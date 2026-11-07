# fedora-transfer

Fast, minimal file sync helper with a remote Fedora build machine over `rsync` and SSH connection caching.

## Features

- **Linear / Apple-inspired CLI**: High-contrast, clean typography, whitespace-spaced progress reporting, and colored final status feedback.
- **SSH Connection Multiplexing**: Reuses a single control socket under `/tmp/opencode/ssh-cm` with 30-minute persistence for fast repeated transfers without re-authenticating every time.
- **Interactive TUI**: Subdued, dark-themed `whiptail` menu for uploads, downloads, and directory inspection.
- **GUI Integration**: Quickly opens remote directories in Dolphin (via `sftp://`) or VS Code Remote SSH.

## CLI Usage

```bash
# Interactive menu
fedora-transfer

# Upload local file or directory
fedora-transfer up <local_path> [remote_dir]

# Download remote file or directory
fedora-transfer down <remote_path> [local_dir]

# List remote directory
fedora-transfer ls [remote_dir]

# Open remote in KDE Dolphin / VS Code
fedora-transfer gui

# Check connection health and uptime
fedora-transfer status
```

## System Integration

- **Binary Symlink**: `~/.local/bin/fedora-transfer` points to `Documents/Bash/fedora-transfer/fedora-transfer.sh`.
- **Desktop Entry**: `~/.local/share/applications/fedora-transfer.desktop` enables launching from the application menu or KRunner.
- **Environment Overrides**:
  - `REMOTE_USER` (default: `gces`)
  - `REMOTE_HOST` (default: `100.69.192.67`)
  - `REMOTE_DIR` (default: `/home/gces/Downloads`)
  - `LOCAL_DIR` (default: `$PWD`)
