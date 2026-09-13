#!/bin/bash
BASE_DIR="/opt/zapret-linux"
BIN="$BASE_DIR/bin"
LISTS="$BASE_DIR/lists"
QNUM=200

# Проверка наличия nfqws
if [ ! -x "$BIN/nfqws" ]; then
    echo "[ОШИБКА] Исполняемый файл nfqws не найден: $BIN/nfqws" >&2
    exit 1
fi

# Загрузка активной стратегии
STRATEGY_FILE="$BASE_DIR/current_strategy.conf"
if [ ! -f "$STRATEGY_FILE" ]; then
    if [ -f "$BASE_DIR/strategies/general_alt13.conf" ]; then
        cp "$BASE_DIR/strategies/general_alt13.conf" "$STRATEGY_FILE"
    else
        echo "[ОШИБКА] Конфигурация стратегии не найдена: $STRATEGY_FILE" >&2
        exit 1
    fi
fi

source "$STRATEGY_FILE"

# Настройка Game Filter (игровой фильтр)
GAME_FILTER_FILE="$BASE_DIR/.game_filter"
GAME_FILTER_TCP="12"
GAME_FILTER_UDP="12"

if [ -f "$GAME_FILTER_FILE" ]; then
    MODE=$(cat "$GAME_FILTER_FILE" 2>/dev/null | tr -d ' \t\r\n')
    case "$MODE" in
        tcp)
            GAME_FILTER_TCP="1024:65535"
            GAME_FILTER_UDP="12"
            ;;
        udp)
            GAME_FILTER_TCP="12"
            GAME_FILTER_UDP="1024:65535"
            ;;
        all|*)
            GAME_FILTER_TCP="1024:65535"
            GAME_FILTER_UDP="1024:65535"
            ;;
    esac
fi

# Порты для iptables
FINAL_TCP_PORTS="$TCP_PORTS"
FINAL_UDP_PORTS="$UDP_PORTS"
if [ "$GAME_FILTER_TCP" != "12" ]; then
    FINAL_TCP_PORTS="$FINAL_TCP_PORTS,$GAME_FILTER_TCP"
fi
if [ "$GAME_FILTER_UDP" != "12" ]; then
    FINAL_UDP_PORTS="$FINAL_UDP_PORTS,$GAME_FILTER_UDP"
fi

# Очистка старых правил
"$BASE_DIR/scripts/zapret-stop.sh" 2>/dev/null

echo "Применение правил фаервола iptables..."
iptables -I OUTPUT -p tcp -m multiport --dports $FINAL_TCP_PORTS -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $QNUM --queue-bypass
iptables -I OUTPUT -p udp -m multiport --dports $FINAL_UDP_PORTS -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $QNUM --queue-bypass

echo "Запуск nfqws со стратегией: $STRATEGY_NAME"
eval "exec \"$BIN/nfqws\" --qnum=$QNUM --dpi-desync-fwmark=0x40000000 $NFQWS_OPT"
