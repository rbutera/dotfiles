# Quickshell (end-4/dots-hyprland) — Integration Notes

This setup uses end-4's Illogical Impulse shell (`qs -c ii`). Keybinds call into
quickshell via Hyprland's `global` dispatcher using IPC action names.

---

## IPC action names

Use these in `keybinds.conf` as:
```
bind = MODIFIERS, KEY, global, quickshell:ACTION_NAME
```

| Action name | What it does |
|---|---|
| `overviewWorkspacesToggle` | Workspace overview (Super+Tab) |
| `overviewClipboardToggle` | Clipboard history panel |
| `overviewEmojiToggle` | Emoji picker |
| `sidebarLeftToggle` | Left sidebar (Super+A) |
| `sidebarRightToggle` | Right sidebar (Super+G) |
| `overlayToggle` | Full system overlay (Hyper+grave) |
| `sessionToggle` | Session menu (lock/logout/shutdown) |
| `cheatsheetToggle` | Keybind cheatsheet |
| `barToggle` | Toggle status bar visibility |
| `mediaControlsToggle` | Media controls panel |
| `oskToggle` | On-screen keyboard |
| `searchToggleReleaseInterrupt` | Search/launcher interrupt |

These are defined in the upstream shell config. If an action stops working after an
upstream update, check `~/.config/quickshell/ii/` for renamed IPC handlers.

---

## Dock behavior

The dock (`~/.config/quickshell/ii/modules/ii/dock/Dock.qml`) uses this reveal condition:

```qml
property bool reveal: root.pinned
    || (Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse)
    || dockApps.requestDockShow
    || (!ToplevelManager.activeToplevel?.activated)
```

The last condition — `!ToplevelManager.activeToplevel?.activated` — means the dock
reveals on **all monitors** whenever there is no active (focused) window anywhere.
This fires when you focus an empty monitor (no windows on that workspace).

This is intentional upstream behavior. The dock auto-hides as soon as any window is
focused. There is no config option to disable the "no active window" reveal trigger
without patching Dock.qml directly.

---

## Shell config location

```
~/.config/quickshell/ii/   ← deployed by end-4 installer, not managed by chezmoi
```

Do not edit these files directly unless you intend to maintain a fork. Upstream updates
via `chezmoi update` (which pulls the dots-hyprland fork) will overwrite local changes.
Custom overrides should live in `~/.config/hypr/custom/` where possible.
