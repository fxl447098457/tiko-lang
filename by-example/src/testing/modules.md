# Testing a module

In a real project the code under test lives in a [module](../modules/writing.md),
and its tests are a separate program that imports it. The module is the one
from the [failing test](failing.md), fixed:

```tiko
{{#include ../../examples/testing/wordstats/wordstats.tiko}}
```

and its tests:

```tiko
{{#include ../../examples/testing/moduletests.tiko}}
```

**Output**

```text
{{#include ../../examples/testing/moduletests.out}}
```

The test program sees the module exactly as any other importer does: its
public procedures, through the module's name, and nothing else. Tests written
against the public interface keep passing while you rearrange the inside of the
module, and fail when you change what its callers depend on, which is the
change you want to hear about.

`#import` lines come before any other code, so the `#include` of the test
library goes after them.

````admonish danger title="Pitfall"
**Tests do not run in the same order on every platform.** Each `TEST` and each
`SUITE` registers itself when the program starts, and platforms walk
those registrations in opposite orders: a program with two suites lists them
in declaration order on Linux and macOS and in reverse on Windows, and run verbosely,
with `fbcu.run_tests( true, true )`, it lists the tests of one suite the same
way. Nothing goes wrong while every test
stands alone. A test that relies on something an earlier test did passes on one
platform and fails on another. Give every test its own setup.
````

### Activities

1. Add a public `UpperWords` to `wordstats` that capitalises each word, and a
   test for it.
2. Try to test a procedure of the module that is not `public`, and read the
   diagnostic.
