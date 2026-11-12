[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **CDialog**

# CDialog

Creates dialog boxes in memory, fills them with controls and shows them modal or modeless.

A `CDialog` builds a dialog from a template it writes in memory, so no resource file is needed:
[DialogNew](#dialognew) creates the empty dialog, hidden; [ControlAdd](#controladd) adds the
controls; [DialogShowModal](#dialogshowmodal) or [DialogShowModeless](#dialogshowmodeless) shows
it and installs your dialog procedure. Most members then work on a control by its **identifier**,
so a dialog procedure rarely needs a control handle.

**One object per dialog, alive as long as the dialog.** The dialog window keeps a pointer to its
`CDialog`, which [CDialogPtr](#cdialogptr) and the internal message handling read. Declare the
object where it outlives the window: in the function that shows a modal dialog, or in a scope
that lasts while a modeless one is open. The destructor does not destroy the window.

**The constructor does three things.** It fixes the dialog's font (Segoe UI 9 by default), loads
every common control class, and reads the desktop's scaling ratios once. Call
`SetProcessDpiAwareness` *before* the `dim`, or the ratios are those of an unaware process (1).
It also initialises COM for the thread, and the destructor uninitialises it.

**Units.** A dialog made with [DialogNew](#dialognew) measures in **dialog units**, which follow
the dialog's font: a horizontal unit is a quarter of the average character width, a vertical
unit an eighth of the character height. A dialog made with [DialogNewPixels](#dialognewpixels)
measures in pixels, but not every member scales the same way:

| Member | Dialog units ([DialogNew](#dialognew)) | Pixels ([DialogNewPixels](#dialognewpixels)) |
| --- | --- | --- |
| `DialogNewPixels` size, `ControlAdd`, `DialogSetClient`, `DialogSetViewPort`, `ScaleX` … | dialog units | **96-DPI units**, multiplied by the desktop's ratio |
| `DialogSetSize`, `DialogSetLoc`, `ControlSetLoc`, `ControlSetSize`, `ControlSetClient` | dialog units | physical pixels |
| every `…Get…` member | dialog units, rounded to whole units | physical pixels |
| `DialogNewPixels` `x`, `y` | — | dialog units (they go into the template) |

**The dialog procedure** has the usual Windows shape and returns `true` for a message it
handled, `false` otherwise:

```freebasic
function DlgProc( byval hDlg as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as INT_PTR
```

It gets `WM_INITDIALOG` with `lParam` pointing at the `CDialog`. To hand a value back for a
message whose result is not the return value, call [CBSetDlgMsgResult](#cbgetdlgmsgresult-cbsetdlgmsgresult)
and return `true`.

**Closing.** End a dialog by sending it `WM_CLOSE` and calling [DialogEnd](#dialogend) from the
`WM_CLOSE` handler, as the example does: `CDialog` re-enables the parent of a modal dialog when
the dialog receives `WM_CLOSE`, not when `DialogEnd` runs. `DialogEnd` destroys the window and
also posts `WM_QUIT`.

**What it handles for you.** Anchored controls move on `WM_SIZE`; the colours set with
[ControlSetColor](#controlsetcolor) answer the `WM_CTLCOLOR…` messages (your procedure does not
see those for coloured controls); a scrollable dialog scrolls; a stabilized dialog ignores the
close command. Fonts made with [FontNew](#fontnew) are yours to free with [FontEnd](#fontend);
the accelerator table, a loaded rich edit library and a class registered by the dialog are
released by the destructor.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A resizable modal dialog in dialog units: a name box that widens with the dialog, and two buttons
anchored to the bottom-right corner. **Greet** (also the Enter key) writes a greeting into the
caption; **Close**, Esc and the close box end the dialog.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_NAME = 101
const IDC_GREET = 102

declare function DlgProc( byval hDlg as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as INT_PTR

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pDlg as CDialog
    pDlg.DialogNew( NULL, "CDialog", -1, -1, 200, 70, WS_OVERLAPPEDWINDOW )
    pDlg.ControlAdd( "Label", -1, "Your name:", 10, 12, 45, 10 )
    pDlg.ControlAdd( "Edit", IDC_NAME, "", 60, 10, 130, 12 )
    pDlg.ControlAdd( "Button", IDC_GREET, "&Greet", 85, 50, 50, 14, BS_DEFPUSHBUTTON )
    pDlg.ControlAdd( "Button", IDCANCEL, "&Close", 140, 50, 50, 14 )
    pDlg.ControlAnchor( IDC_NAME, ANCHOR_WIDTH )
    pDlg.ControlAnchor( IDC_GREET, ANCHOR_BOTTOM_RIGHT )
    pDlg.ControlAnchor( IDCANCEL, ANCHOR_BOTTOM_RIGHT )
    pDlg.DialogShowModal( @DlgProc )
    return pDlg.DialogEndResult()
end function

function DlgProc( byval hDlg as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as INT_PTR
    dim pDlg as CDialog ptr = CDialogPtr( hDlg )
    select case uMsg
        case WM_INITDIALOG
            return true                       ' focus the first control
        case WM_COMMAND
            if CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                select case CBCTL( wParam, lParam )
                    case IDC_GREET
                        dim ustrName as ustring = pDlg->ControlGetText( IDC_NAME )
                        dim ustrCaption as ustring = "Hello, " & ustrName
                        pDlg->DialogSetText( ustrCaption )
                        return true
                    case IDCANCEL                 ' the Close button or Esc
                        pDlg->DialogSend( WM_CLOSE, 0, 0 )
                        return true
                end select
            end if
        case WM_CLOSE
            pDlg->DialogEnd( 0 )
    end select
    return false
end function

end main()
```

More dialog programs, mostly one per control, are in the toolchain's `examples/win64/` folder
under `CDialog Examples`.

## Members

**Creating and showing**

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Sets the dialog font, loads the common controls and reads the scaling ratios. |
| [Destructor](#destructor) | Releases the accelerator table, the rich edit library and a registered class. |
| [DialogNew](#dialognew) | Creates a hidden dialog measured in dialog units. |
| [DialogNewPixels](#dialognewpixels) | Creates a hidden dialog measured in pixels. |
| [RegisterClass](#registerclass) | Registers a window class for a dialog with its own class name. |
| [DialogTemplate](#dialogtemplate) | Builds the in-memory dialog template that `DialogNew` uses. |
| [ControlAdd](#controladd) | Creates a control in the dialog. |
| [DialogShowModal](#dialogshowmodal) | Shows the dialog and runs it until it is destroyed. |
| [DialogShowModeless](#dialogshowmodeless) | Shows the dialog and returns at once. |
| [DialogDoEvents](#dialogdoevents) | Processes one message: the pump for a modeless dialog. |
| [DialogEnd](#dialogend) | Destroys the dialog and records its result. |
| [DialogEndResult](#dialogendresult) | Returns the value passed to `DialogEnd`. |
| [hDialog](#hdialog) | Returns the dialog's window handle. |
| [IsModal](#ismodal) | Tells whether the dialog was shown modal. |
| [IsCustom](#iscustom) | Tells whether the dialog has its own window class. |
| [UsesPixels](#usespixels) | Reads or sets whether the members measure in pixels. |
| [UsesUnits](#usesunits) | Tells whether the members measure in dialog units. |

**The dialog window**

| Member | Does |
| --- | --- |
| [DialogShowState](#dialogshowstate) | Shows, hides, minimizes or maximizes the dialog. |
| [DialogMaximize](#dialogmaximize) | Maximizes the dialog. |
| [DialogMinimize](#dialogminimize) | Minimizes the dialog. |
| [DialogHide](#dialoghide) | Hides the dialog. |
| [DialogNormalize](#dialognormalize) | Shows the dialog at its normal size and position. |
| [DialogDisable](#dialogdisable) | Disables mouse and keyboard input to the dialog. |
| [DialogEnable](#dialogenable) | Enables the dialog again. |
| [DialogRedraw](#dialogredraw) | Repaints the dialog at once. |
| [DialogPost](#dialogpost) | Posts a message to the dialog. |
| [DialogSend](#dialogsend) | Sends a message to the dialog. |
| [DialogGetSize, DialogSetSize](#dialoggetsize-dialogsetsize) | Reads or sets the size of the dialog window. |
| [DialogGetWidth](#dialoggetwidth) | Returns the width of the dialog window. |
| [DialogGetHeight](#dialoggetheight) | Returns the height of the dialog window. |
| [DialogGetBounds](#dialoggetbounds) | Returns the visible frame of the dialog, without its drop shadow. |
| [DialogGetClient, DialogSetClient](#dialoggetclient-dialogsetclient) | Reads or sets the size of the client area. |
| [DialogGetClientWidth](#dialoggetclientwidth) | Returns the width of the client area. |
| [DialogGetClientHeight](#dialoggetclientheight) | Returns the height of the client area. |
| [DialogGetLoc, DialogSetLoc](#dialoggetloc-dialogsetloc) | Reads or sets the position of the dialog. |
| [DialogCenter](#dialogcenter) | Centres the dialog over a window or in the work area. |
| [DialogReposition](#dialogreposition) | Moves the dialog back inside the desktop. |
| [DialogForceVisibility](#dialogforcevisibility) | Brings back a dialog that is on no display. |
| [DialogGetText, DialogSetText](#dialoggettext-dialogsettext) | Reads or sets the caption. |
| [DialogGetUser, DialogSetUser](#dialoggetuser-dialogsetuser) | Reads or sets one of 100 user values. |
| [DialogGetFont](#dialoggetfont) | Returns the dialog's font. |
| [DialogGetFontFaceName](#dialoggetfontfacename) | Returns the face name of the dialog's font. |
| [DialogGetFontPointSize](#dialoggetfontpointsize) | Returns the point size of the dialog's font. |
| [DialogStabilize](#dialogstabilize) | Makes the dialog impossible to close from its frame. |
| [DialogNonStable](#dialognonstable) | Makes a stabilized dialog closeable again. |
| [IsDialogStabilized](#isdialogstabilized) | Tells whether the dialog is stabilized. |
| [IsDialogNonStable](#isdialognonstable) | Tells whether the dialog is closeable. |
| [GetDefId, SetDefId](#getdefid-setdefid) | Reads or sets the default push button. |
| [CBGetDlgMsgResult, CBSetDlgMsgResult](#cbgetdlgmsgresult-cbsetdlgmsgresult) | Reads or sets the result a dialog procedure hands back. |

**Fonts**

| Member | Does |
| --- | --- |
| [FontNew](#fontnew) | Creates a font scaled for the display. |
| [FontEnd](#fontend) | Deletes a font. |
| [ControlGetFont, ControlSetFont](#controlgetfont-controlsetfont) | Reads or sets the font of a control. |
| [ControlGetFontFaceName](#controlgetfontfacename) | Returns the face name of a control's font. |
| [ControlGetFontPointSize](#controlgetfontpointsize) | Returns the point size of a control's font. |

**Controls**

| Member | Does |
| --- | --- |
| [ControlHandle](#controlhandle) | Returns the handle of a control. |
| [ControlSetFocus](#controlsetfocus) | Moves the keyboard focus to a control. |
| [ControlDisable](#controldisable) | Disables a control. |
| [ControlEnable](#controlenable) | Enables a control. |
| [ControlHide](#controlhide) | Hides a control. |
| [ControlNormalize](#controlnormalize) | Shows a control. |
| [ControlShowState](#controlshowstate) | Changes how a control is shown. |
| [ControlKill](#controlkill) | Destroys a control. |
| [ControlRedraw](#controlredraw) | Repaints a control at once. |
| [ControlPost](#controlpost) | Posts a message to a control. |
| [ControlSend](#controlsend) | Sends a message to a control. |
| [ControlGetText, ControlSetText](#controlgettext-controlsettext) | Reads or sets the text of a control. |
| [ControlGetLoc, ControlSetLoc](#controlgetloc-controlsetloc) | Reads or sets the position of a control. |
| [ControlGetSize, ControlSetSize](#controlgetsize-controlsetsize) | Reads or sets the size of a control. |
| [ControlGetWidth](#controlgetwidth) | Returns the width of a control. |
| [ControlGetHeight](#controlgetheight) | Returns the height of a control. |
| [ControlGetClient, ControlSetClient](#controlgetclient-controlsetclient) | Reads the client size of a control, or sets its size. |
| [ControlGetClientWidth](#controlgetclientwidth) | Returns the width of a control's client area. |
| [ControlGetClientHeight](#controlgetclientheight) | Returns the height of a control's client area. |
| [ControlCenterHoriz](#controlcenterhoriz) | Centres a control horizontally in its parent. |
| [ControlCenterVert](#controlcentervert) | Centres a control vertically in its parent. |
| [ControlGetCheck, ControlSetCheck](#controlgetcheck-controlsetcheck) | Reads or sets the check state of a check box or radio button. |
| [ControlSetOption](#controlsetoption) | Checks one radio button of a group. |
| [ControlGetUser, ControlSetUser](#controlgetuser-controlsetuser) | Reads or sets one of ten user values kept for a control. |
| [GetUserDataItem](#getuserdataitem) | Returns where a control's user values are kept. |
| [MenuContext](#menucontext) | Shows a shortcut menu and returns the command chosen. |

**Colours**

| Member | Does |
| --- | --- |
| [ControlSetColor](#controlsetcolor) | Sets the text and background colours of a control. |
| [DialogSetColor](#dialogsetcolor) | Sets the background colour of the dialog. |
| [GetColorItem](#getcoloritem) | Returns where a window's colours are kept. |
| [DialogEnableRepaint](#dialogenablerepaint) | Turns the custom colours on or off. |
| [IsDialogRepaintDisabled](#isdialogrepaintdisabled) | Tells whether the custom colours are off. |
| [DialogDisableRepaintOnResize](#dialogdisablerepaintonresize) | Turns the custom colours off while the user moves or sizes the dialog. |
| [IsDialogRepaintDisabledOnResize](#isdialogrepaintdisabledonresize) | Tells whether that is set. |

**Images**

| Member | Does |
| --- | --- |
| [DialogSetIcon](#dialogseticon) | Loads an icon and sets it as the dialog's icon. |
| [DialogSetIconEx](#dialogseticonex) | Sets the big and small icons from handles. |
| [FindResourceType](#findresourcetype) | Returns the type of a resource in the program. |
| [ControlSetImage](#controlsetimage) | Puts an icon or bitmap resource in an image label. |
| [ControlSetImageX](#controlsetimagex) | Puts an icon or bitmap resource in an image label, sized to the label. |
| [ControlSetImgButton](#controlsetimgbutton) | Puts an icon or bitmap resource on a button. |
| [ControlSetImgButtonX](#controlsetimgbuttonx) | Puts an icon or bitmap resource on a button, sized to the button. |

**Units and scaling**

| Member | Does |
| --- | --- |
| [DialogUnitsToPixels](#dialogunitstopixels) | Converts dialog units to pixels. |
| [DialogUnitsToPixelsRatios](#dialogunitstopixelsratios) | Returns the pixels per dialog unit, both ways. |
| [DluToPixRX](#dlutopixrx) | Returns the pixels per horizontal dialog unit. |
| [DluToPixRY](#dlutopixry) | Returns the pixels per vertical dialog unit. |
| [PixelsToDialogUnits](#pixelstodialogunits) | Converts pixels to dialog units. |
| [PixelsToDialogUnitsRatios](#pixelstodialogunitsratios) | Returns the dialog units per pixel, both ways. |
| [PixToDluRX](#pixtodlurx) | Returns the horizontal dialog units per pixel. |
| [PixToDluRY](#pixtodlury) | Returns the vertical dialog units per pixel. |
| [RxRatio](#rxratio) | Returns the horizontal factor the dialog's units are scaled by. |
| [RyRatio](#ryratio) | Returns the vertical factor the dialog's units are scaled by. |
| [ScaleX](#scalex) | Converts a horizontal value in the dialog's units to pixels. |
| [ScaleY](#scaley) | Converts a vertical value in the dialog's units to pixels. |
| [UnScaleX](#unscalex) | Converts a horizontal pixel value to the dialog's units. |
| [UnScaleY](#unscaley) | Converts a vertical pixel value to the dialog's units. |
| [ScaleRect](#scalerect) | Converts a rectangle in the dialog's units to pixels. |
| [UnScaleRect](#unscalerect) | Converts a pixel rectangle to the dialog's units. |
| [SetWindowPosForDPI](#setwindowposfordpi) | Moves and sizes a window with values in the dialog's units. |
| [MoveWindowForDPI](#movewindowfordpi) | Moves and sizes a window with values in the dialog's units. |

**Layout, accelerators, scrolling**

| Member | Does |
| --- | --- |
| [ControlAnchor](#controlanchor) | Keeps a control at a fixed distance from edges of its parent as the dialog is resized. |
| [GetAnchorItem](#getanchoritem) | Returns where a control's anchor is kept. |
| [AdjustControls](#adjustcontrols) | Moves and sizes every anchored control now. |
| [AccelHandle](#accelhandle) | Returns the accelerator table in use. |
| [AccelAttach](#accelattach) | Uses an accelerator table you made. |
| [AddAccelerator](#addaccelerator) | Adds a keyboard shortcut to the table to be built. |
| [CreateAccelTable](#createacceltable) | Builds the accelerator table from the shortcuts added. |
| [DestroyAccelTable](#destroyacceltable) | Destroys the accelerator table and forgets the shortcuts. |
| [DialogSetViewPort](#dialogsetviewport) | Makes the dialog scrollable by shrinking its client area. |
| [IsDialogScrollable](#isdialogscrollable) | Tells whether the dialog is scrollable. |
| [DialogResetScrollBars](#dialogresetscrollbars) | Scrolls the contents back to the origin. |
| [DialogSetupScrollBars](#dialogsetupscrollbars) | Recomputes the scroll ranges from the client size. |
| [DialogOnVScroll](#dialogonvscroll) | Handles a `WM_VSCROLL` message. |
| [DialogOnHScroll](#dialogonhscroll) | Handles a `WM_HSCROLL` message. |
| [DialogOnSize](#dialogonsize) | Handles a `WM_SIZE` message for a scrollable dialog. |

## Reference

### Constructor

```freebasic
constructor( byref fontName as wstring = "Segoe UI", byval ptSize as long = 9, byval fontStyle as byte = 0, byval charset as byte = DEFAULT_CHARSET )
```

Creates the object, not the dialog. The font is written into every template the object makes,
so it becomes the dialog's font and, through [ControlAdd](#controladd), the font of its
controls; its weight is always normal.

The constructor also loads all the common control classes, calls `CoInitialize` for the thread
and stores the desktop's horizontal and vertical scaling ratios (`LOGPIXELSX / 96`,
`LOGPIXELSY / 96`), which the pixel members use from then on.

| Parameter | Meaning |
| --- | --- |
| `fontName` | The face name. |
| `ptSize` | The size in points. |
| `fontStyle` | Written into the template's italic flag: 0 for upright, nonzero for italic. |
| `charset` | A `…_CHARSET` value; `DEFAULT_CHARSET` follows the system locale. |

**Example**

```freebasic
dim pDlg as CDialog                               ' Segoe UI 9
dim pBig as CDialog = CDialog( "Segoe UI", 11 )
```

Microsoft Learn: [InitCommonControlsEx](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-initcommoncontrolsex)

### Destructor

```freebasic
destructor
```

Destroys the accelerator table, frees the rich edit library if [ControlAdd](#controladd) loaded
it, unregisters the window class if the object registered one, and calls `CoUninitialize`. The
dialog window itself is not destroyed: end it with [DialogEnd](#dialogend) before the object
goes out of scope.

**Example**

```freebasic
scope
    dim pDlg as CDialog
    pDlg.DialogNew( NULL, "Temporary", -1, -1, 100, 50 )
    DestroyWindow( pDlg.hDialog )
end scope                                         ' the destructor runs here
```

Microsoft Learn: [UnregisterClassW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-unregisterclassw)

### DialogNew

```freebasic
function DialogNew( byval hParent as HWND = HWND_DESKTOP, byref wszTitle as wstring, byval x as long = -1, byval y as long = -1, byval cx as long = 0, byval cy as long = 0, byval dwStyle as long = 0, byval dwExStyle as long = 0 ) as HWND
function DialogNew( byref wszClassName as wstring, byval hParent as HWND = HWND_DESKTOP, byref wszTitle as wstring, byval x as long = -1, byval y as long = -1, byval cx as long = 0, byval cy as long = 0, byval dwStyle as long = 0, byval dwExStyle as long = 0 ) as HWND
```

Creates the dialog, **hidden**, measured in dialog units, and makes dialog units the object's
unit. Add the controls, then show it with [DialogShowModal](#dialogshowmodal) or
[DialogShowModeless](#dialogshowmodeless).

`cx` and `cy` are the size of the **client area**: the dialog manager adds the caption and
borders. `x` and `y` are the position of the top-left corner (in screen coordinates for a dialog
without a parent); when both are -1 the dialog is created centred.

When `dwStyle` is 0 the dialog gets `DS_3DLOOK`, `DS_SETFONT`, `DS_MODALFRAME`,
`DS_NOFAILCREATE`, `WS_BORDER`, `WS_CLIPSIBLINGS`, `WS_DLGFRAME` and `WS_POPUP`: a caption with
**no system menu and no close box**, and a fixed size. Any other `dwStyle` is used with
`DS_3DLOOK`, `DS_NOFAILCREATE` and `DS_SETFONT` added; `WS_OVERLAPPEDWINDOW` gives a sizeable
dialog with a close box. `WS_VISIBLE` is always removed. A `dwExStyle` of 0 becomes
`WS_EX_LEFT or WS_EX_LTRREADING or WS_EX_RIGHTSCROLLBAR`.

The second form registers a window class named `wszClassName` for the dialog first (see
[RegisterClass](#registerclass)); if a class of that name is already registered in the program it
creates nothing and returns `NULL`. The class is unregistered by the destructor.

| Parameter | Meaning |
| --- | --- |
| `wszClassName` | The class name for a dialog with its own class. |
| `hParent` | The owner window, or `NULL` / `HWND_DESKTOP` for none. A modal dialog disables it while it runs. |
| `wszTitle` | The caption. |
| `x`, `y` | The position, or -1, -1 to centre. |
| `cx`, `cy` | The client size. |
| `dwStyle` | `WS_*` and `DS_*` styles, or 0 for the default. |
| `dwExStyle` | `WS_EX_*` styles, or 0 for the default. |

**Returns** the dialog handle, also kept in [hDialog](#hdialog), or `NULL` on failure.

**Example**

```freebasic
dim pDlg as CDialog
dim hNew as HWND = pDlg.DialogNew( hwnd, "Options", -1, -1, 220, 120, WS_OVERLAPPEDWINDOW )
```

Microsoft Learn: [CreateDialogIndirectParamW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createdialogindirectparamw)

### DialogNewPixels

```freebasic
function DialogNewPixels( byval hParent as HWND = HWND_DESKTOP, byref wszTitle as wstring, byval x as long = -1, byval y as long = -1, byval cx as long = 0, byval cy as long = 0, byval dwStyle as long = 0, byval dwExStyle as long = 0 ) as HWND
function DialogNewPixels( byref wszClassName as wstring, byval hParent as HWND = HWND_DESKTOP, byref wszTitle as wstring = "", byval x as long = -1, byval y as long = -1, byval cx as long = 0, byval cy as long = 0, byval dwStyle as long = 0, byval dwExStyle as long = 0 ) as HWND
```

Creates the dialog like [DialogNew](#dialognew), with the same styles and the same class-name
rule, but makes pixels the object's unit. `cx` and `cy` are the client size in **96-DPI units**:
they are multiplied by the desktop's scaling ratios, so `300, 200` gives a client area of 525 ×
350 pixels at 175 %. The dialog is centred when `x` and `y` are both -1 or the style has
`DS_CENTER`.

`x` and `y` themselves go into the dialog template unchanged, so Windows reads them as dialog
units; to place the dialog at a pixel position, create it centred and call
[DialogSetLoc](#dialoggetloc-dialogsetloc).

**Returns** the dialog handle, or `NULL` on failure.

**Example**

```freebasic
dim pDlg as CDialog
pDlg.DialogNewPixels( hwnd, "Pixels", -1, -1, 320, 240, WS_OVERLAPPEDWINDOW )
pDlg.ControlAdd( "Button", IDOK, "OK", 230, 200, 75, 25 )
```

Microsoft Learn: [CreateDialogIndirectParamW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createdialogindirectparamw)

### RegisterClass

```freebasic
function RegisterClass( byref wszClassName as const wstring ) as ATOM
```

Registers a window class for a dialog with its own class name, and marks the object as a custom
dialog ([IsCustom](#iscustom)). The class has the dialog extra bytes, an arrow cursor, no icon and
no background brush, and `CDialog`'s own window procedure. [DialogTemplate](#dialogtemplate) and
the class-name forms of `DialogNew` call it; you need it only to build a template yourself.

**Returns** the class atom, or 0 when `wszClassName` is empty or the class is already
registered.

**Example**

```freebasic
dim pDlg as CDialog
if pDlg.RegisterClass( "MyToolDialog" ) = 0 then print "not registered"
```

Microsoft Learn: [RegisterClassExW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerclassexw)

### DialogTemplate

```freebasic
function DialogTemplate( byref wszClassName as wstring, byref wszTitle as wstring, byval x as long = -1, byval y as long = -1, byval cx as long = 0, byval cy as long = 0, byval dwStyle as long = 0, byval dwExStyle as long = 0 ) as string
```

Returns an extended dialog template (`DLGTEMPLATEEX`) with no controls, as raw bytes in a
`string`, with the constructor's font. [DialogNew](#dialognew) passes it to Windows.

A `dwStyle` of 0 here means `WS_VISIBLE`, `WS_OVERLAPPEDWINDOW`, `WS_POPUP`, `WS_SYSMENU`,
`WS_CLIPSIBLINGS`, `DS_MODALFRAME`, `DS_NOFAILCREATE` and `DS_SETFONT`; `DS_SETFONT` is always added. `x = y = -1`
adds `DS_CENTER`. A non-empty `wszClassName` is registered on the way, through
[RegisterClass](#registerclass).

**Returns** the template bytes.

**Example**

```freebasic
dim pDlg as CDialog
dim sTemplate as string = pDlg.DialogTemplate( "", "Built by hand", -1, -1, 200, 100 )
dim hNew as HWND = CreateDialogIndirectParamW( GetModuleHandleW( NULL ), cast( LPCDLGTEMPLATEW, strptr( sTemplate ) ), hwnd, NULL, 0 )
```

Microsoft Learn: [DLGTEMPLATEEX](https://learn.microsoft.com/en-us/windows/win32/dlgbox/dlgtemplateex)

### ControlAdd

```freebasic
function ControlAdd( byref wszClassName as wstring, byval cId as LONG_PTR = 0, byref wszTitle as wstring = "", byval x as long = 0, byval y as long = 0, byval cx as long = 0, byval cy as long = 0, byval dwStyle as long = -1, byval dwExStyle as long = -1, byval lpParam as LONG_PTR = 0, byval pCallbackProc as WNDPROC = NULL ) as HWND
```

Creates a control as a child of the dialog. `x`, `y`, `cx` and `cy` are in dialog units, or in
96-DPI units for a pixel dialog (multiplied by the scaling ratios). The control gets the dialog's
font, except image buttons and image, frame, line, owner-drawn label, progress bar, trackbar,
up-down, scroll bar, size grip, pager and SysLink controls.

`wszClassName` is a Windows class name or one of the friendly names below, compared without
regard to case. A `dwStyle` of -1 takes the default in the table; `WS_CHILD` and `WS_VISIBLE`
are always added. A `dwExStyle` of -1 takes the default extended style: `WS_EX_CLIENTEDGE` for
edits, rich edits, list and combo boxes, tree and list views, calendars, IP address and hot-key
controls, `WS_EX_TRANSPARENT` for images, frames, lines and group boxes, otherwise none.

| `wszClassName` | Creates | Default style |
| --- | --- | --- |
| `Button` | Button | push button, text centred, tab stop |
| `CustomButton`, `OwnerDrawButton`, `ButtonOwnerDraw` | Button | `BS_OWNERDRAW` |
| `Option`, `RadioButton` | Button | `BS_AUTORADIOBUTTON` |
| `CheckBox` | Button | `BS_AUTOCHECKBOX` |
| `Check3State`, `CheckState` | Button | `BS_AUTO3STATE` |
| `GroupBox` | Button | `BS_GROUPBOX` |
| `ImgButton`, `IMGBUTTONX` | Button | push button with `BS_ICON` or `BS_BITMAP`; `wszTitle` names the image |
| `Label` | Static | `SS_LEFT`, `SS_NOTIFY`, `WS_GROUP` |
| `Image`, `ImageX` | Static | `SS_ICON` or `SS_BITMAP` for the resource named by `wszTitle`; `ImageX` stretches it |
| `CustomLabel`, `LabelOwnerDraw` | Static | `SS_OWNERDRAW` |
| `Frame`, `FrameWindow` | Static | `SS_BLACKFRAME`: a plain rectangle |
| `Line` | Static | `SS_ETCHEDFRAME` |
| `Edit`, `TextBox` | Edit | single line, `ES_AUTOHSCROLL` |
| `EditMultiline`, `MultilineTextBox` | Edit | multiline, vertical scroll bar, `ES_WANTRETURN` |
| `RichEdit`, `RichEdit50W` | RichEdit50W | multiline with both scroll bars; loads the rich edit library |
| `ComboBox` | ComboBox | `CBS_DROPDOWN`, sorted |
| `ComboBoxEx`, `ComboBoxEx32` | ComboBoxEx32 | `CBS_DROPDOWNLIST` |
| `ListBox` | ListBox | sorted, notifying, both scroll bars |
| `ListBoxMultiSelect`, `LBMultiSelect` | ListBox | as `ListBox`, plus `LBS_EXTENDEDSEL` |
| `ListView`, `SysListView32` | SysListView32 | report view, label editing |
| `TreeView`, `SysTreeView32` | SysTreeView32 | buttons and lines, also at the root |
| `Header`, `SysHeader32` | SysHeader32 | `HDS_HORZ`, `HDS_BUTTONS` |
| `Toolbar`, `ToolbarWindow32` | ToolbarWindow32 | flat, with tooltips |
| `Rebar`, `RebarWindow32` | ReBarWindow32 | `RBS_VARHEIGHT`, `RBS_BANDBORDERS` |
| `StatusBar`, `msctls_statusbar32` | msctls_statusbar32 | with a size grip |
| `Tab`, `TabControl`, `SysTabControl32` | SysTabControl32 | single row; `WS_EX_CONTROLPARENT` is always added |
| `ProgressBar`, `msctls_progress32` | msctls_progress32 | range 0 to 100 |
| `Trackbar`, `Slider`, `msctls_trackbar32` | msctls_trackbar32 | ticks and tooltips, range 0 to 100, page 10 |
| `UpDown`, `msctls_updown32` | msctls_updown32 | arrow keys, wrap, buddy integer; range set as 100 to 0, base 10 |
| `HScrollBar`, `VScrollBar` | Scrollbar | horizontal or vertical |
| `SizeGrip`, `SizeBox`, `SizeBar` | Scrollbar | a size grip, placed in the bottom-right corner |
| `DateTimePicker`, `SysDateTimePick32` | SysDateTimePick32 | short date; the calendar gets the dialog's font |
| `MonthCalendar`, `MonthCal`, `SysMonthCal32` | SysMonthCal32 | tab stop |
| `IPAddress`, `SysIPAddress32` | SysIPAddress32 | tab stop |
| `HotKey`, `msctls_hotkey32` | msctls_hotkey32 | tab stop |
| `Animate`, `Animation`, `SysAnimate32` | SysAnimate32 | `ACS_TRANSPARENT` |
| `SysLink` | SysLink | tab stop; needs common controls version 6 |
| `Pager`, `SysPager` | SysPager | `PGS_HORZ` |
| any other name | that class | `WS_CHILD or WS_VISIBLE` |

Passing exactly `BS_DEFPUSHBUTTON` or `BS_FLAT` for a `Button`, or exactly `WS_GROUP` for an
`Option`, gives the default style plus that flag; exactly `BS_OWNERDRAW` gives an owner-drawn
button with a tab stop.

A control of class Button whose style has the `BS_DEFPUSHBUTTON` bit (1) becomes the dialog's
default button, and the previous default is cleared. `BS_AUTOCHECKBOX` and `BS_AUTORADIOBUTTON`
share that bit, so a `CheckBox` or `Option` added later also takes over the default identifier,
and Enter then reports that control: call [SetDefId](#getdefid-setdefid) after the last control.

For `ImgButton`, `wszTitle` is `"#"` plus a resource number, a resource name, or a `.bmp` file
name. Whether the button shows an icon or a bitmap is taken from the program's resources, so for
a file pass `BS_BITMAP` in `dwStyle`. The image is loaded at its own size, or stretched to the
button when the name is passed as `IMGBUTTONX`.

`lpParam` is passed to `CreateWindowExW` as the creation parameter. `pCallbackProc` is not used.

| Parameter | Meaning |
| --- | --- |
| `wszClassName` | The class or friendly name. |
| `cId` | The control identifier, or -1 for a control you never address. |
| `wszTitle` | The control's text, or the image for image controls. |
| `x`, `y` | The position in the dialog's client area. |
| `cx`, `cy` | The size. |
| `dwStyle` | The style, or -1 for the default. |
| `dwExStyle` | The extended style, or -1 for the default. |
| `lpParam` | Creation data for the control. |
| `pCallbackProc` | Ignored. |

**Returns** the control handle, or `NULL` when `wszClassName` is empty or the control could not
be created.

**Example**

```freebasic
dim pDlg as CDialog
pDlg.DialogNew( NULL, "Controls", -1, -1, 200, 100, WS_OVERLAPPEDWINDOW )
pDlg.ControlAdd( "Label", -1, "Name:", 10, 12, 40, 10 )
dim hEdit as HWND = pDlg.ControlAdd( "Edit", 101, "", 55, 10, 135, 12 )
pDlg.ControlAdd( "Button", IDOK, "OK", 140, 80, 50, 14, BS_DEFPUSHBUTTON )
```

Microsoft Learn: [CreateWindowExW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createwindowexw)

### DialogShowModal

```freebasic
function DialogShowModal( byval pCallback as any ptr = NULL ) as INT_PTR
```

Shows the dialog and runs it until its window is destroyed, then returns. In order it shows the
dialog at its normal size, installs `pCallback` as the dialog procedure, sends `WM_INITDIALOG`
(`wParam` = the first tab-stop control, `lParam` = this object) and, when your procedure returns
`true`, moves the focus to that control; then it sends `WM_SIZE` so anchored controls settle,
disables the owner, and pumps messages with [DialogDoEvents](#dialogdoevents).

The owner is enabled again when the dialog receives `WM_CLOSE`.

**Returns** `S_OK` (0). The dialog's result is [DialogEndResult](#dialogendresult).

**Example**

```freebasic
function DlgProc( byval hDlg as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as INT_PTR
    if uMsg = WM_CLOSE then CDialogPtr( hDlg )->DialogEnd( 1 )
    return false
end function
dim pDlg as CDialog
pDlg.DialogNew( NULL, "Modal", -1, -1, 200, 100, WS_OVERLAPPEDWINDOW )
pDlg.DialogShowModal( @DlgProc )
print "ended with"; pDlg.DialogEndResult()
```

Microsoft Learn: [DialogProc](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nc-winuser-dlgproc)

### DialogShowModeless

```freebasic
function DialogShowModeless( byval pCallback as any ptr = NULL ) as INT_PTR
```

Shows the dialog, installs `pCallback`, sends `WM_INITDIALOG` and `WM_SIZE` as
[DialogShowModal](#dialogshowmodal) does, and returns at once without disabling the owner. The
program must then pump messages for as long as the dialog is open: call
[DialogDoEvents](#dialogdoevents) in a loop, or keep the dialog inside a program that already
has a message loop.

**Returns** `S_OK` (0).

**Example**

```freebasic
function ToolProc( byval hDlg as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as INT_PTR
    if uMsg = WM_CLOSE then CDialogPtr( hDlg )->DialogEnd()
    return false
end function
dim pDlg as CDialog
pDlg.DialogNew( NULL, "Modeless", -1, -1, 200, 100, WS_OVERLAPPEDWINDOW )
pDlg.DialogShowModeless( @ToolProc )
do
    pDlg.DialogDoEvents()
loop while IsWindow( pDlg.hDialog )
```

Microsoft Learn: [WM_INITDIALOG](https://learn.microsoft.com/en-us/windows/win32/dlgbox/wm-initdialog)

### DialogDoEvents

```freebasic
function DialogDoEvents( byval dwMilliseconds as DWORD = 1 ) as boolean
```

Takes one message off the thread's queue, if there is one, and handles it: the dialog's
accelerator table gets the first look, then the dialog manager (for the active window, so Tab,
Enter and Esc work), and otherwise the message is translated and dispatched. With an empty queue
it sleeps for `dwMilliseconds` instead. A loop around it runs a modeless dialog; it is also the
pump [DialogShowModal](#dialogshowmodal) uses.

**Returns** `true` when it handled a message, `false` when the queue was empty.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
while pDlg->DialogDoEvents( 0 ) : wend          ' drain the queue during a long job
```

Microsoft Learn: [IsDialogMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-isdialogmessagew)

### DialogEnd

```freebasic
function DialogEnd( byval nResult as long = 0 ) as INT_PTR
```

Records `nResult` for [DialogEndResult](#dialogendresult), destroys the dialog window and posts
`WM_QUIT` to the thread. The modal loop and a `DialogDoEvents` loop stop because the window is
gone; a `GetMessage` loop elsewhere in the program, such as [CWindow](CWindow)'s, receives the
`WM_QUIT` and ends too.

Call it from the `WM_CLOSE` handler, so that the owner of a modal dialog is enabled again first.

**Returns** `nResult`.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogEnd( IDOK )                         ' in the WM_CLOSE handler
```

Microsoft Learn: [DestroyWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroywindow)

### DialogEndResult

```freebasic
function DialogEndResult() as INT_PTR
```

Returns the value last passed to [DialogEnd](#dialogend), or 0 if it has not been called. Read it
once [DialogShowModal](#dialogshowmodal) returns.

**Example**

```freebasic
dim pDlg as CDialog
if pDlg.DialogEndResult() = IDOK then print "accepted"
```

### hDialog

```freebasic
property hDialog() as HWND
```

Returns the handle of the dialog window, or `NULL` before [DialogNew](#dialognew). The handle
stays in the object after the window is destroyed, so test it with `IsWindow`.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
SetWindowTextW( pDlg->hDialog, "Ready" )
```

### IsModal

```freebasic
function IsModal() as boolean
```

Returns `true` once the dialog has been shown with [DialogShowModal](#dialogshowmodal), `false`
for a modeless or not yet shown dialog.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->IsModal() then print "modal"
```

### IsCustom

```freebasic
function IsCustom() as boolean
```

Returns `true` when the dialog has a window class of its own, from a class-name form of
[DialogNew](#dialognew) or [RegisterClass](#registerclass).

**Example**

```freebasic
dim pDlg as CDialog
pDlg.DialogNew( "MyDialogClass", NULL, "Custom", -1, -1, 200, 100 )
print pDlg.IsCustom()                           ' true
```

### UsesPixels

```freebasic
property UsesPixels() as boolean
property UsesPixels( byval fUsePixels as boolean )
```

Reads whether the object measures in pixels (`true`, after [DialogNewPixels](#dialognewpixels))
or in dialog units (`false`, after [DialogNew](#dialognew)). Setting it changes how every later
call reads and returns sizes and positions; nothing already on screen moves.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->UsesPixels = true                         ' work in pixels for a moment
```

### UsesUnits

```freebasic
function UsesUnits() as boolean
```

Returns `true` when the object measures in dialog units: the opposite of
[UsesPixels](#usespixels).

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->UsesUnits() then print "dialog units"
```

### DialogShowState

```freebasic
function DialogShowState( byval showState as long ) as boolean
```

Calls `ShowWindow` on the dialog with `showState` (`SW_SHOW`, `SW_HIDE`, `SW_MINIMIZE` …).

**Returns** `true` if the dialog was visible before the call, `false` if it was hidden.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogShowState( SW_SHOWMINNOACTIVE )
```

Microsoft Learn: [ShowWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow)

### DialogMaximize

```freebasic
function DialogMaximize() as boolean
```

Maximizes the dialog (`SW_MAXIMIZE`). The dialog needs a maximize box in its style for the user
to restore it from the frame.

**Returns** `true` if the dialog was visible before.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogMaximize()
```

### DialogMinimize

```freebasic
function DialogMinimize() as boolean
```

Minimizes the dialog (`SW_MINIMIZE`).

**Returns** `true` if the dialog was visible before.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogMinimize()
```

### DialogHide

```freebasic
function DialogHide() as boolean
```

Hides the dialog (`SW_HIDE`). It keeps running; show it again with
[DialogNormalize](#dialognormalize).

**Returns** `true` if the dialog was visible before, `false` if it was already hidden.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogHide()
```

### DialogNormalize

```freebasic
function DialogNormalize() as boolean
```

Shows and activates the dialog at its normal size and position (`SW_SHOWNORMAL`), restoring it
from minimized or maximized.

**Returns** `true` if the dialog was visible before.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogNormalize()
```

### DialogDisable

```freebasic
function DialogDisable() as boolean
```

Disables mouse and keyboard input to the dialog and its controls.

**Returns** `true` if the dialog was already disabled.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogDisable()
```

Microsoft Learn: [EnableWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablewindow)

### DialogEnable

```freebasic
function DialogEnable() as boolean
```

Enables input to the dialog again.

**Returns** `true` if the dialog was disabled before.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogEnable()
```

### DialogRedraw

```freebasic
function DialogRedraw() as boolean
```

Invalidates the whole dialog, erases its background and repaints it before returning.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogRedraw()
```

Microsoft Learn: [RedrawWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-redrawwindow)

### DialogPost

```freebasic
function DialogPost( byval Msg as UINT, byval wPrm as LONG_PTR, byval lPrm as LONG_PTR ) as boolean
```

Posts a message to the dialog's queue and returns without waiting.

**Returns** `true` if the message was posted.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogPost( WM_COMMAND, MAKEWPARAM( IDOK, BN_CLICKED ), 0 )
```

Microsoft Learn: [PostMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-postmessagew)

### DialogSend

```freebasic
function DialogSend( byval Msg as UINT, byval wPrm as LONG_PTR, byval lPrm as LONG_PTR ) as boolean
```

Sends a message to the dialog and waits until it has been handled.

**Returns** whether the message's result was nonzero: a `boolean`, not the result itself. For a
message whose result you need, call `SendMessageW( pDlg->hDialog, … )`.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogSend( WM_CLOSE, 0, 0 )
```

Microsoft Learn: [SendMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessagew)

### DialogGetSize, DialogSetSize

```freebasic
function DialogGetSize( byref nWidth as long, byref nHeight as long ) as boolean
function DialogSetSize( byval nWidth as long, byval nHeight as long ) as boolean
```

`DialogGetSize` reads the size of the whole dialog window, caption and borders included, into
`nWidth` and `nHeight`. `DialogSetSize` resizes the window without moving it. Both are in dialog
units, or physical pixels for a pixel dialog (no DPI scaling here: use
[DialogSetClient](#dialoggetclient-dialogsetclient) for a size in 96-DPI units).

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as long w, h
if pDlg->DialogGetSize( w, h ) then pDlg->DialogSetSize( w + 20, h )
```

Microsoft Learn: [GetWindowRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowrect)

### DialogGetWidth

```freebasic
function DialogGetWidth() as long
```

Returns the width of the dialog window, in the object's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print "width:"; pDlg->DialogGetWidth()
```

### DialogGetHeight

```freebasic
function DialogGetHeight() as long
```

Returns the height of the dialog window, caption included, in the object's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print "height:"; pDlg->DialogGetHeight()
```

### DialogGetBounds

```freebasic
function DialogGetBounds() as RECT
```

Returns the visible frame of the dialog in screen coordinates: the window rectangle without the
invisible resize border and the drop shadow, as the Desktop Window Manager reports it. For a
dialog-unit dialog each edge is converted to dialog units. Read it once the dialog has been
shown: Windows reports the visible frame only after that.

**Returns** the rectangle, or all zeros when the DWM library cannot be loaded.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim rcFrame as RECT = pDlg->DialogGetBounds()
print "frame width:"; rcFrame.right - rcFrame.left
```

Microsoft Learn: [DwmGetWindowAttribute](https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/nf-dwmapi-dwmgetwindowattribute)

### DialogGetClient, DialogSetClient

```freebasic
function DialogGetClient( byref nWidth as long, byref nHeight as long ) as boolean
function DialogSetClient( byval nWidth as long, byval nHeight as long ) as boolean
```

`DialogGetClient` reads the size of the client area. `DialogSetClient` resizes the dialog so that
its client area has the size given, allowing for its caption, borders, a menu bar that wraps and
scroll bars; the dialog does not move or activate.

For a pixel dialog, `DialogGetClient` returns physical pixels while `DialogSetClient` takes
**96-DPI units** and multiplies them by the scaling ratios.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogSetClient( 250, 140 )
```

Microsoft Learn: [AdjustWindowRectEx](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-adjustwindowrectex)

### DialogGetClientWidth

```freebasic
function DialogGetClientWidth() as long
```

Returns the width of the client area, in the object's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print "client width:"; pDlg->DialogGetClientWidth()
```

Microsoft Learn: [GetClientRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getclientrect)

### DialogGetClientHeight

```freebasic
function DialogGetClientHeight() as long
```

Returns the height of the client area, in the object's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print "client height:"; pDlg->DialogGetClientHeight()
```

### DialogGetLoc, DialogSetLoc

```freebasic
function DialogGetLoc( byref nLeft as long, byref nTop as long ) as boolean
function DialogSetLoc( byval nLeft as long, byval nTop as long ) as boolean
```

`DialogGetLoc` reads the top-left corner of the dialog; `DialogSetLoc` moves the dialog there
without resizing it. Both are in dialog units, or physical pixels for a pixel dialog.

For a dialog without an owner both use screen coordinates. For a dialog that has an owner,
`DialogGetLoc` measures from the owner's client area while `DialogSetLoc` still places the
dialog in screen coordinates.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as long x, y
if pDlg->DialogGetLoc( x, y ) then pDlg->DialogSetLoc( x + 10, y + 10 )
```

Microsoft Learn: [SetWindowPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos)

### DialogCenter

```freebasic
sub DialogCenter( byval hwndParent as HWND = NULL )
```

Centres the dialog over `hwndParent`, or in the work area of the primary display when it is
`NULL`, keeping it inside the work area. The size and Z order do not change. Call it after the
last change of size, as a scrollable dialog does after [DialogSetViewPort](#dialogsetviewport).

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogCenter( hwnd )
```

Microsoft Learn: [SystemParametersInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow) with `SPI_GETWORKAREA`

### DialogReposition

```freebasic
function DialogReposition() as boolean
```

Sends the dialog `DM_REPOSITION`, which moves a top-level dialog so that it fits on the desktop.

**Returns** the message's result, which carries no information (`false`).

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogReposition()
```

Microsoft Learn: [DM_REPOSITION](https://learn.microsoft.com/en-us/windows/win32/dlgbox/dm-reposition)

### DialogForceVisibility

```freebasic
sub DialogForceVisibility
```

Brings back a dialog that is on no display at all, by centring it in the work area of the display
nearest to where it was. A dialog that is at least partly on a display is left alone. Call it
after restoring a saved position, which can be off-screen once a monitor is unplugged.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogForceVisibility()
```

Microsoft Learn: [MonitorFromRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-monitorfromrect)

### DialogGetText, DialogSetText

```freebasic
function DialogGetText() as ustring
function DialogSetText( byval pwszText as wstring ptr ) as boolean
```

Reads or sets the dialog's caption.

**Returns** the caption; `DialogSetText` returns `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim ustrCaption as ustring = pDlg->DialogGetText() & " (saved)"
pDlg->DialogSetText( ustrCaption )
```

Microsoft Learn: [SetWindowTextW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowtextw)

### DialogGetUser, DialogSetUser

```freebasic
function DialogGetUser( byval idx as long ) as LONG_PTR
sub DialogSetUser( byval idx as long, byval newValue as LONG_PTR )
```

Reads or stores one of 100 values the object keeps for your own use, numbered 0 to 99: a counter,
a handle, a pointer. An index outside that range is ignored by `DialogSetUser` and reads as 0.

**Returns** the stored value, 0 if none.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogSetUser( 0, pDlg->DialogGetUser( 0 ) + 1 )   ' count the clicks
```

### DialogGetFont

```freebasic
function DialogGetFont() as HFONT
```

Returns the dialog's font, made from the constructor's settings. The dialog owns it: do not
delete it.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
SendMessageW( hCtrl, WM_SETFONT, cast( WPARAM, pDlg->DialogGetFont() ), true )
```

Microsoft Learn: [WM_GETFONT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-getfont)

### DialogGetFontFaceName

```freebasic
function DialogGetFontFaceName() as ustring
```

Returns the face name of the dialog's font, `"Segoe UI"` by default.

**Returns** the name, or `""` if the dialog has no font.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->DialogGetFontFaceName()
```

### DialogGetFontPointSize

```freebasic
function DialogGetFontPointSize() as long
```

Returns the size of the dialog's font in points, worked out from its height and the dialog's DPI
(9 by default).

**Returns** the size, or 0 if the dialog has no font.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->DialogGetFontPointSize(); " pt"
```

### DialogStabilize

```freebasic
function DialogStabilize() as boolean
```

Makes the dialog impossible to close from its frame: removes **Close** and the separator above it
from the system menu, which also greys the close box, and from then on ignores the close command
(Alt+F4, the close box). Your program can still end the dialog with [DialogEnd](#dialogend). Use
it while the dialog must not be interrupted.

**Returns** `true` on success; `false` when the dialog has no system menu, as with the default
[DialogNew](#dialognew) style.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogStabilize()                           ' during a long copy
```

Microsoft Learn: [GetSystemMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmenu)

### DialogNonStable

```freebasic
function DialogNonStable() as boolean
```

Undoes [DialogStabilize](#dialogstabilize): restores the standard system menu and lets the close
command through again.

**Returns** `true`.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogNonStable()
```

### IsDialogStabilized

```freebasic
function IsDialogStabilized() as boolean
```

Returns `true` while the dialog is stabilized.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->IsDialogStabilized() then print "busy"
```

### IsDialogNonStable

```freebasic
function IsDialogNonStable() as boolean
```

Returns `true` while the dialog is closeable: the opposite of
[IsDialogStabilized](#isdialogstabilized).

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->IsDialogNonStable() then print "closeable"
```

### GetDefId, SetDefId

```freebasic
function GetDefId() as INT_PTR
function SetDefId( byval cId as long ) as boolean
```

`GetDefId` returns the identifier of the dialog's default push button, the one Enter presses.
`SetDefId` clears the current default and makes `cId` the default. 

**Returns** the identifier, 0 when there is none; `SetDefId` returns `true`.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->GetDefId() <> IDOK then pDlg->SetDefId( IDOK )
```

Microsoft Learn: [DM_SETDEFID](https://learn.microsoft.com/en-us/windows/win32/dlgbox/dm-setdefid)

### CBGetDlgMsgResult, CBSetDlgMsgResult

```freebasic
function CBGetDlgMsgResult() as LONG_PTR
function CBSetDlgMsgResult( byval result as LONG_PTR ) as LONG_PTR
```

A dialog procedure returns only `true` or `false`; a message that needs a result of its own, such
as a notification answered through `WM_NOTIFY`, takes it from the dialog's message-result slot.
`CBSetDlgMsgResult` stores `result` there and `CBGetDlgMsgResult` reads it. Set it immediately
before the procedure returns `true`, since a call that sends the dialog another message can
overwrite it.

`WM_INITDIALOG`, `WM_CTLCOLOR…`, `WM_COMPAREITEM`, `WM_VKEYTOITEM`, `WM_CHARTOITEM` and
`WM_QUERYDRAGICON` are the exceptions: for those the procedure's return value is the result.

**Returns** the value stored; `CBSetDlgMsgResult` returns the previous one.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->CBSetDlgMsgResult( CDRF_NOTIFYITEMDRAW )   ' then: return true
```

Microsoft Learn: [SetWindowLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowlongptrw) with `DWLP_MSGRESULT`

### FontNew

```freebasic
function FontNew( byref wszFaceName as wstring, byval lPointSize as long, byval lWeight as long = 0, byval bItalic as ubyte = false, byval bUnderline as ubyte = false, byval bStrikeOut as ubyte = false, byval bCharSet as ubyte = DEFAULT_CHARSET ) as HFONT
```

Creates a font of `lPointSize` points for the screen's DPI, ready for
[ControlSetFont](#controlgetfont-controlsetfont). The font is yours: delete it with
[FontEnd](#fontend) once no control uses it.

| Parameter | Meaning |
| --- | --- |
| `wszFaceName` | The face name. |
| `lPointSize` | The size in points. |
| `lWeight` | 0 to 1000: `FW_NORMAL` (400), `FW_BOLD` (700) …; 0 is the default weight. |
| `bItalic`, `bUnderline`, `bStrikeOut` | Nonzero for each effect. |
| `bCharSet` | A `…_CHARSET` value; use `SYMBOL_CHARSET` for symbol fonts such as Marlett. |

**Returns** the font, or `NULL` on failure.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim hBold as HFONT = pDlg->FontNew( "Segoe UI", 9, FW_BOLD )
```

Microsoft Learn: [CreateFontIndirectW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createfontindirectw)

### FontEnd

```freebasic
sub FontEnd( byval hFont as HFONT )
```

Deletes a font made with [FontNew](#fontnew). Give the controls that used it another font first.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim hBold as HFONT = pDlg->FontNew( "Segoe UI", 9, FW_BOLD )
pDlg->FontEnd( hBold )
```

Microsoft Learn: [DeleteObject](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deleteobject)

### ControlGetFont, ControlSetFont

```freebasic
function ControlGetFont( byval cId as long ) as HFONT
sub ControlSetFont( byval cId as long, byval hFont as HFONT, byval fRedraw as boolean = true )
```

`ControlGetFont` returns the font control `cId` draws with. `ControlSetFont` gives it `hFont`
and, when `fRedraw` is `true`, repaints it. The control does not take ownership: keep `hFont`
alive while it is in use and delete it yourself afterwards. The font the control had before is
not deleted.

**Returns** the font, `NULL` for the system font.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim hMono as HFONT = pDlg->FontNew( "Consolas", 10 )
pDlg->ControlSetFont( 101, hMono )
```

Microsoft Learn: [WM_SETFONT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-setfont)

### ControlGetFontFaceName

```freebasic
function ControlGetFontFaceName( byval cId as long ) as ustring
```

Returns the face name of the font control `cId` draws with.

**Returns** the name, or `""` when the control has no font of its own.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->ControlGetFontFaceName( 101 )
```

### ControlGetFontPointSize

```freebasic
function ControlGetFontPointSize( byval cId as long ) as long
```

Returns the size in points of the font control `cId` draws with.

**Returns** the size, or 0 when the control has no font of its own.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->ControlGetFontPointSize( 101 ); " pt"
```

### ControlHandle

```freebasic
function ControlHandle( byval cId as long ) as HWND
```

Returns the handle of control `cId`. Like every member that takes an identifier, it looks only at
the dialog's direct children, not at controls inside a tab page or another child window.

**Returns** the handle, or `NULL` when there is no such control.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim hList as HWND = pDlg->ControlHandle( 101 )
```

Microsoft Learn: [GetDlgItem](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getdlgitem)

### ControlSetFocus

```freebasic
sub ControlSetFocus( byval cId as long )
```

Moves the keyboard focus to control `cId` the way the dialog manager does when the user presses
Tab, which also keeps the default button up to date.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlSetFocus( 101 )
```

Microsoft Learn: [WM_NEXTDLGCTL](https://learn.microsoft.com/en-us/windows/win32/dlgbox/wm-nextdlgctl)

### ControlDisable

```freebasic
function ControlDisable( byval cId as long ) as boolean
```

Disables control `cId`: it is greyed and takes no input.

**Returns** `true` if it was already disabled.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlDisable( IDOK )
```

Microsoft Learn: [EnableWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablewindow)

### ControlEnable

```freebasic
function ControlEnable( byval cId as long ) as boolean
```

Enables control `cId` again.

**Returns** `true` if it was disabled before.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlEnable( IDOK )
```

### ControlHide

```freebasic
function ControlHide( byval cId as long ) as boolean
```

Hides control `cId`.

**Returns** `true` if it was visible before.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlHide( 101 )
```

Microsoft Learn: [ShowWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow)

### ControlNormalize

```freebasic
function ControlNormalize( byval cId as long ) as boolean
```

Shows control `cId` (`SW_SHOW`).

**Returns** `true` if it was visible before.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlNormalize( 101 )
```

### ControlShowState

```freebasic
function ControlShowState( byval cId as long, byval showState as long ) as boolean
```

Calls `ShowWindow` on control `cId` with `showState` (`SW_SHOW`, `SW_HIDE` …).

**Returns** `true` if it was visible before.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlShowState( 101, SW_HIDE )
```

### ControlKill

```freebasic
function ControlKill( byval cId as long ) as boolean
```

Destroys control `cId`. Its identifier is free afterwards.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlKill( 101 )
```

Microsoft Learn: [DestroyWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroywindow)

### ControlRedraw

```freebasic
function ControlRedraw( byval cId as long ) as boolean
```

Invalidates control `cId` and repaints it before returning; the background is not erased first.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlRedraw( 101 )
```

Microsoft Learn: [RedrawWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-redrawwindow)

### ControlPost

```freebasic
function ControlPost( byval cId as long, byval Msg as UINT, byval wPrm as LONG_PTR, byval lPrm as LONG_PTR ) as boolean
```

Posts a message to control `cId` and returns without waiting.

**Returns** `true` if the message was posted.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlPost( 101, EM_SETSEL, 0, -1 )
```

Microsoft Learn: [PostMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-postmessagew)

### ControlSend

```freebasic
function ControlSend( byval cId as long, byval Msg as UINT, byval wPrm as LONG_PTR, byval lPrm as LONG_PTR ) as boolean
```

Sends a message to control `cId` and waits until it has been handled.

**Returns** whether the message's result was nonzero, as a `boolean`. For a result such as a
count or an index, call `SendDlgItemMessageW` or `SendMessageW` directly.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlSend( 101, EM_LIMITTEXT, 40, 0 )
```

Microsoft Learn: [SendDlgItemMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-senddlgitemmessagew)

### ControlGetText, ControlSetText

```freebasic
function ControlGetText( byval cId as long ) as ustring
function ControlSetText( byval cId as long, byval pwszText as wstring ptr ) as boolean
```

Reads or sets the text of control `cId`: the contents of an edit control, the caption of a button
or label.

**Returns** the text, `""` when there is none; `ControlSetText` returns `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim ustrName as ustring = pDlg->ControlGetText( 101 )
pDlg->ControlSetText( 102, "Hello, " & ustrName )
```

Microsoft Learn: [WM_GETTEXT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-gettext)

### ControlGetLoc, ControlSetLoc

```freebasic
function ControlGetLoc( byval cId as long, byref nLeft as long, byref nTop as long ) as boolean
function ControlSetLoc( byval cId as long, byval nLeft as long, byval nTop as long ) as boolean
```

`ControlGetLoc` reads the top-left corner of control `cId`, relative to its parent's client area;
`ControlSetLoc` moves the control there without resizing it. Both are in dialog units, or
physical pixels for a pixel dialog.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as long x, y
pDlg->ControlGetLoc( 101, x, y )
pDlg->ControlSetLoc( 101, x, y + 20 )
```

Microsoft Learn: [MapWindowPoints](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-mapwindowpoints)

### ControlGetSize, ControlSetSize

```freebasic
function ControlGetSize( byval cId as long, byref nWidth as long, byref nHeight as long ) as boolean
function ControlSetSize( byval cId as long, byval nWidth as long, byval nHeight as long ) as boolean
```

Reads or sets the size of control `cId`, borders included, in dialog units or physical pixels.
`ControlSetSize` does not move the control.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as long w, h
if pDlg->ControlGetSize( 101, w, h ) then pDlg->ControlSetSize( 101, w * 2, h )
```

Microsoft Learn: [SetWindowPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos)

### ControlGetWidth

```freebasic
function ControlGetWidth( byval cId as long ) as long
```

Returns the width of control `cId`, in the object's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print "width:"; pDlg->ControlGetWidth( 101 )
```

### ControlGetHeight

```freebasic
function ControlGetHeight( byval cId as long ) as long
```

Returns the height of control `cId`, in the object's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print "height:"; pDlg->ControlGetHeight( 101 )
```

### ControlGetClient, ControlSetClient

```freebasic
function ControlGetClient( byval cId as long, byref nWidth as long, byref nHeight as long ) as boolean
function ControlSetClient( byval cId as long, byval nWidth as long, byval nHeight as long ) as boolean
```

`ControlGetClient` reads the size of the client area of control `cId`, inside its borders and
scroll bars. `ControlSetClient` sets the size of the whole control, exactly as
[ControlSetSize](#controlgetsize-controlsetsize) does: the borders are not added.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as long w, h
pDlg->ControlGetClient( 101, w, h )
print "inside:"; w; " x"; h
```

Microsoft Learn: [GetClientRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getclientrect)

### ControlGetClientWidth

```freebasic
function ControlGetClientWidth( byval cId as long ) as long
```

Returns the width of the client area of control `cId`, in the object's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->ControlGetClientWidth( 101 )
```

### ControlGetClientHeight

```freebasic
function ControlGetClientHeight( byval cId as long ) as long
```

Returns the height of the client area of control `cId`, in the object's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->ControlGetClientHeight( 101 )
```

### ControlCenterHoriz

```freebasic
sub ControlCenterHoriz( byval cId as long )
```

Moves control `cId` so that it is centred horizontally in its parent's client area. Its vertical
position and size stay.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlCenterHoriz( IDOK )
```

### ControlCenterVert

```freebasic
sub ControlCenterVert( byval cId as long )
```

Moves control `cId` so that it is centred vertically in its parent's client area. It also moves
the control **right by half its width**: a button 88 pixels wide at x = 140 ends up at x = 184.
Put it back with [ControlSetLoc](#controlgetloc-controlsetloc) if the horizontal position must
stay.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as long x0, x, y
pDlg->ControlGetLoc( 101, x0, y )
pDlg->ControlCenterVert( 101 )
pDlg->ControlGetLoc( 101, x, y )
pDlg->ControlSetLoc( 101, x0, y )                 ' keep the old x
```

### ControlGetCheck, ControlSetCheck

```freebasic
function ControlGetCheck( byval cId as long ) as long
sub ControlSetCheck( byval cId as long, byval checkState as long )
```

Reads or sets the state of check box or radio button `cId`: `BST_UNCHECKED` (0), `BST_CHECKED`
(1) or, for a three-state box, `BST_INDETERMINATE` (2). Setting a radio button does not clear the
others of its group.

**Returns** the state.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->ControlGetCheck( 301 ) = BST_UNCHECKED then pDlg->ControlSetCheck( 301, BST_CHECKED )
```

Microsoft Learn: [BM_SETCHECK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setcheck)

### ControlSetOption

```freebasic
function ControlSetOption (BYVAL minId AS LONG, BYVAL maxId AS LONG, BYVAL cId AS LONG) AS BOOLEAN
```

Checks one radio button of a group. `minId`is the identifier of the first radio button in the group, `maxId`is the identifier of the last radio button in the group, and `cId` is the identifier of the radio button to select..

**Returns** `true`on success or `false`on failure.

**Example**

```freebasic
ControlSetOption(hDlg, 201, 203, 202)
```

Microsoft Learn: [CheckRadioButton](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-checkradiobutton)

### ControlGetUser, ControlSetUser

```freebasic
function ControlGetUser( byval cid as long, byval index as long ) as LONG_PTR
function ControlSetUser( byval cid as long, byval index as long, byval userValue as LONG_PTR ) as boolean
```

Reads or stores one of ten values, numbered 0 to 9, that the object keeps for control `cid`. The
values live in the `CDialog`, not in the control.

**Returns** the stored value, 0 if none or for an index out of range; `ControlSetUser` returns
`false` for an index out of range or a missing control.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlSetUser( 101, 0, 42 )
print pDlg->ControlGetUser( 101, 0 )            ' 42
```

### GetUserDataItem

```freebasic
function GetUserDataItem( byval cid as long ) as long
```

Returns the position of control `cid` in the object's list of controls with user values, the
list [ControlSetUser](#controlgetuser-controlsetuser) adds to.

**Returns** the position, from 0, or -1 when the control has no values.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->GetUserDataItem( 101 ) = -1 then print "no user values yet"
```

### MenuContext

```freebasic
function MenuContext( byval hPopUpMenu as HMENU, byval x as long, byval y as long, byval flags as UINT ) as long
```

Shows the popup menu `hPopUpMenu` at screen point (`x`, `y`) and waits for the user. The dialog
gets no `WM_COMMAND`: the command chosen is returned instead. `TPM_NONOTIFY`, `TPM_RETURNCMD` and
`TPM_NOANIMATION` are added to `flags`. The menu is not destroyed.

| Parameter | Meaning |
| --- | --- |
| `hPopUpMenu` | A menu from `CreatePopupMenu`. |
| `x`, `y` | The point in screen coordinates, such as the cursor position. |
| `flags` | `TPM_*` alignment and button flags, or 0. |

**Returns** the identifier of the item chosen, or 0 when the menu was dismissed.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim hMenu as HMENU = CreatePopupMenu()
AppendMenuW( hMenu, MF_STRING, 1, "&Copy" )
dim pt as POINT
GetCursorPos( @pt )
if pDlg->MenuContext( hMenu, pt.x, pt.y, 0 ) = 1 then print "copy"
DestroyMenu( hMenu )
```

Microsoft Learn: [TrackPopupMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-trackpopupmenu)

### ControlSetColor

```freebasic
function ControlSetColor( byval hwnd as HWND, byval foreColor as COLORREF, byval backColor as COLORREF ) as boolean
function ControlSetColor( byval cID as long, byval foreColor as COLORREF, byval backColor as COLORREF ) as boolean
```

Gives a control its own text colour and background, given by handle or identifier, and repaints
the dialog. Setting a control again replaces its colours.

The colours are applied when Windows asks the dialog how to paint a control, so they work for
labels, edit controls and list boxes. Push buttons are not coloured this way: use [CXpButton](CXpButton). Your dialog procedure
does not receive the `WM_CTLCOLOR…` messages of a coloured control.

**Returns** `true`, or `false` when the window does not exist.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlSetColor( 101, RGB_WHITE, RGB_NAVY )
```

Microsoft Learn: [WM_CTLCOLORSTATIC](https://learn.microsoft.com/en-us/windows/win32/controls/wm-ctlcolorstatic)

### DialogSetColor

```freebasic
function DialogSetColor( byval foreColor as COLORREF, byval backColor as COLORREF ) as boolean
```

Sets the background colour of the dialog to `backColor` and repaints it. `foreColor` is stored
but not used for the dialog itself; give the labels their own colours with
[ControlSetColor](#controlsetcolor).

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogSetColor( RGB_BLACK, RGB_WHITE )
```

Microsoft Learn: [WM_CTLCOLORDLG](https://learn.microsoft.com/en-us/windows/win32/dlgbox/wm-ctlcolordlg)

### GetColorItem

```freebasic
function GetColorItem( byval hwnd as HWND ) as long
```

Returns the position of window `hwnd` in the object's list of coloured windows, the list
[ControlSetColor](#controlsetcolor) and [DialogSetColor](#dialogsetcolor) add to.

**Returns** the position, from 0, or -1 when the window has no colours.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->GetColorItem( hCtrl ) >= 0 then print "coloured"
```

### DialogEnableRepaint

```freebasic
sub DialogEnableRepaint( byval fRepaint as boolean )
```

Turns the custom colours of [ControlSetColor](#controlsetcolor) and
[DialogSetColor](#dialogsetcolor) off (`false`) or back on (`true`); while they are off, the
dialog and its controls paint in the system colours. The dialog turns them on again by itself
when the user moves or sizes it.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogEnableRepaint( false )
```

### IsDialogRepaintDisabled

```freebasic
function IsDialogRepaintDisabled() as boolean
```

Returns `true` while the custom colours are off.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->IsDialogRepaintDisabled() then pDlg->DialogEnableRepaint( true )
```

### DialogDisableRepaintOnResize

```freebasic
sub DialogDisableRepaintOnResize( byval fRepaint as boolean )
```

With `true`, the custom colours are turned off while the user drags or sizes the dialog and back
on, with a repaint, when the user lets go, which keeps resizing smooth in a dialog with many
coloured controls. `false` (the default) keeps them on throughout.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogDisableRepaintOnResize( true )
```

Microsoft Learn: [WM_ENTERSIZEMOVE](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-entersizemove)

### IsDialogRepaintDisabledOnResize

```freebasic
function IsDialogRepaintDisabledOnResize() as boolean
```

Returns `true` when [DialogDisableRepaintOnResize](#dialogdisablerepaintonresize) was given
`true`.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->IsDialogRepaintDisabledOnResize()
```

### DialogSetIcon

```freebasic
sub DialogSetIcon( byref wszImage as wstring )
```

Loads an icon and makes it both the caption icon and the Alt+Tab icon of the dialog. `wszImage`
is `"#"` plus a resource number, a file name ending in `.ico`, or the name of an icon resource.
The icon is loaded once, at the large icon size, and the same handle serves for both. The icons
it replaces are passed to `DeleteObject`.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogSetIcon( "#100" )                   ' icon resource 100
```

Microsoft Learn: [WM_SETICON](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-seticon)

### DialogSetIconEx

```freebasic
sub DialogSetIconEx( byval hIconBig as HICON, byval hIconSmall as HICON )
```

Sets the big (Alt+Tab) and small (caption) icons of the dialog from handles you loaded. The
icons stay yours, and the ones they replace are not released.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogSetIconEx( LoadIconW( NULL, IDI_APPLICATION ), LoadIconW( NULL, IDI_APPLICATION ) )
```

### FindResourceType

```freebasic
function FindResourceType( byref wszResourceName as wstring ) as string
```

Looks for a resource in the program's own executable, by `"#"` plus a number or by name, among
icons, icon groups, bitmaps and raw data, in that order. The image members use it to choose
between icon and bitmap.

**Returns** `"RT_GROUP_ICON"`, `"RT_ICON"`, `"RT_BITMAP"` or `"RT_RCDATA"`, or `""` when no such
resource exists.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->FindResourceType( "#100" ) = "" then print "no resource 100"
```

Microsoft Learn: [FindResourceW](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-findresourcew)

### ControlSetImage

```freebasic
function ControlSetImage( byval cId as long, byref wszImage as wstring ) as boolean
```

Loads an icon or bitmap resource, at its own size, into image label `cId` (an `Image` from
[ControlAdd](#controladd)); the label takes the size of the image. `wszImage` is `"#"` plus a
resource number or a resource name. The image that was in the label is passed to `DeleteObject`.

A file name ending in `.ico` is tried as a file, but as a bitmap, and nothing is loaded; other
file names are not tried as files. In practice the image must be a resource.

**Returns** `true` when control `cId` exists, whether or not an image was loaded; `false`
otherwise.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlSetImage( 501, "#200" )
```

Microsoft Learn: [STM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/stm-setimage)

### ControlSetImageX

```freebasic
function ControlSetImageX( byval cId as long, byref wszImage as wstring ) as boolean
```

Works like [ControlSetImage](#controlsetimage), but loads the image stretched to the client size
of the label (an `ImageX` from [ControlAdd](#controladd)).

**Returns** `true` when control `cId` exists.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlSetImageX( 501, "#200" )
```

Microsoft Learn: [LoadImageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadimagew)

### ControlSetImgButton

```freebasic
function ControlSetImgButton( byval cId as long, byref wszImage as wstring ) as boolean
```

Loads an icon or bitmap resource, at its own size, onto button `cId` (an `ImgButton` from
[ControlAdd](#controladd), or a button with `BS_ICON` or `BS_BITMAP`). The button keeps its size
and clips an image that is larger. Names and files are treated as in
[ControlSetImage](#controlsetimage); the image that was on the button is passed to `DeleteObject`.

**Returns** `true` when control `cId` exists.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlSetImgButton( 601, "#300" )
```

Microsoft Learn: [BM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setimage)

### ControlSetImgButtonX

```freebasic
function ControlSetImgButtonX( byval cId as long, byref wszImage as wstring ) as boolean
```

Works like [ControlSetImgButton](#controlsetimgbutton), but loads the image stretched to the
button's client area.

**Returns** `true` when control `cId` exists.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlSetImgButtonX( 601, "#300" )
```

### DialogUnitsToPixels

```freebasic
function DialogUnitsToPixels( byval dluX as long, byval dluY as long, byref pixelX as long, byref pixelY as long ) as boolean
```

Converts a horizontal and a vertical distance in this dialog's units to pixels, using the
dialog's font. With Segoe UI 9 at 96 DPI, 100 × 50 dialog units are 175 × 94 pixels.

**Returns** `true` on success, `false` when there is no dialog yet.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as long px, py
pDlg->DialogUnitsToPixels( 100, 50, px, py )
```

Microsoft Learn: [MapDialogRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-mapdialogrect)

### DialogUnitsToPixelsRatios

```freebasic
function DialogUnitsToPixelsRatios( byref ratioX as single, byref ratioY as single ) as boolean
```

Reads the number of pixels in one horizontal and one vertical dialog unit (1.75 and 1.875 for
Segoe UI 9 at 96 DPI).

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as single rx, ry
pDlg->DialogUnitsToPixelsRatios( rx, ry )
```

### DluToPixRX

```freebasic
function DluToPixRX() as single
```

Returns the number of pixels in one horizontal dialog unit.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim nPixels as long = 50 * pDlg->DluToPixRX()
```

### DluToPixRY

```freebasic
function DluToPixRY() as single
```

Returns the number of pixels in one vertical dialog unit.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim nPixels as long = 14 * pDlg->DluToPixRY()
```

### PixelsToDialogUnits

```freebasic
function PixelsToDialogUnits( byval pixelX as long, byval pixelY as long, byref dluX as long, byref dluY as long ) as boolean
```

Converts a horizontal and a vertical distance in pixels to this dialog's units. The results are
rounded to whole units, so a round trip can be a unit out.

**Returns** `true` on success, `false` when there is no dialog yet.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as long dx, dy
pDlg->PixelsToDialogUnits( 175, 94, dx, dy )   ' 100, 50 with the default font at 96 DPI
```

### PixelsToDialogUnitsRatios

```freebasic
function PixelsToDialogUnitsRatios( byref ratioX as single, byref ratioY as single ) as boolean
```

Reads the number of horizontal and vertical dialog units in one pixel: the reciprocals of
[DialogUnitsToPixelsRatios](#dialogunitstopixelsratios).

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim as single rx, ry
pDlg->PixelsToDialogUnitsRatios( rx, ry )
```

### PixToDluRX

```freebasic
function PixToDluRX() as single
```

Returns the number of horizontal dialog units in one pixel.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim nUnits as long = 300 * pDlg->PixToDluRX()
```

### PixToDluRY

```freebasic
function PixToDluRY() as single
```

Returns the number of vertical dialog units in one pixel.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim nUnits as long = 200 * pDlg->PixToDluRY()
```

### RxRatio

```freebasic
function RxRatio() as single
```

Returns what one horizontal unit of this dialog is in pixels: the desktop's horizontal scaling
ratio for a pixel dialog (1.75 at 175 %), or pixels per dialog unit for a dialog-unit dialog.
[ScaleX](#scalex) multiplies by it.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print "1 unit ="; pDlg->RxRatio(); " pixels"
```

### RyRatio

```freebasic
function RyRatio() as single
```

Returns what one vertical unit of this dialog is in pixels, as [RxRatio](#rxratio) does
horizontally.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print "1 unit ="; pDlg->RyRatio(); " pixels"
```

### ScaleX

```freebasic
function ScaleX( byval cx as single ) as single
```

Converts a horizontal value in this dialog's units (96-DPI units or dialog units) to pixels.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim nPixels as long = pDlg->ScaleX( 220 )
```

### ScaleY

```freebasic
function ScaleY( byval cy as single ) as single
```

Converts a vertical value in this dialog's units to pixels.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim nPixels as long = pDlg->ScaleY( 150 )
```

### UnScaleX

```freebasic
function UnScaleX( byval cx as single ) as single
```

Converts a horizontal value in pixels to this dialog's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->UnScaleX( GetSystemMetrics( SM_CXVSCROLL ) )
```

### UnScaleY

```freebasic
function UnScaleY( byval cy as single ) as single
```

Converts a vertical value in pixels to this dialog's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->UnScaleY( GetSystemMetrics( SM_CYCAPTION ) )
```

### ScaleRect

```freebasic
function ScaleRect( byval rc as RECT ) as RECT
```

Returns `rc`, given in this dialog's units, converted to pixels: multiplied by the scaling ratios
for a pixel dialog, converted with the dialog's font for a dialog-unit dialog.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim rcUnits as RECT = type( 10, 10, 110, 60 )
dim rcPixels as RECT = pDlg->ScaleRect( rcUnits )
```

### UnScaleRect

```freebasic
function UnScaleRect( byval rc as RECT ) as RECT
```

Returns the pixel rectangle `rc` converted to this dialog's units.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
dim rcPixels as RECT
GetClientRect( pDlg->hDialog, @rcPixels )
dim rcUnits as RECT = pDlg->UnScaleRect( rcPixels )
```

### SetWindowPosForDPI

```freebasic
function SetWindowPosForDPI( byval hwnd as HWND, byval hWndInsertAfter as HWND, byval x as long, byval y as long, byval cx as long, byval cy as long, byval uFlags as UINT = SWP_NOZORDER ) as boolean
```

Calls Windows' `SetWindowPos` with `x`, `y`, `cx` and `cy` converted by [ScaleX](#scalex) and
[ScaleY](#scaley), so they are in this dialog's units: dialog units for a dialog-unit dialog.
`sys/win` has a function of the same name that always takes 96-DPI units; see
[Window size and position](SysWin-Window-Size-and-Position#setwindowposfordpi).

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->SetWindowPosForDPI( pDlg->ControlHandle( 101 ), NULL, 10, 10, 100, 14 )
```

Microsoft Learn: [SetWindowPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos)

### MoveWindowForDPI

```freebasic
function MoveWindowForDPI( byval hwnd as HWND, byval x as long, byval y as long, byval nWidth as long, byval nHeight as long, byval bRepaint as boolean ) as boolean
```

Calls Windows' `MoveWindow` with the position and size converted to pixels from this dialog's
units. Unlike the `sys/win` function of the same name, `bRepaint` has no default.

**Returns** `true` on success.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->MoveWindowForDPI( pDlg->ControlHandle( 101 ), 10, 30, 100, 14, true )
```

Microsoft Learn: [MoveWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-movewindow)

### ControlAnchor

```freebasic
function ControlAnchor( byval cID as long, byval nAnchorMode as long ) as boolean
function ControlAnchor( byval hCtl as HWND, byval nAnchorMode as long ) as boolean
function ControlAnchor( byval hParent as HWND, byval cID as long, byval nAnchorMode as long ) as boolean
```

Records how a control follows its parent when the dialog is resized. The control's present
distances from its parent's edges and centre are remembered; on every `WM_SIZE` (restored or
maximized) `CDialog` calls [AdjustControls](#adjustcontrols) and moves or stretches the control
to keep the distances its mode names. Anchor after the control has its final position, and
anchor again to change the mode. The third form finds the control by identifier inside another
parent, such as a group of controls in a child window.

| `nAnchorMode` | The control |
| --- | --- |
| `ANCHOR_NONE` | stays where it is |
| `ANCHOR_WIDTH` | stretches with the width |
| `ANCHOR_RIGHT` | keeps its distance from the right edge |
| `ANCHOR_CENTER_HORZ` | keeps its offset from the horizontal centre |
| `ANCHOR_HEIGHT` | stretches with the height |
| `ANCHOR_HEIGHT_WIDTH` | stretches both ways |
| `ANCHOR_HEIGHT_RIGHT` | stretches with the height and keeps to the right edge |
| `ANCHOR_BOTTOM` | keeps its distance from the bottom edge |
| `ANCHOR_BOTTOM_WIDTH` | keeps to the bottom and stretches with the width |
| `ANCHOR_BOTTOM_RIGHT` | keeps to the bottom-right corner |
| `ANCHOR_CENTER_HORZ_BOTTOM` | keeps to the bottom and its offset from the horizontal centre |
| `ANCHOR_CENTER_VERT` | is centred vertically |
| `ANCHOR_CENTER_VERT_RIGHT` | is centred vertically and keeps to the right edge |
| `ANCHOR_CENTER` | keeps its offset from the centre |

A mode outside that range is clamped to it.

**Returns** `true`, or `false` when the control does not exist.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->ControlAnchor( 101, ANCHOR_HEIGHT_WIDTH )
pDlg->ControlAnchor( IDOK, ANCHOR_BOTTOM_RIGHT )
```

### GetAnchorItem

```freebasic
function GetAnchorItem( byval hwndCtl as HWND ) as long
```

Returns the position of control `hwndCtl` in the object's list of anchored controls.

**Returns** the position, from 0, or -1 when the control is not anchored.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->GetAnchorItem( hCtrl ) = -1 then pDlg->ControlAnchor( hCtrl, ANCHOR_WIDTH )
```

### AdjustControls

```freebasic
function AdjustControls() as boolean
```

Moves and sizes every anchored control to fit the current client area, at once. `CDialog` calls
it on `WM_SIZE`; call it yourself after resizing the dialog while it is hidden.

**Returns** `true`, or `false` when no control is anchored.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->AdjustControls() then pDlg->DialogRedraw()
```

Microsoft Learn: [EnumChildWindows](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumchildwindows)

### AccelHandle

```freebasic
property AccelHandle() as HACCEL
```

Returns the accelerator table [DialogDoEvents](#dialogdoevents) translates keys with, or `NULL`
when there is none.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg->AccelHandle = NULL then print "no shortcuts"
```

### AccelAttach

```freebasic
sub AccelAttach( byval hAccel as HACCEL )
```

Makes `hAccel`, a table you created or loaded from a resource, the dialog's accelerator table.
The previous table is destroyed and the shortcuts added with [AddAccelerator](#addaccelerator)
are forgotten. The object owns `hAccel` from then on and destroys it with itself.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->AccelAttach( LoadAcceleratorsW( GetModuleHandleW( NULL ), "MAINACCEL" ) )
```

Microsoft Learn: [TranslateAcceleratorW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-translateacceleratorw)

### AddAccelerator

```freebasic
sub AddAccelerator overload ( byval fvirt as ubyte, byval wKey as WORD, byval cmd as WORD )
sub AddAccelerator overload ( byval fvirt as ubyte, byref wszKey as wstring, byval cmd as WORD )
```

Adds a shortcut to the list that [CreateAccelTable](#createacceltable) builds the table from.
When it is pressed the dialog receives `WM_COMMAND` with `cmd` in the low word of `wParam` and 1
in the high word.

| Parameter | Meaning |
| --- | --- |
| `fvirt` | `FVIRTKEY`, plus any of `FCONTROL`, `FALT`, `FSHIFT`. |
| `wKey` | A virtual-key code (`VK_F5`, `asc( "S" )` …), or a character code without `FVIRTKEY`. |
| `wszKey` | A string whose first character is used as `wKey`; with `FVIRTKEY` use an upper-case letter or digit. |
| `cmd` | The command identifier. |

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->AddAccelerator( FVIRTKEY or FCONTROL, "S", 1001 )
pDlg->AddAccelerator( FVIRTKEY, VK_F5, 1002 )
pDlg->CreateAccelTable()
```

Microsoft Learn: [ACCEL](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-accel)

### CreateAccelTable

```freebasic
function CreateAccelTable() as HACCEL
```

Builds the accelerator table from every shortcut added so far, replacing a table the dialog
already had, and makes it the one [DialogDoEvents](#dialogdoevents) uses. The list is kept, so
shortcuts added later are joined to the old ones by the next call.

**Returns** the table, or `NULL` when no shortcut has been added.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->AddAccelerator( FVIRTKEY or FCONTROL, asc( "O" ), 1003 )
dim hAccel as HACCEL = pDlg->CreateAccelTable()
```

Microsoft Learn: [CreateAcceleratorTableW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createacceleratortablew)

### DestroyAccelTable

```freebasic
sub DestroyAccelTable
```

Destroys the accelerator table and forgets the shortcuts added. The destructor does the same.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DestroyAccelTable()
```

Microsoft Learn: [DestroyAcceleratorTable](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroyacceleratortable)

### DialogSetViewPort

```freebasic
function DialogSetViewPort( byval nWidth as long, byval nHeight as long ) as boolean
```

Makes the dialog scrollable. Lay the dialog out at its full size first; `DialogSetViewPort` then
records that client area as the whole content, shrinks the client area to `nWidth` × `nHeight`
(in the units of [DialogSetClient](#dialoggetclient-dialogsetclient)) and marks the dialog
scrollable. From then on `CDialog` sets up the scroll bars on every `WM_SIZE` and scrolls the
contents on `WM_HSCROLL` and `WM_VSCROLL`, in steps of 10 pixels. Centre the dialog afterwards.

The scroll bars' ranges are set in pixels while `CDialog` keeps their positions in those 10-pixel
steps: after two clicks on the down arrow the contents have moved 20 pixels and the thumb
position reads 2, and dragging the thumb a few pixels scrolls straight to the end.

**Returns** `true`.

**Example**

```freebasic
dim pDlg as CDialog
pDlg.DialogNewPixels( NULL, "Scrollable", -1, -1, 320, 335, WS_OVERLAPPEDWINDOW )
pDlg.ControlAdd( "ListBox", 101, "", 8, 8, 300, 280 )
pDlg.DialogSetViewPort( 250, 260 )
pDlg.DialogCenter()
```

Microsoft Learn: [SetScrollInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setscrollinfo)

### IsDialogScrollable

```freebasic
function IsDialogScrollable() as boolean
```

Returns `true` once [DialogSetViewPort](#dialogsetviewport) has made the dialog scrollable.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
print pDlg->IsDialogScrollable()
```

### DialogResetScrollBars

```freebasic
sub DialogResetScrollBars
```

Scrolls the contents of a scrollable dialog back to the top-left corner and sets both scroll
positions to 0. `CDialog` calls it on `WM_SIZE`, before [DialogSetupScrollBars](#dialogsetupscrollbars).

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogResetScrollBars()
```

Microsoft Learn: [ScrollWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-scrollwindow)

### DialogSetupScrollBars

```freebasic
sub DialogSetupScrollBars
```

Sets the range, page and position of both scroll bars from the full content size recorded by
[DialogSetViewPort](#dialogsetviewport) and the current client size. A scroll bar whose page
covers the whole content disappears.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogSetupScrollBars()
```

### DialogOnVScroll

```freebasic
sub DialogOnVScroll( byval wParam as WPARAM, byval lParam as LPARAM )
```

Scrolls a scrollable dialog vertically for a `WM_VSCROLL` message: an arrow click is one step of
10 pixels, a page-area click a page, and the position stays within the content (see
[DialogSetViewPort](#dialogsetviewport) for how the thumb behaves). `CDialog` already calls it for a scrollable dialog; pass the message's parameters
only if you handle `WM_VSCROLL` some other way.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogOnVScroll( SB_LINEDOWN, 0 )
```

Microsoft Learn: [WM_VSCROLL](https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll)

### DialogOnHScroll

```freebasic
sub DialogOnHScroll( byval wParam as WPARAM, byval lParam as LPARAM )
```

Scrolls a scrollable dialog horizontally for a `WM_HSCROLL` message, as
[DialogOnVScroll](#dialogonvscroll) does vertically. `CDialog` already calls it.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogOnHScroll( SB_LINERIGHT, 0 )
```

Microsoft Learn: [WM_HSCROLL](https://learn.microsoft.com/en-us/windows/win32/controls/wm-hscroll)

### DialogOnSize

```freebasic
sub DialogOnSize( byval wParam as WPARAM, byval lParam as LPARAM )
```

Resets and sets up the scroll bars of a scrollable dialog after its size has changed: the work
`CDialog` itself does on `WM_SIZE`. The parameters are not used.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
pDlg->DialogOnSize( SIZE_RESTORED, 0 )
```

Microsoft Learn: [WM_SIZE](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-size)

## Related functions

| Function | Does |
| --- | --- |
| [CDialogPtr](#cdialogptr) | Returns the `CDialog` of a dialog, from its handle. |
| [DialogInputBox](#dialoginputbox) | Asks the user for a line of text in a modal dialog. |
| [DialogInputBoxWindowProc](#dialoginputboxwindowproc) | The dialog procedure of the input box. |

### CDialogPtr

```freebasic
function CDialogPtr( byval hDlg as HWND ) as CDialog ptr
```

Returns the `CDialog` object behind a dialog, given the dialog's handle, so a dialog procedure needs no global or `static` pointer.

**Returns** the object, or `NULL` for a `NULL` handle.

**Example**

```freebasic
dim pDlg as CDialog ptr = CDialogPtr( hDlg )
if pDlg then pDlg->ControlSetText( 101, "" )
```

Microsoft Learn: [GetAncestor](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getancestor)

### DialogInputBox

```freebasic
function DialogInputBox( byval hParent as HWND = NULL, byval x as long = 0, byval y as long = 0, byref wszCaption as wstring = "", byref wszPrompt as wstring = "", byref wszText as wstring = "", byval nLen as long = 260, byval bPassword as boolean = false ) as ustring
```

Shows a modal, resizable dialog with a prompt, an edit box holding `wszText` (selected) and
**OK** and **Cancel** buttons captioned in the language of Windows, and waits for the user. The
dialog is centred over `hParent` (or in the work area) when `x` and `y` are both 0; other values
are its position in dialog units.

The box is a [DialogNewPixels](#dialognewpixels) dialog with its own class, `CDialog_InputBox`,
and runs with [DialogInputBoxWindowProc](#dialoginputboxwindowproc). Like every `CDialog`, it
ends with [DialogEnd](#dialogend), which posts `WM_QUIT`: in a program built on
[CWindow](CWindow), use `CWindow`'s own `InputBox`.

| Parameter | Meaning |
| --- | --- |
| `hParent` | The owner, disabled while the box is open, or `NULL`. |
| `x`, `y` | The position, or 0, 0 to centre. |
| `wszCaption` | The caption. |
| `wszPrompt` | The prompt above the edit box. |
| `wszText` | The text the edit box starts with. |
| `nLen` | The most characters the user can type: 0 means 260, and a value outside 1 to 2048 means 2048. `wszText` is cut to it. |
| `bPassword` | `true` shows each character typed as an asterisk. |

**Returns** the text in the box when the user chose **OK**, `""` for **Cancel**, Esc or the close
box.

**Example**

```freebasic
dim ustrName as ustring = DialogInputBox( hDlg, 0, 0, "Name", "Who are you?", "Nobody" )
if len( ustrName ) then print "Hello, "; ustrName
```

### DialogInputBoxWindowProc

```freebasic
function DialogInputBoxWindowProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
```

The dialog procedure [DialogInputBox](#dialoginputbox) shows its dialog with. On **OK** (`IDOK`)
it copies the text of edit control 101, up to 2048 characters, to the `wstring` buffer whose
address is in user value 0 ([DialogSetUser](#dialoggetuser-dialogsetuser)), then closes the
dialog; on `IDCANCEL` it closes the dialog; it keeps the dialog at least 220 × 150 96-DPI units;
and on `WM_CLOSE` it calls `DialogEnd( 1 )`. It is public so that a dialog of your own with the
same edit control and buffer can reuse it.

**Returns** `true` for `WM_INITDIALOG`, `false` for every other message.

**Example**

```freebasic
dim wszOut as wstring * 2049
dim pDlg as CDialog
pDlg.DialogNewPixels( hwnd, "Rename", -1, -1, 346, 80, WS_POPUPWINDOW or WS_CAPTION )
pDlg.ControlAdd( "Edit", 101, "old name", 21, 15, 300, 19 )
pDlg.DialogSetUser( 0, cast( LONG_PTR, @wszOut ) )
pDlg.DialogShowModal( @DialogInputBoxWindowProc )
```

## Related types

These are the records `CDialog` keeps for its anchors, colours and control user values. They are
public, but the members above read and write them for you.

| Type | Holds |
| --- | --- |
| [ANCHORPOINT](#anchorpoint) | The `ANCHOR_*` modes of [ControlAnchor](#controlanchor). |
| [ANCHORPROPERTY](#anchorproperty) | One anchored control. |
| [DLGCOLORS](#dlgcolors) | One coloured window. |
| [CTLUSERDATA](#ctluserdata) | The ten user values of one control. |

### ANCHORPOINT

```freebasic
enum ANCHORPOINT
    ANCHOR_NONE = 0
    ANCHOR_WIDTH
    ANCHOR_RIGHT
    ANCHOR_CENTER_HORZ
    ANCHOR_HEIGHT
    ANCHOR_HEIGHT_WIDTH
    ANCHOR_HEIGHT_RIGHT
    ANCHOR_BOTTOM
    ANCHOR_BOTTOM_WIDTH
    ANCHOR_BOTTOM_RIGHT
    ANCHOR_CENTER_HORZ_BOTTOM
    ANCHOR_CENTER_VERT
    ANCHOR_CENTER_VERT_RIGHT
    ANCHOR_CENTER
end enum
```

The anchor modes, numbered 0 to 13; the table under [ControlAnchor](#controlanchor) says what
each does.

**Example**

```freebasic
dim nMode as long = ANCHOR_BOTTOM_RIGHT
print nMode                                     ' 9
```

### ANCHORPROPERTY

```freebasic
type ANCHORPROPERTY
    hwndCtl as HWND
    anchor as long
    rc as RECT
    centerX as long
    centerY as long
end type
```

One anchored control: its handle, its mode, its distances from the parent's left, top, right and
bottom edges (in `rc`, in pixels) and its offset from the parent's centre, as measured when it was
anchored.

**Example**

```freebasic
dim ap as ANCHORPROPERTY
ap.anchor = ANCHOR_WIDTH
```

### DLGCOLORS

```freebasic
type DLGCOLORS
    hwnd as HWND
    foreColor as COLORREF
    backColor as COLORREF
end type
```

One window given colours with [ControlSetColor](#controlsetcolor) or
[DialogSetColor](#dialogsetcolor): its handle, text colour and background colour.

**Example**

```freebasic
dim dc as DLGCOLORS
dc.backColor = RGB_WHITE
```

### CTLUSERDATA

```freebasic
type CTLUSERDATA
    hCtl as HWND
    Values(0 to 9) as LONG_PTR
end type
```

The values [ControlSetUser](#controlgetuser-controlsetuser) keeps for one control: its handle and
ten slots.

**Example**

```freebasic
dim ud as CTLUSERDATA
ud.Values(0) = 42
```

## See also

- [sys/win/gui](SysWin-Gui) for the module and its other classes
- [CWindow](CWindow), the window class for programs that are not dialog-based
- [CXpButton](CXpButton) for buttons with colours and images
- [Units](SysWin-Units) for dialog units, pixels and 96-DPI units
- [Display, screen and DPI](SysWin-Display-and-DPI) for `SetProcessDpiAwareness` and the scaling ratios
- [Window size and position](SysWin-Window-Size-and-Position) for the same measurements on any window
- [Category: sys/win](Category-Sys-Win)
