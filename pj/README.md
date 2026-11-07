# pj (Project Jumper)

Frictionless fuzzy project navigator with MRU (Most Recently Used) tracking, terminal integration, and a Spotlight/Raycast-style floating launcher.

## Features

- **MRU Recency**: Selected and added projects automatically bump to the top. The most recently accessed project is always highlighted first.
- **Clean Display**: Strips redundant `$HOME/` prefixes; displays project names with dimmed relative paths.
- **Full Shell Support**: Native Fish and Bash wrappers delegate to a single source-of-truth Bash script.
- **Floating Spotlight Launcher**: Lightweight borderless popup window powered by Alacritty and `fzf` without running a heavy daemon.
- **Directory Preview**: Press `?` in fuzzy search to preview files inside the highlighted project directory.

## CLI Usage

```bash
# Fuzzy jump to a project
pj

# Save current directory to project list
pj this

# Interactively remove a project from the list
pj rm

# Remove current directory from the list
pj rm this

# Print raw saved project paths
pj list
```

## System Integration Architecture

### 1. Single Core Script
All business logic, sorting, formatting, and `fzf` configuration live in:
```
Documents/Bash/pj/pj.sh -> ~/.local/bin/pj-cli
```

### 2. Shell Wrappers (for in-process `cd`)
Because a child process cannot change its parent shell's working directory, thin shell wrappers handle the `cd`:

- **Fish** (`~/.config/fish/functions/pj.fish`):
  ```fish
  function pj --description 'Fuzzy jump to a project'
      switch "$argv[1]"
          case this rm list help -h --help
              pj-cli $argv
          case '*'
              set -l target (pj-cli $argv)
              and test -n "$target"
              and test -d "$target"
              and cd "$target"
      end
  end
  ```

- **Bash** (`~/.bashrc`):
  ```bash
  pj() {
    case "${1:-}" in
      this|rm|list|help|-h|--help)
        pj-cli "$@"
        ;;
      *)
        local target
        target=$(pj-cli "$@") && [[ -n "$target" && -d "$target" ]] && cd "$target"
        ;;
    esac
  }
  ```

### 3. Floating GUI Launcher (`pj-gui`)
- **Script**: `Documents/Bash/pj/pj-gui.sh` -> `~/.local/bin/pj-gui`
- **Config**: `Documents/Bash/pj/popup.toml` (borderless Alacritty floating profile)
- **Desktop Entry**: `~/.local/share/applications/pj.desktop`
- **Keybinding**: Bind `pj.desktop` to a global shortcut (e.g., `Meta+P`) in KDE System Settings.

In the popup picker, hold Alt with a key to start a tool in the selected project:

| Key | Action |
| --- | --- |
| `Enter` | Open a plain Alacritty window |
| `Alt+A` | Start `agy` in Alacritty |
| `Alt+O` | Start `opencode` in Alacritty |
| `Alt+D` | Open the folder in Dolphin |

Plain `a`, `o`, and `d` stay available for filtering the list.

### 4. Storage Location
Project paths are saved to standard XDG data directory:
```
~/.local/share/pj/projects
```
