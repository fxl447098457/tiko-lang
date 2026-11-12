# Getting Started {#ch-getting-started}

tiko is a compiled, statically typed language for applications and systems programming. It
produces native executables with no garbage collector, no virtual machine and no runtime for
your users to install: a finished program is one file you can copy to a machine and run.

Under the hood the compiler translates your program to LLVM IR and calls clang to assemble and
link it. That matters for exactly one reason, which this chapter gets out of the way first:
clang has to be on the machine, and tiko is particular about where it looks.

This chapter installs the compiler, builds three small programs, reads a diagnostic, and turns on
the runtime checks you should leave on while you work through the book.

## Installing tiko

A tiko installation is a directory. Unpack it wherever you like; nothing is written to the
registry, no environment variable has to be set, and nothing else on the machine is touched.
Moving the directory later is fine — the compiler finds its own headers and libraries relative to
the executable.

```admonish info title="On Windows"
The compiler is `tiko.exe` at the root. Beside it, `inc\` holds the headers and
`lib\windows-x86_64` the libraries.
```

```admonish info title="On Linux"
The compiler is `bin/tiko`, with headers under `inc/` and libraries in `lib/linux-x86_64`.
```

````admonish info title="On macOS"
The compiler is `bin/tiko`, with headers under `inc/` and libraries in `lib/macos-arm64`. It runs
on Apple Silicon Macs with macOS 13 or newer.

A browser marks what it downloads, and macOS then refuses the unsigned compiler: it hangs instead
of running. Clear the mark once, right after unpacking:

```bash
xattr -dr com.apple.quarantine tiko-macos
```
````

Check that it runs:

```bash
tiko --version
```

It prints the compiler's version and the target it builds for by default. Keep that version
handy: this book was written against one specific release, and the exact one is named in the
preface.

## The one thing you must install: clang

tiko contains no assembler and no linker. It emits LLVM IR, then runs `clang` to turn that into
an object file and `lld` to link it. **You need LLVM 18 or newer installed**, and it is not
bundled.

On Windows, install the LLVM package; on Linux, your distribution's `clang` package; on macOS,
Homebrew's (`brew install llvm`), together with Xcode's Command Line Tools
(`xcode-select --install`), which hold the SDK and the linker every macOS link uses. Then check:

```bash
clang --version
```

If clang is installed in the usual place, there is nothing to configure. tiko looks for it in
four places, and takes the first that exists:

| | Where | Why it comes first |
|---|---|---|
| 1 | The path you pass on the command line | Someone who names a compiler has a reason, and it is never second-guessed |
| 2 | The `TIKO_CLANG` environment variable | Settles it for a whole shell or a CI job |
| 3 | The conventional install: `C:\Program Files\LLVM\bin\clang.exe`, `/usr/bin/clang`, or Homebrew's `/opt/homebrew/opt/llvm/bin/clang` on macOS | See the pitfall below |
| 4 | `PATH` | Catches a portable LLVM, a scoop install, or anything under `/usr/local` |

So a clang on `PATH` is found — but only when there is no clang at the conventional location.

````admonish danger title="Pitfall"
**The conventional install outranks `PATH` deliberately**, and it is worth knowing which clang you
are actually getting. On Windows the `clang` on `PATH` is as often a stale copy belonging to some
other toolchain as it is the one you meant, and a backend that quietly used a different clang from
the one its data layout was measured against produces the kind of failure that takes days to find.

If you have several, name the one you want rather than reordering `PATH`:

```bash
export TIKO_CLANG=/home/you/.local/bin/clang
```

`llvm-ar`, `llvm-rc` and libclang are then taken from that same directory, never searched for
separately — so one setting settles all of them. When no clang is found at all you get diagnostic
`TKO0111`, "no usable toolchain", and the process exits with status 3.
````

## Hello, tiko

Source files are `.tiko`, and the headers you write yourself are `.ti`. Here is the whole program:

```tiko
{{#include ../examples/ch01/hello.tiko}}
```

**Output**

```text
{{#include ../examples/ch01/hello.out}}
```

Compile and run it:

```bash
tiko hello.tiko -o hello
./hello
```

`-o` names the output. Without it, the executable takes the source file's name. Two other options
are worth knowing on day one: `-c` compiles to an object file without linking, and `-v` echoes
every clang and linker command tiko runs, which is the quickest way to see what a build actually
did.

When a build finishes, the exit status tells you what happened, which matters as soon as you put
tiko in a script:

| Status | Meaning |
|---|---|
| 0 | success |
| 1 | errors in your program |
| 2 | a bad command line |
| 3 | no usable toolchain — usually clang |
| 4 | an internal compiler error |
| 5 | clang or the linker failed |

Status 4 is a bug in the compiler. It is worth reporting, with the source that caused it.

### Reading the command line

Programs get their arguments through `command`, which returns one argument by position, counting
from 1:

```tiko
{{#include ../examples/ch01/greet.tiko}}
```

```bash
./greet tiko
hello, tiko
```

Two things in those four lines are worth naming now, because every later chapter assumes them.

**`ustring` is the string type.** It holds UTF-16 text, its length is O(1), and it behaves the
same on every platform. Chapter 9 covers text properly, including the older `string` type that
holds bytes and the two cases where you still want it.

**Types say their width.** `int32`, `int64`, `float64` and their siblings mean what they say on
every target — no guessing whether `int` is 32 or 64 bits today. Chapter 4 lists all ten, plus
`integer`, the pointer-sized type that deliberately has no fixed-width name.

## Choosing a target

tiko builds for three targets, and the default is the machine you are on.

| Target | What it is | Default on |
|---|---|---|
| `windows-x86_64` | Microsoft's ABI, linked against `ucrtbase.dll` | Windows |
| `linux-x86_64` | The System V ABI, linked against the system's C library | Linux |
| `macos-arm64` | Apple's arm64 ABI, linked by Apple's linker against the macOS SDK | macOS |

Name one explicitly with `-target`:

```bash
tiko hello.tiko -target windows-x86_64 -o hello
```

Targets are not interchangeable at link time: an object file or static library built for one will
not link into a program for the other. Chapter 31 covers what each target links and
how to ship the result.

## Reading a diagnostic

Every message tiko prints carries a stable identifier: `TKO` followed by four digits. The number
never changes meaning and is never reused, so it is worth searching for, and worth quoting in a
bug report. Appendix B lists them all.

This program has a type error:

```tiko
{{#include ../examples/ch01/oops.tiko}}
```

Compiling it says so:

```
oops.tiko(3,1): error TKO0702: a string and a number do not convert into each other
     |
   3 | count = "seven"
     | ^
```

The parts are the file, the line and column, the severity, the identifier, the message, and then
the offending line with a caret under the position. Five options shape this output:

| Option | Effect |
|---|---|
| `--diagnostics-format gnu` | `file:line:col: error: message [TKO0702]`, the shape most editors and CI tools expect |
| `--color always` / `never` | Force colour on or off, rather than deciding by whether output is a terminal |
| `-Wno-TKO0830` | Silence one warning, by identifier |
| `-Werror` | Treat every warning as an error |
| `-fmax-errors 1` | Stop after the first error, instead of listing everything |

## Turn the checks on now

By default, a tiko program does no bounds checking. Reading past the end of an array is
undefined: usually it quietly returns nonsense, occasionally it corrupts something, and it always
wastes an afternoon.

`-exx` turns on array-bounds and null-pointer checking, and the cost is irrelevant while you are
learning. **Use it for everything in this book.**

A program can carry its own build options, which is how the listings in this book stay
self-contained — the first source file may hold a `#cmdline` line, and the compiler restarts
itself with those options applied:

```tiko
{{#include ../examples/ch01/bounds.tiko}}
```

Running it stops at the bad index rather than carrying on with a corrupted array:

```text
{{#include ../examples/ch01/bounds.out}}
```

The process exits with status 6. Without `-exx` the same program writes 42 somewhere it should
not and prints `not reached`, which is the outcome the check exists to prevent.

The check covers every array, including the ones that grow while the program runs, which Chapter 8
introduces. The null-pointer check is partial: it catches `*p`, but not yet `p->field` or `p[i]`,
which Chapter 11 covers.

There are three levels, and they stack: `-e` enables error checking, `-ex` adds to it, and `-exx`
adds array bounds and null-pointer checks on top. Chapter 18 comes back to them alongside the
error-handling model.

## An editor

None of this book requires a particular editor; every example is a file and a command line. But
two tools come with tiko, and both are worth the five minutes:

- **tkEdit** is the editor in the `tiko-lang` folder. It builds and runs your program with one key,
  lists the compiler's errors and takes you to each one, and shows a procedure's parameters as you
  type its call.
- **tiko-lsp** is tiko's language server. It gives the editor you already use — VS Code, Zed,
  Neovim, Sublime Text and others — errors as you type, completion, go to definition, rename and
  formatting.

Chapter 2 sets up both.

## Looking things up

The reference for everything this book does not spell out — every keyword's full syntax, every
compiler option, every function in the standard library — is the **tiko wiki**, at
[github.com/PaulSquires/tiko-lang/wiki](https://github.com/PaulSquires/tiko-lang/wiki). Two pages
answer most questions: the
[Feature Index](https://github.com/PaulSquires/tiko-lang/wiki/Feature-Index), one line per
language feature and library, and the
[Function Finder](https://github.com/PaulSquires/tiko-lang/wiki/Function-Finder), every function
grouped by the job it does. The wiki's
[Quick Start](https://github.com/PaulSquires/tiko-lang/wiki/Quick-Start) covers building a
toolchain from source, which this chapter does not.

## Summary

- A tiko installation is a directory you unpack anywhere; the compiler locates its own headers and
  libraries.
- **LLVM 18+ must be installed.** tiko finds clang in four places, in order: an explicit path,
  `TIKO_CLANG`, the conventional install location, then `PATH`.
- Source files are `.tiko`; headers you write are `.ti`.
- `tiko hello.tiko -o hello` compiles and links in one step; `-c` stops at the object file and `-v`
  shows every command.
- Three targets: `windows-x86_64` (the Windows default, and no Visual Studio needed),
  `linux-x86_64` (the Linux default) and `macos-arm64` (the macOS default). Objects from different
  targets do not link together.
- Diagnostics carry stable `TKOnnnn` identifiers; `--diagnostics-format gnu` suits tools, and
  `-Werror` suits discipline.
- Build with `-exx` while you learn, and let a listing carry its own options with `#cmdline`.
- `ustring` is the string type, and numeric types say their width: `int32`, `int64`, `float64`.
- The reference for every keyword, option and function is the tiko wiki; start from its Feature
  Index or Function Finder.

## Exercises

1. Write a program that reports which compiler built it and which version that compiler is.
   `__TIKO_COMPILER__` is defined by tiko and by nothing else, and `__TIKO_VERSION__` holds the
   version as a string. Test the first with `#ifdef`. {solution="ex01-01"}
2. Make a program greet you by name and then exit with status 3, and check the status from your
   shell (`echo $?`, or `echo %ERRORLEVEL%` in `cmd`). {solution="ex01-02"}
3. Call a procedure that was never declared, and note the identifier of the diagnostic. Then look
   it up in Appendix B. {solution="ex01-03"}
4. Compile `bounds.tiko` again with the `#cmdline` line deleted, and run it. What does it print,
   and what is its exit status? That is the difference `-exx` makes.
