[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **TreeView**

# TreeView

Adds, finds, expands, selects and styles the items of a tree view control.

A tree view shows a hierarchy of items, each with a label, optional images and an application
value (`lParam`). Every function here takes the control's handle first and is written with the
namespace: `TreeView.AddRootItem( hTree, "Fruit" )`. Create the control with
`CWindow.AddControl( "TreeView", ... )`, which gives it buttons, lines and lines at the root.

An item is an `HTREEITEM` handle. The control owns its items; a handle stays valid until the
item, an ancestor or the whole tree is deleted. Four special handles stand for positions rather
than items: `TVI_ROOT` (the invisible parent of the root items), `TVI_FIRST`, `TVI_LAST` and
`TVI_SORT` (where to insert). Functions that return an item return `NULL` when there is none.

Coordinates are client coordinates of the tree view. Image lists, drag images and colours are
the program's to manage: the control does not destroy an image list you give it. A few messages
need version 6 of the common controls, which a program selects with a manifest; without it
[GetExtendedStyle](#getextendedstyle), [SetExtendedStyle](#setextendedstyle),
[GetItemPartRect](#getitempartrect) and the accessibility mappings return 0.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A tree of fruit and vegetables. Selecting an item puts its text, its parent's text and its
`lParam` in the caption.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_TREE = 101

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "TreeDemo"
    dim hWin as HWND = pWindow.Create( NULL, "TreeView", @WndProc )
    pWindow.SetClientSize( 300, 320 )
    pWindow.Center()
    dim hTree as HWND = pWindow.AddControl( "TreeView", hWin, IDC_TREE, "", 10, 10, 280, 300 )
    dim hFruit as HTREEITEM = TreeView.AddRootItem( hTree, "Fruit" )
    TreeView.AppendItem( hTree, hFruit, "Banana", 1 )
    TreeView.AppendItem( hTree, hFruit, "Apple", 2 )
    TreeView.InsertSortedItem( hTree, hFruit, "Cherry", 3 )
    dim hVeg as HTREEITEM = TreeView.AddRootItem( hTree, "Vegetables" )
    TreeView.AppendItem( hTree, hVeg, "Leek", 4 )
    TreeView.AppendItem( hTree, hVeg, "Carrot", 5 )
    TreeView.SortChildren( hTree, hVeg, false )
    TreeView.SetBold( hTree, hFruit, true )
    TreeView.SetBold( hTree, hVeg, true )
    TreeView.ExpandAllItems( hTree )
    TreeView.SelectItem( hTree, hFruit )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_NOTIFY
            dim pnmh as NMHDR ptr = CBNMHDR( wParam, lParam )
            if pnmh->idFrom = IDC_TREE andalso pnmh->code = TVN_SELCHANGEDW then
                dim pnmtv as NMTREEVIEWW ptr = CBNMSGPTR( NMTREEVIEWW, wParam, lParam )
                dim hItem as HTREEITEM = pnmtv->itemNew.hItem
                SetWindowText( hwnd, TreeView.GetItemText( pnmh->hwndFrom, hItem ) & _
                                     " in [" & TreeView.GetParentText( pnmh->hwndFrom, hItem ) & _
                                     "], lParam " & TreeView.GetlParam( pnmh->hwndFrom, hItem ) )
            end if
            return 0
        case WM_DESTROY
            PostQuitMessage( 0 )
            return 0
    end select
    return DefWindowProcW( hwnd, uMsg, wParam, lParam )
end function

end main()
```

## Functions

| Function | Does |
| --- | --- |
| [AddRootItem](#addrootitem) | Adds an item at the end of the root level. |
| [AppendItem](#appenditem) | Adds an item as the last child of a parent. |
| [InsertFirstItem](#insertfirstitem) | Adds an item as the first child of a parent. |
| [InsertSortedItem](#insertsorteditem) | Adds an item among a parent's children in alphabetical order. |
| [InsertItem](#insertitem) | Inserts an item from a `TVINSERTSTRUCTW` or from text, images and a value. |
| [Insert](#insert) | Inserts an item with images and text, in that order. |
| [DeleteItem](#deleteitem) | Deletes an item and all its children. |
| [DeleteAllItems, Reset](#deleteallitems-reset) | Deletes every item. |
| [GetItem](#getitem) | Reads an item's attributes into a `TVITEMW`. |
| [GetItemEx](#getitemex) | Reads an item's attributes into a `TVITEMEXW`. |
| [SetItem](#setitem) | Sets an item's attributes from a `TVITEMW`. |
| [SetItemEx](#setitemex) | Sets an item's attributes from a `TVITEMEXW`. |
| [GetItemText](#getitemtext) | Returns or reads an item's text. |
| [SetItemText, SetText](#setitemtext-settext) | Changes an item's text. |
| [GetlParam](#getlparam) | Returns an item's application value. |
| [GetItemState](#getitemstate) | Returns some of an item's state bits. |
| [SetItemState](#setitemstate) | Sets some of an item's state bits. |
| [GetBold](#getbold) | Tells whether an item is drawn in bold. |
| [SetBold](#setbold) | Draws an item in bold or not. |
| [GetCheckState](#getcheckstate) | Returns an item's state image index (its check box state). |
| [IsItemChecked, GetCheck](#isitemchecked-getcheck) | Tests an item's state image index against 1. |
| [SetCheckState, SetCheck](#setcheckstate-setcheck) | Checks or unchecks an item's check box. |
| [Expand](#expand) | Expands, collapses or toggles an item. |
| [ExpandPartial](#expandpartial) | Partly expands an item. |
| [Collapse](#collapse) | Collapses an item. |
| [CollapseReset](#collapsereset) | Collapses an item and deletes its children. |
| [Toggle](#toggle) | Expands a collapsed item or collapses an expanded one. |
| [ExpandChildItems](#expandchilditems) | Expands an item and its line of first children. |
| [ExpandAllChildItems](#expandallchilditems) | Expands an item, the siblings after it and all their descendants. |
| [ExpandSiblings](#expandsiblings) | Expands an item and the siblings after it. |
| [ExpandAllItems](#expandallitems) | Expands every item in the tree. |
| [CollapseChildItems](#collapsechilditems) | Collapses an item and its line of first children. |
| [CollapseAllChildItems](#collapseallchilditems) | Collapses an item, the siblings after it and all their descendants. |
| [CollapseSiblings](#collapsesiblings) | Collapses an item and the siblings after it. |
| [CollapseAllItems](#collapseallitems) | Collapses every item in the tree. |
| [GetNextItem](#getnextitem) | Returns the item in a given relation to another. |
| [GetRoot](#getroot) | Returns the first root item. |
| [GetChild](#getchild) | Returns an item's first child. |
| [NextSibling, GetNext](#nextsibling-getnext) | Returns the next sibling. |
| [PrevSibling, GetPrevious](#prevsibling-getprevious) | Returns the previous sibling. |
| [GetParent](#getparent) | Returns an item's parent. |
| [GetParentText](#getparenttext) | Returns or reads the text of an item's parent. |
| [GetSelection, GetSelect](#getselection-getselect) | Returns the selected item. |
| [GetNextSelected](#getnextselected) | Returns the next selected item in a tree with several selections. |
| [GetDropHilight](#getdrophilight) | Returns the item highlighted as a drop target. |
| [GetFirstVisible](#getfirstvisible) | Returns the item at the top of the window. |
| [GetNextVisible](#getnextvisible) | Returns the next visible item. |
| [GetPrevVisible](#getprevvisible) | Returns the previous visible item. |
| [GetLastVisible](#getlastvisible) | Returns the last item of the expanded tree. |
| [ItemExists](#itemexists) | Looks for a child with a given text, case-sensitively. |
| [ItemExistsIgnoreCase](#itemexistsignorecase) | Looks for a child with a given text, ignoring case. |
| [GetCount](#getcount) | Returns the number of items. |
| [GetVisibleCount](#getvisiblecount) | Returns how many items fit in the window. |
| [SelectItem](#selectitem) | Selects an item, or makes it the drop target or the top item. |
| [UnSelect](#unselect) | Clears the selection. |
| [SelectDropTarget](#selectdroptarget) | Draws an item as the target of a drag. |
| [SelectSetFirstVisible](#selectsetfirstvisible) | Scrolls an item to the top of the window. |
| [EnsureVisible](#ensurevisible) | Expands and scrolls so that an item can be seen. |
| [GetItemRect](#getitemrect) | Returns the rectangle of an item or of its text. |
| [GetItemPartRect](#getitempartrect) | Returns the rectangle of an item's expand button. |
| [HitTest](#hittest) | Finds the item at a point. |
| [EditLabel](#editlabel) | Starts editing an item's text in place. |
| [EndEditLabelNow](#endeditlabelnow) | Ends in-place editing. |
| [GetEditControl](#geteditcontrol) | Returns the edit box of an edit in progress. |
| [GetISearchStringLen](#getisearchstringlen) | Returns the length of the incremental search string. |
| [GetISearchString](#getisearchstring) | Returns or reads the incremental search string. |
| [CreateDragImage](#createdragimage) | Makes a drag image of an item. |
| [SetInsertMark](#setinsertmark) | Shows or hides the insertion mark. |
| [GetInsertMarkColor](#getinsertmarkcolor) | Returns the colour of the insertion mark. |
| [SetInsertMarkColor](#setinsertmarkcolor) | Sets the colour of the insertion mark. |
| [GetImageList](#getimagelist) | Returns the normal or state image list. |
| [SetImageList](#setimagelist) | Sets the normal or state image list. |
| [GetIndent](#getindent) | Returns the indentation of child items. |
| [SetIndent](#setindent) | Sets the indentation of child items. |
| [GetItemHeight](#getitemheight) | Returns the height of an item. |
| [SetItemHeight](#setitemheight) | Sets the height of every item. |
| [GetBkColor](#getbkcolor) | Returns the background colour. |
| [SetBkColor](#setbkcolor) | Sets the background colour. |
| [GetTextColor](#gettextcolor) | Returns the text colour. |
| [SetTextColor](#settextcolor) | Sets the text colour. |
| [GetLineColor](#getlinecolor) | Returns the colour of the lines. |
| [SetLineColor](#setlinecolor) | Sets the colour of the lines. |
| [GetExtendedStyle](#getextendedstyle) | Returns the extended styles. |
| [SetExtendedStyle](#setextendedstyle) | Sets some extended styles. |
| [GetScrollTime](#getscrolltime) | Returns the maximum scroll time. |
| [SetScrollTime](#setscrolltime) | Sets the maximum scroll time. |
| [SetAutoScrollInfo](#setautoscrollinfo) | Sets the speed of smooth scrolling. |
| [GetToolTips](#gettooltips) | Returns the tree's tooltip control. |
| [SetToolTips](#settooltips) | Sets the tree's tooltip control. |
| [ShowInfoTip](#showinfotip) | Shows an item's infotip. |
| [MapAccIDToHTREEITEM](#mapaccidtohtreeitem) | Turns an accessibility id into an item. |
| [MapHTREEITEMToAccID](#maphtreeitemtoaccid) | Turns an item into an accessibility id. |
| [SortChildren](#sortchildren) | Sorts a parent's children alphabetically. |
| [SortChildrenCB](#sortchildrencb) | Sorts a parent's children with a comparison function. |
| [SetDarkMode](#setdarkmode) | Gives the tree the dark Explorer theme. |
| [RemoveDarkMode](#removedarkmode) | Gives the tree back its normal theme. |

## Reference

### AddRootItem

```freebasic
function AddRootItem( byval hTreeView as HWND, byval pwszText as wstring ptr, byval lParam as ..LPARAM = 0, byval iImage as long = 0, byval iSelectedImage as long = 0 ) as HTREEITEM
```

Adds an item after the last root item. The same as [InsertItem](#insertitem) with
`hParent = NULL` and `hInsertAfter = TVI_ROOT`.

| Parameter | Meaning |
| --- | --- |
| `hTreeView` | The tree view. |
| `pwszText` | The item's text, or `LPSTR_TEXTCALLBACK` to have the control ask for it with `TVN_GETDISPINFOW`. |
| `lParam` | A value of your own stored with the item; read it back with [GetlParam](#getlparam). |
| `iImage` | Index of the item's image in the normal image list, when it is not selected. |
| `iSelectedImage` | Index of the image shown while it is selected. |

**Returns** the new item, or `NULL` on failure.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.AddRootItem( hCtrl, "My Computer" )
```

Microsoft Learn: [TVM_INSERTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-insertitem)

### AppendItem

```freebasic
function AppendItem( byval hTreeView as HWND, byval hParent as HTREEITEM, byval pwszText as wstring ptr, byval lParam as ..LPARAM = 0, byval iImage as long = 0, byval iSelectedImage as long = 0 ) as HTREEITEM
```

Adds an item after the last child of `hParent` (`TVI_LAST`). With `hParent = NULL` it adds a
root item. The other parameters are those of [AddRootItem](#addrootitem).

**Returns** the new item, or `NULL` on failure.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.AddRootItem( hCtrl, "Fruit" )
TreeView.AppendItem( hCtrl, hRoot, "Banana", 1 )
TreeView.AppendItem( hCtrl, hRoot, "Apple", 2 )   ' after Banana
```

### InsertFirstItem

```freebasic
function InsertFirstItem( byval hTreeView as HWND, byval hParent as HTREEITEM, byval pwszText as wstring ptr, byval lParam as ..LPARAM = 0, byval iImage as long = 0, byval iSelectedImage as long = 0 ) as HTREEITEM
```

Adds an item before the first child of `hParent` (`TVI_FIRST`). The other parameters are those
of [AddRootItem](#addrootitem).

**Returns** the new item, or `NULL` on failure.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.GetRoot( hCtrl )
TreeView.InsertFirstItem( hCtrl, hRoot, "(all)" )
```

### InsertSortedItem

```freebasic
function InsertSortedItem( byval hTreeView as HWND, byval hParent as HTREEITEM, byval pwszText as wstring ptr, byval lParam as LPARAM = 0, byval iImage as long = 0, byval iSelectedImage as long = 0 ) as HTREEITEM
```

Adds an item among the children of `hParent` at its place in alphabetical order (`TVI_SORT`).
The children already there are not re-sorted; use [SortChildren](#sortchildren) for that.

**Returns** the new item, or `NULL` on failure.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.AddRootItem( hCtrl, "Names" )
TreeView.InsertSortedItem( hCtrl, hRoot, "Zoe" )
TreeView.InsertSortedItem( hCtrl, hRoot, "Ann" )   ' goes before Zoe
```

### InsertItem

```freebasic
function InsertItem overload( byval hTreeView as HWND, byval pisw as TVINSERTSTRUCTW ptr ) as HTREEITEM
function InsertItem overload( byval hTreeView as HWND, byref isw as TVINSERTSTRUCTW ) as HTREEITEM
function InsertItem overload( byval hTreeView as HWND, byval hParent as HTREEITEM, byval hInsertAfter as HTREEITEM, byval pwszText as wstring ptr, byval lParam as ..LPARAM = 0, byval iImage as long = 0, byval iSelectedImage as long = 0 ) as HTREEITEM
```

Inserts an item. The first two forms send a `TVINSERTSTRUCTW` you fill in yourself, so every
attribute of the item is available. The third fills one in: it sets the text, both images and
`lParam`, and leaves the state and the child count to the control.

| Parameter | Meaning |
| --- | --- |
| `pisw`, `isw` | The insertion: `hParent`, `hInsertAfter` and the item in `item` (or `itemex`), with `item.mask` saying which members are set. |
| `hParent` | The parent, or `NULL` (or `TVI_ROOT`) for a root item. |
| `hInsertAfter` | The item to insert after, or `TVI_FIRST`, `TVI_LAST`, `TVI_SORT` or `TVI_ROOT`. |
| `pwszText`, `lParam`, `iImage`, `iSelectedImage` | As for [AddRootItem](#addrootitem). |

**Returns** the new item, or `NULL` on failure.

**Example**

```freebasic
dim wszText as wstring * 16 = "Drafts"
dim tvis as TVINSERTSTRUCTW
tvis.hParent = TVI_ROOT : tvis.hInsertAfter = TVI_LAST
tvis.item.mask = TVIF_TEXT or TVIF_STATE
tvis.item.pszText = @wszText
tvis.item.state = TVIS_BOLD : tvis.item.stateMask = TVIS_BOLD
dim hItem as HTREEITEM = TreeView.InsertItem( hCtrl, tvis )
TreeView.InsertItem( hCtrl, hItem, TVI_LAST, "Letter", 42 )
```

Microsoft Learn: [TVM_INSERTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-insertitem)

### Insert

```freebasic
function Insert( byval hTreeView as HWND, byval hParent as HTREEITEM, byval hInsertAfter as HTREEITEM, byval iImage as long = 0, byval iSelectedImage as long = 0, byval pwszText as wstring ptr ) as HTREEITEM
```

Inserts an item like the third form of [InsertItem](#insertitem), with the images before the
text and no `lParam` (it is always 0). The text is the last parameter and has no default, so
leave the image arguments empty to use their defaults.

**Returns** the new item, or `NULL` on failure.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.GetRoot( hCtrl )
TreeView.Insert( hCtrl, hRoot, TVI_LAST, , , "Notes" )
TreeView.Insert( hCtrl, hRoot, TVI_LAST, 2, 3, "Pictures" )
```

### DeleteItem

```freebasic
function DeleteItem( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

Deletes an item and all its descendants. The parent receives `TVN_DELETEITEMW` for each one,
which is the place to free anything an item's `lParam` points to. Passing `TVI_ROOT` deletes
every item.

**Returns** `true` on success.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
if hItem then TreeView.DeleteItem( hCtrl, hItem )
```

Microsoft Learn: [TVM_DELETEITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-deleteitem)

### DeleteAllItems, Reset

```freebasic
function DeleteAllItems( byval hTreeView as HWND ) as boolean
function Reset( byval hTreeView as HWND ) as boolean
```

Delete every item in the tree. The two names do the same thing.

**Returns** `true` on success.

**Example**

```freebasic
TreeView.DeleteAllItems( hCtrl )
print TreeView.GetCount( hCtrl )   ' 0
TreeView.Reset( hCtrl )
```

### GetItem

```freebasic
function GetItem overload( byval hTreeView as HWND, byval pitem as TVITEMW ptr ) as boolean
function GetItem overload( byval hTreeView as HWND, byref item as TVITEMW ) as boolean
```

Reads the attributes of the item named in `item.hItem` that `item.mask` asks for (`TVIF_TEXT`,
`TVIF_IMAGE`, `TVIF_PARAM`, `TVIF_STATE`, `TVIF_CHILDREN` …). For the text, point `pszText` at a
buffer and set `cchTextMax` to its size in characters; for the state, set `stateMask` too.

**Returns** `true` on success.

**Example**

```freebasic
dim tvi as TVITEMW
tvi.hItem = TreeView.GetSelection( hCtrl )
tvi.mask = TVIF_IMAGE or TVIF_CHILDREN
if TreeView.GetItem( hCtrl, tvi ) then print "image"; tvi.iImage; ", has children:"; tvi.cChildren
```

Microsoft Learn: [TVM_GETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getitem)

### GetItemEx

```freebasic
function GetItemEx overload( byval hTreeView as HWND, byval pitem as TVITEMEXW ptr ) as boolean
function GetItemEx overload( byval hTreeView as HWND, byref item as TVITEMEXW ) as boolean
```

[GetItem](#getitem) with the larger `TVITEMEXW`, which adds the item's height in rows
(`iIntegral`, mask `TVIF_INTEGRAL`), its extended state (`uStateEx`, `TVIF_STATEEX`) and its
expanded image (`iExpandedImage`, `TVIF_EXPANDEDIMAGE`).

**Returns** `true` on success.

**Example**

```freebasic
dim tvix as TVITEMEXW
tvix.hItem = TreeView.GetSelection( hCtrl )
tvix.mask = TVIF_INTEGRAL
if TreeView.GetItemEx( hCtrl, tvix ) then print "rows:"; tvix.iIntegral
```

Microsoft Learn: [TVM_GETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getitem)

### SetItem

```freebasic
function SetItem overload( byval hTreeView as HWND, byval pitem as TVITEMW ptr ) as boolean
function SetItem overload( byval hTreeView as HWND, byref item as TVITEMW ) as boolean
```

Changes the attributes of the item named in `item.hItem` that `item.mask` names; the others stay
as they are.

**Returns** `true` on success.

**Example**

```freebasic
dim tvi as TVITEMW
tvi.hItem = TreeView.GetSelection( hCtrl )
tvi.mask = TVIF_IMAGE or TVIF_SELECTEDIMAGE
tvi.iImage = 3 : tvi.iSelectedImage = 4
TreeView.SetItem( hCtrl, tvi )
```

Microsoft Learn: [TVM_SETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setitem)

### SetItemEx

```freebasic
function SetItemEx overload( byval hTreeView as HWND, byval pitem as TVITEMEXW ptr ) as boolean
function SetItemEx overload( byval hTreeView as HWND, byref item as TVITEMEXW ) as boolean
```

[SetItem](#setitem) with a `TVITEMEXW`. Setting `iIntegral` (mask `TVIF_INTEGRAL`) makes an item
several rows tall in a tree with the `TVS_NONEVENHEIGHT` style.

**Returns** `true` on success.

**Example**

```freebasic
dim tvix as TVITEMEXW
tvix.hItem = TreeView.GetSelection( hCtrl )
tvix.mask = TVIF_INTEGRAL : tvix.iIntegral = 2
TreeView.SetItemEx( hCtrl, tvix )
```

Microsoft Learn: [TVM_SETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setitem)

### GetItemText

```freebasic
function GetItemText overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval pwszText as wstring ptr, byval cchtextmax as long ) as boolean
function GetItemText overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval cchTextMax as long = 0 ) as ustring
```

The second form returns an item's text, at most `cchTextMax` characters of it; 0 or less (the
default) means 261. The first copies the text into a buffer of `cchtextmax` characters, the
terminating null included.

| Parameter | Meaning |
| --- | --- |
| `hItem` | The item. |
| `pwszText` | The buffer. `NULL` makes the call return `false` at once. |
| `cchtextmax`, `cchTextMax` | The buffer size; or, for the `ustring` form, the most characters to return. |

**Returns** the text, or `""` on failure; or, for the buffer form, `true` on success.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
print TreeView.GetItemText( hCtrl, hItem )
print TreeView.GetItemText( hCtrl, hItem, 3 )   ' the first 3 characters
```

Microsoft Learn: [TVM_GETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getitem)

### SetItemText, SetText

```freebasic
function SetItemText( byval hTreeView as HWND, byval hItem as HTREEITEM, byval pwszText as wstring ptr ) as boolean
function SetText( byval hTreeView as HWND, byval hItem as HTREEITEM, byval pwszText as wstring ptr ) as boolean
```

Change an item's text; the two names do the same thing. The text is measured before it is sent,
so `pwszText` must point to a string: not `NULL` and not `LPSTR_TEXTCALLBACK` (use
[SetItem](#setitem) for a callback item).

**Returns** `true` on success.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
TreeView.SetItemText( hCtrl, hItem, "Renamed" )
TreeView.SetText( hCtrl, hItem, "Renamed again" )
```

Microsoft Learn: [TVM_SETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setitem)

### GetlParam

```freebasic
function GetlParam( byval hTreeView as HWND, byval hItem as HTREEITEM ) as LPARAM
```

Returns the value stored with an item when it was inserted (or later with
[SetItem](#setitem) and `TVIF_PARAM`).

**Returns** the value, or 0 when the item cannot be read.

**Example**

```freebasic
dim id as LPARAM = TreeView.GetlParam( hCtrl, TreeView.GetSelection( hCtrl ) )
```

### GetItemState

```freebasic
function GetItemState( byval hTreeView as HWND, byval hItem as HTREEITEM, byval mask as UINT ) as UINT
```

Returns the state bits of an item that `mask` selects: `TVIS_SELECTED`, `TVIS_EXPANDED`,
`TVIS_BOLD`, `TVIS_CUT`, `TVIS_DROPHILITED`, `TVIS_STATEIMAGEMASK` and so on.

**Returns** the item's state, limited to `mask`.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetRoot( hCtrl )
if TreeView.GetItemState( hCtrl, hItem, TVIS_EXPANDED ) and TVIS_EXPANDED then print "expanded"
```

Microsoft Learn: [TVM_GETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getitemstate)

### SetItemState

```freebasic
sub SetItemState( byval hTreeView as HWND, byval hItem as HTREEITEM, byval state as UINT, byval statemask as UINT )
```

Sets the state bits of an item that `statemask` names to their values in `state`; the bits
outside the mask are left alone. Setting `TVIS_EXPANDED` this way changes the flag without
sending the expand notifications; use [Expand](#expand) to expand an item.

| Parameter | Meaning |
| --- | --- |
| `hItem` | The item. |
| `state` | The new values of the bits. |
| `statemask` | The bits to change. |

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
TreeView.SetItemState( hCtrl, hItem, TVIS_CUT, TVIS_CUT )   ' draw it as cut
```

Microsoft Learn: [TVM_SETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setitem)

### GetBold

```freebasic
function GetBold( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

**Returns** `true` when the item has the `TVIS_BOLD` state.

**Example**

```freebasic
print TreeView.GetBold( hCtrl, TreeView.GetRoot( hCtrl ) )
```

### SetBold

```freebasic
sub SetBold( byval hTreeView as HWND, byval hItem as HTREEITEM, byval fBold as boolean )
```

Draws an item's text in bold (`fBold = true`) or normal weight (`false`).

**Example**

```freebasic
TreeView.SetBold( hCtrl, TreeView.GetRoot( hCtrl ), true )
```

### GetCheckState

```freebasic
function GetCheckState( byval hTreeView as HWND, byval hItem as HTREEITEM ) as UINT
```

Returns the index of the item's state image. In a tree with the `TVS_CHECKBOXES` style that is
the check box: 1 unchecked, 2 checked; 0 means the item shows no state image.

**Returns** the state image index.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
if TreeView.GetCheckState( hCtrl, hItem ) = 2 then print "checked"
```

Microsoft Learn: [TVM_GETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getitemstate)

### IsItemChecked, GetCheck

```freebasic
function IsItemChecked( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
function GetCheck( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```
**Returns** `true` if the item is checked; false otherwise.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
TreeView.SetCheck( hCtrl, hItem, true )
print TreeView.IsItemChecked( hCtrl, hItem ), TreeView.GetCheck( hCtrl, hItem )   ' true, true
```

### SetCheckState, SetCheck

```freebasic
sub SetCheckState( byval hTreeView as HWND, byval hItem as HTREEITEM, byval fCheck as boolean )
sub SetCheck( byval hTreeView as HWND, byval hItem as HTREEITEM, byval fCheck as boolean )
```

Check (`fCheck = true`, state image 2) or uncheck (`false`, state image 1) an item's check box.
The two names do the same thing. The tree needs the `TVS_CHECKBOXES` style, or a state image list
of its own.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
TreeView.SetCheckState( hCtrl, hItem, true )
print TreeView.GetCheckState( hCtrl, hItem )   ' 2
TreeView.SetCheck( hCtrl, hItem, false )
```

### Expand

```freebasic
function Expand overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval code as UINT ) as boolean
function Expand overload( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

Shows (expands) or hides (collapses) the children of an item. Without `code` it expands. The
first time this expands an item the parent receives `TVN_ITEMEXPANDINGW` before and
`TVN_ITEMEXPANDEDW` after; later calls for the same item send neither, until a collapse with
`TVE_COLLAPSERESET` makes it new again.

| Parameter | Meaning |
| --- | --- |
| `hItem` | The parent item. |
| `code` | `TVE_EXPAND`, `TVE_COLLAPSE` or `TVE_TOGGLE`; add `TVE_COLLAPSERESET` to `TVE_COLLAPSE` or `TVE_EXPANDPARTIAL` to `TVE_EXPAND`. |

**Returns** `true` on success.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.GetRoot( hCtrl )
TreeView.Expand( hCtrl, hRoot )
TreeView.Expand( hCtrl, hRoot, TVE_COLLAPSE )
```

Microsoft Learn: [TVM_EXPAND](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-expand)

### ExpandPartial

```freebasic
function ExpandPartial( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

Expands an item partly (`TVE_EXPAND or TVE_EXPANDPARTIAL`): its children are shown while the
item keeps a plus button.

**Returns** `true` on success.

**Example**

```freebasic
TreeView.ExpandPartial( hCtrl, TreeView.GetRoot( hCtrl ) )
```

### Collapse

```freebasic
function Collapse( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

Hides the children of an item (`TVE_COLLAPSE`).

**Returns** `true` on success.

**Example**

```freebasic
TreeView.Collapse( hCtrl, TreeView.GetRoot( hCtrl ) )
```

### CollapseReset

```freebasic
function CollapseReset( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

Collapses an item and deletes its children (`TVE_COLLAPSE or TVE_COLLAPSERESET`). Use it with
trees filled on demand: the next expansion sends `TVN_ITEMEXPANDINGW` again so that the children
can be added afresh.

**Returns** `true` on success.

**Example**

```freebasic
dim hFolder as HTREEITEM = TreeView.GetSelection( hCtrl )
TreeView.CollapseReset( hCtrl, hFolder )
print TreeView.GetChild( hCtrl, hFolder ) = NULL   ' true: the children are gone
```

### Toggle

```freebasic
function Toggle( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

Expands a collapsed item or collapses an expanded one (`TVE_TOGGLE`).

**Returns** `true` on success.

**Example**

```freebasic
TreeView.Toggle( hCtrl, TreeView.GetSelection( hCtrl ) )
```

### ExpandChildItems

```freebasic
sub ExpandChildItems( byval hTreeView as HWND, byval hNode as HTREEITEM )
```

Expands `hNode`, then its first child, then that child's first child, and so on down. The other
children are left as they are; for a whole branch use [ExpandAllChildItems](#expandallchilditems).

**Example**

```freebasic
TreeView.ExpandChildItems( hCtrl, TreeView.GetRoot( hCtrl ) )
```

### ExpandAllChildItems

```freebasic
sub ExpandAllChildItems( byval hTreeView as HWND, byval hNode as HTREEITEM )
```

Expands `hNode` and every item below it, then does the same for each sibling that follows
`hNode`. Siblings before `hNode` and its parent are not touched. Starting from the first child
of an item expands everything under that item.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.GetRoot( hCtrl )
TreeView.Expand( hCtrl, hRoot )
TreeView.ExpandAllChildItems( hCtrl, TreeView.GetChild( hCtrl, hRoot ) )
```

### ExpandSiblings

```freebasic
sub ExpandSiblings( byval hTreeView as HWND, byval hNode as HTREEITEM )
```

Expands `hNode` and each sibling that follows it; their children are not expanded.

**Example**

```freebasic
TreeView.ExpandSiblings( hCtrl, TreeView.GetRoot( hCtrl ) )   ' every root item
```

### ExpandAllItems

```freebasic
sub ExpandAllItems( byval hTreeView as HWND )
```

Expands every item in the tree. With many items it is slow, because the control redraws after
each one: turn redrawing off around it and repaint once at the end.

**Example**

```freebasic
SendMessageW( hCtrl, WM_SETREDRAW, false, 0 )
TreeView.ExpandAllItems( hCtrl )
SendMessageW( hCtrl, WM_SETREDRAW, true, 0 )
InvalidateRect( hCtrl, NULL, true )
```

### CollapseChildItems

```freebasic
sub CollapseChildItems( byval hTreeView as HWND, byval hNode as HTREEITEM )
```

Collapses `hNode`, then its first child, then that child's first child, and so on down. The
other children keep their state; for a whole branch use
[CollapseAllChildItems](#collapseallchilditems).

**Example**

```freebasic
TreeView.CollapseChildItems( hCtrl, TreeView.GetRoot( hCtrl ) )
```

### CollapseAllChildItems

```freebasic
sub CollapseAllChildItems( byval hTreeView as HWND, byval hNode as HTREEITEM )
```

Collapses `hNode` and every item below it, then does the same for each sibling that follows
`hNode`.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.GetRoot( hCtrl )
TreeView.CollapseAllChildItems( hCtrl, TreeView.GetChild( hCtrl, hRoot ) )
```

### CollapseSiblings

```freebasic
sub CollapseSiblings( byval hTreeView as HWND, byval hNode as HTREEITEM )
```

Collapses `hNode` and each sibling that follows it; their children keep their state.

**Example**

```freebasic
TreeView.CollapseSiblings( hCtrl, TreeView.GetRoot( hCtrl ) )
```

### CollapseAllItems

```freebasic
sub CollapseAllItems( byval hTreeView as HWND )
```

Collapses every item in the tree.

**Example**

```freebasic
TreeView.CollapseAllItems( hCtrl )
```

### GetNextItem

```freebasic
function GetNextItem( byval hTreeView as HWND, byval hItem as HTREEITEM, byval code as UINT ) as HTREEITEM
```

Returns the item that stands in the relation `code` to `hItem`. The navigation functions below
are this call with a fixed code.

| `code` | Returns |
| --- | --- |
| `TVGN_ROOT` | the first root item (`hItem` is ignored) |
| `TVGN_CHILD` | the first child of `hItem` |
| `TVGN_NEXT`, `TVGN_PREVIOUS` | the next or previous sibling |
| `TVGN_PARENT` | the parent |
| `TVGN_CARET` | the selected item |
| `TVGN_DROPHILITE` | the drop target |
| `TVGN_FIRSTVISIBLE`, `TVGN_LASTVISIBLE` | the top item in the window, the last item of the expanded tree |
| `TVGN_NEXTVISIBLE`, `TVGN_PREVIOUSVISIBLE` | the next or previous item that can be seen |
| `TVGN_NEXTSELECTED` | the next selected item |

**Returns** the item, or `NULL` when there is none.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetNextItem( hCtrl, NULL, TVGN_ROOT )
while hItem
    print TreeView.GetItemText( hCtrl, hItem )
    hItem = TreeView.GetNextItem( hCtrl, hItem, TVGN_NEXT )
wend
```

Microsoft Learn: [TVM_GETNEXTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getnextitem)

### GetRoot

```freebasic
function GetRoot( byval hTreeView as HWND ) as HTREEITEM
```

Returns the first root item: the topmost item of the tree.

**Returns** the item, or `NULL` for an empty tree.

**Example**

```freebasic
dim hRoot as HTREEITEM = TreeView.GetRoot( hCtrl )
```

### GetChild

```freebasic
function GetChild( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
```

Returns the first child of `hItem`. With `hItem = NULL` it returns the first root item.

**Returns** the child, or `NULL` when the item has none.

**Example**

```freebasic
dim hChild as HTREEITEM = TreeView.GetChild( hCtrl, TreeView.GetRoot( hCtrl ) )
```

### NextSibling, GetNext

```freebasic
function NextSibling( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
function GetNext( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
```

Return the sibling after `hItem`. The two names do the same thing.

**Returns** the sibling, or `NULL` after the last one.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetChild( hCtrl, TreeView.GetRoot( hCtrl ) )
while hItem
    print TreeView.GetItemText( hCtrl, hItem )
    hItem = TreeView.NextSibling( hCtrl, hItem )   ' or TreeView.GetNext
wend
```

### PrevSibling, GetPrevious

```freebasic
function PrevSibling( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
function GetPrevious( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
```

Return the sibling before `hItem`. The two names do the same thing.

**Returns** the sibling, or `NULL` before the first one.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
dim hPrev as HTREEITEM = TreeView.PrevSibling( hCtrl, hItem )
if hPrev = NULL then hPrev = TreeView.GetPrevious( hCtrl, hItem )
```

### GetParent

```freebasic
function GetParent( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
```

Returns the parent of an item.

**Returns** the parent, or `NULL` for a root item.

**Example**

```freebasic
dim hUp as HTREEITEM = TreeView.GetParent( hCtrl, TreeView.GetSelection( hCtrl ) )
```

### GetParentText

```freebasic
function GetParentText overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval pwszText as wstring ptr, byval cchTextMax as long ) as boolean
function GetParentText overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval cchTextMax as long = 0 ) as ustring
```

[GetItemText](#getitemtext) for the parent of `hItem`, with the same parameters.

**Returns** the parent's text, or `""` for a root item; or, for the buffer form, `true` on
success and `false` for a root item or a `NULL` buffer.

**Example**

```freebasic
print "in "; TreeView.GetParentText( hCtrl, TreeView.GetSelection( hCtrl ) )
```

### GetSelection, GetSelect

```freebasic
function GetSelection( byval hTreeView as HWND ) as HTREEITEM
function GetSelect( byval hTreeView as HWND ) as HTREEITEM
```

Return the selected item. The two names do the same thing.

**Returns** the item, or `NULL` when nothing is selected.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetSelection( hCtrl )
if hItem = NULL then hItem = TreeView.GetSelect( hCtrl )
```

### GetNextSelected

```freebasic
function GetNextSelected( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
```

Returns the next selected item after `hItem` (`TVGN_NEXTSELECTED`), for a tree in which more than
one item can be selected.

**Returns** the item, or `NULL` when there are no more.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.GetNextSelected( hCtrl, NULL )
```

### GetDropHilight

```freebasic
function GetDropHilight( byval hTreeView as HWND ) as HTREEITEM
```

Returns the item drawn as the target of a drag and drop, set with
[SelectDropTarget](#selectdroptarget).

**Returns** the item, or `NULL` when there is none.

**Example**

```freebasic
dim hTarget as HTREEITEM = TreeView.GetDropHilight( hCtrl )
```

### GetFirstVisible

```freebasic
function GetFirstVisible( byval hTreeView as HWND ) as HTREEITEM
```

Returns the item shown at the top of the control's window.

**Returns** the item, or `NULL` for an empty tree.

**Example**

```freebasic
print TreeView.GetItemText( hCtrl, TreeView.GetFirstVisible( hCtrl ) )
```

### GetNextVisible

```freebasic
function GetNextVisible( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
```

Returns the visible item below `hItem`: one whose parents are all expanded, whether or not it is
scrolled into the window. `hItem` must itself be visible in that sense.

**Returns** the item, or `NULL` after the last one.

**Example**

```freebasic
dim hBelow as HTREEITEM = TreeView.GetNextVisible( hCtrl, TreeView.GetFirstVisible( hCtrl ) )
```

### GetPrevVisible

```freebasic
function GetPrevVisible( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HTREEITEM
```

Returns the visible item above `hItem`, in the sense of [GetNextVisible](#getnextvisible).

**Returns** the item, or `NULL` before the first one.

**Example**

```freebasic
dim hAbove as HTREEITEM = TreeView.GetPrevVisible( hCtrl, TreeView.GetSelection( hCtrl ) )
```

### GetLastVisible

```freebasic
function GetLastVisible( byval hTreeView as HWND ) as HTREEITEM
```

Returns the last item of the tree as far as it is expanded: the item that would be at the bottom
if the window were scrolled to the end. It need not be on screen now.

**Returns** the item, or `NULL` for an empty tree.

**Example**

```freebasic
TreeView.EnsureVisible( hCtrl, TreeView.GetLastVisible( hCtrl ) )
```

### ItemExists

```freebasic
function ItemExists( byval hTreeView as HWND, byval hNode as HTREEITEM, byval pwszText as wstring ptr ) as boolean
```
**Returns** `true` if the item exists; false otherwise.

**Example**

```freebasic
dim found as boolean = TreeView.ItemExists( hCtrl, NULL, "Fruit" )
```

### ItemExistsIgnoreCase

```freebasic
function ItemExistsIgnoreCase( byval hTreeView as HWND, byval hNode as HTREEITEM, byval pwszText as wstring ptr ) as boolean
```

[ItemExists](#itemexists) with both texts upper-cased before the comparison.

**Returns** `true` if the item exists; false otherwise.

**Example**

```freebasic
dim found as boolean = TreeView.ItemExists( hCtrl, NULL, "fruit" )
```

### GetCount

```freebasic
function GetCount( byval hTreeView as HWND ) as UINT
```

Returns the number of items in the tree, at every level.

**Returns** the count.

**Example**

```freebasic
print TreeView.GetCount( hCtrl ); " items"
```

Microsoft Learn: [TVM_GETCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getcount)

### GetVisibleCount

```freebasic
function GetVisibleCount( byval hTreeView as HWND ) as UINT
```

Returns how many whole items fit in the control's client area: its height divided by the item
height, rounded down. It does not depend on how many items there are.

**Returns** the count.

**Example**

```freebasic
print TreeView.GetVisibleCount( hCtrl ); " rows fit"
```

Microsoft Learn: [TVM_GETVISIBLECOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getvisiblecount)

### SelectItem

```freebasic
function SelectItem overload( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
function SelectItem overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval code as UINT ) as boolean
```

Without `code`, selects `hItem` (`TVGN_CARET`), expanding a collapsed parent to reveal it; the parent receives `TVN_SELCHANGINGW` and `TVN_SELCHANGEDW`. `code` can also be
`TVGN_DROPHILITE` ([SelectDropTarget](#selectdroptarget)) or `TVGN_FIRSTVISIBLE`
([SelectSetFirstVisible](#selectsetfirstvisible)). `hItem = NULL` clears that kind of selection.

**Returns** `true` on success.

**Example**

```freebasic
TreeView.SelectItem( hCtrl, TreeView.GetRoot( hCtrl ) )
SetFocus( hCtrl )
```

Microsoft Learn: [TVM_SELECTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-selectitem)

### UnSelect

```freebasic
function UnSelect( byval hTreeView as HWND ) as boolean
```

Clears the selection, so that [GetSelection](#getselection-getselect) returns `NULL`.

**Returns** `true` on success.

**Example**

```freebasic
TreeView.UnSelect( hCtrl )
```

### SelectDropTarget

```freebasic
function SelectDropTarget( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

Draws `hItem` as the target of a drag and drop (`TVGN_DROPHILITE`); `NULL` removes the
highlight. Call it while handling `WM_MOUSEMOVE` during a drag.

**Returns** `true` on success.

**Example**

```freebasic
dim ht as TVHITTESTINFO
ht.pt.x = 20 : ht.pt.y = 40
TreeView.SelectDropTarget( hCtrl, TreeView.HitTest( hCtrl, ht ) )
```

Microsoft Learn: [TVM_SELECTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-selectitem)

### SelectSetFirstVisible

```freebasic
function SelectSetFirstVisible( byval hTreeView as HWND, byval hitem as HTREEITEM ) as boolean
```

Scrolls the tree vertically so that `hitem` is the top item in the window (`TVGN_FIRSTVISIBLE`),
as far as the scroll range allows. The selection does not change.

**Returns** `true` on success.

**Example**

```freebasic
TreeView.SelectSetFirstVisible( hCtrl, TreeView.GetSelection( hCtrl ) )
```

### EnsureVisible

```freebasic
function EnsureVisible( byval hTreeView as HWND, byval hItem as HTREEITEM ) as boolean
```

Makes an item visible: expands its collapsed parents and scrolls the window as far as needed.

**Returns** `true` when the control scrolled without having to expand anything, `false`
otherwise.

**Example**

```freebasic
TreeView.EnsureVisible( hCtrl, TreeView.GetLastVisible( hCtrl ) )
```

Microsoft Learn: [TVM_ENSUREVISIBLE](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-ensurevisible)

### GetItemRect

```freebasic
function GetItemRect overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byref rc as RECT, byval code as boolean ) as boolean
function GetItemRect overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval prc as RECT ptr, byval code as boolean ) as boolean
function GetItemRect overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval code as boolean ) as ( long, long, long, long )
```

Gets the rectangle of an item in client coordinates. With `code = true` it covers the item's
text only; with `false` it covers the whole row, the full width of the control. An item whose
parent is collapsed has no rectangle.

| Parameter | Meaning |
| --- | --- |
| `hItem` | The item. |
| `rc`, `prc` | Receives the rectangle. A `NULL` `prc` makes the call return `false`. |
| `code` | `true` for the text, `false` for the row. |

**Returns** `true` when the item is visible and the rectangle was filled; the tuple form returns
`( left, top, right, bottom )`, all zero when the item has no rectangle.

**Example**

```freebasic
var (l, t, r, b) = TreeView.GetItemRect( hCtrl, TreeView.GetSelection( hCtrl ), true )
dim rc as RECT
if TreeView.GetItemRect( hCtrl, TreeView.GetSelection( hCtrl ), rc, false ) then print "row height"; rc.bottom - rc.top
```

Microsoft Learn: [TVM_GETITEMRECT](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getitemrect)

### GetItemPartRect

```freebasic
function GetItemPartRect overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byref rc as RECT, byval partid as TVITEMPART = TVGIPR_BUTTON ) as boolean
function GetItemPartRect overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval prc as RECT ptr, byval partid as TVITEMPART = TVGIPR_BUTTON ) as boolean
function GetItemPartRect overload( byval hTreeView as HWND, byval hItem as HTREEITEM, byval partid as TVITEMPART = TVGIPR_BUTTON ) as RECT
```

Gets the largest rectangle that counts as a hit on one part of an item, in client coordinates.
The only part there is is `TVGIPR_BUTTON`, the expand button. Needs version 6 of the common
controls.

**Returns** `true` on success; the third form returns the rectangle, all zero on failure.

**Example**

```freebasic
dim rc as RECT = TreeView.GetItemPartRect( hCtrl, TreeView.GetRoot( hCtrl ) )
print "button at"; rc.left; ","; rc.top
```

Microsoft Learn: [TVM_GETITEMPARTRECT](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getitempartrect)

### HitTest

```freebasic
function HitTest overload( byval hTreeView as HWND, byval pht as TVHITTESTINFO ptr ) as HTREEITEM
function HitTest overload( byval hTreeView as HWND, byref ht as TVHITTESTINFO ) as HTREEITEM
```

Finds what is at the point `pt` of a `TVHITTESTINFO`, given in client coordinates. On return
`flags` says which part of the control is there (`TVHT_ONITEMLABEL`, `TVHT_ONITEMBUTTON`,
`TVHT_ONITEMICON`, `TVHT_ONITEMSTATEICON`, `TVHT_NOWHERE` …) and `hItem` holds the item, if any.

**Returns** the item at the point, or `NULL`.

**Example**

```freebasic
dim ht as TVHITTESTINFO
GetCursorPos( @ht.pt ) : ScreenToClient( hCtrl, @ht.pt )
dim hItem as HTREEITEM = TreeView.HitTest( hCtrl, ht )
if ht.flags and TVHT_ONITEMSTATEICON then print "click on the check box"
```

Microsoft Learn: [TVM_HITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-hittest)

### EditLabel

```freebasic
function EditLabel( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HWND
```

Replaces an item's text with a single-line edit box holding that text, as when the user edits a
label in a tree with the `TVS_EDITLABELS` style. Give the tree the focus first. The parent
receives `TVN_BEGINLABELEDITW`, and can cancel by returning `true`, and `TVN_ENDLABELEDITW` when
the edit ends.

**Returns** the edit box, or `NULL` when editing did not start.

**Example**

```freebasic
SetFocus( hCtrl )
dim hEdit as HWND = TreeView.EditLabel( hCtrl, TreeView.GetSelection( hCtrl ) )
```

Microsoft Learn: [TVM_EDITLABEL](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-editlabel)

### EndEditLabelNow

```freebasic
function EndEditLabelNow( byval hTreeView as HWND, byval fCancel as boolean ) as boolean
```

Ends an edit started by the user or by [EditLabel](#editlabel). With `fCancel = true` the typed
text is thrown away; with `false` it is offered to the parent in `TVN_ENDLABELEDITW`.

**Returns** `true` on success.

**Example**

```freebasic
TreeView.EndEditLabelNow( hCtrl, false )   ' keep what was typed
```

Microsoft Learn: [TVM_ENDEDITLABELNOW](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-endeditlabelnow)

### GetEditControl

```freebasic
function GetEditControl( byval hTreeView as HWND ) as HWND
```

Returns the edit box of the label edit in progress, for example to limit its length while
handling `TVN_BEGINLABELEDITW`.

**Returns** the edit box, or `NULL` when no label is being edited.

**Example**

```freebasic
dim hEdit as HWND = TreeView.GetEditControl( hCtrl )
if hEdit then SendMessageW( hEdit, EM_LIMITTEXT, 40, 0 )
```

Microsoft Learn: [TVM_GETEDITCONTROL](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-geteditcontrol)

### GetISearchStringLen

```freebasic
function GetISearchStringLen( byval hTreeView as HWND ) as long
```

Returns the length of the incremental search string: the characters the user has typed to jump
to an item by its first letters.

**Returns** the length, or 0 when no incremental search is in progress.

**Example**

```freebasic
if TreeView.GetISearchStringLen( hCtrl ) then print "searching"
```

Microsoft Learn: [TVM_GETISEARCHSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getisearchstring)

### GetISearchString

```freebasic
function GetISearchString overload( byval hTreeView as HWND, byval pwsz as wstring ptr ) as boolean
function GetISearchString overload( byval hTreeView as HWND ) as ustring
```

The second form returns the incremental search string. The first copies it into a buffer, which
must be large enough.

**Returns** the string, or `""` when no search is in progress; or, for the buffer form, the
control's reply, nonzero when there is a search string.

**Example**

```freebasic
dim s as ustring = TreeView.GetISearchString( hCtrl )
if len( s ) then print "typed so far: "; s
```

Microsoft Learn: [TVM_GETISEARCHSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getisearchstring)

### CreateDragImage

```freebasic
function CreateDragImage( byval hTreeView as HWND, byval hItem as HTREEITEM ) as HIMAGELIST
```

Makes an image of an item, its icon and text, to show under the cursor while it is dragged, and
puts it in a new image list. The image list is yours: destroy it with `ImageList_Destroy` when
the drag ends.

**Returns** the image list, or `NULL` on failure.

**Example**

```freebasic
dim himlDrag as HIMAGELIST = TreeView.CreateDragImage( hCtrl, TreeView.GetSelection( hCtrl ) )
if himlDrag then ImageList_BeginDrag( himlDrag, 0, 0, 0 )
ImageList_EndDrag() : ImageList_Destroy( himlDrag )
```

Microsoft Learn: [TVM_CREATEDRAGIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-createdragimage)

### SetInsertMark

```freebasic
function SetInsertMark( byval hTreeView as HWND, byval hItem as HTREEITEM, byval fAfter as boolean ) as boolean
```

Draws the insertion mark, a line showing where a dragged item would land, after (`fAfter = true`)
or before (`false`) `hItem`. `hItem = NULL` removes it.

**Returns** `true` on success.

**Example**

```freebasic
TreeView.SetInsertMark( hCtrl, TreeView.GetSelection( hCtrl ), true )
TreeView.SetInsertMark( hCtrl, NULL, false )   ' remove it
```

Microsoft Learn: [TVM_SETINSERTMARK](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setinsertmark)

### GetInsertMarkColor

```freebasic
function GetInsertMarkColor( byval hTreeView as HWND ) as COLORREF
```

**Returns** the colour of the insertion mark; `CLR_DEFAULT` (`&hFF000000`) until one is set.

**Example**

```freebasic
print hex( TreeView.GetInsertMarkColor( hCtrl ) )
```

Microsoft Learn: [TVM_GETINSERTMARKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getinsertmarkcolor)

### SetInsertMarkColor

```freebasic
function SetInsertMarkColor( byval hTreeView as HWND, byval clr as COLORREF ) as COLORREF
```

Sets the colour of the insertion mark.

**Returns** the previous colour.

**Example**

```freebasic
TreeView.SetInsertMarkColor( hCtrl, BGR( 255, 0, 0 ) )
```

Microsoft Learn: [TVM_SETINSERTMARKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setinsertmarkcolor)

### GetImageList

```freebasic
function GetImageList( byval hTreeView as HWND, byval iImage as long ) as HIMAGELIST
```

Returns the image list of kind `iImage`: `TVSIL_NORMAL` for the item images or `TVSIL_STATE` for
the state images (the check boxes of a `TVS_CHECKBOXES` tree).

**Returns** the image list, or `NULL` when there is none.

**Example**

```freebasic
dim himl as HIMAGELIST = TreeView.GetImageList( hCtrl, TVSIL_NORMAL )
```

Microsoft Learn: [TVM_GETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getimagelist)

### SetImageList

```freebasic
function SetImageList( byval hTreeView as HWND, byval himl as HIMAGELIST, byval iImage as long = TVSIL_NORMAL ) as HIMAGELIST
```

Gives the tree an image list of kind `iImage` (`TVSIL_NORMAL`, the default, or `TVSIL_STATE`)
and redraws it; `NULL` removes the list. The control does not take ownership: the image list
outlives the control, and the program destroys it with `ImageList_Destroy` once the control is
gone.

**Returns** the previous image list of that kind, or `NULL`.

**Example**

```freebasic
dim himl as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32 or ILC_MASK, 4, 4 )
TreeView.SetImageList( hCtrl, himl )
' ... after the tree is destroyed:
ImageList_Destroy( himl )
```

Microsoft Learn: [TVM_SETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setimagelist)

### GetIndent

```freebasic
function GetIndent( byval hTreeView as HWND ) as UINT
```

**Returns** how far, in pixels, child items are indented from their parent.

**Example**

```freebasic
print TreeView.GetIndent( hCtrl )
```

Microsoft Learn: [TVM_GETINDENT](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getindent)

### SetIndent

```freebasic
function SetIndent( byval hTreeView as HWND, byval indent as long ) as boolean
```

Sets how far child items are indented, in pixels, and redraws the control. A value below the
control's minimum is raised to it. The control's reply carries no meaning (it is `false` even
when the indent changes); read the result back with [GetIndent](#getindent).

**Example**

```freebasic
TreeView.SetIndent( hCtrl, 30 )
print TreeView.GetIndent( hCtrl )   ' 30
```

Microsoft Learn: [TVM_SETINDENT](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setindent)

### GetItemHeight

```freebasic
function GetItemHeight( byval hTreeView as HWND ) as long
```

**Returns** the height of one item row, in pixels.

**Example**

```freebasic
print TreeView.GetItemHeight( hCtrl )
```

Microsoft Learn: [TVM_GETITEMHEIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getitemheight)

### SetItemHeight

```freebasic
function SetItemHeight( byval hTreeView as HWND, byval cyItem as short ) as long
```

Sets the height of every item row, in pixels; -1 goes back to the default height. An odd height
is rounded down unless the tree has the `TVS_NONEVENHEIGHT` style.

**Returns** the previous height.

**Example**

```freebasic
TreeView.SetItemHeight( hCtrl, 24 )
```

Microsoft Learn: [TVM_SETITEMHEIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setitemheight)

### GetBkColor

```freebasic
function GetBkColor( byval hTreeView as HWND ) as COLORREF
```

**Returns** the background colour, or -1 (`&hFFFFFFFF`) while the control uses the system
window colour.

**Example**

```freebasic
print hex( TreeView.GetBkColor( hCtrl ) )
```

Microsoft Learn: [TVM_GETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getbkcolor)

### SetBkColor

```freebasic
function SetBkColor( byval hTreeView as HWND, byval clr as COLORREF ) as COLORREF
```

Sets the background colour; -1 goes back to the system colour.

**Returns** the previous colour, -1 if it was the system colour.

**Example**

```freebasic
TreeView.SetBkColor( hCtrl, BGR( 240, 240, 240 ) )
```

Microsoft Learn: [TVM_SETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setbkcolor)

### GetTextColor

```freebasic
function GetTextColor( byval hTreeView as HWND ) as COLORREF
```

**Returns** the text colour, or -1 while the control uses the system colour.

**Example**

```freebasic
print hex( TreeView.GetTextColor( hCtrl ) )
```

Microsoft Learn: [TVM_GETTEXTCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-gettextcolor)

### SetTextColor

```freebasic
function SetTextColor( byval hTreeView as HWND, byval clrText as COLORREF ) as COLORREF
```

Sets the text colour; -1 goes back to the system colour.

**Returns** the previous colour.

**Example**

```freebasic
TreeView.SetTextColor( hCtrl, BGR( 0, 0, 128 ) )
```

Microsoft Learn: [TVM_SETTEXTCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-settextcolor)

### GetLineColor

```freebasic
function GetLineColor( byval hTreeView as HWND ) as COLORREF
```

**Returns** the colour of the lines joining items, `CLR_DEFAULT` (`&hFF000000`) while it is the
system colour.

**Example**

```freebasic
print hex( TreeView.GetLineColor( hCtrl ) )
```

Microsoft Learn: [TVM_GETLINECOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getlinecolor)

### SetLineColor

```freebasic
function SetLineColor( byval hTreeView as HWND, byval clrLine as COLORREF ) as COLORREF
```

Sets the colour of the lines joining items (`TVS_HASLINES`); `CLR_DEFAULT` goes back to the
system colour.

**Returns** the previous colour.

**Example**

```freebasic
TreeView.SetLineColor( hCtrl, BGR( 160, 160, 160 ) )
```

Microsoft Learn: [TVM_SETLINECOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setlinecolor)

### GetExtendedStyle

```freebasic
function GetExtendedStyle( byval hTreeView as HWND ) as DWORD
```

Returns the extended styles (`TVS_EX_*`), which are separate from the window's `WS_EX_*` styles.
Needs version 6 of the common controls.

**Returns** the extended styles.

**Example**

```freebasic
if TreeView.GetExtendedStyle( hCtrl ) and TVS_EX_DOUBLEBUFFER then print "double-buffered"
```

Microsoft Learn: [TVM_GETEXTENDEDSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getextendedstyle)

### SetExtendedStyle

```freebasic
function SetExtendedStyle( byval hTreeView as HWND, byval dwExStyle as DWORD, byval mask as UINT ) as HRESULT
```

Sets the extended styles that `mask` names to their values in `dwExStyle`: for example
`TVS_EX_DOUBLEBUFFER` against flicker, `TVS_EX_FADEINOUTEXPANDOS` or `TVS_EX_AUTOHSCROLL`. Needs
version 6 of the common controls.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
TreeView.SetExtendedStyle( hCtrl, TVS_EX_DOUBLEBUFFER, TVS_EX_DOUBLEBUFFER )
```

Microsoft Learn: [TVM_SETEXTENDEDSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setextendedstyle)

### GetScrollTime

```freebasic
function GetScrollTime( byval hTreeView as HWND ) as UINT
```

Returns the longest time, in milliseconds, that one scroll operation may take. Until one is set
with [SetScrollTime](#setscrolltime) the control returned `&hFFFFFFFF` in testing.

**Returns** the time.

**Example**

```freebasic
print TreeView.GetScrollTime( hCtrl )
```

Microsoft Learn: [TVM_GETSCROLLTIME](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-getscrolltime)

### SetScrollTime

```freebasic
function SetScrollTime( byval hTreeView as HWND, byval uMaxScrollTime as UINT ) as UINT
```

Sets the longest time, in milliseconds, that one scroll operation may take.

**Returns** the previous time.

**Example**

```freebasic
TreeView.SetScrollTime( hCtrl, 100 )
```

Microsoft Learn: [TVM_SETSCROLLTIME](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setscrolltime)

### SetAutoScrollInfo

```freebasic
function SetAutoScrollInfo( byval hTreeView as HWND, byval uPixPerSec as UINT, byval uUpdateTime as UINT ) as LRESULT
```

Sets how fast the control scrolls by itself, for example when an item is selected near the edge
in a tree with `TVS_EX_AUTOHSCROLL`: `uPixPerSec` pixels a second, redrawn every `uUpdateTime`
milliseconds.

**Returns** nonzero.

**Example**

```freebasic
TreeView.SetAutoScrollInfo( hCtrl, 200, 20 )
```

Microsoft Learn: [TVM_SETAUTOSCROLLINFO](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-setautoscrollinfo)

### GetToolTips

```freebasic
function GetToolTips( byval hTreeView as HWND ) as HWND
```

Returns the tooltip control the tree uses to show item text that does not fit. The tree creates
one itself unless it has the `TVS_NOTOOLTIPS` style.

**Returns** the tooltip control, or `NULL`.

**Example**

```freebasic
dim hTip as HWND = TreeView.GetToolTips( hCtrl )
if hTip then SendMessageW( hTip, TTM_SETDELAYTIME, TTDT_INITIAL, 200 )
```

Microsoft Learn: [TVM_GETTOOLTIPS](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-gettooltips)

### SetToolTips

```freebasic
function SetToolTips( byval hTreeView as HWND, byval hwndTT as HWND ) as HWND
```

Makes `hwndTT` the tree's tooltip control.

**Returns** the previous tooltip control, or `NULL`.

**Example**

```freebasic
dim hOld as HWND = TreeView.SetToolTips( hCtrl, CreateWindowExW( 0, TOOLTIPS_CLASSW, NULL, 0, 0, 0, 0, 0, hwnd, NULL, NULL, NULL ) )
```

Microsoft Learn: [TVM_SETTOOLTIPS](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-settooltips)

### ShowInfoTip

```freebasic
function ShowInfoTip( byval hTreeView as HWND, byval hitem as HTREEITEM ) as DWORD
```

Shows the infotip of an item at once, as if the cursor rested on it. The text comes from the
parent's handling of `TVN_GETINFOTIPW`, sent to trees with the `TVS_INFOTIP` style.

**Returns** 0; the reply carries no meaning.

**Example**

```freebasic
TreeView.ShowInfoTip( hCtrl, TreeView.GetSelection( hCtrl ) )
```

Microsoft Learn: [TVM_SHOWINFOTIP](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-showinfotip)

### MapAccIDToHTREEITEM

```freebasic
function MapAccIDToHTREEITEM( byval hTreeView as HWND, byval id as UINT ) as HTREEITEM
```

Returns the item that an accessibility (Active Accessibility / UI Automation) child id stands
for. Needs version 6 of the common controls.

**Returns** the item, or `NULL`.

**Example**

```freebasic
dim hItem as HTREEITEM = TreeView.MapAccIDToHTREEITEM( hCtrl, 3 )
```

Microsoft Learn: [TVM_MAPACCIDTOHTREEITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-mapaccidtohtreeitem)

### MapHTREEITEMToAccID

```freebasic
function MapHTREEITEMToAccID( byval hTreeView as HWND, byval hItem as HTREEITEM ) as UINT
```

Returns the accessibility child id of an item, the reverse of
[MapAccIDToHTREEITEM](#mapaccidtohtreeitem). Needs version 6 of the common controls.

**Returns** the id, or 0.

**Example**

```freebasic
dim id as UINT = TreeView.MapHTREEITEMToAccID( hCtrl, TreeView.GetSelection( hCtrl ) )
```

Microsoft Learn: [TVM_MAPHTREEITEMTOACCID](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-maphtreeitemtoaccid)

### SortChildren

```freebasic
function SortChildren( byval hTreeView as HWND, byval hitem as HTREEITEM, byval fRecurse as boolean ) as boolean
```

Sorts the children of `hitem` into alphabetical order of their text, ignoring case. Microsoft
documents `fRecurse = true` as sorting every level below the parent; in testing only the direct
children were sorted either way, so sort each level that needs it.

**Returns** `true` on success.

**Example**

```freebasic
TreeView.SortChildren( hCtrl, TreeView.GetRoot( hCtrl ), false )
TreeView.SortChildren( hCtrl, TVI_ROOT, false )   ' the root items
```

Microsoft Learn: [TVM_SORTCHILDREN](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-sortchildren)

### SortChildrenCB

```freebasic
function SortChildrenCB( byval hTreeView as HWND, byval psort as TVSORTCB ptr, byval fRecurse as boolean ) as boolean
```

Sorts the children of `psort->hParent` with your comparison function, `psort->lpfnCompare`. The
function receives the `lParam` of two items and `psort->lParam`, and returns a negative number
when the first should come first, a positive one when the second should, and 0 when they are
equal. Pass `false` for `fRecurse`.

**Returns** `true` on success.

**Example**

```freebasic
function CompareByParam( byval lParam1 as LPARAM, byval lParam2 as LPARAM, byval lParamSort as LPARAM ) as long
    return lParam1 - lParam2
end function

sub SortByParam( byval hTree as HWND, byval hParent as HTREEITEM )
    dim sortcb as TVSORTCB
    sortcb.hParent = hParent
    sortcb.lpfnCompare = @CompareByParam
    TreeView.SortChildrenCB( hTree, @sortcb, false )
end sub
```

Microsoft Learn: [TVM_SORTCHILDRENCB](https://learn.microsoft.com/en-us/windows/win32/controls/tvm-sortchildrencb)

### SetDarkMode

```freebasic
function SetDarkMode( byval hTreeView as HWND ) as HRESULT
```

Gives the tree the theme that Explorer uses in dark mode (`DarkMode_Explorer`): dark scroll bars,
expand buttons and selection. The background and text colours are not part of the theme; set
them with [SetBkColor](#setbkcolor) and [SetTextColor](#settextcolor).

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
TreeView.SetDarkMode( hCtrl )
TreeView.SetBkColor( hCtrl, BGR( 32, 32, 32 ) )
TreeView.SetTextColor( hCtrl, BGR( 240, 240, 240 ) )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

### RemoveDarkMode

```freebasic
function RemoveDarkMode( byval hTreeView as HWND ) as HRESULT
```

Gives the tree back its normal visual style. Colours set with [SetBkColor](#setbkcolor) and
[SetTextColor](#settextcolor) stay until set back to -1.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
TreeView.RemoveDarkMode( hCtrl )
TreeView.SetBkColor( hCtrl, -1 ) : TreeView.SetTextColor( hCtrl, -1 )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for `AddControl( "TreeView", ... )`
- [gui macros and helpers](SysWin-Gui-Procedures) for reading `WM_NOTIFY` in the window procedure
- [ListView](SysWin-Gui-ListView), [Header](SysWin-Gui-Header)
- [Dark mode](SysWin-Dark-Mode)
