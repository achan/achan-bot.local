# achan-bot.local

Provision a Mac bot user — either a **remote** bot you SSH into (e.g. on a
Mac mini) or a **local** Standard user on the same machine. One script sets
up everything.

## Bot types

| Type | Description | Use case |
|------|-------------|----------|
| `remote` (default) | Enables SSH, fetches authorized keys, configures Remote Login | Dedicated Mac mini you SSH into from another machine |
| `local` | Skips SSH setup entirely | Standard user on your own Mac for isolated work |

Set `BOT_TYPE` in `.env` to choose.

## Quick start

Logged in as your admin user:

```bash
git clone <this-repo>
cd achan-bot.local
cp .env.example .env
# Edit .env — at minimum set GITHUB_USER and BOT_TYPE
vi .env
./setup.sh
```

### Remote bot

```
┌──────────────────────┐  SSH tunnel   ┌──────────────────────────────┐
│  achan.local          │ ───────────→ │  achan-bot.local (Mac mini)   │
│                       │              │                               │
│  browser:             │  tunneled    │  claude@ (non-admin)          │
│  https://localhost:3000├─────────────│  app servers in tmux          │
│  https://localhost:4000├─────────────│  worktrees, multiple projects │
└──────────────────────┘              └──────────────────────────────┘
```

```bash
ssh -L 3000:localhost:3000 -L 4000:localhost:4000 claude@achan-bot.local
```

### Local bot

```bash
su - claude
# Work in tmux, run app servers, etc.
```

## Configuration

Copy `.env.example` to `.env` and fill in:

| Variable | Required | Description |
|---|---|---|
| `BOT_TYPE` | | `remote` (default) or `local` |
| `GITHUB_USER` | yes | GitHub username — SSH keys and git identity are fetched automatically |
| `ADMIN_GITHUB_USER` | | GitHub username of admin/owner for SSH access (remote only) |
| `BOT_USER` | | Non-admin user to create (default: `claude`) |
| `BOT_USER_FULLNAME` | | Display name (default: `Claude`) |
| `BOT_HOSTNAME` | | Hostname for display (default: `achan-bot.local`) (remote only) |
| `BOT_SSH_PUBLIC_KEY` | | Fallback SSH public key for authorized_keys (remote only) |
| `WORKSPACE_DIR` | | Project directory under home (default: `repos`) |

See `.env.example` for the full list including cert configuration.

## What it does

| Script | Purpose |
|---|---|
| `01-xcode-cli.sh` | Install Xcode Command Line Tools |
| `02-homebrew.sh` | Install or update Homebrew |
| `03-packages.sh` | Install packages from Brewfile |
| `04-create-user.sh` | Create non-admin bot user with `~/repos/` |
| `05-ssh.sh` | Enable Remote Login, fetch SSH keys from GitHub (remote only — skipped for local) |
| `06-dotfiles.sh` | Symlink dotfiles, set git identity from GitHub |
| `07-dev-env.sh` | Verify all tools are installed |
| `08-mkcert.sh` | Generate trusted localhost TLS certs |

All scripts are idempotent — safe to re-run.

## Installed tools

From the Brewfile: `git`, `gh`, `jq`, `curl`, `wget`, `tmux`, `neovim`,
`ripgrep`, `fd`, `mkcert`, `nss`, and `claude-code` (cask).

Runtimes (node, ruby, python, etc.) are managed per-project, not globally.

## Connecting (remote)

From achan.local, SSH in with port forwarding for your app servers:

```bash
ssh -L 3000:localhost:3000 -L 4000:localhost:4000 claude@achan-bot.local
```

Then open `https://localhost:3000` in your browser.

## HTTPS (secure context)

Browser device APIs (camera, mic, WebUSB, etc.) require a secure context.
The setup generates locally-trusted TLS certs via mkcert. App servers use
these certs (exposed as `$LOCALHOST_CERT` and `$LOCALHOST_KEY` env vars)
to serve HTTPS.

**One-time step on achan.local** (remote only) — trust the CA so your browser
accepts the certs:

```bash
scp claude@achan-bot.local:~/.local/share/mkcert/rootCA.pem /tmp/
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain /tmp/rootCA.pem
```

## Dotfiles

Symlinked into the bot user's home directory:

- `.zshrc` — Homebrew PATH, history, aliases, sources `~/.botenv` for cert paths
- `.gitconfig` — rebase on pull, auto setup remote, nvim editor
- `.tmux.conf` — `C-a` prefix, mouse support, 256 color
