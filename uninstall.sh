#!/bin/bash
# Скрипт удаления zapret-discord-youtube-linux

if [ "$EUID" -ne 0 ]; then
    echo "[!] Запустите с правами root: sudo bash $0" >&2
    exit 1
fi

echo "Остановка и отключение службы..."
systemctl stop zapret-linux 2>/dev/null || true
systemctl disable zapret-linux 2>/dev/null || true

# Очистка фаервола
/opt/zapret-linux/scripts/zapret-stop.sh 2>/dev/null || true

rm -f /etc/systemd/system/zapret-linux.service
rm -f /usr/local/bin/zapret-cli
systemctl daemon-reload

echo "Удаление файлов /opt/zapret-linux..."
rm -rf /opt/zapret-linux

echo "[✓] zapret-discord-youtube-linux полностью удален."
