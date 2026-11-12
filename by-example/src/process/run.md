# Running other programs

A program can start another and wait for it. The example uses itself as the
other program: started with the argument `child`, it does the child's work and
exits with code 7. That way it needs no program that might be missing, and it
runs the same on every platform.

```tiko
{{#include ../../examples/process/run.tiko}}
```

**Output**

```text
{{#include ../../examples/process/run.out}}
```

| Statement | Runs | Returns |
|---|---|---|
| `exec( program, args )` | a program, directly | its exit code |
| `shell( "command" )` | a command line, through the system shell | its exit code |
| `open pipe "command" for input as #f` | a command line, whose output the program reads | a file number to read from |

**`exec`** starts the program with no shell in between, so nothing in the
arguments is interpreted: the safe choice when an argument came from a user.
The child writes to the same output as the parent, which is why its line
appears between the parent's.

**`shell`** hands the command line to `cmd.exe` on Windows and `/bin/sh` on
Linux and macOS, so the line is in that shell's language. `exit 3` happens to mean the
same in both.

**`open pipe ... for input`** also goes through the shell, and reads the
command's output a line at a time, as if it were a file. The quotes around
`command( 0 )` keep a path with spaces in one piece. `open pipe ... for output`
sends lines to a command's input instead.

The child inherits a copy of the parent's environment, including anything set
with [`setenviron`](environment.md) before it was started.

### Activities

1. Make the child read an environment variable that the parent sets just
   before `exec`, and print it.
2. Have the child print three lines and read them all through the pipe with a
   `do until eof( f )` loop.
