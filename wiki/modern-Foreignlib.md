[Home](Home) › [Foreign Library Linking](Category-Foreign-Library-Linking) › **#foreignlib**

# #foreignlib

> 📘 **Also in this category:** [#foreignlib Tutorial](modern-Foreignlib-tutorial), the step-by-step introduction

Preprocessor directive

## Syntax

```freebasic
#foreignlib name (static|dynamic) "spec" [, "spec" ...]
```

## Description

Binds `name` to a set of libraries and adds them to the link.

Unlike [`#inclib`](Inclib), a spec that does not start with `system:` is a library **file**, found **relative to the source file containing the directive**, not to the directory the compiler runs in. The file for the target being built is chosen by a naming convention, and whether the library is linked statically or dynamically must be stated.

The bound name may also be used in a [`Lib`](Lib) clause of a hand-written declaration.

## Parameters

| | |
|---|---|
| `name` | An identifier. Visible to the end of the compilation, including in files that include this one. |
| `static` / `dynamic` | Required. Decides which file endings are eligible. A file of the other kind is never used as a fallback. |
| `"spec"` | `"system:foo"` hands `foo` to the linker to find, as `#inclib "foo"` does. Anything else is a library path without its ending: relative to this file, or absolute. |

Several specs are linked in the order given. This is how a static library brings the system libraries it needs:

```freebasic
#foreignlib RAYLIB static "vendor/raylib/raylib", _
    "system:winmm", "system:gdi32", "system:user32", "system:shell32"
```

## Resolution

For a file spec `"dir/base"`, these names are tried, most specific first:

```
dir/base_<os>_<arch><ext>
dir/base_<os><ext>
dir/base_<arch><ext>
dir/base<ext>
```

| | windows-x86_64 | linux-x86_64 | linux-arm64 | macos-arm64 |
|---|---|---|---|---|
| `<os>` | `windows` | `linux` | `linux` | `macos` |
| `<arch>` | `x86_64` | `x86_64` | `arm64` | `arm64` |
| `<ext>`, `static` | `.a`, `.lib` | `.a` | `.a` | `.a` |
| `<ext>`, `dynamic` | `.dll.a`, `.lib`, `.dll` | `.so` | `.so` | `.dylib` |

Every ending for the kind is tried at each step, and the first file that exists is used. It is passed to the linker by its exact file name.

No `lib` prefix is added or removed: the base name is used exactly as written, so `libfoo.a` is `"dir/libfoo"`.

When nothing matches, the error lists every path that was tried:

```
error TKO0329: #foreignlib found no matching library file: GREET dynamic vendor/greet/gret; tried:     vendor/greet/gret_windows_x86_64.dll.a
    vendor/greet/gret_windows_x86_64.lib
    vendor/greet/gret_windows_x86_64.dll
    vendor/greet/gret_windows.dll.a
    vendor/greet/gret_windows.lib
    vendor/greet/gret_windows.dll
    vendor/greet/gret_x86_64.dll.a
    vendor/greet/gret_x86_64.lib
    vendor/greet/gret_x86_64.dll
    vendor/greet/gret.dll.a
    vendor/greet/gret.lib
    vendor/greet/gret.dll
```

So one folder can hold every platform's files, and the source needs no `#ifdef`:

```
vendor/greet/greet_windows_x86_64.lib
vendor/greet/greet_linux_x86_64.so
```

## Errors

| | |
|---|---|
| `TKO0327` | `expected a name, STATIC or DYNAMIC, then a quoted spec after #foreignlib` |
| `TKO0328` | `expected STATIC or DYNAMIC after the #foreignlib name` |
| `TKO0329` | `#foreignlib found no matching library file`, listing every path tried |
| `TKO0330` | `#foreignlib name already bound to a different library set` |
| `TKO0172` | `cannot make an import library for '...': it is not a 64-bit x86-64 DLL` (see below) |

Declaring the same name again with an **identical** set is allowed, which is what happens when two files include the same binding header. A different set is `TKO0330`.

## Remarks

- **A `#foreignlib` links its libraries whether or not any declaration names them**, exactly as [`#inclib`](Inclib) does. Declarations made by [`#cinclude`](modern-Cinclude) carry no `lib` clause and need none.
- **`lib name` in a declaration is not checked.** A misspelt name compiles and links, because the directive has already linked the library. Treat the clause as a note to the reader.
- **On Windows, `.lib` is eligible for both kinds.** A static library and an import library share the ending, and nothing in the name tells them apart, so `static` can match an import library. Give the two different base names, such as `foo-static` and `foo`.
- **The kind is not checked for `system:` specs.** tiko does not look for the file, so the linker takes whatever it finds. On Linux it prefers `libfoo.so` over `libfoo.a` when both exist.
- **A `.dll` with no import library** (windows-x86_64). When a `dynamic` spec matches only a `.dll`, tiko reads the DLL's export table and makes an import library for it while linking, with `llvm-dlltool` from clang's LLVM directory, and deletes it with the other intermediate files. The import library names the DLL as the DLL names itself, not by its file name, so a renamed copy in `vendor/` still loads the original beside the program. A file that is not a 64-bit x86-64 DLL is `TKO0172`. A `.dll.a` or `.lib` of a matching name is found first and used as it is.
- **Separately compiled modules carry their own libraries.** The resolved library file and its absolute directory are recorded in the object file, so a module compiled with `-c` links correctly later, from any working directory.
- **Running the program is up to you.** A dynamically linked program needs its DLL beside the `.exe` on Windows, its `.so` on the loader's path on Linux (`LD_LIBRARY_PATH`, the system's library directories, or an rpath such as `#cmdline "-Wl -rpath,$ORIGIN"`), and on macOS its `.dylib` where its install name points (a program that links a `.dylib` file from `#foreignlib` gets the run path `@loader_path`, so `@rpath/<name>` resolves beside it). `#foreignlib` does not copy library files.
- `#inclib` and `#libpath` work alongside it and can be used in the same program. `#libpath` is relative to the working directory, which is why a shipped binding uses `#foreignlib` instead.

## Working with `#cinclude`

Binding to a C library is **two** jobs. `#foreignlib` does the linkage half, *where is the code?*, and [`#cinclude`](modern-Cinclude) does the header half, *what are these things?*, turning the library's own `.h` into tiko declarations for the target being built.

Together they let a binding ship **entirely inside your own source tree**:

```freebasic
'' mylib/mylib.ti
#pragma once

#cinclude once "vendor/mylib.h"             '' declarations, from the real header
#foreignlib MYLIB dynamic "vendor/mylib"    '' the library, per target
```

Both paths are relative to `mylib.ti`, and the using code needs no `declare` and no `#ifdef`.

### See also

- [#foreignlib Tutorial](modern-Foreignlib-tutorial), building a library and linking it both ways
- [`#cinclude`](modern-Cinclude), the header half of the same job
- [Using C Libraries](Using-C-Libraries-Tutorial), from download to running program for four real libraries
- [`#inclib`](Inclib) · [`#libpath`](Libpath) · [`Lib`](Lib)
- [Compiler Option: -l](Compiler-Option-L) · [Compiler Option: -p](Compiler-Option-P)

## Examples

```freebasic
'' A library kept inside the project, linked as a shared library:
''
''     vendor/greet/greet.h
''     vendor/greet/greet_windows_x86_64.lib    import library
''     vendor/greet/greet_linux_x86_64.so
#cinclude once "vendor/greet/greet.h"
#foreignlib GREET dynamic "vendor/greet/greet"

print "2 + 3 ="; greet_add( 2, 3 )
```

```freebasic
'' Static or dynamic, chosen at build time with -d GREET_STATIC.
#cinclude once "vendor/greet/greet.h"

#ifdef GREET_STATIC
    #foreignlib GREET static "vendor/greet/greet-static"
#else
    #foreignlib GREET dynamic "vendor/greet/greet"
#endif
```

```freebasic
'' A system library, with a declaration written by hand.
#foreignlib WINMM dynamic "system:winmm"

declare function timeGetTime lib WINMM alias "timeGetTime" ( ) as uint32

print "Windows has been running for"; timeGetTime( ) \ 60000; " minutes"
```

---

**Category:** [Foreign Library Linking](Category-Foreign-Library-Linking)  
**Kind:** keyword

---

[Home](Home) · [Keyword Index](Keyword-Index)
