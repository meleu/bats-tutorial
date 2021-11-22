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
