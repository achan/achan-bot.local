# achan-bot.local — Mac Mini Setup (IaC)

Provision a Mac mini so the admin user can run Claude Code on the web,
which SSHes into a dedicated non-admin `claude` user.

## Workflow

```
┌──────────────┐       SSH        ┌──────────────────────┐
│  Browser      │ ──────────────→ │  Mac mini             │
│  Claude Code  │                 │                       │
│  on the web   │                 │  claude@mac-mini      │
└──────────────┘                  │  (non-admin user)     │
                                  └──────────────────────┘

You (admin) run ./setup.sh once on the Mac mini.
Claude Code on the web connects as the 'claude' user via SSH.
```

## Goals

- One command (`./setup.sh`) run by the admin user sets everything up
- Creates a non-admin `claude` user for Claude Code to SSH into
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
│   ├── zshrc
│   ├── gitconfig
│   └── ssh_config
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
5. **Enable SSH (Remote Login)**
   - `systemsetup -setremotelogin on`
   - Allow the `claude` user to connect via SSH
   - Deploy authorized_keys for the `claude` user

### Phase 3 — Environment (scripts 06–07)

Configure the `claude` user's environment so Claude Code works out of the box.

6. **Dotfiles** — Copy into `/Users/claude`:
   - `.zshrc` — PATH (include Homebrew), aliases, prompt
   - `.gitconfig` — name, email, default branch
   - `.ssh/config` — outbound SSH config if needed
7. **Dev environment** (run as `claude` user via `sudo -u claude`)
   - Install Claude Code (`npm install -g @anthropic-ai/claude-code`)
   - Verify `claude` command works
   - Ensure Homebrew-installed tools are on PATH

## Usage

```bash
# 1. On your Mac mini, logged in as your admin user:
git clone <this-repo>
cd achan-bot.local
./setup.sh

# 2. From your browser:
#    Use Claude Code on the web, pointed at claude@<mac-mini-ip>

# 3. Or test manually:
ssh claude@localhost
claude --version
```

## Design Decisions

| Decision | Rationale |
|---|---|
| Bash scripts, not Ansible/Nix | Zero dependencies on a fresh Mac; macOS ships bash/zsh |
| Numbered scripts | Clear execution order; easy to run one step at a time |
| Idempotent checks | Each script checks state before acting (no double-installs) |
| Non-admin `claude` user | Least privilege — Claude Code doesn't need admin |
| Brewfile | Declarative, diffable, version-controllable package list |
| Admin runs setup, claude user is the target | Clean separation of provisioning vs. runtime |

## Open Questions

- [ ] Should we configure macOS energy/sleep settings for always-on use?
- [ ] Any additional Homebrew packages needed?
- [ ] Firewall rules (beyond SSH)?
- [ ] Automatic updates (Homebrew, macOS)?
