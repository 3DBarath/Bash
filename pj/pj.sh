#!/usr/bin/env bash
# pj: Fast, minimal project jumper CLI with MRU tracking and GUI launch support.
set -euo pipefail

PJ_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/pj"
PJ_FILE="$PJ_DATA_DIR/projects"

mkdir -p "$PJ_DATA_DIR"
touch "$PJ_FILE"

# Colors
if [[ -t 2 ]]; then
  BOLD="\033[1m"
  DIM="\033[38;5;241m"
  ACCENT="\033[38;5;105m"
  SUCCESS="\033[38;5;150m"
  ERROR="\033[38;5;203m"
  RESET="\033[0m"
else
  BOLD=""
  DIM=""
  ACCENT=""
  SUCCESS=""
  ERROR=""
  RESET=""
fi

# Touch / bump project to top of list (MRU)
touch_mru() {
  local target="$1"
  if grep -Fxq "$target" "$PJ_FILE" 2>/dev/null; then
    # Move to top: put target first, then remaining lines
    (echo "$target"; grep -Fvx "$target" "$PJ_FILE") > "$PJ_FILE.tmp" && mv "$PJ_FILE.tmp" "$PJ_FILE"
  fi
}

case "${1:-}" in
  this)
    cur="${2:-$PWD}"
    if ! grep -Fxq "$cur" "$PJ_FILE" 2>/dev/null; then
      # New project goes to the top
      (echo "$cur"; cat "$PJ_FILE") > "$PJ_FILE.tmp" && mv "$PJ_FILE.tmp" "$PJ_FILE"
      printf "${SUCCESS}✓${RESET}  Added: %s\n" "$cur" >&2
    else
      touch_mru "$cur"
      printf "${DIM}Updated recency:${RESET} %s\n" "$cur" >&2
    fi
    ;;

  touch)
    if [[ -n "${2:-}" ]]; then
      touch_mru "$2"
    fi
    ;;

  rm)
    if [[ "${2:-}" == "this" ]]; then
      cur="${3:-$PWD}"
      if grep -Fxq "$cur" "$PJ_FILE" 2>/dev/null; then
        grep -Fvx "$cur" "$PJ_FILE" > "$PJ_FILE.tmp" && mv "$PJ_FILE.tmp" "$PJ_FILE"
        printf "${ERROR}✓${RESET}  Removed: %s\n" "$cur" >&2
      else
        printf "${DIM}Not in project list:${RESET} %s\n" "$cur" >&2
      fi
      exit 0
    fi

    if [[ ! -s "$PJ_FILE" ]]; then
      printf "${DIM}No projects to remove.${RESET}\n" >&2
      exit 0
    fi

    selection=$(awk -v home="$HOME" '{
      orig = $0
      rel = $0
      sub("^" home "/", "", rel)
      n = split(rel, p, "/")
      name = p[n]
      printf "%-26s \033[38;5;242m%s\033[0m\t%s\n", name, rel, orig
    }' "$PJ_FILE" | fzf \
      --ansi \
      --delimiter='\t' \
      --with-nth=1 \
      --prompt="✕ Remove > " \
      --pointer="▶" \
      --no-info \
      --height=45% \
      --layout=reverse \
      --border=rounded) || exit 0

    target=$(printf "%s" "$selection" | cut -f2)
    if [[ -n "$target" ]]; then
      grep -Fvx "$target" "$PJ_FILE" > "$PJ_FILE.tmp" && mv "$PJ_FILE.tmp" "$PJ_FILE"
      printf "${ERROR}✓${RESET}  Removed: %s\n" "$target" >&2
    fi
    ;;

  list)
    if [[ -s "$PJ_FILE" ]]; then
      cat "$PJ_FILE"
    else
      printf "${DIM}No projects saved yet. Use 'pj this' inside a project.${RESET}\n" >&2
    fi
    ;;

  gui)
    # Floating popup launcher (can be called by KDE global shortcut)
    exec "${PJ_GUI:-pj-gui}"
    ;;

  -h|--help|help)
    printf "\n  ${BOLD}${ACCENT}pj${RESET}  ${DIM}· fuzzy project jumper (MRU)${RESET}\n\n" >&2
    printf "  ${BOLD}Commands${RESET}\n\n" >&2
    printf "    ${ACCENT}%-12s${RESET} %s\n" "pj" "Fuzzy select and cd into project (MRU order)" >&2
    printf "    ${ACCENT}%-12s${RESET} %s\n" "pj this" "Save current directory" >&2
    printf "    ${ACCENT}%-12s${RESET} %s\n" "pj rm" "Select a project to remove" >&2
    printf "    ${ACCENT}%-12s${RESET} %s\n" "pj rm this" "Remove current directory" >&2
    printf "    ${ACCENT}%-12s${RESET} %s\n" "pj list" "Print saved projects" >&2
    printf "    ${ACCENT}%-12s${RESET} %s\n\n" "pj gui" "Floating window launcher" >&2
    ;;

  *)
    if [[ ! -s "$PJ_FILE" ]]; then
      printf "${DIM}No projects saved yet. Run 'pj this' inside a project first.${RESET}\n" >&2
      exit 0
    fi

    # Read MRU list directly (preserving file order)
    selection=$(awk -v home="$HOME" '{
      orig = $0
      rel = $0
      sub("^" home "/", "", rel)
      n = split(rel, p, "/")
      name = p[n]
      printf "%-26s \033[38;5;242m%s\033[0m\t%s\n", name, rel, orig
    }' "$PJ_FILE" | fzf \
      --ansi \
      --delimiter='\t' \
      --with-nth=1 \
      --prompt="⚡ Jump > " \
      --pointer="▶" \
      --no-info \
      --height=100% \
      --layout=reverse \
      --border=rounded \
      --color='border:#5e6378,prompt:#a594fd,pointer:#bb9af7' \
      --preview='ls -la --color=always {2} 2>/dev/null' \
      --preview-window=right:45%:hidden \
      --bind='?:toggle-preview') || exit 0

    target=$(printf "%s" "$selection" | cut -f2)
    if [[ -n "$target" && -d "$target" ]]; then
      touch_mru "$target"
      printf "%s\n" "$target"
    elif [[ -n "$target" ]]; then
      printf "${ERROR}✕ Directory not found:${RESET} %s\n" "$target" >&2
    fi
    ;;
esac
