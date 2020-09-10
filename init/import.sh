#!/usr/bin/env bash
namespace 'init::import'

function list {
    if [[ "$#" -ne 0 ]]; then
        error 'Invalid number of arguments'
    fi

    printf "%s\n" "${!__INIT_IMPORT_LIST__[@]}"
}
