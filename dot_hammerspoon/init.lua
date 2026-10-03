local function mediaKey(key)
    hs.eventtap.event.newSystemKeyEvent(key, true):post()
    hs.eventtap.event.newSystemKeyEvent(key, false):post()
end

-- Mute with F10
muteHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if event:getKeyCode() == 109 then -- F10
        mediaKey("MUTE")
        return true
    end

    return false
end):start()

-- Volume down with F11
soundDownHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if event:getKeyCode() == 103 then -- F11
        mediaKey("SOUND_DOWN")
        return true
    end

    return false
end):start()

-- Volume up with F12
soundUpHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if event:getKeyCode() == 111 then -- F12
        mediaKey("SOUND_UP")
        return true
    end

    return false
end):start()

-- Music previous track, play/pause and next track with F7, F8 and F9
musicControlHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local code = event:getKeyCode()

    if code == 98 then      -- F7
        hs.osascript.applescript('tell application "Music" to previous track')
        return true
    elseif code == 100 then -- F8
        hs.osascript.applescript('tell application "Music" to playpause')
        return true
    elseif code == 101 then -- F9
        hs.osascript.applescript('tell application "Music" to next track')
        return true
    end

    return false
end):start()

-- Toggle dark mode with Ctrl+Option+Shift+~
toggleDarkModeHotkey = hs.hotkey.bind({ "ctrl", "alt", "shift" }, "`", function()
    hs.osascript.applescript([[
        tell application "System Events"
            tell appearance preferences
                set dark mode to not dark mode
            end tell
        end tell
    ]])
end)

-- Mission Control with desktop previews with mouse button 3
local hasHoverTo, hoverTo = pcall(require, "hover_top_edge")
local missionControlHoverTimers

missionControlMouseHotkey = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown }, function(event)
    if event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber) == 3 then
        hs.spaces.toggleMissionControl()

        if missionControlHoverTimers then
            for _, timer in ipairs(missionControlHoverTimers) do
                timer:stop()
            end

            missionControlHoverTimers = nil
        elseif hasHoverTo then
            -- Hover the top edge, invisibly, to expand the desktop previews
            local function hoverTopEdge()
                local f = hs.mouse.getCurrentScreen():fullFrame()
                hoverTo(f.x + 10, f.y)
            end
            missionControlHoverTimers = {
                hs.timer.doAfter(0.32, hoverTopEdge),
                hs.timer.doAfter(0.5, hoverTopEdge),
            }
        end

        return true
    end

    return false
end):start()
