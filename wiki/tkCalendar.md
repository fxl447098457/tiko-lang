[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkCalendar**

# tkCalendar

Draws a month calendar, one month or a grid of up to twelve, with drill-down to years.

`tkCalendar` is the [tkControls](Category-tkControls) date surface: a child control that shows
one month, or a grid of panels, under a shared navigation band, with one selectable day, an
optional min/max range and a drill-down from days to months to years. It is not a date field;
for typed entry with a drop-down calendar use [tkDatePicker](tkDatePicker), which embeds this
control.

Dates are `TKDATE` values (`wYear`, `wMonth`, `wDayOfWeek`, `wDay`), and the module carries the
date arithmetic to go with them (`tkCalendar_MakeDate`, `AddDays`, `AddMonths`, `DaysInMonth`,
`LocalToday` and more). The setters are silent; `tkCalendar_SelectDate` and
`tkCalendar_Activate` are the two notifying actions. Month and weekday names can be replaced for
localisation, individual day cells can be painted by a callback, and the whole renderer can be
replaced.

For a form designer, whose rows hold numbers and text rather than `TKDATE` values and arrays:
`tkCalendar_SetSelDateParts`, `SetMinDate` / `SetMaxDate` (a year of 0 removes that end),
`SetAnchorMonth` (the month shown), and `SetMonthNamesText` / `SetMonthAbbrevsText` /
`SetWeekdayAbbrevsText` (comma lists, Sunday first for the weekdays; an empty entry keeps that
name). The border follows the theme's `BorderWidth` until `SetBorderThickness` (a calendar starts
with none). In a paint callback, `tkCalendar_PaintDefault( p )` draws the stock content (the frame
is drawn either way); `PaintDayDefault` and `PaintMonthYearDefault` do the same for a day cell and a
month or year cell.

## Importing

```freebasic
#import "vendor/tkControls/tkCalendar"

using tkCalendar
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` for a paint
callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Cal_SelChange( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr, byval bHasDate as boolean )
    if bHasDate then print "selected " & pDate->wYear & "-" & pDate->wMonth & "-" & pDate->wDay
end sub

sub Cal_Activated( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr )
    print "chosen (Enter or double-click)"
end sub

dim as TKDATE today = tkCalendar_LocalToday()
dim as TKDATE stLo = tkCalendar_AddDays( today, -10 ), stHi = tkCalendar_AddDays( today, 45 )

dim as TK_WIDGET ptr cal = tkCalendar_Create( tkHost_Root( host ), 7000 )
tkCalendar_SetPanelGrid( cal, 2, 1 )                ' two months side by side
tkCalendar_SetNavStep( cal, 1 )                     ' the chevrons slide one month
tkCalendar_SetWeekStart( cal, CAL_MONDAY )
tkCalendar_SetRange( cal, stLo, stHi, true, true )
tkCalendar_SetSelDate( cal, today )                 ' silent: no callback
tkCalendar_SetSelChangeCallback( cal, @Cal_SelChange )
tkCalendar_SetDateActivatedCallback( cal, @Cal_Activated )

dim as long w, h
tkCalendar_GetIdealSize( cal, w, h )               ' valid before the control is sized
tkWidget_SetPos( cal, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
```

## Concepts

### The handle is a widget

`tkCalendar_Create( hParent, ctrlId )` makes the calendar a child of the `TK_WIDGET ptr` you
pass; for a top-level control pass `tkHost_Root( host )`. It returns the control's
`TK_WIDGET ptr` (0 when `hParent` is 0). Position and size it with `tkWidget_SetPos`. The control
is focusable, so it takes part in the host's Tab order, and a click on it takes the focus. It
captures nothing: every click acts on the button **down**, so there is no press to protect.

### Selection, anchor, and today are three different things

- **Selection**: the highlighted day. There may be none; that is a legal state
  (`tkCalendar_HasSelDate` returns FALSE).
- **Anchor**: the first displayed month. Its day component is always 1. Navigation moves the
  anchor; it does not move the selection.
- **Today**: read from the system clock (`tkCalendar_LocalToday`) at creation, and re-read by
  `tkCalendar_Refresh` so a calendar left on screen across midnight can correct itself.
  `tkCalendar_SetToday` fixes "today" to a date of your choosing (a server date, a test's pinned
  day) until the next `Refresh`.

### The panel grid

In `CAL_VIEW_DAYS` the control draws `nCols × nRows` month panels, **row-major** (panel `p` sits
at column `p mod nCols`, row `p \ nCols`), showing consecutive months starting at the anchor. The
product may not exceed 12.

```
client
├─ optional border
├─ padding on all four sides
├─ nav band:  [ prev ]      title      [ next ]
├─ nav gap
└─ panel grid, row-major, with horizontal and vertical gutters
      each panel: month caption / weekday row / 6 x 7 day cells
```

Two rules fall out of that and are worth knowing before the geometry surprises you:

- **The per-panel month caption is suppressed when there is only one panel.** At one panel the nav
  band's title already reads "January 2026", so the caption would just repeat it. Above one panel
  the title becomes a range ("Jan - Dec 2026") and each panel names itself. This means a
  one-panel calendar is exactly one caption shorter than a two-panel one.
- **In `CAL_VIEW_MONTHS` and `CAL_VIEW_YEARS` the panel grid does not exist.** The 3 × 4
  drill-down grid takes the whole area below the nav band, at every panel count.

### Cells stretch; ideal size is advice

The panel width is floor-divided by 7 and the body height by 6, so cells grow and shrink with the
control. Left-over pixels become a right and bottom margin.

`tkCalendar_GetIdealSize` computes the natural size from the minimum cell size and the layout
metrics. It is pure arithmetic and measures no text, so it answers correctly **before the control
has ever been sized**, which is exactly when you need it. Sizing below the ideal shrinks the
cells; nothing clips and no scrollbar appears.

```
panelIdealW = 7 * cellMinW
panelIdealH = captionH + weekdayH + 6 * cellMinH
idealW = 2*(pad + border) + nCols*panelIdealW + (nCols-1)*gutterX
idealH = 2*(pad + border) + navBandH + navGap + nRows*panelIdealH + (nRows-1)*gutterY
```

### Rects are derived, never set

Every rectangle the control exposes (nav band, chevrons, title, panels, weekday cells, day cells,
drill-down cells) is computed from the client rect and the layout metrics. You change the metrics;
the control recomputes the rects. Layout is lazy: a setter marks it dirty and the next paint or
geometry query does one pass, so there is no begin/end update pair to bracket a batch of changes.

### Sizes and scale

The layout metrics (`CCAL_PAD` through `CCAL_CELLMINH`) are multiplied by the host's scale once,
at creation. Every setter afterwards takes **raw pixels**; scale them yourself with
`tkHost_Scale` if you need to. When the window moves to a monitor with another scale the control
receives `TKM_SCALECHANGED` and rescales the metrics it holds by the ratio of the two scales, so
nothing needs calling. The border, chevron and focus-ring thicknesses are never scaled; the
chevron stroke is grown with the scale at paint time instead.

### Programmatic setters are silent

`tkCalendar_SetSelDate`, `ClearSelDate`, `SetAnchorDate`, `SetView`, `SetRange`, `SetPanelGrid`,
`SetToday` and every other setter change state without firing a callback. Only user interaction
(a click, a double-click, the wheel or a key) notifies. This lets you call a setter from inside
your own handler without re-entering it.

Two entry points are **actions**, not setters, and they do fire: `tkCalendar_SelectDate` and
`tkCalendar_Activate`. Their names say so.

### Mouse

| Gesture | Effect |
|---|---|
| Click a day | Selects it (fires `SelChange` if the selection changed). An out-of-range day does nothing. A leading or trailing day from a neighbouring month scrolls that month into view when it is not already shown. |
| Double-click a day | Selects it, then fires `DateActivated`. |
| Click a chevron | Moves one navigation step, unless that chevron is disabled. |
| Click the title | Zooms out: days → months → years. |
| Click a month or year cell | Zooms in: years → months → days. It does not select. |
| Wheel | One navigation step per notch: away from you shows the previous page, toward you the next. Stops at a disabled chevron. Sub-notch deltas from a precision touchpad accumulate rather than being dropped. |
| Hover | Lights the cell, title or chevron under the cursor. An out-of-range day and a disabled chevron never light. |

A disabled calendar ignores clicks and the wheel and lights nothing.

### Focus and the keyboard

The control paints a focus ring on the current cell while it has the keyboard focus. In
`CAL_VIEW_DAYS` the arrow keys move the **selection** directly, scrolling the page when the
selection leaves it; there is no separate focus cursor to keep track of.

| Key | Effect |
|---|---|
| ← → | selection ∓ 1 day |
| ↑ ↓ | selection ∓ 1 week |
| PgUp / PgDn | ∓ 1 month |
| Ctrl+PgUp / Ctrl+PgDn | ∓ 1 year |
| Home / End | first / last day of the selection's month |
| Ctrl+Home | today |
| Space / Enter | fire `DateActivated` |
| Esc | back one level toward the days view, **only** while drilled down |

Ctrl is the platform's primary modifier (`TK_KMOD_PRIMARY`), so it is Cmd on macOS. Every move
clamps to the min/max range and to the years 1..9999.

In the drill-down views the arrows move a cell cursor instead (`tkCalendar_GetMyFocus`), Home and
End jump to the first and last cell, PgUp and PgDn page by a year (months view) or a decade
(years view), Space and Enter zoom in, and Esc goes back one level (years → months → days).

A key the calendar does not claim is not consumed and goes on to the parent widget, so Esc in
`CAL_VIEW_DAYS` still reaches the window (a dialog's Cancel keeps working). A disabled calendar
claims no keys.

When nothing is selected, the focus ring falls back to today if it is on the page, and otherwise
to the first day of the first panel. `tkCalendar_GetFocusCell` reports where it is.

## Behaviour and limits

- **Single selection only.** One date or none. There is no multi-select and no contiguous range
  selection; `stMin`/`stMax` restrict what is *selectable*, they are not a selected range.
- **At most 12 panels.** `tkCalendar_SetPanelGrid` **refuses** (and leaves the grid untouched)
  when `nCols * nRows` exceeds 12 or either dimension is below 1. It does not silently clamp.
- **Six week rows, always.** Each month is a fixed 6 × 7 grid, so the control's natural height
  never changes as you navigate. Months needing only four or five weeks show more adjacent days.
- **Out-of-range days are inert, not just dim.** They do not highlight on hover and clicking them
  does nothing.
- **`tkCalendar_SetSelDate` refuses a date outside the range**, and narrowing the range **drops** a
  selection that no longer fits. The setter cannot reach anywhere the user could not.
- **Drilling in never selects.** Picking a month or a year navigates; it does not change the
  selection or fire `SelChange`.
- **Years 1 to 9999.** Navigation and the anchor are clamped to `CCAL_MIN_YEAR` ..
  `CCAL_MAX_YEAR`.
- **No week-number column**, no "Today" footer button, and no variable row count.
- **Adjacent and out-of-range days must stay far apart in colour.** An adjacent day (a leading or
  trailing day from a neighbouring month) is dimmed but still clickable; an out-of-range day is
  inert. If you restyle `DayColorAdjacent` and `DayColorDisabled` to similar values, a restricted
  range reads as a broken calendar.
- **Colours follow the theme until you set them.** See [Colors](#colors).

## API reference

### Creation

| Function | Behaviour |
|---|---|
| `tkCalendar_Create( hParent as TK_WIDGET ptr, ctrlId as long ) as TK_WIDGET ptr` | Creates the control as a child of `hParent`. Position it yourself with `tkWidget_SetPos`. Returns 0 when `hParent` is 0. |

### Selection

All silent unless marked otherwise.

| Function | Behaviour |
|---|---|
| `tkCalendar_GetSelDate( hCtrl, byref st as TKDATE ) as boolean` | FALSE when nothing is selected; `st` untouched. |
| `tkCalendar_SetSelDate( hCtrl, byref st as TKDATE )` | Selects `st` and brings its month into view. **Refuses** a date outside the range. |
| `tkCalendar_SetSelDateParts( hCtrl, y, m, d )` | The same from numbers. A day past the month's end becomes its last day; invalid parts (a year below 1, a bad month or day) are ignored. |
| `tkCalendar_ClearSelDate( hCtrl )` | Returns to the no-selection state. |
| `tkCalendar_HasSelDate( hCtrl ) as boolean` | Whether anything is selected. |
| `tkCalendar_SelectDate( hCtrl, byref st as TKDATE )` | **Action: fires `SelChange`** (when the selection changes). Selects as if the user had clicked. Ignored when out of range. |
| `tkCalendar_Activate( hCtrl )` | **Action: fires `DateActivated`** for the current selection. Does nothing when there is no selection. The door for a host accelerator. |
| `tkCalendar_GetRange( hCtrl, byref stMin, byref stMax, byref bHasMin as boolean, byref bHasMax as boolean )` | Current min/max and whether each is set. |
| `tkCalendar_SetRange( hCtrl, byref stMin, byref stMax, bHasMin as boolean, bHasMax as boolean )` | Sets the selectable range. An inverted pair is **swapped**, not rejected. A selection now outside the range is **dropped**. |
| `tkCalendar_SetMinDate( hCtrl, y, m, d )` / `tkCalendar_SetMaxDate( hCtrl, y, m, d )` | One end of the range from numbers, keeping the other. A year of 0 removes that end. |
| `tkCalendar_GetToday( hCtrl, byref st as TKDATE ) as boolean` | Today's date as the control sees it. |
| `tkCalendar_SetToday( hCtrl, byref st as TKDATE )` | Fixes "today" (the today ring, Ctrl+Home, the focus fallback) until `tkCalendar_Refresh` returns to the clock. |

### Displayed page

| Function | Behaviour |
|---|---|
| `tkCalendar_GetAnchorDate( hCtrl, byref st as TKDATE ) as boolean` | The first displayed month; day component is always 1. |
| `tkCalendar_SetAnchorDate( hCtrl, byref st as TKDATE )` | Scrolls to that month. The day component is discarded. |
| `tkCalendar_SetAnchorMonth( hCtrl, y, m )` | The same from numbers. Invalid parts are ignored. |
| `tkCalendar_GetView( hCtrl ) as long` | `CAL_VIEW_DAYS`, `CAL_VIEW_MONTHS` or `CAL_VIEW_YEARS`. |
| `tkCalendar_SetView( hCtrl, eView as long )` | Switches view and seeds the drill-down cursor. Ignores an out-of-range value. |
| `tkCalendar_GetTitleText( hCtrl ) as ustring` | The nav band's caption for the current view and page: `"January 2026"`, `"Jan - Dec 2026"`, `"2026"`, `"2020 - 2029"`. Honours your localized names. |

### Behaviour

| Function | Behaviour |
|---|---|
| `tkCalendar_GetWeekStart( hCtrl ) as long` | `CAL_SUNDAY` or `CAL_MONDAY`. |
| `tkCalendar_SetWeekStart( hCtrl, nWeekStart as long )` | Anything other than `CAL_MONDAY` is treated as `CAL_SUNDAY`. Rotates the whole grid. |
| `tkCalendar_GetPanelGrid( hCtrl, byref nCols as long, byref nRows as long )` | Current grid shape. |
| `tkCalendar_SetPanelGrid( hCtrl, nCols as long, nRows as long )` | **Refuses** and changes nothing when either dimension is below 1 or the product exceeds 12. |
| `tkCalendar_GetPanelCount( hCtrl ) as long` | `nCols * nRows`, the number of months displayed. |
| `tkCalendar_GetNavStep( hCtrl ) as long` | The configured step. 0 means "one page". |
| `tkCalendar_SetNavStep( hCtrl, nStep as long )` | 0 (the default) = a chevron advances by the whole page, so a one-panel calendar steps a month and a twelve-panel grid steps a year. A positive value steps that many months regardless of panel count: `SetNavStep(1)` on a two-panel calendar gives the sliding range-picker idiom. Negatives are clamped to 0. In the drill-down views a step is a year (months) or a decade (years). |
| `tkCalendar_GetShowTodayRing( hCtrl ) as boolean` | Whether today's cell gets an outline. |
| `tkCalendar_SetShowTodayRing( hCtrl, bShow as boolean )` | Default TRUE. |
| `tkCalendar_IsPrevDisabled( hCtrl ) as boolean` | TRUE when the previous chevron would reveal nothing selectable. |
| `tkCalendar_IsNextDisabled( hCtrl ) as boolean` | Likewise for next. Both account for the panel count: with two panels stepping one month, "next" only dies when the genuinely *new* month falls outside the range, one month later than a single-panel calendar would. |

### Localization

The control ships English names. Any entry you set overrides that one; setting an entry to `""`
reverts it. Weekday entries are indexed by **day of week** (0 = Sunday), never by column, so an
override follows the day through a week-start change.

| Function | Behaviour |
|---|---|
| `tkCalendar_GetMonthName( hCtrl, m as long ) as ustring` | Full month name, `m` = 1..12. Empty string for a bad index. |
| `tkCalendar_SetMonthName( hCtrl, m as long, sName as ustring )` | Used for panel captions and the single-panel title. |
| `tkCalendar_GetMonthAbbrev( hCtrl, m as long ) as ustring` | Short month name, `m` = 1..12. |
| `tkCalendar_SetMonthAbbrev( hCtrl, m as long, sName as ustring )` | Used for multi-panel range titles and the `CAL_VIEW_MONTHS` cells. |
| `tkCalendar_GetWeekdayAbbrev( hCtrl, i as long ) as ustring` | `i` = 0 (Sunday) .. 6 (Saturday). |
| `tkCalendar_SetWeekdayAbbrev( hCtrl, i as long, sName as ustring )` | The weekday header row. |
| `tkCalendar_SetMonthNames( hCtrl, sNames() as ustring )` | Bulk form. Reads from `lbound` upward, mapping the first element to January; a short array leaves the tail alone. |
| `tkCalendar_SetMonthAbbrevs( hCtrl, sNames() as ustring )` | Bulk form, first element = January. |
| `tkCalendar_SetWeekdayAbbrevs( hCtrl, sNames() as ustring )` | Bulk form, first element = **Sunday**. |
| `tkCalendar_SetMonthNamesText` / `SetMonthAbbrevsText` / `SetWeekdayAbbrevsText( hCtrl, sNames as ustring )` | The bulk forms from one comma-separated list (Sunday first for the weekdays). An empty entry keeps that name. |

### Layout and appearance

| Function | Behaviour |
|---|---|
| `tkCalendar_GetFont( hCtrl ) as TTF_Font ptr` | The main font, or 0 when none is set (the host's default font is drawn). |
| `tkCalendar_SetFont( hCtrl, f as TTF_Font ptr )` | Sets all three fonts at once and **clears** any title and weekday overrides. Call this first, then the overrides. The font is borrowed; the control never frees it. |
| `tkCalendar_GetTitleFont( hCtrl ) as TTF_Font ptr` | The title/caption font, resolved: returns the main font when no override is set. |
| `tkCalendar_SetTitleFont( hCtrl, f as TTF_Font ptr )` | Nav band title and panel captions. 0 reverts to the main font. |
| `tkCalendar_GetWeekdayFont( hCtrl ) as TTF_Font ptr` | The weekday-row font, resolved. |
| `tkCalendar_SetWeekdayFont( hCtrl, f as TTF_Font ptr )` | The weekday header row. 0 reverts to the main font. |
| `tkCalendar_ApplyFonts( hCtrl, fText, fGlyph )` | The form's fonts: `fText` (when non-zero) becomes the main font as `SetFont` would. `fGlyph` is unused; the chevrons are drawn, not glyphs. |
| `tkCalendar_GetBorderThickness( hCtrl ) as long` | Frame thickness in pixels. |
| `tkCalendar_SetBorderThickness( hCtrl, nThickness as long )` | Non-zero strokes a rectangle just inside the client and shrinks the drawable area by that much on every side; 0 means no frame. Negatives are clamped to 0. Until this is called the thickness follows the theme's `BorderWidth` (0 when the theme sets none); once called, the theme leaves it alone. |
| `tkCalendar_GetChevronThickness( hCtrl ) as long` | Nav glyph stroke weight. |
| `tkCalendar_SetChevronThickness( hCtrl, nThickness as long )` | Default 2, clamped to a minimum of 1. Appearance only: the chevron cell does not move. |
| `tkCalendar_GetPadding( hCtrl ) as long` | Inset on all four sides, inside any border. |
| `tkCalendar_SetPadding( hCtrl, nPad as long )` | Negatives clamped to 0. Changes the ideal size. |
| `tkCalendar_GetGutters( hCtrl, byref nGutterX as long, byref nGutterY as long )` | Spacing between panels. |
| `tkCalendar_SetGutters( hCtrl, nGutterX as long, nGutterY as long )` | Negatives clamped to 0. Only visible above one panel. |
| `tkCalendar_GetCellMinSize( hCtrl, byref nW as long, byref nH as long )` | The day-cell size used for the ideal-size calculation. |
| `tkCalendar_SetCellMinSize( hCtrl, nW as long, nH as long )` | Feeds `GetIdealSize` **only**. Cells stretch to the control's actual size, so raising this does not enlarge a control that is already sized; it changes what "ideal" means. Clamped to a minimum of 1. |
| `tkCalendar_GetIdealSize( hCtrl, byref nWidth as long, byref nHeight as long )` | The natural size. Pure arithmetic, valid before the control has ever been sized. |
| `tkCalendar_GetEnabled( hCtrl ) as boolean` | Enabled state. |
| `tkCalendar_SetEnabled( hCtrl, isEnabled as boolean )` | Goes through `tkWidget_Enable`, so the host enforces it: no input, and Tab skips the control. |
| `tkCalendar_HasFocus( hCtrl ) as boolean` | Whether the control currently has keyboard focus. |
| `tkCalendar_Refresh( hCtrl )` | Re-reads today's date from the system clock and repaints. |

### Geometry

Each of these (except `GetMyFocus` and `GetHot`) forces any pending layout before answering, and
returns FALSE for a bad handle or an out-of-range index.

| Function | Behaviour |
|---|---|
| `tkCalendar_HitTest( hCtrl, pt as TKPOINT ) as CAL_HITRESULT` | Resolves a client-coordinate point to a part. Identity only: it reports a day cell even when that day is out of range. |
| `tkCalendar_GetInnerRect( hCtrl, byref rc as TKRECT ) as boolean` | Client less border and padding. |
| `tkCalendar_GetNavBandRect( hCtrl, byref rc as TKRECT ) as boolean` | The whole prev/title/next band. |
| `tkCalendar_GetPrevRect( hCtrl, byref rc as TKRECT ) as boolean` | The previous chevron's cell. |
| `tkCalendar_GetNextRect( hCtrl, byref rc as TKRECT ) as boolean` | The next chevron's cell. |
| `tkCalendar_GetTitleRect( hCtrl, byref rc as TKRECT ) as boolean` | The clickable title, between the chevrons. |
| `tkCalendar_GetGridRect( hCtrl, byref rc as TKRECT ) as boolean` | Everything below the nav band. |
| `tkCalendar_GetPanelRect( hCtrl, panel as long, byref rc as TKRECT ) as boolean` | One month panel, `panel` = 0..`GetPanelCount()-1`. |
| `tkCalendar_GetCaptionRect( hCtrl, panel as long, byref rc as TKRECT ) as boolean` | That panel's month caption. **Empty when there is only one panel.** |
| `tkCalendar_GetWeekdayRect( hCtrl, panel as long, i as long, byref rc as TKRECT ) as boolean` | Weekday header cell, `i` = 0..6 by **column**. |
| `tkCalendar_GetDayCellRect( hCtrl, panel as long, k as long, byref rc as TKRECT ) as boolean` | Day cell, `k` = 0..41, row-major within the 6 × 7 grid. |
| `tkCalendar_GetMyCellRect( hCtrl, k as long, byref rc as TKRECT ) as boolean` | Drill-down cell, `k` = 0..11. Empty while in `CAL_VIEW_DAYS`. |
| `tkCalendar_GetCellDate( hCtrl, panel as long, k as long, byref st as TKDATE ) as boolean` | The date a day cell represents, including leading and trailing days from neighbouring months. |
| `tkCalendar_GetPanelMonth( hCtrl, panel as long, byref nYear as long, byref nMonth as long ) as boolean` | Which month a panel is showing. |
| `tkCalendar_GetFocusCell( hCtrl, byref panel as long, byref index as long ) as boolean` | Where the focus ring sits. FALSE in the drill-down views. Falls back through selection → today → first day of panel 0. |
| `tkCalendar_GetMyFocus( hCtrl ) as long` | The drill-down cursor, 0..11. Meaningless in `CAL_VIEW_DAYS`. |
| `tkCalendar_GetHot( hCtrl ) as CAL_HITRESULT` | The part under the cursor, as the renderer sees it (inert days and disabled chevrons are never hot). |

### Callback registration

| Function | Behaviour |
|---|---|
| `tkCalendar_SetSelChangeCallback( hCtrl, usersub as CAL_SelChangeCallbackSub )` | User-driven selection changes. |
| `tkCalendar_SetDateActivatedCallback( hCtrl, usersub as CAL_DateActivatedCallbackSub )` | Double-click, Enter, Space. |
| `tkCalendar_SetViewChangeCallback( hCtrl, usersub as CAL_ViewChangeCallbackSub )` | The user moved the page or changed the view. |
| `tkCalendar_SetPaintCallback( hCtrl, usersub as CAL_PaintCallbackSub )` | Replaces the whole renderer. |
| `tkCalendar_SetDayPaintCallback( hCtrl, usersub as CAL_DayPaintCallbackSub )` | Replaces one day cell's painting. |
| `tkCalendar_SetMonthYearPaintCallback( hCtrl, usersub as CAL_MonthYearPaintCallbackSub )` | Replaces one drill-down cell's painting. |
| `tkCalendar_SetMessageCallback( hCtrl, userfunc as CAL_MessageCallbackFunc )` | Observe or suppress messages. |
| `tkCalendar_SetTooltipCallback( hCtrl, userfunc as CAL_TooltipCallbackFunc )` | Supply tooltip text for day cells. Setting it is what lets a tip exist at all. |

Pass 0 to any of these to remove the callback.

### Default painters

For a paint callback that wants the stock drawing and then adds to it.

| Function | Behaviour |
|---|---|
| `tkCalendar_PaintDefault( p as TKCALENDAR_PAINTINFO ptr )` | Draws the control's stock content into `p->b`. The background and frame are drawn either way. |
| `tkCalendar_PaintDayDefault( p as TKCALENDAR_DAYPAINTINFO ptr )` | Draws one stock day cell. |
| `tkCalendar_PaintMonthYearDefault( p as TKCALENDAR_MYPAINTINFO ptr )` | Draws one stock month or year cell. |

### Tooltips

| Function | Behaviour |
|---|---|
| `tkCalendar_GetTooltipHandle( hCtrl ) as TK_TIP ptr` | The calendar's [tkTooltip](tkTooltip), or **0 until a tip has actually been built**. |

The tip is *tracked*: the control resolves the text for the day cell under the cursor, shows the
tip against that cell at once and hides it when the cursor leaves the day cells or the control,
or on a click. There is no dwell and the tip does not pop away on its own. An out-of-range day,
and a disabled calendar, show no tip.

The tip is also lazy. It is built on the first day cell whose callback returns text, and never at
all for a calendar with no `TooltipCallback`, so `tkCalendar_GetTooltipHandle` returns 0 on a fresh
control; that is correct, not a failure. Removing the callback hides any tip that is showing.

### Colours

| Function | Behaviour |
|---|---|
| `tkCalendar_GetColors( hCtrl, pColors as TKCALENDAR_COLORS ptr )` | Copies the current palette out. |
| `tkCalendar_SetColors( hCtrl, pColors as TKCALENDAR_COLORS ptr )` | Copies a palette in, repaints, and **pins** it: a theme change leaves this calendar alone until `UnpinColors`. Read-modify-write: get, assign the fields you care about, set. |
| `tkCalendar_ThemeColors( byref t as TKTHEME_COLORS ) as TKCALENDAR_COLORS` | The palette a theme gives a calendar. |
| `tkCalendar_ApplyTheme( hCtrl, byref t as TKTHEME_COLORS )` | Re-applies the theme's border thickness (unless `SetBorderThickness` has been called) and, unless the colours are pinned, the palette from `t`. The control calls it itself on `TKM_THEMECHANGED`. |
| `tkCalendar_UnpinColors( hCtrl )` | Drops a pinned palette and returns to the current theme's. |

### Date helpers

Pure functions of their inputs: no control handle, usable anywhere. Serials are days since
1970‑01‑01, proleptic Gregorian, and may be negative.

| Function | Behaviour |
|---|---|
| `tkCalendar_IsLeapYear( y as long ) as boolean` | Gregorian leap-year rule. |
| `tkCalendar_DaysInMonth( y as long, m as long ) as long` | 28–31; returns 30 for an out-of-range month. |
| `tkCalendar_DateToSerial( y as long, m as long, d as long ) as longint` | Day serial. |
| `tkCalendar_SerialToDate( serial as longint, byref y as long, byref m as long, byref d as long )` | The inverse. |
| `tkCalendar_DowSunday( y as long, m as long, d as long ) as long` | Day of week, 0 = Sunday .. 6 = Saturday. |
| `tkCalendar_LeadingCells( y as long, m as long, nWeekStart as long ) as long` | Grid column of the 1st of that month. |
| `tkCalendar_MakeDate( y as long, m as long, d as long ) as TKDATE` | Builds a `TKDATE` with `wDayOfWeek` filled in. |
| `tkCalendar_AddMonths( byref st as TKDATE, delta as long ) as TKDATE` | **Clamps the day** to the target month's length: 31 Jan + 1 month = 28 Feb. |
| `tkCalendar_AddDays( byref st as TKDATE, delta as long ) as TKDATE` | Straight serial arithmetic, so every rollover is handled. |
| `tkCalendar_DecadeBase( y as long ) as long` | The decade's first year: 2026 → 2020. |
| `tkCalendar_LocalToday() as TKDATE` | Today's local date from the system clock. |

### Render probes

For asserting that a paint callback of your own is drawing rather than flooding. Each renders the
whole control (background, content, frame) into the host's back buffer at the widget's place
through the same path a paint uses, and reads the part back before anything is presented; the
host repaints afterwards. `nPart` is a `CAL_PART_*` value, or `CAL_PART_MYCELL_BASE + k` for
drill-down cell `k`, or `CAL_PART_DAYCELL_BASE + panel*100 + k` for day cell `k` of a panel. Each
returns 0 for an unknown or empty part.

| Function | Behaviour |
|---|---|
| `tkCalendar_TestPartTones( hCtrl, nPart as long ) as long` | Distinct colours in a part, capped at 256. A flooded part reports 1 or 2. |
| `tkCalendar_TestPartBrightness( hCtrl, nPart as long ) as long` | Brightest pixel (mean of R, G and B), 0..255. Compare two parts as a **ratio**, not a difference. |
| `tkCalendar_TestHashPart( hCtrl, nPart as long ) as ulongint` | FNV-1a over a part's pixels, for checking that a state change reached the pixels. A changed hash only proves *something* moved; a destroyed render changes it too, so pair it with a tone count. |

## Colors

`TKCALENDAR_COLORS` is a flat struct of ARGB `ulong` fields. A new calendar takes its palette from
the host's [theme](tkTheme) (`tkCalendar_ThemeColors`) and
follows theme changes until `tkCalendar_SetColors` pins it. Read it, assign, and write it back:

```freebasic
dim as TKCALENDAR_COLORS colors
tkCalendar_GetColors( cal, @colors )
colors.DayBackColorSelected = &hFF0078D7ul
colors.DayForeColorSelected = &hFFFFFFFFul
tkCalendar_SetColors( cal, @colors )
```

### Chrome

| Field | Theme role | Paints | When |
|---|---|---|---|
| `BackColor` | `Window` | The whole client, before anything else | Always |
| `BorderColor` | `Border` | The frame | Only when the border thickness is non-zero |
| `FocusRingColor` | `FocusRing` | A ring around the current cell | Only while the control has keyboard focus |
| `TitleColor` | `TextHot` | The nav band title | Idle |
| `TitleColorHot` | `TextStrong` | The nav band title | Cursor over the title |
| `CaptionColor` | `Text` | A panel's own month caption | Two or more panels |
| `NavGlyphColor` | `Text` | Both chevrons | Idle |
| `NavGlyphColorHot` | `TextHot` | One chevron | Cursor over it, and it is not disabled |
| `NavGlyphColorDisabled` | `TextDisabled` | One chevron | That direction would reveal nothing selectable |
| `WeekdayColor` | `TextDim` | The weekday header row | Always |

### Day cells

| Field | Theme role | Paints | When |
|---|---|---|---|
| `DayColor` | `Text` | The day number | Ordinary weekday of the panel's own month |
| `DayColorWeekend` | `AccentHot` | The day number | Saturday or Sunday of the panel's own month |
| `DayColorAdjacent` | `TextDim` | The day number | A leading or trailing day from a neighbouring month: **dimmed but still clickable** |
| `DayColorDisabled` | `TextDisabled` | The day number | Outside the min/max range: inert |
| `DayBackColorHot` | `SurfaceHot` | A rounded chip behind the number | Cursor over an in-range cell |
| `DayForeColorHot` | `TextHot` | The day number | Same |
| `DayBackColorSelected` | `Selected` | A rounded chip behind the number | The selected day |
| `DayForeColorSelected` | `SelectedText` | The day number | Same |
| `TodayRingColor` | `Accent` | An outline on today's cell | Today, not selected, and `SetShowTodayRing` is on |

Day-number colour precedence, highest first:

```
disabled  >  selected  >  hot  >  adjacent  >  weekend  >  ordinary
```

The background chip has its own, shorter chain: `selected > hot > none`. A disabled cell never
gets a hot chip, so the range reads as unavailable rather than merely unselected.

`DayColorAdjacent` and `DayColorDisabled` should keep a clear luminance gap. Adjacent days are
clickable and out-of-range days are not; if you restyle these two to similar values, a restricted
range looks broken.

The drill-down cells reuse the day colours: `DayColor` for a normal cell, `DayColorAdjacent` for
the two decade-overhang years, and the selected and hot pairs as above.

## Callbacks

### Selection changed

```freebasic
type CAL_SelChangeCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr, byval bHasDate as boolean )
```

Fires when the user moves the selection: a click on a day, or any arrow / PgUp / PgDn / Home /
End keystroke that lands somewhere new (and `tkCalendar_SelectDate`). Silent for every
programmatic setter, and silent when a click or key lands on the date already selected.
`bHasDate` is FALSE when the selection was cleared.

### Date activated

```freebasic
type CAL_DateActivatedCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr )
```

The user chose a date: double-click, Enter, or Space (or `tkCalendar_Activate`). This is the
"act on it" signal: close the dialog, open the record. On a double-click it fires **after**
`SelChange`, so the selection you read inside it is already the new one. Pressing Enter or Space
with nothing selected commits the focus cell first (firing `SelChange`), then activates. It never
fires without a selection.

### View changed

```freebasic
type CAL_ViewChangeCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval eView as long, byval pAnchor as TKDATE ptr )
```

Fires after a user action moved the displayed page or changed the view: a chevron, the wheel, the
title, a drill-down cell, or a key that scrolled. `eView` and `pAnchor` are the new view and
anchor. It comes last: a click or key that both selects and scrolls fires `SelChange` (and
`DateActivated`) first, then this. Setters are silent.

### Day painting

```freebasic
type CAL_DayPaintCallbackSub as sub( byval p as TKCALENDAR_DAYPAINTINFO ptr )
```

Draws one day cell instead of the built-in painter. The control has already filled the whole
client with `BackColor` and set the main font, so you start from a known state. Call
`tkCalendar_PaintDayDefault( p )` to draw the stock cell and then add to it.

**Draw your additions, not a background.** A callback that fills a rectangle covering more than its
own cell erases what the control already drew.

The focus ring is drawn by the control *after* this callback returns, so ignoring `isFocused`
cannot make keyboard focus invisible. The flag is there so you can style around the ring.

**`isSelected` is true on exactly one cell per render**, and while there is a selection the focus
ring sits on that same cell. This matters when more than one month is displayed: a date on a month
boundary appears twice, as a real day in its own panel and as a dimmed leading or trailing day in
the neighbouring one, so testing `stDate` against the selected date yourself would highlight both
copies and leave the user unable to tell which cell the keyboard is on. The control resolves it to
the panel that **owns** the date, falling back to a neighbour that merely displays it, so the
selection is never shown twice and never disappears. Use the flag rather than comparing dates.

| Field | Meaning |
|---|---|
| `hCtrl` | This calendar |
| `b` | The `TK_PAINT` to draw into |
| `rcCell` | The cell's rectangle |
| `stDate` | The date this cell represents |
| `dayNumber` | 1..31, the number to draw |
| `panelIndex` | Which month panel, 0-based, row-major |
| `cellIndex` | 0..41 within that panel |
| `isAdjacent` | A leading or trailing day from a neighbouring month |
| `isWeekend` | Saturday or Sunday, from the cell's own date |
| `isToday` | |
| `isSelected` | True on **exactly one cell**, never two |
| `isHot` | The cursor is over this cell |
| `isFocused` | This is the focus cell and the control has focus |
| `isDisabled` | Outside the min/max range, so unclickable |
| `isEnabled` | The control as a whole |

### Drill-down cell painting

```freebasic
type CAL_MonthYearPaintCallbackSub as sub( byval p as TKCALENDAR_MYPAINTINFO ptr )
```

Draws one month or year cell in the drill-down views. `tkCalendar_PaintMonthYearDefault( p )`
draws the stock cell. The focus ring is drawn after this callback, as for day cells.

| Field | Meaning |
|---|---|
| `hCtrl` | This calendar |
| `b` | The `TK_PAINT` to draw into |
| `rcCell` | The cell's rectangle |
| `eView` | `CAL_VIEW_MONTHS` or `CAL_VIEW_YEARS` |
| `cellIndex` | 0..11 |
| `nValue` | Month 1..12, or the four-digit year |
| `wszLabel` | What the built-in painter would draw |
| `isSelected` | The cell holds the selected date's month (in the displayed year) or year |
| `isHot` | |
| `isFocused` | The drill-down cursor is here and the control has focus |
| `isDimmed` | `CAL_VIEW_YEARS` only: the leading and trailing decade overhang cells |
| `isEnabled` | |

### Whole-control painting

```freebasic
type CAL_PaintCallbackSub as sub( byval p as TKCALENDAR_PAINTINFO ptr )
```

Replaces the entire renderer. The control still fills the background before calling and still
strokes the frame afterwards, so those two cannot be lost; everything between is yours. Every
rectangle is already laid out. Call `tkCalendar_PaintDefault( p )` to draw the stock content and
then add to it.

| Field | Meaning |
|---|---|
| `hCtrl` | This calendar |
| `b` | The `TK_PAINT` to draw into |
| `rcClient` | The whole client area |
| `rcInner` | Client less border and padding |
| `rcNavBand` | The prev/title/next band |
| `rcPrev` | Previous chevron cell |
| `rcTitle` | Title cell |
| `rcNext` | Next chevron cell |
| `rcGrid` | Everything below the nav band |
| `eView` | Current view |
| `nCols`, `nRows` | Panel grid shape |
| `panelCount` | `nCols * nRows` |
| `isEnabled` | |
| `isFocused` | |
| `isPrevDisabled` | Previous chevron would reveal nothing selectable |
| `isNextDisabled` | Likewise for next |
| `hotPart` | `CAL_HIT_*` under the cursor |
| `hotPanel`, `hotIndex` | Which cell, when `hotPart` is a cell |

### Messages

```freebasic
type CAL_MessageCallbackFunc as function( byval m as TKCALENDAR_MESSAGEINFO ptr ) as boolean
```

Sees each message before the control acts on it. Return TRUE to suppress the default handling of
`TKM_PAINT`, `TKM_MOUSEMOVE`, `TKM_LBUTTONDOWN`, `TKM_MOUSEWHEEL` and `TKM_KEYDOWN`; for
`TKM_KEYDOWN` that means you can veto a navigation key before it moves anything. A disabled
calendar does not offer key messages to the callback.

The return value is **ignored** for `TKM_SIZE`, `TKM_MOUSELEAVE`, `TKM_LBUTTONUP`,
`TKM_RBUTTONDOWN`, `TKM_RBUTTONUP`, `TKM_SETFOCUS`, `TKM_KILLFOCUS`, `TKM_ENABLE` and
`TKM_DESTROY`: a callback must not be able to leave the control painted as focused when it is not,
or half-destroyed.

| Field | Meaning |
|---|---|
| `hCtrl` | This calendar |
| `msg` | The `TKM_*` message |
| `x`, `y` | The mouse position it carried |
| `key` | The key it carried |
| `mods` | The modifier keys |
| `clicks` | The click count (2 for a double-click) |

### Tooltips

```freebasic
type CAL_TooltipCallbackFunc as function( byval t as TKCALENDAR_TOOLTIPINFO ptr ) as boolean
```

Asked for text as the cursor moves onto a new day cell. Return TRUE having filled `outText`; an
empty string shows no tip. Day cells only: the chevrons and the title never ask. See
[Tooltips](#tooltips) above for how the tip is built and shown.

| Field | Meaning |
|---|---|
| `hCtrl` | This calendar |
| `stDate` | The day under the cursor |
| `isValid` | TRUE: the cursor is over a day cell |
| `outText` | Fill this with the tip text |

## Constants

### Week start

| Value | Meaning |
|---|---|
| `CAL_SUNDAY` | 0, the default |
| `CAL_MONDAY` | 1 |

### View

| Value | Meaning |
|---|---|
| `CAL_VIEW_DAYS` | The month grid, the default |
| `CAL_VIEW_MONTHS` | 3 × 4 month picker |
| `CAL_VIEW_YEARS` | 3 × 4 year picker, showing a decade plus one overhang year at each end |

### Hit-test parts

`tkCalendar_HitTest` returns a `CAL_HITRESULT` of `part`, `panel` and `index`.

| Value | `panel` / `index` |
|---|---|
| `CAL_HIT_NONE` | both −1 |
| `CAL_HIT_PREV` | — |
| `CAL_HIT_NEXT` | — |
| `CAL_HIT_TITLE` | — |
| `CAL_HIT_DAYCELL` | `panel` 0..11, `index` 0..41 |
| `CAL_HIT_MONTHCELL` | `index` 0..11 |
| `CAL_HIT_YEARCELL` | `index` 0..11 |

### Render-probe parts

| Value | Part |
|---|---|
| `CAL_PART_CLIENT` | The whole client |
| `CAL_PART_NAVBAND` | The nav band |
| `CAL_PART_PREV` | Previous chevron cell |
| `CAL_PART_NEXT` | Next chevron cell |
| `CAL_PART_TITLE` | Title cell |
| `CAL_PART_GRID` | Everything below the nav band |
| `CAL_PART_MYCELL_BASE + k` | Drill-down cell `k` (0..11) |
| `CAL_PART_DAYCELL_BASE + panel*100 + k` | Day cell `k` (0..41) of `panel` |

### Layout defaults

Logical pixels, multiplied by the host's scale once at creation.

| Constant | Default | What it is |
|---|---|---|
| `CCAL_PAD` | 8 | Padding on all four sides, inside any border |
| `CCAL_NAVBANDH` | 34 | Height of the prev/title/next band |
| `CCAL_NAVGAP` | 4 | Gap between the nav band and the panel grid |
| `CCAL_CHEVW` | 28 | Width of each chevron cell |
| `CCAL_GUTTERX` | 12 | Horizontal spacing between panels |
| `CCAL_GUTTERY` | 10 | Vertical spacing between panel rows |
| `CCAL_CAPTIONH` | 24 | A panel's own month caption |
| `CCAL_WEEKDAYH` | 22 | The weekday header row |
| `CCAL_CELLMINW` | 34 | Day cell width, for the ideal size only |
| `CCAL_CELLMINH` | 30 | Day cell height, for the ideal size only |

Not scaled:

| Constant | Default | What it is |
|---|---|---|
| `CCAL_DEFAULT_BORDERTHICK` | 0 | Frame thickness when the theme sets none; 0 means no frame |
| `CCAL_DEFAULT_CHEVTHICK` | 2 | Chevron stroke weight (grown with the scale at paint time) |
| `CCAL_DEFAULT_FOCUSTHICK` | 1 | Focus ring stroke weight |
| `CCAL_MY_COLS` | 3 | Drill-down grid columns |
| `CCAL_MY_ROWS` | 4 | Drill-down grid rows |
| `CCAL_MIN_YEAR` | 1 | Earliest year the calendar navigates to |
| `CCAL_MAX_YEAR` | 9999 | Latest year the calendar navigates to |
| `CCAL_MAX_PANELS` | 12 | Maximum `nCols * nRows` |

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const CCAL_PAD = 8
const CCAL_NAVBANDH = 34
const CCAL_NAVGAP = 4
const CCAL_CHEVW = 28
const CCAL_GUTTERX = 12
const CCAL_GUTTERY = 10
const CCAL_CAPTIONH = 24
const CCAL_WEEKDAYH = 22
const CCAL_CELLMINW = 34
const CCAL_CELLMINH = 30
const CCAL_DEFAULT_BORDERTHICK = 0
const CCAL_DEFAULT_CHEVTHICK = 2
const CCAL_DEFAULT_FOCUSTHICK = 1
const CCAL_MY_COLS = 3
const CCAL_MY_ROWS = 4
const CCAL_MIN_YEAR = 1
const CCAL_MAX_YEAR = 9999
const CCAL_MAX_PANELS = 12
const CAL_PART_MYCELL_BASE = 100
const CAL_PART_DAYCELL_BASE = 1000

enum
    CAL_SUNDAY = 0
    CAL_MONDAY = 1
end enum

enum
    CAL_VIEW_DAYS = 0
    CAL_VIEW_MONTHS
    CAL_VIEW_YEARS
end enum

enum
    CAL_HIT_NONE = 0
    CAL_HIT_PREV
    CAL_HIT_NEXT
    CAL_HIT_TITLE
    CAL_HIT_DAYCELL
    CAL_HIT_MONTHCELL
    CAL_HIT_YEARCELL
end enum

enum
    CAL_PART_CLIENT  = 0
    CAL_PART_NAVBAND = 1
    CAL_PART_PREV    = 2
    CAL_PART_NEXT    = 3
    CAL_PART_TITLE   = 4
    CAL_PART_GRID    = 5
end enum
```

### Types

```freebasic
type TKDATE
    wYear      as long
    wMonth     as long
    wDayOfWeek as long
    wDay       as long
end type

type CAL_HITRESULT
    part   as long = CAL_HIT_NONE
    panel  as long = -1
    index  as long = -1
end type

type TKCALENDAR_COLORS
    BackColor              as ulong = &hFF21252Bul
    BorderColor            as ulong = &hFF464C58ul
    FocusRingColor         as ulong = &hFF569CD6ul
    TitleColor             as ulong = &hFFE1E4EAul
    TitleColorHot          as ulong = &hFFFFFFFFul
    CaptionColor           as ulong = &hFFC8CDD5ul
    NavGlyphColor          as ulong = &hFFBEC4CEul
    NavGlyphColorHot       as ulong = &hFFFFFFFFul
    NavGlyphColorDisabled  as ulong = &hFF464A52ul
    WeekdayColor           as ulong = &hFF8C929Cul
    DayColor               as ulong = &hFFD2D6DCul
    DayColorWeekend        as ulong = &hFF96AFCDul
    DayColorAdjacent       as ulong = &hFF7C838Eul     ' still clickable: keep it far from Disabled
    DayColorDisabled       as ulong = &hFF383C44ul     ' out of range, inert
    DayBackColorHot        as ulong = &hFF343A44ul
    DayForeColorHot        as ulong = &hFFFFFFFFul
    DayBackColorSelected   as ulong = &hFF0078D7ul
    DayForeColorSelected   as ulong = &hFFFFFFFFul
    TodayRingColor         as ulong = &hFF569CD6ul
end type

type TKCALENDAR_PAINTINFO
    hCtrl          as TK_WIDGET ptr
    b              as TK_PAINT ptr
    rcClient       as TKRECT
    rcInner        as TKRECT
    rcNavBand      as TKRECT
    rcPrev         as TKRECT
    rcTitle        as TKRECT
    rcNext         as TKRECT
    rcGrid         as TKRECT
    eView          as long
    nCols          as long
    nRows          as long
    panelCount     as long
    isEnabled      as boolean
    isFocused      as boolean
    isPrevDisabled as boolean
    isNextDisabled as boolean
    hotPart        as long
    hotPanel       as long
    hotIndex       as long
end type

type TKCALENDAR_DAYPAINTINFO
    hCtrl       as TK_WIDGET ptr
    b           as TK_PAINT ptr
    rcCell      as TKRECT
    stDate      as TKDATE
    dayNumber   as long
    panelIndex  as long
    cellIndex   as long
    isAdjacent  as boolean
    isWeekend   as boolean
    isToday     as boolean
    isSelected  as boolean     ' exactly ONE cell per render
    isHot       as boolean
    isFocused   as boolean
    isDisabled  as boolean
    isEnabled   as boolean
end type

type TKCALENDAR_MYPAINTINFO
    hCtrl       as TK_WIDGET ptr
    b           as TK_PAINT ptr
    rcCell      as TKRECT
    eView       as long
    cellIndex   as long
    nValue      as long
    wszLabel    as ustring
    isSelected  as boolean
    isHot       as boolean
    isFocused   as boolean
    isDimmed    as boolean
    isEnabled   as boolean
end type

type TKCALENDAR_MESSAGEINFO
    hCtrl       as TK_WIDGET ptr
    msg         as long
    x           as single
    y           as single
    key         as long
    mods        as long
    clicks      as long
end type

type TKCALENDAR_TOOLTIPINFO
    hCtrl       as TK_WIDGET ptr
    stDate      as TKDATE
    isValid     as boolean
    outText     as ustring
end type

type TKCALENDAR_STATE   ' per-instance state; reach it through the procedures

type CAL_SelChangeCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr, byval bHasDate as boolean )
type CAL_DateActivatedCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr )
type CAL_PaintCallbackSub as sub( byval p as TKCALENDAR_PAINTINFO ptr )
type CAL_DayPaintCallbackSub as sub( byval p as TKCALENDAR_DAYPAINTINFO ptr )
type CAL_MonthYearPaintCallbackSub as sub( byval p as TKCALENDAR_MYPAINTINFO ptr )
type CAL_MessageCallbackFunc as function( byval m as TKCALENDAR_MESSAGEINFO ptr ) as boolean
type CAL_TooltipCallbackFunc as function( byval t as TKCALENDAR_TOOLTIPINFO ptr ) as boolean
type CAL_ViewChangeCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval eView as long, byval pAnchor as TKDATE ptr )
```

### Procedures

```freebasic
function tkCalendar_IsLeapYear( byval y as long ) as boolean
function tkCalendar_DaysInMonth( byval y as long, byval m as long ) as long
function tkCalendar_DateToSerial( byval y as long, byval m as long, byval d as long ) as longint
sub tkCalendar_SerialToDate( byval serial as longint, byref y as long, byref m as long, byref d as long )
function tkCalendar_DowSunday( byval y as long, byval m as long, byval d as long ) as long
function tkCalendar_LeadingCells( byval y as long, byval m as long, byval nWeekStart as long ) as long
function tkCalendar_MakeDate( byval y as long, byval m as long, byval d as long ) as TKDATE
function tkCalendar_AddMonths( byref st as TKDATE, byval delta as long ) as TKDATE
function tkCalendar_AddDays( byref st as TKDATE, byval delta as long ) as TKDATE
function tkCalendar_DecadeBase( byval y as long ) as long
function tkCalendar_LocalToday() as TKDATE
function tkCalendar_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkCalendar_GetSelDate( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE ) as boolean
sub tkCalendar_SetSelDate( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE )
sub tkCalendar_ClearSelDate( byval hCtrl as TK_WIDGET ptr )
function tkCalendar_HasSelDate( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkCalendar_SelectDate( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE )
sub tkCalendar_Activate( byval hCtrl as TK_WIDGET ptr )
sub tkCalendar_GetRange( byval hCtrl as TK_WIDGET ptr, byref stMin as TKDATE, byref stMax as TKDATE, byref bHasMin as boolean, byref bHasMax as boolean )
sub tkCalendar_SetRange( byval hCtrl as TK_WIDGET ptr, byref stMin as TKDATE, byref stMax as TKDATE, byval bHasMin as boolean, byval bHasMax as boolean )
function tkCalendar_GetToday( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE ) as boolean
sub tkCalendar_SetToday( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE )
function tkCalendar_GetAnchorDate( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE ) as boolean
sub tkCalendar_SetAnchorDate( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE )
function tkCalendar_GetView( byval hCtrl as TK_WIDGET ptr ) as long
sub tkCalendar_SetView( byval hCtrl as TK_WIDGET ptr, byval eView as long )
function tkCalendar_GetTitleText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkCalendar_GetWeekStart( byval hCtrl as TK_WIDGET ptr ) as long
sub tkCalendar_SetWeekStart( byval hCtrl as TK_WIDGET ptr, byval nWeekStart as long )
sub tkCalendar_GetPanelGrid( byval hCtrl as TK_WIDGET ptr, byref nCols as long, byref nRows as long )
sub tkCalendar_SetPanelGrid( byval hCtrl as TK_WIDGET ptr, byval nCols as long, byval nRows as long )
function tkCalendar_GetPanelCount( byval hCtrl as TK_WIDGET ptr ) as long
function tkCalendar_GetNavStep( byval hCtrl as TK_WIDGET ptr ) as long
sub tkCalendar_SetNavStep( byval hCtrl as TK_WIDGET ptr, byval nStep as long )
function tkCalendar_GetShowTodayRing( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkCalendar_SetShowTodayRing( byval hCtrl as TK_WIDGET ptr, byval bShow as boolean )
function tkCalendar_IsPrevDisabled( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkCalendar_IsNextDisabled( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkCalendar_GetMonthName( byval hCtrl as TK_WIDGET ptr, byval m as long ) as ustring
sub tkCalendar_SetMonthName( byval hCtrl as TK_WIDGET ptr, byval m as long, byval sName as ustring )
function tkCalendar_GetMonthAbbrev( byval hCtrl as TK_WIDGET ptr, byval m as long ) as ustring
sub tkCalendar_SetMonthAbbrev( byval hCtrl as TK_WIDGET ptr, byval m as long, byval sName as ustring )
function tkCalendar_GetWeekdayAbbrev( byval hCtrl as TK_WIDGET ptr, byval i as long ) as ustring
sub tkCalendar_SetWeekdayAbbrev( byval hCtrl as TK_WIDGET ptr, byval i as long, byval sName as ustring )
sub tkCalendar_SetMonthNames( byval hCtrl as TK_WIDGET ptr, sNames() as ustring )
sub tkCalendar_SetMonthAbbrevs( byval hCtrl as TK_WIDGET ptr, sNames() as ustring )
sub tkCalendar_SetWeekdayAbbrevs( byval hCtrl as TK_WIDGET ptr, sNames() as ustring )
function tkCalendar_GetFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCalendar_SetFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkCalendar_GetTitleFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCalendar_SetTitleFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkCalendar_GetWeekdayFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCalendar_SetWeekdayFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkCalendar_ApplyFonts( byval hCtrl as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
function tkCalendar_GetBorderThickness( byval hCtrl as TK_WIDGET ptr ) as long
sub tkCalendar_SetBorderThickness( byval hCtrl as TK_WIDGET ptr, byval nThickness as long )
function tkCalendar_GetChevronThickness( byval hCtrl as TK_WIDGET ptr ) as long
sub tkCalendar_SetChevronThickness( byval hCtrl as TK_WIDGET ptr, byval nThickness as long )
function tkCalendar_GetPadding( byval hCtrl as TK_WIDGET ptr ) as long
sub tkCalendar_SetPadding( byval hCtrl as TK_WIDGET ptr, byval nPad as long )
sub tkCalendar_GetGutters( byval hCtrl as TK_WIDGET ptr, byref nGutterX as long, byref nGutterY as long )
sub tkCalendar_SetGutters( byval hCtrl as TK_WIDGET ptr, byval nGutterX as long, byval nGutterY as long )
sub tkCalendar_GetCellMinSize( byval hCtrl as TK_WIDGET ptr, byref nW as long, byref nH as long )
sub tkCalendar_SetCellMinSize( byval hCtrl as TK_WIDGET ptr, byval nW as long, byval nH as long )
sub tkCalendar_GetIdealSize( byval hCtrl as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkCalendar_GetEnabled( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkCalendar_SetEnabled( byval hCtrl as TK_WIDGET ptr, byval isEnabled as boolean )
function tkCalendar_HasFocus( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkCalendar_Refresh( byval hCtrl as TK_WIDGET ptr )
function tkCalendar_HitTest( byval hCtrl as TK_WIDGET ptr, byval pt as TKPOINT ) as CAL_HITRESULT
function tkCalendar_GetInnerRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCalendar_GetNavBandRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCalendar_GetPrevRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCalendar_GetNextRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCalendar_GetTitleRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCalendar_GetGridRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCalendar_GetPanelRect( byval hCtrl as TK_WIDGET ptr, byval panel as long, byref rc as TKRECT ) as boolean
function tkCalendar_GetCaptionRect( byval hCtrl as TK_WIDGET ptr, byval panel as long, byref rc as TKRECT ) as boolean
function tkCalendar_GetWeekdayRect( byval hCtrl as TK_WIDGET ptr, byval panel as long, byval i as long, byref rc as TKRECT ) as boolean
function tkCalendar_GetDayCellRect( byval hCtrl as TK_WIDGET ptr, byval panel as long, byval k as long, byref rc as TKRECT ) as boolean
function tkCalendar_GetMyCellRect( byval hCtrl as TK_WIDGET ptr, byval k as long, byref rc as TKRECT ) as boolean
function tkCalendar_GetCellDate( byval hCtrl as TK_WIDGET ptr, byval panel as long, byval k as long, byref st as TKDATE ) as boolean
function tkCalendar_GetPanelMonth( byval hCtrl as TK_WIDGET ptr, byval panel as long, byref nYear as long, byref nMonth as long ) as boolean
function tkCalendar_GetFocusCell( byval hCtrl as TK_WIDGET ptr, byref panel as long, byref index as long ) as boolean
function tkCalendar_GetMyFocus( byval hCtrl as TK_WIDGET ptr ) as long
function tkCalendar_GetHot( byval hCtrl as TK_WIDGET ptr ) as CAL_HITRESULT
sub tkCalendar_GetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKCALENDAR_COLORS ptr )
sub tkCalendar_SetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKCALENDAR_COLORS ptr )
function tkCalendar_ThemeColors( byref t as TKTHEME_COLORS ) as TKCALENDAR_COLORS
sub tkCalendar_ApplyTheme( byval hCtrl as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkCalendar_UnpinColors( byval hCtrl as TK_WIDGET ptr )
sub tkCalendar_SetSelChangeCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CAL_SelChangeCallbackSub )
sub tkCalendar_SetDateActivatedCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CAL_DateActivatedCallbackSub )
sub tkCalendar_SetPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CAL_PaintCallbackSub )
sub tkCalendar_SetDayPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CAL_DayPaintCallbackSub )
sub tkCalendar_PaintDayDefault( byval p as TKCALENDAR_DAYPAINTINFO ptr )
sub tkCalendar_PaintDefault( byval p as TKCALENDAR_PAINTINFO ptr )
sub tkCalendar_PaintMonthYearDefault( byval p as TKCALENDAR_MYPAINTINFO ptr )
sub tkCalendar_SetSelDateParts( byval hCtrl as TK_WIDGET ptr, byval y as long, byval m as long, byval d as long )
sub tkCalendar_SetMinDate( byval hCtrl as TK_WIDGET ptr, byval y as long, byval m as long, byval d as long )
sub tkCalendar_SetMaxDate( byval hCtrl as TK_WIDGET ptr, byval y as long, byval m as long, byval d as long )
sub tkCalendar_SetAnchorMonth( byval hCtrl as TK_WIDGET ptr, byval y as long, byval m as long )
sub tkCalendar_SetMonthNamesText( byval hCtrl as TK_WIDGET ptr, byval sNames as ustring )
sub tkCalendar_SetMonthAbbrevsText( byval hCtrl as TK_WIDGET ptr, byval sNames as ustring )
sub tkCalendar_SetWeekdayAbbrevsText( byval hCtrl as TK_WIDGET ptr, byval sNames as ustring )
sub tkCalendar_SetMonthYearPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CAL_MonthYearPaintCallbackSub )
sub tkCalendar_SetMessageCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as CAL_MessageCallbackFunc )
sub tkCalendar_SetTooltipCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as CAL_TooltipCallbackFunc )
sub tkCalendar_SetViewChangeCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CAL_ViewChangeCallbackSub )
function tkCalendar_GetTooltipHandle( byval hCtrl as TK_WIDGET ptr ) as TK_TIP ptr
function tkCalendar_TestPartTones( byval hCtrl as TK_WIDGET ptr, byval nPart as long ) as long
function tkCalendar_TestPartBrightness( byval hCtrl as TK_WIDGET ptr, byval nPart as long ) as long
function tkCalendar_TestHashPart( byval hCtrl as TK_WIDGET ptr, byval nPart as long ) as ulongint
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkDatePicker](tkDatePicker), [tkTooltip](tkTooltip), [tkTheme](tkTheme)
