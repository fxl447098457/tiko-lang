# tkControls

Owner-drawn controls for tiko on **SDL3 + SDL_ttf**, for Windows, Linux and macOS. Every
control draws itself into SDL windows; setters change a control silently, and only what the
user does fires a callback.

Each control is a module of the `vendor` package, reached with one `#import`:

```freebasic
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkButton"

using tkApp
using tkHost
using tkButton
```

Every module imports `vendor/tkControls/tkHost` (the widget core) and, through it,
`vendor/SDL3/ttf` and `vendor/SDL3/image`.

**Fonts come with the package**: Inter (text), Cascadia Mono (code) and Fluent UI System Icons
(glyphs), copied beside every program that imports tkHost. `tkHost_FontDir() & TK_FONT_UI` is
always a file that is there; the `TK_ICON_*` constants name the glyphs.

`tkCodeEdit` hosts **scintk**, a Scintilla build for tkControls (`tkCodeEdit/scintk`), loaded at
run time and copied beside the program as `scintk.dll` / `libscintk.so`.

Runnable demos and a self-test for every control are in the toolchain's `examples/tkControls/`,
with the porting notes (`FINDINGS.md`, `PORTING.md`).

## The modules

Each directory is one module, `vendor/tkControls/<name>`.

| Module | What it is |
| --- | --- |
| `tkApp` | the application framework: start-up, loop, forms, fonts, theme |
| `tkHost` | the widget core: surfaces, widget tree, focus, capture, timers, popups, bundled fonts |
| `tkPaint` | the drawing surface on SDL_Renderer + SDL_ttf |
| `tkTheme` | the shared light / dark theme |
| `tkThemeFile` | a `.tktheme` read at run time: `tkTheme_Load( path )` installs a theme a user picks |
| `tkKeys` | keyboard shortcuts and key maps |
| `tkTest` | the self-test kit the examples use |
| `tkButton`, `tkCheckBox`, `tkOptionButton`, `tkToggle` | buttons and switches |
| `tkTextBox`, `tkNumericUpDown`, `tkDatePicker`, `tkCalendar`, `tkCodeEdit` | text, numbers, dates, code |
| `tkListTree`, `tkComboBox`, `tkSelectBar`, `tkTabBar`, `tkColumnHeader` | lists and selection |
| `tkDataGrid` | a data grid: typed columns over stored rows, painted for the visible cells only, scrolled by the pixel (phase G0: no selection or editing yet) |
| `tkMenuBar`, `tkPopupMenu`, `tkToolbar`, `tkIconPanel`, `tkStatusBar` | command surfaces |
| `tkLayout` | automatic position and size: Anchor and Dock, in design units; a hidden docked control takes no space, and a dock can take its height from the control |
| `tkStack` | a column or a row of controls, one after another, for a phone screen: fixed, own-size (a callback) or FILL items, padding and gaps in design units, a hidden item taking no space, nested stacks (cards); `Measure` gives a scroll panel its content height |
| `tkLabel`, `tkPanel`, `tkGroupBox`, `tkPicture`, `tkTabControl` | text, containers, images and tabbed pages |
| `tkSplitter`, `tkScrollPanel`, `tkScrollBar`, `tkVScrollBar`, `tkHScrollBar` | layout and scrolling |
| `tkMessageBox`, `tkColorPicker`, `tkTooltip`, `tkProgressBar`, `tkSpinner`, `tkFileDialog` | popups and feedback |
| `tkInfoBar` | an inline message bar in the layout: severity, title, message, actions, close |
| `tkToast` | toasts: transient cards in a corner of a window, queued, timed, with actions; one toaster per window |
| `tkNotify` | what the info bar and the toasts share: severities, colours, the item painter |
| `tkChart` | line, column, HLOC and pie charts |
| `tkPrint` | print documents: pages recorded once in points (the `tkPage_*` API, or any widget's own painting), replayed to the screen, PNG and (later) PDF and printers |
| `tkPrintPreview` | a print document's pages as paper: fit / custom zoom, columns, continuous or single view, links, pages generated while shown |
| `tkPdf` | a print document as a PDF file: vector shapes, real (searchable) text in embedded fonts, images, links; no library linked |
| `tkPrinter` | printers and print jobs: Windows (winspool, raster at the printer's resolution), CUPS on Linux / macOS (a PDF job; libcups loaded at run time, `lp` without it) |
| `tkPrintDialog` | the Print and Page Setup dialogs, tk-drawn on every OS |
| `tkReportViewer` | a print document with its tools: toolbar (print, page setup, PDF, pages, zoom), preview, status bar; a tkReportDef shown with a parameter strip (a control per parameter, and Run) |
| `tkReport` | banded reports (report / page / group headers and footers, detail, no-data, summaries, page info) over callback, table, ListTree or custom sources; expressions (tkRExpr): calculated fields, filters, groups, items, totals with their scope, late values, rules and visibility; the table printer for a ListTree |
| `tkReportSqlite` | an SQLite query as a tkReport's data: positional or named parameters; sorts by wrapping the query |
| `tkReportBarcode` | barcodes in tkReport bands: `tkRBand_AddBarcode` draws a field's text as any tkBarcode symbology at its physical size (vector in PDF); `tkReportBarcode_Install` registers the painter, so a report without barcodes links no libzint |
| `tkReportGrid` | a tkDataGrid as a tkReport's data: its visible columns in display order, its rows in view order, typed values |
| `tkReportDef` | a report defined in a `.tkreport` file (TOML): read strictly, written back canonically, laid out by tkReport over the sources bound to it by name (SQLite, a DataGrid, the host's own), master-detail by a join, each source's fields checked against the file |
| `tkRExpr` | the report expression language: typed, sandboxed expressions over `TK_VALUE` (fields, parameters, totals, report values, text / number / date functions, `Format` masks), compiled once and evaluated per row |
| `tkTimer` | a component: calls a procedure every so many milliseconds |
| `tkContextMenu` | a component: a right-click menu attached to widgets (the designer's PopupMenu) |
| `tkImage`, `tkFontList` | image files; the fonts installed on the machine |
| `tkBind` | the conversions a designed form's `LoadFrom` / `SaveTo` use to move record fields in and out of controls, and their strict checks, rules and error report |
| `tkAutoComplete` | a text box with a filter-as-you-type list of suggestions (stored items; the list never takes the keyboard focus) |
| `tkNavigator` | a record navigator: First, Previous, the position ("3 of 120"), Next, Last, New, Delete; a designed form steps it through an array of its records |
| `tkMatch` | filter-as-you-type matching, no SDL: prefix, word-prefix, contains and fuzzy (fzy) with highlight runs, narrowing, ranked and capped filters |
| `tkSlider` | a value on a track (or a lower and upper value, range mode): horizontal or vertical, ticks and labels, a value tip, jump or page clicks; the designer's Slider |
| `tkCheckedList`, `tkCheckedCombo`, `tkTokenBox` | several values picked at once: a list with a check box per item; a combo whose dropdown is a checked list (summary, select-all, filter, OK / Cancel); chips in a text box with suggestions. Each binds its chosen keys as text; the designer's CheckedList, CheckedComboBox and TokenBox. `tkListTree` has the check boxes (tri-state tree cascade) they are built on; `tkItemPopup` is their dropdown |
| `tkTimePicker`, `tkTimePanel` | a time of day: a segmented field you type into and step, with a column or list dropdown (or spin buttons), 12- or 24-hour by pattern, a range and a step; the panel alone embeds in a form; the designer's TimePicker and TimePanel, bound as `time` |
| `tkDateTimePicker` | a date and a time in one segmented field (year, month or its name, day, weekday shown, hour, minute...), with a calendar beside the time columns in one dropdown whose picks wait for OK, Enter or Now; one range over both halves; the designer's DateTimePicker, bound as `datetime` |
| `tkRating` | a rating: a row of stars (or hearts, circles, diamonds, a glyph) set by click, drag or keys; half or tenth steps, read-only display, a caption; the designer's Rating, bound as a number |
| `tkBadge`, `tkAvatar`, `tkAvatarGroup` | status marks: a count, dot, text, glyph or presence badge, standalone or attached to a corner of another control; a picture, initials or glyph in a circle or rounded square, with a presence badge; a row of overlapping avatars ending in `+N`. The designer's Badge, Avatar and AvatarGroup |
| `tkChip`, `tkChipGroup` | compact choices and tags: an action, toggle or removable input chip with avatar, glyph, check, count and remove button; a wrapping or one-row group with none, single or multiple selection, veto-able removal and reordering (Shift+arrows, drag). Chip binds its selected state, ChipGroup its selected keys and its items |
| `tkBarcode` | a 1D or 2D barcode -- EAN / UPC / ISBN, Code 128 / GS1-128, Code 39, Code 93, ITF / ITF-14, Codabar, QR / Micro QR, Data Matrix, PDF417, Aztec -- encoded by libzint (`vendor/zint`): whole-pixel modules, quiet zones, the human-readable text, fit modes, rotation, an error state for data the symbology refuses; also painted widgetless (`tkBarcode_PaintInto`). Design: docs/tkControls/BARCODE.md |

The controls are under the [Mozilla Public License 2.0](LICENSE). The fonts keep their own
licences (SIL OFL 1.1, MIT), shipped beside them in `fonts/`; scintk's Scintilla and Lexilla
keep theirs in `tkCodeEdit/scintk/vendor/`. tkBarcode links libzint, BSD-3 (`vendor/zint/LICENSE`).
