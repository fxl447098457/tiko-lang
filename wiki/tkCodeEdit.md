[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkCodeEdit**

# tkCodeEdit

Embeds a Scintilla code editor as a tkControls widget, with lexing, folding and IME.

tkCodeEdit is a full Scintilla 5.5.7 editor, with Lexilla's tiko lexer, as a tkControls widget: styles, margins, folding, markers, indicators, multiple carets, rectangular selection, autocompletion lists, call tips, a context menu, inline IME composition and per-monitor scale. You drive it with Scintilla's own messages through `tkCodeEdit_Send( h, SCI_*, wParam, lParam )`, so Scintilla's documentation is the reference for what each message does.

The editor's colours and fonts are Scintilla styles that you set, not [tkTheme](tkTheme) roles; only the autocompletion list follows the theme's popup and selection roles.

## Importing

```freebasic
#import "vendor/tkControls/tkCodeEdit"

using tkCodeEdit
using tkHost
```

The module also carries Scintilla's and Lexilla's interface constants (`SCI_*`, `SCN_*`, `SC_*`, `STYLE_*`, `INDIC_*`, `SCE_B_*`, `SCLEX_TIKO`), declared in a second file of the same module, so the one `#import` and `using tkCodeEdit` bring them too. tkCodeEdit re-exports [tkHost](tkHost) and [tkTheme](tkTheme) and imports `std/containers` itself.

## Example

Adapted from the toolchain's `examples/tkControls/tkCodeEdit/`:

```freebasic
' Scintilla takes colours as &hBBGGRR
function Bgr( byval rgb as ulong ) as long
    return ((rgb and &hFF) shl 16) or (rgb and &hFF00) or ((rgb shr 16) and &hFF)
end function

dim as TK_WIDGET ptr ed = tkCodeEdit_Create( tkForm_Widget( f ), 100 )
if ed = 0 then print "tkCodeEdit: " & tkCodeEdit_LibraryError() : end 1
tkCodeEdit_SetFont( ed, tkHost_FontDir() & TK_FONT_MONO, 10 )   ' every style
tkCodeEdit_Send( ed, SCI_STYLESETFORE, STYLE_DEFAULT, Bgr( &hD4D4D4 ) )
tkCodeEdit_Send( ed, SCI_STYLESETBACK, STYLE_DEFAULT, Bgr( &h1E1F22 ) )
tkCodeEdit_Send( ed, SCI_STYLECLEARALL )                         ' copy the default into every style
tkCodeEdit_SetLexer( ed, "tiko" )
tkCodeEdit_SendText( ed, SCI_SETKEYWORDS, 0, "dim as long sub end function return if then else" )
tkCodeEdit_Send( ed, SCI_STYLESETFORE, SCE_B_KEYWORD, Bgr( &h569CD6 ) )
tkCodeEdit_Send( ed, SCI_STYLESETFORE, SCE_B_COMMENT, Bgr( &h6A9955 ) )
tkCodeEdit_Send( ed, SCI_SETMARGINTYPEN, 0, SC_MARGIN_NUMBER )   ' line numbers
tkCodeEdit_Send( ed, SCI_SETMARGINWIDTHN, 0, tkCodeEdit_SendText( ed, SCI_TEXTWIDTH, STYLE_LINENUMBER, "_9999" ) )
tkCodeEdit_SetText( ed, "' hello" & chr( 10 ) & "print ""hi""" & chr( 10 ) )
tkCodeEdit_SetNotifyCallback( ed, @OnSciNotify )
```

```freebasic
sub OnSciNotify( byval hEdit as TK_WIDGET ptr, byval n as const TKCE_NOTIFICATION ptr )
    select case n->code
    case SCN_SAVEPOINTLEFT : print "modified"
    case SCN_CHARADDED     : print "typed " & n->ch
    end select
end sub
```

## The scintk library

The editor itself is **scintk**, a Scintilla and Lexilla build made for tkControls. It is a shared library loaded at run time, not linked: tiko copies it beside every program that imports tkCodeEdit, as `scintk.dll` on Windows, `libscintk.so` on Linux and `libscintk.dylib` on macOS, and the first `tkCodeEdit_Create` loads it from the program's folder. A program that never creates an editor never loads it. When it cannot be loaded, `tkCodeEdit_Create` returns 0 and `tkCodeEdit_LibraryError` says why. Ship the library beside the program.

## Things to know

- **Text** is UTF-8. `tkCodeEdit_SendText` passes a string parameter (`SCI_SETKEYWORDS`, `SCI_STYLESETFONT`, `SCI_AUTOCSHOW` ...); `tkCodeEdit_GetText` and `tkCodeEdit_SetText` move the whole document as a `ustring`.
- **Fonts are files.** `tkCodeEdit_SetFont( h, file, points )` gives every style one font file, at the editor's scale, and resets the styles (`SCI_STYLECLEARALL`), so set style colours after it. `tkCodeEdit_SetFontFace( family, regular, bold, italic, boldItalic )` maps a family name, as `SCI_STYLESETFONT` names it, to files; a missing bold or italic file renders the regular one. `tkCodeEdit_SetFallbackFonts` names, one per line, the faces a glyph the editor font lacks is drawn from (for example a CJK font); call it before `tkCodeEdit_SetFont`. A face inside a `.ttc` collection is written `"path|Family"` (see [tkFontList](tkFontList)).
- **Fonts start bundled.** Until something calls `tkCodeEdit_SetFont`, editors draw in the bundled mono face (`TK_FONT_MONO` beside the program) at 10 points; without a font file nothing would be drawn or measured.
- **Notifications** arrive through `tkCodeEdit_SetNotifyCallback` as `TKCE_NOTIFICATION`, which carries Scintilla's notification fields; `n->code` is an `SCN_*` value. `n->text` is borrowed: copy it during the callback. The common ones also have callbacks of their own, called after the notify callback: `SetChangeCallback` (text inserted or deleted, by the user or by code), `SetCharAddedCallback`, `SetUpdateUICallback`, `SetDirtyCallback` (left or returned to the save point `SCI_SETSAVEPOINT` marks), `SetMarginClickCallback` (which makes the margins click-sensitive) and `SetDoubleClickCallback`.
- **Settings by name.** For a form designer, the common `SCI_*` settings have setters and getters of their own: `ReadOnly`, `TabWidth`, `IndentWidth`, `UseTabs`, `EOLMode` (`TKCE_EOL_*`), `WrapMode` (`TKCE_WRAP_*`), `LineNumbers` (margin 0 sized for five digits, again when the font or scale changes), `IndentGuides`, `HighlightCurrentLine`, `ViewWhitespace`, `ViewEOL`, `Zoom` and `SetKeywords` (the lexer's first list).
- **Context menu.** Right-click shows Scintilla's own menu (Undo, Cut, Copy, Paste, Select All ...). `tkCodeEdit_SetContextMenuCallback( h, proc )` replaces it with yours; `proc` gets editor pixels.
- **Scale.** Each editor restyles its fonts when its window moves to a monitor with another scale. Margins you sized in pixels are yours to resize: `tkCodeEdit_SetScaleCallback` tells you when.
- **Keys.** The editor claims the keys Scintilla uses; the rest bubble to its parent as usual, and a [tkKeys](tkKeys) map attached to the surface is asked first.
- **Popups.** The autocompletion list and the call tip are popup surfaces, `tkCodeEdit_ListPopup()` and `tkCodeEdit_CallTipPopup()` while open (0 when closed).

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKCE_ABI_VERSION = 2

enum
    TKCE_WRAP_NONE = 0
    TKCE_WRAP_WORD
    TKCE_WRAP_CHAR
    TKCE_WRAP_WHITESPACE
end enum

enum
    TKCE_EOL_CRLF = 0
    TKCE_EOL_CR
    TKCE_EOL_LF
end enum
```

### Types

```freebasic
type TKCE_NOTIFICATION
    code                 as long
    position             as longint
    ch                   as long
    modifiers            as long
    modificationType     as long
    text                 as const zstring ptr     ' borrowed: valid during the callback only
    length               as longint
    linesAdded           as longint
    message              as long
    wParam               as longint
    lParam               as longint
    line_                as longint
    foldLevelNow         as long
    foldLevelPrev        as long
    margin               as long
    listType             as long
    x                    as long
    y                    as long
    token                as long
    annotationLinesAdded as longint
    updated              as long
    listCompletionMethod as long
end type

type TKCODEEDIT_NotifySub as sub( byval hEdit as TK_WIDGET ptr, byval n as const TKCE_NOTIFICATION ptr )
type TKCODEEDIT_ContextMenuSub as sub( byval hEdit as TK_WIDGET ptr, byval x as long, byval y as long )
type TKCODEEDIT_ScaleSub as sub( byval hEdit as TK_WIDGET ptr, byval fOld as single, byval fNew as single )
```

### Procedures

```freebasic
function tkCodeEdit_LibraryError() as string
function tkCodeEdit_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkCodeEdit_Send( byval hEdit as TK_WIDGET ptr, byval msg as ulong, byval wp as uinteger = 0, byval lp as integer = 0 ) as integer
function tkCodeEdit_SendText( byval hEdit as TK_WIDGET ptr, byval msg as ulong, byval wp as uinteger, byref s as ustring ) as integer
function tkCodeEdit_GetText( byval hEdit as TK_WIDGET ptr ) as ustring
sub tkCodeEdit_SetText( byval hEdit as TK_WIDGET ptr, byref s as ustring )
sub tkCodeEdit_SetFont( byval hEdit as TK_WIDGET ptr, byref sFile as const ustring, byval nPoints as long )
function tkCodeEdit_SetLexer( byval hEdit as TK_WIDGET ptr, byref sName as string ) as boolean
sub tkCodeEdit_SetNotifyCallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_NotifySub )
function tkCodeEdit_LastPaintMs( byval hEdit as TK_WIDGET ptr ) as double
function tkCodeEdit_PaintCount( byval hEdit as TK_WIDGET ptr ) as long
function tkCodeEdit_BlitCount( byval hEdit as TK_WIDGET ptr ) as long
function tkCodeEdit_Profile() as string
function tkCodeEdit_IsDirty( byval hEdit as TK_WIDGET ptr ) as boolean
sub tkCodeEdit_SetFontFace( byref sFamily as string, byref sRegular as string, byref sBold as string = "", byref sItalic as string = "", byref sBoldItalic as string = "" )
sub tkCodeEdit_SetFallbackFonts( byref sChain as string )
sub tkCodeEdit_SetContextMenuCallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_ContextMenuSub )
sub tkCodeEdit_SetScaleCallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_ScaleSub )
sub tkCodeEdit_SetReadOnly( byval hEdit as TK_WIDGET ptr, byval bReadOnly as boolean )
function tkCodeEdit_GetReadOnly( byval hEdit as TK_WIDGET ptr ) as boolean
sub tkCodeEdit_SetTabWidth( byval hEdit as TK_WIDGET ptr, byval nWidth as long )
function tkCodeEdit_GetTabWidth( byval hEdit as TK_WIDGET ptr ) as long
sub tkCodeEdit_SetIndentWidth( byval hEdit as TK_WIDGET ptr, byval nWidth as long )
function tkCodeEdit_GetIndentWidth( byval hEdit as TK_WIDGET ptr ) as long
sub tkCodeEdit_SetUseTabs( byval hEdit as TK_WIDGET ptr, byval bUseTabs as boolean )
function tkCodeEdit_GetUseTabs( byval hEdit as TK_WIDGET ptr ) as boolean
sub tkCodeEdit_SetEOLMode( byval hEdit as TK_WIDGET ptr, byval nMode as long )
function tkCodeEdit_GetEOLMode( byval hEdit as TK_WIDGET ptr ) as long
sub tkCodeEdit_SetWrapMode( byval hEdit as TK_WIDGET ptr, byval nMode as long )
function tkCodeEdit_GetWrapMode( byval hEdit as TK_WIDGET ptr ) as long
sub tkCodeEdit_SetLineNumbers( byval hEdit as TK_WIDGET ptr, byval bShow as boolean )
function tkCodeEdit_GetLineNumbers( byval hEdit as TK_WIDGET ptr ) as boolean
sub tkCodeEdit_SetIndentGuides( byval hEdit as TK_WIDGET ptr, byval bShow as boolean )
function tkCodeEdit_GetIndentGuides( byval hEdit as TK_WIDGET ptr ) as boolean
sub tkCodeEdit_SetHighlightCurrentLine( byval hEdit as TK_WIDGET ptr, byval bShow as boolean )
function tkCodeEdit_GetHighlightCurrentLine( byval hEdit as TK_WIDGET ptr ) as boolean
sub tkCodeEdit_SetViewWhitespace( byval hEdit as TK_WIDGET ptr, byval bShow as boolean )
function tkCodeEdit_GetViewWhitespace( byval hEdit as TK_WIDGET ptr ) as boolean
sub tkCodeEdit_SetViewEOL( byval hEdit as TK_WIDGET ptr, byval bShow as boolean )
function tkCodeEdit_GetViewEOL( byval hEdit as TK_WIDGET ptr ) as boolean
sub tkCodeEdit_SetZoom( byval hEdit as TK_WIDGET ptr, byval nPoints as long )
function tkCodeEdit_GetZoom( byval hEdit as TK_WIDGET ptr ) as long
sub tkCodeEdit_SetKeywords( byval hEdit as TK_WIDGET ptr, byval sWords as ustring )
sub tkCodeEdit_SetChangeCallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_ChangeSub )
sub tkCodeEdit_SetCharAddedCallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_CharAddedSub )
sub tkCodeEdit_SetUpdateUICallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_UpdateUISub )
sub tkCodeEdit_SetDirtyCallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_DirtySub )
sub tkCodeEdit_SetMarginClickCallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_MarginClickSub )
sub tkCodeEdit_SetDoubleClickCallback( byval hEdit as TK_WIDGET ptr, byval pfn as TKCODEEDIT_DoubleClickSub )
function tkCodeEdit_ListPopup() as TK_HOST ptr
function tkCodeEdit_CallTipPopup() as TK_HOST ptr
function tkCodeEdit_ContextMenu() as TK_MENU ptr
function tkCodeEdit_MeasureWidths( byref sFile as string, byval px as long, byref u8 as string, pos64() as long ) as boolean
function tkCodeEdit_MeasureText( byref sFile as string, byval px as long, byref u8 as string ) as long
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
