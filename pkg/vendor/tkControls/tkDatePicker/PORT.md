# tkDatePicker: port notes (from vendor PsDatePicker)

**Name map:** `PsDatePicker_*` → `tkDatePicker_*`; `PSDATEPICKER_COLORS` / `_PAINTINFO` /
`_DAYPAINTINFO` / `_MESSAGEINFO` / `_TOOLTIPINFO` → `TKDATEPICKER_*`. `DTP_*` constants and the
`DTP_*Callback*` types are unchanged, as are the `CDTP_DEFAULT_*` values. `SYSTEMTIME` →
`TKDATE` (tkCalendar's). The handle is the widget.

**Kept (vendor):**
- the layout: icon = the right `nIconWidth`, divider beside it, field from `left + radius` to
  the divider, inset by the border; the rects are derived (FALSE before the first size);
- `GetIdealSize`'s formula, including the `"Wednesday, September 30, 2222"` stand-in;
- the editing-box painter: frame fill, icon cell extended past the divider, divider, glyph,
  outline last;
- Format with the ISO fallback, Parse with none (no callback = typed text is never accepted),
  the silent revert on a failed parse, AllowEmpty, the
  range clamp and the inverted-pair swap;
- commit on Enter or focus leaving the field; F4 / Down / Alt+Down open and close;
- silent setters; `DropDownCallback` also for programmatic opens, the opening edge before
  anything is built, the pairing kept when the popup cannot be made;
- one calendar open per process; every open re-seeds (week start, month count, footer,
  range, selection, today, the days view, the selected or current month);
- the Today band ("Today: " + Format), dimmed and inert when today is out of range;
- an outside press closes the calendar AND reaches its target (`bPassDismissClick`);
- the reopen guard, so the icon press that closed the calendar does not reopen it;
- the colour struct, its defaults and `ThemeColors` role map; pinning; `ApplyFonts`;
- render probes `TestCalendarTones`, `TestFooterTones`, `TestPartBrightness` (vendor's part
  numbers).

**Changed:**
- **The calendar is tkCalendar** (PsPlatform's decision), not a second month grid. The popup
  is a `TK_SURF_POPUP` holding a frame widget, a tkCalendar and the optional Today band. It
  is created at every open, because Wayland fixes a popup's position at creation.
  - `GetCalendarHandle` is the tkCalendar widget while the calendar is open, and 0 otherwise
    (vendor's window survived a close).
  - The chrome is tkCalendar's: each panel has a caption, and the month names are
    host-replaceable.
- **Keys go to the open calendar** (the host routes them to the top popup), so the calendar's
  keyboard works: arrows, PageUp/PageDown, Home/End, Enter picks. Vendor's popup had no
  arrows. F4 and Alt+Up/Down close it, as does Escape (via the host). Typing into the field
  resumes once the calendar is closed.
- **One click on a day picks it.** Vendor fired DateChanged on every pick; here it fires only
  for a real change, as vendor's README says.
- **The icon is drawn** (PsPlatform's small calendar) until a glyph font is handed over.
  `SetIconFont` / `ApplyFonts`' glyph font switch to vendor's glyph, `&hE787` by default. The
  control creates no font.
- **`SetShowTodayFooter` on an open calendar** resizes it in place: `SDL_SetWindowSize`, with
  the band added or removed. An earlier rebuild of the popup let focus wander, and the host's
  focus-loss rule then closed the new one (measured: 1 in 12 runs).
- **The tooltip** is tkCalendar's (tkTipHost dwell timing), not vendor's tracked tip. It is
  still lazy, and absent without a `TooltipCallback`.
- **The message callback** sees `TKM_*` messages, and the field's messages arrive as the
  picker's. The return value is ignored for KILLFOCUS, LBUTTONUP, MOUSELEAVE and ENABLE.

**Added:**
- `SetToday( h, st, bPin )`: pins "today" for the ring and the band (tests, screenshots).
- `GetPopup` and `GetFooterHandle` (test seams).
- `GetIconHot`.
- For the form designer: `FormatIso` / `ParseIso` (the ISO pair, for callbacks), `SetDateParts`,
  `SetMinDate` / `SetMaxDate` (rows hold numbers, not a TKDATE), the border following the theme's
  BorderWidth until `SetBorderThickness` (which now pins the shape), and `PaintDefault` /
  `PaintDayDefault` (the stock drawing, for paint callbacks).

**Dropped (Win32-only):**
- `FilterMessage`. The host routes Escape, dismisses on an outside press, and closes popups
  150 ms after focus leaves the application.
- The 100 ms foreground poll.
- `SetTooltipMode` / `GetTooltipMode` / `GetPsTooltipHandle`; `GetTooltipHandle` now returns
  the `TK_TIP ptr`.
- `TestPrepareCalendar` and `GetDatePickerCalPointer`: open it and use tkCalendar's own
  queries instead.
- `DTP_CM_*`, `DTP_HIT_*`, `WS_EX_CONTROLPARENT`, `CS_DBLCLKS`, PsRegistry.
- `Rescale(oldDpi, newDpi)`, replaced by `TKM_SCALECHANGED`. Metrics are multiplied by
  fNew/fOld, the hairlines are not, and an open calendar closes.

**Shared change:** `tkHost_PressSerial()`, a counter bumped for each press before the
dismissal rule runs. It is the reopen guard's only input.

**Not verified:**
- a real second monitor (the flip-above placement);
- IME composition in the field (tkTextBox's own limits);
- the interactive pass.
