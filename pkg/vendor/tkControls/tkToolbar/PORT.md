# tkToolbar: port notes (from vendor PsToolbar)

**Name map:** `PsToolbar_*` → `tkToolbar_*`; `PSTOOLBAR_*` → `TKTOOLBAR_*` (`_COLORS`, `_ITEM`,
`_PAINTINFO`, `_MESSAGEINFO`, `_STATE`, `_DEFAULT_*`). `TBR_KIND_*`, `TBR_GRAVITY_*`, `TBR_ZONE_*`,
`TBR_PART_*`, `TBR_MOOD_*` and the `TBR_*Callback*` types are unchanged. The toolbar and its
CONTROL children are `TK_WIDGET ptr`; its menus are `TK_MENU ptr` (tkPopupMenu).

**Kept:** the six kinds; the cell-width formula with gaps charged only between two things
(`tkToolbar_ComputeCellWidth`), measured captions; the ideal size valid before sizing; left /
right gravity, the last right item hard against the edge; the eviction ladder
(`tkToolbar_ComputeOverflowSplit`: left tail first, then the right run's front, CONTROL cells
never); the overflow chevron inboard of the right run; separators trimmed at each run's edges
(not re-run as a fixpoint); a CONTROL child hidden when it cannot be placed; capture per zone
(action zones take it, menu zones open on the down and take none); the matched press / slide-off
/ release on the same item AND zone; the split's chevron zone owning the trailing padding; radio
groups (both writes before either callback, losers first, re-clicking the checked member a
no-op, `SetSelected` silent but enforcing); the one commit path for a strip click, an overflow
pick and `tkToolbar_Click`; `tkToolbar_Toggle`; the overflow menu rebuilt per open, ids = index +
1, separators collapsed, a DROPDOWN picked from it anchored at the overflow button; the item
menu's opening edge before any row is built (the just-in-time hook), the overflow's after, an
empty menu reporting a balanced open/close; the reopen guard narrowed to the zone that owns the
open menu (a click on another item closes the menu and presses that item); menus themed from
the bar, `SetMenuColors` claiming them; glyph-or-image icon cells (owned); per-item fore colour on
the idle rung only; the pill fill over the bar fill, half a split lit; the dynamic item set with
index fix-ups; theme roles; the rescale (divider not scaled); the pure helpers and the render
probes (`CountRenderedTones`, `HashRenderedPart`, through the real paint path).

**Changed:**
- CONTROL cells hold a WIDGET created as a child of the toolbar (`tkXxx_Create( hToolbar, ... )`);
  the toolbar positions, shows and hides it and never destroys it (`DeleteItem` / `Clear` hide
  and forget it). It is destroyed with the toolbar, as a Win32 child window was.
- No pump filter: tkHost routes keys to the open popup and closes it on an outside press, which
  still lands. The toolbar learns that a menu closed through select / closed callbacks it
  installs on the menu when it opens it; an item menu's own callbacks (the host's) are kept and
  run behind the toolbar's. The reopen guard is a dismissal remembered for 250 ms.
- A chain closed behind the toolbar's back (another popup opened elsewhere) is re-synced, with
  its closing edge, on the next paint, mouse event or `IsDroppedDown` / `GetDroppedItem`.
- `TKTOOLBAR_MESSAGEINFO` carries `msg` (a `TKM_*`), `x`, `y`, `idx`, `nZone`; the paint info's
  `pImage` is a `tkImageFile ptr` (draw it with `tkImage_Paint`).
- Fonts are `TTF_Font ptr`, borrowed; with no text font the host's default measures and paints.
- `GetTooltipHandle` returns the `TK_TIP ptr`. Added `GetHotItem`, `GetPressedItem`.
- Added `PaintItemDefault( p )`: the stock item, for an item-paint callback (the form designer's
  Paint event).

**Dropped as Win32-only:** `FilterMessage`; `SetControlNotifyCallback` /
`TKTOOLBAR_CONTROLNOTIFY` and the forwarding of a child's `WM_COMMAND` / `WM_NOTIFY` /
`WM_CTLCOLOR*` to the toolbar's parent (a tk child widget reports through its own callbacks);
the 100 ms hot-track poll (`IDT_PSTOOLBAR_HOTTRACK`, `PSTOOLBAR_HOTTRACK_MS`); `WM_MOUSEHOVER` and
the hover time's double duty; `SetTooltipMode` / `GetTooltipMode` / the comctl32 handle;
`WS_EX_CONTROLPARENT` / `IsDialogMessage` (the host's Tab walks into the CONTROL children);
`CS_DBLCLKS`; `RunSelfTest` (the selftest lives in `examples/tkControls/tkToolbar`); PsRegistry.

**Vendor bug found (fixed here):** `InsertItemSlot` reset the inserted slot without clearing
`pImage`, so after the tail shift the new item aliased its neighbour's image: it drew that image
and the two items freed one pointer twice on destroy. `ResetItem` clears every field. The
selftest asserts it (the A/B plant reproduces the bug: the check fails and the process dies on
the double free).

**Test note:** the selftest filters the OS's focus-lost and mouse-leave window events
(`SDL_SetEventFilter`), as tkMenuBar's does: parallel test runs steal the focus and the host then
dismisses open menus. No check is about either.
