[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/richedit](SysWin-RichEdit) › **CTextSelection2**

# CTextSelection2
Reads and changes the selection of a rich edit control through the Text Object Model.

<!-- scope: CTextSelection2 -->

Reads and changes the selection of a rich edit control through the Text Object Model.

A `CTextSelection2` wraps the `ITextSelection2` interface of a rich edit control: the text the user has selected, or the caret when nothing is. It is a text range like [CTextRange2](CTextRange2), with the same members, plus the ones that act like the keyboard (`MoveLeft`, `HomeKey`, `TypeText` …) and the selection flags. Whatever it does shows on the screen at once: moving it moves the caret. Get it from `CRichEditCtx.Selection2()` (see [CRichEditCtx: document](CRichEditCtx-Document)); a control has one selection, so every object you make for it works on the same one.

**Positions.** Character positions count from 0; the selection covers its start up to, not including, its end, and a caret is a selection whose start equals its end. One end is *active*: the one the caret is at and that Shift+arrow moves.

**Ownership.** The constructor and `Let` take over the pointer they are given and the destructor releases it, so `dim sel as CTextSelection2 = pRichEdit->Selection2()` is the whole job. [Attach](#attach) can add a reference instead; [Detach](#detach) gives the pointer back to you. Members that return another interface (`GetDuplicate`, `GetFont`, `GetPara` …) hand you a reference you own.

**Results.** Most members return the value an interface method reports rather than its result code. The class extends `CTextObjectBase`: after any call `GetLastResult()` returns the `HRESULT` of the method (`S_OK`, `S_FALSE`, `E_NOTIMPL` …) and `GetErrorInfo()` turns it into text.

**TOM constants** such as `tomWord`, `tomStart`, `tomTrue` and `tomUseCRLF` come with `sys/win/richedit`; `tomTrue` is -1 and `tomFalse` 0.

The snippets on this page assume `hCtrl` is a rich edit control made by `CRichEditCtx` holding "Hello world. Second sentence here.", and `sel` its selection, set as the snippet's first line shows.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/richedit"
using win, gui, richedit
```

## Example

A rich edit box with two buttons: Upper capitalises the selection, or the word the caret is in, and Stamp types a note at the caret as if the user had typed it.

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/richedit"
using win, gui, richedit

const IDC_RICHEDIT = 101
const IDC_UPPER    = 102
const IDC_STAMP    = 103

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "SelectionDemo"
    dim hWin as HWND = pWindow.Create( NULL, "CTextSelection2", @WndProc )
    pWindow.SetClientSize( 500, 300 )
    pWindow.Center()
    dim pRichEdit as CRichEditCtx = CRichEditCtx( @pWindow, IDC_RICHEDIT, "", 10, 10, 480, 240, -1, WS_EX_CLIENTEDGE )
    pRichEdit.SetText( "Put the caret in a word and press Upper, or press Stamp to type a note." )
    pWindow.AddControl( "Button", hWin, IDC_UPPER, "&Upper", 280, 262, 100, 28 )
    pWindow.AddControl( "Button", hWin, IDC_STAMP, "&Stamp", 390, 262, 100, 28 )
    SetFocus( pRichEdit.hRichEdit )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTLMSG( wParam, lParam ) <> BN_CLICKED then return 0
            dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hwnd, IDC_RICHEDIT )
            if pRichEdit = NULL then return 0
            dim sel as CTextSelection2 = pRichEdit->Selection2()   ' released at the end of the block
            select case CBCTL( wParam, lParam )
                case IDC_UPPER
                    if sel.GetType() = tomSelectionIP then sel.Expand( tomWord )   ' a caret takes its word
                    sel.ChangeCase( tomUpperCase )
                case IDC_STAMP
                    sel.TypeText( "[note] " )                     ' replaces any selected text, like typing
            end select
            SetWindowText( hwnd, "selection " & sel.GetStart() & " to " & sel.GetEnd() )
            SetFocus( pRichEdit->hRichEdit )
            return 0
        case WM_DESTROY
            PostQuitMessage( 0 )
            return 0
    end select
    return DefWindowProcW( hwnd, uMsg, wParam, lParam )
end function

end main()
```

## Members

**Creating the object**

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Wraps an interface pointer, taking it over or adding a reference. |
| [Destructor](#destructor) | Releases the interface pointer. |
| [Let, Cast](#let-cast) | Assigns a new interface pointer; reads the one held. |
| [TextSelectionPtr](#textselectionptr) | Returns the interface pointer, without adding a reference. |
| [Attach](#attach) | Replaces the interface pointer, optionally adding a reference. |
| [Detach](#detach) | Gives up the interface pointer without releasing it. |

**Text**

| Member | Does |
| --- | --- |
| [GetText, SetText](#gettext-settext) | Reads or replaces the plain text. |
| [GetChar, SetChar](#getchar-setchar) | Reads or replaces the character at the start. |
| [GetChar2](#getchar2) | Reads a character relative to the end. |
| [GetFormattedText, SetFormattedText](#getformattedtext-setformattedtext) | Reads or replaces the text with its formatting. |
| [TypeText](#typetext) | Types text at the selection as the user would. |
| [GetURL, SetURL](#geturl-seturl) | Reads or sets the hyperlink of the text. |
| [ChangeCase](#changecase) | Changes the case of the letters. |
| [HexToUnicode](#hextounicode) | Turns the hexadecimal digits before the end into a character. |
| [UnicodeToHex](#unicodetohex) | Turns the character before the start into hexadecimal digits. |

**Position and extent**

| Member | Does |
| --- | --- |
| [GetStart, SetStart](#getstart-setstart) | Reads or moves the start position. |
| [GetEnd, SetEnd](#getend-setend) | Reads or moves the end position. |
| [GetLength, SetLength](#getlength-setlength) | Reads or sets the number of characters covered. |
| [GetCch](#getcch) | Returns the signed character count. |
| [SetRange](#setrange) | Sets both ends, anchor first. |
| [Collapse](#collapse) | Shrinks to an insertion point at one end. |
| [Expand](#expand) | Grows to cover whole units. |
| [GetIndex, SetIndex](#getindex-setindex) | Reads or moves to the number of a unit. |
| [GetStoryLength](#getstorylength) | Returns the length of the whole story. |
| [GetStoryType](#getstorytype) | Returns the kind of story. |
| [GetStartPara](#getstartpara) | Returns where the paragraph begins. |
| [GetDuplicate](#getduplicate) | Returns a new range over the same text. |
| [InRange, InStory, IsEqual](#inrange-instory-isequal) | Compares with another range. |
| [Select_](#select_) | Makes the control select this text. |

**Moving**

| Member | Does |
| --- | --- |
| [StartOf, EndOf](#startof-endof) | Moves to the start or end of the current unit. |
| [Move](#move) | Moves an insertion point by a number of units. |
| [MoveStart, MoveEnd](#movestart-moveend) | Moves one end by a number of units. |
| [MoveWhile, MoveStartWhile, MoveEndWhile](#movewhile-movestartwhile-moveendwhile) | Moves past characters that belong to a set. |
| [MoveUntil, MoveStartUntil, MoveEndUntil](#moveuntil-movestartuntil-moveenduntil) | Moves to the first character that belongs to a set. |

**Keyboard-style moves**

| Member | Does |
| --- | --- |
| [MoveLeft, MoveRight](#moveleft-moveright) | Moves like the Left and Right arrow keys. |
| [MoveUp, MoveDown](#moveup-movedown) | Moves like the Up and Down arrow and Page keys. |
| [HomeKey, EndKey](#homekey-endkey) | Moves like the Home and End keys. |
| [GetFlags, SetFlags](#getflags-setflags) | Reads or sets the selection flags. |
| [GetType](#gettype) | Returns the kind of selection. |

**Finding**

| Member | Does |
| --- | --- |
| [FindText, FindTextStart, FindTextEnd](#findtext-findtextstart-findtextend) | Searches for a string. |
| [Find](#find) | Searches for formatted text, math functions included. |

**Deleting and the clipboard**

| Member | Does |
| --- | --- |
| [Delete_](#delete_) | Deletes text like the Delete and Backspace keys. |
| [Cut, Copy](#cut-copy) | Copies the text to the clipboard or a data object; Cut deletes it too. |
| [Paste](#paste) | Pastes from the clipboard or a data object. |
| [CanPaste](#canpaste) | Tells whether a paste would work. |
| [CanEdit](#canedit) | Tells whether the text can be changed. |

**Formatting**

| Member | Does |
| --- | --- |
| [GetFont, SetFont](#getfont-setfont) | Reads the character formatting; SetFont is refused. |
| [GetPara, SetPara](#getpara-setpara) | Reads the paragraph formatting; SetPara is refused. |
| [GetGravity, SetGravity](#getgravity-setgravity) | Reads or sets which side's formatting the ends take. |
| [GetProperty, SetProperty](#getproperty-setproperty) | Reads or sets a range property by number. |
| [GetDropCap, SetDropCap](#getdropcap-setdropcap) | Reads or sets a drop capital; not implemented by the control. |

**The screen**

| Member | Does |
| --- | --- |
| [GetPoint](#getpoint) | Returns where an end of the text is drawn. |
| [SetPoint](#setpoint) | Moves to the text at a point. |
| [GetRect](#getrect) | Returns a rectangle around the text. |
| [ScrollIntoView](#scrollintoview) | Scrolls the control to show the text. |
| [GetEmbeddedObject](#getembeddedobject) | Returns the object embedded at the start. |

**Subranges**

| Member | Does |
| --- | --- |
| [GetCount](#getcount) | Returns the number of subranges. |
| [AddSubrange](#addsubrange) | Adds a subrange. |
| [GetSubrange](#getsubrange) | Reads the ends of a subrange. |
| [DeleteSubrange, SetActiveSubrange](#deletesubrange-setactivesubrange) | Remove a subrange or make one active. |

**Tables, math and objects**

| Member | Does |
| --- | --- |
| [InsertTable](#inserttable) | Inserts a table. |
| [GetRow](#getrow) | Returns the table row at the text. |
| [GetCells, GetColumn, GetTable](#getcells-getcolumn-gettable) | Table objects; not implemented by the control. |
| [BuildUpMath, Linearize](#buildupmath-linearize) | Converts math between linear and built-up form. |
| [GetInlineObject, SetInlineObject](#getinlineobject-setinlineobject) | Reads or inserts an inline object such as a fraction. |
| [GetMathFunctionType](#getmathfunctiontype) | Classifies a math function name. |
| [InsertImage](#insertimage) | Inserts an image from a stream. |

## Reference

### Constructor

```freebasic
constructor( byval pTextSelection2 as ITextSelection2 ptr, byval fAddRef as boolean = false )
```

Wraps a TOM interface pointer. With `fAddRef` `false` (the default) the object takes the pointer over: it releases it in its destructor, so do not release it yourself. Pass the result of a call that hands you a new reference, such as `CRichEditCtx.Selection2`, straight to the constructor. With `fAddRef` `true` the object adds a reference of its own and you keep yours.

A `NULL` pointer is refused: `GetLastResult()` returns `E_INVALIDARG` and the object holds no interface. The other members use the pointer without checking it, so do not call them on such an object.

To point an existing object at another selection pointer, use [Let](#let-cast) or [Attach](#attach).

| Parameter | Meaning |
| --- | --- |
| `pTextSelection2` | The interface pointer. |
| `fAddRef` | `true` to add a reference; `false` (the default) to take over the caller's. |

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
print sel.GetStart(); sel.GetEnd()
```

### Destructor

```freebasic
destructor
```

Releases the interface pointer the object holds, if any. It runs when the variable goes out of scope, or on `delete` for an object made with `new`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
dim pSel as CTextSelection2 ptr = new CTextSelection2( CRichEditCtxPtr( hCtrl )->Selection2() )
print pSel->GetStart()
delete pSel   ' releases the selection
```

### Let, Cast

```freebasic
operator let( byval pTextSelection2 as ITextSelection2 ptr )
operator cast() as ITextSelection2 ptr
```

`Let` replaces the pointer the object holds: it releases the old one and **takes over** the new one without adding a reference, as the constructor does by default. A `NULL` pointer is ignored, and `GetLastResult()` returns `E_INVALIDARG`.

`Cast` returns the pointer the object holds, without adding a reference, so the object can be passed where an `ITextSelection2 ptr` is expected. Do not release what it returns.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel = CRichEditCtxPtr( hCtrl )->Selection2()   ' the old pointer is released
dim p as ITextSelection2 ptr = sel
```

### TextSelectionPtr

```freebasic
function TextSelectionPtr() as ITextSelection2 ptr
```

Returns the `ITextSelection2` pointer the object holds, or `NULL`, without adding a reference. Use it to call an interface method the class does not wrap; do not release it. The same pointer is in the public field `m_pTextSelection2`.

Members that take a range, such as [InRange](#inrange-instory-isequal), want an `ITextRange2 ptr`: pass `cast( ITextRange2 ptr, sel.TextSelectionPtr() )`.

**Returns** the pointer, or `NULL`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim p as ITextSelection2 ptr = sel.TextSelectionPtr()
if p then print "the selection starts at"; sel.GetStart()
```

### Attach

```freebasic
function Attach( byval pTextSelection2 as ITextSelection2 ptr, byval fAddRef as boolean = false ) as HRESULT
```

Releases the pointer the object holds, if any, and stores `pTextSelection2` in its place: taken over when `fAddRef` is `false` (the default), with a reference of its own when it is `true`. `NULL` is refused with `E_INVALIDARG` and the object keeps what it had.

The return value is not an `HRESULT` when a pointer was replaced: it is what releasing the old pointer returned, its remaining reference count (2, for example, while the control still holds the selection). When the object held nothing it is the previous `GetLastResult()` value. Test the pointer, not the result.

| Parameter | Meaning |
| --- | --- |
| `pTextSelection2` | The new interface pointer. |
| `fAddRef` | `true` to add a reference; `false` (the default) to take over the caller's. |

**Returns** `E_INVALIDARG` for `NULL`; otherwise the old pointer's remaining reference count, or the previous result when there was none.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim p as ITextSelection2 ptr = sel.Detach()
sel.Attach( p )   ' takes the reference back
```

### Detach

```freebasic
function Detach() as ITextSelection2 ptr
```

Returns the pointer the object holds and forgets it, without releasing it: the caller now owns that reference and must release it. The destructor then has nothing to release.

**Returns** the pointer, or `NULL`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim p as ITextSelection2 ptr = sel.Detach()
if p then p->lpvtbl->Release( p )
```

### GetText, SetText

```freebasic
function GetText( byval Flags as long = tomUseCRLF ) as ustring
function SetText( byref wszText as wstring, byval Flags as long = 0 ) as HRESULT
```

`GetText` returns the text of the selection as a `ustring`. `Flags` controls the conversion; the default, `tomUseCRLF`, turns each paragraph mark into a CR/LF pair. Hidden text is included unless you add `tomNoHidden`: a hyperlink, for example, reads back with its hidden field code in front of the visible text.

`SetText` replaces the text of the selection with `wszText`; afterwards the selection covers the new text. An empty string deletes the text. `Flags` is 0 by default; it can combine `tomUnicodeBiDi`, `tomMathCFCheck`, `tomUnlink` (do not make the text part of a link), `tomUnhide` and `tomCheckTextLimit` (obey the control's text limit).

| Parameter | Meaning |
| --- | --- |
| `Flags` | `GetText`: `tomUseCRLF` (default), `tomAdjustCRLF`, `tomTextize`, `tomAllowFinalEOP`, `tomNoHidden`, `tomIncludeNumbering`, `tomTranslateTableCell`, `tomNoMathZoneBrackets`, `tomFoldMathAlpha`, `tomLanguageTag`, combined with `or`. `SetText`: see above. |
| `wszText` | The new text; `""` deletes. |

**Returns** `GetText`: the text, or `""`. `SetText`: `S_OK`, or an error such as `E_ACCESSDENIED` for protected text.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print sel.GetText()                        ' the first five characters
sel.SetText( "Howdy" )
print sel.GetStart(); sel.GetEnd()            ' 0 5: the new text
```

Microsoft Learn: [ITextRange2::GetText2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-gettext2), [ITextRange2::SetText2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-settext2)

### GetChar, SetChar

```freebasic
function GetChar() as long
function SetChar( byval char as long ) as HRESULT
```

`GetChar` returns the character code at the start of the selection: 72 for a selection that starts with "H". `SetChar` replaces that character with `char`; the selection itself does not move.

| Parameter | Meaning |
| --- | --- |
| `char` | The new character code. |

**Returns** `GetChar`: the character code, or 0. `SetChar`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print sel.GetChar()          ' 72 for "Hello"
sel.SetChar( asc( "J" ) )     ' "Hello" becomes "Jello"
```

Microsoft Learn: [ITextRange::GetChar](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-getchar), [ITextRange::SetChar](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-setchar)

### GetChar2

```freebasic
function GetChar2( byval Offset as long ) as long
```

Returns the character at `Offset` from the **end** of the selection: 0 is the first character after the selection, -1 the last character inside it, 1 the second after it. For "Hello" in "Hello world", `GetChar2( 0 )` is 32 (the space) and `GetChar2( -1 )` is 111 ("o").

| Parameter | Meaning |
| --- | --- |
| `Offset` | The offset from the end position. |

**Returns** the character code, or 0.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print sel.GetChar2( -1 )     ' the last character of the range
```

Microsoft Learn: [ITextRange2::GetChar2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getchar2)

### GetFormattedText, SetFormattedText

```freebasic
function GetFormattedText() as ITextRange2 ptr
function SetFormattedText( byval pRange as ITextRange2 ptr ) as HRESULT
```

`GetFormattedText` returns a new `ITextRange2` holding the formatted text of the selection; the caller owns it (wrap it in a `CTextRange2`). `SetFormattedText` replaces the text of the selection with the formatted text of `pRange`, so text can be copied with its fonts and paragraph formats without going through the clipboard; afterwards the selection covers the inserted text.

| Parameter | Meaning |
| --- | --- |
| `pRange` | The range whose formatted text is copied. |

**Returns** `GetFormattedText`: the new range, or `NULL`. `SetFormattedText`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim src as CTextRange2 = sel.GetFormattedText()
sel.Collapse( tomEnd )
sel.SetFormattedText( src.m_pTextRange2 )   ' a formatted copy after the original
```

Microsoft Learn: [ITextRange2::GetFormattedText2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getformattedtext2), [ITextRange2::SetFormattedText2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-setformattedtext2)

### TypeText

```freebasic
function TypeText( byref wszText as wstring ) as HRESULT
```

Inserts `wszText` as if the user had typed it: it replaces the selection, honours the Insert / Overtype state and applies the control's typing options such as AutoCorrect. Afterwards the selection is an insertion point after the new text. Use [SetText](#gettext-settext) to replace text without those rules.

| Parameter | Meaning |
| --- | --- |
| `wszText` | The text to type. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
sel.TypeText( ">> " )
print sel.GetStart()     ' 3: just after the typed text
```

Microsoft Learn: [ITextSelection::TypeText](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-typetext)

### GetURL, SetURL

```freebasic
function GetURL() as ustring
function SetURL( byref wszUrl as wstring ) as HRESULT
```

`SetURL` turns the text of the selection into a hyperlink to `wszUrl`, with the text as its friendly name. The URL is not checked; it must be **in double quotes**, as in `"""https://example.com"""` in tiko source. The selection must not be empty, and it may cover different positions afterwards.

`GetURL` returns the URL of the link at the selection, quotes included, or `""` (with `GetLastResult()` `S_FALSE`) when there is none.

| Parameter | Meaning |
| --- | --- |
| `wszUrl` | The URL, enclosed in double quotes. |

**Returns** `GetURL`: the URL or `""`. `SetURL`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 6, 11 )
sel.SetURL( """https://example.com""" )
print sel.GetURL()      ' "https://example.com"
```

Microsoft Learn: [ITextRange2::GetURL](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-geturl), [ITextRange2::SetURL](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-seturl)

### ChangeCase

```freebasic
function ChangeCase( byval nType as long = tomLowerCase ) as HRESULT
```

Changes the case of the letters in the selection: `tomLowerCase` (0, the default), `tomUpperCase`, `tomTitleCase` (first letter of each word), `tomSentenceCase` or `tomToggleCase`.

| Parameter | Meaning |
| --- | --- |
| `nType` | One of the `tom*Case` values. |

**Returns** `S_OK`; `S_FALSE` (1) when nothing changed (title case on "Hello", in testing).

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.ChangeCase( tomUpperCase )
print sel.GetText()      ' HELLO
```

Microsoft Learn: [ITextRange::ChangeCase](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-changecase)

### HexToUnicode

```freebasic
function HexToUnicode() as HRESULT
```

Replaces the hexadecimal number just before the end of the selection with the character it codes, as the Alt+X key does in some editors: `263A` becomes the smiling face U+263A.

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
sel.SetText( "263A" )
sel.Collapse( tomEnd )
sel.HexToUnicode()       ' the four digits become one character
```

Microsoft Learn: [ITextRange2::HexToUnicode](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-hextounicode)

### UnicodeToHex

```freebasic
function UnicodeToHex() as HRESULT
```

Replaces the character just before the start of the selection with its code in hexadecimal and makes the selection cover the digits: the reverse of [HexToUnicode](#hextounicode).

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 1, 1 )
sel.UnicodeToHex()       ' "H" before position 1 becomes "48"
print sel.GetText()
```

Microsoft Learn: [ITextRange2::UnicodeToHex](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-unicodetohex)

### GetStart, SetStart

```freebasic
function GetStart() as long
function SetStart( byval cpFirst as long ) as HRESULT
```

`GetStart` returns the character position where the selection starts. `SetStart` moves the start to `cpFirst`; if that is past the end, the end moves there too and the selection becomes an insertion point.

| Parameter | Meaning |
| --- | --- |
| `cpFirst` | The new start position. |

**Returns** `GetStart`: the position. `SetStart`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.SetStart( 1 )
print sel.GetStart()     ' 1
```

Microsoft Learn: [ITextRange::GetStart](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-getstart), [ITextRange::SetStart](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-setstart)

### GetEnd, SetEnd

```freebasic
function GetEnd() as long
function SetEnd( byval cpLim as long ) as HRESULT
```

`GetEnd` returns the position just after the last character of the selection. `SetEnd` moves the end to `cpLim`; if that is before the start, the start moves there too.

| Parameter | Meaning |
| --- | --- |
| `cpLim` | The new end position. |

**Returns** `GetEnd`: the position. `SetEnd`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.SetEnd( 3 )
print sel.GetText()      ' "Hel"
```

Microsoft Learn: [ITextRange::GetEnd](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-getend), [ITextRange::SetEnd](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-setend)

### GetLength, SetLength

```freebasic
function GetLength() as long
function SetLength( byval Value as long ) as HRESULT
```

Helpers over the start and end positions. `GetLength` returns end minus start, always 0 or more, and 0 when a position cannot be read. `SetLength` moves the end to start + `Value`.

| Parameter | Meaning |
| --- | --- |
| `Value` | The new length. |

**Returns** `GetLength`: the length. `SetLength`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.SetLength( 11 )
print sel.GetLength()    ' 11
```

Microsoft Learn: [ITextRange::SetEnd](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-setend)

### GetCch

```freebasic
function GetCch() as long
```

Returns the number of characters in the selection, **signed**: negative when the active end is the start. `CRichEditCtx.Range( 0, 5 )` makes position 0 active, so its count is -5; `SetRange( 0, 5 )` makes 5 active and the count 5. Use [GetLength](#getlength-setlength) for the plain size.

**Returns** the signed count.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print sel.GetCch()     ' 5 after SetRange( 0, 5 )
```

Microsoft Learn: [ITextRange2::GetCch](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getcch)

### SetRange

```freebasic
function SetRange( byval cpAnchor as long, byval cpActive as long ) as HRESULT
```

Moves the selection to cover `cpAnchor` to `cpActive`, in either order. The **active** end is the one that moves when the selection is extended. Note the order: anchor first here, active first in `CRichEditCtx.Range`.

| Parameter | Meaning |
| --- | --- |
| `cpAnchor` | The fixed end. |
| `cpActive` | The active end. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 11 )  ' selects the first eleven characters, caret at 11
```

Microsoft Learn: [ITextRange::SetRange](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-setrange)

### Collapse

```freebasic
function Collapse( byval bStart as long = tomStart ) as HRESULT
```

Makes the selection an insertion point (a degenerate selection, with start equal to end) at its start, the default, or at its end with `tomEnd` (0).

| Parameter | Meaning |
| --- | --- |
| `bStart` | `tomStart` (the default) or `tomEnd`. |

**Returns** `S_OK`, or `S_FALSE` when the selection was already an insertion point there.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.Collapse( tomEnd )
print sel.GetStart(); sel.GetEnd()     ' 5 5
```

Microsoft Learn: [ITextRange::Collapse](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-collapse)

### Expand

```freebasic
function Expand( byval Unit as long = tomWord ) as long
```

Extends both ends so that every unit the selection touches is covered completely. An insertion point inside a word grows to the whole word, with its trailing space: at position 2 of "Hello world" it becomes "Hello " and returns 6.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomWord` (the default), `tomCharacter`, `tomSentence`, `tomParagraph`, `tomLine`, `tomStory` … |

**Returns** the number of characters added.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 2, 2 )
sel.Expand( tomSentence )
print sel.GetText()      ' the whole first sentence
```

Microsoft Learn: [ITextRange::Expand](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-expand)

### GetIndex, SetIndex

```freebasic
function GetIndex( byval Unit as long = tomWord ) as long
function SetIndex( byval Unit as long, byval Index as long, byval Extend as long = 0 ) as HRESULT
```

`GetIndex` returns the number, counted from 1, of the `Unit` that holds the start of the selection. `SetIndex` moves the selection to the `Index`-th unit of the story: with `Extend` 0 (the default) to an insertion point at the start of that unit, otherwise covering the whole unit.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomWord` (default for `GetIndex`), `tomSentence`, `tomParagraph`, `tomLine` … |
| `Index` | The unit number, from 1. |
| `Extend` | 0 for an insertion point; nonzero to cover the unit. |

**Returns** `GetIndex`: the number. `SetIndex`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print sel.GetIndex( tomSentence )      ' 1
sel.SetIndex( tomWord, 2, 1 )          ' covers the second word
```

Microsoft Learn: [ITextRange::GetIndex](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-getindex), [ITextRange::SetIndex](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-setindex)

### GetStoryLength

```freebasic
function GetStoryLength() as long
```

Returns the number of characters in the story the selection belongs to, including the final paragraph mark: 35 for a control holding 34 characters.

**Returns** the count.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print sel.GetStoryLength()
```

Microsoft Learn: [ITextRange::GetStoryLength](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-getstorylength)

### GetStoryType

```freebasic
function GetStoryType() as long
```

Returns the type of the story the selection belongs to; the text of a rich edit control is `tomMainTextStory` (1).

**Returns** a `tom*Story` value.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
if sel.GetStoryType() = tomMainTextStory then print "main text"
```

Microsoft Learn: [ITextRange::GetStoryType](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-getstorytype)

### GetStartPara

```freebasic
function GetStartPara() as long
```

Returns the character position at which the paragraph holding the start of the selection begins.

**Returns** the position.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print "paragraph starts at"; sel.GetStartPara()
```

Microsoft Learn: [ITextRange2::GetStartPara](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getstartpara)

### GetDuplicate

```freebasic
function GetDuplicate() as ITextRange2 ptr
```

Returns a new `ITextRange2` covering the same text as the selection, which can then be moved on its own. The caller owns it: wrap it in a [CTextRange2](CTextRange2).

**Returns** the new range, or `NULL`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim copy as CTextRange2 = sel.GetDuplicate()
copy.Collapse( tomEnd )   ' r does not move
```

Microsoft Learn: [ITextRange2::GetDuplicate2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getduplicate2)

### InRange, InStory, IsEqual

```freebasic
function InRange( byval pRange as ITextRange2 ptr ) as long
function InStory( byval pRange as ITextRange2 ptr ) as long
function IsEqual( byval pRange as ITextRange2 ptr ) as long
```

Each compares the selection with `pRange` and returns `tomTrue` (-1) or `tomFalse` (0). `InRange`: the selection lies within `pRange` (or covers the same text). `InStory`: both are in the same story. `IsEqual`: both cover the same positions in the same story. A duplicate of a range is equal to it and in range of it.

| Parameter | Meaning |
| --- | --- |
| `pRange` | The range to compare with. |

**Returns** `tomTrue` or `tomFalse`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim other as CTextRange2 = sel.GetDuplicate()
print sel.IsEqual( other.m_pTextRange2 )     ' -1
```

Microsoft Learn: [ITextRange::InRange](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-inrange), [ITextRange::InStory](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-instory), [ITextRange::IsEqual](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-isequal)

### Select_

```freebasic
function Select_() as HRESULT
```

Sets the control's selection to the text of the selection, active end included. The trailing underscore keeps the name clear of the `select` keyword.

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.Select_()     ' already the selection: nothing changes
```

Microsoft Learn: [ITextRange::Select](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-select)

### StartOf, EndOf

```freebasic
function StartOf( byval Unit as long, byval Extend as long = 0 ) as long
function EndOf( byval Unit as long, byval Extend as long = 0 ) as long
```

`StartOf` moves the selection to the start of the first `Unit` it overlaps, `EndOf` to the end of the last. With `Extend` 0 (the default) both ends move and the selection becomes an insertion point; with `tomExtend` (1) only the nearer end moves, so the selection grows to that boundary.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomWord`, `tomSentence`, `tomParagraph`, `tomLine`, `tomStory` … |
| `Extend` | 0 (`tomMove`) or `tomExtend`. |

**Returns** the number of characters the end moved: 0 or negative for `StartOf`, 0 or positive for `EndOf`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
sel.EndOf( tomSentence, tomExtend )
print sel.GetText()      ' from 0 to the end of the first sentence
```

Microsoft Learn: [ITextRange::StartOf](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-startof), [ITextRange::EndOf](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-endof)

### Move

```freebasic
function Move( byval Unit as long = tomCharacter, byval Count as long = 1 ) as long
```

Moves the selection as an insertion point `Count` units forward, or back for a negative count. A non-empty selection first collapses to its end (forward) or start (back), and that counts as one unit: `Move()` on characters 0 to 5 leaves an insertion point at 5 and returns 1.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomCharacter` (the default), `tomWord`, `tomSentence`, `tomParagraph`, `tomLine`, `tomStory` … |
| `Count` | Units to move; negative moves back. Default 1. |

**Returns** the number of units moved, negative when back.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
sel.Move( tomWord, 2 )
print sel.GetStart()     ' the start of the third word
```

Microsoft Learn: [ITextRange::Move](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-move)

### MoveStart, MoveEnd

```freebasic
function MoveStart( byval Unit as long = tomCharacter, byval Count as long = 1 ) as long
function MoveEnd( byval Unit as long = tomCharacter, byval Count as long = 1 ) as long
```

`MoveStart` moves only the start, `MoveEnd` only the end, `Count` units forward or (negative) back. If the start passes the end, or the end the start, the other end goes with it.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomCharacter` (the default), `tomWord` … |
| `Count` | Units to move; default 1. |

**Returns** the number of units moved.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.MoveStart( tomCharacter, 2 )
sel.MoveEnd( tomCharacter, -1 )
print sel.GetText()      ' "ll"
```

Microsoft Learn: [ITextRange::MoveStart](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-movestart), [ITextRange::MoveEnd](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-moveend)

### MoveWhile, MoveStartWhile, MoveEndWhile

```freebasic
function MoveWhile( byval Cset as VARIANT ptr, byval Count as long = tomForward ) as long
function MoveStartWhile( byval Cset as VARIANT ptr, byval Count as long = tomForward ) as long
function MoveEndWhile( byval Cset as VARIANT ptr, byval Count as long = tomForward ) as long
```

`MoveWhile` moves the selection as an insertion point past every following character that is in the set; `MoveStartWhile` and `MoveEndWhile` move only the start or the end, so `MoveEndWhile` extends the selection over a run of matching characters.

`Cset` points to a `VARIANT` naming the characters: either a `VT_BSTR` string of them, listed in **ascending order** (with "Howdy " out of order, the match stopped at the "d" in testing), or a `VT_I4` character-type mask such as `C1_ALPHA`, `C1_DIGIT` or `C1_SPACE`. `Count` limits how many characters are looked at; the default, `tomForward`, means up to the end of the story, and `tomBackward` or a negative number goes back.

| Parameter | Meaning |
| --- | --- |
| `Cset` | The character set, as above. |
| `Count` | The most characters to pass; `tomForward` (the default) or `tomBackward`. |

**Returns** the number of characters passed.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim v as VARIANT
v.vt = VT_I4 : v.lVal = C1_ALPHA
sel.MoveEndWhile( @v )
print sel.GetText()      ' "Hello": the letters from position 0
```

Microsoft Learn: [ITextRange::MoveWhile](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-movewhile), [ITextRange::MoveStartWhile](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-movestartwhile), [ITextRange::MoveEndWhile](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-moveendwhile)

### MoveUntil, MoveStartUntil, MoveEndUntil

```freebasic
function MoveUntil( byval Cset as VARIANT ptr, byval Count as long = tomForward ) as long
function MoveStartUntil( byval Cset as VARIANT ptr, byval Count as long = tomForward ) as long
function MoveEndUntil( byval Cset as VARIANT ptr, byval Count as long = tomForward ) as long
```

`MoveUntil` moves the selection as an insertion point to just before the first character that is in the set; `MoveStartUntil` and `MoveEndUntil` move only the start or the end there.

`Cset` points to a `VARIANT` naming the characters: either a `VT_BSTR` string of them, listed in **ascending order** (with "Howdy " out of order, the match stopped at the "d" in testing), or a `VT_I4` character-type mask such as `C1_ALPHA`, `C1_DIGIT` or `C1_SPACE`. `Count` limits how many characters are looked at; the default, `tomForward`, means up to the end of the story, and `tomBackward` or a negative number goes back.

| Parameter | Meaning |
| --- | --- |
| `Cset` | The character set, as above. |
| `Count` | The most characters to look at; `tomForward` (the default) or `tomBackward`. |

**Returns** the number of characters passed **plus 1** when a match was found (6 for the example), 0 when none was.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim v as VARIANT
v.vt = VT_I4 : v.lVal = C1_SPACE
sel.MoveEndUntil( @v )
print sel.GetText()      ' "Hello": up to the first space
```

Microsoft Learn: [ITextRange::MoveUntil](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-moveuntil), [ITextRange::MoveStartUntil](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-movestartuntil), [ITextRange::MoveEndUntil](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-moveenduntil)

### MoveLeft, MoveRight

```freebasic
function MoveLeft( byval Unit as long = tomCharacter, byval Count as long = 1, byval Extend as long = 0 ) as long
function MoveRight( byval Unit as long = tomCharacter, byval Count as long = 1, byval Extend as long = 0 ) as long
```

Moves the selection `Count` units left or right, like the arrow keys: with `Extend` 0 (the default) the selection becomes an insertion point, with `tomExtend` (1) the active end moves and the selection grows or shrinks, like Shift+arrow. A non-empty selection moved without `Extend` first collapses to its left or right end, and that counts as one unit.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomCharacter` (the default) or `tomWord`. |
| `Count` | Units to move; default 1. |
| `Extend` | 0 to move, `tomExtend` to extend. |

**Returns** the number of units moved.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
sel.MoveRight( tomWord, 1, tomExtend )   ' like Ctrl+Shift+Right
print sel.GetText()                      ' "Hello "
```

Microsoft Learn: [ITextSelection::MoveLeft](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-moveleft), [ITextSelection::MoveRight](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-moveright)

### MoveUp, MoveDown

```freebasic
function MoveUp( byval Unit as long = tomLine, byval Count as long = 1, byval Extend as long = 0 ) as long
function MoveDown( byval Unit as long = tomLine, byval Count as long = 1, byval Extend as long = 0 ) as long
```

Moves the selection `Count` lines up or down, like the arrow keys, or `Count` screens with `tomScreen` (Page Up and Page Down). `Extend` works as for [MoveLeft](#moveleft-moveright). In text of a single line nothing moves: the call returns 0 and `GetLastResult()` is `S_FALSE`.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomLine` (the default), `tomParagraph`, `tomScreen` or `tomWindow`. |
| `Count` | Units to move; default 1. |
| `Extend` | 0 to move, `tomExtend` to extend. |

**Returns** the number of units moved.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
sel.MoveDown( tomLine, 1, tomExtend )   ' like Shift+Down
```

Microsoft Learn: [ITextSelection::MoveUp](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-moveup), [ITextSelection::MoveDown](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-movedown)

### HomeKey, EndKey

```freebasic
function HomeKey( byval Unit as long = tomLine, byval Extend as long = 0 ) as long
function EndKey( byval Unit as long = tomLine, byval Extend as long = 0 ) as long
```

Moves the selection to the start or end of the current line, like Home and End, or of the whole text with `tomStory`, like Ctrl+Home and Ctrl+End. With `tomExtend` the selection grows to there instead: `EndKey( tomStory, tomExtend )` from position 0 selects everything, final paragraph mark included.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomLine` (the default), `tomStory`, `tomColumn` or `tomRow`. |
| `Extend` | 0 to move, `tomExtend` to extend. |

**Returns** the number of characters moved: 0 or negative for `HomeKey`, 0 or positive for `EndKey`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
sel.HomeKey( tomStory )                 ' like Ctrl+Home
sel.EndKey( tomStory, tomExtend )        ' like Ctrl+Shift+End
```

Microsoft Learn: [ITextSelection::HomeKey](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-homekey), [ITextSelection::EndKey](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-endkey)

### GetFlags, SetFlags

```freebasic
function GetFlags() as long
function SetFlags( byval Flags as long ) as HRESULT
```

The flags describe the selection: `tomSelStartActive` (1, the start is the active end), `tomSelAtEOL` (2), `tomSelOvertype` (4, typing overwrites), `tomSelActive` (8) and `tomSelReplace` (16, typing replaces the selection). A fresh caret reads 17. `SetFlags` replaces them all, so read, change and write back.

| Parameter | Meaning |
| --- | --- |
| `Flags` | A combination of the `tomSel*` values. |

**Returns** `GetFlags`: the flags. `SetFlags`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim f as long = sel.GetFlags()
sel.SetFlags( f or tomSelOvertype )   ' overtype mode on
```

Microsoft Learn: [ITextSelection::GetFlags](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-getflags), [ITextSelection::SetFlags](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-setflags)

### GetType

```freebasic
function GetType() as long
```

Returns `tomSelectionIP` (1) for a caret, `tomSelectionNormal` (2) for selected text, or another `tomSelection*` value (`tomSelectionRow`, `tomSelectionInlineShape` …); `tomNoSelection` (0) when there is none.

**Returns** a `tomSelection*` value.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
if sel.GetType() = tomSelectionIP then print "just a caret"
```

Microsoft Learn: [ITextSelection::GetType](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextselection-gettype)

### FindText, FindTextStart, FindTextEnd

```freebasic
function FindText( byref wszText as wstring, byval Count as long = tomForward, byval Flags as long = 0 ) as long
function FindTextStart( byref wszText as wstring, byval Count as long = tomForward, byval Flags as long = 0 ) as long
function FindTextEnd( byref wszText as wstring, byval Count as long = tomForward, byval Flags as long = 0 ) as long
```

Search for `wszText`. The search is not case-sensitive unless `Flags` has `tomMatchCase`; add `tomMatchWord` for whole words only. When nothing is found the selection does not change and the call returns 0.

- `FindText` searches forward from the start of the selection (back from its end with a negative `Count`) and, on a match, makes the selection cover the text found.
- `FindTextStart` searches from the start and moves **only the start** to the start of the match: from 30 back for "world", the selection becomes 6 to 30.
- `FindTextEnd` searches from the end and moves **only the end** to the end of the match: from 0 forward for "world", the selection becomes 0 to 11.

| Parameter | Meaning |
| --- | --- |
| `wszText` | The text to find. |
| `Count` | How many characters to search: `tomForward` (the default), `tomBackward`, or a number (negative goes back). |
| `Flags` | 0, or `tomMatchCase`, `tomMatchWord`, `tomMatchPattern` combined with `or`. |

**Returns** the length of the text found, or 0.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
if sel.FindText( "Second" ) then print "found at"; sel.GetStart()   ' 13
sel.Collapse( tomEnd )   ' to search on for the next one
```

Microsoft Learn: [ITextRange::FindText](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-findtext), [ITextRange::FindTextStart](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-findtextstart), [ITextRange::FindTextEnd](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-findtextend)

### Find

```freebasic
function Find( byval pRange as ITextRange2 ptr, byval Count as long, byval Flags as long ) as long
```

Searches for the formatted text of `pRange`, matching built-up math functions as well as plain characters. On a match the selection covers the text found. `Count` and `Flags` are as for [FindText](#findtext-findtextstart-findtextend). A `NULL` `pRange` gives `E_INVALIDARG`.

| Parameter | Meaning |
| --- | --- |
| `pRange` | The text to look for. |
| `Count` | Characters to search. |
| `Flags` | As for `FindText`. |

**Returns** the count the control reports (characters passed).

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim what as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 13, 19 )
sel.Find( what.m_pTextRange2, tomForward, 0 )
```

Microsoft Learn: [ITextRange2::Find](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-find)

### Delete_

```freebasic
function Delete_( byval Unit as long = tomCharacter, byval Count as long = 1 ) as long
```

A non-empty selection is deleted as a whole. From an insertion point it deletes `Count` units forward, like Delete (Ctrl+Delete with `tomWord`), or back for a negative count, like Backspace. The trailing underscore keeps the name clear of the `delete` keyword.

| Parameter | Meaning |
| --- | --- |
| `Unit` | `tomCharacter` (the default) or `tomWord`. |
| `Count` | Units to delete; negative goes back. Default 1. |

**Returns** the number of units deleted: 1 for a non-empty selection, 0 when there was nothing to delete.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.Delete_()            ' removes "Hello"
```

Microsoft Learn: [ITextRange::Delete](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-delete)

### Cut, Copy

```freebasic
function Cut( byval pVar as VARIANT ptr ) as HRESULT
function Copy( byval pVar as VARIANT ptr ) as HRESULT
```

`Copy` copies the text of the selection, with its formatting, and `Cut` copies it and then deletes it. `pVar` is `NULL` for the clipboard, or a `VARIANT` of type `VT_UNKNOWN or VT_BYREF` whose `ppunkVal` points to an `IDataObject ptr` variable, which receives a new data object that the caller must release.

| Parameter | Meaning |
| --- | --- |
| `pVar` | `NULL`, or the data-object `VARIANT` described above. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim pData as IDataObject ptr
dim v as VARIANT
v.vt = VT_UNKNOWN or VT_BYREF : v.ppunkVal = cast( IUnknown ptr ptr, @pData )
if sel.Copy( @v ) = S_OK then pData->lpvtbl->Release( pData )
```

Microsoft Learn: [ITextRange::Cut](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-cut), [ITextRange::Copy](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-copy)

### Paste

```freebasic
function Paste( byval pVar as VARIANT ptr, byval Format as long = 0 ) as HRESULT
```

Replaces the text of the selection with the contents of the clipboard (`pVar` `NULL`) or of a data object (a `VARIANT` of type `VT_UNKNOWN` holding the `IDataObject`). Afterwards the selection is an insertion point after the pasted text.

| Parameter | Meaning |
| --- | --- |
| `pVar` | `NULL`, or a `VT_UNKNOWN` `VARIANT` holding an `IDataObject`. |
| `Format` | The clipboard format to paste; 0 (the default) takes the best one. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.Collapse( tomEnd )
sel.Paste( NULL )        ' pastes the clipboard after "Hello"
```

Microsoft Learn: [ITextRange::Paste](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-paste)

### CanPaste

```freebasic
function CanPaste( byval pVar as VARIANT ptr, byval Format as long ) as long
```

Returns whether the clipboard (`pVar` `NULL`) or a data object can be pasted into the selection in `Format`. `Format` has no default: pass 0 for any format.

| Parameter | Meaning |
| --- | --- |
| `pVar` | As for [Paste](#paste). |
| `Format` | A clipboard format, or 0 for any. |

**Returns** `tomTrue` (-1) or `tomFalse` (0).

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
if sel.CanPaste( NULL, 0 ) = tomTrue then sel.Paste( NULL )
```

Microsoft Learn: [ITextRange::CanPaste](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-canpaste)

### CanEdit

```freebasic
function CanEdit() as long
```

Returns `tomTrue` (-1) when the text of the selection can be edited, `tomFalse` when the control is read-only or the text is protected.

**Returns** `tomTrue` or `tomFalse`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
if sel.CanEdit() then sel.SetText( "Hi" )
```

Microsoft Learn: [ITextRange::CanEdit](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-canedit)

### GetFont, SetFont

```freebasic
function GetFont() as ITextFont2 ptr
function SetFont( byval pFont as ITextFont2 ptr ) as HRESULT
```

`GetFont` returns an `ITextFont2` for the character formatting of the selection. The caller owns it: wrap it in a [CTextFont2](CTextFont2). The object is **live**: setting a property on it, such as `SetBold` or `SetSize`, changes the text of the selection at once.

`SetFont` passes `pFont` to `ITextRange2::SetFont2`, which the rich edit control refused with `E_NOTIMPL` (&h80004001) in testing, both for the selection's own font and for a duplicate. Change the object `GetFont` returns instead.

| Parameter | Meaning |
| --- | --- |
| `pFont` | The font object whose attributes to apply. |

**Returns** `GetFont`: the font object, or `NULL`. `SetFont`: an `HRESULT`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim font as CTextFont2 = sel.GetFont()
font.SetBold( tomTrue )     ' the five characters turn bold
```

Microsoft Learn: [ITextRange2::GetFont2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getfont2), [ITextRange2::SetFont2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-setfont2)

### GetPara, SetPara

```freebasic
function GetPara() as ITextPara2 ptr
function SetPara( byval pPara as ITextPara2 ptr ) as HRESULT
```

`GetPara` returns an `ITextPara2` for the paragraph formatting of the paragraphs the selection touches. The caller owns it: wrap it in a [CTextPara2](CTextPara2). Like the font, it is live: setting a property on it reformats the paragraphs.

`SetPara` passes `pPara` to `ITextRange2::SetPara2`, which the control refused with `E_NOTIMPL` in testing. Change the object `GetPara` returns instead.

| Parameter | Meaning |
| --- | --- |
| `pPara` | The paragraph object whose attributes to apply. |

**Returns** `GetPara`: the paragraph object, or `NULL`. `SetPara`: an `HRESULT`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim para as CTextPara2 = sel.GetPara()
para.SetAlignment( tomAlignCenter )
```

Microsoft Learn: [ITextRange2::GetPara2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getpara2), [ITextRange2::SetPara2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-setpara2)

### GetGravity, SetGravity

```freebasic
function GetGravity() as long
function SetGravity( byval Value as long ) as HRESULT
```

The gravity decides, at each end of the selection, whether it takes the character formatting of the text before or after it. `tomGravityUI` (0, the default) follows the user-interface rules; `tomGravityBack` (1) and `tomGravityFore` (2) use the text before or after at both ends; `tomGravityIn` (3) and `tomGravityOut` (4) use the text inside or outside the selection.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomGravity*` value. |

**Returns** `GetGravity`: the gravity. `SetGravity`: `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.SetGravity( tomGravityFore )
print sel.GetGravity()   ' 2
```

Microsoft Learn: [ITextRange2::GetGravity](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getgravity), [ITextRange2::SetGravity](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-setgravity)

### GetProperty, SetProperty

```freebasic
function GetProperty( byval nType as long ) as long
function SetProperty( byval nType as long, byval Value as long ) as HRESULT
```

Read and set one property of the selection by its id. The ids are not listed in the interface's documentation; in testing, 0 and `tomCanCopy` gave `E_NOTIMPL`. Prefer the named members and the font and paragraph objects.

| Parameter | Meaning |
| --- | --- |
| `nType` | The property id. |
| `Value` | The new value. |

**Returns** `GetProperty`: the value, 0 on failure. `SetProperty`: an `HRESULT`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim v as long = sel.GetProperty( tomCanCopy )
if sel.GetLastResult() <> S_OK then print "not available"
```

Microsoft Learn: [ITextRange2::GetProperty](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getproperty), [ITextRange2::SetProperty](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-setproperty)

### GetDropCap, SetDropCap

```freebasic
function GetDropCap( byval pcLine as long ptr, byval pPosition as long ptr ) as HRESULT
function SetDropCap( byval cLine as long, byval Position as long ) as HRESULT
```

Would read or set the drop-cap (a large initial letter) of the paragraph: `pcLine` and `pPosition` receive the number of lines it spans and its position. The rich edit control returns `E_NOTIMPL` for both.

| Parameter | Meaning |
| --- | --- |
| `pcLine`, `cLine` | The number of lines the letter spans. |
| `pPosition`, `Position` | Its position. |

**Returns** `E_NOTIMPL`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim as long nLines, nPos
if sel.GetDropCap( @nLines, @nPos ) = E_NOTIMPL then print "no drop caps"
```

Microsoft Learn: [ITextRange2::GetDropCap](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getdropcap), [ITextRange2::SetDropCap](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-setdropcap)

### GetPoint

```freebasic
function GetPoint( byval nType as long = tomStart + TA_BASELINE + TA_LEFT, byval px as long ptr, byval py as long ptr ) as HRESULT
```

Writes to `*px` and `*py` the position of the start or end of the selection. `nType` combines `tomStart` or `tomEnd` with a `TA_LEFT` / `TA_CENTER` / `TA_RIGHT` and a `TA_TOP` / `TA_BASELINE` / `TA_BOTTOM` alignment; the point is in screen coordinates unless `tomClientCoord` is added, and off-screen text fails unless `tomAllowOffClient` is. The first parameter has a default but the two after it do not: write `GetPoint( , @x, @y )` to use it.

| Parameter | Meaning |
| --- | --- |
| `nType` | Which end and alignment; default `tomStart + TA_BASELINE + TA_LEFT`. |
| `px`, `py` | Receive the coordinates. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim as long x, y
if sel.GetPoint( tomStart or TA_TOP or TA_LEFT or tomClientCoord, @x, @y ) = S_OK then print x; y
```

Microsoft Learn: [ITextRange::GetPoint](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-getpoint)

### SetPoint

```freebasic
function SetPoint( byval x as long, byval y as long, byval nType as long, byval Extend as long = 0 ) as HRESULT
```

Moves the selection to the character at (`x`, `y`), or with `Extend` nonzero extends it to there. `nType` is as for [GetPoint](#getpoint).

| Parameter | Meaning |
| --- | --- |
| `x`, `y` | The point. |
| `nType` | Alignment and coordinate flags, as for `GetPoint`. |
| `Extend` | 0 to move; nonzero to extend. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.SetPoint( 10, 10, tomStart or TA_TOP or TA_LEFT or tomClientCoord )
```

Microsoft Learn: [ITextRange::SetPoint](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-setpoint)

### GetRect

```freebasic
function GetRect( byval nType as long, byval pLeft as long ptr, byval pTop as long ptr, byval pRight as long ptr, byval pBottom as long ptr, byval pHit as long ptr ) as HRESULT
```

Writes the rectangle of the selection to the four edge pointers, and to `*pHit` a hit-test value. `nType` takes the same flags as for [GetPoint](#getpoint). The rectangle is in client coordinates.

| Parameter | Meaning |
| --- | --- |
| `nType` | Flags, as for `GetPoint`. |
| `pLeft` … `pBottom` | Receive the edges. |
| `pHit` | Receives the hit-test value. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim as long l, t, rgt, b, hit
sel.GetRect( tomStart, @l, @t, @rgt, @b, @hit )
print rgt - l; " x"; b - t
```

Microsoft Learn: [ITextRange2::GetRect](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getrect)

### ScrollIntoView

```freebasic
function ScrollIntoView( byval Value as long = tomStart ) as HRESULT
```

Scrolls the control until the start of the selection (the default) or its end, with `tomEnd`, is in view.

| Parameter | Meaning |
| --- | --- |
| `Value` | `tomStart` (the default) or `tomEnd`. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.ScrollIntoView( tomEnd )
```

Microsoft Learn: [ITextRange::ScrollIntoView](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-scrollintoview)

### GetEmbeddedObject

```freebasic
function GetEmbeddedObject() as IUnknown ptr
```

Returns the `IUnknown` of the OLE object at the start of the selection, which must be an insertion point or cover just that object. The caller releases it. Where there is no object it returns `NULL` and `GetLastResult()` is `S_FALSE`.

**Returns** the object, or `NULL`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim pObj as IUnknown ptr = sel.GetEmbeddedObject()
if pObj then pObj->lpvtbl->Release( pObj )
```

Microsoft Learn: [ITextRange::GetEmbeddedObject](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange-getembeddedobject)

### GetCount

```freebasic
function GetCount() as long
```

Returns how many subranges the selection has, the active one included: 1 for an ordinary selection. A multiple selection (made with Ctrl in the control, or with [AddSubrange](#addsubrange)) has more.

**Returns** the count.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print sel.GetCount()     ' 1
```

Microsoft Learn: [ITextRange2::GetCount](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getcount)

### AddSubrange

```freebasic
function AddSubrange( byval cp1 as long, byval cp2 as long, byval Activate as long ) as HRESULT
```

Adds the text from `cp1` to `cp2` as a subrange; with `Activate` nonzero it becomes the active one. In testing this worked on the selection (the count went to 2) but not on a plain range, where it returned `S_OK` and the count stayed 1.

| Parameter | Meaning |
| --- | --- |
| `cp1`, `cp2` | The ends of the new subrange. |
| `Activate` | Nonzero to make it active. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
sel.AddSubrange( 12, 15, 0 )
print sel.GetCount()   ' 2
```

Microsoft Learn: [ITextRange2::AddSubrange](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-addsubrange)

### GetSubrange

```freebasic
function GetSubrange( byval iSubrange as long, byval pcpFirst as long ptr, byval pcpLim as long ptr ) as HRESULT
```

Writes the start and end of subrange `iSubrange` (from 0) to `*pcpFirst` and `*pcpLim`. An index that does not exist gives `E_FAIL`.

| Parameter | Meaning |
| --- | --- |
| `iSubrange` | The subrange, from 0. |
| `pcpFirst`, `pcpLim` | Receive its ends. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
dim as long cpFirst, cpLim
if sel.GetSubrange( 0, @cpFirst, @cpLim ) = S_OK then print cpFirst; cpLim
```

Microsoft Learn: [ITextRange2::GetSubrange](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getsubrange)

### DeleteSubrange, SetActiveSubrange

```freebasic
function DeleteSubrange( byval cpFirst as long, byval cpLim as long ) as HRESULT
function SetActiveSubrange( byval cpAnchor as long, byval cpActive as long ) as HRESULT
```

`DeleteSubrange` removes the subrange from `cpFirst` to `cpLim`; `SetActiveSubrange` makes the subrange with those ends the active one. Both returned `E_NOTIMPL` in testing, on the selection and on a range.

| Parameter | Meaning |
| --- | --- |
| `cpFirst`, `cpLim` / `cpAnchor`, `cpActive` | The ends of the subrange. |

**Returns** an `HRESULT`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
if sel.SetActiveSubrange( 6, 9 ) = E_NOTIMPL then print "not supported"
```

Microsoft Learn: [ITextRange2::DeleteSubrange](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-deletesubrange), [ITextRange2::SetActiveSubrange](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-setactivesubrange)

### InsertTable

```freebasic
function InsertTable( byval cCol as long, byval cRow as long, byval AutoFit as long ) as HRESULT
```

Inserts a table of `cCol` columns and `cRow` rows at the selection, replacing its text if any. `AutoFit` says how the cell widths fit the space. The borders are thin and black; use [GetRow](#getrow) to change the table's properties.

| Parameter | Meaning |
| --- | --- |
| `cCol` | Columns. |
| `cRow` | Rows. |
| `AutoFit` | How the cells fit the target space. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
sel.InsertTable( 3, 2, 0 )   ' three columns, two rows
```

Microsoft Learn: [ITextRange2::InsertTable](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-inserttable)

### GetRow

```freebasic
function GetRow() as ITextRow ptr
```

Returns an `ITextRow` for the table row the selection is in; the caller owns it: wrap it in a [CTextRow](CTextRow). Outside a table it returns `NULL` and `GetLastResult()` is `E_FAIL`.

**Returns** the row object, or `NULL`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim pRow as ITextRow ptr = sel.GetRow()
if pRow then pRow->lpvtbl->Release( pRow )
```

Microsoft Learn: [ITextRange2::GetRow](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getrow)

### GetCells, GetColumn, GetTable

```freebasic
function GetCells() as IUnknown ptr
function GetColumn() as IUnknown ptr
function GetTable() as IUnknown ptr
```

Would return objects for the selected cells, column and table. The rich edit control returns `E_NOTIMPL` and `NULL` for all three; use [GetRow](#getrow) for table work.

**Returns** `NULL`.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
if sel.GetTable() = NULL then print "&h"; hex( sel.GetLastResult() )   ' &h80004001
```

Microsoft Learn: [ITextRange2::GetCells](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getcells), [ITextRange2::GetColumn](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getcolumn), [ITextRange2::GetTable](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-gettable)

### BuildUpMath, Linearize

```freebasic
function BuildUpMath( byval Flags as long ) as HRESULT
function Linearize( byval Flags as long ) as HRESULT
```

`BuildUpMath` turns linear-format math in the selection, such as `a/b`, into built-up form (a stacked fraction), or changes the built-up form it is in; `Linearize` turns built-up math, ruby and other inline objects back into linear text. `Flags` takes `tomMath*` values (`tomMathAutoCorrect`, `tomMathBuildDown`, `tomNeedTermOp` …). The text must be in a math zone.

| Parameter | Meaning |
| --- | --- |
| `Flags` | A combination of `tomMath*` flags, or 0. |

**Returns** `S_OK` when something changed, `S_FALSE` when nothing did, or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
if sel.BuildUpMath( 0 ) = S_OK then sel.Linearize( 0 )
```

Microsoft Learn: [ITextRange2::BuildUpMath](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-buildupmath), [ITextRange2::Linearize](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-linearize)

### GetInlineObject, SetInlineObject

```freebasic
function GetInlineObject( byval pType as long ptr, byval pAlign as long ptr, byval pChar as long ptr, byval pChar1 as long ptr, byval pChar2 as long ptr, byval pCount as long ptr, byval pTeXStyle as long ptr, byval pcCol as long ptr, byval pLevel as long ptr ) as HRESULT
function SetInlineObject( byval nType as long, byval Align as long, byval Char as long, byval Char1 as long, byval Char2 as long, byval Count as long, byval TeXStyle as long, byval cCol as long ) as HRESULT
```

`GetInlineObject` writes the properties of the inline object (a built-up math object, ruby text …) at the active end of the selection to the nine pointers: its type, alignment, characters, argument count, TeX style, column count and nesting level. Where there is none it returns `S_FALSE` and the type is `tomSimpleText` (0).

`SetInlineObject` inserts an inline object of type `nType` (`tomFraction`, `tomRuby` …) with those properties at an insertion point.

| Parameter | Meaning |
| --- | --- |
| `nType`, `pType` | The object type: `tomFraction`, `tomRuby`, `tomEq` … |
| `Align`, `pAlign` | The alignment. |
| `Char`, `Char1`, `Char2` | Characters the object uses, such as brackets. |
| `Count`, `pCount` | The number of arguments. |
| `TeXStyle`, `pTeXStyle` | The TeX style. |
| `cCol`, `pcCol` | Columns, for an equation array. |
| `pLevel` | Receives the nesting level. |

**Returns** `S_OK`, `S_FALSE` (no object) or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim as long t, a, c, c1, c2, n, tex, cols, lvl
if sel.GetInlineObject( @t, @a, @c, @c1, @c2, @n, @tex, @cols, @lvl ) = S_OK then print "object type"; t
```

Microsoft Learn: [ITextRange2::GetInlineObject](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getinlineobject), [ITextRange2::SetInlineObject](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-setinlineobject)

### GetMathFunctionType

```freebasic
function GetMathFunctionType( byref wszName as wstring ) as HRESULT
```

Returns how the math engine treats the function name `wszName`: `tomFunctionTypeTakesArg` (1) for "sin", `tomFunctionTypeIsLim` (4) for "lim", `tomFunctionTypeNone` (0) for a name it does not know. The declaration says `HRESULT`, but the value returned is this type, not a result code; the result is in `GetLastResult()`.

| Parameter | Meaning |
| --- | --- |
| `wszName` | The function name. |

**Returns** a `tomFunctionType*` value.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 5 )
print sel.GetMathFunctionType( "sin" )    ' 1
```

Microsoft Learn: [ITextRange2::GetMathFunctionType](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-getmathfunctiontype)

### InsertImage

```freebasic
function InsertImage( byval width_ as long, byval height_ as long, byval ascent as long, byval nType as long, byref wszAltText as wstring, byval pStream as IStream ptr ) as HRESULT
```

Inserts the image whose data `pStream` holds, replacing the text of the selection if any. `width_` and `height_` are the displayed size in HiMetric units (0.01 mm). `nType` is the vertical alignment: `TA_BASELINE`, `TA_TOP` or `TA_BOTTOM`; with `TA_BASELINE`, `ascent` is how far the image rises above the baseline. `wszAltText` is its alternative text.

| Parameter | Meaning |
| --- | --- |
| `width_`, `height_` | The size, in HiMetric. |
| `ascent` | The rise above the baseline, for `TA_BASELINE`. |
| `nType` | `TA_BASELINE`, `TA_TOP` or `TA_BOTTOM`. |
| `wszAltText` | The alternative text. |
| `pStream` | The image data. |

**Returns** `S_OK` or an error.

**Example**

```freebasic
dim sel as CTextSelection2 = CRichEditCtxPtr( hCtrl )->Selection2()
sel.SetRange( 0, 0 )
dim pStream as IStream ptr
CreateStreamOnHGlobal( NULL, TRUE, @pStream )   ' fill it with PNG data first
sel.InsertImage( 2000, 1000, 0, TA_BASELINE, "A chart", pStream )
pStream->lpvtbl->Release( pStream )
```

Microsoft Learn: [ITextRange2::InsertImage](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextrange2-insertimage)

## See also

- [sys/win/richedit](SysWin-RichEdit), the module overview
- [CTextRange2](CTextRange2), a span of text that is not the selection, with the same members
- [CRichEditCtx: document](CRichEditCtx-Document) for `Range`, `Selection2` and the document
- [CTextFont2](CTextFont2) and [CTextPara2](CTextPara2) for the objects `GetFont` and `GetPara` return
- [CTextRow](CTextRow) for table rows, [CTextStory](CTextStory) for stories
- [Text Object Model interfaces](SysWin-RichEdit-TOM)
- Microsoft Learn: [ITextRange2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nn-tom-itextrange2), [ITextSelection2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nn-tom-itextselection2)
