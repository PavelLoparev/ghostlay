# ghostlay

Automate Ghostty terminal pane splitting, navigation, resizing, and command execution. Sends keystrokes via your choice of injection tool (default is `wtype`).

## Quick demo

https://github.com/user-attachments/assets/bd9298f4-44c4-4f44-bd80-2ca8722978a2

This inline layout:
```
ghostlay --layout 'v opencode p rr rr "fresh ." h rd rd p'
```
translates to:
1. `v` - split vertically
2. `opencode` - run command
3. `p` - go to previous pane
4. `rr` - resize right 100px
5. `rr` - resize right 100px
6. `fresh .` - run command
7. `h` - split horizontally
8. `rd` - resize down 100px
9. `rd` - resize down 100px
10. `p` - go to previous pane

## Dependencies

- A [Ghostty](https://ghostty.org) terminal (script checks `$GHOSTTY_RESOURCES_DIR` or `xterm-ghostty`)
- A keystroke injection tool (default: [wtype](https://github.com/atx/wtype) — auto-configured on first run)

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

If no config file exists, ghostlay creates one on first run with default `wtype` bindings.

```
delay = 1          # seconds between keystrokes (default 0.5)

# Full shell commands — use any keystroke tool
bind = v:wtype -M ctrl -M shift -k o -m shift -m ctrl
bind = n:wtype -M logo -M ctrl -k bracketright -m ctrl -m logo
bind = cmd:wtype "$TOKEN" 2>/dev/null; wtype -k Return 2>/dev/null

dev = v p "nvim" n "cargo watch"
```

Now if you run `ghostlay dev` it will produce a simple 2-pane setup (vertical split) with `nvim`
on the left pane and `cargo watch` on the right. `v p "nvim" n "cargo watch"` stands for:
`v` - split vertically then `p` - go to previous pane then run nvim then `n` - go to the next
pane and run cargo watch.

Lines starting with `#` are ignored.

### Bind format

```
bind = <token>:<full_shell_command>
```

Each bind is a full shell command executed when the token is encountered. The `$TOKEN` variable
is set to the current token at runtime (useful in the `cmd` binding).

Built-in tokens (v, h, n, p, rr, rl, ru, rd) have no special handling — they work entirely
through their bindings. The `cmd` token is the fallback for any unrecognized token.

### Using a different keystroke tool

```ini
# ydotool example
bind = v:ydotool key 29+42+24
bind = cmd:ydotool type "$TOKEN"; ydotool key 28
```

## Tokens

| Token  | Default action           | Default keystroke                  |
|--------|--------------------------|------------------------------------|
| `v`    | Vertical split           | Ctrl+Shift+O                       |
| `h`    | Horizontal split         | Ctrl+Shift+E                       |
| `n`    | Next pane                | Super+Ctrl+]                       |
| `p`    | Previous pane            | Super+Ctrl+[                       |
| `rr`   | Resize right             | Super+Ctrl+Alt+Shift+Right         |
| `rl`   | Resize left              | Super+Ctrl+Alt+Shift+Left          |
| `ru`   | Resize up                | Super+Ctrl+Alt+Shift+Up            |
| `rd`   | Resize down              | Super+Ctrl+Alt+Shift+Down          |
| `cmd`  | Type and press Enter     | Anything else (quote if spaced)    |

All keystrokes are configurable via `bind = <token>:<command>` in the config file.

## How it works

1. Reads a layout — either from config or `--layout` string
2. Parses the token sequence
3. Looks up each token in the bindings and executes the corresponding shell command
4. All keystrokes target the currently focused window

## Testing

Requires [bats](https://github.com/bats-core/bats-core):

```sh
bats test/ghostlay.bats
```
