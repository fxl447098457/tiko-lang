# tkSplitter: port notes (from vendor PsSplitter)

**Name map:** `PsSplitter_*` → `tkSplitter_*`; `PSSPLITTER_*` → `TKSPLITTER_*` (orientation,
phase, paint/message info). `SPL_PaintCallbackSub`, `SPL_MessageCallbackFunc` and
`SPL_PosChangedCallbackSub` keep their names. The handle is `TK_WIDGET ptr`; positions and
phases are `long`.

**Kept verbatim:**
- the one-number model: `nPos` is the bar's leading edge in the PARENT's coordinates (the
  widget's own parent-relative x / y);
- ClampPos, including the inverted range pinning at `nMin`; the unbounded `&h7FFFFFFF` default
  (`TKSPLITTER_MAX_UNBOUNDED`);
- MoveBar: the control moves itself along the drag axis only, cross-axis position and size
  preserved;
- the three phases: BEGIN from the press at the unchanged position, MOVE only when the clamped
  position changed (quiet against a limit), END last with `IsDragging` already FALSE;
- the absolute grab offset (no sticky clamps); capture before the message callback; the
  callback's result ignored for the button-up; EndDrag shared by up, capture loss and hide;
- hot pinned TRUE for the whole drag and re-derived from the cursor when it ends;
- silent `SetPos` / `SetRange`; the paint callback replacing the built-in flat fill;
- the theme mapping `BackColor = Divider`, `HotColor = TextDisabled`; `SetColors` pins.

**Changed:**
- `Create( hParent as TK_WIDGET ptr, id [, nOrientation] )`; a top-level parent is
  `tkHost_Root( h )`. Created at 0,0, zero-sized; place it with `tkWidget_SetPos`.
- The cursor is the widget's `TK_CURSOR_SIZEWE` / `TK_CURSOR_SIZENS`, set at create. The host
  shows it over the bar and, under capture, for the whole drag.
- The double click is `TKM_LBUTTONDOWN` with `clicks = 2`. It gets the same capture handling
  as a down, so claiming it from the message callback still gives the collapse/restore idiom.
- `TKSPLITTER_MESSAGEINFO` carries `msg` (`TKM_LBUTTONDOWN` / `TKM_MOUSEMOVE` /
  `TKM_LBUTTONUP`), widget-local `x` / `y` and `clicks`, in place of `uMsg` / `wParam` /
  `lParam`.
- Re-sync: tkHost sends nothing when a widget moves, so there is no `WM_WINDOWPOSCHANGED`. The
  position is re-read from the widget at every entry point (except mid-drag). It is the same
  observation as vendor's: nothing is clamped and nothing is notified.
- Hover on a move is a rect test, not "any move that reaches us". Under a capture the host keeps
  (a claimed double click), moves arrive from anywhere.
- Colours start from the current theme: `tkSplitter_ThemeColors( tkTheme_Get() )`. Under the
  dark preset that is Divider (55,60,69) / TextDisabled (96,102,112). The
  `TKSPLITTER_COLORS` struct defaults are vendor's (53,59,69) / (90,98,112).
- `Rescale(oldDpi, newDpi)` → `TKM_SCALECHANGED`. It still multiplies pos/min/max by
  fNew/fOld (the sentinel max is left alone), then clamps and moves the bar silently.
- A disabled widget (`tkWidget_Enable`, a host feature vendor lacks) ends the drag and drops the
  hover.

**Dropped (Win32-only):**
- `WM_SETCURSOR` in the message callback. There is no such message; a host that wants its own
  cursor calls `tkWidget_SetCursor( hSplit, ... )`.
- `CS_DBLCLKS` (SDL counts clicks).
- `TrackMouseEvent` and the 100 ms hover poll: `IDT_CSPLITTER_HOTTRACK` and
  `PSSPLITTER_HOTTRACK_MS` are gone, because the host guarantees the leave.
- `WM_WINDOWPOSCHANGED`, `WM_ERASEBKGND`, `GWLP_ID` / `GetDlgItem` (the id is `w->ctrlId`).
- PsRegistry.

**Not added, because vendor has none:**
- fonts (the control measures no text);
- tooltips (README: "No tooltip support");
- keyboard;
- grip, snap or collapse of its own.

PsPlatform's splitter (grip mark, a hit band wider than the bar, a bar that does not move
itself) contradicts vendor's "Behaviour and limits" and was not followed.

**Added:**
- `tkSplitter_GetHotColor` (vendor has no hot-colour getter);
- `TKSPLITTER_COLORS` and `tkSplitter_ThemeColors`;
- `TKSPLITTER_MAX_UNBOUNDED`;
- `tkSplitter_PaintDefault( p )`: the stock bar, for a paint callback (the form designer's Paint
  event).

**Vendor bugs found (fixed here):**
- `PsSplitter_Rescale` scaled `nPos` but not `dragOffset`, so a DPI change mid-drag made the bar
  jump by the unscaled offset at the next move. The offset is now scaled too.

Otherwise vendor's logic held up under the port.
