#!/bin/bash
# zapret-discord-youtube-linux: прямой запуск в терминале (аналог opt/zapret/start.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BASE_DIR="$SCRIPT_DIR"
exec "$SCRIPT_DIR/scripts/zapret-run.sh" "$@"
