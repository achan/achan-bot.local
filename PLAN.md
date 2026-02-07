# achan-bot.local — Mac Mini Setup (IaC)

Provision a Mac mini (achan-bot.local) as a multi-project dev/server box.
You SSH in from achan.local, work across multiple projects and worktrees,
run app servers in tmux, and test from achan.local's browser.

## Workflow

```
┌──────────────────┐     SSH      ┌──────────────────────────────────┐
│  achan.local      │ ──────────→ │  achan-bot.local (Mac mini)       │
│  (your machine)   │             │                                   │
│                   │   browser   │  claude@achan-bot.local            │
│  test apps here ←─┼─────────── │                                   │
│                   │  :3000      │  project-a server                  │
│                   │  :3001      │  project-a feature branch server   │
│                   │  :4000      │  project-b server                  │
└──────────────────┘  (ports)    └──────────────────────────────────┘

1. Admin runs ./setup.sh once on the Mac mini
2. SSH in: ssh claude@achan-bot.local
3. Work in tmux, multiple projects, multiple worktrees
4. Test from achan.local browser (http://achan-bot.local:PORT)
```

## Goals

- One command (`./setup.sh`) run by the admin user sets everything up
- Creates a non-admin `claude` user for day-to-day SSH work
- Multiple projects with multiple worktrees running app servers on different ports
- tmux for persistent sessions
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
│   ├── 05-ssh.sh             # Enable Remote Login, configure for claude user
│   ├── 06-dotfiles.sh        # Deploy dotfiles for claude user
│   └── 07-dev-env.sh         # Dev tools (Node.js, Claude Code CLI)
├── dotfiles/
│   ├── zshrc                 # Shell config (PATH, aliases)
│   ├── gitconfig             # Git config
│   └── tmux.conf             # tmux configuration
└── config/
    └── sshd_config.d/        # Drop-in sshd config
```

## Phases

### Phase 1 — Bootstrap (scripts 01–03)

Run as the admin user. Installs system-level tooling.

1. **Xcode CLI Tools** — `xcode-select --install` (gate for everything else)
2. **Homebrew** — Install if missing, update if present
3. **Brewfile** — Declarative package list:
   - CLI: `git`, `gh`, `jq`, `curl`, `wget`, `tmux`, `neovim`, `ripgrep`, `fd`
   - Runtimes: `node` (required for Claude Code)
   - Casks: as needed

### Phase 2 — User & Access (scripts 04–05)

Create the `claude` user and open SSH access.

4. **Create `claude` user** (non-admin)
   - Standard user via `sysadminctl`
   - Home directory at `/Users/claude`
   - Add to `staff` group (Homebrew access)
   - Shell set to `/bin/zsh`
   - Create `~/src/` directory
5. **Enable SSH (Remote Login)**
   - `systemsetup -setremotelogin on`
   - Allow the `claude` user to connect via SSH
   - Deploy authorized_keys for the `claude` user

### Phase 3 — Environment (scripts 06–07)

Configure the `claude` user's environment.

6. **Dotfiles** — Copy into `/Users/claude`:
   - `.zshrc` — PATH (include Homebrew), aliases, prompt
   - `.tmux.conf` — sensible defaults, status bar
   - `.gitconfig` — name, email, default branch
7. **Dev environment** (run as `claude` user via `sudo -u claude`)
   - Install Claude Code (`npm install -g @anthropic-ai/claude-code`)
   - Verify tools work
   - Ensure Homebrew-installed tools are on PATH

## Usage

```bash
# 1. On achan-bot.local, logged in as your admin user:
git clone <this-repo>
cd achan-bot.local
./setup.sh

# 2. From achan.local, SSH in:
ssh claude@achan-bot.local

# 3. Work in tmux, clone projects, use worktrees as each project defines.
#    App servers bind to various ports.

# 4. Test from achan.local:
#    http://achan-bot.local:3000
#    http://achan-bot.local:4000
#    etc.
```

## Design Decisions

| Decision | Rationale |
|---|---|
| Bash scripts, not Ansible/Nix | Zero dependencies on a fresh Mac; macOS ships bash/zsh |
| Numbered scripts | Clear execution order; easy to run one step at a time |
| Idempotent checks | Each script checks state before acting (no double-installs) |
| Non-admin `claude` user | Least privilege for daily work |
| Brewfile | Declarative, diffable, version-controllable package list |
| No worktree tooling here | Each project brings its own worktree conventions |
| tmux | Persistent sessions survive SSH disconnects |

## Open Questions

- [ ] Should we configure macOS energy/sleep settings for always-on use?
- [ ] Any additional Homebrew packages needed?
- [ ] Firewall rules (beyond SSH)?
- [ ] Automatic updates (Homebrew, macOS)?
- [ ] tmux auto-attach on SSH login?
