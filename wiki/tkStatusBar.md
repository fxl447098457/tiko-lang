[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkStatusBar**

# tkStatusBar

Draws a status bar of text panels, one of which stretches to fill the leftover width.

tkStatusBar is the strip along the bottom of a window: "Ready", the caret position, the line ending, the encoding. Each panel holds text and item data, and is as wide as its text plus padding, or its minimum width if that is larger. A panel set to stretch with `tkStatusBar_SetPanelStretch` is a **spring**: the springs share the leftover width evenly (the first ones take a pixel each of any remainder), and a hidden spring takes none. `tkStatusBar_SetExpandPanel( sb, i )` makes panel `i` the only spring (`-1`: none), and `tkStatusBar_GetExpandPanel` answers the first one. When the bar is too narrow nothing shrinks; panels run past the right edge.

Without a paint callback the bar draws its panels itself: the text inset by the padding and a divider between panels. Set a click callback and a panel under the mouse gets a hover fill, since it can now be clicked. A paint callback replaces the built-in painter and draws every panel pixel itself; `tkStatusBar_PaintPanelDefault( p )` in it draws the built-in panel first.

The bar takes no focus and no keyboard, and has no size grip; your program places it, usually from the window's size handler. Each panel can show a tooltip, from the tooltip callback or else its own text. Setters are silent.

## Importing

```freebasic
#import "vendor/tkControls/tkStatusBar"
using tkStatusBar
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` to write a paint callback.

## Example

`gHost` is the window ([tkHost](tkHost)); `gFont10` is a font opened with `tkHost_OpenFont`.

```freebasic
sub OnClick( byval hBar as TK_WIDGET ptr, byval idx as long, byval clicks as long )
    print "clicked "; tkStatusBar_GetText( hBar, idx ); " (clicks="; clicks; ")"
end sub

dim as TK_WIDGET ptr sb = tkStatusBar_Create( tkHost_Root( gHost ), 1 )
tkStatusBar_SetFont( sb, gFont10 )
tkStatusBar_SetClickCallback( sb, @OnClick )
tkStatusBar_AddPanel( sb, "Ready", 1001 )
tkStatusBar_AddPanel( sb, "", 1002 )                     ' the spring
tkStatusBar_AddPanel( sb, "Ln 1, Col 1", 1003 )
tkStatusBar_AddPanel( sb, "UTF-8", 1004 )
tkStatusBar_SetExpandPanel( sb, 1 )
tkStatusBar_SetPanelMinWidth( sb, 2, tkHost_Scale( gHost, 110 ) )

' in the window's size handler, with pw x ph the window's pixel size:
tkWidget_SetPos( sb, 0, ph - tkHost_Scale( gHost, 24 ), pw, tkHost_Scale( gHost, 24 ) )

' later, silently:
tkStatusBar_SetText( sb, 2, "Ln 12, Col 5" )
```

`tkStatusBar_SetPanelVisible( sb, idx, false )` hides a panel without renumbering the others: it keeps its index and takes no width. The toolchain's `examples/tkControls/tkStatusBar/` shows two bars with custom painters and one with the built-in painter and a click callback.

## Concepts

### A panel is a rectangle, not a widget

The bar is one widget, created with `tkStatusBar_Create( parent, id )` (for a window's top level
pass `tkHost_Root( h )`). It is created zero-sized, so it shows nothing until your size handler
places it. Its height is yours; every panel spans the full height.

Panels live in an internal array and are named by their **model index**, `0` to
`tkStatusBar_GetCount() - 1`. They can be added, inserted, deleted and cleared at any time. Each
carries its `Text`, an `itemData` integer of your choosing (a command id, typically) and
`nMinWidth`; its rect is derived by the control and read-only to you.

**Indices move.** Insert or delete a panel and every later panel's index shifts, so an index you
stored earlier can now name a different panel. `tkStatusBar_InsertPanel` clamps its index to
`[0, count]` and returns the index it used. A spring is a flag on its panel, so it moves with the
panel; deleting a spring panel removes that spring. Every insert, delete and clear also clears
the hot panel; the next mouse move recomputes it.

### How wide a panel is

```
  panelWidth(i) = max( textWidth(i) + 2*padding, nMinWidth(i) )
```

`textWidth` is the panel's text measured with the bar's font (the host's default font if none is
set). `padding` is one value for the whole bar, charged on **both** sides; it starts at
`TKSTATUSBAR_DEFAULT_PADDING`, scaled. `nMinWidth` is a **floor, not a fixed width**: a panel
whose text is wider grows past it. Set one on a panel whose text changes length, or it resizes
and shoves its neighbours on every update.

The leftover width (`clientWidth` minus the sum of the panel widths), when positive, is shared
evenly by the visible springs. The panels are then laid left to right, each the full client
height. A hidden panel is laid out at width 0.

An 800-pixel bar, padding 8, with the panels "Ready", an empty spring, "Ln 1, Col 1" (minimum
110) and "UTF-8" might measure 56, 16, 110 and 54: a total of 236, so the spring grows by 564 and
the last two panels sit flush against the right edge through every resize. That is the whole
alignment story: a trailing right-aligned group is a spring in front of it.

**On overflow nothing shrinks.** When the leftover is zero or negative no spring grows and no
panel is squeezed; the panels run past the right edge and are clipped, and hit-testing stays
honest.

### Layout is lazy

Every mutator (text, padding, minimum width, font, visibility, springs) marks the layout stale and
repaints. The next paint, `tkStatusBar_GetPanelRect` or `tkStatusBar_HitTest` performs one
measuring pass, so a burst of `tkStatusBar_SetText` calls costs one layout. A layout attempted
before the bar has a size stays stale and retries once it is sized.

`tkStatusBar_GetItemRect` returns the last **computed** rect without forcing a pending layout, so
it can be stale between a mutator and the next paint; `tkStatusBar_GetPanelRect` is always
current.

### Hover

One panel at a time is hot: the one under the cursor. It reaches a paint callback as `isHot`, and
it is the only per-panel visual state; there is no selection and no pressed state. The host's
mouse-leave clears it, and disabling the bar (`tkWidget_Enable`) clears it and hides any tip.

### Tooltips

The bar owns one tooltip covering the whole bar. Its text is resolved on demand for the hot
panel: the tooltip callback if one is set, otherwise the panel's own `Text`; `""` shows no tip.
Moving to another panel hides a visible tip and re-resolves the text on the next dwell.
`tkStatusBar_GetTooltipHandle` returns the `TK_TIP ptr` for any [tkTooltip](tkTooltip) call; the
bar owns and destroys it.

`tkStatusBar_SetHoverTime` does double duty: it sets the tip's initial delay **and** the delay of
the `TKSB_MOUSEHOVER` message handed to the message callback (default
`TKSTATUSBAR_DEFAULT_HOVERTIME`, 250 ms). `tkStatusBar_SetAutoPopTime` and
`tkStatusBar_SetReshowTime` set how long a tip stays up and the shorter delay after one was
recently dismissed.

### Pixels and scale

`tkStatusBar_SetPadding` and `tkStatusBar_SetPanelMinWidth` take pixels; scale your literals with
`tkHost_Scale`. When the host's scale changes, the bar rescales its padding, its divider inset and
every panel's minimum width on its own.

## Behaviour and limits

- **No mouse capture.** A left-button down is not guaranteed a matching up: press inside and
  release outside, and no up arrives. Press on panel 3, drag to panel 5 and release, and panel 5
  is the one clicked.
- **No focus and no keyboard.** The bar is never a tab stop and never takes focus, so clicking it
  does not take focus from the editor.
- **No panel width setter.** A panel gets text and an optional minimum width; the bar measures it.
- **No vertical layout**, no per-panel alignment, no per-panel icons, no fixed-width panels and no
  size grip.
- **The right button is reported, never acted on.** `TKM_RBUTTONDOWN` reaches the message
  callback; its up does not.
- **`tkStatusBar_SetBackColor` does not repaint.** It stores the colour, pins the colours and
  returns the previous colour; follow it with `tkStatusBar_Refresh` on a visible bar.
- **`tkStatusBar_SetItemData` and `tkStatusBar_SetPaintCallback` do not repaint.**
- **Getters on an invalid index** return `""`, `0` or FALSE; `tkStatusBar_GetItemData`'s `0` is
  indistinguishable from real data of 0.

## Colours

`TKSTATUSBAR_COLORS` holds five colours. The bar takes them from the current theme when it is
created (including any theme recipe for `"StatusBar"`) and follows every theme change.

| Colour | Paints | Theme role |
|---|---|---|
| `BackColor` | The whole bar, filled before any panel is drawn, including any gap on the right | `Window` |
| `BackColorHot` | A hot panel's fill (built-in painter, clickable bar only) | `SurfaceHot` |
| `ForeColor` | Panel text (built-in painter) | `TextDim` |
| `ForeColorHot` | A hot panel's text (built-in painter, clickable bar only) | `TextHot` |
| `DividerColor` | The divider after every panel but the last (built-in painter) | `Divider` |

`tkStatusBar_SetColors` copies a struct and pins it, so a theme change leaves this bar alone;
`tkStatusBar_SetBackColor` pins too. `tkStatusBar_UnpinColors` hands the bar back to the theme
and applies it at once. `tkStatusBar_GetColors` reads the colours in force.

### The paint sequence

Each repaint consumes any pending layout, fills the whole bar with `BackColor`, then draws each
panel in turn (skipping hidden panels and any that start past the right edge): the paint callback
if one is set, otherwise the built-in painter. The built-in painter draws the text inset by the
padding, a 1-pixel divider after every panel but the last (inset `TKSTATUSBAR_DEFAULT_DIVIDERINSET`
from top and bottom, scaled), and, only when a click callback is set and the bar is enabled, a hot
fill and hot text on the panel under the mouse.

## Callbacks

All are optional and independent; passing 0 clears one.

### Paint

```freebasic
type SB_PaintCallbackSub as sub( byval p as TKSTATUSBAR_PAINTINFO ptr )
```

Draws **one panel**, called once per panel per repaint, so keep it cheap. It replaces the
built-in painter and owns every pixel of the panel; `tkStatusBar_PaintPanelDefault( p )` draws
the built-in panel first if you want to add to it. Paint through `p->b` and do not keep it past
the call. `BackColor` has already been filled.

| Field | Meaning |
|---|---|
| `hStatusBar` | The control, so the callback can query it, chiefly for `tkStatusBar_GetPadding` |
| `itemID` | The panel's model index |
| `b` | The paint context for this repaint (borrowed, not owned) |
| `rc` | This panel's rect, widget-local: the only rect to fill |
| `isHot` | The mouse is over this panel |
| `wszCaption` | The panel's `Text` |

Two contracts keep the drawing in step with the layout: draw with the font the bar measures with
(`tkStatusBar_SetFont`, or the host's default), and inset the text by
`tkStatusBar_GetPadding( p->hStatusBar )`, which is already part of the width. Fill `p->rc`,
never the whole bar, or you erase the panels drawn before it.

### Message

```freebasic
type SB_MessageCallbackFunc as function( byval m as TKSTATUSBAR_MESSAGEINFO ptr ) as boolean
```

Observes mouse messages. `TKSTATUSBAR_MESSAGEINFO` carries `hStatusBar`, `msg`, widget-local
`x` / `y`, `clicks`, and `idx`, the panel under the mouse or `-1` for none. Return TRUE to
suppress the control's own handling; the result is honoured for every message, since the bar
holds no capture that suppressing could strand.

| Message | Notes |
|---|---|
| `TKM_MOUSEMOVE` | Called **after** the hot panel is updated, so `idx` and the control agree |
| `TKSB_MOUSEHOVER` | Sent once per rest, after the hover time, while the mouse is still on the bar |
| `TKM_MOUSELEAVE` | `idx` is always `-1`; hover is already cleared |
| `TKM_LBUTTONDOWN` | `clicks = 2` on the second click of a double click |
| `TKM_LBUTTONUP` | Only arrives while the cursor is over the bar. Returning TRUE suppresses the click callback |
| `TKM_RBUTTONDOWN` | Reported, never acted on |

### Tooltip

```freebasic
type SB_TooltipCallbackFunc as function( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as ustring
```

Supplies the tip text for panel `idx`, called only when a tip is about to show. Return `""` for no
tip on that panel, for example over an empty spring. Without it the tip shows the panel's own text.

### Click

```freebasic
type SB_ClickCallbackSub as sub( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byval clicks as long )
```

Fired on the left-button release over a panel, with `clicks = 2` on the second click of a double
click, unless the message callback returned TRUE for that release. Setting one makes the bar
clickable, which is what turns on the built-in painter's hot fill.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKSTATUSBAR_DEFAULT_PADDING = 8
const as long TKSTATUSBAR_DEFAULT_HOVERTIME = 250
const as long TKSTATUSBAR_DEFAULT_DIVIDERINSET = 4
const as long TKSB_MOUSEHOVER = 1001
```

### Types

```freebasic
type TKSTATUSBAR_PANELINFO
    Text      as ustring
    itemData  as integer
    nMinWidth as long            ' floor for this panel's width; 0 = auto-size to the text
    bHidden   as boolean         ' laid out at width 0: not painted, no divider, never hit
    bStretch  as boolean         ' takes a share of the leftover width
    rc        as TKRECT          ' derived by LayoutPanels, read-only to the host
end type

type TKSTATUSBAR_COLORS
    BackColor    as ulong = &hFF21252Bul    ' ( 33, 37, 43) theme Window
    BackColorHot as ulong = &hFF373D48ul    ' ( 55, 61, 72) theme SurfaceHot
    ForeColor    as ulong = &hFF969CA6ul    ' (150,156,166) theme TextDim
    ForeColorHot as ulong = &hFFE2E6EEul    ' (226,230,238) theme TextHot
    DividerColor as ulong = &hFF373C45ul    ' ( 55, 60, 69) theme Divider
end type

type TKSTATUSBAR_PAINTINFO
    hStatusBar as TK_WIDGET ptr      ' the control, so the callback can ask for GetPadding
    itemID     as long               ' the panel's model index
    b          as TK_PAINT ptr       ' this repaint's painter (borrowed)
    rc         as TKRECT             ' this panel's rect, widget-local -- the only rect to fill
    isHot      as boolean            ' the mouse is over this panel
    wszCaption as ustring            ' the panel's Text
end type

type TKSTATUSBAR_MESSAGEINFO
    hStatusBar as TK_WIDGET ptr
    msg        as long               ' TKM_MOUSEMOVE / TKM_MOUSELEAVE / TKM_LBUTTONDOWN / TKM_LBUTTONUP / TKM_RBUTTONDOWN / TKSB_MOUSEHOVER
    x          as single             ' widget-local pixels
    y          as single
    clicks     as long
    idx        as long               ' panel under the mouse, -1 for none
end type

type TKSTATUSBAR_STATE   ' per-instance state; reach it through the procedures

type SB_PaintCallbackSub as sub( byval p as TKSTATUSBAR_PAINTINFO ptr )
type SB_MessageCallbackFunc as function( byval m as TKSTATUSBAR_MESSAGEINFO ptr ) as boolean
type SB_TooltipCallbackFunc as function( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as ustring
type SB_ClickCallbackSub as sub( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byval clicks as long )
```

### Procedures

```freebasic
function tkStatusBar_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkStatusBar_AddPanel( byval hStatusBar as TK_WIDGET ptr, byval Text as ustring, byval itemData as integer = 0 ) as long
function tkStatusBar_InsertPanel( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byval Text as ustring, byval itemData as integer = 0 ) as long
function tkStatusBar_DeletePanel( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkStatusBar_Clear( byval hStatusBar as TK_WIDGET ptr )
function tkStatusBar_GetCount( byval hStatusBar as TK_WIDGET ptr ) as long
sub tkStatusBar_Refresh( byval hStatusBar as TK_WIDGET ptr )
function tkStatusBar_GetText( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkStatusBar_SetText( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkStatusBar_GetItemData( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as integer
function tkStatusBar_SetItemData( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byval itemData as integer ) as boolean
function tkStatusBar_GetPanelMinWidth( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as long
function tkStatusBar_SetPanelVisible( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byval bVisible as boolean ) as boolean
function tkStatusBar_GetPanelVisible( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkStatusBar_SetPanelMinWidth( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byval nMinWidth as long ) as boolean
function tkStatusBar_GetExpandPanel( byval hStatusBar as TK_WIDGET ptr ) as long
function tkStatusBar_SetExpandPanel( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkStatusBar_SetPanelStretch( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byval bStretch as boolean ) as boolean
function tkStatusBar_GetPanelStretch( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkStatusBar_GetPadding( byval hStatusBar as TK_WIDGET ptr ) as long
sub tkStatusBar_SetPadding( byval hStatusBar as TK_WIDGET ptr, byval nPadding as long )
function tkStatusBar_GetPanelRect( byval hStatusBar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkStatusBar_GetItemRect( byval hStatusBar as TK_WIDGET ptr, byval idx as long ) as TKRECT
function tkStatusBar_HitTest( byval hStatusBar as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkStatusBar_GetHot( byval hStatusBar as TK_WIDGET ptr ) as long
function tkStatusBar_GetBackColor( byval hStatusBar as TK_WIDGET ptr ) as ulong
function tkStatusBar_SetBackColor( byval hStatusBar as TK_WIDGET ptr, byval clr as ulong ) as ulong
sub tkStatusBar_GetColors( byval hStatusBar as TK_WIDGET ptr, byval pColors as TKSTATUSBAR_COLORS ptr )
sub tkStatusBar_SetColors( byval hStatusBar as TK_WIDGET ptr, byval pColors as TKSTATUSBAR_COLORS ptr )
function tkStatusBar_ThemeColors( byref t as TKTHEME_COLORS ) as TKSTATUSBAR_COLORS
sub tkStatusBar_ApplyTheme( byval hStatusBar as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkStatusBar_UnpinColors( byval hStatusBar as TK_WIDGET ptr )
function tkStatusBar_GetFont( byval hStatusBar as TK_WIDGET ptr ) as TTF_Font ptr
function tkStatusBar_SetFont( byval hStatusBar as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
sub tkStatusBar_ApplyFonts( byval hStatusBar as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
function tkStatusBar_GetTooltipHandle( byval hStatusBar as TK_WIDGET ptr ) as TK_TIP ptr
sub tkStatusBar_SetHoverTime( byval hStatusBar as TK_WIDGET ptr, byval milliseconds as long )
sub tkStatusBar_SetAutoPopTime( byval hStatusBar as TK_WIDGET ptr, byval milliseconds as long )
sub tkStatusBar_SetReshowTime( byval hStatusBar as TK_WIDGET ptr, byval milliseconds as long )
sub tkStatusBar_PaintPanelDefault( byval p as TKSTATUSBAR_PAINTINFO ptr )
sub tkStatusBar_SetPaintCallback( byval hStatusBar as TK_WIDGET ptr, byval usersub as SB_PaintCallbackSub )
sub tkStatusBar_SetMessageCallback( byval hStatusBar as TK_WIDGET ptr, byval userfunc as SB_MessageCallbackFunc )
sub tkStatusBar_SetTooltipCallback( byval hStatusBar as TK_WIDGET ptr, byval userfunc as SB_TooltipCallbackFunc )
sub tkStatusBar_SetClickCallback( byval hStatusBar as TK_WIDGET ptr, byval usersub as SB_ClickCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip)
