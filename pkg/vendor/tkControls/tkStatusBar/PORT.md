# tkStatusBar: port notes (from vendor PsStatusBar)

**Name map:** `PsStatusBar_*` → `tkStatusBar_*`; `PSSTATUSBAR_*` → `TKSTATUSBAR_*`
(`_PANELINFO`, `_PAINTINFO`, `_MESSAGEINFO`, `_DEFAULT_PADDING`). The `SB_*` callback types are
unchanged. The handle is `TK_WIDGET ptr`; indices are `long` where vendor used `integer`.

**Kept verbatim:**
- the panel model (text, itemData, nMinWidth; rects derived, read-only);
- the width law `max( textWidth + 2*padding, nMinWidth )` — the minimum is a floor, not a fixed
  width;
- the leftover absorbed by the spring(s); on overflow nothing shrinks and panels run past the edge.
  **Changed in tk:** several springs, a flag per panel (`SetPanelStretch` / `GetPanelStretch`), sharing
  the leftover evenly (the first ones take a pixel each of the remainder; a hidden one takes none).
  `SetExpandPanel` / `GetExpandPanel` remain as the one-spring view: set makes that panel the only
  spring, get answers the first;
- the stored-index fix-ups (insert at or before the spring shifts it; deleting it clears it;
  deleting before it shifts it down; `Clear` resets it); `InsertPanel` clamps to `[0, count]`;
  `SetExpandPanel` refuses an index that is neither valid nor -1 and keeps the old spring;
- lazy layout: `GetPanelRect` forces it, `GetItemRect` does not; zero client = stays stale;
- one hot panel, passed to the paint callback as `isHot`;
- no capture (press on 3, release on 5 fires 5; release outside: no up), no focus, not a tabstop,
  no keyboard;
- the message callback, called after the hot update, its result honoured uniformly; MOUSELEAVE
  reports idx -1; the right button's down is reported, its up is not;
- the tooltip resolved on demand for the hot panel (callback, else the panel's own text; ""
  suppresses), the tool index moved on every hot change (`tkTipHost_SetToolIndex`);
- `SetHoverTime` doing double duty (tip delay and the hover message);
- `SetBackColor` returns the previous colour, pins, and does not repaint; `SetItemData` does not
  repaint; `SetPaintCallback` does not repaint;
- `Rescale` scales the padding and every panel's minimum width.

**Changed:**
- `Create( hParent as TK_WIDGET ptr, id )`; a top-level parent is `tkHost_Root( h )`. Created
  zero-sized but not hidden (a zero-size widget shows nothing; no tk control hides itself).
- Messages are `TKM_*`: `WM_LBUTTONDBLCLK` is `TKM_LBUTTONDOWN` with `clicks = 2`;
  `WM_MOUSEHOVER` is `TKSB_MOUSEHOVER` (tkHost has none), scheduled by the control on
  `TK_TIMER_HOVER`, re-armed on every move and fired once per rest, only while the cursor is
  still on the bar. `TKSTATUSBAR_MESSAGEINFO` carries `msg / x / y / clicks / idx` in place of
  `uMsg / wParam / lParam`.
- `GetPsTooltipHandle` → `tkStatusBar_GetTooltipHandle` (a `TK_TIP ptr`); the three delays go
  through `tkTipHost_SetDelay`. `SetHoverTime` takes `long` (vendor's odd `integer` dropped).
- The font is a `TTF_Font ptr`, borrowed; with none, the host's default font measures.
- Colours: vendor's single `BackColor` sits in `TKSTATUSBAR_COLORS` with the built-in painter's
  four; `tkStatusBar_ThemeColors` maps BackColor = `Window` (vendor), BackColorHot =
  `SurfaceHot`, ForeColor = `TextDim`, DividerColor = `Divider` (PsPlatform's keys), ForeColorHot
  = `TextHot`. Created with `ThemeColors( tkTheme_Get() )`; `TKM_THEMECHANGED` re-applies.
- `Rescale(oldDpi, newDpi)` → `TKM_SCALECHANGED` (also scales the divider inset).

**Dropped (Win32-only):**
- the 100 ms hot-track poll and `IDT_CSTATUSBAR_HOTTRACK` / `PSSTATUSBAR_HOTTRACK_MS` (the host
  guarantees the leave);
- `CS_DBLCLKS` (SDL reports the click count), `WM_ERASEBKGND`, the update-rect skip (no damage
  regions: panels wholly past the right edge are still skipped);
- `SetTooltipMode` / `GetTooltipMode`, the comctl32 `GetTooltipHandle` and the
  `TTN_GETDISPINFOW` arm;
- PsRegistry.

**Added:**
- **The built-in panel painter** (PsPlatform's `PsStatusBar.OnPaint`), used when no paint
  callback is installed: the caption inset by the padding, a hot fill on a *clickable* panel
  (one with a click callback — "hover only matters where a click does something"), and a
  1-pixel divider after every panel but the last, inset by `TKSTATUSBAR_DEFAULT_DIVIDERINSET`
  (4, scaled). Vendor's paint callback, when installed, replaces it and owns every panel pixel.
  This contradicts vendor's "nothing renders inside a panel without a paint callback" on
  purpose (PORTING.md keeps PsPlatform's painters).
- `tkStatusBar_SetClickCallback( h, sub( hBar, idx, clicks ) )` (PsPlatform `OnClick`): fired on
  the left-button UP over a panel — vendor's documented click convention — `clicks = 2` on the
  second click of a double click; a message callback returning TRUE for that up suppresses it.
- `tkStatusBar_PaintPanelDefault( p )`: the built-in panel, for a paint callback (the form
  designer's Paint event).
- `tkStatusBar_GetColors` / `SetColors` (pins) / `ThemeColors`; `tkStatusBar_HitTest`
  (PsPlatform `HitTestIndex`); `tkStatusBar_GetHot` (test probe).
- `tkStatusBar_SetPanelVisible( h, idx, bVisible )` / `GetPanelVisible` (2026-10-27, for tkEdit's
  status-line switches): a hidden panel keeps its index and is laid out at width 0 -- not
  painted, never hit, no divider -- so a host can hide one without renumbering the others.

**Not in vendor, so not here:** per-panel glyphs/icons, per-panel alignment, fixed-width panels,
a size grip, docking (the host places the bar from its `OnSize`).

**Vendor bugs found (fixed in tk):**
- **Insert/delete left the hot index naming a different panel.** Vendor only cleared it when it
  fell past the end, so after inserting or deleting before the hot panel the paint callback was
  told the wrong panel was hot (and the tip's tool index pointed at it) until the next mouse
  move. tk clears the hot index and the tool index on every insert, delete and clear.
- **`ApplyTheme` never repainted.** It went through `SetBackColor`, which does not invalidate, so
  a theme change left a visible bar in the old colour until something else repainted it. tk's
  `ApplyTheme` invalidates.
