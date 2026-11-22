# tkTabBar: port notes (from vendor PsTabBar)

**Name map:** `PsTabBar_*` → `tkTabBar_*`; `PSTABBAR_*` → `TKTABBAR_*` (`_TABINFO`,
`_PAINTINFO`, `_MESSAGEINFO`, `_STATE`, `_DEFAULT_*`). The `TB_*Callback*` types are
unchanged. The handle is the `TK_WIDGET ptr`; indices are `long`.

**Kept:** a bar, not a container; the no-shrink width formula, measured with SDL_ttf
(`tkText_Width`); the five derived rects and the asymmetric `rcPaint` deflation; icons and
caption on the symmetric height; first-visible scrolling, scroll-into-view consumed at layout,
back-fill, `CanNavigate` / `Navigate`, wheel up = left; select on DOWN unless on the "X"; the
matched close gestures (left on the X, middle anywhere); live drag-to-reorder past the drag
threshold, gated on the direction of travel, hover pinned to the dragged tab, the move cursor
for the gesture, no restore on capture loss; a mutation cancels a live press; the index
fix-ups on insert/delete/move; the chrome after the callbacks (broken bottom rule, three-sided
active border; width 0 = none); silent `SetCurSel` / `MoveTab` / `DeleteTab`; tooltips = the
callback else the caption; `SetBackColor` does not repaint, `SetBorderColor` does, both return
the previous colour and pin; rescale with the border floored at 1.

**Changed:**
- `PSTABBAR_MESSAGEINFO` carries `msg` (a `TKM_*`), `x`, `y`, `clicks` and `wheelY`. A
  `TKM_LBUTTONDOWN` with `clicks = 2` is vendor's `WM_LBUTTONDBLCLK` (same bookkeeping).
- The drag threshold is `TKTABBAR_DRAG_THRESHOLD` (4, scaled), `SM_CXDRAG`'s default.
- The move cursor is the widget's `TK_CURSOR_SIZEALL` while dragging.
- The two colour properties live in `TKTABBAR_COLORS` with the painter's (below);
  `GetColors` / `SetColors` (pins) added.
- Fonts are `TTF_Font ptr`; with none, the host's default font measures.

**Added (PsPlatform's PsTabBar):**
- A built-in painter used when no paint callback is set (vendor draws no tabs then):
  dragging > selected > hot > normal fills, a top accent bar on the active tab, the X on the
  hot or active tab, a focus ring when the bar has focus. Its colours are the new
  `TKTABBAR_COLORS` fields (theme roles Surface / SurfaceHot / Window / Selected / TextDim /
  TextHot / TextStrong / Accent / FocusRing). `SetGlyphFont` supplies the X and the icons.
- `PaintTabDefault( p )`: the built-in painter's tab, for a paint callback (the form designer's
  Paint event).
- `SetGlyph` / `GetGlyph`: a per-tab left icon for the built-in painter.
- `SetClosable` / `GetClosable`: a tab that refuses both close gestures (the rect stays reserved,
  so nothing shifts).
- `SetKeyboard` / `GetKeyboard`: opt-in keyboard. The bar becomes a Tab stop answering Left /
  Right / Home / End as a USER selection (SelChange fires). Clicks still never take focus.
- `HitTest`, `GetHotTab`, `GetHotClose`, `IsDragging`: state queries for hosts and the selftest.

**Dropped as Win32-only:** `TCM_NAVIGATE` / `TCM_CANNAVIGATE` (the `SendMessage` doors; the
functions are the API), the 100 ms hot-track poll (`IDT_CTABBAR_HOTTRACK`,
`PSTABBAR_HOTTRACK_MS`), `WM_MOUSEHOVER` and the hover time's double duty
(`SetHoverTime` is the tooltip delay only), `WM_SETCURSOR`, `SetTooltipMode` /
`GetTooltipMode` / the comctl32 `GetTooltipHandle` (`GetTooltipHandle` returns the `TK_TIP ptr`,
vendor's `GetPsTooltipHandle`), `CS_DBLCLKS`, `WM_ERASEBKGND`, PsRegistry.

**Vendor bugs found (fixed here):**
- The README says a message callback returning TRUE for `WM_MOUSEMOVE` "stops that move
  driving a live drag", but vendor calls the callback AFTER the drag code. tk calls it first.
- `InsertTabAt` did not shift the hover index, so after an insert at or before the hot tab
  the wrong tab painted hot (and drew its X) until the next mouse move.
