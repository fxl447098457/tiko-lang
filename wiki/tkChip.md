[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkChip**

# tkChip

Draws a chip: a compact pill holding a label, with an optional leading avatar, glyph or round image,
a check mark when selected, a count badge and a remove button.

`tkChip` is the [tkControls](Category-tkControls) chip, in three kinds: an action chip that is
clicked, a toggle chip that is selected and deselected (a filter), and an input chip that stands for
an entity (a person, a tag) and can be removed. One layout serves the widget and a widgetless
painter, and [tkChipGroup](tkChipGroup) draws each of its items with that painter.

Every setter is silent. A click on an action or input chip fires `Click`; a click on a toggle chip
flips `Selected` and fires `SelectedChanged`. The remove button, or Delete / Backspace, fires
`RemoveRequested`, and **the host removes the chip**. The Form Designer's **Chip** binds `Selected`
as a boolean.

## Importing

```freebasic
#import "vendor/tkControls/tkChip"

using tkChip
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkImage](tkImage), [tkBadge](tkBadge) and
[tkAvatar](tkAvatar). Add `using tkBadge` for the `TKBADGE_*` status constants, and `using tkPaint`
for a paint callback or `tkChip_PaintInto`.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Filter_Changed( byval hChip as TK_WIDGET ptr, byval isSelected as boolean )
    print tkChip_GetText( hChip ) & iif( isSelected, " on", " off" )
end sub

sub Person_Remove( byval hChip as TK_WIDGET ptr )
    tkWidget_Destroy( hChip )                    ' the host removes the chip
end sub

dim as TK_WIDGET ptr flt = tkChip_Create( tkHost_Root( host ), 100 )
tkChip_SetKind( flt, TKCHIP_TOGGLE )
tkChip_SetText( flt, "Unread" )
tkChip_SetCount( flt, 12 )
tkChip_SetReserveCheck( flt, true )          ' the width stays put as it toggles
tkChip_SetSelected( flt, true )              ' silent: no callback
tkChip_SetSelectedChangedCallback( flt, @Filter_Changed )

dim as TK_WIDGET ptr who = tkChip_Create( tkHost_Root( host ), 101 )
tkChip_SetKind( who, TKCHIP_INPUT )          ' INPUT: removable
tkChip_SetText( who, "Ada Lovelace" )
tkChip_SetLeadingAvatar( who, "" )           ' initials from the label
tkChip_SetRemoveRequestedCallback( who, @Person_Remove )

dim as long w, h
tkChip_GetIdealSize( flt, w, h )             ' valid before the control is sized
tkWidget_SetPos( flt, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
tkChip_GetIdealSize( who, w, h )
tkWidget_SetPos( who, tkHost_Scale( host, 20 ), tkHost_Scale( host, 60 ), w, h )
```

## Kinds

`SetKind` takes one of three; `TKCHIP_ACTION` is the default.

| Kind | A click on the body |
| --- | --- |
| `TKCHIP_ACTION` | fires `Click` |
| `TKCHIP_TOGGLE` | flips `Selected` and fires `SelectedChanged` |
| `TKCHIP_INPUT` | fires `Click`; with `SetSelectable( true )` it flips `Selected` instead, as a toggle does |

- `SetKind( TKCHIP_INPUT )` makes the chip removable. A later `SetRemovable( false )` turns that off;
  a later `SetKind` to another kind leaves it on. `SetRemovable( true )` gives any kind a remove
  button.
- `SetSelected` is silent and draws any kind selected. Only a toggle chip, or a selectable input
  chip, changes it on a click.

## Anatomy

```
[pad][leading][gap][label ...][gap][count][gap][remove][pad]
```

- **Height**: `TKCHIP_SMALL` 24, `TKCHIP_MEDIUM` 32 (the default), in design units (`SetSize`). The
  width follows from the parts. The pad is 12 at an end with nothing beside it and 4 beside a leading
  part, a check or the remove button; the gap is 4.
- **Leading part**, a square the chip's height less 8:
  - `SetLeadingAvatar( h, name, img )` draws a [tkAvatar](tkAvatar): initials from `name` ("" uses
    the label), or `img` as its picture (borrowed). The chip opens its own bold font for the
    initials.
  - `SetLeadingGlyph` draws a glyph. It needs a glyph font from `SetGlyphFont` or `ApplyFonts`;
    without one there is no leading part.
  - `SetLeadingImageFile` and `SetLeadingImagePixels` draw an image the chip owns, clipped round. A
    load that fails leaves no leading part.
  - `ClearLeading` removes it.
- **Check mark**: drawn when the chip is selected and `ShowCheck` is on (the default). It replaces
  the leading part when there is one; otherwise it is inserted before the label and the chip widens.
  `SetReserveCheck( true )` keeps its room while unselected, so a row of chips does not jump.
- **Label**: one line. Beyond `SetMaxLabelWidth` (design units; `TKCHIP_DEFAULT_MAXLABEL`, 200, by
  default; 0 = no limit) it is ellipsised, and the tooltip shows it whole.
- **Count**: `SetCount( n )` with `n > 0` draws a small [tkBadge](tkBadge) count after the label; 0
  removes it.
- **Remove button**: a circle half the height plus 2 across, with an × drawn in two lines and a hot
  background under the pointer. Its hit target is at least `TKCHIP_MIN_TARGET` (24, scaled) across,
  centred on the button and kept inside the chip. A disabled chip hides it.

## Look

- `SetAppearance( TKCHIP_FILLED | TKCHIP_OUTLINED )`. A filled Neutral chip has no border until it
  is selected. An outlined chip has a border and, while unselected, is filled with the back colour.
- `SetShape( TKCHIP_PILL | TKCHIP_ROUNDED )`: round ends, or rounded corners.
- `SetStatus` takes the badge's six: `TKBADGE_NEUTRAL` (the default), `TKBADGE_ACCENT`,
  `TKBADGE_INFO`, `TKBADGE_SUCCESS`, `TKBADGE_WARNING`, `TKBADGE_ERROR`. A chip with a status other
  than Neutral is filled with a 20 % tint of the status colour (30 % when hot or pressed), with the
  status colour as its border and text; selected, it is filled with the status colour itself.
- Disabled, the chip takes the disabled colours, a leading avatar is drawn inactive and a leading
  image at half opacity.

## Mouse and keyboard

- A press focuses the chip; on the body or the remove button it also captures the mouse. The
  release acts only on the part the press began on: a press that slides off is cancelled.
- The chip is a tab stop, with a focus ring round the pill.
- **Space**, **Enter** and keypad **Enter** act as a click on the body. **Delete** and **Backspace**
  fire `RemoveRequested` on a removable chip and are not claimed on another. Held keys do not repeat.
- The wheel, other keys and any key with Ctrl, Alt or the GUI key held are not claimed. A disabled
  chip takes no input.

## Notifications

| Callback | When |
| --- | --- |
| `SetClickCallback` | a click (or Space / Enter) on an action chip, or on an input chip that is not selectable |
| `SetSelectedChangedCallback` | the user flipped `Selected` on a toggle chip or a selectable input chip |
| `SetRemoveRequestedCallback` | the remove button was clicked, or Delete / Backspace pressed; the host removes the chip |
| `SetPaintCallback` | replaces the drawing, focus ring included; `tkChip_PaintDefault( p )` draws the stock chip without the ring |
| `SetMessageCallback` | the input stream, with the part under the pointer (`TKCHIP_HIT_*`); TRUE claims a press, a release (no click) or a key |

The state is updated before a callback runs: inside `SelectedChanged`, `GetSelected` already answers
the new value. Callbacks are fired last, so a callback may destroy the chip; `RemoveRequested` is
where a host usually does.

## Geometry

- `GetIdealSize` is valid before the control is sized: the chip plus the focus ring's band
  (`TKCHIP_FOCUSGAP` scaled, plus `TKCHIP_FOCUSTHICK`) on every side.
- `GetParts( h, pt )` fills a `TKCHIP_PARTS` in control-local pixels: `rcChip`, `rcLeading`,
  `rcCheck`, `rcLabel`, `rcCount`, `rcRemove` (the visible circle), `rcRemoveTarget` (the hit target)
  and `bLabelCut`. A rect the chip does not have is empty. The chip sits at the left after the ring
  band, centred vertically.
- `HitTest( h, x, y )` answers `TKCHIP_HIT_NONE`, `TKCHIP_HIT_BODY` or `TKCHIP_HIT_REMOVE`.
- `GetTipText` answers what the tooltip shows: `SetTooltipText`'s text, else the full label when it
  is cut, else "".

## Painting without a widget

A `TKCHIP_SPEC` holds everything that decides a chip's look and layout: the text, the leading part
(`nLead`, `wszAvatarName`, `wszGlyph`, `pImage`), `bSelected`, `bShowCheck`, `bReserveCheck`,
`bRemovable`, `nCount`, `nStatus`, `nAppearance`, `nShape`, `nSize`, `nMaxLabel`, `bEnabled`, the
live states `bHot`, `bPressed` and `bRemoveHot`, the fonts (`fText`, `fGlyph`, `fAvatar`), `fScale`
and `pColors`.

- `tkChip_LayoutSpec( s, x, y, pt )` lays the chip out with its top-left at (x, y).
- `tkChip_MeasureSpec( s, w, h )` answers its size.
- `tkChip_PaintInto( b, rc, s )` draws it at `rc.left`, centred vertically in `rc` and clipped to
  it. `pColors = 0` uses the app theme's colours.

There is no widget to supply defaults: set `fText` (no font, no label), `fScale`, `fGlyph` for a
glyph and `fAvatar` for an avatar's initials. `nMaxLabel` is in pixels: -1 (the default) is
`TKCHIP_DEFAULT_MAXLABEL` scaled, 0 is no limit. A list or a grid cell can draw chips this way
without a widget for each.

## Colours and theme

`TKCHIP_COLORS` holds the Neutral status's colours: the back and the focus ring; the fill normal,
hot, pressed, selected, selected and hot, and disabled; the border normal, hot, selected and
disabled; the text normal, selected and disabled; the check; the remove button's × normal and hot,
and its hot background. Another status takes its colours from [tkBadge](tkBadge)'s at paint.

`tkChip_ThemeColors( t )` maps the struct from the theme's roles; `ApplyTheme` resolves it under
the style name "Chip". `SetColors` pins the struct (a theme change leaves it) until `UnpinColors`.
[tkChipGroup](tkChipGroup) uses the same struct.

## In the Form Designer

The toolbox's **Chip** (Common) has the properties above, in the order the form sets them: Kind
first, because Input makes the chip removable and a later Removable can turn that off; then Text,
Selected, Removable, Selectable, LeadingGlyph, LeadingImage, AvatarName, ShowCheck, ReserveCheck,
Count, Status, Appearance, Shape, Size, MaxLabelWidth, Font, GlyphFont (the form's glyph font, for
LeadingGlyph) and TooltipText. Each of LeadingGlyph,
LeadingImage and AvatarName sets the leading part, so of those given, the last wins. Its events are
Click (the default), SelectedChanged, RemoveRequested, Paint and Message.

**Bind** moves `Selected` into and out of a field of the form's DataType, as a boolean. See
[Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKCHIP_ACTION`, `TKCHIP_TOGGLE`, `TKCHIP_INPUT` · `TKCHIP_LEAD_NONE`, `TKCHIP_LEAD_AVATAR`,
`TKCHIP_LEAD_GLYPH`, `TKCHIP_LEAD_IMAGE` · `TKCHIP_FILLED`, `TKCHIP_OUTLINED` · `TKCHIP_PILL`,
`TKCHIP_ROUNDED` · `TKCHIP_SMALL`, `TKCHIP_MEDIUM` · `TKCHIP_HIT_NONE`, `TKCHIP_HIT_BODY`,
`TKCHIP_HIT_REMOVE` · `TKCHIP_DEFAULT_MAXLABEL` (200), `TKCHIP_MIN_TARGET` (24),
`TKCHIP_FOCUSGAP`, `TKCHIP_FOCUSTHICK`.

### Types

`TKCHIP_COLORS`, `TKCHIP_SPEC` (a chip's look and layout, with or without a widget),
`TKCHIP_PARTS` (the laid-out rects), `TKCHIP_PAINTINFO` (the chip, the paint target, the client
rect, the parts, the focus), `TKCHIP_MESSAGEINFO`, and the callback types `CHP_ClickCallbackSub`,
`CHP_SelectedChangedCallbackSub`, `CHP_RemoveRequestedCallbackSub`, `CHP_PaintCallbackSub`,
`CHP_MessageCallbackFunc`.

### Procedures

```freebasic
sub tkChip_LayoutSpec( byref s as TKCHIP_SPEC, byval x as long, byval y as long, byref pt as TKCHIP_PARTS )
sub tkChip_MeasureSpec( byref s as TKCHIP_SPEC, byref nWidth as long, byref nHeight as long )
sub tkChip_PaintInto( byval b as TK_PAINT ptr, byref rc as TKRECT, byref s as TKCHIP_SPEC )
function tkChip_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkChip_GetID( byval hChip as TK_WIDGET ptr ) as long
sub tkChip_SetEnabled( byval hChip as TK_WIDGET ptr, byval isEnabled as boolean )
function tkChip_GetFocused( byval hChip as TK_WIDGET ptr ) as boolean
function tkChip_GetText( byval hChip as TK_WIDGET ptr ) as ustring
sub tkChip_SetText( byval hChip as TK_WIDGET ptr, byval Text as ustring )
function tkChip_GetKind( byval hChip as TK_WIDGET ptr ) as long
sub tkChip_SetKind( byval hChip as TK_WIDGET ptr, byval nKind as long )
function tkChip_GetSelected( byval hChip as TK_WIDGET ptr ) as boolean
sub tkChip_SetSelected( byval hChip as TK_WIDGET ptr, byval bOn as boolean )
sub tkChip_SetSelectable( byval hChip as TK_WIDGET ptr, byval bOn as boolean )
function tkChip_GetRemovable( byval hChip as TK_WIDGET ptr ) as boolean
sub tkChip_SetRemovable( byval hChip as TK_WIDGET ptr, byval bOn as boolean )
sub tkChip_SetLeadingAvatar( byval hChip as TK_WIDGET ptr, byval Name_ as ustring, byval pImage as tkImageFile ptr = 0 )
sub tkChip_SetLeadingGlyph( byval hChip as TK_WIDGET ptr, byval Glyph as ustring )
sub tkChip_SetLeadingImageFile( byval hChip as TK_WIDGET ptr, byval Path as ustring )
sub tkChip_SetLeadingImagePixels( byval hChip as TK_WIDGET ptr, byval w as long, byval h as long, byval argb as ulong ptr )
sub tkChip_ClearLeading( byval hChip as TK_WIDGET ptr )
sub tkChip_SetShowCheck( byval hChip as TK_WIDGET ptr, byval bOn as boolean )
sub tkChip_SetReserveCheck( byval hChip as TK_WIDGET ptr, byval bOn as boolean )
sub tkChip_SetCount( byval hChip as TK_WIDGET ptr, byval nCount as long )
sub tkChip_SetStatus( byval hChip as TK_WIDGET ptr, byval nStatus as long )
sub tkChip_SetAppearance( byval hChip as TK_WIDGET ptr, byval nAppearance as long )
sub tkChip_SetShape( byval hChip as TK_WIDGET ptr, byval nShape as long )
sub tkChip_SetSize( byval hChip as TK_WIDGET ptr, byval nSize as long )
sub tkChip_SetMaxLabelWidth( byval hChip as TK_WIDGET ptr, byval nDu as long )
sub tkChip_SetFont( byval hChip as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkChip_SetGlyphFont( byval hChip as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkChip_ApplyFonts( byval hChip as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkChip_GetIdealSize( byval hChip as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
sub tkChip_GetParts( byval hChip as TK_WIDGET ptr, byref pt as TKCHIP_PARTS )
function tkChip_HitTest( byval hChip as TK_WIDGET ptr, byval x as long, byval y as long ) as long
sub tkChip_SetTooltipText( byval hChip as TK_WIDGET ptr, byval Text as ustring )
function tkChip_GetTipText( byval hChip as TK_WIDGET ptr ) as ustring
sub tkChip_GetColors( byval hChip as TK_WIDGET ptr, byval pColors as TKCHIP_COLORS ptr )
sub tkChip_SetColors( byval hChip as TK_WIDGET ptr, byval pColors as TKCHIP_COLORS ptr )
function tkChip_ThemeColors( byref t as TKTHEME_COLORS ) as TKCHIP_COLORS
sub tkChip_ApplyTheme( byval hChip as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkChip_UnpinColors( byval hChip as TK_WIDGET ptr )
sub tkChip_PaintDefault( byval pi as TKCHIP_PAINTINFO ptr )
sub tkChip_SetClickCallback( byval hChip as TK_WIDGET ptr, byval usersub as CHP_ClickCallbackSub )
sub tkChip_SetSelectedChangedCallback( byval hChip as TK_WIDGET ptr, byval usersub as CHP_SelectedChangedCallbackSub )
sub tkChip_SetRemoveRequestedCallback( byval hChip as TK_WIDGET ptr, byval usersub as CHP_RemoveRequestedCallbackSub )
sub tkChip_SetPaintCallback( byval hChip as TK_WIDGET ptr, byval usersub as CHP_PaintCallbackSub )
sub tkChip_SetMessageCallback( byval hChip as TK_WIDGET ptr, byval userfunc as CHP_MessageCallbackFunc )
```

### See also

- [tkControls](Category-tkControls)
- [tkChipGroup](tkChipGroup), many chips as items of one widget
- [tkBadge](tkBadge), [tkAvatar](tkAvatar), the count and the leading avatar
- [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkImage](tkImage)
- [Form Designer](Form-Designer), data binding
