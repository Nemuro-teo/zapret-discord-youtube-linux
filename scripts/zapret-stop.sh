#!/bin/bash
BASE_DIR="/opt/zapret-linux"
QNUM=200

# Очистка всех правил NFQUEUE для заданной очереди
iptables -S OUTPUT 2>/dev/null | grep "NFQUEUE --queue-num $QNUM" | while read -r rule; do
    cmd=$(echo "$rule" | sed 's/^-A /-D /')
    iptables $cmd 2>/dev/null
done

exit 0
