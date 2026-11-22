# tkScrollPanel: port notes (from vendor PsScrollPanel)

**Name map:** `PsScrollPanel_*` → `tkScrollPanel_*`; `PSSCROLLPANEL_*` → `TKSCROLLPANEL_*`
(`_STATE`, `_LINE_HEIGHT`, `_REVEAL_MS`). `SCP_PAINTINFO`, `SCP_MESSAGEINFO` and the
`SCP_*Callback*` types are unchanged. Handles are `TK_WIDGET ptr`; sizes are `long`.

**Kept:** three widgets as vendor had three windows: the container (the viewport, clipping its
children through the tkHost tree), the page (ids +1) and a `tkVScrollBar` (+2) in a strip that
stays reserved whether the thumb shows or not. Scrolling moves the page (`y = -nPos`) and nothing
on it. Everything in pixels; the layout pass in vendor's order (width first, the host's layout
callback with `cxPanel` handed in, height, clamp, strip, sync) with its re-entrancy guard
(`SetContentHeight` inside the callback is recorded); the page stretched to the viewport; the
reveal rule `needs AND (mouse over OR focus inside)` as the pure `ShouldShow`, polled every
100 ms while there is something to scroll, never hiding under a thumb drag, dropped while hidden;
the focus-into-view scroll on a focus CHANGE only; `EnsureVisible`'s minimum scroll (taller than
the viewport: top-aligned; refuses non-descendants); `AutoSizeContent` skipping hidden children;
the wheel as lines x line height with sub-notch accumulation, over the page, the host's children
(they bubble) and the strip; silent setters vs the notifying user paths (wheel, thumb, the focus
scroll); the strip coloured like the page by `SetColors`; theme roles; rescale of content height
and position, with the strip width and line height stored unscaled.

**Auto-scroll-to-focus is implemented** (it was dead code in PsPlatform): the reveal tick
compares the host's focus widget with the last one it saw; a change landing inside the page
scrolls it into view and fires the scroll callback. Asserted for `tkHost_SetFocus`, for Tab, for
the no-yank-back rule and for `SetAutoScrollToFocus( false )`.

**Changed:**
- "The cursor is over the control" is the host's hot (or capture) widget being the container or
  any descendant -- a cursor over a host button on the page counts, as vendor's geometric test.
- `SCP_MESSAGEINFO` carries `msg` (a `TKM_*`), `x`, `y`, `wheelY`; observed on both widgets:
  wheel, left/right down/up, move. No `lResult`.
- `HandleWheelDelta` takes 120ths of a notch, positive = up (Win32's sign). The system's
  wheel-lines setting is `TKSCROLL_SYSTEM_WHEEL_LINES` (3); SDL exposes none, and there is no
  page-per-notch mode.
- The reveal timer is the container's `TKSCROLLPANEL_TIMER_REVEAL` (`TK_TIMER_APP`).
- Added `GetColors`, `GetLineHeight` (the foreground has no `WM_CTLCOLOR*` to go to, so hosts
  read it back for their own widgets).
- Added `PaintDefault( p )`: the page's stock background, for a paint callback (the form
  designer's Paint event).

**Dropped as Win32-only:** `WM_CTLCOLORSTATIC/BTN/EDIT/LISTBOX` and the brush; forwarding
`WM_COMMAND` / `WM_NOTIFY` / `WM_HSCROLL` / `WM_VSCROLL` to the container's parent;
`SetFont` (a `WM_SETFONT` broadcast -- tk widgets take fonts through their own setters);
`lResult`; `WS_EX_CONTROLPARENT` / `IsDialogMessage` (the host owns Tab and walks the tree);
`WM_SETCURSOR`; `CS_HREDRAW` / `CS_VREDRAW`; `SPI_GETWHEELSCROLLLINES` / `WHEEL_PAGESCROLL`;
the trace switch; PsRegistry.

**Vendor bugs found:** none.

**Test note:** the selftest drives most reveal decisions with a direct tick right after the
input. Parallel test runs on one desktop pop windows that steal hover and focus mid-wait (seen:
1 run in 2 lost the thumb under a 250 ms wait); the real 100 ms poll is still asserted, with
retries, and the focus scroll runs on the real timer.
