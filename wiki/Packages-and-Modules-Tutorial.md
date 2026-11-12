[Home](Home) › **Packages and Modules Tutorial**

# Packages and Modules Tutorial

**Who this is for:** a tiko programmer who has written programs in one file, and maybe used
`#include`, but has never written `#import`. No knowledge of modules or packages is assumed.

By the end you will be able to use the standard library, use a C library the toolchain ships
(SQLite), split your own program into modules, and choose how a C library is linked into it.

**What you need:** a tiko toolchain. The commands below write `tiko`; use the full path to
`tiko.exe` (Windows) or `tiko` (Linux and macOS) if it is not on your `PATH`. Every program in this tutorial
was compiled and run on windows-x86_64, and the output shown is the real output.

---

## Contents

| # | Section | What you learn |
|---|---|---|
| 1 | [Four words](#1-four-words) | Module, package, import, and the packages the toolchain ships |
| 2 | [Your first import](#2-your-first-import) | `#import "std/strings"` and qualified names |
| 3 | [Shorter names: `using` and `as`](#3-shorter-names-using-and-as) | Dropping or renaming the prefix |
| 4 | [What is in `std`](#4-what-is-in-std) | The standard library's modules |
| 5 | [When an import goes wrong](#5-when-an-import-goes-wrong) | The four mistakes everyone makes once |
| 6 | [Your own module](#6-your-own-module) | A directory, `#module`, `public` |
| 7 | [Vendor packages: C libraries](#7-vendor-packages-c-libraries) | `#import "vendor/sqlite3"` |
| 8 | [`link static` and `link dynamic`](#8-link-static-and-link-dynamic) | Choosing how the library is linked |
| 9 | [A module around a C library](#9-a-module-around-a-c-library) | Keeping SQLite in one place |
| 10 | [Growing into a package](#10-growing-into-a-package) | `tiko.toml` and dependencies |
| 11 | [Seeing what the compiler did](#11-seeing-what-the-compiler-did) | `--print-graph`, `-v`, the build cache |
| — | [Cheat sheet](#cheat-sheet) | Every form of `#import` on one page |
| — | [Messages](#messages) | The errors this tutorial shows, and what they mean |

---

## 1. Four words

- A **module** is a directory of tiko source files that compiles as one unit. It shows other code
  only what it marks `public`, and its names are reached through the module's name:
  `strings.Replace`, not `Replace`.
- A **package** is a set of modules shipped together. A package can be the toolchain's, someone
  else's, or your own project.
- **`#import`** is the line that brings a module into your file. It names the module by a path:
  `#import "std/strings"` is the module `strings` of the package `std`.
- The toolchain ships two packages:
  - **`std`**, the standard library: strings, files, containers, dates, concurrency and more. It is
    written in tiko.
  - **`vendor`**, popular C libraries — SQLite, raylib, SDL3, cJSON — ready to use, with the
    library files included.

You do not install, download or configure either of them. If tiko is installed, `std` and `vendor`
are there.

> **`#import` or `#include`?** `#include` pastes a file's text into yours, and every name in it
> lands in your scope. `#import` brings in a module that was compiled once, keeps its names behind
> its own name, and shows you only its public part. Use `#import` for libraries; `#include` still
> works for headers.

---

## 2. Your first import

```freebasic
#import "std/strings"

dim as ustring who = "world"
print strings.Format( "Hello, {}!", who )
print strings.Replace( "red, green, blue", ", ", " | " )
print strings.StartsWith( "tiko-lang", "tiko" )
```

```
tiko hello.tiko
```

```
Hello, world!
red | green | blue
true
```

Three rules are at work, and they are the same for every import you will ever write.

1. **`#import` comes first**, before any code. Comments may come before it; statements may not.
2. **The path is quoted and uses `/`**, on Windows too. `"std/strings"` is not a file name: it names
   a module, and tiko knows where the toolchain keeps it.
3. **The module's names are reached through the last part of the path.** `"std/strings"` gives you
   `strings`, so you write `strings.Format` and `strings.Replace`.

You did not list any other file on the command line, and you did not tell tiko to link anything.
`tiko hello.tiko` read the `#import`, found the module, compiled it the first time (it is cached
after that — see [section 11](#11-seeing-what-the-compiler-did)) and linked it in.

---

## 3. Shorter names: `using` and `as`

Writing `strings.` before every call is clear, but it gets long when a file uses one module a lot.
There are two ways to shorten it.

### `using`: drop the prefix

```freebasic
#import "std/strings"
#import "std/containers"

using containers

dim as ustring text = "the cat saw the dog and the dog saw the cat"
dim counts as OrderedMap( of ustring, int32 )

for each w as ustring in strings.Split( text, " " )
    counts[ w ] += 1
next

for each kv in counts
    print strings.Format( "{:<5} {}", kv.key, kv.value )
next
```

```
and   1
cat   2
dog   2
saw   2
the   4
```

`using containers` lets this file write `OrderedMap` instead of `containers.OrderedMap`. The other
import, `strings`, is still written in full. That is a reasonable habit: `using` for the module a
file is about, the full name for the rest, so a reader can see where each name comes from.

### `as`: rename the module

```freebasic
#import "std/strings" as txt
#import "std/fs"

print txt.Format( "{} has the extension {}", "notes.txt", fs.PathExtension( "notes.txt" ) )
print fs.PathStem( "reports/2026/summary.csv" )
```

```
notes.txt has the extension .txt
summary
```

`as txt` changes what *this file* calls the module. Nothing else changes: the module is still
`strings`, and another file can import it under its own name. Use `as` when two imports end in the
same word, or when a name is long.

### When `using` is not enough

Two modules may both have a name. `strings` and `containers` both have a `Contains`. With both
`using`s in effect, a bare `Contains` is refused instead of guessed:

```freebasic
#import "std/strings"
#import "std/containers"

using strings
using containers

print Contains( "tiko-lang", "lang" )
```

```
amb.tiko(7,7): error TKO0919: 'contains' is ambiguous: more than one USING in effect declares it; qualify it
     |
   7 | print Contains( "tiko-lang", "lang" )
     |       ^
```

The fix is the one the message gives: write `strings.Contains( "tiko-lang", "lang" )`, and the
program prints `true`.

---

## 4. What is in `std`

Every module below is imported as `#import "std/<name>"` and used as `<name>.Something`.

| Module | What it holds | Reference |
|---|---|---|
| `std/strings` | `Split`, `Join`, `Replace`, `Between`, padding, `Format` | [String Library](Category-String-Library) · [Format](Category-Format) |
| `std/containers` | `Array`, `Map`, `Set`, `OrderedMap`, `OrderedSet`, `LinkedList`, `PriorityQueue`, `Deque`, `BitSet`, sorting, searching | [Map](Category-Map) · [Array](Category-Array) · [Sorting](Category-Sorting) · [Searching](Category-Searching) |
| `std/fs` | Paths, files, directories, globbing | [Filesystem](Category-Filesystem) |
| `std/chrono` | Dates, times, durations, time zones | [Date and Time](Category-Date-and-Time-Chrono) |
| `std/tasks` | `spawn`, channels, `select channel`, wait groups (build with `-mt`) | [Goroutines and Channels](Category-Goroutines-and-Channels) |
| `std/outcome` | `Result` and `Optional`: a value or a reason there is none | [Result](Category-Result) · [Optional](Category-Optional) |
| `std/numeric` | Maths: rounding, statistics, random numbers, vectors and matrices | [Math Library](Category-Math-Library) |
| `std/money` | Decimal money arithmetic and financial functions | [Finance](Category-Finance) |
| `std/logs` | Logging at levels, to the console or a file | [Logging](Category-Logging) |
| `std/tui` | Terminal user interfaces | [Terminal UI](Category-Terminal-TUI-Library) |
| `std/memory` | Smart pointers | [Smart Pointers](Category-Smart-Pointers) |
| `std/codec` | Base64, hex and percent-encoding; numbers in byte buffers | [Codec](Category-Codec) |
| `std/uuids` | UUIDs: random and time-ordered | [UUID](Category-UUID) |
| `std/hash` | Checksums, SHA-2, HMAC | [Hash](Category-Hash) |
| `std/os` | Arguments, environment, host facts, Ctrl-C | [OS](Category-OS) |
| `std/process` | Running other programs, pipes, exit codes | [Process](Category-Process) |
| `std/config` | INI and TOML files: read, query, write | [Config](Category-Config) |
| `std/net` | IP addresses, host lookup, TCP and UDP sockets, URLs and query strings | [Net](Category-Net) |
| `std/tls` | TLS client and server streams over any connected stream | [HTTP and TLS](Category-Http) |
| `std/http` | an HTTP/1.1 client: `http` and `https`, redirects, connection reuse | [HTTP and TLS](Category-Http) |

A few language statements need a module too. `spawn` and `select channel` are built on
`std/tasks`, so a file that uses them writes `#import "std/tasks"` (without it, the compiler says
`TKO0423`) and is built with `-mt`.

A module may import other modules. `std/strings` imports `std/containers`, because `Split` returns
an `Array`. You do not have to import `std/containers` to use the array `Split` gives you — but you
do to write the type's name yourself, as `containers.Array( of ustring )`.

---

## 5. When an import goes wrong

Each of these is a mistake worth making once on purpose, so you recognise the message.

**The import is below some code.**

```freebasic
print "starting"
#import "std/strings"
```

```
late.tiko(2,1): error TKO0362: '#import' must come before any code, in the compiled file
```

Move every `#import` to the top of the file.

**The name is used without its module.**

```freebasic
#import "std/strings"

print Replace( "a-b", "-", "+" )
```

```
bare.tiko(3,7): error TKO0743: 'replace' is not declared
```

Write `strings.Replace`, or add `using strings`.

**The module's name is a keyword.**

```freebasic
#import "std/string"
```

```
nostd.tiko(1,1): error TKO0364: malformed '#import': 'string' is a keyword
```

The module is `strings`, plural. The singular is the `string` type, a keyword, and no part of an
import path may be a keyword, because that part becomes a name in your program.

**The module does not exist.**

```freebasic
#import "std/strng"
```

```
missing.tiko(1,1): error TKO0140: cannot find module 'std/strng' (searched: …/pkg/std/strng)
```

The message lists every place tiko looked. For a misspelling, the list shows you where it expected
the module to be.

---

## 6. Your own module

Any directory of your own can be a module. Here is a program that counts words, with the counting
moved out of the main file:

```
wordapp/
    main.tiko
    textstats/
        textstats.tiko
```

`textstats/textstats.tiko`:

```freebasic
#module "textstats"

#import "std/strings"
#import "std/containers"

'' No keyword: module-private. Every file of this module may call it; a program may not.
function Words_( byval text as ustring ) as containers.Array( of ustring )
    return strings.Split( lcase( text ), " " )
end function

public function WordCount( byval text as ustring ) as int32
    return Words_( text ).Count( )
end function

public function MostCommon( byval text as ustring ) as ustring
    dim counts as containers.Map( of ustring, int32 )
    dim as ustring best
    dim as int32 bestCount = 0
    for each w as ustring in Words_( text )
        counts[ w ] += 1
        if counts[ w ] > bestCount then
            best = w
            bestCount = counts[ w ]
        end if
    next
    return best
end function
```

`main.tiko`:

```freebasic
#import "std/strings"
#import "./textstats"

dim as ustring sentence = "The cat saw the dog and the dog saw THE cat"

print strings.Format( "{} words", textstats.WordCount( sentence ) )
print strings.Format( "most common: {}", textstats.MostCommon( sentence ) )
```

```
cd wordapp
tiko main.tiko
```

```
11 words
most common: the
```

What made `textstats` a module:

1. **It is a directory**, and every file in it begins with `#module "textstats"` — the directory's
   own name. Comments may come before the `#module` line; nothing else may.
2. **`#import "./textstats"`** starts with `./`, which means "relative to this file". The module's
   name in the program is again the last part of the path: `textstats`.
3. **Only `public` names can be used from outside.** `WordCount` and `MostCommon` are public.
   `Words_` has no keyword, so it is **module-private**: every file of `textstats` may use it, and
   nothing outside may.

Try to reach the private helper and the compiler names the rule:

```freebasic
#import "./textstats"

print textstats.Words_( "a b c" ).Count( )
```

```
peek.tiko(3,17): error TKO0860: 'words_' is not public in module 'main.textstats'
```

`main.textstats` is the module's full name: its package, then its path. A program with no
`tiko.toml` is the package `main` ([section 10](#10-growing-into-a-package) gives it a name).

### What else a module gives you

- **A module can be several files.** Put more `.tiko` files in `textstats/`, each starting with
  `#module "textstats"`. They are compiled together and see each other's names, in any order,
  with no `declare` lines between them. One [partial type](Category-Partial-Types) can even have a
  part in each file.
- **Imports belong to the file that writes them.** `textstats.tiko` imports `std/strings` for
  itself; `main.tiko` imports it again because it calls `strings.Format` too. A second file of the
  module that wants `strings` writes its own `#import`.
- **A module never sees your program's `#define`s or `-d` options.** That is what lets it be
  compiled once and reused. Pass settings as parameters.
- **Two modules may each have a `Parse`.** One is `csv.Parse`, the other `ini.Parse`, and they
  never collide — in your code, or in the linker.

The full rules — visibility levels, re-exporting with `public`, exported macros and generics,
initialisation order — are in [Chapter 15 of the book](https://tiko-lang.net/book/ch15-modules-packages.html).

---

## 7. Vendor packages: C libraries

`std` is written in tiko. The `vendor` package is different: each of its modules is a **C library**,
with its header already translated to tiko and its library files included. One `#import` gives you
the whole library.

| Module | Library |
|---|---|
| `vendor/sqlite3` | SQLite, the SQL database in a file |
| `vendor/raylib6` | raylib, games and graphics (with `vendor/raylib6/raymath`, `vendor/raylib6/rlgl`) |
| `vendor/SDL3` | SDL 3, windows, input, audio (with `vendor/SDL3/image`, `/ttf`, `/mixer`) |
| `vendor/cJSON` | cJSON, reading and writing JSON (with `vendor/cJSON/utils`) |

The full list, with the versions and the link modes each one ships, is on
[Vendor Packages](Vendor-Packages).

Here is a to-do list kept in an SQLite database:

```freebasic
#import "vendor/sqlite3" link dynamic
#import "std/strings"

print "SQLite "; *sqlite3_libversion( )

dim as sqlite3 ptr db
if sqlite3_open( ":memory:", @db ) <> SQLITE_OK then
    print "cannot open the database"
    end 1
end if

sqlite3_exec( db, "create table todo( id integer primary key, task text )", nullptr, nullptr, nullptr )

dim as ustring tasks(0 to 2) = { "buy milk", "call Ada", "write the tutorial" }
dim as sqlite3_stmt ptr st
sqlite3_prepare_v2( db, "insert into todo( task ) values( ? )", -1, @st, nullptr )
for each t in tasks
    sqlite3_bind_text( st, 1, t, -1, SQLITE_TRANSIENT )
    sqlite3_step( st )
    sqlite3_reset( st )
next
sqlite3_finalize( st )

sqlite3_prepare_v2( db, "select id, task from todo order by id", -1, @st, nullptr )
while sqlite3_step( st ) = SQLITE_ROW
    dim as int32 id = sqlite3_column_int( st, 0 )
    dim as ustring task = *cast( zstring ptr, sqlite3_column_text( st, 1 ) )
    print strings.Format( "{}. {}", id, task )
wend
sqlite3_finalize( st )
sqlite3_close( db )
```

```
tiko todo.tiko
```

```
SQLite 3.54.0
1. buy milk
2. call Ada
3. write the tutorial
```

Look at what is **different** from `std`:

- **The names are not qualified.** It is `sqlite3_open`, `SQLITE_OK` and `sqlite3_stmt`, exactly as
  SQLite's own documentation spells them — not `sqlite3.sqlite3_open`. A C library already puts a
  prefix on everything it declares, and keeping C's names means every C example and every answer
  on the web reads the same in tiko.
- **The functions are C functions.** They take and return C types: a `zstring ptr` for text, which
  you read with `*` (`*sqlite3_libversion( )`), and pointers to handles (`sqlite3 ptr`). Passing a
  `ustring` where SQLite wants text works, as `sqlite3_bind_text( st, 1, t, … )` shows.
- **The import has a `link` clause**, which decides how the library becomes part of your program.
  That is the next section.

There is nothing on the command line: no include directory, no library name, no library path, and
no C compiler.

---

## 8. `link static` and `link dynamic`

A C library comes in two forms, and you choose one for your program:

| | `link static` | `link dynamic` |
|---|---|---|
| The library's code | is copied **into** your program | stays in its own file: `sqlite3.dll` on Windows, a `.so` on Linux, a `.dylib` on macOS |
| What you ship | one file: your program | your program **and** the library file beside it |
| Program size | larger | smaller |
| Updating the library | rebuild your program | replace the library file |

With `link dynamic`, tiko **copies the library beside your program** when it builds it, so the
program starts straight away:

```
todo.exe
todo.tiko
sqlite3.dll        <- copied by the build
```

Change the first line to

```freebasic
#import "vendor/sqlite3" link static
```

and rebuild. The output is the same and `sqlite3.dll` is not needed, but `todo.exe` grows from
about 100 KB to about 1.2 MB: SQLite is inside it now.

**Leave the clause out** — `#import "vendor/sqlite3"` — and the package uses its own default.
For `vendor/sqlite3` that is dynamic. Writing the mode you want is clearer, and costs four words.

When you ship a dynamically linked program, ship the library file that the build copied beside it.

Not every package ships both forms, and `std` ships no C library at all. Asking for what is not
there is an error, at the import:

```freebasic
#import "vendor/SDL3" link static
```

```
sdlstatic.tiko(1,1): error TKO0156: 'link static': package 'vendor' ships no static link of module 'vendor.sdl3'
```

```freebasic
#import "std/strings" link static
```

```
linkstd.tiko(1,1): error TKO0155: 'link static' on '#import "std/strings"': package 'std' links nothing
```

---

## 9. A module around a C library

In a bigger program you rarely want SQLite calls spread through every file. Put them in **one
module of your own**, give it a small tiko-shaped API, and let the rest of the program use that.

```
notesapp/
    main.tiko
    notes/
        notes.tiko
```

`notes/notes.tiko`:

```freebasic
#module "notes"

#import "vendor/sqlite3" link dynamic

public type Notebook
    declare constructor( byval path as ustring )
    declare destructor( )
    declare sub Add( byval note as ustring )
    declare sub PrintAll( )
private:
    db_ as sqlite3 ptr
end type

constructor Notebook( byval path as ustring )
    sqlite3_open( path, @db_ )
    sqlite3_exec( db_, "create table if not exists notes( body text )", nullptr, nullptr, nullptr )
end constructor

destructor Notebook( )
    sqlite3_close( db_ )
end destructor

sub Notebook.Add( byval note as ustring )
    dim as sqlite3_stmt ptr st
    sqlite3_prepare_v2( db_, "insert into notes( body ) values( ? )", -1, @st, nullptr )
    sqlite3_bind_text( st, 1, note, -1, SQLITE_TRANSIENT )
    sqlite3_step( st )
    sqlite3_finalize( st )
end sub

sub Notebook.PrintAll( )
    dim as sqlite3_stmt ptr st
    sqlite3_prepare_v2( db_, "select rowid, body from notes", -1, @st, nullptr )
    while sqlite3_step( st ) = SQLITE_ROW
        print sqlite3_column_int( st, 0 ); "  "; *cast( zstring ptr, sqlite3_column_text( st, 1 ) )
    wend
    sqlite3_finalize( st )
end sub
```

`main.tiko`:

```freebasic
#import "./notes"

dim book as notes.Notebook = notes.Notebook( ":memory:" )
book.Add( "modules keep names apart" )
book.Add( "vendor packages bring C libraries" )
book.PrintAll( )
```

```
 1  modules keep names apart
 2  vendor packages bring C libraries
```

The program never mentions SQLite, yet `sqlite3.dll` was copied beside `main.exe`: the link
clause in the module decides for the whole program. The database closes itself when `book` goes
out of scope, because the `Notebook` destructor calls `sqlite3_close`.

**A program links a library one way.** If another file asks for the other mode, the build stops
and shows you both places:

```freebasic
#import "./notes"
#import "vendor/sqlite3" link static
```

```
notes/notes.tiko(3,1): error TKO0157: module 'vendor.sqlite3' is imported with 'link dynamic' here and 'link static' elsewhere; a program links it one way
     |
   3 | #import "vendor/sqlite3" link dynamic
     | ^
clash.tiko(2,1): note: imported here
     |
   2 | #import "vendor/sqlite3" link static
     | ^
```

An import **without** a `link` clause never conflicts: it goes along with the mode some other
import chose. So a good rule is: **write the `link` clause once**, in the module that owns the
library, and write the other imports of the same package without one.

---

## 10. Growing into a package

So far the program has been the package `main`, and modules sat beside it. When you want to share
modules between several programs, give them a home of their own and a `tiko.toml`:

```
wordkit/                      <- a package of your modules
    tiko.toml
    textstats/
        textstats.tiko        (the module from section 6, unchanged)
app/                          <- a program that uses it
    tiko.toml
    main.tiko
```

`wordkit/tiko.toml`:

```toml
[package]
name = "wordkit"
version = "0.1.0"
```

`app/tiko.toml`:

```toml
[package]
name = "app"

[dependencies]
wordkit = { path = "../wordkit" }
```

`app/main.tiko`:

```freebasic
#import "wordkit/textstats"

print textstats.MostCommon( "one fish two fish red fish blue fish" )
```

```
cd app
tiko main.tiko
```

```
fish
```

The import now starts with the package's name, `wordkit/`, instead of `./`. The `[dependencies]`
table tells tiko where `wordkit` lives. That path is in the project, not in anyone's environment,
so a fresh checkout of `app` builds with a bare `tiko main.tiko`.

For `#import "a/b"`, tiko looks in these places in order and takes the first that has it:

| | Where | Example |
|---|---|---|
| 1 | relative to the importing file, for a path starting `./` or `../` | `#import "./textstats"` |
| 2 | the current package, when the first part is its name | inside `wordkit`: `#import "wordkit/textstats"` |
| 3 | a dependency in the current package's `tiko.toml` | `wordkit = { path = "../wordkit" }` |
| 4 | each `-i` directory, then each directory in `TIKO_PATH` | `TIKO_PATH=C:\tikolibs` |
| 5 | the toolchain's own packages | `std`, `vendor` |

`std` and `vendor` are always the toolchain's: a directory of yours called `std` or `vendor` cannot
replace them by accident.

A `tiko.toml` can also set a package's `[defines]` and name build targets for
[`tiko build`](Category-Tiko-Build), which builds a whole project from its manifest.

---

## 11. Seeing what the compiler did

**`--print-graph`** lists every module a program imports, in the order they are built, and stops:

```
tiko --print-graph main.tiko
```

```
std.containers  …/pkg/std/containers
std.outcome     …/pkg/std/outcome
std.strings     …/pkg/std/strings  [std.containers std.outcome]
main.textstats  textstats  [std.containers std.strings]
```

Each line is a module's full name, the directory it came from, and what it imports.

**`-v`** reports whether each module came from the build cache:

```
module std.containers: hit
module std.outcome: hit
module std.strings: hit
module main.textstats: hit
```

**The build cache** keeps every module once it is compiled, in one directory shared by all your
projects — `%LOCALAPPDATA%\tiko\modcache` on Windows, `~/.cache/tiko/modcache` on Linux and macOS. A module
is rebuilt only when its source, its settings or something it imports changes. Nothing is written
into your project. If you ever doubt it, `tiko --clean-module-cache` empties it; nothing is lost
but the time to compile again.

---

## Cheat sheet

```freebasic
#import "std/strings"                      '' a std module: strings.Replace( … )
#import "std/strings" as txt               '' the same, called txt in this file
using strings                              '' then: Replace( … ) with no prefix

#import "vendor/sqlite3" link dynamic      '' a C library, its DLL copied beside the program
#import "vendor/sqlite3" link static       '' a C library, built into the program
#import "vendor/sqlite3"                   '' the package's default link, or another import's

#import "./textstats"                      '' your module, relative to this file
#import "wordkit/textstats"                '' a module of a package named in tiko.toml
#import "./textstats" public               '' (inside a module) pass the import on to importers
```

```freebasic
#module "textstats"                        '' first line of every file of textstats/

public function WordCount( … ) as int32    '' importers may call it
function Words_( … ) as …                  '' module-private: this module's files only
private function Secret_( … ) as …         '' private: this module's own object only
```

---

## Messages

| Message | Meaning | Fix |
|---|---|---|
| `TKO0140` cannot find module | No directory for that path, in any place tiko looks | Check the spelling against the list it prints |
| `TKO0155` package links nothing | `link` on a package with no C library (`std`, your own) | Remove the `link` clause |
| `TKO0156` ships no static link | The package does not offer that link mode | Use the other mode; see [Vendor Packages](Vendor-Packages) |
| `TKO0157` imported with 'link dynamic' here and 'link static' elsewhere | Two imports ask for different modes | Write `link` in one place only |
| `TKO0362` `#import` must come before any code | An import below a statement | Move imports to the top |
| `TKO0364` is a keyword | A part of the path is a keyword (`std/string`) | Use the real name (`std/strings`) |
| `TKO0423` | `spawn` or `select channel` without `std/tasks` | `#import "std/tasks"` and build with `-mt` |
| `TKO0743` is not declared | A module's name used without its module | Qualify it, or add `using` |
| `TKO0860` is not public | A module-private name used from outside | Mark it `public`, or use the public API |
| `TKO0919` is ambiguous | Two `using`s supply the same name | Qualify it |

---

### See also

- [Chapter 15 of the book: Modules and Packages](https://tiko-lang.net/book/ch15-modules-packages.html) — every rule, in depth
- [Vendor Packages](Vendor-Packages) — the C libraries the toolchain ships, and how a vendor package is made
- [tiko c2t Tutorial](C2t-Tutorial) — translating a C header of your own
- [tiko build](Category-Tiko-Build) — building a project from its `tiko.toml`
- [Goroutines Tutorial](Modern-Goroutines-Tutorial) — `std/tasks` in depth

---

[Home](Home) · [Feature Index](Feature-Index)
