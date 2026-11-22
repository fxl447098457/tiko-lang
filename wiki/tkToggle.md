[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkToggle**

# tkToggle

Draws an on/off switch: a rounded track and a knob that marks the state.

`tkToggle` is the [tkControls](Category-tkControls) switch for a single setting that takes
effect at once. It is a track and a knob and nothing else: no caption, no font and no animation,
so put a label beside it. It can carry a tooltip (`tkToggle_SetTooltipText`, with the usual
`SetHoverTime` / `SetAutoPopTime` / `SetReshowTime` and `GetTooltipHandle`). A click, Space or Enter flips it; a held key does not
re-flip it. The arrow keys are not claimed.

`tkToggle_SetChecked` is silent; the check-changed callback runs only when the user flips the
switch. The switch sits left, centred or right inside its client area (`TOG_JUSTIFY_*`), and a
client too short for the track clips it rather than squeezing it.

The track's border follows the theme's `BorderWidth` until `tkToggle_SetBorderThickness` sets it.
A paint callback replaces the drawing; `tkToggle_PaintDefault( p )` draws the stock toggle first.

## Importing

```freebasic
#import "vendor/tkControls/tkToggle"

using tkToggle
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image) and [tkTheme](tkTheme). Add `using tkPaint` for a paint callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Wifi_Changed( byval hToggle as TK_WIDGET ptr, byval isChecked as boolean )
    print "Wi-Fi " & iif( isChecked, "on", "off" )
end sub

dim as TK_WIDGET ptr tog = tkToggle_Create( tkHost_Root( host ), 3000 )
tkToggle_SetChecked( tog, true )                   ' silent: no callback
tkToggle_SetCheckChangedCallback( tog, @Wifi_Changed )

dim as long w, h
tkToggle_GetIdealSize( tog, w, h )
tkWidget_SetPos( tog, tkHost_Scale( host, 20 ), tkHost_Scale( host, 100 ), w, h )
```

## Concepts

### Creating and sizing

`tkToggle_Create( hParent, ctrlId )` creates the switch as a focusable child of a
`TK_WIDGET ptr` (for a top-level control pass `tkHost_Root( host )`). It is created with no size:
read `tkToggle_GetIdealSize` and place it with `tkWidget_SetPos`, as in the example.

### Geometry is derived, never assigned

The control computes three rects, readable through `tkToggle_GetTrackRect`,
`tkToggle_GetKnobRect` and `tkToggle_GetVisualRect`:

| Rect | What it is |
|---|---|
| `rcTrack` | The pill |
| `rcKnob` | The circle, already at the end the current state calls for |
| `rcVisual` | `rcTrack` grown on all four sides by the focus-ring band |

```
  ringPad      = focusGap + focusThickness
  knobDia      = trackHeight - 2*knobInset          (floored at 1)

  rcTrack.top  = (clientH - trackHeight) \ 2        always vertically centred
  rcTrack.left = LEFT   -> ringPad
                 CENTER -> (clientW - trackWidth) \ 2
                 RIGHT  -> clientW - ringPad - trackWidth

  rcKnob.top   = rcTrack.top + knobInset            (w = h = knobDia)
  rcKnob.left  = OFF -> rcTrack.left  + knobInset
                 ON  -> rcTrack.right - knobInset - knobDia

  rcVisual     = rcTrack inflated by ringPad on all four sides
```

The pill has an intrinsic size and is placed inside the client, never stretched to it. The
knob's diameter follows the track height and the inset, never the width: a wider track is a
longer pill with the same knob.

Layout is lazy: a setter marks it stale and repaints, and the next paint or rect query recomputes
it once. The rect queries return FALSE, with `rc` empty, until the control has a size.

### The focus-ring band is always reserved

The ring is drawn inside a band of `focusGap + focusThickness` pixels around the track, reserved
whether or not the control has focus, so the pill does not move when you Tab onto it. Changing
either focus-ring value therefore changes the ideal size. `tkToggle_GetIdealSize` returns those
full bounds, `(trackW + 2*ringPad) x (trackH + 2*ringPad)`, computed from the settings rather than
the layout, so it is valid before the control has ever been sized.

### Pixels and scale

| Setting | Default | Scaled? |
|---|---:|---|
| Track width | `TKTOGGLE_DEFAULT_TRACKW` (40) | At create and on every scale change |
| Track height | `TKTOGGLE_DEFAULT_TRACKH` (20) | At create and on every scale change |
| Knob inset | `TKTOGGLE_DEFAULT_KNOBINSET` (2) | At create and on every scale change |
| Focus-ring gap | `TKTOGGLE_DEFAULT_FOCUSGAP` (3) | At create and on every scale change |
| Border thickness | `TKTOGGLE_DEFAULT_BORDERTHICK` (1), or the theme's border width | Never |
| Focus-ring thickness | `TKTOGGLE_DEFAULT_FOCUSTHICK` (1) | Never |

Every setter takes pixels; scale sizes with `tkHost_Scale`, but leave the two thicknesses
unscaled so a hairline stays a hairline. Until `tkToggle_SetBorderThickness` is called, the
border follows the current theme's border width; setting it pins it.

### Programmatic changes are silent

`tkToggle_SetChecked` never runs the check-changed callback, and does nothing when the state
already matches. The callback reports user action only, so you can call `tkToggle_SetChecked`
from inside your own handler without recursing.

### How a click is decided

A left press focuses the control, then takes the mouse capture. The state flips on **release**,
and only if the press started on the control and the cursor is still over it: press, slide off,
release, and nothing happens. While the cursor is off during a press, the switch stops painting
as pressed; slide back on and it re-arms.

Space, Enter and keypad Enter take the same path as a completed click, so keyboard and mouse
cannot drift apart. A held key does not re-flip at the repeat rate. Arrow keys and every other key
are left unclaimed. A double click is two ordinary clicks, so it flips the switch twice.

### Enabling and disabling

`tkToggle_SetEnabled` enables or disables the widget itself: input stops, Tab skips it, and hover,
a live press and any tooltip go at once. Disabling does not change the checked state; a disabled ON
switch still reads as ON, which is why the colours have separate disabled shades for each state.
Hiding the widget also clears hover and a live press.

## Behaviour and limits

- **No caption and no font.** Nothing about the geometry is measured. Put a label beside it.
- **No animation.** The knob is at one end or the other.
- **No tri-state.** Checked or unchecked.
- **No hit-test function.** The whole widget is the hit area.
- **The right button is reported, never acted on.** A context menu is yours; no capture is taken
  for it.
- **Invalid justification values are ignored**, keeping the current setting.
- **Too small for the pill, justification falls back to LEFT and the pill clips at the edge.**
  The pill keeps its shape; a client shorter than the track clips top and bottom rather than
  squashing it.
- **Tooltip text is the toggle's own** (`tkToggle_SetTooltipText`, `""` for none); a press hides
  a visible tip.

## Colours

`TKTOGGLE_COLORS` has twenty fields: three drawn parts (track fill, track border, knob) times two
states (ON, OFF) times three moods (idle, hot, disabled), plus the background and the focus ring.
The toggle takes them from the current theme when it is created (including any theme recipe for
`"Toggle"`) and follows every theme change. `tkToggle_SetColors` copies a struct and pins it, so a
theme change leaves this toggle alone; `tkToggle_UnpinColors` hands it back to the theme and
applies it at once. To change one colour, read with `tkToggle_GetColors`, modify, and set.

| Field | Paints | Theme role |
|---|---|---|
| `BackColor` | The widget behind the pill | `Window` |
| `FocusRingColor` | The focus ring | `FocusRing` |
| `TrackColorOn`, `TrackColorOnHot`, `TrackColorOnDisabled` | Pill fill, ON | `Accent`, `AccentHot`, `Border` |
| `TrackBorderColorOn`, `...OnHot`, `...OnDisabled` | Pill border, ON | `Accent`, `AccentHot`, `Border` |
| `KnobColorOn`, `KnobColorOnHot`, `KnobColorOnDisabled` | Knob, ON | `SelectedText`, `SelectedText`, `TextDisabled` |
| `TrackColorOff`, `TrackColorOffHot`, `TrackColorOffDisabled` | Pill fill, OFF | `Track`, `SurfaceHot`, `SurfaceDisabled` |
| `TrackBorderColorOff`, `...OffHot`, `...OffDisabled` | Pill border, OFF | `TextDim`, `Text`, `TextDisabled` |
| `KnobColorOff`, `KnobColorOffHot`, `KnobColorOffDisabled` | Knob, OFF | `TextDim`, `Text`, `TextDisabled` |

### Which colour wins

The built-in painter picks one fill, one border and one knob colour per repaint, within the ON or
OFF group that applies:

```
disabled   >   hot or pressed   >   idle
```

There are no pressed colours: a live press renders as hot. A paint callback still receives
`isPressed` separately.

The ON pill looks borderless because its border colours equal its fill colours; the OFF pill
reads as an outline, its border lighter than its fill. Set the ON border to something else if you
want one.

### What the painter draws

The widget is filled with `BackColor` first. The track is a pill: a rounded rect whose corner
diameter equals its height, so both ends are semicircles, drawn with a border when the border
thickness is above 0. The knob is a filled circle. The focus ring is a rounded outline over
`rcVisual`, drawn only while the control has focus and the ring thickness is above 0; it is never
filled, because it lies over the pill.

## Callbacks

All are optional and independent; passing 0 clears one.

### Check changed

```freebasic
type TOG_CheckChangedCallbackSub as sub( byval hToggle as TK_WIDGET ptr, byval isChecked as boolean )
```

The user flipped the switch: a completed click, Space or Enter. It fires after the state is
updated, so `tkToggle_GetChecked` already equals `isChecked`. It never fires for
`tkToggle_SetChecked`.

### Paint

```freebasic
type TOG_PaintCallbackSub as sub( byval p as TKTOGGLE_PAINTINFO ptr )
```

Draws the control instead of the built-in painter. `BackColor` has already been filled, so draw
your additions, not a background. `tkToggle_PaintDefault( p )` draws the stock toggle first. Use
the rects as given; do not re-derive the knob from the track, because the inset can change.

| Field | Meaning |
|---|---|
| `hToggle` | The control, so the callback can query it |
| `b` | The paint context for this repaint (borrowed) |
| `rcClient` | The whole widget |
| `rcTrack` | The pill |
| `rcKnob` | The knob, at the end the state calls for |
| `rcVisual` | `rcTrack` inflated by the focus-ring band |
| `isChecked` | ON when TRUE |
| `isHot` | The mouse is over the control |
| `isPressed` | A live left press **and** the cursor still inside |
| `isEnabled` | The control's enabled state |
| `isFocused` | Draw a focus ring when TRUE |

### Message

```freebasic
type TOG_MessageCallbackFunc as function( byval m as TKTOGGLE_MESSAGEINFO ptr ) as boolean
```

Observes messages as they arrive. `TKTOGGLE_MESSAGEINFO` carries `hToggle`, `msg`, widget-local
`x` / `y` and `key`. Return TRUE to suppress the control's own handling where that is allowed:

| Message | Effect of returning TRUE |
|---|---|
| `TKM_LBUTTONDOWN` | No press starts and no capture is taken (focus is already given) |
| `TKM_KEYDOWN` for Space or Enter | The switch does not flip |
| `TKM_MOUSEMOVE`, `TKM_MOUSELEAVE`, `TKM_RBUTTONDOWN`, `TKM_RBUTTONUP` | Reported after the control's own handling; nothing left to suppress |
| `TKM_LBUTTONUP` | **Ignored**: it ends the press and releases the capture |
| `TKM_SETFOCUS`, `TKM_KILLFOCUS` | **Ignored**: focus is a fact, already applied |
| `TKM_KEYDOWN` for any other key | **Ignored**: the key is not the toggle's |

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKTOGGLE_DEFAULT_TRACKW = 40
const as long TKTOGGLE_DEFAULT_TRACKH = 20
const as long TKTOGGLE_DEFAULT_KNOBINSET = 2
const as long TKTOGGLE_DEFAULT_BORDERTHICK = 1
const as long TKTOGGLE_DEFAULT_FOCUSGAP = 3
const as long TKTOGGLE_DEFAULT_FOCUSTHICK = 1

enum
    TOG_JUSTIFY_LEFT = 0
    TOG_JUSTIFY_CENTER
    TOG_JUSTIFY_RIGHT
end enum
```

### Types

```freebasic
type TKTOGGLE_COLORS
    BackColor                   as ulong = &hFF21252Bul    ' ( 33, 37, 43) the control's own background
    FocusRingColor              as ulong = &hFF569CD6ul    ' ( 86,156,214)
    TrackColorOn                as ulong = &hFF4A6C8Cul    ' ( 74,108,140)
    TrackColorOnHot             as ulong = &hFF5C84AAul    ' ( 92,132,170)
    TrackColorOnDisabled        as ulong = &hFF384654ul    ' ( 56, 70, 84)
    TrackBorderColorOn          as ulong = &hFF4A6C8Cul    ' = TrackColorOn
    TrackBorderColorOnHot       as ulong = &hFF5C84AAul    ' = TrackColorOnHot
    TrackBorderColorOnDisabled  as ulong = &hFF384654ul    ' = TrackColorOnDisabled
    KnobColorOn                 as ulong = &hFFD8DCE2ul    ' (216,220,226)
    KnobColorOnHot              as ulong = &hFFFFFFFFul
    KnobColorOnDisabled         as ulong = &hFF787E86ul    ' (120,126,134)
    TrackColorOff               as ulong = &hFF33373Ful    ' ( 51, 55, 63)
    TrackColorOffHot            as ulong = &hFF3E434Dul    ' ( 62, 67, 77)
    TrackColorOffDisabled       as ulong = &hFF2C3037ul    ' ( 44, 48, 55)
    TrackBorderColorOff         as ulong = &hFF6B7280ul    ' (107,114,128)
    TrackBorderColorOffHot      as ulong = &hFF8A92A1ul    ' (138,146,161)
    TrackBorderColorOffDisabled as ulong = &hFF484D56ul    ' ( 72, 77, 86)
    KnobColorOff                as ulong = &hFF8A9099ul    ' (138,144,153)
    KnobColorOffHot             as ulong = &hFFB0B6BFul    ' (176,182,191)
    KnobColorOffDisabled        as ulong = &hFF545961ul    ' ( 84, 89, 97)
end type

type TKTOGGLE_PAINTINFO
    hToggle    as TK_WIDGET ptr
    b          as TK_PAINT ptr          ' the control's paint for this frame (borrowed)
    rcClient   as TKRECT
    rcTrack    as TKRECT
    rcKnob     as TKRECT                ' already at the end the current state calls for
    rcVisual   as TKRECT                ' rcTrack inflated by the focus-ring band
    isChecked  as boolean
    isHot      as boolean
    isPressed  as boolean               ' a live left press AND the cursor still inside
    isEnabled  as boolean
    isFocused  as boolean
end type

type TKTOGGLE_MESSAGEINFO
    hToggle as TK_WIDGET ptr
    msg     as long                     ' TKM_*
    x       as single
    y       as single
    key     as long
end type

type TKTOGGLE_STATE   ' per-instance state; reach it through the procedures

type TOG_PaintCallbackSub as sub( byval p as TKTOGGLE_PAINTINFO ptr )
type TOG_MessageCallbackFunc as function( byval m as TKTOGGLE_MESSAGEINFO ptr ) as boolean
type TOG_CheckChangedCallbackSub as sub( byval hToggle as TK_WIDGET ptr, byval isChecked as boolean )
```

### Procedures

```freebasic
function tkToggle_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkToggle_GetChecked( byval hToggle as TK_WIDGET ptr ) as boolean
sub tkToggle_SetChecked( byval hToggle as TK_WIDGET ptr, byval isChecked as boolean )
function tkToggle_GetEnabled( byval hToggle as TK_WIDGET ptr ) as boolean
sub tkToggle_SetEnabled( byval hToggle as TK_WIDGET ptr, byval isEnabled as boolean )
function tkToggle_GetFocused( byval hToggle as TK_WIDGET ptr ) as boolean
sub tkToggle_Refresh( byval hToggle as TK_WIDGET ptr )
function tkToggle_GetHot( byval hToggle as TK_WIDGET ptr ) as boolean
function tkToggle_GetPressed( byval hToggle as TK_WIDGET ptr ) as boolean
function tkToggle_GetID( byval hToggle as TK_WIDGET ptr ) as long
sub tkToggle_GetTrackSize( byval hToggle as TK_WIDGET ptr, byref nTrackWidth as long, byref nTrackHeight as long )
sub tkToggle_SetTrackSize( byval hToggle as TK_WIDGET ptr, byval nTrackWidth as long, byval nTrackHeight as long )
function tkToggle_GetKnobInset( byval hToggle as TK_WIDGET ptr ) as long
sub tkToggle_SetKnobInset( byval hToggle as TK_WIDGET ptr, byval nKnobInset as long )
function tkToggle_GetBorderThickness( byval hToggle as TK_WIDGET ptr ) as long
sub tkToggle_SetBorderThickness( byval hToggle as TK_WIDGET ptr, byval nThickness as long )
sub tkToggle_GetFocusRing( byval hToggle as TK_WIDGET ptr, byref nGap as long, byref nThickness as long )
sub tkToggle_SetFocusRing( byval hToggle as TK_WIDGET ptr, byval nGap as long, byval nThickness as long )
function tkToggle_GetJustify( byval hToggle as TK_WIDGET ptr ) as long
sub tkToggle_SetJustify( byval hToggle as TK_WIDGET ptr, byval nJustify as long )
sub tkToggle_GetIdealSize( byval hToggle as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkToggle_GetTrackRect( byval hToggle as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkToggle_GetKnobRect( byval hToggle as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkToggle_GetVisualRect( byval hToggle as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkToggle_GetColors( byval hToggle as TK_WIDGET ptr, byval pColors as TKTOGGLE_COLORS ptr )
sub tkToggle_SetColors( byval hToggle as TK_WIDGET ptr, byval pColors as TKTOGGLE_COLORS ptr )
function tkToggle_ThemeColors( byref t as TKTHEME_COLORS ) as TKTOGGLE_COLORS
sub tkToggle_ApplyTheme( byval hToggle as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkToggle_UnpinColors( byval hToggle as TK_WIDGET ptr )
sub tkToggle_SetPaintCallback( byval hToggle as TK_WIDGET ptr, byval usersub as TOG_PaintCallbackSub )
sub tkToggle_PaintDefault( byval p as TKTOGGLE_PAINTINFO ptr )
sub tkToggle_SetTooltipText( byval hToggle as TK_WIDGET ptr, byval Text as ustring )
function tkToggle_GetTooltipText( byval hToggle as TK_WIDGET ptr ) as ustring
function tkToggle_GetTooltipHandle( byval hToggle as TK_WIDGET ptr ) as TK_TIP ptr
sub tkToggle_SetHoverTime( byval hToggle as TK_WIDGET ptr, byval ms as long )
sub tkToggle_SetAutoPopTime( byval hToggle as TK_WIDGET ptr, byval ms as long )
sub tkToggle_SetReshowTime( byval hToggle as TK_WIDGET ptr, byval ms as long )
sub tkToggle_SetMessageCallback( byval hToggle as TK_WIDGET ptr, byval userfunc as TOG_MessageCallbackFunc )
sub tkToggle_SetCheckChangedCallback( byval hToggle as TK_WIDGET ptr, byval usersub as TOG_CheckChangedCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip)
