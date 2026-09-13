#!/bin/bash
# zapret-discord-youtube-linux: остановка и очистка правил
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BASE_DIR="$SCRIPT_DIR"
exec "$SCRIPT_DIR/scripts/zapret-stop.sh" "$@"
