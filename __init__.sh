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
    declare -gxr PS4='+ [${BASH_SOURCE}:${FUNCNAME[0]}(): ${LINENO}]:> '

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

#=============================================================================
# NAMESPACE
#=============================================================================
function namespace {
    if [[ "$#" -ne 1 ]]; then
        error 'Invalid number of arguments'
    fi

    if [[ ! "${1}" =~ ^[A-Za-z] ]]; then
        error 'Namespace must start with a char'
    fi

    declare -gx __NAMESPACE__="${1}"

    return
}

#=============================================================================
# FROM
#=============================================================================
function from {
    if [[ "$#" -lt 3 ]]; then
        error 'Invalid number of arguments'
    fi

    for i in "${@}"; do
        case "${i}" in
            -h | --help )
                usage::__init__::from; exit 0
                ;;
        esac
    done

    if [[ "${1}" =~ ^\- ]]; then
        error 'First argument must be either a namespace or a path'
    fi

    if [[ "${2}" != 'import' ]]; then
        error 'Second argument must be import'
    fi

    local -r from="${1}"; shift 2

    import --from="${from}" $@

    return
}

#=============================================================================
# IMPORT
#=============================================================================
function import {
    if [[ "$#" -eq 0 ]]; then
        error 'Invalid number of arguments'
    fi

    local -a imports=()
    local -a paths=()

    local debug
    local from
    local reload
    local translated_import

    while [[ "$#" -gt 0 ]]; do
        case "${1}" in
            -d | --debug )
                readonly debug='True';    shift

                debug::on
                ;;
            -f | --from )
                shift

                if [[ "$#" -eq 0 ]]; then
                    error 'Invalid number of arguments'
                else
                    readonly from="${1}"; shift
                fi

                ;;
            --from=* )
                readonly from="${1#*=}";  shift
                ;;
            -h | --help )
                usage::__init__::import;  exit 0
                ;;
            -r | --reload )
                readonly reload='True';   shift
                ;;
            * )
                imports+=( "${1}" );      shift
                ;;
        esac
    done

    for import in "${imports[@]}"; do
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # Namespace-based
        #   - CAN have :: in the name, but may not if it is a single word
        #   - Does NOT have a slash in the name
        #   - Must NOT end in .sh
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if [[   "${import}" =~ :: || ! "${import}" =~ ::    ]] && \
           [[ ! "${import}" =~ \/    ]] && \
           [[ ! "${import}" =~ \.sh$ ]]
        then
            # Delimiters can only be single characters, so change :: to :
            namespace_import=$(echo "${import}" | sed 's/::/:/g')

            if [[ "${namespace_import}" =~ : ]]; then
                # Create an array of paths to walk down separated on ':'
                IFS=':' read -a paths -r <<< "${namespace_import}"; unset IFS
            else
                # single word namespace
                paths=( "${namespace_import}" )
            fi

            local -r namespace_imported

            for init_path in "${!__INIT_PATH_LIST__[@]}"; do
                translated_import="${init_path}"

                if [[ "${#paths[@]}" -gt 1 ]]; then
                    for path in "${paths[@]::${#paths[@]}-1}"; do
                        if [[ -d "${translated_import}/${path}" ]]; then
                            translated_import+="/${path}"
                        elif [[ -d "${translated_import}/lib/${path}" ]]; then
                            translated_import+="/lib/${path}"
                        else
                            error "Unable to find import '${import}'"
                        fi
                    done
                fi

                if [[ -f "${translated_import}/${paths[-1]}.sh" ]]; then
                    readonly namespace_imported='True'

                    translated_import+="/${paths[-1]}.sh"; break 1
                elif [[ -f "${import}/lib/${paths[-1]}.sh" ]]; then
                    readonly namespace_imported='True'

                    translated_import+="/lib/${paths[-1]}.sh"; break 1
                else
                    continue
                fi
            done

            if [[ -z "${namespace_imported:-}" ]]; then
                error "Unable to find import '${import}'"
            fi

        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # Relative-path
        #   - Does NOT have :: in the name
        #   - MUST not start with /
        #   - CAN have / in the name, but may not if it is a single word
        #   - MUST end in .sh
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        elif [[ ! "${import}" =~ ::    ]] && \
             [[ ! "${import}" =~ ^\/   ]] && \
             [[   "${import}" =~ \/    || ! "${import}" =~ \/ ]] && \
             [[   "${import}" =~ \.sh$ ]]
        then
            translated_import="$(cd $(dirname "${0}"); pwd -P)/${import}"

            if [[ ! -f "${translated_import}" ]]; then
                error "Unable to find import '${translated_import}'"
            fi
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # Absolute-path
        #   - Does NOT have :: in the name
        #   - MUST start with / in the name
        #   - MUST end in .sh
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        elif [[ ! "${import}" =~ ::    ]] && \
             [[   "${import}" =~ ^\/   ]] && \
             [[   "${import}" =~ \.sh$ ]]
        then
            translated_import="${import}"

            if [[ ! -f "${translated_import}" ]]; then
                error "Unable to find import '${translated_import}'"
            fi
        else
            echo "ERROR: ${BASH_LINENO[0]}"; exit 1
        fi

        if [[ -z "${translated_import:-}" ]]; then
            echo "ERROR: ${BASH_LINENO[0]}"; exit 1
        fi

        if [[ "${reload:-}" == 'True' ]] && \
           [[ -v __INIT_IMPORT_LIST__["${translated_import}"] ]]; then
            unset __INIT_IMPORT_LIST__["${translated_import}"]
        fi

        local self_source="$(
            cd $(dirname "${BASH_SOURCE}")
            pwd -P)/$(basename "${BASH_SOURCE}"
        )"

        if [[ ! -v __INIT_IMPORT_LIST__["${translated_import}"] ]]; then
            __INIT_IMPORT_LIST__["${translated_import}"]=''
            namespace="$(env -i bash --noprofile --norc << __SCRIPT__
                         source "${self_source}"
                         source "${translated_import}"

                         echo "\${__NAMESPACE__:-}"
__SCRIPT__
                         )"

            local -ar outer_functions=(
                $(compgen -A 'function' | sort)
            )

            local -ar outer_variables=(
                $(compgen -A 'variable' | sort)
            )

            local -ar inner_functions=(
                $(env -i bash --noprofile --norc << __SCRIPT__
                  source "${self_source}"
                  source "${translated_import}"

                  compgen -A 'function' | sort
__SCRIPT__
                  ) )

            local -ar inner_variables=(
                $(env -i bash --noprofile --norc << __SCRIPT__
                  source "${self_source}"
                  source "${translated_import}"

                  compgen -A 'variable' | sort
__SCRIPT__
                  ) )

            local function_body

            for i in "${inner_functions[@]}"; do
                for o in "${outer_functions[@]}"; do
                    if [[ "${i}" == "${o}" ]]; then
                        continue 2
                    fi
                done

               function_body="$(
                    env -i bash --noprofile --norc << __SCRIPT__
                    source "${self_source}"
                    source "${translated_import}"

                    declare -f "${i}"
__SCRIPT__
                    )"

                function_body="${function_body#*{}"
                function_body="${function_body%\}}"

                if [[ -n "${namespace:-}" ]]; then
                    if [[ $(declare -f "${namespace}::${i}" &> /dev/null) ]]
                    then
                        error "Function ${namespace}::${i} is already defined"
                    fi

                    eval "${namespace}::${i}() { ${function_body} }"
                else
                    if [[ $(declare -f "${i}" &> /dev/null) ]]; then
                        error "Function '${i}' in '${import}' is already defined"
                    fi

                    eval "${i}() { ${function_body} }"
                fi
            done

            local variable_declare

            for i in "${inner_variables[@]}"; do
                for o in "${outer_variables[@]}"; do
                    if [[ "${i}" == "${o}" ]] || \
                       [[ "${i}" == '__NAMESPACE__' ]]
                    then
                        continue 2
                    fi
                done

                variable_declare="$(
                    env -i bash --noprofile --norc << __SCRIPT__
                    source "${self_source}"
                    source "${translated_import}"

                    declare -p "${i}"
__SCRIPT__
                    )"

                if [[ -v "$(echo "${i}")" ]]; then
                    error "Variable '${i}' in '${import}' is already defined"
                else
                    eval "${variable_declare}"
                fi
            done
        fi
    done

    if [[ -n "${debug:-}" ]] && [[ "${debug:-}" == 'True' ]]; then
        debug::off
    fi

    return
}

#=============================================================================
# USAGE
#=============================================================================
function usage::__init__::from {
>&2 cat <<__USAGE__

Usage:
    from <namespace | path> import [-d] [-h] [-r] <imports[0]> <imports[1]>
                                                  <imports[2]> ...

Optional Arguments:
    -d, --debug                 Display debug information of path searches
    -h, --help                  Display function usage information
    -r, --reload                Re-import import even if imported previously

Required Argument:
    @imports

Examples:
    from '.' import 'test_01.sh' 'test_02.sh' 'test_03.sh'
    from 'dir1::dir2' import 'test_01' 'test_02' 'test_03'
    from 'dir1' import 'dir2/test_01.sh'
    from 'tmp' import 'dir1::test_01'
    from '../../../' import 'tmp/dir1/test_01.sh'

Description:
    Provides the ability import source functions and variables from files.
    Imports will only once occur once unless the reload argument is provided.

Notes:
    The from string and imports array can be provided in 1 of 3 varieties.
        * Namespace
        * Relative path
        * Absolute path

    Namespace:
        - COULD have '::' in the name
        - NEVER has a '/' in the name
        - MUST NOT end in '.sh' if name is an 'imports' array element
        - DO NOT need to specify 'lib' directories
        - IF the function 'import::path::add' was used, then the additional
          paths will be searched first, followed by the base path of the
          repo where '__init__.sh' is located

    Relative path:
        - NEVER has '::' in the name
        - COULD have a '/' in the name
        - NEVER starts with a '/'
        - MUST end in '.sh' if name is an 'imports' array element
        - MUST specify 'lib' directories
        - IF the function 'import::path::add' was used, then the additional
          paths will be searched first, followed by the base path of the
          repo where '__init__.sh' is located

    Absolute path:
        - NEVER has '::' in the name
        - MUST have a '/' in the name
        - MUST start with a '/'
        - MUST end in '.sh' if name is an 'imports' array element
        - MUST specify 'lib' directories
        - IF the function 'import::path::add' was used, then the additional
          paths will be searched first, followed by the base path of the
          repo where '__init__.sh' is located

__USAGE__

    return
}

function usage::__init__::import {
>&2 cat <<__USAGE__

Usage:
    import [-d] [-f from] [-h] [-r] <imports[0]> <imports[1]> <imports[2]> ...

Optional Arguments:
    -d, --debug                 Display debug information of path searches
    -f, --from                  Prepend a namespace or path to import paths
    -h, --help                  Display function usage information
    -r, --reload                Re-import import even if previously imported

Required Argument:
    @imports

Examples:
    import 'test_01.sh' 'test_02.sh' 'test_03.sh'
    import 'dir1::test_01' 'dir1::test_02' 'dir1::test_03'
    import 'dir1/test_01.sh'
    import 'tmp::dir1::test_01'
    import '../../../tmp/dir1/test_01.sh'

Description:
    Provides the ability import source functions and variables from files.
    Imports will only once occur once unless the reload argument is provided.

    The from string and imports array can be provided in 1 of 3 varieties.
        * Namespace
        * Relative path
        * Absolute path

    Namespace:
        - COULD have '::' in the name
        - NEVER has a '/' in the name
        - MUST NOT end in '.sh'
        - DO NOT need to specify 'lib' directories
        - IF the function 'import::path::add' was used, then the additional
          paths will be searched first, followed by the base path of the
          repo where '__init__.sh' is located

    Relative path:
        - NEVER has '::' in the name
        - COULD have a '/' in the name
        - NEVER starts with a '/'
        - MUST end in '.sh'
        - MUST specify 'lib' directories
        - IF the function 'import::path::add' was used, then the additional
          paths will be searched first, followed by the base path of the
          repo where '__init__.sh' is located

    Absolute path:
        - NEVER has '::' in the name
        - MUST have a '/' in the name
        - MUST start with a '/'
        - MUST end in '.sh'
        - MUST specify 'lib' directories
        - IF the function 'import::path::add' was used, then the additional
          paths will be searched first, followed by the base path of the
          repo where '__init__.sh' is located

__USAGE__

    return
}

#=============================================================================
# END
#=============================================================================
