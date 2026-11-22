# Testing

A program that compiles is a program the compiler could read. Whether it does
what you meant is a separate question, and a test answers it every time you
build. tiko ships a unit-test library, `fbcunit.bi`: tests are blocks of code
that check results with assertion macros, grouped into suites, and one call
runs them all and prints a summary.

```tiko
{{#include ../../examples/testing/firsttests.tiko}}
```

**Output**

```text
{{#include ../../examples/testing/firsttests.out}}
```

- **`#include once "fbcunit.bi"`** brings in the library. It is a header, not
  a module, so it is included rather than imported.
- **`SUITE( clamping )` … `END_SUITE`** groups related tests. Each
  **`TEST( name )` … `END_TEST`** is one test, and its body is ordinary code.
- **`CU_ASSERT_EQUAL( a, b )`** records a pass when `a = b` and a failure
  otherwise. The summary counts both, per suite.
- **`fbcu.run_tests( )`** runs every test, prints the summary, and returns
  `true` only if every assertion passed. `end iif( …, 0, 1 )` turns that into
  the program's exit code, which is what a build script or a CI job checks.

A test program written this way is an ordinary program, built with
`tiko firsttests.tiko` and run like any other. fbcunit is the library
FreeBASIC code already uses; for new code, `test` blocks and
[tiko test](tikotest.md) find, build and run a project's tests in one command.

Name a suite after the behaviour it checks, `clamping`, not after the
procedure it tests, `Clamp`. A suite is a namespace, and inside a suite called
`clamp` the name `Clamp` would mean the suite, not the function.

### Activities

1. Add a test that `Clamp( 5, 5, 5 )` is `5`.
2. Break `Clamp` on purpose and watch the summary and the exit code change.
