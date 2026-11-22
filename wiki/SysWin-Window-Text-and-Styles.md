[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › **Window text and styles**

# Window text and styles

Reads and sets a window's text, class, styles and icon, and redraws windows.

A window's *text* is its caption for a top-level window, and the label or contents of a button,
static or edit control. Its *class* is the name it was registered under (`Button`, `Edit`, your
own window class), fixed for its life.

Its *styles* are two sets of bit flags: the window styles (`WS_*`, and the control's own
`BS_*`, `ES_*` … flags), read with `GetWindowLongPtrW( hwnd, GWL_STYLE )`, and the extended
styles (`WS_EX_*`), read with `GWL_EXSTYLE`. The style functions here change the flags and then
tell Windows to recalculate the frame, so a change to the border or caption shows at once. Some
flags only take effect when the window is created, and a few, such as `WS_EX_TOPMOST`, cannot be
set this way at all (use `SetWindowPos` with `HWND_TOPMOST`).

## Importing

```freebasic
#import "sys/win"
using win
```

## Example

A window with two buttons that switch its sizing border and its tool-window frame on and off,
showing the class name and the style flags in the caption:

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "StyleDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Window text and styles", @WndProc )
    SetWindowClientSizeForDpi( hWin, 360, 120 )
    CenterWindow( hWin )
    pWindow.AddControl( "Button", hWin, 100, "&Sizing border", 20, 40, 150, 30 )
    pWindow.AddControl( "Button", hWin, 101, "&Tool window", 190, 40, 150, 30 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                select case CBCTL( wParam, lParam )
                    case 100
                        if GetWindowLongPtrW( hwnd, GWL_STYLE ) and WS_THICKFRAME then
                            RemoveWindowStyle( hwnd, WS_THICKFRAME or WS_MAXIMIZEBOX )
                        else
                            AddWindowStyle( hwnd, WS_THICKFRAME or WS_MAXIMIZEBOX )
                        end if
                    case 101
                        if GetWindowLongPtrW( hwnd, GWL_EXSTYLE ) and WS_EX_TOOLWINDOW then
                            RemoveWindowExStyle( hwnd, WS_EX_TOOLWINDOW )
                        else
                            AddWindowExStyle( hwnd, WS_EX_TOOLWINDOW )
                        end if
                end select
                dim ustrCaption as ustring = GetWindowClassName( hwnd ) & ": style &h" & hex( GetWindowLongPtrW( hwnd, GWL_STYLE ) )
                SetWindowText( hwnd, ustrCaption )
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
| [GetWindowClassName](#getwindowclassname) | Returns the class name of a window. |
| [GetWindowText](#getwindowtext) | Returns the text of a window or control. |
| [SetWindowText](#setwindowtext) | Sets the text of a window or control. |
| [SetWindowStyle](#setwindowstyle) | Replaces all the window styles of a window. |
| [SetWindowExStyle](#setwindowexstyle) | Replaces all the extended styles of a window. |
| [AddWindowStyle](#addwindowstyle) | Adds window styles. |
| [AddWindowExStyle](#addwindowexstyle) | Adds extended styles. |
| [RemoveWindowStyle](#removewindowstyle) | Removes window styles. |
| [RemoveWindowExStyle](#removewindowexstyle) | Removes extended styles. |
| [SetWindowIcon](#setwindowicon) | Sets the large or small icon of a window. |
| [RedrawWindow](#redrawwindow) | Repaints the client area of a window now. |
| [RedrawNonClientArea](#redrawnonclientarea) | Repaints the frame of a window. |
| [SetRenderingPolicy](#setrenderingpolicy) | Turns the desktop compositor's drawing of the window frame on or off. |
| [EnableVisualStyles](#enablevisualstyles) | Gives the program's controls the current Windows look without a manifest. |
| [SetDialogResult](#setdialogresult) | Stores a dialog procedure's message result. |

## Reference

### GetWindowClassName

```freebasic
function GetWindowClassName( byval hWin as HWND ) as ustring
```

Returns the name of the class a window belongs to: `Button`, `Edit`, `Static`, `#32770` for a
dialog, or the name your program registered.

**Returns** the class name, or an empty string for an invalid handle.

**Example**

```freebasic
if GetWindowClassName( hCtrl ) = "Edit" then print "an edit control"
```

Microsoft Learn: [GetClassNameW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getclassnamew)

### GetWindowText

```freebasic
function GetWindowText overload( byval hWin as HWND ) as ustring
```

Returns the text of a window: the caption of a top-level window or dialog, the label of a button
or static control, the contents of an edit control. For a window of another program it returns
the caption reliably; the current contents of another program's edit control need a
`WM_GETTEXT` message sent to it.

The Windows function of the same name, which fills a buffer, is still there with three
arguments.

**Returns** the text, or an empty string when the window has none or the handle is invalid.

**Example**

```freebasic
dim ustrName as ustring = GetWindowText( hCtrl )
if len( ustrName ) = 0 then print "please enter a name"
```

Microsoft Learn: [GetWindowTextW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtextw)

### SetWindowText

```freebasic
function SetWindowText overload( byval hwnd as HWND, byval pwszText as wstring ptr ) as boolean
function SetWindowText overload( byval hwnd as HWND, byref szText as zstring ) as boolean
```

Sets the text of a window: the caption of a top-level window or dialog, the label of a button or
static control, the contents of an edit control. It cannot change the text of a control that
belongs to another program.

Pass a literal, a `ustring` or a `wstring`. The first form takes wide text; the second takes
narrow text (a literal, a `string` or a `zstring`) and reads it as UTF-8, as tiko's
literals are, so `SetWindowText( hwnd, "Grüße" )` shows `Grüße`. Text passed as an explicit
`zstring ptr` (`@sz`, `strptr( s )`) still goes to the Windows function, which treats it as ANSI.

| Parameter | Meaning |
| --- | --- |
| `hwnd` | The window or control. |
| `pwszText`, `szText` | The new text. |

**Returns** `true` on success; on failure `false`, and `GetLastError()` says why.

**Example**

```freebasic
SetWindowText( hwnd, "Untitled - Editor" )
dim ustrTitle as ustring = "Report " & 2
SetWindowText( hwnd, ustrTitle )
```

Microsoft Learn: [SetWindowTextW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowtextw)

### SetWindowStyle

```freebasic
function SetWindowStyle( byval hWin as HWND, byval dwStyle as LONG_PTR ) as LONG_PTR
```

Replaces all of a window's window styles (`GWL_STYLE`) with `dwStyle`, then has the frame
recalculated and redrawn. Windows keeps some flags itself: a top-level window keeps
`WS_CLIPSIBLINGS` whatever you pass. To change one flag and leave the rest, use
[AddWindowStyle](#addwindowstyle) or [RemoveWindowStyle](#removewindowstyle).

**Returns** the styles the window had before.

**Example**

```freebasic
dim dwOld as LONG_PTR = SetWindowStyle( hwnd, WS_OVERLAPPEDWINDOW or WS_VISIBLE )
```

Microsoft Learn: [SetWindowLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowlongptrw)

### SetWindowExStyle

```freebasic
function SetWindowExStyle( byval hWin as HWND, byval dwExStyle as LONG_PTR ) as LONG_PTR
```

Replaces all of a window's extended styles (`GWL_EXSTYLE`) with `dwExStyle`, then has the frame
recalculated and redrawn. `WS_EX_TOPMOST` passed here is ignored: Windows only changes it through
`SetWindowPos`.

**Returns** the extended styles the window had before.

**Example**

```freebasic
SetWindowExStyle( hwnd, WS_EX_TOOLWINDOW )
```

Microsoft Learn: [SetWindowLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowlongptrw)

### AddWindowStyle

```freebasic
function AddWindowStyle( byval hWin as HWND, byval dwStyle as LONG_PTR ) as LONG_PTR
```

Adds the flags in `dwStyle` to a window's window styles, leaving the others as they are, then has
the frame recalculated and redrawn.

**Returns** the styles the window had before.

**Example**

```freebasic
AddWindowStyle( hwnd, WS_THICKFRAME or WS_MAXIMIZEBOX )   ' make it resizable
```

### AddWindowExStyle

```freebasic
function AddWindowExStyle( byval hWin as HWND, byval dwExStyle as LONG_PTR ) as LONG_PTR
```

Adds the flags in `dwExStyle` to a window's extended styles, leaving the others as they are, then
has the frame recalculated and redrawn.

**Returns** the extended styles the window had before.

**Example**

```freebasic
AddWindowExStyle( hCtrl, WS_EX_CLIENTEDGE )   ' a sunken border
```

### RemoveWindowStyle

```freebasic
function RemoveWindowStyle( byval hWin as HWND, byval dwStyle as LONG_PTR ) as LONG_PTR
```

Clears the flags in `dwStyle` from a window's window styles, leaving the others as they are, then
has the frame recalculated and redrawn. Removing `WS_BORDER` from a captioned window also removes
its caption, since `WS_CAPTION` is `WS_BORDER or WS_DLGFRAME`.

**Returns** the styles the window had before.

**Example**

```freebasic
RemoveWindowStyle( hwnd, WS_THICKFRAME or WS_MAXIMIZEBOX )   ' fixed size
```

### RemoveWindowExStyle

```freebasic
function RemoveWindowExStyle( byval hWin as HWND, byval dwExStyle as DWORD ) as LONG_PTR
```

Clears the flags in `dwExStyle` from a window's extended styles, leaving the others as they are,
then has the frame recalculated and redrawn.

**Returns** the extended styles the window had before.

**Example**

```freebasic
RemoveWindowExStyle( hCtrl, WS_EX_CLIENTEDGE )
```

### SetWindowIcon

```freebasic
function SetWindowIcon( byval hWin as HWND, byval nIconType as long, byval icon as HICON ) as HICON
```

Sets one of a window's two icons: the large one, shown in the Alt+Tab switcher, or the small
one, shown in the caption. `NULL` removes the icon.

The window does not take ownership of the icon. An icon from `LoadIconW` is shared and needs no
clean-up; one you created or loaded with `LoadImageW` must be destroyed with `DestroyIcon` once
no window uses it, which is why the previous icon is returned.

| Parameter | Meaning |
| --- | --- |
| `hWin` | The window. |
| `nIconType` | `ICON_BIG` (1) or `ICON_SMALL` (0). |
| `icon` | The icon, or `NULL` to remove it. |

**Returns** the icon of that type the window had before, or `NULL` if it had none.

**Example**

```freebasic
dim hOld as HICON = SetWindowIcon( hwnd, ICON_SMALL, LoadIconW( NULL, cast( LPCWSTR, IDI_INFORMATION ) ) )
```

Microsoft Learn: [WM_SETICON](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-seticon)

### RedrawWindow

```freebasic
sub RedrawWindow overload( byval hWin as HWND )
```

Marks the whole client area of a window as needing a repaint, background included, and repaints
it at once instead of waiting for the next `WM_PAINT`. Do not call it while handling `WM_PAINT`.

The Windows function of the same name, which takes a rectangle, a region and flags, is still
there with four arguments.

**Example**

```freebasic
RedrawWindow( hCtrl )
```

Microsoft Learn: [InvalidateRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-invalidaterect), [UpdateWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-updatewindow)

### RedrawNonClientArea

```freebasic
function RedrawNonClientArea( byval hWin as HWND ) as boolean
```

Has Windows recalculate a window's frame (it sends `WM_NCCALCSIZE`) and repaint it: the caption,
borders, menu bar and scroll bars. The position, size and Z order stay as they are and the window
is not activated. Call it after changing anything that the frame is drawn from.

**Returns** `true` on success; on failure `false`, and `GetLastError()` says why.

**Example**

```freebasic
RedrawNonClientArea( hwnd )
```

Microsoft Learn: [SetWindowPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos)

### SetRenderingPolicy

```freebasic
function SetRenderingPolicy( byval hWin as HWND, byval policy as long = DWMNCRP_USEWINDOWSTYLE ) as HRESULT
```

Sets whether the desktop compositor draws the frame of a window, then has the frame redrawn.

| Parameter | Meaning |
| --- | --- |
| `hWin` | A top-level window. |
| `policy` | `DWMNCRP_USEWINDOWSTYLE` (the default): decided by the window's styles. `DWMNCRP_DISABLED`: never, the window draws its own frame. `DWMNCRP_ENABLED`: always. |

**Returns** `S_OK` on success, otherwise an error `HRESULT`.

**Example**

```freebasic
if SetRenderingPolicy( hwnd, DWMNCRP_DISABLED ) <> S_OK then print "policy not set"
```

Microsoft Learn: [DwmSetWindowAttribute](https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/nf-dwmapi-dwmsetwindowattribute), [DWMNCRENDERINGPOLICY](https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/ne-dwmapi-dwmncrenderingpolicy)

### EnableVisualStyles

```freebasic
function EnableVisualStyles() as boolean
```

Makes the program use version 6 of the common controls, which draw in the current Windows look,
without a manifest in the program: it creates an activation context from the manifest built
into the system's `shell32.dll` and makes it the default for the whole process. Call it once, at
the start, before any window or control is created. A program that already has a manifest asking
for version 6 does not need it.

**Returns** `true` if the activation context was created, `false` if not.

**Example**

```freebasic
if EnableVisualStyles() = false then print "the classic look will be used"
```

Microsoft Learn: [CreateActCtxW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createactctxw)

### SetDialogResult

```freebasic
function SetDialogResult( byval hDlg as HWND, byval uMsg as UINT, byval result as LONG_PTR ) as boolean
```

Stores `result` in a dialog's `DWLP_MSGRESULT` slot.

| Parameter | Meaning |
| --- | --- |
| `hDlg` | The dialog. |
| `uMsg` | The message being answered. |
| `result` | The value to store. |

**Returns** `false` for any message outside the twelve. For one of them, `true` when the slot
held a nonzero value before the call and `false` when it held 0.

**Example**

```freebasic
dim bOld as boolean = SetDialogResult( hDlg, WM_CTLCOLORDLG, cast( LONG_PTR, GetStockObject( WHITE_BRUSH ) ) )
```

Microsoft Learn: [DLGPROC](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nc-winuser-dlgproc)

## See also

- [Category: sys/win](Category-Sys-Win)
- [Window size and position](SysWin-Window-Size-and-Position)
- [Finding windows](SysWin-Finding-Windows)
- [Dark mode](SysWin-Dark-Mode) for the frame's colours and corners
- [Fonts](SysWin-Fonts) for a window's font
