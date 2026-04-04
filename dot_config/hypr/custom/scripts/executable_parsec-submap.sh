#!/usr/bin/env bash
# parsec-submap: watch Hyprland focus events and switch to a passthrough submap
# when Parsec is focused, restoring normal binds when it loses focus or closes.
#
# In Hyprland, an empty submap passes all keypresses through to the focused window.
# This lets Parsec receive Super key presses uninterrupted (needed for Mac clients
# where Parsec maps Ctrl→Cmd and Super acts as Ctrl).

PARSEC_CLASS="parsecd"
IN_PARSEC=0

# Single-instance lock — exit if another instance is already running
LOCKFILE="/tmp/parsec-submap.lock"
exec 9>"$LOCKFILE"
flock -n 9 || exit 0

reset_submap() {
    if [[ "$IN_PARSEC" -eq 1 ]]; then
        hyprctl dispatch submap reset
        IN_PARSEC=0
    fi
}

handle() {
    local event="$1"

    # activewindow>>class,title — fires on every focus change
    if [[ "$event" == activewindow\>\>* ]]; then
        local class="${event#activewindow>>}"
        class="${class%%,*}"

        if [[ "$class" == "$PARSEC_CLASS" ]]; then
            if [[ "$IN_PARSEC" -eq 0 ]]; then
                hyprctl dispatch submap parsec
                IN_PARSEC=1
            fi
        else
            reset_submap
        fi

    # activewindow>> with empty payload — focus moved to empty workspace
    elif [[ "$event" == "activewindow>>" ]]; then
        reset_submap

    # closewindow>>address — a window closed; if we're in parsec submap,
    # check whether parsecd is still running and reset if not
    elif [[ "$event" == closewindow\>\>* ]]; then
        if [[ "$IN_PARSEC" -eq 1 ]]; then
            still_running=$(hyprctl clients -j | jq -r --arg c "$PARSEC_CLASS" \
                '[.[] | select(.class == $c)] | length')
            if [[ "$still_running" -eq 0 ]]; then
                reset_submap
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
