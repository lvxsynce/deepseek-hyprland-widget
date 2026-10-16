# Сколько весит окно и где оно появляется.

windowrule {
    name = "deepseek_widget"
    match:class = chrome-chat\.deepseek\.com.*
    float = on
    center = on
    size = 600 650
    stay_focused = on
    workspace = special:ai silent
}

# ─────────────────────────────────────────────────
# Хоткей и автозапуск
# ─────────────────────────────────────────────────
# Для обычного hyprland.conf просто допиши в конец файла:
#
#   bind = SUPER SHIFT_L, exec, ~/.config/hypr/scripts/deepseek-toggle.sh
#   exec-once = chromium --class=deepseek --user-data-dir=/home/USER/.config/deepseek --ozone-platform-hint=auto --app=https://chat.deepseek.com
#
# Если у тебя конфиг генерируется из settings.json (как в hyprland-dots),
# положи ключ в .keybinds[], а строку запуска в .startup[]:
#
#   {
#     "type": "bind",
#     "mods": "$mainMod",
#     "key": "SHIFT_L",
#     "dispatcher": "exec",
#     "command": "~/.config/hypr/scripts/deepseek-toggle.sh"
#   }
#   {
#     "command": "chromium --class=deepseek --user-data-dir=/home/USER/.config/deepseek --ozone-platform-hint=auto --app=https://chat.deepseek.com"
#   }