[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPrintDialog**

# tkPrintDialog

Shows the Print and Page Setup dialogs, drawn the same on every system.

- **Print** offers:
  - the printer, with its location;
  - on Windows, the driver's own **Properties...**;
  - copies and collate;
  - the pages: all, the current page, or a range such as `1-3, 7, 10-`, checked against the document's page count;
  - two-sided printing, when the printer can;
  - colour.

  A range that names no page is refused, with the reason shown in the dialog.
- **Page Setup** offers the paper, the orientation and the margins (in millimetres, or in inches where Letter is the paper), with a drawing of the page and its printable area. Margins that leave less than an inch are refused.

## Importing

```freebasic
#import "vendor/tkControls/tkPrintDialog"

using tkPrintDialog
using tkPrinter
using tkPdf
using tkPrint
using tkHost
using tkPaint
```

## Example

```freebasic
dim as TKPAGESETUP ps = tkPrintDoc_GetPageSetup( doc )
if tkPageSetupDialog_Show( h, ps ) then
    tkPrintDoc_SetPageSetup( doc, ps )
    tkPrintDoc_Generate( doc )
end if
dim as TKPRINTJOB job
if tkPrintDialog_Show( h, doc, job, currentPage ) then tkPrintDoc_Print( doc, job )
```

`Show` is `Create` + `Run`. `Create` builds the dialog without showing it. `Collect` reads its controls into a job or page setup; it returns FALSE, and shows why, when they do not make one. `Run` is modal: it returns TRUE for Print / OK and destroys the dialog. Enter is Print / OK; Esc cancels. `tkPrintDialog_GetControl( dlg, TKPD_ID_* )` reaches each control.

The text is English. `tkPrintDialog_SetStrings` replaces it with a `TKPRINTDIALOG_STRINGS` (every caption, label and message).

## Public declarations

```freebasic
function tkPrintDialog_Create( byval owner as TK_HOST ptr, byval doc as TK_PRINTDOC ptr, byref job as TKPRINTJOB, byval currentPage as long = -1 ) as TK_HOST ptr
function tkPrintDialog_Collect( byval dlg as TK_HOST ptr, byref job as TKPRINTJOB ) as boolean
function tkPrintDialog_Run( byval dlg as TK_HOST ptr, byref job as TKPRINTJOB ) as boolean
function tkPrintDialog_Show( byval owner as TK_HOST ptr, byval doc as TK_PRINTDOC ptr, byref job as TKPRINTJOB, byval currentPage as long = -1 ) as boolean
function tkPageSetupDialog_Create( byval owner as TK_HOST ptr, byref ps as TKPAGESETUP ) as TK_HOST ptr
function tkPageSetupDialog_Collect( byval dlg as TK_HOST ptr, byref ps as TKPAGESETUP ) as boolean
function tkPageSetupDialog_Run( byval dlg as TK_HOST ptr, byref ps as TKPAGESETUP ) as boolean
function tkPageSetupDialog_Show( byval owner as TK_HOST ptr, byref ps as TKPAGESETUP ) as boolean
function tkPrintDialog_GetControl( byval dlg as TK_HOST ptr, byval id as long ) as TK_WIDGET ptr
sub tkPrintDialog_SetStrings( byref s as TKPRINTDIALOG_STRINGS )
function tkPrintDialog_GetStrings( ) as TKPRINTDIALOG_STRINGS
```

The control ids are `TKPD_ID_PRINTER`, `_PROPERTIES`, `_INFO`, `_COPIES`, `_COLLATE`, `_ALL`, `_CURRENT`, `_RANGE`, `_RANGETEXT`, `_DUPLEX`, `_COLOUR`, `_ERROR`, `_OK`, `_CANCEL`, `_PAPER`, `_PORTRAIT`, `_LANDSCAPE`, `_MARGIN_L` / `_T` / `_R` / `_B` and `_PREVIEW`.

### See also

- [tkPrinter](tkPrinter)
- [tkReportViewer](tkReportViewer)
