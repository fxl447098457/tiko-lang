[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkScrollPanel**

# tkScrollPanel

Scrolls a page of ordinary child widgets that is taller than the space it is shown in.

tkScrollPanel is a viewport onto a page of controls, with a vertical scrollbar in a strip down
the right edge. Build the page from buttons, text boxes and the rest exactly as on a plain
window, lay them out once, and the panel scrolls by moving the whole page under the viewport.
Your widgets keep the coordinates you gave them. Use it for a settings page or any form that
runs past one screen.

The thumb appears only when the mouse is over the panel or the focus is inside it, but the strip
is always reserved, so nothing on the page shifts sideways. When the focus moves to a widget
below or above the viewport (by Tab or by `tkHost_SetFocus`), the panel scrolls it into view;
`tkScrollPanel_SetAutoScrollToFocus( h, false )` turns that off.

**Parent your widgets to `tkScrollPanel_GetPanel( h )`, never to the panel's own handle.** A
widget created on the panel itself sits over the viewport and never scrolls.

## Importing

```freebasic
#import "vendor/tkControls/tkScrollPanel"

using tkScrollPanel
using tkHost
using tkPaint
```

The module imports `tkHost`, `tkTheme`, `tkScrollBar` and `tkVScrollBar` publicly; the bar inside
the panel is a [tkVScrollBar](tkVScrollBar), returned by `tkScrollPanel_GetScrollBar`.

## Example

A layout callback places the page's widgets against the width it is handed and returns the
page height; the panel calls it whenever the viewport is resized. The rows here are
[tkButton](tkButton)s, so the program also imports `vendor/tkControls/tkButton`.

```freebasic
dim shared as TK_WIDGET ptr gScp, gRows(0 to 29)
dim shared as long gRowCount

function Page_Layout( byval hPanel as TK_WIDGET ptr, byval cxPanel as long ) as long
    dim as long y = tkHost_Scale( gHost, 16 )
    for i as long = 0 to gRowCount - 1
        tkWidget_SetPos( gRows(i), cxPanel - tkHost_Scale( gHost, 186 ), y, _
                         tkHost_Scale( gHost, 170 ), tkHost_Scale( gHost, 24 ) )
        y += tkHost_Scale( gHost, 34 )
    next
    return y + tkHost_Scale( gHost, 16 )       ' the page height
end function

gScp = tkScrollPanel_Create( tkHost_Root( gHost ), 100 )
tkScrollPanel_SetLayoutCallback( gScp, @Page_Layout )
tkScrollPanel_SetLineHeight( gScp, 34 )        ' one wheel line, unscaled
dim as TK_WIDGET ptr hPage = tkScrollPanel_GetPanel( gScp )
for i as long = 0 to 29
    gRows(i) = tkButton_Create( hPage, 2000 + i )
next
gRowCount = 30
tkWidget_SetPos( gScp, x, y, cx, cy )
```

Without a layout callback, place the widgets yourself and call `tkScrollPanel_SetContentHeight`,
or let `tkScrollPanel_AutoSizeContent` measure the visible children. `tkScrollPanel_SetPos`,
`tkScrollPanel_SetContentHeight` and the other setters are silent; the wheel, the thumb and the
focus scroll call the scroll callback. A paint callback draws the page; `tkScrollPanel_PaintDefault( p )` in it fills
the stock background first.

## Layout

- `tkScrollPanel_Create( hParent, CtrlID )` returns the viewport, created zero-sized; pass
  `tkHost_Root( h )` as the parent for a top-level window and place it with `tkWidget_SetPos`.
  It creates two widgets of its own: the page (`tkScrollPanel_GetPanel`, id `CtrlID + 1`) and
  the bar (`tkScrollPanel_GetScrollBar`, id `CtrlID + 2`). The bar's rectangle, visibility,
  range and position belong to the panel; never show, hide, move or size it yourself.
- The page is as wide as the viewport minus the strip (`tkScrollPanel_GetPanelWidth`), and as
  tall as the content height or the viewport, whichever is larger. Scrolling sets the page's
  top edge to minus the position and moves nothing on it, so a page of fifty widgets scrolls
  as cheaply as a page of five, and your layout code never sees the scroll position.
- Vertical only. Content wider than the page is clipped; re-flow to the width you are handed.
- Everything is pixels in page coordinates: content height, position, `EnsureVisible` margins.
  The strip width (`tkScrollPanel_SetScrollBarWidth`, default `TKSCROLL_DEFAULT_THICKNESS`, 12)
  and the wheel line height (default `TKSCROLLPANEL_LINE_HEIGHT`, 20) are given unscaled and
  scaled at use. On a display-scale change the content height and position are rescaled and the
  layout runs again.
- The layout callback runs on every resize, on `tkScrollPanel_Recalc`, when the strip width
  changes and after a scale change. It is handed the width the page is being given (the page
  already has it) and returns the page height, or 0 to keep the current content height.
  Calling `tkScrollPanel_SetContentHeight` inside it is safe: the value is recorded and the
  running pass finishes the job.
- The panel does not watch the page. After adding, removing, hiding or moving a widget outside
  a resize, call `tkScrollPanel_Recalc`. `tkScrollPanel_AutoSizeContent` sets the content
  height to the bottom of the lowest visible child of the page plus the padding (0, with no
  padding, when no child is visible) and returns it. Left at 0, nothing scrolls.
- The position is clamped to 0 .. content height − viewport height.
- `tkScrollPanel_EnsureVisible` makes the minimum scroll that brings a widget on the page, plus
  the margin, fully into view; one taller than the viewport is top-aligned. It returns false
  for a widget that is not on the page or when nothing needed to move, and never moves the focus.
- The page and your widgets on it are destroyed with the panel.

## The thumb

- The thumb shows when there is something to scroll **and** either the mouse is over the panel
  (a cursor resting on one of your widgets counts) or the focus is on the page. So a keyboard
  user Tabbing through the page still sees where they are. `tkScrollPanel_ShouldShow( bNeeds,
  bMouse, bFocus )` is that rule as a pure function; `tkScrollPanel_IsThumbVisible` reports the
  current state. During a thumb drag it stays shown even if the cursor leaves the strip.
- Only the bar hides. Its strip stays reserved and is painted in the page's background, so the
  empty strip is invisible and right-aligned widgets never jitter as the mouse comes and goes.
- The rule is re-checked on mouse moves over the panel and when the mouse leaves, and polled
  every `TKSCROLLPANEL_REVEAL_MS` (100 ms) while there is something to scroll and the panel is
  visible, so the thumb can lag the cursor by up to 100 ms. The poll is the panel's timer
  `TKSCROLLPANEL_TIMER_REVEAL`; don't start a timer of your own with that id on the panel.
  Hiding the panel stops the poll and hides the thumb.
- The same tick makes the focus-into-view scroll, on a focus **change** only: a user who
  scrolls the focused widget off screen does not have it pulled back on the next tick.

## Mouse wheel

- One notch scrolls `TKSCROLL_SYSTEM_WHEEL_LINES` (3) times the line height; set the line
  height to your row pitch (`tkScrollPanel_SetLineHeight`) and a notch moves whole rows.
  Sub-notch deltas from a trackpad accumulate rather than being dropped.
- The wheel scrolls over the page, over your widgets that do not take it themselves (it
  bubbles up to the page), over the empty strip and over the bar, all by the same step. A
  purely sideways wheel passes on to the panel's parent.
- `tkScrollPanel_HandleWheelDelta( h, nDelta )` feeds a delta in 120ths of a notch, positive
  scrolling up, and notifies as a real wheel does.

## Callbacks

- **Paint** draws the page **instead of** the stock flat fill, so it must fill the background
  itself; `tkScrollPanel_PaintDefault( p )` does that. `p->b` is the page's paint buffer for
  this repaint. `p->rcClient` is the whole page in page coordinates, not the visible slice:
  draw section rules or bands at the coordinates your layout recorded and only the visible
  slice reaches the screen. `p->nPos` is the scroll position, for content that wants it.
- **Message** observes the mouse on both the page and the viewport (`hFrom` says which):
  `TKM_MOUSEWHEEL`, `TKM_LBUTTONDOWN` / `TKM_LBUTTONUP`, `TKM_RBUTTONDOWN` / `TKM_RBUTTONUP` and
  `TKM_MOUSEMOVE`, with `x`, `y` and `wheelY`. Returning true from a wheel message stops the
  panel scrolling; for the others the return value is ignored. The panel takes no capture and
  keeps no press state. Mouse input over your own widgets goes to those widgets.
- **Scroll** reports user action only: the wheel, a thumb drag or track click, and the
  focus-into-view scroll. It fires after the page has moved, so `tkScrollPanel_GetPos` already
  equals `newPos`. `tkScrollPanel_SetPos`, `ScrollBy`, `SetContentHeight`, `AutoSizeContent`,
  `EnsureVisible` and `Recalc` never fire it, so they are safe to call from inside the handler.

The panel forwards nothing from the widgets on the page: each reports through its own
callbacks and takes its font through its own setter.

## Colours and theme

- The panel has two colours. The background fills the page and the strip, and is also the
  bar's background; the foreground is not drawn by the panel at all. `tkScrollPanel_GetColors`
  reads both back so your own widgets can match the page.
- They start from the current theme: the page from `Window` / `Text`, the bar from `Window`
  (background), `Border` (thumb) and `TextDisabled` (thumb while hovered or dragged).
- `tkScrollPanel_SetColors` also sets the bar's background to the new page background, so call
  it before `tkScrollPanel_SetScrollBarColors`. A bar background that differs from the page
  shows as a visible gutter down the right edge.
- Both setters pin the colours: a theme change then leaves them alone. Unpinned, the panel
  re-applies the theme whenever it changes. `tkScrollPanel_UnpinColors` returns to the theme
  and applies it at once.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKSCROLLPANEL_REVEAL_MS = 100
const TKSCROLLPANEL_LINE_HEIGHT = 20 ' default wheel unit, unscaled (scaled at use)
const TKSCROLLPANEL_TIMER_REVEAL = TK_TIMER_APP
```

### Types

```freebasic
type SCP_PAINTINFO
    hScrollPanel as TK_WIDGET ptr
    hPanel       as TK_WIDGET ptr     ' the page, being painted
    b            as TK_PAINT ptr
    rcClient     as TKRECT            ' the WHOLE page, page coordinates
    nPos         as long
end type

type SCP_MESSAGEINFO
    hScrollPanel as TK_WIDGET ptr
    hPanel       as TK_WIDGET ptr
    hFrom        as TK_WIDGET ptr     ' which of the two it arrived on
    msg          as long              ' TKM_*
    x            as single
    y            as single
    wheelY       as single
end type

type TKSCROLLPANEL_STATE   ' per-instance state; reach it through the procedures

type SCP_PaintCallbackSub as sub( byval p as SCP_PAINTINFO ptr )
type SCP_MessageCallbackFunc as function( byval m as SCP_MESSAGEINFO ptr ) as boolean
type SCP_LayoutCallbackFunc as function( byval hPanel as TK_WIDGET ptr, byval cxPanel as long ) as long
type SCP_ScrollCallbackSub as sub( byval hScrollPanel as TK_WIDGET ptr, byval newPos as long )
```

### Procedures

```freebasic
function tkScrollPanel_ShouldShow( byval bNeeds as boolean, byval bMouse as boolean, byval bFocus as boolean ) as boolean
function tkScrollPanel_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkScrollPanel_GetPanel( byval hScp as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkScrollPanel_GetScrollBar( byval hScp as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkScrollPanel_SetContentHeight( byval hScp as TK_WIDGET ptr, byval nHeight as long )
function tkScrollPanel_GetContentHeight( byval hScp as TK_WIDGET ptr ) as long
function tkScrollPanel_AutoSizeContent( byval hScp as TK_WIDGET ptr, byval bottomPadding as long = 0 ) as long
function tkScrollPanel_GetPos( byval hScp as TK_WIDGET ptr ) as long
sub tkScrollPanel_SetPos( byval hScp as TK_WIDGET ptr, byval nPosition as long )
function tkScrollPanel_ScrollBy( byval hScp as TK_WIDGET ptr, byval nDelta as long ) as boolean
function tkScrollPanel_EnsureVisible( byval hScp as TK_WIDGET ptr, byval hChild as TK_WIDGET ptr, byval nMargin as long = 0 ) as boolean
function tkScrollPanel_HandleWheelDelta( byval hScp as TK_WIDGET ptr, byval nDelta as long ) as boolean
sub tkScrollPanel_SetLineHeight( byval hScp as TK_WIDGET ptr, byval nHeight as long )
function tkScrollPanel_GetLineHeight( byval hScp as TK_WIDGET ptr ) as long
sub tkScrollPanel_SetAutoScrollToFocus( byval hScp as TK_WIDGET ptr, byval bEnable as boolean )
function tkScrollPanel_GetAutoScrollToFocus( byval hScp as TK_WIDGET ptr ) as boolean
function tkScrollPanel_GetViewportHeight( byval hScp as TK_WIDGET ptr ) as long
function tkScrollPanel_GetPanelWidth( byval hScp as TK_WIDGET ptr ) as long
function tkScrollPanel_IsThumbVisible( byval hScp as TK_WIDGET ptr ) as boolean
sub tkScrollPanel_Recalc( byval hScp as TK_WIDGET ptr )
sub tkScrollPanel_SetColors( byval hScp as TK_WIDGET ptr, byval backclr as ulong, byval foreclr as ulong )
sub tkScrollPanel_GetColors( byval hScp as TK_WIDGET ptr, byref backclr as ulong, byref foreclr as ulong )
sub tkScrollPanel_SetScrollBarColors( byval hScp as TK_WIDGET ptr, byval backclr as ulong, byval foreclr as ulong, byval foreclrhot as ulong )
sub tkScrollPanel_ApplyTheme( byval hScp as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkScrollPanel_UnpinColors( byval hScp as TK_WIDGET ptr )
sub tkScrollPanel_SetScrollBarWidth( byval hScp as TK_WIDGET ptr, byval nWidth as long )
sub tkScrollPanel_PaintDefault( byval p as SCP_PAINTINFO ptr )
sub tkScrollPanel_SetPaintCallback( byval hScp as TK_WIDGET ptr, byval usersub as SCP_PaintCallbackSub )
sub tkScrollPanel_SetMessageCallback( byval hScp as TK_WIDGET ptr, byval userfunc as SCP_MessageCallbackFunc )
sub tkScrollPanel_SetLayoutCallback( byval hScp as TK_WIDGET ptr, byval userfunc as SCP_LayoutCallbackFunc )
sub tkScrollPanel_SetScrollCallback( byval hScp as TK_WIDGET ptr, byval usersub as SCP_ScrollCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
