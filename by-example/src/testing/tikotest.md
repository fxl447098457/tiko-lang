# tiko test

A test is a block of its own, `test "name"` … `end test`, written beside the
code it checks. `tiko test` finds every test in a project, builds them into one
program and runs it.

A module, `conv/conv.tiko`, in a project whose `tiko.toml` names the package
`temps`:

```tiko
{{#include ../../examples/testing/temps/conv/conv.tiko}}
```

Tests inside the module's directory, `conv/conv_test.tiko`:

```tiko
{{#include ../../examples/testing/temps/conv/conv_test.tiko}}
```

and tests beside the project's `tiko.toml`, `conv_api_test.tiko`:

```tiko
{{#include ../../examples/testing/temps/conv_api_test.tiko}}
```

`tiko test`, in the project's directory:

**Output**

```text
{{#include ../../examples/testing/temps/conv_api_test.out}}
```

- **`#import "std/testing"`** brings in the checks. Each is a macro, used
  qualified: `testing.ExpectEq( a, b )`.
- **`test "name"` … `end test`** is one test; its body is ordinary code, and
  what it declares is its own.
- **A test file's name ends `_test.tiko`.** Inside a module's directory it
  begins with the module's `#module` line and is part of the module, so it can
  test `Round1_`, which no importer can see. Anywhere else it is a program of
  its own that imports the module like any client.
- **A normal build drops all of it.** `tiko build` leaves a module's
  `_test.tiko` files out and skips every `test` block, so the shipped program
  carries no tests.
- **The exit code is 0** when every test passed and 1 otherwise.

| Command | Runs |
|---|---|
| `tiko test` | every test of the project |
| `tiko test --filter freeze` | the tests whose names hold `freeze` |
| `tiko test conv` | the tests under the `conv` directory |
| `tiko test -- --list` | nothing: lists the tests |

### Activities

1. Break `ToCelsius` on purpose and read the failure: which file, which line,
   and which values?
2. Move the `test "there and back"` block into `conv.tiko`, below
   `ToCelsius`, and run `tiko test` again.
