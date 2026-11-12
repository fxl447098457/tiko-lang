[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **ListBox**

# ListBox

Adds, finds, selects and reads the items of a list box control.

A list box shows a column of items, usually strings, from which the user picks one or several.
Create one with `CWindow.AddControl( "ListBox", ... )`: it is sorted (`LBS_SORT`), keeps its
strings (`LBS_HASSTRINGS`), has a border and both scroll bars, and sends notifications
(`LBS_NOTIFY`). Every function here takes the control's handle first and is written with the
namespace: `ListBox.AddString( hList, "Apple" )`.

Items are numbered from 0. Most functions send one list-box message and return what it
returns: an index or a count on success, `LB_ERR` (-1) on failure and `LB_ERRSPACE` (-2) when
the list box ran out of memory. Each item also holds one `LONG_PTR` of **item data** for the
program's own use; the list box never frees what it points to. An owner-drawn list box without
`LBS_HASSTRINGS` stores no text at all, and the `*ItemData` functions add and find its items by
that value.

There are three kinds of selection, set by the style when the control is created:

| Style | The user selects | Read the selection with |
| --- | --- | --- |
| none | one item | [GetCurSel](#getcursel) |
| `LBS_MULTIPLESEL` | any number, each click toggles one | [GetSel](#getsel), [GetSelItems](#getselitems) |
| `LBS_EXTENDEDSEL` | ranges, with `Shift` and `Ctrl` | [GetSel](#getsel), [GetSelItems](#getselitems), [GetSelect](#getselect) |

Several helpers look at the style and send a different message for each kind; their entries
say which. The parent learns of changes through `WM_COMMAND`: `LBN_SELCHANGE` when the user
changes the selection, `LBN_DBLCLK` on a double click. The functions here never notify.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A sorted list of fruit, each with its price as item data. Selecting one shows its price below
the list; the button removes the selected item.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_LIST = 101
const IDC_INFO = 102
const IDC_REMOVE = 103

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "ListBoxDemo"
    dim hWin as HWND = pWindow.Create( NULL, "ListBox", @WndProc )
    pWindow.SetClientSize( 300, 240 )
    pWindow.Center()
    dim hList as HWND = pWindow.AddControl( "ListBox", hWin, IDC_LIST, "", 10, 10, 280, 180 )
    dim ustrFruit(0 to 4) as ustring = { "Pear", "Apple", "Cherry", "Banana", "Plum" }
    dim nCents(0 to 4) as long = { 120, 95, 450, 60, 210 }
    for i as long = 0 to 4
        dim idx as long = ListBox.AddString( hList, ustrFruit(i) )
        ListBox.SetItemData( hList, idx, nCents(i) )
    next
    pWindow.AddControl( "Label", hWin, IDC_INFO, "Pick a fruit", 10, 204, 180, 22 )
    pWindow.AddControl( "Button", hWin, IDC_REMOVE, "&Remove", 200, 200, 90, 28 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            dim hList as HWND = GetDlgItem( hwnd, IDC_LIST )
            select case CBCTL( wParam, lParam )
                case IDC_LIST
                    if CBCTLMSG( wParam, lParam ) = LBN_SELCHANGE then
                        dim i as long = ListBox.GetCurSel( hList )
                        if i >= 0 then
                            Label.SetText( GetDlgItem( hwnd, IDC_INFO ), _
                                           ListBox.GetText( hList, i ) & ": " & ListBox.GetItemData( hList, i ) & " cents" )
                        end if
                    end if
                case IDC_REMOVE
                    if CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                        dim i as long = ListBox.GetCurSel( hList )
                        if i >= 0 then
                            dim nLeft as long = ListBox.DeleteString( hList, i )
                            if i >= nLeft then i = nLeft - 1
                            ListBox.SetCurSel( hList, i )
                        end if
                    end if
            end select
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
| [AddString](#addstring) | Adds a string, in sorted order when the list is sorted. |
| [InsertString](#insertstring) | Inserts a string at an index. |
| [DeleteString](#deletestring) | Deletes an item. |
| [ResetContent](#resetcontent) | Deletes every item. |
| [ReplaceString](#replacestring) | Replaces an item's text and item data, then selects it. |
| [SetText](#settext) | Replaces an item's text, then selects it. |
| [AddFile](#addfile) | Adds a file name to a list filled by [Dir](#dir). |
| [Dir](#dir) | Adds the files, folders or drives that match a pattern. |
| [InitStorage](#initstorage) | Reserves memory before adding many items. |
| [SetCount](#setcount) | Sets the number of items of a list box without data. |
| [GetCount](#getcount) | Returns the number of items. |
| [GetText](#gettext) | Returns an item's text. |
| [GetTextLen](#gettextlen) | Returns the length of an item's text. |
| [FindString](#findstring) | Finds the first item that begins with a string. |
| [FindStringExact](#findstringexact) | Finds the first item equal to a string. |
| [GetItemData](#getitemdata) | Returns an item's item data. |
| [SetItemData](#setitemdata) | Sets an item's item data. |
| [AddItemData](#additemdata) | Adds an item to an owner-drawn list box without strings. |
| [InsertItemData](#insertitemdata) | Inserts an item into an owner-drawn list box without strings. |
| [FindItemData](#finditemdata) | Finds the item with a given item data. |
| [SelectItemData](#selectitemdata) | Finds and selects the item with a given item data. |
| [GetCurSel](#getcursel) | Returns the selected item. |
| [SetCurSel](#setcursel) | Selects an item in a single-selection list box. |
| [GetSelect](#getselect) | Returns the first selected item from a starting index. |
| [GetSel](#getsel) | Returns whether an item is selected. |
| [SetSel](#setsel) | Selects or deselects an item. |
| [SelectString](#selectstring) | Selects the first item that begins with a string, or an item by index. |
| [UnselectString](#unselectstring) | Deselects an item. |
| [GetSelCount](#getselcount) | Returns the number of selected items. |
| [GetSelItems](#getselitems) | Reads the indexes of the selected items. |
| [SelItemRange](#selitemrange) | Selects or deselects a range of items. |
| [SelItemRangeEx](#selitemrangeex) | Selects or deselects a range of items. |
| [GetAnchorIndex](#getanchorindex) | Returns the item a range selection starts from. |
| [SetAnchorIndex](#setanchorindex) | Sets the item a range selection starts from. |
| [GetCaretIndex](#getcaretindex) | Returns the item with the focus rectangle. |
| [SetCaretIndex](#setcaretindex) | Moves the focus rectangle to an item. |
| [GetTopIndex](#gettopindex) | Returns the first visible item. |
| [SetTopIndex](#settopindex) | Scrolls an item to the top. |
| [GetItemHeight](#getitemheight) | Returns the height of the items. |
| [SetItemHeight](#setitemheight) | Sets the height of the items. |
| [GetItemRect](#getitemrect) | Returns the rectangle of an item. |
| [ItemFromPoint](#itemfrompoint) | Returns the item nearest a point. |
| [GetListBoxInfo](#getlistboxinfo) | Returns the number of items in each column. |
| [SetColumnWidth](#setcolumnwidth) | Sets the column width of a multicolumn list box. |
| [SetTabStops](#settabstops) | Sets the tab stops used to draw item text. |
| [GetHorizontalExtent](#gethorizontalextent) | Returns the scrollable width. |
| [SetHorizontalExtent](#sethorizontalextent) | Sets the scrollable width. |
| [CalcHorizontalExtent](#calchorizontalextent) | Measures the widest item. |
| [GetLocale](#getlocale) | Returns the locale used for sorting. |
| [SetLocale](#setlocale) | Sets the locale used for sorting. |
| [Enable](#enable) | Lets the user use the list box. |
| [Disable](#disable) | Greys the list box out. |
| [SetDarkMode](#setdarkmode) | Draws the scroll bars with the dark theme. |
| [RemoveDarkMode](#removedarkmode) | Draws the scroll bars with the default theme again. |

## Reference

### AddString

```freebasic
function AddString( byval hListBox as HWND, byval pwszText as wstring ptr ) as long
```

Adds a string. A list box with `LBS_SORT` inserts it in sorted order (case does not count);
any other adds it at the end.

**Returns** the index the string went to, or `LB_ERR` / `LB_ERRSPACE`. In a sorted list box
adding `"Pear"`, `"Apple"`, `"Banana"` and `"apricot"` returns 0, 0, 1 and 1.

**Example**

```freebasic
dim idx as long = ListBox.AddString( hCtrl, "Apple" )
ListBox.SetCurSel( hCtrl, idx )
```

Microsoft Learn: [LB_ADDSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-addstring)

### InsertString

```freebasic
function InsertString( byval hListBox as HWND, byval index as long, byval pwszText as wstring ptr ) as long
```

Inserts a string before item `index`, or at the end when `index` is -1. A sorted list box is
not re-sorted: the string stays where it was put.

**Returns** the index of the new item, or `LB_ERR` / `LB_ERRSPACE`.

**Example**

```freebasic
ListBox.InsertString( hCtrl, 0, "(none)" )
```

Microsoft Learn: [LB_INSERTSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-insertstring)

### DeleteString

```freebasic
function DeleteString( byval hListBox as HWND, byval index as long ) as long
```

Deletes item `index`. The item data goes with it; free whatever it pointed to first.

**Returns** the number of items left, or `LB_ERR` when `index` is not an item.

**Example**

```freebasic
dim i as long = ListBox.GetCurSel( hCtrl )
if i >= 0 then ListBox.DeleteString( hCtrl, i )
```

Microsoft Learn: [LB_DELETESTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-deletestring)

### ResetContent

```freebasic
sub ResetContent( byval hListBox as HWND )
```

Deletes every item.

**Example**

```freebasic
ListBox.ResetContent( hCtrl )
```

Microsoft Learn: [LB_RESETCONTENT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-resetcontent)

### ReplaceString

```freebasic
function ReplaceString( byval hListBox as HWND, byval index as long, byval pwszNewText as wstring ptr, byval pNewData as LONG_PTR = NULL ) as long
```

Replaces item `index` with a new string and item data: it deletes the item, inserts
`pwszNewText` at the same index (a sorted list box is not re-sorted), sets its item data to
`pNewData` (0 by default) and then selects it.

The selection step depends on the style. A single-selection list box selects the new item. An
`LBS_EXTENDEDSEL` list box keeps the new text but the selection step fails, and the function
returns `LB_ERR`. An `LBS_MULTIPLESEL` list box gets `LB_SETSEL` with the index in the place of
the select flag, so it selects item 0 (or, when `index` is 0, deselects it) and leaves the new
item unselected.

| Parameter | Meaning |
| --- | --- |
| `hListBox` | The list box. |
| `index` | The item to replace. |
| `pwszNewText` | Its new text. |
| `pNewData` | Its new item data. |

**Returns** `LB_ERR` when `index` is not an item or the selection step fails, `LB_ERRSPACE`
when memory ran out, otherwise the result of the selection step: the index in a
single-selection list box.

**Example**

```freebasic
ListBox.ReplaceString( hCtrl, 2, "Cherry", 450 )
```

Microsoft Learn: [LB_INSERTSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-insertstring)

### SetText

```freebasic
function SetText( byval hListBox as HWND, byval index as long, byval pwszNewText as wstring ptr ) as long
```

Replaces the text of item `index`, like [ReplaceString](#replacestring) without the item-data
step: the item is deleted and inserted again, so its item data becomes 0. The new item is then
selected, with the same per-style behaviour as [ReplaceString](#replacestring).

**Returns** as [ReplaceString](#replacestring).

**Example**

```freebasic
ListBox.SetText( hCtrl, 0, "Apple (ripe)" )
```

Microsoft Learn: [LB_DELETESTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-deletestring)

### AddFile

```freebasic
function AddFile( byval hListBox as HWND, byval pwszFileName as wstring ptr ) as long
```

Adds the name of an existing file to a list box that [Dir](#dir) filled.

**Returns** the index of the new item, or `LB_ERR`.

**Example**

```freebasic
ListBox.AddFile( hCtrl, "readme.txt" )
```

Microsoft Learn: [LB_ADDFILE](https://learn.microsoft.com/en-us/windows/win32/controls/lb-addfile)

### Dir

```freebasic
function Dir( byval hListBox as HWND, byval Attr as DWORD, byval pwszFileSpec as wstring ptr ) as long
```

Adds the names of the files that match `pwszFileSpec` (a path with wildcards, such as `*.txt`)
and have the attributes in `Attr`. `Attr` is a combination of `DDL_*` values:
`DDL_READWRITE` (0) for ordinary files, `DDL_DIRECTORY` for folders, shown as `[name]`,
`DDL_DRIVES` for drives, shown as `[-c-]`, and `DDL_EXCLUSIVE` for only the kinds named.

**Returns** the index of the last name added, or `LB_ERR` / `LB_ERRSPACE`.

**Example**

```freebasic
ListBox.Dir( hCtrl, DDL_READWRITE or DDL_DIRECTORY, "*.*" )
```

Microsoft Learn: [LB_DIR](https://learn.microsoft.com/en-us/windows/win32/controls/lb-dir)

### InitStorage

```freebasic
function InitStorage( byval hListBox as HWND, byval nItems as DWORD, byval nBytes as DWORD ) as long
```

Reserves memory for `nItems` more items and `nBytes` bytes of their strings before a long run
of [AddString](#addstring) calls, so that the list box does not grow its memory one item at a
time.

**Returns** the number of items memory is now reserved for, the existing ones included (a list
of 4 items reserving 100 more returns 104), or `LB_ERRSPACE`.

**Example**

```freebasic
ListBox.InitStorage( hCtrl, 10000, 10000 * 20 )
```

Microsoft Learn: [LB_INITSTORAGE](https://learn.microsoft.com/en-us/windows/win32/controls/lb-initstorage)

### SetCount

```freebasic
function SetCount( byval hListBox as HWND, byval nCount as DWORD ) as long
```

Sets the number of items of a list box created with `LBS_NODATA` and without
`LBS_HASSTRINGS`, which stores nothing and has its items drawn by the owner from the program's
own data.

**Returns** 0 on success, `LB_ERR` or `LB_ERRSPACE` otherwise.

**Example**

```freebasic
ListBox.SetCount( hCtrl, 100000 )
```

Microsoft Learn: [LB_SETCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setcount)

### GetCount

```freebasic
function GetCount( byval hListBox as HWND ) as long
```

Returns the number of items.

**Returns** the count.

**Example**

```freebasic
for i as long = 0 to ListBox.GetCount( hCtrl ) - 1
    print ListBox.GetText( hCtrl, i )
next
```

Microsoft Learn: [LB_GETCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getcount)

### GetText

```freebasic
function GetText( byval hListBox as HWND, byval index as long ) as ustring
```

Returns the text of item `index`. A negative `index` means the current item: the caret item in
an `LBS_MULTIPLESEL` list box, the selected item in any other (see [GetCurSel](#getcursel)).
The string is exactly the item's text, with no null character at the end.

**Returns** the text, or `""` when there is no such item; afterwards `GetLastError()` is the
number of characters read, or `LB_ERR` when the item does not exist.

**Example**

```freebasic
print "selected: "; ListBox.GetText( hCtrl, -1 )
```

Microsoft Learn: [LB_GETTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-gettext)

### GetTextLen

```freebasic
function GetTextLen( byval hListBox as HWND, byval index as long ) as long
```

Returns the number of characters in the text of item `index`.

**Returns** the length, or `LB_ERR` when `index` is not an item.

**Example**

```freebasic
print ListBox.GetTextLen( hCtrl, 0 ); " characters"
```

Microsoft Learn: [LB_GETTEXTLEN](https://learn.microsoft.com/en-us/windows/win32/controls/lb-gettextlen)

### FindString

```freebasic
function FindString( byval hListBox as HWND, byval indexStart as long, byval pwszString as wstring ptr ) as long
```

Finds the first item whose text begins with `pwszString`, ignoring case. The search starts
after item `indexStart` and wraps round to the top; pass -1 to search from the first item.

**Returns** the index of the item found, or `LB_ERR`.

**Example**

```freebasic
dim i as long = ListBox.FindString( hCtrl, -1, "ap" )   ' finds "Apple" or "apricot"
```

Microsoft Learn: [LB_FINDSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-findstring)

### FindStringExact

```freebasic
function FindStringExact( byval hListBox as HWND, byval indexStart as long, byval pwszSearchString as wstring ptr ) as long
```

Finds the first item whose whole text is `pwszSearchString`, ignoring case. `indexStart` works
as for [FindString](#findstring).

**Returns** the index of the item found, or `LB_ERR`.

**Example**

```freebasic
if ListBox.FindStringExact( hCtrl, -1, "banana" ) = LB_ERR then ListBox.AddString( hCtrl, "Banana" )
```

Microsoft Learn: [LB_FINDSTRINGEXACT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-findstringexact)

### GetItemData

```freebasic
function GetItemData( byval hListBox as HWND, byval index as long ) as LONG_PTR
```

Returns the item data of item `index`: the value set with [SetItemData](#setitemdata), or 0.

**Returns** the value, or `LB_ERR` when `index` is not an item.

**Example**

```freebasic
dim nId as LONG_PTR = ListBox.GetItemData( hCtrl, ListBox.GetCurSel( hCtrl ) )
```

Microsoft Learn: [LB_GETITEMDATA](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getitemdata)

### SetItemData

```freebasic
function SetItemData( byval hListBox as HWND, byval index as long, byval pData as LONG_PTR ) as long
```

Stores a value with item `index`: a number, or a pointer the program allocated and frees
itself before the item is deleted.

**Returns** `LB_ERR` on failure, another value on success.

**Example**

```freebasic
ListBox.SetItemData( hCtrl, ListBox.AddString( hCtrl, "Plum" ), 210 )
```

Microsoft Learn: [LB_SETITEMDATA](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setitemdata)

### AddItemData

```freebasic
function AddItemData( byval hListBox as HWND, byval pData as LONG_PTR ) as long
```

Adds an item to an owner-drawn list box without `LBS_HASSTRINGS`, whose items have only item
data: `pData` becomes the new item's item data. Without `LBS_SORT` the item goes at the end;
with it, the list box asks the owner where with `WM_COMPAREITEM`. On a list box with strings,
`pData` would be read as a string pointer.

**Returns** the index of the new item, or `LB_ERR` / `LB_ERRSPACE`.

**Example**

```freebasic
ListBox.AddItemData( hCtrl, 111 )
```

Microsoft Learn: [LB_ADDSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-addstring)

### InsertItemData

```freebasic
function InsertItemData( byval hListBox as HWND, byval index as long, byval pData as LONG_PTR ) as long
```

Inserts an item with item data `pData` before item `index` of an owner-drawn list box without
`LBS_HASSTRINGS`, or at the end when `index` is -1.

**Returns** the index of the new item, or `LB_ERR` / `LB_ERRSPACE`.

**Example**

```freebasic
ListBox.InsertItemData( hCtrl, 0, 333 )
```

Microsoft Learn: [LB_INSERTSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-insertstring)

### FindItemData

```freebasic
function FindItemData( byval hListBox as HWND, byval indexStart as long, byval pData as LONG_PTR ) as long
```

Finds the first item whose item data is `pData` in an owner-drawn list box without
`LBS_HASSTRINGS`. `indexStart` works as for [FindString](#findstring). With `LBS_SORT` the list
box asks the owner to compare with `WM_COMPAREITEM` instead.

**Returns** the index of the item found, or `LB_ERR`.

**Example**

```freebasic
dim i as long = ListBox.FindItemData( hCtrl, -1, 222 )
```

Microsoft Learn: [LB_FINDSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-findstring)

### SelectItemData

```freebasic
function SelectItemData( byval hListBox as HWND, byval indexStart as long, byval pData as LONG_PTR ) as long
```

Finds the item whose item data is `pData`, as [FindItemData](#finditemdata) does, and selects
it. Single-selection list boxes only.

**Returns** the index of the item selected, or `LB_ERR`.

**Example**

```freebasic
ListBox.SelectItemData( hCtrl, -1, 111 )
```

Microsoft Learn: [LB_SELECTSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-selectstring)

### GetCurSel

```freebasic
function GetCurSel( byval hListBox as HWND ) as long
```

Returns the current item. In a single-selection list box that is the selected item. In an
`LBS_MULTIPLESEL` list box it is the caret item, the one with the focus rectangle, whether it is
selected or not; in an `LBS_EXTENDEDSEL` list box Windows also returns the focused item. Use
[GetSel](#getsel) or [GetSelItems](#getselitems) to read a multiple selection.

**Returns** the index, or `LB_ERR` when nothing is selected in a single-selection list box.

**Example**

```freebasic
dim i as long = ListBox.GetCurSel( hCtrl )
if i = LB_ERR then print "nothing selected"
```

Microsoft Learn: [LB_GETCURSEL](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getcursel)

### SetCurSel

```freebasic
function SetCurSel( byval hListBox as HWND, byval index as long ) as long
```

Selects item `index` of a single-selection list box, scrolling it into view and deselecting
the item selected before. -1 clears the selection. A multiple-selection list box refuses it.

**Returns** `index`, or `LB_ERR` on failure and when `index` is -1.

**Example**

```freebasic
ListBox.SetCurSel( hCtrl, 0 )
```

Microsoft Learn: [LB_SETCURSEL](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setcursel)

### GetSelect

```freebasic
function GetSelect( byval hListBox as HWND, byval startIndex as long = 0 ) as long
```

Returns the first selected item at or after `startIndex`, in an `LBS_EXTENDEDSEL` list box.
Call it again from the index found plus one to walk the whole selection. Any other list box
returns the same as [GetCurSel](#getcursel) and `startIndex` is ignored; in an
`LBS_MULTIPLESEL` list box that is the caret item, which may not be selected.

**Returns** the index, or -1 when no selected item is found. With items 1 to 3 selected,
`GetSelect( h )` is 1, `GetSelect( h, 2 )` is 2 and `GetSelect( h, 4 )` is -1.

**Example**

```freebasic
dim i as long = ListBox.GetSelect( hCtrl )
while i >= 0
    print ListBox.GetText( hCtrl, i )
    i = ListBox.GetSelect( hCtrl, i + 1 )
wend
```

### GetSel

```freebasic
function GetSel( byval hListBox as HWND, byval Index as long ) as boolean
```

Returns whether item `Index` is selected. Works in every kind of list box.

**Returns** `true` when it is selected; `false` when it is not or is not an item.

**Example**

```freebasic
if ListBox.GetSel( hCtrl, 2 ) then print "item 2 is selected"
```

Microsoft Learn: [LB_GETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getsel)

### SetSel

```freebasic
function SetSel( byval hListBox as HWND, byval fSelect as boolean, byval index as long = -1 ) as long
```

Selects (`fSelect` `true`) or deselects item `index` of an `LBS_EXTENDEDSEL` list box; -1, the
default, means every item. Any other list box gets [SetCurSel](#setcursel) with `index`, and
`fSelect` is ignored: a single-selection list box selects `index` even when `fSelect` is
`false` (-1 clears its selection), and an `LBS_MULTIPLESEL` list box refuses the call and
returns `LB_ERR`.

| Parameter | Meaning |
| --- | --- |
| `hListBox` | The list box. |
| `fSelect` | `true` to select, `false` to deselect (extended selection only). |
| `index` | The item, or -1 for all. |

**Returns** `LB_ERR` on failure; otherwise 0 (extended selection) or `index`.

**Example**

```freebasic
ListBox.SetSel( hCtrl, true, 5 )     ' add item 5 to the selection
ListBox.SetSel( hCtrl, false )       ' deselect everything
```

Microsoft Learn: [LB_SETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setsel)

### SelectString

```freebasic
function SelectString( byval hListBox as HWND, byval start as long, byval pwszText as wstring ptr ) as long
function SelectString( byval hListBox as HWND, byval index as long = -1 ) as long
```

The first form finds the first item whose text begins with `pwszText`, ignoring case and
starting after item `start` (-1 for the top), and selects it, scrolling it into view.
Single-selection list boxes only.

The second form selects by index, not by text: in an `LBS_EXTENDEDSEL` list box it adds item
`index` to the selection (-1, the default, selects every item); in any other it calls
[SetCurSel](#setcursel) with `index`.

**Returns** the index of the item selected, or `LB_ERR` (first form); 0 or `index`, or `LB_ERR`
(second form).

**Example**

```freebasic
ListBox.SelectString( hCtrl, -1, "Ba" )   ' selects "Banana"
ListBox.SelectString( hCtrl, 3 )          ' selects item 3
```

Microsoft Learn: [LB_SELECTSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lb-selectstring)

### UnselectString

```freebasic
function UnselectString( byval hListBox as HWND, byval index as long = -1 ) as long
```

Deselects item `index` of an `LBS_EXTENDEDSEL` list box; -1, the default, deselects every
item. Any other list box clears its whole selection, whatever `index` is.

**Returns** 0 in an extended-selection list box, `LB_ERR` on failure. In any other list box it
returns `LB_ERR` (-1) also when the selection was cleared.

**Example**

```freebasic
ListBox.UnselectString( hCtrl, 2 )
```

Microsoft Learn: [LB_SETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setsel)

### GetSelCount

```freebasic
function GetSelCount( byval hListBox as HWND ) as long
```

Returns the number of selected items in a multiple-selection list box.

**Returns** the count, or `LB_ERR` in a single-selection list box.

**Example**

```freebasic
print ListBox.GetSelCount( hCtrl ); " selected"
```

Microsoft Learn: [LB_GETSELCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getselcount)

### GetSelItems

```freebasic
function GetSelItems( byval hListBox as HWND, byval items as DWORD, byval prgItems as long ptr ) as long
```

Reads the indexes of the selected items of a multiple-selection list box, in ascending order,
into an array of `items` `long`s.

| Parameter | Meaning |
| --- | --- |
| `hListBox` | The list box. |
| `items` | How many indexes the array holds. |
| `prgItems` | The first element of the array. |

**Returns** the number of indexes written, or `LB_ERR` in a single-selection list box.

**Example**

```freebasic
dim n as long = ListBox.GetSelCount( hCtrl )
if n > 0 then
    dim sel(0 to n - 1) as long
    n = ListBox.GetSelItems( hCtrl, n, @sel(0) )
end if
```

Microsoft Learn: [LB_GETSELITEMS](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getselitems)

### SelItemRange

```freebasic
function SelItemRange( byval hListBox as HWND, byval fSel as boolean, byval startIndex as short, byval endIndex as short ) as long
```

Selects (`fSel` `true`) or deselects items `startIndex` to `endIndex` of a multiple-selection
list box. The indexes are 16-bit; use [SelItemRangeEx](#selitemrangeex) beyond item 32767.

**Returns** 0, or `LB_ERR` on failure.

**Example**

```freebasic
ListBox.SelItemRange( hCtrl, true, 0, 2 )
```

Microsoft Learn: [LB_SELITEMRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/lb-selitemrange)

### SelItemRangeEx

```freebasic
function SelItemRangeEx( byval hListBox as HWND, byval startIndex as long, byval endIndex as long ) as long
```

Selects items `startIndex` to `endIndex` of a multiple-selection list box. When `startIndex` is
greater than `endIndex`, the items from `endIndex` to `startIndex` are deselected instead.

**Returns** 0, or `LB_ERR` on failure.

**Example**

```freebasic
ListBox.SelItemRangeEx( hCtrl, 1, 3 )   ' select 1 to 3
ListBox.SelItemRangeEx( hCtrl, 3, 1 )   ' deselect them
```

Microsoft Learn: [LB_SELITEMRANGEEX](https://learn.microsoft.com/en-us/windows/win32/controls/lb-selitemrangeex)

### GetAnchorIndex

```freebasic
function GetAnchorIndex( byval hListBox as HWND ) as long
```

Returns the anchor item of a multiple-selection list box: the item a `Shift`-click selection
extends from to the caret item.

**Returns** the index, or -1 when there is none yet.

**Example**

```freebasic
print "anchor"; ListBox.GetAnchorIndex( hCtrl )
```

Microsoft Learn: [LB_GETANCHORINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getanchorindex)

### SetAnchorIndex

```freebasic
function SetAnchorIndex( byval hListBox as HWND, byval index as long ) as long
```

Sets the anchor item of a multiple-selection list box.

**Returns** 0, or `LB_ERR` on failure.

**Example**

```freebasic
ListBox.SetAnchorIndex( hCtrl, 1 )
```

Microsoft Learn: [LB_SETANCHORINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setanchorindex)

### GetCaretIndex

```freebasic
function GetCaretIndex( byval hListBox as HWND ) as long
```

Returns the item that has the focus rectangle, selected or not. In a single-selection list box
it is the selected item, or 0.

**Returns** the index.

**Example**

```freebasic
print "focus on item"; ListBox.GetCaretIndex( hCtrl )
```

Microsoft Learn: [LB_GETCARETINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getcaretindex)

### SetCaretIndex

```freebasic
function SetCaretIndex( byval hListBox as HWND, byval index as long, byval fVisibility as boolean = false ) as long
```

Moves the focus rectangle of a multiple-selection list box to item `index` and scrolls it into
view: wholly with `fVisibility` `false` (the default), partly with `true`.

**Returns** 0, or `LB_ERR` on failure.

**Example**

```freebasic
ListBox.SetCaretIndex( hCtrl, 3 )
```

Microsoft Learn: [LB_SETCARETINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setcaretindex)

### GetTopIndex

```freebasic
function GetTopIndex( byval hListBox as HWND ) as long
```

Returns the first visible item: 0 until the list is scrolled.

**Returns** the index.

**Example**

```freebasic
print "top item"; ListBox.GetTopIndex( hCtrl )
```

Microsoft Learn: [LB_GETTOPINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lb-gettopindex)

### SetTopIndex

```freebasic
function SetTopIndex( byval hListBox as HWND, byval index as long ) as long
```

Scrolls the list so that item `index` is at the top, or as near as the end of the list allows.

**Returns** 0, or `LB_ERR` on failure.

**Example**

```freebasic
ListBox.SetTopIndex( hCtrl, ListBox.GetCount( hCtrl ) - 1 )
```

Microsoft Learn: [LB_SETTOPINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lb-settopindex)

### GetItemHeight

```freebasic
function GetItemHeight( byval hListBox as HWND, byval index as long ) as long
```

Returns the height of the items in pixels. `index` matters only with `LBS_OWNERDRAWVARIABLE`,
where every item has its own height; pass 0 otherwise.

**Returns** the height, or `LB_ERR`.

**Example**

```freebasic
print "rows are"; ListBox.GetItemHeight( hCtrl, 0 ); " pixels high"
```

Microsoft Learn: [LB_GETITEMHEIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getitemheight)

### SetItemHeight

```freebasic
function SetItemHeight( byval hListBox as HWND, byval index as long, byval nHeight as DWORD ) as long
```

Sets the height of the items to `nHeight` pixels (at most 255). With `LBS_OWNERDRAWVARIABLE` it
sets the height of item `index` only; otherwise of all items, and `index` is ignored.

**Returns** `LB_ERR` when the height is out of range, another value otherwise.

**Example**

```freebasic
ListBox.SetItemHeight( hCtrl, 0, 24 )
```

Microsoft Learn: [LB_SETITEMHEIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setitemheight)

### GetItemRect

```freebasic
function GetItemRect( byval hListBox as HWND, byval index as long, byval prc as RECT ptr ) as long
function GetItemRect( byval hListBox as HWND, byval index as long, byref rc as RECT ) as long
function GetItemRect( byval hListBox as HWND, byval index as long ) as ( long, long, long, long )
```

Returns the rectangle item `index` takes up in the list box, in its client coordinates, as it
is displayed now: an item scrolled out of view lies outside the client area.

**Returns** `LB_ERR` on failure (first two forms), or `( left, top, right, bottom )`; afterwards
the third form leaves `GetLastError()` at 1 when the call succeeded, and at `LB_ERR` with four
zeros when `index` is not an item.

**Example**

```freebasic
var (l, t, r, b) = ListBox.GetItemRect( hCtrl, 1 )
if GetLastError() = 1 then print "item 1 is"; b - t; " pixels high"
```

Microsoft Learn: [LB_GETITEMRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getitemrect)

### ItemFromPoint

```freebasic
function ItemFromPoint( byval hListBox as HWND, byval x as short, byval y as short ) as long
```

Returns the item nearest the point (`x`, `y`), in the list box's client coordinates.

**Returns** two values in one: the index in the low word and, in the high word, 0 when the
point is over an item and 1 when it is not. In a list box of 5 items, a point below the last item
returns `&h10004`, whether it is inside the control or outside it.

**Example**

```freebasic
dim r as long = ListBox.ItemFromPoint( hCtrl, 10, 40 )
if HIWORD( r ) = 0 then print "over item"; LOWORD( r )
```

Microsoft Learn: [LB_ITEMFROMPOINT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-itemfrompoint)

### GetListBoxInfo

```freebasic
function GetListBoxInfo( byval hListBox as HWND ) as long
```

Returns how many items fit in each column of the list box, which is what a multicolumn list box
(`LBS_MULTICOLUMN`) wraps at.

**Returns** the number of items per column.

**Example**

```freebasic
print ListBox.GetListBoxInfo( hCtrl ); " items per column"
```

Microsoft Learn: [LB_GETLISTBOXINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getlistboxinfo)

### SetColumnWidth

```freebasic
sub SetColumnWidth( byval hListBox as HWND, byval nWidth as DWORD )
```

Sets the width, in pixels, of every column of a multicolumn list box (`LBS_MULTICOLUMN`).

**Example**

```freebasic
ListBox.SetColumnWidth( hCtrl, 120 )
```

Microsoft Learn: [LB_SETCOLUMNWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setcolumnwidth)

### SetTabStops

```freebasic
sub SetTabStops( byval hListBox as HWND, byval cTabs as long, byval prgTabs as long ptr )
```

Sets where a tab character in an item's text moves to, for a list box created with
`LBS_USETABSTOPS`. The positions are in dialog template units (a quarter of the average
character width). `cTabs` 0 with `prgTabs` `NULL` sets a stop every 32 units; `cTabs` 1 sets
stops at every multiple of `prgTabs[0]`.

| Parameter | Meaning |
| --- | --- |
| `hListBox` | The list box. |
| `cTabs` | The number of tab stops. |
| `prgTabs` | The first of `cTabs` positions, in ascending order. |

**Example**

```freebasic
dim tabs(0 to 1) as long = { 80, 140 }
ListBox.SetTabStops( hCtrl, 2, @tabs(0) )
ListBox.AddString( hCtrl, "Apple" & chr(9) & "0.95" & chr(9) & "kg" )
```

Microsoft Learn: [LB_SETTABSTOPS](https://learn.microsoft.com/en-us/windows/win32/controls/lb-settabstops)

### GetHorizontalExtent

```freebasic
function GetHorizontalExtent( byval hListBox as HWND ) as long
```

Returns the width, in pixels, by which a list box with a horizontal scroll bar can be scrolled
sideways. It is 0 until [SetHorizontalExtent](#sethorizontalextent) sets it.

**Returns** the width.

**Example**

```freebasic
print "scrollable width"; ListBox.GetHorizontalExtent( hCtrl )
```

Microsoft Learn: [LB_GETHORIZONTALEXTENT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-gethorizontalextent)

### SetHorizontalExtent

```freebasic
sub SetHorizontalExtent( byval hListBox as HWND, byval cxExtent as long )
```

Sets the width, in pixels, by which the list box can be scrolled sideways. A list box does not
work it out itself: when the widest item is wider than the control, set this to its width and
the horizontal scroll bar (`WS_HSCROLL`) appears; when the control is wider, the scroll bar is
hidden.

**Example**

```freebasic
ListBox.SetHorizontalExtent( hCtrl, 600 )
```

Microsoft Learn: [LB_SETHORIZONTALEXTENT](https://learn.microsoft.com/en-us/windows/win32/controls/lb-sethorizontalextent)

### CalcHorizontalExtent

```freebasic
function CalcHorizontalExtent( byval hListBox as HWND ) as long
```

Measures the text of every item and returns the width of the widest, for
[SetHorizontalExtent](#sethorizontalextent).

The text is measured in the list box's device context as `GetDC` returns it, with the system
font selected rather than the font the control draws with, so the width differs from what the
user sees unless the control uses the system font. Each item's text is read into a buffer one
character too short for the terminating null, which the list box writes past its end; in testing
a program that called this crashed later, in unrelated code. Measuring the items yourself, with
the control's font (`WM_GETFONT`) selected into the DC, avoids both.

**Returns** the width of the widest item, in logical units of that device context.

**Example**

```freebasic
dim cx as long = ListBox.CalcHorizontalExtent( hCtrl )
ListBox.SetHorizontalExtent( hCtrl, cx )
```

Microsoft Learn: [GetTextExtentPoint32W](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-gettextextentpoint32w)

### GetLocale

```freebasic
function GetLocale( byval hListBox as HWND ) as long
```

Returns the locale a sorted list box compares strings with: the language identifier in the low
word and the country code in the high word.

**Returns** the locale.

**Example**

```freebasic
print "sorting language &h"; hex( LOWORD( ListBox.GetLocale( hCtrl ) ) )
```

Microsoft Learn: [LB_GETLOCALE](https://learn.microsoft.com/en-us/windows/win32/controls/lb-getlocale)

### SetLocale

```freebasic
function SetLocale( byval hListBox as HWND, byval wLocaleID as DWORD ) as long
```

Sets the locale a sorted list box compares strings with when items are added.

**Returns** the previous locale, or `LB_ERR`.

**Example**

```freebasic
ListBox.SetLocale( hCtrl, &h0409 )   ' English (United States)
```

Microsoft Learn: [LB_SETLOCALE](https://learn.microsoft.com/en-us/windows/win32/controls/lb-setlocale)

### Enable

```freebasic
function Enable( byval hListBox as HWND ) as boolean
```

Enables the list box, so that it takes mouse and keyboard input again.

**Returns** `true` or `false`.

**Example**

```freebasic
ListBox.Enable( hCtrl )
```

Microsoft Learn: [EnableWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablewindow)

### Disable

```freebasic
function Disable( byval hListBox as HWND ) as boolean
```

Disables the list box: it is greyed out and ignores the mouse and the keyboard.

**Returns** `true` or `false`.

**Example**

```freebasic
if ListBox.Disable( hCtrl ) then print "was enabled"
```

Microsoft Learn: [EnableWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablewindow)

### SetDarkMode

```freebasic
function SetDarkMode( byval hListBox as HWND ) as HRESULT
```

Gives the list box the `DarkMode_Explorer` theme. Only the scroll bars change; the item colours
come from the parent's `WM_CTLCOLORLISTBOX` handling.

**Returns** `S_OK` on success.

**Example**

```freebasic
if AppsUseDarkMode() then ListBox.SetDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

### RemoveDarkMode

```freebasic
function RemoveDarkMode( byval hListBox as HWND ) as HRESULT
```

Gives the scroll bars the default theme again.

**Returns** `S_OK` on success.

**Example**

```freebasic
ListBox.RemoveDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for `AddControl( "ListBox", ... )`
- [Combo](SysWin-Gui-Combo) for a list that drops down from an edit box
- [ListView](SysWin-Gui-ListView) for lists with columns, icons and check boxes
- [Dark mode](SysWin-Dark-Mode)
