[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkDateTimePicker**

# tkDateTimePicker

Draws one field holding a date and a time: the year, month, day, hour, minute, second and AM/PM of
a pattern, each typed into and stepped on its own, with a dropdown that puts a calendar beside the
time columns (or a spin pair, or nothing).

`tkDateTimePicker` is the [tkControls](Category-tkControls) control for a moment: an appointment's
start, a deadline. Its frame, divider and button cell are [tkDatePicker](tkDatePicker)'s and
[tkTimePicker](tkTimePicker)'s, to the pixel, so the three line up in a form. The value is a
`TKDATETIME` ([tkTimePanel](tkTimePanel)'s), held apart from how it is shown. For a date alone use
tkDatePicker; for a time alone, tkTimePicker; for a date and a time in two fields, bind both to one
`chrono.DateTime`.

Every setter is silent. `DateTimeChanged` fires once for each change the user completes, never for
a half-typed entry and never for a pick in the dropdown that was not accepted. The Form Designer's
**DateTimePicker** binds the whole value to one field.

## Importing

```freebasic
#import "vendor/tkControls/tkDateTimePicker"

using tkDateTimePicker
using tkTimePanel
using tkHost
```

The module brings in [tkTimePanel](tkTimePanel) (`TKDATETIME`, the `tkTimePanel_*DateTime` helpers
and the pattern engine), [tkCalendar](tkCalendar), [tkHost](tkHost) (and through it
[tkPaint](tkPaint), SDL3, SDL_ttf and SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip).
`using tkTimePanel` names `TKDATETIME` and the `TKTP_*` constants. Add `using tkPaint` for a paint
callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Due_Changed( byval hCtrl as TK_WIDGET ptr, byval pDT as TKDATETIME ptr, byval bHasValue as boolean )
    if bHasValue then print "due " & tkTimePanel_FormatIsoDateTime( *pDT ) else print "no deadline"
end sub

dim as TK_WIDGET ptr dt = tkDateTimePicker_Create( tkHost_Root( host ), 100 )
tkDateTimePicker_SetFormat( dt, "ddd d MMM yyyy h:mm tt" )      ' Mon 23 Nov 2026 2:30 PM
tkDateTimePicker_SetWeekStart( dt, TKDTM_MONDAY )
tkDateTimePicker_SetStep( dt, 900 )                             ' 15 minutes
tkDateTimePicker_SetShowNow( dt, true )
tkDateTimePicker_SetDateTime( dt, tkTimePanel_MakeDateTime( 2026, 11, 23, 14, 30 ) )   ' silent
tkDateTimePicker_SetDateTimeChangedCallback( dt, @Due_Changed )

dim as long w, h
tkDateTimePicker_GetIdealSize( dt, w, h )                       ' valid before the control is sized
tkWidget_SetPos( dt, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
```

## The value

- A `TKDATETIME` is SYSTEMTIME's layout: `wYear`, `wMonth`, `wDayOfWeek`, `wDay`, `wHour`,
  `wMinute`, `wSecond`, `wMilliseconds`. **`wYear = 0` is no value**, and is its default.
  `tkTimePanel_MakeDateTime( y, mo, d, hh, mi, ss, ms )` fills the weekday, and gives no value for
  any part out of range.
- `GetDateTime` / `SetDateTime` / `ClearDateTime` / `HasDateTime`; `GetDateTimeValue` /
  `SetDateTimeValue` take and give it by value (the designer's bind pair).
  `SetDateTimeParts( y, mo, d, hh, mi, ss )` is for designer rows.
- **Setters keep every part**, as tkTimePicker's do; a **user** edit zeroes the parts the pattern
  does not show. A pattern with no time keeps a user's value at midnight.
- `SetRange( min, max )` (an inverted pair is swapped) is one range over date and time together,
  and clamps every route. `SetMinDateTime` / `SetMaxDateTime` take numbers, for designer rows.
- `SetAllowEmpty( false )` stops the user from clearing the field. `SetStep( seconds )` is
  tkTimePicker's: it sets the dropdown's minute or second items and the grid Up / Down snap to.

## The pattern

`SetFormat( pattern )`, default `yyyy-MM-dd HH:mm`. The time tokens are
[tkTimePicker](tkTimePicker)'s (`H` `HH` `h` `hh` `m` `mm` `s` `ss` `f`… `t` `tt`); the date tokens:

| Token | Shows |
| --- | --- |
| `yyyy` `yy` | the year, four digits or the last two |
| `M` `MM` | the month number, one or two digits |
| `MMM` `MMMM` | the month's short or full name |
| `d` `dd` | the day, one or two digits |
| `ddd` `dddd` | the weekday's short or full name (shown, never edited) |
| `'text'` | text as it is |

`SetMonthNames( "January,…,December|Jan,…,Dec" )` and `SetDayNames( "Sunday,…|Sun,…" )`
(Sunday first) translate the names; the part after `|` is the short names, and without it they
stay as they were. `GetMonthName( m, bShort )` reads one. `SetAmPmText`, `SetPlaceholderText` and
`GetText` are tkTimePicker's. `SetFormatCallback` (**FormatDateTime**) replaces the text at rest,
as tkTimePicker's FormatTime does.

## Typing and keys

The keys are tkTimePicker's, with the date segments added:

- **The year** takes four digits (`yy` takes two, 20xx). **The month** completes at once on 2–9,
  the **day** on 4–9; otherwise the second digit completes it, and an impossible pair (`15` for a
  month) starts over with its last digit. The day's limit is the days in the shown month.
- **A month name** takes letters: they search the names from the start (`j` `u` `l` finds July),
  and the search restarts after a one-second pause.
- `-` `/` `:` `.` and space finish an entry and move on. **The weekday** is skipped.
- **Up / Down** wrap inside the segment with no carry: day 31 goes to day 1 and the month stays.
  **Page Up / Page Down** move 10 years, 3 months or 7 days, and on the time segments what tkTimePicker's do. Changing the
  month or the year clamps the day: 31 January, Up on the month, is 28 February.
- On an empty field the first step lands on today at 00:00 (clamped to the range).
- **Ctrl+C** copies the pattern's text; **Ctrl+V** pastes an ISO date with an optional time in any
  form tkTimePicker pastes (`2026-12-24 6:30 pm`), or a time alone, which keeps the date.

## The button cell

`SetButtonStyle`: `TKDTM_BUTTON_DROPDOWN` (default; **F4** and **Alt+Down** open it too),
`TKDTM_BUTTON_SPIN` (an up and a down chevron step the focused segment, repeating while held) or
`TKDTM_BUTTON_NONE`. `SetIconFont` plus `SetIconGlyph` replace the drawn clock.

## The dropdown

- A [tkCalendar](tkCalendar) on the left, a [tkTimePanel](tkTimePanel)'s columns on the right (as
  tall as the calendar), and a band with **OK**, and **Now** with `SetShowNow( true )`. The
  calendar takes the week start (`SetWeekStart( TKDTM_SUNDAY / TKDTM_MONDAY )`), the month names and
  the range's dates. It opens with the calendar focused, or the panel when the field's focus was on
  a time segment.
- **A pick in either part is pending: the field does not change** until the user accepts it with
  **OK**, **Enter** (in either part; Space on a day too), **Now**, or a double click on a day.
  **Esc**, **F4**, **Alt+Up / Down** and a press outside **dismiss** it. On accept the dropdown
  closes first, then the value is written and `DateTimeChanged` fires once, only for a real change.
- Over a range, the panel greys the hours and minutes outside it only on the min's or the max's
  day, and is re-limited when another day is picked.
- `DropDown`, `CloseUp`, `IsDroppedDown`; `GetCalendarHandle` and `GetPanelHandle` are the open
  dropdown's parts (0 while closed) and `GetPendingDateTime` its pending value. `SetVisibleRows`,
  `SetFooterText( now, ok )`, and `SetNow( dt )` to pin **Now** for tests and screenshots.

## Notifications

| Callback | When |
| --- | --- |
| `SetDateTimeChangedCallback` | each completed user change: a finished segment, a step, a paste, a clear, an accepted dropdown |
| `SetDropDownCallback` | the dropdown opens and closes |
| `SetFormatCallback` | the text at rest |
| `SetItemDisabledCallback` | asked for each time item in the dropdown: TRUE greys it out |
| `SetTooltipCallback` | the tip: `TKDATETIMEPICKER_TOOLTIPINFO` carries the value, the part (`TKDTM_HIT_*`) and the segment under the pointer |
| `SetPaintCallback` | replaces the drawing; `tkDateTimePicker_PaintDefault( p )` draws the stock picker |
| `SetMessageCallback` | the input stream; TRUE claims a message |

## Layout, colours and theme

- `GetIdealSize` is valid before the control is sized: tkDatePicker's formula on the widest value
  the pattern can show. The rect getters, `HitTest`, the segment getters and `StepBy` are
  tkTimePicker's.
- `TKDATETIMEPICKER_COLORS` is `TKTIMEPICKER_COLORS`' fields followed by `TKDATEPICKER_COLORS`'
  calendar block (title, navigation, weekdays, days, today's ring). `tkDateTimePicker_ThemeColors(
  t )` maps both from the same theme roles as its siblings. `SetColors` pins the struct until
  `UnpinColors`.

## In the Form Designer

The toolbox's **DateTimePicker** has Format, AllowEmpty, Step, ButtonStyle, WeekStart,
VisibleRows, ShowNow, TabMovesSegments, PlaceholderText, AmText, PmText, the fonts and icon,
CornerRadius, BorderThickness, MinDateTime, MaxDateTime and DateTime. Its events are
DateTimeChanged, DropDown, ItemDisabled, Paint, Message, FormatDateTime and Tooltip.

**Bind** moves the value into and out of one field of the form's DataType: a `chrono.DateTime`
(its offset is ignored on load and kept on save; no value is `DateTime.Invalid()`), a `TKDATETIME`,
or a `ustring` / `string` (ISO `yyyy-mm-ddTHH:mm:ss` out; ISO or lenient text in). See
[Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKDTM_BUTTON_DROPDOWN`, `TKDTM_BUTTON_SPIN`, `TKDTM_BUTTON_NONE` · `TKDTM_SUNDAY`, `TKDTM_MONDAY` ·
`TKDTM_HIT_NONE`, `TKDTM_HIT_FIELD`, `TKDTM_HIT_BUTTON`, `TKDTM_HIT_SPINUP`, `TKDTM_HIT_SPINDOWN` ·
`TKDTM_DEFAULT_PATTERN` · `CDTM_DEFAULT_*` (the design-unit sizes) · from
[tkTimePanel](tkTimePanel): `TKTP_SEG_*`.

### Types

`TKDATETIMEPICKER_COLORS`, `TKDATETIMEPICKER_PAINTINFO`, `TKDATETIMEPICKER_MESSAGEINFO`,
`TKDATETIMEPICKER_TOOLTIPINFO`, and the callback types `DTM_DateTimeChangedCallbackSub`,
`DTM_DropDownCallbackSub`, `DTM_ItemDisabledCallbackFunc`, `DTM_PaintCallbackSub`,
`DTM_MessageCallbackFunc`, `DTM_FormatCallbackSub`, `DTM_TooltipCallbackFunc`. `TKDATETIME` is
[tkTimePanel](tkTimePanel)'s.

### Procedures

```freebasic
function tkDateTimePicker_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkDateTimePicker_GetID( byval hCtrl as TK_WIDGET ptr ) as long
function tkDateTimePicker_GetEnabled( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDateTimePicker_SetEnabled( byval hCtrl as TK_WIDGET ptr, byval isEnabled as boolean )
function tkDateTimePicker_GetFocused( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDateTimePicker_Refresh( byval hCtrl as TK_WIDGET ptr )
function tkDateTimePicker_GetDateTime( byval hCtrl as TK_WIDGET ptr, byref t as TKDATETIME ) as boolean
sub tkDateTimePicker_SetDateTime( byval hCtrl as TK_WIDGET ptr, byref t as const TKDATETIME )
sub tkDateTimePicker_ClearDateTime( byval hCtrl as TK_WIDGET ptr )
function tkDateTimePicker_HasDateTime( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkDateTimePicker_GetDateTimeValue( byval hCtrl as TK_WIDGET ptr ) as TKDATETIME
sub tkDateTimePicker_SetDateTimeValue( byval hCtrl as TK_WIDGET ptr, byval t as TKDATETIME )
sub tkDateTimePicker_SetDateTimeParts( byval hCtrl as TK_WIDGET ptr, byval y as long, byval mo as long, byval d as long, _
sub tkDateTimePicker_GetRange( byval hCtrl as TK_WIDGET ptr, byref tMin as TKDATETIME, byref tMax as TKDATETIME, _
sub tkDateTimePicker_SetRange( byval hCtrl as TK_WIDGET ptr, byref tMin as const TKDATETIME, byref tMax as const TKDATETIME, _
sub tkDateTimePicker_SetMinDateTime( byval hCtrl as TK_WIDGET ptr, byval y as long, byval mo as long, byval d as long, _
sub tkDateTimePicker_SetMaxDateTime( byval hCtrl as TK_WIDGET ptr, byval y as long, byval mo as long, byval d as long, _
function tkDateTimePicker_GetAllowEmpty( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDateTimePicker_SetAllowEmpty( byval hCtrl as TK_WIDGET ptr, byval bAllow as boolean )
function tkDateTimePicker_GetStep( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_SetStep( byval hCtrl as TK_WIDGET ptr, byval nSeconds as long )
sub tkDateTimePicker_SetMonthNames( byval hCtrl as TK_WIDGET ptr, byval sNames as ustring )
sub tkDateTimePicker_SetDayNames( byval hCtrl as TK_WIDGET ptr, byval sNames as ustring )
function tkDateTimePicker_GetMonthName( byval hCtrl as TK_WIDGET ptr, byval m as long, byval bShort as boolean = false ) as ustring
function tkDateTimePicker_GetWeekStart( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_SetWeekStart( byval hCtrl as TK_WIDGET ptr, byval nWeekStart as long )
function tkDateTimePicker_GetFormat( byval hCtrl as TK_WIDGET ptr ) as ustring
sub tkDateTimePicker_SetFormat( byval hCtrl as TK_WIDGET ptr, byval sPattern as ustring )
sub tkDateTimePicker_SetAmPmText( byval hCtrl as TK_WIDGET ptr, byval sAm as ustring, byval sPm as ustring )
sub tkDateTimePicker_SetAmText( byval hCtrl as TK_WIDGET ptr, byval sAm as ustring )
sub tkDateTimePicker_SetPmText( byval hCtrl as TK_WIDGET ptr, byval sPm as ustring )
function tkDateTimePicker_GetAmText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkDateTimePicker_GetPmText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkDateTimePicker_GetPlaceholderText( byval hCtrl as TK_WIDGET ptr ) as ustring
sub tkDateTimePicker_SetPlaceholderText( byval hCtrl as TK_WIDGET ptr, byval sText as ustring )
function tkDateTimePicker_GetText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkDateTimePicker_GetButtonStyle( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_SetButtonStyle( byval hCtrl as TK_WIDGET ptr, byval nStyle as long )
function tkDateTimePicker_GetTabMovesSegments( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDateTimePicker_SetTabMovesSegments( byval hCtrl as TK_WIDGET ptr, byval bMoves as boolean )
function tkDateTimePicker_GetSegmentCount( byval hCtrl as TK_WIDGET ptr ) as long
function tkDateTimePicker_GetSegmentKind( byval hCtrl as TK_WIDGET ptr, byval i as long ) as long
function tkDateTimePicker_GetFocusedSegment( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_SetFocusedSegment( byval hCtrl as TK_WIDGET ptr, byval i as long )
function tkDateTimePicker_GetSegmentRect( byval hCtrl as TK_WIDGET ptr, byval i as long, byref rc as TKRECT ) as boolean
function tkDateTimePicker_GetPendingEntry( byval hCtrl as TK_WIDGET ptr ) as string
sub tkDateTimePicker_StepBy( byval hCtrl as TK_WIDGET ptr, byval i as long, byval n as long )
function tkDateTimePicker_GetFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkDateTimePicker_SetFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkDateTimePicker_GetIconFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkDateTimePicker_SetIconFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkDateTimePicker_GetIconGlyph( byval hCtrl as TK_WIDGET ptr ) as ustring
sub tkDateTimePicker_SetIconGlyph( byval hCtrl as TK_WIDGET ptr, byval sGlyph as ustring )
function tkDateTimePicker_GetIconWidth( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_SetIconWidth( byval hCtrl as TK_WIDGET ptr, byval nWidth as long )
function tkDateTimePicker_GetCornerRadius( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_SetCornerRadius( byval hCtrl as TK_WIDGET ptr, byval nRadius as long )
function tkDateTimePicker_GetBorderThickness( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_SetBorderThickness( byval hCtrl as TK_WIDGET ptr, byval nThickness as long )
sub tkDateTimePicker_GetIdealSize( byval hCtrl as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkDateTimePicker_GetFrameRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkDateTimePicker_GetFieldRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkDateTimePicker_GetIconRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkDateTimePicker_GetSpinRect( byval hCtrl as TK_WIDGET ptr, byval bUp as boolean, byref rc as TKRECT ) as boolean
function tkDateTimePicker_HitTest( byval hCtrl as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkDateTimePicker_GetHotPart( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_GetRepeat( byval hCtrl as TK_WIDGET ptr, byref nDelayMs as long, byref nIntervalMs as long )
sub tkDateTimePicker_SetRepeat( byval hCtrl as TK_WIDGET ptr, byval nDelayMs as long, byval nIntervalMs as long )
sub tkDateTimePicker_GetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKDATETIMEPICKER_COLORS ptr )
sub tkDateTimePicker_SetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKDATETIMEPICKER_COLORS ptr )
function tkDateTimePicker_ThemeColors( byref t as TKTHEME_COLORS ) as TKDATETIMEPICKER_COLORS
sub tkDateTimePicker_ApplyTheme( byval hCtrl as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkDateTimePicker_UnpinColors( byval hCtrl as TK_WIDGET ptr )
sub tkDateTimePicker_ApplyFonts( byval hCtrl as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkDateTimePicker_PaintDefault( byval pi as TKDATETIMEPICKER_PAINTINFO ptr )
sub tkDateTimePicker_SetDateTimeChangedCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTM_DateTimeChangedCallbackSub )
sub tkDateTimePicker_SetDropDownCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTM_DropDownCallbackSub )
sub tkDateTimePicker_SetPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTM_PaintCallbackSub )
sub tkDateTimePicker_SetItemDisabledCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as DTM_ItemDisabledCallbackFunc )
sub tkDateTimePicker_SetMessageCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as DTM_MessageCallbackFunc )
sub tkDateTimePicker_SetFormatCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTM_FormatCallbackSub )
sub tkDateTimePicker_SetTooltipCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as DTM_TooltipCallbackFunc )
function tkDateTimePicker_GetTooltipHandle( byval hCtrl as TK_WIDGET ptr ) as TK_TIP ptr
sub tkDateTimePicker_DropDown( byval hCtrl as TK_WIDGET ptr )
sub tkDateTimePicker_CloseUp( byval hCtrl as TK_WIDGET ptr )
function tkDateTimePicker_IsDroppedDown( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkDateTimePicker_GetCalendarHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkDateTimePicker_GetPanelHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkDateTimePicker_GetPopup( byval hCtrl as TK_WIDGET ptr ) as TK_HOST ptr
function tkDateTimePicker_GetFooterHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkDateTimePicker_GetFooterButtonRects( byval hCtrl as TK_WIDGET ptr, byref rcNow as TKRECT, byref rcOK as TKRECT )
function tkDateTimePicker_GetPendingDateTime( byval hCtrl as TK_WIDGET ptr ) as TKDATETIME
function tkDateTimePicker_GetVisibleRows( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDateTimePicker_SetVisibleRows( byval hCtrl as TK_WIDGET ptr, byval nRows as long )
function tkDateTimePicker_GetShowNow( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDateTimePicker_SetShowNow( byval hCtrl as TK_WIDGET ptr, byval bShow as boolean )
sub tkDateTimePicker_SetFooterText( byval hCtrl as TK_WIDGET ptr, byval sNow as ustring, byval sOK as ustring )
sub tkDateTimePicker_SetNow( byval hCtrl as TK_WIDGET ptr, byref t as const TKDATETIME, byval bPin as boolean = true )
```

### See also

- [tkControls](Category-tkControls)
- [tkDatePicker](tkDatePicker) and [tkTimePicker](tkTimePicker), its siblings
- [tkTimePanel](tkTimePanel), the time columns and the date-time helpers
- [Form Designer](Form-Designer), data binding
