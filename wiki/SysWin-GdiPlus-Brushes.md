[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gdiplus](SysWin-GdiPlus) › **GDI+ brushes**

# GDI+ brushes
Fills shapes and text in GDI+ with a colour, a hatch pattern, an image or a gradient.

<!-- scope: CGpBrush -->
<!-- scope: CGpSolidBrush -->
<!-- scope: CGpHatchBrush -->
<!-- scope: CGpTextureBrush -->
<!-- scope: CGpLinearGradientBrush -->
<!-- scope: CGpPathGradientBrush -->

Fills shapes and text in GDI+ with a colour, a hatch pattern, an image or a gradient.

Every `Fill…` method of [CGpGraphics](CGpGraphics), and `DrawString`, takes a brush by address:
`graphics.FillRectangle( @brush, 10, 10, 100, 50 )`. A [CGpPen](CGpPen) can stroke with a brush
too. There are five kinds, one class each, all derived from `CGpBrush`:

| Class | Fills with | [GetType](#gettype) |
| --- | --- | --- |
| [CGpSolidBrush](#cgpsolidbrush) | one colour, which may be partly transparent | `BrushTypeSolidColor` (0) |
| [CGpHatchBrush](#cgphatchbrush) | a two-colour pattern of lines, dots or checks | `BrushTypeHatchFill` (1) |
| [CGpTextureBrush](#cgptexturebrush) | an image, repeated | `BrushTypeTextureFill` (2) |
| [CGpPathGradientBrush](#cgppathgradientbrush) | colours that blend from the centre of a shape out to its edge | `BrushTypePathGradient` (3) |
| [CGpLinearGradientBrush](#cgplineargradientbrush) | colours that blend along a line | `BrushTypeLinearGradient` (4) |

**Lifetime.** Each object wraps one GDI+ brush, which its constructor creates and the
`CGpBrush` destructor deletes. Graphics objects and pens that are given a brush use it during the
call or keep their own copy, and a texture brush keeps its own copy of the image, so the brush
and the image can go out of scope afterwards. Never copy a brush by value (`dim b as
CGpSolidBrush = a`, or a `byval` parameter): the copy holds the same GDI+ object and deletes it
when it goes. Pass the address instead, `dim b as CGpSolidBrush = @a`, or use [Clone](#clone).

**Coordinates.** Gradients and textures are laid out in the coordinates of the graphics object
they fill, not of the shape: a linear gradient from x = 0 to x = 100 repeats every 100 units
across the whole surface, wherever the shape is. Texture and gradient brushes have their own
transformation as well, which moves, scales and turns the pattern; see [CGpMatrix](CGpMatrix)
for the order rules.

**Status.** The methods return a `GpStatus`: `Ok` (0) on success, otherwise the reason, such as
`InvalidParameter` (2), `InsufficientBuffer` (5) or `NotImplemented` (6). The status is also
stored, and `GetLastStatus()`, which every `CGp*` class inherits, returns it; getters that return
a value store theirs too. Calls that take a pointer to a `CGpMatrix`, `CGpImage` or
`CGpGraphicsPath` read that object, so the pointer must not be `NULL` unless the entry says so.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus
```

## Example

A window that fills five shapes, one with each kind of brush. The texture is a small bitmap
painted at start-up:

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim token as ULONG_PTR = gdiplus.Init()
    dim pWindow as CWindow = "BrushDemo"
    pWindow.Create( NULL, "GDI+ brushes", @WndProc )
    pWindow.SetClientSize( 400, 250 )
    pWindow.Center()
    dim nResult as long = pWindow.DoEvents( SW_NORMAL )
    gdiplus.Uninit( token )
    return nResult
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_PAINT
            dim ps as PAINTSTRUCT
            dim hdc as HDC = BeginPaint( hwnd, @ps )
            scope
                dim graphics as CGpGraphics = hdc
                graphics.SetSmoothingMode( SmoothingModeAntiAlias )
                graphics.Clear( ARGB_WHITE )
                graphics.ScaleTransformForDpi()

                dim solid as CGpSolidBrush = CGpSolidBrush( &h80FF0000 )     ' half-transparent red
                graphics.FillRectangle( @solid, 20, 20, 100, 90 )

                dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleDiagonalCross, ARGB_NAVY, ARGB_LIGHTYELLOW )
                graphics.FillRectangle( @hatch, 150, 20, 100, 90 )

                dim tile as CGpBitmap = CGpBitmap( 16, 16 )
                scope
                    dim g as CGpGraphics = CGpGraphics( @tile )
                    dim dark as CGpSolidBrush = CGpSolidBrush( ARGB_DARKGREEN )
                    g.Clear( ARGB_PALEGREEN )
                    g.FillRectangle( @dark, 0, 0, 8, 8 )
                    g.FillRectangle( @dark, 8, 8, 8, 8 )
                end scope
                dim texture as CGpTextureBrush = CGpTextureBrush( @tile )
                graphics.FillEllipse( @texture, 280, 20, 100, 90 )

                dim p1 as GpPointF = type<GpPointF>( 20, 0 )
                dim p2 as GpPointF = type<GpPointF>( 180, 0 )
                dim linear as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_GOLD, ARGB_PURPLE )
                graphics.FillRectangle( @linear, 20, 140, 160, 90 )

                dim path as CGpGraphicsPath
                path.AddEllipse( 230, 140, 150, 90 )
                dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @path )
                radial.SetCenterColor( ARGB_WHITE )
                dim edge as ARGB = ARGB_STEELBLUE
                dim nEdge as INT_ = 1
                radial.SetSurroundColors( @edge, @nEdge )
                graphics.FillPath( @radial, @path )
            end scope
            EndPaint( hwnd, @ps )
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

| Member | Does |
| --- | --- |
| **CGpBrush** | |
| [Constructor](#constructor) | Creates an empty object or a copy of any brush. |
| [Destructor](#destructor) | Deletes the GDI+ brush. |
| [Clone](#clone) | Copies this brush into another object. |
| [GetType](#gettype) | Tells which kind of brush the object holds. |
| **CGpSolidBrush** | |
| [Constructor](#constructor-1) | Creates a brush of one colour, or a copy. |
| [GetColor](#getcolor) | Reads the colour. |
| [SetColor](#setcolor) | Changes the colour. |
| **CGpHatchBrush** | |
| [Constructor](#constructor-2) | Creates a brush of a hatch pattern in two colours, or a copy. |
| [GetHatchStyle](#gethatchstyle) | Returns the pattern. |
| [GetForegroundColor](#getforegroundcolor) | Reads the colour of the pattern. |
| [GetBackgroundColor](#getbackgroundcolor) | Reads the colour behind the pattern. |
| **CGpTextureBrush** | |
| [Constructor](#constructor-3) | Creates a brush that tiles an image or part of one, or a copy. |
| [SetTransform](#settransform) | Replaces the brush's transformation. |
| [GetTransform](#gettransform) | Reads the brush's transformation. |
| [ResetTransform](#resettransform) | Makes the transformation the identity. |
| [MultiplyTransform](#multiplytransform) | Combines the transformation with a matrix. |
| [TranslateTransform](#translatetransform) | Adds a move. |
| [ScaleTransform](#scaletransform) | Adds a scaling. |
| [RotateTransform](#rotatetransform) | Adds a rotation. |
| [SetWrapMode](#setwrapmode) | Sets how the tiles are laid. |
| [GetWrapMode](#getwrapmode) | Reads how the tiles are laid. |
| [GetImage](#getimage) | Reads a copy of the image. |
| **CGpLinearGradientBrush** | |
| [Constructor](#constructor-4) | Creates a gradient between two points or across a rectangle, or a copy. |
| [SetLinearColors](#setlinearcolors) | Replaces the start and end colours. |
| [GetLinearColors](#getlinearcolors) | Reads the start and end colours. |
| [GetRectangle](#getrectangle) | Reads the rectangle one repeat spans. |
| [SetGammaCorrection](#setgammacorrection) | Turns gamma correction on or off. |
| [GetGammaCorrection](#getgammacorrection) | Tells whether gamma correction is on. |
| [GetBlendCount](#getblendcount) | Returns the number of blend factors. |
| [SetBlend](#setblend) | Sets how fast the colours change along the gradient. |
| [GetBlend](#getblend) | Reads the blend. |
| [GetInterpolationColorCount](#getinterpolationcolorcount) | Returns the number of interpolation colours. |
| [SetInterpolationColors](#setinterpolationcolors) | Makes the gradient pass through several colours. |
| [GetInterpolationColors](#getinterpolationcolors) | Reads the interpolation colours. |
| [SetBlendBellShape](#setblendbellshape) | Sets a bell-shaped blend. |
| [SetBlendTriangularShape](#setblendtriangularshape) | Sets a triangular blend. |
| [SetTransform](#settransform-1) | Replaces the brush's transformation. |
| [GetTransform](#gettransform-1) | Reads the brush's transformation. |
| [ResetTransform](#resettransform-1) | Makes the transformation the identity. |
| [MultiplyTransform](#multiplytransform-1) | Combines the transformation with a matrix. |
| [TranslateTransform](#translatetransform-1) | Adds a move. |
| [ScaleTransform](#scaletransform-1) | Adds a scaling. |
| [RotateTransform](#rotatetransform-1) | Adds a rotation. |
| [SetWrapMode](#setwrapmode-1) | Sets how the gradient repeats. |
| [GetWrapMode](#getwrapmode-1) | Reads how the gradient repeats. |
| **CGpPathGradientBrush** | |
| [Constructor](#constructor-5) | Creates a gradient inside a polygon or path, or a copy. |
| [GetCenterColor](#getcentercolor) | Reads the colour at the centre. |
| [SetCenterColor](#setcentercolor) | Sets the colour at the centre. |
| [GetPointCount](#getpointcount) | Returns the number of boundary points. |
| [GetSurroundColorCount](#getsurroundcolorcount) | Returns the size of array the surround colours need. |
| [GetSurroundColors](#getsurroundcolors) | Reads the colours at the boundary. |
| [SetSurroundColors](#setsurroundcolors) | Sets the colours at the boundary. |
| [GetGraphicsPath](#getgraphicspath) | Is meant to read the boundary path; not implemented. |
| [SetGraphicsPath](#setgraphicspath) | Is meant to replace the boundary path; not implemented. |
| [GetCenterPoint](#getcenterpoint) | Reads the centre point. |
| [SetCenterPoint](#setcenterpoint) | Moves the centre point. |
| [GetRectangle](#getrectangle-1) | Reads the rectangle around the boundary. |
| [SetGammaCorrection](#setgammacorrection-1) | Turns gamma correction on or off. |
| [GetGammaCorrection](#getgammacorrection-1) | Tells whether gamma correction is on. |
| [GetBlendCount](#getblendcount-1) | Returns the number of blend factors. |
| [GetBlend](#getblend-1) | Reads the blend. |
| [SetBlend](#setblend-1) | Sets how fast the colours change from edge to centre. |
| [GetInterpolationColorCount](#getinterpolationcolorcount-1) | Returns the number of interpolation colours. |
| [SetInterpolationColors](#setinterpolationcolors-1) | Makes the gradient pass through several colours. |
| [GetInterpolationColors](#getinterpolationcolors-1) | Reads the interpolation colours. |
| [SetBlendBellShape](#setblendbellshape-1) | Sets a bell-shaped blend. |
| [SetBlendTriangularShape](#setblendtriangularshape-1) | Sets a triangular blend. |
| [GetTransform](#gettransform-2) | Reads the brush's transformation. |
| [SetTransform](#settransform-2) | Replaces the brush's transformation. |
| [ResetTransform](#resettransform-2) | Makes the transformation the identity. |
| [MultiplyTransform](#multiplytransform-2) | Combines the transformation with a matrix. |
| [TranslateTransform](#translatetransform-2) | Adds a move. |
| [ScaleTransform](#scaletransform-2) | Adds a scaling. |
| [RotateTransform](#rotatetransform-2) | Adds a rotation. |
| [GetFocusScales](#getfocusscales) | Reads the size of the solid centre patch. |
| [SetFocusScales](#setfocusscales) | Widens the centre into a patch of solid colour. |
| [GetWrapMode](#getwrapmode-2) | Reads how the brush repeats outside the boundary. |
| [SetWrapMode](#setwrapmode-2) | Sets how the brush repeats outside the boundary. |

## Reference

## CGpBrush

The base class. A `CGpBrush` can hold a brush of any kind, which makes it the type to receive a
copy whose kind you do not know in advance, as [CGpPen](CGpPen) `GetBrush` does. Every brush
class inherits [Clone](#clone) and [GetType](#gettype) from it.

### Constructor

```freebasic
constructor
constructor( byval pBrush as CGpBrush ptr )
```

With no argument the object holds no brush: [GetType](#gettype) returns -1 and other calls fail
with `InvalidParameter` until [Clone](#clone) fills it. With a pointer to any brush it holds an
independent copy of that brush, of the same kind. The pointer must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pBrush` | The brush to copy. |

**Example**

```freebasic
dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleCross, ARGB_RED, ARGB_WHITE )
dim copy as CGpBrush = @hatch
print copy.GetType()                                ' 1
```

Microsoft Learn: [Brush](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nl-gdiplusbrush-brush)

### Destructor

```freebasic
destructor
```

Deletes the GDI+ brush, whatever its kind. The derived classes have no destructor of their own.

**Example**

```freebasic
dim pBrush as CGpSolidBrush ptr = new CGpSolidBrush( ARGB_BLUE )
print hex( pBrush->GetColor() )                     ' FF0000FF
delete pBrush
```

### Clone

```freebasic
function Clone( byval pBrush as CGpBrush ptr ) as GpStatus
```

Copies this brush into the existing object that `pBrush` points to. The GDI+ brush the target
held is deleted first. The target may be a plain `CGpBrush` or an object of the same class as
this one; giving a solid brush the copy of a hatch brush leaves an object whose methods do not
match what it holds.

| Parameter | Meaning |
| --- | --- |
| `pBrush` | The object that receives the copy. |

**Returns** `Ok` on success; `InvalidParameter` when `pBrush` is `NULL`.

**Example**

```freebasic
dim red as CGpSolidBrush = CGpSolidBrush( ARGB_RED )
dim copy as CGpBrush
if red.Clone( @copy ) = Ok then print copy.GetType()   ' 0
```

Microsoft Learn: [Brush::Clone](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-brush-clone)

### GetType

```freebasic
function GetType() as GpBrushType
```

Tells what kind of brush the object holds.

**Returns** `BrushTypeSolidColor` (0), `BrushTypeHatchFill` (1), `BrushTypeTextureFill` (2),
`BrushTypePathGradient` (3) or `BrushTypeLinearGradient` (4); -1 when the object holds no brush.

**Example**

```freebasic
dim empty as CGpBrush
dim blue as CGpSolidBrush = CGpSolidBrush( ARGB_BLUE )
print empty.GetType(); blue.GetType()               ' -1 0
```

Microsoft Learn: [Brush::GetType](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-brush-gettype)

## CGpSolidBrush

Fills with one colour. The alpha byte of the colour makes the fill partly transparent:
`&h80FF0000` is half-transparent red.

### Constructor

```freebasic
constructor( byval pSolidBrush as CGpSolidBrush ptr )
constructor( byval colour as ARGB = &hFF000000 )
```

Creates a solid brush of `colour` (opaque black when it is left out), or an independent copy of
another solid brush. The pointer must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pSolidBrush` | The brush to copy. |
| `colour` | An ARGB colour. |

**Example**

```freebasic
dim red as CGpSolidBrush = CGpSolidBrush( ARGB_RED )
dim black as CGpSolidBrush
print hex( red.GetColor() ); " "; hex( black.GetColor() )   ' FFFF0000 FF000000
```

Microsoft Learn: [SolidBrush::SolidBrush](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-solidbrush-solidbrush%28constcolor_%29)

### GetColor

```freebasic
function GetColor( byval colour as ARGB ptr ) as GpStatus
function GetColor() as ARGB
```

Reads the brush's colour: the first form stores it in the `ARGB` that `colour` points to and
returns the status, the second returns the colour.

| Parameter | Meaning |
| --- | --- |
| `colour` | The variable that receives the colour. |

**Returns** the status, or the colour.

**Example**

```freebasic
dim green as CGpSolidBrush = CGpSolidBrush( ARGB_GREEN )
dim c as ARGB
green.GetColor( @c )
print hex( c ); " "; hex( green.GetColor() )        ' FF008000 FF008000
```

Microsoft Learn: [SolidBrush::GetColor](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-solidbrush-getcolor)

### SetColor

```freebasic
function SetColor( byval colour as ARGB ) as GpStatus
```

Changes the brush's colour. One brush can fill many shapes in turn, with a `SetColor` between
them.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim brush as CGpSolidBrush
brush.SetColor( &h80FF0000 )
print hex( brush.GetColor() )                       ' 80FF0000
```

Microsoft Learn: [SolidBrush::SetColor](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-solidbrush-setcolor)

## CGpHatchBrush

Fills with a small repeating pattern in a foreground colour on a background colour. The
`HatchStyle` constants name more than fifty patterns: `HatchStyleHorizontal`,
`HatchStyleVertical`, `HatchStyleCross`, `HatchStyleDiagonalCross`, `HatchStyleForwardDiagonal`,
`HatchStyleDottedGrid`, `HatchStyleLargeCheckerBoard`, `HatchStyleHorizontalBrick` and so on, from
`HatchStyleMin` to `HatchStyleMax`.

### Constructor

```freebasic
constructor( byval pHatchBrush as CGpHatchBrush ptr )
constructor( byval nHatchStyle as HatchStyle, byval foreColor as ARGB, byval backColor as ARGB = &HFF000000 )
```

Creates a hatch brush, or an independent copy of another one. The background is opaque black
when it is left out. The pointer must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pHatchBrush` | The brush to copy. |
| `nHatchStyle` | A `HatchStyle` constant. |
| `foreColor` | The colour of the lines or dots. |
| `backColor` | The colour between them; use a transparent colour such as `&h00000000` to let the background show. |

**Example**

```freebasic
dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleDiagonalCross, ARGB_NAVY, ARGB_WHITE )
print hatch.GetHatchStyle()                         ' 5
```

Microsoft Learn: [HatchBrush::HatchBrush](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-hatchbrush-hatchbrush%28hatchstyle_constcolor__constcolor_%29)

### GetHatchStyle

```freebasic
function GetHatchStyle() as HatchStyle
```

Returns the brush's pattern.

**Returns** the `HatchStyle`.

**Example**

```freebasic
dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleCross, ARGB_RED, ARGB_WHITE )
print hatch.GetHatchStyle()                         ' 4
```

Microsoft Learn: [HatchBrush::GetHatchStyle](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-hatchbrush-gethatchstyle)

### GetForegroundColor

```freebasic
function GetForegroundColor( byval colour as ARGB ptr ) as GpStatus
function GetForegroundColor() as ARGB
```

The first form stores the foreground colour in the `ARGB` that `colour` points to. The form
without an argument returns the colour.

| Parameter | Meaning |
| --- | --- |
| `colour` | The variable that receives the colour. |

**Returns** the colour.

**Example**

```freebasic
dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleCross, ARGB_RED, ARGB_WHITE )
dim c as ARGB
hatch.GetForegroundColor( @c )
print hex( c )                                      ' FFFF0000
```

Microsoft Learn: [HatchBrush::GetForegroundColor](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-hatchbrush-getforegroundcolor)

### GetBackgroundColor

```freebasic
function GetBackgroundColor( byval colour as ARGB ptr ) as GpStatus
function GetBackgroundColor() as ARGB
```

The same for the background colour: the first form stores it in the variable `colour` points
to; the form without an argument returns the colour.

| Parameter | Meaning |
| --- | --- |
| `colour` | The variable that receives the colour. |

**Returns** the colour.

**Example**

```freebasic
dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleHorizontal, ARGB_RED )
dim c as ARGB
hatch.GetBackgroundColor( @c )
print hex( c )                                      ' FF000000
```

Microsoft Learn: [HatchBrush::GetBackgroundColor](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-hatchbrush-getbackgroundcolor)

## CGpTextureBrush

Fills with an image, a [CGpBitmap](SysWin-GdiPlus-Images) or any other `CGpImage`, laid edge to
edge across the surface. The brush keeps its own copy of the image. The wrap mode says how the
copies meet: `WrapModeTile` (the default for every constructor that does not take one) repeats
the image as it is; `WrapModeTileFlipX`, `WrapModeTileFlipY` and `WrapModeTileFlipXY` mirror
every other copy so the edges match; `WrapModeClamp` draws the image once and nothing around it.

### Constructor

```freebasic
constructor( byval pTextureBrush as CGpTextureBrush ptr )
constructor( byval pImage as CGpImage ptr, byval nWrapMode as wrapMode = WrapModeTile )
constructor( byval pImage as CGpImage ptr, byval dstRect as GpRectF ptr, byval pImageAttributes as CGpImageAttributes_ ptr = NULL )
constructor( byval pImage as CGpImage ptr, byval dstRect as GpRect ptr, byval pImageAttributes as CGpImageAttributes_ ptr = NULL )
constructor( byval pImage as CGpImage ptr, byval nWrapMode as wrapMode, byval dstRect as GpRect ptr )
constructor( byval pImage as CGpImage ptr, byval nWrapMode as wrapMode, byval dstRect as GpRectF ptr )
constructor( byval pImage as CGpImage ptr, byval nWrapMode as wrapMode, byval dstX as single, byval dstY as single, byval dstWidth as single, byval dstHeight as single )
```

Creates a texture brush from an image, or an independent copy of another texture brush.

- With an image (and a wrap mode), the whole image is the tile.
- With a rectangle, only that part of the image, in image pixels, is the tile.
- With image attributes ([CGpImageAttributes](CGpImageAttributes)), their colour adjustments are
  applied to the tile once, when the brush is made. `NULL` (the default) applies none.

| Parameter | Meaning |
| --- | --- |
| `pTextureBrush` | The brush to copy; must not be `NULL`. |
| `pImage` | The image. |
| `nWrapMode` | How the tiles are laid. |
| `dstRect`, `dstX` … `dstHeight` | The part of the image to use. |
| `pImageAttributes` | Colour adjustments, or `NULL`. |

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim part as GpRectF = type<GpRectF>( 0, 0, 8, 8 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp, WrapModeTileFlipXY, @part )
print tile.GetLastStatus(); tile.GetWrapMode()      ' 0 3
```

Microsoft Learn: [TextureBrush::TextureBrush](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-texturebrush%28image_wrapmode_constrectf_%29)

### SetTransform

```freebasic
function SetTransform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Replaces the brush's transformation with a copy of a matrix: the tiles are moved, scaled and
turned by it. `NULL` returns `InvalidParameter`.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
dim m as CGpMatrix = CGpMatrix( 2, 0, 0, 2, 0, 0 )
print tile.SetTransform( @m )                       ' 0
```

Microsoft Learn: [TextureBrush::SetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-settransform)

### GetTransform

```freebasic
function GetTransform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Copies the brush's transformation into an existing [CGpMatrix](CGpMatrix).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
tile.TranslateTransform( 5, 0 )
dim m as CGpMatrix
tile.GetTransform( @m )
print m.OffsetX()                                   ' 5
```

Microsoft Learn: [TextureBrush::GetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-gettransform)

### ResetTransform

```freebasic
function ResetTransform() as GpStatus
```

Makes the brush's transformation the identity again.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
tile.RotateTransform( 45 )
tile.ResetTransform()
```

Microsoft Learn: [TextureBrush::ResetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-resettransform)

### MultiplyTransform

```freebasic
function MultiplyTransform( byval pMatrix as CGpMatrix ptr, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Combines the brush's transformation with a matrix, before (`MatrixOrderPrepend`, the default)
or after (`MatrixOrderAppend`) what it already holds. `NULL` leaves the transformation as it is.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
dim m as CGpMatrix = CGpMatrix( 1, 0, 0, 1, 4, 4 )
tile.MultiplyTransform( @m, MatrixOrderAppend )
```

Microsoft Learn: [TextureBrush::MultiplyTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-multiplytransform)

### TranslateTransform

```freebasic
function TranslateTransform( byval dx as single, byval dy as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a move by (`dx`, `dy`) to the brush's transformation: the tiles start at a different
point.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
tile.TranslateTransform( 8, 8 )
```

Microsoft Learn: [TextureBrush::TranslateTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-translatetransform)

### ScaleTransform

```freebasic
function ScaleTransform( byval sx as single, byval sy as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a scaling to the brush's transformation: `2, 2` draws each tile twice as large.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
tile.ScaleTransform( 2, 2 )
```

Microsoft Learn: [TextureBrush::ScaleTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-scaletransform)

### RotateTransform

```freebasic
function RotateTransform( byval angle as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a rotation by `angle` degrees to the brush's transformation.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
tile.RotateTransform( 30 )
```

Microsoft Learn: [TextureBrush::RotateTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-rotatetransform)

### SetWrapMode

```freebasic
function SetWrapMode( byval nWrapMode as wrapMode ) as GpStatus
```

Changes how the tiles are laid; see the start of this section.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
tile.SetWrapMode( WrapModeTileFlipXY )
```

Microsoft Learn: [TextureBrush::SetWrapMode](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-setwrapmode)

### GetWrapMode

```freebasic
function GetWrapMode() as wrapMode
```

Returns how the tiles are laid.

**Returns** the `WrapMode`: `WrapModeTile` (0) unless one was given.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 16, 16 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp, WrapModeClamp )
print tile.GetWrapMode()                            ' 4
```

Microsoft Learn: [TextureBrush::GetWrapMode](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-getwrapmode)

### GetImage

```freebasic
function GetImage( byval pImage as CGpImage ptr ) as GpStatus
```

Puts a copy of the brush's image into the `CGpImage` (or `CGpBitmap`) that `pImage` points to,
which then owns it. An image the object held before is disposed of first.

| Parameter | Meaning |
| --- | --- |
| `pImage` | The object that receives the copy. |

**Returns** `Ok` on success; `InvalidParameter` when `pImage` is `NULL`.

**Example**

```freebasic
dim bmp as CGpBitmap = CGpBitmap( 8, 6 )
dim tile as CGpTextureBrush = CGpTextureBrush( @bmp )
dim img as CGpImage
if tile.GetImage( @img ) = Ok then print img.GetWidth(); " x "; img.GetHeight()   ' 8 x 6
```

Microsoft Learn: [TextureBrush::GetImage](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-texturebrush-getimage)

## CGpLinearGradientBrush

Fills with colours that change along a line. The gradient runs from a start colour at one
boundary line to an end colour at the other, both at right angles to its direction, and
repeats beyond them; the wrap mode says how. A blend ([SetBlend](#setblend)) bends how fast the
colours change, and interpolation colours ([SetInterpolationColors](#setinterpolationcolors))
put more than two colours along the way.

### Constructor

```freebasic
constructor( byval pLinearGradientBrush as CGpLinearGradientBrush ptr )
constructor( byval point1 as GpPointF ptr, byval point2 as GpPointF ptr, byval color1 as ARGB, byval color2 as ARGB )
constructor( byval point1 as GpPoint ptr, byval point2 as GpPoint ptr, byval color1 as ARGB, byval color2 as ARGB )
constructor( byval rc as GpRectF ptr, byval color1 as ARGB, byval color2 as ARGB, byval nMode as LinearGradientMode )
constructor( byval rc as GpRect ptr, byval color1 as ARGB, byval color2 as ARGB, byval nMode as LinearGradientMode )
constructor( byval rc as GpRectF ptr, byval color1 as ARGB, byval color2 as ARGB, byval angle as single, byval isAngleScalable as BOOL = FALSE )
constructor( byval rc as GpRect ptr, byval color1 as ARGB, byval color2 as ARGB, byval angle as single, byval isAngleScalable as BOOL = FALSE )
```

Creates a linear gradient brush, or an independent copy of another one. The wrap mode starts as
`WrapModeTile`.

- With two points, the gradient runs from `point1` (`color1`) to `point2` (`color2`).
- With a rectangle and a mode, it runs across the rectangle: `LinearGradientModeHorizontal`
  (left to right), `LinearGradientModeVertical` (top to bottom),
  `LinearGradientModeForwardDiagonal` (top-left to bottom-right) or
  `LinearGradientModeBackwardDiagonal` (top-right to bottom-left).
- With a rectangle and an angle, it runs across the rectangle at `angle` degrees clockwise from
  the horizontal. With `isAngleScalable` true the angle is adjusted to the rectangle's shape, so
  that 45 degrees runs corner to corner. Write the angle as a `single`, `45.0` or `45!`: a whole
  number such as `45` selects the `LinearGradientMode` form, which then fails.

The pointers must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pLinearGradientBrush` | The brush to copy. |
| `point1`, `point2` | The start and end of the gradient. |
| `rc` | The rectangle the gradient spans. |
| `color1`, `color2` | The start and end colours. |
| `nMode` | The direction across the rectangle. |
| `angle` | The direction in degrees. |
| `isAngleScalable` | `CTRUE` to fit the angle to the rectangle. |

**Example**

```freebasic
dim rc as GpRectF = type<GpRectF>( 0, 0, 200, 100 )
dim down as CGpLinearGradientBrush = CGpLinearGradientBrush( @rc, ARGB_WHITE, ARGB_BLACK, LinearGradientModeVertical )
dim tilted as CGpLinearGradientBrush = CGpLinearGradientBrush( @rc, ARGB_WHITE, ARGB_BLACK, 45.0 )
print down.GetLastStatus(); tilted.GetLastStatus()  ' 0 0
```

Microsoft Learn: [LinearGradientBrush::LinearGradientBrush](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-lineargradientbrush%28constpointf__constpointf__constcolor__constcolor_%29)

### SetLinearColors

```freebasic
function SetLinearColors( byval color1 as ARGB, byval color2 as ARGB ) as GpStatus
```

Replaces the start and end colours.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
grad.SetLinearColors( ARGB_WHITE, ARGB_BLACK )
```

Microsoft Learn: [LinearGradientBrush::SetLinearColors](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-setlinearcolors)

### GetLinearColors

```freebasic
function GetLinearColors( byval colors as ARGB ptr ) as GpStatus
```

Stores the start and end colours in an array of two `ARGB` values.

| Parameter | Meaning |
| --- | --- |
| `colors` | The first of two `ARGB` values. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
dim c(0 to 1) as ARGB
grad.GetLinearColors( @c(0) )
print hex( c(0) ); " "; hex( c(1) )                 ' FFFF0000 FF0000FF
```

Microsoft Learn: [LinearGradientBrush::GetLinearColors](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-getlinearcolors)

### GetRectangle

```freebasic
function GetRectangle( byval rc as GpRectF ptr ) as GpStatus
function GetRectangle( byval rc as GpRect ptr ) as GpStatus
```

Reads the rectangle one repeat of the gradient spans. For a brush made from two points it is the
square whose side is the line between them.

| Parameter | Meaning |
| --- | --- |
| `rc` | The rectangle that receives it. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
dim rc as GpRectF
grad.GetRectangle( @rc )
print rc.x; rc.y; rc.Width; rc.Height               ' 0 -50 100 100
```

Microsoft Learn: [LinearGradientBrush::GetRectangle](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-getrectangle%28rectf%29)

### SetGammaCorrection

```freebasic
function SetGammaCorrection( byval useGammaCorrection as BOOL ) as GpStatus
```

Turns gamma correction on (`CTRUE`) or off (`FALSE`, the default). With it on, the colours are
blended with gamma correction, which changes how light the middle of the gradient looks.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
grad.SetGammaCorrection( CTRUE )
```

Microsoft Learn: [LinearGradientBrush::SetGammaCorrection](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-setgammacorrection)

### GetGammaCorrection

```freebasic
function GetGammaCorrection() as boolean
```

Tells whether gamma correction is on.

**Returns** `true` or `false`.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
print grad.GetGammaCorrection()                     ' false
```

Microsoft Learn: [LinearGradientBrush::GetGammaCorrection](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-getgammacorrection)

### GetBlendCount

```freebasic
function GetBlendCount() as INT_
```

Returns the number of factors in the brush's blend: 1 for a new brush, which blends evenly.

**Returns** the count.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
print grad.GetBlendCount()                          ' 1
```

Microsoft Learn: [LinearGradientBrush::GetBlendCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-getblendcount)

### SetBlend

```freebasic
function SetBlend( byval blendFactors as single ptr, byval blendPositions as single ptr, byval nCount as long ) as GpStatus
```

Sets a custom blend: at each position along the gradient (0 = start, 1 = end, in increasing
order, the first 0 and the last 1) the colour is the given factor of the way from the start
colour (0) to the end colour (1). `{ 0, 1, 0 }` at `{ 0, 0.5, 1 }` goes to the end colour in
the middle and back. A blend replaces interpolation colours.

| Parameter | Meaning |
| --- | --- |
| `blendFactors` | The first of `nCount` factors, 0 to 1. |
| `blendPositions` | The first of `nCount` positions, 0 to 1. |
| `nCount` | The number of each. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
dim f(0 to 2) as single = { 0, 1, 0 }
dim p(0 to 2) as single = { 0, 0.5, 1 }
print grad.SetBlend( @f(0), @p(0), 3 ); grad.GetBlendCount()   ' 0 3
```

Microsoft Learn: [LinearGradientBrush::SetBlend](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-setblend)

### GetBlend

```freebasic
function GetBlend( byval blendFactors as single ptr, byval blendPositions as single ptr, byval nCount as long ) as GpStatus
```

Copies the blend into two arrays of `nCount` values each; size them with
[GetBlendCount](#getblendcount).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
grad.SetBlendTriangularShape( 0.5 )
dim f(0 to 2) as single, p(0 to 2) as single
grad.GetBlend( @f(0), @p(0), grad.GetBlendCount() )
print f(1); p(1)                                    ' 1 0.5
```

Microsoft Learn: [LinearGradientBrush::GetBlend](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-getblend)

### GetInterpolationColorCount

```freebasic
function GetInterpolationColorCount() as INT_
```

Returns the number of interpolation colours: 0 until
[SetInterpolationColors](#setinterpolationcolors) sets some.

**Returns** the count.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
print grad.GetInterpolationColorCount()             ' 0
```

Microsoft Learn: [LinearGradientBrush::GetInterpolationColorCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-getinterpolationcolorcount)

### SetInterpolationColors

```freebasic
function SetInterpolationColors( byval presetColors as ARGB ptr, byval blendPositions as single ptr, byval nCount as long ) as GpStatus
```

Makes the gradient pass through several colours: `presetColors(i)` at `blendPositions(i)`, the
positions from 0 to 1 in increasing order. These replace the start and end colours and the
blend.

| Parameter | Meaning |
| --- | --- |
| `presetColors` | The first of `nCount` colours. |
| `blendPositions` | The first of `nCount` positions; the first 0, the last 1. |
| `nCount` | At least 2. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 300, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
dim c(0 to 2) as ARGB = { ARGB_RED, ARGB_YELLOW, ARGB_BLUE }
dim p(0 to 2) as single = { 0, 0.5, 1 }
print grad.SetInterpolationColors( @c(0), @p(0), 3 ); grad.GetInterpolationColorCount()   ' 0 3
```

Microsoft Learn: [LinearGradientBrush::SetInterpolationColors](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-setinterpolationcolors)

### GetInterpolationColors

```freebasic
function GetInterpolationColors( byval presetColors as ARGB ptr, byval blendPositions as single ptr, byval nCount as long ) as GpStatus
```

Copies the interpolation colours and their positions into two arrays of `nCount` values; size
them with [GetInterpolationColorCount](#getinterpolationcolorcount).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 300, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
dim c(0 to 2) as ARGB = { ARGB_RED, ARGB_YELLOW, ARGB_BLUE }
dim p(0 to 2) as single = { 0, 0.5, 1 }
grad.SetInterpolationColors( @c(0), @p(0), 3 )
dim gc(0 to 2) as ARGB, gp(0 to 2) as single
grad.GetInterpolationColors( @gc(0), @gp(0), 3 )
print hex( gc(1) ); gp(1)                           ' FFFFFF00 0.5
```

Microsoft Learn: [LinearGradientBrush::GetInterpolationColors](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-getinterpolationcolors)

### SetBlendBellShape

```freebasic
function SetBlendBellShape( byval focus as single, byval scale as single = 1.0 ) as GpStatus
```

Replaces the blend with a bell curve: the colour moves smoothly from the start colour to
`scale` of the way to the end colour at position `focus`, and back again.

| Parameter | Meaning |
| --- | --- |
| `focus` | Where the peak is, 0 to 1. |
| `scale` | How far towards the end colour the peak goes, 0 to 1; 1 by default. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_WHITE, ARGB_NAVY )
grad.SetBlendBellShape( 0.5 )
```

Microsoft Learn: [LinearGradientBrush::SetBlendBellShape](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-setblendbellshape)

### SetBlendTriangularShape

```freebasic
function SetBlendTriangularShape( byval focus as single, byval scale as single = 1.0 ) as GpStatus
```

Replaces the blend with a straight rise to `scale` at position `focus` and a straight fall
after it: a blend of three factors.

| Parameter | Meaning |
| --- | --- |
| `focus` | Where the peak is, 0 to 1. |
| `scale` | How far towards the end colour the peak goes, 0 to 1; 1 by default. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_WHITE, ARGB_NAVY )
grad.SetBlendTriangularShape( 0.5 )
print grad.GetBlendCount()                          ' 3
```

Microsoft Learn: [LinearGradientBrush::SetBlendTriangularShape](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-setblendtriangularshape)

### SetTransform

```freebasic
function SetTransform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Replaces the brush's transformation with a copy of a matrix, which moves, scales and turns the
gradient.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
dim m as CGpMatrix = CGpMatrix( 1, 0, 0, 1, 3, 0 )
grad.SetTransform( @m )
```

Microsoft Learn: [LinearGradientBrush::SetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-settransform)

### GetTransform

```freebasic
function GetTransform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Copies the brush's transformation into an existing [CGpMatrix](CGpMatrix). A brush made with an
angle starts with a transformation that is not the identity.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
grad.TranslateTransform( 7, 0 )
dim m as CGpMatrix
grad.GetTransform( @m )
print m.OffsetX()                                   ' 7
```

Microsoft Learn: [LinearGradientBrush::GetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-gettransform)

### ResetTransform

```freebasic
function ResetTransform() as GpStatus
```

Makes the brush's transformation the identity again.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
grad.RotateTransform( 90 )
grad.ResetTransform()
```

Microsoft Learn: [LinearGradientBrush::ResetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-resettransform)

### MultiplyTransform

```freebasic
function MultiplyTransform( byval pMatrix as CGpMatrix ptr, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Combines the brush's transformation with a matrix, before (`MatrixOrderPrepend`, the default)
or after (`MatrixOrderAppend`) what it already holds.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
dim m as CGpMatrix = CGpMatrix( 2, 0, 0, 1, 0, 0 )
grad.MultiplyTransform( @m )
```

Microsoft Learn: [LinearGradientBrush::MultiplyTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-multiplytransform)

### TranslateTransform

```freebasic
function TranslateTransform( byval dx as single, byval dy as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a move by (`dx`, `dy`) to the brush's transformation.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
grad.TranslateTransform( 50, 0 )
```

Microsoft Learn: [LinearGradientBrush::TranslateTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-translatetransform)

### ScaleTransform

```freebasic
function ScaleTransform( byval sx as single, byval sy as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a scaling to the brush's transformation: `2, 1` stretches one repeat of the gradient to
twice its length.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
grad.ScaleTransform( 2, 1 )
```

Microsoft Learn: [LinearGradientBrush::ScaleTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-scaletransform)

### RotateTransform

```freebasic
function RotateTransform( byval angle as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a rotation by `angle` degrees to the brush's transformation.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
grad.RotateTransform( 90 )                          ' now runs top to bottom
```

Microsoft Learn: [LinearGradientBrush::RotateTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-rotatetransform)

### SetWrapMode

```freebasic
function SetWrapMode( byval nWrapMode as WrapMode ) as GpStatus
```

Sets how the gradient repeats beyond its two boundary lines: `WrapModeTile` (the default) starts
again, `WrapModeTileFlipX` and the other flip modes run it back the other way. `WrapModeClamp`
is not allowed for a linear gradient and returns `InvalidParameter`.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
print grad.SetWrapMode( WrapModeTileFlipX ); grad.SetWrapMode( WrapModeClamp )   ' 0 2
```

Microsoft Learn: [LinearGradientBrush::SetWrapMode](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-setwrapmode)

### GetWrapMode

```freebasic
function GetWrapMode() as WrapMode
```

Returns how the gradient repeats.

**Returns** the `WrapMode`.

**Example**

```freebasic
dim p1 as GpPointF = type<GpPointF>( 0, 0 )
dim p2 as GpPointF = type<GpPointF>( 100, 0 )
dim grad as CGpLinearGradientBrush = CGpLinearGradientBrush( @p1, @p2, ARGB_RED, ARGB_BLUE )
print grad.GetWrapMode()                            ' 0
```

Microsoft Learn: [LinearGradientBrush::GetWrapMode](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusbrush/nf-gdiplusbrush-lineargradientbrush-getwrapmode)

## CGpPathGradientBrush

Fills with colours that blend from a centre point out to the edge of a shape, the boundary path:
a polygon given as points, or a [CGpGraphicsPath](CGpGraphicsPath). The centre has one colour
(opaque black for a new brush); each point of the boundary has a surround colour (white for a
new brush). The centre point starts at the centroid of the shape and can be moved, even outside
it. Outside the boundary the brush paints nothing with `WrapModeClamp`, the default.

### Constructor

```freebasic
constructor( byval pPathGradientBrush as CGpPathGradientBrush ptr )
constructor( byval pts as GpPointF ptr, byval nCount as long, byval nWrapMode as WrapMode = WrapModeClamp )
constructor( byval pts as GpPoint ptr, byval nCount as long, byval nWrapMode as WrapMode = WrapModeClamp )
constructor( byval pGraphPath as CGpGraphicsPath_ ptr )
```

Creates a path gradient brush whose boundary is a polygon of `nCount` points or a path, or an
independent copy of another path gradient brush. The pointers must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pPathGradientBrush` | The brush to copy. |
| `pts` | The first of `nCount` boundary points. |
| `nCount` | The number of points. |
| `nWrapMode` | How the brush repeats outside the boundary. |
| `pGraphPath` | A path whose outline is the boundary. |

**Example**

```freebasic
dim path as CGpGraphicsPath
path.AddRectangle( 0, 0, 50, 50 )
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @path )
print radial.GetLastStatus(); radial.GetPointCount()    ' 0 4
```

Microsoft Learn: [PathGradientBrush::PathGradientBrush](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-pathgradientbrush%28constgraphicspath%29)

### GetCenterColor

```freebasic
function GetCenterColor( byval colour as ARGB ptr ) as ARGB
function GetCenterColor() as ARGB
```

The first form stores the colour of the centre point in the `ARGB` that `colour` points to. The
form without an argument returns the ARGB colour.

| Parameter | Meaning |
| --- | --- |
| `colour` | The variable that receives the colour. |

**Returns** the colour.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.SetCenterColor( ARGB_RED )
dim c as ARGB
radial.GetCenterColor( @c )
print hex( c ); " "; radial.GetCenterColor()       ' FFFF0000 0
```

Microsoft Learn: [PathGradientBrush::GetCenterColor](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getcentercolor)

### SetCenterColor

```freebasic
function SetCenterColor( byval colour as ARGB ) as GpStatus
```

Sets the colour at the centre point.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.SetCenterColor( ARGB_WHITE )
```

Microsoft Learn: [PathGradientBrush::SetCenterColor](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setcentercolor)

### GetPointCount

```freebasic
function GetPointCount() as INT_
```

Returns the number of points in the boundary path: as many as were given, or for a path, as
many as it holds (an ellipse is several Bézier curves).

**Returns** the count.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
print radial.GetPointCount()                        ' 3
```

Microsoft Learn: [PathGradientBrush::GetPointCount](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getpointcount)

### GetSurroundColorCount

```freebasic
function GetSurroundColorCount() as INT_
```

Returns the size of array [GetSurroundColors](#getsurroundcolors) needs: the number of boundary
points.

**Returns** the count.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
print radial.GetSurroundColorCount()                ' 3
```

Microsoft Learn: [PathGradientBrush::GetSurroundColorCount](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getsurroundcolorcount)

### GetSurroundColors

```freebasic
function GetSurroundColors( byval colors as ARGB ptr, byval nCount as INT_ ptr ) as GpStatus
```

Copies the surround colours into an array. On the way in, `*nCount` is the size of the array,
which must be at least [GetSurroundColorCount](#getsurroundcolorcount); on success it is set to
the number of distinct colours GDI+ stored: 1 when every point has the same colour.

| Parameter | Meaning |
| --- | --- |
| `colors` | The first element of the array. |
| `nCount` | In: the array size. Out: the number of colours stored. |

**Returns** `Ok` on success; `InvalidParameter` when a pointer is `NULL`; `InsufficientBuffer`
(5) when the array is too small.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim c(0 to 2) as ARGB, n as INT_ = 3
radial.GetSurroundColors( @c(0), @n )
print hex( c(0) ); n                                ' FFFFFFFF 1
```

Microsoft Learn: [PathGradientBrush::GetSurroundColors](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getsurroundcolors)

### SetSurroundColors

```freebasic
function SetSurroundColors( byval colors as ARGB ptr, byval nCount as INT_ ptr ) as GpStatus
```

Gives the boundary points their colours: `colors(i)` for point `i`. When there are fewer colours
than points, the last colour is used for the rest, so one colour colours the whole edge.
`*nCount` is the number of colours; it may not exceed the number of points.

| Parameter | Meaning |
| --- | --- |
| `colors` | The first of the colours. |
| `nCount` | A variable holding the number of colours; set to the number used on success. |

**Returns** `Ok` on success; `InvalidParameter` when a pointer is `NULL` or there are more
colours than points.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim c(0 to 2) as ARGB = { ARGB_RED, ARGB_GREEN, ARGB_BLUE }
dim n as INT_ = 3
print radial.SetSurroundColors( @c(0), @n )         ' 0
```

Microsoft Learn: [PathGradientBrush::SetSurroundColors](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setsurroundcolors)

### GetGraphicsPath

```freebasic
function GetGraphicsPath( byval pGrapgPath as CGpGraphicsPath_ ptr ) as GpStatus
```

Is meant to copy the boundary path into a [CGpGraphicsPath](CGpGraphicsPath). GDI+ does not
implement it.

**Returns** `NotImplemented` (6); `InvalidParameter` when the pointer is `NULL`.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim path as CGpGraphicsPath
print radial.GetGraphicsPath( @path )               ' 6
```

Microsoft Learn: [PathGradientBrush::GetGraphicsPath](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getgraphicspath)

### SetGraphicsPath

```freebasic
function SetGraphicsPath( byval pGraphPath as CGpGraphicsPath_ ptr ) as GpStatus
```

Is meant to replace the boundary path. It calls the same GDI+ function as
[GetGraphicsPath](#getgraphicspath), which is not implemented, so the boundary does not change.
Make a new brush from the path instead.

**Returns** `NotImplemented` (6); `InvalidParameter` when the pointer is `NULL`.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim path as CGpGraphicsPath
path.AddRectangle( 0, 0, 50, 50 )
print radial.SetGraphicsPath( @path )               ' 6
```

Microsoft Learn: [PathGradientBrush::SetGraphicsPath](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setgraphicspath)

### GetCenterPoint

```freebasic
function GetCenterPoint( byval pt as GpPointF ptr ) as GpStatus
function GetCenterPoint( byval pt as GpPoint ptr ) as GpStatus
```

Reads the centre point, in the coordinates of the boundary.

| Parameter | Meaning |
| --- | --- |
| `pt` | The point that receives it. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim pt as GpPointF
radial.GetCenterPoint( @pt )
print pt.x; pt.y                                    ' 50 26.66667
```

Microsoft Learn: [PathGradientBrush::GetCenterPoint](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getcenterpoint%28pointf%29)

### SetCenterPoint

```freebasic
function SetCenterPoint( byval pt as GpPointF ptr ) as GpStatus
function SetCenterPoint( byval pt as GpPoint ptr ) as GpStatus
```

Moves the centre point, where the centre colour is. Off-centre, it gives a lit-from-one-side
look.

| Parameter | Meaning |
| --- | --- |
| `pt` | The new centre. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim pt as GpPointF = type<GpPointF>( 30, 20 )
radial.SetCenterPoint( @pt )
```

Microsoft Learn: [PathGradientBrush::SetCenterPoint](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setcenterpoint%28constpointf_%29)

### GetRectangle

```freebasic
function GetRectangle( byval rc as GpRectF ptr ) as GpStatus
function GetRectangle( byval rc as GpRect ptr ) as GpStatus
```

Reads the smallest rectangle that holds the boundary path.

| Parameter | Meaning |
| --- | --- |
| `rc` | The rectangle that receives it. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim rc as GpRectF
radial.GetRectangle( @rc )
print rc.Width; rc.Height                           ' 100 80
```

Microsoft Learn: [PathGradientBrush::GetRectangle](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getrectangle%28rectf%29)

### SetGammaCorrection

```freebasic
function SetGammaCorrection( byval useGammaCorrection as BOOL ) as GpStatus
```

Turns gamma correction on (`CTRUE`) or off (`FALSE`, the default).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.SetGammaCorrection( CTRUE )
print radial.GetGammaCorrection()                   ' true
```

Microsoft Learn: [PathGradientBrush::SetGammaCorrection](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setgammacorrection)

### GetGammaCorrection

```freebasic
function GetGammaCorrection() as boolean
```

Tells whether gamma correction is on.

**Returns** `true` or `false`.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
print radial.GetGammaCorrection()                   ' false
```

Microsoft Learn: [PathGradientBrush::GetGammaCorrection](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getgammacorrection)

### GetBlendCount

```freebasic
function GetBlendCount() as INT_
```

Returns the number of factors in the brush's blend: 1 for a new brush.

**Returns** the count.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
print radial.GetBlendCount()                        ' 1
```

Microsoft Learn: [PathGradientBrush::GetBlendCount](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getblendcount)

### GetBlend

```freebasic
function GetBlend( byval blendFactors as single ptr, byval blendPositions as single ptr, byval nCount as INT_ ) as GpStatus
```

Copies the blend into two arrays of `nCount` values each; size them with
[GetBlendCount](#getblendcount-1).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.SetBlendTriangularShape( 0.5 )
dim f(0 to 2) as single, p(0 to 2) as single
radial.GetBlend( @f(0), @p(0), radial.GetBlendCount() )
print f(1); p(1)                                    ' 1 0.5
```

Microsoft Learn: [PathGradientBrush::GetBlend](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getblend)

### SetBlend

```freebasic
function SetBlend( byval blendFactors as single ptr, byval blendPositions as single ptr, byval nCount as INT_ ) as GpStatus
```

Sets a custom blend. Positions run from the boundary (0) to the centre (1); each factor says how
far the colour is from the surround colour (0) to the centre colour (1) at that position.

| Parameter | Meaning |
| --- | --- |
| `blendFactors` | The first of `nCount` factors, 0 to 1. |
| `blendPositions` | The first of `nCount` positions, 0 to 1; the first 0, the last 1. |
| `nCount` | The number of each. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim f(0 to 2) as single = { 0, 0.2, 1 }
dim p(0 to 2) as single = { 0, 0.8, 1 }
print radial.SetBlend( @f(0), @p(0), 3 ); radial.GetBlendCount()   ' 0 3
```

Microsoft Learn: [PathGradientBrush::SetBlend](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setblend)

### GetInterpolationColorCount

```freebasic
function GetInterpolationColorCount() as INT_
```

Returns the number of interpolation colours: 0 until some are set.

**Returns** the count.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
print radial.GetInterpolationColorCount()           ' 0
```

Microsoft Learn: [PathGradientBrush::GetInterpolationColorCount](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getinterpolationcolorcount)

### SetInterpolationColors

```freebasic
function SetInterpolationColors( byval presetColors as ARGB ptr, byval blendPositions as single ptr, byval nCount as INT_ ) as GpStatus
```

Makes the gradient pass through several colours, from the boundary (position 0) to the centre
(position 1), in place of the centre and surround colours.

| Parameter | Meaning |
| --- | --- |
| `presetColors` | The first of `nCount` colours. |
| `blendPositions` | The first of `nCount` positions; the first 0, the last 1. |
| `nCount` | At least 2. |

**Returns** `Ok` on success; `InvalidParameter` when `nCount` is 0 or less.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim c(0 to 2) as ARGB = { ARGB_BLUE, ARGB_WHITE, ARGB_RED }
dim p(0 to 2) as single = { 0, 0.5, 1 }
print radial.SetInterpolationColors( @c(0), @p(0), 3 )   ' 0
```

Microsoft Learn: [PathGradientBrush::SetInterpolationColors](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setinterpolationcolors)

### GetInterpolationColors

```freebasic
function GetInterpolationColors( byval presetColors as ARGB ptr, byval blendPositions as single ptr, byval nCount as INT_ ) as GpStatus
```

Copies the interpolation colours and their positions into two arrays of `nCount` values; size
them with [GetInterpolationColorCount](#getinterpolationcolorcount-1).

**Returns** `Ok` on success; `InvalidParameter` when `nCount` is 0 or less.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim c(0 to 2) as ARGB = { ARGB_BLUE, ARGB_WHITE, ARGB_RED }
dim p(0 to 2) as single = { 0, 0.5, 1 }
radial.SetInterpolationColors( @c(0), @p(0), 3 )
dim gc(0 to 2) as ARGB, gp(0 to 2) as single
radial.GetInterpolationColors( @gc(0), @gp(0), 3 )
print hex( gc(1) ); gp(1)                           ' FFFFFFFF 0.5
```

Microsoft Learn: [PathGradientBrush::GetInterpolationColors](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getinterpolationcolors)

### SetBlendBellShape

```freebasic
function SetBlendBellShape( byval focus as single, byval scale as single = 1.0 ) as GpStatus
```

Replaces the blend with a bell curve that peaks at `focus` (0 = boundary, 1 = centre) at
`scale` of the way to the centre colour.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.SetBlendBellShape( 0.5 )
```

Microsoft Learn: [PathGradientBrush::SetBlendBellShape](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setblendbellshape)

### SetBlendTriangularShape

```freebasic
function SetBlendTriangularShape( byval focus as single, byval scale as single = 1.0 ) as GpStatus
```

Replaces the blend with a straight rise to `scale` at `focus` and a straight fall after it.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.SetBlendTriangularShape( 0.5 )
print radial.GetBlendCount()                        ' 3
```

Microsoft Learn: [PathGradientBrush::SetBlendTriangularShape](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setblendtriangularshape)

### GetTransform

```freebasic
function GetTransform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Copies the brush's transformation into an existing [CGpMatrix](CGpMatrix).

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.TranslateTransform( 3, 4 )
dim m as CGpMatrix
radial.GetTransform( @m )
print m.OffsetX(); m.OffsetY()                      ' 3 4
```

Microsoft Learn: [PathGradientBrush::GetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-gettransform)

### SetTransform

```freebasic
function SetTransform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Replaces the brush's transformation with a copy of a matrix, which moves, scales and turns the
whole gradient, boundary included.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim m as CGpMatrix = CGpMatrix( 1, 0, 0, 1, 2, 0 )
radial.SetTransform( @m )
```

Microsoft Learn: [PathGradientBrush::SetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-settransform)

### ResetTransform

```freebasic
function ResetTransform() as GpStatus
```

Makes the brush's transformation the identity again.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.ScaleTransform( 2, 2 )
radial.ResetTransform()
```

Microsoft Learn: [PathGradientBrush::ResetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-resettransform)

### MultiplyTransform

```freebasic
function MultiplyTransform( byval pMatrix as CGpMatrix ptr, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Combines the brush's transformation with a matrix, before (`MatrixOrderPrepend`, the default)
or after (`MatrixOrderAppend`) what it already holds.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim m as CGpMatrix = CGpMatrix( 2, 0, 0, 2, 0, 0 )
radial.MultiplyTransform( @m, MatrixOrderAppend )
```

Microsoft Learn: [PathGradientBrush::MultiplyTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-multiplytransform)

### TranslateTransform

```freebasic
function TranslateTransform( byval dx as single, byval dy as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a move by (`dx`, `dy`) to the brush's transformation.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.TranslateTransform( 100, 0 )
```

Microsoft Learn: [PathGradientBrush::TranslateTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-translatetransform)

### ScaleTransform

```freebasic
function ScaleTransform( byval sx as single, byval sy as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a scaling to the brush's transformation.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.ScaleTransform( 2, 2 )
```

Microsoft Learn: [PathGradientBrush::ScaleTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-scaletransform)

### RotateTransform

```freebasic
function RotateTransform( byval angle as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a rotation by `angle` degrees to the brush's transformation.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.RotateTransform( 15 )
```

Microsoft Learn: [PathGradientBrush::RotateTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-rotatetransform)

### GetFocusScales

```freebasic
function GetFocusScales( byval xScale as single ptr, byval yScale as single ptr ) as GpStatus
```

Reads the focus scales into two variables; both are 0 for a new brush. It returns the status
without storing it, so `GetLastStatus()` does not change.

| Parameter | Meaning |
| --- | --- |
| `xScale`, `yScale` | The variables that receive the scales. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
dim as single sx, sy
radial.GetFocusScales( @sx, @sy )
print sx; sy                                        ' 0 0
```

Microsoft Learn: [PathGradientBrush::GetFocusScales](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getfocusscales)

### SetFocusScales

```freebasic
function SetFocusScales( byval xScale as single, byval yScale as single ) as GpStatus
```

Widens the centre into a patch of solid centre colour: a copy of the boundary shrunk to `xScale`
of its width and `yScale` of its height, around the centre point. The gradient then runs from
that patch to the boundary.

| Parameter | Meaning |
| --- | --- |
| `xScale`, `yScale` | 0 to 1; 0 makes the centre a point. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.SetFocusScales( 0.5, 0.25 )
```

Microsoft Learn: [PathGradientBrush::SetFocusScales](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setfocusscales)

### GetWrapMode

```freebasic
function GetWrapMode() as WrapMode
```

Returns how the brush repeats outside its boundary.

**Returns** the `WrapMode`: `WrapModeClamp` (4) unless one was given.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
print radial.GetWrapMode()                          ' 4
```

Microsoft Learn: [PathGradientBrush::GetWrapMode](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-getwrapmode)

### SetWrapMode

```freebasic
function SetWrapMode( byval nWrapMode as WrapMode ) as GpStatus
```

Sets how the brush repeats outside its boundary: `WrapModeClamp` paints nothing there,
`WrapModeTile` and the flip modes repeat the whole gradient, boundary rectangle by boundary
rectangle.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pts(0 to 2) as GpPointF = { (0, 0), (100, 0), (50, 80) }
dim radial as CGpPathGradientBrush = CGpPathGradientBrush( @pts(0), 3 )
radial.SetWrapMode( WrapModeTile )
```

Microsoft Learn: [PathGradientBrush::SetWrapMode](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspath/nf-gdipluspath-pathgradientbrush-setwrapmode)

## See also

- [CGpGraphics](CGpGraphics), whose `Fill…` methods take a brush
- [CGpPen](CGpPen), which can stroke with a brush
- [CGpGraphicsPath](CGpGraphicsPath) for the boundary of a path gradient
- [GDI+ images](SysWin-GdiPlus-Images) for the bitmaps a texture brush uses
- [CGpMatrix](CGpMatrix) for brush transformations
- [Colours](SysWin-Colors) for the `ARGB_*` constants
- [sys/win/gdiplus](SysWin-GdiPlus)
