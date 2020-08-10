#!/usr/bin/env bash
set -Eeuo pipefail

#=============================================================================
# GLOBAL
#=============================================================================
declare -gxr TERM='xterm-256color'

if [[ ! -v __INIT_IMPORT_LIST__[@] ]]; then
    declare -Agx __INIT_IMPORT_LIST__=()
fi

if [[ ! -v __INIT_PATH_LIST__[@] ]]; then
    declare -Agx __INIT_PATH_LIST__=(
        ["$(cd $(dirname "${BASH_SOURCE}"); pwd -P)"]=''
    )
fi

#=============================================================================
# DEBUG
#=============================================================================
function debug::on {
    export PS4='+ [${BASH_SOURCE}:${FUNCNAME[0]}(): ${LINENO}]:> '

    set -v
    set -x

    return
}

function debug::off {
    set +v
    set +x

    return
}

#=============================================================================
# ERROR
#=============================================================================
function error {
    debug::off

    local -i indent=0
    local -i lineno_count=0
    local -i bash_source_count=1
    local -i trace_count="$(expr ${#BASH_SOURCE[@]} - 1)"

    local -i lineno="${BASH_LINENO[${lineno_count}]}"
    local bash_source="${BASH_SOURCE[${bash_source_count}]}"
    local func_name="${FUNCNAME[${bash_source_count}]}"

    tput sgr0 >&2
    tput bold >&2
    tput setaf 1; printf "%b" "\U1F480"
    tput setaf 7; printf ' ['  >&2
    tput setaf 5; printf "%s" "$(basename "${bash_source}"):" >&2
    tput setaf 4; printf "%s" "${func_name}():"  >&2
    tput setaf 3; printf "%s" "${lineno}"  >&2
    tput setaf 7; printf "%s " '] -'  >&2
    tput setaf 1; printf "%s\n" " ERROR: $@" >&2

    while [[ "${bash_source_count}" -ne "${trace_count}" ]]; do
        (( lineno_count += 1 ))
        (( bash_source_count += 1 ))
        (( indent += 4 ))

        lineno="${BASH_LINENO[${lineno_count}]}"
        bash_source="${BASH_SOURCE[${bash_source_count}]}"
        func_name="${FUNCNAME[${bash_source_count}]}"

        tput setaf 3; printf "%-${indent}s%b " "" "\U27A1" >&2
        tput setaf 7; printf '['  >&2
        tput setaf 5; printf "%s" "$(basename "${bash_source}"):" >&2
        tput setaf 4; printf "%s" "${func_name}():"  >&2
        tput setaf 3; printf "%s" "${lineno}"  >&2
        tput setaf 7; printf "%s " '] -'  >&2
        tput setaf 6; printf "%s\n" \
            "$(sed -n "${lineno}p" "${bash_source}" | sed -r 's|^\s+||')" >&2
    done

    tput sgr0 >&2

    exit 1

    return 1
}
