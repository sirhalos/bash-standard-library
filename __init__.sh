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
