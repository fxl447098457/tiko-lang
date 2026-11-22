[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkProgressBar**

# tkProgressBar

Draws a horizontal or vertical progress bar, determinate or with a running marquee.

`tkProgressBar` is the [tkControls](Category-tkControls) progress indicator. A determinate bar
fills in proportion to its position within a range (0 to 100 by default); an indeterminate bar
runs a marquee chunk that bounces or wraps. The fill is solid or a two-stop gradient, continuous
or segmented into blocks, can grow from either end, and changes colour for the paused and error
states. An optional caption (percent, value, or your own text) is drawn across the bar in two
colours, one over the fill and one over the track.

The bar is output only: it has no change callback, and every setter is silent. The marquee is the
only timer it runs, and only while the bar is indeterminate, enabled and shown.

## Importing

```freebasic
#import "vendor/tkControls/tkProgressBar"

using tkProgressBar
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` to name the
`TK_GRADIENT_*` modes or to write a paint callback; `tkProgressBar_PaintDefault( p )` in one draws
the stock bar first.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
function Copy_Text( byval hBar as TK_WIDGET ptr, byval nPos as long, _
                    byval nMin as long, byval nMax as long ) as ustring
    return nPos & " of " & nMax & " files"
end function

dim as TK_WIDGET ptr copyBar = tkProgressBar_Create( tkHost_Root( host ), 8000 )
tkProgressBar_SetRange( copyBar, 0, 250 )
tkProgressBar_SetFillStyle( copyBar, PRG_FILL_GRADIENT )
tkProgressBar_SetTextCallback( copyBar, @Copy_Text )
tkProgressBar_SetTextMode( copyBar, PRG_TEXT_CALLBACK )
tkWidget_SetPos( copyBar, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkHost_Scale( host, 300 ), tkHost_Scale( host, 22 ) )

' as work completes
tkProgressBar_SetPos( copyBar, 120 )

' a "busy" bar with no known end
dim as TK_WIDGET ptr busy = tkProgressBar_Create( tkHost_Root( host ), 8001 )
tkProgressBar_SetMarqueeStyle( busy, PRG_MARQUEE_WRAP )
tkProgressBar_SetMode( busy, PRG_MODE_INDETERMINATE )
tkWidget_SetPos( busy, tkHost_Scale( host, 20 ), tkHost_Scale( host, 50 ), _
                 tkHost_Scale( host, 300 ), tkHost_Scale( host, 6 ) )
```

## Layout

`tkProgressBar_Create( hParent, CtrlID, nOrientation )` takes a `TK_WIDGET ptr` parent (for a
top-level bar, `tkHost_Root( host )`). The orientation is fixed there; anything but
`PRG_VERTICAL` is horizontal. A horizontal bar grows left to right and a vertical one bottom-up;
`tkProgressBar_SetReverse` makes them grow right to left and top-down.

The control derives three rects from its size and settings, lazily, and you never set them:

```
rcTrack  the whole size along the growth axis, the thickness across it, centred
         (thickness 0, the default, or more than the control's size fills it)
rcFill   rcTrack inset by the bar inset on every side: where a full bar reaches
         (an inset too large collapses it to empty rather than inverting it)
rcBar    determinate:   from rcFill's start edge, (pos - min) / (max - min) of its length
         indeterminate: a chunk of the chunk percent of rcFill, at the marquee's offset
```

`tkProgressBar_GetTrackRect`, `tkProgressBar_GetFillRect` and `tkProgressBar_GetBarRect` return
them in the control's own pixels.

The curvature is a corner diameter: 0 gives square corners and any negative value becomes
`TKPROGRESSBAR_CURVATURE_STADIUM`, which makes both ends exact semicircles whatever the
thickness. It is clamped to each painted rect's shorter side, so at the stadium setting every
block of a segmented bar is a small capsule; `tkProgressBar_SetCurvature( h, 0 )` gives square
blocks and a small value such as 3 softened ones. `tkProgressBar_SetBorderThickness` outlines the
track in `TrackBorderColor`; 0, the default, draws no outline.

`tkProgressBar_SetSegmented` and `tkProgressBar_SetFillStyle` are independent, so all four
combinations work.

- **Blocks** are the block length long with the gap between them, tiled from the bar's own start
  edge; only whole blocks are drawn. In indeterminate mode they tile the chunk and travel with
  it. `tkProgressBar_GetBlockCount` counts the blocks drawn now (0 when not segmented), and
  `tkProgressBar_GetBlockRect` returns `false` with `rc` emptied for an index past the last one.
  `tkProgressBar_SetBlockMetrics` ignores a length of 0 or less and a negative gap.
- **A gradient** runs between the state's two colour stops in the `TK_GRADIENT_*` direction of
  `tkProgressBar_SetGradientMode` (from [tkPaint](tkPaint); default vertical, and an unknown value
  becomes vertical). On a segmented bar each block is its slice of one ramp across the whole bar;
  on the two diagonal modes a block's corners match the ramp but its inside shades along its own
  diagonal.

The thickness, inset, block length and gap and the marquee step are scaled to the window at
creation, and again whenever its scale changes; the setters take pixels at the current scale.
The border thickness, the curvature and the marquee interval are never scaled.

## Position, modes and states

- The range starts at 0 to 100, the position at 0 and the step at 10. `tkProgressBar_SetRange`
  swaps an inverted pair and pulls the position into the new range; a range whose minimum equals
  its maximum draws an empty bar, and `tkProgressBar_GetPercent` answers 0 for it.
- `tkProgressBar_SetPos` clamps to the range and repaints only when the value changes. The bar
  jumps to the new position rather than easing toward it; for smooth motion, drive the position
  from your own timer. `tkProgressBar_StepIt` and `tkProgressBar_DeltaPos` clamp too: a full bar
  stays full rather than wrapping back to the start.
- In `PRG_MODE_INDETERMINATE` the position is kept but nothing draws from it. The chunk is
  `tkProgressBar_SetMarqueeChunkPercent` of the fill (default 25, clamped to 1..100) and moves
  by the step every interval (`tkProgressBar_SetMarqueeSpeed`, default 2 pixels every 30 ms;
  a value of 0 or less leaves that setting alone). `PRG_MARQUEE_BOUNCE`, the default, travels
  back and forth and keeps one width; `PRG_MARQUEE_WRAP` slides off one end and in at the other,
  clipped at the edges, so it is narrower while it crosses.
- The marquee timer runs only while the bar is indeterminate, enabled and shown. Switching the
  mode or the marquee style restarts the animation from the beginning; disabling or hiding pauses
  it, and enabling or showing again resumes where it stopped. The marquee settings can be made in
  determinate mode and take effect on the switch. `tkProgressBar_GetMarqueeTick` reads the
  animation's clock.
- `tkProgressBar_SetState` swaps the bar's colour pair for `PRG_STATE_PAUSED` or
  `PRG_STATE_ERROR`. An unknown state, mode, marquee style or fill style falls back to the first
  value of its enum.
- `tkProgressBar_SetEnabled` goes through `tkWidget_Enable`, and a direct `tkWidget_Enable` has
  the same effect: the disabled colours, the marquee paused and any tooltip closed.

## Text

`tkProgressBar_SetTextMode` picks the caption: `PRG_TEXT_NONE` (the default), `PRG_TEXT_PERCENT`
(`"45%"`), `PRG_TEXT_VALUE` (the raw position, `"45"`) or `PRG_TEXT_CALLBACK`. The text callback
is asked on every repaint, so keep it cheap; an empty string, or no callback, draws nothing.
`tkProgressBar_GetDisplayText` returns what would be drawn now.

The caption is drawn centred on the track twice into the same rect, clipped: over the filled bar
in `TextColorOnBar`, over the rest of the track in `TextColor`. The glyphs land in the same place,
so the colour changes exactly at the fill boundary, even part-way through a letter. A disabled
bar draws it once, in `TextColorDisabled`. The text is not rotated on a vertical bar, so leave a
narrow vertical bar at `PRG_TEXT_NONE`.

The font is borrowed and must outlive the bar; `tkProgressBar_SetFont( h, 0 )` returns to the
window's default font. `tkProgressBar_ApplyFonts` uses only its text font.

## Mouse, messages and tooltips

The bar is display-only: it takes no focus and is not a tab stop, takes no mouse capture or keys,
and never acts on a click; the mouse wheel passes on to its parent. The message callback is
offered every message except `TKM_DESTROY` before the bar handles it, and returning `true`
suppresses the bar's own handling, `TKM_PAINT` included. It is the place to make a bar
interactive, click-to-cancel being the usual case. `TKPROGRESSBAR_MESSAGEINFO` carries the
`TKM_*` code and the message's `x`, `y`, `key`, `timerId` and `bFlag`.

The tooltip shows the text set with `tkProgressBar_SetTooltipText`; without it, the tooltip
callback is asked as the tip is about to show; without either, there is no tooltip (it never
falls back to the percentage). `tkProgressBar_SetHoverTime`, `SetAutoPopTime` and
`SetReshowTime` set its delays, and `tkProgressBar_GetTooltipHandle` returns the bar's own
[tkTooltip](tkTooltip) as a `TK_TIP ptr`.

## Colours and theme

| Field | Paints | Theme colour |
| --- | --- | --- |
| `BackColor` | The control behind the track | `Window` |
| `TrackColor` | The track | `Track` |
| `TrackBorderColor` | The track's outline, when the border thickness is 1 or more | `Border` |
| `BarColor` / `BarColorEnd` | The bar's two stops, enabled and `PRG_STATE_NORMAL` | `Accent` |
| `BarColorPaused` / `BarColorPausedEnd` | Enabled and `PRG_STATE_PAUSED` | `Warning` |
| `BarColorError` / `BarColorErrorEnd` | Enabled and `PRG_STATE_ERROR` | `Error` |
| `BarColorDisabled` / `BarColorDisabledEnd` | Disabled, whatever the state | `TextDisabled` |
| `TextColor` | The caption over the empty track | `Text` |
| `TextColorOnBar` | The caption over the filled bar | `SelectedText` |
| `TextColorDisabled` | The whole caption, disabled | `TextDisabled` |

The bar colour goes disabled, then error, then paused, then normal: a paused bar that is disabled
draws in the disabled colours. A solid fill uses only the first stop of the pair, so one set of
colours serves both fill styles.

The colours come from the [tkTheme](tkTheme) palette (with any colours the theme gives progress
bars in particular) at creation and on every theme change. Both stops of a pair take the same
theme colour, so a themed gradient is flat until you set end stops of your own: read the colours
with `tkProgressBar_GetColors`, change the fields and hand them to `tkProgressBar_SetColors`,
which pins them so theme changes leave the bar alone until `tkProgressBar_UnpinColors`. The
initial values in `TKPROGRESSBAR_COLORS` are a dark palette with real gradients. The theme's
corner radius also sets the curvature, until `tkProgressBar_SetCurvature` is called.
`tkProgressBar_ResolveBarColors` returns the two stops the bar would use now.

## Painting your own

`tkProgressBar_SetPaintCallback` replaces the built-in painter; 0 restores it. The control has
filled itself with `BackColor` before the callback runs, and `tkProgressBar_PaintDefault( p )`
draws the stock bar so a callback can add to it. Draw through `p->b`. The paint info's rects are
the three above, `nCurvature` is already resolved (never the stadium sentinel), `nPercent` is
clamped to 0..100 and `wszText` is the caption with its mode and callback applied.

`PaintBorderRect` and `PaintRoundBorderRect` fill before they stroke, so one used as a frame over
the whole control wipes out what was drawn; `PaintRoundOutline` strokes only. Two probes render
the control offscreen and check for that kind of mistake: `tkProgressBar_CountRenderedTones( h,
part )` counts the distinct colours in a `PRG_PART_*` rect (a part flooded by one fill scores 1;
0 means the part has no area yet), and `tkProgressBar_HashRenderedPart` hashes the same pixels, so two
hashes of one part in two states that compare equal mean the change never reached the screen.
`PRG_PART_TEXT` is the middle third of the track, where a centred caption lands.

The three `Compute` functions are the arithmetic the bar uses, with no control involved:

- `tkProgressBar_ComputeBarLength` clamps the position and answers 0 for an empty or inverted
  range or a zero-length track; very large ranges do not overflow.
- `tkProgressBar_ComputeMarqueeOffset` gives the chunk's leading edge at a tick. `BOUNCE` stays
  in `0 .. track - chunk`, out and back; `WRAP` runs from `-chunk` to just under `track` and goes
  negative on purpose, so the caller clips the chunk to the track. A step below 1 counts as 1.
- `tkProgressBar_ComputeBlockCount` counts the whole blocks that fit, the last needing no
  trailing gap; 0 for a block length of 0 or a length shorter than one block.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKPROGRESSBAR_DEFAULT_THICKNESS = 0 ' 0 = fill the client's cross axis
const TKPROGRESSBAR_DEFAULT_BARINSET = 0
const TKPROGRESSBAR_DEFAULT_BORDERTHICK = 0 ' not scaled; 0 = no track border
const TKPROGRESSBAR_DEFAULT_CURVATURE = -1 ' not scaled; -1 = stadium
const TKPROGRESSBAR_DEFAULT_BLOCKLEN = 10
const TKPROGRESSBAR_DEFAULT_BLOCKGAP = 3
const TKPROGRESSBAR_DEFAULT_MARQUEE_MS = 30
const TKPROGRESSBAR_DEFAULT_MARQUEE_STEP = 2
const TKPROGRESSBAR_DEFAULT_CHUNK_PCT = 25
const TKPROGRESSBAR_CURVATURE_STADIUM = -1

enum
    PRG_HORIZONTAL = 0
    PRG_VERTICAL
end enum

enum
    PRG_MODE_DETERMINATE = 0
    PRG_MODE_INDETERMINATE
end enum

enum
    PRG_MARQUEE_BOUNCE = 0
    PRG_MARQUEE_WRAP
end enum

enum
    PRG_FILL_SOLID = 0
    PRG_FILL_GRADIENT
end enum

enum
    PRG_STATE_NORMAL = 0
    PRG_STATE_PAUSED
    PRG_STATE_ERROR
end enum

enum
    PRG_TEXT_NONE = 0
    PRG_TEXT_PERCENT
    PRG_TEXT_VALUE
    PRG_TEXT_CALLBACK
end enum

enum
    PRG_PART_CONTROL = 0
    PRG_PART_TRACK
    PRG_PART_BAR
    PRG_PART_TEXT
end enum
```

### Types

```freebasic
type TKPROGRESSBAR_COLORS
    BackColor            as ulong = &hFF21252Bul    ' ( 33, 37, 43)
    TrackColor           as ulong = &hFF33373Ful    ' ( 51, 55, 63)
    TrackBorderColor     as ulong = &hFF484D56ul    ' ( 72, 77, 86)
    BarColor             as ulong = &hFF569CD6ul    ' ( 86,156,214)
    BarColorEnd          as ulong = &hFF346EAAul    ' ( 52,110,170)
    BarColorPaused       as ulong = &hFFDEB846ul    ' (222,184, 70)
    BarColorPausedEnd    as ulong = &hFFB28C22ul    ' (178,140, 34)
    BarColorError        as ulong = &hFFE06060ul    ' (224, 96, 96)
    BarColorErrorEnd     as ulong = &hFFB03838ul    ' (176, 56, 56)
    BarColorDisabled     as ulong = &hFF545961ul    ' ( 84, 89, 97)
    BarColorDisabledEnd  as ulong = &hFF3E434Bul    ' ( 62, 67, 75)
    TextColor            as ulong = &hFFBEC4CEul    ' (190,196,206) over the EMPTY track
    TextColorOnBar       as ulong = &hFFFFFFFFul    ' over the FILLED bar
    TextColorDisabled    as ulong = &hFF5A606Aul    ' ( 90, 96,106) both halves, disabled
end type

type TKPROGRESSBAR_PAINTINFO
    hProgressBar     as TK_WIDGET ptr
    b                as TK_PAINT ptr
    rcClient         as TKRECT
    rcTrack          as TKRECT
    rcFill           as TKRECT
    rcBar            as TKRECT          ' indeterminate: the floating chunk
    nPos             as long
    nMin             as long
    nMax             as long
    nPercent         as long
    isIndeterminate  as boolean
    isEnabled        as boolean
    isReverse        as boolean
    isSegmented      as boolean
    nOrientation     as long
    nState           as long
    nFillStyle       as long
    nCurvature       as long            ' resolved: the stadium sentinel never reaches here
    nBlockLength     as long
    nBlockGap        as long
    wszText          as ustring         ' "" = draw nothing
end type

type TKPROGRESSBAR_MESSAGEINFO
    hProgressBar as TK_WIDGET ptr
    msg          as long                ' TKM_*
    x            as single
    y            as single
    key          as long
    timerId      as long
    bFlag        as boolean
end type

type TKPROGRESSBAR_STATE   ' per-instance state; reach it through the procedures

type PRG_PaintCallbackSub as sub( byval p as TKPROGRESSBAR_PAINTINFO ptr )
type PRG_MessageCallbackFunc as function( byval m as TKPROGRESSBAR_MESSAGEINFO ptr ) as boolean
type PRG_TooltipCallbackFunc as function( byval hProgressBar as TK_WIDGET ptr ) as ustring
type PRG_TextCallbackFunc as function( byval hProgressBar as TK_WIDGET ptr, byval nPos as long, byval nMin as long, byval nMax as long ) as ustring
```

### Procedures

```freebasic
function tkProgressBar_ComputeBarLength( byval nPos as long, byval nMin as long, byval nMax as long, byval nTrackLen as long ) as long
function tkProgressBar_ComputeMarqueeOffset( byval nTrackLen as long, byval nChunkLen as long, byval nStep as long, byval nTick as long, byval nStyle as long ) as long
function tkProgressBar_ComputeBlockCount( byval nLength as long, byval nBlockLen as long, byval nBlockGap as long ) as long
function tkProgressBar_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long, byval nOrientation as long = PRG_HORIZONTAL ) as TK_WIDGET ptr
sub tkProgressBar_Refresh( byval hProgressBar as TK_WIDGET ptr )
function tkProgressBar_GetOrientation( byval hProgressBar as TK_WIDGET ptr ) as long
function tkProgressBar_GetID( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_GetRange( byval hProgressBar as TK_WIDGET ptr, byref nMin as long, byref nMax as long )
sub tkProgressBar_SetRange( byval hProgressBar as TK_WIDGET ptr, byval nMin as long, byval nMax as long )
function tkProgressBar_GetPos( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetPos( byval hProgressBar as TK_WIDGET ptr, byval nPos as long )
function tkProgressBar_GetStep( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetStep( byval hProgressBar as TK_WIDGET ptr, byval nStep as long )
function tkProgressBar_StepIt( byval hProgressBar as TK_WIDGET ptr ) as long
function tkProgressBar_DeltaPos( byval hProgressBar as TK_WIDGET ptr, byval nDelta as long ) as long
function tkProgressBar_GetPercent( byval hProgressBar as TK_WIDGET ptr ) as long
function tkProgressBar_GetMode( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetMode( byval hProgressBar as TK_WIDGET ptr, byval nMode as long )
function tkProgressBar_GetState( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetState( byval hProgressBar as TK_WIDGET ptr, byval nState as long )
function tkProgressBar_GetEnabled( byval hProgressBar as TK_WIDGET ptr ) as boolean
sub tkProgressBar_SetEnabled( byval hProgressBar as TK_WIDGET ptr, byval isEnabled as boolean )
function tkProgressBar_GetMarqueeStyle( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetMarqueeStyle( byval hProgressBar as TK_WIDGET ptr, byval nStyle as long )
sub tkProgressBar_GetMarqueeSpeed( byval hProgressBar as TK_WIDGET ptr, byref nIntervalMs as long, byref nStepPx as long )
sub tkProgressBar_SetMarqueeSpeed( byval hProgressBar as TK_WIDGET ptr, byval nIntervalMs as long, byval nStepPx as long )
function tkProgressBar_GetMarqueeChunkPercent( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetMarqueeChunkPercent( byval hProgressBar as TK_WIDGET ptr, byval nPercent as long )
function tkProgressBar_GetMarqueeTick( byval hProgressBar as TK_WIDGET ptr ) as long
function tkProgressBar_GetFillStyle( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetFillStyle( byval hProgressBar as TK_WIDGET ptr, byval nFillStyle as long )
function tkProgressBar_GetGradientMode( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetGradientMode( byval hProgressBar as TK_WIDGET ptr, byval nMode as long )
function tkProgressBar_GetSegmented( byval hProgressBar as TK_WIDGET ptr ) as boolean
sub tkProgressBar_SetSegmented( byval hProgressBar as TK_WIDGET ptr, byval isSegmented as boolean )
sub tkProgressBar_GetBlockMetrics( byval hProgressBar as TK_WIDGET ptr, byref nBlockLen as long, byref nBlockGap as long )
sub tkProgressBar_SetBlockMetrics( byval hProgressBar as TK_WIDGET ptr, byval nBlockLen as long, byval nBlockGap as long )
function tkProgressBar_GetBlockCount( byval hProgressBar as TK_WIDGET ptr ) as long
function tkProgressBar_GetBlockRect( byval hProgressBar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkProgressBar_GetThickness( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetThickness( byval hProgressBar as TK_WIDGET ptr, byval nThickness as long )
function tkProgressBar_GetBarInset( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetBarInset( byval hProgressBar as TK_WIDGET ptr, byval nBarInset as long )
function tkProgressBar_GetBorderThickness( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetBorderThickness( byval hProgressBar as TK_WIDGET ptr, byval nThickness as long )
function tkProgressBar_GetCurvature( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetCurvature( byval hProgressBar as TK_WIDGET ptr, byval nCurvature as long )
function tkProgressBar_GetReverse( byval hProgressBar as TK_WIDGET ptr ) as boolean
sub tkProgressBar_SetReverse( byval hProgressBar as TK_WIDGET ptr, byval isReverse as boolean )
function tkProgressBar_GetTrackRect( byval hProgressBar as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkProgressBar_GetFillRect( byval hProgressBar as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkProgressBar_GetBarRect( byval hProgressBar as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkProgressBar_GetTextMode( byval hProgressBar as TK_WIDGET ptr ) as long
sub tkProgressBar_SetTextMode( byval hProgressBar as TK_WIDGET ptr, byval nTextMode as long )
function tkProgressBar_GetFont( byval hProgressBar as TK_WIDGET ptr ) as TTF_Font ptr
sub tkProgressBar_SetFont( byval hProgressBar as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkProgressBar_GetDisplayText( byval hProgressBar as TK_WIDGET ptr ) as ustring
sub tkProgressBar_GetColors( byval hProgressBar as TK_WIDGET ptr, byval pColors as TKPROGRESSBAR_COLORS ptr )
sub tkProgressBar_SetColors( byval hProgressBar as TK_WIDGET ptr, byval pColors as TKPROGRESSBAR_COLORS ptr )
function tkProgressBar_ThemeColors( byref t as TKTHEME_COLORS ) as TKPROGRESSBAR_COLORS
sub tkProgressBar_ApplyTheme( byval hProgressBar as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkProgressBar_UnpinColors( byval hProgressBar as TK_WIDGET ptr )
sub tkProgressBar_ApplyFonts( byval hProgressBar as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkProgressBar_ResolveBarColors( byval hProgressBar as TK_WIDGET ptr, byref clr1 as ulong, byref clr2 as ulong )
function tkProgressBar_GetTooltipText( byval hProgressBar as TK_WIDGET ptr ) as ustring
sub tkProgressBar_SetTooltipText( byval hProgressBar as TK_WIDGET ptr, byval Text as ustring )
function tkProgressBar_GetTooltipHandle( byval hProgressBar as TK_WIDGET ptr ) as TK_TIP ptr
sub tkProgressBar_SetHoverTime( byval hProgressBar as TK_WIDGET ptr, byval ms as long )
sub tkProgressBar_SetAutoPopTime( byval hProgressBar as TK_WIDGET ptr, byval ms as long )
sub tkProgressBar_SetReshowTime( byval hProgressBar as TK_WIDGET ptr, byval ms as long )
sub tkProgressBar_PaintDefault( byval p as TKPROGRESSBAR_PAINTINFO ptr )
sub tkProgressBar_SetPaintCallback( byval hProgressBar as TK_WIDGET ptr, byval usersub as PRG_PaintCallbackSub )
sub tkProgressBar_SetMessageCallback( byval hProgressBar as TK_WIDGET ptr, byval userfunc as PRG_MessageCallbackFunc )
sub tkProgressBar_SetTooltipCallback( byval hProgressBar as TK_WIDGET ptr, byval userfunc as PRG_TooltipCallbackFunc )
sub tkProgressBar_SetTextCallback( byval hProgressBar as TK_WIDGET ptr, byval userfunc as PRG_TextCallbackFunc )
function tkProgressBar_CountRenderedTones( byval hProgressBar as TK_WIDGET ptr, byval nPart as long ) as long
function tkProgressBar_HashRenderedPart( byval hProgressBar as TK_WIDGET ptr, byval nPart as long ) as ulong
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
