# Dotfiles

Personal dev environment. Every path under this repo is symlinked into `$HOME`
by `./link_dotfiles.zsh`. After any change, re-run the script to update links.

NEVER edit dotfiles directly in `$HOME` — always make changes in this repo and
re-run `./link_dotfiles.zsh` to apply them.

Zsh plugins are git submodules — run `git submodule update --init --recursive`
after a fresh clone.

## Structure

| Path | Tool | Links to |
|------|------|----------|
| `.config/git/` | Git (delta pager) | `~/.config/git` |
| `.config/nvim/` | Neovim (lazy.nvim) | `~/.config/nvim` |
| `.config/zsh/` | Zsh (modular: aliases, completion, fzf, git, docker, functions) | `~/.config/zsh` |
| `.config/starship.toml` | Starship prompt | `~/.config/starship.toml` |
| `.config/zellij/` | Zellij (primary multiplexer, tmux-like prefix) | `~/.config/zellij` |
| `.config/wezterm/` | WezTerm terminal | `~/.config/wezterm` |
| `.claude/` | Claude Code (settings, statusline, skills) | `~/.claude/` (select files) |
| `claude-plugins/` | Claude Code local plugins (neovim, perf) | `~/.claude/local-plugins` |
| `.zshenv` | Zsh env bootstrap (sets ZDOTDIR) | `~/.zshenv` |

## Conventions

- XDG Base Directory layout — configs in `~/.config`, state in `~/.local/state`
- Catppuccin Macchiato theme and JetBrainsMono Nerd Font everywhere
- See `README.md` for full installation instructions (macOS, Ubuntu, CentOS)
