[Home](Home) › [All Categories](Categories) › [tiko build](Category-Tiko-Build) › **tiko test**

# tiko test

```freebasic
' src/util/util_test.tiko -- beside util.tiko, in the module's own directory
#module "util"
#import "std/testing"

test "Twice doubles"
    testing.ExpectEq( Twice( 3 ), 6 )
end test

test "Half_ is private, and a test in the module can reach it"
    testing.ExpectEq( Half_( 8 ), 4 )
end test
```

```
> tiko test
running 2 tests
test Twice doubles ... ok
test Half_ is private, and a test in the module can reach it ... ok

test result: ok. 2 passed; 0 failed; 0 crashed; 0 timed out; 0 skipped (0.01 s)
```

`tiko test` finds a project's tests, builds them into one program, runs it and reports each test. A test is a `test "name" ... end test` block; the checks in it are [std/testing](#stdtesting)'s, qualified (`testing.ExpectEq`), so a failure names the file and line it was written on.

## Test blocks

```freebasic
test "what it checks"
    ' any statements: a test is a procedure
end test
```

- **`test` is not a keyword.** It is recognised at the start of a statement when a string follows it and nothing else does, and no procedure called `test` has been declared above it -- so `sub test( s as string )` and its paren-less call `test "x"` keep working, and so does a variable called `test`.
- **At the top level of a file only**: not inside a procedure, a namespace, a type or another test (`TKO1200`). The name is not empty (`TKO1202`).
- **The body is a procedure's.** What it declares is its own; `exit sub` leaves the test.
- **A normal build drops every test block.** It is parsed -- a syntax error in one is an error -- and then left out: nothing of it is compiled, and the program never names std/testing. So tests can sit beside the code they test.
- **A test build compiles and registers each one**: `tiko test`, or the compiler's `--test`. The file must import std/testing then (`TKO1201`).

## Test files

Tests live in files whose names end `_test.tiko` (or `_test.bas`). Where one is decides what it can see:

| Where | What it is |
|---|---|
| **in a module's directory**, beginning `#module "<that module>"` | **white-box**: part of the module in a test build, so it reaches the module's private names. A normal build leaves the file out of the module altogether. |
| **anywhere else in the project** | **black-box**: a program of its own in the test build, using the modules through `#import` as any program would. It must `#import "std/testing"`; a file only *named* like a test is left alone (`TKO1204` under `-v`). |

A `test` block in one of a module's ordinary files is compiled in a test build too, like a white-box file. A test block in a program's main file is not run by `tiko test` -- move the code under test into a module.

Only the project's own modules take part: the toolchain's `std` and `vendor`, and dependencies, keep their normal builds (and their cache entries).

## Running tests

```
tiko test [<dirs> | <x_test.tiko>...] [--profile <p>] [--timeout <s>] [--filter <text>] [--no-run]
          [build options] [-- <program arguments>]
```

| | |
|---|---|
| *(no words)* | the project: the `tiko.toml`'s directory, else the current one |
| `<dir>` | the tests under that directory |
| `<x_test.tiko>` | that test file |
| `--profile <p>` | `debug` unless given: `-g -exx -O0`, so a null or out-of-bounds access in a test is a runtime error with its line |
| `--timeout <s>` | how long one test may run; 120 seconds unless given, `0` for no limit |
| `--filter <text>` | only the tests whose names hold the text, in any case; may be repeated |
| `--no-run` | build the test program only |
| `-- ...` | arguments for the test program: `--list`, `--run <text>`, `--skip <text>`, `--exact <name>` |

The build options are `tiko build`'s: `--manifest`, `-target`, `--options`, `-j`, `--no-cache`, `--message-format json`, `-v`.

**What is built.** `out/test/tests.tiko` -- generated: it imports std/testing and each module with tests, and its one line of code is `end testing.RunMain( )` -- and every black-box test file, as one program, `out/test/tests` (`.exe` on Windows). It is built like any other with the [build cache](Category-Tiko-Build#what-is-not-done-twice): the second run of unchanged tests compiles nothing. Without a `tiko.toml`, the first directory named (else the current one) is the project, and its `out/test/` holds the program.

**The order** is the files' paths, then the lines: the same on every run.

**A test that ends the program** -- a runtime error under `-exx`, an `end`, a crash -- is reported `CRASHED (exit code N)`, and the program is started again after it, so the rest still run. **A test that runs too long** is killed and reported `TIMED OUT`, and the run goes on the same way.

**Exit code**: 0 when every test passed (or was skipped), 1 otherwise -- a failure, a crash or a timeout. A failed build exits as `tiko build` does.

A test program for another system cannot run here: `TKO1205`, unless `--no-run`.

## std/testing

```freebasic
#import "std/testing"
```

| Check | Passes when |
|---|---|
| `testing.Expect( c )` | `c` is true |
| `testing.ExpectFalse( c )` | `c` is false |
| `testing.ExpectEq( a, b )` | `a = b` |
| `testing.ExpectNe( a, b )` | `a <> b` |
| `testing.ExpectNear( a, b, eps )` | `abs( a - b ) <= eps` |
| `testing.Require( c )` | as `Expect`, and the test **stops** when it fails |
| `testing.RequireEq( a, b )` | as `ExpectEq`, and the test stops when it fails |
| `testing.Fail( "why" )` | never: a failure, and the test goes on |
| `testing.Skip( "why" )` | the test stops here and counts as skipped |

- `ExpectEq` and `ExpectNe` take integers of any width, enums, `double` and `single`, `boolean`, `string`, `ustring` and pointers, and a literal on either side.
- An `Expect` that fails marks its test failed, and **the test goes on**, so one run shows every failed check.
- They are **macros, used qualified**: only a macro sees the line it is written on, and an exported macro is never global (`using testing` does not make them bare).

A failure:

```
test Twice doubles ... FAILED
    util_test.tiko:4: ExpectEq failed
      Twice( 3 ) = 7
      6
```

`testing.CurrentTestName( )` is the running test's name. `testing.RunMain( )` runs the registered tests and returns the exit code; `tiko test` writes the call for you, and a single file of tests can end with `end testing.RunMain( )` and be built with `tiko --test file.tiko`.

## The JSON event stream

With `--message-format json`, the build's [events](Category-Tiko-Build#the-json-event-stream) come first, then one per test. The test program's own output goes to `out/test/output.log`, not into the stream.

```
{"event":"test-plan","tests":3}
{"event":"test-start","index":0,"name":"Twice doubles","file":"C:/proj/src/util/util_test.tiko","line":4}
{"event":"test-fail","index":0,"file":"C:/proj/src/util/util_test.tiko","line":5,"message":"ExpectEq failed\n      ..."}
{"event":"test-end","index":0,"name":"Twice doubles","status":"fail","ms":0}
{"event":"test-summary","passed":2,"failed":1,"skipped":0,"crashed":0,"timedOut":0,"ms":41}
```

`status` is `pass`, `fail`, `skip`, `crash` (with `"exit"`, and `"output"`: the end of the program's output) or `timeout`.

## Diagnostics

| Id | When |
|---|---|
| `TKO1200` | a `test` block inside a procedure, a namespace, a type or another test |
| `TKO1201` | a test build of a `test` block in a file that does not import std/testing |
| `TKO1202` | `test ""` |
| `TKO1203` | (warning) no tests found |
| `TKO1204` | (note, `-v`) a file named like a test that does not import std/testing |
| `TKO1205` | a test program for another system, without `--no-run` |
| `TKO1206` | the test program stopped before running a test: a module's initialiser ended it |
| `TKO1211` | a word that is neither a directory nor a test file |

## Not yet

- Test blocks inside a namespace.
- Tests run one at a time, in one process (started again after a crash).
- Code examples in documentation comments are not compiled yet ([tiko doc](Category-Tiko-Doc)).
