# Contribute

Use GitHub issues for bug reports and feature requests.
Before you report an error, read the troubleshooting section in the [README](README.md#troubleshooting).

Include these details in a bug report:

- Your operating system, terminal, tmux version, and Neovim version.
- The steps that reproduce the error.
- The expected result and the actual result.
- Relevant configuration and error messages, without private terminal content.

## Development

Clone the repository and create a branch for your change:

```sh
git clone https://github.com/BartSte/tmux-scrollback.git
cd tmux-scrollback
git switch -c my-change
```

Install the requirements from the README.
Install ShellCheck for shell lint checks.
Run the checks before you open a pull request:

```sh
bash tests/run.sh
```

CI requires ShellCheck and runs the suite on Ubuntu 22.04 and 24.04.
Each operating system uses Neovim 0.10.4 and the current stable version.
Clipboard tests use a test provider and preserve your system clipboard.
The tmux integration test uses a separate server and preserves your normal sessions.

Keep each change focused on one purpose.
Add a regression test for changes to capture, rendering, or clipboard behavior.
Update the documentation when the behavior changes.
Use Conventional Commits, such as `fix: preserve cursor position`.

## Project structure

| Path | Purpose |
| --- | --- |
| `bin/tmux-scrollback` | Capture a pane, open the popup, or copy standard input. |
| `lua/tmux_scrollback.lua` | Render terminal text and use the Neovim clipboard provider. |
| `tests/run.sh` | Run shell checks and the test suite. |
| `tests/test_scrollback.lua` | Check terminal rendering, cursor placement, and Neovim behavior. |
| `tests/test_tmux.sh` | Check capture and popup arguments through an isolated tmux server. |

Contributions use the [MIT license](LICENSE).
