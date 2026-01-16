# ClickUp Workflow

ClickUp integration for Claude Code with task management, parallel development using git worktrees, and autonomous agent orchestration via tmux sessions.

## Features

- **Task Management**: List, view details, create, update, and comment on ClickUp tasks
- **Git Worktrees**: Automatic branch and worktree creation for parallel development
- **Agent Orchestration**: Spawn autonomous Claude agents in tmux sessions
- **Real-time Monitoring**: Attach to agent sessions, monitor progress, provide guidance

## Installation

```bash
claude plugin install clickup-workflow@methuz-claude-marketplace
```

## Configuration

### 1. ClickUp API Token

Add to your project's `.env` file:

```env
CLICKUP_TOKEN=pk_your_api_token_here
CLICKUP_LIST_ID=your_list_id_here
```

Get your token from: https://app.clickup.com/settings/apps

### 2. Custom Field Configuration (Optional)

If you use a custom "branch" field in ClickUp, copy and configure the config file:

```bash
# Find your plugin installation
PLUGIN_PATH=$(find ~/.claude/plugins/cache/methuz-claude-marketplace/clickup-workflow -name "config.json.template" | head -1 | xargs dirname)

# Copy template to config.json
cp "$PLUGIN_PATH/config.json.template" "$PLUGIN_PATH/config.json"

# Edit with your custom field ID
# Get field ID from ClickUp API: GET /list/{list_id}/field
```

## Commands

| Command | Purpose |
|---------|---------|
| `/clickup:list` | List tasks by status |
| `/clickup:detail <id>` | View task details & comments |
| `/clickup:process <id>` | Start task - create branch + worktree |
| `/clickup:work <id>` | Spawn agent in tmux session |
| `/clickup:attach <id>` | Attach to agent's tmux session |
| `/clickup:kill <id>` | Terminate agent tmux session |
| `/clickup:done` | Complete task - merge + update ClickUp |
| `/clickup:status` | Show active agents & worktrees |
| `/clickup:add <title> <tag>` | Create new task |
| `/clickup:comment <prompt>` | Add AI-generated comment |
| `/clickup:update <id> <prompt>` | Update task via natural language |

## Workflows

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
/clickup:process 86abc 86def 86ghi    # Create worktrees for all
/clickup:work --all                   # Spawn agents for all
/clickup:status                       # Monitor progress
```

### One-Command Parallel Workflow
```
/clickup:process 86abc 86def 86ghi --work   # Process AND spawn agents
/clickup:status                              # Monitor progress
```

## Requirements

- `jq` - JSON processor
- `git` - For branch/worktree operations
- `tmux` - For agent session management
- `curl` - For ClickUp API calls

## License

MIT
