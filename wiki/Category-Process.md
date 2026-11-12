[Home](Home) › [All Categories](Categories) › **Process**

# Process: Running Other Programs

The `std/process` module starts other programs, passes them arguments without a shell in between, connects to their standard input and output through pipes, and waits for them to finish.

```freebasic
#import "std/process"

dim r as process.ProcResultOutput = process.Capture( process.Command( "git" ).Arg( "status" ).Arg( "--short" ) )
if r.IsOk( ) then
    print r.Value( ).StdoutText( )
else
    print r.Failure( ).Message( )
end if
```

`Output` is a keyword, so the helper is `Capture`. Write `process.Command( … )` qualified even after `using process`: an unqualified `Command( … )` is the built-in `COMMAND` function.

## Commands

A `Command` describes what to run. Every setter returns the `Command`, so calls chain, and a `Command` is an ordinary value: copy it, keep it, run it again.

| Call | Does |
|---|---|
| `process.Command( program )` | the program: a name looked up on `PATH`, or a path |
| `Arg( a )`, `Args( array )` | one argument, or an `Array( of ustring )` of them |
| `Cwd( dir )` | the child's working directory |
| `Env( name, value )`, `EnvRemove( name )` | change one variable for the child only |
| `EnvClear( )` | start the child with an empty environment (then `Env` what it needs) |
| `StdinFrom( s )`, `StdoutTo( s )`, `StderrTo( s )` | `STDIO_INHERIT`, `STDIO_NULL` or `STDIO_PIPE` |
| `StderrToStdout( )` | send the child's stderr wherever its stdout goes (`2>&1`) |
| `NewProcessGroup( )` | put the child in its own process group |
| `HideWindow( )` | on Windows, start a console program without a console window |
| `ToString( )` | the command line, quoted as the system will see it — for logs |

**There is no shell.** Each argument reaches the program exactly as given: spaces, quotes, backslashes, `*`, `$` and `&` are not interpreted. On Windows the arguments are quoted into a command line by the rules the C runtime and `CommandLineToArgvW` use to split it again; on Linux and macOS they are passed as the argument vector.

**Program lookup.** A name without a path separator is searched for on `PATH` — the child's `PATH` if `Env( "PATH", … )` changed it — and on Windows with each `PATHEXT` extension (`.COM`, `.EXE`, `.BAT`, `.CMD`). The current directory is **never** searched, so a program dropped into it cannot stand in for one on `PATH`. A relative path such as `tools/gen` is taken from this program's current directory, whatever `Cwd` says.

**Batch files.** A `.bat` or `.cmd` file runs through `cmd.exe`. `cmd.exe` expands `%NAME%` even inside quotes, so an argument it cannot be given safely — one with `%`, a line break, or a `"` together with one of `& | < > ^ ( )` — is refused with `PROC_UNSAFE_ARGUMENT` instead of being passed on.

## Running To Completion

| Helper | Gives |
|---|---|
| `Run( cmd )` | runs with the child's stdin, stdout and stderr inherited; `ProcResultStatus` |
| `Capture( cmd )` | collects stdout and stderr, stdin is empty; `ProcResultOutput` |
| `Capture( cmd, stdinData )` | the same, with `stdinData` (an `Array( of ubyte )`) fed to the child's stdin |
| `Shell( commandLine )` | the one way to a shell: `cmd.exe /d /s /c` on Windows, `/bin/sh -c` on Linux and macOS |
| `CurrentId( )` | this process's id |

```freebasic
#import "std/process"

dim st as process.ProcResultStatus = process.Run( process.Command( "tiko" ).Arg( "--version" ) )
if st.IsOk( ) then print "exit code"; st.Value( ).Code( )

dim o as process.ProcResultOutput = process.Capture( process.Command( "tiko" ).Arg( "--version" ) )
if o.IsOk( ) then
    print o.Value( ).Stdout.Count( ); " bytes on stdout"
    print o.Value( ).StdoutText( )
end if
```

A `ProcessOutput` holds `Status` (an `ExitStatus`), `Stdout` and `Stderr` (each an `Array( of ubyte )`), and `StdoutText( )` / `StderrText( )`, which decode the bytes as UTF-8 with U+FFFD for anything invalid.

`Capture` reads stdout and stderr **at the same time**, so a program that writes megabytes to both cannot stall waiting for one of them to be read.

An `ExitStatus` has `Code( )`, `Success( )` (`Code( ) = 0`) and, on Linux and macOS, `Signal( )`: the signal that ended the program, with `Code( )` -1 then.

## A Running Child

For anything longer-lived, `Spawn` a `Child` and talk to it while it runs. With `STDIO_PIPE`, `Stdin( )`, `Stdout( )` and `Stderr( )` are `PipeStream`s — [streams](Category-File-Streams) like a file, so `WriteUtf8`, `ReadExact` and `ReadToEnd` all work on them.

```freebasic
#import "std/process"
#import "std/containers"
using containers

dim k as process.Child
dim c as process.Command = process.Command( "sort" )
c.StdinFrom( process.STDIO_PIPE ).StdoutTo( process.STDIO_PIPE )
if k.Spawn( c ).IsOk( ) then
    k.Stdin( ).WriteUtf8( "pear" & chr( 10 ) & "apple" & chr( 10 ) )
    k.Stdin( ).Close( )
    dim got as Array( of ubyte )
    k.Stdout( ).ReadToEnd( got )
    print got.Count( ); " bytes back"
    k.Wait( )
end if
```

| Call | Does |
|---|---|
| `Spawn( cmd )` | starts it; stdio is inherited unless the `Command` says otherwise |
| `Id( )` | its process id |
| `Stdin( )`, `Stdout( )`, `Stderr( )` | the pipe ends — a runtime error if that stream is not `STDIO_PIPE` |
| `Wait( )` | closes our end of its stdin, waits, gives the `ExitStatus`; again gives the same one |
| `WaitTimeout( ms )`, `TryWait( )` | an `Optional( of ExitStatus )`, empty while it is still running |
| `Kill( )` | ends it at once (Windows: exit code 1; Linux and macOS: `SIGKILL`) |
| `Terminate( )` | asks it to stop: `SIGTERM` on Linux and macOS, which a program can catch; the same as `Kill` on Windows |

A `Child` cannot be copied. Destroying one **does not stop the program**: it closes our ends of its pipes and lets it run on. On Linux and macOS a child that is never waited for stays a zombie until this program exits, so `Wait` for every child you start. After `Wait`, `Kill` and `Terminate` fail with `PROC_ALREADY_WAITED`, because the process id may already belong to another program.

On Windows a child started with `NewProcessGroup( )` can be sent Ctrl-Break, and a program using [std/os](Category-OS)'s `CatchInterrupt` sees it as `INT_BREAK`.

## What The Child Gets

- **Only the three standard handles.** On Windows the child receives an explicit list of exactly those, so files and pipes this program has open do not leak into it. On Linux and macOS every pipe is opened close-on-exec; a file opened with the legacy `OPEN` statement is not, and is visible to the child.
- **Default signal handling** on Linux and macOS, whatever this program set.
- **On Linux and macOS the first spawn sets `SIGPIPE` to ignored in this program**, so writing to a pipe whose reader has gone is an `FS_BROKEN_PIPE` error rather than the end of the program.

## Errors

Every failure is a `ProcError`: `Code( )`, `OsCode( )` (the system's own error number, or 0), `Operation( )`, `Subject( )` (the program, argument or directory concerned) and `Message( )` — for example `Spawn 'gti': program not found`. Nothing is started when the `Command` itself is wrong.

| Code | Means |
|---|---|
| `PROC_NOT_FOUND` | no such program on `PATH` or at the path given |
| `PROC_ACCESS_DENIED` | it is there but may not be run |
| `PROC_INVALID_ARGUMENT` | a NUL character anywhere, an empty program name, an `=` in a variable name |
| `PROC_UNSAFE_ARGUMENT` | an argument a batch file cannot be given safely |
| `PROC_BAD_DIRECTORY` | the `Cwd` is not a directory |
| `PROC_TOO_MANY_PROCESSES` | the system refused another process |
| `PROC_NOT_STARTED` | `Wait` or `Kill` on a `Child` that was never spawned |
| `PROC_ALREADY_WAITED` | `Kill` or `Terminate` after `Wait` |
| `PROC_IO` | a pipe failed |
| `PROC_UNKNOWN` | anything else; `OsCode( )` says what |

Reads and writes on a `PipeStream` report an `fs.FsError`, as every stream does.

## See Also

- [OS](Category-OS) — this program's own arguments, environment and interrupts
- [Filesystem Library](Category-Filesystem) — streams, the executable's path
- [Operating System Functions](Category-Operating-System-Functions) — the built-in `SHELL`, `EXEC`, `RUN`
