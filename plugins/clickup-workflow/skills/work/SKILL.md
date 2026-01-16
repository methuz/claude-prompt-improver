---
name: work
description: "Spawn subagent(s) to work on ClickUp task(s) in their worktree folders"
category: integration
complexity: advanced
mcp-servers: []
personas: []
---

# /clickup:work - Spawn Subagent to Work on Task(s)

## Purpose
Spawn autonomous Claude agents in tmux sessions to work on ClickUp task(s) in their respective worktree folders. Each agent runs in an interactive tmux session that you can attach to for real-time interaction.

## Usage
```
/clickup:work <task_id>                    # Work on a single task
/clickup:work <id1> <id2> <id3>            # Work on multiple specific tasks
/clickup:work --all                        # Work on all "In Progress" tasks
```

## Agent Session Controls
After spawning, use these commands to interact with agents:
- `/clickup:attach <task_id>` - Attach to agent's tmux session for real-time interaction
- `/clickup:kill <task_id>` - Terminate an agent session
- `/clickup:status` - View all agent sessions and their status

## Prerequisites
- Tasks should be processed via `/clickup:process` first (creates worktree)
- If worktree doesn't exist, will auto-create it (runs process internally)

## Behavioral Flow

### Multi-Task Mode (`/clickup:work <id1> <id2> ...`)

When multiple task IDs are provided:

1. **Parse Task IDs**: Extract all task IDs from arguments
2. **Fetch Full Context for Each Task**:
   - Fetch task details (title, description, priority, tags)
   - Fetch task comments (recent 10 for each)
   - This provides complete context for each subagent
3. **Setup Worktrees**: For each task, ensure worktree exists (auto-create if missing)
4. **Assign Ports**: Each worktree gets unique port starting from 5556
   ```
   Task 1: PORT=5556
   Task 2: PORT=5557
   Task 3: PORT=5558
   ```
5. **Spawn Agents in Parallel**: Launch subagent for each task with full context
6. **Track Progress**: Monitor all agents and report status

### Single Task Mode (`/clickup:work <task_id>`)

1. **Load Environment**: Read ClickUp credentials from `.env`

2. **Fetch Task Details**: Get comprehensive task info from ClickUp API:
   ```bash
   # Get task with all details
   curl -s "https://api.clickup.com/api/v2/task/${TASK_ID}" \
     -H "Authorization: ${CLICKUP_TOKEN}"
   ```

   Extract from response:
   - `name`: Task title
   - `description`: Full task description (may contain markdown)
   - `text_content`: Plain text version of description
   - `status.status`: Current status
   - `tags`: Array of tags (for bug/feature detection)
   - `custom_fields`: Including branch name if set
   - `priority`: Task priority level
   - `assignees`: Who's assigned

3. **Fetch Task Comments**: Get all comments for additional context:
   ```bash
   curl -s "https://api.clickup.com/api/v2/task/${TASK_ID}/comment" \
     -H "Authorization: ${CLICKUP_TOKEN}"
   ```

   Extract from response:
   - `comments[].comment_text`: Comment content
   - `comments[].user.username`: Who wrote the comment
   - `comments[].date`: When it was written

   Filter to most recent 10 comments to avoid context overflow.

4. **Validate Task**:
   - Verify task exists
   - Verify status is "In Progress"
   - Get branch name from custom field

5. **Locate Worktree**:
   - Find worktree at `.worktrees/{branch-name}/`
   - If not found, prompt user to run `/clickup:process <task_id>` first

6. **Setup Worktree Environment**:
   ```bash
   cd .worktrees/{branch-name}

   # Check if .env exists (should be symlinked from /clickup:process)
   if [ ! -f .env ]; then
     ln -sf "$(git rev-parse --show-toplevel)/.env" .env
   fi

   # IMPORTANT: Ensure fresh node_modules (not symlinked)
   if [ -L node_modules ]; then
     rm node_modules  # Remove symlink
   fi

   # Install dependencies - fresh copy per worktree
   if [ ! -d node_modules ] || [ package.json -nt node_modules ]; then
     if command -v pnpm &> /dev/null; then
       pnpm install --prefer-offline
     else
       npm install --prefer-offline
     fi
   fi

   # Verify node_modules is not symlinked
   if [ -L node_modules ]; then
     echo "ERROR: node_modules is still symlinked"
     exit 1
   fi

   # Assign unique port for this worktree (base 5556 + index)
   # Write port to .worktree-port file for reference
   echo "PORT=${ASSIGNED_PORT}" > .worktree-port

   # Check for Prisma schema changes
   npx prisma db pull --print > /tmp/current_schema.prisma 2>/dev/null
   if ! diff -q prisma/schema.prisma /tmp/current_schema.prisma > /dev/null 2>&1; then
     echo "⚠️ SCHEMA CHANGE DETECTED"
   fi
   ```

7. **Schema Change Detection** (CRITICAL):
   - Compare local `prisma/schema.prisma` with database schema
   - If schema differs:
     ```
     ⚠️ SCHEMA CHANGE DETECTED

     The task's schema differs from the database.
     Since we share one database, this could cause conflicts.

     Options:
     1. Review schema changes manually
     2. Skip this task for now
     3. Proceed anyway (risky)

     Pausing for user decision...
     ```
   - **PAUSE and report to user** - do not proceed without confirmation

8. **Spawn Agent in tmux Session**:
   Use the tmux-spawn-agent.sh script to spawn an autonomous Claude agent:

   ```bash
   # Spawn agent in tmux session
   ./scripts/clickup/tmux-spawn-agent.sh {task_id} .worktrees/{branch-name} "
   Work on ClickUp task: {task_title}

   Task ID: {task_id}
   Priority: {priority}
   Tags: {tags_list}

   📝 DESCRIPTION:
   {task_description}

   💬 COMMENTS:
   {formatted_comments}

   📌 INSTRUCTIONS:
   1. Read and understand the task requirements
   2. Explore the codebase to understand relevant code
   3. Implement the required changes
   4. Write/update tests as needed
   5. Run tests to verify changes work
   6. Commit your changes with a descriptive message

   🚨 RULES:
   - NEVER merge to staging
   - ALWAYS commit your work before reporting complete
   - If stuck, leave a clear message and exit
   "
   ```

   The agent runs in tmux session `clickup-{task_id}` with `--dangerously-skip-permissions` for autonomous operation.

9. **Output**:
   ```
   🚀 Spawned agent for task: {task_title}

   📁 Worktree: .worktrees/{branch-name}
   📋 Task ID: {task_id}
   🖥️  tmux Session: clickup-{task_id}

   Agent controls:
   • Attach: /clickup:attach {task_id}
   • Kill:   /clickup:kill {task_id}
   • Status: /clickup:status

   ⏳ Agent working autonomously...
   ```

### All Tasks Mode (`/clickup:work --all`)

Same as multi-task mode, but automatically fetches all "In Progress" tasks:

1. **Fetch "In Progress" Tasks**:
   ```bash
   curl -s "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task?statuses[]=in%20progress" \
     -H "Authorization: ${CLICKUP_TOKEN}"
   ```

2. Then follows same flow as multi-task mode (validate, setup, assign ports, spawn)

## Orchestration & Progress Tracking

When spawning multiple agents, each runs in its own tmux session:

1. **tmux Session Naming**: Each agent gets session `clickup-{task_id}`
   ```bash
   # List all ClickUp agent sessions
   tmux ls | grep clickup-

   # Example output:
   clickup-86abc123: 1 windows (created Thu Jan  9 06:30:00 2026)
   clickup-86def456: 1 windows (created Thu Jan  9 06:30:01 2026)
   clickup-86ghi789: 1 windows (created Thu Jan  9 06:30:02 2026)
   ```

2. **Agent Interaction**: Attach to any agent for real-time control
   ```bash
   # Attach to specific agent
   /clickup:attach 86abc123

   # Inside tmux session:
   # - See exactly what the agent is doing
   # - Provide guidance or corrections
   # - Detach with Ctrl+B then D
   ```

3. **Progress Dashboard**: Use `/clickup:status` for overview
   ```
   ┌─────────────────────────────────────────────────────────────┐
   │  🤖 ClickUp Agent Dashboard                                 │
   ├─────────────────────────────────────────────────────────────┤
   │  86abc123 │ 🔄 Active  │ clickup-86abc123 │ fix/...         │
   │  86def456 │ ✅ Exited  │ -                │ feature/...     │
   │  86ghi789 │ 🔄 Active  │ clickup-86ghi789 │ fix/...         │
   └─────────────────────────────────────────────────────────────┘

   Commands: /clickup:attach <id>  |  /clickup:kill <id>
   ```

3. **Schema Conflict Check** (CRITICAL):
   - Before spawning ANY agents, check ALL worktrees for schema differences
   - If ANY schema differs:
     ```
     ⚠️ SCHEMA CONFLICTS DETECTED

     The following tasks have schema changes:
     - {task_id_1}: {branch_name_1}
     - {task_id_2}: {branch_name_2}

     Since we share one database, only one schema can be active.
     Please resolve schema conflicts before proceeding.

     Pausing for user decision...
     ```
   - **PAUSE and report to user** - do not spawn any agents

4. **Output on Start**:
   ```
   🚀 Spawning 3 agents:

   │ # │ Task ID   │ Title                    │ Port │ Branch              │
   │---|-----------|--------------------------|------|---------------------|
   │ 1 │ 86abc123  │ Fix payment webhook      │ 5556 │ fix/86abc123-pay... │
   │ 2 │ 86def456  │ Add user avatar          │ 5557 │ feature/86def456... │
   │ 3 │ 86ghi789  │ Login redirect bug       │ 5558 │ fix/86ghi789-log... │

   ⏳ Agents working in parallel...
   📊 Use /clickup:status to check progress
   ```

## Subagent Reporting

Subagents report back with structured messages:

### Success Report
```
✅ TASK COMPLETE: {task_title}

Branch: {branch_name}
Task ID: {task_id}

Changes Made:
- {list of files changed}
- {summary of implementation}

Tests:
- {test results summary}

Ready for manual review and merge.
```

### Stuck Report
```
❌ STUCK: {task_title}

Branch: {branch_name}
Task ID: {task_id}

Issue:
{detailed description of the problem}

Attempted:
- {what was tried}

Need:
- {specific help or clarification needed}
```

### Clarification Report
```
❓ NEED CLARIFICATION: {task_title}

Branch: {branch_name}
Task ID: {task_id}

Questions:
1. {specific question}
2. {specific question}

Context:
{relevant context for the questions}
```

## Error Handling

- Task ID not provided and no `--all` flag: Show usage instructions
- Task not found: Show error with task ID
- Task not "In Progress": Suggest running `/clickup:process` first
- Worktree not found: Show error and suggest `/clickup:process`
- Schema conflict: **PAUSE** and report to user (never proceed automatically)
- npm install fails: Report error and pause
- Prisma issues: Report error and pause

## Safety Rules

1. **NEVER merge automatically** - all merges are manual
2. **NEVER run /clickup:done** - report back instead
3. **PAUSE on schema changes** - single database means conflicts possible
4. **Report all blockers** - never silently fail

## Tool Coordination

- **tmux-spawn-agent.sh**: Primary method - spawns Claude in interactive tmux session
- **Bash**: Git commands, npm, prisma, curl for ClickUp API
- **Read**: Load `.env`, check worktrees, read task descriptions
- **AskUser**: Get confirmation on schema conflicts

## Related Commands

- `/clickup:attach <id>` - Attach to agent session for real-time interaction
- `/clickup:kill <id>` - Terminate agent session
- `/clickup:status` - View all agent statuses
- `/clickup:done <id>` - Complete workflow (merge, update ClickUp, cleanup)

ARGUMENTS: $ARGUMENTS
