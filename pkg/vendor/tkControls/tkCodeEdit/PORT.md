# tkCodeEdit: port notes (from PsPlatform's src/scintilla)

tkCodeEdit is a Scintilla 5.5.7 editor as a tkControls widget, built for tiko-studio. It has
no vendor PsControls twin: the source is PsPlatform's
Scintilla platform layer, which ran Scintilla on Blend2D + FreeType + HarfBuzz.

## Two halves

**scintk/** is C++, one shared library: Scintilla + Lexilla (LexTiko only, vendored from
PsPlatform `src/scintilla/vendor`) + `PlatTk.cxx` + `ScintillaTk.cxx`. It is built by `build.sh`
(clang++ on Windows with a static CRT, g++ on Linux with static libstdc++). Each library depends
only on the C runtime: KERNEL32 on Windows, libc/libm on Linux. Output goes to `scintk/bin/<os>/`,
which is not tracked; rebuild after a fresh clone.

**tkCodeEdit.tiko** is the host. It loads the library at run time with `SDL_LoadObject`, so a
program that never makes an editor never needs it. It registers the text and drawing tables
the library calls, and it is the widget.

## Name map

- `SciPs_*` → `SciTk_*`; `PsTeApi` → `TkTeApi`; `PlatPs_*` → `PlatTk_*`; `ScintillaPs` →
  `ScintillaTk`; `PsScintillaC.h` + `PsTextEngineC.h` → `scintk.h`.
- PsSciView → tkCodeEdit (widget); PsSciInput → `SciKey`/`SciMods` and the `CeProc` cases;
  PsSciClipboard → `CeClipGet`/`CeClipSet`; PsSciNotify → `CeNotify` + `TKCE_NOTIFICATION`.

## Kept verbatim

- PlatPs's Font (the resolver and fallback-chain seams), Window, ListBox, Menu and Platform.
- ScintillaPs's editor: the fine tickers, the host-owned clipboard and its undo-grouped paste,
  the notification POD and its copy, and the menu command translation.
- PsSciInput's rules:
  - keys are asked, not told;
  - text comes from text events, never from key events;
  - modifiers are translated one bit at a time;
  - three wheel lines a notch, with fractions accumulating;
  - Ctrl+wheel zooms and Shift+wheel scrolls sideways.
- PsTextEngine's rule that every byte of a cluster gets the cluster's end.

## Changed

- **The surface.** `SurfaceTk` forwards every primitive to a host `TkDrawApi` table: fill,
  frame, round rect, line, polyline, polygon, ellipse, gradient, RGBA image, pixmap
  create/copy/tile, clip push/pop. tkCodeEdit implements the table over SDL_Renderer. The C++
  side includes no SDL and no graphics library.
- **The view is a texture.** Scintilla paints into the widget's own render-target texture, and
  only when it invalidated or the size changed. Every frame then blits that texture in one call,
  so a caret blink costs one view re-render (~0.6 ms on D3D11), not a document relayout.
- **Pixmaps** are render-target textures. `SCI_SETBUFFEREDDRAW 0`: the view is already
  buffered, and per-line pixmaps would only add target switches.
- **Render state is set only on a change.** A clip or blend change splits SDL's draw batch, and
  on GL each split is a draw call. Setting both per primitive cost 18–25 ms a re-render under
  WSLg.
- **The cluster map** sums each codepoint's hinted advance plus kerning, every byte of the
  codepoint getting its end. SDL_ttf's `TTF_GetTextSubStringsForRange` is per run, not per
  cluster: every byte got the run's end. Its `TTF_GetTextSubString` rects are INK boxes, not
  the pen: Cascadia's `i` sits at x 9, w 6 inside an 8 px cell. Both were measured with a probe.
  The run width is the last position from the same walk, so measuring and drawing agree with
  `TTF_GetStringSize`; the selftest checks this.
- **Shaped runs are cached** (`gRuns`). The key is engine + font + colour + bytes; the cache is
  flushed whole at 8,192 entries, when a font closes and when an editor goes. Measured, 575
  runs a re-render: 1.2 ms → 0.3 ms on Windows, 14.6 ms → 0.3 ms under WSLg. SDL3_ttf shapes
  with HarfBuzz there, so the uncached cost was the shaping.
- **Text input is one codepoint per call.** That gives one `SCN_CHARADDED` per character, as
  ScintillaGTK commits IME strings; auto-indent and autocompletion count on it.
- **The editor is created 4096×4096** until its first `TKM_SIZE`. Otherwise a caret placed
  before layout scrolls the view sideways to fit a 100 px pane. The demo screenshot found this.
- `SciTk_Create(w, h)` without a font. `SciTk_SetFontPath`, `SciTk_SetDpi` and
  `SciTk_SetFontResolver` are exported separately.
- `SciTk_CreateLexer` exports Lexilla's `CreateLexer`, so there is no second library.
- `SciTk_Cursor` reports Scintilla's pointer per view; the host shows it.
- `SciTk_AbiVersion` and `SciTk_NotificationSize` are checked at load.
- On macOS, Cmd reaches Scintilla's key map as Ctrl (the Primary modifier).

## The rest of the editor (2026-10-25)

- **The autocompletion list** is Scintilla's ListBox model (scintk `SciTk_Lb*`) shown as a tkHost
  POPUP surface:
  - It is made per show, because Wayland fixes a popup's position at creation.
  - It is placed under the caret line, or above it when the display ends first
    (`tkHost_PlacePopup`).
  - It draws its rows itself, in the editor's font and the theme's popup / selection roles.
  - A click selects a row; a double click completes it; the wheel scrolls.
  - The popup takes the keyboard on Linux, so it FORWARDS keys, text and IME to its editor.
  - The editor ignores the focus loss its own popup causes (PsSciInput's g_sciAcOwner rule).
  - A close the host made (a press elsewhere, focus leaving the app) is told to Scintilla
    (`SCI_AUTOCCANCEL`).
- **The call tip** is a popup Scintilla paints itself.
  - `CreateCallTipWindow` names the tip's window after its CallTip and registers it with the
    editor's `SciTkCallTipHost`. Window's methods route show, hide and repaint to the host
    (PlatTk, a third kind of WindowID).
  - `GetClientPosition` answers from (0,0), which is what `CallTip::PaintCT` reads.
  - The host paints the tip with `SciTk_PaintCallTip` into a render-target texture of its own.
    Clicks go to `SciTk_CallTipClick`, which notifies `SCN_CALLTIPCLICK`.
- **The context menu** is Scintilla's own, built through `SciTkMenuHost` as a tkPopupMenu and
  raised on the right-button RELEASE. `tkCodeEdit_SetContextMenuCallback` replaces it with the
  host's.
- **IME** is ScintillaGTK's inline pre-edit, ported (`SciTk_ImeCompose`):
  - the composition is inserted TENTATIVELY with the IME indicator, replacing the last one;
  - the carets move to the input method's cursor;
  - the commit (`SciTk_TextInput`) undoes the tentative text first, so it lands once and leaves
    no undo step;
  - the candidate window goes under the caret (`SciTk_CaretRect` → `tkHost_SetTextInputArea`).
- **Faces.** `tkCodeEdit_SetFontFace( family, regular, bold, italic, boldItalic )` answers
  PlatTk's resolver; a file may be `path|face`, a face of a `.ttc`. The face is chosen by family
  name through `TTF_OpenFontWithProperties`. The wrong name FAILS rather than opening face 0
  (PlatPs's rule).
- **Fallbacks.** `tkCodeEdit_SetFallbackFonts` sets the chain; each font holds its fallback
  fonts, added once each.
  - `TeAdvance` measures a glyph the primary lacks from the fallback that has it, so measuring
    and drawing still agree.
  - CJK in Cascadia Mono now draws from MS Gothic. Its width equals `TTF_GetStringSize` with the
    same fallback (the oracle).
- **Per-editor DPI.** Each editor keeps its own DPI, set at create and on `TKM_SCALECHANGED`
  (`SciTk_SetEditorDpi`, which restyles). Every scintk entry point makes that editor's DPI the
  process value first, through `Use()`. `tkCodeEdit_SetScaleCallback` tells the host, whose
  margins are in pixels.
- **Text drag** stays inside the editor. `StartDrag` sets dragging and TAKES THE CAPTURE BACK:
  Editor releases it before an OS drag, but ButtonUp drops only while captured, so without this
  the drop was silently a click. The drop caret follows the mouse (`SetDragPosition`).
- **The rectangular-selection key** is the platform's: Alt by default, with
  `SCI_SET/GETRECTANGULARSELECTIONMODIFIER` handled in `ScintillaTk::WndProc`. The chosen key is
  reported to Editor as Alt, as ScintillaGTK does. It is no longer Editor's Ctrl, which collided
  with Ctrl+click add-a-caret.
- **The release point counts.** While captured, Editor throttles moves (`autoScrollTimer`) and
  lets the scroll ticker catch up. A release right after a fast move ended a rectangle a line
  short, so the last move is applied, unthrottled, before ButtonUp.
- **`GetMonitorRect` is unbounded.** Scintilla used it to flip lists above the caret against the
  EDITOR's edge; the host places popups against the display instead.
- **Fixed on the way:**
  - `tkCodeEdit_SendText( "" )` passed a NULL pointer, so `SetText( "" )` kept the old text.
    An empty string now goes as a NUL.
  - The list's frame was drawn with `PaintRectFactory`, which fills before it strokes and
    painted the rows out.
- **ABI 2:** call tips, IME, caret rect and per-editor DPI.

## For the form designer (2026-11-13)

- Settings by name over `SCI_*` (ReadOnly, TabWidth, IndentWidth, UseTabs, EOLMode, WrapMode,
  LineNumbers, IndentGuides, HighlightCurrentLine, ViewWhitespace, ViewEOL, Zoom, Keywords), with
  `TKCE_WRAP_*` / `TKCE_EOL_*` here because the generated constants file lacks
  `SC_WRAP_WHITESPACE`.
- Callbacks of their own for Change, CharAdded, UpdateUI, Dirty (the save point), MarginClick
  and DoubleClick, dispatched from the notify stream after `SetNotifyCallback`'s sub.
- An editor with no `SetFont` now draws in the bundled mono face: before, a CodeEdit placed on a
  form drew and measured nothing (`TeOpen` refuses an empty path).

## Still not done

- Ligature fonts: measuring sums advances while drawing shapes.
- Images in autocompletion rows (`SCI_REGISTERIMAGE`): the row type is carried, not drawn.
- A real input method, a real second monitor, and an OS drag into or out of the editor are
  untested. Drags inside the editor are tested.

## Measured (first gate, 2026-10-25, examples/tkControls/tkCodeEdit)

| | Windows (D3D11) | Linux X11 (WSLg GL) | Linux Wayland (WSLg GL) |
| --- | --- | --- | --- |
| Suite | 102/102 | 102/102 | 102/102 |
| 50k lines: load + first frame | 4.8–6.0 ms | 14.1–14.5 ms | 12.0–15.4 ms |
| Scroll 25,000 lines, re-render | 0.6 ms | 2.7–3.2 ms | 2.9–3.1 ms |
| Keystroke → painted frame | 0.9–1.2 ms | 5.2–7.7 ms | 4.0–7.2 ms |
| Caret blink re-render | 0.6 ms | 1.7–3.0 ms | 1.4–2.0 ms |
| Unseen page of real source (tkListTree.tiko, worst of 10) | 1.3–1.8 ms | 10.8–13.0 ms | 10.4–10.6 ms |

A/B plant: giving only a codepoint's LAST byte its position failed 4 checks (combining and CJK
at both scales); reverted, 102/102.

## Measured (the rest of the editor, 2026-10-25)

`examples/tkControls/tkCodeEdit`: **198/198 on Windows, X11 and Wayland.** The 96 checks added for the rest of the editor cover:
- the list: show, Down, Enter, double click, Escape, typing to filter, a click outside;
- the call tip: painted, highlight repaint, click notification, cancel;
- the context menu: 9 items, Select All; plus a host callback that replaces it;
- IME: inline, indicator, replace, one commit, cancel, undo;
- a fold header, its margin box, fold and unfold by click;
- circle and RGBA-image markers;
- a squiggle and a translucent box;
- Ctrl+click multi-caret typing, an Alt rectangle, text drag;
- a bold face file, an unknown family;
- the CJK fallback, measured against SDL_ttf and drawn;
- a DPI restyle and back.

The first gate's numbers held, with Linux's worst unseen page at 9.7–10.8 ms.

A/B plant: popups not forwarding keys failed 10 checks; reverted, 198/198.
