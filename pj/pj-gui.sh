#!/usr/bin/env bash
# pj-gui: Fast, minimal popup launcher for pj
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

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
  -e bash -c "pj-cli > '$TMP_TARGET'"

# If target selected, launch terminal directly inside it
if [[ -s "$TMP_TARGET" ]]; then
  TARGET="$(<"$TMP_TARGET")"
  if [[ -n "$TARGET" && -d "$TARGET" ]]; then
    pj-cli touch "$TARGET"
    alacritty --working-directory "$TARGET" &
    disown
  fi
fi
