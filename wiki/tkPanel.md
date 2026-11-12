[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPanel**

# tkPanel

Groups controls on a plain background, with an optional border.

`tkPanel` is the [tkControls](Category-tkControls) container for grouping controls without a caption. It is never a tab stop. Children are parented to the panel (`tkPanel_Create` returns the widget to pass as their `hParent`) and are positioned relative to its top-left corner.

The background uses the theme's window colour and the border its border colour. `tkPanel_SetTransparent` skips the background fill, so what is behind the panel shows through. `tkPanel_SetBorderStyle` takes `PNL_BORDER_NONE` or `PNL_BORDER_LINE`; any other value becomes `PNL_BORDER_NONE`.

A paint callback draws over the background and border and under the children, for a panel that needs its own artwork.

A panel is also the page of a [tkTabControl](tkTabControl).

## Importing

```freebasic
#import "vendor/tkControls/tkPanel"

using tkPanel
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and SDL_image) and [tkTheme](tkTheme). The paint callback's `TK_PAINT` type comes from [tkPaint](tkPaint).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Card_Paint( byval p as TKPANEL_PAINTINFO ptr )
    p->b->SetPenColor( &hFF569CD6ul )
    p->b->PaintBorderRect( @p->rcClient )
end sub

dim as TK_WIDGET ptr card = tkPanel_Create( tkHost_Root( host ), 2100 )
tkPanel_SetBorderStyle( card, PNL_BORDER_LINE )
tkPanel_SetPaintCallback( card, @Card_Paint )
tkWidget_SetPos( card, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkHost_Scale( host, 300 ), tkHost_Scale( host, 160 ) )

' a child panel, placed relative to the card
dim as TK_WIDGET ptr kid = tkPanel_Create( card, 2101 )
tkWidget_SetPos( kid, tkHost_Scale( host, 10 ), tkHost_Scale( host, 10 ), _
                 tkHost_Scale( host, 100 ), tkHost_Scale( host, 40 ) )
```

## Typed wrapper

The module also provides `Panel`, a typed value for designed forms (see [tkForms](tkForms) and the [Form Designer](Form-Designer)). `Panel.Handle` is the `TK_WIDGET ptr`. It has `Create( hParent, id )`, `SetFocus( )`, and these properties, each read and write:

`Enabled`, `Visible`, `BackColor`, `BorderColor`, `BorderStyle`, `Transparent`.

## Behaviour notes

- `tkPanel_SetBackColor` and `tkPanel_SetBorderColor` pin the colours: they then survive a theme change until `tkPanel_UnpinColors`.
- The paint callback receives a `TKPANEL_PAINTINFO` with the panel, the `TK_PAINT ptr` for this frame and the client rectangle. It runs on every paint, after the fill and the border.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
enum
    PNL_BORDER_NONE = 0
    PNL_BORDER_LINE
end enum
```

### Types

```freebasic
type TKPANEL_COLORS
    BackColor   as ulong
    BorderColor as ulong
end type

type TKPANEL_PAINTINFO
    hPanel   as TK_WIDGET ptr
    b        as TK_PAINT ptr
    rcClient as TKRECT
end type

type TKPANEL_STATE   ' per-instance state; reach it through the procedures

type PNL_PaintCallbackSub as sub( byval p as TKPANEL_PAINTINFO ptr )
```

### Procedures

```freebasic
function tkPanel_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkPanel_GetBackColor( byval h as TK_WIDGET ptr ) as ulong
sub tkPanel_SetBackColor( byval h as TK_WIDGET ptr, byval clr as ulong )
function tkPanel_GetBorderColor( byval h as TK_WIDGET ptr ) as ulong
sub tkPanel_SetBorderColor( byval h as TK_WIDGET ptr, byval clr as ulong )
function tkPanel_GetBorderStyle( byval h as TK_WIDGET ptr ) as long
sub tkPanel_SetBorderStyle( byval h as TK_WIDGET ptr, byval nStyle as long )
function tkPanel_GetTransparent( byval h as TK_WIDGET ptr ) as boolean
sub tkPanel_SetTransparent( byval h as TK_WIDGET ptr, byval bTransparent as boolean )
sub tkPanel_SetPaintCallback( byval h as TK_WIDGET ptr, byval usersub as PNL_PaintCallbackSub )
function tkPanel_ThemeColors( byref t as TKTHEME_COLORS ) as TKPANEL_COLORS
sub tkPanel_ApplyTheme( byval h as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkPanel_UnpinColors( byval h as TK_WIDGET ptr )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme)
- [tkGroupBox](tkGroupBox), [tkTabControl](tkTabControl), [tkLayout](tkLayout)
