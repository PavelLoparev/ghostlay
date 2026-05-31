setup() {
    export GHOSTTY_RESOURCES_DIR=/tmp/fake-ghostty
    export GHOSTLAY_CONFIG="$BATS_TEST_TMPDIR/config"
    export WTYPE_LOG="$BATS_TEST_TMPDIR/wtype.log"
    export PATH="$(dirname "$BATS_TEST_FILENAME")/bin:$PATH"
    : > "$WTYPE_LOG"
    source "$(dirname "$BATS_TEST_FILENAME")/../ghostlay"
}

# Helper: write a config file
write_config() {
    cat > "$GHOSTLAY_CONFIG"
}

# Helper: read wtype log
wtype_log() {
    cat "$WTYPE_LOG"
}

@test "refuses to run without Ghostty env vars" {
    unset GHOSTTY_RESOURCES_DIR
    export TERM=xterm
    run main --layout 'v'
    [ "$status" -eq 1 ]
    [[ "$output" == *"not running in a Ghostty terminal"* ]]
}

@test "passes with GHOSTTY_RESOURCES_DIR set" {
    run main --layout 'v'
    [ "$status" -eq 0 ]
}

@test "reads delay from config" {
    write_config <<'EOF'
delay = 2
EOF
    read_config
    [ "$DELAY" = "2" ]
}

@test "reads bind override from config" {
    write_config <<'EOF'
bind = v:wtype -M foo -k bar
EOF
    read_config
    [ "${BINDS[v]}" = "wtype -M foo -k bar" ]
}

@test "parses a single layout from config" {
    write_config <<'EOF'
dev = v p "nvim" n "cargo watch"
EOF
    read_config
    [ "${LAYOUTS[dev]}" = "v p \"nvim\" n \"cargo watch\"" ]
}

@test "parses multiple layouts from config" {
    write_config <<'EOF'
dev = v p "nvim"
ops = h n "htop"
EOF
    read_config
    [ "${LAYOUTS[dev]}" = "v p \"nvim\"" ]
    [ "${LAYOUTS[ops]}" = "h n \"htop\"" ]
}

@test "ignores comments and blank lines in config" {
    write_config <<'EOF'
# this is a comment

dev = v "nvim"
EOF
    read_config
    [ "${#LAYOUTS[@]}" -eq 1 ]
    [ "${LAYOUTS[dev]}" = "v \"nvim\"" ]
}

@test "empty config loads without error" {
    : > "$GHOSTLAY_CONFIG"
    read_config
    [ "${#LAYOUTS[@]}" -eq 0 ]
}

@test "config with all features combined parses correctly" {
    write_config <<'EOF'
delay = 1.5
bind = n:wtype -M foo -k bar
dev = v "nvim"
ops = h "htop"
EOF
    read_config
    [ "$DELAY" = "1.5" ]
    [ "${BINDS[n]}" = "wtype -M foo -k bar" ]
    [ "${LAYOUTS[dev]}" = "v \"nvim\"" ]
    [ "${LAYOUTS[ops]}" = "h \"htop\"" ]
}

@test "shows usage with no arguments" {
    run main
    [ "$status" -eq 1 ]
    [ "$output" = "Usage: ghostlay [--debug] [--layout <string>] <layout_name|ls>" ]
}

@test "--help shows help text" {
    run help_text
    expected="$output"
    expected_status="$status"
    run main --help
    [ "$status" = "$expected_status" ]
    [ "$output" = "$expected" ]
}

@test "-h shows help text" {
    run help_text
    expected="$output"
    expected_status="$status"
    run main -h
    [ "$status" = "$expected_status" ]
    [ "$output" = "$expected" ]
}

@test "ls lists layout names from config" {
    write_config <<'EOF'
dev = v "nvim"
EOF
    run main ls
    [ "$status" -eq 0 ]
    [ "$output" = "Available layouts:
  dev" ]
}

@test "ls with empty config shows no layouts" {
    run main ls
    [ "$status" -eq 0 ]
}

@test "--debug flag outputs trace to stderr" {
    run main --debug --layout 'v'
    [ "$status" -eq 0 ]
    [ "$output" = "Tokens: v
  bind v: wtype -M ctrl -M shift -k o -m shift -m ctrl" ]
}

@test "--layout runs inline tokens without config" {
    rm -f "$GHOSTLAY_CONFIG"
    run main --layout 'v'
    [ "$status" -eq 0 ]
}

@test "v dispatches vertical split" {
    run main --layout 'v'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M ctrl -M shift -k o -m shift -m ctrl" ]
}

@test "h dispatches horizontal split" {
    run main --layout 'h'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M ctrl -M shift -k e -m shift -m ctrl" ]
}

@test "n dispatches next pane" {
    run main --layout 'n'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M logo -M ctrl -k bracketright -m ctrl -m logo" ]
}

@test "p dispatches previous pane" {
    run main --layout 'p'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M logo -M ctrl -k bracketleft -m ctrl -m logo" ]
}

@test "rr dispatches resize right" {
    run main --layout 'rr'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M logo -M ctrl -M alt -M shift -k Right -m shift -m alt -m ctrl -m logo" ]
}

@test "rl dispatches resize left" {
    run main --layout 'rl'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M logo -M ctrl -M alt -M shift -k Left -m shift -m alt -m ctrl -m logo" ]
}

@test "ru dispatches resize up" {
    run main --layout 'ru'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M logo -M ctrl -M alt -M shift -k Up -m shift -m alt -m ctrl -m logo" ]
}

@test "rd dispatches resize down" {
    run main --layout 'rd'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M logo -M ctrl -M alt -M shift -k Down -m shift -m alt -m ctrl -m logo" ]
}

@test "command token types the string and presses Enter" {
    run main --layout '"nvim"'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "nvim
-k Return" ]
}

@test "bind override uses custom wtype args" {
    write_config <<'EOF'
bind = v:wtype -M foo -k bar
EOF
    run main --layout 'v'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M foo -k bar" ]
}

@test "multiple tokens dispatch in sequence" {
    run main --layout 'v n'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M ctrl -M shift -k o -m shift -m ctrl
-M logo -M ctrl -k bracketright -m ctrl -m logo" ]
}

@test "auto-generates default config when missing, runs --layout" {
    rm -f "$GHOSTLAY_CONFIG"
    [[ ! -f "$GHOSTLAY_CONFIG" ]]
    run main --layout 'v'
    [ "$status" -eq 0 ]
    [ "$(wtype_log)" = "-M ctrl -M shift -k o -m shift -m ctrl" ]
}

@test "dies when layout name not found in config" {
    run main nonexistent
    [ "$status" -eq 1 ]
    [ "$output" = "ghostlay: layout not found: nonexistent (use 'ghostlay ls' to list)" ]
}

@test "dies when tokens are empty" {
    run main --layout '   '
    [ "$status" -eq 1 ]
    [ "$output" = "ghostlay: no tokens in layout:    " ]
}
