[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **CGraphCtx**

# CGraphCtx

Creates a graphic control: a child window that keeps and repaints what you draw on it.

The control owns an off-screen picture, the **virtual buffer**: a memory device context with a
DIB section selected into it, in the screen's colour depth (32 bits per pixel on current
displays). Draw on [GetMemDC](#getmemdc) with GDI, with a GDI+ `CGpGraphics`, or through a
Direct2D DC render target; the control copies the buffer to the screen whenever Windows asks it
to paint, so the drawing survives being covered, minimised or scrolled. Coordinates are pixels of
the buffer, (0, 0) at its top-left corner.

The buffer starts at the size of the control. It can be larger: then the control shows the part
that fits and adds scroll bars ([SetVirtualBufferSize](#setvirtualbuffersize)). Two properties
change how it is shown: [Stretchable](#stretchable) stretches the whole buffer over the control,
[Resizable](#resizable) makes the buffer follow the size of the control. They exclude each other.

**Repainting.** The control does not know when you have drawn. Before the window is shown nothing
is needed; afterwards call `InvalidateRect( pGraphCtx.hWindow(), NULL, false )` to show the new
picture.

**Background.** The first buffer is filled with the parent window's class background. After
that, the colour last passed to [Clear](#clear) fills any new area of the buffer and the part of
the control the buffer does not cover; until `Clear` is called that colour is black.

**Input.** The control takes all keystrokes: the arrow keys, Page Up, Page Down, Home and End
scroll the buffer (Ctrl with Left or Right scrolls a page), Tab and Shift+Tab move the focus,
Enter sends the parent `WM_COMMAND` with `IDOK` and Esc with `IDCANCEL`. The mouse wheel scrolls
up and down, or left and right with Ctrl. Clicks and focus changes reach the parent as
`WM_NOTIFY` with the control's id in `wParam` and `NMHDR.idFrom`, and one of `NM_CLICK`,
`NM_DBLCLK`, `NM_RCLICK`, `NM_RDBLCLK`, `NM_SETFOCUS` or `NM_KILLFOCUS` in `code`.
`WM_COMMAND` and `WM_NOTIFY` sent to the control are passed on to its parent.

**OpenGL.** With `"OPENGL"` as the caption the control also gets an OpenGL rendering context on
its memory device context ([SetPixelFormat](#setpixelformat), [CreateContext](#createcontext)).

**Lifetime.** The window class is `TK_GRAPHCTX`. The control's window keeps a pointer to the
object ([CGraphCtxPtr](#cgraphctxptr)) and its window procedure uses it, so the object must live
as long as the window. The destructor frees the buffer, the memory device context and the
OpenGL context; the window itself is destroyed with its parent.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus
```

## Example

A window filled by a graphic control that grows with it; an ellipse and a line of text are drawn
once into the buffer, a click sets the caption, and Esc closes the window:

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_GRCTX = 1001

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "GraphCtxDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Graphic control", @WndProc )
    pWindow.SetClientSize( 400, 260 )
    pWindow.Center

    ' a graphic control filling the client area, growing with the window
    dim pGraphCtx as CGraphCtx = CGraphCtx( @pWindow, IDC_GRCTX, "", 0, 0, pWindow.ClientWidth, pWindow.ClientHeight )
    pWindow.AnchorControl( pGraphCtx.hWindow, ANCHOR_HEIGHT_WIDTH )

    ' draw once into the buffer: the control repaints itself from it
    pGraphCtx.Clear( RGB_WHITE )
    dim hMemDC as HDC = pGraphCtx.GetMemDC()
    Ellipse( hMemDC, 20, 20, 220, 160 )
    dim wszText as wstring * 64 = "Click the picture"
    TextOutW( hMemDC, 240, 80, @wszText, len( wszText ) )

    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_NOTIFY
            dim phdr as NMHDR ptr = cast( NMHDR ptr, lParam )
            if phdr->idFrom = IDC_GRCTX andalso phdr->code = NM_CLICK then
                SetWindowText( hwnd, "Clicked" )
            end if
            return 0
        case WM_COMMAND
            ' Esc in the graphic control arrives as IDCANCEL
            if CBCTL( wParam, lParam ) = IDCANCEL then SendMessageW( hwnd, WM_CLOSE, 0, 0 )
            return 0
        case WM_DESTROY
            PostQuitMessage( 0 )
            return 0
    end select
    return DefWindowProcW( hwnd, uMsg, wParam, lParam )
end function

end main()
```

The buffer here keeps the size the control had when it was created: enlarging the window shows
the part beyond it in the [Clear](#clear) colour. Set [Resizable](#resizable) to make the buffer
follow the control, and redraw after each `WM_SIZE`.

## Members

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Registers the window class and creates the control and its buffer. |
| [Destructor](#destructor) | Frees the buffer, its device context and the OpenGL context. |
| [hWindow](#hwindow) | Returns the control's window handle. |
| [CGraphCtxProc](#cgraphctxproc) | The control's window procedure. |
| [SetVirtualBufferSize](#setvirtualbuffersize) | Gives the buffer a new size, keeping what is drawn. |
| [GetVirtualBufferWidth, GetVirtualBufferHeight](#getvirtualbufferwidth-getvirtualbufferheight) | Return the size of the buffer. |
| [GetMemDC](#getmemdc) | Returns the memory device context to draw on. |
| [GethBmp](#gethbmp) | Returns the buffer's bitmap. |
| [GetBits](#getbits) | Returns the pointer the class keeps for the buffer's pixels. |
| [GethRC](#gethrc) | Returns the OpenGL rendering context. |
| [Clear](#clear) | Fills the buffer with a colour and makes it the background colour. |
| [Stretchable](#stretchable) | Reads or sets whether the buffer is stretched over the control. |
| [StretchMode](#stretchmode) | Reads or sets how GDI stretches it. |
| [Resizable](#resizable) | Reads or sets whether the buffer follows the size of the control. |
| [LoadImageFromFile](#loadimagefromfile) | Loads an image file into the buffer. |
| [CreateBitmapFromFile](#createbitmapfromfile) | Loads an image file into the buffer, optionally dimmed or grey. |
| [LoadImageFromRes](#loadimagefromres) | Loads an image resource into the buffer. |
| [DrawBitmap](#drawbitmap) | Draws a bitmap onto the buffer. |
| [SaveImage](#saveimage) | Saves the buffer to a file in a format given by MIME type. |
| [SaveImageAsBmp, SaveImageAsJpeg, SaveImageAsPng, SaveImageAsGif, SaveImageAsTiff](#saveimageasbmp-saveimageasjpeg-saveimageaspng-saveimageasgif-saveimageastiff) | Save the buffer in one fixed format. |
| [PrintImage](#printimage) | Prints the buffer on the default printer. |
| [SetPixelFormat](#setpixelformat) | Sets an OpenGL pixel format on the memory device context. |
| [CreateContext](#createcontext) | Creates an OpenGL rendering context and makes it current. |
| [DeleteContext](#deletecontext) | Deletes the control's OpenGL rendering context. |
| [MakeCurrent, MakeNotCurrent](#makecurrent-makenotcurrent) | Direct OpenGL calls to this control, or to none. |
| [CGraphCtxPtr](#cgraphctxptr) | Returns the object of a graphic control from its window handle. |

## Reference

### Constructor

```freebasic
constructor( byval pWindow as CWindow ptr, byval cID as LONG_PTR, byref wszTitle as wstring = "", byval x as long = 0, byval y as long = 0, byval nWidth as long = 0, byval nHeight as long = 0, byval dwStyle as DWORD = 0, byval dwExStyle as DWORD = 0, byval lpParam as LONG_PTR = 0 )
constructor( byval hWin as HWND, byval cID as LONG_PTR, byref wszTitle as wstring = "", byval x as long = 0, byval y as long = 0, byval nWidth as long = 0, byval nHeight as long = 0, byval dwStyle as DWORD = 0, byval dwExStyle as DWORD = 0, byval lpParam as LONG_PTR = 0 )
```

Registers the `TK_GRAPHCTX` window class the first time, creates the control as a child of the
window through its `CWindow` ([AddControl](CWindow#addcontrol)), and creates a buffer the size of
the control's client area. Scroll bars start with ranges that match the buffer, and the stretch
mode is `HALFTONE`. The second form takes the handle of a window created with `CWindow` and
does nothing for `NULL` or any other window.

`x`, `y`, `nWidth` and `nHeight` are passed to `AddControl` as they are. A `dwStyle` of 0 means
`WS_VISIBLE or WS_TABSTOP`; `WS_CHILD` is always added. The caption `"OPENGL"` (in capitals) also
adds `WS_CLIPCHILDREN` and `WS_CLIPSIBLINGS`, and in any case it sets up OpenGL: a pixel format
for the screen's colour depth and a rendering context, made current.

| Parameter | Meaning |
| --- | --- |
| `pWindow` | The `CWindow` of the parent window. |
| `hWin` | The handle of a window created with `CWindow`. |
| `cID` | The control's id, used in its notifications. |
| `wszTitle` | The caption; `"OPENGL"` adds OpenGL support. |
| `x`, `y` | The position in the parent's client area. |
| `nWidth`, `nHeight` | The size of the control. |
| `dwStyle` | Window styles, or 0 for the defaults. |
| `dwExStyle` | Extended window styles. |
| `lpParam` | Passed to `CreateWindowExW` as its creation data. |

**Example**

```freebasic
dim pWindow as CWindow ptr = cast( CWindow ptr, GetWindowLongPtrW( hwnd, 0 ) )
dim pGraph as CGraphCtx = CGraphCtx( pWindow, 1001, "", 10, 10, 300, 200 )
dim pGL as CGraphCtx ptr = new CGraphCtx( hwnd, 1002, "OPENGL", 320, 10, 300, 200 )
```

Microsoft Learn: [CreateDIBSection](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createdibsection)

### Destructor

```freebasic
destructor
```

Selects the original bitmap back into the memory device context, makes no OpenGL context
current, deletes the rendering context, the buffer's bitmap and the memory device context. It
does not destroy the control's window.

**Example**

```freebasic
dim pGL as CGraphCtx ptr = new CGraphCtx( hwnd, 1002, "OPENGL", 0, 0, 300, 200 )
DestroyWindow( pGL->hWindow() )
delete pGL          ' the buffer and the OpenGL context are freed here
```

### hWindow

```freebasic
function hWindow() as HWND
```

Returns the control's window handle, for `InvalidateRect`, `AnchorControl`, `MoveWindow` and the
like.

**Returns** the handle, or `NULL` when the control could not be created.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
InvalidateRect( pGraphCtx->hWindow(), NULL, false )
```

### CGraphCtxProc

```freebasic
static function CGraphCtxProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
```

The window procedure of the `TK_GRAPHCTX` class; Windows calls it, you do not. It paints the
buffer, scrolls it, forwards notifications and handles the keys described in the intro. It finds
the object through [CGraphCtxPtr](#cgraphctxptr). Messages you send to the control arrive here.

**Returns** what each message expects; unhandled messages go to `DefWindowProcW`.

**Example**

```freebasic
dim pfn as WNDPROC = @CGraphCtx.CGraphCtxProc
print cast( any ptr, GetClassLongPtrW( hCtrl, GCLP_WNDPROC ) ) = cast( any ptr, pfn )
SendMessageW( hCtrl, WM_VSCROLL, SB_TOP, 0 )     ' scroll back to the top-left corner
```

### SetVirtualBufferSize

```freebasic
function SetVirtualBufferSize( byval nWidth as long, byval nHeight as long ) as long
```

Replaces the buffer with one of `nWidth` × `nHeight` pixels. What was drawn is copied into the
new buffer at its top-left corner, cut off if the new buffer is smaller, and new area is filled
with the background colour (see [Clear](#clear)). The memory device context, the bitmap and,
with OpenGL, the rendering context are all created anew: handles read earlier from
[GetMemDC](#getmemdc), [GethBmp](#gethbmp) and [GethRC](#gethrc) are no longer valid.

Unless the control is stretchable or resizable, a buffer larger than the parent's client area
adds scroll bars to the control, and a scroll bar that is not needed is hidden.

| Parameter | Meaning |
| --- | --- |
| `nWidth`, `nHeight` | The new size of the buffer in pixels. |

**Returns** `S_OK` (0).

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->SetVirtualBufferSize( 2000, 1500 )
dim hMemDC as HDC = pGraphCtx->GetMemDC()      ' read it again after a resize
```

### GetVirtualBufferWidth, GetVirtualBufferHeight

```freebasic
function GetVirtualBufferWidth() as long
function GetVirtualBufferHeight() as long
```

Return the width and height of the buffer in pixels: the control's client size at creation,
then whatever [SetVirtualBufferSize](#setvirtualbuffersize) or a loaded image made it.

**Returns** the size.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
print pGraphCtx->GetVirtualBufferWidth(); " x"; pGraphCtx->GetVirtualBufferHeight()
```

### GetMemDC

```freebasic
function GetMemDC() as HDC
```

Returns the memory device context that holds the buffer. Draw on it with any GDI call or wrap it
in a GDI+ `CGpGraphics`; the object owns it, so do not delete it, and do not select another
bitmap into it for good.

**Returns** the handle.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
Rectangle( pGraphCtx->GetMemDC(), 10, 10, 110, 60 )
InvalidateRect( hCtrl, NULL, false )
```

### GethBmp

```freebasic
function GethBmp() as HBITMAP
```

Returns the DIB section that holds the buffer's pixels. It stays owned by the object; copy it
(for example with `CopyImage`) to keep a picture beyond the next resize.

**Returns** the handle.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
dim ds as DIBSECTION
GetObjectW( pGraphCtx->GethBmp(), sizeof( ds ), @ds )
print ds.dsBm.bmWidth; " x"; ds.dsBm.bmHeight; ","; ds.dsBm.bmBitsPixel; " bits per pixel"
```

### GetBits

```freebasic
function GetBits() as any ptr
```

Returns the pointer the class keeps for the buffer's pixels.

**Returns** A pointer to the location of the DIB bit values.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
dim pBits as any ptr = pGraphCtx.GetBits
```

### GethRC

```freebasic
function GethRC() as HGLRC
```

Returns the OpenGL rendering context the control created.

**Returns** the handle, or `NULL` when the control was not created with `"OPENGL"` or setting up
OpenGL failed.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
if pGraphCtx->GethRC() = NULL then print "no OpenGL"
```

### Clear

```freebasic
function Clear( byval RGBColor as COLORREF ) as boolean
```

Fills the whole buffer with `RGBColor` and remembers it as the background colour, used for new
area and for the part of the control the buffer does not cover. It does not repaint the control.

| Parameter | Meaning |
| --- | --- |
| `RGBColor` | The colour, such as `RGB_WHITE` or `BGR( 240, 240, 240 )`. |

**Returns** `true` on success, `false` when there is no buffer.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->Clear( RGB_FLORALWHITE )
InvalidateRect( hCtrl, NULL, false )
```

Microsoft Learn: [FillRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-fillrect)

### Stretchable

```freebasic
property Stretchable() as boolean
property Stretchable( byval bStretchable as boolean )
```

Reads or sets whether the whole buffer is stretched over the control's client area, with
[StretchMode](#stretchmode), instead of being shown at its size and scrolled. Setting it also
turns [Resizable](#resizable) off. It takes effect at the next paint.

**Returns** (getter) `true` or `false`; `false` by default.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->Stretchable = true
InvalidateRect( hCtrl, NULL, false )
```

### StretchMode

```freebasic
property StretchMode() as long
property StretchMode( byval nStretchMode as long )
```

Reads or sets how a [stretchable](#stretchable) buffer is scaled: `HALFTONE` (the default,
averages pixels for the best picture), `COLORONCOLOR` (drops pixels, fast), `BLACKONWHITE` or
`WHITEONBLACK` (keep black or white pixels of monochrome pictures).

**Returns** (getter) the mode.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->StretchMode = COLORONCOLOR
```

Microsoft Learn: [SetStretchBltMode](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-setstretchbltmode)

### Resizable

```freebasic
property Resizable() as boolean
property Resizable( byval bResizable as boolean )
```

Reads or sets whether the buffer follows the size of the control: every `WM_SIZE` calls
[SetVirtualBufferSize](#setvirtualbuffersize) with the new client size. What was drawn is kept
up to the new size, so after shrinking and growing again part of the picture is gone: redraw it
on `WM_SIZE` in the parent. Setting it also turns [Stretchable](#stretchable) off.

**Returns** (getter) `true` or `false`; `false` by default.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->Resizable = true
```

### LoadImageFromFile

```freebasic
sub LoadImageFromFile( byref wszFileName as wstring )
```

Loads an image file with GDI+ (BMP, PNG, JPEG, GIF, TIFF, ICO and the other formats it reads),
sizes the buffer to the image, clears it with the background colour and draws the image. GDI+ is
started and shut down for the call. Nothing happens when the file cannot be read. The control is
not repainted.

GDI+ loads some black-and-white images with raised contrast; for an image without transparency,
[CreateBitmapFromFile](#createbitmapfromfile) avoids that.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The path of the image file. |

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->LoadImageFromFile( "photo.png" )
InvalidateRect( hCtrl, NULL, false )
```

Microsoft Learn: [Bitmap::FromFile](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-bitmap-fromfile)

### CreateBitmapFromFile

```freebasic
sub CreateBitmapFromFile( byref wszFileName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false )
```

Loads an image file into a GDI bitmap, optionally dimmed or turned grey, sizes the buffer to it,
clears the buffer with the background colour and copies the bitmap in. Transparent pixels come
out black. Nothing happens for an empty name or a file that cannot be read.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The path of the image file. |
| `dimPercent` | 1 to 99 lightens the image that far towards white; 0 leaves it. |
| `bGrayScale` | `true` turns it to shades of grey. |

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->CreateBitmapFromFile( "scan.jpg", 0, true )
InvalidateRect( hCtrl, NULL, false )
```

### LoadImageFromRes

```freebasic
sub LoadImageFromRes( byval hInst as HINSTANCE, byref wszImageName as wstring, byval dimPercent as long = 0, byval bGrayScale as long = false, byval clrBackground as ARGB = 0 )
```

Loads an image stored as an `RCDATA` resource (PNG, JPEG, GIF, TIFF …), like
[CreateBitmapFromFile](#createbitmapfromfile) does for a file.

| Parameter | Meaning |
| --- | --- |
| `hInst` | The module holding the resource; `NULL` means the program itself. |
| `wszImageName` | The resource name, or `"#"` and its number, as in `"#998"`. |
| `dimPercent` | 1 to 99 lightens the image that far towards white; 0 leaves it. |
| `bGrayScale` | `true` turns it to shades of grey. |
| `clrBackground` | The GDI+ `ARGB` colour transparent pixels take; ignored for an opaque image. |

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->LoadImageFromRes( GetModuleHandleW( NULL ), "#101", 0, false, ARGB_WHITE )
```

### DrawBitmap

```freebasic
function DrawBitmap( byval hbmp as HBITMAP, byval x as single = 0, byval y as single = 0 ) as GpStatus
function DrawBitmap( byval pBitmap as GpBitmap ptr, byval x as single = 0, byval y as single = 0, ) as GpStatus
function DrawBitmap( byref pMemBmp as CMemBmp, byval x as single = 0, byval y as single = 0 ) as GpStatus
```

Draws a GDI bitmap, a GDI+ bitmap or a [CMemBmp](CMemBmp) onto the buffer with GDI+, its
top-left corner at (`x`, `y`).

GDI+ must be running: call `gdiplus.Init()` first, or keep a GDI+ object alive. The bitmap you
pass stays yours.

| Parameter | Meaning |
| --- | --- |
| `hbmp` | A GDI bitmap. |
| `pBitmap` | A GDI+ bitmap. |
| `pMemBmp` | A memory bitmap. |
| `x`, `y` | Where the top-left corner goes. |
| `nRight`, `nBottom` | The width and height to stretch to, or 0 for the image's own size. |

**Returns** `Ok` (0) on success, `InvalidParameter` (2) for a `NULL` bitmap,
`GdiplusNotInitialized` (18) when GDI+ is not running, or another `GpStatus` code.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
dim token as ULONG_PTR = gdiplus.Init()
dim pic as CMemBmp = CMemBmp( "logo.png" )
pGraphCtx->DrawBitmap( pic, 10, 10 )               ' its own size
pGraphCtx->DrawBitmap( pic, 200, 10, 64, 64 )      ' stretched to 64 x 64
gdiplus.Uninit( token )
```

Microsoft Learn: [Graphics::DrawImage](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusgraphics/nf-gdiplusgraphics-graphics-drawimage%28image_real_real_real_real%29)

### SaveImage

```freebasic
function SaveImage( byref wszFileName as wstring, byref wszMimeType as wstring = "image/bmp" ) as long
```

Saves the whole buffer to `wszFileName` in the format named by `wszMimeType`; the file's
extension is not looked at. GDI+ is started and shut down for the call.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The file to write; an existing file is replaced. |
| `wszMimeType` | `"image/bmp"` (the default), `"image/png"`, `"image/jpeg"`, `"image/gif"` or `"image/tiff"`. |

**Returns** `Ok` (0) on success, `InvalidParameter` (2) for an empty file name, or another
`GpStatus` code.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
if pGraphCtx->SaveImage( "drawing.png", "image/png" ) <> Ok then print "not saved"
```

Microsoft Learn: [Image::Save](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-image-save%28constwchar_constclsid_constencoderparameters%29)

### SaveImageAsBmp, SaveImageAsJpeg, SaveImageAsPng, SaveImageAsGif, SaveImageAsTiff

```freebasic
function SaveImageAsBmp( byref wszFileName as wstring ) as long
function SaveImageAsJpeg( byref wszFileName as wstring ) as long
function SaveImageAsPng( byref wszFileName as wstring ) as long
function SaveImageAsGif( byref wszFileName as wstring ) as long
function SaveImageAsTiff( byref wszFileName as wstring ) as long
```

[SaveImage](#saveimage) with the MIME type fixed: `"image/bmp"`, `"image/jpeg"`, `"image/png"`,
`"image/gif"` and `"image/tiff"`.

**Returns** `Ok` (0) on success, otherwise a `GpStatus` code.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->SaveImageAsPng( "drawing.png" )
pGraphCtx->SaveImageAsJpeg( "drawing.jpg" )
```

### PrintImage

```freebasic
function PrintImage( byval bStretch as boolean = false, byval nStretchMode as long = InterpolationModeHighQualityBicubic ) as boolean
```

Prints the buffer on the default printer, in a print job named "Printing bitmap", once for each
copy the printer is set to print, without showing a dialog. With `bStretch` the picture fills the
printable area; otherwise it is drawn at its own size in the top-left corner. GDI+ is started
and shut down for the call.

| Parameter | Meaning |
| --- | --- |
| `bStretch` | `true` stretches the picture over the page. |
| `nStretchMode` | How GDI+ scales it: an `InterpolationMode*` value, `InterpolationModeHighQualityBicubic` (7) by default. |

**Returns** `true` when the job was sent, `false` when there is no default printer or printing
could not start.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
if pGraphCtx->PrintImage( true, InterpolationModeNearestNeighbor ) = false then print "not printed"
```

### SetPixelFormat

```freebasic
function SetPixelFormat( byval nBitsPerPel as long ) as boolean
```

Chooses and sets a pixel format on the memory device context that supports OpenGL and GDI
drawing, RGBA, with `nBitsPerPel` colour bits and a depth buffer of `nBitsPerPel - 8` bits
(at least 16). The constructor and [SetVirtualBufferSize](#setvirtualbuffersize) call it for an
OpenGL control. A device context takes a pixel format only once.

When no format matches or it cannot be set, a message box says so before the call returns.

| Parameter | Meaning |
| --- | --- |
| `nBitsPerPel` | The colour depth, normally the screen's: 32. |

**Returns** `true` when the format was set, `false` otherwise.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
if pGraphCtx->GethRC() = NULL andalso pGraphCtx->SetPixelFormat( 32 ) then pGraphCtx->CreateContext()
```

Microsoft Learn: [ChoosePixelFormat](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-choosepixelformat), [SetPixelFormat](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-setpixelformat)

### CreateContext

```freebasic
function CreateContext() as HGLRC
```

Creates an OpenGL rendering context for the memory device context and makes it current. The
constructor keeps the context it creates this way (see [GethRC](#gethrc)); a context from a call
of your own is not kept, so delete it yourself with `wglDeleteContext`. A message box reports a
failure.

**Returns** the rendering context, or `NULL` on failure.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
dim hRC as HGLRC = pGraphCtx->CreateContext()
' ... draw with OpenGL ...
wglMakeCurrent( NULL, NULL )
wglDeleteContext( hRC )
```

Microsoft Learn: [wglCreateContext](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-wglcreatecontext)

### DeleteContext

```freebasic
function DeleteContext() as boolean
```

Deletes the rendering context the control keeps ([GethRC](#gethrc)). The handle stays stored, so
the destructor tries to delete it again; let the destructor do it rather than calling this.

**Returns** `true` when the context was deleted.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
pGraphCtx->MakeNotCurrent()
pGraphCtx->DeleteContext()
```

Microsoft Learn: [wglDeleteContext](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-wgldeletecontext)

### MakeCurrent, MakeNotCurrent

```freebasic
function MakeCurrent() as boolean
function MakeNotCurrent() as boolean
```

`MakeCurrent` makes the control's rendering context the thread's current one, so that OpenGL
calls draw into this control's buffer; call it before drawing when there are several OpenGL
controls. `MakeNotCurrent` leaves the thread with no current context for this device context.

**Returns** `true` on success, `false` otherwise.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( hCtrl )
if pGraphCtx->MakeCurrent() then
    glClearColor( 0, 0, 0.5, 1 )
    glClear( GL_COLOR_BUFFER_BIT )
    glFlush()
    pGraphCtx->MakeNotCurrent()
end if
InvalidateRect( hCtrl, NULL, false )
```

Microsoft Learn: [wglMakeCurrent](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-wglmakecurrent)

### CGraphCtxPtr

```freebasic
function CGraphCtxPtr( byval hwnd as HWND ) as CGraphCtx ptr
```

Returns the object of a graphic control from its window handle: the pointer stored in the
window's first extra bytes. Pass only the handle of a `TK_GRAPHCTX` control; for any other
window the result is whatever that window keeps there (a `CWindow` window keeps its own object).

| Parameter | Meaning |
| --- | --- |
| `hwnd` | The graphic control, as returned by [hWindow](#hwindow) or `GetDlgItem`. |

**Returns** the object.

**Example**

```freebasic
dim pGraphCtx as CGraphCtx ptr = CGraphCtxPtr( GetDlgItem( hwnd, 1001 ) )
if pGraphCtx then pGraphCtx->Clear( RGB_BLACK )
```

Microsoft Learn: [GetWindowLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowlongptrw)

## See also

- [CMemBmp](CMemBmp), an off-screen bitmap `DrawBitmap` can display
- [CWindow](CWindow) for the parent window and `AnchorControl`
- [CGpGraphics](CGpGraphics) for drawing on the memory device context with GDI+
- [Direct2D render targets](SysWin-Direct2D-Render-Targets) for drawing on it with a Direct2D DC render target
- [GDI+ images](SysWin-GdiPlus-Images) for `BitmapFromFile` and the image helpers the loaders use
- [sys/win/gui](SysWin-Gui)
