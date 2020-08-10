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
