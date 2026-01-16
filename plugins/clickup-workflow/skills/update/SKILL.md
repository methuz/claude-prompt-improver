---
name: update
description: "Update a ClickUp task based on natural language prompt - comment, tag, edit fields"
category: integration
complexity: intermediate
mcp-servers: []
personas: []
---

# /clickup:update - Update ClickUp Task

## Purpose
Update a ClickUp task using natural language. Claude interprets the prompt and performs the appropriate action(s): add comments, manage tags, update fields, change priority, etc.

## Usage
```
/clickup:update <task_id> <prompt>
```

If `task_id` is omitted and you're on a task branch, uses the current task.

## Examples
```
/clickup:update 86ew3km2a add tag "urgent"
/clickup:update 86ew3km2a set priority to high
/clickup:update 86ew3km2a comment "Started working on the API integration"
/clickup:update 86ew3km2a remove tag "bug", add tag "feature"
/clickup:update 86ew3km2a set due date to next friday
/clickup:update add tag "blocked" and comment "waiting for design specs"
```

## Supported Actions

### Comments
```
/clickup:update <id> comment "Your message here"
/clickup:update <id> add comment about the progress
```

### Tags
```
/clickup:update <id> add tag "urgent"
/clickup:update <id> remove tag "bug"
/clickup:update <id> add tags "frontend", "needs-review"
```

### Priority
```
/clickup:update <id> set priority to urgent
/clickup:update <id> set priority high
/clickup:update <id> lower priority
```
Priority levels: urgent (1), high (2), normal (3), low (4)

### Status
```
/clickup:update <id> move to "in progress"
/clickup:update <id> set status "to review"
```

### Custom Fields
```
/clickup:update <id> set branch to "feature/new-feature"
/clickup:update <id> update field "estimate" to "3 hours"
```

### Combined Actions
```
/clickup:update <id> add tag "urgent", set priority high, comment "This needs immediate attention"
```

## Behavioral Flow

1. **Parse Task ID**:
   - If ID provided, use it directly
   - If omitted, extract from current branch name (like `/clickup:comment`)

2. **Fetch Current Task State**:
   - Get task details including tags, priority, status, custom fields
   - This provides context for the update

3. **Interpret Prompt**:
   Claude analyzes the prompt to determine action(s):
   - Identify action type(s): comment, tag, priority, status, field
   - Extract values and parameters
   - Handle multiple actions in one prompt

4. **Show Preview**:
   ```
   📋 Task: Test Task (86ew3km2a)

   🔄 Proposed Changes:
   ├─ Add tag: "urgent"
   ├─ Set priority: normal → high
   └─ Add comment: "This needs immediate attention"

   Apply these changes? [Y/n]
   ```

5. **Execute Updates**:
   Make appropriate API calls based on action type:

   **Add/Remove Tags**:
   ```bash
   # Add tag
   curl -X POST "https://api.clickup.com/api/v2/task/{task_id}/tag/{tag_name}" \
     -H "Authorization: ${CLICKUP_TOKEN}"

   # Remove tag
   curl -X DELETE "https://api.clickup.com/api/v2/task/{task_id}/tag/{tag_name}" \
     -H "Authorization: ${CLICKUP_TOKEN}"
   ```

   **Update Priority/Status**:
   ```bash
   curl -X PUT "https://api.clickup.com/api/v2/task/{task_id}" \
     -H "Authorization: ${CLICKUP_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{"priority": 2, "status": "in progress"}'
   ```

   **Add Comment**:
   ```bash
   curl -X POST "https://api.clickup.com/api/v2/task/{task_id}/comment" \
     -H "Authorization: ${CLICKUP_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{"comment_text": "..."}'
   ```

   **Update Custom Field**:
   ```bash
   curl -X POST "https://api.clickup.com/api/v2/task/{task_id}/field/{field_id}" \
     -H "Authorization: ${CLICKUP_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{"value": "..."}'
   ```

6. **Confirm Success**:
   ```
   ✅ Task updated successfully!

   📋 Test Task (86ew3km2a)
   ├─ ✓ Added tag: "urgent"
   ├─ ✓ Priority: high
   └─ ✓ Comment added

   🔗 View: https://app.clickup.com/t/86ew3km2a
   ```

## Action Detection Keywords

| Keywords | Action |
|----------|--------|
| `comment`, `note`, `add comment` | Add comment |
| `tag`, `add tag`, `remove tag`, `label` | Manage tags |
| `priority`, `urgent`, `high`, `normal`, `low` | Set priority |
| `status`, `move to`, `set status` | Change status |
| `field`, `set`, `update` + field name | Update custom field |
| `due`, `deadline`, `due date` | Set due date |
| `assign`, `assignee` | Manage assignees |

## Error Handling

- Task not found: "Task {id} not found in ClickUp"
- Invalid tag: "Tag '{name}' doesn't exist. Create it? [Y/n]"
- Invalid status: "Status '{name}' not available. Valid statuses: to do, in progress, to review, complete"
- Permission denied: "You don't have permission to update this task"
- No actions detected: "Could not determine what to update. Please be more specific."

## Tool Coordination

- **Bash**: curl for ClickUp API calls
- **Read**: Load `.env` for credentials
- **AskUser**: Confirm changes before applying

ARGUMENTS: $ARGUMENTS
