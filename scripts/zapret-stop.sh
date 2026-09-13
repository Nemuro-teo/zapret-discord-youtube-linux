#!/bin/bash
BASE_DIR="/opt/zapret-linux"
QNUM=200

# Очистка всех правил NFQUEUE для IPv4
iptables -S OUTPUT 2>/dev/null | grep "NFQUEUE --queue-num $QNUM" | while read -r rule; do
    cmd=$(echo "$rule" | sed 's/^-A /-D /')
    iptables $cmd 2>/dev/null
done

# Очистка всех правил NFQUEUE для IPv6
if command -v ip6tables >/dev/null 2>&1; then
    ip6tables -S OUTPUT 2>/dev/null | grep "NFQUEUE --queue-num $QNUM" | while read -r rule; do
        cmd=$(echo "$rule" | sed 's/^-A /-D /')
        ip6tables $cmd 2>/dev/null
    done
fi

exit 0
