# Prompt Improver

A Claude Code plugin that automatically provides grammar corrections and refined versions of your prompts before Claude responds.

## What It Does

Every time you submit a prompt, Claude will first output:

> **1. Grammar**: [Your prompt with corrected grammar, spelling, and punctuation]
> **2. Refined**: [Your prompt rewritten as a highly educated writer would phrase it]

Then Claude proceeds with the actual response.

## Example

**You type:**
```
why this dont work good
```

**Claude responds:**
> **1. Grammar**: Why doesn't this work well?
> **2. Refined**: What is preventing this from functioning properly?

[Then the actual answer to your question...]

## Installation

### Option 1: Install from Local Path

```bash
# Clone this repository
git clone https://github.com/rubick/claude-prompt-improver.git ~/Workspace/claude/prompt-improver

# Install the plugin
claude plugins install ~/Workspace/claude/prompt-improver
```

### Option 2: Install from GitHub (when published)

```bash
claude plugins install rubick/claude-prompt-improver
```

### Manual Installation

If the plugin system doesn't work, add this to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/prompt-improver/hooks/prompt-improver.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

## Configuration

Edit `hooks/prompt-improver.py` to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `MIN_PROMPT_LENGTH` | `10` | Skip prompts shorter than this |
| `SKIP_PREFIXES` | `("/", "!", "?")` | Skip prompts starting with these |
| `SKIP_EXACT` | `{"y", "n", "yes", ...}` | Skip these exact phrases |

## Customizing the Output Style

Edit the `create_instruction()` function in `prompt-improver.py`:

### Academic Style
```python
Output format (use exactly):
> **1. Corrected**: [grammatically correct version]
> **2. Academic**: [formal academic prose]
> **3. Concise**: [shortened essential version]
```

### Technical Style
```python
Output format (use exactly):
> **1. Grammar**: [fix errors]
> **2. Technical**: [as a senior engineer would phrase it]
```

### Minimal Style
```python
Output format (use exactly):
> **Corrected**: [grammar fixed]
```

## How It Works

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  User types     │────▶│  prompt-improver.py  │────▶│  Claude sees    │
│  prompt         │     │  intercepts &        │     │  instruction +  │
│                 │     │  adds instruction    │     │  original       │
└─────────────────┘     └──────────────────────┘     └─────────────────┘
```

1. You submit a prompt
2. Claude Code triggers the `UserPromptSubmit` hook
3. The hook script outputs a `<MANDATORY-FIRST-RESPONSE>` instruction
4. Claude follows the instruction, providing corrections first
5. Claude then answers your actual question

## Skipped Prompts

The plugin automatically skips:
- Very short prompts (< 10 characters)
- Slash commands (`/help`, `/clear`, etc.)
- Simple confirmations (`yes`, `no`, `ok`, `thanks`)

## Uninstall

```bash
claude plugins uninstall prompt-improver
```

Or manually remove the hook from `~/.claude/settings.json`.

## License

MIT License - feel free to modify and share!

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
