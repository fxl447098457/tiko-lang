[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkOptionButton**

# tkOptionButton

Draws a radio button whose group allows at most one checked choice.

`tkOptionButton` is the [tkControls](Category-tkControls) radio button: a circle, an optional
single-line caption, and a dot in the circle when checked. Buttons belong to a group, named by
their parent widget and a group id, and checking one unchecks the others. Mutual exclusion is
handled inside the control: both state changes land before any callback runs, and the button
that lost is told first.

A group has one Tab stop. Inside it, the arrow keys move focus and the check (Up/Left to the
previous member, Down/Right to the next, wrapping and skipping disabled or hidden members), and
Space checks the focused button. Enter is left to the window. Arrow order is creation order.

## Importing

```freebasic
#import "vendor/tkControls/tkOptionButton"

using tkOptionButton
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` for a paint
callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
const as long GRP_QUALITY = 1

sub Quality_Changed( byval hOpt as TK_WIDGET ptr, byval isChecked as boolean )
    if isChecked then print "quality: " & tkOptionButton_GetText( hOpt )
end sub

dim as string captions(0 to 2) = { "Low", "Medium", "High" }
dim as TK_WIDGET ptr opt(0 to 2)
for i as long = 0 to 2
    opt(i) = tkOptionButton_Create( tkHost_Root( host ), 2000 + i, GRP_QUALITY )
    tkOptionButton_SetText( opt(i), captions(i) )
    tkOptionButton_SetCheckChangedCallback( opt(i), @Quality_Changed )
    dim as long w, h
    tkOptionButton_GetIdealSize( opt(i), w, h )
    tkWidget_SetPos( opt(i), tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 + i * 28 ), w, h )
next
tkOptionButton_SetChecked( opt(1), true )        ' silent: no callback

' later: which one is checked? (-1 when none)
print tkOptionButton_FindCheckedID( tkHost_Root( host ), GRP_QUALITY )
```

## Groups

- A group is the pair (parent widget, group id); for top-level buttons the parent is
  `tkHost_Root( host )`. Two groups on one parent never interfere, and buttons with different
  parents are never in one group. The id defaults to 0, so a parent with a single group needs no
  ids. `tkOptionButton_SetGroupID` moves a button later.
- A group starts with nothing checked, and `tkOptionButton_FindCheckedID` returns -1 for it
  (unanswered, not failed). The user can never get back there: clicking the checked member does
  nothing and no gesture unchecks. Only `SetChecked( h, false )` or `ClearGroup` empties a group.
- `SetChecked`, `SetGroupID` and `ClearGroup` are silent. `SetChecked` works on a disabled
  button, so saved settings can be restored onto a greyed-out form.
- A checked button moved by `SetGroupID` into a group that already has a checked member arrives
  unchecked; the group it left is left with nothing checked. Destroying the checked member also
  leaves its group with nothing checked: the check is not handed on.
- `GetGroupMember` counts in creation order. `SetID` changes the id `FindCheckedID` reports (the
  `ctrlId` given to `Create` until then); `SetItemData` stores a value the control never reads.
  Group calls given a widget that is not an option button answer 0 or false.

Exactly one member of a group is focusable, which makes the group one Tab stop: the checked member
if it is enabled, else the first enabled member, else the first. While focus is on a member, that
member holds the stop, so Tab leaves the group from wherever focus sits. The stop moves by itself
when the check moves, a member is enabled, disabled, regrouped or destroyed; do not set
focusability on these widgets yourself. `tkOptionButton_GetTabStop` says whether a member holds
it.

## Layout

A new button is 0 x 0. Size it from `tkOptionButton_GetIdealSize`, which is valid before the
button has ever been sized, or turn on `tkOptionButton_SetAutoSize`, which resizes it to its ideal
size, keeping its top-left, after any change that could alter it. The rects are derived from the
inputs and can be read but not set:

```
ringPad   = focusGap + focusThick          reserved always, focused or not
textBlock = caption ? boxGap + textW : 0
contentH  = max( caption ? textH : 0, boxHeight )

idealW    = 2*ringPad + padLeft + boxWidth + textBlock + padRight
idealH    = 2*ringPad + padTop  + contentH + padBottom
```

- The box cell sits against the padding on its `OPT_BOXALIGN_*` side, centred vertically, and the
  caption takes the whole span left over, placed in it by `OPT_TEXTALIGN_*`. Sized to its ideal
  size the button packs as `(o) Caption`; sized to a full row the circle sits at the far side. A
  column of `OPT_BOXALIGN_RIGHT` buttons of one width lines its circles up. The box side does not
  change the ideal size.
- `rcText` is the caption's span, not its ink, so the one-line caption has room to end in "…"
  when the button is too narrow. With no caption it is empty and the box gap is not charged; a
  caption-less button is also shorter, because its height ignores the font.
- `rcBox` is the declared cell; `rcCircle`, the largest centred square inside it, is what is drawn.
  They differ once the cell is not square, so a paint callback should draw round `rcCircle`.
- A dot size of 0 (the default) makes the dot 40% of the circle; a non-zero size is fixed, and no
  longer follows `SetBoxSize`. Either way it is at least 2 pixels and at most the circle.
- The caption font is also the measuring font; without one, the host's default font measures and
  draws.
- Setters take pixels; the defaults are scaled when the button is created. The ring and focus-ring
  thicknesses are drawn as given, never scaled. Negative sizes, padding and gaps clamp to 0, and
  out-of-range `SetBoxAlign` / `SetTextAlign` values are ignored. When the window's scale changes,
  padding, gap, box, a fixed dot size, focus gap and focus curvature rescale; the two thicknesses
  do not.
- The rect getters lay out first, so they are never stale. They return false while the button has
  no size, or when the rect is empty (`GetTextRect` with no caption).

## Mouse and keyboard

The whole client, caption included, is the hit area. A left press takes focus and the mouse
capture; the check lands on release inside. Slide off while pressed and the pressed look goes as
the cursor leaves; release outside and nothing is checked. Losing the capture cancels the press.
Right-button presses are reported to the message callback and otherwise ignored.

Space checks the focused button and the arrows move through the group as described above; Enter,
Tab and every other key go on to the window. A disabled button ignores the mouse and the keyboard,
drops any hover or press, and is stepped over by the arrows. `tkOptionButton_Click` checks a button
exactly as the user would, notifying; it is the way to give a button an accelerator. It does
nothing on a checked or disabled button.

## Callbacks

- **Check changed** fires only for the user's actions: a completed click, Space, an arrow move, or
  `tkOptionButton_Click`. Both edges fire, the loser first: checking B while A was checked calls
  `OnChanged( A, false )`, then `OnChanged( B, true )`. Both state changes land before either
  call, so `GetChecked` and `FindChecked` are coherent inside either one, and calling a setter from
  the handler cannot recurse. If only the winner matters, test `isChecked`.
- **Message** sees `TKM_MOUSEMOVE`, `TKM_MOUSELEAVE`, the left and right button messages,
  `TKM_SETFOCUS` / `TKM_KILLFOCUS` and `TKM_KEYDOWN`, as `msg`, `x`, `y` and `key`. Returning true
  vetoes a `TKM_LBUTTONDOWN` (focus has already moved) or a `TKM_KEYDOWN`, which arrives before
  Space or an arrow acts. Every other result is ignored: suppressing `TKM_LBUTTONUP` would strand
  the capture, and focus is a fact, not a request.
- **Paint** replaces the built-in drawing. The client is already filled with the state's back
  colour, so draw only what you add; `tkOptionButton_PaintDefault( p )` draws the stock look first
  if you want it. Draw the caption in the font given to `SetFont`, which measured the ideal width.
  Frame with `PaintRoundOutline`: `PaintBorderRect` fills before it strokes and `PaintEllipse`
  always fills, so either wipes what is under it. `tkOptionButton_CountRenderedTones` and
  `HashRenderedPart` render one `OPT_PART_*` rect with the current painter and the focus ring
  forced on, so a test can assert a paint callback has not flooded a part (tones cap at 64; both
  return 0 on failure).
- **Tooltip** text is the button's own `SetTooltipText` text, else the callback's answer, else
  nothing: the caption is never repeated as a tip. A press or disabling hides the tip.
  `SetHoverTime`, `SetAutoPopTime` and `SetReshowTime` set its delays, and
  `tkOptionButton_GetTooltipHandle` returns the [tkTooltip](tkTooltip) for any `tkTooltip_*` call.

## Colours and theme

The unchecked circle is filled with the back colour and stroked in `RingColor*`; the checked
circle is a disc in `RingColorChecked*` with the dot on it in `DotColor*`. `FocusRingColor` outlines
the visual rect while the button has focus, its corners rounded by the focus curvature (a
diameter). The state precedence is disabled, then pressed, then hot, then idle, and checked picks
between the two ring sets within it. `tkOptionButton_ResolveMood` and `ResolveColors` are pure, so
a paint callback can get exactly the colours the built-in drawing would use.

The button is flat by default: `BackColorHot`, `BackColorPressed` and `BackColorDisabled` equal
`BackColor`, so hovering changes only the circle and the caption. For a highlight across the row:

```freebasic
dim as TKOPTIONBUTTON_COLORS c
tkOptionButton_GetColors( hOpt, @c )
c.BackColorHot     = tkRGB( 44, 49, 58 )
c.BackColorPressed = tkRGB( 44, 49, 58 )
tkOptionButton_SetColors( hOpt, @c )
```

The dot sits on the accent fill, so it takes the theme's selected-text colour, and
`DotColorDisabled` equals the back colour: a disabled checked button reads as a hollow ring.

Colours start from the current [tkTheme](tkTheme) palette (`tkOptionButton_ThemeColors` is the
mapping) and follow theme changes. `SetColors` pins them, so theme changes pass the button by until
`tkOptionButton_UnpinColors` hands it back. The focus curvature follows the theme's corner radius
until `SetFocusCurvature` sets it. Fonts are `TTF_Font ptr`, borrowed; there is no glyph font, so
`tkOptionButton_ApplyFonts` ignores its glyph argument.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKOPTIONBUTTON_DEFAULT_PADLEFT = 4
const as long TKOPTIONBUTTON_DEFAULT_PADTOP = 2
const as long TKOPTIONBUTTON_DEFAULT_PADRIGHT = 4
const as long TKOPTIONBUTTON_DEFAULT_PADBOTTOM = 2
const as long TKOPTIONBUTTON_DEFAULT_BOXGAP = 8
const as long TKOPTIONBUTTON_DEFAULT_BOXWIDTH = 16
const as long TKOPTIONBUTTON_DEFAULT_BOXHEIGHT = 16
const as long TKOPTIONBUTTON_DEFAULT_RINGTHICK = 1 ' never scaled
const as long TKOPTIONBUTTON_DEFAULT_FOCUSTHICK = 1 ' never scaled
const as long TKOPTIONBUTTON_DEFAULT_DOTSIZE = 0 ' 0 = derive from the circle
const as long TKOPTIONBUTTON_DOTRATIO_PCT = 40
const as long TKOPTIONBUTTON_DEFAULT_FOCUSGAP = 2
const as long TKOPTIONBUTTON_DEFAULT_FOCUSCURV = 4 ' ellipse DIAMETER
const as long TKOPTIONBUTTON_DEFAULT_GROUPID = 0

enum
    OPT_BOXALIGN_LEFT = 0
    OPT_BOXALIGN_RIGHT
end enum

enum
    OPT_TEXTALIGN_LEFT = 0
    OPT_TEXTALIGN_CENTER
    OPT_TEXTALIGN_RIGHT
end enum

enum
    OPT_MOOD_IDLE = 0
    OPT_MOOD_HOT
    OPT_MOOD_PRESSED
    OPT_MOOD_DISABLED
end enum

enum
    OPT_PART_CONTROL = 0
    OPT_PART_BOX
    OPT_PART_TEXT
end enum
```

### Types

```freebasic
type TKOPTIONBUTTON_COLORS
    BackColor                as ulong = &hFF21252Bul    ' ( 33, 37, 43)
    BackColorHot             as ulong = &hFF21252Bul    ' = BackColor: flat out of the box
    BackColorPressed         as ulong = &hFF21252Bul
    BackColorDisabled        as ulong = &hFF21252Bul
    ForeColor                as ulong = &hFFC8CDD6ul    ' (200,205,214)
    ForeColorHot             as ulong = &hFFE2E6EEul    ' (226,230,238)
    ForeColorPressed         as ulong = &hFFFFFFFFul
    ForeColorDisabled        as ulong = &hFF606670ul    ' ( 96,102,112)
    RingColor                as ulong = &hFF8A9099ul    ' (138,144,153) the UNCHECKED outline
    RingColorHot             as ulong = &hFFB0B6BFul    ' (176,182,191)
    RingColorPressed         as ulong = &hFFC8CDD6ul    ' (200,205,214)
    RingColorDisabled        as ulong = &hFF545961ul    ' ( 84, 89, 97)
    RingColorChecked         as ulong = &hFF569CD6ul    ' ( 86,156,214) the CHECKED fill
    RingColorCheckedHot      as ulong = &hFF7AB4E6ul    ' (122,180,230)
    RingColorCheckedPressed  as ulong = &hFF96C8F0ul    ' (150,200,240)
    RingColorCheckedDisabled as ulong = &hFF384654ul    ' ( 56, 70, 84)
    DotColor                 as ulong = &hFFFFFFFFul    ' on the accent fill, not on the back
    DotColorHot              as ulong = &hFFFFFFFFul
    DotColorPressed          as ulong = &hFFFFFFFFul
    DotColorDisabled         as ulong = &hFF21252Bul    ' = BackColor: a hollow disabled ring
    FocusRingColor           as ulong = &hFF569CD6ul    ' ( 86,156,214)
end type

type TKOPTIONBUTTON_PAINTINFO
    hOptionButton as TK_WIDGET ptr
    b             as TK_PAINT ptr
    rcClient      as TKRECT
    rcContent     as TKRECT        ' rcClient deflated by the focus-ring band
    rcBox         as TKRECT        ' the declared box CELL
    rcCircle      as TKRECT        ' the largest centred square in rcBox: what is drawn round
    rcDot         as TKRECT        ' centred in rcCircle; computed checked or not
    rcText        as TKRECT        ' the caption SPAN, not the ink; empty with no caption
    rcVisual      as TKRECT        ' rcContent inflated by the band: where the ring goes
    isChecked     as boolean
    isHot         as boolean
    isPressed     as boolean       ' a live press AND the cursor still inside
    isEnabled     as boolean
    isFocused     as boolean
    wszText       as ustring
    nRingThick    as long          ' pen width in pixels (never scaled)
    nBoxAlign     as long
    nTextAlign    as long
end type

type TKOPTIONBUTTON_MESSAGEINFO
    hOptionButton as TK_WIDGET ptr
    msg           as long          ' TKM_*
    x             as single
    y             as single
    key           as long
end type

type TKOPTIONBUTTON_STATE   ' per-instance state; reach it through the procedures

type OPT_PaintCallbackSub as sub( byval p as TKOPTIONBUTTON_PAINTINFO ptr )
type OPT_MessageCallbackFunc as function( byval m as TKOPTIONBUTTON_MESSAGEINFO ptr ) as boolean
type OPT_TooltipCallbackFunc as function( byval hOptionButton as TK_WIDGET ptr ) as ustring
type OPT_CheckChangedCallbackSub as sub( byval hOptionButton as TK_WIDGET ptr, byval isChecked as boolean )
```

### Procedures

```freebasic
function tkOptionButton_ResolveMood( byval isEnabled as boolean, byval isPressed as boolean, byval isHot as boolean ) as long
sub tkOptionButton_ResolveColors( byval pColors as TKOPTIONBUTTON_COLORS ptr, byval nMood as long, byval isChecked as boolean, byref clrBack as ulong, byref clrFore as ulong, byref clrRing as ulong, byref clrDot as ulong )
function tkOptionButton_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long, byval nGroupID as long = TKOPTIONBUTTON_DEFAULT_GROUPID ) as TK_WIDGET ptr
function tkOptionButton_GetGroupID( byval hOptionButton as TK_WIDGET ptr ) as long
sub tkOptionButton_SetGroupID( byval hOptionButton as TK_WIDGET ptr, byval nGroupID as long )
function tkOptionButton_GetGroupCount( byval hOptionButton as TK_WIDGET ptr ) as long
function tkOptionButton_GetGroupMember( byval hOptionButton as TK_WIDGET ptr, byval idx as long ) as TK_WIDGET ptr
function tkOptionButton_GetGroupChecked( byval hOptionButton as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkOptionButton_FindChecked( byval hParent as TK_WIDGET ptr, byval nGroupID as long ) as TK_WIDGET ptr
function tkOptionButton_FindCheckedID( byval hParent as TK_WIDGET ptr, byval nGroupID as long ) as long
sub tkOptionButton_ClearGroup( byval hOptionButton as TK_WIDGET ptr )
function tkOptionButton_GetTabStop( byval hOptionButton as TK_WIDGET ptr ) as boolean
function tkOptionButton_GetText( byval hOptionButton as TK_WIDGET ptr ) as ustring
sub tkOptionButton_SetText( byval hOptionButton as TK_WIDGET ptr, byval Text as ustring )
function tkOptionButton_GetID( byval hOptionButton as TK_WIDGET ptr ) as long
sub tkOptionButton_SetID( byval hOptionButton as TK_WIDGET ptr, byval id as long )
function tkOptionButton_GetItemData( byval hOptionButton as TK_WIDGET ptr ) as integer
sub tkOptionButton_SetItemData( byval hOptionButton as TK_WIDGET ptr, byval itemData as integer )
function tkOptionButton_GetChecked( byval hOptionButton as TK_WIDGET ptr ) as boolean
sub tkOptionButton_SetChecked( byval hOptionButton as TK_WIDGET ptr, byval isChecked as boolean )
function tkOptionButton_GetEnabled( byval hOptionButton as TK_WIDGET ptr ) as boolean
sub tkOptionButton_SetEnabled( byval hOptionButton as TK_WIDGET ptr, byval isEnabled as boolean )
function tkOptionButton_GetFocused( byval hOptionButton as TK_WIDGET ptr ) as boolean
function tkOptionButton_GetHot( byval hOptionButton as TK_WIDGET ptr ) as boolean
function tkOptionButton_GetPressed( byval hOptionButton as TK_WIDGET ptr ) as boolean
sub tkOptionButton_Refresh( byval hOptionButton as TK_WIDGET ptr )
sub tkOptionButton_Click( byval hOptionButton as TK_WIDGET ptr )
function tkOptionButton_GetBoxAlign( byval hOptionButton as TK_WIDGET ptr ) as long
sub tkOptionButton_SetBoxAlign( byval hOptionButton as TK_WIDGET ptr, byval nBoxAlign as long )
function tkOptionButton_GetTextAlign( byval hOptionButton as TK_WIDGET ptr ) as long
sub tkOptionButton_SetTextAlign( byval hOptionButton as TK_WIDGET ptr, byval nTextAlign as long )
sub tkOptionButton_GetPadding( byval hOptionButton as TK_WIDGET ptr, byref nLeft as long, byref nTop as long, byref nRight as long, byref nBottom as long )
sub tkOptionButton_SetPadding( byval hOptionButton as TK_WIDGET ptr, byval nLeft as long, byval nTop as long, byval nRight as long, byval nBottom as long )
function tkOptionButton_GetBoxGap( byval hOptionButton as TK_WIDGET ptr ) as long
sub tkOptionButton_SetBoxGap( byval hOptionButton as TK_WIDGET ptr, byval nBoxGap as long )
sub tkOptionButton_GetBoxSize( byval hOptionButton as TK_WIDGET ptr, byref nBoxWidth as long, byref nBoxHeight as long )
sub tkOptionButton_SetBoxSize( byval hOptionButton as TK_WIDGET ptr, byval nBoxWidth as long, byval nBoxHeight as long )
function tkOptionButton_GetRingThickness( byval hOptionButton as TK_WIDGET ptr ) as long
sub tkOptionButton_SetRingThickness( byval hOptionButton as TK_WIDGET ptr, byval nThickness as long )
function tkOptionButton_GetDotSize( byval hOptionButton as TK_WIDGET ptr ) as long
sub tkOptionButton_SetDotSize( byval hOptionButton as TK_WIDGET ptr, byval nDotSize as long )
sub tkOptionButton_GetFocusRing( byval hOptionButton as TK_WIDGET ptr, byref nGap as long, byref nThickness as long )
sub tkOptionButton_SetFocusRing( byval hOptionButton as TK_WIDGET ptr, byval nGap as long, byval nThickness as long )
function tkOptionButton_GetFocusCurvature( byval hOptionButton as TK_WIDGET ptr ) as long
sub tkOptionButton_SetFocusCurvature( byval hOptionButton as TK_WIDGET ptr, byval nCurvature as long )
function tkOptionButton_GetAutoSize( byval hOptionButton as TK_WIDGET ptr ) as boolean
sub tkOptionButton_SetAutoSize( byval hOptionButton as TK_WIDGET ptr, byval bAutoSize as boolean )
sub tkOptionButton_GetIdealSize( byval hOptionButton as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
sub tkOptionButton_GetTextSize( byval hOptionButton as TK_WIDGET ptr, byref tw as long, byref nTextH as long )
function tkOptionButton_GetContentRect( byval hOptionButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkOptionButton_GetBoxRect( byval hOptionButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkOptionButton_GetCircleRect( byval hOptionButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkOptionButton_GetDotRect( byval hOptionButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkOptionButton_GetTextRect( byval hOptionButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkOptionButton_GetVisualRect( byval hOptionButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkOptionButton_GetColors( byval hOptionButton as TK_WIDGET ptr, byval pColors as TKOPTIONBUTTON_COLORS ptr )
sub tkOptionButton_SetColors( byval hOptionButton as TK_WIDGET ptr, byval pColors as TKOPTIONBUTTON_COLORS ptr )
function tkOptionButton_ThemeColors( byref t as TKTHEME_COLORS ) as TKOPTIONBUTTON_COLORS
sub tkOptionButton_ApplyTheme( byval hOptionButton as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkOptionButton_UnpinColors( byval hOptionButton as TK_WIDGET ptr )
function tkOptionButton_GetFont( byval hOptionButton as TK_WIDGET ptr ) as TTF_Font ptr
sub tkOptionButton_SetFont( byval hOptionButton as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkOptionButton_ApplyFonts( byval hOptionButton as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkOptionButton_SetTooltipText( byval hOptionButton as TK_WIDGET ptr, byval Text as ustring )
function tkOptionButton_GetTooltipText( byval hOptionButton as TK_WIDGET ptr ) as ustring
function tkOptionButton_GetTooltipHandle( byval hOptionButton as TK_WIDGET ptr ) as TK_TIP ptr
sub tkOptionButton_SetHoverTime( byval hOptionButton as TK_WIDGET ptr, byval ms as long )
sub tkOptionButton_SetAutoPopTime( byval hOptionButton as TK_WIDGET ptr, byval ms as long )
sub tkOptionButton_SetReshowTime( byval hOptionButton as TK_WIDGET ptr, byval ms as long )
sub tkOptionButton_PaintDefault( byval p as TKOPTIONBUTTON_PAINTINFO ptr )
sub tkOptionButton_SetPaintCallback( byval hOptionButton as TK_WIDGET ptr, byval usersub as OPT_PaintCallbackSub )
sub tkOptionButton_SetMessageCallback( byval hOptionButton as TK_WIDGET ptr, byval userfunc as OPT_MessageCallbackFunc )
sub tkOptionButton_SetTooltipCallback( byval hOptionButton as TK_WIDGET ptr, byval userfunc as OPT_TooltipCallbackFunc )
sub tkOptionButton_SetCheckChangedCallback( byval hOptionButton as TK_WIDGET ptr, byval usersub as OPT_CheckChangedCallbackSub )
function tkOptionButton_CountRenderedTones( byval hOptionButton as TK_WIDGET ptr, byval nPart as long ) as long
function tkOptionButton_HashRenderedPart( byval hOptionButton as TK_WIDGET ptr, byval nPart as long ) as ulong
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
