[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkNumericUpDown**

# tkNumericUpDown

Draws a numeric spinner: a typed value between minus and plus buttons, kept in range.

`tkNumericUpDown` is the [tkControls](Category-tkControls) number entry: a rounded frame with a
"−" button, an editable value cell and a "+" button. The value lives on a decimal grid
(`SetDecimalPlaces`) and is clamped to its range; it never wraps. A button steps on the press and
repeats while held (`SetAutoRepeat`); the arrow keys, Page Up/Page Down (the large increment) and
the mouse wheel step too, and a button at its limit draws as disabled.

The value-changed callback runs at once for buttons, keys and the wheel, and on commit (Enter or
focus loss) for typed text. Every setter is silent. Read-only blocks typing but not stepping.

`tkNumericUpDown_SetTooltipText` gives the control a tooltip, shown while the pointer rests on any
part of it, the value field included; `SetHoverTime`, `SetAutoPopTime` and `SetReshowTime` set its
delays, and `GetTooltipHandle` reaches the tkTooltip itself. The border follows the theme's
`BorderWidth` until `SetBorderThickness` is called. A paint callback replaces the drawing; call
`tkNumericUpDown_PaintDefault( p )` in it to draw the stock control first and add to it.

## Importing

```freebasic
#import "vendor/tkControls/tkNumericUpDown"

using tkNumericUpDown
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTextBox](tkTextBox), whose single-line numeric box is the
value cell. Add `using tkPaint` for a paint callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Zoom_Changed( byval hCtrl as TK_WIDGET ptr, byval nValue as double )
    print "zoom " & nValue & "x"
end sub

dim as TK_WIDGET ptr zoom = tkNumericUpDown_Create( tkHost_Root( host ), 5000 )
tkNumericUpDown_SetDecimalPlaces( zoom, 2 )
tkNumericUpDown_SetRange( zoom, 0.5, 3 )
tkNumericUpDown_SetIncrement( zoom, 0.25 )
tkNumericUpDown_SetLargeIncrement( zoom, 1 )
tkNumericUpDown_SetValue( zoom, 1.5 )               ' silent: no callback
tkNumericUpDown_SetValueChangedCallback( zoom, @Zoom_Changed )

dim as long w, h
tkNumericUpDown_GetIdealSize( zoom, w, h )         ' measured from both ends of the range
tkWidget_SetPos( zoom, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
```

## The value field

`tkNumericUpDown_Create( hParent, CtrlID )` makes the control as a child of `hParent` (for a
top-level control pass `tkHost_Root( host )`); `tkNumericUpDown_GetID` returns `CtrlID`. The
value cell is a [tkTextBox](tkTextBox) child widget: borderless, in numeric mode, centred, with an
empty field reading as zero. `tkNumericUpDown_GetTextBoxHandle` returns it, and any `tkTextBox_*`
setter applies to it except `SetValue`, `SetDecimalPlaces` and `SetBorderWidth` and its focus,
Enter and message callbacks, which the spinner owns. Typing, selection, the clipboard and the
right-click menu are the text box's own.

- The control itself is not a tab stop; the field is. `tkNumericUpDown_HasFocus` asks the field,
  and giving the control the focus passes it to the field.
- Arriving by Tab selects the whole number, so the first keystroke replaces it. Clicking a button
  focuses the field without selecting it.
- Focus recolours the frame (`FocusBorderColor`); there is no separate ring, so the size does not
  change when focus arrives.
- `tkNumericUpDown_SetFont` hands the font to the field; it is borrowed, so keep it alive. There
  is no glyph font: the "−" and "+" are drawn bars. With no font set, the host's default font
  is measured.

## Value, range and stepping

- Every value, whatever its route, is **snapped to the decimal grid** (half away from zero), not
  merely rounded for display, and then **clamped** into the range. The range never wraps. The
  default range is ±1,000,000, so an unconfigured control does not visibly clamp.
- A step starts from what is in the field, not from the last committed value: typing `50` and
  pressing "+" gives `51`. Typed text that is out of range is clamped on the way in.
- `tkNumericUpDown_SetRange` swaps an inverted pair rather than rejecting it, and re-clamps the
  value. `tkNumericUpDown_SetDecimalPlaces` floors a negative count at 0, re-snaps the value onto
  the new grid (`16.25` at 2 places becomes `16` at 0), and at 0 places the field refuses a
  decimal point. Set the decimal places and the range before the value: both rewrite it.
- `SetIncrement` (buttons, arrows, one wheel notch) and `SetLargeIncrement` (Page Up/Page Down)
  store the magnitude, so "−" always goes down. The large increment defaults to 10.
- `tkNumericUpDown_GetValue` returns the **committed** value: while the user is typing it still
  reports the last committed number, and so does the buttons' at-a-limit look.

## Mouse and keyboard

- **The step happens on the button press**, not the release, so sliding off a pressed button
  does not undo it. A double click is two presses.
- Holding a button repeats after the delay, then at the interval (`SetAutoRepeat`, 400 and 60 ms
  by default). The repeat pauses when the pointer leaves the button and resumes after the full
  delay when it comes back, and it stops dead at a limit. Either timing at or below zero turns
  repeating off and stops a running one.
- In the field, Up and Down step by the increment and Page Up / Page Down by the large
  increment. Home and End are not claimed; they move the caret.
- The wheel, over the field or a button, steps one increment per notch; partial notches
  accumulate.
- The right button over the buttons is reported to the message callback and never acted on.
  `tkNumericUpDown_HitTest` reports `NUD_PART_VALUE` but the control never acts on it: the field
  covers that cell and takes its own mouse input.
- **Read-only** (`SetReadOnly`) blocks typing only; the buttons, keys and wheel still step.
  **Disabling** (`tkNumericUpDown_SetEnabled` or `tkWidget_Enable`) disables the field with it,
  clears the hover, cancels a press and its repeat, and hides the tooltip.

## Notifications

The value-changed callback reports **user** action only, after the value has been snapped,
clamped and displayed, so `tkNumericUpDown_GetValue` already equals `nValue`. It fires only when
the value really changed.

| Input | When the callback fires |
|---|---|
| "−" / "+" press, each repeat tick | at once |
| Up / Down, Page Up / Page Down, the wheel | at once |
| Typing | on commit only: Enter, or focus leaving the field |
| `SetValue`, `SetRange`, `SetDecimalPlaces`, `StepUp`, `StepDown` | never |

Typing `16` therefore never reports the transient `1`, and the commit is also when typed text is
clamped, snapped and reformatted (`5.` becomes `5.00`). Because setters are silent, calling
`SetValue` inside the callback does not recurse. `StepUp` / `StepDown` do exactly what the
buttons do, minus the notification.

## Layout

The control derives nine rects from its size:

```
  rcFrame    = the whole control (the outline is stroked inside it, over the cells)
  rcMinus    = left edge .. + buttonWidth, full height
  rcDiv1     = rcMinus.right .. + dividerThickness
  rcPlus     = right edge - buttonWidth .. right edge, full height
  rcDiv2     = rcPlus.left - dividerThickness .. rcPlus.left
  rcValue    = rcDiv1.right .. rcDiv2.left, inset top and bottom by border + vertical padding
  rcMinusBar = glyphLength x glyphThickness, centred in rcMinus
  rcPlusBarH / rcPlusBarV = the same bar, both centred on rcPlus's centre
```

- The button cells are not inset by the border; only `rcValue` is, and the field sits exactly on
  it. When the control is too short for the vertical padding, `rcValue` is inset by the border
  alone.
- Too narrow for both buttons and dividers, the value cell collapses to zero width (it never
  inverts) and the field is hidden; the buttons keep their width and clip at the edge.
- `tkNumericUpDown_GetIdealSize` measures both ends of the range at the current decimal places
  and takes the wider, so `-1000` costs more than `999`. It is valid before the control has been
  sized:

  ```
  width  = 2*buttonWidth + 2*dividerThickness + padLeft + padRight + widestEnd
  height = fontHeight + 2*vertPadding + 2*borderThickness
  ```

- Setters take pixels and clamp negatives to 0; `SetGlyphSize` floors both values at 1. A corner
  radius of 0 gives square corners, a border of 0 no frame, a divider of 0 no dividers (and no
  space for them).
- The defaults are scaled at creation and rescaled when the display scale changes, the glyph
  thickness included (it is an icon stroke); the border and the dividers are hairlines and keep
  their thickness. The corner radius and the border follow the theme's shape (`CornerRadius`,
  `BorderWidth`) until `SetCornerRadius` or `SetBorderThickness` sets them.
- Layout is lazy: setters mark it stale, and the next paint or rect query recomputes it. The rect
  queries return FALSE until the control has a size.

## Colours and theme

The colours start from the current [tkTheme](tkTheme) palette (`tkNumericUpDown_ThemeColors`,
plus the theme's own recipes for the control) and follow theme changes;
`tkNumericUpDown_SetColors` pins them, and `tkNumericUpDown_UnpinColors` hands them back. The four
`Value*` fields are handed to the field rather than painted here, and re-applied when the enabled
state changes; the field's selection and cue colours come from the theme.

- `ButtonBackColor` equals `ValueBackColor` by default, so at rest the control reads as one flat
  rounded cell divided by hairlines.
- A button cell: disabled (the control disabled **or** this button at its limit) > pressed (held
  with the pointer still on it) > hot > idle.
- The outline: disabled > focused > idle.

The built-in painter fills the control with `BackColor` (seen outside the rounded corners), fills
the frame as a rounded rect in the value background, fills each button cell as a rounded rect
extended past its divider and clipped to its cell (so only its outer rounding shows), draws the
dividers and the glyph bars as plain rects, and strokes the outline last.

## Callbacks

**Paint.** The paint callback replaces the frame, the cells, the dividers and the glyphs, never
the number: the field paints that over `rcValue`. The control is already filled with `BackColor`;
call `tkNumericUpDown_PaintDefault( p )` to draw the stock control and add to it. Use the rects as
given; `pressedPart` is set only while the pointer is still on the pressed button, and `bAtMin` /
`bAtMax` say which button to draw disabled. `PaintBorderRect` and `PaintRoundBorderRect` fill
before they stroke, so as a frame they flood everything beneath; use `PaintRoundOutline` (radius
0 for square).

**Message.** One stream covers the whole control: its own mouse messages, the wheel, the right
button, the repeat's `TKM_TIMER` ticks and `TKM_ENABLE`, plus the field's key, character, mouse, wheel and focus
messages, relayed with `hCtrl` set to the spinner. Returning TRUE suppresses the control's
handling of a left press, the wheel and the field's messages, so a host can repurpose the arrow
keys, Page Up/Page Down or the wheel. It is ignored for `TKM_LBUTTONUP`, which ends a press, and
`TKM_KILLFOCUS`, which commits typing.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKNUD_DEFAULT_BUTTONW = 28
const TKNUD_DEFAULT_VALUEPAD = 6 ' left and right, inside the value cell
const TKNUD_DEFAULT_VERTPAD = 5 ' above and below the text
const TKNUD_DEFAULT_CORNERRADIUS = 6
const TKNUD_DEFAULT_BORDERTHICK = 1 ' not scaled
const TKNUD_DEFAULT_DIVIDERTHICK = 1 ' not scaled
const TKNUD_DEFAULT_GLYPHLENGTH = 10
const TKNUD_DEFAULT_GLYPHTHICK = 1 ' SCALED: an icon stroke, not a rule
const TKNUD_DEFAULT_REPEATDELAY = 400
const TKNUD_DEFAULT_REPEATINTERVAL = 60
const TKNUD_DEFAULT_MIN = -1000000.0
const TKNUD_DEFAULT_MAX = 1000000.0
const TKNUD_DEFAULT_INCREMENT = 1.0
const TKNUD_DEFAULT_DECIMALPLACES = 0

enum
    NUD_PART_NONE = 0
    NUD_PART_MINUS
    NUD_PART_VALUE       ' reported by HitTest, never acted on
    NUD_PART_PLUS
end enum
```

### Types

```freebasic
type TKNUMERICUPDOWN_COLORS
    BackColor                as ulong = &hFF21252Bul    ' behind the rounded corners
    BorderColor              as ulong = &hFF3C424Dul
    FocusBorderColor         as ulong = &hFF569CD6ul
    BorderColorDisabled      as ulong = &hFF30343Cul
    DividerColor             as ulong = &hFF3C424Dul
    DividerColorDisabled     as ulong = &hFF30343Cul
    ValueBackColor           as ulong = &hFF2C313Aul    ' handed to the tkTextBox
    ValueForeColor           as ulong = &hFFD7DAE0ul
    ValueBackColorDisabled   as ulong = &hFF262A31ul
    ValueForeColorDisabled   as ulong = &hFF5A606Aul
    ButtonBackColor          as ulong = &hFF2C313Aul    ' = ValueBackColor: one flat cell at rest
    ButtonBackColorHot       as ulong = &hFF383E49ul
    ButtonBackColorPressed   as ulong = &hFF264F78ul
    ButtonBackColorDisabled  as ulong = &hFF262A31ul
    GlyphColor               as ulong = &hFFBEC4CEul
    GlyphColorHot            as ulong = &hFFFFFFFFul
    GlyphColorPressed        as ulong = &hFFFFFFFFul
    GlyphColorDisabled       as ulong = &hFF5A606Aul
end type

type TKNUMERICUPDOWN_PAINTINFO
    hCtrl        as TK_WIDGET ptr
    b            as TK_PAINT ptr
    rcClient     as TKRECT
    rcFrame      as TKRECT
    rcMinus      as TKRECT
    rcDiv1       as TKRECT
    rcValue      as TKRECT
    rcDiv2       as TKRECT
    rcPlus       as TKRECT
    rcMinusBar   as TKRECT
    rcPlusBarH   as TKRECT
    rcPlusBarV   as TKRECT
    hotPart      as long
    pressedPart  as long
    isEnabled    as boolean
    isFocused    as boolean
    bAtMin       as boolean
    bAtMax       as boolean
    nValue       as double
end type

type TKNUMERICUPDOWN_MESSAGEINFO
    hCtrl as TK_WIDGET ptr            ' this control, ALWAYS -- also for the field's relayed messages
    msg   as long                     ' TKM_*
    x     as single
    y     as single
    key   as long
    mods  as long
    wheelY as single                  ' TKM_MOUSEWHEEL: notches, positive = away
end type

type TKNUMERICUPDOWN_STATE   ' per-instance state; reach it through the procedures

type NUD_PaintCallbackSub as sub( byval p as TKNUMERICUPDOWN_PAINTINFO ptr )
type NUD_MessageCallbackFunc as function( byval m as TKNUMERICUPDOWN_MESSAGEINFO ptr ) as boolean
type NUD_ValueChangedCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval nValue as double )
```

### Procedures

```freebasic
function tkNumericUpDown_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkNumericUpDown_GetTextBoxHandle( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkNumericUpDown_HasFocus( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkNumericUpDown_GetID( byval hCtrl as TK_WIDGET ptr ) as long
function tkNumericUpDown_GetEnabled( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkNumericUpDown_SetEnabled( byval hCtrl as TK_WIDGET ptr, byval isEnabled as boolean )
sub tkNumericUpDown_Refresh( byval hCtrl as TK_WIDGET ptr )
function tkNumericUpDown_GetValue( byval hCtrl as TK_WIDGET ptr ) as double
sub tkNumericUpDown_SetValue( byval hCtrl as TK_WIDGET ptr, byval nValue as double )
sub tkNumericUpDown_GetRange( byval hCtrl as TK_WIDGET ptr, byref nMin as double, byref nMax as double )
sub tkNumericUpDown_SetRange( byval hCtrl as TK_WIDGET ptr, byval nMin as double, byval nMax as double )
function tkNumericUpDown_GetIncrement( byval hCtrl as TK_WIDGET ptr ) as double
sub tkNumericUpDown_SetIncrement( byval hCtrl as TK_WIDGET ptr, byval nIncrement as double )
function tkNumericUpDown_GetLargeIncrement( byval hCtrl as TK_WIDGET ptr ) as double
sub tkNumericUpDown_SetLargeIncrement( byval hCtrl as TK_WIDGET ptr, byval nIncrement as double )
function tkNumericUpDown_GetDecimalPlaces( byval hCtrl as TK_WIDGET ptr ) as long
sub tkNumericUpDown_SetDecimalPlaces( byval hCtrl as TK_WIDGET ptr, byval nPlaces as long )
sub tkNumericUpDown_StepUp( byval hCtrl as TK_WIDGET ptr )
sub tkNumericUpDown_StepDown( byval hCtrl as TK_WIDGET ptr )
sub tkNumericUpDown_GetAutoRepeat( byval hCtrl as TK_WIDGET ptr, byref nDelayMs as long, byref nIntervalMs as long )
sub tkNumericUpDown_SetAutoRepeat( byval hCtrl as TK_WIDGET ptr, byval nDelayMs as long, byval nIntervalMs as long )
function tkNumericUpDown_GetReadOnly( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkNumericUpDown_SetReadOnly( byval hCtrl as TK_WIDGET ptr, byval bReadOnly as boolean )
function tkNumericUpDown_GetFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkNumericUpDown_SetFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkNumericUpDown_GetButtonWidth( byval hCtrl as TK_WIDGET ptr ) as long
sub tkNumericUpDown_SetButtonWidth( byval hCtrl as TK_WIDGET ptr, byval nWidth as long )
sub tkNumericUpDown_GetValuePadding( byval hCtrl as TK_WIDGET ptr, byref nLeft as long, byref nRight as long, byref nVert as long )
sub tkNumericUpDown_SetValuePadding( byval hCtrl as TK_WIDGET ptr, byval nLeft as long, byval nRight as long, byval nVert as long )
function tkNumericUpDown_GetCornerRadius( byval hCtrl as TK_WIDGET ptr ) as long
sub tkNumericUpDown_SetCornerRadius( byval hCtrl as TK_WIDGET ptr, byval nRadius as long )
function tkNumericUpDown_GetBorderThickness( byval hCtrl as TK_WIDGET ptr ) as long
sub tkNumericUpDown_SetBorderThickness( byval hCtrl as TK_WIDGET ptr, byval nThickness as long )
function tkNumericUpDown_GetDividerThickness( byval hCtrl as TK_WIDGET ptr ) as long
sub tkNumericUpDown_SetDividerThickness( byval hCtrl as TK_WIDGET ptr, byval nThickness as long )
sub tkNumericUpDown_GetGlyphSize( byval hCtrl as TK_WIDGET ptr, byref nLength as long, byref nThickness as long )
sub tkNumericUpDown_SetGlyphSize( byval hCtrl as TK_WIDGET ptr, byval nLength as long, byval nThickness as long )
sub tkNumericUpDown_GetIdealSize( byval hCtrl as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkNumericUpDown_GetFrameRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkNumericUpDown_GetMinusRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkNumericUpDown_GetValueRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkNumericUpDown_GetPlusRect( byval hCtrl as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkNumericUpDown_HitTest( byval hCtrl as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkNumericUpDown_GetHotPart( byval hCtrl as TK_WIDGET ptr ) as long
function tkNumericUpDown_GetPressedPart( byval hCtrl as TK_WIDGET ptr ) as long
function tkNumericUpDown_IsRepeating( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkNumericUpDown_GetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKNUMERICUPDOWN_COLORS ptr )
sub tkNumericUpDown_SetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKNUMERICUPDOWN_COLORS ptr )
function tkNumericUpDown_ThemeColors( byref t as TKTHEME_COLORS ) as TKNUMERICUPDOWN_COLORS
sub tkNumericUpDown_ApplyTheme( byval hCtrl as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkNumericUpDown_UnpinColors( byval hCtrl as TK_WIDGET ptr )
sub tkNumericUpDown_ApplyFonts( byval hCtrl as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkNumericUpDown_SetPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as NUD_PaintCallbackSub )
sub tkNumericUpDown_SetMessageCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as NUD_MessageCallbackFunc )
sub tkNumericUpDown_SetValueChangedCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as NUD_ValueChangedCallbackSub )
sub tkNumericUpDown_PaintDefault( byval pi as TKNUMERICUPDOWN_PAINTINFO ptr )
sub tkNumericUpDown_SetTooltipText( byval hCtrl as TK_WIDGET ptr, byval Text as ustring )
function tkNumericUpDown_GetTooltipText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkNumericUpDown_GetTooltipHandle( byval hCtrl as TK_WIDGET ptr ) as TK_TIP ptr
sub tkNumericUpDown_SetHoverTime( byval hCtrl as TK_WIDGET ptr, byval ms as long )
sub tkNumericUpDown_SetAutoPopTime( byval hCtrl as TK_WIDGET ptr, byval ms as long )
sub tkNumericUpDown_SetReshowTime( byval hCtrl as TK_WIDGET ptr, byval ms as long )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkTextBox](tkTextBox), the value field
