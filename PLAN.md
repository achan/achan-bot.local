# achan-bot.local — Mac Mini Setup (IaC)

Provision a Mac mini (achan-bot.local) as a multi-project dev/server box.
You SSH in from achan.local, work across multiple projects and worktrees,
run app servers in tmux, and test from achan.local's browser via SSH tunnels.

## Workflow

```
┌──────────────────────┐  SSH tunnel   ┌──────────────────────────────┐
│  achan.local          │ ───────────→ │  achan-bot.local (Mac mini)   │
│  (your machine)       │              │                               │
│                       │              │  claude@achan-bot.local        │
│  browser:             │  tunneled    │                               │
│  https://localhost:3000├─────────────│  app server :3000              │
│  https://localhost:3001├─────────────│  app server :3001              │
│  https://localhost:4000├─────────────│  app server :4000              │
└──────────────────────┘              └──────────────────────────────┘

1. Admin runs ./setup.sh once on the Mac mini
2. SSH in with tunnels: ssh -L 3000:localhost:3000 ... claude@achan-bot.local
3. Work in tmux, multiple projects, multiple worktrees
4. Test from achan.local browser (https://localhost:PORT)
```

Browser APIs (camera, mic, WebUSB, etc.) require a secure context.
SSH tunnels encrypt transport but the browser still sees `http://localhost`.
We use **mkcert** to generate locally-trusted certs for `localhost` so
app servers can serve HTTPS and satisfy secure context requirements.

## Goals

- One command (`./setup.sh`) run by the admin user sets everything up
- Creates a non-admin `claude` user for day-to-day SSH work
- HTTPS via mkcert localhost certs (secure context for browser device APIs)
- SSH tunnels for access from achan.local — no exposing ports on the network
- Multiple projects with multiple worktrees running app servers on different ports
- tmux for persistent sessions
- Idempotent — safe to re-run
- Minimal dependencies (only what ships with macOS + Homebrew)

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
│   ├── 07-dev-env.sh         # Verify tools, PATH setup
│   └── 08-mkcert.sh          # Generate localhost TLS certs for claude user
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
   - Casks: `claude-code`
   - TLS: `mkcert`, `nss` (for cert trust)
   - Runtimes: none — managed per-project

### Phase 2 — User & Access (scripts 04–05)

Create the `claude` user and open SSH access.

4. **Create `claude` user** (non-admin)
   - Standard user via `sysadminctl`
   - Home directory at `/Users/claude`
   - Add to `staff` group (Homebrew access)
   - Shell set to `/bin/zsh`
   - Create `~/repos/` directory
5. **Enable SSH (Remote Login)**
   - `systemsetup -setremotelogin on`
   - Allow the `claude` user to connect via SSH
   - Deploy authorized_keys for the `claude` user

### Phase 3 — Environment (scripts 06–08)

Configure the `claude` user's environment.

6. **Dotfiles** — Copy into `/Users/claude`:
   - `.zshrc` — PATH (include Homebrew), aliases, prompt
   - `.tmux.conf` — sensible defaults, status bar
   - `.gitconfig` — name, email, default branch
7. **Dev environment** (run as `claude` user via `sudo -u claude`)
   - Claude Code already installed via Brewfile (`brew install --cask claude-code`)
   - Verify `claude` command works
   - Ensure Homebrew-installed tools are on PATH
   - Runtimes (node, ruby, etc.) are managed per-project, not installed globally
8. **mkcert setup** (run as `claude` user)
   - `mkcert -install` (install local CA)
   - `mkcert localhost 127.0.0.1 ::1` (generate cert + key)
   - Store certs in `~/.local/share/mkcert/` (or similar well-known path)
   - App servers reference these certs to serve HTTPS

### Manual step on achan.local (one-time)

To trust the certs in your browser on achan.local, copy the CA root cert
from achan-bot.local and install it:

```bash
# From achan.local:
scp claude@achan-bot.local:~/.local/share/mkcert/rootCA.pem /tmp/
# Then install it in your system keychain / browser trust store
```

This is a one-time step. After this, `https://localhost:*` via SSH tunnels
is trusted by your browser.

## Usage

```bash
# 1. On achan-bot.local, logged in as your admin user:
git clone <this-repo>
cd achan-bot.local
./setup.sh

# 2. From achan.local, SSH in with port forwarding:
ssh -L 3000:localhost:3000 -L 3001:localhost:3001 -L 4000:localhost:4000 \
    claude@achan-bot.local

# 3. Work in tmux, clone projects, run app servers with HTTPS:
#    App servers use the mkcert localhost certs to serve HTTPS.

# 4. Test from achan.local browser:
#    https://localhost:3000
#    https://localhost:4000
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
| SSH tunnels | Encrypted access without exposing ports on the network |
| mkcert for localhost | Browser secure context for device APIs (camera, mic, etc.) |
| No worktree tooling here | Each project brings its own worktree conventions |
| tmux | Persistent sessions survive SSH disconnects |

## Open Questions

- [ ] Should we configure macOS energy/sleep settings for always-on use?
- [ ] Any additional Homebrew packages needed?
- [ ] Firewall rules (beyond SSH)?
- [ ] Automatic updates (Homebrew, macOS)?
- [ ] tmux auto-attach on SSH login?
