#!/bin/bash
BASE_DIR="${BASE_DIR:-/opt/zapret-linux}"
BIN="$BASE_DIR/bin"
LISTS="$BASE_DIR/lists"
QNUM=200

# Проверка наличия nfqws
if [ ! -x "$BIN/nfqws" ]; then
    echo "[ОШИБКА] Исполняемый файл nfqws не найден: $BIN/nfqws" >&2
    exit 1
fi

# Загрузка модулей ядра для NFQUEUE и фаервола (xtables и nftables)
modprobe nfnetlink_queue 2>/dev/null || true
modprobe nft_queue 2>/dev/null || true
modprobe xt_NFQUEUE 2>/dev/null || true
modprobe xt_multiport 2>/dev/null || true
modprobe xt_mark 2>/dev/null || true

# Настройки сетевого стека для корректной десинхронизации
sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1 || true
sysctl -w net.netfilter.nf_conntrack_tcp_be_liberal=1 >/dev/null 2>&1 || true

# 1. Настройка Game Filter (игровой фильтр) ДО загрузки стратегии
GAME_FILTER_FILE="$BASE_DIR/.game_filter"
GAME_FILTER_TCP="12"
GAME_FILTER_UDP="12"

if [ -f "$GAME_FILTER_FILE" ]; then
    MODE=$(cat "$GAME_FILTER_FILE" 2>/dev/null | tr -d ' \t\r\n')
    case "$MODE" in
        tcp)
            GAME_FILTER_TCP="1024-65535"
            GAME_FILTER_UDP="12"
            ;;
        udp)
            GAME_FILTER_TCP="12"
            GAME_FILTER_UDP="1024-65535"
            ;;
        all|*)
            GAME_FILTER_TCP="1024-65535"
            GAME_FILTER_UDP="1024-65535"
            ;;
    esac
fi

# 2. Загрузка активной стратегии (подставляет BIN, LISTS, GAME_FILTER_TCP/UDP)
STRATEGY_FILE="$BASE_DIR/current_strategy.conf"
if [ ! -f "$STRATEGY_FILE" ]; then
    if [ -f "$BASE_DIR/strategies/general_alt13.conf" ]; then
        cp "$BASE_DIR/strategies/general_alt13.conf" "$STRATEGY_FILE"
    else
        echo "[ОШИБКА] Конфигурация стратегии не найдена: $STRATEGY_FILE" >&2
        exit 1
    fi
fi

# Авто-исправление старых артефактов Windows CMD (^!) в конфигурации стратегии
sed -i 's/\^!/!/g' "$STRATEGY_FILE" 2>/dev/null || true

source "$STRATEGY_FILE"

# Если игровой фильтр отключен (12), убираем неиспользуемые профили для 100% совпадения с чистым Flowseal
if [ "$GAME_FILTER_TCP" = "12" ] && [ "$GAME_FILTER_UDP" = "12" ]; then
    NFQWS_OPT="${NFQWS_OPT%%--new --filter-tcp=12*}"
fi

# Убираем возможные висячие обратные слэши и пробелы в конце строки
NFQWS_OPT=$(echo "$NFQWS_OPT" | sed -e 's/[[:space:]\\]*$//')


# 3. Порты для iptables (диапазоны в Linux-фаерволе задаются через двоеточие)
FINAL_TCP_PORTS="$TCP_PORTS"
FINAL_UDP_PORTS="$UDP_PORTS"
if [ "$GAME_FILTER_TCP" != "12" ]; then
    IPTABLES_GAME_TCP="${GAME_FILTER_TCP//-/:}"
    FINAL_TCP_PORTS="$FINAL_TCP_PORTS,$IPTABLES_GAME_TCP"
fi
if [ "$GAME_FILTER_UDP" != "12" ]; then
    IPTABLES_GAME_UDP="${GAME_FILTER_UDP//-/:}"
    FINAL_UDP_PORTS="$FINAL_UDP_PORTS,$IPTABLES_GAME_UDP"
fi

# Очистка старых правил
"$BASE_DIR/scripts/zapret-stop.sh" 2>/dev/null

echo "Применение правил фаервола iptables (IPv4)..."
if ! iptables -I OUTPUT -p tcp -m multiport --dports $FINAL_TCP_PORTS -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $QNUM --queue-bypass; then
    echo "[ОШИБКА] Сбой команды iptables для TCP!" >&2
fi
if ! iptables -I OUTPUT -p udp -m multiport --dports $FINAL_UDP_PORTS -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $QNUM --queue-bypass; then
    echo "[ОШИБКА] Сбой команды iptables для UDP!" >&2
fi

# Блокировка QUIC (UDP 443), принуждающая браузеры мгновенно переходить на TCP TLS (HTTP/2)
if [ -f "$BASE_DIR/.block_quic" ]; then
    iptables -I OUTPUT -p udp --dport 443 -j REJECT --reject-with icmp-port-unreachable 2>/dev/null || true
fi

echo "Запуск nfqws со стратегией: $STRATEGY_NAME"
eval "exec \"$BIN/nfqws\" --qnum=$QNUM --dpi-desync-fwmark=0x40000000 $NFQWS_OPT"

