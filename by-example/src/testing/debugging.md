# Debugging in tkEdit

When a result is wrong and you do not know where, stop the program and look.
tkEdit, the editor that comes with tiko, has a debugger: set a breakpoint, run
to it, and read every variable while the program waits.

```tiko
{{#include ../../examples/testing/debugging.tiko}}
```

**Output**

```text
{{#include ../../examples/testing/debugging.out}}
```

Open the file in tkEdit, put the cursor on line 10 (`total += …`) and press
**`F9`**: a red circle in the margin marks the breakpoint. Press **`F6`**.
tkEdit builds the program with `-g -exx` and without `-O`, runs it in its
terminal, and stops on line 10 inside `Average`, with a yellow arrow in the
margin. The output pane opens on its **Debug** tab, and the **Locals** tab
shows:

| Name | Value | Type |
|---|---|---|
| `scores` | `(1 to 3)` | `Score()` |
| `total` | `0` | `long` |
| `i` | `1` | `long` |

- **`scores` opens** to `scores(1)`, `scores(2)` and `scores(3)`: elements are
  named by the subscripts the program uses, so they match the source. Each
  element opens to `player` and `points`, and a `ustring` shows its text,
  `u"Ana"`. An array with more than a hundred elements opens to groups of them
  first.
- **The Type column** uses the debugger's names for the numeric types: an
  `int32` is a `long` and a `float64` a `double`.
- **`F10`** runs line 10 and stops on the next one; press it again and again
  to watch `total` grow and `i` count. A value that changed since the last stop
  is shown in red.
- **`F6`** continues to the next breakpoint — here, line 10 again, for the
  next element. Take the breakpoint away with `F9` first, and **`Shift+F11`**
  runs to the end of `Average` and stops back in the main program.

The keys:

| Key | |
|---|---|
| `F9` | breakpoint on the cursor's line, on or off |
| `F6` | build and start; in a session, continue |
| `F10` / `F11` / `Shift+F11` | step over / step into / step out |
| `Ctrl+F10` | run to the cursor's line |
| `Ctrl+F6` | break into the running program |
| `Shift+F6` | stop; the program ends |
| `Ctrl+Shift+F9` | remove every breakpoint |

On macOS each `Ctrl` is `Cmd`. All of them are on the **Debug** menu too.

**Watch** takes a name the way the program writes it: add a row with the `+`
button, type `scores(2).player`, and press `Enter`. Case does not matter, and
the subscript is the program's. A watch is a variable, a field or an element,
not a calculation, and a name the stopped procedure cannot see shows
`<not in scope>`.

**Call Stack** lists `Average` and, below it, `main`, the main program; a click on a
frame shows that frame's locals and goes to its line. **Breakpoints** lists
them all, and the buttons at the end of its tab row remove the selected one,
or every one. Resting the mouse on a name in the source shows its value.

```admonish info title="lldb-dap"
tkEdit drives **lldb-dap**, from LLVM. On Windows it is beside clang; a `win32`
program needs a native i686 adapter, while a 64-bit program uses the 64-bit one.
It needs Python 3.10 on the `PATH` for LLVM 21, or any Python 3 for LLVM 23. On
Linux it is in the `lldb` package. On macOS it comes with the Command Line Tools, and macOS lets it
control a program only in Developer Mode (`sudo DevToolsSecurity -enable`) or
when you allow it. When it is somewhere else, set its path as `adapter` in the
`[debug]` table of `settings.toml`, or set `TKEDIT_LLDB_DAP` for a test or
portable toolchain.
```

### Activities

1. Step through the loop with `F10` and stop when `total` is `27`. What is `i`?
2. Add a watch on `total / 3` and on `total`. Which one shows a value, and why?
3. Set a second breakpoint on the `print` line, remove the first one on the
   Breakpoints tab, and press `F6` again.
