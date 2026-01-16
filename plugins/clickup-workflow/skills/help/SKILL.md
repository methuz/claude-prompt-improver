---
name: help
description: "List all available /clickup commands and their functionality"
category: integration
complexity: basic
mcp-servers: []
personas: []
---

# /clickup:help - ClickUp Integration Commands

## Overview

ClickUp integration commands for task management, parallel development, and agent orchestration.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/clickup:list` | List tasks by status |
| `/clickup:detail <id>` | View task details & comments |
| `/clickup:process <id>` | Start task → create branch + worktree |
| `/clickup:work <id>` | Spawn agent in tmux session |
| `/clickup:attach <id>` | Attach to agent's tmux session |
| `/clickup:kill <id>` | Terminate agent tmux session |
| `/clickup:done` | Complete task → merge + update ClickUp |
| `/clickup:status` | Show active agents & worktrees |
| `/clickup:add <title> <tag>` | Create new task |
| `/clickup:comment <prompt>` | Add AI-generated comment |
| `/clickup:update <id> <prompt>` | Update task via natural language |

---

## Commands

### `/clickup:list`
**Fetch and display tasks by status**

```
/clickup:list                         # Default: "To Do" tasks
/clickup:list --status "in progress"  # Tasks being worked on
/clickup:list --status "to review"    # Tasks ready for review
```

Output shows: ID, Type (bug/story), Priority, Title

---

### `/clickup:detail <task_id>`
**View comprehensive task information**

```
/clickup:detail 86ew4b2eg
```

Shows: Title, Status, Priority, Tags, Description, Custom Fields, Comments

---

### `/clickup:process <task_id(s)>`
**Start working on task(s) - creates branch/worktrees and updates ClickUp**

```
/clickup:process 86ew4b2eg                          # Single task, create branch
/clickup:process 86ew4b2eg --worktree               # Single task with worktree
/clickup:process 86abc 86def 86ghi                  # Multiple tasks → all get worktrees
/clickup:process 86abc 86def 86ghi --work           # Process + spawn agents immediately
```

Actions:
- Creates branch: `fix/{id}-{slug}` (for bugs) or `feature/{id}-{slug}` (for stories)
- Updates ClickUp status: "To Do" → "In Progress"
- Sets branch name in ClickUp custom field
- With `--work`: Spawns parallel agents for each task

---

### `/clickup:work <task_id>`
**Spawn autonomous Claude agent in tmux session**

```
/clickup:work 86ew4b2eg                 # Work on single task
/clickup:work 86abc 86def 86ghi         # Work on multiple tasks in parallel
/clickup:work --all                     # Work on all "In Progress" tasks
```

Prerequisites:
- Run `/clickup:process <id>` first to create worktree
- Or let it auto-create the worktree

The agent:
- Runs in named tmux session: `clickup-{task_id}`
- Works in isolated worktree with fresh node_modules
- Has full task context (description + comments)
- Can be attached to for real-time interaction

---

### `/clickup:attach <task_id>`
**Attach to agent's tmux session for real-time interaction**

```
/clickup:attach 86ew4b2eg               # Attach to specific agent
```

Once attached:
- See exactly what the agent is doing
- Provide guidance or corrections
- Detach with `Ctrl+B` then `D`
- Exit scroll mode with `q`

---

### `/clickup:kill <task_id>`
**Terminate agent's tmux session**

```
/clickup:kill 86ew4b2eg                 # Kill session only
/clickup:kill 86ew4b2eg --cleanup       # Kill session AND remove worktree
```

Use when:
- Agent is stuck and needs restart
- You want to manually take over
- Task is abandoned

---

### `/clickup:done`
**Complete task - merge to staging and update ClickUp**

```
/clickup:done                    # Auto-detect task from current branch
/clickup:done 86ew4b2eg          # Explicitly specify task ID
/clickup:done --keep-worktree    # Don't remove worktree after completion
```

Actions:
- Merges branch to local staging
- Posts summary comment to ClickUp
- Updates status: "In Progress" → "To Review"
- Removes worktree (unless --keep-worktree)

---

### `/clickup:status`
**Show agent dashboard and worktree status**

```
/clickup:status              # Show all active agents
/clickup:status 86ew4b2eg    # Show specific task status
/clickup:status --worktrees  # Show all worktrees
```

Shows: Agent status (working/done/stuck), ports, branches, elapsed time

---

### `/clickup:add <title> <tag> [description]`
**Create a new task directly in ClickUp**

```
/clickup:add "Fix login button" bug
/clickup:add "User profile page" story "Add ability to edit profile"
/clickup:add "Update README" task
```

Parameters:
- `title` (required): Task title
- `tag` (required): bug, story, task, feature, etc.
- `description` (optional): Task description

---

### `/clickup:comment <prompt>`
**Add AI-generated comment to current task**

```
/clickup:comment blocking - waiting for API credentials
/clickup:comment progress update - completed auth flow
/clickup:comment question - should we use OAuth or API keys?
/clickup:comment ready for review
```

Auto-detects task from current branch. Generates structured markdown comment based on your prompt.

---

### `/clickup:update <task_id> <prompt>`
**Update task using natural language**

```
/clickup:update 86ew4b2eg add tag "urgent"
/clickup:update 86ew4b2eg set priority to high
/clickup:update 86ew4b2eg comment "Started working on API"
/clickup:update add tag "blocked" and comment "waiting for specs"
```

Supports: tags, priority, status, comments, custom fields, due dates

---

## Typical Workflows

### Solo Development
```
/clickup:list                    # See available tasks
/clickup:detail 86ew4b2eg        # Read task details
/clickup:process 86ew4b2eg       # Create branch, start working
# ... do the work ...
/clickup:done                    # Merge and complete
```

### Parallel Development (Multiple Tasks)
```
/clickup:list                              # See available tasks
/clickup:process 86abc 86def 86ghi         # Create worktrees for all at once
/clickup:work --all                        # Spawn agents for all
/clickup:status                            # Monitor progress
```

### One-Command Parallel Workflow (Fastest)
```
# Process AND spawn agents in a single command:
/clickup:process 86abc 86def 86ghi --work
/clickup:status                            # Monitor progress
```

### Autonomous Agent Work
```
/clickup:list --status "in progress"       # See in-progress tasks
/clickup:work --all                        # Spawn agents in tmux sessions
/clickup:status                            # Monitor progress
/clickup:attach 86abc                      # Attach to agent to watch/steer
# Press Ctrl+B, D to detach
```

### Interactive Agent Monitoring
```
/clickup:work 86abc 86def 86ghi            # Spawn 3 agents
/clickup:status                            # See session status
/clickup:attach 86abc                      # Attach to first agent
# Watch agent work, provide guidance if needed
# Ctrl+B, D to detach
/clickup:attach 86def                      # Switch to second agent
```

---

## Environment Setup

Required in `.env`:
```
CLICKUP_TOKEN=pk_xxxxx
CLICKUP_LIST_ID=901814851000
```

Get your token from: https://app.clickup.com/settings/apps

---

## Status Icons

| Icon | Meaning |
|------|---------|
| 🟢 | tmux session active |
| ⚪ | No tmux session (exited or not started) |
| ✅ | Task completed |
| ❌ | Error/stuck |

## tmux Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+B` then `D` | Detach from session |
| `Ctrl+B` then `[` | Enter scroll mode |
| `q` | Exit scroll mode |
| `Ctrl+B` then `c` | Create new window |
| `Ctrl+B` then `n` | Next window |

ARGUMENTS: $ARGUMENTS
