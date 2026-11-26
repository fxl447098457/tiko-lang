[Home](Home) › [Function Finder](Function-Finder) › **Graphics and windows**

# Graphics and windows

The functions to draw on a graphics screen, read the mouse, build GUI controls for Windows, Linux and macOS, grouped by what you want to do. The **From** column says what a program needs before it can call one:

- **built-in**: nothing; it is always available.
- `vendor/tkControls/<Name>`: `#import "vendor/tkControls/<Name>"`, then `using <Name>` to call it by its bare name.
- `fbgfx.bi`: `#include "fbgfx.bi"`.

Jump to: [Open a graphics window](#open-a-graphics-window) · [Draw lines, shapes and pixels](#draw-lines-shapes-and-pixels) · [Draw text](#draw-text) · [Make colours](#make-colours) · [Create and inspect images](#create-and-inspect-images) · [Copy images to and from the screen](#copy-images-to-and-from-the-screen) · [Choose how Put combines pixels](#choose-how-put-combines-pixels) · [Load and save images](#load-and-save-images) · [Draw without flicker](#draw-without-flicker) · [Set the drawing area and coordinates](#set-the-drawing-area-and-coordinates) · [Read the mouse, keyboard and joystick](#read-the-mouse-keyboard-and-joystick) · [Run a program of controls](#run-a-program-of-controls) · [Take text, numbers and dates from the user](#take-text-numbers-and-dates-from-the-user) · [Add buttons and switches](#add-buttons-and-switches) · [Show lists and choices](#show-lists-and-choices) · [Add menus, toolbars and status bars](#add-menus-toolbars-and-status-bars) · [Split, scroll and lay out a window](#split-scroll-and-lay-out-a-window) · [Show messages, colour pickers and tooltips](#show-messages-colour-pickers-and-tooltips) · [Show progress and charts](#show-progress-and-charts) · [Print, preview and export reports](#print-preview-and-export-reports) · [Paint and support your own controls](#paint-and-support-your-own-controls)

## Open a graphics window

| Function | What it does | From |
|---|---|---|
| [ScreenRes](Screenres) | Opens a graphics window of a given width, height and colour depth. | built-in |
| [Screen](Screen-Graphics) | Opens a graphics mode by mode number, or picks the work and visible pages. | built-in |
| [WindowTitle](Windowtitle) | Sets the title of the graphics window. | built-in |
| [ScreenList](Screenlist) | Returns the fullscreen resolutions for a colour depth, one per call, then 0. | built-in |
| [ScreenInfo](Screeninfo) | Fills in the screen's width, height, depth and driver, or the desktop's if none is open. | built-in |
| [ScreenControl](Screencontrol) | Sets or reads graphics library settings, such as the driver or the window position. | built-in |
| [ScreenGLProc](Screenglproc) | Returns the address of an OpenGL procedure by name, or 0 if it is not found. | built-in |

## Draw lines, shapes and pixels

| Function | What it does | From |
|---|---|---|
| [PSet](Pset-Statement) | Plots one pixel, in the given colour or the current foreground colour. | built-in |
| [PReset](Preset) | Plots one pixel, in the given colour or the current background colour. | built-in |
| [Line](Line-Graphics) | Draws a line between two points, or a box or filled box with B or BF. | built-in |
| [Circle](Circle) | Draws a circle, ellipse or arc, optionally filled. | built-in |
| [Paint](Paint) | Fills the area enclosed by a border colour with a colour or a pattern. | built-in |
| [Draw](Draw) | Draws a figure from a string of pen commands such as "U10 R10". | built-in |
| [Point](Point) | Returns the colour of a pixel, or -1 if it is off the screen or image. | built-in |
| [PointCoord](Pointcoord) | Returns the x or y position of the Draw pen. | built-in |

## Draw text

| Function | What it does | From |
|---|---|---|
| [Draw String](Draw-String) | Draws text at a pixel position, on a transparent background, with an optional font. | built-in |

## Make colours

| Function | What it does | From |
|---|---|---|
| [RGB](Rgb) | Returns an opaque colour value from red, green and blue parts of 0 to 255. | built-in |
| [RGBA](Rgba) | Returns a colour value from red, green, blue and alpha parts of 0 to 255. | built-in |
| [Palette](Palette) | Sets or reads the colours of a palette mode, or restores the default palette. | built-in |

## Create and inspect images

| Function | What it does | From |
|---|---|---|
| [ImageCreate](Imagecreate) | Creates an image of a given size filled with one colour; returns 0 on failure. | built-in |
| [ImageDestroy](Imagedestroy) | Frees an image made by ImageCreate. | built-in |
| [ImageInfo](Imageinfo) | Fills in an image's width, height, bytes per pixel, pitch and pixel pointer. | built-in |
| [ImageConvertRow](Imageconvertrow) | Copies a row of pixels to another buffer, converting its colour depth. | built-in |

## Copy images to and from the screen

| Function | What it does | From |
|---|---|---|
| [Get](Get-Graphics) | Copies a rectangle of the screen or an image into an image buffer. | built-in |
| [Put](Put-Graphics) | Draws an image onto the screen or another image, with a choice of blending method. | built-in |

## Choose how Put combines pixels

| Function | What it does | From |
|---|---|---|
| [PSet](Pset-Graphics-Put) (Put method) | Copies source pixels over the destination unchanged, as a Put method. | built-in |
| [Trans](Trans) | Copies pixels with Put but skips the mask colour, magenta or index 0. | built-in |
| [Alpha](Alpha) | Blends pixels with Put by each pixel's alpha, or by one alpha value you give. | built-in |
| [Add](Add) | Adds source and destination colour values with Put, capped at 255. | built-in |
| [And](And-Graphics-Put) | Combines source and destination pixels with a bitwise And, as a Put method. | built-in |
| [Or](Or-Graphics-Put) | Combines source and destination pixels with a bitwise Or, as a Put method. | built-in |
| [Xor](Xor-Graphics-Put) | Combines source and destination pixels with a bitwise Xor, as a Put method. | built-in |
| [Custom](Custom) | Calls your own function for each pixel to combine source and destination in Put. | built-in |

## Load and save images

| Function | What it does | From |
|---|---|---|
| [BLoad](Bload) | Loads a BMP file or BSave data onto the screen or into memory. | built-in |
| [BSave](Bsave) | Saves memory or the screen to a file, as a BMP image if the name ends in .bmp. | built-in |

## Draw without flicker

| Function | What it does | From |
|---|---|---|
| [ScreenLock](Screenlock) | Stops screen updates while you draw, so the user never sees half a frame. | built-in |
| [ScreenUnlock](Screenunlock) | Resumes screen updates after ScreenLock and shows what was drawn. | built-in |
| [ScreenSet](Screenset) | Sets which page is drawn on and which page is shown. | built-in |
| [ScreenCopy](Screencopy) | Copies one graphics page onto another, by default the work page onto the shown one. | built-in |
| [PCopy](Pcopy) | Copies one graphics or text page onto another. | built-in |
| [Flip](Flip) | Shows the OpenGL back buffer, or copies a page as ScreenCopy does in other modes. | built-in |
| [ScreenSync](Screensync) | Waits for the display to finish drawing a frame, to reduce flicker. | built-in |
| [ScreenPtr](Screenptr) | Returns a pointer to the work page's pixels, or 0 if no graphics mode is set. | built-in |

## Set the drawing area and coordinates

| Function | What it does | From |
|---|---|---|
| [View](View-Graphics) | Sets the rectangle that drawing is clipped to, or resets it to the whole screen. | built-in |
| [Window](Window) | Sets the coordinate system mapped onto the current view. | built-in |
| [PMap](Pmap) | Converts a coordinate between the Window system and physical pixels. | built-in |

## Read the mouse, keyboard and joystick

| Function | What it does | From |
|---|---|---|
| [GetMouse](Getmouse) | Fills in the mouse position, wheel and buttons, or -1 in each if there is no mouse. | built-in |
| [SetMouse](Setmouse) | Moves the mouse pointer, shows or hides it, or keeps it inside the window. | built-in |
| [MultiKey](Multikey) | Returns -1 while the key with a given scancode is held down, or 0 if it is not. | built-in |
| [GetJoystick](Getjoystick) | Fills in a joystick's buttons and axis positions; returns 0 on success or 1. | built-in |
| [ScreenEvent](Screenevent) | Returns -1 if a mouse, keyboard or window event is waiting, and fetches it. | built-in |
| [Event](Event-Message-Data-From-Screenevent) | Holds one event fetched by ScreenEvent: its type and its key or mouse data. | `fbgfx.bi` |

## Run a program of controls

| Function | What it does | From |
|---|---|---|
| [tkApp](tkApp) | Runs a tkControls program: start-up, the event loop, forms, fonts and the theme. | `vendor/tkControls/tkApp` |
| [tkTheme](tkTheme) | Keeps the shared light and dark theme every tkControls control takes its colours from. | `vendor/tkControls/tkTheme` |
| [tkForms](tkForms) | Provides the base a designed form extends: a window, its layout, show and close. | `vendor/tkControls/tkForms` |
| [tkLanguage](tkLanguage) | Shows a designed program's captions in another language, from TOML catalogs. | `vendor/tkControls/tkLanguage` |

## Take text, numbers and dates from the user

| Function | What it does | From |
|---|---|---|
| [tkTextBox](tkTextBox) | Draws an editable text box, single-line or word-wrapped multiline, with its own editor. | `vendor/tkControls/tkTextBox` |
| [tkNumericUpDown](tkNumericUpDown) | Draws a numeric spinner: a typed value between minus and plus buttons, kept in range. | `vendor/tkControls/tkNumericUpDown` |
| [tkDatePicker](tkDatePicker) | Shows an editable date field with a calendar icon that drops down a month calendar. | `vendor/tkControls/tkDatePicker` |
| [tkCalendar](tkCalendar) | Draws a month calendar, one month or a grid of up to twelve, with drill-down to years. | `vendor/tkControls/tkCalendar` |
| [tkCodeEdit](tkCodeEdit) | Embeds a Scintilla code editor as a tkControls widget, with lexing, folding and IME. | `vendor/tkControls/tkCodeEdit` |
| [tkLabel](tkLabel) | Shows a line or block of text that the user can't edit. | `vendor/tkControls/tkLabel` |
| [tkSlider](tkSlider) | Draws a slider: a value, or a low and high pair, picked by dragging along a track. | `vendor/tkControls/tkSlider` |
| [tkTimePicker](tkTimePicker) | Shows an editable time field whose button drops down a chooser of hours and minutes. | `vendor/tkControls/tkTimePicker` |
| [tkDateTimePicker](tkDateTimePicker) | Shows one field holding a date and a time, with a calendar and time columns beside it. | `vendor/tkControls/tkDateTimePicker` |
| [tkTimePanel](tkTimePanel) | Draws a time chooser: a column each for the hours, minutes, seconds and AM/PM. | `vendor/tkControls/tkTimePanel` |
| [tkAutoComplete](tkAutoComplete) | Draws a text box whose typing narrows a dropped list of suggestions, or a search box. | `vendor/tkControls/tkAutoComplete` |

## Add buttons and switches

| Function | What it does | From |
|---|---|---|
| [tkButton](tkButton) | Draws a momentary command button with an optional glyph or image on either side. | `vendor/tkControls/tkButton` |
| [tkCheckBox](tkCheckBox) | Draws a two-state checkbox with an optional caption on either side of the box. | `vendor/tkControls/tkCheckBox` |
| [tkOptionButton](tkOptionButton) | Draws a radio button whose group allows at most one checked choice. | `vendor/tkControls/tkOptionButton` |
| [tkToggle](tkToggle) | Draws an on/off switch: a rounded track and a knob that marks the state. | `vendor/tkControls/tkToggle` |

## Show lists and choices

| Function | What it does | From |
|---|---|---|
| [tkListTree](tkListTree) | Shows a scrolling list of rows you paint that is also a tree, with columns and editing. | `vendor/tkControls/tkListTree` |
| [tkComboBox](tkComboBox) | Shows the current choice on a button that drops a scrolling list of the alternatives. | `vendor/tkControls/tkComboBox` |
| [tkSelectBar](tkSelectBar) | Draws a strip of text panels where exactly one is current, marked by a line beneath it. | `vendor/tkControls/tkSelectBar` |
| [tkTabBar](tkTabBar) | Draws a row of document tabs that scroll, close and reorder by drag. | `vendor/tkControls/tkTabBar` |
| [tkDataGrid](tkDataGrid) | Draws a data grid of typed columns, edited in place, sorted, filtered and totalled. | `vendor/tkControls/tkDataGrid` |
| [tkCheckedList](tkCheckedList) | Shows a list with a check box on each item, so several can be picked at once. | `vendor/tkControls/tkCheckedList` |
| [tkCheckedCombo](tkCheckedCombo) | Draws a combo button whose dropdown is a checked list of several picked values. | `vendor/tkControls/tkCheckedCombo` |
| [tkTokenBox](tkTokenBox) | Draws an input whose values are chips, typed or picked, each with a remove button. | `vendor/tkControls/tkTokenBox` |
| [tkChip](tkChip) | Draws a chip: a compact pill with a label and an optional avatar, glyph or remove button. | `vendor/tkControls/tkChip` |
| [tkChipGroup](tkChipGroup) | Draws a group of chips that wrap in rows, with single or multiple selection. | `vendor/tkControls/tkChipGroup` |
| [tkRating](tkRating) | Draws a row of stars or other shapes filled to a value, which the user can set. | `vendor/tkControls/tkRating` |

## Add menus, toolbars and status bars

| Function | What it does | From |
|---|---|---|
| [tkMenuBar](tkMenuBar) | Draws a window's menu bar, whose items drop down tkPopupMenu menus. | `vendor/tkControls/tkMenuBar` |
| [tkToolbar](tkToolbar) | Draws a toolbar of command, toggle, split and dropdown buttons that overflows to a menu. | `vendor/tkControls/tkToolbar` |
| [tkIconPanel](tkIconPanel) | Draws a row or column of icon-only buttons, toggles and separators. | `vendor/tkControls/tkIconPanel` |
| [tkStatusBar](tkStatusBar) | Draws a status bar of text panels, one of which stretches to fill the leftover width. | `vendor/tkControls/tkStatusBar` |
| [tkNavigator](tkNavigator) | Draws a record navigator: first, previous, the position, next, last, new and delete. | `vendor/tkControls/tkNavigator` |

## Split, scroll and lay out a window

| Function | What it does | From |
|---|---|---|
| [tkSplitter](tkSplitter) | Draws a draggable divider bar between two panes and reports where the user drags it. | `vendor/tkControls/tkSplitter` |
| [tkScrollPanel](tkScrollPanel) | Scrolls a page of ordinary child widgets that is taller than the space it is shown in. | `vendor/tkControls/tkScrollPanel` |
| [tkStack](tkStack) | Lays out controls one after another in a column or a row, the layout of a phone screen. | `vendor/tkControls/tkStack` |
| [tkVScrollBar](tkVScrollBar) | Draws a vertical scrollbar that you size, feed a range, and listen to. | `vendor/tkControls/tkVScrollBar` |
| [tkHScrollBar](tkHScrollBar) | Draws a horizontal scrollbar that you size, feed a range, and listen to. | `vendor/tkControls/tkHScrollBar` |
| [tkPanel](tkPanel) | Groups controls on a plain background, with an optional border. | `vendor/tkControls/tkPanel` |
| [tkGroupBox](tkGroupBox) | Frames a set of controls under a caption. | `vendor/tkControls/tkGroupBox` |
| [tkTabControl](tkTabControl) | Shows one page of controls at a time under a strip of tabs. | `vendor/tkControls/tkTabControl` |
| [tkLayout](tkLayout) | Keeps controls placed as the window resizes, by Anchor or Dock. | `vendor/tkControls/tkLayout` |

## Show messages, colour pickers and tooltips

| Function | What it does | From |
|---|---|---|
| [tkMessageBox](tkMessageBox) | Shows a themed modal message box and returns the id of the button that closed it. | `vendor/tkControls/tkMessageBox` |
| [tkColorPicker](tkColorPicker) | Shows a modal colour picker popup and returns the colour and alpha the user chose. | `vendor/tkControls/tkColorPicker` |
| [tkFileDialog](tkFileDialog) | Shows the system open, save and folder dialogs and returns the chosen paths. | `vendor/tkControls/tkFileDialog` |
| [tkTooltip](tkTooltip) | Shows an owner-drawn tooltip for a widget after the mouse rests on it. | `vendor/tkControls/tkTooltip` |
| [tkInfoBar](tkInfoBar) | Shows a message strip in the form's layout, with a severity, a message and actions. | `vendor/tkControls/tkInfoBar` |
| [tkToast](tkToast) | Shows short-lived notification cards stacked in a corner of a window. | `vendor/tkControls/tkToast` |

## Show progress and charts

| Function | What it does | From |
|---|---|---|
| [tkProgressBar](tkProgressBar) | Draws a horizontal or vertical progress bar, determinate or with a running marquee. | `vendor/tkControls/tkProgressBar` |
| [tkSpinner](tkSpinner) | Shows a small animation while something takes its time. | `vendor/tkControls/tkSpinner` |
| [tkChart](tkChart) | Draws line, column, HLOC and pie charts from series of labelled values. | `vendor/tkControls/tkChart` |
| [tkPicture](tkPicture) | Shows an image, scaled or clipped to its area. | `vendor/tkControls/tkPicture` |
| [tkBarcode](tkBarcode) | Draws 1D and 2D barcodes: EAN, UPC, Code 128, Code 39, QR, Data Matrix, PDF417, Aztec. | `vendor/tkControls/tkBarcode` |
| [tkBadge](tkBadge) | Draws a badge: a dot, a count, a short text or a presence mark, alone or on a control. | `vendor/tkControls/tkBadge` |
| [tkAvatar](tkAvatar) | Draws a person's avatar: their photo, or their initials on a colour of their own. | `vendor/tkControls/tkAvatar` |
| [tkAvatarGroup](tkAvatarGroup) | Draws a row of avatars, overlapping or apart, with a +N disc for the rest. | `vendor/tkControls/tkAvatarGroup` |

## Print, preview and export reports

| Function | What it does | From |
|---|---|---|
| [tkPrint](tkPrint) | Builds print documents: pages drawn once in points, then shown, printed or exported. | `vendor/tkControls/tkPrint` |
| [tkPrintPreview](tkPrintPreview) | Shows a print document's pages as paper, with zoom, columns and scrolling. | `vendor/tkControls/tkPrintPreview` |
| [tkPdf](tkPdf) | Writes a print document as a PDF file. | `vendor/tkControls/tkPdf` |
| [tkPrinter](tkPrinter) | Lists the printers and prints print documents on them. | `vendor/tkControls/tkPrinter` |
| [tkPrintDialog](tkPrintDialog) | Shows the Print and Page Setup dialogs, drawn the same on every system. | `vendor/tkControls/tkPrintDialog` |
| [tkReportViewer](tkReportViewer) | Shows a print document with a toolbar, a preview and a status bar. | `vendor/tkControls/tkReportViewer` |
| [tkReport](tkReport) | Lays out banded reports over rows of data, with group headers, footers and totals. | `vendor/tkControls/tkReport` |

## Paint and support your own controls

| Function | What it does | From |
|---|---|---|
| [tkHost](tkHost) | Runs every tkControls widget: SDL windows, the widget tree, input, timers and fonts. | `vendor/tkControls/tkHost` |
| [tkPaint](tkPaint) | Paints shapes, text and images for tkControls widgets on SDL_Renderer and SDL_ttf. | `vendor/tkControls/tkPaint` |
| [tkKeys](tkKeys) | Parses, formats and dispatches keyboard shortcuts for tkControls surfaces. | `vendor/tkControls/tkKeys` |
| [tkImage](tkImage) | Loads an image file once and draws it in any tkControls window. | `vendor/tkControls/tkImage` |
| [tkPopupMenu](tkPopupMenu) | Shows a popup menu of commands, separators, check marks and submenus. | `vendor/tkControls/tkPopupMenu` |
| [tkContextMenu](tkContextMenu) | Opens a menu when a widget is right-clicked. | `vendor/tkControls/tkContextMenu` |
| [tkTimer](tkTimer) | Calls a procedure every so many milliseconds. | `vendor/tkControls/tkTimer` |
| [tkColumnHeader](tkColumnHeader) | Draws a band of column headings with draggable dividers and one column taking the rest. | `vendor/tkControls/tkColumnHeader` |
| [tkScrollBar](tkScrollBar) | Runs the one scrollbar engine behind tkVScrollBar and tkHScrollBar. | `vendor/tkControls/tkScrollBar` |
| [tkFontList](tkFontList) | Lists the fonts installed on the machine by family, style and file. | `vendor/tkControls/tkFontList` |
| [tkTest](tkTest) | Drives tkControls self-tests by pushing real SDL input events and checking the results. | `vendor/tkControls/tkTest` |

## See Also

- [Screen functions](Category-Screen-Functions)
- [2D drawing functions](Category-2D-Drawing-Functions)
- [Graphics input functions](Category-User-Input-Functions-Graphics-Library)
- [Vendor packages](Vendor-Packages)
- [tkControls guide](Category-tkControls)

---

[Home](Home) · [Function Finder](Function-Finder) · [Keyword Index](Keyword-Index)

<!-- Generated by tools/wikifinder/finder.py. Edit the data, not this page. -->
