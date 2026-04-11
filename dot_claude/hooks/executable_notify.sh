#!/bin/bash
# Claude Code hook notification script
# Sends OSC 9 desktop notifications, with tmux DCS passthrough support.

set -euo pipefail

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name')
CWD=$(echo "$INPUT" | jq -r '.cwd')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

# Lock file to prevent Stop from overwriting a question notification
LOCK_DIR="${TMPDIR:-/tmp}"
LOCK_FILE="${LOCK_DIR}/claude-notify-${SESSION_ID}"

# For Stop events, skip if a question notification just fired
if [ "$EVENT" = "Stop" ]; then
  STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
  if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
  fi
  # If a question was just asked, the lock file exists — skip the idle notification
  if [ -f "$LOCK_FILE" ]; then
    rm -f "$LOCK_FILE"
    exit 0
  fi
fi

# Build context: directory name, git branch
DIR_NAME=$(basename "$CWD")
BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || echo "no-branch")
SHORT_SESSION=$(echo "$SESSION_ID" | cut -c1-8)

PREFIX="${DIR_NAME}@${BRANCH} [${SHORT_SESSION}]"

# Build message based on event type
case "$EVENT" in
  PreToolUse)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name')
    if [ "$TOOL" = "AskUserQuestion" ]; then
      QUESTION=$(echo "$INPUT" | jq -r '.tool_input.questions[0].question // "question"' | head -c 120)
      MSG="${PREFIX}: ${QUESTION}"
      # Set lock so the subsequent Stop hook doesn't overwrite this notification
      touch "$LOCK_FILE"
    else
      MSG="${PREFIX}: waiting for input (${TOOL})"
    fi
    ;;
  Notification)
    TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
    case "$TYPE" in
      permission_prompt)  MSG="${PREFIX}: permission needed" ;;
      idle_prompt)        MSG="${PREFIX}: idle" ;;
      elicitation_dialog) MSG="${PREFIX}: waiting for input" ;;
      *)                  MSG="${PREFIX}: notification (${TYPE})" ;;
    esac
    # Set lock so the subsequent Stop hook doesn't overwrite
    touch "$LOCK_FILE"
    ;;
  Stop)
    MSG="${PREFIX}: idle"
    ;;
  *)
    MSG="${PREFIX}: ${EVENT}"
    ;;
esac

# Send OSC 9 notification, with tmux DCS passthrough if needed
send_osc9() {
  local msg="$1"
  if [ -n "${TMUX:-}" ]; then
    # DCS passthrough: \ePtmux;\e<sequence>\e\\
    printf '\ePtmux;\e\e]9;%s\a\e\\' "$msg" > /dev/tty
  else
    printf '\e]9;%s\a' "$msg" > /dev/tty
  fi
}

send_osc9 "$MSG"

exit 0
