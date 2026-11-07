#!/usr/bin/env bash
# pj-gui: Spotlight / Raycast-style floating window launcher for pj
set -euo pipefail

# Ensure ~/.local/bin is in PATH for desktop/KWin shortcut launches
export PATH="$HOME/.local/bin:$PATH"

# Resolve canonical script directory
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/popup.toml"

# Temporary file to capture selection across subshell boundary
TMP_TARGET="$(mktemp /tmp/pj-target.XXXXXX)"

cleanup() {
  rm -f "$TMP_TARGET"
}
trap cleanup EXIT

# Run picker inside popup terminal
alacritty \
  --config-file "$CONFIG_FILE" \
  --class "pj-popup,pj-popup" \
  --title "Project Jumper" \
  -e bash -c "pj-cli > '$TMP_TARGET'"

# If target was selected, spawn terminal inside it
if [[ -s "$TMP_TARGET" ]]; then
  TARGET="$(cat "$TMP_TARGET")"
  if [[ -n "$TARGET" && -d "$TARGET" ]]; then
    pj-cli touch "$TARGET"
    # Launch new terminal in background independent of the popup
    alacritty --working-directory "$TARGET" &
    disown
  fi
fi
