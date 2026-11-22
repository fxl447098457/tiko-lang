# tkSelectBar: port notes (from vendor PsSelectBar)

**Name map:** `PsSelectBar_*` → `tkSelectBar_*`; `PSSELECTBAR_*` → `TKSELECTBAR_*`
(`_COLORS`, `_PANEL`, `_PAINTINFO`, `_MESSAGEINFO`, `_DEFAULT_*`). `SEL_*` callback types are
unchanged. The handle is `TK_WIDGET ptr`; the font is a borrowed `TTF_Font ptr`.

**Kept verbatim:**
- the static panel set: `AddPanel` / `Clear`, no insert or delete;
- exactly one current panel: the first added auto-selects silently, `SetCurSel` rejects -1 and
  disabled panels, `SetEnabled(false)` refuses the current one;
- LayoutPanels: `cellWidth = padLeft + textW + padRight`, ONE text height for the bar
  (`TTF_GetFontHeight` = `tmHeight`), the text + gap + line block centred as a unit, `rc` full
  client height, the run from x = 0, `GetIdealWidth` valid before sizing;
- per-panel padding with -1 = inherit (below -1 clamps to -1);
- the colour struct (value for value) and its precedence, pressed painting as hot, the
  indicator drawn last;
- press / slide off / release with capture; the snapshot-before-release; CAPTURECHANGED cancels;
  the message callback's result ignored for the left-button up; a press never takes focus;
- `HitTest` = geometry (disabled included, no client test); the callback `idx` = interaction;
- silent setters; the selection-change callback for user action only;
- per-panel tooltips (own text, then callback, never the caption);
- `ThemeColors` role mapping, `ApplyTheme` / `UnpinColors`, `SetColors` pins;
- the indicator thickness is scaled at create and on rescale, as vendor does: it is a layout
  input, not a pen width.

**Changed:**
- `Create( hParent as TK_WIDGET ptr, id )`; a top-level parent is `tkHost_Root( h )`.
- A double click is `TKM_LBUTTONDOWN` with `clicks = 2` (was `WM_LBUTTONDBLCLK`). It is handled
  as a press, as vendor's shared arm did, and the message callback sees `clicks`.
- `TKSELECTBAR_MESSAGEINFO` carries `msg` (TKM_*), `x`, `y`, `clicks`, `idx` instead of
  `uMsg` / `wParam` / `lParam`.
- The tooltip is a tkTooltip owned through tkTipHost; the hot panel drives
  `tkTipHost_SetToolIndex`. `GetTooltipHandle` returns it (vendor's `GetPsTooltipHandle`).
  `SetHoverTime` / `AutoPop` / `Reshow` → tkTipHost delays.
- Rescale is `TKM_SCALECHANGED` (k = fNew / fOld) instead of `PsSelectBar_Rescale(oldDpi, newDpi)`.
- With no font set, the measuring pass AND the painter use the host's default font.
- Every change repaints the whole bar (the host has no damage regions).

**Dropped (Win32-only):**
- the 100 ms hot-tracking poll and `IDT_CSELECTBAR_HOTTRACK` / `PSSELECTBAR_HOTTRACK_MS` (the
  host guarantees the leave);
- `WM_MOUSEHOVER` reporting (no `TrackMouseEvent`; the tip owns its own dwell);
- `CS_DBLCLKS`, `WM_ERASEBKGND`, the `TTN_GETDISPINFO` arm;
- `SetTooltipMode` / `GetTooltipMode` and the comctl32 handle;
- PsRegistry.

**Added:**
- `tkSelectBar_PaintPanelDefault( p )`: the stock panel, for a panel-paint callback (the form
  designer's Paint event).
- **Keyboard focus, from PsPlatform.** The bar is a Tab stop. Left / Right move the selection,
  skipping disabled panels and never wrapping; Home / End go to the first / last enabled panel.
  A key is a user action, so it NOTIFIES. Up / Down, Space and Enter are not claimed (PsPlatform
  defines none), so they bubble and Tab still moves focus. A click still never takes focus.
- A 1 px focus ring round the current panel's cell, inset by a scaled 2 px:
  `TKSELECTBAR_COLORS.FocusRingColor` (theme role `FocusRing`) and `PAINTINFO.isFocused`.
- The whole widget disabled (`tkWidget_Enable`) greys every label (PsPlatform); the indicator
  stays.
- Probes: `tkSelectBar_GetHot`, `GetPressed`, `GetFocused`, `GetTextHeight`.

**Vendor bugs found (fixed here):**
- `Clear` and disabling the hot panel left the tooltip on the old tool index, so a visible tip
  stayed up for a panel that no longer existed or could no longer be hot. Both now move the tip
  to index -1.
- LayoutPanels' zero-client bail left the rects of an earlier size in place, so a bar shrunk
  to 0×0 answered stale rects. They are emptied now, as the README promises.
- With no font set, the measuring pass used `DEFAULT_GUI_FONT` while the painter drew with
  whatever the DC held, so the widths and the drawn text could disagree (the README admits it).
  Here both use the host's default font.
