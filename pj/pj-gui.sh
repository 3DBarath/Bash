#!/usr/bin/env bash
# pj-gui: Fast, minimal popup launcher for pj
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
CONFIG_FILE="$SCRIPT_DIR/popup.toml"
TMP_TARGET="/tmp/pj-target.$$"

# Clean up on exit
trap 'rm -f "$TMP_TARGET"' EXIT

# Launch popup picker with IPC disabled and scrollback turned off for instant startup
alacritty \
  --config-file "$CONFIG_FILE" \
  --class "pj-popup,pj-popup" \
  --title "Project Jumper" \
  -e bash -c "PJ_ACTIONS=1 pj-cli > '$TMP_TARGET'"

# If target selected, launch the chosen tool inside it
if [[ -s "$TMP_TARGET" ]]; then
  mapfile -t LINES < "$TMP_TARGET"
  KEY="${LINES[0]:-}"
  TARGET="${LINES[1]:-}"
  if [[ -n "$TARGET" && -d "$TARGET" ]]; then
    pj-cli touch "$TARGET"
    case "$KEY" in
      alt-a) alacritty --working-directory "$TARGET" -e agy & ;;
      alt-o) alacritty --working-directory "$TARGET" -e opencode & ;;
      alt-d) dolphin "$TARGET" & ;;
      *) alacritty --working-directory "$TARGET" & ;;
    esac
    disown
  fi
fi
