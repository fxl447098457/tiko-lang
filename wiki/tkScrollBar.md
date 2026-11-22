[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkScrollBar**

# tkScrollBar

Runs the one scrollbar engine behind tkVScrollBar and tkHScrollBar.

tkScrollBar is the shared implementation of the two scrollbar controls. A vertical and a
horizontal bar are the same control with the axes swapped, so both are built here and
[tkVScrollBar](tkVScrollBar) and [tkHScrollBar](tkHScrollBar) are thin modules over it. Import
one of those for a bar; this page describes the behaviour they share.

A bar is a flat track with a flat thumb, and no arrow buttons. It knows nothing about your
content: you give it a total, a page (how many units are visible) and a position, and it calls
you back when the user moves it. It never takes focus, handles no keys, and does not size, place
or hide itself.

## Importing

```freebasic
#import "vendor/tkControls/tkVScrollBar"   ' or tkHScrollBar, or both

using tkVScrollBar
using tkScrollBar
using tkHost
```

Each of the two bar modules imports `tkScrollBar`, `tkHost` and `tkTheme` publicly. Open
`tkScrollBar` with `using` only to call an engine name such as `tkScrollBar_GetThumbRect` on a
bar of either kind; every bar handle is accepted by the `tkScrollBar_*` procedures.

## How a bar behaves

### The range model: total, page, position

Three numbers describe everything, and the bar has no idea whether a unit is a line, a column,
a pixel or a record:

| Term | Meaning |
| --- | --- |
| `total` | How many units of content there are altogether |
| `page` | How many units are visible at once |
| `pos` | The index of the first visible unit: the topmost for a vertical bar, the leftmost for a horizontal one |

```
  MaxPos     = max( total - page, 0 )
  NeedsThumb = (total > 0) and (page > 0) and (total > page)
```

- Positions are whole units, clamped to `0 .. MaxPos` by every path that can change them:
  `SetRange`, `SetPos`, a thumb drag, a track click, the auto-repeat and the wheel. For finer
  scrolling make the unit smaller (pixels rather than lines) and the range larger.
- `SetRange` clamps `total` and `page` to at least 0, then clamps the position into the range
  they imply, so a position past the end means "as far as it goes", and passing `GetPos` keeps
  where the user was. There is no getter for `total` or `page`.
- When everything fits (`page >= total`) there is no thumb: `tkScrollBar_NeedsThumb` is false,
  `tkScrollBar_GetThumbRect` is empty, and only the track is painted.

### Who owns the content

You do. The bar stores three integers and paints a thumb; it never scrolls anything.

1. You compute `total`, `page` and `pos` and push them in with `SetRange`.
2. The user drags, clicks or wheels; the bar clamps, repaints, and calls your scroll callback
   with the new position.
3. Your callback scrolls and repaints your content. It need not push the position back: the bar
   already has it.

`SetPos` is for the other direction: when you scroll the content yourself (a key, a "go to
line", a search hit) and the bar has to catch up. `SetRange` and `SetPos` are silent, so both
are safe to call from inside the scroll callback.

### Geometry

The thumb is recomputed from the range on every paint, resize and position change; you never
set it. For a vertical bar (swap the axes for a horizontal one):

```
  track      = client height
  minThumb   = TKSCROLL_MIN_THUMB, scaled
  thumbLen   = clamp( (page / total) * track, minThumb, track )
  span       = track - thumbLen
  thumb.top  = (pos / MaxPos) * span          0 when MaxPos = 0
```

The thumb always spans the bar's full thickness. Its minimum length keeps it grabbable on a
very large range, at the cost of no longer being exactly proportional there. A drag runs the
mapping backwards (the cursor, less the offset where the thumb was grabbed) and rebuilds the
thumb from the resulting position, so the thumb and the position you are told about cannot
drift apart.

### The bar never sizes, places or hides itself

A bar is created zero-sized. Place and size it with `tkWidget_SetPos`; the usual thickness is
`TKSCROLL_DEFAULT_THICKNESS` (`TKVSCROLL_DEFAULT_WIDTH` / `TKHSCROLL_DEFAULT_HEIGHT`), scaled
with `tkHost_Scale`. Show and hide it with `tkWidget_Show`.

Auto-hide is your decision. `tkScrollBar_NeedsThumb` answers the range question only and
ignores the bar's own size, so it is valid before the bar has ever been sized; a test that
needed a track would never show a bar that had not been sized yet. Hiding a bar drops the hover
highlight, stops any auto-repeat and ends a drag, so nothing stale comes back when it is shown
again. If you hide a bar on mouse-leave, ask `tkScrollBar_IsDragging` first: it is true while a
thumb drag or a track auto-repeat is live, when the cursor may legitimately be outside the bar.

### Mouse

- Pressing on the thumb starts a drag and takes the mouse capture, so the drag carries on
  outside the bar; the position simply clamps.
- Pressing on the track pages by exactly `page` toward the click and takes the capture. Held,
  it repeats after `TKSCROLL_REPEAT_DELAY` ms and then every `TKSCROLL_REPEAT_MS` ms, stopping
  when the thumb reaches the cursor or there is nowhere left to go.
- Releasing the button ends the drag or the repeat and releases the capture. Losing the capture
  any other way cancels both.
- The thumb is drawn hot while the mouse is over it and while it is dragged; leaving the bar
  clears the highlight.
- When there is nothing to scroll, a press does nothing and takes no capture.
- No double-click, right-button or keyboard handling, no focus, no enabled state, no tooltips.
  Home, End, PgUp and PgDn are yours to handle with `SetPos`.

### Wheel and touchpad

- One notch is 120 units of delta and moves the wheel step (`tkScrollBar_SetWheelStep`) in
  range units, or `TKSCROLL_SYSTEM_WHEEL_LINES` units when the step is 0 (the default). Set a
  step when your units are neither lines nor characters.
- Partial notches from a precise wheel or touchpad accumulate until they add up to a unit, so a
  slow swipe scrolls continuously; only the delta the applied units represent is consumed.
  Changing the step discards the part-accumulated remainder; setting the step it already has
  keeps it, so a layout routine that sets the step on every pass does not stall a swipe.
- A vertical bar takes only the vertical wheel and a horizontal bar only the horizontal one; the
  other axis passes on to the parent. A wheel on the bar's own axis is consumed whether or not
  the position moved.
- `HandleWheelDelta` takes 120ths of a notch and returns true when the position moved. A
  positive delta moves a vertical bar up (decreasing `pos`) but a horizontal bar right
  (increasing it). That is the sign of `wheelY * 120` and `wheelX * 120` in a `TKM_MOUSEWHEEL`,
  so pass the value through unchanged.
- The wheel goes to the widget under the pointer, so the bar sees it only while the pointer is
  over the bar. Forward the wheel from your content widget with `HandleWheelDelta` so the whole
  content area scrolls, not only a twelve-pixel strip.
- Wheel scrolling calls the scroll callback, because it is the user scrolling.

### Colours and painting

| Colour | Set by | Theme role | Paints |
| --- | --- | --- | --- |
| Track | `SetColors` `backclr` | `Window` | The whole bar, behind the thumb |
| Thumb | `SetColors` `foreclr` | `Border` | The thumb at rest |
| Thumb, active | `SetColors` `foreclrhot` | `TextDisabled` | The thumb while hot or dragged |
| Divider | `tkScrollBar_SetDividerColor` | `Divider` | A vertical bar's one-pixel left edge, when shown |

- Colours follow the current theme until `SetColors` or `SetDividerColor` pins them;
  `UnpinColors` hands them back. Before any theme reaches it a bar paints `&hFF21252B`,
  `&hFF353B45` and `&hFF5A6270`.
- The built-in painter fills the track, then draws the thumb as a plain filled rectangle (no
  border, rounding or gradient), then a vertical bar's divider.
- A paint callback replaces the built-in painter and must cover the whole bar; it can call
  `tkScrollBar_PaintDefault( p )` to draw the stock bar first and then add to it.
  `TKSCROLLBAR_PAINTINFO` carries the paint context `b`, the client rect, the thumb rect (empty
  when there is no thumb; recomputed just before the callback), the hot and dragging states,
  and the bar itself in `hScrollBar`, so one callback can serve several bars.
- The scroll callback, `tkScrollNotifySub( hSB, newPos )`, fires once per position change of a
  thumb drag, for a track click and each auto-repeat step, and for a wheel step that moved the
  bar. The bar's state is already updated, so `GetPos` equals `newPos`.
  `tkScrollBar_StepBy` moves the bar as a user step does, callback included.
- A destroyed bar stops its auto-repeat timer and frees its state; it owns nothing else.

### Constants

| Constant | Value | Meaning |
| --- | ---: | --- |
| `TKSCROLL_REPEAT_DELAY` | 400 | ms before a held track click starts repeating |
| `TKSCROLL_REPEAT_MS` | 80 | ms between repeats while the button is held |
| `TKSCROLL_MIN_THUMB` | 20 | Minimum thumb length, scaled at the point of use |
| `TKSCROLL_DEFAULT_THICKNESS` | 12 | Suggested bar thickness; the bar never reads it |
| `TKSCROLL_SYSTEM_WHEEL_LINES` | 3 | Units per notch when the wheel step is 0 |

The two bar modules re-export these as `TKVSCROLL_*` and `TKHSCROLL_*`, and name the callback
types `VScrollCallbackSub` / `VScrollPaintCallbackSub` and `HScrollCallbackSub` /
`HScrollPaintCallbackSub`. Every procedure takes the bar's `TK_WIDGET ptr`, and
`Create( hParent, CtrlID )` takes a `TK_WIDGET ptr` parent (`tkHost_Root( h )` for a top-level
window).

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKSCROLL_REPEAT_DELAY = 400
const TKSCROLL_REPEAT_MS = 80
const TKSCROLL_MIN_THUMB = 20
const TKSCROLL_DEFAULT_THICKNESS = 12
const TKSCROLL_SYSTEM_WHEEL_LINES = 3
```

### Types

```freebasic
type TKSCROLLBAR_PAINTINFO
    b          as TK_PAINT ptr
    rcClient   as TKRECT
    rcThumb    as TKRECT              ' empty when no thumb is needed
    isHot      as boolean             ' the mouse is over the thumb
    isDragging as boolean
    hScrollBar as TK_WIDGET ptr       ' the bar, so the callback can find its owner
end type

type TKSCROLLBAR_STATE   ' per-instance state; reach it through the procedures

type tkScrollPaintSub as sub( byval p as TKSCROLLBAR_PAINTINFO ptr )
type tkScrollNotifySub as sub( byval hSB as TK_WIDGET ptr, byval newPos as integer )
```

### Procedures

```freebasic
function tkScrollBar_StepBy( byval pSB as TKSCROLLBAR_STATE ptr, byval nUnits as integer ) as boolean
function tkScrollBar_HandleWheelDelta( byval hSB as TK_WIDGET ptr, byval nDelta as integer ) as boolean
function tkScrollBar_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as integer, byval bVertical as boolean ) as TK_WIDGET ptr
function tkScrollBar_State( byval hSB as TK_WIDGET ptr ) as TKSCROLLBAR_STATE ptr
sub tkScrollBar_SetRange( byval hSB as TK_WIDGET ptr, byval nTotal as integer, byval nPage as integer, byval nPosition as integer )
function tkScrollBar_GetPos( byval hSB as TK_WIDGET ptr ) as integer
sub tkScrollBar_SetPos( byval hSB as TK_WIDGET ptr, byval nPosition as integer )
function tkScrollBar_NeedsThumb( byval hSB as TK_WIDGET ptr ) as boolean
function tkScrollBar_IsDragging( byval hSB as TK_WIDGET ptr ) as boolean
function tkScrollBar_GetThumbRect( byval hSB as TK_WIDGET ptr ) as TKRECT
sub tkScrollBar_SetColors( byval hSB as TK_WIDGET ptr, byval backclr as ulong, byval foreclr as ulong, byval foreclrhot as ulong )
sub tkScrollBar_SetDividerColor( byval hSB as TK_WIDGET ptr, byval clr as ulong, byval bShow as boolean = true )
sub tkScrollBar_ApplyTheme( byval hSB as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkScrollBar_UnpinColors( byval hSB as TK_WIDGET ptr )
sub tkScrollBar_PaintDefault( byval p as TKSCROLLBAR_PAINTINFO ptr )
sub tkScrollBar_SetPaintCallback( byval hSB as TK_WIDGET ptr, byval usersub as tkScrollPaintSub )
sub tkScrollBar_SetScrollCallback( byval hSB as TK_WIDGET ptr, byval usersub as tkScrollNotifySub )
sub tkScrollBar_SetWheelStep( byval hSB as TK_WIDGET ptr, byval nUnitsPerNotch as integer )
function tkScrollBar_GetWheelStep( byval hSB as TK_WIDGET ptr ) as integer
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
