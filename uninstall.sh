#!/bin/bash
# Скрипт удаления zapret-discord-youtube-linux

if [ "$EUID" -ne 0 ]; then
    echo "[!] Запустите с правами root: sudo bash $0" >&2
    exit 1
fi

echo "Остановка и отключение служб..."
systemctl stop zapret-linux 2>/dev/null || true
systemctl disable zapret-linux 2>/dev/null || true
systemctl stop zapret-tg-proxy 2>/dev/null || true
systemctl disable zapret-tg-proxy 2>/dev/null || true
pkill -f "tgproxy.py" 2>/dev/null || true

# Очистка фаервола и /etc/hosts
if [ -x /opt/zapret-linux/scripts/zapret-stop.sh ]; then
    /opt/zapret-linux/scripts/zapret-stop.sh 2>/dev/null || true
fi
if [ -x /opt/zapret-linux/scripts/zapret-hosts.sh ]; then
    /opt/zapret-linux/scripts/zapret-hosts.sh remove 2>/dev/null || true
fi
sed -i "/# BEGIN zapret-linux unblock/,/# END zapret-linux unblock/d" /etc/hosts 2>/dev/null || true

rm -f /etc/systemd/system/zapret-linux.service
rm -f /etc/systemd/system/zapret-tg-proxy.service
rm -f /usr/local/bin/zapret-cli
rm -f /usr/bin/zapret-cli
rm -f /etc/sysctl.d/99-zapret.conf

systemctl daemon-reload
systemctl reset-failed zapret-linux.service 2>/dev/null || true
systemctl reset-failed zapret-tg-proxy.service 2>/dev/null || true

echo "Удаление файлов /opt/zapret-linux..."
rm -rf /opt/zapret-linux

echo "[✓] zapret-discord-youtube-linux полностью удален из системы."
