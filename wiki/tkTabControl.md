[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTabControl**

# tkTabControl

Shows one page of controls at a time under a strip of tabs.

`tkTabControl` is the [tkControls](Category-tkControls) tab container. It is a [tkTabBar](tkTabBar) across the top and one [tkPanel](tkPanel) page for each tab. Only the page of the selected tab is visible. To put controls on a tab, make them children of `tkTabControl_GetPage( tab, index )`.

The control itself is never a tab stop; its bar is. The bar takes a fixed height (`tkTabControl_SetTabHeight`, in design units) and the pages fill the rest of the control. Pages are laid out again when the control is resized or the scale changes.

`tkTabControl_AddPage` appends a tab and its empty page. The first page added is selected; adding later ones leaves the selection where it is. `tkTabControl_SetCurSel` is silent: the selection callback runs only when the user changes the tab.

For the strip's own styling (fonts, colours, glyphs, closable tabs) use the bar that `tkTabControl_GetTabBar` returns, with the [tkTabBar](tkTabBar) functions.

## Importing

```freebasic
#import "vendor/tkControls/tkTabControl"

using tkTabControl
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and SDL_image), [tkTheme](tkTheme), [tkTabBar](tkTabBar) and [tkPanel](tkPanel).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
#import "vendor/tkControls/tkLabel"
using tkLabel

sub Tabs_Changed( byval hTab as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
    print "tab " & idxOld & " to " & idxNew
end sub

dim as TK_WIDGET ptr tabs = tkTabControl_Create( tkHost_Root( host ), 2400 )
tkTabControl_AddPage( tabs, "General" )
tkTabControl_AddPage( tabs, "Advanced" )
tkTabControl_SetSelChangeCallback( tabs, @Tabs_Changed )

dim as TK_WIDGET ptr page1 = tkTabControl_GetPage( tabs, 1 )
dim as TK_WIDGET ptr note = tkLabel_Create( page1, 2401 )
tkLabel_SetText( note, "Settings for experts." )
tkWidget_SetPos( note, tkHost_Scale( host, 12 ), tkHost_Scale( host, 12 ), _
                 tkHost_Scale( host, 200 ), tkHost_Scale( host, 24 ) )

tkTabControl_SetCurSel( tabs, 1 )          ' silent: no callback
tkWidget_SetPos( tabs, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkHost_Scale( host, 400 ), tkHost_Scale( host, 240 ) )
```

## Typed wrapper

The module also provides `TabControl`, a typed value for designed forms (see [tkForms](tkForms) and the [Form Designer](Form-Designer)). `TabControl.Handle` is the `TK_WIDGET ptr`. It has `Create( hParent, id )`, `SetFocus( )`, and these properties, each read and write:

`Enabled`, `Visible`, `TabHeight`.

Pages are added through the procedures, with `TabControl.Handle`.

## Behaviour notes

- `tkTabControl_InsertPage( h, idx, text )` inserts at `idx`; `-1`, or an index past the end, appends. It returns the new index, or -1 on failure. Inserting before the selected tab keeps the same page selected.
- `tkTabControl_DeletePage` destroys the tab, its page and everything on the page. Do not call it from inside an event callback of a control on that page. It returns false for a bad index.
- `tkTabControl_SetCurSel` returns false for an index outside the pages, and changes nothing.
- `tkTabControl_GetCurSel` is -1 while there are no pages.
- `tkTabControl_GetPage` returns 0 for an index outside the pages.
- `tkTabControl_SetTabHeight` is in design units and ignores a negative value. The default is `TKTABCONTROL_DEFAULT_TABHEIGHT`.
- The control's bar has control id 1, and the pages take ids from 100 up. Give your own controls ids that do not clash within the same parent.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKTABCONTROL_DEFAULT_TABHEIGHT = 30
```

### Types

```freebasic
type TKTABCONTROL_STATE   ' per-instance state; reach it through the procedures

type TC_SelChangeCallbackSub as sub( byval hTabControl as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
```

### Procedures

```freebasic
function tkTabControl_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkTabControl_GetTabBar( byval h as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkTabControl_InsertPage( byval h as TK_WIDGET ptr, byval idx as long, byref text as const ustring ) as long
function tkTabControl_AddPage( byval h as TK_WIDGET ptr, byref text as const ustring ) as long
function tkTabControl_DeletePage( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabControl_GetPageCount( byval h as TK_WIDGET ptr ) as long
function tkTabControl_GetPage( byval h as TK_WIDGET ptr, byval idx as long ) as TK_WIDGET ptr
function tkTabControl_GetPageText( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
function tkTabControl_SetPageText( byval h as TK_WIDGET ptr, byval idx as long, byref text as const ustring ) as boolean
function tkTabControl_GetCurSel( byval h as TK_WIDGET ptr ) as long
function tkTabControl_SetCurSel( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabControl_GetTabHeight( byval h as TK_WIDGET ptr ) as long
sub tkTabControl_SetTabHeight( byval h as TK_WIDGET ptr, byval nHeight as long )
sub tkTabControl_SetSelChangeCallback( byval h as TK_WIDGET ptr, byval usersub as TC_SelChangeCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme)
- [tkTabBar](tkTabBar), [tkPanel](tkPanel), [tkLayout](tkLayout)
