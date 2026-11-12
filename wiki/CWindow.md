[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **CWindow**

# CWindow

Creates a main window, adds controls to it and runs its message loop, scaled for DPI.

A `CWindow` object owns one window. `Create` registers a window class of its own for it, makes
the window and remembers the object in the window, so that any message handler can get back to
it with [CWindowPtr](#cwindowptr). `AddControl` adds child controls with ready-made styles and
the window's font, and `DoEvents` shows the window and runs the message loop until the program
quits. On top of that the class keeps per-window and per-control data: control colours, anchors
that move controls when the window is resized, an accelerator table, user values and callbacks.

**Lifetime.** The object must outlive its window: declare it in `main` (or allocate it with
`new`) and keep it until `DoEvents` returns. The destructor deletes the default font, destroys
the accelerator table, unregisters the window class and frees the rich edit library if
`AddControl` loaded it. It does **not** destroy the window.

**DPI.** The scaling ratio is fixed when the object is constructed. If the process is DPI aware
at that moment, the ratio is the display's DPI divided by 96 (1.75 at 175 %); otherwise it is 1.
So call `SetProcessDpiAwareness` **before** the `dim`. Every position and size the class takes
(`Create`, `AddControl`, `SetClientSize`, `SetWindowPos`, `MoveWindow`, `SetViewPort`) is in
**96-DPI units** and is multiplied by the ratio; every size it returns (`Width`, `ClientWidth`,
`GetClientRect` …) is divided by it. At 175 %, `Create( NULL, "", NULL, 0, 0, 400, 300 )` makes a
window 700 pixels wide, and `Width` reads it back as 400.

**Your window procedure.** CWindow installs its own procedure for the window. It handles a few
messages itself (colours, anchors, scroll bars, control callbacks, a stabilized window's close
command) and then passes every message to the procedure you gave to `Create`. Whatever yours
returns is returned to Windows, including 0, so **end your procedure with
`return DefWindowProcW( hwnd, uMsg, wParam, lParam )`** as the example does. The object is
remembered in the window only once `Create` is about to return: in `WM_CREATE` use
`CWindowPtr( lParam )`, and messages that arrive during `Create` before `WM_CREATE` or after it
are handled by `DefWindowProcW` without reaching your procedure.

The snippets on this page assume `hwnd` is a window made by `Create` and `hCtrl` a control on it.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A window with a label, an edit box and a button. The edit box stretches and the button stays in
the bottom-right corner when the window is resized; Ctrl+G does the same as the button.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_NAME  = 101
const IDC_GREET = 102

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "GreetDemo"
    dim hWin as HWND = pWindow.Create( NULL, "CWindow", @WndProc )
    pWindow.SetClientSize( 360, 110 )
    pWindow.Center()
    pWindow.AddControl( "Label", hWin, -1, "Your name:", 10, 14, 80, 20 )
    pWindow.AddControl( "Edit", hWin, IDC_NAME, "", 95, 10, 255, 24 )
    pWindow.AddControl( "Button", hWin, IDC_GREET, "&Greet", 250, 70, 100, 28 )
    pWindow.AnchorControl( IDC_NAME, ANCHOR_WIDTH )
    pWindow.AnchorControl( IDC_GREET, ANCHOR_BOTTOM_RIGHT )
    pWindow.AddAccelerator( FVIRTKEY or FCONTROL, "G", IDC_GREET )
    pWindow.CreateAcceleratorTable()
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            select case CBCTL( wParam, lParam )
                case IDC_GREET   ' the button, or Ctrl+G
                    SetWindowText( hwnd, "Hello, " & GetWindowText( GetDlgItem( hwnd, IDC_NAME ) ) )
                case IDCANCEL    ' Esc
                    SendMessageW( hwnd, WM_CLOSE, 0, 0 )
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

## Members

**Creating and running**

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Sets up the object: class name, DPI ratio, default font, common controls. |
| [Destructor](#destructor) | Releases the font, accelerator table and window class. |
| [Create](#create) | Creates the window. |
| [CreateOverlapped](#createoverlapped) | Creates a fixed-size window with a title bar and a system menu. |
| [DoEvents](#doevents) | Shows the window and runs the message loop. |
| [GetWindowProc](#getwindowproc) | Returns the window procedure given to `Create`. |
| [hWindow](#hwindow) | The window's handle. |
| [InstanceHandle](#instancehandle) | The module handle the class is registered with. |

**Class, styles and background**

| Member | Does |
| --- | --- |
| [ClassStyle](#classstyle) | Reads or sets the window class style. |
| [WindowStyle](#windowstyle) | Reads or sets the window style. |
| [WindowExStyle, WindowStyleEx](#windowexstyle-windowstyleex) | Reads or sets the extended window style. |
| [Brush](#brush) | Reads or sets the class background brush. |
| [SetBackColor](#setbackcolor) | Paints the window's background in a colour. |
| [BigIcon, SmallIcon](#bigicon-smallicon) | Sets the window's large and small icons. |

**Fonts**

| Member | Does |
| --- | --- |
| [DefaultFontName](#defaultfontname) | The face name of the default font. |
| [DefaultFontSize](#defaultfontsize) | The point size of the default font. |
| [Font](#font) | The default font that `Create` and `AddControl` give to windows. |
| [CreateFont](#createfont) | Creates a font scaled for the object's DPI. |
| [SetFont](#setfont) | Replaces the default font. |

**DPI scaling**

| Member | Does |
| --- | --- |
| [DPI](#dpi) | Reads or sets the DPI the object scales for. |
| [rxRatio, ryRatio](#rxratio-ryratio) | Reads or sets the horizontal and vertical scaling ratios. |
| [ScaleX, ScaleY](#scalex-scaley) | Turns 96-DPI units into pixels. |
| [UnScaleX, UnScaleY](#unscalex-unscaley) | Turns pixels into 96-DPI units. |

**Size and position** (all in 96-DPI units)

| Member | Does |
| --- | --- |
| [Width, Height](#width-height) | The size of the window rectangle. |
| [ClientWidth, ClientHeight](#clientwidth-clientheight) | The size of the client area. |
| [ScreenX, ScreenY](#screenx-screeny) | The window's top-left corner. |
| [ControlWidth, ControlHeight](#controlwidth-controlheight) | The size of another window's rectangle. |
| [ControlClientWidth, ControlClientHeight](#controlclientwidth-controlclientheight) | The size of another window's client area. |
| [GetWindowRect](#getwindowrect) | The window rectangle. |
| [GetClientRect](#getclientrect) | The client rectangle. |
| [GetControlWindowRect](#getcontrolwindowrect) | Another window's rectangle. |
| [GetControlClientRect](#getcontrolclientrect) | Another window's client rectangle. |
| [GetWorkArea](#getworkarea) | The work area of the primary display. |
| [SetClientSize](#setclientsize) | Resizes the window to a client size. |
| [Center](#center) | Centres a window in the work area or over another window. |
| [SetWindowPos](#setwindowpos) | Moves, resizes and reorders a window. |
| [MoveWindow](#movewindow) | Moves and resizes a window. |
| [Resize](#resize) | Sends the window a `WM_SIZE` message. |
| [ForceVisibleDisplay](#forcevisibledisplay) | Brings the window back onto a display. |

**Controls**

| Member | Does |
| --- | --- |
| [AddControl](#addcontrol) | Creates a control, with default styles and the default font. |
| [ControlHandle](#controlhandle) | Returns the handle of a control from its identifier. |
| [ControlGetStyle, ControlGetExStyle](#controlgetstyle-controlgetexstyle) | Read a window's styles. |
| [ControlSetStyle, ControlSetExStyle](#controlsetstyle-controlsetexstyle) | Replace a window's styles. |
| [ControlAddStyle, ControlAddExStyle](#controladdstyle-controladdexstyle) | Add styles to a window. |
| [ControlRemoveStyle, ControlRemoveExStyle](#controlremovestyle-controlremoveexstyle) | Remove styles from a window. |
| [SetControlSubclass](#setcontrolsubclass) | Subclasses a control. |
| [SetControlCallback](#setcontrolcallback) | Sends a control's `WM_COMMAND` and `WM_NOTIFY` messages to a procedure of its own. |
| [GetControlCallback](#getcontrolcallback) | Returns a control's callback. |
| [GetControlCallbackItem](#getcontrolcallbackitem) | Finds a control's callback entry. |

**Colours**

| Member | Does |
| --- | --- |
| [SetCtlColors](#setctlcolors) | Sets the text and background colours of an edit, list box or static control. |
| [GetForeColor, GetBackColor](#getforecolor-getbackcolor) | Read the colours set for a control. |
| [GetColorItem](#getcoloritem) | Finds a control's colour entry. |

**User data**

| Member | Does |
| --- | --- |
| [UserData](#userdata) | One hundred values of your own, kept with the window. |
| [ControlSetUser](#controlsetuser) | Stores one of ten values of your own for a control. |
| [ControlGetUser](#controlgetuser) | Reads a value stored with `ControlSetUser`. |
| [GetUserDataItem](#getuserdataitem) | Finds a control's user data entry. |

**Layout manager**

| Member | Does |
| --- | --- |
| [AnchorControl](#anchorcontrol) | Keeps a control in place, or stretches it, when its parent is resized. |
| [AdjustControls](#adjustcontrols) | Moves the anchored controls now. |
| [GetAnchorItem](#getanchoritem) | Finds a control's anchor entry. |

**Scrollable windows**

| Member | Does |
| --- | --- |
| [SetViewPort](#setviewport) | Makes the window scrollable by shrinking its client area. |
| [IsWindowScrollable](#iswindowscrollable) | Tells whether `SetViewPort` has been called. |
| [ResetScrollBars](#resetscrollbars) | Scrolls back to the origin. |
| [SetupScrollBars](#setupscrollbars) | Recomputes the scroll ranges. |
| [OnVScroll, OnHScroll](#onvscroll-onhscroll) | Handle `WM_VSCROLL` and `WM_HSCROLL`. |
| [OnSize](#onsize) | Handles `WM_SIZE` for a scrollable window. |

**Stabilization**

| Member | Does |
| --- | --- |
| [Stabilize](#stabilize) | Stops the user from closing the window. |
| [NonStable](#nonstable) | Lets the user close the window again. |
| [IsStabilized, IsNonStable](#isstabilized-isnonstable) | Tell whether the window is stabilized. |

**Keyboard accelerators**

| Member | Does |
| --- | --- |
| [AccelHandle](#accelhandle) | Reads or replaces the accelerator table. |
| [AddAccelerator](#addaccelerator) | Adds a key to the table being built. |
| [CreateAcceleratorTable](#createacceleratortable) | Builds the accelerator table. |
| [DestroyAcceleratorTable](#destroyacceleratortable) | Destroys the accelerator table. |

## Reference

### Constructor

```freebasic
constructor( byref wszClassName as const wstring = "" )
```

Prepares the object; it creates no window. It stores the class name to register, the program's
module handle and the scaling ratio (see the introduction), picks the default font (Segoe UI
9 pt in a DPI-aware process, Tahoma 8 pt otherwise) and initialises the common controls library
for every control class `AddControl` knows.

With no class name, `Create` registers a generated one, `FBWindowClass:0`, `FBWindowClass:1` and
so on. A class name can be registered only once at a time: a second `CWindow` with the same name
fails in `Create`. Leave the name out for popup windows and tab pages.

| Parameter | Meaning |
| --- | --- |
| `wszClassName` | The window class name to register, or `""` for a generated one. |

**Example**

```freebasic
dim pWindow as CWindow = "InvoiceMain"   ' or: dim pWindow as CWindow
```

Microsoft Learn: [InitCommonControlsEx](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-initcommoncontrolsex)

### Destructor

```freebasic
destructor
```

Deletes the default font (the one `Create` made, or the one given with [Font](#font) or
[SetFont](#setfont)), destroys the accelerator table, unregisters the window class and frees the
rich edit library. The window itself is left alone: destroy it first (closing it does), because a
class cannot be unregistered while a window of it exists.

**Example**

```freebasic
dim pPopup as CWindow ptr = new CWindow
pPopup->Create( hwnd, "Details", NULL, 0, 0, 300, 200, WS_POPUPWINDOW or WS_CAPTION )
' ...
DestroyWindow( pPopup->hWindow )
delete pPopup
```

Microsoft Learn: [UnregisterClassW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-unregisterclassw)

### Create

```freebasic
function Create( byval hParent as HWND = NULL, byref wszTitle as wstring = "", byval lpfnWndProc as WNDPROC = NULL, byval x as long = CW_USEDEFAULT, byval y as long = CW_USEDEFAULT, byval nWidth as long = CW_USEDEFAULT, byval nHeight as long = CW_USEDEFAULT, byval dwStyle as DWORD = WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN or WS_CLIPSIBLINGS, byval dwExStyle as DWORD = WS_EX_CONTROLPARENT or WS_EX_WINDOWEDGE ) as HWND
```

Registers the window class and creates the window, hidden; [DoEvents](#doevents) shows it. The
class has the styles `CS_DBLCLKS`, `CS_HREDRAW` and `CS_VREDRAW`, the arrow cursor, the
`COLOR_3DFACE` background and no icon. The default font is created if there is none yet and given
to the window with `WM_SETFONT`.

`x`, `y`, `nWidth` and `nHeight` are 96-DPI units; `CW_USEDEFAULT` lets Windows choose. Many
programs leave the size out and call [SetClientSize](#setclientsize) next. A window object can
create one window: a second call returns `NULL`.

The pointer to the object is passed as the creation parameter, so `WM_CREATE` can reach it with
`CWindowPtr( lParam )`.

| Parameter | Meaning |
| --- | --- |
| `hParent` | The parent or owner window, or `NULL` for a top-level window. |
| `wszTitle` | The caption. |
| `lpfnWndProc` | Your window procedure, or `NULL` to let `DefWindowProcW` handle everything. |
| `x`, `y` | The position. |
| `nWidth`, `nHeight` | The size of the whole window. |
| `dwStyle` | `WS_*` styles; `WS_POPUPWINDOW or WS_CAPTION` makes a popup. |
| `dwExStyle` | `WS_EX_*` styles; `WS_EX_CONTROLPARENT` lets Tab move into child windows. |

**Returns** the window handle, or `NULL` when the class could not be registered or the window
could not be created.

**Example**

```freebasic
dim pWindow as CWindow
dim hWin as HWND = pWindow.Create( NULL, "Orders", NULL, 0, 0, 640, 480 )
```

Microsoft Learn: [CreateWindowExW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createwindowexw)

### CreateOverlapped

```freebasic
function CreateOverlapped( byval hParent as HWND = NULL, byref wszTitle as wstring = "", byval lpfnWndProc as WNDPROC = NULL, byval x as long = CW_USEDEFAULT, byval y as long = CW_USEDEFAULT, byval nWidth as long = CW_USEDEFAULT, byval nHeight as long = CW_USEDEFAULT, byval dwExStyle as UINT = WS_EX_CONTROLPARENT or WS_EX_WINDOWEDGE ) as HWND
```

[Create](#create) with the style `WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU`: a title bar, a
border and a system menu, but no sizing border and no minimize or maximize button.

**Returns** the window handle, or `NULL`.

**Example**

```freebasic
dim pWindow as CWindow
dim hWin as HWND = pWindow.CreateOverlapped( NULL, "About", NULL, 0, 0, 320, 160 )
```

### DoEvents

```freebasic
function DoEvents( byval nCmdShow as long = 0 ) as long
```

Shows the window (`SW_SHOW` when `nCmdShow` is 0), paints it, and runs the message loop until
`WM_QUIT`. Each message goes first to the accelerator table, if there is one, then to
`IsDialogMessageW` for the window, and only then to `TranslateMessage` and `DispatchMessageW`.

`IsDialogMessageW` gives the window dialog-box keyboard handling: Tab and the arrow keys move the
focus, Enter presses the default button and Esc sends `WM_COMMAND` with `IDCANCEL`. A control of
yours that needs those keys answers `WM_GETDLGCODE` with `DLGC_WANTALLKEYS`, or with
`DLGC_WANTARROWS or DLGC_WANTCHARS`.

**Returns** the exit code given to `PostQuitMessage`, or 0 at once when there is no window.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim nExitCode as long = pWindow->DoEvents( SW_SHOWNORMAL )
```

Microsoft Learn: [IsDialogMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-isdialogmessagew)

### GetWindowProc

```freebasic
function GetWindowProc() as WNDPROC
```

**Returns** the window procedure given to `Create`, or `NULL`. CWindow's own procedure is the one
Windows calls; this is the one it passes messages on to.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->GetWindowProc() = NULL then print "no window procedure of its own"
```

### hWindow

```freebasic
property hWindow() as HWND
property hWindow( byval hwnd as HWND )
```

Reads the window's handle, `NULL` before `Create`. Setting it takes effect only while the object
has no window yet, and is then the window the members work on; once there is one it is ignored.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowOwnerPtr( hCtrl )
SetWindowText( pWindow->hWindow, "Saved" )
```

### InstanceHandle

```freebasic
property InstanceHandle() as HINSTANCE
```

Reads the module handle the window class is registered with and controls are created with:
the program's own, `GetModuleHandleW( NULL )`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim hIcon as HICON = LoadIconW( pWindow->InstanceHandle, cast(LPCWSTR, 100) )
```

### ClassStyle

```freebasic
property ClassStyle() as ULONG_PTR
property ClassStyle( byval dwStyle as LONG_PTR )
```

Reads or replaces the class style of the window's class. The default, `CS_DBLCLKS or CS_HREDRAW
or CS_VREDRAW`, repaints the whole window on every resize; a window with many controls flickers
less with `CS_DBLCLKS` alone, as long as it repaints what needs repainting itself. Reads 0 before
`Create`, and setting it then does nothing.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->ClassStyle = CS_DBLCLKS
```

Microsoft Learn: [SetClassLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setclasslongptrw)

### WindowStyle

```freebasic
property WindowStyle() as LONG_PTR
property WindowStyle( byval dwStyle as LONG_PTR )
```

Reads or replaces the window's `WS_*` style. Setting it redraws the frame so that the change
shows at once. Does nothing before `Create`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->WindowStyle = pWindow->WindowStyle and not WS_MAXIMIZEBOX
```

Microsoft Learn: [SetWindowLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowlongptrw)

### WindowExStyle, WindowStyleEx

```freebasic
property WindowExStyle() as LONG_PTR
property WindowExStyle( byval dwExStyle as LONG_PTR )
property WindowStyleEx() as LONG_PTR
property WindowStyleEx( byval dwExStyle as LONG_PTR )
```

Read or replace the window's `WS_EX_*` style; the two names do the same. Setting it redraws the
frame. Does nothing before `Create`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->WindowExStyle = pWindow->WindowExStyle or WS_EX_TOPMOST
```

### Brush

```freebasic
property Brush() as HBRUSH
property Brush( byval hbrBackground as HBRUSH )
```

Reads or replaces the class background brush, the one Windows paints the client area with, and
repaints the window. The value can be a brush handle or a system colour plus 1 cast to `HBRUSH`.
CWindow does not delete it: a brush you made with `CreateSolidBrush` is yours to delete once the
window is gone. While [SetBackColor](#setbackcolor) is in force, that colour is painted instead.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->Brush = cast(HBRUSH, COLOR_WINDOW + 1)
```

Microsoft Learn: [WNDCLASSEXW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-wndclassexw)

### SetBackColor

```freebasic
function SetBackColor( byval backColor as COLORREF ) as boolean
```

Paints the window's background in `backColor`: CWindow then answers `WM_ERASEBKGND` itself by
filling the client area with that colour. It is kept with the colours of
[SetCtlColors](#setctlcolors), as the window's own entry.

**Returns** `true`; `false` when there is no window.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->SetBackColor( RGB_WHITE )
```

Microsoft Learn: [WM_ERASEBKGND](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-erasebkgnd)

### BigIcon, SmallIcon

```freebasic
property BigIcon( byval hIcon as HICON )
property SmallIcon( byval hIcon as HICON )
```

Set the large icon (shown by Alt+Tab) and the small icon (shown in the caption) by sending
`WM_SETICON`. `NULL` removes the icon. Both can only be set. The icons are not destroyed by
CWindow; one loaded with `LoadImageW` without `LR_SHARED` is yours to destroy.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->SmallIcon = LoadIconW( NULL, IDI_APPLICATION )
pWindow->BigIcon = LoadIconW( NULL, IDI_APPLICATION )
```

Microsoft Learn: [WM_SETICON](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-seticon)

### DefaultFontName

```freebasic
property DefaultFontName() as string
property DefaultFontName( byref wszFontName as wstring )
```

Reads the face name of the default font: the one `Create` makes the default font from and that
[CreateFont](#createfont) and [SetFont](#setfont) use when given an empty name. The getter
returns a narrow `string`.

With the current toolchain, assigning to the property damages the program's memory (a program
that does so stops with a heap error). To choose the default font, call [SetFont](#setfont)
before `Create`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
print "default font: "; pWindow->DefaultFontName; pWindow->DefaultFontSize; " pt"
```

### DefaultFontSize

```freebasic
property DefaultFontSize() as long
property DefaultFontSize( byval nPointSize as long )
```

Reads or sets the point size `Create` makes the default font with. Setting it after `Create`
changes nothing on screen; use [SetFont](#setfont) for that.

**Example**

```freebasic
dim pWindow as CWindow
pWindow.DefaultFontSize = 10
pWindow.Create( NULL, "Larger text" )
```

### Font

```freebasic
property Font() as HFONT
property Font( byval hFont as HFONT )
```

Reads the default font, the one `Create` gives to the window and `AddControl` to each control.
Setting it takes effect only while there is none, that is before `Create`; after that it is
ignored. A font set this way belongs to the object, which deletes it.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
SendMessageW( hCtrl, WM_SETFONT, cast(WPARAM, pWindow->Font), true )
```

Microsoft Learn: [WM_SETFONT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-setfont)

### CreateFont

```freebasic
function CreateFont( byref wszFaceName as wstring, byval lPointSize as long, byval lWeight as long = 0, byval bItalic as ubyte = false, byval bUnderline as ubyte = false, byval bStrikeOut as ubyte = false, byval bCharSet as ubyte = DEFAULT_CHARSET ) as HFONT
```

Creates a TrueType-preferring font of `lPointSize` points for the object's [DPI](#dpi): at 168
DPI, 10 points is 23 pixels high. An empty face name uses [DefaultFontName](#defaultfontname).

| Parameter | Meaning |
| --- | --- |
| `wszFaceName` | The typeface, for example `"Segoe UI"`; at most 31 characters. |
| `lPointSize` | The size in points. |
| `lWeight` | 0 to 1000: `FW_NORMAL` (400), `FW_BOLD` (700) …; 0 is the default weight. |
| `bItalic`, `bUnderline`, `bStrikeOut` | Nonzero for an italic, underlined or struck-out font. |
| `bCharSet` | The character set; `DEFAULT_CHARSET` follows the system locale, `SYMBOL_CHARSET` suits symbol fonts such as Marlett. |

**Returns** the font, or `NULL` on failure. It is yours: delete it with `DeleteObject` when no
window uses it any more.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim hBold as HFONT = pWindow->CreateFont( "Segoe UI", 12, FW_BOLD )
SendMessageW( hCtrl, WM_SETFONT, cast(WPARAM, hBold), true )
```

Microsoft Learn: [CreateFontIndirectW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createfontindirectw)

### SetFont

```freebasic
function SetFont( byref wszFaceName as wstring, byval lPointSize as long, byval lWeight as long = 0, byval bItalic as ubyte = false, byval bUnderline as ubyte = false, byval bStrikeOut as ubyte = false, byval bCharSet as ubyte = DEFAULT_CHARSET ) as boolean
```

Creates a font as [CreateFont](#createfont) does and makes it the default font, deleting the
previous one; the face name and size become [DefaultFontName](#defaultfontname) and
[DefaultFontSize](#defaultfontsize). Windows that already exist keep their font: called before
`Create` it sets the font of everything, called later it sets the font of the controls added
after it.

**Returns** `true` when the font was created, `false` otherwise (the old default stays).

**Example**

```freebasic
dim pWindow as CWindow
pWindow.SetFont( "Consolas", 11 )
pWindow.Create( NULL, "Log viewer" )
```

### DPI

```freebasic
property DPI() as single
property DPI( byval dpi as single )
```

Reads the DPI the object scales for: the display's DPI in a DPI-aware process, otherwise 96.
Setting it changes both scaling ratios to `dpi / 96`; -1 takes the display's horizontal DPI. Set
it before `Create`, never after: windows and controls already made keep their size.

**Example**

```freebasic
dim pWindow as CWindow
pWindow.DPI = 96   ' no scaling at all
```

Microsoft Learn: [GetDeviceCaps](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getdevicecaps)

### rxRatio, ryRatio

```freebasic
property rxRatio() as single
property rxRatio( byval rx as single )
property ryRatio( byval rx as single )
property ryRatio() as single
```

Read or set the horizontal and vertical scaling ratios: 1.75 at 175 %. Setting one changes how
everything after it is scaled.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim cxMin as long = 400 * pWindow->rxRatio   ' a minimum width, in pixels
```

### ScaleX, ScaleY

```freebasic
function ScaleX( byval cx as single ) as single
function ScaleY( byval cy as single ) as single
```

Multiply a horizontal or vertical distance in 96-DPI units by the scaling ratio, giving pixels.
At 175 %, `ScaleX( 100 )` is 175.

**Returns** the distance in pixels.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim cy as long = pWindow->ScaleY( 24 )
```

### UnScaleX, UnScaleY

```freebasic
function UnScaleX( byval cx as single ) as single
function UnScaleY( byval cy as single ) as single
```

Divide a distance in pixels by the scaling ratio, giving 96-DPI units. At 175 %, `UnScaleX( 150 )`
is 85.71429.

**Returns** the distance in 96-DPI units.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
print "the button is"; pWindow->UnScaleX( GetWindowWidth( hCtrl ) ); " units wide"
```

### Width, Height

```freebasic
property Width() as long
property Height() as long
```

The width and height of the window rectangle (caption and borders included) in 96-DPI units,
rounded to the nearest unit.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
print pWindow->Width; " x"; pWindow->Height
```

### ClientWidth, ClientHeight

```freebasic
property ClientHeight() as long
property ClientWidth() as long
```

The width and height of the client area in 96-DPI units: after `SetClientSize( 300, 200 )` they
read 300 and 200 whatever the display's scaling.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->AddControl( "Button", hwnd, IDOK, "OK", pWindow->ClientWidth - 85, pWindow->ClientHeight - 33, 75, 23 )
```

### ScreenX, ScreenY

```freebasic
property ScreenX() as long
property ScreenY() as long
```

The window's left and top edges in 96-DPI units, relative to the client area of the window
`GetParent` returns: the parent of a child window, the owner of an owned popup window. For a
top-level window without an owner they are screen coordinates.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
print "at"; pWindow->ScreenX; ","; pWindow->ScreenY
```

### ControlWidth, ControlHeight

```freebasic
property ControlWidth( byval hwnd as HWND ) as long
property ControlHeight( byval hwnd as HWND ) as long
```

The width and height of any window's rectangle in 96-DPI units, rounded: a button made 75 units
wide reads back 75.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
print "button:"; pWindow->ControlWidth( hCtrl ); " x"; pWindow->ControlHeight( hCtrl )
```

### ControlClientWidth, ControlClientHeight

```freebasic
property ControlClientWidth( byval hwnd as HWND ) as long
property ControlClientHeight( byval hwnd as HWND ) as long
```

The width and height of any window's client area in 96-DPI units.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
print "inside:"; pWindow->ControlClientWidth( hCtrl ); " x"; pWindow->ControlClientHeight( hCtrl )
```

### GetWindowRect

```freebasic
sub GetWindowRect overload( byval lpRect as LPRECT )
function GetWindowRect overload() as RECT
```

The window rectangle in screen coordinates, every edge divided by the scaling ratio. The sub form
fills the `RECT` that `lpRect` points to and does nothing when it is `NULL`.

**Returns** the rectangle (function form).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim rc as RECT = pWindow->GetWindowRect()
print "frame width:"; rc.Right - rc.Left
```

Microsoft Learn: [GetWindowRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowrect)

### GetClientRect

```freebasic
sub GetClientRect overload( byval lpRect as LPRECT )
function GetClientRect overload() as RECT
```

The client rectangle in 96-DPI units: `Left` and `Top` are 0, `Right` and `Bottom` the width and
height.

**Returns** the rectangle (function form).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim rc as RECT
pWindow->GetClientRect( @rc )
```

Microsoft Learn: [GetClientRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getclientrect)

### GetControlWindowRect

```freebasic
sub GetControlWindowRect overload( byval hwnd as HWND, byval lpRect as LPRECT )
function GetControlWindowRect overload( byval hwnd as HWND ) as RECT
```

Any window's rectangle in screen coordinates divided by the scaling ratio.

**Returns** the rectangle (function form).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim rc as RECT = pWindow->GetControlWindowRect( hCtrl )
```

### GetControlClientRect

```freebasic
sub GetControlClientRect overload( byval hwnd as HWND, byval lpRect as LPRECT )
function GetControlClientRect overload( byval hwnd as HWND ) as RECT
```

Any window's client rectangle in 96-DPI units.

**Returns** the rectangle (function form).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim rc as RECT = pWindow->GetControlClientRect( hCtrl )
print "client:"; rc.Right; " x"; rc.Bottom
```

### GetWorkArea

```freebasic
sub GetWorkArea overload( byval lpRect as LPRECT )
function GetWorkArea overload() as RECT
```

The work area of the primary display (the screen less the taskbar and docked toolbars), divided
by the scaling ratio.

**Returns** the rectangle (function form).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim rc as RECT = pWindow->GetWorkArea()
pWindow->SetWindowPos( hwnd, NULL, rc.Left, rc.Top, rc.Right - rc.Left, rc.Bottom - rc.Top, SWP_NOZORDER )
```

Microsoft Learn: [SystemParametersInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow)

### SetClientSize

```freebasic
sub SetClientSize( byval nWidth as long, byval nHeight as long )
```

Resizes the window so that its client area is `nWidth` × `nHeight` 96-DPI units, allowing for the
caption, borders, menu and scroll bars. This is the usual way to size a window, because the
frame's size differs between Windows versions and styles. See
[SetWindowClientSize](SysWin-Window-Size-and-Position#setwindowclientsize).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->SetClientSize( 500, 320 )
```

### Center

```freebasic
sub Center( byval hwnd as HWND = NULL, byval hwndParent as HWND = NULL )
```

Centres `hwnd` (the object's own window when it is `NULL`) over `hwndParent`, or in the work area
when that is `NULL`, keeping it inside the work area. See
[CenterWindow](SysWin-Window-Size-and-Position#centerwindow).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->Center()
```

### SetWindowPos

```freebasic
function SetWindowPos( byval hwnd as HWND, byval hwndInsertAfter as HWND, byval x as long, byval y as long, byval cx as long, byval cy as long, byval uFlags as UINT ) as boolean
```

Calls Windows' `SetWindowPos` for any window with `x`, `y`, `cx` and `cy` multiplied by the
scaling ratios, so they are given in 96-DPI units.

| Parameter | Meaning |
| --- | --- |
| `hwnd` | The window or control. |
| `hwndInsertAfter` | The window to place it after in the Z order, or `HWND_TOP`, `HWND_TOPMOST` …; ignored with `SWP_NOZORDER`. |
| `x`, `y` | The new position. |
| `cx`, `cy` | The new size. |
| `uFlags` | `SWP_*` flags. |

**Returns** `true` on success.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->SetWindowPos( hCtrl, NULL, 10, 10, 80, 24, SWP_NOZORDER )
```

Microsoft Learn: [SetWindowPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos)

### MoveWindow

```freebasic
function MoveWindow( byval hwnd as HWND, byval x as long, byval y as long, byval nWidth as long, byval nHeight as long, byval bRepaint as boolean = true ) as boolean
```

Calls Windows' `MoveWindow` for any window with the position and size multiplied by the scaling
ratios. A child window's position is relative to its parent's client area.

**Returns** `true` on success.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->MoveWindow( hCtrl, 20, 20, 100, 30 )
```

Microsoft Learn: [MoveWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-movewindow)

### Resize

```freebasic
sub Resize()
```

Sends the window `WM_SIZE` with `SIZE_RESTORED`, so that anchored controls and the scroll bars of
a scrollable window are laid out again and your `WM_SIZE` handler runs.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->Resize()
```

Microsoft Learn: [WM_SIZE](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-size)

### ForceVisibleDisplay

```freebasic
sub ForceVisibleDisplay()
```

If the window is on no display at all, centres it in the work area of the display nearest to it;
a window that is at least partly visible is left alone. Call it after restoring a saved position.
See [ForceVisibleDisplay](SysWin-Window-Size-and-Position#forcevisibledisplay).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->ForceVisibleDisplay()
```

Microsoft Learn: [MonitorFromRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-monitorfromrect)

### AddControl

```freebasic
function AddControl( byref wszClassName as wstring, byval hParent as HWND = NULL, byval cID as LONG_PTR = 0, byref wszTitle as wstring = "", byval x as long = 0, byval y as long = 0, byval nWidth as long = 0, byval nHeight as long = 0, byval dwStyle as long = -1, byval dwExStyle as long = -1, byval lpParam as LONG_PTR = 0 ) as HWND
```

Creates a control at `x`, `y`, `nWidth` × `nHeight` 96-DPI units in `hParent` (the object's
window when it is `NULL`). `wszClassName` is a Windows class name or one of the aliases below,
in any case. `dwStyle` and `dwExStyle` left at -1 take the defaults below; `WS_CHILD` is always
added. Most controls get the default font.

| Name | Class | Default style besides `WS_CHILD` | Default extended style |
| --- | --- | --- | --- |
| `Button` | Button | `WS_VISIBLE`, `WS_TABSTOP`, `BS_PUSHBUTTON`, `BS_CENTER`, `BS_VCENTER` | none |
| `CustomButton`, `OwnerDrawButton` | Button | `WS_VISIBLE`, `WS_TABSTOP`, `BS_OWNERDRAW` | none |
| `RadioButton`, `Option` | Button | `WS_VISIBLE`, `WS_TABSTOP`, `BS_AUTORADIOBUTTON`, `BS_LEFT`, `BS_VCENTER` | none |
| `CheckBox` | Button | `WS_VISIBLE`, `WS_TABSTOP`, `BS_AUTOCHECKBOX`, `BS_LEFT`, `BS_VCENTER` | none |
| `Check3State` | Button | as `CheckBox` with `BS_AUTO3STATE` | none |
| `BitmapButton`, `IconButton` | Button | `WS_VISIBLE`, `WS_TABSTOP`, `BS_PUSHBUTTON`, `BS_BITMAP` or `BS_ICON` | none |
| `GroupBox` | Button | `WS_VISIBLE`, `WS_CLIPSIBLINGS`, `WS_GROUP`, `BS_GROUPBOX` | `WS_EX_TRANSPARENT` |
| `Label` | Static | `WS_VISIBLE`, `SS_LEFT`, `SS_NOTIFY` | none |
| `BitmapLabel`, `IconLabel` | Static | `WS_VISIBLE`, `WS_GROUP`, `SS_BITMAP` or `SS_ICON` | `WS_EX_TRANSPARENT` |
| `CustomLabel` | Static | `WS_VISIBLE`, `WS_GROUP`, `SS_OWNERDRAW` | none |
| `Frame`, `FrameWindow` | Static | `WS_VISIBLE`, `WS_CLIPSIBLINGS`, `WS_GROUP`, `SS_BLACKFRAME` | `WS_EX_TRANSPARENT` |
| `Line` | Static | `WS_VISIBLE`, `SS_ETCHEDFRAME` | `WS_EX_TRANSPARENT` |
| `Edit`, `TextBox` | Edit | `WS_VISIBLE`, `WS_TABSTOP`, `ES_LEFT`, `ES_AUTOHSCROLL` | `WS_EX_CLIENTEDGE` |
| `EditMultiline`, `MultilineTextBox` | Edit | as `Edit` with `WS_VSCROLL`, `ES_MULTILINE`, `ES_NOHIDESEL`, `ES_WANTRETURN` | `WS_EX_CLIENTEDGE` |
| `RichEdit`, `RichEdit50W` | RichEdit50W | `WS_VISIBLE`, `WS_TABSTOP`, `WS_HSCROLL`, `WS_VSCROLL`, `ES_LEFT`, `ES_AUTOHSCROLL`, `ES_AUTOVSCROLL`, `ES_MULTILINE`, `ES_WANTRETURN`, `ES_NOHIDESEL`, `ES_SAVESEL` | none |
| `ComboBox` | ComboBox | `WS_VISIBLE`, `WS_VSCROLL`, `WS_BORDER`, `WS_TABSTOP`, `CBS_DROPDOWN`, `CBS_HASSTRINGS`, `CBS_SORT` | `WS_EX_CLIENTEDGE` |
| `ComboBoxEx`, `ComboBoxEx32` | ComboBoxEx32 | `WS_VISIBLE`, `WS_BORDER`, `WS_TABSTOP`, `CBS_DROPDOWNLIST` | none |
| `ListBox` | ListBox | `WS_VISIBLE`, `WS_HSCROLL`, `WS_VSCROLL`, `WS_BORDER`, `WS_TABSTOP`, `LBS_STANDARD`, `LBS_HASSTRINGS`, `LBS_SORT`, `LBS_NOTIFY` | `WS_EX_CLIENTEDGE` |
| `ListView`, `SysListView32` | SysListView32 | `WS_VISIBLE`, `WS_CLIPCHILDREN`, `WS_TABSTOP`, `LVS_REPORT`, `LVS_SHOWSELALWAYS`, `LVS_SHAREIMAGELISTS`, `LVS_AUTOARRANGE`, `LVS_EDITLABELS`, `LVS_ALIGNTOP` | `WS_EX_CLIENTEDGE` |
| `TreeView`, `SysTreeView32` | SysTreeView32 | `WS_VISIBLE`, `WS_BORDER`, `WS_TABSTOP`, `TVS_HASBUTTONS`, `TVS_HASLINES`, `TVS_LINESATROOT`, `TVS_SHOWSELALWAYS` | `WS_EX_CLIENTEDGE` |
| `Header`, `SysHeader32` | SysHeader32 | `WS_VISIBLE`, `CCS_TOP`, `HDS_HORZ`, `HDS_BUTTONS` | none |
| `Toolbar`, `ToolbarWindow32` | ToolbarWindow32 | `WS_VISIBLE`, `WS_CLIPCHILDREN`, `WS_CLIPSIBLINGS`, `CCS_TOP`, `WS_BORDER`, `TBSTYLE_FLAT`, `TBSTYLE_TOOLTIPS` | none |
| `Rebar`, `RebarWindow32` | ReBarWindow32 | `WS_VISIBLE`, `WS_BORDER`, `WS_CLIPCHILDREN`, `WS_CLIPSIBLINGS`, `CCS_NODIVIDER`, `RBS_VARHEIGHT`, `RBS_BANDBORDERS` | none |
| `StatusBar`, `msctls_statusbar32` | msctls_statusbar32 | `WS_VISIBLE`, `WS_CLIPCHILDREN`, `WS_CLIPSIBLINGS`, `CCS_BOTTOM`, `SBARS_SIZEGRIP` | none |
| `ProgressBar`, `msctls_progress32` | msctls_progress32 | `WS_VISIBLE` | none |
| `Trackbar`, `msctls_trackbar32`, `Slider` | msctls_trackbar32 | `WS_VISIBLE`, `WS_TABSTOP`, `TBS_AUTOTICKS`, `TBS_HORZ`, `TBS_BOTTOM`, `TBS_TOOLTIPS` | none |
| `UpDown`, `msctls_updown32` | msctls_updown32 | `WS_VISIBLE`, `UDS_WRAP`, `UDS_ARROWKEYS`, `UDS_ALIGNRIGHT`, `UDS_SETBUDDYINT` | none |
| `Tab`, `TabControl`, `SysTabControl32` | SysTabControl32 | `WS_VISIBLE`, `WS_GROUP`, `WS_TABSTOP`, `WS_CLIPCHILDREN`, `WS_CLIPSIBLINGS`, `TCS_TABS`, `TCS_SINGLELINE`, `TCS_RAGGEDRIGHT` | `WS_EX_CONTROLPARENT`, always added |
| `DateTimePicker`, `SysDateTimePick32` | SysDateTimePick32 | `WS_VISIBLE`, `WS_TABSTOP`, `DTS_SHORTDATEFORMAT` | none |
| `MonthCalendar`, `MonthCal`, `SysMonthCal32` | SysMonthCal32 | `WS_VISIBLE`, `WS_TABSTOP` | `WS_EX_CLIENTEDGE` |
| `IPAddress`, `SysIPAddress32` | SysIPAddress32 | `WS_VISIBLE`, `WS_TABSTOP` | `WS_EX_CLIENTEDGE` |
| `HotKey`, `msctls_hotkey32` | msctls_hotkey32 | `WS_VISIBLE`, `WS_TABSTOP` | `WS_EX_CLIENTEDGE` |
| `Animate`, `Animation`, `SysAnimate32` | SysAnimate32 | `WS_VISIBLE`, `ACS_TRANSPARENT` | none |
| `SysLink` | SysLink | `WS_VISIBLE`, `WS_TABSTOP` | none |
| `Pager`, `SysPager` | SysPager | `WS_VISIBLE`, `WS_TABSTOP`, `PGS_HORZ` | none |
| `SizeGrip`, `SizeBox`, `SizeBar` | Scrollbar | `WS_VISIBLE`, `SBS_SIZEGRIP`, `SBS_SIZEBOXBOTTOMRIGHTALIGN` | none |
| `HScrollBar`, `VScrollBar` | Scrollbar | `WS_VISIBLE`, `WS_TABSTOP`, `SBS_HORZ` or `SBS_VERT` | none |

For `Button`, a `dwStyle` of just `BS_FLAT`, `BS_DEFPUSHBUTTON`, `BS_BITMAP`, `BS_ICON`,
`BS_OWNERDRAW`, `BS_SPLITBUTTON`, `BS_DEFSPLITBUTTON`, `BS_COMMANDLINK` or `BS_DEFCOMMANDLINK`
gives that kind of button with the usual visible, tab-stop and alignment styles; likewise
`WS_GROUP` alone for `RadioButton` and `SBARS_TOOLTIPS` alone for `StatusBar`.

Some controls are set up further: a progress bar and a trackbar get the range 0 to 100 (the
trackbar a page size of 10), an up-down control base 10, range 0 to 100 and position 0, a scroll
bar range 0 to 100, a toolbar a button size scaled for DPI, and a date and time picker its font
for the drop-down calendar. A size grip ignores the position and size given and sits in the
bottom-right corner of the client area. `RichEdit` loads `MSFTEDIT.DLL` the first time, and the
destructor frees it.

For `BitmapLabel`, `IconLabel`, `BitmapButton` and `IconButton`, `wszTitle` names the bitmap or
icon in the program's resources: a name, or `#` and a number such as `"#101"`. The image is
loaded and given to the control, and is yours to delete before the program ends.

| Parameter | Meaning |
| --- | --- |
| `wszClassName` | A class name or alias from the table. |
| `hParent` | The parent window, or `NULL` for the object's window. |
| `cID` | The control identifier, unique among its siblings; -1 for a control you never address. |
| `wszTitle` | The control's text, or the image resource for the image controls. |
| `x`, `y` | The position in the parent's client area. |
| `nWidth`, `nHeight` | The size. |
| `dwStyle`, `dwExStyle` | Styles, or -1 for the defaults. |
| `lpParam` | Passed to the control in `CREATESTRUCT.lpCreateParams`. |

**Returns** the control's handle, or `NULL` on failure (an empty class name, an unknown class, a
creation error).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim hList as HWND = pWindow->AddControl( "ListView", hwnd, 1001, "", 10, 10, 300, 200 )
pWindow->AddControl( "Button", hwnd, IDOK, "&OK", 230, 220, 80, 26, BS_DEFPUSHBUTTON )
```

Microsoft Learn: [CreateWindowExW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createwindowexw)

### ControlHandle

```freebasic
function ControlHandle( byval cID as long ) as HWND
```

**Returns** the handle of the object's window's child control with identifier `cID`, or `NULL`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
EnableWindow( pWindow->ControlHandle( IDOK ), false )
```

Microsoft Learn: [GetDlgItem](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getdlgitem)

### ControlGetStyle, ControlGetExStyle

```freebasic
function ControlGetStyle( byval hWnd as HWND ) as LONG_PTR
function ControlGetExStyle( byval hWnd as HWND ) as LONG_PTR
```

**Returns** the `WS_*` (and class-specific) style, or the `WS_EX_*` style, of any window.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->ControlGetStyle( hCtrl ) and WS_DISABLED then print "disabled"
```

Microsoft Learn: [GetWindowLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowlongptrw)

### ControlSetStyle, ControlSetExStyle

```freebasic
function ControlSetStyle( byval hWnd as HWND, byval dwStyle as LONG_PTR ) as LONG_PTR
function ControlSetExStyle( byval hWnd as HWND, byval dwExStyle as LONG_PTR ) as LONG_PTR
```

Replace the style, or the extended style, of any window and redraw its frame.

**Returns** the previous style.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->ControlSetExStyle( hCtrl, WS_EX_STATICEDGE )
```

### ControlAddStyle, ControlAddExStyle

```freebasic
function ControlAddStyle( byval hWnd as HWND, byval dwStyle as LONG_PTR ) as LONG_PTR
function ControlAddExStyle( byval hWnd as HWND, byval dwExStyle as LONG_PTR ) as LONG_PTR
```

Add styles, or extended styles, to those a window has, and redraw its frame.

**Returns** the previous style.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->ControlAddStyle( hCtrl, BS_FLAT )
```

### ControlRemoveStyle, ControlRemoveExStyle

```freebasic
function ControlRemoveStyle( byval hWnd as HWND, byval dwStyle as LONG_PTR ) as LONG_PTR
function ControlRemoveExStyle( byval hWnd as HWND, byval dwExStyle as DWORD ) as LONG_PTR
```

Remove styles, or extended styles, from a window and redraw its frame.

**Returns** the previous style.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->ControlRemoveExStyle( hCtrl, WS_EX_CLIENTEDGE )
```

### SetControlSubclass

```freebasic
function SetControlSubclass( byval hCtl as HWND, byval pfnSubclass as any ptr, byval uIdSubclass as UINT_PTR, byval dwRefData as any ptr ) as boolean
function SetControlSubclass( byval hCtl as HWND, byval pfnSubclass as any ptr, byval uIdSubclass as UINT_PTR, byval dwRefData as DWORD_PTR ) as boolean
```

Subclasses a control with `SetWindowSubclass`: `pfnSubclass` then sees the control's messages
before the control does. The procedure and `uIdSubclass` together name the subclass; calling
again with the same pair only changes `dwRefData`. The procedure has the shape below, passes on
what it does not handle with `DefSubclassProc`, and removes itself with `RemoveWindowSubclass`,
at the latest on `WM_NCDESTROY`. A subclass works only on the thread that made the control.

| Parameter | Meaning |
| --- | --- |
| `hCtl` | The control; not `NULL` and not the object's own window. |
| `pfnSubclass` | The subclass procedure. |
| `uIdSubclass` | An identifier of your choice, passed to the procedure. |
| `dwRefData` | A value or pointer of your choice, passed to the procedure. |

**Returns** `true` when the subclass is installed; `false` for `NULL` or the object's window.

**Example**

```freebasic
function EditSubclass( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM, byval uIdSubclass as UINT_PTR, byval dwRefData as DWORD_PTR ) as LRESULT
    select case uMsg
        case WM_CHAR
            if wParam = 32 then return 0          ' no spaces
        case WM_NCDESTROY
            RemoveWindowSubclass( hwnd, @EditSubclass, uIdSubclass )
    end select
    return DefSubclassProc( hwnd, uMsg, wParam, lParam )
end function

sub NoSpaces( byval pWindow as CWindow ptr, byval hEdit as HWND )
    pWindow->SetControlSubclass( hEdit, @EditSubclass, 1, NULL )
end sub
```

Microsoft Learn: [SetWindowSubclass](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-setwindowsubclass)

### SetControlCallback

```freebasic
function SetControlCallback( byval cID as long, byval pCallback as any ptr ) as boolean
function SetControlCallback( byval hCtl as HWND, byval pCallback as any ptr ) as boolean
```

Gives a control a procedure of its own for the `WM_COMMAND` and `WM_NOTIFY` messages it sends to
the object's window. CWindow calls `pCallback`, shaped like a window procedure, with the
**control's** handle and the message's `wParam` and `lParam`, and returns what it returns: your
main window procedure does not see those messages. Only controls whose parent is the object's
window send their messages there; the identifier form looks among that window's children.
Calling again replaces the callback.

**Returns** `true`; `false` when the control does not exist.

**Example**

```freebasic
function OkClicked( byval hCtl as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    if uMsg = WM_COMMAND andalso CBCTLMSG( wParam, lParam ) = BN_CLICKED then
        SendMessageW( GetParent( hCtl ), WM_CLOSE, 0, 0 )
    end if
    return 0
end function

sub WireUp( byval pWindow as CWindow ptr )
    pWindow->SetControlCallback( IDOK, @OkClicked )
end sub
```

### GetControlCallback

```freebasic
function GetControlCallback( byval cID as long ) as any ptr
function GetControlCallback( byval hCtl as HWND ) as any ptr
```

**Returns** the callback set with [SetControlCallback](#setcontrolcallback) for a control, or
`NULL`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->GetControlCallback( IDOK ) then print "IDOK has its own callback"
```

### GetControlCallbackItem

```freebasic
function GetControlCallbackItem( byval cID as long ) as long
function GetControlCallbackItem( byval hCtl as HWND ) as long
```

**Returns** the index of the control's entry in the object's callback list, or -1 when it has
none.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
print "entry"; pWindow->GetControlCallbackItem( hCtrl )
```

### SetCtlColors

```freebasic
function SetCtlColors( byval hCtl as ..HWND, byval foreColor as COLORREF, byval backColor as COLORREF ) as boolean
function SetCtlColors( byval cID as long, byval foreColor as COLORREF, byval backColor as COLORREF ) as boolean
```

Gives a control a text colour and a background colour, and redraws it. CWindow applies them by
answering the `WM_CTLCOLOREDIT`, `WM_CTLCOLORLISTBOX` and `WM_CTLCOLORSTATIC` messages that edit,
list box and static controls send to their parent, so the control must be a child of the object's
window. Push buttons are not coloured this way ([CXpButton](CXpButton) is a button that can be).
The identifier form looks among the window's children. Calling again replaces the colours.

**Returns** `true`; `false` when the control does not exist.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->SetCtlColors( hCtrl, RGB_WHITE, RGB_NAVY )
```

Microsoft Learn: [WM_CTLCOLORSTATIC](https://learn.microsoft.com/en-us/windows/win32/controls/wm-ctlcolorstatic)

### GetForeColor, GetBackColor

```freebasic
function GetForeColor( byval nItem as long ) as COLORREF
function GetForeColor( byval hCtl as HWND ) as COLORREF
function GetBackColor( byval nItem as long ) as COLORREF
function GetBackColor( byval hCtl as HWND ) as COLORREF
```

Read the text and background colours set with [SetCtlColors](#setctlcolors) or
[SetBackColor](#setbackcolor), by control or by entry index from [GetColorItem](#getcoloritem).

**Returns** the colour, or 0 when none is set.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
print "text "; hex( pWindow->GetForeColor( hCtrl ) ); ", background "; hex( pWindow->GetBackColor( hCtrl ) )
```

### GetColorItem

```freebasic
function GetColorItem( byval hwnd as ..HWND ) as long
```

**Returns** the index of the window's or control's entry in the object's colour list, or -1.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->GetColorItem( hCtrl ) = -1 then pWindow->SetCtlColors( hCtrl, RGB_BLACK, RGB_LIGHTYELLOW )
```

### UserData

```freebasic
property UserData( byval idx as long ) as LONG_PTR
property UserData( byval idx as long, byval newValue as LONG_PTR )
```

One hundred values of your own, indexes 0 to 99, kept in the object: a pointer to your state, a
handle, a flag. Reading outside the range gives 0 and writing outside it is ignored.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->UserData( 0 ) = 42
print pWindow->UserData( 0 )
```

### ControlSetUser

```freebasic
function ControlSetUser( byval cid as long, byval index as long, byval userValue as LONG_PTR ) as boolean
function ControlSetUser( byval hctl as HWND, byval index as long, byval userValue as LONG_PTR ) as boolean
```

Stores one of ten values of your own (indexes 0 to 9) for a control. The identifier form looks
among the object's window's children.

**Returns** `true`; `false` for an index outside 0 to 9 or a control that does not exist.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->ControlSetUser( hCtrl, 0, 1500 )   ' e.g. a record number
```

### ControlGetUser

```freebasic
function ControlGetUser( byval cid as long, byval index as long ) as LONG_PTR
function ControlGetUser( byval hctl as HWND, byval index as long ) as LONG_PTR
```

**Returns** the value stored with [ControlSetUser](#controlsetuser), or 0 when there is none or
the index is outside 0 to 9.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
dim nRecord as LONG_PTR = pWindow->ControlGetUser( hCtrl, 0 )
```

### GetUserDataItem

```freebasic
function GetUserDataItem( byval cid as long ) as long
function GetUserDataItem( byval hctl as HWND ) as long
```

**Returns** the index of the control's entry in the object's user data list, or -1 when nothing is
stored for it.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->GetUserDataItem( hCtrl ) = -1 then print "no values stored"
```

### AnchorControl

```freebasic
function AnchorControl( byval cID as long, byval nAnchorMode as long ) as boolean
function AnchorControl( byval hCtl as HWND, byval nAnchorMode as long ) as boolean
function AnchorControl( byval hParent as HWND, byval cID as long, byval nAnchorMode as long ) as boolean
```

Keeps a control in place relative to an edge or the centre of its parent, or stretches it, when
the parent is resized. The call records the control's present distances from its parent's edges
and centre; whenever the object's window gets `WM_SIZE` for a restore or a maximize, CWindow moves
every anchored control among its descendants by its mode, relative to that control's own parent,
and repaints the window. Lay the controls out first, then anchor them. Calling again replaces the
mode.

| Mode | The control keeps | and |
| --- | --- | --- |
| `ANCHOR_NONE` | its place and size | is never moved |
| `ANCHOR_WIDTH` | its left, top and height | stretches to keep its right margin |
| `ANCHOR_RIGHT` | its size, top and right margin | |
| `ANCHOR_CENTER_HORZ` | its size, top and offset from the horizontal centre | |
| `ANCHOR_HEIGHT` | its left, top and width | stretches to keep its bottom margin |
| `ANCHOR_HEIGHT_WIDTH` | its left and top | stretches both ways |
| `ANCHOR_HEIGHT_RIGHT` | its width, top and right margin | stretches to keep its bottom margin |
| `ANCHOR_BOTTOM` | its size, left and bottom margin | |
| `ANCHOR_BOTTOM_WIDTH` | its height, left and bottom margin | stretches to keep its right margin |
| `ANCHOR_BOTTOM_RIGHT` | its size and its right and bottom margins | |
| `ANCHOR_CENTER_HORZ_BOTTOM` | its size, bottom margin and offset from the horizontal centre | |
| `ANCHOR_CENTER_VERT` | its size and left | is centred vertically |
| `ANCHOR_CENTER_VERT_RIGHT` | its size and right margin | is centred vertically |
| `ANCHOR_CENTER` | its size and offset from the centre | |

| Parameter | Meaning |
| --- | --- |
| `cID` | The control's identifier: among the object's window's children, or among `hParent`'s. |
| `hCtl` | The control. |
| `hParent` | The control's parent, for a control inside a child window such as a group of controls on a page. |
| `nAnchorMode` | One of the modes; values outside the range are clamped to it. |

**Returns** `true`; `false` when the control does not exist.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->AnchorControl( IDCANCEL, ANCHOR_BOTTOM_RIGHT )
pWindow->AnchorControl( hCtrl, ANCHOR_HEIGHT_WIDTH )
```

### AdjustControls

```freebasic
function AdjustControls() as boolean
```

Moves the anchored controls now, as `WM_SIZE` does. Useful after changing the window's size
while it is minimized, or after anchoring controls in a window that is already shown.

**Returns** `true`; `false` when no control is anchored.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->AdjustControls()
```

Microsoft Learn: [EnumChildWindows](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumchildwindows)

### GetAnchorItem

```freebasic
function GetAnchorItem( byval hwndCtl as HWND ) as long
```

**Returns** the index of the control's entry in the object's anchor list, or -1 when it is not
anchored.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->GetAnchorItem( hCtrl ) >= 0 then print "anchored"
```

### SetViewPort

```freebasic
function SetViewPort( byval nWidth as long, byval nHeight as long ) as boolean
```

Makes the window scrollable. The present client area becomes the size of the content, the window
is shrunk to a client area of `nWidth` × `nHeight` 96-DPI units, and from then on CWindow adds
scroll bars and scrolls the client area in steps of 10 pixels. So: size the window for all its
controls with [SetClientSize](#setclientsize), add the controls, then call `SetViewPort`.

The scroll bars appear on the window's next `WM_SIZE`; call [Resize](#resize) to have them at
once. The scroll bars' range is set in pixels while CWindow keeps the position in 10-pixel steps,
so the thumb stays near the start of its track and dragging it scrolls further than it moves;
clicking the arrows and the track scrolls the content step by step.

**Returns** `true`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->SetClientSize( 320, 600 )   ' room for every control
pWindow->SetViewPort( 320, 300 )     ' show half of it
pWindow->Resize()
```

Microsoft Learn: [SetScrollInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setscrollinfo)

### IsWindowScrollable

```freebasic
function IsWindowScrollable() as boolean
```

**Returns** `true` once [SetViewPort](#setviewport) has been called.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->IsWindowScrollable() then pWindow->ResetScrollBars()
```

### ResetScrollBars

```freebasic
sub ResetScrollBars
```

Scrolls the content of a scrollable window back to its origin and sets both scroll positions to 0.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->ResetScrollBars()
```

Microsoft Learn: [ScrollWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-scrollwindow)

### SetupScrollBars

```freebasic
sub SetupScrollBars
```

Works out the scroll ranges from the content size and the present client size and sets the
scroll bars. CWindow calls it, after [ResetScrollBars](#resetscrollbars), on every `WM_SIZE` of a
scrollable window.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->ResetScrollBars()
pWindow->SetupScrollBars()
```

### OnVScroll, OnHScroll

```freebasic
sub OnVScroll( byval wParam as WPARAM, byval lParam as LPARAM )
sub OnHScroll( byval wParam as WPARAM, byval lParam as LPARAM )
```

Scroll a scrollable window as `WM_VSCROLL` and `WM_HSCROLL` ask: a line is 10 pixels, and Top
and Bottom from the scroll bar's menu go to the ends. Vertically a page jumps by the whole scroll
range; horizontally it is 10 lines. CWindow calls them itself for a scrollable window; `lParam` is not used.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->OnVScroll( SB_LINEDOWN, 0 )
```

Microsoft Learn: [WM_VSCROLL](https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll)

### OnSize

```freebasic
sub OnSize( byval wParam as WPARAM, byval lParam as LPARAM )
```

Calls [ResetScrollBars](#resetscrollbars) and [SetupScrollBars](#setupscrollbars); `wParam` and
`lParam` are not used. CWindow does the same itself on `WM_SIZE`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->OnSize( SIZE_RESTORED, 0 )
```

### Stabilize

```freebasic
function Stabilize() as boolean
```

Stops the user from closing the window: removes **Close** and the separator above it from the
system menu, which also disables the close button, and ignores the close command that Alt+F4 and
the button send. The program can still close the window with `WM_CLOSE` or `DestroyWindow`. Call
it once: each call removes the last two items of the menu.

**Returns** `true`; `false` when the window has no system menu.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->Stabilize()   ' while saving
```

Microsoft Learn: [GetSystemMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmenu)

### NonStable

```freebasic
function NonStable() as boolean
```

Lets the user close the window again: restores the standard system menu and stops ignoring the
close command.

**Returns** `true`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->NonStable()
```

### IsStabilized, IsNonStable

```freebasic
function IsStabilized() as boolean
function IsNonStable() as boolean
```

**Returns** whether the window is stabilized (`IsStabilized`) or closeable (`IsNonStable`).

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->IsStabilized() then print "still busy"
```

### AccelHandle

```freebasic
property AccelHandle() as HACCEL
property AccelHandle( byval hAccel as HACCEL )
```

Reads the accelerator table [DoEvents](#doevents) translates keys with, or `NULL`. Setting it
destroys the present table and the keys added for the next one, and hands the new table to the
object, which destroys it in turn; `NULL` just removes the table.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->AccelHandle = LoadAcceleratorsW( pWindow->InstanceHandle, cast(LPCWSTR, 200) )
```

Microsoft Learn: [TranslateAcceleratorW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-translateacceleratorw)

### AddAccelerator

```freebasic
sub AddAccelerator overload( byval fvirt as ubyte, byval wKey as WORD, byval cmd as WORD )
sub AddAccelerator overload( byval fvirt as ubyte, byref wszKey as wstring, byval cmd as WORD )
```

Adds a key to the accelerator table being built; nothing happens until
[CreateAcceleratorTable](#createacceleratortable). When the key is pressed, the window gets
`WM_COMMAND` with `cmd` in the low word of `wParam` and 1 in the high word.

| Parameter | Meaning |
| --- | --- |
| `fvirt` | `FVIRTKEY` (the key is a virtual-key code) with any of `FCONTROL`, `FSHIFT`, `FALT`. |
| `wKey` | A virtual-key code such as `VK_F5`, or a character code without `FVIRTKEY`. |
| `wszKey` | The key as a string; its first character's code is used, so `"S"` is the S key. |
| `cmd` | The command identifier. |

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->AddAccelerator( FVIRTKEY or FCONTROL, "S", 1001 )   ' Ctrl+S
pWindow->AddAccelerator( FVIRTKEY, VK_F5, 1002 )             ' F5
pWindow->CreateAcceleratorTable()
```

Microsoft Learn: [ACCEL](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-accel)

### CreateAcceleratorTable

```freebasic
function CreateAcceleratorTable() as HACCEL
```

Builds the accelerator table from every key added so far, replacing the present table. The keys
stay in the list, so adding more and calling again builds a table with all of them. The object
destroys the table.

**Returns** the table, or `NULL` when no key has been added.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow->CreateAcceleratorTable() = NULL then print "no accelerators"
```

Microsoft Learn: [CreateAcceleratorTableW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createacceleratortablew)

### DestroyAcceleratorTable

```freebasic
sub DestroyAcceleratorTable()
```

Destroys the accelerator table and empties the list of keys, so that a new table can be built from
scratch.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
pWindow->DestroyAcceleratorTable()
pWindow->AddAccelerator( FVIRTKEY or FCONTROL, "N", 1003 )
pWindow->CreateAcceleratorTable()
```

## Related functions

| Function | Does |
| --- | --- |
| [CWindowPtr](#cwindowptr) | Returns the `CWindow` of a window, or of the window being created. |
| [CWindowOwnerPtr](#cwindowownerptr) | Returns the `CWindow` of the top-level window that owns a window or control. |
| [InputBox](#inputbox) | Asks the user for a line of text. |
| [CWindow_RegisterClass](#cwindow_registerclass) | Registers a window class the way `Create` does. |
| [CWindow_WindowProc](#cwindow_windowproc) | The window procedure every `CWindow` window has. |
| [ANCHORPROPERTY, WINDOWCOLORS, CTLUSERDATA, CTLCALLBACKS](#anchorproperty-windowcolors-ctluserdata-ctlcallbacks) | The records a `CWindow` keeps for its controls. |

### CWindowPtr

```freebasic
function CWindowPtr overload( byval hwnd as HWND ) as CWindow ptr
function CWindowPtr overload( byval lParam as LPARAM ) as CWindow ptr
function CWindowPtr overload( byval pCreateStruct as CREATESTRUCT ptr ) as CWindow ptr
```

Gets back to the `CWindow` object from a window procedure. The `HWND` form reads the pointer that
`Create` stores in the window, so it works for windows made by a `CWindow` once `Create` has
returned; in `WM_CREATE` it is still `NULL`. The `LPARAM` and `CREATESTRUCT ptr` forms read the
creation parameter, so they work in `WM_CREATE` only, where `lParam` points to the
`CREATESTRUCT`.

**Returns** the object, or `NULL`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowPtr( hwnd )
if pWindow then pWindow->SetClientSize( 400, 300 )
```

Microsoft Learn: [CREATESTRUCTW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-createstructw)

### CWindowOwnerPtr

```freebasic
function CWindowOwnerPtr overload( byval hwnd as HWND ) as CWindow ptr
```

Like `CWindowPtr( hwnd )`, but for any window or control: it goes up to the top-level window
that owns `hwnd` and returns that window's object. For a control on a [tab page](CTabPage) that is
the main window's object, not the page's.

**Returns** the object, or `NULL`.

**Example**

```freebasic
dim pWindow as CWindow ptr = CWindowOwnerPtr( hCtrl )
if pWindow then print "the main window is"; pWindow->ClientWidth; " units wide"
```

Microsoft Learn: [GetAncestor](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getancestor)

### InputBox

```freebasic
function InputBox( byval hParent as HWND = NULL, byval x as long = 0, byval y as long = 0, byref ustrCaption as ustring = "", byref ustrPrompt as ustring = "", byref ustrText as ustring = "", byval nLen as long = 260, byval bPassword as boolean = false ) as ustring
```

Shows a small modal window with a prompt, an edit box holding `ustrText` (selected) and OK and
Cancel buttons labelled in the language of Windows, and waits for the user. The parent is disabled
while it is open. It runs a message loop of its own and returns when it closes.

| Parameter | Meaning |
| --- | --- |
| `hParent` | The window it belongs to, or `NULL`. |
| `x`, `y` | Its position in 96-DPI screen units; when both are 0 it is centred over `hParent`, or in the work area. |
| `ustrCaption` | The caption. |
| `ustrPrompt` | The text above the edit box. |
| `ustrText` | The text to start with. When it is longer than `nLen` the variable passed is itself cut to `nLen` characters. |
| `nLen` | The most characters the user can type: 260 by default, 0 means 260, and anything below 1 or above 2048 means 2048. |
| `bPassword` | `true` shows each character as an asterisk. |

**Returns** the text in the edit box when OK was pressed, or `""` for Cancel, Esc or the close
button.

**Example**

```freebasic
dim sName as ustring = InputBox( hwnd, 0, 0, "New customer", "Customer name:" )
if len( sName ) then print "adding "; sName
```

### CWindow_RegisterClass

```freebasic
function CWindow_RegisterClass( byref wszClassName as const wstring, byval hInstance as HINSTANCE, byval lpfnWndProc as WNDPROC ) as ATOM
```

Registers a window class with the settings `Create` uses: `CS_DBLCLKS`, `CS_HREDRAW` and
`CS_VREDRAW`, the arrow cursor, the `COLOR_3DFACE` background, no icon and room in each window for
one pointer. An empty name registers the next generated name, `FBWindowClass:` and a number.
`Create` calls it; a program rarely needs to.

**Returns** the class atom, or 0 when the class could not be registered (for example because the
name is taken).

**Example**

```freebasic
dim wAtom as ATOM = CWindow_RegisterClass( "ToolPalette", GetModuleHandleW( NULL ), @DefWindowProcW )
if wAtom = 0 then print "error"; GetLastError()
```

Microsoft Learn: [RegisterClassExW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerclassexw)

### CWindow_WindowProc

```freebasic
function CWindow_WindowProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
```

The window procedure of every window `Create` makes. It handles, before your procedure sees the
message:

| Message | What it does |
| --- | --- |
| `WM_CREATE` | Calls your procedure with the message and returns its result (-1 cancels the creation). |
| `WM_SYSCOMMAND` | Ignores `SC_CLOSE` while the window is [stabilized](#stabilize). |
| `WM_COMMAND`, `WM_NOTIFY` | Sends the message to the control's [callback](#setcontrolcallback), if it has one, and returns. |
| `WM_ERASEBKGND` | Fills the client area with the [background colour](#setbackcolor), if one is set, and returns. |
| `WM_CTLCOLOREDIT`, `WM_CTLCOLORLISTBOX`, `WM_CTLCOLORSTATIC` | Applies the control's [colours](#setctlcolors), if it has any, and returns. |
| `WM_SIZE` | Moves the [anchored](#anchorcontrol) controls on a restore or maximize, and sets up the scroll bars of a [scrollable](#setviewport) window. |
| `WM_HSCROLL`, `WM_VSCROLL` | Scrolls a scrollable window. |

Then it calls your procedure and returns its result; with no procedure of yours, it calls
`DefWindowProcW`.

**Example**

```freebasic
dim pfn as WNDPROC = @CWindow_WindowProc
print "made by CWindow: "; GetWindowLongPtrW( hwnd, GWLP_WNDPROC ) = cast(LONG_PTR, pfn)
```

Microsoft Learn: [DefWindowProcW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-defwindowprocw)

### ANCHORPROPERTY, WINDOWCOLORS, CTLUSERDATA, CTLCALLBACKS

```freebasic
type ANCHORPROPERTY
   hwndCtl as HWND
   anchor  as long
   rc      as RECT
   centerX as long
   centerY as long
end type

type WINDOWCOLORS
   hwnd as ..HWND
   foreColor as COLORREF
   backColor as COLORREF
end type

type CTLUSERDATA
   hCtl as HWND
   Values (0 to 9) as LONG_PTR
end type

type CTLCALLBACKS
   hCtl as HWND
   pCallback as any ptr
end type
```

The entries a `CWindow` keeps, one per control: an anchor (the mode, the margins in `rc` and the
offsets from the parent's centre, in pixels), a pair of colours, ten user values, a callback. The
`Get…Item` members return indexes into these lists. Programs rarely use the types themselves.

**Example**

```freebasic
dim ap as ANCHORPROPERTY
ap.hwndCtl = hCtrl
ap.anchor = ANCHOR_BOTTOM_RIGHT
```

## See also

- [sys/win/gui](SysWin-Gui) for the module and its other classes
- [CDialog](CDialog), the same services for dialog boxes
- [CTabPage](CTabPage), a `CWindow` that is one page of a tab control
- [gui macros and helpers](SysWin-Gui-Procedures) for `CBCTL`, `CBCTLMSG` and the other message helpers
- [Window size and position](SysWin-Window-Size-and-Position), the pixel-based helpers behind `SetClientSize` and `Center`
- [Display, screen and DPI](SysWin-Display-and-DPI) for DPI awareness and scaling ratios
- [Colours](SysWin-Colors) for the `RGB_*` constants
