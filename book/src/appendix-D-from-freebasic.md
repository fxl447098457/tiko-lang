# Appendix D: Coming from FreeBASIC {#app-from-freebasic}

tiko compiles FreeBASIC. Its dialect is FreeBASIC 1.20's `#lang "fb"` plus tiko's extensions,
which are most of what Parts III to V of this book describe. The aim
is the **same accept/reject decision** as fbc and the **same observable behaviour**: what a program
prints, returns and does. Existing code moves over, and mixes freely with tiko code in one program.

This appendix is the list of what is different. Every row was measured on 2026-10-04 by compiling
the same program with the toolchain this book is pinned to and with **fbc 1.20** (Windows
unless a row says otherwise), and comparing what each did. Where the two agree, the appendix says
so too, because "does tiko do this the same way?" is the question it exists to answer.

## Dialects and the features they carry

tiko implements one dialect, `fb`. A file that asks for another one is refused, not quietly
compiled as `fb`:

| Program | fbc | tiko |
|---|---|---|
| `#lang "qb"`, `"fblite"`, `"deprecated"` | compiles in that dialect | `TKO0317`: unsupported language mode |
| `'$lang: "qb"` | compiles as `qb` | `TKO0317` |
| `-lang qb` on the command line | compiles as `qb` | `TKO0100`: unknown option |
| inline `asm … end asm` | compiles | `TKO0407`: inline assembly is not supported |

The features of the older dialects are refused by **both** compilers in `-lang fb`. fbc calls each
one error 146, "Only valid in -lang deprecated or fblite or qb", and tiko `TKO0409` (`TKO0944` for a
line number):

| Construct | Write instead (Chapter 32) |
|---|---|
| `gosub` / `return`, `on k gosub` | a `sub` |
| line numbers, `10 print 1` | a label, `here:` |
| `call Foo( )` | `Foo( )` |
| `let x = 1` | `x = 1` |
| `option explicit` | nothing: `fb` is always explicit |
| `option base 1` | bounds written out, `dim a( 1 to n )` |
| `defint a-z` and the other `def` types | declare each variable's type |
| `'$include: 'x.bi'`, `'$dynamic` | `#include "x.bi"`; arrays are dynamic when declared so |
| `lprint` | `open lpt` and `print #` |

## threadcall

`threadcall Proc( args )` is meant to start a thread for an ordinary procedure. tiko does not
implement it: it warns, the procedure does not run, and the handle is 0.

```text
warning TKO0797: 'threadcall' is not supported: 'hello' will not run, and the thread handle is 0
```

The fbc build used for these measurements did not run the procedure either: it also
returned a handle of 0, without a warning. Use `threadcreate` with a parameter block, or `spawn`
(Chapter 23).

## assert

The same in both compilers. `assert( expr )` checks nothing unless the program is compiled with
`-g` or `-eassert`. When it does check and the expression is false, it prints the file, the line,
the procedure and the expression, and ends the program with exit code 1:

```text
assert.bas(2): assertion failed at __FB_MAINPROC__: x = 3
```

## The intrinsic defines

The defines a program can test with `#ifdef`, and their values. **The same in both:**
`__FB_VERSION__` (`"1.20.0"`), `__FB_LANG__` (`"fb"`), `__FB_64BIT__`, `__FB_X86__`,
`__FB_WIN32__` on Windows and `__FB_LINUX__` and `__FB_UNIX__` on Linux, `__FB_ASM__`,
`__FB_PCOS__` on Windows, `__FB_FPU__`, `__FB_FPMODE__`, `__FB_DEBUG__`, `__FB_ERR__`, `__FB_MT__`,
`__FB_VER_MAJOR__`, `__FB_VER_MINOR__` and `__FB_VER_PATCH__` (`1`, `20`, `0`), `__FB_GUI__` (`-1`
under `-s gui`), `__FB_OPTIMIZE__` (the `-O` level), `__FB_PROFILE__` and `__FB_VECTORIZE__` (`0`),
`__FB_MAIN__` in the module that becomes `main`, `__FB_ARGC__` and `__FB_ARGV__` (`main`'s own
parameters, usable in module-level code only), an empty `__FB_BUILD_SHA1__`, every
`__FB_OPTION_…__` and `__FB_OUT_…__`, and the macro-like ones: `__FB_ARG_COUNT__` and the other `__FB_ARG_…__`,
`__FB_EVAL__`, `__FB_IIF__`, `__FB_JOIN__`, `__FB_QUOTE__`, `__FB_UNQUOTE__` and the
`__FB_UNIQUEID…__` family.

**Different:**

| Define | fbc | tiko |
|---|---|---|
| `__TIKO_COMPILER__` | not defined | `1`: how a source tree asks "is this tiko?" |
| `__TIKO_VERSION__` | not defined | `"0.1.4"` |
| `__FB_SIGNATURE__` | `"FreeBASIC 1.20.0"` | `"tiko-lang"` |
| `__FB_BACKEND__` | `"gcc"` | `"llvm"` |
| `__FB_GCC__` | `-1` | `0` |
| `__FB_MIN_VERSION__( … )` | defined | not defined: `#if __FB_MIN_VERSION__( 1, 20, 0 )` is `TKO0308` |
| `__FB_BUILD_FORK_ID__` | the fork id fbc was built with | `"tiko-lang"` |
| `__FB_BUILD_DATE__`, `__FB_BUILD_DATE_ISO__` | the date fbc was built | the date tiko was built |
| `__FB_QUERY_SYMBOL__( … )` | defined | not defined: it queries fbc's symbol table while preprocessing, and tiko preprocesses before any symbol exists |

## Command-line options

The options that mean the same thing in both compilers: `-c`, `-d`, `-dll`, `-dylib`, `-e`, `-ex`,
`-exx`, `-g`, `-i`, `-l`, `-lib`, `-m`, `-mt`, `-p`, `-s`, `-v`, `-x`, and the extension options
`-maxinstdepth`, `-cinclude`, `-cdefine` and `-cimport` (with `-cimport-out`). `-z` is accepted and
ignored.

Those spelled differently:

| fbc | tiko |
|---|---|
| `-o file` after a source: that source's object file | `-o file` names the program too, when there is no `-x` |
| `-O 2` | `-O2`, the level joined to the option |
| `-w all`, `-w pedantic` | `-Werror`, `-Wno-TKOnnnn` |
| `-maxerr n` | `-fmax-errors n` |
| `-r`, `-rr`, `-R`, `-RR` | `--emit-ir`, `--emit-asm`, `--keep-temps` |
| `-C` | `--keep-temps` |
| `-pp` | none: `--pp-only` preprocesses and reports counts without writing a file |

Everything else is `TKO0100: unknown option`, because tiko has one backend, one dialect and its own
linker driver: `-a`, `-arch`, `-asm`, `-b`, `-export`, `-forcelang`, `-gen`, `-include`, `-lang`,
`-map`, `-nodeflibs`, `-noerrline`, `-nolib`, `-noobjinfo`, `-nostrip`, `-pic`, `-prefix`,
`-print`, `-profile`, `-profgen`, `-showincludes`, `-static`, `-strip`, `-sysroot`, `-t`, `-title`,
`-vec`, `-Wa`, `-Wc` and `-Wl`. Appendix C lists tiko's own options.

## Diagnostics

tiko's messages are its own. Each has a stable id, `TKOnnnn` (Appendix B), and an id is never
reused, so a build log stays meaningful. fbc's error numbers survive only where a running program
can see them, through `err`: the runtime errors are fbc's, number for number.

The usual mistakes, side by side:

| Mistake | fbc | tiko |
|---|---|---|
| a variable or procedure never declared | 42 Variable not declared | `TKO0743` |
| a string assigned to a number | 181 Invalid assignment/conversion | `TKO0702` |
| the wrong number of arguments | 1 Argument count mismatch | `TKO0775` |
| the same name declared twice | 4 Duplicated definition | `TKO0600` |
| a name expected, something else found | 14 Expected identifier | `TKO0406` |
| a block not closed: `if` without `end if` | 32 Expected 'END IF' | `TKO0405` |
| a `for` without `next` | 13 Expected 'NEXT' | `TKO0401` |
| a member the type does not have | 18 Element not defined | `TKO0739` |
| an unknown type name | 14 Expected identifier | `TKO0808` |
| a constant division by zero | 100 Division by zero | `TKO0671` |
| an include file not found | 23 File not found | `TKO0301` |
| `redim` of a fixed-size array | 54 Expected var-len array | `TKO0723` |
| calling something that is not a procedure | 10 Expected '=' | `TKO0772` |
| a string initialising a pointer | 24 Invalid data types | `TKO0653` |
| `end function` closing a `sub` | 125 Expected 'END SUB' | `TKO0405` |
| a string returned from a numeric function | 181 Invalid assignment/conversion | `TKO0702` |
| `exit for` outside any `for` | 239 Illegal outside a FOR compound statement | `TKO0947` |
| `exit for, for` inside only one `for` | 247 No outer FOR compound statement found | `TKO0948` |
| `goto` to a label the procedure does not have | 48 Undefined label (104 at module level) | `TKO0949` |

## Other differences

- **tiko accepts `#define run 5`.** `run` is a runtime procedure (Appendix A), and fbc refuses to
  define a macro over it, error 4. tiko defines it, and `print run` prints 5.
- **A virtual call's object is evaluated once.** fbc evaluates the object expression of a virtual
  method call twice: `GetP( )->VM( )` calls `GetP` twice under fbc and once under tiko. Only a
  program whose object expression has a side effect can tell.
- **A `"""` that ends its line starts a block string** (Chapter 9). In fbc it is a string missing
  its closing quote, warning 12. `"""abc"""` and `""""` mean what they always meant, in both.
- **`defer` is a contextual keyword**, and so are the other words in Appendix A's list. Where they
  are not in their statement's position they are ordinary names, as they are in fbc 1.20.
- **Properties do more.** fbc allows at most one index, no `static` property, no property outside
  a type, and refuses `swap` on a property. tiko allows any number of indices, `static` and
  namespace properties, auto-properties (`get, private set`), property blocks (Chapter 12),
  `swap`, and writes a property passed `byref` back through its setter, which fbc does not.
- **The ten fixed-width type names**, `int8` to `float64`, are predeclared typedefs. A program's own
  declaration of one replaces tiko's.
- **Graphics is Windows-only.** The Linux and macOS toolchains ship no graphics library, so a
  program that uses `screen` builds on Windows only.
- **tiko targets x86-64 on Windows and Linux, and arm64 on macOS** (`macos-arm64`, Apple
  Silicon). There it defines `__FB_DARWIN__`, `__FB_UNIX__` and `__FB_ARM__`, and not
  `__FB_X86__`. `-m32` is `TKO0104`.

## What fbc 1.20 does not have

Generics, `for each`, tuples, `defer`, lambdas, `ustring`, the fixed-width type names, `spawn` and
channels, `#cinclude`, `#foreignlib`, `#import` and modules, auto-properties and property blocks are tiko's. Code that uses them does
not compile under FreeBASIC's own fbc, and that is not a compatibility difference:
it is the language this book teaches. A source tree that must build with both tests
`#ifdef __TIKO_COMPILER__` and keeps the extensions on one side of it.
