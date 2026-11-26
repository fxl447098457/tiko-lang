[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkCheckedCombo**

# tkCheckedCombo

Draws a combo button whose dropdown is a checked list of several picked values.

`tkCheckedCombo` is the [tkControls](Category-tkControls) multi-select combo. Its button looks like a
[tkComboBox](tkComboBox)'s: the same layout, moods, chevron and theme colours. Instead of the current
item it shows a **summary** of the checked ones: their names joined, a count, or as many names as fit
and `+k`. The dropdown is a check-box [tkListTree](tkListTree) in a popup. It can have a select-all
row, a type-to-filter line and an OK / Cancel footer.

By default each toggle in the list is the value at once. With `SetShowButtons( h, true )` the toggles
wait for OK. Every setter is silent; the user's toggles fire `ItemCheck` before and `CheckedChanged`
after. The Form Designer's **CheckedComboBox** binds its value as text.

## Importing

```freebasic
#import "vendor/tkControls/tkCheckedCombo"

using tkCheckedCombo
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint) and SDL3), [tkTheme](tkTheme),
[tkTooltip](tkTooltip), [tkComboBox](tkComboBox) and its dropdown, `tkItemPopup` (with
[tkListTree](tkListTree) and `tkMatch`). Add `using tkPaint` for a paint callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Colours_Changed( byval hCombo as TK_WIDGET ptr )
    print "colours: " & tkCheckedCombo_GetCheckedText( hCombo )    ' "red;blue"
end sub

dim as TK_WIDGET ptr cbo = tkCheckedCombo_Create( tkHost_Root( host ), 200 )
tkCheckedCombo_AddItem( cbo, "Red", "red" )          ' text, key
tkCheckedCombo_AddItem( cbo, "Green", "green" )
tkCheckedCombo_AddItem( cbo, "Blue", "blue" )
tkCheckedCombo_SetPlaceholderText( cbo, "Pick colours" )
tkCheckedCombo_SetSummaryMode( cbo, CCB_SUMMARY_FIT )
tkCheckedCombo_SetShowSelectAll( cbo, true )
tkCheckedCombo_SetCheckedText( cbo, "red;blue" )     ' silent: the button reads "Red, Blue"
tkCheckedCombo_SetCheckedChangedCallback( cbo, @Colours_Changed )
tkWidget_SetPos( cbo, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), tkHost_Scale( host, 180 ), tkHost_Scale( host, 28 ) )
```

## The summary

| `SetSummaryMode` | The button shows |
| --- | --- |
| `CCB_SUMMARY_JOIN` (default) | the checked items' text in item order, joined by the DisplaySeparator (`", "`), with an ellipsis when it does not fit |
| `CCB_SUMMARY_COUNT` | `SetCountFormat` with `{n}` (the checked count) and `{total}` (the item count): `"{n} selected"` |
| `CCB_SUMMARY_FIT` | as many names as fit the text area, then `SetMoreFormat` with `{k}`, the names left out: `"Red, Green +2"` |

With nothing checked the button shows `SetPlaceholderText` in the placeholder colour. With every item
checked it shows `SetAllText`, when that is set. `GetDisplayText` answers what the button shows now.
With no tooltip text of its own, the button's tooltip is the full list of names whenever the summary
cuts it short.

## The list

- **Opening.** A click opens the list, and so do F4, Alt+Down, Alt+Up, Space or Enter on the closed
  combo. Up / Down do nothing on the closed combo (there is no single value to step). Delete clears
  every check, with one `CheckedChanged`. `DropDown( h )` and `CloseUp( h, bCommit )` do the same
  from code; `IsDroppedDown` asks.
- **The popup never takes the keyboard focus** (`SDL_WINDOW_NOT_FOCUSABLE`): the combo keeps it, and
  the popup gets the keys. Up / Down / PgUp / PgDn / Home / End move the current row. Space toggles
  it, and a click on a row toggles that row. `+` / `-` check and uncheck when there is no filter.
  Ctrl+A checks every shown, enabled item, or unchecks them when all are checked. Enter, Tab, F4 or
  Alt+Up close the list and commit; Tab then moves the focus on. Escape closes and cancels. Any other Ctrl /
  Alt key is offered to the main window's accelerators.
- **`SetShowSelectAll( h, true )`** adds a select-all row (`SetSelectAllText`). It reads checked,
  unchecked or mixed over the **shown, enabled** items, and toggling it checks or unchecks exactly
  those.
- **`SetShowFilter( h, true )`** adds a filter line: typed text narrows the list to the items whose
  text contains it (case ignored), Backspace widens it, and Escape clears it before it closes the
  list. A filtered-out item keeps its check. With a filter, Space still toggles the row (it is never
  typed), while `+` and `-` are text. With ShowFilter on, the combo wants text input while it has the
  focus, so a character typed on the closed combo opens the list filtered by it.
- **`SetShowButtons( h, true )`** adds an OK / Cancel footer (`SetButtonTexts`). The toggles then edit
  a working copy. OK, Enter or Tab put it in, with one `CheckedChanged` if anything differs. Cancel,
  Escape or a click outside throw it away.
- **`SetMaxChecked( h, n )`** refuses a check beyond n, before `ItemCheck` is asked. At the limit the
  unchecked rows are drawn disabled.
- A disabled item (`SetItemEnabled`) cannot be toggled, and select-all leaves it as it is.
- `SetListMaxRows` (12) caps the rows shown; the list scrolls beyond it. `GetListTree`,
  `GetListRow( h, idx )`, `GetListHost`, `GetListButton` and `GetFilterText` reach the open list (for
  tests and hosts).

## The value

The value is the checked items' **keys**, in item order (an item's key, else its text):
`GetCheckedKeys` / `SetCheckedKeys`, and the bind pair `GetCheckedText` / `SetCheckedText`, which join
and split on the ValueSeparator (`;`), trim each piece and ignore unknown keys. `SetChecked`,
`GetChecked`, `GetCheckedCount`, `CheckAll`. Items: `AddItem( h, text, key, id, itemData )`,
`InsertItem`, `DeleteItem`, `Clear`, `SetItemText`, `FindItemByKey`. Adding, inserting, deleting
or clearing items closes an open list.

## Callbacks

| Callback | Fires |
| --- | --- |
| `SetItemCheckCallback` | `CCB_ItemCheckCallbackFunc( h, idx, bNewChecked ) as boolean`: before a user's toggle in the list (`idx` = -1 for select-all and Ctrl+A); false vetoes it |
| `SetCheckedChangedCallback` | `CCB_CheckedChangedCallbackSub( h )`: the value changed by the user (each toggle; with ShowButtons, once on OK) |
| `SetDropDownCallback` | `CCB_DropDownCallbackSub( h, isOpen )`: the list opened or closed |
| `SetPaintCallback` | `CCB_PaintCallbackSub( p )`: the button; `tkCheckedCombo_PaintDefault( p )` draws the stock one. `TKCHECKEDCOMBO_PAINTINFO` carries the rects, the moods, the summary text and its parts (`nChecked`, `nShown`, `nMore`) |
| `SetMessageCallback` | `CCB_MessageCallbackFunc( m ) as boolean`: the button's input; true claims a message |

## Colours and theme

`TKCHECKEDCOMBO_COLORS` has [tkComboBox](tkComboBox)'s fields: back, fore, border and chevron for
normal, hot, open and disabled, plus the placeholder and the focus ring.
`tkCheckedCombo_ThemeColors( t )` fills it from `tkComboBox_ThemeColors`, so the two combos look the
same, and a theme's **CheckedComboBox** recipes apply on top. `SetColors` pins the struct until
`UnpinColors`. The list's rows and boxes follow the theme ([tkListTree](tkListTree)'s stock painter,
[tkCheckBox](tkCheckBox)'s colours).

## In the Form Designer

The toolbox's **CheckedComboBox** (Common) has PlaceholderText, SummaryMode, CountFormat, MoreFormat,
AllText, DisplaySeparator, ValueSeparator, ShowSelectAll, SelectAllText, ShowFilter, ShowButtons,
ButtonTexts, MaxChecked, ListMaxRows, Font and TooltipText. Its events are CheckedChanged (the
default), ItemCheck (the handler sets `Allow`), DropDown, Paint and Message, and its colours are
edited in the Colors dialog.

**Bind** moves the checked keys, as text, into and out of a field of the form's DataType. An
**ItemsSource** or **ItemsField** fills the items from an `Array( of T )`: **DisplayField** is each
item's text and **ValueField** its key. See [Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`CCB_SUMMARY_JOIN`, `CCB_SUMMARY_COUNT`, `CCB_SUMMARY_FIT` · `TKCHECKEDCOMBO_DEFAULT_SEPARATOR` (`";"`).

### Types

`TKCHECKEDCOMBO_COLORS`, `TKCHECKEDCOMBO_ITEM` (Text, Key, id, itemData, bChecked, bEnabled),
`TKCHECKEDCOMBO_PAINTINFO`, `TKCHECKEDCOMBO_MESSAGEINFO`, `TKCHECKEDCOMBO_STATE` (per-instance), and
the callback types `CCB_PaintCallbackSub`, `CCB_MessageCallbackFunc`, `CCB_ItemCheckCallbackFunc`,
`CCB_CheckedChangedCallbackSub`, `CCB_DropDownCallbackSub`.

### Procedures

```freebasic
function tkCheckedCombo_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkCheckedCombo_GetID( byval h as TK_WIDGET ptr ) as long
function tkCheckedCombo_InsertItem( byval h as TK_WIDGET ptr, byval idx as long, byval Text as ustring, byval Key as ustring = "", byval id as long = 0, byval itemData as integer = 0 ) as long
function tkCheckedCombo_AddItem( byval h as TK_WIDGET ptr, byval Text as ustring, byval Key as ustring = "", byval id as long = 0, byval itemData as integer = 0 ) as long
function tkCheckedCombo_DeleteItem( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkCheckedCombo_Clear( byval h as TK_WIDGET ptr )
function tkCheckedCombo_GetCount( byval h as TK_WIDGET ptr ) as long
function tkCheckedCombo_GetItemText( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
function tkCheckedCombo_SetItemText( byval h as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkCheckedCombo_GetItemKey( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
function tkCheckedCombo_GetItemID( byval h as TK_WIDGET ptr, byval idx as long ) as long
function tkCheckedCombo_GetItemData( byval h as TK_WIDGET ptr, byval idx as long ) as integer
function tkCheckedCombo_SetItemEnabled( byval h as TK_WIDGET ptr, byval idx as long, byval bEnabled as boolean ) as boolean
function tkCheckedCombo_GetItemEnabled( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkCheckedCombo_FindItemByKey( byval h as TK_WIDGET ptr, byval Key as ustring ) as long
function tkCheckedCombo_SetChecked( byval h as TK_WIDGET ptr, byval idx as long, byval bChecked as boolean ) as boolean
function tkCheckedCombo_GetChecked( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkCheckedCombo_GetCheckedCount( byval h as TK_WIDGET ptr ) as long
sub tkCheckedCombo_CheckAll( byval h as TK_WIDGET ptr, byval bChecked as boolean )
function tkCheckedCombo_GetCheckedKeys( byval h as TK_WIDGET ptr, keys() as ustring ) as long
sub tkCheckedCombo_SetCheckedKeys( byval h as TK_WIDGET ptr, keys() as ustring )
sub tkCheckedCombo_SetValueSeparator( byval h as TK_WIDGET ptr, byval Sep as ustring )
function tkCheckedCombo_GetCheckedText( byval h as TK_WIDGET ptr ) as ustring
sub tkCheckedCombo_SetCheckedText( byval h as TK_WIDGET ptr, byval s as ustring )
function tkCheckedCombo_GetDisplayText( byval h as TK_WIDGET ptr ) as ustring
sub tkCheckedCombo_SetSummaryMode( byval h as TK_WIDGET ptr, byval nMode as long )
function tkCheckedCombo_GetSummaryMode( byval h as TK_WIDGET ptr ) as long
sub tkCheckedCombo_SetDisplaySeparator( byval h as TK_WIDGET ptr, byval Sep as ustring )
sub tkCheckedCombo_SetCountFormat( byval h as TK_WIDGET ptr, byval Fmt as ustring )
sub tkCheckedCombo_SetMoreFormat( byval h as TK_WIDGET ptr, byval Fmt as ustring )
sub tkCheckedCombo_SetAllText( byval h as TK_WIDGET ptr, byval Text as ustring )
sub tkCheckedCombo_SetPlaceholderText( byval h as TK_WIDGET ptr, byval Text as ustring )
function tkCheckedCombo_GetPlaceholderText( byval h as TK_WIDGET ptr ) as ustring
sub tkCheckedCombo_SetShowSelectAll( byval h as TK_WIDGET ptr, byval bShow as boolean )
sub tkCheckedCombo_SetSelectAllText( byval h as TK_WIDGET ptr, byval Text as ustring )
sub tkCheckedCombo_SetShowFilter( byval h as TK_WIDGET ptr, byval bShow as boolean )
sub tkCheckedCombo_SetShowButtons( byval h as TK_WIDGET ptr, byval bShow as boolean )
sub tkCheckedCombo_SetButtonTexts( byval h as TK_WIDGET ptr, byval OkText as ustring, byval CancelText as ustring )
sub tkCheckedCombo_SetMaxChecked( byval h as TK_WIDGET ptr, byval nMax as long )
sub tkCheckedCombo_SetListMaxRows( byval h as TK_WIDGET ptr, byval nRows as long )
sub tkCheckedCombo_SetFont( byval h as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkCheckedCombo_GetFont( byval h as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCheckedCombo_SetTooltipText( byval h as TK_WIDGET ptr, byval Text as ustring )
sub tkCheckedCombo_SetEnabled( byval h as TK_WIDGET ptr, byval bEnabled as boolean )
function tkCheckedCombo_GetEnabled( byval h as TK_WIDGET ptr ) as boolean
function tkCheckedCombo_GetTextRect( byval h as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCheckedCombo_DropDown( byval h as TK_WIDGET ptr ) as boolean
sub tkCheckedCombo_CloseUp( byval h as TK_WIDGET ptr, byval bCommit as boolean = false )
function tkCheckedCombo_IsDroppedDown( byval h as TK_WIDGET ptr ) as boolean
function tkCheckedCombo_GetListTree( byval h as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkCheckedCombo_GetListRow( byval h as TK_WIDGET ptr, byval idx as long ) as integer
function tkCheckedCombo_GetListHost( byval h as TK_WIDGET ptr ) as TK_HOST ptr
function tkCheckedCombo_GetListButton( byval h as TK_WIDGET ptr, byval bOK as boolean ) as TK_WIDGET ptr
function tkCheckedCombo_GetFilterText( byval h as TK_WIDGET ptr ) as ustring
sub tkCheckedCombo_GetColors( byval h as TK_WIDGET ptr, byval pColors as TKCHECKEDCOMBO_COLORS ptr )
sub tkCheckedCombo_SetColors( byval h as TK_WIDGET ptr, byval pColors as TKCHECKEDCOMBO_COLORS ptr )
function tkCheckedCombo_ThemeColors( byref t as TKTHEME_COLORS ) as TKCHECKEDCOMBO_COLORS
sub tkCheckedCombo_ApplyTheme( byval hCombo as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkCheckedCombo_UnpinColors( byval h as TK_WIDGET ptr )
sub tkCheckedCombo_PaintDefault( byval pi as TKCHECKEDCOMBO_PAINTINFO ptr )
sub tkCheckedCombo_SetPaintCallback( byval h as TK_WIDGET ptr, byval usersub as CCB_PaintCallbackSub )
sub tkCheckedCombo_SetMessageCallback( byval h as TK_WIDGET ptr, byval userfunc as CCB_MessageCallbackFunc )
sub tkCheckedCombo_SetItemCheckCallback( byval h as TK_WIDGET ptr, byval userfunc as CCB_ItemCheckCallbackFunc )
sub tkCheckedCombo_SetCheckedChangedCallback( byval h as TK_WIDGET ptr, byval usersub as CCB_CheckedChangedCallbackSub )
sub tkCheckedCombo_SetDropDownCallback( byval h as TK_WIDGET ptr, byval usersub as CCB_DropDownCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkComboBox](tkComboBox), whose button this is; [tkListTree](tkListTree), the list in the popup
- [tkCheckedList](tkCheckedList), the same choice as a list; [tkTokenBox](tkTokenBox), as chips
- [Form Designer](Form-Designer), data binding
