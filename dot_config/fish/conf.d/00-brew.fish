if test -x /opt/homebrew/bin/brew
    eval $(/opt/homebrew/bin/brew shellenv fish)
    set -gx HOMEBREW_NO_ASK 1
else if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)
    set -gx HOMEBREW_NO_ASK 1
end
