# tmux-scrollback

[![CI](https://github.com/BartSte/tmux-scrollback/actions/workflows/ci.yml/badge.svg)](https://github.com/BartSte/tmux-scrollback/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Open tmux scrollback in a Neovim popup with your existing mappings, plugins, and clipboard provider.

The viewer captures terminal text and ANSI colors, then renders the capture through Neovim's terminal renderer.
It starts in normal mode near the original terminal cursor.
Your normal Neovim settings remain in control.

## Requirements

- Linux or WSL.
- Bash and the standard Linux tools `realpath`, `dirname`, `mktemp`, and `unlink`.
- tmux 3.3 or later.
- Neovim 0.10.4 or later.

CI covers Ubuntu 22.04 and 24.04 with Neovim 0.10.4 and the current stable version.
Local checks also cover tmux 3.8 and Neovim 0.12.6 on Linux.
WSL uses the same Linux tools. Windows-native execution and macOS are outside the supported platforms.
No Neovim plugin installation or changes to your Neovim settings are necessary.

## Setup

Clone the repository into a stable location:

```sh
git clone https://github.com/BartSte/tmux-scrollback.git ~/.local/share/tmux-scrollback
```

Add these bindings to your tmux settings.
Replace `/path/to/tmux-scrollback` with the absolute path to your clone, such as `/home/alice/.local/share/tmux-scrollback`.

```tmux
bind [ run-shell -b '/path/to/tmux-scrollback/bin/tmux-scrollback "#{pane_id}"'
bind M-[ copy-mode
```

Reload your tmux settings:

```sh
tmux source-file ~/.tmux.conf
```

The viewer opens with `prefix [`.
Native tmux copy mode remains available with `prefix Alt-[`.
The prefix comes from your existing tmux settings.
For installation paths with spaces, put double quotes around the script path inside the single-quoted command.

The launcher also accepts a pane ID directly from a shell inside tmux:

```sh
/path/to/tmux-scrollback/bin/tmux-scrollback "$TMUX_PANE"
/path/to/tmux-scrollback/bin/tmux-scrollback --help
```

The popup requires an attached tmux client.

## Copy text

Use your normal Neovim commands inside the viewer.

| Action | Standard Neovim keys |
| --- | --- |
| Copy a word to the unnamed register | `yiw` |
| Copy a word to the system clipboard | `"+yiw` |
| Select characters or lines | `v` or `V` |
| Copy a selection to the system clipboard | `"+y` |
| Close the viewer | `:q` |

Custom mappings from your Neovim settings also apply.
For example, a `+` mapping to `"+` makes `+y` copy to the system clipboard.
The viewer does not add that mapping itself.
The unnamed register belongs to this Neovim process and disappears when the process closes.

## Native tmux clipboard

The optional clipboard command sends text through your normal Neovim clipboard provider.
This keeps Linux and WSL behavior consistent with Neovim.

```tmux
set -s copy-command '/path/to/tmux-scrollback/bin/tmux-scrollback --clipboard'
set -s set-clipboard off
bind -T copy-mode-vi y send-keys -X copy-selection
bind -T copy-mode-vi + switch-client -T scrollback-clipboard
bind -T scrollback-clipboard y send-keys -X copy-pipe
```

In this example, `y` copies to a tmux buffer and `+y` copies to the system clipboard.
Enter and mouse copying also use the configured clipboard command through tmux's default `copy-pipe` bindings.
Each clipboard operation starts a headless Neovim process with your normal settings.

## Rendering limits

- The viewer shows a snapshot, so later terminal output does not appear.
- Unicode symbols depend on your terminal font.
- Indexed and default colors use Neovim's terminal palette.
- Terminal images and graphics do not survive the text capture.
- Physical terminal row breaks remain in the capture and in copied text.
- Only the scrollback that tmux still retains is available.
- Neovim retains at most 100,000 history lines, in addition to the visible terminal rows.

The temporary capture is removed after the popup closes.

## Troubleshooting

If the popup does not open, run `tmux -V` and `nvim --version` to check the requirements.
Make sure that `nvim` is available in the `PATH` that the tmux server uses.
The launcher and its `lua` directory must remain together in the repository.

If your Neovim configuration prevents startup, correct that configuration first.
The viewer loads your normal plugins, mappings, and startup commands.
The tests use an isolated configuration, so they cannot detect conflicts with your plugins.

If clipboard copying fails, run `:checkhealth vim.provider` in your normal Neovim session.
Configure a working clipboard provider for your system.
WSL clipboard access also depends on your Neovim provider configuration.

If older output is absent, increase tmux's `history-limit` before you create a new pane.
tmux cannot recover output that it already discarded.

## Update or uninstall

To update, run `git pull --ff-only` inside your clone.
To uninstall, remove the bindings and the optional clipboard command from your tmux configuration.
Reload the tmux configuration before you delete the clone.

## Development

Run all checks from the repository root:

```sh
bash tests/run.sh
```

The checks cover Unicode, cursor placement, text objects, clipboard routing, newline preservation, and paths with spaces.
Clipboard checks use a test provider and do not overwrite your system clipboard.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for development and bug-report instructions.
See [CHANGELOG.md](CHANGELOG.md) for release changes.

## License

This project uses the [MIT license](LICENSE).
