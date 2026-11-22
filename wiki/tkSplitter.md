[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkSplitter**

# tkSplitter

Draws a draggable divider bar between two panes and reports where the user drags it.

tkSplitter is a thin bar, vertical or horizontal, that shows a resize cursor, moves itself while
the user drags it, and calls you back with its new position. It keeps exactly one number: the
bar's leading edge in its parent's coordinates (its x for a vertical bar, its y for a horizontal
one).

It does not own, create or size the panes on either side. Your layout code reads
`tkSplitter_GetPos`, places the panes, and pushes the limits in with `tkSplitter_SetRange`
whenever the window resizes. Use it for any two-pane layout: a file list beside an editor, an
output panel under a document.

## Importing

```freebasic
#import "vendor/tkControls/tkSplitter"

using tkSplitter
using tkHost
using tkPaint
```

The module imports `tkHost` and `tkTheme` publicly, so `tkHost_*`, `tkWidget_*`, the `TK_PAINT`
drawing calls and `tkTheme_*` are available once their namespaces are opened with `using`.

## Example

A vertical bar between two panes. The callback fires with `TKSPLITTER_PHASE_BEGIN`, then
`TKSPLITTER_PHASE_MOVE` for each change of position, then `TKSPLITTER_PHASE_END`.

```freebasic
dim shared as TK_WIDGET ptr gSplit

sub Split_PosChanged( byval hSplitter as TK_WIDGET ptr, byval newPos as long, byval nPhase as long )
    ' The bar has already moved itself: lay out the panes either side of newPos.
    tkHost_Invalidate( gHost )
end sub

sub Form_Size( byval h as TK_HOST ptr )
    dim as long pw, ph
    tkHost_PixelSize( h, pw, ph )
    dim as long bar = tkHost_Scale( h, 6 ), minPane = tkHost_Scale( h, 80 )
    tkSplitter_SetRange( gSplit, minPane, pw - minPane - bar )
    tkWidget_SetPos( gSplit, tkSplitter_GetPos( gSplit ), 0, bar, ph )
end sub

gSplit = tkSplitter_Create( tkHost_Root( gHost ), 1001, TKSPLITTER_VERTICAL )
tkSplitter_SetPosChangedCallback( gSplit, @Split_PosChanged )
tkSplitter_SetPos( gSplit, tkHost_Scale( gHost, 240 ) )
gHost->OnSize = @Form_Size
```

`tkSplitter_SetPos` and `tkSplitter_SetRange` are silent: they move or clamp the bar without
calling the position callback, so repaint the panes yourself after calling them.

## Concepts

### The orientation is named for the bar's own axis

| Orientation | The bar is | It separates | It drags | Cursor | The position is |
|---|---|---|---|---|---|
| `TKSPLITTER_VERTICAL` | a vertical line | a **left** and a **right** pane | horizontally | `TK_CURSOR_SIZEWE` | the bar's **x** |
| `TKSPLITTER_HORIZONTAL` | a horizontal line | a **top** and a **bottom** pane | vertically | `TK_CURSOR_SIZENS` | the bar's **y** |

A vertical splitter does not split a window into a top and a bottom: it *is* a vertical bar,
and it splits left from right.

The orientation is passed to `tkSplitter_Create` and is fixed for the control's lifetime; any
value other than `TKSPLITTER_HORIZONTAL` is taken as `TKSPLITTER_VERTICAL`. There is no setter.
To switch split modes, destroy the control and create the other one.

### The position is the bar's leading edge, in the parent's coordinates

It is the *leading* edge, not the centre: the right pane of a vertical split starts at
`nPos + barWidth`, not at `nPos`. The parent is the widget passed to `tkSplitter_Create` (for a
top-level window, `tkHost_Root( h )`). `nMin`, `nMax` and the `newPos` your callback receives
all live in the same space.

### The size you give the bar is the grab area

The splitter is created at 0,0 with no size; place and size it with `tkWidget_SetPos`. There is
no separate hit margin: the whole widget is the bar. For a thin visual line inside a comfortable
grab area, size the widget comfortably and draw the line from a paint callback.

### The three drag phases

A user drag produces one `BEGIN`, zero or more `MOVE`s, and one `END`, in that order, all
through the position callback:

| Phase | When | `newPos` | What a host typically does |
|---|---|---|---|
| `TKSPLITTER_PHASE_BEGIN` | The user just grabbed the bar, before it has moved at all. | The current, unchanged position | Start the gesture: suspend an expensive reflow, snapshot state |
| `TKSPLITTER_PHASE_MOVE` | The position actually changed. Never fired when the clamped position is the same as before, so a drag held against a limit goes quiet. | The new position, already applied | Lay out the two panes; keep it cheap |
| `TKSPLITTER_PHASE_END` | The drag ended: the button came up, or the capture was lost. | The final position | Commit: resume the reflow, save the position |

`END` always arrives. Losing the capture mid-drag, hiding the splitter or disabling it ends the
drag at the position the user dragged to; every intermediate position has already been applied,
so there is nothing to undo. By the time `END` runs, `tkSplitter_IsDragging` already returns
FALSE.

By the time any phase fires, the control has already clamped the position and moved itself. Lay
out the panes from the callback; do not move the bar.

### Who owns what

| Owned by the control | Owned by you |
|---|---|
| The bar's position along its drag axis | The bar's thickness, its cross-axis position and its extent |
| Clamping to the range | Computing the range and pushing it in with `tkSplitter_SetRange` |
| Cursor, hover, capture, the drag arithmetic | Everything on both sides of the bar |
| Its own repaint | Repainting your panes |
| — | Collapse / restore, if you want it |

The control never derives the range from its parent's size, because it cannot know what else
lives in that space. Recompute the limits whenever the window resizes and call
`tkSplitter_SetRange`.

### Programmatic changes are silent

`tkSplitter_SetPos` and `tkSplitter_SetRange` clamp, move the bar and repaint, and fire nothing.
You can call either one from inside the position callback without re-entering it, and a
programmatic move must be followed by your own pane layout and repaint.

### Moving the bar yourself

If you move the widget yourself (a layout pass, a pane collapse), the control re-reads its
position from the widget whenever it is queried or set, so `tkSplitter_GetPos` always agrees
with where the bar actually is. That re-read is an observation: nothing is clamped and nothing
is notified. A bar placed outside its range is reported honestly, and the next drag or
`tkSplitter_SetPos` pulls it back in. The re-read is skipped while a drag is in progress, when
the control is the one doing the moving.

### Hover

The bar paints in its hot colour while the mouse is over it, and the host's mouse-leave clears
it. While a drag is live, hover is pinned TRUE, because under capture the cursor roams far
outside the bar. When the drag ends, hover is re-derived from where the cursor finished. Hiding
or disabling the splitter ends any drag and drops the hover, so the highlight cannot reappear
stale.

### Mouse capture

The control takes the capture on the button-down, before your message callback runs, so a
callback that claims the down still gets a clean, matched release. The message callback's
return value is ignored for `TKM_LBUTTONUP`: a host allowed to suppress it would strand the
capture.

### Double-click

A double click arrives as `TKM_LBUTTONDOWN` with `clicks = 2`. The control gives it the same
capture-and-begin-drag handling as an ordinary down, and does nothing else with it. Collapse and
restore are yours to implement: claim the double click from the message callback (return TRUE)
and no drag starts. Inside that handler, `tkSplitter_SetPos` moves the bar silently, so lay out
and repaint the panes yourself.

The first click of a double click is a real click: it begins and ends a zero-length drag (one
`BEGIN`, one `END`) before the double click arrives.

### Pixels and scale

Positions, limits and the bar's thickness are pixels in the parent's space; scale your literals
with `tkHost_Scale`. When the host's scale changes, the control rescales its position and both
limits (an unbounded maximum stays unbounded), re-clamps and moves the bar, silently. The
control measures no text and owns no font.

## Behaviour and limits

- **It does not create, size or know about the panes.** Your callback lays them out.
- **It does not compute its own limits.** Until `tkSplitter_SetRange` is called the range is
  `0 .. TKSPLITTER_MAX_UNBOUNDED`.
- **Limits are absolute pixel positions**, not fractions; nothing rescales when the parent
  resizes, so re-push the range on every resize.
- **An inverted range (`nMax < nMin`) pins the bar at `nMin`** rather than rejecting the call. A
  window too small to hold both panes legitimately produces one.
- **The control moves only along its drag axis.** Cross-axis position and size are read back
  from the widget and preserved. Moving the bar sideways (a horizontal bar inside the right pane
  of a vertical split) is your `tkWidget_SetPos`.
- **No keyboard.** The splitter is never focusable and handles no keys; keyboard resizing is the
  host's, through `tkSplitter_SetPos`.
- **A flat fill only.** Grip dots, a hairline or an etched edge are a paint callback's job.
- **No collapse, restore or snap of its own.** The control holds one number and no memory of a
  previous one.
- **No tooltip and no text.**
- **The cursor is the widget's own**, `TK_CURSOR_SIZEWE` or `TK_CURSOR_SIZENS`, set at create
  and held for the whole drag. Replace it with `tkWidget_SetCursor`.
- **Disabled** (`tkWidget_Enable`), the splitter ends any drag, drops its hover and takes no
  mouse input.

## Colours

The built-in painter uses two colours, held in `TKSPLITTER_COLORS`:

| Colour | Paints | Theme role |
|---|---|---|
| `BackColor` | The whole bar, idle | `Divider` |
| `HotColor` | The whole bar, while the mouse is over it **or** a drag is in progress | `TextDisabled` |

The splitter takes its colours from the current theme when it is created (including any theme
recipe for `"Splitter"`) and follows every theme change. `tkSplitter_SetColors` sets both
colours and pins them, so a theme change leaves this splitter alone; `tkSplitter_UnpinColors`
hands it back to the theme and applies the theme at once. `tkSplitter_GetColors` reads the pair
in force, `tkSplitter_ThemeColors` gives the theme mapping as a value, and
`tkSplitter_ApplyTheme` applies a given theme to an unpinned splitter.

The painter picks one colour per repaint, hot or dragging over idle, and fills the whole bar
with it. There is no separate dragging colour and no disabled colour. A paint callback ignores
both colours.

## Callbacks

All three are optional and independent. Passing 0 clears a callback; clearing the paint
callback restores the built-in painter.

### Position changed

```freebasic
type SPL_PosChangedCallbackSub as sub( byval hSplitter as TK_WIDGET ptr, byval newPos as long, byval nPhase as long )
```

The user moved the splitter. `newPos` is the new leading edge in the parent's coordinates and
`nPhase` is one of the three phases above. It does not fire for `tkSplitter_SetPos` or
`tkSplitter_SetRange`. One callback can serve several splitters: `hSplitter` says which one,
and `tkSplitter_GetOrientation` says which axis it moved on.

### Paint

```freebasic
type SPL_PaintCallbackSub as sub( byval p as TKSPLITTER_PAINTINFO ptr )
```

Draws the whole bar instead of the built-in painter. Nothing is drawn for you first: paint every
pixel through `p->b` inside `p->rcClient`. To draw the stock bar and add to it, call
`tkSplitter_PaintDefault( p )` first.

| Field | Meaning |
|---|---|
| `hSplitter` | The control, so the callback can query it |
| `b` | The paint context for this repaint (borrowed, not owned) |
| `rcClient` | The whole bar, widget-local |
| `nOrientation` | `TKSPLITTER_VERTICAL` or `TKSPLITTER_HORIZONTAL`, so one callback can serve both |
| `isHot` | The mouse is over the bar; stays TRUE for the whole of a drag |
| `isDragging` | A drag is in progress |

### Message

```freebasic
type SPL_MessageCallbackFunc as function( byval m as TKSPLITTER_MESSAGEINFO ptr ) as boolean
```

Observes the control's mouse messages as they arrive. `TKSPLITTER_MESSAGEINFO` carries
`hSplitter`, `msg`, widget-local `x` / `y` and `clicks`. Return TRUE to suppress the control's
own handling. It is called for these messages and no others:

| Message | Effect of returning TRUE |
|---|---|
| `TKM_LBUTTONDOWN` | No drag starts and no `BEGIN` is sent. The capture is already taken and is released on the trailing up. With `clicks = 2`, this is the way to implement collapse / restore. |
| `TKM_MOUSEMOVE` | Neither the drag update nor the hover update runs for this move. |
| `TKM_LBUTTONUP` | Ignored. The up ends the drag and releases the capture regardless. |

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKSPLITTER_MAX_UNBOUNDED = &h7FFFFFFF

enum TKSPLITTER_ORIENTATION
    TKSPLITTER_VERTICAL   = 0     ' vertical bar,   left/right panes -> TK_CURSOR_SIZEWE, nPos = x
    TKSPLITTER_HORIZONTAL = 1     ' horizontal bar, top/bottom panes -> TK_CURSOR_SIZENS, nPos = y
end enum

enum TKSPLITTER_PHASE
    TKSPLITTER_PHASE_BEGIN = 0    ' the user just grabbed the bar; newPos = current position
    TKSPLITTER_PHASE_MOVE  = 1    ' the position actually changed
    TKSPLITTER_PHASE_END   = 2    ' the drag ended (button up, or capture lost); final position
end enum
```

### Types

```freebasic
type TKSPLITTER_COLORS
    BackColor as ulong = &hFF353B45ul      ' the whole bar, idle
    HotColor  as ulong = &hFF5A6270ul      ' the whole bar, hot OR dragging
end type

type TKSPLITTER_PAINTINFO
    hSplitter    as TK_WIDGET ptr         ' the control, so the callback can query it
    b            as TK_PAINT ptr          ' the paint context for this repaint (borrowed)
    rcClient     as TKRECT                ' the whole bar, widget-local
    nOrientation as long                  ' TKSPLITTER_VERTICAL / TKSPLITTER_HORIZONTAL
    isHot        as boolean               ' the mouse is over the bar (pinned TRUE for a drag)
    isDragging   as boolean               ' a drag is in progress
end type

type TKSPLITTER_MESSAGEINFO
    hSplitter as TK_WIDGET ptr
    msg       as long
    x         as single
    y         as single
    clicks    as long
end type

type TKSPLITTER_STATE   ' per-instance state; reach it through the procedures

type SPL_PaintCallbackSub as sub( byval p as TKSPLITTER_PAINTINFO ptr )
type SPL_MessageCallbackFunc as function( byval m as TKSPLITTER_MESSAGEINFO ptr ) as boolean
type SPL_PosChangedCallbackSub as sub( byval hSplitter as TK_WIDGET ptr, byval newPos as long, byval nPhase as long )
```

### Procedures

```freebasic
function tkSplitter_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long, byval nOrientation as long = TKSPLITTER_VERTICAL ) as TK_WIDGET ptr
function tkSplitter_GetOrientation( byval hSplit as TK_WIDGET ptr ) as long
function tkSplitter_GetPos( byval hSplit as TK_WIDGET ptr ) as long
sub tkSplitter_SetPos( byval hSplit as TK_WIDGET ptr, byval nPosition as long )
sub tkSplitter_SetRange( byval hSplit as TK_WIDGET ptr, byval nMin as long, byval nMax as long )
function tkSplitter_GetMin( byval hSplit as TK_WIDGET ptr ) as long
function tkSplitter_GetMax( byval hSplit as TK_WIDGET ptr ) as long
function tkSplitter_IsHot( byval hSplit as TK_WIDGET ptr ) as boolean
function tkSplitter_IsDragging( byval hSplit as TK_WIDGET ptr ) as boolean
function tkSplitter_GetBackColor( byval hSplit as TK_WIDGET ptr ) as ulong
function tkSplitter_GetHotColor( byval hSplit as TK_WIDGET ptr ) as ulong
sub tkSplitter_SetColors( byval hSplit as TK_WIDGET ptr, byval backclr as ulong, byval hotclr as ulong )
function tkSplitter_ThemeColors( byref t as TKTHEME_COLORS ) as TKSPLITTER_COLORS
sub tkSplitter_ApplyTheme( byval hSplit as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkSplitter_GetColors( byval hSplit as TK_WIDGET ptr, byval pColors as TKSPLITTER_COLORS ptr )
sub tkSplitter_UnpinColors( byval hSplit as TK_WIDGET ptr )
sub tkSplitter_PaintDefault( byval p as TKSPLITTER_PAINTINFO ptr )
sub tkSplitter_SetPaintCallback( byval hSplit as TK_WIDGET ptr, byval usersub as SPL_PaintCallbackSub )
sub tkSplitter_SetMessageCallback( byval hSplit as TK_WIDGET ptr, byval userfunc as SPL_MessageCallbackFunc )
sub tkSplitter_SetPosChangedCallback( byval hSplit as TK_WIDGET ptr, byval usersub as SPL_PosChangedCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme)
