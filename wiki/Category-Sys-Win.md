[Home](Home) › [All Categories](Categories) › **sys/win**

# sys/win

> **In tiko.** Windows programming support written in tiko by José Roca: helpers over the Win32
> API, windows and dialogs, every common control, COM, rich edit, GDI+, Direct2D and WebView2.
> It ships with the toolchain as the `sys` package, source only: `#import "sys/win"` and nothing
> on the command line.

`sys/win` is **Windows-only**. Its modules build for `-target windows-x86_64`; importing one for
Linux or macOS stops with `sys/win is Windows-only` as the first error.

Each module also brings in the Windows headers it is built on, so the whole Win32 API (`HWND`,
`SendMessageW`, `WM_COMMAND`, `RECT` …) is there in any file that imports one.

## The modules

| Import | `using` name | What it holds |
| --- | --- | --- |
| `#import "sys/win"` | `win` | Helpers for windows, the display and DPI, fonts, the clipboard, bitmaps, paths, resources, common dialogs, the Internet and Unicode text |
| `#import "sys/win/gui"` | `gui` | `CWindow`, `CDialog` and the other window classes, and one namespace of functions per common control (`ListView`, `TreeView`, `Edit` …) |
| `#import "sys/win/com"` | `com` | `DVARIANT`, `DSafeArray`, `BSTRING`, `CDispInvoke` and COM helpers |
| `#import "sys/win/richedit"` | `richedit` | `CRichEditCtx`, the `RichEdit` functions and the Text Object Model classes |
| `#import "sys/win/gdiplus"` | `gdiplus` | The GDI+ classes: `CGpGraphics`, `CGpBitmap`, pens, brushes, paths, fonts, effects |
| `#import "sys/win/direct2d"` | `direct2d` | Direct2D factories, render targets, brushes and geometries, DirectWrite and WIC |
| `#import "sys/win/webview2"` | `webview2` | `CWebView2`, an Edge browser control in a window, and its event handlers |

The other modules import `sys/win` themselves; a program names each one it calls into.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"

using win, gui
```

`using` lets every name be written bare: `CenterWindow( hwnd )`. Without it, write the module
name first: `win.CenterWindow( hwnd )`. The control functions of `sys/win/gui` live in one
namespace per control and are always written with it, `ListView.AddColumn`, `Edit.GetText`,
after `using gui` as before.

## Things to know

**Wide strings.** Parameters that take text are `wstring ptr` or `byref wstring`: pass a literal,
a `ustring` or a `wstring` buffer. Functions that return text return a `ustring`.

**The W forms of Win32.** The Windows headers come in without `UNICODE`, so a bare Win32 name
such as `DrawText` or `SendMessage` is the ANSI (`A`) function and `LOGFONT` is the ANSI
structure. Either call the `W` names (`DrawTextW`, `SendMessageW`, `LOGFONTW`), as every page of
this category does, or build with `-d UNICODE`, or set it in your `tiko.toml` (a file cannot
`#define UNICODE` ahead of `#import "sys/win"`):

```toml
[target.main.defines]
UNICODE = "1"
```

The functions of `sys/win` itself are Unicode whichever you choose.

**One name, two meanings.** Where a helper has the name of a Win32 function, both are there and
the arguments pick: `GetWindowText( hwnd )` returns a `ustring`, while the Windows form still
takes a buffer and a length. A narrow literal passed to `SetWindowText` goes to the Unicode
helper, read as UTF-8.

**Rectangles as tuples.** Functions that measure a rectangle return the four edges as a tuple:
`var (l, t, r, b) = GetWindowRect( hwnd )`.

**Colours.** `RGB_*` (a `COLORREF` for GDI, red in the low byte) and `ARGB_*` (an opaque GDI+
colour) constants come with `sys/win/gui` and `sys/win/gdiplus`; see [Colours](SysWin-Colors).

**Examples.** Every function has a short example. The examples assume `hwnd` is your window,
`hDlg` a dialog and `hCtrl` a control; a page's full program at the top is complete and builds as
it stands with `tiko file.tiko`. More programs, from a button in a window to a WebView2
browser, are in the toolchain's `examples/win64/` folder.

## sys/win

| Page | What it does |
| --- | --- |
| [Program basics](SysWin-Program-Basics) | Reads the command line, shows message boxes, pumps messages and explains Windows errors. |
| [Windows version and system](SysWin-Windows-Version) | Reports the Windows version, build, edition and bitness, and the version of any file. |
| [System folders](SysWin-System-Folders) | Returns the paths of the Windows, system and temporary folders and of known folders. |
| [Window text and styles](SysWin-Window-Text-and-Styles) | Reads and sets a window's text, class, styles and icon, and redraws windows. |
| [Window size and position](SysWin-Window-Size-and-Position) | Reads and sets a window's position and size in pixels, and centres windows and controls. |
| [Finding windows](SysWin-Finding-Windows) | Finds a control's form, top-level windows, controls by id, and the windows of a process. |
| [Dark mode](SysWin-Dark-Mode) | Gives windows a dark title bar and rounded corners, and reads the light or dark setting. |
| [Display, screen and DPI](SysWin-Display-and-DPI) | Measures the desktop, the screen, the work area and monitors, and scales values for DPI. |
| [Units](SysWin-Units) | Converts between pixels, points, twips, HiMetric units, DIPs and dialog units. |
| [Fonts](SysWin-Fonts) | Creates fonts, reads the fonts Windows uses and changes the font of a window or control. |
| [Clipboard](SysWin-Clipboard) | Puts text and other data on the clipboard, reads it back and empties the clipboard. |
| [Bitmaps](SysWin-Bitmaps) | Creates, loads, saves and draws bitmaps, captures the screen and saves icons. |
| [Paths and files](SysWin-Paths-and-Files) | Splits paths into folder, name and extension, and detects UTF-16 and UTF-8 text. |
| [Resources](SysWin-Resources) | Reads raw data embedded in a program's resources into a string or out to a file. |
| [Common dialogs](SysWin-Common-Dialogs) | Shows the open, save, folder and colour dialogs, and opens Control Panel applets. |
| [Internet](SysWin-Internet) | Reads the connection state, combines and cleans URLs, and finds browsers and mail. |
| [Strings](SysWin-Strings) | Converts case by locale, translates between code pages, formats sizes and splits fields. |
| [Colours](SysWin-Colors) | Names the web colours twice: as `RGB_*` values for GDI and as `ARGB_*` values for GDI+. |

## sys/win/gui

Start with the [sys/win/gui overview](SysWin-Gui).

| Page | What it does |
| --- | --- |
| [CWindow](CWindow) | Creates a main window, adds controls to it and runs its message loop, scaled for DPI. |
| [CTabPage](CTabPage) | Creates a window that serves as one page of a tab control. |
| [CDialog](CDialog) | Creates dialog boxes in memory, fills them with controls and shows them modal or modeless. |
| [gui macros and helpers](SysWin-Gui-Procedures) | Extracts control ids, notification codes and pointers from window-message parameters. |
| [CMaskedEdit](CMaskedEdit) | Creates an edit control that accepts input only in a set shape, such as a phone number. |
| [CMemBmp](CMemBmp) | Creates an off-screen bitmap to draw on with GDI or GDI+, then save, print or display. |
| [CGraphCtx](CGraphCtx) | Creates a graphic control: a child window that keeps and repaints what you draw on it. |
| [File dialogs](SysWin-Gui-File-Dialogs) | Shows the Windows Open and Save dialogs and reads the files the user picked. |
| [CIFileDialogCustomize](CIFileDialogCustomize) | Adds check boxes, lists, buttons and other controls to an open or save dialog. |
| [File dialog events](SysWin-Gui-File-Dialog-Events) | Handles the events of an open or save dialog and of the controls added to it. |
| [Explorer browser](CExplorerBrowser) | Hosts a Windows Explorer folder view in your window and reports where the user navigates. |
| [Button](SysWin-Gui-Button) | Checks, clicks and labels push buttons, check boxes, radio buttons and split buttons. |
| [Label](SysWin-Gui-Label) | Sets and reads the text, icon, bitmap, cursor or metafile of a static control. |
| [Edit](SysWin-Gui-Edit) | Reads, changes, selects and formats the text of single-line and multiline edit controls. |
| [Combo](SysWin-Gui-Combo) | Adds, finds, selects and reads the items of a combo box, and sets its list and edit box. |
| [CBEx](SysWin-Gui-CBEx) | Inserts, reads and changes the items of a ComboBoxEx control, a combo box with images. |
| [ListBox](SysWin-Gui-ListBox) | Adds, finds, selects and reads the items of a list box control. |
| [ListView](SysWin-Gui-ListView) | Adds columns and rows to a list view and reads, selects, sorts and groups its items. |
| [TreeView](SysWin-Gui-TreeView) | Adds, finds, expands, selects and styles the items of a tree view control. |
| [Header](SysWin-Gui-Header) | Adds, reads, sizes and reorders the columns of a header control. |
| [TabCtl](SysWin-Gui-TabCtl) | Adds, selects, renames and removes the tabs of a tab control, and manages its tab pages. |
| [ToolBar](SysWin-Gui-ToolBar) | Adds, changes and queries the buttons of a toolbar control and the images they show. |
| [Rebar](SysWin-Gui-Rebar) | Inserts, moves, sizes and queries the bands of a rebar, the container for toolbars. |
| [Menu](SysWin-Gui-Menu) | Builds menu bars, drop-down and shortcut menus, and reads and changes their items. |
| [StatusBar](SysWin-Gui-StatusBar) | Divides a status bar into parts and sets and reads their text, icons and tooltips. |
| [ToolTip](SysWin-Gui-ToolTip) | Creates tooltips for controls and windows and sets their text, timing, colours and place. |
| [ProgBar](SysWin-Gui-ProgBar) | Sets the range, position, step, colours and state of a progress bar control. |
| [TrackBar](SysWin-Gui-TrackBar) | Reads and sets a trackbar's position, range, tick marks, selection and buddy windows. |
| [UpDown](SysWin-Gui-UpDown) | Reads and sets an up-down control's position, range, base, buddy window and acceleration. |
| [Pager](SysWin-Gui-Pager) | Sets what a pager control scrolls, and reads and sets its position, buttons and colours. |
| [MonthCal](SysWin-Gui-MonthCal) | Reads and sets the selected date, range, today and colours of a month calendar control. |
| [DTP](SysWin-Gui-DTP) | Reads and sets the date and time, range, format and drop-down calendar of a date picker. |
| [Animate](SysWin-Gui-Animate) | Opens, plays, stops and closes silent AVI clips in an animation control. |
| [HotKey](SysWin-Gui-HotKey) | Reads and sets the key combination in a hot key control, and the combinations it refuses. |
| [IPAddress](SysWin-Gui-IPAddress) | Reads, sets and clears the address in an IP address control, and limits its four fields. |
| [ScrollBar](SysWin-Gui-ScrollBar) | Shows, hides, enables and positions a scroll bar control, and reads and sets its range. |
| [SysLink](SysWin-Gui-SysLink) | Measures a SysLink control, reads and sets its links, and finds the link at a point. |

## sys/win/com

Start with the [sys/win/com overview](SysWin-Com).

| Page | What it does |
| --- | --- |
| [DVARIANT](DVARIANT) | Holds a COM `VARIANT` and converts it to and from tiko numbers, strings, dates and arrays. |
| [DSafeArray](DSafeArray) | Holds a COM `SAFEARRAY` and destroys it, with all its elements, when it goes out of scope. |
| [BSTRING](BSTRING) | Wraps a COM `BSTR` string and frees it when the variable goes out of scope. |
| [CInt96](CInt96) | Stores a 96-bit signed integer in a COM `DECIMAL` and does arithmetic on it. |
| [CDispInvoke](CDispInvoke) | Calls the methods and properties of a COM Automation object by name. |
| [COM procedures](SysWin-Com-Procedures) | Creates COM objects and handles GUIDs, reference counts, event connections and variants. |

## sys/win/richedit

Start with the [sys/win/richedit overview](SysWin-RichEdit).

| Page | What it does |
| --- | --- |
| [CRichEditCtx](CRichEditCtx) | Creates a rich edit control in a CWindow and reads and sets its options and formatting. |
| [CRichEditCtx: editing](CRichEditCtx-Editing) | Selects, finds, inserts and replaces text in a rich edit control, and undoes edits. |
| [CRichEditCtx: files, formatting and the document](CRichEditCtx-Document) | Loads, saves and formats rich edit text, and drives its Text Object Model document. |
| [RichEdit](SysWin-RichEdit-Control) | Sends rich edit messages to a control by its handle: text, selection, formatting and RTF. |
| [CTextFont2](CTextFont2) | Reads and sets the character formatting of rich edit text: font, size, colour and effects. |
| [CTextPara2](CTextPara2) | Reads and sets paragraph formatting in rich edit text: indents, spacing, tabs and lists. |
| [CTextRange2](CTextRange2) | Reads, edits, searches and formats a span of rich edit text through the Text Object Model. |
| [CTextSelection2](CTextSelection2) | Reads and changes the selection of a rich edit control through the Text Object Model. |
| [CTextRow](CTextRow) | Inserts table rows into rich edit text and reads and changes row and cell properties. |
| [CTextStory](CTextStory) | Reads and replaces the text of a rich edit story and gives ranges over it. |
| [CRichEditOleCallback](CRichEditOleCallback) | Answers a rich edit control's OLE questions, so that pictures and objects can be pasted. |
| [Text Object Model](SysWin-RichEdit-TOM) | Lists the Text Object Model interfaces and constants, and the base of the TOM classes. |

## sys/win/gdiplus

Start with the [sys/win/gdiplus overview](SysWin-GdiPlus).

| Page | What it does |
| --- | --- |
| [CGpGraphics](CGpGraphics) | Draws lines, shapes, text and images with GDI+ on a window, a device context or an image. |
| [CGpPen](CGpPen) | Draws lines and outlines in GDI+ with a colour or brush, a width, dashes and caps. |
| [GDI+ brushes](SysWin-GdiPlus-Brushes) | Fills shapes and text in GDI+ with a colour, a hatch pattern, an image or a gradient. |
| [GDI+ line caps](SysWin-GdiPlus-Line-Caps) | Draws arrow heads and shapes of your own at the ends of lines drawn with a GDI+ pen. |
| [Graphics paths](CGpGraphicsPath) | Builds shapes from lines, curves and text, and walks the points they are made of. |
| [CGpRegion](CGpRegion) | Combines rectangles and paths into areas for filling, clipping and hit-testing in GDI+. |
| [CGpMatrix](CGpMatrix) | Moves, scales, rotates and shears points with a GDI+ affine transformation matrix. |
| [GDI+ images](SysWin-GdiPlus-Images) | Loads, creates, edits and saves images with GDI+: bitmaps, metafiles and cached bitmaps. |
| [CGpImageAttributes](CGpImageAttributes) | Adjusts the colours of an image as it is drawn: colour matrices, gamma, keys, remapping. |
| [GDI+ effects](SysWin-GdiPlus-Effects) | Blurs, sharpens, tints and corrects the colours of bitmaps with the GDI+ effect classes. |
| [GDI+ fonts](SysWin-GdiPlus-Fonts) | Creates GDI+ fonts and font families and lists the fonts installed or loaded from files. |
| [CGpStringFormat](CGpStringFormat) | Sets how GDI+ lays out text in a rectangle: alignment, wrapping, trimming and tab stops. |
| [GDI+ procedures and types](SysWin-GdiPlus-Procedures) | Starts GDI+, builds colours and rectangles, and converts, saves and prints images. |

## sys/win/direct2d

Start with the [sys/win/direct2d overview](SysWin-Direct2D).

| Page | What it does |
| --- | --- |
| [CD2D1Factory](CD2D1Factory) | Creates the Direct2D factory that makes render targets, geometries and stroke styles. |
| [Direct2D stroke styles and multithreading](SysWin-Direct2D-Stroke-Styles) | Holds Direct2D stroke styles, reads back their settings and locks a multithreaded factory. |
| [CID2D1RenderTarget](CID2D1RenderTarget) | Draws shapes, bitmaps and text with Direct2D and creates the brushes and bitmaps it uses. |
| [Direct2D render targets](SysWin-Direct2D-Render-Targets) | Draws into windows, device contexts and bitmaps, and saves and restores drawing state. |
| [Direct2D brushes](SysWin-Direct2D-Brushes) | Paints shapes, lines and text in Direct2D with a colour, a gradient, a bitmap or an image. |
| [Direct2D bitmaps and colour contexts](SysWin-Direct2D-Bitmaps) | Holds pixel images for a Direct2D render target, and the colour profiles they are in. |
| [CID2D1Geometry](CID2D1Geometry) | Measures, hit-tests and reshapes Direct2D geometries; the base class of every shape. |
| [Direct2D geometries](SysWin-Direct2D-Geometries) | Builds Direct2D shapes from rectangles, ellipses, lines, curves and arcs. |
| [Direct2D helpers](SysWin-Direct2D-Helpers) | Builds the points, rectangles, colours, matrices and property records Direct2D calls take. |
| [Direct2D interfaces and types](SysWin-Direct2D-Interfaces) | Lists the Direct2D interfaces, structures and enumerations that sys/win/direct2d declares. |
| [DirectWrite interfaces and types](SysWin-DirectWrite-Interfaces) | Lists the DirectWrite interfaces, enumerations and structures of sys/win/direct2d. |
| [DXGI interfaces and types](SysWin-DXGI-Interfaces) | Lists the DXGI interfaces, enumerations and structures of sys/win/direct2d. |
| [WIC interfaces and types](SysWin-WIC-Interfaces) | Lists the WIC interfaces, enumerations and structures of sys/win/direct2d. |

## sys/win/webview2

Start with the [sys/win/webview2 overview](SysWin-WebView2).

| Page | What it does |
| --- | --- |
| [CWebView2](CWebView2) | Hosts a Microsoft Edge browser in a window and drives it from tiko code. |
| [WebView2 event handlers](SysWin-WebView2-Events) | Implements the WebView2 callback interfaces as classes to extend, one per event or result. |
| [WebView2 interfaces and types](SysWin-WebView2-Interfaces) | Lists the WebView2 interfaces, enumerations and structures that sys/win/webview2 declares. |
