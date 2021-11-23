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

## Using the setup function

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

Important notes about the `setup` function:

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

- <https://github.com/bats-core/bats-assert>
- <https://github.com/bats-core/bats-file>



