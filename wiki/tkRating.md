[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkRating**

# tkRating

Draws a rating: a row of stars (or hearts, circles, diamonds or glyphs) filled to a value, which
the user sets with the mouse (a tap on a touch screen) or the keyboard.

`tkRating` is the [tkControls](Category-tkControls) rating. It holds a `double` from 0 to the item
count, 0 meaning unset, and draws it exactly: 3.7 fills three items and 70 % of the fourth. The
Precision (whole, half, tenth) decides only what the user can pick. Around that: a hover preview, a
placeholder value under an unset rating, a caption to the right, one tooltip per item, three size
presets, a per-item paint callback, and `tkRating_PaintInto` for a rating with no widget.

Every setter is silent. `ValueChanged` fires for each change the user makes (a click, a clear, a
key); `HoverChanged` when the previewed value changes. The Form Designer's **Rating** binds its
value, a number, both ways.

## Importing

```freebasic
#import "vendor/tkControls/tkRating"

using tkRating
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` for a paint callback
or `tkRating_PaintInto`.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Mine_Changed( byval hRating as TK_WIDGET ptr, byval nValue as double )
    print "rated " & nValue                        ' a click, a clear or a key
end sub

function Mine_Caption( byval hRating as TK_WIDGET ptr, byval nValue as double, byval nHover as double ) as ustring
    dim as double v = iif( nHover >= 0, nHover, nValue )     ' the preview while there is one
    if v <= 0 then return "Not rated"
    return str( v ) & " of 5"
end function

dim as TK_WIDGET ptr mine = tkRating_Create( tkHost_Root( host ), 100 )
tkRating_SetPrecision( mine, TKRATING_HALF )
tkRating_SetPlaceholderValue( mine, 3.6 )         ' the average, drawn while the value is 0
tkRating_SetFormatCaptionCallback( mine, @Mine_Caption )
tkRating_SetValueChangedCallback( mine, @Mine_Changed )

dim as TK_WIDGET ptr avg = tkRating_Create( tkHost_Root( host ), 101 )
tkRating_SetReadOnly( avg, true )
tkRating_SetSize( avg, TKRATING_SIZE_SMALL )
tkRating_SetValue( avg, 4.27 )                    ' silent; drawn as 4.27 whatever the Precision
tkRating_SetCaption( avg, "(1,234 reviews)" )

dim as long w, h
tkRating_GetIdealSize( mine, w, h )               ' valid before the control is sized
tkWidget_SetPos( mine, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w + tkHost_Scale( host, 60 ), h )
```

`GetIdealSize` measures the caption as it reads now, so the example adds room for longer ones.

## The value

- `SetValue` clamps to `[0, ItemCount]` and rounds to 6 decimals; otherwise it stores what it is
  given. **Precision does not snap a setter**: a FULL rating loaded with 3.5 shows 3.5, and
  `GetValue` answers 3.5 until the user picks.
- **The display is exact.** Item *i* (0-based) is filled to `clamp( Value - i, 0, 1 )` of its
  width.
- `SetItemCount` takes 1 to `TKRATING_MAX_ITEMS` (20); the default is 5. It clamps the value and
  the placeholder again, silently.
- `SetPrecision( TKRATING_FULL | _HALF | _TENTH )` is what a click or a key can set: whole items,
  halves or tenths. Other values are ignored, and the value is not snapped again.
- `SetAllowClear` (default on) lets the user set 0: a click on the current value, **0**, **Delete**,
  **Backspace**, **Home**, or stepping down from the first step. Off, the lowest the user can set
  is one step; a setter can still set 0.
- `SetPlaceholderValue` is drawn in the placeholder colour **while the value is 0**: a community
  average under a control the user has not rated. 0 is none. It is clamped like a value.
- `SetReadOnly( true )` keeps the rating focusable, with its ring, but nothing previews or changes
  the value and it takes no keys. `SetEnabled( false )` greys it and takes it out of the Tab order.
- `GetHoverValue` is the previewed value, or -1; `IsPressed` is TRUE while a press is held.

## Mouse and keyboard

- **Hover** previews the value a click would set, drawn in the hot colours. `SetHoverPreview(
  false )` shows the preview only while pressed. The pointer must be on the row: the items, the
  gaps and the ring band round them (`GetFocusRect`).
- **The value under the pointer.** Each item answers for a zone: itself and half of each gap
  beside it. In item *i* at fraction *f*: FULL gives *i* + 1; HALF *i* + 0.5 up to the middle,
  else *i* + 1; TENTH *i* + ceil( 10 *f* ) / 10. In the half-gap before an item it gives *i* (one
  step before the first item); after it, *i* + 1. `ValueFromPoint` answers the same.
- **A press** takes the focus and the capture; the preview follows the pointer while it is held, so
  the user can drag along the row. **The release** sets the value. A release on the current
  value clears it to 0 when AllowClear is on. A release off the row, **Esc** while pressed, or a
  lost capture cancels. A double click is an ordinary press.
- After a click or a key changes the value, the preview of that same value is held back until the
  pointer moves to another value or leaves, so the new value shows.
- **The wheel** is never taken: it scrolls the form.
- **Keys**: **Right** / **Up** go one Precision step up, **Left** / **Down** one step down. A step
  goes to the next grid value, so a loaded 3.45 goes to 3.5 or 3.0 on a HALF rating. Stepping down
  stops at 0, or at one step without AllowClear (so Left on an unset rating then sets the first
  step).
  **Home** sets 0 (one step without AllowClear), **End** the item count. **1** to **9**, top row or
  keypad, set that whole value if it is not above the item count. **0**, **Delete** and
  **Backspace** clear (AllowClear only).
- A key at a limit is still claimed. Other keys (Space, Enter, Tab) are not, nor is any key with
  Ctrl, Alt or the GUI key held (Alt+1 stays an accelerator). While the rating is
  read-only or pressed it takes no key but **Esc**, and Esc only during a press.
- The right button is reported to the Message callback and never acted on.

## Notifications

| Callback | When |
| --- | --- |
| `SetValueChangedCallback` | each user change: a release on a new value, a clear, a key |
| `SetHoverChangedCallback` | the previewed value changes; -1 when the preview ends |
| `SetFormatCaptionCallback` | the caption's text for the value and the preview (-1 for none); "" keeps the Caption |
| `SetPaintItemCallback` | replaces the drawing of each item; `tkRating_PaintItemDefault( p )` draws one as stock |
| `SetPaintCallback` | replaces the drawing; `tkRating_PaintDefault( p )` draws the stock rating |
| `SetMessageCallback` | the input stream; TRUE claims a press or a key |

The state is updated before a callback runs: inside it, `GetValue` already answers the new value.
When one change fires both, `HoverChanged` comes before `ValueChanged`. A callback may destroy the
rating.

## Shapes, size and caption

- `SetShape( TKRATING_STAR )` (default), `_HEART`, `_CIRCLE`, `_DIAMOND` or `_GLYPH`. Each item
  is drawn empty (in the empty colour, with a border), then filled, clipped to its filled fraction.
  `SetShowEmpty( false )` leaves out the empty items and the empty part of a partial one.
- **GLYPH** draws the characters of `SetGlyphs( filled, empty )` in the glyph font
  (`SetGlyphFont`, or `ApplyFonts`' second font). An empty `empty` draws the filled glyph in the
  empty colour. Without a glyph font or a filled glyph it draws the star.
- `SetSize( TKRATING_SIZE_SMALL | _MEDIUM | _LARGE )` sets the item size to 16, 20 or 28 design
  units, scaled at the call. `SetItemSize( pixels )` sets it directly, and `GetSize` then answers
  `TKRATING_SIZE_CUSTOM`.
- `SetItemSpacing`, `SetCaptionGap` and `SetFocusRing( gap, thickness )` take pixels; the caller
  scales. A scale change rescales the item size, spacing, ring gap and caption gap.
- `SetBorderThickness` is the outline of each item, 0 for none. It follows the theme's
  `BorderWidth` until it is called. Neither it nor the ring thickness is ever scaled.
- `SetCaption` puts text right of the row, after the caption gap (8 design units), cut with an
  ellipsis. A FormatCaption callback's non-empty answer replaces it, and is asked again as the
  value and the preview change. `GetCaptionText` is what it reads now. `SetFont` sets its font (0
  is the surface's default); `ApplyFonts( text, glyph )` sets both fonts, a 0 leaving that one alone.
- **Tooltips**: `SetTooltipText` is the rating's. `SetItemTooltip( h, i, text )` gives item *i*
  its own, shown while the pointer is in that item's zone; "" falls back to the rating's.
  `GetTipItem` is the item the tip is on (-1 for the rating), `GetTipText` its text.
  `SetHoverTime`, `SetAutoPopTime`, `SetReshowTime` as on every control.

## Layout

- The row starts after the ring band (the focus gap, 2 design units, plus the ring's thickness,
  1 pixel) and is centred vertically. The band is kept whether or not the rating has the focus.
- `GetIdealSize` is valid before the control is sized: the items and gaps, plus the ring band both
  ways, plus the caption gap and the caption's width as it reads now. The height is the item size
  plus the band, or the caption font's line height if that is taller.
- `GetItemRect`, `GetItemZone`, `GetRowRect`, `GetFocusRect` (also where the pointer must be to
  preview or set), `GetCaptionRect` (FALSE with no caption or no room), `ValueFromPoint` and
  `HitTest` answer in control-local pixels. They answer FALSE, with an empty rect, while the
  control is not laid out. `HitTest` gives the item index, `TKRATING_HIT_CAPTION` or
  `TKRATING_HIT_NONE`.

## Drawing without a widget

`tkRating_PaintInto( b, rc, value, nItems, pSpec )` draws a rating into any paint context: a grid
cell, a list row, a report. The row starts at `rc`'s left and is centred vertically; everything is
clipped to `rc`. The control draws its own items through the same painter.

`TKRATING_DRAWSPEC` says how: `nShape`, `wszGlyphFilled` / `wszGlyphEmpty` with `fGlyph`,
`nItemSize` (0: `rc`'s height), `nSpacing` (-1: a fifth of the item size), `nBorder`,
`bShowEmpty`, `bEnabled`, `bPreview` (the hot colours), `nPlaceholder` (drawn under a value of 0)
and `pColors` (0: the app theme's). Sizes are pixels. A `pSpec` of 0 uses the defaults.

`tkRating_MeasureSpec( nItems, pSpec, w, h )` gives the row's size; the spec's `nItemSize` must be
above 0.

```freebasic
' in a host paint handler: h is the TK_HOST ptr, b the TK_PAINT ptr, rcCell the cell
dim as TKRATING_DRAWSPEC spec
spec.nItemSize = tkHost_Scale( h, 16 )
tkRating_PaintInto( b, rcCell, 2.6, 5, @spec )
```

## Colours and theme

`TKRATING_COLORS` has the back, the focus ring, the fill and the empty colours with their hot and
disabled states, the border and its disabled state, the placeholder, and the caption with its
disabled state. An item is drawn in one mood, `TKRATING_MOOD_*`: disabled wins over the preview
(the hot colours), the preview over the placeholder, the placeholder over normal.

`tkRating_ThemeColors( t )` maps them from the theme's roles: the fill is `Warning` (amber), the
empty items `Track`, the placeholder and the caption `TextDim`. `SetColors` pins the struct (a
theme change leaves it) until `UnpinColors`.

## In the Form Designer

The toolbox's **Rating** (Common) has the properties above, in the order the form sets them:
ItemCount and Precision first, then Value and PlaceholderValue, which clamp to the item count.
Then AllowClear, ReadOnly, HoverPreview, ShowEmpty, Shape, Glyphs, Size, ItemSpacing, Caption,
CaptionGap, Font, GlyphFont, BorderThickness, FocusRing, TooltipText, HoverTime, AutoPopTime and ReshowTime.
GlyphFont gives a Glyph rating the form's glyph font (as a button's). Its events
are ValueChanged (the default), HoverChanged, FormatCaption (the handler sets `Text`), PaintItem,
Paint and Message.

**Bind** moves the value into and out of a number field of the form's DataType. A setter does not
snap, so a loaded value saves back unchanged. See [Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKRATING_FULL`, `TKRATING_HALF`, `TKRATING_TENTH` · `TKRATING_HIT_NONE`, `TKRATING_HIT_CAPTION` ·
`TKRATING_STAR`, `TKRATING_HEART`, `TKRATING_CIRCLE`, `TKRATING_DIAMOND`, `TKRATING_GLYPH` ·
`TKRATING_SIZE_CUSTOM`, `TKRATING_SIZE_SMALL`, `TKRATING_SIZE_MEDIUM`, `TKRATING_SIZE_LARGE` ·
`TKRATING_MOOD_NORMAL`, `TKRATING_MOOD_PREVIEW`, `TKRATING_MOOD_PLACEHOLDER`,
`TKRATING_MOOD_DISABLED` · `TKRATING_MAX_ITEMS` (20) · `TKRATING_DEFAULT_ITEMS`,
`TKRATING_DEFAULT_ITEMSIZE`, `TKRATING_DEFAULT_SPACING`, `TKRATING_DEFAULT_FOCUSGAP`,
`TKRATING_DEFAULT_CAPTIONGAP` (design units), `TKRATING_DEFAULT_FOCUSTHICK`,
`TKRATING_DEFAULT_BORDER` (pixels, never scaled).

### Types

`TKRATING_COLORS`, `TKRATING_PAINTINFO` (the client, row, ring and caption rects, the caption's
text, the item count, the value, the placeholder, what is drawn and its mood, the state),
`TKRATING_ITEMPAINTINFO` (one item: its index, rect, fill 0..1 and mood), `TKRATING_DRAWSPEC`,
`TKRATING_MESSAGEINFO`, and the callback types `RTG_ValueChangedCallbackSub`,
`RTG_HoverChangedCallbackSub`, `RTG_PaintCallbackSub`, `RTG_PaintItemCallbackSub`,
`RTG_FormatCaptionCallbackFunc`, `RTG_MessageCallbackFunc`. `TKRATING_STATE` is the per-instance
state; reach it through the procedures.

### Procedures

```freebasic
function tkRating_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkRating_GetID( byval hRating as TK_WIDGET ptr ) as long
function tkRating_GetEnabled( byval hRating as TK_WIDGET ptr ) as boolean
sub tkRating_SetEnabled( byval hRating as TK_WIDGET ptr, byval isEnabled as boolean )
function tkRating_GetFocused( byval hRating as TK_WIDGET ptr ) as boolean
sub tkRating_Refresh( byval hRating as TK_WIDGET ptr )
function tkRating_GetValue( byval hRating as TK_WIDGET ptr ) as double
sub tkRating_SetValue( byval hRating as TK_WIDGET ptr, byval nValue as double )
function tkRating_GetItemCount( byval hRating as TK_WIDGET ptr ) as long
sub tkRating_SetItemCount( byval hRating as TK_WIDGET ptr, byval nItems as long )
function tkRating_GetPrecision( byval hRating as TK_WIDGET ptr ) as long
sub tkRating_SetPrecision( byval hRating as TK_WIDGET ptr, byval nPrecision as long )
function tkRating_GetAllowClear( byval hRating as TK_WIDGET ptr ) as boolean
sub tkRating_SetAllowClear( byval hRating as TK_WIDGET ptr, byval bAllow as boolean )
function tkRating_GetReadOnly( byval hRating as TK_WIDGET ptr ) as boolean
sub tkRating_SetReadOnly( byval hRating as TK_WIDGET ptr, byval bReadOnly as boolean )
function tkRating_GetHoverPreview( byval hRating as TK_WIDGET ptr ) as boolean
sub tkRating_SetHoverPreview( byval hRating as TK_WIDGET ptr, byval bOn as boolean )
function tkRating_GetShowEmpty( byval hRating as TK_WIDGET ptr ) as boolean
sub tkRating_SetShowEmpty( byval hRating as TK_WIDGET ptr, byval bOn as boolean )
function tkRating_GetHoverValue( byval hRating as TK_WIDGET ptr ) as double
function tkRating_IsPressed( byval hRating as TK_WIDGET ptr ) as boolean
function tkRating_GetItemSize( byval hRating as TK_WIDGET ptr ) as long
sub tkRating_SetItemSize( byval hRating as TK_WIDGET ptr, byval nSize as long )
function tkRating_GetItemSpacing( byval hRating as TK_WIDGET ptr ) as long
sub tkRating_SetItemSpacing( byval hRating as TK_WIDGET ptr, byval nSpacing as long )
function tkRating_GetBorderThickness( byval hRating as TK_WIDGET ptr ) as long
sub tkRating_SetBorderThickness( byval hRating as TK_WIDGET ptr, byval nThick as long )
sub tkRating_GetFocusRing( byval hRating as TK_WIDGET ptr, byref nGap as long, byref nThickness as long )
sub tkRating_SetFocusRing( byval hRating as TK_WIDGET ptr, byval nGap as long, byval nThickness as long )
sub tkRating_GetIdealSize( byval hRating as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkRating_GetItemRect( byval hRating as TK_WIDGET ptr, byval nItem as long, byref rc as TKRECT ) as boolean
function tkRating_GetItemZone( byval hRating as TK_WIDGET ptr, byval nItem as long, byref rc as TKRECT ) as boolean
function tkRating_GetRowRect( byval hRating as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkRating_GetFocusRect( byval hRating as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkRating_ValueFromPoint( byval hRating as TK_WIDGET ptr, byval x as long ) as double
function tkRating_HitTest( byval hRating as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkRating_GetShape( byval hRating as TK_WIDGET ptr ) as long
sub tkRating_SetShape( byval hRating as TK_WIDGET ptr, byval nShape as long )
sub tkRating_SetGlyphs( byval hRating as TK_WIDGET ptr, byval wszFilled as ustring, byval wszEmpty as ustring )
sub tkRating_GetGlyphs( byval hRating as TK_WIDGET ptr, byref wszFilled as ustring, byref wszEmpty as ustring )
function tkRating_GetSize( byval hRating as TK_WIDGET ptr ) as long
sub tkRating_SetSize( byval hRating as TK_WIDGET ptr, byval nSize as long )
function tkRating_GetPlaceholderValue( byval hRating as TK_WIDGET ptr ) as double
sub tkRating_SetPlaceholderValue( byval hRating as TK_WIDGET ptr, byval nValue as double )
function tkRating_GetCaption( byval hRating as TK_WIDGET ptr ) as ustring
sub tkRating_SetCaption( byval hRating as TK_WIDGET ptr, byval wszCaption as ustring )
function tkRating_GetCaptionText( byval hRating as TK_WIDGET ptr ) as ustring
function tkRating_GetCaptionGap( byval hRating as TK_WIDGET ptr ) as long
sub tkRating_SetCaptionGap( byval hRating as TK_WIDGET ptr, byval nGap as long )
function tkRating_GetCaptionRect( byval hRating as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkRating_GetFont( byval hRating as TK_WIDGET ptr ) as TTF_Font ptr
sub tkRating_SetFont( byval hRating as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkRating_GetGlyphFont( byval hRating as TK_WIDGET ptr ) as TTF_Font ptr
sub tkRating_SetGlyphFont( byval hRating as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkRating_ApplyFonts( byval hRating as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkRating_SetItemTooltip( byval hRating as TK_WIDGET ptr, byval nItem as long, byval Text as ustring )
function tkRating_GetItemTooltip( byval hRating as TK_WIDGET ptr, byval nItem as long ) as ustring
function tkRating_GetTipItem( byval hRating as TK_WIDGET ptr ) as long
function tkRating_GetTipText( byval hRating as TK_WIDGET ptr ) as ustring
sub tkRating_SetTooltipText( byval hRating as TK_WIDGET ptr, byval Text as ustring )
function tkRating_GetTooltipText( byval hRating as TK_WIDGET ptr ) as ustring
function tkRating_GetTooltipHandle( byval hRating as TK_WIDGET ptr ) as TK_TIP ptr
sub tkRating_SetHoverTime( byval hRating as TK_WIDGET ptr, byval ms as long )
sub tkRating_SetAutoPopTime( byval hRating as TK_WIDGET ptr, byval ms as long )
sub tkRating_SetReshowTime( byval hRating as TK_WIDGET ptr, byval ms as long )
sub tkRating_GetColors( byval hRating as TK_WIDGET ptr, byval pColors as TKRATING_COLORS ptr )
sub tkRating_SetColors( byval hRating as TK_WIDGET ptr, byval pColors as TKRATING_COLORS ptr )
function tkRating_ThemeColors( byref t as TKTHEME_COLORS ) as TKRATING_COLORS
sub tkRating_ApplyTheme( byval hRating as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkRating_UnpinColors( byval hRating as TK_WIDGET ptr )
sub tkRating_SetPaintCallback( byval hRating as TK_WIDGET ptr, byval usersub as RTG_PaintCallbackSub )
sub tkRating_SetMessageCallback( byval hRating as TK_WIDGET ptr, byval userfunc as RTG_MessageCallbackFunc )
sub tkRating_SetPaintItemCallback( byval hRating as TK_WIDGET ptr, byval usersub as RTG_PaintItemCallbackSub )
sub tkRating_SetFormatCaptionCallback( byval hRating as TK_WIDGET ptr, byval userfunc as RTG_FormatCaptionCallbackFunc )
sub tkRating_SetValueChangedCallback( byval hRating as TK_WIDGET ptr, byval usersub as RTG_ValueChangedCallbackSub )
sub tkRating_SetHoverChangedCallback( byval hRating as TK_WIDGET ptr, byval usersub as RTG_HoverChangedCallbackSub )
sub tkRating_PaintDefault( byval pi as TKRATING_PAINTINFO ptr )
sub tkRating_PaintItemDefault( byval ii as TKRATING_ITEMPAINTINFO ptr )
sub tkRating_MeasureSpec( byval nItems as long, byval pSpec as TKRATING_DRAWSPEC ptr,
sub tkRating_PaintInto( byval b as TK_PAINT ptr, byref rc as TKRECT, byval nValue as double,
```

### See also

- [tkControls](Category-tkControls)
- [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip)
- [tkBadge](tkBadge), its sibling from the same design
- [Form Designer](Form-Designer), data binding
