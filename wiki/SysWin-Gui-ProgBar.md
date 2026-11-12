[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **ProgBar**

# ProgBar

Sets the range, position, step, colours and state of a progress bar control.

A progress bar shows how far a long operation has got, as a bar that fills from left to right
(or bottom to top with `PBS_VERTICAL`). Create one with
`CWindow.AddControl( "ProgressBar", ... )`, which also sets its range to 0–100 and its position
to 0. Every function here takes the control's handle first and is written with the namespace:
`ProgBar.SetPos( hBar, 50 )`.

The bar has a **range**, a low and a high limit, and a **position** inside it; a position set
outside the range is moved to the nearest limit. [StepIt](#stepit) advances by the **step**
(10 unless set), wrapping back to the start when it passes the end. A bar created with
`PBS_MARQUEE` has no position: it shows a block that moves back and forth while marquee mode is
on, for work whose length is not known.

Marquee mode, the paused and error states (yellow and red) and reading the colours need version
6 of the common controls, which a program selects with a manifest or by calling
`EnableVisualStyles()` before it creates the bar. Under visual styles the bar is drawn in the
theme's colours and the colour functions change only what they report. A progress bar sends no
notifications and owns nothing that needs to be freed.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A progress bar that moves on by a step at each click of **Step**, a marquee bar below it, and a
**Pause** button that shows the first bar's paused state.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_BAR = 101
const IDC_MARQUEE = 102
const IDC_STEP = 103
const IDC_PAUSE = 104

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    EnableVisualStyles()
    dim pWindow as CWindow = "ProgBarDemo"
    dim hWin as HWND = pWindow.Create( NULL, "ProgBar", @WndProc )
    pWindow.SetClientSize( 320, 130 )
    pWindow.Center()
    dim hBar as HWND = pWindow.AddControl( "ProgressBar", hWin, IDC_BAR, "", 10, 10, 300, 22 )
    ProgBar.SetRange32( hBar, 0, 200 )
    ProgBar.SetStep( hBar, 25 )
    dim hMarquee as HWND = pWindow.AddControl( "ProgressBar", hWin, IDC_MARQUEE, "", 10, 42, 300, 22, _
                                               WS_VISIBLE or PBS_MARQUEE )
    ProgBar.SetMarqueeOn( hMarquee, 30 )
    pWindow.AddControl( "Button", hWin, IDC_STEP, "&Step", 10, 84, 100, 30 )
    pWindow.AddControl( "Button", hWin, IDC_PAUSE, "&Pause", 120, 84, 100, 30 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                dim hBar as HWND = GetDlgItem( hwnd, IDC_BAR )
                select case CBCTL( wParam, lParam )
                    case IDC_STEP
                        ProgBar.StepIt( hBar )
                        SetWindowText( hwnd, "Position " & ProgBar.GetPos( hBar ) & " of " & ProgBar.GetHighLimit( hBar ) )
                    case IDC_PAUSE
                        if ProgBar.GetState( hBar ) = PBST_PAUSED then
                            ProgBar.SetState( hBar, PBST_NORMAL )
                        else
                            ProgBar.SetState( hBar, PBST_PAUSED )
                        end if
                end select
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
| [SetRange](#setrange) | Sets the range, with 16-bit limits. |
| [SetRange32](#setrange32) | Sets the range, with 32-bit limits. |
| [GetRange](#getrange) | Reads both limits into a `PBRANGE`. |
| [GetLowLimit](#getlowlimit) | Returns the low limit. |
| [GetHighLimit](#gethighlimit) | Returns the high limit. |
| [GetMinRange](#getminrange) | Returns the low limit. |
| [GetMaxRange](#getmaxrange) | Returns the high limit. |
| [GetPos](#getpos) | Returns the position. |
| [SetPos](#setpos) | Sets the position. |
| [DeltaPos](#deltapos) | Moves the position by an amount. |
| [IncPos](#incpos) | Moves the position by an amount, in two steps. |
| [SetStep](#setstep) | Sets the step. |
| [StepIt](#stepit) | Moves the position on by the step. |
| [SetMarquee](#setmarquee) | Turns marquee mode on or off. |
| [SetMarqueeOn](#setmarqueeon) | Turns marquee mode on. |
| [SetMarqueeOff](#setmarqueeoff) | Turns marquee mode off. |
| [GetState](#getstate) | Returns the normal, error or paused state. |
| [SetState](#setstate) | Sets the normal, error or paused state. |
| [GetBarColor](#getbarcolor) | Returns the bar colour. |
| [SetBarColor](#setbarcolor) | Sets the bar colour. |
| [GetBkColor](#getbkcolor) | Returns the background colour. |
| [SetBkColor](#setbkcolor) | Sets the background colour. |

## Reference

### SetRange

```freebasic
function SetRange( byval hProgBar as HWND, byval nMinRange as WORD, byval nMaxRange as WORD ) as DWORD
```

Sets the low and high limits of the range, each from 0 to 65535, and redraws the bar. The high
limit must be greater than the low one. Use [SetRange32](#setrange32) for negative or larger
limits.

**Returns** the previous range in one value: the low limit in the low word and the high limit
in the high word (`&h640000` for the default 0–100), or 0 on failure.

**Example**

```freebasic
dim r as DWORD = ProgBar.SetRange( hCtrl, 0, 1000 )
print "was"; LOWORD( r ); " to"; HIWORD( r )
```

Microsoft Learn: [PBM_SETRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setrange)

### SetRange32

```freebasic
function SetRange32( byval hProgBar as HWND, byval nMinRange as long, byval nMaxRange as long ) as DWORD
```

Sets the low and high limits of the range as 32-bit values, negative ones included, and redraws
the bar.

**Returns** the previous range as [SetRange](#setrange) does, cut to the low word of each
limit; read the full values with [GetRange](#getrange) before the call.

**Example**

```freebasic
ProgBar.SetRange32( hCtrl, 0, 250000 )
```

Microsoft Learn: [PBM_SETRANGE32](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setrange32)

### GetRange

```freebasic
function GetRange( byval hProgBar as HWND, byval fWhichLimit as boolean, byval pPBRange as PBRANGE ptr ) as long
function GetRange( byval hProgBar as HWND, byval fWhichLimit as boolean, byref range as PBRANGE ) as long
function GetRange( byval hProgBar as HWND, byval fWhichLimit as boolean ) as PBRANGE
```

Reads both limits of the range into a `PBRANGE` (`iLow`, `iHigh`). In the first two forms
`fWhichLimit` picks the limit returned: `true` the low one, `false` the high one. The third
form returns the structure, and `fWhichLimit` makes no difference to it.

**Returns** the limit picked (first two forms), or the structure.

**Example**

```freebasic
dim r as PBRANGE = ProgBar.GetRange( hCtrl, true )
print "range"; r.iLow; " to"; r.iHigh
```

Microsoft Learn: [PBM_GETRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getrange)

### GetLowLimit

```freebasic
function GetLowLimit( byval hProgBar as HWND ) as long
```

Returns the low limit of the range.

**Returns** the limit.

**Example**

```freebasic
print "from"; ProgBar.GetLowLimit( hCtrl )
```

Microsoft Learn: [PBM_GETRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getrange)

### GetHighLimit

```freebasic
function GetHighLimit( byval hProgBar as HWND ) as long
```

Returns the high limit of the range.

**Returns** the limit.

**Example**

```freebasic
print "to"; ProgBar.GetHighLimit( hCtrl )
```

Microsoft Learn: [PBM_GETRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getrange)

### GetMinRange

```freebasic
function GetMinRange( byval hProgBar as HWND ) as long
```

Returns the low limit of the range; the same as [GetLowLimit](#getlowlimit).

**Returns** the limit.

**Example**

```freebasic
dim nMin as long = ProgBar.GetMinRange( hCtrl )
```

Microsoft Learn: [PBM_GETRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getrange)

### GetMaxRange

```freebasic
function GetMaxRange( byval hProgBar as HWND ) as long
```

Returns the high limit of the range; the same as [GetHighLimit](#gethighlimit).

**Returns** the limit.

**Example**

```freebasic
dim nMax as long = ProgBar.GetMaxRange( hCtrl )
```

Microsoft Learn: [PBM_GETRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getrange)

### GetPos

```freebasic
function GetPos( byval hProgBar as HWND ) as LONG
```

Returns the position of the bar.

**Returns** the position.

**Example**

```freebasic
dim nPos as long = cast( long, ProgBar.GetPos( hCtrl ) )
```

Microsoft Learn: [PBM_GETPOS](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getpos)

### SetPos

```freebasic
function SetPos( byval hProgBar as HWND, byval nNewPos as long ) as long
```

Sets the position and redraws the bar. A position outside the range is moved to the nearest
limit: 500 on a 0–100 bar sets 100. Not for a marquee bar.

**Returns** the previous position.

**Example**

```freebasic
ProgBar.SetPos( hCtrl, 50 )
```

Microsoft Learn: [PBM_SETPOS](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setpos)

### DeltaPos

```freebasic
function DeltaPos( byval hProgBar as HWND, byval nIncrement as long ) as long
```

Moves the position by `nIncrement`, which may be negative, and redraws the bar. The new position
is kept inside the range. Not for a marquee bar.

**Returns** the previous position.

**Example**

```freebasic
ProgBar.DeltaPos( hCtrl, 5 )
```

Microsoft Learn: [PBM_DELTAPOS](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-deltapos)

### IncPos

```freebasic
function IncPos( byval hProgBar as HWND, byval nIncVal as long ) as long
```

Moves the position by `nIncVal`, as [DeltaPos](#deltapos) does, by reading the position and
setting it to that plus `nIncVal`. `nIncVal` is an amount to add, not a new position. Not for a
marquee bar.

**Returns** the previous position: 35 for a bar at 35 moved by 10.

**Example**

```freebasic
ProgBar.IncPos( hCtrl, 10 )
```

Microsoft Learn: [PBM_SETPOS](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setpos)

### SetStep

```freebasic
function SetStep( byval hProgBar as HWND, byval nStepInc as long ) as long
```

Sets the amount [StepIt](#stepit) moves the position by. It starts at 10.

**Returns** the previous step.

**Example**

```freebasic
ProgBar.SetStep( hCtrl, 1 )
```

Microsoft Learn: [PBM_SETSTEP](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setstep)

### StepIt

```freebasic
function StepIt( byval hProgBar as HWND ) as long
```

Moves the position on by the step and redraws the bar. A position that passes the high limit
wraps round from the low one: on a 0–100 bar with a step of 25, stepping from 95 gives 20. Not
for a marquee bar.

**Returns** the previous position.

**Example**

```freebasic
for i as long = 1 to 10
    ProgBar.StepIt( hCtrl )
next
```

Microsoft Learn: [PBM_STEPIT](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-stepit)

### SetMarquee

```freebasic
function SetMarquee( byval hProgBar as HWND, byval fOn as boolean, byval dwAnimationSpeed as DWORD ) as long
```

Turns marquee mode on (`fOn` `true`) or off for a bar with `PBS_MARQUEE`.
`dwAnimationSpeed` is the time between moves of the block, in milliseconds; 0 means 30.

**Returns** 1, or 0 without version 6 of the common controls.

**Example**

```freebasic
ProgBar.SetMarquee( hCtrl, true, 0 )
```

Microsoft Learn: [PBM_SETMARQUEE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setmarquee)

### SetMarqueeOn

```freebasic
function SetMarqueeOn( byval hProgBar as HWND, byval dwAnimationSpeed as DWORD ) as long
```

Turns marquee mode on, moving the block every `dwAnimationSpeed` milliseconds (0 for 30):
[SetMarquee](#setmarquee) with `fOn` `true`.

**Returns** 1, or 0 without version 6 of the common controls.

**Example**

```freebasic
ProgBar.SetMarqueeOn( hCtrl, 50 )
```

Microsoft Learn: [PBM_SETMARQUEE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setmarquee)

### SetMarqueeOff

```freebasic
function SetMarqueeOff( byval hProgBar as HWND ) as long
```

Turns marquee mode off; the block stops moving.

**Returns** 1, or 0 without version 6 of the common controls.

**Example**

```freebasic
ProgBar.SetMarqueeOff( hCtrl )
```

Microsoft Learn: [PBM_SETMARQUEE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setmarquee)

### GetState

```freebasic
function GetState( byval hProgBar as HWND ) as long
```

Returns the state of the bar: `PBST_NORMAL` (1, in progress), `PBST_ERROR` (2, drawn red) or
`PBST_PAUSED` (3, drawn yellow).

**Returns** the state, or 0 without version 6 of the common controls.

**Example**

```freebasic
if ProgBar.GetState( hCtrl ) = PBST_ERROR then print "failed"
```

Microsoft Learn: [PBM_GETSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getstate)

### SetState

```freebasic
function SetState( byval hProgBar as HWND, byval iState as long ) as long
```

Sets the state of the bar to `PBST_NORMAL`, `PBST_ERROR` or `PBST_PAUSED`; see
[GetState](#getstate).

**Returns** the previous state, or 0 without version 6 of the common controls.

**Example**

```freebasic
ProgBar.SetState( hCtrl, PBST_ERROR )
```

Microsoft Learn: [PBM_SETSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setstate)

### GetBarColor

```freebasic
function GetBarColor( byval hProgBar as HWND ) as COLORREF
```

Returns the colour set with [SetBarColor](#setbarcolor).

**Returns** the colour, `CLR_DEFAULT` while the default colour is used, or 0 without version 6
of the common controls.

**Example**

```freebasic
if ProgBar.GetBarColor( hCtrl ) = CLR_DEFAULT then print "default colour"
```

Microsoft Learn: [PBM_GETBARCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getbarcolor)

### SetBarColor

```freebasic
function SetBarColor( byval hProgBar as HWND, byval clrBar as COLORREF ) as COLORREF
```

Sets the colour of the bar, or the default colour with `CLR_DEFAULT`. The bar is drawn in it
only when visual styles are off for it (for example after `SetWindowTheme( h, "", "" )`).

**Returns** the previous colour, or `CLR_DEFAULT`.

**Example**

```freebasic
ProgBar.SetBarColor( hCtrl, BGR( 0, 160, 0 ) )
```

Microsoft Learn: [PBM_SETBARCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setbarcolor)

### GetBkColor

```freebasic
function GetBkColor( byval hProgBar as HWND ) as COLORREF
```

Returns the background colour set with [SetBkColor](#setbkcolor).

**Returns** the colour, `CLR_DEFAULT` while the default colour is used, or 0 without version 6
of the common controls.

**Example**

```freebasic
print "background &h"; hex( ProgBar.GetBkColor( hCtrl ) )
```

Microsoft Learn: [PBM_GETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-getbkcolor)

### SetBkColor

```freebasic
function SetBkColor( byval hProgBar as HWND, byval clrBk as COLORREF ) as COLORREF
```

Sets the background colour, or the default colour with `CLR_DEFAULT`. As with
[SetBarColor](#setbarcolor), it shows only when visual styles are off for the bar.

**Returns** the previous colour, or `CLR_DEFAULT`.

**Example**

```freebasic
ProgBar.SetBkColor( hCtrl, BGR( 255, 255, 255 ) )
```

Microsoft Learn: [PBM_SETBKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/pbm-setbkcolor)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for `AddControl( "ProgressBar", ... )`
- [StatusBar](SysWin-Gui-StatusBar), which can hold a progress bar in one of its parts
- [TrackBar](SysWin-Gui-TrackBar) for a bar the user drags
