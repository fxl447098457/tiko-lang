# Using C libraries

Chapter 28 used SQLite through `vendor/sqlite3`, one of the toolchain's vendor packages: a C
library that arrives ready to `#import`. The toolchain ships a handful of those. Every other C
library — and there are thousands, for databases, compression, graphics, sound, networking —
you connect yourself.

Real libraries arrive as an archive from a project's website, with the files arranged the way
their authors chose, built for compilers you may not have, in several variants whose differences
the archive does not explain. Before the first line of your program compiles you have to choose
a package, unpack it, give tiko the library's declarations, decide which file to link, and make
sure the program can find the library again when it runs, on your machine and on someone else's.

tiko does it in two steps, and they are the steps every vendor package was made with:

1. **`tiko c2t`** translates the library's C header, once, into a tiko header: a `.ti` file that
   reads like the C it came from, which you look over, finish where it says so, and keep with
   your code.
2. **`#foreignlib`** links the library's compiled code, statically or dynamically, choosing the
   right file for each platform.

This chapter takes four of the most widely used C libraries through both steps:

| Library | Version | What it is for | Licence |
|---|---|---|---|
| **SQLite** | 3.54.0 | an SQL database in a single file, with no server | public domain |
| **raylib** | 6.0 | games and graphics: windows, drawing, input, sound | zlib |
| **GLFW** | 3.5.1 | a window and an OpenGL context, and the input that goes with them | zlib |
| **SDL3** | 3.4.18 | windows, rendering, audio, input and more, for games and media | zlib |

Each one is taken from its download page to a running program, linked both **statically** and
**dynamically**, kept either **inside the project** or **installed once** for every program on
the machine, on Windows and on Linux. The programs are the libraries' own first examples,
translated into tiko, so you can put them beside the library's documentation and read the two
together.

```admonish info title="On macOS"
The SQLite programs run on macOS too: `fetch-libs.sh` builds SQLite's static archive and its
`.dylib` there. This chapter's raylib, GLFW and SDL programs are for Windows and Linux. tiko can
link Apple's frameworks (`#foreignlib ... "framework:Cocoa"`), but these listings have not been
set up or run on a Mac. On a Mac, the toolchain's `vendor/SDL3` links Homebrew's SDL instead.
```

Every listing in this chapter was compiled and run on Windows and Linux, against exactly the
versions in the table.

## Before you start

Building a program that uses a translated header needs nothing more than tiko and LLVM, as
Chapter 1 set up. **Translating** a header needs more, because `tiko c2t` hands the header to
Clang and Clang has to read every header it includes:

- **libclang**, Clang as a library, which the LLVM installation provides.
- **The Windows headers, on Windows.** c2t reads a header once for each of tiko's targets. For
  the Windows pass Clang reads the C runtime's and the Windows SDK's headers from the **Visual
  Studio Build Tools**: install them, free, with *Desktop development with C++*.
- **The Linux headers, for the Linux pass.** On Linux they are already there, with the `-dev`
  package of any library a header includes. On Windows, the headers of a Linux installation in
  WSL serve, named with `--sysroot`.
- **The macOS headers, for a macOS pass.** It is optional and runs on a Mac:
  `--macos-sysroot $(xcrun --show-sdk-path)` names the SDK from Xcode's Command Line Tools.

All of that is needed **only by whoever translates**. The `.ti` it writes is an ordinary tiko
file: anyone who builds the program afterwards, on any platform, needs no Clang, no Visual
Studio and no C headers. This chapter translates on Windows, with Ubuntu in WSL for the Linux
pass. On Linux, c2t translates a header that includes nothing beyond C's freestanding headers
(`stddef.h`, `stdint.h`, `stdbool.h`, `stdarg.h`), as `sqlite3.h` and `raylib.h` do; one that
includes `<GL/gl.h>` or `<stdio.h>` fails its Windows pass there, for want of the Windows
headers.

Two more tools are used to build libraries from their source: **CMake**, from `cmake.org` or your
package manager, and on Linux **a C compiler and the development packages** a library lists,
named in each library's section.

The shell commands in this chapter are written for **bash**, and the same commands work on both
platforms: on Windows, run them in Git Bash, which comes with Git for Windows. The LLVM tools they
use (`clang`, `llvm-lib`, `llvm-dlltool`) are in LLVM's `bin` directory, `C:\Program Files\LLVM\bin`
by default; add it to `PATH`, or write the full path.

## What a library package contains

Open any C library's download and you find the same few kinds of file, under different names.

| File | Windows | Linux | macOS | What it is for |
|---|---|---|---|---|
| header | `.h` | `.h` | `.h` | the declarations: what `tiko c2t` translates |
| static library | `.lib` | `.a` | `.a` | the library's compiled code, copied into your program when it links |
| shared library | `.dll` | `.so`, `.so.6`, `.so.6.0.0` | `.dylib` | the compiled code as a separate file, loaded when your program starts |
| import library | `.lib` | none | none | Windows only: a small file that tells the linker which DLL holds each function |

On Windows, `.lib` means two different things. A **static** `.lib` holds the library's code; an
**import** `.lib` holds none, only the names of the functions and the name of the DLL they live
in. You cannot tell them apart by the name, only by the size and by the package's documentation:
raylib's `raylib.lib` is 5 MB of code, its `raylibdll.lib` 400 KB of names.

The linker never reads a `.dll`. To link with a DLL, you link with its import library, and the
DLL is used only when the program runs. If a package ships a DLL without one, `#foreignlib` makes
one for you when the program links; the SQLite section shows it.

### Choosing the right package

Libraries publish several builds of the same version. Two choices matter for tiko:

- **64-bit only.** tiko builds x86-64 programs. A package marked `win32`, `x86`, `i386` or
  `i686` cannot be linked into them.
- **On Windows, the Visual C++ build.** tiko's Windows target, `windows-x86_64`, uses Microsoft's
  conventions and Microsoft's C runtime, the same as Visual C++. Packages are labelled `msvc`,
  `VC`, `vc2022` or similar. The `mingw` packages are built for GCC's conventions on Windows,
  and are not the ones this chapter uses.

On Linux the choice is simpler: a library built by your distribution's compiler, for x86-64.

## Translating a header

Chapter 29's `#cinclude` reads a C header at every build and keeps what it learns in a cache
for the compiler alone. **`tiko c2t`** reads the header once and writes a tiko header that a
person can read:

```bash
tiko c2t vendor/sqlite/sqlite3.h --verify
```

It writes `vendor/sqlite/sqlite3.ti`, beside the header, in about three seconds. Here is a piece
of `sqlite3.h`, the type every connection is and two of its result codes:

```c
typedef struct sqlite3 sqlite3;
SQLITE_API int sqlite3_close(sqlite3*);
#define SQLITE_ROW         100  /* sqlite3_step() has another row ready */
#define SQLITE_DONE        101  /* sqlite3_step() has finished executing */
```

and the same lines in `sqlite3.ti`:

```tiko
type sqlite3__fwd as sqlite3
declare function sqlite3_close( byval as sqlite3 ptr ) as int32
#define SQLITE_ROW 100          /' sqlite3_step() has another row ready '/
#define SQLITE_DONE 101         /' sqlite3_step() has finished executing '/
```

Every declaration is where the C put it, with its comments, its blank lines and SQLite's
documentation around it, so the `.ti` reads alongside the library's manual. C's types become
tiko's fixed-width ones — `int` is `int32`, `const char *` is `const zstring ptr` — the same on
both targets. `SQLITE_API`, the macro SQLite puts before every function, is recognised as
decoration and dropped. A struct the header declares but never defines, like `sqlite3`, is an
**opaque** type: a program can hold a pointer to one and nothing else.

### Two platforms in one file

c2t parses the header twice, once as Clang would compile it for **windows-x86_64** and once for
**linux-x86_64**, and merges the two. What is the same on both is written once. What differs is
written under a guard the translation makes, `#if defined(TIKO_OS_WINDOWS)` … `#endif`, and the
header's own `#if` lines are kept, with C's platform tests spelled as tiko's: `_WIN32` becomes
`TIKO_OS_WINDOWS`, `__linux__` becomes `TIKO_OS_LINUX`. One `.ti` serves both platforms, which is
why it can be committed and shared. Given `--macos-sysroot`, c2t adds a third pass, for
**macos-arm64**, and `__APPLE__` becomes `TIKO_OS_MACOS`.

A branch neither platform takes — an `#ifdef SQLITE_ENABLE_SESSION` for an optional feature, an
`#elif` for macOS — is translated as well, inside its `#if`. Define the macro before including
the `.ti`, and the program sees what a C program that defined it would see.

### The banner

Every translation opens with a banner, which is the first thing to read:

```text
'' sqlite3.ti -- tiko header translated by c2t (tiko 0.1.0-dev)
''   from the C header "sqlite3.h"
''   source sha256 : cd20a2877bc82b94...c581aac6e240925535cbd90166
''   clang         : clang version 21.1.0
''   passes        : x86_64-pc-windows-msvc, x86_64-pc-linux-gnu
''   options       : --verify
''
'' Generated from C. Search for C2T-TODO and translate those parts by
'' hand.
''
'' Renamed:
''   parameter  sqlite3_bind_text64.encoding
''              -> sqlite3_bind_text64.encoding_   (tiko reserved word)
''   ...
''   constant   double -> double_   (tiko reserved word)
''
'' 1 item needs manual translation:
''   line 11414  sqlite3.h:11450  C2T-TODO(macro)  double
```

(Wrapped here to fit the page, with the hash shortened and five renames left out; and this is the banner of a plain
`--verify` run, before the `--shared-macro` pass that *Variables a DLL exports* adds.) The SHA-256
names the exact header that was translated, so the `.ti` says which version of the library it
belongs to. There is no date in it: translating the same header again gives the same bytes, and
after an upgrade, a diff of the `.ti` shows exactly what the library changed.

**Renamed** lists every C name that is a tiko word. `encoding` and `type` are keywords in tiko,
so a parameter called that gets an underscore. Parameter names do not affect a call, so these
renames cost nothing; a renamed function or type would be called by its new name.

**Items that need manual translation** are the parts c2t could not carry. Each is marked where it
stands, the C quoted underneath:

```tiko
#ifdef SQLITE_OMIT_FLOATING_POINT
'' C2T-TODO(macro) sqlite3.h:11450 -- 'double' is a tiko keyword:
'' #undef would remove it
'' # undef double
#endif
```

(The TODO's first line is one line in the file.)

The exit status says how it went: **0**, clean; **2**, translated, with TODOs to read; **1**,
nothing written. A TODO is API that is missing until someone writes it by hand, and the reason in
brackets says why. Most fall into three kinds:

- **A C feature tiko cannot express**: a variadic macro (`__VA_ARGS__`), a macro that pastes
  tokens with `##`, a `static inline` function, whose body c2t quotes for porting because there
  is no symbol in the library to link against.
- **A system header with no tiko counterpart.** c2t knows C's standard headers (`<stdio.h>`
  becomes `crt/stdio.bi`), Windows' (`<windows.h>` becomes `windows.bi`) and OpenGL's; anything
  else is a TODO.
- **A branch Clang cannot parse** even when it is switched on: C++ under `#ifdef __cplusplus`,
  or a Vulkan type in a header that expects Vulkan's own to have been included first.

Read the list and decide, item by item, whether your program needs it. SQLite's one TODO sits in
a branch that only a build without floating point would take, and nothing a program calls is
missing. GLFW, below, has twenty-two, and none of them is on its way.

A **NOTE** is information rather than a gap: the translation is complete, and something deserves a
look. SQLite's `SQLITE_TRANSIENT` is a C macro that casts `-1` to a function pointer; c2t
translates it, `cast(sqlite3_destructor_type, (-1))`, and notes that Clang gives no value for a
pointer to check it against.

**`--verify`** compiles the translation for both targets inside c2t and compares every struct's
size, alignment and member offsets, and every integer macro's value, with Clang's. A struct that
differs is refused and marked, never written wrong. It costs almost nothing — `sqlite3.h` takes
three seconds with it and without — so use it every time.

```admonish danger title="Pitfall"
**A translation describes one version of the library.** Link `sqlite3.ti`, made from 3.54.0's
header, with an older SQLite, and a function the old library lacks is a link error, which is
noticed. A struct that changed shape between versions is not: the program compiles, links and
runs, and reads the wrong bytes. Translate the header that came in the same package as the
library you link, and translate again whenever you upgrade either. The banner's SHA-256 says
which header a `.ti` was made from.
```

### Finishing a translation

When a TODO is something your program needs, write it by hand — but **not in the generated
file**, where the next translation would overwrite it. Put it in a file of its own beside it,
`sqlite3-residue.ti` say, included after the translation, with a line saying why each item is
there. The vendor packages do exactly this: `vendor/sqlite3` is the translated `sqlite3.ti`, a
`sqlite3-residue.ti`, and the line that links the library.

### Variables a DLL exports

Most C libraries export only functions, and a translated header calls them the same way however
the library is linked. A **variable** the library exports is different on Windows: a program
linked to the DLL must reach it through the import table, which tiko writes `extern import`, and a
program linked statically must not. SQLite has three, among them `sqlite3_version`. Without help,
a dynamic program that reads one fails to link:

```text
lld-link: error: undefined symbol: sqlite3_version
```

c2t solves it with one more pass, given the library's **shared-build switch**: the macro that
makes the header declare things for a DLL. raylib's is `USE_LIBTYPE_SHARED`. SQLite has none of
its own, so the switch is its export macro defined the way a DLL build would define it:

```bash
tiko c2t vendor/sqlite/sqlite3.h --verify \
    --shared-macro "SQLITE_API=__attribute__((dllimport))"
```

Each exported variable is then written both ways, the import form under
`defined(TIKO_LINK_DYNAMIC)`. A program linked to the DLL defines that before it includes the
translation:

```tiko
#define TIKO_LINK_DYNAMIC 1
#include once "vendor/sqlite/sqlite3.ti"
#foreignlib SQLITE dynamic "vendor/sqlite/sqlite3"
```

and `print sqlite3_version` prints `3.54.0`. A vendor package defines it for you, from the
`link` on its `#import`.

### Headers that include each other

c2t translates **one header per run**. An `#include` of another of the library's headers becomes
`#include once` of that header's `.ti`, at the same relative path, so translating each header
into the same tree gives a tree of `.ti` files that include one another as the `.h` files did.
`--verify` compiles each translation, so the headers a header includes must be translated first.
For a library with many headers, a script walks them in that order; SDL's section shows one.

Because the includes are relative, a translated library needs no include directory on the
command line, wherever it is kept. Its `.ti` files find each other as they found each other in C.

### When to use c2t

`#cinclude` and `tiko c2t` share tiko's C importer, so a type comes across the same way in both.
Use `#cinclude` for a quick experiment, or a header you never want to look at. Use `tiko c2t` for
a library your program depends on: the translation is a file you can read, search, review in a
pull request and diff on an upgrade; it builds on machines that have no Clang; and the parts that
did not translate are written down where they are, rather than discovered at a call.

## Static or dynamic

Every library in this chapter can be linked either way. The difference is where its code ends up.

**Linked statically**, the library's code is copied into your program. The program is one file;
nothing can go missing when it is copied to another machine; and only the parts of the library
the program uses are copied in. It is larger, and updating the library means relinking it.

**Linked dynamically**, your program holds only references to the library, and the library's own
file, the DLL or `.so`, must be present when the program starts. The program is small, several
programs can share one copy of the library, and the library can be updated without relinking.
But the program now comes in two parts, and the second part has to be found.

Measured on the programs in this chapter, each linked both ways, in kilobytes of 1,000 bytes:

| Program | Windows, static | Windows, dynamic | Linux, static | Linux, dynamic |
|---|---:|---:|---:|---:|
| `sqlite-quick` | 1,168 | 38 + 3,519 | 1,114 | 44 + 1,197 |
| `raylib-window` | 608 | 27 + 1,905 | 996 | 35 + 2,100 |
| `glfw-window` | 227 | 29 + 234 | 331 | 35 + 353 |
| `sdl-clear` | 2,745 | 29 + 2,848 | 3,604 | 40 + 4,096 |

The second figure in each dynamic column is the shared library that has to travel with the
program. A static program is smaller than the program plus its library, because the linker copies
in only what is called.

All four licences allow either way. That is not true of every library: under the LGPL, for
instance, linking statically brings obligations that linking dynamically does not. Read a
library's licence before you decide.

`#foreignlib` says which, after the name it gives the library:

```tiko
#foreignlib SQLITE dynamic "vendor/sqlite/sqlite3"
#foreignlib SQLITE static "vendor/sqlite/sqlite3-static"
```

The path is relative to **the file the directive is in**, and names the library without its
platform's prefix or extension. The rest of this section is about what happens after the link.

### Where a program finds its shared libraries

**On Windows**, a program looks for a DLL first in **its own directory**, then in the system
directories, then in the current directory and the directories on `PATH`. Put the DLL beside the
`.exe` and it is found. When it is not, the program does not start; from a console it exits at
once with code `-1073741515`, which is `0xC0000135`, *DLL not found*, and prints nothing.

**On Linux**, a program looks for a `.so` in the directories listed in `LD_LIBRARY_PATH`, then
in the system's library directories (`/usr/lib`, `/usr/local/lib` and the others the system's
`ldconfig` knows), and **not** in its own directory. When it fails, it says so:

```text
./raylib-dll: error while loading shared libraries: libraylib.so.600:
cannot open shared object file: No such file or directory
```

and exits with code 127. The name it looks for is the library's **soname**, a name recorded
inside the `.so` when it was built (`libraylib.so.600`), not the name of the file you linked.
That is why a Linux package carries the same library under three names, such as
`libraylib.so`, `libraylib.so.600` and `libraylib.so.6.0.0`: the first is for the linker, the
second is the soname the program will ask for, and the third is the real file.

For a library installed on the system, nothing more is needed. For one inside your project, there
are two ways to say where it is. The quick one is to run the program with the project's directory
on `LD_LIBRARY_PATH`:

```bash
LD_LIBRARY_PATH=. ./sqlite-quick
```

The lasting one is an **rpath**: a directory recorded inside the program, which the loader searches
before the system's own directories. The usual value is `$ORIGIN`, which the loader reads as "the
directory this program is in", so a program and its `.so` files can be copied anywhere together.
It is given to the linker, through tiko's **`-Wl`** option, which passes its value to the linker
unchanged, split at commas:

```tiko
{{#include ../examples/ch30/raylib-rpath.tiko:link}}
```

This listing is `raylib-dll` with one more line. It runs with no `LD_LIBRARY_PATH` at all:

```text
{{#include ../examples/ch30/raylib-rpath.out}}
```

Typed in a shell, `$ORIGIN` must be in single quotes, or the shell replaces it with an empty
variable before tiko sees it: `tiko game.tiko -Wl '-rpath,$ORIGIN'`. In a `#cmdline`, as here, and
in a `tiko.toml`'s `options`, no shell is involved and it needs no quoting. On Windows, where a
program looks beside itself anyway, `-Wl` passes options to `lld-link` instead: `-Wl /STACK:8388608`
reserves an 8 MB stack.

```admonish danger title="Pitfall"
**On Linux, a missing library is not always an error.** Ubuntu has `libsqlite3.so.0` installed
for its own use. A program linked with the SQLite 3.54.0 in this chapter's project asks for that
same soname, so run without `LD_LIBRARY_PATH` it starts without complaint, using the system's
copy, an older version, and nothing says so. The same program prints `SQLite 3.54.0` with
`LD_LIBRARY_PATH=.` and `SQLite 3.45.1` without it. A program that depends on a newer feature
fails much later, and somewhere that looks unrelated. An rpath of `$ORIGIN` puts your copy first;
and when it matters which copy is loaded, check it the way the listings here do: ask the library
for its version.
```

### A static library brings its dependencies with it

A static library is the library's code and nothing else. Whatever *that* code calls becomes your
program's to link. raylib calls Windows' multimedia timer, so a program that links raylib
statically must also link `winmm`; SDL asks Windows about the devices plugged in, so it needs
`setupapi`. A shared library carries those links inside itself, which is why the dynamic listings
in this chapter name no system libraries.

`#foreignlib` takes them after the library itself, each as `"system:name"`:

```tiko
#foreignlib RAYLIB static "vendor/raylib/raylib", _
    "system:winmm", "system:gdi32", "system:user32", "system:shell32"
```

To find the list for a library, look first in its documentation: most say what a static build
needs. If they do not, link without any and read what the linker cannot find:

```text
lld-link: error: undefined symbol: __declspec(dllimport) SetupDiGetClassDevsA
lld-link: error: undefined symbol: __declspec(dllimport) CoInitializeEx
lld-link: error: undefined symbol: __declspec(dllimport) SysFreeString
```

Each name is a function of the operating system. On Windows, Microsoft's documentation for the
function names the library in its *Requirements* table: `SetupDiGetClassDevsA` is in
`setupapi.lib`, `CoInitializeEx` in `ole32.lib`, `SysFreeString` in `oleaut32.lib`. On Linux,
the manual page or the package that provides the function says which library holds it. Add one
`system:` entry for each library, and link again until nothing is missing.

## Vendored or installed

Separately from static or dynamic, you choose where the library lives.

**Vendored** means the project carries its own copy, in a directory of its own, usually
`vendor/`. Anyone who checks out the project can build it with nothing to install; the version is
the one you tested with, and stays that way until you change it; and two projects can use two
different versions without meeting. The cost is that each project carries its own copy.

**Installed** means one copy, in a shared place, used by every program on the machine. On Linux
that place exists already, and the package manager fills it. On Windows there is no such place for
C libraries, so you make one.

### A vendored library

A translated header and `#foreignlib` were both made for vendoring. `#include` finds a quoted name
beside the file that includes it first, and `#foreignlib` resolves its path relative to the file
that contains the directive, so a program finds the library's declarations and its files wherever
it is built from.

`#foreignlib` also chooses the file **for the target**. Given `"vendor/raylib/raylib"`, it tries
`raylib_windows_x86_64`, `raylib_windows`, `raylib_x86_64` and plain `raylib`, each with the
target's extensions. So both platforms' files can sit side by side, and one directive serves
both — as one `.ti` does:

```text
vendor/raylib/raylib.h                        the C header
vendor/raylib/raylib.ti                       its translation, committed
vendor/raylib/raylib_windows_x86_64.lib       static, for Windows
vendor/raylib/raylib_linux_x86_64.a           static, for Linux
vendor/raylib/raylibdll_windows_x86_64.lib    import lib for raylib.dll
vendor/raylib/raylibdll_linux_x86_64.so       libraylib.so.600, renamed
raylib.dll                                    beside the program
libraylib.so.600                              beside the program
```

The target tags are not optional when both platforms share a folder. On Windows a static search
tries `.a` before `.lib`, so an untagged `raylib.a` built for Linux is found first, and the link
fails with an error that does not say why: `lld-link: error: unknown file type: rcore.o`.

Notice which files are renamed and which are not. You rename the files the **linker** reads, to
give them their target tags. You never rename the files the program loads when it **runs**: the
DLL keeps the name its import library records (`raylib.dll`) and the `.so` keeps its soname
(`libraylib.so.600`), because those are the names the program will ask for.

Of all those files, only the `.ti` is source. The libraries are built artefacts, recreated from the
download, and the C header is only an input to c2t. A project commits its translations and fetches
the rest; this chapter's examples do exactly that. The script `examples/ch30/fetch-libs.sh` builds
the `vendor/` directory: it downloads each package, checks it against a SHA-256 checksum, and
copies and renames the files, building the ones that have no download. Run it once on each
platform:

```bash
bash fetch-libs.sh
```

The script `examples/ch30/translate.sh` then holds the c2t commands for all four libraries, the
ones this chapter shows. Between them, the two scripts are the exact record of every step in the
chapter, in order. When the prose says "copy this file there", the scripts are where to look to
see it done.

### An installed library

On **Linux**, the package manager installs a library's header into `/usr/include` and the library
into `/usr/lib/x86_64-linux-gnu`. A library you build yourself and install with
`sudo cmake --install build` goes to `/usr/local/include` and `/usr/local/lib`. The linker
searches all of them by default, so a program links an installed library by name alone:

```tiko
#include once "sqlite3.ti"
#foreignlib SQLITE dynamic "system:sqlite3"
```

The header still needs translating, once: `tiko c2t /usr/include/sqlite3.h -o sqlite3.ti`, and
the `.ti` lives with the project. It describes the version the machine had when it was made, so
retranslate when the distribution upgrades the library.

`"system:sqlite3"` hands `sqlite3` to the linker the way `#inclib "sqlite3"` would, and the
linker finds `libsqlite3.so`. Two things to know about it: the `static` or `dynamic` before a
`system:` spec is **not checked**, and when a directory has both `libsqlite3.so` and
`libsqlite3.a`, the linker takes the `.so`. After installing a library into `/usr/local/lib`
yourself, run `sudo ldconfig` once, so that programs can find it when they start.

On **Windows** you choose a folder, such as `C:\tiko-libs`, and put each library in it the same
way as `vendor/`, its translation beside it. A program then needs to be told where that folder is,
which is the job of a **binding header**, at the end of this chapter.

## SQLite

SQLite is an SQL database engine in a library: no server to install or start, and a whole
database is one ordinary file. Its authors describe it as the most widely deployed database
engine in the world, and it is inside many of the programs you already use.

```admonish note
tiko already ships SQLite, as `vendor/sqlite3`, and Chapter 28 uses it. This section makes the
same library from its download, which is what you do for a newer SQLite than the toolchain's, or
SQLite built with options of your own — and it is the pattern for every library that has no
vendor package.
```

### Downloading

Everything is on the download page, `https://sqlite.org/download.html`:

| File | What is in it |
|---|---|
| `sqlite-amalgamation-3540000.zip` | `sqlite3.c` and `sqlite3.h`: the **whole library as one C file**, with its header |
| `sqlite-dll-win-x64-3540000.zip` | `sqlite3.dll` and `sqlite3.def`, the library already built for 64-bit Windows |
| `sqlite-autoconf-3540000.tar.gz` | the same `sqlite3.c` and `sqlite3.h`, with a build script, for Unix |

The number in each name is the version: 3.54.0 is `3540000`.

SQLite is unusual in shipping its source as one file. It is meant to be compiled into your
program directly, which makes a static library easy to build yourself.

### The header

`sqlite3.h` goes to `vendor/sqlite/`, and is translated there, with the shared-build pass from
*Variables a DLL exports*:

```bash
tiko c2t vendor/sqlite/sqlite3.h --verify \
    --shared-macro "SQLITE_API=__attribute__((dllimport))"
```

`sqlite3.h` includes nothing but `<stdarg.h>`, which tiko has built in, so it needs no
`--sysroot`, and c2t translates it on Linux as well. Exit status 2, and the one TODO from *The
banner*.

### Windows: the dynamic library

The DLL zip has `sqlite3.dll` and `sqlite3.def`, a text file that lists every function the DLL
exports, but **no import library**. You do not have to make one. Put the DLL into the project
under its target-tagged name, and the original beside the program:

```text
vendor/sqlite/sqlite3_windows_x86_64.dll     the DLL, for the link
sqlite3.dll                                  the same file, for the program to load
```

When `#foreignlib SQLITE dynamic "vendor/sqlite/sqlite3"` finds only a `.dll`, the link reads the
DLL's own table of exports and makes the import library from it, with `llvm-dlltool` from the
LLVM installation tiko already uses, then deletes it with the other intermediate files. Run with
`-v`, the `llvm-dlltool` command is printed before the link.

The import library names the DLL **as the DLL names itself**, the name it was built with,
`sqlite3.dll`, and not by the name of the file it was read from. That is the Windows counterpart
of a soname: the copy in `vendor/` can carry its target tag, and the program still loads
`sqlite3.dll`. A DLL that is not 64-bit x86-64 is `TKO0172`, with the reason:

```text
error TKO0172: cannot make an import library for 'lib/w32_windows_x86_64.dll':
it is not a 64-bit x86-64 DLL (machine &h014C)
```

(One line on the screen, its path shortened here.) That is the 32-bit download, taken by mistake.

### Windows: an import library of your own

To keep an import library in the project instead, so the link does not make one each time, make
it from the `.def` with `llvm-dlltool`:

```bash
llvm-dlltool -m i386:x86-64 -d sqlite3.def -D sqlite3.dll \
    -l vendor/sqlite/sqlite3_windows_x86_64.lib
```

`-m i386:x86-64` asks for a 64-bit import library, `-d` names the export list, `-l` the library
to write, and `-D` the DLL that the program will load. The import library records that name, and
the program asks for exactly that file when it starts.

````admonish danger title="Pitfall"
**An import library with no DLL name links, and the program then cannot start.** `sqlite3.def`
has no `LIBRARY` line naming its DLL, so the name must come from the command line. Made with
`llvm-lib /def:sqlite3.def` and no name, the import library is accepted, the program links
cleanly, and running it fails at once with `0xC0000135`: Windows was asked to load a DLL called
nothing. `llvm-readobj --coff-imports` on the `.exe` shows it, an import block with an empty
`Name:`. Give the name with `-D sqlite3.dll`, or add a first line `LIBRARY sqlite3.dll` to the
`.def`.
````

A `.lib` beside the DLL under one of the names `#foreignlib` tries is found before the `.dll`, so
when both are there, the import library you made is the one that is linked.

### Windows: the static library

Compile the amalgamation with clang and put the one object in a library with `llvm-lib`:

```bash
clang -c -O2 -o sqlite3.obj sqlite3.c
llvm-lib /out:vendor/sqlite/sqlite3-static_windows_x86_64.lib sqlite3.obj
```

It takes about twenty seconds; `sqlite3.c` is over nine megabytes of C. On Windows clang compiles
for Microsoft's conventions by default, the same as tiko, and finds the C runtime's headers in
the Visual Studio Build Tools. Since a static `.lib` and an import `.lib` cannot share a name, the
static one is called `sqlite3-static`.

### Linux

The same two libraries, from the autoconf archive's `sqlite3.c`:

```bash
gcc -O2 -fPIC -c -o sqlite3.o sqlite3.c
ar rcs vendor/sqlite/sqlite3-static_linux_x86_64.a sqlite3.o
gcc -shared -Wl,-soname,libsqlite3.so.0 \
    -o vendor/sqlite/sqlite3_linux_x86_64.so sqlite3.o -lm
cp vendor/sqlite/sqlite3_linux_x86_64.so libsqlite3.so.0
```

`-fPIC` makes code that works at any address, which a shared library needs. `-Wl,-soname,…`
records the soname, the name a program linked with the library will look for. Without one, the
program would record the path it was linked with, `vendor/sqlite/sqlite3_linux_x86_64.so`, and
work only from the directory it was built in. The last line puts the library beside the
program under its soname.

To install SQLite for every program instead, use the distribution's package, which installs both
the header and the library:

```bash
sudo apt install libsqlite3-dev
```

### A first program

SQLite's documentation opens with a short C program, *SQLite In 5 Minutes Or Less*: it opens the
database named by its first argument, runs the SQL in its second, and prints every row of the
result. Here it is in tiko, linked dynamically:

```tiko
{{#include ../examples/ch30/sqlite-quick.tiko:all}}
```

Run with an in-memory database and four statements, one string that the shell lets run over
several lines:

```bash
./sqlite-quick :memory: "create table tbl1(one text, two int);
    insert into tbl1 values('hello!', 10);
    insert into tbl1 values('goodbye', 20);
    select * from tbl1"
```

```text
{{#include ../examples/ch30/sqlite-quick.out}}
```

The two directives at the top are the whole connection to SQLite: the translation for the
declarations, `#foreignlib` for the code. Everything else is the C program, line for line, and it
shows the parts of Chapter 29 that a real library uses most:

- **Opaque handles.** `sqlite3` is a struct the header declares but never defines, so a program
  can hold only a pointer to one. `sqlite3_open` fills `db` through its address, `@db`, the way
  the C passes `&db`.
- **Strings into C.** `command( 2 )` is a tiko string; passed where the header says
  `const char *`, the compiler passes a pointer to its bytes.
- **Strings out of C.** `sqlite3_errmsg` returns `const char *`, and `*sqlite3_errmsg( db )` copies
  the text into a tiko string.
- **A callback.** `sqlite3_exec` calls `Callback` once per row, so `Callback` is `cdecl` and takes
  exactly the parameters the translated declaration says: `any ptr`, `int32`, and two
  `zstring ptr ptr`. `argv[i]` is the `i`th column's text, or a null pointer for SQL's `NULL`.
- **Memory C allocated.** On failure, `sqlite3_exec` points `errMsg` at a message SQLite
  allocated; SQLite's documentation says to free it with `sqlite3_free`, so the program does.

### Prepared statements, linked statically

Gluing values into SQL text is how SQL injection happens, and the text has to be parsed again
for every row. Real programs **prepare** a statement once, with `?` where the values go, and then
**bind** a value to each `?`. This program does that, linked statically:

```tiko
{{#include ../examples/ch30/sqlite-bind.tiko:all}}
```

```text
{{#include ../examples/ch30/sqlite-bind.out}}
```

Only the `#foreignlib` line differs from the dynamic program:

```tiko
{{#include ../examples/ch30/sqlite-bind.tiko:link}}
```

`static` instead of `dynamic`, and the static library's base name. The program now needs no DLL:
copied to another machine, it runs. The translation is the same file: it does not care how the
library is linked.

Chapter 28 covered SQLite's interface itself — preparing, binding, stepping, finalizing. Two
points belong to the translation. `SQLITE_STATIC`, which promises SQLite the string outlives the
statement's use of it, is one of the pointer macros c2t translated with a NOTE,
`cast(sqlite3_destructor_type, 0)`. And `sqlite3_column_text` returns `const unsigned char *`, so the
translation declares it `const uint8 ptr`; cast it to a `zstring ptr` to read it as text.

## raylib

raylib is a library for making games, designed to be easy to learn: one header, 600 functions
with plain names, and no setup beyond opening a window. It draws with OpenGL and handles the
keyboard, mouse, gamepads, sound, textures, fonts and 3D models.

### Downloading

raylib publishes prebuilt packages on GitHub, `https://github.com/raysan5/raylib/releases`. For
6.0, two are for tiko:

| File | What is in it |
|---|---|
| `raylib-6.0_win64_msvc16.zip` | `include/raylib.h` (and `raymath.h`, `rlgl.h`); `lib/raylib.lib`, static; `lib/raylibdll.lib`, the import library; `lib/raylib.dll` |
| `raylib-6.0_linux_amd64.tar.gz` | the same headers; `lib/libraylib.a`, static; `lib/libraylib.so.6.0.0` with its links `libraylib.so.600` and `libraylib.so` |

The other packages on the page are for 32-bit Windows (`win32`), the MinGW compiler, ARM, macOS
and the web.

### Installing it in a project

From the Windows package:

| From the package | Into the project |
|---|---|
| `include/raylib.h` | `vendor/raylib/raylib.h` |
| `lib/raylib.lib` | `vendor/raylib/raylib_windows_x86_64.lib` |
| `lib/raylibdll.lib` | `vendor/raylib/raylibdll_windows_x86_64.lib` |
| `lib/raylib.dll` | `raylib.dll`, beside the program |

From the Linux package:

| From the package | Into the project |
|---|---|
| `include/raylib.h` | `vendor/raylib/raylib.h` (the same file) |
| `lib/libraylib.a` | `vendor/raylib/raylib_linux_x86_64.a` |
| `lib/libraylib.so.6.0.0` | `vendor/raylib/raylibdll_linux_x86_64.so` |
| `lib/libraylib.so.6.0.0` | `libraylib.so.600`, beside the program |

The dynamic base name is `raylibdll` on both platforms, after the Windows import library, so that
one `#foreignlib` line finds the right file on each. Then translate the header:

```bash
tiko c2t vendor/raylib/raylib.h --verify
```

Exit status 0: all of raylib's 600 functions, its structs, enums and colours, with nothing left
to finish. raylib exports no variables, so it needs no `--shared-macro`.

### Installing it for every program

On **Linux**, recent distributions package raylib as `libraylib-dev`; Ubuntu 24.04 does not.
Without a package, copy the prebuilt files into `/usr/local` and refresh the loader's cache:

```bash
sudo cp include/*.h /usr/local/include/
sudo cp -P lib/libraylib.* /usr/local/lib/
sudo ldconfig
```

`cp -P` copies the two links as links. A program then includes its translation of `raylib.h` and
writes `#foreignlib RAYLIB dynamic "system:raylib"`.

On **Windows**, see *A binding header* below.

### A first window

raylib's examples start with `core_basic_window`, which opens a window and writes one line of
text in it:

```tiko
{{#include ../examples/ch30/raylib-window.tiko:all}}
```

```text
{{#include ../examples/ch30/raylib-window.out}}
```

![The window that `raylib-window` opens.](img/ch30-raylib-window.png)

Everything after the directives is raylib's example as it is written in C. A few lines are new:

- **Linked statically**, raylib needs a different set of system libraries on each platform, so
  the `#foreignlib` line is chosen with `#ifdef __FB_WIN32__`. On Linux it is the list raylib's
  documentation gives: OpenGL, the maths library, threads, `dl`, `rt` and X11.
- **`SetTraceLogLevel( LOG_WARNING )`** comes first because raylib reports everything it does,
  about forty lines when a window opens, on standard output. The listings keep it quiet so that
  their output is the program's own.
- **`maxFrames`** lets the program stop by itself after a number of frames given on the
  command line, so this book's checks can run it. Started with no argument, it runs until you
  close the window, as raylib's example does.

Two things in the translation are more than declarations. `RAYWHITE` and `LIGHTGRAY` are C macros
that build a struct with a C compound literal:

```c
#define RAYWHITE   CLITERAL(Color){ 245, 245, 245, 255 }
```

c2t asks Clang for each field's value and writes the tiko equivalent:

```tiko
#define RAYWHITE type<Color>(245, 245, 245, 255)
```

And `DrawText` takes that `Color` **by value**, a four-byte struct passed the way C passes it, as
Chapter 29 described for `geom_point`.

### Linked dynamically

The same program, with its first lines replaced:

```tiko
{{#include ../examples/ch30/raylib-dll.tiko:link}}
```

No system libraries this time: `raylib.dll` and `libraylib.so.600` already link everything they
need. The program is 27 KB instead of 608 KB on Windows, and the DLL must travel with it.

## GLFW

GLFW does less than raylib, on purpose. It creates windows, gives each one an **OpenGL context**,
the surface OpenGL draws on, and reports keyboard, mouse, gamepad and window events. All drawing
is left to OpenGL, or to Vulkan. It is the library to reach for when you want to write the
graphics code yourself.

### Downloading

On **Windows**, take *64-bit Windows binaries* from `https://www.glfw.org/download.html`,
`glfw-3.5.1.bin.WIN64.zip`. It holds `include/GLFW/glfw3.h` and one folder of libraries per
compiler:

| Folder | What is in it |
|---|---|
| `lib-vc2022` | **the one to use:** `glfw3.lib`, static; `glfw3dll.lib`, the import library; `glfw3.dll` |
| `lib-vc2017`, `lib-vc2019`, `lib-vc2026` | the same, from other Visual C++ versions |
| `lib-static-ucrt` | a DLL built with the C runtime linked into it |
| `lib-mingw-w64` | for the MinGW compiler |

`lib-vc2022` also has `glfw3_mt.lib`. GLFW's own `README.md` explains the difference: `glfw3.lib`
is for programs that use the C runtime as a DLL, and `glfw3_mt.lib` for programs that link it
statically. tiko's programs use the C runtime DLL, `ucrtbase.dll`, so take `glfw3.lib`.

On **Linux**, GLFW publishes source only: `glfw-3.5.1.zip` from the same page. Its documentation
lists what building it needs, for both of Linux's window systems, X11 and Wayland:

```bash
sudo apt install libwayland-dev libxkbcommon-dev xorg-dev
```

Then build it twice with CMake, once as a static library and once as a shared one (a `\` at
the end of a line continues the command on the next):

```bash
cmake -S glfw-3.5.1 -B build-static -DCMAKE_BUILD_TYPE=Release
cmake --build build-static
cmake -S glfw-3.5.1 -B build-shared -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
cmake --build build-shared
```

`build-static/src/libglfw3.a` becomes `vendor/glfw/glfw3_linux_x86_64.a`, and
`build-shared/src/libglfw.so.3` becomes both `vendor/glfw/glfw3dll_linux_x86_64.so` and, beside
the program, `libglfw.so.3`. To build for Wayland alone, without the X11 packages, add
`-DGLFW_BUILD_X11=OFF`; this book's checks were built that way.

To install GLFW for every program on Linux, `sudo apt install libglfw3-dev` gives the
distribution's version, which on Ubuntu 24.04 is 3.3.10; or run `sudo cmake --install
build-shared` after the build above.

### The header

The package's `include/` goes to `vendor/glfw/include/`. `glfw3.h` includes OpenGL's header,
`<GL/gl.h>`, and the Linux pass has to read it, so on Windows it needs the Linux headers:

```bash
tiko c2t vendor/glfw/include/GLFW/glfw3.h \
    --sysroot //wsl.localhost/Ubuntu --verify
```

`//wsl.localhost/Ubuntu` is the root of the Ubuntu installation in WSL, as Windows sees it, and
`GL/gl.h` comes from its Mesa development package (`sudo apt install libgl-dev`). Without
`--sysroot`, c2t stops and says what it needs:

```text
tiko-lang: error TKO0120: unable to import C header
vendor/glfw/include/GLFW/glfw3.h (x86_64-pc-linux-gnu)
  note: clang: vendor/glfw/include/GLFW/glfw3.h:241:12: fatal error:
  'GL/gl.h' file not found
  note: the Linux pass needs Linux's system headers: give --sysroot
  (on Windows, the WSL root, e.g. //wsl.localhost/Ubuntu)
```

(Three lines on the screen.)

Reading the Linux headers through WSL is slow, so the translation takes about twenty seconds.
OpenGL itself is not translated: c2t maps `<GL/gl.h>` to tiko's own `GL/gl.bi`, which the
toolchain ships.

Exit status 2, with twenty-two TODOs, and none of them is in this program's way. Sixteen are
headers c2t has no counterpart for — Vulkan's, OpenGL ES's, macOS's and GLU's — each under the
`#if` that asks for it; four are functions whose parameters are Vulkan types, which Clang cannot
parse without Vulkan's header; and two are the lines around a `GLAPIENTRY` definition that other
OpenGL headers use. A program that uses GLFW with Vulkan would translate Vulkan's header first.
This one draws with OpenGL, and loses nothing.

### A window and an OpenGL context

GLFW's documentation shows this program first: a window, an OpenGL context, and a loop that
clears the window until it is closed.

```tiko
{{#include ../examples/ch30/glfw-window.tiko:all}}
```

```text
{{#include ../examples/ch30/glfw-window.out}}
```

`glClear` and `GL_COLOR_BUFFER_BIT` are not GLFW's. They are OpenGL's, declared in `GL/gl.bi`,
which `glfw3.ti` includes as `glfw3.h` includes `GL/gl.h`. But the code behind them is OpenGL's,
in `opengl32.dll` on Windows and `libGL.so` on Linux, so the program links OpenGL itself:
`"system:opengl32"` and `"system:GL"`. A program that called only GLFW would not need them.

`OnError` is a **callback** GLFW calls whenever something fails, with an error code and a
description. `glfwSetErrorCallback( @OnError )` installs it before `glfwInit`, so that even a
failure to start is explained, which is why GLFW's documentation sets it first.

The dynamic version keeps the OpenGL library, for the same reason:

```tiko
{{#include ../examples/ch30/glfw-dll.tiko:link}}
```

```admonish note
Through `opengl32.dll`, Windows offers only OpenGL 1.1, the version from 1997, which is where
`glClear` comes from. The functions of every later version are looked up while the program runs,
with `glfwGetProcAddress`, usually by a loader library such as glad. That is OpenGL's design on
every platform, not something tiko adds.
```

## SDL3

SDL, the *Simple DirectMedia Layer*, is the oldest and broadest of the four: windows, 2D
rendering, a GPU interface, audio, gamepads, cameras, file dialogs, threads and timers, on
desktop and mobile platforms alike. Many commercial games and emulators are built on it. SDL3 is
its current version.

### Downloading

From `https://github.com/libsdl-org/SDL/releases`, release 3.4.18:

| File | What is in it |
|---|---|
| `SDL3-devel-3.4.18-VC.zip` | for Visual C++: `include/SDL3/*.h`, and in `lib/x64/` the import library `SDL3.lib` and `SDL3.dll` |
| `SDL3-3.4.18.tar.gz` | the source, for Linux and for a static library on Windows |
| `SDL3-3.4.18-win32-x64.zip` | `SDL3.dll` alone, for people who run a program, not for building one |

There is no static library in the Windows package, and no Linux package at all: SDL is built from
its source for both. Into the project go `include/` as `vendor/sdl3/include/`, `SDL3.lib` as
`vendor/sdl3/SDL3_windows_x86_64.lib`, and `SDL3.dll` beside the program.

**On Linux**, SDL's `docs/README-linux.md` lists the packages its build uses; it uses whatever it
finds, so more packages give more features. Then:

```bash
cmake -S SDL3-3.4.18 -B build -DCMAKE_BUILD_TYPE=Release \
    -DSDL_STATIC=ON -DSDL_SHARED=ON
cmake --build build
```

`build/libSDL3.a` becomes `vendor/sdl3/SDL3-static_linux_x86_64.a`; `build/libSDL3.so.0` becomes
`vendor/sdl3/SDL3_linux_x86_64.so` and, beside the program, `libSDL3.so.0`. To install it for
every program, `sudo cmake --install build`; distributions newer than Ubuntu 24.04 package it as
`libsdl3-dev`.

### A library of headers

SDL's interface is not one header but dozens. `SDL.h` brings in fifty-seven others, and they
include one another the way C programs include them:

```c
#include <SDL3/SDL_stdinc.h>
```

c2t translates one header per run, so SDL is translated by a loop: start at `SDL.h`, visit each
header it includes before the header itself, and translate them in that order, so that every
header's includes are already translated when `--verify` compiles it. `-I` names SDL's `include`
directory, where Clang finds `<SDL3/...>`:

```bash
tiko c2t vendor/sdl3/include/SDL3/SDL_stdinc.h -I vendor/sdl3/include \
    --sysroot //wsl.localhost/Ubuntu --verify
```

is one step of it; `translate.sh` has the whole loop. Two of SDL's headers are left out:
`SDL_begin_code.h` and `SDL_close_code.h` only wrap the others in compiler decorations, which c2t
recognises and strips where they are used, and neither can be parsed on its own.

`SDL_main.h` is not among `SDL.h`'s includes, and a program that uses SDL's main callbacks needs
it. That makes fifty-nine translations in all, in under five minutes. In C it supplies the program's `main` function; a tiko program has its own beginning, so it is
translated with SDL's macro for that case, `SDL_MAIN_HANDLED`, defined:

```bash
tiko c2t vendor/sdl3/include/SDL3/SDL_main.h -I vendor/sdl3/include \
    --sysroot //wsl.localhost/Ubuntu -D SDL_MAIN_HANDLED --verify
```

A `-D` is written into the translation as a `#define`, so `SDL_main.ti` reads the macro exactly as
Clang did.

Twenty-six of the fifty-nine end with exit status 2, and their banners list 1,704 TODOs between
them. The number looks worse than it is. 1,175 are in `SDL_oldnames.h`, a table of SDL2's names
kept to help port SDL2 programs: in C it turns each old name into a compile error that names its
replacement, and without it an old name is still an error in tiko, an undeclared one. Most of the
rest are in `SDL_stdinc.h` and its neighbours, SDL's portable C library — `#if` tests on what the
C compiler predefines, `printf` format macros, `alloca` — the plumbing SDL is built from rather
than the interface a program calls. The TODOs that are API are a short list: twenty-eight `static
inline` functions, among them `SDL_rect.h`'s rectangle tests such as `SDL_PointInRect`, quoted for
porting. A program that needs one writes it in a residue file of its own.

Each `SDL3/X.h` gets an `SDL3/X.ti` beside it, and `#include <SDL3/SDL_stdinc.h>` became `#include
once "SDL_stdinc.ti"`, relative to the header that includes it. So a program includes SDL by its
path in the project and needs no include directory at all.

### The main callbacks

SDL3 can run a program for you: instead of writing the main loop, you give SDL four functions,
and it calls the first once at the start, the second for every event, the third once per frame,
and the fourth at the end. It is SDL's recommended way to write a program, because it works the
same on platforms where a program cannot own its main loop, such as phones and the web. SDL's
example `renderer/01-clear` is written that way; here it is in tiko:

```tiko
{{#include ../examples/ch30/sdl-clear.tiko:all}}
```

```text
{{#include ../examples/ch30/sdl-clear.out}}
```

The connection to SDL comes first:

```tiko
{{#include ../examples/ch30/sdl-clear.tiko:link}}
```

- `SDL.ti` brings the whole of SDL's interface, through the `.ti` files it includes.
- `SDL_main.ti` declares `SDL_EnterAppMainCallbacks`, the function that runs the callbacks. It is
  what `SDL_main.h`'s `main` would have called, and the program calls it at the end, passing the
  four procedures by address.

The four callbacks are `cdecl` and take exactly the parameters SDL's header gives their types,
`SDL_AppInit_func` and the rest. Get one wrong, say `int32 ptr` where SDL passes `void *`, and
the compiler says so with warning `TKO0833: passing different pointer types`, but builds the
program anyway. Treat that warning as an error: called with the wrong parameter types, a callback
reads garbage.

**State without globals.** The callbacks share a window and a renderer, and a C program would
keep them in global variables, as SDL's example does. SDL offers a better place: `AppInit` gets
the address of a pointer, `appstate`, and whatever it stores there is passed to every later
callback. The listing creates one `AppState` with `new`, stores it, and `AppQuit` deletes it.

**`bool` results.** SDL3's functions return C's `bool`, which the translation declares
`boolean`, and the listing compares them with `false`: `if SDL_Init( SDL_INIT_VIDEO ) = false
then`.

**Constants.** `SDL_PI_D` and `SDL_ALPHA_OPAQUE_FLOAT` are `#define`s in SDL's headers with
number values, and they are `#define`s in the translation, with the same values.

```admonish tip
SDL reads the environment variable `SDL_VIDEO_DRIVER` to choose its video system, and the value
`dummy` gives it one that draws nowhere. A program that opens windows can then run where there is
no screen, such as on a build server, and still exercise all of its code:
`SDL_VIDEO_DRIVER=dummy ./sdl-clear 60`.
```

### SDL linked statically

SDL's Windows package has no static library, so build one from the source archive, with CMake
and the Visual Studio Build Tools:

```bash
cmake -S SDL3-3.4.18 -B build -DSDL_STATIC=ON -DSDL_SHARED=OFF
cmake --build build --config Release
```

`build/Release/SDL3-static.lib`, 13 MB, becomes `vendor/sdl3/SDL3-static_windows_x86_64.lib`.
SDL uses more of Windows than the other three, and linked statically it needs five system
libraries, found by the method from *A static library brings its dependencies with it*:

```tiko
{{#include ../examples/ch30/sdl-static.tiko:link}}
```

On Linux the static library needs nothing more: SDL finds the window system and the sound
system while the program runs, rather than linking them. On both platforms the program now runs
with no `SDL3.dll` or `libSDL3.so.0` beside it.

## A binding header

Each program so far has named its library's files itself. That is fine for one program, but it
repeats in each, with the platform's system libraries every time, and it ties every program to
where the files are. Move those lines into a header of their own, a **binding header**, and a
program needs one line:

```tiko
{{#include ../examples/ch30/vendor/raylib-binding.ti}}
```

Both paths in `raylib-binding.ti` are relative to the binding header itself: `#include` looks
beside the file that includes, and `#foreignlib` always resolves that way. So the folder holding
`raylib-binding.ti` and `raylib/` can be anywhere: inside one project, or in one place that every
program on the machine shares.

A program includes it by name, and the project says where the folder is with `-i`, which adds a
directory to the ones `#include` searches:

```toml
{{#include ../examples/ch30/game/tiko.toml}}
```

```tiko
{{#include ../examples/ch30/game/main.tiko:all}}
```

`tiko build game`, then `out/debug/game 60`:

```text
{{#include ../examples/ch30/game/main.out}}
```

This is raylib's example `core_input_keys`, which moves a ball with the arrow keys. Its `ball` is
a `Vector2`, a struct of two `float`s, filled with `type( … )` and passed by value to
`DrawCircleV`; `KEY_RIGHT` and the other keys are the values of a C `enum`.

That is the Windows answer to "install once for every program". Put each library's folder and
its binding header in one place, say `C:\tiko-libs`:

```text
C:\tiko-libs\raylib-binding.ti
C:\tiko-libs\raylib\raylib.ti
C:\tiko-libs\raylib\raylib_windows_x86_64.lib
```

Then every project that uses raylib writes `#include once "raylib-binding.ti"` and adds
`options = ["-i", "C:/tiko-libs"]` to its `tiko.toml`, or `-i C:\tiko-libs` on the command
line. Notice what is not there: the C header. Once translated, it is no longer needed to build.
For a library linked dynamically, its DLL still has to be found when the program runs: copy it
beside each program, or add its folder to `PATH`.

### A binding module

A binding can also be a **module**, which Chapter 15 introduced: a directory a program `#import`s.
A module's names are its own unless it marks them `public`, and that is true of an `#include`
inside one too. Written as **`public #include`**, the header travels with the module, whole, and
every program that imports it sees its names exactly as if it had included the header itself:

```tiko
{{#include ../examples/ch30/modules/raylib/raylib.tiko}}
```

```toml
{{#include ../examples/ch30/modgame/tiko.toml}}
```

```tiko
{{#include ../examples/ch30/modgame/main.tiko:all}}
```

`tiko build modgame`, then `out/debug/modgame 60`:

```text
{{#include ../examples/ch30/modgame/main.out}}
```

The program writes `#import "raylib"` and nothing else: `InitWindow`, the `LOG_WARNING` constant
and the `RAYWHITE` macro come from the module, and the module's `#foreignlib` links the library
into the program. The names are bare, as an `#include` would make them, not `raylib.InitWindow`,
because a C header's `#define`s and struct macros are preprocessor names, which no namespace can
hold.

This is exactly the shape of the toolchain's vendor packages. `vendor/sqlite3` is a module whose
file holds a `public #include` of its translated `sqlite3.ti`, another of its hand-written
`sqlite3-residue.ti`, and a `#foreignlib` for each link mode, chosen by the `link` its importer
wrote. Chapter 28's one line, `#import "vendor/sqlite3"`, is this section's binding module, made
by the people who ship tiko.

A plain `#include` in a module stays private: the module can use a C library to do its work
without handing the whole C interface to everyone who imports it. `public #include` outside a
module file is `TKO0369`.

To install a binding module for every program, put its folder in one directory and name that
directory in **`TIKO_PATH`**, the list of directories `#import` searches, separated by `;` on
Windows and `:` on Linux and macOS. Because a translated library's headers include one another by relative
path, any library can be a module this way, SDL's fifty-nine headers included.

## When something goes wrong

Every failure in this table happened while this chapter was being written.

| What you see | What it means | What to do |
|---|---|---|
| c2t: `TKO0120: unable to import C header`, `fatal error: 'X.h' file not found` | Clang cannot find a header the header includes | for one of the library's own, add `-I`; for a system header in the Linux pass on Windows, `--sysroot` |
| c2t exits with status 2 | the translation has TODOs | read the banner's list; finish what you need in a file of its own |
| c2t: `TKO0120` on a header that `included without matching` another | the header cannot stand alone | leave it out: it is meant only to be included |
| `TKO0329: #foreignlib found no matching library file`, with a list of names tried | no file has any of the names in the list | rename the library to one of them, usually with its target tag |
| `TKO0172: cannot make an import library for '…': it is not a 64-bit x86-64 DLL` | the DLL is the 32-bit build | download the 64-bit package |
| `undefined symbol: …` when linking statically | a system library the static library needs is not linked | add it as `"system:name"`; see *A static library brings its dependencies with it* |
| `undefined symbol:` a variable, when linking to a DLL | the program reads a variable the DLL exports | translate with `--shared-macro`; define `TIKO_LINK_DYNAMIC` before the include |
| the program exits at once, code `-1073741515` (`0xC0000135`) | Windows cannot find a DLL, or the import library names none | put the DLL beside the program; check the import library has the DLL's name |
| `error while loading shared libraries: libX.so.N` and exit 127 | Linux cannot find the `.so` | `LD_LIBRARY_PATH=.`, an rpath, or install the library |
| the program runs but reports an older version of the library | Linux found the system's copy, not yours | `LD_LIBRARY_PATH=.` or an rpath; ask the library its version |
| a C library prints pages of messages | many libraries log to standard output | look for a log level in the library: raylib's is `SetTraceLogLevel` |
| `warning TKO0833: passing different pointer types` where a callback is passed | the callback's parameters differ from the C type | make them match the translated declaration exactly |

## What it costs

- **Calling a C library costs what calling C costs**, as in Chapter 29: no wrapper, no conversion
  beyond what the C function itself would need.
- **Translating costs seconds, once.** `sqlite3.h` took three seconds, `glfw3.h` twenty, through
  WSL; SDL's fifty-nine headers, run by the loop, under five minutes. A build after that reads a
  `.ti` like any tiko header and runs no Clang.
- **A translation costs upkeep**: it belongs to one version of the library, and an upgrade means
  translating again and reading the diff.
- **Static linking costs size**: the table in *Static or dynamic* shows from 200 KB to 2.7 MB
  added to each program. **Dynamic linking costs a second file** that must be shipped and found.
- **A vendored library costs space in every project** that uses it, and keeping it current is
  your job. **An installed library costs reproducibility**: the program is built and run with
  whatever version the machine has.

## Summary

- A C library comes as a header, a static library, a shared library and, on Windows, an import
  library. On Windows take the 64-bit Visual C++ package.
- **`tiko c2t x.h --verify`** translates a header once into `x.ti`, for both targets in one file,
  laid out like the C, with layouts checked against Clang's. Only the person translating needs
  Clang, the Visual Studio Build Tools and, on Windows, a Linux sysroot through `--sysroot`.
- The **banner** names the header by SHA-256 and lists every rename and every **TODO**. Exit 2
  means TODOs: read them, and write what you need in a file of its own, never in the `.ti`.
- One header per run; includes become relative `#include once "x.ti"`, so a library's
  translations find each other with no include directory. `-I` and `-D` pass C's options;
  `--shared-macro` writes a DLL's variables for `TIKO_LINK_DYNAMIC`.
- **`#foreignlib NAME static|dynamic "path"`** links the code, relative to its own file, choosing
  `name_windows_x86_64.lib` or `name_linux_x86_64.a` by target. A static link also needs the
  system libraries the library calls, each as `"system:name"`.
- Linked **dynamically**, the library must be found when the program starts: beside the `.exe` on
  Windows; on Linux, in the system's directories, on `LD_LIBRARY_PATH`, or in an rpath:
  `-Wl -rpath,$ORIGIN` records "beside the program". A Linux program asks for its library by
  **soname**, and a missing one may silently be replaced by the system's own copy.
- A **vendored** library lives in the project: commit the `.ti`, fetch the binaries. An
  **installed** library on Linux is linked with `"system:x"`; its header still gets translated.
- **SQLite**: compile the amalgamation for a static library; its DLL needs no import library.
  **raylib**: prebuilt, translates clean. **GLFW**: needs the Linux headers to translate; its
  TODOs are Vulkan's and GLES's. **SDL3**: fifty-nine headers, translated by a loop in include
  order.
- A **binding header** holds a library's `#include` and `#foreignlib`, relative to itself. A
  **binding module** does the same with `public #include`, and is installed through `TIKO_PATH` —
  which is exactly what a vendor package is.

## Exercises

1. Run `sqlite-quick` with a file name instead of `:memory:`, once to create a table and insert a
   row, and again to select it. Then open the file with SQLite's own `sqlite3` command-line tool,
   from the *precompiled binaries* on the download page.
2. Link `sqlite-quick` statically and compare its size and its start-up with the dynamic version.
   On Linux, run both without `LD_LIBRARY_PATH` and explain the difference in what they print
   with a `select sqlite_version()`.
3. Translate `raymath.h`, which is in `vendor/raylib/` beside `raylib.h`, and read its TODOs.
   Which kind of C is most of them, and which of raymath's functions can a program still call?
4. In `raylib-window.tiko`, draw the frame number in the window with raylib's `TextFormat`, which
   is variadic like C's `printf`. What type must the argument have for `%i`?
5. Add a key callback to `glfw-window.tiko` with `glfwSetKeyCallback`, so that Escape closes the
   window by calling `glfwSetWindowShouldClose`.
6. Make `sdl-clear.tiko`'s `AppEvent` return `SDL_APP_SUCCESS` when Escape is pressed: an event
   whose `type` is `SDL_EVENT_KEY_DOWN` carries the key in `event->key.key`, to compare with
   `SDLK_ESCAPE`.
7. Make SDL a binding module, the way `modules/raylib` makes raylib one, and a `tiko build`
   project that uses it to run `sdl-clear`. Which `-i` does the project need, and why does it
   need nothing for SDL's fifty-nine headers?
