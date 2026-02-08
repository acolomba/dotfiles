function fish_prompt --description Hydro
    echo -e -n (set_color --bold red)(hostname -s)(set_color normal)":$_hydro_color_pwd$_hydro_pwd$hydro_color_normal $_hydro_color_git$$_hydro_git$hydro_color_normal$_hydro_status$hydro_color_normal "
end
