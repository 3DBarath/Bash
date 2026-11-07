#!/usr/bin/env bash
# fedora-transfer: fast, minimal file sync with remote Fedora box.
#
# Usage:
#   fedora-transfer                  Interactive menu
#   fedora-transfer up   <src> [dst] Upload local file or directory
#   fedora-transfer down <src> [dst] Download remote file or directory
#   fedora-transfer ls   [dir]       List remote directory
#   fedora-transfer gui              Open remote in file manager
#   fedora-transfer status           Check remote connectivity
set -euo pipefail

# Configuration
REMOTE_USER="${REMOTE_USER:-gces}"
REMOTE_HOST="${REMOTE_HOST:-100.69.192.67}"
REMOTE_PASS="${REMOTE_PASS:-ALTRONIX266}"
REMOTE_DIR="${REMOTE_DIR:-/home/gces/Downloads}"
LOCAL_DIR="${LOCAL_DIR:-$PWD}"

CM_DIR="/tmp/opencode/ssh-cm"
mkdir -p "$CM_DIR"

SSH_OPTS="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ControlMaster=auto -o ControlPath=$CM_DIR/%r@%h:%p -o ControlPersist=30m"
ssh_cmd=($SSH_OPTS)

# Palette (Linear dark theme: deep slate, indigo/violet accent, sage green, coral red, muted gray)
if [[ -t 1 ]]; then
  BOLD="\033[1m"
  DIM="\033[38;5;241m"
  RESET="\033[0m"

  # Core colors
  C_ACCENT="\033[38;5;105m"  # Soft linear violet/indigo
  C_PRIMARY="\033[38;5;255m" # Bright clean text
  C_CYAN="\033[38;5;74m"     # Remote indicator
  C_SUCCESS="\033[38;5;150m" # Sage green
  C_WARN="\033[38;5;216m"    # Soft peach/amber
  C_ERROR="\033[38;5;203m"   # Coral red
  C_PATH="\033[38;5;110m"    # Steel blue for paths
else
  BOLD=""
  DIM=""
  RESET=""
  C_ACCENT=""
  C_PRIMARY=""
  C_CYAN=""
  C_SUCCESS=""
  C_WARN=""
  C_ERROR=""
  C_PATH=""
fi

# Linear dark theme for whiptail / newt
export NEWT_COLORS='
root=,black
window=white,black
border=blue,black
shadow=black,black
title=magenta,black
button=black,cyan
actbutton=black,white
compactbutton=lightgray,black
entry=white,blue
curentry=black,cyan
listbox=lightgray,black
actlistbox=black,cyan
textbox=white,black
acttextbox=black,cyan
helpline=white,blue
roottext=lightgray,black
'

msg()    { printf "  ${C_PRIMARY}%s${RESET}\n" "$*"; }
dim()    { printf "  ${DIM}%s${RESET}\n" "$*"; }
status() { printf "\n  ${C_ACCENT}●${RESET}  ${BOLD}%s${RESET}\n\n" "$*"; }
ok()     { printf "  ${C_SUCCESS}✓${RESET}  ${C_PRIMARY}%s${RESET}\n\n" "$*"; }
fail()   { printf "\n  ${C_ERROR}✕${RESET}  ${C_ERROR}%s${RESET}\n\n" "$*" >&2; }

run_ssh() {
  SSHPASS="$REMOTE_PASS" sshpass -e "${ssh_cmd[@]}" "$REMOTE_USER@$REMOTE_HOST" "$@"
}

run_sync() {
  local src="$1" dst="$2"
  SSHPASS="$REMOTE_PASS" sshpass -e rsync -avh --partial --progress -e "$SSH_OPTS" "$src" "$dst"
}

cmd_status() {
  status "Checking connectivity"
  dim "Host: $REMOTE_USER@$REMOTE_HOST"
  if out=$(run_ssh "uptime" 2>/dev/null); then
    printf "\n  ${DIM}%s${RESET}\n\n" "$out"
    ok "Connected"
  else
    fail "Host unreachable ($REMOTE_HOST)"
    return 1
  fi
}

cmd_up() {
  local src="${1:-}" dst="${2:-$REMOTE_DIR}"
  if [[ -z "$src" ]]; then
    fail "Local path required: fedora-transfer up <path> [remote_dir]"
    exit 1
  fi
  if [[ ! -e "$src" ]]; then
    fail "Path not found: $src"
    exit 1
  fi

  status "Uploading"
  printf "  ${C_PATH}%s${RESET}\n  ${DIM}↓${RESET}\n  ${C_CYAN}%s@%s${RESET}:${C_PATH}%s${RESET}\n\n" "$src" "$REMOTE_USER" "$REMOTE_HOST" "$dst"

  if run_sync "$src" "$REMOTE_USER@$REMOTE_HOST:$dst"; then
    printf "\n"
    printf "  ${C_SUCCESS}✓${RESET}  Uploaded ${BOLD}${C_SUCCESS}%s${RESET}\n\n" "$(basename "$src")"
  else
    fail "Upload failed"
    exit 1
  fi
}

cmd_down() {
  local src="${1:-}" dst="${2:-$LOCAL_DIR}"
  if [[ -z "$src" ]]; then
    fail "Remote path required: fedora-transfer down <remote_path> [local_dir]"
    exit 1
  fi

  status "Downloading"
  printf "  ${C_CYAN}%s@%s${RESET}:${C_PATH}%s${RESET}\n  ${DIM}↓${RESET}\n  ${C_PATH}%s${RESET}\n\n" "$REMOTE_USER" "$REMOTE_HOST" "$src" "$dst"

  if run_sync "$REMOTE_USER@$REMOTE_HOST:$src" "$dst"; then
    printf "\n"
    printf "  ${C_SUCCESS}✓${RESET}  Downloaded ${BOLD}${C_SUCCESS}%s${RESET}\n\n" "$(basename "$src")"
  else
    fail "Download failed"
    exit 1
  fi
}

cmd_ls() {
  local dir="${1:-$REMOTE_DIR}"
  status "Listing directory"
  printf "  ${C_CYAN}%s@%s${RESET}:${C_PATH}%s${RESET}\n\n" "$REMOTE_USER" "$REMOTE_HOST" "$dir"

  run_ssh "ls -lh --color=always '$dir'" || {
    fail "Failed to list $dir"
    exit 1
  }
  printf "\n"
}

cmd_gui() {
  status "File Manager"
  if command -v dolphin >/dev/null 2>&1; then
    dolphin "sftp://$REMOTE_USER@$REMOTE_HOST$REMOTE_DIR" >/dev/null 2>&1 &
    ok "Opened remote folder in Dolphin"
  elif command -v code >/dev/null 2>&1; then
    code --remote "ssh-remote+$REMOTE_USER@$REMOTE_HOST" "$REMOTE_DIR" >/dev/null 2>&1 &
    ok "Opened remote folder in VS Code"
  else
    fail "No GUI file manager found (dolphin or code)"
    exit 1
  fi
}

usage() {
  printf "\n"
  printf "  ${BOLD}${C_ACCENT}fedora-transfer${RESET}  ${DIM}·  %s@%s${RESET}\n\n" "$REMOTE_USER" "$REMOTE_HOST"

  printf "  ${BOLD}Commands${RESET}\n\n"
  printf "    ${C_ACCENT}%-8s${RESET} %-14s ${DIM}%-24s${RESET} ${DIM}%s${RESET}\n" "up" "<src> [dst]" "Upload to remote" "$REMOTE_DIR"
  printf "    ${C_ACCENT}%-8s${RESET} %-14s ${DIM}%-24s${RESET} ${DIM}%s${RESET}\n" "down" "<src> [dst]" "Download to local" "$LOCAL_DIR"
  printf "    ${C_ACCENT}%-8s${RESET} %-14s ${DIM}%-24s${RESET}\n" "ls" "[dir]" "List remote directory"
  printf "    ${C_ACCENT}%-8s${RESET} %-14s ${DIM}%-24s${RESET}\n" "gui" "" "Open in Dolphin / VS Code"
  printf "    ${C_ACCENT}%-8s${RESET} %-14s ${DIM}%-24s${RESET}\n" "status" "" "Check host connection"
  printf "    ${C_ACCENT}%-8s${RESET} %-14s ${DIM}%-24s${RESET}\n" "menu" "" "Interactive menu (default)"
  printf "\n"
}

interactive() {
  while true; do
    choice=$(whiptail --title " Fedora Transfer " --menu "" 16 56 6 \
      "1" "Upload to remote" \
      "2" "Download from remote" \
      "3" "List remote directory" \
      "4" "Open in file manager" \
      "5" "Connection status" \
      "6" "Quit" 3>&1 1>&2 2>&3) || exit 0

    case "$choice" in
      1)
        src=$(whiptail --title "Upload" --inputbox "Local file or directory" 10 58 "$LOCAL_DIR/" 3>&1 1>&2 2>&3) || continue
        dst=$(whiptail --title "Upload" --inputbox "Remote destination" 10 58 "$REMOTE_DIR" 3>&1 1>&2 2>&3) || continue
        clear
        cmd_up "$src" "$dst" || true
        printf "  "
        read -r -p "Press Enter to return..."
        ;;
      2)
        src=$(whiptail --title "Download" --inputbox "Remote file or directory" 10 58 "$REMOTE_DIR/" 3>&1 1>&2 2>&3) || continue
        dst=$(whiptail --title "Download" --inputbox "Local destination" 10 58 "$LOCAL_DIR" 3>&1 1>&2 2>&3) || continue
        clear
        cmd_down "$src" "$dst" || true
        printf "  "
        read -r -p "Press Enter to return..."
        ;;
      3)
        dir=$(whiptail --title "List Remote" --inputbox "Remote directory" 10 58 "$REMOTE_DIR" 3>&1 1>&2 2>&3) || continue
        out=$(run_ssh "ls -lh '$dir'" 2>&1) || out="Failed to read $dir"
        whiptail --title " $dir " --scrolltext --textbox <(printf '%s\n' "$out") 22 76
        ;;
      4)
        clear
        cmd_gui
        sleep 1
        ;;
      5)
        clear
        cmd_status || true
        printf "  "
        read -r -p "Press Enter to return..."
        ;;
      6)
        clear
        exit 0
        ;;
    esac
  done
}

case "${1:-}" in
  up) shift; cmd_up "$@" ;;
  down) shift; cmd_down "$@" ;;
  ls) shift; cmd_ls "$@" ;;
  gui) cmd_gui ;;
  status|ping) cmd_status ;;
  menu) interactive ;;
  -h|--help|help) usage ;;
  "") interactive ;;
  *)
    fail "Unknown command: $1"
    usage
    exit 1
    ;;
esac
