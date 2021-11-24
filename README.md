# BATS Tutorial

My own (shorter) version of the [official BATS tutorial](https://bats-core.readthedocs.io/en/stable/tutorial.html) for quick references in the future.

## Installation

```bash
mkdir my-project
cd my-project

git submodule add \
  https://github.com/bats-core/bats-core.git test/bats
git submodule add \
  https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git submodule add \
  https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
```

## First Test

`test/test.bats`:
```bash
@test "can run our script" {
  ./project.sh
}
```

Run the test:
```bash
./test/bats/bin/bats test/test.bats
# it'll fail

mkdir src/
echo '#!/usr/bin/env bash' > src/project.sh
chmod a+x src/project.sh

./test/bats/bin/bats test/test.bats
# it'll fail again
```

Let's add the path to the `test/test.bats`:
```bash
@test "can run our script" {
  ./src/project.sh
}
```

```bash
./test/bats/bin/bats test/test.bats
# it'll succeed! :)
```

## Using the `setup` function

In the `test/test.bats`
```bash
setup() {
  local dir
  # get the containing directory of this file
  dir="$( 
    cd "$( dirname "${BATS_TEST_FILENAME}" )" >/dev/null 2>&1 \
    && pwd
  )"
  PATH="${dir}/../src:${PATH}"
}


@test "Can run our script" {}
  # as we added `src/` to ${PATH}, we can omit the relative path
  project.sh
}
```

Still works:
```bash
./test/bats/bin/bats test/test.bats
# it'll succeed! :)
```

**Important notes about the `setup` function:**

- The `setup` function will be called before each individual test in the file.
- Each file can only define one `setup` function for all tests in it.
    - The `setup` functions can differ between different test files.


## Dealing with output

`project.sh`:
```bash
#!/usr/bin/env bash

echo "Welcome to our project!"

echo "NOT IMPLEMENTED!" >&2
exit 1
```

For better handling output, we should use the modules `bats-support` and 
`bats-assert`.

`test/test.bats`:
```bash
setup() {
  local dir

  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  # get the containing directory of this file
  dir="$( 
    cd "$( dirname "${BATS_TEST_FILENAME}" )" >/dev/null 2>&1 \
    && pwd
  )"
  PATH="${dir}/../src:${PATH}"
}


@test "Can run our script" {}
  run project.sh
  assert_output 'Welcome to our project!'
}
```

It'll fail:
```
./test/bats/bin/bats test/test.bats
 ✗ can run our script
   (from function `assert_output' in file test/test_helper/bats-assert/src/assert_output.bash, line 194,
    in test file test/test.bats, line 14)
     `assert_output 'Welcome to our project!'' failed

   -- output differs --
   expected (1 lines):
     Welcome to our project!
   actual (2 lines):
     Welcome to our project!
     NOT IMPLEMENTED!
   --


1 test, 1 failure
```

### What happens when you call your script prefixed with `run`

- `run` sucks up the `stdout` and `stderr` and stores it in `${output}`
- `run` stores the exit code in `${status}` and return 0
- `run` **never** fails
- `run` won't generate any output in the log of a failed test

Marking the test as failed and printing the context information is up to the
consumer of `${status}` and `${output}`. In our test above such consumer is
`assert_output`.


### What `assert_output` do

- compares `${output}` to the parameter it got and tell us the result
- to compare partial strings, use the `--partial` option

```bash
@test "Check welcome message" {
    run project.sh
    assert_output --partial 'Welcome to our project!'
}
```

That will make the test for our latest `project.sh` succeed, even if it finishes 
with a non-zero exit status.

### Other useful BATS libraries/functions

Skimming the README files of these repositories can be useful:

- <https://github.com/bats-core/bats-assert>
- <https://github.com/bats-core/bats-file>


## Cleaning up your mess with `teardown`

Often our tests leave behind some artifacts that clutter our test environment. We can define a `teardown` function to be called **after each test**, regardless whether it failed or not.

Test example:
```bash
@test "Show welcome message on first invocation" {
    run project.sh
    assert_output --partial 'Welcome to our project!'

    run project.sh
    refute_output --partial 'Welcome to our project!'
}
```

Since the `project.sh` produces the same output each time it runs, that test
will fail.

Now let's consider we want the `project.sh` to produce that output only in
the first run:
```bash
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
```

Now our test succeed:
```
./test/bats/bin/bats test/test.bats
 ✓ Show welcome message on first invocation

1 test, 0 failures
```

But if we run it again it fails:
```
./test/bats/bin/bats test/test.bats
 ✗ Show welcome message on first invocation
   (from function `assert_output' in file test/test_helper/bats-assert/src/assert_output.bash, line 186,
    in test file test/test.bats, line 14)
     `assert_output --partial 'Welcome to our project!'' failed

   -- output does not contain substring --
   substring : Welcome to our project!
   output    : NOT IMPLEMENTED!
   --


1 test, 1 failure
```

Let's define a `teardown` function to help us with this scenario:
```bash
teardown() {
  rm -f /tmp/bats-tutorial-project-ran
}
```

Now you can run your test multiple times.

You could do the `rm` in the test code itself, but if would get skipped on
failures.

**Important notes about the `teardown` function:**

- it runs after **every single** test in a file, regardless of test success.
- as a test ends at its first failure, using `teardown` make sure it's a code to be always executed
- each `.bats` file can only one `teardown` function
- if you need a different `teardown`, create it with the tests that will need it in a separate file


## Test what you can, `skip` what you can't test

If you're running tests on environments that are not ready for testing, you can
`skip` such tests.

As an example, let's use that script that echoes a message only in the first run
and `skip` the test instead of doing the cleanup:
```bash
teardown() {
    : # no cleanup at all
}

@test "Show welcome message on first invocation" {
    if [[ -f /tmp/bats-tutorial-project-ran ]]; then
        skip 'The FIRST_RUN_FILE already exists'
    fi

    run project.sh
    assert_output --partial 'Welcome to our project!'

    run project.sh
    refute_output --partial 'Welcome to our project!'
}
```

**Important notes about the `skip` call:**

- it won't fail a test
- it's counted separately
- no test command after `skip` will be executed
- if an error occurs before `skip`, the test will fail
    - tip: use `skip` as early as you know it doesn't make sense to continue
- an optional reason can be passed to `skip` to be printed in the test output



