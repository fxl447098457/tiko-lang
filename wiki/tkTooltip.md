[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTooltip**

# tkTooltip

Shows an owner-drawn tooltip for a widget after the mouse rests on it.

tkTooltip is a themed hover tip: an optional icon glyph and title over a word-wrapped
message, as a plain rounded rectangle (`TIP_STYLE_RECT`) or a balloon with a stem pointing at its
anchor (`TIP_STYLE_BALLOON`). Attach one to any widget and it waits for the mouse to rest there,
shows after the initial delay, fades in, hides after the auto-pop delay or when the mouse leaves
or a button is pressed. Only one tip is on screen at a time.

Every tkControls control that has tooltips already owns a tip, created with the control. Set its
text with the control's own setter (`tkButton_SetTooltipText`, for example) and reach the tip for
anything else (title, glyph, style, colours) with the control's `..._GetTooltipHandle`. Create a
tip yourself with `tkTooltip_Create` only for a widget of your own.

The handle is a `TK_TIP ptr`, not a widget. The tip opens its own small transparent window each
time it shows and closes it when it hides. It detaches itself when its widget is destroyed, and
follows the theme until `tkTooltip_SetColors` pins its colours.

## Importing

```freebasic
#import "vendor/tkControls/tkTooltip"

using tkTooltip
using tkHost
```

The module imports `tkHost` and `tkTheme` publicly. Every control with tooltips imports
`tkTooltip` itself, so a program that only sets tooltip text through a control needs no import.

## Example

A tip on a widget of your own, with a title and an icon, its text worked out when it shows:

```freebasic
function Canvas_TipText( byval hTooltip as TK_TIP ptr, byval hAttached as TK_WIDGET ptr, byval idx as long ) as ustring
    return "Zoom " & gZoom & "%"           ' called each time the tip is about to show
end function

dim as TTF_Font ptr fText  = tkHost_OpenFont( gHost, tkHost_FontDir() & TK_FONT_UI, 9 )
dim as TTF_Font ptr fTitle = tkHost_OpenFont( gHost, tkHost_FontDir() & TK_FONT_UI_BOLD, 9 )
dim as TTF_Font ptr fGlyph = tkHost_OpenFont( gHost, tkHost_FontDir() & TK_FONT_ICONS, 12 )

dim as TK_TIP ptr tip = tkTooltip_Create( hCanvas )     ' created AND attached
tkTooltip_SetFonts( tip, fText, fTitle, fGlyph )
tkTooltip_SetTitle( tip, "Canvas" )
tkTooltip_SetGlyph( tip, wchr( TK_ICON_INFO ) )
tkTooltip_SetStyle( tip, TIP_STYLE_BALLOON )
tkTooltip_SetTooltipCallback( tip, @Canvas_TipText )
' ...
tkTooltip_Destroy( tip )                  ' you own a tip you created
```

To give every tip the same look, set the process defaults before creating the controls:
`tkTooltip_SetDefaultFonts`, `tkTooltip_SetDefaultStyle`, `tkTooltip_SetDefaultColors`,
`tkTooltip_SetDefaultMaxWidth` and `tkTooltip_SetDefaultDelays` apply to each tip created
afterwards. `tkTooltip_ApplyDefaults` applies them to a tip that already exists.

## tkTipHost

The same module holds **tkTipHost**, the helper each control uses to own its tip:
`TKTIPHOST_STATE` and the `tkTipHost_*` procedures. There is no separate module to import;
`tkTipHost_*` comes with `using tkTooltip`. You need it only when writing a control of your own:
keep a `TKTIPHOST_STATE` in the control's state, call `tkTipHost_Ensure( @st, hCtrl, @TipText )`
at create and `tkTipHost_Destroy( @st )` when the control is destroyed. Delays set with
`tkTipHost_SetDelay( @st, TK_TIPDELAY_INITIAL, ms )` before the tip exists are kept and applied
when it does. `tkTipHost_TrackShow` / `tkTipHost_TrackHide` show text at once against a
rectangle, skipping the hover delay, for a tip that the control drives itself.

## Concepts

### It sizes and places itself

A tip is not a rectangle you lay out. Its **size** comes from its content (text, title, glyph,
padding, border, stem band) and its **position** from the cursor or from an anchor rectangle you
pass to `tkTooltip_ShowForRect`, in the attached widget's coordinates. Placement is clamped into
the work area of the display (`tkHost_WorkRect`), and when there is no room below the anchor the
tip **flips above it** rather than being pushed up over it. The tip window is not click-through:
at the cursor it is placed clear of the pointer, and moving onto it leaves the widget and hides
it. On Wayland the compositor does the clamping.

`tkTooltip_GetIdealSize` and `tkTooltip_GetPartRect( tip, TIP_PART_* )` report the size and the
regions for the current content. Both resolve the text first if it has not been, which can run
your tooltip callback.

### Size formula

```
contentW = max( titleRow, message )
    titleRow = glyphCell + (glyphGap if both a glyph and a title) + title
    message  = wrapped to (maxWidth - 2*padX - 2*border) when a max width is set,
               natural width otherwise

width  = contentW + 2*padX + 2*border
height = titleRowHeight + (titleGap if both bands present) + messageHeight
         + 2*padY + 2*border
         + stemHeight   (TIP_STYLE_BALLOON only)
```

`tkTooltip_SetMaxWidth` bounds the message wrap; 0 turns wrapping off, so only line breaks in the
text break lines. The width is a `max()` over the bands, so a title longer than the cap
legitimately makes the tip wider rather than being clipped.

### The glyph cell is declared, not measured

`tkTooltip_SetGlyphCell( tip, cell, gap )` states how much room the icon gets. Nothing is
measured, so a glyph missing from the font, or a different size from the last one, cannot shift
the text. The gap is spent only when a title sits beside the glyph.

### It watches the hover; it does not intercept your widget

The tip watches its widget through a hidden, zero-size child of it, which carries the tip's clock
and receives the widget's scale and theme changes and its destruction. Your widget's own
messages are untouched. "Over" means the window's hot widget is the attached one or a descendant
of it (or, while the mouse is captured, that the cursor is inside it). The clock runs only while
the cursor is over an attached widget or a tip is up or fading, so an idle window costs nothing.

The tip cannot see your widget's *items*. A per-item tip calls `tkTooltip_SetToolIndex( tip, idx )`
as the hovered item changes (-1 for a whole-widget tip); a set to the current value costs nothing,
so it is safe from every mouse move. A real change hides a visible tip at once and makes the next
one a new offer.

### Text resolution order

1. `tkTooltip_SetText`: if it is non-empty, that is the text.
2. Otherwise the tooltip callback, if one is set.
3. Otherwise no tip appears.

There is no fallback to the widget's caption: return it from the callback if you want it. Setting
the text or the callback discards the resolved text, so the next show re-reads it.

### When a tip shows and hides

The cursor must rest on the widget, within the move tolerance, for the initial delay. A tip shown
and dismissed a moment ago comes back after the shorter reshow delay instead. A tip that is up
does not follow the cursor: moving within the widget neither moves nor dismisses it. It hides when
the cursor leaves the widget, when a mouse button is pressed, when the tool index changes, or after
the auto-pop delay (0: never). After a click or an auto-pop, the tip stays suppressed until the
cursor leaves the widget and comes back.

Shows and hides fade over the fade time (0: instant); a fade is interruptible, and a hide during a
fade-in continues down from the current opacity. On Wayland the tip appears at once.

### Programmatic and user-driven shows both notify

`tkTooltip_Show` (at the cursor) and `tkTooltip_ShowForRect` skip the dwell, and the clock still
auto-hides what they put up; `tkTooltip_Hide` hides with a fade. The show callback reports both
kinds. Its showing edge is a veto: return FALSE and no tip appears, and no hiding edge follows.

## Behaviour and limits

- **Only one tip is visible at a time**, process-wide. Showing one hides any other.
- **The stem is always vertical.** A tip goes above or below its anchor, never beside it.
- **The stem is dropped, not shrunk, when it will not fit.** A tip too narrow to seat it clear of
  the rounded corners draws as a plain rounded rectangle; so does a stem narrower than 2 or shorter
  than 1.
- **A refused show is not retried during the same hover.** Returning FALSE from the show callback,
  or `""` from the tooltip callback, suppresses the tip until the cursor leaves, so a callback is
  consulted once per hover. Changing the tool index clears the suppression.
- **Fonts are borrowed.** A title or glyph font of 0 falls back to the text font, and with no text
  font the host's default is used. Keep a font alive while any tip uses it.
- **Timing is per tip.** Each tip has its own delays, fade time and move tolerance.
- **The tip detaches itself when its widget is destroyed**, hiding first. `tkTooltip_Attach`
  re-points a tip at another widget (hiding it first) and `tkTooltip_Detach` stops it watching; a
  tip you created is yours to `tkTooltip_Destroy`.

## Appearance

| Setter | Behaviour |
|---|---|
| `tkTooltip_SetStyle` | `TIP_STYLE_RECT` or `TIP_STYLE_BALLOON`. The balloon adds the stem height to the tip and nothing to its width |
| `tkTooltip_SetMaxWidth` | The wrap bound, above; 0 for no wrapping |
| `tkTooltip_SetPadding( x, y )` | A negative value leaves that axis alone |
| `tkTooltip_SetCurvature` | The corner **diameter**; negatives clamp to 0 (square) |
| `tkTooltip_SetBorderWidth` | Negatives clamp to 0 (no frame). The pen is scaled when it is drawn, so do not pre-scale it |
| `tkTooltip_SetStemSize( w, h )` | A negative value leaves that axis alone |
| `tkTooltip_SetGlyphCell( cell, gap )` | A negative value leaves that field alone |
| `tkTooltip_SetInitialDelay`, `SetAutoPopDelay`, `SetReshowDelay`, `SetFadeTime`, `SetMoveTolerance` | Milliseconds (pixels for the tolerance); negatives clamp to 0 |

The geometry defaults (`TKTOOLTIP_DEFAULT_*`) are scaled when the tip is created; setters take
pixels afterwards, so scale your literals with `tkHost_Scale`. When the host's scale changes, the
tip rescales every stored size, the max width and the move tolerance, but not the border width.
The delays default to 500, 5000 and 100 ms (initial, auto-pop, reshow) and the fade to
`TKTOOLTIP_DEFAULT_FADEMS`.

### Process-wide defaults

A control creates its tip itself, so the way to style every tip is the defaults:
`tkTooltip_SetDefaultColors`, `SetDefaultFonts`, `SetDefaultStyle`, `SetDefaultMaxWidth` and
`SetDefaultDelays`, called once before the controls are created. Each is armed independently: a
field never set keeps the tip's own default, and a negative argument to `SetDefaultDelays` leaves
that delay alone, so "change only the hover time" is one call. `tkTooltip_ClearDefaults` disarms
them all, and `tkTooltip_ApplyDefaults( tip )` applies the armed ones to an existing tip. Default
fonts are borrowed by every tip created afterwards; they must outlive them all. Default colours are
applied as set colours, so a tip given them does not follow theme changes.

## Colours

`TKTOOLTIP_COLORS` has five fields, one per surface; a tip is never interactive, so there are no
hot, pressed or disabled variants. A tip takes its colours from the current theme and follows every
theme change until `tkTooltip_SetColors` pins them; `tkTooltip_UnpinColors` hands it back to the
theme and applies it at once. `tkTooltip_ThemeColors` gives the mapping as a value.

| Field | Paints | Theme role |
|---|---|---|
| `BackColor` | The body fill and the stem's interior | `Popup` |
| `BorderColor` | The frame and the stem's two sloped edges | `Border` |
| `ForeColor` | The message | `PopupText` |
| `TitleColor` | The title line | `TextStrong` |
| `GlyphColor` | The icon glyph | `Accent` |

The built-in painter draws, in order: the body fill, the frame, the stem fill, the stem edges, the
glyph, the title (ellipsised if it must be) and the message. The stem is filled **after** the frame,
reaching a little into the body, so the frame's edge does not cut across the stem's base and the
balloon reads as one shape.

## Callbacks

All are optional; passing 0 clears one.

### Tooltip

```freebasic
type TIP_TooltipCallbackFunc as function( byval hTooltip as TK_TIP ptr, byval hAttached as TK_WIDGET ptr, byval idx as long ) as ustring
```

Supplies the message on demand: consulted **only** when the tip has no text of its own, and only
when a tip is about to appear. `idx` is the current tool index, or -1. Return `""` for no tip.

### Show

```freebasic
type TIP_ShowCallbackFunc as function( byval hTooltip as TK_TIP ptr, byval hAttached as TK_WIDGET ptr, byval idx as long, byval bShowing as boolean ) as boolean
```

The showing edge runs after the text is resolved and the tip sized, before anything reaches the
screen: return FALSE to suppress the tip for the rest of the hover. The hiding edge's result is
ignored. Both edges fire for programmatic shows and hides; a vetoed show has no hiding edge.

### Paint

```freebasic
type TIP_PaintCallbackSub as sub( byval p as TKTOOLTIP_PAINTINFO ptr )
```

Draws the whole tip instead of the built-in painter, through `p->b`. Nothing has been drawn when
you are called: the window is transparent, and the body is the shape.

- Paint the body against `p->rcBody`, not `p->rcClient`, which includes the stem band.
- Draw the message with `p->nTextFlags` and the text font: the tip was sized by measuring with
  both, and anything else clips.
- Stroke a frame with an outline call (`PaintRoundOutline`); a border-rect primitive fills before
  it strokes and erases what is beneath. `tkTooltip_CountRenderedTones` and
  `tkTooltip_HashRenderedPart` render the tip offscreen through the real painter and read back one
  `TIP_PART_*` rect, so you can check a painter: count tones in a part, or compare hashes across a
  change (isolate the change: if it also resizes the tip, the part moves).

| Field | Meaning |
|---|---|
| `hTooltip`, `hAttached` | The tip and the widget it serves |
| `b` | The paint context for this repaint |
| `rcClient` | The whole window, including the stem band |
| `rcBody` | The rounded frame: `rcClient` less the stem band on whichever edge the stem leaves |
| `rcGlyph` | The declared glyph cell; empty without a glyph |
| `rcTitle` | The title span, out to the content's right edge; empty without a title |
| `rcText` | The message span; empty without a message |
| `ptStem(0 to 2)` | The stem's vertices: base, apex, base |
| `bHasStem` | FALSE for `TIP_STYLE_RECT`, and when the stem does not fit |
| `bStemOnTop` | TRUE when the tip is below its anchor and the stem points up |
| `wszText` | The **resolved** message |
| `wszTitle`, `wszGlyph` | The title and the glyph |
| `nStyle`, `nCurvature`, `nBorderWidth` | The style, the corner diameter and the unscaled border width |
| `nToolIndex` | -1 for a whole-widget tip |
| `nTextFlags` | The `TK_DT_*` flags the message was measured with |

### Pure helpers

`tkTooltip_ComputeOrigin` (where a tip of a given size goes against an anchor, clamped and
flipped), `tkTooltip_StemOnTop`, `tkTooltip_ComputeStem` (the stem's vertices, kept clear of the
corners; FALSE when it does not fit), `tkTooltip_ComputeAlpha` (the fade ramp, 0 to 255) and
`tkTooltip_ShouldShow` (the decision table) are the arithmetic behind placement and timing,
exposed so you can predict it. `tkTooltip_TickForTest` drives one tick of the dwell, hide and fade
state machine with injected inputs; it is for tests, not for application code.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKTOOLTIP_DEFAULT_PADX = 10
const TKTOOLTIP_DEFAULT_PADY = 7
const TKTOOLTIP_DEFAULT_CURVATURE = 6 ' corner ellipse DIAMETER
const TKTOOLTIP_DEFAULT_STEMW = 14
const TKTOOLTIP_DEFAULT_STEMH = 7
const TKTOOLTIP_DEFAULT_GLYPHCELL = 20
const TKTOOLTIP_DEFAULT_GLYPHGAP = 8
const TKTOOLTIP_DEFAULT_TITLEGAP = 4
const TKTOOLTIP_DEFAULT_MOVETOL = 3
const TKTOOLTIP_DEFAULT_FADEMS = 120
const TKTOOLTIP_CLOCK_IDLE_MS = 100
const TKTOOLTIP_CLOCK_FADE_MS = 15

enum
    TIP_STYLE_RECT    = 0
    TIP_STYLE_BALLOON = 1
end enum

enum
    TIP_ALIGN_CURSOR = 0         ' below-right of the cursor, cleared by the cursor's height
    TIP_ALIGN_BELOW  = 1         ' below the anchor, flipping above when there is no room
    TIP_ALIGN_ABOVE  = 2         ' above the anchor, flipping below when there is no room
end enum

enum
    TIP_PART_CLIENT = 0
    TIP_PART_BODY   = 1
    TIP_PART_GLYPH  = 2
    TIP_PART_TITLE  = 3
    TIP_PART_TEXT   = 4
    TIP_PART_STEM   = 5
end enum

enum
    TK_TIPDELAY_INITIAL = 0
    TK_TIPDELAY_AUTOPOP
    TK_TIPDELAY_RESHOW
end enum
```

### Types

```freebasic
type TKTOOLTIP_COLORS
    BackColor    as ulong = &hFF2D323Aul    ' ( 45, 50, 58)
    BorderColor  as ulong = &hFF4E545Eul    ' ( 78, 84, 94)
    ForeColor    as ulong = &hFFD4D9E2ul    ' (212,217,226)
    TitleColor   as ulong = &hFFFFFFFFul
    GlyphColor   as ulong = &hFF569CD6ul    ' ( 86,156,214)
end type

type TKTOOLTIP_PAINTINFO
    hTooltip     as TK_TIP ptr
    hAttached    as TK_WIDGET ptr
    b            as TK_PAINT ptr
    rcClient     as TKRECT              ' the whole window, INCLUDING the stem band
    rcBody       as TKRECT              ' the rounded frame (rcClient minus the stem band)
    rcGlyph      as TKRECT
    rcTitle      as TKRECT
    rcText       as TKRECT
    ptStem(0 to 2) as TKPOINT
    bHasStem     as boolean
    bStemOnTop   as boolean
    wszText      as ustring             ' the RESOLVED message
    wszTitle     as ustring
    wszGlyph     as ustring
    nStyle       as long
    nCurvature   as long
    nBorderWidth as long
    nToolIndex   as long
    nTextFlags   as long                ' the TK_DT_* flags the message was MEASURED with
end type

type TK_TIP_   ' per-instance state; reach it through the procedures

type TKTIPHOST_STATE   ' per-instance state; reach it through the procedures

type TK_TIP as TK_TIP_
type TIP_PaintCallbackSub as sub( byval p as TKTOOLTIP_PAINTINFO ptr )
type TIP_TooltipCallbackFunc as function( byval hTooltip as TK_TIP ptr, byval hAttached as TK_WIDGET ptr, byval idx as long ) as ustring
type TIP_ShowCallbackFunc as function( byval hTooltip as TK_TIP ptr, byval hAttached as TK_WIDGET ptr, byval idx as long, byval bShowing as boolean ) as boolean
```

### Procedures

```freebasic
function tkTooltip_ComputeOrigin( byref rcAnchor as TKRECT, byval tipW as long, byval tipH as long, byref rcWork as TKRECT, byval nAlign as long, byval nCursorOffset as long ) as TKPOINT
function tkTooltip_StemOnTop( byref rcAnchor as TKRECT, byref ptOrigin as TKPOINT, byval nAlign as long ) as boolean
function tkTooltip_ComputeStem( byval cxClient as long, byval cyClient as long, byval bStemOnTop as boolean, byval nStemW as long, byval nStemH as long, byval nTargetX as long, byval nCurvature as long, byval pts as TKPOINT ptr ) as boolean
function tkTooltip_ComputeAlpha( byval nElapsed as long, byval nFadeMs as long, byval bFadingIn as boolean ) as long
function tkTooltip_ShouldShow( byval bOver as boolean, byval bResting as boolean, byval bHasText as boolean, byval bButtonDown as boolean, byval bSuppressed as boolean ) as boolean
function tkTooltip_Create( byval hAttach as TK_WIDGET ptr ) as TK_TIP ptr
sub tkTooltip_Destroy( byval hTooltip as TK_TIP ptr )
sub tkTooltip_Attach( byval hTooltip as TK_TIP ptr, byval hAttach as TK_WIDGET ptr )
sub tkTooltip_Detach( byval hTooltip as TK_TIP ptr )
function tkTooltip_GetAttached( byval hTooltip as TK_TIP ptr ) as TK_WIDGET ptr
sub tkTooltip_SetText( byval hTooltip as TK_TIP ptr, byval wszText as ustring )
function tkTooltip_GetText( byval hTooltip as TK_TIP ptr ) as ustring
sub tkTooltip_SetTitle( byval hTooltip as TK_TIP ptr, byval wszTitle as ustring )
function tkTooltip_GetTitle( byval hTooltip as TK_TIP ptr ) as ustring
sub tkTooltip_SetGlyph( byval hTooltip as TK_TIP ptr, byval wszGlyph as ustring )
function tkTooltip_GetGlyph( byval hTooltip as TK_TIP ptr ) as ustring
sub tkTooltip_SetToolIndex( byval hTooltip as TK_TIP ptr, byval idx as long )
function tkTooltip_GetToolIndex( byval hTooltip as TK_TIP ptr ) as long
sub tkTooltip_SetColors( byval hTooltip as TK_TIP ptr, byval pColors as TKTOOLTIP_COLORS ptr )
sub tkTooltip_GetColors( byval hTooltip as TK_TIP ptr, byval pColors as TKTOOLTIP_COLORS ptr )
function tkTooltip_ThemeColors( byref t as TKTHEME_COLORS ) as TKTOOLTIP_COLORS
sub tkTooltip_ApplyTheme( byval hTooltip as TK_TIP ptr, byref t as TKTHEME_COLORS )
sub tkTooltip_UnpinColors( byval hTooltip as TK_TIP ptr )
sub tkTooltip_SetFonts( byval hTooltip as TK_TIP ptr, byval fText as TTF_Font ptr, byval fTitle as TTF_Font ptr = 0, byval fGlyph as TTF_Font ptr = 0 )
sub tkTooltip_ApplyFonts( byval hTooltip as TK_TIP ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkTooltip_Rescale( byval hTooltip as TK_TIP ptr, byval fOld as single, byval fNew as single )
sub tkTooltip_SetStyle( byval hTooltip as TK_TIP ptr, byval nStyle as long )
function tkTooltip_GetStyle( byval hTooltip as TK_TIP ptr ) as long
sub tkTooltip_SetMaxWidth( byval hTooltip as TK_TIP ptr, byval nMaxWidth as long )
function tkTooltip_GetMaxWidth( byval hTooltip as TK_TIP ptr ) as long
sub tkTooltip_SetPadding( byval hTooltip as TK_TIP ptr, byval nX as long, byval nY as long )
sub tkTooltip_SetCurvature( byval hTooltip as TK_TIP ptr, byval nCurvature as long )
sub tkTooltip_SetBorderWidth( byval hTooltip as TK_TIP ptr, byval nBorderWidth as long )
sub tkTooltip_SetStemSize( byval hTooltip as TK_TIP ptr, byval nW as long, byval nH as long )
sub tkTooltip_SetGlyphCell( byval hTooltip as TK_TIP ptr, byval nCell as long, byval nGap as long )
sub tkTooltip_SetInitialDelay( byval hTooltip as TK_TIP ptr, byval nMs as long )
sub tkTooltip_SetAutoPopDelay( byval hTooltip as TK_TIP ptr, byval nMs as long )
sub tkTooltip_SetReshowDelay( byval hTooltip as TK_TIP ptr, byval nMs as long )
sub tkTooltip_SetFadeTime( byval hTooltip as TK_TIP ptr, byval nMs as long )
sub tkTooltip_SetMoveTolerance( byval hTooltip as TK_TIP ptr, byval nPixels as long )
sub tkTooltip_SetDefaultColors( byval pColors as TKTOOLTIP_COLORS ptr )
sub tkTooltip_SetDefaultFonts( byval fText as TTF_Font ptr, byval fTitle as TTF_Font ptr = 0, byval fGlyph as TTF_Font ptr = 0 )
sub tkTooltip_SetDefaultStyle( byval nStyle as long )
sub tkTooltip_SetDefaultMaxWidth( byval nMaxWidth as long )
sub tkTooltip_SetDefaultDelays( byval nInitialMs as long, byval nAutoPopMs as long = -1, byval nReshowMs as long = -1 )
sub tkTooltip_ClearDefaults()
sub tkTooltip_ApplyDefaults( byval hTooltip as TK_TIP ptr )
function tkTooltip_Show( byval hTooltip as TK_TIP ptr ) as boolean
function tkTooltip_ShowForRect( byval hTooltip as TK_TIP ptr, byref rcAnchor as TKRECT, byval nAlign as long = TIP_ALIGN_BELOW ) as boolean
sub tkTooltip_Hide( byval hTooltip as TK_TIP ptr )
function tkTooltip_IsVisible( byval hTooltip as TK_TIP ptr ) as boolean
function tkTooltip_Surface( byval hTooltip as TK_TIP ptr ) as TK_HOST ptr
sub tkTooltip_SetPaintCallback( byval hTooltip as TK_TIP ptr, byval userfunc as TIP_PaintCallbackSub )
sub tkTooltip_SetTooltipCallback( byval hTooltip as TK_TIP ptr, byval userfunc as TIP_TooltipCallbackFunc )
sub tkTooltip_SetShowCallback( byval hTooltip as TK_TIP ptr, byval userfunc as TIP_ShowCallbackFunc )
sub tkTooltip_GetIdealSize( byval hTooltip as TK_TIP ptr, byref nW as long, byref nH as long )
function tkTooltip_GetPartRect( byval hTooltip as TK_TIP ptr, byval nPart as long ) as TKRECT
sub tkTooltip_TickForTest( byval hTooltip as TK_TIP ptr, byval cx as long, byval cy as long, byval bOver as boolean, byval bButtonDown as boolean, byval tNow as longint )
function tkTooltip_CountRenderedTones( byval hTooltip as TK_TIP ptr, byval nPart as long ) as long
function tkTooltip_HashRenderedPart( byval hTooltip as TK_TIP ptr, byval nPart as long ) as ulong
function tkTipHost_Ensure( byval pHost as TKTIPHOST_STATE ptr, byval hCtrl as TK_WIDGET ptr, byval TipCallback as TIP_TooltipCallbackFunc = 0 ) as boolean
sub tkTipHost_Destroy( byval pHost as TKTIPHOST_STATE ptr )
function tkTipHost_Tip( byval pHost as TKTIPHOST_STATE ptr ) as TK_TIP ptr
sub tkTipHost_SetToolIndex( byval pHost as TKTIPHOST_STATE ptr, byval idx as long )
sub tkTipHost_Pop( byval pHost as TKTIPHOST_STATE ptr )
sub tkTipHost_SetTracked( byval pHost as TKTIPHOST_STATE ptr, byval bTracked as boolean )
function tkTipHost_IsTracked( byval pHost as TKTIPHOST_STATE ptr ) as boolean
sub tkTipHost_TrackShow( byval pHost as TKTIPHOST_STATE ptr, byref rcAnchor as TKRECT, byval wszText as ustring )
sub tkTipHost_TrackHide( byval pHost as TKTIPHOST_STATE ptr )
sub tkTipHost_SetDelay( byval pHost as TKTIPHOST_STATE ptr, byval nWhich as long, byval nMs as long )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme)
