[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTimePicker**

# tkTimePicker

Draws a time-of-day field: the hour, minute, second and AM/PM of a pattern, each typed into and
stepped on its own, with a dropdown chooser beside it (or a spin pair, or nothing).

`tkTimePicker` is the [tkControls](Category-tkControls) time picker. Its frame, divider and button
cell are [tkDatePicker](tkDatePicker)'s, to the pixel, so the two sit side by side as a pair. The
dropdown is a [tkTimePanel](tkTimePanel) in a popup: columns (hours | minutes | AM/PM) or one list
of times at an interval, with an optional **Now** / **OK** band. The value is a `TKTIME`
(tkTimePanel's), held apart from how it is shown: a 12- or 24-hour pattern only formats it.

Every setter is silent. `TimeChanged` fires once for each change the user completes, never for a
half-typed entry. The Form Designer's **TimePicker** binds its time; a DatePicker and a TimePicker
bound to one `chrono.DateTime` field save both halves in one call.

## Importing

```freebasic
#import "vendor/tkControls/tkTimePicker"

using tkTimePicker
using tkTimePanel
using tkHost
```

The module brings in [tkTimePanel](tkTimePanel) (`TKTIME`, the `tkTimePanel_*` time helpers and
the pattern engine), [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). `using tkTimePanel` names `TKTIME` and the `TKTP_*`
constants. Add `using tkPaint` for a paint callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Start_Changed( byval hCtrl as TK_WIDGET ptr, byval pTime as TKTIME ptr, byval bHasTime as boolean )
    if bHasTime then print "starts " & tkTimePanel_FormatIso( *pTime ) else print "no time"
end sub

dim as TK_WIDGET ptr tp = tkTimePicker_Create( tkHost_Root( host ), 100 )
tkTimePicker_SetFormat( tp, "h:mm tt" )                 ' 12-hour, AM / PM
tkTimePicker_SetStep( tp, 900 )                         ' 15 minutes
tkTimePicker_SetRange( tp, tkTimePanel_MakeTime( 8, 0 ), tkTimePanel_MakeTime( 18, 0 ) )
tkTimePicker_SetShowNow( tp, true )
tkTimePicker_SetTime( tp, tkTimePanel_MakeTime( 9, 30 ) )   ' silent: no callback
tkTimePicker_SetTimeChangedCallback( tp, @Start_Changed )

dim as long w, h
tkTimePicker_GetIdealSize( tp, w, h )                   ' valid before the control is sized
tkWidget_SetPos( tp, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
```

## The value

- A `TKTIME` is `wHour`, `wMinute`, `wSecond`, `wMilliseconds` (SYSTEMTIME's time half, as
  `TKDATE` is its date half). **`wHour = -1` is no time**, and is its default: `dim t as TKTIME` is
  empty, while 0 is midnight. `tkTimePanel_MakeTime( h, m, s, ms )` gives the empty time for any
  part out of range.
- `GetTime` / `SetTime` / `ClearTime` / `HasTime`; `GetTimeValue` / `SetTimeValue` take and give a
  `TKTIME` by value (the designer's bind pair). `SetTimeParts( h, m, s )` is for designer rows.
- **Setters keep every part.** A picker showing `HH:mm` keeps 14:30:15 if it is given it. A **user**
  edit zeroes the parts the pattern does not show, so the user never sees 14:31 that is secretly
  14:31:15.
- `SetRange( min, max )` (an inverted pair is swapped) clamps every route: setters, typing,
  stepping, the dropdown, pasting. `SetMinTime` / `SetMaxTime` take numbers, for designer rows.
  A range does not wrap past midnight.
- `SetAllowEmpty( false )` stops the user from clearing the field; a setter can still clear it.
- `SetStep( seconds )`, 1 to 3600: under a minute it steps the seconds, from a minute up `step \ 60`
  steps the minutes. It decides the dropdown's items, and Up / Down on the finest segment move to
  the next point of its grid. A typed value is not snapped to it.

## The pattern

`SetFormat( pattern )`, default `HH:mm`:

| Token | Shows |
| --- | --- |
| `H` `HH` | hour 0–23, one or two digits |
| `h` `hh` | hour 1–12 |
| `m` `mm` | minute |
| `s` `ss` | second |
| `f` `ff` `fff` | tenths, hundredths, milliseconds |
| `t` `tt` | the designator's first letter, or all of it |
| `'text'` | text as it is (`''` is a quote) |

Any other character shows as itself. `SetAmPmText( am, pm )` (or `SetAmText` / `SetPmText`) sets
the designators; the default is `AM` / `PM`. `GetText` answers the formatted time, "" for none.
`SetPlaceholderText` shows a hint while the field is empty and unfocused.

`SetFormatCallback` (the designer's **FormatTime**) changes the text: the callback gets the time
and `sOut` already holding the pattern's text, and may replace it ("" keeps it). Its text is shown
**at rest** -- unfocused, with a time, nothing being typed -- and answers `GetText`, sizes
`GetIdealSize`, and labels the dropdown's list. Focus brings the segments back, because typing
and stepping work on the pattern. Ctrl+C copies the pattern's text, which pastes back.

## Typing and keys

The field takes no text input; it reads keys. One segment has the focus, filled with the selection
colour.

- **Digits** fill the focused segment. A digit that cannot start a two-digit value completes at once
  and moves on (hour 3–9 on a 24-hour clock, 2–9 on a 12-hour one, minute or second 6–9). Otherwise
  the second digit completes it, and an impossible pair (`25`) starts over with its last digit. An
  entry also completes on `:` `.` or space (which move on), on a one-second pause, on Enter, on the
  arrows, and when the focus leaves. The top row's digit keys count by position too, so an AZERTY
  keyboard types digits without Shift.
- **Up / Down** step the segment and wrap inside it with no carry: 59 goes to 00 and the hour stays.
  A 12-hour hour wraps from 12 to 1 within its half of the day. **Page Up / Page Down** move 10
  minutes or seconds, an hour, or the half of the day. On an empty field the first step lands on
  00:00 (clamped to the range).
- **Left / Right**, **Home / End** move between segments. **Tab** leaves the control, unless
  `SetTabMovesSegments( true )` makes it walk the segments first.
- `a` / `p` (or the first letters of your designators) set the half of the day, from any segment.
- **Backspace / Delete** drop a pending entry, or clear the time (only with AllowEmpty).
- **Enter** and **Esc** are claimed only to finish or drop a pending entry, so otherwise a form's
  default and cancel buttons get them.
- **Ctrl+C** copies the text, **Ctrl+X** copies and clears, **Ctrl+V** pastes leniently (`14:30`,
  `1430`, `2:30 pm`, `2p`, `12 am`); text that is no time changes nothing.
- **The wheel** steps the segment under the pointer, but only while the field has the focus, so
  scrolling a form never edits a time.

## The button cell

`SetButtonStyle`:

- `TKTP_BUTTON_DROPDOWN` (default): a clock button opens the dropdown. **F4** and **Alt+Down**
  open it too.
- `TKTP_BUTTON_SPIN`: an up and a down chevron step the focused segment; held, they repeat
  (`SetRepeat( delay, interval )`, 400 ms then every 60 ms), paused while the pointer is off the
  pressed half.
- `TKTP_BUTTON_NONE`: the field alone.

The clock is drawn; `SetIconFont` plus `SetIconGlyph` replace it with a glyph.

## The dropdown

- `SetPanelMode( TKTP_PANEL_COLUMNS )` (default) shows a column per unit the pattern has;
  `TKTP_PANEL_LIST` shows one list from `SetListRange( start, end, intervalSeconds )`.
  `SetVisibleRows` sets its height in items. It opens at least as wide as the field, with the
  column of the focused segment focused.
- **A pick in the dropdown is pending: the field does not change** until the user **accepts** it
  with Enter, **OK**, **Now**, a pick in the last column, or a pick in the list. **Esc**, **F4**,
  **Alt+Up / Down**, a press outside and focus leaving the application **dismiss** it, and the
  value is unchanged. On accept the dropdown closes first, then the value is written and
  `TimeChanged` fires once, only for a real change.
- `SetShowNow` / `SetShowOK` add the band; `SetFooterText( now, ok )` labels it. **Now** takes the
  clock's time (clamped, the hidden parts zeroed); `SetNow( t )` pins it for tests and screenshots.
- `DropDown`, `CloseUp`, `IsDroppedDown`. `GetPanelHandle` is the open dropdown's tkTimePanel, 0
  while closed; it is built anew at every open. Clicking the button again closes it and does not
  reopen it. One dropdown is open per process.

## Notifications

| Callback | When |
| --- | --- |
| `SetTimeChangedCallback` | each completed user change: a finished segment, a step, a paste, a clear, an accepted dropdown pick |
| `SetDropDownCallback` | the dropdown opens (before it is built) and closes |
| `SetFormatCallback` | the text at rest and in the dropdown's list (above) |
| `SetItemDisabledCallback` | asked for each dropdown item: TRUE greys it out (hours are passed as 0–23) |
| `SetTooltipCallback` | the tip: `TKTIMEPICKER_TOOLTIPINFO` carries the time, the part (`TKTPK_HIT_*`) and the segment under the pointer; set `outText` and return TRUE to show it. The tip is made when this is first set; moving to another segment brings a fresh one |
| `SetPaintCallback` | replaces the drawing; `tkTimePicker_PaintDefault( p )` draws the stock picker |
| `SetMessageCallback` | the input stream; TRUE claims a message |

The state is updated before a callback runs. A callback may destroy the picker.

## Layout

- `GetIdealSize` is valid before the control is sized: [tkDatePicker](tkDatePicker)'s formula, on
  the widest time the pattern can show (or the placeholder).
- `GetFrameRect`, `GetFieldRect`, `GetIconRect`, `GetSpinRect( h, bUp, rc )`,
  `GetSegmentRect( h, i, rc )` and `HitTest` answer in control-local pixels.
  `GetSegmentCount` / `GetSegmentKind` / `Get` / `SetFocusedSegment` read the pattern's segments;
  `StepBy( h, i, n )` steps one as the keys do, silently.
- `SetIconWidth`, `SetCornerRadius`, `SetBorderThickness`, `SetFont`.

## Colours and theme

`TKTIMEPICKER_COLORS` has tkDatePicker's frame block colour for colour (back, border, focus border,
divider, field, icon), then the focused segment, the placeholder, and the dropdown's panel, items,
column divider and band. `tkTimePicker_ThemeColors( t )` maps them from the theme's roles,
exactly as the DatePicker does for its own. `SetColors` pins the struct until `UnpinColors`. The
corner radius and border follow the theme's shape until a setter pins them.

## In the Form Designer

The toolbox's **TimePicker** has Format, AllowEmpty, Step, ButtonStyle, PanelMode, VisibleRows,
ShowNow, ShowOK, TabMovesSegments, PlaceholderText, AmText, PmText, the fonts and icon, CornerRadius,
BorderThickness, MinTime, MaxTime and Time. Its events are TimeChanged, DropDown, ItemDisabled,
Paint, Message, FormatTime (the handler sets `sOut`) and Tooltip (it sets `t->outText`; `Show`
starts TRUE).

**Bind** moves the time into and out of a field of the form's DataType: a `TKTIME`,
`chrono.LocalTime`, `ustring` or `string` (ISO `HH:mm:ss`), or the time half of a `chrono.DateTime`.
Bind a DatePicker and a TimePicker to the same `DateTime` field, and `SaveTo` writes both halves in
one call, so a new record gets its date and its time whichever control comes first. See
[Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKTP_BUTTON_DROPDOWN`, `TKTP_BUTTON_SPIN`, `TKTP_BUTTON_NONE` · `TKTPK_HIT_NONE`, `TKTPK_HIT_FIELD`,
`TKTPK_HIT_BUTTON`, `TKTPK_HIT_SPINUP`, `TKTPK_HIT_SPINDOWN` · `CTP_DEFAULT_*` (the design-unit
sizes) · from [tkTimePanel](tkTimePanel): `TKTP_PANEL_COLUMNS`, `TKTP_PANEL_LIST`, `TKTP_SEG_*`.

### Types

`TKTIMEPICKER_COLORS`, `TKTIMEPICKER_PAINTINFO` (the frame, field, divider, icon and spin rects,
the state, the hot and pressed part, the focused segment), `TKTIMEPICKER_MESSAGEINFO`,
`TKTIMEPICKER_TOOLTIPINFO`, and the callback types `TPK_TimeChangedCallbackSub`,
`TPK_DropDownCallbackSub`, `TPK_ItemDisabledCallbackFunc`, `TPK_PaintCallbackSub`,
`TPK_MessageCallbackFunc`, `TPK_FormatCallbackSub`, `TPK_TooltipCallbackFunc`. `TKTIME` is [tkTimePanel](tkTimePanel)'s.

### Procedures

```freebasic
function tkTimePicker_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkTimePicker_GetID( byval hCtrl as TK_WIDGET ptr ) as long
function tkTimePicker_GetEnabled( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkTimePicker_SetEnabled( byval hCtrl as TK_WIDGET ptr, byval isEnabled as boolean )
function tkTimePicker_GetFocused( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkTimePicker_Refresh( byval hCtrl as TK_WIDGET ptr )
function tkTimePicker_GetTime( byval hCtrl as TK_WIDGET ptr, byref t as TKTIME ) as boolean
sub tkTimePicker_SetTime( byval hCtrl as TK_WIDGET ptr, byref t as const TKTIME )
sub tkTimePicker_ClearTime( byval hCtrl as TK_WIDGET ptr )
function tkTimePicker_HasTime( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkTimePicker_GetTimeValue( byval hCtrl as TK_WIDGET ptr ) as TKTIME
sub tkTimePicker_SetTimeValue( byval hCtrl as TK_WIDGET ptr, byval t as TKTIME )
sub tkTimePicker_SetTimeParts( byval hCtrl as TK_WIDGET ptr, byval hh as long, byval mi as long, byval ss as long )
sub tkTimePicker_GetRange( byval hCtrl as TK_WIDGET ptr, byref tMin as TKTIME, byref tMax as TKTIME, _
sub tkTimePicker_SetRange( byval hCtrl as TK_WIDGET ptr, byref tMin as const TKTIME, byref tMax as const TKTIME, _
sub tkTimePicker_SetMinTime( byval hCtrl as TK_WIDGET ptr, byval hh as long, byval mi as long, byval ss as long )
sub tkTimePicker_SetMaxTime( byval hCtrl as TK_WIDGET ptr, byval hh as long, byval mi as long, byval ss as long )
function tkTimePicker_GetAllowEmpty( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkTimePicker_SetAllowEmpty( byval hCtrl as TK_WIDGET ptr, byval bAllow as boolean )
function tkTimePicker_GetStep( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_SetStep( byval hCtrl as TK_WIDGET ptr, byval nSeconds as long )
function tkTimePicker_GetFormat( byval hCtrl as TK_WIDGET ptr ) as ustring
sub tkTimePicker_SetFormat( byval hCtrl as TK_WIDGET ptr, byval sPattern as ustring )
sub tkTimePicker_SetAmPmText( byval hCtrl as TK_WIDGET ptr, byval sAm as ustring, byval sPm as ustring )
sub tkTimePicker_SetAmText( byval hCtrl as TK_WIDGET ptr, byval sAm as ustring )
sub tkTimePicker_SetPmText( byval hCtrl as TK_WIDGET ptr, byval sPm as ustring )
function tkTimePicker_GetAmText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkTimePicker_GetPmText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkTimePicker_GetPlaceholderText( byval hCtrl as TK_WIDGET ptr ) as ustring
sub tkTimePicker_SetPlaceholderText( byval hCtrl as TK_WIDGET ptr, byval sText as ustring )
function tkTimePicker_GetText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkTimePicker_GetButtonStyle( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_SetButtonStyle( byval hCtrl as TK_WIDGET ptr, byval nStyle as long )
function tkTimePicker_GetTabMovesSegments( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkTimePicker_SetTabMovesSegments( byval hCtrl as TK_WIDGET ptr, byval bMoves as boolean )
function tkTimePicker_GetSegmentCount( byval hCtrl as TK_WIDGET ptr ) as long
function tkTimePicker_GetSegmentKind( byval hCtrl as TK_WIDGET ptr, byval i as long ) as long
function tkTimePicker_GetFocusedSegment( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_SetFocusedSegment( byval hCtrl as TK_WIDGET ptr, byval i as long )
function tkTimePicker_GetSegmentRect( byval hCtrl as TK_WIDGET ptr, byval i as long, byref rc as TKRECT ) as boolean
function tkTimePicker_GetPendingEntry( byval hCtrl as TK_WIDGET ptr ) as string
sub tkTimePicker_StepBy( byval hCtrl as TK_WIDGET ptr, byval i as long, byval n as long )
function tkTimePicker_GetFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkTimePicker_SetFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkTimePicker_GetIconFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkTimePicker_SetIconFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkTimePicker_GetIconGlyph( byval hCtrl as TK_WIDGET ptr ) as ustring
sub tkTimePicker_SetIconGlyph( byval hCtrl as TK_WIDGET ptr, byval sGlyph as ustring )
function tkTimePicker_GetIconWidth( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_SetIconWidth( byval hCtrl as TK_WIDGET ptr, byval nWidth as long )
function tkTimePicker_GetCornerRadius( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_SetCornerRadius( byval hCtrl as TK_WIDGET ptr, byval nRadius as long )
function tkTimePicker_GetBorderThickness( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_SetBorderThickness( byval hCtrl as TK_WIDGET ptr, byval nThickness as long )
sub tkTimePicker_GetIdealSize( byval hCtrl as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkTimePicker_GetFrameRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkTimePicker_GetFieldRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkTimePicker_GetIconRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkTimePicker_GetSpinRect( byval hCtrl as TK_WIDGET ptr, byval bUp as boolean, byref rc as TKRECT ) as boolean
function tkTimePicker_HitTest( byval hCtrl as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkTimePicker_GetHotPart( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_GetRepeat( byval hCtrl as TK_WIDGET ptr, byref nDelayMs as long, byref nIntervalMs as long )
sub tkTimePicker_SetRepeat( byval hCtrl as TK_WIDGET ptr, byval nDelayMs as long, byval nIntervalMs as long )
sub tkTimePicker_GetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKTIMEPICKER_COLORS ptr )
sub tkTimePicker_SetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKTIMEPICKER_COLORS ptr )
function tkTimePicker_ThemeColors( byref t as TKTHEME_COLORS ) as TKTIMEPICKER_COLORS
sub tkTimePicker_ApplyTheme( byval hCtrl as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkTimePicker_UnpinColors( byval hCtrl as TK_WIDGET ptr )
sub tkTimePicker_ApplyFonts( byval hCtrl as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkTimePicker_PaintDefault( byval pi as TKTIMEPICKER_PAINTINFO ptr )
sub tkTimePicker_SetTimeChangedCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as TPK_TimeChangedCallbackSub )
sub tkTimePicker_SetDropDownCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as TPK_DropDownCallbackSub )
sub tkTimePicker_SetPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as TPK_PaintCallbackSub )
sub tkTimePicker_SetItemDisabledCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as TPK_ItemDisabledCallbackFunc )
sub tkTimePicker_SetMessageCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as TPK_MessageCallbackFunc )
sub tkTimePicker_SetFormatCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as TPK_FormatCallbackSub )
sub tkTimePicker_SetTooltipCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as TPK_TooltipCallbackFunc )
function tkTimePicker_GetTooltipHandle( byval hCtrl as TK_WIDGET ptr ) as TK_TIP ptr
sub tkTimePicker_DropDown( byval hCtrl as TK_WIDGET ptr )
sub tkTimePicker_CloseUp( byval hCtrl as TK_WIDGET ptr )
function tkTimePicker_IsDroppedDown( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkTimePicker_GetPanelHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkTimePicker_GetPopup( byval hCtrl as TK_WIDGET ptr ) as TK_HOST ptr
function tkTimePicker_GetFooterHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkTimePicker_GetFooterButtonRects( byval hCtrl as TK_WIDGET ptr, byref rcNow as TKRECT, byref rcOK as TKRECT )
function tkTimePicker_GetPanelMode( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_SetPanelMode( byval hCtrl as TK_WIDGET ptr, byval nMode as long )
sub tkTimePicker_SetListRange( byval hCtrl as TK_WIDGET ptr, byref tStart as const TKTIME, byref tEnd as const TKTIME, _
sub tkTimePicker_GetListRange( byval hCtrl as TK_WIDGET ptr, byref tStart as TKTIME, byref tEnd as TKTIME, _
function tkTimePicker_GetVisibleRows( byval hCtrl as TK_WIDGET ptr ) as long
sub tkTimePicker_SetVisibleRows( byval hCtrl as TK_WIDGET ptr, byval nRows as long )
function tkTimePicker_GetShowNow( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkTimePicker_SetShowNow( byval hCtrl as TK_WIDGET ptr, byval bShow as boolean )
function tkTimePicker_GetShowOK( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkTimePicker_SetShowOK( byval hCtrl as TK_WIDGET ptr, byval bShow as boolean )
sub tkTimePicker_SetFooterText( byval hCtrl as TK_WIDGET ptr, byval sNow as ustring, byval sOK as ustring )
sub tkTimePicker_SetNow( byval hCtrl as TK_WIDGET ptr, byref t as const TKTIME, byval bPin as boolean = true )
```

### See also

- [tkControls](Category-tkControls)
- [tkTimePanel](tkTimePanel), the chooser and the time helpers
- [tkDatePicker](tkDatePicker), its sibling for dates
- [Form Designer](Form-Designer), data binding
