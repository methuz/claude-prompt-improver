---
name: status
description: "Show status of all active ClickUp agents and worktrees"
category: integration
complexity: basic
mcp-servers: []
personas: []
---

# /clickup:status - Show Agent Status

## Purpose
Display the current status of all active ClickUp agent tmux sessions and worktrees.

## Usage
```
/clickup:status              # Show all active agents and worktrees
/clickup:status <task_id>    # Show status of specific task
/clickup:status --worktrees  # Show all worktrees only
/clickup:status --sessions   # Show tmux sessions only
```

## Behavioral Flow

When this command is invoked:

1. **Check tmux Sessions**: List all ClickUp agent sessions
   ```bash
   # List all clickup sessions
   tmux ls 2>/dev/null | grep "clickup-"

   # Example output:
   clickup-86abc123: 1 windows (created Thu Jan  9 06:30:00 2026)
   clickup-86def456: 1 windows (created Thu Jan  9 06:30:01 2026)
   ```

2. **Check Worktrees**: List all git worktrees
   ```bash
   git worktree list | grep .worktrees
   ```

3. **Match Sessions to Worktrees**: Cross-reference to show complete status

4. **Display Dashboard**:
   ```
   ┌───────────────────────────────────────────────────────────────────────┐
   │  🤖 ClickUp Agent Status                                              │
   ├───────────────────────────────────────────────────────────────────────┤
   │                                                                        │
   │  ACTIVE SESSIONS (2)                                                   │
   │  ────────────────────────────────────────────────────────────────────  │
   │  │ Task ID   │ tmux Session      │ Worktree                          │
   │  │-----------|-------------------|-----------------------------------|
   │  │ 86abc123  │ 🟢 clickup-86abc │ .worktrees/fix/86abc123-pay...    │
   │  │ 86ghi789  │ 🟢 clickup-86ghi │ .worktrees/fix/86ghi789-log...    │
   │                                                                        │
   │  WORKTREES WITHOUT SESSIONS (1)                                        │
   │  ────────────────────────────────────────────────────────────────────  │
   │  │ 86def456  │ ⚪ no session     │ .worktrees/feature/86def456-...   │
   │                                                                        │
   └───────────────────────────────────────────────────────────────────────┘

   Commands:
     /clickup:attach <id>   Attach to agent's tmux session
     /clickup:kill <id>     Kill agent session
     /clickup:work <id>     Start agent for worktree without session
     /clickup:done <id>     Complete and merge a task
   ```

## Status Types

| Status | Icon | Meaning |
|--------|------|---------|
| active | 🟢 | tmux session running, agent working |
| exited | ⚪ | tmux session ended (check worktree for results) |
| no session | ⚪ | Worktree exists but no tmux session |

## Single Task Status

When called with a task ID (`/clickup:status 86abc123`):

```
📋 Task: 86abc123 - Fix payment webhook race condition

tmux Session: 🟢 clickup-86abc123 (active)
Branch: fix/86abc123-payment-webhook
Worktree: .worktrees/fix/86abc123-payment-webhook

Git Status:
  • 3 files modified
  • 1 commit ahead of staging

ClickUp Status: In Progress
ClickUp URL: https://app.clickup.com/t/86abc123

Commands:
  • Attach: /clickup:attach 86abc123
  • Kill:   /clickup:kill 86abc123
```

## Worktrees Only Mode

When called with `--worktrees`:

```
📁 Git Worktrees

│ Branch                              │ Path                                    │ Status    │
│-------------------------------------|------------------------------------------|-----------|
│ staging                             │ /Users/rubick/.../doink-app             │ 🏠 Main   │
│ fix/86abc123-payment-webhook        │ .worktrees/fix/86abc123-payment-webhook │ 🟢 Active │
│ feature/86def456-user-avatar        │ .worktrees/feature/86def456-user-avatar │ ✅ Done   │
│ fix/86ghi789-login-redirect         │ .worktrees/fix/86ghi789-login-redirect  │ ❌ Stuck  │

Total: 4 worktrees (1 main + 3 task worktrees)
```

## Tool Coordination

- **Bash**: `tmux ls`, `git worktree list`, `git status`
- **tmux-list-agents.sh**: Script for detailed agent session info
- **wt-status-all.sh**: Script for worktree status summary

## Scripts Used

```bash
# List all agent sessions
./scripts/clickup/tmux-list-agents.sh

# Show worktree status summary
./scripts/clickup/wt-status-all.sh

# List worktrees
./scripts/clickup/wt-list.sh --clickup
```

## Related Commands

- `/clickup:attach <id>` - Attach to agent's tmux session
- `/clickup:kill <id>` - Kill agent session
- `/clickup:work <id>` - Start agent for task
- `/clickup:done <id>` - Complete and merge task
- `/clickup:list` - Show ClickUp tasks

ARGUMENTS: $ARGUMENTS
