[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkSpinner**

# tkSpinner

Shows a small animation while something takes its time.

`tkSpinner` is the [tkControls](Category-tkControls) busy indicator: the spinning circle a program shows while it loads, saves or waits on the network. It is display-only: never a tab stop, and it does nothing with the mouse or the keyboard. It draws in the largest square centred in its client, so it can be any size.

There are six animations, chosen at create or with `tkSpinner_SetStyle`:

| Style | What it shows |
|---|---|
| `SPN_STYLE_RING` | a quarter arc going round a faint track (the default) |
| `SPN_STYLE_ARC` | one arc that grows and shrinks as it turns |
| `SPN_STYLE_DOTS` | a ring of dots: a bright head and a fading tail going round |
| `SPN_STYLE_SPOKES` | bars round a hub, fading in turn |
| `SPN_STYLE_PULSE` | a disc that grows and fades out, twice a cycle |
| `SPN_STYLE_BOUNCE` | three dots in a row rising and falling in turn |

It is created stopped, showing its first frame still. `tkSpinner_Start` sets it going and `tkSpinner_Stop` stops it where it is; with `tkSpinner_SetHideWhenStopped` a stopped spinner draws nothing. One cycle takes `Period` milliseconds (1000 by default) and a frame is drawn every `FrameMs` (16). It runs only while it is started, enabled and shown: hidden or disabled it waits, and goes on where it left off. A disabled spinner draws in its disabled colour.

It is transparent by default, so it sits on whatever is behind it; `tkSpinner_SetTransparent( spn, false )` fills the client with its BackColor. `Count` is the number of dots (DOTS) or bars (SPOKES), 3 to 24, 8 by default. `Thickness` is the stroke of RING, ARC and SPOKES in design units; 0, the default, is a tenth of the spinner's size. Setters are silent.

The colours come from the theme: ForeColor is the accent, TrackColor the theme's track, BackColor the window. A paint callback draws the frame itself; `tkSpinner_PaintDefault( p )` in it draws the stock frame first.

## Importing

```freebasic
#import "vendor/tkControls/tkSpinner"

using tkSpinner
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint)) and [tkTheme](tkTheme).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
dim as TK_WIDGET ptr busy = tkSpinner_Create( tkHost_Root( host ), 2400, SPN_STYLE_DOTS )
tkWidget_SetPos( busy, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkHost_Scale( host, 32 ), tkHost_Scale( host, 32 ) )
tkSpinner_SetHideWhenStopped( busy, true )

tkSpinner_Start( busy )          ' the work begins
' ...
tkSpinner_Stop( busy )           ' and it's done: the spinner disappears
```

## Typed wrapper

The module also provides `Spinner`, a typed value for designed forms (see [tkForms](tkForms) and the [Form Designer](Form-Designer)). `Spinner.Handle` is the `TK_WIDGET ptr`. It has `Create( hParent, id, Style )`, `SetFocus( )`, and these properties, each read and write:

`Enabled`, `Visible`, `Running`, `Period`, `FrameMs`, `Count`, `Thickness`, `HideWhenStopped`, `Transparent`.

On the design surface a spinner shows its first frame still, whatever `Running` says.

## Behaviour notes

- The phase is where in the cycle the animation is, 0 up to 1. `tkSpinner_SetPhase` shows a chosen still frame, and a started spinner goes on from it.
- `Period` below 50 is 50; `FrameMs` is kept to 10 through 1000; `Count` to 3 through 24.
- A style out of range is refused: the spinner keeps the one it has.
- The message callback is offered every message but `TKM_DESTROY`; answering TRUE for a `TKM_TIMER` holds the animation still.
- `tkSpinner_SetColors` pins the colours: they then survive a theme change until `tkSpinner_UnpinColors`.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
enum
    SPN_STYLE_RING = 0    ' a quarter arc going round a faint track
    SPN_STYLE_ARC         ' one arc growing and shrinking as it turns
    SPN_STYLE_DOTS        ' Count dots on a circle: a bright head, a fading tail
    SPN_STYLE_SPOKES      ' Count bars round a hub, fading in turn
    SPN_STYLE_PULSE       ' a disc growing and fading out, twice a cycle
    SPN_STYLE_BOUNCE      ' three dots in a row rising and falling in turn
    SPN_STYLE_COUNT
end enum

const TKSPINNER_DEFAULT_PERIOD  = 1000
const TKSPINNER_DEFAULT_FRAMEMS = 16
const TKSPINNER_DEFAULT_COUNT   = 8
```

### Types

```freebasic
type TKSPINNER_COLORS
    BackColor         as ulong    ' the client, when not transparent
    ForeColor         as ulong    ' what moves
    TrackColor        as ulong    ' what stays: the ring's track
    ForeColorDisabled as ulong    ' what moves, while disabled
end type

type TKSPINNER_PAINTINFO
    hSpinner   as TK_WIDGET ptr
    b          as TK_PAINT ptr
    rcClient   as TKRECT
    rc         as TKRECT                ' the square the animation is drawn in
    nStyle     as long
    fPhase     as single                ' 0 up to 1: where in the cycle
    nCount     as long
    nThick     as long                  ' pixels
    clrFore    as ulong                 ' ForeColor, or ForeColorDisabled while disabled
    clrTrack   as ulong
    isRunning  as boolean
    isEnabled  as boolean
end type

type TKSPINNER_MESSAGEINFO
    hSpinner as TK_WIDGET ptr
    msg      as long                    ' TKM_*
    x        as single
    y        as single
    timerId  as long
    bFlag    as boolean
end type

type SPN_PaintCallbackSub as sub( byval p as TKSPINNER_PAINTINFO ptr )
type SPN_MessageCallbackFunc as function( byval m as TKSPINNER_MESSAGEINFO ptr ) as boolean

type TKSPINNER_STATE   ' per-instance state; reach it through the procedures
```

### Procedures

```freebasic
function tkSpinner_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long, byval nStyle as long = SPN_STYLE_RING ) as TK_WIDGET ptr
function tkSpinner_GetStyle( byval h as TK_WIDGET ptr ) as long
sub tkSpinner_SetStyle( byval h as TK_WIDGET ptr, byval nStyle as long )
sub tkSpinner_Start( byval h as TK_WIDGET ptr )
sub tkSpinner_Stop( byval h as TK_WIDGET ptr )
function tkSpinner_IsRunning( byval h as TK_WIDGET ptr ) as boolean
sub tkSpinner_SetRunning( byval h as TK_WIDGET ptr, byval bRun as boolean )
function tkSpinner_GetPeriod( byval h as TK_WIDGET ptr ) as long
sub tkSpinner_SetPeriod( byval h as TK_WIDGET ptr, byval ms as long )
function tkSpinner_GetFrameMs( byval h as TK_WIDGET ptr ) as long
sub tkSpinner_SetFrameMs( byval h as TK_WIDGET ptr, byval ms as long )
function tkSpinner_GetCount( byval h as TK_WIDGET ptr ) as long
sub tkSpinner_SetCount( byval h as TK_WIDGET ptr, byval n as long )
function tkSpinner_GetThickness( byval h as TK_WIDGET ptr ) as long
sub tkSpinner_SetThickness( byval h as TK_WIDGET ptr, byval n as long )
function tkSpinner_GetHideWhenStopped( byval h as TK_WIDGET ptr ) as boolean
sub tkSpinner_SetHideWhenStopped( byval h as TK_WIDGET ptr, byval bHide as boolean )
function tkSpinner_GetTransparent( byval h as TK_WIDGET ptr ) as boolean
sub tkSpinner_SetTransparent( byval h as TK_WIDGET ptr, byval bTransparent as boolean )
function tkSpinner_GetPhase( byval h as TK_WIDGET ptr ) as single
sub tkSpinner_SetPhase( byval h as TK_WIDGET ptr, byval f as single )
sub tkSpinner_GetColors( byval h as TK_WIDGET ptr, byval pColors as TKSPINNER_COLORS ptr )
sub tkSpinner_SetColors( byval h as TK_WIDGET ptr, byval pColors as TKSPINNER_COLORS ptr )
function tkSpinner_ThemeColors( byref t as TKTHEME_COLORS ) as TKSPINNER_COLORS
sub tkSpinner_ApplyTheme( byval h as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkSpinner_UnpinColors( byval h as TK_WIDGET ptr )
sub tkSpinner_PaintDefault( byval p as TKSPINNER_PAINTINFO ptr )
sub tkSpinner_SetPaintCallback( byval h as TK_WIDGET ptr, byval usersub as SPN_PaintCallbackSub )
sub tkSpinner_SetMessageCallback( byval h as TK_WIDGET ptr, byval userfunc as SPN_MessageCallbackFunc )
function tkSpinner_CountRenderedTones( byval h as TK_WIDGET ptr ) as long
function tkSpinner_HashRenderedPart( byval h as TK_WIDGET ptr ) as ulong
```

### See also

- [tkControls](Category-tkControls)
- [tkProgressBar](tkProgressBar), [tkHost](tkHost), [tkTheme](tkTheme)
- [Form Designer](Form-Designer)
