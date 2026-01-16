#!/bin/bash
# ClickUp API Utilities for Claude Code Slash Commands

CLICKUP_API_BASE="https://api.clickup.com/api/v2"

# Load environment variables from .env file
# Searches: current dir -> git root -> main worktree
load_env() {
  local env_file=""

  # Try current directory first
  if [ -f ".env" ]; then
    env_file=".env"
  # Try git root (works for regular repos)
  elif [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/.env" ]; then
    env_file="$(git rev-parse --show-toplevel)/.env"
  # Try main worktree (for git worktrees)
  elif [ -d "$(git rev-parse --git-common-dir 2>/dev/null)/../" ]; then
    local main_worktree
    main_worktree=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)
    if [ -f "${main_worktree}/.env" ]; then
      env_file="${main_worktree}/.env"
    fi
  fi

  if [ -n "$env_file" ] && [ -f "$env_file" ]; then
    export $(grep -E "^CLICKUP_" "$env_file" | xargs)
    return 0
  else
    echo "Warning: .env file not found" >&2
    return 1
  fi
}

# Get the main project directory (works from worktrees too)
get_main_project_dir() {
  if [ -d "$(git rev-parse --git-common-dir 2>/dev/null)/../" ]; then
    cd "$(git rev-parse --git-common-dir)/.." && pwd
  else
    git rev-parse --show-toplevel 2>/dev/null || pwd
  fi
}

# Generic ClickUp API call wrapper
# Usage: clickup_api METHOD ENDPOINT [DATA]
clickup_api() {
  local method="$1"
  local endpoint="$2"
  local data="$3"

  if [ -z "$CLICKUP_TOKEN" ]; then
    echo "Error: CLICKUP_TOKEN not set" >&2
    return 1
  fi

  local args=(-s -X "$method" "${CLICKUP_API_BASE}${endpoint}")
  args+=(-H "Authorization: $CLICKUP_TOKEN")
  args+=(-H "Content-Type: application/json")

  if [ -n "$data" ]; then
    args+=(-d "$data")
  fi

  curl "${args[@]}"
}

# Get tasks from a list with optional status filter
# Usage: get_tasks [status]
get_tasks() {
  local status="${1:-To Do}"
  local encoded_status
  encoded_status=$(printf '%s' "$status" | jq -sRr @uri 2>/dev/null || echo "$status" | sed 's/ /%20/g')

  clickup_api GET "/list/${CLICKUP_LIST_ID}/task?statuses[]=${encoded_status}&include_closed=false"
}

# Get a single task by ID
# Usage: get_task TASK_ID
get_task() {
  local task_id="$1"
  clickup_api GET "/task/${task_id}"
}

# Update task status
# Usage: update_task_status TASK_ID STATUS
update_task_status() {
  local task_id="$1"
  local status="$2"
  clickup_api PUT "/task/${task_id}" "{\"status\": \"${status}\"}"
}

# Get custom fields for a list
# Usage: get_custom_fields
get_custom_fields() {
  clickup_api GET "/list/${CLICKUP_LIST_ID}/field"
}

# Update a custom field value
# Usage: update_custom_field TASK_ID FIELD_ID VALUE
update_custom_field() {
  local task_id="$1"
  local field_id="$2"
  local value="$3"
  clickup_api POST "/task/${task_id}/field/${field_id}" "{\"value\": \"${value}\"}"
}

# Add a comment to a task
# Usage: add_comment TASK_ID COMMENT
add_comment() {
  local task_id="$1"
  local comment="$2"
  # Escape the comment for JSON
  local escaped_comment
  escaped_comment=$(printf '%s' "$comment" | jq -Rs .)
  clickup_api POST "/task/${task_id}/comment" "{\"comment_text\": ${escaped_comment}}"
}

# Extract task ID from branch name
# Usage: extract_task_id BRANCH_NAME
extract_task_id() {
  local branch="$1"
  echo "$branch" | sed -n 's/^[^/]*\/\([a-z0-9]*\)-.*/\1/p'
}

# Get current git branch
get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Slugify a string for use in branch names
# Usage: slugify "Some Title Here"
slugify() {
  local str="$1"
  echo "$str" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-//' | \
    sed 's/-$//' | \
    cut -c1-50
}

# Determine branch prefix from task tags
# Usage: get_branch_prefix TAGS_JSON
get_branch_prefix() {
  local tags_json="$1"
  local has_bug
  has_bug=$(echo "$tags_json" | jq -r '.[] | select(.name | test("bug"; "i")) | .name' 2>/dev/null)

  if [ -n "$has_bug" ]; then
    echo "fix"
  else
    echo "feature"
  fi
}

# Format priority for display
format_priority() {
  local priority="$1"
  case "$priority" in
    1) echo "🔴 Urgent" ;;
    2) echo "🟠 High" ;;
    3) echo "🟡 Normal" ;;
    4) echo "🟢 Low" ;;
    *) echo "⚪ None" ;;
  esac
}

# Format task type for display
format_type() {
  local tags_json="$1"
  local has_bug
  has_bug=$(echo "$tags_json" | jq -r '.[] | select(.name | test("bug"; "i")) | .name' 2>/dev/null)

  if [ -n "$has_bug" ]; then
    echo "🐛"
  else
    echo "📖"
  fi
}

# ============================================
# TMUX Session Helpers
# ============================================

# Get scripts directory (in main project)
get_scripts_dir() {
  local main_dir
  main_dir=$(get_main_project_dir)
  echo "${main_dir}/scripts/clickup"
}

# Check if tmux session exists for task
# Usage: has_tmux_session TASK_ID
has_tmux_session() {
  local task_id="$1"
  tmux has-session -t "clickup-${task_id}" 2>/dev/null
}

# Get tmux session status for task
# Usage: get_tmux_status TASK_ID
get_tmux_status() {
  local task_id="$1"
  if has_tmux_session "$task_id"; then
    echo "active"
  else
    echo "inactive"
  fi
}

# Spawn agent in tmux session
# Usage: spawn_agent TASK_ID WORKTREE_PATH [PROMPT]
spawn_agent() {
  local task_id="$1"
  local worktree="$2"
  local prompt="$3"
  local scripts_dir
  scripts_dir=$(get_scripts_dir)

  if [ -x "${scripts_dir}/tmux-spawn-agent.sh" ]; then
    "${scripts_dir}/tmux-spawn-agent.sh" "$task_id" "$worktree" "$prompt"
  else
    echo "Error: tmux-spawn-agent.sh not found or not executable" >&2
    return 1
  fi
}

# Attach to agent tmux session
# Usage: attach_agent TASK_ID
attach_agent() {
  local task_id="$1"
  local scripts_dir
  scripts_dir=$(get_scripts_dir)

  if [ -x "${scripts_dir}/tmux-attach.sh" ]; then
    "${scripts_dir}/tmux-attach.sh" "$task_id"
  else
    tmux attach -t "clickup-${task_id}"
  fi
}

# Kill agent tmux session
# Usage: kill_agent TASK_ID [--cleanup]
kill_agent() {
  local task_id="$1"
  local cleanup="$2"
  local scripts_dir
  scripts_dir=$(get_scripts_dir)

  if [ -x "${scripts_dir}/tmux-kill.sh" ]; then
    "${scripts_dir}/tmux-kill.sh" "$task_id" "$cleanup"
  else
    tmux kill-session -t "clickup-${task_id}" 2>/dev/null
  fi
}

# List all active agent sessions
list_agents() {
  local scripts_dir
  scripts_dir=$(get_scripts_dir)

  if [ -x "${scripts_dir}/tmux-list-agents.sh" ]; then
    "${scripts_dir}/tmux-list-agents.sh" "$@"
  else
    tmux ls 2>/dev/null | grep "clickup-" || echo "No active sessions"
  fi
}

# ============================================
# Worktree Helpers
# ============================================

# Cleanup worktree with two-phase removal
# Usage: cleanup_worktree WORKTREE_PATH
cleanup_worktree() {
  local worktree="$1"
  local scripts_dir
  scripts_dir=$(get_scripts_dir)

  if [ -x "${scripts_dir}/wt-cleanup.sh" ]; then
    "${scripts_dir}/wt-cleanup.sh" "$worktree"
  else
    # Fallback two-phase cleanup
    git worktree remove "$worktree" --force 2>/dev/null || true
    [ -d "$worktree" ] && rm -rf "$worktree"
    git worktree prune
  fi
}

# Find worktree path by task ID
# Usage: find_worktree_by_task TASK_ID
find_worktree_by_task() {
  local task_id="$1"
  local main_dir
  main_dir=$(get_main_project_dir)

  find "${main_dir}/.worktrees" -maxdepth 3 -type d -name "*${task_id}*" 2>/dev/null | head -1
}

# Get worktree status summary
# Usage: get_worktree_status WORKTREE_PATH
get_worktree_status() {
  local worktree="$1"

  if [ ! -d "$worktree" ]; then
    echo "not_found"
    return
  fi

  local changes
  changes=$(git -C "$worktree" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

  if [ "$changes" -eq 0 ]; then
    echo "clean"
  else
    echo "modified:$changes"
  fi
}

# ============================================
# Node Modules Installation
# ============================================

# Install dependencies in worktree (fresh, no symlink)
# Usage: install_worktree_deps WORKTREE_PATH
install_worktree_deps() {
  local worktree="$1"

  if [ ! -d "$worktree" ]; then
    echo "Error: Worktree not found: $worktree" >&2
    return 1
  fi

  cd "$worktree" || return 1

  # Remove symlinked node_modules if exists
  if [ -L node_modules ]; then
    echo "Removing symlinked node_modules..."
    rm node_modules
  fi

  # Install fresh dependencies
  if command -v pnpm &> /dev/null; then
    echo "Installing dependencies with pnpm..."
    pnpm install --prefer-offline
  elif command -v npm &> /dev/null; then
    echo "Installing dependencies with npm..."
    npm install --prefer-offline
  else
    echo "Error: No package manager found (pnpm or npm)" >&2
    return 1
  fi

  # Verify installation
  if [ ! -d node_modules ] || [ -L node_modules ]; then
    echo "Error: node_modules installation failed or still symlinked" >&2
    return 1
  fi

  echo "Dependencies installed successfully"
}
