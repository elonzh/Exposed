#!/bin/bash
# sync.sh - Main sync and translation workflow
# This script is called by opencode to sync and translate documentation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

EN_DIR="documentation-website/Writerside/topics"
ZH_DIR="documentation-website-zh/Writerside/topics"

echo "=== Exposed Documentation Sync ==="
echo ""

# Step 0: Fetch and merge upstream changes
echo "Step 0: Fetching upstream changes..."
bash "$SCRIPT_DIR/fetch-upstream.sh"
echo ""

# Step 1: Detect changes
echo "Step 1: Detecting changes..."
CHANGES=$(bash "$SCRIPT_DIR/detect-changes.sh" "$@" 2>&1)

if [ "$CHANGES" = "NO_CHANGES" ]; then
    echo "No changes detected. Nothing to do."
    exit 0
fi

echo "Changes detected:"
echo ""

# Parse change types
MODIFIED_FILES=""
NEW_FILES=""
DELETED_FILES=""

while IFS= read -r line; do
    case "$line" in
        MODIFIED:*)
            file="${line#MODIFIED:}"
            MODIFIED_FILES="$MODIFIED_FILES $file"
            echo "  [M] $file (needs re-translation)"
            ;;
        NEW:*)
            file="${line#NEW:}"
            NEW_FILES="$NEW_FILES $file"
            echo "  [+] $file (new, needs translation)"
            ;;
        DELETED:*)
            file="${line#DELETED:}"
            DELETED_FILES="$DELETED_FILES $file"
            echo "  [-] $file (deleted in upstream)"
            ;;
        CHANGED|ALL|FIRST_SYNC)
            echo "  Mode: $line"
            ;;
        *)
            # For --all or FIRST_SYNC, all files are listed without prefix
            if [ -n "$line" ]; then
                MODIFIED_FILES="$MODIFIED_FILES $line"
                echo "  [*] $line"
            fi
            ;;
    esac
done <<< "$CHANGES"

echo ""

# Step 2: Handle deletions
if [ -n "$DELETED_FILES" ]; then
    echo "Step 2: Handling deleted files..."
    for file in $DELETED_FILES; do
        zh_file="$ZH_DIR/$file"
        if [ -f "$zh_file" ]; then
            echo "  Removing: $zh_file"
            rm "$zh_file"
        fi
    done
    echo ""
fi

# Step 3: List files to translate
FILES_TO_TRANSLATE="$MODIFIED_FILES $NEW_FILES"
FILES_TO_TRANSLATE=$(echo "$FILES_TO_TRANSLATE" | xargs)

if [ -n "$FILES_TO_TRANSLATE" ]; then
    echo "Step 3: Files to translate:"
    for file in $FILES_TO_TRANSLATE; do
        en_file="$EN_DIR/$file"
        zh_file="$ZH_DIR/$file"
        if [ -f "$en_file" ]; then
            en_lines=$(wc -l < "$en_file")
            if [ -f "$zh_file" ]; then
                zh_lines=$(wc -l < "$zh_file")
                echo "  - $file (EN: ${en_lines}L, ZH: ${zh_lines}L)"
            else
                echo "  - $file (EN: ${en_lines}L, ZH: NEW)"
            fi
        fi
    done
    echo ""
fi

# Summary
echo "=== Sync Summary ==="
[ -n "$MODIFIED_FILES" ] && echo "Modified: $(echo $MODIFIED_FILES | wc -w) files"
[ -n "$NEW_FILES" ] && echo "New: $(echo $NEW_FILES | wc -w) files"
[ -n "$DELETED_FILES" ] && echo "Deleted: $(echo $DELETED_FILES | wc -w) files"
echo ""

echo "Next steps:"
echo "1. Translate the listed files from English to Chinese"
echo "2. Run: bash documentation-website-zh/scripts/build.sh"
echo "3. Run: bash documentation-website-zh/scripts/commit.sh"
