# A test that stops the program

tiko has no exceptions to catch, so a test that ends the program would end
every test after it. `tiko test` restarts the program after such a test, and
stops a test that runs too long.

```tiko
{{#include ../../examples/testing/crashing/ages/ages.tiko}}
```

```tiko
{{#include ../../examples/testing/crashing/ages_test.tiko}}
```

`tiko test --timeout 1`:

**Output**

```text
{{#include ../../examples/testing/crashing/ages_test.out}}
```

- **`end 3` inside `ParseAge` ends the test program.** `tiko test` reports the
  test that was running as `CRASHED`, with the exit code, then starts the
  program again from the next test. A runtime error caught by `-exx`, which
  `tiko test` turns on, is reported the same way.
- **`--timeout 1`** stops a test after a second and reports it `TIMED OUT`.
  Without it a test may run for 120 seconds; `--timeout 0` means no limit.
- **The last test still runs**, and the summary counts crashes and timeouts
  apart from failures.

### Activities

1. Make `ParseAge` return `-1` for a bad age instead of ending the program,
   and change the test to expect it.
