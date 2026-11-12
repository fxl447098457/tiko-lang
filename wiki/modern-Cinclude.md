[Home](Home) › [C Header Import](Category-C-Header-Import) › **#cinclude**

# #cinclude

> 📘 **Also in this category:** [#cinclude Tutorial](modern-Cinclude-tutorial), the step-by-step introduction

Preprocessor directive

## Syntax

```freebasic
#cinclude [once] "header.h"
public #cinclude [once] "header.h"
```

## Description

Uses a C library's **own header** in place of a hand-written binding.

The header is handed to **clang**, and what clang reports is turned into tiko declarations for the target being built: structs, unions, enums, typedefs, functions, function-pointer types, global variables and object-like macros. Those declarations are then included at the point of the directive.

```freebasic
#cinclude once "vendor/sqlite/sqlite3.h"
#foreignlib SQLITE static "vendor/sqlite/sqlite3-static"

dim db as sqlite3 ptr
sqlite3_open( ":memory:", @db )
```

That is the whole binding. There is no `.ti` file to write, no `declare`, and no struct copied out by hand.

`#cinclude` declares things and links nothing. The library's code is linked with [`#foreignlib`](modern-Foreignlib) or [`#inclib`](Inclib).

## Parameters

| | |
|---|---|
| `public` | Only in a module file. The header's names become names of every program that imports the module. Without it, a `#cinclude` in a module is private to the module. |
| `once` | Optional. Include the binding only the first time the directive is reached, as for `#include`. |
| `"header.h"` | The header, spelled as in C. |

`public #cinclude` outside a module file is `TKO0369: 'public #cinclude' is allowed only in a module file`.

## Finding the header

A quoted header is looked for:

1. under the **working directory**;
2. **beside the file** that contains the directive;
3. in each `-cinclude` directory, in order.

Headers that the header itself includes with angle brackets (`#include <lib/other.h>`) are found only in the `-cinclude` directories and in clang's system include directories.

A `-cinclude` directory on the command line or in `#cmdline` is relative to the working directory. In `tiko.toml`'s `options` it is relative to `tiko.toml`.

Because the working directory is searched first, a header there of the same name wins over the one beside the file. Give vendored headers a specific path, such as `"vendor/sqlite/sqlite3.h"`.

A header that cannot be found or does not compile as C is `TKO0336: unable to import C header`, followed by clang's own message and a note giving the search order.

## The layout is checked, not trusted

tiko does **not** copy clang's sizes and offsets. It writes tiko declarations, then lays out every imported struct and union **itself**, and compares the result with clang's: the size, the alignment, and the bit offset of every member.

A record whose layout disagrees is **refused**. It is left out of the binding, and the difference is listed under *declarations were skipped*:

```
'' 1 declarations were skipped:
''     struct    A16                         tiko lays it out in 20 bytes aligned to 4, clang in 32 aligned to 16; member 'v' is at bit 32 in tiko's layout and bit 128 in clang's
```

A record that holds the refused one by value is refused with it (`field 'v': uses 'V4', which was skipped`).

A refused record is an **incomplete type**: usable through a pointer, not by value, which is also all C can do with a type it has not seen defined. A function that takes a pointer to it is kept, and so is a field that points to it, with the record's name. A variable of the record itself is

```
error TKO0810: 'a16' is an incomplete type: nothing declares it, so only a pointer to it may be used here
```

so a program never reads a struct through a wrong layout. In the binding, the record is introduced by an alias of its own, `type A16__fwd as A16`, among the forward references at the top.

`-cnoverify` turns the check off. There is no good reason to use it.

## Requirements

**libclang 16 or newer.** tiko loads libclang the first time a program needs it and never links it, so tiko builds and runs without it. Only `#cinclude`, `-cimport` and `--cimport-probe` need it. It is looked for:

1. in `TIKO_LIBCLANG`, alone, when that variable is set;
2. beside the clang that tiko compiles with;
3. where the LLVM installer, a Linux distribution or Homebrew puts it (`/opt/homebrew/opt/llvm/lib` on macOS).

Every tiko install already needs LLVM, and LLVM ships libclang. When none opens, the directive is `TKO0335: #cinclude needs libclang`, saying what was tried. A program with no `#cinclude` still builds.

**C headers for the target.** On **windows-x86_64**, headers are imported against the installed **Visual Studio Build Tools** (*Desktop development with C++*) and **Windows SDK**, because almost every header includes the C runtime's. On **linux-x86_64**, against the system's C headers (`build-essential` on Ubuntu). On **macos-arm64**, against the macOS SDK from Xcode's Command Line Tools.

```
tiko --cimport-probe stddef.h
```

loads libclang, parses one header, prints the libclang it loaded, clang's version, resource directory and target, then every header clang read, and exits. Use it to check the installation.

## The command-line form

```
tiko -cimport windows.h -cimport-out windows_binding.ti
```

writes the binding to a **file** instead of including it: to read it, to check it in, or to compare it across an SDK upgrade. `-cimport-out -` writes it to standard output.

Several headers in one command make one binding, and a type they share is declared once:

```
tiko -cimport windows.h -cimport commctrl.h -cimport-out win.ti
```

The output is **deterministic**: the same headers and options give a byte-identical file. A difference between two runs means a header changed.

The file starts with a banner naming the headers, the target and the clang version, the number of declarations, and then two lists: every name that was **changed** and every declaration that was **skipped**, each with its reason. On windows-x86_64, `windows.h` gives 42,945 declarations and 42 skipped.

## Options

| option | |
|---|---|
| `-cinclude <dir>` | a C include directory (clang's `-I`) |
| `-cdefine <name>[=<value>]` | a C macro (clang's `-D`) |
| `-csysroot <dir>` | the C sysroot (clang's `--sysroot`) |
| `-copt <arg>` | an argument passed to clang verbatim |
| `-cnomacros` | do not import object-like macros as constants |
| `-cnoverify` | do not check the layout of imported records |
| `-cnocache` | neither read nor write the binding cache |
| `-ccachedir <dir>` | where bindings are cached (default: the user's cache directory) |
| `-cimport <header>` | import a header to a file; needs `-cimport-out` |
| `-cimport-out <file>` | where `-cimport` writes; `-` for standard output |
| `-cimport-manifest <file>` | write clang's layout of every imported record |
| `--print-cincludes` | import every `#cinclude` the inputs reach, print where each binding is as JSON, and stop |
| `--cimport-probe <header>` | load libclang, parse one header, print what clang saw |

Every option is part of the cache key, so one header imported with different options gives different entries.

## What comes across

| | |
|---|---|
| structs, unions | written `extern "c"`, so laid out by the target's C rules, and the layout checked; bit-fields included; an anonymous union member stays anonymous; a member whose struct type has no name gets a generated type name, such as `Outer_pos_t` |
| enums | a 32-bit integer type named after the enum, plus its values in an anonymous `enum` block |
| typedefs | kept by name, so `LPCWSTR` stays `LPCWSTR` |
| functions | including variadic ones, with the calling convention the header states for the target |
| function pointers | with their real signatures, so a callback handed to C is type-checked |
| global variables | as `extern`, with an `alias` |
| object-like macros | numeric ones, such as `#define MAX_PATH 260`, as constants, with the value clang computes |

An opaque handle, `typedef struct sqlite3 sqlite3;` with no definition, becomes `type sqlite3 as any`: you only ever hold a `sqlite3 ptr`.

C's `int` arrives as `long` (32 bits, the same type as `int32`), `long long` as `longint`, `double` as `double`, `char *` as `zstring ptr`, `void *` as `any ptr`, and `char name[16]` as `zstring * 16`. Where C's types differ by platform, so does the binding: C's `long` is 32 bits on Windows and 64 on Linux and macOS, and a binding that uses it includes `crt/long.bi`.

## Calling conventions

An imported function or function pointer carries the convention the header states **for the target being built**. On x86-64 there is one C calling convention, so `windows.h`'s `WINAPI` comes across as `cdecl`.

tiko treats `cdecl`, `stdcall` and no convention at all as the same call on its 64-bit targets. A callback can be written any of the three ways and matches an imported pointer with no warning:

```freebasic
function A cdecl   ( byval x as int32 ) as int32 : return x : end function
function B stdcall ( byval x as int32 ) as int32 : return x : end function
function C         ( byval x as int32 ) as int32 : return x : end function
```

`pascal` is different and warns: it passes the arguments in reverse order, so a `pascal` function called through a `cdecl` pointer with `(1, 2)` receives `(2, 1)`. Assigning one is `TKO0830: suspicious pointer assignment`; passing one as an argument is `TKO0833: passing different pointer types`.

A callback whose **parameters** differ from the C type is also `TKO0833`. Treat it as an error: the program builds, and the callback reads garbage.

## What does not come across

- **Function-like macros.** `#define MAKEINTRESOURCE(i) ((LPWSTR)((ULONG_PTR)(i)))` is C code, not a value, and translating it would mean compiling C expressions. A macro translated *nearly* right is worse than one not translated at all. Write the expansion yourself.
- **Macros whose value is a string**, such as `#define VERSION "1.2"`.
- **`static inline` functions.** They have no symbol to link against.
- **`NULL`.** Use [`nullptr`](Category-Nullptr).
- **C++.** C headers only.
- **Types tiko cannot express**, each listed under *declarations were skipped* with the reason: `_Complex` numbers, an 80-bit `long double` (Linux), infinity and NaN as constant values, array typedefs, flexible array members, and function pointers declared with `(...)` and no named parameter (Windows' `FARPROC`, and so `GetProcAddress`).

**The Universal C Runtime's inline functions (windows-x86_64).** The UCRT's `stdio.h` defines `printf` and its family in the header, as inline functions with no symbol. The fourteen functions of the `printf` and `scanf` families (`printf`, `fprintf`, `sprintf`, `snprintf`, `scanf`, `fscanf`, `sscanf` and their `v` forms) work all the same, because tiko's runtime supplies each one. Any other inline UCRT function is not declared. `time` is one: it is a real function on Linux and an inline one on Windows.

## Names

The C name is kept wherever tiko allows it, and every change is listed at the top of the binding with its reason.

- **A word tiko already uses gets a `_`.** `abs`, `exit` and `system` in `stdlib.h`, and `sin`, `cos`, `exp` and `log` in `math.h`, become `abs_`, `exit_` and so on. A macro named like a tiko keyword is renamed the same way.
- **Names that differ only in case collide**, because tiko ignores case. The second gets a number: `_Exit` beside `exit` becomes `_Exit_2`.
- **A type and a procedure may share a name.** The struct `INITCOMMONCONTROLSEX` and the function `InitCommonControlsEx` both keep their names, as do POSIX's `struct stat` and `stat()`.

Every function and variable carries `alias "<exact C name>"`, so a rename never changes the symbol the linker sees.

## The binding cache

A binding is **cached**, so clang runs once per configuration and every later build only reads tiko text. A program that includes `windows.h` takes a few seconds the first time and well under a second after.

An entry is used only when everything it depends on is unchanged: every file clang read (each is re-checked on every use), every C option, `UNICODE`, the target, libclang and its resource directory, the working directory, the running `tiko` itself, and the environment clang uses to find system headers (`CPATH`, `C_INCLUDE_PATH`, `INCLUDE`, `VCToolsInstallDir`, `WindowsSdkDir`). `-cnocache` bypasses the cache; `-ccachedir` moves it.

## Working with `#foreignlib`

Binding to a C library is **two** jobs:

| | answers | |
|---|---|---|
| `#cinclude` | *what are these things?* the types, signatures and constants | the **header** half |
| [`#foreignlib`](modern-Foreignlib) | *where is the code?* which file to link, for this target | the **linkage** half |

Together they let a binding ship **inside your own source tree**, with nothing installed on the system:

```
mylib/
    mylib.ti                            <- the binding: both directives
    vendor/mylib.h                      <- the library's own header
    vendor/mylib_windows_x86_64.lib
    vendor/mylib_linux_x86_64.so
```

```freebasic
'' mylib/mylib.ti
#pragma once

#cinclude once "vendor/mylib.h"             '' the declarations, from the real header
#foreignlib MYLIB dynamic "vendor/mylib"    '' the library, per target
```

A program then needs `#include once "mylib.ti"` and nothing else: no `declare` and no `#ifdef`. Both paths are relative to `mylib.ti`, so the folder can live anywhere.

The imported declarations carry no `lib MYLIB` clause, and need none: a `#foreignlib` links its libraries whether or not a declaration names them.

For a library installed on the system, name it with `system:`, or with [`#inclib`](Inclib):

```freebasic
#cinclude once "sqlite3.h"
#foreignlib SQLITE dynamic "system:sqlite3"
```

## Remarks

- **Over-alignment** (`__declspec(align(16))`, `_Alignas(16)`) has no tiko spelling, so such a record usually fails the layout check and is refused. The exception is a record whose members already need 8-byte alignment: tiko writes out C's padding, so its size and every member offset match, but a local variable or array element of it is aligned to 8 bytes where C promises 16.

### See also

- [#cinclude Tutorial](modern-Cinclude-tutorial), start here
- [`#foreignlib`](modern-Foreignlib) and its [tutorial](modern-Foreignlib-tutorial), the linkage half
- [Using C Libraries](Using-C-Libraries-Tutorial), from download to running program for four real libraries
- [`Alias`](Alias-Modifier) · [`Extern`](Extern) · [`Declare`](Declare)
- [`DyLibLoad`](Dylibload)

## Examples

```freebasic
'' A window class from windows.h, with no binding file and no
'' calling convention: the header supplies both.
#define UNICODE
#cinclude once "windows.h"

function WndProc( byval hwnd as HWND, byval msg as UINT, _
                  byval wp as WPARAM, byval lp as LPARAM ) as LRESULT
    if msg = WM_DESTROY then
        PostQuitMessage( 0 )
        return 0
    end if
    return DefWindowProc( hwnd, msg, wp, lp )
end function

dim className as wstring * 16 = "TikoDemo"
dim wc as WNDCLASSEX
wc.cbSize        = sizeof( WNDCLASSEX )
wc.lpfnWndProc   = @WndProc
wc.hInstance     = GetModuleHandle( nullptr )
wc.lpszClassName = @className
if RegisterClassEx( @wc ) then print "window class registered"
```

```
window class registered
```

`WndProc` has no calling convention, and needs none: `WNDPROC` is imported as `cdecl`, which on x86-64 is the same call as tiko's default.

```freebasic
'' A third-party library: its own header, and its library file.
#cinclude once "vendor/sqlite/sqlite3.h"
#foreignlib SQLITE static "vendor/sqlite/sqlite3-static"

function OnRow cdecl( byval user as any ptr, byval ncols as int32, _
        byval values as zstring ptr ptr, _
        byval names as zstring ptr ptr ) as int32
    print *names[0]; " = "; *values[0]
    return 0
end function

dim db as sqlite3 ptr
sqlite3_open( ":memory:", @db )
sqlite3_exec( db, "select sqlite_version() as version", @OnRow, nullptr, nullptr )
sqlite3_close( db )
```

```
version = 3.54.0
```

The [SQLite tutorial](SQLite-Tutorial) shows how to lay out `vendor/sqlite/` for Windows and Linux.

---

**Category:** [C Header Import](Category-C-Header-Import)
**Kind:** preprocessor directive

---

[Home](Home) · [Keyword Index](Keyword-Index)
