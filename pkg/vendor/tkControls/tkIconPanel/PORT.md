# tkIconPanel: port notes (from vendor PsIconPanel)

**Name map:** `PsIconPanel_*` → `tkIconPanel_*`; `PSICONPANEL_*` → `TKICONPANEL_*`
(`_COLORS`, `_ITEM`, `_PAINTINFO`, `_MESSAGEINFO`, `_STATE`, `_DEFAULT_*`). `IP_JUSTIFY_*`,
`IP_KIND_*` and the `IP_*Callback*` types are unchanged. The handle is the `TK_WIDGET ptr`.

**Kept:** the declared-cell layout (nothing measured; a resize moves `x0` only; overflow
degrades to LEFT with honest rects), the static item set, the three kinds, selection as a set
on the items, silent setters (`SetSelected` refuses non-toggles), the press / slide-off /
release gesture with capture and the snapshot-before-release rule, the message callback's
result ignored for the up, the right button reported only, no focus taken, disabled items
hit-testable but inert, the state precedence and the eight colours, glyph-or-image cells
(owned), per-item tooltips (own text, then callback, then nothing), `GetIdealWidth` valid
before sizing, and the per-monitor rescale (inherit sentinels left alone).

**Changed:**
- `PSICONPANEL_MESSAGEINFO` carries `msg` (a `TKM_*`) and `x`/`y` instead of
  `uMsg`/`wParam`/`lParam`.
- `PSICONPANEL_PAINTINFO.b` is a `TK_PAINT ptr`; `pImage` is the item's `tkImageFile ptr`
  (draw it with `tkImage_Paint`); added `isVertical`.
- Fonts are `TTF_Font ptr`, borrowed. With none set, the host's default font draws.
- `GetTooltipHandle` returns the `TK_TIP ptr` (vendor's `GetPsTooltipHandle`).
- The whole panel repaints on any change (no damage regions; see FINDINGS).

**Added (PsPlatform's PsIconPanel, off by default):**
- `SetVertical` / `GetVertical`: the activity-bar column. Cells stack downwards, the icon is
  centred across, a separator's rule lies flat, justify LEFT/CENTER/RIGHT = top/centre/bottom.
  In that mode `GetIdealWidth` is the widest icon and the new `GetIdealHeight` is the summed
  run (in a row, `GetIdealHeight` is the tallest icon).
- `SetMarker( nSize, bFillSelected )` / `GetMarker` / `GetMarkerRect`: the selection marker,
  a slab down a column's left edge or a rule under a row's cell, in the new
  `TKICONPANEL_COLORS.MarkerColor` (theme role `Accent`). `bFillSelected = false` keeps a
  latched toggle on the idle fill (the tab-row look).
- `SelectExclusive`: the radio helper, silent.
- `GetHotItem`, `GetPressedItem`: state queries the selftest asserts through.
- `PaintItemDefault( p )`: the stock item, for an item-paint callback (the form designer's Paint
  event).

**Dropped as Win32-only:** the 100 ms hot-track timer (`IDT_CICONPANEL_HOTTRACK`,
`PSICONPANEL_HOTTRACK_MS`; the host guarantees the leave), `WM_MOUSEHOVER` reporting and the
hover-time double duty for `TrackMouseEvent` (`SetHoverTime` is the tooltip delay only),
`SetTooltipMode` / `GetTooltipMode` and the comctl32 `GetTooltipHandle`, `WM_NOTIFY`,
`WM_ERASEBKGND`, `CS_DBLCLKS` (a `clicks = 2` press is an ordinary press here, asserted),
PsRegistry.

**Vendor bugs found:** none.
