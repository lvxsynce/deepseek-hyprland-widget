#!/usr/bin/env bash
# Убирает DeepSeek-виджет из Hyprland. / Removes the DeepSeek widget from Hyprland.

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR_DIR="$CONFIG_DIR/hypr"
RULES_FILE="$HYPR_DIR/config/rules.conf"
TOGGLE_CMD="$HYPR_DIR/scripts/deepseek-toggle.sh"
APPS_DIR="$HOME/.local/share/applications"
PROFILE_DIR="$CONFIG_DIR/deepseek"

START_MARK="# >>> deepseek-hyprland-widget >>>"
END_MARK="# <<< deepseek-hyprland-widget <<<"

TOGGLE_CMD="$TOGGLE_CMD"

say() { printf '\033[1;36m==>\033[0m %s\n' "$1"; }

# окно могло остаться запущенным
pkill -f "user-data-dir=$PROFILE_DIR" 2>/dev/null || true

rm -f "$TOGGLE_CMD"
say "удалил $TOGGLE_CMD"

rm -f "$APPS_DIR/deepseek.desktop"
command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
say "удалил .desktop"

if [ -f "$RULES_FILE" ] && grep -qF "$START_MARK" "$RULES_FILE"; then
    tmp="$(mktemp)"
    awk -v s="$START_MARK" -v e="$END_MARK" '
        $0 == s { skip = 1; next }
        $0 == e { skip = 0; next }
        !skip   { print }
    ' "$RULES_FILE" > "$tmp"
    mv "$tmp" "$RULES_FILE"
    say "вырезал правило окна из rules.conf"
fi

if [ -f "$HYPR_DIR/settings.json" ]; then
    cp "$HYPR_DIR/settings.json" "$HYPR_DIR/settings.json.bak"
    tmp="$(mktemp)"
    python3 - "$HYPR_DIR/settings.json" "$tmp" "$TOGGLE_CMD" "$PROFILE_DIR" <<'PY'
import json, sys

src, dst, toggle_cmd, profile_dir = sys.argv[1:5]

with open(src) as f:
    cfg = json.load(f)

cfg["keybinds"] = [
    k for k in cfg.get("keybinds", [])
    if (k.get("command") or "") != toggle_cmd
]
cfg["startup"] = [
    s for s in cfg.get("startup", [])
    if profile_dir not in (s.get("command") or "")
]

with open(dst, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    mv "$tmp" "$HYPR_DIR/settings.json"
    say "почистил settings.json (бэкап: settings.json.bak)"
fi

cat <<EOF

$(say "готово")

  hyprctl reload

Папка ~/.config/deepseek осталась — это твоя сессия.
Удали её руками, если больше не нужен вход:
  rm -rf ~/.config/deepseek
EOF