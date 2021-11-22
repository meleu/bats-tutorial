#!/usr/bin/env bats


setup() {
  local dir

  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  # get the containing directory of this file
  dir="$( cd "$( dirname "${BATS_TEST_FILENAME}" )" >/dev/null 2>&1 && pwd )"
  PATH="${dir}/../src:${PATH}"
}

teardown() {
  rm -f /tmp/bats-tutorial-project-ran
}


@test "Check welcome message only in first invocation" {
  run project.sh
  assert_output --partial 'Welcome to our project!'

  run project.sh
  refute --partial 'Welcome to our project!'
}


@test "Check welcome message" {
  run project.sh
  assert_output --partial 'Welcome to our project!'
}

