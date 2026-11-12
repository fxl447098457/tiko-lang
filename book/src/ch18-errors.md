# Errors: Optional, Result and Runtime Checks

Every program meets things that go wrong: a file that is not there, a line that does not parse, a
divisor that turns out to be zero. The question is never whether failure happens but where the
program finds out about it, and whether the code that finds out is the code that can do something
about it.

tiko gives you two kinds of answer. **Values that say they might have failed** — `Optional` and
`Result` from the standard library — put the possibility of failure into a function's type, so the
caller cannot use the answer without first deciding what to do when there is none. **Runtime
errors** — the `error` statement, `on error goto`, and the checks `-exx` adds — stop the normal
flow and jump to a handler. The first kind is for failures a caller is expected to handle. The
second is for the ones it is not.

This chapter covers both, then the checks the compiler can add for you and the assertions you can
add yourself.

## A value that means "nothing"

The oldest way to report failure is a value that cannot otherwise happen:

```tiko
{{#include ../examples/ch18/sentinel.tiko}}
```

```text
{{#include ../examples/ch18/sentinel.out}}
```

````admonish danger title="Pitfall"
**A sentinel is only safe while it cannot be a real answer.** `Coldest` returns −1 to mean "there
were no readings", and −1 is also a perfectly good temperature. Both calls print −1; one means
"nothing", the other means "minus one degree", and the caller has no way to tell them apart.

It compiles, it runs, and it is wrong exactly when the data reaches the sentinel — the case a test
is least likely to cover. The fix is not a cleverer sentinel (−9999 is a legal reading somewhere);
it is a return type that has room for "no answer" beside every possible answer.
````

## Optional

`Optional( of T )` is a `T` that might not be there. It lives in the standard library's `outcome`
module:

```tiko
{{#include ../examples/ch18/optional.tiko}}
```

```text
{{#include ../examples/ch18/optional.out}}
```

| Member or procedure | Does |
|---|---|
| `outcome.Some( v )` | an `Optional` holding `v` |
| `outcome.None( of T )( )` | an `Optional` holding nothing |
| `o.HasValue( )` | whether there is a value |
| `o.Value( )` | the value — **a runtime error if there is none** |
| `o.ValueOr( d )` | the value, or `d` if there is none; never raises |

`FindIndex` can now say "15 is at index 2" and "99 is not here" without inventing an index that
means nothing. The caller has to ask: there is no way to get an `int32` out of the result without
choosing between `HasValue`, `Value` and `ValueOr`.

A few details matter in practice:

- **A new `Optional` is empty.** `dim nothing as outcome.Optional( of ustring )` holds no value,
  and there is no separate "uninitialised" state to get wrong.
- **`Some` infers `T` from its argument, and a literal is an `integer`.** `outcome.Some( 42 )` is
  an `Optional( of integer )`, which does not convert to an `Optional( of int32 )`. Write
  `outcome.Some( of int32 )( 42 )` when the type has to be exact. `None` has no argument to infer
  from, so its type is always written.
- **`Value( )` on an empty `Optional` is a bug at the call site**, not a recoverable condition: it
  raises runtime error 1, "illegal function call". Ask `HasValue` first, or use `ValueOr`. The
  section on runtime errors shows the error being caught.

## Result

`Optional` says *that* there is no answer. Often the caller also needs to know *why*, and that is
`Result( of T, E )`: a `T` on success, or an `E` that explains the failure.

```tiko
{{#include ../examples/ch18/result.tiko}}
```

```text
{{#include ../examples/ch18/result.out}}
```

| Member or procedure | Does |
|---|---|
| `outcome.Ok( of T, E )( v )` | a success holding `v` |
| `outcome.Fail( of T, E )( f )` | a failure holding `f` |
| `r.IsOk( )` | whether it succeeded |
| `r.Value( )` | the value — a runtime error if it failed |
| `r.Failure( )` | the reason — a runtime error if it succeeded |
| `r.ValueOr( d )` | the value, or `d` on failure |

`Ok` and `Fail` each mention only one of `T` and `E` in their parameters, so the compiler cannot
work out the other: **both type arguments are always written**. That is why the result type is
usually named once with a `type … as`, here `DigitResult`, and the long spelling appears only
where a value is built.

**A new `Result` is a failure.** `dim blank as DigitResult` reports `IsOk( )` false, and its
`Failure( )` is a default-constructed `E`. That is the safe default — code that forgets to set a
`Result` cannot accidentally claim success — and it has a consequence for your own error types:
`E` needs a constructor that takes no arguments, because every `Result` builds one.

### Passing a failure on

A function that calls another fallible function usually wants to stop at the first failure and
pass it up, adding what it knows:

```tiko
{{#include ../examples/ch18/checkeddivide.tiko}}
```

```text
{{#include ../examples/ch18/checkeddivide.out}}
```

`Average` asks `IsOk( )`, and on failure builds its own failure that wraps the reason it was
given. On success it returns `Divide`'s result unchanged, because it is already the right type.
Each layer either handles a failure or passes it on, and either way it says so in its code.

### An error type of your own

A `ustring` is enough to tell a person what went wrong. A program that wants to *react* to the
failure — retry, skip the line, ask again — needs something it can branch on. The standard
library's `fs.FsError` is the model: a code, the operation and path involved, and a message. A
configuration parser built the same way:

```tiko
{{#include ../examples/ch18/parseconfig.tiko}}
```

```text
{{#include ../examples/ch18/parseconfig.out}}
```

`ConfigError` carries a `ConfigCode` for programs and a `Message( )` for people, and it has the
constructor with no arguments that `Result` needs. `ParseLine` fails in three distinct ways, and
`ParseConfig` stops at the first failing line and passes its error up unchanged. The caller sees
exactly which line failed and why, and nothing below it had to print anything.

The standard library's own errors work the same way. Reading a file that is not there:

```tiko
{{#include ../examples/ch18/fserror.tiko}}
```

```text
{{#include ../examples/ch18/fserror.out}}
```

`ReadAllText` returns a `Result` whose failure is an `fs.FsError`. `Code( )` is what the program
branches on — `fs.FS_NOT_FOUND` here, the same on Windows, Linux and macOS — and the text is for the
person reading the output.

## Statements that return an error code

Some of the runtime's oldest statements have a **function form** that returns an error number
instead of raising a runtime error. `open` and `close` are the ones you will meet most:

```tiko
{{#include ../examples/ch18/iocodes.tiko}}
```

```text
{{#include ../examples/ch18/iocodes.out}}
```

0 means success. Any other value is a runtime error number: 2 is "file not found", and closing a
file number that is no longer open is 1, "illegal function call".

Written as a statement — `open "notes.txt" for input as #f` — the same failure is **silent**
unless the program was compiled with `-e`, and then it stops the program with runtime error 2. A
missing file that nothing reports is the worst outcome of the three, which is the reason to use
the function form whenever a missing file is an expected event rather than a bug.

## Runtime errors

A **runtime error** is a numbered failure that stops the normal flow of the program. The runtime
raises them itself — a file that cannot be opened, an `Optional` with no value — and your code can
raise one with `error n`. If nothing handles it, the program prints the error and ends with that
number as its exit code. To handle one, install a handler with `on error goto`:

```tiko
{{#include ../examples/ch18/runtimeerrors.tiko}}
```

```text
{{#include ../examples/ch18/runtimeerrors.out}}
```

`on local error goto failed` installs a handler for the rest of `Report`. When `Ratio` raises
error 11, control jumps to `failed:`, where four functions describe what happened:

| Function | Gives |
|---|---|
| `err` | the error number |
| `erl` | the line it happened on |
| `erfn( )` | the procedure it happened in, as a `zstring ptr` |
| `ermn( )` | the module (source file) it happened in, as a `zstring ptr` |

`erfn` and `ermn` need the error-location information `-exx` compiles in; without it `erfn( )`
is empty. And **read `err` before doing anything else.** The next call into the runtime may clear
it: `print "error"; err` printed 0 in testing, because printing the text came first. Copying it to
a variable on the handler's first line is the reliable form.

An empty `Optional` raises in exactly this way:

```tiko
{{#include ../examples/ch18/emptyvalue.tiko}}
```

```text
{{#include ../examples/ch18/emptyvalue.out}}
```

### What the jump skips

````admonish danger title="Pitfall"
**When an error jumps out of a procedure, that procedure's destructors and `defer`s do not run.**

```tiko
{{#include ../examples/ch18/escape.tiko}}
```

```text
{{#include ../examples/ch18/escape.out}}
```

`Transfer` opens a `Connection` and schedules a `defer`. The error leaves `Transfer` for the
handler at module level, and neither runs: the connection is never closed, and nothing reports
it. A handler *inside* the procedure is different — `Report` above returns normally from its own
handler, and its locals are cleaned up as usual. The danger is the error that crosses a procedure
boundary on its way to a handler further out. Keep handlers next to the resources they protect,
or report failures with a `Result`, which unwinds like any other return.
````

```admonish tip title="Coming from FreeBASIC"
tiko has no `resume`. In a handler you can inspect the error, clean up and leave; you cannot jump
back into the code that failed. `resume` is refused as `TKO0409: 'RESUME' is not available in the
fb dialect`. A loop around a `Result` does what a `resume` would have, and says so where it
happens.
```

## Runtime checking

Some mistakes can only be caught while the program runs: an array index out of range, a null
pointer followed. The compiler adds checks for them when asked, and three options control how
many:

| Option | Adds |
|---|---|
| `-e` | error checking: runtime errors report and end the program, and handlers work |
| `-ex` | the same, plus the support `resume` would need in FreeBASIC |
| `-exx` | the same, plus array bounds, null pointers and the error's location |

Chapters 8 and 11 showed what `-exx` catches. A program can ask how it was compiled through
`__FB_ERR__`, a bit mask:

```tiko
{{#include ../examples/ch18/errflags.tiko}}
```

```text
{{#include ../examples/ch18/errflags.out}}
```

The values are 0 with no option, 513 with `-e`, 515 with `-ex` and 1823 with `-exx`. Bit 1 is
error checking, 8 array bounds and 16 null pointers; the rest are documented with the
compiler's options.

Each check also has an option of its own, for a build that wants one check and not the rest:
`-earray` (8), `-enullptr` (16), `-elocation`, `-eassert`, `-edebug`, `-edebuginfo`, `-eunwind` and
`-earraydims`, each setting only its own bit. `-g` sets 32, 64 and 128 — assertions, debug
information and `__FB_DEBUG__` — so `__FB_ERR__` is 224 with `-g` alone and 2047 with `-g -exx`.

**Checks cost speed.** `-exx` adds a comparison to every array access and a test to every pointer
dereference. Use it while developing and testing, and decide deliberately whether a release
build keeps it.

## Assertions

An **assertion** states something that must be true, and stops the program if it is not. tiko has
two kinds.

`#assert` is checked by the compiler, against constants:

```tiko
{{#include ../examples/ch18/staticassert.tiko}}
```

```
staticassert.tiko(4,1): error TKO0604: #assert condition failed
     |
   4 | #assert SLOTS <= 8               '' refused
     | ^
```

It costs nothing at run time and catches a configuration mistake before the program exists.

`assert` is checked while the program runs, and **only in a build with `-g`**. Without `-g` it
compiles to nothing at all, so it can stay in code that ships:

```tiko
{{#include ../examples/ch18/assertfail.tiko}}
```

```text
{{#include ../examples/ch18/assertfail.out}}
```

The failure names the file, the line, the procedure and the condition as written, and the program
exits with status 1. `assertwarn` does the same and carries on.

An assertion is for a mistake in the program — a caller passing 0 where the documentation says
"never 0". A condition the program should expect, like a missing file, is a `Result`.

## What it costs

- **An `Optional( of T )` is a `T` plus a flag**, and the `T` is default-constructed even when
  there is no value. A `Result( of T, E )` holds both a `T` and an `E`. For small types this is
  nothing; for a large one, return it through a parameter or a pointer instead.
- **Checking a `Result` is a branch** at every call. That is the point: the cost is paid where
  the decision is made.
- **`on error goto` costs nothing until an error happens**, and then skips destructors on its way
  out of a procedure, which is a cost of a different kind.
- **`-exx` slows every array access and pointer dereference.** `assert` costs nothing without
  `-g`, and a comparison with it.

## Summary

- A sentinel return value is ambiguous whenever it can also be a real answer.
- `Optional( of T )` holds a value or nothing: `HasValue`, `Value` (raises when empty), `ValueOr`.
  `Some( v )` and `None( of T )( )` build one; a new one is empty.
- `Result( of T, E )` holds a value or a reason: `IsOk`, `Value`, `Failure`, `ValueOr`. `Ok` and
  `Fail` need both type arguments, so name the type with `type … as`. **A new `Result` is a
  failure**, and `E` needs a default constructor.
- Pass failures up by returning them; give the error a code to branch on, as `fs.FsError` does.
- `open( … )` and `close( … )` used as functions return an error number instead of raising.
- `error n` raises a runtime error; `on [local] error goto` handles it; `err`, `erl`, `erfn`,
  `ermn` describe it. Copy `err` first.
- **An error that leaves a procedure for an outer handler skips that procedure's destructors and
  `defer`s.** tiko has no `resume`.
- `-e`, `-ex` and `-exx` add runtime checks; `__FB_ERR__` says which were used.
- `#assert` checks constants at compile time (`TKO0604`); `assert` checks at run time under `-g`.

## Exercises

1. Write `ToInt( s )` returning an `Optional( of int32 )` that accepts digits with an optional
   leading minus and refuses anything else. Use it to total the valid entries of a list and count
   the refused ones. {solution="ex18-01"}
2. Write `Divide` and `Root`, each returning a `Result( of float64, ustring )`, and a
   `RootOfRatio( a, b )` that stops at the first failure and passes it on. Run it over a success
   and one failure of each kind. {solution="ex18-02"}
3. Give `ConfigError` a `CFG_DUPLICATE` code, and make `ParseConfig` refuse a key that appears
   twice. Which function has to know about the other lines, and why?
4. Move the handler in `escape.tiko` into `Transfer`. What changes in the output, and why?
5. Compile `runtimeerrors.tiko` with `-e` instead of `-exx`. Which part of the handler's output
   changes?
