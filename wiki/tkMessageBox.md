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

## Showing it

`tkMessageBox_Create( hParent )` makes a hidden, borderless dialog window owned by `hParent`'s
window (`hParent` may be 0 for an unowned box); the handle it returns is the box widget that
fills that window. Nothing is shown until `tkMessageBox_DoModal`, which:

1. measures the box and sizes its window to `tkMessageBox_GetIdealSize`;
2. centres it on the owner window, or on the display when there is no owner, clamped into the
   display's usable area (on Wayland the compositor places windows, so centring is a request);
3. gives the keyboard focus to the starting button (see below);
4. runs a modal loop, during which the owner window receives no input;
5. destroys the box and returns the dismissing id.

A quit request ends the loop with 0 and is re-posted, so your own loop still sees it. A box you
built but decided not to show is freed with `tkMessageBox_Destroy`. `tkMessageBox_GetSurface`
returns the box's window as a `TK_HOST ptr`; the first layout replaces the window `Create` made,
so the answer is final only after `tkMessageBox_LayoutForTest` (or inside `DoModal`).

## Buttons and dismissal

- The six `MBX_BTN_*` presets add their buttons, make the first the default and set the cancel
  id: OK (cancel OK), OK / Cancel, Yes / No (cancel No), Yes / No / Cancel, Retry / Cancel, and
  Save / Don't Save / Cancel, which returns `MBX_IDYES` / `MBX_IDNO` / `MBX_IDCANCEL`. The
  captions are English literals; a localised program uses `tkMessageBox_AddButton`.
  `tkMessageBox_AddPreset` is additive: it appends to the buttons already there.
- `tkMessageBox_AddButton( h, Text, id )` adds a button of your own and returns the tkButton, or
  0 once the box holds `TKMESSAGEBOX_MAXBUTTONS` (3). `id` is yours and is exactly what `DoModal`
  returns. The box's text font, glyph font and button colours are pushed into each new button,
  so configuring before or after adding gives the same result.
- Clicking a button (or Space / Enter on the focused one) returns its id. Esc, the close X and
  the window's own close (Alt+F4, the window manager) return the cancel id. A box with no
  buttons returns 0.
- **The cancel id defaults to the LAST button's id.** That is right for every preset, where the
  last button is Cancel or No, but a box whose last button is destructive must call
  `tkMessageBox_SetCancelID`, or Esc performs the destructive action.
  `tkMessageBox_GetCancelID` reports the resolved answer.
- `tkMessageBox_SetDefaultButton( h, idx )` gives that button the accent border, makes Enter fire
  it box-wide, and makes it the starting focus; -1 clears it, and there is never more than one
  default.
- The focus starts on the button set with `tkMessageBox_SetFocusButton`, else the default button,
  else the first; `tkMessageBox_GetFocusButton` reports that resolved index (-1 with no buttons).
  To have the focus differ from the default, call `SetFocusButton` after `SetDefaultButton`; once
  set it cannot be unset.
- Enter fires the focused button. It reaches the box, and fires the default, only when no button
  claims it.

## Mouse and keyboard

- The caption band drags the window, all of it except the close X.
- The close X has a press / slide-off / release gesture: press it, slide off, release, and
  nothing happens. It is invisible until the pointer reaches it (its idle background equals the
  caption's), then shows hot, and pressed while held.
- Tab and Shift+Tab move the focus between the buttons, in the order they were added.
- The message is drawn text: it cannot be selected or copied.
- There is no system sound: `tkMessageBox_SetBeep` is stored and reported by
  `tkMessageBox_GetBeep`, but nothing beeps.

## Layout

Three bands tile the box, each the full width: the **caption** (its height is declared by
`tkMessageBox_SetCaptionHeight`, never measured, so a title too tall for it clips), the
**body**, and the **footer**, `2 × footerPadY` plus the tallest button's height, or nothing when
there are no buttons. The title sits `captionPadX` in from the left and ellipsises before the
close X's cell at the right edge; an empty title still leaves the band and the X.

```
  iconBlock = hasIcon ? iconWidth + iconGap : 0
  wrapW     = maxWidth - 2*bodyPadX - iconBlock          (at least 40)
  textW/H   = the message wrapped at wrapW: its widest line, its height

  idealW    = max( 2*bodyPadX + iconBlock + textW,
                   2*footerPadX + sum(button widths) + (n-1)*buttonGap,
                   captionPadX + titleWidth + closeWidth,
                   minWidth )
  idealH    = captionHeight + 2*bodyPadY + max( textH, hasIcon ? iconHeight : 0 ) + footerH
```

- `tkMessageBox_SetMaxWidth` sets the wrap width, not a cap on the box: wide buttons or a long
  title still make the box wider. The box shrinks to fit the text it actually wraps, down to
  `tkMessageBox_SetMinWidth`.
- The message is left-aligned and wrapped in the text font; a newline starts a new line, CR is
  dropped and a tab becomes four spaces.
- The icon and the text are centred vertically on the taller of the two. `MBX_ICON_NONE` removes
  the icon cell and its gap from the layout. The icon cell is declared, not measured, so size it
  (`tkMessageBox_SetIconSize`) to the icon font or the glyph clips.
- Every button gets the tallest one's height and its own ideal width, raised to
  `tkMessageBox_SetButtonMinWidth`. The buttons are right-aligned and run left to right in the
  order added.
- The defaults (the `TKMESSAGEBOX_DEFAULT_*` constants) are scaled when the box is created and
  rescaled when the display scale changes, except the border and the footer divider, hairlines
  that keep their thickness (1 pixel by default) at every scale. Setters take pixels at the
  current scale. Out-of-range values are ignored: a negative size, padding or gap, a maximum
  width below 1, an unknown icon kind, a button index outside the buttons.
- Setters are silent and lazy: the next paint or query lays the box out once. The ideal size is
  valid before the box has ever been sized. The rect queries return FALSE until the box has a
  size (after `LayoutForTest` or inside `DoModal`); an absent part answers TRUE with an empty
  rect.

## Fonts and icons

All four fonts are borrowed: keep them alive while the box is up.

- `tkMessageBox_SetFont`: the message, and the measuring font, so it decides the wrap and the
  height. It is also pushed into every button. Unset, the host's default font is used.
- `tkMessageBox_SetCaptionFont`: the title; unset, the message font.
- `tkMessageBox_SetGlyphFont`: the message icon, an icon font sized to fill the icon cell. It is
  also the buttons' glyph font. Unset, the message font is used and the icon draws as a missing
  glyph.
- `tkMessageBox_SetCloseGlyphFont`: the close X, a small icon font; unset, the icon font, which
  draws an X as large as the icon.
- `tkMessageBox_ApplyFonts( h, fText, fGlyph )` sets the message and icon fonts together.

`tkMessageBox_SetIconKind` picks the glyph (`TKMESSAGEBOX_GLYPH_*`, glyphs of the bundled icon
font) and its colour. `tkMessageBox_SetGlyph` overrides the glyph per box, and turns the icon on
even at `MBX_ICON_NONE`; `""` clears the override. `tkMessageBox_SetIconColor` overrides the
colour and cannot be undone. `tkMessageBox_ResolveGlyph` and `tkMessageBox_ResolveIconColor` are
pure functions of the kind and ignore both overrides; the colour of `MBX_ICON_NONE` is the body's
`ForeColor`.

## Colours and theme

The box starts from the current [tkTheme](tkTheme) palette (`tkMessageBox_ThemeColors`), and
its buttons from tkButton's, and both follow theme changes. `tkMessageBox_SetColors` and
`tkMessageBox_SetButtonColors` pin them; `tkMessageBox_UnpinColors` hands both back to the
theme. `SetButtonColors` reaches the buttons that exist now and every button added later.
There is no disabled colour anywhere: everything on a modal box is live.

The built-in painter fills the client with `BackColor`, then draws the caption band, the close X
(pressed > hot > idle), the title, the footer band with a `DividerColor` hairline along its top,
the icon centred in its cell, the message, and last the border, so no band covers it
(`tkMessageBox_SetBorderThickness`, 0 for none). It ignores `isActive`.

## Callbacks

**Paint.** `tkMessageBox_SetPaintCallback` replaces the built-in painter; the client is already
filled with `BackColor`, and the buttons still paint themselves. Use the rects in
`MBX_PAINTINFO` as given; `wszGlyph` and `clrIcon` already include the overrides, and `isActive`
is TRUE while the box's window has the keyboard focus. Draw the message with the font given to
`SetFont`, wrapped (`PaintTextEx` with `TK_DT_WORDBREAK`), with CR removed and tabs as four
spaces, or the measured height is wrong. `PaintBorderRect` and `PaintRoundBorderRect` fill
before they stroke and flood everything beneath them; outline with `PaintRoundOutline` or
`PaintLine`. `tkMessageBox_CountRenderedTones( h, MBX_PART_* )` renders the box with its current
painter and counts the distinct colours in one part (up to 64), so a test can catch a part that
was wiped to one colour.

**Message.** `tkMessageBox_SetMessageCallback` observes the box's mouse moves and leaves, button
presses and releases, the keys that reach the box (Esc, and Enter when no button takes it),
`TKMBX_MSG_CLOSE` (Esc, the X or the window's close, with no position or key) and `TKM_DESTROY`.
Returning TRUE suppresses a left press (on the X) or a key; the result is ignored for everything
else, so the close cannot be vetoed. It is a natural place to raise a nested box.

**Testing.** `tkMessageBox_LayoutForTest` sizes the box to its ideal size without showing it or
running the loop, so the rect queries and `CountRenderedTones` work; free the box afterwards
with `tkMessageBox_Destroy`.

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
- [tkButton](tkButton), the footer buttons
