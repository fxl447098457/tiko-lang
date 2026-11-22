# tpad on tkControls

The program of the wiki's [Notepad Tutorial](https://github.com/PaulSquires/tiko-lang/wiki/Notepad2-Tutorial):
a plain-text editor on tkControls, with one `Editor`, its commands and the one `Execute`. It
runs on Windows, **Linux and macOS**.

```text
examples/tkControls/tpad/
    tiko.toml               the package (vendor/tkControls comes with the toolchain)
    textfile/textfile.tiko  the document: lines, Find, load and save; no window
    offsets/offsets.tiko    UTF-8 bytes (tkTextBox) and UTF-16 units (ustring)
    pad/pad.tiko            the window, on tkApp + tk controls
    tpad.tiko               the program, and its self-test
    expected.txt            what the self-test prints
```

## Result

`tpad --selftest` drives the real window and prints what it saw. Its output matches
`expected.txt` byte for byte on:
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
