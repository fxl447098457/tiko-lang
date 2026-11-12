[Home](Home) › [C Header Import](Category-C-Header-Import) › **#cinclude Tutorial**

# #cinclude Tutorial

> 📘 **Reference:** [#cinclude](modern-Cinclude) · **Next:** [#foreignlib Tutorial](modern-Foreignlib-tutorial)

This tutorial shows you how to use a C library from tiko with `#cinclude`. You will call the C runtime, build a tiny C library of your own and use it, look at what tiko makes from a C header, hand a tiko function to C as a callback, and call the Windows API. No earlier experience with C libraries is needed.

---

## 1. Three words first

**Header.** A C library describes itself in a *header*, a `.h` file. It lists the library's functions, the types they use, and its constants. It holds no code.

**Library.** The code itself is in a *library* file: a `.lib` or `.dll` on Windows, a `.a` or `.so` on Linux, a `.a` or `.dylib` on macOS.

**Binding.** Before tiko can call a C function, it must know the function's name, its parameters and its result. A *binding* is the list of those declarations, written in tiko.

You could write a binding by hand, with one `declare` for each function and one `type` for each struct. That works, but it is slow, and every line is a copy of something the header already says. A copy can be wrong: one `int32` where C has a 64-bit number, and every field after it is read from the wrong place, with no error to tell you.

`#cinclude` does that job for you. It hands the library's **own header** to **clang**, a real C compiler, and turns what clang reports into tiko declarations. You write one line:

```freebasic
#cinclude once "shapes.h"
```

and every function, type and constant in `shapes.h` is ready to use.

`#cinclude` only declares things. To link the library's code into your program, add a [`#foreignlib`](modern-Foreignlib) line, which section 4 shows. The [#foreignlib Tutorial](modern-Foreignlib-tutorial) covers linking in detail.

## 2. What you need

| | Windows | Linux | macOS |
|---|---|---|---|
| tiko and LLVM | as for any tiko program | as for any tiko program | as for any tiko program |
| C headers | **Visual Studio Build Tools**, with *Desktop development with C++* and the Windows SDK | your distribution's C compiler (`build-essential` on Ubuntu) | Xcode's **Command Line Tools** |

`#cinclude` uses **libclang**, which comes with the LLVM install that tiko already needs. tiko loads it only when a program has a `#cinclude`, so programs without one never need it.

On Windows, almost every C header includes the C runtime's own headers (`stdio.h`, `string.h` and the rest), and those come with Visual Studio. tiko itself does not need Visual Studio. Only `#cinclude` does.

## 3. Your first `#cinclude`

The C runtime library is always linked into a tiko program, so you can call it with nothing but its headers. Save this as `first.tiko`:

```freebasic
'' first.tiko -- call two functions from the C runtime library,
'' declared by the C runtime's own headers.
#cinclude once "string.h"
#cinclude once "ctype.h"

dim word as zstring * 32 = "tiko"
print "strlen( word ) is "; str( strlen( word ) )
print "toupper( 'a' ) is "; chr( toupper( asc( "a" ) ) )
```

Build it and run it:

```bash
tiko first.tiko
./first
```

```
strlen( word ) is 4
toupper( 'a' ) is A
```

`strlen` and `toupper` are not declared anywhere in your program. They came from `string.h` and `ctype.h`.

`once` works as it does for `#include`: the header is read only the first time the directive is reached.

If you see `TKO0335: #cinclude needs libclang`, tiko could not find libclang. Check that LLVM is installed, or set the `TIKO_LIBCLANG` environment variable to the full path of the libclang library.

## 4. A C library of your own

Now make a small C library and use it, the way you would use any library you download. Create this layout:

```
shapes-app/
    shapes-demo.tiko
    vendor/shapes/shapes.h
    vendor/shapes/shapes.c
```

`vendor/shapes/shapes.h`, the header:

```c
/* shapes.h -- a tiny C library, for trying out #cinclude */
#ifndef SHAPES_H
#define SHAPES_H

#define SHAPES_VERSION   3
#define SHAPES_MAX_NAME  16

typedef enum { SHAPE_CIRCLE, SHAPE_SQUARE } ShapeKind;

typedef struct Shape {
    ShapeKind kind;
    double    size;                    /* radius or side */
    char      name[SHAPES_MAX_NAME];
} Shape;

/* called once for each shape by shapes_each() */
typedef void (*ShapeVisitor)(const Shape *shape, void *user);

double shape_area(const Shape *shape);
void   shapes_each(const Shape *list, int count, ShapeVisitor visit, void *user);

/* a function-like macro: tiko does not import these */
#define SHAPE_IS_ROUND(s) ((s)->kind == SHAPE_CIRCLE)

#endif
```

`vendor/shapes/shapes.c`, the code:

```c
/* shapes.c -- the code behind shapes.h */
#include "shapes.h"

double shape_area(const Shape *shape)
{
    if (shape->kind == SHAPE_CIRCLE)
        return 3.14159265358979 * shape->size * shape->size;
    return shape->size * shape->size;
}

void shapes_each(const Shape *list, int count, ShapeVisitor visit, void *user)
{
    for (int i = 0; i < count; i++)
        visit(&list[i], user);
}
```

### Build the C library

Compile `shapes.c` with clang and put the result in a *static library*, a file of compiled code that the linker copies into your program. Run these from `shapes-app`.

On Windows:

```bash
clang -c -O2 vendor/shapes/shapes.c -o shapes.obj
llvm-lib /out:vendor/shapes/shapes_windows_x86_64.lib shapes.obj
```

On Linux:

```bash
clang -c -O2 vendor/shapes/shapes.c -o shapes.o
ar rcs vendor/shapes/shapes_linux_x86_64.a shapes.o
```

The `_windows_x86_64` and `_linux_x86_64` endings tell `#foreignlib` which platform each file is for. The [#foreignlib Tutorial](modern-Foreignlib-tutorial) explains them.

### Use it from tiko

`shapes-demo.tiko`:

```freebasic
'' shapes-demo.tiko -- use the shapes library through its own C header.
#cinclude once "vendor/shapes/shapes.h"
#foreignlib SHAPES static "vendor/shapes/shapes"

'' shapes_each() calls this once for each shape in the list.
sub ShowShape cdecl( byval shape as const Shape ptr, byval user as any ptr )
    dim total as float64 ptr = user
    dim area as float64 = shape_area( shape )
    *total += area
    print using "&: ##.##"; shape->name; area
end sub

print "shapes library, version "; str( SHAPES_VERSION )

dim list( 0 to 2 ) as Shape
list( 0 ).kind = SHAPE_CIRCLE : list( 0 ).size = 1 : list( 0 ).name = "unit circle"
list( 1 ).kind = SHAPE_SQUARE : list( 1 ).size = 2 : list( 1 ).name = "square"
list( 2 ).kind = SHAPE_CIRCLE : list( 2 ).size = 3 : list( 2 ).name = "big circle"

dim total as float64
shapes_each( @list( 0 ), 3, @ShowShape, @total )
print using "total area: ##.##"; total
print "one Shape takes "; str( sizeof( Shape ) ); " bytes"
```

```bash
tiko shapes-demo.tiko
./shapes-demo
```

```
shapes library, version 3
unit circle:  3.14
square:  4.00
big circle: 28.27
total area: 35.42
one Shape takes 32 bytes
```

**What each part does:**

| Line | Why |
|---|---|
| `#cinclude once "vendor/shapes/shapes.h"` | reads the header. `Shape`, `ShapeKind`, `SHAPE_CIRCLE`, `SHAPES_VERSION`, `shape_area` and `shapes_each` all come from here. |
| `#foreignlib SHAPES static "vendor/shapes/shapes"` | links the library file for the platform you build on. The path is relative to **this source file**. |
| `sub ShowShape cdecl( ... )` | C calls this function, so its parameters must match C's `ShapeVisitor` type exactly (section 6). |
| `list( 0 ).name = "unit circle"` | C's `char name[16]` is a `zstring * 16` in tiko, so a string can be assigned to it. |
| `@list( 0 )` | C's `&list[0]`: the address of the first shape. |
| `sizeof( Shape )` | 32 bytes, the same size C gives the struct. tiko checks that for every struct it imports (section 10). |

You can build from any directory. `tiko shapes-app/shapes-demo.tiko` run from the folder above works too, because tiko also looks for the header beside the file that names it (section 7).

## 5. Look at what tiko made

`-cimport` writes the binding to a file instead of using it, so you can read it:

```bash
tiko -cimport vendor/shapes/shapes.h -cimport-out shapes_binding.ti
```

Use `-cimport-out -` to print it instead. For `shapes.h` you get:

```freebasic
'' Generated by tiko -cimport. Do not edit.
''
''   header      : vendor/shapes/shapes.h
''   target      : windows-x86_64 (x86_64-pc-windows-msvc)
''   clang       : 21
''   importer    : schema 1
''   C files read: 2
''
'' 7 declarations.

#pragma once

extern "C"

type ShapeKind as long
enum
	SHAPE_CIRCLE = 0
	SHAPE_SQUARE = 1
end enum
type Shape
	kind as ShapeKind
	size as double
	name as zstring * 16
end type
type ShapeVisitor as sub cdecl( byval as const Shape ptr, byval as any ptr )
declare function shape_area cdecl alias "shape_area" ( byval shape as const Shape ptr ) as double
declare sub shapes_each cdecl alias "shapes_each" ( byval list as const Shape ptr, byval count as long, byval visit as ShapeVisitor, byval user as any ptr )
const SHAPES_VERSION = 3
const SHAPES_MAX_NAME = 16

end extern
```

This is the binding you would otherwise have written by hand.

The binding is made **for the platform you build for**, from what clang reports there, so it can differ a little between platforms. On Linux the banner says `linux-x86_64`, and `ShapeKind` is a `ulong`, because that is the type the C compiler gives this enum there. Your code does not change.

Here is how the common C types appear:

| C | tiko |
|---|---|
| `int`, `unsigned int` | `long`, `ulong` (32 bits, the same types as `int32` and `uint32`) |
| `long long` | `longint` (64 bits, the same as `int64`) |
| `double`, `float` | `double`, `single` (the same as `float64` and `float32`) |
| `char *`, `const char *` | `zstring ptr`, `const zstring ptr` |
| `char name[16]` | `name as zstring * 16` |
| `void *` | `any ptr` |
| `Shape *` | `Shape ptr` |
| `size_t` | `size_t`, an unsigned 64-bit integer |
| an enum | a 32-bit integer type, plus its values as constants |
| an opaque handle (`typedef struct db db;`, never defined) | `type db as any`, so you only ever hold a `db ptr` |

Every function keeps its exact C name in an `alias "..."`, so the linker finds it even when tiko has to rename it (section 8).

## 6. Callbacks: when C calls your code

Some C functions take a *callback*, a function of yours that the library calls. `shapes_each` is one: it calls a `ShapeVisitor` once for each shape. The C type is

```c
typedef void (*ShapeVisitor)(const Shape *shape, void *user);
```

so your tiko function must be a `sub` with exactly these parameters:

```freebasic
sub ShowShape cdecl( byval shape as const Shape ptr, byval user as any ptr )
```

tiko compares your function with the imported type. If they differ, you get a warning, here for a callback that takes an `int32` where C passes a pointer:

```
warning TKO0833: passing different pointer types: a 'sub( as shape ptr, as int32 ) ptr' for a 'sub( as const shape ptr, as any ptr ) ptr' parameter
```

**Treat this warning as an error.** The program still builds, but C will hand your function values of the wrong type, and it will read garbage.

The `void *user` parameter is how a callback gets at your data. `shapes-demo.tiko` passes `@total`, and the callback turns it back into a `float64 ptr`.

About calling conventions: on Windows, Linux and macOS there is only one way C calls a function, so you can write `cdecl` or leave the convention out. Both match. Do not write `pascal`: it reverses the order of the arguments, and tiko warns about it.

## 7. Where tiko looks for a header

For `#cinclude once "vendor/shapes/shapes.h"`, tiko looks:

1. under the **working directory**, the folder you ran `tiko` in;
2. **beside the file** that contains the `#cinclude`;
3. in each folder named with `-cinclude`.

If the header is not found, the error says what tiko tried:

```
error TKO0336: unable to import C header vendor/shapes/shape.h
note: clang: tiko-cimport.c:1:10: fatal error: 'vendor/shapes/shape.h' file not found
note: a header is found by the path given, then beside the file that names it, then in each -cinclude directory
```

### Headers that include other headers

A library header often includes the library's other headers with angle brackets:

```c
#include <colors/rgb.h>
```

clang looks for those only in its include folders, so tell it where they are with `-cinclude`:

```bash
tiko app.tiko -cinclude vendor/colors/include
```

Without it, clang reports `'colors/rgb.h' file not found with <angled> include`.

A `-cinclude` folder given on the command line, or in a `#cmdline` line, is relative to the **working directory**. To make a project build from anywhere, put it in the project's `tiko.toml`, where every path is relative to `tiko.toml` itself:

```toml
[package]
name = "colors"

[target.colors]
main    = "app.tiko"
options = ["-cinclude", "vendor/colors/include"]
```

and build with `tiko build`. See [tiko build](Category-Tiko-Build).

> ⚠️ **A header under the working directory wins.** It is searched before the one beside the file. Give vendored headers a specific path (`vendor/shapes/shapes.h`, not just `shapes.h`), so that a stray file of the same name can never be picked up instead.

## 8. What comes across, and what does not

**Comes across:** structs and unions, enums, typedefs, functions (including ones with `...` arguments), function-pointer types, global variables, and *object-like* macros that are numbers, such as `#define SHAPES_VERSION 3`. clang works out each macro's value, so `#define BUFFER_SIZE (4 * 1024)` arrives as `const BUFFER_SIZE = 4096`.

**Does not come across:**

- **Function-like macros.** `SHAPE_IS_ROUND(s)` takes arguments, so it is a piece of C code rather than a value. tiko does not translate C code. Using it gives `TKO0743: 'shape_is_round' is not declared`. Write the test yourself:

  ```freebasic
  if shape->kind = SHAPE_CIRCLE then print "round"
  ```

- **Macros that are strings**, such as `#define GREETING "hello"`. Write the constant yourself.
- **`static inline` functions.** They have no code in the library to link to.
- **`NULL`.** Use tiko's `nullptr`.
- **C++.** `#cinclude` reads C headers only.

When a declaration cannot be expressed in tiko, it is left out, and the top of the binding says so. On Windows, `tiko -cimport math.h -cimport-out -` lists:

```
'' 5 declarations were skipped:
''     define    INFINITY                    value is infinity or NaN, which has no FreeBASIC literal
''     define    HUGE_VAL                    value is infinity or NaN, which has no FreeBASIC literal
''     define    HUGE_VALF                   value is infinity or NaN, which has no FreeBASIC literal
''     define    HUGE_VALL                   value is infinity or NaN, which has no FreeBASIC literal
''     define    NAN                         value is infinity or NaN, which has no FreeBASIC literal
```

On Linux the list is longer, because there C's `long double` is an 80-bit number, and tiko has no type that size. Everything else in `math.h` is there.

### Renamed names

tiko does not tell upper and lower case apart, and it has words of its own, so now and then a C name has to change. The top of the binding lists every change. Importing `stdlib.h` gives:

```
'' 4 names were changed:
''     procedure  exit -> exit_  (FreeBASIC reserved)
''     procedure  _Exit -> _Exit_2  (case-insensitive collision)
''     procedure  abs -> abs_  (FreeBASIC reserved)
''     procedure  system -> system_  (FreeBASIC reserved)
```

`abs` is already a tiko function, so C's `abs()` is called `abs_()`:

```freebasic
#cinclude once "stdlib.h"
#cinclude once "math.h"

print abs_( -5 ); cos_( 0.0 )
```

```
 5 1
```

In the same way, `math.h`'s `sin`, `cos`, `exp`, `log` and a few others gain a `_`. The `alias` keeps the real name, `abs`, for the linker. In your own code you would normally use tiko's built-in `abs` and `cos`. The point is what happens to a library's names: when one is changed, the list at the top of the binding tells you its new spelling.

## 9. The Windows API

`windows.h` is just another header. This program asks Windows for the computer's name and the screen size, and counts the open windows with a callback:

```freebasic
'' winapi.tiko -- a few Windows API calls, straight from windows.h.
#define UNICODE
#cinclude once "windows.h"

'' EnumWindows() calls this once for each top-level window.
function CountWindow( byval hwnd as HWND, byval lp as LPARAM ) as BOOL
    dim count as int32 ptr = cast( int32 ptr, lp )
    *count += 1
    return TRUE
end function

dim buffer as wstring * 256
dim size as DWORD = 256
if GetComputerName( @buffer, @size ) then
    dim computer as ustring = buffer
    print "This computer is called "; computer
end if

print "The screen is"; GetSystemMetrics( SM_CXSCREEN ); " by"; _
    GetSystemMetrics( SM_CYSCREEN ); " pixels"

dim count as int32
EnumWindows( @CountWindow, cast( LPARAM, @count ) )
print "There are"; count; " top-level windows"
```

```bash
tiko winapi.tiko
./winapi
```

The output depends on your computer, for example:

```
This computer is called MY-PC
The screen is 1646 by 1029 pixels
There are 445 top-level windows
```

Two things to notice:

- **`#define UNICODE` picks the wide functions.** Many Windows functions come in two versions, `GetComputerNameA` for 8-bit text and `GetComputerNameW` for UTF-16 text. `GetComputerName` is a name for one of them. With `#define UNICODE` before the `#cinclude` it means the `W` version, which takes a `wstring`. Without it, it means the `A` version, which takes a `zstring`. You can always call either one by its full name.
- **`CountWindow` has no calling convention**, and needs none (section 6).

## 10. tiko checks every struct

For every struct and union it imports, tiko works out the size and the position of each field **itself**, and compares that with what clang says. If the two do not agree, tiko leaves the struct out and lists it, with both layouts, under *declarations were skipped*. You can still pass pointers to it, but a variable of the struct itself is an error (`TKO0810: '...' is an incomplete type`) instead of a program that quietly reads the wrong bytes.

This check is the reason `#cinclude` is safer than a hand-written binding: nothing checks a hand-written `type` against C. `-cnoverify` turns the check off. There is no good reason to use it.

## 11. Speed: the binding cache

The first build that reads a big header takes a while. A program that includes `windows.h` takes a few seconds the first time. tiko then keeps the binding in a cache, and the next build takes well under a second.

tiko notices changes by itself. Editing a header, changing a C option or upgrading clang makes it read the header again. Two options control the cache:

- `-cnocache` reads the header again and leaves the cache alone;
- `-ccachedir <dir>` keeps the cache in `<dir>` instead of your user cache folder.

## 12. Sharing a binding

### A binding header

When several programs use one library, move the `#cinclude` and `#foreignlib` lines into a `.ti` file next to the library:

```freebasic
'' shapes.ti -- the shapes library for tiko: its header, and the
'' library file to link. Both paths are relative to this file.
#pragma once

#cinclude once "shapes/shapes.h"
#foreignlib SHAPES static "shapes/shapes"
```

Saved as `vendor/shapes.ti`, a program needs one line:

```freebasic
#include once "shapes.ti"

dim sq as Shape
sq.kind = SHAPE_SQUARE
sq.size = 5
print "a 5 by 5 square has area"; shape_area( @sq )
```

```bash
tiko usebind.tiko -i vendor
```

```
a 5 by 5 square has area 25
```

`-i vendor` tells tiko where to find `shapes.ti`. Both paths inside `shapes.ti` are relative to `shapes.ti`, so the `vendor` folder can live anywhere.

### A binding module

A binding can also be a [module](https://tiko-lang.net/book/ch15-modules-packages.html). Inside a module, write **`public #cinclude`**, and every program that imports the module sees the header's names. A plain `#cinclude` inside a module keeps them private to the module.

`modules/shapes/shapes.tiko`:

```freebasic
'' The shapes library as a module. 'public #cinclude' hands the
'' header's names to every program that imports this module.
#module "shapes"

public #cinclude once "../../vendor/shapes/shapes.h"
#foreignlib SHAPES static "../../vendor/shapes/shapes"
```

```freebasic
#import "shapes"

dim sq as Shape
sq.kind = SHAPE_SQUARE
sq.size = 5
print "area of a 5 by 5 square:"; shape_area( @sq )
```

```bash
tiko usemod.tiko -i modules
```

```
area of a 5 by 5 square: 25
```

The names stay bare (`Shape`, not `shapes.Shape`), because a C header's names do not belong to a namespace.

## 13. When it goes wrong

| What you see | Cause | Fix |
|---|---|---|
| `TKO0335: #cinclude needs libclang` | libclang was not found | install LLVM, or set `TIKO_LIBCLANG` |
| `TKO0336: unable to import C header` + `file not found` | the header, or one it includes, is not where tiko looked | check the path; add `-cinclude` for `<...>` includes (section 7) |
| the same + a note about the Windows SDK | Visual Studio Build Tools are not installed | install them, with the Windows SDK |
| `TKO0743: '...' is not declared` for a name in the header | a function-like or string macro, a `static inline` function, or a renamed name | look at the binding with `-cimport` (sections 5 and 8) |
| `TKO0808: the type '...' is not declared` or `TKO0810: '...' is an incomplete type` for a struct in the header | the struct was skipped | read the reason at the top of the binding |
| `warning TKO0833` at a callback | your callback's parameters differ from the C type | match the C type exactly (section 6) |
| `undefined symbol` when linking | the header was read, but the library was not linked | add a `#foreignlib` line ([#foreignlib Tutorial](modern-Foreignlib-tutorial)) |

## 14. Options

| Option | What it does |
|---|---|
| `-cinclude <dir>` | a folder clang searches for headers (clang's `-I`) |
| `-cdefine <name>[=<value>]` | defines a C macro (clang's `-D`) |
| `-csysroot <dir>` | the C sysroot (clang's `--sysroot`) |
| `-copt <arg>` | passes one argument to clang unchanged |
| `-cnomacros` | does not import macros as constants |
| `-cnoverify` | does not check struct layouts (section 10) |
| `-cnocache` | neither reads nor writes the binding cache |
| `-ccachedir <dir>` | where the binding cache is kept |
| `-cimport <header>` | writes a header's binding to a file; needs `-cimport-out` |
| `-cimport-out <file>` | where `-cimport` writes; `-` for the screen |
| `-cimport-manifest <file>` | writes clang's layout of every imported struct |

### See also

- [#cinclude](modern-Cinclude), the reference page
- [#foreignlib Tutorial](modern-Foreignlib-tutorial), linking the library's code
- [Using C Libraries](Using-C-Libraries-Tutorial), with step-by-step tutorials for [SQLite](SQLite-Tutorial), [raylib](Raylib-Tutorial), [GLFW](GLFW-Tutorial) and [SDL3](SDL3-Tutorial)

---

**Category:** [C Header Import](Category-C-Header-Import)
**Kind:** tutorial

---

[Home](Home) · [Keyword Index](Keyword-Index)
