[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › **Units**

# Units

Converts between pixels, points, twips, HiMetric units, DIPs and dialog units.

Screens are measured in pixels, but much of Windows measures in units of physical length, so that
a size means the same on every display:

| Unit | Size | Used by |
| --- | --- | --- |
| point | 1/72 inch | font sizes |
| twip | 1/1440 inch, a twentieth of a point | rich edit controls, printing |
| HiMetric | 1/100 millimetre, 2540 to the inch | OLE and COM pictures and controls |
| DIP | 1/96 inch | Direct2D and DirectWrite |
| dialog unit | a quarter of the dialog font's average character width across, an eighth of its height down | dialog templates |

An inch is as many pixels as the DPI: 96 at 100 %, 144 at 150 %. Every conversion here except
[PointSizeToDip](#pointsizetodip) and the dialog units uses the desktop's DPI, the `X` function
the horizontal DPI and the `Y` function the vertical one; see
[Display, screen and DPI](SysWin-Display-and-DPI). A program that is not DPI aware is told 96
DPI on every display.

All but [PointSizeToDip](#pointsizetodip) take and return whole numbers, so each result is
rounded to the nearest unit.

## Importing

```freebasic
#import "sys/win"
using win
```

## Example

A console program that converts a few sizes at the desktop's DPI:

```freebasic
#import "sys/win"
using win

function main() as long
    print "DPI:"; GetLogPixelsX()
    print "a 12-point font is"; PointsToPixelsX( 12 ); " pixels high"
    print "96 pixels are"; PixelsToPointsX( 96 ); " points"
    print "a pixel is"; TwipsPerPixelX(); " twips"
    print "an inch (2540 HiMetric) is"; HiMetricToPixelsX( 2540 ); " pixels"
    print "12 points are"; PointSizeToDip( 12 ); " DIPs"
    return 0
end function

end main()
```

As a program that is not DPI aware, it prints `DPI: 96`, then 16 pixels, 72 points, 15 twips,
96 pixels and 16 DIPs. Declared DPI aware on a display at 175 % (168 DPI), the same conversions
give 28 pixels, 41 points, 9 twips and 168 pixels; the DIPs, which do not depend on the display,
stay 16.

## Functions

| Function | Does |
| --- | --- |
| [HiMetricToPixelsX](#himetrictopixelsx) | Converts a width in HiMetric units to pixels. |
| [HiMetricToPixelsY](#himetrictopixelsy) | Converts a height in HiMetric units to pixels. |
| [PixelsToHiMetricX](#pixelstohimetricx) | Converts a width in pixels to HiMetric units. |
| [PixelsToHiMetricY](#pixelstohimetricy) | Converts a height in pixels to HiMetric units. |
| [PixelsToPointsX](#pixelstopointsx) | Converts a width in pixels to points. |
| [PixelsToPointsY](#pixelstopointsy) | Converts a height in pixels to points. |
| [PointsToPixelsX](#pointstopixelsx) | Converts a width in points to pixels. |
| [PointsToPixelsY](#pointstopixelsy) | Converts a height in points to pixels. |
| [PixelsToTwipsX](#pixelstotwipsx) | Converts a width in pixels to twips. |
| [PixelsToTwipsY](#pixelstotwipsy) | Converts a height in pixels to twips. |
| [TwipsToPixelsX](#twipstopixelsx) | Converts a width in twips to pixels. |
| [TwipsToPixelsY](#twipstopixelsy) | Converts a height in twips to pixels. |
| [TwipsPerPixelX](#twipsperpixelx) | Returns the width of a pixel in twips. |
| [TwipsPerPixelY](#twipsperpixely) | Returns the height of a pixel in twips. |
| [PointSizeToDip](#pointsizetodip) | Converts a size in points to DIPs. |
| [DialogUnitsToPixels](#dialogunitstopixels) | Converts dialog units to pixels for a dialog. |
| [PixelsToDialogUnits](#pixelstodialogunits) | Converts pixels to dialog units for a dialog. |

## Reference

### HiMetricToPixelsX

```freebasic
function HiMetricToPixelsX( byval hm as long ) as long
```

Converts a width in HiMetric units (hundredths of a millimetre) to pixels at the horizontal DPI:
`hm * DPI / 2540`, rounded. 2540 is one inch, 96 pixels at 96 DPI.

**Returns** the width in pixels.

**Example**

```freebasic
print "1 cm ="; HiMetricToPixelsX( 1000 ); " pixels"   ' 38 at 96 DPI
```

Microsoft Learn: [MulDiv](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-muldiv)

### HiMetricToPixelsY

```freebasic
function HiMetricToPixelsY( byval hm as long ) as long
```

Converts a height in HiMetric units to pixels at the vertical DPI.

**Returns** the height in pixels.

**Example**

```freebasic
print HiMetricToPixelsY( 2540 )   ' 96 at 96 DPI
```

### PixelsToHiMetricX

```freebasic
function PixelsToHiMetricX( byval cx as long ) as long
```

Converts a width in pixels to HiMetric units at the horizontal DPI: `cx * 2540 / DPI`, rounded.
Use it for the sizes OLE and COM objects expect, such as an `IPicture`'s.

**Returns** the width in HiMetric units.

**Example**

```freebasic
print PixelsToHiMetricX( 96 )   ' 2540 at 96 DPI
```

### PixelsToHiMetricY

```freebasic
function PixelsToHiMetricY( byval cy as long ) as long
```

Converts a height in pixels to HiMetric units at the vertical DPI.

**Returns** the height in HiMetric units.

**Example**

```freebasic
print PixelsToHiMetricY( 48 )   ' 1270 at 96 DPI
```

### PixelsToPointsX

```freebasic
function PixelsToPointsX( byval pix as long ) as long
```

Converts a width in pixels to points at the horizontal DPI: `pix * 72 / DPI`, rounded.

**Returns** the width in points.

**Example**

```freebasic
print PixelsToPointsX( 96 )   ' 72 at 96 DPI
```

### PixelsToPointsY

```freebasic
function PixelsToPointsY( byval pix as long ) as long
```

Converts a height in pixels to points at the vertical DPI: the point size of a font that is
`pix` pixels high.

**Returns** the height in points.

**Example**

```freebasic
print "a 16-pixel font is"; PixelsToPointsY( 16 ); " points"   ' 12 at 96 DPI
```

### PointsToPixelsX

```freebasic
function PointsToPixelsX( byval pts as long ) as long
```

Converts a width in points to pixels at the horizontal DPI: `pts * DPI / 72`, rounded.

**Returns** the width in pixels.

**Example**

```freebasic
print PointsToPixelsX( 12 )   ' 16 at 96 DPI, 28 at 168 DPI
```

Microsoft Learn: [MulDiv](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-muldiv)

### PointsToPixelsY

```freebasic
function PointsToPixelsY( byval pts as long ) as long
```

Converts a height in points to pixels at the vertical DPI: the character height of a font of
that point size, the value `LOGFONTW.lfHeight` takes as a negative number.

**Returns** the height in pixels.

**Example**

```freebasic
dim lf as LOGFONTW
lf.lfHeight = -PointsToPixelsY( 10 )
```

### PixelsToTwipsX

```freebasic
function PixelsToTwipsX( byval nPixels as long ) as long
```

Converts a width in pixels to twips at the horizontal DPI: `nPixels * 1440 / DPI`, rounded.

**Returns** the width in twips.

**Example**

```freebasic
print PixelsToTwipsX( 100 )   ' 1500 at 96 DPI
```

### PixelsToTwipsY

```freebasic
function PixelsToTwipsY( byval nPixels as long ) as long
```

Converts a height in pixels to twips at the vertical DPI.

**Returns** the height in twips.

**Example**

```freebasic
print PixelsToTwipsY( 1 )   ' 15 at 96 DPI
```

### TwipsToPixelsX

```freebasic
function TwipsToPixelsX( byval nTwips as long ) as long
```

Converts a width in twips to pixels at the horizontal DPI: `nTwips / 1440 * DPI`, rounded.

**Returns** the width in pixels.

**Example**

```freebasic
print TwipsToPixelsX( 1440 )   ' one inch: 96 at 96 DPI
```

### TwipsToPixelsY

```freebasic
function TwipsToPixelsY( byval nTwips as long ) as long
```

Converts a height in twips to pixels at the vertical DPI.

**Returns** the height in pixels.

**Example**

```freebasic
print TwipsToPixelsY( 100 )   ' 7 at 96 DPI
```

### TwipsPerPixelX

```freebasic
function TwipsPerPixelX() as long
```

Returns the width of one pixel in twips, `1440 / DPI`, rounded to a whole number: 15 at 96 DPI,
but 9 at 168 DPI, where the exact value is 8.57. Multiplying by it is only exact where 1440 divides
evenly by the DPI, as at 96, 120 and 144; use [PixelsToTwipsX](#pixelstotwipsx) for other sizes.

**Returns** the twips per pixel.

**Example**

```freebasic
print "a pixel is"; TwipsPerPixelX(); " twips wide"
```

### TwipsPerPixelY

```freebasic
function TwipsPerPixelY() as long
```

Returns the height of one pixel in twips, rounded to a whole number as
[TwipsPerPixelX](#twipsperpixelx) is.

**Returns** the twips per pixel.

**Example**

```freebasic
print "a pixel is"; TwipsPerPixelY(); " twips high"
```

### PointSizeToDip

```freebasic
function PointSizeToDip( byval ptsize as single ) as single
```

Converts a size in points to device-independent pixels (DIPs), `ptsize / 72 * 96`: the font size
DirectWrite expects for a font the user knows by its point size. It does not depend on the
display and is not rounded.

**Returns** the size in DIPs: 16 for 12 points, 12 for 9 points.

**Example**

```freebasic
dim sngSize as single = PointSizeToDip( 10.5 )   ' 14
```

### DialogUnitsToPixels

```freebasic
function DialogUnitsToPixels( byval hDlg as HWND, byval dluX as long, byval dluY as long, byref pixelX as long, byref pixelY as long ) as boolean
```

Converts a position or size given in a dialog's own dialog units to pixels, from the font that
dialog uses. A dialog created from a template with 9-point Segoe UI at 168 DPI turns 100 × 50
dialog units into 300 × 188 pixels.

`hDlg` must be a dialog created from a dialog template. A window that only has the dialog class
gets 0 × 0.

| Parameter | Meaning |
| --- | --- |
| `hDlg` | The dialog. |
| `dluX`, `dluY` | The horizontal and vertical dialog units. |
| `pixelX`, `pixelY` | Receive the pixels. |

**Returns** `true` on success; `false` when `hDlg` is `NULL` or the conversion fails.

**Example**

```freebasic
dim as long cx, cy
if DialogUnitsToPixels( hDlg, 50, 14, cx, cy ) then print "a standard button is"; cx; " x"; cy
```

Microsoft Learn: [MapDialogRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-mapdialogrect)

### PixelsToDialogUnits

```freebasic
function PixelsToDialogUnits( byval hDlg as HWND, byval pixelX as long, byval pixelY as long, byref dluX as long, byref dluY as long ) as boolean
```

Converts pixels to a dialog's dialog units: the inverse of
[DialogUnitsToPixels](#dialogunitstopixels), rounded to whole units. In the same dialog, 200 ×
200 pixels are 67 × 53 dialog units.

| Parameter | Meaning |
| --- | --- |
| `hDlg` | The dialog, created from a template. |
| `pixelX`, `pixelY` | The horizontal and vertical pixels; both nonzero. |
| `dluX`, `dluY` | Receive the dialog units. |

**Returns** `true` once the conversion has been made; `false` when `hDlg` is `NULL` or the
conversion fails.

**Example**

```freebasic
dim as long dx, dy
if PixelsToDialogUnits( hDlg, 200, 100, dx, dy ) then print dx; " x"; dy; " dialog units"
```

Microsoft Learn: [MapDialogRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-mapdialogrect)

## See also

- [Category: sys/win](Category-Sys-Win)
- [Display, screen and DPI](SysWin-Display-and-DPI)
- [Fonts](SysWin-Fonts)
- [CDialog](CDialog)
