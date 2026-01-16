---
name: comment
description: "Add an AI-generated comment to the current ClickUp task"
category: integration
complexity: intermediate
mcp-servers: []
personas: []
---

# /clickup:comment - Add Comment to Current Task

## Purpose
Add a well-structured comment to the current ClickUp task. The comment is AI-generated based on your prompt and task context, then presented for confirmation before posting.

## Usage
```
/clickup:comment <prompt>
```

## Examples
```
/clickup:comment blocking - waiting for API credentials
/clickup:comment progress update - completed auth flow
/clickup:comment question - should we use OAuth or API keys?
/clickup:comment ready for review
```

## Behavioral Flow

When this command is invoked:

1. **Detect Current Task**:
   - Get current git branch: `git rev-parse --abbrev-ref HEAD`
   - Extract task ID from branch name pattern: `{type}/{task_id}-{title}`
   - Example: `fix/86bqy2f6j-payment-webhook` → Task ID: `86bqy2f6j`

2. **Fetch Task Context**:
   - Get task details from ClickUp for context (title, status, description)

3. **Gather Git Context** (optional, for richer comments):
   - Recent commits on branch: `git log --oneline staging..HEAD`
   - Files changed: `git diff --stat staging...HEAD`

4. **Generate Comment**:
   Based on the user's prompt, generate a well-structured markdown comment. Detect comment type from keywords:

   | Keyword | Comment Type | Icon |
   |---------|--------------|------|
   | blocking, blocked, waiting | Blocker | ⏸️ |
   | progress, update, completed | Progress Update | 📊 |
   | question, help, clarify | Question | ❓ |
   | ready, done, finished | Ready for Review | ✅ |
   | issue, problem, bug | Issue Found | 🐛 |

5. **Show Preview for Confirmation**:
   ```
   📋 Task: Fix payment webhook race condition
   🌿 Branch: fix/86bqy2f6j-payment-webhook-race

   📝 Generated Comment:
   ---
   ## ⏸️ Blocked

   **Reason**: Waiting for API credentials

   **Current Progress**:
   - Implemented core webhook handler
   - Added retry logic

   **Next Steps**: Resume implementation once credentials are received.

   **Branch**: `fix/86bqy2f6j-payment-webhook-race`
   ---

   Post this comment to ClickUp? [Y/n]
   ```

6. **Post Comment** (on confirmation):
   ```bash
   curl -X POST "https://api.clickup.com/api/v2/task/${TASK_ID}/comment" \
     -H "Authorization: ${CLICKUP_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{"comment_text": "..."}'
   ```

7. **Confirm Success**:
   ```
   ✅ Comment posted to ClickUp
   🔗 View task: https://app.clickup.com/t/86bqy2f6j
   ```

## Comment Templates

### Blocker Comment
```markdown
## ⏸️ Blocked

**Reason**: {user's reason}

**Current Progress**:
- {bullet points from git commits if available}

**Next Steps**: {what happens when unblocked}

**Branch**: `{branch-name}`
```

### Progress Update
```markdown
## 📊 Progress Update

**Completed**:
- {items from user prompt or git commits}

**In Progress**:
- {current work}

**Branch**: `{branch-name}`
```

### Question
```markdown
## ❓ Question

{user's question}

**Context**: {relevant task/branch info}
```

### Ready for Review
```markdown
## ✅ Ready for Review

**Summary**:
{brief summary of changes}

**Changes**:
- {list of changes from git}

**Branch**: `{branch-name}`
```

## Error Handling

- Not on a feature branch: "Not currently on a task branch. Use /clickup:work to start a task."
- Task ID not found in branch: "Could not extract task ID from branch name."
- Task not found in ClickUp: "Task {id} not found in ClickUp."
- Comment cancelled: "Comment not posted."

## Tool Coordination

- **Bash**: Git commands and curl for ClickUp API
- **Read**: Load `.env` file
- **AskUser**: Confirm before posting comment

ARGUMENTS: $ARGUMENTS
