[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **CPrint**

# CPrint

Chooses a printer, measures its page, reads and changes its settings, and prints.

A `CPrint` holds one printer at a time: its name and a **printer device context** for it.
[AttachPrinter](#attachprinter) attaches a printer by name, [ChoosePrinter](#chooseprinter) lets
the user pick one in the Print dialog. Until one of them succeeds there is no device context:
[GetDC](#getdc) returns `NULL` and the measuring members return 0.

**Ownership.** The device context belongs to the object. Attaching another printer deletes the
previous one, and the destructor deletes the last; never call `DeleteDC` on what
[GetDC](#getdc) returns, and do not use it once the object is gone.

**Two sides of a printer.** The measuring members ([GetPPIX](#getppix-getppiy),
[GetHorizontalResolution](#gethorizontalresolution-getverticalresolution),
[GetMarginsPixels](#getmarginspixels) …) ask the device context. The settings
([Copies](#copies), [Orientation](#orientation), [PaperSize](#papersize) …) are read from and
written to the printer's **stored default settings**, by its name, every time:

- reading one opens the printer and returns the value from its defaults, not from the device
  context or from what the user chose in the Print dialog;
- setting one changes the defaults of that printer for every program on the computer, if Windows
  allows it, and the property setters do not say whether it worked. A device context already
  attached keeps the settings it was created with: attach the printer again to print with the
  new ones.

**Units.** Positions on a printer device context are device pixels, counted from the top-left
corner of the **printable area** (the page less the margins the printer cannot reach). The
members named `Units` use hundredths of an inch; `Points` are 1/72 of an inch. Paper lengths and
widths are tenths of a millimetre.

To print, attach a printer, then call `StartDocW`, `StartPage`, draw on [GetDC](#getdc) with GDI
or a GDI+ `CGpGraphics`, `EndPage` and `EndDoc`. [PrintBitmap](#printbitmap) and
[PrintRtf](#printrtf) run the whole job for a bitmap or a rich edit control.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus
```

## Example

Attaches the PDF printer that comes with Windows, reports its page, and prints one line of
12-point text an inch in from the corner of the printable area into a PDF file:

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

function main() as long
    dim pPrint as CPrint
    if pPrint.AttachPrinter( "Microsoft Print to PDF" ) = false then
        print "no such printer"
        return 1
    end if
    print pPrint.GetPrinterName(); ":"; pPrint.GetHorizontalResolution(); " x"; pPrint.GetVerticalResolution(); _
          " pixels at"; pPrint.GetPPIX(); " pixels per inch"

    dim hdc as HDC = pPrint.GetDC()
    dim wszDoc as wstring * 64 = "CPrint demo"
    dim wszFile as wstring * MAX_PATH = "cprint-demo.pdf"
    dim di as DOCINFOW
    di.cbSize = sizeof( DOCINFOW )
    di.lpszDocName = @wszDoc
    di.lpszOutput = @wszFile          ' the PDF printer writes here instead of asking
    if StartDocW( hdc, @di ) <= 0 then return 1
    StartPage( hdc )

    ' a 12-point font, one inch in from the corner of the printable area
    dim hFont as HFONT = CreateFontW( -pPrint.PointsToPixelsY( 12 ), 0, 0, 0, FW_NORMAL, 0, 0, 0, _
                                      DEFAULT_CHARSET, 0, 0, 0, 0, "Segoe UI" )
    dim hOldFont as HGDIOBJ = SelectObject( hdc, hFont )
    dim inch as long = pPrint.UnitsToPixelsX( 100 )
    dim wszText as wstring * 64 = "Printed with CPrint"
    TextOutW( hdc, inch, inch, @wszText, len( wszText ) )
    SelectObject( hdc, hOldFont )
    DeleteObject( hFont )

    EndPage( hdc )
    EndDoc( hdc )
    print "written to "; wszFile
    return 0
end function

end main()
```

On a letter-size page the PDF printer reports 5100 × 6600 pixels at 600 pixels per inch.

## Members

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Creates the object with no printer attached. |
| [Destructor](#destructor) | Deletes the printer device context. |
| [AttachPrinter](#attachprinter) | Attaches a printer by name, or the default printer. |
| [ChoosePrinter](#chooseprinter) | Shows the Print dialog and attaches the printer the user picks. |
| [PageSetup](#pagesetup) | Shows the Page Setup dialog. |
| [GetDC](#getdc) | Returns the printer device context. |
| [GetPrinterName](#getprintername) | Returns the name of the attached printer. |
| [GetDefaultPrinter](#getdefaultprinter) | Returns the name of the user's default printer. |
| [GetDefaultPrinterDriver](#getdefaultprinterdriver) | Returns the driver entry of the default printer. |
| [GetDefaultPrinterPort](#getdefaultprinterport) | Returns the port of the default printer. |
| [SetDefaultPrinterPort](#setdefaultprinterport) | Declared without a body. |
| [SetDefaultPrinter](#setdefaultprinter) | Makes a printer the user's default. |
| [EnumPrinterNames](#enumprinternames) | Lists the printers installed on the computer. |
| [GetPPIX, GetPPIY](#getppix-getppiy) | Return the printer's pixels per inch. |
| [GetHorizontalResolution, GetVerticalResolution](#gethorizontalresolution-getverticalresolution) | Return the size of the printable area in pixels. |
| [GetHorizontalUnits, GetVerticalUnits](#gethorizontalunits-getverticalunits) | Return the size of the printable area in hundredths of an inch. |
| [GetMarginsPixels](#getmarginspixels) | Returns the four non-printable margins in pixels. |
| [GetMarginsUnits](#getmarginsunits) | Returns the four non-printable margins in hundredths of an inch. |
| [PixelsToUnitsX, PixelsToUnitsY](#pixelstounitsx-pixelstounitsy) | Convert printer pixels to hundredths of an inch. |
| [UnitsToPixelsX, UnitsToPixelsY](#unitstopixelsx-unitstopixelsy) | Convert hundredths of an inch to printer pixels. |
| [PixelsToPointsX, PixelsToPointsY](#pixelstopointsx-pixelstopointsy) | Convert printer pixels to points. |
| [PointsToPixelsX, PointsToPixelsY](#pointstopixelsx-pointstopixelsy) | Convert points to printer pixels. |
| [GetDocumentProperties](#getdocumentproperties) | Reads one field of the printer's stored settings. |
| [SetPrinterInfo](#setprinterinfo) | Changes one field of the printer's stored settings. |
| [Collate](#collate) | Says whether the printer can collate. |
| [CollateMode](#collatemode) | Reads or sets whether copies are collated. |
| [Color](#color) | Says whether the printer prints in colour. |
| [ColorMode](#colormode) | Sets colour or monochrome printing. |
| [Copies](#copies) | Reads or sets the number of copies. |
| [Duplex](#duplex) | Says whether the printer prints on both sides. |
| [DuplexMode](#duplexmode) | Reads or sets one- or two-sided printing. |
| [Orientation](#orientation) | Reads or sets portrait or landscape. |
| [PaperSize](#papersize) | Reads or sets the paper size by number. |
| [SetPaperSize](#setpapersize) | Sets a custom paper length and width. |
| [PaperLength](#paperlength) | Reads or sets the paper length. |
| [PaperWidth](#paperwidth) | Reads or sets the paper width. |
| [GetPaperNames](#getpapernames) | Lists the paper sizes the printer offers. |
| [Quality](#quality) | Reads or sets the print quality. |
| [Scale](#scale) | Reads or sets the scaling factor. |
| [Tray](#tray) | Reads or sets the paper source. |
| [GetTrayNames](#gettraynames) | Declared without a body. |
| [PrintBitmap](#printbitmap) | Prints a bitmap on the attached printer. |
| [PrintBitmapToFile](#printbitmaptofile) | Prints a bitmap on the attached printer into a file. |
| [PrintRtf](#printrtf) | Prints the contents of a rich edit control. |

## Reference

### Constructor

```freebasic
constructor
```

Creates the object with no printer attached and no device context.

**Example**

```freebasic
dim pr as CPrint
print pr.GetDC()            ' 0 until a printer is attached
```

### Destructor

```freebasic
destructor
```

Deletes the device context of the attached printer, if there is one.

**Example**

```freebasic
scope
    dim pr as CPrint
    pr.AttachPrinter()
end scope   ' the printer device context is deleted here
```

Microsoft Learn: [DeleteDC](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deletedc)

### AttachPrinter

```freebasic
function AttachPrinter( byref wszPrinterName as wstring = "" ) as boolean
```

Creates a device context for the printer named `wszPrinterName`, with that printer's stored
settings, and makes it the attached printer; an empty name means the default printer. On success
the previous device context is deleted.

The name is stored before the device context is created, so after a failure
[GetPrinterName](#getprintername) returns the name that failed while [GetDC](#getdc) still
returns the previous printer's device context.

| Parameter | Meaning |
| --- | --- |
| `wszPrinterName` | The printer's name as Windows shows it under Printers & scanners, such as `"Microsoft Print to PDF"`, or `""` for the default printer. |

**Returns** `true` when the device context was created, `false` when there is no such printer.

**Example**

```freebasic
dim pr as CPrint
if pr.AttachPrinter( "Microsoft Print to PDF" ) = false then pr.AttachPrinter()
```

Microsoft Learn: [CreateDCW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createdcw)

### ChoosePrinter

```freebasic
function ChoosePrinter( byval hwndOwner as HWND = NULL ) as boolean
```

Shows the Print dialog. When the user clicks **Print**, the printer chosen there is attached:
its name is stored and the device context the dialog creates, with the user's choices in it,
replaces the previous one. The dialog has no Print to file box, and its Selection and page
range options are off.

| Parameter | Meaning |
| --- | --- |
| `hwndOwner` | The window that owns the dialog, or `NULL` for none. |

**Returns** `true` when the user clicked **Print**; `false` when the dialog was cancelled or
failed, and then nothing changes.

**Example**

```freebasic
dim pr as CPrint
if pr.ChoosePrinter( hwnd ) then print "printing on "; pr.GetPrinterName()
```

Microsoft Learn: [PRINTDLGW](https://learn.microsoft.com/en-us/windows/win32/api/commdlg/ns-commdlg-printdlgw), [Print dialog box](https://learn.microsoft.com/en-us/windows/win32/dlgbox/print-dialog-box)

### PageSetup

```freebasic
function PageSetup (BYVAL hwndOwner AS HWND, BYREF psd AS PAGESETUPDLGW) AS BOOLEAN
```

Shows the Page Setup dialog, where the user picks paper, source, orientation and margins. The caller is responsible of freeing the `hDevMode` and `hDevNames` members of the `PAGESETUPDLGW` structure:

```freebasic
IF psd.hDevMode THEN GlobalFree(psd.hDevMode)
IF psd.hDevNames THEN GlobalFree(psd.hDevNames)
```

| Parameter | Meaning |
| --- | --- |
| `hwndOwner` | The window that owns the dialog, or `NULL` for none. |
| `psd` | A `PAGESETUPDLGW` structure. |

**Returns** `true` when the user clicked **OK**, `false` otherwise.

**Example**

```freebasic
dim pr as CPrint
if pr.PageSetup( hwnd ) then print "confirmed"
```

Microsoft Learn: [PAGESETUPDLGW](https://learn.microsoft.com/en-us/windows/win32/api/commdlg/ns-commdlg-pagesetupdlgw), [Page Setup dialog box](https://learn.microsoft.com/en-us/windows/win32/dlgbox/page-setup-dialog-box)

### GetDC

```freebasic
function GetDC() as HDC
```

Returns the device context of the attached printer, for `StartDocW` and drawing. It stays owned
by the object.

**Returns** the handle, or `NULL` when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
dim hdc as HDC = pr.GetDC()
if hdc then print "page:"; GetDeviceCaps( hdc, HORZRES ); " x"; GetDeviceCaps( hdc, VERTRES )
```

### GetPrinterName

```freebasic
function GetPrinterName() as ustring
```

Returns the name of the printer last passed to [AttachPrinter](#attachprinter) or chosen in
[ChoosePrinter](#chooseprinter); the settings properties use this name.

**Returns** the name, or `""` before any printer was attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
print "attached: "; pr.GetPrinterName()
```

### GetDefaultPrinter

```freebasic
function GetDefaultPrinter() as ustring
```

Returns the name of the current user's default printer. It does not need a printer to be
attached.

**Returns** the name, or `""` when there is no default printer.

**Example**

```freebasic
dim pr as CPrint
print "default printer: "; pr.GetDefaultPrinter()
```

Microsoft Learn: [GetProfileStringW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-getprofilestringw)

### GetDefaultPrinterDriver

```freebasic
function GetDefaultPrinterDriver() as ustring
```

Returns the second field of the default printer's entry in the user's `[windows] device`
setting, which names the driver; on current Windows it normally reads `winspool`.

**Returns** the field, or `""` when there is no default printer.

**Example**

```freebasic
dim pr as CPrint
print "driver: "; pr.GetDefaultPrinterDriver()
```

### GetDefaultPrinterPort

```freebasic
function GetDefaultPrinterPort() as ustring
```

Returns the third field of the same entry: the port the default printer is on, such as `Ne00:`.

**Returns** the port, or `""` when there is no default printer.

**Example**

```freebasic
dim pr as CPrint
print "port: "; pr.GetDefaultPrinterPort()
```

### SetDefaultPrinterPort

```freebasic
function SetDefaultPrinterPort() as ustring
```

Declared in the class but given no body: a program that calls it compiles, then stops at the link
step with an undefined symbol. Read the port with
[GetDefaultPrinterPort](#getdefaultprinterport).

**Example**

```freebasic
dim pr as CPrint
dim port as ustring = pr.GetDefaultPrinterPort()   ' SetDefaultPrinterPort does not link
```

### SetDefaultPrinter

```freebasic
function SetDefaultPrinter( byref wszPrinterName as wstring ) as boolean
```

Makes `wszPrinterName` the current user's default printer, for every program. An empty name
lets Windows pick one of the installed printers. The attached printer does not change.

| Parameter | Meaning |
| --- | --- |
| `wszPrinterName` | A local printer's name, or `\\server\printer` for a network printer. |

**Returns** `true` on success; on failure `false`, and `GetLastError()` says why.

**Example**

```freebasic
dim pr as CPrint
if pr.SetDefaultPrinter( "Microsoft Print to PDF" ) = false then print "error"; GetLastError()
```

Microsoft Learn: [SetDefaultPrinter](https://learn.microsoft.com/en-us/windows/win32/printdocs/setdefaultprinter)

### EnumPrinterNames

```freebasic
function EnumPrinterNames() as ustring
```

Lists the printers installed on the computer, one name per line, with a carriage return and line
feed between names and none after the last. It does not need a printer to be attached.

**Returns** the names, or `""` when there are none.

**Example**

```freebasic
dim pr as CPrint
dim names as ustring = pr.EnumPrinterNames()
print names
```

Microsoft Learn: [EnumPrinters](https://learn.microsoft.com/en-us/windows/win32/printdocs/enumprinters)

### GetPPIX, GetPPIY

```freebasic
function GetPPIX() as long
function GetPPIY() as long
```

Return the attached printer's resolution: pixels per inch across and down the page.

**Returns** the resolution, or 0 when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter( "Microsoft Print to PDF" )
print pr.GetPPIX(); " x"; pr.GetPPIY()      ' 600 x 600
```

Microsoft Learn: [GetDeviceCaps](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getdevicecaps) with `LOGPIXELSX`, `LOGPIXELSY`

### GetHorizontalResolution, GetVerticalResolution

```freebasic
function GetHorizontalResolution() as long
function GetVerticalResolution() as long
```

Return the width and height of the printable area in device pixels: the drawing space of
[GetDC](#getdc), from (0, 0) to these values.

**Returns** the size, or 0 when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter( "Microsoft Print to PDF" )
print pr.GetHorizontalResolution(); " x"; pr.GetVerticalResolution()   ' 5100 x 6600 on letter paper
```

Microsoft Learn: [GetDeviceCaps](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getdevicecaps) with `HORZRES`, `VERTRES`

### GetHorizontalUnits, GetVerticalUnits

```freebasic
function GetHorizontalUnits() as long
function GetVerticalUnits() as long
```

Return the width and height of the printable area in hundredths of an inch: the pixel size
divided by the resolution, times 100.

**Returns** the size, or 0 when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter( "Microsoft Print to PDF" )
print pr.GetHorizontalUnits(); " x"; pr.GetVerticalUnits()   ' 850 x 1100: 8.5 x 11 inches
```

### GetMarginsPixels

```freebasic
sub GetMarginsPixels overload( byref nLeft as long, byref nTop as long, byref nRight as long, byref nBottom as long )
function GetMarginsPixels overload() as RECT
```

Returns the four margins of the page that the printer cannot print on, in device pixels: the
distance from each edge of the paper to the printable area. The `RECT` form puts the four
widths in `left`, `top`, `right` and `bottom`; they are widths, not coordinates.

With no printer attached the sub leaves its arguments alone and the function returns an
all-zero `RECT`. The PDF printer reports four zero margins.

| Parameter | Meaning |
| --- | --- |
| `nLeft`, `nTop`, `nRight`, `nBottom` | Receive the left, top, right and bottom margins. |

**Returns** (function form) the margins as a `RECT`.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
dim as long l, t, r, b
pr.GetMarginsPixels( l, t, r, b )
dim rc as RECT = pr.GetMarginsPixels()
```

Microsoft Learn: [GetDeviceCaps](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getdevicecaps) with `PHYSICALOFFSETX`, `PHYSICALWIDTH`

### GetMarginsUnits

```freebasic
sub GetMarginsUnits overload( byref nLeft as long, byref nTop as long, byref nRight as long, byref nBottom as long )
function GetMarginsUnits overload() as RECT
```

The same margins as [GetMarginsPixels](#getmarginspixels), in hundredths of an inch. The right
and bottom margins are worked out from sizes already converted and rounded, so they can differ
by one from a conversion of the pixel values.

| Parameter | Meaning |
| --- | --- |
| `nLeft`, `nTop`, `nRight`, `nBottom` | Receive the left, top, right and bottom margins. |

**Returns** (function form) the margins as a `RECT`.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
dim rc as RECT = pr.GetMarginsUnits()
print "left margin:"; rc.left / 100; " inch"
```

### PixelsToUnitsX, PixelsToUnitsY

```freebasic
function PixelsToUnitsX( byval pix as long ) as long
function PixelsToUnitsY( byval pix as long ) as long
```

Convert a horizontal or vertical distance in printer pixels to hundredths of an inch, rounded.

**Returns** the distance, or 0 when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter( "Microsoft Print to PDF" )
print pr.PixelsToUnitsX( 600 ); pr.PixelsToUnitsY( 300 )    ' 100 50
```

### UnitsToPixelsX, UnitsToPixelsY

```freebasic
function UnitsToPixelsX( byval units as long ) as long
function UnitsToPixelsY( byval units as long ) as long
```

Convert a horizontal or vertical distance in hundredths of an inch to printer pixels, rounded.

**Returns** the distance, or 0 when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter( "Microsoft Print to PDF" )
print pr.UnitsToPixelsX( 100 ); pr.UnitsToPixelsY( 50 )     ' 600 300
```

Microsoft Learn: [MulDiv](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-muldiv)

### PixelsToPointsX, PixelsToPointsY

```freebasic
function PixelsToPointsX( byval pix as long ) as long
function PixelsToPointsY( byval pix as long ) as long
```

Convert a horizontal or vertical distance in printer pixels to points (1/72 inch), rounded.

**Returns** the distance, or 0 when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter( "Microsoft Print to PDF" )
print pr.PixelsToPointsX( 600 ); pr.PixelsToPointsY( 100 )   ' 72 12
```

### PointsToPixelsX, PointsToPixelsY

```freebasic
function PointsToPixelsX( byval pts as long ) as long
function PointsToPixelsY( byval pts as long ) as long
```

Convert a horizontal or vertical distance in points to printer pixels, rounded. Pass the
negated result of `PointsToPixelsY` as the height of a font for it to print at that point size.

**Returns** the distance, or 0 when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
dim hFont as HFONT = CreateFontW( -pr.PointsToPixelsY( 10 ), 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, "Arial" )
print pr.PointsToPixelsX( 72 )      ' one inch
DeleteObject( hFont )
```

### GetDocumentProperties

```freebasic
function GetDocumentProperties( byval dmField as DWORD ) as long
```

Opens the attached printer by name and reads one field of its stored settings (its `DEVMODEW`).
`dmField` is one of `DM_COLLATE`, `DM_COPIES`, `DM_ORIENTATION`, `DM_PAPERSIZE`,
`DM_PRINTQUALITY`, `DM_SCALE`, `DM_DEFAULTSOURCE`, `DM_PAPERLENGTH`, `DM_PAPERWIDTH` or
`DM_DUPLEX`. For any other value, `DM_COLOR` among them, the call returns 1 (`IDOK`) when the
settings could be read, whatever they hold. The settings properties are built on it.

| Parameter | Meaning |
| --- | --- |
| `dmField` | The `DM_*` flag of the field to read. |

**Returns** the field's value; 0 when no printer is attached or it cannot be opened; 0 or a
negative value when its settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.GetDocumentProperties( DM_ORIENTATION ) = DMORIENT_LANDSCAPE then print "landscape"
```

Microsoft Learn: [DocumentProperties](https://learn.microsoft.com/en-us/windows/win32/printdocs/documentproperties), [DEVMODEW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-devmodew)

### SetPrinterInfo

```freebasic
function SetPrinterInfo( byval dmField as DWORD, byval nValue as long ) as boolean
```

Changes one field of the attached printer's **stored** settings, for every program on the
computer. `dmField` is one of `DM_COLLATE`, `DM_COLOR`, `DM_COPIES`, `DM_DUPLEX`,
`DM_ORIENTATION`, `DM_PAPERSIZE`, `DM_PRINTQUALITY`, `DM_DEFAULTSOURCE`, `DM_SCALE`,
`DM_PAPERLENGTH` or `DM_PAPERWIDTH`. A field the driver does not support is left as it is, and
the settings are still written back.

The printer is opened with `PRINTER_ACCESS_USE` only; Windows may refuse to change a printer's
defaults without administrative rights, and then the call returns `false`. The attached device
context is not changed: call [AttachPrinter](#attachprinter) again to print with the new value.
The settings properties' setters call it and drop its result.

| Parameter | Meaning |
| --- | --- |
| `dmField` | The `DM_*` flag of the field to change. |
| `nValue` | The new value. |

**Returns** `true` when the printer accepted the new settings, `false` otherwise.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.SetPrinterInfo( DM_ORIENTATION, DMORIENT_LANDSCAPE ) then pr.AttachPrinter( pr.GetPrinterName() )
```

Microsoft Learn: [SetPrinter](https://learn.microsoft.com/en-us/windows/win32/printdocs/setprinter)

### Collate

```freebasic
property Collate() as boolean
```

Says whether the attached printer can collate copies (print one whole copy before starting the
next). With no printer attached, or for a name Windows does not know, it returns `true`, the
same as the error value it receives.

**Returns** `true` or `false`.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.Collate then pr.CollateMode = DMCOLLATE_TRUE
```

Microsoft Learn: [DeviceCapabilitiesW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-devicecapabilitiesw) with `DC_COLLATE`

### CollateMode

```freebasic
property CollateMode() as long
property CollateMode( byval nMode as long )
```

Reads or sets whether copies are collated: `DMCOLLATE_TRUE` (1) or `DMCOLLATE_FALSE` (0). The
setter changes the printer's stored settings (see [SetPrinterInfo](#setprinterinfo)).

**Returns** (getter) the mode, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
print "collate:"; pr.CollateMode
```

### Color

```freebasic
property Color() as boolean
```

Says whether the attached printer is a colour printer. With no printer attached it returns
`true`, the same as for [Collate](#collate).

**Returns** `true` or `false`.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.Color = false then print "black and white only"
```

Microsoft Learn: [DeviceCapabilitiesW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-devicecapabilitiesw) with `DC_COLORDEVICE`

### ColorMode

```freebasic
property ColorMode() as long
property ColorMode( byval nMode as long )
```

The setter switches a colour printer's stored settings between `DMCOLOR_MONOCHROME` (1) and
`DMCOLOR_COLOR` (2). The getter reads through
[GetDocumentProperties](#getdocumentproperties), which has no case for `DM_COLOR`: it returns 1
whenever the settings can be read, whichever mode is set. To read the real mode, take `dmColor`
from the printer's `DEVMODEW` with `DocumentPropertiesW`.

**Returns** (getter) 1 when the settings can be read, otherwise 0 or a negative value.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.Color then pr.ColorMode = DMCOLOR_MONOCHROME
```

### Copies

```freebasic
property Copies() as long
property Copies( byval nCopies as long )
```

Reads or sets the number of copies in the printer's stored settings, for printers that make
copies themselves. [PrintBitmap](#printbitmap), [PrintBitmapToFile](#printbitmaptofile) and
[PrintRtf](#printrtf) read it to know how many times to print.

**Returns** (getter) the number of copies, or 0 when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
print "copies:"; pr.Copies          ' usually 1
```

### Duplex

```freebasic
property Duplex() as boolean
```

Says whether the attached printer can print on both sides of the paper. With no printer
attached it returns `true`, the same as for [Collate](#collate).

**Returns** `true` or `false`.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.Duplex then pr.DuplexMode = DMDUP_VERTICAL
```

Microsoft Learn: [DeviceCapabilitiesW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-devicecapabilitiesw) with `DC_DUPLEX`

### DuplexMode

```freebasic
property DuplexMode() as long
property DuplexMode( byval nDuplexMode as long )
```

Reads or sets two-sided printing: `DMDUP_SIMPLEX` (1, one side), `DMDUP_VERTICAL` (2, turned
over on the long edge in portrait) or `DMDUP_HORIZONTAL` (3, turned over on the short edge).

**Returns** (getter) the mode, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
print "duplex mode:"; pr.DuplexMode
```

### Orientation

```freebasic
property Orientation() as long
property Orientation( byval nOrientation as long )
```

Reads or sets the page orientation: `DMORIENT_PORTRAIT` (1) or `DMORIENT_LANDSCAPE` (2).

**Returns** (getter) the orientation, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.Orientation = DMORIENT_PORTRAIT then print "portrait"
```

### PaperSize

```freebasic
property PaperSize() as long
property PaperSize( byval nSize as long )
```

Reads or sets the paper size as a `DMPAPER_*` number, such as `DMPAPER_LETTER` (1),
`DMPAPER_LEGAL` (5), `DMPAPER_A3` (8) or `DMPAPER_A4` (9).

**Returns** (getter) the paper size, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.PaperSize <> DMPAPER_A4 then pr.PaperSize = DMPAPER_A4
```

Microsoft Learn: [Paper sizes](https://learn.microsoft.com/en-us/windows/win32/intl/paper-sizes)

### SetPaperSize

```freebasic
function SetPaperSize( byval nLength as long, byval nWidth as long ) as boolean
```

Sets a custom paper length and then width, in tenths of a millimetre, in the printer's stored
settings. It stops after the length when that fails.

| Parameter | Meaning |
| --- | --- |
| `nLength` | The paper length (its height in portrait). |
| `nWidth` | The paper width. |

**Returns** `true` when both were set, `false` otherwise.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.SetPaperSize( 2970, 2100 ) = false then print "custom size refused"    ' 297 x 210 mm
```

### PaperLength

```freebasic
property PaperLength() as long
property PaperLength( byval nLength as long )
```

Reads or sets the paper length in tenths of a millimetre. A length that is set overrides the
length of [PaperSize](#papersize): it is for custom sizes and for printers that take paper of
any length.

**Returns** (getter) the length, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
print "length:"; pr.PaperLength / 10; " mm"     ' 279.4 for letter paper
```

### PaperWidth

```freebasic
property PaperWidth() as long
property PaperWidth( byval nWidth as long )
```

Reads or sets the paper width in tenths of a millimetre; set it whenever you set
[PaperLength](#paperlength).

**Returns** (getter) the width, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
print "width:"; pr.PaperWidth / 10; " mm"       ' 215.9 for letter paper
```

### GetPaperNames

```freebasic
function GetPaperNames() as ustring
```

Lists the names of the paper sizes the attached printer offers, such as `Letter` or `A4`, one per
line, with a carriage return and line feed between names.

**Returns** the names, or `""` when no printer is attached.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
print pr.GetPaperNames()
```

Microsoft Learn: [DeviceCapabilitiesW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-devicecapabilitiesw) with `DC_PAPERNAMES`

### Quality

```freebasic
property Quality() as long
property Quality( byval nMode as long )
```

Reads or sets the print quality: `DMRES_DRAFT` (-1), `DMRES_LOW` (-2), `DMRES_MEDIUM` (-3) or
`DMRES_HIGH` (-4), or a positive number of pixels per inch.

**Returns** (getter) the quality, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
pr.Quality = DMRES_DRAFT
```

### Scale

```freebasic
property Scale() as long
property Scale( byval nScale as long )
```

Reads or sets the scaling factor in percent. The printer draws everything at `nScale / 100` of
its size, so at 50 a letter page holds as much as a 17 × 22 inch page.

**Returns** (getter) the factor, normally 100, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
print "scale:"; pr.Scale; "%"
```

### Tray

```freebasic
property Tray() as long
property Tray( byval nTray as long )
```

Reads or sets the paper source: one of `DMBIN_UPPER` (1), `DMBIN_LOWER` (2), `DMBIN_MIDDLE`
(3), `DMBIN_MANUAL` (4), `DMBIN_ENVELOPE` (5), `DMBIN_ENVMANUAL` (6), `DMBIN_AUTO` (7),
`DMBIN_TRACTOR` (8), `DMBIN_SMALLFMT` (9), `DMBIN_LARGEFMT` (10), `DMBIN_LARGECAPACITY` (11),
`DMBIN_CASSETTE` (14) or `DMBIN_FORMSOURCE` (15), or a driver's own number from `DMBIN_USER`
(256) up.

**Returns** (getter) the source, or 0 when the settings cannot be read.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
if pr.Tray <> DMBIN_MANUAL then pr.Tray = DMBIN_MANUAL
```

### GetTrayNames

```freebasic
function GetTrayNames() as ustring
```

Declared in the class but given no body: a program that calls it compiles, then stops at the link
step with an undefined symbol. The names of the paper sources come from `DeviceCapabilitiesW`
with `DC_BINNAMES`, 24 characters per name.

**Example**

```freebasic
dim pr as CPrint
pr.AttachPrinter()
dim nBins as long = DeviceCapabilitiesW( pr.GetPrinterName(), NULL, DC_BINNAMES, NULL, NULL )
print nBins; " paper sources"       ' instead of GetTrayNames
```

Microsoft Learn: [DeviceCapabilitiesW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-devicecapabilitiesw) with `DC_BINNAMES`

### PrintBitmap

```freebasic
function PrintBitmap( byref wszDocName as wstring, byval hbmp as HBITMAP, byval bStretch as boolean = false, byval nStretchMode as long = InterpolationModeHighQualityBicubic ) as boolean
```

Prints a GDI bitmap on the attached printer as a print job named `wszDocName`, one page per
copy in [Copies](#copies). The image goes at the top-left corner of the printable area; with
`bStretch` it is stretched to fill the whole printable area, without keeping its proportions.
GDI+ is started and shut down for the call; the bitmap stays yours.

| Parameter | Meaning |
| --- | --- |
| `wszDocName` | The name the job has in the print queue. |
| `hbmp` | The bitmap to print. |
| `bStretch` | `true` stretches the image over the printable area. |
| `nStretchMode` | How GDI+ scales a stretched image: an `InterpolationMode*` value, `InterpolationModeHighQualityBicubic` (7) by default. |

**Returns** `true` when the job was sent, `false` when no printer is attached or printing could
not start.

**Example**

```freebasic
dim pr as CPrint
dim hbmp as HBITMAP = BitmapFromFile( "photo.jpg" )
if pr.ChoosePrinter( hwnd ) then pr.PrintBitmap( "Photo", hbmp, true )
DeleteObject( hbmp )
```

Microsoft Learn: [StartDocW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-startdocw)

### PrintBitmapToFile

```freebasic
function PrintBitmapToFile( byref wszDocName as wstring, byref wszOutputFileName as wstring, byval hbmp as HBITMAP, byval bStretch as boolean = false, byval nStretchMode as long = InterpolationModeHighQualityBicubic ) as boolean
```

Prints like [PrintBitmap](#printbitmap), but the printer driver writes its output to
`wszOutputFileName` instead of sending it to the device. What the file holds depends on the
driver: a PDF for Microsoft Print to PDF, the printer's own language for a physical printer.

| Parameter | Meaning |
| --- | --- |
| `wszDocName` | The name of the print job. |
| `wszOutputFileName` | The file to write. |
| `hbmp` | The bitmap to print. |
| `bStretch` | `true` stretches the image over the printable area. |
| `nStretchMode` | How GDI+ scales a stretched image. |

**Returns** `true` when the job was sent, `false` when no printer is attached or printing could
not start.

**Example**

```freebasic
dim pr as CPrint
dim hbmp as HBITMAP = BitmapFromFile( "chart.png" )
if pr.AttachPrinter( "Microsoft Print to PDF" ) then pr.PrintBitmapToFile( "Chart", "chart.pdf", hbmp )
DeleteObject( hbmp )
```

Microsoft Learn: [DOCINFOW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-docinfow)

### PrintRtf

```freebasic
function PrintRtf( byval hRichEdit as HWND, byref wszDocName as wstring ) as boolean
```

Prints the whole contents of a rich edit control, page by page. It always shows the Print
dialog first (with no owner window) and prints on the printer chosen there, which becomes the
attached printer; when the user cancels, nothing is printed.

Before printing it selects all the text in the control and makes the printer the control's
target device, so afterwards the text is selected and the control lays out its lines for the
printer's page width. Send `EM_SETTARGETDEVICE` with 0 and 0 to wrap at the window again. Only
the first copy prints pages: a [Copies](#copies) value above 1 adds no further copies. A page
that fails ends the job with `AbortDoc`.

| Parameter | Meaning |
| --- | --- |
| `hRichEdit` | The rich edit control. |
| `wszDocName` | The name of the print job. |

**Returns** `true` when every page printed, `false` when the dialog was cancelled or a page
failed.

**Example**

```freebasic
dim pr as CPrint
dim hRichEdit as HWND = GetDlgItem( hwnd, 101 )
if pr.PrintRtf( hRichEdit, "Letter" ) then SendMessageW( hRichEdit, EM_SETTARGETDEVICE, 0, 0 )
```

Microsoft Learn: [EM_FORMATRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/em-formatrange), [EM_SETTARGETDEVICE](https://learn.microsoft.com/en-us/windows/win32/controls/em-settargetdevice)

## See also

- [CMemBmp](CMemBmp), an off-screen bitmap with its own `PrintBitmap`
- [CGraphCtx](CGraphCtx), a graphic control whose `PrintImage` prints on the default printer
- [CGpGraphics](CGpGraphics) for drawing on the printer device context with GDI+
- [RichEdit](SysWin-RichEdit-Control) for the rich edit control `PrintRtf` prints
- [Common dialogs](SysWin-Common-Dialogs) for the other standard dialogs
- [sys/win/gui](SysWin-Gui)
