# /clickup:kill - Terminate Agent Session

Kill a ClickUp agent's tmux session, optionally cleaning up the worktree.

## Usage

```
/clickup:kill <task_id> [--cleanup]
```

## Arguments

- `task_id` (required): The ClickUp task ID (e.g., `86ew43633`)
- `--cleanup` (optional): Also remove the worktree after killing the session

## Behavior

When this command is invoked:

1. **Kill tmux Session**: Terminate the agent's tmux session
2. **Optional Cleanup**: If `--cleanup` is specified, remove the worktree
3. **Report Status**: Confirm what was done

## Instructions for Claude

When the user runs `/clickup:kill`, execute the following:

```bash
# Parse arguments
TASK_ID=""
CLEANUP=""

for arg in $ARGUMENTS; do
  if [ "$arg" = "--cleanup" ]; then
    CLEANUP="--cleanup"
  elif [ -z "$TASK_ID" ]; then
    TASK_ID="$arg"
  fi
done

if [ -z "$TASK_ID" ]; then
  echo "Usage: /clickup:kill <task_id> [--cleanup]"
  echo ""
  echo "Options:"
  echo "  --cleanup    Also remove the worktree"
  echo ""
  echo "Available ClickUp sessions:"
  tmux ls 2>/dev/null | grep "clickup-" || echo "  No active sessions"
  exit 1
fi

SESSION="clickup-${TASK_ID}"

# Kill session
if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
  echo "✅ Killed session: $SESSION"
else
  echo "⚠️ Session not found: $SESSION (may already be terminated)"
fi

# Optional cleanup
if [ "$CLEANUP" = "--cleanup" ]; then
  echo ""
  echo "🧹 Cleaning up worktree..."

  PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  # Find worktree by task ID
  WORKTREE=$(find "$PROJECT_ROOT/.worktrees" -maxdepth 3 -type d -name "*${TASK_ID}*" 2>/dev/null | head -1)

  if [ -n "$WORKTREE" ] && [ -d "$WORKTREE" ]; then
    echo "Found worktree: $WORKTREE"

    # Two-phase cleanup
    git worktree remove "$WORKTREE" --force 2>/dev/null || true
    [ -d "$WORKTREE" ] && rm -rf "$WORKTREE"
    git worktree prune

    echo "✅ Worktree removed"
  else
    echo "⚠️ No worktree found for task: $TASK_ID"
  fi
fi
```

## Alternative: Use Script

If the project has the scripts/clickup directory:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/clickup/tmux-kill.sh "$TASK_ID" "$CLEANUP"
```

## Examples

```bash
# Kill session only (keep worktree for later inspection)
/clickup:kill 86ew43633

# Kill session and cleanup worktree
/clickup:kill 86ew43633 --cleanup

# List sessions before killing
tmux ls | grep clickup-
```

## When to Use --cleanup

Use `--cleanup` when:
- The task is complete and merged
- You want to free up disk space
- The agent crashed and work is unrecoverable

Don't use `--cleanup` when:
- You might want to inspect the work later
- The agent is just paused temporarily
- You want to manually review changes before cleanup

## Related Commands

- `/clickup:attach` - Attach to an agent session
- `/clickup:status` - View all agent sessions
- `/clickup:done` - Complete workflow (includes cleanup)
