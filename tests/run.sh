#!/usr/bin/env bash
set -euo pipefail

repository=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for script in "$repository/bin/tmux-scrollback" "$repository/tests/run.sh"; do
    bash -n "$script"
done
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$repository/bin/tmux-scrollback" "$repository/tests/run.sh"
fi
nvim --headless -u NONE -i NONE -l "$repository/tests/test_scrollback.lua"

test_directory=$(mktemp -d)
relocated_repository="$test_directory/repository with spaces"
cleanup() {
    local file
    for file in \
        "$relocated_repository/bin/tmux-scrollback" \
        "$relocated_repository/lua/tmux_scrollback.lua" \
        "$test_directory/config/nvim/init.lua" \
        "$test_directory/expected" "$test_directory/actual" \
        "$test_directory/error" "$test_directory/launcher link"; do
        if [[ -e $file || -L $file ]]; then
            unlink -- "$file"
        fi
    done
    rmdir -- "$relocated_repository/bin" "$relocated_repository/lua" \
        "$relocated_repository" "$test_directory/config/nvim" \
        "$test_directory/config" "$test_directory"
}
mkdir -p "$relocated_repository/bin" "$relocated_repository/lua" "$test_directory/config/nvim"
trap cleanup EXIT
cp -- "$repository/bin/tmux-scrollback" "$relocated_repository/bin/"
cp -- "$repository/lua/tmux_scrollback.lua" "$relocated_repository/lua/"
ln -s -- "$relocated_repository/bin/tmux-scrollback" "$test_directory/launcher link"

cat > "$test_directory/config/nvim/init.lua" <<'LUA'
vim.g.clipboard = {
    name = "Launcher test provider",
    copy = {
        ["+"] = function(lines)
            vim.fn.writefile(lines, vim.env.CLIP_TEST_OUTPUT, "b")
        end,
        ["*"] = function() error("Unexpected register") end,
    },
    paste = {
        ["+"] = function() return { "" }, "v" end,
        ["*"] = function() return { "" }, "v" end,
    },
}
LUA

copy_with_test_provider() {
    XDG_CONFIG_HOME="$test_directory/config" NVIM_APPNAME=nvim \
        CLIP_TEST_OUTPUT="$test_directory/actual" \
        "$test_directory/launcher link" --clipboard < "$test_directory/expected"
    cmp -- "$test_directory/expected" "$test_directory/actual"
}

printf 'café 🌍\nsecond line\n' > "$test_directory/expected"
copy_with_test_provider
printf 'text without a final newline' > "$test_directory/expected"
copy_with_test_provider
: > "$test_directory/expected"
copy_with_test_provider

for argument in '' invalid; do
    if "$relocated_repository/bin/tmux-scrollback" "$argument" > "$test_directory/error" 2>&1; then
        printf 'Invalid pane argument was accepted: %s\n' "$argument" >&2
        exit 1
    else
        status=$?
        if [[ $status -ne 2 ]]; then
            printf 'Expected usage exit status 2, received %s.\n' "$status" >&2
            exit 1
        fi
    fi
done
printf 'Launcher and clipboard tests passed.\n'
