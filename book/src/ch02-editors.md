# Editors: tkEdit and the Language Server

The compiler tells you about a mistake when you build. That is a round trip: save, switch to a
terminal, run `tiko`, read a line number, go back and find the line. For a missing `end if` the
trip costs more than the fix.

An editor that understands tiko shortens it. It underlines the missing `end if` while you are
still on the line, shows a procedure's parameters while you type its call, takes you to a
declaration with one key, and builds and runs the program with another.

tiko comes with two tools for this. **tkEdit** is an editor of its own, in the same folder as the
compiler. **tiko-lsp**, the tiko *language server*, gives the editor you already use — VS Code,
Zed, Neovim, Sublime Text and others — the same understanding. This chapter sets up both. Neither
is required by anything else in this book: every example is a file and a command line.

## What the editor knows, and what only the compiler knows

Both tools read your code as you type, and both do it **without compiling it**. They find the
declarations — which names a file declares and where, what type a variable was declared with,
which members that type has, what an `#include` or an `#import` brings in — in well under the
time between two keystrokes: the language server reads a 900-line file in about a millisecond.
That is enough for completion, codetips and going to a declaration. The language server also
checks the code's *shape* — a `function` with no `end function`, a string with no closing
quote — and underlines a mistake in it as you type.

Neither knows what only compiling tells you: whether a name used in an expression was ever
declared, whether a string is being assigned to a number, whether a call has the right number of
arguments. Those errors come from the compiler, when you build. Both tools then show the
compiler's errors in the source and in a list, beside their own, so the difference is easy to
forget. The Pitfall at the end of the chapter shows what that costs.

This program is the one the chapter edits:

```tiko
{{#include ../examples/ch02/rect.tiko}}
```

```
{{#include ../examples/ch02/rect.out}}
```

## tkEdit

tkEdit is a small, keyboard-driven editor for tiko, on Windows, Linux and macOS. It comes with
the toolchain, so there is nothing else to install:

| System | tkEdit |
|---|---|
| Windows | `tiko-lang\tkedit.exe` |
| Linux | `tiko-lang/tkedit` |
| macOS | `tiko-lang/tkEdit.app` |

Start it with the files to edit, or with none to restore the last session:

```
tkedit rect.tiko
```

The editor fills the window, with a tab for each open file above it and no toolbar. The menu bar
appears when you press `Ctrl+Shift+M` and goes again when you pick a command. On a Mac, every
`Ctrl` chord in this section is `Cmd`.

tkEdit finds the compiler beside itself, in the same `tiko-lang` folder, or on your `PATH`; if it
cannot, it asks for it once, when it starts.

### Building and running

| Key | What it does |
|---|---|
| `F5` | Build, then run |
| `Ctrl+F5` | Build only |
| `Shift+F5` | Run the last build |
| `Ctrl+Alt+F5` | Rebuild everything |
| `Ctrl+Shift+F5` | Set the arguments the program is run with |
| `F7` | Choose a build configuration: *Debug* (`-g -exx`, the default) or *Release* (`-O2`) |
| `Alt+PgDn` / `Alt+PgUp` | Go to the next or previous error |

What `F5` builds depends on what you have open. With a project — a folder with a `tiko.toml`,
opened by opening that file — it builds the project's target, as `tiko build` would. Without
one, it builds the file you are editing. Modified source files are saved first.

When the build fails, the compiler's errors open in the output pane at the bottom of the window,
each with its `TKOnnnn` identifier, and are underlined in the source; `Alt+PgDn` takes you from
one to the next. A console program runs in a terminal of its own, which waits for a key when the
program ends, so its output stays on the screen.

### Debugging

tkEdit can stop your program on a line and show you its variables. It does this through
**lldb-dap**, the LLVM debugger that editors talk to, reading the DWARF debug information that
`-g` writes — the same information Chapter 19 reads with lldb from a terminal.

| Key | What it does |
|---|---|
| `F9` | Set or remove a breakpoint on the cursor's line |
| `F6` | Build for debugging and start; in a session, continue to the next stop |
| `F10` | Step over: the next line, running any call on this one to its end |
| `F11` | Step into: the next line, inside a procedure this one calls |
| `Shift+F11` | Step out: run until the current procedure returns |
| `Ctrl+F10` | Run to the cursor's line |
| `Ctrl+F6` | Break: stop the running program where it is |
| `Shift+F6` | Stop debugging; the program ends |
| `Ctrl+Shift+F9` | Remove every breakpoint |

The same commands are on the **Debug** menu, after **Build**.

A breakpoint is a red circle in the margin. `F9` sets it; a click in the margin sets a bookmark
instead, unless the setting `margin_click = "breakpoint"` is in the `[editor]` table of
`settings.toml`. Breakpoints are kept with the session, so they are still there tomorrow.

`F6` builds with your configuration's options, without its `-O` and with `-g -exx` added, because
an optimised program has lost the variables you want to look at. Then it runs the program in its
terminal, as `F5` does, and stops on the first breakpoint it reaches — or, with no breakpoint set,
on the program's first statement. A yellow arrow in the margin marks the line about to run, and the
output pane opens on its **Debug** tab:

- The buttons along the top are the commands in the table: Continue, Break, Stop, Step, Step
  Over, Step Out, Run to Cursor. The status line at the bottom of the window says why the
  program stopped and where — `Stopped - breakpoint  rect.tiko:10  in Area`.
- **Locals**, **Globals** and **Watch** share the left side, with their tabs along its bottom.
  Each variable has a row: its name, its value and its type. A record opens to its fields and an
  array to its elements, named the way the program names them — `rs(1)`, `rs(2)`, `rs(3)` for an
  array declared `rs( 1 to 3 )`. A large array opens in groups of a hundred elements first. A value
  that changed since the last stop is shown in red, and what you opened stays open as you step.
  A click on a column heading sorts by it.
- **Call Stack** and **Breakpoints** share the right side. A click on a frame of the call stack
  shows that procedure's locals and goes to its line. The Breakpoints list has every breakpoint
  in every open file, with the text of its line; a double click goes to it. Of the two buttons at
  the end of its tab row, the first removes the selected breakpoint and the second removes them
  all.

On the Watch tab, the `+` button adds a row; type a name to watch, written as in the program —
`r.w`, `rs(2).sensor`, in any case — and press `Enter`. Its value is read again at every stop.
A double click on the row edits it, and emptying it removes it.
A watch is a variable, a field or an element, not a calculation: `r.w * 2` shows
`<not in scope>`, as does a name the stopped procedure cannot see.

While the program is stopped, rest the mouse on a name in the source and its value appears
beside it.

````admonish info title="Before the first session"
tkEdit looks for lldb-dap on your `PATH`, then where LLVM installs it. If it cannot find one, it
says so in the status line; set its path as `adapter` in the `[debug]` table of `settings.toml`.

- **Windows:** lldb-dap is in LLVM's `bin` folder, beside clang. It needs a 64-bit Python on the
  `PATH`: any **Python 3** for LLVM 23 (it loads `python3.dll`), **Python 3.10** for LLVM 21
  (`python310.dll`). tkEdit checks for the one your LLVM loads before it starts.
- **Linux:** install your distribution's `lldb` package, which provides `lldb-dap` or a
  numbered `lldb-dap-NN`; tkEdit takes the newest.
- **macOS:** lldb-dap comes with Apple's Command Line Tools. macOS lets one program control
  another only with **Developer Mode** on, or when you allow it in the dialog it shows. Turn it on
  once with

  ```
  sudo DevToolsSecurity -enable
  ```

  Without it, the status line says so, and no session starts.
````

### Finding your way

| Key | What it does |
|---|---|
| `F12` | Go to the declaration of the name under the cursor |
| `Alt+Left` / `Alt+Right` | Go back, or forward again |
| `Ctrl+P` | Search every file and declaration of the project by name |
| `Ctrl+Shift+P` | List the procedures of this file, or of every open file |
| `Ctrl+Shift+F` | Search the text of every project file |
| `Ctrl+E` | List the open files; `Ctrl+Tab` switches to the last one |
| `Ctrl+\` | Split the window; `Ctrl+Tilde` moves between the panes |

### Codetips and completion

Type `Area(` in `rect.tiko` and tkEdit shows the procedure's parameter list, read from its
declaration. Type `left(` and it shows `Left(string, n)`: the built-in procedures have codetips
too, square brackets marking the arguments you may leave out. Type `box.` and the members of
`Rect` are offered; type three letters of a name and the names that start with them are offered,
and after `as`, the types. `Ctrl+Space` completes a word at any time. The setting `codetips`
turns all of this off.

### Settings

tkEdit is configured with three text files, and saving one applies it:

| Key | File |
|---|---|
| `Ctrl+Comma` | `settings.toml` — fonts, tabs, the build, the language of the menus |
| `Ctrl+K` | `keybindings.toml` — every key in this section can be moved |
| `Ctrl+Shift+T` | the theme, light or dark |

## The language server

tiko-lsp speaks the **Language Server Protocol**, which most editors understand. The editor
starts it in the background and asks it questions — what is under the cursor, what could be
typed here, where is this declared — and it answers in terms of tiko. One server, so every editor
gets the same answers.

| Feature | What it does |
|---|---|
| Errors as you type | Underlines a mistake in the code's shape, such as an `if` with no `end if` |
| Completion | Variables, procedures and types in scope; fields after `.`; a module's exports after `strings.` |
| Hover | The declaration of the name under the mouse |
| Signature help | The parameter list while you type a call — built-ins included — with the current one marked |
| Go to definition | Across files, into `#include`d headers and `#import`ed modules |
| Find references, rename | Every use in the project; a rename it cannot do safely is refused, with the reason |
| Formatting | Re-indents a file; it never touches a file that has errors |
| Outline, workspace symbols | The procedures and types of a file, or of the whole project, by name |

### VS Code

1. In VS Code, open the Extensions view (`Ctrl+Shift+X`), search for **tiko** and install
   **Tiko**. VSCodium, Cursor and the other editors built on VS Code install it the same way,
   from their own Extensions view.
2. Open the folder your program is in, with *File > Open Folder*. The server reads the whole
   folder, so opening a single file gives you less.
3. Open `rect.tiko`. Hover `Area`; press `F12` on it; type `box.` on a new line and see `w` and
   `h` offered.

The extension carries its own copy of the server, for Windows, Linux on x86-64 and arm64, and macOS
on Apple silicon.

**Building and running.** Press `Ctrl+F5`, or click the ▶ button at the top right of the editor,
to run the program: the extension runs `tiko run` in VS Code's terminal, so the program can read
input. **Tiko: Build** builds without running; `Ctrl+Shift+B` offers the same build. As in tkEdit,
a `tiko.toml` at or above the file is built as a project, and otherwise the file itself is. The
compiler's errors go to the **Problems** view (`Ctrl+Shift+M`); click one to go to it.

**Finding the toolchain.** For the standard library and the system headers — `#import
"std/strings"`, `#include "windows.bi"` — the server needs the toolchain. It finds it by itself
if `tiko` is on your `PATH`, or if the `tiko-lang` folder is in your home folder or your
Downloads folder. Otherwise VS Code says so, once, with a **Locate Toolchain…** button: choose
the `tiko-lang` folder and the extension saves it as the setting `tiko.toolchainPath`. The
command **Tiko: Show Language Server Output** names the toolchain in use.

**Files.** `.tiko`, `.ti` and `.tko` files are tiko. The `.bas`, `.bi` and `.inc` extensions of
older tiko code are also used by other languages, so the extension leaves them alone until you
claim them, in the folder's `.vscode/settings.json`:

```jsonc
"files.associations": { "*.bas": "tiko", "*.bi": "tiko", "*.inc": "tiko" }
```

### Other editors

Zed, Neovim, Sublime Text, Helix and any other editor that speaks the protocol run the same
server, and every tiko release carries it beside the compiler:

| System | The server |
|---|---|
| Windows | `tiko-lang\tiko-lsp.exe` |
| Linux, macOS | `tiko-lang/bin/tiko-lsp` |

So if `tiko` is on your `PATH`, `tiko-lsp` is too. The tiko packages for Zed, Neovim and Sublime
Text find it there, or in the `tiko-lang` folder you name in their settings; the server then
takes the headers and packages of that same toolchain. Their instructions are in the
`editors` folder of the [tiko-lsp repository](https://github.com/PaulSquires/tiko-lsp). Any
other editor needs three things: the command `tiko-lsp --stdio`, the extensions `.tiko`, `.ti`
and `.tko` mapped to a language called `tiko`, and — if `tiko` is not on your `PATH` — the
toolchain folder as the option `toolchainPath`. For Helix, in `languages.toml`:

```toml
[language-server.tiko-lsp]
command = "tiko-lsp"
args = ["--stdio"]
config = { toolchainPath = "/home/you/tiko-lang" }

[[language]]
name = "tiko"
scope = "source.tiko"
file-types = ["tiko", "ti", "tko"]
roots = ["tiko.toml", ".git"]
comment-token = "'"
language-servers = ["tiko-lsp"]
```

### Updating

The server in your other editors is the one in the toolchain, so **installing a newer tiko
updates it**; restart the server, or the editor, afterwards. VS Code updates its extension, and
the server inside it, by itself.

### When something is wrong

- **No colour, no completion.** The editor has not recognised the file as tiko. In VS Code, the
  language mode at the bottom right should say *Tiko*. If VS Code shows *Restricted Mode*, the
  folder is not trusted, and the extension does not start a program in an untrusted folder.
- **`std/` and `windows.bi` names do not complete.** The server has not found the toolchain.
  Name the `tiko-lang` folder (in VS Code, with **Tiko: Locate Toolchain…**) and restart the
  server.
- **An underline on code that compiles.** That is a defect in the server. Report it at the
  tiko-lsp repository with the smallest program that shows it.
- **You want to see what the server is doing.** Start it with `--log-level debug --log-file`
  and a path; it writes nothing else to disk. `tiko-lsp --version` names the version you have.

## A clean editor is not a clean build

````admonish danger title="Pitfall"
This file is complete. Every block is closed, every statement ends where it should, and neither
tkEdit nor the language server underlines anything in it:

```tiko
{{#include ../examples/ch02/typo.tiko}}
```

It does not compile:

```
typo.tiko(6,7): error TKO0743: 'totl' is not declared
     |
   6 | print totl
     |       ^
```

The editor reads the code's shape; whether `totl` names anything is a question for the compiler.
A file with no underline has not been checked the way a build checks it. Build before you
believe it — `F5` in tkEdit, `Ctrl+F5` in VS Code — and read the errors that come back.
````

## What it costs

- **The first look at a large header takes seconds.** `windows.bi` and what it includes declare
  about 190,000 names. The server reads them once, in the background, when a project uses them;
  after that, completion costs tens of milliseconds a keystroke instead of a few.
- **The reader does not run the preprocessor.** Both branches of an `#ifdef` are read, so
  completion offers `MessageBoxA` and `MessageBoxW` alike, and a name made by `#define` is not
  offered at all.
- **Rename works by name.** It follows what each file can see, and refuses where a local
  variable shares the name it would change, but two unrelated declarations with one name in files
  that see each other are one name to it.
- **Codetips for the built-ins are a fixed list,** shipped with the tools; a procedure you
  declare is described by its own declaration instead, and wins over a built-in of the same name.

## Summary

- tkEdit and tiko-lsp read your code as you type, without compiling it. They catch mistakes in
  its shape; the compiler catches the rest, when you build.
- tkEdit comes with tiko (`tiko-lang/tkedit`). `F5` builds and runs — a `tiko.toml` project, or
  else the current file — and `Alt+PgDn` walks the compiler's errors.
- `F12` goes to a declaration, `Ctrl+P` finds any name, codetips show parameters as you type, and
  three TOML files hold every setting.
- tiko-lsp gives any editor that speaks the Language Server Protocol completion, hover, signature
  help, go to definition, references, rename, formatting and errors as you type.
- In VS Code, install the **Tiko** extension: it carries the server, runs your program with
  `Ctrl+F5`, and puts the compiler's errors in **Problems**.
- Every tiko release carries `tiko-lsp` beside the compiler, for every other editor; a newer tiko
  updates it.
- `F9` sets a breakpoint and `F6` runs to it; `F10`, `F11` and `Shift+F11` step. The Debug tab shows
  locals, globals and watches beside the call stack and the breakpoints. It needs lldb-dap, and on
  macOS Developer Mode.
- **No underline is not a successful build.** Build, and read what the compiler says.

## Exercises

1. Open `rect.tiko` in tkEdit and run it with `F5`. Delete the line `end function`, build again,
   and use `Alt+PgDn` to reach the error. Which line does it point at, and why that one?
2. In tkEdit, put the cursor on `Area` in the last line, go to its declaration with `F12`, and
   come back with `Alt+Left`. Then, in an editor with the language server, rename `Rect` to
   `Box2` (in VS Code, `F2`), and check that the declaration and the `dim` changed together.
3. In an editor with the language server, start typing `print mid(` and watch the parameter
   list. Type an argument and a comma at a time: which parameter is marked after each comma, and
   what happens after the third?
4. Copy `typo.tiko` into your editor. Find out, without building, which tool would tell you about
   `totl`, then build and compare the identifier you get with the one in this chapter.
5. In tkEdit, set a breakpoint on line 10 of `rect.tiko` (`return r.w * r.h`) and press `F6`.
   Open `r` on the Locals tab. Then select the second row of the Call Stack: what does Locals
   show now, and where is the editor's cursor? Step out with `Shift+F11` and watch the arrow.
