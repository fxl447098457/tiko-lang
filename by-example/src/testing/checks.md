# Checks

The checks in `std/testing` all report where they are written: the file, the
line, and the expressions as you wrote them.

```tiko
{{#include ../../examples/testing/checks/checks_test.tiko}}
```

`tiko test` in its directory:

**Output**

```text
{{#include ../../examples/testing/checks/checks_test.out}}
```

| Check | Passes when |
|---|---|
| `testing.Expect( c )`, `testing.ExpectFalse( c )` | `c` is true, or false |
| `testing.ExpectEq( a, b )`, `testing.ExpectNe( a, b )` | `a = b`, or `a <> b` |
| `testing.ExpectNear( a, b, eps )` | `a` is within `eps` of `b` |
| `testing.Require( c )`, `testing.RequireEq( a, b )` | as `Expect`, `ExpectEq`; a failure ends the test |
| `testing.Fail( "why" )` | never |
| `testing.Skip( "why" )` | the test ends here, counted as skipped |

- **A failed `Expect` lets the test go on**, so the second test reports both
  its failures.
- **`Require` stops the test** when it fails. The third test would follow a
  null pointer on its next line; `Require` ends it first.
- **`ExpectEq` takes numbers, strings, `ustring`s, booleans and pointers**, and
  a literal on either side. A literal is printed once.
- **`ExpectNear` is for floating point**: `0.1 + 0.2` is not exactly `0.3`.

### Activities

1. Change the third test's `Require` to `Expect` and run it again. What
   happens to the test, and to the run?
