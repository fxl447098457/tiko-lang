[Home](Home) › [All Categories](Categories) › **OS**

# OS: Arguments, Environment And Interrupts

The `std/os` module is the program's view of its own process and the machine it runs on: the command-line arguments, the environment, a handful of host facts, a clean exit, and a way to notice Ctrl-C without being killed by it.

```freebasic
#import "std/os"

for each a as ustring in os.Args( )
    print a
next
print os.OS_NAME, os.CpuCount( ), os.Hostname( ).ValueOr( "?" )
```

## Arguments

`os.Args( )` returns an `Array( of ustring )` with the program itself first. Arguments are Unicode on Windows, Linux and macOS, and an empty argument (`""` on the command line) is kept as an empty element.

On Windows the command line is split by the standard Windows rules: double quotes group words, `\"` is a literal quote, and backslashes are literal everywhere else.

## Environment

```freebasic
#import "std/os"
#import "std/outcome"
using outcome

dim v as Optional( of ustring ) = os.GetEnv( "EDITOR" )
if v.HasValue( ) then
    print "editor: "; v.Value( )
else
    print "EDITOR is not set"
end if

os.SetEnv( "APP_MODE", "test" )
print os.ExpandEnv( "mode=$APP_MODE home=${HOME}" )
os.UnsetEnv( "APP_MODE" )
```

| Call | Does |
|---|---|
| `GetEnv( name )` | `Optional( of ustring )`: **empty when the variable is unset**, holding `""` when it is set to nothing |
| `SetEnv( name, value )` | sets it for this process and the programs it starts; `Result( of boolean, OsError )` |
| `UnsetEnv( name )` | removes it; removing one that is not there succeeds |
| `Environment( )` | a sorted snapshot, `OrderedMap( of ustring, ustring )` |
| `ExpandEnv( s )` | `$NAME` and `${NAME}` become the value, or nothing when unset; on Windows `%NAME%` too, left as written when unset |

A name may not be empty or contain `=`; `SetEnv` and `UnsetEnv` fail with `OS_INVALID_ARGUMENT` and `GetEnv` returns an empty `Optional`. Names are case-insensitive on Windows and case-sensitive on Linux and macOS, as each system treats them.

**Set the environment before starting threads.** On Linux and macOS, changing the environment while another thread reads it is not safe.

## Host Facts

| Name | Gives |
|---|---|
| `OS_NAME` | `"windows"`, `"linux"` or `"macos"` (a constant) |
| `ARCH_NAME` | `"x86_64"` (a constant) |
| `OsVersion( )` | `"10.0.26100"` on Windows, the kernel release on Linux and macOS |
| `Hostname( )`, `UserName( )` | `Result( of ustring, OsError )` |
| `ProcessId( )` | this process's id |
| `CpuCount( )` | the processors **this process may run on** — fewer than the machine has under a container limit or an affinity mask |
| `PageSize( )` | the memory page size in bytes |
| `TotalMemory( )` | physical memory in bytes; 0 if it cannot be found |
| `IsTerminal( fd )` | whether 0, 1 or 2 (stdin, stdout, stderr) is an interactive terminal |

Home, config and cache folders are in [std/fs](Category-Filesystem).

## Exit

`os.ExitWith( code )` ends the program the way `end code` does: module destructors run and open files are flushed. `os.Abort( )` ends it at once with no cleanup at all. The trailing underscore is there because `Exit` is a keyword.

## Ctrl-C And Termination

By default Ctrl-C kills a console program on the spot. `CatchInterrupt( )` turns it — and Ctrl-Break, `SIGTERM`, `SIGHUP`, and closing the console window — into a flag the program checks when it is ready to stop:

```freebasic
#import "std/os"

os.CatchInterrupt( )
dim as long n = 0
while os.Interrupted( ) = FALSE andalso n < 50
    ' ... one unit of work ...
    sleep 10
    n += 1
wend
if os.Interrupted( ) then print "stopping cleanly after "; n; " steps"
```

| Call | Does |
|---|---|
| `CatchInterrupt( forceOnSecond = TRUE )` | starts catching; calling it again only changes `forceOnSecond` |
| `Interrupted( )` | whether one has arrived; never blocks |
| `WaitInterrupt( timeoutMs = -1 )` | blocks until one arrives (`TRUE`) or the time is up (`FALSE`); -1 waits for ever |
| `LastInterrupt( )` | `INT_CTRL_C`, `INT_BREAK`, `INT_TERMINATE`, `INT_HANGUP`, or `INT_NONE` |
| `InterruptCount( )` | how many since the last reset |
| `ResetInterrupt( )` | clears the flag and the count |
| `ReleaseInterrupt( )` | gives the signals back to their default handling |

**A second interrupt ends the program with exit code 130**, so a program stuck in a long step can still be stopped. Pass `FALSE` to keep counting instead.

None of your code runs inside the signal handler; it only records what happened. When Windows closes the console, logs the user off or shuts down, the program has about five seconds after the interrupt before Windows ends it regardless.

| Kind | Windows | Linux and macOS |
|---|---|---|
| `INT_CTRL_C` | Ctrl-C | `SIGINT` |
| `INT_BREAK` | Ctrl-Break | — |
| `INT_TERMINATE` | console closed, logoff, shutdown | `SIGTERM` |
| `INT_HANGUP` | — | `SIGHUP` |

### With Goroutines

`tasks.InterruptContext( )` is a [Context](Category-Goroutines-and-Channels) that is cancelled by the first interrupt, so every goroutine that watches a context stops on Ctrl-C with no extra code:

```freebasic
#import "std/tasks"
using tasks

sub Worker( byval ctx as Context, byval wg as WaitGroup ptr )
    while ctx.IsCancelled( ) = FALSE
        sleep 10            ' ... one unit of work ...
    wend
    print "worker: "; ctx.Err( )
    wg->Done( )
end sub

dim ctx as Context = InterruptContext( )
dim wg as WaitGroup
wg.Add( )
spawn Worker( ctx, @wg )
wg.Wait( )                  ' returns once Ctrl-C has stopped the worker
```

It calls `os.CatchInterrupt( )` for you and returns the same context every time. Build with `-mt`, as for everything in `std/tasks`.

## Errors

`SetEnv`, `UnsetEnv`, `Hostname`, `UserName` and `CatchInterrupt` return a `Result` whose failure is an `OsError`: `Code( )` (`OS_INVALID_ARGUMENT`, `OS_NOT_FOUND`, `OS_UNSUPPORTED`, `OS_SYSTEM`), `OsCode( )` (the system's own error number, or 0), `Operation( )`, `Subject( )` and `Message( )` — for example `SetEnv 'A=B': invalid argument`.

## See Also

- [Process](Category-Process) — starting other programs, and sending a child Ctrl-Break
- [Filesystem Library](Category-Filesystem) — home and config folders, the executable's path
- [Goroutines and Channels](Category-Goroutines-and-Channels) — `Context` and cancellation
- [Operating System Functions](Category-Operating-System-Functions) — the built-in `COMMAND`, `ENVIRON`, `SHELL`
