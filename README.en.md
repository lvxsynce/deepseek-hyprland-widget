# DeepSeek widget for Hyprland

A small DeepSeek window that always runs in the background. Hit one hotkey
and it pops up right in the middle of your screen, on top of whatever you're
doing.

Log in once and you're done. After that it's `Super + Shift` and you just
type to the model without ever switching to a browser.

<!-- Russian version: [README.md](README.md) -->

## What you get

```
 Super + Shift  →  600x650 window, centered, on top of everything
 Super + Shift  →  window hides back into the background
```

It starts on login, so you never have to open the browser yourself.

## Requirements

- Hyprland
- chromium / google-chrome / chromium-browser

## Install

```bash
git clone https://github.com/lvxsynce/deepseek-hyprland-widget.git
cd deepseek-hyprland-widget
./install.sh
```

The script will:

- drop the toggle script into `~/.config/hypr/scripts/`
- add a `.desktop` file so DeepSeek shows up in your app launcher
- add the window rule to `~/.config/hypr/config/rules.conf`
- add the hotkey and the autostart entry

Everything it touches gets a `*.bak` backup. After it's done:

```bash
hyprctl reload
```

Press `Super + Shift`. DeepSeek opens. Log in once.

That's it. Nothing else to configure.

## Want to tweak it?

| I want | Where |
|---|---|
| A different hotkey | the `bind` line in your hypr config or `settings.json` |
| A different size | `size = 600 650` in `rules.conf` |
| No autostart | drop the `chromium` line from your startup entries |

## If it doesn't work

**The window opens fullscreen.** The window rule didn't match. Make sure
`rules.conf` matches `chrome-chat\.deepseek\.com.*` exactly — Chromium on
Wayland ignores `--class` and reports a different class name.

**Nothing happens when I press the key.** Check the log:

```bash
hyprctl clients -j | grep -i deepseek
```

Empty means the app never started. Run the command by hand in a terminal
to see the actual error.

**DeepSeek logged you out.** The session lives in `~/.config/deepseek`.
Don't delete that folder unless you want to log in again.

## Uninstall

```bash
./uninstall.sh
hyprctl reload
```

## How it works

No magic, it's plain Hyprland:

- **special workspace** `special:ai` — a workspace drawn on top of the
  current one. That's why the window is always above everything else.
- **windowrule** — tells Hyprland: this window is always floating,
  centered, 600x650, and lives on `special:ai`.
- **a separate chromium profile** (`--user-data-dir`) — so DeepSeek's
  cookies don't mix with your normal browser.
- **the script** — starts the app if it isn't running yet, otherwise it
  just toggles the special workspace.

## Notes

- DeepSeek breaks its own layout sometimes, and Cloudflare may throw a
  captcha at you. Just restart the window, it fixes itself.
- If you'd rather not keep a browser around, there's an API option with a
  key (free credits on platform.deepseek.com). Different story though.