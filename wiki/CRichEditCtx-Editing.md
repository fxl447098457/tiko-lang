[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/richedit](SysWin-RichEdit) › [CRichEditCtx](CRichEditCtx) › **CRichEditCtx: editing**

# CRichEditCtx: editing
Selects, finds, inserts and replaces text in a rich edit control, and undoes edits.

<!-- scope: CRichEditCtx -->

Selects, finds, inserts and replaces text in a rich edit control, and undoes edits.

These are the [CRichEditCtx](CRichEditCtx) members that work on the text itself: the selection
and the caret, searching, lines and scrolling, inserting and replacing, undo and redo, word wrap,
margins, tables, images and streams. Creating the control, its properties and the file members
are on [CRichEditCtx](CRichEditCtx) and [CRichEditCtx: documents and formatting](CRichEditCtx-Document).

**Positions.** A character position is a zero-based index into the text. A paragraph break is
one character, a carriage return (`chr(13)`), and an inserted image or object is one character
too. Text read back with [GetTextRange](#gettextrange), [GetSelText](#getseltext) or
[GetLine](#getline) has a lone carriage return at each paragraph break, not a CR/LF pair. The
pair `(0, -1)` means the whole text. After the last character there is one more, the final
paragraph mark, so selecting everything ends one past the text: for 31 characters the selection
is `0` to `32`.

**Lines.** Line numbers are zero-based and count the lines as the control shows them: with word
wrap on, one paragraph can be several lines.

**Results.** Most members that return the control's answer to a message reset
`GetLastResult()` to 0, and several of those that return nothing or a structure store the
message's result there. The members that work through COM or a file (`Undo( Count )`,
[InsertImage](#insertimage), [SaveRawText](#saverawtext) …) store an `HRESULT` or a Windows
error code.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/richedit"
using win, gui, richedit
```

## Example

A rich edit control with three buttons: **Find fox** selects the next "fox" after the selection,
wrapping round to the top, and reports its line and column in the caption; **Insert** inserts a
word at the caret; **Undo** undoes the last edit:

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/richedit"
using win, gui, richedit

const IDC_EDIT = 101, IDC_FIND = 102, IDC_INSERT = 103, IDC_UNDO = 104

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "EditingDemo"
    dim hWin as HWND = pWindow.Create( NULL, "CRichEditCtx: editing", @WndProc )
    pWindow.SetClientSize( 520, 300 )
    pWindow.Center
    dim pRichEdit as CRichEditCtx = CRichEditCtx( @pWindow, IDC_EDIT, "", 10, 10, 500, 240 )
    pRichEdit.SetText( "The quick brown fox jumps over the lazy dog." & chr(13) & "A second fox is waiting." )
    pRichEdit.EnableWordWrap()
    pRichEdit.EmptyUndoBuffer()
    pWindow.AddControl( "Button", hWin, IDC_FIND, "&Find fox", 10, 260, 90, 28 )
    pWindow.AddControl( "Button", hWin, IDC_INSERT, "&Insert", 110, 260, 90, 28 )
    pWindow.AddControl( "Button", hWin, IDC_UNDO, "&Undo", 210, 260, 90, 28 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hwnd, IDC_EDIT )
                if pRichEdit = NULL then return 0
                select case CBCTL( wParam, lParam )
                    case IDC_FIND
                        dim cr as CHARRANGE = pRichEdit->ExGetSel()
                        dim found as CHARRANGE = pRichEdit->FindTextEx( FR_DOWN, cr.cpMax, -1, "fox" )
                        if found.cpMin = -1 then found = pRichEdit->FindTextEx( FR_DOWN, 0, -1, "fox" )
                        if found.cpMin <> -1 then
                            pRichEdit->ExSetSel( found.cpMin, found.cpMax )
                            pRichEdit->ScrollCaret()
                            dim nLine as long = pRichEdit->ExLineFromChar( found.cpMin )
                            SetWindowText( hwnd, "fox at line " & ( nLine + 1 ) & ", column " & _
                                                 ( found.cpMin - pRichEdit->LineIndex( nLine ) + 1 ) )
                        end if
                    case IDC_INSERT
                        dim wszWord as wstring * 16 = "[note] "
                        pRichEdit->InsertText( wszWord )
                    case IDC_UNDO
                        if pRichEdit->CanUndo() then pRichEdit->Undo()
                end select
                SetFocus( pRichEdit->hRichEdit )
            end if
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

| Member | Does |
| --- | --- |
| [CanPaste](#canpaste) | Says whether the clipboard holds a format the control can paste. |
| [CanRedo](#canredo) | Says whether there is anything to redo. |
| [CanUndo](#canundo) | Says whether there is anything to undo. |
| [CallAutocorrectProc](#callautocorrectproc) | Runs the autocorrect procedure for a character. |
| [DisplayBand](#displayband) | Draws a band of text formatted with FormatRange. |
| [EmptyUndoBuffer](#emptyundobuffer) | Empties the undo and redo queues. |
| [ExGetSel](#exgetsel) | Returns the selection as a `CHARRANGE`. |
| [ExLimitText](#exlimittext) | Limits how much text the user can type or paste. |
| [ExLineFromChar](#exlinefromchar) | Returns the line that holds a character. |
| [ExSetSel](#exsetsel) | Selects a range of characters. |
| [FindText](#findtext) | Finds text and returns where it starts. |
| [FindTextEx](#findtextex) | Finds text and returns the range it covers. |
| [FindWordBreak](#findwordbreak) | Finds the next word break, or classifies a character. |
| [FirstVisibleLine, GetFirstVisibleLine](#firstvisibleline-getfirstvisibleline) | Return the topmost visible line. |
| [FormatRange](#formatrange) | Formats, measures or draws a range of text for a device. |
| [CharFromPos, GetCharFromPos](#charfrompos-getcharfrompos) | Return the character nearest a point. |
| [IMECompMode, GetIMECompMode](#imecompmode-getimecompmode) | Return the current IME composition mode. |
| [GetIMEColor, SetIMEColor](#getimecolor-setimecolor) | Read or set the IME composition colours. |
| [IMEProperty, GetIMEProperty](#imeproperty-getimeproperty) | Return a property of the current IME. |
| [GetLine](#getline) | Returns the text of one line. |
| [GetOleInterface](#getoleinterface) | Returns the control's `IRichEditOle` interface. |
| [GetSel](#getsel) | Returns the start and end of the selection. |
| [SetSel](#setsel) | Selects a range of characters. |
| [CaretPos, GetCaretPos, SetCaretPos](#caretpos-getcaretpos-setcaretpos) | Read or move the caret. |
| [GetSelText](#getseltext) | Returns the selected text. |
| [WordWrapMode, GetWordWrapMode, SetWordWrapMode](#wordwrapmode-getwordwrapmode-setwordwrapmode) | Read or set the word-wrap and word-break options. |
| [GetZoom, SetZoom](#getzoom-setzoom) | Read or set the zoom ratio. |
| [GetTableParams, SetTableParams](#gettableparams-settableparams) | Read or change the parameters of table rows and cells. |
| [GetTextEx](#gettextex) | Copies the text into a buffer, in a code page of your choice. |
| [GetRawTextLength](#getrawtextlength) | Returns the size of the buffer GetRawText uses. |
| [GetRawText](#getrawtext) | Returns the text as stored, in the ANSI code page. |
| [SaveRawText](#saverawtext) | Writes GetRawText to a file. |
| [SetTextEx](#settextex) | Sets, inserts or replaces text, plain or RTF. |
| [InsertText](#inserttext) | Inserts text at the caret or at a position. |
| [ReplaceText](#replacetext) | Replaces a range of text. |
| [GetThumb](#getthumb) | Returns the position of the vertical scroll box. |
| [WordBreakProc, GetWordBreakProc, SetWordBreakProc](#wordbreakproc-getwordbreakproc-setwordbreakproc) | Read or replace the word-break procedure. |
| [WordBreakProcEx, GetWordBreakProcEx, SetWordBreakProcEx](#wordbreakprocex-getwordbreakprocex-setwordbreakprocex) | Read or replace the extended word-break procedure. |
| [HideSelection](#hideselection) | Hides or shows the selection highlight. |
| [GetIMECompText](#getimecomptext) | Copies the IME composition text. |
| [InsertImage](#insertimage) | Replaces the selection with an image. |
| [InsertTable](#inserttable) | Inserts table rows with empty cells. |
| [IsIME](#isime) | Says whether the input locale is East Asian. |
| [GetLineCount](#getlinecount) | Returns the number of lines. |
| [LineFromChar](#linefromchar) | Returns the line that holds a character. |
| [LineIndex](#lineindex) | Returns the position of the first character of a line. |
| [LineLength](#linelength) | Returns the length of a line. |
| [LineScroll](#linescroll) | Scrolls the text up or down by lines. |
| [PasteSpecial](#pastespecial) | Pastes one clipboard format. |
| [PosFromChar](#posfromchar) | Returns where a character is drawn. |
| [Reconversion](#reconversion) | Opens the IME reconversion window. |
| [ReplaceSel](#replacesel) | Replaces the selection with text. |
| [RequestResize](#requestresize) | Asks the control to send `EN_REQUESTRESIZE`. |
| [Scroll](#scroll) | Scrolls by a line or a page. |
| [ScrollCaret](#scrollcaret) | Scrolls the caret into view. |
| [SelectionType](#selectiontype) | Says what the selection contains. |
| [SetBkgndColor](#setbkgndcolor) | Sets the background colour. |
| [SetFontSize](#setfontsize) | Makes the selected text larger or smaller. |
| [Margins, SetMargins](#margins-setmargins) | Set the left and right margins. |
| [LeftMargin, SetLeftMargin](#leftmargin-setleftmargin) | Set the left margin. |
| [RightMargin, SetRightMargin](#rightmargin-setrightmargin) | Set the right margin. |
| [SetOleCallback](#setolecallback) | Gives the control an `IRichEditOleCallback` object. |
| [SetPalette](#setpalette) | Sets the palette the control draws with. |
| [SetReadOnly](#setreadonly) | Makes the control read-only or editable. |
| [SetTabStops](#settabstops) | Sets the tab stops. |
| [SetTargetDevice](#settargetdevice) | Sets the device and line width text is formatted for. |
| [SetUIAName](#setuianame) | Sets the control's name for UI Automation. |
| [SetUndoLimit](#setundolimit) | Sets how many actions the undo queue holds. |
| [ShowScrollBar](#showscrollbar) | Shows or hides a scroll bar. |
| [StopGroupTyping](#stopgrouptyping) | Ends the current typing undo action. |
| [StreamIn](#streamin) | Reads text or RTF from a callback. |
| [StreamOut](#streamout) | Writes the text or RTF to a callback. |
| [TextLengthEx, GetTextLengthEx](#textlengthex-gettextlengthex) | Return the length of the text, counted as you choose. |
| [GetTextRange](#gettextrange) | Returns a range of text. |
| [Redo](#redo) | Redoes one or more actions. |
| [Undo](#undo) | Undoes one or more actions. |
| [SuspendUndo](#suspendundo) | Turns undo off and empties the undo queue. |
| [ResumeUndo](#resumeundo) | Turns undo back on. |
| [EnableWordWrap](#enablewordwrap) | Wraps lines at the width of the control. |
| [DisableWordWrap](#disablewordwrap) | Formats lines for a wide fixed width. |

## Reference

### CanPaste

```freebasic
function CanPaste( byval clipformat as long ) as boolean
```

Says whether the control can paste the clipboard format `clipformat` (`CF_UNICODETEXT`,
`CF_BITMAP`, a registered format …). With `0` it says whether the clipboard holds any format the
control can paste.

**Returns** `true` when the format can be pasted.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "something to paste: "; pRichEdit->CanPaste( 0 )
```

Microsoft Learn: [EM_CANPASTE](https://learn.microsoft.com/en-us/windows/win32/controls/em-canpaste)

### CanRedo

```freebasic
function CanRedo() as boolean
```

Says whether the redo queue holds an action, that is whether [Redo](#redo) would do anything.

**Returns** `true` when there is something to redo.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->CanRedo() then pRichEdit->Redo()
```

Microsoft Learn: [EM_CANREDO](https://learn.microsoft.com/en-us/windows/win32/controls/em-canredo)

### CanUndo

```freebasic
function CanUndo() as boolean
```

Says whether the undo queue holds an action, that is whether [Undo](#undo) would do anything.
Text set with `SetText` does not go into the queue.

**Returns** `true` when there is something to undo.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->CanUndo() then pRichEdit->Undo()
```

Microsoft Learn: [EM_CANUNDO](https://learn.microsoft.com/en-us/windows/win32/controls/em-canundo)

### CallAutocorrectProc

```freebasic
function CallAutocorrectProc( byval char as WCHAR ) as long
```

Calls the autocorrect procedure set with `SetAutoCorrectProc`, as if the user had just typed
`char`, provided the text before the insertion point is a candidate for correction.

**Returns** the control's answer to the message; it was 1 in a control with no autocorrect
procedure set.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->CallAutocorrectProc( asc( " " ) )
```

Microsoft Learn: [EM_CALLAUTOCORRECTPROC](https://learn.microsoft.com/en-us/windows/win32/controls/em-callautocorrectproc)

### DisplayBand

```freebasic
function DisplayBand( byref rc as .RECT ) as boolean
```

Draws the text formatted by a [FormatRange](#formatrange) call with `fRender` set to `false`
into the rectangle `rc` of that call's device context. Use it to print a page in bands.

**Returns** `true` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim rcBand as RECT = type( 0, 0, 1440 * 6, 1440 )     ' twips
pRichEdit->DisplayBand( rcBand )
```

Microsoft Learn: [EM_DISPLAYBAND](https://learn.microsoft.com/en-us/windows/win32/controls/em-displayband)

### EmptyUndoBuffer

```freebasic
sub EmptyUndoBuffer()
```

Empties the undo and redo queues, so [CanUndo](#canundo) and [CanRedo](#canredo) return
`false` until the next edit or undo. Call it after loading a document, so that the first undo does not
remove it.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetText( "A fresh document" )
pRichEdit->EmptyUndoBuffer()
```

Microsoft Learn: [EM_EMPTYUNDOBUFFER](https://learn.microsoft.com/en-us/windows/win32/controls/em-emptyundobuffer)

### ExGetSel

```freebasic
function ExGetSel() as CHARRANGE
sub ExGetSel( byref cpMin as long, byref cpMax as long )
```

Reads the selection. `cpMin` is the first selected character and `cpMax` the position after the
last one; when nothing is selected both are the caret position.

The first form returns both in a `CHARRANGE`. The second writes the start into `cpMin` and the end in cpMax.

**Returns** the selection (first form).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim cr as CHARRANGE = pRichEdit->ExGetSel()
print "selected"; cr.cpMax - cr.cpMin; " characters from"; cr.cpMin
```

Microsoft Learn: [EM_EXGETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-exgetsel)

### ExLimitText

```freebasic
sub ExLimitText( byval dwLimit as DWORD )
```

Sets the most characters the user can type or paste into the control; `0` restores the default
of 64K characters. Text the program puts in is not held to it: `SetText` and
[ReplaceSel](#replacesel) both went past a limit of 5.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->ExLimitText( 1024 * 1024 )     ' a megabyte of characters
```

Microsoft Learn: [EM_EXLIMITTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/em-exlimittext)

### ExLineFromChar

```freebasic
function ExLineFromChar( byval iIndex as long ) as long
```

Returns the zero-based line that holds the character at position `iIndex`. `-1` gives the line
of the caret, or of the start of the selection.

**Returns** the line number.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "the caret is on line"; pRichEdit->ExLineFromChar( -1 ) + 1
```

Microsoft Learn: [EM_EXLINEFROMCHAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-exlinefromchar)

### ExSetSel

```freebasic
function ExSetSel( byref cr as CHARRANGE ) as DWORD
sub ExSetSel( byval cpMin as long = 0, byval cpMax as long = -1 )
```

Selects the characters from `cpMin` up to, not including, `cpMax`. `(0, -1)`, the second form's
default, selects everything; equal values put the caret there with nothing selected; a `cpMin`
of `-1` removes the selection and leaves the caret where it is. The control does not scroll: call
[ScrollCaret](#scrollcaret) to bring the selection into view.

**Returns** first form: the end of the selection the control actually set, the higher of the
two positions (3 for 1 to 3, and 4 for 4 to 2).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->ExSetSel()            ' select all
pRichEdit->ExSetSel( 4, 7 )      ' characters 4, 5 and 6
```

Microsoft Learn: [EM_EXSETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-exsetsel)

### FindText

```freebasic
function FindText( byval fOptions as DWORD, byref ftw as FINDTEXTW ) as long
function FindText( byval fOptions as DWORD = FR_DOWN, byval cpMin as long = 0, byval cpMax as long = -1, byref wszText as wstring ) as long
```

Searches the text for `wszText` between `cpMin` and `cpMax` (`-1`: to the end). The second form
fills the `FINDTEXTW` for you; the first takes one you filled.

| Parameter | Meaning |
| --- | --- |
| `fOptions` | `FR_DOWN` to search forward from `cpMin`; without it the search goes backward from `cpMin` towards `cpMax`. Add `FR_MATCHCASE` and `FR_WHOLEWORD` as needed. |
| `cpMin`, `cpMax` | The range to search. |
| `wszText` | The text to find. |

**Returns** the position where the match starts, or `-1` when there is none. With the text
"one two three", searching for "two" returned 4 and a whole-word search for "on" returned `-1`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim nPos as long = pRichEdit->FindText( FR_DOWN or FR_MATCHCASE, 0, -1, "Total" )
if nPos >= 0 then pRichEdit->ExSetSel( nPos, nPos + 5 )
```

Microsoft Learn: [EM_FINDTEXTW](https://learn.microsoft.com/en-us/windows/win32/controls/em-findtextw)

### FindTextEx

```freebasic
function FindTextEx( byval fOptions as DWORD, byref ftexw as FINDTEXTEXW ) as long
function FindTextEx( byval fOptions as DWORD = FR_DOWN, byval cpMin as long = 0, byval cpMax as long = -1, byref wszText as wstring ) as CHARRANGE
```

Searches like [FindText](#findtext) and also reports the range the match covers, ready for
[ExSetSel](#exsetsel). The first form returns the start and puts the range in
`ftexw.chrgText`; the second returns the range itself.

**Returns** the range of the match (second form), `(-1, -1)` when there is none; the start of the
match or `-1` (first form).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim found as CHARRANGE = pRichEdit->FindTextEx( FR_DOWN, 0, -1, "line" )
if found.cpMin <> -1 then pRichEdit->ExSetSel( found.cpMin, found.cpMax )
```

Microsoft Learn: [EM_FINDTEXTEXW](https://learn.microsoft.com/en-us/windows/win32/controls/em-findtextexw)

### FindWordBreak

```freebasic
function FindWordBreak( byval fOperation as DWORD, byval dwStartPos as DWORD ) as DWORD
```

Finds the next word break before or after the position `dwStartPos`, or says what kind of
character is there, using the control's word-break rules.

| Parameter | Meaning |
| --- | --- |
| `fOperation` | `WB_MOVEWORDRIGHT` / `WB_MOVEWORDLEFT` (start of the next / previous word), `WB_RIGHT` / `WB_LEFT` (next / previous break), `WB_ISDELIMITER`, `WB_CLASSIFY` … |
| `dwStartPos` | The position to start from. |

**Returns** a position, or for `WB_ISDELIMITER` nonzero when the character is a delimiter. In
"one two three", `WB_MOVEWORDRIGHT` from 0 returned 4.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim nNext as DWORD = pRichEdit->FindWordBreak( WB_MOVEWORDRIGHT, pRichEdit->GetCaretPos() )
pRichEdit->SetCaretPos( nNext )
```

Microsoft Learn: [EM_FINDWORDBREAK](https://learn.microsoft.com/en-us/windows/win32/controls/em-findwordbreak)

### FirstVisibleLine, GetFirstVisibleLine

```freebasic
property FirstVisibleLine() as long
function GetFirstVisibleLine() as long
```

Return the zero-based number of the topmost line the control shows.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "top line:"; pRichEdit->FirstVisibleLine + 1
```

Microsoft Learn: [EM_GETFIRSTVISIBLELINE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getfirstvisibleline)

### FormatRange

```freebasic
function FormatRange( byval fRender as long, byref fr as FORMATRANGE ) as DWORD
```

Lays out the characters `fr.chrg` for the device context `fr.hdc` in the rectangle `fr.rc`
(twips), as for printing. With `fRender` nonzero the text is drawn; with `false` it is only
measured, for [DisplayBand](#displayband) to draw later.

The control keeps information between calls. When you are done, free it by sending the message
with no structure, which this member cannot do: call `richedit.RichEdit.FormatRange( hRichEdit,
false, NULL )` (the `RichEdit` functions are written with the module name in front, since
`RichEdit` alone names the module).

**Returns** the position of the first character that did not fit, where the next page starts.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim hdcPrn as HDC = GetDC( hwnd )
dim fr as FORMATRANGE
fr.hdc = hdcPrn : fr.hdcTarget = hdcPrn
fr.rc = type( 0, 0, 1440 * 6, 1440 * 9 ) : fr.rcPage = fr.rc : fr.chrg = type( 0, -1 )
print "the next page starts at"; pRichEdit->FormatRange( false, fr )
richedit.RichEdit.FormatRange( pRichEdit->hRichEdit, false, NULL ) : ReleaseDC( hwnd, hdcPrn )
```

Microsoft Learn: [EM_FORMATRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/em-formatrange)

### CharFromPos, GetCharFromPos

```freebasic
property CharFromPos( byref ptl as .POINTL ) as long
function GetCharFromPos( byref ptl as .POINTL ) as long
```

Return the position of the character nearest the point `ptl`, in client coordinates. The
reverse of [PosFromChar](#posfromchar).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim ptl as POINTL = type( 20, 40 )
print "character under (20, 40):"; pRichEdit->GetCharFromPos( ptl )
```

Microsoft Learn: [EM_CHARFROMPOS](https://learn.microsoft.com/en-us/windows/win32/controls/em-charfrompos)

### IMECompMode, GetIMECompMode

```freebasic
property IMECompMode() as DWORD
function GetIMECompMode() as DWORD
```

Return the composition mode of the Input Method Editor: `ICM_NOTOPEN` (0) when no IME is open,
otherwise `ICM_LEVEL3`, `ICM_LEVEL2`, `ICM_LEVEL2_5`, `ICM_LEVEL2_SUI` or `ICM_CTF`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->IMECompMode <> ICM_NOTOPEN then print "an IME is composing"
```

Microsoft Learn: [EM_GETIMECOMPMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimecompmode)

### GetIMEColor, SetIMEColor

```freebasic
function GetIMEColor( byval rgCmpclr as .COMPCOLOR ptr ) as long
function SetIMEColor( byval pcompcolor as .COMPCOLOR ptr ) as long
```

Read or set the colours the control uses for IME composition text: an array of four
`COMPCOLOR`, one for each composition state. These apply to East Asian versions of Windows.

**Returns** nonzero on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim cc(0 to 3) as COMPCOLOR
if pRichEdit->GetIMEColor( @cc(0) ) then print hex( cc(0).crText )
```

Microsoft Learn: [EM_GETIMECOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimecolor), [EM_SETIMECOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/em-setimecolor)

### IMEProperty, GetIMEProperty

```freebasic
property IMEProperty( byval figp as DWORD ) as DWORD
function GetIMEProperty( byval figp as DWORD ) as DWORD
```

Return one property of the IME of the current input locale: `figp` is `IGP_PROPERTY`,
`IGP_CONVERSION`, `IGP_SENTENCE`, `IGP_UI`, `IGP_SETCOMPSTR`, `IGP_SELECT` or
`IGP_GETIMEVERSION`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "IME properties: "; hex( pRichEdit->GetIMEProperty( IGP_PROPERTY ) )
```

Microsoft Learn: [EM_GETIMEPROPERTY](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimeproperty)

### GetLine

```freebasic
function GetLine( byval which as DWORD ) as ustring
```

Returns the text of line `which`, as the control shows it. The line ends with the carriage
return of its paragraph when it has one, and the last line ends with the final paragraph mark,
so for "one" / "two" / "third" the three lines are 4, 4 and 6 characters long. A wrapped line
has no carriage return. A line number past the end gives `""`. At most 32 765 characters are
read.

**Returns** the line.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim uLine as ustring = pRichEdit->GetLine( 0 )
print "first line: "; rtrim( uLine, chr(13) )
```

Microsoft Learn: [EM_GETLINE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getline)

### GetOleInterface

```freebasic
function GetOleInterface() as IRichEditOle ptr
```

Returns the control's `IRichEditOle` interface, for working with the objects embedded in the
text. The interface comes with a reference you own: call `Release` on it when you are done.

**Returns** the interface, or `NULL` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pOle as IRichEditOle ptr = pRichEdit->GetOleInterface()
if pOle then print "objects:"; pOle->lpVtbl->GetObjectCount( pOle ) : pOle->lpVtbl->Release( pOle )
```

Microsoft Learn: [EM_GETOLEINTERFACE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getoleinterface)

### GetSel

```freebasic
function GetSel( byref dwStartPos as DWORD, byref dwEndPos as DWORD ) as long
function GetSel() as .POINTL
```

Read the selection: the first selected character and the position after the last one, both the
caret position when nothing is selected. The first form writes them into `dwStartPos` and
`dwEndPos`; the second returns them as `x` (start) and `y` (end) of a `POINTL`.

**Returns** the second form, the selection. The first form returns both positions packed in one
value, the start in the low word and the end in the high word (`&h70004` for 4 to 7), and `-1`
once a position is above 65 535; read the two variables instead.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pt as POINTL = pRichEdit->GetSel()
print "selection:"; pt.x; " to"; pt.y
```

Microsoft Learn: [EM_GETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-getsel)

### SetSel

```freebasic
sub SetSel( byval nStart as long, byval nEnd as long )
sub SetSel( byref pt as POINTL )
```

Selects from `nStart` to `nEnd`, or from `pt.x` to `pt.y`. `(0, -1)` selects everything; a
start of `-1` removes the selection. The two positions may come in either order.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetSel( 0, -1 )
```

Microsoft Learn: [EM_SETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel)

### CaretPos, GetCaretPos, SetCaretPos

```freebasic
property CaretPos() as DWORD
property CaretPos( byval dwPos as DWORD )
function GetCaretPos() as DWORD
sub SetCaretPos( byval dwPos as DWORD )
```

Read or move the caret. Reading gives the start of the selection, the lower of its two ends.
Setting removes the selection and puts the caret before the character at `dwPos`; `-1` puts it
at the end of the text.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->CaretPos = -1          ' to the end
pRichEdit->ScrollCaret()
```

Microsoft Learn: [EM_SETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel)

### GetSelText

```freebasic
function GetSelText() as ustring
```

Returns the selected text, with a carriage return at each paragraph break. Selecting everything
in "one" / "two" gives "one", `chr(13)`, "two": the final paragraph mark is not included.

**Returns** the text, or `""` when nothing is selected.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim uSel as ustring = pRichEdit->GetSelText()
if len( uSel ) then print "selected: "; uSel
```

Microsoft Learn: [EM_GETSELTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getseltext)

### WordWrapMode, GetWordWrapMode, SetWordWrapMode

```freebasic
property WordWrapMode() as DWORD
property WordWrapMode( byval values as DWORD ) as DWORD
function GetWordWrapMode() as DWORD
function SetWordWrapMode( byval values as DWORD ) as DWORD
```

Read or set the word-wrap and word-break options used for East Asian text: a combination of
`WBF_WORDWRAP`, `WBF_WORDBREAK`, `WBF_OVERFLOW`, `WBF_LEVEL1`, `WBF_LEVEL2` and `WBF_CUSTOM`.
A new control reports 0. These options do not turn wrapping of ordinary text on or off; that is
[EnableWordWrap](#enablewordwrap) and [SetTargetDevice](#settargetdevice).

**Returns** the options.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetWordWrapMode( WBF_WORDWRAP or WBF_WORDBREAK )
print hex( pRichEdit->GetWordWrapMode() )
```

Microsoft Learn: [EM_GETWORDWRAPMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getwordwrapmode), [EM_SETWORDWRAPMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setwordwrapmode)

### GetZoom, SetZoom

```freebasic
function GetZoom( byref pzNum as DWORD, byref pzDen as DWORD ) as long
function SetZoom( byval zNum as DWORD, byval zDen as DWORD ) as long
```

Read or set the zoom as the ratio `zNum / zDen`, which must lie between 1/64 and 64.
`SetZoom( 0, 0 )` turns zooming off, and `GetZoom` then reads `0 / 0`.

**Returns** nonzero on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetZoom( 150, 100 )          ' 150 %
dim as DWORD zNum, zDen
if pRichEdit->GetZoom( zNum, zDen ) then print zNum; "/"; zDen
```

Microsoft Learn: [EM_GETZOOM](https://learn.microsoft.com/en-us/windows/win32/controls/em-getzoom), [EM_SETZOOM](https://learn.microsoft.com/en-us/windows/win32/controls/em-setzoom)

### GetTableParams, SetTableParams

```freebasic
function GetTableParams( byref tp as TABLEROWPARMS, byref tcp as TABLECELLPARMS ) as DWORD
function SetTableParams( byref tp as TABLEROWPARMS, byref tcp as TABLECELLPARMS ) as DWORD
```

Read or change the parameters of a table row (`tp`) and its cells (`tcp`, the first of an array
of `tp.cCell` cells). Set `tp.cbRow` and `tp.cbCell` to the sizes of the two structures and
`tp.cpStartRow` to a position in the row first. After [InsertTable](#inserttable) made three
1440-twip cells, reading the row at 0 gave 3 cells, the first 1440 wide.

**Returns** an `HRESULT`: `S_OK` (0) on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim tp as TABLEROWPARMS : tp.cbRow = sizeof( TABLEROWPARMS ) : tp.cbCell = sizeof( TABLECELLPARMS )
tp.cCell = 3 : tp.cpStartRow = 0
dim cells(0 to 2) as TABLECELLPARMS
if pRichEdit->GetTableParams( tp, cells(0) ) = S_OK then print "first cell width:"; cells(0).dxWidth
```

Microsoft Learn: [EM_GETTABLEPARMS](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettableparms), [EM_SETTABLEPARMS](https://learn.microsoft.com/en-us/windows/win32/controls/em-settableparms)

### GetTextEx

```freebasic
function GetTextEx( byref gtex as .GETTEXTEX, byval buffer as any ptr ) as DWORD
```

Copies the text into `buffer`, converted to the code page `gtex.codepage` (1200 for UTF-16,
`CP_UTF8`, `CP_ACP` …). `gtex.cb` is the size of the buffer in bytes; `GT_USECRLF` in
`gtex.flags` turns each paragraph break into CR/LF, `GT_SELECTION` copies only the selection.

**Returns** the number of characters copied, the terminating null not counted.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim wszBuf as wstring * 1024
dim gtex as GETTEXTEX : gtex.cb = sizeof( wszBuf ) : gtex.flags = GT_USECRLF : gtex.codepage = 1200
print pRichEdit->GetTextEx( gtex, @wszBuf ); " characters: "; wszBuf
```

Microsoft Learn: [EM_GETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextex)

### GetRawTextLength

```freebasic
function GetRawTextLength() as long
```

Returns the length [GetRawText](#getrawtext) makes its buffer. The flags it sends ask the
control for a quick estimate in the ANSI code page rather than an exact count, and the estimate
is generous: for 31 characters of plain text it was 62.

**Returns** the estimate, in bytes.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "raw buffer:"; pRichEdit->GetRawTextLength(); " bytes"
```

Microsoft Learn: [EM_GETTEXTLENGTHEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextlengthex)

### GetRawText

```freebasic
function GetRawText() as string
```

Returns the text exactly as the control stores it (`GT_RAWTEXT`), in the ANSI code page.

**Returns** the buffer.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim sRaw as string = pRichEdit->GetRawText()
```

Microsoft Learn: [EM_GETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextex)

### SaveRawText

```freebasic
function SaveRawText( byref wszFilename as wstring, byval Overwrite as boolean = false, byval dwFlagsAndAttributes as DWORD = FILE_ATTRIBUTE_NORMAL ) as boolean
```

Writes the whole string [GetRawText](#getrawtext) returns to the file `wszFilename`.

| Parameter | Meaning |
| --- | --- |
| `wszFilename` | The file to write. |
| `Overwrite` | `true` replaces an existing file; with `false` (the default) an existing file makes the call fail. |
| `dwFlagsAndAttributes` | The attributes of a new file. |

**Returns** `true` on success. On failure `false`, and `GetLastResult()` holds the Windows error
code: 80 (`ERROR_FILE_EXISTS`) when the file is there and `Overwrite` is `false`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->SaveRawText( "notes.txt", true ) = false then print "error"; pRichEdit->GetLastResult()
```

Microsoft Learn: [CreateFileW](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew)

### SetTextEx

```freebasic
function SetTextEx( byref wszText as wstring ) as DWORD
function SetTextEx( byref stex as .SETTEXTEX, byval buffer as any ptr ) as DWORD
function SetTextEx( byref stex as .SETTEXTEX, byref wszText as wstring ) as DWORD
function SetTextEx( byval nStart as long, byval nEnd as long, byref wszText as wstring ) as DWORD
function SetTextEx( byval nPos as long, byref wszText as wstring ) as DWORD
```

Puts text into the control. The text may be plain or RTF (it is RTF when it starts with
`{\rtf`).

- With a `SETTEXTEX`, the forms send the text as they are told: `stex.flags` says whether it
  replaces everything (`ST_DEFAULT`) or the selection (`ST_SELECTION`) and whether the edit can be
  undone (`ST_KEEPUNDO`); `stex.codepage` is the code page of the text, 1200 for a `wstring`.
- With only text, the text is inserted at the caret: the selection is first reduced to its
  start, so nothing selected is replaced.
- With `nPos`, the text is inserted at that position; with `nStart` and `nEnd`, it replaces that
  range.

The forms without a `SETTEXTEX` replace a selection and keep the undo queue, so the edit can be
undone.

**Returns** the number of characters put in when a selection was replaced (3 for "def", 14 for
the RTF below); 1 when all the text was set.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim stex as SETTEXTEX : stex.flags = ST_SELECTION : stex.codepage = CP_ACP
pRichEdit->SetTextEx( stex, "{\rtf1 Some {\b bold} text}" )
```

Microsoft Learn: [EM_SETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-settextex)

### InsertText

```freebasic
function InsertText( byref wszText as wstring ) as DWORD
function InsertText( byval nPos as long, byref wszText as wstring ) as DWORD
```

Inserts text at the caret, or at the position `nPos`, as an edit that can be undone. A selection
is not replaced: the text goes in before it. With "abc" and the caret at 1, inserting "Z" gave
"aZbc" and left the caret at 2.

**Returns** the number of characters inserted.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim wszStamp as wstring * 32 = "Checked ✓ "
pRichEdit->InsertText( 0, wszStamp )
```

Microsoft Learn: [EM_SETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-settextex)

### ReplaceText

```freebasic
function ReplaceText( byval nStart as long, byval nEnd as long, byref wszText as wstring ) as DWORD
```

Replaces the characters from `nStart` up to `nEnd` with the text, as an edit that can be undone,
and leaves the caret after the new text: replacing 1 to 3 of "abcdef" with "XY" left it at 3.

**Returns** the number of characters put in.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim found as CHARRANGE = pRichEdit->FindTextEx( FR_DOWN, 0, -1, "colour" )
if found.cpMin <> -1 then pRichEdit->ReplaceText( found.cpMin, found.cpMax, "color" )
```

Microsoft Learn: [EM_SETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-settextex)

### GetThumb

```freebasic
function GetThumb() as long
```

Returns the position of the scroll box in the vertical scroll bar; 0 when the text is not
scrolled.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "scroll box at"; pRichEdit->GetThumb()
```

Microsoft Learn: [EM_GETTHUMB](https://learn.microsoft.com/en-us/windows/win32/controls/em-getthumb)

### WordBreakProc, GetWordBreakProc, SetWordBreakProc

```freebasic
property WordBreakProc() as LONG_PTR
property WordBreakProc( byval pfn as LONG_PTR )
function GetWordBreakProc() as LONG_PTR
sub SetWordBreakProc( byval pfn as LONG_PTR )
```

Read or replace the procedure the control calls to find word breaks, for double-click selection,
Ctrl+arrow moves and wrapping. Pass the address of an `EDITWORDBREAKPROC` function; reading gives
0 while the control uses its own rules.

**Example**

```freebasic
' a word ends only at a space
function SpaceBreak( byval lpch as WCHAR ptr, byval ichCurrent as long, byval cch as long, byval code as long ) as long
    dim i as long = ichCurrent
    select case code
        case WB_ISDELIMITER : return iif( lpch[i] = 32, 1, 0 )
        case WB_LEFT : do while i > 0 andalso lpch[i - 1] <> 32 : i -= 1 : loop
        case else : do while i < cch andalso lpch[i] <> 32 : i += 1 : loop
    end select
    return i
end function

dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetWordBreakProc( cast( LONG_PTR, @SpaceBreak ) )
```

Microsoft Learn: [EM_SETWORDBREAKPROC](https://learn.microsoft.com/en-us/windows/win32/controls/em-setwordbreakproc), [EM_GETWORDBREAKPROC](https://learn.microsoft.com/en-us/windows/win32/controls/em-getwordbreakproc)

### WordBreakProcEx, GetWordBreakProcEx, SetWordBreakProcEx

```freebasic
property WordBreakProcEx() as LONG_PTR
property WordBreakProcEx( byval pfn as LONG_PTR )
function GetWordBreakProcEx() as LONG_PTR
function SetWordBreakProcEx( byval pfn as LONG_PTR ) as LONG_PTR
```

Read or replace the extended word-break procedure, an `EDITWORDBREAKPROCEX` that also receives
the character set of the text. Reading gives 0 when none is set.

**Returns** `SetWordBreakProcEx`: the address of the previous procedure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->GetWordBreakProcEx() = 0 then print "the control's own word breaks"
```

Microsoft Learn: [EM_SETWORDBREAKPROCEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-setwordbreakprocex), [EM_GETWORDBREAKPROCEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-getwordbreakprocex)

### HideSelection

```freebasic
sub HideSelection( byval fHide as DWORD )
```

Hides the selection highlight (`fHide` nonzero) or shows it again (0). The selection itself
does not change.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->HideSelection( true )
```

Microsoft Learn: [EM_HIDESELECTION](https://learn.microsoft.com/en-us/windows/win32/controls/em-hideselection)

### GetIMECompText

```freebasic
function GetIMECompText( byref ict as .IMECOMPTEXT, byval buffer as any ptr ) as DWORD
```

Copies the IME composition text into `buffer`. Set `ict.cb` to the size of the buffer in bytes
and `ict.flags` to `ICT_RESULTREADSTR`.

**Returns** the number of characters copied.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim wszComp as wstring * 256
dim ict as IMECOMPTEXT : ict.cb = sizeof( wszComp ) : ict.flags = ICT_RESULTREADSTR
pRichEdit->GetIMECompText( ict, @wszComp )
```

Microsoft Learn: [EM_GETIMECOMPTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimecomptext)

### InsertImage

```freebasic
function InsertImage( byref ip as RICHEDIT_IMAGE_PARAMETERS ) as DWORD
function InsertImage( byref wszFileName as wstring, byval xWidth as long = 0, byval yHeight as long = 0, byval Ascent as long = 0, byval nType as long = TA_BASELINE, byref wszAlternateText as wstring = "" ) as boolean
```

Replaces the selection with an image, which then counts as one character. The first form takes a
`RICHEDIT_IMAGE_PARAMETERS` you filled, with an `IStream` on the image and sizes in HiMetric.
The second opens the file `wszFileName` (PNG, JPEG, GIF, BMP …) and fills the structure for you.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The image file. |
| `xWidth`, `yHeight` | The size in pixels. When both are 0 the image's own size is read from the file; when only one is 0 it stays 0. Both are multiplied by the control's `ScalingRatio`. |
| `Ascent` | For `TA_BASELINE`, how far the image rises above the baseline, in pixels. |
| `nType` | Where the image sits on the line: `TA_BASELINE`, `TA_BOTTOM` or `TA_TOP`. |
| `wszAlternateText` | Text that stands for the image, for screen readers. |

**Returns** first form: an `HRESULT`, `S_OK` on success. Second form: `true` on success; on
failure `false`, and `GetLastResult()` holds the `HRESULT`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->CaretPos = -1
if pRichEdit->InsertImage( "logo.png", 0, 0, 0, TA_BASELINE, "Company logo" ) = false then print "no image"
```

Microsoft Learn: [EM_INSERTIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/em-insertimage), [SHCreateStreamOnFileEx](https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-shcreatestreamonfileex)

### InsertTable

```freebasic
function InsertTable( byref tp as TABLEROWPARMS, byref tcp as TABLECELLPARMS ) as DWORD
```

Inserts `tp.cRow` identical rows of `tp.cCell` empty cells. Set `tp.cbRow` and `tp.cbCell` to the
structure sizes and `tp.cpStartRow` to `-1` to insert at the selection; with `tp.fIdentCells` set
to 1, `tcp` describes every cell, otherwise it is the first of `tp.cCell` cells. Widths are in
twips.

**Returns** an `HRESULT`: `S_OK` (0) on success, `E_INVALIDARG` when the structures do not add up.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim tp as TABLEROWPARMS : tp.cbRow = sizeof( TABLEROWPARMS ) : tp.cbCell = sizeof( TABLECELLPARMS )
tp.cRow = 2 : tp.cCell = 3 : tp.dxCellMargin = 100 : tp.cpStartRow = -1 : tp.fIdentCells = 1
dim tcp as TABLECELLPARMS : tcp.dxWidth = 1440      ' one inch
pRichEdit->InsertTable( tp, tcp )
```

Microsoft Learn: [EM_INSERTTABLE](https://learn.microsoft.com/en-us/windows/win32/controls/em-inserttable)

### IsIME

```freebasic
function IsIME() as long
```

Says whether the current input locale is an East Asian one, that uses an IME.

**Returns** nonzero for an East Asian locale.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->IsIME() then print "East Asian input locale"
```

Microsoft Learn: [EM_ISIME](https://learn.microsoft.com/en-us/windows/win32/controls/em-isime)

### GetLineCount

```freebasic
function GetLineCount() as long
```

Returns the number of lines, as the control shows them; an empty control has one.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print pRichEdit->GetLineCount(); " lines"
```

Microsoft Learn: [EM_GETLINECOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getlinecount)

### LineFromChar

```freebasic
function LineFromChar( byval index as DWORD ) as long
```

Returns the line that holds the character at `index`; `-1` gives the line of the caret. The same
as [ExLineFromChar](#exlinefromchar).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "line"; pRichEdit->LineFromChar( pRichEdit->GetCaretPos() ) + 1
```

Microsoft Learn: [EM_LINEFROMCHAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-linefromchar)

### LineIndex

```freebasic
function LineIndex( byval nLine as long ) as long
```

Returns the position of the first character of line `nLine`; `-1` gives the start of the
caret's line. Subtract it from a position to get the column.

**Returns** the position, or `-1` when there is no such line.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim nPos as long = pRichEdit->GetCaretPos()
print "column"; nPos - pRichEdit->LineIndex( -1 ) + 1
```

Microsoft Learn: [EM_LINEINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-lineindex)

### LineLength

```freebasic
function LineLength( byval index as DWORD ) as long
```

Returns the length of the line that holds the character at `index` (a position, not a line
number), without its paragraph break.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "line 2 is"; pRichEdit->LineLength( pRichEdit->LineIndex( 1 ) ); " characters long"
```

Microsoft Learn: [EM_LINELENGTH](https://learn.microsoft.com/en-us/windows/win32/controls/em-linelength)

### LineScroll

```freebasic
function LineScroll( byval y as long ) as long
```

Scrolls the text `y` lines, down for a positive number and up for a negative one.

**Returns** nonzero on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->LineScroll( 10 )
```

Microsoft Learn: [EM_LINESCROLL](https://learn.microsoft.com/en-us/windows/win32/controls/em-linescroll)

### PasteSpecial

```freebasic
sub PasteSpecial( byval clpfmt as DWORD, byref rps as REPASTESPECIAL )
sub PasteSpecial( byval clpfmt as DWORD, byval dwAspect as DWORD, byval hMF as HMETAFILE )
```

Pastes the clipboard in the format `clpfmt` only, such as `CF_UNICODETEXT` to paste plain text.
`rps`, or `dwAspect` and `hMF`, say how an object is shown: `DVASPECT_CONTENT` for its content,
`DVASPECT_ICON` for an icon, with the metafile `hMF` as the picture.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->PasteSpecial( CF_UNICODETEXT, DVASPECT_CONTENT, NULL )     ' paste without formatting
```

Microsoft Learn: [EM_PASTESPECIAL](https://learn.microsoft.com/en-us/windows/win32/controls/em-pastespecial)

### PosFromChar

```freebasic
function PosFromChar( byval index as DWORD ) as .POINTL
```

Returns the client coordinates of the top-left corner of the character at `index`. The reverse
of [CharFromPos](#charfrompos-getcharfrompos).

**Returns** the point.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pt as POINTL = pRichEdit->PosFromChar( pRichEdit->GetCaretPos() )
print "the caret is at"; pt.x; ","; pt.y
```

Microsoft Learn: [EM_POSFROMCHAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-posfromchar)

### Reconversion

```freebasic
sub Reconversion()
```

Opens the IME reconversion window for the selected text, on an East Asian input locale.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->IsIME() then pRichEdit->Reconversion()
```

Microsoft Learn: [EM_RECONVERSION](https://learn.microsoft.com/en-us/windows/win32/controls/em-reconversion)

### ReplaceSel

```freebasic
sub ReplaceSel( byval bCanBeUndone as long = true, byref wszText as wstring )
```

Replaces the selection with `wszText`, or inserts it at the caret when nothing is selected, and
leaves the caret after it. With `bCanBeUndone` nonzero the edit goes into the undo queue. Both
arguments are needed, since the default comes first.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->ReplaceSel( true, "replacement" )
```

Microsoft Learn: [EM_REPLACESEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-replacesel)

### RequestResize

```freebasic
sub RequestResize()
```

Makes the control send its parent an `EN_REQUESTRESIZE` notification with the size its contents
need. The notification comes only when `ENM_REQUESTRESIZE` is in the event mask.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetEventMask( pRichEdit->GetEventMask() or ENM_REQUESTRESIZE )
pRichEdit->RequestResize()
```

Microsoft Learn: [EM_REQUESTRESIZE](https://learn.microsoft.com/en-us/windows/win32/controls/em-requestresize)

### Scroll

```freebasic
function Scroll( byval nAction as long ) as long
```

Scrolls the text vertically, as the scroll bar does: `nAction` is `SB_LINEUP`, `SB_LINEDOWN`,
`SB_PAGEUP` or `SB_PAGEDOWN`.

**Returns** on success, `true` in the high word and the number of lines scrolled in the low word.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "scrolled"; LOWORD( pRichEdit->Scroll( SB_PAGEDOWN ) ); " lines"
```

Microsoft Learn: [EM_SCROLL](https://learn.microsoft.com/en-us/windows/win32/controls/em-scroll)

### ScrollCaret

```freebasic
sub ScrollCaret()
```

Scrolls the text so that the caret is visible. Selecting text from code does not scroll; call
this afterwards.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->ExSetSel( 5000, 5010 )
pRichEdit->ScrollCaret()
```

Microsoft Learn: [EM_SCROLLCARET](https://learn.microsoft.com/en-us/windows/win32/controls/em-scrollcaret)

### SelectionType

```freebasic
function SelectionType() as long
```

Says what the selection holds: `SEL_EMPTY` (0) when nothing is selected, otherwise a combination
of `SEL_TEXT` (1), `SEL_OBJECT` (2), `SEL_MULTICHAR` (4) and `SEL_MULTIOBJECT` (8). One selected
character gave 1, three gave 5, an image gave 2.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->SelectionType() and SEL_OBJECT then print "an object is selected"
```

Microsoft Learn: [EM_SELECTIONTYPE](https://learn.microsoft.com/en-us/windows/win32/controls/em-selectiontype)

### SetBkgndColor

```freebasic
function SetBkgndColor( byval pSysColor as DWORD, byval pBkColor as DWORD ) as DWORD
```

Sets the background colour. With `pSysColor` nonzero the control uses the system window colour
and `pBkColor` is ignored; with 0 it uses `pBkColor`, a `COLORREF`.

**Returns** the previous background colour (`&hFFFFFF`, white, for a new control).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetBkgndColor( 0, BGR( 255, 255, 224 ) )     ' light yellow
```

Microsoft Learn: [EM_SETBKGNDCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/em-setbkgndcolor)

### SetFontSize

```freebasic
function SetFontSize( byval ptsize as long ) as long
```

Makes the selected text larger or smaller. `ptsize` is a **change**, not a size: positive makes
the text larger, negative smaller, and the control rounds the result to its own steps. Text of
8.25 points became 10 with `+2`, then 22 with `+12`, then 18 with `-4`. To set an exact size use
`SetTextHeight`.

**Returns** nonzero on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetFontSize( 2 )      ' one step larger
```

Microsoft Learn: [EM_SETFONTSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setfontsize)

### Margins, SetMargins

```freebasic
property Margins( byval nMargins as long, byval nWidth as long )
sub SetMargins( byval nMargins as long, byval nWidth as long )
```

Set the left and right margins, in pixels, and redraw the control. `nMargins` says which:
`EC_LEFTMARGIN`, `EC_RIGHTMARGIN` or both. `nWidth` holds the left margin in its low word and the
right margin in its high word. The property is written `Margins( nMargins ) = nWidth`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetMargins( EC_LEFTMARGIN or EC_RIGHTMARGIN, MAKELONG( 8, 8 ) )
```

Microsoft Learn: [EM_SETMARGINS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setmargins)

### LeftMargin, SetLeftMargin

```freebasic
property LeftMargin( byval nWidth as long )
sub SetLeftMargin( byval nWidth as long )
```

Set the left margin to `nWidth` pixels; the right margin stays as it is. The value is not scaled
for DPI.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->LeftMargin = 60
```

Microsoft Learn: [EM_SETMARGINS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setmargins)

### RightMargin, SetRightMargin

```freebasic
property RightMargin( byval nWidth as long )
sub SetRightMargin( byval nWidth as long )
```

Set the right margin to `nWidth` pixels; the left margin stays as it is. The value is not scaled
for DPI.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetRightMargin( 60 )
```

Microsoft Learn: [EM_SETMARGINS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setmargins)

### SetOleCallback

```freebasic
function SetOleCallback( byval pCallback as any ptr ) as long
```

Gives the control an `IRichEditOleCallback` object, which it asks for storage and menus when
objects and images are pasted, dropped or inserted. [CRichEditOleCallback](CRichEditOleCallback)
is a ready-made one. Create it with `new`: the control releases it when it is destroyed, and
its last `Release` deletes it.

**Returns** nonzero on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetOleCallback( new CRichEditOleCallback )   ' the control releases it
```

Microsoft Learn: [EM_SETOLECALLBACK](https://learn.microsoft.com/en-us/windows/win32/controls/em-setolecallback)

### SetPalette

```freebasic
sub SetPalette( byval newPalette as HPALETTE )
```

Sets the palette the control draws with, on a display limited to 256 colours.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetPalette( cast( HPALETTE, GetStockObject( DEFAULT_PALETTE ) ) )
```

Microsoft Learn: [EM_SETPALETTE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setpalette)

### SetReadOnly

```freebasic
function SetReadOnly( byval fReadOnly as long ) as boolean
```

Makes the control read-only (`fReadOnly` nonzero), so the user can select and copy but not
change the text, or editable again (0). The program can still change it: `SetText` and
[InsertText](#inserttext) worked on a read-only control.

**Returns** `true` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetReadOnly( true )
```

Microsoft Learn: [EM_SETREADONLY](https://learn.microsoft.com/en-us/windows/win32/controls/em-setreadonly)

### SetTabStops

```freebasic
function SetTabStops( byval nTabs as long, byval rgTabStops as LONG_PTR ) as long
```

Sets the tab stops of the control. `rgTabStops` is the address of an array of `nTabs` `long`
values, in dialog template units; with one value the stops repeat at that distance, and with
`nTabs` 0 they fall back to every 32 units.

**Returns** nonzero when all the tab stops were set.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim tabs(0 to 1) as long = { 40, 120 }
pRichEdit->SetTabStops( 2, cast( LONG_PTR, @tabs(0) ) )
```

Microsoft Learn: [EM_SETTABSTOPS](https://learn.microsoft.com/en-us/windows/win32/controls/em-settabstops)

### SetTargetDevice

```freebasic
function SetTargetDevice( byval hDC as HDC, byval lnwidth as long ) as boolean
```

Sets the device the text is laid out for, and the line width. With a device context, lines are
`lnwidth` twips wide on that device, which is how a document is made to wrap as it will print.
With `NULL` the control formats for the screen: `lnwidth` 0 wraps lines at the width of the
control, and 1 does not wrap at all (a 5000-character paragraph stayed one line).

**Returns** `true` on success; `GetLastResult()` is then `S_OK`, and `S_FALSE` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetTargetDevice( NULL, 1 )      ' no word wrap
```

Microsoft Learn: [EM_SETTARGETDEVICE](https://learn.microsoft.com/en-us/windows/win32/controls/em-settargetdevice)

### SetUIAName

```freebasic
function SetUIAName( byref wszName as wstring ) as DWORD
```

Sets the name screen readers and other UI Automation clients report for the control.

**Returns** nonzero on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetUIAName( "Message body" )
```

Microsoft Learn: [EM_SETUIANAME](https://learn.microsoft.com/en-us/windows/win32/controls/em-setuianame)

### SetUndoLimit

```freebasic
function SetUndoLimit( byval maxactions as DWORD ) as DWORD
```

Sets how many actions the undo queue holds; the default is 100. `0` turns undo off.

**Returns** the new limit (50 for `SetUndoLimit( 50 )`).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetUndoLimit( 500 )
```

Microsoft Learn: [EM_SETUNDOLIMIT](https://learn.microsoft.com/en-us/windows/win32/controls/em-setundolimit)

### ShowScrollBar

```freebasic
sub ShowScrollBar( byval nScrollBar as DWORD, byval fShow as long )
```

Shows (`fShow` nonzero) or hides (0) one scroll bar: `nScrollBar` is `SB_VERT` or `SB_HORZ`.
The control must have been created with that scroll bar.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->ShowScrollBar( SB_HORZ, false )
```

Microsoft Learn: [EM_SHOWSCROLLBAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-showscrollbar)

### StopGroupTyping

```freebasic
function StopGroupTyping() as DWORD
```

Closes the undo action that is collecting the user's typing, so the next keystrokes start a new
one and one undo does not take back more than you want.

**Returns** 0.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->StopGroupTyping()     ' e.g. after each word, or on a timer
```

Microsoft Learn: [EM_STOPGROUPTYPING](https://learn.microsoft.com/en-us/windows/win32/controls/em-stopgrouptyping)

### StreamIn

```freebasic
function StreamIn( byval psf as long, byref edst as EDITSTREAM ) as DWORD
```

Replaces the text, or with `SFF_SELECTION` the selection, with data the control asks for in
pieces from the callback `edst.pfnCallback`. `psf` is `SF_TEXT` or `SF_RTF`, optionally with
`SF_UNICODE` or `SFF_SELECTION`. The callback copies up to `cb` bytes to `pbBuff`, stores how
many in `*pcb` (0 at the end) and returns 0 to go on.

**Returns** the number of characters read in (10 for `{\rtf1 hello {\b bold}\par}`).

**Example**

```freebasic
dim shared as string gRtf
dim shared as long gRead

function ReadRtf( byval dwCookie as DWORD_PTR, byval pbBuff as BYTE ptr, byval cb as long, byval pcb as long ptr ) as DWORD
    dim n as long = len( gRtf ) - gRead
    if n > cb then n = cb
    if n > 0 then memcpy( pbBuff, strptr( gRtf ) + gRead, n )
    gRead += n : *pcb = n
    return 0
end function

gRtf = "{\rtf1 Hello {\b bold} world\par}" : gRead = 0
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim es as EDITSTREAM : es.pfnCallback = @ReadRtf
pRichEdit->StreamIn( SF_RTF, es )
```

Microsoft Learn: [EM_STREAMIN](https://learn.microsoft.com/en-us/windows/win32/controls/em-streamin)

### StreamOut

```freebasic
function StreamOut( byval psf as long, byref edst as EDITSTREAM ) as DWORD
```

Hands the text, or with `SFF_SELECTION` the selection, to the callback `edst.pfnCallback` in
pieces. `psf` is `SF_TEXT`, `SF_RTF` or `SF_RTFNOOBJS`, optionally with `SF_UNICODE`. The
callback receives `cb` bytes at `pbBuff`, stores in `*pcb` how many it took and returns 0 to go
on. Plain text comes out with CR/LF at paragraph breaks.

**Returns** the number of characters written: 33 for 31 characters in three paragraphs as
`SF_TEXT`.

**Example**

```freebasic
dim shared as string gOut

function WriteOut( byval dwCookie as DWORD_PTR, byval pbBuff as BYTE ptr, byval cb as long, byval pcb as long ptr ) as DWORD
    dim s as string = space( cb )
    memcpy( strptr( s ), pbBuff, cb )
    gOut &= s : *pcb = cb
    return 0
end function

dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim es as EDITSTREAM : es.pfnCallback = @WriteOut
pRichEdit->StreamOut( SF_RTF, es )
print left( gOut, 6 )      ' {\rtf1
```

Microsoft Learn: [EM_STREAMOUT](https://learn.microsoft.com/en-us/windows/win32/controls/em-streamout)

### TextLengthEx, GetTextLengthEx

```freebasic
function TextLengthEx( byref gtex as .GETTEXTLENGTHEX ) as long
function TextLengthEx( byval dwFlags as DWORD = GTL_DEFAULT ) as long
function GetTextLengthEx( byref gtex as .GETTEXTLENGTHEX ) as long
function GetTextLengthEx( byval dwFlags as DWORD = GTL_DEFAULT ) as long
```

Return the length of the text, counted as the flags say: `GTL_USECRLF` counts each paragraph
break as two characters, `GTL_PRECISE` asks for an exact count, `GTL_NUMCHARS` for characters and
`GTL_NUMBYTES` for bytes. The `dwFlags` forms use the code page 1200 (UTF-16); the others take a
`GETTEXTLENGTHEX` you filled.

For "one two three", "second line" and "third" in three paragraphs: `GTL_DEFAULT` gives 31 and
`GTL_NUMCHARS or GTL_USECRLF` gives 33. Without `GTL_NUMCHARS` other flags can give bytes:
`GTL_USECRLF` alone gave 66.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print pRichEdit->TextLengthEx( GTL_NUMCHARS or GTL_USECRLF ); " characters with CR/LF"
```

Microsoft Learn: [EM_GETTEXTLENGTHEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextlengthex)

### GetTextRange

```freebasic
function GetTextRange( byref trg as .TEXTRANGEW ) as DWORD
function GetTextRange( byval cpMin as long = 0, byval cpMax as long = -1 ) as ustring
```

Returns the characters from `cpMin` up to `cpMax`, with a carriage return at each paragraph
break. `(0, -1)`, the default, returns the whole text. A `cpMax` of `-1` works only with a
`cpMin` of 0: any other start with `-1` returns `""` and sets `GetLastResult()` to
`E_INVALIDARG`. Equal positions return `""`. The first form fills a `TEXTRANGEW` whose
`lpstrText` you pointed at a buffer large enough.

**Returns** the text (second form); the number of characters copied (first form).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "characters 4 to 6: "; pRichEdit->GetTextRange( 4, 7 )
print "from 10 to the end: "; pRichEdit->GetTextRange( 10, pRichEdit->TextLengthEx() )
```

Microsoft Learn: [EM_GETTEXTRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextrange)

### Redo

```freebasic
function Redo() as long
function Redo( byval Count as long ) as long
```

Redoes the next action in the redo queue, or up to `Count` actions. The second form goes through
the control's Text Object Model document.

**Returns** first form: nonzero on success. Second form: the number of actions redone (2 when 5
were asked for and 2 were queued); `GetLastResult()` holds the `HRESULT`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "redid"; pRichEdit->Redo( 3 ); " actions"
```

Microsoft Learn: [EM_REDO](https://learn.microsoft.com/en-us/windows/win32/controls/em-redo), [ITextDocument::Redo](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-redo)

### Undo

```freebasic
function Undo() as long
function Undo( byval Count as long ) as long
```

Undoes the last action in the undo queue, or up to `Count` actions; what was undone moves to the
redo queue. The second form goes through the control's Text Object Model document.

**Returns** first form: nonzero on success. Second form: the number of actions undone;
`GetLastResult()` holds the `HRESULT`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->CanUndo() then pRichEdit->Undo( 2 )
```

Microsoft Learn: [EM_UNDO](https://learn.microsoft.com/en-us/windows/win32/controls/em-undo), [ITextDocument::Undo](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-undo)

### SuspendUndo

```freebasic
function SuspendUndo() as long
```

Turns undo off, with `tomFalse`, so that the edits that follow are not recorded. It also
**empties** the undo queue: after `SuspendUndo` and [ResumeUndo](#resumeundo),
[CanUndo](#canundo) is `false` even though there were actions to undo before.

**Returns** 0; `GetLastResult()` holds the `HRESULT`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SuspendUndo()
pRichEdit->InsertText( 0, "Generated header" & chr(13) )
pRichEdit->ResumeUndo()
```

Microsoft Learn: [ITextDocument::Undo](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-undo)

### ResumeUndo

```freebasic
function ResumeUndo() as long
```

Turns undo back on, with `tomTrue`, after [SuspendUndo](#suspendundo). The edits that follow go
into the undo queue again.

**Returns** 0; `GetLastResult()` holds the `HRESULT`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->ResumeUndo()
```

Microsoft Learn: [ITextDocument::Undo](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-undo)

### EnableWordWrap

```freebasic
function EnableWordWrap() as boolean
```

Makes lines wrap at the width of the control. A control made by [CRichEditCtx](CRichEditCtx)
with the default styles has a horizontal scroll bar and does not wrap until this is called.

**Returns** `true` on success; on failure `false`, and `GetLastResult()` is `S_FALSE`, or
`E_FAIL` when no device context could be had.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->EnableWordWrap()
```

Microsoft Learn: [EM_SETTARGETDEVICE](https://learn.microsoft.com/en-us/windows/win32/controls/em-settargetdevice)

### DisableWordWrap

```freebasic
function DisableWordWrap( byval LineWidth as long = -1 ) as boolean
```
Disables wrapping. If you specify a positive value, formats lines for a fixed width of `LineWidth` twips on the screen, instead of the width of the control.

**Returns** `true` on success; on failure `false`, and `GetLastResult()` is `S_FALSE`, or
`E_FAIL` when no device context could be had.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->DisableWordWrap()
```

Microsoft Learn: [EM_SETTARGETDEVICE](https://learn.microsoft.com/en-us/windows/win32/controls/em-settargetdevice)

## See also

- [CRichEditCtx](CRichEditCtx) for creating the control and its properties
- [CRichEditCtx: documents and formatting](CRichEditCtx-Document) for fonts, files and the Text Object Model wrappers
- [RichEdit](SysWin-RichEdit-Control) for the same messages as functions on a control handle
- [CRichEditOleCallback](CRichEditOleCallback) for embedded objects and images
- [Text Object Model](SysWin-RichEdit-TOM)
- [sys/win/richedit](SysWin-RichEdit)
