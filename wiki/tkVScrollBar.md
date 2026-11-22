[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkVScrollBar**

# tkVScrollBar

Draws a vertical scrollbar that you size, feed a range, and listen to.

tkVScrollBar is a flat vertical track with a flat thumb and no arrow buttons. You tell it the
total, the page and the position; it tells you when the user drags, pages or wheels it. It does
not scroll anything itself, so use it beside content you already draw: a list, a canvas, a
preview. For a panel that scrolls child content for you, see [tkScrollPanel](tkScrollPanel).

It is a thin module over [tkScrollBar](tkScrollBar), which describes the behaviour both bars
share: the range model, paging and auto-repeat, the minimum thumb, the wheel and theme colours.
`tkVScrollBar_SetDividerColor` is its own: a one-pixel line down the bar's left edge, separating
it from the content.

## Importing

```freebasic
#import "vendor/tkControls/tkVScrollBar"

using tkVScrollBar
using tkHost
```

The module imports `tkScrollBar`, `tkHost` and `tkTheme` publicly.

## Example

A bar down the right edge of a content widget, which forwards its own wheel to the bar.

```freebasic
dim shared as TK_WIDGET ptr gVS

sub VS_Scroll( byval hSB as TK_WIDGET ptr, byval newPos as integer )
    gTopLine = newPos              ' the user moved the bar: redraw the content from here
    tkHost_Invalidate( gHost )
end sub

function Content_Proc( byval w as TK_WIDGET ptr, byval m as TK_MSG ptr ) as boolean
    if m->msg = TKM_MOUSEWHEEL then
        tkVScrollBar_HandleWheelDelta( gVS, cint( m->wheelY * 120 ) )
        return true
    end if
    return false
end function

gVS = tkVScrollBar_Create( tkHost_Root( gHost ), 1002 )
tkWidget_SetPos( gVS, pw - tkHost_Scale( gHost, TKVSCROLL_DEFAULT_WIDTH ), 0, _
                 tkHost_Scale( gHost, TKVSCROLL_DEFAULT_WIDTH ), ph )
tkVScrollBar_SetRange( gVS, nLines, nVisibleLines, 0 )
tkVScrollBar_SetScrollCallback( gVS, @VS_Scroll )
```

`tkVScrollBar_SetRange` and `tkVScrollBar_SetPos` are silent; only the user's actions call the
scroll callback.

## How it behaves

The full description is on [tkScrollBar](tkScrollBar); in short, for the vertical bar:

- `pos` is the index of the topmost visible unit, a whole number clamped to
  `0 .. total - page`. When everything fits there is no thumb and `tkVScrollBar_NeedsThumb` is
  false: hiding the bar then is your decision, and the bar never sizes, places or hides itself.
- The thumb spans the bar's full width; its height is proportional to `page / total`, but never
  less than `TKVSCROLL_MIN_THUMB` (scaled).
- Dragging the thumb takes the mouse capture. A track click pages by exactly `page` toward the
  click and repeats while held (`TKVSCROLL_REPEAT_DELAY`, then every `TKVSCROLL_REPEAT_MS` ms)
  until the thumb reaches the cursor. `tkVScrollBar_IsDragging` is true while either is live.
- Only the vertical wheel is taken; a horizontal swipe passes on to the parent. One notch moves
  the wheel step, or 3 units when the step is 0; partial notches accumulate.
  `tkVScrollBar_HandleWheelDelta` takes 120ths of a notch, and a **positive** delta scrolls
  **up**, decreasing the position: pass `wheelY * 120` unchanged.
- The bar takes no focus and no keys. Home, End, PgUp and PgDn are yours, via
  `tkVScrollBar_SetPos`.
- Colours follow the theme (track `Window`, thumb `Border`, active thumb `TextDisabled`,
  divider `Divider`) until `tkVScrollBar_SetColors` or `tkVScrollBar_SetDividerColor` pins
  them; `tkVScrollBar_UnpinColors` hands them back. The divider is off until you show it with
  `tkVScrollBar_SetDividerColor( hSB, clr )`.
- A paint callback draws the whole bar instead of the built-in painter; call
  `tkVScrollBar_PaintDefault( p )` in it to draw the stock bar first.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKVSCROLL_REPEAT_DELAY = TKSCROLL_REPEAT_DELAY
const TKVSCROLL_REPEAT_MS = TKSCROLL_REPEAT_MS
const TKVSCROLL_MIN_THUMB = TKSCROLL_MIN_THUMB
const TKVSCROLL_DEFAULT_WIDTH = TKSCROLL_DEFAULT_THICKNESS
```

### Types

```freebasic
type TKVSCROLLBAR_PAINTINFO as TKSCROLLBAR_PAINTINFO
type VScrollPaintCallbackSub as tkScrollPaintSub
type VScrollCallbackSub as tkScrollNotifySub
```

### Procedures

```freebasic
function tkVScrollBar_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as integer ) as TK_WIDGET ptr
sub tkVScrollBar_SetRange( byval hSB as TK_WIDGET ptr, byval nTotal as integer, byval nPage as integer, byval nPosition as integer )
function tkVScrollBar_GetPos( byval hSB as TK_WIDGET ptr ) as integer
sub tkVScrollBar_SetPos( byval hSB as TK_WIDGET ptr, byval nPosition as integer )
function tkVScrollBar_HandleWheelDelta( byval hSB as TK_WIDGET ptr, byval nDelta as integer ) as boolean
sub tkVScrollBar_SetWheelStep( byval hSB as TK_WIDGET ptr, byval nUnitsPerNotch as integer )
function tkVScrollBar_GetWheelStep( byval hSB as TK_WIDGET ptr ) as integer
function tkVScrollBar_NeedsThumb( byval hSB as TK_WIDGET ptr ) as boolean
function tkVScrollBar_IsDragging( byval hSB as TK_WIDGET ptr ) as boolean
function tkVScrollBar_GetThumbRect( byval hSB as TK_WIDGET ptr ) as TKRECT
sub tkVScrollBar_SetColors( byval hSB as TK_WIDGET ptr, byval backclr as ulong, byval foreclr as ulong, byval foreclrhot as ulong )
sub tkVScrollBar_SetDividerColor( byval hSB as TK_WIDGET ptr, byval clr as ulong, byval bShow as boolean = true )
function tkVScrollBar_GetDividerColor( byval hSB as TK_WIDGET ptr ) as ulong
sub tkVScrollBar_ApplyTheme( byval hSB as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkVScrollBar_UnpinColors( byval hSB as TK_WIDGET ptr )
sub tkVScrollBar_PaintDefault( byval p as TKVSCROLLBAR_PAINTINFO ptr )
sub tkVScrollBar_SetPaintCallback( byval hSB as TK_WIDGET ptr, byval usersub as VScrollPaintCallbackSub )
sub tkVScrollBar_SetScrollCallback( byval hSB as TK_WIDGET ptr, byval usersub as VScrollCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkScrollBar](tkScrollBar), [tkHScrollBar](tkHScrollBar), [tkScrollPanel](tkScrollPanel)
