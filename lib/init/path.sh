#!/usr/bin/env bash
#=============================================================================
# NAMESPACE
#=============================================================================
namespace 'init::path'

#=============================================================================
# INIT::PATH
#=============================================================================
function append {
    if [[ "$#" -eq 0 ]]; then
        error 'Invalid number of arguments'
    fi

    local fully_qualified_path
    local -r cwd="$(pwd -P)"

    cd "$(dirname "${BASH_SOURCE[1]}")"

    for i in "${@}"; do
        fully_qualified_path="$(cd $(dirname ${i}); pwd -P)"

        if [[ ! -d "${fully_qualified_path}" ]]; then
            error "Path ${i} is not a directory"
        fi

        if [[ -v __INIT__path_list__["${fully_qualified_path}"] ]]; then
            warning "Path ${i} already in init::path"
        else
            __INIT__path_list__["${fully_qualified_path}"]=''
        fi
    done

    cd "${cwd}" || error "Unable to cd to ${cwd}"

    return
}

function list {
    if [[ "$#" -ne 0 ]]; then
        error 'Invalid number of arguments'
    fi

    printf "%s\n" "${!__INIT__path_list__[@]}"
}

#=============================================================================
# END
#=============================================================================
