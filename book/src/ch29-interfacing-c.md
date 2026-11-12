# Interfacing with C

Most of the code a program could use is written in C: the operating system's own interfaces, the
C runtime, compression, databases, graphics, cryptography. tiko calls C directly, with no wrapper
layer between: a C function is declared, and called like any other. This chapter covers
declaring C functions by hand and having the compiler read a C header instead, matching C's
types and layouts, passing strings and callbacks across, calling conventions, linking a library
— including one shipped inside the project's own tree — and loading one while the program runs.

Every listing here runs on every target. Several print different answers on each, and those
differences are the point.

## Declaring a C function

```tiko
{{#include ../examples/ch29/declare.tiko}}
```

```text
{{#include ../examples/ch29/declare.out}}
```

A C function is declared with `declare`, like a tiko one, plus three things C needs:

- **`cdecl`**: C's calling convention. On x86-64 every convention is the same, but saying `cdecl`
  keeps the declaration honest and matches what the C header says.
- **`alias "name"`**: the exact name the linker looks for. tiko's names are case-insensitive and
  C's are not, so `alias` fixes the spelling, and it also lets the tiko name differ: `CLength`
  above is C's `strlen`.
- **`lib "name"`** (optional): the library the function lives in, which is then linked. The C
  runtime is always linked, so the listing names none.

**`extern "C"` … `end extern`** declares a block at once. Everything inside is `cdecl`, and every
name keeps the exact spelling it was written with, so `toupper` links to C's `toupper` with no
`alias`. Inside the block, `alias` still renames: `abs_` is C's `abs`, renamed because `abs` is a
tiko function already. `extern "C" lib "name"` names a library for the whole block.

A declaration is a promise the compiler cannot check: it believes every parameter type and the
result type, and a mistake shows up when the program runs, not when it compiles. Copy the types
from the C header carefully, which is the first thing the next section is about — or let the
compiler read the header itself, which is the section after it.

## Matching C's types

```tiko
{{#include ../examples/ch29/ctypes.tiko}}
```

On Windows:

```text
{{#include ../examples/ch29/ctypes.out}}
```

On Linux:

```text
{{#include ../examples/ch29/ctypes.linux-x86_64.out}}
```

On macOS:

```text
{{#include ../examples/ch29/ctypes.macos-arm64.out}}
```

Most C types have one tiko equivalent on every platform:

| C | tiko |
|---|---|
| `char`, `signed char`, `unsigned char` | `byte` / `ubyte` |
| `short`, `unsigned short` | `int16` / `uint16` |
| `int`, `unsigned int` | `int32` / `uint32` |
| `long long`, `unsigned long long` | `int64` / `uint64` |
| `float`, `double` | `float32` / `float64` |
| `size_t`, `intptr_t` | `uinteger` / `integer`, or `size_t` from `crt/stddef.bi` |
| `T *` | `T ptr`; `void *` is `any ptr` |
| `const char *` | `const zstring ptr` |
| a function pointer | a `type` alias for a `function cdecl( … )` or `sub cdecl( … )` |

Two do not:

- **C's `long` is 4 bytes on Windows and 8 on Linux and macOS.** Use `clong` and `culong` from
  `crt/long.bi`, which follow the platform. Writing `int32` for a `long` works on Windows and
  breaks everywhere else.
- **`wchar_t` is 2 bytes on Windows (UTF-16) and 4 on Linux and macOS (UTF-32).** tiko's
  `wstring` follows the same rule, so a `wstring ptr` is a `wchar_t *` everywhere.

```admonish danger title="Pitfall"
**`long` is not `int32`.** A C function returning `long` declared `as int32` loses the top half of
every value on Linux and macOS, and nothing complains — the Windows build, where the two agree, works. The
solution to exercise 2 uses `strtol`, which returns `long`, for that reason.
```

`__FB_MSVC__` is defined when the program is built against Microsoft's C runtime — the default
on Windows, the `windows-x86_64` target. `__FB_WIN32__`, `__FB_LINUX__` and `__FB_DARWIN__` name the platform. The
`crt/` headers (`crt/string.bi`, `crt/stdlib.bi`, `crt/math.bi` and the rest, or all of them at
once through `crt.bi`) declare the C runtime by hand, ready to use.

### Structs and their layout

```tiko
{{#include ../examples/ch29/layout.tiko}}
```

```text
{{#include ../examples/ch29/layout.out}}
```

A `type` lays its fields out the way C lays out a `struct` on the same platform: each field on a
boundary of its own size, with padding between where needed, and the whole rounded up to its
largest alignment. So a `type` with the same fields in the same order as a C struct has the same
size and the same offsets, and a pointer to one can be handed to C.

`field = 1` packs a type with no padding, as C's `#pragma pack(1)` does; `field = 2` and
`field = 4` limit the alignment the same way. Use them only to match a C struct that is packed —
a packed type is slower to use, and an unpacked C struct read through a packed type is garbage.
A fixed-size `zstring * n` is an inline array of `n` characters, like C's `char name[n]`; a
`ustring` field is not, since it holds a pointer to the text, and never belongs in a struct C
will read. `offsetof( T, field )` checks an offset against the C header.

### Strings across the boundary

```tiko
{{#include ../examples/ch29/cstrings.tiko}}
```

```text
{{#include ../examples/ch29/cstrings.out}}
```

C's strings are bytes ending in a zero byte, and that is how a tiko `string` and a `zstring` are
stored. **Into C**: `strptr( s )` is a pointer to a `string`'s own bytes, valid until the string
next changes; `@z` does the same for a `zstring`. **Out of C**: a `zstring ptr` points at C's
memory, and `*p` reads the characters into a tiko string, which copies them. Copy at once; C may
reuse or free that memory.

**Memory C allocates, C must free.** The listing copies into memory from `malloc` and then reads
it into a `ustring` — a copy — before `free`. A pointer from a C library comes with rules about
who frees it, and the library's documentation says which; the C runtime's `free` is right only for
memory from the C runtime's `malloc`.

A `ustring` holds UTF-8, so `*p` from a C function that returns UTF-8 gives the right text. A C
interface that takes `wchar_t *` takes a `wstring ptr` on every platform; on Windows that is
UTF-16, which is what the `W` functions of the Windows API expect.

## Callbacks

```tiko
{{#include ../examples/ch29/callbacks.tiko}}
```

```text
{{#include ../examples/ch29/callbacks.out}}
```

A C function that takes a function pointer calls back into the program: `qsort` calls its
comparison function once per comparison. A tiko procedure can be the callback if it is
**`cdecl`** and takes exactly the parameters C passes, with the right types. `@Ascending` is its
address.

A **lambda that captures nothing** (Chapter 21) is an ordinary function, so it converts to a
function pointer and can be passed straight to C, as the second call does. A lambda that captures
variables cannot: it carries the captured values with it, and C has nowhere to put them.

C's way to pass state into a callback is the extra `void *` parameter that most callback APIs
have — `user`, `context` or `arg`. The program passes a pointer to its own data, and the callback
casts it back. The geom listings below use one to count visits.

## Variadic functions

```tiko
{{#include ../examples/ch29/variadic.tiko}}
```

On Windows:

```text
{{#include ../examples/ch29/variadic.out}}
```

On Linux the last line is:

```text
cva_list is 24 bytes
```

A **variadic** C function, like `printf` and `snprintf`, is declared with its fixed parameters
followed by `...`. The arguments after the fixed ones are passed by C's rules: integers as at
least an `int`, `float32` as a `float64`. Nothing checks them against the format string, so a `%d`
given a `float64` prints nonsense.

A tiko procedure can be variadic too, for C to call or for tiko's own use: declare it `cdecl` with
`...`, then walk the arguments with a **`cva_list`**: `cva_start( list, last )` starts after the
last fixed parameter, `cva_arg( list, T )` takes the next one as type `T`, and `cva_end( list )`
finishes. Nothing says how many arguments there are or what types they have; the fixed
parameters must, as `count` does here and the format string does for `printf`.

A `cva_list` is 8 bytes on Windows and macOS (a pointer) and 24 on Linux (a small record), so it is not
something to store or pass by value across platforms. Pass it to C's `v` functions — `vsnprintf`
and the rest — which take a `va_list`.

`sizeof( cva_list )` names the type directly and gives the same 8 and 24.

## Calling conventions and names

On 32-bit x86, C had several calling conventions — `cdecl`, `stdcall`, `pascal`, `fastcall` and
`thiscall` — that differed in which side cleaned up the stack and in what order the arguments
went. x86-64 has **one** per platform: Microsoft's on Windows and the System V convention on
Linux. Apple's arm64, tiko's macOS target, has one too. So `cdecl` and `stdcall` mean the same thing and can be used
interchangeably; a Windows header's `WINAPI` (which is `stdcall`) and a plain `cdecl` describe
the same call.

The exception is **`pascal`**, which passes its arguments in reverse order on every platform.
Assigning a `pascal` procedure to a `cdecl` function pointer is warning `TKO0830`, because called
through the pointer, its arguments arrive backwards.

Each convention also decides the **name** the linker sees:

```tiko
{{#include ../examples/ch29/mangle.tiko}}
```

```text
{{#include ../examples/ch29/mangle.out}}
```

`tiko --dump-mangle mangle.tiko` prints the symbol each procedure becomes, the same on both
targets:

```text
PLAIN
c_style
_ZN3geo9cpp_styleEi
```

A plain procedure's symbol is its name in capitals, because tiko's names are case-insensitive.
Inside `extern "C"` the name is kept exactly as written, which is what a C library expects to
find. Inside **`extern "C++"`** it is *mangled* the way a C++ compiler would, with the namespace
and the parameter types folded into the symbol, so a tiko declaration can link to a C++ function
that is not `extern "C"`: `geo::cpp_style( int )` is `_ZN3geo9cpp_styleEi`. Only functions link
this way; C++ classes, templates and exceptions do not cross. `--dump-mangle` is the way to find
out why a link fails with an unresolved symbol: compare its spelling with what the library
exports.

## Linking

A declaration says a function exists; the linker needs the library that contains it. There are
three ways to name one:

- **`#inclib "name"`** in the source links the library `name`: `libname.a` or `libname.so` on
  Linux, `libname.a` or `libname.dylib` on macOS, `name.lib` on Windows. `#libpath "dir"` adds a directory to search.
- **`-l name`** and **`-p dir`** on the command line do the same from outside.
- **`lib "name"`** on a declaration, or on an `extern` block, links the library too, as if
  `#inclib` had been written.

The linker searches the directories from `-p` and `#libpath` first, in the order given, then the
toolchain's own library directory, and **the current directory last**, so a stray library there
cannot replace the runtime that was shipped with the compiler. `#libpath` directories are relative
to where the compiler runs, not to the source file — which is what the next section fixes.

### A library inside the project: #foreignlib

```tiko
{{#include ../examples/ch29/geom-hand.tiko}}
```

```text
{{#include ../examples/ch29/geom-hand.out}}
```

`geom` is a small C library that ships with this chapter: `geom.h` and `geom.c`, a `build.sh`
that builds it, and one prebuilt static library per platform:

```text
geom/geom.h
geom/geom.c
geom/build.sh
geom/geom_windows_x86_64.lib
geom/geom_linux_x86_64.a
geom/geom_macos_arm64.a
```

**`#foreignlib GEOM static "geom/geom"`** binds the name `GEOM` to that library. Three things set
it apart from `#inclib`:

- **The path is relative to the file the directive is in**, not to wherever the compiler is run.
  A binding can sit in a subdirectory of a project, with its libraries beside it, and work from
  any working directory.
- **The platform picks the file.** The compiler adds the target to the name, most specific
  first: `geom_windows_x86_64`, `geom_windows`, `geom_x86_64`, then plain `geom`, each with the
  platform's extensions. One directive serves every platform the project ships libraries for, with
  no `#ifdef`.
- **`static` or `dynamic` must be said**, and limits which files can match: `.a` and `.lib` for
  static; `.so`, `.dll`, `.dll.a` and `.lib` for dynamic. On Windows a `.lib` can be either kind —
  a static library or the import library of a DLL — so it matches both.

The bound name then goes where a library name would: `extern "C" lib GEOM`. A `#foreignlib`
library is linked whether or not anything names it, as `#inclib`'s is.

A spec beginning **`system:`** names an installed library instead of a file: `"system:m"` links
the maths library on Linux and macOS, exactly as `#inclib "m"` would, and its `static` or `dynamic` is not
checked.

When nothing matches, the error lists every file that was tried. On Windows:

```tiko
{{#include ../examples/ch29/nolib.tiko}}
```

```text
nolib.tiko(3,1): error TKO0329: #foreignlib found no matching library
file: SHAPES static geom/shapes; tried:
    geom/shapes_windows_x86_64.a
    geom/shapes_windows_x86_64.lib
    geom/shapes_windows.a
    geom/shapes_windows.lib
    geom/shapes_x86_64.a
    geom/shapes_x86_64.lib
    geom/shapes.a
    geom/shapes.lib
```

(The first line is one line; it is broken here to fit the page.)

The other `#foreignlib` errors are about the directive itself: `TKO0327` and `TKO0328` when the
name, `static`/`dynamic` or the quoted spec is missing, and `TKO0330` when one name is bound twice
to different libraries.

The geom listing passes a `geom_point` **by value** to `geom_distance`. That works because the
`type` has C's layout, and tiko passes it by the platform's rules for a 16-byte struct — by hidden
reference on Windows, in two floating-point registers on Linux and macOS — exactly as a C compiler would.

## Reading the C header: #cinclude

```tiko
{{#include ../examples/ch29/geom-cinclude.tiko}}
```

```text
{{#include ../examples/ch29/geom-cinclude.out}}
```

Writing a binding by hand means copying every type and declaration out of the header, and
getting each one right. **`#cinclude`** reads the header itself: it hands `geom.h` to **clang**,
the C compiler, and turns what clang reports into tiko declarations, for the platform being
built. The listing has no `type`, no `declare` and no `extern`: `geom_point`, `geom_visit`, all
four functions and the constant `GEOM_VERSION_MAJOR` come from the header. `#foreignlib` still
does the linking; the two do separate jobs.

What comes across: structs and unions, enums, `typedef`s, functions (variadic ones included),
function pointer types, global variables, and `#define`s that are constants. What does not: macros
with parameters, which are C code rather than declarations; C++ headers; and `NULL`, which is `0` —
write `nullptr`. Every name keeps its C spelling through `alias`, and a name that would collide with
a tiko keyword gets an underscore — `out` becomes `out_`.

**The layout is checked, not trusted.** The importer writes tiko declarations and lets tiko lay
out each struct, then compares every size, alignment and field offset against clang's. A struct
whose layout disagrees is left out rather than imported wrong.

A quoted header is looked for in two places: first under the directory the compiler runs in, then
beside the file that says `#cinclude`. So this listing compiles from any directory, as
`#foreignlib`'s path does. A header that includes others with angle brackets, as in
`#include <lib/other.h>`, is a different matter: clang looks for those only in the directories
given with `-cinclude`, and in the system's own.

```admonish danger title="Pitfall"
**A header under the working directory wins over the one beside the file.** If the directory you
compile from happens to hold a `geom/geom.h` of its own, an older copy or another library's, that
is the header `#cinclude` imports, and nothing says so. `#include` searches the other way round,
beside the file first. Keep a vendored header's path specific to its library.
```

`#cinclude` needs **libclang**, which comes with the LLVM installation tiko already uses; a program
without `#cinclude` never loads it. The result is cached, so a large header such as `windows.h`
is slow the first time and quick after.

### Steering the importer

The importer takes options of its own, each passed to clang:

| Option | Does |
|---|---|
| `-cinclude dir` | adds a directory clang searches for headers (C's `-I`) |
| `-cdefine name[=value]` | defines a C macro before the header is read (C's `-D`) |
| `-csysroot dir` | the root of the C headers and libraries for the target |
| `-copt arg` | passes any other argument to clang unchanged |
| `-cnomacros` | leaves `#define` constants out |
| `-cnoverify` | skips the layout check — there is no good reason to |
| `-cnocache`, `-ccachedir dir` | skip the cache, or keep it somewhere else |

To see what `#cinclude` would produce, **`-cimport header -cimport-out file`** writes the binding
as a file instead (`-` for the screen), and `-cimport-manifest file` adds clang's layout of every
struct. For `geom.h` it writes an `extern "C"` block holding the struct —

```text
type geom_point
	x as double
	y as double
end type
```

— a `type geom_visit as sub cdecl( … )` for the callback, one `declare … cdecl alias "…"` per
function, and `const GEOM_VERSION_MAJOR = 1`. They are the declarations `geom-hand.tiko` wrote by
hand. A generated binding can be kept in the project and compared with the next version of the
header, which shows exactly what the library changed.

On Windows, `#define UNICODE` before `#cinclude once "windows.h"` makes the unsuffixed Windows
names such as `MessageBox` mean the `W` (UTF-16) functions; without it they mean the `A` ones.
Both suffixed forms are always there.

## Loading a library at run time

```tiko
{{#include ../examples/ch29/dylib.tiko}}
```

```text
{{#include ../examples/ch29/dylib.out}}
```

A library linked at build time must be present for the program to start. **`dylibload( name )`**
opens a shared library while the program runs and returns a handle, or `nullptr` if it cannot. A
program can then decide what to do when a plugin or an optional library is missing.
**`dylibsymbol( handle, "name" )`** finds a function or variable by name and returns its address,
or `nullptr`; assigning it to a function pointer of the right type makes it callable.
**`dylibfree`** closes the library, after which every address taken from it is invalid.

The names differ by platform: `name.dll` on Windows, `libname.so` (often with a version, as in
`libm.so.6`) on Linux, `libname.dylib` on macOS. The listing loads the C runtime's maths library
on each — `ucrtbase.dll`, `libm.so.6` and `libm.dylib` — and calls its `cos`.

`dylibsymbol` returns an untyped address, so the function pointer's type is a promise exactly as a
`declare` is. Nothing checks it. A plugin system typically agrees on one entry point with a fixed
signature, looks that up, and receives everything else from it.

A tiko program can be the library: `tiko -dll plugin.tiko` builds a DLL or shared object, and
`tiko -lib` a static library, whose procedures C or another tiko program can call.

## What it costs

- **A call to C costs what a call to tiko costs.** There is no wrapper and no conversion: the
  arguments go in registers and on the stack exactly as C would put them.
- **Strings are copied when they come back.** `*p` copies C's characters into a tiko string.
  `strptr` going in copies nothing.
- **`#cinclude` costs compile time on the first build**, seconds for a large header, and almost
  nothing after, from the cache.
- **`dylibload` and `dylibsymbol` cost a search at run time.** Look a symbol up once and keep
  the pointer.

## Summary

- `declare … cdecl alias "name"`, or an `extern "C"` … `end extern` block, declares a C
  function. `lib "name"` links its library.
- `int` is `int32`, `long long` is `int64`, `double` is `float64`. **C's `long` is `clong`**: 4
  bytes on Windows, 8 on Linux and macOS. `wchar_t` is 2 bytes on Windows, 4 on Linux and macOS, like `wstring`.
- A `type` has C's struct layout; `field = n` packs it. A `ustring` never belongs in a struct C
  reads.
- `strptr` passes a string's bytes to C; `*p` copies C's back. Memory C allocates, C frees.
- A callback is a `cdecl` procedure, or a lambda that captures nothing.
- `...` declares a variadic C function; `cva_list`, `cva_start`, `cva_arg`, `cva_end` write one.
- x86-64 has one calling convention per platform; `pascal` alone reverses its arguments.
  `extern "C++"` mangles names as C++ does; `--dump-mangle` shows them.
- `#inclib`, `#libpath`, `-l`, `-p` link installed libraries. `#foreignlib name static|dynamic
  "path"` links one inside the project, relative to the declaring file, picked per platform.
- `#cinclude "header.h"` turns a C header into declarations through clang, layout-checked; the
  header is found under the working directory, then beside the file, then in `-cinclude`
  directories.
- `dylibload`, `dylibsymbol` and `dylibfree` load a library while the program runs.

## Exercises

1. Bind C's `bsearch` and use it to look values up in a sorted array, with a `cdecl` comparison
   function. {solution="ex29-01"}
2. Bind `strtol`, using its end pointer to read every number at the start of a string and report
   where the numbers stopped. Use the right type for C's `long`. {solution="ex29-02"}
3. Add a function `geom_area` to `geom.c` that returns the area of a polygon, rebuild the
   library with `build.sh`, and call it through `#cinclude`. What did you have to change on the
   tiko side?
4. Rewrite `callbacks.tiko` so the comparison sorts by distance from a point chosen at run time.
   Why can the comparison not be a capturing lambda, and how does the `user` pointer of
   `geom_each` solve the same problem?
5. Build a tiko procedure into a DLL or shared object with `-dll`, and load it from another
   program with `dylibload`.
