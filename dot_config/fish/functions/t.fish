function t --wraps tmux
    tmux new -A -D -s main $argv
end
