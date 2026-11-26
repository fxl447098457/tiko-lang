[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkReportViewer**

# tkReportViewer

Shows a print document with a toolbar, a preview and a status bar.

- **Toolbar:**
  - **Print** runs [tkPrintDialog](tkPrintDialog), then prints with [tkPrinter](tkPrinter); the status bar counts the pages.
  - **Page setup** runs the Page Setup dialog and, for a document with a PrintPage callback, generates it again.
  - **PDF** asks where and writes the document with [tkPdf](tkPdf).
  - first / previous / a page box (type a number, Enter) / of N / next / last.
  - zoom out, a zoom list (fit width, fit page, 50–200%), zoom in.
- **Status bar:** "Page 3 of 12" (with "+" while pages are still being made), the zoom, and the last message or the document's warnings.

## Importing

```freebasic
#import "vendor/tkControls/tkReportViewer"

using tkReportViewer
using tkReport
using tkBind
using tkPrintPreview
using tkPrintDialog
using tkPrinter
using tkPdf
using tkPrint
using tkHost
using tkPaint
```

## Example

```freebasic
dim as TK_PRINTDOC ptr doc = tkPrintDoc_Create( "Orders" )
tkPrintDoc_SetPrintPageCallback( doc, @OrdersPage )
tkPrintDoc_BeginGenerate( doc )                      ' made while shown
dim as TK_WIDGET ptr rv = tkReportViewer_Create( tkHost_Root( h ), 1 )
tkWidget_SetPos( rv, 0, 0, 900, 700 )
tkReportViewer_SetDocument( rv, doc )
```

The toolchain's `examples/tkControls/tkReportViewer/demo` shows a 12-page document.

## Its own report

The viewer can hold a [tkReport](tkReport) of its own, over rows it is given: what a designed form binds to an array.

```freebasic
tkReportViewer_SetTitle( rv, "Orders" )
tkReportViewer_AddField( rv, "Customer", 160 )       ' a caption, and a width in pixels
tkReportViewer_AddField( rv, "Amount", 100 )
tkReportViewer_ClearRows( rv )
for i as long = 0 to orders.Count( ) - 1
    dim as integer r = tkReportViewer_AddRow( rv )
    tkBind_ToValue( orders[i].Customer, tkReportViewer_Cell( rv, r, 0 ) )
    tkBind_ToValue( orders[i].Amount, tkReportViewer_Cell( rv, r, 1 ) )
next
tkReportViewer_RefreshReport( rv )                   ' laid out on the preview
```

- `tkBind_ToValue( field, cell )` stores a field by its own type: integers as int, `single` / `double` as float, text, dates, times, booleans.
- A field's kind is the kind of its first non-empty value.
- The first `RefreshReport` makes the report's bands:
  - with a **BuildReport** callback, `BuildReport( h, rpt )` lays the report out with the [tkReport](tkReport) API. It finds fields with `tkReport_FindField`.
  - without one, the viewer makes a table:
    - the title, on page 1;
    - the captions, on every page;
    - a line per row: numbers right-aligned, floats as `#,##0.00`, booleans as check boxes;
    - "Page {p} of {n}".

    Columns wider than the page are scaled down to fit it.
- Later calls lay the same bands out again over the new rows.
- The viewer owns this report and its document. `GetReport` returns the report, for its page setup or its callbacks.

## API

- The document is borrowed: `SetDocument`, `GetDocument`, `Refresh` (after it changes outside the viewer), `SetPage`.
- `tkReportViewer_Print( h, bDialog = true )`, `tkReportViewer_PageSetup( h )` and `tkReportViewer_ExportPdf( h, path = "" )` do what the buttons do. With `bDialog = FALSE`, Print sends the job set by `SetJob` without asking.
- `SetShowToolbar` / `SetShowStatus` hide the bars; the preview takes their place.
- `GetPreview`, `GetToolbar`, `GetStatusBar`, `GetPageBox` and `GetZoomCombo` reach each part, to restyle or extend it.
- Events, on user action only:
  - `BeforePrint( h, job ) as boolean`: change the job, or return FALSE to stop it.
  - `AfterPrint( h, bOk )`.
  - `Exported( h, path, bOk )`.

In a designed form it is the `ReportViewer` control (category Other): properties Title, ShowToolbar and ShowStatus, and four events (BuildReport too). Its items are its report's fields: a caption, a width and a **Field** each. With an **ItemsSource** and an **ItemType**, the generated `<name>_Fill( )` fills the rows from an `Array( of T )` and calls `RefreshReport` (see [Form Designer](Form-Designer), Lists).

## Public declarations

```freebasic
enum
    TKRV_CMD_PRINT = 1
    TKRV_CMD_SETUP
    TKRV_CMD_PDF
    TKRV_CMD_FIRST
    TKRV_CMD_PREV
    TKRV_CMD_NEXT
    TKRV_CMD_LAST
    TKRV_CMD_ZOOMOUT
    TKRV_CMD_ZOOMIN
end enum

type RV_BeforePrintFunc as function( byval hViewer as TK_WIDGET ptr, byref job as TKPRINTJOB ) as boolean
type RV_AfterPrintSub as sub( byval hViewer as TK_WIDGET ptr, byval bOk as boolean )
type RV_ExportedSub as sub( byval hViewer as TK_WIDGET ptr, byref path as ustring, byval bOk as boolean )
type RV_BuildReportSub as sub( byval hViewer as TK_WIDGET ptr, byval rpt as TK_REPORT ptr )

function tkReportViewer_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkReportViewer_GetID( byval hViewer as TK_WIDGET ptr ) as long
sub tkReportViewer_SetDocument( byval hViewer as TK_WIDGET ptr, byval doc as TK_PRINTDOC ptr )
function tkReportViewer_GetDocument( byval hViewer as TK_WIDGET ptr ) as TK_PRINTDOC ptr
sub tkReportViewer_SetJob( byval hViewer as TK_WIDGET ptr, byref job as TKPRINTJOB )
function tkReportViewer_GetJob( byval hViewer as TK_WIDGET ptr ) as TKPRINTJOB
sub tkReportViewer_Refresh( byval hViewer as TK_WIDGET ptr )
sub tkReportViewer_SetPage( byval hViewer as TK_WIDGET ptr, byval nPage as long )
function tkReportViewer_Print( byval hViewer as TK_WIDGET ptr, byval bDialog as boolean = true ) as boolean
function tkReportViewer_PageSetup( byval hViewer as TK_WIDGET ptr ) as boolean
function tkReportViewer_ExportPdf( byval hViewer as TK_WIDGET ptr, byref path as ustring = "" ) as boolean
function tkReportViewer_GetShowToolbar( byval hViewer as TK_WIDGET ptr ) as boolean
sub tkReportViewer_SetShowToolbar( byval hViewer as TK_WIDGET ptr, byval bShow as boolean )
function tkReportViewer_GetShowStatus( byval hViewer as TK_WIDGET ptr ) as boolean
sub tkReportViewer_SetShowStatus( byval hViewer as TK_WIDGET ptr, byval bShow as boolean )
function tkReportViewer_GetPreview( byval hViewer as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkReportViewer_GetToolbar( byval hViewer as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkReportViewer_GetStatusBar( byval hViewer as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkReportViewer_GetPageBox( byval hViewer as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkReportViewer_GetZoomCombo( byval hViewer as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkReportViewer_SetBeforePrintCallback( byval hViewer as TK_WIDGET ptr, byval cb as RV_BeforePrintFunc )
sub tkReportViewer_SetAfterPrintCallback( byval hViewer as TK_WIDGET ptr, byval cb as RV_AfterPrintSub )
sub tkReportViewer_SetExportedCallback( byval hViewer as TK_WIDGET ptr, byval cb as RV_ExportedSub )
' its own report
sub tkReportViewer_SetBuildReportCallback( byval hViewer as TK_WIDGET ptr, byval cb as RV_BuildReportSub )
sub tkReportViewer_SetTitle( byval hViewer as TK_WIDGET ptr, byref title as const ustring )
function tkReportViewer_GetTitle( byval hViewer as TK_WIDGET ptr ) as ustring
function tkReportViewer_GetReport( byval hViewer as TK_WIDGET ptr ) as TK_REPORT ptr
function tkReportViewer_AddField( byval hViewer as TK_WIDGET ptr, byref caption as ustring, byval nWidth as long = 100 ) as long
function tkReportViewer_GetFieldCount( byval hViewer as TK_WIDGET ptr ) as long
sub tkReportViewer_ClearRows( byval hViewer as TK_WIDGET ptr )
function tkReportViewer_AddRow( byval hViewer as TK_WIDGET ptr ) as integer
function tkReportViewer_Cell( byval hViewer as TK_WIDGET ptr, byval row as integer, byval f as long ) as TK_VALUE ptr
function tkReportViewer_GetRowCount( byval hViewer as TK_WIDGET ptr ) as integer
sub tkReportViewer_RefreshReport( byval hViewer as TK_WIDGET ptr )
```

### See also

- [tkPrintPreview](tkPrintPreview)
- [tkReport](tkReport)
- [tkPrintDialog](tkPrintDialog)
- [tkPrinter](tkPrinter)

To draw a report instead of building it in code, see the [Report Designer](Report-Designer); the
[Orders Tutorial](Orders-Tutorial) shows designed reports in viewers on designed forms.
