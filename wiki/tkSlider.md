[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkSlider**

# tkSlider

Draws a slider: a value picked by dragging a thumb along a track; or, in range mode, a lower and an
upper value with a thumb each.

`tkSlider` is the [tkControls](Category-tkControls) slider and range slider: horizontal or vertical,
optionally reversed, with tick marks, tick labels, a value tip over the thumb while it moves, a fill
from the Min end (or from an origin value, or between the two thumbs), and a round or rectangular
thumb. The value is a `double` on a Step grid (or continuous), like [tkNumericUpDown](tkNumericUpDown)'s,
so the two can show one field.

Every setter is silent. `ValueChanged` fires for every change the user makes, each move of a drag
included; `ValueCommitted` when the user is done (the drag released on a new value, or each key, wheel
or page step). The Form Designer's **Slider** binds its value, and in range mode its upper value too.

## Importing

```freebasic
#import "vendor/tkControls/tkSlider"

using tkSlider
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` for a paint callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Volume_Changed( byval hSlider as TK_WIDGET ptr, byval nThumb as long, byval nValue as double )
    print "volume " & nValue            ' every step of a drag
end sub

sub Price_Committed( byval hSlider as TK_WIDGET ptr, byval nThumb as long, byval nValue as double )
    print iif( nThumb = 0, "from ", "to " ) & nValue      ' once the user lets go
end sub

dim as TK_WIDGET ptr vol = tkSlider_Create( tkHost_Root( host ), 100 )
tkSlider_SetRange( vol, 0, 100 )
tkSlider_SetTickFrequency( vol, 10 )
tkSlider_SetTickPlacement( vol, TKSL_TICKS_BOTTOMRIGHT )
tkSlider_SetShowTickLabels( vol, true )
tkSlider_SetLabelEvery( vol, 2 )
tkSlider_SetValue( vol, 40 )                 ' silent: no callback
tkSlider_SetValueChangedCallback( vol, @Volume_Changed )

dim as TK_WIDGET ptr price = tkSlider_Create( tkHost_Root( host ), 101 )
tkSlider_SetMode( price, TKSL_MODE_RANGE )
tkSlider_SetRange( price, 0, 500 )
tkSlider_SetStep( price, 5 )
tkSlider_SetMinDistance( price, 10 )
tkSlider_SetAllowRangeDrag( price, true )
tkSlider_SetValues( price, 120, 340 )
tkSlider_SetValueCommittedCallback( price, @Price_Committed )

dim as long w, h
tkSlider_GetIdealSize( vol, w, h )           ' valid before the control is sized
tkWidget_SetPos( vol, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), tkHost_Scale( host, 300 ), h )
```

## Value, range and stepping

- `SetRange( min, max )` (an inverted pair is swapped), `SetValue`, `SetStep`. `Step > 0` is a grid
  anchored at Min; `Step = 0` is continuous. **Max is always reachable**, even when it is off the
  grid (0..10 step 3 has 0, 3, 6, 9 and 10).
- Every value, from a setter or from the user, is **snapped** to the nearest legal value and
  **clamped**; then rounded to `DecimalPlaces + 6` digits, so `0.1` steps never show binary residue.
  `SetDecimalPlaces` (0..9) is the default text's digits, not a grid.
- `SetSmallChange` (the arrows, one wheel notch; 0 means Step) and `SetLargeChange` (Page Up / Page
  Down and a page click). A step rounds toward where it started and, if that is no move, goes to the
  next legal value, so a SmallChange smaller than Step still moves.
- `SetSnapToTicks( true )` makes the tick values the legal values instead of the grid.
- `tkSlider_StepBy( h, nSteps, nThumb )` steps as the arrow keys do, silently.

## Range mode

`SetMode( TKSL_MODE_RANGE )` gives the slider a second thumb. Thumb 0 holds `Value` (the lower),
thumb 1 `UpperValue` (default Max), and `Value <= UpperValue` always.

- **The user's thumb stops** at the other one, and `SetMinDistance` short of it. It never passes
  or swaps, so thumb 0 is always the lower.
- **Setters push**: `SetValue` above the upper value pushes it up; `SetUpperValue` below the lower
  pushes it down. Setting lower then upper is therefore right from any old pair, which is what a
  designed form's `LoadFrom` does. `SetValues( lo, hi )` sets both.
- **Two thumbs on one spot**: the first drag's direction picks the one that can go that way.
- A press on the track moves the **nearer** thumb. With `SetAllowRangeDrag( true )`, a press
  between the thumbs drags both, the distance kept.
- The **active thumb** (`GetActiveThumb` / `SetActiveThumb`) takes the keys and the wheel, is drawn
  on top and carries the focus ring. **Tab** goes from thumb 0 to thumb 1 and **Shift+Tab** back;
  from the ends they move the focus on. Keyboard focus always arrives on thumb 0.
- Range mode fills between the thumbs; `FillMode` is single-mode only.

## Mouse and keyboard

- A press on a thumb drags it from where it was grabbed (the thumb's hit target is at least 24
  pixels across, scaled). **Esc** during a drag puts the values back.
- A press elsewhere on the track: `TKSL_CLICK_JUMP` (default) brings the thumb there and the drag
  goes on; `TKSL_CLICK_PAGE` moves it by LargeChange toward the press and repeats while held
  (`SetAutoRepeat`, 400 ms then every 80 ms) until it reaches the pointer.
- **Keys**: along the track they follow the drawing (Right on a reversed horizontal slider
  decreases; Up on a vertical one increases unless reversed); the other two arrows follow the
  value. Page Up / Page Down, Home (Min), End (Max). Held keys repeat.
- **The wheel**: `TKSL_WHEEL_FOCUSED` (default) moves the slider only while it has the focus and
  otherwise lets the wheel scroll the form; `TKSL_WHEEL_HOVER` and `TKSL_WHEEL_NEVER`.
- `SetReadOnly` keeps the slider focusable but changes nothing; `SetEnabled( false )` greys it.

## Notifications

| Callback | When |
| --- | --- |
| `SetValueChangedCallback` | every user change, including each move of a live drag; `nThumb` says which thumb |
| `SetValueCommittedCallback` | the user is done: a drag released on a new value, each key, wheel or page step |
| `SetFormatValueCallback` | the text of a tick label (`TKSL_FMT_TICK`) or the value tip (`TKSL_FMT_TIP`); "" keeps the default |
| `SetPaintCallback` | replaces the drawing; `tkSlider_PaintDefault( p )` draws the stock slider |
| `SetMessageCallback` | the input stream; TRUE claims a message |

The state is updated before a callback runs: inside it, `GetValue` already answers the new value. A
range drag reports thumb 0 then thumb 1. A callback may destroy the slider.

## Ticks, labels and the value tip

- `SetTickFrequency( f )` puts ticks at Min + k·f, plus Max; `SetTicks( values() )` puts them at
  exactly these values. `SetTickPlacement( TKSL_TICKS_NONE | _TOPLEFT | _BOTTOMRIGHT | _BOTH )`.
  Ticks closer than 2 pixels (scaled) are thinned; the first and last always show.
- `SetShowTickLabels( true )` labels the ticks on their side, `SetLabelEvery( n )` every n-th (the
  last always). Labels are centred on their tick, kept inside the control and thinned so they never
  overlap. `SetFont` sets their font.
- `SetShowValueTip( TKSL_TIP_DRAG )` (default) shows the value above the thumb while it is dragged
  or paged; `TKSL_TIP_FOCUSED` while the slider has the focus; `TKSL_TIP_NONE`.

## Layout

- `SetOrientation( TKSL_VERTICAL )` puts Min at the bottom; `SetReversed( true )` mirrors either
  orientation.
- `SetThumbSize( along, across )` is measured along and across the track, so one setting reads the
  same in both orientations. `SetThumbShape( TKSL_THUMB_RECT )` makes it a rounded rectangle.
  `SetTrackSize`, `SetTickSize( length, gap, labelGap )`, `SetFocusRing( gap, thickness )`.
- `GetIdealSize` is valid before the control is sized: the thumb plus 120 (scaled) along, the thumb
  band with its ticks and labels across.
- `GetTrackRect`, `GetFillRect`, `GetThumbRect( h, n, rc )`, `GetTickPos`, `GetLabelRect`,
  `ValueToPos`, `PosToValue` and `HitTest` answer in control-local pixels (along the track: x when
  horizontal, y when vertical).

## Colours and theme

`TKSLIDER_COLORS` has the back, the focus ring, and track, fill, thumb, thumb border, tick and label
colours with their hot, pressed and disabled states. `tkSlider_ThemeColors( t )` maps them from the
theme's roles. `SetColors` pins the struct (a theme change leaves it) until `UnpinColors`. The thumb's
border follows the theme's `BorderWidth` until `SetBorderThickness` is called.

## In the Form Designer

The toolbox's **Slider** has the properties above, in the order the form sets them: Range, Step,
DecimalPlaces, the ticks and Mode first, then Value and UpperValue, so a value outside the default
0..100 is not clamped before its range arrives. Its events are ValueChanged, ValueCommitted,
FormatValue (the handler sets `Text`), Paint and Message.

**Bind** moves the value into and out of a field of the form's DataType; with **Mode** = Range,
**BindUpper** moves the upper value. See [Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKSL_MODE_SINGLE`, `TKSL_MODE_RANGE` · `TKSL_HORIZONTAL`, `TKSL_VERTICAL` ·
`TKSL_CLICK_JUMP`, `TKSL_CLICK_PAGE` · `TKSL_WHEEL_FOCUSED`, `TKSL_WHEEL_HOVER`, `TKSL_WHEEL_NEVER` ·
`TKSL_FILL_MIN`, `TKSL_FILL_NONE`, `TKSL_FILL_ORIGIN` · `TKSL_TICKS_NONE`, `TKSL_TICKS_TOPLEFT`,
`TKSL_TICKS_BOTTOMRIGHT`, `TKSL_TICKS_BOTH` · `TKSL_THUMB_ROUND`, `TKSL_THUMB_RECT` ·
`TKSL_TIP_NONE`, `TKSL_TIP_DRAG`, `TKSL_TIP_FOCUSED` · `TKSL_FMT_TICK`, `TKSL_FMT_TIP` ·
`TKSL_PART_NONE`, `TKSL_PART_TRACK`, `TKSL_PART_THUMB0`, `TKSL_PART_TICKS`, `TKSL_PART_THUMB1`,
`TKSL_PART_RANGE` · `TKSL_THUMB_BOTH` (a range drag's pressed thumb).

### Types

`TKSLIDER_COLORS`, `TKSLIDER_PAINTINFO` (the rects of track, fill, thumbs and focus ring, the hot,
pressed and active thumb, the state, the values), `TKSLIDER_MESSAGEINFO`, and the callback types
`SLD_ValueChangedCallbackSub`, `SLD_ValueCommittedCallbackSub`, `SLD_FormatValueCallbackFunc`,
`SLD_PaintCallbackSub`, `SLD_MessageCallbackFunc`.

### Procedures

```freebasic
function tkSlider_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkSlider_GetID( byval hSlider as TK_WIDGET ptr ) as long
function tkSlider_GetEnabled( byval hSlider as TK_WIDGET ptr ) as boolean
sub tkSlider_SetEnabled( byval hSlider as TK_WIDGET ptr, byval isEnabled as boolean )
function tkSlider_GetFocused( byval hSlider as TK_WIDGET ptr ) as boolean
sub tkSlider_Refresh( byval hSlider as TK_WIDGET ptr )
function tkSlider_GetValue( byval hSlider as TK_WIDGET ptr ) as double
sub tkSlider_SetValue( byval hSlider as TK_WIDGET ptr, byval nValue as double )
function tkSlider_GetUpperValue( byval hSlider as TK_WIDGET ptr ) as double
sub tkSlider_SetUpperValue( byval hSlider as TK_WIDGET ptr, byval nValue as double )
sub tkSlider_SetValues( byval hSlider as TK_WIDGET ptr, byval nLower as double, byval nUpper as double )
function tkSlider_GetMode( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetMode( byval hSlider as TK_WIDGET ptr, byval nMode as long )
function tkSlider_GetMinDistance( byval hSlider as TK_WIDGET ptr ) as double
sub tkSlider_SetMinDistance( byval hSlider as TK_WIDGET ptr, byval n as double )
function tkSlider_GetAllowRangeDrag( byval hSlider as TK_WIDGET ptr ) as boolean
sub tkSlider_SetAllowRangeDrag( byval hSlider as TK_WIDGET ptr, byval bAllow as boolean )
function tkSlider_GetActiveThumb( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetActiveThumb( byval hSlider as TK_WIDGET ptr, byval nThumb as long )
sub tkSlider_GetRange( byval hSlider as TK_WIDGET ptr, byref nMin as double, byref nMax as double )
sub tkSlider_SetRange( byval hSlider as TK_WIDGET ptr, byval nMin as double, byval nMax as double )
function tkSlider_GetStep( byval hSlider as TK_WIDGET ptr ) as double
sub tkSlider_SetStep( byval hSlider as TK_WIDGET ptr, byval nStep as double )
function tkSlider_GetSmallChange( byval hSlider as TK_WIDGET ptr ) as double
sub tkSlider_SetSmallChange( byval hSlider as TK_WIDGET ptr, byval n as double )
function tkSlider_GetLargeChange( byval hSlider as TK_WIDGET ptr ) as double
sub tkSlider_SetLargeChange( byval hSlider as TK_WIDGET ptr, byval n as double )
function tkSlider_GetDecimalPlaces( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetDecimalPlaces( byval hSlider as TK_WIDGET ptr, byval nPlaces as long )
sub tkSlider_StepBy( byval hSlider as TK_WIDGET ptr, byval nSteps as long, byval nThumb as long = 0 )
function tkSlider_FormatValue( byval hSlider as TK_WIDGET ptr, byval nValue as double,
function tkSlider_GetOrientation( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetOrientation( byval hSlider as TK_WIDGET ptr, byval nOrientation as long )
function tkSlider_GetReversed( byval hSlider as TK_WIDGET ptr ) as boolean
sub tkSlider_SetReversed( byval hSlider as TK_WIDGET ptr, byval bReversed as boolean )
function tkSlider_GetTrackClick( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetTrackClick( byval hSlider as TK_WIDGET ptr, byval nMode as long )
function tkSlider_GetFillMode( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetFillMode( byval hSlider as TK_WIDGET ptr, byval nMode as long )
function tkSlider_GetFillOrigin( byval hSlider as TK_WIDGET ptr ) as double
sub tkSlider_SetFillOrigin( byval hSlider as TK_WIDGET ptr, byval nOrigin as double )
function tkSlider_GetThumbShape( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetThumbShape( byval hSlider as TK_WIDGET ptr, byval nShape as long )
function tkSlider_GetShowValueTip( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetShowValueTip( byval hSlider as TK_WIDGET ptr, byval nMode as long )
function tkSlider_GetValueTipHandle( byval hSlider as TK_WIDGET ptr ) as TK_TIP ptr
function tkSlider_IsValueTipShown( byval hSlider as TK_WIDGET ptr ) as boolean
function tkSlider_GetReadOnly( byval hSlider as TK_WIDGET ptr ) as boolean
sub tkSlider_SetReadOnly( byval hSlider as TK_WIDGET ptr, byval bReadOnly as boolean )
function tkSlider_GetWheelMode( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetWheelMode( byval hSlider as TK_WIDGET ptr, byval nMode as long )
sub tkSlider_GetAutoRepeat( byval hSlider as TK_WIDGET ptr, byref nDelayMs as long, byref nIntervalMs as long )
sub tkSlider_SetAutoRepeat( byval hSlider as TK_WIDGET ptr, byval nDelayMs as long, byval nIntervalMs as long )
function tkSlider_GetTrackSize( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetTrackSize( byval hSlider as TK_WIDGET ptr, byval nThickness as long )
sub tkSlider_GetThumbSize( byval hSlider as TK_WIDGET ptr, byref nAlong as long, byref nAcross as long )
sub tkSlider_SetThumbSize( byval hSlider as TK_WIDGET ptr, byval nAlong as long, byval nAcross as long )
sub tkSlider_GetTickSize( byval hSlider as TK_WIDGET ptr, byref nLength as long, byref nGap as long, byref nLabelGap as long )
sub tkSlider_SetTickSize( byval hSlider as TK_WIDGET ptr, byval nLength as long, byval nGap as long, byval nLabelGap as long )
function tkSlider_GetBorderThickness( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetBorderThickness( byval hSlider as TK_WIDGET ptr, byval nThickness as long )
sub tkSlider_GetFocusRing( byval hSlider as TK_WIDGET ptr, byref nGap as long, byref nThickness as long )
sub tkSlider_SetFocusRing( byval hSlider as TK_WIDGET ptr, byval nGap as long, byval nThickness as long )
sub tkSlider_GetIdealSize( byval hSlider as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkSlider_GetTrackRect( byval hSlider as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkSlider_GetFillRect( byval hSlider as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkSlider_GetThumbRect( byval hSlider as TK_WIDGET ptr, byval nThumb as long, byref rc as TKRECT ) as boolean
function tkSlider_GetThumbTarget( byval hSlider as TK_WIDGET ptr, byval nThumb as long, byref rc as TKRECT ) as boolean
function tkSlider_ValueToPos( byval hSlider as TK_WIDGET ptr, byval nValue as double ) as long
function tkSlider_PosToValue( byval hSlider as TK_WIDGET ptr, byval nPos as long ) as double
function tkSlider_HitTest( byval hSlider as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkSlider_GetHotThumb( byval hSlider as TK_WIDGET ptr ) as long
function tkSlider_GetPressedThumb( byval hSlider as TK_WIDGET ptr ) as long
function tkSlider_IsDragging( byval hSlider as TK_WIDGET ptr ) as boolean
function tkSlider_IsRepeating( byval hSlider as TK_WIDGET ptr ) as boolean
sub tkSlider_SetTooltipText( byval hSlider as TK_WIDGET ptr, byval Text as ustring )
function tkSlider_GetTooltipText( byval hSlider as TK_WIDGET ptr ) as ustring
function tkSlider_GetTooltipHandle( byval hSlider as TK_WIDGET ptr ) as TK_TIP ptr
sub tkSlider_SetHoverTime( byval hSlider as TK_WIDGET ptr, byval ms as long )
sub tkSlider_SetAutoPopTime( byval hSlider as TK_WIDGET ptr, byval ms as long )
sub tkSlider_SetReshowTime( byval hSlider as TK_WIDGET ptr, byval ms as long )
sub tkSlider_GetColors( byval hSlider as TK_WIDGET ptr, byval pColors as TKSLIDER_COLORS ptr )
sub tkSlider_SetColors( byval hSlider as TK_WIDGET ptr, byval pColors as TKSLIDER_COLORS ptr )
function tkSlider_ThemeColors( byref t as TKTHEME_COLORS ) as TKSLIDER_COLORS
sub tkSlider_ApplyTheme( byval hSlider as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkSlider_UnpinColors( byval hSlider as TK_WIDGET ptr )
sub tkSlider_PaintDefault( byval pi as TKSLIDER_PAINTINFO ptr )
sub tkSlider_SetPaintCallback( byval hSlider as TK_WIDGET ptr, byval usersub as SLD_PaintCallbackSub )
sub tkSlider_SetMessageCallback( byval hSlider as TK_WIDGET ptr, byval userfunc as SLD_MessageCallbackFunc )
sub tkSlider_SetValueChangedCallback( byval hSlider as TK_WIDGET ptr, byval usersub as SLD_ValueChangedCallbackSub )
sub tkSlider_SetValueCommittedCallback( byval hSlider as TK_WIDGET ptr, byval usersub as SLD_ValueCommittedCallbackSub )
sub tkSlider_SetFormatValueCallback( byval hSlider as TK_WIDGET ptr, byval userfunc as SLD_FormatValueCallbackFunc )
function tkSlider_GetTickFrequency( byval hSlider as TK_WIDGET ptr ) as double
sub tkSlider_SetTickFrequency( byval hSlider as TK_WIDGET ptr, byval f as double )
sub tkSlider_SetTicks( byval hSlider as TK_WIDGET ptr, values() as double )
function tkSlider_GetTickPlacement( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetTickPlacement( byval hSlider as TK_WIDGET ptr, byval nPlacement as long )
function tkSlider_GetSnapToTicks( byval hSlider as TK_WIDGET ptr ) as boolean
sub tkSlider_SetSnapToTicks( byval hSlider as TK_WIDGET ptr, byval bSnap as boolean )
function tkSlider_GetShowTickLabels( byval hSlider as TK_WIDGET ptr ) as boolean
sub tkSlider_SetShowTickLabels( byval hSlider as TK_WIDGET ptr, byval bShow as boolean )
function tkSlider_GetLabelEvery( byval hSlider as TK_WIDGET ptr ) as long
sub tkSlider_SetLabelEvery( byval hSlider as TK_WIDGET ptr, byval n as long )
function tkSlider_GetTickCount( byval hSlider as TK_WIDGET ptr ) as long
function tkSlider_GetTickValue( byval hSlider as TK_WIDGET ptr, byval i as long ) as double
function tkSlider_GetTickPos( byval hSlider as TK_WIDGET ptr, byval i as long ) as long
function tkSlider_GetTickShown( byval hSlider as TK_WIDGET ptr, byval i as long ) as boolean
function tkSlider_GetLabelRect( byval hSlider as TK_WIDGET ptr, byval i as long, byref rc as TKRECT ) as boolean
function tkSlider_GetLabelText( byval hSlider as TK_WIDGET ptr, byval i as long ) as ustring
function tkSlider_GetFont( byval hSlider as TK_WIDGET ptr ) as TTF_Font ptr
sub tkSlider_SetFont( byval hSlider as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkSlider_ApplyFonts( byval hSlider as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
```

### See also

- [tkControls](Category-tkControls)
- [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip)
- [tkNumericUpDown](tkNumericUpDown), the same value model typed in
- [Form Designer](Form-Designer), data binding
