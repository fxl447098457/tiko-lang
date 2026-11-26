[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkChipGroup**

# tkChipGroup

Draws a group of chips: items that flow left to right in wrapping rows, or one row that ends in a
`+N` chip, with no selection, one or many, and removable items.

`tkChipGroup` is the [tkControls](Category-tkControls) chip group: filter rows, single choices, tag
and people lists. Its items are data, not child widgets: each is laid out and drawn with
[tkChip](tkChip)'s widgetless painter, so hundreds of tags are one widget and one tab stop. The
group's selection is a set of keys, held apart from the items, so the items and the selection can
be set in either order.

Every setter is silent. `ItemClick` fires for a click when there is no selection; `SelChange` for
every change the user makes to the selection; `ItemRemoving` (which may veto) and `ItemRemoved` for
a removal by the user; `OverflowClick` for the `+N` chip. The Form Designer's **ChipGroup** binds its
selected keys as text, and **BindItems** its items.

## Importing

```freebasic
#import "vendor/tkControls/tkChipGroup"

using tkChipGroup
using tkChip
using tkHost
```

The module brings in [tkChip](tkChip) (`TKCHIP_COLORS` and the `TKCHIP_*` size, shape and appearance
constants) and with it [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkImage](tkImage), [tkBadge](tkBadge) and
[tkAvatar](tkAvatar). Add `using tkBadge` for the `TKBADGE_*` status constants.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Filters_SelChange( byval hGroup as TK_WIDGET ptr, byval idx as long, byval isSelected as boolean )
    print "filters: " & tkChipGroup_GetSelectedKeys( hGroup )
end sub

function People_Removing( byval hGroup as TK_WIDGET ptr, byval idx as long ) as boolean
    return tkChipGroup_GetItemKey( hGroup, idx ) <> "admin"      ' FALSE vetoes
end function

sub People_Removed( byval hGroup as TK_WIDGET ptr, byval Key as ustring )
    print "removed " & Key & "; left: " & tkChipGroup_GetItemsText( hGroup )
end sub

dim as TK_WIDGET ptr flt = tkChipGroup_Create( tkHost_Root( host ), 100 )
tkChipGroup_SetSelectionMode( flt, TKCHIPGRP_MULTI )
tkChipGroup_SetItemsText( flt, "Unread;Flagged;Attachments;This week" )
tkChipGroup_SetItemCountBadge( flt, 0, 12 )
tkChipGroup_SetSelectedKeys( flt, "Unread;Attachments" )      ' silent: no callback
tkChipGroup_SetSelChangeCallback( flt, @Filters_SelChange )

dim as TK_WIDGET ptr ppl = tkChipGroup_Create( tkHost_Root( host ), 101 )
tkChipGroup_SetRemovable( ppl, true )
tkChipGroup_AddItem( ppl, "Ada Lovelace", "ada" )
tkChipGroup_AddItem( ppl, "Grace Hopper", "grace" )
tkChipGroup_AddItem( ppl, "Administrator", "admin" )
tkChipGroup_SetItemLeadingAvatar( ppl, 0 )                    ' initials from the text
tkChipGroup_SetItemLeadingAvatar( ppl, 1 )
tkChipGroup_SetItemRemovingCallback( ppl, @People_Removing )
tkChipGroup_SetItemRemovedCallback( ppl, @People_Removed )

dim as long w = tkHost_Scale( host, 400 )
tkWidget_SetPos( flt, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, tkChipGroup_GetIdealHeight( flt, w ) )
tkWidget_SetPos( ppl, tkHost_Scale( host, 20 ), tkHost_Scale( host, 100 ), w, tkChipGroup_GetIdealHeight( ppl, w ) )
```

## Items

- `AddItem( h, text, key )` and `InsertItem( h, nBefore, text, key )` (`nBefore = -1` is the end)
  return the new index. The key defaults to the text. A key holding the `KeySeparator`, or one an
  item already has, is refused, and the answer is -1. Keys are the items' identity: the selection
  is by key.
- `RemoveItem` and `Clear` are silent and leave the selection's keys alone. `GetCount`,
  `FindItemByKey` (-1 when absent).
- Per item: `SetItemText` / `GetItemText`, `GetItemKey`, `SetItemLeadingAvatar( h, idx, name, img )`
  (initials from `name`, "" uses the text, or `img`, borrowed), `SetItemLeadingGlyph` (needs a glyph
  font from `ApplyFonts`), `SetItemEnabled` / `GetItemEnabled`, `SetItemRemovable` (else the group's
  `SetRemovable`), `SetItemStatus` (a `TKBADGE_*` status, as [tkChip](tkChip)'s), `SetItemCountBadge`
  (0 = none), `SetItemData` / `GetItemData` (an `integer` of yours) and `SetItemTooltip`.
- `GetItemsText` answers the items' keys joined by the `KeySeparator`. `SetItemsText( h, "a;b;c" )`
  replaces every item with one per key (text = key, empty pieces skipped), and keeps the selection.
- `SetKeySeparator` (default `;`; "" is ignored) splits and joins both the items and the keys. A
  separator found inside an item's key is refused.
- `SetSize`, `SetShape`, `SetAppearance`, `SetMaxLabelWidth` (design units; 0 = no limit) and
  `ApplyFonts( h, fText, fGlyph )` apply to every item, with [tkChip](tkChip)'s meanings. The group
  opens one bold font of its own for leading avatars.

## Wrap or one row

- `SetWrap( true )` (the default): items flow left to right, `ItemGap` apart, and start a new row
  `RowGap` below when the next would pass the right margin. A row always takes its first item, even
  one wider than the group. `SetGaps( itemGap, rowGap )` is in design units; both are 8.
- `GetIdealHeight( h, nWidth )` is the height the items take wrapped at `nWidth`, margins included;
  valid before the control is sized. With no items it is one chip's height. The group does not size
  itself: the host sizes it with this.
- `SetWrap( false )`: one row. The items that do not fit are hidden, and a `+N` chip takes their
  place, room for it kept inside the width. A click on it fires `OverflowClick`; its tooltip lists
  the hidden items' texts (ten, then "...").
- `GetIdealSize` is one row of every item, plus the margins.
- The margin on every side is the focus ring's band (`TKCHIPGRP_FOCUSGAP` scaled, plus
  `TKCHIPGRP_FOCUSTHICK`).

## Selection modes

`SetSelectionMode` rules what a click (or Space / Enter) on an item does.

| Mode | A click on an item |
| --- | --- |
| `TKCHIPGRP_NONE` (default) | fires `ItemClick`; the selection does not change |
| `TKCHIPGRP_SINGLE` | selects it; a click on the selected item keeps it |
| `TKCHIPGRP_SINGLE_OR_NONE` | selects it; a click on the selected item deselects it |
| `TKCHIPGRP_MULTI` | toggles it |

- When a single selection moves, `SelChange` fires for the old item (deselected), then for the new
  one (selected).
- Check marks show on selected items in `TKCHIPGRP_MULTI` only; `SetShowCheck` sets them on or off
  for every mode.
- `SetItemSelected` is silent; in the two single modes, selecting one clears the rest.
  `GetItemSelected`, and `GetCurSel` (the first selected item; -1 = none).
- The two single modes hold one key. Switching to one, or `SetSelectedKeys` in one, keeps the
  first selected item's key, else the first key given.

## The selection is a key set

- `SetSelectedKeys( h, "a;b" )` stores the set as given, keys not (yet) among the items included. An
  item added later with one of them is selected.
- `GetSelectedKeys` answers the keys of the items present that are selected, in item order.
- `SetItemsText`, `Clear` and `RemoveItem` keep the set. Setting the items and setting the selection
  therefore commute: either may come first, which is what a designed form's `LoadFrom` relies on.
- A removal by the user takes its key out of the set; a user's click in a single mode replaces the
  set with the one key.

## Removal

A removable item shows a remove button. The button, or **Delete** / **Backspace** on the focus
item, removes it:

1. `ItemRemoving( hGroup, idx )` fires. FALSE vetoes: nothing changes and nothing else fires. With no
   callback the removal goes ahead. The handler may change the items (the item is found again by
   its key), but must not destroy the group.
2. The group removes the item, and its key leaves the selection.
3. The focus moves to the next item, else the previous one. `RemoveItem` from code keeps the focus
   on the item it was on.
4. `ItemRemoved( hGroup, key )` fires.

A disabled item cannot be removed by the user. When no item is left, the focus ring goes round the
whole group. `RemoveItem` from code is silent.

## Reordering

`SetAllowReorder( true )` (default off) lets the user change the items' order:

- **Shift+Left** / **Shift+Right** move the focus item one place, among the items shown. At either
  end nothing moves (the key is still claimed). A disabled item does not move.
- **A drag**: a press on an item's body that moves more than 4 pixels (scaled) starts it; no click
  follows. While it lasts, a bar in the focus ring's colour marks where the item will go: in the
  gap before the first item of the row nearest the pointer whose centre is right of it, else after
  that row's last item. The release moves the item there. **Esc** cancels; a release outside the
  group moves nothing.
- Either way `ItemMoved( hGroup, nFrom, nTo )` fires after the move. The selection (a key set) and
  the focus item stay with their items. A bound **BindItems** saves the new order.
- `MoveItem( h, nFrom, nTo )` does the same from code, silently. `GetDropMark( h, rc )` answers the
  mark while a drag is on.

Items hidden behind a `+N` take no part: a drag drops among the items shown.

## Mouse and keyboard

The group is one tab stop with a roving focus item (`GetFocusItem` / `SetFocusItem`;
`TKCHIPGRP_OVERFLOW` is the `+N` chip). The layout keeps it valid: an item hidden behind the `+N`
gives its focus to the `+N`, and when the `+N` goes, the focus goes to the last item.

- A press focuses the group and makes the pressed item the focus item. The release acts only on the
  item and the part (body or remove button) the press began on: a press that slides off is
  cancelled. The remove button's hit target is at least 24 pixels across, scaled.
- **Left** / **Right**: the previous / next enabled item, no wrap. Right from the last item shown
  reaches the `+N`, and Left from it comes back.
- **Up** / **Down**: the enabled item in the row above / below whose centre is nearest the focus
  item's.
- **Home**: the first enabled item. **End**: the `+N` when there is one, else the last enabled item.
- **Space**, **Enter** and keypad **Enter**: a click on the focus item, by the mode; on the `+N`,
  `OverflowClick`. **Delete** / **Backspace**: remove the focus item, when it is removable. Held keys
  do not repeat.
- Disabled items are skipped by the keys and ignore the mouse. A disabled group takes no input,
  and draws its `+N` disabled too.
- A key with Ctrl, Alt or the GUI key held is not the group's: it goes on to the form.

## Notifications

| Callback | When |
| --- | --- |
| `SetItemClickCallback` | a click on an item in `TKCHIPGRP_NONE` |
| `SetSelChangeCallback` | every change the user makes to the selection; `isSelected` says which way |
| `SetItemRemovingCallback` | the user asked to remove an item; return FALSE to veto |
| `SetItemRemovedCallback` | the item is gone; the callback gets its key |
| `SetOverflowClickCallback` | a click on the `+N` chip, or Space / Enter on it |
| `SetItemMovedCallback` | the user moved an item (Shift+arrow or a drag); `nFrom`, `nTo` |
| `SetMessageCallback` | the input stream, with the item (`idx`) and the part under the pointer; TRUE claims a press, a release (no click) or a key |

The state is updated before a callback runs: inside `SelChange`, `GetSelectedKeys` already answers
the new set, and inside `ItemRemoved` the item is gone. There is no paint callback: the items are
drawn by tkChip's painter.

## Geometry

- `GetItemRect` answers an item's rect, FALSE for an item hidden behind the `+N`. `GetItemRow`
  answers its row.
- `GetRemoveRect` answers an item's remove target (FALSE when it has none); `GetOverflowRect` the
  `+N` chip's; `GetOverflowCount` how many items it hides (0 = none).
- `HitTest( h, x, y, part )` answers an item index, `TKCHIPGRP_OVERFLOW` or `TKCHIPGRP_HIT_NONE`,
  and sets `part` to `TKCHIP_HIT_BODY` or `TKCHIP_HIT_REMOVE`.
- `GetTipText( h, idx )` answers what the tooltip shows for an item (its own tooltip, else its full
  label when cut) or for `TKCHIPGRP_OVERFLOW`.
- All rects are in control-local pixels.

## Colours and theme

The group shares [tkChip](tkChip)'s `TKCHIP_COLORS`; an item's status tints them at paint, as a
chip's does. `tkChipGroup_ThemeColors( t )` answers `tkChip_ThemeColors( t )`; `ApplyTheme`
resolves the struct under the style name "ChipGroup". `SetColors` pins the struct (a theme change
leaves it) until `UnpinColors`.

## In the Form Designer

The toolbox's **ChipGroup** (Lists) has the properties above, in the order the form sets them:
KeySeparator first, because Items and SelectedKeys are both split by it; then SelectionMode, Items,
SelectedKeys, Removable, Wrap, AllowReorder, Gaps (ItemGap, RowGap), Size, Shape, Appearance and
MaxLabelWidth.
Items and SelectedKeys may come in either order, since the selection is a key set. Its events are
ItemClick, SelChange (the default), ItemRemoving (the handler sets `Allow`, which starts TRUE),
ItemRemoved, OverflowClick, ItemMoved and Message.

**Bind** moves the selected keys into and out of a text field of the form's DataType, joined by the
KeySeparator. **BindItems** moves the items the same way: a tag editor can bind its items, and a
filter row with designed Items its selection. The two load in either order. See
[Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKCHIPGRP_NONE`, `TKCHIPGRP_SINGLE`, `TKCHIPGRP_SINGLE_OR_NONE`, `TKCHIPGRP_MULTI` ·
`TKCHIPGRP_OVERFLOW` (the `+N` chip: HitTest, the focus item), `TKCHIPGRP_HIT_NONE` ·
`TKCHIPGRP_FOCUSGAP`, `TKCHIPGRP_FOCUSTHICK`. The look's constants are [tkChip](tkChip)'s.

### Types

`TKCHIPGRP_MESSAGEINFO` (the message, the item and the part), and the callback types
`CHG_ItemClickCallbackSub`, `CHG_SelChangeCallbackSub`, `CHG_ItemRemovingCallbackFunc`,
`CHG_ItemRemovedCallbackSub`, `CHG_OverflowClickCallbackSub`, `CHG_ItemMovedCallbackSub`,
`CHG_MessageCallbackFunc`. The colours
are tkChip's `TKCHIP_COLORS`.

### Procedures

```freebasic
function tkChipGroup_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkChipGroup_GetID( byval hGroup as TK_WIDGET ptr ) as long
sub tkChipGroup_SetEnabled( byval hGroup as TK_WIDGET ptr, byval isEnabled as boolean )
function tkChipGroup_InsertItem( byval hGroup as TK_WIDGET ptr, byval nBefore as long, byval Text as ustring,
function tkChipGroup_AddItem( byval hGroup as TK_WIDGET ptr, byval Text as ustring, byval Key as ustring = "" ) as long
sub tkChipGroup_RemoveItem( byval hGroup as TK_WIDGET ptr, byval idx as long )
sub tkChipGroup_Clear( byval hGroup as TK_WIDGET ptr )
function tkChipGroup_GetCount( byval hGroup as TK_WIDGET ptr ) as long
function tkChipGroup_FindItemByKey( byval hGroup as TK_WIDGET ptr, byval Key as ustring ) as long
sub tkChipGroup_MoveItem( byval hGroup as TK_WIDGET ptr, byval nFrom as long, byval nTo as long )
sub tkChipGroup_SetAllowReorder( byval hGroup as TK_WIDGET ptr, byval bOn as boolean )
function tkChipGroup_GetAllowReorder( byval hGroup as TK_WIDGET ptr ) as boolean
function tkChipGroup_GetDropMark( byval hGroup as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkChipGroup_GetItemText( byval hGroup as TK_WIDGET ptr, byval idx as long ) as ustring
sub tkChipGroup_SetItemText( byval hGroup as TK_WIDGET ptr, byval idx as long, byval Text as ustring )
function tkChipGroup_GetItemKey( byval hGroup as TK_WIDGET ptr, byval idx as long ) as ustring
sub tkChipGroup_SetItemLeadingAvatar( byval hGroup as TK_WIDGET ptr, byval idx as long, byval Name_ as ustring = "",
sub tkChipGroup_SetItemLeadingGlyph( byval hGroup as TK_WIDGET ptr, byval idx as long, byval Glyph as ustring )
sub tkChipGroup_SetItemEnabled( byval hGroup as TK_WIDGET ptr, byval idx as long, byval bOn as boolean )
function tkChipGroup_GetItemEnabled( byval hGroup as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkChipGroup_SetItemRemovable( byval hGroup as TK_WIDGET ptr, byval idx as long, byval bOn as boolean )
sub tkChipGroup_SetItemStatus( byval hGroup as TK_WIDGET ptr, byval idx as long, byval nStatus as long )
sub tkChipGroup_SetItemCountBadge( byval hGroup as TK_WIDGET ptr, byval idx as long, byval nCount as long )
sub tkChipGroup_SetItemData( byval hGroup as TK_WIDGET ptr, byval idx as long, byval nData as integer )
function tkChipGroup_GetItemData( byval hGroup as TK_WIDGET ptr, byval idx as long ) as integer
sub tkChipGroup_SetItemTooltip( byval hGroup as TK_WIDGET ptr, byval idx as long, byval Text as ustring )
function tkChipGroup_GetTipText( byval hGroup as TK_WIDGET ptr, byval idx as long ) as ustring
function tkChipGroup_GetSelectionMode( byval hGroup as TK_WIDGET ptr ) as long
sub tkChipGroup_SetSelectionMode( byval hGroup as TK_WIDGET ptr, byval nMode as long )
function tkChipGroup_GetItemSelected( byval hGroup as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkChipGroup_SetItemSelected( byval hGroup as TK_WIDGET ptr, byval idx as long, byval bOn as boolean )
function tkChipGroup_GetSelectedKeys( byval hGroup as TK_WIDGET ptr ) as ustring
sub tkChipGroup_SetSelectedKeys( byval hGroup as TK_WIDGET ptr, byval Keys as ustring )
function tkChipGroup_GetCurSel( byval hGroup as TK_WIDGET ptr ) as long
function tkChipGroup_GetItemsText( byval hGroup as TK_WIDGET ptr ) as ustring
sub tkChipGroup_SetItemsText( byval hGroup as TK_WIDGET ptr, byval Items as ustring )
function tkChipGroup_GetKeySeparator( byval hGroup as TK_WIDGET ptr ) as ustring
sub tkChipGroup_SetKeySeparator( byval hGroup as TK_WIDGET ptr, byval Sep as ustring )
sub tkChipGroup_SetRemovable( byval hGroup as TK_WIDGET ptr, byval bOn as boolean )
sub tkChipGroup_SetShowCheck( byval hGroup as TK_WIDGET ptr, byval bOn as boolean )
sub tkChipGroup_SetWrap( byval hGroup as TK_WIDGET ptr, byval bOn as boolean )
sub tkChipGroup_SetGaps( byval hGroup as TK_WIDGET ptr, byval nItemGapDu as long, byval nRowGapDu as long )
sub tkChipGroup_SetSize( byval hGroup as TK_WIDGET ptr, byval nSize as long )
sub tkChipGroup_SetShape( byval hGroup as TK_WIDGET ptr, byval nShape as long )
sub tkChipGroup_SetAppearance( byval hGroup as TK_WIDGET ptr, byval nAppearance as long )
sub tkChipGroup_SetMaxLabelWidth( byval hGroup as TK_WIDGET ptr, byval nDu as long )
sub tkChipGroup_ApplyFonts( byval hGroup as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
function tkChipGroup_GetIdealHeight( byval hGroup as TK_WIDGET ptr, byval nWidth as long ) as long
sub tkChipGroup_GetIdealSize( byval hGroup as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkChipGroup_GetItemRect( byval hGroup as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkChipGroup_GetItemRow( byval hGroup as TK_WIDGET ptr, byval idx as long ) as long
function tkChipGroup_GetRemoveRect( byval hGroup as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkChipGroup_GetOverflowRect( byval hGroup as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkChipGroup_GetOverflowCount( byval hGroup as TK_WIDGET ptr ) as long
function tkChipGroup_HitTest( byval hGroup as TK_WIDGET ptr, byval x as long, byval y as long, byref part as long ) as long
function tkChipGroup_GetFocusItem( byval hGroup as TK_WIDGET ptr ) as long
sub tkChipGroup_SetFocusItem( byval hGroup as TK_WIDGET ptr, byval idx as long )
sub tkChipGroup_GetColors( byval hGroup as TK_WIDGET ptr, byval pColors as TKCHIP_COLORS ptr )
sub tkChipGroup_SetColors( byval hGroup as TK_WIDGET ptr, byval pColors as TKCHIP_COLORS ptr )
function tkChipGroup_ThemeColors( byref t as TKTHEME_COLORS ) as TKCHIP_COLORS
sub tkChipGroup_ApplyTheme( byval hGroup as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkChipGroup_UnpinColors( byval hGroup as TK_WIDGET ptr )
sub tkChipGroup_SetItemClickCallback( byval hGroup as TK_WIDGET ptr, byval usersub as CHG_ItemClickCallbackSub )
sub tkChipGroup_SetSelChangeCallback( byval hGroup as TK_WIDGET ptr, byval usersub as CHG_SelChangeCallbackSub )
sub tkChipGroup_SetItemRemovingCallback( byval hGroup as TK_WIDGET ptr, byval userfunc as CHG_ItemRemovingCallbackFunc )
sub tkChipGroup_SetItemRemovedCallback( byval hGroup as TK_WIDGET ptr, byval usersub as CHG_ItemRemovedCallbackSub )
sub tkChipGroup_SetOverflowClickCallback( byval hGroup as TK_WIDGET ptr, byval usersub as CHG_OverflowClickCallbackSub )
sub tkChipGroup_SetItemMovedCallback( byval hGroup as TK_WIDGET ptr, byval usersub as CHG_ItemMovedCallbackSub )
sub tkChipGroup_SetMessageCallback( byval hGroup as TK_WIDGET ptr, byval userfunc as CHG_MessageCallbackFunc )
```

### See also

- [tkControls](Category-tkControls)
- [tkChip](tkChip), the standalone chip and the painter the items use
- [tkBadge](tkBadge), [tkAvatar](tkAvatar), the count and the leading avatar
- [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip)
- [Form Designer](Form-Designer), data binding
