---
name: process
description: "Start processing a ClickUp task - creates branch and updates ClickUp status"
category: integration
complexity: intermediate
mcp-servers: []
personas: []
---

# /clickup:process - Start Processing Task(s)

## Purpose
Start development setup for ClickUp task(s) by creating git branches/worktrees and updating task status in ClickUp. Supports batch processing with optional parallel agent spawning.

## Usage
```
/clickup:process <task_id>                          # Single task, create branch
/clickup:process <task_id> --worktree               # Single task with worktree
/clickup:process <id1> <id2> <id3>                  # Multiple tasks, all get worktrees
/clickup:process <id1> <id2> --work                 # Process AND spawn agents immediately
/clickup:process 86ew43633 86ew426dv 86ew44udu --work  # Example: 3 quick wins in parallel
```

## Behavioral Flow

### Single Task Mode (`/clickup:process <task_id>`)

1. **Load Environment**: Read ClickUp credentials from `.env`:
   - `CLICKUP_TOKEN`
   - `CLICKUP_LIST_ID`

2. **Fetch Task Details**: Get task info from ClickUp API:
   ```bash
   curl -s "https://api.clickup.com/api/v2/task/${TASK_ID}" \
     -H "Authorization: ${CLICKUP_TOKEN}"
   ```

3. **Validate Task**:
   - Verify task exists
   - Check current status is "To Do" (warn if already in progress)

4. **Generate Branch Name**:
   - Determine type from tags: `bug` tag → `fix/`, otherwise → `feature/`
   - Format: `{type}/{task_id}-{slugified-title}`
   - Example: `fix/86bqy2f6j-payment-webhook-race`

5. **Create Git Branch** (Default - no flags):
   ```bash
   git checkout -b {branch-name}
   ```

6. **OR Create Git Worktree** (with `--worktree` flag):
   ```bash
   git worktree add .worktrees/{branch-name} -b {branch-name}
   ln -sf "$(pwd)/.env" ".worktrees/{branch-name}/.env"
   cd ".worktrees/{branch-name}"

   # IMPORTANT: Remove any symlinked node_modules first
   if [ -L node_modules ]; then
     rm node_modules
   fi

   # Fresh install (not symlink)
   if command -v pnpm &> /dev/null; then
     pnpm install --prefer-offline
   else
     npm install --prefer-offline
   fi

   # Verify installation (must be directory, not symlink)
   if [ ! -d node_modules ] || [ -L node_modules ]; then
     echo "ERROR: node_modules installation failed"
     exit 1
   fi
   ```

7. **Update ClickUp Task**:
   ```bash
   curl -X PUT "https://api.clickup.com/api/v2/task/${TASK_ID}" \
     -H "Authorization: ${CLICKUP_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{"status": "in progress"}'
   ```

8. **Output Success**:
   ```
   ✅ Processing task: Fix payment webhook race condition

   🌿 Branch: fix/86bqy2f6j-payment-webhook-race
   📋 ClickUp status: To Do → In Progress

   💡 Use /clickup:work <task_id> to spawn a subagent
   💡 Use /clickup:done when finished
   ```

---

### Multi-Task Mode (`/clickup:process <id1> <id2> <id3>`)

When multiple task IDs are provided:

1. **Parse Task IDs**: Extract all task IDs from arguments (space or comma separated)
   ```
   Input: "86ew43633 86ew426dv 86ew44udu"
   Input: "86ew43633, 86ew426dv, 86ew44udu"  # Also valid
   ```

2. **Fetch All Tasks in Parallel**:
   For each task ID, call ClickUp API to get details:
   ```bash
   # Parallel fetch using background processes
   for TASK_ID in $TASK_IDS; do
     curl -s "https://api.clickup.com/api/v2/task/${TASK_ID}" \
       -H "Authorization: ${CLICKUP_TOKEN}" > "/tmp/task_${TASK_ID}.json" &
   done
   wait
   ```

3. **Generate Branch Names**: For each task:
   - Check tags for `bug` → `fix/` or default → `feature/`
   - Format: `{type}/{task_id}-{slugified-title}`

4. **Create All Worktrees** (multi-task mode always uses worktrees):
   ```bash
   # Create worktrees in parallel
   for BRANCH in $BRANCHES; do
     git worktree add ".worktrees/${BRANCH}" -b "${BRANCH}" &
   done
   wait

   # Setup each worktree with FRESH node_modules
   for BRANCH in $BRANCHES; do
     ln -sf "$(pwd)/.env" ".worktrees/${BRANCH}/.env"
     (
       cd ".worktrees/${BRANCH}"
       # Remove symlinked node_modules if exists
       [ -L node_modules ] && rm node_modules
       # Fresh install
       if command -v pnpm &> /dev/null; then
         pnpm install --prefer-offline
       else
         npm install --prefer-offline
       fi
     ) &
   done
   wait
   ```

5. **Update All ClickUp Tasks**:
   ```bash
   for TASK_ID in $TASK_IDS; do
     curl -X PUT "https://api.clickup.com/api/v2/task/${TASK_ID}" \
       -H "Authorization: ${CLICKUP_TOKEN}" \
       -H "Content-Type: application/json" \
       -d '{"status": "in progress"}' &
   done
   wait
   ```

6. **Output Summary**:
   ```
   ✅ Processed 3 tasks:

   │ # │ Task ID    │ Title                    │ Branch                          │
   │---|------------|--------------------------|----------------------------------|
   │ 1 │ 86ew43633  │ Price step fix           │ fix/86ew43633-price-step        │
   │ 2 │ 86ew426dv  │ Hide print area default  │ fix/86ew426dv-hide-print-area   │
   │ 3 │ 86ew44udu  │ Review layout reorder    │ fix/86ew44udu-review-layout     │

   📁 Worktrees created in: .worktrees/

   💡 Next steps:
   • /clickup:work --all          # Spawn agents for all in-progress tasks
   • /clickup:work 86ew43633      # Spawn agent for specific task
   • /clickup:status              # Check agent status
   ```

---

### Process + Work Mode (`/clickup:process <id1> <id2> --work`)

The `--work` flag combines process and work into a single command:

1. **Process all tasks** (same as multi-task mode above)
2. **Immediately spawn agents** using Task tool with parallel invocations

**Execution Flow**:
```
/clickup:process 86ew43633 86ew426dv 86ew44udu --work

1. Create 3 worktrees in parallel
2. Update 3 ClickUp tasks to "In Progress"
3. Spawn 3 agents in parallel (using Task tool)
   - Agent 1 → .worktrees/fix/86ew43633-price-step/
   - Agent 2 → .worktrees/fix/86ew426dv-hide-print-area/
   - Agent 3 → .worktrees/fix/86ew44udu-review-layout/
```

**Output**:
```
✅ Processed 3 tasks:

│ # │ Task ID    │ Title                    │ Branch                          │
│---|------------|--------------------------|----------------------------------|
│ 1 │ 86ew43633  │ Price step fix           │ fix/86ew43633-price-step        │
│ 2 │ 86ew426dv  │ Hide print area default  │ fix/86ew426dv-hide-print-area   │
│ 3 │ 86ew44udu  │ Review layout reorder    │ fix/86ew44udu-review-layout     │

🚀 Spawning 3 agents in parallel...

│ # │ Task ID    │ Port  │ Status     │
│---|------------|-------|------------|
│ 1 │ 86ew43633  │ 5556  │ 🔄 Working │
│ 2 │ 86ew426dv  │ 5557  │ 🔄 Working │
│ 3 │ 86ew44udu  │ 5558  │ 🔄 Working │

⏳ Agents working autonomously...
📊 Use /clickup:status to check progress
```

---

## Agent Spawning Details

When `--work` flag is used, spawn agents using the Task tool:

```javascript
// Spawn multiple agents in parallel using Task tool
// Each agent gets full context: task description + comments

Task: Work on ClickUp task: {task_title}

Working Directory: {project_root}/.worktrees/{branch-name}
Task ID: {task_id}
Priority: {priority}
Tags: {tags}

📝 DESCRIPTION:
{task_description}

💬 COMMENTS:
{formatted_comments}

📌 INSTRUCTIONS:
1. cd to the worktree directory
2. Read and understand the task requirements
3. Explore relevant code
4. Implement changes
5. Write/update tests
6. Run tests and linting
7. Report back when done or stuck

🚨 RULES:
- NEVER merge to staging
- NEVER run /clickup:done
- Report back with summary when complete
```

---

## Branch Naming Convention

| Task Type | Branch Prefix | Example |
|-----------|---------------|---------|
| Bug (has 'bug' tag) | `fix/` | `fix/86bqy2f6j-login-redirect` |
| Story/Feature | `feature/` | `feature/abc123-user-profile` |
| Task | `task/` | `task/def456-update-docs` |

## Worktree Location

Worktrees are created at: `.worktrees/{branch-name}/`

## Quick Reference

| Command | Creates | Updates ClickUp | Spawns Agents |
|---------|---------|-----------------|---------------|
| `/clickup:process <id>` | Branch | ✅ | ❌ |
| `/clickup:process <id> --worktree` | Worktree | ✅ | ❌ |
| `/clickup:process <id1> <id2>` | Worktrees | ✅ | ❌ |
| `/clickup:process <id1> <id2> --work` | Worktrees | ✅ | ✅ |

## Examples

### Quick Wins Batch Processing
```bash
# Process 6 quick wins and start agents immediately
/clickup:process 86ew43633 86ew426dv 86ew44udu 86ew47ma5 86ew4b4ju 86ew42uev --work
```

### Step-by-Step Processing
```bash
# First, set up worktrees
/clickup:process 86ew43633 86ew426dv 86ew44udu

# Then, spawn agents when ready
/clickup:work --all
```

## Error Handling

- Task ID not provided: Show usage instructions
- Task not found: Show error with task ID
- Task already in progress: Warn but allow continuing
- Branch already exists: Offer to use existing or create new
- Git worktree creation fails: Show git error and recovery steps
- API rate limit: Pause and retry with backoff

## Tool Coordination

- **Bash**: Git commands and curl for ClickUp API
- **Read**: Load `.env` and check existing worktrees
- **Task**: Spawn subagents when `--work` flag is used (run in parallel)

ARGUMENTS: $ARGUMENTS
