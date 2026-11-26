[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPrint**

# tkPrint

Builds print documents: pages drawn once in points, then shown, printed or exported.

A `TK_PRINTDOC` holds pages. You draw a page with the `tkPage_*` API, in **points** (1/72 inch, origin top-left, y down), or let any widget paint itself onto it with `tkPrint_PaintWidget`. Either way the page is a *recording* of what [tkPaint](tkPaint) would have drawn, so it can be replayed at any size: in a window (`tkPrintReplay_Page`), as a surface (`tkPrintDoc_RenderSurface`) or as PNG files (`tkPrintDoc_ExportPng`). A page replayed at the scale it was recorded at is the same pixels as painting it directly.

The pages can be shown in [tkPrintPreview](tkPrintPreview) and written as PDF by [tkPdf](tkPdf). [tkPrinter](tkPrinter) prints them, [tkPrintDialog](tkPrintDialog) asks how, and [tkReportViewer](tkReportViewer) puts all of it in one control. [tkReport](tkReport) builds documents from rows of data.

## Importing

```freebasic
#import "vendor/tkControls/tkPrint"

using tkHost
using tkPaint
using tkPrint
```

It imports [tkHost](tkHost) (and so tkPaint) publicly.

## Example

Two pages with a footer that knows the page count, written out at 150 dpi:

```freebasic
function MyPage( byval doc as TK_PRINTDOC ptr, byval pg as TK_PAGE ptr, byval i as long ) as boolean
    dim as TKRECTF m, r
    tkPage_GetMarginRect( pg, m )
    dim as TKFONTSPEC fs
    fs.pt = 18 : fs.bold = true
    tkPage_SetFont( pg, fs )
    tkRectF_Set( r, m.left, m.top, m.right, m.top + 28 )
    tkPage_Text( pg, "Report, part " & (i + 1), r, TK_DT_LEFT )
    fs.pt = 8 : fs.bold = false
    tkPage_SetFont( pg, fs )
    tkRectF_Set( r, m.left, m.bottom - 14, m.right, m.bottom )
    tkPage_LateText( pg, r, "Page {p} of {n}", TK_DT_RIGHT )
    return i < 1                                   ' TRUE: another page follows
end function

dim as TK_PRINTDOC ptr doc = tkPrintDoc_Create( "Report" )
tkPrintDoc_SetPrintPageCallback( doc, @MyPage )
tkPrintDoc_Generate( doc )
tkPrintDoc_ExportPng( doc, "report-p{p}.png", 150 )
tkPrintDoc_Destroy( doc )
```

The toolchain's `examples/tkControls/tkPrint/demo` also prints a [tkChart](tkChart) through its own paint code.

## Documents and pages

- `tkPrintDoc_Create( title )` makes an empty document with the default page setup; `tkPrintDoc_Destroy` frees it.
- `TKPAGESETUP` is the paper (`TK_PAPER_A4`, `_LETTER`, `_LEGAL`, `_A3`, `_A5`, `_B5`, `_TABLOID`, `_EXECUTIVE`, or `_CUSTOM` with `widthPt` / `heightPt`), `landscape`, and four margins in points from the paper's edge (20 mm by default). `TK_PAPER_DEFAULT` becomes Letter in the regions that use it (US, Canada, Mexico and others) and A4 everywhere else, from the user's locale.
- **Push style:** `tkPrintDoc_AddPage( doc )` (or `AddPageEx` with its own setup) returns the page to draw on now.
- **Pull style:** `tkPrintDoc_SetPrintPageCallback( doc, cb )`, then `tkPrintDoc_Generate( doc )` calls `cb( doc, pg, pageIndex )` until it returns FALSE, and returns the page count. Generating again starts over.
- **A few pages at a time:** `tkPrintDoc_BeginGenerate( doc )`, then `tkPrintDoc_GenerateStep( doc, n )` makes up to n more pages and returns TRUE while more remain. `tkPrintDoc_IsComplete` says the count is final; `tkPrintDoc_Cancel` stops and keeps what was made. A [tkPrintPreview](tkPrintPreview) given a document begun this way finishes it on its own timer.
- `tkPrintDoc_GetSerial( doc )` changes whenever pages are added or cleared, for a cache of rendered pages to key on.
- A document has **one** `TK_PAGE` pen: `AddPage` moves it to the new page, so a `TK_PAGE ptr` always means the latest page.
- `tkPrintDoc_Warnings( doc )` lists anything replaced while recording or writing (a font tkHost did not open, an image that could not be read, text a PDF draws as an image), one line each. An output device adds to it with `tkPrintDoc_Warn`.

## Drawing on a page

Everything is in points. Fill colour fills, line colour strokes, text colour writes; colours are tkPaint's `&hAARRGGBB`. `tkPage_SetPen( pg, widthPt, dash )` sets the pen (0.5 pt by default; 0 draws nothing).

- Shapes: `FillRect`, `StrokeRect`, `FillRoundRect` / `StrokeRoundRect` (a corner *radius*), `FillEllipse` / `StrokeEllipse`, `Line`, `Polyline`, `Polygon`, `Pie`, `GradientRect`. A stroke around a rect or ellipse sits inside it, as in tkPaint.
- Text: `tkPage_SetFont( pg, fs )` takes a `TKFONTSPEC` (`src` a font file or registered name, `""` for the bundled UI font; `pt`; `bold`; `italic`). `tkPage_Text( pg, s, rc, flags )` lays text out with tkPaint's `TK_DT_*` flags (ellipsis, alignment, word wrap) and returns the height used. `MeasureText`, `MeasureWrapped`, `TextHeight` and `LineSkip` measure.
- `tkPage_LateText( pg, rc, fmt, flags )` writes text known only when the document is complete: `{p}` is the page number and `{n}` the page count, filled in each time the page is drawn.
- Images: `tkPage_Image( pg, file, rc, fit )` and `tkPage_ImageSurface` copy the pixels into the document.
- `tkPage_PushClip` / `PopClip` clip to a rect.
- Links: `tkPage_Link( pg, rc, url )` and `tkPage_LinkToPage( pg, rc, page, yPt )` make a rect clickable in a preview. They draw nothing; draw the text yourself. `tkPrintDoc_LinkAt( doc, page, xPt, yPt, url, targetPage, targetY )` finds the link at a point.

The page API draws through a recording `TK_PAINT` at 10 pixels per point, so positions are exact to 0.1 pt and text is measured by SDL_ttf at that size.

## Printing a widget

`tkPrint_PaintWidget( pg, w, rc )` records widget `w` and its children, in z-order, exactly as [tkHost](tkHost) paints them, and maps them into `rc`, scaled to fit and centred. Nothing needs to change in a control: anything that paints through `TK_PAINT` prints. The widget keeps its current pixel layout; its shapes, pens and fonts scale with it. A hidden widget prints too. `tkHost_Root( h )` prints a whole form. Controls that draw with SDL directly (tkCodeEdit) are not recorded.

## Replay and raster

- `tkPrintReplay_Create( renderer, engine )` makes a replayer for one renderer; it caches fonts at the sizes asked for and textures for the document's images. `tkPrintReplay_Page( rp, doc, page, x, y, pxPerPt )` draws a page with its top-left at (x, y). It does not draw the paper.
- `tkPrintDoc_RenderSurface( doc, page, dpi )` returns the page on white as an ARGB8888 surface.
- `tkPrintDoc_ExportPng( doc, pattern, dpi, first, last )` writes pages as PNG; `{p}` in the pattern is the page number.
- `tkPrintDoc_GetOpCount` and `tkPrintDoc_GetOp` read a page's recording back, for tests.

## Public declarations

### Constants

```freebasic
const TK_PT_PER_INCH = 72.0
const TK_PT_PER_MM = 2.834645669
const TKPRINT_OP_LATE = PR_LATE

enum
    TK_PAPER_DEFAULT = 0      ' Letter or A4 by the user's locale (tkPrint_DefaultPaper)
    TK_PAPER_A4
    TK_PAPER_LETTER
    TK_PAPER_LEGAL
    TK_PAPER_A3
    TK_PAPER_A5
    TK_PAPER_B5               ' ISO B5
    TK_PAPER_TABLOID
    TK_PAPER_EXECUTIVE
    TK_PAPER_CUSTOM           ' widthPt / heightPt as given
end enum
```

### Types

```freebasic
type TKRECTF
    left   as single
    top    as single
    right  as single
    bottom as single
end type

type TKPOINTF
    x as single
    y as single
end type

type TKPAGESETUP
    paper     as long = TK_PAPER_DEFAULT
    widthPt   as single           ' portrait width; filled from paper unless CUSTOM
    heightPt  as single
    landscape as boolean
    marginL   as single = 56.69   ' 20 mm, from the paper's edge
    marginT   as single = 56.69
    marginR   as single = 56.69
    marginB   as single = 56.69
end type

type TKFONTSPEC
    src       as string           ' a tkHost resource name or a font file; "" = the UI font
    face      as long             ' face index in a collection
    pt        as single = 10
    bold      as boolean
    italic    as boolean
end type

type PR_PrintPageFunc as function( byval doc as TK_PRINTDOC ptr, byval pg as TK_PAGE ptr, byval pageIndex as long ) as boolean

type TKPRINT_OPINFO
    op     as long                ' TKREC_* or TKPRINT_OP_LATE
    c      as ulong
    w      as single              ' stroke width, points
    n      as long                ' point count (CLIP: 0 = none)
    x      as single              ' rect / text origin, points
    y      as single
    cw     as single
    ch     as single
    x0     as single              ' the first point (outline ops)
    y0     as single
    size   as single              ' font size, points
    tw     as single              ' text width, points
    text   as string              ' TEXT: the run; LATE: the format
    font   as string              ' the font's source
end type
```

`TK_PRINTDOC`, `TK_PAGE` and `TK_PRINTREPLAY` are handles: use them through the procedures.

### Procedures

```freebasic
sub tkRectF_Set( byref rc as TKRECTF, byval l as single, byval t as single, byval r as single, byval b as single )
function tkPrint_DefaultPaper() as long
function tkPrint_PaperSize( byval paper as long, byref w as single, byref h as single ) as boolean
sub tkPageSetup_Resolve( byref ps as TKPAGESETUP )
sub tkPageSetup_PageSize( byref ps as TKPAGESETUP, byref w as single, byref h as single )
function tkPrintDoc_Create( byref title as ustring = "" ) as TK_PRINTDOC ptr
sub tkPrintDoc_Clear( byval doc as TK_PRINTDOC ptr )
sub tkPrintDoc_Destroy( byval doc as TK_PRINTDOC ptr )
sub tkPrintDoc_SetPageSetup( byval doc as TK_PRINTDOC ptr, byref ps as TKPAGESETUP )
function tkPrintDoc_GetPageSetup( byval doc as TK_PRINTDOC ptr ) as TKPAGESETUP
sub tkPrintDoc_SetTitle( byval doc as TK_PRINTDOC ptr, byref title as ustring )
function tkPrintDoc_GetTitle( byval doc as TK_PRINTDOC ptr ) as ustring
sub tkPrintDoc_SetUserData( byval doc as TK_PRINTDOC ptr, byval p as any ptr )
function tkPrintDoc_GetUserData( byval doc as TK_PRINTDOC ptr ) as any ptr
function tkPrintDoc_GetPageCount( byval doc as TK_PRINTDOC ptr ) as long
function tkPrintDoc_GetPageSize( byval doc as TK_PRINTDOC ptr, byval page as long, byref w as single, byref h as single ) as boolean
sub tkPrintDoc_Warn( byval doc as TK_PRINTDOC ptr, byref s as ustring )
function tkPrintDoc_Warnings( byval doc as TK_PRINTDOC ptr ) as ustring
function tkPrintDoc_AddPageEx( byval doc as TK_PRINTDOC ptr, byref ps as TKPAGESETUP ) as TK_PAGE ptr
function tkPrintDoc_AddPage( byval doc as TK_PRINTDOC ptr ) as TK_PAGE ptr
sub tkPrintDoc_SetPrintPageCallback( byval doc as TK_PRINTDOC ptr, byval cb as PR_PrintPageFunc )
sub tkPrintDoc_BeginGenerate( byval doc as TK_PRINTDOC ptr )
function tkPrintDoc_GenerateStep( byval doc as TK_PRINTDOC ptr, byval nMax as long = 1 ) as boolean
function tkPrintDoc_IsComplete( byval doc as TK_PRINTDOC ptr ) as boolean
sub tkPrintDoc_Cancel( byval doc as TK_PRINTDOC ptr )
function tkPrintDoc_GetSerial( byval doc as TK_PRINTDOC ptr ) as long
function tkPrintDoc_Generate( byval doc as TK_PRINTDOC ptr ) as long
function tkPrintDoc_LinkAt( byval doc as TK_PRINTDOC ptr, byval page as long, byval xPt as single, byval yPt as single, byref url as ustring, byref targetPage as long, byref targetY as single ) as boolean
function tkPrintDoc_GetOpCount( byval doc as TK_PRINTDOC ptr, byval page as long ) as long
function tkPrintDoc_GetOp( byval doc as TK_PRINTDOC ptr, byval page as long, byval i as long, byref info as TKPRINT_OPINFO ) as boolean
function tkPrint_PaintWidget( byval pg as TK_PAGE ptr, byval w as TK_WIDGET ptr, byref rc as TKRECTF ) as boolean
function tkPage_GetIndex( byval pg as TK_PAGE ptr ) as long
sub tkPage_GetSize( byval pg as TK_PAGE ptr, byref w as single, byref h as single )
sub tkPage_GetMarginRect( byval pg as TK_PAGE ptr, byref rc as TKRECTF )
sub tkPage_SetFillColor( byval pg as TK_PAGE ptr, byval c as ulong )
sub tkPage_SetLineColor( byval pg as TK_PAGE ptr, byval c as ulong )
sub tkPage_SetTextColor( byval pg as TK_PAGE ptr, byval c as ulong )
sub tkPage_SetPen( byval pg as TK_PAGE ptr, byval widthPt as single, byval nDash as long = TK_PENDASH_SOLID )
function tkPage_SetFont( byval pg as TK_PAGE ptr, byref fs as TKFONTSPEC ) as boolean
sub tkPage_FillRect( byval pg as TK_PAGE ptr, byref rc as TKRECTF )
sub tkPage_StrokeRect( byval pg as TK_PAGE ptr, byref rc as TKRECTF )
sub tkPage_FillRoundRect( byval pg as TK_PAGE ptr, byref rc as TKRECTF, byval radiusPt as single )
sub tkPage_StrokeRoundRect( byval pg as TK_PAGE ptr, byref rc as TKRECTF, byval radiusPt as single )
sub tkPage_FillEllipse( byval pg as TK_PAGE ptr, byref rc as TKRECTF )
sub tkPage_StrokeEllipse( byval pg as TK_PAGE ptr, byref rc as TKRECTF )
sub tkPage_Line( byval pg as TK_PAGE ptr, byval x1 as single, byval y1 as single, byval x2 as single, byval y2 as single )
sub tkPage_Polyline( byval pg as TK_PAGE ptr, byval pts as TKPOINTF ptr, byval n as long )
sub tkPage_Polygon( byval pg as TK_PAGE ptr, byval pts as TKPOINTF ptr, byval n as long, byval bStroke as boolean = false )
sub tkPage_Pie( byval pg as TK_PAGE ptr, byref rc as TKRECTF, byval startDeg as single, byval sweepDeg as single, byval bStroke as boolean = false )
sub tkPage_GradientRect( byval pg as TK_PAGE ptr, byref rc as TKRECTF, byval c1 as ulong, byval c2 as ulong, byval nMode as long = TK_GRADIENT_VERTICAL )
sub tkPage_PushClip( byval pg as TK_PAGE ptr, byref rc as TKRECTF )
sub tkPage_PopClip( byval pg as TK_PAGE ptr )
function tkPage_Text( byval pg as TK_PAGE ptr, byref s as ustring, byref rc as TKRECTF, byval flags as long = 0 ) as single
function tkPage_MeasureText( byval pg as TK_PAGE ptr, byref s as ustring ) as single
function tkPage_MeasureWrapped( byval pg as TK_PAGE ptr, byref s as ustring, byval widthPt as single ) as single
function tkPage_TextHeight( byval pg as TK_PAGE ptr ) as single
function tkPage_LineSkip( byval pg as TK_PAGE ptr ) as single
sub tkPage_LateText( byval pg as TK_PAGE ptr, byref rc as TKRECTF, byref fmt as ustring, byval flags as long = 0 )
function tkPage_ImageSurface( byval pg as TK_PAGE ptr, byval s as SDL_Surface ptr, byref rc as TKRECTF, byval nFit as long = TK_IMGFIT_ASPECT ) as boolean
function tkPage_Image( byval pg as TK_PAGE ptr, byref file as ustring, byref rc as TKRECTF, byval nFit as long = TK_IMGFIT_ASPECT ) as boolean
sub tkPage_Link( byval pg as TK_PAGE ptr, byref rc as TKRECTF, byref url as ustring )
sub tkPage_LinkToPage( byval pg as TK_PAGE ptr, byref rc as TKRECTF, byval page as long, byval yPt as single = 0 )
function tkPrintReplay_Create( byval r as SDL_Renderer ptr, byval engine as TTF_TextEngine ptr = 0 ) as TK_PRINTREPLAY ptr
sub tkPrintReplay_Flush( byval rp as TK_PRINTREPLAY ptr )
sub tkPrintReplay_Destroy( byval rp as TK_PRINTREPLAY ptr )
function tkPrintReplay_Page( byval rp as TK_PRINTREPLAY ptr, byval doc as TK_PRINTDOC ptr, byval page as long, byval x as single, byval y as single, byval pxPerPt as single, byval pClip as TKRECT ptr = 0 ) as boolean
function tkPrintDoc_RenderSurface( byval doc as TK_PRINTDOC ptr, byval page as long, byval dpi as single, byval bTransparent as boolean = false ) as SDL_Surface ptr
function tkPrintDoc_ExportPng( byval doc as TK_PRINTDOC ptr, byref pathPattern as ustring, byval dpi as single, byval first as long = 0, byval last as long = -1 ) as boolean
```

### See also

- [tkPrintPreview](tkPrintPreview) — shows the pages
- [tkPdf](tkPdf) — writes them as PDF
- [tkPaint](tkPaint) — the drawing it records
- [tkChart](tkChart)
- [tkControls](Category-tkControls)
