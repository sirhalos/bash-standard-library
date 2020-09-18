#!/usr/bin/env bash
#=============================================================================
# NAMESPACE
#=============================================================================
namespace 'test'

#=============================================================================
# GLOBAL
#=============================================================================
declare -Ag __TEST__=()

#=============================================================================
# COUNT
#=============================================================================
function count::fail::increment {
    if [[ "$#" -ne 1 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    local -r test="${1}"

    if [[ "$(test::group::exist "${test}")" == 'False' ]]; then
        error "TEST: '${test}' not defined"; exit 1
    fi

    local -r test_sha="${__TEST__["${test}"]}"
    local -n test_pointer="__TEST__${test_sha}__"
    local -r test_count="${test_pointer['fail']}"

    let test_pointer['fail']="${test_count} + 1"

    return
}

function count::fail::total {
    if [[ "$#" -ne 1 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    local -r test="${1}"

    if [[ "$(test::group::exist "${test}")" == 'False' ]]; then
        error "TEST: '${test}' not defined"; exit 1
    fi

    local -r test_sha="${__TEST__["${test}"]}"
    local -n test_pointer="__TEST__${test_sha}__"

    echo "${test_pointer['fail']}"

    return
}

function count::pass::increment {
    if [[ "$#" -ne 1 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    local -r test="${1}"

    if [[ "$(test::group::exist "${test}")" == 'False' ]]; then
        error "TEST: '${test}' not defined"; exit 1
    fi

    local -r test_sha="${__TEST__["${test}"]}"
    local -n test_pointer="__TEST__${test_sha}__"
    local -r test_count="${test_pointer['pass']}"

    let test_pointer['pass']="${test_count} + 1"

    return
}

function count::pass::total {
    if [[ "$#" -ne 1 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    local -r test="${1}"

    if [[ "$(test::group::exist "${test}")" == 'False' ]]; then
        error "TEST: '${test}' not defined"; exit 1
    fi

    local -r test_sha="${__TEST__["${test}"]}"
    local -n test_pointer="__TEST__${test_sha}__"

    echo "${test_pointer['pass']}"

    return
}

#=============================================================================
# GROUP
#=============================================================================
function group::add {
    if [[ "$#" -ne 4 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    local test
    local description

    while [[ "$#" -gt 0 ]]; do
        if [[ "$#" -lt 2 ]]; then
            error "Invalid number of arguments '$#'"; exit 1
        fi

        case "${1}" in
            -t | --test )
                readonly test="${2}";        shift 2 ;;
            -d | --description )
                readonly description="${2}"; shift 2 ;;
            *)
                error "Invalid argument '${1}'"; exit 1 ;;
            --)
                break ;;
        esac
    done

    if [[ -z "${test:-}" ]] || [[ -z "${description:-}" ]]; then
        error 'Missing required argument'; exit 1
    fi


    if [[ "$(test::group::exist "${test}")" == 'True' ]]; then
        error "TEST: '${test}' already defined"; exit 1
    fi

    local -r test_sha=$(sha1sum <<< $(date +%s%N) | cut -c1-8)

    __TEST__["${test}"]="${test_sha}"

    declare -Agx "__TEST__${test_sha}__"

    local -n test_pointer="__TEST__${test_sha}__"

    test_pointer['description']="${description}"
    test_pointer['pass']=0
    test_pointer['fail']=0

    tput bold
    tput setaf 4; printf "+=============================================================================\n+"
    tput setaf 3; printf "        TEST: ${test}\n"
    tput setaf 4; printf "+"
    tput setaf 3; printf " DESCRIPTION: $(test::group::description "${test}")\n"
    tput setaf 4; printf "+=============================================================================\n"
    tput sgr0

    return
}

function group::count {
    if [[ "$#" -ne 0 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    printf "%s\n" "${#__TEST__[@]}"

    return
}

function group::description {
    if [[ "$#" -ne 1 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    local -r test="${1}"

    if [[ "$(test::group::exist "${test}")" == 'False' ]]; then
        error "TEST: '${test}' not defined"; exit 1
    fi

    local -r test_sha="${__TEST__["${test}"]}"
    local -n test_pointer="__TEST__${test_sha}__"

    echo "${test_pointer['description']}"

    return
}

function group::exist {
    if [[ "$#" -ne 1 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    local -r test="${1}"

    if [[ ! -v __TEST__["${test}"] ]]; then
        echo 'False'; return
    fi

    echo 'True'; return
}

function group::list {
    if [[ "$#" -ne 0 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    sort <<< $(printf "%s\n" "${!__TEST__[@]}")

    return
}

function group::done {
    if [[ "$#" -ne 1 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    local -r test="${1}"

    tput bold
    tput setaf 4; printf "+=============================================================================\n+"
    tput setaf 2; printf " PASS: $(test::count::pass::total  "${test}")\n"
    tput setaf 4; printf "+"
    tput setaf 1; printf " FAIL: $(test::count::fail::total  "${test}")\n"
    tput setaf 4; printf "+=============================================================================\n+\n"
    tput sgr0

    return
}

#=============================================================================
# LOCAL
#=============================================================================
function local::is {
     if [[ "$#" -ne 8 ]] && [[ "$#" -ne 10 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    __TEST_local__ --style 'is' "$@"

    return
}

function local::isnt {
     if [[ "$#" -ne 8 ]] && [[ "$#" -ne 10 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    __TEST_local__ --style 'isnt' "$@"

    return
}

function local::like {
     if [[ "$#" -ne 8 ]] && [[ "$#" -ne 10 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    __TEST_local__ --style 'like' "$@"

    return
}

function local::unlike {
    if [[ "$#" -ne 8 ]] && [[ "$#" -ne 10 ]]; then
        error "Invalid number of arguments '$#'"; exit 1
    fi

    __TEST_local__ --style 'unlike' "$@"

    return
}

#=============================================================================
# DONE
#=============================================================================
function done {
    if [[ "$#" -ne 0 ]]; then
        error 'Invalid number of arguments'; exit 1
    fi

    local pass_total=0
    local fail_total=0
    local total=0

    for sha in "${__TEST__[@]}"; do
        local -n test_pointer="__TEST__${sha}__"

        pass_total="$(( ${pass_total} + ${test_pointer['pass']} ))"
        fail_total="$(( ${fail_total} + ${test_pointer['fail']} ))"

        unset test_pointer
    done

    local -i total="$(( ${pass_total} + ${fail_total} ))"

    tput bold
    tput setaf 4; printf "+=============================================================================\n+"
    tput setaf 3; printf " TEST COMPLETE!\n"
    tput setaf 4; printf "+=============================================================================\n+"
    tput setaf 2; printf " PASS: ${pass_total}\n"
    tput setaf 4; printf "+"
    tput setaf 1; printf " FAIL: ${fail_total}\n"
    tput setaf 4; printf "+=============================================================================\n+"
    tput setaf 3; printf " TOTAL: ${total}\n"
    tput setaf 4; printf "+=============================================================================\n"
    printf "\n"

    tput sgr0

    if [[ "${fail_total}" -ne 0 ]]; then
        exit 1
    fi

    return
}

#=============================================================================
# PRIVATE
#=============================================================================
function __TEST_local__ {
    if [[ "$#" -ne 10 ]] && [[ "$#" -ne 12 ]]; then
        test::info::error "Invalid number of arguments '$#'"
        usage::__TEST_local__; exit 1
    fi

    local style         # required
    local test          # required
    local description   # required
    local command       # required
    local filter        # optional  Used for post parsing Example jq or yq
    local expected      # required

    while [[ "$#" -gt 0 ]]; do
        if [[ "$#" -lt 2 ]]; then
            error "Invalid number of arguments '$#'"
            usage::__TEST_local__; exit 1
        fi

        case "${1}" in
            -s | --style )
                readonly style="${2}";       shift 2 ;;
            -t | --test )
                readonly test="${2}";        shift 2 ;;
            -d | --description )
                readonly description="${2}"; shift 2 ;;
            -c | --command )
                readonly command="${2}";     shift 2 ;;
            -e | --expected )
                readonly expected="${2}";    shift 2 ;;
            -f | --filter )
                filter="${2}";               shift 2 ;;
            *)
                error "Invalid argument '${1}'"
                usage::__TEST_local__; exit 1 ;;
        esac
    done

    if [[ -z "${style:-}"       ]] || [[ -z "${test:-}"    ]] || \
       [[ -z "${description:-}" ]] || [[ -z "${command:-}" ]] || \
       [[ -z "${expected:-}"    ]]
    then
        error 'Missing required argument'
        usage::__TEST_local__; exit 1
    fi

    local -r return="$(eval "${command}" 2> /dev/null)"

    if [[ -n "${VERBOSE:-}" ]]; then
        echo "COMMAND: ${return}"
    fi

    if [[ -n "${filter:-}" ]]; then
        got="$(echo "${return}" | eval "${filter}" 2> /dev/null)"
    else
        got="${return}"
    fi

    if [[ -n "${VERBOSE:-}" ]]; then
        echo "GOT: ${got}"
    fi

    local result

    case "${style}" in
        is )
            if [[ "${got}" == "${expected}" ]]; then
                count::pass::increment "${test}"
                readonly result="\xE2\x9C\x85"
            else
                count::fail::increment "${test}"
                readonly result="\xE2\x9D\x8C"
            fi
            ;;
        isnt )
            if [[ "${got}" != "${expected}" ]]; then
                count::pass::increment "${test}"
                readonly result="\xE2\x9C\x85"
            else
                count::fail::increment "${test}"
                readonly result="\xE2\x9D\x8C"
            fi
            ;;
        like )
            if [[ "$( echo "${got:-''}" \
                   |& grep -Pzbc "(?xms)$(echo "${expected}" \
                                        | sed 's| |\\s|g')")" -gt 0 ]]
            then
                count::pass::increment "${test}"
                readonly result="\xE2\x9C\x85"
            else
                count::fail::increment "${test}"
                readonly result="\xE2\x9D\x8C"
            fi
            ;;
        unlike )
            if [[ "$( echo "${got:-''}" \
                   |& grep -Pzbc "(?xms)$(echo "${expected}" \
                                        | sed 's| |\\s|g')")" -gt 0 ]]
            then
                count::fail::increment "${test}"
                readonly result="\xE2\x9D\x8C"
            else
                count::pass::increment "${test}"
                readonly result="\xE2\x9C\x85"
            fi
            ;;
        *)
            error "Invalid style '${style}'"; exit 1 ;;
    esac


    local -r group_description=$(group::description "${test}")
    local -r group_pass_count=$(count::pass::total  "${test}")
    local -r group_fail_count=$(count::fail::total  "${test}")

    let test_count="${group_pass_count} + ${group_fail_count}"

    printf " ${result}"

    tput bold
    tput setaf 7; printf " [ "
    tput setaf 5; printf "${style^^}"
    tput setaf 7; printf " ] "
    tput setaf 3; printf "${test_count}"
    tput setaf 7; printf " - "
    tput setaf 7; printf "${description}\n"
    tput sgr0

    if [[ "${result}" == "\xE2\x9D\x8C" ]]; then
        tput bold
        tput setaf 3; printf "    \xE2\x86\xAA       "
        tput setaf 4; printf "got: "
        tput setaf 1; printf "'${got}'\n"
        tput setaf 3; printf "    \xE2\x86\xAA  "
        tput setaf 4; printf "expected: "
        tput setaf 2; printf "'${expected}'\n\n"
        tput sgr0
    fi

    return
}

#=============================================================================
# USAGE
#=============================================================================

#=============================================================================
# END
#=============================================================================
