[Home](Home) › [C Header Import](Category-C-Header-Import) › **tiko c2t Tutorial**

# tiko c2t Tutorial

**Who this is for:** a tiko programmer who wants to call a C library that tiko does not ship, and
has never written a binding. You need to be able to read a little C — a `struct`, a function
declaration — but not to write it.

By the end you will have taken a C library from its source to a running tiko program: translated
its header with `tiko c2t`, finished the one part the translation leaves to you, and linked the
library both dynamically and statically with `#include` and `#foreignlib`.

**What you need:**

- A tiko toolchain. The commands below write `tiko`; use the full path if it is not on your `PATH`.
- **libclang**, which comes with LLVM. tiko already needs LLVM, so if tiko builds programs, this is
  usually already there. `tiko c2t` uses it to read C the way a C compiler does.
- **The C headers for your system**: the Visual Studio Build Tools (*Desktop development with
  C++*) on Windows, `build-essential` or your distribution's equivalent on Linux, Xcode's Command Line Tools on macOS.
- A C compiler — `clang` or `gcc` — **only** because this tutorial builds its own small library. For a
  library that ships ready-built files, you need none.

Every program in this tutorial was compiled and run on windows-x86_64, and the binding of
section 11 was also built and run on linux-x86_64, linked both ways. The output shown is the real
output.

> **Is the library already in `vendor`?** SQLite, raylib, SDL3 and cJSON are shipped with tiko,
> already translated: `#import "vendor/sqlite3" link dynamic` and you are done. See the
> [Packages and Modules Tutorial](Packages-and-Modules-Tutorial). This tutorial is for every other
> C library.

---

## Contents

| # | Section | What you learn |
|---|---|---|
| 1 | [The two halves of a C library](#1-the-two-halves-of-a-c-library) | The header, the library file, and which tiko tool handles each |
| 2 | [The library](#2-the-library) | The C library this tutorial uses |
| 3 | [Build the library](#3-build-the-library) | A DLL or `.so`, and a static archive |
| 4 | [Translate the header](#4-translate-the-header) | Running `tiko c2t`, and its exit status |
| 5 | [Read the translation](#5-read-the-translation) | What each C construct became, and why |
| 6 | [Finish the TODOs](#6-finish-the-todos) | Translating what c2t could not, in a file of your own |
| 7 | [Lay out the project](#7-lay-out-the-project) | Where the files go, and how `#foreignlib` finds them |
| 8 | [The program](#8-the-program) | `#include` plus `#foreignlib`, and a callback from C |
| 9 | [Running it](#9-running-it) | Where the DLL or `.so` must be |
| 10 | [Static linking](#10-static-linking) | One line changes |
| 11 | [One header for the whole binding](#11-one-header-for-the-whole-binding) | A binding the rest of the program includes once |
| 12 | [c2t options](#12-c2t-options) | `-o`, `-I`, `-D`, `--verify` and the rest |
| 13 | [When the library changes](#13-when-the-library-changes) | Translating again, and keeping your fixes |
| — | [Mistakes and messages](#mistakes-and-messages) | What goes wrong first, and what it looks like |

---

## 1. The two halves of a C library

A C library always comes in two parts, and a tiko program needs both:

| | The **header** (`minigeo.h`) | The **library file** (`minigeo.dll`, `libminigeo.so`, `minigeo.a`) |
|---|---|---|
| What it is | C text: the names of the functions, types and constants | Compiled machine code |
| What it tells the compiler | *what* the things are, and how to call them | *where* the code is |
| tiko's tool | **`tiko c2t`** turns it into a tiko header, `minigeo.ti`, **once** | **`#foreignlib`** links it into your program, at every build |
| In your program | `#include once "minigeo/minigeo.ti"` | `#foreignlib MINIGEO dynamic "minigeo/minigeo"` |

`tiko c2t` is a translator: you run it once, read what it wrote, finish what it marks, and keep the
`.ti` file with your project like any other source file. Your program never needs the C header or
libclang again.

---

## 2. The library

This tutorial uses a small 2-D geometry library, written for the purpose, so that you can build
every piece yourself. It is small, but it has what real C headers have: an include guard, an export
macro, constants, a function-like macro, a `struct`, an `enum`, a type that differs between Windows
and Linux, an opaque handle, a callback, and an inline function.

`minigeo.h`:

```c
/* minigeo.h -- a small 2-D geometry library in C. */
#ifndef MINIGEO_H
#define MINIGEO_H

#include <stdint.h>
#include <stdbool.h>

/* Building the DLL marks every function for export. */
#if defined(_WIN32) && defined(MINIGEO_BUILD_DLL)
    #define MGAPI __declspec(dllexport)
#else
    #define MGAPI
#endif

#define MG_VERSION_MAJOR  1
#define MG_VERSION_MINOR  2
#define MG_PI             3.14159265358979323846
#define MG_FLAG_CLOSED    (1 << 0)   /* the last point joins the first */
#define MG_FLAG_SMOOTH    (1 << 1)   /* draw with curves */
#define MG_SQUARE(x)      ((x) * (x))

/* A point in the plane. */
typedef struct mg_point {
    double x;
    double y;
} mg_point;

/* Which way three points turn. */
typedef enum mg_turn {
    MG_RIGHT    = -1,
    MG_STRAIGHT =  0,
    MG_LEFT     =  1
} mg_turn;

/* The window a path is drawn into: a different thing on each system. */
#ifdef _WIN32
typedef void *mg_window;            /* an HWND */
#else
typedef unsigned long mg_window;    /* an X11 Window */
#endif

/* A path is opaque: the library makes it, you hold a pointer to it. */
typedef struct mg_path mg_path;

/* Called once per point by mg_path_each; return false to stop early. */
typedef bool (*mg_visit_fn)(const mg_point *p, int32_t index, void *user);

MGAPI const char *mg_version(void);
MGAPI double      mg_distance(mg_point a, mg_point b);
MGAPI mg_turn     mg_turn_of(mg_point a, mg_point b, mg_point c);

MGAPI mg_path *mg_path_new(uint32_t flags);
MGAPI void     mg_path_add(mg_path *path, double x, double y);
MGAPI int32_t  mg_path_count(const mg_path *path);
MGAPI double   mg_path_length(const mg_path *path);
MGAPI int32_t  mg_path_each(const mg_path *path, mg_visit_fn visit, void *user);
MGAPI void     mg_path_free(mg_path *path);

/* Inline in the header: no symbol in the library. */
static inline double mg_dot(mg_point a, mg_point b) { return a.x * b.x + a.y * b.y; }

#endif /* MINIGEO_H */
```

<details>
<summary><code>minigeo.c</code>, the implementation (you only need it to build the library)</summary>

```c
/* minigeo.c -- the implementation of minigeo.h. */
#include <math.h>
#include <stdlib.h>
#include "minigeo.h"

struct mg_path {
    uint32_t  flags;
    int32_t   count;
    int32_t   capacity;
    mg_point *points;
};

const char *mg_version(void) { return "minigeo 1.2"; }

double mg_distance(mg_point a, mg_point b)
{
    return sqrt(MG_SQUARE(b.x - a.x) + MG_SQUARE(b.y - a.y));
}

mg_turn mg_turn_of(mg_point a, mg_point b, mg_point c)
{
    double cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    return cross > 0 ? MG_LEFT : cross < 0 ? MG_RIGHT : MG_STRAIGHT;
}

mg_path *mg_path_new(uint32_t flags)
{
    mg_path *p = calloc(1, sizeof *p);
    p->flags = flags;
    return p;
}

void mg_path_add(mg_path *path, double x, double y)
{
    if (path->count == path->capacity) {
        path->capacity = path->capacity ? path->capacity * 2 : 8;
        path->points = realloc(path->points, path->capacity * sizeof *path->points);
    }
    path->points[path->count].x = x;
    path->points[path->count].y = y;
    path->count++;
}

int32_t mg_path_count(const mg_path *path) { return path->count; }

double mg_path_length(const mg_path *path)
{
    double total = 0;
    for (int32_t i = 1; i < path->count; i++)
        total += mg_distance(path->points[i - 1], path->points[i]);
    if ((path->flags & MG_FLAG_CLOSED) && path->count > 2)
        total += mg_distance(path->points[path->count - 1], path->points[0]);
    return total;
}

int32_t mg_path_each(const mg_path *path, mg_visit_fn visit, void *user)
{
    int32_t i;
    for (i = 0; i < path->count; i++)
        if (!visit(&path->points[i], i, user))
            return i + 1;
    return path->count;
}

void mg_path_free(mg_path *path)
{
    if (path) { free(path->points); free(path); }
}
```

</details>

---

## 3. Build the library

Skip this section for a real library that publishes ready-built files: download them instead. For
`minigeo`, build two files on each system — a **shared** library, for dynamic linking, and a
**static** archive.

**Windows** (with `clang` from LLVM):

```
clang -O2 -shared -DMINIGEO_BUILD_DLL -o build/minigeo.dll minigeo.c
clang -O2 -c -o build/minigeo.o minigeo.c
llvm-ar rcs build/minigeo_windows_x86_64.a build/minigeo.o
```

`-DMINIGEO_BUILD_DLL` switches `MGAPI` to `__declspec(dllexport)`, so the DLL exports its functions.
The first command also writes `minigeo.lib`, an import library; this tutorial does not need it,
because tiko can make one from the DLL itself.

**Linux** (with `gcc`):

```
gcc -O2 -fPIC -c -o minigeo.o minigeo.c
gcc -shared -Wl,-soname,libminigeo.so -o minigeo_linux_x86_64.so minigeo.o -lm
ar rcs minigeo_linux_x86_64.a minigeo.o
```

`-fPIC` is needed for code that goes into a shared library. `-Wl,-soname,libminigeo.so` records the
name the program will look for when it starts.

The odd file names — `minigeo_windows_x86_64.a`, `minigeo_linux_x86_64.so` — are on purpose. They let
one folder hold every system's files, and [section 7](#7-lay-out-the-project) shows how tiko
picks the right one.

---

## 4. Translate the header

```
tiko c2t minigeo.h
```

That is the whole command. It writes `minigeo.ti` beside the header (`-o` chooses another place)
and prints nothing. Check its **exit status**, because it tells you whether there is work left:

| Exit status | Means |
|---|---|
| **0** | Everything was translated. |
| **2** | The file was written, and at least one part needs translating by hand: a **TODO**. |
| **1** | An error, such as a header that does not exist. Nothing was written. |

For `minigeo.h` it is **2**: one TODO. On Windows, `echo %errorlevel%` (cmd) or `$LASTEXITCODE`
(PowerShell) shows the status; on Linux and macOS, `echo $?`.

What happened behind that one command: Clang read the header **twice**, once as Windows reads it
and once as Linux does, and `tiko c2t` merged the two readings into one file. Where they agree,
the text is written once; where they differ, both versions are written under a guard. You get one
`.ti` file that works on both systems.

---

## 5. Read the translation

Here is `minigeo.ti`, exactly as written:

```freebasic
'' =============================================================================
'' minigeo.ti -- tiko header translated by c2t (tiko 0.1.0-dev) from the C header "minigeo.h"
''   source sha256 : 2dbccffa60f9eb70eb8cb74d69603c2e10ff4a29e091c35cd6598867d0c789ee
''   clang         : clang version 21.1.0
''   passes        : x86_64-pc-windows-msvc, x86_64-pc-linux-gnu
''   options       : (none)
''
'' Generated from C. Search for C2T-TODO and translate those parts by hand.
''
'' 1 item needs manual translation:
''   line 73  minigeo.h:60  C2T-TODO(static-inline)  mg_dot
'' =============================================================================

/' minigeo.h -- a small 2-D geometry library in C. '/
#pragma once

#include once "crt/long.bi"

extern "C"

'' <stdint.h>: built into tiko
'' <stdbool.h>: built into tiko

/' Building the DLL marks every function for export. '/
'' c2t: export macro MGAPI (decoration, stripped where used)

#define MG_VERSION_MAJOR 1
#define MG_VERSION_MINOR 2
#define MG_PI 3.14159265358979323846
#define MG_FLAG_CLOSED (1 shl 0)     /' the last point joins the first '/
#define MG_FLAG_SMOOTH (1 shl 1)     /' draw with curves '/
#define MG_SQUARE(x) ((x) * (x))

/' A point in the plane. '/
type mg_point
    x as float64
    y as float64
end type

/' Which way three points turn. '/
type mg_turn as int32
enum
    MG_RIGHT = -1
    MG_STRAIGHT = 0
    MG_LEFT = 1
end enum

/' The window a path is drawn into: a different thing on each system. '/
#ifdef TIKO_OS_WINDOWS
type mg_window as any ptr           /' an HWND '/
#else
type mg_window as culong            /' an X11 Window '/
#endif

/' A path is opaque: the library makes it, you hold a pointer to it. '/
type mg_path__fwd as mg_path

/' Called once per point by mg_path_each; return false to stop early. '/
type mg_visit_fn as function cdecl( byval as const mg_point ptr, byval as int32, byval as any ptr ) as boolean

declare function mg_version( ) as const zstring ptr
declare function mg_distance( byval a as mg_point, byval b as mg_point ) as float64
declare function mg_turn_of( byval a as mg_point, byval b as mg_point, byval c as mg_point ) as mg_turn

declare function mg_path_new( byval flags as uint32 ) as mg_path ptr
declare sub mg_path_add( byval path as mg_path ptr, byval x as float64, byval y as float64 )
declare function mg_path_count( byval path as const mg_path ptr ) as int32
declare function mg_path_length( byval path as const mg_path ptr ) as float64
declare function mg_path_each( byval path as const mg_path ptr, byval visit as mg_visit_fn, byval user as any ptr ) as int32
declare sub mg_path_free( byval path as mg_path ptr )

/' Inline in the header: no symbol in the library. '/
'' C2T-TODO(static-inline) minigeo.h:60 -- static inline function 'mg_dot': no symbol to link against; port the body by hand
'' static inline double mg_dot(mg_point a, mg_point b) { return a.x * b.x + a.y * b.y; }

end extern
```

It reads like the C it came from: the same order, the same comments, the same blank lines. That is
deliberate. You are meant to read it, and to compare it with the C when you are unsure.

### The banner

The block at the top records where the file came from: the header's name and SHA-256, the tiko
and Clang versions (yours will show your own), the two systems it was read for, the options used,
and **every TODO, with its line in the `.ti` and in the `.h`**. There is no date, so translating the
same header again gives the same bytes. Read the TODO list first: it is your to-do list.

### Line by line

| C | tiko | Why |
|---|---|---|
| `/* … */` | `/' … '/` | tiko's block comment |
| `#ifndef MINIGEO_H` … `#endif` | `#pragma once` | The include guard, said the tiko way |
| `#include <stdint.h>`, `<stdbool.h>` | a comment | `int32_t`, `bool` and the rest are built into tiko |
| `MGAPI` | removed | An export macro decorates declarations and declares nothing; tiko does not need it |
| `1 << 0` | `1 shl 0` | tiko's shift operator |
| `MG_SQUARE(x)` | `#define MG_SQUARE(x) ((x) * (x))` | A simple function-like macro translates directly |
| `double` | `float64` | Every type is written by its exact size, the same on every system |
| `struct mg_point { … }` | `type mg_point … end type` | Same fields, same order, same layout as C |
| `typedef enum mg_turn { … } mg_turn` | `type mg_turn as int32`, then an `enum` of its constants | The type keeps C's size (4 bytes); the constants keep C's names and values |
| `#ifdef _WIN32` | `#ifdef TIKO_OS_WINDOWS` | C's platform macros become tiko's |
| `unsigned long` | `culong`, from `crt/long.bi` | C's `long` is 4 bytes on Windows and 8 on Linux and macOS; `culong` follows the system |
| `typedef struct mg_path mg_path` (never defined) | `type mg_path__fwd as mg_path`, and `mg_path ptr` | An opaque handle: you only ever hold a pointer to it |
| `bool (*mg_visit_fn)(…)` | `type mg_visit_fn as function cdecl( … ) as boolean` | A pointer to a function C will call |
| `const char *` | `const zstring ptr` | A C string |
| `void f(void)`, returning nothing | `declare sub f( )` | |
| everything | inside `extern "C"` … `end extern` | The names are C's: case kept, nothing added, so the linker finds them |

### The TODO

`mg_dot` is a **`static inline`** function. Its code is in the header, not in the library, so there
is no `mg_dot` in `minigeo.dll` for tiko to call. `tiko c2t` cannot turn C statements into tiko
statements, so it marks the place and quotes the C:

```freebasic
'' C2T-TODO(static-inline) minigeo.h:60 -- static inline function 'mg_dot': no symbol to link against; port the body by hand
'' static inline double mg_dot(mg_point a, mg_point b) { return a.x * b.x + a.y * b.y; }
```

Everything else in the file is complete. A program that never calls `mg_dot` could use the `.ti` as
it is.

A **TODO** always means API that is missing until you supply it. You may also meet a **NOTE**,
which is only information: the translation is complete, but something deserves a look. The
[tiko c2t](C2t#todos-and-notes) reference lists every reason for both.

---

## 6. Finish the TODOs

You could edit `minigeo.ti` directly. **Don't.** When the library ships a new version you will
translate its header again, and the new `.ti` would overwrite your edit. Put your translations in a
file of your own beside it:

`minigeo-extra.ti`:

```freebasic
'' minigeo-extra.ti -- what c2t could not translate from minigeo.h, by hand.
#pragma once
#include once "minigeo.ti"

'' minigeo.h:60, C2T-TODO(static-inline): mg_dot is a static inline function, so the
'' library has no symbol for it. Its body is one line, ported here.
private function mg_dot( byval a as mg_point, byval b as mg_point ) as float64
    return a.x * b.x + a.y * b.y
end function
```

`private` keeps it to the file that includes it, as C's `static` does: two source files of your
program can both include this header without the linker seeing two `mg_dot`s.

Each kind of TODO has its own usual answer:

| TODO reason | What to do |
|---|---|
| `static-inline` | Port the body, as above. If you never call it, leave it. |
| `function-like-macro` | Write a `#define` or a small `private function` that does the same |
| `macro` | Write the constant's value yourself, often from the library's documentation |
| `system-header` | Include the tiko header that declares the same things, or declare the few names you need |
| `conditional`, `branch-unparsed` | Decide which branch your program needs, and translate that one |

The exit status `2` and the banner's list tell you how many there are. When you have dealt with each
one, write in your extra file which ones you handled and how, as above, so the next person knows.

---

## 7. Lay out the project

```
geoapp/
    main.tiko
    minigeo/
        minigeo.h                    the C header (kept, to translate again later)
        minigeo.ti                   written by tiko c2t
        minigeo-extra.ti             written by you
        minigeo_windows_x86_64.dll   minigeo.dll, renamed
        minigeo_windows_x86_64.a     static archive, Windows
        minigeo_linux_x86_64.so      shared library, Linux
        minigeo_linux_x86_64.a       static archive, Linux
```

You need only the files for the systems and the kind of linking you use.

`#foreignlib` names a library **without** its ending or its system: `"minigeo/minigeo"`. tiko
then tries these names, in this order, and takes the first file that exists:

```
minigeo/minigeo_<os>_<arch><ending>
minigeo/minigeo_<os><ending>
minigeo/minigeo_<arch><ending>
minigeo/minigeo<ending>
```

| | windows-x86_64 | linux-x86_64 | macos-arm64 |
|---|---|---|---|
| `<os>_<arch>` | `windows_x86_64` | `linux_x86_64` | `macos_arm64` |
| endings for `static` | `.a`, `.lib` | `.a` | `.a` |
| endings for `dynamic` | `.dll.a`, `.lib`, `.dll` | `.so` | `.dylib` |

So on Windows, `dynamic` finds `minigeo_windows_x86_64.dll`, and `static` finds
`minigeo_windows_x86_64.a`; on Linux, the two `linux` files. The path is relative to the file that
contains the `#foreignlib` line, not to the folder you build from. One source file, every system,
no `#ifdef`.

**A DLL on its own is enough.** When `dynamic` finds only a `.dll`, tiko reads the functions it
exports and makes the import library while it links. The DLL keeps its own name inside — here
`minigeo.dll` — and that is the name the program will look for when it starts, whatever the file in
`minigeo/` is called.

---

## 8. The program

`main.tiko`:

```freebasic
#include once "minigeo/minigeo.ti"         '' the C header, translated by tiko c2t
#include once "minigeo/minigeo-extra.ti"   '' the part we translated by hand
#foreignlib MINIGEO dynamic "minigeo/minigeo"

'' mg_path_each calls this once for every point of a path. It is C that calls it,
'' so it uses C's calling convention: cdecl.
function ShowPoint cdecl( byval p as const mg_point ptr, byval index as int32, _
                          byval user as any ptr ) as boolean
    print "  point " & index & ": (" & p->x & ", " & p->y & ")"
    return true                     '' false would stop the walk
end function

print *mg_version( ) & ", header version " & MG_VERSION_MAJOR & "." & MG_VERSION_MINOR

dim as mg_point a = ( 0, 0 ), b = ( 3, 4 ), c = ( 3, 8 )
print "distance from a to b: " & mg_distance( a, b )
print "b . c = " & mg_dot( b, c )

select case mg_turn_of( a, b, c )
case MG_LEFT     : print "a -> b -> c turns left"
case MG_RIGHT    : print "a -> b -> c turns right"
case MG_STRAIGHT : print "a, b and c lie on one line"
end select

dim as mg_path ptr box = mg_path_new( MG_FLAG_CLOSED )
mg_path_add( box, 0, 0 )
mg_path_add( box, 4, 0 )
mg_path_add( box, 4, 3 )
mg_path_add( box, 0, 3 )
print "the box has " & mg_path_count( box ) & " points; its perimeter is " & mg_path_length( box )
mg_path_each( box, @ShowPoint, nullptr )
mg_path_free( box )
```

The three lines at the top are the whole binding:

- **`#include once "minigeo/minigeo.ti"`** brings in the declarations. From here on the program can
  name `mg_point`, `MG_LEFT` and `mg_path_new` exactly as C does.
- **`#include once "minigeo/minigeo-extra.ti"`** brings in your hand-written `mg_dot`.
- **`#foreignlib MINIGEO dynamic "minigeo/minigeo"`** links the library. `MINIGEO` is a name for
  this set of libraries (any name will do); `dynamic` says which kind of file to look for.

And the C library is used as a C programmer would use it:

- **Structs by value.** `mg_distance( a, b )` passes two `mg_point`s; `( 0, 0 )` fills one in.
- **Text.** `mg_version( )` returns a `const zstring ptr`; `*` reads the string it points to.
- **An enum.** `mg_turn_of` returns an `mg_turn`, compared with `MG_LEFT` and the others.
- **An opaque handle.** `mg_path_new` returns an `mg_path ptr`. You never look inside it; you hand it
  back to the library, and free it with `mg_path_free` when you are done.
- **A callback.** `@ShowPoint` is a pointer to your function, which the library calls once per point.
  Its parameters must match `mg_visit_fn` exactly, and it is `cdecl` because C calls it.

```
tiko main.tiko
```

---

## 9. Running it

Run `main.exe` straight after building and it stops at once. Windows says that `minigeo.dll` was
not found; Linux says `error while loading shared libraries: libminigeo.so`.

**`#foreignlib` links a dynamic library, but does not copy it.** The library file must be where
the system looks for it when the program starts:

- **Windows:** beside the `.exe`, under the name the DLL gives itself:

  ```
  copy minigeo\minigeo_windows_x86_64.dll minigeo.dll
  ```

- **Linux:** beside the program, under its soname. tiko gives a program that links a shared library
  a run path of `$ORIGIN`, so "beside the program" is a place the loader looks:

  ```
  cp minigeo/minigeo_linux_x86_64.so libminigeo.so
  ```

Now:

```
minigeo 1.2, header version 1.2
distance from a to b: 5
b . c = 41
a -> b -> c turns left
the box has 4 points; its perimeter is 14
  point 0: (0, 0)
  point 1: (4, 0)
  point 2: (4, 3)
  point 3: (0, 3)
```

When you ship the program, ship that library file with it.

---

## 10. Static linking

Change `dynamic` to `static` and build again:

```freebasic
#foreignlib MINIGEO static "minigeo/minigeo"
```

tiko now finds `minigeo_windows_x86_64.a` (or `minigeo_linux_x86_64.a`) and copies the library's
code into the program. The output is the same, and no DLL or `.so` is needed beside it: the
program is one file.

| | `static` | `dynamic` |
|---|---|---|
| The library's code | inside your program | in its own file |
| What you ship | the program | the program and the library file |
| Updating the library | rebuild the program | replace the library file |

The header does not change between the two: the same `minigeo.ti` declares the same functions,
and only the `#foreignlib` line says where their code comes from.

---

## 11. One header for the whole binding

Three lines at the top of every file that uses minigeo is two lines too many. Put them in one
header beside the others:

`minigeo/geo.ti`:

```freebasic
'' geo.ti -- everything a program needs to use minigeo: one #include.
#pragma once

#include once "minigeo.ti"          '' the C header, translated by tiko c2t
#include once "minigeo-extra.ti"    '' what the translation left to us

#ifdef MINIGEO_STATIC
    #foreignlib MINIGEO static "minigeo"
#else
    #foreignlib MINIGEO dynamic "minigeo"
#endif
```

Now the paths are relative to `geo.ti`, so they are just `"minigeo.ti"` and `"minigeo"`. Any file of
the program writes one line:

```freebasic
#include once "minigeo/geo.ti"

dim as mg_path ptr box = mg_path_new( MG_FLAG_CLOSED )
mg_path_add( box, 0, 0 )
mg_path_add( box, 4, 0 )
mg_path_add( box, 4, 3 )
print "perimeter:"; mg_path_length( box )
mg_path_free( box )
```

```
perimeter: 12
```

and the kind of link is chosen when you build:

```
tiko box.tiko                      (dynamic: copy the DLL or .so beside it)
tiko -d MINIGEO_STATIC box.tiko    (static: one file)
```

Two files of the program may both include `geo.ti`: `#pragma once` reads it once, and a second
`#foreignlib` with the same name and the same library is allowed.

The whole `minigeo/` folder is now a binding you can copy into another project. To share it as a
module that other programs `#import`, with the link mode written on the import line, see how the
toolchain's own [vendor packages](Vendor-Packages#inside-a-vendor-package) are made: they are this
same layout, wrapped in a module.

---

## 12. c2t options

```
tiko c2t <in.h> [-o <out.ti>|-] [-I <dir>] [-D <name>[=<value>]] [-U <name>]
                [--pass "<clang args>"] [--shared-macro <name>[=<value>]]
                [--sysroot <dir>] [--verify]
```

The ones you will use first:

| Option | Use it when |
|---|---|
| `-o <file>` | You want the `.ti` somewhere else, or named differently. `-o -` prints it instead. |
| `-I <dir>` | The header includes other headers of the library that are in another folder. |
| `-D NAME[=value]` | The library's documentation says to define something before including it. The `#define` is also written into the `.ti`, so tiko sees what C saw. |
| `--verify` | You want proof the types match C. tiko compiles the translation for both systems and compares every struct's size, alignment and field offsets, and every integer constant, with Clang's. Something that differs is marked as a TODO instead of being left wrong. |
| `--macos-sysroot <sdk>` | You want a macOS reading too: on a Mac, `--macos-sysroot $(xcrun --show-sdk-path)` adds a third pass for macos-arm64. |
| `--sysroot <dir>` | You are on Windows, and the header includes a system header such as `<stdio.h>`: the Linux reading needs Linux's headers. The WSL root works, `--sysroot //wsl.localhost/Ubuntu`. `minigeo.h` includes only headers built into tiko, so it needs none. |

**One header per run.** If the library has several headers that include each other, translate each
with its own run, into the same folder, in include order. An `#include "other.h"` in C becomes
`#include once "other.ti"` in the translation.

The [tiko c2t](C2t) reference has every option, every TODO and NOTE reason, and the table of
system headers.

---

## 13. When the library changes

A new version of the library comes with a new header. Translate it again, over the old `.ti`:

```
tiko c2t minigeo.h
```

Because the banner has no date and the layout follows the C, **a diff of the old and new `.ti`
shows exactly what changed in the library's API**: a new function, a field added to a struct, a
constant with a new value. Then:

1. Read the banner's TODO list. A TODO that is new needs a line in `minigeo-extra.ti`; one that is gone
   needs its line removed, or the program will declare the name twice.
2. Replace the library files in `minigeo/`.
3. Rebuild your program, and fix whatever the new API changed.

Your hand-written file was never touched, which is why it is a file of its own.

---

## Mistakes and messages

**The `#foreignlib` line is missing.** The program compiles, but the link fails, naming the first
function it could not find:

```
lld-link: error: undefined symbol: mg_version
>>> referenced by nolib.exe.1.o:(main)
tiko-lang: error TKO0116: link failed (exit 1)
```

**The library file is not where `#foreignlib` looks.** The message lists every file it tried:

```
main.tiko(3,1): error TKO0329: #foreignlib found no matching library file: MINIGEO dynamic minigeo/minigeo; tried:
    minigeo/minigeo_windows_x86_64.dll.a
    minigeo/minigeo_windows_x86_64.lib
    minigeo/minigeo_windows_x86_64.dll
    minigeo/minigeo_windows.dll.a
    minigeo/minigeo_windows.lib
    minigeo/minigeo_windows.dll
    minigeo/minigeo_x86_64.dll.a
    minigeo/minigeo_x86_64.lib
    minigeo/minigeo_x86_64.dll
    minigeo/minigeo.dll.a
    minigeo/minigeo.lib
    minigeo/minigeo.dll
```

Check the folder, the name, and the ending for the kind (`static` or `dynamic`).

**A TODO was not finished.** Calling `mg_dot` without `minigeo-extra.ti`:

```
nodot.tiko(5,7): error TKO0743: 'mg_dot' is not declared
```

**The program builds and will not start.** A dynamic library is not beside it; see
[section 9](#9-running-it).

**`tiko c2t` cannot read the header.**

```
tiko-lang: error TKO0174: cannot read the C header 'nothere.h'
```

The exit status is 1, and nothing was written.

**`tiko c2t` cannot find libclang.** It says so and lists where it looked. Set `TIKO_LIBCLANG` to the
full path of `libclang.dll` or `libclang.so`.

---

### See also

- [tiko c2t](C2t) — the reference: every option, TODO and NOTE
- [`#foreignlib`](modern-Foreignlib) — every rule for finding and linking a library file
- [Vendor Packages](Vendor-Packages) — C libraries the toolchain ships already translated
- [Packages and Modules Tutorial](Packages-and-Modules-Tutorial) — `#import`, `std` and `vendor`
- [`#include`](procedures-Include) · [`Extern...End Extern`](Extern-End-Extern)

---

[Home](Home) · [Feature Index](Feature-Index)
