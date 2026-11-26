[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPdf**

# tkPdf

Writes a print document as a PDF file.

Every page becomes a PDF page as it was recorded: shapes as vector paths, text as real text in the embedded font (searchable and copyable), images, gradients, clips and links. No PDF library is linked; the writer, its compression and its font reader are part of the module.

## Importing

```freebasic
#import "vendor/tkControls/tkPdf"

using tkPdf
using tkPrint
using tkHost
using tkPaint
```

It imports [tkPrint](tkPrint) publicly.

## Example

```freebasic
dim as TK_PRINTDOC ptr doc = tkPrintDoc_Create( "Quarterly report" )
tkPrintDoc_SetPrintPageCallback( doc, @MyPage )
tkPrintDoc_Generate( doc )
if tkPrintDoc_ExportPdf( doc, "report.pdf" ) = false then print "could not write report.pdf"
print tkPrintDoc_Warnings( doc )                 ' anything drawn as an image instead of text
tkPrintDoc_Destroy( doc )
```

The toolchain's `examples/tkControls/tkPrint/demo --pdf report.pdf` writes a page with a [tkChart](tkChart), text and a table.

## What is written

- **Text.** Each font is embedded whole as a Type 0 font, with a `ToUnicode` map so text can be searched and copied. A run sits at the baseline and width it had on the page; the width is fitted with horizontal scaling (95–105%), so the PDF matches the preview. Synthetic bold and italic (a font file without that face) become stroked and slanted text.
- **Icons.** Characters in the Private Use Area (icon fonts such as Fluent UI System Icons) are drawn as filled outlines from the font's glyphs. The icon font itself is not embedded.
- **Text drawn as an image** (a warning says so):
  - scripts that need shaping (Arabic, Hebrew, Indic, Thai and others) are drawn at 300 dpi as SDL_ttf renders them;
  - so is text in a font that cannot be embedded: a CFF (`.otf`) font, a face of a `.ttc` collection, or a font whose licence restricts embedding.
- **Shapes.**
  - Fills, strokes, dashes and rects are vector paths, as tkPaint drew them.
  - Gradients are axial shadings; their colours' alpha is not kept.
  - Transparency uses graphics states.
- **Images** are RGB with a soft mask when any pixel is not opaque.
- **Links** are link annotations: a page destination (`tkPage_LinkToPage`) or a URI (`tkPage_Link`).
- Every stream is compressed (deflate) unless `bCompress` is FALSE. The document's title, and the options' author and subject, go into the file's information.

## Public declarations

### Types

```freebasic
type TKPDF_OPTIONS
    bCompress as boolean = true        ' FlateDecode every stream
    author    as ustring
    subject   as ustring
end type

type PDF_BUF                           ' a growing byte buffer: b(0 .. n - 1)
    b(any) as ubyte
    n      as integer
end type
```

### Procedures

```freebasic
function tkPrintDoc_ExportPdf( byval doc as TK_PRINTDOC ptr, byref path as ustring, byval pOpts as TKPDF_OPTIONS ptr = 0 ) as boolean
function tkPdf_Write( byval doc as TK_PRINTDOC ptr, byref outBuf as PDF_BUF, byval pOpts as TKPDF_OPTIONS ptr = 0 ) as boolean
sub tkPdf_Deflate( byval p as const ubyte ptr, byval n as integer, byref outBuf as PDF_BUF )
```

`tkPdf_Write` builds the file in memory. `tkPdf_Deflate` appends a zlib stream of n bytes to a buffer.

### See also

- [tkPrint](tkPrint)
- [tkPrintPreview](tkPrintPreview)
- [tkControls](Category-tkControls)
