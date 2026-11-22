[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/richedit](SysWin-RichEdit) › [CRichEditCtx](CRichEditCtx) › **CRichEditCtx: files, formatting and the document**

# CRichEditCtx: files, formatting and the document
Loads, saves and formats rich edit text, and drives its Text Object Model document.

<!-- scope: CRichEditCtx -->

Loads, saves and formats rich edit text, and drives its Text Object Model document.

These are the members of [CRichEditCtx](CRichEditCtx) that move text in and out of the control,
change the look of the selected text, and wrap the control's `ITextDocument2` interface. The
constructor, the destructor and the message wrappers are on [CRichEditCtx](CRichEditCtx) and
[CRichEditCtx: editing](CRichEditCtx-Editing).

The members fall into three groups:

| Group | Works through | Members |
| --- | --- | --- |
| Files and streams | `EM_STREAMIN`, `EM_STREAMOUT`, `EM_SETTEXTEX` and plain file I/O | [SetFont](#setfont) to [SaveSelText](#saveseltext) |
| Formatting the selection | `EM_GETCHARFORMAT` / `EM_SETCHARFORMAT` | [TextColor](#textcolor-gettextcolor-settextcolor) to [TextFontName](#textfontname-gettextfontname-settextfontname) |
| The TOM document | the `ITextDocument2` interface the class holds | [GetDocumentInterface](#getdocumentinterface) to [NewStory](#newstory-getnewstory) |

Things to know:

- **The selection, or the word at the caret.** The formatting members act on the selected text.
  When nothing is selected they act on the word the caret is in.
- **Units.** Font sizes and offsets are in points, positions are character positions counted
  from 0. Inside the control a paragraph ends with a single `CR`; text read back with the `Text`
  property has `CR LF` at the end of each paragraph.
- **Result codes.** Most members store their result in the object; read it with
  `GetLastResult()` and turn it into text with `GetErrorInfo()` (see
  [CRichEditCtx](CRichEditCtx)). For the file members it is a Windows error code, for the TOM
  members an `HRESULT`.
- **What must be released.** The class holds one `ITextDocument2` pointer for its whole life and
  releases it in its destructor. Every interface pointer a member here **returns** (a story, a
  range, the selection, a font, `GetDocumentInterface` itself) is a new reference: release it
  with `SafeRelease( p )` from `sys/win/com` when done. A member that **takes** a pointer does
  not keep yours.
- **Automatic saving.** [NewDoc](#newdoc) and [OpenDoc](#opendoc) first write unsaved changes
  of the current document back to its file, if it has one.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/com"
#import "sys/win/richedit"
using win, gui, com, richedit
```

The examples below find the class from the control's handle with
`CRichEditCtxPtr( hCtrl )`; in your own code you usually have the `CRichEditCtx` variable
itself.

## Example

A notes window. It opens `notes.rtf` next to the program if it is there; **Bold** and **Red**
format the selected text (or the word at the caret) and **Save** writes the notes back as RTF:

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/com"
#import "sys/win/richedit"
using win, gui, com, richedit

const IDC_RICHEDIT = 1001
const IDC_BOLD = 1002
const IDC_RED = 1003
const IDC_SAVE = 1004

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "NotesDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Notes", @WndProc )
    SetWindowClientSizeForDpi( hWin, 520, 320 )
    CenterWindow( hWin )
    dim pRichEdit as CRichEditCtx = CRichEditCtx( @pWindow, IDC_RICHEDIT, "", 10, 10, 500, 260 )
    dim dv as DVARIANT = GetExePath() & "\notes.rtf"
    if pRichEdit.OpenDoc( dv, tomOpenExisting or tomRTF ) <> S_OK then
        pRichEdit.SetText( "Select a word, press Bold or Red, then Save." )
        pRichEdit.SetFont( "Segoe UI", 11 )
    end if
    pWindow.AddControl( "Button", hWin, IDC_BOLD, "&Bold", 10, 280, 80, 28 )
    pWindow.AddControl( "Button", hWin, IDC_RED, "&Red", 100, 280, 80, 28 )
    pWindow.AddControl( "Button", hWin, IDC_SAVE, "&Save", 430, 280, 80, 28 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hwnd, IDC_RICHEDIT )
            if pRichEdit <> NULL andalso CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                select case CBCTL( wParam, lParam )
                    case IDC_BOLD
                        pRichEdit->SetTextBold()
                    case IDC_RED
                        pRichEdit->SetTextColor( RGB_RED )
                    case IDC_SAVE
                        dim dv as DVARIANT = GetExePath() & "\notes.rtf"
                        if pRichEdit->SaveDoc( dv, tomCreateAlways or tomRTF ) = S_OK then
                            SetWindowText( hwnd, "Notes - saved" )
                        end if
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

When `OpenDoc` fails the control is left empty, which is why the text and font are set after it.

## Members

| Member | Does |
| --- | --- |
| [CRichEditCtxEnumFontFamProcW](#cricheditctxenumfontfamprocw) | Font enumeration callback used by `SetFont`. |
| [SetFont](#setfont) | Sets the face and size of all the text. |
| [CRichEditCtxGetTextCallback](#cricheditctxgettextcallback) | Stream-out callback used by `GetRtf`. |
| [GetRtf](#getrtf) | Returns the contents, or the selection, as RTF or text. |
| [CRichEditCtxLoadRtfFromResourceCallback](#cricheditctxloadrtffromresourcecallback) | Stream-in callback that reads a block of memory. |
| [LoadRtfFromResource](#loadrtffromresource) | Replaces the contents with an RTF resource of the program. |
| [GetTextFromFile](#gettextfromfile) | Reads a whole file into a `string`. |
| [AppendDocFile](#appenddocfile) | Adds an RTF or text file at the end of the text. |
| [InsertDocFile](#insertdocfile) | Inserts an RTF or text file at a position or at the caret. |
| [InsertObject](#insertobject) | Inserts a file as an embedded OLE object. |
| [AddLF, AddCR, AddCRLF](#addlf-addcr-addcrlf) | Starts a new paragraph at the caret or at the end. |
| [SaveRtf](#savertf) | Saves the contents to an RTF file. |
| [SaveRtfNoObjs](#savertfnoobjs) | Saves the contents to RTF, without embedded objects. |
| [SaveSelRtf](#saveselrtf) | Saves the selection to an RTF file. |
| [SaveSelRtfNoObjs](#saveselrtfnoobjs) | Saves the selection to RTF, without embedded objects. |
| [SaveText](#savetext) | Saves the text to a UTF-8 file. |
| [SaveSelText](#saveseltext) | Saves the selected text to a UTF-8 file. |
| [TextColor, GetTextColor, SetTextColor](#textcolor-gettextcolor-settextcolor) | Reads or sets the colour of the selected text. |
| [IsTextBold](#istextbold) | Tells whether the selected text is bold. |
| [SetTextBold](#settextbold) | Turns bold on or off for the selected text. |
| [IsTextItalic](#istextitalic) | Tells whether the selected text is italic. |
| [SetTextItalic](#settextitalic) | Turns italic on or off for the selected text. |
| [IsTextStrikeout](#istextstrikeout) | Tells whether the selected text is struck out. |
| [SetTextStrikeout](#settextstrikeout) | Turns strikeout on or off for the selected text. |
| [IsTextUnderline](#istextunderline) | Tells whether the selected text is underlined. |
| [SetTextUnderline](#settextunderline) | Turns underlining on or off for the selected text. |
| [TextHeight, GetTextHeight, SetTextHeight](#textheight-gettextheight-settextheight) | Reads or sets the font size of the selected text. |
| [TextOffset, GetTextOffset, SetTextOffset](#textoffset-gettextoffset-settextoffset) | Reads or sets how far the selected text is raised or lowered. |
| [TextFontName, GetTextFontName, SetTextFontName](#textfontname-gettextfontname-settextfontname) | Reads or sets the face name of the selected text. |
| [GetDocumentInterface](#getdocumentinterface) | Returns a new `ITextDocument2` pointer for the control. |
| [NewDoc](#newdoc) | Closes the current document and starts an empty one. |
| [OpenDoc](#opendoc) | Opens an RTF or text file as the document. |
| [SaveDoc](#savedoc) | Saves the document as RTF or text. |
| [DocName, GetDocName](#docname-getdocname) | Returns the file name of the document. |
| [Selection, GetSelection](#selection-getselection) | Returns the active selection as `ITextSelection`. |
| [Selection2, GetSelection2](#selection2-getselection2) | Returns the active selection as `ITextSelection2`. |
| [StoryCount, GetStoryCount](#storycount-getstorycount) | Returns the number of stories in the document. |
| [GetStoryRanges](#getstoryranges) | Returns the collection of stories. |
| [GetStoryRanges2](#getstoryranges2) | Returns the collection of stories, version 2. |
| [Saved, GetSaved, SetSaved](#saved-getsaved-setsaved) | Reads or sets whether the document has unsaved changes. |
| [DefaultTabStop, GetDefaultTabStop, SetDefaultTabStop](#defaulttabstop-getdefaulttabstop-setdefaulttabstop) | Reads or sets the default tab width. |
| [Freeze](#freeze) | Stops the control from repainting. |
| [Unfreeze](#unfreeze) | Lets the control repaint again. |
| [BeginEditCollection](#begineditcollection) | Starts collecting edits into one undo step. |
| [EndEditCollection](#endeditcollection) | Ends the undo step started by `BeginEditCollection`. |
| [Range](#range) | Returns a text range of the active story. |
| [RangeFromPoint](#rangefrompoint) | Returns the empty range at a point on the screen. |
| [CaretType, GetCaretType, SetCaretType](#carettype-getcarettype-setcarettype) | Reads or sets the kind of caret. |
| [GetDisplays](#getdisplays) | Returns the displays collection. |
| [DocumentFont, GetDocumentFont, SetDocumentFont](#documentfont-getdocumentfont-setdocumentfont) | Reads or sets the default character format. |
| [DocumentPara, GetDocumentPara, SetDocumentPara](#documentpara-getdocumentpara-setdocumentpara) | Reads or sets the default paragraph format. |
| [EastAsianFlags, GetEastAsianFlags](#eastasianflags-geteastasianflags) | Returns the East Asian and text-flow flags. |
| [GetGenerator](#getgenerator) | Returns the name and version of the text engine. |
| [SetIMEInProgress](#setimeinprogress) | Sets the input-method-in-progress flag. |
| [NotificationMode, GetNotificationMode, SetNotificationMode](#notificationmode-getnotificationmode-setnotificationmode) | Reads or sets whether TOM notifications are sent. |
| [GetWindow](#getwindow) | Returns the window the engine draws in. |
| [AttachMsgFilter](#attachmsgfilter) | Attaches a message filter to the control. |
| [CheckTextLimit](#checktextlimit) | Tells how many characters would go over the text limit. |
| [GetCallManager](#getcallmanager) | Returns the engine's call manager. |
| [GetClientRect](#getclientrect) | Returns the client rectangle of the control. |
| [EffectColor, GetEffectColor, SetEffectColor](#effectcolor-geteffectcolor-seteffectcolor) | Reads or sets the colours used for underlines. |
| [GetPreferredFont](#getpreferredfont) | Returns the font the engine would pick for a script and position. |
| [GetImmContext](#getimmcontext) | Returns the input method context. |
| [GetProperty](#getproperty) | Reads a document property. |
| [SetProperty](#setproperty) | Sets a document property. |
| [GetStrings](#getstrings) | Returns a collection of rich-text strings. |
| [Notify](#notify) | Passes an input method event to the engine. |
| [ReleaseCallManager](#releasecallmanager) | Releases the call manager. |
| [ReleaseImmContext](#releaseimmcontext) | Releases an input method context. |
| [SysBeep](#sysbeep) | Plays the system beep. |
| [Update](#update) | Updates the selection and the caret. |
| [UpdateWindow](#updatewindow) | Asks the host to repaint the view. |
| [MathProperties, GetMathProperties, SetMathProperties](#mathproperties-getmathproperties-setmathproperties) | Reads or sets the document's math options. |
| [GetStory](#getstory) | Returns a story by index. |
| [ActiveStory, GetActiveStory, SetActiveStory](#activestory-getactivestory-setactivestory) | Reads or sets the story that gets keyboard and mouse input. |
| [MainStory, GetMainStory](#mainstory-getmainstory) | Returns the main story. |
| [NewStory, GetNewStory](#newstory-getnewstory) | Asks for a new story. |

## Reference

### CRichEditCtxEnumFontFamProcW

```freebasic
static function CRichEditCtxEnumFontFamProcW( byval lpelf as ENUMLOGFONTW ptr, byval lpntm as NEWTEXTMETRICW ptr, byval FontType as long, byval lplf as LOGFONTW ptr ) as long
```

The callback [SetFont](#setfont) passes to `EnumFontFamiliesW`. For the first font of the family
it copies the character set, the pitch and family, and the face name into the `LOGFONTW` whose
address was given as the enumeration's `lParam`, then stops the enumeration. You only call it
yourself to look a font family up the same way.

| Parameter | Meaning |
| --- | --- |
| `lpelf` | The font Windows found. |
| `lpntm` | Its metrics; ignored. |
| `FontType` | Its type; ignored. |
| `lplf` | The `LOGFONTW` to fill: the `lParam` given to `EnumFontFamiliesW`. |

**Returns** 0, which ends the enumeration after the first font.

**Example**

```freebasic
dim lf as LOGFONTW
dim face as wstring * 32 = "consolas"
dim hdc as HDC = GetDC( NULL )
EnumFontFamiliesW( hdc, @face, cast(FONTENUMPROCW, @CRichEditCtx.CRichEditCtxEnumFontFamProcW), cast(LPARAM, @lf) )
ReleaseDC( NULL, hdc )   ' lf.lfFaceName is now "Consolas"
```

Microsoft Learn: [EnumFontFamiliesW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-enumfontfamiliesw)

### SetFont

```freebasic
function SetFont( byref wszFaceName as wstring, byval ptsize as long ) as HRESULT
```

Sets the font of **all** the text: the face, the size in points, and the character set and pitch
Windows reports for that face. Bold, italic, underline and strikeout
are switched off for the whole text at the same time.

If no font of that name is installed the face is left blank and the control substitutes one of
its own choosing.

| Parameter | Meaning |
| --- | --- |
| `wszFaceName` | The font face, e.g. `"Segoe UI"`. |
| `ptsize` | The size in points. |

**Returns** what `EM_SETCHARFORMAT` returns: 1 on success, 0 on failure. Despite the `HRESULT`
type, 1 here means success, not `S_FALSE`. `GetLastResult()` holds the same value.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetFont( "Segoe UI", 11 )
```

Microsoft Learn: [EM_SETCHARFORMAT](https://learn.microsoft.com/en-us/windows/win32/controls/em-setcharformat)

### CRichEditCtxGetTextCallback

```freebasic
static function CRichEditCtxGetTextCallback( byval dwCookie as DWORD_PTR, byval pbBuff as byte ptr, byval cb as long, byval pcb as long ptr ) as DWORD
```

The `EM_STREAMOUT` callback [GetRtf](#getrtf) uses. `dwCookie` is the address of a `string`; each
call appends the `cb` bytes the control hands over to it and reports them all as taken.

| Parameter | Meaning |
| --- | --- |
| `dwCookie` | The `dwCookie` of the `EDITSTREAM`: the address of the `string` to append to. |
| `pbBuff` | The bytes the control is writing out. |
| `cb` | How many bytes there are. |
| `pcb` | Receives `cb`. |

**Returns** 0, so the stream continues to the end.

**Example**

```freebasic
dim s as string
dim es as EDITSTREAM
es.dwCookie = cast(DWORD_PTR, @s)
es.pfnCallback = cast(EDITSTREAMCALLBACK, @CRichEditCtx.CRichEditCtxGetTextCallback)
SendMessageW( hCtrl, EM_STREAMOUT, SF_TEXT, cast(LPARAM, @es) )
print s
```

Microsoft Learn: [EditStreamCallback](https://learn.microsoft.com/en-us/windows/win32/api/richedit/nc-richedit-editstreamcallback)

### GetRtf

```freebasic
function GetRtf( byval dwOptionsAndFlags as DWORD = SF_RTF ) as string
```

Streams the contents of the control out with `EM_STREAMOUT` and returns the bytes in a `string`.
Despite the name it returns plain text too, depending on the format asked for:

| Format | Returns |
| --- | --- |
| `SF_RTF` (the default) | RTF, embedded objects included. |
| `SF_RTFNOOBJS` | RTF with a space in place of each embedded object. |
| `SF_TEXT` | Plain text in the ANSI code page; characters it cannot hold become `?`. |
| `SF_TEXTIZED` | Plain text with a text form of each embedded object. |

Add `SFF_SELECTION` for the selection only, `SFF_PLAINRTF` to leave out language-specific RTF
keywords, `SF_UNICODE` with `SF_TEXT` for UTF-16 bytes, or `SF_USECODEPAGE` with a code page in
the high word, e.g. `(CP_UTF8 shl 16) or SF_USECODEPAGE or SF_TEXT` for UTF-8.

**Returns** the bytes, or `""` for an empty control. `GetLastResult()` is set to 0 whatever
happens.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim strRtf as string = pRichEdit->GetRtf()                  ' "{\rtf1..."
print pRichEdit->GetRtf( SF_TEXT or SFF_SELECTION )         ' the selected text
```

Microsoft Learn: [EM_STREAMOUT](https://learn.microsoft.com/en-us/windows/win32/controls/em-streamout)

### CRichEditCtxLoadRtfFromResourceCallback

```freebasic
static function CRichEditCtxLoadRtfFromResourceCallback( byval pCustData as CRichEditCtx_CUSTOMDATA ptr, byval lpBuff as byte ptr, byval cb as long, byval pcb as long ptr ) as DWORD
```

The `EM_STREAMIN` callback [LoadRtfFromResource](#loadrtffromresource) uses. It feeds the
control from a block of memory described by a `CRichEditCtx_CUSTOMDATA`, at most `cb` bytes per
call, and moves `curPos` on by what it copied:

| Field of `CRichEditCtx_CUSTOMDATA` | Meaning |
| --- | --- |
| `pData as byte ptr` | The first byte of the data. |
| `nLen as long` | How many bytes there are. |
| `curPos as long` | How many have been read so far; start it at 0. |

| Parameter | Meaning |
| --- | --- |
| `pCustData` | The `dwCookie` of the `EDITSTREAM`: the address of the `CRichEditCtx_CUSTOMDATA`. |
| `lpBuff` | Where to copy the next bytes. |
| `cb` | How many bytes fit. |
| `pcb` | Receives how many were copied; 0 at the end. |

**Returns** 0 while there was data to copy, 1 once everything has been read.

**Example**

```freebasic
dim rtf as string = "{\rtf1 Hello \b RTF\b0}"
dim cd as CRichEditCtx_CUSTOMDATA
cd.pData = strptr( rtf ) : cd.nLen = len( rtf )
dim es as EDITSTREAM
es.dwCookie = cast(DWORD_PTR, @cd)
es.pfnCallback = cast(EDITSTREAMCALLBACK, @CRichEditCtx.CRichEditCtxLoadRtfFromResourceCallback)
SendMessageW( hCtrl, EM_STREAMIN, SF_RTF, cast(LPARAM, @es) )   ' the control shows "Hello RTF"
```

Microsoft Learn: [EM_STREAMIN](https://learn.microsoft.com/en-us/windows/win32/controls/em-streamin)

### LoadRtfFromResource

```freebasic
function LoadRtfFromResource( byref wszResourceName as wstring ) as boolean
```

Replaces the whole contents of the control with an RTF document stored as an `RCDATA` resource in
the program (the module whose instance handle the parent `CWindow` holds). Put the file in the
resource script and build the script with the program, e.g. `NOTES RCDATA "notes.rtf"` in
`notes.rc` and `tiko notes.tiko notes.rc`; see [Resources](SysWin-Resources).

RTF that holds pictures or other embedded objects needs an OLE callback set first with
`SetOleCallback` (see [CRichEditOleCallback](CRichEditOleCallback)).

| Parameter | Meaning |
| --- | --- |
| `wszResourceName` | The name of the resource. |

**Returns** `true` on success. On failure `false`, and `GetLastResult()` is the Windows error:
1814 (`ERROR_RESOURCE_NAME_NOT_FOUND`) when there is no resource of that name, 1812 when the
program has no resources at all, or the stream's error code.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->LoadRtfFromResource( "NOTES" ) = false then print pRichEdit->GetErrorInfo()
```

Microsoft Learn: [FindResourceW](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-findresourcew)

### GetTextFromFile

```freebasic
function GetTextFromFile( byref wszFileName as wstring ) as string
```

Reads a whole file into a `string`, byte for byte: no code-page conversion, and a byte-order mark
is kept. [AppendDocFile](#appenddocfile) and [InsertDocFile](#insertdocfile) use it; it does not
touch the control.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The path of the file. |

**Returns** the contents or "" on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim strData as string = pRichEdit->GetTextFromFile( GetExePath() & "\notes.rtf" )
if left( strData, 5 ) = "{\rtf" then print "an RTF file"
```

Microsoft Learn: [ReadFile](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile)

### AppendDocFile

```freebasic
function AppendDocFile( byref wszFileName as wstring, byval CodePage as DWORD = CP_ACP ) as DWORD
```

Adds the contents of a file at the end of the text. The caret moves to the end and the file is
inserted there with `EM_SETTEXTEX`, so it can be undone. An RTF file is recognised by its
`{\rtf` start and read as RTF; any other file is read as text in `CodePage`.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The path of the file. |
| `CodePage` | The code page of a text file: `CP_ACP` (the default, the ANSI code page), `CP_UTF8` or 1200 for UTF-16. |

A UTF-16 file's byte-order mark is inserted as a character, and a file read with the wrong code
page comes in garbled or cut short.

**Returns** the number of characters inserted, or 0 on failure. `GetLastResult()` is then 2
when the file could not be read (or is empty) and `E_FAIL` when the control refused the text.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->AppendDocFile( GetExePath() & "\chapter2.rtf" )
pRichEdit->AppendDocFile( GetExePath() & "\readme.txt", CP_UTF8 )
```

Microsoft Learn: [EM_SETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-settextex)

### InsertDocFile

```freebasic
function InsertDocFile( byref wszFileName as wstring, byval nPos as DWORD, byval CodePage as DWORD = CP_ACP ) as DWORD
```

Inserts the contents of a file at a character position, the same way as
[AppendDocFile](#appenddocfile): RTF as RTF, anything else as text in `CodePage`, undoable.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The path of the file. |
| `nPos` | The character position to insert at; the caret is moved there. Pass -1 to insert at the caret. |
| `CodePage` | The code page of a text file, as for `AppendDocFile`. |

**Returns** the number of characters inserted, or 0 on failure, with `GetLastResult()` as for
`AppendDocFile`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->InsertDocFile( GetExePath() & "\header.rtf", 0 )      ' at the start
pRichEdit->InsertDocFile( GetExePath() & "\snippet.txt", -1 )    ' at the caret
```

Microsoft Learn: [EM_SETTEXTEX](https://learn.microsoft.com/en-us/windows/win32/controls/em-settextex)

### InsertObject

```freebasic
function InsertObject( byref wszFileName as wstring ) as boolean
```

Replaces the selection with the file as an embedded OLE object, created by the file's registered
OLE server, resizable by the user. When the file is an image whose size can be read, the object
starts at that size multiplied by the control's `ScalingRatio`.

The object is drawn by its server: an image that is not a bitmap shows as an icon. To show a
picture, use `InsertImage` (see [CRichEditCtx: editing](CRichEditCtx-Editing)). Creating OLE
objects needs OLE initialised on the thread with `OleInitialize( NULL )`.

When it fails part of the way through, the interfaces it obtained up to that point are not
released.

| Parameter | Meaning |
| --- | --- |
| `wszFileName` | The path of the file. |

**Returns** `true` on success. On failure `false`, and `GetLastResult()` is the `HRESULT`, e.g.
`&h80030002` (`STG_E_FILENOTFOUND`) for a missing file.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->InsertObject( GetExePath() & "\budget.xlsx" ) = false then print pRichEdit->GetErrorInfo()
```

Microsoft Learn: [IRichEditOle::InsertObject](https://learn.microsoft.com/en-us/windows/win32/api/richole/nf-richole-iricheditole-insertobject)

### AddLF, AddCR, AddCRLF

```freebasic
sub AddLF( byval atEnd as boolean = false )
sub AddCR( byval atEnd as boolean = false )
sub AddCRLF( byval atEnd as boolean = false )
```

Insert a line feed, a carriage return, or both, replacing the selection, which can be undone.
The control turns each of the three into one paragraph mark, so all three start a new paragraph.

| Parameter | Meaning |
| --- | --- |
| `atEnd` | `true` to add it at the end of the text instead of at the caret. |

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->AddCRLF( true )   ' a new paragraph after the last one
```

Microsoft Learn: [EM_REPLACESEL](https://learn.microsoft.com/en-us/windows/win32/controls/em-replacesel)

### SaveRtf

```freebasic
function SaveRtf( byref wszFilename as wstring, byval Overwrite as boolean = false, byval dwFlagsAndAttributes as DWORD = FILE_ATTRIBUTE_NORMAL ) as boolean
```

Writes the whole contents, as RTF with embedded objects, to a file. It is the same as writing out
`GetRtf( SF_RTF )`; it does not change the document's name or its `Saved` state (for that, see
[SaveDoc](#savedoc)).

| Parameter | Meaning |
| --- | --- |
| `wszFilename` | The path of the file. |
| `Overwrite` | `true` to replace a file that exists. With `false` (the default) an existing file is left alone and the call fails. |
| `dwFlagsAndAttributes` | File attributes and flags for `CreateFileW`; `FILE_ATTRIBUTE_NORMAL` by default. |

**Returns** `true` on success. On failure `false`, and `GetLastResult()` is the Windows error,
80 (`ERROR_FILE_EXISTS`) when the file exists and `Overwrite` is `false`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->SaveRtf( GetExePath() & "\notes.rtf", true ) = false then print pRichEdit->GetErrorInfo()
```

Microsoft Learn: [CreateFileW](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew)

### SaveRtfNoObjs

```freebasic
function SaveRtfNoObjs( byref wszFilename as wstring, byval Overwrite as boolean = false, byval dwFlagsAndAttributes as DWORD = FILE_ATTRIBUTE_NORMAL ) as boolean
```

Like [SaveRtf](#savertf), but writes a space in place of each embedded object
(`SF_RTFNOOBJS`), which keeps the file small when the program stores its objects elsewhere.

**Returns** `true` on success; on failure `false`, and `GetLastResult()` says why.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SaveRtfNoObjs( GetExePath() & "\notes.rtf", true )
```

### SaveSelRtf

```freebasic
function SaveSelRtf( byref wszFilename as wstring, byval Overwrite as boolean = false, byval dwFlagsAndAttributes as DWORD = FILE_ATTRIBUTE_NORMAL ) as boolean
```

Like [SaveRtf](#savertf), but writes only the selection.

**Returns** `true` on success; on failure `false`, and `GetLastResult()` says why.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SaveSelRtf( GetExePath() & "\clip.rtf", true )
```

### SaveSelRtfNoObjs

```freebasic
function SaveSelRtfNoObjs( byref wszFilename as wstring, byval Overwrite as boolean = false, byval dwFlagsAndAttributes as DWORD = FILE_ATTRIBUTE_NORMAL ) as boolean
```

Like [SaveRtfNoObjs](#savertfnoobjs), but writes only the selection.

**Returns** `true` on success; on failure `false`, and `GetLastResult()` says why.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SaveSelRtfNoObjs( GetExePath() & "\clip.rtf", true )
```

### SaveText

```freebasic
function SaveText( byref wszFilename as wstring, byval Overwrite as boolean = false, byval dwFlagsAndAttributes as DWORD = FILE_ATTRIBUTE_NORMAL ) as boolean
```

Writes the text of the control, without formatting, to a file as UTF-8 without a byte-order mark.
Paragraphs end with `CR LF`. The parameters are those of [SaveRtf](#savertf).

**Returns** `true` on success; on failure `false`, and `GetLastResult()` says why.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SaveText( GetExePath() & "\notes.txt", true )
```

### SaveSelText

```freebasic
function SaveSelText( byref wszFilename as wstring, byval Overwrite as boolean = false, byval dwFlagsAndAttributes as DWORD = FILE_ATTRIBUTE_NORMAL ) as boolean
```

Writes the selected text, without formatting, to a file as UTF-8 without a byte-order mark. The
parameters are those of [SaveRtf](#savertf).

**Returns** `true` on success; on failure `false`, and `GetLastResult()` says why. With nothing
selected the file is created empty.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SaveSelText( GetExePath() & "\clip.txt", true )
```

### TextColor, GetTextColor, SetTextColor

```freebasic
property TextColor() as COLORREF
property TextColor( byval crTxtColor as COLORREF )
function GetTextColor() as COLORREF
function SetTextColor( byval crTxtColor as COLORREF ) as boolean
```

Read or set the colour of the selected text, or of the word at the caret. The value is a GDI
`COLORREF`, red in the low byte, as the `RGB_*` constants of `sys/win/gui` are.

| Parameter | Meaning |
| --- | --- |
| `crTxtColor` | The new colour. |

**Returns** (get) the colour; (`SetTextColor`) `true` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->TextColor = RGB_RED
print hex( pRichEdit->GetTextColor() )   ' FF
```

Microsoft Learn: [CHARFORMATW](https://learn.microsoft.com/en-us/windows/win32/api/richedit/ns-richedit-charformatw)

### IsTextBold

```freebasic
function IsTextBold() as boolean
```

Tells whether the selected text, or the word at the caret, is bold.

**Returns** `true` when it is bold.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->IsTextBold() then print "bold"
```

### SetTextBold

```freebasic
sub SetTextBold()
```

Makes the selected text, or the word at the caret, bold, or plain again if it was bold: calling it
twice gives back what was there.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetSel( 0, 5 )
pRichEdit->SetTextBold()
```

### IsTextItalic

```freebasic
function IsTextItalic() as boolean
```

Tells whether the selected text, or the word at the caret, is italic.

**Returns** `true` when it is italic.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->IsTextItalic() then print "italic"
```

### SetTextItalic

```freebasic
sub SetTextItalic()
```

Makes the selected text, or the word at the caret, italic, or upright again if it was italic.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetTextItalic()
```

### IsTextStrikeout

```freebasic
function IsTextStrikeout() as boolean
```

Tells whether the selected text, or the word at the caret, is struck out.

**Returns** `true` when it is struck out.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->IsTextStrikeout() then print "struck out"
```

### SetTextStrikeout

```freebasic
sub SetTextStrikeout()
```

Strikes out the selected text, or the word at the caret, or removes the strikeout if it was
there.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetTextStrikeout()
```

### IsTextUnderline

```freebasic
function IsTextUnderline() as boolean
```

Tells whether the selected text, or the word at the caret, is underlined.

**Returns** `true` when it is underlined.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->IsTextUnderline() then print "underlined"
```

### SetTextUnderline

```freebasic
sub SetTextUnderline()
```

Underlines the selected text, or the word at the caret, or removes the underline if it was there.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetTextUnderline()
```

### TextHeight, GetTextHeight, SetTextHeight

```freebasic
property TextHeight() as long
property TextHeight( byval ptSize as long )
function GetTextHeight() as long
function SetTextHeight( byval ptSize as long ) as boolean
```

Read or set the font size, in whole points, of the selected text or the word at the caret.

| Parameter | Meaning |
| --- | --- |
| `ptSize` | The new size in points. |

**Returns** (get) the size in points, rounded to a whole number; (`SetTextHeight`) `true` on
success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetTextHeight( 14 )
print pRichEdit->TextHeight   ' 14
```

### TextOffset, GetTextOffset, SetTextOffset

```freebasic
property TextOffset() as long
property TextOffset( byval offset as long )
function GetTextOffset() as long
function SetTextOffset( byval offset as long ) as boolean
```

Read or set how far the selected text, or the word at the caret, sits above (positive) or below
(negative) the baseline, in whole points.

| Parameter | Meaning |
| --- | --- |
| `offset` | The offset in points: positive raises the text, negative lowers it. |

**Returns** (get) the offset in points; (`SetTextOffset`) `true` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetTextOffset( 3 )    ' raise by 3 points
pRichEdit->TextOffset = -2       ' lower by 2 points
```

### TextFontName, GetTextFontName, SetTextFontName

```freebasic
property TextFontName() as ustring
property TextFontName( byref wszFaceName as wstring )
function GetTextFontName() as ustring
function SetTextFontName( byref wszFaceName as wstring ) as boolean
```

Read or set the font face of the selected text, or of the word at the caret. Only the face
changes; size and effects stay.

Give the property form a `wstring` or `ustring` value. A narrow string literal assigned to it
(`TextFontName = "Arial"`) reaches the control unconverted and comes out as unreadable
characters; use `SetTextFontName( "Arial" )` for a literal.

| Parameter | Meaning |
| --- | --- |
| `wszFaceName` | The new face name, at most 31 characters. |

**Returns** (get) the face name; (`SetTextFontName`) `true` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetTextFontName( "Consolas" )
print pRichEdit->TextFontName   ' Consolas
```

### GetDocumentInterface

```freebasic
function GetDocumentInterface() as ITextDocument2 ptr
```

Returns a pointer to the control's `ITextDocument2` interface, the Text Object Model document the
rest of this page wraps. The constructor calls it once and keeps that pointer; each further call
returns a **new reference**, which you release.

**Returns** the interface, or `NULL` if the control has none.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pDoc as ITextDocument2 ptr = pRichEdit->GetDocumentInterface()
' ... call pDoc->lpvtbl->... directly
SafeRelease( pDoc )
```

Microsoft Learn: [ITextDocument2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nn-tom-itextdocument2)

### NewDoc

```freebasic
function NewDoc() as HRESULT
```

Closes the current document and starts an empty one with no name. If the current document came
from a file and has unsaved changes, they are written to that file first.

**Returns** `S_OK` on success, otherwise an `HRESULT` error.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->NewDoc()
```

Microsoft Learn: [ITextDocument::New](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-new)

### OpenDoc

```freebasic
function OpenDoc( byval pVar as VARIANT ptr, byval Flags as long = 0, byval CodePage as long = CP_ACP ) as HRESULT
function OpenDoc( byref v as DVARIANT, byval Flags as long = 0, byval CodePage as long = CP_ACP ) as HRESULT
```

Closes the current document, as [NewDoc](#newdoc) does (saving its changes to its file), and
loads a file in its place. The file's path becomes the document's name ([DocName](#docname-getdocname))
and the document counts as saved. A `ustring` path converts to the `DVARIANT` by itself.

If the file cannot be opened the call fails and the control is left empty.

| Parameter | Meaning |
| --- | --- |
| `pVar`, `v` | The path of the file. |
| `Flags` | 0 (the default) to recognise RTF by its content, or `tomRTF` / `tomText`; add `tomOpenExisting` to fail when the file is missing, `tomOpenAlways` to create it, `tomReadOnly` to open it read-only. |
| `CodePage` | The code page of a text file: `CP_ACP` (the default), `CP_UTF8`, or 1200 for UTF-16. A file that starts with a UTF-16 byte-order mark is read as UTF-16. |

**Returns** `S_OK` on success, otherwise an `HRESULT` error, e.g. `&h80070002` for a missing
file.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim dv as DVARIANT = GetExePath() & "\notes.rtf"
if pRichEdit->OpenDoc( dv ) <> S_OK then print pRichEdit->GetErrorInfo()
pRichEdit->OpenDoc( GetExePath() & "\readme.txt", tomText, CP_UTF8 )
```

Microsoft Learn: [ITextDocument::Open](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-open)

### SaveDoc

```freebasic
function SaveDoc( byval pVar as VARIANT ptr, byval Flags as long = tomRTF, byval CodePage as long = CP_ACP ) as HRESULT
function SaveDoc( byref dv as DVARIANT, byval Flags as long = tomRTF, byval CodePage as long = CP_ACP ) as HRESULT
```

Saves the document to a file. A path given here becomes the document's new name; pass `NULL`
through the `VARIANT ptr` form to save under the current name. Afterwards the document counts as
saved.

| Parameter | Meaning |
| --- | --- |
| `pVar`, `dv` | The path to save to, or `NULL` for the document's own name. |
| `Flags` | `tomRTF` (the default) or `tomText`, plus `tomCreateAlways` to replace an existing file or `tomCreateNew` to fail if it exists. |
| `CodePage` | For `tomText`: `CP_ACP` (the default), `CP_UTF8`, or 1200 for UTF-16 (written with a byte-order mark). |

**Returns** `S_OK` on success, otherwise an `HRESULT` error.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim dv as DVARIANT = GetExePath() & "\notes.rtf"
pRichEdit->SaveDoc( dv, tomCreateAlways or tomRTF )
pRichEdit->SaveDoc( cast(VARIANT ptr, NULL) )   ' again, under the same name
```

Microsoft Learn: [ITextDocument::Save](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-save)

### DocName, GetDocName

```freebasic
function DocName() as ustring
function GetDocName() as ustring
```

Return the full path of the file the document was opened from or last saved to.

**Returns** the path, or `""` for a document that has no file (`GetLastResult()` is then
`S_FALSE`).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print "editing "; pRichEdit->DocName()
```

Microsoft Learn: [ITextDocument::GetName](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-getname)

### Selection, GetSelection

```freebasic
function Selection() as ITextSelection ptr
function GetSelection() as ITextSelection ptr
```

Return the active selection as a TOM `ITextSelection`: a range that follows what the user
selects. Release it when done.

**Returns** the selection, or `NULL` when there is none (`GetLastResult()` is then `S_FALSE`).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pSel as ITextSelection ptr = pRichEdit->Selection()
dim nStart as long
if pSel then pSel->lpvtbl->GetStart( pSel, @nStart ) : SafeRelease( pSel )
```

Microsoft Learn: [ITextDocument::GetSelection](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-getselection)

### Selection2, GetSelection2

```freebasic
function Selection2() as ITextSelection2 ptr
function GetSelection2() as ITextSelection2 ptr
```

Return the active selection as an `ITextSelection2`, which adds the TOM 2 range methods. Release
it when done; [CTextSelection2](CTextSelection2) wraps it.

**Returns** the selection, or `NULL`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pSel as ITextSelection2 ptr = pRichEdit->GetSelection2()
dim nEnd as long
if pSel then pSel->lpvtbl->GetEnd( pSel, @nEnd ) : SafeRelease( pSel )
```

Microsoft Learn: [ITextDocument2::GetSelection2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getselection2)

### StoryCount, GetStoryCount

```freebasic
function StoryCount() as long
function GetStoryCount() as long
```

Return how many stories the document has. A story is one run of text with its own formatting,
such as the main text; a plain rich edit control has one.

**Returns** the number of stories.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print pRichEdit->StoryCount()   ' 1
```

Microsoft Learn: [ITextDocument::GetStoryCount](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-getstorycount)

### GetStoryRanges

```freebasic
function GetStoryRanges() as ITextStoryRanges ptr
```

Returns the collection of the document's stories, one range per story. Release it when done.

**Returns** the collection, or `NULL` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pStories as ITextStoryRanges ptr = pRichEdit->GetStoryRanges()
if pStories then SafeRelease( pStories )
```

Microsoft Learn: [ITextDocument::GetStoryRanges](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-getstoryranges)

### GetStoryRanges2

```freebasic
function GetStoryRanges2() as ITextStoryRanges2 ptr
```

Returns the story collection as an `ITextStoryRanges2`, whose items are `ITextRange2` ranges.
Release it when done.

**Returns** the collection, or `NULL` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pStories as ITextStoryRanges2 ptr = pRichEdit->GetStoryRanges2()
dim n as long
if pStories then pStories->lpvtbl->GetCount( pStories, @n ) : SafeRelease( pStories )
```

Microsoft Learn: [ITextDocument2::GetStoryRanges2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getstoryranges2)

### Saved, GetSaved, SetSaved

```freebasic
property Saved() as boolean
property Saved( byval value as boolean )
function GetSaved() as boolean
function SetSaved( byval value as boolean ) as HRESULT
```

Read or set whether the document is unchanged since it was opened or saved. It is `false` in a
new control, becomes `true` after [OpenDoc](#opendoc) or [SaveDoc](#savedoc) and `false` again as
soon as the text changes. Setting it does not save anything; it only changes the flag.

| Parameter | Meaning |
| --- | --- |
| `value` | `true` to mark the document as saved, `false` as changed. |

**Returns** (get) `true` when there are no unsaved changes; (`SetSaved`) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->Saved = false then pRichEdit->SaveDoc( cast(VARIANT ptr, NULL) )
```

Microsoft Learn: [ITextDocument::GetSaved](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-getsaved)

### DefaultTabStop, GetDefaultTabStop, SetDefaultTabStop

```freebasic
property DefaultTabStop() as single
property DefaultTabStop( byval Value as single )
function GetDefaultTabStop() as single
function SetDefaultTabStop( byval Value as single = 36.0 ) as HRESULT
```

Read or set the distance between the default tab stops, in points, used wherever a paragraph
sets no tab stop of its own. It starts at 36 points (half an inch).

| Parameter | Meaning |
| --- | --- |
| `Value` | The width in points; `SetDefaultTabStop` with no argument restores 36. |

**Returns** (get) the width; (`SetDefaultTabStop`) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->DefaultTabStop = 72   ' one inch
```

Microsoft Learn: [ITextDocument::SetDefaultTabStop](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-setdefaulttabstop)

### Freeze

```freebasic
function Freeze() as long
```

Adds one to the freeze count. While the count is above zero the control does not repaint, so a
run of changes shows at once, without flicker, when the last [Unfreeze](#unfreeze) brings it back
to zero.

**Returns** the new freeze count.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->Freeze()
pRichEdit->AppendDocFile( GetExePath() & "\log.txt" )
pRichEdit->Unfreeze()
```

Microsoft Learn: [ITextDocument::Freeze](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-freeze)

### Unfreeze

```freebasic
function Unfreeze() as long
```

Takes one from the freeze count; at zero the control repaints again. The count does not go below
zero.

**Returns** the new freeze count.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->Unfreeze() = 0 then print "repainting again"
```

Microsoft Learn: [ITextDocument::Unfreeze](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-unfreeze)

### BeginEditCollection

```freebasic
function BeginEditCollection() as HRESULT
```

Starts collecting the edits that follow into one undo step, until
[EndEditCollection](#endeditcollection): one undo then takes them all back.

**Returns** `S_OK` on success, `S_FALSE` when undo is turned off.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->BeginEditCollection()
pRichEdit->AddCRLF( true )
pRichEdit->AppendDocFile( GetExePath() & "\footer.rtf" )
pRichEdit->EndEditCollection()
```

Microsoft Learn: [ITextDocument::BeginEditCollection](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-begineditcollection)

### EndEditCollection

```freebasic
function EndEditCollection() as HRESULT
```

Ends the undo step started by [BeginEditCollection](#begineditcollection).

**Returns** `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->EndEditCollection()
```

Microsoft Learn: [ITextDocument::EndEditCollection](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument-endeditcollection)

### Range

```freebasic
function Range( byval cpActive as long = 0, byval cpAnchor as long = 0 ) as ITextRange2 ptr
```

Returns a new text range over the characters between two positions of the active story. A range
is independent of the selection; release it when done, or wrap it in
[CTextRange2](CTextRange2).

| Parameter | Meaning |
| --- | --- |
| `cpActive` | The active end of the range. |
| `cpAnchor` | The other end. With both 0 (the default) the range is empty, at the start. |

**Returns** the range, or `NULL` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pRange as ITextRange2 ptr = pRichEdit->Range( 0, 5 )   ' the first five characters
if pRange then pRange->lpvtbl->Select( pRange ) : SafeRelease( pRange )
```

Microsoft Learn: [ITextDocument2::Range2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-range2)

### RangeFromPoint

```freebasic
function RangeFromPoint( byval x as long, byval y as long, byval nType as long ) as ITextRange2 ptr
```

Returns the empty range at, or nearest to, a point on the screen: the place a click there would
put the caret. Release it when done.

| Parameter | Meaning |
| --- | --- |
| `x`, `y` | The point, in screen coordinates. |
| `nType` | How the point is aligned to the character: `tomStart` or `tomEnd` plus `TA_*` flags, as for `ITextRange::GetPoint`. |

**Returns** the range, or `NULL` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pt as POINT
GetCursorPos( @pt )
dim pRange as ITextRange2 ptr = pRichEdit->RangeFromPoint( pt.x, pt.y, tomStart or TA_TOP or TA_LEFT )
if pRange then SafeRelease( pRange )
```

Microsoft Learn: [ITextDocument2::RangeFromPoint2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-rangefrompoint2)

### CaretType, GetCaretType, SetCaretType

```freebasic
property CaretType() as long
property CaretType( byval Value as long ) as HRESULT
function GetCaretType() as long
function SetCaretType( byval Value as long ) as HRESULT
```

Read or set the kind of caret: `tomNormalCaret` (0, the default), `tomKoreanBlockCaret` or
`tomNullCaret` (no caret at all).

The second `CaretType` is declared with a result, which makes it an indexed read rather than a
setter: write `pRichEdit->CaretType( tomNullCaret )`, which sets the type and returns the
`HRESULT`, or `SetCaretType`. The assignment form `CaretType = value` does not work with this
declaration.

| Parameter | Meaning |
| --- | --- |
| `Value` | The caret type. |

**Returns** (get) the caret type; (set) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetCaretType( tomNullCaret )   ' hide the caret
print pRichEdit->CaretType                ' 2
```

Microsoft Learn: [ITextDocument2::SetCaretType](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-setcarettype)

### GetDisplays

```freebasic
function GetDisplays() as ITextDisplays ptr
```

Asks for the engine's collection of displays. The rich edit control does not implement it.

**Returns** `NULL`, with `GetLastResult()` `E_NOTIMPL` (`&h80004001`).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->GetDisplays() = NULL then print hex( pRichEdit->GetLastResult() )   ' 80004001
```

Microsoft Learn: [ITextDocument2::GetDisplays](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getdisplays)

### DocumentFont, GetDocumentFont, SetDocumentFont

```freebasic
property DocumentFont() as ITextFont2 ptr
property DocumentFont( byval pFont as ITextFont2 ptr )
function GetDocumentFont() as ITextFont2 ptr
function SetDocumentFont( byval pFont as ITextFont2 ptr ) as HRESULT
```

Read or set the document's default character format, as a TOM font object. The getter returns a
new object you release; change it, then pass it back to the setter to apply it.
[CTextFont2](CTextFont2) wraps it.

| Parameter | Meaning |
| --- | --- |
| `pFont` | The new default format. It is read, not kept. |

**Returns** (get) the font object, or `NULL`; (`SetDocumentFont`) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pFont as ITextFont2 ptr = pRichEdit->DocumentFont
pFont->lpvtbl->SetSize( pFont, 12 )
pRichEdit->DocumentFont = pFont
SafeRelease( pFont )
```

Microsoft Learn: [ITextDocument2::GetDocumentFont](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getdocumentfont)

### DocumentPara, GetDocumentPara, SetDocumentPara

```freebasic
property DocumentPara() as ITextPara2 ptr
property DocumentPara( byval pTextPara as ITextPara2 ptr )
function GetDocumentPara() as ITextPara2 ptr
function SetDocumentPara( byval pTextPara as ITextPara2 ptr ) as HRESULT
```

Read or set the document's default paragraph format, as a TOM paragraph object, the same way as
[DocumentFont](#documentfont-getdocumentfont-setdocumentfont). [CTextPara2](CTextPara2) wraps it.

| Parameter | Meaning |
| --- | --- |
| `pTextPara` | The new default format. It is read, not kept. |

**Returns** (get) the paragraph object, or `NULL`; (`SetDocumentPara`) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pPara as ITextPara2 ptr = pRichEdit->GetDocumentPara()
pPara->lpvtbl->SetSpaceAfter( pPara, 6 )
pRichEdit->SetDocumentPara( pPara )
SafeRelease( pPara )
```

Microsoft Learn: [ITextDocument2::GetDocumentPara](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getdocumentpara)

### EastAsianFlags, GetEastAsianFlags

```freebasic
function EastAsianFlags() as long
function GetEastAsianFlags() as long
```

Return the document's East Asian flags: the text-flow direction (`tomTextFlowMask`), whether
`@` fonts are used for vertical text, password and input method settings.

**Returns** the flags; 0 for ordinary left-to-right horizontal text.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print hex( pRichEdit->EastAsianFlags() )   ' 0
```

Microsoft Learn: [ITextDocument2::GetEastAsianFlags](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-geteastasianflags)

### GetGenerator

```freebasic
function GetGenerator() as ustring
```

Returns the name and version of the text engine behind the control.

**Returns** the name, for example `Riched20 10.0.26100`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print pRichEdit->GetGenerator()
```

Microsoft Learn: [ITextDocument2::GetGenerator](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getgenerator)

### SetIMEInProgress

```freebasic
function SetIMEInProgress( byval Value as long ) as HRESULT
```

Turns the engine's input-method-in-progress flag on (`tomTrue`) or off (`tomFalse`). A host that
runs an input method editor itself uses it.

**Returns** `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetIMEInProgress( tomFalse )
```

Microsoft Learn: [ITextDocument2::SetIMEInProgress](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-setimeinprogress)

### NotificationMode, GetNotificationMode, SetNotificationMode

```freebasic
property NotificationMode() as long
property NotificationMode( byval Value as long )
function GetNotificationMode() as long
function SetNotificationMode( byval Value as long ) as HRESULT
```

Read or set whether the engine sends its TOM notifications: `tomTrue` (the default) or
`tomFalse`.

| Parameter | Meaning |
| --- | --- |
| `Value` | `tomTrue` or `tomFalse`. |

**Returns** (get) `tomTrue` or `tomFalse`; (`SetNotificationMode`) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->NotificationMode = tomFalse
```

Microsoft Learn: [ITextDocument2::SetNotificationMode](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-setnotificationmode)

### GetWindow

```freebasic
function GetWindow() as __int64
```

Returns the handle of the window the engine draws in; for this class it is the control itself,
the same as `hRichEdit`.

**Returns** the handle as a 64-bit integer; `cast` it to `HWND`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim hDraw as HWND = cast(HWND, pRichEdit->GetWindow())
```

Microsoft Learn: [ITextDocument2::GetWindow](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getwindow)

### AttachMsgFilter

```freebasic
function AttachMsgFilter( byval pFilter as IUnknown ptr ) as HRESULT
```

Attaches a message filter, an object that implements `ITextMsgFilter`: every window message the
control receives goes to the filter first. `pFilter` must be a real object; `NULL` is not
accepted.

| Parameter | Meaning |
| --- | --- |
| `pFilter` | The filter object. |

**Returns** `S_OK` on success, otherwise an `HRESULT` error.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pFilter as IUnknown ptr    ' your ITextMsgFilter object
if pFilter then pRichEdit->AttachMsgFilter( pFilter )
```

Microsoft Learn: [ITextDocument2::AttachMsgFilter](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-attachmsgfilter)

### CheckTextLimit

```freebasic
function CheckTextLimit( byval cch as long ) as long
```

Tells whether `cch` more characters would fit under the control's text limit (32,767 characters
unless `LimitText` raised it).

| Parameter | Meaning |
| --- | --- |
| `cch` | The number of characters you want to add. |

**Returns** how many of them would go over the limit, or 0 when they all fit.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->CheckTextLimit( 50000 ) > 0 then pRichEdit->LimitText = 1000000
```

Microsoft Learn: [ITextDocument2::CheckTextLimit](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-checktextlimit)

### GetCallManager

```freebasic
function GetCallManager() as IUnknown ptr
```

Returns the engine's call manager, an opaque object the engine uses for some internal
notifications. The rich edit control returns `NULL`.

**Returns** the call manager, or `NULL`; give one you get back with
[ReleaseCallManager](#releasecallmanager).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pMgr as IUnknown ptr = pRichEdit->GetCallManager()
if pMgr then pRichEdit->ReleaseCallManager( pMgr )
```

Microsoft Learn: [ITextDocument2::GetCallManager](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getcallmanager)

### GetClientRect

```freebasic
function GetClientRect( byval nType as long, byref Left as long, byref Top as long, byref Right as long, byref Bottom as long ) as HRESULT
function GetClientRect( byval nType as long ) as .RECT
```

Return the control's client rectangle, either into four variables or as a `RECT`.

| Parameter | Meaning |
| --- | --- |
| `nType` | `tomClientCoord` for client coordinates, otherwise screen coordinates; add `tomIncludeInset` to take the control's insets off, `tomTransform` to apply the host's world transform. |
| `Left`, `Top`, `Right`, `Bottom` | Receive the edges. |

**Returns** (first form) `S_OK` on success; (second form) the rectangle, with the `HRESULT` in
`GetLastResult()`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim rc as RECT = pRichEdit->GetClientRect( tomClientCoord )
print rc.right - rc.left; " x"; rc.bottom - rc.top
```

Microsoft Learn: [ITextDocument2::GetClientRect](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getclientrect)

### EffectColor, GetEffectColor, SetEffectColor

```freebasic
property EffectColor( byval Index as long ) as ULONG
property EffectColor( byval Index as long, byval Value as ULONG )
function GetEffectColor( byval Index as long ) as ULONG
function SetEffectColor( byval Index as long, byval Value as ULONG ) as HRESULT
```

Read or set one of the colours the document uses for special text attributes. Index 0 is the
text colour; 1 to 16 are the colours an underline can be given, which start as the 16 standard
colours (black, blue, cyan, green, magenta, red, yellow, white, then the dark ones and two greys).

| Parameter | Meaning |
| --- | --- |
| `Index` | Which colour. |
| `Value` | The new colour as a `COLORREF`. In the property form it is the assigned value: `EffectColor( 2 ) = RGB_RED`. |

**Returns** (get) the colour; (`SetEffectColor`) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
print hex( pRichEdit->EffectColor( 2 ) )   ' FF0000, blue
pRichEdit->EffectColor( 2 ) = RGB_RED
```

Microsoft Learn: [ITextDocument2::SetEffectColor](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-seteffectcolor)

### GetPreferredFont

```freebasic
function GetPreferredFont( byval cp as long, byval CharRep as long, byval nOptions as long, byval curCharRep as long, byval curFontSize as long, byref ustrFontName as ustring, byref PitchAndFamily as long, byref NewFontSize as long ) as HRESULT
```

Asks the engine which font it would use for a character repertoire (a script) at a character
position: the font-binding choice it makes when text in another script is typed.

| Parameter | Meaning |
| --- | --- |
| `cp` | The character position. |
| `CharRep` | The character repertoire wanted, e.g. `tomAnsi`, `tomCyrillic`, `tomGreek`. |
| `nOptions` | `tomMatchCharRep`, `tomMatchFontSignature`, `tomIgnoreCurrentFont` …; `tomUseTwips` in the high word gives sizes in twips. |
| `curCharRep` | The repertoire of the current font. |
| `curFontSize` | The current font size. |
| `ustrFontName` | Receives the face name. |
| `PitchAndFamily` | Receives the pitch and family. |
| `NewFontSize` | Receives the size. |

**Returns** `S_OK` on success, otherwise an `HRESULT` error.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim as ustring face
dim as long pitch, size
pRichEdit->GetPreferredFont( 0, tomAnsi, 0, tomAnsi, 11, face, pitch, size )
print face; size
```

Microsoft Learn: [ITextDocument2::GetPreferredFont](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getpreferredfont)

### GetImmContext

```freebasic
function GetImmContext() as __int64
```

Returns the input method context the host gives the engine. Release one you get with
[ReleaseImmContext](#releaseimmcontext).

**Returns** the context, or 0 when there is none (`GetLastResult()` is then `S_FALSE`).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim ctx as __int64 = pRichEdit->GetImmContext()
if ctx then pRichEdit->ReleaseImmContext( ctx )
```

Microsoft Learn: [ITextDocument2::GetImmContext](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getimmcontext)

### GetProperty

```freebasic
function GetProperty( byval nType as long ) as long
```

Reads a document property, such as `tomCanUndo`, `tomCanRedo`, `tomCanCopy`, `tomUndoLimit`,
`tomEllipsisMode` or one of the `tomMath*` spacing values.

| Parameter | Meaning |
| --- | --- |
| `nType` | The property. |

**Returns** its value; the yes/no properties give `tomTrue` (-1) or `tomFalse` (0).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->GetProperty( tomCanUndo ) = tomTrue then print "there is something to undo"
```

Microsoft Learn: [ITextDocument2::GetProperty](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getproperty)

### SetProperty

```freebasic
function SetProperty( byval nType as long, byval Value as long ) as HRESULT
```

Sets a document property, from the same list as [GetProperty](#getproperty).

| Parameter | Meaning |
| --- | --- |
| `nType` | The property. |
| `Value` | The new value. |

**Returns** `S_OK` on success, otherwise an `HRESULT` error.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetProperty( tomUndoLimit, 50 )
print pRichEdit->GetProperty( tomUndoLimit )   ' 50
```

Microsoft Learn: [ITextDocument2::SetProperty](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-setproperty)

### GetStrings

```freebasic
function GetStrings() as ITextStrings ptr
```

Returns a collection of rich-text strings: a scratch stack of formatted text, used mainly to
convert math between its linear and built-up forms. Release it when done.

**Returns** the collection, or `NULL` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pStrings as ITextStrings ptr = pRichEdit->GetStrings()
if pStrings then SafeRelease( pStrings )
```

Microsoft Learn: [ITextDocument2::GetStrings](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getstrings)

### Notify

```freebasic
function Notify( byval nNotify as long ) as HRESULT
```

Passes an input method editor event to the engine, for a host that runs the input method itself.

| Parameter | Meaning |
| --- | --- |
| `nNotify` | The notification code. |

**Returns** `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim nCode as long    ' the input method event
pRichEdit->Notify( nCode )
```

Microsoft Learn: [ITextDocument2::Notify](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-notify)

### ReleaseCallManager

```freebasic
function ReleaseCallManager( byval pVoid as IUnknown ptr ) as HRESULT
```

Gives back a call manager obtained with [GetCallManager](#getcallmanager).

| Parameter | Meaning |
| --- | --- |
| `pVoid` | The call manager. |

**Returns** `S_OK` on success; `E_INVALIDARG` for `NULL`.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pMgr as IUnknown ptr = pRichEdit->GetCallManager()
if pMgr then pRichEdit->ReleaseCallManager( pMgr )
```

Microsoft Learn: [ITextDocument2::ReleaseCallManager](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-releasecallmanager)

### ReleaseImmContext

```freebasic
function ReleaseImmContext( byval Context as __int64 ) as HRESULT
```

Gives back an input method context obtained with [GetImmContext](#getimmcontext).

| Parameter | Meaning |
| --- | --- |
| `Context` | The context. |

**Returns** `S_OK` on success, `S_FALSE` when there was nothing to release.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim ctx as __int64 = pRichEdit->GetImmContext()
if ctx then pRichEdit->ReleaseImmContext( ctx )
```

Microsoft Learn: [ITextDocument2::ReleaseImmContext](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-releaseimmcontext)

### SysBeep

```freebasic
function SysBeep() as HRESULT
```

Plays the system's default beep, as the control does when the user does something it refuses.

**Returns** `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
if pRichEdit->CheckTextLimit( 1 ) then pRichEdit->SysBeep()
```

Microsoft Learn: [ITextDocument2::SysBeep](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-sysbeep)

### Update

```freebasic
function Update( byval Value as long ) as HRESULT
```

Brings the selection and the caret up to date after changes made through TOM; with `tomTrue` it
also scrolls the caret into view.

| Parameter | Meaning |
| --- | --- |
| `Value` | `tomTrue` to scroll the caret into view, `tomFalse` not to. |

**Returns** `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->Update( tomTrue )
```

Microsoft Learn: [ITextDocument2::Update](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-update)

### UpdateWindow

```freebasic
function UpdateWindow() as HRESULT
```

Tells the host that the view has changed and should be repainted.

**Returns** `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->UpdateWindow()
```

Microsoft Learn: [ITextDocument2::UpdateWindow](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-updatewindow)

### MathProperties, GetMathProperties, SetMathProperties

```freebasic
property MathProperties() as long
property MathProperties( byval nOptions as long, byval Mask as long )
function GetMathProperties() as long
function SetMathProperties( byval Options as long, byval Mask as long ) as HRESULT
```

Read or set how the document lays out math: display alignment (`tomMathDispAlignLeft`,
`tomMathDispAlignCenter`, `tomMathDispAlignRight`), where n-ary limits go, how empty arguments
show, line breaks at operators and more. Only the bits set in the mask change.

In the property form the options are the index and the mask is the assigned value:
`MathProperties( tomMathDispAlignLeft ) = tomMathDispAlignMask`.

| Parameter | Meaning |
| --- | --- |
| `nOptions`, `Options` | The new `tomMath*` options. |
| `Mask` | Which options to change, e.g. `tomMathDispAlignMask`. |

**Returns** (get) the options, 0 by default; (`SetMathProperties`) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
pRichEdit->SetMathProperties( tomMathDispAlignLeft, tomMathDispAlignMask )
```

Microsoft Learn: [ITextDocument2::SetMathProperties](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-setmathproperties)

### GetStory

```freebasic
function GetStory( byval Index as long ) as ITextStory ptr
```

Returns a story of the document by its index. Release it when done; [CTextStory](CTextStory)
wraps it. In a plain rich edit control, which has only its main story, indexes 0 and 1 both fail
with `E_INVALIDARG`; use [MainStory](#mainstory-getmainstory) for that one.

| Parameter | Meaning |
| --- | --- |
| `Index` | The index of the story. |

**Returns** the story, or `NULL` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
for i as long = 1 to pRichEdit->StoryCount() - 1
    dim pStory as ITextStory ptr = pRichEdit->GetStory( i )
    if pStory then SafeRelease( pStory )
next
```

Microsoft Learn: [ITextDocument2::GetStory](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getstory)

### ActiveStory, GetActiveStory, SetActiveStory

```freebasic
property ActiveStory() as ITextStory ptr
property ActiveStory( byval pStory as ITextStory ptr )
function GetActiveStory() as ITextStory ptr
function SetActiveStory( byval pStory as ITextStory ptr ) as HRESULT
```

Read or set the active story, the one that receives keyboard and mouse input; by default the
main story. The getter returns a new reference you release.

| Parameter | Meaning |
| --- | --- |
| `pStory` | The story to make active. |

**Returns** (get) the story, or `NULL`; (`SetActiveStory`) `S_OK` on success.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pStory as ITextStory ptr = pRichEdit->MainStory()
pRichEdit->ActiveStory = pStory
SafeRelease( pStory )
```

Microsoft Learn: [ITextDocument2::SetActiveStory](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-setactivestory)

### MainStory, GetMainStory

```freebasic
function MainStory() as ITextStory ptr
function GetMainStory() as ITextStory ptr
```

Return the main story: the document's ordinary text, of type `tomMainTextStory`. Release it when
done.

**Returns** the story, or `NULL` on failure.

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pStory as ITextStory ptr = pRichEdit->GetMainStory()
dim nType as long
if pStory then pStory->lpvtbl->GetType( pStory, @nType ) : SafeRelease( pStory )   ' tomMainTextStory
```

Microsoft Learn: [ITextDocument2::GetMainStory](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getmainstory)

### NewStory, GetNewStory

```freebasic
function NewStory() as ITextStory ptr
function GetNewStory() as ITextStory ptr
```

Ask the engine for a new, empty story. The rich edit control does not implement it.

**Returns** `NULL`, with `GetLastResult()` `E_NOTIMPL` (`&h80004001`).

**Example**

```freebasic
dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hCtrl )
dim pStory as ITextStory ptr = pRichEdit->NewStory()
if pStory then SafeRelease( pStory )
```

Microsoft Learn: [ITextDocument2::GetNewStory](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextdocument2-getnewstory)

## See also

- [CRichEditCtx](CRichEditCtx) for the constructor, the handle and the result codes
- [CRichEditCtx: editing](CRichEditCtx-Editing) for selection, text, undo and the message wrappers
- [RichEdit](SysWin-RichEdit-Control) for the same operations on a control handle
- [CRichEditOleCallback](CRichEditOleCallback) for embedded objects and pictures
- [CTextRange2](CTextRange2), [CTextSelection2](CTextSelection2), [CTextFont2](CTextFont2),
  [CTextPara2](CTextPara2) and [CTextStory](CTextStory) to work with the TOM objects these members return
- [Text Object Model interfaces](SysWin-RichEdit-TOM)
- [sys/win/richedit](SysWin-RichEdit)
