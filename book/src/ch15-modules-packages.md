# Modules and Packages

Sooner or later a program uses two libraries written by people who never met, and both of them
define `Parse`. With `#include` there is nothing to be done about it. A header is text pasted
into the file that includes it, so both `Parse`s land in the same scope and the program does not
compile. That is not the only cost. A header's helpers are visible to everyone who includes it.
Its code is compiled again by every file that includes it. And when two libraries each need
setting up before `main` runs, the order they are set up in depends on how the program happened
to be linked.

A **module** is tiko's answer to all four. It is a directory of source files that compiles as one
unit, shows the world only what it marks `public`, keeps its names behind its own name, is built
once and cached, and is initialised in a fixed order: after everything it uses, before anything
that uses it. A **package** is a set of modules shipped together, with a small `tiko.toml` saying
what it is called and what it depends on.

This chapter builds a module, then several, then a package. Everything in it is a tiko extension:
`#include` still works exactly as Chapter 16 describes, and a program that never writes
`#import` compiles as if modules did not exist.

## What `#include` cannot do

Here are two small header libraries. `csv.ti` counts the fields in a line; `ini.ti` finds where a
value starts. Each is reasonable on its own:

```tiko
{{#include ../examples/ch15/headers/csv.ti}}
```

```tiko
{{#include ../examples/ch15/headers/ini.ti}}
```

A program that wants both cannot have them:

```tiko
{{#include ../examples/ch15/clash.tiko}}
```

```
headers/ini.ti(2,1): error TKO0600: 'parse' is already declared in this scope
     |
   2 | function Parse( byval s as ustring ) as int32
     | ^
headers/csv.ti(2,1): note: declared here
     |
   2 | function Parse( byval s as ustring ) as int32
     | ^
```

Neither author did anything wrong. The only fix available to them is to wrap their library in a
`namespace`, and every library author has to remember to do it. The problem is the mechanism:
`#include` puts every name a library declares into the scope of whoever includes it.

## A module is a directory

```text
hello.tiko
greet/
    greet.tiko
```

```tiko
{{#include ../examples/ch15/greet/greet.tiko}}
```

```tiko
{{#include ../examples/ch15/hello.tiko}}
```

```text
{{#include ../examples/ch15/hello.out}}
```

Three rules are at work.

1. **Every file of a module begins with `#module "name"`, and the name is the directory's name.**
   Comments may come first; any other directive is `TKO0360`. A name that does not match its
   directory is `TKO0361`.
2. **`#import` comes before any code.** The path is quoted, uses `/` on every platform, and
   `./greet` is relative to the file that imports it. An `#import` after any statement — even
   after a `#define` or a `#cmdline` — is `TKO0362`.
3. **The module's names are reached through the module's name.** The import binds `greet`, the
   last segment of the path, and the program calls `greet.Hello`.

Because a module's name becomes a name in the program, no segment of an import path may be a
keyword: `#import "./sub/inner"` is `TKO0364`, `'sub' is a keyword`. Name modules for what they
hold — `text`, `report` — not after statements.

There is no list of files on the command line and no build script. `tiko hello.tiko` reads the
`#import`, finds `greet/`, compiles it, and links it in.

## Who can see what

`Hello` is marked `public`; `Capitalise_` is not. Reaching for it from outside is refused, and the
message names the rule:

```tiko
{{#include ../examples/ch15/notpublic.tiko}}
```

```
notpublic.tiko(3,13): error TKO0860: 'capitalise_' is not public in module 'main.greet'
     |
   3 | print greet.Capitalise_( "world" )        '' refused
     |             ^
```

`main.greet` is the module's **chain**: its package's name followed by its path. A program with no
`tiko.toml` is the package `main`. The chain is how tiko tells two modules called `greet` apart.

A module has three levels of visibility, and **the default is the middle one**:

| You write | Visible to | Use it for |
|---|---|---|
| `public` | every file that imports the module | the module's API |
| nothing | every file of this module | helpers the module's files share |
| `private` | this module, and nothing reached from outside it | helpers nothing else may ever call |

That default is the opposite of a classic program's, where a procedure is visible everywhere
unless it says `private`. It is the right way round for a library: a helper you forgot to mark
never becomes part of your API, so you are free to change it later.

The difference between the last two is what each one means to the linker. Measured on the object
`tiko -c` writes for a module named `gen` with one procedure at each level:

| Level | Name in the object | Linux (ELF) | Windows (COFF) | macOS (Mach-O) |
|---|---|---|---|---|
| `public` | `_ZN4MAIN3GEN3APIEv` | global | external | external |
| module-private | `_ZN4MAIN3GEN7SHARED_Ev` | global, **hidden** | external | **private external** |
| `private` | `_ZN4MAIN3GEN7SECRET_Ev` | local | local | non-external |

Mach-O puts one more `_` in front of each name.

Every name is spelled from the chain, so two packages' `Parse` procedures can never collide in
the linker either. A module-private procedure is still an external symbol, because code compiled
*outside* the module sometimes has to call it: a generic's body, and an exported macro's
expansion, are compiled in the importer. A `private` one is local to the module's object and
cannot be reached that way at all. The section on generics shows the difference.

**A public procedure may not name a type that is not public.** An importer should never be handed
a value of a type it cannot name, so `public function Make( ) as Secret`, where `Secret` has no
`public`, is refused: `TKO0868: 'secret' is module-private but appears in the public declaration
of 'make'`. Every type that appears in a public signature is public too.

## A module with several files

A module may be as many files as it needs, and all of them form one module. They see each
other's non-`private` names freely, **in any order**:

```tiko
{{#include ../examples/ch15/report/report.tiko}}
```

```tiko
{{#include ../examples/ch15/report/format.tiko}}
```

```tiko
{{#include ../examples/ch15/several.tiko}}
```

```text
{{#include ../examples/ch15/several.out}}
```

`report.tiko` calls `PadRight_` and `Format_`, which are declared in another file. `PadRight_`
uses `LABEL_WIDTH`, which is declared *below* it. None of that needs a `declare` line, and there
is no internal header gluing the files together, because a module is compiled as a single unit
and its top-level declarations are collected before any of them is checked.

Inside a procedure body nothing changes: a local variable is still declared before it is used. And
code outside any module keeps declare-before-use for everything, as Chapter 7 described.

**Macros do not cross between the files of a module.** A `#define` in `report.tiko` is not visible
in `format.tiko`; each file starts from the same clean slate. A macro several files need belongs
in a small header that each of them includes.

**Imports do not cross between the files either.** An import belongs to the file that writes it,
so each file says where its own names come from. A sibling file that writes `util.` without an
`#import "../util"` of its own gets `TKO0743: 'util' is not declared`, with a note pointing at the
file that did import it: `'util' is imported by another file of this module; an import belongs to
the file that writes it`.

## One type across several files

A module's files can share procedures, constants and types, but each type is still one block in
one file. That stops working when a type has two authors. A form designer or a protocol compiler
writes fields and method declarations; you write the data and methods of your own. If the two
share a block, the tool has to edit text you own every time it runs, and one bad merge loses your
work.

`partial type` lets one type be written in several blocks. Here a tool owns one file of a module
and you own the other:

```tiko
{{#include ../examples/ch15/orderform/orderform.gen.tiko}}
```

```tiko
{{#include ../examples/ch15/orderform/orderform.tiko}}
```

```tiko
{{#include ../examples/ch15/partialform.tiko}}
```

```text
{{#include ../examples/ch15/partialform.out}}
```

The compiler combines the blocks into one `Form` before anything else reads them, so a program
importing the module sees an ordinary type, and `sizeof` counts the fields of both parts.
`Submit_Click` is declared by the tool's part and has its body in your file, where it uses `Total`
from the tool's part and `Clicks` from yours. Because the tool writes only its own file, it can
rewrite that file whenever it likes.

The rules are short:

- **Every block says `partial`.** A `partial type` and an ordinary `type` of one name are refused
  with `TKO1063`.
- **The parts live in one compilation unit**: one source file with its includes, or the files of
  one module. They are at module or namespace level, in the same namespace.
- **`public` on any part makes the type public.** The other parts need not repeat it, which is why
  your file above says only `partial type`. `public` on one part and `private` on another is an
  error.
- **Each header clause is given once.** `extends`, `inherits`, `field` and `implements` may each
  appear on one part, whichever part that is, and apply to the whole type.
- **A part can be methods alone**, as long as the whole type has a field.
- **A generic type cannot be partial.** A generic is re-read for each instantiation, from one place
  in the source.

`partial` is a keyword only directly before `type` or `class`. A variable or procedure can still be
called `partial`.

`partial class` does the same for a class. A class with no `inherits` line takes `object` as its
base, so the parts that say nothing simply take whatever base another part names:

```tiko
{{#include ../examples/ch15/partialclass.tiko}}
```

```text
{{#include ../examples/ch15/partialclass.out}}
```

The base's fields come first in the layout, wherever `inherits` was written.

````admonish danger title="Pitfall"
Fields are laid out part by part, and a module's files are read in sorted order of their names.
`orderform.gen.tiko` sorts first, so its fields come first. Rename it `zform.gen.tiko` and `Clicks`
moves to the front of `Form`. Nothing warns you, and every field still works by name. It matters
only when something depends on the layout: a record you write to a file with `put`, or a `Form ptr`
passed to C. When layout matters, keep every field in one part.
````

## Importing

`#import` has two optional parts, and the imported names can be brought into scope with `using`:

```tiko
{{#include ../examples/ch15/shapes/shapes.tiko}}
```

```tiko
{{#include ../examples/ch15/importing.tiko}}
```

```text
{{#include ../examples/ch15/importing.out}}
```

- **`as sh` renames the module for this program.** Use it when two imports end in the same name,
  or when a name is long. The module is still `shapes`; only the spelling here changes.
- **Types are reached the same way as procedures**: `dim c as sh.Circle`. A value of a module's
  type behaves exactly as one of your own: `c.Area( )` needs no qualification, because a method
  belongs to its type.
- **`using greet` makes `greet`'s public names usable bare**, as `using` does for a namespace.

When two modules you are `using` both supply a name, a bare use of it is refused rather than
guessed:

```tiko
{{#include ../examples/ch15/ambiguous.tiko}}
```

```
ambiguous.tiko(6,7): error TKO0919: 'kind' is ambiguous: more than one USING in effect declares it; qualify it
     |
   6 | print Kind( )                             '' refused
     |       ^
```

Write `tag.Kind( )` or `label.Kind( )` and move on. That is the qualified name doing its job: the
question "which `Kind`?" has an answer written in the source.

### Passing an import on

An import is private to the module that writes it. A module can pass one on to its own importers
by adding `public` to the `#import`:

```tiko
{{#include ../examples/ch15/kit/kit.tiko}}
```

```tiko
{{#include ../examples/ch15/reexport.tiko}}
```

```text
{{#include ../examples/ch15/reexport.out}}
```

`kit` re-exports `greet`, so an importer of `kit` reaches it as `kit.greet`. `shapes` is imported
without `public`, so it stays `kit`'s business:

```tiko
{{#include ../examples/ch15/noleak.tiko}}
```

```
noleak.tiko(3,11): error TKO0745: the namespace 'kit' has no member named 'shapes'
     |
   3 | print kit.shapes.PI_                       '' refused
     |           ^
```

That is what makes a module's dependencies its own to change. Swapping `shapes` for something
else inside `kit` cannot break a program that imports `kit`, because no such program could have
used it.

## Packages

So far every module has sat beside the program that uses it. Once modules are meant for more
than one program, they become a **package**: a directory tree of modules with a `tiko.toml` at its
root.

```text
acme/
    tiko.toml
    config/config.tiko
    text/pad/pad.tiko
app/
    tiko.toml
    main.tiko
```

```toml
{{#include ../examples/ch15/acme/tiko.toml}}
```

```tiko
{{#include ../examples/ch15/acme/config/config.tiko}}
```

```tiko
{{#include ../examples/ch15/acme/text/pad/pad.tiko}}
```

`pad` imports `acme/config` by its full path. Inside a package, a path that starts with the
package's own name means "this package". The module `pad`'s chain is `acme.text.pad`, and the
program still calls it `pad`: the last segment.

The program says where to find `acme`:

```toml
{{#include ../examples/ch15/app/tiko.toml}}
```

```tiko
{{#include ../examples/ch15/app/main.tiko}}
```

```text
{{#include ../examples/ch15/app/main.out}}
```

A `tiko.toml` is optional — the programs before this section had none — and you add one for four
things:

1. **A stable name.** Without one, a package is called `main`. With one, the name is written in
   the code and goes wherever the code goes.
2. **A root.** The directory holding `tiko.toml` is where the package starts. A relative import
   may not climb above it (`TKO0142`).
3. **Dependencies that travel with the project.** `acme = { path = "../acme" }` is in the
   repository, not in anyone's environment, so a fresh checkout builds with a bare `tiko main.tiko`.
4. **Settings for a library.** That is `[defines]`, and it needs a section of its own.

The file is a small subset of TOML: tables, strings, integers, booleans, inline tables and arrays
of strings. Anything it does not recognise is `TKO0144`, naming the file and line. `version` is
recorded for a future package manager and not otherwise used.

### Where an import is looked for

For `#import "acme/text/pad"`, tiko tries these in order and takes the first that has it:

| | Where | Example |
|---|---|---|
| 1 | a relative path, from the importing file | `#import "./greet"` |
| 2 | the current package, when the first segment is its name | inside acme: `#import "acme/config"` |
| 3 | a dependency in the current package's `tiko.toml` | `acme = { path = "../acme" }` |
| 4 | each `-i` directory, then each directory in `TIKO_PATH` | `TIKO_PATH=C:\tikolibs` |
| 5 | the toolchain's own `pkg/` directory | `std` |

Nothing found is `TKO0140`, and the message lists every place it looked. `std` is special: it is
always the toolchain's, so no project can replace the standard library by accident. And one build
may not find two different directories both claiming the same package name (`TKO0149`).

## Settings that cross the boundary, and settings that do not

`acme`'s `config` module reads `ACME_COLUMNS`, which no source file defines. It comes from the
package's `[defines]`, and a program that depends on `acme` can override it in its own manifest:

```toml
{{#include ../examples/ch15/tuned/tiko.toml}}
```

```text
{{#include ../examples/ch15/tuned/main.out}}
```

The same `main.tiko` now prints four-column cells. That is the only way in. **A module never sees
the macros of the program that imports it** — not its `#define`s, and not its `-d` options either.
This is deliberate, and it is what lets a module be compiled once and cached: if a program's
macros could reach into a module, every program would need its own copy of it.

````admonish danger title="Pitfall"
**`-d` does not reach a module.** A module that tests a symbol with `#ifdef` is compiled without
any symbol the importing program defines:

```tiko
{{#include ../examples/ch15/cfg/cfg.tiko}}
```

```tiko
{{#include ../examples/ch15/hermetic.tiko}}
```

```text
{{#include ../examples/ch15/hermetic.out}}
```

Both lines compile and run, and the module quietly takes its `#else` branch. Nothing warns you,
because from the module's side nothing is wrong. A setting a module is meant to take belongs in
its package's `[defines]`, which a program overrides in `tiko.toml`; or, better, in an ordinary
parameter, which the compiler checks.
````

## Initialisation

A module may have top-level statements, shared variables with constructors, and `constructor`
and `destructor` subs. tiko runs them in one order, the same on every target and whatever order
the objects are linked in:

> **A module is initialised after every module it imports, and before any code that imports it.
> Shutdown is the exact reverse.**

```tiko
{{#include ../examples/ch15/logger/logger.tiko}}
```

```tiko
{{#include ../examples/ch15/store/store.tiko}}
```

```tiko
{{#include ../examples/ch15/initorder.tiko}}
```

```text
{{#include ../examples/ch15/initorder.out}}
```

Read the output top to bottom. `logger` is set up completely — its shared `Sink` constructed, then
its top-level code — before `store`'s top-level code calls `logger.Info`. `store` is set up before
`main` runs. At the end, `store`'s destructor runs while `logger` is still there to log it, and
only then is the `Sink` destroyed. Each module is initialised once, however many modules import it.

That is the guarantee classic code cannot make. Without modules, two libraries' setup code runs
in the order the linker happened to place it, and that order differs between Windows and Linux.

**Numbered constructors keep their meaning.** `constructor 101` asks for a slot by number, and
those slots run before any module is initialised — which is why `Early` printed first. A
number must be from 101 to 65535 (`TKO0422`). Use one only for something that genuinely must
precede everything, and prefer the import order, which says *why* one thing comes before another.

## Macros and generics across modules

### Exporting a macro

A module's macros are its own unless it exports them by name, after defining them:

```tiko
{{#include ../examples/ch15/check/check.tiko}}
```

```tiko
{{#include ../examples/ch15/macros.tiko}}
```

```text
{{#include ../examples/ch15/macros.out}}
```

- **An exported macro is used qualified**, as `check.Ensure( … )`. A bare `Ensure( … )` is not a
  macro at all, so importing a module can never capture a name of yours.
- **Its body means what it meant in the module.** `Fail_` in `Ensure`'s body is `check`'s
  `Fail_`, even though the program cannot name it and has a `Fail_` of its own. Names the module
  does not declare — `items`, the macro's argument — are left as the caller wrote them.
- `__FILE__` and `__LINE__` expand where the macro is used, as they always do. And `#cond`
  shows the argument after expansion, so `check.MAX_ITEMS` appears as `10`.
- **The module's own headers keep their macros too.** When a public declaration names a type
  from one of the module's headers, your program reads that header to get the type, but the
  header's macros stop there. A module that wants a header shared whole, macros and all, says
  `public #include`. Headers from outside the package, such as `windows.bi`, are read as if you had
  included them yourself.

### Exporting a generic

```tiko
{{#include ../examples/ch15/coll/coll.tiko}}
```

```tiko
{{#include ../examples/ch15/generics.tiko}}
```

```text
{{#include ../examples/ch15/generics.out}}
```

A generic is instantiated by the program that uses it, so its body travels with the module's
interface and is compiled in the importer. That is why `Counted_` is module-private rather than
`private`: `Push`'s body calls it from the program's own code, and a module-private name is an
external symbol that code can reach. Make the helper `private` and the instantiation fails with
`TKO0743: 'counted_' is not declared`, because a `private` name does not exist outside the
module's object.

## Building

`tiko main.tiko` does everything: it finds the imports, builds each module once, and links the
result. Four options show or change what it did.

`--print-graph` lists the modules a program imports, in the order they are built, and stops.
Each line is a chain, the directory it came from, and what it imports:

```text
> tiko --print-graph main.tiko
acme.config    ../acme/config
acme.text.pad  ../acme/text/pad  [acme.config]
```

`-v` reports, per module, whether the build cache had it. Three builds of the two programs above:

```text
module acme.config: miss (new)
module acme.text.pad: miss (new)

module acme.config: hit
module acme.text.pad: hit

module acme.config: miss (define ACME_COLUMNS=4)
module acme.text.pad: miss (define ACME_COLUMNS=4)
```

**The cache** is one directory shared by every project of yours: `%LOCALAPPDATA%\tiko\modcache`
on Windows, `~/.cache/tiko/modcache` on Linux and macOS (or under `$XDG_CACHE_HOME`), and wherever
`TIKO_MODCACHE` names if you set it. Nothing is written into the project, so there is nothing to
add to `.gitignore`, and a module two projects build the same way is compiled once for both. A
build with different settings is a different entry, as the third build shows. The key is the
module's content, not file dates, so touching a file changes nothing.

What a change rebuilds, measured on `acme`:

| You change | Rebuilt |
|---|---|
| a procedure's body in `pad` | `pad` only |
| something `public` in `config` | `config`, and `pad`, because it imports `config` |
| a setting in `[defines]`, or `-g`, `-exx`, the target | every module it affects |

If you ever doubt the cache, `tiko --clean-module-cache` empties it, and
`--no-module-cache` builds without reading or writing it. Nothing is lost but time.

`--emit-tki` prints a module's **interface**, the declarations an importer is compiled against,
as ordinary tiko source:

```text
> tiko --emit-tki thermo
'' tiko-interface 1
'' module main.thermo
namespace __tko_mod_main_thermo
declare function Round1_( byval x as float64 ) as float64
public declare function ToFahrenheit( byval c as float64 ) as float64
end namespace
```

(The real output carries a `#line` before each declaration, pointing back at the source.) The
module-private `Round1_` is in it, without `public`: that is how a generic or macro body
compiled in the importer can reach it, while the importer's own code cannot.

### Objects, libraries and DLLs

The other output kinds work on a program that imports:

- `tiko -c -m main main.tiko -o out/main.o` compiles to objects, writing each module beside the
  output as its chain — `out/main.store.o`, `out/main.logger.o`. Linking `out/main.o` alone
  later finds the modules' objects through a record inside it.
- `tiko -lib` puts every module's object into the archive, so the library is complete on its own.
- `tiko -dll` links the modules in and exports only what the root marks `export`. A module's
  names never are.

`__TKO_MODULE__` is defined while a module is compiled and not otherwise, and `__TIKO_COMPILER__`
is defined by tiko always: the test for "am I being compiled by tiko", for code that must also
build elsewhere.

## The standard library as a package

The standard library is the package `std`, shipped in the toolchain's `pkg/` directory. Its
modules are `strings`, `fs`, `containers`, `chrono`, `tasks`, `outcome`, `numeric`, `money`,
`logs`, `tui` and `memory`, and the library chapters (Part IV) use them throughout:

```tiko
{{#include ../examples/ch15/stdlib.tiko}}
```

```text
{{#include ../examples/ch15/stdlib.out}}
```

These are ordinary modules, built the way this chapter describes: compiled once, cached, and
initialised in import order. Everything in the chapter applies to them:

- **`using strings` makes `Replace` a bare name**, as for any module. Two `using`s that supply
  the same name -- `strings.Contains` and `containers.Contains` -- are `TKO0919` when the name is
  used bare; qualify it.
- **Their macros are exported**, and used qualified: `logs.LogInfo( "started" )`.
- **A statement may need one.** `spawn` and `select channel` lower to `std/tasks`, so a file that
  uses them imports it (`TKO0423` otherwise), and builds with `-mt`.

## Converting a header library into a module

Most existing libraries are headers. Moving one to a module is mostly mechanical, and the result
is easier to use and cheaper to build. Here is a header library, the classic way:

```tiko
{{#include ../examples/ch15/classic/thermo.ti}}
```

```tiko
{{#include ../examples/ch15/classic.tiko}}
```

And the same library as a module, with a program using it:

```tiko
{{#include ../examples/ch15/thermo/thermo.tiko}}
```

```tiko
{{#include ../examples/ch15/converted.tiko}}
```

Both programs print the same line:

```text
{{#include ../examples/ch15/converted.out}}
```

The recipe, file by file:

| Step | Header library | Module |
|---|---|---|
| Place | `thermo.ti` | `thermo/thermo.tiko`, beginning `#module "thermo"` |
| Guard | `#pragma once` | gone: a module file is never included |
| Namespace | `namespace Thermo … end namespace` | gone: the module *is* the namespace |
| API | `private function ToFahrenheit` (every includer gets a copy) | `public function ToFahrenheit` |
| Helpers | `private function Round1_` | no keyword: module-private |
| Library-internal includes | `#include once "other.ti"` | `#import` of the module that holds it |
| API macros | `#define` | `#define` then `#export`; or, better, a procedure |
| Configuration macros | "define this before you include me" | `[defines]` in the package's `tiko.toml` |

Two steps need judgement. **Headers that include each other** cannot become two modules, because
imports may not form a cycle (`TKO0141`, which names the cycle); merge them into one module, or
move what they share into a third. And **a system header your public signatures mention** — a
Windows handle type, say — stays an `#include` in the module. The module's interface records that
it needs the header, and including it again in the importer is harmless: it is the same file, read
once.

## What it costs

- **A module is compiled once and cached**, so the first build of a program that imports a large
  module is slow and every later build is not. A header library is compiled again by every file
  that includes it, every time.
- **Changing a public declaration rebuilds every module that imports it**, directly or through
  others. Changing a body rebuilds one module. Keep public interfaces stable and the rebuild stays
  small.
- **Calls across a module boundary are ordinary calls.** A module is not a separate binary at run
  time; the linker joins everything into one executable, as before.
- **Generics are instantiated in the importer**, so each program that uses `coll.Stack( of int32 )`
  compiles that instance itself, and a program that instantiates many pays in compile time and
  binary size exactly as Chapter 17 described.
- **The cache costs disk space** and is never cleaned on its own. `--clean-module-cache` empties it.

## Summary

- `#include` pastes a library into its includer: two libraries' names collide (`TKO0600`), helpers
  are visible to all, and the code is compiled again by every includer.
- **A module is a directory**; every file begins `#module "name"`, matching the directory
  (`TKO0360`, `TKO0361`). `#import "./greet"` comes before any code (`TKO0362`) and binds `greet`.
- **Module-private is the default.** `public` exports; `private` keeps a name inside the module's
  object. Names are spelled from the module's chain, so they never collide in the linker either.
- **`partial type` and `partial class` write one type in several blocks**, usually two files of one
  module, so a tool's half and yours never edit each other's text. Fields follow file-name order.
  Reaching a module-private name is `TKO0860`.
- **Inside a module, declaration order does not matter**, across files or within one. Macros do
  not cross between its files.
- `#import … as x` renames; `using` makes public names bare, and a name two `using`s supply is
  `TKO0919`. `#import … public` re-exports; otherwise imports never leak (`TKO0745`).
- **A package is a directory tree with a `tiko.toml`**: a name, a root, `path` dependencies, and
  `[defines]` a program overrides through `[dependencies.NAME.defines]`.
- **A module never sees its importer's macros or `-d` options**, which is what makes it cacheable,
  and which silently takes a module's `#else` branch if you expect otherwise.
- **Modules initialise after what they import and finalise in reverse**, once each, the same on
  every target. Numbered constructors run first.
- `#export NAME` shares a macro, used qualified and hygienic. An exported generic is instantiated
  in the importer, so its helpers must be module-private, not `private`.
- `--print-graph`, `-v`, `--no-module-cache`, `--clean-module-cache` and `--emit-tki` show and
  control the build; `-c`, `-lib` and `-dll` work on programs that import.
- `std` is a package in the toolchain, and its modules are ordinary modules.
- Converting a header library: add `#module`, drop the guard and the namespace, mark the API
  `public`, unmark the helpers, and turn configuration macros into `[defines]`.

## Exercises

1. Write a module `temp` with public `CToF` and `FToC` and a module-private rounding helper, and a
   program that prints a table from −10 to 30 degrees in steps of 10, converting each value there
   and back. {solution="ex15-01"}
2. Write a module `counter` whose top-level code prints that it is initialising and whose
   `destructor` sub prints that it is done, with a public shared `hits`. Import it from two
   modules, `left` and `right`, that each add one to `hits`, and import all three from a program.
   Predict how often `counter` initialises, then run it. {solution="ex15-02"}
3. Move `report`'s `LABEL_WIDTH` into a third file of the module. What did you have to change
   elsewhere, and why?
4. Make `acme`'s column count a parameter of `pad.Cell` instead of a `[defines]` setting. What
   does the program gain, and what does the package lose?
5. Take a header library of your own and convert it with the recipe. Which step needed a
   decision rather than an edit?
