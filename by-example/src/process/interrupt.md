# Ctrl-C

Pressing Ctrl-C normally ends a console program wherever it happens to be. A
program that is halfway through writing a file would rather finish the record
it is on. `os.CatchInterrupt( )` turns Ctrl-C into a flag the program checks.

```tiko
{{#include ../../examples/process/interrupt.tiko}}
```

**Output**, when nobody presses a key:

```text
{{#include ../../examples/process/interrupt.out}}
```

Press Ctrl-C while it runs and the loop stops at the next check, prints how
many records it saved and `interrupted by kind 1`, and exits with 130 — the
code a shell shows for a program stopped by Ctrl-C.

| Call | Does |
|---|---|
| `os.CatchInterrupt( )` | start catching Ctrl-C, Ctrl-Break and termination requests |
| `os.Interrupted( )` | has one arrived? never waits |
| `os.WaitInterrupt( ms )` | wait for one, at most `ms` milliseconds; -1 for ever |
| `os.LastInterrupt( )` | `INT_CTRL_C` (1), `INT_BREAK` (2), `INT_TERMINATE` (3), `INT_HANGUP` (4) |
| `os.ResetInterrupt( )` | clear the flag |
| `os.ReleaseInterrupt( )` | let Ctrl-C end the program again |

**A second Ctrl-C ends the program at once**, with code 130, so a program that
is stuck in a long step can still be stopped. `os.CatchInterrupt( false )`
keeps counting instead.

`INT_TERMINATE` is `SIGTERM` on Linux and macOS — what a service manager sends to stop a
program — and on Windows the console window closing, the user logging off or
the machine shutting down. Windows then allows about five seconds before it
ends the program regardless.

With goroutines, `tasks.InterruptContext( )` is a
[context](../concurrency/cancellation.md) that Ctrl-C cancels, so every
goroutine watching it stops too.

`os.ExitWith( code )` is `end code` as a procedure call. `os.Abort( )` ends the
program at once, without running destructors or flushing files.

### Activities

1. Run the program and press Ctrl-C before it finishes.
2. Pass `false` to `CatchInterrupt` and press Ctrl-C three times. What does
   `os.InterruptCount( )` say?
