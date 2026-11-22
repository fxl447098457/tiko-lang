[Home](Home) › [Function Finder](Function-Finder) › **Windows programming**

# Windows programming

The functions to build Win32 programs with windows, dialogs and common controls; draw with GDI+ and Direct2D; host COM and WebView2, grouped by what you want to do. The **From** column says what a program needs before it can call one:

- `sys/win`: `#import "sys/win"`, then `using win` to call it by its bare name.
- `sys/win/<Name>`: `#import "sys/win/<Name>"`, then `using <Name>` to call it by its bare name.

Jump to: [Start a Windows program](#start-a-windows-program) · [Measure, move and style windows](#measure-move-and-style-windows) · [Add controls](#add-controls) · [Show file, folder and print dialogs](#show-file-folder-and-print-dialogs) · [Read system information, folders, text and the clipboard](#read-system-information-folders-text-and-the-clipboard) · [Use fonts, colours and bitmaps](#use-fonts-colours-and-bitmaps) · [Edit rich text](#edit-rich-text) · [Draw with GDI+](#draw-with-gdi) · [Draw with Direct2D and DirectWrite](#draw-with-direct2d-and-directwrite) · [Call COM objects and use variants](#call-com-objects-and-use-variants) · [Show web pages in a window](#show-web-pages-in-a-window)

## Start a Windows program

| Function | What it does | From |
|---|---|---|
| [Program basics](SysWin-Program-Basics) | Reads the command line, shows message boxes, pumps messages and explains Windows errors. | `sys/win` |
| [CWindow](CWindow) | Creates a main window, adds controls to it and runs its message loop, scaled for DPI. | `sys/win/gui` |
| [CDialog](CDialog) | Creates dialog boxes in memory, fills them with controls and shows them modal or modeless. | `sys/win/gui` |
| [gui macros and helpers](SysWin-Gui-Procedures) | Extracts control ids, notification codes and pointers from window-message parameters. | `sys/win/gui` |

## Measure, move and style windows

| Function | What it does | From |
|---|---|---|
| [Window text and styles](SysWin-Window-Text-and-Styles) | Reads and sets a window's text, class, styles and icon, and redraws windows. | `sys/win` |
| [Window size and position](SysWin-Window-Size-and-Position) | Reads and sets a window's position and size in pixels, and centres windows and controls. | `sys/win` |
| [Finding windows](SysWin-Finding-Windows) | Finds a control's form, top-level windows, controls by id, and the windows of a process. | `sys/win` |
| [Dark mode](SysWin-Dark-Mode) | Gives windows a dark title bar and rounded corners, and reads the light or dark setting. | `sys/win` |
| [Display, screen and DPI](SysWin-Display-and-DPI) | Measures the desktop, the screen, the work area and monitors, and scales values for DPI. | `sys/win` |
| [Units](SysWin-Units) | Converts between pixels, points, twips, HiMetric units, DIPs and dialog units. | `sys/win` |

## Add controls

| Function | What it does | From |
|---|---|---|
| [CTabPage](CTabPage) | Creates a window that serves as one page of a tab control. | `sys/win/gui` |
| [CMaskedEdit](CMaskedEdit) | Creates an edit control that accepts input only in a set shape, such as a phone number. | `sys/win/gui` |
| [Button](SysWin-Gui-Button) | Checks, clicks and labels push buttons, check boxes, radio buttons and split buttons. | `sys/win/gui` |
| [Label](SysWin-Gui-Label) | Sets and reads the text, icon, bitmap, cursor or metafile of a static control. | `sys/win/gui` |
| [Edit](SysWin-Gui-Edit) | Reads, changes, selects and formats the text of single-line and multiline edit controls. | `sys/win/gui` |
| [Combo](SysWin-Gui-Combo) | Adds, finds, selects and reads the items of a combo box, and sets its list and edit box. | `sys/win/gui` |
| [CBEx](SysWin-Gui-CBEx) | Inserts, reads and changes the items of a ComboBoxEx control, a combo box with images. | `sys/win/gui` |
| [ListBox](SysWin-Gui-ListBox) | Adds, finds, selects and reads the items of a list box control. | `sys/win/gui` |
| [ListView](SysWin-Gui-ListView) | Adds columns and rows to a list view and reads, selects, sorts and groups its items. | `sys/win/gui` |
| [TreeView](SysWin-Gui-TreeView) | Adds, finds, expands, selects and styles the items of a tree view control. | `sys/win/gui` |
| [Header](SysWin-Gui-Header) | Adds, reads, sizes and reorders the columns of a header control. | `sys/win/gui` |
| [TabCtl](SysWin-Gui-TabCtl) | Adds, selects, renames and removes the tabs of a tab control, and manages its tab pages. | `sys/win/gui` |
| [ToolBar](SysWin-Gui-ToolBar) | Adds, changes and queries the buttons of a toolbar control and the images they show. | `sys/win/gui` |
| [Rebar](SysWin-Gui-Rebar) | Inserts, moves, sizes and queries the bands of a rebar, the container for toolbars. | `sys/win/gui` |
| [Menu](SysWin-Gui-Menu) | Builds menu bars, drop-down and shortcut menus, and reads and changes their items. | `sys/win/gui` |
| [StatusBar](SysWin-Gui-StatusBar) | Divides a status bar into parts and sets and reads their text, icons and tooltips. | `sys/win/gui` |
| [ToolTip](SysWin-Gui-ToolTip) | Creates tooltips for controls and windows and sets their text, timing, colours and place. | `sys/win/gui` |
| [ProgBar](SysWin-Gui-ProgBar) | Sets the range, position, step, colours and state of a progress bar control. | `sys/win/gui` |
| [TrackBar](SysWin-Gui-TrackBar) | Reads and sets a trackbar's position, range, tick marks, selection and buddy windows. | `sys/win/gui` |
| [UpDown](SysWin-Gui-UpDown) | Reads and sets an up-down control's position, range, base, buddy window and acceleration. | `sys/win/gui` |
| [Pager](SysWin-Gui-Pager) | Sets what a pager control scrolls, and reads and sets its position, buttons and colours. | `sys/win/gui` |
| [MonthCal](SysWin-Gui-MonthCal) | Reads and sets the selected date, range, today and colours of a month calendar control. | `sys/win/gui` |
| [DTP](SysWin-Gui-DTP) | Reads and sets the date and time, range, format and drop-down calendar of a date picker. | `sys/win/gui` |
| [Animate](SysWin-Gui-Animate) | Opens, plays, stops and closes silent AVI clips in an animation control. | `sys/win/gui` |
| [HotKey](SysWin-Gui-HotKey) | Reads and sets the key combination in a hot key control, and the combinations it refuses. | `sys/win/gui` |
| [IPAddress](SysWin-Gui-IPAddress) | Reads, sets and clears the address in an IP address control, and limits its four fields. | `sys/win/gui` |
| [ScrollBar](SysWin-Gui-ScrollBar) | Shows, hides, enables and positions a scroll bar control, and reads and sets its range. | `sys/win/gui` |
| [SysLink](SysWin-Gui-SysLink) | Measures a SysLink control, reads and sets its links, and finds the link at a point. | `sys/win/gui` |

## Show file, folder and print dialogs

| Function | What it does | From |
|---|---|---|
| [Common dialogs](SysWin-Common-Dialogs) | Shows the open, save, folder and colour dialogs, and opens Control Panel applets. | `sys/win` |
| [File dialogs](SysWin-Gui-File-Dialogs) | Shows the Windows Open and Save dialogs and reads the files the user picked. | `sys/win/gui` |
| [CIFileDialogCustomize](CIFileDialogCustomize) | Adds check boxes, lists, buttons and other controls to an open or save dialog. | `sys/win/gui` |
| [File dialog events](SysWin-Gui-File-Dialog-Events) | Handles the events of an open or save dialog and of the controls added to it. | `sys/win/gui` |
| [CExplorerBrowser](CExplorerBrowser) | Hosts a Windows Explorer folder view in your window and reports where the user navigates. | `sys/win/gui` |

## Read system information, folders, text and the clipboard

| Function | What it does | From |
|---|---|---|
| [Windows version and system](SysWin-Windows-Version) | Reports the Windows version, build, edition and bitness, and the version of any file. | `sys/win` |
| [System folders](SysWin-System-Folders) | Returns the paths of the Windows, system and temporary folders and of known folders. | `sys/win` |
| [Clipboard](SysWin-Clipboard) | Puts text and other data on the clipboard, reads it back and empties the clipboard. | `sys/win` |
| [Paths and files](SysWin-Paths-and-Files) | Splits paths into folder, name and extension, and detects UTF-16 and UTF-8 text. | `sys/win` |
| [Resources](SysWin-Resources) | Reads raw data embedded in a program's resources into a string or out to a file. | `sys/win` |
| [Internet](SysWin-Internet) | Reads the connection state, combines and cleans URLs, and finds browsers and mail. | `sys/win` |
| [Strings](SysWin-Strings) | Converts case by locale, translates between code pages, formats sizes and splits fields. | `sys/win` |

## Use fonts, colours and bitmaps

| Function | What it does | From |
|---|---|---|
| [Fonts](SysWin-Fonts) | Creates fonts, reads the fonts Windows uses and changes the font of a window or control. | `sys/win` |
| [Bitmaps](SysWin-Bitmaps) | Creates, loads, saves and draws bitmaps, captures the screen and saves icons. | `sys/win` |
| [Colours](SysWin-Colors) | Names the web colours twice: as `RGB_*` values for GDI and as `ARGB_*` values for GDI+. | `sys/win` |
| [CMemBmp](CMemBmp) | Creates an off-screen bitmap to draw on with GDI or GDI+, then save, print or display. | `sys/win/gui` |
| [CGraphCtx](CGraphCtx) | Creates a graphic control: a child window that keeps and repaints what you draw on it. | `sys/win/gui` |

## Edit rich text

| Function | What it does | From |
|---|---|---|
| [CRichEditCtx](CRichEditCtx) | Creates a rich edit control in a CWindow and reads and sets its options and formatting. | `sys/win/richedit` |
| [CRichEditCtx-Editing](CRichEditCtx-Editing) | Selects, finds, inserts and replaces text in a rich edit control, and undoes edits. | `sys/win/richedit` |
| [CRichEditCtx-Document](CRichEditCtx-Document) | Loads, saves and formats rich edit text, and drives its Text Object Model document. | `sys/win/richedit` |
| [RichEdit](SysWin-RichEdit-Control) | Sends rich edit messages to a control by its handle: text, selection, formatting and RTF. | `sys/win/richedit` |
| [CTextFont2](CTextFont2) | Reads and sets the character formatting of rich edit text: font, size, colour and effects. | `sys/win/richedit` |
| [CTextPara2](CTextPara2) | Reads and sets paragraph formatting in rich edit text: indents, spacing, tabs and lists. | `sys/win/richedit` |
| [CTextRange2](CTextRange2) | Reads, edits, searches and formats a span of rich edit text through the Text Object Model. | `sys/win/richedit` |
| [CTextSelection2](CTextSelection2) | Reads and changes the selection of a rich edit control through the Text Object Model. | `sys/win/richedit` |
| [CTextRow](CTextRow) | Inserts table rows into rich edit text and reads and changes row and cell properties. | `sys/win/richedit` |
| [CTextStory](CTextStory) | Reads and replaces the text of a rich edit story and gives ranges over it. | `sys/win/richedit` |
| [CRichEditOleCallback](CRichEditOleCallback) | Answers a rich edit control's OLE questions, so that pictures and objects can be pasted. | `sys/win/richedit` |
| [Text Object Model](SysWin-RichEdit-TOM) | Lists the Text Object Model interfaces and constants, and the base of the TOM classes. | `sys/win/richedit` |

## Draw with GDI+

| Function | What it does | From |
|---|---|---|
| [CGpGraphics](CGpGraphics) | Draws lines, shapes, text and images with GDI+ on a window, a device context or an image. | `sys/win/gdiplus` |
| [CGpPen](CGpPen) | Draws lines and outlines in GDI+ with a colour or brush, a width, dashes and caps. | `sys/win/gdiplus` |
| [GDI+ brushes](SysWin-GdiPlus-Brushes) | Fills shapes and text in GDI+ with a colour, a hatch pattern, an image or a gradient. | `sys/win/gdiplus` |
| [GDI+ line caps](SysWin-GdiPlus-Line-Caps) | Draws arrow heads and shapes of your own at the ends of lines drawn with a GDI+ pen. | `sys/win/gdiplus` |
| [CGpGraphicsPath](CGpGraphicsPath) | Builds shapes from lines, curves and text, and walks the points they are made of. | `sys/win/gdiplus` |
| [CGpRegion](CGpRegion) | Combines rectangles and paths into areas for filling, clipping and hit-testing in GDI+. | `sys/win/gdiplus` |
| [CGpMatrix](CGpMatrix) | Moves, scales, rotates and shears points with a GDI+ affine transformation matrix. | `sys/win/gdiplus` |
| [GDI+ images](SysWin-GdiPlus-Images) | Loads, creates, edits and saves images with GDI+: bitmaps, metafiles and cached bitmaps. | `sys/win/gdiplus` |
| [CGpImageAttributes](CGpImageAttributes) | Adjusts the colours of an image as it is drawn: colour matrices, gamma, keys, remapping. | `sys/win/gdiplus` |
| [GDI+ effects](SysWin-GdiPlus-Effects) | Blurs, sharpens, tints and corrects the colours of bitmaps with the GDI+ effect classes. | `sys/win/gdiplus` |
| [GDI+ fonts](SysWin-GdiPlus-Fonts) | Creates GDI+ fonts and font families and lists the fonts installed or loaded from files. | `sys/win/gdiplus` |
| [CGpStringFormat](CGpStringFormat) | Sets how GDI+ lays out text in a rectangle: alignment, wrapping, trimming and tab stops. | `sys/win/gdiplus` |
| [GDI+ procedures and types](SysWin-GdiPlus-Procedures) | Starts GDI+, builds colours and rectangles, and converts, saves and prints images. | `sys/win/gdiplus` |

## Draw with Direct2D and DirectWrite

| Function | What it does | From |
|---|---|---|
| [CD2D1Factory](CD2D1Factory) | Creates the Direct2D factory that makes render targets, geometries and stroke styles. | `sys/win/direct2d` |
| [Direct2D stroke styles and multithreading](SysWin-Direct2D-Stroke-Styles) | Holds Direct2D stroke styles, reads back their settings and locks a multithreaded factory. | `sys/win/direct2d` |
| [CID2D1RenderTarget](CID2D1RenderTarget) | Draws shapes, bitmaps and text with Direct2D and creates the brushes and bitmaps it uses. | `sys/win/direct2d` |
| [Direct2D render targets](SysWin-Direct2D-Render-Targets) | Draws into windows, device contexts and bitmaps, and saves and restores drawing state. | `sys/win/direct2d` |
| [Direct2D brushes](SysWin-Direct2D-Brushes) | Paints shapes, lines and text in Direct2D with a colour, a gradient, a bitmap or an image. | `sys/win/direct2d` |
| [Direct2D bitmaps and colour contexts](SysWin-Direct2D-Bitmaps) | Holds pixel images for a Direct2D render target, and the colour profiles they are in. | `sys/win/direct2d` |
| [CID2D1Geometry](CID2D1Geometry) | Measures, hit-tests and reshapes Direct2D geometries; the base class of every shape. | `sys/win/direct2d` |
| [Direct2D geometries](SysWin-Direct2D-Geometries) | Builds Direct2D shapes from rectangles, ellipses, lines, curves and arcs. | `sys/win/direct2d` |
| [Direct2D helpers](SysWin-Direct2D-Helpers) | Builds the points, rectangles, colours, matrices and property records Direct2D calls take. | `sys/win/direct2d` |
| [Direct2D interfaces and types](SysWin-Direct2D-Interfaces) | Lists the Direct2D interfaces, structures and enumerations that sys/win/direct2d declares. | `sys/win/direct2d` |
| [DirectWrite interfaces and types](SysWin-DirectWrite-Interfaces) | Lists the DirectWrite interfaces, enumerations and structures of sys/win/direct2d. | `sys/win/direct2d` |
| [DXGI interfaces and types](SysWin-DXGI-Interfaces) | Lists the DXGI interfaces, enumerations and structures of sys/win/direct2d. | `sys/win/direct2d` |
| [WIC interfaces and types](SysWin-WIC-Interfaces) | Lists the WIC interfaces, enumerations and structures of sys/win/direct2d. | `sys/win/direct2d` |

## Call COM objects and use variants

| Function | What it does | From |
|---|---|---|
| [DVARIANT](DVARIANT) | Holds a COM `VARIANT` and converts it to and from tiko numbers, strings, dates and arrays. | `sys/win/com` |
| [DSafeArray](DSafeArray) | Holds a COM `SAFEARRAY` and destroys it, with all its elements, when it goes out of scope. | `sys/win/com` |
| [BSTRING](BSTRING) | Wraps a COM `BSTR` string and frees it when the variable goes out of scope. | `sys/win/com` |
| [CInt96](CInt96) | Stores a 96-bit signed integer in a COM `DECIMAL` and does arithmetic on it. | `sys/win/com` |
| [CDispInvoke](CDispInvoke) | Calls the methods and properties of a COM Automation object by name. | `sys/win/com` |
| [COM procedures](SysWin-Com-Procedures) | Creates COM objects and handles GUIDs, reference counts, event connections and variants. | `sys/win/com` |

## Show web pages in a window

| Function | What it does | From |
|---|---|---|
| [CWebView2](CWebView2) | Hosts a Microsoft Edge browser in a window and drives it from tiko code. | `sys/win/webview2` |
| [WebView2 event handlers](SysWin-WebView2-Events) | Implements the WebView2 callback interfaces as classes to extend, one per event or result. | `sys/win/webview2` |
| [WebView2 interfaces and types](SysWin-WebView2-Interfaces) | Lists the WebView2 interfaces, enumerations and structures that sys/win/webview2 declares. | `sys/win/webview2` |

## See Also

- [sys/win guide](Category-Sys-Win)

---

[Home](Home) · [Function Finder](Function-Finder) · [Keyword Index](Keyword-Index)

<!-- Generated by tools/wikifinder/finder.py. Edit the data, not this page. -->
