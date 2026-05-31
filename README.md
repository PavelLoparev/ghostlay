# ghostlay

Automate Ghostty terminal pane splitting, navigation, resizing, and command execution. Sends keystrokes via `wtype` — nothing to install beyond the script itself.

## Dependencies

- [wtype](https://github.com/atx/wtype) — Wayland keyboard input simulator
- A [Ghostty](https://ghostty.org) terminal (script checks `$GHOSTTY_RESOURCES_DIR` or `xterm-ghostty`)

## Install

```sh
cp ghostlay ~/.local/bin/
chmod +x ~/.local/bin/ghostlay
```

## Usage

```
ghostlay ls                        list saved layouts
ghostlay dev                       run the "dev" layout from config
ghostlay --layout 'v n "htop"'     inline layout (no config needed)
ghostlay --debug dev               show tokens as they execute
```

## Config

`~/.config/ghostlay/config`

```
delay = 1          # seconds between keystrokes (default 0.5)
bind = v:-M ctrl -M shift -k o -m shift -m ctrl  # override wtype args for a token

dev = v p "nvim" n "cargo watch"
```
Now if you run `ghostlay dev` it will produce simple 2 pane setup (vertical split) with `nvim`
on the left pane and the `cargo watch` on the right. `v p "nvim" n "cargo watch"` stands for:
`v` - split vertically then `p` - go to previous pane then run nvim then `n` - go to the next
pane and run cargo watch.

Lines starting with `#` are ignored.

## Tokens

| Token  | Action                    | Keystroke                        |
|--------|---------------------------|----------------------------------|
| `v`    | Vertical split            | Ctrl+Shift+O                     |
| `h`    | Horizontal split          | Ctrl+Shift+E                     |
| `n`    | Next pane                 | Super+Ctrl+]                     |
| `p`    | Previous pane             | Super+Ctrl+[                     |
| `rr`   | Resize right              | Super+Ctrl+Alt+Shift+Right       |
| `rl`   | Resize left               | Super+Ctrl+Alt+Shift+Left        |
| `ru`   | Resize up                 | Super+Ctrl+Alt+Shift+Up          |
| `rd`   | Resize down               | Super+Ctrl+Alt+Shift+Down        |
| `...`  | Type and press Enter      | Anything else (quote if spaced)  |

## How it works

1. Reads a layout — either from config or `--layout` string
2. Parses the token sequence
3. Sends the corresponding `wtype` keystrokes with a delay between each
4. All keystrokes target the currently focused window

## Testing

Requires [bats](https://github.com/bats-core/bats-core):

```sh
bats test/ghostlay.bats
```
