# Compatibility

This page is for FreeBASIC code you already have. tiko is a language of its own, and it still compiles FreeBASIC 1.20 (`#lang "fb"`), so existing programs can move over and mix freely with tiko code. It aims at **the same accept/reject decision as fbc** in `-lang fb`, and **the same observable behaviour**: what a program prints, returns and does.

The reference is the official **fbc 1.20.0**, built from FreeBASIC's master branch. Every fact below was established by compiling a probe with that fbc and with tiko, and comparing the results. A probe beats a reading: where the two disagree, the probe wins.

The **diagnostic text** is tiko's own. Every message has a stable `TKOnnnn` id. fbc's error numbers survive only where a program can see them, through `ERR`.

**What fbc 1.20 does not have is not a compatibility difference.** Generics, tuples, collection initializers, `defer`, lambdas, `ustring`, the fixed-width type names, `nullptr`, string slices (`s[lo to hi]`, `uslice`), typed variadic parameters (`xs() as const long ...`, fbc error 7), the C layout of `type T extern "c"` (fbc error 17), `spawn` and channels, `#cinclude` and `#import` are tiko's own. Code that uses them does not compile under fbc 1.20. `dim a as int8` is fbc error 14, and `defer x` is error 42. The [Feature Index](Feature-Index) lists them. This page is about the code that both compilers accept, or one of them should.

## What does not compile under tiko

Each of these is a diagnostic, not a silent difference:

| Construct | fbc 1.20 | tiko |
| --- | --- | --- |
| `#lang "qb"`, `"fblite"`, `"deprecated"` | accepted | `TKO0317: unsupported language mode 'qb'; tiko-lang implements "fb" only` |
| `GOSUB` | error 146 in `-lang fb` (it is valid only in `fblite` and `qb`) | `TKO0409: 'GOSUB' is not available in the fb dialect` |
| inline `ASM` | compiles | `TKO0407: inline assembly is not supported; compile that module with fbc` |
| `-lang`, `-gen` | accepted | `TKO0100: unknown option` |
| `-m32`, `-target win32` | | `TKO0104`, `TKO0103`: x86-64 only |

`GOSUB` is the one row where the two compilers agree in `-lang fb`: both refuse it. Code that asks for another dialect is what tiko refuses.

## Where tiko differs

**tiko defines `__TIKO_COMPILER__`, always `1`,** and fbc does not, so `#ifdef __TIKO_COMPILER__` is how a source tree asks "is this tiko?". `__TIKO_VERSION__` gives tiko's version (`0.1.0-dev`), and fbc has no such name. See [`__TIKO_COMPILER__`](Category-Tiko-Compiler-Define).

**tiko declares ten fixed-width type names that fbc does not have:** `int8`, `uint8`, `int16`, `uint16`, `int32`, `uint32`, `int64`, `uint64`, `float32` and `float64`, typedefs for `byte` through `double`. They are not keywords. A program's own declaration of one of the names replaces tiko's with no diagnostic, so code that already uses them compiles and prints the same under both compilers: `win/basetsd.bi`'s `type INT32 as long`, a `type uint8 as integer`, a variable called `float32`. See [Fixed-Width Types](Category-Fixed-Width-Types).

**tiko predeclares `nullptr`, which fbc does not have:** `const nullptr as any ptr = 0`. It is not a keyword. A program's own declaration of the name replaces tiko's with no diagnostic, whether it is a field, a namespace member, a local, a parameter, a `for` counter or a module-level name, so code that already uses it compiles and runs the same under both compilers. fbc's own `virtual/fbrtti.bi` has a field called `nullptr`. Code that uses tiko's `nullptr` needs `const nullptr as any ptr = 0` under `#ifndef __TIKO_COMPILER__` to compile under fbc. A generic infers its type argument from a pointer-typed constant in tiko (`Echo( nullptr )` makes `T` an `any ptr`). See [Nullptr](Category-Nullptr).

**`defer` is a contextual keyword in tiko and an ordinary name in fbc 1.20.** It is the keyword only when a name, a keyword other than `as`, or the end of the statement follows. Everywhere else it stays usable as an identifier, and both compilers agree: a sub named `defer` is CALLED by `defer( 5 )`, `defer 5` and `defer -1`, and an array or a UDT named `defer` is used as one (`defer( 1 ) = 3`, `defer.field_ = 4`). Where the keyword applies, fbc 1.20 has no such statement:
- `defer print "out"` runs at the end of the scope under tiko. fbc says error 42, "Variable not declared".
- `defer x` is `TKO0874` under tiko, and a bare `defer` is `TKO0828`. fbc says error 42 for both.
- `defer q + 1` compiles under tiko with no diagnostic.
- `defer:` is a label in both compilers.

**A `"""` that ends its line opens a [block string](Category-Block-Strings) in tiko.** In fbc it is a string missing its closing quote: warning 12, and the value is one `"`. tiko reads every line up to one that starts with `"""` as the string's text instead, or reports `TKO0207` when none follows. This is the only spelling whose meaning changed: `"""abc"""` is still the five-character `"abc"` and `""""` is still one quote, in both compilers. No line of the vendored fbc suite (its 2,709 `.bas` files and 41 `.bi` files) or of `pkg/` opens one.

**`#embed` at the start of a line is a [directive](Category-Embed) in tiko.** In fbc it is `error 17: Syntax error`. Nothing else changes meaning: `embed` is an ordinary name in both compilers, and `#embed` in the middle of a line is a file number in both, so `print #embed, "x"` writes to file number `embed`.

**`partial type` or `partial class` followed by a name declares part of a [partial type](Category-Partial-Types) in tiko.** In fbc the same line is `error 42: Variable not declared, partial`. `partial` stays an ordinary name in both compilers.

**tiko accepts some programs that fbc rejects.** What was confirmed:

| Program | fbc 1.20 | tiko |
| --- | --- | --- |
| `#define run 5` -- a name fbc's runtime predeclares | `error 4: Duplicated definition` | accepted: `print run` prints 5 |
| `F( 5 )` where `F` is overloaded, one overload takes `byref w as const W`, and `W` has `constructor( byval n as long )` | `error 99: No matching overloaded function` | accepted: the constructor builds a temporary `W` and that overload runs |
| `declare function F( byval x as long ) as long` then `declare function F overload( byref s as string ) as string` -- `OVERLOAD` on a later declaration only | `error 4: Duplicated definition` | accepted: both are one overload set, and each call picks by signature |
| the same with `function F overload( ... )`, a definition, after the plain `declare` -- or after `windows.bi`'s `GetWindowText`, `GetWindowRect` | `error 40: Return type here does not match DECLARE prototype` | accepted, as above |
| on Windows, `open "日本.txt" for output as #1` (a UTF-8 name from the source), or the same name as a `wstring` | creates `æ—¥æœ¬.txt` -- the bytes read as the ANSI code page; the `wstring` fails (file not found) | creates `日本.txt` |

The constructor case is the one form fbc leaves out. Both compilers accept the same call when the overload takes `byval w as W` or `byref w as W`, and when `F` is not overloaded at all. tiko applies the conversion to `byref ... as const` too.

**`OVERLOAD` may join a name whose first declaration did not write it.** fbc wants the keyword on the first declaration of a name; tiko lets any later declaration or definition that writes it add an overload, which is how a library offers `GetWindowText( hWin ) as ustring` beside the three-argument Windows function. Two overloads whose parameter types are the same are still refused (`TKO0677`). A [module](Packages-and-Modules-Tutorial)'s public overload of a name a header declares belongs to the same set in every program that imports the module: `GetWindowText( h )` and `win.GetWindowText( h )` both reach it, and `GetWindowText( h, buf, n )` still reaches Windows'.

**File names on Windows are Unicode.** The classic file statements -- `OPEN`, `KILL`, `NAME`, `MKDIR`, `RMDIR`, `CHDIR`, `CURDIR`, `DIR`, `EXEPATH`, and `file.bi`'s `FileExists`, `FileLen`, `FileCopy`, `FileDateTime` -- read a narrow name as UTF-8 when its bytes are valid UTF-8, and as the ANSI code page when they are not, so an old Latin-1 byte name still works; a `wstring` name is passed as UTF-8, like a `string` or `ustring` one. The paths `CURDIR`, `EXEPATH` and `DIR` return are UTF-8. fbc reads every name in the ANSI code page, so a name it cannot spell is mangled or not found. On Linux both compilers pass the bytes through, which is already UTF-8.

**Properties go further than fbc 1.20's.** tiko compiles property forms fbc refuses: a combination operator on a property (`obj.Size += 2`), `Swap` over two properties (fbc error 99), more than one index (errors 190 and 191), a `Static` property (error 213), a property in a namespace or at module level (errors 17 and 168), an auto-property (`Declare Property Age As Long Get, Set`) and a property block with `Get` and `Set` sections. One difference changes code that both compilers accept: **a property passed to a `ByRef` parameter is written back.** fbc passes a temporary holding the getter's value and discards it, so `Inc( obj.Size )` leaves `obj.Size` unchanged. tiko calls the setter with the temporary after the call returns, when the parameter is not `Const` and the setter may be called there. See [Property](Property).

**A virtual call's object is evaluated once.** fbc evaluates the object expression of a VIRTUAL method call TWICE: `getP( )->VM( )` calls `getP` twice (probed: 2 calls). tiko evaluates it once (1 call). A program whose object expression has a side effect prints differently.

**The same on both sides.** `print len`, `print asc`, `print abs` with no operand are refused by both (fbc error 6, tiko `TKO0872`), and so are `print len( )`, `print sqr( )`, `print chr( )` (fbc error 9, tiko `TKO0801`). A `pascal` procedure gets its arguments in the same order from both compilers.

**Pointer conversions get the same answer from both compilers**:

- A suspicious pointer assignment (`byte ptr` from `integer ptr`) draws fbc's warning 4 and tiko's `TKO0830` on the same line.
- A pointer stored into a pointer-sized integer (`dim as integer n = p`, `n += p`, `return p` from a function `as integer`) draws fbc's warning 5 and tiko's `TKO0968` on the same line. So does a pointer *constant* — `nullptr`, `cptr( any ptr, 0 )` — stored into a narrower integer or a `boolean`.
- A run-time pointer stored into a narrower integer or a `boolean` is refused by both: `bo = p` and `return p` from a function `as long` or `as boolean` (fbc error 181, tiko `TKO0910`), `dim as boolean b = p` (fbc 24, tiko `TKO0910`), `TakeBool( p )` (fbc 24, tiko `TKO0698`) and `cbool( p )` (fbc 20, tiko `TKO0890`). `cbool( nullptr )` is accepted by both.
- A pointer in a compound assignment other than `+=` and `-=` is refused by both — `n *= p`, `n mod= p`, `n shl= p`, `p and= 2` and the rest (fbc error 20, tiko `TKO0820`), as the plain operator already was.
- A pointer passed for a number or `boolean` parameter, byval or byref, draws fbc's warning 2 and tiko's `TKO0970` on the same line.

Across the vendored fbc suite, every line tiko gives `TKO0968` (22) or `TKO0970` (24) is one where fbc gives warning 5 or warning 2.

**A linux-x86_64 program that links a shared library from `#foreignlib` gets a run path of `$ORIGIN`.** fbc writes none, so its program finds a `.so` beside it only through `LD_LIBRARY_PATH`; tiko's finds it there, and `LD_LIBRARY_PATH` still wins. A program that links no shared library from `#foreignlib` is linked exactly as before, and `-norpath` turns the run path off. See [Vendor Packages](Vendor-Packages).

**Graphics links on `windows-x86_64` only.** libtkogfx is built for that ABI alone.

**`macos-arm64` is a tiko target, named `-target macos-arm64`.** `-target darwin` is refused (`TKO0103`). It defines `__FB_DARWIN__`, `__FB_UNIX__`, `__FB_ARM__` and `__FB_64BIT__`, and not `__FB_X86__`, so code under `#ifdef __FB_X86__` is left out there. `WSTRING` is 4 bytes, as on Linux. There is no graphics library.

**`#pragma msbitfields` is accepted and does nothing.** In fbc 1.20 it stops a bitfield from sharing a unit with the ordinary field before it: `short s : 4, byte c, long i : 7` is 8 bytes with `i` at bit 32, where both compilers say 4 bytes and bit 24 without it. tiko keeps the 4-byte layout under the pragma. It is not MSVC's rule either -- fbc still packs `byte a : 3, long b : 5` into one byte, where MSVC uses 8 -- and `type T extern "c"` is how tiko lays a type out as C does.

## What is the same

- **Symbol names** are byte-identical to fbc's. A probe with a namespaced procedure, overloads, a UDT with two constructors, a destructor, a method taking a string, a property, an `operator let`, a static function, virtual methods, a free function with `zstring ptr` and `wstring ptr` parameters, and a global operator exports 13 external symbols under fbc. tiko exports the same 13 under the same names, among them `_ZN2NS2PT4MOVEEiR8FBSTRING`, `_ZN2NS3SUMEii`, `_ZN2NS3SUMEdd`, `_ZN2NS3SUMEPNS_2PTERi` and `_ZplRN2NS2PTES1_`. tiko also exports three implicit members that fbc keeps file-local: the default constructors of a polymorphic base and of a type derived from it (`_ZN4ROOTC1Ev`, `_ZN3KIDC1Ev`), and the base's implicit `operator let` (`_ZN4ROOTaSERKS_`). A global in a namespace is file-local in both.
- **The runtime ABI** is `libfb`'s: its `FBSTRING` descriptor and the calling convention of its `fb_*` functions. tiko links tiko-rt, a reimplementation of that ABI in FreeBASIC.
- **The headers** are a subset of the ones fbc ships. Of the 1,698 files in fbc 1.20's `inc/`, tiko's Windows toolchain carries 386: 373 identical (ignoring line endings) and 13 that differ: `crt/locale.bi`, `crt/win32/stdio.bi`, `fbc-int/string.bi`, and `win/_mingw.bi`, `commctrl.bi`, `excpt.bi`, `richedit.bi`, `secext.bi`, `shtypes.bi`, `wincrypt.bi`, `windef.bi`, `winioctl.bi` and `winuser.bi`. The other 1,312 are not shipped: third-party bindings (GSL, X11, wx-c, FLTK, libxml and others) and headers for platforms tiko does not target, such as DOS. The toolchain adds about 2,450 files of its own, almost all of them AfxNova; the standard library ships beside `inc/` as modules, in `pkg/std/`.
- **Namespacing.** The standard libraries are modules behind an `#import`, so nothing becomes a keyword. `each`, `in` and `spawn` stay usable as ordinary variable names in tiko, and so does `defer` as a *variable*: one program that declares all four and prints them prints `1 2 3 4` under both compilers.

## How it is verified

- fbc's own test corpus is vendored (2,709 `.bas` files) and run differentially: programs, fbcunit suites and the test sources are each built by both compilers and compared.
- tiko compiles itself to a byte-identical fixpoint on windows-x86_64, linux-x86_64 and macos-arm64.

## Licensing

tiko is its own compiler, written from scratch. It is licensed in parts: GPL v2-or-later for the compiler, and LGPL v2.1-or-later with the static-linking exception for tiko-rt and libtkogfx. See [License](License).
