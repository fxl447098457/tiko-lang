# Exit codes

When a program ends it returns a number to whatever started it. Zero means
success to every shell and build tool; anything else is a failure whose number
the caller can test. A program that can fail should say so through its exit
code, not only through what it prints.

```tiko
{{#include ../../examples/process/exitcode.tiko}}
```

**Output**, and exit code 4:

```text
{{#include ../../examples/process/exitcode.out}}
```

`end n` stops the program at once with exit status `n`. Reaching the end of the
program, or a bare `end`, exits with 0. The caller reads the code as `$?` in a
Unix shell, `%ERRORLEVEL%` in `cmd.exe`, or as the result of `exec` or `shell`
in another tiko program.

```admonish info title="On Linux and macOS"
An exit code is one byte: only 0 to 255 reach the caller, so `end 300`
arrives as 44. Keep exit codes in that range on every platform.
```

`end` does not return to the caller of the current procedure; it ends the whole
program, so a procedure deep in the program can stop it. Use it for the
program's final answer, and let errors inside the program travel by the means
in [Error Handling](../errors/index.md).

### Activities

1. Change `CountErrors` to return 0 and check the exit code in your shell.
2. Exit with 1 when the program is given no arguments.
