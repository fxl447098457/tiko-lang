[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkCheckBox**

# tkCheckBox

Draws a two-state checkbox with an optional caption on either side of the box.

`tkCheckBox` is the [tkControls](Category-tkControls) checkbox: a box, an optional single-line
caption and a focus ring around the pair. It has two states, checked and unchecked; there is no
indeterminate state. A click anywhere on the control, Space or Enter toggles it, and the
check-changed callback reports the new state after it has been applied.

By default the box is drawn as vectors (`CHK_BOXSTYLE_VECTOR`): a rounded square when unchecked,
the square filled with a knocked-out tick when checked. It needs no font, so it looks the same on
Windows, Linux and macOS. `CHK_BOXSTYLE_GLYPH` draws one font glyph per state instead.

## Importing

```freebasic
#import "vendor/tkControls/tkCheckBox"

using tkCheckBox
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` for a paint
callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Dark_Changed( byval hCheckBox as TK_WIDGET ptr, byval isChecked as boolean )
    print tkCheckBox_GetText( hCheckBox ) & ": " & isChecked
end sub

dim as TK_WIDGET ptr chk = tkCheckBox_Create( tkHost_Root( host ), 1001 )
tkCheckBox_SetText( chk, "Enable dark mode" )
tkCheckBox_SetChecked( chk, true )                 ' silent: no callback
tkCheckBox_SetCheckChangedCallback( chk, @Dark_Changed )

dim as long w, h
tkCheckBox_GetIdealSize( chk, w, h )
tkWidget_SetPos( chk, tkHost_Scale( host, 20 ), tkHost_Scale( host, 60 ), w, h )
```

## The box styles

- `CHK_BOXSTYLE_VECTOR` (default) paints the box in the mood's box colour. A paint callback can
  draw the same box with `tkCheckBox_DrawVectorBox`; `tkCheckBox_VectorSquare` and
  `tkCheckBox_VectorPen` give its square and pen width.
- `CHK_BOXSTYLE_GLYPH` draws `TKCHECKBOX_GLYPH_UNCHECKED` / `TKCHECKBOX_GLYPH_CHECKED` from the
  glyph font. Set that font with `tkCheckBox_SetGlyphFont` (the bundled `TK_FONT_ICONS`), and
  change the glyphs with `tkCheckBox_SetGlyphUnchecked` / `SetGlyphChecked`.

## Coming from PsCheckBox

[PsCheckBox](PsCheckBox) is the Win32 twin; its page remains the behaviour reference for
everything not listed here.

- Names: `PsCheckBox_*` → `tkCheckBox_*`, `PSCHECKBOX_*` → `TKCHECKBOX_*`. `CHK_BOXALIGN_*`,
  `CHK_TEXTALIGN_*`, `CHK_MOOD_*`, `CHK_PART_*` and the `CHK_*Callback*` types keep their names.
  The handle is `TK_WIDGET ptr`.
- `tkCheckBox_Create( hParent, ctrlId )` takes a `TK_WIDGET ptr` parent; for a top-level control
  pass `tkHost_Root( host )`.
- The box is vector-drawn by default rather than a Segoe Fluent Icons glyph pair; call
  `tkCheckBox_SetBoxStyle( h, CHK_BOXSTYLE_GLYPH )` for the glyph box. `TKCHECKBOX_PAINTINFO`
  gains `nBoxStyle`.
- Fonts are `TTF_Font ptr`, borrowed (`tkCheckBox_SetFont`, `SetGlyphFont`, `ApplyFonts`).
- Colours start from the current [tkTheme](tkTheme) palette.
- `TKCHECKBOX_MESSAGEINFO` carries `msg` (a `TKM_*` code), `x`, `y` and `key` instead of
  `uMsg` / `wParam` / `lParam`.
- The tooltip is a [tkTooltip](tkTooltip); `tkCheckBox_GetTooltipHandle` returns it. There is
  no tooltip mode and no comctl32 tooltip.
- Scale changes reach the control as `TKM_SCALECHANGED`; there is no `Rescale` call.
- No equivalent: window text (`WM_SETTEXT` / `WM_GETTEXT`), PsRegistry, the self-test.
- Added: the box styles (`CHK_BOXSTYLE_*`, `tkCheckBox_SetBoxStyle` / `GetBoxStyle`), the
  vector-box helpers, and `tkCheckBox_GetHot`, `GetPressed` and `GetTextSize`.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKCHECKBOX_GLYPH_UNCHECKED = !"\uF291"
const TKCHECKBOX_GLYPH_CHECKED = !"\uF28D"
const as long TKCHECKBOX_DEFAULT_PADLEFT = 4
const as long TKCHECKBOX_DEFAULT_PADTOP = 2
const as long TKCHECKBOX_DEFAULT_PADRIGHT = 4
const as long TKCHECKBOX_DEFAULT_PADBOTTOM = 2
const as long TKCHECKBOX_DEFAULT_BOXGAP = 8
const as long TKCHECKBOX_DEFAULT_BOXWIDTH = 16
const as long TKCHECKBOX_DEFAULT_BOXHEIGHT = 16
const as long TKCHECKBOX_DEFAULT_FOCUSGAP = 2
const as long TKCHECKBOX_DEFAULT_FOCUSCURV = 4 ' ellipse DIAMETER
const as long TKCHECKBOX_DEFAULT_FOCUSTHICK = 1 ' never scaled

enum
    CHK_BOXALIGN_LEFT = 0
    CHK_BOXALIGN_RIGHT
end enum

enum
    CHK_TEXTALIGN_LEFT = 0
    CHK_TEXTALIGN_CENTER
    CHK_TEXTALIGN_RIGHT
end enum

enum
    CHK_MOOD_IDLE = 0
    CHK_MOOD_HOT
    CHK_MOOD_PRESSED
    CHK_MOOD_DISABLED
end enum

enum
    CHK_PART_CONTROL = 0
    CHK_PART_BOX
    CHK_PART_TEXT
end enum

enum
    CHK_BOXSTYLE_VECTOR = 0      ' rounded square + polygon tick, no font needed (default)
    CHK_BOXSTYLE_GLYPH
end enum
```

### Types

```freebasic
type TKCHECKBOX_COLORS
    BackColor               as ulong = &hFF21252Bul    ' ( 33, 37, 43)
    BackColorHot            as ulong = &hFF21252Bul    ' = BackColor: flat out of the box
    BackColorPressed        as ulong = &hFF21252Bul
    BackColorDisabled       as ulong = &hFF21252Bul
    ForeColor               as ulong = &hFFC8CDD6ul    ' (200,205,214)
    ForeColorHot            as ulong = &hFFE2E6EEul    ' (226,230,238)
    ForeColorPressed        as ulong = &hFFFFFFFFul
    ForeColorDisabled       as ulong = &hFF606670ul    ' ( 96,102,112)
    BoxColor                as ulong = &hFF8A9099ul    ' (138,144,153)
    BoxColorHot             as ulong = &hFFB0B6BFul    ' (176,182,191)
    BoxColorPressed         as ulong = &hFFC8CDD6ul    ' (200,205,214)
    BoxColorDisabled        as ulong = &hFF545961ul    ' ( 84, 89, 97)
    BoxColorChecked         as ulong = &hFF569CD6ul    ' ( 86,156,214)
    BoxColorCheckedHot      as ulong = &hFF7AB4E6ul    ' (122,180,230)
    BoxColorCheckedPressed  as ulong = &hFF96C8F0ul    ' (150,200,240)
    BoxColorCheckedDisabled as ulong = &hFF384654ul    ' ( 56, 70, 84)
    FocusRingColor          as ulong = &hFF569CD6ul    ' ( 86,156,214)
end type

type TKCHECKBOX_PAINTINFO
    hCheckBox   as TK_WIDGET ptr
    b           as TK_PAINT ptr
    rcClient    as TKRECT
    rcContent   as TKRECT          ' rcClient deflated by the focus-ring band
    rcBox       as TKRECT          ' the box cell; never empty once sized
    rcText      as TKRECT          ' the caption SPAN, not the ink; empty with no caption
    rcVisual    as TKRECT          ' rcContent inflated by the band: where the ring goes
    isChecked   as boolean
    isHot       as boolean
    isPressed   as boolean         ' a live press AND the cursor still inside
    isEnabled   as boolean
    isFocused   as boolean
    wszText     as ustring
    wszGlyph    as ustring         ' already resolved for isChecked
    nBoxAlign   as long
    nTextAlign  as long
    nBoxStyle   as long            ' CHK_BOXSTYLE_* (added)
end type

type TKCHECKBOX_MESSAGEINFO
    hCheckBox as TK_WIDGET ptr
    msg       as long              ' TKM_*
    x         as single
    y         as single
    key       as long
end type

type TKCHECKBOX_STATE   ' per-instance state; reach it through the procedures

type CHK_PaintCallbackSub as sub( byval p as TKCHECKBOX_PAINTINFO ptr )
type CHK_MessageCallbackFunc as function( byval m as TKCHECKBOX_MESSAGEINFO ptr ) as boolean
type CHK_TooltipCallbackFunc as function( byval hCheckBox as TK_WIDGET ptr ) as ustring
type CHK_CheckChangedCallbackSub as sub( byval hCheckBox as TK_WIDGET ptr, byval isChecked as boolean )
```

### Procedures

```freebasic
function tkCheckBox_ResolveMood( byval isEnabled as boolean, byval isPressed as boolean, byval isHot as boolean ) as long
sub tkCheckBox_ResolveColors( byval pColors as TKCHECKBOX_COLORS ptr, byval nMood as long, byval isChecked as boolean, byref clrBack as ulong, byref clrFore as ulong, byref clrBox as ulong )
sub tkCheckBox_VectorSquare( byref rcCell as TKRECT, byref rcSq as TKRECT )
function tkCheckBox_VectorPen( byval side as long ) as long
sub tkCheckBox_DrawVectorBox( byval b as TK_PAINT ptr, byref rcCell as TKRECT, byval isChecked as boolean, byval clrBox as ulong, byval clrBack as ulong )
function tkCheckBox_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkCheckBox_GetText( byval hCheckBox as TK_WIDGET ptr ) as ustring
sub tkCheckBox_SetText( byval hCheckBox as TK_WIDGET ptr, byval Text as ustring )
function tkCheckBox_GetGlyphUnchecked( byval hCheckBox as TK_WIDGET ptr ) as ustring
sub tkCheckBox_SetGlyphUnchecked( byval hCheckBox as TK_WIDGET ptr, byval Glyph as ustring )
function tkCheckBox_GetGlyphChecked( byval hCheckBox as TK_WIDGET ptr ) as ustring
sub tkCheckBox_SetGlyphChecked( byval hCheckBox as TK_WIDGET ptr, byval Glyph as ustring )
function tkCheckBox_GetBoxStyle( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetBoxStyle( byval hCheckBox as TK_WIDGET ptr, byval nBoxStyle as long )
function tkCheckBox_GetID( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetID( byval hCheckBox as TK_WIDGET ptr, byval id as long )
function tkCheckBox_GetItemData( byval hCheckBox as TK_WIDGET ptr ) as integer
sub tkCheckBox_SetItemData( byval hCheckBox as TK_WIDGET ptr, byval itemData as integer )
function tkCheckBox_GetChecked( byval hCheckBox as TK_WIDGET ptr ) as boolean
sub tkCheckBox_SetChecked( byval hCheckBox as TK_WIDGET ptr, byval isChecked as boolean )
function tkCheckBox_GetEnabled( byval hCheckBox as TK_WIDGET ptr ) as boolean
sub tkCheckBox_SetEnabled( byval hCheckBox as TK_WIDGET ptr, byval isEnabled as boolean )
function tkCheckBox_GetFocused( byval hCheckBox as TK_WIDGET ptr ) as boolean
function tkCheckBox_GetHot( byval hCheckBox as TK_WIDGET ptr ) as boolean
function tkCheckBox_GetPressed( byval hCheckBox as TK_WIDGET ptr ) as boolean
sub tkCheckBox_Refresh( byval hCheckBox as TK_WIDGET ptr )
sub tkCheckBox_Toggle( byval hCheckBox as TK_WIDGET ptr )
function tkCheckBox_GetBoxAlign( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetBoxAlign( byval hCheckBox as TK_WIDGET ptr, byval nBoxAlign as long )
function tkCheckBox_GetTextAlign( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetTextAlign( byval hCheckBox as TK_WIDGET ptr, byval nTextAlign as long )
sub tkCheckBox_GetPadding( byval hCheckBox as TK_WIDGET ptr, byref nLeft as long, byref nTop as long, byref nRight as long, byref nBottom as long )
sub tkCheckBox_SetPadding( byval hCheckBox as TK_WIDGET ptr, byval nLeft as long, byval nTop as long, byval nRight as long, byval nBottom as long )
function tkCheckBox_GetBoxGap( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetBoxGap( byval hCheckBox as TK_WIDGET ptr, byval nBoxGap as long )
sub tkCheckBox_GetBoxSize( byval hCheckBox as TK_WIDGET ptr, byref nBoxWidth as long, byref nBoxHeight as long )
sub tkCheckBox_SetBoxSize( byval hCheckBox as TK_WIDGET ptr, byval nBoxWidth as long, byval nBoxHeight as long )
sub tkCheckBox_GetFocusRing( byval hCheckBox as TK_WIDGET ptr, byref nGap as long, byref nThickness as long )
sub tkCheckBox_SetFocusRing( byval hCheckBox as TK_WIDGET ptr, byval nGap as long, byval nThickness as long )
function tkCheckBox_GetFocusCurvature( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetFocusCurvature( byval hCheckBox as TK_WIDGET ptr, byval nCurvature as long )
function tkCheckBox_GetAutoSize( byval hCheckBox as TK_WIDGET ptr ) as boolean
sub tkCheckBox_SetAutoSize( byval hCheckBox as TK_WIDGET ptr, byval bAutoSize as boolean )
sub tkCheckBox_GetIdealSize( byval hCheckBox as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
sub tkCheckBox_GetTextSize( byval hCheckBox as TK_WIDGET ptr, byref tw as long, byref nTextH as long )
function tkCheckBox_GetContentRect( byval hCheckBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCheckBox_GetBoxRect( byval hCheckBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCheckBox_GetTextRect( byval hCheckBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCheckBox_GetVisualRect( byval hCheckBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkCheckBox_GetColors( byval hCheckBox as TK_WIDGET ptr, byval pColors as TKCHECKBOX_COLORS ptr )
sub tkCheckBox_SetColors( byval hCheckBox as TK_WIDGET ptr, byval pColors as TKCHECKBOX_COLORS ptr )
function tkCheckBox_ThemeColors( byref t as TKTHEME_COLORS ) as TKCHECKBOX_COLORS
sub tkCheckBox_ApplyTheme( byval hCheckBox as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkCheckBox_UnpinColors( byval hCheckBox as TK_WIDGET ptr )
function tkCheckBox_GetFont( byval hCheckBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCheckBox_SetFont( byval hCheckBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkCheckBox_GetGlyphFont( byval hCheckBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCheckBox_SetGlyphFont( byval hCheckBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkCheckBox_ApplyFonts( byval hCheckBox as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkCheckBox_SetTooltipText( byval hCheckBox as TK_WIDGET ptr, byval Text as ustring )
function tkCheckBox_GetTooltipText( byval hCheckBox as TK_WIDGET ptr ) as ustring
function tkCheckBox_GetTooltipHandle( byval hCheckBox as TK_WIDGET ptr ) as TK_TIP ptr
sub tkCheckBox_SetHoverTime( byval hCheckBox as TK_WIDGET ptr, byval ms as long )
sub tkCheckBox_SetAutoPopTime( byval hCheckBox as TK_WIDGET ptr, byval ms as long )
sub tkCheckBox_SetReshowTime( byval hCheckBox as TK_WIDGET ptr, byval ms as long )
sub tkCheckBox_SetPaintCallback( byval hCheckBox as TK_WIDGET ptr, byval usersub as CHK_PaintCallbackSub )
sub tkCheckBox_SetMessageCallback( byval hCheckBox as TK_WIDGET ptr, byval userfunc as CHK_MessageCallbackFunc )
sub tkCheckBox_SetTooltipCallback( byval hCheckBox as TK_WIDGET ptr, byval userfunc as CHK_TooltipCallbackFunc )
sub tkCheckBox_SetCheckChangedCallback( byval hCheckBox as TK_WIDGET ptr, byval usersub as CHK_CheckChangedCallbackSub )
function tkCheckBox_CountRenderedTones( byval hCheckBox as TK_WIDGET ptr, byval nPart as long ) as long
function tkCheckBox_HashRenderedPart( byval hCheckBox as TK_WIDGET ptr, byval nPart as long ) as ulong
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [PsCheckBox](PsCheckBox), the PsControls control
