#!/usr/bin/env bash
# Simple random quote display for shell startup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUOTES_FILE="$SCRIPT_DIR/quotes.json"

# Check if quotes file exists
if [[ ! -f "$QUOTES_FILE" ]]; then
    return 0
fi

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    return 0
fi

# Use Python to select and format a random quote
QUOTES_FILE="$QUOTES_FILE" python3 << 'EOF'
import json
import random
import textwrap
import os

# Configuration
BOX_WIDTH = 60
TEXT_WIDTH = BOX_WIDTH - 6  # Account for "│  " (3) on left and "  │" (3) on right

quotes_file = os.environ.get('QUOTES_FILE')

try:
    with open(quotes_file, 'r') as f:
        quotes = json.load(f)

    if not quotes:
        exit(0)

    # Select random quote
    selected = random.choice(quotes)
    quote_text = selected['quote']
    author = selected['author']

    # Wrap the quote text
    wrapped_lines = textwrap.wrap(quote_text, width=TEXT_WIDTH)

    # Print the box
    print()
    print("╭" + "─" * (BOX_WIDTH - 2) + "╮")
    print("│" + " " * (BOX_WIDTH - 2) + "│")

    # Print wrapped quote lines
    for line in wrapped_lines:
        padding = " " * (TEXT_WIDTH - len(line))
        print(f"│  {line}{padding}  │")

    # Print empty line
    print("│" + " " * (BOX_WIDTH - 2) + "│")

    # Print author line
    author_line = f"— {author}"
    author_padding = " " * (TEXT_WIDTH - len(author_line))
    print(f"│  {author_line}{author_padding}  │")

    print("╰" + "─" * (BOX_WIDTH - 2) + "╯")
    print()

except (FileNotFoundError, json.JSONDecodeError, KeyError):
    pass
EOF
