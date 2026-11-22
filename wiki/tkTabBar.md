[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTabBar**

# tkTabBar

Draws a row of document tabs that scroll, close and reorder by drag.

tkTabBar is a tab **bar**, not a tab container: it shows the tabs and reports what the user does, and your program swaps whatever sits beneath it. It is the strip above an editor's documents: tabs as wide as their text (never squeezed), scrolling when they overflow, a close "X" on each, a middle click to close anywhere on a tab, and live drag-to-reorder.

A tab is selected on the mouse press, unless the press is on its X. A close gesture does not delete the tab; it calls the Close callback, and your program decides whether to call `tkTabBar_DeleteTab`. `tkTabBar_CanNavigate` and `tkTabBar_Navigate` scroll the strip one tab left or right, for arrow buttons beside it.

Without a paint callback the bar draws its tabs itself, with an optional icon per tab (`tkTabBar_SetGlyph`, drawn with the font from `tkTabBar_SetGlyphFont`) and an accent on the active tab. Set a paint callback to draw the tabs yourself (`tkTabBar_PaintTabDefault( p )` in it draws the stock tab first); the bottom rule and the active tab's border are drawn after it. Setters are silent; SelChange, Close and Reorder fire only for what the user does.

## Importing

```freebasic
#import "vendor/tkControls/tkTabBar"
using tkTabBar
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` to write a paint callback.

## Example

`gHost` is the window ([tkHost](tkHost)); `gFont10` and `gGlyph9` are fonts opened with `tkHost_OpenFont`, the second from `tkHost_FontDir() & TK_FONT_ICONS`.

```freebasic
sub OnSel( byval b as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
    print "show document "; tkTabBar_GetItemData( b, idxNew )
end sub

sub OnClose( byval b as TK_WIDGET ptr, byval idx as long )
    tkTabBar_DeleteTab( b, idx )   ' the program decides; the bar only asks
end sub

dim as TK_WIDGET ptr bar = tkTabBar_Create( tkHost_Root( gHost ), 1003 )
tkTabBar_SetFont( bar, gFont10 )
tkTabBar_SetGlyphFont( bar, gGlyph9 )
tkTabBar_SetSelChangeCallback( bar, @OnSel )
tkTabBar_SetCloseCallback( bar, @OnClose )
tkTabBar_SetKeyboard( bar, true )

tkTabBar_AddTab( bar, "Explorer", 3001 ) : tkTabBar_SetGlyph( bar, 0, wchr( TK_ICON_FOLDER ) )
tkTabBar_AddTab( bar, "Search", 3002 )   : tkTabBar_SetGlyph( bar, 1, wchr( TK_ICON_SEARCH ) )
tkTabBar_AddTab( bar, "Output", 3003 )   : tkTabBar_SetGlyph( bar, 2, wchr( TK_ICON_CONSOLE ) )
tkTabBar_SetClosable( bar, 2, false )
tkTabBar_SetCurSel( bar, 0 )
tkWidget_SetPos( bar, 0, 0, 600, tkHost_Scale( gHost, 32 ) )
```

The toolchain's `examples/tkControls/tkTabBar/` shows two bars with custom painters and navigation buttons, and one with the built-in painter.

## Concepts

### The bar is one widget; tabs are rectangles

`tkTabBar_Create( parent, id )` creates the bar as a child of a `TK_WIDGET ptr` (for a window's
top level pass `tkHost_Root( h )`). It is created zero-sized, so it shows nothing until you place
it with `tkWidget_SetPos`. Every tab is a rectangle painted into the bar, which is why
hit-testing, hover and tooltips all work off rects.

### Tab indices are model indices

Every index in the API counts tabs from 0 through `tkTabBar_GetCount() - 1`, in bar order.
Scrolling does not shift them; inserting, deleting and moving do, and the bar remaps what it
stores: the selection and the hover follow the *tab*, so the selected document stays selected as
indices shift. `tkTabBar_InsertTab` clamps its index to `[0, count]` and returns the index it
used.

`itemData` is an `integer` the bar stores and never looks at. It travels with its tab through
every insert, delete and drag, and it is how you find your document from a tab index that has
moved.

Adding a tab does not select it, and deleting the selected tab selects nothing:
`tkTabBar_GetCurSel` returns -1 until you select something. Deleting an earlier tab keeps the
same tab selected at its new index.

### Programmatic setters are silent; only the user notifies

| Route | SelChange | Reorder | Close |
|---|---|---|---|
| `tkTabBar_SetCurSel` | no | — | — |
| `tkTabBar_MoveTab` | — | no | — |
| `tkTabBar_DeleteTab` | — | — | no |
| A press on a tab (not on its X) | **yes** | — | — |
| Left / Right / Home / End, with the keyboard on | **yes** | — | — |
| A drag past a neighbour | — | **yes**, once per move | — |
| A matched close gesture | — | — | **yes** |

So you can call `tkTabBar_SetCurSel` from inside your SelChange handler, `tkTabBar_MoveTab` from
your Reorder handler and `tkTabBar_DeleteTab` from your Close handler without re-entering
anything. SelChange and Reorder fire **after** the bar's state is updated, so the getters already
agree with the arguments you are handed.

### Tabs never shrink, and overflow clips

```
  width = max( textWidth + 2*iconWidth + 2*padding + 2*borderWidth,  nMinWidth )
```

`textWidth` is the caption measured with the bar's font (the host's default font if none is set).
No tab is ever narrower than its caption plus its two icon cells; there is no tab-width setter and
no compression. When tabs stop fitting, the rightmost one clips at the edge and scrolling takes
over. `nMinWidth` (`tkTabBar_SetTabMinWidth`) is a floor, not a fixed width; set one on a tab
whose caption changes, so it does not shove its neighbours on each update.

### Both icon cells are always reserved

Every tab reserves two square cells of `tkTabBar_GetIconWidth` pixels: a left one for an icon and
a right one for the close X, whether or not anything is drawn in them. That keeps the caption at
the same offset in every tab and stops it jumping when the X appears on hover. A tab made
unclosable with `tkTabBar_SetClosable` keeps its X cell too, so nothing shifts.

### Geometry is derived, never assigned

The bar computes five rects per tab, readable through `tkTabBar_GetTabRect` and
`tkTabBar_GetTabParts`:

| Rect | What it is |
|---|---|
| `rc` | The full tab, the bar's full height |
| `rcPaint` | `rc` deflated by the border width; handed to a paint callback as `p->rc` |
| `rcText` | The caption area, between the two icon cells |
| `rcIcon` | The left icon square |
| `rcClose` | The right icon square, and the close X's hit target |

The deflation is asymmetric on purpose. Left, top and right are deflated on every tab, so the
caption does not move when a tab is selected; the bottom is deflated on inactive tabs only, so
the active tab's fill runs to the bottom and covers the break in the bottom rule. The icon cells
and `rcText` are centred on the symmetric height, so they sit at the same offset whether or not
the tab is selected.

Layout is lazy: a mutator marks it stale and repaints, and the next paint or rect query
recomputes it once. A burst of `tkTabBar_SetText` calls costs one measuring pass. Both rect
queries force a pending layout, and return FALSE with empty rects for an invalid index. A tab
scrolled off the left has empty rects, which is its honest geometry, not a failure.

### The chrome belongs to the bar

Two things are drawn by the bar itself, after every tab, in `BorderColor` and the border width:

- **A full-width bottom rule that breaks under the active tab**, drawn as two segments either
  side of it.
- **The active tab's three-sided border**: left, top, right, the full tab height.

`tkTabBar_SetBorderWidth( bar, 0 )` removes both. Until you set a border width, the bar takes it
from the current theme's shape (1 pixel, scaled, by default); setting one pins it.

### Scrolling is a first-visible index

`tkTabBar_GetFirstVisible` is the leftmost **whole** tab; tabs are never half-drawn at the left
edge, and tabs scrolled off the left cannot be hovered or clicked. It moves when:

- `tkTabBar_Navigate( bar, -1 or +1 )` steps it one tab, doing nothing when
  `tkTabBar_CanNavigate` says the step would not move. Left can move unless the first tab is
  already showing; right can move while the last tab still clips at the edge. `CanNavigate` is
  FALSE for an empty bar, for any direction other than ±1, and before the bar has a size. Use it
  to enable arrow buttons beside the bar.
- `tkTabBar_SetFirstVisible` sets it outright, cancelling any pending scroll-into-view.
- the mouse wheel over the bar steps it; wheel up scrolls left.

Two things move it for you. Selecting a tab (by the user, or `tkTabBar_SetCurSel` with a valid
index) queues a scroll-into-view consumed at the next layout, so it is safe before the bar has a
size. And the layout back-fills: when the tail from the first visible tab onward fits with room
for the tab before it, earlier tabs are pulled back into view, so a delete or a widening resize
never leaves empty space on the right while tabs sit hidden on the left.

### How a click, a close and a drag are decided

The bar takes the mouse capture on a left or middle press, so the release always comes back to
it.

- **Select** happens on the left button **down**, unless the press landed on the tab's X:
  closing a tab must not first activate it. Clicks never take focus, so a tab press does not pull
  the caret out of your editor.
- **Close** fires only on a **matched** gesture: pressed on a tab's X and released on the same
  tab's X, or a middle press and release on the same tab, anywhere on it. Press, slide off and
  release cancels. A tab set unclosable with `tkTabBar_SetClosable( bar, idx, false )` refuses
  both gestures and draws no X.
- **Drag** starts when a left press that did not land on the X moves `TKTABBAR_DRAG_THRESHOLD`
  pixels (scaled) in either direction. Reordering is live: the tabs exchange the moment the
  pointer crosses into a neighbour, gated on the direction of travel so a narrow tab dragged over
  a wide one does not oscillate. The moving tabs are the feedback; there is no ghost image or drop
  marker. The cursor is `TK_CURSOR_SIZEALL` for the drag.

While a drag is live, hover is pinned to the dragged tab: it keeps `isHot` for the whole gesture,
and no tab it passes over lights up or shows an X. There is no Escape to cancel, and losing the
capture mid-drag does not restore the old order; every intermediate order has already been
notified. Any insert, delete or clear cancels a live press.

### Hover

The bar tracks two hover facts: which tab the cursor is over, and whether it is on that tab's X.
A tab is `isHot` and `isHotClose` at once when the cursor is on its X. The host's mouse-leave
clears hover (except during a drag), and so does disabling the bar.

### Keyboard (opt-in)

By default the bar is never focusable and handles no keys. `tkTabBar_SetKeyboard( bar, true )`
makes it a Tab stop: Left and Right select the neighbouring tab, Home and End the first and last,
each as a user selection that fires SelChange. While it has focus, `isFocused` is TRUE in the
paint info and the built-in painter rings the selected tab. Clicks still never take focus.
Turning the keyboard off while the bar has focus clears the focus.

### Tooltips

The bar owns one tooltip covering the whole bar. Its text is resolved on demand for the hot tab:
the tooltip callback if one is set, otherwise the tab's caption, so tooltips are on by default.
`""` shows no tip. A press or the start of a drag hides a visible tip.
`tkTabBar_SetHoverTime`, `tkTabBar_SetAutoPopTime` and `tkTabBar_SetReshowTime` set the tip's
delays; `tkTabBar_GetTooltipHandle` returns the `TK_TIP ptr` for any [tkTooltip](tkTooltip) call.

### Pixels and scale

The padding (`TKTABBAR_DEFAULT_PADDING`), icon width (`TKTABBAR_DEFAULT_ICONWIDTH`) and border
width (1) start scaled. Every setter afterwards takes pixels, clamps negatives to 0 and re-lays
out; scale your literals with `tkHost_Scale`. When the host's scale changes, the bar rescales its
padding, icon width, border width (never below 1 unless it is 0) and every tab's minimum width.

## Behaviour and limits

- **The bar never deletes a tab on its own.** The Close callback only asks; doing nothing vetoes
  the close.
- **Nothing shrinks and nothing ellipsises.** Tabs clip at the edge.
- **A partly clipped rightmost tab is clickable, but its X can sit past the edge.** Scroll it into
  view, or middle-click it.
- **The right button is observed, never acted on.** `TKM_RBUTTONDOWN` reaches the message
  callback; no capture is taken and its up is not reported.
- **A double click is a press.** `TKM_LBUTTONDOWN` with `clicks = 2` runs the same press-and-select
  handling and is reported to the message callback; there is no double-click callback.
- **All tabs are the bar's height**; no per-tab height, no multiple rows.
- **One selected tab at most**, and no drag between two bars.
- **`tkTabBar_SetBackColor` does not repaint**; call `tkTabBar_Refresh` after it on a visible bar.
  `tkTabBar_SetBorderColor` does repaint. Both return the previous colour and pin the colours.
- **`tkTabBar_SetItemData` does not repaint**; nothing visible changed.
- **Getters on an invalid index** return `""`, `0`, `-1` or FALSE rather than failing.

## Colours

`TKTABBAR_COLORS` holds every colour the bar uses. The bar takes them from the current theme when
it is created (including any theme recipe for `"TabBar"`) and follows every theme change.
`tkTabBar_SetColors`, `tkTabBar_SetBackColor` and `tkTabBar_SetBorderColor` pin them, so a theme
change leaves this bar alone; `tkTabBar_UnpinColors` hands it back to the theme and applies it at
once.

| Colour | Paints | Theme role |
|---|---|---|
| `BackColor` | The whole bar, filled first; shows through any gap, including past the last tab | `Window` |
| `BorderColor` | The bottom rule and the active tab's border | `Border` |
| `TabBackColor` | An idle tab | `Surface` |
| `TabBackColorHot` | The hot tab | `SurfaceHot` |
| `TabBackColorSelected` | The active tab | `Window` |
| `TabBackColorDrag` | The tab being dragged | `Selected` |
| `TextColor` | An idle tab's caption and icon | `TextDim` |
| `TextColorHot` | The hot tab's caption and icon | `TextHot` |
| `TextColorSelected` | The active or dragged tab's caption and icon | `TextStrong` |
| `CloseColor` | The X | `TextDim` |
| `CloseColorHot` | The X under the mouse | `TextHot` |
| `AccentColor` | The accent bar along the top of the active tab | `Accent` |
| `FocusRingColor` | The ring on the active tab while the bar has focus | `FocusRing` |

Every colour below `BorderColor` is the built-in painter's; a paint callback uses only what it
chooses to.

### Paint order

```
  1.  the whole bar, filled with BackColor
  2.  each visible tab: the paint callback if set, otherwise the built-in painter
  3.  the chrome, in BorderColor: the bottom rule, then the active tab's border
```

The chrome runs last, so it is drawn the same whatever a callback painted. The break in the
bottom rule is where the active tab's own fill shows through.

### The built-in painter

With no paint callback, each tab is filled by state with precedence
`dragging > selected > hot > normal`; the active tab gets a 2-pixel (scaled) accent bar along its
top. The tab's glyph (`tkTabBar_SetGlyph`) is centred in `rcIcon` with the glyph font from
`tkTabBar_SetGlyphFont`, and is drawn only when both are set. The caption is drawn left-aligned
in `rcText`. The X is drawn on a closable tab while it is hot or selected, in `CloseColorHot`
when the cursor is on it; it uses `TK_ICON_CLOSE` from the glyph font, or a multiplication sign
from the text font when no glyph font is set.

## Callbacks

All are optional and independent; passing 0 clears one. One callback can serve several bars:
each receives the bar it fired for.

### Paint

```freebasic
type TB_PaintCallbackSub as sub( byval p as TKTABBAR_PAINTINFO ptr )
```

Draws **one tab**, called once per visible tab per repaint, instead of the built-in painter. Paint
through `p->b` and do not keep it past the call; `tkTabBar_PaintTabDefault( p )` draws the stock
tab first if you want to add to it. Draw with the bar's font and use the rects as handed to you:
they are exactly the space the measured width accounts for. Fill `p->rc`, never the whole bar,
or you erase the tabs drawn before it.

| Field | Meaning |
|---|---|
| `hTabBar` | The bar, so the callback can query it |
| `itemID` | This tab's model index |
| `b` | The paint context for this repaint (borrowed) |
| `rc` | The border-deflated paint area: fill this. On the active tab it runs to the bottom |
| `rcText` | The caption area |
| `rcIcon` | The left icon square |
| `rcClose` | The right icon square, the close X |
| `isSelected` | This is the active tab |
| `isHot` | The mouse is over this tab |
| `isHotClose` | The mouse is over this tab's X; `isHot` is TRUE too |
| `isPressed` | A live left press is on this tab |
| `isDragging` | This tab is being dragged; `isPressed` is TRUE too |
| `isFocused` | The bar has keyboard focus |
| `wszCaption` | The tab's text |

A reading order that works is `dragging > selected > hot > normal`, with `isHotClose` changing
only how the X is drawn.

### Selection changed

```freebasic
type TB_SelChangeCallbackSub as sub( byval hTabBar as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
```

The user changed the active tab. `tkTabBar_GetCurSel` already equals `idxNew`; `idxOld` is -1 when
nothing was selected. This is where you swap the page beneath the bar.

### Close requested

```freebasic
type TB_CloseCallbackSub as sub( byval hTabBar as TK_WIDGET ptr, byval idx as long )
```

The user asked to close tab `idx` with a matched gesture. The bar deletes nothing: prompt to save,
do nothing to veto, or call `tkTabBar_DeleteTab`. A close on the X never selects the tab first, so
`idx` is often not the active tab.

### Reorder

```freebasic
type TB_ReorderCallbackSub as sub( byval hTabBar as TK_WIDGET ptr, byval idxFrom as long, byval idxTo as long )
```

A drag moved a tab, fired once per move after the bar's array and indices are updated. One drag
across several tabs fires several; mirror each move into your own model as it arrives. There is
nothing to veto.

### Tooltip

```freebasic
type TB_TooltipCallbackFunc as function( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as ustring
```

The tip text for the hot tab, called only when a tip is about to show, so it is the place to build
a full path or a modified-state suffix. Return `""` for no tip.

### Message

```freebasic
type TB_MessageCallbackFunc as function( byval m as TKTABBAR_MESSAGEINFO ptr ) as boolean
```

Observes mouse messages. `TKTABBAR_MESSAGEINFO` carries `hTabBar`, `msg`, widget-local `x` / `y`,
`clicks`, `wheelY` and `idx`, the tab under the cursor or -1 for none. Return TRUE to suppress
the bar's own handling. It is called for `TKM_MOUSEMOVE`, `TKM_MOUSELEAVE` (`idx` -1),
`TKM_LBUTTONDOWN`, `TKM_LBUTTONUP`, `TKM_MBUTTONDOWN`, `TKM_MBUTTONUP`, `TKM_RBUTTONDOWN` and
`TKM_MOUSEWHEEL`, and no others.

| Message | Effect of returning TRUE |
|---|---|
| `TKM_MOUSEMOVE` | The move does not drive a drag. Hover is already updated |
| `TKM_LBUTTONDOWN` | No selection and no press. The capture is already taken and is released on the up |
| `TKM_MBUTTONDOWN` | The middle-click close is not armed |
| `TKM_MOUSEWHEEL` | The bar does not scroll |
| `TKM_LBUTTONUP`, `TKM_MBUTTONUP` | **Ignored.** These end the press and release the capture regardless |

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKTABBAR_DEFAULT_PADDING = 8
const TKTABBAR_DEFAULT_ICONWIDTH = 20
const TKTABBAR_DRAG_THRESHOLD = 4
```

### Types

```freebasic
type TKTABBAR_COLORS
    BackColor            as ulong = &hFF21252Bul    ' the whole client, filled first
    BorderColor          as ulong = &hFF444A56ul    ' bottom rule + the active tab's border
    TabBackColor         as ulong = &hFF2C313Aul    ' --- built-in painter only ---
    TabBackColorHot      as ulong = &hFF373D48ul
    TabBackColorSelected as ulong = &hFF21252Bul
    TabBackColorDrag     as ulong = &hFF264F78ul
    TextColor            as ulong = &hFF969CA6ul
    TextColorHot         as ulong = &hFFE2E6EEul
    TextColorSelected    as ulong = &hFFFFFFFFul
    CloseColor           as ulong = &hFF969CA6ul
    CloseColorHot        as ulong = &hFFE2E6EEul
    AccentColor          as ulong = &hFF569CD6ul
    FocusRingColor       as ulong = &hFF61AFEFul
end type

type TKTABBAR_TABINFO
    Text      as ustring
    itemData  as integer
    nMinWidth as long
    wszGlyph  as ustring
    bClosable as boolean = true
    nWidth    as long
    rc        as TKRECT
    rcPaint   as TKRECT
    rcText    as TKRECT
    rcIcon    as TKRECT
    rcClose   as TKRECT
end type

type TKTABBAR_PAINTINFO
    hTabBar    as TK_WIDGET ptr
    itemID     as long
    b          as TK_PAINT ptr
    rc         as TKRECT            ' the border-DEFLATED paint area: fill THIS
    rcText     as TKRECT
    rcIcon     as TKRECT
    rcClose    as TKRECT
    isSelected as boolean
    isHot      as boolean
    isHotClose as boolean
    isPressed  as boolean
    isDragging as boolean
    isFocused  as boolean           ' the bar has keyboard focus (opt-in keyboard)
    wszCaption as ustring
end type

type TKTABBAR_MESSAGEINFO
    hTabBar as TK_WIDGET ptr
    msg     as long                 ' TKM_*
    x       as single
    y       as single
    clicks  as long
    wheelY  as single               ' TKM_MOUSEWHEEL
    idx     as long
end type

type TKTABBAR_STATE   ' per-instance state; reach it through the procedures

type TB_PaintCallbackSub as sub( byval p as TKTABBAR_PAINTINFO ptr )
type TB_MessageCallbackFunc as function( byval m as TKTABBAR_MESSAGEINFO ptr ) as boolean
type TB_TooltipCallbackFunc as function( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as ustring
type TB_SelChangeCallbackSub as sub( byval hTabBar as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
type TB_CloseCallbackSub as sub( byval hTabBar as TK_WIDGET ptr, byval idx as long )
type TB_ReorderCallbackSub as sub( byval hTabBar as TK_WIDGET ptr, byval idxFrom as long, byval idxTo as long )
```

### Procedures

```freebasic
function tkTabBar_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkTabBar_AddTab( byval hTabBar as TK_WIDGET ptr, byval Text as ustring, byval itemData as integer = 0 ) as long
function tkTabBar_InsertTab( byval hTabBar as TK_WIDGET ptr, byval idx as long, byval Text as ustring, byval itemData as integer = 0 ) as long
function tkTabBar_DeleteTab( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabBar_MoveTab( byval hTabBar as TK_WIDGET ptr, byval idxFrom as long, byval idxTo as long ) as boolean
sub tkTabBar_Clear( byval hTabBar as TK_WIDGET ptr )
function tkTabBar_GetCount( byval hTabBar as TK_WIDGET ptr ) as long
function tkTabBar_IsValidTab( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabBar_GetText( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkTabBar_SetText( byval hTabBar as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkTabBar_GetItemData( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as integer
function tkTabBar_SetItemData( byval hTabBar as TK_WIDGET ptr, byval idx as long, byval itemData as integer ) as boolean
function tkTabBar_SetGlyph( byval hTabBar as TK_WIDGET ptr, byval idx as long, byval Glyph as ustring ) as boolean
function tkTabBar_GetGlyph( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkTabBar_SetClosable( byval hTabBar as TK_WIDGET ptr, byval idx as long, byval bClosable as boolean ) as boolean
function tkTabBar_GetClosable( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkTabBar_Refresh( byval hTabBar as TK_WIDGET ptr )
function tkTabBar_GetCurSel( byval hTabBar as TK_WIDGET ptr ) as long
function tkTabBar_SetCurSel( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabBar_GetFirstVisible( byval hTabBar as TK_WIDGET ptr ) as long
function tkTabBar_SetFirstVisible( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabBar_CanNavigate( byval hTabBar as TK_WIDGET ptr, byval nDirection as long ) as boolean
function tkTabBar_Navigate( byval hTabBar as TK_WIDGET ptr, byval nDirection as long ) as long
function tkTabBar_GetTabMinWidth( byval hTabBar as TK_WIDGET ptr, byval idx as long ) as long
function tkTabBar_SetTabMinWidth( byval hTabBar as TK_WIDGET ptr, byval idx as long, byval nMinWidth as long ) as boolean
function tkTabBar_GetPadding( byval hTabBar as TK_WIDGET ptr ) as long
sub tkTabBar_SetPadding( byval hTabBar as TK_WIDGET ptr, byval nPadding as long )
function tkTabBar_GetIconWidth( byval hTabBar as TK_WIDGET ptr ) as long
sub tkTabBar_SetIconWidth( byval hTabBar as TK_WIDGET ptr, byval nIconWidth as long )
function tkTabBar_GetBorderWidth( byval hTabBar as TK_WIDGET ptr ) as long
sub tkTabBar_SetBorderWidth( byval hTabBar as TK_WIDGET ptr, byval nBorderWidth as long )
function tkTabBar_GetTabRect( byval hTabBar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkTabBar_GetTabParts( byval hTabBar as TK_WIDGET ptr, byval idx as long, byref rcPaint as TKRECT, byref rcText as TKRECT, byref rcIcon as TKRECT, byref rcClose as TKRECT ) as boolean
function tkTabBar_HitTest( byval hTabBar as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkTabBar_GetHotTab( byval hTabBar as TK_WIDGET ptr ) as long
function tkTabBar_GetHotClose( byval hTabBar as TK_WIDGET ptr ) as boolean
function tkTabBar_IsDragging( byval hTabBar as TK_WIDGET ptr ) as boolean
function tkTabBar_GetBackColor( byval hTabBar as TK_WIDGET ptr ) as ulong
function tkTabBar_SetBackColor( byval hTabBar as TK_WIDGET ptr, byval clr as ulong ) as ulong
function tkTabBar_GetBorderColor( byval hTabBar as TK_WIDGET ptr ) as ulong
function tkTabBar_SetBorderColor( byval hTabBar as TK_WIDGET ptr, byval clr as ulong ) as ulong
sub tkTabBar_GetColors( byval hTabBar as TK_WIDGET ptr, byval pColors as TKTABBAR_COLORS ptr )
sub tkTabBar_SetColors( byval hTabBar as TK_WIDGET ptr, byval pColors as TKTABBAR_COLORS ptr )
function tkTabBar_ThemeColors( byref t as TKTHEME_COLORS ) as TKTABBAR_COLORS
sub tkTabBar_ApplyTheme( byval hTabBar as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkTabBar_UnpinColors( byval hTabBar as TK_WIDGET ptr )
function tkTabBar_GetFont( byval hTabBar as TK_WIDGET ptr ) as TTF_Font ptr
function tkTabBar_SetFont( byval hTabBar as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
sub tkTabBar_SetGlyphFont( byval hTabBar as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkTabBar_ApplyFonts( byval hTabBar as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkTabBar_SetKeyboard( byval hTabBar as TK_WIDGET ptr, byval bOn as boolean )
function tkTabBar_GetKeyboard( byval hTabBar as TK_WIDGET ptr ) as boolean
function tkTabBar_GetTooltipHandle( byval hTabBar as TK_WIDGET ptr ) as TK_TIP ptr
sub tkTabBar_SetHoverTime( byval hTabBar as TK_WIDGET ptr, byval milliseconds as long )
sub tkTabBar_SetAutoPopTime( byval hTabBar as TK_WIDGET ptr, byval milliseconds as long )
sub tkTabBar_SetReshowTime( byval hTabBar as TK_WIDGET ptr, byval milliseconds as long )
sub tkTabBar_PaintTabDefault( byval p as TKTABBAR_PAINTINFO ptr )
sub tkTabBar_SetPaintCallback( byval hTabBar as TK_WIDGET ptr, byval usersub as TB_PaintCallbackSub )
sub tkTabBar_SetMessageCallback( byval hTabBar as TK_WIDGET ptr, byval userfunc as TB_MessageCallbackFunc )
sub tkTabBar_SetTooltipCallback( byval hTabBar as TK_WIDGET ptr, byval userfunc as TB_TooltipCallbackFunc )
sub tkTabBar_SetSelChangeCallback( byval hTabBar as TK_WIDGET ptr, byval usersub as TB_SelChangeCallbackSub )
sub tkTabBar_SetCloseCallback( byval hTabBar as TK_WIDGET ptr, byval usersub as TB_CloseCallbackSub )
sub tkTabBar_SetReorderCallback( byval hTabBar as TK_WIDGET ptr, byval usersub as TB_ReorderCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip)
