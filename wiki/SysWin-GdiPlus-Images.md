[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gdiplus](SysWin-GdiPlus) › **GDI+ images**

# GDI+ images
Loads, creates, edits and saves images with GDI+: bitmaps, metafiles and cached bitmaps.

<!-- scope: CGpImage -->
<!-- scope: CGpBitmap -->
<!-- scope: CGpCachedBitmap -->
<!-- scope: CGpMetafile -->

Loads, creates, edits and saves images with GDI+: bitmaps, metafiles and cached bitmaps.

Four classes cover images:

| Class | Holds |
| --- | --- |
| [CGpImage](#cgpimage) | Any image GDI+ can read: BMP, GIF, JPEG, PNG, TIFF, ICO, EMF, WMF. The base of the next two, with everything they share: size, format, frames, metadata, saving. |
| [CGpBitmap](#cgpbitmap) | A raster image: one you load, create empty, or make from a GDI bitmap, an icon or pixel memory. You can draw into it, read and write its pixels and apply [effects](SysWin-GdiPlus-Effects). |
| [CGpMetafile](#cgpmetafile) | A vector image, a recording of drawing commands: one you open to play back, or a new one you record into. |
| [CGpCachedBitmap](#cgpcachedbitmap) | A copy of a bitmap in the display's own format, for drawing the same bitmap fast and often. |

To draw an image, pass its address to [CGpGraphics](CGpGraphics) `DrawImage`; to draw *into* a
bitmap or record into a metafile, create a `CGpGraphics` on it: `dim g as CGpGraphics = @bmp`.

**Ownership.** Each object owns one GDI+ image and disposes of it in its destructor. Never copy
an image object with `=` or pass it `byval`: the copy would dispose of the same image a second
time. Pass its address, or make an independent copy with `Clone` or the copy constructor.

**Files and streams stay in use.** GDI+ reads an image lazily, so a file stays open, and cannot be
overwritten, until the image loaded from it is destroyed: saving back over that file fails with
`Win32Error`. Likewise a stream you load from must stay alive as long as the image; the
constructors that read a resource keep their own stream and release it in the destructor.

**Status.** Methods that do something return a `GpStatus`, `Ok` (0) on success, otherwise the
reason. Every method also stores its result, so after a constructor or a getter
`GetLastStatus()` (inherited by every `CGp*` class) says whether it worked. An object made with
the default constructor, or one whose file could not be opened, holds no image: its getters
return 0 and its methods `InvalidParameter`.

**Saving** needs the CLSID of an encoder, which [GetEncoderClsid](SysWin-GdiPlus-Procedures)
looks up by MIME type: `"image/bmp"`, `"image/gif"`, `"image/jpeg"`, `"image/png"`,
`"image/tiff"`.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus
```

## Example

A console program that draws an ellipse into a new bitmap, saves it as PNG, loads the file back,
looks at it, rotates it and saves a JPEG copy:

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus

function main() as long
    ' draw into a new 32-bit bitmap
    dim bmp as CGpBitmap = CGpBitmap( 200, 100 )
    scope
        dim g as CGpGraphics = @bmp
        g.Clear( ARGB_White )
        dim brush as CGpSolidBrush = CGpSolidBrush( ARGB_SteelBlue )
        g.FillEllipse( @brush, 10, 10, 180, 80 )
    end scope

    ' save it as a PNG file
    dim png as GUID = GetEncoderClsid( "image/png" )
    if bmp.Save( "ellipse.png", @png, NULL ) <> Ok then
        print "save failed:"; bmp.GetLastStatus()
        return 1
    end if

    ' load it back and look at it
    dim img as CGpBitmap = "ellipse.png"
    if img.GetLastStatus() <> Ok then return 1
    dim fmt as GUID = img.GetRawFormat()
    print "size "; img.GetWidth(); " x "; img.GetHeight(); iif( IsEqualGuid( @fmt, @ImageFormatPNG ), ", PNG", "" )
    print "corner &h"; hex( img.GetPixel( 0, 0 ) ); ", centre &h"; hex( img.GetPixel( 100, 50 ) )

    ' turn it on its side and save a JPEG copy
    img.RotateFlip( Rotate90FlipNone )
    print "rotated "; img.GetWidth(); " x "; img.GetHeight()
    dim jpg as GUID = GetEncoderClsid( "image/jpeg" )
    if img.Save( "ellipse.jpg", @jpg, NULL ) = Ok then print "saved ellipse.jpg"
    return 0
end function

end main()
```

It prints:

```text
size 200 x 100, PNG
corner &hFFFFFFFF, centre &hFF4682B4
rotated 100 x 200
saved ellipse.jpg
```

The `scope` block destroys the `CGpGraphics` before the bitmap is saved, so every drawing
operation has reached the pixels.

## Members

| Member | Does |
| --- | --- |
| **CGpImage** | |
| [Constructor](#constructor) | Loads an image from a file, a stream or a resource, or copies one. |
| [Destructor](#destructor) | Disposes of the image and releases a resource stream. |
| [Clone](#clone) | Copies the image into another object. |
| [Save](#save) | Saves the image to a file or a stream with an encoder. |
| [SaveAdd](#saveadd) | Adds a frame to a multi-frame file being saved. |
| [GetEncoderParameterListSize, GetEncoderParameterList](#getencoderparameterlistsize-getencoderparameterlist) | List the parameters an encoder accepts. |
| [GetType](#gettype) | Says whether the image is a bitmap or a metafile. |
| [GetWidth, GetHeight](#getwidth-getheight) | Return the size in pixels. |
| [GetPhysicalDimension](#getphysicaldimension) | Returns the size in the image's own unit. |
| [GetBounds](#getbounds) | Returns the bounding rectangle and its unit. |
| [GetHorizontalResolution, GetVerticalResolution](#gethorizontalresolution-getverticalresolution) | Return the resolution in dots per inch. |
| [GetFlags](#getflags) | Returns attributes such as alpha and colour space. |
| [GetRawFormat](#getrawformat) | Returns the GUID of the file format. |
| [GetPixelFormat](#getpixelformat) | Returns the pixel format. |
| [GetPaletteSize](#getpalettesize) | Returns the size of the palette in bytes. |
| [GetPalette, SetPalette](#getpalette-setpalette) | Read or replace the palette. |
| [GetFrameDimensionsCount](#getframedimensionscount) | Returns how many kinds of frame the image has. |
| [GetFrameDimensionsList](#getframedimensionslist) | Returns the GUIDs of those kinds. |
| [GetFrameCount](#getframecount) | Returns the number of frames of one kind. |
| [SelectActiveFrame](#selectactiveframe) | Makes one frame the current one. |
| [RotateFlip](#rotateflip) | Rotates and flips the image in place. |
| [GetThumbnailImage](#getthumbnailimage) | Makes a small copy of the image. |
| [GetPropertyCount](#getpropertycount) | Returns the number of metadata items. |
| [GetPropertyIdList](#getpropertyidlist) | Returns the ids of the metadata items. |
| [GetPropertyItemSize](#getpropertyitemsize) | Returns the size of one metadata item. |
| [GetPropertyItem](#getpropertyitem) | Reads one metadata item. |
| [GetPropertySize](#getpropertysize) | Returns the size and number of all metadata items. |
| [GetAllPropertyItems](#getallpropertyitems) | Reads every metadata item. |
| [SetPropertyItem](#setpropertyitem) | Adds or changes a metadata item. |
| [RemovePropertyItem](#removepropertyitem) | Removes a metadata item. |
| [FindFirstItem, FindNextItem](#findfirstitem-findnextitem) | Walk through the image's metadata blocks. |
| [GetItemData](#getitemdata) | Reads one metadata block. |
| **CGpBitmap** | |
| [Constructor](#constructor-1) | Creates a bitmap: empty, from a file, a stream, memory, a GDI bitmap, an icon or a resource. |
| [GetPixel, SetPixel](#getpixel-setpixel) | Read or write one pixel. |
| [LockBits, UnlockBits](#lockbits-unlockbits) | Give direct access to the pixel memory and take it back. |
| [Clone](#clone-1) | Copies all or part of the bitmap into another object. |
| [GetHBITMAP](#gethbitmap) | Makes a GDI bitmap from the bitmap. |
| [GetHICON](#gethicon) | Makes an icon from the bitmap. |
| [SetResolution](#setresolution) | Sets the resolution stored with the bitmap. |
| [SetResolutionForDpi](#setresolutionfordpi) | Sets it to the resolution of the display. |
| [MakeTransparent](#maketransparent) | Replaces a colour, converting the bitmap to 32-bit ARGB. |
| [ConvertFormat](#convertformat) | Converts the bitmap to another pixel format. |
| [InitializePalette](#initializepalette) | Fills a palette with a standard or an optimal set of colours. |
| [GetHistogramSize](#gethistogramsize) | Returns the number of entries a histogram has. |
| [GetHistogram](#gethistogram) | Counts how often each channel value occurs. |
| [ApplyEffect](#applyeffect) | Changes the pixels with a blur, a tint or another effect. |
| **CGpCachedBitmap** | |
| [Constructor](#constructor-2) | Makes a display-format copy of a bitmap. |
| [Destructor](#destructor-1) | Deletes the copy. |
| **CGpMetafile** | |
| [Constructor](#constructor-3) | Opens a metafile for playback or starts a recording. |
| [GetMetafileHeader](#getmetafileheader) | Reads the header of a metafile. |
| [GetHENHMETAFILE](#gethenhmetafile) | Hands the metafile over as a GDI enhanced metafile handle. |
| [PlayRecord](#playrecord) | Plays one record while a metafile is being enumerated. |
| [GetDownLevelRasterizationLimit, SetDownLevelRasterizationLimit](#getdownlevelrasterizationlimit-setdownlevelrasterizationlimit) | Read or set the resolution brush bitmaps are stored at. |
| [EmfToWmfBits](#emftowmfbits) | Converts an enhanced metafile to the older WMF format. |

## Reference

## CGpImage

The base class. Create a `CGpImage` directly to open any image file, metafiles included, when you
only need to draw, inspect or save it; create a [CGpBitmap](#cgpbitmap) when you also want its
pixels.

The class also declares `FromFile` and `FromStream`, but there is no code behind them: a program
that calls either does not link. Use the constructors.

### Constructor

```freebasic
constructor
constructor( byval pImage as CGpImage ptr )
constructor( byval pwszFileName as wstring ptr, byval useEmbeddedColorManagement as boolean = false )
constructor( byval pStream as IStream ptr, byval useEmbeddedColorManagement as boolean = false )
constructor( byval hInst as HINSTANCE, byref wszImageName as wstring )
```

- With no argument the object holds no image.
- With `pImage` it holds an independent copy of that image.
- With a file name it opens the file. Bitmaps, icons and metafiles are all accepted; the file
  stays open until the object is destroyed.
- With a stream it reads the image from the stream, which must stay alive as long as the object.
- With a module handle and a name it reads an image stored as an `RCDATA` resource of that module
  (`GetModuleHandleW( NULL )` for the program itself). Give a numeric id as `"#"` followed by the
  number, for example `"#101"`. This form does not record a status: when the resource is missing
  `GetLastStatus()` still reads `Ok`, so test `GetWidth()` instead.

| Parameter | Meaning |
| --- | --- |
| `pImage` | The image to copy. |
| `pwszFileName` | The file to open. |
| `pStream` | The stream to read from. |
| `useEmbeddedColorManagement` | `true` to correct colours with a colour profile embedded in the file; `false` (the default) not to. |
| `hInst`, `wszImageName` | The module and the name of the resource. |

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
if img.GetLastStatus() <> Ok then print "cannot open photo.jpg"
dim logo as CGpImage = CGpImage( GetModuleHandleW( NULL ), "#101" )
if logo.GetWidth() = 0 then print "no resource 101"
```

Microsoft Learn: [Image::Image](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-image%28constwchar_bool%29), [Image::Image (stream)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-image%28istream_bool%29)

### Destructor

```freebasic
destructor
```

Disposes of the GDI+ image, which closes the file it was loaded from, and releases the stream a
resource constructor made. A stream you passed to a constructor is yours to release, after the
object is gone. `CGpBitmap` and `CGpMetafile` use this destructor.

**Example**

```freebasic
dim pImg as CGpImage ptr = new CGpImage( "photo.jpg" )
print pImg->GetWidth()
delete pImg                         ' photo.jpg can now be overwritten
```

### Clone

```freebasic
function Clone( byval pImage as CGpImage ptr ) as GpStatus
```

Makes `pImage` hold an independent copy of this image: whatever image it held is disposed of
first. Changing one afterwards does not change the other.

**Returns** `Ok` on success; `InvalidParameter` when `pImage` is `NULL`.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
dim copy as CGpImage
if img.Clone( @copy ) = Ok then copy.RotateFlip( Rotate180FlipNone )
```

Microsoft Learn: [Image::Clone](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-clone)

### Save

```freebasic
function Save( byval pwszFileName as wstring ptr, byval clsidEncoder as GUID ptr, byval encoderParams as EncoderParameters ptr ) as GpStatus
function Save( byval pStream as IStream ptr, byval clsidEncoder as GUID ptr, byval encoderParams as EncoderParameters ptr ) as GpStatus
```

Encodes the image with the encoder `clsidEncoder` and writes it to a file, replacing any file of
that name, or to a stream. The format is the encoder's, whatever the file name's extension says.
A file the image was loaded from cannot be the target (`Win32Error`); save to another name.

| Parameter | Meaning |
| --- | --- |
| `pwszFileName`, `pStream` | Where to write. |
| `clsidEncoder` | The encoder, from `GetEncoderClsid( "image/png" )` and the like. |
| `encoderParams` | Encoder options such as JPEG quality, or `NULL` for the encoder's defaults. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpImage = "photo.png"
dim jpg as GUID = GetEncoderClsid( "image/jpeg" )
dim quality as ULONG = 50
dim ep as EncoderParameters
ep.Count = 1
ep.Parameter(0).Guid = EncoderQuality
ep.Parameter(0).Type = EncoderParameterValueTypeLong
ep.Parameter(0).NumberOfValues = 1
ep.Parameter(0).Value = @quality
img.Save( "photo-50.jpg", @jpg, @ep )
```

Microsoft Learn: [Image::Save (file)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-save%28constwchar_constclsid_constencoderparameters%29), [Image::Save (stream)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-save%28istream_constclsid_constencoderparameters%29)

### SaveAdd

```freebasic
function SaveAdd( byval encoderParams as EncoderParameters ptr ) as GpStatus
function SaveAdd( byval pNewImage as CGpImage ptr, byval encoderParams as EncoderParameters ptr ) as GpStatus
```

Builds a multi-frame file (a TIFF with several pages). Start with [Save](#save) and the encoder
parameter `EncoderSaveFlag` set to `EncoderValueMultiFrame`; then call `SaveAdd` with an image
and `EncoderValueFrameDimensionPage` for each further page; finally call `SaveAdd` with only the
parameters and `EncoderValueFlush` to close the file.

| Parameter | Meaning |
| --- | --- |
| `pNewImage` | The image to add as the next frame. |
| `encoderParams` | An `EncoderSaveFlag` parameter with the value for this step. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim page1 as CGpBitmap = CGpBitmap( 100, 100 ), page2 as CGpBitmap = CGpBitmap( 100, 100 )
dim tif as GUID = GetEncoderClsid( "image/tiff" )
dim flag as ULONG, ep as EncoderParameters
ep.Count = 1 : ep.Parameter(0).Guid = EncoderSaveFlag
ep.Parameter(0).Type = EncoderParameterValueTypeLong : ep.Parameter(0).NumberOfValues = 1 : ep.Parameter(0).Value = @flag
flag = EncoderValueMultiFrame        : page1.Save( "pages.tif", @tif, @ep )
flag = EncoderValueFrameDimensionPage : page1.SaveAdd( @page2, @ep )
flag = EncoderValueFlush             : page1.SaveAdd( @ep )
```

Microsoft Learn: [Image::SaveAdd](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-saveadd%28image_constencoderparameters%29), [Image::SaveAdd (flush)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-saveadd%28constencoderparameters%29)

### GetEncoderParameterListSize, GetEncoderParameterList

```freebasic
function GetEncoderParameterListSize( byval clsidEncoder as GUID ptr ) as UINT
function GetEncoderParameterList( byval clsidEncoder as GUID ptr, byval uSize as UINT, byval buffer as EncoderParameters ptr ) as GpStatus
```

Find out which options an encoder accepts. `GetEncoderParameterListSize` returns the size in
bytes of the list; allocate that much and pass it to `GetEncoderParameterList`, which fills it
with an `EncoderParameters` structure: `Count`, then `Count` entries whose `Guid` names an option
(`EncoderQuality`, `EncoderCompression` …).

**Returns** the size in bytes (0 on failure), or `Ok` and the filled buffer.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
dim jpg as GUID = GetEncoderClsid( "image/jpeg" )
dim size as UINT = img.GetEncoderParameterListSize( @jpg )
dim list as EncoderParameters ptr = callocate( size )
if img.GetEncoderParameterList( @jpg, size, list ) = Ok then print list->Count; " options"
deallocate( list )
```

Microsoft Learn: [Image::GetEncoderParameterListSize](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getencoderparameterlistsize), [Image::GetEncoderParameterList](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getencoderparameterlist)

### GetType

```freebasic
function GetType() as ImageType
```

**Returns** `ImageTypeBitmap` (1) or `ImageTypeMetafile` (2); `ImageTypeUnknown` (0) when the
object holds no image.

**Example**

```freebasic
dim img as CGpImage = "drawing.emf"
if img.GetType() = ImageTypeMetafile then print "a vector image"
```

Microsoft Learn: [Image::GetType](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-gettype)

### GetWidth, GetHeight

```freebasic
function GetWidth() as UINT
function GetHeight() as UINT
```

Return the width and the height of the image in pixels. For a metafile they are the size of its
frame at its own resolution.

**Returns** the size, or 0 when the object holds no image.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
print img.GetWidth(); " x "; img.GetHeight()
```

Microsoft Learn: [Image::GetWidth](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getwidth), [Image::GetHeight](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getheight)

### GetPhysicalDimension

```freebasic
function GetPhysicalDimension( byval psize as GpSizeF ptr ) as GpStatus
function GetPhysicalDimension() as GpSizeF
```

Returns the width and height of the image in its own unit: pixels for a bitmap, hundredths of a
millimetre for a metafile. The first form writes them into `psize` and returns the status; the
second returns them.

**Returns** the size, or `Ok` and the filled `GpSizeF`.

**Example**

```freebasic
dim img as CGpImage = "drawing.emf"
dim size as GpSizeF = img.GetPhysicalDimension()
print size.Width / 100; " mm wide"
```

Microsoft Learn: [Image::GetPhysicalDimension](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getphysicaldimension)

### GetBounds

```freebasic
function GetBounds( byval srcRect as GpRectF ptr, byval srcUnit as GpUnit ptr ) as GpStatus
```

Writes the image's bounding rectangle into `srcRect` and its unit into `srcUnit`. For a bitmap
the rectangle is (0, 0, width, height) in `UnitPixel`; a metafile's frame can start at a
negative position.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 4, 3 )
dim rc as GpRectF, unit as GpUnit
bmp.GetBounds( @rc, @unit )         ' 0 0 4 3, UnitPixel
```

Microsoft Learn: [Image::GetBounds](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getbounds)

### GetHorizontalResolution, GetVerticalResolution

```freebasic
function GetHorizontalResolution() as single
function GetVerticalResolution() as single
```

Return the resolution stored with the image, in dots per inch. A new bitmap has 96; a file has
whatever it was saved with. The resolution decides how large `DrawImage` draws the image when no
size is given.

**Returns** the resolution, or 0 when the object holds no image.

**Example**

```freebasic
dim img as CGpImage = "scan.tif"
print img.GetHorizontalResolution(); " x"; img.GetVerticalResolution(); " dpi"
```

Microsoft Learn: [Image::GetHorizontalResolution](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-gethorizontalresolution), [Image::GetVerticalResolution](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getverticalresolution)

### GetFlags

```freebasic
function GetFlags() as UINT
```

**Returns** a combination of `ImageFlags` values: `ImageFlagsHasAlpha` when there is an alpha
channel, `ImageFlagsColorSpaceRGB`, `ImageFlagsColorSpaceCMYK` and the like for the colour
space, `ImageFlagsReadOnly` for an image loaded from a file, `ImageFlagsHasRealDPI` when the file
stores its resolution. A new 32-bit bitmap gives `ImageFlagsHasAlpha` (2).

**Example**

```freebasic
dim img as CGpImage = "logo.png"
if img.GetFlags() and ImageFlagsHasAlpha then print "has transparency"
```

Microsoft Learn: [Image::GetFlags](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getflags)

### GetRawFormat

```freebasic
function GetRawFormat( byval guidformat as GUID ptr ) as GpStatus
function GetRawFormat() as GUID
```

Returns the GUID of the format the image was read from: `ImageFormatBMP`, `ImageFormatGIF`,
`ImageFormatJPEG`, `ImageFormatPNG`, `ImageFormatTIFF`, `ImageFormatIcon`, `ImageFormatEMF`,
`ImageFormatWMF`. Compare with `IsEqualGuid`. The first form writes it into `guidformat` and
returns the status.

A bitmap created in memory, from an icon or from a GDI bitmap reports the memory-bitmap format
(`b96b3caa-…`). In this release that GUID is the value of `ImageFormatUndefined`, and
`ImageFormatMemoryBMP` holds another one, so test such a bitmap against `ImageFormatUndefined`.

**Returns** the GUID, or `Ok` and the filled GUID.

**Example**

```freebasic
dim img as CGpImage = "picture.dat"
dim fmt as GUID = img.GetRawFormat()
if IsEqualGuid( @fmt, @ImageFormatJPEG ) then print "a JPEG, whatever the name says"
```

Microsoft Learn: [Image::GetRawFormat](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getrawformat)

### GetPixelFormat

```freebasic
function GetPixelFormat() as PixelFormat
```

**Returns** the pixel format: `PixelFormat24bppRGB`, `PixelFormat32bppARGB`,
`PixelFormat32bppPARGB`, `PixelFormat8bppIndexed` and so on. A PNG with transparency loads as
`PixelFormat32bppARGB`, a JPEG as `PixelFormat24bppRGB`.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
if img.GetPixelFormat() = PixelFormat24bppRGB then print "24-bit, no alpha"
```

Microsoft Learn: [Image::GetPixelFormat](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getpixelformat)

### GetPaletteSize

```freebasic
function GetPaletteSize() as INT_
```

Returns how many bytes a `ColorPalette` holding this image's palette needs: 8 bytes of header
plus 4 per colour, so 1032 for an 8-bit indexed image with 256 colours. Allocate that much for
[GetPalette](#getpalette-setpalette).

**Returns** the size in bytes.

**Example**

```freebasic
dim gif as CGpImage = "anim.gif"
print gif.GetPaletteSize(); " bytes of palette"
```

Microsoft Learn: [Image::GetPaletteSize](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getpalettesize)

### GetPalette, SetPalette

```freebasic
function GetPalette( byval pal as ColorPalette ptr, byval nSize as INT_ ) as GpStatus
function SetPalette( byval pal as ColorPalette ptr ) as GpStatus
```

`GetPalette` copies the image's palette into `pal`, a buffer of `nSize` bytes (see
[GetPaletteSize](#getpalettesize)). A `ColorPalette` has `Flags`, `Count` and `Count` colours in
`Entries`. `SetPalette` replaces the palette with the one in `pal`; for an indexed image this
changes how every pixel looks.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16, PixelFormat8bppIndexed )
dim size as long = bmp.GetPaletteSize()
dim pal as ColorPalette ptr = callocate( size )
bmp.GetPalette( pal, size )
pal->Entries(0) = ARGB_Navy         ' index 0 is now navy blue
bmp.SetPalette( pal )
deallocate( pal )
```

Microsoft Learn: [Image::GetPalette](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getpalette), [Image::SetPalette](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-setpalette)

### GetFrameDimensionsCount

```freebasic
function GetFrameDimensionsCount() as UINT
```

Images can hold several frames: the pages of a TIFF (`FrameDimensionPage`), the frames of an
animated GIF (`FrameDimensionTime`), an image stored at several resolutions
(`FrameDimensionResolution`). This
returns how many such dimensions the image has; a single-frame image has one.

**Returns** the number of frame dimensions.

**Example**

```freebasic
dim img as CGpImage = "pages.tif"
print img.GetFrameDimensionsCount()
```

Microsoft Learn: [Image::GetFrameDimensionsCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getframedimensionscount)

### GetFrameDimensionsList

```freebasic
function GetFrameDimensionsList( byval dimensionIDs as GUID ptr, byval nCount as UINT ) as GpStatus
```

Writes the GUIDs of the image's frame dimensions into an array of `nCount` GUIDs.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpImage = "anim.gif"
dim dimension as GUID
img.GetFrameDimensionsList( @dimension, 1 )
print img.GetFrameCount( @dimension ); " frames"
```

Microsoft Learn: [Image::GetFrameDimensionsList](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getframedimensionslist)

### GetFrameCount

```freebasic
function GetFrameCount( byval dimensionID as GUID ptr ) as UINT
```

**Returns** the number of frames in the dimension `dimensionID`: pages of a TIFF, frames of an
animated GIF. A single-frame image returns 1 for its dimension.

**Example**

```freebasic
dim img as CGpImage = "pages.tif"
dim pageDim as GUID = FrameDimensionPage
print img.GetFrameCount( @pageDim ); " pages"
```

Microsoft Learn: [Image::GetFrameCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getframecount)

### SelectActiveFrame

```freebasic
function SelectActiveFrame( byval dimensionID as GUID ptr, byval frameIndex as UINT ) as GpStatus
```

Makes frame `frameIndex` (0 is the first) of dimension `dimensionID` the current one. Size,
pixels, drawing and saving then all refer to that frame.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpImage = "pages.tif"
dim pageDim as GUID = FrameDimensionPage
if img.SelectActiveFrame( @pageDim, 1 ) = Ok then print "page 2 is"; img.GetWidth(); " wide"
```

Microsoft Learn: [Image::SelectActiveFrame](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-selectactiveframe)

### RotateFlip

```freebasic
function RotateFlip( byval rotateFlipType as RotateFlipType ) as GpStatus
```

Rotates the image clockwise by 90, 180 or 270 degrees and/or flips it, in place. The names say
both parts: `Rotate90FlipNone`, `RotateNoneFlipX` (mirror left to right), `Rotate180FlipY` and so
on. A 90 or 270 degree turn swaps width and height.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpBitmap = "photo.jpg"
img.RotateFlip( RotateNoneFlipX )   ' mirror image
```

Microsoft Learn: [Image::RotateFlip](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-rotateflip)

### GetThumbnailImage

```freebasic
function GetThumbnailImage( byval thumbWidth as UINT, byval thumbHeight as UINT, byval pThumbnail as CGpImage ptr, byval pCallback as any ptr = NULL, byval callbackData as any ptr = NULL ) as GpStatus
```

Makes a `thumbWidth` × `thumbHeight` copy of the image and puts it in `pThumbnail`, disposing of
whatever image that object held. If the file has a thumbnail of its own (many JPEGs do), GDI+
scales that one; otherwise it scales the image. The size is used as given, so work out the
height from the aspect ratio yourself. `pThumbnail` must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `thumbWidth`, `thumbHeight` | The size of the thumbnail in pixels. |
| `pThumbnail` | The object that receives it. |
| `pCallback`, `callbackData` | An optional `GetThumbnailImageAbort` callback and the data passed to it; `NULL` for none. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
dim thumb as CGpImage
img.GetThumbnailImage( 96, 96 * img.GetHeight() \ img.GetWidth(), @thumb )
```

Microsoft Learn: [Image::GetThumbnailImage](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getthumbnailimage)

### GetPropertyCount

```freebasic
function GetPropertyCount() as UINT
```

**Returns** the number of metadata items (EXIF and other property items: camera, date, image
description …) stored in the image; 0 for a new bitmap.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
print img.GetPropertyCount(); " metadata items"
```

Microsoft Learn: [Image::GetPropertyCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getpropertycount)

### GetPropertyIdList

```freebasic
function GetPropertyIdList( byval numOfProperty as UINT, byval list as PROPID ptr ) as GpStatus
```

Writes the ids of the image's metadata items into an array of `numOfProperty` `PROPID`s (use
[GetPropertyCount](#getpropertycount) for the size). The ids are the `PropertyTag…` constants,
such as `PropertyTagImageDescription` or `PropertyTagEquipMake`.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
dim n as UINT = img.GetPropertyCount()
if n then
    dim ids( n - 1 ) as PROPID
    img.GetPropertyIdList( n, @ids(0) )
    print "first id: &h"; hex( ids(0) )
end if
```

Microsoft Learn: [Image::GetPropertyIdList](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getpropertyidlist)

### GetPropertyItemSize

```freebasic
function GetPropertyItemSize( byval propId as PROPID ) as UINT
```

**Returns** the number of bytes [GetPropertyItem](#getpropertyitem) needs for the item `propId`:
the `PropertyItem` header and the value that follows it. 0 when the image has no such item
(`GetLastStatus()` is then `PropertyNotFound`).

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
print img.GetPropertyItemSize( PropertyTagEquipMake ); " bytes"
```

Microsoft Learn: [Image::GetPropertyItemSize](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getpropertyitemsize)

### GetPropertyItem

```freebasic
function GetPropertyItem( byval propId as PROPID, byval propSize as UINT, byval buffer as PropertyItem ptr ) as GpStatus
```

Copies the metadata item `propId` into `buffer`, which must be `propSize` bytes, the size
[GetPropertyItemSize](#getpropertyitemsize) gave. The `PropertyItem` at the start holds `id`,
`length` (of the value in bytes), `type` (`PropertyTagTypeASCII`, `PropertyTagTypeShort` …) and
`value`, a pointer into the same buffer.

**Returns** `Ok` on success; `PropertyNotFound` when the image has no such item.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
dim size as UINT = img.GetPropertyItemSize( PropertyTagEquipMake )
if size then
    dim item as PropertyItem ptr = callocate( size )
    if img.GetPropertyItem( PropertyTagEquipMake, size, item ) = Ok then print "camera: "; *cast( zstring ptr, item->value )
    deallocate( item )
end if
```

Microsoft Learn: [Image::GetPropertyItem](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getpropertyitem)

### GetPropertySize

```freebasic
function GetPropertySize( byval totalBufferSize as UINT ptr, byval numProperties as UINT ptr ) as GpStatus
```

Writes into `totalBufferSize` the number of bytes [GetAllPropertyItems](#getallpropertyitems)
needs and into `numProperties` the number of items.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
dim as UINT total, count
img.GetPropertySize( @total, @count )
print count; " items in"; total; " bytes"
```

Microsoft Learn: [Image::GetPropertySize](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getpropertysize)

### GetAllPropertyItems

```freebasic
function GetAllPropertyItems( byval totalBufferSize as UINT, byval numProperties as UINT, byval allItems as PropertyItem ptr ) as GpStatus
```

Copies every metadata item into one buffer of `totalBufferSize` bytes: an array of
`numProperties` `PropertyItem` headers, followed by the values they point to. Take both numbers
from [GetPropertySize](#getpropertysize).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpImage = "photo.jpg"
dim as UINT total, count
img.GetPropertySize( @total, @count )
dim items as PropertyItem ptr = callocate( total )
if img.GetAllPropertyItems( total, count, items ) = Ok then
    for i as long = 0 to count - 1
        print hex( items[i].id ), items[i].length
    next
end if
deallocate( items )
```

Microsoft Learn: [Image::GetAllPropertyItems](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getallpropertyitems)

### SetPropertyItem

```freebasic
function SetPropertyItem( byval pitem as PropertyItem ptr ) as GpStatus
```

Adds the metadata item `pitem` to the image, or replaces the item with the same `id`. GDI+ copies
the value. The item is written to the file the next time the image is saved, by encoders that
store metadata (JPEG, TIFF).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpBitmap = "photo.jpg"
dim text as zstring * 8 = "Holiday"
dim item as PropertyItem
item.id = PropertyTagImageDescription : item.type = PropertyTagTypeASCII
item.length = len( text ) + 1 : item.value = @text
img.SetPropertyItem( @item )
```

Microsoft Learn: [Image::SetPropertyItem](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-setpropertyitem)

### RemovePropertyItem

```freebasic
function RemovePropertyItem( byval propId as PROPID ) as GpStatus
```

Removes the metadata item `propId` from the image.

**Returns** `Ok` on success; `PropertyNotFound` (19) when the image has no such item.

**Example**

```freebasic
dim img as CGpBitmap = "photo.jpg"
img.RemovePropertyItem( PropertyTagGpsLatitude )
img.RemovePropertyItem( PropertyTagGpsLongitude )
```

Microsoft Learn: [Image::RemovePropertyItem](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-removepropertyitem)

### FindFirstItem, FindNextItem

```freebasic
function FindFirstItem( byval pitem as ImageItemData ptr ) as GpStatus
function FindNextItem( byval pitem as ImageItemData ptr ) as GpStatus
```

Walk through the raw metadata blocks of an image (blocks that are not property items, such as
comments): `FindFirstItem` fills `pitem` with the description and size of the first block,
`FindNextItem` with the next one. Read a block's data with [GetItemData](#getitemdata). Few
formats support this: for a JPEG, `FindFirstItem` returns `NotImplemented`.

**Returns** `Ok` while there is an item, otherwise the reason.

**Example**

```freebasic
dim img as CGpImage = "photo.gif"
dim item as ImageItemData
if img.FindFirstItem( @item ) = Ok then
    do
        print "block of"; item.DataSize; " bytes"
    loop while img.FindNextItem( @item ) = Ok
end if
```

Microsoft Learn: [Image::FindFirstItem](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-findfirstitem), [Image::FindNextItem](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-findnextitem)

### GetItemData

```freebasic
function GetItemData( byval pitem as ImageItemData ptr ) as GpStatus
```

Copies the data of the metadata block described by `pitem` (from
[FindFirstItem, FindNextItem](#findfirstitem-findnextitem)) into the buffer its `Data` field
points to, which must hold `DataSize` bytes.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim img as CGpImage = "photo.gif"
dim item as ImageItemData
if img.FindFirstItem( @item ) = Ok then
    item.Data = callocate( item.DataSize )
    img.GetItemData( @item )
    deallocate( item.Data )
end if
```

Microsoft Learn: [Image::GetItemData](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-getitemdata)

## CGpBitmap

A raster image, derived from [CGpImage](#cgpimage): everything above works on a `CGpBitmap` too.
Pixels are `ARGB` values, `&hAARRGGBB`, whatever the pixel format they are stored in.

### Constructor

```freebasic
constructor
constructor( byval pBitmap as CGpBitmap ptr )
constructor( byval pwszFileName as wstring ptr, byval useEmbeddedColorManagement as boolean = false )
constructor( byval pStream as IStream ptr, byval useEmbeddedColorManagement as boolean = false )
constructor( byval nWidth as INT_, byval nHeight as INT_, byval stride as INT_, byval pxFormat as PixelFormat, byval scan0 as ubyte ptr )
constructor( byval nWidth as INT_, byval nHeight as INT_, byval pxFormat as PixelFormat = PixelFormat32bppPARGB )
constructor( byval nWidth as INT_, byval nHeight as INT_, byval pTarget as CGpGraphics_ ptr )
constructor( byval gdiBitmapInfo as BITMAPINFO ptr, byval gdiBitmapData as any ptr )
constructor( byval hbm as HBITMAP, byval hPal as HPALETTE = NULL )
constructor( byval hicon as HICON )
constructor( byval hInstance as HINSTANCE, byref wszbitmapName as wstring )
constructor( byval surface as IDirectDrawSurface7 ptr )
```

- No argument: no bitmap.
- `pBitmap`: an independent copy of that bitmap.
- A file name or a stream: the image in it, as a bitmap. A metafile is rendered to pixels at its
  own size. The file or stream stays in use as with [CGpImage](#constructor).
- Width, height, `stride`, format and `scan0`: a bitmap over pixel memory you own. GDI+ draws
  into that memory directly and does not copy it, so it must outlive the bitmap. `stride` is the
  number of bytes from one row to the next, a multiple of 4.
- Width, height and a format: a new bitmap, every pixel transparent black (0). The default
  format, `PixelFormat32bppPARGB`, is the fastest to draw.
- Width, height and a [CGpGraphics](CGpGraphics): a new 32-bit bitmap with the resolution of that
  surface.
- `BITMAPINFO` and pixel data: a copy of a device-independent bitmap, bottom-up rows included.
- `HBITMAP` and an optional palette: a copy of a GDI bitmap. A 32-bit GDI bitmap becomes
  `PixelFormat32bppRGB`: its alpha bytes are ignored. The `HBITMAP` stays yours to delete.
- `HICON`: a 32-bit ARGB copy of the icon, transparency included. The icon stays yours.
- A module handle and a name: an image stored as an `RCDATA` resource, as with
  [CGpImage](#constructor), and again without a status: test `GetWidth()`.
- An `IDirectDrawSurface7`: a bitmap over a DirectDraw surface, which it keeps a reference to.

| Parameter | Meaning |
| --- | --- |
| `pBitmap` | The bitmap to copy. |
| `pwszFileName`, `pStream`, `useEmbeddedColorManagement` | As for [CGpImage](#constructor). |
| `nWidth`, `nHeight` | The size in pixels. |
| `stride`, `scan0` | The row length in bytes and the first byte of the pixel memory. |
| `pxFormat` | A `PixelFormat…` constant. |
| `pTarget` | The surface whose resolution the bitmap takes. |
| `gdiBitmapInfo`, `gdiBitmapData` | The DIB header and its pixels. |
| `hbm`, `hPal` | The GDI bitmap and, for palette bitmaps, its palette. |
| `hicon` | The icon. |
| `hInstance`, `wszbitmapName` | The module and the resource name, or `"#"` and a number. |
| `surface` | The DirectDraw surface. |

**Example**

```freebasic
dim canvas as CGpBitmap = CGpBitmap( 320, 200 )                   ' 32bppPARGB, transparent
dim photo as CGpBitmap = "photo.jpg"
dim hIcon as HICON = LoadIconW( NULL, cast( LPCWSTR, IDI_INFORMATION ) )
dim fromIcon as CGpBitmap = CGpBitmap( hIcon )
dim px(3) as ulong = { &hFFFF0000, &hFF00FF00, &hFF0000FF, &hFFFFFFFF }
dim fromMemory as CGpBitmap = CGpBitmap( 2, 2, 8, PixelFormat32bppARGB, cast( ubyte ptr, @px(0) ) )
```

Microsoft Learn: [Bitmap::Bitmap (file)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-bitmap%28constwchar_bool%29), [Bitmap::Bitmap (size)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-bitmap%28int_int_pixelformat%29), [Bitmap::Bitmap (memory)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-bitmap%28int_int_int_pixelformat_byte%29), [Bitmap::Bitmap (HBITMAP)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-bitmap%28hbitmap_hpalette%29), [Bitmap::Bitmap (HICON)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-bitmap%28hicon%29)

### GetPixel, SetPixel

```freebasic
function GetPixel( byval x as long, byval y as long, byval colour as ARGB ptr ) as GpStatus
function GetPixel( byval x as long, byval y as long ) as ARGB
function SetPixel( byval x as long, byval y as long, byval colour as ARGB ) as GpStatus
```

`GetPixel` reads the colour of the pixel at (`x`, `y`), 0-based from the top-left corner; the
first form writes it into `colour` and returns the status, the second returns it. `SetPixel`
writes one. Outside the bitmap both fail with `InvalidParameter` and the second `GetPixel` returns
0. For more than a few pixels, [LockBits](#lockbits-unlockbits) is much faster.

**Returns** the colour, or the status.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 4, 3 )
bmp.SetPixel( 1, 1, ARGB_Red )
print hex( bmp.GetPixel( 1, 1 ) )   ' FFFF0000
```

Microsoft Learn: [Bitmap::GetPixel](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-getpixel), [Bitmap::SetPixel](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-setpixel)

### LockBits, UnlockBits

```freebasic
function LockBits( byval rc as GpRect ptr, byval flags as UINT, byval pxFormat as PixelFormat, byval lockedBitmapData as BitmapData ptr ) as GpStatus
function LockBits( byval rc as GpRect ptr, byval flags as UINT, byval pxFormat as PixelFormat ) as BitmapData
function UnlockBits( byval lockedBitmapData as BitmapData ptr ) as GpStatus
```

`LockBits` gives direct access to the pixels of rectangle `rc`, converted to `pxFormat` if the
bitmap stores another format. The `BitmapData` it fills (first form) or returns (second form) has
`Width`, `Height`, `Stride` (bytes from one row to the next) and `Scan0` (the first byte).
`UnlockBits` ends the access and, when the lock allowed writing, copies what you wrote back into
the bitmap. Lock, work and unlock without drawing on the bitmap in between.

| Parameter | Meaning |
| --- | --- |
| `rc` | The rectangle to lock, or `NULL` for the whole bitmap. |
| `flags` | `ImageLockModeRead`, `ImageLockModeWrite` or both (`or`); add `ImageLockModeUserInputBuf` to supply the buffer yourself in `Scan0`. |
| `pxFormat` | The format you want to see the pixels in, such as `PixelFormat32bppARGB`. |
| `lockedBitmapData` | Receives the description (first form); pass the same structure to `UnlockBits`. |

**Returns** `Ok` on success, otherwise the error; the second form returns the `BitmapData` and
stores the status.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 64, 64, PixelFormat32bppARGB )
dim rc as GpRect = ( 0, 0, 64, 64 )
dim bd as BitmapData = bmp.LockBits( @rc, ImageLockModeWrite, PixelFormat32bppARGB )
for y as long = 0 to 63
    dim row as ulong ptr = cast( ulong ptr, cast( ubyte ptr, bd.Scan0 ) + y * bd.Stride )
    for x as long = 0 to 63 : row[x] = &hFF000000 or ( x * 4 ) shl 16 or ( y * 4 ) : next
next
bmp.UnlockBits( @bd )
```

Microsoft Learn: [Bitmap::LockBits](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-lockbits), [Bitmap::UnlockBits](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-unlockbits)

### Clone

```freebasic
function Clone( byval pCloneBitmap as CGpBitmap ptr ) as GpStatus
function Clone( byval x as single, byval y as single, byval nWidth as single, byval nHeight as single, byval pxFormat as PixelFormat, byval pCloneBitmap as CGpBitmap ptr ) as GpStatus
function Clone( byval x as single, byval y as single, byval nWidth as single, byval nHeight as single, byval pxFormat as PixelFormat ) as CGpBitmap
function Clone( byval rcf as GpRectF ptr, byval pxFormat as PixelFormat, byval pCloneBitmap as CGpBitmap ptr ) as GpStatus
function Clone( byval rc as GpRect ptr, byval pxFormat as PixelFormat, byval pCloneBitmap as CGpBitmap ptr ) as GpStatus
```

Makes `pCloneBitmap` hold an independent copy of the whole bitmap (first form) or of a rectangle
of it converted to `pxFormat`, disposing of whatever image it held first. The third form, which
would return the copy, is declared but has no code behind it: a program that calls it does not
link. Use one of the forms that take `pCloneBitmap`.

| Parameter | Meaning |
| --- | --- |
| `x`, `y`, `nWidth`, `nHeight`, `rcf`, `rc` | The rectangle to copy, in pixels. |
| `pxFormat` | The pixel format of the copy. |
| `pCloneBitmap` | The object that receives the copy. |

**Returns** `Ok` on success; `InvalidParameter` when `pCloneBitmap` is `NULL`; an error such
as `OutOfMemory` when the rectangle reaches outside the bitmap.

**Example**

```freebasic
dim photo as CGpBitmap = "photo.jpg"
dim face as CGpBitmap
dim rc as GpRect = ( 40, 30, 120, 120 )
photo.Clone( @rc, PixelFormat24bppRGB, @face )
```

Microsoft Learn: [Bitmap::Clone](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-clone%28constrect__pixelformat%29)

### GetHBITMAP

```freebasic
function GetHBITMAP( byval colorBackground as ARGB, byval hbmReturn as HBITMAP ptr ) as GpStatus
function GetHBITMAP( byval colorBackground as ARGB ) as HBITMAP
```

Creates a GDI bitmap (a 32-bit DIB section) with the bitmap's pixels, blended onto
`colorBackground` where they are transparent: a fully transparent pixel comes out as the
background colour. The first form writes the handle into `hbmReturn` and returns the status; the
second returns the handle. Delete it with `DeleteObject` when done.

**Returns** the handle (`NULL` on failure), or the status.

**Example**

```freebasic
dim logo as CGpBitmap = "logo.png"
dim hbm as HBITMAP = logo.GetHBITMAP( ARGB_White )
' ... select it into a DC, put it on a button ...
DeleteObject( hbm )
```

Microsoft Learn: [Bitmap::GetHBITMAP](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-gethbitmap)

### GetHICON

```freebasic
function GetHICON( byval hiconReturn as HICON ptr ) as GpStatus
function GetHICON() as HICON
```

Creates an icon from the bitmap, transparency included. The first form writes the handle into
`hiconReturn` and returns the status; the second returns the handle. Destroy it with
`DestroyIcon` when done.

**Returns** the handle (`NULL` on failure), or the status.

**Example**

```freebasic
dim png as CGpBitmap = "app32.png"
dim hIcon as HICON = png.GetHICON()
SendMessageW( hwnd, WM_SETICON, ICON_SMALL, cast( LPARAM, hIcon ) )
```

Microsoft Learn: [Bitmap::GetHICON](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-gethicon)

### SetResolution

```freebasic
function SetResolution( byval xdpi as single, byval ydpi as single ) as GpStatus
```

Sets the resolution stored with the bitmap, in dots per inch. The pixels do not change, but
`DrawImage` without a size draws the bitmap at `width / xdpi` inches, and the value is saved with
the file.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 300, 300 )
bmp.SetResolution( 300, 300 )       ' one inch square when printed
```

Microsoft Learn: [Bitmap::SetResolution](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-setresolution)

### SetResolutionForDpi

```freebasic
function SetResolutionForDpi() as GpStatus
```

Sets the bitmap's resolution to that of the desktop (`LOGPIXELSX`, `LOGPIXELSY`), so that drawing
it without a size gives one bitmap pixel per screen pixel. In a program that is not DPI-aware
Windows reports 96.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = "toolbar.png"
bmp.SetResolutionForDpi()
```

### MakeTransparent

```freebasic
function MakeTransparent( byval transparentColor as ARGB ) as GpStatus
function MakeTransparent() as GpStatus
```

Redraws the bitmap as `PixelFormat32bppARGB` with the pixels of `transparentColor` left out.
In this release the left-out pixels are not transparent: the new bitmap is filled with opaque
light grey (`ARGB_LightGray`, `&hFFD3D3D3`) first, so they come out light grey. The second form
takes the colour of the bottom-left pixel; when that pixel already has some transparency it
changes nothing and returns `Ok`.

An image read from an `.ico` file is refused with `NotImplemented` (6).

For real transparency, draw the bitmap through a colour key instead:
[CGpImageAttributes.SetColorKey](CGpImageAttributes#setcolorkey-clearcolorkey).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim sprite as CGpBitmap = "sprite.bmp"
sprite.MakeTransparent( ARGB_Magenta )      ' magenta pixels become &hFFD3D3D3
```

### ConvertFormat

```freebasic
function ConvertFormat( byval pxFormat as PixelFormat, byval nDitherType as DitherType, byval nPaletteType as PaletteType, byval colourPalette as ColorPalette ptr, byval alphaThresholdPercent as single ) as GpStatus
```

Converts the bitmap's pixels to another format, in place. Converting to an indexed format needs
a palette and usually dithering.

| Parameter | Meaning |
| --- | --- |
| `pxFormat` | The new pixel format. |
| `nDitherType` | `DitherTypeNone`, `DitherTypeSolid`, `DitherTypeOrdered8x8`, `DitherTypeErrorDiffusion` …; `DitherTypeNone` when not converting to fewer colours. |
| `nPaletteType` | The kind of palette for an indexed format: `PaletteTypeCustom`, `PaletteTypeOptimal`, `PaletteTypeFixedHalftone256` …. |
| `colourPalette` | The palette for an indexed format (see [InitializePalette](#initializepalette)), or `NULL`. |
| `alphaThresholdPercent` | For a format without alpha but with a transparent palette entry: pixels less opaque than this percentage become that entry. 0 for none. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 100, 100, PixelFormat32bppARGB )
bmp.ConvertFormat( PixelFormat24bppRGB, DitherTypeNone, PaletteTypeCustom, NULL, 0 )
```

Microsoft Learn: [Bitmap::ConvertFormat](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-convertformat)

### InitializePalette

```freebasic
function InitializePalette( byval colourPalette as ColorPalette ptr, byval nPaletteType as PaletteType, byval optimalColors as INT_, byval useTransparentColor as BOOL, byval pBitmap as CGpBitmap ptr ) as GpStatus
```

Fills `colourPalette` with a standard palette or with the colours that best represent a bitmap.
It does not change any bitmap; pass the palette to [ConvertFormat](#convertformat) or
[SetPalette](#getpalette-setpalette). Allocate the palette for the number of entries you want and
set its `Count` first: with `Count` 0 the call fails.

`pBitmap` is read even for a fixed palette and must point to a bitmap: with `NULL` the program
stops. Any bitmap will do when `nPaletteType` is not `PaletteTypeOptimal`.

| Parameter | Meaning |
| --- | --- |
| `colourPalette` | The palette to fill; `Count` is the number of entries. |
| `nPaletteType` | `PaletteTypeOptimal` for the best colours of `pBitmap`, or a fixed palette such as `PaletteTypeFixedHalftone256`. |
| `optimalColors` | With `PaletteTypeOptimal`, how many colours to choose. |
| `useTransparentColor` | `TRUE` to keep one entry for transparency. |
| `pBitmap` | The bitmap whose colours an optimal palette is chosen from. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim photo as CGpBitmap = "photo.jpg"
dim pal as ColorPalette ptr = callocate( sizeof( ColorPalette ) + 255 * sizeof( ARGB ) )
pal->Count = 16
photo.InitializePalette( pal, PaletteTypeOptimal, 16, FALSE, @photo )
deallocate( pal )
```

Microsoft Learn: [Bitmap::InitializePalette](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-initializepalette)

### GetHistogramSize

```freebasic
function GetHistogramSize( byval nFormat as HistogramFormat, byval NumberOfEntries as UINT ptr ) as GpStatus
function GetHistogramSize( byval nFormat as HistogramFormat ) as UINT
```

Returns how many entries each channel array of [GetHistogram](#gethistogram) must have: 256, one
per channel value. The first form writes it into `NumberOfEntries` and returns the status. Neither
looks at the bitmap.

**Returns** the number of entries, or the status.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 8, 8 )
print bmp.GetHistogramSize( HistogramFormatARGB )   ' 256
```

Microsoft Learn: [Bitmap::GetHistogramSize](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-gethistogramsize)

### GetHistogram

```freebasic
function GetHistogram( byval nFormat as HistogramFormat, byval NumberOfEntries as UINT, byval channel0 as UINT ptr, byval channel1 as UINT ptr, byval channel2 as UINT ptr, byval channel3 as UINT ptr ) as GpStatus
```

Counts, for each channel `nFormat` names, how many pixels have each value from 0 to 255:
`channel0( v )` is the number of pixels whose first channel is `v`. The format decides how many
arrays are filled and in what order: `HistogramFormatARGB` four (alpha, red, green, blue),
`HistogramFormatRGB` three, `HistogramFormatGray`, `HistogramFormatR` and the other single
channels one. Pass `NULL` for the arrays a format does not use.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim photo as CGpBitmap = "photo.jpg"
dim n as UINT = photo.GetHistogramSize( HistogramFormatGray )
dim counts( n - 1 ) as UINT
photo.GetHistogram( HistogramFormatGray, n, @counts(0), NULL, NULL, NULL )
print counts(0); " black pixels"
```

Microsoft Learn: [Bitmap::GetHistogram](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-gethistogram)

### ApplyEffect

```freebasic
function ApplyEffect( byval pEffect as CGpEffect ptr, byval roi as RECT ptr, byval useAuxData as boolean, byval auxData as any ptr ptr, byval auxDataSize as INT_ ptr ) as GpStatus
function ApplyEffect( byval pEffect as CGpEffect ptr, byval roi as RECT ptr = NULL ) as GpStatus
```

Changes the bitmap's pixels with an [effect](SysWin-GdiPlus-Effects): a blur, a tint, a colour
correction. `roi` limits the effect to a rectangle; `NULL` applies it to the whole bitmap. The
bitmap's size never changes.

The first form can also return the lookup tables some effects build: with `useAuxData` `true`,
GDI+ allocates them and writes their address into `*auxData` and their size into
`*auxDataSize`. Pass `@fx.m_auxData` and `@fx.m_auxDataSize` of the effect itself and its
destructor frees them; with variables of your own, free the buffer with `GdipFree`.

`pEffect` must be an effect that was created: one whose `GetLastStatus()` was `Ok` after its
constructor. A bare [CGpEffect](SysWin-GdiPlus-Effects#cgpeffect), or an effect whose
constructor failed, stops the program.

| Parameter | Meaning |
| --- | --- |
| `pEffect` | The effect, with its parameters set. |
| `roi` | The rectangle to change, in pixels, or `NULL` for all of it. |
| `useAuxData` | `true` to receive the lookup tables. |
| `auxData`, `auxDataSize` | Receive the address and size of the tables. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim photo as CGpBitmap = "photo.jpg"
dim sharpen as CGpSharpen
sharpen.SetParameters( 3, 40 )
dim top as RECT = ( 0, 0, photo.GetWidth(), photo.GetHeight() \ 2 )
photo.ApplyEffect( @sharpen, @top )         ' the top half only
```

Microsoft Learn: [Bitmap::ApplyEffect](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-applyeffect%28effect_rect%29)

## CGpCachedBitmap

A copy of a bitmap converted to the format of a display, which [CGpGraphics](CGpGraphics)
`DrawCachedBitmap` draws faster than `DrawImage` draws the bitmap. It cannot be scaled, rotated or
read back, and must be made again when the display's colour depth changes. It is independent of
the bitmap it was made from.

### Constructor

```freebasic
constructor( byval pBitmap as CGpBitmap ptr, byval pGraphics as CGpGraphics_ ptr )
```

Copies `pBitmap` into the format that suits the device of `pGraphics`. There is no default
constructor. Either pointer may be `NULL`; GDI+ then refuses and `GetLastStatus()` is
`InvalidParameter`.

| Parameter | Meaning |
| --- | --- |
| `pBitmap` | The bitmap to copy. |
| `pGraphics` | A surface on the display the copy will be drawn on. |

**Example**

```freebasic
dim g as CGpGraphics = hwnd
dim sprite as CGpBitmap = "sprite.png"
dim fast as CGpCachedBitmap = CGpCachedBitmap( @sprite, @g )
g.DrawCachedBitmap( @fast, 10, 10 )
```

Microsoft Learn: [CachedBitmap::CachedBitmap](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-cachedbitmap-cachedbitmap%28bitmap_graphics%29)

### Destructor

```freebasic
destructor
```

Deletes the cached copy. The bitmap it was made from is not affected.

**Example**

```freebasic
dim g as CGpGraphics = hwnd
dim sprite as CGpBitmap = CGpBitmap( 32, 32 )
dim pFast as CGpCachedBitmap ptr = new CGpCachedBitmap( @sprite, @g )
delete pFast
```

Microsoft Learn: [CachedBitmap](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nl-gdiplusheaders-cachedbitmap)

## CGpMetafile

A vector image: a sequence of recorded drawing commands, in the Windows metafile formats (WMF,
EMF, EMF+). Derived from [CGpImage](#cgpimage). Open one to play it back with `DrawImage`, or
create one for recording: create a [CGpGraphics](CGpGraphics) on it (`dim g as CGpGraphics =
@mf`), draw, and destroy the graphics object; the recording is then complete and the metafile can
be drawn or, for a file, read by other programs once the metafile object is gone too.

### Constructor

```freebasic
constructor( byval hWmf as HMETAFILE, byval wmfPFH as WmfPlaceableFileHeader ptr, byval deleteWmf as BOOL = false )
constructor( byval hEmf as HENHMETAFILE, byval deleteEmf as BOOL = false )
constructor( byval pwszFileName as wstring ptr )
constructor( byval pwszFileName as wstring ptr, byval wmfPFH as WmfPlaceableFileHeader ptr )
constructor( byval pStream as IStream ptr )
constructor( byval referenceHdc as HDC, byval nType as EmfType = EmfTypeEmfPlusDual, byval description as wstring ptr = NULL )
constructor( byval referenceHdc as HDC, byval frmRect as GpRectF ptr, byval frameUnit as MetafileFrameUnit = MetafileFrameUnitGdi, byval nType as EmfType = EmfTypeEmfPlusDual, byval description as wstring ptr = NULL )
constructor( byval referenceHdc as HDC, byval frmRect as GpRect ptr, byval frameUnit as MetafileFrameUnit = MetafileFrameUnitGdi, byval nType as EmfType = EmfTypeEmfPlusDual, byval description as wstring ptr = NULL )
constructor( byval pwszFileName as wstring ptr, byval referenceHdc as HDC, byval nType as EmfType = EmfTypeEmfPlusDual, byval description as wstring ptr = NULL )
constructor( byval pwszFileName as wstring ptr, byval referenceHdc as HDC, byval frmRect as GpRectF ptr, byval frameUnit as MetafileFrameUnit = MetafileFrameUnitGdi, byval nType as EmfType = EmfTypeEmfPlusDual, byval description as wstring ptr = NULL )
constructor( byval pwszFileName as wstring ptr, byval referenceHdc as HDC, byval frmRect as GpRect ptr, byval frameUnit as MetafileFrameUnit = MetafileFrameUnitGdi, byval nType as EmfType = EmfTypeEmfPlusDual, byval description as wstring ptr = NULL )
constructor( byval pStream as IStream ptr, byval referenceHdc as HDC, byval nType as EmfType, byval description as wstring ptr )
constructor( byval pStream as IStream ptr, byval referenceHdc as HDC, byval frmRect as GpRectF ptr, byval frameUnit as MetafileFrameUnit = MetafileFrameUnitGdi, byval nType as EmfType = EmfTypeEmfPlusDual, byval description as wstring ptr = NULL )
constructor( byval pStream as IStream ptr, byval referenceHdc as HDC, byval frmRect as GpRect ptr, byval frameUnit as MetafileFrameUnit = MetafileFrameUnitGdi, byval nType as EmfType = EmfTypeEmfPlusDual, byval description as wstring ptr = NULL )
```

The first five open a metafile for **playback**:

- A GDI `HMETAFILE` (WMF) with its placeable header, or a GDI `HENHMETAFILE` (EMF). With
  `deleteWmf` / `deleteEmf` `TRUE` the handle is deleted along with this object; with `FALSE`
  (the default) it stays yours.
- A file name: an EMF, EMF+ or placeable WMF file. With a `WmfPlaceableFileHeader` as well, a WMF
  file without a placeable header, described by the one you give.
- A stream holding a metafile.

The others start a **recording**, in memory, into a file or into a stream:

- `referenceHdc` is a device context (usually the screen's, `GetDC( NULL )`) whose resolution and
  units the recording is based on.
- `frmRect` and `frameUnit` give the frame, the rectangle the picture occupies; without it, the
  frame is the bounding box of what is drawn. `MetafileFrameUnitGdi` (the default) means
  hundredths of a millimetre; `MetafileFrameUnitPixel`, `MetafileFrameUnitPoint`,
  `MetafileFrameUnitInch` and the others are there too.
- `nType` chooses the records written: `EmfTypeEmfPlusDual` (the default: EMF+ records with plain
  EMF ones as a fallback), `EmfTypeEmfPlusOnly`, `EmfTypeEmfOnly`.
- `description` is an optional text stored in the file. In the stream form without a frame, pass
  a description: there is no default for it.

| Parameter | Meaning |
| --- | --- |
| `hWmf`, `hEmf`, `wmfPFH` | The GDI metafile handle and, for WMF, its placeable header. |
| `deleteWmf`, `deleteEmf` | `TRUE` to delete the handle with this object. |
| `pwszFileName`, `pStream` | The file or stream to play back, or to record into. |
| `referenceHdc` | The reference device context for a recording. |
| `frmRect`, `frameUnit` | The frame of the picture and its unit. |
| `nType` | The kind of records to write. |
| `description` | A description to store, or `NULL`. |

**Example**

```freebasic
dim hdcScreen as HDC = GetDC( NULL )
scope
    dim mf as CGpMetafile = CGpMetafile( "drawing.emf", hdcScreen )
    dim g as CGpGraphics = @mf
    dim pen as CGpPen = CGpPen( ARGB_Red, 2 )
    g.DrawLine( @pen, 0, 0, 100, 50 )
end scope                           ' drawing.emf is complete
ReleaseDC( NULL, hdcScreen )
dim playback as CGpMetafile = CGpMetafile( "drawing.emf" )
```

Microsoft Learn: [Metafile::Metafile (record)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-metafile%28hdc_emftype_constwchar%29), [Metafile::Metafile (frame)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-metafile%28hdc_constrectf__metafileframeunit_emftype_constwchar%29), [Metafile::Metafile (file)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-metafile%28constwchar%29), [Metafile::Metafile (HENHMETAFILE)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-metafile%28henhmetafile_bool%29)

### GetMetafileHeader

```freebasic
function GetMetafileHeader( byval hWmf as HMETAFILE, byval wmfPFH as WmfPlaceableFileHeader ptr, byval mh as MetafileHeader ptr ) as GpStatus
function GetMetafileHeader( byval hEmf as HENHMETAFILE, byval mh as MetafileHeader ptr ) as GpStatus
function GetMetafileHeader( byval pwsFileName as wstring ptr, byval mh as MetafileHeader ptr ) as GpStatus
function GetMetafileHeader( byval pStream as IStream ptr, byval mh as MetafileHeader ptr ) as GpStatus
function GetMetafileHeader( byval mh as MetafileHeader ptr ) as GpStatus
```

Fills a `MetafileHeader` with the type (`Type`: `MetafileTypeWmf`, `MetafileTypeEmf`,
`MetafileTypeEmfPlusOnly`, `MetafileTypeEmfPlusDual` …), size in bytes (`Size`), resolution
(`DpiX`, `DpiY`) and bounds of a metafile. The last form reads this object's metafile; the others
read the metafile given by handle, file or stream and do not use this object.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim mf as CGpMetafile = CGpMetafile( "drawing.emf" )
dim mh as MetafileHeader
if mf.GetMetafileHeader( @mh ) = Ok then print "type"; mh.Type; ","; mh.Size; " bytes"
```

Microsoft Learn: [Metafile::GetMetafileHeader](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-getmetafileheader%28metafileheader%29), [Metafile::GetMetafileHeader (file)](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-getmetafileheader%28constwchar_metafileheader%29)

### GetHENHMETAFILE

```freebasic
function GetHENHMETAFILE() as HENHMETAFILE
```

Hands the metafile over as a GDI enhanced-metafile handle, for GDI functions such as
`PlayEnhMetaFile` or for the clipboard. After the call the object no longer holds a usable
metafile (its getters return 0 and its methods `InvalidParameter`), and the handle is yours:
delete it with `DeleteEnhMetaFile`.

**Returns** the handle, or `NULL` on failure.

**Example**

```freebasic
dim mf as CGpMetafile = CGpMetafile( "drawing.emf" )
dim hEmf as HENHMETAFILE = mf.GetHENHMETAFILE()
' ... PlayEnhMetaFile( hdc, hEmf, @rc ) ...
DeleteEnhMetaFile( hEmf )
```

Microsoft Learn: [Metafile::GetHENHMETAFILE](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-gethenhmetafile)

### PlayRecord

```freebasic
function PlayRecord( byval recordType as EmfPlusRecordType, byval flags as UINT, byval dataSize as UINT, byval pData as byte ptr ) as GpStatus
```

Plays one metafile record. Call it from the callback that a [CGpGraphics](CGpGraphics)
`EnumerateMetafile…` method calls for each record, passing on the record's type, flags, size and
data as the callback received them; skip the call for records you want to leave out.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
function PlayAllButText( byval recordType as EmfPlusRecordType, byval flags as UINT, byval dataSize as UINT, byval pData as const ubyte ptr, byval callbackData as any ptr ) as BOOL
    dim pMf as CGpMetafile ptr = callbackData
    if recordType <> EmfPlusRecordTypeDrawString then pMf->PlayRecord( recordType, flags, dataSize, cast( byte ptr, pData ) )
    return TRUE
end function
```

Microsoft Learn: [Metafile::PlayRecord](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-playrecord)

### GetDownLevelRasterizationLimit, SetDownLevelRasterizationLimit

```freebasic
function GetDownLevelRasterizationLimit() as UINT
function SetDownLevelRasterizationLimit( byval metafileRasterizationLimitDpi as UINT ) as GpStatus
```

When a recording also writes plain EMF records, brush bitmaps that EMF cannot describe are stored
as pixels. `SetDownLevelRasterizationLimit` caps the resolution they are stored at, in dots per
inch: recording against a printer DC but setting 96 keeps the file small. 0 means the resolution
of the reference DC. `GetDownLevelRasterizationLimit` reads the value back. Both apply to a
metafile being recorded; for one opened for playback they fail with `WrongState` and the getter
returns 0.

**Returns** the limit in dots per inch, or the status.

**Example**

```freebasic
dim hdcScreen as HDC = GetDC( NULL )
dim mf as CGpMetafile = CGpMetafile( hdcScreen )
mf.SetDownLevelRasterizationLimit( 96 )
print mf.GetDownLevelRasterizationLimit()   ' 96
ReleaseDC( NULL, hdcScreen )
```

Microsoft Learn: [Metafile::SetDownLevelRasterizationLimit](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-setdownlevelrasterizationlimit), [Metafile::GetDownLevelRasterizationLimit](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-getdownlevelrasterizationlimit)

### EmfToWmfBits

```freebasic
function EmfToWmfBits( byval hEmf as HENHMETAFILE, byval cbData16 as UINT, byval pData16 as byte ptr, byval iMapMode as INT_ = MM_ANISOTROPIC, byval eFlags as INT_ = EmfToWmfBitsFlagsDefault ) as UINT
```

Converts the enhanced metafile `hEmf` (not this object's metafile) to the older WMF format and
writes the WMF bytes into `pData16`, a buffer of `cbData16` bytes. Call it first with `NULL` and
0 to learn the size, then with a buffer that large. `SetWinMetaFileBits` turns the bytes into an
`HMETAFILE`.

| Parameter | Meaning |
| --- | --- |
| `hEmf` | The enhanced metafile to convert. |
| `cbData16`, `pData16` | The size of the buffer and the buffer, or 0 and `NULL`. |
| `iMapMode` | The mapping mode of the WMF; `MM_ANISOTROPIC` by default. |
| `eFlags` | `EmfToWmfBitsFlagsDefault`, or flags such as `EmfToWmfBitsFlagsEmbedEmf` and `EmfToWmfBitsFlagsIncludePlaceable`. |

**Returns** the size in bytes.

**Example**

```freebasic
dim hEmf as HENHMETAFILE = GetEnhMetaFileW( "drawing.emf" )
dim mf as CGpMetafile = CGpMetafile( hEmf )
dim need as UINT = mf.EmfToWmfBits( hEmf, 0, NULL )
dim wmf as byte ptr = callocate( need )
mf.EmfToWmfBits( hEmf, need, wmf )
deallocate( wmf )
```

Microsoft Learn: [Metafile::EmfToWmfBits](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-metafile-emftowmfbits)

## See also

- [CGpGraphics](CGpGraphics): `DrawImage`, `DrawCachedBitmap` and drawing into a bitmap or a metafile
- [CGpImageAttributes](CGpImageAttributes): colour adjustments applied while drawing an image
- [GDI+ effects](SysWin-GdiPlus-Effects): the effects `ApplyEffect` takes
- [GDI+ procedures](SysWin-GdiPlus-Procedures): `GetEncoderClsid`, and helpers that load and save images in one call
- [Bitmaps](SysWin-Bitmaps): GDI bitmaps and DIB sections
- [sys/win/gdiplus](SysWin-GdiPlus)
