[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkCheckedList**

# tkCheckedList

Shows a list with a check box on each item, so several can be picked at once.

`tkCheckedList` is the [tkControls](Category-tkControls) checked list box. It is a thin control over a
[tkListTree](tkListTree) with its check boxes on: flat, two-state, drawn by the list's stock row
painter. What it adds is an item table with a **key**, an ID and data per item, and a **value**: the
checked items' keys, in item order, as a list or as one delimited text.

Every setter is silent. The user's gestures (the box, Space, `+` / `-`, a row click with CheckOnClick)
fire `ItemCheck` before the change and `CheckedChanged` once after it. The Form Designer's
**CheckedList** binds its value as text.

## Importing

```freebasic
#import "vendor/tkControls/tkCheckedList"

using tkCheckedList
using tkListTree
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint) and SDL3), [tkTheme](tkTheme)
and [tkListTree](tkListTree). Add `using tkListTree` for the `LT_CHECK_*` constants or the inner list's
API.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Days_Changed( byval hList as TK_WIDGET ptr )
    print "days: " & tkCheckedList_GetCheckedText( hList )     ' "mon;wed"
end sub

function Days_Check( byval hList as TK_WIDGET ptr, byval idx as long, byref bNewChecked as boolean ) as boolean
    return idx <> 6                       ' Sunday stays as it is
end function

dim as TK_WIDGET ptr days = tkCheckedList_Create( tkHost_Root( host ), 100 )
tkCheckedList_AddItem( days, "Monday", "mon" )        ' text, key
tkCheckedList_AddItem( days, "Tuesday", "tue" )
tkCheckedList_AddItem( days, "Wednesday", "wed" )
tkCheckedList_AddItem( days, "Thursday", "thu" )
tkCheckedList_AddItem( days, "Friday", "fri" )
tkCheckedList_AddItem( days, "Saturday", "sat" )
tkCheckedList_AddItem( days, "Sunday", "sun" )      ' index 6
tkCheckedList_SetCheckedText( days, "mon;wed" )      ' silent: no callback
tkCheckedList_SetItemCheckCallback( days, @Days_Check )
tkCheckedList_SetCheckedChangedCallback( days, @Days_Changed )
tkWidget_SetPos( days, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), tkHost_Scale( host, 200 ), tkHost_Scale( host, 160 ) )
```

## Items and keys

- `AddItem( h, text, key, id, itemData )` appends; `InsertItem( h, idx, ... )` inserts (the index is
  clamped to 0..count). Both return the index. An item and its check move together when items are
  inserted or deleted.
- An item's **key** is what the value is made of. An empty key means "the text is the key";
  `GetItemKey` answers the key in use. Keys compare exactly (case-sensitive): `FindItemByKey` is
  exact, while `FindItemByText` ignores case.
- `SetItemEnabled( h, idx, false )` makes the row unselectable. Its box is drawn disabled and no
  gesture reaches it, but its check is kept and still part of the value.
- The list's rows ARE the items, in order; the list is never reordered.

## The value

- `GetCheckedKeys( h, keys() )` and `SetCheckedKeys( h, keys() )`: exactly the items whose key is in
  `keys()` end up checked, and keys no item has are ignored. Keys come back in item order.
- `GetCheckedText` and `SetCheckedText`, the bind pair, join and split on the **ValueSeparator** (`;`
  by default, `SetValueSeparator`). Each piece is trimmed, empty pieces are dropped, and an empty text
  unchecks everything. A key that contains the separator cannot make a round trip through the text.
- `SetChecked`, `GetChecked`, `GetCheckedCount`, `GetCheckedIndices( h, indices() )`, `CheckAll`.

## The user

The check boxes are the [tkListTree](tkListTree)'s. A press and release on the box toggles it, and the
selection is left alone. Space toggles the focused item (with `SetExtendedSelect`, every selected item
follows it). `+` checks and `-` unchecks. `SetCheckOnClick( h, true )` makes one click on a row select
it and toggle it (WinForms' CheckOnClick).

| Callback | Fires |
| --- | --- |
| `SetItemCheckCallback` | `CKL_ItemCheckCallbackFunc( h, idx, byref bNewChecked ) as boolean`: before a user's toggle; false vetoes it, and `bNewChecked` may be rewritten |
| `SetCheckedChangedCallback` | `CKL_CheckedChangedCallbackSub( h )`: once after a gesture that changed anything |
| `SetSelChangeCallback` | `CKL_SelChangeCallbackSub( h, idx )`: the user moved the current item |
| `SetActivateCallback` | `CKL_ActivateCallbackSub( h, idx )`: a double click or Enter on an item |

Every callback gets the checked list's handle, not the inner list's. `GetListTree( h )` reaches the
whole [tkListTree](tkListTree) API: fonts, colours, tooltips, the paint and message callbacks. The
list's SelChange, Activate, ItemCheck and ItemChecked callbacks belong to this control, so set them
here, not on the inner list.

## Colours

There is no colour struct. The rows are the list's stock painter, which draws in the theme's roles,
and the boxes are [tkCheckBox](tkCheckBox)'s colours for the theme. `tkListTree_SetCheckColors(
GetListTree( h ), ... )` pins the box colours.

## In the Form Designer

The toolbox's **CheckedList** (Lists) has the properties CheckOnClick, ExtendedSelect, ValueSeparator,
RowHeight and Font, and the events CheckedChanged (the default), ItemCheck (the handler sets
`Allow`), SelChange and Activate. Its design-time Items are added with `AddItem`; with no key, the
text is the key.

**Bind** moves the checked keys, as text, into and out of a field of the form's DataType (a `ustring`
holds `"mon;wed"`). An **ItemsSource** or **ItemsField** fills the items from an `Array( of T )`:
**DisplayField** is each item's text and **ValueField** its key. See
[Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKCHECKEDLIST_DEFAULT_SEPARATOR` (`";"`).

### Types

`TKCHECKEDLIST_ITEM` (Text, Key, id, itemData), `TKCHECKEDLIST_STATE` (per-instance; reach it through
the procedures), and the callback types `CKL_ItemCheckCallbackFunc`, `CKL_CheckedChangedCallbackSub`,
`CKL_SelChangeCallbackSub`, `CKL_ActivateCallbackSub`.

### Procedures

```freebasic
function tkCheckedList_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkCheckedList_GetListTree( byval h as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkCheckedList_GetID( byval h as TK_WIDGET ptr ) as long
function tkCheckedList_InsertItem( byval h as TK_WIDGET ptr, byval idx as long, byval Text as ustring, byval Key as ustring = "", byval id as long = 0, byval itemData as integer = 0 ) as long
function tkCheckedList_AddItem( byval h as TK_WIDGET ptr, byval Text as ustring, byval Key as ustring = "", byval id as long = 0, byval itemData as integer = 0 ) as long
function tkCheckedList_DeleteItem( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkCheckedList_Clear( byval h as TK_WIDGET ptr )
function tkCheckedList_GetCount( byval h as TK_WIDGET ptr ) as long
function tkCheckedList_GetItemText( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
function tkCheckedList_SetItemText( byval h as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkCheckedList_GetItemKey( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
function tkCheckedList_SetItemKey( byval h as TK_WIDGET ptr, byval idx as long, byval Key as ustring ) as boolean
function tkCheckedList_GetItemID( byval h as TK_WIDGET ptr, byval idx as long ) as long
function tkCheckedList_SetItemID( byval h as TK_WIDGET ptr, byval idx as long, byval id as long ) as boolean
function tkCheckedList_GetItemData( byval h as TK_WIDGET ptr, byval idx as long ) as integer
function tkCheckedList_SetItemData( byval h as TK_WIDGET ptr, byval idx as long, byval itemData as integer ) as boolean
function tkCheckedList_SetItemEnabled( byval h as TK_WIDGET ptr, byval idx as long, byval bEnabled as boolean ) as boolean
function tkCheckedList_GetItemEnabled( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkCheckedList_FindItemByKey( byval h as TK_WIDGET ptr, byval Key as ustring ) as long
function tkCheckedList_FindItemByText( byval h as TK_WIDGET ptr, byval Text as ustring ) as long
function tkCheckedList_SetChecked( byval h as TK_WIDGET ptr, byval idx as long, byval bChecked as boolean ) as boolean
function tkCheckedList_GetChecked( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkCheckedList_GetCheckedCount( byval h as TK_WIDGET ptr ) as long
function tkCheckedList_GetCheckedIndices( byval h as TK_WIDGET ptr, indices() as integer ) as long
sub tkCheckedList_CheckAll( byval h as TK_WIDGET ptr, byval bChecked as boolean )
function tkCheckedList_GetCheckedKeys( byval h as TK_WIDGET ptr, keys() as ustring ) as long
sub tkCheckedList_SetCheckedKeys( byval h as TK_WIDGET ptr, keys() as ustring )
sub tkCheckedList_SetValueSeparator( byval h as TK_WIDGET ptr, byval Sep as ustring )
function tkCheckedList_GetValueSeparator( byval h as TK_WIDGET ptr ) as ustring
function tkCheckedList_GetCheckedText( byval h as TK_WIDGET ptr ) as ustring
sub tkCheckedList_SetCheckedText( byval h as TK_WIDGET ptr, byval s as ustring )
function tkCheckedList_GetCurSel( byval h as TK_WIDGET ptr ) as long
function tkCheckedList_SetCurSel( byval h as TK_WIDGET ptr, byval idx as long ) as long
sub tkCheckedList_SetCheckOnClick( byval h as TK_WIDGET ptr, byval bEnable as boolean )
function tkCheckedList_GetCheckOnClick( byval h as TK_WIDGET ptr ) as boolean
sub tkCheckedList_SetExtendedSelect( byval h as TK_WIDGET ptr, byval bEnable as boolean )
sub tkCheckedList_SetFont( byval h as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkCheckedList_GetFont( byval h as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCheckedList_SetRowHeight( byval h as TK_WIDGET ptr, byval nHeight as long )
function tkCheckedList_GetRowHeight( byval h as TK_WIDGET ptr ) as long
function tkCheckedList_GetCheckRect( byval h as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
sub tkCheckedList_SetItemCheckCallback( byval h as TK_WIDGET ptr, byval userfunc as CKL_ItemCheckCallbackFunc )
sub tkCheckedList_SetCheckedChangedCallback( byval h as TK_WIDGET ptr, byval usersub as CKL_CheckedChangedCallbackSub )
sub tkCheckedList_SetSelChangeCallback( byval h as TK_WIDGET ptr, byval usersub as CKL_SelChangeCallbackSub )
sub tkCheckedList_SetActivateCallback( byval h as TK_WIDGET ptr, byval usersub as CKL_ActivateCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkListTree](tkListTree), whose check boxes this is built on; [tkCheckBox](tkCheckBox)
- [tkCheckedCombo](tkCheckedCombo), the same choice in a dropdown; [tkTokenBox](tkTokenBox), as chips
- [Form Designer](Form-Designer), data binding
