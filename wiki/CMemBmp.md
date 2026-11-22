[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **CMemBmp**

# CMemBmp

Creates an off-screen bitmap to draw on with GDI or GDI+, then save, print or display.

A `CMemBmp` owns two things: a device-dependent bitmap (DDB) and a memory device context with
that bitmap selected into it. Draw on [GetMemDC](#getmemdc) with any GDI call (`Rectangle`,
`LineTo`, `DrawTextW` …) or wrap it in a GDI+ `CGpGraphics`; the pixels land in the bitmap,
which [GethBmp](#gethbmp) returns. Coordinates are pixels with (0, 0) at the top-left corner.

**Ownership.** The destructor selects the original bitmap back into the memory DC, then deletes
the bitmap and the DC, so neither handle may be used after the object is gone and neither may be
deleted by you. Keep the object alive as long as you need the bitmap, and pass it `byref`: the
class has no copy constructor of its own, so a copy would hold the same two handles and delete
them a second time. The three handles are also public fields, `m_hBmp`, `m_hMemDc` and
`m_hOldBmp`; read them through the methods.

**Compatible with what.** The bitmap matches the device context passed to the first constructor,
or the screen when none is passed and for the two constructors that load an image. Use
`GetDIBits` to turn it into a device-independent bitmap, or `GdipCreateBitmapFromHBITMAP` for a
GDI+ bitmap; a [CGraphCtx](CGraphCtx) displays it with its own `DrawBitmap`.

**GDI+.** Loading an image and [DrawBitmap](#drawbitmap) use GDI+, which must be running: call
`gdiplus.Init()` first and `gdiplus.Uninit( token )` when done, or keep a GDI+ class object such
as a `CGpGraphics` alive. Without it a loaded image comes out the right size but black, and
`DrawBitmap` returns `GdiplusNotInitialized` (18). The save methods and
[PrintBitmap](#printbitmap) start GDI+ for themselves.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus
```

## Example

Draws a filled ellipse and a caption with GDI on a 200 × 100 bitmap, saves it as a PNG, then
loads the file into a second bitmap and reads a pixel back:

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus

function main() as long
    dim bmp as CMemBmp = CMemBmp( 200, 100 )            ' white, 200 x 100
    dim hdc as HDC = bmp.GetMemDC()
    dim hBrush as HBRUSH = CreateSolidBrush( BGR( 0, 120, 215 ) )
    dim hOld as HGDIOBJ = SelectObject( hdc, hBrush )
    Ellipse( hdc, 10, 10, 190, 90 )
    SelectObject( hdc, hOld )
    DeleteObject( hBrush )
    SetBkMode( hdc, TRANSPARENT )
    SetTextColor( hdc, BGR( 255, 255, 255 ) )
    dim rc as RECT
    SetRect( @rc, 0, 0, 200, 100 )
    DrawTextW( hdc, "CMemBmp", -1, @rc, DT_CENTER or DT_VCENTER or DT_SINGLELINE )
    print "pixel at 30, 50: &h"; hex( bmp.GetPixel( 30, 50 ) )
    if bmp.SaveBitmapAsPng( "drawing.png" ) = Ok then print "saved drawing.png"

    dim token as ULONG_PTR = gdiplus.Init()             ' loading an image needs GDI+
    scope
        dim copy as CMemBmp = CMemBmp( "drawing.png" )
        print "loaded"; copy.GetWidth(); " x"; copy.GetHeight(); ", pixel at 30, 50: &h"; hex( copy.GetPixel( 30, 50 ) )
    end scope
    gdiplus.Uninit( token )
    return 0
end function

end main()
```

It prints:

```text
pixel at 30, 50: &hD77800
saved drawing.png
loaded 200 x 100, pixel at 30, 50: &hD77800
```

## Members

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Creates an empty bitmap, or one holding an image from a file or a resource. |
| [Destructor](#destructor) | Deletes the bitmap and its memory device context. |
| [GetMemDC](#getmemdc) | Returns the memory device context to draw on. |
| [GethBmp](#gethbmp) | Returns the bitmap handle. |
| [GetWidth](#getwidth) | Returns the width in pixels. |
| [GetHeight](#getheight) | Returns the height in pixels. |
| [GetWidthBytes](#getwidthbytes) | Returns the number of bytes in one scan line. |
| [GetPlanes](#getplanes) | Returns the number of colour planes. |
| [GetBitsPixel](#getbitspixel) | Returns the number of bits per pixel. |
| [GetPixel](#getpixel) | Returns the colour of one pixel. |
| [SetPixel](#setpixel) | Sets the colour of one pixel. |
| [DrawBitmap](#drawbitmap) | Draws a GDI or GDI+ bitmap onto the memory bitmap, at its size or stretched. |
| [SaveBitmap](#savebitmap) | Saves the bitmap to a file in a format given by MIME type. |
| [SaveBitmapAsBmp, SaveBitmapAsJpeg, SaveBitmapAsPng, SaveBitmapAsGif, SaveBitmapAsTiff](#savebitmapasbmp-savebitmapasjpeg-savebitmapaspng-savebitmapasgif-savebitmapastiff) | Save the bitmap in one fixed format. |
| [PrintBitmap](#printbitmap) | Prints the bitmap on the default printer. |

## Reference

### Constructor

```freebasic
constructor( byval nWidth as long = 0, byval nHeight as long = 0, byval hdc as HDC = NULL, byval clrBkg as COLORREF = BGR(255, 255, 255) )
constructor( byref wszFileName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false, byval clrBkg as ARGB = 0 )
constructor( byval hInst as HINSTANCE, byref wszImageName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false, byval clrBkg as ARGB = 0 )
```

The first form creates an empty `nWidth` × `nHeight` bitmap compatible with `hdc`, or with the
screen when `hdc` is `NULL`, and fills it with `clrBkg` (white by default). A bitmap made for the
screen has the screen's colour depth, 32 bits per pixel on current displays.

The second form loads an image file (BMP, PNG, JPEG, GIF, TIFF or any other format GDI+ reads) and
the third an image stored as an `RCDATA` resource; the bitmap takes the image's size and holds a
copy of it. Both can dim the image or turn it to grey first, and both need GDI+ to be running
(see the intro). When the image cannot be found or read the result is a 1 × 1 bitmap.

`clrBkg` in the loading forms is a GDI+ `ARGB` value: the colour the image's transparent pixels
take, with its alpha ignored. The default, 0, makes them black.

| Parameter | Meaning |
| --- | --- |
| `nWidth`, `nHeight` | The size of an empty bitmap, in pixels. |
| `hdc` | The device context the bitmap is made compatible with, or `NULL` for the screen. |
| `clrBkg` | First form: the `COLORREF` the bitmap is filled with. Loading forms: the `ARGB` colour behind transparent pixels. |
| `wszFileName` | The path of the image file. |
| `hInst` | The module that holds the resource; `NULL` means the program itself. |
| `wszImageName` | The resource name, or `"#"` followed by its number, as in `"#998"`. Only `RCDATA` resources are read. |
| `dimPercent` | 1 to 99 lightens every pixel that far towards white; 0 leaves the image as it is. |
| `bGrayScale` | `true` turns the image to shades of grey. |

**Example**

```freebasic
dim canvas as CMemBmp = CMemBmp( 320, 200, NULL, BGR( 255, 255, 224 ) )
dim token as ULONG_PTR = gdiplus.Init()
dim photo as CMemBmp = CMemBmp( "photo.jpg", 0, true )        ' a grey copy
dim logo as CMemBmp = CMemBmp( GetModuleHandleW( NULL ), "#101" )
```

Microsoft Learn: [CreateCompatibleBitmap](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createcompatiblebitmap), [CreateCompatibleDC](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createcompatibledc)

### Destructor

```freebasic
destructor
```

Selects the original bitmap back into the memory device context, deletes the bitmap and deletes
the device context. Handles returned by [GetMemDC](#getmemdc) and [GethBmp](#gethbmp) are invalid
afterwards.

**Example**

```freebasic
scope
    dim bmp as CMemBmp = CMemBmp( 64, 64 )
    Rectangle( bmp.GetMemDC(), 8, 8, 56, 56 )
end scope   ' the bitmap and its device context are deleted here
```

Microsoft Learn: [DeleteDC](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deletedc)

### GetMemDC

```freebasic
function GetMemDC() as HDC
```

Returns the memory device context that holds the bitmap. Everything drawn on it changes the
bitmap. Select your own pens, brushes and fonts into it as on any DC, and select the old ones
back before deleting yours; never delete the DC itself.

**Returns** the device context, or `NULL` if it could not be created.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 200, 100 )
MoveToEx( bmp.GetMemDC(), 0, 0, NULL )
LineTo( bmp.GetMemDC(), 199, 99 )
```

### GethBmp

```freebasic
function GethBmp() as HBITMAP
```

Returns the bitmap. It stays selected into the memory DC and belongs to the object: use it to
copy, save or display the image, not to delete it or select it into another DC.

**Returns** the bitmap handle, or `NULL` if it could not be created.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 200, 100 )
SaveHBITMAPToFile( bmp.GethBmp(), "blank.bmp" )
```

### GetWidth

```freebasic
function GetWidth() as long
```

**Returns** the width of the bitmap in pixels, or 0 if there is no bitmap.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 200, 100 )
print bmp.GetWidth()   ' 200
```

Microsoft Learn: [BITMAP](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmap)

### GetHeight

```freebasic
function GetHeight() as long
```

**Returns** the height of the bitmap in pixels, or 0 if there is no bitmap.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 200, 100 )
print bmp.GetHeight()   ' 100
```

### GetWidthBytes

```freebasic
function GetWidthBytes() as long
```

**Returns** the number of bytes in one scan line of the bitmap, always an even number: 400 for a
200-pixel line at 32 bits per pixel.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 100, 50 )
print bmp.GetWidthBytes()   ' 400 on a 32-bit display
```

### GetPlanes

```freebasic
function GetPlanes() as long
```

**Returns** the number of colour planes, 1 for every bitmap on current displays.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 100, 50 )
print bmp.GetPlanes()   ' 1
```

### GetBitsPixel

```freebasic
function GetBitsPixel() as long
```

**Returns** the number of bits that hold the colour of one pixel: the colour depth of the device
the bitmap was made for, 32 for the screen on current displays.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 100, 50 )
print bmp.GetBitsPixel()   ' 32
```

### GetPixel

```freebasic
function GetPixel( byval x as long, byval y as long ) as COLORREF
```

Reads the colour of the pixel at (`x`, `y`).

| Parameter | Meaning |
| --- | --- |
| `x`, `y` | The pixel, in pixels from the top-left corner. |

**Returns** the colour as a `COLORREF` (red in the low byte), or `CLR_INVALID` (`&hFFFFFFFF`) for
a point outside the bitmap.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 100, 50 )
print hex( bmp.GetPixel( 0, 0 ) )   ' FFFFFF: white
```

Microsoft Learn: [GetPixel](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getpixel)

### SetPixel

```freebasic
function SetPixel( byval x as long, byval y as long, byval crColor as COLORREF ) as COLORREF
```

Sets the pixel at (`x`, `y`) to `crColor`, or to the nearest colour the bitmap can hold.

| Parameter | Meaning |
| --- | --- |
| `x`, `y` | The pixel, in pixels from the top-left corner. |
| `crColor` | The colour; build it with `BGR( r, g, b )` or use an `RGB_*` constant. |

**Returns** the colour the pixel was given, or `CLR_INVALID` (`&hFFFFFFFF`) for a point outside
the bitmap.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 100, 50 )
bmp.SetPixel( 5, 5, BGR( 255, 0, 0 ) )
print hex( bmp.GetPixel( 5, 5 ) )   ' FF: red
```

Microsoft Learn: [SetPixel](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-setpixel)

### DrawBitmap

```freebasic
function DrawBitmap( byval hbmp as HBITMAP, byval x as single = 0, byval y as single = 0 ) as GpStatus
function DrawBitmap( byval pBitmap as GpBitmap ptr, byval x as single = 0 ) as GpStatus
```

Draws a GDI bitmap or a GDI+ bitmap onto the memory bitmap with its top-left corner at
(`x`, `y`), using GDI+.

The `HBITMAP` form copies the bitmap into a temporary GDI+ bitmap and frees it again; the
bitmap you pass stays yours. The `GpBitmap ptr` form draws the GDI+ bitmap as it is and does not
dispose of it. GDI+ must be running (see the intro).

| Parameter | Meaning |
| --- | --- |
| `hbmp` | A GDI bitmap, for example another `CMemBmp`'s [GethBmp](#gethbmp). |
| `pBitmap` | A GDI+ bitmap. |
| `x`, `y` | Where the top-left corner of the image goes. |
| `nRight`, `nBottom` | The width and height to stretch the image to, or 0 for its own size. |

**Returns** `Ok` (0) on success, `InvalidParameter` (2) for a `NULL` `pBitmap`,
`GdiplusNotInitialized` (18) when GDI+ is not running, or another `GpStatus` code.

**Example**

```freebasic
dim token as ULONG_PTR = gdiplus.Init()
dim canvas as CMemBmp = CMemBmp( 300, 200 )
dim icon as HBITMAP = BitmapFromFile( "logo.png" )
canvas.DrawBitmap( icon, 10, 10 )                  ' its own size
canvas.DrawBitmap( icon, 150, 10, 64, 64 )         ' stretched to 64 x 64
DeleteObject( icon )
```

Microsoft Learn: [Graphics::DrawImage](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusgraphics/nf-gdiplusgraphics-graphics-drawimage%28image_real_real_real_real%29)

### SaveBitmap

```freebasic
function SaveBitmap( byref wszFileName as wstring, byref wszMimeType as wstring = "image/bmp" ) as long
```

Saves the bitmap to `wszFileName` in the format named by `wszMimeType`. The extension of the file
name is not looked at. GDI+ is started and shut down for the call.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The path of the file to write; an existing file is replaced. |
| `wszMimeType` | `"image/bmp"` (the default), `"image/png"`, `"image/jpeg"`, `"image/gif"` or `"image/tiff"`. |

**Returns** `Ok` (0) on success, otherwise a `GpStatus` code: `Win32Error` (7) when the file
cannot be written, for example because its folder does not exist.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 200, 100 )
if bmp.SaveBitmap( "out.png", "image/png" ) <> Ok then print "could not save"
```

Microsoft Learn: [Image::Save](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-save%28constwchar_constclsid_constencoderparameters%29)

### SaveBitmapAsBmp, SaveBitmapAsJpeg, SaveBitmapAsPng, SaveBitmapAsGif, SaveBitmapAsTiff

```freebasic
function SaveBitmapAsBmp( byref wszFileName as wstring ) as long
function SaveBitmapAsJpeg( byref wszFileName as wstring ) as long
function SaveBitmapAsPng( byref wszFileName as wstring ) as long
function SaveBitmapAsGif( byref wszFileName as wstring ) as long
function SaveBitmapAsTiff( byref wszFileName as wstring ) as long
```

[SaveBitmap](#savebitmap) with the MIME type fixed: `"image/bmp"`, `"image/jpeg"`, `"image/png"`,
`"image/gif"` and `"image/tiff"`.

**Returns** `Ok` (0) on success, otherwise a `GpStatus` code.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 200, 100 )
bmp.SaveBitmapAsPng( "picture.png" )
bmp.SaveBitmapAsJpeg( "picture.jpg" )
```

### PrintBitmap

```freebasic
function PrintBitmap( byval bStretch as boolean = false, byval nStretchMode as long = InterpolationModeHighQualityBicubic ) as boolean
```

Prints the bitmap on the default printer, in a print job named "Printing bitmap", once for each
copy the printer is set to print. With `bStretch` the image is stretched over the printable
area of the page; otherwise it is drawn at its own size in the top-left corner. Nothing is shown
on the screen. GDI+ is started and shut down for the call.

| Parameter | Meaning |
| --- | --- |
| `bStretch` | `true` stretches the image over the page. |
| `nStretchMode` | How GDI+ scales the image when stretching: one of the `InterpolationMode*` values, `InterpolationModeHighQualityBicubic` (7) by default; `InterpolationModeNearestNeighbor` (5) keeps hard pixel edges. |

**Returns** `true` when the job was sent to the printer, `false` when there is no default printer
or printing could not start.

**Example**

```freebasic
dim bmp as CMemBmp = CMemBmp( 600, 400 )
if bmp.PrintBitmap( true ) = false then print "nothing printed"
```

Microsoft Learn: [StartDocW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-startdocw)

## See also

- [CGraphCtx](CGraphCtx), a control that displays a `CMemBmp` with its `DrawBitmap`
- [Bitmaps](SysWin-Bitmaps) for DIB sections, loading, saving and capturing bitmaps
- [CGpGraphics](CGpGraphics) for drawing on the memory DC with GDI+
- [GDI+ images](SysWin-GdiPlus-Images) for `BitmapFromFile`, `SaveHBITMAPToFile` and the other image helpers
- [sys/win/gui](SysWin-Gui)
