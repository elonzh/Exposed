#!/bin/bash
# fetch-upstream.sh - Fetch and merge upstream changes from JetBrains/Exposed
# Always merges upstream into current branch; reports doc changes for translation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

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

# Always merge upstream changes (code, docs, snippets, images, etc.)
echo "Merging upstream/$UPSTREAM_BRANCH into $CURRENT_BRANCH..."
git merge "upstream/$UPSTREAM_BRANCH" --no-edit --quiet || {
    echo "Merge conflict detected. Aborting."
    git merge --abort
    exit 1
}

echo "=== Upstream Sync Complete ==="
