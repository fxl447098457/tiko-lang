[Home](Home) › **Using C Libraries**

# Using C Libraries Tutorial

> 📘 **Step by step, one library each:** [SQLite](SQLite-Tutorial) · [raylib](Raylib-Tutorial) · [GLFW](GLFW-Tutorial) · [SDL3](SDL3-Tutorial)
>
> 📖 **In the book:** [Chapter 30, Using C Libraries](https://tiko-lang.net/book/ch30-c-libraries.html) covers the same ground in one chapter. Every program on these pages is one of its listings, compiled and run on Windows and Linux with tiko.

Most of the code a program might want already exists as a C library: databases, graphics, sound, compression, networking. tiko uses a C library directly. [`#cinclude`](modern-Cinclude) reads the library's own header, so you write no declarations, and [`#foreignlib`](Category-Foreign-Library-Linking) links the library's file. This page covers what is the same for every library. The four tutorials above then take one library each from its download page to a running program.

---

## 1. What you need

| | Windows | Linux | macOS |
|---|---|---|---|
| tiko and LLVM | as for any tiko program | as for any tiko program | as for any tiko program (Homebrew's `llvm`) |
| C headers for `#cinclude` | **Visual Studio Build Tools**, with *Desktop development with C++* and the Windows SDK | your distribution's C compiler (`build-essential` on Ubuntu) | Xcode's **Command Line Tools**, which every macOS link needs anyway |
| building libraries from source | CMake | CMake, plus the library's `-dev` packages | CMake, or the library from Homebrew |

tiko itself does not need Visual Studio, but `#cinclude` does. On Windows, clang reads the C runtime's headers (`stdio.h` and the rest) from the Visual Studio installation, and almost every library header includes one. Without the Build Tools you see this:

```
note: windows-x86_64 imports against the installed MSVC and Windows SDK
headers; install Visual Studio Build Tools with the Windows SDK, or name
the directory with -cinclude
```

## 2. The files in a library package

| File | Windows | Linux | macOS | Used by |
|---|---|---|---|---|
| header | `name.h` | `name.h` | `name.h` | `#cinclude`, when you compile |
| static library | `name.lib` | `libname.a` | `libname.a` | the linker: the code is **copied into** your program |
| import library | `name.lib` or `namedll.lib` | (none) | (none) | the linker: says which DLL holds each function |
| shared library | `name.dll` | `libname.so.N` | `libname.N.dylib` | your program, **every time it starts** |

On Windows, a static library and an import library are both `.lib`. The package's documentation, or the file size, tells you which is which: raylib's static `raylib.lib` is 5 MB, and its import library `raylibdll.lib` is 400 KB.

**A DLL with no import library is fine.** When `#foreignlib ... dynamic` finds only a `.dll`, tiko reads the DLL's table of exports and makes the import library itself while linking, naming the DLL as the DLL names itself. The [SQLite tutorial](SQLite-Tutorial#3-lay-it-out-windows) uses that.

**Choose the right download.** tiko builds 64-bit programs only, so skip anything marked `win32`, `x86`, `i386` or `i686`. On Windows, take the package built for **Visual C++** (`msvc`, `VC`, `vc2022`), because tiko's Windows target follows Visual C++'s conventions and uses its C runtime. The `mingw` packages are for a different toolchain.

## 3. Static or dynamic?

| | Static | Dynamic |
|---|---|---|
| your program is | one file | the program **plus** the DLL or `.so` |
| size (raylib example, Windows) | 608 kB | 27 kB + 1,905 kB DLL |
| update the library by | relinking | replacing the DLL |
| system libraries | **you** link the ones the library calls | the DLL already links them |
| can go wrong when | linking | the program starts |

All four libraries in these tutorials allow both. Check the licence of any other library first: some, such as the LGPL, ask more of a static link than of a dynamic one.

### Where a running program finds its shared library

- **Windows** looks in the **program's own directory** first, then the system directories, then the current directory and `PATH`. Put the DLL beside the `.exe`. If it is missing, the program exits immediately with code `-1073741515` (`0xC0000135`, *DLL not found*) and prints nothing.
- **Linux** looks in `LD_LIBRARY_PATH`, then the system's library directories. It does **not** look beside the program. It asks for the library's **soname**, such as `libraylib.so.600`, which is recorded inside the `.so`. If the library is missing:

  ```
  error while loading shared libraries: libraylib.so.600: cannot open shared object file: No such file or directory
  ```

  For a library kept inside your project, run with `LD_LIBRARY_PATH=. ./program` for a quick test. To make it last, record an **rpath** in the program: a directory the loader searches before the system's. `$ORIGIN` means "the directory this program is in", and tiko's `-Wl` option hands it to the linker:

  ```freebasic
  #cmdline "-Wl -rpath,$ORIGIN"
  ```

  The program and its `.so` files can then be copied anywhere together. `-Wl` passes its value to the linker, split at commas. In a shell, single-quote it so the shell leaves `$ORIGIN` alone: `tiko game.tiko -Wl '-rpath,$ORIGIN'`. In `#cmdline` or in `tiko.toml`'s `options`, no quoting is needed. Put `#cmdline` lines that only make sense on Linux inside `#ifdef __FB_LINUX__`: on Windows, `-Wl` talks to `lld-link`, which has no `-rpath`.

- **macOS** loads a library by its **install name**, recorded in the program when it links. Homebrew's libraries name their own absolute path (`/opt/homebrew/opt/sdl3/lib/libSDL3.0.dylib`), so they load from there. A library you build names `@rpath/libname.dylib`, and a program that links a `.dylib` from `#foreignlib` has the run path `@loader_path`, its own directory: put the library beside the program. If it is missing, dyld stops the program before it starts (exit 134):

  ```
  dyld[<pid>]: Library not loaded: @rpath/libname.dylib
  ```

  Headers and libraries installed by Homebrew are under `/opt/homebrew/include` and `/opt/homebrew/lib`. A macOS link searches `/opt/homebrew/lib` after your own paths, so `system:` libraries from Homebrew need no `-p`.

> ⚠️ **A missing library is not always an error on Linux.** If the system has its own copy under the same soname, the program silently loads that one. A program linked with SQLite 3.54.0 prints `SQLite 3.54.0` with `LD_LIBRARY_PATH=.` and `SQLite 3.45.1` without it, because Ubuntu 24.04 ships 3.45.1. An rpath of `$ORIGIN` puts your copy first. Ask the library for its version when it matters.

### Static linking means linking the library's dependencies too

A static library is only that library's code. Whatever it calls in the operating system, your program must link. Each one goes after the library in `#foreignlib`, as `"system:name"`:

```freebasic
#foreignlib RAYLIB static "vendor/raylib/raylib", _
    "system:winmm", "system:gdi32", "system:user32", "system:shell32"
```

To find the list, check the library's documentation first. If it doesn't say, link without any and read the errors:

```
lld-link: error: undefined symbol: __declspec(dllimport) SetupDiGetClassDevsA
lld-link: error: undefined symbol: __declspec(dllimport) CoInitializeEx
```

On Windows, search Microsoft's documentation for each function. The *Requirements* table at the bottom names its library: `SetupDiGetClassDevsA` is in `setupapi.lib`, so add `"system:setupapi"`. Repeat until the link succeeds.

## 4. Inside the project, or installed for everyone?

### Vendored: the project carries the library

Put the library in a `vendor/` folder of the project. Anyone can then build the project without installing anything, and the version never changes behind your back.

`#foreignlib` was designed for this. Its path is relative to **the file that contains it**, not to where you run the compiler. It also picks the file **by target**: for `"vendor/raylib/raylib"` it tries `raylib_windows_x86_64`, `raylib_windows`, `raylib_x86_64`, then `raylib`, each with the target's extensions. So rename the files the **linker** reads, and both platforms can share one folder:

```
vendor/raylib/raylib.h
vendor/raylib/raylib_windows_x86_64.lib       static, Windows
vendor/raylib/raylib_linux_x86_64.a           static, Linux
vendor/raylib/raylibdll_windows_x86_64.lib    import library, Windows
vendor/raylib/raylibdll_linux_x86_64.so       shared, Linux (renamed)
raylib.dll                                    beside the program
libraylib.so.600                              beside the program
```

**Never rename the files the program loads when it runs.** A DLL keeps the name its import library records. A `.so` keeps its soname.

Use the target tags whenever two platforms share a folder. On Windows a static search tries `.a` before `.lib`, so an untagged Linux `raylib.a` would be picked up on Windows.

`#cinclude "vendor/raylib/raylib.h"` finds the header under the directory you compile from, and then beside the file that names it. When the header itself includes others with angle brackets (`#include <SDL3/SDL_stdinc.h>`), name its `include` folder with `-cinclude`.

> ⚠️ **Search order:** a header under the **working directory** wins over the one beside the file. That is the reverse of `#include`. Keep vendored header paths specific (`vendor/raylib/raylib.h`, not `raylib.h`), so that no stray copy can shadow them.

### Installed: one copy for every program

**Linux.** The package manager puts headers in `/usr/include` and libraries in `/usr/lib/x86_64-linux-gnu`. A library built from source and installed with `sudo cmake --install build` goes to `/usr/local/include` and `/usr/local/lib`. clang and the linker search all of these by default, so the program names no paths:

```freebasic
#cinclude once "sqlite3.h"
#foreignlib SQLITE dynamic "system:sqlite3"
```

`"system:sqlite3"` passes `-lsqlite3` to the linker. The `static`/`dynamic` word is **not checked** for a `system:` spec, and the linker prefers `libsqlite3.so` over `libsqlite3.a` when both exist. After installing into `/usr/local/lib` yourself, run `sudo ldconfig` once.

**Windows** has no system-wide place for C libraries, so make one, such as `C:\tiko-libs`. Then write a **binding header** (next section), and point each project at the folder with `-i`.

## 5. A binding header

Move the `#cinclude` and `#foreignlib` lines into a `.ti` file next to the library. Both paths in it are relative to the `.ti` itself, so the folder works wherever it is:

```freebasic
'' raylib.ti -- raylib 6.0 for tiko: its header, and the library to
'' link, in one file a program includes. Both paths are relative to
'' this file, so the folder it sits in can live anywhere: inside one
'' project, or in a single place that every program shares.
#pragma once

#cinclude once "raylib/raylib.h"

#ifdef __FB_WIN32__
    #foreignlib RAYLIB static "raylib/raylib", _
        "system:winmm", "system:gdi32", "system:user32", _
        "system:shell32"
#else
    #foreignlib RAYLIB static "raylib/raylib", _
        "system:GL", "system:m", "system:pthread", "system:dl", _
        "system:rt", "system:X11"
#endif
```

A program then needs one line, `#include once "raylib.ti"`, and the project says where the bindings are:

```toml
# A program that uses raylib without saying where raylib is: the
# -i below names the folder of bindings, relative to this file.
[package]
name = "game"

[target.game]
main    = "main.tiko"
options = ["-i", "../vendor"]
```

To share the bindings between every program on the machine, put `raylib.ti` and its `raylib/` folder in `C:\tiko-libs`, and use `options = ["-i", "C:/tiko-libs"]` in each `tiko.toml` (or `-i C:\tiko-libs` on the command line). The [raylib tutorial](Raylib-Tutorial#7-one-copy-for-every-program) shows the whole project.

### Or a binding module

A binding can also be a **module**. Inside a module, write **`public #cinclude`**: the header's names then travel with the module, and every program that `#import`s it sees them as if it had read the header itself. A plain `#cinclude` in a module stays private.

```freebasic
'' raylib as a module. 'public #cinclude' makes raylib.h's names the
'' names of every program that imports the module, and the module's
'' own #foreignlib links the library into each of them. Both paths are
'' relative to this file.
#module "raylib"

public #cinclude once "../../vendor/raylib/raylib.h"

#ifdef __FB_WIN32__
    #foreignlib RAYLIB static "../../vendor/raylib/raylib", _
        "system:winmm", "system:gdi32", "system:user32", _
        "system:shell32"
#else
    #foreignlib RAYLIB static "../../vendor/raylib/raylib", _
        "system:GL", "system:m", "system:pthread", "system:dl", _
        "system:rt", "system:X11"
#endif
```

A program then needs one line, `#import "raylib"`. Install the module for every program by putting its folder in a directory named in **`TIKO_PATH`** (`;`-separated on Windows, `:` on Linux and macOS). A module may not use `#cmdline`, so a library whose headers need `-cinclude` (SDL3's do) is still best kept as a binding header. The [raylib tutorial](Raylib-Tutorial#8-a-binding-module) has the whole project.

## 6. When it goes wrong

| What you see | Cause | Fix |
|---|---|---|
| `TKO0336: unable to import C header` + clang `file not found` | the header, or one it includes, is not found | check the path; add `-cinclude <dir>` for `<...>` includes |
| the same + a note about the Windows SDK | no Visual Studio Build Tools | install them with the Windows SDK |
| `TKO0329: #foreignlib found no matching library file` + a list | no file has any of the listed names | rename the file to one of them, with its target tag |
| `TKO0172: cannot make an import library for '...': it is not a 64-bit x86-64 DLL` | a `.dll` with no import library was linked, and it is the 32-bit build | download the 64-bit package |
| `undefined symbol: ...` when linking statically | a system library the static library needs is missing | add `"system:name"` (section 3) |
| program exits at once, code `-1073741515` | Windows cannot find the DLL, or the import library has no DLL name | put the DLL beside the `.exe`; check the import library |
| `error while loading shared libraries`, exit 127 | Linux cannot find the `.so` | `-Wl -rpath,$ORIGIN`, `LD_LIBRARY_PATH=.`, or install it |
| the program reports an older library version | Linux loaded the system's copy | `-Wl -rpath,$ORIGIN` |
| `warning TKO0833: passing different pointer types` at a callback | your callback's parameters differ from the C type | match the header exactly, since a wrong callback reads garbage |
| a library floods the console | it logs to standard output | lower its log level (raylib: `SetTraceLogLevel( LOG_WARNING )`) |

---

### See also

- [#cinclude](modern-Cinclude) and the [#cinclude Tutorial](modern-Cinclude-tutorial)
- [Foreign Library Linking](Category-Foreign-Library-Linking) and the [#foreignlib Tutorial](modern-Foreignlib-tutorial)
- [tiko build](Category-Tiko-Build), for `tiko.toml`
- [Chapter 29, Interfacing with C](https://tiko-lang.net/book/ch29-interfacing-c.html): types, strings and callbacks across the boundary

---

[Home](Home)
