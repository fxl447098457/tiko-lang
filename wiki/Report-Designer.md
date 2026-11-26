[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **Report Designer**

# Report Designer

Draw a report in tkEdit, bind it to your program's data, show it in a viewer, print it, or write a PDF.

The Report Designer is part of tkEdit, beside the [Form Designer](Form-Designer). A report is a
`.tkreport` file: bands down the page, items in the bands, data sources, parameters. tkEdit
generates a typed tiko module from it. Your program fills that module with data and shows the report
in a [tkReportViewer](tkReportViewer). The report is laid out by [tkReport](tkReport) at run time,
so the program does not need the designer.

## Getting started

**Design > New Report...** asks where, then opens the wizard:

| Wizard field | What it does |
| --- | --- |
| title | The report header's text. |
| source, kind | The data source's name and kind: `host`, `array`, `sqlite` or `grid`. |
| item_type | For an array source: the element type, such as `orderdb.Order`. |
| sql, design_db | For a SQLite source: the query, and the database the designer previews from. |
| fields | The source's fields: `Customer, Amount:float`. A field with no kind is text; the others are `int float bool date time`. |
| parameters | `MinAmount:float, Region`. |
| group_by | A field to group on: a group header and footer, and the sort that brings the rows in group order. |
| layout | `tabular` (captions over columns) or `columnar` (a label and a value per line). |
| paper, landscape | The page. |

It makes a folder of its own:

```
rptSales/
  rptSales.tkreport        the report: the designer owns this
  rptSales.design.tiko     generated from it: don't edit, do commit
  rptSales.tiko            your code (event handlers), when you need one
  rptSales.sample.toml     design rows for the Preview (optional)
```

## The canvas

- **Bands** are stacked as the report prints them. Each band sits under a caption bar showing its
  id, its kind, and what it shows or groups on:
  - report header and page header;
  - group headers, outer to inner;
  - the detail, with a detail report for a master-detail child;
  - group footers, inner to outer;
  - report footer, page footer, no-data.
- **What you see is what prints.** Each band is drawn by the same code that prints the report. A
  field shows its expression, such as `[Customer]`.
- **The mouse:**
  - Click to select. Shift- or Ctrl-click adds an item; the item last added has the grips.
  - Drag to move. Moves snap to a 1 mm grid (0.05 in or 1 pt, by the report's `units`); Alt turns
    snapping off.
  - Drag an item into another band to move it there.
  - Drag a grip to resize, or a band's bottom edge to set its height.
  - Drag on empty space to select with a rubber band.
  - Click a band's caption to pick the band.
- **The keys:**
  - Arrows move a grid step, Ctrl+arrow 0.1 pt, and Shift+arrow resizes.
  - Del deletes the selection or the picked band. Esc drops the selection. Tab walks the items.
- **Edit and Design menu commands:** Cut, Copy, Paste, Select All, Align, Same Size, Bring to Front,
  Send to Back and Equal Spacing.
- **Undo:** every gesture and every dialog's OK is one Undo step.

## The palettes

- **Toolbox:**
  - The item kinds (text, field, line, box, image, check, custom). Click one, then click in a band.
  - `+ <band kind>` inserts a band. A group header adds a new innermost group level.
    `+ detail_report` adds a master-detail section under the selected detail band, over its source's
    child source, with its own report header, detail and report footer.
  - **Data sources...**, **Parameters...**, **Calculated fields...**, **Group and sort...** and
    **Page setup...** open their dialogs. A parameter becomes a field of the generated `Report`, so a
    keyword can't name it.
- **Fields:**
  - Each source's fields, with its child sources under it, then the parameters and the built-in
    values: PageNumber, PageCount, RowNumber, GroupRowNumber and PrintDate.
  - Click one, then click in a band. A field placed in a detail band also places its bold caption in
    the header band above. Hold Shift to place the field alone.
- **Object Tree:** the report, its bands and their items. Click a row to select it.
- **Properties:**
  - The selected item's, band's or report's properties, named as the `.tkreport` names them.
  - A value the file can't hold is refused, with the reason shown in the status bar.
  - `...` on an expression opens the expression editor. `...` on `rules` opens the item's
    conditional styles.

## Expressions

Fields are `[Name]` in the band's own source and `[Source.Name]` elsewhere. Parameters are `@Name`.
Text items mix plain text with expressions in braces: `Page {PageNumber} of {PageCount}`. Totals
are functions: `Sum([Amount])`, `Count( )`, `Avg`, `Min`, `Max`. A total in a group footer covers
its group, and in the report footer the whole report.

The expression editor checks as you type. It shows the expression's type (`= float`), or the first
error and its column (`5: no field [Nope]`). Double-click a field, parameter or function to insert
it.

## Data

| Source kind | Where the rows come from in your program |
| --- | --- |
| `array` | an `Array( of T )`: `r.SetOrders( rows )`, or `items_source` |
| `sqlite` | `r.SetDatabase( db )`; the query's `:Name` parameters come from `params` |
| `grid` | a DataGrid on a form: `r.SetStockGrid( hGrid )` |
| `host` | any `TKREPORT_SOURCE` of yours: `r.SetExtraSource( src )` |

A child source (master-detail) names its master. For arrays, the master's field that holds the
child rows is its `relation`.

A calculated field (**Calculated fields...**) belongs to a source: a name and an expression over the
source's fields and the parameters, such as `LineTotal` = `[Qty] * [UnitPrice]`. It is listed under
**Fields** with the source's own fields and named like one, `[LineTotal]`.

## Preview

**Shift+F7** switches between the bands and a Preview of the report. Nothing is compiled: the
report is made inside tkEdit and shown in a viewer with its parameter strip, Run, Print and PDF.

- A **SQLite** source with a `design_db` is read live from that database.
- **Other sources** show rows from `rptX.sample.toml`, one `[[Source]]` table per row. A child
  row names its master's row with `_master = 1`. Without that file, the Preview generates dummy
  rows: five masters, two children each.

## In your program

```
#import "./rptSales"
dim as rptSales.Report r
r.MinAmount = 100                    ' parameters are typed fields
r.SetOrders( myOrders )              ' Array( of orderdb.Order )
r.ShowIn( viewer.Handle )            ' a tkReportViewer: parameter strip, Run, Print, PDF
' or: dim as ustring errs : r.ExportPdf( "sales.pdf", errs )
```

On a form, a ReportViewer's **Report** property names the report module; its `...` lists the
project's reports. The form then has a member `<viewer>Report` of that report's type.

The sample `examples/tkControls/tkReportDesigner` builds `orders`, a program showing a designed
report in a designed form. Its selftest covers arrays with master-detail, SQLite, a DataGrid,
parameters, events, the viewer and PDF.

The [Orders Tutorial](Orders-Tutorial) adds three designed reports to a data-bound program, one per
kind of data: an invoice from an array of records with a child array, sales by customer from an
SQL query with date parameters, and an order list from a DataGrid as the user filtered it. It is
finished in the toolchain's `examples/tkControls/tkOrders`.

## See also

[tkReport](tkReport) · [tkReportViewer](tkReportViewer) · [Form Designer](Form-Designer) · [Orders Tutorial](Orders-Tutorial) · [tkPrint](tkPrint) · [tkPdf](tkPdf)
