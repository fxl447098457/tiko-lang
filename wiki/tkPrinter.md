[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPrinter**

# tkPrinter

Lists the printers and prints print documents on them.

- **Windows.** The printers, their papers, duplex and colour come from winspool; no import library is linked. A job is sent as images: each page is replayed by tkPrint at the printer's resolution (at most 600 dpi), in bands, and lined up with the paper's edge as in the preview. Copies and collation are done by tkPrinter.
- **Linux and macOS.** CUPS: the document is written as a PDF by [tkPdf](tkPdf) and submitted with its options. libcups is loaded at run time; without it the `lpstat` and `lp` commands are used.

## Importing

```freebasic
#import "vendor/tkControls/tkPrinter"

using tkPrinter
using tkPdf
using tkPrint
using tkHost
using tkPaint
```

## Example

```freebasic
dim as TKPRINTJOB job
job.printer = ""                         ' the default printer
job.copies = 2
job.pageSet = "1-3, 7"                   ' "" = every page
if tkPrintDoc_Print( doc, job ) = false then print "not printed: " & tkPrinter_LastError( )
```

Most programs let the user choose with [tkPrintDialog](tkPrintDialog), or use [tkReportViewer](tkReportViewer)'s Print button.

## Jobs

`TKPRINTJOB` holds:
- the printer (`""` = the default), copies and collation;
- the page set: `"1-3,7,10-"`, pages from 1, `10-` running to the end;
- two-sided printing (`TK_DUPLEX_NONE`, `_LONGEDGE`, `_SHORTEDGE`) and colour;
- the job's title;
- a progress callback that is told of each page and can cancel.

On Windows `outputFile` sends a print-to-file driver's output to a file without asking: "Microsoft Print to PDF" writes a PDF there. `devMode` keeps the driver's own settings from `tkPrinter_Properties`.

`tkPrintDoc_Print` is synchronous. It returns FALSE with a reason in `tkPrinter_LastError` when there is no printer, the page set names no page, the printer refuses the job, or the job is cancelled.

## Printers

- `tkPrinter_Enumerate( list() )` lists the printers: name, location, comment, and which is the default.
- `tkPrinter_GetDefault( )` returns the default printer's name.
- `tkPrinter_GetCaps( name, caps )` gives a printer's papers (in points, portrait), duplex and colour. On CUPS it reports the papers tkPrint knows, with duplex and colour assumed.
- `tkPrinter_Properties( owner, job )` shows the Windows driver's own settings dialog.
- `tkPrinter_ParsePageSet( spec, nPages, pages() )` expands a page set (FALSE for one that names no page).
- `tkPrinter_CupsOptions( doc, job )` returns the CUPS options a job becomes.

## Public declarations

```freebasic
enum
    TK_DUPLEX_NONE = 0
    TK_DUPLEX_LONGEDGE        ' turn pages like a book (portrait)
    TK_DUPLEX_SHORTEDGE       ' turn pages like a calendar
end enum

type TKPRINTERINFO
    name      as ustring
    location  as ustring
    comment   as ustring
    isDefault as boolean
end type

type TKPRINTERCAPS
    nPapers     as long
    paperName(any) as ustring
    paperW(any) as single           ' portrait, points
    paperH(any) as single
    bDuplex     as boolean
    bColor      as boolean
end type

type PRN_ProgressFunc as function( byval doc as TK_PRINTDOC ptr, byval nDone as long, byval nTotal as long, byval pCtx as any ptr ) as boolean

type TKPRINTJOB
    printer     as ustring          ' "" = the default printer
    copies      as long = 1
    collate     as boolean = true
    pageSet     as ustring          ' "1-3,7,10-" (pages from 1); "" = all
    duplex      as long = TK_DUPLEX_NONE
    color       as boolean = true
    title       as ustring          ' the job's name; "" = the document's title
    outputFile  as ustring          ' Windows: a print-to-file driver writes here, no prompt ("Microsoft Print to PDF")
    devMode     as string           ' Windows: the driver's settings from tkPrinter_Properties (opaque)
    pfnProgress as PRN_ProgressFunc
    pCtx        as any ptr
end type

function tkPrinter_LastError( ) as ustring
function tkPrinter_ParsePageSet( byref spec as ustring, byval nPages as long, pages() as long ) as long
function tkPrinter_CupsOptions( byval doc as TK_PRINTDOC ptr, byref job as TKPRINTJOB ) as string
function tkPrinter_Enumerate( list() as TKPRINTERINFO ) as long
function tkPrinter_GetDefault( ) as ustring
function tkPrinter_GetCaps( byref printer as ustring, byref caps as TKPRINTERCAPS ) as boolean
function tkPrinter_Properties( byval owner as TK_HOST ptr, byref job as TKPRINTJOB ) as boolean
function tkPrintDoc_Print( byval doc as TK_PRINTDOC ptr, byref job as TKPRINTJOB ) as boolean
```

### See also

- [tkPrintDialog](tkPrintDialog)
- [tkReportViewer](tkReportViewer)
- [tkPrint](tkPrint)
