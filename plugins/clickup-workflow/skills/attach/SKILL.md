# /clickup:attach - Attach to Agent Session

Attach to a running ClickUp agent's tmux session for real-time interaction.

## Usage

```
/clickup:attach <task_id>
```

## Arguments

- `task_id` (required): The ClickUp task ID (e.g., `86ew43633`)

## Behavior

When this command is invoked:

1. **Check Session Exists**: Verify there's an active tmux session for this task
2. **Display Info**: Show session details before attaching
3. **Attach**: Connect to the tmux session

## Instructions for Claude

When the user runs `/clickup:attach`, execute the following:

```bash
# Get task ID from arguments
TASK_ID="$ARGUMENTS"

if [ -z "$TASK_ID" ]; then
  echo "Usage: /clickup:attach <task_id>"
  echo ""
  echo "Available ClickUp sessions:"
  tmux ls 2>/dev/null | grep "clickup-" || echo "  No active sessions"
  exit 1
fi

SESSION="clickup-${TASK_ID}"

# Check if session exists
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "❌ Session not found: $SESSION"
  echo ""
  echo "Available ClickUp sessions:"
  tmux ls 2>/dev/null | grep "clickup-" || echo "  No active sessions"
  exit 1
fi

# Show session info
echo "📎 Attaching to session: $SESSION"
echo ""
echo "Controls:"
echo "  • Detach: Ctrl+B then D"
echo "  • Scroll: Ctrl+B then [ (q to exit scroll mode)"
echo "  • Kill:   /clickup:kill $TASK_ID"
echo ""

# Attach
tmux attach -t "$SESSION"
```

## Alternative: Use Script

If the project has the scripts/clickup directory:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/clickup/tmux-attach.sh "$TASK_ID"
```

## Keyboard Controls in tmux

| Key | Action |
|-----|--------|
| `Ctrl+B` then `D` | Detach (leave session running) |
| `Ctrl+B` then `[` | Enter scroll mode |
| `q` | Exit scroll mode |
| `Ctrl+B` then `c` | Create new window |
| `Ctrl+B` then `n` | Next window |
| `Ctrl+B` then `p` | Previous window |

## Examples

```bash
# Attach to task 86ew43633
/clickup:attach 86ew43633

# List available sessions first
tmux ls | grep clickup-
```

## Related Commands

- `/clickup:status` - View all agent sessions
- `/clickup:kill` - Terminate an agent session
- `/clickup:work` - Start new agent sessions
