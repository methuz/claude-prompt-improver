#!/usr/bin/env python3
"""
Claude Code Plugin: Prompt Improver
Automatically provides grammar corrections and refined versions of user prompts.

This hook intercepts user prompts and instructs Claude to provide:
1. Grammar-corrected version
2. Refined version as a highly educated writer would phrase it
"""

import sys
import json
import os

# Configuration
MIN_PROMPT_LENGTH = 10  # Skip prompts shorter than this
SKIP_PREFIXES = ("/", "!", "?")  # Skip commands and single-char inputs
SKIP_EXACT = {"y", "n", "yes", "no", "ok", "okay", "sure", "thanks", "thank you"}


def should_skip(prompt: str) -> bool:
    """Determine if prompt should be skipped."""
    # Too short
    if len(prompt) < MIN_PROMPT_LENGTH:
        return True

    # Starts with command prefix
    if prompt.startswith(SKIP_PREFIXES):
        return True

    # Exact match skip words
    if prompt.lower().strip() in SKIP_EXACT:
        return True

    return False


def create_instruction(prompt: str) -> str:
    """Generate the instruction block for Claude."""
    return f"""<user-prompt-submit-hook>
<MANDATORY-FIRST-RESPONSE>
BEFORE ANY OTHER RESPONSE, you MUST first output these two corrections in a compact block:

Original: "{prompt}"

Output format (use exactly):
> **1. Grammar**: [corrected version with proper grammar, spelling, punctuation]
> **2. Refined**: [rewritten as a highly educated writer would phrase it - eloquent, precise, professional]

Then add a blank line and proceed with your actual response to the user's request.
If the original is already perfect, just note "✓ Original is well-written" and proceed.
</MANDATORY-FIRST-RESPONSE>
</user-prompt-submit-hook>"""


def main():
    """Main entry point."""
    # Read JSON input from Claude Code via stdin
    try:
        input_data = sys.stdin.read()
        data = json.loads(input_data)
        prompt = data.get("prompt", "")
    except (json.JSONDecodeError, KeyError):
        # Silent fail on bad input
        sys.exit(0)

    # Check if we should skip this prompt
    if should_skip(prompt):
        sys.exit(0)

    # Output the instruction block
    print(create_instruction(prompt))
    sys.exit(0)


if __name__ == "__main__":
    main()
