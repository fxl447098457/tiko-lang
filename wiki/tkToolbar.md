[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkToolbar**

# tkToolbar

Draws a toolbar of command, toggle, split and dropdown buttons that overflows to a menu.

tkToolbar is a strip of buttons along the top of a window or panel. Each item is one of six kinds: `TBR_KIND_COMMAND` (a button), `TBR_KIND_TOGGLE` (stays pressed; toggles sharing a group id act as radio buttons), `TBR_KIND_SPLIT` (a button with a chevron that opens a menu), `TBR_KIND_DROPDOWN` (the whole button opens a menu), `TBR_KIND_SEPARATOR`, and `TBR_KIND_CONTROL`, which hosts another widget such as a search box. An item shows a glyph from the icon font, an image file, a caption, or an icon with a caption.

Items run from the left, or with `TBR_GRAVITY_RIGHT` hug the right edge. When the bar is too narrow, items move into an overflow menu behind a chevron: the left run's tail goes first, then the front of the right run; CONTROL items never overflow and are hidden instead.

A click reports the item's index and id through the Click callback; a toggle's change goes to the SelChange callback. The menus of split and dropdown items are [tkPopupMenu](tkPopupMenu) menus, and the DropDown callback fires as one opens, so you can fill it just in time. A paint callback draws each item yourself; `tkToolbar_PaintItemDefault( p )` in it draws the stock item first. Setters are silent.

## Importing

```freebasic
#import "vendor/tkControls/tkToolbar"
using tkToolbar
using tkPopupMenu
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkImage](tkImage) and [tkPopupMenu](tkPopupMenu). Import the module of any widget you place in a CONTROL item.

## Example

`gHost` is the window ([tkHost](tkHost)); `gFont10` and `gGlyph12` are fonts opened with `tkHost_OpenFont`, the second from `tkHost_FontDir() & TK_FONT_ICONS`.

```freebasic
const as long IDM_SAVE = 1, IDM_RUN = 2, IDM_RUN_DEBUG = 3, IDM_WRAP = 4

sub OnClick( byval h as TK_WIDGET ptr, byval idx as long, byval id as long )
    print "command "; id
end sub

sub OnDrop( byval h as TK_WIDGET ptr, byval idx as long, byval m as TK_MENU ptr, byval isOpen as boolean )
    if (isOpen = false) orelse (idx = -1) then exit sub        ' -1: the overflow menu
    if tkToolbar_GetItemID( h, idx ) = IDM_RUN then
        tkPopupMenu_Clear( m )
        tkPopupMenu_AddItem( m, IDM_RUN_DEBUG, "Run in Debugger", "F5" )
    end if
end sub

dim as TK_WIDGET ptr t = tkToolbar_Create( tkHost_Root( gHost ), 100 )
tkToolbar_SetTextFont( t, gFont10 )
tkToolbar_SetGlyphFont( t, gGlyph12 )
tkToolbar_SetClickCallback( t, @OnClick )
tkToolbar_SetDropDownCallback( t, @OnDrop )

tkToolbar_AddItem( t, TBR_KIND_COMMAND, wchr( TK_ICON_SAVE ), "Save", IDM_SAVE )
tkToolbar_AddSeparator( t )
dim as long idx = tkToolbar_AddItem( t, TBR_KIND_SPLIT, wchr( TK_ICON_PLAY ), "Run", IDM_RUN )
tkToolbar_SetTooltipText( t, idx, "Run (click the chevron for options)" )
idx = tkToolbar_AddItem( t, TBR_KIND_TOGGLE, wchr( TK_ICON_WRAP ), "Wrap", IDM_WRAP )
tkToolbar_SetItemGravity( t, idx, TBR_GRAVITY_RIGHT )

dim as long iw, ih
tkToolbar_GetIdealSize( t, iw, ih )
tkWidget_SetPos( t, 0, 0, 640, ih )
```

A command chosen from an item's menu goes to that menu's own Select callback: set it with `tkPopupMenu_SetSelectCallback( tkToolbar_GetItemMenu( t, idx ), ... )`. The toolchain's `examples/tkControls/tkToolbar/` has every kind, an image icon, a radio group, a CONTROL item and a custom painter.

## CONTROL items

Create the widget **as a child of the toolbar**, then hand it over with `tkToolbar_AddControl( t, child, width, height, id )`. The toolbar positions it, shows it and hides it when there is no room; `tkToolbar_DeleteItem` and `tkToolbar_Clear` hide and forget it but do not destroy it, and it is destroyed with the toolbar. The child reports through its own callbacks. Tab walks into CONTROL children like any other widget.

## Concepts

### The bar is one widget

`tkToolbar_Create( parent, id )` creates the bar as a child of a `TK_WIDGET ptr` (for a window's
top level pass `tkHost_Root( h )`). It is created zero-sized, never takes focus and is never a tab
stop: read `tkToolbar_GetIdealSize` and place it with `tkWidget_SetPos`, as in the example.

### Item kinds

| Kind | Behaviour |
|---|---|
| `TBR_KIND_COMMAND` | Momentary. Draws pressed while held; the Click callback fires on a matched release. |
| `TBR_KIND_TOGGLE` | Latches; the SelChange callback fires. With a group id it is a radio button. |
| `TBR_KIND_SEPARATOR` | A vertical rule. Never hit. |
| `TBR_KIND_SPLIT` | Two zones: an action zone that behaves like a command, and a chevron zone that opens the item's menu. |
| `TBR_KIND_DROPDOWN` | The whole cell opens the item's menu. |
| `TBR_KIND_CONTROL` | A cell of declared width holding a child widget (see *CONTROL items* above). |

### Geometry is derived, never set

You supply paddings, an icon size, a text gap and per-item overrides; the bar computes every rect.
Layout is lazy: a burst of `tkToolbar_AddItem` calls costs one pass, and every geometry query
forces a pending one.

```
cellWidth = padBefore + content + padAfter

content   = iconWidth                                      icon only
          = textWidth                                      caption only
          = iconWidth + textGap + textWidth                both
          = separatorWidth                                 SEPARATOR
          = controlWidth                                   CONTROL
          + chevronGap + dividerThickness + chevronWidth   SPLIT   (gap and divider only after content)
          + chevronGap +                    chevronWidth   DROPDOWN (gap only after content)

idealHeight = padTop + max( textHeight, iconHeight, controlHeight ) + padBottom
```

A gap is charged only when there is something on both sides of it, so icon-only, caption-only and
icon-plus-caption items all come from one formula. `tkToolbar_ComputeCellWidth` is that formula
as a pure function. `tkToolbar_GetIdealSize` / `GetIdealWidth` give the width the whole run wants
and the height the tallest content needs, and are valid before the bar has a size.

### Gravity and overflow

Left-gravity items pack from the left edge in the order you added them. Right-gravity items pack
against the right edge, also in order, so the last one sits hard against the edge. The overflow
chevron appears just inboard of the right run, so it never displaces a pinned right-hand item.

When the run does not fit, items move into the overflow menu from the **tail of the left run**
(its last item first), then from the **front of the right run**, so the outermost right-hand items
survive longest. CONTROL cells never move into the menu; one that cannot be placed is hidden.
`tkToolbar_ComputeOverflowSplit` is that decision as a pure function. A separator left leading or
trailing a run is suppressed, but the width it frees is not given back.

`tkToolbar_IsItemOverflowed` and `tkToolbar_GetOverflowCount` report the split;
`tkToolbar_GetOverflowRect` returns the overflow button's cell, or FALSE when nothing overflows.
The item rect queries return an empty rect for a hidden, overflowed or suppressed item.

### Two fonts

The **text font** (`tkToolbar_SetTextFont`) is a layout input: changing it re-measures every
caption, and it is passed on to the menus the bar owns. Without one, the host's default font
measures and paints. The **glyph font** (`tkToolbar_SetGlyphFont`) is paint-time only: the icon
cell is a size you declare, never measured, so a glyph too large for its cell clips. Both are
borrowed. The built-in painter draws captions in the text font and ellipsises them if the cell
is short.

### An icon is a glyph or an image

An item's icon cell holds either a glyph or an image loaded from a file, never both.
`tkToolbar_SetItemImage( t, idx, path )` loads any image [tkImage](tkImage) can read and clears
the glyph on success; `""` removes the image. It returns FALSE only for a bad index or a file
that will not decode. The image is fitted into the same icon cell a glyph would use, aspect
preserved, so switching costs no layout change. An item with neither charges no icon cell. The
bar owns every image it loaded and frees it on delete, clear and destroy. The chevron and the
overflow button are always glyphs (`TK_ICON_CHEVRON_DOWN` and `TK_ICON_MORE` by default;
`tkToolbar_SetGlyphs` changes both).

### Programmatic setters are silent

`tkToolbar_SetSelected` changes a toggle without the SelChange callback (it still enforces the
item's radio group). Only user interaction notifies. The two exceptions are actions, not setters:
`tkToolbar_Click` activates an item as a click would (fires Click, toggles, or opens a dropdown,
by kind; refused for invalid, disabled, separator and CONTROL items) and `tkToolbar_Toggle` flips
an enabled toggle and fires SelChange. They are how an accelerator drives the bar.

### Radio groups

Give two or more toggles the same non-zero group id (`tkToolbar_SetItemGroupID`) and checking
one unchecks the others. Both edges are reported, **loser first**, and every state write lands
before any callback, so a handler that reads the group sees a coherent one. Clicking the member
already checked does nothing. Joining a group while checked enforces it at once, silently.
`tkToolbar_FindCheckedInGroup` returns the checked member or -1. "Nothing checked" can be set
but not reached by the user.

### The press, the release and the menus

An action zone (a command, a toggle, a split button's main part) takes the mouse capture on the
press and acts on a **matched** release: same item, same zone. Press, slide off, release: nothing
happens. A menu zone (a dropdown, a split button's chevron, the overflow button) opens its menu on
the **press** and takes no capture. A split button's chevron zone owns the trailing padding, so a
click near its right edge opens the menu. Pressing the zone whose menu is open closes it rather
than reopening it; pressing another item closes the menu and presses that item.

There is no double-click handling: a toggle clicked twice quickly toggles twice. Disabled items
do not go hot and swallow clicks; disabling the item under a live press cancels it. Disabling the
whole bar cancels any press and clears hover.

### Menus are owned by the bar, filled by you

`tkToolbar_GetItemMenu( t, idx )` creates the item's [tkPopupMenu](tkPopupMenu) on first call
and returns it after. Fill it like any popup menu and handle its commands with
`tkPopupMenu_SetSelectCallback`; the bar wires its own select and closed callbacks in front of
yours when it opens the menu and still runs yours. The bar destroys every menu it created.

The **overflow** menu (`tkToolbar_GetOverflowMenu`, for theming only) is rebuilt on every open
from the items that did not fit: a row per item, captioned by its text, else its tooltip, else
`#n`; separators only between rows; disabled and checked states carried over. Its row ids are
item index + 1. Picking a row activates that item exactly as a strip click would, so the Click
callback need not know which happened; a dropdown picked from it opens anchored at the overflow
button.

Every menu the bar creates is themed from the bar's colours and re-themed when they change.
`tkToolbar_SetMenuColors` claims the palette of every owned menu, present and future (and pins
the bar's colours). Only one menu chain is open at a time: opening a dropdown closes any other,
and the closed one reports its closing edge. `tkToolbar_IsDroppedDown`,
`tkToolbar_GetDroppedItem` (-1 for the overflow menu or for nothing), `tkToolbar_DropDown( t, idx )`
(-1 for the overflow menu) and `tkToolbar_CloseUp` query and drive them.

### Tooltips

An item's own text (`tkToolbar_SetTooltipText`) wins; otherwise the tooltip callback is asked;
otherwise there is no tip. There is no fallback to the caption, so give icon-only items a tip.
`tkToolbar_SetHoverTime`, `SetAutoPopTime` and `SetReshowTime` set the delays;
`tkToolbar_GetTooltipHandle` returns the `TK_TIP ptr` for any [tkTooltip](tkTooltip) call. A press
hides a visible tip.

### Pixels and scale

The defaults (`TKTOOLBAR_DEFAULT_*`) are scaled at create, except the split divider's thickness.
Every setter afterwards takes pixels; scale your literals with `tkHost_Scale`. Setters ignore
values that make no sense: `SetIconSize` ignores values of 0 or less, `SetPadding` ignores
negatives (so one can be set and -1 passed for the rest). Per-item overrides go back to inheriting
with -1 (`SetItemPadding`) or 0 (`SetItemIconSize`). When the host's scale changes, the bar
rescales every size and override except the divider thickness. Until you call
`tkToolbar_SetCornerCurvature`, the rounding of the state fill follows the theme's shape.

## Behaviour and limits

- **Horizontal only.**
- **No focus and no keyboard.** Reach commands from the keyboard through your own accelerators and
  `tkToolbar_Click`.
- **The overflow menu does not scroll.** This is for a dozen or so items in a narrow bar.
- **A separator never hits**, and a hidden item (`tkToolbar_SetVisible`) leaves layout, hit-testing
  and the overflow entirely, hiding a CONTROL item's child with it.
- **`tkToolbar_HitTest` / `HitTestEx`** exclude separators, hidden and overflowed items but not
  disabled ones; `HitTestEx` also reports the zone, and returns -1 with `TBR_ZONE_OVERFLOW` over the
  overflow button.
- **Indices move.** The bar fixes up its own stored indices across an insert or delete; fix up any
  you hold. `tkToolbar_InsertItem` takes `idx = count` to append and returns -1 past the end.

## Colours

`TKTOOLBAR_COLORS` holds nine colours. The bar takes them from the current theme when it is
created (including any theme recipe for `"Toolbar"`) and follows every theme change, re-theming
its menus too. `tkToolbar_SetColors` copies a struct and pins it; `tkToolbar_UnpinColors` hands the
bar back to the theme and applies it at once.

| Field | Paints | When | Theme role |
|---|---|---|---|
| `BackColor` | The bar, and every cell's base fill | Always | `Window` |
| `ForeColor` | Glyph and caption | Idle | `Text` |
| `BackColorHot` | The state fill | Pointer over the item, or its menu open | `SurfaceHot` |
| `ForeColorHot` | Glyph and caption | Pointer over the item, or its menu open | `TextHot` |
| `BackColorSelect` | The state fill | Latched toggle, and pressed | `Selected` |
| `ForeColorSelect` | Glyph and caption | Latched toggle, and pressed | `SelectedText` |
| `ForeColorDisabled` | Glyph and caption | Disabled | `TextDisabled` |
| `SeparatorColor` | A separator's rule | Always | `Divider` |
| `SplitDividerColor` | The hairline between a split button's zones | Always | `Divider` |

The mood, resolved by `tkToolbar_ResolveMood` so a custom painter can agree with the bar, is:

```
disabled > pressed > hot > idle
```

A latched toggle is not a mood: the painter combines it, so a selected idle item takes the Select
pair and a selected disabled item keeps the Select fill under the disabled foreground. Pressed
reuses the Select pair. `tkToolbar_SetItemForeColor` overrides one item's **idle** foreground
only; `ClearItemForeColor` removes it.

The state fill is a rounded rect (`tkToolbar_SetCornerCurvature`, 0 for square) drawn over the
base fill, so the bar shows between cells and an item reads as a pill. On a split button, hover and
press light only the half under the pointer.

## Callbacks

All are optional; passing 0 removes one.

### Paint

```freebasic
type TBR_PaintItemCallbackSub as sub( byval p as TKTOOLBAR_PAINTINFO ptr )
```

Replaces the built-in painter for **every** item, separators and the overflow button included;
the overflow button arrives with `itemID = -1` and `itemKind = TBR_KIND_DROPDOWN`.
`tkToolbar_PaintItemDefault( p )` draws the stock item first. Fill `p->rc`, which includes the
padding; draw captions in the text font the bar measured with; when `p->pImage` is set, draw it
with `tkImage_Paint` instead of the glyph. `tkToolbar_CountRenderedTones` and
`tkToolbar_HashRenderedPart` render the bar through the real paint path and read back one
`TBR_PART_*` rect, so you can check a painter: a low tone count means it floods the cell, and equal
hashes across a state change mean the change never reached the pixels.

| Field | Meaning |
|---|---|
| `hToolbar` | The bar |
| `itemID` | Model index; -1 for the overflow button |
| `b` | The paint context for this repaint |
| `itemKind` | `TBR_KIND_*` |
| `rc` | The whole cell: fill this |
| `rcIcon` | The icon box, or a separator's rule |
| `rcText` | The caption span |
| `rcChevron` | The chevron box; empty except on split and dropdown items |
| `nMood` | `TBR_MOOD_*` |
| `isHot` | The pointer is over this item |
| `isSelected` | A latched toggle |
| `isPressed` | A live press is on this item **and** the pointer is still over it |
| `isEnabled` | The item's enabled state |
| `isChevronHot` | The pointer is over a split button's chevron zone |
| `isDropped` | This item's menu is open |
| `wszGlyph`, `wszText` | The glyph and the caption |
| `pImage` | The item's image, or 0 |

### Message

```freebasic
type TBR_MessageCallbackFunc as function( byval m as TKTOOLBAR_MESSAGEINFO ptr ) as boolean
```

Observes `TKM_MOUSEMOVE`, `TKM_MOUSELEAVE`, `TKM_LBUTTONDOWN`, `TKM_LBUTTONUP`, `TKM_RBUTTONDOWN`
and `TKM_RBUTTONUP`. `TKTOOLBAR_MESSAGEINFO` carries `hToolbar`, `msg`, widget-local `x` / `y`,
`idx` (the item under the mouse, or -1) and `nZone`. Returning TRUE for `TKM_LBUTTONDOWN`
suppresses the press and any menu opening; the result is **ignored** for `TKM_LBUTTONUP`, which
ends the press and releases the capture. The other messages are reported after the bar's own
handling. The right button is reported, never acted on.

### Tooltip

```freebasic
type TBR_TooltipCallbackFunc as function( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as ustring
```

Asked only when the item has no tooltip text of its own, and only when a tip is about to show.
Return `""` for none.

### Click

```freebasic
type TBR_ClickCallbackSub as sub( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval id as long )
```

A matched press and release on a command item or a split button's action zone, a pick from the
overflow menu, or `tkToolbar_Click`. Toggles report through SelChange instead.

### Selection change

```freebasic
type TBR_SelChangeCallbackSub as sub( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval isSelected as boolean )
```

A toggle latched or unlatched by the user (or `tkToolbar_Toggle`), after the state is updated. For a
radio group both edges fire, loser first. `tkToolbar_SetSelected` never fires it.

### Drop down

```freebasic
type TBR_DropDownCallbackSub as sub( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval hMenu as TK_MENU ptr, byval isOpen as boolean )
```

A menu opened (`isOpen` TRUE) or closed; `idx` is -1 for the overflow menu. It reports the menu's
state, so it fires for `tkToolbar_DropDown` too. For a split or dropdown item the opening edge runs
**before** any row is shown, which is the just-in-time hook used in the example; the overflow
menu's opening edge runs after the bar has built it. A menu left empty after the opening edge does
not open, and reports a balanced open and close.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKTOOLBAR_DEFAULT_ICONWIDTH = 16
const TKTOOLBAR_DEFAULT_ICONHEIGHT = 16
const TKTOOLBAR_DEFAULT_PADBEFORE = 6
const TKTOOLBAR_DEFAULT_PADAFTER = 6
const TKTOOLBAR_DEFAULT_PADTOP = 4
const TKTOOLBAR_DEFAULT_PADBOTTOM = 4
const TKTOOLBAR_DEFAULT_TEXTGAP = 6
const TKTOOLBAR_DEFAULT_SEPWIDTH = 1
const TKTOOLBAR_DEFAULT_CHEVRONWIDTH = 14
const TKTOOLBAR_DEFAULT_CHEVRONGAP = 4
const TKTOOLBAR_DEFAULT_DIVIDERTHICK = 1 ' NOT scaled: a hairline stays a hairline
const TKTOOLBAR_DEFAULT_CURVATURE = 4

enum
    TBR_KIND_COMMAND = 0
    TBR_KIND_TOGGLE
    TBR_KIND_SEPARATOR
    TBR_KIND_SPLIT
    TBR_KIND_DROPDOWN
    TBR_KIND_CONTROL
end enum

enum
    TBR_GRAVITY_LEFT = 0
    TBR_GRAVITY_RIGHT
end enum

enum
    TBR_ZONE_NONE = 0
    TBR_ZONE_ACTION
    TBR_ZONE_CHEVRON
    TBR_ZONE_OVERFLOW
end enum

enum
    TBR_PART_TOOLBAR = 0
    TBR_PART_ITEM
    TBR_PART_ICON
    TBR_PART_TEXT
    TBR_PART_CHEVRON
end enum

enum
    TBR_MOOD_IDLE = 0
    TBR_MOOD_HOT
    TBR_MOOD_PRESSED
    TBR_MOOD_DISABLED
end enum
```

### Types

```freebasic
type TKTOOLBAR_COLORS
    BackColor         as ulong = &hFF21252Bul    ' ( 33, 37, 43)
    ForeColor         as ulong = &hFFD7DAE0ul    ' (215,218,224)
    BackColorHot      as ulong = &hFF2C313Aul    ' ( 44, 49, 58)
    ForeColorHot      as ulong = &hFFFFFFFFul
    BackColorSelect   as ulong = &hFF264F78ul    ' ( 38, 79,120)
    ForeColorSelect   as ulong = &hFFFFFFFFul
    ForeColorDisabled as ulong = &hFF6E737Dul    ' (110,115,125)
    SeparatorColor    as ulong = &hFF464C58ul    ' ( 70, 76, 88)
    SplitDividerColor as ulong = &hFF464C58ul
end type

type TKTOOLBAR_ITEM
    itemKind       as long = TBR_KIND_COMMAND
    wszGlyph       as ustring
    pImage         as tkImageFile ptr       ' OWNED; glyph OR image
    wszText        as ustring
    wszTooltip     as ustring
    id             as long
    itemData       as integer
    isSelected     as boolean
    isEnabled      as boolean = true
    isVisible      as boolean = true
    nGroupID       as long
    nGravity       as long = TBR_GRAVITY_LEFT
    hMenu          as TK_MENU ptr           ' OWNED, created on demand
    prevSelect     as PM_SelectCallbackSub  ' the menu's own callbacks, chained behind ours
    prevClosed     as PM_ClosedCallbackSub
    hChild         as TK_WIDGET ptr         ' CONTROL: the host's widget, a child of the toolbar
    nControlWidth  as long
    nControlHeight as long
    nPadBefore     as long = -1
    nPadAfter      as long = -1
    nIconWidth     as long = 0
    nIconHeight    as long = 0
    ForeColorItem  as ulong
    bHasForeColor  as boolean
    nTextWidth     as long
    nCellWidth     as long
    bOverflowed    as boolean
    bTrimmed       as boolean
    rc             as TKRECT
    rcIcon         as TKRECT
    rcText         as TKRECT               ' the caption SPAN, not the ink
    rcChevron      as TKRECT
end type

type TKTOOLBAR_PAINTINFO
    hToolbar     as TK_WIDGET ptr
    itemID       as long                   ' -1 = the overflow button
    b            as TK_PAINT ptr
    itemKind     as long
    rc           as TKRECT
    rcIcon       as TKRECT
    rcText       as TKRECT
    rcChevron    as TKRECT
    nMood        as long
    isHot        as boolean
    isSelected   as boolean
    isPressed    as boolean
    isEnabled    as boolean
    isChevronHot as boolean
    isDropped    as boolean
    wszGlyph     as ustring
    wszText      as ustring
    pImage       as tkImageFile ptr        ' draw with tkImage_Paint INSTEAD OF the glyph
end type

type TKTOOLBAR_MESSAGEINFO
    hToolbar as TK_WIDGET ptr
    msg      as long                       ' TKM_*
    x        as single
    y        as single
    idx      as long
    nZone    as long
end type

type TKTOOLBAR_STATE   ' per-instance state; reach it through the procedures

type TBR_PaintItemCallbackSub as sub( byval p as TKTOOLBAR_PAINTINFO ptr )
type TBR_MessageCallbackFunc as function( byval m as TKTOOLBAR_MESSAGEINFO ptr ) as boolean
type TBR_TooltipCallbackFunc as function( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as ustring
type TBR_ClickCallbackSub as sub( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval id as long )
type TBR_SelChangeCallbackSub as sub( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval isSelected as boolean )
type TBR_DropDownCallbackSub as sub( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval hMenu as TK_MENU ptr, byval isOpen as boolean )
```

### Procedures

```freebasic
function tkToolbar_ComputeCellWidth( byval nKind as long, byval nIconWidth as long, byval nTextWidth as long, byval nTextGap as long, byval nSepWidth as long, byval nControlWidth as long, byval nChevronWidth as long, byval nChevronGap as long, byval nDividerThick as long, byval nPadBefore as long, byval nPadAfter as long ) as long
sub tkToolbar_ComputeOverflowSplit( nCellW() as long, nGravity() as long, nKind() as long, byval nCount as long, byval nClientW as long, byval nOverflowCellW as long, bOverflow() as boolean, byref bNeedOverflow as boolean )
function tkToolbar_ResolveMood( byval isEnabled as boolean, byval isPressed as boolean, byval isHot as boolean ) as long
function tkToolbar_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkToolbar_AddItem( byval hToolbar as TK_WIDGET ptr, byval itemKind as long, byval Glyph as ustring, byval Text as ustring = "", byval id as long = 0, byval itemData as integer = 0 ) as long
function tkToolbar_InsertItem( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval itemKind as long, byval Glyph as ustring, byval Text as ustring = "", byval id as long = 0, byval itemData as integer = 0 ) as long
function tkToolbar_AddSeparator( byval hToolbar as TK_WIDGET ptr ) as long
function tkToolbar_AddControl( byval hToolbar as TK_WIDGET ptr, byval hChild as TK_WIDGET ptr, byval nControlWidth as long, byval nControlHeight as long = 0, byval id as long = 0 ) as long
function tkToolbar_DeleteItem( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkToolbar_Clear( byval hToolbar as TK_WIDGET ptr )
sub tkToolbar_Refresh( byval hToolbar as TK_WIDGET ptr )
function tkToolbar_GetCount( byval hToolbar as TK_WIDGET ptr ) as long
function tkToolbar_IsValidItem( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkToolbar_FindItemByID( byval hToolbar as TK_WIDGET ptr, byval id as long ) as long
function tkToolbar_HitTestEx( byval hToolbar as TK_WIDGET ptr, byval x as long, byval y as long, byref nZone as long ) as long
function tkToolbar_HitTest( byval hToolbar as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkToolbar_GetItemKind( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as long
function tkToolbar_GetGlyph( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkToolbar_SetGlyph( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval Glyph as ustring ) as boolean
function tkToolbar_SetItemImage( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval Path as ustring ) as boolean
function tkToolbar_GetText( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkToolbar_SetText( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkToolbar_GetItemID( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as long
function tkToolbar_SetItemID( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval id as long ) as boolean
function tkToolbar_GetItemData( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as integer
function tkToolbar_SetItemData( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval itemData as integer ) as boolean
function tkToolbar_GetSelected( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkToolbar_SetSelected( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval isSelected as boolean ) as boolean
function tkToolbar_GetEnabled( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkToolbar_SetEnabled( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval isEnabled as boolean ) as boolean
function tkToolbar_GetVisible( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkToolbar_SetVisible( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval isVisible as boolean ) as boolean
function tkToolbar_GetItemGroupID( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as long
function tkToolbar_SetItemGroupID( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval nGroupID as long ) as boolean
function tkToolbar_FindCheckedInGroup( byval hToolbar as TK_WIDGET ptr, byval nGroupID as long ) as long
function tkToolbar_GetItemGravity( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as long
function tkToolbar_SetItemGravity( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval nGravity as long ) as boolean
function tkToolbar_GetItemChild( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as TK_WIDGET ptr
function tkToolbar_FindItemByChild( byval hToolbar as TK_WIDGET ptr, byval hChild as TK_WIDGET ptr ) as long
function tkToolbar_Click( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkToolbar_Toggle( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkToolbar_GetIconSize( byval hToolbar as TK_WIDGET ptr, byref nIconWidth as long, byref nIconHeight as long )
sub tkToolbar_SetIconSize( byval hToolbar as TK_WIDGET ptr, byval nIconWidth as long, byval nIconHeight as long )
sub tkToolbar_GetPadding( byval hToolbar as TK_WIDGET ptr, byref nPadBefore as long, byref nPadAfter as long, byref nPadTop as long, byref nPadBottom as long )
sub tkToolbar_SetPadding( byval hToolbar as TK_WIDGET ptr, byval nPadBefore as long, byval nPadAfter as long, byval nPadTop as long, byval nPadBottom as long )
function tkToolbar_GetTextGap( byval hToolbar as TK_WIDGET ptr ) as long
sub tkToolbar_SetTextGap( byval hToolbar as TK_WIDGET ptr, byval nTextGap as long )
function tkToolbar_GetSeparatorWidth( byval hToolbar as TK_WIDGET ptr ) as long
sub tkToolbar_SetSeparatorWidth( byval hToolbar as TK_WIDGET ptr, byval nSepWidth as long )
function tkToolbar_GetSeparatorHeight( byval hToolbar as TK_WIDGET ptr ) as long
sub tkToolbar_SetSeparatorHeight( byval hToolbar as TK_WIDGET ptr, byval nSepHeight as long )
sub tkToolbar_GetChevronSize( byval hToolbar as TK_WIDGET ptr, byref nChevronWidth as long, byref nChevronGap as long )
sub tkToolbar_SetChevronSize( byval hToolbar as TK_WIDGET ptr, byval nChevronWidth as long, byval nChevronGap as long )
function tkToolbar_GetDividerThickness( byval hToolbar as TK_WIDGET ptr ) as long
sub tkToolbar_SetDividerThickness( byval hToolbar as TK_WIDGET ptr, byval nThickness as long )
function tkToolbar_GetCornerCurvature( byval hToolbar as TK_WIDGET ptr ) as long
sub tkToolbar_SetCornerCurvature( byval hToolbar as TK_WIDGET ptr, byval nCurvature as long )
function tkToolbar_SetItemPadding( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval nPadBefore as long, byval nPadAfter as long ) as boolean
function tkToolbar_SetItemIconSize( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval nIconWidth as long, byval nIconHeight as long ) as boolean
function tkToolbar_SetItemControlSize( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval nControlWidth as long, byval nControlHeight as long ) as boolean
function tkToolbar_GetItemRect( byval hToolbar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkToolbar_GetItemIconRect( byval hToolbar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkToolbar_GetItemTextRect( byval hToolbar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkToolbar_GetItemChevronRect( byval hToolbar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkToolbar_GetOverflowRect( byval hToolbar as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkToolbar_GetIdealSize( byval hToolbar as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkToolbar_GetIdealWidth( byval hToolbar as TK_WIDGET ptr ) as long
function tkToolbar_IsItemOverflowed( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkToolbar_GetOverflowCount( byval hToolbar as TK_WIDGET ptr ) as long
sub tkToolbar_GetColors( byval hToolbar as TK_WIDGET ptr, byval pColors as TKTOOLBAR_COLORS ptr )
sub tkToolbar_SetColors( byval hToolbar as TK_WIDGET ptr, byval pColors as TKTOOLBAR_COLORS ptr )
function tkToolbar_ThemeColors( byref t as TKTHEME_COLORS ) as TKTOOLBAR_COLORS
sub tkToolbar_ApplyTheme( byval hToolbar as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkToolbar_UnpinColors( byval hToolbar as TK_WIDGET ptr )
function tkToolbar_SetItemForeColor( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval clr as ulong ) as boolean
function tkToolbar_ClearItemForeColor( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkToolbar_GetTextFont( byval hToolbar as TK_WIDGET ptr ) as TTF_Font ptr
function tkToolbar_SetTextFont( byval hToolbar as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
function tkToolbar_GetGlyphFont( byval hToolbar as TK_WIDGET ptr ) as TTF_Font ptr
function tkToolbar_SetGlyphFont( byval hToolbar as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
sub tkToolbar_ApplyFonts( byval hToolbar as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkToolbar_GetGlyphs( byval hToolbar as TK_WIDGET ptr, byref wszChevron as ustring, byref wszOverflow as ustring )
sub tkToolbar_SetGlyphs( byval hToolbar as TK_WIDGET ptr, byval wszChevron as ustring, byval wszOverflow as ustring )
function tkToolbar_GetItemMenu( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as TK_MENU ptr
function tkToolbar_GetOverflowMenu( byval hToolbar as TK_WIDGET ptr ) as TK_MENU ptr
sub tkToolbar_SetMenuColors( byval hToolbar as TK_WIDGET ptr, byval pColors as TKPOPUPMENU_COLORS ptr )
function tkToolbar_IsDroppedDown( byval hToolbar as TK_WIDGET ptr ) as boolean
function tkToolbar_GetDroppedItem( byval hToolbar as TK_WIDGET ptr ) as long
function tkToolbar_DropDown( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkToolbar_CloseUp( byval hToolbar as TK_WIDGET ptr )
function tkToolbar_GetTooltipText( byval hToolbar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkToolbar_SetTooltipText( byval hToolbar as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkToolbar_GetTooltipHandle( byval hToolbar as TK_WIDGET ptr ) as TK_TIP ptr
sub tkToolbar_SetHoverTime( byval hToolbar as TK_WIDGET ptr, byval milliseconds as long )
sub tkToolbar_SetAutoPopTime( byval hToolbar as TK_WIDGET ptr, byval milliseconds as long )
sub tkToolbar_SetReshowTime( byval hToolbar as TK_WIDGET ptr, byval milliseconds as long )
function tkToolbar_GetHotItem( byval hToolbar as TK_WIDGET ptr, byref nZone as long ) as long
function tkToolbar_GetPressedItem( byval hToolbar as TK_WIDGET ptr ) as long
sub tkToolbar_PaintItemDefault( byval p as TKTOOLBAR_PAINTINFO ptr )
sub tkToolbar_SetPaintItemCallback( byval hToolbar as TK_WIDGET ptr, byval usersub as TBR_PaintItemCallbackSub )
sub tkToolbar_SetMessageCallback( byval hToolbar as TK_WIDGET ptr, byval userfunc as TBR_MessageCallbackFunc )
sub tkToolbar_SetTooltipCallback( byval hToolbar as TK_WIDGET ptr, byval userfunc as TBR_TooltipCallbackFunc )
sub tkToolbar_SetClickCallback( byval hToolbar as TK_WIDGET ptr, byval usersub as TBR_ClickCallbackSub )
sub tkToolbar_SetSelChangeCallback( byval hToolbar as TK_WIDGET ptr, byval usersub as TBR_SelChangeCallbackSub )
sub tkToolbar_SetDropDownCallback( byval hToolbar as TK_WIDGET ptr, byval usersub as TBR_DropDownCallbackSub )
function tkToolbar_CountRenderedTones( byval hToolbar as TK_WIDGET ptr, byval nPart as long, byval idx as long ) as long
function tkToolbar_HashRenderedPart( byval hToolbar as TK_WIDGET ptr, byval nPart as long, byval idx as long ) as ulong
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme), [tkPopupMenu](tkPopupMenu), [tkTooltip](tkTooltip), [tkImage](tkImage)
