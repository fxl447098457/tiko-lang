# Logging, Terminal UIs, SQLite and Regular Expressions

Four libraries cover four things most programs end up doing. A program that runs for any length
of time needs to say what it did, and **`std/logs`** writes that record properly: with levels,
typed fields, more than one destination and no lines torn apart by threads. A tool that a person
drives from a terminal can do better than `print` and `input`, and **`std/tui`** builds full-screen
interfaces from a grid of cells, a layout solver and some thirty widgets. A program that keeps data
between runs usually wants a database rather than files of its own invention, and
**`vendor/sqlite3`** puts SQLite, the most widely deployed database there is, an `#import` away.
Text that has to be searched for a shape rather than for fixed words — a date, an amount, the
fields of a log line — wants a regular expression, and **`vendor/pcre2`** brings PCRE2, the
library PHP's `preg_` functions are built on.

The chapter ends with a map of the finance library, the rest of the `std/money` module from
Chapter 27.

## Logging

```tiko
{{#include ../examples/ch28/log-demo.tiko}}
```

```text
{{#include ../examples/ch28/log-demo.out}}
```

Three objects make a log. A **`Logger`** is what the program calls. A **sink** is where records
go — `ConsoleSink` to the terminal, `FileSink` to a file — and a logger may have several. A
**renderer** turns a record into text: `TextRenderer` for people, `JsonRenderer` for programs.
`lg.AddSink( @con )` connects them. **The logger does not own its sinks**: it keeps a pointer, so
a sink must live at least as long as every logger that uses it.

### Levels

Every record has a **level**, from least to most severe: `LOG_TRACE`, `LOG_DEBUG`, `LOG_INFO`,
`LOG_WARN`, `LOG_ERROR` and `LOG_FATAL` (10 to 60, ten apart so a program can define its own in
between), plus `LOG_OFF`. **`MinLevel`** discards everything below it, and a discarded record is
never built — its fields are not converted, and nothing is allocated. Its arguments are still
evaluated, though: `lg.Trace( ).AddText( "dump", Expensive( ) )` calls `Expensive` whatever the level.

`LOG_FATAL` is a severity and nothing more. It does not end the program; a library that called
`end` on its host's behalf would be a bad library. Write the `end` yourself.

`LevelName`, `LevelNameShort` and `LevelFromName` convert to and from text, so a level can come
from a configuration file or the command line. `LevelFromName` leaves its output unchanged when the
name is not a level — a typo in a setting does not silently switch logging off.

### Records with fields

`lg.Info( "message" )` logs a line. For anything with data in it, **`lg.Warn( )`** without a
message starts a record, each **field** method adds a name and a value, and **`Msg( "text" )`**
finishes and sends it: `AddText`, `AddInt`, `AddUInt`, `AddFloat`, `AddBool`, `AddPtr`, and `AddTime` and `AddSpan` for
Chapter 26's `Instant` and `TimeSpan`. The values keep their types all the way to the renderer, so a
JSON renderer writes `3` and not `"3"`. A record that is never finished is never sent: forgetting
`Msg( )` costs a missing line, which is noticed, rather than a stray one.

**`WithField( name, value )`** returns a **child logger** that adds that field to every record it
writes, with the parent's level and sinks — `db` above marks everything from the database layer.
The child is a copy: changing the parent later does not change it.

### Files, JSON and the default logger

```tiko
{{#include ../examples/ch28/log-json.tiko}}
```

```text
{{#include ../examples/ch28/log-json.out}}
```

**`FileSink( path, @renderer )`** appends to a file. It can also **rotate** the file — set
`policy` to `RP_SIZE`, `RP_DAILY` or `RP_BOTH`, with `maxbytes` and `maxbackups` — so a long-running
program's log does not grow without bound. `JsonRenderer` writes one JSON object per line, which
log-collecting tools read directly; each object begins with the time, which the listing skips
because it is different on every run.

```tiko
{{#include ../examples/ch28/log-default.tiko}}
```

```text
{{#include ../examples/ch28/log-default.out}}
```

Passing a logger to every procedure that might log is tedious. The **default logger** is one
logger for the whole program, and `std/logs` holds it, so there is nothing to define:
**`LogInit`** attaches a sink and sets the level, **`DefaultLogger( )`** reaches it from anywhere, and
**`LogShutdown`** flushes and closes its sinks. It is not called for you at exit, so a program
calls it last, or risks losing its final lines.

A sink that cannot write — a full disk, a deleted folder — does not stop the program or return an
error to every log call. It counts what it dropped (`DroppedCount( )`) and reports the failure
through a handler that `SetLogErrorHandler` replaces. **`AsyncSink`** wraps another sink and writes
from a background thread, so a slow destination does not slow the program down; its `policy`
decides what happens when its queue is full — wait (`OP_BLOCK`), or drop the newest or oldest
record and count it.

**Every sink is safe to share between threads.** Each one holds a lock while it renders and writes
a record, so two threads' records never interleave inside a line — which `print #` to a shared
file does not promise. And a `ConsoleSink` writes to **stderr** by default: logs are diagnostics,
and a program whose output is piped into another must not mix them into the pipe. It colours the
level word on a terminal and never when its output is redirected.

## Terminal user interfaces

`std/tui` draws full-screen terminal programs: editors, dashboards, wizards, the menus of an
installer. It works on a grid of cells, and three ideas carry the whole library.

**The application is three methods.** A `TuiApp` has `Init`, which sets up state; `Update`, which
receives an event (a key, the mouse, a resize, a timer tick) and changes state; and `View`, which
draws the screen from state. Update never draws and View never changes anything.

**The screen is redrawn from scratch every frame, and only the difference is written.** There is no
tree of widget objects to keep in step with the data. `View` describes the whole screen each time;
the library compares that with the previous frame and sends the terminal only the cells that
changed. An unchanged frame costs nothing.

**Widgets are values; their state is yours.** A widget is built in `View` and thrown away. What must
survive between frames — a list's selection, a text box's contents, which widget has the focus —
lives in a state record that your app owns and the widget points at.

```tiko
{{#include ../examples/ch28/tui-hello.tiko}}
```

```text
{{#include ../examples/ch28/tui-hello.out}}
```

A real program ends with **`tui.TuiRun( app, tui.TuiTermOptionsDefault( ) )`**, which takes over the
terminal, runs the loop — wait for events, apply them all, draw once — and restores the terminal
on the way out, even after a crash. It returns a `Result`: run with its output redirected, it
fails with a message instead of drawing a dashboard into a file.

The listing does what a test does instead. **`TuiRenderOnce( app, screen )`** draws one frame into
a screen with no terminal at all and returns the bytes it would have sent, and `screen.Front( )`
holds the cells, which `Dump` prints. `Update` is a plain method, so feeding it an event is just a
call. The byte counts show the difference engine at work: the first frame draws everything, the
second only the changed digit, the third nothing.

`Update` returns a **command**: `TuiNone( )`, `TuiRedraw( )`, `TuiQuit( code )`, or
`TuiTick( ms )` to receive a timer event — one tick per call, so an animation re-arms it on each
tick.

### Layout and widgets

```tiko
{{#include ../examples/ch28/tui-widgets.tiko}}
```

```text
{{#include ../examples/ch28/tui-widgets.out}}
```

**Layout** divides a rectangle by constraints: `TuiLength( n )` for exactly `n` cells,
`TuiPercent`, `TuiRatio`, `TuiMin_` and `TuiMax_`, and `TuiFill( )` for a share of what is left.
`TuiSplitV` stacks the pieces and `TuiSplitH` puts them side by side, and splitting a piece again
builds any screen. The result is the same for the same sizes on every platform.

The listing uses four widgets: **`TuiBlock`** (a border with titles, whose `Inner` is the space
inside), **`TuiList`**, **`TuiTable`** with columns sized by the same constraints, and
**`TuiStatusBar`**. The rest of the set includes `TuiParagraph`, `TuiTabs`, `TuiGauge` and
`TuiSpinner`; the form widgets `TuiTextInput`, `TuiTextArea`, `TuiCheckbox`, `TuiRadioGroup` and
`TuiSelect`, with a `TuiFocusRing` that moves the focus on Tab; the overlays `TuiPopup`,
`TuiMessageBox` and `TuiMenuBar`; `TuiTree`; and the charts `TuiGraph`, `TuiSparkline`,
`TuiBarChart` and `TuiMeter`.

The listings draw `TUIBORDER_ASCII` borders so that the output prints anywhere. A real program
usually wants `TUIBORDER_ROUNDED` or `TUIBORDER_PLAIN`, drawn with the box-drawing characters,
and colour: a `TuiStyle` sets foreground, background and attributes, in 24-bit colour that the
library steps down to what the terminal supports.

```admonish danger title="Pitfall"
**A focusable widget must outlive the frame.** A focus ring holds pointers to widgets, so a
`TuiTextInput` declared inside `View` is gone by the time Tab moves to it, and the form cannot be
navigated. Make every widget that takes the focus a field of the app, as the state records are.
```

## SQLite

SQLite is a database in a library: no server, one file per database (or none, in memory), and
the SQL language. tiko ships it as **`vendor/sqlite3`**, one of the toolchain's **vendor
packages**: a C library with its header already translated into tiko and its compiled code beside
it, reached with one `#import`. What you call is SQLite's own C interface, so every function is
written the way SQLite's documentation writes it: `sqlite3_open`, not `sqlite3.sqlite3_open`.
Chapter 30 shows how a package like this is made, for any C library.

```tiko
{{#include ../examples/ch28/contacts-db.tiko}}
```

```text
{{#include ../examples/ch28/contacts-db.out}}
```

A connection is a **`sqlite3 ptr`**. `sqlite3` is a type SQLite declares but never defines, so a
program can only hold a pointer to one, and `sqlite3_open` fills it in through its address,
`@db`. The name `:memory:` opens a private database that lives as long as the connection; any
other name is a file, created when it does not exist. `sqlite3_close` closes it.

Almost every function returns a **result code**: `SQLITE_OK` for success, anything else for a
failure, and then `sqlite3_errmsg( db )` says what went wrong. Nothing raises a runtime error, so
a code that is ignored is a failure that is ignored. The listing's `Check` turns every failure
into a message and a stop, which is enough for a short program; a larger one decides call by call.

**`sqlite3_exec`** runs SQL that returns no rows. Its last three arguments are a callback that
would receive rows, an argument for that callback, and the address of an error message. Given
that address, as the last statement gives it, SQLite stores its message there, and the program
frees it with `sqlite3_free`. That is how the last line of output arrives: a `not null`
constraint refusing a row.

### Prepared statements

Everything else goes through a **statement**, in four steps:

1. **`sqlite3_prepare_v2`** compiles the SQL once, into a `sqlite3_stmt ptr`.
2. **`sqlite3_bind_text`**, `sqlite3_bind_int64`, `sqlite3_bind_null` and their siblings give a
   value to each `?`, counting from 1.
3. **`sqlite3_step`** runs it: `SQLITE_ROW` for each row of a result, `SQLITE_DONE` at the end.
   On a row, `sqlite3_column_text`, `sqlite3_column_int64` and the others read its columns,
   counting from 0. **`sqlite3_reset`** makes the statement ready to run again with new values.
4. **`sqlite3_finalize`** frees it.

```admonish danger title="Pitfall"
**Never build SQL by pasting values into the text.** `"... where name = '" & name & "'"` breaks on
the first name with an apostrophe in it, and lets anyone who controls the value rewrite the query.
Write `?` where each value goes and bind the values: they travel separately from the SQL and
cannot change what it means.
```

The last argument of `sqlite3_bind_text` says how long SQLite may keep the text.
`SQLITE_TRANSIENT` asks it to take a copy, which is always safe; `SQLITE_STATIC` promises the text
will not change while the statement uses it, and saves the copy. The `-1` before it means "the
text ends at its zero byte".

**Text crosses as UTF-8.** SQLite's `_text` functions take and return C's `char *`, holding
UTF-8. A `ustring` passed where the C function wants a `const char *` is converted to UTF-8 for
the call; a `string`, tiko's byte string, passes its bytes as they are. These listings keep their
values in `string` because they are bytes that go to SQLite and come back unchanged. The other
way, `sqlite3_column_text` returns a pointer to bytes SQLite owns, valid until the next step, and
`*cast( zstring ptr, … )` copies them into a string before then; a `string` holding UTF-8, assigned
to a `ustring`, is read as UTF-8. Chapter 35's ledger keeps its text in `ustring` and works this
way.

**A transaction** groups statements: `begin`, then `commit` to keep everything or `rollback` to
undo everything, as the listing does with its `delete`. They are SQL like any other, run with
`sqlite3_exec`. A transaction is also how many inserts become fast: each statement outside one
is its own transaction, written to disk separately.

### Importing CSV

```text
{{#include ../examples/ch28/people.csv}}
```

```tiko
{{#include ../examples/ch28/csv-import.tiko}}
```

```text
{{#include ../examples/ch28/csv-import.out}}
```

Reading CSV properly is Chapter 9's **`strings.SplitCsv`**: quoted fields, commas and doubled
quotes inside them, line breaks inside quotes. Given a `string`, it returns rows whose fields are
`string`s as well, the same UTF-8 bytes the file holds, so they are bound with no conversion. The
listing reads the whole file as bytes, takes row 0 as the header, binds an empty field as SQL's
`NULL` with `sqlite3_bind_null`, and loads every row inside one transaction.
`sqlite3_column_type` tells a `NULL` from text when it is read back.

### Static or dynamic

`#import "vendor/sqlite3"` links SQLite **dynamically**: the program calls into SQLite's shared
library, `sqlite3.dll` on Windows, and **tiko copies that library beside the program** when it
builds it, so the program starts wherever the two travel together. To have SQLite's code linked
into the program instead, which is then one file, say so on the import:

```tiko
#import "vendor/sqlite3" link static
```

Nothing else in the program changes. A program links a library one way only: two imports asking
for different modes are an error, `TKO0157`.

## Regular expressions

A regular expression describes the shape of some text: `\d{4}-\d\d-\d\d` is four digits, a hyphen,
two digits, a hyphen and two more, which is any ISO date. tiko ships **PCRE2**, the Perl-compatible
regular-expression library, as **`vendor/pcre2`**: its 8-bit library, built with Unicode support
and its just-in-time compiler. As with SQLite, what you call is PCRE2's own C interface, written as
PCRE2's documentation writes it: `pcre2_compile`, `pcre2_match`, `pcre2_match_data`.

```tiko
{{#include ../examples/ch28/regex-find.tiko}}
```

```text
{{#include ../examples/ch28/regex-find.out}}
```

A pattern is compiled once, by **`pcre2_compile`**, into a `pcre2_code ptr`, and matched as often
as you like. When the pattern is wrong, `pcre2_compile` returns `nullptr` and fills in an error
code and the offset where it gave up; **`pcre2_get_error_message`** turns the code into words. That
is the listing's last line: the `(` at the start of `(\d+` is never closed. Like SQLite, PCRE2
raises no runtime error; a return value that is not checked is a failure that is not noticed.

**Text crosses as UTF-8 bytes.** The 8-bit library takes a pattern or a subject as a `PCRE2_SPTR`,
a `const uint8 ptr`, and a length, so the listing keeps its text in `string` and passes
`strptr( s )` and `len( s )`. A `ustring` holds UTF-16 (Chapter 9), and assigning it to a `string`
converts it to UTF-8, which is what `subject` is. A string literal does not convert to a
`PCRE2_SPTR` at all (`TKO0698`), which is why `Compile` takes its pattern as a `string`.
**`PCRE2_UTF`** tells PCRE2 that pattern and subject are UTF-8, so `\p{Lu}`, any uppercase letter,
can match `Ł`, which is two bytes. **`PCRE2_UCP`** gives `\w`, `\d` and `\b` their Unicode meaning;
without it `\w` is ASCII letters, digits and `_`, and `Zoë` stops fitting the pattern, as the
listing's second-last line shows.

### Groups and the ovector

Parentheses make **groups**, numbered from 1 by their opening parenthesis; group 0 is the whole
match. **`pcre2_match`** returns one more than the highest group that matched, `PCRE2_ERROR_NOMATCH`
(-1) when there is no match, and another negative code for an error. Where everything was found is
in the **match data**, which `pcre2_match_data_create_from_pattern` sizes to hold every group of the
pattern: `pcre2_get_ovector_pointer` gives its **ovector**, a start and an end offset for each group,
group *n* at `ov[2 * n]` and `ov[2 * n + 1]`. A group that took no part in the match has both set
to `PCRE2_UNSET`.

To find **every** match, `pcre2_match` takes the offset to start from. After each match,
**`pcre2_next_match`** says what that offset should be and which options the next attempt needs:
after a match of nothing, starting again at the same place would find the same empty match for
ever, and it handles that. It returns 0 when there is nothing more to try.

```admonish danger title="Pitfall"
**Every offset PCRE2 gives is in bytes.** The ovector, the error offset and the start of a match
all count bytes of the UTF-8 subject. Used on the `string`, as `Group` uses them, they cut the right
text. Used on the `ustring` the bytes came from, they cut the wrong characters as soon as anything
before them was not ASCII: `Łukasz` starts at byte 31, but character 32 of `text` is the `u`,
because `ë` took two bytes and one character. Cut from the bytes, then convert.
```

Both the compiled pattern and the match data belong to PCRE2, and go back to it:
**`pcre2_code_free`** and **`pcre2_match_data_free`**.

### Replacing

```tiko
{{#include ../examples/ch28/regex-replace.tiko}}
```

```text
{{#include ../examples/ch28/regex-replace.out}}
```

**`pcre2_substitute`** copies the subject with matches replaced. `$1` in the replacement is group 1,
and `${1}` the same where letters or digits follow. `PCRE2_SUBSTITUTE_GLOBAL` replaces
every match rather than the first. `PCRE2_SUBSTITUTE_EXTENDED` adds more syntax, such as `\U` and
`\E` around text to put in upper case. A replacement that names a group the pattern lacks is an
error code like any other, and `$4` gets "unknown substring".

The result goes into **a buffer the caller provides**, here a `string` of spaces as long as the
subject. The last argument gives its size, and comes back as the result's length. Too small a
buffer is `PCRE2_ERROR_NOMEMORY`; with `PCRE2_SUBSTITUTE_OVERFLOW_LENGTH` set, PCRE2 goes on to
work out how much room it needs, and `Replace` makes that much and tries again. The room includes a
terminating zero that PCRE2 always writes, so a result as long as its subject does not fit the
first buffer either: the dates line took the second attempt, as did the third line, which is longer
than its subject. Only the shorter second line fitted at once.

### Patterns from outside the program

PCRE2 finds a match by **backtracking**: when part of the pattern fails, it goes back and tries the
next way of matching what came before. Most patterns have few ways to try. A pattern like `(a+)+$`
has as many as there are ways of splitting a run of `a`s into groups, and doubles them with each
`a` more; given a long run that does not end where `$` wants it to, PCRE2 tries them all.

When the pattern comes from a user, a file or the network, that is a way to stop a program, and
PCRE2 has limits for it:

```tiko
{{#include ../examples/ch28/regex-limits.tiko}}
```

```text
{{#include ../examples/ch28/regex-limits.out}}
```

A **match context**, given as `pcre2_match`'s last argument, carries limits for one match.
**`pcre2_set_match_limit`** caps the steps it may take, and a match that reaches the cap stops with
`PCRE2_ERROR_MATCHLIMIT` (-47) rather than an answer. `pcre2_set_depth_limit` and
`pcre2_set_heap_limit` cap how deep its backtracking may nest and how much memory it may use. A
**compile context**, `pcre2_compile`'s last argument, does the same for the pattern:
`pcre2_set_max_pattern_length` refuses one that is too long.

**`pcre2_jit_compile`** translates a compiled pattern into machine code. After it, `pcre2_match` on
that pattern runs the machine code, and the match limit still holds, as the second line shows. The
depth and heap limits do not apply to machine code, which has a stack of its own.

`#import "vendor/pcre2" link static` builds PCRE2 into the program, exactly as for SQLite; the
default, `link dynamic`, copies `pcre2.dll` (on Linux `pcre2_linux_x86_64.so`, on macOS
`pcre2_macos_arm64.dylib`) beside it.

## The finance library

Chapter 27 used `Decimal`, `Currency` and loan schedules from **`#import "std/money"`**. The same
module carries the rest of a finance library, one source file per subject, all built on `Decimal`:

| File | Covers |
|---|---|
| `fincore.tiko` | interest, rates and the conventions they are quoted in; compounding and payment frequency; day counts |
| `fintvm.tiko` | the time value of money: present and future value, annuities |
| `finloan.tiko` | loans, mortgages and amortization schedules |
| `fincash.tiko` | cash flows: net present value, internal rate of return, payback |
| `findeprec.tiko` | depreciation, by six methods |
| `finport.tiko` | portfolio returns and risk: volatility, drawdown, Sharpe and Sortino ratios |
| `finsolve.tiko` | the one root finder behind every implied rate |
| `finerror.tiko` | `FinanceError`, which every fallible call returns in its `Result` |

Each calculation is exact where it can be — growth over a whole number of periods, every sum and
product of money — and uses `float64` only where a fractional power or a solver makes that
impossible, converting back to `Decimal` at a fixed scale. The comments in `pkg/std/money` document
every function, and all of them are reached as `money.`.

## What it costs

- **A disabled log level costs one comparison.** An enabled record costs its fields, the
  rendering, and a lock per sink.
- **A frame costs its drawing plus a cell-by-cell comparison** of the whole screen; an
  unchanged frame writes nothing, and an idle interface uses no processor time.
- **Each SQL statement outside a transaction is a separate write to disk.** Thousands of inserts
  belong in one transaction; a prepared statement saves compiling the SQL each time.
- **`vendor/sqlite3` costs a second file or a larger program.** Linked dynamically, SQLite's
  shared library, 3.5 MB on Windows, travels beside the program; linked statically, the program
  grows by about 1.1 MB. Either way nothing needs installing on the machine that runs it.

## Summary

- `#import "std/logs"`: a `Logger` with `MinLevel` and sinks; `Info( "text" )`, or
  `Warn( ).AddText( … ).AddInt( … ).Msg( "text" )` for fields; `WithField` for a child logger.
- Sinks: `ConsoleSink` (stderr by default), `FileSink` with rotation, `AsyncSink`; renderers:
  `TextRenderer`, `JsonRenderer`. The logger does not own its sinks.
- `LogInit`, `DefaultLogger( )` and `LogShutdown` for the one program-wide logger, which
  `std/logs` holds.
- `#import "std/tui"`: a `TuiApp` with `Init`, `Update` and `View`; `TuiRun` drives it, and
  `TuiRenderOnce` draws a frame with no terminal. Layout with constraints, widgets as values, state
  in the app.
- `#import "vendor/sqlite3"`: SQLite's own C interface, unqualified: `sqlite3_open`,
  `sqlite3_exec`; statements with `sqlite3_prepare_v2`, `?` and `sqlite3_bind_*`, then
  `sqlite3_step`, `sqlite3_column_*` and `sqlite3_finalize`. Every call returns a result code,
  and `sqlite3_errmsg` explains a failure. Text is UTF-8, so values travel as `string`.
- `link static` or `link dynamic` on the import chooses how SQLite is linked; dynamic, the
  default, copies the shared library beside the program. `strings.SplitCsv` reads CSV to load.
- `#import "vendor/pcre2"`: PCRE2's C interface, unqualified. `pcre2_compile` once,
  `pcre2_get_error_message` when it fails; `pcre2_match` into match data, whose ovector holds each
  group's start and end; `pcre2_next_match` to find every match; `pcre2_substitute` to replace,
  into a buffer of yours. Free with `pcre2_code_free` and `pcre2_match_data_free`.
- Text goes in as UTF-8 bytes: a `string`, passed as `strptr( s )` and `len( s )`, with
  `PCRE2_UTF` (and `PCRE2_UCP` for Unicode `\w`). Every offset that comes back counts bytes.
- A pattern from outside the program gets a match context with `pcre2_set_match_limit`; a
  match that reaches it returns `PCRE2_ERROR_MATCHLIMIT`. After `pcre2_jit_compile`, matching
  runs machine code and still keeps to the match limit.
- `std/money` also carries rates, the time value of money, loans, cash flows, depreciation and
  portfolio measures.

## Exercises

1. Store a list of sales in a table, then print each region's total and number of sales, largest
   first, with one SQL query. {solution="ex28-01"}
2. Set a logger's minimum level from a level name given on the command line, falling back to
   `INFO` for a name that is not a level. {solution="ex28-02"}
3. Add a `FileSink` to `log-demo.tiko` beside the console, so every record goes to both. What
   happens to the file if the program is run twice?
4. Make `tui-widgets.tiko` respond to the Down key by moving the list's selection, and check it the
   way `tui-hello.tiko` checks its key press.
5. Import a CSV file of your own, then, inside a transaction, delete the rows that fail a check,
   and roll back if more than half of them would go. `sqlite3_changes( db )` says how many rows
   the last statement changed.
6. Write `Split( pattern, text )`, which returns the pieces of `text` between the matches of
   `pattern`, and use it to split `"a, b ,c,,d"` on `\s*,\s*`. Which pieces are empty, and why?
7. Make `regex-find.tiko` print each name with the character position it starts at in `text`,
   computed from the byte offset PCRE2 gives.
