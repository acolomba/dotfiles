local function mediaKey(key)
    hs.eventtap.event.newSystemKeyEvent(key, true):post()
    hs.eventtap.event.newSystemKeyEvent(key, false):post()
end

local function toggleDarkMode()
    hs.osascript.applescript([[
        tell application "System Events"
            tell appearance preferences
                set dark mode to not dark mode
            end tell
        end tell
    ]])
end

muteHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if event:getKeyCode() == 109 then -- F10
        mediaKey("MUTE")
        return true
    end
    return false
end):start()

soundDownHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if event:getKeyCode() == 103 then -- F11
        mediaKey("SOUND_DOWN")
        return true
    end
    return false
end):start()

soundUpHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if event:getKeyCode() == 111 then -- F12
        mediaKey("SOUND_UP")
        return true
    end
    return false
end):start()

local function musicCommand(cmd)
    hs.osascript.applescript('tell application "Music" to ' .. cmd)
end

musicControlHotkey = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local code = event:getKeyCode()
    if code == 98 then      -- F7
        musicCommand("previous track")
        return true
    elseif code == 100 then -- F8
        musicCommand("playpause")
        return true
    elseif code == 101 then -- F9
        musicCommand("next track")
        return true
    end
    return false
end):start()

-- Toggle dark mode with option+shift+ctrl+~
toggleDarkModeHotkey = hs.hotkey.bind({ "alt", "shift", "ctrl" }, "`", function()
    toggleDarkMode()
end)
