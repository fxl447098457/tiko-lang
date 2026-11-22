[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/richedit](SysWin-RichEdit) › **RichEd**

# RichEd

Sends rich edit messages to a control by its handle: text, selection, formatting and RTF.

The `RichEd` namespace holds one function per rich edit message, plus a few helpers that load
RTF and set the font. Each takes the control's handle first, sends the message with
`SendMessageW` and returns what the control returns, so they work on any rich edit control: one
made with `CWindow.AddControl( "RichEdit", ... )` (which loads `Msftedit.dll` and creates a
`RichEdit50W` control), the `hRichEdit` of a [CRichEditCtx](CRichEditCtx), or a rich edit control
in a dialog. `CRichEditCtx` wraps most of the same messages as members; use these functions when
all you have is a handle.

**Character positions** count characters from 0 at the start of the text. A range runs from its
start to just before its end, and an end of -1 means the end of the text, so `SetSel( hCtrl, 0,
-1 )` selects everything. The control keeps each paragraph end as one carriage return (13): the
positions count it as one character, while [GetText](#gettext) and
[GetTextLength](#gettextlength) report it as `CR LF`. Lines are lines as displayed; with word
wrap on, one paragraph can take several.

**Structures.** Many functions take a pointer to a Windows structure (`CHARRANGE`,
`CHARFORMATW`, `PARAFORMAT`, `FINDTEXTEXW` …). Set its `cbSize` first where it has one. The
`CHARFORMAT2W` and `PARAFORMAT2` forms are accepted with a cast. Three parameter types are written
`..FORMATRANGE`, `..GETTEXTEX` and `..GETTEXTLENGTHEX`: the leading `..` names the Windows
structure, not the namespace function of the same name; in your own code write `FORMATRANGE`.

**Notifications.** A rich edit control sends its parent only the notifications named in its event
mask ([SetEventMask](#geteventmask-seteventmask)): `ENM_CHANGE` for `EN_CHANGE`, `ENM_SELCHANGE`
for `EN_SELCHANGE`, and so on. A new control has an empty mask.

Text parameters are `wstring ptr` or `byref wstring`: pass a literal, a `ustring` or a `wstring`.
Functions that return text return a `ustring`. Nothing here allocates anything you must free,
except the interface [GetOleInterface](#getoleinterface) returns.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/richedit"
using win, richedit
```

## Example

A rich edit control that fills the window, filled from RTF. The caption follows the caret: line,
column and the selected text, from the control's `EN_SELCHANGE` notification.

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/richedit"
using win, gui, richedit

const IDC_RICHEDIT = 101

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "RichEditFunctions"
    dim hWin as HWND = pWindow.Create( NULL, "RichEdit", @WndProc )
    pWindow.SetClientSize( 480, 260 )
    pWindow.Center()
    dim hRich as HWND = pWindow.AddControl( "RichEdit", hWin, IDC_RICHEDIT, "", 0, 0, 480, 260 )
    pWindow.AnchorControl( IDC_RICHEDIT, ANCHOR_HEIGHT_WIDTH )
    richedit.RichEdit.SetFont( hRich, "Segoe UI", 11 )
    dim stx as SETTEXTEX
    stx.flags = ST_DEFAULT : stx.codepage = CP_ACP
    dim rtf as string = "{\rtf1\ansi Move the caret: the caption shows the {\b line}, the {\b column} and the {\i selection}.\par A second paragraph.}"
    richedit.RichEdit.SetTextExW( hRich, @stx, cast( wstring ptr, strptr( rtf ) ) )
    richedit.RichEdit.SetEventMask( hRich, ENM_SELCHANGE )
    richedit.RichEdit.SetModify( hRich, 0 )
    SetFocus( hRich )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_NOTIFY
            dim pnm as NMHDR ptr = cast( NMHDR ptr, lParam )
            if pnm->idFrom = IDC_RICHEDIT andalso pnm->code = EN_SELCHANGE then
                dim psc as SELCHANGE ptr = cast( SELCHANGE ptr, lParam )
                dim hRich as HWND = pnm->hwndFrom
                dim nLine as long = richedit.RichEdit.ExLineFromChar( hRich, psc->chrg.cpMin )
                dim nCol as long = psc->chrg.cpMin - richedit.RichEdit.LineIndex( hRich, nLine )
                SetWindowText( hwnd, "line " & nLine + 1 & ", column " & nCol + 1 & _
                                     ", selected [" & richedit.RichEdit.GetSelText( hRich ) & "]" )
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

## Functions

**Text**

| Function | Does |
| --- | --- |
| [GetText](#gettext) | Returns the control's text. |
| [GetTextLength](#gettextlength) | Returns the length of the text, paragraph ends counted as two. |
| [SetText](#settext) | Replaces the text. |
| [GetTextEx](#gettextex) | Copies the text into a buffer, in a code page of your choice. |
| [GetTextLengthEx](#gettextlengthex) | Measures the text in several ways. |
| [SetTextExW](#settextexw) | Sets the text or the selection from plain text or RTF. |
| [GetTextRange](#gettextrange) | Copies a range of characters into a buffer. |
| [GetLine](#getline) | Returns one line. |
| [GetLineCount](#getlinecount) | Returns the number of lines. |
| [LineIndex](#lineindex) | Returns the position at which a line starts. |
| [LineFromChar](#linefromchar) | Returns the line that holds a character. |
| [ExLineFromChar](#exlinefromchar) | Returns the line that holds a character, for any position. |
| [LineLength](#linelength) | Returns the length of the line that holds a character. |
| [GetLimitText, LimitText, SetLimitText](#getlimittext-limittext-setlimittext) | Reads or sets how much text the user can enter. |
| [ExLimitText](#exlimittext) | Sets how much text the user can enter, above 64K. |
| [GetTextMode, SetTextMode](#gettextmode-settextmode) | Reads or sets rich or plain text and the undo levels. |
| [GetModify, SetModify](#getmodify-setmodify) | Reads or sets the changed flag. |

**Selection**

| Function | Does |
| --- | --- |
| [GetSel](#getsel) | Reads the selection. |
| [SetSel](#setsel) | Selects a range of characters. |
| [ExGetSel](#exgetsel) | Reads the selection into a `CHARRANGE`. |
| [ExSetSel](#exsetsel) | Selects the range a `CHARRANGE` holds. |
| [GetSelText](#getseltext) | Returns the selected text. |
| [ReplaceSel](#replacesel) | Replaces the selection with text. |
| [SelectionType](#selectiontype) | Tells what the selection holds. |
| [HideSelection](#hideselection) | Hides or shows the selection. |
| [FindText](#findtext) | Finds text. |
| [FindTextEx](#findtextex) | Finds text and returns the range found. |
| [FindWordBreak](#findwordbreak) | Finds the next word break, or classifies a character. |
| [CharFromPos](#charfrompos) | Returns the character nearest a point. |
| [PosFromChar](#posfromchar) | Returns where a character is drawn. |

**Formatting**

| Function | Does |
| --- | --- |
| [GetCharFormat](#getcharformat) | Reads character formatting. |
| [SetCharFormat](#setcharformat) | Sets character formatting. |
| [SetFont](#setfont) | Sets the font face and size of all the text. |
| [SetFontSize](#setfontsize) | Makes the selected text larger or smaller. |
| [GetParaFormat, SetParaFormat](#getparaformat-setparaformat) | Reads or sets paragraph formatting. |
| [SetBkgndColor](#setbkgndcolor) | Sets the background colour. |
| [InsertTable](#inserttable) | Inserts table rows. |
| [GetTableParams, SetTableParams](#gettableparams-settableparams) | Reads or changes table rows and cells. |
| [InsertImage](#insertimage) | Replaces the selection with an image. |
| [SetTabStops](#settabstops) | Sets tab stops. |
| [GetBidiOptions, SetBidiOptions](#getbidioptions-setbidioptions) | Reads or sets bidirectional options. |
| [GetHyphenateInfo, SetHyphenateInfo](#gethyphenateinfo-sethyphenateinfo) | Reads or sets hyphenation. |

**Editing and undo**

| Function | Does |
| --- | --- |
| [CanUndo](#canundo) | Tells whether there is something to undo. |
| [Undo](#undo) | Undoes the last action. |
| [CanRedo](#canredo) | Tells whether there is something to redo. |
| [Redo](#redo) | Redoes the next action. |
| [GetUndoName](#getundoname) | Tells what kind of action the next undo is. |
| [GetRedoName](#getredoname) | Tells what kind of action the next redo is. |
| [EmptyUndoBuffer](#emptyundobuffer) | Forgets what could be undone. |
| [SetUndoLimit](#setundolimit) | Sets how many actions can be undone. |
| [StopGroupTyping](#stopgrouptyping) | Starts a new undo action for the next typing. |
| [CanPaste](#canpaste) | Tells whether a clipboard format can be pasted. |
| [PasteSpecial](#pastespecial) | Pastes a given clipboard format. |
| [SetReadOnly](#setreadonly) | Makes the control read-only or editable. |
| [GetPasswordChar, SetPasswordChar](#getpasswordchar-setpasswordchar) | Reads or sets the character shown in place of what is typed. |

**Options and styles**

| Function | Does |
| --- | --- |
| [GetEventMask, SetEventMask](#geteventmask-seteventmask) | Reads or sets which notifications the control sends. |
| [GetOptions, SetOptions](#getoptions-setoptions) | Reads or sets the `ECO_*` options. |
| [GetEditStyle, SetEditStyle](#geteditstyle-seteditstyle) | Reads or sets the `SES_*` edit styles. |
| [GetEditStyleEx, SetEditStyleEx](#geteditstyleex-seteditstyleex) | Reads or sets the `SES_EX_*` edit styles. |
| [GetTypographyOptions, SetTypographyOptions](#gettypographyoptions-settypographyoptions) | Reads or sets advanced typography. |
| [AutoUrlDetect, GetAutoUrlDetect](#autourldetect-getautourldetect) | Turns URL detection on or off, or reads it. |
| [GetEllipsisMode, SetEllipsisMode](#getellipsismode-setellipsismode) | Reads or sets how text that does not fit is cut. |
| [GetEllipsisState](#getellipsisstate) | Tells whether an ellipsis is showing. |
| [GetTouchOptions, SetTouchOptions](#gettouchoptions-settouchoptions) | Reads or sets the touch options. |
| [GetWordWrapMode, SetWordWrapMode](#getwordwrapmode-setwordwrapmode) | Reads or sets the word wrap and word break options. |
| [GetWordBreakProc, SetWordBreakProc](#getwordbreakproc-setwordbreakproc) | Reads or replaces the word-break procedure. |
| [GetWordBreakProcEx, SetWordBreakProcEx](#getwordbreakprocex-setwordbreakprocex) | Reads or replaces the extended word-break procedure. |
| [GetAutoCorrectProc, SetAutoCorrectProc](#getautocorrectproc-setautocorrectproc) | Reads or sets the autocorrect procedure. |
| [CallAutocorrectProc](#callautocorrectproc) | Runs the autocorrect procedure. |
| [GetPunctuation, SetPunctuation](#getpunctuation-setpunctuation) | Reads or sets the punctuation characters for Asian text. |
| [GetPageRotate, SetPageRotate](#getpagerotate-setpagerotate) | Reads or sets the text layout. |
| [GetStoryType, SetStoryType](#getstorytype-setstorytype) | Reads or sets a story's type. |
| [SetUIAName](#setuianame) | Sets the name UI Automation reports. |
| [SetPalette](#setpalette) | Sets the palette the control draws with. |
| [SetOleCallback](#setolecallback) | Gives the control an `IRichEditOleCallback` object. |
| [GetOleInterface](#getoleinterface) | Returns the control's `IRichEditOle` interface. |

**View and scrolling**

| Function | Does |
| --- | --- |
| [GetZoom, SetZoom](#getzoom-setzoom) | Reads or sets the zoom ratio. |
| [GetFirstVisibleLine](#getfirstvisibleline) | Returns the top visible line. |
| [GetScrollPos, SetScrollPos](#getscrollpos-setscrollpos) | Reads or sets the scroll position in pixels. |
| [LineScroll](#linescroll) | Scrolls by lines. |
| [Scroll](#scroll) | Scrolls by a line or a page. |
| [ScrollCaret](#scrollcaret) | Scrolls the caret into view. |
| [GetThumb](#getthumb) | Returns the vertical scroll box position. |
| [ShowScrollBar](#showscrollbar) | Shows or hides a scroll bar. |
| [GetRect, SetRect, SetRectNP](#getrect-setrect-setrectnp) | Reads or sets the formatting rectangle. |
| [SetMargins](#setmargins) | Sets the left and right margins. |
| [SetTargetDevice](#settargetdevice) | Sets the line width or the device text is laid out for. |
| [RequestResize](#requestresize) | Asks the control for an `EN_REQUESTRESIZE` notification. |

**Streams, files and printing**

| Function | Does |
| --- | --- |
| [StreamIn](#streamin) | Replaces the contents with data from a callback. |
| [StreamOut](#streamout) | Hands the contents to a callback. |
| [LoadRtfFromFile](#loadrtffromfile) | Loads an RTF file. |
| [LoadRtfFromResource](#loadrtffromresource) | Loads RTF from a resource. |
| [LoadRtfFromFileCallback](#loadrtffromfilecallback) | The stream callback `LoadRtfFromFile` uses. |
| [LoadRtfFromResourceCallback](#loadrtffromresourcecallback) | The stream callback `LoadRtfFromResource` uses. |
| [EnumFontFamProcW](#enumfontfamprocw) | The font enumeration callback `SetFont` uses. |
| [FormatRange](#formatrange) | Formats, and draws, text for a device. |
| [DisplayBand](#displayband) | Draws text formatted by `FormatRange`. |

**Input method editors**

| Function | Does |
| --- | --- |
| [IsIME](#isime) | Tells whether the input locale is East Asian. |
| [GetIMECompMode](#getimecompmode) | Returns the IME composition mode. |
| [GetIMECompText](#getimecomptext) | Copies the IME composition text. |
| [GetIMEColor, SetIMEColor](#getimecolor-setimecolor) | Reads or sets the composition colours. |
| [GetIMEModeBias, SetIMEModeBias](#getimemodebias-setimemodebias) | Reads or sets the IME mode bias. |
| [GetIMEOptions, SetIMEOptions](#getimeoptions-setimeoptions) | Reads or sets the IME options. |
| [GetIMEProperty](#getimeproperty) | Returns a property of the IME. |
| [GetLangOptions, SetLangOptions](#getlangoptions-setlangoptions) | Reads or sets the IME and Asian language options. |
| [GetCTFModeBias, SetCTFModeBias](#getctfmodebias-setctfmodebias) | Reads or sets the Text Services Framework mode bias. |
| [GetCTFOpenStatus, SetCTFOpenStatus](#getctfopenstatus-setctfopenstatus) | Reads, opens or closes the Text Services Framework keyboard. |
| [Reconversion](#reconversion) | Opens the IME reconversion dialog. |

**Types**

| Type | Holds |
| --- | --- |
| [RICHEDIT_CUSTOMDATA](#richedit_customdata) | A block of RTF in memory, for `LoadRtfFromResourceCallback`. |

## Reference

### GetText

```freebasic
function GetText( byval hRichEdit as HWND ) as ustring
```

Returns all the text of the control as plain text, without formatting. Each paragraph end comes
back as `CR LF`: text set as `"ab" & chr(13) & "cd"` reads back as six characters. An empty
control gives `""`.

It sends `WM_GETTEXT` rather than calling `GetWindowText`, so it also reads a control in another
program.

**Returns** the text.

**Example**

```freebasic
dim s as ustring = richedit.RichEdit.GetText( hCtrl )
print len( s ); " characters"
```

Microsoft Learn: [WM_GETTEXT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-gettext)

### GetTextLength

```freebasic
function GetTextLength( byval hRichEdit as HWND ) as long
```

Returns the length of the text as [GetText](#gettext) returns it, each paragraph end counted as
two characters (`CR LF`). For the number of character positions use
[GetTextLengthEx](#gettextlengthex) with `GTL_NUMCHARS`.

**Returns** the length in characters.

**Example**

```freebasic
if richedit.RichEdit.GetTextLength( hCtrl ) = 0 then print "empty"
```

Microsoft Learn: [WM_GETTEXTLENGTH](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-gettextlength)

### SetText

```freebasic
function SetText( byval hRichEdit as HWND, byval pwszText as wstring ptr ) as long
```

Replaces all the text with `pwszText`, as plain text, and empties the undo queue: [CanUndo](#canundo)
returns 0 afterwards. To set RTF, use [SetTextExW](#settextexw) or
[StreamIn](#streamin).

| Parameter | Meaning |
| --- | --- |
| `hRichEdit` | The rich edit control. |
| `pwszText` | The new text: a literal, a `ustring` or a `wstring`. |

**Returns** nonzero on success, 0 on failure.

**Example**

```freebasic
richedit.RichEdit.SetText( hCtrl, "First paragraph" & chr(13) & "Second paragraph" )
```

Microsoft Learn: [WM_SETTEXT](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-settext)

### GetTextEx

```freebasic
function GetTextEx( byval hRichEdit as HWND, byval lpgtex as ..GETTEXTEX ptr, byval buffer as any ptr ) as DWORD
```

Copies the text, or the selection, into `buffer`. `GETTEXTEX` says how: `cb` is the buffer size
in bytes, `flags` picks `GT_DEFAULT`, `GT_USECRLF`, `GT_SELECTION` …, and `codepage` the code
page (1200 for UTF-16). With `GT_DEFAULT` paragraph ends stay single carriage returns.

| Parameter | Meaning |
| --- | --- |
| `lpgtex` | A filled-in `GETTEXTEX`. |
| `buffer` | Receives the text and a terminating null. |

**Returns** the number of characters (or bytes, for a narrow code page) copied.

**Example**

```freebasic
dim gt as GETTEXTEX
dim buf as wstring * 256
gt.cb = sizeof( buf ) : gt.flags = GT_DEFAULT : gt.codepage = 1200
richedit.RichEdit.GetTextEx( hCtrl, @gt, @buf )
```

Microsoft Learn: [EM_GETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextex)

### GetTextLengthEx

```freebasic
function GetTextLengthEx( byval hRichEdit as HWND, byval lpgtex as ..GETTEXTLENGTHEX ptr ) as long
```

Measures the text the way `GETTEXTLENGTHEX` asks: `flags` combines `GTL_NUMCHARS` or
`GTL_NUMBYTES` with `GTL_USECRLF` (count each paragraph end as two) and `GTL_PRECISE` or
`GTL_CLOSE`; `codepage` is the code page the count is for. For `"one" & chr(13) & "two"`,
`GTL_NUMCHARS` gives 7 and `GTL_NUMCHARS or GTL_USECRLF` gives 8.

**Returns** the length, or `E_INVALIDARG`.

**Example**

```freebasic
dim gtl as GETTEXTLENGTHEX
gtl.flags = GTL_NUMCHARS : gtl.codepage = 1200
print richedit.RichEdit.GetTextLengthEx( hCtrl, @gtl ); " character positions"
```

Microsoft Learn: [EM_GETTEXTLENGTHEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextlengthex)

### SetTextExW

```freebasic
function SetTextExW( byval hRichEdit as HWND, byval pstex as SETTEXTEX ptr, byval pwszText as wstring ptr ) as DWORD
```

Replaces the text, or with `ST_SELECTION` only the selection, with `pwszText`. Text that starts
with `{\rtf` is read as RTF, anything else as plain text. `SETTEXTEX.flags` combines
`ST_DEFAULT`, `ST_KEEPUNDO`, `ST_SELECTION`, `ST_NEWCHARS` and `ST_UNICODE`; `codepage` is the
code page of the text: 1200 for a `wstring`, or `CP_ACP` for RTF held in a narrow `string`,
passed with a cast.

| Parameter | Meaning |
| --- | --- |
| `pstex` | A filled-in `SETTEXTEX`. |
| `pwszText` | The text or RTF. |

**Returns** 1 on success (for `ST_SELECTION`, the number of characters inserted), 0 on failure.

**Example**

```freebasic
dim stx as SETTEXTEX
stx.flags = ST_DEFAULT : stx.codepage = CP_ACP
dim rtf as string = "{\rtf1\ansi plain {\b bold} plain}"
richedit.RichEdit.SetTextExW( hCtrl, @stx, cast( wstring ptr, strptr( rtf ) ) )
```

Microsoft Learn: [EM_SETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-settextex)

### GetTextRange

```freebasic
function GetTextRange( byval hRichEdit as HWND, byval lptrg as TEXTRANGEW ptr ) as DWORD
```

Copies the characters from `chrg.cpMin` to just before `chrg.cpMax` of a `TEXTRANGEW` into the
buffer its `lpstrText` points to, which must have room for them and a terminating null.

**Returns** the number of characters copied.

**Example**

```freebasic
dim buf as wstring * 32
dim tr as TEXTRANGEW
tr.chrg.cpMin = 4 : tr.chrg.cpMax = 7 : tr.lpstrText = @buf
richedit.RichEdit.GetTextRange( hCtrl, @tr )   ' buf holds characters 4, 5 and 6
```

Microsoft Learn: [EM_GETTEXTRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextrange)

### GetLine

```freebasic
function GetLine( byval hRichEdit as HWND, byval which as DWORD ) as ustring
```

Returns line `which` (counted from 0) as plain text. A line that ends a paragraph comes back with
its carriage return (13) at the end, and so does the last line: for `"one" & chr(13) & "two"`
both lines read back as four characters. A line number past the last line gives `""`.

The line is read into a buffer of about 32,000 characters; longer lines are not supported.

**Returns** the line.

**Example**

```freebasic
dim s as ustring = richedit.RichEdit.GetLine( hCtrl, 0 )
print "first line: "; rtrim( s, chr(13) )
```

Microsoft Learn: [EM_GETLINE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getline)

### GetLineCount

```freebasic
function GetLineCount( byval hRichEdit as HWND ) as long
```

Returns the number of lines, as displayed. An empty control has one line.

**Returns** the line count.

**Example**

```freebasic
print richedit.RichEdit.GetLineCount( hCtrl ); " lines"
```

Microsoft Learn: [EM_GETLINECOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getlinecount)

### LineIndex

```freebasic
function LineIndex( byval hRichEdit as HWND, byval nLine as long ) as long
```

Returns the position of the first character of line `nLine`; -1 means the line that holds the
caret. In `"first line" & chr(13) & "second"` line 1 starts at 11.

**Returns** the position, or -1 when the line does not exist.

**Example**

```freebasic
dim nStart as long = richedit.RichEdit.LineIndex( hCtrl, 1 )
richedit.RichEdit.SetSel( hCtrl, nStart, nStart )   ' caret to the start of line 1
```

Microsoft Learn: [EM_LINEINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-lineindex)

### LineFromChar

```freebasic
function LineFromChar( byval hRichEdit as HWND, byval index as DWORD ) as long
```

Returns the line that holds the character at `index`. `-1` gives the line of the caret, or of
the start of the selection. Positions beyond 65,535 need [ExLineFromChar](#exlinefromchar).

**Returns** the line, counted from 0.

**Example**

```freebasic
print "the caret is on line"; richedit.RichEdit.LineFromChar( hCtrl, -1 ) + 1
```

Microsoft Learn: [EM_LINEFROMCHAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-linefromchar)

### ExLineFromChar

```freebasic
function ExLineFromChar( byval hRichEdit as HWND, byval iIndex as long ) as long
```

Returns the line that holds the character at `iIndex`, for any position in the text.

**Returns** the line, counted from 0.

**Example**

```freebasic
dim cr as CHARRANGE
richedit.RichEdit.ExGetSel( hCtrl, @cr )
print "line"; richedit.RichEdit.ExLineFromChar( hCtrl, cr.cpMin ) + 1
```

Microsoft Learn: [EM_EXLINEFROMCHAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-exlinefromchar)

### LineLength

```freebasic
function LineLength( byval hRichEdit as HWND, byval index as DWORD ) as long
```

Returns the length of the line that holds the character at `index`, without its carriage return.
With `-1` it returns the number of characters on the selected lines that are not selected.

**Returns** the length in characters.

**Example**

```freebasic
dim nLen as long = richedit.RichEdit.LineLength( hCtrl, richedit.RichEdit.LineIndex( hCtrl, 0 ) )
```

Microsoft Learn: [EM_LINELENGTH](https://learn.microsoft.com/en-us/windows/win32/controls/em-linelength)

### GetLimitText, LimitText, SetLimitText

```freebasic
function GetLimitText( byval hRichEdit as HWND ) as long
sub LimitText( byval hRichEdit as HWND, byval chMax as DWORD )
sub SetLimitText( byval hRichEdit as HWND, byval chMax as DWORD )
```

`GetLimitText` returns how many characters the user can type or paste; a new control allows
32,767. `LimitText` and `SetLimitText` are the same call: they set that limit to `chMax`, and 0
sets 65,536. The limit does not stop text set by the program: [SetText](#settext) with ten
characters still sets all ten under a limit of 5. For a limit above 65,536 use
[ExLimitText](#exlimittext).

**Returns** (`GetLimitText`) the limit in characters.

**Example**

```freebasic
richedit.RichEdit.LimitText( hCtrl, 500 )
print richedit.RichEdit.GetLimitText( hCtrl )   ' 500
```

Microsoft Learn: [EM_GETLIMITTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getlimittext), [EM_LIMITTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/em-limittext)

### ExLimitText

```freebasic
sub ExLimitText( byval hRichEdit as HWND, byval dwLimit as DWORD )
```

Sets how many characters the user can type or paste, with no 64K ceiling. 0 sets the default of
65,536.

**Example**

```freebasic
richedit.RichEdit.ExLimitText( hCtrl, 1000000 )
```

Microsoft Learn: [EM_EXLIMITTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/em-exlimittext)

### GetTextMode, SetTextMode

```freebasic
function GetTextMode( byval hRichEdit as HWND ) as DWORD
function SetTextMode( byval hRichEdit as HWND, byval pvalues as long ) as long
```

`GetTextMode` returns the control's text mode: `TM_RICHTEXT` or `TM_PLAINTEXT`, combined with
`TM_SINGLELEVELUNDO` or `TM_MULTILEVELUNDO` and `TM_SINGLECODEPAGE` or `TM_MULTICODEPAGE`. A new
`RichEdit50W` control reads 42 (`TM_RICHTEXT or TM_MULTILEVELUNDO or TM_MULTICODEPAGE`).

**Returns** (`GetTextMode`) the `TM_*` flags; (`SetTextMode`) 0.

**Example**

```freebasic
print richedit.RichEdit.GetTextMode( hCtrl )
SendMessageW( hCtrl, EM_SETTEXTMODE, TM_PLAINTEXT, 0 )   ' what changes the mode of an empty control
```

Microsoft Learn: [EM_GETTEXTMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettextmode), [EM_SETTEXTMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-settextmode)

### GetModify, SetModify

```freebasic
function GetModify( byval hRichEdit as HWND ) as long
sub SetModify( byval hRichEdit as HWND, byval fModify as long )
```

The control sets its modification flag whenever the text changes. `GetModify` reads it;
`SetModify` sets it (nonzero) or clears it (0), for example after saving.

**Returns** (`GetModify`) nonzero when the text has changed since the flag was cleared.

**Example**

```freebasic
if richedit.RichEdit.GetModify( hCtrl ) then print "unsaved changes"
richedit.RichEdit.SetModify( hCtrl, 0 )
```

Microsoft Learn: [EM_GETMODIFY](https://learn.microsoft.com/en-us/windows/win32/controls/em-getmodify), [EM_SETMODIFY](https://learn.microsoft.com/en-us/windows/win32/controls/em-setmodify)

### GetSel

```freebasic
function GetSel( byval hRichEdit as HWND, byval pdwStartPos as DWORD ptr, byval pdwEndPos as DWORD ptr ) as long
```

Reads the start and end of the selection into the two variables; either pointer may be `NULL`.
When nothing is selected both hold the caret position.

**Returns** the start in the low word and the end in the high word, which is only meaningful for
positions below 65,536 (a selection from 7 to 11 returns `&hB0007`); use the variables, or
[ExGetSel](#exgetsel), instead.

**Example**

```freebasic
dim as DWORD nStart, nEnd
richedit.RichEdit.GetSel( hCtrl, @nStart, @nEnd )
print "selected"; nStart; " to"; nEnd
```

Microsoft Learn: [EM_GETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-getsel)

### SetSel

```freebasic
sub SetSel( byval hRichEdit as HWND, byval nStart as long, byval nEnd as long )
```

Selects the characters from `nStart` to just before `nEnd`. `0, -1` selects all the text; a
start of -1 removes the selection and leaves the caret where it was; equal values put the caret
there with nothing selected.

| Parameter | Meaning |
| --- | --- |
| `nStart` | Where the selection starts. |
| `nEnd` | Where it ends; -1 for the end of the text. |

**Example**

```freebasic
richedit.RichEdit.SetSel( hCtrl, 0, -1 )   ' select all
```

Microsoft Learn: [EM_SETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel)

### ExGetSel

```freebasic
sub ExGetSel( byval hRichEdit as HWND, byval lpchr as CHARRANGE ptr )
```

Reads the selection into a `CHARRANGE`: `cpMin` is the start, `cpMax` the end.

**Example**

```freebasic
dim cr as CHARRANGE
richedit.RichEdit.ExGetSel( hCtrl, @cr )
print cr.cpMax - cr.cpMin; " characters selected"
```

Microsoft Learn: [EM_EXGETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-exgetsel)

### ExSetSel

```freebasic
function ExSetSel( byval hRichEdit as HWND, byval lpcr as CHARRANGE ptr ) as DWORD
```

Selects the range a `CHARRANGE` holds, with the same conventions as [SetSel](#setsel).

**Returns** the end of the selection the control actually set (5 for `0` to `5`).

**Example**

```freebasic
dim cr as CHARRANGE
cr.cpMin = 0 : cr.cpMax = 5
richedit.RichEdit.ExSetSel( hCtrl, @cr )
```

Microsoft Learn: [EM_EXSETSEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-exsetsel)

### GetSelText

```freebasic
function GetSelText( byval hRichEdit as HWND ) as ustring
```

Returns the selected text as plain text, or `""` when nothing is selected.

**Returns** the selected text.

**Example**

```freebasic
richedit.RichEdit.SetSel( hCtrl, 0, 5 )
print richedit.RichEdit.GetSelText( hCtrl )   ' the first five characters
```

Microsoft Learn: [EM_GETSELTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getseltext)

### ReplaceSel

```freebasic
sub ReplaceSel( byval hRichEdit as HWND, byval bCanBeUndone as long, byval pwszText as wstring ptr )
```

Replaces the selection with `pwszText`, in the format of the selection's start; with nothing
selected it inserts the text at the caret. To append, put the caret at the end of the text first,
as the example does.

| Parameter | Meaning |
| --- | --- |
| `bCanBeUndone` | Nonzero to make the replacement an action [Undo](#undo) can undo. |
| `pwszText` | The new text. |

**Example**

```freebasic
dim n as long = richedit.RichEdit.GetTextLength( hCtrl )
richedit.RichEdit.SetSel( hCtrl, n, n )
richedit.RichEdit.ReplaceSel( hCtrl, true, "appended" )
```

Microsoft Learn: [EM_REPLACESEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-replacesel)

### SelectionType

```freebasic
function SelectionType( byval hRichEdit as HWND ) as long
```

Tells what the selection holds, as `SEL_*` flags: `SEL_EMPTY` (0), or a combination of
`SEL_TEXT`, `SEL_OBJECT`, `SEL_MULTICHAR` and `SEL_MULTIOBJECT`. Four selected characters give
5 (`SEL_TEXT or SEL_MULTICHAR`).

**Returns** the flags.

**Example**

```freebasic
if richedit.RichEdit.SelectionType( hCtrl ) and SEL_OBJECT then print "an object is selected"
```

Microsoft Learn: [EM_SELECTIONTYPE](https://learn.microsoft.com/en-us/windows/win32/controls/em-selectiontype)

### HideSelection

```freebasic
sub HideSelection( byval hRichEdit as HWND, byval fHide as DWORD )
```

Hides the selection highlight (`fHide` nonzero) or shows it again (0). The selection itself does
not change.

**Example**

```freebasic
richedit.RichEdit.HideSelection( hCtrl, true )
```

Microsoft Learn: [EM_HIDESELECTION](https://learn.microsoft.com/en-us/windows/win32/controls/em-hideselection)

### FindText

```freebasic
function FindText( byval hRichEdit as HWND, byval fOptions as DWORD, byval lpft as FINDTEXTW ptr ) as long
```

Searches for `lpstrText` of a `FINDTEXTW` within its range `chrg`. `fOptions` combines `FR_DOWN`
(search forward; without it the search runs backward), `FR_MATCHCASE` and `FR_WHOLEWORD`. The
selection does not move.

**Returns** the position where the text was found, or -1.

**Example**

```freebasic
dim ft as FINDTEXTW
ft.chrg.cpMin = 0 : ft.chrg.cpMax = -1
ft.lpstrText = @wstr( "two" )
print "found at"; richedit.RichEdit.FindText( hCtrl, FR_DOWN, @ft )
```

Microsoft Learn: [EM_FINDTEXTW](https://learn.microsoft.com/en-us/windows/win32/controls/em-findtextw)

### FindTextEx

```freebasic
function FindTextEx( byval hRichEdit as HWND, byval fOptions as DWORD, byval lpftexw as FINDTEXTEXW ptr ) as long
```

Searches like [FindText](#findtext) and also stores the range of the text found in the
structure's `chrgText`, ready to pass to [ExSetSel](#exsetsel). In `"one two three two"`, a
search for `"two"` from 0 returns 4 with `chrgText` 4 to 7.

**Returns** the position where the text was found, or -1.

**Example**

```freebasic
dim ft as FINDTEXTEXW
ft.chrg.cpMin = 0 : ft.chrg.cpMax = -1
ft.lpstrText = @wstr( "two" )
if richedit.RichEdit.FindTextEx( hCtrl, FR_DOWN, @ft ) >= 0 then richedit.RichEdit.ExSetSel( hCtrl, @ft.chrgText )
```

Microsoft Learn: [EM_FINDTEXTEXW](https://learn.microsoft.com/en-us/windows/win32/controls/em-findtextexw)

### FindWordBreak

```freebasic
function FindWordBreak( byval hRichEdit as HWND, byval fOperation as DWORD, byval dwStartPos as DWORD ) as DWORD
```

Finds a word break from `dwStartPos`, or tells something about the character there, depending on
`fOperation`: `WB_MOVEWORDRIGHT` and `WB_MOVEWORDLEFT` return where the next or previous word
starts, `WB_LEFT` and `WB_RIGHT` where the word ends, and `WB_ISDELIMITER` whether the
character is a delimiter. In `"one two three two"`, `WB_MOVEWORDRIGHT` from 0 returns 4.

**Returns** the position found, or for the classifying operations the answer.

**Example**

```freebasic
dim nNext as DWORD = richedit.RichEdit.FindWordBreak( hCtrl, WB_MOVEWORDRIGHT, 0 )
```

Microsoft Learn: [EM_FINDWORDBREAK](https://learn.microsoft.com/en-us/windows/win32/controls/em-findwordbreak)

### CharFromPos

```freebasic
function CharFromPos( byval hRichEdit as HWND, byval lppl as POINTL ptr ) as long
```

Returns the character nearest a point given in client coordinates. With the point that
[PosFromChar](#posfromchar) gives for a character, it returns that character.

**Returns** the position of the character.

**Example**

```freebasic
dim pt as POINTL
pt.x = 10 : pt.y = 10
print "character"; richedit.RichEdit.CharFromPos( hCtrl, @pt )
```

Microsoft Learn: [EM_CHARFROMPOS](https://learn.microsoft.com/en-us/windows/win32/controls/em-charfrompos)

### PosFromChar

```freebasic
sub PosFromChar( byval hRichEdit as HWND, byval pt as POINTL ptr, byval index as DWORD )
```

Stores in `pt` the client coordinates of the top-left corner of the character at `index`.

**Example**

```freebasic
dim pt as POINTL
richedit.RichEdit.PosFromChar( hCtrl, @pt, 3 )
print "character 3 is at"; pt.x; ","; pt.y
```

Microsoft Learn: [EM_POSFROMCHAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-posfromchar)

### GetCharFormat

```freebasic
function GetCharFormat( byval hRichEdit as HWND, byval fOption as DWORD, byval lpcf as CHARFORMATW ptr ) as DWORD
```

Reads character formatting into a `CHARFORMATW` (or a `CHARFORMAT2W`, cast): with `SCF_SELECTION`
the formatting of the selection, with `SCF_DEFAULT` the default formatting. Set `cbSize` first.
Sizes (`yHeight`) are in twips, twentieths of a point.

| Parameter | Meaning |
| --- | --- |
| `fOption` | `SCF_SELECTION` or `SCF_DEFAULT`. |
| `lpcf` | Receives the formatting. |

**Returns** the `dwMask` of the attributes that are the same over the whole selection; the same
value is stored in `dwMask`.

**Example**

```freebasic
dim cf as CHARFORMATW
cf.cbSize = sizeof( cf )
richedit.RichEdit.GetCharFormat( hCtrl, SCF_SELECTION, @cf )
print cf.szFaceName; cf.yHeight / 20; " pt"
```

Microsoft Learn: [EM_GETCHARFORMAT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getcharformat)

### SetCharFormat

```freebasic
function SetCharFormat( byval hRichEdit as HWND, byval chfmt as DWORD, byval lpcf as CHARFORMATW ptr ) as long
```

Applies the attributes `dwMask` names from a `CHARFORMATW` (or a `CHARFORMAT2W`, cast). `chfmt`
says to what: `SCF_SELECTION` (the selection, or the typing at the caret), `SCF_WORD or
SCF_SELECTION` (the word at the caret), `SCF_ALL` (all the text) or `SCF_DEFAULT` (the default
formatting).

**Returns** nonzero on success, 0 on failure.

**Example**

```freebasic
dim cf as CHARFORMATW
cf.cbSize = sizeof( cf ) : cf.dwMask = CFM_BOLD : cf.dwEffects = CFE_BOLD
richedit.RichEdit.SetSel( hCtrl, 0, 5 )
richedit.RichEdit.SetCharFormat( hCtrl, SCF_SELECTION, @cf )
```

Microsoft Learn: [EM_SETCHARFORMAT](https://learn.microsoft.com/en-us/windows/win32/controls/em-setcharformat)

### SetFont

```freebasic
function SetFont( byval hRichEdit as HWND, byref wszFaceName as wstring, byval ptsize as long ) as LRESULT
```

Sets the face and size of **all** the text. It looks up the font's character set and pitch by
enumerating the fonts called `wszFaceName`, then applies face, character set and size to the
whole text with one `SCF_ALL` call.

| Parameter | Meaning |
| --- | --- |
| `wszFaceName` | The font's face name, such as `"Segoe UI"`. |
| `ptsize` | The size in points. |

**Returns** 0 when the formatting failed. If the operation succeeds, the return value is a nonzero value.

**Example**

```freebasic
richedit.RichEdit.SetFont( hCtrl, "Consolas", 10 )
```

Microsoft Learn: [EM_SETCHARFORMAT](https://learn.microsoft.com/en-us/windows/win32/controls/em-setcharformat), [EnumFontFamiliesW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-enumfontfamiliesw)

### SetFontSize

```freebasic
function SetFontSize( byval hRichEdit as HWND, byval ptsize as long ) as long
```

Makes the font of the selected text larger (`ptsize` positive) or smaller (negative) by that many
points: 12-point text with `2` becomes 14 points. The control rounds to its standard sizes and
keeps the size between 1 and 1638 points.

**Returns** nonzero on success, 0 when there was no change.

**Example**

```freebasic
richedit.RichEdit.SetSel( hCtrl, 0, -1 )
richedit.RichEdit.SetFontSize( hCtrl, 2 )
```

Microsoft Learn: [EM_SETFONTSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setfontsize)

### GetParaFormat, SetParaFormat

```freebasic
function GetParaFormat( byval hRichEdit as HWND, byval pParaFmt as PARAFORMAT ptr ) as DWORD
function SetParaFormat( byval hRichEdit as HWND, byval pfmt as PARAFORMAT ptr ) as long
```

Read or set the paragraph formatting of the paragraphs in the selection: alignment, indents, tab
stops, numbering and, with a `PARAFORMAT2` (cast), spacing, borders and shading. Set `cbSize`
first and, to set, name the attributes in `dwMask`.

**Returns** (`GetParaFormat`) the `dwMask` of the attributes that are the same over the
selection; (`SetParaFormat`) nonzero on success.

**Example**

```freebasic
dim pf as PARAFORMAT2
pf.cbSize = sizeof( pf ) : pf.dwMask = PFM_ALIGNMENT : pf.wAlignment = PFA_CENTER
richedit.RichEdit.SetParaFormat( hCtrl, cast( PARAFORMAT ptr, @pf ) )
```

Microsoft Learn: [EM_GETPARAFORMAT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getparaformat), [EM_SETPARAFORMAT](https://learn.microsoft.com/en-us/windows/win32/controls/em-setparaformat)

### SetBkgndColor

```freebasic
function SetBkgndColor( byval hRichEdit as HWND, byval pSysColor as DWORD, byval pBkColor as DWORD ) as DWORD
```

Sets the background colour. With `pSysColor` nonzero the control uses the system window colour
and ignores `pBkColor`; with 0 it uses the `COLORREF` in `pBkColor`.

**Returns** the previous background colour.

**Example**

```freebasic
richedit.RichEdit.SetBkgndColor( hCtrl, 0, BGR( 255, 255, 224 ) )   ' light yellow
```

Microsoft Learn: [EM_SETBKGNDCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/em-setbkgndcolor)

### InsertTable

```freebasic
function InsertTable( byval hRichEdit as HWND, byval lptp as TABLEROWPARMS ptr, byval lptcp as TABLECELLPARMS ptr ) as DWORD
```

Inserts `cRow` identical rows of `cCell` empty cells at the selection. `lptp` describes the rows
(set `cbRow` and `cbCell` to the two structure sizes); `lptcp` points to an array of `cCell`
`TABLECELLPARMS`, one per cell, with widths in twips.

**Returns** `S_OK` on success, otherwise an error code.

**Example**

```freebasic
dim trp as TABLEROWPARMS
trp.cbRow = sizeof( TABLEROWPARMS ) : trp.cbCell = sizeof( TABLECELLPARMS ) : trp.cCell = 3 : trp.cRow = 2
dim tcp( 0 to 2 ) as TABLECELLPARMS
for i as long = 0 to 2 : tcp( i ).dxWidth = 1440 : next   ' one inch each
richedit.RichEdit.InsertTable( hCtrl, @trp, @tcp( 0 ) )
```

Microsoft Learn: [EM_INSERTTABLE](https://learn.microsoft.com/en-us/windows/win32/controls/em-inserttable)

### GetTableParams, SetTableParams

```freebasic
function GetTableParams( byval hRichEdit as HWND, byval lptp as TABLEROWPARMS ptr, byval lptcp as TABLECELLPARMS ptr ) as DWORD
function SetTableParams( byval hRichEdit as HWND, byval lptp as TABLEROWPARMS ptr, byval lptcp as TABLECELLPARMS ptr ) as DWORD
```

Read or change the row and cell parameters of the table row that holds the selection. Set
`cbRow`, `cbCell` and `cCell` first; `lptcp` points to an array with room for `cCell` cells.

**Returns** `S_OK` on success, otherwise an error code.

**Example**

```freebasic
dim trp as TABLEROWPARMS
trp.cbRow = sizeof( TABLEROWPARMS ) : trp.cbCell = sizeof( TABLECELLPARMS ) : trp.cCell = 3
dim tcp( 0 to 2 ) as TABLECELLPARMS
if richedit.RichEdit.GetTableParams( hCtrl, @trp, @tcp( 0 ) ) = S_OK then print "first cell"; tcp( 0 ).dxWidth; " twips"
```

Microsoft Learn: [EM_GETTABLEPARMS](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettableparms), [EM_SETTABLEPARMS](https://learn.microsoft.com/en-us/windows/win32/controls/em-settableparms)

### InsertImage

```freebasic
function InsertImage( byval hRichEdit as HWND, byval lpip as RICHEDIT_IMAGE_PARAMETERS ptr ) as DWORD
```

Replaces the selection with an image read from the `IStream` in `pIStream`. `xWidth` and
`yHeight` give its size in HIMETRIC units (hundredths of a millimetre), `Type` its vertical
alignment (`TA_BASELINE`, `TA_TOP`, `TA_BOTTOM`), and `pwszAlternateText` its alternative text.

**Returns** `S_OK` on success, otherwise an error code.

**Example**

```freebasic
dim pStream as IStream ptr
SHCreateStreamOnFileEx( "picture.png", STGM_READ, 0, false, NULL, @pStream )
dim ip as RICHEDIT_IMAGE_PARAMETERS
ip.xWidth = 2540 : ip.yHeight = 2540 : ip.Type = TA_BASELINE : ip.pwszAlternateText = @wstr( "a picture" ) : ip.pIStream = pStream
if pStream then richedit.RichEdit.InsertImage( hCtrl, @ip ) : pStream->lpVtbl->Release( pStream )
```

Microsoft Learn: [EM_INSERTIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/em-insertimage)

### SetTabStops

```freebasic
function SetTabStops( byval hRichEdit as HWND, byval nTabs as long, byval rgTabStops as LONG_PTR ) as long
```

Sets tab stops for the whole control. `rgTabStops` is the address of an array of `nTabs` `long`
positions in dialog template units; 0 tabs restores the default of a stop every 32 units.
Per-paragraph tab stops are set with [SetParaFormat](#getparaformat-setparaformat).

**Returns** nonzero when all the tabs were set.

**Example**

```freebasic
dim tabs( 0 to 1 ) as long = { 32, 64 }
richedit.RichEdit.SetTabStops( hCtrl, 2, cast( LONG_PTR, @tabs( 0 ) ) )
```

Microsoft Learn: [EM_SETTABSTOPS](https://learn.microsoft.com/en-us/windows/win32/controls/em-settabstops)

### GetBidiOptions, SetBidiOptions

```freebasic
sub GetBidiOptions( byval hRichEdit as HWND, byval lpbo as BIDIOPTIONS ptr )
sub SetBidiOptions( byval hRichEdit as HWND, byval pOptions as BIDIOPTIONS ptr )
```

Read or set the options for right-to-left text in a `BIDIOPTIONS`: `wMask` names the `BOM_*`
options to read or change, `wEffects` holds their `BOE_*` values. Set `cbSize` first.

**Example**

```freebasic
dim bo as BIDIOPTIONS
bo.cbSize = sizeof( bo ) : bo.wMask = BOM_CONTEXTREADING : bo.wEffects = BOE_CONTEXTREADING
richedit.RichEdit.SetBidiOptions( hCtrl, @bo )
```

Microsoft Learn: [EM_GETBIDIOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-getbidioptions), [EM_SETBIDIOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setbidioptions)

### GetHyphenateInfo, SetHyphenateInfo

```freebasic
sub GetHyphenateInfo( byval hRichEdit as HWND, byval lphi as HYPHENATEINFO ptr )
sub SetHyphenateInfo( byval hRichEdit as HWND, byval phinfo as HYPHENATEINFO ptr )
```

Read or set how the control hyphenates, in a `HYPHENATEINFO`: the hyphenation zone
`dxHyphenateZone` and the procedure `pfnHyphenate` that decides where words break. Set `cbSize`
first.

**Example**

```freebasic
dim hi as HYPHENATEINFO
hi.cbSize = sizeof( hi )
richedit.RichEdit.GetHyphenateInfo( hCtrl, @hi )
```

Microsoft Learn: [EM_GETHYPHENATEINFO](https://learn.microsoft.com/en-us/windows/win32/controls/em-gethyphenateinfo), [EM_SETHYPHENATEINFO](https://learn.microsoft.com/en-us/windows/win32/controls/em-sethyphenateinfo)

### CanUndo

```freebasic
function CanUndo( byval hRichEdit as HWND ) as long
```

Tells whether there is an action to undo.

**Returns** nonzero when [Undo](#undo) would do something.

**Example**

```freebasic
if richedit.RichEdit.CanUndo( hCtrl ) then print "something to undo"
```

Microsoft Learn: [EM_CANUNDO](https://learn.microsoft.com/en-us/windows/win32/controls/em-canundo)

### Undo

```freebasic
function Undo( byval hRichEdit as HWND ) as long
```

Undoes the last action in the undo queue. With multilevel undo, the default, each call goes one
action further back.

**Returns** nonzero on success, 0 when there was nothing to undo.

**Example**

```freebasic
if richedit.RichEdit.CanUndo( hCtrl ) then richedit.RichEdit.Undo( hCtrl )
```

Microsoft Learn: [EM_UNDO](https://learn.microsoft.com/en-us/windows/win32/controls/em-undo)

### CanRedo

```freebasic
function CanRedo( byval hRichEdit as HWND ) as long
```

Tells whether there is an undone action to redo.

**Returns** nonzero when [Redo](#redo) would do something.

**Example**

```freebasic
if richedit.RichEdit.CanRedo( hCtrl ) then print "redo is possible"
```

Microsoft Learn: [EM_CANREDO](https://learn.microsoft.com/en-us/windows/win32/controls/em-canredo)

### Redo

```freebasic
function Redo( byval hRichEdit as HWND ) as long
```

Redoes the action that [Undo](#undo) last undid.

**Returns** nonzero on success, 0 when there was nothing to redo.

**Example**

```freebasic
richedit.RichEdit.Redo( hCtrl )
```

Microsoft Learn: [EM_REDO](https://learn.microsoft.com/en-us/windows/win32/controls/em-redo)

### GetUndoName

```freebasic
function GetUndoName( byval hRichEdit as HWND ) as DWORD
```

Tells what kind of action the next [Undo](#undo) would undo, as a `UID_*` value: `UID_TYPING`,
`UID_DELETE`, `UID_DRAGDROP`, `UID_CUT`, `UID_PASTE` … or `UID_UNKNOWN` (0). A control with
nothing to undo returns 0.

**Returns** the `UID_*` value.

**Example**

```freebasic
if richedit.RichEdit.GetUndoName( hCtrl ) = UID_TYPING then print "undo typing"
```

Microsoft Learn: [EM_GETUNDONAME](https://learn.microsoft.com/en-us/windows/win32/controls/em-getundoname)

### GetRedoName

```freebasic
function GetRedoName( byval hRichEdit as HWND ) as long
```

Tells what kind of action the next [Redo](#redo) would redo, as a `UID_*` value.

**Returns** the `UID_*` value, 0 when there is nothing to redo or the kind is not known.

**Example**

```freebasic
if richedit.RichEdit.GetRedoName( hCtrl ) = UID_PASTE then print "redo paste"
```

Microsoft Learn: [EM_GETREDONAME](https://learn.microsoft.com/en-us/windows/win32/controls/em-getredoname)

### EmptyUndoBuffer

```freebasic
sub EmptyUndoBuffer( byval hRichEdit as HWND )
```

Empties the undo and redo queues, so that nothing done so far can be undone; [CanUndo](#canundo)
returns 0 afterwards.

**Example**

```freebasic
richedit.RichEdit.EmptyUndoBuffer( hCtrl )
```

Microsoft Learn: [EM_EMPTYUNDOBUFFER](https://learn.microsoft.com/en-us/windows/win32/controls/em-emptyundobuffer)

### SetUndoLimit

```freebasic
function SetUndoLimit( byval hRichEdit as HWND, byval maxactions as DWORD ) as DWORD
```

Sets how many actions the undo queue keeps; the default is 100, and 0 turns undo off.

**Returns** the new limit, which can be lower than asked for when memory is short.

**Example**

```freebasic
richedit.RichEdit.SetUndoLimit( hCtrl, 50 )
```

Microsoft Learn: [EM_SETUNDOLIMIT](https://learn.microsoft.com/en-us/windows/win32/controls/em-setundolimit)

### StopGroupTyping

```freebasic
function StopGroupTyping( byval hRichEdit as HWND ) as DWORD
```

Ends the current undo action for typing, so that what is typed next is undone separately. The
control otherwise groups consecutive typing into one action.

**Returns** 0.

**Example**

```freebasic
richedit.RichEdit.StopGroupTyping( hCtrl )
```

Microsoft Learn: [EM_STOPGROUPTYPING](https://learn.microsoft.com/en-us/windows/win32/controls/em-stopgrouptyping)

### CanPaste

```freebasic
function CanPaste( byval hRichEdit as HWND, byval clipformat as long ) as long
```

Tells whether the control can paste clipboard format `clipformat`; 0 asks about any format on the
clipboard.

**Returns** nonzero when it can.

**Example**

```freebasic
if richedit.RichEdit.CanPaste( hCtrl, CF_UNICODETEXT ) then print "text can be pasted"
```

Microsoft Learn: [EM_CANPASTE](https://learn.microsoft.com/en-us/windows/win32/controls/em-canpaste)

### PasteSpecial

```freebasic
sub PasteSpecial( byval hRichEdit as HWND, byval clpfmt as DWORD, byval lprps as REPASTESPECIAL ptr )
```

Pastes the clipboard's data in format `clpfmt`, for example `CF_UNICODETEXT` to paste formatted
text as plain text. `lprps` may be `NULL`, or a `REPASTESPECIAL` that says how to show a pasted
object.

**Example**

```freebasic
richedit.RichEdit.PasteSpecial( hCtrl, CF_UNICODETEXT, NULL )   ' paste as plain text
```

Microsoft Learn: [EM_PASTESPECIAL](https://learn.microsoft.com/en-us/windows/win32/controls/em-pastespecial)

### SetReadOnly

```freebasic
function SetReadOnly( byval hRichEdit as HWND, byval fReadOnly as long ) as long
```

Makes the control read-only (nonzero) or editable again (0). The program can still change the
text with [SetText](#settext) and [ReplaceSel](#replacesel); the `ECO_READONLY` bit of [GetOptions](#getoptions-setoptions) shows the state.

**Returns** nonzero on success.

**Example**

```freebasic
richedit.RichEdit.SetReadOnly( hCtrl, true )
```

Microsoft Learn: [EM_SETREADONLY](https://learn.microsoft.com/en-us/windows/win32/controls/em-setreadonly)

### GetPasswordChar, SetPasswordChar

```freebasic
function GetPasswordChar( byval hRichEdit as HWND ) as long
sub SetPasswordChar( byval hRichEdit as HWND, byval dwchar as DWORD )
```

`SetPasswordChar` makes the control show `dwchar` in place of every character, or show the text
again with 0. `GetPasswordChar` returns the character in use.

**Returns** (`GetPasswordChar`) the character code, 0 when there is none.

**Example**

```freebasic
richedit.RichEdit.SetPasswordChar( hCtrl, asc( "*" ) )
print richedit.RichEdit.GetPasswordChar( hCtrl )   ' 42
```

Microsoft Learn: [EM_GETPASSWORDCHAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-getpasswordchar), [EM_SETPASSWORDCHAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-setpasswordchar)

### GetEventMask, SetEventMask

```freebasic
function GetEventMask( byval hRichEdit as HWND ) as DWORD
function SetEventMask( byval hRichEdit as HWND, byval fMask as long ) as long
```

The event mask says which notifications the control sends its parent: `ENM_CHANGE`,
`ENM_SELCHANGE`, `ENM_LINK`, `ENM_REQUESTRESIZE`, `ENM_SCROLL`, `ENM_KEYEVENTS`,
`ENM_MOUSEEVENTS` … combined with `or`. A new control has an empty mask. `SetEventMask` replaces
the whole mask; to add one, `or` it with `GetEventMask`.

**Returns** (`GetEventMask`) the mask; (`SetEventMask`) the previous mask.

**Example**

```freebasic
richedit.RichEdit.SetEventMask( hCtrl, richedit.RichEdit.GetEventMask( hCtrl ) or ENM_SELCHANGE )
```

Microsoft Learn: [EM_GETEVENTMASK](https://learn.microsoft.com/en-us/windows/win32/controls/em-geteventmask), [EM_SETEVENTMASK](https://learn.microsoft.com/en-us/windows/win32/controls/em-seteventmask)

### GetOptions, SetOptions

```freebasic
function GetOptions( byval hRichEdit as HWND ) as DWORD
function SetOptions( byval hRichEdit as HWND, byval fCoop as long, byval fOptions as long ) as long
```

Read or change the `ECO_*` options: `ECO_AUTOVSCROLL`, `ECO_AUTOHSCROLL`, `ECO_NOHIDESEL`,
`ECO_READONLY`, `ECO_WANTRETURN`, `ECO_SAVESEL`, `ECO_SELECTIONBAR` (a margin at the left for
selecting lines) … `fCoop` says how `fOptions` combines with the current options: `ECOOP_SET`,
`ECOOP_OR`, `ECOOP_AND` or `ECOOP_XOR`.

**Returns** (`GetOptions`) the options; (`SetOptions`) the options after the change.

**Example**

```freebasic
richedit.RichEdit.SetOptions( hCtrl, ECOOP_OR, ECO_SELECTIONBAR )
```

Microsoft Learn: [EM_GETOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-getoptions), [EM_SETOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setoptions)

### GetEditStyle, SetEditStyle

```freebasic
function GetEditStyle( byval hRichEdit as HWND ) as DWORD
function SetEditStyle( byval hRichEdit as HWND, byval fStyle as long, byval fMask as long ) as DWORD
```

Read or change the `SES_*` edit styles (`SES_EMULATESYSEDIT`, `SES_BEEPONMAXTEXT`,
`SES_XLTCRCRLFTOCR`, `SES_HYPERLINKTOOLTIPS` …). `SetEditStyle` changes the styles named in
`fMask` to their values in `fStyle`.

**Returns** the edit styles (for `SetEditStyle`, as they are after the change).

**Example**

```freebasic
richedit.RichEdit.SetEditStyle( hCtrl, SES_HYPERLINKTOOLTIPS, SES_HYPERLINKTOOLTIPS )
```

Microsoft Learn: [EM_GETEDITSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/em-geteditstyle), [EM_SETEDITSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/em-seteditstyle)

### GetEditStyleEx, SetEditStyleEx

```freebasic
function GetEditStyleEx( byval hRichEdit as HWND ) as DWORD
function SetEditStyleEx( byval hRichEdit as HWND, byval fStyle as long, byval fMask as long ) as DWORD
```

Read or change the extended edit styles `SES_EX_*` (`SES_EX_NOTABLE`, `SES_EX_HANDLEFRIENDLYURL`,
`SES_EX_MULTITOUCH` …), the styles in `fMask` taking their values from `fStyle`.

**Returns** the extended edit styles.

**Example**

```freebasic
richedit.RichEdit.SetEditStyleEx( hCtrl, SES_EX_HANDLEFRIENDLYURL, SES_EX_HANDLEFRIENDLYURL )
```

Microsoft Learn: [EM_GETEDITSTYLEEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-geteditstyleex), [EM_SETEDITSTYLEEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-seteditstyleex)

### GetTypographyOptions, SetTypographyOptions

```freebasic
function GetTypographyOptions( byval hRichEdit as HWND ) as DWORD
function SetTypographyOptions( byval hRichEdit as HWND, byval pto as long, byval fMask as long ) as long
```

Read or change the typography options: `TO_ADVANCEDTYPOGRAPHY` (line breaking and layout for
complex scripts), `TO_SIMPLELINEBREAK` and others. `SetTypographyOptions` sets the options in
`fMask` to their values in `pto`.

**Returns** (`GetTypographyOptions`) the options; (`SetTypographyOptions`) nonzero on success.

**Example**

```freebasic
richedit.RichEdit.SetTypographyOptions( hCtrl, TO_ADVANCEDTYPOGRAPHY, TO_ADVANCEDTYPOGRAPHY )
```

Microsoft Learn: [EM_GETTYPOGRAPHYOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettypographyoptions), [EM_SETTYPOGRAPHYOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-settypographyoptions)

### AutoUrlDetect, GetAutoUrlDetect

```freebasic
function AutoUrlDetect( byval hRichEdit as HWND, byval fUrlDetect as long ) as long
function GetAutoUrlDetect( byval hRichEdit as HWND ) as long
```

`AutoUrlDetect` turns detection of URLs in the text on or off: 0 turns it off, `AURL_ENABLEURL`
turns it on, and `AURL_ENABLEEMAILADDR`, `AURL_ENABLETELNO`, `AURL_ENABLEEAURLS` and
`AURL_ENABLEDRIVELETTERS` add other kinds of link. Detected links are shown as links; to be told
when one is clicked, add `ENM_LINK` to the event mask. `GetAutoUrlDetect` reads the setting.

**Returns** (`AutoUrlDetect`) 0 on success, otherwise an error code; (`GetAutoUrlDetect`) the
`AURL_*` flags in force, 0 when detection is off.

**Example**

```freebasic
richedit.RichEdit.AutoUrlDetect( hCtrl, AURL_ENABLEURL )
print richedit.RichEdit.GetAutoUrlDetect( hCtrl )   ' 1
```

Microsoft Learn: [EM_AUTOURLDETECT](https://learn.microsoft.com/en-us/windows/win32/controls/em-autourldetect), [EM_GETAUTOURLDETECT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getautourldetect)

### GetEllipsisMode, SetEllipsisMode

```freebasic
function GetEllipsisMode( byval hRichEdit as HWND, byval pmode as DWORD ptr ) as DWORD
function SetEllipsisMode( byval hRichEdit as HWND, byval fMode as DWORD ) as DWORD
```

The ellipsis mode says how text that does not fit is cut: `ELLIPSIS_NONE`, `ELLIPSIS_END` (at
any character) or `ELLIPSIS_WORD` (at a word). `GetEllipsisMode` stores it in `*pmode`;
`SetEllipsisMode` sets it.

**Returns** nonzero on success.

**Example**

```freebasic
dim nMode as DWORD
richedit.RichEdit.SetEllipsisMode( hCtrl, ELLIPSIS_END )
richedit.RichEdit.GetEllipsisMode( hCtrl, @nMode )   ' nMode is ELLIPSIS_END
```

Microsoft Learn: [EM_GETELLIPSISMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getellipsismode), [EM_SETELLIPSISMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setellipsismode)

### GetEllipsisState

```freebasic
function GetEllipsisState( byval hRichEdit as HWND ) as DWORD
```

Tells whether the control is showing an ellipsis now, because text was cut under the
[ellipsis mode](#getellipsismode-setellipsismode).

**Returns** nonzero when an ellipsis is showing.

**Example**

```freebasic
if richedit.RichEdit.GetEllipsisState( hCtrl ) then print "the text is cut"
```

Microsoft Learn: [EM_GETELLIPSISSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getellipsisstate)

### GetTouchOptions, SetTouchOptions

```freebasic
function GetTouchOptions( byval hRichEdit as HWND, byval Options as long ptr ) as DWORD
sub SetTouchOptions( byval hRichEdit as HWND, byval Options as long, byval fEnable as long )
```

Read or set a touch option: `RTO_SHOWHANDLES` (show the touch gripper handles) or
`RTO_DISABLEHANDLES`. `SetTouchOptions` turns `Options` on (`fEnable` nonzero) or off.

`GetTouchOptions` sends `Options` as the option value itself, though it is declared `long ptr`:
pass the option cast, `cast( long ptr, RTO_SHOWHANDLES )`, not the address of a variable.

**Returns** (`GetTouchOptions`) the state of that option.

**Example**

```freebasic
richedit.RichEdit.SetTouchOptions( hCtrl, RTO_SHOWHANDLES, true )
print richedit.RichEdit.GetTouchOptions( hCtrl, cast( long ptr, RTO_SHOWHANDLES ) )
```

Microsoft Learn: [EM_GETTOUCHOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-gettouchoptions), [EM_SETTOUCHOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-settouchoptions)

### GetWordWrapMode, SetWordWrapMode

```freebasic
function GetWordWrapMode( byval hRichEdit as HWND ) as DWORD
function SetWordWrapMode( byval hRichEdit as HWND, byval pvalues as long ) as long
```

Read or set the word-wrap and word-break options for Asian text, as `WBF_*` flags
(`WBF_WORDWRAP`, `WBF_WORDBREAK`, `WBF_OVERFLOW` …). Current rich edit controls report and keep 0
here; whether lines wrap at all is set with [SetTargetDevice](#settargetdevice).

**Returns** (`GetWordWrapMode`) the flags; (`SetWordWrapMode`) the previous flags.

**Example**

```freebasic
dim nWrap as DWORD = richedit.RichEdit.GetWordWrapMode( hCtrl )
```

Microsoft Learn: [EM_GETWORDWRAPMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getwordwrapmode), [EM_SETWORDWRAPMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setwordwrapmode)

### GetWordBreakProc, SetWordBreakProc

```freebasic
function GetWordBreakProc( byval hRichEdit as HWND ) as LONG_PTR
sub SetWordBreakProc( byval hRichEdit as HWND, byval pfn as LONG_PTR )
```

Read or replace the procedure that decides where words break, for word wrap and for moving by
words. The procedure has the `EDITWORDBREAKPROCW` shape: it gets the text, a position, the length
and a `WB_*` code, and returns a position or a flag. `SetWordBreakProc` with 0 restores the
control's own; `GetWordBreakProc` returns 0 while no procedure of yours is set.

**Returns** (`GetWordBreakProc`) the address of the procedure, or 0.

**Example**

```freebasic
' standalone
function SpaceBreak( byval lpch as wstring ptr, byval ichCurrent as long, byval cch as long, byval code as long ) as long
    if code = WB_ISDELIMITER then return iif( lpch[ichCurrent] = 32, 1, 0 )
    return ichCurrent
end function

sub UseSpaceBreak( byval hRich as HWND )
    richedit.RichEdit.SetWordBreakProc( hRich, cast( LONG_PTR, @SpaceBreak ) )
end sub
```

Microsoft Learn: [EM_GETWORDBREAKPROC](https://learn.microsoft.com/en-us/windows/win32/controls/em-getwordbreakproc), [EM_SETWORDBREAKPROC](https://learn.microsoft.com/en-us/windows/win32/controls/em-setwordbreakproc)

### GetWordBreakProcEx, SetWordBreakProcEx

```freebasic
function GetWordBreakProcEx( byval hRichEdit as HWND ) as LONG_PTR
function SetWordBreakProcEx( byval hRichEdit as HWND, byval pfn as LONG_PTR ) as LONG_PTR
```

Read or replace the extended word-break procedure, an older form that gets the character set of
the text as well. Current rich edit controls do not use it; use
[SetWordBreakProc](#getwordbreakproc-setwordbreakproc).

**Returns** (`GetWordBreakProcEx`) the procedure's address, or 0; (`SetWordBreakProcEx`) the
previous one.

**Example**

```freebasic
dim pfnOld as LONG_PTR = richedit.RichEdit.GetWordBreakProcEx( hCtrl )
```

Microsoft Learn: [EM_GETWORDBREAKPROCEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-getwordbreakprocex), [EM_SETWORDBREAKPROCEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-setwordbreakprocex)

### GetAutoCorrectProc, SetAutoCorrectProc

```freebasic
function GetAutoCorrectProc( byval hRichEdit as HWND ) as LONG_PTR
function SetAutoCorrectProc( byval hRichEdit as HWND, byval pfn as LONG_PTR ) as DWORD
```

An autocorrect procedure, of the `AutoCorrectProc` shape, is called as the user types and can
replace the word before the caret. `GetAutoCorrectProc` returns the one installed, or 0.

`SetAutoCorrectProc` sends `pfn` as the message's second parameter (`lParam`), while the control
reads the procedure from the first: the call returns nonzero but installs nothing, and
`GetAutoCorrectProc` still returns 0. To install a procedure, send the message with its address in
`wParam`, as the example does.

**Returns** (`GetAutoCorrectProc`) the procedure's address, or 0; (`SetAutoCorrectProc`) nonzero.

**Example**

```freebasic
' standalone
function NoCorrection( byval langid as LANGID, byval pszBefore as const wstring ptr, byval pszAfter as wstring ptr, byval cchAfter as LONG, byval pcchReplaced as LONG ptr ) as long
    return ATP_NOCHANGE
end function

sub UseAutoCorrect( byval hRich as HWND )
    SendMessageW( hRich, EM_SETAUTOCORRECTPROC, cast( WPARAM, @NoCorrection ), 0 )
    if richedit.RichEdit.GetAutoCorrectProc( hRich ) = cast( LONG_PTR, @NoCorrection ) then print "installed"
end sub
```

Microsoft Learn: [EM_GETAUTOCORRECTPROC](https://learn.microsoft.com/en-us/windows/win32/controls/em-getautocorrectproc), [EM_SETAUTOCORRECTPROC](https://learn.microsoft.com/en-us/windows/win32/controls/em-setautocorrectproc)

### CallAutocorrectProc

```freebasic
function CallAutocorrectProc( byval hRichEdit as HWND, byval char as WCHAR ) as long
```

Calls the installed autocorrect procedure as if the user had typed `char`, provided the text
before the caret is a candidate for correction.

**Returns** nonzero when the procedure was called.

**Example**

```freebasic
richedit.RichEdit.CallAutocorrectProc( hCtrl, 32 )   ' as if a space was typed
```

Microsoft Learn: [EM_CALLAUTOCORRECTPROC](https://learn.microsoft.com/en-us/windows/win32/controls/em-callautocorrectproc)

### GetPunctuation, SetPunctuation

```freebasic
function GetPunctuation( byval hRichEdit as HWND, byval punctype as DWORD, byval lppunct as PUNCTUATION ptr ) as long
function SetPunctuation( byval hRichEdit as HWND, byval punctype as long, byval ppunct as PUNCTUATION ptr ) as long
```

Read or set the punctuation characters used to break Asian text into lines. `punctype` picks the
set (`PC_FOLLOWING`, `PC_LEADING`, `PC_OVERFLOW`, `PC_DELIMITER`); the `PUNCTUATION` structure
holds a buffer (`szPunctuation`) and its size (`iSize`).

**Returns** nonzero on success.

**Example**

```freebasic
dim buf as zstring * 64
dim pu as PUNCTUATION
pu.iSize = sizeof( buf ) : pu.szPunctuation = @buf
richedit.RichEdit.GetPunctuation( hCtrl, PC_FOLLOWING, @pu )
```

Microsoft Learn: [EM_GETPUNCTUATION](https://learn.microsoft.com/en-us/windows/win32/controls/em-getpunctuation), [EM_SETPUNCTUATION](https://learn.microsoft.com/en-us/windows/win32/controls/em-setpunctuation)

### GetPageRotate, SetPageRotate

```freebasic
function GetPageRotate( byval hRichEdit as HWND ) as DWORD
function SetPageRotate( byval hRichEdit as HWND, byval txtlayout as long ) as long
```

Read or set the text layout: `EPR_0` (left to right, top to bottom), `EPR_90`, `EPR_180` or
`EPR_270`. Both are deprecated in Windows and kept for old code.

**Returns** the layout (for `SetPageRotate`, the new one).

**Example**

```freebasic
if richedit.RichEdit.GetPageRotate( hCtrl ) = EPR_0 then print "horizontal text"
```

Microsoft Learn: [EM_GETPAGEROTATE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getpagerotate), [EM_SETPAGEROTATE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setpagerotate)

### GetStoryType, SetStoryType

```freebasic
function GetStoryType( byval hRichEdit as HWND, byval Index as DWORD ) as DWORD
function SetStoryType( byval hRichEdit as HWND, byval Index as long, byval dwType as DWORD ) as DWORD
```

Read or set the type of story `Index` of the document (a story is a separate stream of text, such
as the main text or a footnote).

**Returns** the story type (for `SetStoryType`, the new type).

**Example**

```freebasic
dim nType as DWORD = richedit.RichEdit.GetStoryType( hCtrl, 0 )
```

Microsoft Learn: [EM_GETSTORYTYPE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getstorytype), [EM_SETSTORYTYPE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setstorytype)

### SetUIAName

```freebasic
function SetUIAName( byval hRichEdit as HWND, byval pwszName as wstring ptr ) as DWORD
```

Sets the name that UI Automation, and so a screen reader, reports for the control.

**Returns** nonzero on success.

**Example**

```freebasic
richedit.RichEdit.SetUIAName( hCtrl, "Notes" )
```

Microsoft Learn: [EM_SETUIANAME](https://learn.microsoft.com/en-us/windows/win32/controls/em-setuianame)

### SetPalette

```freebasic
sub SetPalette( byval hRichEdit as HWND, byval newPalette as HPALETTE )
```

Gives the control the palette to draw with on a display with 256 colours or fewer.

**Example**

```freebasic
dim hPal as HPALETTE = CreateHalftonePalette( NULL )
richedit.RichEdit.SetPalette( hCtrl, hPal )
```

Microsoft Learn: [EM_SETPALETTE](https://learn.microsoft.com/en-us/windows/win32/controls/em-setpalette)

### SetOleCallback

```freebasic
function SetOleCallback( byval hRichEdit as HWND, byval pCallback as any ptr ) as long
```

Gives the control an `IRichEditOleCallback` object, through which it asks the program for
storage for embedded objects, its context menu and what may be pasted or dropped. The control
adds a reference of its own. [CRichEditOleCallback](CRichEditOleCallback) is such an object.

**Returns** nonzero on success.

**Example**

```freebasic
dim pCallback as CRichEditOleCallback ptr = new CRichEditOleCallback
richedit.RichEdit.SetOleCallback( hCtrl, pCallback )
```

Microsoft Learn: [EM_SETOLECALLBACK](https://learn.microsoft.com/en-us/windows/win32/controls/em-setolecallback)

### GetOleInterface

```freebasic
function GetOleInterface( byval hRichEdit as HWND, byval ppObject as IUnknown ptr ptr ) as long
```

Stores the control's `IRichEditOle` interface in `*ppObject`; from it the program can reach the
embedded objects and, with `QueryInterface`, the Text Object Model's `ITextDocument`. **Release
the pointer** when done.

**Returns** nonzero on success.

**Example**

```freebasic
dim pUnk as IUnknown ptr
if richedit.RichEdit.GetOleInterface( hCtrl, @pUnk ) then pUnk->lpVtbl->Release( pUnk )
```

Microsoft Learn: [EM_GETOLEINTERFACE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getoleinterface)

### GetZoom, SetZoom

```freebasic
function GetZoom( byval hRichEdit as HWND, byval pzNum as DWORD ptr, byval pzDen as DWORD ptr ) as long
function SetZoom( byval hRichEdit as HWND, byval zNum as DWORD, byval zDen as DWORD ) as long
```

The zoom ratio is `zNum / zDen`, between 1/64 and 64. `SetZoom( hCtrl, 3, 2 )` shows the text at
150 %, and `0, 0` turns zoom off. `GetZoom` stores the two numbers; both are 0 while no zoom is
set.

**Returns** nonzero on success.

**Example**

```freebasic
dim as DWORD zn, zd
richedit.RichEdit.SetZoom( hCtrl, 3, 2 )
richedit.RichEdit.GetZoom( hCtrl, @zn, @zd )   ' 3 and 2
```

Microsoft Learn: [EM_GETZOOM](https://learn.microsoft.com/en-us/windows/win32/controls/em-getzoom), [EM_SETZOOM](https://learn.microsoft.com/en-us/windows/win32/controls/em-setzoom)

### GetFirstVisibleLine

```freebasic
function GetFirstVisibleLine( byval hRichEdit as HWND ) as long
```

Returns the line shown at the top of the control.

**Returns** the line, counted from 0.

**Example**

```freebasic
print "top line"; richedit.RichEdit.GetFirstVisibleLine( hCtrl )
```

Microsoft Learn: [EM_GETFIRSTVISIBLELINE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getfirstvisibleline)

### GetScrollPos, SetScrollPos

```freebasic
function GetScrollPos( byval hRichEdit as HWND, byval lppt as POINT ptr ) as DWORD
function SetScrollPos( byval hRichEdit as HWND, byval pt as POINT ptr ) as DWORD
```

Read or set how far the text is scrolled, as the point of the document, in pixels, shown at the
top-left corner of the control. Save it before reloading the text and set it back afterwards to
keep the view.

**Returns** 1.

**Example**

```freebasic
dim pt as POINT
richedit.RichEdit.GetScrollPos( hCtrl, @pt )
richedit.RichEdit.SetScrollPos( hCtrl, @pt )
```

Microsoft Learn: [EM_GETSCROLLPOS](https://learn.microsoft.com/en-us/windows/win32/controls/em-getscrollpos), [EM_SETSCROLLPOS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setscrollpos)

### LineScroll

```freebasic
function LineScroll( byval hRichEdit as HWND, byval y as long ) as long
```

Scrolls the text vertically by `y` lines: a positive number moves towards the end of the text, so
`LineScroll( hCtrl, 5 )` from the top makes line 5 the first visible line.

**Returns** nonzero for a multiline control.

**Example**

```freebasic
richedit.RichEdit.LineScroll( hCtrl, 5 )
```

Microsoft Learn: [EM_LINESCROLL](https://learn.microsoft.com/en-us/windows/win32/controls/em-linescroll)

### Scroll

```freebasic
function Scroll( byval hRichEdit as HWND, byval nAction as long ) as long
```

Scrolls the text vertically as a scroll bar would: `nAction` is `SB_LINEUP`, `SB_LINEDOWN`,
`SB_PAGEUP` or `SB_PAGEDOWN`.

**Returns** nonzero in the high word on success, with the number of lines scrolled in the low
word.

**Example**

```freebasic
richedit.RichEdit.Scroll( hCtrl, SB_PAGEDOWN )
```

Microsoft Learn: [EM_SCROLL](https://learn.microsoft.com/en-us/windows/win32/controls/em-scroll)

### ScrollCaret

```freebasic
sub ScrollCaret( byval hRichEdit as HWND )
```

Scrolls the text so that the caret can be seen.

**Example**

```freebasic
richedit.RichEdit.SetSel( hCtrl, -1, -1 )
richedit.RichEdit.ScrollCaret( hCtrl )
```

Microsoft Learn: [EM_SCROLLCARET](https://learn.microsoft.com/en-us/windows/win32/controls/em-scrollcaret)

### GetThumb

```freebasic
function GetThumb( byval hRichEdit as HWND ) as long
```

Returns the position of the scroll box in the vertical scroll bar.

**Returns** the position.

**Example**

```freebasic
print "thumb at"; richedit.RichEdit.GetThumb( hCtrl )
```

Microsoft Learn: [EM_GETTHUMB](https://learn.microsoft.com/en-us/windows/win32/controls/em-getthumb)

### ShowScrollBar

```freebasic
sub ShowScrollBar( byval hRichEdit as HWND, byval nScrollBar as DWORD, byval fShow as long )
```

Shows (`fShow` nonzero) or hides the horizontal (`SB_HORZ`) or vertical (`SB_VERT`) scroll bar of
a control created with that scroll bar.

**Example**

```freebasic
richedit.RichEdit.ShowScrollBar( hCtrl, SB_HORZ, false )
```

Microsoft Learn: [EM_SHOWSCROLLBAR](https://learn.microsoft.com/en-us/windows/win32/controls/em-showscrollbar)

### GetRect, SetRect, SetRectNP

```freebasic
sub GetRect( byval hRichEdit as HWND, byval prc as RECT ptr )
sub SetRect( byval hRichEdit as HWND, byval fCoord as long, byval prect as RECT ptr )
sub SetRectNP( byval hRichEdit as HWND, byval fCoord as long, byval prect as RECT ptr )
```

The formatting rectangle is the part of the control the text is laid out in. `GetRect` reads it,
in client coordinates; margins set with [SetMargins](#setmargins) narrow it. `SetRect` sets it
and redraws the control; `SetRectNP` sets it without redrawing. With `fCoord` 0, `prect` is in
client coordinates; with 1 its values are added to the current rectangle. `NULL` restores the
default.

**Example**

```freebasic
dim rc as RECT
richedit.RichEdit.GetRect( hCtrl, @rc )
rc.left += 8 : rc.right -= 8
richedit.RichEdit.SetRect( hCtrl, 0, @rc )
```

Microsoft Learn: [EM_GETRECT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getrect), [EM_SETRECT](https://learn.microsoft.com/en-us/windows/win32/controls/em-setrect), [EM_SETRECTNP](https://learn.microsoft.com/en-us/windows/win32/controls/em-setrectnp)

### SetMargins

```freebasic
sub SetMargins( byval hRichEdit as HWND, byval nMargins as long, byval nWidth as long )
```

Sets the left and right margins, in pixels, and redraws the control. `nMargins` names the
margins to set (`EC_LEFTMARGIN`, `EC_RIGHTMARGIN`); `nWidth` holds the left one in its low word
and the right one in its high word. In a control 400 pixels wide, margins of 10 make the
formatting rectangle run from 10 to 390.

**Example**

```freebasic
richedit.RichEdit.SetMargins( hCtrl, EC_LEFTMARGIN or EC_RIGHTMARGIN, MAKELONG( 10, 10 ) )
```

Microsoft Learn: [EM_SETMARGINS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setmargins)

### SetTargetDevice

```freebasic
function SetTargetDevice( byval hRichEdit as HWND, byval hDC as HDC, byval lnwidth as long ) as long
```

Sets the device and line width the text is laid out for. With `hDC` `NULL`, `lnwidth` 0 wraps
lines at the edge of the control and 1 turns word wrap off. With a printer's device context and a
line width in twips, the text is laid out as it will print.

**Returns** nonzero on success.

**Example**

```freebasic
richedit.RichEdit.SetTargetDevice( hCtrl, NULL, 1 )   ' no word wrap
```

Microsoft Learn: [EM_SETTARGETDEVICE](https://learn.microsoft.com/en-us/windows/win32/controls/em-settargetdevice)

### RequestResize

```freebasic
sub RequestResize( byval hRichEdit as HWND )
```

Makes the control send its parent an `EN_REQUESTRESIZE` notification with the size its contents
need, which a control that grows with its text uses. `ENM_REQUESTRESIZE` must be in the event
mask.

**Example**

```freebasic
richedit.RichEdit.SetEventMask( hCtrl, ENM_REQUESTRESIZE )
richedit.RichEdit.RequestResize( hCtrl )
```

Microsoft Learn: [EM_REQUESTRESIZE](https://learn.microsoft.com/en-us/windows/win32/controls/em-requestresize)

### StreamIn

```freebasic
function StreamIn( byval hRichEdit as HWND, byval psf as long, byval pedst as EDITSTREAM ptr ) as DWORD
```

Replaces the contents, or with `SFF_SELECTION` the selection, with data a callback supplies. `psf`
is the format, `SF_TEXT` or `SF_RTF`, optionally combined with `SF_UNICODE` and `SFF_SELECTION`.
The `EDITSTREAM` holds a value of your own (`dwCookie`) and the callback (`pfnCallback`), which the
control calls again and again with a buffer to fill, until it fills less than was asked or
returns nonzero. Afterwards `dwError` holds the callback's last nonzero return, or 0.

**Returns** the number of characters read.

**Example**

```freebasic
dim rtf as string = "{\rtf1\ansi Memory {\i RTF}}"
dim cd as RICHEDIT_CUSTOMDATA
cd.pData = cast( BYTE ptr, strptr( rtf ) ) : cd.nLen = len( rtf )
dim eds as EDITSTREAM
eds.dwCookie = cast( DWORD_PTR, @cd ) : eds.pfnCallback = cast( EDITSTREAMCALLBACK, @richedit.RichEdit.LoadRtfFromResourceCallback )
richedit.RichEdit.StreamIn( hCtrl, SF_RTF, @eds )   ' the control now reads "Memory RTF"
```

Microsoft Learn: [EM_STREAMIN](https://learn.microsoft.com/en-us/windows/win32/controls/em-streamin), [EditStreamCallback](https://learn.microsoft.com/en-us/windows/win32/api/richedit/nc-richedit-editstreamcallback)

### StreamOut

```freebasic
function StreamOut( byval hRichEdit as HWND, byval psf as long, byval pedst as EDITSTREAM ptr ) as DWORD
```

Hands the contents, or with `SFF_SELECTION` the selection, to a callback in pieces: as plain text
with `SF_TEXT` or as RTF with `SF_RTF`. The callback gets each piece in its buffer, stores how
much it took in `*pcb` and returns 0 to go on.

**Returns** the number of characters written.

**Example**

```freebasic
' standalone
dim shared as string g_rtf

function CollectRtf( byval dwCookie as DWORD_PTR, byval pbBuff as BYTE ptr, byval cb as LONG, byval pcb as LONG ptr ) as DWORD
    dim s as string = space( cb )
    if cb then CopyMemory( strptr( s ), pbBuff, cb )
    g_rtf &= s : *pcb = cb
    return 0
end function

sub SaveRtf( byval hRich as HWND )
    dim eds as EDITSTREAM
    eds.pfnCallback = @CollectRtf
    g_rtf = "" : richedit.RichEdit.StreamOut( hRich, SF_RTF, @eds )   ' g_rtf holds the document as RTF
end sub
```

Microsoft Learn: [EM_STREAMOUT](https://learn.microsoft.com/en-us/windows/win32/controls/em-streamout)

### LoadRtfFromFile

```freebasic
function LoadRtfFromFile( byval hRichEdit as HWND, byref wszFileName as wstring ) as boolean
```

Replaces the contents of the control with an RTF file, streamed in with
[LoadRtfFromFileCallback](#loadrtffromfilecallback). The file is opened for reading, shared with
other readers, and closed again before the function returns.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The path of the `.rtf` file. |

**Returns** `true` when text was read without error; `false` for a `NULL` handle, an empty name,
a file that cannot be opened, or a stream error.

**Example**

```freebasic
if richedit.RichEdit.LoadRtfFromFile( hCtrl, "readme.rtf" ) = false then print "could not load"
```

Microsoft Learn: [EM_STREAMIN](https://learn.microsoft.com/en-us/windows/win32/controls/em-streamin), [CreateFileW](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew)

### LoadRtfFromResource

```freebasic
function LoadRtfFromResource( byval hRichEdit as HWND, byval hInstance as HINSTANCE, byref wszResourceName as wstring ) as boolean
```

Replaces the contents of the control with RTF kept as an `RCDATA` resource of the module
`hInstance`, under the name `wszResourceName`. The data is copied to a buffer and streamed in
with [LoadRtfFromResourceCallback](#loadrtffromresourcecallback).

| Parameter | Meaning |
| --- | --- |
| `hInstance` | The module holding the resource, `GetModuleHandleW( NULL )` for the program itself. |
| `wszResourceName` | The resource's name. |

**Returns** `true` when text was read without error; `false` for a `NULL` handle or instance, an
empty name, a resource that is not found, or a stream error.

**Example**

```freebasic
richedit.RichEdit.LoadRtfFromResource( hCtrl, GetModuleHandleW( NULL ), "HELPTEXT" )
```

Microsoft Learn: [FindResourceW](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-findresourcew), [EM_STREAMIN](https://learn.microsoft.com/en-us/windows/win32/controls/em-streamin)

### LoadRtfFromFileCallback

```freebasic
function LoadRtfFromFileCallback( byval hFile as HANDLE, byval lpBuff as byte ptr, byval cb as long, byval pcb as long ptr ) as UINT
```

The `EditStreamCallback` [LoadRtfFromFile](#loadrtffromfile) uses: it reads up to `cb` bytes from
the open file `hFile` (the `dwCookie` of the `EDITSTREAM`) into `lpBuff` and stores the number
read in `*pcb`. Use it with [StreamIn](#streamin) to read a file you opened yourself, in any
`SF_*` format.

**Returns** 0, or the `GetLastError` code when the read fails.

**Example**

```freebasic
dim hFile as HANDLE = CreateFileW( "notes.txt", GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL )
dim eds as EDITSTREAM
eds.dwCookie = cast( DWORD_PTR, hFile ) : eds.pfnCallback = cast( EDITSTREAMCALLBACK, @richedit.RichEdit.LoadRtfFromFileCallback )
if hFile <> INVALID_HANDLE_VALUE then richedit.RichEdit.StreamIn( hCtrl, SF_TEXT, @eds ) : CloseHandle( hFile )
```

Microsoft Learn: [EditStreamCallback](https://learn.microsoft.com/en-us/windows/win32/api/richedit/nc-richedit-editstreamcallback)

### LoadRtfFromResourceCallback

```freebasic
function LoadRtfFromResourceCallback( byval pCustData as RICHEDIT_CUSTOMDATA ptr, byval lpBuff as byte ptr, byval cb as long, byval pcb as long ptr ) as DWORD
```

The `EditStreamCallback` [LoadRtfFromResource](#loadrtffromresource) uses: it copies the next
`cb` bytes, or what is left, of the block a [RICHEDIT_CUSTOMDATA](#richedit_customdata)
describes (the `dwCookie` of the `EDITSTREAM`) into `lpBuff`, moves `curPos` on and stores the
number copied in `*pcb`. Use it with [StreamIn](#streamin) for RTF or text held in memory.

**Returns** 0 while there was data to copy; 1, with `*pcb` set to 0, once the block is used up.

**Example**

```freebasic
dim buf as string = space( 4 )
dim as long nGot
dim rtf as string = "{\rtf1 abc}"
dim cd as RICHEDIT_CUSTOMDATA
cd.pData = cast( BYTE ptr, strptr( rtf ) ) : cd.nLen = len( rtf )
richedit.RichEdit.LoadRtfFromResourceCallback( @cd, cast( BYTE ptr, strptr( buf ) ), 4, @nGot )   ' buf is "{\rt", nGot 4
```

Microsoft Learn: [EditStreamCallback](https://learn.microsoft.com/en-us/windows/win32/api/richedit/nc-richedit-editstreamcallback)

### EnumFontFamProcW

```freebasic
function EnumFontFamProcW( byval lpelf as ENUMLOGFONTW ptr, byval lpntm as NEWTEXTMETRICW ptr, byval FontType as long, byval lplf as LOGFONTW ptr ) as long
```

The font enumeration callback [SetFont](#setfont) uses. It copies the character set, pitch and
family and face name of the first font enumerated into the `LOGFONTW` passed as the
enumeration's `lParam`, and returns 0 to stop the enumeration there.

**Returns** 0.

**Example**

```freebasic
dim lf as LOGFONTW
dim hdc as HDC = GetDC( NULL )
EnumFontFamiliesW( hdc, "Consolas", cast( FONTENUMPROCW, @richedit.RichEdit.EnumFontFamProcW ), cast( LPARAM, @lf ) )
ReleaseDC( NULL, hdc )   ' lf.lfFaceName is "Consolas" when the font is installed
```

Microsoft Learn: [EnumFontFamiliesW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-enumfontfamiliesw)

### FormatRange

```freebasic
function FormatRange( byval hRichEdit as HWND, byval fRender as long, byval lpfr as ..FORMATRANGE ptr ) as DWORD
```

Lays out a range of the text for a device, usually a printer, and with `fRender` nonzero draws
it. The `FORMATRANGE` names the device context to draw on (`hdc`) and to measure for
(`hdcTarget`), the area to draw in (`rc`) and the whole page (`rcPage`), both in twips, and the
range (`chrg`). Call it page after page, starting each from the value the last call returned.
Afterwards call it once with `lpfr` `NULL` to free what the control cached.

**Returns** the position of the first character that did not fit, where the next page starts.

**Example**

```freebasic
dim hdcPrn as HDC = GetDC( NULL )   ' a printer DC in a real program
dim fr as FORMATRANGE
fr.hdc = hdcPrn : fr.hdcTarget = hdcPrn
fr.rc.right = 12240 : fr.rc.bottom = 15840 : fr.rcPage = fr.rc   ' 8.5 x 11 inches in twips
fr.chrg.cpMin = 0 : fr.chrg.cpMax = -1
dim nNext as long = richedit.RichEdit.FormatRange( hCtrl, true, @fr )
richedit.RichEdit.FormatRange( hCtrl, false, NULL ) : ReleaseDC( NULL, hdcPrn )
```

Microsoft Learn: [EM_FORMATRANGE](https://learn.microsoft.com/en-us/windows/win32/controls/em-formatrange)

### DisplayBand

```freebasic
function DisplayBand( byval hRichEdit as HWND, byval lprc as RECT ptr ) as long
```

Draws part of the text that [FormatRange](#formatrange) laid out with `fRender` 0, into the
rectangle `lprc` (in device units). Used to print a page in bands.

**Returns** nonzero on success.

**Example**

```freebasic
dim rc as RECT
rc.right = 600 : rc.bottom = 200
richedit.RichEdit.DisplayBand( hCtrl, @rc )
```

Microsoft Learn: [EM_DISPLAYBAND](https://learn.microsoft.com/en-us/windows/win32/controls/em-displayband)

### IsIME

```freebasic
function IsIME( byval hRichEdit as HWND ) as long
```

Tells whether the current input locale is East Asian, which uses an input method editor (IME).

**Returns** nonzero for an East Asian input locale.

**Example**

```freebasic
if richedit.RichEdit.IsIME( hCtrl ) then print "an IME is in use"
```

Microsoft Learn: [EM_ISIME](https://learn.microsoft.com/en-us/windows/win32/controls/em-isime)

### GetIMECompMode

```freebasic
function GetIMECompMode( byval hRichEdit as HWND ) as DWORD
```

Returns the IME composition mode: `ICM_NOTOPEN` (0) when no IME is open, otherwise an `ICM_*`
value.

**Returns** the mode.

**Example**

```freebasic
if richedit.RichEdit.GetIMECompMode( hCtrl ) = ICM_NOTOPEN then print "no IME open"
```

Microsoft Learn: [EM_GETIMECOMPMODE](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimecompmode)

### GetIMECompText

```freebasic
function GetIMECompText( byval hRichEdit as HWND, byval lpict as IMECOMPTEXT ptr, byval buffer as any ptr ) as DWORD
```

Copies the text the IME is composing into `buffer`. In the `IMECOMPTEXT`, `cb` is the buffer size
in bytes and `flags` is `ICT_RESULTREADSTR`.

**Returns** the number of characters copied.

**Example**

```freebasic
dim buf as wstring * 256
dim ict as IMECOMPTEXT
ict.cb = sizeof( buf ) : ict.flags = ICT_RESULTREADSTR
richedit.RichEdit.GetIMECompText( hCtrl, @ict, @buf )
```

Microsoft Learn: [EM_GETIMECOMPTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimecomptext)

### GetIMEColor, SetIMEColor

```freebasic
function GetIMEColor( byval hRichEdit as HWND, byval rgCmpclr as COMPCOLOR ptr ) as long
function SetIMEColor( byval hRichEdit as HWND, byval pcompcolor as COMPCOLOR ptr ) as long
```

Read or set the colours of IME composition text: an array of four `COMPCOLOR`, one per stage of
composition, each with text and background colours and effects.

**Returns** nonzero on success.

**Example**

```freebasic
dim cc( 0 to 3 ) as COMPCOLOR
richedit.RichEdit.GetIMEColor( hCtrl, @cc( 0 ) )
```

Microsoft Learn: [EM_GETIMECOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimecolor), [EM_SETIMECOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/em-setimecolor)

### GetIMEModeBias, SetIMEModeBias

```freebasic
function GetIMEModeBias( byval hRichEdit as HWND ) as DWORD
function SetIMEModeBias( byval hRichEdit as HWND, byval nModeBias as long ) as long
```

Read or set the IME mode bias, the kind of input the IME should expect (`IMF_SMODE_PLAURALCLAUSE`,
`IMF_SMODE_NONE`). `SetIMEModeBias` sends `nModeBias` as both the bias and the mask of bits to
change.

**Returns** the mode bias (for `SetIMEModeBias`, the new one).

**Example**

```freebasic
richedit.RichEdit.SetIMEModeBias( hCtrl, IMF_SMODE_PLAURALCLAUSE )
```

Microsoft Learn: [EM_GETIMEMODEBIAS](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimemodebias), [EM_SETIMEMODEBIAS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setimemodebias)

### GetIMEOptions, SetIMEOptions

```freebasic
function GetIMEOptions( byval hRichEdit as HWND ) as DWORD
function SetIMEOptions( byval hRichEdit as HWND, byval fCoop as long, byval fOptions as long ) as long
```

Read or change the `IMF_*` IME options (`IMF_FORCEENABLE`, `IMF_CLOSESTATUSWINDOW` …); `fCoop`
says how `fOptions` combines with the current ones: `ECOOP_SET`, `ECOOP_OR`, `ECOOP_AND` or
`ECOOP_XOR`.

**Returns** (`GetIMEOptions`) the options; (`SetIMEOptions`) nonzero on success.

**Example**

```freebasic
richedit.RichEdit.SetIMEOptions( hCtrl, ECOOP_OR, IMF_CLOSESTATUSWINDOW )
```

Microsoft Learn: [EM_GETIMEOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimeoptions), [EM_SETIMEOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setimeoptions)

### GetIMEProperty

```freebasic
function GetIMEProperty( byval hRichEdit as HWND, byval figp as DWORD ) as DWORD
```

Returns a property of the IME of the current input locale; `figp` picks which: `IGP_PROPERTY`,
`IGP_CONVERSION`, `IGP_SENTENCE`, `IGP_UI`, `IGP_SETCOMPSTR`, `IGP_SELECT` or `IGP_GETIMEVERSION`.

**Returns** the property's value.

**Example**

```freebasic
dim nProps as DWORD = richedit.RichEdit.GetIMEProperty( hCtrl, IGP_PROPERTY )
```

Microsoft Learn: [EM_GETIMEPROPERTY](https://learn.microsoft.com/en-us/windows/win32/controls/em-getimeproperty)

### GetLangOptions, SetLangOptions

```freebasic
function GetLangOptions( byval hRichEdit as HWND ) as DWORD
function SetLangOptions( byval hRichEdit as HWND, byval lgoptions as long ) as DWORD
```

Read or set the options for IMEs and for text in several languages: `IMF_AUTOFONT` (switch fonts
when the keyboard language changes), `IMF_AUTOKEYBOARD`, `IMF_DUALFONT`, `IMF_UIFONTS` …
`SetLangOptions` replaces them all; `or` with `GetLangOptions` to add one.

**Returns** (`GetLangOptions`) the options; (`SetLangOptions`) nonzero.

**Example**

```freebasic
richedit.RichEdit.SetLangOptions( hCtrl, richedit.RichEdit.GetLangOptions( hCtrl ) and not IMF_AUTOFONT )
```

Microsoft Learn: [EM_GETLANGOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-getlangoptions), [EM_SETLANGOPTIONS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setlangoptions)

### GetCTFModeBias, SetCTFModeBias

```freebasic
function GetCTFModeBias( byval hRichEdit as HWND ) as long
function SetCTFModeBias( byval hRichEdit as HWND, byval nModeBias as long ) as long
```

Read or set the Text Services Framework mode bias, the kind of input expected: `CTFMODEBIAS_DEFAULT`,
`CTFMODEBIAS_FILENAME`, `CTFMODEBIAS_NAME`, `CTFMODEBIAS_NUMERIC` and others.

**Returns** the mode bias (for `SetCTFModeBias`, the new one).

**Example**

```freebasic
richedit.RichEdit.SetCTFModeBias( hCtrl, CTFMODEBIAS_NUMERIC )
```

Microsoft Learn: [EM_GETCTFMODEBIAS](https://learn.microsoft.com/en-us/windows/win32/controls/em-getctfmodebias), [EM_SETCTFMODEBIAS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setctfmodebias)

### GetCTFOpenStatus, SetCTFOpenStatus

```freebasic
function GetCTFOpenStatus( byval hRichEdit as HWND ) as long
function SetCTFOpenStatus( byval hRichEdit as HWND, byval fTSFkbd as long ) as DWORD
```

Read whether the Text Services Framework keyboard is open, or open (`fTSFkbd` nonzero) or close
it.

**Returns** (`GetCTFOpenStatus`) nonzero when it is open; (`SetCTFOpenStatus`) nonzero on
success.

**Example**

```freebasic
if richedit.RichEdit.GetCTFOpenStatus( hCtrl ) then richedit.RichEdit.SetCTFOpenStatus( hCtrl, false )
```

Microsoft Learn: [EM_GETCTFOPENSTATUS](https://learn.microsoft.com/en-us/windows/win32/controls/em-getctfopenstatus), [EM_SETCTFOPENSTATUS](https://learn.microsoft.com/en-us/windows/win32/controls/em-setctfopenstatus)

### Reconversion

```freebasic
function Reconversion( byval hRichEdit as HWND ) as DWORD
```

Opens the IME reconversion dialog for the selected text.

**Returns** 0.

**Example**

```freebasic
richedit.RichEdit.Reconversion( hCtrl )
```

Microsoft Learn: [EM_RECONVERSION](https://learn.microsoft.com/en-us/windows/win32/controls/em-reconversion)

### RICHEDIT_CUSTOMDATA

```freebasic
type RICHEDIT_CUSTOMDATA
   pData  as byte ptr
   nLen   as long
   curPos as long
end type
```

Describes a block of data in memory for [LoadRtfFromResourceCallback](#loadrtffromresourcecallback):
`pData` points to the data, `nLen` is its length in bytes and `curPos` how much has been read so
far, 0 to start. The type is declared outside the `RichEdit` namespace: after `using richedit`
it is written `RICHEDIT_CUSTOMDATA`. The data must stay in place until the stream ends.

**Example**

```freebasic
dim rtf as string = "{\rtf1 Hello}"
dim cd as RICHEDIT_CUSTOMDATA
cd.pData = cast( BYTE ptr, strptr( rtf ) ) : cd.nLen = len( rtf ) : cd.curPos = 0
```

## See also

- [sys/win/richedit](SysWin-RichEdit) for the module and its three ways of working with a rich edit control
- [CRichEditCtx](CRichEditCtx), the class that creates a rich edit control and wraps these messages as members
- [CRichEditCtx: editing](CRichEditCtx-Editing) and [CRichEditCtx: document](CRichEditCtx-Document)
- [Text Object Model](SysWin-RichEdit-TOM) and [CTextRange2](CTextRange2) for formatting through TOM
- [CRichEditOleCallback](CRichEditOleCallback) for [SetOleCallback](#setolecallback)
- [Edit](SysWin-Gui-Edit) for the plain edit control's functions
- [CWindow](CWindow) for `AddControl( "RichEdit", ... )`
