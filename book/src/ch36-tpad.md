# Capstone: a Notepad for Windows

The other capstones run in a terminal. This one has windows. **`tpad`** is a plain-text editor in
the shape of the Notepad that comes with Windows: a menu bar, a page of text, a status bar, the
usual keys, and a question before it throws away unsaved work.

It is built from **PsControls**, the vendor package of owner-drawn Windows controls that comes with
the toolchain, and from **PsApp**, the small framework in the same package that runs the message
loop, the theme and the DPI scaling. With those doing the work Windows usually asks of a program,
`tpad` is about 800 lines, a sixth of them its self-test, and much of the rest is about text
files rather than windows. It joins:

- modules and a package (Chapter 15), with the part that needs no window kept apart from the part
  that does;
- procedure pointers and lambdas (Chapters 7 and 21), which is how every control reports back;
- `new` and `delete` for state that lives as long as a window (Chapter 11);
- files, text encodings and atomic writes through `std/fs` (Chapters 9 and 25);
- a C API — Windows itself — called directly where no wrapper is needed (Chapter 29);
- the GUI subsystem, resources and build profiles (Chapter 31).

This is not a Windows programming primer. Where a Win32 call appears, the text says in a sentence
what it does and moves on.

```admonish info title="On Linux and macOS"
The window is Windows-only: PsControls draws with GDI and GDI+. The text-file module and its test,
`filetest`, compile and run on Linux and macOS like every other listing, and so do the exercise
solutions.
```

![tpad with a short file open, in the dark theme.](img/ch36-tpad.png)

## The specification

```text
tpad [file]
tpad --selftest
```

- **One window**: a menu bar, the text, a vertical scroll bar beside it, and a status bar.
- **File**: New (Ctrl+N), Open (Ctrl+O), Save (Ctrl+S), Save As (Ctrl+Shift+S), Exit. **Edit**: Undo,
  Cut, Copy, Paste and Select All, on their usual keys; Find (Ctrl+F) and Find Next (F3).
- **Text is UTF-8.** A file keeps the line ending it was written with, CR LF or LF, and its
  byte-order mark if it had one, when it is saved. A file with no line break is saved with CR LF.
  A file that is not UTF-8 opens with U+FFFD in place of what could not be read, and `tpad` says
  so.
- **The status bar** shows the caret's line and column, the line ending, and the encoding.
- **The title bar** shows the file's name, with a `*` in front while there are unsaved changes.
- **Before anything throws away unsaved text** — New, Open, closing the window — `tpad` asks: Save,
  Don't Save, or Cancel.
- **Find** ignores case unless asked not to, and wraps around from the end to the top.
- The window follows Windows' light or dark setting, and the DPI of the monitor it is on.
- **`--selftest`** drives the window with nobody at it, prints what happened, and exits.

## The layout

```text
ch36/
    tiko.toml               the package, and the target tpad with its resources
    tpad.rc, tpad.manifest  the manifest, compiled into the program
    textfile/textfile.tiko  the document: load, save, find, line and column
    pad/pad.tiko            the window: controls, menus, commands
    tpad.tiko               the program, and its self-test
    filetest.tiko           textfile on its own, on every target
```

The rule is the one from Chapter 33: **the part that does not need a window does not import one.**
Everything `tpad` knows about text files is in `textfile`, which imports `std/fs` and
`std/strings` and nothing from Windows. It can be tested on every target, by a program that prints,
and it could serve a Linux editor unchanged. `pad` is the window, and `tpad.tiko` starts it.

## The document

```tiko
{{#include ../examples/ch36/textfile/textfile.tiko:head}}
```

```tiko
{{#include ../examples/ch36/textfile/textfile.tiko:model}}
```

A `Document` is what was read from the file, and what is needed to write it back the same way:
its path, its text, its line ending, and whether it began with a byte-order mark. `lossy` records
that some of its bytes could not be read. (The module is `textfile` and not `document` because a
module may not export a name it shares, in any case, with its own:
`TKO0870: public 'document' has the same name as its module 'document'`.)

The comment on `text` is the most important line in the module. **Inside a `Document`, a line
break is one character, LF.** The editor control counts a line break as one character too, so an
offset into `text` and an offset into the control are the same number, and a match found in one
can be selected in the other. `ToLf` makes that true of any text, whatever its line breaks:

```tiko
{{#include ../examples/ch36/textfile/textfile.tiko:tolf}}
```

````admonish danger title="Pitfall"
The text control does not hand its text back in the form it counts it. Measured with a
multiline `PsTextBox` holding `ab`, CR LF, `cd`, LF, `ef`:

```text
PsTextBox_GetText          10 characters: every line break comes back as CR LF
PsTextBox_SetSel( 0, -1 )  selects 0 to 8: every line break counts as one
```

Search the text `GetText` returns and select what you found, and the selection lands one
character early for every line above the match — right on the first line, wrong everywhere
else. Convert with `ToLf` first, as `pad` does in its one function that reads the control's text.
````

### Loading

```tiko
{{#include ../examples/ch36/textfile/textfile.tiko:load}}
```

`fs.ReadAllText` does most of the work, and two things it does decide the rest of the function:

- **It removes a byte-order mark**, UTF-8's or UTF-16's, and decodes what follows. That is what a
  program reading text wants, but an editor must write the mark back, so `StartsWithBom` opens the
  file and reads its first three bytes itself.
- **It replaces bytes that are not UTF-8 with U+FFFD**, the replacement character, on both
  targets. A file in an old 8-bit encoding opens, but its accented letters are gone from the
  text, and saving writes the replacement characters. `Load` records that in `lossy`, and the
  window warns before anyone edits the file.

The line ending is the file's first one: an LF with a CR before it means CR LF. A file that mixes
the two is saved with the first kind throughout. `Load` fills a local `Document` and copies it to
`doc` only when everything has worked, so a failed open leaves the document that was there.

````admonish danger title="Pitfall"
`fs.ReadAllBytes` has a three-argument form, and it is not "read the first *n* bytes". The third
argument is a **limit**: a file larger than it is refused with an error, and nothing is read.

```tiko
fs.ReadAllBytes( p, head, 3 )    '' fails on any file over 3 bytes
```

The first draft of `StartsWithBom` was that line. It compiled, every file was "too large", the
function returned `false`, and the byte-order mark was quietly dropped on every save.
`filetest` caught it: its first file has a mark. Read a prefix with a `File` and `Read`, as the
listing does.
````

### Saving

```tiko
{{#include ../examples/ch36/textfile/textfile.tiko:save}}
```

`Save` undoes what `Load` did: LF back to CR LF if that is how the file was written, and the mark
back on the front. The mark is the character U+FEFF, which UTF-8 writes as the three bytes
`EF BB BF`. **`fs.WriteAtomic`** writes a temporary file beside the real one and renames it into
place only when the write is complete (Chapter 25), so a full disk or a crash in the middle of a
save leaves the old file whole, never half of the new one.

### Names, finding, line and column

```tiko
{{#include ../examples/ch36/textfile/textfile.tiko:names}}
```

```tiko
{{#include ../examples/ch36/textfile/textfile.tiko:find}}
```

`FindNext` takes and returns offsets counted from 0, as the control's selection is, and converts at
its edges: `instr` counts from 1. It searches from `start` to the end, then from the top, so a
search always wraps around once. Without match case, it lowers the case of both strings and
searches the copies; that keeps the offsets right, because `lcase` changes no string's length.

```tiko
{{#include ../examples/ch36/textfile/textfile.tiko:linecol}}
```

### Testing it on every target

```tiko
{{#include ../examples/ch36/filetest.tiko}}
```

```text
{{#include ../examples/ch36/filetest.out}}
```

The test writes its files byte by byte, so that what it reads does not depend on how this source
file's own line endings were checked out. The Windows file keeps its mark and its CR LF through a
load, an edit and a save. The Latin-1 file opens with LF, as `lossy`, with U+FFFD where the
e-acute was. A file that is not there is refused, and `doc` still holds the file before it.

## The window

### An application and a form

```tiko
{{#include ../examples/ch36/pad/pad.tiko:head}}
```

Each control is a module of its own, and a program imports the ones it uses and links only those.
`using` makes their names bare, so a call is `PsTextBox_SetText`, as the package's documentation
writes it, rather than `PsTextBox.PsTextBox_SetText`. `gui` is `sys/win/gui`, which PsApp imports
for the program, and which holds the file dialogs.

PsApp supplies two types. A **`PsApplication`** is the program: its `Init` sets up COM, GDI+, the
DPI awareness and the theme, and its `Run` is the message loop, which runs until the main window
closes. A **`PsForm`** is a window. It reports what happens to it through procedure pointers set
by `OnSize`, `OnClose`, `OnCommand` and the rest, each of which receives the form first; a
message with no handler gets Windows' default behaviour.

```tiko
{{#include ../examples/ch36/pad/pad.tiko:state}}
```

`Editor` is everything `tpad` keeps about one window, and **the form holds a pointer to it in its
`Tag`**. That is the answer to a question every callback raises. A control's callback receives the
control's window handle and nothing else; `PsForm.FromHwnd` finds the form that handle is on, and
the form's `Tag` finds the `Editor`. `EditorOf` does both. So no part of the program needs a
`dim shared` variable, and a second `tpad` window would be a second `Editor` with nothing shared.

`Cmd` names every command once. A menu item, a key and the self-test all end up passing one of
these numbers to the same procedure.

The last two fields are the subject of a later section. **`ask` and `pick` are the two places a
person answers `tpad`** — a question in a message box, and a file name in a file dialog. Both are
procedure pointers, and `Create` points them at the real thing:

```tiko
{{#include ../examples/ch36/pad/pad.tiko:people}}
```

`PsMessageBox_Show` puts up a themed message box and waits for an answer. Its button sets are
named presets; `MBX_BTN_SAVE_DONTSAVE_CANCEL` returns `IDYES`, `IDNO` or `IDCANCEL`, because Windows
has no "Save" result and a save question is a yes-no-cancel question with better captions.
`CISaveFileDialog` and `CIOpenFileDialog` are the Windows file dialogs, from `sys/win/gui`, and
`SIGDN_FILESYSPATH` asks for the result as an ordinary path.

### The text and its scroll bar

```tiko
{{#include ../examples/ch36/pad/pad.tiko:text}}
```

The third argument to `PsTextBox_Create` makes a **multiline** box: Enter starts a new line, Tab
inserts a tab, and long lines wrap. `f->Font( PSFONT_MONO )` is the form's monospaced font,
Cascadia Mono where it is installed and Consolas where it is not. The text limit is raised from
the control's default to nearly 2^31 characters.

Four callbacks, each a lambda, connect the box to the rest of the window:

- **The change callback** fires when *the person* changes the text: typing, cutting, pasting,
  undoing. It never fires for `PsTextBox_SetText`. Every PsControls setter is silent in the same
  way, so a program can set a control's value inside its own handler without being called back
  in the middle of it. `tpad` relies on that when it loads a file.
- **The message callback** sees the box's keyboard and mouse messages *before* the box acts on
  them. A key that moves the caret has not moved it yet, so reading the caret position here gives
  the old one. Instead the callback posts `WM_CARETMOVED` to the form: a posted message waits in the
  queue until the current one is finished, by which time the caret has moved, and the form's
  handler for it updates the status bar. `false` lets the box handle the message as usual.
- **The scroll callbacks** connect the box to a `PsVScrollBar`. The box draws no scroll bar of its
  own. It reports its line count, page size and top line whenever they may have changed, and the
  scroll bar reports a new position when it is dragged.

### The status bar

```tiko
{{#include ../examples/ch36/pad/pad.tiko:status}}
```

`PsStatusBar` lays its panels out: each is as wide as its text, and `SetExpandPanel` makes the
first one take the space left over. **It does not draw what is in a panel.** That is the paint
callback's job, and without one the bar is a blank strip. This one paints in the theme's colours,
which it asks the application for each time, so a switch between light and dark needs nothing
more.

```tiko
{{#include ../examples/ch36/pad/pad.tiko:refresh}}
```

`TextOf` is the one place `pad` reads the control's text, and it converts to the one-LF form at
once. `ShowTitle` reads the box's **modified flag**, which the control sets on every edit the
person makes and `pad` clears after a load or a save. `ShowStatus` takes the end of the selection
as the caret, and lets `textfile` count lines.

### Layout

```tiko
{{#include ../examples/ch36/pad/pad.tiko:layout}}
```

PsControls are created **hidden and zero-sized**. Nothing is on screen until the form's size
handler places each one and shows it; `SWP_SHOWWINDOW` in `SetWindowPos` does both at once. The
handler runs whenever the window's size changes, including the first time it is shown. Every
literal is passed through `ScaleX` or `ScaleY`, which turn device-independent units into pixels
at the form's DPI. Thirty units is thirty pixels on an ordinary monitor and sixty on one at 200%.

### Menus and keys

```tiko
{{#include ../examples/ch36/pad/pad.tiko:menus}}
```

A `PsMenuBar` holds the titles; each title drops down a `PsPopupMenu`. The text after an item —
`"Ctrl+N"` — is only shown. What makes the key work is the **accelerator table**: `AddAccelerator`
maps a key and its modifiers to a command number, and the message loop turns the key into a
`WM_COMMAND` for the form before the text box sees it. The form's command callback hands any `Cmd`
to `Execute`, and returns `false` for anything else so that it gets the default handling.

The edit keys are left out of the table on purpose. The text control already handles Ctrl+Z, X,
C, V and A, wherever the keyboard focus is in it; an accelerator would take the key away from it.

### Commands

```tiko
{{#include ../examples/ch36/pad/pad.tiko:commands}}
```

**One procedure carries out every command**, whether it came from a menu, a key or the self-test.
The menus and the keys say *which* command; `Execute` says *what* it does. Adding a command means
adding a `Cmd`, an item, perhaps a key, and a `case`.

### Files, and the question before discarding

```tiko
{{#include ../examples/ch36/pad/pad.tiko:files}}
```

`MayDiscard` is the specification's question, in one place. New and Open call it before they
replace the text, and the form's close handler, below, calls it before the window goes. **Save**
in the answer saves, and continues only if the save worked: a save that is cancelled at the file
dialog, or fails, keeps the window and its text.

`SaveDocument` reads the text out of the control into the document, saves, and clears the modified
flag only after `textfile.Save` reports success. An error from either module comes back as text,
and goes to the person as a message box with an OK button.

### Find

```tiko
{{#include ../examples/ch36/pad/pad.tiko:finding}}
```

The Find box is a **modal** form. `ShowModal` disables the main window, runs the message loop
until the box ends it, enables the main window again, destroys the box and returns the code passed
to `EndModal`. Esc and the close box end it with `IDCANCEL`. The box only collects what to look
for, into the `Editor` its `Tag` points at; `FindAgain` does the searching, so F3 can repeat a
search without the box. A match is selected and `EM_SCROLLCARET` scrolls it into view. That is a
classic edit-control message, and a `PsTextBox` passes such messages to its edit control unchanged.

### Creating it all

```tiko
{{#include ../examples/ch36/pad/pad.tiko:create}}
```

`Create` allocates the `Editor` with `new`, because it must outlive the call: it lives exactly as
long as the window, and the form's destroy handler deletes it. The close handler is the
specification's question again; returning `false` from it cancels the close, so Cancel keeps the
window open. The DPI handler is the subject of this chapter's last pitfall:

````admonish danger title="Pitfall"
When a form moves to a monitor with a different DPI, PsApp re-creates its fonts at the new size
and **gives every control the form's UI font** — including a control that was given another font.
Without the DPI handler, `tpad`'s text turns from Cascadia Mono into Segoe UI the first time the
window is dragged to a monitor at another scale, and nothing else changes. The self-test below
checks it, by sending the form the message Windows sends:

```text
== moved to a monitor at twice the DPI
  the text is still monospaced: true
```

With the handler's one line commented out, that line reads `false`.
````

## The program

```tiko
{{#include ../examples/ch36/tpad.tiko:head}}
```

```tiko
{{#include ../examples/ch36/tpad.tiko:main}}
```

`#cmdline "-s gui"` builds for the GUI subsystem (Chapter 31), so starting `tpad` from Explorer
opens no console window. `app.Run` shows the main window and runs the message loop until the window
is destroyed, and its result is the program's exit code. A file named on the command line is
opened before the loop starts; if it cannot be, the person is told and gets an empty window.

The package's `tiko.toml` names the program and its resources:

```toml
{{#include ../examples/ch36/tiko.toml}}
```

`UNICODE` is defined for the whole build, as the PsControls package requires: it makes every bare
Win32 name, such as `SetWindowText` or `MessageBox`, mean the function that takes UTF-16 text.
The manifest that `tpad.rc` compiles in declares per-monitor DPI awareness and asks for version 6
of the Windows common controls.

## Testing a window with nobody at it

The harness that checks this book's listings runs every program and compares its output with what
the book prints. A window waits for a person. So `tpad` takes `--selftest`, which **drives the real
window — the real controls, the real callbacks, the real `Execute` — and prints what it saw**.

The only things it cannot drive are the two that wait for a person: the message box and the file
dialog. That is why they are behind `ask` and `pick`. The test points them at a script:

```tiko
{{#include ../examples/ch36/tpad.tiko:script}}
```

```tiko
{{#include ../examples/ch36/tpad.tiko:drive}}
```

`Press` and `Type_` send the text control's own edit window the messages the keyboard would:
`WM_KEYDOWN` for a key that moves, `WM_CHAR` for a character. They take the same path a key takes,
through the message callback and the change callback. `Pump` then delivers whatever was posted,
which is how `WM_CARETMOVED` reaches the form; the self-test runs before `app.Run`, so there is no
message loop doing it.

```tiko
{{#include ../examples/ch36/tpad.tiko:test}}
```

```text
{{#include ../examples/ch36/tpad.out}}
```

The window is never shown. The test sizes it first, and that matters twice over. A key sent to a
zero-sized text box is accepted and does nothing: in the first draft, which sent its keys before
sizing the window, Down and Down left the caret on line 1. And the layout itself is checked by
comparing edges, which is the same at any DPI, rather than pixel counts, which are not.

```admonish note
`Report` copies the title from a `wstring` buffer into a `ustring` before printing it. That is
not tidiness. Printed to a pipe or a file — and the harness reads a pipe — a `wstring` is written
as its raw UTF-16 code units, a zero byte after every ASCII letter, while a `ustring` is written as
UTF-8. On a console the two print the same, which is why the difference shows up only when the
output is redirected.
```

### What the self-test cannot see

The first version of `tpad` had no status-bar paint callback. Its self-test passed: `Report`
reads each panel's text back with `PsStatusBar_GetText`, and the text was right. On screen the
panels were empty, because nothing painted them. **A test that reads the model does not see
pixels.** The status bar was caught by looking at the window, and the screenshot at the top of
this chapter is the check that it now paints. What the self-test proves is that the commands, the
callbacks and the files behave; that the window *looks* right is still a matter of looking at it.

## Running it

From the chapter's directory:

```text
tiko build tpad
out/debug/tpad.exe notes.txt
```

`tiko build tpad` builds the target `tpad` with the `debug` profile into `out/debug`;
`tiko run -- notes.txt` builds and starts it in one step. The first build compiles every PsControls module
the program imports, and takes a few minutes. After that, a change to `tpad`'s own files is
rebuilt in under half a minute.

## Shipping

`tiko build tpad --profile release` builds an optimised `out/release/tpad.exe` of 316,416 bytes.
It imports only libraries that come with Windows: `KERNEL32`, `USER32`, `GDI32`, `gdiplus`,
`COMCTL32`, `ole32`, `ADVAPI32`, `VERSION`, `dwmapi` and the C runtime `ucrtbase`. There is no
installer and no runtime to install. Copy the file, and it runs.

The debug build is ten times the size, 3,101,696 bytes, because it carries `-exx`'s checks and the
debugger's information (Chapter 31). Ship the release build.

## What it costs

- **Every caret move reads the whole text.** `ShowStatus` copies the text out of the control,
  converts its line breaks and counts lines up to the caret. Measured on a 1 MB file, in a release
  build: about 16 ms per update, of which 7 ms is `PsTextBox_GetText` alone. A notes file costs
  nothing; a 10 MB log would make the caret lag. The cheaper way asks the control for the line
  with `EM_EXLINEFROMCHAR` and `EM_LINEINDEX`, but those count lines as they are *displayed*,
  wrapped, and the status bar wants lines as they are in the file.
- **The text always wraps.** A multiline `PsTextBox` wraps long lines and has no horizontal
  scroll bar, so Notepad's Word Wrap switch has nothing to switch.
- **The whole file is in memory**, twice while it is saved: once in the control and once in the
  document being written.
- **Text that is not UTF-8 is not preserved.** `tpad` warns, and saving writes U+FFFD where the
  unreadable bytes were. Keeping them would mean reading the file in its own encoding, which
  needs the encoding to be known or guessed.
- **A self-test is code in the shipped program.** It is a few dozen lines that do nothing unless
  asked, and the price buys a window that is checked on every build.

## Summary

- Keep the part of a program that needs no window in a module that imports none. `textfile` is
  tested on Windows, Linux and macOS by a program that prints; only `pad` needs Windows.
- Give text one line-break convention inside the program — one LF, counted as one character — and
  convert at the edges: `ToLf` on the way in from the file and from the control, the file's own
  ending on the way out.
- `fs.ReadAllText` removes a byte-order mark and replaces bytes that are not UTF-8 with U+FFFD.
  An editor that must write a file back the same way reads the mark itself. `fs.ReadAllBytes`'s
  third argument is a size limit, not a prefix length.
- Save with `fs.WriteAtomic`, so a failed save leaves the old file whole.
- `PsApplication` is the program and its message loop; a `PsForm` is a window that reports through
  procedure pointers. Keep per-window state in a `new`ed type that the form's `Tag` points at, and
  reach it from any control's callback with `PsForm.FromHwnd`.
- PsControls setters are silent: only a person's actions call back. Read the caret after a key by
  posting a message to yourself, and give a `PsStatusBar` a paint callback or its panels stay
  blank.
- Controls are created hidden and zero-sized. Place them in `OnSize`, scale every literal with
  `ScaleX`/`ScaleY`, and set your own fonts again in `OnDpiChanged`.
- Route menus, keys and tests to one `Execute`. Put the accelerator keys the text control does not
  handle itself in the form's table.
- Ask the person in one place, before anything is thrown away, and wire the close handler to it.
- Put the person behind procedure pointers, and a test can drive the real window: send the
  control the messages the keyboard would, pump the queue, and print what changed. Then look at
  the window as well.

## Exercises

1. Add Find Previous (Shift+F3) to `textfile` and to the Edit menu: the last match that ends at or
   before the start of the selection, wrapping around to the bottom. {solution="ex36-01"}
2. Show a word count in a fourth status-bar panel. Write the counting function in `textfile`, so
   that it can be tested on every target. {solution="ex36-02"}
3. Add Replace (Ctrl+H): a modal box with *Find what*, *Replace with*, Replace and Replace All.
   Do the replacing in `textfile`, so that it can be tested on every target.
4. Add Time/Date (F5), which inserts the local date and time at the caret, with `std/chrono`.
5. Open a file dropped on the window from Explorer. `DragAcceptFiles` turns dropping on, the form
   receives `WM_DROPFILES` (`OnMessage`), and `DragQueryFileW` gives the path. Ask `MayDiscard`
   first.
6. Extend the self-test to Save As: point `pick` at a new name, and check the title and the file
   on disk afterwards.
