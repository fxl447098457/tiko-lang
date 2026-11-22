[Home](Home) › **Debugging**

# Debugging

Compile with [`-g`](Compiler-Option-G) and tiko writes DWARF debug information into the program: line tables, every procedure, its parameters and locals, `shared` variables, and their types -- a `type`'s fields, a `string`'s or `ustring`'s text. Any DWARF debugger reads it. **lldb** comes with LLVM, which tiko already needs; **gdb** works as well.

```
tiko -g prog.tiko
```

`-edebuginfo` writes the same debug information without the rest of `-g` (asserts, `__FB_DEBUG__`).

## A session in lldb

The program:

```freebasic
type Point
    as long x, y
end type

dim shared as long counter = 7

function Area( byval w as long, byval h as long ) as long
    dim as long a = w * h
    dim as Point p
    p.x = w : p.y = h
    dim as ustring label = "box"
    dim as string s = "hello"
    dim as double ratio = w / h
    counter += 1
    return a
end function

print Area( 6, 4 )
```

Start lldb on the executable, set a breakpoint by file and line, and run:

```
lldb prog.exe
(lldb) breakpoint set --file prog.tiko --line 14
(lldb) run
* thread #1, stop reason = breakpoint 1.1
    frame #0: prog.exe`Area(w=6, h=4) at prog.tiko:14
-> 14  	    counter += 1
```

`frame variable` lists the parameters and locals, with their types:

```
(lldb) frame variable
(long) w = 6
(long) h = 4
(long) a = 24
(Point) p = {
  x = 6
  y = 4
}
(ustring) label = (data = u"box", len = 3, size = 16)
(string) s = (data = "hello", len = 5, size = 32)
(double) ratio = 1.5
```

`print` evaluates one name, a `shared` variable included, and `bt` shows the call stack in source terms:

```
(lldb) print counter
(long) 7
(lldb) bt
  * frame #0: prog.exe`Area(w=6, h=4) at prog.tiko:14
    frame #1: prog.exe`main at prog.tiko:18
```

The commands used most:

| lldb | gdb | |
| --- | --- | --- |
| `b prog.tiko:14` | `break prog.tiko:14` | breakpoint at a line |
| `b Area` | `break Area` | breakpoint at a procedure |
| `run` | `run` | start the program |
| `next` | `next` | the next line, stepping over calls |
| `step` | `step` | the next line, stepping into calls |
| `finish` | `finish` | run until the current procedure returns |
| `continue` | `continue` | run to the next breakpoint |
| `frame variable` | `info locals` | the locals |
| `print p` | `print p` | one variable |
| `bt` | `bt` | the call stack |

## In tkEdit

tkEdit, the editor that comes with tiko, debugs a program without a command line. It drives **lldb-dap**, LLVM's debugger for editors, over the same DWARF.

| Key | Command |
| --- | --- |
| `F9` | Toggle a breakpoint on the cursor's line |
| `F6` | Start Debugging; in a session, Continue |
| `F10` | Step Over |
| `F11` | Step Into |
| `Shift+F11` | Step Out |
| `Ctrl+F10` | Run to Cursor |
| `Ctrl+F6` | Break |
| `Shift+F6` | Stop Debugging |
| `Ctrl+Shift+F9` | Delete All Breakpoints |

On macOS each `Ctrl` is `Cmd`. The commands are on the **Debug** menu, and every key can be moved in `keybindings.toml`.

**Start Debugging** builds with the selected configuration's options, without `-O` and with `-g -exx`, runs the program in its terminal as Run does, and stops on the first breakpoint it reaches -- or, with none set, on the program's first statement. A yellow arrow in the margin marks the line about to run; the status line says why it stopped and where.

The output pane's **Debug** tab holds the session:

- A row of buttons: Continue, Break, Stop, Step, Step Over, Step Out, Run to Cursor.
- On the left, tabs along the bottom: **Locals**, **Globals** and **Watch**, each a tree of Name, Value and Type. A record opens to its fields; an array shows its bounds, `(1 to 3)`, and opens to its elements, named by the program's own subscripts -- `rs(1)`, `rs(2)`, `rs(3)` -- in groups of a hundred when it is large. A string shows its text. A value that changed since the last stop is shown in the error colour, open rows stay open as you step, and a click on a column heading sorts.
- On the right: **Call Stack**, where a click on a frame shows its locals and goes to its line, and **Breakpoints**, every breakpoint in every open file with the text of its line; its two buttons remove the selected one or all of them.

A **watch** is a name written as in the program -- `rs(2).sensor`, `p->next`, `grid(1, 2)` -- matched case-insensitively against the stopped frame's locals, then the globals. It is a variable, a field or an element, not a calculation: `total / 3` shows `<not in scope>`. `+` adds a watch, a double click edits one, and an empty one is removed.

While the program is stopped, resting the mouse on a name in the source shows its value.

A click in the margin toggles a bookmark; `margin_click = "breakpoint"` in the `[editor]` table of `settings.toml` makes it toggle a breakpoint. Breakpoints are saved with the session.

### lldb-dap

tkEdit looks for lldb-dap on the `PATH`, then in LLVM's usual places; `adapter` in the `[debug]` table of `settings.toml` names it explicitly.

| System | lldb-dap |
| --- | --- |
| Windows | LLVM's `bin` folder, beside clang. It loads a 64-bit Python, which must be on the `PATH`: LLVM 23 takes any **Python 3** (`python3.dll`), LLVM 21 only **Python 3.10** (`python310.dll`). tkEdit reads which from `liblldb.dll` and checks for it before it starts. |
| Linux | The distribution's `lldb` package: `lldb-dap`, or a numbered `lldb-dap-NN` (the newest is taken). |
| macOS | Apple's Command Line Tools. macOS lets it control a program only in **Developer Mode** -- `sudo DevToolsSecurity -enable` -- or when the dialog asking for it is allowed. |

On macOS, `-g` also writes `<program>.dSYM` beside the executable: that is where the debugger finds the DWARF.

## Names

A procedure, a variable and a type are named as they are written in the source, and the debugger matches names **case-sensitively**: with `function Area` declared, `b Area` sets a breakpoint and `b area` finds nothing.

A `string` or `ustring` shows as its three parts: `data`, the text; `len`, its length in characters; and `size`, the bytes allocated.

An instantiation of a generic type is named by an internal number rather than by its type arguments: `Box( of long )` appears as `box<6>`, and its method's frame as `box<6>.SetV`. Its fields, parameters and locals show with their types as usual.

## See also

- [Compiler Option: -g](Compiler-Option-G)
- [Compiler Option: -fsanitize](Compiler-Option-Fsanitize): memory errors a debugger does not show
- [Compiler Error Messages](Compiler-Error-Messages)
- [`Assert`](Assert)
