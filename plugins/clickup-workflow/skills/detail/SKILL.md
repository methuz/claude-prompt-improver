---
name: detail
description: "Show detailed information about a ClickUp task including description and comments"
category: integration
complexity: basic
mcp-servers: []
personas: []
---

# /clickup:detail - View Task Details

## Purpose
Display comprehensive information about a ClickUp task including title, description, status, priority, tags, custom fields, and recent comments.

## Usage
```
/clickup:detail <task_id>
```

## Behavioral Flow

When this command is invoked with a task ID:

1. **Load Environment**: Read ClickUp credentials from `.env`:
   - `CLICKUP_TOKEN`

2. **Fetch Task Details**:
   ```bash
   curl -s "https://api.clickup.com/api/v2/task/${TASK_ID}" \
     -H "Authorization: ${CLICKUP_TOKEN}"
   ```

3. **Fetch Task Comments**:
   ```bash
   curl -s "https://api.clickup.com/api/v2/task/${TASK_ID}/comment" \
     -H "Authorization: ${CLICKUP_TOKEN}"
   ```

4. **Display Formatted Output**:
   ```
   ╔═══════════════════════════════════════════════════════════════════╗
   ║  📋 CLICKUP TASK DETAILS                                          ║
   ╚═══════════════════════════════════════════════════════════════════╝

   🆔 Task ID:     {task_id}
   📌 Title:       {task_name}
   📊 Status:      {status} {status_color_emoji}
   🎯 Priority:    {priority_flag} {priority_name}
   🏷️  Tags:        {tags_list or "None"}
   👤 Assignees:   {assignee_names or "Unassigned"}
   📅 Due Date:    {due_date or "No due date"}
   🔗 URL:         https://app.clickup.com/t/{task_id}

   ───────────────────────────────────────────────────────────────────
   📝 DESCRIPTION
   ───────────────────────────────────────────────────────────────────
   {task_description or "No description provided."}

   ───────────────────────────────────────────────────────────────────
   🔧 CUSTOM FIELDS
   ───────────────────────────────────────────────────────────────────
   {custom_field_name}: {custom_field_value}
   ...
   (If no custom fields: "No custom fields set.")

   ───────────────────────────────────────────────────────────────────
   💬 COMMENTS ({comment_count})
   ───────────────────────────────────────────────────────────────────

   [{timestamp}] @{username}:
   {comment_text}

   [{timestamp}] @{username}:
   {comment_text}

   ...

   (If no comments: "No comments on this task.")

   ═══════════════════════════════════════════════════════════════════
   ```

## Field Extraction

### From Task Response
| Field | JSON Path | Description |
|-------|-----------|-------------|
| Task ID | `id` | Unique task identifier |
| Title | `name` | Task name/title |
| Status | `status.status` | Current status name |
| Status Color | `status.color` | Status color for emoji mapping |
| Priority | `priority.priority` | Priority level (1=urgent, 4=low) |
| Priority Name | `priority.priority` | "urgent", "high", "normal", "low" |
| Tags | `tags[].name` | Array of tag names |
| Assignees | `assignees[].username` | Array of assigned usernames |
| Due Date | `due_date` | Unix timestamp (convert to readable) |
| Description | `description` | Markdown description |
| Text Content | `text_content` | Plain text version |
| Custom Fields | `custom_fields[]` | Array of custom field objects |

### From Comments Response
| Field | JSON Path | Description |
|-------|-----------|-------------|
| Comment Text | `comments[].comment_text` | Comment content |
| Username | `comments[].user.username` | Author username |
| Timestamp | `comments[].date` | Unix timestamp |

## Status Emoji Mapping
| Status | Emoji |
|--------|-------|
| to do | ⚪ |
| in progress | 🔵 |
| in review | 🟡 |
| complete | 🟢 |
| closed | ⚫ |

## Priority Emoji Mapping
| Priority | Emoji |
|----------|-------|
| urgent | 🔴 |
| high | 🟠 |
| normal | 🔵 |
| low | ⚪ |

## Error Handling

- Task ID not provided: Show usage instructions
- Task not found: "Task {task_id} not found. Please verify the task ID."
- API error: "Failed to fetch task details: {error_message}"
- Invalid token: "ClickUp authentication failed. Check CLICKUP_TOKEN in .env"

## Related Commands

- `/clickup:list` - List tasks from ClickUp
- `/clickup:process <id>` - Start working on a task
- `/clickup:work <id>` - Spawn subagent to work on task
- `/clickup:done` - Complete and merge task

## Tool Coordination

- **Bash**: curl for ClickUp API calls
- **Read**: Load `.env` for credentials

ARGUMENTS: $ARGUMENTS
