[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **ScrollBar**

# ScrollBar

Shows, hides, enables and positions a scroll bar control, and reads and sets its range.

These functions are for a **scroll bar control**, a window of its own that the program places
anywhere, not for the scroll bars along the edges of a window with `WS_HSCROLL` or `WS_VSCROLL`.
Create one with `CWindow.AddControl( "HScrollBar", ... )` or `"VScrollBar"`, which also sets a
range of 0 to 100 and the position 0. Every function here takes the control's handle first and
is written with the namespace: `ScrollBar.GetPos( hSB )`.

A scroll bar does not move its own thumb. When the user clicks or drags it, the parent receives
`WM_HSCROLL` (or `WM_VSCROLL`) with the scroll bar's handle in `lParam` and an `SB_*` request in
the low word of `wParam`; the program works out the new position and calls
[SetPos](#setpos). For a proportional thumb and 32-bit tracking positions use the Windows
function `SetScrollInfo` with `SB_CTL`.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A horizontal scroll bar from 0 to 255 that answers the arrows, the channel and the thumb, and
puts its value in the caption.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_SCROLL = 101

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "ScrollBarDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Value: 0", @WndProc )
    pWindow.SetClientSize( 340, 80 )
    pWindow.Center()
    dim hSB as HWND = pWindow.AddControl( "HScrollBar", hWin, IDC_SCROLL, "", 20, 30, 300, 20 )
    ScrollBar.SetRange( hSB, 0, 255, true )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_HSCROLL
            dim hSB as HWND = cast( HWND, lParam )
            if hSB = GetDlgItem( hwnd, IDC_SCROLL ) then
                dim as long nMin, nMax
                ScrollBar.GetRange( hSB, nMin, nMax )
                dim nPos as long = ScrollBar.GetPos( hSB )
                select case LOWORD( wParam )
                    case SB_LINELEFT : nPos -= 1
                    case SB_LINERIGHT : nPos += 1
                    case SB_PAGELEFT : nPos -= 16
                    case SB_PAGERIGHT : nPos += 16
                    case SB_THUMBTRACK, SB_THUMBPOSITION : nPos = HIWORD( wParam )
                    case SB_LEFT : nPos = nMin
                    case SB_RIGHT : nPos = nMax
                end select
                nPos = iif( nPos < nMin, nMin, iif( nPos > nMax, nMax, nPos ) )
                ScrollBar.SetPos( hSB, nPos, true )
                SetWindowText( hwnd, "Value: " & nPos )
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
| [GetPos](#getpos) | Returns the thumb's position. |
| [SetPos](#setpos) | Moves the thumb. |
| [GetRange](#getrange) | Reads the minimum and maximum positions. |
| [SetRange](#setrange) | Sets the minimum and maximum positions. |
| [Enable](#enable) | Enables or disables the arrows. |
| [Show](#show) | Shows, or shows or hides, the scroll bar. |
| [Hide](#hide) | Hides the scroll bar. |

## Reference

### GetPos

```freebasic
function GetPos( byval hSB as HWND ) as long
```

**Returns** the thumb's position, or 0 on failure.

**Example**

```freebasic
print "position:"; ScrollBar.GetPos( hCtrl )
```

Microsoft Learn: [GetScrollPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getscrollpos)

### SetPos

```freebasic
function SetPos( byval hSB as HWND, byval nPos as long, byval fRedraw as boolean ) as boolean
```

Moves the thumb to `nPos`, which should lie within the range; `fRedraw` `true` redraws the
scroll bar at once.

**Returns** If the function succeeds, the return value is the previous position of the scroll box. If the function fails, the return value is zero. To get extended error information, call [GetLastError](https://learn.microsoft.com/en-us/windows/desktop/api/errhandlingapi/nf-errhandlingapi-getlasterror).

**Example**

```freebasic
ScrollBar.SetPos( hCtrl, 50, true )
```

Microsoft Learn: [SetScrollPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setscrollpos)

### GetRange

```freebasic
function GetRange overload( byval hSB as HWND, byval posMin as long ptr, byval posMax as long ptr ) as boolean
function GetRange overload( byval hSB as HWND, byref posMin as long, byref posMax as long ) as boolean
```

Reads the minimum and maximum positions into `posMin` and `posMax`.

**Returns** `true` on success.

**Example**

```freebasic
dim as long nMin, nMax
if ScrollBar.GetRange( hCtrl, nMin, nMax ) then print "from"; nMin; " to"; nMax
```

Microsoft Learn: [GetScrollRange](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getscrollrange)

### SetRange

```freebasic
function SetRange( byval hSB as HWND, byval posMin as long, byval posMax as long, byval fRedraw as boolean ) as boolean
```

Sets the minimum and maximum positions; `fRedraw` `true` redraws the scroll bar.

**Returns** `true` on success.

**Example**

```freebasic
ScrollBar.SetRange( hCtrl, 0, 1000, true )
```

Microsoft Learn: [SetScrollRange](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setscrollrange)

### Enable

```freebasic
function Enable( byval hSB as HWND, byval flags as UINT ) as boolean
```

Enables or disables one or both arrows: `flags` is `ESB_ENABLE_BOTH`, `ESB_DISABLE_BOTH`,
`ESB_DISABLE_LEFT` (or `ESB_DISABLE_UP`) or `ESB_DISABLE_RIGHT` (`ESB_DISABLE_DOWN`).

**Returns** `true` when the arrows changed state; `false` when they were already in that state
or on failure.

**Example**

```freebasic
ScrollBar.Enable( hCtrl, ESB_DISABLE_BOTH )
```

Microsoft Learn: [EnableScrollBar](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablescrollbar)

### Show

```freebasic
function Show overload( byval hSB as HWND, byval fShow as boolean ) as boolean
function Show overload( byval hSB as HWND ) as boolean
```

Shows the scroll bar, or with `fShow` `false` hides it, with `ShowWindow`.

**Returns** whether the scroll bar was visible **before** the call, as `ShowWindow` does: not
whether the call succeeded.

**Example**

```freebasic
ScrollBar.Show( hCtrl, GetWindowClientWidth( hwnd ) < 400 )
```

Microsoft Learn: [ShowWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow)

### Hide

```freebasic
function Hide( byval hSB as HWND ) as boolean
```

Hides the scroll bar.

**Returns** `true` when it was visible before the call, `false` when it was already hidden.

**Example**

```freebasic
ScrollBar.Hide( hCtrl )
```

Microsoft Learn: [ShowWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for `AddControl( "HScrollBar", ... )`
- [TrackBar](SysWin-Gui-TrackBar), which moves its own thumb
- [Window size and position](SysWin-Window-Size-and-Position)
