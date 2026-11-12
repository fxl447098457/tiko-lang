# Namespaces, Headers and the Preprocessor

A program outgrows one file long before it outgrows one author. The geometry goes in one file, the
measuring in another, the program that uses them in a third, and each has to know enough about the
others to call them. Chapter 15 builds that out of modules, which is what new code should do. This
chapter is the machinery underneath: files compiled one at a time and joined by the linker, headers
that tell each file what the others provide, namespaces that keep their names apart, and the
**preprocessor**, which rewrites the source before the compiler reads a word of it.

You need all of it anyway. Every binding to a C library is a header. Every program that must
behave differently on Windows, Linux and macOS says so with the preprocessor. And a module is itself
built from these parts, so the rules here are the ones that hold underneath Chapter 15.

## A program in several files

Here is a small program in three source files. The part they share goes in a **header**, a `.ti`
file that declares what exists without defining it:

```tiko
{{#include ../examples/ch16/geometry.ti}}
```

`declare` promises a procedure that some other file defines; `extern` promises a variable. The
two source files keep those promises. `shapes.tiko` defines the procedures, and `measure.tiko` owns
the counter:

```tiko
{{#include ../examples/ch16/shapes.tiko}}
```

```tiko
{{#include ../examples/ch16/measure.tiko}}
```

The main file includes the same header and uses all of it:

```tiko
{{#include ../examples/ch16/geometry.tiko}}
```

```text
{{#include ../examples/ch16/geometry.out}}
```

Build it by naming every source file; the first one named is the program:

```text
tiko geometry.tiko shapes.tiko measure.tiko -o geometry
```

Each `.tiko` file is compiled **on its own**, as if the others did not exist. That is why each one
includes the header: a file knows only what it has been told. The linker then joins the compiled
files and connects every `declare` and `extern` to the one definition behind it. `dim shared
measured` in `measure.tiko` is that definition; `extern measured` in the header lets the other two
files use it.

`#include` pastes a file's text in place. `#include once` pastes it only the first time, and
`#pragma once` at the top of a header says the same thing from the inside, so the header is safe
however many times it is reached. `geometry.ti` says both ways, which costs nothing.

### Where `#include` looks

```tiko
{{#include ../examples/ch16/platform.tiko}}
```

```tiko
{{#include ../examples/ch16/include/platform.ti}}
```

```tiko
{{#include ../examples/ch16/include/separator.ti}}
```

`platform.tiko` names `include/platform.ti`, a path relative to itself. `platform.ti` then
includes `separator.ti` with no directory at all, and finds it beside `platform.ti`: **a name is
looked for first beside the file that includes it**, not beside the program's first file. That is
what lets a header bring its own helpers along without knowing where it will be used from.

When the file is not there, tiko tries the directory the compiler was run in, then each directory
given with `-i`, in the order they were given, and finally its own `inc/`, which holds the C
bindings and the classic headers that ship with the toolchain. The first place that has the file
wins. So a header of your own in the working directory, named like one of the toolchain's, is the
one your files get when they include that name, in place of the toolchain's. Give your headers
names of their own, or include them by a path relative to the file that needs them.

### Headers or modules?

Chapter 15 opens with the two problems headers cannot solve: every name a header declares lands in
the scope of whoever includes it, and its code is compiled again by every file that does. For your
own code, a module is the better tool. Headers remain the right one for a binding to a C library,
for macros meant to be shared between files, and for existing code that is already written as
headers.

## Linkage

Two files compiled on their own can both define a name, and neither compile notices. The linker
does:

```tiko
{{#include ../examples/ch16/clash.tiko}}
```

```tiko
{{#include ../examples/ch16/clashother.tiko}}
```

```
lld-link: error: duplicate symbol: INIT
clang: error: linker command failed with exit code 1 (use -v to see invocation)
tiko-lang: error TKO0116: link failed (exit 1)
```

(The linker's two `>>> defined at` lines, which name the temporary object files, are left out.)

A procedure is **public** by default: its name is visible to the linker, so every other file can
call it, and two files cannot both have one. **`private`** keeps a procedure inside its own file.
Make one of the two `Init`s private and the program links. The file that owns it reaches it
through a public procedure:

```tiko
{{#include ../examples/ch16/privatefixother.tiko}}
```

```tiko
{{#include ../examples/ch16/privatefix.tiko}}
```

```text
{{#include ../examples/ch16/privatefix.out}}
```

Make helpers `private` as a habit. A public helper is a name another file can collide with, and an
entry point nobody meant to offer.

### Private by default, for a region

Marking every helper costs a word on each one. `#pragma push( private, true )` turns the default
around until the matching `#pragma pop( private )`. Inside the region a procedure is private unless
it says `public`:

```tiko
{{#include ../examples/ch16/pragmaother.tiko}}
```

```tiko
{{#include ../examples/ch16/pragma.tiko}}
```

```text
{{#include ../examples/ch16/pragma.out}}
```

`pragma.tiko` can reach `Save`, which follows the region, and `Flush`, which says `public` inside
it. Declaring `Validate` there and calling it would fail at the link: no file offers a public
`Validate`.

### Shared variables

You have seen one way to share a variable: `dim shared` in exactly one file and `extern` in the
header. The other is **`common`**. Every file that declares the same `common shared` variable gets
the same storage, and no file has to be the owner:

```tiko
{{#include ../examples/ch16/tally.tiko}}
```

```tiko
{{#include ../examples/ch16/tallyother.tiko}}
```

```text
{{#include ../examples/ch16/tally.out}}
```

Prefer `extern`. With `extern`, one file says where the variable lives and the header says what it
is, so a mismatch is caught when the files are compiled. `common` makes every file restate the
declaration, and nothing checks that they agree: declared `int32` in one file and `float64` in
the other, the program still links, and counts wrong.

## Startup and shutdown

A program sometimes has work to do before its first statement, and after its last. A sub marked
**`constructor`** runs before the main program; one marked **`destructor`** runs after it. A
number after the keyword is a **priority**:

```tiko
{{#include ../examples/ch16/startup.tiko}}
```

```tiko
{{#include ../examples/ch16/startupconfig.tiko}}
```

```text
{{#include ../examples/ch16/startup.out}}
```

Constructors run lowest priority first, and destructors run in the opposite order, so whatever
started first is shut down last: the configuration is saved before the log it writes to is closed.
Give anything that depends on something else a higher number than the thing it depends on.

Look at where `startupconfig.tiko`'s own top-level code ran: before the main program, after the
constructors. Only one file is the **main module**, whose top-level code is the program. Every
other file's top-level code runs as part of startup. The main module is the first file named,
unless `-m` names another:

```tiko
{{#include ../examples/ch16/whichmain.tiko}}
```

```tiko
{{#include ../examples/ch16/whichmainother.tiko}}
```

```text
{{#include ../examples/ch16/whichmain.out}}
```

`#cmdline "-m whichmainother"` puts the option in the source, so the listing builds the same way
whoever compiles it.

## Namespaces

A `private` procedure is hidden from other files, but that does not help when two parts of the
*same* program both want a function called `Area`. A **namespace** gives names a family name:

```tiko
{{#include ../examples/ch16/namespaces.tiko}}
```

```text
{{#include ../examples/ch16/namespaces.out}}
```

- **Outside the namespace, a member is written qualified**: `Geo.Area`, `Geo.Units.CM_PER_M`.
- **Namespaces nest**, and the path is written out in full.
- **A namespace can be reopened.** The second `namespace Geo` adds `Perimeter` to the same
  namespace, and another file can do the same.
- **`using Geo`** makes Geo's members usable without the prefix, from the `using` to the end of
  the block that contains it: here, the sub `Report`. Written at the top of a file, it lasts to the
  end of the file.

### How a name is found

`using` makes a namespace's names *available*. It does not make them *preferred*:

```tiko
{{#include ../examples/ch16/lookup.tiko}}
```

```text
{{#include ../examples/ch16/lookup.out}}
```

Inside `Show`, `LIMIT` and `Label` are both declared twice: once in `Defaults`, which `using`
brings in, and once at module level. **A name declared on the way out — in the procedure, then in
the enclosing scopes, then the module — beats every `using`.** The namespace's members are reached
only where nothing closer has the name. To mean the namespace's, qualify it.

When two `using`s both supply a name and nothing closer declares it, tiko does not pick one:

```tiko
{{#include ../examples/ch16/ambiguous.tiko}}
```

```
ambiguous.tiko(14,7): error TKO0919: 'title' is ambiguous: more than one USING in effect declares it; qualify it
     |
  14 | print Title( )
     |       ^
```

## Macros

The preprocessor reads the source before the compiler does, and **macros** are its main tool. A
macro is a name for a piece of text, and the preprocessor replaces every use of the name with the
text:

```tiko
{{#include ../examples/ch16/macros.tiko}}
```

```text
{{#include ../examples/ch16/macros.out}}
```

- **`#define LIMIT 100`** is an object-like macro: `LIMIT` becomes `100` wherever it appears.
- **`#define SQUARE( x ) ...`** takes arguments. The text of each argument is substituted for the
  parameter, unevaluated.
- **`#x`** turns an argument into a string literal, so `AS_TEXT( width1 + width2 )` is the text
  `width1 + width2`, not the sum.
- **`prefix##n`** pastes two pieces into one token: `PASTE( width, 2 )` becomes the identifier
  `width2`.
- **`#macro` … `#endmacro`** defines a macro that spans several lines, which is how a macro expands
  to whole statements. `SWAP_VALUES` wraps its temporary in a `scope` so that two uses in one
  procedure do not both declare `t_`.

A macro cannot take the name of a reserved word: `#define print 1` is `TKO0371`, "'print' cannot be
defined as a macro: it is a reserved word".

````admonish danger title="Pitfall"
**A macro substitutes text, not values.** The parentheses in `SQUARE` are not decoration:

```tiko
{{#include ../examples/ch16/badsquare.tiko}}
```

```text
{{#include ../examples/ch16/badsquare.out}}
```

`BAD_SQUARE( 1 + 2 )` becomes `1 + 2 * 1 + 2`, which is 5. Wrap every parameter in parentheses,
and the whole body too: without the outer pair, `100 / SQUARE( 5 )` would divide by the first `5`
and multiply by the second. A function has neither problem, and should be the first thing you
reach for. Use a macro for what a function cannot do.
````

What a function cannot do is generate code. This macro writes an `enum` and a function that names
its values, from one list:

```tiko
{{#include ../examples/ch16/enumnames.tiko}}
```

```text
{{#include ../examples/ch16/enumnames.out}}
```

Each value is written once, so the names can never disagree with the enum. `name##_Name` builds
the function's name from the enum's, and `#a` turns each value into its own spelling.

### The built-in macros

A family of built-in macros works on macro arguments themselves:

```tiko
{{#include ../examples/ch16/builtins.tiko}}
```

```text
{{#include ../examples/ch16/builtins.out}}
```

| Macro | Gives |
|---|---|
| `__FB_ARG_COUNT__( ... )` | how many comma-separated arguments it was given |
| `__FB_ARG_EXTRACT__( n, ... )` | the argument at position `n`, counting from 0 |
| `__FB_ARG_LEFTOF__( arg, sep )`, `__FB_ARG_RIGHTOF__( arg, sep )` | the text on either side of `sep` |
| `__FB_QUOTE__( text )`, `__FB_UNQUOTE__( "text" )` | text as a string literal, and a string literal as text |
| `__FB_EVAL__( expr )` | the constant expression's value, worked out by the preprocessor |
| `__FB_JOIN__( a, b )` | `a` and `b` pasted into one token, like `##` |
| `__FB_UNIQUEID_PUSH__( id )`, `__FB_UNIQUEID__( id )`, `__FB_UNIQUEID_POP__( id )` | a name no other expansion can produce |

The last row is what makes a macro safe to use twice. `TIMES_TWO` needs a temporary, and a fixed
name would be declared twice the second time the macro is used. `__FB_UNIQUEID__( tmp )` names a
fresh one for each expansion.

## Conditional compilation

`#if`, `#ifdef`, `#elseif`, `#else` and `#endif` choose which lines are compiled at all. A line
in a branch not taken is never compiled, so it can call things that do not exist on that platform.
`platform.ti`, above, is the usual use: one source, a different constant on each platform. The
platform symbols tiko defines:

| Symbol | Defined on |
|---|---|
| `__FB_WIN32__` | Windows |
| `__FB_LINUX__`, `__FB_UNIX__` | Linux |
| `__FB_DARWIN__`, `__FB_UNIX__`, `__FB_ARM__` | macOS |
| `__FB_64BIT__` | every 64-bit target |
| `__FB_MSVC__` | the `windows-x86_64` target |
| `__TIKO_VERSION__` | always: tiko's version, as a string |

You define your own on the command line: `-d NAME=value` is `#define NAME value` before the first
line of every file.

````admonish danger title="Pitfall"
**`#ifdef` asks whether a name is defined, not what it is.**

```tiko
{{#include ../examples/ch16/ifdeftrap.tiko}}
```

```text
{{#include ../examples/ch16/ifdeftrap.out}}
```

`TRACE` is defined, as `0`, so every `#ifdef TRACE` in the program is true and the tracing it was
meant to turn off is compiled in. Choose one convention per switch and keep to it: either a switch
is defined or not, and you test it with `#ifdef`, or it always has a value, and you test it with
`#if`. `#if defined( NAME ) andalso NAME <> 0` covers a name that might be either.
````

## Compile-time checks

The preprocessor can also ask questions about the program, and stop the build when the answer is
wrong:

```tiko
{{#include ../examples/ch16/checks.tiko}}
```

```text
{{#include ../examples/ch16/checks.out}}
```

- **`defined( NAME )`** is true when `NAME` has been declared — as a macro, or as anything else
  above the line — and it combines with `andalso`, `orelse` and `not`.
- **`#if typeof( a ) = typeof( b )`** compares two types exactly: `int32` is not `int64`, and a
  pointer is not what it points to.
- **`#assert`** stops the build when its condition is false. `Header` is a record written to files;
  if a field is ever added, the build stops at the `#assert`, before a file in the old layout is
  misread.

**`#error`** stops the build with a message of your own:

```tiko
{{#include ../examples/ch16/unsupported.tiko}}
```

```
unsupported.tiko(3,5): error TKO0309: #error: "build with -d CONFIG=1 (development) or 2 (release)"
     |
   3 |     #error "build with -d CONFIG=1 (development) or 2 (release)"
     |     ^
```

Built with `-d CONFIG=1`, the same file prints `configuration 1`. The `print` sits in the `#else`
branch for a reason: `#error` reports, and the compiler carries on reading the rest of the file
for more errors, so a `print` that used `CONFIG` after the `#endif` would add a second error,
about a name that is not declared. Keep the code that needs the setting in the branch that has it.

`#print` is the gentle form. `#print the build is starting` reports its text as a note,
`TKO0315`, and the build goes on.

## Source information and pragmas

The compiler knows where every line came from, and tells you:

```tiko
{{#include ../examples/ch16/sourceinfo.tiko}}
```

```text
{{#include ../examples/ch16/sourceinfo.out}}
```

- **`__LINE__`** is the line it is written on, and **`__FILE__`** the file's name.
- **`__FUNCTION__`** is the enclosing procedure's name, in upper case.
- **`__DATE_ISO__`** is the date of the build as `yyyy-mm-dd`, which is why the listing prints only
  its length: the date changes every day, and an expected output cannot.
- **`#line 1000 "generated.tiko"`** tells the compiler that the *next* line is line 1000 of
  `generated.tiko`. A program that writes tiko source for another program uses it, so errors point
  at the file a person edits rather than the generated one.

Diagnostics use the same information, so after a `#line` they point where it says.

Pragmas are instructions to the compiler. You have met `#pragma once` and `#pragma push( private,
true )`. `#pragma reserve` keeps a name from being declared at all, which lets a library claim a
name now and fill it in later:

```tiko
{{#include ../examples/ch16/reserved.tiko}}
```

```
reserved.tiko(4,1): error TKO0769: 'checksum' is reserved by '#pragma reserve' and cannot be declared
     |
   4 | function Checksum( byval s as ustring ) as uint32
     | ^
```

`#lang "fb"` names the language a file is written in. It is the only one tiko accepts, so you
never need to write it; any other is `TKO0317`.

## What it costs

- **A header is compiled again by every file that includes it.** That is nothing for a few
  declarations and a great deal for a large C binding included by fifty files. Modules exist to
  pay that cost once (Chapter 15).
- **Linking is where separately compiled files meet**, so a clash or a missing definition is found
  last, after every file has compiled, and reported by the linker in the linker's terms.
- **A macro has no type and no scope.** It is checked only after it is expanded, so a mistake in a
  macro is reported at every use, in terms of the expanded text.
- **A branch of conditional compilation is compiled only on the platform that takes it.** Code
  for Linux that is never built on Linux is code nobody has compiled. Build every target you
  claim to support.
- **Namespaces cost nothing when the program runs.** A namespace changes the name the linker
  sees, not the code.

## Summary

- A program can be several files, each compiled on its own and joined by the linker. A header
  (`.ti`) declares what the files share: `declare` for procedures, `extern` for variables. Exactly
  one file defines each.
- `#include once` and `#pragma once` make a header safe to reach more than once. A header is
  looked for first beside the file that includes it, then in the working directory, then in each
  `-i` directory in turn, then in tiko's `inc/`.
- Procedures are public by default. `private` keeps one in its file, and `#pragma push( private,
  true )` … `#pragma pop( private )` makes private the default for a region.
- `dim shared` in one file with `extern` in the header shares a variable; `common shared` makes
  every declaring file share one, unchecked.
- `constructor` and `destructor` subs run before and after the main program, lowest priority first
  and last respectively. Other files' top-level code runs during startup; `-m` chooses the main
  module.
- A namespace qualifies names. It nests and can be reopened; `using` makes its members available
  to the end of the enclosing block, but any closer declaration of the name wins, and two `using`s
  supplying the same name is `TKO0919`.
- Macros substitute text: parenthesise parameters and bodies, use `#` to quote, `##` to paste, and
  `#macro` for whole statements. Prefer a function unless the macro generates code.
- `#if` tests a value and `#ifdef` tests a definition. Platform symbols include `__FB_WIN32__`,
  `__FB_LINUX__`, `__FB_DARWIN__`, `__FB_64BIT__` and `__FB_MSVC__`; `-d` defines your own.
- `defined( )`, `#if typeof`, `#assert` and `#error` check the program while it compiles. `#error`
  reports and the compiler reads on.
- `__FILE__`, `__LINE__`, `__FUNCTION__` and `__DATE_ISO__` describe the source; `#line` renumbers
  it. `#pragma reserve` claims a name.

## Exercises

1. Write `CUBE( x )` so that `CUBE( 1 + 1 )` is 8 and `100 \ CUBE( 2 )` is 12. Then call it with a
   function that prints each time it runs. How many times does it run, and why?
   {solution="ex16-01"}
2. Write a `#macro` `DEFINE_COUNTER( name )` that defines a function `Next<name>` returning 1, 2,
   3 … on successive calls, so that `DEFINE_COUNTER( Order )` gives `NextOrder( )`. Define two
   counters and show they count separately. {solution="ex16-02"}
3. Write a program that prints the name of the environment variable that holds the temporary
   directory: `TEMP` on Windows, `TMPDIR` on Linux and macOS. Make it refuse to build anywhere else.
   {solution="ex16-03"}
4. Put a function `Area` in a namespace `Disc` (one radius) and another in a namespace `Rect`
   (width and height). Call the first without its prefix from a sub, and the second qualified.
   {solution="ex16-04"}
5. Take `clash.tiko` and `clashother.tiko` and make them link with `#pragma push( private, true )`
   instead of the word `private`. Which file did you change, and why that one?
