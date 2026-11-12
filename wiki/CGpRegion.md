[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gdiplus](SysWin-GdiPlus) › **CGpRegion**

# CGpRegion

Combines rectangles and paths into areas for filling, clipping and hit-testing in GDI+.

A `CGpRegion` wraps one GDI+ `Region` object: an area of any shape, made from rectangles, the
interiors of [paths](CGpGraphicsPath), saved region data or a GDI region. It creates the object
in its constructor and deletes it in its destructor. A new region made with no argument is
**infinite**: it covers everything.

**Using a region.** Fill it with [CGpGraphics](CGpGraphics) `FillRegion`, make it the clipping
area with `SetClip`, or ask whether a point or a rectangle lies in it with
[IsVisible](#isvisible).

**Combining.** [Intersect](#intersect), [Union_](#union_), [Xor_](#xor_), [Exclude](#exclude)
and [Complement](#complement) change the region in place, combining it with a rectangle, a path
or another region. `Union_` and `Xor_` end in an underscore because `union` and `xor` are
keywords. Pointer arguments are not checked: pass a real rectangle, path or region.

**The `pGraphics` argument.** Several queries take a [CGpGraphics](CGpGraphics) whose
transformation and device are used to evaluate the region. [IsEmpty](#isempty),
[IsInfinite](#isinfinite), [Equals](#equals) and [GetBounds](#getbounds) need a real one: with
`NULL` they fail with `InvalidParameter` and return `false` or leave the rectangle unset.
[IsVisible](#isvisible) and [GetHRGN](#gethrgn) accept `NULL`.

**Lifetime.** Never copy a `CGpRegion` by value (`dim b as CGpRegion = a`, or a `byval`
parameter): the copy holds the same GDI+ object and deletes it when it goes. Copy with
`dim b as CGpRegion = @a` or [Clone](#clone).

**Status.** The methods that change the region return a `GpStatus`: `Ok` (0) on success,
otherwise the reason. The status is also stored and `GetLastStatus()`, inherited by every
`CGp*` class, returns it; getters store theirs too.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus
```

## Example

A window that fills the parts of two circles that do not overlap, then uses the same region as
a clip so that white stripes appear only inside it:

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim token as ULONG_PTR = gdiplus.Init()
    dim pWindow as CWindow = "RegionDemo"
    pWindow.Create( NULL, "CGpRegion", @WndProc )
    pWindow.SetClientSize( 360, 220 )
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
                graphics.ScaleTransformForDpi()
                graphics.Clear( ARGB_WHITE )
                dim circle1 as CGpGraphicsPath
                circle1.AddEllipse( 40, 30, 160, 160 )
                dim circle2 as CGpGraphicsPath
                circle2.AddEllipse( 140, 30, 160, 160 )
                dim region as CGpRegion = @circle1
                region.Xor_( @circle2 )
                dim brush as CGpSolidBrush = ARGB_CORNFLOWERBLUE
                graphics.FillRegion( @brush, @region )
                graphics.SetClip( @region )
                dim pen as CGpPen = CGpPen( ARGB_WHITE, 4 )
                for x as long = 0 to 360 step 16
                    graphics.DrawLine( @pen, x, 0, x + 120, 220 )
                next
                graphics.ResetClip()
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
| [Constructor](#constructor) | Creates an infinite region, or one from a rectangle, a path, data, a GDI region or another region. |
| [Destructor](#destructor) | Deletes the GDI+ region. |
| [Clone](#clone) | Copies this region into another `CGpRegion`. |
| [MakeInfinite](#makeinfinite) | Makes the region cover everything. |
| [MakeEmpty](#makeempty) | Makes the region cover nothing. |
| [Intersect](#intersect) | Keeps only the part shared with a rectangle, path or region. |
| [Union_](#union_) | Adds a rectangle, path or region. |
| [Xor_](#xor_) | Keeps the parts that are in one of the two but not both. |
| [Exclude](#exclude) | Removes a rectangle, path or region. |
| [Complement](#complement) | Becomes the part of a rectangle, path or region that is outside this one. |
| [Translate](#translate) | Moves the region. |
| [Transform](#transform) | Applies a matrix to the region. |
| [GetBounds](#getbounds) | Reads the smallest rectangle that encloses the region. |
| [GetHRGN](#gethrgn) | Creates a GDI region from the region. |
| [IsEmpty](#isempty) | Tells whether the region covers nothing. |
| [IsInfinite](#isinfinite) | Tells whether the region covers everything. |
| [Equals](#equals) | Tells whether two regions cover the same area. |
| [GetDataSize](#getdatasize) | Returns the size of the data that describes the region. |
| [GetData](#getdata) | Copies out the data that describes the region. |
| [IsVisible](#isvisible) | Tells whether a point or a rectangle lies in the region. |
| [GetRegionScansCount](#getregionscanscount) | Returns how many rectangles approximate the region. |
| [GetRegionScans](#getregionscans) | Copies out the rectangles that approximate the region. |

## Reference

### Constructor

```freebasic
constructor
constructor( byval pRegion as CGpRegion ptr )
constructor( byval rcf as GpRectF ptr )
constructor( byval rc as GpRect ptr )
constructor( byval x as single, byval y as single, byval nWidth as single, byval nHeight as single )
constructor( byval pPath as CGpGraphicsPath_ ptr )
constructor( byval regionData as byte ptr, byval nSize as long )
constructor( byval hRgn as HRGN )
```

Creates the GDI+ region.

- With no argument the region is infinite.
- With another region's address it is an independent copy; the pointer must not be `NULL`.
- With a rectangle, or its position and size, it is that rectangle.
- With a path's address it is the path's interior, filled with the path's fill mode. `NULL`
  creates nothing and the status is `InvalidParameter`.
- With data from [GetData](#getdata) and its size in bytes it is the region the data describes.
- With a GDI region it is a copy of that region; you may delete the `HRGN` afterwards.

`CGpGraphicsPath_` is another name for [CGpGraphicsPath](CGpGraphicsPath).
`GetLastStatus()` tells whether the region was created.

| Parameter | Meaning |
| --- | --- |
| `pRegion` | The region to copy. |
| `rcf`, `rc` | The rectangle. |
| `x`, `y`, `nWidth`, `nHeight` | The rectangle's position and size. |
| `pPath` | The path whose interior becomes the region. |
| `regionData`, `nSize` | Region data and its size in bytes. |
| `hRgn` | A GDI region. |

**Example**

```freebasic
dim box as CGpRegion = CGpRegion( 10, 10, 100, 50 )
dim h as HRGN = CreateRectRgn( 0, 0, 20, 20 )
dim fromGdi as CGpRegion = h
DeleteObject( h )                           ' the region keeps its own copy
```

Microsoft Learn: [Region::Region](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-region%28constrectf_%29)

### Destructor

```freebasic
destructor
```

Deletes the GDI+ region. An `HRGN` made by [GetHRGN](#gethrgn) is a separate object and is
not affected.

**Example**

```freebasic
dim pR as CGpRegion ptr = new CGpRegion( 0, 0, 50, 50 )
print pR->GetLastStatus()                   ' 0
delete pR
```

### Clone

```freebasic
function Clone( byval pRegion as CGpRegion ptr ) as GpStatus
```

Copies this region into the existing `CGpRegion` that `pRegion` points to. The GDI+ region the
target held is deleted first.

| Parameter | Meaning |
| --- | --- |
| `pRegion` | The object that receives the copy. |

**Returns** `Ok` on success; `InvalidParameter` when `pRegion` is `NULL`.

**Example**

```freebasic
dim a as CGpRegion = CGpRegion( 0, 0, 10, 10 )
dim b as CGpRegion
a.Clone( @b )                               ' b is now 0, 0, 10, 10
```

Microsoft Learn: [Region::Clone](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-clone)

### MakeInfinite

```freebasic
function MakeInfinite() as GpStatus
```

Makes the region infinite, covering the whole plane.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
r.MakeInfinite()
```

Microsoft Learn: [Region::MakeInfinite](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-makeinfinite)

### MakeEmpty

```freebasic
function MakeEmpty() as GpStatus
```

Makes the region empty: it covers no point at all. Combine an empty region with
[Union_](#union_) to build one up from pieces.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim r as CGpRegion
r.MakeEmpty()
dim rc as GpRectF = type<GpRectF>( 0, 0, 10, 10 )
r.Union_( @rc )
```

Microsoft Learn: [Region::MakeEmpty](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-makeempty)

### Intersect

```freebasic
function Intersect( byval rc as GpRectF ptr ) as GpStatus
function Intersect( byval rc as GpRect ptr ) as GpStatus
function Intersect( byval pPath as CGpGraphicsPath_ ptr ) as GpStatus
function Intersect( byval pRegion as CGpRegion ptr ) as GpStatus
```

Changes the region to the part of it that is also inside the rectangle, the path's interior or
the other region.

| Parameter | Meaning |
| --- | --- |
| `rc` | A rectangle. |
| `pPath` | A path. |
| `pRegion` | Another region. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 10, 10, 100, 50 )
dim rc as GpRectF = type<GpRectF>( 50, 0, 100, 30 )
r.Intersect( @rc )                          ' now 50, 10, 60 x 20
```

Microsoft Learn: [Region::Intersect](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-intersect%28constrectf_%29)

### Union_

```freebasic
function Union_( byval rc as GpRectF ptr ) as GpStatus
function Union_( byval rc as GpRect ptr ) as GpStatus
function Union_( byval pPath as CGpGraphicsPath_ ptr ) as GpStatus
function Union_( byval pRegion as CGpRegion ptr ) as GpStatus
```

Changes the region to everything that is in it or in the rectangle, the path's interior or the
other region.

| Parameter | Meaning |
| --- | --- |
| `rc` | A rectangle. |
| `pPath` | A path. |
| `pRegion` | Another region. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
dim rc as GpRectF = type<GpRectF>( 20, 0, 10, 10 )
r.Union_( @rc )                             ' two separate squares
```

Microsoft Learn: [Region::Union](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-union%28constrectf_%29)

### Xor_

```freebasic
function Xor_( byval rc as GpRectF ptr ) as GpStatus
function Xor_( byval rc as GpRect ptr ) as GpStatus
function Xor_( byval gpPath as CGpGraphicsPath_ ptr ) as GpStatus
function Xor_( byval gpRegion as CGpRegion ptr ) as GpStatus
```

Changes the region to the parts that are in it or in the rectangle, path or other region, but
not in both.

| Parameter | Meaning |
| --- | --- |
| `rc` | A rectangle. |
| `gpPath` | A path. |
| `gpRegion` | Another region. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim a as CGpGraphicsPath
a.AddEllipse( 0, 0, 100, 100 )
dim r as CGpRegion = @a
dim rc as GpRectF = type<GpRectF>( 50, 0, 100, 100 )
r.Xor_( @rc )
```

Microsoft Learn: [Region::Xor](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-xor%28constrectf_%29)

### Exclude

```freebasic
function Exclude( byval rc as GpRectF ptr ) as GpStatus
function Exclude( byval rc as GpRect ptr ) as GpStatus
function Exclude( byval pPath as CGpGraphicsPath_ ptr ) as GpStatus
function Exclude( byval pRegion as CGpRegion ptr ) as GpStatus
```

Changes the region to the part of it that is **not** in the rectangle, path or other region: the
second shape is cut out of this one.

| Parameter | Meaning |
| --- | --- |
| `rc` | A rectangle. |
| `pPath` | A path. |
| `pRegion` | Another region. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
dim rc as GpRectF = type<GpRectF>( 5, 0, 10, 10 )
r.Exclude( @rc )                            ' now 0, 0, 5 x 10
```

Microsoft Learn: [Region::Exclude](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-exclude%28constrectf_%29)

### Complement

```freebasic
function Complement( byval rc as GpRectF ptr ) as GpStatus
function Complement( byval rc as GpRect ptr ) as GpStatus
function Complement( byval pPath as CGpGraphicsPath_ ptr ) as GpStatus
function Complement( byval pRegion as CGpRegion ptr ) as GpStatus
```

Changes the region to the part of the rectangle, path or other region that is **not** in this
region: the reverse of [Exclude](#exclude), this one is cut out of the second shape.

| Parameter | Meaning |
| --- | --- |
| `rc` | A rectangle. |
| `pPath` | A path. |
| `pRegion` | Another region. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
dim rc as GpRectF = type<GpRectF>( 5, 0, 10, 10 )
r.Complement( @rc )                         ' now 10, 0, 5 x 10
```

Microsoft Learn: [Region::Complement](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-complement%28constrectf_%29)

### Translate

```freebasic
function Translate( byval dx as single, byval dy as single ) as GpStatus
```

Moves the region by `dx` horizontally and `dy` vertically.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
r.Translate( 100, 0 )                       ' now 100, 0, 10 x 10
```

Microsoft Learn: [Region::Translate](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-translate%28real_real%29)

### Transform

```freebasic
function Transform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Applies a [matrix](CGpMatrix) to every point of the region.

| Parameter | Meaning |
| --- | --- |
| `pMatrix` | The transformation. |

**Returns** `Ok` on success; `InvalidParameter` when `pMatrix` is `NULL`.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 10, 0, 10, 10 )
dim m as CGpMatrix
m.Scale( 2, 2 )
r.Transform( @m )                           ' now 20, 0, 20 x 20
```

Microsoft Learn: [Region::Transform](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-transform)

### GetBounds

```freebasic
function GetBounds( byval rc as GpRectF ptr, byval pGraphics as CGpGraphics_ ptr ) as GpStatus
function GetBounds( byval rc as GpRect ptr, byval pGraphics as CGpGraphics_ ptr ) as GpStatus
```

Reads the smallest rectangle that encloses the region, in the world coordinates of
`pGraphics`. An infinite region gives a very large rectangle.

| Parameter | Meaning |
| --- | --- |
| `rc` | Receives the rectangle. |
| `pGraphics` | The graphics whose transformation applies; must not be `NULL`. |

**Returns** `Ok` on success; `InvalidParameter` when `pGraphics` is `NULL`.

**Example**

```freebasic
dim g as CGpGraphics = hwnd
dim r as CGpRegion = CGpRegion( 10, 10, 100, 50 )
dim rc as GpRectF
if r.GetBounds( @rc, @g ) = Ok then print rc.x; rc.y; rc.Width; rc.Height   ' 10 10 100 50
```

Microsoft Learn: [Region::GetBounds](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-getbounds%28rectf_constgraphics%29)

### GetHRGN

```freebasic
function GetHRGN( byval pGraphics as CGpGraphics_ ptr ) as HRGN
```

Creates a GDI region with the same shape, in the device coordinates of `pGraphics` (or the
region's own coordinates when `pGraphics` is `NULL`). **Free it with `DeleteObject`** when you
no longer need it.

| Parameter | Meaning |
| --- | --- |
| `pGraphics` | The graphics whose transformation applies, or `NULL`. |

**Returns** the new `HRGN`. For an infinite region it is `NULL` and the status is `Ok`; on
failure it is `NULL` and `GetLastStatus()` holds the error.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 100, 100 )
dim h as HRGN = r.GetHRGN( NULL )
if h then SetWindowRgn( hwnd, h, TRUE )     ' the window now owns h
```

Microsoft Learn: [Region::GetHRGN](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-gethrgn)

### IsEmpty

```freebasic
function IsEmpty( byval pGraphics as CGpGraphics_ ptr ) as boolean
```

Tells whether the region covers no point at all.

| Parameter | Meaning |
| --- | --- |
| `pGraphics` | A graphics object; must not be `NULL`. |

**Returns** `true` if it is empty; `false` otherwise, or when `pGraphics` is `NULL`.

**Example**

```freebasic
dim g as CGpGraphics = hwnd
dim r as CGpRegion
r.MakeEmpty()
print r.IsEmpty( @g )                       ' true
```

Microsoft Learn: [Region::IsEmpty](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-isempty)

### IsInfinite

```freebasic
function IsInfinite( byval pGraphics as CGpGraphics_ ptr ) as boolean
```

Tells whether the region covers everything, as a new region made with no argument does.

| Parameter | Meaning |
| --- | --- |
| `pGraphics` | A graphics object; must not be `NULL`. |

**Returns** `true` if it is infinite; `false` otherwise, or when `pGraphics` is `NULL`.

**Example**

```freebasic
dim g as CGpGraphics = hwnd
dim r as CGpRegion
print r.IsInfinite( @g )                    ' true
```

Microsoft Learn: [Region::IsInfinite](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-isinfinite)

### Equals

```freebasic
function Equals( byval pRegion as CGpRegion ptr, byval pGraphics as CGpGraphics_ ptr ) as boolean
```

Tells whether this region and another one cover the same area.

| Parameter | Meaning |
| --- | --- |
| `pRegion` | The region to compare with. |
| `pGraphics` | A graphics object; must not be `NULL`. |

**Returns** `true` if they are equal; `false` otherwise, or when `pGraphics` is `NULL`.

**Example**

```freebasic
dim g as CGpGraphics = hwnd
dim a as CGpRegion = CGpRegion( 0, 0, 10, 10 )
dim b as CGpRegion = CGpRegion( 0, 0, 10, 10 )
print a.Equals( @b, @g )                    ' true
```

Microsoft Learn: [Region::Equals](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-equals)

### GetDataSize

```freebasic
function GetDataSize() as UINT
```

Returns how many bytes [GetData](#getdata) needs to describe the region.

**Returns** the size in bytes, or 0 on failure.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
print "region data:"; r.GetDataSize(); " bytes"
```

Microsoft Learn: [Region::GetDataSize](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-getdatasize)

### GetData

```freebasic
function GetData( byval buffer as byte ptr, byval bufferSize as UINT, byval sizeFilled as UINT ptr ) as GpStatus
```

Copies the data that describes the region into `buffer`. Size the buffer with
[GetDataSize](#getdatasize). The data can be saved and turned back into a region with the
`regionData` [constructor](#constructor).

| Parameter | Meaning |
| --- | --- |
| `buffer` | The buffer that receives the data. |
| `bufferSize` | Its size in bytes. |
| `sizeFilled` | Receives how many bytes were written; may be `NULL`. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
dim nSize as UINT = r.GetDataSize()
dim buf(0 to nSize - 1) as byte
r.GetData( @buf(0), nSize, NULL )
dim restored as CGpRegion = CGpRegion( @buf(0), nSize )
```

Microsoft Learn: [Region::GetData](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-getdata)

### IsVisible

```freebasic
function IsVisible( byval pt as GpPointF ptr, byval pGraphics as CGpGraphics_ ptr ) as Boolean
function IsVisible( byval pt as GpPoint ptr, byval pGraphics as CGpGraphics_ ptr ) as Boolean
function IsVisible( byval x as single, byval y as single, byval pGraphics as CGpGraphics_ ptr ) as Boolean
function IsVisible( byval rc as GpRectF ptr, byval pGraphics as CGpGraphics_ ptr ) as Boolean
function IsVisible( byval rc as GpRect ptr, byval pGraphics as CGpGraphics_ ptr ) as Boolean
function IsVisible( byval x as single, byval y as single, byval nWidth as single, byval nHeight as single, byval pGraphics as CGpGraphics_ ptr ) as Boolean
```

Tells whether a point lies in the region, or whether any part of a rectangle does. `pGraphics`
may be `NULL`; when it is given, its world transformation applies.

| Parameter | Meaning |
| --- | --- |
| `pt`, `x`, `y` | The point. |
| `rc`, `x`, `y`, `nWidth`, `nHeight` | The rectangle. |
| `pGraphics` | A graphics object, or `NULL`. |

**Returns** `true` if visible, `false` if not.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
if r.IsVisible( 5, 5, NULL ) then print "inside"
print r.IsVisible( 50, 50, NULL )           ' 0
```

Microsoft Learn: [Region::IsVisible](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-isvisible%28real_real_constgraphics%29)

### GetRegionScansCount

```freebasic
function GetRegionScansCount( byval pMatrix as CGpMatrix ptr ) as UINT
```

Returns how many rectangles make up the region once `pMatrix` has been applied to it: GDI+
approximates any region by horizontal strips of rectangles. Pass an identity
[CGpMatrix](CGpMatrix) to measure the region as it is; `NULL` fails with `InvalidParameter`
and returns 0.

| Parameter | Meaning |
| --- | --- |
| `pMatrix` | The transformation to apply first; must not be `NULL`. |

**Returns** the number of rectangles.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
dim rc as GpRectF = type<GpRectF>( 20, 0, 10, 10 )
r.Union_( @rc )
dim identity as CGpMatrix
print r.GetRegionScansCount( @identity )    ' 2
```

Microsoft Learn: [Region::GetRegionScansCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-getregionscanscount)

### GetRegionScans

```freebasic
function GetRegionScans( byval pMatrix as CGpMatrix ptr, byval rects as GpRectF ptr, byval nCount as INT_ ptr ) as GpStatus
```

Copies the rectangles that make up the region, after `pMatrix` has been applied, into an array
sized with [GetRegionScansCount](#getregionscanscount). `nCount` points to a variable that
receives how many rectangles were written. As with the count, `pMatrix` must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pMatrix` | The transformation to apply first. |
| `rects` | The first element of the array that receives the rectangles. |
| `nCount` | Receives the number of rectangles. |

**Returns** `Ok` on success; `InvalidParameter` when `pMatrix` is `NULL`.

**Example**

```freebasic
dim r as CGpRegion = CGpRegion( 0, 0, 10, 10 )
dim identity as CGpMatrix
dim n as INT_ = r.GetRegionScansCount( @identity )
dim rects(0 to n - 1) as GpRectF
r.GetRegionScans( @identity, @rects(0), @n )
```

Microsoft Learn: [Region::GetRegionScans](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-region-getregionscans%28constmatrix_rectf_int%29)

## See also

- [CGpGraphicsPath](CGpGraphicsPath) for the shapes a region is built from
- [CGpGraphics](CGpGraphics) for `FillRegion` and clipping
- [CGpMatrix](CGpMatrix) for [Transform](#transform) and the region scans
- [sys/win/gdiplus](SysWin-GdiPlus)
