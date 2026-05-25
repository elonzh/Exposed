#!/bin/bash
# detect-changes.sh - Detect upstream documentation changes
# Outputs list of files that need translation

set -e

EN_DIR="documentation-website/Writerside/topics"
ZH_DIR="documentation-website-zh/Writerside/topics"

# Check if force translate is requested
if [ "$1" = "--all" ]; then
    echo "ALL"
    ls "$EN_DIR"/*.topic "$EN_DIR"/*.md 2>/dev/null | xargs -n1 basename
    exit 0
fi

# Get the last sync commit
LAST_SYNC=$(git log --format="%H" --grep="docs(zh): sync" -1 2>/dev/null || echo "")

if [ -z "$LAST_SYNC" ]; then
    echo "FIRST_SYNC"
    ls "$EN_DIR"/*.topic "$EN_DIR"/*.md 2>/dev/null | xargs -n1 basename
    exit 0
fi

# Find changed files since last sync
CHANGED_FILES=$(git diff --name-only "$LAST_SYNC" HEAD -- "$EN_DIR/" 2>/dev/null || echo "")

if [ -z "$CHANGED_FILES" ]; then
    # Also check for new files not in Chinese directory
    NEW_FILES=""
    for en_file in "$EN_DIR"/*.topic "$EN_DIR"/*.md; do
        [ -f "$en_file" ] || continue
        filename=$(basename "$en_file")
        zh_file="$ZH_DIR/$filename"
        if [ ! -f "$zh_file" ]; then
            NEW_FILES="$NEW_FILES $filename"
        fi
    done
    
    if [ -n "$NEW_FILES" ]; then
        echo "NEW_FILES"
        echo "$NEW_FILES" | tr ' ' '\n' | grep -v '^$'
    else
        echo "NO_CHANGES"
    fi
else
    echo "CHANGED"
    echo "$CHANGED_FILES" | xargs -n1 basename
fi
