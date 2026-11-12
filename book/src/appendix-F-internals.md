# Appendix F: Compiler Internals {#app-internals}

This appendix is a map of the compiler for readers who want to know what happens between
`tiko hello.tiko` and `hello.exe`, or who want to read the source. tiko is written in tiko —
`.tiko` sources and `.ti` headers, built by tiko itself — and it lives in one repository,
`tiko-lang`, with its runtime, its graphics library and this book. The figures here were measured
at the commit the book is pinned to.

## The pipeline

```text
 source ─► lexer ─► preprocessor ─► parser ─► Collect ─► Resolve ─► Check ─► late checks
                                      │                                          │
                                      AST                               typed AST + symbols
                                                                                 │
     executable ◄─ clang + lld ◄─ clang -c ◄─ LLVM IR ◄─ ABI pass ◄─ MIR ◄─ lowering
```

Each stage is a separate pass over a separate representation, and each one hands the next a
finished product: the lexer does not ask the parser anything, and the backend never sees the AST.
`-v` shows the last two steps as the commands they are:

```text
clang.exe -target x86_64-pc-windows-msvc -c "hello.exe.1.o.ll" -o "hello.exe.1.o" ...
clang.exe -target x86_64-pc-windows-msvc -fuse-ld=lld "hello.exe.1.o" -o "hello.exe" ... libfb.a ...
```

**Lexer** (`src/lexer`). Bytes to tokens, one file at a time. The keyword table, `keywords.bi`,
is the 247 words of Appendix A. A token is 16 bytes: its kind, flags (did a space precede it, did a
macro make it, was it a `:`), a source location, its length in the source and a payload — an
interned name or an index into the literal pool. A source file may be UTF-8, with or without a byte-order mark, or UTF-16 or UTF-32 with one;
anything else is read as plain bytes. Each file is detected on its own and converted to UTF-8
before it is lexed.

**Preprocessor** (`src/pp`). Pulls tokens from the lexer and gives the parser one stream: macros
expanded, `#include`d files spliced in, `#if` branches chosen. It is also where `#import` is
handled: the imported module's **interface** — a `.tki` file, written in tiko source — is spliced in
as a frame of its own, with the headers its public declarations need (Chapter 15).

**Parser** (`src/parser`). Recursive descent, statement by statement, into an **AST** kept in an
arena: nodes are indices, not pointers. Operator precedence comes from one table, `prectable.bi`,
the only place in the compiler that states it. Nearly every diagnostic in this book with an id in
`TKO0400`–`TKO0599` comes from here; the two exceptions are `TKO0409`, which the preprocessor
reports, and `TKO0423`, which comes from name resolution.

**Collect, Resolve and Check** (`src/symbols`, `src/types`). Collect enters every declaration into
the symbol table. Resolve binds every name to its symbol and works out every type, instantiating
generics as it meets them. Check judges what Resolve found: conversions, overloads, arguments,
assignments. A last group of passes — visibility, abstract types, override promises, the rules
about what may be initialised how — runs once everything is known. Together they are the largest
part of the frontend, and the source of most `TKO06xx`–`TKO08xx` diagnostics.

**Lowering to MIR** (`src/mir`). MIR is tiko's one intermediate representation: functions of basic
blocks, each a list of typed instructions ending in exactly one terminator. Lowering is where
FreeBASIC's semantics are eliminated — strings and their descriptors, dynamic arrays, `print`,
`for`'s exact iteration rules, constructors and destructors, `defer`, closures, goroutine frames —
so that what comes out is plain code over plain values. A verifier checks every function before
it goes on. This is the biggest directory in the compiler.

**The ABI pass** (`src/codegen`). Rewrites each signature and call for the target's calling
convention — the Microsoft x64 convention on Windows, System V on Linux, Apple's AAPCS64 on
macOS — so the IR that follows
has no implicit ABI behaviour: which structures travel in registers, which by hidden pointer, how
a function returns one. `--dump-ir` shows MIR after this pass, so what will really be passed is
visible without reading LLVM.

**LLVM IR and clang**. The emitter writes LLVM IR as text, one `.ll` file per unit, and clang
compiles it. clang is not bundled: tiko runs whatever `TIKO_CLANG` names, else
`C:\Program Files\LLVM\bin\clang.exe` on Windows, `/usr/bin/clang` on Linux or Homebrew's
`/opt/homebrew/opt/llvm/bin/clang` on macOS, else the first
clang on the `PATH`, and it needs clang 18 or newer. The link
goes through clang with lld, or on Linux the system linker when there is no `ld.lld`; on macOS
it goes through Apple's linker with the macOS SDK.
`-O1` to `-O3` are clang's optimisations; tiko's own optimiser is deliberately thin.

**The driver** (`src/driver`). Reads the command line, decides what is being built, builds the
modules a program imports in dependency order, and runs everything above. A module is compiled
once and **cached** — its object and its interface, keyed by its sources, its options and the
interfaces of everything it imports — so a second build that
imports `std/containers` does not compile it again. `#cmdline` restarts the driver with the new
options. `#cinclude` (Chapter 29) loads libclang the first time a program uses it, to read the C
header itself.

**Diagnostics** (`src/diag`). Every message the compiler can emit is one row in one table,
`diagids.bi`, which is what Appendix B is generated from. Nothing else may invent a message, and an
id is never reused.

### Where the code is

At the pin, counting source files (`.tiko`, `.ti`, and the few `.bas`, `.c` and `.h` files), tests
included:

| Directory | Files | Lines | Holds |
|---|---:|---:|---|
| `src/support`, `src/source` | 18 | 2,437 | arenas, interning, text, files and source locations |
| `src/diag` | 9 | 1,945 | the diagnostic table and its rendering |
| `src/lexer` | 5 | 1,979 | the lexer and the keyword table |
| `src/pp` | 15 | 8,402 | the preprocessor and `#import` |
| `src/parser`, `src/ast` | 29 | 12,141 | the parser and the AST |
| `src/symbols`, `src/types` | 126 | 47,419 | Collect, Resolve, Check and the late checks; the type table |
| `src/mir` | 89 | 55,880 | MIR and lowering |
| `src/codegen` | 21 | 6,213 | the ABI pass and the LLVM IR emitter |
| `src/driver` | 43 | 9,980 | the driver, modules and linking |
| `src/build` | 8 | 1,380 | `tiko build` |
| `src/cimport` | 12 | 3,541 | `#cinclude` |
| `src/api` | 2 | 397 | the parser library an editor loads |
| `lib/rt` | 363 | 87,238 | tiko-rt, the runtime, and its tests |
| `lib/gfx` | 99 | 23,450 | libtkogfx, the graphics library, and its A/B tools |

The compiler is about 152,000 lines; with its runtime and graphics library, about 262,000. The
directories are **layered**: a module may include only modules below it, the frontend never
includes anything from MIR or the backend, and a lint pass enforces that, along with a limit of
1,500 lines per source file.

## The runtime: tiko-rt

A compiled program calls a runtime library for everything the language does that the machine does
not: strings, arrays, files, the console, errors, threads. tiko's is **tiko-rt** (`lib/rt`), and it
is a reimplementation of FreeBASIC's `libfb` **written in tiko**: 229 `.tiko` and `.ti` files and
nine small C files for what the language cannot express — atomics, the jump behind `on error`, the
start-up and shutdown hooks, the Microsoft C runtime's start-up glue, the base `Object`'s
constructor and type record, and the two port I/O instructions behind `inp` and `out` on Linux.

It is **ABI-compatible with `libfb`**: the same `FBSTRING` and array descriptor layouts, the same
`fb_*` function names and signatures. That is what makes tiko's runtime errors fbc's, number for
number, and lets an object fbc compiled call into it. The toolchain ships two builds of it,
`libfb.a` and the thread-safe `libfbmt.a`, and the driver picks the second by itself when a program
creates a thread, whether or not `-mt` was given (Chapter 23). Linux adds position-independent
variants for shared libraries. tiko-rt is built with tiko, like the compiler, and is licensed
LGPL-2.1-or-later with the static-linking exception: a program tiko compiles may carry any licence.

## The graphics library: libtkogfx

**libtkogfx** (`lib/gfx`) is FreeBASIC's graphics library, `libfbgfx`, reimplemented in tiko: the
same `fb_Gfx*` entry points, so it is a drop-in replacement. Its A/B tests (`lib/gfx/tools`) run
drawing primitives through both libraries and compare what they drew. It is
derived from FreeBASIC's `gfxlib2`, under the same LGPL licence and exception. It is built for
windows-x86_64 only, which is why graphics programs build on Windows only (Appendix D).

## Self-hosting

tiko compiles itself. `build/bootstrap.sh` (and `bootstrap.bat` on Windows) runs the whole cycle:

```text
stage0   the seed builds tiko                      -> stage1
stage1   compiles tiko's own sources               -> stage2
stage2   compiles them again                       -> stage3
```

The **seed** is a packaged tiko compiler built from an earlier commit, which the repository pins;
no other compiler takes part.
The script asserts five things: that stage1 lowers **every statement** of every module (a
statement the compiler declines would otherwise vanish from the compiler it is building); that
**stage2 and stage3 are byte-identical files**, with nothing masked, which is a reproducible link
as well as a fixpoint; that **stage1 and stage2 are identical too**, because the seed builds stage1
with exactly the command stage1 builds stage2 with; that stage3 compiles a program that prints what
the seed's build of it prints; and, with `--gate`, that the test suite fails against stage2 exactly
what it fails against stage1. A successful run reports each step (the target line that opens it
is left out here):

```text
bootstrap: stage1  built by <seed directory> in <t> s, <size> bytes
bootstrap: stage1  lowers every statement of all <n> modules; all verify
bootstrap: stage2  built by stage1 in <t> s, <size> bytes
bootstrap: stage3  built by stage2 in <t> s, <size> bytes
bootstrap: fixpoint  stage1 == stage2 as well: the seed reproduces this commit's compiler
bootstrap: fixpoint  stage2 == stage3, sha256 <first 16 hex digits>...
bootstrap: stage3  builds hello.tiko, and it prints what the seed's build prints
bootstrap: ok
```

<!-- REMEASURE: the timings, sizes, module count and sha above were dropped when the seed
replaced fbc-modern as stage0; fill them in from a bootstrap run at the pin. -->


A fixpoint proves the compiler reproduces itself. It proves nothing about code the compiler's own
source never uses, which is why the last check runs the suite.

## How it is tested

- **The test suite**: 2,046 tests at the pin, each a small program with its expected
  diagnostics, IR or output. A fix lands with the test that would have caught it.
- **fbc's own test corpus**, vendored in `tests/vendor/` and never edited, is the acceptance gate:
  every file's diagnostics are recorded, and a change that moves any of them is examined before it
  lands.
- **Differential probes.** Every compatibility fact in the compiler — and in this book — was
  established by compiling a program with fbc and with tiko and comparing the results. The source
  carries the measurement beside the code that depends on it, so a later change has to argue with
  it.
- **This book's listings**, compiled and run on every target against the pinned toolchain before
  each release of the book.
