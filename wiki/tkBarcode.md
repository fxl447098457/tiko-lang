[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkBarcode**

# tkBarcode

Draws 1D and 2D barcodes: EAN, UPC, Code 128, Code 39, QR, Data Matrix, PDF417, Aztec.

`tkBarcode` is the [tkControls](Category-tkControls) barcode. You give it a symbology and the data, and
it shows a symbol a scanner reads. The encoding is libzint's, from [`vendor/zint`](Vendor-Packages);
the drawing is the control's own:

- **On screen**, every module is a whole number of pixels, so there is no blur.
- **On paper and in PDF**, the module is a physical X-dimension in millimetres and every bar is a
  vector rectangle.
- **Quiet zones**, the white margins a scanner needs, are included.
- **The human-readable text** under the bars is drawn in the control's font.
- **Data the symbology refuses** puts the control in a visible error state.

Every setter is silent: a barcode has no user input that changes its data. The Form Designer's
**Barcode** binds its data, load only. A report draws barcodes through
[tkReportBarcode](#reports). Barcodes are tested on Windows, Linux (X11 and Wayland) and macOS.

## Importing

```freebasic
#import "vendor/tkControls/tkBarcode"

using tkBarcode
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint) and SDL3), [tkTheme](tkTheme),
[tkTooltip](tkTooltip), [tkPrint](tkPrint), [tkPdf](tkPdf) and `vendor/zint`. Its default link mode is
`dynamic`, which copies `zint.dll` (or the `.so` / `.dylib`) beside the program. Write
`#import "vendor/zint" link static` in the program to put libzint inside it instead.

## Example

```freebasic
dim as TK_WIDGET ptr sku = tkBarcode_Create( tkHost_Root( host ), 100, TKBC_EAN13 )
tkBarcode_SetData( sku, "590123412345" )           ' 12 digits: the check digit is added
tkWidget_SetPos( sku, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), tkHost_Scale( host, 240 ), tkHost_Scale( host, 120 ) )

dim as TK_WIDGET ptr url = tkBarcode_Create( tkHost_Root( host ), 101, TKBC_QR )
tkBarcode_SetData( url, "https://tiko-lang.net" )
tkBarcode_SetModuleWidth( url, 4 )                  ' 4 design units per module
tkWidget_SetPos( url, tkHost_Scale( host, 290 ), tkHost_Scale( host, 20 ), tkHost_Scale( host, 160 ), tkHost_Scale( host, 160 ) )

if tkBarcode_IsValid( sku ) = false then print tkBarcode_GetErrorText( sku )
tkBarcode_ExportPdf( sku, "sku.pdf" )               ' vector, at EAN's 0.33 mm module
```

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

## Symbologies

| Family | `TKBC_*` |
| --- | --- |
| Retail | `EAN13`, `EAN8`, `UPCA`, `UPCE`, `ISBN` |
| Industrial | `CODE128`, `GS1_128`, `CODE39`, `CODE39_EXT`, `CODE93`, `ITF`, `ITF14`, `CODABAR` |
| QR | `QR`, `MICRO_QR` |
| Other 2D | `DATAMATRIX`, `GS1_DATAMATRIX`, `PDF417`, `PDF417_COMPACT`, `AZTEC` |

`tkBarcode_Create( parent, id, symbology )` picks one, and `tkBarcode_SetSymbology` changes it.
`tkBarcode_SetZintSymbology( h, id )` reaches any other symbology libzint has (MaxiCode, DotCode, GS1
DataBar, postal codes) by its `BARCODE_*` number.

**Data** is text (`tkBarcode_SetData`), sent to libzint as UTF-8.
- **EAN and UPC:** short data is padded with leading zeros, the check digit is added, and a check
  digit you give is verified. `+12` or `+51234` after the digits adds a 2- or 5-digit add-on.
- **GS1 symbologies** take `[01]09501101530003[17]140704` or `(01)…`.
- **Code 39** reads lower case as upper case.
- **Options**, each a named setter; 0 is always libzint's default:

| Setter | For | Value |
| --- | --- | --- |
| `SetEccLevel` | QR, Micro QR, PDF417, Aztec | QR 1–4 = L M Q H; PDF417 1–9 = level 0–8 |
| `SetSymbolSize` | QR (version), Data Matrix, Aztec, PDF417 (columns) | 0 = automatic |
| `SetMask` | QR, Micro QR | 1–8 = mask 0–7 |
| `SetSquareOnly` | Data Matrix | square sizes only |
| `SetCheckDigit` | Code 39, ITF, Codabar | add the optional check character |
| `SetGs1` | Code 128, Data Matrix, QR | the data is GS1 |
| `SetEscapes`, `SetEci` | all / 2D | `\d029`-style escapes; an ECI number |
| `SetBearer` | ITF, ITF-14 | `TKBC_BEARER_DEFAULT` (ITF-14: a box), `BOX`, `TOPBOTTOM`, `NONE` |

## Valid, invalid, empty

`tkBarcode_IsValid` is TRUE when a symbol is drawn. `tkBarcode_GetStatus` gives `TKBC_OK`, a warning
(`TKBC_WARN_ECI`: UTF-8 put into a QR code; the symbol still draws), or an error:

- `TKBC_ERR_INVALID_DATA`
- `TKBC_ERR_INVALID_CHECK`
- `TKBC_ERR_TOO_LONG`
- `TKBC_ERR_INVALID_OPTION`
- `TKBC_ERR_NONCOMPLIANT`: GS1 data with a wrong check digit, which libzint only warns about

An error draws a frame in the theme's Error colour with a short line ("Wrong check digit"). **It never
draws a symbol that would scan wrong.** The tooltip gives libzint's full message (also
`tkBarcode_GetErrorText`); `SetShowErrors( h, false )` draws only the background. Empty data is
`TKBC_EMPTY`: nothing is drawn, and nothing is wrong.

`tkBarcode_Validate( symbology, data, sErr )` checks data without a control.

## Look on screen

| Setting | What it does |
| --- | --- |
| `SetModuleWidth` | pixels per module, in design units (default 2), scaled to **whole** pixels |
| `SetFitMode` | `TKBC_FIT_NORMAL` (the module width, centred); `FIT` (smaller by whole pixels until it fits); `PROPORTIONAL` (the largest size that fits: whole pixels for 1D, fractional for 2D); `STRETCH` (fills the control; a small 1D code stretched this way may not scan) |
| `SetBarHeight` | 1D bar height in modules; 0 (default) fills the control's height |
| `SetQuietZone` | the symbology's quiet zones, on by default (EAN and UPC always keep theirs: their outer digits sit in them) |
| `SetTextMode` | `TKBC_TEXT_BELOW` (default), `ABOVE` (1D other than EAN/UPC), `NONE` |
| `SetCaption` | a text of your own instead of libzint's, centred; also under a 2D symbol |
| `SetRotation` | `TKBC_ROT_0`, `90`, `180`, `270`; the text is drawn at 0° only |
| `SetBorder`, `SetFont`, `SetTooltipText` | a 1-pixel frame; the text's font; a tooltip of your own |

**The symbol stays black on white whatever the theme**, because scanners need dark bars on a light
ground. `tkBarcode_SetColors` changes it anyway (and pins the colours against theme changes).
`tkBarcode_GetContrast` gives the WCAG contrast of the bars on the background; keep it above 3.

## Paper, PDF, PNG, SVG, clipboard

On paper a module is a size from the standard: `tkBarcode_SetXDimension( h, mm )` sets it, and 0
gives libzint's default for the symbology (EAN 0.33 mm, Code 128 0.495 mm, QR 0.625 mm).
`SetBarHeightMm` sets the height of a 1D code's bars.

| Call | Gives |
| --- | --- |
| `tkBarcode_PrintTo( h, page, rc [, dpi] [, align] )` | the symbol on a [tkPrint](tkPrint) page, in `rc` (points), at its physical size |
| `tkBarcode_ExportPdf( h, path )` | a PDF of the symbol alone; every bar an exact vector rectangle |
| `tkBarcode_ExportPng( h, path [, dpi] )` | a PNG (300 dpi by default), every module whole pixels |
| `tkBarcode_ExportSvg( h, path )` | SVG sized in mm, one `<rect>` per run of bars |
| `tkBarcode_CopyToClipboard( h [, dpi] )` | the image (PNG and BMP) and the data as text; needs a window open |

A **dpi** given to `PrintTo` snaps the module and the origin to that device's dots, so every bar is a
whole number of dots. Symbols also scan without it: on Windows a printed page is rasterised at the
printer's resolution, up to 600 dpi, with each bar's edges rounded to the dot grid.

## Data binding

In the [Form Designer](Form-Designer) a Barcode's **Bind** takes a field of the form's DataType:

- **LoadFrom** sets the data. **SaveTo** leaves the field alone, because the barcode is load only.
- **Any field type binds through its text**: an `int64` id becomes its digits. Keep an EAN with
  leading zeros in a text field.
- **A record whose data the symbology refuses** shows the error state, and loading it never fails.

A dropped Barcode starts with its own name as its data, a Code 128 the canvas can show.

## Reports

`vendor/tkControls/tkReportBarcode` puts barcodes in [tkReport](tkReport) bands:

```freebasic
#import "vendor/tkControls/tkReportBarcode"

tkReportBarcode_Install( )                          ' once, before a report runs
dim as TKBARCODE_SPEC ean
ean.nSymbology = TKBC_EAN13
tkRBand_AddBarcode( tkReport_GetBand( rpt, TKRB_DETAIL ), rc, tkReport_FindField( rpt, "sku" ), ean )
```

- Each row's field text is drawn at its physical size from the top of the item's rectangle, as a
  vector in PDF.
- A row the symbology refuses draws a thin red frame, and the report goes on.
- A program that never imports tkReportBarcode links no libzint: tkReport itself does not.

## Without a widget

```freebasic
dim as TKBARCODE_SPEC spec
spec.nSymbology = TKBC_QR
dim as TKBARCODE_SYMBOL sym
tkBarcode_Encode( spec, "hello", sym )               ' once
dim as TKBARCODE_LOOK look
look.nModulePx = 3
tkBarcode_PaintInto( b, rc, sym, spec, look )        ' in any paint callback (b: a TK_PAINT ptr)
```

`tkBarcode_PaintPage( page, rc, sym, spec, pagelook )` does the same on a page. `tkBarcode_Encode`
gives the symbol in module units: its rectangles, its module matrix (`tkBarcode_SymbolModule`) and
its text runs.
