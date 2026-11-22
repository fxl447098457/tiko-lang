[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPaint**

# tkPaint

Paints shapes, text and images for tkControls widgets on SDL_Renderer and SDL_ttf.

tkPaint is the drawing surface every tkControls control paints through. You do not create one: [tkHost](tkHost) hands each widget a `TK_PAINT ptr` in `TKM_PAINT` (`m->pPaint`), and [tkApp](tkApp) hands one to a form's `OnPaint`. It is already clipped to the widget, with the origin at the widget's top-left, so every rect you pass is in widget-local pixels.

Every shape is anti-aliased, with straight edges on whole pixels kept crisp. Colours are state on the object (back for fills, pen for strokes, fore for text) and are `ulong` values in `&hAARRGGBB` form: `tkRGB( r, g, b )`, `tkRGBA( r, g, b, a )`, `tkColor_WithAlpha`, `tkColor_Lerp`. Fonts are `TTF_Font ptr`, borrowed, never owned.

The module also holds the small types the whole family uses: `TKRECT` and `TKPOINT` (right and bottom exclusive: `(10, 5, 40, 20)` covers x 10..39, y 5..19) with the `tkRect_*` helpers, and the UTF-8 text measurers `tkText_*`.

## Importing

```freebasic
#import "vendor/tkControls/tkPaint"

using tkPaint
```

Every control imports it through [tkHost](tkHost), so after any control's `#import`, `using tkPaint` is enough. It re-exports `vendor/SDL3/ttf` and `vendor/SDL3/image`.

## Example

A form's paint callback, adapted from the toolchain's `examples/tkControls/tkApp/`:

```freebasic
sub Main_Paint( byval f as TK_FORM ptr, byval b as TK_PAINT ptr )
    dim as TKTHEME_COLORS t = tkApp_Theme()
    dim as TKRECT rc
    tkRect_Set( rc, tkForm_Scale( f, 16 ), tkForm_Scale( f, 16 ), _
                tkForm_Widget( f )->cw - tkForm_Scale( f, 16 ), tkForm_Scale( f, 80 ) )
    b->SetBackColor( t.Surface )
    b->SetPenColor( t.Border )
    b->PaintRoundBorderRect( @rc, tkForm_Scale( f, 12 ) )      ' curvature is a diameter
    b->SetFont( tkForm_Font( f, TKFONT_UI_LARGE ) )
    b->SetForeColor( t.TextStrong )
    b->PaintText( "Hello from tkPaint", @rc, TK_DT_CENTER or TK_DT_ELLIPSIS )
end sub
```

## The frame and the state

The host paints the whole window every frame, parents before children, and presents it once; there is no buffer of your own and nothing to begin or end. Each widget's paint gets a fresh `TK_PAINT`: back colour opaque black, fore and pen colour white, a solid pen, and the host's default font. Whatever you set lasts until you change it, within that one paint.

- **Back colour** feeds every fill: `PaintRect`, `PaintRoundRect`, `PaintEllipse`, `PaintPolygon`, `PaintPie`, `PaintPieRing`, and the interiors of `PaintBorderRect`, `PaintRoundBorderRect` and `PaintRectFactory`.
- **Pen colour** feeds every stroke: their borders, `PaintRoundOutline`, the rims of `PaintEllipse`, `PaintPolygon`, `PaintPie` and `PaintPieRing`, and `PaintPolyline`, `PaintCurve` and `PaintLine`.
- **Fore colour** feeds `PaintText` and `PaintTextEx`. `PaintChar` takes its colour as an argument and leaves the fore colour alone; `PaintGradientRect` takes its two stops as arguments and uses neither back nor pen.
- Alpha is part of the colour and blends with what is already drawn, text included.
- `SetFont( 0 )` is ignored, so a font can be replaced but not cleared. The text methods draw nothing without a font.

Hover and selection styling is yours: decide the state, set the colours, then paint. To clear a widget, fill its own rect, `0, 0, w->cw, w->ch`, at the top of the paint.

## Shapes and pens

- **Fills cover what is under them.** `PaintBorderRect`, `PaintRoundBorderRect` and `PaintRectFactory` fill first and then stroke, so used as a frame over content they erase it. `PaintRoundOutline` strokes without filling: use it for a focus ring or a frame. `PaintGradientRect` never strokes; frame it afterwards with `PaintRoundOutline`.
- **Curvature is the corner ellipse's diameter**, halved internally, and clamped to half the shape's width and height, so an over-large value gives a stadium. `0` gives square corners. A pill is a rounded rect whose curvature equals its height.
- **Where a stroke lands:** `PaintRoundOutline`, the bordered rects and `PaintEllipse`'s rim sit inside the rect, so a border is on the rect's edge at any width and needs no deflating. `PaintPolygon`'s outline and the pie rims are centred on the path.
- **Pen widths are pixels as given**, except `PaintPie`, `PaintPieRing`, `PaintPolyline` and `PaintCurve`, which scale theirs by the surface's scale (never below 1). A width of 0 or less draws no stroke; `PaintRoundOutline` and `PaintLine` then draw nothing at all.
- `PaintLine` draws an axis-aligned rule as a crisp filled rect, centred on the line and stopping short of the end point; a diagonal is an anti-aliased line through the centres of both end pixels.
- `SetPenDashStyle` applies to `PaintPolyline` and `PaintCurve`; the pattern is in pen-width units, and an unknown value means `TK_PENDASH_SOLID`. A solid polyline or curve wider than 1.5 pixels gets round joins.
- `PaintPolygon` fills any simple polygon, convex or not, closing it for you; its points are pixel centres. Fewer than 3 points draw nothing.
- `PaintPie` and `PaintPieRing` take angles in degrees, clockwise from the positive x axis. A zero sweep draws nothing; a sweep of 360 or more is the whole ellipse. The ring's hole is `nInnerRatio` of the radius, clamped to 0..0.9; a hole under a pixel draws a plain pie.
- `PaintCurve` draws a cardinal spline through the points, `nTension` clamped to 0..1; with fewer than 3 points it is a polyline.
- Empty rects and missing pointers are skipped silently.

## Text

- `PaintText` draws one line, vertically centred unless `TK_DT_TOP` or `TK_DT_BOTTOM`; `TK_DT_ELLIPSIS` cuts it with "…" when it does not fit. It never wraps, and `&` is drawn as itself.
- `PaintTextEx` breaks at newlines and, with `TK_DT_WORDBREAK`, wraps to the rect's width, dropping spaces at the break and cutting a word wider than the line where it stops fitting. Each line takes the horizontal alignment; the block sits at the top unless `TK_DT_VCENTER` or `TK_DT_BOTTOM`. `tkText_MeasureWrapped` gives the height it needs, and `tkText_Wrap` the line offsets.
- `PaintChar( glyph, rc, clr )` draws one icon-font glyph in the current font, left-aligned, vertically centred and unclipped, in its own colour (see [tkHost](tkHost)'s `TK_ICON_*`). Set the icon font first.
- Text is drawn with no background, and clipped to its rect unless `TK_DT_NOCLIP`.
- `tkText_Height` is the one line height layout should use; `tkText_LineSkip` is the baseline-to-baseline distance. String offsets for `tkText_IndexToX`, `XToIndex`, `NextOffset` and `PrevOffset` are UTF-8 byte offsets on codepoint boundaries. `IndexToX` is the caret position before an offset; `XToIndex` is the offset whose caret is nearest x.

## Clipping and images

Every call is clipped to the widget, and to any ancestor that clips its children. `SetClipRect` narrows that to a rect until `ResetClip`; each call replaces the last. `PushClip` intersects with the clip in force and `PopClip` restores it, nesting up to eight deep; `ResetClip` also empties that stack.

`PaintImage( tex, rc, fit )` draws an `SDL_Texture`, clipped to `rc`: `TK_IMGFIT_ASPECT` fits it inside, centred, with its proportions kept, `_STRETCH` fills `rc` exactly, `_CENTER` draws it centred at natural size. For an image file, use [tkImage](tkImage)'s `tkImage_Paint`, which makes the texture for you.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
enum
    TK_DT_LEFT      = 0
    TK_DT_CENTER    = 1
    TK_DT_RIGHT     = 2
    TK_DT_ELLIPSIS  = 4
    TK_DT_TOP       = 8
    TK_DT_BOTTOM    = 16
    TK_DT_VCENTER   = 32
    TK_DT_WORDBREAK = 64
    TK_DT_NOCLIP    = 128
end enum

enum
    TK_IMGFIT_ASPECT = 0      ' fit inside, proportions kept, centred
    TK_IMGFIT_STRETCH         ' fill exactly
    TK_IMGFIT_CENTER          ' natural size, centred, clipped
end enum

enum
    TK_PENDASH_SOLID = 0
    TK_PENDASH_DASH
    TK_PENDASH_DOT
    TK_PENDASH_DASHDOT
end enum

enum
    TK_GRADIENT_HORIZONTAL = 0
    TK_GRADIENT_VERTICAL
    TK_GRADIENT_FDIAGONAL     ' top-left -> bottom-right
    TK_GRADIENT_BDIAGONAL     ' top-right -> bottom-left
end enum
```

### Types

```freebasic
type TKRECT
    left   as long
    top    as long
    right  as long
    bottom as long
end type

type TKPOINT
    x as long
    y as long
end type

type TK_PAINT
    renderer as SDL_Renderer ptr
    engine   as TTF_TextEngine ptr
    fScale   as single = 1               ' the surface's scale, for the DPI-scaled pens
    ox       as long                     ' widget origin, window pixels
    oy       as long
    rcClip   as TKRECT                   ' the widget's own clip, window pixels
    rcCur    as TKRECT                   ' the clip in force now (window pixels)
    clipStack(0 to 7) as TKRECT
    nClip    as long
    clrBack  as ulong = &hFF000000ul
    clrFore  as ulong = &hFFFFFFFFul
    clrPen   as ulong = &hFFFFFFFFul
    nDash    as long = TK_PENDASH_SOLID
    pFont    as TTF_Font ptr
    declare sub SetBackColor( byval c as ulong )
    declare sub SetForeColor( byval c as ulong )
    declare sub SetPenColor( byval c as ulong )
    declare sub SetColors( byval fore as ulong, byval back as ulong )
    declare sub SetFont( byval f as TTF_Font ptr )
    declare sub SetPenDashStyle( byval nDash as long )
    declare function GetPenDashStyle() as long
    declare sub Begin( byval x as long, byval y as long, byval w as long, byval h as long, byval pParentClip as TKRECT ptr = 0 )
    declare sub SetClipRect( byval rc as TKRECT ptr )
    declare sub ResetClip()
    declare sub PushClip( byval rc as TKRECT ptr )
    declare sub PopClip()
    declare sub ApplyClip( byval rc as TKRECT ptr )
    declare sub PaintRect( byval rc as TKRECT ptr )
    declare sub PaintBorderRect( byval rc as TKRECT ptr, byval nPenWidth as long = 1 )
    declare sub PaintRectFactory( byval rc as TKRECT ptr, byval nPenWidth as long = 1, byval nCurvature as long = 0 )
    declare sub PaintRoundRect( byval rc as TKRECT ptr, byval curvature as long = 20 )
    declare sub PaintRoundBorderRect( byval rc as TKRECT ptr, byval curvature as long = 20, byval thick as long = 1 )
    declare sub PaintRoundOutline( byval rc as TKRECT ptr, byval curvature as long = 20, byval thick as long = 1 )
    declare sub PaintGradientRect( byval rc as TKRECT ptr, byval clr1 as ulong, byval clr2 as ulong, byval nMode as long = TK_GRADIENT_VERTICAL, byval nCurvature as long = 0 )
    declare sub PaintEllipse( byval rc as TKRECT ptr, byval nPenWidth as long = 0 )
    declare sub PaintPolygon( byval pts as TKPOINT ptr, byval nCount as long, byval nPenWidth as long = 0 )
    declare sub PaintPie( byval rc as TKRECT ptr, byval startAngle as single, byval sweepAngle as single, byval nPenWidth as long = 0 )
    declare sub PaintPieRing( byval rc as TKRECT ptr, byval nInnerRatio as single, byval startAngle as single, byval sweepAngle as single, byval nPenWidth as long = 0 )
    declare sub PaintPolyline( byval pts as TKPOINT ptr, byval nCount as long, byval nPenWidth as long = 1 )
    declare sub PaintCurve( byval pts as TKPOINT ptr, byval nCount as long, byval nPenWidth as long = 1, byval nTension as single = 0.5 )
    declare sub PaintLine( byval nWidth as long, byval l as long, byval t as long, byval r as long, byval b as long )
    declare sub PaintText( byref s as ustring, byval rc as TKRECT ptr, byval flags as long )
    declare sub PaintTextEx( byref s as ustring, byval rc as TKRECT ptr, byval flags as long )
    declare sub PaintChar( byref glyph as ustring, byval rc as TKRECT ptr, byval clr as ulong )
    declare sub PaintImage( byval tex as SDL_Texture ptr, byval rc as TKRECT ptr, byval nFit as long = TK_IMGFIT_ASPECT )
end type
```

### Procedures

```freebasic
sub tkRect_Set( byref rc as TKRECT, byval l as long, byval t as long, byval r as long, byval b as long )
sub tkRect_SetEmpty( byref rc as TKRECT )
function tkRect_IsEmpty( byref rc as TKRECT ) as boolean
sub tkRect_Inflate( byref rc as TKRECT, byval dx as long, byval dy as long )
sub tkRect_Offset( byref rc as TKRECT, byval dx as long, byval dy as long )
function tkRect_Contains( byref rc as TKRECT, byval x as single, byval y as single ) as boolean
function tkRect_Intersect( byref a as TKRECT, byref b as TKRECT ) as TKRECT
function tkRect_Width( byref rc as TKRECT ) as long
function tkRect_Height( byref rc as TKRECT ) as long
function tkRect_Str( byref rc as TKRECT ) as string
function tkRGB( byval r as long, byval g as long, byval b as long ) as ulong
function tkRGBA( byval r as long, byval g as long, byval b as long, byval a as long ) as ulong
function tkColor_WithAlpha( byval c as ulong, byval a as long ) as ulong
function tkColor_Lerp( byval a as ulong, byval b as ulong, byval t as single ) as ulong
function tkText_Height( byval f as TTF_Font ptr ) as long
function tkText_LineSkip( byval f as TTF_Font ptr ) as long
function tkText_WidthU8( byval f as TTF_Font ptr, byref u8 as string ) as long
function tkText_Width( byval f as TTF_Font ptr, byref s as ustring ) as long
function tkText_NextOffset( byref u8 as string, byval i as long ) as long
function tkText_PrevOffset( byref u8 as string, byval i as long ) as long
function tkText_IndexToX( byval f as TTF_Font ptr, byref u8 as string, byval i as long ) as long
function tkText_XToIndex( byval f as TTF_Font ptr, byref u8 as string, byval x as long ) as long
function tkText_Wrap( byval f as TTF_Font ptr, byref u8 as string, byval nWidth as long, starts() as long, ends() as long ) as long
function tkText_MeasureWrapped( byval f as TTF_Font ptr, byref s as ustring, byval nWidth as long ) as long
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
