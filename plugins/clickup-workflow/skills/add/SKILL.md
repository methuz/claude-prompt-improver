---
name: add
description: "Add a new task to ClickUp directly (no AI processing)"
category: integration
complexity: basic
mcp-servers: []
personas: []
---

# /clickup:add - Add New Task

## Purpose
Create a new task in ClickUp directly. No AI processing - just sends the data straight to ClickUp.

## Usage
```
/clickup:add <title> <tag> [description]
```

## Parameters
- `title` (required): Task title
- `tag` (required): Tag name (bug, story, task, etc.)
- `description` (optional): Task description

## Examples
```
/clickup:add "Fix login button" bug
/clickup:add "User profile page" story "Add ability to edit profile picture and bio"
/clickup:add "Update README" task
/clickup:add "Payment integration" feature "Integrate Stripe for subscription payments"
```

## Behavioral Flow

1. **Parse Arguments**:
   - Extract title (required)
   - Extract tag (required)
   - Extract description (optional)

2. **Create Task** (direct API call, no AI):
   ```bash
   curl -X POST "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task" \
     -H "Authorization: ${CLICKUP_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "{title}",
       "tags": ["{tag}"],
       "description": "{description}"  // only if provided
     }'
   ```

3. **Output Result**:
   ```
   ✅ Task created!

   📋 Title: Fix login button
   🏷️ Tag: bug
   🆔 ID: 86ew3xxxx

   🔗 View: https://app.clickup.com/t/86ew3xxxx
   ```

## API Endpoint

**Create Task**:
```
POST https://api.clickup.com/api/v2/list/{list_id}/task
```

**Request Body (with description)**:
```json
{
  "name": "Task title",
  "tags": ["bug"],
  "description": "Optional description",
  "status": "to do"
}
```

**Request Body (without description)**:
```json
{
  "name": "Task title",
  "tags": ["story"],
  "status": "to do"
}
```

## Error Handling

- Missing title: "Error: Title is required. Usage: /clickup:add <title> <tag> [description]"
- Missing tag: "Error: Tag is required. Usage: /clickup:add <title> <tag> [description]"
- API error: Show ClickUp error message
- Invalid tag: Task created, tag may not appear if it doesn't exist in space

## Notes

- Task is created with status "to do" by default
- No AI processing - data goes directly to ClickUp as provided
- Tags are case-insensitive in ClickUp

ARGUMENTS: $ARGUMENTS
