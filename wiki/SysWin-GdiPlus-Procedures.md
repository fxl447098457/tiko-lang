[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gdiplus](SysWin-GdiPlus) › **GDI+ procedures and types**

# GDI+ procedures and types
Starts GDI+, builds colours and rectangles, and converts, saves and prints images.

<!-- scope: CGpBase -->

Starts GDI+, builds colours and rectangles, and converts, saves and prints images.

These are the plain procedures of `sys/win/gdiplus`, the `CGpBase` class every `CGp*` class
derives from, and the structures, enumerations and constants the module declares.

**Starting GDI+.** GDI+ must be running before any of its objects is created. Every `CGp*` object
takes care of this through [CGpBase](#cgpbase): the first one created starts GDI+ and the last
one destroyed shuts it down, so a program that creates its objects in each `WM_PAINT` starts and
stops GDI+ on every paint. Call [Init](#init) once at start-up and [Uninit](#uninit) at the end
to keep it running, and always do so when you call the GDI+ functions directly (`Gdip…`).
The image procedures below start and stop GDI+ for themselves.

**Colours.** A GDI+ colour is an `ARGB`, a `DWORD` holding alpha, red, green and blue from the
high byte to the low: `&hFF0000FF` is opaque blue. Alpha 255 is opaque and 0 fully transparent.
This is not the byte order of a GDI `COLORREF` (`&h00BBGGRR`); use the `GDIP_*` helpers, or the
`ARGB_*` constants of [Colours](SysWin-Colors), rather than `RGB()`.

**Status.** GDI+ reports success or failure as a `GpStatus`: `Ok` (0) on success, otherwise a
reason from the [Status table](#status-values). [StatusStr](#statusstr) turns one into text.

**Images to GDI handles.** The `…FromFile`, `…FromBuffer` and `…FromRes` procedures load a PNG,
JPEG, GIF, TIFF, BMP or ICO image with GDI+ and return a new GDI icon (`HICON`) or bitmap
(`HBITMAP`), optionally dimmed or turned grey, for toolbars, image lists and buttons. **You own
the handle**: free it with `DestroyIcon` or `DeleteObject`.

**The flat API.** All the GDI+ flat functions (`GdipCreateFromHDC`, `GdipDrawLine` …), and
`GdiplusStartup` and `GdiplusShutdown`, are declared too, with the opaque handle types they take
(`GpGraphics`, `GpImage`, `GpBitmap`, `GpFont` …). Every `CGp*` object keeps its handle in a
public field (`m_pGraphics`, `m_pImage`, `m_pFont` …), so you can mix the two.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus
```

## Example

A console program that draws a half-transparent box into a bitmap, saves it as a PNG file, reads
the file's size back and makes a grey GDI bitmap from it:

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus

function main() as long
    dim token as ULONG_PTR = gdiplus.Init()
    dim st as GpStatus
    scope
        ' a half-transparent red box on a pale background, 200 x 100 pixels
        dim bmp as CGpBitmap = CGpBitmap( 200, 100 )
        dim g as CGpGraphics = @bmp
        g.Clear( GDIP_XRGB( 240, 248, 255 ) )
        dim fill as CGpSolidBrush = CGpSolidBrush( GDIP_ARGB( 160, 255, 0, 0 ) )
        dim rc as GpRectF = GDIP_RECTF( 20, 20, 160, 60 )
        g.FillRectangle( @fill, @rc )
        st = SaveImageToPng( bmp.m_pImage, "box.png" )
        print "SaveImageToPng: "; StatusStr( st )
    end scope
    dim as DWORD w, h
    st = GetImageSizeFromFile( "box.png", @w, @h )
    print "GetImageSizeFromFile: " & rtrim( StatusStr( st ) ) & ", " & w & " x " & h
    st = GetImageSizeFromFile( "missing.png", @w, @h )
    print "missing file: "; StatusStr( st )
    ' a grey GDI bitmap made from the file
    dim hbm as HBITMAP = BitmapFromFile( "box.png", 0, true )
    if hbm then print "grey HBITMAP created" else print "BitmapFromFile failed"
    DeleteObject( hbm )
    gdiplus.Uninit( token )
    return 0
end function

end main()
```

It prints:

```text
SaveImageToPng: Ok
GetImageSizeFromFile: Ok, 200 x 100
missing file: Out of memory
grey HBITMAP created
```

GDI+ reports a file it cannot open as `OutOfMemory` (3), not as `FileNotFound`.

## Functions

| Function | Does |
| --- | --- |
| **Starting GDI+** | |
| [Init](#init) | Starts GDI+ and returns a token. |
| [Uninit](#uninit) | Shuts GDI+ down. |
| [DllVersion](#dllversion) | Returns the version of `gdiplus.dll`. |
| [StatusStr](#statusstr) | Returns the description of a status code. |
| **Colours** | |
| [GDIP_ARGB](#gdip_argb) | Makes an `ARGB` colour from alpha, red, green and blue. |
| [GDIP_COLOR](#gdip_color) | The same as `GDIP_ARGB`. |
| [GDIP_XRGB](#gdip_xrgb) | Makes an opaque `ARGB` colour from red, green and blue. |
| [GDIP_RGBA](#gdip_rgba) | Makes an `ARGB` colour, alpha given last. |
| [GDIP_BGRA](#gdip_bgra) | Makes an `ARGB` colour from blue, green, red and alpha. |
| [GDIP_GetAlpha, GDIP_GetRed, GDIP_GetGreen, GDIP_GetBlue](#gdip_getalpha-gdip_getred-gdip_getgreen-gdip_getblue) | Return one component of a colour. |
| [GDIP_ARGB_SetAlpha, GDIP_ARGB_SetRed, GDIP_ARGB_SetGreen, GDIP_ARGB_SetBlue](#gdip_argb_setalpha-gdip_argb_setred-gdip_argb_setgreen-gdip_argb_setblue) | Return a colour with one component replaced. |
| **Rectangles and points** | |
| [GDIP_RECTF, GDIP_RECT](#gdip_rectf-gdip_rect) | Make a `GpRectF` or a `GpRect`. |
| [GDIP_POINTF, GDIP_POINT](#gdip_pointf-gdip_point) | Make a `GpPointF` or a `GpPoint`. |
| [PointsToPixels](#pointstopixels) | Converts a font size in points to pixels. |
| **Images to icons and bitmaps** | |
| [GetImageSizeFromFile](#getimagesizefromfile) | Reads the width and height of an image file. |
| [ImageFromFile](#imagefromfile) | Loads an image file as an icon or a bitmap. |
| [IconFromFile, BitmapFromFile](#iconfromfile-bitmapfromfile) | Load an image file as an icon, or as a bitmap. |
| [ImageFromFile2](#imagefromfile2) | Loads an image file as an icon or a bitmap, through GDI+'s own file loader. |
| [AddIconFromFile](#addiconfromfile) | Loads an image file as an icon and adds it to an image list. |
| [ImageFromBuffer](#imagefrombuffer) | Converts an image in memory into an icon or a bitmap. |
| [IconFromBuffer, BitmapFromBuffer](#iconfrombuffer-bitmapfrombuffer) | Convert an image in memory into an icon, or a bitmap. |
| [ImageFromRes](#imagefromres) | Converts an image resource into an icon or a bitmap. |
| [IconFromRes, BitmapFromRes](#iconfromres-bitmapfromres) | Convert an image resource into an icon, or a bitmap. |
| [AddIconFromRes](#addiconfromres) | Converts an image resource into an icon and adds it to an image list. |
| [ImageStreamFromRes](#imagestreamfromres) | Copies an image resource into a stream. |
| **Saving and printing** | |
| [GetEncoderClsid](#getencoderclsid) | Returns the class id of the encoder for a MIME type. |
| [SaveImageToFile](#saveimagetofile) | Saves a GDI+ image in a format given by its MIME type. |
| [SaveImageToBmp, SaveImageToJpeg, SaveImageToJpg, SaveImageToPng, SaveImageToGif, SaveImageToTiff](#saveimagetobmp-saveimagetojpeg-saveimagetojpg-saveimagetopng-saveimagetogif-saveimagetotiff) | Save a GDI+ image in one format. |
| [SaveHBITMAPToFile](#savehbitmaptofile) | Saves a GDI bitmap to a file. |
| [PrintHBITMAP](#printhbitmap) | Prints a GDI bitmap on the default printer. |
| [LoadTexture](#loadtexture) | Loads a square image as 32-bit texture data for OpenGL. |
| **Other** | |
| [ObjectTypeIsValid](#objecttypeisvalid) | Tells whether a value is a valid `ObjectType`. |
| **CGpBase** | |
| [Constructor, Destructor](#constructor-destructor) | Count the live GDI+ objects, starting and stopping GDI+. |
| [GetLastStatus](#getlaststatus) | Returns the status of the last call. |
| [SetStatus](#setstatus) | Stores a status. |
| [RefCount](#refcount) | Changes the count of live objects. |

## Reference

### Init

```freebasic
function Init() as ULONG_PTR
```

Starts GDI+ (version 1, with its background thread) and returns the token that
[Uninit](#uninit) needs. Each call starts it once more; GDI+ stays up until every start has been
matched by a shutdown, so a program can call `Init` once at start-up whatever its objects do.

The examples write it `gdiplus.Init()`, which makes plain which module's `Init` is meant.

**Returns** the token, or 0 when GDI+ could not be started.

**Example**

```freebasic
dim token as ULONG_PTR = gdiplus.Init()
if token = 0 then print "GDI+ did not start"
gdiplus.Uninit( token )
```

Microsoft Learn: [GdiplusStartup](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusinit/nf-gdiplusinit-gdiplusstartup)

### Uninit

```freebasic
sub Uninit( byval token as ULONG_PTR )
```

Shuts down the GDI+ start that `token` came from. Call it after the last `CGp*` object has been
destroyed, and never more than once per token. A token of 0 is ignored.

**Example**

```freebasic
dim token as ULONG_PTR = gdiplus.Init()
scope
    dim pen as CGpPen = CGpPen( ARGB_Red, 2 )
end scope                        ' the pen is gone before GDI+ stops
gdiplus.Uninit( token )
```

Microsoft Learn: [GdiplusShutdown](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusinit/nf-gdiplusinit-gdiplusshutdown)

### DllVersion

```freebasic
function DllVersion() as long
```

Returns the file version of `gdiplus.dll` times 100: major × 100 + minor, so version 10.0 gives
1000 and version 6.1 gives 601.

**Returns** the version, or 0 when it cannot be read.

**Example**

```freebasic
print "gdiplus.dll"; DllVersion()   ' 1000 on current Windows
```

Microsoft Learn: [GetFileVersionInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winver/nf-winver-getfileversioninfow)

### StatusStr

```freebasic
function StatusStr( byval status as GpStatus ) as ustring
```

Returns the English description of a GDI+ status code: `"Ok"`, `"Invalid parameter"`,
`"Out of memory"`, `"File not found"` …, or `"Unknown"` for any other value.

**Returns** the description.

**Example**

```freebasic
print "[" & StatusStr( InvalidParameter ) & "]"   ' [Invalid parameter]
```

Microsoft Learn: [Status](https://learn.microsoft.com/en-us/windows/win32/api/gdiplustypes/ne-gdiplustypes-status)

### GDIP_ARGB

```freebasic
function GDIP_ARGB( byval a as ubyte, byval r as ubyte, byval g as ubyte, byval b as ubyte ) as COLORREF
```

Returns the `ARGB` colour with alpha `a`, red `r`, green `g` and blue `b`, each 0 to 255:
`&hAARRGGBB`. The return type is `COLORREF`, a `DWORD` like `ARGB`, so it can be passed wherever
an `ARGB` is taken.

**Example**

```freebasic
print hex( GDIP_ARGB( 255, 255, 0, 0 ) )   ' FFFF0000: opaque red
dim glass as CGpSolidBrush = CGpSolidBrush( GDIP_ARGB( 128, 0, 0, 255 ) )
```

Microsoft Learn: [Color::MakeARGB](https://learn.microsoft.com/en-us/windows/win32/api/gdipluscolor/nf-gdipluscolor-color-makeargb)

### GDIP_COLOR

```freebasic
function GDIP_COLOR( byval a as ubyte, byval r as ubyte, byval g as ubyte, byval b as ubyte ) as COLORREF
```

Another name for [GDIP_ARGB](#gdip_argb): the same arguments in the same order, the same result.

**Example**

```freebasic
print hex( GDIP_COLOR( 128, 1, 2, 3 ) )   ' 80010203
```

### GDIP_XRGB

```freebasic
function GDIP_XRGB( byval r as ubyte, byval g as ubyte, byval b as ubyte ) as COLORREF
```

Returns the **opaque** `ARGB` colour with red `r`, green `g` and blue `b`: alpha is 255.

**Example**

```freebasic
print hex( GDIP_XRGB( 1, 2, 3 ) )   ' FF010203
```

### GDIP_RGBA

```freebasic
function GDIP_RGBA( byval r as ubyte, byval g as ubyte, byval b as ubyte, byval a as ubyte ) as COLORREF
```

Returns the `ARGB` colour with red `r`, green `g`, blue `b` and alpha `a`: the arguments are in
RGBA order, the result is the usual `&hAARRGGBB`.

**Example**

```freebasic
print hex( GDIP_RGBA( 1, 2, 3, 4 ) )   ' 4010203
```

### GDIP_BGRA

```freebasic
function GDIP_BGRA( byval b as ubyte, byval g as ubyte, byval r as ubyte, byval a as ubyte ) as COLORREF
```

Returns the `ARGB` colour with blue `b`, green `g`, red `r` and alpha `a`: the arguments are in
the order the bytes have in memory, the result is the usual `&hAARRGGBB`.

`GDIP_BGRA` is also the name of a union that overlays a colour (`color`) with its four bytes
(`blue`, `green`, `red`, `alpha`); see [Types](#types).

**Example**

```freebasic
print hex( GDIP_BGRA( 1, 2, 3, 4 ) )   ' 4030201
```

### GDIP_GetAlpha, GDIP_GetRed, GDIP_GetGreen, GDIP_GetBlue

```freebasic
function GDIP_GetAlpha( byval argbcolor as COLORREF ) as byte
function GDIP_GetRed( byval argbcolor as COLORREF ) as byte
function GDIP_GetGreen( byval argbcolor as COLORREF ) as byte
function GDIP_GetBlue( byval argbcolor as COLORREF ) as byte
```

Return one component of an `ARGB` colour.

The result type is `byte`, which is **signed**: a component of 128 or more comes back negative,
so opaque alpha (255) reads as -1. Mask it with `and 255` for the value 0 to 255.

**Returns** the component, as a signed byte.

**Example**

```freebasic
dim c as ARGB = &hFF102030
print GDIP_GetAlpha( c ); GDIP_GetRed( c ); GDIP_GetGreen( c ); GDIP_GetBlue( c )   ' -1 16 32 48
print GDIP_GetAlpha( c ) and 255                                                     ' 255
```

### GDIP_ARGB_SetAlpha, GDIP_ARGB_SetRed, GDIP_ARGB_SetGreen, GDIP_ARGB_SetBlue

```freebasic
function GDIP_ARGB_SetAlpha( byval argbcolor as COLORREF, byval alphaColor as byte ) as ARGB
function GDIP_ARGB_SetRed( byval argbcolor as COLORREF, byval redColor as byte ) as ARGB
function GDIP_ARGB_SetGreen( byval argbcolor as COLORREF, byval greenColor as byte ) as ARGB
function GDIP_ARGB_SetBlue( byval argbcolor as COLORREF, byval blueColor as byte ) as ARGB
```

Return `argbcolor` with one component replaced and the other three unchanged. Use
`GDIP_ARGB_SetAlpha` to make a translucent version of a named colour. The new component is a
`byte`, but 128 to 255 work as well: they are stored as the same bits, so
`GDIP_ARGB_SetAlpha( c, 200 )` gives alpha &hC8.

**Returns** the new colour.

**Example**

```freebasic
print hex( GDIP_ARGB_SetAlpha( &hFF102030, 64 ) )   ' 40102030
dim shadow as CGpSolidBrush = CGpSolidBrush( GDIP_ARGB_SetAlpha( ARGB_Black, 96 ) )
```

### GDIP_RECTF, GDIP_RECT

```freebasic
function GDIP_RECTF( byval x as single, byval y as single, byval nWidth as single, byval nHeight as single ) as GpRectF
function GDIP_RECT( byval x as long, byval y as long, byval nWidth as long, byval nHeight as long ) as GpRect
```

Return a GDI+ rectangle with its top-left corner at (`x`, `y`) and the given width and height:
`GpRectF` in `single` coordinates, `GpRect` in whole pixels. Unlike a GDI `RECT`, a GDI+
rectangle stores a width and a height, not the right and bottom edges.

**Example**

```freebasic
dim rcf as GpRectF = GDIP_RECTF( 1.5, 2, 3, 4 )
dim rc as GpRect = GDIP_RECT( 10, 10, 100, 50 )
print rcf.X; rc.Width   ' 1.5 100
```

Microsoft Learn: [RectF](https://learn.microsoft.com/en-us/windows/win32/api/gdiplustypes/nl-gdiplustypes-rectf)

### GDIP_POINTF, GDIP_POINT

```freebasic
function GDIP_POINTF( byval x as single, byval y as single ) as GpPointF
function GDIP_POINT( byval x as long, byval y as long ) as GpPoint
```

Return a GDI+ point (`x`, `y`): `GpPointF` in `single` coordinates, `GpPoint` in whole pixels.

**Example**

```freebasic
dim ptf as GpPointF = GDIP_POINTF( 0.5, 1.5 )
dim pt as GpPoint = GDIP_POINT( 7, 8 )
print ptf.Y; pt.X   ' 1.5 7
```

Microsoft Learn: [PointF](https://learn.microsoft.com/en-us/windows/win32/api/gdiplustypes/nl-gdiplustypes-pointf)

### PointsToPixels

```freebasic
function PointsToPixels( byval ptSize as single, byval fUsingWorldTransform as boolean = false ) as single
```

Converts a font size in points (1/72 inch) to pixels.

- With `fUsingWorldTransform` `false` (the default) the size is scaled with the desktop's
  horizontal DPI: `ptSize × dpi / 72`.
- With `true`, for a [CGpGraphics](CGpGraphics) whose world transformation already scales for
  the DPI (`ScaleTransformForDpi`), the result is `ptSize × 1.3333`, the 96-DPI conversion.

**Returns** the size in pixels.

**Example**

```freebasic
print PointsToPixels( 12 ); PointsToPixels( 10.5 ); PointsToPixels( 12, true )   ' 16 13 15.9996 at 96 DPI
```

Microsoft Learn: [MulDiv](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-muldiv)

### GetImageSizeFromFile

```freebasic
function GetImageSizeFromFile( byref wszFileName as wstring, byval nWidth as DWORD ptr, byval nHeight as DWORD ptr ) as long
```

Opens an image file with GDI+ and reads its width and height in pixels into `*nWidth` and
`*nHeight`. GDI+ is started and stopped for the call.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The image file. |
| `nWidth`, `nHeight` | Receive the size; left as they were when the file cannot be opened. |

**Returns** `Ok` (0) on success; a GDI+ status on failure (`OutOfMemory` for a missing or
unreadable file); `E_INVALIDARG` for an empty file name. When GDI+ itself cannot be started it
returns 0 without filling the sizes.

**Example**

```freebasic
dim as DWORD w, h
if GetImageSizeFromFile( "photo.jpg", @w, @h ) = Ok then print w; " x"; h
```

Microsoft Learn: [Image::GetWidth](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getwidth)

### ImageFromFile

```freebasic
function ImageFromFile( byref wszFileName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false, byval imageType as long = IMAGE_ICON, byval clrBackground as ARGB = 0 ) as HANDLE
```

Reads an image file into memory and converts it, like [ImageFromBuffer](#imagefrombuffer), into
a new GDI icon or bitmap of the image's size. The file is read with the Windows file functions,
so Unicode paths work; files of 4 GB or more, folders and files marked temporary are refused.

The pixels can be changed on the way:

- **`dimPercent`** from 1 to 99 moves each colour that percentage of the way towards white:
  50 turns red (255, 0, 0) into (255, 128, 128). Use it for the faded image of a disabled
  button.
- **`bGrayScale`** `true` turns each pixel grey, from 0.299 red + 0.587 green + 0.114 blue,
  after any dimming. Alpha is kept.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The image file: PNG, JPEG, GIF, TIFF, BMP, ICO. |
| `dimPercent` | 0 (the default) for no dimming, or 1 to 99. |
| `bGrayScale` | `true` to turn the image grey. |
| `imageType` | `IMAGE_ICON` (the default) or `IMAGE_BITMAP`. |
| `clrBackground` | For `IMAGE_BITMAP`, the `ARGB` colour that translucent pixels are blended with; ignored for icons. |

**Returns** the new `HICON` or `HBITMAP`, which you must free with `DestroyIcon` or
`DeleteObject`; `NULL` on failure.

**Example**

```freebasic
dim hIcon as HICON = ImageFromFile( "save.png" )
dim hGrey as HBITMAP = ImageFromFile( "save.png", 40, true, IMAGE_BITMAP, ARGB_White )
DestroyIcon( hIcon ) : DeleteObject( hGrey )
```

Microsoft Learn: [Bitmap::GetHICON](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-gethicon)

### IconFromFile, BitmapFromFile

```freebasic
function IconFromFile( byref wszFileName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false ) as HANDLE
function BitmapFromFile( byref wszFileName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false, byval clrBackground as ARGB = 0 ) as HANDLE
```

[ImageFromFile](#imagefromfile) with `IMAGE_ICON` or with `IMAGE_BITMAP`.

**Returns** the new `HICON` or `HBITMAP`, yours to free; `NULL` on failure.

**Example**

```freebasic
dim hIcon as HICON = IconFromFile( "open.png" )
dim hbm as HBITMAP = BitmapFromFile( "logo.png", 0, false, ARGB_White )
if hIcon = NULL then print "open.png could not be loaded"
```

Microsoft Learn: [Bitmap::GetHBITMAP](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-gethbitmap)

### ImageFromFile2

```freebasic
function ImageFromFile2( byref wszFileName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false, byval imageType as long = IMAGE_ICON, byval clrBackground as ARGB = 0 ) as HANDLE
```

The same as [ImageFromFile](#imagefromfile), but the file is opened by GDI+'s own file loader
instead of being read into memory first. That loader shows images in dim grey (often used for
disabled icons) in darker shades, so prefer `ImageFromFile`. When the file cannot be opened the
call returns without shutting down the GDI+ start it made.

**Returns** the new `HICON` or `HBITMAP`, yours to free; `NULL` on failure.

**Example**

```freebasic
dim hbm as HBITMAP = ImageFromFile2( "chart.png", 0, false, IMAGE_BITMAP )
DeleteObject( hbm )
```

Microsoft Learn: [Image::FromFile](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-fromfile)

### AddIconFromFile

```freebasic
function AddIconFromFile( byval hIml as HIMAGELIST, byref wszFileName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false ) as long
```

Loads an image file as an icon, with [ImageFromFile](#imagefromfile), adds it to the end of an
image list and destroys the icon.

| Parameter | Meaning |
| --- | --- |
| `hIml` | The image list. |
| `wszFileName` | The image file. |
| `dimPercent`, `bGrayScale` | As for [ImageFromFile](#imagefromfile). |

**Returns** the index of the new image.

**Example**

```freebasic
dim hIml as HIMAGELIST = ImageList_Create( 24, 24, ILC_COLOR32 or ILC_MASK, 4, 4 )
AddIconFromFile( hIml, "new.png" )
AddIconFromFile( hIml, "new.png", 50, true )   ' the disabled look
```

Microsoft Learn: [ImageList_ReplaceIcon](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-imagelist_replaceicon)

### ImageFromBuffer

```freebasic
function ImageFromBuffer( byval pBuffer as any ptr, byval bufferSize as SIZE_T_, byval dimPercent as long = 0, byval bGrayScale as long = false, byval imageType as long = IMAGE_ICON, byval clrBackground as ARGB = 0 ) as HANDLE
```

Converts an image file held in memory (the bytes of a PNG, JPEG, GIF … file) into a new GDI
icon or bitmap. The bytes are copied into a stream for GDI+, so the buffer can be freed as soon
as the call returns. `dimPercent`, `bGrayScale`, `imageType` and `clrBackground` work as for
[ImageFromFile](#imagefromfile).

| Parameter | Meaning |
| --- | --- |
| `pBuffer` | The first byte of the image. |
| `bufferSize` | Its size in bytes. |

**Returns** the new `HICON` or `HBITMAP`, yours to free; `NULL` on failure.

**Example**

```freebasic
dim hRes as HRSRC = FindResourceW( NULL, "LOGO", cast( LPCWSTR, RT_RCDATA ) )
dim pData as any ptr = LockResource( LoadResource( NULL, hRes ) )
dim hbm as HBITMAP = ImageFromBuffer( pData, SizeofResource( NULL, hRes ), 0, false, IMAGE_BITMAP )
```

Microsoft Learn: [CreateStreamOnHGlobal](https://learn.microsoft.com/en-us/windows/win32/api/combaseapi/nf-combaseapi-createstreamonhglobal)

### IconFromBuffer, BitmapFromBuffer

```freebasic
function IconFromBuffer( byval pBuffer as any ptr, byval bufferSize as SIZE_T_, byval dimPercent as long = 0, byval bGrayScale as long = false ) as HANDLE
function BitmapFromBuffer( byval pBuffer as any ptr, byval bufferSize as SIZE_T_, byval dimPercent as long = 0, byval bGrayScale as long = false, byval clrBackground as ARGB = 0 ) as HANDLE
```

[ImageFromBuffer](#imagefrombuffer) with `IMAGE_ICON` or with `IMAGE_BITMAP`.

**Returns** the new `HICON` or `HBITMAP`, yours to free; `NULL` on failure.

**Example**

```freebasic
dim pPng as ubyte ptr = callocate( 1 )   ' the bytes of a PNG file
dim hIcon as HICON = IconFromBuffer( pPng, 1 )
if hIcon = NULL then print "not an image"
deallocate( pPng )
```

### ImageFromRes

```freebasic
function ImageFromRes( byval hInstance as HINSTANCE, byref wszImageName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false, byval imageType as long = IMAGE_ICON, byval clrBackground as ARGB = 0 ) as HANDLE
```

Converts an image stored as a raw-data resource (`RCDATA`) into a new GDI icon or bitmap, as
[ImageFromBuffer](#imagefrombuffer) does with memory. `dimPercent`, `bGrayScale`, `imageType`
and `clrBackground` work as for [ImageFromFile](#imagefromfile).

| Parameter | Meaning |
| --- | --- |
| `hInstance` | The module that holds the resource; `NULL` for the program itself. |
| `wszImageName` | The resource's name, or `"#"` and its number, such as `"#998"`. |

The resource must be embedded as `RCDATA`, for example `LOGO RCDATA "logo.png"` in the `.rc`
file; see [Resources](SysWin-Resources).

**Returns** the new `HICON` or `HBITMAP`, yours to free; `NULL` on failure.

**Example**

```freebasic
dim hbm as HBITMAP = ImageFromRes( NULL, "LOGO", 0, false, IMAGE_BITMAP, ARGB_White )
dim hIcon as HICON = ImageFromRes( NULL, "#998" )
```

Microsoft Learn: [FindResourceW](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-findresourcew)

### IconFromRes, BitmapFromRes

```freebasic
function IconFromRes( byval hInstance as HINSTANCE, byref wszImageName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false ) as HANDLE
function BitmapFromRes( byval hInstance as HINSTANCE, byref wszImageName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false, byval clrBackground as ARGB = 0 ) as HANDLE
```

[ImageFromRes](#imagefromres) with `IMAGE_ICON` or with `IMAGE_BITMAP`.

**Returns** the new `HICON` or `HBITMAP`, yours to free; `NULL` on failure.

**Example**

```freebasic
dim hIcon as HICON = IconFromRes( GetModuleHandleW( NULL ), "TOOL_SAVE" )
dim hbm as HBITMAP = BitmapFromRes( NULL, "BANNER" )
```

### AddIconFromRes

```freebasic
function AddIconFromRes( byval hIml as HIMAGELIST, byval hInstance as HINSTANCE, byref wszImageName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false ) as long
```

Converts an `RCDATA` image resource into an icon, with [ImageFromRes](#imagefromres), adds it to
the end of an image list and destroys the icon.

**Returns** the index of the new image.

**Example**

```freebasic
dim hIml as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32 or ILC_MASK, 4, 4 )
AddIconFromRes( hIml, NULL, "TOOL_OPEN" )
AddIconFromRes( hIml, NULL, "TOOL_SAVE" )
```

### ImageStreamFromRes

```freebasic
function ImageStreamFromRes( byval hInstance as HINSTANCE, byref wszImageName as wstring ) as IStream ptr
```

Copies an `RCDATA` resource into a block of global memory and returns a stream over it, ready for
the stream constructors of `CGpImage` and `CGpBitmap` (see [GDI+ images](SysWin-GdiPlus-Images)).
The stream owns the memory and frees it when it is released. The names work as for
[ImageFromRes](#imagefromres).

Each call starts GDI+ once and does not shut it down again.

**Returns** the stream, which you must release (`pStream->lpVtbl->Release( pStream )`) once the
image made from it has been destroyed; `NULL` on failure.

**Example**

```freebasic
dim pStream as IStream ptr = ImageStreamFromRes( NULL, "PHOTO" )
if pStream then
    scope
        dim img as CGpBitmap = CGpBitmap( pStream )
        print img.GetWidth()
    end scope
    pStream->lpVtbl->Release( pStream )
end if
```

Microsoft Learn: [CreateStreamOnHGlobal](https://learn.microsoft.com/en-us/windows/win32/api/combaseapi/nf-combaseapi-createstreamonhglobal)

### GetEncoderClsid

```freebasic
function GetEncoderClsid( byref wszMimeType as wstring ) as GUID
```

Returns the class id of the image encoder for a MIME type, which `CGpImage.Save` and
`GdipSaveImageToFile` need. The built-in encoders are `"image/bmp"`, `"image/jpeg"`,
`"image/gif"`, `"image/tiff"` and `"image/png"`; the case of the letters does not matter.

**Returns** the class id, or a GUID of zeros when no encoder handles the type.

**Example**

```freebasic
dim clsid as GUID = GetEncoderClsid( "image/png" )
dim wsz as wstring * 40
StringFromGUID2( @clsid, @wsz, 40 )   ' the PNG encoder's class id as text
```

Microsoft Learn: [Retrieving the class identifier for an encoder](https://learn.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-retrieving-the-class-identifier-for-an-encoder-use)

### SaveImageToFile

```freebasic
function SaveImageToFile( byval pImage as GpImage ptr, byref wszFileName as wstring, byref wszMimeType as wstring ) as long
```

Saves a GDI+ image in the format of a MIME type (see [GetEncoderClsid](#getencoderclsid)), with
the encoder's default settings. An existing file is replaced. For a `CGpImage` or `CGpBitmap`
pass its `m_pImage` field.

| Parameter | Meaning |
| --- | --- |
| `pImage` | The GDI+ image. |
| `wszFileName` | The file to write. |
| `wszMimeType` | The format, such as `"image/png"`. |

**Returns** `Ok` on success, otherwise a GDI+ status; `InvalidParameter` when `pImage` is `NULL`
or the file name is blank. When GDI+ cannot be started it returns `GdiplusNotInitialized` without saving.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 64, 64 )
if SaveImageToFile( bmp.m_pImage, "blank.png", "image/png" ) <> Ok then print "not saved"
```

Microsoft Learn: [Image::Save](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-save%28constwchar_constclsid_constencoderparameters%29)

### SaveImageToBmp, SaveImageToJpeg, SaveImageToJpg, SaveImageToPng, SaveImageToGif, SaveImageToTiff

```freebasic
function SaveImageToBmp( byval pImage as GpImage ptr, byref wszFileName as wstring ) as long
function SaveImageToJpeg overload( byval pImage as GpImage ptr, byref wszFileName as wstring ) as long
function SaveImageToJpg overload( byval pImage as GpImage ptr, byref wszFileName as wstring ) as long
function SaveImageToPng( byval pImage as GpImage ptr, byref wszFileName as wstring ) as long
function SaveImageToGif( byval pImage as GpImage ptr, byref wszFileName as wstring ) as long
function SaveImageToTiff( byval pImage as GpImage ptr, byref wszFileName as wstring ) as long
```

[SaveImageToFile](#saveimagetofile) with `"image/bmp"`, `"image/jpeg"` (both `Jpeg` and `Jpg`),
`"image/png"`, `"image/gif"` or `"image/tiff"`. JPEG is saved at the encoder's default quality;
GIF reduces the image to 256 colours.

**Returns** `Ok` on success, otherwise a GDI+ status.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 64, 64 )
SaveImageToPng( bmp.m_pImage, "icon.png" )
SaveImageToJpg( bmp.m_pImage, "icon.jpg" )
```

### SaveHBITMAPToFile

```freebasic
function SaveHBITMAPToFile( byval hbmp as HBITMAP, byref wszFileName as wstring, byref wszMimeType as wstring = "image/bmp" ) as long
```

Saves a GDI bitmap, such as a screen capture, to a file in the format of a MIME type
(`"image/bmp"` by default; see [GetEncoderClsid](#getencoderclsid)). The bitmap is copied and
stays yours.

**Returns** `Ok` on success, otherwise a GDI+ status; `InvalidParameter` when `hbmp` is `NULL` or
the file name is blank.

**Example**

```freebasic
dim hbm as HBITMAP = BitmapFromFile( "photo.jpg" )
SaveHBITMAPToFile( hbm, "photo.png", "image/png" )
DeleteObject( hbm )
```

Microsoft Learn: [Bitmap](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nl-gdiplusheaders-bitmap)

### PrintHBITMAP

```freebasic
function PrintHBITMAP( byval hbmp as HBITMAP, byval bStretch as boolean = false, byval nStretchMode as long = InterpolationModeHighQualityBicubic ) as boolean
```

Prints a GDI bitmap on the default printer, without a dialog, as a document named "Printing
bitmap", once per copy set in the printer's default settings.

- With `bStretch` `false` the bitmap is drawn at the top-left of the printable area at its own
  physical size (its resolution, 96 DPI for a screen bitmap).
- With `true` it is stretched to fill the whole printable area, resampled with
  `nStretchMode`; the proportions are not kept.

The printer's device context is not deleted afterwards.

| Parameter | Meaning |
| --- | --- |
| `hbmp` | The bitmap; it stays yours. |
| `bStretch` | `true` to fill the page. |
| `nStretchMode` | An `InterpolationMode*` value, used when stretching. |

**Returns** `true` when the document was sent to the printer; `false` when there is no default
printer or a step failed.

**Example**

```freebasic
dim hbm as HBITMAP = BitmapFromFile( "chart.png", 0, false, ARGB_White )
if PrintHBITMAP( hbm, true ) = false then print "not printed"
DeleteObject( hbm )
```

Microsoft Learn: [StartDocW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-startdocw)

### LoadTexture

```freebasic
function LoadTexture overload( byref wszFileName as wstring, byref TextureWidth as long, byref TextureHeight as long, byref strTextureData as string ) as long
function LoadTexture overload( byval hInstance as HINSTANCE, byref wszResourceName as wstring, byref TextureWidth as long, byref TextureHeight as long, byref strTextureData as string ) as long
```

Loads an image from a file, or from an `RCDATA` resource, as texture data for OpenGL. The image
must be **square, with a side that is a power of 2** (64, 128, 256 …). It is flipped vertically,
because OpenGL starts at the bottom row, and its pixels are stored in `strTextureData` as 4
bytes each, red, green, blue, alpha: the layout `glTexImage2D` takes with `GL_RGBA` and
`GL_UNSIGNED_BYTE`. The string holds width × height × 4 bytes.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The image file. |
| `hInstance`, `wszResourceName` | The module and the name of the resource. |
| `TextureWidth`, `TextureHeight` | Receive the size of the image. |
| `strTextureData` | Receives the pixels. |

**Returns** 0 on success; `ERROR_INVALID_DATA` (13) when the image is not square or its side is
not a power of 2 (the size is still filled in); a GDI+ status when the image cannot be loaded
(`OutOfMemory` (3) for a missing file); for the resource form, `E_POINTER` when the resource is
missing; 18 (`GdiplusNotInitialized`) when GDI+ cannot be started.

**Example**

```freebasic
dim as long w, h
dim texels as string
if LoadTexture( "brick.png", w, h, texels ) = 0 then
    ' glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, strptr( texels ) )
    print w; " x"; h; len( texels )   ' 64 x 64 16384 for a 64-pixel image
end if
```

Microsoft Learn: [Image::GetThumbnailImage](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getthumbnailimage)

### ObjectTypeIsValid

```freebasic
function ObjectTypeIsValid( byval type_ as ObjectType ) as boolean
```

Returns `true` when `type_` is one of the GDI+ object types of an EMF+ record, from
`ObjectTypeBrush` (1) to `ObjectTypeGraphics` (9).

**Example**

```freebasic
print ObjectTypeIsValid( ObjectTypeFont ); ObjectTypeIsValid( 99 )   ' truefalse
```

Microsoft Learn: [ObjectType](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusenums/ne-gdiplusenums-objecttype)

## CGpBase

`CGpBase` is the base of every GDI+ class of the module. It holds the last status and keeps one
count, shared by all classes, of the live objects. You do not create one yourself; its members
are called on any `CGp*` object.

### Constructor, Destructor

```freebasic
constructor
destructor
```

The constructor adds one to the count of live GDI+ objects; when the count was 0 it starts GDI+
first. The destructor takes one off; when the count reaches 0 it shuts GDI+ down. If GDI+ cannot
be started, the constructor shows a message box saying so and stores the failure as the
object's status.

**Example**

```freebasic
scope
    dim pen as CGpPen = CGpPen( ARGB_Blue )   ' the first object: GDI+ starts
end scope                                     ' the last object: GDI+ stops
```

Microsoft Learn: [GdiplusStartup](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusinit/nf-gdiplusinit-gdiplusstartup)

### GetLastStatus

```freebasic
function GetLastStatus() as GpStatus
```

Returns the status stored by the object's last call: the constructor's outcome until a method is
called, then the outcome of the last method that stores one. Unlike GDI+'s own `GetLastStatus`
it does not reset the value.

**Example**

```freebasic
dim fam as CGpFontFamily = CGpFontFamily( "NoSuchFont" )
if fam.GetLastStatus() <> Ok then print rtrim( StatusStr( fam.GetLastStatus() ) )   ' Font family not found
```

### SetStatus

```freebasic
function SetStatus( byval status as GpStatus ) as GpStatus
```

Stores `status` as the object's last status and returns it. The classes use it to record the
outcome of each call; call it yourself to clear the status before a sequence of calls.

**Returns** `status`.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_Red )
pen.SetStatus( Ok )
```

### RefCount

```freebasic
function RefCount( byval bIncrement as boolean ) as long
```

Adds one to the shared count of live GDI+ objects (`bIncrement` `true`) or takes one off
(`false`), starting GDI+ when the count was 0 and shutting it down when it reaches 0. The
constructor and destructor call it; call it yourself in matched pairs only, to keep GDI+ running
across a stretch of code without an object.

**Returns** the new count.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_Red )
pen.RefCount( true )      ' GDI+ now outlives the pen
pen.RefCount( false )
```

## Types

### Structures

| Type | Holds |
| --- | --- |
| `GpPoint`, `GpPointF` | A point: `X`, `Y` (`INT_` or `single`). |
| `GpSize`, `GpSizeF` | A size: `Width`, `Height`. |
| `GpRect`, `GpRectF` | A rectangle: `X`, `Y`, `Width`, `Height`. |
| `GpCharacterRange` | A range of characters in a string: `First`, `Length`; see [CGpStringFormat](CGpStringFormat). |
| `GpPathData`, `GDIP_PATHDATA` | The points of a path: `Count`, `Points` (`GpPointF ptr`), `Types` (one byte per point). |
| `BitmapData` | A locked area of a bitmap: `Width`, `Height`, `Stride`, `PixelFormat`, `Scan0`. |
| `ColorPalette`, `GpColorPalette` | A palette: `Flags`, `Count`, `Entries()`; `GpColorPalette` has room for 256 entries. |
| `ColorMatrix`, `GpColorMatrix` | A 5 × 5 matrix of `single`, `m(0 to 4, 0 to 4)`, for colour transformations. |
| `Color_`, `GpColor` | A colour: `Color_` is a structure with one `ARGB` field `Value`; `GpColor` is another name for `ARGB`. |
| `ColorMap_`, `GpColorMap`, `GDIP_COLORMAP` | An old colour and a new colour, for remap tables; the union `GDIP_COLORMAP` also names them `from` and `to`. |
| `GDIP_BGRA` | A union of a colour (`color`) with its bytes `blue`, `green`, `red`, `alpha`. |
| `EncoderParameter`, `EncoderParameters` | Settings for an image encoder (a GUID, a value type and values), and a counted array of them. |
| `ImageCodecInfo` | A codec's class id, format, name, file extensions and MIME type. |
| `ImageItemData` | Custom metadata of an image. |
| `PropertyItem` | One item of image metadata: `id`, `length`, `type`, `value`. |
| `MetafileHeader` | The properties of a metafile; holds a `METAHEADER` or an `ENHMETAHEADER3`. |
| `tagENHMETAHEADER3`, `ENHMETAHEADER3`, `LPENHMETAHEADER3` | The header of an enhanced metafile. |
| `WmfPlaceableFileHeader`, `PWMFRect16` | The header of a placeable metafile and its bounding rectangle. |
| `GdiplusStartupInput`, `GdiplusStartupOutput` | The arguments and results of `GdiplusStartup`. |
| `BlurParams`, `SharpenParams`, `BrightnessContrastParams`, `HueSaturationLightnessParams`, `LevelsParams`, `TintParams`, `ColorBalanceParams`, `ColorCurveParams`, `ColorLUTParams`, `RedEyeCorrectionParams` | The parameters of the GDI+ effects; see [GDI+ effects](SysWin-GdiPlus-Effects). |

### Other type names

| Type | Is |
| --- | --- |
| `ARGB` | A `DWORD` colour, `&hAARRGGBB`. |
| `PixelFormat` | An `INT_` pixel format; see [Pixel formats](#pixel-formats). |
| `GraphicsContainer`, `GraphicsState` | `DWORD` values returned by the container and save methods of [CGpGraphics](CGpGraphics). |
| `GpGraphics`, `GpImage`, `GpBitmap`, `GpMetafile`, `GpCachedBitmap`, `GpBrush`, `GpSolidFill`, `GpHatch`, `GpTexture`, `GpLineGradient`, `GpPathGradient`, `GpPen`, `GpCustomLineCap`, `GpAdjustableArrowCap`, `GpPath`, `GpPathIterator`, `GpRegion`, `GpMatrix`, `GpFont`, `GpFontFamily`, `GpFontCollection`, `GpStringFormat`, `GpImageAttributes`, `GpEffect` | The opaque GDI+ objects of the flat API, always used as pointers. |
| `GpBrushType`, `GpCombineMode`, `GpUnit`, `GpFillMode`, `GpMatrixOrder` … | A `Gp` name for each enumeration below (`GpUnit` for `Unit`). |
| `DebugEventProc`, `DrawImageAbort`, `GetThumbnailImageAbort`, `EnumerateMetafileProc`, `NotificationHookProc`, `NotificationUnhookProc`, `GdiplusAbort` | Callback and abort types of the flat API. |

### Enumerations

Each enumeration is a `long` type whose constants start with its name, except `Status_` and
`GpStatus`.

| Type | Constants | For |
| --- | --- | --- |
| `BrushType` | `BrushTypeSolidColor` … `BrushTypeLinearGradient` | the kind of a brush |
| `CombineMode` | `CombineModeReplace`, `Intersect`, `Union`, `Xor`, `Exclude`, `Complement` | combining regions and clips |
| `CompositingMode`, `CompositingQuality` | `CompositingModeSourceOver`, `SourceCopy`; `CompositingQuality…` | blending with the background |
| `CoordinateSpace` | `CoordinateSpaceWorld`, `Page`, `Device` | transforming points |
| `CustomLineCapType` | `CustomLineCapTypeDefault`, `AdjustableArrow` | line caps |
| `DashCap`, `DashStyle` | `DashCapFlat` …; `DashStyleSolid`, `Dash`, `Dot`, `DashDot`, `DashDotDot`, `Custom` | dashed lines |
| `DitherType`, `PaletteType`, `PaletteFlags` | `DitherType…`, `PaletteType…`, `PaletteFlags…` | converting pixel formats and palettes |
| `DriverStringOptions` | `DriverStringOptions…` | drawing glyph strings |
| `EmfPlusRecordType`, `EmfToWmfBitsFlags`, `EmfType`, `MetafileFrameUnit`, `MetafileType` | `WmfRecordType…` and `EmfPlusRecordType…`, … | metafiles |
| `EncoderParameterValueType`, `EncoderValue` | `EncoderParameterValueType…`, `EncoderValue…` | encoder settings |
| `FillMode` | `FillModeAlternate`, `FillModeWinding` | filling paths and polygons |
| `FlushIntention` | `FlushIntentionFlush`, `Sync` | flushing a graphics object |
| `FontStyle` | `FontStyleRegular`, `Bold`, `Italic`, `BoldItalic`, `Underline`, `Strikeout` | [fonts](SysWin-GdiPlus-Fonts) |
| `HatchStyle` | `HatchStyleHorizontal` … `HatchStyleMax` | hatch brushes |
| `HotkeyPrefix`, `StringAlignment`, `StringDigitSubstitute`, `StringFormatFlags`, `StringTrimming` | see [CGpStringFormat](CGpStringFormat) | text layout |
| `ImageType`, `ImageFlags`, `ImageCodecFlags`, `ImageLockMode`, `ItemDataPosition`, `RotateFlipType` | `ImageType…`, `ImageFlags…`, `ImageCodecFlags…`, `ImageLockMode…`, `ItemDataPosition…`, `Rotate…Flip…` | images |
| `InterpolationMode`, `PixelOffsetMode`, `SmoothingMode`, `TextRenderingHint`, `QualityMode` | `InterpolationMode…`, `PixelOffsetMode…`, `SmoothingMode…`, `TextRenderingHint…`, `QualityMode…` | rendering quality |
| `LinearGradientMode`, `WrapMode`, `WarpMode` | `LinearGradientModeHorizontal` …, `WrapModeTile` …, `WarpModePerspective`, `Bilinear` | gradients, textures, warping |
| `LineCap`, `LineJoin`, `PenAlignment`, `PenType` | `LineCapFlat` …, `LineJoinMiter` …, `PenAlignmentCenter`, `Inset`, `PenType…` | pens |
| `MatrixOrder` | `MatrixOrderPrepend`, `MatrixOrderAppend` | transformations |
| `ObjectType` | `ObjectTypeInvalid`, `ObjectTypeBrush` … `ObjectTypeGraphics`, `ObjectTypeMin`, `ObjectTypeMax` | EMF+ records |
| `PathPointType` | `PathPointTypeStart`, `Line`, `Bezier`, `CloseSubpath` … | path points |
| `Unit` | `UnitWorld` (0), `UnitDisplay`, `UnitPixel`, `UnitPoint`, `UnitInch`, `UnitDocument`, `UnitMillimeter` | sizes and page units |
| `ColorAdjustType`, `ColorMatrixFlags`, `ColorChannelFlags`, `HistogramFormat` | `ColorAdjustType…`, `ColorMatrixFlags…`, `ColorChannelFlags…`, `HistogramFormat…` | image attributes and histograms |
| `CurveAdjustments`, `CurveChannel` | `AdjustExposure` …, `CurveChannelAll` … | the colour-curve effect |
| `GpTestControlEnum` | `TestControlForceBilinear`, `TestControlForceNoICM`, `TestControlGetBuildNumber` | GDI+ test settings |
| `Status_`, `GpStatus` | see [Status values](#status-values) | results |

### Status values

`Status_` names the codes without a prefix, `GpStatus` with the prefix `Status`; both have the
same values, and every method and procedure returns them.

| Value | `Status_` | `GpStatus` |
| --- | --- | --- |
| 0 | `Ok` | `StatusOk` |
| 1 | `GenericError` | `StatusGenericError` |
| 2 | `InvalidParameter` | `StatusInvalidParameter` |
| 3 | `OutOfMemory` | `StatusOutOfMemory` |
| 4 | `ObjectBusy` | `StatusObjectBusy` |
| 5 | `InsufficientBuffer` | `StatusInsufficientBuffer` |
| 6 | `NotImplemented` | `StatusNotImplemented` |
| 7 | `Win32Error` | `StatusWin32Error` |
| 8 | `WrongState` | `StatusWrongState` |
| 9 | `Aborted` | `StatusAborted` |
| 10 | `FileNotFound` | `StatusFileNotFound` |
| 11 | `ValueOverflow` | `StatusValueOverflow` |
| 12 | `AccessDenied` | `StatusAccessDenied` |
| 13 | `UnknownImageFormat` | `StatusUnknownImageFormat` |
| 14 | `FontFamilyNotFound` | `StatusFontFamilyNotFound` |
| 15 | `FontStyleNotFound` | `StatusFontStyleNotFound` |
| 16 | `NotTrueTypeFont` | `StatusNotTrueTypeFont` |
| 17 | `UnsupportedGdiplusVersion` | `StatusUnsupportedGdiplusVersion` |
| 18 | `GdiplusNotInitialized` | `StatusGdiplusNotInitialized` |
| 19 | `PropertyNotFound` | `StatusPropertyNotFound` |
| 20 | `PropertyNotSupported` | `StatusPropertyNotSupported` |
| 21 | `ProfileNotFound` | `StatusProfileNotFound` |

### Pixel formats

A `PixelFormat` value holds the bits per pixel in its second byte and flags in its upper bits.

| Constant | Value | Bits | Alpha | Notes |
| --- | --- | --- | --- | --- |
| `PixelFormat1bppIndexed` | &h30101 | 1 | | indexed (palette) |
| `PixelFormat4bppIndexed` | &h30402 | 4 | | indexed |
| `PixelFormat8bppIndexed` | &h30803 | 8 | | indexed |
| `PixelFormat16bppGrayScale` | &h101004 | 16 | | extended |
| `PixelFormat16bppRGB555` | &h21005 | 16 | | |
| `PixelFormat16bppRGB565` | &h21006 | 16 | | |
| `PixelFormat16bppARGB1555` | &h61007 | 16 | yes | |
| `PixelFormat24bppRGB` | &h21808 | 24 | | |
| `PixelFormat32bppRGB` | &h22009 | 32 | | |
| `PixelFormat32bppARGB` | &h26200A | 32 | yes | canonical |
| `PixelFormat32bppPARGB` | &hE200B | 32 | yes | premultiplied alpha; the default of `CGpBitmap` |
| `PixelFormat48bppRGB` | &h10300C | 48 | | extended |
| `PixelFormat64bppARGB` | &h34400D | 64 | yes | canonical, extended |
| `PixelFormat64bppPARGB` | &h1C400E | 64 | yes | premultiplied, extended |

The flags are `PixelFormatIndexed` (&h10000), `PixelFormatGDI` (&h20000), `PixelFormatAlpha`
(&h40000), `PixelFormatPAlpha` (&h80000), `PixelFormatExtended` (&h100000) and
`PixelFormatCanonical` (&h200000); `PixelFormatUndefined` and `PixelFormatDontCare` are 0 and
`PixelFormatMax` is 15. Four macros test a format and one reads its size:

| Macro | Gives |
| --- | --- |
| `GetPixelFormatSize( pixfmt )` | the bits per pixel, as a `UINT` |
| `IsAlphaPixelFormat( pixfmt )` | 1 when the format has alpha, otherwise 0 |
| `IsIndexedPixelFormat( pixfmt )` | 1 when the format uses a palette |
| `IsCanonicalPixelFormat( pixfmt )` | 1 for the formats GDI+ works in natively |
| `IsExtendedPixelFormat( pixfmt )` | 1 for the formats with 16 bits per channel |

```freebasic
print GetPixelFormatSize( PixelFormat24bppRGB ); IsAlphaPixelFormat( PixelFormat32bppARGB )   ' 24 1
```

Microsoft Learn: [Image pixel format constants](https://learn.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-constant-image-pixel-format-constants)

### Constants and GUIDs

| Name | Is |
| --- | --- |
| `ImageFormatBMP`, `ImageFormatEMF`, `ImageFormatEXIF`, `ImageFormatGIF`, `ImageFormatIcon`, `ImageFormatJPEG`, `ImageFormatMemoryBMP`, `ImageFormatPNG`, `ImageFormatTIFF`, `ImageFormatUndefined`, `ImageFormatWMF` | `GUID` variables: the file format of an image, as `CGpImage.GetRawFormat` returns it. |
| `EncoderChrominanceTable`, `EncoderColorDepth`, `EncoderColorSpace`, `EncoderCompression`, `EncoderImageItems`, `EncoderLuminanceTable`, `EncoderQuality`, `EncoderRenderMethod`, `EncoderSaveAsCMYK`, `EncoderSaveFlag`, `EncoderScanMethod`, `EncoderTransformation`, `EncoderVersion` | `GUID` variables: the encoder settings an `EncoderParameter` can carry. |
| `FrameDimensionPage`, `FrameDimensionResolution`, `FrameDimensionTime` | `GUID` variables: the frame dimensions of multi-frame images (pages of a TIFF, frames of a GIF). |
| `BlurEffectGuid`, `SharpenEffectGuid`, `BrightnessContrastEffectGuid`, `HueSaturationLightnessEffectGuid`, `LevelsEffectGuid`, `TintEffectGuid`, `ColorBalanceEffectGuid`, `ColorCurveEffectGuid`, `ColorLUTEffectGuid`, `ColorMatrixEffectGuid`, `RedEyeCorrectionEffectGuid` | `GUID` variables: the GDI+ effects. `ColorBalanceEffectGuid` and `ColorCurveEffectGuid` do not match the GUIDs GDI+ knows, so creating those two effects from them fails with `Win32Error` (7). |
| `FlatnessDefault` | 0.25, the default flatness for flattening curves. |
| `GDIP_EMFPLUS_RECORD_BASE`, `GDIP_EMFPLUSFLAGS_DISPLAY` | &h4000 and 1, for EMF+ records. |
| `PropertyTag…` | The ids of image metadata items (`PropertyTagGpsLatitude`, `PropertyTagExifDTOrig` …), as `PROPID` values. |

## See also

- [sys/win/gdiplus](SysWin-GdiPlus)
- [GDI+ images](SysWin-GdiPlus-Images) for `CGpImage` and `CGpBitmap`
- [CGpGraphics](CGpGraphics)
- [Colours](SysWin-Colors) for the `ARGB_*` constants
- [Bitmaps](SysWin-Bitmaps) for GDI bitmaps and screen capture
- Microsoft Learn: [GDI+ flat API](https://learn.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-flatapi-flat)
