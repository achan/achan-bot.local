# achan-bot.local — Mac Mini Setup (IaC)

Provision a Mac mini (achan-bot.local) as a multi-project dev/server box.
You SSH in from achan.local, work across multiple projects using git worktrees,
run app servers in tmux, and test from achan.local's browser.

## Workflow

```
┌──────────────────┐     SSH      ┌──────────────────────────────────┐
│  achan.local      │ ──────────→ │  achan-bot.local (Mac mini)       │
│  (your machine)   │             │                                   │
│                   │   browser   │  claude@achan-bot.local            │
│  test apps here ←─┼─────────── │                                   │
│                   │  :3000      │  ~/src/project-a/main/  (server)  │
│                   │  :3001      │  ~/src/project-a/feature-x/       │
│                   │  :4000      │  ~/src/project-b/main/  (server)  │
│                   │  :4001      │  ~/src/project-b/fix-y/           │
└──────────────────┘             └──────────────────────────────────┘

1. Admin runs ./setup.sh once on the Mac mini
2. SSH in: ssh claude@achan-bot.local
3. tmux session per project, worktrees for parallel branches
4. Test from achan.local browser (http://achan-bot.local:PORT)
```

## Goals

- One command (`./setup.sh`) run by the admin user sets everything up
- Creates a non-admin `claude` user for day-to-day SSH work
- Workspace layout designed for git worktrees + multiple projects
- tmux session per project with persistent servers
- Idempotent — safe to re-run
- Minimal dependencies (only what ships with macOS)

## Workspace Layout

```
/Users/claude/
├── src/                          # All projects live here
│   ├── project-a/                # One dir per repo
│   │   ├── .bare/                # Bare clone (worktree root)
│   │   ├── main/                 # Worktree: main branch
│   │   ├── feature-x/           # Worktree: feature branch
│   │   └── fix-y/               # Worktree: bugfix branch
│   ├── project-b/
│   │   ├── .bare/
│   │   ├── main/
│   │   └── feature-z/
│   └── ...
└── bin/                          # User scripts/helpers
    └── wt                        # Worktree helper (create/list/remove)
```

**Worktree convention:**
- Each repo is a bare clone in `~/src/<project>/.bare/`
- Worktrees are siblings: `~/src/<project>/<branch-name>/`
- Each worktree can run its own dev server on a distinct port
- No branch switching needed — just `cd` between directories

## tmux Layout

One tmux session per project, windows for each concern:

```
tmux sessions:
  project-a           ← tmux new -s project-a
    window 0: main    ← server running on :3000
    window 1: feat-x  ← server running on :3001
    window 2: shell   ← general work

  project-b           ← tmux new -s project-b
    window 0: main    ← server running on :4000
    window 1: shell
```

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
│   ├── zshrc                 # Shell config (PATH, aliases, worktree helpers)
│   ├── gitconfig             # Git config (worktree-friendly defaults)
│   ├── tmux.conf             # tmux config (session/window management)
│   └── ssh_config
├── bin/
│   └── wt                    # Worktree helper script
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
   - Create `~/src/` and `~/bin/` directories
5. **Enable SSH (Remote Login)**
   - `systemsetup -setremotelogin on`
   - Allow the `claude` user to connect via SSH
   - Deploy authorized_keys for the `claude` user

### Phase 3 — Environment (scripts 06–07)

Configure the `claude` user's environment for multi-project work.

6. **Dotfiles** — Copy into `/Users/claude`:
   - `.zshrc` — PATH (Homebrew + `~/bin`), aliases, prompt showing project/branch
   - `.tmux.conf` — status bar with session name, sensible defaults
   - `.gitconfig` — name, email, default branch, worktree-friendly settings
   - `.ssh/config` — outbound SSH config if needed
7. **Dev environment** (run as `claude` user via `sudo -u claude`)
   - Install Claude Code (`npm install -g @anthropic-ai/claude-code`)
   - Install `wt` worktree helper into `~/bin/`
   - Verify tools work
   - Ensure Homebrew-installed tools are on PATH

## Worktree Helper (`wt`)

A small shell script in `~/bin/wt` to streamline worktree management:

```bash
# Clone a repo as bare + create main worktree:
wt clone git@github.com:user/project.git

# Creates:
#   ~/src/project/.bare/    (bare clone)
#   ~/src/project/main/     (main branch worktree)

# Add a new worktree:
cd ~/src/project
wt add feature-x

# List worktrees:
wt list

# Remove a worktree:
wt rm feature-x
```

## Usage

```bash
# 1. On achan-bot.local, logged in as your admin user:
git clone <this-repo>
cd achan-bot.local
./setup.sh

# 2. From achan.local, SSH in:
ssh claude@achan-bot.local

# 3. Set up a project with worktrees:
wt clone git@github.com:you/your-app.git
cd ~/src/your-app/main
npm start  # runs on :3000

# 4. Work on a feature in parallel:
cd ~/src/your-app
wt add feature-x
cd feature-x
npm start -- --port 3001

# 5. Test from achan.local:
#    http://achan-bot.local:3000  (main)
#    http://achan-bot.local:3001  (feature-x)
```

## Design Decisions

| Decision | Rationale |
|---|---|
| Bash scripts, not Ansible/Nix | Zero dependencies on a fresh Mac; macOS ships bash/zsh |
| Numbered scripts | Clear execution order; easy to run one step at a time |
| Idempotent checks | Each script checks state before acting (no double-installs) |
| Non-admin `claude` user | Least privilege for daily work |
| Brewfile | Declarative, diffable, version-controllable package list |
| Bare clone + worktrees | Run multiple branches simultaneously without switching |
| tmux session per project | Isolate projects, persist servers across SSH disconnects |
| `~/src/<project>/<branch>/` | Flat, predictable layout for worktrees |
| `wt` helper script | Consistent worktree conventions without memorizing git commands |

## Open Questions

- [ ] Should we configure macOS energy/sleep settings for always-on use?
- [ ] Any additional Homebrew packages needed?
- [ ] Firewall rules (beyond SSH)?
- [ ] Automatic updates (Homebrew, macOS)?
- [ ] tmux auto-attach on SSH login?
- [ ] Port assignment convention per project? (e.g., project-a = 3xxx, project-b = 4xxx)
