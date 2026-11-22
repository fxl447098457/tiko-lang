# Testing, Debugging and Tooling

A program that compiles is a program the compiler could read. Whether it does what you meant is a
separate question, and the sooner you find out the cheaper the answer is. A failed test costs a
minute. A wrong number found in a report a month later costs the month.

This chapter is about the tools that shorten that distance. **Tests** check behaviour you have
decided on, every time you run `tiko test`. **Tracing** and a **debugger** show you what a program did when a
test, or a user, finds it doing something else. And the compiler's own options — its warnings, its
diagnostics file and its ways of showing you the code it generated — are tools too.

## Unit tests with tiko test

A test checks one thing you have decided the code must do. In tiko a test is a block of its own,
written beside the code it checks, and one command finds every test in a project, builds them into
a program and runs it:

```text
tiko test
```

```admonish warning title="Status in this version"
`tiko test`, `test` blocks and std/testing arrive after tiko 0.1.6, the toolchain this book is pinned
to. The listings in this section were compiled and run with the development toolchain; the book's
harness reports them as blocked (`pin-0.1.6`) until the pin moves to a release that has them.
```

### A test, and what it checks

Here is a small project: a stack of `int32` in a module, and the tests that pin its behaviour down.
The module first, `stacks/stacks.tiko`:

```tiko
{{#include ../examples/ch19/tested/stacks/stacks.tiko}}
```

The tests a client of the module would write sit in the project's own directory, in a file whose
name ends `_test.tiko`:

```tiko
{{#include ../examples/ch19/tested/stack_api_test.tiko}}
```

`tiko test`, in the project's directory:

```text
{{#include ../examples/ch19/tested/stack_api_test.out}}
```

- **`test "name"` … `end test`** is one test. Its body is ordinary code, and it is a procedure of
  its own: what it declares is its own, and every test starts with a fresh `Stack`.
- **`testing.ExpectEq( a, b )`** checks that `a = b`. When it does not, the failure names the file
  and line the check is written on, and both sides: the expression as written, and the value it
  had. A literal is shown once.
- **A failed `Expect` does not stop its test.** The test carries on, so one run reports every
  failed check, not just the first.
- **The exit code is 1** when anything failed — the third test is wrong on purpose — which is what
  a build script or a CI job checks.

The checks are macros, which is why they are written `testing.ExpectEq` and never bare: only a
macro sees the line it is written on. The ones you will use most:

| Check | Passes when |
|---|---|
| `testing.Expect( c )`, `testing.ExpectFalse( c )` | `c` is true, or false |
| `testing.ExpectEq( a, b )`, `testing.ExpectNe( a, b )` | `a = b`, or `a <> b` |
| `testing.ExpectNear( a, b, eps )` | `a` is within `eps` of `b` |
| `testing.Require( c )`, `testing.RequireEq( a, b )` | as `Expect` and `ExpectEq`, and the test **stops** when they fail |
| `testing.Fail( "why" )` | never: marks a line that must not be reached |
| `testing.Skip( "why" )` | the test stops here and is counted as skipped |

Use `Require` when the rest of the test means nothing without it: a pointer that must not be null
before you follow it, a file that must have opened before you read it.

### Tests inside a module

The fourth test in that run came from somewhere else. A `_test.tiko` file **inside a module's
directory** begins with the module's own `#module` line and is part of the module — but only in a
test build:

```tiko
{{#include ../examples/ch19/tested/stacks/stacks_test.tiko}}
```

`NextSize_` has no `public`: no program that imports `stacks` can call it. A test inside the module
can, because it *is* the module. These are **white-box** tests, for the internals that matter on
their own; the file outside the module holds **black-box** tests, which see only what any client
sees. A normal `tiko build` leaves every `_test.tiko` file out of its module altogether, and parses
and drops every `test` block, so tests cost the shipped program nothing.

A `test` block may also sit in one of the module's ordinary files, beside the procedure it checks.
`tiko test` finds those too.

### Running a selection

```text
tiko test --filter pops          only the tests whose names hold "pops"
tiko test stacks                 only the tests under that directory
tiko test -- --list              print the tests and stop
```

`tiko test` builds its program the way `tiko build` builds any other — the first run compiles, a
second with nothing changed compiles nothing — under the `debug` profile, so `-exx` is on: a null
pointer or an index out of range inside a test is a runtime error with its line, not a quietly
wrong number.

### A test that ends the program

tiko has no exceptions to catch, so a test that ends the program — a runtime error, an `end`, a
crash — ends every test after it too. `tiko test` does not let it. It runs the program, and when a
test stops it, reports that test and starts the program again from the next one. A test that runs
too long is stopped the same way:

```tiko
{{#include ../examples/ch19/stopping/sensors_test.tiko}}
```

`tiko test --timeout 1`:

```text
{{#include ../examples/ch19/stopping/sensors_test.out}}
```

`ParseReading` ends the program on a reading it cannot believe — exit code 3 — and
`WaitForSensor` never returns. Each is reported, and the last test still runs. Without
`--timeout`, a test may run for 120 seconds.

````admonish danger title="Pitfall"
**A test in the program's main file never runs.** This project's tests are in `main.tiko`:

```tiko
{{#include ../examples/ch19/forgotten/main.tiko}}
```

`tiko test`:

```text
{{#include ../examples/ch19/forgotten/main.out}}
```

The test is wrong — `Twice( 2 )` is 4, not 5 — and nothing says so. A normal build drops every
`test` block, and `tiko test` looks for tests only in modules and in `_test.tiko` files, never in a
program's main file, whose top-level code would run as well. The only sign is the warning, and
exit code 0. Put the code under test in a module, and its tests beside it.
````

## Unit tests with fbcunit

FreeBASIC's own unit-test library, fbcunit, ships with tiko too, and code written for it compiles
unchanged. Prefer `tiko test` for new code; this section is for the tests you already have. A test
is a block of code that checks something with an assertion; tests are grouped into suites; one call
runs them all and prints a summary. No module fronts the library, so it is reached with `#include`:

```tiko
{{#include ../examples/ch19/firsttests.tiko}}
```

```text
{{#include ../examples/ch19/firsttests.out}}
```

`SUITE( lifo )` … `END_SUITE` groups the tests; each `TEST( name )` … `END_TEST` is one test with a
fresh `Stack` of its own. `fbcu.run_tests( )` runs every test, prints each failed assertion with
its file, line and the assertion as written, then the summary, and returns `true` only if
everything passed. The last line turns that into the program's exit code — 1 here, because the
third test is wrong on purpose — which is what a build script or a CI job checks.

The assertions you will use most:

| Macro | Passes when |
|---|---|
| `CU_ASSERT( c )` | `c` is true |
| `CU_ASSERT_EQUAL( a, b )` | `a = b` |
| `CU_ASSERT_NOT_EQUAL( a, b )` | `a <> b` |
| `CU_ASSERT_TRUE( c )`, `CU_ASSERT_FALSE( c )` | `c` is true, or false |
| `CU_ASSERT_DOUBLE_EQUAL( a, e, g )` | `a` is within `g` of `e` |
| `CU_FAIL( msg )` | never: marks code that must not be reached |

A failed assertion does not stop its test: the test carries on, and every failed assertion is
listed before the summary. That is why one `TEST` can hold several related checks, as
`pops_in_reverse` does.

```admonish note
**A suite is a namespace,** so it cannot share a name with something it sits beside.
`SUITE( stack )` next to a `Stack` type is refused, and the message lands on the type's methods —
`TKO0669: 'stack.push' adds a new name to a namespace from outside it` — rather than on the suite.
Name a suite after the behaviour it checks, not after the type.
```

### Tests in a multi-module project

In a real project the code under test lives in a module, and the tests are a separate program that
imports it. Here is the stack as Chapter 15's kind of module, `stacks/stacks.tiko`:

```tiko
{{#include ../examples/ch19/stacks/stacks.tiko}}
```

and its tests:

```tiko
{{#include ../examples/ch19/stacktests.tiko}}
```

```text
{{#include ../examples/ch19/stacktests.out}}
```

The test program sees the module exactly as any other client does: `stacks.Stack` and its public
members, and nothing `private`. That is a feature. Tests written against the public surface keep
passing while you rearrange the inside, and they fail when you change what callers depend on —
which is the change you wanted to hear about.

````admonish danger title="Pitfall"
**Suites do not run in the same order on every platform.** On Windows the same program prints its
summary the other way round:

```text
{{#include ../examples/ch19/stacktests.windows-x86_64.out}}
```

Each `SUITE` registers itself with a module constructor, and module constructors run in the order
each platform's start-up code walks them — declaration order on Linux and macOS, the reverse on Windows,
exactly as fbc does it. Nothing is wrong while every test stands alone. A test that quietly relies
on state an earlier suite left behind — a file it wrote, a global it set — passes on one platform
and fails on the other. Give every test its own setup.
````

## Tracing

Sometimes the quickest way to see what a program did is to have it tell you. Three predefined
names make that useful: **`__FILE__`** is the source file being compiled, **`__LINE__`** the line,
and **`__FUNCTION__`** the procedure — in capitals, and `__FB_MAINPROC__` at module level. Wrapped
in a macro, they report where the macro was *used*, not where it was defined:

```tiko
{{#include ../examples/ch19/trace.ti}}
```

```tiko
{{#include ../examples/ch19/tracing.tiko}}
```

```text
{{#include ../examples/ch19/tracing.out}}
```

Two decisions in `trace.ti` are worth copying:

- **Trace output goes to stderr.** `open err` opens the standard error stream as a file number.
  The program's real output stays on stdout, so `program > result.txt` still captures exactly the
  result, and the trace stays on the screen or goes to a file of its own with `2> trace.txt`.
- **Tracing is switched off by the preprocessor, not by an `if`.** Remove the `#define TRACING`
  line and `TRACE( … )` expands to nothing: the calls are gone from the generated code, and so is
  the cost of building their messages. The `TraceAt` procedure itself is still compiled; it is
  never called.

```admonish note
Do not mix trace lines and ordinary output in one stream and expect their order to hold. stdout
and stderr are separate streams with separate buffers; when both go to the same place, how the
lines interleave depends on the platform and on what is reading them. That is why everything
`tracing.tiko` prints goes through `TRACE`.
```

## Debugging with -g

Tracing answers questions you thought to ask before you ran the program. A debugger answers the
ones you think of while it is stopped. Compile with **`-g`** and tiko writes **DWARF** debug
information into the executable: line tables, procedures, and every variable with its type. Any
DWARF debugger can then stop the program and show you its state. The one that comes with the LLVM
install tiko already uses is **lldb**.

```tiko
{{#include ../examples/ch19/readings.tiko}}
```

```text
{{#include ../examples/ch19/readings.out}}
```

Build it with `tiko -g readings.tiko`, then run it under lldb, stopping at line 10:

```text
(lldb) breakpoint set -f readings.tiko -l 10
(lldb) run
* thread #1, stop reason = breakpoint 1.1
    frame #0: readings.exe`Total(rs=0x0000005c4975f7e0) at readings.tiko:10
   9   	    for i as int32 = lbound( rs ) to ubound( rs )
-> 10  	        sum += rs( i ).value
   11  	    next
(lldb) frame variable sum i
(double) sum = 0
(long) i = 1
(lldb) up
frame #1: readings.exe`main at readings.tiko:20
-> 20  	print label; Total( rs( ) )
(lldb) frame variable label
(ustring) label = (data = u"total", len = 5, size = 16)
(lldb) frame variable rs
(Reading(1 to 3)) rs = {
  [0] = {
    sensor = (data = u"north", len = 5, size = 18)
    value = 3.5
  }
  [1] = {
    sensor = (data = u"south", len = 5, size = 18)
    value = 4
  }
  [2] = {
    sensor = (data = u"east", len = 4, size = 18)
    value = 5.5
  }
}
```

The breakpoint is set by file and line, the stop shows the source around it, and `up` moves to the
caller. Variables keep their types: a record shows its fields, a `ustring` its text and length, and
the array its declared bounds, `Reading(1 to 3)`. lldb spells some types the way C would — an
`int32` is a `long` and a `float64` a `double` — because that is the vocabulary it has.

Two kinds of value read less well. An **array parameter**, such as `rs` inside `Total`, is passed
as a descriptor, and lldb shows the descriptor's fields — the data pointer, the element size, and
eight dimension slots of which only the first `dimensions` mean anything. And a `ustring` shows its
bookkeeping beside its text.

````admonish danger title="Pitfall"
**lldb's `[ ]` counts from zero, whatever bounds the array was declared with.**

```text
(lldb) p rs[1]
(Reading) {
  sensor = (data = u"south", len = 5, size = 18)
  value = 4
}
```

`rs` is declared `1 to 3`, so `rs( 1 )` in the program is `"north"` — but lldb's `rs[1]` is the
*second* element, `"south"`. lldb reads the expression as C, and C arrays start at zero. The listing
labels the elements `[0]` to `[2]` for the same reason. Subtract the lower bound before you index,
or read the element out of the full listing.
````

```admonish info title="On Windows"
On windows-x86_64 the DWARF is placed inside the `.exe`; tiko asks the linker for that itself under
`-g` (`-debug:dwarf`). No `.pdb` is written and no CodeView is emitted, so Visual Studio and
WinDbg cannot read a tiko program's variables. lldb, and `lldb-dap` for editors, are in the same
LLVM `bin` directory as clang.
```

```admonish info title="On Linux"
gdb, which Ubuntu installs by default, reads the same DWARF. `break readings.tiko:10`, `run` and
`info locals` stop in `Total` and show `sum` and `i`; `print rs` in the caller shows the three
records with their strings. Unlike lldb, gdb honours the declared lower bound: its `print rs[1]` is
the element the program calls `rs( 1 )`, `"north"`.
```

The same session needs no commands in tkEdit (Chapter 2). Put the cursor on line 10, press `F9`
for a breakpoint and `F6` to build with `-g` and run. The program stops in `Total`, and the
Locals tab of the output pane lists `rs`, `sum` and `i`. There `rs` is `(1 to 3)` and opens to `rs(1)`, `rs(2)` and
`rs(3)`, each element named by the subscript the program uses: tkEdit reads the array descriptor,
so the zero-based pitfall above does not apply. A string shows its text, `u"north"`, without the
bookkeeping, and a watch takes the program's spelling, `rs(2).sensor`.

## Memory errors with -fsanitize=address

`-exx` catches an index past an array's bounds and a null pointer. It cannot catch memory that was
freed and then used: the pointer still holds a real address, and the program reads whatever is
there now. **AddressSanitizer** can. Build with **`-fsanitize=address`** and every procedure checks
each memory access against a map of what the program may touch, and freed blocks are held back
from reuse, so a stale pointer lands on poisoned memory instead of someone else's data.

```admonish warning title="Status in this version"
`-fsanitize=address` arrives after tiko 0.1.6, the toolchain this book is pinned to. The listing in
this section was compiled and run with the development toolchain; the book's harness reports it as
blocked (`pin-0.1.6`) until the pin moves to a release that has it.
```

```tiko
{{#include ../examples/ch19/freed.tiko}}
```

```text
{{#include ../examples/ch19/freed.out}}
```

The listing names its options itself, so `tiko freed.tiko` builds it checked. Without the
`#cmdline` line the same program prints a second reading, a meaningless number such as
`1.228383301872162e-311`, and exits 0 as if nothing had happened. Checked, it stops at the read,
exits 1 (macOS aborts it instead, exit 134), and prints its report on standard error. Trimmed to
the lines that matter:

```text
==11612==ERROR: AddressSanitizer: heap-use-after-free on address 0x1206dbfa0070 ...
READ of size 8 at 0x1206dbfa0070 thread T0
    #0 0x7ff6a82c1136 in main freed.tiko:12
freed by thread T0 here:
    #1 0x7ff6a82c10f2 in main freed.tiko:11
previously allocated by thread T0 here:
    #1 0x7ff6a82c102e in main freed.tiko:8
```

**The report answers all three questions** a stale pointer raises: where it was used, where the
block was freed, and where it was allocated. `-g` is what puts line numbers in it; without `-g` it
names procedures only. The same build catches the other memory errors a program can make:

| Bug | Report |
|---|---|
| Reading or writing a block after `delete` or `deallocate` | `heap-use-after-free` |
| Freeing a block twice | `attempting double-free` |
| A pointer past either end of an `allocate`d block | `heap-buffer-overflow` |
| A local array or record reached past its end through a pointer | `stack-buffer-overflow` |
| The address of a local, used after its procedure returned | `stack-use-after-return` |

A project gets all of it from one option: **`tiko build --profile asan`** uses a built-in profile,
`-g -exx -O1 -fsanitize=address`, and builds into `out/asan/` beside the debug build (Chapter 31).
Code that has to know is told: `__TIKO_ASAN__` is defined, as `1`, in a checked build.

The runtime that does the checking is clang's, from the LLVM tiko already uses. On Windows its DLL,
`clang_rt.asan_dynamic-x86_64.dll`, is copied beside the program; on Ubuntu, install the
`libclang-rt-<version>-dev` package that matches clang.

```admonish danger title="Pitfall"
**It checks your program's memory, not tiko's runtime.** Every `new`, `delete`, `allocate` and
string the program makes goes through the checked allocator, so a mistake in how the program uses
memory is caught. A bug inside a runtime routine is not.
```

## Warnings and the diagnostics workflow

An error stops the build. A **warning** does not: the program is built, and it runs. That is
exactly what makes warnings worth your attention.

````admonish danger title="Pitfall"
**A warning is often a wrong answer the compiler noticed first.**

```tiko
{{#include ../examples/ch19/ptrwarn.tiko}}
```

```text
ptrwarn.tiko(9,7): warning TKO0833: passing different pointer types: a 'int64 ptr' for a 'int32 ptr' parameter
     |
   9 | Fill( @squares( 0 ), 4 )
     |       ^
```

```text
{{#include ../examples/ch19/ptrwarn.out}}
```

`Fill` writes four `int32`s, sixteen bytes. `squares` is four `int64`s. The first two squares land
in `squares( 0 )` and `squares( 1 )` as halves of 64-bit numbers, and the last two elements are
never touched. The build succeeded and the exit code is 0. Only the warning said anything.
````

Three options decide what warnings do to a build:

| Option | Effect |
|---|---|
| `-Werror` | every warning becomes an error, and the build fails |
| `-Wno-TKOnnnn` | that one diagnostic is not reported |
| `--diagnostics-format gnu` | the location as `file:line:col:`, the form many tools parse |

With `-Werror` the same program stops at `error TKO0833` and the exit code is 1. Turn it on in any
build where you would rather fix a warning than discover it. Use `-Wno-` for a single, understood
warning, by id, and never wider: every diagnostic has a permanent number (Appendix B), so the
option says exactly what it silences.

### The diagnostics file

The console text is for a person. A tool that needs the diagnostics — an editor, a build script, a
CI job — asks for **`--diagnostics-file path`**, and tiko writes every diagnostic of the run there
as well, one tab-separated record per line:

```text
tiko-diagnostics	1
warning	TKO0833	C:\work\ptrwarn.tiko	9	7	9	8	passing different pointer types: a 'int64 ptr' for a 'int32 ptr' parameter
end	0	1	0
```

The first line names the format and its version. Each record is the kind — after `-Werror` and
`-Wno-` have been applied — the id, the absolute path, the start and end of the range (line and
column, the end exclusive), and the message. The `end` record carries the error count, the warning
count and the exit code; a file with no `end` record means the compiler did not finish. The
console output is unchanged. This is what tkEdit reads after every build, to list the errors
and underline them in the source.

## Looking inside a build

When you need to know what the compiler made of your code, ask it. One listing to look at:

```tiko
{{#include ../examples/ch19/layout.tiko}}
```

```text
{{#include ../examples/ch19/layout.out}}
```

**`--dump-udt`** prints each record's size, alignment and field offsets, and stops:

```text
packet size 12 align 4
  packet off kind 0
  packet off length 4
  packet off flags 8
```

Six bytes of fields take twelve bytes of record. `length` is aligned to 4, so three bytes of
padding follow `kind`, and the record's size is rounded up to its alignment after `flags`. Chapter
9's advice — order fields from largest to smallest — is the fix, and `--dump-udt` is how you check
it worked.

**`--emit-ir`** writes the LLVM IR tiko hands to clang, and stops. Without `-o` it goes to
stdout:

```text
define i32 @"SQUARE"(i32 %p0) nounwind uwtable(sync) {
L0:
  %s0 = alloca i32, align 4
  store i32 0, ptr %s0, align 4
  %s1 = alloca i32, align 4
  store i32 %p0, ptr %s1, align 4
  %t4 = load i32, ptr %s1, align 4
  %t5 = load i32, ptr %s1, align 4
  %t6 = sext i32 %t4 to i64
  %t7 = sext i32 %t5 to i64
  %t8 = mul i64 %t6, %t7
  %t9 = trunc i64 %t8 to i32
  ret i32 %t9
}
```

**`--emit-asm`** writes the machine code as assembly, to `layout.s` unless `-o` names another
file, and stops. With `-O2` the IR above becomes three instructions:

```text
SQUARE:
	movl	%ecx, %eax
	imull	%ecx, %eax
	retq
```

The IR is written plainly — every parameter goes to memory and comes back, the multiplication is
done at 64 bits and narrowed — and the optimiser removes all of it. Read the IR to see what your
code *means*; read optimised assembly to see what it *costs*.

| Option | Shows |
|---|---|
| `--dump-udt` | records' sizes, alignment and field offsets |
| `--dump-vtable` | each type's virtual method table (Chapter 14) |
| `--dump-mangle` | the symbol name each procedure is emitted under |
| `--emit-ir` | the LLVM IR, then stops |
| `--emit-asm` | the assembly, then stops |
| `--keep-temps` | builds normally and keeps the `.ll` and `.o` files beside the output |
| `-v` | the clang and linker command lines tiko runs |

The full list, with the front end's own `--dump-*` options, is Appendix C.

## What it costs

- **`tiko test` builds one more program**, with `-exx` on: slower than a release build, and the
  point — a test that reads out of bounds should fail, not pass by luck. A test that ends the
  program costs a restart, and each restart runs every module's initialisation again.
- **Tests are code you maintain.** They pay for themselves when they check behaviour callers
  depend on, and cost you when they pin down details nobody relies on. Test through the public
  surface.
- **Tracing costs nothing when it is compiled out**, and a call, a string build and a write per
  `TRACE` when it is in.
- **`-g` makes the executable larger**: the debug information is stored beside the code. Keep it
  in every development build. Optimisation works against it — variables live in registers and
  lines are reordered — so debug an unoptimised build.
- **`-fsanitize=address` makes a program slower and larger**, and it uses more memory: freed
  blocks wait before they are reused, and every access is checked. It is a build for finding bugs,
  not one to ship.
- **`-Werror` costs a little friction**, paid when the warning appears rather than when the bug it
  predicted does.

## Summary

- A test is `test "name"` … `end test`; `tiko test` finds, builds and runs every test of a
  project. Checks are std/testing's macros, written `testing.ExpectEq( a, b )`; a failure names its
  file and line, and a failed `Expect` lets the test go on while `Require` stops it.
- A `_test.tiko` file in a module's directory is part of the module in a test build only, and can
  test its private names; one elsewhere tests through the public surface. Normal builds drop every
  test.
- A test that ends the program, or runs past `--timeout`, is reported, and the rest still run.
- **A test in a program's main file never runs.**
- fbcunit: `#include once "fbcunit.bi"`, `SUITE`/`TEST` blocks, `CU_ASSERT*` macros, and
  `fbcu.run_tests( )`, whose result becomes the exit code. A suite is a namespace; name it after a
  behaviour.
- Test a module from a separate program that imports it, through its public surface.
- **Suites run in a platform-dependent order**; no test may depend on another.
- `__FILE__`, `__LINE__` and `__FUNCTION__` inside a macro report the place of use. Trace to
  stderr with `open err`, and switch tracing off with the preprocessor.
- `-g` writes DWARF with variables and types. lldb shows locals, records, strings and fixed
  arrays; **its `[ ]` counts from zero**. On Windows the DWARF is inside the `.exe`; there is no
  `.pdb`.
- tkEdit's debugger (`F9`, `F6`) reads the same DWARF and names elements by the program's own
  subscripts.
- `-fsanitize=address` (with `-g`), or `tiko build --profile asan`, stops a program at a
  use-after-free, a double free, an overflow or a returned local's address, and names the line of
  the use, the free and the allocation.
- A warning can be a wrong answer: `-Werror` fails the build on one, `-Wno-TKOnnnn` silences one
  by id, `--diagnostics-file` gives tools the records.
- `--dump-udt`, `--emit-ir`, `--emit-asm`, `--keep-temps` and `-v` show what the compiler made of
  your code.

## Exercises

1. Write `Clamp( v, lo, hi )` and an fbcunit suite for it with three tests: a value inside the
   range, values on both edges, and values outside on both sides. {solution="ex19-01"}
2. Add `TRACEVAL( x )` to `trace.ti`'s family: it prints the expression as written, `=`, and its
   value. (`#x` turns a macro argument into a string.) {solution="ex19-02"}
3. Make `stacktests.tiko` fail on one platform only, by letting the `peeking` suite rely on
   something `lifo` does. Then remove the dependency.
4. Reorder `Packet`'s fields so that `--dump-udt` reports a size of 8. Why not 6?
5. Run `readings.tiko` under lldb and print the element `rs( 3 )` the program means. Which
   expression did you need?
6. Add a `test` block to `stacks.tiko` itself, beside `Stack.Pop`, checking that popping the only
   item leaves the stack empty. Run `tiko test` and find your test in the output.
