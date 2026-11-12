# The os module

`command` and `environ` are built in and short, but each loses something. An
empty argument looks like the end of the list, and a variable that is not set
reads the same as one set to nothing. `std/os` keeps both apart.

```tiko
{{#include ../../examples/process/os.tiko}}
```

Run as `os first "" "third one"`:

**Output**

```text
{{#include ../../examples/process/os.out}}
```

| Call | Gives |
|---|---|
| `os.Args( )` | every argument in an `Array( of ustring )`, the program first |
| `os.GetEnv( name )` | an `Optional( of ustring )`, empty when not set |
| `os.SetEnv( name, value )` | sets it; a `Result` that fails on a name with `=` |
| `os.UnsetEnv( name )` | removes it |
| `os.Environment( )` | every variable, sorted, in an `OrderedMap` |
| `os.ExpandEnv( text )` | `$NAME` and `${NAME}` replaced; `%NAME%` too on Windows |

`GetEnv( ... ).ValueOr( "info" )` is the usual way to give a setting a default.
A variable that is not set expands to nothing, as in a shell.

The module also knows about the machine: `os.OS_NAME` and `os.ARCH_NAME`,
`OsVersion( )`, `Hostname( )`, `UserName( )`, `ProcessId( )`, `PageSize( )`,
`TotalMemory( )`, `IsTerminal( fd )`, and `CpuCount( )` — the processors this
program may use, which is fewer than the machine has inside a container. The
example prints only facts that are the same everywhere.

```admonish info title="Threads"
Set the environment before starting threads. On Linux and macOS, changing a variable
while another thread reads the environment is not safe.
```

### Activities

1. Set `BYEXAMPLE_LEVEL` in your shell and run the program again.
2. Print `os.CpuCount( )` and compare it with what your system monitor says.
