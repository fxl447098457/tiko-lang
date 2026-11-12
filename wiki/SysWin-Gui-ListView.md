[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **ListView**

# ListView

Adds columns and rows to a list view and reads, selects, sorts and groups its items.

A list view shows a collection of items in one of five views: large icons, small icons, a list,
a report (details) with one column per field, or tiles. Every function in the `ListView`
namespace takes the control's handle first and sends it one message, or a few.

The model the reader needs:

- **Items and subitems.** Items (rows) are numbered from 0. In report view each item has one
  subitem per column, numbered like the columns: subitem 0 is the item's own text, shown in
  column 0. Deleting or inserting an item renumbers the items after it; sorting renumbers all of
  them. An item keeps an application value (`lParam`) and, with visual styles, a unique ID
  ([MapIndexToID](#mapindextoid)) that survive renumbering.
- **Header.** Report view draws its column titles with a separate header control, reached with
  [GetHeader](#getheader); several functions here work on it directly.
- **Image lists.** The control draws icons from image lists you give it with
  [SetImageList](#setimagelist). It destroys them when it is destroyed unless it has the
  `LVS_SHAREIMAGELISTS` style, in which case they stay yours to destroy.
- **Visual styles.** Groups, tiles, footers, item IDs and [GetView](#getview)/[SetView](#setview)
  need version 6 of the common controls: call `EnableVisualStyles()` at start-up, or ship a
  manifest. Without it these calls fail or return 0.
- **Text.** Text goes in and out as Unicode, with four exceptions noted on their entries: the
  structure forms of [GetItem](#getitem), [SetItem](#setitem), [InsertColumn](#insertcolumn)
  and the background-image calls send the ANSI messages.

`CWindow.AddControl( "ListView", ... )` creates a report-view list view with a client edge and the
styles `LVS_SHOWSELALWAYS`, `LVS_SHAREIMAGELISTS`, `LVS_AUTOARRANGE`, `LVS_EDITLABELS` and
`LVS_ALIGNTOP`. What the user does arrives at the parent window as `WM_NOTIFY` messages with
`LVN_*` codes.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A report view of planets with three columns and full-row selection; selecting a row puts its
name in the caption:

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

#define IDC_LIST 1001

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    EnableVisualStyles()
    dim pWindow as CWindow = "ListViewDemo"
    dim hWin as HWND = pWindow.Create( NULL, "ListView", @WndProc )
    SetWindowClientSizeForDpi( hWin, 420, 240 )
    CenterWindow( hWin )
    dim hList as HWND = pWindow.AddControl( "ListView", hWin, IDC_LIST, "", 10, 10, 400, 220 )
    ListView.SetExtendedStyle( hList, LVS_EX_FULLROWSELECT or LVS_EX_GRIDLINES )
    ListView.AddColumn( hList, 0, "Planet", 100 )
    ListView.AddColumn( hList, 1, "Moons", 80, LVCFMT_RIGHT )
    ListView.AddColumn( hList, 2, "Kind", 100 )
    dim names(0 to 3) as ustring = { "Mercury", "Venus", "Earth", "Mars" }
    dim moons(0 to 3) as ustring = { "0", "0", "1", "2" }
    for i as long = 0 to 3
        ListView.AddItem( hList, i, 0, names(i) )
        ListView.SetItemText( hList, i, 1, moons(i) )
        ListView.SetItemText( hList, i, 2, wstr("rocky") )
    next
    ListView.AutoSizeHeader( hList )
    ListView.SelectItem( hList, 0 )
    SetFocus( hList )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_NOTIFY
            dim pnmv as NMLISTVIEW ptr = cast(NMLISTVIEW ptr, lParam)
            if pnmv->hdr.idFrom = IDC_LIST andalso pnmv->hdr.code = LVN_ITEMCHANGED then
                if ( pnmv->uNewState and LVIS_SELECTED ) <> 0 then
                    dim wszName as wstring * 64
                    ListView.GetItemText( pnmv->hdr.hwndFrom, pnmv->iItem, 0, @wszName, 64 )
                    dim ustrName as ustring = wszName
                    SetWindowText( hwnd, "Selected: " & ustrName )
                end if
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
| **Columns** | |
| [AddColumn](#addcolumn) | Adds a column with a title, a width and an alignment. |
| [InsertColumn](#insertcolumn) | Inserts a column, from a title or from a column structure. |
| [DeleteColumn](#deletecolumn) | Removes a column. |
| [GetColumn](#getcolumn) | Reads a column's attributes. |
| [SetColumn](#setcolumn) | Changes a column's attributes. |
| [GetColumnText](#getcolumntext) | Returns a column's title. |
| [GetColumnCount](#getcolumncount) | Returns the number of columns. |
| [GetColumnWidth](#getcolumnwidth) | Returns a column's width. |
| [SetColumnWidth](#setcolumnwidth) | Sets a column's width. |
| [FitContent](#fitcontent) | Sizes a column to its widest item. |
| [FitHeader](#fitheader) | Sizes a column to its title, or the last one to the remaining width. |
| [AutoSizeColumns](#autosizecolumns) | Sizes every column to its widest item. |
| [AutoSizeHeader](#autosizeheader) | Sizes every column to its title. |
| [GetColumnOrderArray](#getcolumnorderarray) | Reads the left-to-right order of the columns. |
| [SetColumnOrderArray](#setcolumnorderarray) | Sets the left-to-right order of the columns. |
| [GetColumnOrder](#getcolumnorder) | Returns where one column is shown. |
| [GetOrderArray](#getorderarray) | Reads the column order from the header control. |
| [GetSelectedColumn](#getselectedcolumn) | Returns the highlighted column. |
| [SetSelectedColumn](#setselectedcolumn) | Highlights a column. |
| **Header** | |
| [GetHeader](#getheader) | Returns the header control. |
| [GetHeaderText](#getheadertext) | Returns a column title, read from the header control. |
| [MakeHeaderFlat](#makeheaderflat) | Switches the header between button-like and flat titles. |
| [SetHeaderFont](#setheaderfont) | Creates a font and gives it to the header. |
| [ModifyHeaderFont](#modifyheaderfont) | Gives the header a changed copy of its font. |
| **Items** | |
| [AddItem](#additem) | Inserts an item with a text. |
| [InsertItem](#insertitem) | Inserts an item, from a text or from an item structure. |
| [AppendItem](#appenditem) | Adds an item at the end. |
| [DeleteItem](#deleteitem) | Removes an item. |
| [DeleteAllItems](#deleteallitems) | Removes every item. |
| [GetItem](#getitem) | Reads an item's attributes. |
| [SetItem](#setitem) | Changes an item's attributes. |
| [GetItemCount](#getitemcount) | Returns the number of items. |
| [SetItemCount](#setitemcount) | Reserves room for items, or sets a virtual list's count. |
| [SetItemCountEx](#setitemcountex) | Sets a virtual list's count, with flags. |
| [GetItemState](#getitemstate) | Returns state bits of an item. |
| [SetItemState](#setitemstate) | Changes state bits of an item or of all items. |
| [Update](#update) | Updates an item and rearranges the control. |
| [RedrawItems](#redrawitems) | Marks a range of items for repainting. |
| [MapIndexToID](#mapindextoid) | Returns the unique ID of an item. |
| [MapIDToIndex](#mapidtoindex) | Returns the current index of an item ID. |
| [GetCallbackMask](#getcallbackmask) | Returns the states the application keeps itself. |
| [SetCallbackMask](#setcallbackmask) | Sets the states the application keeps itself. |
| **Text** | |
| [GetItemText](#getitemtext) | Copies the text of an item or subitem into a buffer. |
| [SetItemText](#setitemtext) | Sets the text of an item or subitem. |
| [GetStringWidth](#getstringwidth) | Measures a text in the control's font. |
| [EditLabel](#editlabel) | Starts in-place editing of an item's text. |
| [CancelEditLabel](#canceleditlabel) | Cancels in-place editing. |
| [GetEditControl](#geteditcontrol) | Returns the edit control used for in-place editing. |
| [GetEmptyText](#getemptytext) | Reads the text shown when the control is empty. |
| **Searching** | |
| [FindItem](#finditem) | Finds an item by text, `lParam` or position. |
| [FindString](#findstring) | Finds the first item whose text starts with a string. |
| [GetNextItem](#getnextitem) | Finds the next item with given properties. |
| [GetNextItemIndex](#getnextitemindex) | Finds the next item with given properties, by item and group. |
| [GetISearchString](#getisearchstring) | Returns what the user has typed to find an item. |
| [GetISearchStringLen](#getisearchstringlen) | Returns the length of that search text. |
| **Selection and focus** | |
| [GetSelection](#getselection) | Returns the first selected item. |
| [GetFocusedItem](#getfocuseditem) | Returns the item with the focus. |
| [GetSelectedCount](#getselectedcount) | Returns the number of selected items. |
| [SelectItem](#selectitem) | Selects an item and gives it the focus. |
| [SelectAllItems](#selectallitems) | Selects every item. |
| [UnselectItem](#unselectitem) | Deselects an item. |
| [UnselectAllItems](#unselectallitems) | Deselects every item and removes the focus. |
| [GetSelectionMark](#getselectionmark) | Returns the selection mark. |
| [SetSelectionMark](#setselectionmark) | Sets the selection mark. |
| [SetItemIndexState](#setitemindexstate) | Changes the state of an item named by item and group. |
| [GetHotItem](#gethotitem) | Returns the item under the pointer when hot tracking. |
| [SetHotItem](#sethotitem) | Sets the hot item. |
| [GetHotCursor](#gethotcursor) | Returns the cursor shown over hot items. |
| [SetHotCursor](#sethotcursor) | Sets the cursor shown over hot items. |
| [GetHoverTime](#gethovertime) | Returns the hover time before an item is selected. |
| [SetHoverTime](#sethovertime) | Sets the hover time before an item is selected. |
| **Check boxes** | |
| [GetCheckState](#getcheckstate) | Reads whether an item's check box is checked. |
| [SetCheckState](#setcheckstate) | Checks or unchecks an item's check box. |
| **Styles and view** | |
| [GetExtendedStyle](#getextendedstyle) | Returns the `LVS_EX_*` styles. |
| [SetExtendedStyle](#setextendedstyle) | Replaces the `LVS_EX_*` styles. |
| [SetExtendedStyleEx](#setextendedstyleex) | Changes some `LVS_EX_*` styles. |
| [GetView](#getview) | Returns the current view. |
| [SetView](#setview) | Switches to another view. |
| [SetDarkMode](#setdarkmode) | Gives the control the dark Explorer theme. |
| [RemoveDarkMode](#removedarkmode) | Restores the default theme. |
| **Colours and background** | |
| [GetBkColor](#getbkcolor) | Returns the background colour. |
| [SetBkColor](#setbkcolor) | Sets the background colour. |
| [GetTextColor](#gettextcolor) | Returns the text colour. |
| [SetTextColor](#settextcolor) | Sets the text colour. |
| [GetTextBkColor](#gettextbkcolor) | Returns the text background colour. |
| [SetTextBkColor](#settextbkcolor) | Sets the text background colour. |
| [GetOutlineColor](#getoutlinecolor) | Returns the border colour of `LVS_EX_BORDERSELECT`. |
| [SetOutlineColor](#setoutlinecolor) | Sets the border colour of `LVS_EX_BORDERSELECT`. |
| [GetBkImage](#getbkimage) | Reads the background image. |
| [SetBkImage](#setbkimage) | Sets the background image. |
| **Images** | |
| [GetImageList](#getimagelist) | Returns one of the control's image lists. |
| [SetImageList](#setimagelist) | Gives the control an image list. |
| [CreateDragImage](#createdragimage) | Creates a drag image for an item. |
| **Layout, position and scrolling** | |
| [ApproximateViewRect](#approximateviewrect) | Estimates the size needed for a number of items. |
| [Arrange](#arrange) | Arranges the items in icon view. |
| [GetCountPerPage](#getcountperpage) | Returns how many items fit in the visible area. |
| [GetTopIndex](#gettopindex) | Returns the first visible item. |
| [EnsureVisible](#ensurevisible) | Scrolls an item into view. |
| [IsItemVisible](#isitemvisible) | Reads whether an item is visible. |
| [Scroll](#scroll) | Scrolls the content. |
| [GetOrigin](#getorigin) | Returns the view origin. |
| [GetViewRect](#getviewrect) | Returns the rectangle around all items. |
| [GetItemRect](#getitemrect) | Returns the rectangle of an item or part of it. |
| [GetSubItemRect](#getsubitemrect) | Returns the rectangle of a subitem. |
| [GetItemIndexRect](#getitemindexrect) | Returns the rectangle of a subitem named by item and group. |
| [GetItemPosition](#getitemposition) | Returns where an item is. |
| [SetItemPosition](#setitemposition) | Moves an item in icon view. |
| [SetItemPosition32](#setitemposition32) | Moves an item in icon view, with 32-bit coordinates. |
| [GetItemSpacing](#getitemspacing) | Returns the spacing between items. |
| [GetItemHorizontalSpacing](#getitemhorizontalspacing) | Returns the horizontal spacing between items. |
| [GetItemVerticalSpacing](#getitemverticalspacing) | Returns the vertical spacing between items. |
| [SetIconSpacing](#seticonspacing) | Sets the spacing between icons. |
| [GetWorkAreas](#getworkareas) | Reads the working areas. |
| [SetWorkAreas](#setworkareas) | Sets the working areas. |
| [GetNumberOfWorkAreas](#getnumberofworkareas) | Meant to return the number of working areas. |
| **Hit testing** | |
| [HitTest](#hittest) | Finds the item at a point. |
| [HitTestEx](#hittestex) | Finds the item, subitem and group at a point. |
| [SubItemHitTest](#subitemhittest) | Finds the item and subitem at a point. |
| [SubItemHitTestEx](#subitemhittestex) | Finds the item, subitem and group at a point. |
| **Insertion mark** | |
| [GetInsertMark](#getinsertmark) | Reads where the insertion mark is. |
| [SetInsertMark](#setinsertmark) | Places or removes the insertion mark. |
| [GetInsertMarkColor](#getinsertmarkcolor) | Returns the insertion mark's colour. |
| [SetInsertMarkColor](#setinsertmarkcolor) | Sets the insertion mark's colour. |
| [GetInsertMarkRect](#getinsertmarkrect) | Returns the rectangle of the insertion mark. |
| [InsertMarkHitTest](#insertmarkhittest) | Finds the insertion point nearest a point. |
| **Sorting** | |
| [SortItems](#sortitems) | Sorts the items with a function comparing `lParam` values. |
| [SortItemsEx](#sortitemsex) | Sorts the items with a function comparing indexes. |
| [SortGroups](#sortgroups) | Sorts the groups with a function comparing group IDs. |
| **Groups** | |
| [EnableGroupView](#enablegroupview) | Turns group view on or off. |
| [IsGroupViewEnabled](#isgroupviewenabled) | Reads whether group view is on. |
| [InsertGroup](#insertgroup) | Inserts a group. |
| [InsertGroupSorted](#insertgroupsorted) | Inserts a group in sorted order. |
| [RemoveGroup](#removegroup) | Removes a group. |
| [RemoveAllGroups](#removeallgroups) | Removes every group. |
| [HasGroup](#hasgroup) | Reads whether a group ID exists. |
| [GetGroupCount](#getgroupcount) | Returns the number of groups. |
| [GetGroupInfo](#getgroupinfo) | Reads a group's attributes, by ID. |
| [GetGroupInfoByIndex](#getgroupinfobyindex) | Reads a group's attributes, by index. |
| [SetGroupInfo](#setgroupinfo) | Changes a group's attributes. |
| [GetGroupState](#getgroupstate) | Returns state bits of a group. |
| [SetGroupState](#setgroupstate) | Changes state bits of a group. |
| [GetGroupMetrics](#getgroupmetrics) | Reads how groups are drawn. |
| [SetGroupMetrics](#setgroupmetrics) | Sets how groups are drawn. |
| [GetGroupRect](#getgrouprect) | Returns the rectangle of a group or part of it. |
| [GetFocusedGroup](#getfocusedgroup) | Returns the group with the focus. |
| [GetGroupHeaderImageList](#getgroupheaderimagelist) | Returns the group header image list. |
| [SetGroupHeaderImageList](#setgroupheaderimagelist) | Sets the group header image list. |
| **Tiles** | |
| [GetTileInfo](#gettileinfo) | Reads which subitems a tile shows. |
| [SetTileInfo](#settileinfo) | Sets which subitems a tile shows. |
| [GetTileViewInfo](#gettileviewinfo) | Reads the tile view settings. |
| [SetTileViewInfo](#settileviewinfo) | Changes the tile view settings. |
| **Footer** | |
| [GetFooterInfo](#getfooterinfo) | Reads the footer's attributes. |
| [GetFooterItem](#getfooteritem) | Reads a footer item. |
| [GetFooterItemRect](#getfooteritemrect) | Returns the rectangle of a footer item. |
| [GetFooterRect](#getfooterrect) | Returns the rectangle of the footer. |
| **Tooltips** | |
| [GetToolTips](#gettooltips) | Returns the tooltip control. |
| [SetToolTips](#settooltips) | Gives the control another tooltip control. |
| [SetInfoTip](#setinfotip) | Sets an item's tooltip text. |
| [GetTooltipsFont](#gettooltipsfont) | Returns the tooltip control's font. |
| [SetTooltipsFont](#settooltipsfont) | Sets the tooltip control's font. |

## Reference

### AddColumn

```freebasic
function AddColumn( byval hListView as HWND, byval iCol as long, byref wszText as wstring, byval nWidth as long, byval nFormat as long = LVCFMT_LEFT ) as long
```

Inserts a column at position `iCol` with the title `wszText`, `nWidth` pixels wide. In report
view the column shows subitem `iCol` of every item. The leftmost column is always left-aligned,
whatever `nFormat` says.

| Parameter | Meaning |
| --- | --- |
| `hListView` | The list view. |
| `iCol` | Where to insert the column, from 0. A value past the last column appends it. |
| `wszText` | The column title: a literal, a `ustring` or a `wstring`. |
| `nWidth` | The width in pixels. |
| `nFormat` | `LVCFMT_LEFT` (the default), `LVCFMT_RIGHT` or `LVCFMT_CENTER`. |

**Returns** the index of the new column, or -1 on failure.

**Example**

```freebasic
ListView.AddColumn( hCtrl, 0, "Name", 160 )
ListView.AddColumn( hCtrl, 1, "Size", 80, LVCFMT_RIGHT )
```

Microsoft Learn: [LVM_INSERTCOLUMN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-insertcolumn)

### InsertColumn

```freebasic
function InsertColumn overload( byval hListView as HWND, byval iCol as long, byval pcol as LVCOLUMNW ptr ) as long
function InsertColumn overload( byval hListView as HWND, byval iCol as long, byref col as LVCOLUMNW ) as long
function InsertColumn( byval hListView as HWND, byval iCol as long, byref wszText as wstring, byval nWidth as long, byval nFormat as long = LVCFMT_LEFT ) as long
```

The form with a title is the same as [AddColumn](#addcolumn).

The structure forms pass your column structure as it is.

**Returns** the index of the new column, or -1 on failure.

**Example**

```freebasic
dim col as LVCOLUMN
dim szTitle as zstring * 16 = "Date"
col.mask = LVCF_TEXT or LVCF_WIDTH : col.pszText = @szTitle : col.cx = 100
ListView.InsertColumn( hCtrl, 2, col )
```

Microsoft Learn: [LVM_INSERTCOLUMN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-insertcolumn)

### DeleteColumn

```freebasic
function DeleteColumn( byval hListView as HWND, byval iCol as long ) as boolean
```

Removes column `iCol`; the columns after it move left one index.

**Returns** `true` on success.

**Example**

```freebasic
ListView.DeleteColumn( hCtrl, 1 )
```

Microsoft Learn: [LVM_DELETECOLUMN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-deletecolumn)

### GetColumn

```freebasic
function GetColumn overload( byval hListView as HWND, byval iCol as long, byval pcol as LVCOLUMNW ptr ) as boolean
function GetColumn overload( byval hListView as HWND, byval iCol as long, byref col as LVCOLUMNW ) as boolean
```

Reads the attributes of column `iCol` that the structure's `mask` asks for (`LVCF_WIDTH`,
`LVCF_FMT`, `LVCF_TEXT` with a buffer in `pszText` and its size in `cchTextMax` …).

**Returns** `true` on success, or `false`otherwise.

**Example**

```freebasic
dim col as LVCOLUMNW
col.mask = LVCF_WIDTH or LVCF_FMT
if ListView.GetColumn( hCtrl, 1, col ) then print "width"; col.cx
```

Microsoft Learn: [LVM_GETCOLUMN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getcolumn)

### SetColumn

```freebasic
function SetColumn overload( byval hListView as HWND, byval iCol as long, byval pcol as LVCOLUMNW ptr ) as boolean
function SetColumn overload( byval hListView as HWND, byval iCol as long, byref col as LVCOLUMNW ) as boolean
```

Changes the attributes of column `iCol` that the structure's `mask` names.

**Returns** `true` on success.

**Example**

```freebasic
dim col as LVCOLUMNW
col.mask = LVCF_TEXT : col.pszText = @wstr("Size (KB)")
ListView.SetColumn( hCtrl, 1, col )
```

Microsoft Learn: [LVM_SETCOLUMN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setcolumn)

### GetColumnText

```freebasic
function GetColumnText( byval hListView as HWND, byval iCol as long, byval cchTextMax as long = 260 ) as ustring
```

Returns the title of column `iCol`, reading at most `cchTextMax` characters.

**Returns** the title in a buffer-sized `ustring`, or an empty string on failure.

**Example**

```freebasic
dim ustrTitle as ustring = ListView.GetColumnText( hListView, 1 )
print ustrTitle
```

Microsoft Learn: [LVM_GETCOLUMN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getcolumn)

### GetColumnCount

```freebasic
function GetColumnCount( byval hListView as HWND ) as long
```

Returns the number of columns, counted on the header control.

**Returns** the count, or 0 when the control has no header.

**Example**

```freebasic
print "columns:"; ListView.GetColumnCount( hCtrl )
```

Microsoft Learn: [HDM_GETITEMCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getitemcount)

### GetColumnWidth

```freebasic
function GetColumnWidth( byval hListView as HWND, byval iCol as long ) as long
```

Returns the width of column `iCol` in report view. In list view, where all columns are as wide,
`iCol` is ignored.

**Returns** the width in pixels, or 0 on failure.

**Example**

```freebasic
print "width:"; ListView.GetColumnWidth( hCtrl, 0 )
```

Microsoft Learn: [LVM_GETCOLUMNWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getcolumnwidth)

### SetColumnWidth

```freebasic
function SetColumnWidth( byval hListView as HWND, byval iCol as long, byval cx as long ) as boolean
```

Sets the width of column `iCol` in report view, or of every column in list view (pass 0). `cx`
is a width in pixels, or `LVSCW_AUTOSIZE` (fit the widest item) or `LVSCW_AUTOSIZE_USEHEADER`
(fit the title; the last column fills the rest of the control).

**Returns** `true` on success.

**Example**

```freebasic
ListView.SetColumnWidth( hCtrl, 0, 200 )
```

Microsoft Learn: [LVM_SETCOLUMNWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setcolumnwidth)

### FitContent

```freebasic
function FitContent( byval hListView as HWND, byval iCol as long ) as boolean
```

Sizes column `iCol` to its widest item: [SetColumnWidth](#setcolumnwidth) with
`LVSCW_AUTOSIZE`.

**Returns** `true` on success.

**Example**

```freebasic
ListView.FitContent( hCtrl, 0 )
```

Microsoft Learn: [LVM_SETCOLUMNWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setcolumnwidth)

### FitHeader

```freebasic
function FitHeader( byval hListView as HWND, byval iCol as long ) as boolean
```

Sizes column `iCol` to its title: [SetColumnWidth](#setcolumnwidth) with
`LVSCW_AUTOSIZE_USEHEADER`. Used on the last column, it makes that column fill the rest of the
control's width.

**Returns** `true` on success.

**Example**

```freebasic
ListView.FitHeader( hCtrl, ListView.GetColumnCount( hCtrl ) - 1 )
```

Microsoft Learn: [LVM_SETCOLUMNWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setcolumnwidth)

### AutoSizeColumns

```freebasic
function AutoSizeColumns( byval hListView as HWND ) as boolean
```

Calls [FitContent](#fitcontent) on every column.

**Returns** the result for the last column; `false` when there are no columns or no header.

**Example**

```freebasic
ListView.AutoSizeColumns( hCtrl )
```

Microsoft Learn: [LVM_SETCOLUMNWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setcolumnwidth)

### AutoSizeHeader

```freebasic
function AutoSizeHeader( byval hListView as HWND ) as boolean
```

Calls [FitHeader](#fitheader) on every column, so each fits its title and the last fills the
rest of the control.

**Returns** the result for the last column; `false` when there are no columns or no header.

**Example**

```freebasic
ListView.AutoSizeHeader( hCtrl )
```

Microsoft Learn: [LVM_SETCOLUMNWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setcolumnwidth)

### GetColumnOrderArray

```freebasic
function GetColumnOrderArray( byval hListView as HWND, byval iCount as long, byval lpiArray as long ptr ) as long
```

Fills `lpiArray` with the column indexes in the order they appear from left to right. The
user can reorder columns when the control has `LVS_EX_HEADERDRAGDROP`.

| Parameter | Meaning |
| --- | --- |
| `iCount` | The number of columns; the array must hold that many `long`s. |
| `lpiArray` | Receives the indexes. |

**Returns** nonzero on success, 0 on failure.

**Example**

```freebasic
dim order(0 to 1) as long
if ListView.GetColumnOrderArray( hCtrl, 2, @order(0) ) then print "leftmost column:"; order(0)
```

Microsoft Learn: [LVM_GETCOLUMNORDERARRAY](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getcolumnorderarray)

### SetColumnOrderArray

```freebasic
sub SetColumnOrderArray( byval hListView as HWND, byval iCount as long, byval prgi as long ptr )
```

Shows the columns in the order the `iCount` indexes in `prgi` give, from left to right.

**Example**

```freebasic
dim order(0 to 1) as long = { 1, 0 }
ListView.SetColumnOrderArray( hCtrl, 2, @order(0) )
```

Microsoft Learn: [LVM_SETCOLUMNORDERARRAY](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setcolumnorderarray)

### GetColumnOrder

```freebasic
function GetColumnOrder( byval hListView as HWND, byval iCol as long ) as long
```

Returns the position, from the left and from 0, at which column `iCol` is shown. `GetLastError()`
is nonzero afterwards when the header answered.

**Returns** the position, or 0 when the control has no header.

**Example**

```freebasic
print "column 1 is shown at"; ListView.GetColumnOrder( hCtrl, 1 )
```

Microsoft Learn: [HDM_GETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getitem)

### GetOrderArray

```freebasic
function GetOrderArray( byval hListView as HWND, byval iCount as DWORD, byval lpi as long ptr ) as long
```

Reads the left-to-right column order from the header control into `lpi`, which holds `iCount`
`long`s. The result is the same as [GetColumnOrderArray](#getcolumnorderarray).

**Returns** nonzero on success; 0 on failure or when the control has no header.

**Example**

```freebasic
dim order(0 to 1) as long
ListView.GetOrderArray( hCtrl, 2, @order(0) )
```

Microsoft Learn: [HDM_GETORDERARRAY](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getorderarray)

### GetSelectedColumn

```freebasic
function GetSelectedColumn( byval hListView as HWND ) as UINT
```

Returns the column drawn highlighted, as sort-by-column lists do.

**Returns** the column index.

**Example**

```freebasic
print "highlighted column:"; clng( ListView.GetSelectedColumn( hCtrl ) )
```

Microsoft Learn: [LVM_GETSELECTEDCOLUMN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getselectedcolumn)

### SetSelectedColumn

```freebasic
sub SetSelectedColumn( byval hListView as HWND, byval iCol as long )
```

Highlights column `iCol`, typically the one the list is sorted by. -1 removes the highlight.

**Example**

```freebasic
ListView.SetSelectedColumn( hCtrl, 1 )
```

Microsoft Learn: [LVM_SETSELECTEDCOLUMN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setselectedcolumn)

### GetHeader

```freebasic
function GetHeader( byval hListView as HWND ) as HWND
```

Returns the header control that draws the column titles in report view. The functions of
[Header](SysWin-Gui-Header) work on it.

**Returns** the header's handle, or `NULL`.

**Example**

```freebasic
dim hHeader as HWND = ListView.GetHeader( hCtrl )
```

Microsoft Learn: [LVM_GETHEADER](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getheader)

### GetHeaderText

```freebasic
function GetHeaderText( byval hListView as HWND, byval iCol as long, byval cchTextMax as long = MAX_PATH + 1 ) as ustring
```

Returns the title of column `iCol`, read from the header control, at most `cchTextMax`
characters (a value below 1 means `MAX_PATH + 1`). As with [GetColumnText](#getcolumntext) the
`ustring` keeps the buffer's length, `cchTextMax + 1`: cut it at the null character.
`GetLastError()` is nonzero afterwards when the header answered.

**Returns** the title in a buffer-sized `ustring`; an empty string when the control has no
header.

**Example**

```freebasic
dim ustrTitle as ustring = ListView.GetHeaderText( hCtrl, 0 )
ustrTitle = *cast( wstring ptr, strptr( ustrTitle ) )
```

Microsoft Learn: [HDM_GETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/hdm-getitem)

### MakeHeaderFlat

```freebasic
sub MakeHeaderFlat( byval hListView as HWND )
```

Removes the header's `HDS_BUTTONS` style: a header with button-like titles becomes flat. It then asks the list view's parent
to redraw its frame.

**Example**

```freebasic
ListView.MakeHeaderFlat( hCtrl )
```

Microsoft Learn: [Header control styles](https://learn.microsoft.com/en-us/windows/win32/controls/header-control-styles)

### SetHeaderFont

```freebasic
function SetHeaderFont( byval hListView as HWND, byref wszFaceName as wstring, byval lPointSize as long, byval lWeight as long, byval bItalic as byte, byval bUnderline as byte, byval bStrikeOut as byte, byval bCharSet as byte ) as HFONT
```

Creates a font from the values given and gives it to the header control, which redraws. The
point size is converted to pixels with the desktop's DPI.

The font is yours: delete it with `DeleteObject` once the header no longer uses it (after the
control is destroyed, or after giving it another font). The header's previous font is not
deleted.

| Parameter | Meaning |
| --- | --- |
| `wszFaceName` | The typeface, such as `"Segoe UI"`. |
| `lPointSize` | The size in points. |
| `lWeight` | `FW_NORMAL`, `FW_BOLD` or another weight from 0 to 1000. |
| `bItalic`, `bUnderline`, `bStrikeOut` | Nonzero for italic, underlined or struck-out text. |
| `bCharSet` | The character set, usually `DEFAULT_CHARSET`. |

**Returns** the new font, or `NULL` when the control has no header or the font cannot be
created.

**Example**

```freebasic
dim hFont as HFONT = ListView.SetHeaderFont( hCtrl, "Segoe UI", 10, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET )
```

Microsoft Learn: [CreateFontIndirectW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createfontindirectw)

### ModifyHeaderFont

```freebasic
function ModifyHeaderFont( byval hListView as HWND, byref wszFaceName as wstring, byval lPointSize as long, byval lWeight as long, byval bItalic as byte, byval bUnderline as byte, byval bStrikeOut as byte, byval bCharSet as byte ) as HFONT
```

Reads the header's current font, changes the values you pass that are not empty or zero,
creates a font from the result and gives it to the header. Since zero means "leave as it is",
it can turn italic, underline or strikeout on but not off. The header must have a font of its
own; for a header that draws with the system font it returns `NULL`.

As with [SetHeaderFont](#setheaderfont), the new font is yours to delete with `DeleteObject`, and
the old one is not deleted.

**Returns** the new font, or `NULL`.

**Example**

```freebasic
dim hFont as HFONT = ListView.ModifyHeaderFont( hCtrl, "", 0, FW_BOLD, 0, 0, 0, 0 )   ' bold, the rest as it was
```

Microsoft Learn: [WM_GETFONT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-getfont)

### AddItem

```freebasic
function AddItem( byval hListView as HWND, byval iItem as long, byval iImage as long, byref wszText as wstring ) as long
```

Inserts an item with the text `wszText` at index `iItem`. An index past the end appends the item;
the return value is the index it got. The item's other columns are empty until
[SetItemText](#setitemtext) fills them.

| Parameter | Meaning |
| --- | --- |
| `iItem` | Where to insert the item, from 0. |
| `iImage` | Not applied (see above). |
| `wszText` | The item's text: a literal, a `ustring` or a `wstring`. |

**Returns** the index of the new item, or -1 on failure.

**Example**

```freebasic
dim i as long = ListView.AddItem( hCtrl, 0, 0, "Mercury" )
ListView.SetItemText( hCtrl, i, 1, wstr("0 moons") )
```

Microsoft Learn: [LVM_INSERTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-insertitem)

### InsertItem

```freebasic
function InsertItem overload( byval hListView as HWND, byval pitem as LVITEMW ptr ) as long
function InsertItem overload( byval hListView as HWND, byref item as LVITEMW ) as long
function InsertItem( byval hListView as HWND, byval iItem as long, byval iImage as long, byref wszText as wstring ) as long
```

The form with a text is the same as [AddItem](#additem), `iImage` included. The structure forms
send your `LVITEMW` as it is, with the Unicode message: set `mask`, `iItem` and the members
`mask` names. They return -1 at once for a null structure.

**Returns** the index of the new item, or -1 on failure.

**Example**

```freebasic
dim lvi as LVITEMW
lvi.mask = LVIF_TEXT or LVIF_IMAGE or LVIF_PARAM
lvi.iItem = 0 : lvi.pszText = @wstr("Venus") : lvi.iImage = 1 : lvi.lParam = 2
ListView.InsertItem( hCtrl, lvi )
```

Microsoft Learn: [LVM_INSERTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-insertitem)

### AppendItem

```freebasic
function AppendItem( byval hListView as HWND, byval iImage as long, byval pwszText as wstring ptr ) as long
```

Adds an item with the text `pwszText` after the last one.

**Returns** the index of the new item, or -1 on failure.

**Example**

```freebasic
ListView.AppendItem( hCtrl, 0, "Earth" )
```

Microsoft Learn: [LVM_INSERTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-insertitem)

### DeleteItem

```freebasic
function DeleteItem( byval hListView as HWND, byval i as long ) as boolean
```

Removes item `i`; the items after it move up one index. The parent receives `LVN_DELETEITEM`.

**Returns** `true` on success.

**Example**

```freebasic
dim iSel as long = ListView.GetSelection( hCtrl )
if iSel >= 0 then ListView.DeleteItem( hCtrl, iSel )
```

Microsoft Learn: [LVM_DELETEITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-deleteitem)

### DeleteAllItems

```freebasic
function DeleteAllItems( byval hListView as HWND ) as boolean
```

Removes every item. The columns stay.

**Returns** `true` on success.

**Example**

```freebasic
ListView.DeleteAllItems( hCtrl )
```

Microsoft Learn: [LVM_DELETEALLITEMS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-deleteallitems)

### GetItem

```freebasic
function GetItem overload( byval hListView as HWND, byval pitem as LVITEMW ptr ) as boolean
function GetItem overload( byval hListView as HWND, byref item as LVITEMW ) as boolean
```

Reads the attributes of an item or subitem that the structure's `mask` asks for: set `iItem`,
`iSubItem` and `mask` first.

Both forms send the ANSI message, although they take an `LVITEMW`. State, image, indent,
`lParam` and group come back correctly; text comes back as 8-bit characters in the `pszText`
buffer. Read text with [GetItemText](#getitemtext).

**Returns** `true` on success.

**Example**

```freebasic
dim lvi as LVITEMW
lvi.mask = LVIF_PARAM or LVIF_STATE : lvi.iItem = 0 : lvi.stateMask = LVIS_SELECTED
if ListView.GetItem( hCtrl, lvi ) then print "lParam"; lvi.lParam
```

Microsoft Learn: [LVM_GETITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitem)

### GetItemCount

```freebasic
function GetItemCount( byval hListView as HWND ) as long
```

**Returns** the number of items.

**Example**

```freebasic
print "items:"; ListView.GetItemCount( hCtrl )
```

Microsoft Learn: [LVM_GETITEMCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemcount)

### SetItemCount

```freebasic
function SetItemCount( byval hListView as HWND, byval cItems as long ) as LRESULT
```

For an ordinary list view, reserves memory for `cItems` items before adding many of them; the
item count does not change. For a virtual list view (`LVS_OWNERDATA`) it sets the number of
items.

**Returns** nonzero on success.

**Example**

```freebasic
ListView.SetItemCount( hCtrl, 10000 )
```

Microsoft Learn: [LVM_SETITEMCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemcount)

### SetItemCountEx

```freebasic
function SetItemCountEx( byval hListView as HWND, byval cItems as long, byval dwFlags as long ) as LRESULT
```

Sets the number of items of a virtual list view, with `dwFlags` saying how to redraw:
`LVSICF_NOINVALIDATEALL` repaints only items that changed, `LVSICF_NOSCROLL` keeps the scroll
position.

**Returns** nonzero on success.

**Example**

```freebasic
ListView.SetItemCountEx( hCtrl, 5000, LVSICF_NOINVALIDATEALL or LVSICF_NOSCROLL )
```

Microsoft Learn: [LVM_SETITEMCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemcount)

### GetItemState

```freebasic
function GetItemState( byval hListView as HWND, byval i as long, byval mask as long ) as UINT
```

Returns the state bits of item `i` that `mask` selects: `LVIS_SELECTED`, `LVIS_FOCUSED`,
`LVIS_CUT`, `LVIS_DROPHILITED`, `LVIS_OVERLAYMASK`, `LVIS_STATEIMAGEMASK`.

**Returns** the state bits.

**Example**

```freebasic
if ListView.GetItemState( hCtrl, 0, LVIS_SELECTED ) then print "item 0 is selected"
```

Microsoft Learn: [LVM_GETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemstate)

### SetItemState

```freebasic
sub SetItemState( byval hListView as HWND, byval i as long, byval dwState as DWORD, byval mask as DWORD )
```

Sets the state bits of item `i` that `mask` selects to the values in `dwState`. `i` = -1
changes every item.

**Example**

```freebasic
ListView.SetItemState( hCtrl, 2, LVIS_CUT, LVIS_CUT )   ' draw item 2 as cut
```

Microsoft Learn: [LVM_SETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemstate)

### Update

```freebasic
function Update( byval hListView as HWND, byval iItem as long ) as boolean
```

Redraws item `iItem`; with `LVS_AUTOARRANGE`, also rearranges the control.

**Returns** `true` on success.

**Example**

```freebasic
ListView.Update( hCtrl, 0 )
```

Microsoft Learn: [LVM_UPDATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-update)

### RedrawItems

```freebasic
function RedrawItems( byval hListView as HWND, byval iFirst as long, byval iLast as long ) as boolean
```

Marks items `iFirst` to `iLast` for repainting; they are drawn at the next `WM_PAINT`. Call
`UpdateWindow` to paint them at once.

**Returns** `true` on success.

**Example**

```freebasic
ListView.RedrawItems( hCtrl, 0, 9 )
UpdateWindow( hCtrl )
```

Microsoft Learn: [LVM_REDRAWITEMS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-redrawitems)

### MapIndexToID

```freebasic
function MapIndexToID( byval hListView as HWND, byval index as UINT ) as UINT
```

Returns the unique ID of the item at `index`. Unlike the index, the ID does not change when
items are inserted, deleted or sorted. Needs visual styles.

**Returns** the ID.

**Example**

```freebasic
dim id as UINT = ListView.MapIndexToID( hCtrl, 2 )
```

Microsoft Learn: [LVM_MAPINDEXTOID](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-mapindextoid)

### MapIDToIndex

```freebasic
function MapIDToIndex( byval hListView as HWND, byval id as UINT ) as UINT
```

Returns the current index of the item with the unique ID `id`. Needs visual styles.

**Returns** the index.

**Example**

```freebasic
dim id as UINT = ListView.MapIndexToID( hCtrl, 2 )
ListView.DeleteItem( hCtrl, 0 )   ' the items after it move up
print "now at"; ListView.MapIDToIndex( hCtrl, id )
```

Microsoft Learn: [LVM_MAPIDTOINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-mapidtoindex)

### GetCallbackMask

```freebasic
function GetCallbackMask( byval hListView as HWND ) as UINT
```

Returns the `LVIS_*` state bits that the application keeps itself and supplies through
`LVN_GETDISPINFO`, instead of the control storing them.

**Returns** the mask.

**Example**

```freebasic
print "callback mask:"; ListView.GetCallbackMask( hCtrl )
```

Microsoft Learn: [LVM_GETCALLBACKMASK](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getcallbackmask)

### SetCallbackMask

```freebasic
function SetCallbackMask( byval hListView as HWND, byval mask as DWORD ) as boolean
```

Sets the `LVIS_*` state bits that the application keeps itself.

**Returns** `true` on success.

**Example**

```freebasic
ListView.SetCallbackMask( hCtrl, LVIS_SELECTED or LVIS_FOCUSED )
```

Microsoft Learn: [LVM_SETCALLBACKMASK](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setcallbackmask)

### GetItemText

```freebasic
sub GetItemText( byval hListView as HWND, byval i as long, byval iSubItem as long, byval pwszText as wstring ptr, byval cchTextMax as long = 260 )
function GetItemText( byval hListView as HWND, byval i as long, byval iSubItem as long, byval cchTextMax as long = 260 ) as ustring
```

Copies the text of subitem `iSubItem` of item `i` into `pwszText`, at most `cchTextMax`
characters including the terminating null.

| Parameter | Meaning |
| --- | --- |
| `i` | The zero-based item. |
| `iSubItem` | The zerp-based subitem (column). |
| `pwszText` | The buffer that receives the text. |
| `cchTextMax` | The size of the buffer in characters. The default assumes 260: pass the real size of a smaller buffer. |

**Examples**

```freebasic
dim wszText as wstring * 260
ListView.GetItemText( hListView, 3, 1, @wszText, 260 )
dim ustrText as ustring = wszText
```
```freebasic
print ListView.GetItemText( hListView, 0, 1 )   ' column 1 of the first row
```

Microsoft Learn: [LVM_GETITEMTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemtext)

### SetItemText

```freebasic
function SetItemText( byval hListView as HWND, byval i as long, byval iSubItem as long, byref pwszText as wstring ptr ) as boolean
```

Sets the text of subitem `iSubItem` of item `i`.

`pwszText` is taken by reference as a `wstring ptr`. Pass a `ustring`, a wide literal written
`wstr("...")` or the address of a `wstring` buffer.

**Returns** `true` on success.

**Example**

```freebasic
dim ustrSize as ustring = "12 KB"
ListView.SetItemText( hCtrl, 0, 1, ustrSize )
ListView.SetItemText( hCtrl, 0, 2, wstr("rocky") )
```

Microsoft Learn: [LVM_SETITEMTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemtext)

### GetStringWidth

```freebasic
function GetStringWidth( byval hListView as HWND, byref wszText as wstring ) as long
```

Measures `wszText` in the control's current font. Add some padding when you size a column
with it: the control leaves a margin around item text.

**Returns** the width in pixels, or 0 on failure.

**Example**

```freebasic
print "width:"; ListView.GetStringWidth( hCtrl, "Jupiter" )
```

Microsoft Learn: [LVM_GETSTRINGWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getstringwidth)

### EditLabel

```freebasic
function EditLabel( byval hListView as HWND, byval i as long ) as HWND
```

Starts in-place editing of the text of item `i`, which is selected and focused. The control
must have the focus and the `LVS_EDITLABELS` style. Pass -1 to stop editing. The parent
receives `LVN_BEGINLABELEDIT` and, when editing ends, `LVN_ENDLABELEDIT`.

**Returns** the edit control's handle, or `NULL` on failure.

**Example**

```freebasic
SetFocus( hCtrl )
dim hEdit as HWND = ListView.EditLabel( hCtrl, 0 )
```

Microsoft Learn: [LVM_EDITLABEL](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-editlabel)

### CancelEditLabel

```freebasic
sub CancelEditLabel( byval hListView as HWND )
```

Cancels in-place editing; the item keeps its old text.

**Example**

```freebasic
ListView.CancelEditLabel( hCtrl )
```

Microsoft Learn: [LVM_CANCELEDITLABEL](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-canceleditlabel)

### GetEditControl

```freebasic
function GetEditControl( byval hListView as HWND ) as HWND
```

Returns the edit control used while the user edits an item's text, for example to limit its
length in `LVN_BEGINLABELEDIT`.

**Returns** the edit control's handle, or `NULL` when no item is being edited.

**Example**

```freebasic
dim hEdit as HWND = ListView.GetEditControl( hCtrl )
if hEdit then SendMessageW( hEdit, EM_LIMITTEXT, 32, 0 )
```

Microsoft Learn: [LVM_GETEDITCONTROL](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-geteditcontrol)

### GetEmptyText

```freebasic
function GetEmptyText( byval hListView as HWND, byval pwszText as wstring ptr, byval cchText as DWORD ) as boolean
```

Copies into `pwszText`, at most `cchText` characters, the text the control shows when it has
no items.

**Returns** `true` when there is such a text.

**Example**

```freebasic
dim wszEmpty as wstring * 128
if ListView.GetEmptyText( hCtrl, @wszEmpty, 128 ) then print "has an empty-list text"
```

Microsoft Learn: [LVM_GETEMPTYTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getemptytext)

### FindItem

```freebasic
function FindItem overload( byval hListView as HWND, byval iStart as long, byval pvfi as LVFINDINFOW ptr ) as long
function FindItem overload( byval hListView as HWND, byval iStart as long, byref vfi as LVFINDINFOW ) as long
```

Searches for an item matching the `LVFINDINFOW` structure: by text (`LVFI_STRING`, with
`LVFI_PARTIAL` for a prefix), by `lParam` (`LVFI_PARAM`) or by position (`LVFI_NEARESTXY`).
The search starts after item `iStart`; -1 searches from the beginning. `LVFI_WRAP` continues
from the top.

**Returns** the index of the item found, or -1.

**Example**

```freebasic
dim lvfi as LVFINDINFOW
lvfi.flags = LVFI_PARAM : lvfi.lParam = 42
print "item with lParam 42:"; ListView.FindItem( hCtrl, -1, lvfi )
```

Microsoft Learn: [LVM_FINDITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-finditem)

### FindString

```freebasic
function FindString( byval hListView as HWND, byval pwszText as wstring ptr ) as long
```

Returns the first item whose text starts with `pwszText`, ignoring case, searching from the
first item. `"on"` finds `"One"`.

**Returns** the index of the item, or -1.

**Example**

```freebasic
dim i as long = ListView.FindString( hCtrl, "Ear" )
if i >= 0 then ListView.SelectItem( hCtrl, i )
```

Microsoft Learn: [LVM_FINDITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-finditem)

### GetNextItem

```freebasic
function GetNextItem( byval hListView as HWND, byval iStart as long, byval flags as UINT ) as long
```

Searches from item `iStart` for an item with the properties in `flags`: a state
(`LVNI_SELECTED`, `LVNI_FOCUSED`, `LVNI_CUT`, `LVNI_DROPHILITED`) and/or a direction
(`LVNI_ABOVE`, `LVNI_BELOW`, `LVNI_TOLEFT`, `LVNI_TORIGHT`). `LVNI_ALL` searches by index.
`iStart` = -1 starts before the first item.

**Returns** the index of the item found, or -1.

**Example**

```freebasic
dim i as long = ListView.GetNextItem( hCtrl, -1, LVNI_SELECTED )
do while i >= 0
    print "selected:"; i
    i = ListView.GetNextItem( hCtrl, i, LVNI_SELECTED )
loop
```

Microsoft Learn: [LVM_GETNEXTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getnextitem)

### GetNextItemIndex

```freebasic
function GetNextItemIndex overload( byval hListView as HWND, byval plvii as LVITEMINDEX ptr, byval flags as ..LPARAM ) as long
function GetNextItemIndex overload( byval hListView as HWND, byref lvii as LVITEMINDEX, byval flags as ..LPARAM ) as long
```

Like [GetNextItem](#getnextitem), but the start and the result are an `LVITEMINDEX` (item and
group), so it can walk items in group order. `lvii` is updated to the item found. Needs visual
styles.

**Returns** nonzero when an item was found.

**Example**

```freebasic
dim lvii as LVITEMINDEX
lvii.iItem = -1 : lvii.iGroup = 0
if ListView.GetNextItemIndex( hCtrl, lvii, LVNI_SELECTED ) then print "item"; lvii.iItem
```

Microsoft Learn: [LVM_GETNEXTITEMINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getnextitemindex)

### GetISearchString

```freebasic
function GetISearchString( byval hListView as HWND ) as ustring
```

Returns the incremental search text: the characters the user has typed in quick succession to
jump to an item.

**Returns** the text, or an empty string when the user is not searching.

**Example**

```freebasic
print "typed so far: "; ListView.GetISearchString( hCtrl )
```

Microsoft Learn: [LVM_GETISEARCHSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getisearchstring)

### GetISearchStringLen

```freebasic
function GetISearchStringLen( byval hListView as HWND ) as long
```

**Returns** the length of the incremental search text, or 0 when the user is not searching.

**Example**

```freebasic
if ListView.GetISearchStringLen( hCtrl ) then print "the user is typing a search"
```

Microsoft Learn: [LVM_GETISEARCHSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getisearchstring)

### GetSelection

```freebasic
function GetSelection( byval hListView as HWND ) as long
```

Returns the first selected item. In a multiple-selection list use
[GetNextItem](#getnextitem) with `LVNI_SELECTED` to visit the others.

**Returns** the index, or -1 when nothing is selected.

**Example**

```freebasic
dim iSel as long = ListView.GetSelection( hCtrl )
```

Microsoft Learn: [LVM_GETNEXTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getnextitem)

### GetFocusedItem

```freebasic
function GetFocusedItem( byval hListView as HWND ) as long
```

Returns the item with the focus rectangle, which may or may not be selected.

**Returns** the index, or -1.

**Example**

```freebasic
print "focused item:"; ListView.GetFocusedItem( hCtrl )
```

Microsoft Learn: [LVM_GETNEXTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getnextitem)

### GetSelectedCount

```freebasic
function GetSelectedCount( byval hListView as HWND ) as UINT
```

**Returns** the number of selected items.

**Example**

```freebasic
print ListView.GetSelectedCount( hCtrl ); " selected"
```

Microsoft Learn: [LVM_GETSELECTEDCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getselectedcount)

### SelectItem

```freebasic
function SelectItem( byval hListView as HWND, byval iIndex as long ) as boolean
```

Selects item `iIndex` and gives it the focus; it also clears its cut and drop-highlight states.
Other selected items stay selected in a multiple-selection list. The item is not scrolled into
view: call [EnsureVisible](#ensurevisible) for that.

**Returns** `true` on success.

**Example**

```freebasic
ListView.SelectItem( hCtrl, 0 )
ListView.EnsureVisible( hCtrl, 0, false )
```

Microsoft Learn: [LVM_SETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemstate)

### SelectAllItems

```freebasic
function SelectAllItems( byval hListView as HWND ) as boolean
```

Selects every item. A list with `LVS_SINGLESEL` allows only one selected item.

**Returns** `true` on success.

**Example**

```freebasic
ListView.SelectAllItems( hCtrl )
```

Microsoft Learn: [LVM_SETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemstate)

### UnselectItem

```freebasic
function UnselectItem( byval hListView as HWND, byval iIndex as long ) as boolean
```

Deselects item `iIndex`; its focus is left as it is.

**Returns** `true` on success.

**Example**

```freebasic
ListView.UnselectItem( hCtrl, 0 )
```

Microsoft Learn: [LVM_SETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemstate)

### UnselectAllItems

```freebasic
function UnselectAllItems( byval hListView as HWND ) as boolean
```

Deselects every item and takes the focus rectangle away, so [GetFocusedItem](#getfocuseditem)
returns -1 afterwards.

**Returns** `true` on success.

**Example**

```freebasic
ListView.UnselectAllItems( hCtrl )
```

Microsoft Learn: [LVM_SETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemstate)

### GetSelectionMark

```freebasic
function GetSelectionMark( byval hListView as HWND ) as long
```

Returns the selection mark: the item a Shift+click range selection starts from.

**Returns** the index, or -1 when there is none.

**Example**

```freebasic
print "selection mark:"; ListView.GetSelectionMark( hCtrl )
```

Microsoft Learn: [LVM_GETSELECTIONMARK](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getselectionmark)

### SetSelectionMark

```freebasic
function SetSelectionMark( byval hListView as HWND, byval iIndex as long ) as long
```

Makes item `iIndex` the selection mark.

**Returns** the previous selection mark, or -1.

**Example**

```freebasic
ListView.SetSelectionMark( hCtrl, 0 )
```

Microsoft Learn: [LVM_SETSELECTIONMARK](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setselectionmark)

### SetItemIndexState

```freebasic
function SetItemIndexState overload( byval hListView as HWND, byval plvii as LVITEMINDEX ptr, byval dwData as UINT, byval mask as UINT ) as HRESULT
function SetItemIndexState overload( byval hListView as HWND, byref lvii as LVITEMINDEX, byval dwData as UINT, byval mask as UINT ) as HRESULT
```

Sets the state bits that `mask` selects to the values in `dwData`, for the item that an
`LVITEMINDEX` (item and group) names. Needs visual styles.

**Returns** `S_OK` on success, otherwise an error `HRESULT`.

**Example**

```freebasic
dim lvii as LVITEMINDEX
lvii.iItem = 0 : lvii.iGroup = 0
ListView.SetItemIndexState( hCtrl, lvii, LVIS_SELECTED, LVIS_SELECTED )
```

Microsoft Learn: [LVM_SETITEMINDEXSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemindexstate)

### GetHotItem

```freebasic
function GetHotItem( byval hListView as HWND ) as long
```

Returns the hot item: the one under the pointer when hot tracking (`LVS_EX_TRACKSELECT`,
`LVS_EX_ONECLICKACTIVATE` or `LVS_EX_TWOCLICKACTIVATE`) is on.

**Returns** the index, or -1.

**Example**

```freebasic
print "hot item:"; ListView.GetHotItem( hCtrl )
```

Microsoft Learn: [LVM_GETHOTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gethotitem)

### SetHotItem

```freebasic
function SetHotItem( byval hListView as HWND, byval iIndex as DWORD ) as long
```

Makes item `iIndex` the hot item.

**Returns** the previous hot item.

**Example**

```freebasic
ListView.SetHotItem( hCtrl, 1 )
```

Microsoft Learn: [LVM_SETHOTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-sethotitem)

### GetHotCursor

```freebasic
function GetHotCursor( byval hListView as HWND ) as HCURSOR
```

**Returns** the cursor shown while the pointer is over an item with hot tracking on.

**Example**

```freebasic
dim hCur as HCURSOR = ListView.GetHotCursor( hCtrl )
```

Microsoft Learn: [LVM_GETHOTCURSOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gethotcursor)

### SetHotCursor

```freebasic
function SetHotCursor( byval hListView as HWND, byval hCur as HCURSOR ) as HCURSOR
```

Sets the cursor shown while the pointer is over an item with hot tracking on.

**Returns** the previous cursor.

**Example**

```freebasic
ListView.SetHotCursor( hCtrl, LoadCursorW( NULL, IDC_HAND ) )
```

Microsoft Learn: [LVM_SETHOTCURSOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-sethotcursor)

### GetHoverTime

```freebasic
function GetHoverTime( byval hListView as HWND ) as DWORD
```

Returns how long, in milliseconds, the pointer must rest on an item before it is selected with
`LVS_EX_TRACKSELECT`.

**Returns** the time; `&hFFFFFFFF` (-1) for the system default.

**Example**

```freebasic
print "hover time:"; clng( ListView.GetHoverTime( hCtrl ) )
```

Microsoft Learn: [LVM_GETHOVERTIME](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gethovertime)

### SetHoverTime

```freebasic
sub SetHoverTime( byval hListView as HWND, byval dwHoverTimeMs as DWORD )
```

Sets the hover time in milliseconds; -1 restores the system default.

**Example**

```freebasic
ListView.SetHoverTime( hCtrl, 800 )
```

Microsoft Learn: [LVM_SETHOVERTIME](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-sethovertime)

### GetCheckState

```freebasic
function GetCheckState( byval hListView as HWND, byval i as long ) as UINT
```

Reads the check box of item `i` in a list view with `LVS_EX_CHECKBOXES`. The value is not a
boolean, and both results are nonzero:

| Check box | Returns |
| --- | --- |
| checked | `&hFFFFFFFF` (-1 as a `long`) |
| unchecked | `&hFFFFFFFE` (-2 as a `long`) |

An item with no check box at all (no `LVS_EX_CHECKBOXES`) also returns `&hFFFFFFFF`. Compare
with `&hFFFFFFFF`; never test the result for truth.

**Returns** `&hFFFFFFFF` when checked, `&hFFFFFFFE` when unchecked.

**Example**

```freebasic
if ListView.GetCheckState( hCtrl, 0 ) = &hFFFFFFFF then print "item 0 is checked"
```

Microsoft Learn: [LVM_GETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemstate)

### SetCheckState

```freebasic
sub SetCheckState( byval hListView as HWND, byval iIndex as long, byval fCheck as boolean )
```

Checks (`fCheck` = `true`) or unchecks the check box of item `iIndex`, by setting its state
image to 2 or 1. The control needs `LVS_EX_CHECKBOXES`. `iIndex` = -1 changes every item.

**Example**

```freebasic
ListView.SetExtendedStyleEx( hCtrl, LVS_EX_CHECKBOXES, LVS_EX_CHECKBOXES )
ListView.SetCheckState( hCtrl, 0, true )
```

Microsoft Learn: [LVM_SETITEMSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemstate)

### GetExtendedStyle

```freebasic
function GetExtendedStyle( byval hListView as HWND ) as DWORD
```

**Returns** the control's `LVS_EX_*` extended styles. They are not window styles:
`GetWindowLong` does not show them.

**Example**

```freebasic
if ListView.GetExtendedStyle( hCtrl ) and LVS_EX_GRIDLINES then print "grid lines on"
```

Microsoft Learn: [LVM_GETEXTENDEDLISTVIEWSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getextendedlistviewstyle)

### SetExtendedStyle

```freebasic
sub SetExtendedStyle( byval hListView as HWND, byval dwExStyle as DWORD )
```

Replaces all the `LVS_EX_*` extended styles with `dwExStyle`; styles not in it are turned off.
To add one, combine it with [GetExtendedStyle](#getextendedstyle) or use
[SetExtendedStyleEx](#setextendedstyleex).

**Example**

```freebasic
ListView.SetExtendedStyle( hCtrl, ListView.GetExtendedStyle( hCtrl ) or LVS_EX_FULLROWSELECT )
```

Microsoft Learn: [LVM_SETEXTENDEDLISTVIEWSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setextendedlistviewstyle)

### SetExtendedStyleEx

```freebasic
sub SetExtendedStyleEx( byval hListView as HWND, byval dwExMask as DWORD, byval dwExStyle as DWORD )
```

Changes only the extended styles in `dwExMask`, turning each on or off as `dwExStyle` says.

**Example**

```freebasic
ListView.SetExtendedStyleEx( hCtrl, LVS_EX_GRIDLINES, 0 )   ' grid lines off, the rest unchanged
```

Microsoft Learn: [LVM_SETEXTENDEDLISTVIEWSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setextendedlistviewstyle)

### GetView

```freebasic
function GetView( byval hListView as HWND ) as DWORD
```

Returns the current view: `LV_VIEW_ICON`, `LV_VIEW_SMALLICON`, `LV_VIEW_LIST`,
`LV_VIEW_DETAILS` (report) or `LV_VIEW_TILE`. Needs visual styles; without them it returns 0
whatever the view.

**Returns** the view.

**Example**

```freebasic
if ListView.GetView( hCtrl ) = LV_VIEW_DETAILS then print "report view"
```

Microsoft Learn: [LVM_GETVIEW](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getview)

### SetView

```freebasic
function SetView( byval hListView as HWND, byval iView as DWORD ) as long
```

Switches to view `iView` (`LV_VIEW_*`). This is the only way into tile view. Needs visual
styles.

**Returns** 1 on success, -1 on failure.

**Example**

```freebasic
ListView.SetView( hCtrl, LV_VIEW_TILE )
```

Microsoft Learn: [LVM_SETVIEW](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setview)

### SetDarkMode

```freebasic
function SetDarkMode( byval hListView as HWND ) as HRESULT
```

Gives the control the `DarkMode_Explorer` visual theme, which draws its scroll bars and
selection in dark colours. The background and text colours are not changed: set them with
[SetBkColor](#setbkcolor), [SetTextColor](#settextcolor) and
[SetTextBkColor](#settextbkcolor).

**Returns** `S_OK` on success, otherwise an error `HRESULT`.

**Example**

```freebasic
ListView.SetDarkMode( hCtrl )
ListView.SetBkColor( hCtrl, BGR( 32, 32, 32 ) )
ListView.SetTextBkColor( hCtrl, BGR( 32, 32, 32 ) )
ListView.SetTextColor( hCtrl, BGR( 230, 230, 230 ) )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

### RemoveDarkMode

```freebasic
function RemoveDarkMode( byval hListView as HWND ) as HRESULT
```

Restores the control's default visual theme.

**Returns** `S_OK` on success, otherwise an error `HRESULT`.

**Example**

```freebasic
ListView.RemoveDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

### GetBkColor

```freebasic
function GetBkColor( byval hListView as HWND ) as COLORREF
```

**Returns** the background colour, or `CLR_NONE` when the control has no background colour.

**Example**

```freebasic
print "background: &h"; hex( ListView.GetBkColor( hCtrl ), 6 )
```

Microsoft Learn: [LVM_GETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getbkcolor)

### SetBkColor

```freebasic
function SetBkColor( byval hListView as HWND, byval clrBk as COLORREF ) as boolean
```

Sets the background colour; `CLR_NONE` gives no background, for a background image.

**Returns** `true` on success.

**Example**

```freebasic
ListView.SetBkColor( hCtrl, BGR( 255, 255, 224 ) )
```

Microsoft Learn: [LVM_SETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setbkcolor)

### GetTextColor

```freebasic
function GetTextColor( byval hListView as HWND ) as COLORREF
```

**Returns** the text colour.

**Example**

```freebasic
dim clr as COLORREF = ListView.GetTextColor( hCtrl )
```

Microsoft Learn: [LVM_GETTEXTCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gettextcolor)

### SetTextColor

```freebasic
function SetTextColor( byval hListView as HWND, byval clrText as COLORREF ) as boolean
```

Sets the text colour.

**Returns** `true` on success.

**Example**

```freebasic
ListView.SetTextColor( hCtrl, BGR( 0, 0, 128 ) )
```

Microsoft Learn: [LVM_SETTEXTCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-settextcolor)

### GetTextBkColor

```freebasic
function GetTextBkColor( byval hListView as HWND ) as COLORREF
```

**Returns** the colour behind item text.

**Example**

```freebasic
dim clr as COLORREF = ListView.GetTextBkColor( hCtrl )
```

Microsoft Learn: [LVM_GETTEXTBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gettextbkcolor)

### SetTextBkColor

```freebasic
function SetTextBkColor( byval hListView as HWND, byval clrTextBk as COLORREF ) as boolean
```

Sets the colour behind item text; `CLR_NONE` makes it transparent.

**Returns** `true` on success.

**Example**

```freebasic
ListView.SetTextBkColor( hCtrl, CLR_NONE )
```

Microsoft Learn: [LVM_SETTEXTBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-settextbkcolor)

### GetOutlineColor

```freebasic
function GetOutlineColor( byval hListView as HWND ) as COLORREF
```

**Returns** the colour of the border drawn around a selected item with `LVS_EX_BORDERSELECT`.

**Example**

```freebasic
dim clr as COLORREF = ListView.GetOutlineColor( hCtrl )
```

Microsoft Learn: [LVM_GETOUTLINECOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getoutlinecolor)

### SetOutlineColor

```freebasic
function SetOutlineColor( byval hListView as HWND, byval clr as COLORREF ) as COLORREF
```

Sets the colour of the `LVS_EX_BORDERSELECT` border.

**Returns** the previous colour.

**Example**

```freebasic
ListView.SetOutlineColor( hCtrl, BGR( 255, 0, 0 ) )
```

Microsoft Learn: [LVM_SETOUTLINECOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setoutlinecolor)

### GetBkImage

```freebasic
function GetBkImage overload( byval hListView as HWND, byval pvbki as LVBKIMAGEW ptr ) as boolean
function GetBkImage overload( byval hListView as HWND, byref vbki as LVBKIMAGEW ) as boolean
function GetBkImage overload( byval hListView as HWND ) as LVBKIMAGEW
```

Reads the background image into an `LVBKIMAGEW`. The forms that take a structure send the ANSI
message, so a URL or file name comes back in 8-bit characters; the form that returns the
structure sends the Unicode one. `ulFlags` says what kind of image is set.

**Returns** `true` on success, or the structure.

**Example**

```freebasic
dim bki as LVBKIMAGEW = ListView.GetBkImage( hCtrl )
if ( bki.ulFlags and LVBKIF_SOURCE_MASK ) = LVBKIF_SOURCE_NONE then print "no background image"
```

Microsoft Learn: [LVM_GETBKIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getbkimage)

### SetBkImage

```freebasic
function SetBkImage overload( byval hListView as HWND, byval pvbki as LVBKIMAGEW ptr ) as boolean
function SetBkImage overload( byval hListView as HWND, byref vbki as LVBKIMAGEW ) as boolean
```

Sets or removes the background image, from a bitmap (`LVBKIF_SOURCE_HBITMAP`) or from a file or
URL. Set the background colour to `CLR_NONE` for the image to show.

**Returns** `true` on success.

**Example**

```freebasic
dim bki as LVBKIMAGE
dim hbmp as HBITMAP = cast( HBITMAP, LoadImageW( NULL, "back.bmp", IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE ) )
bki.ulFlags = LVBKIF_SOURCE_HBITMAP or LVBKIF_STYLE_TILE : bki.hbm = hbmp
ListView.SetBkImage( hCtrl, bki )
```

Microsoft Learn: [LVM_SETBKIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setbkimage)

### GetImageList

```freebasic
function GetImageList( byval hListView as HWND, byval iImageList as long ) as HIMAGELIST
```

Returns one of the control's image lists: `LVSIL_NORMAL` (large icons), `LVSIL_SMALL`,
`LVSIL_STATE` (check boxes and other state images) or `LVSIL_GROUPHEADER`.

**Returns** the image list, or `NULL`.

**Example**

```freebasic
dim himl as HIMAGELIST = ListView.GetImageList( hCtrl, LVSIL_SMALL )
```

Microsoft Learn: [LVM_GETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getimagelist)

### SetImageList

```freebasic
function SetImageList( byval hListView as HWND, byval himl as HIMAGELIST, byval nImageList as long ) as HIMAGELIST
```

Gives the control the image list `himl` for the use `nImageList` names (`LVSIL_NORMAL`,
`LVSIL_SMALL`, `LVSIL_STATE`, `LVSIL_GROUPHEADER`). Items choose their image by index with
`LVIF_IMAGE`.

Who destroys the list: the control, when it is destroyed, unless it has `LVS_SHAREIMAGELISTS`
(which `CWindow.AddControl` sets); then destroy it yourself with `ImageList_Destroy` after the
control is gone.

**Returns** the image list it replaces, or `NULL`.

**Example**

```freebasic
dim himl as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32 or ILC_MASK, 4, 4 )
ListView.SetImageList( hCtrl, himl, LVSIL_SMALL )
```

Microsoft Learn: [LVM_SETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setimagelist)

### CreateDragImage

```freebasic
function CreateDragImage overload( byval hListView as HWND, byval i as long, byval lpptUpLeft as POINT ptr ) as HIMAGELIST
function CreateDragImage overload( byval hListView as HWND, byval i as long, byref tUpLeft as POINT ) as HIMAGELIST
```

Creates an image list holding a picture of item `i`, for dragging it with the `ImageList_Drag*`
functions. The control writes the image's upper-left corner, in view coordinates, into the
`POINT` you pass.

The image list is yours: destroy it with `ImageList_Destroy` when the drag ends.

**Returns** the image list, or `NULL` on failure.

**Example**

```freebasic
dim ptCorner as POINT
dim himlDrag as HIMAGELIST = ListView.CreateDragImage( hCtrl, 0, ptCorner )
if himlDrag then ImageList_Destroy( himlDrag )
```

Microsoft Learn: [LVM_CREATEDRAGIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-createdragimage)

### ApproximateViewRect

```freebasic
function ApproximateViewRect( byval hListView as HWND, byval iWidth as short, byval iHeight as short, byval iCount as long ) as DWORD
```

Estimates the width and height the control needs to show `iCount` items (-1 for all of them)
when given the proposed size `iWidth` × `iHeight` (-1 for the current size).

**Returns** the width in the low word and the height in the high word.

**Example**

```freebasic
dim dwSize as DWORD = ListView.ApproximateViewRect( hCtrl, -1, -1, -1 )
print "needs"; LOWORD( dwSize ); " x"; HIWORD( dwSize )
```

Microsoft Learn: [LVM_APPROXIMATEVIEWRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-approximateviewrect)

### Arrange

```freebasic
function Arrange( byval hListView as HWND, byval code as UINT ) as boolean
```

Arranges the items in icon or small icon view: `LVA_DEFAULT` follows the control's alignment
style, `LVA_ALIGNLEFT` and `LVA_ALIGNTOP` align them to an edge, `LVA_SNAPTOGRID` snaps them to
the nearest grid position.

**Returns** `true` on success.

**Example**

```freebasic
ListView.Arrange( hCtrl, LVA_SNAPTOGRID )
```

Microsoft Learn: [LVM_ARRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-arrange)

### GetCountPerPage

```freebasic
function GetCountPerPage( byval hListView as HWND ) as long
```

Returns how many items fit in the visible area in list or report view; in icon views, the
total number of items.

**Returns** the count.

**Example**

```freebasic
print "rows per page:"; ListView.GetCountPerPage( hCtrl )
```

Microsoft Learn: [LVM_GETCOUNTPERPAGE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getcountperpage)

### GetTopIndex

```freebasic
function GetTopIndex( byval hListView as HWND ) as long
```

Returns the first visible item in list or report view; 0 in icon views.

**Returns** the index.

**Example**

```freebasic
print "first visible row:"; ListView.GetTopIndex( hCtrl )
```

Microsoft Learn: [LVM_GETTOPINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gettopindex)

### EnsureVisible

```freebasic
function EnsureVisible( byval hListView as HWND, byval i as long, byval fPartialOK as boolean ) as boolean
```

Scrolls the control, if needed, so that item `i` is visible. With `fPartialOK` = `true` an item
already partly visible is left where it is.

**Returns** `true` on success.

**Example**

```freebasic
ListView.EnsureVisible( hCtrl, ListView.GetItemCount( hCtrl ) - 1, false )   ' show the last row
```

Microsoft Learn: [LVM_ENSUREVISIBLE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-ensurevisible)

### IsItemVisible

```freebasic
function IsItemVisible( byval hListView as HWND, byval index as UINT ) as boolean
```

Reads whether item `index` is visible. Needs visual styles.

**Returns** `true` when the item is visible.

**Example**

```freebasic
if ListView.IsItemVisible( hCtrl, 5 ) = false then ListView.EnsureVisible( hCtrl, 5, false )
```

Microsoft Learn: [LVM_ISITEMVISIBLE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-isitemvisible)

### Scroll

```freebasic
function Scroll( byval hListView as HWND, byval dx as long, byval dy as long ) as boolean
```

Scrolls the content by `dx` and `dy` pixels. In list view `dx` is rounded to whole columns, and
in report view `dy` to whole rows.

**Returns** `true` on success.

**Example**

```freebasic
ListView.Scroll( hCtrl, 0, 40 )
```

Microsoft Learn: [LVM_SCROLL](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-scroll)

### GetOrigin

```freebasic
function GetOrigin overload( byval hListView as HWND, byval pptOrg as POINT ptr ) as boolean
function GetOrigin overload( byval hListView as HWND, byref ptOrg as POINT ) as boolean
function GetOrigin overload( byval hListView as HWND ) as POINT
```

Reads the view origin, which converts view coordinates (item positions) to client
coordinates. Only icon and small icon views have one.

**Returns** `true` on success (`false` in list and report view), or the point.

**Example**

```freebasic
dim ptOrg as POINT
if ListView.GetOrigin( hCtrl, ptOrg ) then print "origin"; ptOrg.x; ","; ptOrg.y
```

Microsoft Learn: [LVM_GETORIGIN](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getorigin)

### GetViewRect

```freebasic
function GetViewRect overload( byval hListView as HWND, byval prc as RECT ptr ) as boolean
function GetViewRect overload( byval hListView as HWND, byref rc as RECT ) as boolean
function GetViewRect overload( byval hListView as HWND ) as ( long, long, long, long )
```

Reads the rectangle that bounds all items, in view coordinates, in icon or small icon view. The
tuple form returns `( left, top, right, bottom )` and leaves `GetLastError()` nonzero on
success.

**Returns** `true` on success, or the four edges.

**Example**

```freebasic
var (l, t, r, b) = ListView.GetViewRect( hCtrl )
if GetLastError() then print "all items fit in"; r - l; " x"; b - t
```

Microsoft Learn: [LVM_GETVIEWRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getviewrect)

### GetItemRect

```freebasic
function GetItemRect overload( byval hListView as HWND, byval i as long, byval prc as RECT ptr ) as boolean
function GetItemRect overload( byval hListView as HWND, byval i as long, byref rc as RECT ) as boolean
function GetItemRect overload( byval hListView as HWND, byval i as long, byval code as long ) as ( long, long, long, long )
```

Reads the rectangle of item `i`, in client coordinates. Which part is set by `code`:
`LVIR_BOUNDS` (the whole item), `LVIR_ICON`, `LVIR_LABEL` or `LVIR_SELECTBOUNDS`.

The tuple form takes `code` and returns `( left, top, right, bottom )`, leaving `GetLastError()`
nonzero on success. The forms that take a `RECT` read the code from its `left` member: set it
before the call.

**Returns** `true` on success, or the four edges.

**Example**

```freebasic
var (l, t, r, b) = ListView.GetItemRect( hCtrl, 0, LVIR_BOUNDS )
if GetLastError() then print "row height:"; b - t
```

Microsoft Learn: [LVM_GETITEMRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemrect)

### GetSubItemRect

```freebasic
function GetSubItemRect overload( byval hListView as HWND, byval iItem as long, byval iSubItem as long, byval nCode as long, byval prc as RECT ptr ) as boolean
function GetSubItemRect overload( byval hListView as HWND, byval iItem as long, byval iSubItem as long, byval nCode as long, byref rc as RECT ) as boolean
function GetSubItemRect overload( byval hListView as HWND, byval iItem as long, byval iSubItem as long, byval nCode as long ) as ( long, long, long, long )
```

Reads the rectangle of subitem `iSubItem` of item `iItem` in report view, in client
coordinates; `nCode` is `LVIR_BOUNDS`, `LVIR_ICON` or `LVIR_LABEL`. For subitem 0 the bounds
are those of the whole row. The tuple form leaves `GetLastError()` nonzero on success; the
pointer form returns `false` for a null pointer.

**Returns** `true` on success, or the four edges.

**Example**

```freebasic
var (l, t, r, b) = ListView.GetSubItemRect( hCtrl, 0, 1, LVIR_BOUNDS )
if GetLastError() then print "column 1 spans"; l; " to"; r
```

Microsoft Learn: [LVM_GETSUBITEMRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getsubitemrect)

### GetItemIndexRect

```freebasic
function GetItemIndexRect overload( byval hListView as HWND, byval pvii as LVITEMINDEX ptr, byval iSubItem as long, byval code as long, byval prc as RECT ptr ) as boolean
function GetItemIndexRect overload( byval hListView as HWND, byref lvii as LVITEMINDEX, byval iSubItem as long, byval code as long, byref rc as RECT ) as boolean
function GetItemIndexRect overload( byval hListView as HWND, byref vii as LVITEMINDEX, byval iSubItem as long, byval code as long ) as ( long, long, long, long )
```

Like [GetSubItemRect](#getsubitemrect), for the item that an `LVITEMINDEX` (item and group)
names. The tuple form leaves `GetLastError()` nonzero on success. Needs visual styles.

**Returns** `true` on success, or the four edges.

**Example**

```freebasic
dim lvii as LVITEMINDEX
lvii.iItem = 0 : lvii.iGroup = 0
var (l, t, r, b) = ListView.GetItemIndexRect( hCtrl, lvii, 0, LVIR_BOUNDS )
```

Microsoft Learn: [LVM_GETITEMINDEXRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemindexrect)

### GetItemPosition

```freebasic
function GetItemPosition overload( byval hListView as HWND, byval i as long, byval ppt as POINT ptr ) as boolean
function GetItemPosition overload( byval hListView as HWND, byval i as long, byref pt as POINT ) as boolean
function GetItemPosition overload( byval hListView as HWND, byval i as long ) as POINT
```

Reads the position of item `i`'s upper-left corner, in view coordinates.

**Returns** `true` on success, or the point.

**Example**

```freebasic
dim pt as POINT = ListView.GetItemPosition( hCtrl, 0 )
print "item 0 at"; pt.x; ","; pt.y
```

Microsoft Learn: [LVM_GETITEMPOSITION](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemposition)

### SetItemPosition

```freebasic
function SetItemPosition( byval hListView as HWND, byval i as long, byval x as short, byval y as short ) as boolean
```

Moves item `i` to (`x`, `y`) in view coordinates, in icon or small icon view. The coordinates
are 16-bit; for larger ones use [SetItemPosition32](#setitemposition32). An auto-arranged
control moves it back on the next arrangement.

**Returns** `true` on success.

**Example**

```freebasic
ListView.SetItemPosition( hCtrl, 0, 100, 40 )
```

Microsoft Learn: [LVM_SETITEMPOSITION](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemposition)

### SetItemPosition32

```freebasic
sub SetItemPosition32( byval hListView as HWND, byval i as long, byval x as long, byval y as long )
```

Moves item `i` to (`x`, `y`) in view coordinates, in icon or small icon view, with 32-bit
coordinates.

**Example**

```freebasic
ListView.SetItemPosition32( hCtrl, 0, 100000, 40 )
```

Microsoft Learn: [LVM_SETITEMPOSITION32](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setitemposition32)

### GetItemSpacing

```freebasic
function GetItemSpacing( byval hListView as HWND, byval fSmall as boolean ) as DWORD
```

Returns the distance between items in icon view (`fSmall` = `false`) or small icon view
(`true`).

**Returns** the horizontal spacing in the low word and the vertical spacing in the high word.

**Example**

```freebasic
dim dwSpacing as DWORD = ListView.GetItemSpacing( hCtrl, false )
print LOWORD( dwSpacing ); " x"; HIWORD( dwSpacing )
```

Microsoft Learn: [LVM_GETITEMSPACING](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemspacing)

### GetItemHorizontalSpacing

```freebasic
function GetItemHorizontalSpacing( byval hListView as HWND, byval fSmall as boolean ) as DWORD
```

**Returns** the low word of [GetItemSpacing](#getitemspacing): the horizontal distance between
items.

**Example**

```freebasic
print ListView.GetItemHorizontalSpacing( hCtrl, false )
```

Microsoft Learn: [LVM_GETITEMSPACING](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemspacing)

### GetItemVerticalSpacing

```freebasic
function GetItemVerticalSpacing( byval hListView as HWND, byval fSmall as boolean ) as DWORD
```

**Returns** the high word of [GetItemSpacing](#getitemspacing): the vertical distance between
items.

**Example**

```freebasic
print ListView.GetItemVerticalSpacing( hCtrl, false )
```

Microsoft Learn: [LVM_GETITEMSPACING](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getitemspacing)

### SetIconSpacing

```freebasic
function SetIconSpacing( byval hListView as HWND, byval cx as short, byval cy as short ) as DWORD
```

Sets the distance between icons in icon view, in pixels, including the icon itself; -1 for
both values restores the default spacing.

**Returns** the previous spacing, horizontal in the low word and vertical in the high word.

**Example**

```freebasic
ListView.SetIconSpacing( hCtrl, 96, 80 )
```

Microsoft Learn: [LVM_SETICONSPACING](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-seticonspacing)

### GetWorkAreas

```freebasic
sub GetWorkAreas overload( byval hListView as HWND, byval nWorkAreas as long, byval prc as RECT ptr )
sub GetWorkAreas overload( byval hListView as HWND, byval nWorkAreas as long, byref rc as RECT )
```

Reads `nWorkAreas` working areas: rectangles of the icon view that items are arranged in. The
`RECT` forms write `nWorkAreas` rectangles, so pass the first element of an array that large.

**Example**

```freebasic
dim rcAreas(0 to 1) as RECT
ListView.GetWorkAreas( hCtrl, 2, rcAreas(0) )
```

Microsoft Learn: [LVM_GETWORKAREAS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getworkareas)

### SetWorkAreas

```freebasic
sub SetWorkAreas overload( byval hListView as HWND, byval nWorkAreas as long, byval prc as RECT ptr )
sub SetWorkAreas overload( byval hListView as HWND, byval nWorkAreas as long, byref rc as RECT )
```

Sets up to `LV_MAX_WORKAREAS` working areas, from the `nWorkAreas` rectangles of an array
(pass its first element); 0 removes them.

**Example**

```freebasic
dim rcAreas(0 to 1) as RECT
rcAreas(0).right = 200 : rcAreas(0).bottom = 300
rcAreas(1).left = 200 : rcAreas(1).right = 400 : rcAreas(1).bottom = 300
ListView.SetWorkAreas( hCtrl, 2, rcAreas(0) )
```

Microsoft Learn: [LVM_SETWORKAREAS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setworkareas)

### GetNumberOfWorkAreas

```freebasic
function GetNumberOfWorkAreas( byval hListView as HWND ) as DWORD
```

**Returns** The number of working areas.

**Example**

```freebasic
dim nAreas as UINT = ListView.GetNumberOfWorkAreas( hCtrl )
print "work areas:"; nAreas
```

Microsoft Learn: [LVM_GETNUMBEROFWORKAREAS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getnumberofworkareas)

### HitTest

```freebasic
function HitTest overload( byval hListView as HWND, byval pinfo as LVHITTESTINFO ptr ) as long
function HitTest overload( byval hListView as HWND, byref info as LVHITTESTINFO ) as long
function HitTest overload( byval hListView as HWND ) as LVHITTESTINFO
```

Finds the item at the point `pt` of an `LVHITTESTINFO`, in client coordinates. The control
fills `flags` (`LVHT_ONITEMLABEL`, `LVHT_NOWHERE` …) and `iItem`. The form without a structure
tests the point (0, 0) and returns the filled structure, leaving the item index in
`GetLastError()`.

**Returns** the index of the item, or -1; or the structure.

**Example**

```freebasic
dim hti as LVHITTESTINFO
GetCursorPos( @hti.pt ) : ScreenToClient( hCtrl, @hti.pt )
print "item under the pointer:"; ListView.HitTest( hCtrl, hti )
```

Microsoft Learn: [LVM_HITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-hittest)

### HitTestEx

```freebasic
function HitTestEx overload( byval hListView as HWND, byref pinfo as LVHITTESTINFO ptr ) as long
function HitTestEx overload( byval hListView as HWND, byref info as LVHITTESTINFO ) as long
function HitTestEx overload( byval hListView as HWND ) as LVHITTESTINFO
```

Like [HitTest](#hittest), but asks the control to fill the extended members as well: the
subitem (`iSubItem`) and the group (`iGroup`) at the point.

**Returns** the index of the item, or -1; or the structure.

**Example**

```freebasic
dim hti as LVHITTESTINFO
hti.pt.x = 10 : hti.pt.y = 30
if ListView.HitTestEx( hCtrl, hti ) >= 0 then print "group"; hti.iGroup
```

Microsoft Learn: [LVM_HITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-hittest)

### SubItemHitTest

```freebasic
function SubItemHitTest overload( byval hListView as HWND, byval plvhti as LVHITTESTINFO ptr ) as long
function SubItemHitTest overload( byval hListView as HWND, byref lvhti as LVHITTESTINFO ) as long
```

Finds the item and subitem at the point in an `LVHITTESTINFO`, in client coordinates; the
control fills `iItem`, `iSubItem` and `flags`. Use it in report view to know which cell was
clicked.

**Returns** the index of the item, or -1.

**Example**

```freebasic
dim hti as LVHITTESTINFO
hti.pt.x = 150 : hti.pt.y = 30
if ListView.SubItemHitTest( hCtrl, hti ) >= 0 then print "row"; hti.iItem; " column"; hti.iSubItem
```

Microsoft Learn: [LVM_SUBITEMHITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-subitemhittest)

### SubItemHitTestEx

```freebasic
function SubItemHitTestEx overload( byval hListView as HWND, byval plvhti as LVHITTESTINFO ptr ) as long
function SubItemHitTestEx overload( byval hListView as HWND, byref lvhti as LVHITTESTINFO ) as long
```

Like [SubItemHitTest](#subitemhittest), and fills the group (`iGroup`) as well.

**Returns** the index of the item, or -1.

**Example**

```freebasic
dim hti as LVHITTESTINFO
hti.pt.x = 150 : hti.pt.y = 30
ListView.SubItemHitTestEx( hCtrl, hti )
```

Microsoft Learn: [LVM_SUBITEMHITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-subitemhittest)

### GetInsertMark

```freebasic
function GetInsertMark overload( byval hListView as HWND, byval pvim as LVINSERTMARK ptr ) as boolean
function GetInsertMark overload( byval hListView as HWND, byref vim as LVINSERTMARK ) as boolean
function GetInsertMark overload( byval hListView as HWND ) as LVINSERTMARK
```

Reads where the insertion mark is: the item it is next to (`iItem`, -1 for none) and, in
`dwFlags`, whether it is after it (`LVIM_AFTER`). The function sets `cbSize` itself. The form
that returns the structure leaves the message's result in `GetLastError()`.

**Returns** `true` on success, or the structure.

**Example**

```freebasic
dim lvim as LVINSERTMARK = ListView.GetInsertMark( hCtrl )
print "insertion mark at item"; lvim.iItem
```

Microsoft Learn: [LVM_GETINSERTMARK](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getinsertmark)

### SetInsertMark

```freebasic
function SetInsertMark overload( byval hListView as HWND, byval plvim as LVINSERTMARK ptr ) as boolean
function SetInsertMark overload( byval hListView as HWND, byref lvim as LVINSERTMARK ) as boolean
```

Places the insertion mark next to item `iItem` of an `LVINSERTMARK`, before it or after it
(`LVIM_AFTER`); `iItem` = -1 removes it. Set `cbSize` yourself. Used while dragging items in
icon view.

**Returns** `true` on success.

**Example**

```freebasic
dim lvim as LVINSERTMARK
lvim.cbSize = sizeof( LVINSERTMARK ) : lvim.iItem = 2 : lvim.dwFlags = LVIM_AFTER
ListView.SetInsertMark( hCtrl, lvim )
```

Microsoft Learn: [LVM_SETINSERTMARK](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setinsertmark)

### GetInsertMarkColor

```freebasic
function GetInsertMarkColor( byval hListView as HWND ) as COLORREF
```

**Returns** the colour of the insertion mark.

**Example**

```freebasic
dim clr as COLORREF = ListView.GetInsertMarkColor( hCtrl )
```

Microsoft Learn: [LVM_GETINSERTMARKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getinsertmarkcolor)

### SetInsertMarkColor

```freebasic
function SetInsertMarkColor( byval hListView as HWND, byval clr as COLORREF ) as COLORREF
```

Sets the colour of the insertion mark.

**Returns** the previous colour.

**Example**

```freebasic
ListView.SetInsertMarkColor( hCtrl, BGR( 255, 0, 0 ) )
```

Microsoft Learn: [LVM_SETINSERTMARKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setinsertmarkcolor)

### GetInsertMarkRect

```freebasic
function GetInsertMarkRect overload( byval hListView as HWND, byval prc as RECT ptr ) as long
function GetInsertMarkRect overload( byval hListView as HWND, byref rc as RECT ) as long
function GetInsertMarkRect overload( byval hListView as HWND ) as ( long, long, long, long )
```

Reads the rectangle around the insertion mark, in client coordinates. The tuple form leaves
`GetLastError()` nonzero when there is a mark.

**Returns** nonzero when a rectangle was found, or the four edges.

**Example**

```freebasic
var (l, t, r, b) = ListView.GetInsertMarkRect( hCtrl )
if GetLastError() then InvalidateRect( hCtrl, NULL, true )
```

Microsoft Learn: [LVM_GETINSERTMARKRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getinsertmarkrect)

### InsertMarkHitTest

```freebasic
function InsertMarkHitTest overload( byval hListView as HWND, byval ppt as POINT ptr, byval pvim as LVINSERTMARK ptr ) as boolean
function InsertMarkHitTest overload( byval hListView as HWND, byref pt as POINT, byref vim as LVINSERTMARK ) as boolean
```

Finds the insertion point closest to a point in client coordinates and describes it in an
`LVINSERTMARK`, ready for [SetInsertMark](#setinsertmark). Set the structure's `cbSize` first.

**Returns** `true` on success.

**Example**

```freebasic
dim pt as POINT = ( 40, 60 )
dim lvim as LVINSERTMARK
lvim.cbSize = sizeof( LVINSERTMARK )
if ListView.InsertMarkHitTest( hCtrl, pt, lvim ) then ListView.SetInsertMark( hCtrl, lvim )
```

Microsoft Learn: [LVM_INSERTMARKHITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-insertmarkhittest)

### SortItems

```freebasic
function SortItems( byval hListView as HWND, byval _pfnCompare as PFNLVCOMPARE ptr, byval _lPrm as LPARAM ) as long
```

Sorts the items with a comparison function, which receives the `lParam` values of two items
and `_lPrm`, and returns a negative number when the first comes first, a positive number when
the second does, and 0 when they are equal. The items are renumbered to the new order.

The parameter is a pointer to `PFNLVCOMPARE`, so pass the function's address cast to it, as
below.

**Returns** nonzero on success.

**Example**

```freebasic
function CompareByParam( byval lParam1 as LPARAM, byval lParam2 as LPARAM, byval lParamSort as LPARAM ) as long
    return lParam1 - lParam2
end function

sub SortList( byval hList as HWND )
    ListView.SortItems( hList, cast( PFNLVCOMPARE ptr, @CompareByParam ), 0 )
end sub
```

Microsoft Learn: [LVM_SORTITEMS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-sortitems)

### SortItemsEx

```freebasic
function SortItemsEx( byval hListView as HWND, byval _pfnCompare as PFNLVCOMPARE ptr, byval _lPrm as LPARAM ) as long
```

Like [SortItems](#sortitems), but the comparison function receives the current **indexes** of
the two items, so it can read their text with [GetItemText](#getitemtext).

**Returns** nonzero on success.

**Example**

```freebasic
function CompareByText( byval i1 as LPARAM, byval i2 as LPARAM, byval hList as LPARAM ) as long
    dim as wstring * 128 w1, w2
    ListView.GetItemText( cast( HWND, hList ), i1, 0, @w1, 128 )
    ListView.GetItemText( cast( HWND, hList ), i2, 0, @w2, 128 )
    return lstrcmpiW( @w1, @w2 )
end function

sub SortListByText( byval hList as HWND )
    ListView.SortItemsEx( hList, cast( PFNLVCOMPARE ptr, @CompareByText ), cast( LPARAM, hList ) )
end sub
```

Microsoft Learn: [LVM_SORTITEMSEX](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-sortitemsex)

### SortGroups

```freebasic
function SortGroups( byval hListView as HWND, byval _pfnGroupCompare as PFNLVGROUPCOMPARE ptr, byval _plv as any ptr ) as boolean
```

Sorts the groups with a comparison function, which receives two group IDs and `_plv`. Pass the
function's address cast to `PFNLVGROUPCOMPARE ptr`.

**Returns** `true` on success.

**Example**

```freebasic
function CompareGroups( byval id1 as long, byval id2 as long, byval pv as any ptr ) as long
    return id1 - id2
end function

sub SortGroupsById( byval hList as HWND )
    ListView.SortGroups( hList, cast( PFNLVGROUPCOMPARE ptr, @CompareGroups ), NULL )
end sub
```

Microsoft Learn: [LVM_SORTGROUPS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-sortgroups)

### EnableGroupView

```freebasic
function EnableGroupView( byval hListView as HWND, byval fEnable as boolean ) as long
```

Turns group view on or off. With it on, items are shown under the group their `iGroupId` names
(set with [SetItem](#setitem) and `LVIF_GROUPID`); items in no group are not shown. Needs
visual styles.

**Returns** 1 when the setting changed, 0 when it already was so, -1 on failure.

**Example**

```freebasic
ListView.EnableGroupView( hCtrl, true )
```

Microsoft Learn: [LVM_ENABLEGROUPVIEW](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-enablegroupview)

### IsGroupViewEnabled

```freebasic
function IsGroupViewEnabled( byval hListView as HWND ) as boolean
```

**Returns** `true` when group view is on.

**Example**

```freebasic
if ListView.IsGroupViewEnabled( hCtrl ) then print "grouped"
```

Microsoft Learn: [LVM_ISGROUPVIEWENABLED](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-isgroupviewenabled)

### InsertGroup

```freebasic
function InsertGroup overload( byval hListView as HWND, byval index as long, byval pgrp as LVGROUP ptr ) as long
function InsertGroup overload( byval hListView as HWND, byval index as long, byref grp as LVGROUP ) as long
```

Inserts a group described by an `LVGROUP` at position `index` (-1 appends it). Set `cbSize`,
`mask` and the members it names; `iGroupId` is the ID items use to join the group.

**Returns** the index of the new group, or -1 on failure.

**Example**

```freebasic
dim grp as LVGROUP
grp.cbSize = sizeof( LVGROUP ) : grp.mask = LVGF_HEADER or LVGF_GROUPID
grp.pszHeader = @wstr("Inner planets") : grp.iGroupId = 1
ListView.InsertGroup( hCtrl, -1, grp )
```

Microsoft Learn: [LVM_INSERTGROUP](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-insertgroup)

### InsertGroupSorted

```freebasic
sub InsertGroupSorted overload( byval hListView as HWND, byval pstructInsert as LVINSERTGROUPSORTED ptr )
sub InsertGroupSorted overload( byval hListView as HWND, byref structInsert as LVINSERTGROUPSORTED )
```

Inserts a group into an ordered list of groups, using the comparison function and the
`LVGROUP` in an `LVINSERTGROUPSORTED`.

**Example**

```freebasic
dim igs as LVINSERTGROUPSORTED
igs.lvGroup.cbSize = sizeof( LVGROUP ) : igs.lvGroup.mask = LVGF_HEADER or LVGF_GROUPID
igs.lvGroup.pszHeader = @wstr("Gas giants") : igs.lvGroup.iGroupId = 2
ListView.InsertGroupSorted( hCtrl, igs )
```

Microsoft Learn: [LVM_INSERTGROUPSORTED](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-insertgroupsorted)

### RemoveGroup

```freebasic
function RemoveGroup( byval hListView as HWND, byval iGroupId as long ) as long
```

Removes the group with ID `iGroupId`.

**Returns** the index of the group removed, or -1 on failure.

**Example**

```freebasic
ListView.RemoveGroup( hCtrl, 2 )
```

Microsoft Learn: [LVM_REMOVEGROUP](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-removegroup)

### RemoveAllGroups

```freebasic
sub RemoveAllGroups( byval hListView as HWND )
```

Removes every group.

**Example**

```freebasic
ListView.RemoveAllGroups( hCtrl )
```

Microsoft Learn: [LVM_REMOVEALLGROUPS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-removeallgroups)

### HasGroup

```freebasic
function HasGroup( byval hListView as HWND, byval iGroupId as long ) as boolean
```

**Returns** `true` when there is a group with ID `iGroupId`.

**Example**

```freebasic
if ListView.HasGroup( hCtrl, 1 ) = false then print "no group 1"
```

Microsoft Learn: [LVM_HASGROUP](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-hasgroup)

### GetGroupCount

```freebasic
function GetGroupCount( byval hListView as HWND ) as long
```

**Returns** the number of groups.

**Example**

```freebasic
print "groups:"; ListView.GetGroupCount( hCtrl )
```

Microsoft Learn: [LVM_GETGROUPCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getgroupcount)

### GetGroupInfo

```freebasic
function GetGroupInfo overload( byval hListView as HWND, byval iGroupId as long, byval pgrp as LVGROUP ptr ) as long
function GetGroupInfo overload( byval hListView as HWND, byval iGroupId as long, byref grp as LVGROUP ) as long
```

Reads the attributes of the group with ID `iGroupId` that the `LVGROUP`'s `mask` asks for. The
function sets `cbSize` itself; for text, give `pszHeader` a buffer and `cchHeader` its size.

**Returns** the group's ID, or -1 on failure (and for a null pointer).

**Example**

```freebasic
dim grp as LVGROUP
grp.mask = LVGF_STATE : grp.stateMask = LVGS_COLLAPSED
if ListView.GetGroupInfo( hCtrl, 1, grp ) <> -1 andalso ( grp.state and LVGS_COLLAPSED ) <> 0 then print "collapsed"
```

Microsoft Learn: [LVM_GETGROUPINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getgroupinfo)

### GetGroupInfoByIndex

```freebasic
function GetGroupInfoByIndex overload( byval hListView as HWND, byval iIndex as long, byref pgrp as LVGROUP ptr ) as boolean
function GetGroupInfoByIndex overload( byval hListView as HWND, byval iIndex as long, byref grp as LVGROUP ) as boolean
```

Like [GetGroupInfo](#getgroupinfo), for the group at position `iIndex` (from 0) rather than by
ID. The function sets `cbSize` itself.

**Returns** `true` on success.

**Example**

```freebasic
dim grp as LVGROUP
grp.mask = LVGF_GROUPID
for i as long = 0 to ListView.GetGroupCount( hCtrl ) - 1
    if ListView.GetGroupInfoByIndex( hCtrl, i, grp ) then print "group ID"; grp.iGroupId
next
```

Microsoft Learn: [LVM_GETGROUPINFOBYINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getgroupinfobyindex)

### SetGroupInfo

```freebasic
function SetGroupInfo overload( byval hListView as HWND, byval iGroupId as long, byval pgrp as LVGROUP ptr ) as long
function SetGroupInfo overload( byval hListView as HWND, byval iGroupId as long, byref grp as LVGROUP ) as long
```

Changes the attributes of the group with ID `iGroupId` that the `LVGROUP`'s `mask` names. Set
`cbSize` yourself.

**Returns** the group's ID, or -1 on failure.

**Example**

```freebasic
dim grp as LVGROUP
grp.cbSize = sizeof( LVGROUP ) : grp.mask = LVGF_HEADER : grp.pszHeader = @wstr("Rocky planets")
ListView.SetGroupInfo( hCtrl, 1, grp )
```

Microsoft Learn: [LVM_SETGROUPINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setgroupinfo)

### GetGroupState

```freebasic
function GetGroupState( byval hListView as HWND, byval dwGroupId as UINT, byval dwMask as UINT ) as UINT
```

Returns the state bits of group `dwGroupId` that `dwMask` selects: `LVGS_COLLAPSED`,
`LVGS_COLLAPSIBLE`, `LVGS_HIDDEN` …

**Returns** the state bits.

**Example**

```freebasic
if ListView.GetGroupState( hCtrl, 1, LVGS_COLLAPSED ) then print "group 1 is collapsed"
```

Microsoft Learn: [LVM_GETGROUPSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getgroupstate)

### SetGroupState

```freebasic
function SetGroupState( byval hListView as HWND, byval dwGroupId as UINT, byval dwMask as UINT, byval dwState as UINT ) as long
```

Sets the state bits of group `dwGroupId` that `dwMask` selects to the values in `dwState`.

**Returns** the group's ID, or -1 on failure.

**Example**

```freebasic
ListView.SetGroupState( hCtrl, 1, LVGS_COLLAPSIBLE, LVGS_COLLAPSIBLE )
```

Microsoft Learn: [LVM_SETGROUPINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setgroupinfo)

### GetGroupMetrics

```freebasic
sub GetGroupMetrics overload( byval hListView as HWND, byval pGroupMetrics as LVGROUPMETRICS ptr )
sub GetGroupMetrics overload( byval hListView as HWND, byref GroupMetrics as LVGROUPMETRICS )
```

Reads how groups are drawn (border sizes and colours) into an `LVGROUPMETRICS`, as its `mask`
asks. The function sets `cbSize` itself and does nothing for a null pointer.

**Example**

```freebasic
dim gm as LVGROUPMETRICS
gm.mask = LVGMF_BORDERSIZE
ListView.GetGroupMetrics( hCtrl, gm )
print "group border:"; gm.Left; gm.Top
```

Microsoft Learn: [LVM_GETGROUPMETRICS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getgroupmetrics)

### SetGroupMetrics

```freebasic
sub SetGroupMetrics overload( byval hListView as HWND, byval pGroupMetrics as LVGROUPMETRICS ptr )
sub SetGroupMetrics overload( byval hListView as HWND, byref GroupMetrics as LVGROUPMETRICS )
```

Sets how groups are drawn from an `LVGROUPMETRICS`. Unlike [GetGroupMetrics](#getgroupmetrics),
it does not set `cbSize`: set it yourself.

**Example**

```freebasic
dim gm as LVGROUPMETRICS
gm.cbSize = sizeof( LVGROUPMETRICS ) : gm.mask = LVGMF_BORDERSIZE
gm.Left = 8 : gm.Top = 8 : gm.Right = 8 : gm.Bottom = 8
ListView.SetGroupMetrics( hCtrl, gm )
```

Microsoft Learn: [LVM_SETGROUPMETRICS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setgroupmetrics)

### GetGroupRect

```freebasic
function GetGroupRect overload( byval hListView as HWND, byval iGroupId as long, byval prc as RECT ptr ) as boolean
function GetGroupRect overload( byval hListView as HWND, byval iGroupId as long, byref rc as RECT ) as boolean
function GetGroupRect overload( byval hListView as HWND, byval iGroupId as long, byval nType as long ) as ( long, long, long, long )
```

Reads the rectangle of group `iGroupId`, in client coordinates. `nType` picks the part:
`LVGGR_GROUP` (the whole group), `LVGGR_HEADER`, `LVGGR_LABEL` or `LVGGR_SUBSETLINK`.

**Returns** `true` on success, or the four edges.

**Example**

```freebasic
var (l, t, r, b) = ListView.GetGroupRect( hCtrl, 1, LVGGR_HEADER )
if GetLastError() then print "header height:"; b - t
```

Microsoft Learn: [LVM_GETGROUPRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getgrouprect)

### GetFocusedGroup

```freebasic
function GetFocusedGroup( byval hListView as HWND ) as long
```

**Returns** the index of the group with the focus, or -1.

**Example**

```freebasic
print "focused group:"; ListView.GetFocusedGroup( hCtrl )
```

Microsoft Learn: [LVM_GETFOCUSEDGROUP](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getfocusedgroup)

### GetGroupHeaderImageList

```freebasic
function GetGroupHeaderImageList( byval hListView as HWND ) as HIMAGELIST
```

**Returns** the image list for group headers, or `NULL`: the same as
[GetImageList](#getimagelist) with `LVSIL_GROUPHEADER`.

**Example**

```freebasic
dim himl as HIMAGELIST = ListView.GetGroupHeaderImageList( hCtrl )
```

Microsoft Learn: [LVM_GETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getimagelist)

### SetGroupHeaderImageList

```freebasic
function SetGroupHeaderImageList( byval hListView as HWND, byval himl as HIMAGELIST ) as HIMAGELIST
```

Gives the control the image list for group headers: the same as
[SetImageList](#setimagelist) with `LVSIL_GROUPHEADER`. A group shows an image from it with
`LVGF_TITLEIMAGE`.

**Returns** the image list it replaces, or `NULL`.

**Example**

```freebasic
dim himl as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32, 2, 2 )
ListView.SetGroupHeaderImageList( hCtrl, himl )
```

Microsoft Learn: [LVM_SETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setimagelist)

### GetTileInfo

```freebasic
sub GetTileInfo overload( byval hListView as HWND, byval pti as LVTILEINFO ptr )
sub GetTileInfo overload( byval hListView as HWND, byref ti as LVTILEINFO )
function GetTileInfo overload( byval hListView as HWND ) as LVTILEINFO
```

Reads which subitems the tile of an item shows, into an `LVTILEINFO`: set `iItem`, and give
`puColumns` an array and `cColumns` its size. The function sets `cbSize` itself. The form that
returns the structure asks about item 0 and passes no array.

**Example**

```freebasic
dim cols(0 to 3) as UINT
dim lvti as LVTILEINFO
lvti.iItem = 0 : lvti.cColumns = 4 : lvti.puColumns = @cols(0)
ListView.GetTileInfo( hCtrl, lvti )
print "tile shows"; lvti.cColumns; " subitems"
```

Microsoft Learn: [LVM_GETTILEINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gettileinfo)

### SetTileInfo

```freebasic
function SetTileInfo overload( byval hListView as HWND, byval plvtinfo as LVTILEINFO ptr ) as boolean
function SetTileInfo overload( byval hListView as HWND, byref lvtinfo as LVTILEINFO ) as boolean
```

Sets which subitems the tile of item `iItem` shows, below its text, from an `LVTILEINFO`. Set
`cbSize` yourself.

**Returns** `true` on success.

**Example**

```freebasic
dim cols(0 to 1) as UINT = { 1, 2 }
dim lvti as LVTILEINFO
lvti.cbSize = sizeof( LVTILEINFO ) : lvti.iItem = 0 : lvti.cColumns = 2 : lvti.puColumns = @cols(0)
ListView.SetTileInfo( hCtrl, lvti )
```

Microsoft Learn: [LVM_SETTILEINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-settileinfo)

### GetTileViewInfo

```freebasic
sub GetTileViewInfo overload( byval hListView as HWND, byval ptvi as LVTILEVIEWINFO ptr )
sub GetTileViewInfo overload( byval hListView as HWND, byref tvi as LVTILEVIEWINFO )
```

Reads the tile view settings (tile size, lines of text, margins) that the `LVTILEVIEWINFO`'s
`dwMask` asks for. The function sets `cbSize` itself.

**Example**

```freebasic
dim tvi as LVTILEVIEWINFO
tvi.dwMask = LVTVIM_COLUMNS
ListView.GetTileViewInfo( hCtrl, tvi )
print "lines per tile:"; tvi.cLines
```

Microsoft Learn: [LVM_GETTILEVIEWINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gettileviewinfo)

### SetTileViewInfo

```freebasic
function SetTileViewInfo overload( byval hListView as HWND, byval plvtvinfo as LVTILEVIEWINFO ptr ) as boolean
function SetTileViewInfo overload( byval hListView as HWND, byref lvtvinfo as LVTILEVIEWINFO ) as boolean
```

Changes the tile view settings that the `LVTILEVIEWINFO`'s `dwMask` names. Set `cbSize`
yourself.

**Returns** `true` on success.

**Example**

```freebasic
dim tvi as LVTILEVIEWINFO
tvi.cbSize = sizeof( LVTILEVIEWINFO ) : tvi.dwMask = LVTVIM_COLUMNS : tvi.cLines = 2
ListView.SetTileViewInfo( hCtrl, tvi )
```

Microsoft Learn: [LVM_SETTILEVIEWINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-settileviewinfo)

### GetFooterInfo

```freebasic
function GetFooterInfo overload( byval hListView as HWND, byval pvfi as LVFOOTERINFO ptr ) as boolean
function GetFooterInfo overload( byval hListView as HWND, byref vfi as LVFOOTERINFO ) as boolean
```

Reads the attributes of the control's footer (the area below the items that a list view can
show, with clickable items) that the `LVFOOTERINFO`'s `mask` asks for.

**Returns** `true` on success, or `false`otherwise.

**Example**

```freebasic
dim lvfi as LVFOOTERINFO
lvfi.mask = LVFF_ITEMCOUNT
if ListView.GetFooterInfo( hCtrl, lvfi ) then print "footer items:"; lvfi.cItems
```

Microsoft Learn: [LVM_GETFOOTERINFO](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getfooterinfo)

### GetFooterItem

```freebasic
function GetFooterItem overload( byval hListView as HWND, byval iItem as long, byval pfi as LVFOOTERITEM ptr ) as boolean
function GetFooterItem overload( byval hListView as HWND, byval iItem as long, byref fi as LVFOOTERITEM ) as boolean
```

Reads footer item `iItem` into an `LVFOOTERITEM`, as its `mask` asks.

**Returns** `true` on success, or `false` otherwise.

**Example**

```freebasic
dim wszText as wstring * 64
dim lvfi as LVFOOTERITEM
lvfi.mask = LVFIF_TEXT : lvfi.pszText = @wszText : lvfi.cchTextMax = 64
ListView.GetFooterItem( hCtrl, 0, lvfi )
```

Microsoft Learn: [LVM_GETFOOTERITEM](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getfooteritem)

### GetFooterItemRect

```freebasic
function GetFooterItemRect overload( byval hListView as HWND, byval iItem as UINT, byval prc as RECT ptr ) as boolean
function GetFooterItemRect overload( byval hListView as HWND, byval iItem as UINT, byref rc as RECT ) as boolean
function GetFooterItemRect overload( byval hListView as HWND, byval iItem as UINT ) as ( long, long, long, long )
```

Reads the rectangle of footer item `iItem`, in client coordinates. The tuple form leaves
`GetLastError()` nonzero on success.

**Returns** `true` on success, or the four edges.

**Example**

```freebasic
var (l, t, r, b) = ListView.GetFooterItemRect( hCtrl, 0 )
```

Microsoft Learn: [LVM_GETFOOTERITEMRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getfooteritemrect)

### GetFooterRect

```freebasic
function GetFooterRect overload( byval hListView as HWND, byval prc as RECT ptr ) as boolean
function GetFooterRect overload( byval hListView as HWND, byref rc as RECT ) as boolean
function GetFooterRect overload( byval hListView as HWND ) as ( long, long, long, long )
```

Reads the rectangle of the footer, in client coordinates. The tuple form leaves
`GetLastError()` nonzero on success.

**Returns** `true` on success, or the four edges.

**Example**

```freebasic
var (l, t, r, b) = ListView.GetFooterRect( hCtrl )
if GetLastError() then print "footer height:"; b - t
```

Microsoft Learn: [LVM_GETFOOTERRECT](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-getfooterrect)

### GetToolTips

```freebasic
function GetToolTips( byval hListView as HWND ) as HWND
```

Returns the tooltip control the list view uses. The functions of [ToolTip](SysWin-Gui-ToolTip)
work on it.

**Returns** its handle, or `NULL`.

**Example**

```freebasic
dim hTip as HWND = ListView.GetToolTips( hCtrl )
```

Microsoft Learn: [LVM_GETTOOLTIPS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-gettooltips)

### SetToolTips

```freebasic
function SetToolTips( byval hListView as HWND, byval hwndToolTip as HWND ) as HWND
```

Gives the list view another tooltip control.

**Returns** the tooltip control it used before, or `NULL`.

**Example**

```freebasic
dim hTip as HWND = CreateWindowExW( 0, TOOLTIPS_CLASSW, NULL, TTS_ALWAYSTIP, 0, 0, 0, 0, hwnd, NULL, NULL, NULL )
dim hOldTip as HWND = ListView.SetToolTips( hCtrl, hTip )
```

Microsoft Learn: [LVM_SETTOOLTIPS](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-settooltips)

### SetInfoTip

```freebasic
function SetInfoTip overload( byval hListView as HWND, byval plvInfoTip as LVSETINFOTIP ptr ) as boolean
function SetInfoTip overload( byval hListView as HWND, byref lvInfoTip as LVSETINFOTIP ) as boolean
```

Sets the tooltip text of an item or subitem from an `LVSETINFOTIP` (`iItem`, `iSubItem`,
`pszText`). The function sets `cbSize` itself; the pointer form returns `false` for a null
pointer. Tooltips for items need `LVS_EX_INFOTIP`.

**Returns** `true` on success.

**Example**

```freebasic
dim lvit as LVSETINFOTIP
lvit.iItem = 0 : lvit.pszText = @wstr("The closest planet to the Sun")
ListView.SetInfoTip( hCtrl, lvit )
```

Microsoft Learn: [LVM_SETINFOTIP](https://learn.microsoft.com/en-us/windows/win32/controls/lvm-setinfotip)

### GetTooltipsFont

```freebasic
function GetTooltipsFont( byval hListView as HWND ) as HFONT
```

**Returns** the font of the list view's tooltip control, or `NULL` when it draws with the
system font.

**Example**

```freebasic
dim hFont as HFONT = ListView.GetTooltipsFont( hCtrl )
```

Microsoft Learn: [WM_GETFONT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-getfont)

### SetTooltipsFont

```freebasic
sub SetTooltipsFont( byval hListView as HWND, byval hFont as HFONT = NULL, byval fRedraw as boolean = false )
```

Sets the font of the list view's tooltip control; `NULL` returns it to the system font, and
`fRedraw` = `true` redraws it at once. The font stays yours to delete after the control is gone.
Does nothing when the list view has no tooltip control.

**Example**

```freebasic
ListView.SetTooltipsFont( hCtrl, cast( HFONT, GetStockObject( DEFAULT_GUI_FONT ) ), true )
```

Microsoft Learn: [WM_SETFONT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-setfont)

## See also

- [sys/win/gui](SysWin-Gui) for the module and the other controls
- [CWindow](CWindow) for `AddControl`, which creates the list view
- [Header](SysWin-Gui-Header) for the header control of report view
- [TreeView](SysWin-Gui-TreeView) and [ListBox](SysWin-Gui-ListBox), the other list controls
- [ToolTip](SysWin-Gui-ToolTip) for the list view's tooltip control
- [Dark mode](SysWin-Dark-Mode) for dark title bars and the user's colour setting
