[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › **Display, screen and DPI**

# Display, screen and DPI

Measures the desktop, the screen, the work area and monitors, and scales values for DPI.

Three areas are measured here, all of the **primary** monitor unless a function takes a window:

| Area | Covers | Read it with |
| --- | --- | --- |
| Screen (desktop) | the whole primary monitor | [GetDesktopSize](#getdesktopsize), [GetScreenWidth](#getscreenwidth) |
| Work area | the screen less the taskbar and any docked toolbars | [GetWorkArea](#getworkarea) |
| Display mode | the monitor's real resolution, colour depth and refresh rate | [GetDisplayPixelsWidth](#getdisplaypixelswidth) |

**DPI.** The user sets a scale for the display, 100 %, 125 %, 150 % …, which Windows expresses as
*dots per inch*: 96 DPI at 100 %, 120 at 125 %, 144 at 150 %, 168 at 175 %. The *scaling ratio*
is the DPI divided by 96.

What a program is told depends on whether it has declared itself **DPI aware**
(`SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )` at the start, or a manifest). An aware
program sees real pixels and the real DPI. A program that is not aware is scaled up by Windows as
a bitmap and is told a smaller screen and 96 DPI: on a 2880 × 1800 display at 175 %, it sees a
1646 × 1029 screen. Only the display-mode functions report the real resolution either way.

The DPI functions here read the system DPI, the one of the primary monitor when the user signed
in. Lay a window out in 96-DPI units and multiply by [ScaleRatio](#scaleratio), or use the
`ForDpi` functions of [Window size and position](SysWin-Window-Size-and-Position).

## Importing

```freebasic
#import "sys/win"
using win
```

## Example

A console program that declares itself DPI aware and reports the primary display:

```freebasic
#import "sys/win"
using win

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    print "screen:     "; GetScreenWidth(); " x"; GetScreenHeight()
    print "work area:  "; GetWorkAreaWidth(); " x"; GetWorkAreaHeight()
    print "mode:       "; GetDisplayPixelsWidth(); " x "; GetDisplayPixelsHeight(); ", "; _
          GetDisplayBitsPerPixel(); " bits, "; GetDisplayFrequency(); " Hz"
    print "DPI:        "; GetLogPixelsX(); ", scaling ratio"; ScaleRatio()
    print "a 400-unit-wide window is"; Scale( 400 ); " pixels wide"
    return 0
end function

end main()
```

On a 2880 × 1800 display at 175 % with the taskbar at the bottom it prints:

```text
screen:      2880 x 1800
work area:   2880 x 1716
mode:       2880 x 1800, 32 bits, 120 Hz
DPI:         168, scaling ratio 1.75
a 400-unit-wide window is 700 pixels wide
```

## Functions

| Function | Does |
| --- | --- |
| [GetDesktopLocation](#getdesktoplocation) | Reads the top-left corner of the work area. |
| [GetDesktopSize](#getdesktopsize) | Returns the rectangle of the primary screen. |
| [GetDesktopWidth](#getdesktopwidth) | Returns the width of the primary screen. |
| [GetDesktopHeight](#getdesktopheight) | Returns the height of the primary screen. |
| [GetDesktopClientSize](#getdesktopclientsize) | Returns the client rectangle of the desktop window. |
| [GetDesktopClientWidth](#getdesktopclientwidth) | Returns the client width of the desktop window. |
| [GetDesktopClientHeight](#getdesktopclientheight) | Returns the client height of the desktop window. |
| [GetScreenWidth](#getscreenwidth) | Returns the width of the primary screen. |
| [GetScreenHeight](#getscreenheight) | Returns the height of the primary screen. |
| [GetDisplayPixelsWidth](#getdisplaypixelswidth) | Returns the real horizontal resolution of the display. |
| [GetDisplayPixelsHeight](#getdisplaypixelsheight) | Returns the real vertical resolution of the display. |
| [GetDisplayBitsPerPixel](#getdisplaybitsperpixel) | Returns the colour depth of the display. |
| [GetDisplayFrequency](#getdisplayfrequency) | Returns the refresh rate of the display. |
| [GetWorkArea](#getworkarea) | Returns the rectangle of the work area. |
| [GetWorkAreaWidth](#getworkareawidth) | Returns the width of the work area. |
| [GetWorkAreaHeight](#getworkareaheight) | Returns the height of the work area. |
| [UseDpiScaling](#usedpiscaling) | Reads the old `UseDpiScaling` system setting. |
| [ScaleRatio](#scaleratio) | Returns the desktop's scaling ratio, 1.5 at 144 DPI. |
| [Scale](#scale) | Multiplies a value by the scaling ratio. |
| [Unscale](#unscale) | Divides a value by the scaling ratio. |
| [GetLogPixelsX](#getlogpixelsx) | Returns the horizontal DPI of the desktop. |
| [GetLogPixelsY](#getlogpixelsy) | Returns the vertical DPI of the desktop. |
| [IsResolutionAtLeast](#isresolutionatleast) | Tests whether the screen is at least a given size in pixels. |
| [IsDPIResolutionAtLeast](#isdpiresolutionatleast) | Tests whether the screen is at least a given size in 96-DPI units. |
| [GetMonitorLogicalWidth](#getmonitorlogicalwidth) | Returns the width of the monitor a window is on, as the program sees it. |
| [GetMonitorLogicalHeight](#getmonitorlogicalheight) | Returns the height of the monitor a window is on, as the program sees it. |
| [GetMonitorHorizontalScaling](#getmonitorhorizontalscaling) | Returns how much Windows stretches the program horizontally. |
| [GetMonitorVerticalScaling](#getmonitorverticalscaling) | Returns how much Windows stretches the program vertically. |

## Reference

### GetDesktopLocation

```freebasic
function GetDesktopLocation( byref x as long, byref y as long ) as boolean
```

Reads the top-left corner of the work area of the primary monitor: (0, 0) unless the taskbar is
docked at the top or the left.

| Parameter | Meaning |
| --- | --- |
| `x` | Receives the left edge of the work area. |
| `y` | Receives the top edge of the work area. |

**Returns** `true`. It does so even when the work area could not be read, and `x` and `y` are
then 0.

**Example**

```freebasic
dim as long x, y
GetDesktopLocation( x, y )
print "the work area starts at"; x; ","; y
```

Microsoft Learn: [SystemParametersInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow) with `SPI_GETWORKAREA`

### GetDesktopSize

```freebasic
function GetDesktopSize() as ( long, long, long, long )
```

Returns the rectangle of the desktop window as `( left, top, right, bottom )`: the primary
screen, with `left` and `top` 0, so `right` and `bottom` are its width and height.

**Returns** the four edges. `GetLastError()` is nonzero afterwards when the call succeeded and
0 when it failed.

**Example**

```freebasic
var (l, t, r, b) = GetDesktopSize()
if GetLastError() then print "screen:"; r - l; " x"; b - t
```

Microsoft Learn: [GetWindowRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowrect)

### GetDesktopWidth

```freebasic
function GetDesktopWidth() as long
```

Returns the width of the primary screen, in pixels.

**Returns** the width, or 0 on failure.

**Example**

```freebasic
print "screen width:"; GetDesktopWidth()
```

### GetDesktopHeight

```freebasic
function GetDesktopHeight() as long
```

Returns the height of the primary screen, in pixels, the taskbar included.

**Returns** the height, or 0 on failure.

**Example**

```freebasic
print "screen height:"; GetDesktopHeight()
```

### GetDesktopClientSize

```freebasic
function GetDesktopClientSize() as ( long, long, long, long )
```

Returns the client rectangle of the desktop window as `( left, top, right, bottom )`. The
desktop window has no frame, so this is the same as [GetDesktopSize](#getdesktopsize): the whole
primary screen, taskbar included. For the screen less the taskbar use
[GetWorkArea](#getworkarea).

**Returns** the four edges. `GetLastError()` is nonzero afterwards when the call succeeded and
0 when it failed.

**Example**

```freebasic
var (l, t, r, b) = GetDesktopClientSize()
if GetLastError() then print r; " x"; b
```

Microsoft Learn: [GetClientRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getclientrect)

### GetDesktopClientWidth

```freebasic
function GetDesktopClientWidth() as long
```

Returns the client width of the desktop window: the width of the primary screen.

**Returns** the width, or 0 on failure.

**Example**

```freebasic
print GetDesktopClientWidth()
```

### GetDesktopClientHeight

```freebasic
function GetDesktopClientHeight() as long
```

Returns the client height of the desktop window: the height of the primary screen, taskbar
included.

**Returns** the height, or 0 on failure.

**Example**

```freebasic
print GetDesktopClientHeight()
```

### GetScreenWidth

```freebasic
function GetScreenWidth() as long
```

Returns the width of the primary screen in pixels, as the program sees it: the real width in a
DPI-aware program, a smaller, scaled width in one that is not.

**Returns** the width.

**Example**

```freebasic
if GetScreenWidth() < 1280 then print "a small screen"
```

### GetScreenHeight

```freebasic
function GetScreenHeight() as long
```

Returns the height of the primary screen in pixels, as the program sees it.

**Returns** the height.

**Example**

```freebasic
print "screen height:"; GetScreenHeight()
```

### GetDisplayPixelsWidth

```freebasic
function GetDisplayPixelsWidth() as DWORD
```

Returns the horizontal resolution of the current display mode: the monitor's real width in
pixels, whether the program is DPI aware or not. A program that is not aware, on a 2880-pixel
display at 175 %, is told 1646 by [GetScreenWidth](#getscreenwidth) but 2880 by this.

**Returns** the width, or 0 if the display settings could not be read.

**Example**

```freebasic
print "real width:"; GetDisplayPixelsWidth(); ", seen as"; GetScreenWidth()
```

Microsoft Learn: [EnumDisplaySettingsW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumdisplaysettingsw)

### GetDisplayPixelsHeight

```freebasic
function GetDisplayPixelsHeight() as DWORD
```

Returns the vertical resolution of the current display mode, in real pixels.

**Returns** the height, or 0 if the display settings could not be read.

**Example**

```freebasic
print "real height:"; GetDisplayPixelsHeight()
```

### GetDisplayBitsPerPixel

```freebasic
function GetDisplayBitsPerPixel() as DWORD
```

Returns the colour depth of the current display mode, in bits per pixel: 32 on current hardware.

**Returns** the depth, or 0 if the display settings could not be read.

**Example**

```freebasic
print GetDisplayBitsPerPixel(); " bits per pixel"
```

### GetDisplayFrequency

```freebasic
function GetDisplayFrequency() as DWORD
```

Returns the refresh rate of the current display mode, in hertz: 60, 120, 144 …

**Returns** the rate. 0 or 1 means the hardware's default rate.

**Example**

```freebasic
print "refresh rate:"; GetDisplayFrequency(); " Hz"
```

### GetWorkArea

```freebasic
function GetWorkArea() as ( long, long, long, long )
```

Returns the work area of the primary monitor as `( left, top, right, bottom )`, in screen
coordinates: the screen less the taskbar and any docked toolbars. Use it to place a window where
nothing covers it. For another monitor, call `GetMonitorInfoW`.

**Returns** the four edges. `GetLastError()` is nonzero afterwards when the call succeeded and
0 when it failed.

**Example**

```freebasic
var (l, t, r, b) = GetWorkArea()
if GetLastError() then SetWindowPos( hwnd, NULL, l, t, r - l, b - t, SWP_NOZORDER )
```

Microsoft Learn: [SystemParametersInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow) with `SPI_GETWORKAREA`

### GetWorkAreaWidth

```freebasic
function GetWorkAreaWidth() as long
```

Returns the width of the work area of the primary monitor.

**Returns** the width, or 0 on failure.

**Example**

```freebasic
print "work area width:"; GetWorkAreaWidth()
```

### GetWorkAreaHeight

```freebasic
function GetWorkAreaHeight() as long
```

Returns the height of the work area of the primary monitor: the screen height less a taskbar at
the top or bottom.

**Returns** the height, or 0 on failure.

**Example**

```freebasic
print "the taskbar takes"; GetScreenHeight() - GetWorkAreaHeight(); " pixels"
```

### UseDpiScaling

```freebasic
function UseDpiScaling() as boolean
```

Reads the `UseDpiScaling` value under `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\DWM`, a
setting of older Windows versions. Current Windows versions usually do not record it, and then
the function returns `false` whether the display is scaled or not; compare
[GetLogPixelsX](#getlogpixelsx) with 96 instead.

**Returns** `true` when the value is there and nonzero, otherwise `false`.

**Example**

```freebasic
print "UseDpiScaling: "; UseDpiScaling()
```

### ScaleRatio

```freebasic
function ScaleRatio() as single
```

Returns the desktop's horizontal scaling ratio: its DPI divided by 96. It is 1 at 100 %, 1.5 at
150 %, 1.75 at 175 %, and always 1 in a program that is not DPI aware.

**Returns** the ratio.

**Example**

```freebasic
dim nMargin as long = 8 * ScaleRatio()
```

### Scale

```freebasic
function Scale( byval cx as single ) as single
```

Multiplies a value given in 96-DPI units by the desktop's horizontal scaling ratio, turning it
into pixels: `Scale( 100 )` is 175 at 175 %.

**Returns** the scaled value.

**Example**

```freebasic
SetWindowPos( hCtrl, NULL, Scale( 10 ), Scale( 10 ), Scale( 120 ), Scale( 28 ), SWP_NOZORDER )
```

### Unscale

```freebasic
function Unscale( byval cx as single ) as single
```

Divides a value in pixels by the desktop's horizontal scaling ratio, turning it back into 96-DPI
units: `Unscale( 175 )` is 100 at 175 %.

**Returns** the unscaled value.

**Example**

```freebasic
print "the window is"; Unscale( GetWindowWidth( hwnd ) ); " units wide"
```

### GetLogPixelsX

```freebasic
function GetLogPixelsX() as long
```

Returns the number of pixels per logical inch across the desktop: the system DPI, 96 at 100 %,
144 at 150 %. It is the same for every monitor, and 96 in a program that is not DPI aware.

**Returns** the DPI.

**Example**

```freebasic
if GetLogPixelsX() > 96 then print "the display is scaled"
```

Microsoft Learn: [GetDeviceCaps](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getdevicecaps)

### GetLogPixelsY

```freebasic
function GetLogPixelsY() as long
```

Returns the number of pixels per logical inch down the desktop. On every current display it is
the same as [GetLogPixelsX](#getlogpixelsx).

**Returns** the DPI.

**Example**

```freebasic
print "vertical DPI:"; GetLogPixelsY()
```

### IsResolutionAtLeast

```freebasic
function IsResolutionAtLeast( byval cxMin as long, byval cyMin as long ) as boolean
```

Tests whether the primary screen, as the program sees it, is at least `cxMin` × `cyMin` pixels.

**Returns** `true` when both the width and the height are large enough.

**Example**

```freebasic
if IsResolutionAtLeast( 1280, 720 ) = false then print "this program needs a 1280 x 720 screen"
```

Microsoft Learn: [GetSystemMetrics](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmetrics)

### IsDPIResolutionAtLeast

```freebasic
function IsDPIResolutionAtLeast( byval cxMin as long, byval cyMin as long ) as boolean
```

Tests whether the primary screen has room for `cxMin` × `cyMin` **96-DPI units**: each is
multiplied by the scaling ratio before the comparison. A 2880 × 1800 screen at 175 % has room for
1645 × 1028 units, and for 1600 × 1000, but not for 1646 × 1029. Both sizes are scaled by the
horizontal ratio.

**Returns** `true` when both scaled sizes fit.

**Example**

```freebasic
if IsDPIResolutionAtLeast( 1024, 768 ) then print "room for the full layout"
```

### GetMonitorLogicalWidth

```freebasic
function GetMonitorLogicalWidth( byval hWin as HWND = NULL ) as DWORD
```

Returns the width of the monitor a window is on (the nearest one, if it is on none), as the
program sees it: real pixels in a DPI-aware program, scaled ones otherwise. With `NULL` it
measures the primary monitor.

**Returns** the width.

**Example**

```freebasic
print "this monitor is"; GetMonitorLogicalWidth( hwnd ); " pixels wide"
```

Microsoft Learn: [MonitorFromWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-monitorfromwindow), [GetMonitorInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmonitorinfow)

### GetMonitorLogicalHeight

```freebasic
function GetMonitorLogicalHeight( byval hWin as HWND = NULL ) as DWORD
```

Returns the height of the monitor a window is on, as the program sees it. With `NULL` it
measures the primary monitor.

**Returns** the height.

**Example**

```freebasic
print "this monitor is"; GetMonitorLogicalHeight( hwnd ); " pixels high"
```

### GetMonitorHorizontalScaling

```freebasic
function GetMonitorHorizontalScaling( byval hWin as HWND = NULL ) as SINGLE
```

Returns how far Windows stretches the program across the monitor a window is on: the monitor's
real width divided by the width the program sees. It is 1 in a DPI-aware program. In one that is
not, it is the scaling ratio.

**Returns** the ratio.

**Example**

```freebasic
if GetMonitorHorizontalScaling( hwnd ) > 1 then print "this window is being stretched"
```

Microsoft Learn: [EnumDisplaySettingsW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumdisplaysettingsw)

### GetMonitorVerticalScaling

```freebasic
function GetMonitorVerticalScaling( byval hWin as HWND = NULL ) as SINGLE
```

Returns how far Windows stretches the program down the monitor a window is on: the real height
divided by the height the program sees.

**Returns** the ratio.

**Example**

```freebasic
print "vertical stretch:"; GetMonitorVerticalScaling( hwnd )
```

## See also

- [Category: sys/win](Category-Sys-Win)
- [Window size and position](SysWin-Window-Size-and-Position) for the `ForDpi` functions
- [Units](SysWin-Units) for points, twips and dialog units
- [Fonts](SysWin-Fonts)
