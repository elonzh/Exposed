#!/bin/bash
# notify-feishu.sh - Send workflow result notification to Feishu webhook
# Usage: notify-feishu.sh <webhook_url> <workflow_name> <workflow_url> <branch> <sync_result> <build_result>

set -e

WEBHOOK_URL="$1"
WORKFLOW_NAME="$2"
WORKFLOW_URL="$3"
BRANCH="$4"
SYNC_RESULT="$5"
BUILD_RESULT="$6"

if [[ -z "$WEBHOOK_URL" ]]; then
    echo "Error: Feishu webhook URL is required"
    exit 1
fi

if [[ "$SYNC_RESULT" == "success" && "$BUILD_RESULT" == "success" ]]; then
    COLOR="green"
    TITLE="✅ Chinese Docs Sync Succeeded"
else
    COLOR="red"
    TITLE="❌ Chinese Docs Sync Failed"
fi

CONTENT="**Workflow**: [$WORKFLOW_NAME]($WORKFLOW_URL)\n**Branch**: $BRANCH\n**Sync**: $SYNC_RESULT\n**Build**: $BUILD_RESULT"

PAYLOAD=$(jq -n \
    --arg title "$TITLE" \
    --arg color "$COLOR" \
    --arg content "$CONTENT" \
    '{
        msg_type: "interactive",
        card: {
            header: {
                title: { tag: "plain_text", content: $title },
                template: $color
            },
            elements: [
                {
                    tag: "div",
                    text: {
                        tag: "lark_md",
                        content: $content
                    }
                }
            ]
        }
    }')

curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD"

echo "Feishu notification sent."
