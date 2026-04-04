#!/usr/bin/env bash
# parsec-submap: watch Hyprland focus events and switch to a passthrough submap
# when Parsec is focused, restoring normal binds when it loses focus.
#
# In Hyprland, an empty submap passes all keypresses through to the focused window.
# This lets Parsec receive Super key presses uninterrupted (needed for Mac clients
# where Parsec maps Ctrl→Cmd and Super acts as Ctrl).

PARSEC_CLASS="parsecd"
IN_PARSEC=0

handle() {
    local event="$1"

    # activewindow>>class,title fires on every focus change
    if [[ "$event" == activewindow\>\>* ]]; then
        local class="${event#activewindow>>}"
        class="${class%%,*}"

        if [[ "$class" == "$PARSEC_CLASS" ]]; then
            if [[ "$IN_PARSEC" -eq 0 ]]; then
                hyprctl dispatch submap parsec
                IN_PARSEC=1
            fi
        else
            if [[ "$IN_PARSEC" -eq 1 ]]; then
                hyprctl dispatch submap reset
                IN_PARSEC=0
            fi
        fi
    fi
}

# Connect to Hyprland's event socket and process events
# Socket location varies by distro: check XDG_RUNTIME_DIR first, fall back to /tmp/hypr
socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
[[ ! -S "$socket" ]] && socket="/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
socat - "UNIX-CONNECT:${socket}" | while read -r line; do
    handle "$line"
done
