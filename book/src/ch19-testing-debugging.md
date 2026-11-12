# Testing, Debugging and Tooling

A program that compiles is a program the compiler could read. Whether it does what you meant is a
separate question, and the sooner you find out the cheaper the answer is. A failed test costs a
minute. A wrong number found in a report a month later costs the month.

This chapter is about the tools that shorten that distance. **Tests** check behaviour you have
decided on, every time you build. **Tracing** and a **debugger** show you what a program did when a
test, or a user, finds it doing something else. And the compiler's own options — its warnings, its
diagnostics file and its ways of showing you the code it generated — are tools too.

## Unit tests with fbcunit

tiko ships a unit-test library, fbcunit. A test is a block of code that checks something with an
assertion; tests are grouped into suites; one call runs them all and prints a summary. No module
fronts the library, so it is reached with `#include`:

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

- **Tests are code you maintain.** They pay for themselves when they check behaviour callers
  depend on, and cost you when they pin down details nobody relies on. Test through the public
  surface.
- **Tracing costs nothing when it is compiled out**, and a call, a string build and a write per
  `TRACE` when it is in.
- **`-g` makes the executable larger**: the debug information is stored beside the code. Keep it
  in every development build. Optimisation works against it — variables live in registers and
  lines are reordered — so debug an unoptimised build.
- **`-Werror` costs a little friction**, paid when the warning appears rather than when the bug it
  predicted does.

## Summary

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
