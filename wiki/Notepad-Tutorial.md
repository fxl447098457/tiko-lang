[Home](Home) › [PsControls](Category-PsControls) › **Notepad Tutorial**

# Notepad Tutorial

> 📘 **Start with:** [PsControls](Category-PsControls) and [PsApp](PsApp), the controls and the framework these steps use.
>
> 📖 **In the book:** [Chapter 36, Capstone: a Notepad for Windows](https://tiko-lang.net/book/ch36-tpad.html), which explains every step in more depth. The code on this page is the book's, and it is compiled and run with every build of the book.

This tutorial builds **`tpad`**, a plain-text editor in the shape of Windows Notepad: a menu bar, the text, a scroll bar, a status bar with the line and column, Find, and a question before unsaved work is thrown away. It is about 800 lines of tiko, a sixth of them a self-test, and the release build is one 309 KB executable that needs nothing Windows does not already have.

![tpad with a short file open, in the dark theme.](Notepad-Tutorial.png)

---

## 1. The project

```text
tpad/
    tiko.toml               the package, and the target tpad
    tpad.rc, tpad.manifest  the manifest, compiled into the program
    textfile/textfile.tiko  the document: load, save, find, line and column
    pad/pad.tiko            the window: controls, menus, commands
    tpad.tiko               the program, and its self-test
```

`textfile` imports nothing from Windows, so it can be tested on Linux and macOS as well. `pad` is the window, and `tpad.tiko` starts it.

```toml
# tpad: `tiko build tpad` writes out/debug/tpad.exe
[package]
name = "tpad"

[target.tpad]
main      = "tpad.tiko"
resources = ["tpad.rc"]

[target.tpad.defines]
# Every Win32 name means its W (UTF-16) form.
UNICODE = "1"
```

`UNICODE` is required by PsControls: every bare Win32 name then means its UTF-16 form. `tpad.rc` is one line, `1 24 "tpad.manifest"`, and the manifest asks for per-monitor DPI awareness and version 6 of the common controls:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0"
          xmlns:asmv3="urn:schemas-microsoft-com:asm.v3">
  <assemblyIdentity version="1.0.0.0" processorArchitecture="*"
                    name="tpad" type="win32"/>
  <asmv3:application>
    <asmv3:windowsSettings
        xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">
      <dpiAwareness>PerMonitorV2, PerMonitor</dpiAwareness>
    </asmv3:windowsSettings>
  </asmv3:application>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <!-- Windows 10 and 11 -->
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
    </application>
  </compatibility>
  <dependency>
    <dependentAssembly>
      <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls"
          version="6.0.0.0" processorArchitecture="*"
          publicKeyToken="6595b64144ccf1df" language="*"/>
    </dependentAssembly>
  </dependency>
</assembly>
```

## 2. The document

The module keeps text with **one LF per line break**. The text control counts a line break as one character too, so an offset in a `Document` is an offset in the control.

```freebasic
#module "textfile"
#import "std/fs"
#import "std/strings"
'' Nothing here knows about windows: this module is the part of tpad
'' that compiles, and is tested, on every target.

public enum LineEnding
    CrLf
    Lf
end enum

'' A text file as the editor sees it. Inside, every line break is one
'' LF, so an offset into Text is an offset into the editor control,
'' which also counts a line break as one character.
public type Document
    as ustring path             '' "" until the first Save As
    as ustring text
    as LineEnding ending = LineEnding.CrLf
    as boolean hasBom           '' the file began with a byte-order mark
    as boolean lossy            '' some bytes were not UTF-8
end type

'' CR LF and a lone CR both become LF.
public function ToLf( byref s as const ustring ) as ustring
    return strings.Replace( strings.Replace( s, !"\r\n", !"\n" ), _
                            !"\r", !"\n" )
end function
```

> ⚠️ **The control does not hand back what it counts.** `PsTextBox_GetText` returns every line break as CR LF, while `PsTextBox_SetSel` counts each break as one character. Search the text `GetText` returns, select the match, and the selection lands one character early for every line above it. Convert with `ToLf` first.

Loading and saving keep a file the way it was written: its line ending, and its byte-order mark if it had one. `fs.ReadAllText` removes a mark and turns bytes that are not UTF-8 into U+FFFD, so the module reads the first three bytes itself and records a lossy load. `fs.WriteAtomic` replaces the old file only when the new one is complete.

```freebasic
'' Did the file start with a byte-order mark? Only its first three
'' bytes are read.
private function StartsWithBom( byref p as const ustring ) as boolean
    dim as fs.File f
    if f.OpenRead( p ).IsOk( ) = false then return false
    dim as ubyte b( 0 to 2 )
    var got = f.Read( @b( 0 ), 3 )
    if got.IsOk( ) = false then return false
    dim as longint n = got.Value( )
    if n >= 3 andalso b( 0 ) = &hEF andalso b( 1 ) = &hBB andalso _
       b( 2 ) = &hBF then return true
    return n >= 2 andalso b( 0 ) = &hFF andalso b( 1 ) = &hFE
end function

'' Reads a file into doc. Returns "" or what went wrong; on failure doc
'' is left as it was.
public function Load( byref p as const ustring, _
                      byref doc as Document ) as ustring
    var r = fs.ReadAllText( p )
    if r.IsOk( ) = false then return r.Failure( ).Message( )

    dim as Document d
    d.path = p
    dim as ustring raw = r.Value( )
    '' The first line break says how the file writes them.
    dim as int32 lf = instr( raw, !"\n" ), cr = instr( raw, !"\r" )
    if lf > 0 andalso cr <> lf - 1 then d.ending = LineEnding.Lf
    d.text = ToLf( raw )
    d.hasBom = StartsWithBom( p )
    d.lossy = instr( d.text, wchr( &hFFFD ) ) > 0
    doc = d
    return ""
end function

'' Writes doc.text to doc.path in the file's own line ending. The old
'' file is replaced only once the new one is complete on disk.
public function Save( byref doc as Document ) as ustring
    dim as ustring s = doc.text
    if doc.ending = LineEnding.CrLf then
        s = strings.Replace( s, !"\n", !"\r\n" )
    end if
    if doc.hasBom then s = wchr( &hFEFF ) & s
    var r = fs.WriteAtomic( doc.path, s )
    if r.IsOk( ) = false then return r.Failure( ).Message( )
    return ""
end function
```

> ⚠️ **`fs.ReadAllBytes( p, buf, 3 )` does not read three bytes.** The third argument is a size limit: any larger file is refused and nothing is read. Read a prefix with a `File`, as `StartsWithBom` does.

The title, the search and the status bar's numbers:

```freebasic
'' The file's name without its folder, or "Untitled".
public function DisplayName( byref doc as Document ) as ustring
    if len( doc.path ) = 0 then return "Untitled"
    dim as int32 i = len( doc.path )
    do until i = 0
        dim as ustring c = mid( doc.path, i, 1 )
        if c = "\" orelse c = "/" then exit do
        i -= 1
    loop
    return mid( doc.path, i + 1 )
end function

'' The title bar: "*notes.txt - tpad" while there are unsaved changes.
public function Caption( byref doc as Document, _
                         byval modified as boolean ) as ustring
    return iif( modified, "*", "" ) & DisplayName( doc ) & " - tpad"
end function

'' The offset of the next match at or after start, wrapping around to
'' the top; -1 when there is none. Offsets count from 0, as the editor
'' control's do.
public function FindNext( byref text as const ustring, _
                          byref needle as const ustring, _
                          byval start as int32, _
                          byval matchCase as boolean ) as int32
    if len( needle ) = 0 then return -1
    dim as ustring hay = text, pin = needle
    if matchCase = false then
        hay = lcase( hay )
        pin = lcase( pin )
    end if
    dim as int32 at = instr( start + 1, hay, pin )
    if at = 0 then at = instr( hay, pin )
    return at - 1
end function

'' The 1-based line and column of an offset, for the status bar.
public sub LineColumn( byref text as const ustring, _
                       byval offset as int32, _
                       byref ln as int32, byref col as int32 )
    ln = 1
    dim as int32 lineStart = 1, at = instr( text, !"\n" )
    do until at = 0 orelse at > offset
        ln += 1
        lineStart = at + 1
        at = instr( at + 1, text, !"\n" )
    loop
    col = offset + 2 - lineStart
end sub
```

## 3. The window's state

```freebasic
#module "pad"
#import "vendor/PsControls/PsApp"
#import "vendor/PsControls/PsMenuBar"
#import "vendor/PsControls/PsPopupMenu"
#import "vendor/PsControls/PsTextBox"
#import "vendor/PsControls/PsVScrollBar"
#import "vendor/PsControls/PsStatusBar"
#import "vendor/PsControls/PsMessageBox"
#import "vendor/PsControls/PsButton"
#import "vendor/PsControls/PsCheckBox"
#import "../textfile"

using PsApp
using PsTheme
using PsBufferPaint
using PsMenuBar
using PsPopupMenu
using PsTextBox
using PsVScrollBar
using PsStatusBar
using PsMessageBox
using PsButton
using PsCheckBox
using gui

'' Every command the menus and the keyboard can give.
public enum Cmd
    CmdNew = 1000
    CmdOpen
    CmdSave
    CmdSaveAs
    CmdExit
    CmdUndo
    CmdCut
    CmdCopy
    CmdPaste
    CmdSelectAll
    CmdFind
    CmdFindNext
end enum

'' The two things a person answers: a question in a message box, and
'' a file name in a file dialog. Each is reached through a pointer, so
'' a test can answer in the person's place.
public type AskProc as function( byval f as PsForm ptr, _
    byref text as ustring, byval buttons as long ) as long
public type PickProc as function( byval f as PsForm ptr, _
    byval saving as boolean, byref suggest as ustring ) as ustring

'' One open file and its window. The form's Tag points here.
public type Editor
    as PsForm ptr form
    as HWND text, scroll, status
    as textfile.Document doc
    as ustring findWhat
    as boolean matchCase
    as AskProc ask
    as PickProc pick
end type

enum
    IDC_BAR = 100
    IDC_TEXT
    IDC_SCROLL
    IDC_STATUS
    IDC_WHAT
    IDC_CASE
end enum

'' Posted to the form after a key or a click in the text, so the
'' status bar is read once the control has moved the caret.
const WM_CARETMOVED = WM_APP + 1

function EditorOf( byval h as HWND ) as Editor ptr
    return PsForm.FromHwnd( h )->Tag
end function
```

Everything about one window is an `Editor`, allocated with `new`, and **the form's `Tag` points at it**. A control's callback receives only the control's handle; `PsForm.FromHwnd` finds the form, and its `Tag` finds the `Editor`. No `dim shared` is needed anywhere.

`ask` and `pick` are the two places a person answers: a message box and a file dialog. They are procedure pointers so that a test can answer instead.

```freebasic
'' The real answers come from a person.
function AskPerson( byval f as PsForm ptr, byref text as ustring, _
                    byval buttons as long ) as long
    return PsMessageBox_Show( f->hWindow, text, "tpad", _
        iif( buttons = MBX_BTN_OK, MBX_ICON_INFO, MBX_ICON_QUESTION ), _
        buttons )
end function

function PickFile( byval f as PsForm ptr, byval saving as boolean, _
                   byref suggest as ustring ) as ustring
    if saving then
        dim as CISaveFileDialog d
        d.AddFileType( "Text files", "*.txt" )
        d.AddFileType( "All files", "*.*" )
        d.SetFileTypes( )
        d.SetDefaultExtension( "txt" )
        d.SetFileName( suggest )
        if d.ShowSave( f->hWindow ) <> S_OK then return ""
        return d.GetResultString( SIGDN_FILESYSPATH )
    end if
    dim as CIOpenFileDialog d
    d.AddFileType( "Text files", "*.txt" )
    d.AddFileType( "All files", "*.*" )
    d.SetFileTypes( )
    if d.ShowOpen( f->hWindow ) <> S_OK then return ""
    return d.GetResultString( SIGDN_FILESYSPATH )
end function
```

## 4. The text, its scroll bar and the status bar

```freebasic
sub BuildText( byval f as PsForm ptr, byval ed as Editor ptr )
    ed->text = PsTextBox_Create( f->hWindow, IDC_TEXT, true )
    PsTextBox_SetFont( ed->text, f->Font( PSFONT_MONO ) )
    PsTextBox_SetLimitText( ed->text, &h7FFFFFFE )
    PsTextBox_SetMargins( ed->text, f->ScaleX( 6 ), f->ScaleX( 6 ) )

    '' The person typed, cut, pasted or undid something.
    PsTextBox_SetChangeCallback( ed->text, _
        sub( byval h as HWND )
            ShowTitle( EditorOf( h ) )
            ShowStatus( EditorOf( h ) )
        end sub )

    '' The caret may have moved: look once the control has acted.
    PsTextBox_SetMessageCallback( ed->text, _
        function( byval m as PSTEXTBOX_MESSAGEINFO ptr ) as boolean
            select case m->uMsg
            case WM_KEYDOWN, WM_KEYUP, WM_LBUTTONDOWN, WM_LBUTTONUP
                PostMessageW( GetParent( m->hTextBox ), _
                              WM_CARETMOVED, 0, 0 )
            end select
            return false
        end function )
    f->OnMessage( WM_CARETMOVED, _
        function( byval f as PsForm ptr, byval uMsg as UINT, _
                  byval wParam as WPARAM, byval lParam as LPARAM, _
                  byref result as LRESULT ) as boolean
            ShowStatus( f->Tag )
            return true
        end function )

    '' The control draws no scroll bar of its own; it tells one.
    ed->scroll = PsVScrollBar_Create( f->hWindow, IDC_SCROLL )
    PsTextBox_SetScrollChangedCallback( ed->text, _
        sub( byval h as HWND )
            dim as integer total, page, top
            PsTextBox_GetVScrollInfo( h, total, page, top )
            PsVScrollBar_SetRange( EditorOf( h )->scroll, total, _
                                   page, top )
        end sub )
    PsVScrollBar_SetScrollCallback( ed->scroll, _
        sub( byval h as HWND, byval newPos as integer )
            PsTextBox_ScrollToLine( EditorOf( h )->text, newPos )
        end sub )
end sub
```

- **The change callback** fires only for the person's edits. PsControls setters such as `PsTextBox_SetText` are silent.
- **The message callback** runs *before* the box acts on a key or a click, so it posts `WM_CARETMOVED`. The form handles that once the caret has moved.
- **The box draws no scroll bar.** It reports its line count, page and top line, and a `PsVScrollBar` reports where it was dragged.

```freebasic
sub BuildStatus( byval f as PsForm ptr, byval ed as Editor ptr )
    ed->status = PsStatusBar_Create( f->hWindow, IDC_STATUS )
    PsStatusBar_AddPanel( ed->status, "" )      '' Ln, Col: springs
    PsStatusBar_AddPanel( ed->status, "" )      '' line ending
    PsStatusBar_AddPanel( ed->status, "" )      '' encoding
    PsStatusBar_SetExpandPanel( ed->status, 0 )
    '' The bar lays the panels out; what is inside one, it leaves to
    '' the program. Without this, the panels are blank.
    PsStatusBar_SetPaintCallback( ed->status, _
        sub( byval p as PSSTATUSBAR_PAINTINFO ptr )
            dim as PSTHEME_COLORS t = PsApp_Instance( )->Theme( )
            p->b->SetColors( t.TextDim, t.Window )
            p->b->PaintRect( @p->rc )
            dim as RECT r = p->rc
            r.left += PsStatusBar_GetPadding( p->hStatusBar )
            p->b->SetFont( PsStatusBar_GetFont( p->hStatusBar ) )
            p->b->PaintText( p->wszCaption, @r, DT_LEFT )
        end sub )
end sub

'' The editor's text, with one LF per line break, as textfile wants.
function TextOf( byval ed as Editor ptr ) as ustring
    return textfile.ToLf( PsTextBox_GetText( ed->text ) )
end function

sub ShowTitle( byval ed as Editor ptr )
    SetWindowTextW( ed->form->hWindow, textfile.Caption( ed->doc, _
                    PsTextBox_GetModify( ed->text ) ) )
end sub

sub ShowStatus( byval ed as Editor ptr )
    dim as integer first, last
    PsTextBox_GetSel( ed->text, first, last )
    dim as int32 ln, col
    textfile.LineColumn( TextOf( ed ), last, ln, col )
    PsStatusBar_SetText( ed->status, 0, _
                         "Ln " & ln & ", Col " & col )
    PsStatusBar_SetText( ed->status, 1, _
        iif( ed->doc.ending = textfile.LineEnding.CrLf, _
             "Windows (CRLF)", "Unix (LF)" ) )
    PsStatusBar_SetText( ed->status, 2, _
        iif( ed->doc.hasBom, "UTF-8 with BOM", "UTF-8" ) )
end sub
```

> ⚠️ **A `PsStatusBar` with no paint callback is a blank strip.** It lays the panels out and leaves their contents to you. `PsStatusBar_GetText` still returns the right text, so a test that reads the text passes while the screen shows nothing.

## 5. Layout, menus and commands

```freebasic
sub Main_OnSize( byval f as PsForm ptr, byval cx as long, _
                 byval cy as long )
    dim as long barH = f->ScaleY( 30 ), statusH = f->ScaleY( 26 )
    dim as long sbW = f->ScaleX( 14 )
    dim as long textH = cy - barH - statusH
    SetWindowPos( f->Item( IDC_BAR ), null, 0, 0, cx, barH, _
                  SWP_NOZORDER or SWP_SHOWWINDOW )
    SetWindowPos( f->Item( IDC_TEXT ), null, 0, barH, cx - sbW, _
                  textH, SWP_NOZORDER or SWP_SHOWWINDOW )
    SetWindowPos( f->Item( IDC_SCROLL ), null, cx - sbW, barH, sbW, _
                  textH, SWP_NOZORDER or SWP_SHOWWINDOW )
    SetWindowPos( f->Item( IDC_STATUS ), null, 0, cy - statusH, cx, _
                  statusH, SWP_NOZORDER or SWP_SHOWWINDOW )
end sub
```

Controls are created hidden and zero-sized; `OnSize` places and shows them. Every literal goes through `ScaleX` or `ScaleY`.

```freebasic
function AddMenu( byval f as PsForm ptr, byval bar as HWND, _
                  byref title as ustring ) as HWND
    dim as long i = PsMenuBar_AddItem( bar, title, 0 )
    dim as HWND m = PsPopupMenu_Create( f->hWindow )
    PsMenuBar_SetDropDown( bar, i, m )
    return m
end function

sub BuildMenus( byval f as PsForm ptr )
    dim as HWND bar = PsMenuBar_Create( f->hWindow, IDC_BAR )
    PsMenuBar_SetCommandCallback( bar, _
        sub( byval h as HWND, byval id as long )
            Execute( EditorOf( h ), id )
        end sub )
    dim as HWND m = AddMenu( f, bar, "File" )
    PsPopupMenu_AddItem( m, CmdNew, "New", "Ctrl+N" )
    PsPopupMenu_AddItem( m, CmdOpen, "Open...", "Ctrl+O" )
    PsPopupMenu_AddItem( m, CmdSave, "Save", "Ctrl+S" )
    PsPopupMenu_AddItem( m, CmdSaveAs, "Save As...", "Ctrl+Shift+S" )
    PsPopupMenu_AddSeparator( m )
    PsPopupMenu_AddItem( m, CmdExit, "Exit" )
    m = AddMenu( f, bar, "Edit" )
    PsPopupMenu_AddItem( m, CmdUndo, "Undo", "Ctrl+Z" )
    PsPopupMenu_AddSeparator( m )
    PsPopupMenu_AddItem( m, CmdCut, "Cut", "Ctrl+X" )
    PsPopupMenu_AddItem( m, CmdCopy, "Copy", "Ctrl+C" )
    PsPopupMenu_AddItem( m, CmdPaste, "Paste", "Ctrl+V" )
    PsPopupMenu_AddItem( m, CmdSelectAll, "Select All", "Ctrl+A" )
    PsPopupMenu_AddSeparator( m )
    PsPopupMenu_AddItem( m, CmdFind, "Find...", "Ctrl+F" )
    PsPopupMenu_AddItem( m, CmdFindNext, "Find Next", "F3" )

    '' The text control handles Ctrl+Z, X, C, V and A itself. These are
    '' the keys only tpad knows.
    f->AddAccelerator( FVIRTKEY or FCONTROL, asc( "N" ), CmdNew )
    f->AddAccelerator( FVIRTKEY or FCONTROL, asc( "O" ), CmdOpen )
    f->AddAccelerator( FVIRTKEY or FCONTROL, asc( "S" ), CmdSave )
    f->AddAccelerator( FVIRTKEY or FCONTROL or FSHIFT, asc( "S" ), _
                       CmdSaveAs )
    f->AddAccelerator( FVIRTKEY or FCONTROL, asc( "F" ), CmdFind )
    f->AddAccelerator( FVIRTKEY, VK_F3, CmdFindNext )
    f->CreateAcceleratorTable( )
    f->OnCommand( _
        function( byval f as PsForm ptr, byval id as long, _
                  byval code as long, byval hCtl as HWND ) as boolean
            if id < CmdNew orelse id > CmdFindNext then return false
            Execute( f->Tag, id )
            return true
        end function )
end sub

'' The one place a command is carried out, wherever it came from.
public sub Execute( byval ed as Editor ptr, byval id as long )
    select case id
    case CmdNew
        if MayDiscard( ed ) then
            dim as textfile.Document blank
            ShowDocument( ed, blank )
        end if
    case CmdOpen
        if MayDiscard( ed ) then
            dim as ustring p = ed->pick( ed->form, false, "" )
            if len( p ) then OpenPath( ed, p )
        end if
    case CmdSave
        SaveDocument( ed, false )
    case CmdSaveAs
        SaveDocument( ed, true )
    case CmdExit
        ed->form->Close( )
    case CmdUndo
        PsTextBox_Undo( ed->text )
    case CmdCut
        PsTextBox_Cut( ed->text )
    case CmdCopy
        PsTextBox_Copy( ed->text )
    case CmdPaste
        PsTextBox_Paste( ed->text )
    case CmdSelectAll
        PsTextBox_SelectAll( ed->text )
    case CmdFind
        AskWhatToFind( ed )
    case CmdFindNext
        if len( ed->findWhat ) then
            FindAgain( ed )
        else
            AskWhatToFind( ed )
        end if
    end select
end sub
```

The accelerator table turns Ctrl+N, Ctrl+O, Ctrl+S, Ctrl+Shift+S, Ctrl+F and F3 into commands before the text box sees them. Ctrl+Z, X, C, V and A stay out of it, because the text control handles them itself. Menus, keys and the self-test all end in the one `Execute`.

## 6. Files, Find, and building the window

```freebasic
'' Puts doc in the window, replacing what was there.
sub ShowDocument( byval ed as Editor ptr, _
                  byref doc as textfile.Document )
    ed->doc = doc
    PsTextBox_SetText( ed->text, doc.text )
    PsTextBox_SetModify( ed->text, false )
    PsTextBox_SetSel( ed->text, 0, 0 )
    ShowTitle( ed )
    ShowStatus( ed )
end sub

'' Opens path; says why not if it cannot.
public function OpenPath( byval ed as Editor ptr, _
                          byref path as ustring ) as boolean
    dim as textfile.Document doc
    dim as ustring e = textfile.Load( path, doc )
    if len( e ) then
        ed->ask( ed->form, e, MBX_BTN_OK )
        return false
    end if
    ShowDocument( ed, doc )
    if doc.lossy then
        ed->ask( ed->form, textfile.DisplayName( doc ) & _
            " is not UTF-8. Characters that could not be read show" & _
            " as U+FFFD, and saving writes them that way.", MBX_BTN_OK )
    end if
    return true
end function

'' Saves, asking for a name when there is none (or when asked to).
function SaveDocument( byval ed as Editor ptr, _
                       byval newName as boolean ) as boolean
    if newName orelse len( ed->doc.path ) = 0 then
        dim as ustring p = ed->pick( ed->form, true, _
                                     textfile.DisplayName( ed->doc ) )
        if len( p ) = 0 then return false
        ed->doc.path = p
    end if
    ed->doc.text = TextOf( ed )
    dim as ustring e = textfile.Save( ed->doc )
    if len( e ) then
        ed->ask( ed->form, e, MBX_BTN_OK )
        return false
    end if
    PsTextBox_SetModify( ed->text, false )
    ShowTitle( ed )
    return true
end function

'' True when it is all right to throw the text away: it is saved,
'' the person saved it now, or said not to.
function MayDiscard( byval ed as Editor ptr ) as boolean
    if PsTextBox_GetModify( ed->text ) = false then return true
    select case ed->ask( ed->form, "Do you want to save changes to " & _
                         textfile.DisplayName( ed->doc ) & "?", _
                         MBX_BTN_SAVE_DONTSAVE_CANCEL )
    case IDYES
        return SaveDocument( ed, false )
    case IDNO
        return true
    end select
    return false
end function

sub FindAgain( byval ed as Editor ptr )
    if len( ed->findWhat ) = 0 then exit sub
    dim as integer first, last
    PsTextBox_GetSel( ed->text, first, last )
    dim as int32 at = textfile.FindNext( TextOf( ed ), ed->findWhat, _
                                         last, ed->matchCase )
    if at < 0 then
        ed->ask( ed->form, "Cannot find """ & ed->findWhat & """", _
                 MBX_BTN_OK )
        exit sub
    end if
    PsTextBox_SetSel( ed->text, at, at + len( ed->findWhat ) )
    SendMessageW( ed->text, EM_SCROLLCARET, 0, 0 )
    ShowStatus( ed )
end sub

'' The Find box: a modal form that only collects the search.
sub FindBox_OnSize( byval f as PsForm ptr, byval cx as long, _
                    byval cy as long )
    '' Two rows, each as tall as a button: the search and its button,
    '' then the option and Cancel.
    dim as long pad = f->ScaleX( 12 ), bw, bh
    PsButton_GetIdealSize( f->Item( IDOK ), bw, bh )
    dim as long w = cx - 3 * pad - bw
    SetWindowPos( f->Item( IDC_WHAT ), null, pad, pad, w, bh, _
                  SWP_NOZORDER or SWP_SHOWWINDOW )
    SetWindowPos( f->Item( IDC_CASE ), null, pad, 2 * pad + bh, _
                  w, bh, SWP_NOZORDER or SWP_SHOWWINDOW )
    SetWindowPos( f->Item( IDOK ), null, cx - pad - bw, pad, bw, bh, _
                  SWP_NOZORDER or SWP_SHOWWINDOW )
    SetWindowPos( f->Item( IDCANCEL ), null, cx - pad - bw, _
                  2 * pad + bh, bw, bh, SWP_NOZORDER or SWP_SHOWWINDOW )
end sub

sub FindBox_Ok( byval h as HWND, byval id as long )
    dim as PsForm ptr f = PsForm.FromHwnd( h )
    dim as Editor ptr ed = f->Tag
    ed->findWhat = PsTextBox_GetText( f->Item( IDC_WHAT ) )
    ed->matchCase = PsCheckBox_GetChecked( f->Item( IDC_CASE ) )
    f->EndModal( IDOK )
end sub

sub AskWhatToFind( byval ed as Editor ptr )
    dim as PsForm ptr f = PsApp_Instance( )->NewForm( "Find", 420, _
        150, WS_POPUP or WS_CAPTION or WS_SYSMENU or WS_CLIPCHILDREN, _
        WS_EX_CONTROLPARENT or WS_EX_DLGMODALFRAME, ed->form->hWindow )
    f->Tag = ed
    dim as HWND hWhat = PsTextBox_Create( f->hWindow, IDC_WHAT )
    PsTextBox_SetText( hWhat, ed->findWhat )
    PsTextBox_SetSelectOnFocus( hWhat, true )
    dim as HWND hCase = PsCheckBox_Create( f->hWindow, IDC_CASE )
    PsCheckBox_SetText( hCase, "Match case" )
    PsCheckBox_SetChecked( hCase, ed->matchCase )
    dim as HWND hOk = PsButton_Create( f->hWindow, IDOK )
    PsButton_SetText( hOk, "Find Next" )
    PsButton_SetClickCallback( hOk, @FindBox_Ok )
    dim as HWND hCancel = PsButton_Create( f->hWindow, IDCANCEL )
    PsButton_SetText( hCancel, "Cancel" )
    PsButton_SetClickCallback( hCancel, _
        sub( byval h as HWND, byval id as long )
            PsForm.FromHwnd( h )->EndModal( IDCANCEL )
        end sub )
    f->OnSize( @FindBox_OnSize )
    f->SetClientSize( 420, 112 )
    if f->ShowModal( ed->form->hWindow ) = IDOK then FindAgain( ed )
end sub

'' Builds the main window, with an empty, untitled document.
public function Create( byref app as PsApplication ) as Editor ptr
    dim as Editor ptr ed = new Editor
    ed->ask = @AskPerson
    ed->pick = @PickFile
    dim as PsForm ptr f = app.NewForm( "tpad", 720, 480 )
    ed->form = f
    f->Tag = ed

    BuildMenus( f )
    BuildText( f, ed )
    BuildStatus( f, ed )

    f->OnSize( @Main_OnSize )
    '' Asked before the window closes, however it is closed.
    f->OnClose( _
        function( byval f as PsForm ptr ) as boolean
            return MayDiscard( f->Tag )
        end function )
    '' A new DPI gives every control the form's UI font: put the
    '' monospaced one back.
    f->OnDpiChanged( _
        sub( byval f as PsForm ptr, byval oldDpi as long, _
             byval newDpi as long )
            dim as Editor ptr ed = f->Tag
            PsTextBox_SetFont( ed->text, f->Font( PSFONT_MONO ) )
        end sub )
    f->OnDestroy( _
        sub( byval f as PsForm ptr )
            delete cast( Editor ptr, f->Tag )
            f->Tag = 0
        end sub )

    ShowTitle( ed )
    ShowStatus( ed )
    return ed
end function
```

`MayDiscard` asks Save, Don't Save or Cancel before New, Open or closing; returning `false` from `OnClose` keeps the window open.

> ⚠️ **A DPI change replaces your fonts.** When the window moves to a monitor at another scale, PsApp gives every control the form's UI font, the text box included. Set the monospaced font again in `OnDpiChanged`, as `Create` does.

## 7. The program

```freebasic
#cmdline "-s gui"
#import "./pad"
#import "std/fs"
#import "std/strings"
#import "vendor/PsControls/PsApp"
#import "vendor/PsControls/PsTextBox"
#import "vendor/PsControls/PsStatusBar"
#import "vendor/PsControls/PsMessageBox"

using PsApp
using PsTextBox
using PsStatusBar
using PsMessageBox

dim as PsApplication app
app.Init( )
dim as pad.Editor ptr ed = pad.Create( app )
if command( 1 ) = "--selftest" then end SelfTest( ed )
if len( command( 1 ) ) then pad.OpenPath( ed, command( 1 ) )
end app.Run( ed->form )
```

`-s gui` means no console window. `app.Run` shows the main window and runs the message loop until it closes.

Build and run it from the project folder:

```text
tiko build tpad
out/debug/tpad.exe notes.txt
```

The first build compiles the PsControls modules the program imports and takes a few minutes; later builds compile only what changed. `tiko build tpad --profile release` writes the optimised `out/release/tpad.exe`, 316,416 bytes. It imports only Windows' own libraries, so copying the file is the whole installation.

## 8. Testing the window with nobody at it

`tpad --selftest` drives the real window and prints what it saw. The message box and the file dialog are scripted through `ask` and `pick`:

```freebasic
'' The person, scripted: what the test answers to each question.
function ScriptedAsk( byval f as PsForm ptr, byref text as ustring, _
                      byval buttons as long ) as long
    static as long replies( ... ) = { IDCANCEL, IDNO, IDNO }
    static as int32 n
    print "  asked: "; text
    if buttons = MBX_BTN_OK then return IDOK
    n += 1
    print "  answered: "; iif( replies( n - 1 ) = IDNO, _
                               "Don't Save", "Cancel" )
    return replies( n - 1 )
end function

function ScriptedPick( byval f as PsForm ptr, byval saving as boolean, _
                       byref suggest as ustring ) as ustring
    print "  picked: lf.tmp"
    return "lf.tmp"
end function

'' Lets posted messages arrive, as the message loop would.
sub Pump( )
    dim as MSG m
    do until PeekMessageW( @m, null, 0, 0, PM_REMOVE ) = 0
        TranslateMessage( @m )
        DispatchMessageW( @m )
    loop
end sub

'' A key, delivered where the keyboard would deliver it.
sub Press( byval ed as pad.Editor ptr, byval vk as long )
    SendMessageW( PsTextBox_GetRichEditHandle( ed->text ), _
                  WM_KEYDOWN, vk, 0 )
    Pump( )
end sub

sub Type_( byval ed as pad.Editor ptr, byref s as ustring )
    for i as int32 = 1 to len( s )
        SendMessageW( PsTextBox_GetRichEditHandle( ed->text ), _
                      WM_CHAR, asc( s, i ), 0 )
    next
    Pump( )
end sub

sub Report( byval ed as pad.Editor ptr )
    '' Win32 fills a wstring buffer. Printed to a pipe or a file, a
    '' wstring is written as raw UTF-16, so it is copied to a ustring,
    '' which is written as UTF-8.
    dim as wstring * 260 buffer
    GetWindowTextW( ed->form->hWindow, buffer, 260 )
    dim as ustring title = buffer
    print "  title:  "; title
    print "  status: "; PsStatusBar_GetText( ed->status, 0 ); " | "; _
          PsStatusBar_GetText( ed->status, 1 ); " | "; _
          PsStatusBar_GetText( ed->status, 2 )
end sub

function SelfTest( byval ed as pad.Editor ptr ) as long
    ed->ask = @ScriptedAsk
    ed->pick = @ScriptedPick
    fs.WriteAllText( "lf.tmp", !"one\ntwo\nthree\n" )

    print "== a new window"
    Report( ed )
    print "== the layout, at 600 x 400"
    ed->form->SetClientSize( 600, 400 )
    dim as RECT client, text, bar, status
    GetClientRect( ed->form->hWindow, @client )
    GetWindowRect( ed->text, @text )
    GetWindowRect( ed->scroll, @bar )
    GetWindowRect( ed->status, @status )
    print "  text meets the scroll bar: "; _
          cbool( text.right = bar.left )
    print "  text meets the status bar: "; _
          cbool( text.bottom = status.top )
    print "  status bar is as wide as the window: "; _
          cbool( status.right - status.left = client.right )

    print "== File > Open"
    pad.Execute( ed, pad.CmdOpen )
    Report( ed )
    print "== Down, Down, End, and type ""!"""
    Press( ed, VK_DOWN )
    Press( ed, VK_DOWN )
    Press( ed, VK_END )
    Type_( ed, "!" )
    Report( ed )

    print "== Find Next, for ""T"", twice"
    ed->findWhat = "T"
    pad.Execute( ed, pad.CmdFindNext )
    Report( ed )
    pad.Execute( ed, pad.CmdFindNext )
    Report( ed )
    print "== Find Next, for ""four"""
    ed->findWhat = "four"
    pad.Execute( ed, pad.CmdFindNext )

    print "== File > Save"
    pad.Execute( ed, pad.CmdSave )
    Report( ed )
    dim as ustring saved = fs.ReadAllText( "lf.tmp" ).Value( )
    print "  on disk: "; strings.Escape( saved )

    print "== type, then File > New, twice"
    Type_( ed, "?" )
    pad.Execute( ed, pad.CmdNew )
    Report( ed )
    pad.Execute( ed, pad.CmdNew )
    Report( ed )

    print "== moved to a monitor at twice the DPI"
    dim as HWND w = ed->form->hWindow
    dim as long dpi = GetDpiForWindow( w )
    dim as RECT r
    GetWindowRect( w, @r )
    SendMessageW( w, WM_DPICHANGED, MAKEWPARAM( 2 * dpi, 2 * dpi ), _
                  cast( LPARAM, @r ) )
    print "  the text is still monospaced: "; _
          cbool( PsTextBox_GetFont( ed->text ) = _
                 ed->form->Font( PSFONT_MONO ) )

    print "== type, then close the window"
    Type_( ed, "x" )
    ed->form->Close( )
    print "  window closed: "; cbool( IsWindow( w ) = 0 )
    return 0
end function
```

Its output:

```text
== a new window
  title:  Untitled - tpad
  status: Ln 1, Col 1 | Windows (CRLF) | UTF-8
== the layout, at 600 x 400
  text meets the scroll bar: true
  text meets the status bar: true
  status bar is as wide as the window: true
== File > Open
  picked: lf.tmp
  title:  lf.tmp - tpad
  status: Ln 1, Col 1 | Unix (LF) | UTF-8
== Down, Down, End, and type "!"
  title:  *lf.tmp - tpad
  status: Ln 3, Col 7 | Unix (LF) | UTF-8
== Find Next, for "T", twice
  title:  *lf.tmp - tpad
  status: Ln 2, Col 2 | Unix (LF) | UTF-8
  title:  *lf.tmp - tpad
  status: Ln 3, Col 2 | Unix (LF) | UTF-8
== Find Next, for "four"
  asked: Cannot find "four"
== File > Save
  title:  lf.tmp - tpad
  status: Ln 3, Col 2 | Unix (LF) | UTF-8
  on disk: one\ntwo\nthree!\n
== type, then File > New, twice
  asked: Do you want to save changes to lf.tmp?
  answered: Cancel
  title:  *lf.tmp - tpad
  status: Ln 3, Col 2 | Unix (LF) | UTF-8
  asked: Do you want to save changes to lf.tmp?
  answered: Don't Save
  title:  Untitled - tpad
  status: Ln 1, Col 1 | Windows (CRLF) | UTF-8
== moved to a monitor at twice the DPI
  the text is still monospaced: true
== type, then close the window
  asked: Do you want to save changes to Untitled?
  answered: Don't Save
  window closed: true
```

- **Size the window first.** A key sent to a zero-sized text box is accepted and moves nothing.
- **Print a `ustring`, not a `wstring`.** Sent to a pipe or a file, a `wstring` is written as raw UTF-16.
- **Look at the window too.** The self-test checks commands, callbacks and files, not pixels.

### See also

- [PsApp](PsApp)
- [PsTextBox](PsTextBox), [PsStatusBar](PsStatusBar), [PsMenuBar](PsMenuBar), [PsMessageBox](PsMessageBox)
- [Notepad2 Tutorial](Notepad2-Tutorial): this program on [tkControls](Category-tkControls), for Windows, Linux and macOS
- [tiko build](Category-Tiko-Build)
- [Filesystem](Category-Filesystem)
