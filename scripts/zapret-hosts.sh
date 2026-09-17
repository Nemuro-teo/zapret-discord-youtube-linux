#!/bin/bash
# ==============================================================================
# zapret-hosts.sh: Управление безопасным маппингом незаблокированных CDN IP в /etc/hosts
# Разблокирует: Instagram, Facebook, WhatsApp (Meta) и Telegram Web
# Источники: MagilaCDN / GeoHide DNS / Nukera / Flowseal
# ==============================================================================

BASE_DIR="${BASE_DIR:-/opt/zapret-linux}"
LISTS_DIR="$BASE_DIR/lists"
HOSTS_FILE="/etc/hosts"
MARKER_START="# BEGIN zapret-linux unblock"
MARKER_END="# END zapret-linux unblock"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

remove_hosts() {
    if [ ! -f "$HOSTS_FILE" ]; then
        return 0
    fi
    if grep -qF "$MARKER_START" "$HOSTS_FILE" 2>/dev/null; then
        # Удаляем всё от MARKER_START до MARKER_END включительно
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE" 2>/dev/null || true
    fi
}

apply_hosts() {
    remove_hosts

    local entries=""
    for f in "$LISTS_DIR/hosts-meta.txt" "$LISTS_DIR/hosts-telegram.txt" "$LISTS_DIR/hosts-user.txt"; do
        if [ -f "$f" ]; then
            while IFS= read -r line || [ -n "$line" ]; do
                # Пропускаем пустые строки и комментарии
                line_trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                case "$line_trimmed" in
                    ""|\#*) continue ;;
                    *) entries="${entries}${line_trimmed}\n" ;;
                esac
            done < "$f"
        fi
    done

    if [ -n "$entries" ]; then
        {
            echo ""
            echo "$MARKER_START"
            printf "%b" "$entries"
            echo "$MARKER_END"
        } >> "$HOSTS_FILE"
    fi
}

status_hosts() {
    if [ -f "$HOSTS_FILE" ] && grep -qF "$MARKER_START" "$HOSTS_FILE" 2>/dev/null; then
        local count
        count=$(sed -n "/$MARKER_START/,/$MARKER_END/p" "$HOSTS_FILE" | grep -v '^#' | grep -c '[^[:space:]]' || true)
        echo -e "${GREEN}АКТИВЕН${NC} (записей в /etc/hosts: $count)"
        return 0
    else
        echo -e "${YELLOW}ОТКЛЮЧЕН${NC}"
        return 1
    fi
}

case "$1" in
    apply|on)
        apply_hosts
        echo -e "${GREEN}[✓] Записи для Instagram, Facebook и Telegram Web успешно добавлены в $HOSTS_FILE.${NC}"
        ;;
    remove|off)
        remove_hosts
        echo -e "${GREEN}[✓] Записи zapret-linux удалены из $HOSTS_FILE.${NC}"
        ;;
    status)
        status_hosts
        ;;
    toggle)
        if status_hosts >/dev/null 2>&1; then
            remove_hosts
            echo -e "${YELLOW}[-] Обход через hosts отключен.${NC}"
        else
            apply_hosts
            echo -e "${GREEN}[+] Обход через hosts включен.${NC}"
        fi
        ;;
    *)
        echo "Использование: $0 {apply|remove|status|toggle}"
        exit 1
        ;;
esac
