if command -q screen
    function scr --wraps screen
        screen -d -RR $argv
    end
end
