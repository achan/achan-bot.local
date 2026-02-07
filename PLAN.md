# achan-bot.local — Mac Mini Setup (IaC)

Provision a Mac mini as a dedicated machine for running Claude Code over SSH
with a non-admin `claude` user.

## Goals

- One command (`./setup.sh`) turns a fresh Mac into a ready-to-use bot
- Idempotent — safe to re-run
- Minimal dependencies (only what ships with macOS)

## Project Structure

```
achan-bot.local/
├── setup.sh                  # Main entry point (run as admin)
├── Brewfile                  # Homebrew packages (CLI tools, casks)
├── scripts/
│   ├── 01-xcode-cli.sh       # Xcode Command Line Tools
│   ├── 02-homebrew.sh        # Install/update Homebrew
│   ├── 03-packages.sh        # Install packages from Brewfile
│   ├── 04-create-user.sh     # Create non-admin 'claude' user
│   ├── 05-ssh.sh             # Enable Remote Login, harden sshd
│   ├── 06-dotfiles.sh        # Deploy dotfiles for claude user
│   └── 07-dev-env.sh         # Dev tools (Node.js, runtimes, Claude Code)
├── dotfiles/
│   ├── zshrc
│   ├── gitconfig
│   └── ssh_config
└── config/
    └── sshd_config.d/        # Drop-in sshd hardening
```

## Phases

### Phase 1 — Bootstrap (scripts 01–03)

1. **Xcode CLI Tools** — `xcode-select --install` (gate for everything else)
2. **Homebrew** — Install if missing, update if present
3. **Brewfile** — Declarative package list:
   - CLI: `git`, `gh`, `jq`, `curl`, `wget`, `tmux`, `neovim`, `ripgrep`, `fd`
   - Runtimes: `node` (required for Claude Code), `python`, `ruby`
   - Casks: (optional, e.g. `iterm2` if you ever use the GUI)

### Phase 2 — User & Access (scripts 04–05)

4. **Create `claude` user** (non-admin)
   - Standard user via `sysadminctl`
   - Home directory at `/Users/claude`
   - Add to `staff` group (Homebrew access)
   - Shell set to `/bin/zsh`
5. **Enable SSH (Remote Login)**
   - `systemsetup -setremotelogin on`
   - Restrict SSH to specific users/groups (`AllowUsers`)
   - Disable password auth (key-only) — optional, configurable
   - Deploy authorized_keys for the `claude` user

### Phase 3 — Environment (scripts 06–07)

6. **Dotfiles** — Symlink from repo into `claude` home:
   - `.zshrc` — PATH, aliases, prompt
   - `.gitconfig` — name, email, default branch
   - `.ssh/config` — any outbound SSH config
7. **Dev environment**
   - Install Claude Code (`npm install -g @anthropic-ai/claude-code`)
   - Verify `claude` command works as the `claude` user
   - Set up any API key injection (env var via `.zshrc` or a secrets file)

## Usage

```bash
# Run as an admin user on the Mac mini:
git clone <this-repo>
cd achan-bot.local
./setup.sh

# Then from your other machine:
ssh claude@<mac-mini-ip>
claude
```

## Design Decisions

| Decision | Rationale |
|---|---|
| Bash scripts, not Ansible/Nix | Zero dependencies on a fresh Mac; macOS ships bash/zsh |
| Numbered scripts | Clear execution order; easy to run one step at a time |
| Idempotent checks | Each script checks state before acting (no double-installs) |
| Non-admin `claude` user | Least privilege — Claude Code doesn't need admin access |
| Brewfile | Declarative, diffable, version-controllable package list |
| Dotfiles as symlinks | Edit in repo, changes apply immediately |

## Open Questions

- [ ] Should SSH be key-only or also allow password auth?
- [ ] Any additional Homebrew packages needed?
- [ ] Should we configure macOS energy/sleep settings for always-on use?
- [ ] Firewall rules (beyond SSH)?
- [ ] Automatic updates (Homebrew, macOS)?
