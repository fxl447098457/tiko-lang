[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkBadge**

# tkBadge

Draws a badge: a dot, a count ("99+"), a short text, a glyph or a presence mark, in a semantic
colour.

`tkBadge` is the [tkControls](Category-tkControls) badge, used three ways. **Standalone**, it is an
ordinary widget, optionally with a label to its right ("● Active"). **Attached** to another
control, it hangs on that control's corner as an adornment: it overhangs it, follows it, and a
click on it reaches the control. **Without a widget**, `tkBadge_PaintInto` draws the same badge in
any paint context: a tab, a list row, a grid cell.

Every setter is silent, and a badge has no user input that changes data, so there is no change
callback. A standalone badge reports the mouse to its Message callback. The Form Designer's
**Badge** binds its count, load only.

## Importing

```freebasic
#import "vendor/tkControls/tkBadge"

using tkBadge
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` for a paint callback
or `tkBadge_PaintInto`.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example. The
example also imports `vendor/tkControls/tkButton` for the button the badge hangs on.

```freebasic
dim as TK_WIDGET ptr inbox = tkButton_Create( tkHost_Root( host ), 100 )
tkButton_SetText( inbox, "Inbox" )
tkWidget_SetPos( inbox, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), tkHost_Scale( host, 110 ), tkHost_Scale( host, 32 ) )

dim as TK_WIDGET ptr unread = tkBadge_Create( tkHost_Root( host ), 200 )
tkBadge_Attach( unread, inbox )                ' top right, a 2-pixel ring, follows the button
tkBadge_SetCount( unread, 120 )                ' reads "99+"
tkBadge_SetStatus( unread, TKBADGE_ERROR )

dim as TK_WIDGET ptr active = tkBadge_Create( tkHost_Root( host ), 201 )
tkBadge_SetStatus( active, TKBADGE_SUCCESS )   ' a dot: the default kind
tkBadge_SetLabel( active, "Active" )

dim as long w, h
tkBadge_GetIdealSize( active, w, h )           ' valid before the control is sized
tkWidget_SetPos( active, tkHost_Scale( host, 20 ), tkHost_Scale( host, 70 ), w, h )
```

## Content

A badge shows one **kind** of content at a time. Each content setter switches the kind:

| Kind | Set by | Shows |
| --- | --- | --- |
| `TKBADGE_KIND_DOT` (default) | `SetDot` | a dot |
| `TKBADGE_KIND_COUNT` | `SetCount` | the count, as `tkBadge_FormatCount` reads it |
| `TKBADGE_KIND_TEXT` | `SetText` | a short text, one line; nothing when it is empty |
| `TKBADGE_KIND_GLYPH` | `SetGlyph` | a character of the glyph font (`SetGlyphFont`, or `ApplyFonts`' second font); a dot without that font |
| `TKBADGE_KIND_PRESENCE` | `SetPresence` | a presence mark (below) |

- `SetKind` switches the kind and leaves every content as it is; `GetKind` reads it.
- **Counts**: a negative count is stored as 0. 0 shows nothing unless `SetShowZero( true )`. Above
  `MaxCount` (99 by default) the badge reads "99+". `SetMaxCount( 0 )` removes the cap.
  `tkBadge_FormatCount( n, max, showZero )` gives the text: "", "0", "7" or "99+".
- `SetInvisible( true )` hides the paint and keeps the widget, so a standalone badge keeps its
  space. `tkWidget_Show` hides the widget itself.
- `tkBadge_IsShowing` answers whether anything is drawn: the kind, its content, ShowZero and
  Invisible together.

## Look

- `SetStatus` picks the colour: `TKBADGE_ACCENT` (default), `_INFO`, `_SUCCESS`, `_WARNING`,
  `_ERROR`, `_NEUTRAL`, from the theme's Accent, Accent, Success, Warning, Error and TextDim.
- `SetAppearance`: `TKBADGE_FILLED` (default: the status fill, a contrasting ink),
  `TKBADGE_OUTLINE` (a status border and status ink on the background), `TKBADGE_TINT`
  (the status at 20 % over the background, status ink).
- `SetShape`: `TKBADGE_PILL` (default: round ends, so one character gives a circle),
  `TKBADGE_ROUNDED`, `TKBADGE_SQUARE`.
- `SetSize`: `TKBADGE_SMALL`, `_MEDIUM` (default), `_LARGE`. The height is 16, 20 or 24 design
  units, a dot 6, 8 or 10, a presence mark 10, 12 or 14. A pill is as wide as its text plus 5
  design units each side, and never narrower than it is high. Sizes follow the host's scale.
- **The size does not change the font.** The text uses `SetFont`'s font, else the surface's
  default.
- `SetRing( pixels )` draws a ring of `RingColor` round the badge: the badge's shape, grown by the
  ring. It is the cut-out look where a badge overlaps its target, and it is never scaled. It is 0
  standalone; `Attach` makes it 2 (`TKBADGE_ATTACHED_RING`) unless `SetRing` ran, and `Detach`
  makes it 0 again. With a ring, OUTLINE and TINT are drawn on `RingColor` instead of `BackColor`.
- `SetCustomColors( fill, ink )` uses that pair instead of the status colours; `SetStatus` goes
  back to the status.
- `SetEnabled( false )` draws the badge in `FillDisabled` / `InkDisabled`, over custom colours too,
  and the label in its disabled colour.

## Presence

`SetPresence( TKBADGE_PRESENCE_* )` draws a round mark in colour **and** shape, so it reads without
colour vision:

| Presence | Mark |
| --- | --- |
| `TKBADGE_PRESENCE_AVAILABLE` | a Success disc with a check |
| `TKBADGE_PRESENCE_AWAY` | a Warning disc with clock hands |
| `TKBADGE_PRESENCE_BUSY` | an Error disc |
| `TKBADGE_PRESENCE_DND` | an Error disc with a bar |
| `TKBADGE_PRESENCE_OFFLINE` | a Neutral ring |
| `TKBADGE_PRESENCE_OOO` | an Accent ring with an arrow |
| `TKBADGE_PRESENCE_BLOCKED` | an Error ring with a slash |
| `TKBADGE_PRESENCE_UNKNOWN` | a Neutral ring with "?" |

The marks are drawn lines; only UNKNOWN's "?" needs a text font. A value out of range is ignored.

## Standalone

`tkBadge_Create( hParent, id )` makes a child of `hParent`, created 0 × 0; size it from
`GetIdealSize` and place it with `tkWidget_SetPos`. It is never focusable. It fills its client with
`BackColor`, which should be what its parent paints.

- `SetLabel` puts text right of the badge, after a gap of 6 design units, in `LabelColor`, cut with
  an ellipsis.
- `SetJustify( TKBADGE_JUSTIFY_LEFT | _CENTER | _RIGHT )` places the badge and its label in the
  client; both are centred vertically.
- `SetTooltipText` gives it a tooltip; `GetTooltipHandle` is the tip.
- Mouse moves, leave, and the left and right buttons go to the Message callback.

## Attached

`tkBadge_Attach( hBadge, hTarget, nCorner, dx, dy, nOverlap )` hangs the badge on a control:

- The badge is reparented under `hTarget` and becomes an **adornment** of it
  (`tkWidget_SetAdorner`, see [tkHost](tkHost)). It is painted after the target and its children,
  overhangs the target and is clipped by the target's parent. It is never hit-tested, so a click on
  it reaches the target, and it is never in the Tab order. It is hidden, moved and destroyed with
  the target.
- `nCorner`: `TKBADGE_TOP_RIGHT` (default), `_TOP_LEFT`, `_BOTTOM_RIGHT`, `_BOTTOM_LEFT`.
- `nOverlap`: `TKBADGE_OVERLAP_RECT` (default) anchors on the corner. `TKBADGE_OVERLAP_CIRCLE`
  anchors on the 45° point of the circle inscribed in the target, r (1 - 1/√2) in from each edge,
  with r half the target's shorter side: for avatars and round buttons.
- Before each paint the badge **centres itself on the anchor**, then moves by `(dx, dy)` design
  units, scaled. A count that widens grows both ways. While it shows nothing it is 0 × 0.
- Attached, it paints no background and no label. Its own tooltip is closed at `Attach`.
- `Attach` with `hTarget` 0, or the badge itself, detaches. Attaching an attached badge elsewhere
  moves it.
- `tkBadge_Detach( hBadge, hNewParent = 0 )` makes it a plain widget again, under `hNewParent` or
  the parent it had before it was first attached. Place it again with `tkWidget_SetPos`.
- `GetTarget` is the target, 0 while standalone.

## Drawing without a widget

`tkBadge_PaintInto( b, rc, spec )` draws a badge centred in `rc`. `TKBADGE_SPEC` holds everything
that decides its look: `nKind`, `nCount`, `wszText`, `wszGlyph`, `nPresence`, `nStatus`,
`nAppearance`, `nShape`, `nSize`, `nMaxCount`, `bShowZero`, `bInvisible`, `bEnabled`, `nRing`,
`nDiameter`, the fonts `fText` and `fGlyph`, `fScale`, `bCustom` with `clrFill` / `clrInk`, and
`pColors`.

- `fScale` (default 1) multiplies the design-unit sizes: pass the host's scale.
- Text is drawn only with `fText`; a glyph only with `fGlyph`.
- `nDiameter` sets a dot's or a presence mark's size in pixels; 0 takes the Size's.
- `pColors` 0 takes the app theme's colours.
- `tkBadge_MeasureSpec( spec, w, h )` gives the size with the ring, 0 × 0 when nothing shows.

```freebasic
' in a host paint handler: h is the TK_HOST ptr, b the TK_PAINT ptr, rcCell the cell
dim as TKBADGE_SPEC s
s.nKind = TKBADGE_KIND_TEXT : s.wszText = "NEW" : s.nStatus = TKBADGE_SUCCESS
s.fText = h->pDefaultFont : s.fScale = h->fScale
tkBadge_PaintInto( b, rcCell, s )
```

The widget is a thin shell over these: it fills a spec from its state and draws it.

## Layout

- `GetIdealSize` is valid before the control is sized: the badge with its ring, plus, standalone,
  the gap and the label. With a label, the height is the font's line height if that is taller
  than the badge. Attached, it is the badge alone.
- `GetBadgeRect` is the badge with its ring, in widget-local pixels; FALSE while nothing shows or
  the badge is not laid out.

## Notifications

| Callback | When |
| --- | --- |
| `SetPaintCallback` | replaces the drawing; `tkBadge_PaintDefault( p )` draws the stock badge |
| `SetMessageCallback` | mouse moves, leave, left and right button presses and releases; standalone only, since an attached badge is never hit. The answer is not used |

## Colours and theme

`TKBADGE_COLORS` has the back colour, the ring colour, the label and its disabled state, then a
fill and an ink for each status in status order (`FillAccent`, `InkAccent`, … `FillNeutral`,
`InkNeutral`), then `FillDisabled` and `InkDisabled`. `tkBadge_StatusFill( c, status )` and
`tkBadge_StatusInk( c, status )` read a status's pair.

`tkBadge_ThemeColors( t )` maps them from the theme's roles: the back and the ring are `Window`,
the fills come from the status roles. **Each status ink is chosen by contrast**: of the theme's
`SelectedText`, `TextStrong`, `Window` and `Text`, the one with the highest WCAG contrast on its
fill (`tkBadge_Contrast`). A theme file's own colours therefore stay legible. `SetColors` pins the
struct (a theme change leaves it) until `UnpinColors`.

## In the Form Designer

The toolbox's **Badge** (Common) has the properties above, in the order the form sets them:
MaxCount and ShowZero, then Count, Text, Glyph and Presence, then **Kind**. Each content setter
switches the kind, so Kind comes after them and the designer's choice wins. Then Invisible, Status,
Appearance, Shape, Size, Ring, Label, Justify, Font, GlyphFont (the form's glyph font, as a
button's) and TooltipText. Its events are Paint (the default) and Message.

**AttachTo** hangs a designed badge on another control of the form (not a Badge, not a component),
with **AttachCorner**, **AttachOffset** (`dx,dy`) and **AttachOverlap**. The generated code calls
`tkBadge_Attach` once both controls exist, and gives the badge no layout entry: its target places it.
The designer draws it on the corner, and a click there selects the badge.

**Bind** loads the count from a number field of the form's DataType; `SaveTo` leaves the field
alone. See [Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKBADGE_KIND_DOT`, `TKBADGE_KIND_COUNT`, `TKBADGE_KIND_TEXT`, `TKBADGE_KIND_GLYPH`,
`TKBADGE_KIND_PRESENCE` · `TKBADGE_ACCENT`, `TKBADGE_INFO`, `TKBADGE_SUCCESS`, `TKBADGE_WARNING`,
`TKBADGE_ERROR`, `TKBADGE_NEUTRAL` · `TKBADGE_FILLED`, `TKBADGE_OUTLINE`, `TKBADGE_TINT` ·
`TKBADGE_PILL`, `TKBADGE_ROUNDED`, `TKBADGE_SQUARE` · `TKBADGE_SMALL`, `TKBADGE_MEDIUM`,
`TKBADGE_LARGE` · `TKBADGE_TOP_RIGHT`, `TKBADGE_TOP_LEFT`, `TKBADGE_BOTTOM_RIGHT`,
`TKBADGE_BOTTOM_LEFT` · `TKBADGE_OVERLAP_RECT`, `TKBADGE_OVERLAP_CIRCLE` ·
`TKBADGE_PRESENCE_AVAILABLE`, `TKBADGE_PRESENCE_AWAY`, `TKBADGE_PRESENCE_BUSY`,
`TKBADGE_PRESENCE_DND`, `TKBADGE_PRESENCE_OFFLINE`, `TKBADGE_PRESENCE_OOO`,
`TKBADGE_PRESENCE_BLOCKED`, `TKBADGE_PRESENCE_UNKNOWN` · `TKBADGE_JUSTIFY_LEFT`,
`TKBADGE_JUSTIFY_CENTER`, `TKBADGE_JUSTIFY_RIGHT` · `TKBADGE_DEFAULT_MAXCOUNT` (99),
`TKBADGE_DEFAULT_PADX`, `TKBADGE_DEFAULT_LABELGAP` (design units), `TKBADGE_ATTACHED_RING`
(pixels, never scaled).

### Types

`TKBADGE_COLORS`, `TKBADGE_SPEC`, `TKBADGE_PAINTINFO` (the client, badge and label rects, enabled,
attached), `TKBADGE_MESSAGEINFO`, and the callback types `BDG_PaintCallbackSub`,
`BDG_MessageCallbackFunc`. `TKBADGE_STATE` is the per-instance state; reach it through the
procedures.

### Procedures

```freebasic
function tkBadge_FormatCount( byval nCount as long, byval nMaxCount as long = TKBADGE_DEFAULT_MAXCOUNT,
function tkBadge_Contrast( byval a as ulong, byval b as ulong ) as double
function tkBadge_StatusFill( byref c as TKBADGE_COLORS, byval nStatus as long ) as ulong
function tkBadge_StatusInk( byref c as TKBADGE_COLORS, byval nStatus as long ) as ulong
sub tkBadge_MeasureSpec( byref s as TKBADGE_SPEC, byref nWidth as long, byref nHeight as long )
sub tkBadge_PaintInto( byval b as TK_PAINT ptr, byref rc as TKRECT, byref s as TKBADGE_SPEC )
function tkBadge_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkBadge_GetID( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetEnabled( byval hBadge as TK_WIDGET ptr, byval isEnabled as boolean )
sub tkBadge_SetDot( byval hBadge as TK_WIDGET ptr )
sub tkBadge_SetCount( byval hBadge as TK_WIDGET ptr, byval nCount as long )
function tkBadge_GetCount( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetText( byval hBadge as TK_WIDGET ptr, byval Text as ustring )
function tkBadge_GetText( byval hBadge as TK_WIDGET ptr ) as ustring
sub tkBadge_SetGlyph( byval hBadge as TK_WIDGET ptr, byval Glyph as ustring )
sub tkBadge_SetPresence( byval hBadge as TK_WIDGET ptr, byval nPresence as long )
function tkBadge_GetPresence( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetKind( byval hBadge as TK_WIDGET ptr, byval nKind as long )
function tkBadge_GetKind( byval hBadge as TK_WIDGET ptr ) as long
function tkBadge_GetMaxCount( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetMaxCount( byval hBadge as TK_WIDGET ptr, byval nMax as long )
function tkBadge_GetShowZero( byval hBadge as TK_WIDGET ptr ) as boolean
sub tkBadge_SetShowZero( byval hBadge as TK_WIDGET ptr, byval bOn as boolean )
function tkBadge_GetInvisible( byval hBadge as TK_WIDGET ptr ) as boolean
sub tkBadge_SetInvisible( byval hBadge as TK_WIDGET ptr, byval bOn as boolean )
function tkBadge_IsShowing( byval hBadge as TK_WIDGET ptr ) as boolean
function tkBadge_GetStatus( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetStatus( byval hBadge as TK_WIDGET ptr, byval nStatus as long )
function tkBadge_GetAppearance( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetAppearance( byval hBadge as TK_WIDGET ptr, byval nAppearance as long )
function tkBadge_GetShape( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetShape( byval hBadge as TK_WIDGET ptr, byval nShape as long )
function tkBadge_GetSize( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetSize( byval hBadge as TK_WIDGET ptr, byval nSize as long )
function tkBadge_GetRing( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetRing( byval hBadge as TK_WIDGET ptr, byval nRing as long )
sub tkBadge_SetCustomColors( byval hBadge as TK_WIDGET ptr, byval clrFill as ulong, byval clrInk as ulong )
function tkBadge_GetLabel( byval hBadge as TK_WIDGET ptr ) as ustring
sub tkBadge_SetLabel( byval hBadge as TK_WIDGET ptr, byval Text as ustring )
function tkBadge_GetJustify( byval hBadge as TK_WIDGET ptr ) as long
sub tkBadge_SetJustify( byval hBadge as TK_WIDGET ptr, byval nJustify as long )
sub tkBadge_GetIdealSize( byval hBadge as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkBadge_GetBadgeRect( byval hBadge as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkBadge_Attach( byval hBadge as TK_WIDGET ptr, byval hTarget as TK_WIDGET ptr,
sub tkBadge_Detach( byval hBadge as TK_WIDGET ptr, byval hNewParent as TK_WIDGET ptr = 0 )
function tkBadge_GetTarget( byval hBadge as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkBadge_SetFont( byval hBadge as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkBadge_GetFont( byval hBadge as TK_WIDGET ptr ) as TTF_Font ptr
sub tkBadge_SetGlyphFont( byval hBadge as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkBadge_ApplyFonts( byval hBadge as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkBadge_SetTooltipText( byval hBadge as TK_WIDGET ptr, byval Text as ustring )
function tkBadge_GetTooltipText( byval hBadge as TK_WIDGET ptr ) as ustring
function tkBadge_GetTooltipHandle( byval hBadge as TK_WIDGET ptr ) as TK_TIP ptr
sub tkBadge_GetColors( byval hBadge as TK_WIDGET ptr, byval pColors as TKBADGE_COLORS ptr )
sub tkBadge_SetColors( byval hBadge as TK_WIDGET ptr, byval pColors as TKBADGE_COLORS ptr )
function tkBadge_ThemeColors( byref t as TKTHEME_COLORS ) as TKBADGE_COLORS
sub tkBadge_ApplyTheme( byval hBadge as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkBadge_UnpinColors( byval hBadge as TK_WIDGET ptr )
sub tkBadge_PaintDefault( byval pi as TKBADGE_PAINTINFO ptr )
sub tkBadge_SetPaintCallback( byval hBadge as TK_WIDGET ptr, byval usersub as BDG_PaintCallbackSub )
sub tkBadge_SetMessageCallback( byval hBadge as TK_WIDGET ptr, byval userfunc as BDG_MessageCallbackFunc )
```

### See also

- [tkControls](Category-tkControls)
- [tkHost](tkHost) (adornments), [tkTheme](tkTheme), [tkTooltip](tkTooltip)
- [tkRating](tkRating), its sibling from the same design
- [tkAvatar](tkAvatar), which draws tkBadge's presence mark
- [Form Designer](Form-Designer), data binding
