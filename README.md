# Emergency Console

A Claude Code plugin that provides an always-on emergency session for restarting
other Claude sessions on the same machine.

## What it does

- **Plugin agent** (`audiobook-organizer:emergency-console`): a red, Bash-only agent
  that any Claude session can summon to dry-run and restart other Claude processes.
- **Standalone session mode**: run a dedicated Claude session under `claude-loop`
  in tmux so it survives disconnects and auto-resumes after being signaled.
- **Auto-installs dependencies**: checks for `claude-loop` and the restart script
  on startup, installs from the plugin cache if missing.

## Install

```bash
claude plugin install falkcorp/emergency-console
```

Then run the one-time setup (installs `claude-loop` and the launcher to `~/.local/bin`):

```bash
bash "$(claude plugin path falkcorp/emergency-console)/scripts/install.sh"
```

## Usage

### As a plugin agent (from any Claude session)

Just say one of:
- "restart all claudes"
- "fire"
- "what would get restarted"

### As a standalone always-on session

```bash
emergency-console
```

This creates a tmux session named `emergency-console` running `claude-loop`. The session:
- Holds station and responds only to trigger words (`restart`, `fire`, `dry-run`, `status`)
- Auto-resumes after being signaled (because it runs under `claude-loop`)
- Is the last session standing when everything else is restarted

## How restart works

The restart script sends `SIGHUP` to all `claude` CLI processes **except the current
session and its ancestor chain**. Sessions running under `claude-loop` detect the signal,
exit cleanly, and relaunch with `claude --continue` to resume the same conversation.

The emergency console session itself is excluded from the signal — it is never its
own target.

## Dependencies

- `tmux` — for the standalone session (most systems have this)
- `python3` — for the restart script (standard)
- `claude-loop` — installed automatically by `scripts/install.sh` or by the agent on first run

## Files

| Path | Purpose |
|---|---|
| `agents/emergency-console.md` | Plugin agent definition |
| `assets/claude-loop.sh` | Restart-aware Claude wrapper |
| `assets/session.md` | Standalone session behavior (installed as `~/.claude/emergency-console/CLAUDE.md`) |
| `assets/launcher.sh` | Installed as `emergency-console` in `~/.local/bin` |
| `scripts/restart_claudes.py` | Sends SIGHUP to other Claude processes |
| `scripts/install.sh` | One-time setup script |

## License

MIT
