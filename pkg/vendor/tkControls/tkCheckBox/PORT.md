# tkCheckBox: port notes (from vendor PsCheckBox)

**Name map:** `PsCheckBox_*` → `tkCheckBox_*`; `PSCHECKBOX_*` → `TKCHECKBOX_*` (`_COLORS`,
`_PAINTINFO`, `_MESSAGEINFO`, `_GLYPH_*`, `_DEFAULT_*`). `CHK_BOXALIGN_*`, `CHK_TEXTALIGN_*`,
`CHK_MOOD_*`, `CHK_PART_*` and the four `CHK_*Callback*` types are unchanged. The handle is
`TK_WIDGET ptr`.

**Kept verbatim:**
- LayoutCheckBox and its geometry (ideal size, rcContent / rcBox / rcText span / rcVisual, box
  pinned to its side's padding, the caption taking the leftover span, degenerate span when starved);
- ResolveMood / ResolveColors, the 17-field colour struct and its dark defaults, `ThemeColors`
  role for role;
- two states only (no indeterminate: neither vendor nor PsPlatform has one);
- single line with end ellipsis; no mnemonics; no hit test (clicking the caption toggles);
- press → slide off → release; capture lost cancels the press;
- Space AND Enter (and keypad Enter) toggle; the message callback can veto either;
- silent setters, with `Toggle` as the one notifying action (refused while disabled); the change
  callback fires after the state is updated;
- the message callback's three ignored results (LBUTTONUP, SETFOCUS, KILLFOCUS);
- AutoSize (keeps the top-left; re-applied by exactly vendor's setters); GetIdealSize before sizing;
- the declared box cell: glyph, glyph-font and style setters repaint only;
- `CountRenderedTones` / `HashRenderedPart` (now `SDL_RenderReadPixels`, focus forced on);
- tooltip text resolution: own text, then callback, then nothing (no caption fallback).

**Changed:**
- `Create( hParent as TK_WIDGET ptr, id )`; a top-level parent is `tkHost_Root( h )`.
- **The box is drawn as vectors by default** (`CHK_BOXSTYLE_VECTOR`): PsPlatform's six-point
  polygon tick, derived from the box's side rather than from scaled constants. Vendor draws a
  Segoe Fluent Icons glyph pair, but that font ships only with Windows 11, so it cannot be the
  default of a control that also runs on Linux; vendor's own README calls an unset glyph font a
  trap (missing-glyph box). Vendor's "one colour per box" is kept: unchecked is a rounded outline
  in the resolved box colour; checked is the square filled with it and the tick knocked out in the
  mood's back colour -- no new colour field. Pen = `max(1, (side+8)\16)`, curvature = side\4,
  both derived from the (scaled) box size. The square is the largest one centred in the cell.
  `tkCheckBox_SetBoxStyle( h, CHK_BOXSTYLE_GLYPH )` gives vendor's font-glyph box exactly
  (`SetGlyphFont`, `SetGlyphUnchecked/Checked`, E739 / E73A defaults all kept).
- The tooltip is a tkTooltip owned through tkTipHost. `GetTooltipHandle` returns it (vendor's
  `GetPsTooltipHandle`); `SetHoverTime` / `SetAutoPopTime` / `SetReshowTime` → tkTipHost delays.
- `TKCHECKBOX_MESSAGEINFO` carries `msg` (TKM_*), `x`, `y`, `key` instead of uMsg/wParam/lParam.
- Colours start from the current theme (`tkTheme_Get()`); `SetColors` pins, `ApplyTheme` skips
  pinned, `UnpinColors` re-applies, `TKM_THEMECHANGED` re-applies.
- `Rescale( oldDpi, newDpi )` → `TKM_SCALECHANGED` (every metric × fNew/fOld; ring thickness not).
- Fonts are `TTF_Font ptr`, borrowed; `GetFont` / `GetGlyphFont` return them.

**Dropped (Win32-only):**
- `WM_SETTEXT` / `WM_GETTEXT` / `WM_GETTEXTLENGTH` (no window text);
- `WM_GETDLGCODE` and the WM_CHAR swallow (the host owns Tab; SDL never beeps);
- the 100 ms hover poll and `IDT_CCHECKBOX_HOTTRACK` / `PSCHECKBOX_HOTTRACK_MS` (the host
  guarantees the leave);
- `SetTooltipMode` / `GetTooltipMode` and the comctl32 handle;
- `PsCheckBox_RunSelfTest` (replaced by `examples/tkControls/tkCheckBox/selftest.tiko`);
- PsRegistry.

**Added:**
- `CHK_BOXSTYLE_VECTOR` / `CHK_BOXSTYLE_GLYPH`, `tkCheckBox_SetBoxStyle` / `GetBoxStyle`, and
  `TKCHECKBOX_PAINTINFO.nBoxStyle`;
- `tkCheckBox_DrawVectorBox( b, rcCell, isChecked, clrBox, clrBack )`, `tkCheckBox_VectorSquare`,
  `tkCheckBox_VectorPen` -- public so a paint callback (or a sibling such as tkOptionButton) can
  draw the built-in box;
- probes `tkCheckBox_GetHot`, `GetPressed` (the live gesture), `GetTextSize`;
- `tkCheckBox_PaintDefault( p )`: the stock drawing, for a paint callback (the form designer's
  Paint event).

**Vendor bug found (fixed here):**
- **Sliding off did not un-flash.** The README promises that while a press is live "sliding off
  visibly un-flashes the control" and that `PAINTINFO.isPressed` is "a live left press AND the
  cursor is still inside". The code kept `isPressed` true until release and both the background
  fill and `PsCheckBox_FillPaintInfo` used it raw, so a slid-off press kept painting the pressed
  mood. tk keeps the gesture flag and paints `isPressed andalso isHot` (`ShowsPressed`). This is
  the suite's A/B plant: reverting to vendor's line fails exactly `slid off: un-flashed to
  BoxColor` at both scales.
