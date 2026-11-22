[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkIconPanel**

# tkIconPanel

Draws a row or column of icon-only buttons, toggles and separators.

tkIconPanel is a compact strip of icon buttons with no captions: the small tool row above a panel, or the activity bar down the side of an editor window. Each item is an `IP_KIND_COMMAND` (a button), an `IP_KIND_TOGGLE` (latches on and off) or an `IP_KIND_SEPARATOR`. An icon is a glyph from the font you set, or an image file; captions belong in the tooltips.

Each cell is its declared icon size plus padding, whatever the glyph, and `tkIconPanel_SetJustify` places the run left, centred or right. The item set is static once built. Selection is a set of latched toggles; a radio-style group is one call, `tkIconPanel_SelectExclusive`, from the SelChange callback.

`tkIconPanel_SetVertical` turns the row into a column, and `tkIconPanel_SetMarker` draws a selection marker: a slab down a column's left edge, or a rule under a row's cell. Both are off by default. A paint callback draws each item yourself; `tkIconPanel_PaintItemDefault( p )` in it draws the stock item first. A click never takes the keyboard focus. Setters are silent; Click and SelChange fire only for what the user does.

## Importing

```freebasic
#import "vendor/tkControls/tkIconPanel"
using tkIconPanel
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip) and [tkImage](tkImage). Add `using tkPaint` to write a paint callback.

## Example

An activity bar. `gHost` is the window ([tkHost](tkHost)); `gGlyph12` is the bundled icon font, opened with `tkHost_OpenFont( gHost, tkHost_FontDir() & TK_FONT_ICONS, 12 )`.

```freebasic
sub OnSelChange( byval p as TK_WIDGET ptr, byval idx as long, byval isSelected as boolean )
    tkIconPanel_SelectExclusive( p, idx )        ' one view at a time
end sub

sub OnClick( byval p as TK_WIDGET ptr, byval idx as long, byval id as long )
    print "command "; id
end sub

dim as TK_WIDGET ptr bar = tkIconPanel_Create( tkHost_Root( gHost ), 1100 )
tkIconPanel_SetVertical( bar, true )
tkIconPanel_SetFont( bar, gGlyph12 )
tkIconPanel_SetIconSize( bar, tkHost_Scale( gHost, 24 ), tkHost_Scale( gHost, 24 ) )
tkIconPanel_SetPadding( bar, tkHost_Scale( gHost, 6 ), tkHost_Scale( gHost, 6 ) )
tkIconPanel_SetMarker( bar, tkHost_Scale( gHost, 3 ), true )
tkIconPanel_SetSelChangeCallback( bar, @OnSelChange )
tkIconPanel_SetClickCallback( bar, @OnClick )

dim as long idx
idx = tkIconPanel_AddItem( bar, IP_KIND_TOGGLE, wchr( TK_ICON_DOCUMENT ), 1 ) : tkIconPanel_SetTooltipText( bar, idx, "Explorer" )
idx = tkIconPanel_AddItem( bar, IP_KIND_TOGGLE, wchr( TK_ICON_SEARCH ), 2 )   : tkIconPanel_SetTooltipText( bar, idx, "Search" )
tkIconPanel_AddSeparator( bar )
idx = tkIconPanel_AddItem( bar, IP_KIND_COMMAND, wchr( TK_ICON_SETTINGS ), 4 ) : tkIconPanel_SetTooltipText( bar, idx, "Settings" )
tkIconPanel_SetSelected( bar, 0, true )

tkWidget_SetPos( bar, 0, 0, tkIconPanel_GetIdealWidth( bar ), tkIconPanel_GetIdealHeight( bar ) )
```

The toolchain's `examples/tkControls/tkIconPanel/` shows three rows (left, centred and right, one with a custom painter) and this column.

## How it works

### The cell model: you own the spacing

Each item occupies a cell whose length along the run is the sum of three declared numbers.
Nothing is measured, ever. For a row (a column is the same with the axes swapped):

```
  cellWidth(i)  = padBefore(i) + iconWidth(i)   + padAfter(i)     TOGGLE / COMMAND
                = padBefore(i) + separatorWidth + padAfter(i)     SEPARATOR
  padBefore(i)  = the item's own value, or the panel's when the item's is -1
  padAfter(i)   = the item's own value, or the panel's when the item's is -1
  iconWidth(i)  = the item's own value, or the panel's when the item's is  0
  iconHeight(i) = the item's own value, or the panel's when the item's is  0
                  (clamped down to the client height, once there is one)
  totalW        = sum of every cellWidth        <- GetIdealWidth
  x0            = 0                             LEFT, or totalW >= clientW
                = (clientW - totalW) \ 2        CENTER
                = clientW - totalW              RIGHT
  rc(i)         = ( x, 0, x + cellWidth(i), clientH )        the full client height
  rcIcon(i)     = ( x + padBefore(i), yTop, x + padBefore(i) + iconWidth(i), yTop + iconHeight(i) )
                  where yTop = (clientH - iconHeight(i)) \ 2
```

- A resize moves `x0` and nothing else: the spacing inside the run is authored and is never
  redistributed or squeezed, so the run slides as one block.
- `rc` spans the full client height, so the hot and selected fills read like a menu bar and the
  hit target includes the padding. The glyph sits centred in its cell only when `padBefore` and
  `padAfter` are equal, as the defaults are.
- In a column (`SetVertical`) the cells stack downwards, the icon is centred across the column,
  a separator's rule lies flat, and justify LEFT / CENTER / RIGHT means top / centre / bottom.
  `GetIdealWidth` is then the widest icon and `GetIdealHeight` the whole run; in a row
  `GetIdealHeight` is the tallest icon.
- Layout is lazy. A setter marks it stale and asks for a repaint; the next paint, or any rect,
  hit-test or ideal-size query, recomputes it. Building twenty items costs one layout pass.
- When the run is longer than the client, justification falls back to LEFT and the tail clips
  at the far edge; the leading items keep honest rects, and a point outside the client never
  lights an item.
- Item rects are empty until the panel has a size. `GetIdealWidth` and `GetIdealHeight` are the
  exception: they are valid immediately, which is what you call to choose that size.

### Three kinds of item

| Kind | Behaviour |
| --- | --- |
| `IP_KIND_TOGGLE` | Latches. A completed click flips its selected flag and calls the SelChange callback. |
| `IP_KIND_COMMAND` | Momentary. Draws pressed while held, calls the Click callback on a completed click, never latches. |
| `IP_KIND_SEPARATOR` | A rule the panel draws. Never hot, never pressed, and `tkIconPanel_HitTest` returns -1 for it. |

The kind is fixed when the item is added. A separator's rule replaces the icon's length along
the run but keeps its extent across it, so it stands as tall (or, in a column, as wide) as the
icons it divides; give it its own padding to size the gap. The kind is not validated: any
other value is laid out and painted like an icon item, but a completed click on it does nothing.

### Selection is a set

Every toggle latches independently, so any number can be selected at once. Radio behaviour is
yours to ask for: call `tkIconPanel_SelectExclusive( h, idx )` (latch `idx`, clear every other
toggle) from the SelChange callback. It is silent, as is `tkIconPanel_SetSelected`, which
refuses (returns false for) anything but a toggle; so neither can re-enter the callback.

### A click is decided on release

Pressing the left button over an enabled, non-separator item takes the mouse capture and arms
the press. The action happens on release, and only if the pointer is still over the same item:
press, slide off, release, and nothing fires. While the pointer is off the item it stops
drawing as pressed, and sliding back re-arms it. Only a release, a capture loss, disabling the
pressed item or disabling the panel ends the gesture. A click never takes the keyboard focus,
so the panel cannot steal the caret from an editor beside it. A rapid second click is an
ordinary press and toggles the item again.

### Glyph or image

An icon cell holds a glyph or an image, never both. `tkIconPanel_SetImage( h, idx, path )`
loads any file [tkImage](tkImage) can read and draws it in the same declared cell, aspect kept
and centred, so no geometry changes. A successful load clears the item's glyph; a non-empty
`SetGlyph` frees its image; `SetImage( h, idx, "" )` removes the image. It returns false only
for a bad index or a file that would not load, and a failed load leaves no image. The panel
owns the images and frees them when it is destroyed.

The font is a paint-time input: `SetFont` repaints but never re-lays out, because no geometry
came from it. `rcIcon` is a layout cell, not a measurement, so a glyph too large for it clips:
pick a size that fits the icon size you declared. With no font set, the host's default font
draws.

### Pixels

The defaults (icon 20 x 20, padding 4 and 4, separator 1) are scaled for the surface at
creation, and every size is rescaled when the scale changes; an item's inherit values (-1, 0)
stay inheriting. Every setter takes pixels as given: scale them with `tkHost_Scale`.

### Tooltips

One tooltip serves the whole panel and resolves its text for the item under the pointer:
the item's own text (`SetTooltipText`), else the tooltip callback, else no tip. Moving to
another item hides the tip and re-resolves it on the next dwell, and a press hides it.
`SetHoverTime`, `SetAutoPopTime` and `SetReshowTime` set the tip's delays in milliseconds, and
`tkIconPanel_GetTooltipHandle` returns its `TK_TIP ptr` for any [tkTooltip](tkTooltip) call.

## Behaviour and limits

- The item set is static: `AddItem` and `AddSeparator` add, and nothing removes, inserts or
  reorders. Drive a built strip with `SetSelected`, `SetEnabled`, `SetGlyph`, `SetImage` and
  `SetItemForeColor`.
- `FindItemByID` returns the first item with that id and skips separators, which all carry
  id 0.
- A disabled item keeps its cell, greys out, never goes hot or pressed and swallows clicks, but
  `HitTest` still reports it. Disabling the hot item clears the hover; disabling the pressed
  item cancels the press.
- `SetJustify` ignores values outside the three `IP_JUSTIFY_*` constants.
- No keyboard handling and no focus. The right button is reported to the message callback and
  never acted on, so that is where a context menu goes.
- A paint callback replaces the built-in painter for every item, separators included.

## Colours

`TKICONPANEL_COLORS` holds nine colours. They come from the theme at creation and on every
theme change until `SetColors` pins them; `UnpinColors` hands them back.

| Field | Theme role | Paints |
| --- | --- | --- |
| `BackColor` | `Window` | The panel background, and an idle cell |
| `ForeColor` | `Text` | An idle glyph |
| `BackColorHot` / `ForeColorHot` | `SurfaceHot` / `TextHot` | The item under the pointer |
| `BackColorSelect` / `ForeColorSelect` | `Selected` / `SelectedText` | A latched toggle, and the press flash |
| `ForeColorDisabled` | `TextDisabled` | A disabled glyph; its cell keeps `BackColor` |
| `SeparatorColor` | `Divider` | A separator's rule |
| `MarkerColor` | `Accent` | The selection marker |

The built-in painter picks one fill and one glyph colour per item:

```
disabled  >  pressed  >  hot  >  selected  >  per-item fore colour  >  idle
```

There is no separate pressed colour: a press reuses the Select pair, a flash on a command and a
preview of the latched look on a toggle. `SetItemForeColor` overrides only the idle glyph
colour (a red record dot, a green run arrow); `ClearItemForeColor` drops it. With a marker
(`SetMarker( h, nSize, bFillSelected )`, `nSize` 0 for none) a selected item also gets a slab of
`MarkerColor` down a column's left edge or under a row's cell; `bFillSelected = false` keeps the
selected item on the idle fill, so the marker alone shows it, as in a tab row.

The painter fills the client with `BackColor`, then for each item fills `rc`, draws the marker,
and draws the image into `rcIcon` or, failing that, the glyph centred in it. A separator is its
cell in `BackColor` with `rcIcon` filled in `SeparatorColor`.

## Callbacks

- **Click**, `IP_ClickCallbackSub( h, idx, id )`: a command item was clicked (a completed
  press and release on the same enabled item). `id` is the item's command id.
- **SelChange**, `IP_SelChangeCallbackSub( h, idx, isSelected )`: the user latched or
  unlatched a toggle. The state is already updated, so `GetSelected( h, idx )` equals
  `isSelected`.
- **Tooltip**, `IP_TooltipCallbackFunc( h, idx ) as ustring`: the tip for an item with no text
  of its own, asked only when a tip is about to show; `""` for none.
- **Paint item**, `IP_PaintItemCallbackSub( p )`: draws one item instead of the built-in
  painter, separators included, so it must handle `p->itemKind = IP_KIND_SEPARATOR`. The client
  is already filled with `BackColor`. Confine drawing to `p->rc` (the whole cell, padding
  included); draw the icon in `p->rcIcon`, and when `p->pImage` is set draw it with
  `tkImage_Paint` instead of the glyph. `isPressed` is true only while the press is live and the
  pointer is still on the item; `isVertical` says which way the run goes.
  `tkIconPanel_PaintItemDefault( p )` draws the stock item first.
- **Message**, `IP_MessageCallbackFunc( m ) as boolean`: reports `TKM_MOUSEMOVE`,
  `TKM_MOUSELEAVE`, `TKM_LBUTTONDOWN`, `TKM_LBUTTONUP`, `TKM_RBUTTONDOWN` and `TKM_RBUTTONUP`
  with `x`, `y` and `idx`, the item under the pointer (-1 for none, a separator or a disabled
  item; always -1 for the leave). Returning true from `TKM_LBUTTONDOWN` suppresses the press;
  for the others the return value is ignored. The button-up is reported after the capture is
  released and before Click or SelChange fires.

`tkIconPanel_GetHotItem` and `tkIconPanel_GetPressedItem` return the item under the pointer and
the item under a live press, or -1.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKICONPANEL_DEFAULT_ICONWIDTH = 20
const TKICONPANEL_DEFAULT_ICONHEIGHT = 20
const TKICONPANEL_DEFAULT_PADBEFORE = 4
const TKICONPANEL_DEFAULT_PADAFTER = 4
const TKICONPANEL_DEFAULT_SEPWIDTH = 1

enum
    IP_JUSTIFY_LEFT = 0           ' TOP in vertical mode
    IP_JUSTIFY_CENTER
    IP_JUSTIFY_RIGHT              ' BOTTOM in vertical mode
end enum

enum
    IP_KIND_TOGGLE = 0
    IP_KIND_COMMAND
    IP_KIND_SEPARATOR
end enum
```

### Types

```freebasic
type TKICONPANEL_COLORS
    BackColor         as ulong = &hFF21252Bul    ' ( 33, 37, 43) panel + idle cell
    ForeColor         as ulong = &hFFD7DAE0ul    ' (215,218,224) idle glyph
    BackColorHot      as ulong = &hFF2C313Aul    ' ( 44, 49, 58)
    ForeColorHot      as ulong = &hFFFFFFFFul
    BackColorSelect   as ulong = &hFF264F78ul    ' ( 38, 79,120) latched toggle + press flash
    ForeColorSelect   as ulong = &hFFFFFFFFul
    ForeColorDisabled as ulong = &hFF6E737Dul    ' (110,115,125)
    SeparatorColor    as ulong = &hFF464C58ul    ' ( 70, 76, 88)
    MarkerColor       as ulong = &hFF569CD6ul    ' the selection marker (tk addition)
end type

type TKICONPANEL_ITEM
    itemKind      as long = IP_KIND_TOGGLE
    wszGlyph      as ustring
    pImage        as tkImageFile ptr     ' OWNED; a cell is a glyph or an image, never both
    wszTooltip    as ustring
    id            as long
    itemData      as integer
    isSelected    as boolean
    isEnabled     as boolean = true
    nPadBefore    as long = -1           ' -1 = inherit
    nPadAfter     as long = -1
    nIconWidth    as long = 0            '  0 = inherit
    nIconHeight   as long = 0
    ForeColorItem as ulong
    bHasForeColor as boolean
    nCellWidth    as long                ' the cell's extent ALONG the run (a height when vertical)
    rc            as TKRECT
    rcIcon        as TKRECT
end type

type TKICONPANEL_PAINTINFO
    hIconPanel as TK_WIDGET ptr
    itemID     as long
    b          as TK_PAINT ptr
    itemKind   as long
    rc         as TKRECT
    rcIcon     as TKRECT
    isHot      as boolean
    isSelected as boolean
    isPressed  as boolean
    isEnabled  as boolean
    wszGlyph   as ustring
    pImage     as tkImageFile ptr        ' draw with tkImage_Paint INSTEAD OF the glyph
    isVertical as boolean
end type

type TKICONPANEL_MESSAGEINFO
    hIconPanel as TK_WIDGET ptr
    msg        as long                   ' TKM_*
    x          as single
    y          as single
    idx        as long                   ' item under the mouse, -1 for none
end type

type TKICONPANEL_STATE   ' per-instance state; reach it through the procedures

type IP_PaintItemCallbackSub as sub( byval p as TKICONPANEL_PAINTINFO ptr )
type IP_MessageCallbackFunc as function( byval m as TKICONPANEL_MESSAGEINFO ptr ) as boolean
type IP_TooltipCallbackFunc as function( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as ustring
type IP_ClickCallbackSub as sub( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval id as long )
type IP_SelChangeCallbackSub as sub( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval isSelected as boolean )
```

### Procedures

```freebasic
function tkIconPanel_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkIconPanel_AddItem( byval hIconPanel as TK_WIDGET ptr, byval itemKind as long, byval Glyph as ustring, byval id as long = 0, byval itemData as integer = 0 ) as long
function tkIconPanel_AddSeparator( byval hIconPanel as TK_WIDGET ptr ) as long
sub tkIconPanel_Refresh( byval hIconPanel as TK_WIDGET ptr )
function tkIconPanel_GetCount( byval hIconPanel as TK_WIDGET ptr ) as long
function tkIconPanel_IsValidItem( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as boolean
function tkIconPanel_FindItemByID( byval hIconPanel as TK_WIDGET ptr, byval id as long ) as long
function tkIconPanel_HitTest( byval hIconPanel as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkIconPanel_GetItemKind( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as long
function tkIconPanel_GetGlyph( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as ustring
function tkIconPanel_SetGlyph( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval Glyph as ustring ) as boolean
function tkIconPanel_SetImage( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval Path as ustring ) as boolean
function tkIconPanel_GetItemID( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as long
function tkIconPanel_SetItemID( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval id as long ) as boolean
function tkIconPanel_GetItemData( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as integer
function tkIconPanel_SetItemData( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval itemData as integer ) as boolean
function tkIconPanel_GetSelected( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as boolean
function tkIconPanel_SetSelected( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval isSelected as boolean ) as boolean
sub tkIconPanel_SelectExclusive( byval hIconPanel as TK_WIDGET ptr, byval idx as long )
function tkIconPanel_GetEnabled( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as boolean
function tkIconPanel_SetEnabled( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval isEnabled as boolean ) as boolean
function tkIconPanel_GetJustify( byval hIconPanel as TK_WIDGET ptr ) as long
sub tkIconPanel_SetJustify( byval hIconPanel as TK_WIDGET ptr, byval nJustify as long )
sub tkIconPanel_SetVertical( byval hIconPanel as TK_WIDGET ptr, byval bVertical as boolean )
function tkIconPanel_GetVertical( byval hIconPanel as TK_WIDGET ptr ) as boolean
sub tkIconPanel_SetMarker( byval hIconPanel as TK_WIDGET ptr, byval nSize as long, byval bFillSelected as boolean = true )
sub tkIconPanel_GetMarker( byval hIconPanel as TK_WIDGET ptr, byref nSize as long, byref bFillSelected as boolean )
function tkIconPanel_GetMarkerRect( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
sub tkIconPanel_GetIconSize( byval hIconPanel as TK_WIDGET ptr, byref nIconWidth as long, byref nIconHeight as long )
sub tkIconPanel_SetIconSize( byval hIconPanel as TK_WIDGET ptr, byval nIconWidth as long, byval nIconHeight as long )
sub tkIconPanel_GetPadding( byval hIconPanel as TK_WIDGET ptr, byref nPadBefore as long, byref nPadAfter as long )
sub tkIconPanel_SetPadding( byval hIconPanel as TK_WIDGET ptr, byval nPadBefore as long, byval nPadAfter as long )
function tkIconPanel_GetSeparatorWidth( byval hIconPanel as TK_WIDGET ptr ) as long
sub tkIconPanel_SetSeparatorWidth( byval hIconPanel as TK_WIDGET ptr, byval nSepWidth as long )
function tkIconPanel_SetItemPadding( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval nPadBefore as long, byval nPadAfter as long ) as boolean
function tkIconPanel_SetItemIconSize( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval nIconWidth as long, byval nIconHeight as long ) as boolean
function tkIconPanel_GetItemRect( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkIconPanel_GetItemIconRect( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkIconPanel_GetIdealWidth( byval hIconPanel as TK_WIDGET ptr ) as long
function tkIconPanel_GetIdealHeight( byval hIconPanel as TK_WIDGET ptr ) as long
sub tkIconPanel_GetColors( byval hIconPanel as TK_WIDGET ptr, byval pColors as TKICONPANEL_COLORS ptr )
sub tkIconPanel_SetColors( byval hIconPanel as TK_WIDGET ptr, byval pColors as TKICONPANEL_COLORS ptr )
function tkIconPanel_ThemeColors( byref t as TKTHEME_COLORS ) as TKICONPANEL_COLORS
sub tkIconPanel_ApplyTheme( byval hIconPanel as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkIconPanel_UnpinColors( byval hIconPanel as TK_WIDGET ptr )
sub tkIconPanel_ApplyFonts( byval hIconPanel as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
function tkIconPanel_SetItemForeColor( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval clr as ulong ) as boolean
function tkIconPanel_ClearItemForeColor( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as boolean
function tkIconPanel_GetFont( byval hIconPanel as TK_WIDGET ptr ) as TTF_Font ptr
function tkIconPanel_SetFont( byval hIconPanel as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
function tkIconPanel_GetTooltipHandle( byval hIconPanel as TK_WIDGET ptr ) as TK_TIP ptr
sub tkIconPanel_SetHoverTime( byval hIconPanel as TK_WIDGET ptr, byval milliseconds as long )
sub tkIconPanel_SetAutoPopTime( byval hIconPanel as TK_WIDGET ptr, byval milliseconds as long )
sub tkIconPanel_SetReshowTime( byval hIconPanel as TK_WIDGET ptr, byval milliseconds as long )
function tkIconPanel_GetTooltipText( byval hIconPanel as TK_WIDGET ptr, byval idx as long ) as ustring
function tkIconPanel_SetTooltipText( byval hIconPanel as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkIconPanel_GetHotItem( byval hIconPanel as TK_WIDGET ptr ) as long
function tkIconPanel_GetPressedItem( byval hIconPanel as TK_WIDGET ptr ) as long
sub tkIconPanel_PaintItemDefault( byval p as TKICONPANEL_PAINTINFO ptr )
sub tkIconPanel_SetPaintItemCallback( byval hIconPanel as TK_WIDGET ptr, byval usersub as IP_PaintItemCallbackSub )
sub tkIconPanel_SetMessageCallback( byval hIconPanel as TK_WIDGET ptr, byval userfunc as IP_MessageCallbackFunc )
sub tkIconPanel_SetTooltipCallback( byval hIconPanel as TK_WIDGET ptr, byval userfunc as IP_TooltipCallbackFunc )
sub tkIconPanel_SetClickCallback( byval hIconPanel as TK_WIDGET ptr, byval usersub as IP_ClickCallbackSub )
sub tkIconPanel_SetSelChangeCallback( byval hIconPanel as TK_WIDGET ptr, byval usersub as IP_SelChangeCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkImage](tkImage), [tkTooltip](tkTooltip), [tkToolbar](tkToolbar)
