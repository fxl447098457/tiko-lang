[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkDatePicker**

# tkDatePicker

Shows an editable date field with a calendar icon that drops down a month calendar.

`tkDatePicker` is the [tkControls](Category-tkControls) date entry. Typing a date into the field
and picking one from the drop-down calendar are two routes to the same `TKDATE` value. The field
is a borderless [tkTextBox](tkTextBox), so caret, selection, undo, paste and the right-click menu
are the text box's; the drop-down is a [tkCalendar](tkCalendar) in a popup, with an optional
"Today: ..." band underneath.

Your program owns the text format: a format callback turns a date into text and a parse callback
turns text back into a date. Without a format callback the field writes ISO `yyyy-MM-dd`; without
a parse callback typed text is never accepted, so only the calendar sets the date.
`tkDatePicker_FormatIso` and `tkDatePicker_ParseIso` are the ISO pair, for callbacks to use or fall
back on. Typed text commits on Enter or when focus leaves the field; text that does not parse
silently reverts. The date-changed callback runs only for a real change by the user. The setters
are silent.

For a form designer, whose rows hold numbers, `tkDatePicker_SetDateParts( h, y, m, d )` sets the
date and `tkDatePicker_SetMinDate` / `SetMaxDate` set one end of the range (a year of 0 removes
it). The border follows the theme's `BorderWidth` until `SetBorderThickness`. A paint callback
replaces the editing box's drawing and a day-paint callback a calendar day's;
`tkDatePicker_PaintDefault( p )` and `tkDatePicker_PaintDayDefault( d )` draw the stock ones first.

F4, Down or Alt+Down opens the calendar. While it is open its own keys work (arrows, Page
Up/Page Down, Home/End, Enter picks), one click on a day picks it, and Escape or a click outside
closes it.

## Importing

```freebasic
#import "vendor/tkControls/tkDatePicker"

using tkDatePicker
using tkHost
using tkCalendar
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkTextBox](tkTextBox) and
[tkCalendar](tkCalendar). `using tkCalendar` names `TKDATE` and `tkCalendar_LocalToday`.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Due_Changed( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr, byval bHasDate as boolean )
    if bHasDate then
        print "due " & pDate->wYear & "-" & pDate->wMonth & "-" & pDate->wDay
    else
        print "no due date"
    end if
end sub

dim as TKDATE today = tkCalendar_LocalToday()
dim as TKDATE last = tkDatePicker_MakeDate( today.wYear + 1, 12, 31 )

dim as TK_WIDGET ptr due = tkDatePicker_Create( tkHost_Root( host ), 6000 )
tkDatePicker_SetWeekStart( due, DTP_MONDAY )
tkDatePicker_SetRange( due, today, last, true, true )
tkDatePicker_SetAllowEmpty( due, true )
tkDatePicker_SetShowTodayFooter( due, true )
tkDatePicker_SetDate( due, today )                  ' silent: no callback
tkDatePicker_SetDateChangedCallback( due, @Due_Changed )

dim as long w, h
tkDatePicker_GetIdealSize( due, w, h )
tkWidget_SetPos( due, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
```

## How it works

### Format and Parse must round-trip

This is the one wiring mistake that produces no error. On a commit the control hands your Parse
callback whatever is in the field; when Parse returns false the field silently reverts to the
last text the control wrote, which looks exactly as if the user typed nothing. So if Format
writes `"Jul 24, 2026"` and Parse only understands digits, every commit after the calendar or a
setter wrote the field fails and reverts. Check that `Parse( Format( d ) ) = d` for a few dates
when you wire the pair, or use `tkDatePicker_FormatIso` / `tkDatePicker_ParseIso` together.
`ParseIso` accepts year, month and day separated by `-`, `/` or `.`, with up to four digits each.

### Focus is the field's

Keyboard focus belongs to the embedded [tkTextBox](tkTextBox), not to the picker widget: ask
`tkDatePicker_HasFocus`. A click on the frame outside the icon focuses the field, and the
field selects its whole text when it takes focus. `tkDatePicker_GetTextBoxHandle` returns the
field for `tkTextBox_*` styling; leave its border and margins alone, because the picker owns both.

### Programmatic setters are silent

`SetDate`, `SetDateParts`, `ClearDate`, `SetRange`, `SetMinDate` / `SetMaxDate` and
`ReformatText` never call the date-changed callback. It runs only for the user: a typed commit
(Enter, or focus leaving the field) or a pick in the calendar, and only when the value really
changed. That is what lets a setter be called from inside your own handler.

The drop-down callback is the exception: it reports the calendar opening and closing, so it
fires for `tkDatePicker_DropDown` and `tkDatePicker_CloseUp` too.

### The layout is derived

The frame, field, divider and icon rects are worked out from the control's size; you read them
back with `GetFrameRect`, `GetFieldRect` and `GetIconRect`, which return false until the control
has been given a non-empty size.

```
icon    = the right nIconWidth pixels, full height
divider = nDividerThick pixels immediately left of the icon
field   = from left + nCornerRadius to the divider,
          inset top and bottom by nBorderThick
```

The field is inset by the corner radius so the frame's rounded left corners show around the
text box's square one; the text box is moved to the field rect at every layout.
`tkDatePicker_HitTest` returns 1 for a point in the icon cell and 0 for anything else.

### The calendar is a popup the control owns

The calendar is a [tkCalendar](tkCalendar) in a popup surface, placed under the control with
the left edges aligned. It is built at every open and destroyed at every close, so
`tkDatePicker_GetCalendarHandle`, `GetPopup` and `GetFooterHandle` return 0 while it is closed.
Every open seeds it from the picker: font, week start, month count, today ring, range, the
selected date, and the days view showing the selected date's month (or today's when there is
no date). Only one picker's calendar is open at a time; opening one closes another.

While it is open the calendar has the keyboard: its arrows, Page Up/Page Down, Home/End and
Enter (which picks), and the wheel over it pages the months. F4, Alt+Up or Alt+Down closes it,
as do Escape, a press outside it (which still reaches whatever it landed on) and focus leaving
the application. A press on the icon that closed the calendar does not reopen it.

A pick (a day click, Enter, or the Today band) closes the calendar first, with the drop-down
callback's closing edge, and then writes the field and calls the date-changed callback. A day
outside the range does nothing.

`tkDatePicker_SetToday( h, st )` pins the date the calendar treats as today, for the ring and
the band; `bPin = false` returns to the local date.

### Sizes

The icon width, field padding, vertical padding, corner radius and Today band height are scaled
for the surface when the control is created, and rescaled when the scale changes (which also
closes an open calendar). Every setter takes pixels as given: scale them with `tkHost_Scale`.
The border and divider are hairlines and are never scaled. Until `SetCornerRadius` or
`SetBorderThickness` is called, both follow the theme's shape (its `CornerRadius`, scaled, and
its `BorderWidth`).

## Behaviour and limits

- `SetMonthCount` takes 1 or 2; anything else is clamped. `SetWeekStart` takes `DTP_MONDAY`,
  and anything else means `DTP_SUNDAY`. Both take effect at the next open.
- The range clamps rather than refuses. `SetDate` and a typed commit clamp into `[min, max]`,
  `SetRange` re-clamps the current date silently, and an inverted pair is swapped. Days outside
  the range are inert in the calendar.
- Empty is a legal value unless `SetAllowEmpty( h, false )`; then committing an empty field
  reverts it to the last valid text. `ClearDate` works either way: the setting governs the
  user, not you.
- `SetShowTodayFooter` on an open calendar adds or removes the band and resizes the popup in
  place. The band shows `"Today: "` plus your Format of today, hot-tracks, and picks today on a
  click; when today is outside the range it is dimmed and inert. There is no keyboard route to
  it.
- `SetEnabled( h, false )` disables the picker and its field, closes an open calendar and
  clears the icon's hover.
- `SetFont` is used by the field, the calendar and the band; the control never frees a font.
  The icon is drawn from rectangles until an icon font is set (`SetIconFont`, or the glyph
  font of `ApplyFonts`); it then draws the icon glyph, `TK_ICON_CALENDAR` by default, in that
  font. `SetIconFont( h, 0 )` returns to the drawn icon.
- `GetIdealSize` measures the field's current text, or `"Wednesday, September 30, 2222"` when
  it is empty, and adds the corner inset, padding, divider and icon; the height is one text
  line plus vertical padding and border. It is valid before the control has been sized.
- There is a tooltip only over the calendar's days, and only when a tooltip callback is set.

## Colours

`TKDATEPICKER_COLORS` is a flat struct. It is filled from the theme when the control is created
and whenever the theme changes, until `SetColors` pins it; `UnpinColors` returns it to the
theme. Read-modify-write it with `GetColors` / `SetColors`, which also repaints the field and
an open calendar. `tkDatePicker_ThemeColors( t )` gives the struct a theme maps to.

| Field | Theme role | Paints |
| --- | --- | --- |
| `BackColor` | `Window` | The client behind the rounded frame |
| `BorderColor` / `FocusBorderColor` / `BorderColorDisabled` | `Border` / `FocusRing` / `BorderDisabled` | The frame outline: at rest, while the field has focus, disabled |
| `DividerColor` / `DividerColorDisabled` | `Divider` / `BorderDisabled` | The hairline between field and icon |
| `FieldBackColor` / `FieldBackColorDisabled` | `Surface` / `SurfaceDisabled` | The frame and field fill |
| `FieldForeColor` / `FieldForeColorDisabled` | `Text` / `TextDisabled` | The date text, drawn by the field |
| `IconColor` / `IconBackColorHot` | `Surface` / `SurfaceHot` | The icon cell at rest (flat, like the field) and while hovered or pressed |
| `IconGlyphColor` / `IconGlyphColorHot` / `IconGlyphColorDisabled` | `Text` / `TextHot` / `TextDisabled` | The icon |
| `CalBackColor` / `CalBorderColor` | `Popup` / `Border` | The popup's background and one-pixel outline |
| `TitleColor` / `TitleColorHot` | `TextHot` / `TextStrong` | The calendar's title and captions; the title under the mouse |
| `NavGlyphColor` / `NavGlyphColorHot` / `NavGlyphColorDisabled` | `Text` / `TextHot` / `TextDisabled` | The chevrons; disabled when nothing in range lies that way |
| `WeekdayColor` | `TextDim` | The weekday header row |
| `DayColor` / `DayColorWeekend` | `PopupText` / `AccentHot` | A day number, ordinary and weekend |
| `DayColorAdjacent` | `TextDim` | A day of the neighbouring month, which can still be picked |
| `DayColorDisabled` | `TextDisabled` | A day outside the range, inert |
| `DayBackColorHot` / `DayForeColorHot` | `SurfaceHot` / `TextHot` | The day under the mouse |
| `DayBackColorSelected` / `DayForeColorSelected` | `Selected` / `SelectedText` | The selected day |
| `TodayRingColor` | `Accent` | The ring on today's cell |
| `TodayFooterColor` / `TodayFooterColorHot` / `TodayFooterColorDisabled` | `TextDim` / `TextHot` / `TextDisabled` | The Today band's caption: at rest, hovered, today out of range |

`FocusBorderColor` is also the calendar's focus ring. Keep `DayColorAdjacent` and
`DayColorDisabled` clearly apart: an adjacent day can be picked and a disabled one cannot, and
in a short range most of the month is one or the other.

The built-in editing-box painter fills the client with `BackColor`, fills the rounded frame,
fills the icon cell (rounded on its outer corners only), draws the divider and the icon, and
draws the outline last.

## Callbacks

- **Parse**, `DTP_ParseCallbackFunc( hCtrl, sText, pDate )`: called on a commit with the
  field's text. Fill `*pDate` and return true, or return false to make the field revert. Empty
  text never reaches it (see `SetAllowEmpty`), and the date it returns is clamped afterwards.
  Without one, typed text is never accepted.
- **Format**, `DTP_FormatCallbackSub( hCtrl, pDate, sOut )`: called whenever the control
  writes the field (a setter, a pick, a successful parse, `ReformatText`, and
  `SetFormatCallback` itself, which re-renders at once) and for the Today band's caption.
  Without one the field is ISO `yyyy-MM-dd`.
- **Date changed**, `DTP_DateChangedCallbackSub( hCtrl, pDate, bHasDate )`: user action only,
  and only for a real change. `bHasDate` is false when the user cleared the field, and `pDate`
  then still holds the previous value: test the flag, not the pointer.
- **Drop-down**, `DTP_DropDownCallbackSub( hCtrl, isOpen )`: opening and closing, programmatic
  ones included. The opening edge runs before the calendar is built or seeded, which makes it
  the place to set a range or month count that depends on current state. If the popup cannot
  be made, the closing edge follows at once so the pair still matches.
- **Paint**, `DTP_PaintCallbackSub( p )`: replaces the editing-box painter (frame, divider,
  icon). The client is already filled with `BackColor`, and the field draws its text on top of
  whatever you paint in `rcField`. `tkDatePicker_PaintDefault( p )` draws the stock box first.
  `TKDATEPICKER_PAINTINFO` carries the rects and the enabled, focused, open, icon-hot and
  icon-pressed states.
- **Day paint**, `DTP_DayPaintCallbackSub( p )`: draws one calendar day cell instead of the
  built-in painter; `tkDatePicker_PaintDayDefault( p )` draws the stock cell first.
  `TKDATEPICKER_DAYPAINTINFO` names the picker (not the calendar) in `hCtrl`, the cell in
  calendar pixels, its date and day number, the panel (`monthIndex`, 0 or 1), and the
  adjacent, weekend, today, selected, hot, disabled and enabled flags.
- **Message**, `DTP_MessageCallbackFunc( m )`: sees the picker's `TKM_*` messages and the
  field's, all reported with the picker in `hCtrl`; return true to suppress the control's own
  handling. The return value is ignored for `TKM_SIZE`, `TKM_MOUSELEAVE`, `TKM_LBUTTONUP`,
  `TKM_ENABLE` and the field's `TKM_KILLFOCUS` (which commits the typed text), because the
  control's state has already moved. Keys the field leaves unclaimed arrive as the picker's
  `TKM_KEYDOWN`.
- **Tooltip**, `DTP_TooltipCallbackFunc( t )`: fill `outText` for the day under the mouse and
  return true, or return false (or leave it empty) for no tip. `isValid` is false when the
  mouse is not over a day. Setting it is what turns tooltips on; the tip uses
  [tkTooltip](tkTooltip) timing, and `tkDatePicker_GetTooltipHandle` returns its `TK_TIP ptr`
  while the calendar is open.

## Date helpers and test probes

The date helpers are pure functions, safe before any control exists: `IsLeapYear` (proleptic
Gregorian), `DaysInMonth`, `DateToSerial` / `SerialToDate` (a day count, so month and year
rollovers are plain arithmetic), `DowSunday` (0 = Sunday ... 6 = Saturday), `LeadingCells`
(0-6 cells of the previous month at the start of the grid for a week start), `MakeDate`,
`AddMonths` (whole months, the day clamped to the target month: 31 Jan + 1 month is the end of
February) and `DecadeBase` (2021 → 2020).

`tkDatePicker_TestCalendarTones` (distinct colours over the open calendar), `TestFooterTones`
(the same inside the Today band, 0 when there is none) and `TestPartBrightness( h, nPart )`
(the brightest pixel of a part: 0 the previous chevron, 1 the next, `100 + k` day cell *k* of
the first panel) render the open calendar so a test can check that a replaced day painter or a
disabled part really draws as intended. They take the picker and return 0 (or -1 for
`TestPartBrightness`) while the calendar is closed.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const CDTP_DEFAULT_ICONWIDTH = 28
const CDTP_DEFAULT_FIELDPAD = 6
const CDTP_DEFAULT_VERTPAD = 5
const CDTP_DEFAULT_CORNERRADIUS = 6
const CDTP_DEFAULT_BORDERTHICK = 1 ' never scaled: a hairline
const CDTP_DEFAULT_DIVIDERTHICK = 1 ' never scaled
const CDTP_DEFAULT_ICONGLYPH = TK_ICON_CALENDAR
const CDTP_CAL_BORDERTHICK = 1 ' the popup's outline; never scaled
const CDTP_CAL_FOOTERH = 30 ' the Today band

enum
    DTP_SUNDAY = 0
    DTP_MONDAY = 1
end enum

enum
    DTP_VIEW_DAYS = 0
    DTP_VIEW_MONTHS
    DTP_VIEW_YEARS
end enum
```

### Types

```freebasic
type TKDATEPICKER_COLORS
    BackColor                as ulong = &hFF21252Bul    ' behind the rounded corners
    BorderColor              as ulong = &hFF3C424Dul
    FocusBorderColor         as ulong = &hFF569CD6ul    ' while the field has focus
    BorderColorDisabled      as ulong = &hFF30343Cul
    DividerColor             as ulong = &hFF3C424Dul
    DividerColorDisabled     as ulong = &hFF30343Cul
    FieldBackColor           as ulong = &hFF2C313Aul
    FieldForeColor           as ulong = &hFFD7DAE0ul
    FieldBackColorDisabled   as ulong = &hFF262A31ul
    FieldForeColorDisabled   as ulong = &hFF5A606Aul
    IconColor                as ulong = &hFF2C313Aul    ' = FieldBackColor (flat at rest)
    IconGlyphColor           as ulong = &hFFBEC4CEul
    IconGlyphColorHot        as ulong = &hFFFFFFFFul
    IconBackColorHot         as ulong = &hFF383E49ul
    IconGlyphColorDisabled   as ulong = &hFF5A606Aul
    CalBackColor             as ulong = &hFF21252Bul
    CalBorderColor           as ulong = &hFF464C58ul
    TitleColor               as ulong = &hFFE1E4EAul
    TitleColorHot            as ulong = &hFFFFFFFFul
    NavGlyphColor            as ulong = &hFFBEC4CEul
    NavGlyphColorHot         as ulong = &hFFFFFFFFul
    NavGlyphColorDisabled    as ulong = &hFF464A52ul
    WeekdayColor             as ulong = &hFF8C929Cul
    DayColor                 as ulong = &hFFD2D6DCul
    DayColorWeekend          as ulong = &hFF96AFCDul
    DayColorAdjacent         as ulong = &hFF7C838Eul    ' still clickable: keep it far from Disabled
    DayColorDisabled         as ulong = &hFF383C44ul    ' out of range, inert
    DayBackColorHot          as ulong = &hFF343A44ul
    DayForeColorHot          as ulong = &hFFFFFFFFul
    DayBackColorSelected     as ulong = &hFF0078D7ul
    DayForeColorSelected     as ulong = &hFFFFFFFFul
    TodayRingColor           as ulong = &hFF569CD6ul
    TodayFooterColor         as ulong = &hFFAAB0BAul
    TodayFooterColorHot      as ulong = &hFFFFFFFFul
    TodayFooterColorDisabled as ulong = &hFF464A52ul    ' today is outside the range
end type

type TKDATEPICKER_PAINTINFO
    hCtrl       as TK_WIDGET ptr
    b           as TK_PAINT ptr
    rcClient    as TKRECT
    rcFrame     as TKRECT
    rcField     as TKRECT
    rcDiv       as TKRECT
    rcIcon      as TKRECT
    isEnabled   as boolean
    isFocused   as boolean
    isOpen      as boolean
    iconHot     as boolean
    iconPressed as boolean
end type

type TKDATEPICKER_DAYPAINTINFO
    hCtrl       as TK_WIDGET ptr       ' the PICKER, not the calendar
    b           as TK_PAINT ptr
    rcCell      as TKRECT              ' calendar-local pixels
    stDate      as TKDATE
    dayNumber   as long
    monthIndex  as long                ' 0 = left / only panel, 1 = right
    isAdjacent  as boolean
    isWeekend   as boolean
    isToday     as boolean
    isSelected  as boolean
    isHot       as boolean
    isDisabled  as boolean
    isEnabled   as boolean
end type

type TKDATEPICKER_MESSAGEINFO
    hCtrl       as TK_WIDGET ptr       ' the picker, also for a message that reached the field
    msg         as long                ' TKM_* (or TKTEXTBOX_MSG_CONTEXTMENU from the field)
    x           as single
    y           as single
    key         as long
    mods        as long
    text        as string
end type

type TKDATEPICKER_TOOLTIPINFO
    hCtrl       as TK_WIDGET ptr
    stDate      as TKDATE
    isValid     as boolean
    outText     as ustring
end type

type TKDATEPICKER_STATE   ' per-instance state; reach it through the procedures

type DTP_ParseCallbackFunc as function( byval hCtrl as TK_WIDGET ptr, byval sText as ustring, byval pDate as TKDATE ptr ) as boolean
type DTP_FormatCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr, byref sOut as ustring )
type DTP_DateChangedCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval pDate as TKDATE ptr, byval bHasDate as boolean )
type DTP_DropDownCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval isOpen as boolean )
type DTP_PaintCallbackSub as sub( byval p as TKDATEPICKER_PAINTINFO ptr )
type DTP_DayPaintCallbackSub as sub( byval p as TKDATEPICKER_DAYPAINTINFO ptr )
type DTP_MessageCallbackFunc as function( byval m as TKDATEPICKER_MESSAGEINFO ptr ) as boolean
type DTP_TooltipCallbackFunc as function( byval t as TKDATEPICKER_TOOLTIPINFO ptr ) as boolean
```

### Procedures

```freebasic
function tkDatePicker_IsLeapYear( byval y as long ) as boolean
function tkDatePicker_DaysInMonth( byval y as long, byval m as long ) as long
function tkDatePicker_DateToSerial( byval y as long, byval m as long, byval d as long ) as longint
sub tkDatePicker_SerialToDate( byval serial as longint, byref y as long, byref m as long, byref d as long )
function tkDatePicker_DowSunday( byval y as long, byval m as long, byval d as long ) as long
function tkDatePicker_LeadingCells( byval y as long, byval m as long, byval nWeekStart as long ) as long
function tkDatePicker_MakeDate( byval y as long, byval m as long, byval d as long ) as TKDATE
function tkDatePicker_AddMonths( byref st as TKDATE, byval delta as long ) as TKDATE
function tkDatePicker_DecadeBase( byval y as long ) as long
function tkDatePicker_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkDatePicker_GetTextBoxHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkDatePicker_GetCalendarHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkDatePicker_GetPopup( byval hCtrl as TK_WIDGET ptr ) as TK_HOST ptr
function tkDatePicker_GetFooterHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkDatePicker_HasFocus( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkDatePicker_GetDate( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE ) as boolean
sub tkDatePicker_SetDate( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE )
sub tkDatePicker_ClearDate( byval hCtrl as TK_WIDGET ptr )
function tkDatePicker_HasDate( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDatePicker_GetRange( byval hCtrl as TK_WIDGET ptr, byref stMin as TKDATE, byref stMax as TKDATE, byref bHasMin as boolean, byref bHasMax as boolean )
sub tkDatePicker_SetRange( byval hCtrl as TK_WIDGET ptr, byref stMin as TKDATE, byref stMax as TKDATE, byval bHasMin as boolean, byval bHasMax as boolean )
function tkDatePicker_GetAllowEmpty( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDatePicker_SetAllowEmpty( byval hCtrl as TK_WIDGET ptr, byval bAllow as boolean )
sub tkDatePicker_ReformatText( byval hCtrl as TK_WIDGET ptr )
sub tkDatePicker_SetToday( byval hCtrl as TK_WIDGET ptr, byref st as TKDATE, byval bPin as boolean = true )
function tkDatePicker_GetWeekStart( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDatePicker_SetWeekStart( byval hCtrl as TK_WIDGET ptr, byval nWeekStart as long )
function tkDatePicker_GetMonthCount( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDatePicker_SetMonthCount( byval hCtrl as TK_WIDGET ptr, byval nCount as long )
function tkDatePicker_GetShowToday( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDatePicker_SetShowToday( byval hCtrl as TK_WIDGET ptr, byval bShow as boolean )
function tkDatePicker_GetShowTodayFooter( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDatePicker_SetShowTodayFooter( byval hCtrl as TK_WIDGET ptr, byval bShow as boolean )
sub tkDatePicker_DropDown( byval hCtrl as TK_WIDGET ptr )
sub tkDatePicker_CloseUp( byval hCtrl as TK_WIDGET ptr )
function tkDatePicker_IsDroppedDown( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkDatePicker_GetFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkDatePicker_SetFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkDatePicker_GetIconFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkDatePicker_SetIconFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkDatePicker_GetIconGlyph( byval hCtrl as TK_WIDGET ptr ) as ustring
sub tkDatePicker_SetIconGlyph( byval hCtrl as TK_WIDGET ptr, byval sGlyph as ustring )
function tkDatePicker_GetIconWidth( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDatePicker_SetIconWidth( byval hCtrl as TK_WIDGET ptr, byval nWidth as long )
function tkDatePicker_GetCornerRadius( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDatePicker_SetCornerRadius( byval hCtrl as TK_WIDGET ptr, byval nRadius as long )
function tkDatePicker_GetBorderThickness( byval hCtrl as TK_WIDGET ptr ) as long
sub tkDatePicker_SetBorderThickness( byval hCtrl as TK_WIDGET ptr, byval nThickness as long )
sub tkDatePicker_GetIdealSize( byval hCtrl as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkDatePicker_GetEnabled( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDatePicker_SetEnabled( byval hCtrl as TK_WIDGET ptr, byval isEnabled as boolean )
sub tkDatePicker_Refresh( byval hCtrl as TK_WIDGET ptr )
function tkDatePicker_GetFrameRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkDatePicker_GetFieldRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkDatePicker_GetIconRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkDatePicker_HitTest( byval hCtrl as TK_WIDGET ptr, byval pt as TKPOINT ) as long
function tkDatePicker_GetIconHot( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkDatePicker_GetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKDATEPICKER_COLORS ptr )
sub tkDatePicker_SetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKDATEPICKER_COLORS ptr )
function tkDatePicker_ThemeColors( byref t as TKTHEME_COLORS ) as TKDATEPICKER_COLORS
sub tkDatePicker_ApplyTheme( byval hCtrl as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkDatePicker_UnpinColors( byval hCtrl as TK_WIDGET ptr )
sub tkDatePicker_ApplyFonts( byval hCtrl as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkDatePicker_SetParseCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as DTP_ParseCallbackFunc )
sub tkDatePicker_SetFormatCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTP_FormatCallbackSub )
sub tkDatePicker_SetDateChangedCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTP_DateChangedCallbackSub )
sub tkDatePicker_SetDropDownCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTP_DropDownCallbackSub )
sub tkDatePicker_SetPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTP_PaintCallbackSub )
sub tkDatePicker_SetDayPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as DTP_DayPaintCallbackSub )
sub tkDatePicker_SetMessageCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as DTP_MessageCallbackFunc )
sub tkDatePicker_SetTooltipCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as DTP_TooltipCallbackFunc )
function tkDatePicker_GetTooltipHandle( byval hCtrl as TK_WIDGET ptr ) as TK_TIP ptr
function tkDatePicker_FormatIso( byval pDate as TKDATE ptr ) as ustring
function tkDatePicker_ParseIso( byval sText as ustring, byval pDate as TKDATE ptr ) as boolean
sub tkDatePicker_SetDateParts( byval hCtrl as TK_WIDGET ptr, byval y as long, byval m as long, byval d as long )
sub tkDatePicker_SetMinDate( byval hCtrl as TK_WIDGET ptr, byval y as long, byval m as long, byval d as long )
sub tkDatePicker_SetMaxDate( byval hCtrl as TK_WIDGET ptr, byval y as long, byval m as long, byval d as long )
sub tkDatePicker_PaintDefault( byval pi as TKDATEPICKER_PAINTINFO ptr )
sub tkDatePicker_PaintDayDefault( byval d as TKDATEPICKER_DAYPAINTINFO ptr )
function tkDatePicker_TestCalendarTones( byval hCtrl as TK_WIDGET ptr ) as long
function tkDatePicker_TestPartBrightness( byval hCtrl as TK_WIDGET ptr, byval nPart as long ) as long
function tkDatePicker_TestFooterTones( byval hCtrl as TK_WIDGET ptr ) as long
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkCalendar](tkCalendar), [tkTextBox](tkTextBox), [tkTooltip](tkTooltip)
