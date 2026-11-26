[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPrintPreview**

# tkPrintPreview

Shows a print document's pages as paper, with zoom, columns and scrolling.

The preview lays the pages out in rows (one page per row by default, two for facing pages), scrolls them by the pixel, and zooms to fit the width, to fit a page, or to a custom factor. Pages are drawn by replaying the document, once per page and zoom, into a texture that is reused until the zoom or the document changes. A document still being made is finished by the preview itself, a few pages per tick, so the first pages show while the rest are made.

## Importing

```freebasic
#import "vendor/tkControls/tkPrintPreview"

using tkPrintPreview
using tkPrint
using tkHost
using tkPaint
```

It imports [tkPrint](tkPrint) publicly. Name `tkPrintPreview` before `tkPrint`, and `tkPrint` before `tkHost`.

## Example

```freebasic
dim shared as TK_PRINTDOC ptr gDoc

gDoc = tkPrintDoc_Create( "Report" )
tkPrintDoc_SetPrintPageCallback( gDoc, @MyPage )      ' a PR_PrintPageFunc, as in tkPrint
tkPrintDoc_BeginGenerate( gDoc )                      ' the preview makes the pages
dim as TK_WIDGET ptr pv = tkPrintPreview_Create( tkHost_Root( h ), 1 )
tkWidget_SetPos( pv, 0, 0, 600, 800 )
tkPrintPreview_SetDocument( pv, gDoc )
```

The document is borrowed: keep it until the preview is destroyed or shows another one. The toolchain's `examples/tkControls/tkPrintPreview/demo` shows a 24-page document with a contents page whose lines are links.

## Layout and zoom

- `tkPrintPreview_SetColumns( h, n )`: pages side by side in a row, 1 to 8. `2` gives facing pages.
- `tkPrintPreview_SetViewMode( h, mode )`: `TKPV_VIEW_CONTINUOUS` shows every row, one under the other. `TKPV_VIEW_SINGLE` shows one row at a time, and PgUp / PgDn turn it.
- `tkPrintPreview_SetZoomMode( h, mode )`: `TKPV_ZOOM_FITWIDTH` (the default) makes the widest row fill the view's width. `TKPV_ZOOM_FITPAGE` also fits the tallest page. `TKPV_ZOOM_CUSTOM` keeps the last zoom set.
- `tkPrintPreview_SetZoom( h, z )`: a custom zoom, 0.1 to 8. At 1 (100%) a point is 96/72 pixels at the surface's scale. `tkPrintPreview_GetZoom` returns the zoom in force, fitted or set.
- `tkPrintPreview_SetPage( h, n )`: brings page n's row to the top. `GetPage` returns the current page: the one a third of the way down the view.
- `tkPrintPreview_GetPageRect( h, n, rc )`: page n's rect in widget pixels, as drawn now.
- `tkPrintPreview_Refresh( h )`: call it after you generate the document again or change its page setup.

## Keyboard and mouse

| Input | Does |
|---|---|
| PgUp / PgDn | a view up or down; in the single view, the previous or next row |
| Home / End | the first / last page |
| arrows | scroll |
| `+` / `-` (and the keypad's) | zoom in or out by 1.25, about the view's centre |
| Ctrl+0 | fit width |
| wheel | scroll; Shift+wheel scrolls sideways; Ctrl+wheel zooms about the pointer |
| a link | the cursor is a hand over it; a click runs it |

A link made with `tkPage_LinkToPage` scrolls to its page; one made with `tkPage_Link` opens its URL. Set a `LinkClick` callback and return TRUE to handle a link yourself.

## Events

Setters are silent: only the user's scrolling, keys and clicks notify.

- `PageChanged( hPreview, nPage )`: the current page moved.
- `ZoomChanged( hPreview, fZoom )`: the user zoomed.
- `LinkClick( hPreview, nPage, url, nTargetPage, fTargetY ) as boolean`: TRUE = handled.

## Appearance

`TKPRINTPREVIEW_COLORS` holds four colours:
- `BackColor`: the backdrop; the theme's `Track`.
- `PaperColor`: white.
- `ShadowColor`.
- `PageBorderColor`: the theme's `Border`.

`SetColors` pins them; `UnpinColors` hands them back to the theme.

`tkPrintPreview_SetCacheSize( h, n )` sets how many page textures are kept (8). With 0, every frame replays the pages.

## Public declarations

### Constants

```freebasic
enum
    TKPV_ZOOM_CUSTOM = 0
    TKPV_ZOOM_FITWIDTH        ' the widest row fills the view's width (the default)
    TKPV_ZOOM_FITPAGE         ' the widest row and the tallest page fit the view
end enum

enum
    TKPV_VIEW_CONTINUOUS = 0  ' every row, one under the other
    TKPV_VIEW_SINGLE          ' one row at a time
end enum

const as long TKPV_DEFAULT_GAP = 12        ' between pages and around them
const as long TKPV_DEFAULT_SHADOW = 3
const as long TKPV_DEFAULT_CACHE = 8       ' page textures kept
const as single TKPV_ZOOM_MIN = 0.1
const as single TKPV_ZOOM_MAX = 8.0
```

### Types

```freebasic
type TKPRINTPREVIEW_COLORS
    BackColor       as ulong = &hFF3A3F47ul       ' the backdrop
    PaperColor      as ulong = &hFFFFFFFFul
    ShadowColor     as ulong = &h50000000ul
    PageBorderColor as ulong = &hFF5A606Aul
end type

type PV_PageChangedSub as sub( byval hPreview as TK_WIDGET ptr, byval nPage as long )
type PV_ZoomChangedSub as sub( byval hPreview as TK_WIDGET ptr, byval fZoom as single )
type PV_LinkClickFunc as function( byval hPreview as TK_WIDGET ptr, byval nPage as long, byref url as ustring, byval nTargetPage as long, byval fTargetY as single ) as boolean
```

### Procedures

```freebasic
function tkPrintPreview_ThemeColors( byref t as TKTHEME_COLORS ) as TKPRINTPREVIEW_COLORS
sub tkPrintPreview_ApplyTheme( byval hPreview as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
function tkPrintPreview_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkPrintPreview_GetID( byval hPreview as TK_WIDGET ptr ) as long
sub tkPrintPreview_SetDocument( byval hPreview as TK_WIDGET ptr, byval doc as TK_PRINTDOC ptr )
function tkPrintPreview_GetDocument( byval hPreview as TK_WIDGET ptr ) as TK_PRINTDOC ptr
sub tkPrintPreview_Refresh( byval hPreview as TK_WIDGET ptr )
function tkPrintPreview_GetPageCount( byval hPreview as TK_WIDGET ptr ) as long
function tkPrintPreview_GetPage( byval hPreview as TK_WIDGET ptr ) as long
sub tkPrintPreview_SetPage( byval hPreview as TK_WIDGET ptr, byval nPage as long )
function tkPrintPreview_GetZoom( byval hPreview as TK_WIDGET ptr ) as single
sub tkPrintPreview_SetZoom( byval hPreview as TK_WIDGET ptr, byval fZoom as single )
function tkPrintPreview_GetZoomMode( byval hPreview as TK_WIDGET ptr ) as long
sub tkPrintPreview_SetZoomMode( byval hPreview as TK_WIDGET ptr, byval nMode as long )
function tkPrintPreview_GetViewMode( byval hPreview as TK_WIDGET ptr ) as long
sub tkPrintPreview_SetViewMode( byval hPreview as TK_WIDGET ptr, byval nView as long )
function tkPrintPreview_GetColumns( byval hPreview as TK_WIDGET ptr ) as long
sub tkPrintPreview_SetColumns( byval hPreview as TK_WIDGET ptr, byval nCols as long )
function tkPrintPreview_GetPageRect( byval hPreview as TK_WIDGET ptr, byval nPage as long, byref rc as TKRECT ) as boolean
sub tkPrintPreview_GetScrollPos( byval hPreview as TK_WIDGET ptr, byref x as long, byref y as long )
sub tkPrintPreview_SetScrollPos( byval hPreview as TK_WIDGET ptr, byval x as long, byval y as long )
sub tkPrintPreview_SetCacheSize( byval hPreview as TK_WIDGET ptr, byval n as long )
function tkPrintPreview_GetCacheSize( byval hPreview as TK_WIDGET ptr ) as long
function tkPrintPreview_GetVScrollBar( byval hPreview as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkPrintPreview_GetHScrollBar( byval hPreview as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkPrintPreview_GetColors( byval hPreview as TK_WIDGET ptr, byval pColors as TKPRINTPREVIEW_COLORS ptr )
sub tkPrintPreview_SetColors( byval hPreview as TK_WIDGET ptr, byval pColors as TKPRINTPREVIEW_COLORS ptr )
sub tkPrintPreview_UnpinColors( byval hPreview as TK_WIDGET ptr )
sub tkPrintPreview_SetPageChangedCallback( byval hPreview as TK_WIDGET ptr, byval cb as PV_PageChangedSub )
sub tkPrintPreview_SetZoomChangedCallback( byval hPreview as TK_WIDGET ptr, byval cb as PV_ZoomChangedSub )
sub tkPrintPreview_SetLinkClickCallback( byval hPreview as TK_WIDGET ptr, byval cb as PV_LinkClickFunc )
```

In a designed form it is the `PrintPreview` control (category Other), with the properties ViewMode, Columns, Zoom, ZoomMode and CacheSize and the three events above.

### See also

- [tkPrint](tkPrint)
- [tkControls](Category-tkControls)
