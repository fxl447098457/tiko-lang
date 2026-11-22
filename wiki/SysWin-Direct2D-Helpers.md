[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/direct2d](SysWin-Direct2D) › **Direct2D helpers**

# Direct2D helpers

Builds the points, rectangles, colours, matrices and property records Direct2D calls take.

Direct2D methods take small structures by value or by reference: a `D2D1_POINT_2F`, a
`D2D1_RECT_F`, a `D2D1_COLOR_F`, a `D2D1_MATRIX_3X2_F`, a `D2D1_RENDER_TARGET_PROPERTIES`. Each
function on this page fills one of them from its arguments and returns it, so it can be written
straight into a call: `pTarget->FillEllipse( D2D1_EllipseF( 60, 35, 50, 25 ), pBrush )`. They
allocate nothing and need nothing released, apart from [D2D1_SafeRelease](#d2d1_saferelease),
which releases an interface.

Coordinates are **device-independent pixels** (DIPs): 1/96 inch, so a render target at 96 DPI
maps one DIP to one pixel. Colours are four `single` values from 0 to 1, red, green, blue and
alpha. Angles are in **degrees**, clockwise on screen because y grows downwards.

The 3 × 2 matrices are row-vector affine transforms: a point is multiplied on the left,
`p * m`, and `a * b` means "apply `a`, then `b`". The `m31` and `m32` cells hold the
translation.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/direct2d"
using win, direct2d
```

## Example

A transform built from two helpers, applied to a point and undone, and the colour and shape
records a drawing call takes:

```freebasic
#import "sys/win"
#import "sys/win/direct2d"
using win, direct2d

' a transform: scale by 2 about (50, 50), then move 10 to the right
dim m as D2D1_MATRIX_3X2_F = D2D1_MatrixScale( 2, 2, D2D1_Point2F( 50, 50 ) ) * D2D1_MatrixTranslation( 10, 0 )
dim p as D2D1_POINT_2F = D2D1_Point2F( 60, 60 ) * m
print "(60, 60) maps to"; p.x; ","; p.y

' and back again
D2D1_InvertMatrix( m )
p = p * m
print "and back to"; p.x; ","; p.y

' a named colour as the four floats Direct2D uses
dim c as D2D1_COLOR_F = D2D1_ColorF( D2D1_Orange, 0.5 )
print "orange at half opacity:"; c.r; c.g; c.b; c.a

' the shapes the drawing calls take
dim rr as D2D1_ROUNDED_RECT = D2D1_RoundedRect( 10, 10, 110, 60, 8, 8 )
dim e as D2D1_ELLIPSE = D2D1_EllipseF( 60, 35, 50, 25 )
print "rounded rect"; rr.rect.left; rr.rect.top; rr.rect.right; rr.rect.bottom; ", ellipse radii"; e.radiusX; e.radiusY
```

It prints:

```
(60, 60) maps to 80, 70
and back to 60, 60
orange at half opacity: 1 0.6470588 0 0.5
rounded rect 10 10 110 60, ellipse radii 50 25
```

## Functions

| Function | Does |
| --- | --- |
| [D2D1_SafeRelease](#d2d1_saferelease) | Releases an interface pointer and sets it to `NULL`. |
| [D2D1_Point2F](#d2d1_point2f) | Makes a point with `single` coordinates. |
| [D2D1_Point2U](#d2d1_point2u) | Makes a point with unsigned coordinates. |
| [D2D1_Point2L](#d2d1_point2l) | Makes a point with signed 32-bit coordinates. |
| [D2D1_SizeF](#d2d1_sizef) | Makes a `single` width and height. |
| [D2D1_SizeU](#d2d1_sizeu) | Makes an unsigned width and height. |
| [D2D1_RectF](#d2d1_rectf) | Makes a rectangle with `single` edges. |
| [D2D1_RectU](#d2d1_rectu) | Makes a rectangle with unsigned edges. |
| [D2D1_RectL](#d2d1_rectl) | Makes a rectangle with signed 32-bit edges. |
| [D2D1_InfiniteRect](#d2d1_infiniterect) | Makes a rectangle that covers the whole plane. |
| [D2D1_InfiniteRectU](#d2d1_infiniterectu) | Makes the largest unsigned rectangle. |
| [D2D1_FloatMax](#d2d1_floatmax) | Returns the largest `single` value. |
| [D2D1_Vector2F](#d2d1_vector2f) | Makes a two-component vector. |
| [D2D1_Vector3F](#d2d1_vector3f) | Makes a three-component vector. |
| [D2D1_Vector_4F](#d2d1_vector_4f) | Makes a four-component vector. |
| [D2D1_EllipseF](#d2d1_ellipsef) | Makes an ellipse from a centre and two radii. |
| [D2D1_RoundedRect](#d2d1_roundedrect) | Makes a rectangle with rounded corners. |
| [D2D1_ArcSegment](#d2d1_arcsegment) | Makes an elliptical arc segment for a path. |
| [D2D1_BezierSegment](#d2d1_beziersegment) | Makes a cubic Bézier segment for a path. |
| [D2D1_QuadraticBezierSegment](#d2d1_quadraticbeziersegment) | Makes a quadratic Bézier segment for a path. |
| [KnowColor](#knowcolor) | The named colours, as `&hRRGGBB` values. |
| [sc_redShift, sc_greenShift, sc_blueShift, sc_redMask, sc_greenMask, sc_blueMask](#sc_redshift-sc_greenshift-sc_blueshift-sc_redmask-sc_greenmask-sc_bluemask) | Where each channel sits in an `&hRRGGBB` value. |
| [D2D1_InitColorF](#d2d1_initcolorf) | Turns an `&hRRGGBB` value and an alpha into a colour. |
| [D2D1_ColorF](#d2d1_colorf) | Makes a colour from `&hRRGGBB` or from four channels. |
| [D2D1_GradientStop](#d2d1_gradientstop) | Makes one stop of a gradient. |
| [D2D1_BrushProperties](#d2d1_brushproperties) | Makes the opacity and transform of a brush. |
| [D2D1_BitmapBrushProperties](#d2d1_bitmapbrushproperties) | Makes the extend and interpolation modes of a bitmap brush. |
| [D2D1_LinearGradientBrushProperties](#d2d1_lineargradientbrushproperties) | Makes the start and end of a linear gradient. |
| [D2D1_RadialGradientBrushProperties](#d2d1_radialgradientbrushproperties) | Makes the centre and radii of a radial gradient. |
| [D2D1_StrokeStyleProperties](#d2d1_strokestyleproperties) | Makes the caps, join and dashes of a stroke style. |
| [D2D1_StrokeStyleProperties1](#d2d1_strokestyleproperties1) | The same, with a stroke transform type. |
| [D2D1_PixelFormat](#d2d1_pixelformat) | Makes a pixel format and alpha mode. |
| [D2D1_BitmapProperties](#d2d1_bitmapproperties) | Makes the pixel format and DPI of a bitmap. |
| [D2D1_BitmapProperties1](#d2d1_bitmapproperties1) | The same, with bitmap options and a colour context. |
| [D2D1_RenderTargetProperties](#d2d1_rendertargetproperties) | Makes the type, format, DPI and usage of a render target. |
| [D2D1_HwndRenderTargetProperties](#d2d1_hwndrendertargetproperties) | Makes the window, size and present options of a window render target. |
| [D2D1_LayerParameters](#d2d1_layerparameters) | Makes the bounds, mask and opacity of a layer. |
| [D2D1_LayerParameters1](#d2d1_layerparameters1) | The same, with the newer layer options. |
| [D2D1_DrawingStateDescription](#d2d1_drawingstatedescription) | Makes the state a drawing state block saves. |
| [D2D1_DrawingStateDescription1](#d2d1_drawingstatedescription1) | The same, with primitive blend and unit mode. |
| [D2D1_ImageBrushProperties](#d2d1_imagebrushproperties) | Makes the source rectangle and modes of an image brush. |
| [D2D1_ImageBrushProperties1](#d2d1_imagebrushproperties1) | Makes the extend and interpolation modes of a newer bitmap brush. |
| [D2D1_PrintControlProperties](#d2d1_printcontrolproperties) | Makes the settings of a print control. |
| [D2D1_RenderingControls](#d2d1_renderingcontrols) | Makes the buffer precision and tile size of a device context. |
| [D2D1_EffectInputDescription](#d2d1_effectinputdescription) | Names an effect input and a rectangle on it. |
| [D2D1_CreationProperties](#d2d1_creationproperties) | Makes the threading, debug and options of a new device. |
| [D2D1_IdentityMatrix](#d2d1_identitymatrix) | Returns the 3 × 2 identity matrix. |
| [D2D1_Matrix3x2F](#d2d1_matrix3x2f) | Makes a 3 × 2 matrix from six values. |
| [D2D1_MatrixTranslation](#d2d1_matrixtranslation) | Makes a translation. |
| [D2D1_MatrixScale](#d2d1_matrixscale) | Makes a scale about a centre point. |
| [D2D1_MatrixRotation](#d2d1_matrixrotation) | Makes a rotation about a centre point. |
| [D2D1_MatrixSkew](#d2d1_matrixskew) | Makes a skew about a centre point. |
| [D2D1_MatrixDeterminant](#d2d1_matrixdeterminant) | Returns the determinant of a 3 × 2 matrix. |
| [D2D1_IsInvertibleMatrix](#d2d1_isinvertiblematrix) | Tells whether a 3 × 2 matrix can be inverted. |
| [D2D1_InvertMatrix](#d2d1_invertmatrix) | Inverts a 3 × 2 matrix in place. |
| [D2D1_IsIdentityMatrix](#d2d1_isidentitymatrix) | Tells whether a 3 × 2 matrix is the identity. |
| [D2D1_MultiplyMatrices](#d2d1_multiplymatrices) | Multiplies two 3 × 2 matrices. |
| [D2D1_MatrixTransformPoint](#d2d1_matrixtransformpoint) | Applies a 3 × 2 matrix to a point. |
| [Operator *](#operator-) | Multiplies matrices, or a point by a matrix. |
| [D2D1_ComputeFlatteningTolerance](#d2d1_computeflatteningtolerance) | Works out the flattening tolerance for a transform and DPI. |
| [D2D1_Matrix4x3F](#d2d1_matrix4x3f) | Makes a 4 × 3 matrix. |
| [D2D1_Matrix4x4F](#d2d1_matrix4x4f) | Makes a 4 × 4 matrix. |
| [D2D1_Matrix4x4FTranslation](#d2d1_matrix4x4ftranslation) | Makes a 3D translation. |
| [D2D1_Matrix4x4FScale](#d2d1_matrix4x4fscale) | Makes a 3D scale. |
| [D2D1_Matrix4x4FRotationX](#d2d1_matrix4x4frotationx) | Makes a rotation about the x axis. |
| [D2D1_Matrix4x4FRotationY](#d2d1_matrix4x4frotationy) | Makes a rotation about the y axis. |
| [D2D1_Matrix4x4FRotationZ](#d2d1_matrix4x4frotationz) | Makes a rotation about the z axis. |
| [D2D1_Matrix4x4FRotationArbitraryAxis](#d2d1_matrix4x4frotationarbitraryaxis) | Makes a rotation about any axis. |
| [D2D1_Matrix4x4FSkewX](#d2d1_matrix4x4fskewx) | Makes a 3D skew along x. |
| [D2D1_Matrix4x4FSkewY](#d2d1_matrix4x4fskewy) | Makes a 3D skew along y. |
| [D2D1_Matrix4x4FPerspectiveProjection](#d2d1_matrix4x4fperspectiveprojection) | Makes a perspective projection. |
| [D2D1_Matrix4x4FDeterminant](#d2d1_matrix4x4fdeterminant) | Returns the determinant of a 4 × 4 matrix. |
| [D2D1_Matrix4x4FIsIdentity](#d2d1_matrix4x4fisidentity) | Tells whether a 4 × 4 matrix is the identity, within a tolerance. |
| [D2D1_Matrix4x4FSetProduct](#d2d1_matrix4x4fsetproduct) | Multiplies two 4 × 4 matrices. |
| [D2D1_Matrix5x4F](#d2d1_matrix5x4f) | Makes a 5 × 4 colour matrix. |
| [D2D1_GradientMeshPatch](#d2d1_gradientmeshpatch) | Makes a gradient mesh patch from 16 points and 4 colours. |
| [D2D1_GradientMeshPatchFromCoonsPatch](#d2d1_gradientmeshpatchfromcoonspatch) | Makes a gradient mesh patch from the 12 points of a Coons patch. |
| [D2D1_InkPoint](#d2d1_inkpoint) | Makes a point of an ink stroke. |
| [D2D1_InkBezierSegment](#d2d1_inkbeziersegment) | Makes a Bézier segment of an ink stroke. |
| [D2D1_InkStyleProperties](#d2d1_inkstyleproperties) | Makes the nib of an ink style. |
| [D2D1_SimpleColorProfile](#d2d1_simplecolorprofile) | Makes a colour profile from primaries, white point and gamma. |

## Reference

### D2D1_SafeRelease

```freebasic
function D2D1_SafeRelease( byref pv as any ptr ) as ULONG
```

Calls `Release` on the interface `pv` points to and then sets `pv` to `NULL`, so the same
variable can be released twice without harm. `pv` is taken by reference: pass the pointer
variable itself, of any interface type (`ID2D1Factory ptr`, `ID2D1SolidColorBrush ptr` …). A
`NULL` pointer is left alone.

| Parameter | Meaning |
| --- | --- |
| `pv` | The interface pointer variable; it is `NULL` afterwards. |

**Returns** the reference count after the release (meant for diagnostics only), or 0 when `pv`
was already `NULL`.

**Example**

```freebasic
dim pFactory as ID2D1Factory ptr
D2D1CreateFactory( D2D1_FACTORY_TYPE_SINGLE_THREADED, IID_ID2D1Factory, byval NULL, pFactory )
D2D1_SafeRelease( pFactory )   ' pFactory is NULL now
```

Microsoft Learn: [IUnknown::Release](https://learn.microsoft.com/en-us/windows/win32/api/unknwn/nf-unknwn-iunknown-release)

### D2D1_Point2F

```freebasic
function D2D1_Point2F( byval x as FLOAT = 0.0, byval y as FLOAT = 0.0 ) as D2D1_POINT_2F
```

Returns a point with `single` coordinates; with no arguments, (0, 0). This is the point type
the drawing calls take.

**Returns** the `D2D1_POINT_2F`.

**Example**

```freebasic
dim pt as D2D1_POINT_2F = D2D1_Point2F( 10, 20 )
print pt.x; pt.y   ' 10 20
```

Microsoft Learn: [Point2F](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-point2f)

### D2D1_Point2U

```freebasic
function D2D1_Point2U( byval x as DWORD = 0, byval y as DWORD = 0 ) as D2D1_POINT_2U
```

Returns a point with unsigned 32-bit coordinates, as taken by the bitmap copy calls.

**Returns** the `D2D1_POINT_2U`.

**Example**

```freebasic
dim pt as D2D1_POINT_2U = D2D1_Point2U( 3, 4 )
```

Microsoft Learn: [Point2U](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-point2u)

### D2D1_Point2L

```freebasic
function D2D1_Point2L( byval x as INT32 = 0, byval y as INT32 = 0 ) as D2D1_POINT_2L
```

Returns a point with signed 32-bit coordinates. `D2D1_POINT_2L` is the Windows `POINT`
structure, so the result can be passed wherever a `POINT` is wanted.

**Returns** the `D2D1_POINT_2L`.

**Example**

```freebasic
dim pt as D2D1_POINT_2L = D2D1_Point2L( -5, 6 )
```

Microsoft Learn: [Point2L](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-point2l)

### D2D1_SizeF

```freebasic
function D2D1_SizeF( byval nWidth as FLOAT = 0.0, byval nHeight as FLOAT = 0.0 ) as D2D1_SIZE_F
```

Returns a width and height as `single` values.

**Returns** the `D2D1_SIZE_F`.

**Example**

```freebasic
dim sz as D2D1_SIZE_F = D2D1_SizeF( 640, 480 )
print sz.width; sz.height   ' 640 480
```

Microsoft Learn: [SizeF](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-sizef)

### D2D1_SizeU

```freebasic
function D2D1_SizeU( byval nWidth as UINT32 = 0, byval nHeight as UINT32 = 0 ) as D2D1_SIZE_U
```

Returns a width and height as unsigned 32-bit values: the pixel size of a window render target
or a bitmap.

**Returns** the `D2D1_SIZE_U`.

**Example**

```freebasic
var (l, t, r, b) = GetWindowClientRect( hwnd )
dim pixels as D2D1_SIZE_U = D2D1_SizeU( r, b )
```

Microsoft Learn: [SizeU](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-sizeu)

### D2D1_RectF

```freebasic
function D2D1_RectF( byval nLeft as FLOAT = 0.0, byval nTop as FLOAT = 0.0, byval nRight as FLOAT = 0.0, byval nBottom as FLOAT = 0.0 ) as D2D1_RECT_F
```

Returns a rectangle from its four edges (not from a width and height). This is the rectangle
type the drawing calls take.

**Returns** the `D2D1_RECT_F`.

**Example**

```freebasic
dim rc as D2D1_RECT_F = D2D1_RectF( 10, 20, 110, 70 )   ' 100 x 50 at (10, 20)
```

Microsoft Learn: [RectF](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-rectf)

### D2D1_RectU

```freebasic
function D2D1_RectU( byval nLeft as UINT32 = 0, byval nTop as UINT32 = 0, byval nRight as UINT32 = 0, byval nBottom as UINT32 = 0 ) as D2D1_RECT_U
```

Returns a rectangle with unsigned 32-bit edges, as taken by the bitmap copy calls.

**Returns** the `D2D1_RECT_U`.

**Example**

```freebasic
dim rc as D2D1_RECT_U = D2D1_RectU( 0, 0, 64, 64 )
```

Microsoft Learn: [RectU](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-rectu)

### D2D1_RectL

```freebasic
function D2D1_RectL( byval nLeft as INT32 = 0, byval nTop as INT32 = 0, byval nRight as INT32 = 0, byval nBottom as INT32 = 0 ) as D2D1_RECT_L
```

Returns a rectangle with signed 32-bit edges. `D2D1_RECT_L` is the Windows `RECT` structure.

**Returns** the `D2D1_RECT_L`.

**Example**

```freebasic
dim rc as D2D1_RECT_L = D2D1_RectL( -1, -2, 3, 4 )
```

Microsoft Learn: [RectL](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-rectl)

### D2D1_InfiniteRect

```freebasic
function D2D1_InfiniteRect() as D2D1_RECT_F
```

Returns a rectangle from (−3.402823e+38, −3.402823e+38) to (3.402823e+38, 3.402823e+38): the
largest `single` value on each side, which Direct2D treats as "no bounds". It is the default
content bounds of a layer.

**Returns** the `D2D1_RECT_F`.

**Example**

```freebasic
dim rc as D2D1_RECT_F = D2D1_InfiniteRect()
print rc.right   ' 3.402823e+038
```

Microsoft Learn: [InfiniteRect](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-infiniterect)

### D2D1_InfiniteRectU

```freebasic
function D2D1_InfiniteRectU() as D2D1_RECT_U
```

Returns the unsigned rectangle from (0, 0) to (&hFFFFFFFF, &hFFFFFFFF), the largest `UINT32` on
both sides.

**Returns** the `D2D1_RECT_U`.

**Example**

```freebasic
dim rc as D2D1_RECT_U = D2D1_InfiniteRectU()
print rc.right   ' 4294967295, that is &hFFFFFFFF
```

Microsoft Learn: [InfiniteRectU](https://learn.microsoft.com/en-us/windows/win32/direct2d/infiniterectu)

### D2D1_FloatMax

```freebasic
function D2D1_FloatMax() as FLOAT
```

Returns the largest finite `single` value, 3.402823e+38.

**Returns** the value.

**Example**

```freebasic
print D2D1_FloatMax()   ' 3.402823e+038
```

Microsoft Learn: [FloatMax](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-floatmax)

### D2D1_Vector2F

```freebasic
function D2D1_Vector2F( byval x as FLOAT = 0.0, byval y as FLOAT = 0.0 ) as D2D1_VECTOR_2F
```

Returns a two-component vector, as some effect properties take.

**Returns** the `D2D1_VECTOR_2F`.

**Example**

```freebasic
dim v as D2D1_VECTOR_2F = D2D1_Vector2F( 1, 2 )
```

Microsoft Learn: [Vector2F](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-vector2f)

### D2D1_Vector3F

```freebasic
function D2D1_Vector3F( byval x as FLOAT = 0.0, byval y as FLOAT = 0.0, byval z as FLOAT = 0.0 ) as D2D1_VECTOR_3F
```

Meant to return a three-component vector. As written it stores `x` in `x` and `z` in `y`, and
leaves `z` at 0: `D2D1_Vector3F( 1, 2, 3 )` gives (1, 3, 0). Set the fields yourself when all
three matter.

**Returns** the `D2D1_VECTOR_3F`.

**Example**

```freebasic
dim v as D2D1_VECTOR_3F
v.x = 1 : v.y = 2 : v.z = 3   ' D2D1_Vector3F( 1, 2, 3 ) would give 1 3 0
```

Microsoft Learn: [Vector3F](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-vector3f)

### D2D1_Vector_4F

```freebasic
function D2D1_Vector_4F( byval x as FLOAT = 0.0, byval y as FLOAT = 0.0, byval z as FLOAT = 0.0, byval w as FLOAT = 0.0 ) as D2D1_VECTOR_4F
```

Meant to return a four-component vector (note the underscore in the name). As written it
stores `x` in `x` and `w` in `y`, and leaves `z` and `w` at 0: `D2D1_Vector_4F( 1, 2, 3, 4 )`
gives (1, 4, 0, 0). Set the fields yourself when they matter.

**Returns** the `D2D1_VECTOR_4F`.

**Example**

```freebasic
dim v as D2D1_VECTOR_4F
v.x = 1 : v.y = 2 : v.z = 3 : v.w = 4   ' D2D1_Vector_4F( 1, 2, 3, 4 ) would give 1 4 0 0
```

Microsoft Learn: [Vector4F](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-vector4f)

### D2D1_EllipseF

```freebasic
function D2D1_EllipseF overload( byval center as D2D1_POINT_2F, byval radiusX as FLOAT, byval radiusY as FLOAT ) as D2D1_ELLIPSE
function D2D1_EllipseF overload( byval x as FLOAT, byval y as FLOAT, byval radiusX as FLOAT, byval radiusY as FLOAT ) as D2D1_ELLIPSE
```

Returns an ellipse from its centre, given as a point or as `x` and `y`, and its horizontal and
vertical radii. Equal radii give a circle. `DrawEllipse` and `FillEllipse` take it.

| Parameter | Meaning |
| --- | --- |
| `center` or `x`, `y` | The centre. |
| `radiusX`, `radiusY` | Half the width and half the height. |

**Returns** the `D2D1_ELLIPSE`.

**Example**

```freebasic
dim pTarget as ID2D1RenderTarget ptr, pBrush as ID2D1SolidColorBrush ptr
if pTarget then pTarget->FillEllipse( D2D1_EllipseF( 100, 100, 50, 30 ), pBrush )
```

Microsoft Learn: [Ellipse](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-ellipse)

### D2D1_RoundedRect

```freebasic
function D2D1_RoundedRect overload( byref rc as D2D1_RECT_F, byval radiusX as FLOAT, byval radiusY as FLOAT ) as D2D1_ROUNDED_RECT
function D2D1_RoundedRect overload( byval nLeft as FLOAT, byval nTop as FLOAT, byval nRight as FLOAT, byval nBottom as FLOAT, byval radiusX as FLOAT, byval radiusY as FLOAT ) as D2D1_ROUNDED_RECT
```

Returns a rectangle, given as a `D2D1_RECT_F` or as four edges, with the horizontal and
vertical radii of its corners. `DrawRoundedRectangle` and `FillRoundedRectangle` take it.

**Returns** the `D2D1_ROUNDED_RECT`.

**Example**

```freebasic
dim rr as D2D1_ROUNDED_RECT = D2D1_RoundedRect( D2D1_RectF( 0, 0, 100, 50 ), 8, 8 )
```

Microsoft Learn: [RoundedRect](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-roundedrect)

### D2D1_ArcSegment

```freebasic
function D2D1_ArcSegment( byref pf as D2D1_POINT_2F, byref sf as D2D1_SIZE_F, byval rotationAngle as FLOAT, byval sweepDirection as D2D1_SWEEP_DIRECTION, byval arcSize as D2D1_ARC_SIZE ) as D2D1_ARC_SEGMENT
```

Returns an elliptical arc for a geometry sink's `AddArc`: the arc runs from the sink's current
point to `pf` along an ellipse of radii `sf`.

| Parameter | Meaning |
| --- | --- |
| `pf` | The end point of the arc. |
| `sf` | The x and y radii of the ellipse. |
| `rotationAngle` | Rotation of the ellipse, in degrees, clockwise. |
| `sweepDirection` | `D2D1_SWEEP_DIRECTION_CLOCKWISE` or `D2D1_SWEEP_DIRECTION_COUNTER_CLOCKWISE`. |
| `arcSize` | `D2D1_ARC_SIZE_SMALL` (180° or less) or `D2D1_ARC_SIZE_LARGE`. |

**Returns** the `D2D1_ARC_SEGMENT`.

**Example**

```freebasic
dim seg as D2D1_ARC_SEGMENT = D2D1_ArcSegment( D2D1_Point2F( 100, 50 ), D2D1_SizeF( 50, 25 ), 0, D2D1_SWEEP_DIRECTION_CLOCKWISE, D2D1_ARC_SIZE_SMALL )
```

Microsoft Learn: [ArcSegment](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-arcsegment)

### D2D1_BezierSegment

```freebasic
function D2D1_BezierSegment( byref point1 as D2D1_POINT_2F, byref point2 as D2D1_POINT_2F, byref point3 as D2D1_POINT_2F ) as D2D1_BEZIER_SEGMENT
```

Returns a cubic Bézier segment for a geometry sink's `AddBezier`: `point1` and `point2` are the
control points and `point3` the end point; the start is the sink's current point.

**Returns** the `D2D1_BEZIER_SEGMENT`.

**Example**

```freebasic
dim bz as D2D1_BEZIER_SEGMENT = D2D1_BezierSegment( D2D1_Point2F( 30, 0 ), D2D1_Point2F( 70, 100 ), D2D1_Point2F( 100, 50 ) )
```

Microsoft Learn: [BezierSegment](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-beziersegment)

### D2D1_QuadraticBezierSegment

```freebasic
function D2D1_QuadraticBezierSegment( byref point1 as D2D1_POINT_2F, byref point2 as D2D1_POINT_2F ) as D2D1_QUADRATIC_BEZIER_SEGMENT
```

Returns a quadratic Bézier segment for a geometry sink's `AddQuadraticBezier`: `point1` is the
control point and `point2` the end point.

**Returns** the `D2D1_QUADRATIC_BEZIER_SEGMENT`.

**Example**

```freebasic
dim q as D2D1_QUADRATIC_BEZIER_SEGMENT = D2D1_QuadraticBezierSegment( D2D1_Point2F( 50, 0 ), D2D1_Point2F( 100, 50 ) )
```

Microsoft Learn: [QuadraticBezierSegment](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-quadraticbeziersegment)

### KnowColor

```freebasic
enum KnowColor
   D2D1_AliceBlue = &HF0F8FF
   ...
   D2D1_YellowGreen = &H9ACD32
end enum
```

The 140 named web colours, from `D2D1_AliceBlue` to `D2D1_YellowGreen`, each an `&hRRGGBB`
value with red in the high byte: `D2D1_Red` is `&hFF0000`, `D2D1_CornflowerBlue` is
`&h6495ED`. This is the opposite byte order from a GDI `COLORREF`, so pass these to
[D2D1_ColorF](#d2d1_colorf) or [D2D1_GradientStop](#d2d1_gradientstop), not to GDI.
`D2D1_Aqua` and `D2D1_Cyan`, and `D2D1_Fuchsia` and `D2D1_Magenta`, are the same colour.

**Example**

```freebasic
dim c as D2D1_COLOR_F = D2D1_ColorF( D2D1_CornflowerBlue )
print c.r; c.g; c.b   ' 0.3921569 0.5843138 0.9294118
```

Microsoft Learn: [ColorF](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nl-d2d1helper-colorf)

### sc_redShift, sc_greenShift, sc_blueShift, sc_redMask, sc_greenMask, sc_blueMask

```freebasic
const as UINT32 sc_redShift = 16
const as UINT32 sc_greenShift = 8
const as UINT32 sc_blueShift = 0
const as UINT32 sc_redMask = &H00FF0000
const as UINT32 sc_greenMask = &H0000FF00
const as UINT32 sc_blueMask = &H000000FF
```

The bit position and mask of each channel in an `&hRRGGBB` value, as
[D2D1_InitColorF](#d2d1_initcolorf) reads it.

**Example**

```freebasic
dim green as UINT32 = ( D2D1_Orange and sc_greenMask ) shr sc_greenShift
print green   ' 165
```

### D2D1_InitColorF

```freebasic
function D2D1_InitColorF( byval urgb as UINT32, byval alpha as FLOAT ) as D2D1_COLOR_F
```

Splits an `&hRRGGBB` value into red, green and blue, divides each by 255 and adds `alpha`. It is
the worker behind the first form of [D2D1_ColorF](#d2d1_colorf), which is usually the one to
call.

**Returns** the `D2D1_COLOR_F`.

**Example**

```freebasic
dim c as D2D1_COLOR_F = D2D1_InitColorF( &h0000FF, 0.75 )   ' 0 0 1 0.75
```

### D2D1_ColorF

```freebasic
function D2D1_ColorF overload( byval urgb as UINT32, byval a as FLOAT = 1.0 ) as D2D1_COLOR_F
function D2D1_ColorF overload( byval red as FLOAT, byval green as FLOAT, byval blue as FLOAT, byval alpha as FLOAT = 1.0 ) as D2D1_COLOR_F
```

Returns a colour. The first form takes an `&hRRGGBB` value, such as a [KnowColor](#knowcolor)
name, and an opacity; the second takes the four channels as numbers from 0 to 1. Alpha
defaults to 1, fully opaque.

The colour is straight (not premultiplied) alpha; Direct2D premultiplies it itself where the
target needs it.

| Parameter | Meaning |
| --- | --- |
| `urgb` | Red, green and blue as `&hRRGGBB`. |
| `a`, `alpha` | Opacity, 0 (transparent) to 1 (opaque). |
| `red`, `green`, `blue` | Each channel, 0 to 1. |

**Returns** the `D2D1_COLOR_F`.

**Example**

```freebasic
dim pTarget as ID2D1RenderTarget ptr
if pTarget then pTarget->Clear( D2D1_ColorF( D2D1_White ) )
dim c as D2D1_COLOR_F = D2D1_ColorF( &hFF8000, 0.5 )   ' 1 0.5019608 0 0.5
```

Microsoft Learn: [ColorF](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nl-d2d1helper-colorf)

### D2D1_GradientStop

```freebasic
function D2D1_GradientStop overload( byval position as FLOAT, byref clr as D2D1_COLOR_F ) as D2D1_GRADIENT_STOP
function D2D1_GradientStop overload( byval position as FLOAT, byval clr as UINT32, byval alpha as FLOAT = 1.0 ) as D2D1_GRADIENT_STOP
```

Returns one stop of a gradient: a colour, as a `D2D1_COLOR_F` or as `&hRRGGBB` and an alpha, and
its `position` along the gradient from 0 to 1. An array of stops goes to
`CreateGradientStopCollection`.

**Returns** the `D2D1_GRADIENT_STOP`.

**Example**

```freebasic
dim stops(1) as D2D1_GRADIENT_STOP
stops(0) = D2D1_GradientStop( 0, D2D1_Yellow )
stops(1) = D2D1_GradientStop( 1, D2D1_ColorF( 0, 0, 1 ) )
```

Microsoft Learn: [GradientStop](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-gradientstop)

### D2D1_BrushProperties

```freebasic
function D2D1_BrushProperties( byval opacity as FLOAT = 1.0, byref transform as D2D1_MATRIX_3X2_F = D2D1_IdentityMatrix() ) as D2D1_BRUSH_PROPERTIES
```

Returns the opacity (0 to 1) and transform shared by every kind of brush. The defaults, opaque
and untransformed, are what most brushes want, so `D2D1_BrushProperties()` is the usual second
argument to `CreateSolidColorBrush`.

**Returns** the `D2D1_BRUSH_PROPERTIES`.

**Example**

```freebasic
dim pTarget as ID2D1RenderTarget ptr, pBrush as ID2D1SolidColorBrush ptr
if pTarget then pTarget->CreateSolidColorBrush( D2D1_ColorF( D2D1_Navy ), D2D1_BrushProperties( 0.5 ), pBrush )
```

Microsoft Learn: [BrushProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-brushproperties)

### D2D1_BitmapBrushProperties

```freebasic
function D2D1_BitmapBrushProperties( byval extendModeX as D2D1_EXTEND_MODE = D2D1_EXTEND_MODE_CLAMP, byval extendModeY as D2D1_EXTEND_MODE = D2D1_EXTEND_MODE_CLAMP, byval interpolationMode as D2D1_BITMAP_INTERPOLATION_MODE = D2D1_BITMAP_INTERPOLATION_MODE_LINEAR ) as D2D1_BITMAP_BRUSH_PROPERTIES
```

Returns how a bitmap brush paints beyond its bitmap in each direction (`D2D1_EXTEND_MODE_CLAMP`,
`_WRAP` to tile, `_MIRROR`) and how the bitmap is sampled when scaled.

**Returns** the `D2D1_BITMAP_BRUSH_PROPERTIES`.

**Example**

```freebasic
dim bbp as D2D1_BITMAP_BRUSH_PROPERTIES = D2D1_BitmapBrushProperties( D2D1_EXTEND_MODE_WRAP, D2D1_EXTEND_MODE_WRAP )
```

Microsoft Learn: [BitmapBrushProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-bitmapbrushproperties)

### D2D1_LinearGradientBrushProperties

```freebasic
function D2D1_LinearGradientBrushProperties( byref startPoint as const D2D1_POINT_2F, byref endPoint as const D2D1_POINT_2F ) as D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES
```

Returns the line a linear gradient runs along: stop position 0 is drawn at `startPoint` and 1 at
`endPoint`, in the brush's coordinates.

**Returns** the `D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES`.

**Example**

```freebasic
dim lg as D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES = D2D1_LinearGradientBrushProperties( D2D1_Point2F( 0, 0 ), D2D1_Point2F( 200, 0 ) )
```

Microsoft Learn: [LinearGradientBrushProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-lineargradientbrushproperties)

### D2D1_RadialGradientBrushProperties

```freebasic
function D2D1_RadialGradientBrushProperties( byref center as D2D1_POINT_2F, byref gradientOriginOffset as D2D1_POINT_2F, byval radiusX as FLOAT, byval radiusY as FLOAT ) as D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES
```

Returns the ellipse a radial gradient fills: stop 1 lies on the ellipse of radii `radiusX`,
`radiusY` around `center`, and stop 0 at the gradient origin, which is `center` moved by
`gradientOriginOffset`.

**Returns** the `D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES`.

**Example**

```freebasic
dim rg as D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES = D2D1_RadialGradientBrushProperties( D2D1_Point2F( 100, 100 ), D2D1_Point2F( 0, 0 ), 80, 60 )
```

Microsoft Learn: [RadialGradientBrushProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-radialgradientbrushproperties)

### D2D1_StrokeStyleProperties

```freebasic
function D2D1_StrokeStyleProperties( byval startCap as D2D1_CAP_STYLE = D2D1_CAP_STYLE_FLAT, byval endCap as D2D1_CAP_STYLE = D2D1_CAP_STYLE_FLAT, byval dashCap as D2D1_CAP_STYLE = D2D1_CAP_STYLE_FLAT, byval lineJoin as D2D1_LINE_JOIN = D2D1_LINE_JOIN_MITER, byval miterLimit as FLOAT = 10.0, byval dashStyle as D2D1_DASH_STYLE = D2D1_DASH_STYLE_SOLID, byval dashOffset as FLOAT = 0.0 ) as D2D1_STROKE_STYLE_PROPERTIES
```

Returns the settings of a stroke style for the factory's `CreateStrokeStyle`. The defaults give
a plain solid line with flat ends and mitred corners.

| Parameter | Meaning |
| --- | --- |
| `startCap`, `endCap` | Shape of the two ends of an open figure: `D2D1_CAP_STYLE_FLAT`, `_SQUARE`, `_ROUND`, `_TRIANGLE`. |
| `dashCap` | Shape of the ends of each dash. |
| `lineJoin` | Corners: `D2D1_LINE_JOIN_MITER`, `_BEVEL`, `_ROUND`, `_MITER_OR_BEVEL`. |
| `miterLimit` | How far a mitred corner may stick out, in multiples of half the stroke width. |
| `dashStyle` | `D2D1_DASH_STYLE_SOLID`, `_DASH`, `_DOT`, `_DASH_DOT`, `_DASH_DOT_DOT`, `_CUSTOM`. |
| `dashOffset` | Where in the dash pattern the line starts, in stroke widths. |

**Returns** the `D2D1_STROKE_STYLE_PROPERTIES`.

**Example**

```freebasic
dim ssp as D2D1_STROKE_STYLE_PROPERTIES = D2D1_StrokeStyleProperties( D2D1_CAP_STYLE_ROUND, D2D1_CAP_STYLE_ROUND, D2D1_CAP_STYLE_ROUND, D2D1_LINE_JOIN_ROUND, 10, D2D1_DASH_STYLE_DASH )
```

Microsoft Learn: [StrokeStyleProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-strokestyleproperties)

### D2D1_StrokeStyleProperties1

```freebasic
function D2D1_StrokeStyleProperties1( byval startCap as D2D1_CAP_STYLE = D2D1_CAP_STYLE_FLAT, byval endCap as D2D1_CAP_STYLE = D2D1_CAP_STYLE_FLAT, byval dashCap as D2D1_CAP_STYLE = D2D1_CAP_STYLE_FLAT, byval lineJoin as D2D1_LINE_JOIN = D2D1_LINE_JOIN_MITER, byval miterLimit as FLOAT = 10, byval dashStyle as D2D1_DASH_STYLE = D2D1_DASH_STYLE_SOLID, byval dashOffset as FLOAT = 0.0, byval transformType as D2D1_STROKE_TRANSFORM_TYPE = D2D1_STROKE_TRANSFORM_TYPE_NORMAL ) as D2D1_STROKE_STYLE_PROPERTIES1
```

The same as [D2D1_StrokeStyleProperties](#d2d1_strokestyleproperties), for `ID2D1Factory1`'s
`CreateStrokeStyle`, plus `transformType`: `D2D1_STROKE_TRANSFORM_TYPE_NORMAL` scales the stroke
with the world transform, `_FIXED` keeps its width, `_HAIRLINE` draws it one pixel wide.

**Returns** the `D2D1_STROKE_STYLE_PROPERTIES1`.

**Example**

```freebasic
dim ssp as D2D1_STROKE_STYLE_PROPERTIES1 = D2D1_StrokeStyleProperties1( , , , , , , , D2D1_STROKE_TRANSFORM_TYPE_FIXED )
```

Microsoft Learn: [StrokeStyleProperties1](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-strokestyleproperties1)

### D2D1_PixelFormat

```freebasic
function D2D1_PixelFormat( byval dxgiFormat as DXGI_FORMAT = DXGI_FORMAT_UNKNOWN, byval alphaMode as D2D1_ALPHA_MODE = D2D1_ALPHA_MODE_UNKNOWN ) as D2D1_PIXEL_FORMAT
```

Returns a pixel format and alpha mode. With no arguments both are "unknown" (0), which lets a
render target choose its own format.

**Returns** the `D2D1_PIXEL_FORMAT`.

**Example**

```freebasic
dim pf as D2D1_PIXEL_FORMAT = D2D1_PixelFormat( DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED )
```

Microsoft Learn: [PixelFormat](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-pixelformat)

### D2D1_BitmapProperties

```freebasic
function D2D1_BitmapProperties( byref pixelFormat as D2D1_PIXEL_FORMAT = D2D1_PixelFormat(), byval dpiX as FLOAT = 96.0, byval dpiY as FLOAT = 96.0 ) as D2D1_BITMAP_PROPERTIES
```

Returns the pixel format and resolution of a bitmap for `CreateBitmap` and its relatives. The
DPI defaults to 96, so one bitmap pixel is one DIP.

**Returns** the `D2D1_BITMAP_PROPERTIES`.

**Example**

```freebasic
dim bp as D2D1_BITMAP_PROPERTIES = D2D1_BitmapProperties( D2D1_PixelFormat( DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED ) )
```

Microsoft Learn: [BitmapProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-bitmapproperties)

### D2D1_BitmapProperties1

```freebasic
function D2D1_BitmapProperties1( byval bitmapOptions as D2D1_BITMAP_OPTIONS = D2D1_BITMAP_OPTIONS_NONE, byval pixelFormat as const D2D1_PIXEL_FORMAT = D2D1_PixelFormat(), byval dpiX as FLOAT = 96.0, byval dpiY as FLOAT = 96.0, byval colorContext as ID2D1ColorContext ptr = NULL ) as D2D1_BITMAP_PROPERTIES1
```

Returns the properties of an `ID2D1Bitmap1` for a device context: how the bitmap may be used
(`D2D1_BITMAP_OPTIONS_TARGET`, `_CPU_READ`, `_CANNOT_DRAW`, `_GDI_COMPATIBLE`, combined with
`or`), its format, DPI and an optional colour context. The colour context is stored as given,
without an extra reference.

**Returns** the `D2D1_BITMAP_PROPERTIES1`.

**Example**

```freebasic
dim bp as D2D1_BITMAP_PROPERTIES1 = D2D1_BitmapProperties1( D2D1_BITMAP_OPTIONS_TARGET, D2D1_PixelFormat( DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED ) )
```

Microsoft Learn: [BitmapProperties1](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-bitmapproperties1)

### D2D1_RenderTargetProperties

```freebasic
function D2D1_RenderTargetProperties( byval nType as D2D1_RENDER_TARGET_TYPE = D2D1_RENDER_TARGET_TYPE_DEFAULT, byref pixelFormat as D2D1_PIXEL_FORMAT = D2D1_PixelFormat(), byval dpiX as FLOAT = 0.0, byval dpiY as FLOAT = 0.0, byval usage as D2D1_RENDER_TARGET_USAGE = D2D1_RENDER_TARGET_USAGE_NONE, byval minLevel as D2D1_FEATURE_LEVEL = D2D1_FEATURE_LEVEL_DEFAULT ) as D2D1_RENDER_TARGET_PROPERTIES
```

Returns the settings every render target is created with. The defaults ask for hardware
rendering where available, the target's own pixel format and the desktop DPI (0 means "use the
default"), which suits a window render target. A DC render target needs an explicit format,
such as `DXGI_FORMAT_B8G8R8A8_UNORM` with `D2D1_ALPHA_MODE_IGNORE`.

| Parameter | Meaning |
| --- | --- |
| `nType` | `D2D1_RENDER_TARGET_TYPE_DEFAULT`, `_SOFTWARE` or `_HARDWARE`. |
| `pixelFormat` | The pixel format and alpha mode. |
| `dpiX`, `dpiY` | The DPI; 0 for the default. |
| `usage` | `D2D1_RENDER_TARGET_USAGE_*` flags, such as `_GDI_COMPATIBLE`. |
| `minLevel` | The lowest Direct3D feature level accepted for hardware rendering. |

**Returns** the `D2D1_RENDER_TARGET_PROPERTIES`.

**Example**

```freebasic
dim rtp as D2D1_RENDER_TARGET_PROPERTIES = D2D1_RenderTargetProperties( D2D1_RENDER_TARGET_TYPE_DEFAULT, D2D1_PixelFormat( DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_IGNORE ) )
```

Microsoft Learn: [RenderTargetProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-rendertargetproperties)

### D2D1_HwndRenderTargetProperties

```freebasic
function D2D1_HwndRenderTargetProperties overload( byval hwnd as HWND, byval pixelSize as D2D1_SIZE_U = D2D1_SizeU(0, 0), byval presentOptions as D2D1_PRESENT_OPTIONS = D2D1_PRESENT_OPTIONS_NONE ) as D2D1_HWND_RENDER_TARGET_PROPERTIES
function D2D1_HwndRenderTargetProperties overload( byval hwnd as HWND, byval pixelWidth as UINT32 = 0, byval pixelHeight as UINT32 = 0, byval presentOptions as D2D1_PRESENT_OPTIONS = D2D1_PRESENT_OPTIONS_NONE ) as D2D1_HWND_RENDER_TARGET_PROPERTIES
```

Returns the window a window render target draws into, its size in **pixels** (usually the
client area's), and how it presents. `D2D1_PRESENT_OPTIONS_IMMEDIATELY` does not wait for the
display refresh; `_RETAIN_CONTENTS` keeps the previous frame.

The two forms have the same defaults after `hwnd`, so a call that passes only the window
matches both and does not compile: pass the size as well. In the second form `pixelWidth` and
`pixelHeight` are `byref UINT32`, so pass numbers or `UINT32` variables; a `long` variable does
not convert, which is why the example uses the `D2D1_SizeU` form for the client size.

**Returns** the `D2D1_HWND_RENDER_TARGET_PROPERTIES`.

**Example**

```freebasic
var (l, t, r, b) = GetWindowClientRect( hwnd )
dim hp as D2D1_HWND_RENDER_TARGET_PROPERTIES = D2D1_HwndRenderTargetProperties( hwnd, D2D1_SizeU( r, b ) )
hp = D2D1_HwndRenderTargetProperties( hwnd, 320, 240, D2D1_PRESENT_OPTIONS_IMMEDIATELY )
```

Microsoft Learn: [HwndRenderTargetProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-hwndrendertargetproperties)

### D2D1_LayerParameters

```freebasic
function D2D1_LayerParameters( byref contentBounds as D2D1_RECT_F = D2D1_InfiniteRect(), byval geometricMask as ID2D1Geometry ptr = NULL, byval maskAntialiasMode as D2D1_ANTIALIAS_MODE = D2D1_ANTIALIAS_MODE_PER_PRIMITIVE, byref maskTransform as D2D1_MATRIX_3X2_F = D2D1_IdentityMatrix(), byval opacity as FLOAT = 1.0, byval opacityBrush as ID2D1Brush ptr = NULL, byval layerOptions as D2D1_LAYER_OPTIONS = D2D1_LAYER_OPTIONS_NONE ) as D2D1_LAYER_PARAMETERS
```

Returns the parameters of `PushLayer`: what is drawn until the matching `PopLayer` is kept
inside `contentBounds` and `geometricMask`, and faded by `opacity` and `opacityBrush`. The
defaults clip and fade nothing. The geometry and brush pointers are stored as given, without an
extra reference.

| Parameter | Meaning |
| --- | --- |
| `contentBounds` | Content outside this rectangle is dropped. |
| `geometricMask` | A geometry to clip to, or `NULL`. |
| `maskAntialiasMode` | Antialiasing of the mask's edge. |
| `maskTransform` | Transform applied to the mask. |
| `opacity` | Opacity of the layer, 0 to 1. |
| `opacityBrush` | A brush whose alpha fades the layer, or `NULL`. |
| `layerOptions` | `D2D1_LAYER_OPTIONS_INITIALIZE_FOR_CLEARTYPE` or none. |

**Returns** the `D2D1_LAYER_PARAMETERS`.

**Example**

```freebasic
dim pTarget as ID2D1RenderTarget ptr, pLayer as ID2D1Layer ptr
if pTarget then pTarget->PushLayer( D2D1_LayerParameters( D2D1_RectF( 0, 0, 200, 100 ), , , , 0.5 ), pLayer )
```

Microsoft Learn: [LayerParameters](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-layerparameters)

### D2D1_LayerParameters1

```freebasic
function D2D1_LayerParameters1( byref contentBounds as const D2D1_RECT_F = D2D1_InfiniteRect(), byval geometricMask as ID2D1Geometry ptr = NULL, byval maskAntialiasMode as D2D1_ANTIALIAS_MODE = D2D1_ANTIALIAS_MODE_PER_PRIMITIVE, byref maskTransform as D2D1_MATRIX_3X2_F = D2D1_IdentityMatrix(), byval opacity as FLOAT = 1.0, byval opacityBrush as ID2D1Brush ptr = NULL, byval layerOptions as D2D1_LAYER_OPTIONS1 = D2D1_LAYER_OPTIONS1_NONE ) as D2D1_LAYER_PARAMETERS1
```

The same as [D2D1_LayerParameters](#d2d1_layerparameters), for a device context, with the
Direct2D 1.1 options: `D2D1_LAYER_OPTIONS1_INITIALIZE_FROM_BACKGROUND` and
`D2D1_LAYER_OPTIONS1_IGNORE_ALPHA`.

**Returns** the `D2D1_LAYER_PARAMETERS1`.

**Example**

```freebasic
dim lp as D2D1_LAYER_PARAMETERS1 = D2D1_LayerParameters1( , , , , 0.75 )
```

Microsoft Learn: [LayerParameters1](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-layerparameters1)

### D2D1_DrawingStateDescription

```freebasic
function D2D1_DrawingStateDescription( byval antialiasMode as D2D1_ANTIALIAS_MODE = D2D1_ANTIALIAS_MODE_PER_PRIMITIVE, byval textAntialiasMode as D2D1_TEXT_ANTIALIAS_MODE = D2D1_TEXT_ANTIALIAS_MODE_DEFAULT, byval tag1 as D2D1_TAG = 0, byval tag2 as D2D1_TAG = 0, byref transform as D2D1_MATRIX_3X2_F = D2D1_IdentityMatrix() ) as D2D1_DRAWING_STATE_DESCRIPTION
```

Returns the state a drawing state block holds: the antialias modes, the two tags used to find
failing calls, and the transform. The defaults are a render target's initial state.

**Returns** the `D2D1_DRAWING_STATE_DESCRIPTION`.

**Example**

```freebasic
dim ds as D2D1_DRAWING_STATE_DESCRIPTION = D2D1_DrawingStateDescription( D2D1_ANTIALIAS_MODE_ALIASED )
```

Microsoft Learn: [DrawingStateDescription](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-drawingstatedescription)

### D2D1_DrawingStateDescription1

```freebasic
function D2D1_DrawingStateDescription1 overload( byval antialiasMode as D2D1_ANTIALIAS_MODE = D2D1_ANTIALIAS_MODE_PER_PRIMITIVE, byval textAntialiasMode as D2D1_TEXT_ANTIALIAS_MODE = D2D1_TEXT_ANTIALIAS_MODE_DEFAULT, byval tag1 as D2D1_TAG = 0, byval tag2 as D2D1_TAG = 0, byref transform as D2D1_MATRIX_3X2_F = D2D1_IdentityMatrix(), byval primitiveBlend as D2D1_PRIMITIVE_BLEND = D2D1_PRIMITIVE_BLEND_SOURCE_OVER, byval unitMode as D2D1_UNIT_MODE = D2D1_UNIT_MODE_DIPS ) as D2D1_DRAWING_STATE_DESCRIPTION1
function D2D1_DrawingStateDescription1 overload( byref desc as const D2D1_DRAWING_STATE_DESCRIPTION, byval primitiveBlend as D2D1_PRIMITIVE_BLEND = D2D1_PRIMITIVE_BLEND_SOURCE_OVER, byval unitMode as D2D1_UNIT_MODE = D2D1_UNIT_MODE_DIPS ) as D2D1_DRAWING_STATE_DESCRIPTION1
```

The device-context version of [D2D1_DrawingStateDescription](#d2d1_drawingstatedescription),
with the primitive blend and whether units are DIPs or pixels. The second form copies an
existing `D2D1_DRAWING_STATE_DESCRIPTION` and adds the two.

**Returns** the `D2D1_DRAWING_STATE_DESCRIPTION1`.

**Example**

```freebasic
dim ds as D2D1_DRAWING_STATE_DESCRIPTION = D2D1_DrawingStateDescription()
dim ds1 as D2D1_DRAWING_STATE_DESCRIPTION1 = D2D1_DrawingStateDescription1( ds, D2D1_PRIMITIVE_BLEND_COPY, D2D1_UNIT_MODE_PIXELS )
```

Microsoft Learn: [DrawingStateDescription1](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-drawingstatedescription1)

### D2D1_ImageBrushProperties

```freebasic
function D2D1_ImageBrushProperties( byval sourceRectangle as D2D1_RECT_F, byval extendModeX as D2D1_EXTEND_MODE = D2D1_EXTEND_MODE_CLAMP, byval extendModeY as D2D1_EXTEND_MODE = D2D1_EXTEND_MODE_CLAMP, byval interpolationMode as D2D1_INTERPOLATION_MODE = D2D1_INTERPOLATION_MODE_LINEAR ) as D2D1_IMAGE_BRUSH_PROPERTIES
```

Returns the part of an image an image brush paints with, `sourceRectangle`, how it extends past
that part and how it is sampled.

**Returns** the `D2D1_IMAGE_BRUSH_PROPERTIES`.

**Example**

```freebasic
dim ib as D2D1_IMAGE_BRUSH_PROPERTIES = D2D1_ImageBrushProperties( D2D1_RectF( 0, 0, 32, 32 ), D2D1_EXTEND_MODE_WRAP, D2D1_EXTEND_MODE_WRAP )
```

Microsoft Learn: [ImageBrushProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-imagebrushproperties)

### D2D1_ImageBrushProperties1

```freebasic
function D2D1_ImageBrushProperties1( byval extendModeX as D2D1_EXTEND_MODE = D2D1_EXTEND_MODE_CLAMP, byval extendModeY as D2D1_EXTEND_MODE = D2D1_EXTEND_MODE_CLAMP, byval interpolationMode as D2D1_INTERPOLATION_MODE = D2D1_INTERPOLATION_MODE_LINEAR ) as D2D1_BITMAP_BRUSH_PROPERTIES1
```

Despite its name, returns a `D2D1_BITMAP_BRUSH_PROPERTIES1`: the extend modes and interpolation
of an `ID2D1BitmapBrush1`, which takes the Direct2D 1.1 interpolation modes. It is the
counterpart of the Windows helper `BitmapBrushProperties1`.

**Returns** the `D2D1_BITMAP_BRUSH_PROPERTIES1`.

**Example**

```freebasic
dim bbp as D2D1_BITMAP_BRUSH_PROPERTIES1 = D2D1_ImageBrushProperties1( D2D1_EXTEND_MODE_WRAP, D2D1_EXTEND_MODE_WRAP, D2D1_INTERPOLATION_MODE_HIGH_QUALITY_CUBIC )
```

Microsoft Learn: [BitmapBrushProperties1](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-bitmapbrushproperties1)

### D2D1_PrintControlProperties

```freebasic
function D2D1_PrintControlProperties( byval fontSubsetMode as D2D1_PRINT_FONT_SUBSET_MODE = D2D1_PRINT_FONT_SUBSET_MODE_DEFAULT, byval rasterDpi as FLOAT = 150.0, byval colorSpace as D2D1_COLOR_SPACE = D2D1_COLOR_SPACE_SRGB ) as D2D1_PRINT_CONTROL_PROPERTIES
```

Returns the settings of a print control: how fonts are subset, the resolution at which
rasterised content is printed (150 DPI by default) and the colour space.

**Returns** the `D2D1_PRINT_CONTROL_PROPERTIES`.

**Example**

```freebasic
dim pc as D2D1_PRINT_CONTROL_PROPERTIES = D2D1_PrintControlProperties( , 300 )
```

Microsoft Learn: [PrintControlProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-printcontrolproperties)

### D2D1_RenderingControls

```freebasic
function D2D1_RenderingControls( byval bufferPrecision as D2D1_BUFFER_PRECISION, byval tileSize as D2D1_SIZE_U ) as D2D1_RENDERING_CONTROLS
```

Returns the precision of a device context's intermediate buffers and the tile size it renders
effects in.

**Returns** the `D2D1_RENDERING_CONTROLS`.

**Example**

```freebasic
dim rc as D2D1_RENDERING_CONTROLS = D2D1_RenderingControls( D2D1_BUFFER_PRECISION_8BPC_UNORM, D2D1_SizeU( 256, 256 ) )
```

Microsoft Learn: [RenderingControls](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-renderingcontrols)

### D2D1_EffectInputDescription

```freebasic
function D2D1_EffectInputDescription( byval effect as ID2D1Effect ptr, byval inputIndex as UINT32, byval inputRectangle as D2D1_RECT_F ) as D2D1_EFFECT_INPUT_DESCRIPTION
```

Names one input of an effect and a rectangle on it, for the device context's
`GetEffectRequiredInputRectangles`. The effect pointer is stored as given, without an extra
reference.

**Returns** the `D2D1_EFFECT_INPUT_DESCRIPTION`.

**Example**

```freebasic
dim pEffect as ID2D1Effect ptr
dim eid as D2D1_EFFECT_INPUT_DESCRIPTION = D2D1_EffectInputDescription( pEffect, 0, D2D1_RectF( 0, 0, 100, 100 ) )
```

Microsoft Learn: [EffectInputDescription](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-effectinputdescription)

### D2D1_CreationProperties

```freebasic
function D2D1_CreationProperties( byval threadingMode as D2D1_THREADING_MODE, byval debugLevel as D2D1_DEBUG_LEVEL, byval options as D2D1_DEVICE_CONTEXT_OPTIONS ) as D2D1_CREATION_PROPERTIES
```

Returns the threading mode, debug level and device-context options for `D2D1CreateDevice` and
`D2D1CreateDeviceContext`. All three must be given.

**Returns** the `D2D1_CREATION_PROPERTIES`.

**Example**

```freebasic
dim cp as D2D1_CREATION_PROPERTIES = D2D1_CreationProperties( D2D1_THREADING_MODE_SINGLE_THREADED, D2D1_DEBUG_LEVEL_NONE, D2D1_DEVICE_CONTEXT_OPTIONS_NONE )
```

Microsoft Learn: [CreationProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-creationproperties)

### D2D1_IdentityMatrix

```freebasic
function D2D1_IdentityMatrix() as D2D1_MATRIX_3X2_F
```

Returns the 3 × 2 matrix that changes nothing: 1, 0, 0, 1, 0, 0. Set it as a render target's
transform to undo an earlier `SetTransform`.

**Returns** the `D2D1_MATRIX_3X2_F`.

**Example**

```freebasic
dim pTarget as ID2D1RenderTarget ptr
if pTarget then pTarget->SetTransform( D2D1_IdentityMatrix() )
```

Microsoft Learn: [IdentityMatrix](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-identitymatrix)

### D2D1_Matrix3x2F

```freebasic
function D2D1_Matrix3x2F( byval m11 as FLOAT, byval m12 as FLOAT, byval m21 as FLOAT, byval m22 as FLOAT, byval m31 as FLOAT, byval m32 as FLOAT ) as D2D1_MATRIX_3X2_F
```

Returns a 3 × 2 matrix from its six cells, row by row. A point (x, y) becomes
(x·m11 + y·m21 + m31, x·m12 + y·m22 + m32).

**Returns** the `D2D1_MATRIX_3X2_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_Matrix3x2F( 1, 0, 0, -1, 0, 100 )   ' flip vertically in a 100-high area
```

Microsoft Learn: [Matrix3x2F](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nl-d2d1helper-matrix3x2f)

### D2D1_MatrixTranslation

```freebasic
function D2D1_MatrixTranslation overload( byref tsize as D2D1_SIZE_F ) as D2D1_MATRIX_3X2_F
function D2D1_MatrixTranslation overload( byval x as FLOAT, byval y as FLOAT ) as D2D1_MATRIX_3X2_F
```

Returns a transform that moves everything by `x` and `y`, given as two values or as a
`D2D1_SIZE_F`.

**Returns** the `D2D1_MATRIX_3X2_F`: 1, 0, 0, 1, x, y.

**Example**

```freebasic
dim pTarget as ID2D1RenderTarget ptr
if pTarget then pTarget->SetTransform( D2D1_MatrixTranslation( 10, 20 ) )
```

Microsoft Learn: [Matrix3x2F::Translation](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nl-d2d1helper-matrix3x2f)

### D2D1_MatrixScale

```freebasic
function D2D1_MatrixScale overload( byref tsize as D2D1_SIZE_F, byval center as D2D1_POINT_2F = D2D1_Point2F() ) as D2D1_MATRIX_3X2_F
function D2D1_MatrixScale overload( byval x as FLOAT, byval y as FLOAT, byval center as D2D1_POINT_2F = D2D1_Point2F() ) as D2D1_MATRIX_3X2_F
function D2D1_MatrixScale overload( byval x as FLOAT, byval y as FLOAT, byval centerX as FLOAT, byval centerY as FLOAT ) as D2D1_MATRIX_3X2_F
```

Returns a transform that scales by `x` horizontally and `y` vertically (or by the two parts of
`tsize`) about a centre point, which stays where it is. The centre defaults to the origin.

**Returns** the `D2D1_MATRIX_3X2_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_MatrixScale( 2, 3, 10, 10 )   ' 2 0 0 3 -10 -20
```

Microsoft Learn: [Matrix3x2F::Scale](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nl-d2d1helper-matrix3x2f)

### D2D1_MatrixRotation

```freebasic
function D2D1_MatrixRotation overload( byval angle as FLOAT, byval center as D2D1_POINT_2F = D2D1_Point2F() ) as D2D1_MATRIX_3X2_F
function D2D1_MatrixRotation overload( byval angle as FLOAT, byval centerX as FLOAT = 0.0!, byval centerY as FLOAT = 0.0! ) as D2D1_MATRIX_3X2_F
```

Returns a transform that rotates by `angle` degrees, clockwise on screen, about a centre point,
computed by Direct2D's `D2D1MakeRotateMatrix`.

Both forms default every argument after `angle`, so `D2D1_MatrixRotation( 45 )` alone matches
both and does not compile: always pass the centre, as a point or as two values.

**Returns** the `D2D1_MATRIX_3X2_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_MatrixRotation( 90, 50, 50 )   ' 0 1 -1 0 100 0
```

Microsoft Learn: [Matrix3x2F::Rotation](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-rotation)

### D2D1_MatrixSkew

```freebasic
function D2D1_MatrixSkew overload( byval angleX as FLOAT, byval angleY as FLOAT, byval center as D2D1_POINT_2F = D2D1_Point2F() ) as D2D1_MATRIX_3X2_F
function D2D1_MatrixSkew overload( byval angleX as FLOAT, byval angleY as FLOAT, byval centerX as FLOAT = 0.0!, byval centerY as FLOAT = 0.0! ) as D2D1_MATRIX_3X2_F
```

Returns a transform that slants the x axis by `angleX` degrees and the y axis by `angleY`
degrees about a centre point, computed by Direct2D's `D2D1MakeSkewMatrix`.

As with [D2D1_MatrixRotation](#d2d1_matrixrotation), a call that gives only the two angles
matches both forms and does not compile: pass the centre.

**Returns** the `D2D1_MATRIX_3X2_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_MatrixSkew( 45, 0, D2D1_Point2F( 0, 0 ) )   ' 1 0 1 1 0 0
```

Microsoft Learn: [Matrix3x2F::Skew](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-skew)

### D2D1_MatrixDeterminant

```freebasic
function D2D1_MatrixDeterminant( byref m as D2D1_MATRIX_3X2_F ) as FLOAT
```

Returns m11·m22 − m12·m21: the factor by which the transform scales areas. 0 means it cannot be
inverted.

**Returns** the determinant.

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_MatrixScale( 2, 4, 0, 0 )
print D2D1_MatrixDeterminant( m )   ' 8
```

Microsoft Learn: [Matrix3x2F::Determinant](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-determinant)

### D2D1_IsInvertibleMatrix

```freebasic
function D2D1_IsInvertibleMatrix( byref m as D2D1_MATRIX_3X2_F ) as boolean
```

Tells whether a 3 × 2 matrix can be inverted, by asking Direct2D's `D2D1IsMatrixInvertible`.

**Returns** `true` when it can be inverted, `false` when it cannot (a scale by 0, say).

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_MatrixScale( 0, 1, 0, 0 )
print D2D1_IsInvertibleMatrix( m )   ' false
```

Microsoft Learn: [Matrix3x2F::IsInvertible](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-isinvertible)

### D2D1_InvertMatrix

```freebasic
sub D2D1_InvertMatrix( byref m as D2D1_MATRIX_3X2_F )
```

Replaces `m` with its inverse, the transform that undoes it, using Direct2D's
`D2D1InvertMatrix`. A matrix that cannot be inverted is left unchanged, and nothing reports it:
check with [D2D1_IsInvertibleMatrix](#d2d1_isinvertiblematrix) first when it matters.

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_MatrixScale( 2, 4, 0, 0 )
D2D1_InvertMatrix( m )   ' 0.5 0 0 0.25 0 0
```

Microsoft Learn: [Matrix3x2F::Invert](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-invert)

### D2D1_IsIdentityMatrix

```freebasic
function D2D1_IsIdentityMatrix( byref m as D2D1_MATRIX_3X2_F ) as long
```

Tells whether every cell of `m` is exactly that of the identity matrix. The comparison has no
tolerance, so a matrix that is the identity only after rounding reports not.

**Returns** −1 when it is the identity, 0 when it is not (a `long`, not a `boolean`).

**Example**

```freebasic
print D2D1_IsIdentityMatrix( D2D1_IdentityMatrix() )   ' -1
```

Microsoft Learn: [Matrix3x2F::IsIdentity](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-isidentity)

### D2D1_MultiplyMatrices

```freebasic
function D2D1_MultiplyMatrices( byref a as D2D1_MATRIX_3X2_F, byref b as D2D1_MATRIX_3X2_F ) as D2D1_MATRIX_3X2_F
```

Returns `a` × `b`: the transform that applies `a` first and then `b`. The same as
[Operator *](#operator-).

**Returns** the product.

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_MultiplyMatrices( D2D1_MatrixScale( 2, 2, 0, 0 ), D2D1_MatrixTranslation( 10, 0 ) )
' 2 0 0 2 10 0: scale first, then move
```

Microsoft Learn: [Matrix3x2F::SetProduct](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-setproduct)

### D2D1_MatrixTransformPoint

```freebasic
function D2D1_MatrixTransformPoint( byref pt as D2D1_POINT_2F, byref m as D2D1_MATRIX_3X2_F ) as D2D1_POINT_2F
```

Returns where the transform `m` puts the point `pt`. The same as `pt * m`.

**Returns** the transformed point.

**Example**

```freebasic
dim pt as D2D1_POINT_2F = D2D1_MatrixTransformPoint( D2D1_Point2F( 1, 1 ), D2D1_MatrixTranslation( 10, 20 ) )
print pt.x; pt.y   ' 11 21
```

Microsoft Learn: [Matrix3x2F::TransformPoint](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-transformpoint)

### Operator *

```freebasic
operator *( byref a as D2D1_MATRIX_3X2_F, byref b as D2D1_MATRIX_3X2_F ) as D2D1_MATRIX_3X2_F
operator *( byref pt as D2D1_POINT_2F, byref m as D2D1_MATRIX_3X2_F ) as D2D1_POINT_2F
operator *( byref a as D2D1_MATRIX_4X4_F, byref b as D2D1_MATRIX_4X4_F ) as D2D1_MATRIX_4X4_F
```

`*` between two 3 × 2 matrices is [D2D1_MultiplyMatrices](#d2d1_multiplymatrices), between a
point and a 3 × 2 matrix [D2D1_MatrixTransformPoint](#d2d1_matrixtransformpoint), and between
two 4 × 4 matrices [D2D1_Matrix4x4FSetProduct](#d2d1_matrix4x4fsetproduct). Order matters:
`a * b` applies `a` first.

**Returns** the product.

**Example**

```freebasic
dim m as D2D1_MATRIX_3X2_F = D2D1_MatrixRotation( 30, 0, 0 ) * D2D1_MatrixTranslation( 100, 50 )
dim pt as D2D1_POINT_2F = D2D1_Point2F( 3, 4 ) * D2D1_MatrixScale( 2, 2, 0, 0 )   ' 6 8
```

Microsoft Learn: [Matrix3x2F::operator*](https://learn.microsoft.com/en-us/windows/win32/api/d2d1helper/nf-d2d1helper-matrix3x2f-operator-mult)

### D2D1_ComputeFlatteningTolerance

```freebasic
function D2D1_ComputeFlatteningTolerance( byref matrix as D2D1_MATRIX_3X2_F, byval dpiX as FLOAT = 96.0, byval dpiY as FLOAT = 96.0, byval maxZoomFactor as FLOAT = 1.0 ) as FLOAT
```

Returns the flattening tolerance to pass to calls that turn curves into line segments, such as
a device context's `CreateFilledGeometryRealization`: the default tolerance, 0.25, divided by
the largest scale the transform, the DPI and the zoom can apply. The more a geometry will be
enlarged, the finer it must be flattened.

| Parameter | Meaning |
| --- | --- |
| `matrix` | The world transform the geometry will be drawn with. |
| `dpiX`, `dpiY` | The target's DPI. |
| `maxZoomFactor` | The most the geometry will be enlarged beyond that; its sign is ignored. |

**Returns** the tolerance: 0.25 for the identity at 96 DPI, 0.125 at 192 DPI, 0.0625 with a
zoom of 4.

**Example**

```freebasic
dim tol as single = D2D1_ComputeFlatteningTolerance( D2D1_IdentityMatrix(), 192, 192 )   ' 0.125
```

Microsoft Learn: [Direct2D helper functions](https://learn.microsoft.com/en-us/windows/win32/direct2d/d2d1functions), ComputeFlatteningTolerance

### D2D1_Matrix4x3F

```freebasic
function D2D1_Matrix4x3F overload( byval m11 as FLOAT, byval m12 as FLOAT, byval m13 as FLOAT, byval m21 as FLOAT, byval m22 as FLOAT, byval m23 as FLOAT, byval m31 as FLOAT, byval m32 as FLOAT, byval m33 as FLOAT, byval m41 as FLOAT, byval m42 as FLOAT, byval m43 as FLOAT ) as D2D1_MATRIX_4X3_F
function D2D1_Matrix4x3F overload() as D2D1_MATRIX_4X3_F
```

Returns a 4 × 3 matrix from its twelve cells, row by row; with no arguments, ones on the
diagonal (m11, m22, m33) and zeros elsewhere.

**Returns** the `D2D1_MATRIX_4X3_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X3_F = D2D1_Matrix4x3F()
```

Microsoft Learn: [Matrix4x3F](https://learn.microsoft.com/en-us/windows/win32/direct2d/matrix4x3f)

### D2D1_Matrix4x4F

```freebasic
function D2D1_Matrix4x4F overload( byval m11 as FLOAT, byval m12 as FLOAT, byval m13 as FLOAT, byval m14 as FLOAT, byval m21 as FLOAT, byval m22 as FLOAT, byval m23 as FLOAT, byval m24 as FLOAT, byval m31 as FLOAT, byval m32 as FLOAT, byval m33 as FLOAT, byval m34 as FLOAT, byval m41 as FLOAT, byval m42 as FLOAT, byval m43 as FLOAT, byval m44 as FLOAT ) as D2D1_MATRIX_4X4_F
function D2D1_Matrix4x4F overload() as D2D1_MATRIX_4X4_F
```

Returns a 4 × 4 matrix from its sixteen cells, row by row; with no arguments, the identity. The
4 × 4 matrices feed the 3D transform effects and use the same row-vector convention as the
3 × 2 ones: the translation is in row 4.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4F()   ' identity
```

Microsoft Learn: [Matrix4x4F](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nl-d2d1_1helper-matrix4x4f)

### D2D1_Matrix4x4FTranslation

```freebasic
function D2D1_Matrix4x4FTranslation( byval x as FLOAT, byval y as FLOAT, byval z as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a 3D translation by `x`, `y` and `z`: the identity with m41, m42, m43 set.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FTranslation( 10, 20, 30 )
```

Microsoft Learn: [Matrix4x4F](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nl-d2d1_1helper-matrix4x4f)

### D2D1_Matrix4x4FScale

```freebasic
function D2D1_Matrix4x4FScale( byval x as FLOAT, byval y as FLOAT, byval z as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a 3D scale by `x`, `y` and `z` about the origin.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FScale( 2, 3, 4 )
print D2D1_Matrix4x4FDeterminant( m )   ' 24
```

Microsoft Learn: [Matrix4x4F::Scale](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-scale)

### D2D1_Matrix4x4FRotationX

```freebasic
function D2D1_Matrix4x4FRotationX( byval degreeX as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a rotation of `degreeX` degrees about the x axis.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FRotationX( 30 )
```

Microsoft Learn: [Matrix4x4F::RotationX](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-rotationx)

### D2D1_Matrix4x4FRotationY

```freebasic
function D2D1_Matrix4x4FRotationY( byval degreeY as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a rotation of `degreeY` degrees about the y axis.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FRotationY( 45 )
```

Microsoft Learn: [Matrix4x4F::RotationY](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-rotationy)

### D2D1_Matrix4x4FRotationZ

```freebasic
function D2D1_Matrix4x4FRotationZ( byval degreeZ as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a rotation of `degreeZ` degrees about the z axis: in the plane of the screen, like
[D2D1_MatrixRotation](#d2d1_matrixrotation) about the origin.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FRotationZ( 90 )
```

Microsoft Learn: [Matrix4x4F::RotationZ](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-rotationz)

### D2D1_Matrix4x4FRotationArbitraryAxis

```freebasic
function D2D1_Matrix4x4FRotationArbitraryAxis( byval x as FLOAT, byval y as FLOAT, byval z as FLOAT, byval degree as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a rotation of `degree` degrees about the axis through the origin in the direction
(`x`, `y`, `z`). The direction need not be of unit length: it is normalised first, so it must
not be (0, 0, 0).

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FRotationArbitraryAxis( 1, 1, 0, 60 )
```

Microsoft Learn: [Matrix4x4F::RotationArbitraryAxis](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-rotationarbitraryaxis)

### D2D1_Matrix4x4FSkewX

```freebasic
function D2D1_Matrix4x4FSkewX( byval degreeX as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a skew that slants by `degreeX` degrees along x: the tangent of the angle in m21.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FSkewX( 45 )   ' m21 = 1
```

Microsoft Learn: [Matrix4x4F::SkewX](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-skewx)

### D2D1_Matrix4x4FSkewY

```freebasic
function D2D1_Matrix4x4FSkewY( byval degreeY as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a skew that slants by `degreeY` degrees along y: the tangent of the angle in m12.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FSkewY( 45 )   ' m12 = 1
```

Microsoft Learn: [Matrix4x4F::SkewY](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-skewy)

### D2D1_Matrix4x4FPerspectiveProjection

```freebasic
function D2D1_Matrix4x4FPerspectiveProjection( byval depth as FLOAT ) as D2D1_MATRIX_4X4_F
```

Returns a perspective projection for a viewer `depth` units in front of the plane: the identity
with −1/`depth` in m34. A `depth` of 0 or less gives the identity.

**Returns** the `D2D1_MATRIX_4X4_F`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FRotationY( 30 ) * D2D1_Matrix4x4FPerspectiveProjection( 1000 )
```

Microsoft Learn: [Matrix4x4F::PerspectiveProjection](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-perspectiveprojection)

### D2D1_Matrix4x4FDeterminant

```freebasic
function D2D1_Matrix4x4FDeterminant( byref m as D2D1_MATRIX_4X4_F ) as FLOAT
```

Returns the determinant of a 4 × 4 matrix, expanded along the first row.

**Returns** the determinant: 24 for a scale by 2, 3 and 4; 1 for any rotation or translation.

**Example**

```freebasic
print D2D1_Matrix4x4FDeterminant( D2D1_Matrix4x4FScale( 2, 3, 4 ) )   ' 24
```

Microsoft Learn: [Matrix4x4F::Determinant](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-determinant)

### D2D1_Matrix4x4FIsIdentity

```freebasic
function D2D1_Matrix4x4FIsIdentity( byref m as D2D1_MATRIX_4X4_F ) as boolean
```

Tells whether a 4 × 4 matrix is the identity, allowing each cell to be off by less than
0.00001, so a product that should cancel out, such as a rotation and its reverse, still counts.

**Returns** `true` or `false`.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FRotationZ( 90 ) * D2D1_Matrix4x4FRotationZ( -90 )
print D2D1_Matrix4x4FIsIdentity( m )   ' true
```

Microsoft Learn: [Matrix4x4F::IsIdentity](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-isidentity)

### D2D1_Matrix4x4FSetProduct

```freebasic
function D2D1_Matrix4x4FSetProduct( byref a as D2D1_MATRIX_4X4_F, byref b as D2D1_MATRIX_4X4_F ) as D2D1_MATRIX_4X4_F
```

Returns `a` × `b`, the transform that applies `a` and then `b`. Unlike its namesake in the
Windows headers it does not change either argument. `a * b` does the same.

**Returns** the product.

**Example**

```freebasic
dim m as D2D1_MATRIX_4X4_F = D2D1_Matrix4x4FSetProduct( D2D1_Matrix4x4FScale( 2, 2, 2 ), D2D1_Matrix4x4FTranslation( 10, 0, 0 ) )
```

Microsoft Learn: [Matrix4x4F::SetProduct](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_1helper/nf-d2d1_1helper-matrix4x4f-setproduct)

### D2D1_Matrix5x4F

```freebasic
function D2D1_Matrix5x4F overload( byval m11 as FLOAT, byval m12 as FLOAT, byval m13 as FLOAT, byval m14 as FLOAT, byval m21 as FLOAT, byval m22 as FLOAT, byval m23 as FLOAT, byval m24 as FLOAT, byval m31 as FLOAT, byval m32 as FLOAT, byval m33 as FLOAT, byval m34 as FLOAT, byval m41 as FLOAT, byval m42 as FLOAT, byval m43 as FLOAT, byval m44 as FLOAT, byval m51 as FLOAT, byval m52 as FLOAT, byval m53 as FLOAT, byval m54 as FLOAT ) as D2D1_MATRIX_5X4_F
function D2D1_Matrix5x4F overload() as D2D1_MATRIX_5X4_F
```

Returns a 5 × 4 matrix, the kind the colour matrix effect takes: rows 1 to 4 weigh the red,
green, blue and alpha inputs and row 5 adds an offset. With no arguments it is the identity,
which leaves colours unchanged.

The twenty-value form does not store every argument where its name says: `m33` and `m34` end up
in `m31` and `m32` (replacing the values given for those), `m54` ends up in `m53`, and `m33`,
`m34` and `m54` stay 0. Calling it with 1 to 20 gives row 3 = 11, 12, 0, 0 and row 5 = 17, 18,
20, 0. Start from the identity and set the cells yourself instead.

**Returns** the `D2D1_MATRIX_5X4_F`.

**Example**

```freebasic
dim cm as D2D1_MATRIX_5X4_F = D2D1_Matrix5x4F()   ' identity
cm.m11 = 0.3 : cm.m12 = 0.3 : cm.m13 = 0.3        ' red feeds all three channels
```

Microsoft Learn: [Matrix5x4F](https://learn.microsoft.com/en-us/windows/win32/direct2d/matrix5x4f)

### D2D1_GradientMeshPatch

```freebasic
function D2D1_GradientMeshPatch( byval point00 as D2D1_POINT_2F, byval point01 as D2D1_POINT_2F, byval point02 as D2D1_POINT_2F, byval point03 as D2D1_POINT_2F, byval point10 as D2D1_POINT_2F, byval point11 as D2D1_POINT_2F, byval point12 as D2D1_POINT_2F, byval point13 as D2D1_POINT_2F, byval point20 as D2D1_POINT_2F, byval point21 as D2D1_POINT_2F, byval point22 as D2D1_POINT_2F, byval point23 as D2D1_POINT_2F, byval point30 as D2D1_POINT_2F, byval point31 as D2D1_POINT_2F, byval point32 as D2D1_POINT_2F, byval point33 as D2D1_POINT_2F, byval color00 as D2D1_COLOR_F, byval color03 as D2D1_COLOR_F, byval color30 as D2D1_COLOR_F, byval color33 as D2D1_COLOR_F, byval topEdgeMode as D2D1_PATCH_EDGE_MODE, byval leftEdgeMode as D2D1_PATCH_EDGE_MODE, byval bottomEdgeMode as D2D1_PATCH_EDGE_MODE, byval rightEdgeMode as D2D1_PATCH_EDGE_MODE ) as D2D1_GRADIENT_MESH_PATCH
```

Returns one tensor patch of a gradient mesh: the 4 × 4 grid of control points `pointRC` (row R,
column C), the colours of the four corners, and whether each edge is aliased or antialiased.
An array of patches goes to a device context's `CreateGradientMesh`.

**Returns** the `D2D1_GRADIENT_MESH_PATCH`.

**Example**

```freebasic
dim as D2D1_COLOR_F red = D2D1_ColorF( D2D1_Red ), blue = D2D1_ColorF( D2D1_Blue )
dim e as D2D1_PATCH_EDGE_MODE = D2D1_PATCH_EDGE_MODE_ANTIALIASED
dim patch as D2D1_GRADIENT_MESH_PATCH = D2D1_GradientMeshPatch( _
    D2D1_Point2F( 0, 0 ), D2D1_Point2F( 33, 0 ), D2D1_Point2F( 66, 0 ), D2D1_Point2F( 100, 0 ), D2D1_Point2F( 0, 33 ), D2D1_Point2F( 33, 33 ), D2D1_Point2F( 66, 33 ), D2D1_Point2F( 100, 33 ), _
    D2D1_Point2F( 0, 66 ), D2D1_Point2F( 33, 66 ), D2D1_Point2F( 66, 66 ), D2D1_Point2F( 100, 66 ), D2D1_Point2F( 0, 100 ), D2D1_Point2F( 33, 100 ), D2D1_Point2F( 66, 100 ), D2D1_Point2F( 100, 100 ), _
    red, blue, blue, red, e, e, e, e )
```

Microsoft Learn: [GradientMeshPatch](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_3helper/nf-d2d1_3helper-gradientmeshpatch)

### D2D1_GradientMeshPatchFromCoonsPatch

```freebasic
function D2D1_GradientMeshPatchFromCoonsPatch( byval point0 as D2D1_POINT_2F, byval point1 as D2D1_POINT_2F, byval point2 as D2D1_POINT_2F, byval point3 as D2D1_POINT_2F, byval point4 as D2D1_POINT_2F, byval point5 as D2D1_POINT_2F, byval point6 as D2D1_POINT_2F, byval point7 as D2D1_POINT_2F, byval point8 as D2D1_POINT_2F, byval point9 as D2D1_POINT_2F, byval point10 as D2D1_POINT_2F, byval point11 as D2D1_POINT_2F, byval color0 as D2D1_COLOR_F, byval color1 as D2D1_COLOR_F, byval color2 as D2D1_COLOR_F, byval color3 as D2D1_COLOR_F, byval topEdgeMode as D2D1_PATCH_EDGE_MODE, byval leftEdgeMode as D2D1_PATCH_EDGE_MODE, byval bottomEdgeMode as D2D1_PATCH_EDGE_MODE, byval rightEdgeMode as D2D1_PATCH_EDGE_MODE ) as D2D1_GRADIENT_MESH_PATCH
```

Returns a gradient mesh patch from a Coons patch: the twelve points around its border, clockwise
from the top-left corner (`point0`, `point3`, `point6` and `point9` are the corners), and the
colours of the corners in the same clockwise order. Direct2D's
`D2D1GetGradientMeshInteriorPointsFromCoonsPatch` works out the four interior points.

**Returns** the `D2D1_GRADIENT_MESH_PATCH`.

**Example**

```freebasic
dim as D2D1_COLOR_F red = D2D1_ColorF( D2D1_Red ), blue = D2D1_ColorF( D2D1_Blue )
dim e as D2D1_PATCH_EDGE_MODE = D2D1_PATCH_EDGE_MODE_ANTIALIASED
dim patch as D2D1_GRADIENT_MESH_PATCH = D2D1_GradientMeshPatchFromCoonsPatch( _
    D2D1_Point2F( 0, 0 ), D2D1_Point2F( 33, 0 ), D2D1_Point2F( 66, 0 ), D2D1_Point2F( 100, 0 ), D2D1_Point2F( 100, 33 ), D2D1_Point2F( 100, 66 ), _
    D2D1_Point2F( 100, 100 ), D2D1_Point2F( 66, 100 ), D2D1_Point2F( 33, 100 ), D2D1_Point2F( 0, 100 ), D2D1_Point2F( 0, 66 ), D2D1_Point2F( 0, 33 ), _
    red, blue, red, blue, e, e, e, e )
```

Microsoft Learn: [GradientMeshPatchFromCoonsPatch](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_3helper/nf-d2d1_3helper-gradientmeshpatchfromcoonspatch)

### D2D1_InkPoint

```freebasic
function D2D1_InkPoint( byref pt as const D2D1_POINT_2F, byval radius as FLOAT ) as D2D1_INK_POINT
```

Returns a point of an ink stroke and the stroke's radius there; the radius may change from point
to point.

**Returns** the `D2D1_INK_POINT`.

**Example**

```freebasic
dim ip as D2D1_INK_POINT = D2D1_InkPoint( D2D1_Point2F( 5, 6 ), 2 )
```

Microsoft Learn: [InkPoint](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_3helper/nf-d2d1_3helper-inkpoint)

### D2D1_InkBezierSegment

```freebasic
function D2D1_InkBezierSegment( byref point1 as const D2D1_INK_POINT, byref point2 as const D2D1_INK_POINT, byref point3 as const D2D1_INK_POINT ) as D2D1_INK_BEZIER_SEGMENT
```

Returns a cubic Bézier segment of an ink stroke: two control points and an end point, each with
a radius.

**Returns** the `D2D1_INK_BEZIER_SEGMENT`.

**Example**

```freebasic
dim seg as D2D1_INK_BEZIER_SEGMENT = D2D1_InkBezierSegment( D2D1_InkPoint( D2D1_Point2F( 10, 0 ), 1 ), D2D1_InkPoint( D2D1_Point2F( 20, 10 ), 2 ), D2D1_InkPoint( D2D1_Point2F( 30, 0 ), 1 ) )
```

Microsoft Learn: [InkBezierSegment](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_3helper/nf-d2d1_3helper-inkbeziersegment)

### D2D1_InkStyleProperties

```freebasic
function D2D1_InkStyleProperties( byval nibShape as D2D1_INK_NIB_SHAPE, byref nibTransform as const D2D1_MATRIX_3X2_F ) as D2D1_INK_STYLE_PROPERTIES
```

Returns the nib an ink style draws with: round or square, and a transform that stretches or
turns it, for a calligraphic pen say.

**Returns** the `D2D1_INK_STYLE_PROPERTIES`.

**Example**

```freebasic
dim isp as D2D1_INK_STYLE_PROPERTIES = D2D1_InkStyleProperties( D2D1_INK_NIB_SHAPE_SQUARE, D2D1_MatrixRotation( 45, 0, 0 ) )
```

Microsoft Learn: [InkStyleProperties](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_3helper/nf-d2d1_3helper-inkstyleproperties)

### D2D1_SimpleColorProfile

```freebasic
function D2D1_SimpleColorProfile( byref redPrimary as const D2D1_POINT_2F, byref greenPrimary as const D2D1_POINT_2F, byref bluePrimary as const D2D1_POINT_2F, byref gamma as const D2D1_GAMMA1, byref whitePointXZ as const D2D1_POINT_2F ) as D2D1_SIMPLE_COLOR_PROFILE
```

Returns a colour profile described by the chromaticities of its red, green and blue primaries,
its gamma (`D2D1_GAMMA1_G22`, `_G10` or `_G2084`) and its white point, for
`CreateColorContextFromSimpleColorProfile`.

**Returns** the `D2D1_SIMPLE_COLOR_PROFILE`.

**Example**

```freebasic
dim scp as D2D1_SIMPLE_COLOR_PROFILE = D2D1_SimpleColorProfile( D2D1_Point2F( 0.64, 0.33 ), D2D1_Point2F( 0.3, 0.6 ), D2D1_Point2F( 0.15, 0.06 ), D2D1_GAMMA1_G22, D2D1_Point2F( 0.3127, 0.329 ) )
```

Microsoft Learn: [D2D1_SIMPLE_COLOR_PROFILE](https://learn.microsoft.com/en-us/windows/win32/api/d2d1_3/ns-d2d1_3-d2d1_simple_color_profile)

## See also

- [sys/win/direct2d](SysWin-Direct2D)
- [Direct2D interfaces and types](SysWin-Direct2D-Interfaces) for the structures these functions return
- [CID2D1RenderTarget](CID2D1RenderTarget), which takes most of them
- [Direct2D geometries](SysWin-Direct2D-Geometries) for the segments and shapes
- [Direct2D brushes](SysWin-Direct2D-Brushes) for gradient stops and brush properties
- [Colours](SysWin-Colors) for the GDI and GDI+ colour constants
