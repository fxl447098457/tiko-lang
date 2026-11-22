[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkContextMenu**

# tkContextMenu

Opens a menu when a widget is right-clicked.

`tkContextMenu` is the [tkControls](Category-tkControls) right-click menu: a component, not a control. It is a hidden, zero-size child widget that owns a [tkPopupMenu](tkPopupMenu) menu. Attach it to widgets with `tkContextMenu_Attach`; then the right button's release over one of them, or over anything inside it, opens the menu at the pointer, and the Menu key or Shift+F10 on the focused one opens it below that widget. The control itself gets neither the release nor the key, so an attached menu **replaces** a control's own (a [tkTextBox](tkTextBox) or a [tkCodeEdit](tkCodeEdit) has one).

Fill the menu with the tkPopupMenu procedures, on the `TK_MENU ptr` that `tkContextMenu_GetMenu` returns; submenus are tkPopupMenu menus too. The Popup callback runs just before the menu opens and is told which widget it opens for, the moment to enable or check its items. The Command callback gets the id of the item chosen, from a submenu as well. A disabled component opens nothing. The component goes when its parent goes, and takes its menu and every attachment with it. Setters are silent.

A widget inside an attached one, with no menu of its own, opens its parent's menu; the Popup callback is then told the widget that has the menu.

## Importing

```freebasic
#import "vendor/tkControls/tkContextMenu"

using tkContextMenu
using tkPopupMenu
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme) and [tkPopupMenu](tkPopupMenu).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example, and `notes` a [tkTextBox](tkTextBox).

```freebasic
enum
    IDM_CLEAR = 300, IDM_UPPER
end enum

sub Notes_Popup( byval hCtx as TK_WIDGET ptr, byval hSource as TK_WIDGET ptr )
    tkPopupMenu_SetItemEnabled( tkContextMenu_GetMenu( hCtx ), IDM_CLEAR, len( tkTextBox_GetText( hSource ) ) > 0 )
end sub

sub Notes_Command( byval hCtx as TK_WIDGET ptr, byval id as long )
    dim as TK_WIDGET ptr tb = tkContextMenu_GetSource( hCtx )
    select case id
    case IDM_CLEAR : tkTextBox_SetText( tb, "" )
    case IDM_UPPER : tkTextBox_SetText( tb, ucase( tkTextBox_GetText( tb ) ) )
    end select
end sub

dim as TK_WIDGET ptr ctx = tkContextMenu_Create( tkHost_Root( host ), 2300 )
tkPopupMenu_AddItem( tkContextMenu_GetMenu( ctx ), IDM_CLEAR, "Clear" )
tkPopupMenu_AddItem( tkContextMenu_GetMenu( ctx ), IDM_UPPER, "Upper case" )
tkContextMenu_SetPopupCallback( ctx, @Notes_Popup )
tkContextMenu_SetCommandCallback( ctx, @Notes_Command )
tkContextMenu_Attach( ctx, notes )
```

## Typed wrapper

The module also provides `PopupMenu`, a typed value for designed forms (see [tkForms](tkForms) and the [Form Designer](Form-Designer)). `PopupMenu.Handle` is the `TK_WIDGET ptr`. It has `Create( hParent, id )` and the property `Enabled`, read and write. A component has no `Visible` and no `SetFocus`.

## Behaviour notes

- An attachment is within one surface: `tkContextMenu_Attach` with a widget of another window does nothing.
- A menu with no items opens nothing, but the Popup callback still runs (it may fill the menu).
- `tkContextMenu_Show` and `tkContextMenu_ShowFor` open it from code; `tkContextMenu_GetSource` answers the widget it last opened for.
- The right button's press still reaches the control (a text box takes the focus on it); only the release is the menu's.
- `tkContextMenu_Detach` gives a widget its own right button back.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Types

```freebasic
type CTX_PopupCallbackSub as sub( byval hCtx as TK_WIDGET ptr, byval hSource as TK_WIDGET ptr )
type CTX_CommandCallbackSub as sub( byval hCtx as TK_WIDGET ptr, byval id as long )

type TKCONTEXTMENU_STATE   ' per-instance state; reach it through the procedures
```

### Procedures

```freebasic
function tkContextMenu_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkContextMenu_GetMenu( byval h as TK_WIDGET ptr ) as TK_MENU ptr
sub tkContextMenu_Attach( byval h as TK_WIDGET ptr, byval hTarget as TK_WIDGET ptr )
sub tkContextMenu_Detach( byval hTarget as TK_WIDGET ptr )
sub tkContextMenu_Show( byval h as TK_WIDGET ptr, byval x as long, byval y as long, byval hSource as TK_WIDGET ptr = 0 )
sub tkContextMenu_ShowFor( byval h as TK_WIDGET ptr, byval hSource as TK_WIDGET ptr )
function tkContextMenu_GetSource( byval h as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkContextMenu_IsOpen( byval h as TK_WIDGET ptr ) as boolean
sub tkContextMenu_SetPopupCallback( byval h as TK_WIDGET ptr, byval usersub as CTX_PopupCallbackSub )
sub tkContextMenu_SetCommandCallback( byval h as TK_WIDGET ptr, byval usersub as CTX_CommandCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkPopupMenu](tkPopupMenu), [tkHost](tkHost)
- [Form Designer](Form-Designer)
