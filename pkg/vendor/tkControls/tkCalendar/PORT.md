# tkCalendar (vendor PsCalendar): port notes

**Name map:** `PsCalendar_*` → `tkCalendar_*`; `PSCALENDAR_COLORS` / `_PAINTINFO` /
`_DAYPAINTINFO` / `_MYPAINTINFO` / `_MESSAGEINFO` / `_TOOLTIPINFO` → `TKCALENDAR_*`.
Prefix-free names stay: `CCAL_*`, `CAL_*` (views, hit parts, render parts, week starts),
`CAL_HITRESULT`, the `CAL_*Callback*` types. `SYSTEMTIME` → `TKDATE` (its date half, same field
names: `wYear`, `wMonth`, `wDayOfWeek`, `wDay`). `POINT` → `TKPOINT`, `RECT` → `TKRECT`,
`HFONT` → `TTF_Font ptr`, `PsPaintBuffer` → `TK_PAINT`.

**Kept, unchanged:** the date math; `LayoutCalendar` (pure arithmetic, so the ideal size is
valid before sizing); selection / anchor / today; the panel grid (≤ 12, refused, never
clamped) and the one-panel caption suppression; the nav step and the "does it reveal anything"
chevron rule; the year limits 1..9999; the keyboard model (arrows move the selection and notify,
PgUp/PgDn, Ctrl+PgUp/PgDn, Home/End, Ctrl+Home, Enter/Space activate, Esc zooms out only while
drilled down); click acts on the button DOWN, no capture; double-click = SelChange then
Activated; wheel accumulation, away = previous; hot tracking that skips inert days and dead
chevrons; the colour precedence; exactly one selected cell across panels; the focus ring drawn
after any day painter; the five callbacks plus messages and tooltips; silent setters with
`SelectDate` / `Activate` as the two actions; theme mapping and pinning; the three render probes.

**Changed:**
- A key the control does not claim returns FALSE and bubbles to the parent. That is what
  vendor's per-message `WM_GETDLGCODE` achieved: Esc in DAYS view still reaches a dialog.
- The message callback gets `TKCALENDAR_MESSAGEINFO` (`msg` = a `TKM_*`, plus `x`, `y`, `key`,
  `mods`, `clicks`) instead of `uMsg/wParam/lParam`.
- Ctrl comes from the key event's modifiers, not `GetKeyState`.
- The chevron stroke: vendor's `PaintLine` scaled its pen by the DPI; tkPaint's `PaintLine` takes
  raw pixels, so the stroke is multiplied by the surface scale at paint time. The stored
  `nChevThick` stays unscaled, as in vendor.
- The tip is still lazy and tracked: built on the first day cell whose callback returns text,
  shown at once against the cell, with auto-pop off. `GetTooltipHandle` returns the `TK_TIP ptr`
  (0 until built). On hide, the tip's text is cleared so its own dwell clock has nothing to
  re-show.
- Render probes render the full composition into the back buffer at the widget's place and read
  it back before any present (the host repaints after). `TestPartBrightness` is the mean of R,
  G and B, as vendor.

**Added:**
- From PsPlatform's PsCalendar: `tkCalendar_SetToday` (a host-supplied today; `Refresh` returns
  to the clock) and `tkCalendar_SetViewChangeCallback` (fired after a USER action moved the page
  or the view: chevron, wheel, title, drill-down cell, a key that scrolled; setters are silent).
- `tkCalendar_LocalToday` (the clock's date, via `SDL_GetCurrentTime`), `tkCalendar_GetMyFocus`
  (the drill-down cursor) and `tkCalendar_GetHot` (the hot part), for hosts and tests.
- `tkCalendar_PaintDayDefault` (the stock day cell, for a day-paint callback; tkDatePicker's uses it).
- For the form designer: `PaintDefault` and `PaintMonthYearDefault` (the renderer split out of the
  paint so a callback can call it), `SetSelDateParts`, `SetMinDate` / `SetMaxDate`, `SetAnchorMonth`,
  the `Set...Text` name lists, and theme shape support: the border follows the theme's BorderWidth
  until `SetBorderThickness`, which now pins it (tkDatePicker's drop-down sets 0, so keeps none).

**Dropped (Win32-only):** `WM_GETDLGCODE` and the `WM_CHAR` swallow (SDL never beeps), the 100 ms
hot-poll timer (the host guarantees the leave), `CS_DBLCLKS` (SDL counts clicks),
`SetTooltipMode` / `GetTooltipMode` / the comctl32 `GetTooltipHandle`, `GetCalendarPointer` as
public API (it is private here), `PsRegistry`, `Rescale` → `TKM_SCALECHANGED`.

**Vendor bugs found:** none.

**Selftest:** 213 assertions at 1.0 and 1.75 (date math, ideal size and geometry against the
README formulas, mouse, wheel, keyboard, range, silent setters, the single-selected-cell census,
pixels, theme, fonts, localization, disabled, rescale, the tracked tip). A/B: dropping the
owner-panel preference in `CAL_FindCell` fails exactly the "Apr 1 … in April" census and
"GetFocusCell agrees" at both scales (209/213).
