#!/usr/bin/env bash
set -euo pipefail

repository=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_directory=$(mktemp -d)
export TEST_TMUX_SOCKET="$test_directory/socket"
export TEST_TMUX_DIRECTORY="$test_directory/pane with spaces"
export TEST_CAPTURE_RECORD="$test_directory/capture-path"
export TEST_REAL_TMUX TEST_REAL_NVIM
TEST_REAL_TMUX=$(command -v tmux)
TEST_REAL_NVIM=$(command -v nvim)

cleanup() {
    "$TEST_REAL_TMUX" -S "$TEST_TMUX_SOCKET" kill-server 2>/dev/null || true
    rm -rf -- "$test_directory"
}
trap cleanup EXIT
mkdir -p "$test_directory/bin" "$TEST_TMUX_DIRECTORY"

# Use a real, isolated tmux server. Replace only the interactive popup display.
cat > "$test_directory/bin/tmux" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
if [[ $1 != display-popup ]]; then
    exec "$TEST_REAL_TMUX" -S "$TEST_TMUX_SOCKET" "$@"
fi
shift
while [[ $# -gt 1 ]]; do
    case "$1" in
        -E|-B) shift ;;
        -w|-h) [[ $2 == 100% ]]; shift 2 ;;
        -d) [[ $2 == "$TEST_TMUX_DIRECTORY" ]]; shift 2 ;;
        -e) export "${2?}"; shift 2 ;;
        *) printf 'Unexpected popup argument: %s\n' "$1" >&2; exit 1 ;;
    esac
done
[[ -f $NVIM_SCROLLBACK_FILE ]]
[[ $NVIM_SCROLLBACK_ROW -gt 0 ]]
[[ $NVIM_SCROLLBACK_COLUMN -ge 0 ]]
printf '%s' "$NVIM_SCROLLBACK_FILE" > "$TEST_CAPTURE_RECORD"
"$TEST_REAL_TMUX" -S "$TEST_TMUX_SOCKET" capture-pane -p -e -S - -t "$TEST_PANE" | cmp - "$NVIM_SCROLLBACK_FILE"
bash -c "$1"
exit "${TEST_POPUP_STATUS:-0}"
BASH

# Run the actual --view command without a UI or user configuration.
cat > "$test_directory/bin/nvim" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
exec "$TEST_REAL_NVIM" --headless -u NONE "$@" \
    -c 'lua if not vim.wait(1000, function() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("scrollback%-integration") ~= nil end) then vim.cmd("cquit 1") end' \
    -c 'qa!'
BASH
chmod +x "$test_directory/bin/tmux" "$test_directory/bin/nvim"
export PATH="$test_directory/bin:$PATH"
export TEST_PANE
TEST_PANE=$(tmux -f /dev/null new-session -d -s scrollback-test -x 80 -y 24 \
    -c "$TEST_TMUX_DIRECTORY" -P -F '#{pane_id}' \
    "printf '\033[31mscrollback\033[0m scrollback-integration\n'; exec sleep 60")

ready=false
for ((attempt = 0; attempt < 100; attempt++)); do
    if tmux capture-pane -p -t "$TEST_PANE" | grep -q scrollback-integration; then
        ready=true
        break
    fi
    sleep 0.05
done
[[ $ready == true ]]

"$repository/bin/tmux-scrollback" "$TEST_PANE"
capture_file=$(cat "$TEST_CAPTURE_RECORD")
[[ ! -e $capture_file ]]

# A failed popup must return its status and remove the temporary capture.
if TEST_POPUP_STATUS=7 "$repository/bin/tmux-scrollback" "$TEST_PANE"; then
    printf 'The launcher ignored the popup failure.\n' >&2
    exit 1
else
    status=$?
    [[ $status -eq 7 ]]
fi
capture_file=$(cat "$TEST_CAPTURE_RECORD")
[[ ! -e $capture_file ]]
printf 'tmux capture, popup launch, and cleanup tests passed.\n'
