# tmux-scrollback

Open tmux scrollback in a Neovim popup with your existing mappings, plugins, and clipboard provider.

The viewer captures terminal text and ANSI colors, then renders the capture through Neovim's terminal renderer.
It starts in normal mode near the original terminal cursor.
Your normal Neovim settings remain in control.

## Requirements

- Linux or WSL.
- Bash and the standard Linux tools `realpath`, `dirname`, `mktemp`, and `unlink`.
- tmux with `display-popup` and its `-e` option.
- Neovim with `nvim_open_term()`.

The current checks use tmux 3.8 and Neovim 0.12.6.
No Neovim plugin installation or changes to your Neovim settings are necessary.

## Setup

Keep the repository in a stable location.
Add these bindings to your tmux settings.
Replace `/path/to/tmux-scrollback` with the absolute path to the repository.

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

The temporary capture is removed after the popup closes.

## Development

Run all checks from the repository root:

```sh
bash tests/run.sh
```

The checks cover Unicode, cursor placement, text objects, clipboard routing, newline preservation, and paths with spaces.
Clipboard checks use a test provider and do not overwrite your system clipboard.
