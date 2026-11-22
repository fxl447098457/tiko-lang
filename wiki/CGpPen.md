[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gdiplus](SysWin-GdiPlus) › **CGpPen**

# CGpPen

Draws lines and outlines in GDI+ with a colour or brush, a width, dashes and caps.

A `CGpPen` wraps one GDI+ `Pen` object, which it creates in its constructor and deletes in its
destructor. Every `Draw…` method of [CGpGraphics](CGpGraphics) takes a pen by address:
`graphics.DrawLine( @pen, 0, 0, 100, 0 )`.

**What a pen holds.** A pen strokes with either a solid colour or a brush (hatch, texture or
gradient, see [GDI+ brushes](SysWin-GdiPlus-Brushes)); [GetPenType](#getpentype) tells which.
On top of that it has a width, a dash style or custom dash pattern, a cap for each end of a line
and for each dash, a join for corners, an alignment, an optional compound array that splits the
stroke into parallel bands, and its own transformation that reshapes the stroke. A new pen is
solid, with flat caps, mitred joins (miter limit 10) and centred alignment.

**Units.** The width is in the pen's unit, `UnitWorld` by default: the units of the
`CGpGraphics` it draws on, after that object's own transformation. Dash lengths, dash offsets
and compound positions are relative to the width.

**Lifetime.** The pen keeps its own copies of a brush or custom cap you give it, so those can
go out of scope while the pen is still in use. Never copy a `CGpPen` by value
(`dim b as CGpPen = a`, or a `byval` parameter): the copy holds the same GDI+ object and deletes
it when it goes. To make an independent copy pass the address, `dim b as CGpPen = @a`, or use
[Clone](#clone).

**Status.** The setters return a `GpStatus`: `Ok` (0) on success, otherwise the reason, such as
`InvalidParameter` (2) or `WrongState` (8). The status is also stored, and `GetLastStatus()`,
which every `CGp*` class inherits, returns it; getters that return a value store theirs too.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus
```

## Example

A window that draws six lines, one per pen: plain, thick with round caps, dashed, with a custom
dash pattern, with an arrow head, and a compound pen of two bands. The graphics object scales
96-DPI units to pixels:

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim token as ULONG_PTR = gdiplus.Init()
    dim pWindow as CWindow = "PenDemo"
    pWindow.Create( NULL, "CGpPen", @WndProc )
    pWindow.SetClientSize( 360, 260 )
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

                dim plain as CGpPen = CGpPen( ARGB_BLACK )
                graphics.DrawLine( @plain, 30, 30, 330, 30 )

                dim thick as CGpPen = CGpPen( ARGB_STEELBLUE, 12 )
                thick.SetLineCap( LineCapRound, LineCapRound, DashCapRound )
                graphics.DrawLine( @thick, 30, 70, 330, 70 )

                dim dashed as CGpPen = CGpPen( ARGB_DARKGREEN, 3 )
                dashed.SetDashStyle( DashStyleDashDot )
                graphics.DrawLine( @dashed, 30, 110, 330, 110 )

                dim pattern(0 to 3) as single = { 6, 2, 1, 2 }
                dim custom as CGpPen = CGpPen( ARGB_PURPLE, 3 )
                custom.SetDashPattern( @pattern(0), 4 )
                graphics.DrawLine( @custom, 30, 150, 330, 150 )

                dim arrow as CGpPen = CGpPen( ARGB_FIREBRICK, 3 )
                arrow.SetStartCap( LineCapRoundAnchor )
                arrow.SetEndCap( LineCapArrowAnchor )
                graphics.DrawLine( @arrow, 30, 190, 330, 190 )

                dim bands(0 to 3) as single = { 0, 0.3, 0.7, 1 }
                dim compound as CGpPen = CGpPen( ARGB_NAVY, 14 )
                compound.SetCompoundArray( @bands(0), 4 )
                graphics.DrawLine( @compound, 30, 230, 330, 230 )
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
| [Constructor](#constructor) | Creates an empty pen, a copy, a pen of a colour, or a pen that strokes with a brush. |
| [Destructor](#destructor) | Deletes the GDI+ pen. |
| [Clone](#clone) | Copies this pen into another `CGpPen`. |
| [SetWidth, GetWidth](#setwidth-getwidth) | Sets or reads the width. |
| [SetLineCap](#setlinecap) | Sets the start, end and dash caps in one call. |
| [SetStartCap, GetStartCap](#setstartcap-getstartcap) | Sets or reads the cap at the start of a line. |
| [SetEndCap, GetEndCap](#setendcap-getendcap) | Sets or reads the cap at the end of a line. |
| [SetDashCap, GetDashCap](#setdashcap-getdashcap) | Sets or reads the cap at both ends of each dash. |
| [SetLineJoin, GetLineJoin](#setlinejoin-getlinejoin) | Sets or reads how corners are joined. |
| [SetCustomStartCap, GetCustomStartCap](#setcustomstartcap-getcustomstartcap) | Sets or reads a custom cap for the start of a line. |
| [SetCustomEndCap, GetCustomEndCap](#setcustomendcap-getcustomendcap) | Sets or reads a custom cap for the end of a line. |
| [SetMiterLimit, GetMiterLimit](#setmiterlimit-getmiterlimit) | Sets or reads how far a mitred corner may stick out. |
| [SetAlignment, GetAlignment](#setalignment-getalignment) | Sets or reads whether the stroke is centred on the line or inside it. |
| [SetTransform](#settransform) | Replaces the pen's transformation. |
| [GetTransform](#gettransform) | Is meant to read the pen's transformation. |
| [ResetTransform](#resettransform) | Makes the pen's transformation the identity. |
| [MultiplyTransform](#multiplytransform) | Combines the pen's transformation with a matrix. |
| [TranslateTransform](#translatetransform) | Adds a move to the pen's transformation. |
| [ScaleTransform](#scaletransform) | Adds a scaling to the pen's transformation. |
| [RotateTransform](#rotatetransform) | Adds a rotation to the pen's transformation. |
| [GetPenType](#getpentype) | Tells whether the pen strokes with a colour or with which kind of brush. |
| [SetColor, GetColor](#setcolor-getcolor) | Makes the pen solid in a colour, or reads that colour. |
| [SetBrush, GetBrush](#setbrush-getbrush) | Makes the pen stroke with a brush, or reads a copy of it. |
| [SetDashStyle, GetDashStyle](#setdashstyle-getdashstyle) | Sets or reads a predefined dash style. |
| [SetDashOffset, GetDashOffset](#setdashoffset-getdashoffset) | Sets or reads where in the dash pattern a line starts. |
| [SetDashPattern, GetDashPattern, GetDashPatternCount](#setdashpattern-getdashpattern-getdashpatterncount) | Sets or reads a custom pattern of dashes and spaces. |
| [SetCompoundArray, GetCompoundArray, GetCompoundArrayCount](#setcompoundarray-getcompoundarray-getcompoundarraycount) | Splits the stroke into parallel bands, or reads the bands. |

## Reference

### Constructor

```freebasic
constructor
constructor( byval pPen as CGpPen ptr )
constructor( byval colour as ARGB, byval nWidth as single = 1.0, byval unit as GpUnit = UnitWorld )
constructor( byval pBrush as CGpBrush ptr, byval nWidth as single = 1.0, byval unit as GpUnit = UnitWorld )
```

Creates the GDI+ pen.

- With no argument the object holds no pen: every call on it fails with `InvalidParameter`
  until [Clone](#clone) of another pen fills it.
- With a pointer to another `CGpPen` it is an independent copy of that pen. The pointer must
  not be `NULL`.
- With a colour it is a solid pen of that colour.
- With a pointer to a brush (any of the [brush classes](SysWin-GdiPlus-Brushes)) it strokes
  with a copy of that brush. The pointer must not be `NULL`.

`GetLastStatus()` tells whether the pen was created.

| Parameter | Meaning |
| --- | --- |
| `pPen` | The pen to copy. |
| `colour` | An ARGB colour, such as `ARGB_RED` or `&hFF336699`. |
| `pBrush` | The brush to stroke with. |
| `nWidth` | The width of the stroke; 1 by default. |
| `unit` | The unit of `nWidth`: `UnitWorld` (the default) follows the graphics object; `UnitPixel`, `UnitPoint`, `UnitInch`, `UnitMillimeter` and `UnitDocument` fix it. |

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_RED, 3 )
print pen.GetLastStatus(); pen.GetWidth()           ' 0 3
dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleCross, ARGB_RED, ARGB_WHITE )
dim hatched as CGpPen = CGpPen( @hatch, 4 )
```

Microsoft Learn: [Pen::Pen](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-pen%28constcolor__real%29)

### Destructor

```freebasic
destructor
```

Deletes the GDI+ pen. Lines already drawn with it stay as they are.

**Example**

```freebasic
dim pPen as CGpPen ptr = new CGpPen( ARGB_BLUE, 2 )
print pPen->GetWidth()                              ' 2
delete pPen
```

### Clone

```freebasic
function Clone( byval pPen as CGpPen ptr ) as GpStatus
```

Copies this pen, with its brush, caps, dashes and transformation, into the existing `CGpPen`
that `pPen` points to. The GDI+ pen the target held is deleted first.

| Parameter | Meaning |
| --- | --- |
| `pPen` | The object that receives the copy. |

**Returns** `Ok` on success; `InvalidParameter` when `pPen` is `NULL`.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_RED, 5 )
dim copy as CGpPen
if pen.Clone( @copy ) = Ok then print copy.GetWidth()   ' 5
```

Microsoft Learn: [Pen::Clone](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-clone)

### SetWidth, GetWidth

```freebasic
function SetWidth( byval nWidth as single ) as GpStatus
function GetWidth() as single
```

`SetWidth` changes the width of the stroke, in the pen's unit. `GetWidth` returns it.

| Parameter | Meaning |
| --- | --- |
| `nWidth` | The new width. |

**Returns** `SetWidth`: `Ok` on success, otherwise the error. `GetWidth`: the width, or 0 when
the object holds no pen.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK )
pen.SetWidth( 5 )
print pen.GetWidth()                                ' 5
```

Microsoft Learn: [Pen::SetWidth](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setwidth)

### SetLineCap

```freebasic
function SetLineCap( byval startCap as LineCap, byval endCap as LineCap, byval nDashCap as DashCap ) as GpStatus
```

Sets the cap drawn at the start of a line, the cap at its end, and the cap at both ends of each
dash, in one call.

| Parameter | Meaning |
| --- | --- |
| `startCap`, `endCap` | A `LineCap`: `LineCapFlat` (the default), `LineCapSquare`, `LineCapRound`, `LineCapTriangle`, or an anchor that is wider than the line: `LineCapNoAnchor`, `LineCapSquareAnchor`, `LineCapRoundAnchor`, `LineCapDiamondAnchor`, `LineCapArrowAnchor`. |
| `nDashCap` | A `DashCap`: `DashCapFlat` (the default), `DashCapRound` or `DashCapTriangle`. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 6 )
pen.SetLineCap( LineCapRound, LineCapArrowAnchor, DashCapTriangle )
print pen.GetStartCap(); pen.GetEndCap(); pen.GetDashCap()    ' 2 20 3
```

Microsoft Learn: [Pen::SetLineCap](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setlinecap)

### SetStartCap, GetStartCap

```freebasic
function SetStartCap( byval startCap as LineCap ) as GpStatus
function GetStartCap() as LineCap
```

`SetStartCap` sets the cap drawn at the start of every line and open figure the pen draws.
`GetStartCap` returns it: `LineCapFlat` (0) for a new pen, `LineCapCustom` (255) after
[SetCustomStartCap](#setcustomstartcap-getcustomstartcap).

| Parameter | Meaning |
| --- | --- |
| `startCap` | A `LineCap`, as for [SetLineCap](#setlinecap). |

**Returns** `SetStartCap`: `Ok` on success, otherwise the error. `GetStartCap`: the cap.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 4 )
pen.SetStartCap( LineCapSquare )
print pen.GetStartCap()                             ' 1
```

Microsoft Learn: [Pen::SetStartCap](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setstartcap)

### SetEndCap, GetEndCap

```freebasic
function SetEndCap( byval endCap as LineCap ) as GpStatus
function GetEndCap() as LineCap
```

`SetEndCap` sets the cap drawn at the end of every line and open figure. `GetEndCap` returns it.

| Parameter | Meaning |
| --- | --- |
| `endCap` | A `LineCap`, as for [SetLineCap](#setlinecap). |

**Returns** `SetEndCap`: `Ok` on success, otherwise the error. `GetEndCap`: the cap.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 4 )
pen.SetEndCap( LineCapDiamondAnchor )
print pen.GetEndCap()                               ' 19
```

Microsoft Learn: [Pen::SetEndCap](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setendcap)

### SetDashCap, GetDashCap

```freebasic
function SetDashCap( byval nDashCap as DashCap ) as GpStatus
function GetDashCap() as DashCap
```

`SetDashCap` sets the shape of both ends of every dash in a dashed line. `GetDashCap` returns
it. It has no effect on a solid line.

| Parameter | Meaning |
| --- | --- |
| `nDashCap` | `DashCapFlat` (the default), `DashCapRound` or `DashCapTriangle`. |

**Returns** `SetDashCap`: `Ok` on success, otherwise the error. `GetDashCap`: the cap.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 4 )
pen.SetDashStyle( DashStyleDash )
pen.SetDashCap( DashCapRound )
print pen.GetDashCap()                              ' 2
```

Microsoft Learn: [Pen::SetDashCap](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setdashcap)

### SetLineJoin, GetLineJoin

```freebasic
function SetLineJoin( byval nLineJoin as LineJoin ) as GpStatus
function GetLineJoin() as LineJoin
```

`SetLineJoin` sets how the pen joins two segments that meet at a corner of a rectangle, polygon,
path or poly-line. `GetLineJoin` returns it.

| Parameter | Meaning |
| --- | --- |
| `nLineJoin` | `LineJoinMiter` (the default, a sharp corner cut off at the [miter limit](#setmiterlimit-getmiterlimit)), `LineJoinBevel`, `LineJoinRound` or `LineJoinMiterClipped`. |

**Returns** `SetLineJoin`: `Ok` on success, otherwise the error. `GetLineJoin`: the join.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 8 )
pen.SetLineJoin( LineJoinBevel )
print pen.GetLineJoin()                             ' 1
```

Microsoft Learn: [Pen::SetLineJoin](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setlinejoin)

### SetCustomStartCap, GetCustomStartCap

```freebasic
function SetCustomStartCap( byval pCustomLineCap as CGpCustomLineCap_ ptr ) as GpStatus
function GetCustomStartCap( byval pCustomLineCap as CGpCustomLineCap_ ptr ) as GpStatus
```

`SetCustomStartCap` draws a custom cap at the start of every line: a
[CGpCustomLineCap or CGpAdjustableArrowCap](SysWin-GdiPlus-Line-Caps). The pen keeps a copy, and
its start cap becomes `LineCapCustom`. The pointer must not be `NULL`.

`GetCustomStartCap` copies the pen's custom start cap into the `CGpCustomLineCap` that
`pCustomLineCap` points to, which then owns the copy and deletes it. Pass an empty object
(`dim cap as CGpCustomLineCap`): a GDI+ cap the object already holds is overwritten without
being deleted.

| Parameter | Meaning |
| --- | --- |
| `pCustomLineCap` | The cap to use, or the object that receives the copy. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim arrow as CGpAdjustableArrowCap = CGpAdjustableArrowCap( 5, 4 )
dim pen as CGpPen = CGpPen( ARGB_BLACK, 2 )
pen.SetCustomStartCap( @arrow )
dim cap as CGpCustomLineCap
print pen.GetCustomStartCap( @cap ); pen.GetStartCap()    ' 0 255
```

Microsoft Learn: [Pen::SetCustomStartCap](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setcustomstartcap)

### SetCustomEndCap, GetCustomEndCap

```freebasic
function SetCustomEndCap( byval pCustomLineCap as CGpCustomLineCap_ ptr ) as GpStatus
function GetCustomEndCap( byval pCustomLineCap as CGpCustomLineCap_ ptr ) as GpStatus
```

The same for the end of every line: `SetCustomEndCap` gives the pen a copy of a custom cap and
makes its end cap `LineCapCustom`; `GetCustomEndCap` copies it into an empty
`CGpCustomLineCap`. Passing `NULL` to `SetCustomEndCap` does not remove a custom cap: it returns
`InvalidParameter`. Call [SetEndCap](#setendcap-getendcap) to go back to a standard cap.

| Parameter | Meaning |
| --- | --- |
| `pCustomLineCap` | The cap to use, or the object that receives the copy. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim arrow as CGpAdjustableArrowCap = CGpAdjustableArrowCap( 6, 4 )
dim pen as CGpPen = CGpPen( ARGB_BLACK, 2 )
pen.SetCustomEndCap( @arrow )
dim cap as CGpCustomLineCap
if pen.GetCustomEndCap( @cap ) = Ok then print cap.GetBaseCap()    ' 3
```

Microsoft Learn: [Pen::SetCustomEndCap](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setcustomendcap)

### SetMiterLimit, GetMiterLimit

```freebasic
function SetMiterLimit( byval miterLimit as single ) as GpStatus
function GetMiterLimit() as single
```

`SetMiterLimit` limits how far the point of a mitred corner may reach beyond the line, as a
multiple of half the pen's width; a sharper corner is cut off. `GetMiterLimit` returns it: 10
for a new pen. Only `LineJoinMiter` corners use it.

| Parameter | Meaning |
| --- | --- |
| `miterLimit` | The limit; values below 1 are treated as 1. |

**Returns** `SetMiterLimit`: `Ok` on success, otherwise the error. `GetMiterLimit`: the limit.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 8 )
pen.SetMiterLimit( 3 )
print pen.GetMiterLimit()                           ' 3
```

Microsoft Learn: [Pen::SetMiterLimit](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setmiterlimit)

### SetAlignment, GetAlignment

```freebasic
function SetAlignment( byval nPenAlignment as PenAlignment ) as GpStatus
function GetAlignment() as PenAlignment
```

`SetAlignment` sets where a closed shape's outline lies: `PenAlignmentCenter` (the default)
centres the stroke on the outline, `PenAlignmentInset` puts it inside, so a thick outline does
not grow the shape. `GetAlignment` returns it.

| Parameter | Meaning |
| --- | --- |
| `nPenAlignment` | `PenAlignmentCenter` or `PenAlignmentInset`. |

**Returns** `SetAlignment`: `Ok` on success, otherwise the error. `GetAlignment`: the alignment.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 10 )
pen.SetAlignment( PenAlignmentInset )
print pen.GetAlignment()                            ' 1
```

Microsoft Learn: [Pen::SetAlignment](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setalignment)

### SetTransform

```freebasic
function SetTransform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Replaces the pen's own transformation with a copy of a [CGpMatrix](CGpMatrix). The pen's
transformation reshapes the stroke, not the line: scaling it by (1, 4) draws horizontal lines
four times as thick and leaves vertical ones as they were. The pointer must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pMatrix` | The matrix to copy. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLUE, 2 )
dim m as CGpMatrix = CGpMatrix( 1, 0, 0, 4, 0, 0 )
print pen.SetTransform( @m )                        ' 0
```

Microsoft Learn: [Pen::SetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-settransform)

### GetTransform

```freebasic
function GetTransform( byval pMatrix as CGpMatrix ptr ) as GpStatus
```

Copies the pen's transformation into the `CGpMatrix` that `pMatrix` points to.

| Parameter | Meaning |
| --- | --- |
| `pMatrix` | An existing matrix. |

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLUE, 2 )
pen.RotateTransform( 30 )
dim m as CGpMatrix
print pen.GetTransform( @m )
```

Microsoft Learn: [Pen::GetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-gettransform)

### ResetTransform

```freebasic
function ResetTransform() as GpStatus
```

Makes the pen's transformation the identity again, so the stroke is drawn as the width says.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLUE, 2 )
pen.ScaleTransform( 1, 4 )
pen.ResetTransform()
```

Microsoft Learn: [Pen::ResetTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-resettransform)

### MultiplyTransform

```freebasic
function MultiplyTransform( byval pMatrix as CGpMatrix ptr, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Combines the pen's transformation with a matrix. With `MatrixOrderPrepend` (the default) the
matrix is applied before the pen's transformation, with `MatrixOrderAppend` after it. The
pointer must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pMatrix` | The matrix to combine with. |
| `order` | `MatrixOrderPrepend` or `MatrixOrderAppend`. |

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLUE, 2 )
dim m as CGpMatrix = CGpMatrix( 2, 0, 0, 1, 0, 0 )
pen.MultiplyTransform( @m, MatrixOrderAppend )
```

Microsoft Learn: [Pen::MultiplyTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-multiplytransform)

### TranslateTransform

```freebasic
function TranslateTransform( byval dx as single, byval dy as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a move by (`dx`, `dy`) to the pen's transformation, before (`MatrixOrderPrepend`, the
default) or after (`MatrixOrderAppend`) what it already holds.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLUE, 2 )
pen.TranslateTransform( 2, 2 )
```

Microsoft Learn: [Pen::TranslateTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-translatetransform)

### ScaleTransform

```freebasic
function ScaleTransform( byval sx as single, byval sy as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a scaling by `sx` horizontally and `sy` vertically to the pen's transformation. A pen of
width 2 scaled by (1, 4) draws horizontal lines 8 thick and vertical lines 2 thick: a
calligraphic nib.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLUE, 2 )
pen.ScaleTransform( 1, 4 )
```

Microsoft Learn: [Pen::ScaleTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-scaletransform)

### RotateTransform

```freebasic
function RotateTransform( byval angle as single, byval order as MatrixOrder = MatrixOrderPrepend ) as GpStatus
```

Adds a rotation by `angle` degrees to the pen's transformation. Combined with a scaling it turns
the calligraphic nib.

**Returns** `Ok` on success, otherwise the error.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLUE, 2 )
pen.ScaleTransform( 1, 4 )
pen.RotateTransform( 45, MatrixOrderAppend )
```

Microsoft Learn: [Pen::RotateTransform](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-rotatetransform)

### GetPenType

```freebasic
function GetPenType() as PenType
```

Tells what the pen strokes with.

**Returns** `PenTypeSolidColor` (0), `PenTypeHatchFill` (1), `PenTypeTextureFill` (2),
`PenTypePathGradient` (3) or `PenTypeLinearGradient` (4).

**Example**

```freebasic
dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleCross, ARGB_RED, ARGB_WHITE )
dim pen as CGpPen = CGpPen( @hatch, 4 )
print pen.GetPenType()                              ' 1
```

Microsoft Learn: [Pen::GetPenType](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-getpentype)

### SetColor, GetColor

```freebasic
function SetColor( byval colour as ARGB ) as GpStatus
function GetColor( byval colour as ARGB ptr ) as GpStatus
```

`SetColor` makes the pen a solid pen of `colour`, replacing a brush it had. `GetColor` stores the
colour of a solid pen in the `ARGB` that `colour` points to; for a pen that strokes with a brush
it returns `WrongState` and leaves the variable alone.

| Parameter | Meaning |
| --- | --- |
| `colour` | The new colour, or the variable that receives it. |

**Returns** `Ok` on success; `GetColor` returns `WrongState` (8) for a brush pen.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_RED )
dim c as ARGB
pen.GetColor( @c )
print hex( c )                                      ' FFFF0000
```

Microsoft Learn: [Pen::SetColor](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setcolor)

### SetBrush, GetBrush

```freebasic
function SetBrush( byval pBrush as CGpBrush ptr ) as GpStatus
function GetBrush( byval pBrush as CGpBrush ptr ) as GpStatus
```

`SetBrush` makes the pen stroke with a copy of a brush; [GetPenType](#getpentype) then names the
kind of brush. The pointer must not be `NULL`.

`GetBrush` puts a copy of the pen's brush (for a solid pen, a solid brush of its colour) into the
`CGpBrush` that `pBrush` points to, which then owns the copy and deletes it. Pass an empty
`CGpBrush`: a GDI+ brush the object already holds is overwritten without being deleted. The copy
is reached through the base class; [GetType](SysWin-GdiPlus-Brushes#gettype) tells which kind it
is.

| Parameter | Meaning |
| --- | --- |
| `pBrush` | The brush to use, or the object that receives the copy. |

**Returns** `Ok` on success; `GetBrush` returns `InvalidParameter` when `pBrush` is `NULL`.

**Example**

```freebasic
dim hatch as CGpHatchBrush = CGpHatchBrush( HatchStyleCross, ARGB_RED, ARGB_WHITE )
dim pen as CGpPen = CGpPen( ARGB_BLACK, 4 )
pen.SetBrush( @hatch )
dim b as CGpBrush
if pen.GetBrush( @b ) = Ok then print b.GetType()   ' 1
```

Microsoft Learn: [Pen::SetBrush](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setbrush)

### SetDashStyle, GetDashStyle

```freebasic
function SetDashStyle( byval nDashStyle as DashStyle ) as GpStatus
function GetDashStyle() as DashStyle
```

`SetDashStyle` picks a predefined pattern of dashes and dots. `GetDashStyle` returns the style:
`DashStyleCustom` (5) once [SetDashPattern](#setdashpattern-getdashpattern-getdashpatterncount)
has set a pattern of your own.

| Parameter | Meaning |
| --- | --- |
| `nDashStyle` | `DashStyleSolid` (the default), `DashStyleDash`, `DashStyleDot`, `DashStyleDashDot` or `DashStyleDashDotDot`. |

**Returns** `SetDashStyle`: `Ok` on success, otherwise the error. `GetDashStyle`: the style.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 2 )
pen.SetDashStyle( DashStyleDash )
print pen.GetDashStyle(); pen.GetDashPatternCount()   ' 1 2
```

Microsoft Learn: [Pen::SetDashStyle](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setdashstyle)

### SetDashOffset, GetDashOffset

```freebasic
function SetDashOffset( byval dashOffset as single ) as GpStatus
function GetDashOffset() as single
```

`SetDashOffset` moves the dash pattern along the line: a line starts `dashOffset` pen widths
into the pattern. Changing it step by step makes "marching ants". `GetDashOffset` returns it,
0 for a new pen.

| Parameter | Meaning |
| --- | --- |
| `dashOffset` | The distance into the pattern, in multiples of the pen width. |

**Returns** `SetDashOffset`: `Ok` on success, otherwise the error. `GetDashOffset`: the offset.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 2 )
pen.SetDashStyle( DashStyleDash )
pen.SetDashOffset( 2 )
print pen.GetDashOffset()                           ' 2
```

Microsoft Learn: [Pen::SetDashOffset](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setdashoffset)

### SetDashPattern, GetDashPattern, GetDashPatternCount

```freebasic
function SetDashPattern( byval dashArray as single ptr, byval nCount as INT_ ) as GpStatus
function GetDashPatternCount() as INT_
function GetDashPattern( byval dashArray as single ptr, byval nCount as INT_ ) as GpStatus
```

`SetDashPattern` sets a pattern of your own: an array of lengths, dash, space, dash, space …,
each a multiple of the pen width, which repeats along the line. The dash style becomes
`DashStyleCustom`.

`GetDashPatternCount` returns the number of lengths in the current pattern (0 for a solid pen,
2 for `DashStyleDash`). `GetDashPattern` copies `nCount` of them into an array you provide;
size it with `GetDashPatternCount`.

| Parameter | Meaning |
| --- | --- |
| `dashArray` | The first element of an array of positive `single` lengths. |
| `nCount` | The number of elements. |

**Returns** `SetDashPattern` and `GetDashPattern`: `Ok` on success, otherwise the error.
`GetDashPatternCount`: the count.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_BLACK, 2 )
dim d(0 to 3) as single = { 4, 2, 1, 2 }
pen.SetDashPattern( @d(0), 4 )
dim r(0 to 3) as single
pen.GetDashPattern( @r(0), pen.GetDashPatternCount() )
print r(0); r(1); r(2); r(3)                        ' 4 2 1 2
```

Microsoft Learn: [Pen::SetDashPattern](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setdashpattern)

### SetCompoundArray, GetCompoundArray, GetCompoundArrayCount

```freebasic
function SetCompoundArray( byval compoundArray as single ptr, byval nCount as INT_ ) as GpStatus
function GetCompoundArrayCount() as INT_
function GetCompoundArray( byval compoundArray as single ptr, byval nCount as INT_ ) as GpStatus
```

`SetCompoundArray` splits the stroke into parallel bands with gaps between them. The array holds
pairs of positions across the width, from 0 (one edge) to 1 (the other), each pair the start and
end of a band, in increasing order: `{ 0, 0.3, 0.7, 1 }` draws two bands with a gap in the
middle.

`GetCompoundArrayCount` returns the number of positions (0 for a plain pen).
`GetCompoundArray` copies `nCount` of them into an array you provide.

| Parameter | Meaning |
| --- | --- |
| `compoundArray` | The first element of the array of positions. |
| `nCount` | The number of elements: even, at least 2. |

**Returns** `SetCompoundArray` and `GetCompoundArray`: `Ok` on success, otherwise the error.
`GetCompoundArrayCount`: the count.

**Example**

```freebasic
dim pen as CGpPen = CGpPen( ARGB_NAVY, 12 )
dim bands(0 to 3) as single = { 0, 0.25, 0.75, 1 }
pen.SetCompoundArray( @bands(0), 4 )
dim r(0 to 3) as single
pen.GetCompoundArray( @r(0), pen.GetCompoundArrayCount() )
print r(1); r(2)                                    ' 0.25 0.75
```

Microsoft Learn: [Pen::SetCompoundArray](https://learn.microsoft.com/en-us/windows/win32/api/gdipluspen/nf-gdipluspen-pen-setcompoundarray)

## See also

- [CGpGraphics](CGpGraphics), whose `Draw…` methods take a pen
- [GDI+ brushes](SysWin-GdiPlus-Brushes) for pens that stroke with a pattern or gradient
- [GDI+ line caps](SysWin-GdiPlus-Line-Caps) for custom caps and arrow heads
- [CGpMatrix](CGpMatrix) for the pen's transformation
- [Colours](SysWin-Colors) for the `ARGB_*` constants
- [sys/win/gdiplus](SysWin-GdiPlus)
