[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTimePanel**

# tkTimePanel

Draws a time chooser: a column each for the hours, minutes, seconds and AM/PM a pattern shows, or
one list of times at an interval. It also holds `TKTIME` and the time helpers every time control
uses.

`tkTimePanel` is to [tkTimePicker](tkTimePicker) what [tkCalendar](tkCalendar) is to
[tkDatePicker](tkDatePicker): the picker shows it in its dropdown, and it works on its own on a
form. Items outside the range, or refused by a callback, are dimmed and cannot be picked.

Every setter is silent. A pick fires `SelChange`; a pick in the last column, a pick in the list or
Enter also fires `Accept`; Esc, F4 and Alt+Up / Down fire `Dismiss`.

## Importing

```freebasic
#import "vendor/tkControls/tkTimePanel"

using tkTimePanel
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image) and [tkTheme](tkTheme). Add `using tkPaint` for an item paint callback.

## Example

```freebasic
sub Slot_Picked( byval hPanel as TK_WIDGET ptr, byval pTime as TKTIME ptr )
    print "booked " & tkTimePanel_FormatPattern( *pTime, "h:mm tt" )
end sub

dim as TK_WIDGET ptr slots = tkTimePanel_Create( tkHost_Root( host ), 200 )
tkTimePanel_SetMode( slots, TKTP_PANEL_LIST )
tkTimePanel_SetFormat( slots, "h:mm tt" )
tkTimePanel_SetListRange( slots, tkTimePanel_MakeTime( 9, 0 ), tkTimePanel_MakeTime( 17, 0 ), 1800 )
tkTimePanel_SetAcceptCallback( slots, @Slot_Picked )

dim as long w, h
tkTimePanel_GetIdealSize( slots, w, h )
tkWidget_SetPos( slots, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
```

## The time helpers

`TKTIME` is `wHour`, `wMinute`, `wSecond`, `wMilliseconds`, and **`wHour = -1` is no time** (its
default; 0 is midnight).

- `tkTimePanel_MakeTime( h, m, s, ms )` gives the empty time for any part out of range.
  `EmptyTime`, `IsTime`, `SameTime`, `CompareTime` (no time sorts first), `TimeToMs` / `MsToTime`
  (milliseconds since midnight), `LocalNow` (the local clock).
- `tkTimePanel_FormatIso( t, bSeconds, bMs )` writes `HH:mm`, `HH:mm:ss` or `HH:mm:ss.fff`;
  `ParseIso` reads them strictly.
- `tkTimePanel_ParseLoose( s, t, am, pm )` reads what people type or paste: `14:30`, `14:30:05.250`,
  `14.30`, `1430`, `930`, `2:30 pm`, `2pm`, `2 p`, `12 am` (00:00), and your own designators. It
  refuses rather than guesses: minutes and seconds take two digits, and a refusal leaves `t` alone.
- `tkTimePanel_FormatPattern( t, pattern, am, pm )` formats through a pattern (the tokens are on
  [tkTimePicker](tkTimePicker)'s page); `ParsePattern` turns one into a `TKTIME_SEGMENT` table and
  `SegmentText` formats one segment.
- `tkTimePanel_KeyDigit( key, scancode )` is the digit a key types, by keycode or by the top row's
  position.

## Columns and list

- **Columns** (`TKTP_PANEL_COLUMNS`, default): `SetFormat( pattern )` decides the columns, hours (0–23,
  or 12, 01–11), minutes, seconds and AM/PM, in the pattern's order. `SetStep( seconds )`: under a
  minute it steps the seconds column, from a minute up `step \ 60` steps the minutes column.
- **List** (`TKTP_PANEL_LIST`): `SetListRange( start, end, intervalSeconds )`, labels formatted by
  the pattern. A value between two items selects none; the one before it is scrolled into view and
  is where the arrow keys start.
- `SetRange( min, max )` dims every item whose whole span is outside it, and clamps the value. An
  `ItemDisabled( hPanel, nKind, nValue )` callback can dim more: hours come as `TKTP_SEG_HOUR24`
  0–23, list items as `TKTP_ITEM_TIME` with seconds since midnight.
- A pick zeroes what the pattern does not show and clamps to the range. A pick on an empty value
  starts from 00:00.
- Setters and picks scroll each selection to the top of its column, as far as the column scrolls.

## Keys and mouse

- **Up / Down**, **Page Up / Page Down**, **Home / End** move within the focused column (or the
  list), skipping dimmed items, with no wrap. With nothing selected, Down starts at the first item
  and Up at the last.
- **Left / Right** move between columns. **Tab** / **Shift+Tab** do too, then hand on to the next
  control.
- **Digits** pick by number in the focused column (two within a second). In the list they match the
  labels' digits with leading zeros dropped (1 3 finds 13:00). `a` / `p` set the half of the day.
- **Enter** fires Accept and **Esc** / **F4** / **Alt+Up/Down** fire Dismiss, but only while those
  callbacks are set, so a panel on a form leaves Enter and Esc to the form.
- A click picks. **The wheel** scrolls the column under the pointer by two items a notch, without
  changing the value, and lets the wheel go to the form when there is nothing to scroll.

## Notifications

| Callback | When |
| --- | --- |
| `SetSelChangeCallback` | every pick that changes the value |
| `SetAcceptCallback` | a pick in the last column, a pick in the list, Enter |
| `SetDismissCallback` | Esc, F4, Alt+Up / Down |
| `SetItemDisabledCallback` | asked for each item: TRUE dims it |
| `SetItemPaintCallback` | draws one item; `tkTimePanel_PaintItemDefault( p )` draws the stock one |
| `SetItemTextCallback` | an item's label: `sText` arrives as the default and may be replaced (hours as 0–23); the columns are measured with it |
| `SetMessageCallback` | the input stream; TRUE claims a message |

Callbacks fire last, from a snapshot: one may destroy the panel.

## Layout and theme

- `GetIdealSize` is valid before sizing: every column as wide as its widest label, and
  `SetVisibleRows` items (default 7) tall. An item is 28 pixels (scaled) or the font's height plus
  8, whichever is more.
- `GetColumnCount`, `GetColumnKind`, `GetItemCount`, `GetItemValue`, `GetItemText`,
  `IsItemDisabled`, `GetSelectedIndex`, `GetItemRect`, `GetColumnRect`, `GetScrollPos`,
  `GetItemHeight`, `HitTest`, `Get` / `SetFocusedColumn` and `EnsureVisible` read and drive it.
- `TKTIMEPANEL_COLORS`: back, border, focus ring, item (normal, disabled, hot, selected) and column
  divider, on tkCalendar's theme roles. `SetColors` pins them until `UnpinColors`. The border follows
  the theme's `BorderWidth` until `SetBorderThickness` (0 draws none).

## In the Form Designer

The toolbox's **TimePanel** has Format, Step, Mode, VisibleRows, Font and BorderThickness, and the
events SelChange, Accept, Dismiss, ItemDisabled, ItemPaint and Message. It does not bind; bind a
[tkTimePicker](tkTimePicker).

## The date-time helpers

[tkDateTimePicker](tkDateTimePicker)'s value lives here too, so it needs neither chrono nor
tkCalendar. `TKDATETIME` is SYSTEMTIME's layout (`wYear wMonth wDayOfWeek wDay wHour wMinute
wSecond wMilliseconds`), and **`wYear = 0` is no value** (its default).

- `tkTimePanel_MakeDateTime( y, mo, d, hh, mi, ss, ms )` fills the weekday and gives the empty
  value for any part out of range. `EmptyDateTime`, `IsDateTime`, `SameDateTime`,
  `CompareDateTime`, `TimeOf` (the time half), `DateTimeToSerial` / `SerialToDateTime`
  (milliseconds), `LocalNowDateTime`. `IsLeapYear`, `DaysInMonth`, `DayOfWeek` (0 = Sunday).
- `tkTimePanel_FormatIsoDateTime( dt, bSeconds, bMs )` writes `yyyy-mm-ddTHH:mm[:ss[.fff]]`;
  `ParseIsoDateTime` reads it, with a space allowed for the `T` and a date alone as midnight.
  `ParseLooseDateTime( s, dt, am, pm )` takes an ISO date, a space, then any time `ParseLoose` reads.
- `ParsePattern( pattern, segs(), bDateTokens )`: only with the flag are `yyyy` `yy`, `M` `MM`
  `MMM` `MMMM`, `d` `dd`, `ddd` `dddd` segments (`TKTP_SEG_YEAR`, `_MONTH`, `_MONTHNAME`, `_DAY`,
  `_WEEKDAY`); without it they are literal text, as they always were for the time controls.
  `FormatPatternDT( dt, pattern, am, pm, pNames )` and `SegmentTextDT` format through them, with
  month and weekday names from a `TKDT_NAMES` (`DefaultNames` is English).

## Public declarations

### Constants

`TKTP_SEG_LITERAL`, `TKTP_SEG_HOUR24`, `TKTP_SEG_HOUR12`, `TKTP_SEG_MINUTE`, `TKTP_SEG_SECOND`,
`TKTP_SEG_FRACTION`, `TKTP_SEG_AMPM`, `TKTP_SEG_YEAR`, `TKTP_SEG_MONTH`, `TKTP_SEG_MONTHNAME`,
`TKTP_SEG_DAY`, `TKTP_SEG_WEEKDAY`, `TKTP_ITEM_TIME` · `TKTP_PANEL_COLUMNS`, `TKTP_PANEL_LIST` ·
`TKTP_PART_NONE`, `TKTP_PART_ITEM`, `TKTP_PART_COLUMN` · `TKTP_MS_PER_DAY`, `TKTP_DEFAULT_PATTERN`,
`TKTP_DEFAULT_STEP`, `TKTP_DEFAULT_ROWS`, `TKTP_DEFAULT_LIST_INTERVAL`, `TKTP_TYPE_TIMEOUT` and the
design-unit sizes.

### Types

`TKTIME`, `TKDATETIME`, `TKDT_NAMES`, `TKTIME_SEGMENT`, `TKTIMEPANEL_HIT`, `TKTIMEPANEL_COLORS`, `TKTIMEPANEL_ITEMPAINTINFO`,
`TKTIMEPANEL_MESSAGEINFO`, and the callback types `TP_SelChangeCallbackSub`, `TP_AcceptCallbackSub`,
`TP_DismissCallbackSub`, `TP_ItemDisabledCallbackFunc`, `TP_ItemPaintCallbackSub`,
`TP_MessageCallbackFunc`, `TP_ItemTextCallbackSub`.

### Procedures

```freebasic
function tkTimePanel_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkTimePanel_GetID( byval hPanel as TK_WIDGET ptr ) as long
function tkTimePanel_GetEnabled( byval hPanel as TK_WIDGET ptr ) as boolean
sub tkTimePanel_SetEnabled( byval hPanel as TK_WIDGET ptr, byval isEnabled as boolean )
function tkTimePanel_GetFocused( byval hPanel as TK_WIDGET ptr ) as boolean
sub tkTimePanel_Refresh( byval hPanel as TK_WIDGET ptr )
function tkTimePanel_GetTime( byval hPanel as TK_WIDGET ptr, byref t as TKTIME ) as boolean
sub tkTimePanel_SetTime( byval hPanel as TK_WIDGET ptr, byref t as const TKTIME )
function tkTimePanel_GetTimeValue( byval hPanel as TK_WIDGET ptr ) as TKTIME
sub tkTimePanel_SetTimeValue( byval hPanel as TK_WIDGET ptr, byval t as TKTIME )
function tkTimePanel_HasTime( byval hPanel as TK_WIDGET ptr ) as boolean
sub tkTimePanel_ClearTime( byval hPanel as TK_WIDGET ptr )
sub tkTimePanel_GetRange( byval hPanel as TK_WIDGET ptr, byref tMin as TKTIME, byref tMax as TKTIME, _
sub tkTimePanel_SetRange( byval hPanel as TK_WIDGET ptr, byref tMin as const TKTIME, byref tMax as const TKTIME, _
function tkTimePanel_GetStep( byval hPanel as TK_WIDGET ptr ) as long
sub tkTimePanel_SetStep( byval hPanel as TK_WIDGET ptr, byval nSeconds as long )
function tkTimePanel_GetFormat( byval hPanel as TK_WIDGET ptr ) as ustring
sub tkTimePanel_SetFormat( byval hPanel as TK_WIDGET ptr, byval sPattern as ustring )
sub tkTimePanel_SetAmPmText( byval hPanel as TK_WIDGET ptr, byval sAm as ustring, byval sPm as ustring )
function tkTimePanel_GetAmText( byval hPanel as TK_WIDGET ptr ) as ustring
function tkTimePanel_GetPmText( byval hPanel as TK_WIDGET ptr ) as ustring
function tkTimePanel_GetMode( byval hPanel as TK_WIDGET ptr ) as long
sub tkTimePanel_SetMode( byval hPanel as TK_WIDGET ptr, byval nMode as long )
sub tkTimePanel_SetListRange( byval hPanel as TK_WIDGET ptr, byref tStart as const TKTIME, byref tEnd as const TKTIME, _
sub tkTimePanel_GetListRange( byval hPanel as TK_WIDGET ptr, byref tStart as TKTIME, byref tEnd as TKTIME, _
function tkTimePanel_GetVisibleRows( byval hPanel as TK_WIDGET ptr ) as long
sub tkTimePanel_SetVisibleRows( byval hPanel as TK_WIDGET ptr, byval nRows as long )
function tkTimePanel_GetFont( byval hPanel as TK_WIDGET ptr ) as TTF_Font ptr
sub tkTimePanel_SetFont( byval hPanel as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkTimePanel_GetBorderThickness( byval hPanel as TK_WIDGET ptr ) as long
sub tkTimePanel_SetBorderThickness( byval hPanel as TK_WIDGET ptr, byval nThickness as long )
sub tkTimePanel_GetIdealSize( byval hPanel as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkTimePanel_GetColumnCount( byval hPanel as TK_WIDGET ptr ) as long
function tkTimePanel_GetColumnKind( byval hPanel as TK_WIDGET ptr, byval nCol as long ) as long
function tkTimePanel_GetItemCount( byval hPanel as TK_WIDGET ptr, byval nCol as long ) as long
function tkTimePanel_GetItemValue( byval hPanel as TK_WIDGET ptr, byval nCol as long, byval nIndex as long ) as long
function tkTimePanel_GetItemText( byval hPanel as TK_WIDGET ptr, byval nCol as long, byval nIndex as long ) as ustring
function tkTimePanel_IsItemDisabled( byval hPanel as TK_WIDGET ptr, byval nCol as long, byval nIndex as long ) as boolean
function tkTimePanel_GetSelectedIndex( byval hPanel as TK_WIDGET ptr, byval nCol as long ) as long
function tkTimePanel_GetFocusedColumn( byval hPanel as TK_WIDGET ptr ) as long
sub tkTimePanel_SetFocusedColumn( byval hPanel as TK_WIDGET ptr, byval nCol as long )
function tkTimePanel_GetScrollPos( byval hPanel as TK_WIDGET ptr, byval nCol as long ) as long
sub tkTimePanel_EnsureVisible( byval hPanel as TK_WIDGET ptr )
function tkTimePanel_GetItemRect( byval hPanel as TK_WIDGET ptr, byval nCol as long, byval nIndex as long, _
function tkTimePanel_GetColumnRect( byval hPanel as TK_WIDGET ptr, byval nCol as long, byref rc as TKRECT ) as boolean
function tkTimePanel_HitTest( byval hPanel as TK_WIDGET ptr, byval x as long, byval y as long ) as TKTIMEPANEL_HIT
function tkTimePanel_GetItemHeight( byval hPanel as TK_WIDGET ptr ) as long
sub tkTimePanel_GetColors( byval hPanel as TK_WIDGET ptr, byval pColors as TKTIMEPANEL_COLORS ptr )
sub tkTimePanel_SetColors( byval hPanel as TK_WIDGET ptr, byval pColors as TKTIMEPANEL_COLORS ptr )
function tkTimePanel_ThemeColors( byref t as TKTHEME_COLORS ) as TKTIMEPANEL_COLORS
sub tkTimePanel_ApplyTheme( byval hPanel as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkTimePanel_UnpinColors( byval hPanel as TK_WIDGET ptr )
sub tkTimePanel_ApplyFonts( byval hPanel as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkTimePanel_PaintItemDefault( byval pi as TKTIMEPANEL_ITEMPAINTINFO ptr )
sub tkTimePanel_SetSelChangeCallback( byval hPanel as TK_WIDGET ptr, byval usersub as TP_SelChangeCallbackSub )
sub tkTimePanel_SetAcceptCallback( byval hPanel as TK_WIDGET ptr, byval usersub as TP_AcceptCallbackSub )
sub tkTimePanel_SetDismissCallback( byval hPanel as TK_WIDGET ptr, byval usersub as TP_DismissCallbackSub )
sub tkTimePanel_SetItemDisabledCallback( byval hPanel as TK_WIDGET ptr, byval userfunc as TP_ItemDisabledCallbackFunc )
sub tkTimePanel_SetItemPaintCallback( byval hPanel as TK_WIDGET ptr, byval usersub as TP_ItemPaintCallbackSub )
sub tkTimePanel_SetMessageCallback( byval hPanel as TK_WIDGET ptr, byval userfunc as TP_MessageCallbackFunc )
sub tkTimePanel_SetItemTextCallback( byval hPanel as TK_WIDGET ptr, byval usersub as TP_ItemTextCallbackSub )
function tkTimePanel_EmptyTime() as TKTIME
function tkTimePanel_IsTime( byref t as const TKTIME ) as boolean
function tkTimePanel_MakeTime( byval hh as long, byval mi as long, byval ss as long = 0, byval ms as long = 0 ) as TKTIME
function tkTimePanel_TimeToMs( byref t as const TKTIME ) as long
function tkTimePanel_MsToTime( byval ms as long ) as TKTIME
function tkTimePanel_CompareTime( byref a as const TKTIME, byref b as const TKTIME ) as long
function tkTimePanel_SameTime( byref a as const TKTIME, byref b as const TKTIME ) as boolean
function tkTimePanel_LocalNow() as TKTIME
function tkTimePanel_FormatIso( byref t as const TKTIME, byval bSeconds as boolean = true, byval bMs as boolean = false ) as ustring
function tkTimePanel_ParseIso( byval sText as ustring, byref t as TKTIME ) as boolean
function tkTimePanel_ParseLoose( byval sText as ustring, byref t as TKTIME, _
function tkTimePanel_ParsePattern( byref pattern as const ustring, segs() as TKTIME_SEGMENT, _
function tkTimePanel_SegmentText( byval kind as long, byval nLen as long, byref t as const TKTIME, _
function tkTimePanel_FormatPattern( byref t as const TKTIME, byref pattern as const ustring, _
function tkTimePanel_KeyDigit( byval key as long, byval scancode as long = 0 ) as long
function tkTimePanel_DefaultNames( ) as TKDT_NAMES
function tkTimePanel_IsLeapYear( byval y as long ) as boolean
function tkTimePanel_DaysInMonth( byval y as long, byval m as long ) as long
function tkTimePanel_DayOfWeek( byval y as long, byval m as long, byval d as long ) as long
function tkTimePanel_EmptyDateTime( ) as TKDATETIME
function tkTimePanel_IsDateTime( byref dt as const TKDATETIME ) as boolean
function tkTimePanel_MakeDateTime( byval y as long, byval mo as long, byval d as long, _
function tkTimePanel_TimeOf( byref dt as const TKDATETIME ) as TKTIME
function tkTimePanel_DateTimeToSerial( byref dt as const TKDATETIME ) as longint
function tkTimePanel_SerialToDateTime( byval serial as longint ) as TKDATETIME
function tkTimePanel_CompareDateTime( byref a as const TKDATETIME, byref b as const TKDATETIME ) as long
function tkTimePanel_SameDateTime( byref a as const TKDATETIME, byref b as const TKDATETIME ) as boolean
function tkTimePanel_LocalNowDateTime( ) as TKDATETIME
function tkTimePanel_FormatIsoDateTime( byref dt as const TKDATETIME, byval bSeconds as boolean = true, _
function tkTimePanel_ParseIsoDateTime( byval sText as ustring, byref dt as TKDATETIME ) as boolean
function tkTimePanel_ParseLooseDateTime( byval sText as ustring, byref dt as TKDATETIME, _
function tkTimePanel_SegmentTextDT( byval kind as long, byval nLen as long, byref dt as const TKDATETIME, _
function tkTimePanel_FormatPatternDT( byref dt as const TKDATETIME, byref pattern as const ustring, _
```

### See also

- [tkControls](Category-tkControls)
- [tkTimePicker](tkTimePicker), the field that shows this panel in its dropdown
- [tkCalendar](tkCalendar), the same idea for dates
