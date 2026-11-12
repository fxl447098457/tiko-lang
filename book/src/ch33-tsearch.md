# Capstone: a CLI Search Tool

This chapter builds a complete program: **`tsearch`**, a small cousin of `grep`. It walks a
directory tree, reads every file in it, and prints the lines that contain a pattern. There is
nothing in it the earlier chapters have not shown; what is new is putting the pieces together and
making the decisions a real tool needs — what goes in a module and what stays in the program, how a
failure reaches the user, what the exit code means, and how the parts are tested.

## The specification

```text
tsearch [-i] [-n] [-l] [-g glob] pattern [path ...]
```

- Print every line, in every file under each **path**, that contains **pattern**, as
  `path:line text`. With no path, search the current directory.
- **`-i`** ignores case, for letters outside ASCII as well as inside it. **`-n`** adds the line
  number: `path:number:line text`. **`-l`** prints only the names of files that match.
  **`-g glob`** searches only files whose names match a glob pattern such as `*.txt`; case matters
  in the glob on every platform.
- Paths are printed with `/` between components on every platform, and files are searched in the
  sorted order of the paths as printed, so the output is the same everywhere.
- When the output goes to a terminal, the file name is coloured; when it is redirected to a file or
  a pipe, it is plain text.
- Problems — a bad option, an empty argument, a path that does not exist, a file or directory that
  cannot be read — go to **stderr**, never into the results.
- The **exit code** says what happened, as `grep`'s does: **0** if anything matched, **1** if
  nothing did, **2** if something went wrong. A script can test it.

## The layout

```text
ch33/
    tiko.toml           the package
    search/search.tiko  the module: everything that can be tested on its own
    tsearch.tiko        the program: the command line, the output, the exit code
    searchtests.tiko    the module's tests
    sample/             files to search
        notes/readme.md
        notes/todo.txt
        poems/fox.txt
```

The work is split along one line: **everything that does not touch the command line or the screen
goes in the module.** Parsing the arguments takes an array and returns options; matching takes two
strings; finding files takes a root and returns paths. None of them prints anything, so the tests
can call each one directly and check what it returns. The program is what is left: reading
`command( )`, printing, and choosing the exit code.

`tiko.toml` makes the directory a **package** (Chapter 15), which lets the exercise solutions in
`solutions/` reach the module as `"../search"` — a relative import may not leave its package:

```text
{{#include ../examples/ch33/tiko.toml}}
```

## The module

```tiko
{{#include ../examples/ch33/search/search.tiko:head}}
```

The module uses `std/fs` for the file system and `std/containers` for its arrays, and declares two
**public** types:

```tiko
{{#include ../examples/ch33/search/search.tiko:types}}
```

`Options` is everything the command line said, already interpreted: the program builds one, and
every other procedure reads it. `Hit` is one result. Neither has methods: they are plain records
passed between the procedures, which keeps each procedure testable with values a test can write out.

### Parsing the arguments

```tiko
{{#include ../examples/ch33/search/search.tiko:parse}}
```

`ParseArgs` reads an array rather than calling `command( n )` itself, so a test can hand it any
argument list. It returns **an error message, or an empty string** — the one thing the caller needs
to know — and fills `opts` in place. A flag that takes a value, `-g`, moves the index past it, and
says so if the value is missing. Anything else starting with `-` is refused rather than searched
for: a misspelt option should be an error, not a silent search for `-x`. The first other argument
is the pattern and the rest are roots, with `.` as the default.

An empty argument is refused as well, with `an argument is empty`, and an empty `-g` value as a
missing one. An empty argument is almost always a shell variable that was never set —
`tsearch "$WORD" notes` — and taken at face value it would be a pattern that says nothing or a path
that names nothing. Refusing it says which.

### Matching

```tiko
{{#include ../examples/ch33/search/search.tiko:match}}
```

A case-insensitive match compares both strings in lower case. For a `ustring`, **`lcase` lowers
more than `A` to `Z`**: `ÄRGER` matches `ärger`, and Greek and Cyrillic capitals lower too. It maps
one character to one character, though, which is lower-casing and not full case folding, so a few
pairs a reader would call equal stay apart: `STRASSE` does not match `straße`, a Greek capital
sigma lowers to `σ` and never to the final `ς`, and the Turkish capital `İ` is left as it is. The
tests pin down both sides. Lower-casing a whole line for every comparison is not the fastest
possible way — the pattern could be lowered once — but it is easy to check, which is the right
first version.

### Finding the files

```tiko
{{#include ../examples/ch33/search/search.tiko:find}}
```

A root that is a file is searched as it is. A directory is walked with **`fs.WalkDir`**
(Chapter 25), which yields one `Result` per entry: a successful entry that is a file is kept when
its name matches the glob, using **`fs.MatchPattern`** — the same matcher `fs.Glob` uses, applied
to one name.

`NameMatches` passes `fs.MatchPattern` a grammar, **`fs.FB_PATH_POSIX`**, rather than leaving it
the default. The default is the platform's own grammar, which ignores case on Windows and respects
it on Linux and macOS, so `-g "*.TXT"` would find `todo.txt` on one and not on another. With the POSIX
grammar named, case matters on every platform, and the same glob gives the same answer.

A failed entry — a directory that cannot be opened, or a root that does not exist — becomes a
message in `problems`, so the program can report it and still search everything else. The message
names **`FsError.Path( )`**, the path that failed: for a missing root that is the root,
`nowhere: no such file or directory`, and for an unreadable directory deep in the tree it is that
directory, `sample/notes: access denied`, not the root the user typed.

The paths are **sorted** before they are returned, and sorted **as they will be printed**. A file
system lists a directory in whatever order it likes, and that order differs between Windows and
Linux; a tool whose output changes between runs on the same files is a tool whose output cannot be
compared. Sorting the native paths would not be enough, because `\` sorts after the capital
letters and `/` before the digits: `d\f.txt` comes after `dA\f.txt`, but `d/f.txt` before it. So
each path goes through `DisplayPath` first, and the sort sees the same strings on every platform.
Windows accepts `/` as a separator, so the display path is also the one the program opens.

`FindFiles` appends what it finds to `files`, in that order, and returns how many it appended,
whether the root is a file or a directory.

### Searching a file

```tiko
{{#include ../examples/ch33/search/search.tiko:searchfile}}
```

`fs.ReadAllLines` returns a **`Result`** (Chapter 18): the number of lines, or an **`FsError`** that
says why the file could not be read. `SearchFile` passes that `Result` straight back, so the caller
learns about a failure in the same value that carries success, and cannot forget to look: there is
no error number to check separately and no runtime error to trap.

```tiko
{{#include ../examples/ch33/search/search.tiko:display}}
```

`DisplayPath` is the last piece of the "same output everywhere" promise: Windows writes `\` between
path components, and the tool prints `/` everywhere. It converts only on Windows. On Linux and macOS `\` is an
ordinary character a file name may contain — `a\b.txt` is one file — and printing it as `a/b.txt`
would name a different one. It is not `public`: `FindFiles` applies it, and nothing outside the
module needs to.

## The program

```tiko
{{#include ../examples/ch33/tsearch.tiko}}
```

The program reads like the specification. It collects the arguments — `command( 1 )` to
`command( __FB_ARGC__ - 1 )` (Chapter 25) — and hands them to `ParseArgs`; a bad command line
prints the problem and the usage line to **stderr** through `Complain`, and ends with exit code 2.
The loop counts rather than stopping at the first empty `command( n )`: that would read
`tsearch fox "" sample` as `tsearch fox` and quietly search `.`.

**`IsRedirected( )`** (from `fbio.bi`, Chapter 25) is true when standard output is not a terminal.
The program colours only when it is false, so `tsearch fox > hits.txt` writes plain text and a
person at a terminal sees the file names in magenta, in `-l` output as well. The colour itself is
an ANSI escape sequence, `ESC [35m` to start and `ESC [0m` to stop.

A Linux or macOS terminal draws those sequences as they arrive. A Windows console draws them only once it
has been asked to, and the runtime does not ask on the program's behalf, so `ColourWanted` does:
it switches on the console's virtual-terminal mode through **`windows.bi`**, the Windows API
header, and gives up colour if the console refuses. `windows.bi` does not name the
`ENABLE_VIRTUAL_TERMINAL_PROCESSING` flag, so the listing defines it. Both `#include` lines sit
below the `#import` lines, because an import must come before any code and a header brings some:
above them, an import fails with `TKO0362: '#import' must come before any code, in the compiled
file`.

Every failure is counted, and reported where it happens, without stopping the search: one
unreadable file should not hide the matches in all the others. Only at the end does the program
choose the exit code: **2** if anything failed, otherwise **0** or **1** by whether anything
matched.

## Running it

Run from the chapter's directory as `tsearch -n -i fox sample`:

```text
{{#include ../examples/ch33/tsearch.out}}
```

A few more runs, on any platform, with the exit code after each:

```text
$ tsearch -l -g "*.txt" fox sample
sample/poems/fox.txt
exit 0
$ tsearch zebra sample
exit 1
$ tsearch fox nowhere
tsearch: nowhere: no such file or directory
exit 2
$ tsearch -x fox
tsearch: unknown option -x
tsearch: usage: tsearch [-i] [-n] [-l] [-g glob] pattern [path ...]
exit 2
```

The second run prints nothing at all and still says something, through its exit code: a script
can write `if tsearch -l secret . ; then …` and never look at the output.

The glob is quoted because a Unix shell expands an unquoted `*.txt` against the current directory
before tsearch sees it. On Windows, quoting is not enough.

```admonish danger title="Pitfall"
On Windows the runtime expands `*` and `?` in every argument before the program starts — quoted or
not, from cmd, PowerShell or any other shell — against the files in the current directory, or in
the directory the argument names. Run from `sample/notes`, which holds `todo.txt`,
`tsearch -l -g "*.txt" fox ..` receives `-g todo.txt`, searches only files named `todo.txt`,
prints nothing and exits 1. Nothing reports the change. With two `.txt` files there, the second
would become the pattern and the real pattern a path.

An argument that matches no file is passed on unchanged, and the expansion knows only `*` and `?`.
So write one character of the glob as a class: `-g "*.tx[t]"` matches no file name literally,
reaches tsearch as typed, and still means `*.txt` to `fs.MatchPattern`. It needs quoting in a Unix
shell too, where it is otherwise a glob for the shell. The runtime asks for the expansion in its
startup code, and the pinned version has no switch to turn it off.
```

## Testing

```tiko
{{#include ../examples/ch33/searchtests.tiko}}
```

On Windows:

```text
{{#include ../examples/ch33/searchtests.windows-x86_64.out}}
```

On Linux and macOS the same suites run in another order (Chapter 19):

```text
{{#include ../examples/ch33/searchtests.out}}
```

The tests are a program of their own, built with fbcunit (Chapter 19), that imports the module just
as `tsearch.tiko` does. Each test calls one procedure with values it chose and checks what came back:
the argument parser with good and bad command lines, an empty argument among them; matching with
and without case, lower-casing beyond ASCII, and where lower-casing stops; finding files in
`sample/`, with and without a glob, in sorted order, and a glob whose case does not match on either
platform; line numbers; and a missing file, which must come back as a failed `Result` rather than
a crash. Nothing here needs a terminal or anything outside `sample/`, so it can run on every build.

The program itself is tested the way the runs above were: by running it on known files and
comparing its output and exit code with what they should be.

## What it costs

- **Every file is read whole** with `ReadAllLines`, so a search holds one file in memory at a
  time. A tool for very large files would read a line at a time with `line input #`.
- **Case-insensitive matching lower-cases every line**, one copy per line. Lowering the pattern once
  and comparing without copying is the obvious optimisation, and the tests are what make it safe
  to try.
- **Sorting the file list** costs a little time for a large tree, and buys output that does not
  depend on the file system.

## Summary

- Put everything that does not touch the command line or the screen in a module, and test it
  directly; keep the program a thin layer over it.
- Parse arguments from an array into an options record, counting to `__FB_ARGC__`, and report
  problems as messages; refuse unknown options and empty arguments.
- `fs.WalkDir` and `fs.MatchPattern` find the files; name the POSIX grammar for the same glob
  answer on every platform, and sort the paths as printed for the same order. `fs.ReadAllLines`
  returns a `Result` whose `FsError` says why a file could not be read, and `Path( )` which file.
- `lcase` lowers letters beyond ASCII one character at a time; it is not full case folding.
- On Windows the runtime expands `*` and `?` in arguments even inside quotes; write one character
  of a glob as a class, `*.tx[t]`, to get it through.
- Diagnostics go to stderr; `IsRedirected( )` decides about colour, and a Windows console needs
  its virtual-terminal mode switched on first; the exit code — 0, 1 or 2 — says what happened.
- fbcunit tests the module's procedures one by one, on every platform.

## Exercises

1. Write a program that uses the `search` module to print how many lines match in each file, as
   `path: count`. {solution="ex33-01"}
2. Add whole-word matching, so that `dog` matches `the lazy dog.` and `hot-dog` but not `dogma` or
   `underdog`. Count a letter outside ASCII as part of a word, so that `Schädog` does not match
   either. {solution="ex33-02"}
3. Add a `-c` option that prints only the number of matching lines in each file, with tests for its
   parsing.
4. Add `-v`, which prints the lines that do *not* match. Which other options does it interact with,
   and how should `-l -v` behave?
5. Make the match cheaper: lower-case the pattern once, outside the loop, and check that every
   test still passes.
