local function mediaKey(key)
    hs.eventtap.event.newSystemKeyEvent(key, true):post()
    hs.eventtap.event.newSystemKeyEvent(key, false):post()
end

local function music(command)
    hs.osascript.applescript('tell application "Music" to ' .. command)
end

-- Apple keyboard layout for keyboards that send plain F-keys (MacBook Pro top row)
local fKeyActions = {
    [122] = function() mediaKey("BRIGHTNESS_DOWN") end,                  -- F1
    [120] = function() mediaKey("BRIGHTNESS_UP") end,                    -- F2
    [99] = function() hs.spaces.toggleMissionControl() end,              -- F3
    [118] = function() hs.eventtap.keyStroke({ "cmd" }, "space", 0) end, -- F4: Spotlight
    [98] = function() music("previous track") end,                       -- F7
    [100] = function() music("playpause") end,                           -- F8
    [101] = function() music("next track") end,                          -- F9
    [109] = function() mediaKey("MUTE") end,                             -- F10
    [103] = function() mediaKey("SOUND_DOWN") end,                       -- F11
    [111] = function() mediaKey("SOUND_UP") end,                         -- F12
}

fKeyHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local action = fKeyActions[event:getKeyCode()]

    if action then
        action()
        return true
    end

    return false
end):start()

-- Media keys (F7, F8, F9 on Apple keyboards) control Music only, not the system's Now Playing app
local musicKeyCommands = {
    PREVIOUS = "previous track",
    REWIND = "previous track",
    PLAY = "playpause",
    NEXT = "next track",
    FAST = "next track",
}

musicMediaKeyHotkey = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(event)
    local key = event:systemKey()
    local command = musicKeyCommands[key.key]

    if command then
        if key.down and not key["repeat"] then
            music(command)
        end

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
