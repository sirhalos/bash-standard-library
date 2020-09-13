#!/usr/bin/env bash
#=============================================================================
# NAMESPACE
#=============================================================================
namespace 'init::import'

#=============================================================================
# INIT::IMPORT
#=============================================================================
function list {
    if [[ "$#" -ne 0 ]]; then
        error 'Invalid number of arguments'
    fi

    printf "%s\n" "${!__INIT_IMPORT_LIST__[@]}"
}

#=============================================================================
# END
#=============================================================================
