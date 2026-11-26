[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkAvatar**

# tkAvatar

Draws a person's avatar: their photo; or, without one, their initials on a colour picked from their
name; or a glyph; or a drawn person.

`tkAvatar` is the [tkControls](Category-tkControls) avatar: round, rounded or square, with a
[tkBadge](tkBadge) presence mark at the bottom right and an optional "active" ring. Photos are drawn
cropped to fill the shape. The initials and the colour come from the display name by fixed rules, so
one person looks the same in every list, on every platform. The same drawing is public as
`tkAvatar_PaintInto`, for a list row or a grid cell with no widget.

Every setter is silent. The avatar is not focusable and takes no keys; `Click` fires when the user
presses and releases the mouse on it. The Form Designer's **Avatar** binds its display name, in only,
and **BindImage** moves its image file's path both ways.

## Importing

```freebasic
#import "vendor/tkControls/tkAvatar"

using tkAvatar
using tkBadge
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkImage](tkImage) (`tkImageFile`) and
[tkBadge](tkBadge). `using tkBadge` names the `TKBADGE_PRESENCE_*` constants. Add `using tkPaint`
for a paint callback or `tkAvatar_PaintInto`.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Contact_Click( byval hAvatar as TK_WIDGET ptr )
    print "open the profile of " & tkAvatar_GetDisplayName( hAvatar )
end sub

dim as TK_WIDGET ptr av = tkAvatar_Create( tkHost_Root( host ), 100 )
tkAvatar_SetDisplayName( av, "Grace Hopper" )         ' silent: "GH", a colour from the name
tkAvatar_SetColorKey( av, "grace@example.com" )       ' the colour now survives a rename
tkAvatar_SetImageFile( av, "photos/grace.jpg" )       ' a failed load falls back to "GH"
tkAvatar_SetPresence( av, TKBADGE_PRESENCE_AVAILABLE )
tkAvatar_SetSize( av, 48 )
tkAvatar_SetClickable( av, true )                     ' a hand cursor
tkAvatar_SetClickCallback( av, @Contact_Click )

dim as long w, h
tkAvatar_GetIdealSize( av, w, h )                     ' valid before the control is sized
tkWidget_SetPos( av, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
```

## Content: image, initials, glyph, person

The avatar shows the first of these it can:

1. **A valid image.** `SetImageFile( path )` loads a file the avatar owns (`GetImageFile` returns
   the path). `SetImage( pImage )` borrows a `tkImageFile`, so many avatars can share one decoded
   photo; it must outlive them. Every way but `SetImageFile` clears the path, so BindImage never
   saves a file that is not the one shown. `SetImagePixels( w, h, argb )` copies `&hAARRGGBB` pixels.
   `SetImageData( pData, nBytes )` decodes an encoded PNG, JPEG or BMP in memory (a database BLOB)
   and copies it. A failed load leaves no image: `GetImageValid` is FALSE and the avatar falls
   through to the next step. `ClearImage` drops the image.
2. **Initials.** `SetInitials` overrides them; "" (the default) makes them from `DisplayName`.
   `GetEffectiveInitials` answers what the avatar shows at its current size ("" = none).
3. **A glyph.** `SetGlyph` and a glyph font from `SetGlyphFont` (borrowed); both are needed.
4. **A drawn person**: a head, and shoulders clipped to the avatar's own shape. `SetIsGroup( true )`
   draws two people.

An image is drawn cropped to fill the shape: proportions kept, centred, the overflow cut off
(tkPaint's `PaintImageShape` with `TK_IMGFIT_COVER`). A photo whose shorter side is more than twice
the diameter is drawn from a copy scaled to twice the diameter, made once per diameter, because
SDL has no mipmaps. `GetDrawnImageWidth` reports that copy's natural width, or the image's.

The initials are drawn in the avatar's own Inter Bold, about 40 % of the diameter tall and at most
70 % of it wide.

## Initials

`tkAvatar_Initials( name, nMax = 2 )` makes the initials, with or without a widget. It works on the
name's code points:

- **Words** are split by spaces, tabs, no-break spaces and ideographic spaces.
- **Brackets** `( )`, `[ ]` and `{ }` are skipped with everything inside them, wherever they are.
- **Punctuation and symbols** are dropped without splitting a word: "O'Brien" and "Jean-Luc" are one
  word each.
- **The result** is the first letter of the first word plus the first letter of the last word,
  upper-cased (é gives É). One word, or `nMax = 1`, gives one letter. A combining mark after a first
  letter stays with it.

| Name | Initials |
| --- | --- |
| `John Smith` | JS |
| `Mary Jane Watson` | MW |
| `john` | J |
| `(Contractor) Ann Lee`, `Ann Lee [Admin]` | AL |
| `O'Brien Pat` | OP |
| `+1 555 0100`, blank | none |
| `李小龙` | none |

**No initials** (and so the glyph or the person) when the name has no letters at all, as a phone
number, or when its first letter is Hebrew, Arabic, Indic, Thai, Hangul, Kana or CJK: initials do
not work that way in those scripts.

The widget shows **one letter** while its diameter is under 24 pixels (scaled).

## Colour

`SetColorMode` picks the background and ink of an image-less avatar:

- `TKAVATAR_COLORFUL` (default): one of `TKAVATAR_PALETTE_SIZE` (16) palette pairs, chosen by
  `tkAvatar_PaletteIndex` of the `ColorKey`, else of the `DisplayName`. That is FNV-1a 32 of the
  UTF-8 bytes, `and 15`: fixed, and the same on every platform. Set `SetColorKey` to an id or an
  e-mail, and a renamed person keeps their colour. An empty key gives the neutral pair, never a
  random one.
- `TKAVATAR_NEUTRAL`: `NeutralBack` / `NeutralInk`.
- `TKAVATAR_ACCENT`: `AccentBack` / `AccentInk`.
- `TKAVATAR_CUSTOM`: `CustomBack` / `CustomInk`. `SetCustomColors( back, ink )` sets the pair and the
  mode.

The palette is 16 hues 22.5° apart: muted and dark on a dark theme, pastel on a light one.
`tkAvatar_PaletteColors( bDark, idx, back, ink )` returns a pair. Each pair's ink is black or white,
whichever contrasts more, which is always at least 4.58:1. `GetEffectiveColors` answers the pair the
avatar is drawn in now.

## Shape, size and state

- `SetShape`: `TKAVATAR_CIRCLE` (default), `TKAVATAR_ROUNDED` (corners of 25 % of the side) or
  `TKAVATAR_SQUARE`.
- The avatar is the square of side `min( width, height )`, less the active ring's band
  (`TKAVATAR_RING_THICK` + `TKAVATAR_RING_GAP`, 4 pixels each side, always reserved), centred.
  The control's whole client is filled with `BackColor` first.
- `SetSize` (design units, 16..256, default `TKAVATAR_DEFAULT_SIZE` = 32) is `GetIdealSize`'s
  diameter. It does not resize the control: size it from `GetIdealSize`, which adds the ring's band
  both ways.
- `SetActive`: `TKAVATAR_ACTIVE_UNSET` (default); `TKAVATAR_ACTIVE_ACTIVE` draws a 2-pixel ring of
  `ActiveRingColor` 2 pixels outside the avatar ("speaking", "selected");
  `TKAVATAR_ACTIVE_INACTIVE` draws the avatar, image included, at half opacity. A disabled avatar
  (`SetEnabled( false )`) is drawn as inactive too.

## Presence

`SetPresence` takes `TKAVATAR_PRESENCE_NONE` (default) or a `TKBADGE_PRESENCE_*`: `_AVAILABLE`,
`_AWAY`, `_BUSY`, `_DND`, `_OFFLINE`, `_OOO`, `_BLOCKED`, `_UNKNOWN`. Any other value is ignored.

The mark is tkBadge's presence mark, 30 % of the diameter (at least 8 pixels, scaled), with a ring
cut out in `BackColor`. On a circle it is centred on the 45° point at the bottom right; on the other
shapes it sits inside the bottom-right corner. `GetPresenceRect` answers it.

A count or a dot is not built in: attach a [tkBadge](tkBadge) with `tkBadge_Attach` and
`TKBADGE_OVERLAP_CIRCLE`.

## Mouse and tooltip

- The avatar is not focusable and takes no keys.
- A press and a release inside fire `Click`. A release outside does nothing. The press is taken
  only while the avatar is enabled and has a Click callback or `Clickable` set.
- `SetClickable( true )` makes the pointer a hand. A Click callback works either way.
- The tip shows `TooltipText`, else the `DisplayName` while `NameTip` is on (the default).
  `GetTipText` answers what it would show now; `GetTooltipHandle` gives the [tkTooltip](tkTooltip).

## Notifications

| Callback | When |
| --- | --- |
| `SetClickCallback` | a press and a release inside the avatar |
| `SetPaintCallback` | replaces the drawing; `tkAvatar_PaintDefault( p )` draws the stock avatar |
| `SetMessageCallback` | the mouse stream: buttons, moves, leave; TRUE on a left press claims it |

The Click callback runs last and may destroy the avatar. The paint info has the client rect, the
avatar's square, the presence rect (empty without presence) and the enabled state; the client is
already filled with `BackColor`.

## Geometry

`GetIdealSize` is valid before the control is sized. `GetAvatarRect` and `GetPresenceRect` answer in
control-local pixels; `GetPresenceRect` is FALSE without presence.

## Drawing with no widget

`TKAVATAR_SPEC` holds everything that decides an avatar's look: the name, the initials, a borrowed
image, the glyph and its font, the initials' font, the shape, the colour mode and key, the
presence, the active state, `bIsGroup`, `bDark`, the scale and the colours.
`tkAvatar_PaintInto( b, rc, spec )` draws it:

- The avatar is the square of side `min( w, h )` centred in `rc`. The active ring is drawn round that
  square, so leave `TKAVATAR_RING_THICK + TKAVATAR_RING_GAP` pixels round it.
- `fText` is the initials' font, resized to the diameter (`TTF_SetFontSize`). Without it there are
  no initials: the glyph or the person.
- `pColors = 0` takes the app theme's colours and its darkness. With `pColors` set, `bDark`
  (default true) picks the palette half.
- `fScale` sets the one-letter size and the presence mark's minimum.
- No pre-scaled copy of a large photo is made.

`tkAvatar_FitFont( f, d, text )` sizes a font for diameter `d` as the avatar does.
[tkAvatarGroup](tkAvatarGroup) and [tkChip](tkChip)'s leading avatar are drawn this way.

## Colours and theme

`TKAVATAR_COLORS` has `BackColor` (what the avatar sits on, and the presence mark's cut-out), the
`NeutralBack` / `NeutralInk`, `AccentBack` / `AccentInk` and `CustomBack` / `CustomInk` pairs, and
`ActiveRingColor`. The 16 palette pairs are not in it. `tkAvatar_ThemeColors( t )` maps them from
the theme's roles: the back from Window, the neutral pair from Surface and TextDim, the accent pair
from Accent with SelectedText or Window as ink (whichever contrasts more), the custom pair from
Surface and Text, the ring from Accent.

`SetColors` pins the struct (a theme change leaves it) until `UnpinColors`. The palette half follows
the theme's darkness even while the colours are pinned. The pair `SetCustomColors` set survives a
theme change while the mode is `TKAVATAR_CUSTOM`.

## In the Form Designer

The toolbox's **Avatar** (Common) has the properties above, in the order the form sets them:
DisplayName, Initials, ImageFile, Glyph, IsGroup, ColorMode, ColorKey, Shape, Size, Presence,
Active, Clickable, NameTip, TooltipText. Its events are Click (the default), Paint and Message.
GlyphFont gives a Glyph avatar the form's glyph font (as a button's). `Size` feeds only
`GetIdealSize`; a designed avatar's diameter comes from its rectangle.

**Bind** moves a text field of the form's DataType into the display name, in only: `SaveTo` never
writes it. **BindImage** moves the image file's path into and out of a text field. See
[Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKAVATAR_CIRCLE`, `TKAVATAR_ROUNDED`, `TKAVATAR_SQUARE` · `TKAVATAR_COLORFUL`, `TKAVATAR_NEUTRAL`,
`TKAVATAR_ACCENT`, `TKAVATAR_CUSTOM` · `TKAVATAR_ACTIVE_UNSET`, `TKAVATAR_ACTIVE_ACTIVE`,
`TKAVATAR_ACTIVE_INACTIVE` · `TKAVATAR_PRESENCE_NONE` · `TKAVATAR_PALETTE_SIZE` (16) ·
`TKAVATAR_DEFAULT_SIZE` (32) · `TKAVATAR_RING_THICK`, `TKAVATAR_RING_GAP` (2 pixels each).

### Types

`TKAVATAR_COLORS`, `TKAVATAR_SPEC` (an avatar's look, for `tkAvatar_PaintInto`),
`TKAVATAR_PAINTINFO` (the client, avatar and presence rects, the enabled state),
`TKAVATAR_MESSAGEINFO`, `TKAVATAR_STATE` (the widget's state), and the callback types
`AVT_ClickCallbackSub`, `AVT_PaintCallbackSub`, `AVT_MessageCallbackFunc`.

### Procedures

```freebasic
function tkAvatar_Initials( byval Name_ as ustring, byval nMax as long = 2 ) as ustring
function tkAvatar_PaletteIndex( byval Key as ustring ) as long
sub tkAvatar_PaletteColors( byval bDark as boolean, byval idx as long, byref clrBack as ulong, byref clrInk as ulong )
sub tkAvatar_FitFont( byval f as TTF_Font ptr, byval d as long, byref Text as ustring )
sub tkAvatar_PaintInto( byval b as TK_PAINT ptr, byref rc as TKRECT, byref s as TKAVATAR_SPEC )
function tkAvatar_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkAvatar_GetID( byval hAvatar as TK_WIDGET ptr ) as long
sub tkAvatar_SetEnabled( byval hAvatar as TK_WIDGET ptr, byval isEnabled as boolean )
function tkAvatar_GetDisplayName( byval hAvatar as TK_WIDGET ptr ) as ustring
sub tkAvatar_SetDisplayName( byval hAvatar as TK_WIDGET ptr, byval Name_ as ustring )
function tkAvatar_GetInitials( byval hAvatar as TK_WIDGET ptr ) as ustring
sub tkAvatar_SetInitials( byval hAvatar as TK_WIDGET ptr, byval Initials as ustring )
function tkAvatar_GetEffectiveInitials( byval hAvatar as TK_WIDGET ptr ) as ustring
sub tkAvatar_SetImageFile( byval hAvatar as TK_WIDGET ptr, byval Path as ustring )
function tkAvatar_GetImageFile( byval hAvatar as TK_WIDGET ptr ) as ustring
sub tkAvatar_SetImage( byval hAvatar as TK_WIDGET ptr, byval pImage as tkImageFile ptr )
sub tkAvatar_SetImagePixels( byval hAvatar as TK_WIDGET ptr, byval w as long, byval h as long, byval argb as ulong ptr )
sub tkAvatar_SetImageData( byval hAvatar as TK_WIDGET ptr, byval pData as const any ptr, byval nBytes as long )
sub tkAvatar_ClearImage( byval hAvatar as TK_WIDGET ptr )
function tkAvatar_GetImageValid( byval hAvatar as TK_WIDGET ptr ) as boolean
function tkAvatar_GetDrawnImageWidth( byval hAvatar as TK_WIDGET ptr ) as long
sub tkAvatar_SetGlyph( byval hAvatar as TK_WIDGET ptr, byval Glyph as ustring )
sub tkAvatar_SetIsGroup( byval hAvatar as TK_WIDGET ptr, byval bOn as boolean )
function tkAvatar_GetColorMode( byval hAvatar as TK_WIDGET ptr ) as long
sub tkAvatar_SetColorMode( byval hAvatar as TK_WIDGET ptr, byval nMode as long )
sub tkAvatar_SetColorKey( byval hAvatar as TK_WIDGET ptr, byval Key as ustring )
sub tkAvatar_GetEffectiveColors( byval hAvatar as TK_WIDGET ptr, byref clrBack as ulong, byref clrInk as ulong )
sub tkAvatar_SetCustomColors( byval hAvatar as TK_WIDGET ptr, byval clrBack as ulong, byval clrInk as ulong )
function tkAvatar_GetShape( byval hAvatar as TK_WIDGET ptr ) as long
sub tkAvatar_SetShape( byval hAvatar as TK_WIDGET ptr, byval nShape as long )
function tkAvatar_GetSize( byval hAvatar as TK_WIDGET ptr ) as long
sub tkAvatar_SetSize( byval hAvatar as TK_WIDGET ptr, byval nDu as long )
function tkAvatar_GetPresence( byval hAvatar as TK_WIDGET ptr ) as long
sub tkAvatar_SetPresence( byval hAvatar as TK_WIDGET ptr, byval nPresence as long )
function tkAvatar_GetActive( byval hAvatar as TK_WIDGET ptr ) as long
sub tkAvatar_SetActive( byval hAvatar as TK_WIDGET ptr, byval nActive as long )
sub tkAvatar_GetIdealSize( byval hAvatar as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkAvatar_GetAvatarRect( byval hAvatar as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkAvatar_GetPresenceRect( byval hAvatar as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkAvatar_SetClickable( byval hAvatar as TK_WIDGET ptr, byval bOn as boolean )
function tkAvatar_GetClickable( byval hAvatar as TK_WIDGET ptr ) as boolean
sub tkAvatar_SetNameTip( byval hAvatar as TK_WIDGET ptr, byval bOn as boolean )
sub tkAvatar_SetTooltipText( byval hAvatar as TK_WIDGET ptr, byval Text as ustring )
function tkAvatar_GetTipText( byval hAvatar as TK_WIDGET ptr ) as ustring
function tkAvatar_GetTooltipHandle( byval hAvatar as TK_WIDGET ptr ) as TK_TIP ptr
sub tkAvatar_SetGlyphFont( byval hAvatar as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkAvatar_GetColors( byval hAvatar as TK_WIDGET ptr, byval pColors as TKAVATAR_COLORS ptr )
sub tkAvatar_SetColors( byval hAvatar as TK_WIDGET ptr, byval pColors as TKAVATAR_COLORS ptr )
function tkAvatar_ThemeColors( byref t as TKTHEME_COLORS ) as TKAVATAR_COLORS
sub tkAvatar_ApplyTheme( byval hAvatar as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkAvatar_UnpinColors( byval hAvatar as TK_WIDGET ptr )
sub tkAvatar_PaintDefault( byval pi as TKAVATAR_PAINTINFO ptr )
sub tkAvatar_SetClickCallback( byval hAvatar as TK_WIDGET ptr, byval usersub as AVT_ClickCallbackSub )
sub tkAvatar_SetPaintCallback( byval hAvatar as TK_WIDGET ptr, byval usersub as AVT_PaintCallbackSub )
sub tkAvatar_SetMessageCallback( byval hAvatar as TK_WIDGET ptr, byval userfunc as AVT_MessageCallbackFunc )
```

### See also

- [tkControls](Category-tkControls)
- [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkImage](tkImage)
- [tkBadge](tkBadge), the presence mark and attached badges
- [tkAvatarGroup](tkAvatarGroup), a row of avatars
- [Form Designer](Form-Designer), data binding
