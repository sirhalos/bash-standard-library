#!/usr/bin/env bash
#=============================================================================
# NAMESPACE
#=============================================================================
namespace 'term::color'

#=============================================================================
# GLOBAL
#=============================================================================
declare -Ar __TERM_COLOR__style__=(
    [bold]=$(       printf '%b' 'tput bold' )
    [dim]=$(        printf '%b' 'tput dim'  )
    [underlined]=$( printf '%b' 'tput smul' )
    [reverse]=$(    printf '%b' 'tput rev'  )
)

declare -Ar __TERM_COLOR__reset__=(
    [reset]=$( printf '%b' 'tput sgr0' )
)

declare -Ar __TERM_COLOR__foreground__=(
    [black]=$(   printf '%b' 'tput setaf 0' )
    [red]=$(     printf '%b' 'tput setaf 1' )
    [green]=$(   printf '%b' 'tput setaf 2' )
    [yellow]=$(  printf '%b' 'tput setaf 3' )
    [blue]=$(    printf '%b' 'tput setaf 4' )
    [magenta]=$( printf '%b' 'tput setaf 5' )
    [cyan]=$(    printf '%b' 'tput setaf 6' )
    [white]=$(   printf '%b' 'tput setaf 7' )
)

declare -Ar __TERM_COLOR__background__=(
    [on_black]=$(   printf '%b' 'tput setab 0' )
    [on_red]=$(     printf '%b' 'tput setab 1' )
    [on_green]=$(   printf '%b' 'tput setab 2' )
    [on_yellow]=$(  printf '%b' 'tput setab 3' )
    [on_blue]=$(    printf '%b' 'tput setab 4' )
    [on_magenta]=$( printf '%b' 'tput setab 5' )
    [on_cyan]=$(    printf '%b' 'tput setab 6' )
    [on_white]=$(   printf '%b' 'tput setab 7' )
)

#=============================================================================
# TERM::COLOR
#=============================================================================
function list {
    compgen -A 'function' | sort | while IFS= read -r i; do
        if [[ ! "${i}" =~ 'term::color::' ]]; then
            continue
        elif [[ "${i}" =~ 'term::color::list' ]]; then
            continue
        elif [[ "${i}" =~ 'term::color::strip' ]]; then
            continue
        else
            eval "${i}" "${i}"
            printf "%50s\n" "${i}"
        fi
    done

    return
}

function strip {
    sed -E 's/\\\[\\e\[[0123456789]([0123456789;])+m\\\]//g' <<< "$@"

    return
}

#=============================================================================
# MAIN
#=============================================================================
for fg in "${!__TERM_COLOR__foreground__[@]}"; do
    for style in "${!__TERM_COLOR__style__[@]}"; do
        for bg in "${!__TERM_COLOR__background__[@]}"; do

            # term::color::foreground::style::background()
            eval "${fg}::${style}::${bg}() {
                ${__TERM_COLOR__foreground__[${fg}]}
                ${__TERM_COLOR__style__[${style}]}
                ${__TERM_COLOR__background__[${bg}]}
                printf '%b' \"\${@}\"
                ${__TERM_COLOR__reset__[reset]}
            }"
        done

        # term::color::foreground::style()
        eval "${fg}::${style}() {
            ${__TERM_COLOR__foreground__[${fg}]}
            ${__TERM_COLOR__style__[${style}]}
            printf '%b' \"\${@}\"
            ${__TERM_COLOR__reset__[reset]}
        }"
    done

    # term::color::foreground()
    eval "${fg}() {
        ${__TERM_COLOR__foreground__[${fg}]}
        printf '%b' \"\${@}\"
        ${__TERM_COLOR__reset__[reset]}
    }"
done

unset fg
unset style
unset bg

#=============================================================================
# END
#=============================================================================
