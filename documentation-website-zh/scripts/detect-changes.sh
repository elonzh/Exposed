#!/bin/bash
# detect-changes.sh - Detect upstream documentation changes
# Outputs list of files that need translation

set -e

EN_DIR="documentation-website/Writerside/topics"
ZH_DIR="documentation-website-zh/Writerside/topics"
TAG_PREFIX="docs-zh-sync"

# Check if force translate is requested
if [ "$1" = "--all" ]; then
    echo "ALL"
    ls "$EN_DIR"/*.topic "$EN_DIR"/*.md 2>/dev/null | xargs -n1 basename
    exit 0
fi

# Find the latest sync tag
LAST_TAG=$(git tag -l "${TAG_PREFIX}-*" --sort=-creatordate | head -n1)

if [ -z "$LAST_TAG" ]; then
    echo "FIRST_SYNC"
    ls "$EN_DIR"/*.topic "$EN_DIR"/*.md 2>/dev/null | xargs -n1 basename
    exit 0
fi

LAST_TAG_COMMIT=$(git rev-list -n1 "$LAST_TAG")
echo "Last sync tag: $LAST_TAG (commit: ${LAST_TAG_COMMIT:0:8})" >&2

# Detect changed, new, and deleted files
CHANGED_FILES=""
NEW_FILES=""
DELETED_FILES=""

# Get diff status (Added/Modified/Deleted)
while IFS=$'\t' read -r status file; do
    # Only process files in EN_DIR
    [[ "$file" != "$EN_DIR/"* ]] && continue

    filename=$(basename "$file")

    case "$status" in
        A)
            NEW_FILES="$NEW_FILES $filename"
            ;;
        M)
            # Check if English file is newer than Chinese translation
            zh_file="$ZH_DIR/$filename"
            if [ -f "$zh_file" ]; then
                en_time=$(stat -c %Y "$EN_DIR/$filename" 2>/dev/null || stat -f %m "$EN_DIR/$filename" 2>/dev/null)
                zh_time=$(stat -c %Y "$zh_file" 2>/dev/null || stat -f %m "$zh_file" 2>/dev/null)
                if [ "$zh_time" -ge "$en_time" ] 2>/dev/null; then
                    echo "SKIP (up-to-date): $filename" >&2
                    continue
                fi
            fi
            CHANGED_FILES="$CHANGED_FILES $filename"
            ;;
        D)
            DELETED_FILES="$DELETED_FILES $filename"
            ;;
        R*)
            # Renamed: old file deleted, new file added
            old_file=$(echo "$file" | cut -f1)
            new_file=$(echo "$file" | cut -f2)
            DELETED_FILES="$DELETED_FILES $(basename "$old_file")"
            NEW_FILES="$NEW_FILES $(basename "$new_file")"
            ;;
    esac
done < <(git diff --name-status "$LAST_TAG_COMMIT" HEAD -- "$EN_DIR/" 2>/dev/null)

# Also check for files in EN_DIR that don't exist in ZH_DIR
for en_file in "$EN_DIR"/*.topic "$EN_DIR"/*.md; do
    [ -f "$en_file" ] || continue
    filename=$(basename "$en_file")
    zh_file="$ZH_DIR/$filename"
    if [ ! -f "$zh_file" ]; then
        # Avoid duplicates
        if [[ ! " $NEW_FILES " =~ " $filename " ]]; then
            NEW_FILES="$NEW_FILES $filename"
        fi
    fi
done

# Check for orphaned files in ZH_DIR (deleted in EN_DIR)
for zh_file in "$ZH_DIR"/*.topic "$ZH_DIR"/*.md; do
    [ -f "$zh_file" ] || continue
    filename=$(basename "$zh_file")
    en_file="$EN_DIR/$filename"
    if [ ! -f "$en_file" ]; then
        # Avoid duplicates
        if [[ ! " $DELETED_FILES " =~ " $filename " ]]; then
            DELETED_FILES="$DELETED_FILES $filename"
        fi
    fi
done

# Build result
HAS_CHANGES=false

if [ -n "$CHANGED_FILES" ] || [ -n "$NEW_FILES" ] || [ -n "$DELETED_FILES" ]; then
    HAS_CHANGES=true
fi

if [ "$HAS_CHANGES" = false ]; then
    echo "NO_CHANGES"
    exit 0
fi

echo "CHANGED"

if [ -n "$CHANGED_FILES" ]; then
    echo "MODIFIED:$CHANGED_FILES" | tr ' ' '\n' | grep -v '^MODIFIED:$'
fi

if [ -n "$NEW_FILES" ]; then
    echo "NEW:$NEW_FILES" | tr ' ' '\n' | grep -v '^NEW:$'
fi

if [ -n "$DELETED_FILES" ]; then
    echo "DELETED:$DELETED_FILES" | tr ' ' '\n' | grep -v '^DELETED:$'
fi
