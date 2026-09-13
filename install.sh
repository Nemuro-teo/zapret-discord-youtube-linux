#!/bin/bash
# ==============================================================================
# zapret-discord-youtube-linux: Скрипт автоматической установки
# Подходит для: РЕД ОС 8, Fedora, CentOS, RHEL, Ubuntu, Debian, Arch Linux
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Пожалуйста, запустите скрипт с правами root: sudo bash $0${NC}" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/opt/zapret-linux"

echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}  Установка zapret-discord-youtube-linux (Flowseal)  ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"
echo

# 1. Определение пакетного менеджера и установка зависимостей
echo -e "${BOLD}[1/6] Проверка и установка системных пакетов...${NC}"
if command -v dnf &>/dev/null; then
    echo "Используется dnf (РЕД ОС / Fedora / CentOS)..."
    dnf install -y iptables ipset libnetfilter_queue curl wget tar
elif command -v yum &>/dev/null; then
    echo "Используется yum..."
    yum install -y iptables ipset libnetfilter_queue curl wget tar
elif command -v apt-get &>/dev/null; then
    echo "Используется apt-get (Ubuntu / Debian)..."
    apt-get update -qq || true
    apt-get install -y --no-install-recommends iptables ipset libnetfilter-queue1 curl wget tar
elif command -v pacman &>/dev/null; then
    echo "Используется pacman (Arch Linux)..."
    pacman -Sy --noconfirm iptables ipset libnetfilter_queue curl wget tar
elif command -v zypper &>/dev/null; then
    echo "Используется zypper..."
    zypper install -y iptables ipset libnetfilter_queue1 curl wget tar
else
    echo -e "${YELLOW}[!] Пакетный менеджер не определен. Убедитесь, что установлены iptables, ipset и libnetfilter_queue.${NC}"
fi

# 2. Копирование файлов в целевую директорию
echo -e "${BOLD}[2/6] Копирование файлов в $TARGET_DIR...${NC}"
mkdir -p "$TARGET_DIR"

# Останавливаем старую службу, если работает
systemctl stop zapret-linux 2>/dev/null || true
systemctl stop zapret-flowseal 2>/dev/null || true
systemctl disable zapret-flowseal 2>/dev/null || true

cp -r "$SCRIPT_DIR/bin" "$TARGET_DIR/"
cp -r "$SCRIPT_DIR/lists" "$TARGET_DIR/"
cp -r "$SCRIPT_DIR/strategies" "$TARGET_DIR/"
cp -r "$SCRIPT_DIR/scripts" "$TARGET_DIR/"
cp "$SCRIPT_DIR/zapret-cli" "$TARGET_DIR/"

# Проверяем наличие пустых списков
touch "$TARGET_DIR/lists/ipset-exclude.txt"
touch "$TARGET_DIR/lists/ipset-exclude-user.txt"
touch "$TARGET_DIR/lists/list-general-user.txt"
touch "$TARGET_DIR/lists/list-exclude-user.txt"

# Устанавливаем стратегию по умолчанию (ALT13)
if [ ! -f "$TARGET_DIR/current_strategy.conf" ]; then
    cp "$TARGET_DIR/strategies/general_alt13.conf" "$TARGET_DIR/current_strategy.conf"
fi

# 3. Проверка или скачивание бинарника nfqws
echo -e "${BOLD}[3/6] Проверка бинарника nfqws...${NC}"
if [ ! -f "$TARGET_DIR/bin/nfqws" ]; then
    echo "Скачивание скомпилированного nfqws (версия v72.13 x86_64)..."
    TMP_DIR=$(mktemp -d)
    wget -q -O "$TMP_DIR/zapret.tar.gz" "https://github.com/bol-van/zapret/releases/download/v72.13/zapret-v72.13.tar.gz"
    tar -xzf "$TMP_DIR/zapret.tar.gz" -C "$TMP_DIR"
    cp "$TMP_DIR"/zapret-*/binaries/x86_64/nfqws "$TARGET_DIR/bin/nfqws"
    rm -rf "$TMP_DIR"
fi
chmod +x "$TARGET_DIR/bin/nfqws"

# 4. Настройка прав доступа и SELinux
echo -e "${BOLD}[4/6] Настройка прав доступа и безопасности...${NC}"
chmod +x "$TARGET_DIR/scripts/"*.sh
chmod +x "$TARGET_DIR/zapret-cli"
chmod 644 "$TARGET_DIR/bin/"*.bin 2>/dev/null || true
chmod 644 "$TARGET_DIR/lists/"*.txt 2>/dev/null || true

# Включаем TCP timestamps для корректной работы десинхронизации (fooling=ts)
sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1 || true
echo "net.ipv4.tcp_timestamps = 1" | tee /etc/sysctl.d/99-zapret.conf >/dev/null 2>&1 || true

# SELinux контекст для РЕД ОС / Fedora
if command -v chcon &>/dev/null; then
    chcon -t bin_t "$TARGET_DIR/bin/nfqws" 2>/dev/null || true
    chcon -t bin_t "$TARGET_DIR/scripts/"*.sh 2>/dev/null || true
    chcon -t bin_t "$TARGET_DIR/zapret-cli" 2>/dev/null || true
fi

# 5. Установка systemd-службы и симлинка CLI
echo -e "${BOLD}[5/6] Настройка службы systemd и CLI...${NC}"
cp "$SCRIPT_DIR/systemd/zapret-linux.service" /etc/systemd/system/zapret-linux.service
ln -sf "$TARGET_DIR/zapret-cli" /usr/local/bin/zapret-cli

systemctl daemon-reload
systemctl enable zapret-linux.service
systemctl restart zapret-linux.service

# 6. Проверка статуса
echo -e "${BOLD}[6/6] Проверка работы службы...${NC}"
sleep 2

if systemctl is-active --quiet zapret-linux.service; then
    echo -e "${GREEN}${BOLD}======================================================${NC}"
    echo -e "${GREEN}${BOLD}  [✓] zapret-discord-youtube-linux успешно установлен!${NC}"
    echo -e "${GREEN}${BOLD}======================================================${NC}"
    echo
    echo -e "Активная стратегия: ${CYAN}$(grep '^STRATEGY_NAME=' "$TARGET_DIR/current_strategy.conf" | cut -d'"' -f2)${NC}"
    echo
    echo -e "Теперь вы можете использовать команду ${BOLD}${GREEN}zapret-cli${NC}:"
    echo -e "  ${BOLD}sudo zapret-cli switch${NC}       - Сменить стратегию обхода (меню)"
    echo -e "  ${BOLD}sudo zapret-cli switch alt12${NC} - Быстро включить стратегию ALT12"
    echo -e "  ${BOLD}zapret-cli status${NC}            - Проверить статус службы"
    echo -e "  ${BOLD}sudo zapret-cli update-lists${NC} - Обновить списки доменов и IP от Flowseal"
    echo -e "  ${BOLD}zapret-cli log${NC}               - Смотреть лог в реальном времени"
    echo
else
    echo -e "${RED}[!] Внимание: служба не смогла запуститься. Проверьте: journalctl -u zapret-linux -n 25${NC}"
fi
