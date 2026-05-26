#!/bin/bash
# fetch-upstream.sh - Fetch and merge upstream changes from JetBrains/Exposed
# Always merges upstream into current branch; reports doc changes for translation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

EN_DIR="documentation-website/Writerside/topics"
UPSTREAM_URL="https://github.com/JetBrains/Exposed.git"
UPSTREAM_BRANCH="main"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "=== Fetching Upstream Changes ==="
echo "Current branch: $CURRENT_BRANCH"

# Ensure upstream remote exists
if ! git remote get-url upstream &>/dev/null; then
    echo "Adding upstream remote..."
    git remote add upstream "$UPSTREAM_URL"
fi

# Fetch upstream
echo "Fetching from $UPSTREAM_URL..."
git fetch upstream --quiet

# Check for structural changes before merging
echo "Checking for structural changes..."
STRUCTURAL_CHANGES=""

# Check if EN_DIR still exists in upstream
if ! git ls-tree -d --name-only "upstream/$UPSTREAM_BRANCH" -- "$EN_DIR" &>/dev/null; then
    STRUCTURAL_CHANGES="$STRUCTURAL_CHANGES\nWARNING: Upstream directory $EN_DIR may have been moved or deleted!"
fi

# Check for renamed/moved documentation files
UPSTREAM_DIFF=$(git diff --name-status "upstream/$UPSTREAM_BRANCH" HEAD -- "$EN_DIR/" 2>/dev/null | grep "^R" || true)
if [ -n "$UPSTREAM_DIFF" ]; then
    STRUCTURAL_CHANGES="$STRUCTURAL_CHANGES\nWARNING: Files have been renamed in upstream:"
    STRUCTURAL_CHANGES="$STRUCTURAL_CHANGES\n$UPSTREAM_DIFF"
fi

# Report structural changes
if [ -n "$STRUCTURAL_CHANGES" ]; then
    echo ""
    echo "=== Structural Changes Detected ==="
    echo -e "$STRUCTURAL_CHANGES"
    echo ""
    echo "Please review these changes carefully after merge."
    echo ""
fi

# Always merge upstream changes (code, docs, snippets, images, etc.)
echo "Merging upstream/$UPSTREAM_BRANCH into $CURRENT_BRANCH..."
if git merge "upstream/$UPSTREAM_BRANCH" --no-edit --quiet 2>/dev/null; then
    echo "Merge completed successfully."
else
    echo "Merge conflict detected. Attempting to resolve..."

    # Check if only documentation conflicts exist
    CONFLICTED_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
    DOC_CONFLICTS=""
    OTHER_CONFLICTS=""

    for file in $CONFLICTED_FILES; do
        if [[ "$file" == documentation-website-zh/* ]]; then
            DOC_CONFLICTS="$DOC_CONFLICTS $file"
        else
            OTHER_CONFLICTS="$OTHER_CONFLICTS $file"
        fi
    done

    if [ -n "$OTHER_CONFLICTS" ]; then
        echo "ERROR: Non-documentation conflicts detected:$OTHER_CONFLICTS"
        echo "Aborting merge. Please resolve conflicts manually."
        git merge --abort
        exit 1
    fi

    if [ -n "$DOC_CONFLICTS" ]; then
        echo "Resolving documentation conflicts by accepting upstream version..."
        for file in $DOC_CONFLICTS; do
            # For Chinese docs, keep our version (don't overwrite translations)
            git checkout --ours "$file" 2>/dev/null || true
        done
        git add $DOC_CONFLICTS
        git commit --no-edit --quiet
        echo "Documentation conflicts resolved (kept Chinese translations)."
    fi
fi

# Detect directory structure changes
echo ""
echo "Checking directory structure..."
if [ -d "$EN_DIR" ]; then
    EN_FILE_COUNT=$(find "$EN_DIR" -name "*.topic" -o -name "*.md" 2>/dev/null | wc -l)
    echo "English docs: $EN_FILE_COUNT files"
else
    echo "WARNING: $EN_DIR does not exist after merge!"
fi

ZH_DIR="documentation-website-zh/Writerside/topics"
if [ -d "$ZH_DIR" ]; then
    ZH_FILE_COUNT=$(find "$ZH_DIR" -name "*.topic" -o -name "*.md" 2>/dev/null | wc -l)
    echo "Chinese docs: $ZH_FILE_COUNT files"
fi

echo ""
echo "=== Upstream Sync Complete ==="
