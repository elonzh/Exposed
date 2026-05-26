#!/bin/bash
# commit.sh - Commit and push translated documentation changes
# Works both locally and in CI; pushes to current branch

set -e

ZH_DIR="documentation-website-zh/Writerside/topics"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Committing documentation changes..."
echo "Current branch: $CURRENT_BRANCH"

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

# Push if in CI environment
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "Pushing to origin/$CURRENT_BRANCH..."
    REMOTE_URL=$(git remote get-url origin)

    if [ -n "$GITHUB_TOKEN" ]; then
        AUTH_URL=$(echo "$REMOTE_URL" | sed "s|https://|https://x-access-token:$GITHUB_TOKEN@|")
        git push "$AUTH_URL" HEAD:"$CURRENT_BRANCH" --quiet
    else
        git push origin HEAD:"$CURRENT_BRANCH" --quiet
    fi

    echo "Changes pushed successfully."
else
    echo "Not in CI. Run 'git push' manually."
fi
