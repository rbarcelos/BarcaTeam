# tmux Cheatsheet

All tmux commands use a **prefix key** first: `Ctrl+B`, then the command key.

## Sessions

| Action | Command |
|---|---|
| New session | `tmux new -s <name>` |
| List sessions | `tmux ls` |
| Attach to session | `tmux attach -t <name>` |
| Detach (keeps running) | `Ctrl+B` → `d` |
| Kill session | `tmux kill-session -t <name>` |
| Rename session | `Ctrl+B` → `$` |
| Switch session | `Ctrl+B` → `s` |

## Windows (tabs)

| Action | Command |
|---|---|
| New window | `Ctrl+B` → `c` |
| Next window | `Ctrl+B` → `n` |
| Previous window | `Ctrl+B` → `p` |
| Go to window # | `Ctrl+B` → `0-9` |
| Rename window | `Ctrl+B` → `,` |
| Close window | `Ctrl+B` → `&` |
| List windows | `Ctrl+B` → `w` |

## Panes (splits)

| Action | Command |
|---|---|
| Split horizontal | `Ctrl+B` → `"` |
| Split vertical | `Ctrl+B` → `%` |
| Navigate panes | `Ctrl+B` → arrow keys |
| Cycle panes | `Ctrl+B` → `o` |
| Close pane | `Ctrl+B` → `x` |
| Toggle fullscreen pane | `Ctrl+B` → `z` |
| Resize pane | `Ctrl+B` → hold arrow key |
| Swap pane positions | `Ctrl+B` → `{` or `}` |
| Show pane numbers | `Ctrl+B` → `q` |

## Copy Mode (scroll/search)

| Action | Command |
|---|---|
| Enter copy mode | `Ctrl+B` → `[` |
| Scroll up/down | Arrow keys or `PgUp`/`PgDn` |
| Search forward | `/` then type |
| Search backward | `?` then type |
| Exit copy mode | `q` or `Esc` |

## Claude Agent Teams in tmux

| Action | Command |
|---|---|
| Start tmux for agents | `tmux new -s agents` |
| Launch Claude in tmux mode | `claude --teammate-mode tmux` |
| Cycle teammates | `Shift+Down` / `Shift+Up` |
| Toggle task list | `Ctrl+T` |
| Delegate mode (lead orchestrates only) | `Shift+Tab` |
| Interact with teammate | Click pane or `Enter` |
| Interrupt teammate | `Escape` |
| Detach (team keeps working) | `Ctrl+B` → `d` |
| Reattach to check progress | `tmux attach -t agents` |

## Useful combos

```bash
# Start fresh session
tmux new -s agents

# Detach and reattach (team keeps running)
Ctrl+B d           # detach
tmux attach -t agents  # reattach later

# Kill everything when done
tmux kill-server
```
