[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkMessageBox**

# tkMessageBox

Shows a themed modal message box and returns the id of the button that closed it.

tkMessageBox is an owner-drawn replacement for the system message box: a caption band with a
title and a close X, a body with an optional icon and a wrapped message, and a footer of one to
three [tkButton](tkButton)s. It opens in its own borderless window, centred on its owner, sizes
itself to the text, and blocks until it is dismissed. Because it is drawn by tkControls, it
follows the theme and looks the same on Windows, Linux and macOS.

Build one with `tkMessageBox_Create`, configure it, and call `tkMessageBox_DoModal`, which shows
it, runs a modal loop (the owner window ignores input meanwhile) and returns the dismissing id.
**The handle is dead once `DoModal` returns.** A box can be raised from inside another box's
callback; the loops nest.

## Importing

```freebasic
#import "vendor/tkControls/tkMessageBox"

using tkMessageBox
using tkHost
```

The module imports `tkHost`, `tkTheme` and `tkButton` publicly; open `tkButton` with `using` to
name `TKBUTTON_COLORS` for `tkMessageBox_SetButtonColors`, or to reach a footer button returned
by `tkMessageBox_AddButton` / `tkMessageBox_GetButtonHandle`.

## Example

```freebasic
dim as TTF_Font ptr fText  = tkHost_OpenFont( gHost, tkHost_FontDir() & TK_FONT_UI, 10 )
dim as TTF_Font ptr fGlyph = tkHost_OpenFont( gHost, tkHost_FontDir() & TK_FONT_ICONS, 20 )

dim as TK_WIDGET ptr h = tkMessageBox_Create( tkHost_Root( gHost ) )
tkMessageBox_ApplyFonts( h, fText, fGlyph )
tkMessageBox_SetCaption( h, "Warning" )
tkMessageBox_SetText( h, "This buffer contains unsaved edits. Do you want to save it?" )
tkMessageBox_SetIconKind( h, MBX_ICON_WARNING )
tkMessageBox_AddPreset( h, MBX_BTN_SAVE_DONTSAVE_CANCEL )

select case tkMessageBox_DoModal( h )      ' h is dead from here on
case MBX_IDYES    : SaveFile()             ' "Save"
case MBX_IDNO     : DiscardEdits()         ' "Don't Save"
case MBX_IDCANCEL : ' keep editing
end select
```

`tkMessageBox_Show( hParent, Text, Caption, nIconKind, nPreset )` does all of that in one call,
but sets no fonts: it draws in the host's default font and an icon renders as a missing glyph.
Use the long form whenever the box has an icon.

## Buttons and dismissal

- The six `MBX_BTN_*` presets add their buttons, make the first the default and set the cancel
  id. Save / Don't Save / Cancel returns `MBX_IDYES` / `MBX_IDNO` / `MBX_IDCANCEL`.
- `tkMessageBox_AddButton( h, Text, id )` adds a button of your own, up to
  `TKMESSAGEBOX_MAXBUTTONS`, right-aligned in the order added.
- Clicking a button returns its id. Esc, the close X and the window's own close (Alt+F4) return
  the cancel id, which is the last button's unless `tkMessageBox_SetCancelID` says otherwise.
  A box with no buttons returns 0, as does a quit request (which is passed on to your loop).
- Enter fires the focused button. The focus starts on the button set with
  `tkMessageBox_SetFocusButton`, else the default button, else the first.

## Coming from PsMessageBox

[PsMessageBox](PsMessageBox) remains the behaviour reference for everything not listed here.

- Names: `PsMessageBox_*` → `tkMessageBox_*`, `PSMESSAGEBOX_*` → `TKMESSAGEBOX_*`,
  `IDC_CMESSAGEBOX_BUTTON_BASE` → `IDC_TKMESSAGEBOX_BUTTON_BASE`. `MBX_COLORS`, `MBX_PAINTINFO`,
  `MBX_MESSAGEINFO`, `MBX_ICON_*`, `MBX_BTN_*`, `MBX_PART_*` and the `MBX_*` callback types keep
  their names.
- The results are `MBX_IDOK` … `MBX_IDNO`, with the Win32 `IDOK` … `IDNO` values, so they never
  collide with `sys/win`.
- Handles are `TK_WIDGET ptr`; fonts are `TTF_Font ptr` (`tkMessageBox_SetFont`,
  `SetCaptionFont`, `SetGlyphFont`, `SetCloseGlyphFont`, or `ApplyFonts` for the text and icon
  fonts together); colours are `ulong`; button colours are `TKBUTTON_COLORS`.
- `tkMessageBox_Create( hParent )` takes a `TK_WIDGET ptr`; the box's window is owned by that
  widget's window. `tkMessageBox_GetSurface` returns that window as a `TK_HOST ptr`.
- Added: `tkMessageBox_Destroy`, for a box you built and then decided not to show.
- `MBX_MESSAGEINFO` carries `msg` (a `TKM_*`, or `TKMBX_MSG_CLOSE` for the window's close),
  `x`, `y`, `key` and `mods`. The close cannot be vetoed.
- There is no system sound: `tkMessageBox_SetBeep` is stored and reported by
  `tkMessageBox_GetBeep`, but nothing beeps.
- A tab in the text becomes four spaces.
- On Wayland the compositor places the window, so centring is a request.
- Gone: the drop shadow, `IsDialogMessage` (the host owns Tab), `Rescale` (DPI changes are
  handled by the box), `RunSelfTest`, and PsRegistry.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKMESSAGEBOX_MAXBUTTONS = 3
const IDC_TKMESSAGEBOX_BUTTON_BASE = 8100
const TKMESSAGEBOX_DEFAULT_CAPTIONHEIGHT = 34
const TKMESSAGEBOX_DEFAULT_CAPTIONPADX = 14
const TKMESSAGEBOX_DEFAULT_CLOSEWIDTH = 44
const TKMESSAGEBOX_DEFAULT_BODYPADX = 20
const TKMESSAGEBOX_DEFAULT_BODYPADY = 20
const TKMESSAGEBOX_DEFAULT_FOOTERPADX = 20
const TKMESSAGEBOX_DEFAULT_FOOTERPADY = 14
const TKMESSAGEBOX_DEFAULT_ICONWIDTH = 32
const TKMESSAGEBOX_DEFAULT_ICONHEIGHT = 32
const TKMESSAGEBOX_DEFAULT_ICONGAP = 16
const TKMESSAGEBOX_DEFAULT_BUTTONGAP = 8
const TKMESSAGEBOX_DEFAULT_BUTTONMINWIDTH = 88
const TKMESSAGEBOX_DEFAULT_MAXWIDTH = 420
const TKMESSAGEBOX_DEFAULT_MINWIDTH = 300
const TKMESSAGEBOX_DEFAULT_BORDERTHICK = 1 ' never scaled
const TKMESSAGEBOX_DEFAULT_DIVIDERTHICK = 1 ' never scaled
const TKMESSAGEBOX_GLYPH_INFO = TK_ICON_INFO
const TKMESSAGEBOX_GLYPH_WARNING = TK_ICON_WARNING
const TKMESSAGEBOX_GLYPH_ERROR = TK_ICON_ERROR
const TKMESSAGEBOX_GLYPH_QUESTION = TK_ICON_QUESTION
const TKMESSAGEBOX_GLYPH_CLOSE = TK_ICON_CLOSE
const MBX_IDOK = 1
const MBX_IDCANCEL = 2
const MBX_IDABORT = 3
const MBX_IDRETRY = 4
const MBX_IDIGNORE = 5
const MBX_IDYES = 6
const MBX_IDNO = 7
const TKMBX_MSG_CLOSE = 1000

enum
    MBX_ICON_NONE = 0
    MBX_ICON_INFO
    MBX_ICON_WARNING
    MBX_ICON_ERROR
    MBX_ICON_QUESTION
end enum

enum
    MBX_BTN_OK = 0
    MBX_BTN_OKCANCEL
    MBX_BTN_YESNO
    MBX_BTN_YESNOCANCEL
    MBX_BTN_RETRYCANCEL
    MBX_BTN_SAVE_DONTSAVE_CANCEL
end enum

enum
    MBX_PART_CAPTION = 0
    MBX_PART_BODY
    MBX_PART_FOOTER
    MBX_PART_TEXT
    MBX_PART_ICON
    MBX_PART_CLOSE
end enum
```

### Types

```freebasic
type MBX_COLORS
    BorderColor           as ulong = &hFF464C56ul
    CaptionBackColor      as ulong = &hFF2C313Aul
    CaptionForeColor      as ulong = &hFFC8CDD6ul
    CloseBackColor        as ulong = &hFF2C313Aul     ' = CaptionBackColor: invisible until hot
    CloseForeColor        as ulong = &hFFC8CDD6ul
    CloseBackColorHot     as ulong = &hFFC42B1Cul
    CloseForeColorHot     as ulong = &hFFFFFFFFul
    CloseBackColorPressed as ulong = &hFFC8463Cul
    CloseForeColorPressed as ulong = &hFFFFFFFFul
    BackColor             as ulong = &hFF21252Bul
    ForeColor             as ulong = &hFFC8CDD6ul
    FooterBackColor       as ulong = &hFF282C33ul
    DividerColor          as ulong = &hFF373C45ul
    IconColorInfo         as ulong = &hFF61AFEFul
    IconColorWarning      as ulong = &hFFE5C07Bul
    IconColorError        as ulong = &hFFE06C75ul
    IconColorQuestion     as ulong = &hFF61AFEFul
end type

type MBX_PAINTINFO
    hMsgBox        as TK_WIDGET ptr
    b              as TK_PAINT ptr
    rcClient       as TKRECT
    rcCaption      as TKRECT
    rcCaptionText  as TKRECT
    rcClose        as TKRECT
    rcBody         as TKRECT
    rcIcon         as TKRECT
    rcText         as TKRECT            ' the WRAP box, not the ink
    rcFooter       as TKRECT
    isCloseHot     as boolean
    isClosePressed as boolean
    isActive       as boolean
    wszCaption     as ustring
    wszText        as ustring
    wszGlyph       as ustring
    clrIcon        as ulong
end type

type MBX_MESSAGEINFO
    hMsgBox    as TK_WIDGET ptr
    msg        as long                  ' TKM_* or TKMBX_MSG_CLOSE
    x          as single
    y          as single
    key        as long
    mods       as long
end type

type TKMESSAGEBOX_STATE   ' per-instance state; reach it through the procedures

type MBX_PaintCallbackSub as sub( byval p as MBX_PAINTINFO ptr )
type MBX_MessageCallbackFunc as function( byval m as MBX_MESSAGEINFO ptr ) as boolean
```

### Procedures

```freebasic
function tkMessageBox_ResolveGlyph( byval nKind as long ) as ustring
function tkMessageBox_ResolveIconColor( byval nKind as long, byval pColors as MBX_COLORS ptr ) as ulong
function tkMessageBox_Create( byval hParent as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkMessageBox_Destroy( byval hMsgBox as TK_WIDGET ptr )
function tkMessageBox_GetSurface( byval hMsgBox as TK_WIDGET ptr ) as TK_HOST ptr
function tkMessageBox_DoModal( byval hMsgBox as TK_WIDGET ptr ) as long
function tkMessageBox_Show( byval hParent as TK_WIDGET ptr, byval Text as ustring, byval Caption as ustring, byval nIconKind as long = MBX_ICON_NONE, byval nPreset as long = MBX_BTN_OK ) as long
sub tkMessageBox_LayoutForTest( byval hMsgBox as TK_WIDGET ptr )
function tkMessageBox_GetCaption( byval hMsgBox as TK_WIDGET ptr ) as ustring
sub tkMessageBox_SetCaption( byval hMsgBox as TK_WIDGET ptr, byval Text as ustring )
function tkMessageBox_GetText( byval hMsgBox as TK_WIDGET ptr ) as ustring
sub tkMessageBox_SetText( byval hMsgBox as TK_WIDGET ptr, byval Text as ustring )
function tkMessageBox_GetIconKind( byval hMsgBox as TK_WIDGET ptr ) as long
sub tkMessageBox_SetIconKind( byval hMsgBox as TK_WIDGET ptr, byval nKind as long )
sub tkMessageBox_SetGlyph( byval hMsgBox as TK_WIDGET ptr, byval Glyph as ustring )
sub tkMessageBox_SetIconColor( byval hMsgBox as TK_WIDGET ptr, byval clr as ulong )
sub tkMessageBox_SetBeep( byval hMsgBox as TK_WIDGET ptr, byval bBeep as boolean )
function tkMessageBox_GetBeep( byval hMsgBox as TK_WIDGET ptr ) as boolean
function tkMessageBox_AddButton( byval hMsgBox as TK_WIDGET ptr, byval Text as ustring, byval id as long ) as TK_WIDGET ptr
sub tkMessageBox_AddPreset( byval hMsgBox as TK_WIDGET ptr, byval nPreset as long )
function tkMessageBox_GetButtonCount( byval hMsgBox as TK_WIDGET ptr ) as long
function tkMessageBox_GetButtonHandle( byval hMsgBox as TK_WIDGET ptr, byval idx as long ) as TK_WIDGET ptr
function tkMessageBox_GetDefaultButton( byval hMsgBox as TK_WIDGET ptr ) as long
sub tkMessageBox_SetDefaultButton( byval hMsgBox as TK_WIDGET ptr, byval idx as long )
function tkMessageBox_GetFocusButton( byval hMsgBox as TK_WIDGET ptr ) as long
sub tkMessageBox_SetFocusButton( byval hMsgBox as TK_WIDGET ptr, byval idx as long )
function tkMessageBox_GetCancelID( byval hMsgBox as TK_WIDGET ptr ) as long
sub tkMessageBox_SetCancelID( byval hMsgBox as TK_WIDGET ptr, byval id as long )
sub tkMessageBox_SetMaxWidth( byval hMsgBox as TK_WIDGET ptr, byval nMaxWidth as long )
sub tkMessageBox_SetMinWidth( byval hMsgBox as TK_WIDGET ptr, byval nMinWidth as long )
sub tkMessageBox_SetCaptionHeight( byval hMsgBox as TK_WIDGET ptr, byval nHeight as long )
sub tkMessageBox_SetBodyPadding( byval hMsgBox as TK_WIDGET ptr, byval nX as long, byval nY as long )
sub tkMessageBox_SetFooterPadding( byval hMsgBox as TK_WIDGET ptr, byval nX as long, byval nY as long )
sub tkMessageBox_SetIconSize( byval hMsgBox as TK_WIDGET ptr, byval nIconWidth as long, byval nIconHeight as long )
sub tkMessageBox_SetIconGap( byval hMsgBox as TK_WIDGET ptr, byval nGap as long )
sub tkMessageBox_SetButtonGap( byval hMsgBox as TK_WIDGET ptr, byval nGap as long )
sub tkMessageBox_SetButtonMinWidth( byval hMsgBox as TK_WIDGET ptr, byval nMinWidth as long )
sub tkMessageBox_SetBorderThickness( byval hMsgBox as TK_WIDGET ptr, byval nThickness as long )
sub tkMessageBox_GetIdealSize( byval hMsgBox as TK_WIDGET ptr, byref nBoxWidth as long, byref nBoxHeight as long )
function tkMessageBox_GetCaptionRect( byval hMsgBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkMessageBox_GetCloseRect( byval hMsgBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkMessageBox_GetBodyRect( byval hMsgBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkMessageBox_GetIconRect( byval hMsgBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkMessageBox_GetTextRect( byval hMsgBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkMessageBox_GetFooterRect( byval hMsgBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkMessageBox_GetButtonRect( byval hMsgBox as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkMessageBox_GetFont( byval hMsgBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkMessageBox_SetFont( byval hMsgBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkMessageBox_GetCaptionFont( byval hMsgBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkMessageBox_SetCaptionFont( byval hMsgBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkMessageBox_GetGlyphFont( byval hMsgBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkMessageBox_SetGlyphFont( byval hMsgBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkMessageBox_GetCloseGlyphFont( byval hMsgBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkMessageBox_SetCloseGlyphFont( byval hMsgBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkMessageBox_ApplyFonts( byval hMsgBox as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkMessageBox_GetColors( byval hMsgBox as TK_WIDGET ptr, byval pColors as MBX_COLORS ptr )
sub tkMessageBox_SetColors( byval hMsgBox as TK_WIDGET ptr, byval pColors as MBX_COLORS ptr )
sub tkMessageBox_SetButtonColors( byval hMsgBox as TK_WIDGET ptr, byval pColors as TKBUTTON_COLORS ptr )
function tkMessageBox_ThemeColors( byref t as TKTHEME_COLORS ) as MBX_COLORS
sub tkMessageBox_ApplyTheme( byval hMsgBox as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkMessageBox_UnpinColors( byval hMsgBox as TK_WIDGET ptr )
sub tkMessageBox_SetPaintCallback( byval hMsgBox as TK_WIDGET ptr, byval usersub as MBX_PaintCallbackSub )
sub tkMessageBox_SetMessageCallback( byval hMsgBox as TK_WIDGET ptr, byval userfunc as MBX_MessageCallbackFunc )
function tkMessageBox_GetCloseHot( byval hMsgBox as TK_WIDGET ptr ) as boolean
function tkMessageBox_CountRenderedTones( byval hMsgBox as TK_WIDGET ptr, byval nPart as long ) as long
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [PsMessageBox](PsMessageBox), the PsControls control
