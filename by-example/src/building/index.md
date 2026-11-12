# Building

Every program so far was built the same way: one command, one source file,
one executable. The `tiko` command does much more than that. Its options choose
checks, optimisation and debug information; it compiles files separately and
builds libraries; and for a project with a `tiko.toml` it builds everything the
project declares, remembering what it built before.

A program can see how it was built. With no options at all:

```tiko
{{#include ../../examples/building/defaults.tiko}}
```

**Output**

```text
{{#include ../../examples/building/defaults.out}}
```

That is the default build: no runtime checks, no debug information, no
optimisation, and the ordinary runtime. Each option below changes one of those,
and defines a symbol the program can test.

| Option | Does |
|---|---|
| `-o file` | names the output file, exactly as written; without it, the program is named after the first source file (`app.exe` on Windows, `app` on Linux and macOS) |
| `-c` | compiles to an object file and does not link |
| `-lib` | builds a static library, `libname.a` |
| `-e` | runtime error checks |
| `-exx` | `-e`, plus array-bounds and null-pointer checks, and where each error happened |
| `-g` | debug information for a debugger; also turns `assert` on |
| `-O0` … `-O3` | how hard the optimiser works; `-O0`, none, is the default |
| `-mt` | the thread-safe runtime; `std/tasks` requires it, and a `threadcreate` call turns it on by itself |
| `-target name` | `windows-x86_64`, `linux-x86_64` or `macos-arm64`; the platform you are on is the default |
| `-d NAME=value` | defines a preprocessor symbol |
| `-v` | shows every tool tiko runs |

`tiko --help` lists every option, by category.

The pages that follow put options [in the source](cmdline.md), show what a
[checked build](checked.md) catches, compile [files
separately](separate.md) and [into a library](libraries.md), build
[projects](projects.md) with [profiles](profiles.md), and look at the two
[targets](targets.md).

### Activities

1. Build `defaults.tiko` with `-exx -O2` on the command line and compare the
   output.
2. Build it with `-g` and check which lines change.
