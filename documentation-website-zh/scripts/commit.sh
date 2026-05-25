#!/bin/bash
# commit.sh - Commit translated documentation changes

set -e

ZH_DIR="documentation-website-zh/Writerside/topics"

echo "Committing documentation changes..."

# Configure git if needed
if [ -z "$(git config user.name)" ]; then
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
fi

# Stage changes
git add "$ZH_DIR/"
git add documentation-website-zh/Writerside/snippets/ 2>/dev/null || true
git add documentation-website-zh/Writerside/images/ 2>/dev/null || true
git add documentation-website-zh/Writerside/resources/ 2>/dev/null || true

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "No changes to commit."
    exit 0
fi

# Create commit
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
git commit -m "docs(zh): sync documentation translation

Synced at: $TIMESTAMP
Triggered by: ${GITHUB_EVENT_NAME:-manual}"

echo "Changes committed successfully."
