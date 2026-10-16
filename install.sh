#!/usr/bin/env bash
# Ставит DeepSeek-виджет в Hyprland. / Installs the DeepSeek widget into Hyprland.

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR_DIR="$CONFIG_DIR/hypr"
RULES_FILE="$HYPR_DIR/config/rules.conf"
SCRIPTS_DIR="$HYPR_DIR/scripts"
APPS_DIR="$HOME/.local/share/applications"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOTKEY_MODS="${HOTKEY_MODS:-\$mainMod}"
HOTKEY_KEY="${HOTKEY_KEY:-SHIFT_L}"
TOGGLE_CMD="$SCRIPTS_DIR/deepseek-toggle.sh"
PROFILE_DIR="$CONFIG_DIR/deepseek"

START_MARK="# >>> deepseek-hyprland-widget >>>"
END_MARK="# <<< deepseek-hyprland-widget <<<"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$1" >&2; exit 1; }

backup() {
    [ -f "$1" ] || return 0
    cp "$1" "$1.bak"
    say "бэкап: $1.bak"
}

# ─── 1. сам скрипт ───────────────────────────────────────────────
say "ставлю toggle-скрипт"
mkdir -p "$SCRIPTS_DIR"
install -m 755 "$SELF_DIR/scripts/deepseek-toggle.sh" "$TOGGLE_CMD"

# ─── 2. .desktop ─────────────────────────────────────────────────
say "ставлю .desktop"
mkdir -p "$APPS_DIR"
install -m 644 "$SELF_DIR/deepseek.desktop" "$APPS_DIR/deepseek.desktop"
command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "$APPS_DIR" 2>/dev/null || true

# ─── 3. профиль chromium ─────────────────────────────────────────
mkdir -p "$PROFILE_DIR"

# ─── 4. правило окна ─────────────────────────────────────────────
if [ -f "$RULES_FILE" ]; then
    if grep -qF "$START_MARK" "$RULES_FILE"; then
        say "правило окна уже есть, пропускаю"
    else
        say "добавляю правило окна в rules.conf"
        backup "$RULES_FILE"
        {
            echo ""
            echo "$START_MARK"
            cat "$SELF_DIR/hypr/rules.conf.snippet"
            echo "$END_MARK"
        } >> "$RULES_FILE"
    fi
else
    die "не нашёл $RULES_FILE — допиши правило руками (см. hypr/rules.conf.snippet)"
fi

# ─── 5. хоткей + автозапуск ──────────────────────────────────────
launch_cmd="chromium --class=deepseek --user-data-dir=$PROFILE_DIR --ozone-platform-hint=auto --app=https://chat.deepseek.com"

if [ -f "$HYPR_DIR/settings.json" ]; then
    say "правлю settings.json (хоткей + автозапуск)"
    backup "$HYPR_DIR/settings.json"

    TMP="$(mktemp)"
    python3 - "$HYPR_DIR/settings.json" "$TMP" "$HOTKEY_MODS" "$HOTKEY_KEY" "$TOGGLE_CMD" "$launch_cmd" <<'PY'
import json, sys

src, dst, mods, key, toggle_cmd, launch_cmd = sys.argv[1:7]

with open(src) as f:
    cfg = json.load(f)

cfg.setdefault("keybinds", [])
cfg.setdefault("startup", [])

if not any((k.get("command") or "") == toggle_cmd for k in cfg["keybinds"]):
    cfg["keybinds"].append({
        "type": "bind",
        "mods": mods,
        "key": key,
        "dispatcher": "exec",
        "command": toggle_cmd,
        "isEditing": False,
    })

if not any(launch_cmd in (s.get("command") or "") for s in cfg["startup"]):
    cfg["startup"].append({"command": launch_cmd})

with open(dst, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    mv "$TMP" "$HYPR_DIR/settings.json"
else
    warn "settings.json не найден — допиши хоткей и автозапуск в hyprland.conf руками:"
    warn "  bind = $HOTKEY_MODS, $HOTKEY_KEY, exec, $TOGGLE_CMD"
    warn "  exec-once = $launch_cmd"
fi

# ─── готово ──────────────────────────────────────────────────────
cat <<EOF

$(say "готово")

Теперь:

  hyprctl reload

и нажми  Super + $HOTKEY_KEY  — вылезет DeepSeek.

Залогинись один раз, всё запомнится в ~/.config/deepseek.

Удалить потом:  ./uninstall.sh && hyprctl reload
EOF