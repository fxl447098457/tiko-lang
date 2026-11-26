[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkReport**

# tkReport

Lays out banded reports over rows of data, with group headers, footers and totals.

A report has the bands every reporting tool shares:

| Band | Printed |
|---|---|
| Report Header | once, at the top of the first page (under the page header) |
| Page Header | at the top of every page |
| Group Header *n* | when group *n*'s key changes, outer groups first; again at the top of each page the group continues on when `repeatOnEveryPage` |
| Detail | once per row |
| Group Footer *n* | when the group ends, inner groups first, with the group's totals |
| Report Footer | once, after the last row |
| Page Footer | at the bottom of every page |

A band holds items placed in points from its top-left corner (the left margin):

- labels and fields;
- summaries: sum, count, average, min and max of a field over a group or the whole report;
- page info: `{p}` and `{n}` filled in when the page is drawn, plus `{date}`, `{time}` and `{title}`;
- lines, boxes, images, check boxes;
- custom items, drawn by a callback.

A band never splits across pages. A group header is never left alone at the bottom of a page. `pageBreakBefore` and `pageBreakAfter` force new pages, and a `canGrow` text item wraps and makes its band taller.

## Importing

```freebasic
#import "vendor/tkControls/tkReport"

using tkReport
using tkBind
using tkPrint
using tkHost
using tkPaint
```

## Example

```freebasic
sub GetOrder( byval rpt as TK_REPORT ptr, byval row as integer, byval f as long, byref v as TK_VALUE )
    select case f
    case 0 : v.SetText( gOrders(row).region )
    case 1 : v.SetText( gOrders(row).customer )
    case 2 : v.SetFloat( gOrders(row).amount )
    end select
end sub

dim as TK_REPORT ptr rpt = tkReport_Create( "Orders" )
dim as ustring names(0 to 2) = { "Region", "Customer", "Amount" }
dim as long kinds(0 to 2) = { TKV_TEXT, TKV_TEXT, TKV_FLOAT }
tkReport_SetFields( rpt, names(), kinds() )
tkReport_SetRowCount( rpt, nOrders )
tkReport_SetGetValueCallback( rpt, @GetOrder )
tkReport_AddGroup( rpt, 0 )                                   ' by region: rows come sorted by it

dim as TKRECTF rc
dim as TK_RBAND ptr b = tkReport_GetBand( rpt, TKRB_GROUP_HEADER, 0 )
tkRectF_Set( rc, 0, 0, 300, 20 ) : tkRBand_AddField( b, rc, 0 )
b = tkReport_GetBand( rpt, TKRB_DETAIL )
tkRBand_SetHeight( b, 16 )
tkRectF_Set( rc, 10, 0, 250, 16 ) : tkRBand_AddField( b, rc, 1 )
tkRectF_Set( rc, 250, 0, 340, 16 ) : tkRBand_AddField( b, rc, 2, "$#,##0.00", TK_DT_RIGHT )
b = tkReport_GetBand( rpt, TKRB_GROUP_FOOTER, 0 )
tkRectF_Set( rc, 250, 0, 340, 20 ) : tkRBand_AddSummary( b, rc, 2, TKRS_SUM, 0, "$#,##0.00" )
b = tkReport_GetBand( rpt, TKRB_PAGE_FOOTER )
tkRectF_Set( rc, 0, 0, 480, 16 ) : tkRBand_AddPageInfo( b, rc )   ' "Page {p} of {n}"

dim as TK_PRINTDOC ptr doc = tkReport_CreateDoc( rpt )
tkPrintDoc_BeginGenerate( doc )
tkReportViewer_SetDocument( viewer, doc )                     ' shown while it is laid out
```

The toolchain's `examples/tkControls/tkReport/demo` is an orders report grouped by region, in a [tkReportViewer](tkReportViewer).

## Data

A report reads rows once, forward, through a `TKREPORT_SOURCE`: the field names and kinds, then `MoveNext` and `GetValue` for each row. Values are tkBind's `TK_VALUE`: text, int, float, bool, date, time, or empty. **The report does not sort: rows must arrive in the order of its groups.**

- **Callbacks:** `tkReport_SetFields( names(), kinds() )`, `SetRowCount`, `SetGetValueCallback`.
- **A tkListTree:** `tkReport_SourceFromListTree( rpt, hList )`. Its column captions are the field names and its rows the rows, as text.
- **A table it holds:** `tkReport_TableAddField( rpt, name )` per field, then `TableAddRow` and `TableCell( rpt, row, f )` to set each value (a `TK_VALUE ptr`, good until the next AddRow). `TableClear` empties the rows. A field's kind is its first non-empty value's. A [tkReportViewer](tkReportViewer)'s own report is one.
- **An SQLite query:** `tkReportSqlite_Open( rpt, db, "select ... order by ..." )` in the `tkReportSqlite` module. A field's kind comes from the column's declared type, and a NULL is empty. Close it with `tkReportSqlite_Close` before the database. A value that comes from outside the program goes in as a **parameter**, never pasted into the SQL: `tkReportSqlite_OpenEx( rpt, db, "select ... where region = ? order by ...", params() )`, a `TK_VALUE` per parameter, `params(0)` being parameter 1. It must hold exactly as many as the query has, or the report is not opened (`Open` is `OpenEx` with none, so it refuses a query that has parameters).
- **Any other source:** fill a `TKREPORT_SOURCE` and call `tkReport_SetSource`.

## Running

`tkReport_CreateDoc( rpt )` makes a document whose pages are the report, laid out a page at a time when shown, generated or printed. `tkReport_Run( rpt )` also generates every page at once. Laying out again (after a page setup change) rewinds the source. The report must outlive its documents.

`tkReport_FormatValue( v, fmt )` formats a value:
- numbers by a mask with literal text around it: `"$#,##0.00"`, `"0.0%"`, `"#,##0 kg"`;
- dates as `"dd/mm/yyyy"` (any order of `yyyy`, `mm`, `dd`);
- times as `"hh:nn:ss"`;
- booleans as `"Yes|No"`.

`BeforePrint( rpt, band, row ) as boolean` can skip a band for one row. `PaintItem` draws custom items.

## The table printer

`tkTablePrint_FromListTree( hList, opts )` snapshots a list as the user sees it: column captions and widths, the rows' text and tree levels, or only the selected rows. `tkTablePrint_CreateDoc` lays the snapshot out:

- a title and subtitle on the first page;
- the column headers on every page;
- alternate row shading and grid lines;
- "Page {p} of {n}";
- a column whose values all read as numbers, right-aligned.

When the table is too wide for the page:
- **`TKTP_FIT_SHRINK`** (the default) scales it down to fit, but not below `minScale` (60%). Past that, columns go on further pages, down then across, with the first column repeated on each.
- **`TKTP_FIT_ALWAYS`** scales to the page width, up or down.
- **`TKTP_FIT_NONE`** never scales.

## Public declarations

```freebasic
enum : TKRB_REPORT_HEADER = 0, TKRB_PAGE_HEADER, TKRB_GROUP_HEADER, TKRB_DETAIL, TKRB_GROUP_FOOTER, TKRB_REPORT_FOOTER, TKRB_PAGE_FOOTER : end enum
enum : TKRI_LABEL = 0, TKRI_FIELD, TKRI_SUMMARY, TKRI_PAGEINFO, TKRI_LINE, TKRI_BOX, TKRI_IMAGE, TKRI_CHECK, TKRI_CUSTOM : end enum
enum : TKRS_SUM = 0, TKRS_COUNT, TKRS_AVG, TKRS_MIN, TKRS_MAX : end enum
const TKRS_SCOPE_REPORT = -1
enum : TKRI_BORDER_LEFT = 1, TKRI_BORDER_TOP = 2, TKRI_BORDER_RIGHT = 4, TKRI_BORDER_BOTTOM = 8, TKRI_BORDER_ALL = 15 : end enum
enum : TKTP_FIT_NONE = 0, TKTP_FIT_SHRINK, TKTP_FIT_ALWAYS : end enum

function tkReport_Create( byref title as ustring = "" ) as TK_REPORT ptr
sub tkReport_Destroy( byval rpt as TK_REPORT ptr )
sub tkReport_SetPageSetup( byval rpt as TK_REPORT ptr, byref ps as TKPAGESETUP )
function tkReport_GetBand( byval rpt as TK_REPORT ptr, byval kind as long, byval level as long = 0 ) as TK_RBAND ptr
function tkReport_AddGroup( byval rpt as TK_REPORT ptr, byval keyField as long ) as long
sub tkRBand_SetHeight( byval band as TK_RBAND ptr, byval heightPt as single )
function tkRBand_AddLabel( byval band as TK_RBAND ptr, byref rc as TKRECTF, byref text as ustring, byval flags as long = TK_DT_LEFT ) as TKREPORT_ITEM ptr
function tkRBand_AddField( byval band as TK_RBAND ptr, byref rc as TKRECTF, byval nField as long, byref fmt as ustring = "", byval flags as long = TK_DT_LEFT ) as TKREPORT_ITEM ptr
function tkRBand_AddSummary( byval band as TK_RBAND ptr, byref rc as TKRECTF, byval nField as long, byval fn as long, byval nScope as long = TKRS_SCOPE_REPORT, byref fmt as ustring = "", byval flags as long = TK_DT_RIGHT ) as TKREPORT_ITEM ptr
function tkRBand_AddPageInfo( byval band as TK_RBAND ptr, byref rc as TKRECTF, byref text as ustring = "Page {p} of {n}", byval flags as long = TK_DT_RIGHT ) as TKREPORT_ITEM ptr
function tkRBand_AddLine / AddBox / AddImage / AddCheckBox / AddCustom / AddItem
sub tkReport_SetFields( byval rpt as TK_REPORT ptr, names() as ustring, kinds() as long )
sub tkReport_SetRowCount( byval rpt as TK_REPORT ptr, byval nRows as integer )
sub tkReport_SetGetValueCallback( byval rpt as TK_REPORT ptr, byval cb as RP_GetValueSub )
sub tkReport_SourceFromListTree( byval rpt as TK_REPORT ptr, byval hList as TK_WIDGET ptr )
sub tkReport_SetSource( byval rpt as TK_REPORT ptr, byref src as TKREPORT_SOURCE )
function tkReport_TableAddField( byval rpt as TK_REPORT ptr, byref name_ as ustring ) as long
sub tkReport_TableClear( byval rpt as TK_REPORT ptr )
function tkReport_TableAddRow( byval rpt as TK_REPORT ptr ) as integer
function tkReport_TableCell( byval rpt as TK_REPORT ptr, byval row as integer, byval f as long ) as TK_VALUE ptr
function tkReport_FindField( byval rpt as TK_REPORT ptr, byref name_ as ustring ) as long
function tkReport_FormatValue( byref v as TK_VALUE, byref fmt as ustring = "", byref boolText as ustring = "Yes|No" ) as ustring
function tkReport_CreateDoc( byval rpt as TK_REPORT ptr ) as TK_PRINTDOC ptr
function tkReport_Run( byval rpt as TK_REPORT ptr ) as TK_PRINTDOC ptr
function tkReport_GetRowsRead( byval rpt as TK_REPORT ptr ) as integer
sub tkReport_SetBeforePrintCallback / SetPaintItemCallback / SetBoolText / SetUserData
function tkTablePrint_FromListTree( byval hList as TK_WIDGET ptr, byref opts as TKTABLEPRINT_OPTIONS, byval pSetup as TKPAGESETUP ptr = 0 ) as TK_TABLEPRINT ptr
function tkTablePrint_CreateDoc( byval t as TK_TABLEPRINT ptr ) as TK_PRINTDOC ptr
sub tkTablePrint_GetLayout( byval t as TK_TABLEPRINT ptr, byref scale as single, byref colPages as long )
sub tkTablePrint_Destroy( byval t as TK_TABLEPRINT ptr )
' module tkReportSqlite
function tkReportSqlite_Open( byval rpt as TK_REPORT ptr, byval db as sqlite3 ptr, byref sql as ustring ) as boolean
function tkReportSqlite_OpenEx( byval rpt as TK_REPORT ptr, byval db as sqlite3 ptr, byref sql as ustring, params() as TK_VALUE ) as boolean
sub tkReportSqlite_Close( byval rpt as TK_REPORT ptr )
```

The types (`TKREPORT_SOURCE`, `TKREPORT_ITEM`, `TKREPORT_BAND`, `TKTABLEPRINT_OPTIONS`) are documented field by field in `tkReport.tiko` and `rpTable.tiko`.

### See also

- [tkReportViewer](tkReportViewer)
- [tkPrint](tkPrint)

To draw a report instead of building it in code, see the [Report Designer](Report-Designer).
