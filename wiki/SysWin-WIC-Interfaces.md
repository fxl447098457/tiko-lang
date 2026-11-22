[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/direct2d](SysWin-Direct2D) › **WIC interfaces and types**

# WIC interfaces and types

Lists the WIC interfaces, enumerations and structures of sys/win/direct2d.

The **Windows Imaging Component** (WIC) reads and writes image files (BMP, PNG, JPEG, GIF,
TIFF, ICO, HEIF, WebP and camera RAW among them), converts between pixel formats, scales, crops
and rotates images, and reads their metadata. Direct2D draws what WIC decodes:
[CID2D1RenderTarget](CID2D1RenderTarget)`.CreateBitmapFromWicBitmap` turns an
`IWICBitmapSource` into a Direct2D bitmap, and [CD2D1Factory](CD2D1Factory)`.CreateWicBitmapRenderTarget`
makes a render target that draws into an `IWICBitmap`. No class wraps WIC itself: a program
works with the interfaces.

**Where the objects come from.** The imaging factory is a COM class. After `CoInitialize`,
`CoCreateInstance` with `CLSID_WICImagingFactory` and `IID_IWICImagingFactory` gives an
`IWICImagingFactory ptr`, and every other object comes from it: decoders from a file name, a
stream or a handle, encoders for a container format, streams, bitmaps, format converters,
scalers, clippers, flip-rotators, palettes and colour contexts.

**Calling a method.** Each interface `IWICX` is a name for the type `IWICX_`, which declares the
methods and extends its parent, so `p->Method( ... )` calls one, and a decoded frame
(`IWICBitmapFrameDecode`) is also an `IWICBitmapSource`. A parameter that receives an object is
`byref ... ptr`: pass the pointer variable. An optional `byref` GUID or rectangle can be left
out by passing `*cast( GUID ptr, NULL )` or `*cast( WICRect ptr, NULL )`. Every pointer handed
out holds one reference: call `Release` when done.

**Identifiers.** All are `GUID` variables:

- `IID_IWICImagingFactory`, `IID_IWICBitmap` … one per interface;
- `CLSID_WICImagingFactory`, `CLSID_WICImagingFactory2` and the codec classes
  (`CLSID_WICPngDecoder`, `CLSID_WICJpegEncoder` …);
- container formats `GUID_ContainerFormatBmp`, `…Png`, `…Ico`, `…Jpeg`, `…Tiff`, `…Gif`,
  `…Wmp`, `…Dds`, `…Heif`, `…Webp`, `…Raw`, `…JpegXL`, `…Adng`;
- pixel formats, named **`IID_WICPixelFormat…`** here (`IID_WICPixelFormat32bppPBGRA`,
  `IID_WICPixelFormat24bppBGR` …), where the Windows headers say `GUID_WICPixelFormat…`; the
  parameter type `WICPixelFormatGUID` is a `GUID`;
- component categories `CATID_WIC…` and the vendor `GUID_VendorMicrosoft`.

**Things to watch.**

- Encoders and decoders take Windows' own `IStream ptr`; an `IWICStream` (built on
  `ComStream`) is passed as `cast( IStream ptr, cast( any ptr, pStream ) )`. The
  `IPropertyBag2` that `CreateNewFrame` returns is released with
  `pOptions->lpVtbl->Release( pOptions )`.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/direct2d"
using win, direct2d
```

## Example

A console program that makes a bitmap from its own pixels, encodes it as a PNG file, decodes
the file again and reads back its size and one pixel:

```freebasic
#import "sys/win"
#import "sys/win/direct2d"
using win, direct2d

function main() as long
    CoInitialize( NULL )

    ' The imaging factory is a COM class: every other WIC object comes from it.
    dim pFactory as IWICImagingFactory ptr
    dim hr as HRESULT = CoCreateInstance( @CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER, _
                                          @IID_IWICImagingFactory, @pFactory )
    if hr <> S_OK then print "no WIC factory: &h"; hex( hr ) : return 1

    ' A 64 x 48 bitmap made from our own pixels: blue on the left, red on the right.
    const W = 64, H = 48
    dim pixels( W * H - 1 ) as ulong
    for i as long = 0 to W * H - 1
        pixels( i ) = iif( ( i mod W ) < W \ 2, &hFF0000FFul, &hFFFF0000ul )   ' &hAARRGGBB
    next
    dim pBitmap as IWICBitmap ptr
    pFactory->CreateBitmapFromMemory( W, H, IID_WICPixelFormat32bppBGRA, W * 4, W * H * 4, _
                                      cast( byte ptr, @pixels( 0 ) ), pBitmap )

    ' Encode it as a PNG file.
    dim wszFile as wstring * MAX_PATH = environ( "TEMP" ) & "\wicdemo.png"
    dim pStream as IWICStream ptr
    pFactory->CreateStream( pStream )
    pStream->InitializeFromFilename( wszFile, GENERIC_WRITE )
    dim pEncoder as IWICBitmapEncoder ptr
    pFactory->CreateEncoder( GUID_ContainerFormatPng, *cast( GUID ptr, NULL ), pEncoder )
    pEncoder->Initialize( cast( IStream ptr, cast( any ptr, pStream ) ), WICBitmapEncoderNoCache )
    dim pFrame as IWICBitmapFrameEncode ptr
    dim pOptions as IPropertyBag2 ptr
    pEncoder->CreateNewFrame( pFrame, pOptions )
    pFrame->Initialize( pOptions )
    pFrame->SetSize( W, H )
    dim fmt as WICPixelFormatGUID = IID_WICPixelFormat32bppBGRA
    pFrame->SetPixelFormat( fmt )
    pFrame->WriteSource( cast( IWICBitmapSource ptr, pBitmap ), *cast( WICRect ptr, NULL ) )
    pFrame->Commit()
    hr = pEncoder->Commit()
    print "PNG written: "; iif( hr = S_OK, "yes", "no" )
    pFrame->Release() : pOptions->lpVtbl->Release( pOptions ) : pEncoder->Release() : pStream->Release()

    ' Decode it again and read the first frame.
    dim pDecoder as IWICBitmapDecoder ptr
    hr = pFactory->CreateDecoderFromFilename( wszFile, *cast( GUID ptr, NULL ), GENERIC_READ, _
                                              WICDecodeMetadataCacheOnDemand, pDecoder )
    dim nFrames as UINT
    pDecoder->GetFrameCount( nFrames )
    dim pDecoded as IWICBitmapFrameDecode ptr
    pDecoder->GetFrame( 0, pDecoded )
    dim as UINT cx, cy
    pDecoded->GetSize( cx, cy )
    print "frames: "; nFrames; ", size: "; cx; " x "; cy

    ' Read one pixel from the right half.
    dim rc as WICRect = ( W - 1, 0, 1, 1 )
    dim px as ulong
    pDecoded->CopyPixels( rc, 4, 4, cast( byte ptr, @px ) )
    print "top-right pixel: &h"; hex( px, 8 )

    pDecoded->Release() : pDecoder->Release() : pBitmap->Release() : pFactory->Release()
    kill( wszFile )
    CoUninitialize()
    return 0
end function

end main()
```

It prints:

```text
PNG written: yes
frames: 1, size: 64 x 48
top-right pixel: &hFFFF0000
```

## Types

The enumeration types are `long`s; their values are separate constants, written bare after
`using direct2d` (`WICBitmapLockWrite`, `WICDecodeMetadataCacheOnLoad`). `WICColorContextType`
is a named `enum`.

### Interfaces

| Interface | Methods declared in | Extends | Is | Microsoft Learn |
| --- | --- | --- | --- | --- |
| — | `ComStream` | `ComUnknown` | The stream methods (`Read`, `Write`, `Seek`, `Stat` …) that `IWICStream` inherits; it has no alias of its own. | [IStream](https://learn.microsoft.com/en-us/windows/win32/api/objidl/nn-objidl-istream) |
| `IWICPalette` | `IWICPalette_` | `ComUnknown` | A colour table for indexed pixel formats: predefined, custom or built from a bitmap. | [IWICPalette](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicpalette) |
| `IWICBitmapSource` | `IWICBitmapSource_` | `ComUnknown` | The base of everything that has pixels: size, pixel format, resolution, `CopyPixels`. Direct2D makes bitmaps from one. | [IWICBitmapSource](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapsource) |
| `IWICFormatConverter` | `IWICFormatConverter_` | `IWICBitmapSource` | Converts a source to another pixel format, such as 32bppPBGRA for Direct2D. | [IWICFormatConverter](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicformatconverter) |
| `IWICPlanarFormatConverter` | `IWICPlanarFormatConverter_` | `IWICBitmapSource` | Converts planar (YCbCr) sources to an interleaved pixel format. | [IWICPlanarFormatConverter](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicplanarformatconverter) |
| `IWICBitmapScaler` | `IWICBitmapScaler_` | `IWICBitmapSource` | Resizes a source with a chosen interpolation mode. | [IWICBitmapScaler](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapscaler) |
| `IWICBitmapClipper` | `IWICBitmapClipper_` | `IWICBitmapSource` | Crops a source to a rectangle. | [IWICBitmapClipper](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapclipper) |
| `IWICBitmapFlipRotator` | `IWICBitmapFlipRotator_` | `IWICBitmapSource` | Flips or rotates a source by multiples of 90 degrees. | [IWICBitmapFlipRotator](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapfliprotator) |
| `IWICBitmapLock` | `IWICBitmapLock_` | `ComUnknown` | Direct access to a locked rectangle of a bitmap: stride, data pointer, pixel format. | [IWICBitmapLock](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmaplock) |
| `IWICBitmap` | `IWICBitmap_` | `IWICBitmapSource` | A bitmap in memory that can be written: `Lock`, palette, resolution. Direct2D can draw into one. | [IWICBitmap](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmap) |
| `IWICColorContext` | `IWICColorContext_` | `ComUnknown` | A colour profile, from an ICC file, memory or an EXIF colour space. | [IWICColorContext](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwiccolorcontext) |
| `IWICColorTransform` | `IWICColorTransform_` | `IWICBitmapSource` | Converts a source from one colour context to another. | [IWICColorTransform](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwiccolortransform) |
| `IWICFastMetadataEncoder` | `IWICFastMetadataEncoder_` | `ComUnknown` | Updates metadata in place, without re-encoding the image. | [IWICFastMetadataEncoder](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicfastmetadataencoder) |
| `IWICStream` | `IWICStream_` | `ComStream` | A stream over a file, a memory block or another stream, for encoders and decoders. | [IWICStream](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicstream) |
| `IWICEnumMetadataItem` | `IWICEnumMetadataItem_` | `ComUnknown` | Walks the items of a metadata block. | [IWICEnumMetadataItem](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicenummetadataitem) |
| `IWICMetadataQueryReader` | `IWICMetadataQueryReader_` | `ComUnknown` | Reads metadata by query path, such as `/app1/ifd/{ushort=274}`. | [IWICMetadataQueryReader](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicmetadataqueryreader) |
| `IWICMetadataQueryWriter` | `IWICMetadataQueryWriter_` | `IWICMetadataQueryReader` | Writes and removes metadata by query path. | [IWICMetadataQueryWriter](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicmetadataquerywriter) |
| `IWICBitmapEncoder` | `IWICBitmapEncoder_` | `ComUnknown` | Writes an image file of one container format: frames, palette, thumbnail, `Commit`. | [IWICBitmapEncoder](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapencoder) |
| `IWICBitmapFrameEncode` | `IWICBitmapFrameEncode_` | `ComUnknown` | One frame being encoded: size, resolution, pixel format, pixels or a source, `Commit`. | [IWICBitmapFrameEncode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapframeencode) |
| `IWICPlanarBitmapFrameEncode` | `IWICPlanarBitmapFrameEncode_` | `ComUnknown` | Writes planar (YCbCr) pixels into a frame. | [IWICPlanarBitmapFrameEncode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicplanarbitmapframeencode) |
| `IWICImageEncoder` | `Afx_IWICImageEncoder_` | `ComUnknown` | Encodes a Direct2D image into a frame. The name is declared but its methods are not reachable through it: they are declared on `Afx_IWICImageEncoder_`. | [IWICImageEncoder](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicimageencoder) |
| `IWICBitmapDecoder` | `IWICBitmapDecoder_` | `ComUnknown` | Reads an image file: container format, frame count, frames, preview, thumbnail, metadata. | [IWICBitmapDecoder](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapdecoder) |
| `IWICBitmapSourceTransform` | `IWICBitmapSourceTransform_` | `ComUnknown` | Lets a decoder scale, flip or convert while it decodes. | [IWICBitmapSourceTransform](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapsourcetransform) |
| `IWICBitmapSourceTransform2` | `IWICBitmapSourceTransform2_` | `IWICBitmapSourceTransform` | Adds colour contexts for a pixel format. | — |
| `IWICPlanarBitmapSourceTransform` | `IWICPlanarBitmapSourceTransform_` | `ComUnknown` | Decodes straight to planar (YCbCr) buffers. | [IWICPlanarBitmapSourceTransform](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicplanarbitmapsourcetransform) |
| `IWICBitmapFrameDecode` | `IWICBitmapFrameDecode_` | `IWICBitmapSource` | One decoded frame: an `IWICBitmapSource` plus metadata, colour contexts and thumbnail. | [IWICBitmapFrameDecode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapframedecode) |
| `IWICProgressiveLevelControl` | `IWICProgressiveLevelControl_` | `ComUnknown` | Chooses the level of a progressively encoded image. | [IWICProgressiveLevelControl](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicprogressivelevelcontrol) |
| `IWICDisplayAdaptationControl` | `Afx_IWICDisplayAdaptationControl_` | `ComUnknown` | Sets the display luminance HDR images are adapted to. The name is declared but its methods are declared on `Afx_IWICDisplayAdaptationControl_`. | — |
| `IWICProgressCallback` | `IWICProgressCallback_` | `ComUnknown` | Implemented by a program to hear the progress of a long operation. | [IWICProgressCallback](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicprogresscallback) |
| `IWICBitmapCodecProgressNotification` | `IWICBitmapCodecProgressNotification_` | `ComUnknown` | Registers a progress callback with an encoder or decoder. | [IWICBitmapCodecProgressNotification](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapcodecprogressnotification) |
| `IWICComponentInfo` | `IWICComponentInfo_` | `ComUnknown` | Common information about a WIC component: type, CLSID, author, version, friendly name. | [IWICComponentInfo](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwiccomponentinfo) |
| `IWICFormatConverterInfo` | `IWICFormatConverterInfo_` | `IWICComponentInfo` | Information about a format converter: the pixel formats it handles. | [IWICFormatConverterInfo](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicformatconverterinfo) |
| `IWICBitmapCodecInfo` | `IWICBitmapCodecInfo_` | `IWICComponentInfo` | Information about a codec: container format, pixel formats, MIME types, file extensions, capabilities. | [IWICBitmapCodecInfo](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapcodecinfo) |
| `IWICBitmapEncoderInfo` | `IWICBitmapEncoderInfo_` | `IWICBitmapCodecInfo` | Information about an encoder; can create it. | [IWICBitmapEncoderInfo](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapencoderinfo) |
| `IWICBitmapDecoderInfo` | `IWICBitmapDecoderInfo_` | `IWICBitmapCodecInfo` | Information about a decoder: the byte patterns it recognises; can create it. | [IWICBitmapDecoderInfo](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicbitmapdecoderinfo) |
| `IWICPixelFormatInfo` | `IWICPixelFormatInfo_` | `IWICComponentInfo` | Information about a pixel format: bits per pixel, channels, channel masks. | [IWICPixelFormatInfo](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicpixelformatinfo) |
| `IWICPixelFormatInfo2` | `IWICPixelFormatInfo2_` | `IWICPixelFormatInfo` | Adds transparency support and the numeric representation. | [IWICPixelFormatInfo2](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicpixelformatinfo2) |
| `IWICImagingFactory` | `IWICImagingFactory_` | `ComUnknown` | The root object: creates decoders, encoders, streams, bitmaps, converters, scalers and palettes. From `CoCreateInstance` with `CLSID_WICImagingFactory`. | [IWICImagingFactory](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicimagingfactory) |
| `IWICImagingFactory2` | `IWICImagingFactory2_` | `IWICImagingFactory` | Adds `CreateImageEncoder` for Direct2D images. | [IWICImagingFactory2](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicimagingfactory2) |
| `IWICDevelopRawNotificationCallback` | `IWICDevelopRawNotificationCallback_` | `ComUnknown` | Implemented by a program to hear when RAW development settings change. | [IWICDevelopRawNotificationCallback](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicdeveloprawnotificationcallback) |
| `IWICDevelopRaw` | `IWICDevelopRaw_` | `IWICBitmapFrameDecode` | Develops a camera RAW frame: exposure, white point, contrast, gamma, sharpening, tone curve, rotation. | [IWICDevelopRaw](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicdevelopraw) |
| `IWICDdsDecoder` | `IWICDdsDecoder_` | `ComUnknown` | DDS texture decoder: parameters and frames by array index, mip level and slice. | [IWICDdsDecoder](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicddsdecoder) |
| `IWICDdsEncoder` | `Afx_IWICDdsEncoder_` | `ComUnknown` | DDS texture encoder. The name is declared but its methods are declared on `Afx_IWICDdsEncoder_`. | [IWICDdsEncoder](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicddsencoder) |
| `IWICDdsFrameDecode` | `IWICDdsFrameDecode_` | `ComUnknown` | One DDS frame: size in blocks, format information, `CopyBlocks`. | [IWICDdsFrameDecode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicddsframedecode) |
| `IWICJpegFrameDecode` | `IWICJpegFrameDecode_` | `ComUnknown` | Low-level JPEG decoding: Huffman and quantization tables, frame and scan headers, scans. | [IWICJpegFrameDecode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicjpegframedecode) |
| `IWICJpegFrameEncode` | `IWICJpegFrameEncode_` | `ComUnknown` | Low-level JPEG encoding: tables and scans written as they are. | [IWICJpegFrameEncode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/nn-wincodec-iwicjpegframeencode) |

### Enumerations

| Type | Values | Is | Microsoft Learn |
| --- | --- | --- | --- |
| `WICColorContextType` | `WICColorContext*` | What a colour context holds: nothing, an ICC profile, an EXIF colour space. | [WICColorContextType](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wiccolorcontexttype) |
| `WICBitmapCreateCacheOption` | `WICBitmap*` | Whether a new bitmap copies its source: no cache, on demand, on load. | [WICBitmapCreateCacheOption](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmapcreatecacheoption) |
| `WICDecodeOptions` | `WICDecodeMetadataCacheOnDemand`, `WICDecodeMetadataCacheOnLoad` | When a decoder reads the metadata: on demand or on load. | [WICDecodeOptions](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicdecodeoptions) |
| `WICBitmapEncoderCacheOption` | `WICBitmapEncoder*` | Where an encoder keeps data: in memory, in a temporary file, nowhere. | [WICBitmapEncoderCacheOption](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmapencodercacheoption) |
| `WICComponentType` | `WICDecoder`, `WICEncoder` … | Kinds of WIC component: decoder, encoder, pixel-format converter, metadata reader and writer, pixel format. | [WICComponentType](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wiccomponenttype) |
| `WICComponentEnumerateOptions` | `WICComponentEnumerate*` | Which components `CreateComponentEnumerator` lists: default, refresh, disabled, unsigned, built-in only. | [WICComponentEnumerateOptions](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wiccomponentenumerateoptions) |
| `WICBitmapInterpolationMode` | `WICBitmapInterpolationMode*` | Scaling filter: nearest neighbour, linear, cubic, Fant, high-quality cubic. | [WICBitmapInterpolationMode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmapinterpolationmode) |
| `WICBitmapPaletteType` | `WICBitmapPaletteType*` | Palettes: custom, median cut, and fixed black and white, halftone, web and grey palettes. | [WICBitmapPaletteType](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmappalettetype) |
| `WICBitmapDitherType` | `WICBitmapDitherType*` | Dithering for colour reduction: none, ordered, spiral, dual spiral, error diffusion. | [WICBitmapDitherType](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmapdithertype) |
| `WICBitmapAlphaChannelOption` | `WICBitmap*` | How an `HBITMAP` alpha channel is read: use, premultiplied, ignore. | [WICBitmapAlphaChannelOption](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmapalphachanneloption) |
| `WICBitmapTransformOptions` | `WICBitmapTransform*` | Rotations by 0, 90, 180, 270 degrees and horizontal or vertical flips. | [WICBitmapTransformOptions](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmaptransformoptions) |
| `WICBitmapLockFlags` | `WICBitmapLockRead`, `WICBitmapLockWrite` | Access to a locked bitmap: read, write. | [WICBitmapLockFlags](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmaplockflags) |
| `WICBitmapDecoderCapabilities` | `WICBitmapDecoderCapability*` | What a decoder can do with a stream: same encoder, all or some images, enumerate metadata, thumbnails. | [WICBitmapDecoderCapabilities](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicbitmapdecodercapabilities) |
| `WICProgressOperation` | `WICProgressOperation*` | Which operations report progress: copying or writing pixels. | [WICProgressOperation](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicprogressoperation) |
| `WICProgressNotification` | `WICProgressNotification*` | When progress is reported: begin, end, frequently, always. | [WICProgressNotification](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicprogressnotification) |
| `WICComponentSigning` | `WICComponent*` | Whether a component is signed, unsigned, safe or disabled. | [WICComponentSigning](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wiccomponentsigning) |
| `WICGifLogicalScreenDescriptorProperties` | `WICGifLogicalScreen*` | Metadata items of a GIF logical screen descriptor. | [WICGifLogicalScreenDescriptorProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicgiflogicalscreendescriptorproperties) |
| `WICGifImageDescriptorProperties` | `WICGifImageDescriptor*` | Metadata items of a GIF image descriptor. | [WICGifImageDescriptorProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicgifimagedescriptorproperties) |
| `WICGifGraphicControlExtensionProperties` | `WICGifGraphicControlExtension*` | Metadata items of a GIF graphic control extension: disposal, delay, transparency. | [WICGifGraphicControlExtensionProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicgifgraphiccontrolextensionproperties) |
| `WICGifApplicationExtensionProperties` | `WICGifApplicationExtensionApplication`, `WICGifApplicationExtensionData` | Metadata items of a GIF application extension. | [WICGifApplicationExtensionProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicgifapplicationextensionproperties) |
| `WICGifCommentExtensionProperties` | `WICGifCommentExtensionText` | Metadata item of a GIF comment extension. | [WICGifCommentExtensionProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicgifcommentextensionproperties) |
| `WICJpegCommentProperties` | `WICJpegCommentText` | Metadata item of a JPEG comment. | [WICJpegCommentProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicjpegcommentproperties) |
| `WICJpegLuminanceProperties` | `WICJpegLuminanceTable` | Metadata item of a JPEG luminance table. | [WICJpegLuminanceProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicjpegluminanceproperties) |
| `WICJpegChrominanceProperties` | `WICJpegChrominanceTable` | Metadata item of a JPEG chrominance table. | [WICJpegChrominanceProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicjpegchrominanceproperties) |
| `WIC8BIMIptcProperties` | `WIC8BIMIptcPString`, `WIC8BIMIptcEmbeddedIPTC` | Metadata items of a Photoshop 8BIM IPTC block. | [WIC8BIMIptcProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wic8bimiptcproperties) |
| `WIC8BIMResolutionInfoProperties` | `WIC8BIMResolutionInfo*` | Metadata items of a Photoshop 8BIM resolution block. | [WIC8BIMResolutionInfoProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wic8bimresolutioninfoproperties) |
| `WIC8BIMIptcDigestProperties` | `WIC8BIMIptcDigestPString`, `WIC8BIMIptcDigestIptcDigest` | Metadata items of a Photoshop 8BIM IPTC digest. | [WIC8BIMIptcDigestProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wic8bimiptcdigestproperties) |
| `WICPngGamaProperties` | `WICPngGamaGamma` | Metadata item of a PNG gAMA chunk. | [WICPngGamaProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpnggamaproperties) |
| `WICPngBkgdProperties` | `WICPngBkgdBackgroundColor` | Metadata item of a PNG bKGD chunk. | [WICPngBkgdProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpngbkgdproperties) |
| `WICPngItxtProperties` | `WICPngItxt*` | Metadata items of a PNG iTXt chunk. | [WICPngItxtProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpngitxtproperties) |
| `WICPngChrmProperties` | `WICPngChrm*` | Metadata items of a PNG cHRM chunk. | [WICPngChrmProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpngchrmproperties) |
| `WICPngHistProperties` | `WICPngHistFrequencies` | Metadata item of a PNG hIST chunk. | [WICPngHistProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpnghistproperties) |
| `WICPngIccpProperties` | `WICPngIccpProfileName`, `WICPngIccpProfileData` | Metadata items of a PNG iCCP chunk. | [WICPngIccpProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpngiccpproperties) |
| `WICPngSrgbProperties` | `WICPngSrgbRenderingIntent` | Metadata item of a PNG sRGB chunk. | [WICPngSrgbProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpngsrgbproperties) |
| `WICPngTimeProperties` | `WICPngTime*` | Metadata items of a PNG tIME chunk. | [WICPngTimeProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpngtimeproperties) |
| `WICHeifProperties` | `WICHeifOrientation` | Metadata item of a HEIF image: orientation. | [WICHeifProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicheifproperties) |
| `WICHeifHdrProperties` | `WICHeifHdr*` | HDR metadata items of a HEIF image. | [WICHeifHdrProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicheifhdrproperties) |
| `WICWebpAnimProperties` | `WICWebpAnimLoopCount` | Metadata item of a WebP ANIM chunk: loop count. | [WICWebpAnimProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicwebpanimproperties) |
| `WICWebpAnmfProperties` | `WICWebpAnmfFrameDuration` | Metadata item of a WebP ANMF chunk: frame duration. | [WICWebpAnmfProperties](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicwebpanmfproperties) |
| `WICJpegXLAnimProperties` | `WICJpegXLAnim*` | Animation metadata items of a JPEG XL image. | — |
| `WICJpegXLAnimFrameProperties` | `WICJpegXLAnimFrameDurationInTicks`, `WICJpegXLAnimFrameName` | Frame metadata items of a JPEG XL animation. | — |
| `WICSectionAccessLevel` | `WICSectionAccessLevelRead`, `WICSectionAccessLevelReadWrite` | Access to a section-backed bitmap: read, read and write. | [WICSectionAccessLevel](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicsectionaccesslevel) |
| `WICPixelFormatNumericRepresentation` | `WICPixelFormatNumericRepresentation*` | How channel values are stored: indexed, integer, fixed point, float. | [WICPixelFormatNumericRepresentation](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpixelformatnumericrepresentation) |
| `WICPlanarOptions` | `WICPlanarOptionsDefault`, `WICPlanarOptionsPreserveSubsampling` | Whether planar decoding keeps chroma subsampling. | [WICPlanarOptions](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicplanaroptions) |
| `WICJpegIndexingOptions` | `WICJpegIndexingOptionsGenerateOnDemand`, `WICJpegIndexingOptionsGenerateOnLoad` | When a JPEG decoder builds its index: on demand, on load. | [WICJpegIndexingOptions](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicjpegindexingoptions) |
| `WICJpegTransferMatrix` | `WICJpegTransferMatrixIdentity`, `WICJpegTransferMatrixBT601` | JPEG colour transfer matrix: identity, BT.601. | [WICJpegTransferMatrix](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicjpegtransfermatrix) |
| `WICJpegScanType` | `WICJpegScanType*` | JPEG scan layout: interleaved, planar components, progressive. | [WICJpegScanType](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicjpegscantype) |
| `WICTiffCompressionOption` | `WICTiffCompression*` | TIFF encoder compression: none, CCITT, LZW, RLE, ZIP, LZWH differencing. | [WICTiffCompressionOption](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wictiffcompressionoption) |
| `WICJpegYCrCbSubsamplingOption` | `WICJpegYCrCbSubsampling*` | JPEG encoder chroma subsampling: 4:2:0, 4:2:2, 4:4:4, 4:4:0. | [WICJpegYCrCbSubsamplingOption](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicjpegycrcbsubsamplingoption) |
| `WICPngFilterOption` | `WICPngFilter*` | PNG encoder row filter: none, sub, up, average, Paeth, adaptive. | [WICPngFilterOption](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicpngfilteroption) |
| `WICHeifCompressionOption` | `WICHeifCompression*` | HEIF encoder compression: none, HEVC, AV1. | [WICHeifCompressionOption](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicheifcompressionoption) |
| `WICNamedWhitePoint` | `WICWhitePoint*` | Named white points for RAW development: daylight, cloudy, shade, tungsten … | [WICNamedWhitePoint](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicnamedwhitepoint) |
| `WICRawCapabilities` | `WICRawCapability*` | Whether a RAW setting can be read, set, or not at all. | [WICRawCapabilities](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicrawcapabilities) |
| `WICRawRotationCapabilities` | `WICRawRotationCapability*` | Which rotations a RAW codec supports. | [WICRawRotationCapabilities](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicrawrotationcapabilities) |
| `WICRawParameterSet` | `WICAsShotParameterSet`, `WICUserAdjustedParameterSet` … | RAW parameter sets: as shot, user adjusted, auto adjusted. | [WICRawParameterSet](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicrawparameterset) |
| `WICRawRenderMode` | `WICRawRenderMode*` | RAW rendering quality: draft, normal, best. | [WICRawRenderMode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicrawrendermode) |
| `WICDdsDimension` | `WICDdsTexture*` | DDS texture shape: 1D, 2D, 3D, cube. | [WICDdsDimension](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicddsdimension) |
| `WICDdsAlphaMode` | `WICDdsAlphaMode*` | DDS alpha interpretation: unknown, straight, premultiplied, opaque, custom. | [WICDdsAlphaMode](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ne-wincodec-wicddsalphamode) |

### Structures

| Type | Is | Microsoft Learn |
| --- | --- | --- |
| `WICRect` | A rectangle by position and size (`X`, `Y`, `Width`, `Height`), the area `CopyPixels` and `Lock` work on. | [WICRect](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicrect) |
| `WICBitmapPattern` | A byte pattern a decoder recognises at a file position. | [WICBitmapPattern](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicbitmappattern) |
| `WICImageParameters` | Pixel format, DPI and area used when encoding a Direct2D image. | [WICImageParameters](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicimageparameters) |
| `WICBitmapPlaneDescription` | Format and size of one plane of a planar image. | [WICBitmapPlaneDescription](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicbitmapplanedescription) |
| `WICBitmapPlane` | Format, buffer and stride of one plane. | [WICBitmapPlane](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicbitmapplane) |
| `WICJpegFrameHeader` | The header of a JPEG frame: size, transfer matrix, scan type, components. | [WICJpegFrameHeader](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicjpegframeheader) |
| `WICJpegScanHeader` | The header of a JPEG scan: components, restart interval, spectral selection. | [WICJpegScanHeader](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicjpegscanheader) |
| `WICRawCapabilitiesInfo` | Which RAW settings a codec supports. | [WICRawCapabilitiesInfo](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicrawcapabilitiesinfo) |
| `WICRawToneCurvePoint` | One point of a RAW tone curve. | [WICRawToneCurvePoint](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicrawtonecurvepoint) |
| `WICRawToneCurve` | A RAW tone curve: a count and its points. | [WICRawToneCurve](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicrawtonecurve) |
| `WICDdsParameters` | Size, depth, mip levels, array size, DXGI format, dimension and alpha mode of a DDS texture. | [WICDdsParameters](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicddsparameters) |
| `WICDdsFormatInfo` | DXGI format and block size of DDS data. | [WICDdsFormatInfo](https://learn.microsoft.com/en-us/windows/win32/api/wincodec/ns-wincodec-wicddsformatinfo) |

### Other types

| Type | Declared as | Is | Microsoft Learn |
| --- | --- | --- | --- |
| `LPCOMSTREAM` | `ComStream ptr` | A pointer to `ComStream`. | — |
| `ID2D1Device` | `ID2D1Device_` | The Direct2D device that `IWICImagingFactory2.CreateImageEncoder` takes; its methods are with Direct2D. | [ID2D1Device](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1/nn-d2d1_1-id2d1device) |
| `ID2D1Image` | `ID2D1Image_` | The Direct2D image an image encoder writes; its methods are with Direct2D. | [ID2D1Image](https://learn.microsoft.com/en-us/windows/win32/api/d2d1/nn-d2d1-id2d1image) |
| `WICColor` | `UINT32` | A palette colour, `&hAARRGGBB`. | — |
| `WICInProcPointer` | `byte ptr` | A pointer to bytes, as `IWICBitmapLock.GetDataPointer` returns. | — |

## Using the interfaces

A decoded frame converted to the pixel format Direct2D wants, ready for
`CreateBitmapFromWicBitmap`:

**Example**

```freebasic
dim pFactory as IWICImagingFactory ptr
CoCreateInstance( @CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER, @IID_IWICImagingFactory, @pFactory )
dim pFrame as IWICBitmapFrameDecode ptr        ' from IWICBitmapDecoder.GetFrame
dim pConverter as IWICFormatConverter ptr
pFactory->CreateFormatConverter( pConverter )
if pFrame then pConverter->Initialize( pFrame, IID_WICPixelFormat32bppPBGRA, WICBitmapDitherTypeNone, NULL, 0, WICBitmapPaletteTypeCustom )
```

Writing pixels through a lock:

**Example**

```freebasic
dim pFactory as IWICImagingFactory ptr, pBitmap as IWICBitmap ptr, pLock as IWICBitmapLock ptr
CoCreateInstance( @CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER, @IID_IWICImagingFactory, @pFactory )
pFactory->CreateBitmap( 8, 4, IID_WICPixelFormat32bppPBGRA, WICBitmapCacheOnLoad, pBitmap )
dim rc as WICRect = ( 0, 0, 8, 4 )
pBitmap->Lock( rc, WICBitmapLockWrite, *cast( IWICBitmapLock ptr, cast( any ptr, @pLock ) ) )
dim cb as UINT, pData as WICInProcPointer
pLock->GetDataPointer( cb, pData )            ' cb = 128: 8 x 4 pixels of 4 bytes
```

The second-version factory, with the identifier Windows registers:

**Example**

```freebasic
dim iid as GUID = ( &h7B816B45, &h1996, &h4476, { &hB1, &h32, &hDE, &h9E, &h24, &h7C, &h8A, &hF0 } )
dim pFactory2 as IWICImagingFactory2 ptr
CoCreateInstance( @CLSID_WICImagingFactory2, NULL, CLSCTX_INPROC_SERVER, @iid, @pFactory2 )
```

Microsoft Learn: [Windows Imaging Component](https://learn.microsoft.com/en-us/windows/win32/wic/-wic-lh),
[Native pixel formats](https://learn.microsoft.com/en-us/windows/win32/wic/-wic-codec-native-pixel-formats)

## See also

- [sys/win/direct2d](SysWin-Direct2D)
- [CID2D1RenderTarget](CID2D1RenderTarget) for `CreateBitmapFromWicBitmap`
- [CD2D1Factory](CD2D1Factory) for `CreateWicBitmapRenderTarget`
- [Direct2D bitmaps](SysWin-Direct2D-Bitmaps)
- [Direct2D interfaces](SysWin-Direct2D-Interfaces), [DirectWrite interfaces and types](SysWin-DirectWrite-Interfaces), [DXGI interfaces and types](SysWin-DXGI-Interfaces)
- [GDI+ images](SysWin-GdiPlus-Images) for loading and saving images with GDI+
- [COM procedures](SysWin-Com-Procedures)
