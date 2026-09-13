#!/bin/bash
BASE_DIR="${BASE_DIR:-/opt/zapret-linux}"
QNUM=200

# Быстрое удаление стандартных правил Flowseal
iptables -D OUTPUT -p tcp -m multiport --dports 80,443,2053,2083,2087,2096,8443 -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null || true
iptables -D OUTPUT -p udp -m multiport --dports 443,19294:19344,50000:50100 -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null || true
while iptables -D OUTPUT -p udp --dport 443 -j REJECT --reject-with icmp-port-unreachable 2>/dev/null; do :; done


# Полная очистка любых оставшихся правил NFQUEUE для IPv4
iptables -S OUTPUT 2>/dev/null | grep "NFQUEUE --queue-num $QNUM" | while read -r rule; do
    cmd=$(echo "$rule" | sed 's/^-A /-D /')
    iptables $cmd 2>/dev/null
done

# Очистка всех правил NFQUEUE для IPv6 (если остались от старых версий)
if command -v ip6tables >/dev/null 2>&1; then
    ip6tables -S OUTPUT 2>/dev/null | grep "NFQUEUE --queue-num $QNUM" | while read -r rule; do
        cmd=$(echo "$rule" | sed 's/^-A /-D /')
        ip6tables $cmd 2>/dev/null
    done
fi

# Остановка standalone процессов nfqws при ручном запуске
pkill -f "$BASE_DIR/bin/nfqws" 2>/dev/null || true

exit 0
