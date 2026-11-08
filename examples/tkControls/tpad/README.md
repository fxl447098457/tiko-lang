# tpad on tkControls

The wiki's [Notepad Tutorial](https://github.com/PaulSquires/tiko-lang/wiki/Notepad-Tutorial)
(the book's Chapter 35), rebuilt on tkControls instead of PsControls. It has the same three
files, the same `Editor`, the same commands and the one `Execute`. It now runs on Windows,
**Linux and macOS**.

```text
examples/tkControls/tpad/
    tiko.toml               the package (vendor/tkControls comes with the toolchain)
    textfile/textfile.tiko  the document -- UNCHANGED from the wiki
    offsets/offsets.tiko    UTF-8 bytes (tkTextBox) and UTF-16 units (ustring)
    pad/pad.tiko            the window, on tkApp + tk controls
    tpad.tiko               the program, and its self-test
    expected.txt            what the self-test prints
```

## Result

`tpad --selftest` drives the real window and prints what it saw. Its output matches
`expected.txt` byte for byte, and its first 36 lines are the PsControls Notepad Tutorial's, on:
- Windows (D3D11);
- Linux X11;
- Linux Wayland (WSLg);
- macOS on Apple Silicon (Metal, Homebrew SDL3).

The command keys are Cmd on macOS and Ctrl elsewhere (`TK_KMOD_PRIMARY`), and the menus
say which. The self-test presses no modifier, so that choice is not in its output.

The output covers the layout, Open, the keys and typing, Find Next (including the "Cannot
find" question), Save and the bytes on disk, the Save / Don't Save / Cancel questions, the
scale change, Find in text that is not ASCII, closing the window while a file dialog is up,
the system's Quit, and the close.

**A/B check:** making `MayDiscard` stop asking drops its questions from the output, and
the diff shows it. Reverted.

**Screenshots:** `tpad --shot out.bmp file` renders at a pinned 1.75 in the dark theme.
Windows vs Wayland: 2.10% of pixels differ.
- Nearly all of the differences are 1–2 levels of anti-aliasing, as in every other demo.
- 200 pixels differ by up to 47 levels. All of them are the straight double quote `"` in
  Cascadia Mono: the Windows and Linux SDL3_ttf builds bundle different FreeType versions,
  and they rasterise that one glyph of the variable font differently.
- tpad is the first program to use the mono role; every other demo is Segoe UI only.

## What changed from the PsControls tpad

| Wiki (PsControls, Win32) | Here (tkControls, SDL3) |
| --- | --- |
| `PsApplication`, `PsForm`, `f->hWindow`, `f->Item( id )` | `tkApp_Init`, `TK_FORM`, `tkForm_Widget( f )`; the `Editor` keeps its widget pointers |
| `PsForm.FromHwnd( h )->Tag` | `tkForm_FromWidget( w )->Tag` |
| `PostMessage( WM_CARETMOVED )`, handled in `OnMessage` | `tkApp_RunOnUI( @CaretMoved, ed )`: the same "after the control has acted" |
| An accelerator table (Ctrl+N, O, S, Shift+S, F, F3) | `tkForm_OnKeyDown`. The text box handles Ctrl+Z / X / C / V / A and leaves every other key unclaimed, so tpad's keys bubble up to the form |
| `CISaveFileDialog` / `CIOpenFileDialog` | `SDL_ShowSaveFileDialog` / `SDL_ShowOpenFileDialog`. They are asynchronous, so `PickFile` pumps until the callback answers, and `picking` holds off commands and the close meanwhile |
| Selection offsets that match `ustring` units | UTF-8 byte offsets, converted by `offsets` |
| Closing the window | Closing the window, and `SDL_EVENT_QUIT` turned into a close by `QuitHook` |
| `SetWindowTextW` / `GetWindowTextW` | `SDL_SetWindowTitle` / `SDL_GetWindowTitle` (UTF-8, so the wiki's wstring-to-pipe warning is moot) |
| `EM_SCROLLCARET` after `SetSel` | Nothing: `tkTextBox_SetSel` scrolls the caret into view itself |
| A status bar paint callback (a PsStatusBar without one is blank) | None: tkStatusBar draws its panels itself |
| `OnDpiChanged` puts the mono font back | Nothing needed: a scale change re-sizes a control's fonts and never hands every control the UI font. The self-test still asserts the text stays monospaced |
| The Find box: a default button takes Enter | The search box's Enter callback is Find Next; Esc ends the modal form by itself |
| `IDYES` / `IDNO`, `MBX_BTN_*` | `MBX_IDYES` / `MBX_IDNO`, the same `MBX_BTN_*` |
| `tpad.rc` and a manifest | None: SDL3 handles DPI awareness |

The self-test answers through the same `ask` / `pick` pointers. It pushes SDL events
(`SDL_EVENT_KEY_DOWN`, `SDL_EVENT_TEXT_INPUT`) where the wiki sent `WM_KEYDOWN` / `WM_CHAR`.
The wiki sends `WM_DPICHANGED`; here the surface's scale is doubled and SDL's scale event is
pushed.

## Bugs found

- **tiko-lang, Linux and macOS (fixed):** importing `vendor/SDL3` (any tk module) *before*
  `std/fs` failed with "expected an identifier" at crt/stdio.bi's `#define SEEK_SET 0`:
  std/fs's interface replays sys/posix's binding, whose `const SEEK_SET = 0` the importer's
  crt macro turned into `const 0 = 0`. The binding now declares such a constant between
  `#pragma push_macro` and `pop_macro`, and the imports may come in any order.
- **Naming:** a local named `fb` collides with tiko's `FB` namespace (identifiers are
  case-insensitive), so the Find box's struct is `box`.

## Build and run

```bash
cd /c/dev/tkControls/examples/tpad
/c/dev/tiko-lang/toolchains/tiko-windows/tiko.exe build tpad
./tpad.exe notes.txt
./tpad.exe --selftest > got.txt && diff expected.txt got.txt
```

On Linux, build with `--options "-p /path/to/linux-lib"` and set `LD_LIBRARY_PATH` to the
same folder, as `tools/run-linux.sh` does.

## Not verified

- The real file dialogs: the self-test scripts `pick`.
- The real message box: the self-test scripts `ask`.
- The menus driven by the mouse.
- An interactive pass.
