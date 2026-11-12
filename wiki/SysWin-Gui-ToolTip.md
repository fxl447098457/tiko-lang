[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **ToolTip**

# ToolTip

Creates tooltips for controls and windows and sets their text, timing, colours and place.

A tooltip control is a small pop-up window that shows a line of text when the mouse rests on a
**tool**: a control, or a rectangle in a window's client area. One tooltip control can serve any
number of tools. Every function here is written with the namespace:
`ToolTip.SetMaxTipWidth( hTip, 300 )`.

The quick way is [AddTooltip](#addtooltip): it creates a tooltip control for one control or
window, registers it as a tool and returns the tooltip's handle; [SetTooltipText](#settooltiptext)
changes the text later and [DeleteTooltip](#deletetooltip) removes the tool. Each call to
`AddTooltip` makes a new tooltip control, and that control has **no owner**: it is not destroyed
with your window, so destroy it with `DestroyWindow` when the window closes.

The other functions work on any tooltip control and are thin wrappers over its messages. A tool
is named by two members of a `TOOLINFOW`: `hwnd`, the window that holds it, and `uId`. For a
control registered with `TTF_IDISHWND` (as `AddTooltip` does), `hwnd` is the control's parent and
`uId` the control's handle; for a rectangle, `hwnd` is the window and `uId` a number of your own.
Functions that take a `TOOLINFOW` fill in its `cbSize` for you.

A few messages need version 6 of the common controls, which a program gets from a manifest or
from `EnableVisualStyles()`: without it, [GetTitle](#gettitle) reads nothing and
[GetBubbleSize](#getbubblesize) ended the test program. In the examples on this page, `hCtrl` is
a tooltip control.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

Two buttons with tooltips, one of them a balloon. Clicking **Count** rewrites its own tooltip;
the tooltips are destroyed with the window.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_COUNT = 101

dim shared as HWND hTipCount, hTipClose
dim shared as long nClicks

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    EnableVisualStyles()
    dim pWindow as CWindow = "TipDemo"
    dim hWin as HWND = pWindow.Create( NULL, "ToolTip", @WndProc )
    pWindow.SetClientSize( 300, 120 )
    pWindow.Center()
    dim hCount as HWND = pWindow.AddControl( "Button", hWin, IDC_COUNT, "&Count", 40, 45, 100, 30 )
    dim hClose as HWND = pWindow.AddControl( "Button", hWin, IDCANCEL, "&Close", 160, 45, 100, 30 )
    hTipCount = ToolTip.AddTooltip( hCount, "Not clicked yet" )
    hTipClose = ToolTip.AddTooltip( hClose, "Closes the window", true )
    ToolTip.SetDelayTime( hTipCount, TTDT_INITIAL, 200 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                select case CBCTL( wParam, lParam )
                    case IDC_COUNT
                        nClicks += 1
                        dim text as ustring = "Clicked " & nClicks & " times"
                        ToolTip.SetTooltipText( hTipCount, GetDlgItem( hwnd, IDC_COUNT ), text )
                    case IDCANCEL
                        SendMessageW( hwnd, WM_CLOSE, 0, 0 )
                end select
            end if
            return 0
        case WM_DESTROY
            DestroyWindow( hTipCount )
            DestroyWindow( hTipClose )
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
| [AddTooltip](#addtooltip) | Creates a tooltip control for a control or window. |
| [SetTooltipText](#settooltiptext) | Changes the text of a tooltip made by `AddTooltip`. |
| [DeleteTooltip](#deletetooltip) | Removes the tool that `AddTooltip` registered. |
| [AddTool](#addtool) | Registers a tool from a `TOOLINFOW`. |
| [DelTool](#deltool) | Removes a tool. |
| [GetToolCount](#gettoolcount) | Returns the number of tools. |
| [EnumTools](#enumtools) | Reads the tool at an index. |
| [GetToolInfo](#gettoolinfo) | Reads what the control keeps about a tool. |
| [SetToolInfo](#settoolinfo) | Changes what the control keeps about a tool. |
| [GetCurrentTool](#getcurrenttool) | Reads the tool the tip is being shown for. |
| [GetText](#gettext) | Returns or reads a tool's text. |
| [UpdateTipText](#updatetiptext) | Changes a tool's text. |
| [NewToolRect](#newtoolrect) | Moves a rectangle tool. |
| [HitTest](#hittest) | Finds the tool at a point. |
| [Activate, Deactivate](#activate-deactivate) | Turns the tooltip control on or off. |
| [Pop](#pop) | Hides the tip being shown. |
| [Popup](#popup) | Shows the tip at the last mouse position. |
| [Update](#update) | Redraws the tip being shown. |
| [RelayEvent](#relayevent) | Passes a mouse message on to the tooltip control. |
| [GetDelayTime](#getdelaytime) | Returns one of the delays, in milliseconds. |
| [SetDelayTime](#setdelaytime) | Sets one of the delays. |
| [GetMaxTipWidth](#getmaxtipwidth) | Returns the width at which text wraps. |
| [SetMaxTipWidth](#setmaxtipwidth) | Sets the width at which text wraps, allowing several lines. |
| [GetMargin](#getmargin) | Returns the margins around the text. |
| [SetMargin](#setmargin) | Sets the margins around the text. |
| [GetBubbleSize](#getbubblesize) | Returns the size the tip of a tool would have. |
| [AdjustRect](#adjustrect) | Converts between a text rectangle and a tip window rectangle. |
| [GetTipBkColor](#gettipbkcolor) | Returns the background colour. |
| [SetTipBkColor](#settipbkcolor) | Sets the background colour. |
| [GetTipTextColor](#gettiptextcolor) | Returns the text colour. |
| [SetTipTextColor](#settiptextcolor) | Sets the text colour. |
| [SetTitle](#settitle) | Adds a bold title and an icon to the tip. |
| [GetTitle](#gettitle) | Reads the title and icon. |
| [SetWindowTheme](#setwindowtheme) | Sets the visual style the tip is drawn with. |
| [SetDarkMode](#setdarkmode) | Draws the tip in the dark style. |
| [TrackActivate](#trackactivate) | Shows a tracking tip. |
| [TrackDeactivate](#trackdeactivate) | Hides a tracking tip. |
| [TrackPosition](#trackposition) | Moves a tracking tip. |

## Reference

### AddTooltip

```freebasic
function AddTooltip( byval hwnd as HWND, byref wszText as const wstring = "", byval bBalloon as boolean = false, byval bCentered as boolean = false ) as HWND
```

Creates a tooltip control (`TTS_ALWAYSTIP`, topmost, with no owner) and registers `hwnd` with it
as a tool, with `TTF_SUBCLASS` so that the tooltip watches the mouse by itself.

- For a **child window** (a control) the tool is the control: `hwnd` of the tool is its parent,
  `uId` the control, with `TTF_IDISHWND`.
- For a **top-level window** the tool is its client rectangle as it is now, with `uId = 0`. The
  rectangle does not follow later resizing; update it with [NewToolRect](#newtoolrect).

The text is copied. Destroy the returned window when it is no longer needed.

| Parameter | Meaning |
| --- | --- |
| `hwnd` | The control or window the tip is for. |
| `wszText` | The text; with the default `""` the tip stays hidden until text is set. |
| `bBalloon` | `true` for a balloon tip (`TTS_BALLOON`). |
| `bCentered` | `true` to centre the tip below the tool (`TTF_CENTERTIP`). |

**Returns** the tooltip control, or `NULL` when `hwnd` is not a window or the control could not
be created.

**Example**

```freebasic
dim hTip as HWND = ToolTip.AddTooltip( GetDlgItem( hwnd, IDOK ), "Saves the changes" )
dim hBalloon as HWND = ToolTip.AddTooltip( GetDlgItem( hwnd, IDCANCEL ), "Discards them", true )
```

Microsoft Learn: [TTM_ADDTOOL](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-addtool)

### SetTooltipText

```freebasic
sub SetTooltipText( byval hTooltip as HWND, byval hwnd as HWND, byref wszText as const wstring )
```

Replaces the text of the tool registered for `hwnd` the way [AddTooltip](#addtooltip) does it
(as a control for a child window, as a rectangle with `uId = 0` for a top-level window). Does
nothing when there is no such tool or a handle is `NULL`.

**Example**

```freebasic
dim hBtn as HWND = GetDlgItem( hwnd, IDOK )
dim hTip as HWND = ToolTip.AddTooltip( hBtn, "Save" )
ToolTip.SetTooltipText( hTip, hBtn, "Save the changes and close" )
```

Microsoft Learn: [TTM_SETTOOLINFO](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-settoolinfo)

### DeleteTooltip

```freebasic
sub DeleteTooltip( byval hTooltip as HWND, byval hwnd as HWND )
```

Removes the tool registered for `hwnd` by [AddTooltip](#addtooltip). The tooltip control itself
stays; destroy it with `DestroyWindow`.

**Example**

```freebasic
dim hBtn as HWND = GetDlgItem( hwnd, IDOK )
dim hTip as HWND = ToolTip.AddTooltip( hBtn, "Save" )
ToolTip.DeleteTooltip( hTip, hBtn )
DestroyWindow( hTip )
```

Microsoft Learn: [TTM_DELTOOL](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-deltool)

### AddTool

```freebasic
function AddTool( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr ) as boolean
```

Registers a tool described by a `TOOLINFOW`: `uFlags` (`TTF_IDISHWND`, `TTF_SUBCLASS`,
`TTF_CENTERTIP`, `TTF_TRACK` …), `hwnd`, `uId`, `rect` for a rectangle tool, and `lpszText`, which
the control copies (or `LPSTR_TEXTCALLBACK` to be asked with `TTN_GETDISPINFOW`). Without
`TTF_SUBCLASS`, pass the mouse messages to the control with [RelayEvent](#relayevent).

**Returns** `true` on success; `false` on failure or for a `NULL` pointer.

**Example**

```freebasic
dim ti as TOOLINFOW
ti.uFlags = TTF_SUBCLASS
ti.hwnd = hwnd : ti.uId = 7
SetRect( @ti.rect, 100, 100, 200, 150 )
ti.lpszText = @wstr( "This area" )
ToolTip.AddTool( hCtrl, @ti )
```

Microsoft Learn: [TTM_ADDTOOL](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-addtool)

### DelTool

```freebasic
sub DelTool overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr )
sub DelTool overload( byval hTooltip as HWND, byref ti as TOOLINFOW )
```

Removes the tool named by the `hwnd` and `uId` members.

**Example**

```freebasic
dim ti as TOOLINFOW
ti.hwnd = hwnd : ti.uId = 7
ToolTip.DelTool( hCtrl, ti )
```

Microsoft Learn: [TTM_DELTOOL](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-deltool)

### GetToolCount

```freebasic
function GetToolCount( byval hTooltip as HWND ) as long
```

Returns the number of tools the control has.

**Returns** the count; 1 for a control made by [AddTooltip](#addtooltip).

**Example**

```freebasic
print ToolTip.GetToolCount( hCtrl )
```

Microsoft Learn: [TTM_GETTOOLCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-gettoolcount)

### EnumTools

```freebasic
function EnumTools overload( byval hTooltip as HWND, byval iTool as DWORD, byval lpti as TOOLINFOW ptr ) as boolean
function EnumTools overload( byval hTooltip as HWND, byval iTool as DWORD, byref ti as TOOLINFOW ) as boolean
```

Reads the tool at zero-based index `iTool` into a `TOOLINFOW`. To get its text as well, point
`lpszText` at a buffer first.

**Returns** `true` when there is a tool at that index.

**Example**

```freebasic
dim ti as TOOLINFOW
for i as long = 0 to ToolTip.GetToolCount( hCtrl ) - 1
    if ToolTip.EnumTools( hCtrl, i, ti ) then print ti.hwnd; ti.uId
next
```

Microsoft Learn: [TTM_ENUMTOOLS](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-enumtools)

### GetToolInfo

```freebasic
function GetToolInfo overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr ) as boolean
function GetToolInfo overload( byval hTooltip as HWND, byref ti as TOOLINFOW ) as boolean
```

Reads what the control keeps about the tool named by `hwnd` and `uId` (flags, rectangle,
instance and, with a buffer in `lpszText`, the text).

**Returns** `true` when the tool exists.

**Example**

```freebasic
dim ti as TOOLINFOW
ti.hwnd = hwnd : ti.uId = cast( UINT_PTR, GetDlgItem( hwnd, IDOK ) )
if ToolTip.GetToolInfo( hCtrl, ti ) then print hex( ti.uFlags )
dim tiZero as TOOLINFOW = ToolTip.GetToolInfo( hCtrl )
```

Microsoft Learn: [TTM_GETTOOLINFO](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-gettoolinfo)

### SetToolInfo

```freebasic
sub SetToolInfo overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr )
sub SetToolInfo overload( byval hTooltip as HWND, byref ti as TOOLINFOW )
```

Replaces everything the control keeps about the tool named by `hwnd` and `uId` with the
structure's members, text included. Read the tool with [GetToolInfo](#gettoolinfo) first and
change what you need.

**Example**

```freebasic
dim ti as TOOLINFOW
ti.hwnd = hwnd : ti.uId = 7
if ToolTip.GetToolInfo( hCtrl, ti ) then
    ti.lpszText = @wstr( "New text" )
    ToolTip.SetToolInfo( hCtrl, ti )
end if
```

Microsoft Learn: [TTM_SETTOOLINFO](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-settoolinfo)

### GetCurrentTool

```freebasic
function GetCurrentTool overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr ) as boolean
function GetCurrentTool overload( byval hTooltip as HWND, byref ti as TOOLINFOW ) as boolean
```

Reads the tool the control is showing its tip for, or the one under the mouse. With a `NULL`
pointer it only tells whether there is one.

**Returns** `true` when there is a current tool.

**Example**

```freebasic
if ToolTip.GetCurrentTool( hCtrl, NULL ) then ToolTip.Pop( hCtrl )
```

Microsoft Learn: [TTM_GETCURRENTTOOL](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-getcurrenttool)

### GetText

```freebasic
sub GetText overload( byval hTooltip as HWND, byval numChars as DWORD, byval lpti as TOOLINFOW ptr )
sub GetText overload( byval hTooltip as HWND, byval numChars as DWORD, byref ti as TOOLINFOW )
function GetText overload( byval hTooltip as HWND, byval hwnd as HWND, byval numChars as DWORD ) as ustring
```

Reads a tool's text. The first two forms copy at most `numChars` characters, terminator
included, into the buffer `lpszText` points to, for the tool named by `hwnd` and `uId`.

The third form finds the tool for a control or window as [AddTooltip](#addtooltip) registers
it and returns its text in a `ustring` that is always `numChars + 1` characters long: the text,
a null character, then spaces (`"Click me"` read with 80 comes back 81 characters long). Cut it
at the null character before using it. It returns `""` when there is no such tool.

**Returns** the third form returns the text as described.

**Example**

```freebasic
dim s as ustring = ToolTip.GetText( hCtrl, GetDlgItem( hwnd, IDOK ), 80 )
s = left( s, instr( s, chr( 0 ) ) - 1 )
dim wszText as wstring * 80
dim ti as TOOLINFOW
ti.hwnd = hwnd : ti.uId = 7 : ti.lpszText = @wszText
ToolTip.GetText( hCtrl, 80, ti )
```

Microsoft Learn: [TTM_GETTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-gettext)

### UpdateTipText

```freebasic
sub UpdateTipText overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr )
sub UpdateTipText overload( byval hTooltip as HWND, byref ti as TOOLINFOW )
```

Changes only the text of the tool named by `hwnd` and `uId`, to `lpszText`.

**Example**

```freebasic
dim ti as TOOLINFOW
ti.hwnd = hwnd : ti.uId = 7 : ti.lpszText = @wstr( "Other area" )
ToolTip.UpdateTipText( hCtrl, ti )
```

Microsoft Learn: [TTM_UPDATETIPTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-updatetiptext)

### NewToolRect

```freebasic
sub NewToolRect overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr )
sub NewToolRect overload( byval hTooltip as HWND, byref ti as TOOLINFOW )
```

Gives the rectangle tool named by `hwnd` and `uId` the new `rect`, in the client coordinates of
`hwnd`. Call it from `WM_SIZE` for a tool that covers a window's client area.

**Example**

```freebasic
dim ti as TOOLINFOW
ti.hwnd = hwnd : ti.uId = 0
GetClientRect( hwnd, @ti.rect )
ToolTip.NewToolRect( hCtrl, ti )
```

Microsoft Learn: [TTM_NEWTOOLRECT](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-newtoolrect)

### HitTest

```freebasic
function HitTest overload( byval hTooltip as HWND, byval lphti as TTHITTESTINFOW ptr ) as boolean
function HitTest overload( byval hTooltip as HWND, byref phti as TTHITTESTINFOW ) as boolean
```

Finds the rectangle tool of window `hwnd` that contains the point `pt` (client coordinates of
`hwnd`) and fills `ti` with it. Set `ti.cbSize` yourself.

**Returns** `true` when a tool is at the point.

**Example**

```freebasic
dim hti as TTHITTESTINFOW
hti.hwnd = hwnd : hti.pt.x = 150 : hti.pt.y = 120
hti.ti.cbSize = sizeof( TOOLINFOW )
if ToolTip.HitTest( hCtrl, hti ) then print "tool"; hti.ti.uId
```

Microsoft Learn: [TTM_HITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-hittest)

### Activate, Deactivate

```freebasic
sub Activate overload( byval hTooltip as HWND, byval fActivate as boolean )
sub Activate overload( byval hTooltip as HWND )
sub Deactivate( byval hTooltip as HWND )
```

Turn the tooltip control on or off for all its tools. A deactivated control shows no tips until
it is activated again. `Activate( hTip )` is `Activate( hTip, true )`.

**Example**

```freebasic
ToolTip.Deactivate( hCtrl )
ToolTip.Activate( hCtrl )
ToolTip.Activate( hCtrl, false )
```

Microsoft Learn: [TTM_ACTIVATE](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-activate)

### Pop

```freebasic
sub Pop( byval hTooltip as HWND )
```

Hides the tip that is being shown.

**Example**

```freebasic
ToolTip.Pop( hCtrl )
```

Microsoft Learn: [TTM_POP](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-pop)

### Popup

```freebasic
sub Popup( byval hTooltip as HWND )
```

Shows the tip at the coordinates of the last mouse message the control saw.

**Example**

```freebasic
ToolTip.Popup( hCtrl )
```

Microsoft Learn: [TTM_POPUP](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-popup)

### Update

```freebasic
sub Update( byval hTooltip as HWND )
```

Redraws the tip that is being shown, after its text or look has changed.

**Example**

```freebasic
ToolTip.Update( hCtrl )
```

Microsoft Learn: [TTM_UPDATE](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-update)

### RelayEvent

```freebasic
function RelayEvent overload( byval hTooltip as HWND, byval lpmsg as tagMSG ptr ) as long
function RelayEvent overload( byval hTooltip as HWND, byref msg as tagMSG ) as long
```

Passes a mouse message to the control, for tools registered without `TTF_SUBCLASS`: the
control needs to see the mouse moving over them to know when to show a tip. Call it for each
`WM_MOUSEMOVE` and button message of the tool's window.

**Returns** 0.

**Example**

```freebasic
dim m as tagMSG
m.hwnd = hwnd : m.message = WM_MOUSEMOVE
ToolTip.RelayEvent( hCtrl, m )
```

Microsoft Learn: [TTM_RELAYEVENT](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-relayevent)

### GetDelayTime

```freebasic
function GetDelayTime( byval hTooltip as HWND, byval flag as DWORD ) as long
```

Returns one of the control's delays, in milliseconds: `TTDT_INITIAL`, how long the mouse must
rest before the tip appears (500 by default); `TTDT_AUTOPOP`, how long the tip stays (5000);
`TTDT_RESHOW`, the delay before the next tool's tip shows (100).

**Returns** the delay.

**Example**

```freebasic
print ToolTip.GetDelayTime( hCtrl, TTDT_INITIAL )   ' 500
```

Microsoft Learn: [TTM_GETDELAYTIME](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-getdelaytime)

### SetDelayTime

```freebasic
sub SetDelayTime( byval hTooltip as HWND, byval flag as DWORD, byval iTime as short )
```

Sets one of the delays of [GetDelayTime](#getdelaytime), in milliseconds, up to 32767; -1
returns it to its default. `TTDT_AUTOMATIC` sets all three from one initial value.

**Example**

```freebasic
ToolTip.SetDelayTime( hCtrl, TTDT_INITIAL, 200 )
ToolTip.SetDelayTime( hCtrl, TTDT_AUTOPOP, 10000 )
ToolTip.SetDelayTime( hCtrl, TTDT_INITIAL, -1 )   ' 500 again
```

Microsoft Learn: [TTM_SETDELAYTIME](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-setdelaytime)

### GetMaxTipWidth

```freebasic
function GetMaxTipWidth( byval hTooltip as HWND ) as long
```

Returns the width, in pixels, beyond which the text wraps onto a new line.

**Returns** the width, or -1 when none is set (one line).

**Example**

```freebasic
print ToolTip.GetMaxTipWidth( hCtrl )
```

Microsoft Learn: [TTM_GETMAXTIPWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-getmaxtipwidth)

### SetMaxTipWidth

```freebasic
function SetMaxTipWidth( byval hTooltip as HWND, byval iWidth as long ) as long
```

Sets the width, in pixels, beyond which the text wraps; once one is set, the text may also hold
line breaks (`chr( 13, 10 )`). -1 goes back to a single line.

**Returns** the previous width.

**Example**

```freebasic
ToolTip.SetMaxTipWidth( hCtrl, 300 )
```

Microsoft Learn: [TTM_SETMAXTIPWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-setmaxtipwidth)

### GetMargin

```freebasic
sub GetMargin overload( byval hTooltip as HWND, byval lprc as RECT ptr )
sub GetMargin overload( byval hTooltip as HWND, byref rc as RECT )
function GetMargin overload( byval hTooltip as HWND ) as ( long, long, long, long )
```

Returns the space between the tip's border and its text, in pixels, with each `RECT` member
holding one side's margin.

**Returns** the third form returns `( left, top, right, bottom )`.

**Example**

```freebasic
var (ml, mt, mr, mb) = ToolTip.GetMargin( hCtrl )
dim rc as RECT
ToolTip.GetMargin( hCtrl, rc )
```

Microsoft Learn: [TTM_GETMARGIN](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-getmargin)

### SetMargin

```freebasic
sub SetMargin overload( byval hTooltip as HWND, byval lprc as RECT ptr )
sub SetMargin overload( byval hTooltip as HWND, byref rc as RECT )
sub SetMargin overload( byval hTooltip as HWND, byval nLeft as long, byval nTop as long, byval nRight as long, byval nBottom as long )
```

Sets the space between the tip's border and its text, one side per `RECT` member.

**Example**

```freebasic
ToolTip.SetMargin( hCtrl, 4, 2, 4, 2 )
```

Microsoft Learn: [TTM_SETMARGIN](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-setmargin)

### GetBubbleSize

```freebasic
function GetBubbleSize overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr ) as DWORD
function GetBubbleSize overload( byval hTooltip as HWND, byref ti as TOOLINFOW ) as DWORD
```

Returns the size the tip of the tool named by `hwnd` and `uId` would have, width in the low word
and height in the high word. Needs version 6 of the common controls.

**Returns** the size, or 0 for a `NULL` pointer.

**Example**

```freebasic
dim ti as TOOLINFOW
ti.hwnd = hwnd : ti.uId = cast( UINT_PTR, GetDlgItem( hwnd, IDOK ) )
dim sz as DWORD = ToolTip.GetBubbleSize( hCtrl, ti )
print LOWORD( sz ); " x"; HIWORD( sz )
```

Microsoft Learn: [TTM_GETBUBBLESIZE](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-getbubblesize)

### AdjustRect

```freebasic
function AdjustRect overload( byval hTooltip as HWND, byval fLarger as boolean, byval lprc as RECT ptr ) as boolean
function AdjustRect overload( byval hTooltip as HWND, byval fLarger as boolean, byref rc as RECT ) as boolean
```

With `fLarger = true`, turns a text rectangle into the tip window rectangle that shows it; with
`false`, the other way. Use it when placing a tip over text in `TTN_SHOW`.

**Returns** `true` on success.

**Example**

```freebasic
dim rc as RECT
SetRect( @rc, 0, 0, 100, 20 )
ToolTip.AdjustRect( hCtrl, true, rc )   ' now the window rectangle
```

Microsoft Learn: [TTM_ADJUSTRECT](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-adjustrect)

### GetTipBkColor

```freebasic
function GetTipBkColor( byval hTooltip as HWND ) as COLORREF
```

Returns the background colour of the tip.

**Returns** the colour.

**Example**

```freebasic
print hex( ToolTip.GetTipBkColor( hCtrl ) )
```

Microsoft Learn: [TTM_GETTIPBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-gettipbkcolor)

### SetTipBkColor

```freebasic
sub SetTipBkColor( byval hTooltip as HWND, byval clr as COLORREF )
```

Sets the background colour of the tip, a `COLORREF` such as an `RGB_*` constant. A tip drawn
with visual styles keeps its themed look; remove the theme with
`SetWindowTheme( hTip, "", "" )` for the colour to show.

**Example**

```freebasic
ToolTip.SetTipBkColor( hCtrl, RGB_LIGHTYELLOW )
```

Microsoft Learn: [TTM_SETTIPBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-settipbkcolor)

### GetTipTextColor

```freebasic
function GetTipTextColor( byval hTooltip as HWND ) as COLORREF
```

Returns the text colour of the tip.

**Returns** the colour.

**Example**

```freebasic
print hex( ToolTip.GetTipTextColor( hCtrl ) )
```

Microsoft Learn: [TTM_GETTIPTEXTCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-gettiptextcolor)

### SetTipTextColor

```freebasic
sub SetTipTextColor( byval hTooltip as HWND, byval clr as COLORREF )
```

Sets the text colour of the tip. Like [SetTipBkColor](#settipbkcolor) it shows only on a tip
not drawn with visual styles.

**Example**

```freebasic
ToolTip.SetTipTextColor( hCtrl, RGB_NAVY )
```

Microsoft Learn: [TTM_SETTIPTEXTCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-settiptextcolor)

### SetTitle

```freebasic
function SetTitle( byval hTooltip as HWND, byval nIcon as long, byval pwszTitle as wstring ptr ) as boolean
```

Adds a bold title above the text of every tip the control shows, with an icon: `TTI_NONE`,
`TTI_INFO`, `TTI_WARNING`, `TTI_ERROR`, their `_LARGE` forms, or an `HICON`.

**Returns** `true` on success.

**Example**

```freebasic
ToolTip.SetTitle( hCtrl, TTI_INFO, "Help" )
```

Microsoft Learn: [TTM_SETTITLE](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-settitle)

### GetTitle

```freebasic
sub GetTitle overload( byval hTooltip as HWND, byval pTTGetTitle as TTGETTITLE ptr )
sub GetTitle overload( byval hTooltip as HWND, byref tTTGetTitle as TTGETTITLE )
```

Reads the title and icon set with [SetTitle](#settitle) into a `TTGETTITLE` (`dwSize` is filled
in for you): set `pszTitle` to a buffer and `cch` to its size in characters. `uTitleBitmap`
receives the icon. Needs version 6 of the common controls.

**Example**

```freebasic
dim tt as TTGETTITLE
dim wszTitle as wstring * 100
tt.pszTitle = @wszTitle : tt.cch = 100
ToolTip.GetTitle( hCtrl, tt )
```

Microsoft Learn: [TTM_GETTITLE](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-gettitle)

### SetWindowTheme

```freebasic
sub SetWindowTheme( byval hTooltip as HWND, byval pwszTheme as wstring ptr )
```

Sets the visual style the tip is drawn with, by the name of a theme class such as
`"Explorer"`.

**Example**

```freebasic
ToolTip.SetWindowTheme( hCtrl, "Explorer" )
```

Microsoft Learn: [TTM_SETWINDOWTHEME](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-setwindowtheme)

### SetDarkMode

```freebasic
sub SetDarkMode( byval hTooltip as HWND )
```

Draws the tip in Windows' dark style (the `DarkMode_Explorer` theme). The program needs visual
styles.

**Example**

```freebasic
dim hTip as HWND = ToolTip.AddTooltip( GetDlgItem( hwnd, IDOK ), "Save" )
ToolTip.SetDarkMode( hTip )
```

### TrackActivate

```freebasic
sub TrackActivate overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr )
sub TrackActivate overload( byval hTooltip as HWND, byref ti as TOOLINFOW )
```

Shows the tip of a **tracking** tool, one registered with `TTF_TRACK` (and usually
`TTF_ABSOLUTE`), whose position the program sets with [TrackPosition](#trackposition) instead of
the mouse. The tool is named by `hwnd` and `uId`.

**Example**

```freebasic
dim ti as TOOLINFOW
ti.uFlags = TTF_TRACK or TTF_ABSOLUTE
ti.hwnd = hwnd : ti.uId = 9 : ti.lpszText = @wstr( "Here" )
ToolTip.AddTool( hCtrl, @ti )
ToolTip.TrackPosition( hCtrl, 200, 200 )
ToolTip.TrackActivate( hCtrl, ti )
```

Microsoft Learn: [TTM_TRACKACTIVATE](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-trackactivate)

### TrackDeactivate

```freebasic
sub TrackDeactivate overload( byval hTooltip as HWND, byval lpti as TOOLINFOW ptr )
sub TrackDeactivate overload( byval hTooltip as HWND, byref ti as TOOLINFOW )
```

Hides the tip of a tracking tool shown with [TrackActivate](#trackactivate).

**Example**

```freebasic
dim ti as TOOLINFOW
ti.hwnd = hwnd : ti.uId = 9
ToolTip.TrackDeactivate( hCtrl, ti )
```

Microsoft Learn: [TTM_TRACKACTIVATE](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-trackactivate)

### TrackPosition

```freebasic
sub TrackPosition( byval hTooltip as HWND, byval xPos as long, byval yPos as long )
```

Moves the tip of a tracking tool to (`xPos`, `yPos`), in screen coordinates.

**Example**

```freebasic
dim pt as POINT : GetCursorPos( @pt )
ToolTip.TrackPosition( hCtrl, pt.x + 16, pt.y + 16 )
```

Microsoft Learn: [TTM_TRACKPOSITION](https://learn.microsoft.com/en-us/windows/win32/controls/ttm-trackposition)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for the window and controls tips are added to
- [StatusBar](SysWin-Gui-StatusBar), whose parts have tooltips of their own
- [ToolBar](SysWin-Gui-ToolBar), whose buttons show tooltips with `TBSTYLE_TOOLTIPS`
- [Dark mode](SysWin-Dark-Mode)
- [Colours](SysWin-Colors) for the `RGB_*` constants
