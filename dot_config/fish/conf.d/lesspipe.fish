if command -v lesspipe.sh >/dev/null
    set -gx LESSOPEN "| "(command -v lesspipe.sh)" %s"
    set -gx LESS_ADVANCED_PREPROCESSOR 1
end
