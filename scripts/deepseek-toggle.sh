#!/usr/bin/env bash
# Показать / скрыть окно DeepSeek поверх всего.
# Если окно ещё не запущено — сначала запускает его в фоне.

set -uo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PROFILE_DIR="$CONFIG_DIR/deepseek"
SCRIPT_PATH="$HOME/.config/hypr/scripts/deepseek-toggle.sh"
URL="${DEEPSEEK_URL:-https://chat.deepseek.com}"

# Chromium на Wayland игнорирует --class и называет окно
# chrome-<домен>__-Default. Поэтому ищем окно по домену.
WINDOW_MATCH="chat\.deepseek"

launch() {
    local bin
    bin="$(command -v chromium || command -v chromium-browser || command -v google-chrome)"

    if [ -z "$bin" ]; then
        notify-send "DeepSeek" "Не найден chromium/chrome" 2>/dev/null
        return 1
    fi

    mkdir -p "$PROFILE_DIR"
    hyprctl dispatch exec "[workspace special:ai silent] \
$bin --class=deepseek \
     --user-data-dir=$PROFILE_DIR \
     --ozone-platform-hint=auto \
     --app=$URL" >/dev/null 2>&1

    # ждём пока окно появится, иначе togglespecialworkspace откроет пустую воркспейс-обёртку
    sleep 1.2
}

is_running() {
    hyprctl clients -j 2>/dev/null | grep -qi "$WINDOW_MATCH"
}

if is_running; then
    hyprctl dispatch togglespecialworkspace ai >/dev/null 2>&1
else
    launch || exit 1
    is_running && hyprctl dispatch togglespecialworkspace ai >/dev/null 2>&1
fi