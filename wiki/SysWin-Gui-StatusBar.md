[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **StatusBar**

# StatusBar

Divides a status bar into parts and sets and reads their text, icons and tooltips.

A status bar is the strip along the bottom of a window that reports what the program is doing.
Every function here takes the control's handle first and is written with the namespace:
`StatusBar.SetText( hStatus, 0, "Ready" )`. Create the control with
`CWindow.AddControl( "StatusBar", hWin, id )`, which puts it at the bottom with a size grip;
pass `SBARS_TOOLTIPS` as the style to get the same plus tooltips for its parts.

The bar is split into **parts**, numbered from 0 on the left. Each part is set by the
x coordinate of its right edge, in the bar's client coordinates; -1 makes a part reach the
right edge of the window. In **simple mode** ([Simple](#simple)) the bar shows one part holding
its own text, and the parts and their text come back when simple mode ends.

The bar sizes and places itself. When the window changes size, pass `WM_SIZE` on to it (or
anchor it with `CWindow.AnchorControl( id, ANCHOR_BOTTOM_WIDTH )`). Icons and fonts given to
the bar stay the program's to destroy. In the examples on this page, `hCtrl` is a status bar.

Tooltips ([SetTipText](#settiptext), [GetTipText](#gettiptext)) need the `SBARS_TOOLTIPS`
style and appear for parts whose text is cut off or that hold only an icon. With version 5 of
the common controls, which a program gets when it has neither a manifest nor
`EnableVisualStyles()`, asking for the tip text of a part that has none ended the program;
with version 6 it leaves the buffer as it was.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A window with a three-part status bar: a message on the left, the mouse position in the middle
and the client size on the right, kept up to date as the mouse moves and the window is resized.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_STATUS = 101

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    EnableVisualStyles()
    dim pWindow as CWindow = "StatusDemo"
    dim hWin as HWND = pWindow.Create( NULL, "StatusBar", @WndProc )
    dim hStatus as HWND = pWindow.AddControl( "StatusBar", hWin, IDC_STATUS, "", 0, 0, 0, 0, SBARS_TOOLTIPS )
    StatusBar.SetParts( hStatus, "160,110,-1" )
    StatusBar.SetText( hStatus, 0, "Ready" )
    StatusBar.SetTipText( hStatus, 0, "What the program is doing" )
    pWindow.SetClientSize( 420, 220 )
    pWindow.Center()
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_MOUSEMOVE
            dim hStatus as HWND = GetDlgItem( hwnd, IDC_STATUS )
            StatusBar.SetText( hStatus, 1, GET_X_LPARAM( lParam ) & ", " & GET_Y_LPARAM( lParam ) )
            return 0
        case WM_SIZE
            dim hStatus as HWND = GetDlgItem( hwnd, IDC_STATUS )
            if hStatus then
                SendMessageW( hStatus, WM_SIZE, wParam, lParam )
                StatusBar.SetText( hStatus, 2, LOWORD( lParam ) & " x " & HIWORD( lParam ) )
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
| [SetParts](#setparts) | Divides the bar into parts, from right edges or from a list of widths. |
| [GetParts](#getparts) | Reads the right edges of the parts and returns how many there are. |
| [GetPartsCount](#getpartscount) | Returns the number of parts. |
| [SetText](#settext) | Sets a part's text and how it is drawn. |
| [GetText](#gettext) | Returns or reads a part's text. |
| [GetTextLength](#gettextlength) | Returns the length of a part's text. |
| [GetTextDrawingMode](#gettextdrawingmode) | Returns the `SBT_*` flags a part's text was set with. |
| [SetTipText](#settiptext) | Sets a part's tooltip text. |
| [GetTipText](#gettiptext) | Returns or reads a part's tooltip text. |
| [SetIcon](#seticon) | Shows an icon in a part, or removes it. |
| [GetIcon](#geticon) | Returns a part's icon. |
| [GetRect](#getrect) | Returns the rectangle of a part. |
| [GetBorders](#getborders) | Returns the widths of the bar's borders. |
| [GetHeight](#getheight) | Returns the height of the bar. |
| [SetMinHeight](#setminheight) | Sets the smallest height of the bar's drawing area. |
| [Simple](#simple) | Switches the bar between one simple part and its parts. |
| [IsSimple](#issimple) | Tells whether the bar is in simple mode. |
| [SetBkColor](#setbkcolor) | Sets the background colour. |
| [SetFont](#setfont) | Sets the font of the text. |
| [SetUnicodeFormat](#setunicodeformat) | Clears the tooltip text of part 0 or of another part. |

## Reference

### SetParts

```freebasic
function SetParts overload( byval hStatusBar as HWND, byval dwParts as DWORD, byval rgWidths as long ptr ) as boolean
function SetParts overload( byval hStatusBar as HWND, byref strSizes as string ) as boolean
```

Divide the bar into parts. The first form takes an array of `dwParts` right edges (at most
256), in pixels from the bar's left side; -1 as the last edge stretches the last part to the
window's edge.

The second form takes the **widths** as a comma-separated list, scales each from 96 DPI to the
desktop's DPI and adds them up into right edges: `"100,50,-1"` gives edges 100, 150 and -1 at
96 DPI. A width of 0 or less, after the first, makes that part stretch to the edge, so put it
last. It also ends simple mode. A list with one width or none does not make one part: it puts
the bar in simple mode instead.

| Parameter | Meaning |
| --- | --- |
| `dwParts` | The number of parts. |
| `rgWidths` | The right edge of each part. |
| `strSizes` | The widths, for example `"120,80,-1"`. |

**Returns** `true` on success.

**Example**

```freebasic
StatusBar.SetParts( hCtrl, "100,50,-1" )
dim edges(0 to 1) as long = { 200, -1 }
StatusBar.SetParts( hCtrl, 2, @edges(0) )
```

Microsoft Learn: [SB_SETPARTS](https://learn.microsoft.com/en-us/windows/win32/controls/sb-setparts)

### GetParts

```freebasic
function GetParts( byval hStatusBar as HWND, byval nParts as DWORD, byval rgRightCoords as long ptr ) as long
```

Reads the right edges of up to `nParts` parts into an array, as [SetParts](#setparts) took them
(-1 for a part that reaches the edge). Pass 0 and `NULL` to get only the count.

**Returns** the number of parts in the bar.

**Example**

```freebasic
StatusBar.SetParts( hCtrl, "100,50,-1" )
dim edges(0 to 2) as long
StatusBar.GetParts( hCtrl, 3, @edges(0) )
print edges(0); edges(1); edges(2)   ' 100 150 -1 at 96 DPI
```

Microsoft Learn: [SB_GETPARTS](https://learn.microsoft.com/en-us/windows/win32/controls/sb-getparts)

### GetPartsCount

```freebasic
function GetPartsCount( byval hStatusBar as HWND ) as DWORD
```

Returns the number of parts.

**Returns** the count.

**Example**

```freebasic
print StatusBar.GetPartsCount( hCtrl )
```

### SetText

```freebasic
function SetText( byval hStatusBar as HWND, byval nPart as long, byval pwszText as wstring ptr, byval uType as DWORD = 0 ) as boolean
```

Sets the text of a part. Tabs split it: text before the first tab is left-aligned, after the
first centred and after the second right-aligned. In simple mode, set the simple text with
`nPart = SB_SIMPLEID`.

| Parameter | Meaning |
| --- | --- |
| `nPart` | The part, from 0, or `SB_SIMPLEID`. |
| `pwszText` | The text; with `SBT_OWNERDRAW`, a value passed to the parent in `WM_DRAWITEM`. |
| `uType` | 0 (sunken), or `SBT_NOBORDERS`, `SBT_POPOUT` (raised), `SBT_OWNERDRAW`, `SBT_RTLREADING`, `SBT_NOTABPARSING`. |

**Returns** `true` on success.

**Example**

```freebasic
StatusBar.SetText( hCtrl, 0, "Ready" )
StatusBar.SetText( hCtrl, 1, "Ln 1", SBT_POPOUT )
StatusBar.SetText( hCtrl, 2, chr( 9 ) & "centred" )
```

Microsoft Learn: [SB_SETTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/sb-settext)

### GetText

```freebasic
function GetText overload( byval hStatusBar as HWND, byval nPart as DWORD, byval pwszText as wstring ptr ) as DWORD
function GetText overload( byval hStatusBar as HWND, byval nPart as DWORD ) as ustring
```

Returns the text of a part. In simple mode, part 0 holds the simple text. The first form copies
it into a buffer that must hold [GetTextLength](#gettextlength) characters plus the terminator.

**Returns** the text, or `""`; the first form returns the length in the low word and the
`SBT_*` flags in the high word (`&h2000004` for `"Ln 1"` set with `SBT_POPOUT`), or 0 for a
`NULL` buffer.

**Example**

```freebasic
print StatusBar.GetText( hCtrl, 0 )   ' Ready
dim wszText as wstring * 260
StatusBar.GetText( hCtrl, 1, @wszText )
```

Microsoft Learn: [SB_GETTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/sb-gettext)

### GetTextLength

```freebasic
function GetTextLength( byval hStatusBar as HWND, byval nPart as DWORD ) as long
```

Returns the length of a part's text in characters, without the terminator.

**Returns** the length.

**Example**

```freebasic
print StatusBar.GetTextLength( hCtrl, 0 )   ' 5 for "Ready"
```

Microsoft Learn: [SB_GETTEXTLENGTH](https://learn.microsoft.com/en-us/windows/win32/controls/sb-gettextlength)

### GetTextDrawingMode

```freebasic
function GetTextDrawingMode( byval hStatusBar as HWND, byval nPart as DWORD ) as long
```

Returns the `SBT_*` flags the part's text was set with, as `SBT_*` values: compare it with
`SBT_POPOUT`, `SBT_NOBORDERS` and the rest. 0 means sunken.

**Returns** the flags.

**Example**

```freebasic
if StatusBar.GetTextDrawingMode( hCtrl, 1 ) = SBT_POPOUT then print "raised"
```

### SetTipText

```freebasic
sub SetTipText( byval hStatusBar as HWND, byval nPart as long, byval pwszTipText as wstring ptr )
```

Sets the tooltip text of a part. The bar needs the `SBARS_TOOLTIPS` style; the tip appears when
the part's text does not fit or the part shows only an icon.

**Example**

```freebasic
StatusBar.SetTipText( hCtrl, 0, "What the program is doing" )
```

Microsoft Learn: [SB_SETTIPTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/sb-settiptext)

### GetTipText

```freebasic
sub GetTipText overload( byval hStatusBar as HWND, byval nPart as WORD, byval pwszText as wstring ptr, byval wLen as WORD )
function GetTipText overload( byval hStatusBar as HWND, byval nPart as WORD ) as ustring
```

Returns the tooltip text of a part. The first form copies at most `wLen` characters, terminator
included, into a buffer; a buffer smaller than `wLen` overflows. Ask only for parts whose tip
was set (see the introduction).

**Returns** the second form returns the text.

**Example**

```freebasic
StatusBar.SetTipText( hCtrl, 0, "Status" )
print StatusBar.GetTipText( hCtrl, 0 )   ' Status
dim wszTip as wstring * 64
StatusBar.GetTipText( hCtrl, 0, @wszTip, 64 )
```

Microsoft Learn: [SB_GETTIPTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/sb-gettiptext)

### SetIcon

```freebasic
function SetIcon( byval hStatusBar as HWND, byval nPart as long, byval hIcon as HICON ) as boolean
```

Shows an icon at the left of a part, or removes it with `NULL`. `nPart = -1` is the simple-mode
part. The bar does not copy or destroy the icon: keep it alive while it is shown and destroy it
yourself afterwards (a shared icon from `LoadIconW` needs no destroying).

**Returns** `true` on success.

**Example**

```freebasic
StatusBar.SetIcon( hCtrl, 0, LoadIconW( NULL, cast( wstring ptr, IDI_INFORMATION ) ) )
StatusBar.SetIcon( hCtrl, 0, NULL )
```

Microsoft Learn: [SB_SETICON](https://learn.microsoft.com/en-us/windows/win32/controls/sb-seticon)

### GetIcon

```freebasic
function GetIcon( byval hStatusBar as HWND, byval nPart as DWORD ) as HICON
```

Returns the icon of a part.

**Returns** the icon, or `NULL` when the part has none.

**Example**

```freebasic
dim hIcon as HICON = StatusBar.GetIcon( hCtrl, 0 )
```

Microsoft Learn: [SB_GETICON](https://learn.microsoft.com/en-us/windows/win32/controls/sb-geticon)

### GetRect

```freebasic
function GetRect overload( byval hStatusBar as HWND, byval nPart as DWORD, byval lprc as RECT ptr ) as boolean
function GetRect overload( byval hStatusBar as HWND, byval nPart as DWORD, byref rc as RECT ) as boolean
function GetRect overload( byval hStatusBar as HWND, byval nPart as DWORD ) as ( long, long, long, long )
```

Returns the rectangle of a part in the bar's client coordinates, borders excluded. Use it to
place a progress bar or another control over a part.

**Returns** `true` on success; the third form returns `( left, top, right, bottom )` and leaves
`GetLastError()` nonzero when the call succeeded and 0 when it failed.

**Example**

```freebasic
var (l, t, r, b) = StatusBar.GetRect( hCtrl, 1 )
if GetLastError() then print "part 1 is"; r - l; " pixels wide"
```

Microsoft Learn: [SB_GETRECT](https://learn.microsoft.com/en-us/windows/win32/controls/sb-getrect)

### GetBorders

```freebasic
function GetBorders overload( byval hStatusBar as HWND, byval rgBorders as long ptr ) as boolean
function GetBorders overload( byval hStatusBar as HWND ) as ( long, long, long )
```

Returns the widths of the bar's horizontal border, its vertical border and the gap between
parts, in pixels (0, 2 and 2 on a standard system). The first form needs an array of three
`long`s.

**Returns** `true` on success; the second form returns `( horizontal, vertical, between )` and
leaves `GetLastError()` nonzero when the call succeeded and 0 when it failed.

**Example**

```freebasic
var (bh, bv, bb) = StatusBar.GetBorders( hCtrl )
dim rgBorders(0 to 2) as long
StatusBar.GetBorders( hCtrl, @rgBorders(0) )
```

Microsoft Learn: [SB_GETBORDERS](https://learn.microsoft.com/en-us/windows/win32/controls/sb-getborders)

### GetHeight

```freebasic
function GetHeight( byval hStatusBar as HWND ) as long
```

Returns the height of the bar's window rectangle in pixels. Subtract it from the client height
to find the room left for the rest of the window.

**Returns** the height, or 0 for an invalid handle.

**Example**

```freebasic
dim cy as long = GetWindowClientHeight( hwnd ) - StatusBar.GetHeight( hCtrl )
```

### SetMinHeight

```freebasic
sub SetMinHeight( byval hStatusBar as HWND, byval minHeight as DWORD )
```

Sets the smallest height of the bar's drawing area, in pixels; the bar adds its borders to it
(a minimum of 40 gave a bar 42 pixels high). It takes effect when the bar next gets `WM_SIZE`.

**Example**

```freebasic
StatusBar.SetMinHeight( hCtrl, 40 )
SendMessageW( hCtrl, WM_SIZE, 0, 0 )
```

Microsoft Learn: [SB_SETMINHEIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/sb-setminheight)

### Simple

```freebasic
sub Simple( byval hStatusBar as HWND, byval fSimple as boolean )
```

With `true`, shows one part across the bar with its own text (set it with
[SetText](#settext) and `SB_SIMPLEID`), the usual way to show a menu item's help while a menu is
open. With `false`, brings back the parts and their text.

**Example**

```freebasic
StatusBar.Simple( hCtrl, true )
StatusBar.SetText( hCtrl, SB_SIMPLEID, "Opens a document" )
StatusBar.Simple( hCtrl, false )
```

Microsoft Learn: [SB_SIMPLE](https://learn.microsoft.com/en-us/windows/win32/controls/sb-simple)

### IsSimple

```freebasic
function IsSimple( byval hStatusBar as HWND ) as boolean
```

Tells whether the bar is in simple mode.

**Returns** `true` in simple mode.

**Example**

```freebasic
if StatusBar.IsSimple( hCtrl ) then StatusBar.Simple( hCtrl, false )
```

Microsoft Learn: [SB_ISSIMPLE](https://learn.microsoft.com/en-us/windows/win32/controls/sb-issimple)

### SetBkColor

```freebasic
function SetBkColor( byval hStatusBar as HWND, byval clrBk as COLORREF ) as COLORREF
```

Sets the background colour, a `COLORREF` such as an `RGB_*` constant; `CLR_DEFAULT` goes back to
the system colour. A bar drawn with visual styles ignores it.

**Returns** the previous colour, or `CLR_DEFAULT` (`&hFF000000`) when it was the default.

**Example**

```freebasic
StatusBar.SetBkColor( hCtrl, RGB_LIGHTYELLOW )
StatusBar.SetBkColor( hCtrl, CLR_DEFAULT )
```

Microsoft Learn: [SB_SETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/sb-setbkcolor)

### SetFont

```freebasic
sub SetFont( byval hStatusBar as HWND, byval hFont as HFONT, byval fRedraw as long = false )
```

Sets the font the bar draws its text with, redrawing it when `fRedraw` is `true`. The bar does
not destroy the font; keep it while the bar uses it.

**Example**

```freebasic
StatusBar.SetFont( hCtrl, GetStockObject( DEFAULT_GUI_FONT ), true )
```

Microsoft Learn: [WM_SETFONT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-setfont)

### SetUnicodeFormat

```freebasic
sub SetUnicodeFormat( byval hStatusBar as HWND, byval fFormat as boolean )
```

**Example**

```freebasic
StatusBar.SetUnicodeFormat( hCtrl, false )
SendMessageW( hCtrl, SB_SETUNICODEFORMAT, true, 0 )
```

Microsoft Learn: [SB_SETUNICODEFORMAT](https://learn.microsoft.com/en-us/windows/win32/controls/sb-setunicodeformat)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for `AddControl( "StatusBar", ... )` and anchoring
- [Menu](SysWin-Gui-Menu)
- [ToolTip](SysWin-Gui-ToolTip)
- [ProgBar](SysWin-Gui-ProgBar), a progress bar to place over a part with [GetRect](#getrect)
- [Display, screen and DPI](SysWin-Display-and-DPI) for the scaling [SetParts](#setparts) applies
