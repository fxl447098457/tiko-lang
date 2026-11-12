[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gdiplus](SysWin-GdiPlus) › **GDI+ fonts**

# GDI+ fonts
Creates GDI+ fonts and font families and lists the fonts installed or loaded from files.

<!-- scope: CGpFont -->
<!-- scope: CGpFontFamily -->
<!-- scope: CGpFontCollection -->
<!-- scope: CGpInstalledFontCollection -->
<!-- scope: CGpPrivateFontCollection -->

Creates GDI+ fonts and font families and lists the fonts installed or loaded from files.

Text in GDI+ is drawn by [CGpGraphics](CGpGraphics) `DrawString` with a **font**, a brush and,
optionally, a [string format](CGpStringFormat). Five classes cover fonts:

| Class | Wraps | Holds |
| --- | --- | --- |
| `CGpFont` | a GDI+ `Font` | one typeface at one size and style: what `DrawString` takes |
| `CGpFontFamily` | a GDI+ `FontFamily` | a typeface name such as Arial, with its design metrics |
| `CGpFontCollection` | a GDI+ `FontCollection` | the base of the two collections below; never created by itself |
| `CGpInstalledFontCollection` | the installed font collection | every font installed on the computer |
| `CGpPrivateFontCollection` | a private font collection | fonts your program loads from files or memory |

**Sizes and units.** A font's size is its *em size* in the font's unit. The constructors
default to `UnitWorld` (0), which is a pixel until the [CGpGraphics](CGpGraphics) has a world
or page transformation, so `CGpFont( "Segoe UI", 12 )` is 12 pixels high at any DPI. Pass
`UnitPoint` for a size in points that GDI+ converts with the device's resolution; see the
`Unit` values in [GDI+ procedures and types](SysWin-GdiPlus-Procedures#types). Design metrics
(em height, ascent, descent, line spacing) are in **design units**, the font's own grid,
typically 2048 to the em.

**Styles.** `FontStyleRegular` (0), `FontStyleBold` (1), `FontStyleItalic` (2),
`FontStyleBoldItalic` (3), `FontStyleUnderline` (4) and `FontStyleStrikeout` (8), combined with
`or`.

**Lifetime.** Each object deletes its GDI+ object in its destructor. Never copy one by value (no
`=` from another object, no `byval` parameter): both copies would delete the same GDI+ object.
Copy with the pointer constructor (`dim b as CGpFont = @a`) or `Clone`, and pass fonts to
procedures by pointer. A private collection must outlive every font and family made from it.

**Status.** Methods that do something return a `GpStatus`: `Ok` (0) on success, otherwise the
reason, such as `InvalidParameter` (2) or `FontFamilyNotFound` (14). The status is also stored,
getters store theirs, and `GetLastStatus()`, inherited from
[CGpBase](SysWin-GdiPlus-Procedures#cgpbase), returns it. A constructor's outcome is only
reported there. Pointers to fonts, families and collections are not checked for `NULL` unless an
entry says so.

In the signatures `CGpFontFamily_`, `CGpFontCollection_` and `CGpGraphics_` are other names for
`CGpFontFamily`, `CGpFontCollection` and [CGpGraphics](CGpGraphics).

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus
```

## Example

A window that writes one line in each of the three generic families, sized from each family's
line spacing, and shows in its caption how many font families are installed:

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim token as ULONG_PTR = gdiplus.Init()
    dim pWindow as CWindow = "GpFontsDemo"
    dim hWin as HWND = pWindow.Create( NULL, "GDI+ fonts", @WndProc )
    pWindow.SetClientSize( 420, 150 )
    pWindow.Center
    scope
        dim installed as CGpInstalledFontCollection
        SetWindowText( hWin, "GDI+ fonts: " & installed.GetFamilyCount() & " families installed" )
    end scope
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
                dim g as CGpGraphics = hdc
                g.ScaleTransformForDpi()
                g.SetTextRenderingHint( TextRenderingHintAntiAlias )
                g.Clear( ARGB_White )
                dim ink as CGpSolidBrush = CGpSolidBrush( ARGB_Black )
                dim fam(0 to 2) as CGpFontFamily
                fam(0).GenericSansSerif( @fam(0) )
                fam(1).GenericSerif( @fam(1) )
                fam(2).GenericMonospace( @fam(2) )
                dim y as single = 15
                for each byref f in fam
                    dim wszName as wstring * LF_FACESIZE
                    f.GetFamilyName( @wszName )
                    dim fnt as CGpFont = CGpFont( @f, 24, FontStyleRegular, UnitPixel )
                    g.DrawString( @wszName, -1, @fnt, 20.0!, y, @ink )
                    ' line spacing in pixels = em size * line spacing / em height
                    y += 24 * f.GetLineSpacing( FontStyleRegular ) / f.GetEmHeight( FontStyleRegular )
                next
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

On a typical system the three lines read Microsoft Sans Serif, Times New Roman and Courier New.

## Members

| Member | Does |
| --- | --- |
| **CGpFont** | |
| [Constructor](#constructor) | Creates a font from a family name, a family, a logical font or a device context. |
| [Destructor](#destructor) | Deletes the GDI+ font. |
| [GetLogFontA, GetLogFontW](#getlogfonta-getlogfontw) | Fill a `LOGFONTA` or `LOGFONTW` with this font's attributes. |
| [Clone](#clone) | Copies this font into another `CGpFont`. |
| [IsAvailable](#isavailable) | Tells whether the font was created. |
| [GetFamily](#getfamily) | Gets the font's family. |
| [GetStyle](#getstyle) | Returns the style flags. |
| [GetSize](#getsize) | Returns the em size, in the font's unit. |
| [GetUnit](#getunit) | Returns the font's unit. |
| [GetHeight](#getheight) | Returns the line spacing for a graphics object or a resolution. |
| **CGpFontFamily** | |
| [Constructor](#constructor-1) | Creates a family from a name, optionally in a collection. |
| [Destructor](#destructor-1) | Deletes the GDI+ font family. |
| [Clone](#clone-1) | Copies this family into another `CGpFontFamily`. |
| [GenericSansSerif, GenericSerif, GenericMonospace](#genericsansserif-genericserif-genericmonospace) | Put a generic family into a `CGpFontFamily`. |
| [GetFamilyName](#getfamilyname) | Copies the family's name into a buffer. |
| [IsAvailable](#isavailable-1) | Tells whether the family was created. |
| [IsStyleAvailable](#isstyleavailable) | Tells whether the family has a style. |
| [GetEmHeight](#getemheight) | Returns the em height in design units. |
| [GetCellAscent](#getcellascent) | Returns the ascent in design units. |
| [GetCellDescent](#getcelldescent) | Returns the descent in design units. |
| [GetLineSpacing](#getlinespacing) | Returns the line spacing in design units. |
| **CGpFontCollection** | |
| [Constructor, Destructor](#constructor-destructor) | The base of the two collections; holds nothing by itself. |
| [GetFamilyCount](#getfamilycount) | Returns how many families the collection holds. |
| [GetFamilies](#getfamilies) | Copies the collection's families into an array. |
| **CGpInstalledFontCollection** | |
| [Constructor, Destructor](#constructor-destructor-1) | Opens the collection of installed fonts. |
| **CGpPrivateFontCollection** | |
| [Constructor, Destructor](#constructor-destructor-2) | Creates an empty private collection and deletes it. |
| [AddFontFile](#addfontfile) | Adds the fonts in a font file. |
| [AddMemoryFont](#addmemoryfont) | Adds a font held in memory. |

## Reference

## CGpFont

### Constructor

```freebasic
constructor
constructor( byval pFont as CGpFont ptr )
constructor( byval hdc as HDC )
constructor( byval hdc as HDC, byval hFont as HFONT )
constructor( byval hdc as HDC, byval plogfont as LOGFONTW ptr )
constructor( byval hdc as HDC, byval plogfont as LOGFONTA ptr )
constructor( byval pFamily as CGpFontFamily_ ptr, byval emSize as single, byval nStyle as INT_ = 0, byval nUnit as GpUnit = 0 )
constructor( byval pwszFamilyName as wstring ptr, byval emSize as single, byval nStyle as INT_ = 0, byval nUnit as GpUnit = 0, byval pFontCollection as CGpFontCollection_ ptr = NULL )
```

Creates the GDI+ font:

- **No argument**: an empty object that holds no font until [Clone](#clone) fills it.
- **`pFont`**: an independent copy of another font. The pointer must not be `NULL`.
- **`hdc`**: the GDI font selected into the device context. GDI+ only takes TrueType and
  OpenType fonts: the default font of a fresh DC is not one, and the status is then
  `NotTrueTypeFont` (16).
- **`hdc, plogfont`**: a font made from a GDI logical font, `LOGFONTW` or `LOGFONTA`; with a
  `NULL` pointer the font selected into `hdc` is used instead. The size comes out in
  `UnitWorld`, in pixels.
- **`pFamily, emSize …`**: a font of a [family](#cgpfontfamily); a `NULL` family fails.
- **`pwszFamilyName, emSize …`**: a font of the family with that name, looked up in
  `pFontCollection` or, when it is `NULL`, among the installed fonts. **When no family of that
  name exists the font falls back to the generic sans-serif family** (Microsoft Sans Serif) and
  the status is still `Ok`; call [GetFamily](#getfamily) to see which family you got.

The `hdc, hFont` form is declared but has no implementation in the module: a program that uses
it compiles but does not link. Get the font's `LOGFONTW` with `GetObjectW` and use the
`LOGFONTW` form instead.

`nStyle` and `nUnit` default to 0: `FontStyleRegular` and `UnitWorld`.

| Parameter | Meaning |
| --- | --- |
| `pFont` | The font to copy. |
| `hdc` | A device context. |
| `plogfont` | The logical font, or `NULL` for the font selected into `hdc`. |
| `pFamily` | The font family. |
| `pwszFamilyName` | The family name, such as `"Segoe UI"`. |
| `emSize` | The em size, in `nUnit`. |
| `nStyle` | `FontStyle*` flags. |
| `nUnit` | A `Unit` value: `UnitWorld` (0, the default), `UnitPixel`, `UnitPoint`, `UnitInch` … |
| `pFontCollection` | A collection to look the name up in, or `NULL` for the installed fonts. |

**Example**

```freebasic
dim title as CGpFont = CGpFont( "Segoe UI", 18, FontStyleBold, UnitPoint )
dim body as CGpFont = CGpFont( "Segoe UI", 14 )             ' 14 pixels
dim lf as LOGFONTW
GetObjectW( GetStockObject( DEFAULT_GUI_FONT ), sizeof( lf ), @lf )
dim gui as CGpFont = CGpFont( GetDC( hwnd ), @lf )
```

Microsoft Learn: [Font::Font](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-font%28inconstwchar_inreal_inint_inunit_inconstfontcollection%29)

### Destructor

```freebasic
destructor
```

Deletes the GDI+ font, if the object holds one.

**Example**

```freebasic
dim pFont as CGpFont ptr = new CGpFont( "Arial", 12 )
delete pFont
```

### GetLogFontA, GetLogFontW

```freebasic
function GetLogFontA( byval pGraphics as CGpGraphics_ ptr, byval pfA as LOGFONTA ptr ) as GpStatus
function GetLogFontW( byval pGraphics as CGpGraphics_ ptr, byval pfW as LOGFONTW ptr ) as GpStatus
```

Fills a GDI logical font with this font's face name, height, weight, italic, underline and
strikeout, so that you can create the matching GDI font with `CreateFontIndirectW`. The height is
worked out for the graphics object's resolution and comes out negative (a character height), as
GDI expects.

A graphics object is required: with `NULL` the call fails with `InvalidParameter`.

| Parameter | Meaning |
| --- | --- |
| `pGraphics` | The graphics object whose resolution is used. |
| `pfA`, `pfW` | The structure to fill. |

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim g as CGpGraphics = hwnd
dim f as CGpFont = CGpFont( "Arial", 10, FontStyleBold, UnitPoint )
dim lf as LOGFONTW
if f.GetLogFontW( @g, @lf ) = Ok then print lf.lfHeight; lf.lfWeight   ' -13 700 at 96 DPI
```

Microsoft Learn: [Font::GetLogFontW](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-getlogfontw)

### Clone

```freebasic
function Clone( byval pFont as CGpFont ptr ) as GpStatus
```

Copies this font into the existing `CGpFont` that `pFont` points to; the font that object held
is deleted first.

**Returns** `Ok` on success; `InvalidParameter` when `pFont` is `NULL`.

**Example**

```freebasic
dim a as CGpFont = CGpFont( "Arial", 12 )
dim b as CGpFont
if a.Clone( @b ) = Ok then print b.GetSize()   ' 12
```

Microsoft Learn: [Font::Clone](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-clone)

### IsAvailable

```freebasic
function IsAvailable() as boolean
```

Returns `true` when the object holds a GDI+ font, `false` when its construction failed or it was
made with no arguments.

**Example**

```freebasic
dim f as CGpFont = CGpFont( GetDC( hwnd ) )
if f.IsAvailable() = false then print "status"; f.GetLastStatus()
```

Microsoft Learn: [Font::IsAvailable](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-isavailable)

### GetFamily

```freebasic
function GetFamily( byval pFamily as CGpFontFamily_ ptr ) as GpStatus
```

Puts the family this font is based on into the `CGpFontFamily` that `pFamily` points to. A
family the target held before is not deleted, so pass an empty one.

**Returns** `Ok` on success; `InvalidParameter` when `pFamily` is `NULL`.

**Example**

```freebasic
dim f as CGpFont = CGpFont( "NoSuchFont", 12 )
dim fam as CGpFontFamily
dim wszName as wstring * LF_FACESIZE
if f.GetFamily( @fam ) = Ok andalso fam.GetFamilyName( @wszName ) = Ok then print str( wszName )   ' Microsoft Sans Serif
```

Microsoft Learn: [Font::GetFamily](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-getfamily)

### GetStyle

```freebasic
function GetStyle() as INT_
```

Returns the font's `FontStyle*` flags.

**Example**

```freebasic
dim f as CGpFont = CGpFont( "Arial", 10, FontStyleBold or FontStyleItalic )
if f.GetStyle() and FontStyleItalic then print "italic"
```

Microsoft Learn: [Font::GetStyle](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-getstyle)

### GetSize

```freebasic
function GetSize() as single
```

Returns the em size, in the font's own unit (see [GetUnit](#getunit)).

**Example**

```freebasic
dim f as CGpFont = CGpFont( "Arial", 10.5, FontStyleRegular, UnitPoint )
print f.GetSize()   ' 10.5
```

Microsoft Learn: [Font::GetSize](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-getsize)

### GetUnit

```freebasic
function GetUnit() as GpUnit
```

Returns the font's unit: a `Unit` value such as `UnitWorld` (0), `UnitPixel` (2) or `UnitPoint`
(3).

**Example**

```freebasic
dim f as CGpFont = CGpFont( "Arial", 12 )
print f.GetUnit()   ' 0: UnitWorld
```

Microsoft Learn: [Font::GetUnit](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-getunit)

### GetHeight

```freebasic
function GetHeight( byval pGraphics as CGpGraphics_ ptr ) as single
function GetHeight( byval dpi as single ) as single
```

Returns the font's **line spacing**: the distance from one baseline to the next, which is the
character height plus the space between lines.

- With a graphics object the value is in that object's page unit, worked out with its
  resolution.
- With `dpi` the value is in pixels for a device of that resolution. A font in `UnitPixel` or
  `UnitWorld` gives the same value at every resolution; one in points or inches grows with it.

| Parameter | Meaning |
| --- | --- |
| `pGraphics` | The graphics object to measure for. |
| `dpi` | A vertical resolution, in dots per inch. |

**Returns** the line spacing; 0 on failure (see `GetLastStatus()`).

**Example**

```freebasic
dim f as CGpFont = CGpFont( "Arial", 10, FontStyleRegular, UnitPoint )
print f.GetHeight( 96.0! ); f.GetHeight( 144.0! )   ' about 15.3 and 23
```

Microsoft Learn: [Font::GetHeight](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-font-getheight%28real%29)

## CGpFontFamily

### Constructor

```freebasic
constructor
constructor( byval pFontFamily as CGpFontFamily ptr )
constructor( byval pwszName as wstring ptr, byval pFontCollection as CGpFontCollection_ ptr = NULL )
```

Creates the GDI+ font family:

- **No argument**: an empty object, to be filled by [Clone](#clone-1), a generic family or
  [CGpFont.GetFamily](#getfamily).
- **`pFontFamily`**: an independent copy of another family. The pointer must not be `NULL`.
- **`pwszName`**: the family with that name in `pFontCollection`, or among the installed fonts
  when it is `NULL`. An unknown name leaves the object empty with the status
  `FontFamilyNotFound` (14).

| Parameter | Meaning |
| --- | --- |
| `pFontFamily` | The family to copy. |
| `pwszName` | The family name. |
| `pFontCollection` | The collection to look in, or `NULL` for the installed fonts. |

**Example**

```freebasic
dim arial as CGpFontFamily = CGpFontFamily( "Arial" )
dim nope as CGpFontFamily = CGpFontFamily( "NoSuchFont" )
print arial.IsAvailable(); nope.GetLastStatus()   ' true 14
```

Microsoft Learn: [FontFamily::FontFamily](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-fontfamily%28constwchar_constfontcollection%29)

### Destructor

```freebasic
destructor
```

Deletes the GDI+ font family, if the object holds one. Fonts already made from it keep working.

**Example**

```freebasic
dim pFam as CGpFontFamily ptr = new CGpFontFamily( "Arial" )
delete pFam
```

### Clone

```freebasic
function Clone( byval pFontFamily as CGpFontFamily ptr ) as GpStatus
```

Copies this family into the existing `CGpFontFamily` that `pFontFamily` points to; the family
that object held is deleted first.

**Returns** `Ok` on success; `InvalidParameter` when the pointer is `NULL`.

**Example**

```freebasic
dim a as CGpFontFamily = CGpFontFamily( "Arial" )
dim b as CGpFontFamily
print a.Clone( @b )   ' 0
```

Microsoft Learn: [FontFamily::Clone](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-clone)

### GenericSansSerif, GenericSerif, GenericMonospace

```freebasic
function GenericSansSerif( byval pFontFamily as CGpFontFamily ptr ) as GpStatus
function GenericSerif( byval pFontFamily as CGpFontFamily ptr ) as GpStatus
function GenericMonospace( byval pFontFamily as CGpFontFamily ptr ) as GpStatus
```

Put the generic sans-serif, serif or monospace family into the `CGpFontFamily` that
`pFontFamily` points to, deleting the family it held first. On a typical system they are
Microsoft Sans Serif, Times New Roman and Courier New.

The object the method is called on is not changed, except that the outcome is stored as **its**
status, not the target's; you can call it on the target itself, as in the example. Apart from a
`NULL` pointer (`InvalidParameter`), the methods **return 0 whatever happens**: read the outcome
with `GetLastStatus()` on the object you called.

**Returns** `InvalidParameter` when the pointer is `NULL`, otherwise 0.

**Example**

```freebasic
dim mono as CGpFontFamily
mono.GenericMonospace( @mono )
if mono.GetLastStatus() = Ok then print mono.IsAvailable()   ' true
```

Microsoft Learn: [FontFamily::GenericSansSerif](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-genericsansserif)

### GetFamilyName

```freebasic
function GetFamilyName( byval pwszName as wstring ptr, byval language as LANGID = LANG_NEUTRAL ) as GpStatus
```

Copies the family's name, in `language`, into a buffer of at least `LF_FACESIZE` (32) wide
characters.

| Parameter | Meaning |
| --- | --- |
| `pwszName` | The buffer that receives the name. |
| `language` | The language of the name; `LANG_NEUTRAL` (the default) for the user's language. |

**Returns** `Ok` on success; `InvalidParameter` when `pwszName` is `NULL`.

**Example**

```freebasic
dim fam as CGpFontFamily = CGpFontFamily( "Arial" )
dim wszName as wstring * LF_FACESIZE
if fam.GetFamilyName( @wszName ) = Ok then print str( wszName )   ' Arial
```

Microsoft Learn: [FontFamily::GetFamilyName](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-getfamilyname)

### IsAvailable

```freebasic
function IsAvailable() as boolean
```

Returns `true` when the object holds a GDI+ font family.

**Example**

```freebasic
dim fam as CGpFontFamily = CGpFontFamily( "Cascadia Code" )
if fam.IsAvailable() = false then print "not installed"
```

Microsoft Learn: [FontFamily::IsAvailable](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-isavailable)

### IsStyleAvailable

```freebasic
function IsStyleAvailable( byval nStyle as INT_ ) as boolean
```

Returns `true` when the family has the style given by `FontStyle*` flags. GDI+ can draw bold or
italic text for most families even when they have no such face, by synthesising it.

**Example**

```freebasic
dim fam as CGpFontFamily = CGpFontFamily( "Arial" )
print fam.IsStyleAvailable( FontStyleBold )   ' true
```

Microsoft Learn: [FontFamily::IsStyleAvailable](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-isstyleavailable)

### GetEmHeight

```freebasic
function GetEmHeight( byval nStyle as INT_ ) as UINT16
```

Returns the em height of the family's face for `nStyle`, in design units. Divide the other
metrics by it and multiply by a font's size to get them in the font's unit.

**Example**

```freebasic
dim fam as CGpFontFamily = CGpFontFamily( "Arial" )
print fam.GetEmHeight( FontStyleRegular )   ' 2048
```

Microsoft Learn: [FontFamily::GetEmHeight](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-getemheight)

### GetCellAscent

```freebasic
function GetCellAscent( byval nStyle as INT_ ) as UINT16
```

Returns the cell ascent, the distance from the baseline to the top of the tallest character
cell, in design units.

**Example**

```freebasic
dim fam as CGpFontFamily = CGpFontFamily( "Arial" )
print fam.GetCellAscent( FontStyleRegular )   ' 1854
```

Microsoft Learn: [FontFamily::GetCellAscent](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-getcellascent)

### GetCellDescent

```freebasic
function GetCellDescent( byval nStyle as INT_ ) as UINT16
```

Returns the cell descent, the distance from the baseline down to the bottom of the lowest
character cell, in design units.

**Example**

```freebasic
dim fam as CGpFontFamily = CGpFontFamily( "Arial" )
print fam.GetCellDescent( FontStyleRegular )   ' 434
```

Microsoft Learn: [FontFamily::GetCellDescent](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-getcelldescent)

### GetLineSpacing

```freebasic
function GetLineSpacing( byval nStyle as INT_ ) as UINT16
```

Returns the line spacing, from one baseline to the next, in design units.

**Example**

```freebasic
dim fam as CGpFontFamily = CGpFontFamily( "Arial" )
' line spacing of a 16-pixel Arial, in pixels: 16 * 2355 / 2048
print 16 * fam.GetLineSpacing( FontStyleRegular ) / fam.GetEmHeight( FontStyleRegular )
```

Microsoft Learn: [FontFamily::GetLineSpacing](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontfamily-getlinespacing)

## CGpFontCollection

### Constructor, Destructor

```freebasic
constructor
destructor
```

`CGpFontCollection` is the common base of
[CGpInstalledFontCollection](#cgpinstalledfontcollection) and
[CGpPrivateFontCollection](#cgpprivatefontcollection), so that a parameter can take either
(`pFontCollection` in the font and family constructors). Its own constructor and destructor do
nothing; one created by itself holds no collection.

**Example**

```freebasic
dim installed as CGpInstalledFontCollection
dim pColl as CGpFontCollection ptr = @installed
print pColl->GetFamilyCount(); " families"
```

Microsoft Learn: [FontCollection](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nl-gdiplusheaders-fontcollection)

### GetFamilyCount

```freebasic
function GetFamilyCount() as INT_
```

Returns how many font families the collection holds.

**Example**

```freebasic
dim installed as CGpInstalledFontCollection
print installed.GetFamilyCount(); " families installed"
```

Microsoft Learn: [FontCollection::GetFamilyCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontcollection-getfamilycount)

### GetFamilies

```freebasic
function GetFamilies( byval numSought as INT_, byval gpfamilies as CGpFontFamily ptr, byval numFound as INT_ ptr ) as GpStatus
```

Copies up to `numSought` of the collection's families into an array of `CGpFontFamily`, and the
number copied into `*numFound`. Each element receives its own copy; pass elements that are empty,
because a family an element held before is not deleted.

| Parameter | Meaning |
| --- | --- |
| `numSought` | How many families to get; at least 1. |
| `gpfamilies` | The first element of an array of at least `numSought` families. |
| `numFound` | Receives how many were copied. |

**Returns** `Ok` on success; `InvalidParameter` when `numSought` is 0 or less or a pointer is
`NULL`.

**Example**

```freebasic
dim installed as CGpInstalledFontCollection
dim fams(0 to 9) as CGpFontFamily
dim found as long
if installed.GetFamilies( 10, @fams(0), @found ) = Ok then print found   ' 10
```

Microsoft Learn: [FontCollection::GetFamilies](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-fontcollection-getfamilies)

## CGpInstalledFontCollection

### Constructor, Destructor

```freebasic
constructor
destructor
```

Opens the collection of fonts installed on the computer. The collection belongs to GDI+ and is
not deleted by the destructor. Fonts installed while the program runs may not appear in it.

**Example**

```freebasic
dim installed as CGpInstalledFontCollection
dim fam as CGpFontFamily = CGpFontFamily( "Consolas", @installed )
print fam.IsAvailable()
```

Microsoft Learn: [InstalledFontCollection](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nl-gdiplusheaders-installedfontcollection)

## CGpPrivateFontCollection

### Constructor, Destructor

```freebasic
constructor
destructor
```

Creates an empty private font collection, to which [AddFontFile](#addfontfile) and
[AddMemoryFont](#addmemoryfont) add fonts that are not installed. The destructor deletes the
collection: keep it alive as long as any font or family made from it is in use.

**Example**

```freebasic
dim pfc as CGpPrivateFontCollection
print pfc.GetFamilyCount()   ' 0
```

Microsoft Learn: [PrivateFontCollection](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nl-gdiplusheaders-privatefontcollection)

### AddFontFile

```freebasic
function AddFontFile( byval pwszFileName as wstring ptr ) as GpStatus
```

Adds the fonts in a font file (`.ttf`, `.otf`, `.ttc`) to the collection. Use the family name
stored in the file to make fonts from it, with the collection as the last argument.

**Returns** `Ok` on success; for a missing file `FileNotFound` (10).

**Example**

```freebasic
dim pfc as CGpPrivateFontCollection
if pfc.AddFontFile( "C:\Windows\Fonts\consola.ttf" ) = Ok then
    dim f as CGpFont = CGpFont( "Consolas", 11, FontStyleRegular, UnitPixel, @pfc )
end if
```

Microsoft Learn: [PrivateFontCollection::AddFontFile](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-privatefontcollection-addfontfile)

### AddMemoryFont

```freebasic
function AddMemoryFont( byval pMemory as any ptr, byval length as INT_ ) as GpStatus
```

Adds a font whose file image is in memory, such as one read from a file or a resource, to the
collection. The memory must stay valid while the collection is in use.

| Parameter | Meaning |
| --- | --- |
| `pMemory` | The first byte of the font file image. |
| `length` | Its size in bytes. |

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim hRes as HRSRC = FindResourceW( NULL, "MYFONT", cast( LPCWSTR, RT_RCDATA ) )
dim pfc as CGpPrivateFontCollection
if hRes then pfc.AddMemoryFont( LockResource( LoadResource( NULL, hRes ) ), SizeofResource( NULL, hRes ) )
```

Microsoft Learn: [PrivateFontCollection::AddMemoryFont](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nf-gdiplusheaders-privatefontcollection-addmemoryfont)

## See also

- [sys/win/gdiplus](SysWin-GdiPlus)
- [CGpGraphics](CGpGraphics) for `DrawString` and `MeasureString`
- [CGpStringFormat](CGpStringFormat) for alignment, wrapping and trimming of text
- [Fonts](SysWin-Fonts) for GDI fonts (`HFONT`) and the fonts Windows uses
