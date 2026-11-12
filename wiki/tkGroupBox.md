[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkGroupBox**

# tkGroupBox

Frames a set of controls under a caption.

`tkGroupBox` is the [tkControls](Category-tkControls) frame with a caption set into its top edge. It is never a tab stop. Children are parented to the box (`tkGroupBox_Create` returns the widget to pass as their `hParent`) and are positioned relative to its top-left corner.

The frame leaves room for the caption and some padding. `tkGroupBox_GetClientRect` answers the area inside the frame and below the caption, in the box's own pixels, so you place children inside it. It has the shape [tkLayout](tkLayout) wants for a container's docking area: pass `@tkGroupBox_GetClientRect` to `tkLayout_AddContainer` and docked children stay inside the frame.

The caption is one line, left-aligned and cut with an ellipsis when it is wider than the box. The frame line stops either side of it. It is drawn in the theme's dim text colour.

## Importing

```freebasic
#import "vendor/tkControls/tkGroupBox"

using tkGroupBox
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and SDL_image) and [tkTheme](tkTheme).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
#import "vendor/tkControls/tkCheckBox"
using tkCheckBox

dim as TK_WIDGET ptr box = tkGroupBox_Create( tkHost_Root( host ), 2200 )
tkGroupBox_SetText( box, "Options" )
tkWidget_SetPos( box, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkHost_Scale( host, 240 ), tkHost_Scale( host, 120 ) )

dim as TKRECT rc
tkGroupBox_GetClientRect( box, rc )

dim as TK_WIDGET ptr chk = tkCheckBox_Create( box, 2201 )
tkCheckBox_SetText( chk, "Show line numbers" )
tkWidget_SetPos( chk, rc.left, rc.top, rc.right - rc.left, tkHost_Scale( host, 24 ) )
```

## Typed wrapper

The module also provides `GroupBox`, a typed value for designed forms (see [tkForms](tkForms) and the [Form Designer](Form-Designer)). `GroupBox.Handle` is the `TK_WIDGET ptr`. It has `Create( hParent, id )`, `SetFocus( )`, and these properties, each read and write:

`Enabled`, `Visible`, `Text`, `Font`.

## Behaviour notes

- `TKGROUPBOX_PADDING`, `TKGROUPBOX_CAPTION_INDENT` and `TKGROUPBOX_CAPTION_GAP` are design units, scaled with `tkHost_Scale` when used.
- The client rectangle starts `TKGROUPBOX_PADDING` in from the left edge and that far plus the caption height down from the top. It ends the padding short of the right and bottom edges. It never has a negative size.
- `tkGroupBox_SetFont` borrows the font: it must outlive the box. Pass 0 to return to the surface's default font.
- `tkGroupBox_SetColors` pins the colours: they then survive a theme change until `tkGroupBox_UnpinColors`.
- `tkGroupBox_GetClientRect` returns false for a null handle.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKGROUPBOX_PADDING = 8
const as long TKGROUPBOX_CAPTION_INDENT = 10
const as long TKGROUPBOX_CAPTION_GAP = 4
```

### Types

```freebasic
type TKGROUPBOX_COLORS
    BackColor         as ulong
    BorderColor       as ulong
    TextColor         as ulong
    TextColorDisabled as ulong
end type

type TKGROUPBOX_STATE   ' per-instance state; reach it through the procedures
```

### Procedures

```freebasic
function tkGroupBox_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkGroupBox_GetText( byval h as TK_WIDGET ptr ) as ustring
sub tkGroupBox_SetText( byval h as TK_WIDGET ptr, byref s as const ustring )
sub tkGroupBox_SetFont( byval h as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkGroupBox_GetFont( byval h as TK_WIDGET ptr ) as TTF_Font ptr
function tkGroupBox_GetClientRect( byval h as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkGroupBox_SetColors( byval h as TK_WIDGET ptr, byref c as const TKGROUPBOX_COLORS )
function tkGroupBox_GetColors( byval h as TK_WIDGET ptr ) as TKGROUPBOX_COLORS
function tkGroupBox_ThemeColors( byref t as TKTHEME_COLORS ) as TKGROUPBOX_COLORS
sub tkGroupBox_ApplyTheme( byval h as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkGroupBox_UnpinColors( byval h as TK_WIDGET ptr )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme)
- [tkPanel](tkPanel), [tkLayout](tkLayout)
