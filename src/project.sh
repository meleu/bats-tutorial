#!/usr/bin/env bash

main() {
  local fileFirstRun=/tmp/bats-tutorial-project-ran

  if [[ ! -f "${fileFirstRun}" ]]; then
    echo "Welcome to our project!"
    touch "${fileFirstRun}"
  fi

  echo "NOT IMPLEMENTED!" >&2
  return 1
}

main "$@"

