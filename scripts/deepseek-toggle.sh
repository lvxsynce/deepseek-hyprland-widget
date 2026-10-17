#!/usr/bin/env bash
# DeepSeek overlay для Hyprland.
#
#   deepseek-toggle.sh          показать / спрятать
#   deepseek-toggle.sh close    закрыть окно совсем
#
# Логика простая: окно живёт на special workspace и мы им управляем.
# Перед каждым действием проверяем, что окно реально на месте —
# иначе Hyprland откроет пустой special workspace и экран просто
# потемнеет без всякого окна.

set -uo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PROFILE_DIR="$CONFIG_DIR/deepseek"
URL="${DEEPSEEK_URL:-https://chat.deepseek.com}"
SPECIAL="${DEEPSEEK_SPECIAL:-ai}"

# Chromium на Wayland игнорирует --class, окно называется
# chrome-chat.deepseek.com__-Default. Ищем по домену.
CLASS_RE='chat\.deepseek'

have() { command -v "$1" >/dev/null 2>&1; }

find_addr() {
    hyprctl clients -j 2>/dev/null \
        | jq -r --arg re "$CLASS_RE" \
              '.[] | select(.class | test($re; "i")) | .address' 2>/dev/null \
        | head -1
}

# Показанный special workspace лежит в monitors[].specialWorkspace,
# а не в activeworkspace — тот всегда возвращает обычный воркспейс.
spec_open() {
    hyprctl monitors -j 2>/dev/null \
        | jq -e --arg n "special:$SPECIAL" \
              'any(.[]; .specialWorkspace.name == $n)' >/dev/null 2>&1
}

spec_toggle() {
    hyprctl dispatch togglespecialworkspace "$SPECIAL" >/dev/null 2>&1
}

# Убить осиротевший chromium. pkill -f нельзя: паттерн совпадёт
# с самой командой и убьёт шелл, от которого её запустили.
kill_strays() {
    local p
    for p in $(pgrep -x chromium 2>/dev/null); do
        if tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null | grep -q "config/deepseek"; then
            kill "$p" 2>/dev/null
        fi
    done
    sleep 0.4
}

launch() {
    local bin=""
    local candidate
    for candidate in chromium chromium-browser google-chrome brave-browser; do
        if have "$candidate"; then bin="$candidate"; break; fi
    done

    if [ -z "$bin" ]; then
        hyprctl notify "DeepSeek" "не нашёл chromium/chrome" 2>/dev/null
        return 1
    fi

    mkdir -p "$PROFILE_DIR"
    hyprctl dispatch exec \
        "[workspace special:$SPECIAL silent] $bin --class=deepseek --user-data-dir=$PROFILE_DIR --ozone-platform-hint=auto --app=$URL" \
        >/dev/null 2>&1

    sleep 2.5
}

focus() {
    hyprctl dispatch focuswindow "address:$1" >/dev/null 2>&1
}

# ─── закрыть совсем ──────────────────────────────────────────────
if [ "${1:-toggle}" = "close" ]; then
    addr="$(find_addr)"
    [ -n "$addr" ] && hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1
    exit 0
fi

addr="$(find_addr)"

# Окно видно -> прячем
if [ -n "$addr" ] && spec_open; then
    spec_toggle
    exit 0
fi

# Окна нет -> если висит пустой special workspace, гасим его,
# иначе после запуска окно окажется "в показанном" пустом воркспейсе
if [ -z "$addr" ]; then
    if spec_open; then
        spec_toggle
        sleep 0.4
    fi
    kill_strays
    launch || exit 1
    addr="$(find_addr)"
    [ -n "$addr" ] || exit 1
fi

# Окно есть -> возвращаем его на special workspace
hyprctl dispatch movetoworkspace "special:$SPECIAL, address:$addr" >/dev/null 2>&1
sleep 0.2

# Если после переноса special workspace уже показан — всё уже хорошо
if spec_open; then
    focus "$addr"
    exit 0
fi

spec_toggle
focus "$addr"