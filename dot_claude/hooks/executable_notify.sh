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

# UserPromptSubmit: user is active again — clear stale "needs input" state
if [ "$EVENT" = "UserPromptSubmit" ]; then
  rm -f "$LOCK_FILE"
  exit 0
fi

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

# Return a single-line, control-character-free preview capped to N chars.
# This keeps arbitrary command/path text as data only; we never eval it.
sanitize_preview() {
  local max_len="$1"
  head -n 1 | LC_ALL=C tr -d '\000-\010\013\014\016-\037\177' | cut -c 1-"$max_len"
}

# Build message based on event type
case "$EVENT" in
  PreToolUse)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name')
    if [ "$TOOL" = "AskUserQuestion" ]; then
      QUESTION=$(echo "$INPUT" | jq -r '.tool_input.questions[0].question // "question"' | sanitize_preview 120)
      MSG="${PREFIX}: ${QUESTION}"
      # Set lock so the subsequent Stop hook doesn't overwrite this notification
      touch "$LOCK_FILE"
    elif [ "$TOOL" = "Bash" ]; then
      COMMAND_PREVIEW=$(echo "$INPUT" | jq -r '.tool_input.command // ""' | sanitize_preview 80)
      if [ -n "$COMMAND_PREVIEW" ]; then
        MSG="${PREFIX}: Bash: ${COMMAND_PREVIEW}"
      else
        MSG="${PREFIX}: Bash"
      fi
    else
      PATH_PREVIEW=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""' | sanitize_preview 120)
      if [ -n "$PATH_PREVIEW" ]; then
        MSG="${PREFIX}: ${TOOL}: ${PATH_PREVIEW}"
      else
        MSG="${PREFIX}: waiting for input (${TOOL})"
      fi
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

# Send OSC 9 notification through Claude Code's supported hook output.
send_osc9() {
  local msg="$1"
  local seq
  if [ -n "${TMUX:-}" ]; then
    # DCS passthrough: \ePtmux;\e<sequence>\e\\
    seq=$(printf '\033Ptmux;\033\033]9;%s\007\033\\' "$msg")
  else
    seq=$(printf '\033]9;%s\007' "$msg")
  fi
  jq -nc --arg seq "$seq" '{terminalSequence: $seq}'
}

send_osc9 "$MSG"

exit 0
