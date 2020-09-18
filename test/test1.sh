#!/usr/bin/env bash
if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then
    source "$(cd "$(dirname "${0}")"; pwd -P)/../__init__.sh"
fi

import 'test'

test::group::add \
    --test 'output' \
    --description 'Test to check output'

    test::local::is \
        --test 'output' \
        --description 'Checking that echo Hello works' \
        --command 'echo Hello' \
        --expected 'Hello'
test::group::done 'output'
test::done
