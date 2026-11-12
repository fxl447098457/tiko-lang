[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **Rebar**

# Rebar

Inserts, moves, sizes and queries the bands of a rebar, the container for toolbars.

A rebar (also called a coolbar) is a strip across the top of a window divided into **bands**.
Each band can hold one child window, usually a toolbar or a combo box, and may have a gripper,
a label and a background bitmap; the user drags bands to reorder and resize them, and bands wrap
onto further rows when the window is too narrow. Create one with
`CWindow.AddControl( "Rebar", ... )` and pass `WM_SIZE` on to it from the parent's window
procedure so that it follows the window's width. Every function here takes the rebar's handle
first and is written with the namespace: `Rebar.InsertBand( hRebar, ... )`.

A band is described by a `REBARBANDINFOW` whose `fMask` says which members are meant
(`RBBIM_CHILD`, `RBBIM_CHILDSIZE`, `RBBIM_SIZE`, `RBBIM_IDEALSIZE`, `RBBIM_STYLE`, `RBBIM_TEXT`,
`RBBIM_ID` …). [InsertBand](#insertband), [GetBandInfo](#getbandinfo) and
[SetBandInfo](#setbandinfo) fill in `cbSize` for you: the version 6 size when the common
controls in use are version 6 (a manifest or `EnableVisualStyles()`), the older, shorter size
otherwise. Bands have a zero-based **index**, their place from the first band, which changes as
bands move, and an **identifier** (`wID`) you choose, which does not; [IdToIndex](#idtoindex)
converts. When a band is given a child window, the rebar makes itself that window's parent and
sizes it; deleting the band hides the child but does not destroy it.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A rebar holding two bands: a toolbar with the standard Back and Forward images, and an edit box
labelled "Find". The Swap button moves the first band after the second and puts the find band's
new index and the rebar's height in the caption.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_REBAR = 100
const IDC_TOOLBAR = 101
const IDC_FIND = 102
const ID_BAND_TOOLS = 1
const ID_BAND_FIND = 2
enum
    IDM_BACK = 1001
    IDM_FORWARD
    IDM_SWAP
end enum

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    EnableVisualStyles()
    dim pWindow as CWindow = "RebarDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Rebar", @WndProc )
    pWindow.SetClientSize( 480, 200 )
    pWindow.Center()
    dim hRebar as HWND = pWindow.AddControl( "Rebar", hWin, IDC_REBAR )

    ' // A toolbar that the band sizes, not its parent
    dim hToolBar as HWND = pWindow.AddControl( "Toolbar", hWin, IDC_TOOLBAR, "", 0, 0, 0, 0, _
        WS_VISIBLE or TBSTYLE_FLAT or TBSTYLE_LIST or CCS_NORESIZE or CCS_NODIVIDER or CCS_NOPARENTALIGN )
    ToolBar.LoadImages( hToolBar, IDB_HIST_SMALL_COLOR )
    ToolBar.AddButton( hToolBar, HIST_BACK, IDM_BACK, 0, BTNS_AUTOSIZE, 0, "Back" )
    ToolBar.AddButton( hToolBar, HIST_FORWARD, IDM_FORWARD, 0, BTNS_AUTOSIZE, 0, "Forward" )
    ToolBar.AddButton( hToolBar, HIST_VIEWTREE, IDM_SWAP, 0, BTNS_AUTOSIZE, 0, "Swap" )
    var (cx, cy) = ToolBar.GetMaxSize( hToolBar )

    dim rbbi as REBARBANDINFOW
    rbbi.fMask = RBBIM_STYLE or RBBIM_CHILD or RBBIM_CHILDSIZE or RBBIM_SIZE or RBBIM_IDEALSIZE or RBBIM_ID
    rbbi.fStyle = RBBS_CHILDEDGE or RBBS_GRIPPERALWAYS
    rbbi.hwndChild = hToolBar
    rbbi.cxMinChild = cx : rbbi.cyMinChild = cy
    rbbi.cx = cx + 20 : rbbi.cxIdeal = cx
    rbbi.wID = ID_BAND_TOOLS
    Rebar.InsertBand( hRebar, -1, rbbi )

    ' // A labelled band: the label needs the Unicode message
    dim hFind as HWND = pWindow.AddControl( "Edit", hWin, IDC_FIND, "", 0, 0, 160, 22 )
    dim wszLabel as wstring * 16 = "Find"
    dim rbFind as REBARBANDINFOW
    rbFind.cbSize = REBARBANDINFO_V6_SIZE
    rbFind.fMask = RBBIM_STYLE or RBBIM_CHILD or RBBIM_CHILDSIZE or RBBIM_SIZE or RBBIM_TEXT or RBBIM_ID
    rbFind.fStyle = RBBS_CHILDEDGE
    rbFind.hwndChild = hFind
    rbFind.cxMinChild = 100 : rbFind.cyMinChild = GetWindowHeight( hFind )
    rbFind.cx = 220
    rbFind.lpText = @wszLabel
    rbFind.wID = ID_BAND_FIND
    SendMessageW( hRebar, RB_INSERTBANDW, -1, cast( LPARAM, @rbFind ) )

    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_SIZE
            SendMessageW( GetDlgItem( hwnd, IDC_REBAR ), WM_SIZE, 0, 0 )
            return 0
        case WM_COMMAND
            if CBCTL( wParam, lParam ) = IDM_SWAP then
                dim hRebar as HWND = GetDlgItem( hwnd, IDC_REBAR )
                Rebar.MoveBand( hRebar, 0, 1 )
                SetWindowText( hwnd, "Find is band " & Rebar.IdToIndex( hRebar, ID_BAND_FIND ) & _
                                     ", rebar height " & Rebar.GetBarHeight( hRebar ) )
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
| [InsertBand](#insertband) | Inserts a band. |
| [DeleteBand](#deleteband) | Deletes a band. |
| [GetBandCount](#getbandcount) | Returns the number of bands. |
| [GetBandInfo](#getbandinfo) | Reads a band's attributes into a `REBARBANDINFOW`. |
| [SetBandInfo](#setbandinfo) | Changes a band's attributes from a `REBARBANDINFOW`. |
| [IdToIndex](#idtoindex) | Returns the index of the band with an identifier. |
| [MoveBand](#moveband) | Moves a band to another index. |
| [ShowBand](#showband) | Shows or hides a band. |
| [MaximizeBand](#maximizeband) | Widens a band to its ideal or largest width. |
| [MinimizeBand](#minimizeband) | Narrows a band to its smallest width. |
| [SetBandWidth](#setbandwidth) | Sets the width of a band. |
| [GetRect](#getrect) | Returns the rectangle of a band. |
| [GetBandBorders](#getbandborders) | Returns the borders of a band. |
| [GetBandMargins](#getbandmargins) | Returns the margins around band children. |
| [GetBarHeight](#getbarheight) | Returns the height of the rebar. |
| [GetRowCount](#getrowcount) | Returns the number of rows of bands. |
| [GetRowHeight](#getrowheight) | Returns the height of a row. |
| [SizeToRect](#sizetorect) | Lays the bands out to fit a rectangle. |
| [HitTest](#hittest) | Finds the band, and the part of it, at a point. |
| [GetBarInfo](#getbarinfo) | Reads the rebar's image list. |
| [SetBarInfo](#setbarinfo) | Sets the rebar's image list. |
| [GetBkColor](#getbkcolor) | Returns the default band background colour. |
| [SetBkColor](#setbkcolor) | Sets the default band background colour. |
| [GetTextColor](#gettextcolor) | Returns the default band text colour. |
| [SetTextColor](#settextcolor) | Sets the default band text colour. |
| [GetColorScheme](#getcolorscheme) | Reads the highlight and shadow colours. |
| [SetColorScheme](#setcolorscheme) | Sets the highlight and shadow colours. |
| [GetPalette](#getpalette) | Returns the rebar's palette. |
| [SetPalette](#setpalette) | Sets the rebar's palette. |
| [GetTooltips](#gettooltips) | Returns the rebar's tooltip control. |
| [SetTooltips](#settooltips) | Gives the rebar a tooltip control. |
| [SetParent](#setparent) | Sets the window that receives the rebar's notifications. |
| [SetWindowTheme](#setwindowtheme) | Gives the rebar a visual style by name. |
| [SetDarkMode, RemoveDarkMode](#setdarkmode-removedarkmode) | Gives the rebar the dark theme, or its normal one. |
| [BeginDrag, DragMove, EndDrag](#begindrag-dragmove-enddrag) | Drag a band from code. |
| [PushChevron](#pushchevron) | Pushes a band's chevron from code. |
| [GetDropTarget](#getdroptarget) | Returns the rebar's `IDropTarget`. |

## Reference

### InsertBand

```freebasic
function InsertBand overload( byval hRebar as HWND, byval nIndex as long, byval prbbi as REBARBANDINFOW ptr ) as boolean
function InsertBand overload( byval hRebar as HWND, byval nIndex as long, byref rbbi as REBARBANDINFOW ) as boolean
```

Inserts a band before the band at index `nIndex`; -1 adds it after the last. Fill in the members
the band needs and name them in `fMask`; `cbSize` is set for you. For a band holding a child,
`hwndChild` with `RBBIM_CHILD`, and its smallest size, `cxMinChild` and `cyMinChild`, with
`RBBIM_CHILDSIZE`. `cx` (`RBBIM_SIZE`) is the band's width. `fStyle` (`RBBIM_STYLE`) takes `RBBS_*`
styles such as `RBBS_CHILDEDGE`, `RBBS_GRIPPERALWAYS`, `RBBS_NOGRIPPER`, `RBBS_BREAK` (start a
new row), `RBBS_FIXEDSIZE` and `RBBS_USECHEVRON`.

**Returns** `true` on success.

**Example**

```freebasic
dim rbbi as REBARBANDINFOW
rbbi.fMask = RBBIM_CHILD or RBBIM_CHILDSIZE or RBBIM_SIZE or RBBIM_ID
rbbi.hwndChild = GetDlgItem( hwnd, 101 ) : rbbi.cxMinChild = 120 : rbbi.cyMinChild = 24
rbbi.cx = 200 : rbbi.wID = 3
Rebar.InsertBand( hCtrl, -1, rbbi )
```

Microsoft Learn: [RB_INSERTBAND](https://learn.microsoft.com/en-us/windows/win32/controls/rb-insertband)

### DeleteBand

```freebasic
function DeleteBand( byval hRebar as HWND, byval uBand as DWORD ) as boolean
```

Deletes the band at index `uBand`. Its child window is not destroyed: it stays a child of the
rebar, hidden, for you to reuse or destroy.

**Returns** `true` on success.

**Example**

```freebasic
Rebar.DeleteBand( hCtrl, Rebar.IdToIndex( hCtrl, 3 ) )
```

Microsoft Learn: [RB_DELETEBAND](https://learn.microsoft.com/en-us/windows/win32/controls/rb-deleteband)

### GetBandCount

```freebasic
function GetBandCount( byval hRebar as HWND ) as DWORD
```

**Returns** the number of bands, hidden ones included.

**Example**

```freebasic
print Rebar.GetBandCount( hCtrl ); " bands"
```

Microsoft Learn: [RB_GETBANDCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getbandcount)

### GetBandInfo

```freebasic
function GetBandInfo overload( byval hRebar as HWND, byval uBand as DWORD, byval prbbi as REBARBANDINFOW ptr ) as boolean
function GetBandInfo overload( byval hRebar as HWND, byval uBand as DWORD, byref rbbi as REBARBANDINFOW ) as boolean
```

Reads the attributes that `fMask` asks for of the band at index `uBand`; `cbSize` is set for you.
For the text, point `lpText` at a buffer and set `cch`.

**Returns** `true` on success.

**Example**

```freebasic
dim rbbi as REBARBANDINFOW
rbbi.fMask = RBBIM_ID or RBBIM_SIZE or RBBIM_CHILD
if Rebar.GetBandInfo( hCtrl, 0, rbbi ) then print "band"; rbbi.wID; " is"; rbbi.cx; " wide"
```

Microsoft Learn: [RB_GETBANDINFO](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getbandinfo)

### SetBandInfo

```freebasic
function SetBandInfo overload( byval hRebar as HWND, byval uBand as DWORD, byval prbbi as REBARBANDINFOW ptr ) as boolean
function SetBandInfo overload( byval hRebar as HWND, byval uBand as DWORD, byref rbbi as REBARBANDINFOW ) as boolean
```

Changes the attributes that `fMask` names of the band at index `uBand`; the others stay as they
are. `cbSize` is set for you.

**Returns** `true` on success.

**Example**

```freebasic
dim rbbi as REBARBANDINFOW
rbbi.fMask = RBBIM_STYLE : rbbi.fStyle = RBBS_CHILDEDGE or RBBS_BREAK   ' start a new row
Rebar.SetBandInfo( hCtrl, 1, rbbi )
dim lbl as REBARBANDINFOW
lbl.cbSize = REBARBANDINFO_V6_SIZE : lbl.fMask = RBBIM_TEXT : lbl.lpText = @wstr( "Search" )
SendMessageW( hCtrl, RB_SETBANDINFOW, 1, cast( LPARAM, @lbl ) )
```

Microsoft Learn: [RB_SETBANDINFO](https://learn.microsoft.com/en-us/windows/win32/controls/rb-setbandinfo)

### IdToIndex

```freebasic
function IdToIndex( byval hRebar as HWND, byval uBandID as DWORD ) as long
```

**Returns** the index of the band whose identifier (`wID`) is `uBandID`, the first one if several
share it, or -1 when there is none.

**Example**

```freebasic
dim i as long = Rebar.IdToIndex( hCtrl, 2 )
if i >= 0 then Rebar.ShowBand( hCtrl, i, false )
```

Microsoft Learn: [RB_IDTOINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/rb-idtoindex)

### MoveBand

```freebasic
function MoveBand( byval hRebar as HWND, byval nFrom as DWORD, byval nTo as DWORD ) as boolean
```

Moves the band at index `nFrom` to index `nTo`.

**Returns** `true` on success.

**Example**

```freebasic
Rebar.MoveBand( hCtrl, 0, Rebar.GetBandCount( hCtrl ) - 1 )   ' first to last
```

Microsoft Learn: [RB_MOVEBAND](https://learn.microsoft.com/en-us/windows/win32/controls/rb-moveband)

### ShowBand

```freebasic
function ShowBand( byval hRebar as HWND, byval uBand as DWORD, byval fShow as boolean ) as boolean
```

Shows (`fShow` `true`) or hides the band at index `uBand`. A hidden band keeps its index and still
counts in [GetBandCount](#getbandcount).

**Returns** `true` on success.

**Example**

```freebasic
Rebar.ShowBand( hCtrl, 1, false )
```

Microsoft Learn: [RB_SHOWBAND](https://learn.microsoft.com/en-us/windows/win32/controls/rb-showband)

### MaximizeBand

```freebasic
sub MaximizeBand( byval hRebar as HWND, byval uBand as DWORD, byval fIdeal as boolean )
```

Widens the band at index `uBand`: to its ideal width (`cxIdeal`) when `fIdeal` is `true`, or as
far as the row allows when it is `false`.

**Example**

```freebasic
Rebar.MaximizeBand( hCtrl, 0, true )
```

Microsoft Learn: [RB_MAXIMIZEBAND](https://learn.microsoft.com/en-us/windows/win32/controls/rb-maximizeband)

### MinimizeBand

```freebasic
sub MinimizeBand( byval hRebar as HWND, byval uBand as DWORD )
```

Narrows the band at index `uBand` to its smallest width.

**Example**

```freebasic
Rebar.MinimizeBand( hCtrl, 0 )
```

Microsoft Learn: [RB_MINIMIZEBAND](https://learn.microsoft.com/en-us/windows/win32/controls/rb-minimizeband)

### SetBandWidth

```freebasic
function SetBandWidth( byval hRebar as HWND, byval uBand as DWORD, byval nWidth as DWORD ) as boolean
```

Sets the width of the band at index `uBand` to `nWidth` pixels. This function is only compiled
when the Windows headers target exactly Windows 8, which the toolchain's do not (they target
Windows 10), so a call to `Rebar.SetBandWidth` stops with "the namespace 'rebar' has no member
named 'setbandwidth'". Send the message instead, as in the example.

**Returns** `true` on success.

**Example**

```freebasic
SendMessageW( hCtrl, RB_SETBANDWIDTH, 0, 180 )   ' what Rebar.SetBandWidth( hCtrl, 0, 180 ) sends
```

Microsoft Learn: [RB_SETBANDWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/rb-setbandwidth)

### GetRect

```freebasic
function GetRect overload( byval hRebar as HWND, byval uBand as DWORD, byval prc as RECT ptr ) as boolean
function GetRect overload( byval hRebar as HWND, byval uBand as DWORD, byref rc as RECT ) as boolean
function GetRect overload( byval hRebar as HWND, byval uBand as DWORD ) as ( long, long, long, long )
```

Reads the rectangle of the band at index `uBand`, in client coordinates of the rebar. The third
form returns `( left, top, right, bottom )` and leaves the message's result in `GetLastError()`:
nonzero on success, 0 on failure.

**Returns** `true` on success (first two forms); the four edges (third form).

**Example**

```freebasic
var (l, t, r, b) = Rebar.GetRect( hCtrl, 0 )
if GetLastError() then print "band 0:"; r - l; " x"; b - t
```

Microsoft Learn: [RB_GETRECT](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getrect)

### GetBandBorders

```freebasic
sub GetBandBorders overload( byval hRebar as HWND, byval uBand as DWORD, byval prc as RECT ptr )
sub GetBandBorders overload( byval hRebar as HWND, byval uBand as DWORD, byref rc as RECT )
function GetBandBorders overload( byval hRebar as HWND, byval uBand as DWORD ) as ( long, long, long, long )
```

Reads the borders of the band at index `uBand`: the space its gripper, label and edges take on
each side. These are thicknesses, not a rectangle: `left` is how far the child starts from the
band's left edge, and so on. Subtract them from [GetRect](#getrect) for the area the child gets.
With `RBS_BANDBORDERS` all four are set; without it only `left` is.

**Returns** the four thicknesses as `( left, top, right, bottom )` (third form).

**Example**

```freebasic
var (bl, bt, br, bb) = Rebar.GetBandBorders( hCtrl, 0 )
print "the child starts"; bl; " pixels in"
```

Microsoft Learn: [RB_GETBANDBORDERS](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getbandborders)

### GetBandMargins

```freebasic
sub GetBandMargins overload( byval hRebar as HWND, byval pMargins as MARGINS ptr )
sub GetBandMargins overload( byval hRebar as HWND, byref _margins as MARGINS )
function GetBandMargins overload( byval hRebar as HWND ) as MARGINS
```

Reads the margins the visual style puts around the child window of each band. Needs version 6 of
the common controls.

**Returns** the margins (third form).

**Example**

```freebasic
dim m as MARGINS = Rebar.GetBandMargins( hCtrl )
print m.cxLeftWidth; m.cxRightWidth; m.cyTopHeight; m.cyBottomHeight
```

Microsoft Learn: [RB_GETBANDMARGINS](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getbandmargins)

### GetBarHeight

```freebasic
function GetBarHeight( byval hRebar as HWND ) as DWORD
```

**Returns** the height of the rebar in pixels, all its rows together. Use it to lay out the rest
of the client area below the rebar.

**Example**

```freebasic
dim y as long = Rebar.GetBarHeight( hCtrl )
MoveWindow( GetDlgItem( hwnd, 200 ), 0, y, GetWindowClientWidth( hwnd ), GetWindowClientHeight( hwnd ) - y, CTRUE )
```

Microsoft Learn: [RB_GETBARHEIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getbarheight)

### GetRowCount

```freebasic
function GetRowCount( byval hRebar as HWND ) as DWORD
```

**Returns** the number of rows of bands.

**Example**

```freebasic
print Rebar.GetRowCount( hCtrl ); " rows"
```

Microsoft Learn: [RB_GETROWCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getrowcount)

### GetRowHeight

```freebasic
function GetRowHeight( byval hRebar as HWND, byval uRow as DWORD ) as DWORD
```

**Returns** the height in pixels of the row that holds the band at index `uRow`. Despite the
name, the number is a band index, not a row number.

**Example**

```freebasic
print "row of band 0:"; Rebar.GetRowHeight( hCtrl, 0 ); " pixels high"
```

Microsoft Learn: [RB_GETROWHEIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getrowheight)

### SizeToRect

```freebasic
function SizeToRect overload( byval hRebar as HWND, byval prc as RECT ptr ) as boolean
function SizeToRect overload( byval hRebar as HWND, byref rc as RECT ) as boolean
```

Lays the bands out, wrapping them onto rows as needed, to fit as closely as it can the rectangle
given, in client coordinates of the parent.

**Returns** `true` when the layout changed (first two forms); the rectangle (third form).

**Example**

```freebasic
dim rc as RECT = ( 0, 0, 300, 80 )
if Rebar.SizeToRect( hCtrl, rc ) then print "bands rearranged"
```

Microsoft Learn: [RB_SIZETORECT](https://learn.microsoft.com/en-us/windows/win32/controls/rb-sizetorect)

### HitTest

```freebasic
function HitTest( byval hRebar as HWND, byref rhbt as RBHITTESTINFO ) as long
```

Finds the band at the point `rhbt.pt`, given in client coordinates of the rebar. The rebar fills
in `iBand` and, in `flags`, the part of the band the point is on: `RBHT_CAPTION`, `RBHT_CLIENT`,
`RBHT_GRABBER`, `RBHT_CHEVRON` or `RBHT_NOWHERE`.

**Returns** the index of the band at the point, or -1 when there is none.

**Example**

```freebasic
dim ht as RBHITTESTINFO
GetCursorPos( @ht.pt ) : ScreenToClient( hCtrl, @ht.pt )
if Rebar.HitTest( hCtrl, ht ) >= 0 andalso ht.flags = RBHT_GRABBER then print "on the gripper of band"; ht.iBand
```

Microsoft Learn: [RB_HITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/rb-hittest)

### GetBarInfo

```freebasic
function GetBarInfo overload( byval hRebar as HWND, byval prbi as REBARINFO ptr ) as boolean
function GetBarInfo overload( byval hRebar as HWND, byref rbi as REBARINFO ) as boolean
function GetBarInfo overload( byval hRebar as HWND ) as REBARINFO
```

Reads the rebar's image list (`himl`, asked for with `RBIM_IMAGELIST` in `fMask`): the images
bands show with `RBBIM_IMAGE`. `cbSize` is set for you. The third form sends `fMask` 0, so only
`cbSize` comes back set; use one of the first two.

**Returns** `true` on success (first two forms); the structure (third form).

**Example**

```freebasic
dim rbi as REBARINFO
rbi.fMask = RBIM_IMAGELIST
if Rebar.GetBarInfo( hCtrl, rbi ) andalso rbi.himl then print ImageList_GetImageCount( rbi.himl ); " images"
```

Microsoft Learn: [RB_GETBARINFO](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getbarinfo)

### SetBarInfo

```freebasic
function SetBarInfo overload( byval hRebar as HWND, byval prbi as REBARINFO ptr ) as boolean
function SetBarInfo overload( byval hRebar as HWND, byref rbi as REBARINFO ) as boolean
```

Gives the rebar an image list, with `RBIM_IMAGELIST` in `fMask`; `cbSize` is set for you. The
list stays yours to destroy, after the rebar.

**Returns** `true` on success.

**Example**

```freebasic
dim rbi as REBARINFO
rbi.fMask = RBIM_IMAGELIST
rbi.himl = ImageList_Create( 16, 16, ILC_COLOR32 or ILC_MASK, 4, 0 )
Rebar.SetBarInfo( hCtrl, rbi )
```

Microsoft Learn: [RB_SETBARINFO](https://learn.microsoft.com/en-us/windows/win32/controls/rb-setbarinfo)

### GetBkColor

```freebasic
function GetBkColor( byval hRebar as HWND ) as COLORREF
```

**Returns** the background colour bands get when they do not set their own (`RBBIM_COLORS`).
A new rebar returns `CLR_NONE` (&hFFFFFFFF): the visual style or the system colour is used.

**Example**

```freebasic
if Rebar.GetBkColor( hCtrl ) = CLR_NONE then print "default background"
```

Microsoft Learn: [RB_GETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getbkcolor)

### SetBkColor

```freebasic
function SetBkColor( byval hRebar as HWND, byval clrBk as DWORD ) as DWORD
```

Sets the default background colour of bands, a `COLORREF`. With visual styles active the theme
paints the bands and this colour may not show.

**Returns** the previous colour.

**Example**

```freebasic
Rebar.SetBkColor( hCtrl, RGB_OLDLACE )
```

Microsoft Learn: [RB_SETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/rb-setbkcolor)

### GetTextColor

```freebasic
function GetTextColor( byval hRebar as HWND ) as COLORREF
```

**Returns** the default colour of band labels; `CLR_NONE` in a new rebar.

**Example**

```freebasic
print hex( Rebar.GetTextColor( hCtrl ) )
```

Microsoft Learn: [RB_GETTEXTCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/rb-gettextcolor)

### SetTextColor

```freebasic
function SetTextColor( byval hRebar as HWND, byval clrText as COLORREF ) as COLORREF
```

Sets the default colour of band labels.

**Returns** the previous colour.

**Example**

```freebasic
Rebar.SetTextColor( hCtrl, RGB_NAVY )
```

Microsoft Learn: [RB_SETTEXTCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/rb-settextcolor)

### GetColorScheme

```freebasic
function GetColorScheme overload( byval hRebar as HWND, byval pcs as COLORSCHEME ptr ) as boolean
function GetColorScheme overload( byval hRebar as HWND, byref cs as COLORSCHEME ) as boolean
function GetColorScheme overload( byval hRebar as HWND ) as COLORSCHEME
```

Reads the colours the rebar draws highlights and shadows with (`clrBtnHighlight`,
`clrBtnShadow`); `dwSize` is set for you. `CLR_DEFAULT` means the system colour.

**Returns** `true` on success (first form); the colours (third
form).

**Example**

```freebasic
dim cs as COLORSCHEME
if Rebar.GetColorScheme( hCtrl, @cs ) then print hex( cs.clrBtnHighlight )
print hex( Rebar.GetColorScheme( hCtrl ).clrBtnShadow )
```

Microsoft Learn: [RB_GETCOLORSCHEME](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getcolorscheme)

### SetColorScheme

```freebasic
sub SetColorScheme overload( byval hRebar as HWND, byval pcs as COLORSCHEME ptr )
sub SetColorScheme overload( byval hRebar as HWND, byref cs as COLORSCHEME )
```

Sets the highlight and shadow colours; `dwSize` is set for you.

**Example**

```freebasic
dim cs as COLORSCHEME
cs.clrBtnHighlight = RGB_WHITE : cs.clrBtnShadow = RGB_GRAY
Rebar.SetColorScheme( hCtrl, @cs )
```

Microsoft Learn: [RB_SETCOLORSCHEME](https://learn.microsoft.com/en-us/windows/win32/controls/rb-setcolorscheme)

### GetPalette

```freebasic
function GetPalette( byval hRebar as HWND ) as HPALETTE
```

**Returns** the palette the rebar draws with on a palette display, or `NULL` when it has none.

**Example**

```freebasic
dim hPal as HPALETTE = Rebar.GetPalette( hCtrl )
```

Microsoft Learn: [RB_GETPALETTE](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getpalette)

### SetPalette

```freebasic
function SetPalette( byval hRebar as HWND, byval hPal as HPALETTE ) as HPALETTE
```

Sets the palette the rebar draws with.

**Returns** the previous palette, or `NULL`.

**Example**

```freebasic
dim hOld as HPALETTE = Rebar.SetPalette( hCtrl, GetStockObject( DEFAULT_PALETTE ) )
```

Microsoft Learn: [RB_SETPALETTE](https://learn.microsoft.com/en-us/windows/win32/controls/rb-setpalette)

### GetTooltips

```freebasic
function GetTooltips( byval hRebar as HWND ) as HWND
```

**Returns** the rebar's tooltip control, or `NULL` when it has none, as a new rebar made by
`CWindow.AddControl` does not.

**Example**

```freebasic
dim hTip as HWND = Rebar.GetTooltips( hCtrl )
if hTip = NULL then print "no tooltips"
```

Microsoft Learn: [RB_GETTOOLTIPS](https://learn.microsoft.com/en-us/windows/win32/controls/rb-gettooltips)

### SetTooltips

```freebasic
sub SetTooltips( byval hRebar as HWND, byval hwndToolTip as HWND )
```

Gives the rebar the tooltip control `hwndToolTip`.

**Example**

```freebasic
dim hTip as HWND = CreateWindowExW( 0, TOOLTIPS_CLASSW, NULL, TTS_ALWAYSTIP, 0, 0, 0, 0, hwnd, NULL, NULL, NULL )
Rebar.SetTooltips( hCtrl, hTip )
```

Microsoft Learn: [RB_SETTOOLTIPS](https://learn.microsoft.com/en-us/windows/win32/controls/rb-settooltips)

### SetParent

```freebasic
function SetParent( byval hRebar as HWND, byval hwndParent as HWND ) as HWND
```

Sets the window that receives the rebar's notifications. The rebar's parent window, and where it
is drawn, stay as they are.

**Returns** the previous notification window, or `NULL`.

**Example**

```freebasic
Rebar.SetParent( hCtrl, hwnd )
```

Microsoft Learn: [RB_SETPARENT](https://learn.microsoft.com/en-us/windows/win32/controls/rb-setparent)

### SetWindowTheme

```freebasic
sub SetWindowTheme( byval hRebar as HWND, byval pwszTheme as wstring ptr )
```

Gives the rebar the visual style named `pwszTheme`, for example `"Explorer"`. Needs version 6 of
the common controls.

**Example**

```freebasic
Rebar.SetWindowTheme( hCtrl, "Explorer" )
```

Microsoft Learn: [RB_SETWINDOWTHEME](https://learn.microsoft.com/en-us/windows/win32/controls/rb-setwindowtheme)

### SetDarkMode, RemoveDarkMode

```freebasic
function SetDarkMode( byval hRebar as HWND ) as HRESULT
function RemoveDarkMode( byval hRebar as HWND ) as HRESULT
```

`SetDarkMode` gives the rebar the dark theme of Explorer's navigation bar (`DarkModeNavbar`);
`RemoveDarkMode` gives it back its normal visual style. A toolbar in the rebar needs its own
`ToolBar.SetDarkMode`.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
if AppsUseDarkMode() then Rebar.SetDarkMode( hCtrl ) else Rebar.RemoveDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

### BeginDrag, DragMove, EndDrag

```freebasic
sub BeginDrag( byval hRebar as HWND, byval uBand as DWORD, byval dwPos as DWORD )
sub DragMove( byval hRebar as HWND, byval dwPos as DWORD )
sub EndDrag( byval hRebar as HWND )
```

Drag a band from code, as the user does with the gripper. `BeginDrag` starts dragging the band at
index `uBand`; `DragMove` moves it; `EndDrag` drops it, without sending `RBN_ENDDRAG`. `dwPos`
packs a point in client coordinates of the rebar, x in the low word and y in the high word, or is
&hFFFFFFFF (-1) for the position of the last mouse message.

**Example**

```freebasic
Rebar.BeginDrag( hCtrl, 1, MAKELONG( 10, 5 ) )
Rebar.DragMove( hCtrl, MAKELONG( 140, 5 ) )
Rebar.EndDrag( hCtrl )
```

Microsoft Learn: [RB_BEGINDRAG](https://learn.microsoft.com/en-us/windows/win32/controls/rb-begindrag)

### PushChevron

```freebasic
sub PushChevron( byval hRebar as HWND, byval uBand as DWORD, byval iAppValue as DWORD )
```

Pushes the chevron of the band at index `uBand` as if it had been clicked, so that the rebar
sends its parent `RBN_CHEVRONPUSHED`, with `iAppValue` in the notification's `lParamNM`. The band
needs `RBBS_USECHEVRON` and a `cxIdeal` wider than it is shown.

**Example**

```freebasic
Rebar.PushChevron( hCtrl, 0, 0 )
```

Microsoft Learn: [RB_PUSHCHEVRON](https://learn.microsoft.com/en-us/windows/win32/controls/rb-pushchevron)

### GetDropTarget

```freebasic
function GetDropTarget( byval hRebar as HWND ) as IDropTarget ptr
```

**Returns** the rebar's `IDropTarget`, the interface it uses when something is dragged over it.
Each call adds a reference: call `Release` on the pointer when done.

**Example**

```freebasic
dim pDropTarget as IDropTarget ptr = Rebar.GetDropTarget( hCtrl )
if pDropTarget then pDropTarget->lpVtbl->Release( pDropTarget )
```

Microsoft Learn: [RB_GETDROPTARGET](https://learn.microsoft.com/en-us/windows/win32/controls/rb-getdroptarget)

## See also

- [sys/win/gui](SysWin-Gui)
- [ToolBar](SysWin-Gui-ToolBar) for the toolbars that go in the bands
- [CWindow](CWindow) for `AddControl( "Rebar", ... )`
- [Combo](SysWin-Gui-Combo) and [Edit](SysWin-Gui-Edit) for other band children
- [gui macros and helpers](SysWin-Gui-Procedures) for reading `WM_COMMAND` and `WM_NOTIFY`
- [Dark mode](SysWin-Dark-Mode)
