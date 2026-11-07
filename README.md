# Bash Utilities

Personal collection of minimal, focused shell tools and desktop workflow integrations.

## Projects

| Tool | Description | Location |
|---|---|---|
| [`fedora-transfer`](./fedora-transfer/) | High-speed file synchronization and interactive browser for remote Fedora build machine | `Documents/Bash/fedora-transfer` |
| [`pj`](./pj/) | Frictionless project navigator with MRU tracking, Bash/Fish wrappers, and Spotlight-style GUI launcher | `Documents/Bash/pj` |

---

## Global System Setup

All utilities link into `~/.local/bin/` so they are available in your `$PATH`:

```
~/.local/bin/fedora-transfer -> Documents/Bash/fedora-transfer/fedora-transfer.sh
~/.local/bin/pj-cli          -> Documents/Bash/pj/pj.sh
~/.local/bin/pj-gui          -> Documents/Bash/pj/pj-gui.sh
```

Desktop integration files (`.desktop`) are located in `~/.local/share/applications/` for system application menus and KRunner / shortcut bindings.
