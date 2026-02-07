# achan-bot.local

Provision a Mac mini as a dev/server box. One script sets up everything — then
SSH in, work in tmux, run app servers, and test from your local browser over
HTTPS.

```
┌──────────────────────┐  SSH tunnel   ┌──────────────────────────────┐
│  achan.local          │ ───────────→ │  achan-bot.local (Mac mini)   │
│                       │              │                               │
│  browser:             │  tunneled    │  claude@ (non-admin)          │
│  https://localhost:3000├─────────────│  app servers in tmux          │
│  https://localhost:4000├─────────────│  worktrees, multiple projects │
└──────────────────────┘              └──────────────────────────────┘
```

## Quick start

On the Mac mini, logged in as your admin user:

```bash
git clone <this-repo>
cd achan-bot.local
cp .env.example .env
# Edit .env — at minimum set GITHUB_USER
vi .env
./setup.sh
```

## Configuration

Copy `.env.example` to `.env` and fill in:

| Variable | Required | Description |
|---|---|---|
| `GITHUB_USER` | yes | Your GitHub username — SSH keys and git identity are fetched automatically |
| `BOT_USER` | | Non-admin user to create (default: `claude`) |
| `BOT_USER_FULLNAME` | | Display name (default: `Claude`) |
| `BOT_HOSTNAME` | | Hostname for display (default: `achan-bot.local`) |
| `WORKSPACE_DIR` | | Project directory under home (default: `src`) |

See `.env.example` for the full list including cert configuration.

## What it does

| Script | Purpose |
|---|---|
| `01-xcode-cli.sh` | Install Xcode Command Line Tools |
| `02-homebrew.sh` | Install or update Homebrew |
| `03-packages.sh` | Install packages from Brewfile |
| `04-create-user.sh` | Create non-admin bot user with `~/src/` |
| `05-ssh.sh` | Enable Remote Login, fetch SSH keys from GitHub |
| `06-dotfiles.sh` | Symlink dotfiles, set git identity from GitHub |
| `07-dev-env.sh` | Verify all tools are installed |
| `08-mkcert.sh` | Generate trusted localhost TLS certs |

All scripts are idempotent — safe to re-run.

## Installed tools

From the Brewfile: `git`, `gh`, `jq`, `curl`, `wget`, `tmux`, `neovim`,
`ripgrep`, `fd`, `mkcert`, `nss`, and `claude-code` (cask).

Runtimes (node, ruby, python, etc.) are managed per-project, not globally.

## Connecting

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

**One-time step on achan.local** — trust the CA so your browser accepts
the certs:

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
