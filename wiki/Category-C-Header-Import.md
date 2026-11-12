[Home](Home) › [All Categories](Categories) › **C Header Import**

# C Header Import

> **In tiko.** tiko imports C headers itself, through libclang loaded at first use and never linked, for windows-x86_64 (the Windows default), linux-x86_64 and macos-arm64. Its C-import options are `-cinclude`, `-cimport`, `-cimport-out` (`-` for standard output), `-cimport-manifest`, `-cdefine`, `-csysroot`, `-copt`, `-cnomacros`, `-cnoverify`, `-cnocache` and `-ccachedir`, plus the compiler-development option `--cimport-probe`. Measured on windows-x86_64.

> 📘 **Also in this category:** [#cinclude Tutorial](modern-Cinclude-tutorial) · [tiko c2t](C2t) — translate a header once into a readable `.ti` you keep


## Syntax

```freebasic
#cinclude [once] "header.h"
```

## Description

Uses a C library's **own header** in place of a hand-written binding.

The header is handed to **Clang**, and what comes back is converted into tiko declarations for the target being built — structs, unions, enums, typedefs, functions, function pointers, globals and object-like macros — which are then included at the point of the directive.

```freebasic
#cinclude once "sqlite3.h"
#foreignlib SQLITE static "vendor/sqlite3"

dim as sqlite3 ptr db
sqlite3_open( @":memory:", @db )
```

That is the whole binding. No `.bi` file, no `Declare`, no struct copied out by hand.

`once` means what it means for `#include`.

## Parameters

| | |
| --- | --- |
| `once` | Optional. Include the generated binding only the first time it is reached |
| `"header.h"` | The header, as you would spell it in C. Resolved by **Clang** — the compiler's own include search is the wrong one for C headers |

## The layout is checked, not trusted

The importer does **not** write Clang's offsets into the compiler's symbols. It emits tiko **text** and lets the compiler compute every size, alignment and member offset itself, so there are two independent answers to compare.

> **A disagreement does not stop the build.** A record whose size, alignment or any member's bit offset disagrees is refused — left out of the binding, with the difference in the skip ledger — and the header is imported again without it; whatever holds it by value goes with it, and a pointer to it survives. Only a use of the refused record fails. For a record whose member C over-aligns with `__attribute__((aligned(16)))`, which tiko cannot spell, tiko's ledger reads `tiko lays it out in 20 bytes aligned to 4, clang in 32 aligned to 16; member 'x' is at bit 32 in tiko's layout and bit 128 in clang's`, and `dim as lay_holds_aligned h` -- a record holding it by value -- is `TKO0808: the type 'lay_holds_aligned' is not declared`.

`-cnoverify` turns the check off. There is no good reason to use it.

## Requirements

libclang **16 or newer** (`CLANG_MIN_MAJOR`, `src/cimport/clang.ti`). tiko loads it on first use through [`DyLibLoad`](Dylibload) and never links it, so tiko builds and runs without it, and only `#cinclude`, `-cimport` and `--cimport-probe` ask for it. It is looked for in `TIKO_LIBCLANG` (alone, when that is set), then beside the clang tiko compiles with, then where the LLVM installer or a distribution puts it (`src/cimport/clang.tiko`). Every tiko build already needs an installed LLVM with clang 18 or newer, and that install ships libclang. When none opens, a `#cinclude` line is `TKO0335: #cinclude needs libclang: ...`, saying what was tried, and a program with no `#cinclude` still builds.

Targets: **windows-x86_64** (tiko's default on Windows, imported against the installed MSVC and Windows SDK headers), **linux-x86_64**, and **macos-arm64** (imported against the macOS SDK from the Command Line Tools, on a Mac).

```
tiko --cimport-probe stddef.h
```

loads libclang, parses the header, prints the libclang it loaded, clang's version, resource directory and target and then what clang saw, and exits. It is a compiler-development option.

## The command-line form

```
tiko -cimport raylib.h -cimport-out raylib_generated.ti
```

generates the binding as a **file** instead of including it — for reading, for checking into a repository, or for diffing across a library upgrade. The output is deterministic: the same headers and options give a byte-identical file on either operating system, so a diff means something changed in the header.

Several headers in one command share one binding, and shared types are declared exactly once:

```
tiko -cimport raylib.h -cimport raymath.h -cimport rlgl.h -cimport-out raylib.ti
```

> On windows-x86_64, with raylib 6.0's headers: `raylib.h` alone gives 714 declarations in under a second, and two runs are byte-identical (across operating systems is not measured); with `raymath.h` and `rlgl.h` added, 1,273 declarations, and `Vector2`, `Vector3`, `Matrix` and `Color` are each declared once. `-cimport-out -` writes the binding to standard output. tiko imports a named record declared inside another (`sqlite3.h`'s `sqlite3_index_info`), an array parameter, and an anonymous member of an unnamed record.

## Options

| option | |
| --- | --- |
| `-cinclude <dir>` | A C include directory. Passed to Clang as `-I` |
| `-cdefine <name>[=<value>]` | A C macro. Passed as `-D` |
| `-csysroot <dir>` | The C sysroot |
| `-copt <arg>` | Passed to Clang verbatim |
| `-cnomacros` | Do not import object-like macros as constants |
| `-cnoverify` | Skip the layout check |
| `-cimport-manifest <f>` | Write the ABI manifest to a file |
| `-ccachedir <dir>` | Where bindings are cached |
| `-cnocache` | Always re-import |

Every option is part of the **cache key**, so the same header imported with different options gives different entries and they cannot be confused for one another.

### Where each binding is: `--print-cincludes`

A tool with its own parser — the [tiko language server](https://github.com/PaulSquires/tiko-lsp) — cannot read a C header, but it can read the binding tiko makes of it. `tiko --print-cincludes file.tiko` preprocesses the file (and what it `#include`s), imports each `#cinclude` exactly as a build does — the same cache, the same delta chain, `#cmdline` honoured — and prints one JSON object:

```
{"format":1,"cincludes":[
  {"file":"C:\\app\\main.tiko","line":2,"header":"raylib\\raylib.h",
   "binding":"C:\\Users\\me\\AppData\\Local\\tiko\\cimport\\1f692a7e84a065a7\\binding.bi"},
  {"file":"C:\\app\\main.tiko","line":3,"header":"missing.h","binding":"",
   "error":"unable to import C header missing.h: ..."}]}
```

`file` is the file that wrote the directive — an `#include`d `.bi` names itself — and `line` is 1-based. A header that cannot be imported has `binding` empty and an `error`, and its diagnostic still goes to standard error; the exit code is 1 then, but the JSON is printed either way. Under `-cnocache` the binding exists only in memory, so there is no file to name: `binding` is empty and `error` says so. Nothing is parsed, and `#import` is passed over (tiko-lang `tests/cimport/print-cincludes*.test`).

## What comes across

| | |
| --- | --- |
| structs, unions | written `type T extern "c"`, so laid out by the target's C rules -- MSVC's bit-fields on Windows, System V's on Linux and macOS, `#pragma pack` as `field = n`; layout verified, bit-fields included, anonymous members flattened or nested as tiko requires |
| enums | as `type Color as uint32` plus a plain `Enum` block — never as a tiko `Enum`, which is 8 bytes where C says 4 |
| typedefs | kept by name, so `LPCWSTR` stays `LPCWSTR` |
| functions | including variadics, and the calling convention the header states **for the target being built** — see [Calling conventions](#calling-conventions) |
| function pointers | with their real signatures, so a callback handed to C is type-checked |
| globals | as `Extern`, with an `Alias` |
| object-like macros | `#define MAX_PATH 260`, folded by Clang in the real header context |

An opaque handle — `typedef struct sqlite3 sqlite3;` with no definition — becomes `type sqlite3 as any`, which is the opaque pointer C intended.

## Calling conventions

An imported procedure or function pointer carries whatever convention the header states **for the target being built**, which is not always what the documentation says. `windows.h` declares `WNDPROC` as `WINAPI`; on 64-bit Windows the SDK defines `WINAPI` away, because x86-64 Windows has exactly one calling convention, so Clang reports the default and the imported typedef reads `cdecl`.

On 64-bit Windows `cdecl` and `stdcall` describe the same call.

**tiko treats `cdecl`, `stdcall` and `stdcall_ms` as interchangeable on a 64-bit target**, so you do not have to write one to match an imported pointer:

```freebasic
'' all three assign cleanly to an imported `cdecl` procedure pointer
function A cdecl   ( byval x as int32 ) as int32 : return x : end function
function B stdcall ( byval x as int32 ) as int32 : return x : end function
function C         ( byval x as int32 ) as int32 : return x : end function
```

`pascal` is **not** in that set and still warns. It is not a mangling or a register difference — it reverses the argument order, on x86-64 as anywhere else, so a `pascal` procedure called through a `cdecl` pointer with `(1, 2)` returns `21`.

> The `cdecl`/`stdcall` distinction is real only on x86, and tiko does not target 32-bit (`-m32` is `TKO0104: 32-bit targets are not supported; x86-64 only`), so a warning on that mismatch would have nothing to protect.
>
> tiko accepts all three without a warning. A `pascal` procedure draws the warning `TKO0830`, and through the imported `cdecl` pointer with `(1, 2)` it returns `21`, because tiko passes a `pascal` procedure's arguments in reverse. Measured through a function-pointer typedef imported with `#cinclude`, on windows-x86_64.

## What does not

- **Function-like macros.** `#define MAKEINTRESOURCE(i) ((LPWSTR)((ULONG_PTR)(i)))` is an arbitrary token sequence with C's semantics, and translating one means writing a C expression compiler. There is no safe partial version: a macro that translates to *nearly* the right expression is worse than one that does not translate at all. Write the expansion yourself.
- **`NULL`.** Dropped deliberately — the crt headers define it, and emitting it too would be a duplicate definition. Write `0`.
- **C++.** C headers only.
- **`int32 float64`**, and **infinity/NaN** as constant values. tiko has no spelling for either; both are skipped, with the reason in the ledger.
- **An `inline` function of a system header.** A C99 `inline` function in the library's own header -- found beside the source, through `-cinclude` or by a quoted name -- is declared like any other, because the library is expected to export it: raylib exports every one of raymath's. In a **system** header (the Windows SDK, the Universal CRT, `/usr/include`) it is not: such functions have no symbol a program links (`PtrToUlong`, `_snprintf_l`), so they are left out and a call is `TKO0743`. A `static` function is left out wherever it is. Each one left out is listed in the binding's header comment, `function  PtrToUlong  inline, no symbol` or `static`.
- **On windows-x86_64, the Universal CRT's inline functions.** The UCRT's `stdio.h` defines `printf` and its family in the header as inline functions (`_CRT_STDIO_INLINE`), with no symbol. The fourteen of the `printf` and `scanf` families (`printf`, `fprintf`, `sprintf`, `snprintf`, `scanf`, `fscanf`, `sscanf` and their `v` forms) come across all the same, because tiko's runtime defines each one; any other inline function in a UCRT header does not, and a call to it is `TKO0743: '...' is not declared`. `snprintf` and `vsnprintf` into a buffer too small return the length that was wanted (C99).

## Working with `#foreignlib`

Binding to a C library is **two** jobs, and these are the two halves:

| | what it answers | |
| --- | --- | --- |
| [`#cinclude`](modern-Cinclude) | *what are these things?* — the types, the signatures, the constants | the **header** half |
| [`#foreignlib`](modern-Foreignlib) | *where is the code?* — which file to link, for this target | the **linkage** half |

Neither implies the other. `#cinclude` declares everything and links nothing; `#foreignlib` links a library and declares nothing. Used together they let a binding ship **entirely inside your own source tree**, with no system-installed header and no system-installed library:

```
mylib/
    mylib.ti                        <- the binding: both directives
    vendor/mylib.h                  <- the library's own header
    vendor/mylib_windows_x86_64.dll.a
    vendor/mylib_linux_x86_64.so
```

```freebasic
'' mylib/mylib.ti
#pragma once

#cinclude once "mylib.h"            '' the declarations, from the real header
#foreignlib MYLIB dynamic "vendor/mylib"   '' the library, per target
```

and then, with no `Declare` and no `#ifdef` anywhere:

```freebasic
#include once "mylib/mylib.ti"
print mylib_add( 2, 3 )
```

The declarations come out of the header for the target being built, and the right library file is chosen for that same target. A cross-platform binding stops being a maintenance problem in two directions at once.

> **Both resolve beside the file that names them.**
>
> `#foreignlib` resolves its library **relative to the file containing the directive** — that is [the whole reason it exists](modern-Foreignlib), because `#libpath` is relative to the compiler's working directory and therefore unusable in a shipped binding.
>
> tiko's `#cinclude` looks for a quoted header in the **working directory**, then **beside the file that wrote the directive**, then in each `-cinclude` directory — C's own rule for `#include "x"`, with the working directory kept first. So `#cinclude "vendor/mylib.h"` inside `mylib.ti` finds `mylib/vendor/mylib.h` from any working directory, and the layout above needs no `-cinclude` (`tests/cimport/cinclude-beside.test`).

There is **no `lib MYLIB` clause**, and there cannot be — the declarations are generated rather than written. It is not needed: a `#foreignlib` contributes its libraries to the link whether or not any declaration names it, exactly as [`#inclib`](Inclib) does. The bound name exists for hand-written declarations that want it.

If the library is installed on the system rather than vendored, [`#inclib`](Inclib) is simpler and `#foreignlib` buys you nothing:

```freebasic
#cinclude once "sqlite3.h"
#inclib "sqlite3"
```

### `system:` does not give you a dynamic link

`#foreignlib` can spell the same thing with a `system:` spec, and it is tempting to read the mandatory `dynamic` as a guarantee that you will not silently get a static archive:

```freebasic
#foreignlib SQLITE dynamic "system:sqlite3"    '' does NOT guarantee anything
```

It is not a guarantee. A `system:` name goes to the linker as `-lsqlite3`, exactly as [`#inclib`](Inclib) does, and the linker takes whatever it finds first: on Linux, `libsqlite3.so` before `libsqlite3.a` when both exist.

The `static`/`dynamic` keyword is meaningful only for a **file** spec, where it constrains which extensions are eligible and a file of the other kind is an error.

> If you need a genuinely guaranteed dynamic link, neither directive gives you one today. The mechanism exists in GNU `ld` — `-Bdynamic` / `-Bstatic` — but it is **positional** (passing it through `-Wl` lands it after the `-l` it was meant to constrain, where it does nothing) and **sticky** (it also changes resolution for every following library, the C runtime included). Honouring it would mean bracketing the one `-l` and restoring the previous mode, and it is `ld`-specific.

## In a module: `public #cinclude`

A `#cinclude` in a [module](Category-Modularizing) imports the header into the module, and its names stay the module's own: a program that imports the module does not see them. Written **`public #cinclude "x.h"`**, the binding travels with the module's interface instead, and an importer sees the header's functions, types, `#define` constants and struct macros exactly as if it had `#cinclude`d the header itself: bare, not qualified by the module's name, because preprocessor names have no namespace.

```freebasic
'' modules/raylib/raylib.tiko
#module "raylib"
public #cinclude once "../../vendor/raylib/raylib.h"
#foreignlib RAYLIB static "../../vendor/raylib/raylib", "system:winmm", _
    "system:gdi32", "system:user32", "system:shell32"
```

```freebasic
'' a program
#import "raylib"
InitWindow( 800, 450, "raylib" )
```

`public #include "x.ti"` does the same for a tiko header -- the form a [vendor package](Vendor-Packages) uses for a header translated once by [`tiko c2t`](C2t).

The module's `#foreignlib` links the library into every program that imports it. A plain `#cinclude`'s binding also travels when one of the module's public declarations names one of its types. `public #cinclude` outside a module file is `TKO0369`; with `-cnocache`, which leaves the binding in memory rather than in a file an importer can include, it is `TKO0340`. A module cannot use `#cmdline` (`TKO0366`), so a header that needs `-cinclude` is better kept in a binding header. See [Using C Libraries](Using-C-Libraries-Tutorial).

## Names

The C name is kept wherever tiko allows it, and every change is recorded in a ledger at the top of the generated file, with its reason.

- A **quirk word may name a type.** `POINT`, `INPUT`, `IMAGE`, `COLOR` and `DIR` are procedures the compiler already has, so they cannot name a procedure — but `type POINT as tagPOINT` is legal, and `POINT` stays `POINT`.
- A **type and a procedure may share a name.** `INITCOMMONCONTROLSEX` the struct and `InitCommonControlsEx` the function coexist, as do POSIX's `struct stat` and `stat()`.
- What genuinely collides gets a suffix: `size_t` and `SIZE_T` are one name to tiko, so the second becomes `SIZE_T_2`. C's `time()` collides with the [`Time`](Time) statement and becomes `time_`.

Every declaration carries `alias "<exact C name>"`, so a rename never changes the symbol the linker sees. Constants are the exception — a `Const` is a compile-time value, not a symbol.

## Remarks

- The generated binding is **cached**, so the expensive half runs once per configuration and the cheap half — parsing tiko text — runs per compilation, exactly as `#include` does today. The key is the header chain, every option, `UNICODE`, the target, libclang and its resource directory, the working directory, the running `tiko` by size and time, and what clang's header detection reads (`-csysroot`, `CPATH`, `C_INCLUDE_PATH`, `INCLUDE`, `VCToolsInstallDir`, `WindowsSdkDir`); every file clang read is re-checked on each hit, so editing any header in the tree invalidates it. A program that `#cinclude`s `windows.h` built in 18.7 s cold and 0.6 s warm with tiko on windows-x86_64.
- tiko's import of `windows.h` has 42,945 declarations on windows-x86_64 — 2,887 records, every one checked against a clang-compiled program — with no record refused.
- Over-alignment (`__declspec(align(16))`) has no tiko spelling. C's tail padding is written out so `SizeOf` and every member offset are right, and the affected records are reported by name — but a local or array element is 8-byte aligned where C promises 16.

### See also

- [#cinclude Tutorial](modern-Cinclude-tutorial) — start here
- [`#foreignlib`](modern-Foreignlib) — linking a library shipped inside your own source tree, the other half of binding to a C library
- [`Alias`](Alias-Modifier) · [`Extern`](Extern) · [`Declare`](Declare)
- [`DyLibLoad`](Dylibload) — how libclang is loaded
- [Compiler Option: -gen](Compiler-Option-Gen)

## Examples

```freebasic
'' A third-party library, header and all.

#cinclude once "sqlite3.h"
#foreignlib SQLITE static "vendor/sqlite3"

function OnRow ( byval user as any ptr, byval ncols as int32, _
                       byval values as zstring ptr ptr, _
                       byval names as zstring ptr ptr ) as int32
	print *values[0]
	return 0
end function

dim as sqlite3 ptr db
sqlite3_open( @":memory:", @db )
sqlite3_exec( db, @"select name from part;", @OnRow, 0, 0 )
sqlite3_close( db )
```

Naming the header through the folder — `#cinclude once "vendor/sqlite3.h"` — needs no `-cinclude` **when the compiler is run from the directory that contains `vendor/`**. tiko also finds it from anywhere else when `vendor/` sits beside the source, because it looks beside the file that wrote the directive too. (`-cinclude path/to/vendor` does not do it: the directive already names `vendor/`, and tiko reports the header missing — `TKO0336: unable to import C header vendor/sqlite3.h`.)

The example builds with tiko on windows-x86_64 with `-cinclude vendor`. Its library must be built for windows-x86_64: a `sqlite3_windows_x86_64.a` built by MinGW does not link there (`lld-link: error: undefined symbol: ___chkstk_ms`, `TKO0116`).

## Pages in this category

[#cinclude](modern-Cinclude) · [#cinclude Tutorial](modern-Cinclude-tutorial) · [tiko c2t](C2t) · [Vendor Packages](Vendor-Packages)

---


---

[Home](Home) · [Keyword Index](Keyword-Index)
