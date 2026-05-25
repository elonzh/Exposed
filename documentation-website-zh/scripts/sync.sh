#!/bin/bash
# sync.sh - Main sync and translation workflow
# This script is called by opencode to sync and translate documentation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "=== Exposed Documentation Sync ==="
echo ""

# Step 1: Detect changes
echo "Step 1: Detecting changes..."
CHANGES=$(bash "$SCRIPT_DIR/detect-changes.sh" "$@")

if [ "$CHANGES" = "NO_CHANGES" ]; then
    echo "No changes detected. Nothing to do."
    exit 0
fi

echo "Changes detected:"
echo "$CHANGES" | tail -n +2
echo ""

# Step 2: Sync resources
echo "Step 2: Syncing resources..."
bash "$SCRIPT_DIR/sync-resources.sh"
echo ""

# Step 3: List files to translate
echo "Step 3: Files to translate:"
FILES_TO_TRANSLATE=$(echo "$CHANGES" | tail -n +2)
for file in $FILES_TO_TRANSLATE; do
    echo "  - $file"
done
echo ""

echo "=== Sync preparation complete ==="
echo ""
echo "Next steps:"
echo "1. Translate the listed files from English to Chinese"
echo "2. Run: bash documentation-website-zh/scripts/build.sh"
echo "3. Run: bash documentation-website-zh/scripts/commit.sh"
