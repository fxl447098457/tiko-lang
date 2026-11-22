[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTextBox**

# tkTextBox

Draws an editable text box, single-line or word-wrapped multiline, with its own editor.

`tkTextBox` is the [tkControls](Category-tkControls) text entry: a rounded frame around a
self-drawn editor with selection, clipboard, undo and redo, word navigation, a cue banner and a
right-click menu. Single-line or multiline is fixed at creation. A multiline box word-wraps and
scrolls vertically only; Enter starts a new line and Tab inserts a tab. A single-line box always
claims Enter (and reports it through the Enter-pressed callback), lets Tab move focus, and centres
its text vertically.

Programmatic changes (`SetText`, `ReplaceSel`, `Clear`, `SetValue`) are silent; typing, Cut,
Paste, Undo, Delete and Backspace run the change callback. A single-line box also has a numeric
mode, which vets every keystroke and paste and reformats the value when focus leaves.

## Importing

```freebasic
#import "vendor/tkControls/tkTextBox"

using tkTextBox
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme), [tkPopupMenu](tkPopupMenu) (the context menu) and
[tkVScrollBar](tkVScrollBar) (the optional scrollbar). Add `using tkPopupMenu` to style the menu
returned by `tkTextBox_GetContextMenu`.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Search_Changed( byval hTextBox as TK_WIDGET ptr )
    print "typed: " & tkTextBox_GetText( hTextBox )
end sub

sub Search_Enter( byval hTextBox as TK_WIDGET ptr )
    print "search for [" & tkTextBox_GetText( hTextBox ) & "]"
end sub

dim as TK_WIDGET ptr search = tkTextBox_Create( tkHost_Root( host ), 4000 )
tkTextBox_SetCueBannerText( search, "Search anything..." )
tkTextBox_SetMargins( search, tkHost_Scale( host, 8 ), tkHost_Scale( host, 8 ) )
tkTextBox_SetChangeCallback( search, @Search_Changed )
tkTextBox_SetEnterPressedCallback( search, @Search_Enter )
tkWidget_SetPos( search, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkHost_Scale( host, 300 ), tkHost_Scale( host, 30 ) )

dim as TK_WIDGET ptr notes = tkTextBox_Create( tkHost_Root( host ), 4001, true )   ' multiline
tkTextBox_SetScrollBarVisible( notes, true )
```

## Offsets are bytes

The buffer is UTF-8. `GetSel`, `SetSel`, `GetCaret`, `GetTextLength`, `PosFromChar` and
`CharFromPos` work in **byte offsets**, snapped to character boundaries; for ASCII text they
equal character indices. `SetLimitText` counts characters, and its default 0 means no limit.

## Concepts

### One widget, one editor

`tkTextBox_Create( hParent, CtrlID, bMultiline = false )` creates the box as a child of a
`TK_WIDGET ptr` (for a top-level control pass `tkHost_Root( host )`); place it with
`tkWidget_SetPos`. The widget is focusable, shows the I-beam cursor, and draws its frame and
its editor itself. The buffer is one UTF-8 string with LF line breaks; the visual lines are
derived from it whenever the text, the width or the font changes.

### Single-line and multiline

The choice is made at creation and is fixed for the control's lifetime.

| | Single-line | Multiline |
|---|---|---|
| Text layout | One line, vertically centred in the frame | Word-wrapped from the top, at the last space that fits |
| Enter | Always claimed; runs the Enter-pressed callback | Inserts a new line |
| Tab | Not claimed, so the host moves focus | Inserts a tab; not claimed with Ctrl or when read-only |
| Horizontal scroll | Follows the caret | None: the text wraps |
| Vertical scroll | n/a | Wheel, keys, caret, optional built-in scrollbar |
| Up / Down / Page Up / Page Down | Not claimed | Move by line or page, keeping the column |
| Numeric mode | Available | Refused |
| Password character | Available | Refused |
| Pasted or set line breaks | Only the first line is kept | CRLF and lone CR become LF |
| Cue banner | One line, on the centred baseline | Word-wrapped at the top left |

### Programmatic changes are silent

`tkTextBox_SetText`, `tkTextBox_ReplaceSel`, `tkTextBox_Clear`, `tkTextBox_SetValue` and the
numeric reformat on focus loss never run the change callback. Typing, Backspace, Delete, Cut,
Paste, Undo and Redo do, whether they come from the keyboard, the context menu or
`tkTextBox_Cut` / `Paste` / `Undo` / `Redo`. So you can call a setter from inside your own change
handler without recursing.

### Undo, the modify flag and read-only

Every edit goes through one primitive, so undo, the length limit, the numeric filter and the
change notification each apply the same way everywhere. Undo keeps up to `TKTEXTBOX_MAX_UNDO`
steps; consecutive typing coalesces into one step until whitespace, a caret move or another
edit. `tkTextBox_ReplaceSel` is undoable. `tkTextBox_SetText`, `Clear`, `SetValue` and the
numeric reformat clear the undo history and the modify flag; any edit sets the flag.

A read-only box (`tkTextBox_SetReadOnly`) refuses typing, Cut, Paste, Undo and Redo, but still
selects and copies, and its context menu still offers Copy and Select All.

`tkTextBox_SetLimitText` counts characters. An insert that would pass the limit is trimmed to
fit; lowering the limit never truncates what is already there. A password box
(`tkTextBox_SetPasswordChar`, single-line only, 0 turns it off) shows the given character for
each character and will not copy or cut.

### Keyboard

Ctrl below is Cmd on macOS. Shift with any movement key extends the selection.

| Keys | Action |
|---|---|
| Ctrl+A | Select all |
| Ctrl+C, Ctrl+Insert | Copy |
| Ctrl+X, Shift+Delete | Cut |
| Ctrl+V, Shift+Insert | Paste |
| Ctrl+Z | Undo |
| Ctrl+Y, Ctrl+Shift+Z | Redo |
| Left / Right | One character; with a selection, collapse it to that side |
| Ctrl+Left / Ctrl+Right | One word |
| Up / Down / Page Up / Page Down | Multiline only: by line or page, keeping the column across moves |
| Home / End | Start / end of the line (multiline) or of the text (single-line) |
| Ctrl+Home / Ctrl+End | Start / end of the text |
| Backspace / Delete | Delete the selection, or the character before / after the caret |
| Ctrl+Backspace / Ctrl+Delete | Delete to the start / end of the word |
| Enter | Single-line: the Enter-pressed callback. Multiline: a new line |
| Tab | Multiline: a tab character. Single-line: not claimed |
| Menu key, Shift+F10 | Open the context menu at the caret |

Escape is not claimed; the message callback still sees it. While an input method is composing,
key presses belong to it: the composition is drawn inline at the caret, underlined, and
`tkTextBox_GetComposition` returns it.

### Mouse

A left click focuses the box and places the caret; Shift+click extends the selection; a double
click selects the word. Dragging selects, holding the capture, and dragging past an edge scrolls.
A right click focuses the box; the context menu opens on the right button's release. The wheel
scrolls a multiline box `TKTEXTBOX_WHEEL_LINES` lines per notch, and fractional notches
accumulate, so a slow trackpad swipe still scrolls; a single-line box does not handle the wheel.

`tkTextBox_SetSelectOnFocus` selects everything when the box gains focus by Tab or
programmatically; a click still places the caret where it lands.

### Numeric mode

Single-line only (`tkTextBox_SetNumericMode` is a no-op on a multiline box). The accepted text is
an optional leading minus, digits, and at most one decimal point followed by at most
`tkTextBox_GetDecimalPlaces` digits (default 2; 0 means integers only and refuses the point).
Every keystroke is checked against the text as it would be after replacing the selection, and a
paste is checked whole and refused whole.

On focus loss a non-empty value is reformatted to exactly the decimal places (`"5."` becomes
`"5.00"`), silently and before the focus callback runs. An empty box stays empty, and shows its
cue banner, unless `tkTextBox_SetZeroWhenEmpty` is on; turning that on stamps the formatted zero
at once if the box is numeric, empty and not focused. `tkTextBox_GetValue` reads empty, `"-"` and
`"."` as 0; `tkTextBox_SetValue` formats to the decimal places, without thousands separators.
Neither setting reformats text already in the box.

### Scrolling in lines

A multiline box exposes its vertical scroll state in lines, shaped for a scrollbar:
`tkTextBox_GetVScrollInfo` returns the total lines, the whole lines per page (a partial bottom
line is not counted) and the first visible line. All three are 0 before the box has a size; a
single-line box reports one line, first visible 0. `tkTextBox_ScrollToLine` makes a line the
first visible one, clamped, silently.

The scroll-changed callback fires whenever those three numbers change: typing, the wheel, caret
moves, a resize, and a programmatic `SetText` too. Treat it as "re-read the numbers", not "the
user scrolled". Wire an external scrollbar by pushing the numbers into it from that callback and
calling `tkTextBox_ScrollToLine` from the scrollbar's own callback.

Or let the box do it: `tkTextBox_SetScrollBarVisible( box, true )` adds a built-in
[tkVScrollBar](tkVScrollBar) along the right edge (multiline only, off by default), reachable
through `tkTextBox_GetScrollBar`. Its strip is reserved whether or not a thumb is needed, so text
never re-wraps on its account.

### The frame and the cue banner

Each repaint fills the whole widget with `OuterBackColor`, then draws the rounded frame filled
with `BackColor` and stroked in `FocusBorderColor` while the box has focus, `BorderColor`
otherwise. Pass your form's background as the outer colour so rounded corners blend in. A border
width of 0 draws no border. The editor area is the widget inset by the border width; the text
rect (`tkTextBox_GetTextRect`) is that area less the margins and any scrollbar strip.

The cue banner shows whenever the buffer is empty and nothing is being composed, focused or not,
where typed text would appear. It has its own colour and its own font, falling back to the text
font. `tkTextBox_ShowsCue` says whether it is showing.

`tkTextBox_SetTextAlign` aligns each line between the margins while it fits; a line wider than
the text rect starts at the left. An unrecognised value falls back to `TXT_ALIGN_LEFT`. Changing
the alignment keeps the undo history.

The selection is kept but not painted while the box is unfocused. Tabs are drawn and measured as
one space. The caret blinks with a half-period of `TKTEXTBOX_CARET_BLINK_MS` by default;
`tkTextBox_SetCaretBlink( box, 0 )` makes it steady.

### Pixels and scale

Margins and the corner radius are pixels; scale your literals with `tkHost_Scale`. When the
host's scale changes, the box rescales its margins, its corner radius, its scrollbar strip and its
context menu. The border width is a pen width and is never scaled. Until you set a corner radius
or border width, the box takes them from the current theme's shape; setting either pins it.

| Setting | Default |
|---|---|
| Border width | 1 px |
| Corner radius | 0 (square), unless the theme's shape says otherwise |
| Left / right margin | 0 / 0 |
| Text alignment | `TXT_ALIGN_LEFT` |
| Length limit | 0 (none) |
| Select on focus | off |
| Numeric mode / decimal places / zero when empty | off / 2 / off |
| Text font | 0: the host's default font |
| Cue banner font | 0: the text font |
| Context menu labels | `Cut`, `Copy`, `Paste`, `Select All` |

## Behaviour and limits

- **Multiline is a creation-time choice.** There is no setter.
- **Numeric mode and the password character are single-line only.**
- **A single-line Enter is always claimed**, callback or not.
- **No horizontal scroll API.** A single-line box follows its caret; a multiline box wraps.
- **No per-character formatting.** One font and one text colour for the whole buffer.
- **No vertical alignment setting.** A single-line box centres its line; a multiline box starts
  at the top.
- **Alignment is measured between the margins**, so lopsided margins put centred text
  off-centre.
- **The context menu is rebuilt on every open** from the selection, the clipboard and the
  read-only state: Cut (a selection, not read-only, not a password box), Copy (a selection, not a
  password box), Paste (text on the clipboard, not read-only), Select All (any text). When
  nothing qualifies, no menu opens.
- **Offsets are UTF-8 byte offsets** (see above); the length limit counts characters.

## Colours

`TKTEXTBOX_COLORS` holds nine colours. The box takes them from the current theme when it is
created (including any theme recipe for `"TextBox"`) and follows every theme change.
`tkTextBox_SetColors` and every per-colour setter pin the colours, so a theme change leaves this
box alone; `tkTextBox_UnpinColors` hands it back to the theme and applies it at once. The
per-colour setters that return a value return the previous colour.

| Colour | Paints | Theme role |
|---|---|---|
| `ForeColor` | All text, the caret and the composition underline | `Text` |
| `BackColor` | The editor's background, inside the frame | `Surface` |
| `CueColor` | The cue banner | `TextDim` |
| `BorderColor` | The frame without focus | `Border` |
| `FocusBorderColor` | The frame with focus | `FocusRing` |
| `OuterBackColor` | The whole widget under the frame, visible outside the rounded corners | `Window` |
| `SelBackColor` | The selection band | `Selected` |
| `SelForeColor` | Selected text | `SelectedText` |
| `ForeColorDisabled` | All text while the box is disabled | `TextDisabled` |

There is no hot or pressed variant; the frame takes exactly one of its two border colours per
repaint.

## Context menu

`tkTextBox_GetContextMenu` returns the box's [tkPopupMenu](tkPopupMenu), created with the box
and stable for its lifetime. Style it once with `tkPopupMenu`'s setters; it follows theme and
scale changes with the box. Its items are rebuilt on every open; `tkTextBox_SetMenuText`
localises the labels (an empty Select All label keeps the current one).
`tkTextBox_CloseContextMenu()` closes whichever text box menu is open, without running any
command.

## Callbacks

All are optional and independent; passing 0 clears one.

### Change

```freebasic
type TXT_ChangeCallbackSub as sub( byval hTextBox as TK_WIDGET ptr )
```

The user changed the text. Read it with `tkTextBox_GetText`. Never fired by the programmatic
setters listed above.

### Focus

```freebasic
type TXT_FocusCallbackSub as sub( byval hTextBox as TK_WIDGET ptr, byval bGotFocus as boolean )
```

The box gained or lost the keyboard focus. On a loss in numeric mode the value has already been
reformatted. `tkTextBox_HasFocus` asks the same question at any time.

### Enter pressed

```freebasic
type TXT_EnterPressedCallbackSub as sub( byval hTextBox as TK_WIDGET ptr )
```

The user pressed Enter in a single-line box. Never fired by a multiline box.

### Scroll changed

```freebasic
type TXT_ScrollChangedCallbackSub as sub( byval hTextBox as TK_WIDGET ptr )
```

The multiline scroll numbers changed; see *Scrolling in lines*. Not fired by
`tkTextBox_ScrollToLine`, which is the receiving end of a scrollbar.

### Message

```freebasic
type TXT_MessageCallbackFunc as function( byval m as TKTEXTBOX_MESSAGEINFO ptr ) as boolean
```

Observes messages **before** the box acts on them. Return TRUE to suppress the box's handling.
`TKTEXTBOX_MESSAGEINFO` carries `hTextBox`, `msg`, widget-local `x` / `y`, `key`, `mods`,
`wheelY` and `text` (UTF-8, for `TKM_CHAR` and `TKM_IMECOMPOSE`). It is called for
`TKM_KEYDOWN`, `TKM_KEYUP`, `TKM_CHAR`, `TKM_IMECOMPOSE`, `TKM_LBUTTONDOWN`, `TKM_LBUTTONUP`,
`TKM_RBUTTONDOWN`, `TKM_RBUTTONUP`, `TKM_MBUTTONDOWN`, `TKM_MBUTTONUP`, `TKM_MOUSEMOVE`,
`TKM_MOUSEWHEEL`, `TKM_SETFOCUS` and `TKM_KILLFOCUS`, and, after `TKM_RBUTTONUP`, once more as
`TKTEXTBOX_MSG_CONTEXTMENU` just before the menu would open.

| Veto | Effect |
|---|---|
| `TKM_KEYDOWN` for Tab in a single-line box | The key is claimed, so focus stays: how to drive something else, such as a picker list, with Tab |
| `TKM_KEYDOWN` for Escape | Act on Escape (clear the box, close a panel) |
| `TKTEXTBOX_MSG_CONTEXTMENU` | No menu opens on the right click (the Menu key and Shift+F10 arrive as `TKM_KEYDOWN`) |
| `TKM_SETFOCUS` / `TKM_KILLFOCUS` | The frame and caret still follow focus, but select-on-focus, the numeric reformat and the focus callback are skipped |
| `TKM_LBUTTONUP` | Use with care: it is what ends a selection drag and releases the capture |

```freebasic
function Search_Message( byval m as TKTEXTBOX_MESSAGEINFO ptr ) as boolean
    if (m->msg = TKM_KEYDOWN) andalso (m->key = SDLK_ESCAPE) then
        tkTextBox_Clear( m->hTextBox )     ' programmatic, so no change callback
        return true
    end if
    return false
end function
```

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKTEXTBOX_MSG_CONTEXTMENU = 1000
const TKTEXTBOX_CARET_BLINK_MS = 530
const TKTEXTBOX_MAX_UNDO = 100
const TKTEXTBOX_WHEEL_LINES = 3

enum
    TXT_ALIGN_LEFT = 0
    TXT_ALIGN_CENTER
    TXT_ALIGN_RIGHT
end enum

enum
    TKTEXTBOX_IDM_CUT = 1
    TKTEXTBOX_IDM_COPY
    TKTEXTBOX_IDM_PASTE
    TKTEXTBOX_IDM_SELECTALL
end enum
```

### Types

```freebasic
type TKTEXTBOX_COLORS
    ForeColor         as ulong = &hFFC8CDD6ul
    BackColor         as ulong = &hFF2C313Aul
    CueColor          as ulong = &hFF969CA6ul
    BorderColor       as ulong = &hFF444A56ul
    FocusBorderColor  as ulong = &hFF61AFEFul
    OuterBackColor    as ulong = &hFF21252Bul
    SelBackColor      as ulong = &hFF264F78ul
    SelForeColor      as ulong = &hFFFFFFFFul
    ForeColorDisabled as ulong = &hFF606670ul
end type

type TKTEXTBOX_MESSAGEINFO
    hTextBox as TK_WIDGET ptr
    msg      as long                    ' TKM_* or TKTEXTBOX_MSG_CONTEXTMENU
    x        as single
    y        as single
    key      as long
    mods     as long
    wheelY   as single                  ' TKM_MOUSEWHEEL: notches, positive = away
    text     as string                  ' TKM_CHAR / TKM_IMECOMPOSE: UTF-8
end type

type TKTB_UNDO
    sText   as string
    nCaret  as long
    nAnchor as long
end type

type TKTEXTBOX_STATE   ' per-instance state; reach it through the procedures

type TXT_ChangeCallbackSub as sub( byval hTextBox as TK_WIDGET ptr )
type TXT_FocusCallbackSub as sub( byval hTextBox as TK_WIDGET ptr, byval bGotFocus as boolean )
type TXT_EnterPressedCallbackSub as sub( byval hTextBox as TK_WIDGET ptr )
type TXT_ScrollChangedCallbackSub as sub( byval hTextBox as TK_WIDGET ptr )
type TXT_MessageCallbackFunc as function( byval m as TKTEXTBOX_MESSAGEINFO ptr ) as boolean
```

### Procedures

```freebasic
function tkTextBox_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long, byval bMultiline as boolean = false ) as TK_WIDGET ptr
function tkTextBox_GetMultiline( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_HasFocus( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_GetID( byval hTextBox as TK_WIDGET ptr ) as long
function tkTextBox_GetText( byval hTextBox as TK_WIDGET ptr ) as ustring
function tkTextBox_SetText( byval hTextBox as TK_WIDGET ptr, byval Text as ustring ) as boolean
function tkTextBox_GetTextLength( byval hTextBox as TK_WIDGET ptr ) as integer
function tkTextBox_GetSelText( byval hTextBox as TK_WIDGET ptr ) as ustring
function tkTextBox_ReplaceSel( byval hTextBox as TK_WIDGET ptr, byval Text as ustring ) as boolean
function tkTextBox_Clear( byval hTextBox as TK_WIDGET ptr ) as boolean
sub tkTextBox_GetSel( byval hTextBox as TK_WIDGET ptr, byref nStart as integer, byref nEnd as integer )
sub tkTextBox_SetSel( byval hTextBox as TK_WIDGET ptr, byval nStart as integer, byval nEnd as integer )
sub tkTextBox_SelectAll( byval hTextBox as TK_WIDGET ptr )
function tkTextBox_GetCaret( byval hTextBox as TK_WIDGET ptr ) as integer
function tkTextBox_GetLimitText( byval hTextBox as TK_WIDGET ptr ) as integer
sub tkTextBox_SetLimitText( byval hTextBox as TK_WIDGET ptr, byval nLimit as integer )
function tkTextBox_GetReadOnly( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_SetReadOnly( byval hTextBox as TK_WIDGET ptr, byval bReadOnly as boolean ) as boolean
function tkTextBox_GetModify( byval hTextBox as TK_WIDGET ptr ) as boolean
sub tkTextBox_SetModify( byval hTextBox as TK_WIDGET ptr, byval bModified as boolean )
sub tkTextBox_SetPasswordChar( byval hTextBox as TK_WIDGET ptr, byval wchChar as integer )
function tkTextBox_GetPasswordChar( byval hTextBox as TK_WIDGET ptr ) as integer
function tkTextBox_GetSelectOnFocus( byval hTextBox as TK_WIDGET ptr ) as boolean
sub tkTextBox_SetSelectOnFocus( byval hTextBox as TK_WIDGET ptr, byval bSelect as boolean )
sub tkTextBox_GetMargins( byval hTextBox as TK_WIDGET ptr, byref nLeft as integer, byref nRight as integer )
sub tkTextBox_SetMargins( byval hTextBox as TK_WIDGET ptr, byval nLeft as integer, byval nRight as integer )
sub tkTextBox_Cut( byval hTextBox as TK_WIDGET ptr )
sub tkTextBox_Copy( byval hTextBox as TK_WIDGET ptr )
sub tkTextBox_Paste( byval hTextBox as TK_WIDGET ptr )
function tkTextBox_CanPaste( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_Undo( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_CanUndo( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_Redo( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_CanRedo( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_GetNumericMode( byval hTextBox as TK_WIDGET ptr ) as boolean
sub tkTextBox_SetNumericMode( byval hTextBox as TK_WIDGET ptr, byval bEnable as boolean )
function tkTextBox_GetDecimalPlaces( byval hTextBox as TK_WIDGET ptr ) as integer
sub tkTextBox_SetDecimalPlaces( byval hTextBox as TK_WIDGET ptr, byval nPlaces as integer )
function tkTextBox_GetValue( byval hTextBox as TK_WIDGET ptr ) as double
function tkTextBox_SetValue( byval hTextBox as TK_WIDGET ptr, byval nValue as double ) as boolean
function tkTextBox_GetZeroWhenEmpty( byval hTextBox as TK_WIDGET ptr ) as boolean
sub tkTextBox_SetZeroWhenEmpty( byval hTextBox as TK_WIDGET ptr, byval bEnable as boolean )
sub tkTextBox_GetVScrollInfo( byval hTextBox as TK_WIDGET ptr, byref nTotalLines as integer, byref nLinesPerPage as integer, byref nFirstVisibleLine as integer )
sub tkTextBox_ScrollToLine( byval hTextBox as TK_WIDGET ptr, byval nLine as integer )
sub tkTextBox_SetScrollBarVisible( byval hTextBox as TK_WIDGET ptr, byval bShow as boolean )
function tkTextBox_GetScrollBar( byval hTextBox as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkTextBox_GetTextRect( byval hTextBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkTextBox_PosFromChar( byval hTextBox as TK_WIDGET ptr, byval nOffset as integer, byref x as long, byref y as long )
function tkTextBox_CharFromPos( byval hTextBox as TK_WIDGET ptr, byval x as long, byval y as long ) as integer
function tkTextBox_GetCaretRect( byval hTextBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkTextBox_GetCaretVisible( byval hTextBox as TK_WIDGET ptr ) as boolean
sub tkTextBox_SetCaretBlink( byval hTextBox as TK_WIDGET ptr, byval nMs as long )
function tkTextBox_GetCaretBlink( byval hTextBox as TK_WIDGET ptr ) as long
function tkTextBox_GetComposition( byval hTextBox as TK_WIDGET ptr ) as ustring
function tkTextBox_GetFont( byval hTextBox as TK_WIDGET ptr ) as TTF_Font ptr
function tkTextBox_SetFont( byval hTextBox as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
sub tkTextBox_GetColors( byval hTextBox as TK_WIDGET ptr, byval pColors as TKTEXTBOX_COLORS ptr )
sub tkTextBox_SetColors( byval hTextBox as TK_WIDGET ptr, byval pColors as TKTEXTBOX_COLORS ptr )
function tkTextBox_GetForeColor( byval hTextBox as TK_WIDGET ptr ) as ulong
function tkTextBox_SetForeColor( byval hTextBox as TK_WIDGET ptr, byval clr as ulong ) as ulong
function tkTextBox_GetBackColor( byval hTextBox as TK_WIDGET ptr ) as ulong
function tkTextBox_SetBackColor( byval hTextBox as TK_WIDGET ptr, byval clr as ulong ) as ulong
function tkTextBox_GetCueBannerColor( byval hTextBox as TK_WIDGET ptr ) as ulong
sub tkTextBox_SetCueBannerColor( byval hTextBox as TK_WIDGET ptr, byval clr as ulong )
function tkTextBox_GetBorderColor( byval hTextBox as TK_WIDGET ptr ) as ulong
sub tkTextBox_SetBorderColor( byval hTextBox as TK_WIDGET ptr, byval clr as ulong )
function tkTextBox_GetFocusBorderColor( byval hTextBox as TK_WIDGET ptr ) as ulong
sub tkTextBox_SetFocusBorderColor( byval hTextBox as TK_WIDGET ptr, byval clr as ulong )
function tkTextBox_GetOuterBackColor( byval hTextBox as TK_WIDGET ptr ) as ulong
sub tkTextBox_SetOuterBackColor( byval hTextBox as TK_WIDGET ptr, byval clr as ulong )
function tkTextBox_GetCueBannerText( byval hTextBox as TK_WIDGET ptr ) as ustring
sub tkTextBox_SetCueBannerText( byval hTextBox as TK_WIDGET ptr, byval Text as ustring )
function tkTextBox_GetCueBannerFont( byval hTextBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkTextBox_SetCueBannerFont( byval hTextBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkTextBox_ShowsCue( byval hTextBox as TK_WIDGET ptr ) as boolean
function tkTextBox_GetTextAlign( byval hTextBox as TK_WIDGET ptr ) as long
sub tkTextBox_SetTextAlign( byval hTextBox as TK_WIDGET ptr, byval nAlign as long )
function tkTextBox_GetBorderWidth( byval hTextBox as TK_WIDGET ptr ) as integer
sub tkTextBox_SetBorderWidth( byval hTextBox as TK_WIDGET ptr, byval nWidth as integer )
function tkTextBox_GetCornerRadius( byval hTextBox as TK_WIDGET ptr ) as integer
sub tkTextBox_SetCornerRadius( byval hTextBox as TK_WIDGET ptr, byval nRadius as integer )
function tkTextBox_ThemeColors( byref t as TKTHEME_COLORS ) as TKTEXTBOX_COLORS
sub tkTextBox_ApplyTheme( byval hTextBox as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkTextBox_UnpinColors( byval hTextBox as TK_WIDGET ptr )
sub tkTextBox_ApplyFonts( byval hTextBox as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkTextBox_SetMenuText( byval hTextBox as TK_WIDGET ptr, byval CutText as ustring, byval CopyText as ustring, byval PasteText as ustring, byval SelectAllText as ustring = "" )
function tkTextBox_GetContextMenu( byval hTextBox as TK_WIDGET ptr ) as TK_MENU ptr
sub tkTextBox_CloseContextMenu()
sub tkTextBox_SetChangeCallback( byval hTextBox as TK_WIDGET ptr, byval usersub as TXT_ChangeCallbackSub )
sub tkTextBox_SetFocusCallback( byval hTextBox as TK_WIDGET ptr, byval usersub as TXT_FocusCallbackSub )
sub tkTextBox_SetEnterPressedCallback( byval hTextBox as TK_WIDGET ptr, byval usersub as TXT_EnterPressedCallbackSub )
sub tkTextBox_SetMessageCallback( byval hTextBox as TK_WIDGET ptr, byval userfunc as TXT_MessageCallbackFunc )
sub tkTextBox_SetScrollChangedCallback( byval hTextBox as TK_WIDGET ptr, byval usersub as TXT_ScrollChangedCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme), [tkPopupMenu](tkPopupMenu), [tkVScrollBar](tkVScrollBar)
