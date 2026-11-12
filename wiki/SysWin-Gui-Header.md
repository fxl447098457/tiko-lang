[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **Header**

# Header

Adds, reads, sizes and reorders the columns of a header control.

A header control is the strip of column titles above a list: each item is a title the user can
click, drag to a new place or resize by its divider. A list view in report view has one of its
own (get it with `ListView.GetHeader`); a standalone one is created with
`CWindow.AddControl( "Header", ... )`. Every function here takes the control's handle first and
is written with the namespace: `Header.GetItemCount( hHeader )`.

Items have two numbers. The **index** is fixed when the item is inserted and is what every
function here takes; the **order** is the item's position from left to right, which changes
when the user drags it. [OrderToIndex](#ordertoindex), [GetItemOrder](#getitemorder) and the
order arrays convert between them. Rectangles are client coordinates of the header.

An item's attributes travel in an `HDITEMW`, whose `mask` says which members are meant
(`HDI_TEXT`, `HDI_WIDTH`, `HDI_FORMAT`, `HDI_IMAGE`, `HDI_ORDER`, `HDI_LPARAM` …). Image lists
and drag images are the program's to destroy.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A header across the top of a window, three columns wide. It is laid out again whenever the
window is resized, and clicking a column puts its text, width and position in the caption.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_HEADER = 101

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

sub AddColumn( byval hHeader as HWND, byval i as long, byref wszText as wstring, byval cx as long )
    dim hdi as HDITEMW
    hdi.mask = HDI_TEXT or HDI_WIDTH or HDI_FORMAT
    hdi.fmt = HDF_LEFT or HDF_STRING
    hdi.cxy = cx
    hdi.pszText = @wszText
    Header.InsertItem( hHeader, i, hdi )
end sub

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "HeaderDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Header", @WndProc )
    pWindow.SetClientSize( 420, 200 )
    pWindow.Center()
    dim hHeader as HWND = pWindow.AddControl( "Header", hWin, IDC_HEADER, "", 0, 0, 420, 24, _
                                              WS_VISIBLE or HDS_HORZ or HDS_BUTTONS or HDS_DRAGDROP or HDS_FULLDRAG )
    AddColumn( hHeader, 0, "Name", 180 )
    AddColumn( hHeader, 1, "Size", 90 )
    AddColumn( hHeader, 2, "Modified", 150 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_SIZE
            dim hHeader as HWND = GetDlgItem( hwnd, IDC_HEADER )
            dim rc as RECT, wpos as WINDOWPOS, hdl as HDLAYOUT
            GetClientRect( hwnd, @rc )
            hdl.prc = @rc : hdl.pwpos = @wpos
            if Header.Layout( hHeader, hdl ) then
                SetWindowPos( hHeader, wpos.hwndInsertAfter, wpos.x, wpos.y, wpos.cx, wpos.cy, wpos.flags )
            end if
            return 0
        case WM_NOTIFY
            dim pnmh as NMHDR ptr = CBNMHDR( wParam, lParam )
            if pnmh->idFrom = IDC_HEADER andalso pnmh->code = HDN_ITEMCLICKW then
                dim i as long = CBNMSGPTR( NMHEADERW, wParam, lParam )->iItem
                SetWindowText( hwnd, Header.GetItemText( pnmh->hwndFrom, i ) & ": " & _
                                     Header.GetItemWidth( pnmh->hwndFrom, i ) & " pixels, position " & _
                                     Header.GetItemOrder( pnmh->hwndFrom, i ) + 1 )
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
| [InsertItem](#insertitem) | Inserts an item from an `HDITEMW`. |
| [DeleteItem](#deleteitem) | Deletes an item. |
| [GetItemCount](#getitemcount) | Returns the number of items. |
| [GetItem](#getitem) | Reads an item's attributes into an `HDITEMW`. |
| [SetItem](#setitem) | Sets an item's attributes from an `HDITEMW`. |
| [GetItemText, GetText](#getitemtext-gettext) | Returns or reads an item's text. |
| [SetItemText, SetText](#setitemtext-settext) | Changes an item's text. |
| [GetItemWidth](#getitemwidth) | Returns an item's width. |
| [SetItemWidth](#setitemwidth) | Sets an item's width. |
| [GetItemOrder](#getitemorder) | Returns an item's position from the left. |
| [SetItemOrder](#setitemorder) | Moves an item to a position. |
| [OrderToIndex](#ordertoindex) | Returns the index of the item at a position. |
| [GetOrderArray](#getorderarray) | Reads the left-to-right order of all items. |
| [SetOrderArray](#setorderarray) | Sets the left-to-right order of all items. |
| [GetItemRect](#getitemrect) | Returns an item's rectangle. |
| [GetItemDropDownRect](#getitemdropdownrect) | Returns the rectangle of an item's drop-down button. |
| [GetOverflowRect](#getoverflowrect) | Returns the rectangle of the overflow button. |
| [HitTest](#hittest) | Finds the item at a point. |
| [Layout](#layout) | Works out where the header goes in a rectangle. |
| [GetFocusedItem](#getfocuseditem) | Returns the item with the keyboard focus. |
| [SetFocusedItem](#setfocuseditem) | Gives an item the keyboard focus. |
| [SetHotDivider](#sethotdivider) | Highlights the divider where a dragged item would drop. |
| [CreateDragImage](#createdragimage) | Makes a drag image of an item. |
| [GetImageList](#getimagelist) | Returns the item image list. |
| [SetImageList](#setimagelist) | Sets the item image list. |
| [GetStateImageList](#getstateimagelist) | Returns the state image list. |
| [SetStateImageList](#setstateimagelist) | Sets the state image list. |
| [GetBitmapMargin](#getbitmapmargin) | Returns the margin around an item's bitmap. |
| [SetBitmapMargin](#setbitmapmargin) | Sets the margin around an item's bitmap. |
| [ClearFilter](#clearfilter) | Clears one item's filter. |
| [ClearAllFilters](#clearallfilters) | Clears every filter. |
| [EditFilter](#editfilter) | Moves the focus into an item's filter box. |
| [SetFilterChangeTimeout](#setfilterchangetimeout) | Sets the delay before a filter change is reported. |
| [SetDarkMode](#setdarkmode) | Gives the header the dark items-view theme. |
| [RemoveDarkMode](#removedarkmode) | Gives the header back its normal theme. |

## Reference

### InsertItem

```freebasic
function InsertItem overload( byval hHeader as HWND, byval i as DWORD, byval phdi as HDITEMW ptr ) as long
function InsertItem overload( byval hHeader as HWND, byval i as DWORD, byref hdi as HDITEMW ) as long
```

Inserts an item before the item with index `i`. An `i` equal to or above the item count adds it
at the right-hand end. Fill in the `HDITEMW` first: usually `HDI_TEXT or HDI_WIDTH or
HDI_FORMAT` with `fmt = HDF_LEFT or HDF_STRING`.

| Parameter | Meaning |
| --- | --- |
| `i` | The index to insert at. |
| `phdi`, `hdi` | The new item. |

**Returns** the index of the new item, or -1 on failure.

**Example**

```freebasic
dim wszText as wstring * 32 = "Name"
dim hdi as HDITEMW
hdi.mask = HDI_TEXT or HDI_WIDTH or HDI_FORMAT
hdi.fmt = HDF_LEFT or HDF_STRING : hdi.cxy = 120 : hdi.pszText = @wszText
Header.InsertItem( hCtrl, Header.GetItemCount( hCtrl ), hdi )   ' at the end
```

Microsoft Learn: [HDM_INSERTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-insertitem)

### DeleteItem

```freebasic
function DeleteItem( byval hHeader as HWND, byval i as long ) as boolean
```

Deletes the item with index `i`. The items to its right move down one index.

**Returns** `true` on success.

**Example**

```freebasic
Header.DeleteItem( hCtrl, Header.GetItemCount( hCtrl ) - 1 )   ' the last one inserted
```

Microsoft Learn: [HDM_DELETEITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-deleteitem)

### GetItemCount

```freebasic
function GetItemCount( byval hHeader as HWND ) as long
```

**Returns** the number of items, or -1 on failure.

**Example**

```freebasic
print Header.GetItemCount( hCtrl ); " columns"
```

Microsoft Learn: [HDM_GETITEMCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getitemcount)

### GetItem

```freebasic
function GetItem overload( byval hHeader as HWND, byval i as long, byval phdi as HDITEMW ptr ) as boolean
function GetItem overload( byval hHeader as HWND, byval i as long, byref hdi as HDITEMW ) as boolean
```

Reads the attributes of item `i` that `mask` asks for. For the text, point `pszText` at a buffer
and set `cchTextMax`.

**Returns** `true` on success, or `false`otherwise.

**Example**

```freebasic
dim hdi as HDITEMW
hdi.mask = HDI_WIDTH or HDI_FORMAT
if Header.GetItem( hCtrl, 0, hdi ) then print "width"; hdi.cxy; ", right-aligned:"; ( hdi.fmt and HDF_RIGHT ) <> 0
```

Microsoft Learn: [HDM_GETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getitem)

### SetItem

```freebasic
function SetItem overload( byval hHeader as HWND, byval i as DWORD, byval phdi as HDITEMW ptr ) as long
function SetItem overload( byval hHeader as HWND, byval i as DWORD, byref hdi as HDITEMW ) as long
```

Changes the attributes of item `i` that `mask` names; the others stay as they are.

**Returns** nonzero on success, 0 on failure.

**Example**

```freebasic
dim hdi as HDITEMW
hdi.mask = HDI_FORMAT : hdi.fmt = HDF_STRING or HDF_SORTUP
Header.SetItem( hCtrl, 0, hdi )   ' show a sort arrow
```

Microsoft Learn: [HDM_SETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-setitem)

### GetItemText, GetText

```freebasic
function GetItemText overload( byval hHeader as HWND, byval iItem as long, byval pwszText as wstring ptr, byval cchTextMax as long = MAX_PATH + 1 ) as boolean
function GetItemText overload( byval hHeader as HWND, byval iItem as long ) as ustring
function GetText overload( byval hHeader as HWND, byval iItem as long, byval pwszText as wstring ptr, byval cchTextMax as long = MAX_PATH + 1 ) as boolean
function GetText overload( byval hHeader as HWND, byval iItem as long ) as ustring
```

The `ustring` forms return the text of item `iItem`, at most 260 characters, and set
`GetLastError()` to 1 on success and 0 on failure. The buffer forms copy it into a buffer of
`cchTextMax` characters, the terminating null included; the default of 261 suits a
`wstring * 261`, so pass the real size of a smaller buffer. The two names do the same thing.

**Returns** the text, `""` on failure; or, for the buffer forms, `true` on success and `false`
on failure or for a `NULL` buffer.

**Example**

```freebasic
print Header.GetItemText( hCtrl, 0 )
dim wszText as wstring * 64
if Header.GetText( hCtrl, 1, @wszText, 64 ) then print len( wszText ); " characters"
```

Microsoft Learn: [HDM_GETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getitem)

### SetItemText, SetText

```freebasic
function SetItemText( byval hHeader as HWND, byval iItem as long, byval pwszText as wstring ptr ) as boolean
function SetText( byval hHeader as HWND, byval iItem as long, byval pwszText as wstring ptr ) as boolean
```

Change the text of item `iItem`; the two names do the same thing.

**Returns** `true` on success; `false` on failure or when `pwszText` is `NULL`.

**Example**

```freebasic
Header.SetItemText( hCtrl, 0, "File name" )
Header.SetText( hCtrl, 1, "Size (KB)" )
```

Microsoft Learn: [HDM_SETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-setitem)

### GetItemWidth

```freebasic
function GetItemWidth( byval hHeader as HWND, byval iItem as long ) as long
```

**Returns** the width of item `iItem` in pixels, or 0 on failure.

**Example**

```freebasic
print "first column:"; Header.GetItemWidth( hCtrl, 0 ); " pixels"
```

### SetItemWidth

```freebasic
function SetItemWidth( byval hHeader as HWND, byval nItem as long, byval nWidth as long ) as boolean
```

Sets the width of item `nItem` in pixels. The items to its right move.

**Returns** `true` on success.

**Example**

```freebasic
Header.SetItemWidth( hCtrl, 0, 200 )
```

### GetItemOrder

```freebasic
function GetItemOrder( byval hHeader as HWND, byval iItem as long ) as long
```

Returns the position from the left, counting from 0, of the item with index `iItem`.

**Returns** the position, or 0 on failure (the same as the first position).

**Example**

```freebasic
print "column 2 is shown at position"; Header.GetItemOrder( hCtrl, 2 )
```

### SetItemOrder

```freebasic
function SetItemOrder( byval hHeader as HWND, byval iItem as long, byval iOrder as long ) as boolean
```

Moves the item with index `iItem` to position `iOrder` from the left; the other items shift to
make room.

**Returns** `true` on success.

**Example**

```freebasic
Header.SetItemOrder( hCtrl, 2, 0 )   ' column 2 first
```

### OrderToIndex

```freebasic
function OrderToIndex( byval hHeader as HWND, byval i as long ) as long
```

Returns the index of the item shown at position `i` from the left.

**Returns** the index.

**Example**

```freebasic
print "leftmost column has index"; Header.OrderToIndex( hCtrl, 0 )
```

Microsoft Learn: [HDM_ORDERTOINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-ordertoindex)

### GetOrderArray

```freebasic
function GetOrderArray( byval hHeader as HWND, byval iCount as long, byval lpiArray as long ptr ) as long
```

Fills an array of `iCount` longs with item indexes in left-to-right order. Make `iCount` the
item count.

**Returns** nonzero on success, 0 on failure.

**Example**

```freebasic
dim n as long = Header.GetItemCount( hCtrl )
dim order( 0 to 15 ) as long
if n > 0 andalso n <= 16 andalso Header.GetOrderArray( hCtrl, n, @order( 0 ) ) then print "leftmost:"; order( 0 )
```

Microsoft Learn: [HDM_GETORDERARRAY](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getorderarray)

### SetOrderArray

```freebasic
function SetOrderArray( byval hHeader as HWND, byval iCount as long, byval lpiArray as long ptr ) as boolean
```

Rearranges all the items: `lpiArray` holds `iCount` item indexes in the left-to-right order
wanted, and `iCount` must be the item count.

**Returns** `true` on success.

**Example**

```freebasic
dim order( 0 to 2 ) as long = { 2, 0, 1 }
Header.SetOrderArray( hCtrl, 3, @order( 0 ) )   ' column 2, then 0, then 1
```

Microsoft Learn: [HDM_SETORDERARRAY](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-setorderarray)

### GetItemRect

```freebasic
function GetItemRect overload( byval hHeader as HWND, byval iItem as long, byval prc as RECT ptr ) as boolean
function GetItemRect overload( byval hHeader as HWND, byval iItem as long, byref rc as RECT ) as boolean
function GetItemRect overload( byval hHeader as HWND, byval iItem as long ) as ( long, long, long, long )
```

Gets the rectangle of item `iItem` in the header's client coordinates.

**Returns** `true` on success; the tuple form returns `( left, top, right, bottom )` and sets
`GetLastError()` to 1 on success and 0 on failure (four zeros).

**Example**

```freebasic
var (l, t, r, b) = Header.GetItemRect( hCtrl, 1 )
if GetLastError() = 1 then print "column 1 runs from"; l; " to"; r
```

Microsoft Learn: [HDM_GETITEMRECT](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getitemrect)

### GetItemDropDownRect

```freebasic
function GetItemDropDownRect overload( byval hHeader as HWND, byval iItem as long, byval prc as RECT ptr ) as boolean
function GetItemDropDownRect overload( byval hHeader as HWND, byval iItem as long, byref rc as RECT ) as boolean
function GetItemDropDownRect overload( byval hHeader as HWND, byval iItem as long ) as ( long, long, long, long )
```

Gets the rectangle of the drop-down button of item `iItem`, which only an item with the
`HDF_SPLITBUTTON` format has; for others the call fails. Use it to place a menu under the button
when the parent receives `HDN_DROPDOWN`.

**Returns** `true` on success (`false` for a `NULL` `prc`); the tuple form returns the four edges
and sets `GetLastError()` to the control's reply, nonzero on success.

**Example**

```freebasic
var (l, t, r, b) = Header.GetItemDropDownRect( hCtrl, 0 )
if GetLastError() then print "drop-down button at"; l; ","; b
```

Microsoft Learn: [HDM_GETITEMDROPDOWNRECT](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getitemdropdownrect)

### GetOverflowRect

```freebasic
function GetOverflowRect overload( byval hHeader as HWND, byval prc as RECT ptr ) as boolean
function GetOverflowRect overload( byval hHeader as HWND, byref rc as RECT ) as boolean
function GetOverflowRect overload( byval hHeader as HWND ) as ( long, long, long, long )
```

Gets the rectangle of the overflow button, which a header with the `HDS_OVERFLOW` style shows at
its right end when the items do not all fit. Use it to place a menu of the hidden items when the
parent receives `HDN_OVERFLOWCLICK`.

**Returns** `true` on success (`false` for a `NULL` `prc`); the tuple form returns the four edges
and sets `GetLastError()` to the control's reply, nonzero on success.

**Example**

```freebasic
var (l, t, r, b) = Header.GetOverflowRect( hCtrl )
if GetLastError() then print "overflow button at"; l
```

Microsoft Learn: [HDM_GETOVERFLOWRECT](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getoverflowrect)

### HitTest

```freebasic
function HitTest overload( byval hHeader as HWND, byval phdhti as HDHITTESTINFO ptr ) as long
function HitTest overload( byval hHeader as HWND, byref hdhti as HDHITTESTINFO ) as long
```

Finds what is at the point `pt` of an `HDHITTESTINFO`, in client coordinates. On return `flags`
says which part is there (`HHT_ONHEADER`, `HHT_ONDIVIDER`, `HHT_ONFILTER`, `HHT_NOWHERE` …) and
`iItem` holds the item.

The first form returns 0 for a `NULL` pointer, the same value as for item 0.

**Returns** the index of the item at the point, or -1 when there is none.

**Example**

```freebasic
dim ht as HDHITTESTINFO
GetCursorPos( @ht.pt ) : ScreenToClient( hCtrl, @ht.pt )
dim i as long = Header.HitTest( hCtrl, ht )
if ht.flags and HHT_ONDIVIDER then print "on the divider after column"; i
```

Microsoft Learn: [HDM_HITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-hittest)

### Layout

```freebasic
function Layout overload( byval hHeader as HWND, byval phdl as HDLAYOUT ptr ) as boolean
function Layout overload( byval hHeader as HWND, byref hdl as HDLAYOUT ) as boolean
```

Works out the size and position of the header inside a rectangle. `prc` points to the
rectangle, usually the parent's client area, and `pwpos` to a `WINDOWPOS` that receives the
header's position, size and flags, ready for `SetWindowPos`; the rectangle is shrunk to the part
left below the header.

**Returns** `true` on success.

**Example**

```freebasic
dim rc as RECT, wpos as WINDOWPOS, hdl as HDLAYOUT
GetClientRect( hwnd, @rc )
hdl.prc = @rc : hdl.pwpos = @wpos
if Header.Layout( hCtrl, hdl ) then SetWindowPos( hCtrl, wpos.hwndInsertAfter, wpos.x, wpos.y, wpos.cx, wpos.cy, wpos.flags )
```

Microsoft Learn: [HDM_LAYOUT](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-layout)

### GetFocusedItem

```freebasic
function GetFocusedItem( byval hHeader as HWND ) as long
```

**Returns** the index of the item with the keyboard focus, 0 when none has been given it.

**Example**

```freebasic
print "focus on column"; Header.GetFocusedItem( hCtrl )
```

Microsoft Learn: [HDM_GETFOCUSEDITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getfocuseditem)

### SetFocusedItem

```freebasic
function SetFocusedItem( byval hHeader as HWND, byval iItem as long ) as boolean
```

Gives item `iItem` the keyboard focus within the header.

**Returns** `true` on success.

**Example**

```freebasic
Header.SetFocusedItem( hCtrl, 1 )
```

Microsoft Learn: [HDM_SETFOCUSEDITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-setfocuseditem)

### SetHotDivider

```freebasic
function SetHotDivider( byval hHeader as HWND, byval fPos as boolean, byval dwInputValue as long ) as long
```

Highlights a divider to show where an item dragged from outside the header would be dropped.
With `fPos = true`, `dwInputValue` is a point in client coordinates (x in the low word, y in the
high word) and the control picks the divider nearest to it; with `false` it is the divider's
index, and -1 removes the highlight.

**Returns** the index of the highlighted divider, or -1 when none is.

**Example**

```freebasic
Header.SetHotDivider( hCtrl, true, MAKELONG( 150, 5 ) )
Header.SetHotDivider( hCtrl, false, -1 )   ' remove it
```

Microsoft Learn: [HDM_SETHOTDIVIDER](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-sethotdivider)

### CreateDragImage

```freebasic
function CreateDragImage( byval hHeader as HWND, byval i as long ) as HIMAGELIST
```

Makes a semi-transparent image of item `i` to show while it is dragged, in a new image list. The
image list is yours: destroy it with `ImageList_Destroy` when the drag ends.

**Returns** the image list, or `NULL` on failure.

**Example**

```freebasic
dim himlDrag as HIMAGELIST = Header.CreateDragImage( hCtrl, 0 )
if himlDrag then ImageList_Destroy( himlDrag )
```

Microsoft Learn: [HDM_CREATEDRAGIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-createdragimage)

### GetImageList

```freebasic
function GetImageList( byval hHeader as HWND ) as HIMAGELIST
```

Returns the image list whose images items show with `HDI_IMAGE` (`HDSIL_NORMAL`).

**Returns** the image list, or `NULL` when there is none.

**Example**

```freebasic
dim himl as HIMAGELIST = Header.GetImageList( hCtrl )
```

Microsoft Learn: [HDM_GETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getimagelist)

### SetImageList

```freebasic
function SetImageList( byval hHeader as HWND, byval himl as HIMAGELIST ) as HIMAGELIST
```

Gives the header the image list its items take images from (`HDSIL_NORMAL`); `NULL` removes it.
An item shows an image when its mask has `HDI_IMAGE` and its format `HDF_IMAGE`.

**Returns** the previous image list, or `NULL`.

**Example**

```freebasic
dim himl as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32 or ILC_MASK, 2, 2 )
Header.SetImageList( hCtrl, himl )
```

Microsoft Learn: [HDM_SETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-setimagelist)

### GetStateImageList

```freebasic
function GetStateImageList( byval hHeader as HWND ) as HIMAGELIST
```

Returns the state image list (`HDSIL_STATE`), which holds the images of the check boxes of a
header with the `HDS_CHECKBOXES` style.

**Returns** the image list, or `NULL` when there is none.

**Example**

```freebasic
dim himlState as HIMAGELIST = Header.GetStateImageList( hCtrl )
```

Microsoft Learn: [HDM_GETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getimagelist)

### SetStateImageList

```freebasic
function SetStateImageList( byval hHeader as HWND, byval himl as HIMAGELIST ) as HIMAGELIST
```

Sets the state image list (`HDSIL_STATE`); `NULL` removes it.

**Returns** the previous state image list, or `NULL`.

**Example**

```freebasic
dim himl as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32 or ILC_MASK, 2, 2 )
Header.SetStateImageList( hCtrl, himl )
```

Microsoft Learn: [HDM_SETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-setimagelist)

### GetBitmapMargin

```freebasic
function GetBitmapMargin( byval hHeader as HWND ) as long
```

**Returns** the margin, in pixels, around a bitmap or image in an item; until one is set it is
three times the width of a window edge (`GetSystemMetrics( SM_CXEDGE )`).

**Example**

```freebasic
print Header.GetBitmapMargin( hCtrl )
```

Microsoft Learn: [HDM_GETBITMAPMARGIN](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getbitmapmargin)

### SetBitmapMargin

```freebasic
function SetBitmapMargin( byval hHeader as HWND, byval iWidth as DWORD ) as long
```

Sets the margin, in pixels, around a bitmap or image in an item. Microsoft documents the reply
as the margin width, but in testing it was 1 whatever the width; read the margin back with
[GetBitmapMargin](#getbitmapmargin).

**Returns** the control's reply.

**Example**

```freebasic
Header.SetBitmapMargin( hCtrl, 10 )
print Header.GetBitmapMargin( hCtrl )   ' 10
```

Microsoft Learn: [HDM_SETBITMAPMARGIN](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-setbitmapmargin)

### ClearFilter

```freebasic
function ClearFilter( byval hHeader as HWND, byval i as long ) as boolean
```

Empties the filter box of item `i` in a header with the `HDS_FILTERBAR` style.

**Returns** `true` on success.

**Example**

```freebasic
Header.ClearFilter( hCtrl, 0 )
```

Microsoft Learn: [HDM_CLEARFILTER](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-clearfilter)

### ClearAllFilters

```freebasic
function ClearAllFilters( byval hHeader as HWND ) as boolean
```

Empties every filter box: [ClearFilter](#clearfilter) with an index of -1.

**Returns** `true` on success.

**Example**

```freebasic
Header.ClearAllFilters( hCtrl )
```

Microsoft Learn: [HDM_CLEARFILTER](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-clearfilter)

### EditFilter

```freebasic
function EditFilter( byval hHeader as HWND, byval i as long, byval fDiscardChanges as boolean ) as boolean
```

Moves the keyboard focus into the filter box of item `i`, for example when its filter button has
the focus. If the user is in the middle of editing a filter, `fDiscardChanges = true` throws the
edit away and `false` keeps it.

**Returns** `true` on success.

**Example**

```freebasic
Header.EditFilter( hCtrl, 0, false )
```

Microsoft Learn: [HDM_EDITFILTER](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-editfilter)

### SetFilterChangeTimeout

```freebasic
function SetFilterChangeTimeout( byval hHeader as HWND, byval i as long ) as long
```

Sets how long, in milliseconds, the header waits after the user changes a filter before it
sends `HDN_FILTERCHANGE`, so that typing a word gives one notification rather than one a key.

**Returns** the previous timeout (1000 until one is set).

**Example**

```freebasic
Header.SetFilterChangeTimeout( hCtrl, 500 )
```

Microsoft Learn: [HDM_SETFILTERCHANGETIMEOUT](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-setfilterchangetimeout)

### SetDarkMode

```freebasic
function SetDarkMode( byval hHeader as HWND ) as HRESULT
```

Gives the header the dark theme of Explorer's item views (`DarkMode_ItemsView`). Use it on the
header of a list view that is itself in dark mode.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
Header.SetDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

### RemoveDarkMode

```freebasic
function RemoveDarkMode( byval hHeader as HWND ) as HRESULT
```

Gives the header back its normal visual style.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
Header.RemoveDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

## See also

- [sys/win/gui](SysWin-Gui)
- [ListView](SysWin-Gui-ListView) for the header of a report-view list
- [CWindow](CWindow) for `AddControl( "Header", ... )`
- [gui macros and helpers](SysWin-Gui-Procedures) for reading `WM_NOTIFY` in the window procedure
- [TreeView](SysWin-Gui-TreeView)
- [Dark mode](SysWin-Dark-Mode)
