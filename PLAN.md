# Mac Bot Provisioning (IaC)

Provision a Mac bot user for dev work. Supports two modes:

- **Remote** — a non-admin user on a dedicated machine (e.g. Mac mini) that you
  SSH into from another machine, with SSH tunnels for app server access.
- **Local** — a Standard user on your own Mac for isolated work, no SSH setup.

Set `BOT_TYPE=remote` or `BOT_TYPE=local` in `.env` to choose.

## Workflow

### Remote bot

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

### Local bot

```
1. Admin runs ./setup.sh on the same machine
2. su - claude (or log in as the bot user)
3. Work in tmux, run app servers, etc.
```

Browser APIs (camera, mic, WebUSB, etc.) require a secure context.
SSH tunnels encrypt transport but the browser still sees `http://localhost`.
We use **mkcert** to generate locally-trusted certs for `localhost` so
app servers can serve HTTPS and satisfy secure context requirements.

## Goals

- One command (`./setup.sh`) run by the admin user sets everything up
- Creates a non-admin `claude` user for day-to-day work
- Two bot types: `remote` (with SSH) and `local` (no SSH)
- HTTPS via mkcert localhost certs (secure context for browser device APIs)
- SSH tunnels for remote access — no exposing ports on the network
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
│   ├── 05-ssh.sh             # Enable Remote Login (remote only — skipped for local)
│   ├── 06-dotfiles.sh        # Deploy dotfiles for claude user
│   ├── 07-dev-env.sh         # Verify tools, PATH setup
│   └── 08-mkcert.sh          # Generate localhost TLS certs for claude user
├── dotfiles/
│   ├── zshrc                 # Shell config (PATH, aliases)
│   ├── gitconfig             # Git config
│   └── tmux.conf             # tmux configuration
└── config/
    └── sshd_config.d/        # Drop-in sshd config (remote only)
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

Create the bot user and (for remote bots) open SSH access.

4. **Create `claude` user** (non-admin)
   - Standard user via `sysadminctl`
   - Home directory at `/Users/claude`
   - Add to `staff` group (Homebrew access)
   - Shell set to `/bin/zsh`
   - Create `~/repos/` directory
5. **Enable SSH (Remote Login)** — remote only, skipped when `BOT_TYPE=local`
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

### Manual step on achan.local (remote only, one-time)

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

### Remote bot

```bash
# 1. On achan-bot.local, logged in as your admin user:
git clone <this-repo>
cd achan-bot.local
cp .env.example .env
# Set BOT_TYPE="remote", GITHUB_USER, ADMIN_GITHUB_USER
vi .env
./setup.sh

# 2. From achan.local, SSH in with port forwarding:
ssh -L 3000:localhost:3000 -L 3001:localhost:3001 -L 4000:localhost:4000 \
    claude@achan-bot.local

# 3. Work in tmux, clone projects, run app servers with HTTPS
```

### Local bot

```bash
# 1. On your Mac, logged in as your admin user:
git clone <this-repo>
cd achan-bot.local
cp .env.example .env
# Set BOT_TYPE="local", GITHUB_USER
vi .env
./setup.sh

# 2. Switch to the bot user:
su - claude

# 3. Work in tmux, clone projects, run app servers
```

## Design Decisions

| Decision | Rationale |
|---|---|
| Bash scripts, not Ansible/Nix | Zero dependencies on a fresh Mac; macOS ships bash/zsh |
| Numbered scripts | Clear execution order; easy to run one step at a time |
| Idempotent checks | Each script checks state before acting (no double-installs) |
| Non-admin `claude` user | Least privilege for daily work |
| `BOT_TYPE` conditional | Same scripts for remote and local — only SSH setup differs |
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
