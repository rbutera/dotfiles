-- mpv issue 5222
-- Automatically set loop-file=inf for duration <= given length. Default is 5s
-- Use autoloop_duration=n in script-opts/autoloop.conf to set your preferred length
-- Alternatively use script-opts=autoloop-autoloop_duration=n in mpv.conf (takes priority)
-- Also disables the save-position-on-quit for this file, if it qualifies for looping.


require 'mp.options'

local autoloop_duration = 5
local autoloop_applied = false
local ignore_loop_file_change = false
local user_disabled_autoloop = false

function is_loop_enabled(value)
    return value and value ~= "no"
end

function set_loop_file(value)
    if is_loop_enabled(mp.get_property_native("loop-file")) == is_loop_enabled(value) then
        return
    end

    ignore_loop_file_change = true
    mp.set_property_native("loop-file", value)
end

function loop_file_changed(_, value)
    if ignore_loop_file_change then
        ignore_loop_file_change = false
        return
    end

    if is_loop_enabled(value) then
        user_disabled_autoloop = false
    elseif autoloop_applied then
        user_disabled_autoloop = true
        autoloop_applied = false
    end
end

function getOption()
    -- Use recommended way to get options
    local options = {autoloop_duration = 5}
    read_options(options)
    autoloop_duration = options.autoloop_duration


    -- Keep old way just for compatibility (remove lines 15-27 soon)
    if autoloop_duration ~= 5 then
        return
    end

    local opt = tonumber(mp.get_opt("autoloop-duration"))
    if not opt then
        return
    end
    print("Depracted configuration!  Please use script-opts directory to set auto_loop duration")
    print("Or use 'script-opts=autoloop-autoloop_duration' in mpv.conf")
    autoloop_duration = opt
    -- Remove lines 15-27 soon
end

function set_loop()
    local duration = mp.get_property_native("duration")

    -- Checks whether the loop status was changed for the last file
    local was_loop = mp.get_property_native("loop-file")

    -- Cancel operation if there is no file duration
    if not duration then
        return
    end

    -- Loops file if was_loop is false, and file meets requirements
    if not user_disabled_autoloop and not was_loop and duration <= autoloop_duration then
        set_loop_file(true)
        autoloop_applied = true
        mp.set_property_bool("file-local-options/save-position-on-quit", false)
        -- Unloops file if was_loop is true, and file does not meet requirements
    elseif was_loop and duration > autoloop_duration then
        set_loop_file(false)
        autoloop_applied = false
    end
end


getOption()
mp.observe_property("loop-file", "native", loop_file_changed)
mp.register_event("file-loaded", set_loop)
