---
name: list
description: "Fetch and display ClickUp tasks ready for development"
category: integration
complexity: basic
mcp-servers: []
personas: []
---

# /clickup:list - List ClickUp Tasks

## Purpose
Fetch and display user stories/bugs from ClickUp filtered by status.

## Usage
```
/clickup:list                         # Default: "To Do" tasks
/clickup:list --status "in progress"  # Tasks currently being worked on
/clickup:list --status "to review"    # Tasks ready for review
/clickup:list --all                   # All tasks (all statuses)
```

## Common Status Filters
| Status | Use Case |
|--------|----------|
| `to do` | Tasks ready to start (default) |
| `in progress` | Tasks currently being worked on |
| `to review` | Tasks awaiting review |
| `done` | Completed tasks |
| `--all` | All tasks across all statuses |

## Behavioral Flow

When this command is invoked:

1. **Load Environment**: Read ClickUp credentials from the project's `.env` file:
   - `CLICKUP_TOKEN` - API authentication token
   - `CLICKUP_LIST_ID` - The ClickUp list to fetch tasks from

2. **Parse Status Filter**:
   - Default: `To Do`
   - If `--status` provided, use that status (URL encode spaces as `%20`)

3. **Fetch Tasks**: Call ClickUp API with the specified status and format with jq:
   ```bash
   # IMPORTANT:
   # - Always use jq to format output compactly to avoid truncation
   # - Use subtasks=true to ensure ALL tasks are returned (not just first page)
   # - The API may paginate results; subtasks=true bypasses this for most cases

   # Default (To Do) - formatted output
   curl -s "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task?statuses[]=To%20Do&include_closed=false&subtasks=true" \
     -H "Authorization: ${CLICKUP_TOKEN}" | jq -r '
     "📋 Tasks Ready for Development (To Do)\n",
     (.tasks[] | "• [\(.id)] \(if (.tags | map(.name) | contains(["bug"])) then "🐛" elif (.tags | map(.name) | contains(["story"])) then "📖" else "  " end) \(.name)"),
     "",
     "Found \(.tasks | length) tasks ready for development.",
     "",
     "💡 Use: /clickup:process <id> to set up a worktree and start"
   '

   # In Progress - with branch info
   curl -s "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task?statuses[]=in%20progress&include_closed=false&subtasks=true" \
     -H "Authorization: ${CLICKUP_TOKEN}" | jq -r '
     "📋 Tasks In Progress\n",
     (.tasks[] | "• [\(.id)] \(if (.tags | map(.name) | contains(["bug"])) then "🐛" elif (.tags | map(.name) | contains(["story"])) then "📖" else "  " end) \(.name)\n  Branch: \((.custom_fields[] | select(.name == "branch") | .value) // "not set")"),
     "",
     "Found \(.tasks | length) tasks in progress.",
     "",
     "💡 Use: /clickup:work <id> to spawn a subagent to work on a task",
     "💡 Use: /clickup:work --all to work on all in-progress tasks",
     "💡 Use: /clickup:done to complete a task"
   '

   # All statuses - comprehensive view
   curl -s "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task?include_closed=false&subtasks=true" \
     -H "Authorization: ${CLICKUP_TOKEN}" | jq -r '
     "📋 All Tasks\n",
     (.tasks[] | "• [\(.id)] \(if (.tags | map(.name) | contains(["bug"])) then "🐛" elif (.tags | map(.name) | contains(["story"])) then "📖" else "  " end) [\(.status.status)] \(.name)"),
     "",
     "Found \(.tasks | length) total tasks."
   '
   ```

4. **Format Output**: Display tasks in a formatted table with:
   - Task ID (for use with `/clickup:process` or `/clickup:work`)
   - Type (bug or story based on tags)
   - Priority (Urgent, High, Normal, Low)
   - Title
   - Branch (if available, for "In Progress" tasks)

5. **Show Next Steps**: Context-aware suggestions based on status

## Expected Output Format

### "To Do" Tasks (Default)
```
📋 Tasks Ready for Development (To Do)

• [86bqy2f6j] 🐛 Fix payment webhook race condition
• [86bqy3abc] 📖 Add user profile avatar upload
• [def456uvw] 📖 Update dashboard layout for better mobile responsiveness

Found 48 tasks ready for development.

💡 Use: /clickup:process <id> to set up a worktree and start
```

### "In Progress" Tasks
```
📋 Tasks In Progress

• [86bqy2f6j] 🐛 Fix payment webhook race condition
  Branch: fix/86bqy2f6j-payment-webhook
• [abc123def] 📖 Add user profile feature with avatar upload support
  Branch: feature/abc123def-user-profile

Found 2 tasks in progress.

💡 Use: /clickup:work <id> to spawn a subagent to work on a task
💡 Use: /clickup:work --all to work on all in-progress tasks
💡 Use: /clickup:done to complete a task
```

### All Tasks (--all)
```
📋 All Tasks

• [86bqy2f6j] 🐛 [in progress] Fix payment webhook race condition
• [86bqy3abc] 📖 [to do] Add user profile avatar upload
• [def456uvw] 📖 [to review] Update dashboard layout for better mobile responsiveness

Found 50 total tasks.
```

## Error Handling

- If `CLICKUP_TOKEN` is not set: Show error with instructions to set it in `.env`
- If `CLICKUP_LIST_ID` is not set: Show error with instructions
- If API call fails: Show error message from ClickUp
- If no tasks found: Show friendly message that no tasks match the filter

## Tool Coordination

- **Bash**: Execute curl commands for ClickUp API calls
- **Read**: Load `.env` file to get credentials

ARGUMENTS: $ARGUMENTS
