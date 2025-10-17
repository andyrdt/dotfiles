# Minimal Dotfiles

Bare essentials: nice-looking terminal + Claude Code setup.

## Install vs Deploy

**install.sh** - Downloads and installs software (run once per machine)
- Installs zsh, curl, git
- Installs oh-my-zsh and powerlevel10k theme
- Installs Claude Code
- Optionally configures GitHub authentication

**deploy.sh** - Links your configs (run after install, safe to re-run anytime)
- Creates `~/.zshrc` that points to your zsh config
- Creates `~/.tmux.conf` that points to your tmux config
- Copies `claude.md` to `~/.config/claude/claude.md` (where Claude Code reads it)
- Sets zsh as your default shell

**When to use each:**
- First time on a new machine: `./install.sh` then `./deploy.sh`
- Updating configs on existing machine: just `./deploy.sh`
- Moving this repo to a new location: just `./deploy.sh` to update the paths

## Quick Start

```bash
./install.sh    # First time only
./deploy.sh     # Every time you move the repo or update configs
exec zsh        # Start using it
```

## What You Get

**Terminal appearance:**
- Powerlevel10k theme (makes terminal look professional)
- Git integration (shows branch, status in prompt)
- Random inspirational quote on each shell startup

**Useful features:**
- Git tab completion (type `git che<tab>` → `git checkout`)
- Smart history search (type `git`, press up arrow, cycles through git commands only)
- 10,000 command history shared across all terminals

**Tools:**
- Claude Code CLI with your custom instructions

**Optional:**
- GitHub authentication (won't ask for password on push/pull)

## Files

```
dotfiles/
├── install.sh              # Installs software
├── deploy.sh               # Links configs to home directory
├── setup_github.sh         # GitHub authentication setup
├── claude.md               # Your custom Claude Code instructions
├── config/
│   ├── zshrc.sh           # ZSH config (theme + history + git completion)
│   ├── aliases.sh         # Your custom aliases (currently empty)
│   ├── tmux.conf          # Tmux config (mouse support + colors)
│   └── p10k.zsh           # Powerlevel10k theme settings
└── start/
    ├── quotes.json        # Inspirational quotes collection
    └── display_quote.sh   # Random quote display script
```

## Customization

**Add aliases** - Edit `config/aliases.sh` (has examples in comments)

**Customize ZSH** - Edit `config/zshrc.sh`

**Customize Claude Code** - Edit `claude.md`, then run `./deploy.sh` to copy it

**Add your own quotes** - Edit `start/quotes.json` with your favorite quotes:
```json
{
  "quote": "Your inspiring quote here",
  "author": "Author Name"
}
```

## Where Things Go

After running deploy.sh:
- `~/.zshrc` → sources this repo's `config/zshrc.sh`
- `~/.tmux.conf` → sources this repo's `config/tmux.conf`
- `~/.config/claude/claude.md` → copy of your `claude.md`
- `~/.git-credentials` → your GitHub token (if configured)

This means you can edit files in this repo and changes take effect immediately (just restart your shell).

## Credit

Based on [jplhughes/dotfiles](https://github.com/jplhughes/dotfiles).
