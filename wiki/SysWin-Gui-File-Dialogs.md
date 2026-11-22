[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **File dialogs**

# File dialogs
Shows the Windows Open and Save dialogs and reads the files the user picked.

<!-- scope: CIOpenFileDialog -->
<!-- scope: CISaveFileDialog -->

Shows the Windows Open and Save dialogs and reads the files the user picked.

`CIOpenFileDialog` and `CISaveFileDialog` wrap the shell's common item dialogs: the
Explorer-style Open and Save dialogs with a navigation pane, a search box and a file-type list.
The two classes have the same members for setting up and showing a dialog; the Open dialog adds
multiple selection, the Save dialog adds file properties.

**Lifetime.** The constructor starts COM on the thread and creates the dialog; the destructor
detaches the event handler set with `SetEvents`, releases the dialog and stops COM again, so a
program does not call `CoInitialize` itself. Declare the object where it is needed, set it up,
show it, read the result and let it go out of scope. The object assumes the dialog was created:
its members, the destructor included, call through the interface pointer without checking it.
[GetPtr](#getptr) returns `NULL` when creation failed.

**The order of calls.** Everything that shapes the dialog (file types, options, folder, file
name, labels, events, added controls) is set before `ShowOpen` or `ShowSave`. Those two block
until the user closes the dialog and return `S_OK` when a file was chosen. The result is read
afterwards.

**Names.** Members that return a name take a `SIGDN` value. The default, `SIGDN_NORMALDISPLAY`,
is the name Explorer shows (`Windows` for `C:\Windows`, and for a file the extension may be
missing); pass `SIGDN_FILESYSPATH` for the full path. These members copy the name the shell
allocates into a `ustring` and do not free the shell's copy. When a member fails it returns an
empty string and `GetLastError()` holds the `HRESULT`.

**What to release.** [GetPtr](#getptr) returns the class's own pointer: never release it.
[GetIFileDialogPtr](#getifiledialogptr), [GetResult](#getresult), [GetResults](#getresults) and
[GetSelectedItems](#getselecteditems) return a new reference that the caller releases with
`->lpVtbl->Release`.

To add check boxes, lists and buttons to a dialog see [CIFileDialogCustomize](CIFileDialogCustomize);
to react while it is open see [File dialog events](SysWin-Gui-File-Dialog-Events).

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A window with a list box and two buttons. **Open** lets the user pick several text files and
lists their full paths; **Save** asks for a file name and shows it in the caption.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_LIST = 101
const IDC_OPEN = 102
const IDC_SAVE = 103

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "FileDialogsDemo"
    dim hWin as HWND = pWindow.Create( NULL, "File dialogs", @WndProc )
    pWindow.SetClientSize( 460, 240 )
    pWindow.Center()
    pWindow.AddControl( "ListBox", hWin, IDC_LIST, "", 10, 10, 340, 220 )
    pWindow.AddControl( "Button", hWin, IDC_OPEN, "&Open...", 360, 10, 90, 28 )
    pWindow.AddControl( "Button", hWin, IDC_SAVE, "&Save...", 360, 46, 90, 28 )
    return pWindow.DoEvents( SW_NORMAL )
end function

sub OpenFiles( byval hwnd as HWND )
    dim pofd as CIOpenFileDialog
    pofd.AddFileType( "Text files", "*.txt;*.log" )
    pofd.AddFileType( "All files", "*.*" )
    pofd.SetFileTypes()
    pofd.SetOptions( pofd.GetOptions() or FOS_ALLOWMULTISELECT )
    pofd.SetTitle( "Open one or more files" )
    if pofd.ShowOpen( hwnd ) <> S_OK then exit sub          ' cancelled
    dim hList as HWND = GetDlgItem( hwnd, IDC_LIST )
    ListBox.ResetContent( hList )
    dim ustrRes as ustring = pofd.GetResultsString( SIGDN_FILESYSPATH )
    for i as long = 1 to pofd.GetResultsCount()
        ListBox.AddString( hList, pofd.ParseResults( ustrRes, i ) )
    next
end sub

sub SaveFile( byval hwnd as HWND )
    dim psfd as CISaveFileDialog
    psfd.AddFileType( "Text files", "*.txt" )
    psfd.SetFileTypes()
    psfd.SetDefaultExtension( "txt" )
    psfd.SetFileName( "untitled" )
    if psfd.ShowSave( hwnd ) = S_OK then
        SetWindowText( hwnd, "Save to " & psfd.GetResultString( SIGDN_FILESYSPATH ) )
    end if
end sub

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                select case CBCTL( wParam, lParam )
                    case IDC_OPEN : OpenFiles( hwnd )
                    case IDC_SAVE : SaveFile( hwnd )
                end select
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

**CIOpenFileDialog**

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Starts COM and creates an Open dialog. |
| [Destructor](#destructor) | Detaches the event handler, releases the dialog and stops COM. |
| [GetPtr](#getptr) | Returns the dialog's `IFileOpenDialog` pointer. |
| [GetIFileDialogPtr](#getifiledialogptr) | Returns a new `IFileDialog` reference to the dialog. |
| [ShowOpen](#showopen) | Shows the dialog and waits until the user closes it. |
| [AddFileType](#addfiletype) | Adds an entry to the file-type list the class keeps. |
| [SetFileTypes](#setfiletypes) | Gives the dialog its file types. |
| [SetFileTypeIndex](#setfiletypeindex) | Selects a file type by its one-based index. |
| [GetFileTypeIndex](#getfiletypeindex) | Returns the one-based index of the selected file type. |
| [SetOptions](#setoptions) | Sets the `FOS_*` option flags. |
| [GetOptions](#getoptions) | Returns the `FOS_*` option flags. |
| [SetFolder](#setfolder) | Sets the folder the dialog always opens in. |
| [SetDefaultFolder](#setdefaultfolder) | Sets the folder used when there is no recently used one. |
| [GetFolder](#getfolder) | Returns the current folder, or the one the dialog will open in. |
| [AddPlace](#addplace) | Adds a folder to the navigation pane. |
| [SetNavigationRoot](#setnavigationroot) | Sets a folder the user cannot browse above. |
| [SetFileName](#setfilename) | Sets the text of the file name box. |
| [GetFileName](#getfilename) | Returns the text of the file name box. |
| [SetDefaultExtension](#setdefaultextension) | Sets the extension added to names typed without one. |
| [SetTitle](#settitle) | Sets the caption of the dialog. |
| [SetOkButtonLabel](#setokbuttonlabel) | Sets the text of the Open button. |
| [SetFileNameLabel](#setfilenamelabel) | Sets the label next to the file name box. |
| [SetCancelButtonLabel](#setcancelbuttonlabel) | Sets the text of the Cancel button. |
| [GetResult](#getresult) | Returns the chosen item as an `IShellItem`. |
| [GetResultString](#getresultstring) | Returns the name of the chosen item. |
| [GetResults](#getresults) | Returns every chosen item as an `IShellItemArray`. |
| [GetResultsString](#getresultsstring) | Returns the names of every chosen item, separated by "\|". |
| [GetResultsCount](#getresultscount) | Returns how many items were chosen. |
| [ParseResults](#parseresults) | Returns one name from a "\|" separated list. |
| [GetCurrentSelection](#getcurrentselection) | Returns the name of the item selected while the dialog is open. |
| [GetSelectedItems](#getselecteditems) | Returns the items selected while the dialog is open. |
| [SetEvents](#setevents) | Attaches an event handler that the destructor detaches. |
| [Advise](#advise) | Attaches an event handler and returns its cookie. |
| [Unadvise](#unadvise) | Detaches the event handler with that cookie. |
| [Close](#close) | Closes the dialog while it is open. |
| [SetClientGuid](#setclientguid) | Gives the dialog its own remembered state. |
| [ClearClientData](#clearclientdata) | Forgets the state remembered for the client GUID. |

**CISaveFileDialog**

| Member | Does |
| --- | --- |
| [Constructor](#constructor-1) | Starts COM and creates a Save dialog. |
| [Destructor](#destructor-1) | Detaches the event handler, releases the dialog and stops COM. |
| [GetPtr](#getptr-1) | Returns the dialog's `IFileSaveDialog` pointer. |
| [GetIFileDialogPtr](#getifiledialogptr-1) | Returns a new `IFileDialog` reference to the dialog. |
| [ShowSave](#showsave) | Shows the dialog and waits until the user closes it. |
| [AddFileType](#addfiletype-1) | Adds an entry to the file-type list the class keeps. |
| [SetFileTypes](#setfiletypes-1) | Gives the dialog its file types. |
| [SetFileTypeIndex](#setfiletypeindex-1) | Selects a file type by its one-based index. |
| [GetFileTypeIndex](#getfiletypeindex-1) | Returns the one-based index of the selected file type. |
| [SetOptions](#setoptions-1) | Sets the `FOS_*` option flags. |
| [GetOptions](#getoptions-1) | Returns the `FOS_*` option flags. |
| [SetFolder](#setfolder-1) | Sets the folder the dialog always opens in. |
| [SetDefaultFolder](#setdefaultfolder-1) | Sets the folder used when there is no recently used one. |
| [GetFolder](#getfolder-1) | Returns the current folder, or the one the dialog will open in. |
| [AddPlace](#addplace-1) | Adds a folder to the navigation pane. |
| [SetNavigationRoot](#setnavigationroot-1) | Sets a folder the user cannot browse above. |
| [SetFileName](#setfilename-1) | Sets the text of the file name box. |
| [GetFileName](#getfilename-1) | Returns the text of the file name box. |
| [SetDefaultExtension](#setdefaultextension-1) | Sets the extension added to names typed without one. |
| [SetTitle](#settitle-1) | Sets the caption of the dialog. |
| [SetOkButtonLabel](#setokbuttonlabel-1) | Sets the text of the Save button. |
| [SetFileNameLabel](#setfilenamelabel-1) | Sets the label next to the file name box. |
| [SetCancelButtonLabel](#setcancelbuttonlabel-1) | Sets the text of the Cancel button. |
| [GetResult](#getresult-1) | Returns the chosen item as an `IShellItem`. |
| [GetResultString](#getresultstring-1) | Returns the name of the chosen item. |
| [SetSaveAsItem](#setsaveasitem) | Opens the dialog on an existing file, as Save As does. |
| [SetProperties](#setproperties) | Gives default values for the properties of the saved file. |
| [SetCollectedProperties](#setcollectedproperties) | Chooses which properties the dialog lets the user edit. |
| [GetProperties](#getproperties) | Returns the property values the user ended with. |
| [ApplyProperties](#applyproperties) | Writes property values to the saved file. |
| [GetCurrentSelection](#getcurrentselection-1) | Returns the name of the item selected while the dialog is open. |
| [SetEvents](#setevents-1) | Attaches an event handler that the destructor detaches. |
| [Advise](#advise-1) | Attaches an event handler and returns its cookie. |
| [Unadvise](#unadvise-1) | Detaches the event handler with that cookie. |
| [Close](#close-1) | Closes the dialog while it is open. |
| [SetClientGuid](#setclientguid-1) | Gives the dialog its own remembered state. |
| [ClearClientData](#clearclientdata-1) | Forgets the state remembered for the client GUID. |

## CIOpenFileDialog

### Constructor

```freebasic
constructor
```

Calls `CoInitialize` and creates the shell's Open dialog. `GetLastError()` holds the `HRESULT`
of the creation afterwards: `S_OK` (0) when it worked. When it failed [GetPtr](#getptr) returns
`NULL`.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
if pofd.GetPtr() = NULL then print "no Open dialog: "; hex( GetLastError() )
```

Microsoft Learn: [CoCreateInstance](https://learn.microsoft.com/en-us/windows/win32/api/combaseapi/nf-combaseapi-cocreateinstance) with `CLSID_FileOpenDialog`

### Destructor

```freebasic
destructor
```

Detaches the event handler attached with [SetEvents](#setevents), releases the dialog and calls
`CoUninitialize`. A handler attached with [Advise](#advise) stays attached until the dialog itself
goes; detach it with [Unadvise](#unadvise) if it must stop first.

**Example**

```freebasic
scope
    dim pofd as CIOpenFileDialog
    pofd.ShowOpen( hwnd )
end scope   ' the dialog is released here
```

### GetPtr

```freebasic
function GetPtr() as IFileOpenDialog ptr
```

Returns the `IFileOpenDialog` pointer the object holds, for calling a method the class does not
wrap. The object keeps its reference: do not release the pointer. `IFileOpenDialog` extends
`IFileDialog`, so `cast( IFileDialog ptr, pofd.GetPtr() )` is an `IFileDialog` pointer that also
needs no release.

**Returns** the pointer, or `NULL` when the constructor could not create the dialog.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim pfd as IFileOpenDialog ptr = pofd.GetPtr()
pfd->lpVtbl->SetTitle( pfd, "Pick a file" )
```

Microsoft Learn: [IFileOpenDialog](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-ifileopendialog)

### GetIFileDialogPtr

```freebasic
function GetIFileDialogPtr() as IFileDialog ptr
```

Asks the dialog for its `IFileDialog` interface, which is what
[CIFileDialogCustomize](CIFileDialogCustomize) takes.

**Returns** a new reference: release it when done.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim pfd as IFileDialog ptr = pofd.GetIFileDialogPtr()
dim cust as CIFileDialogCustomize = pfd
pfd->lpVtbl->Release( pfd )
cust.AddCheckButton( 1, "Open as read-only" )
```

Microsoft Learn: [IFileDialog](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-ifiledialog)

### ShowOpen

```freebasic
function ShowOpen( byval hwndOwner as HWND ) as HRESULT
```

Shows the dialog, modal to `hwndOwner`, and returns when the user closes it. Set the dialog up
before the call and read the result after it.

| Parameter | Meaning |
| --- | --- |
| `hwndOwner` | The owner window, disabled while the dialog is open; `NULL` for none. |

**Returns** `S_OK` when the user chose a file; `HRESULT_FROM_WIN32( ERROR_CANCELLED )`
(`&h800704C7`) when the user cancelled; the code passed to [Close](#close) when an event handler
closed the dialog.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
if pofd.ShowOpen( hwnd ) = S_OK then print pofd.GetResultString( SIGDN_FILESYSPATH )
```

Microsoft Learn: [IModalWindow::Show](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-imodalwindow-show)

### AddFileType

```freebasic
sub AddFileType( byval pwszName as wstring ptr, byval pwszSpec as wstring ptr )
```

Adds one entry to the list of file types the object keeps; [SetFileTypes](#setfiletypes) with no
arguments then hands the whole list to the dialog. Only the two pointers are stored, not copies
of the text, so pass literals or strings that live as long as the dialog object.

| Parameter | Meaning |
| --- | --- |
| `pwszName` | The text shown in the file-type list, such as `"Text files"`. |
| `pwszSpec` | One or more patterns separated by semicolons, such as `"*.txt;*.log"`. |

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.AddFileType( "Source files", "*.tiko;*.ti" )
pofd.AddFileType( "All files", "*.*" )
pofd.SetFileTypes()
```

### SetFileTypes

```freebasic
function SetFileTypes() as HRESULT
function SetFileTypes( byval cFileTypes as UINT, byval rgFilterSpec as COMDLG_FILTERSPEC ptr ) as HRESULT
```

Gives the dialog the file types it offers. The first form passes the list built with
[AddFileType](#addfiletype); the second passes an array of `cFileTypes` `COMDLG_FILTERSPEC`
entries of your own. A dialog accepts its file types once: a second call fails with
`E_UNEXPECTED`, and so does the first form when no type was added.

| Parameter | Meaning |
| --- | --- |
| `cFileTypes` | The number of entries in the array. |
| `rgFilterSpec` | The first entry; each holds a `pszName` and a `pszSpec` pointer. |

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim rgSpec(0 to 1) as COMDLG_FILTERSPEC
rgSpec(0).pszName = @wstr( "Images" ) : rgSpec(0).pszSpec = @wstr( "*.png;*.jpg" )
rgSpec(1).pszName = @wstr( "All files" ) : rgSpec(1).pszSpec = @wstr( "*.*" )
pofd.SetFileTypes( 2, @rgSpec(0) )
```

Microsoft Learn: [IFileDialog::SetFileTypes](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setfiletypes)

### SetFileTypeIndex

```freebasic
function SetFileTypeIndex( byval iFileType as UINT ) as HRESULT
```

Selects the file type the dialog opens with. The index is **one-based**, in the order the types
were given to [SetFileTypes](#setfiletypes). Call it after `SetFileTypes` and before the dialog
is shown.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.AddFileType( "Text files", "*.txt" ) : pofd.AddFileType( "All files", "*.*" )
pofd.SetFileTypes()
pofd.SetFileTypeIndex( 2 )   ' All files
```

Microsoft Learn: [IFileDialog::SetFileTypeIndex](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setfiletypeindex)

### GetFileTypeIndex

```freebasic
function GetFileTypeIndex() as UINT
```

Returns the one-based index of the selected file type: the one set with
[SetFileTypeIndex](#setfiletypeindex) before the dialog is shown, the user's choice afterwards.

**Returns** the index, or 0 when it could not be read.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
if pofd.ShowOpen( hwnd ) = S_OK then print "file type"; pofd.GetFileTypeIndex()
```

Microsoft Learn: [IFileDialog::GetFileTypeIndex](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-getfiletypeindex)

### SetOptions

```freebasic
function SetOptions( byval fos as FILEOPENDIALOGOPTIONS ) as HRESULT
```

Replaces the dialog's option flags. Read the current ones with [GetOptions](#getoptions) and add
to them, so that the defaults stay. Common flags: `FOS_ALLOWMULTISELECT` (several files),
`FOS_PICKFOLDERS` (choose a folder instead of a file), `FOS_FORCEFILESYSTEM` (only file-system
items), `FOS_FORCESHOWHIDDEN` (show hidden and system items).

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetOptions( pofd.GetOptions() or FOS_PICKFOLDERS )   ' a folder picker
```

Microsoft Learn: [IFileDialog::SetOptions](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setoptions)

### GetOptions

```freebasic
function GetOptions() as FILEOPENDIALOGOPTIONS
```

Returns the dialog's option flags. A new Open dialog has `&h1808`: `FOS_NOCHANGEDIR`,
`FOS_PATHMUSTEXIST` and `FOS_FILEMUSTEXIST`.

**Returns** the flags. `GetLastError()` holds the `HRESULT` of the call.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
print hex( pofd.GetOptions() )   ' 1808
```

Microsoft Learn: [IFileDialog::GetOptions](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-getoptions)

### SetFolder

```freebasic
function SetFolder( byval pwzFolderName as wstring ptr ) as HRESULT
```

Makes the dialog open in a folder, given by its path, whatever folder the user used last. To
suggest a folder only for the first use, see [SetDefaultFolder](#setdefaultfolder).

| Parameter | Meaning |
| --- | --- |
| `pwzFolderName` | The folder's path, or another parsing name such as `"shell:Desktop"`. |

**Returns** `S_OK`; `&h80070002` when the folder does not exist; another error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetFolder( CurDir() )
```

Microsoft Learn: [IFileDialog::SetFolder](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setfolder)

### SetDefaultFolder

```freebasic
function SetDefaultFolder( byval psi as IShellItem ptr ) as HRESULT
```

Sets the folder the dialog opens in when it has no recently used folder to go back to. The
folder is a shell item; the dialog keeps its own reference, so release yours after the call.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim psi as IShellItem ptr
if SHGetKnownFolderItem( @FOLDERID_Desktop, 0, NULL, @IID_IShellItem, @psi ) = S_OK then
    pofd.SetDefaultFolder( psi )
    psi->lpVtbl->Release( psi )
end if
```

Microsoft Learn: [IFileDialog::SetDefaultFolder](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setdefaultfolder)

### GetFolder

```freebasic
function GetFolder( byval sigdnName as SIGDN = SIGDN_NORMALDISPLAY ) as ustring
```

Returns the folder the dialog shows while it is open, or, before it is shown, the folder it will
open in; after [SetFolder](#setfolder)`( "C:\Windows" )` it returns `Windows`, or `C:\Windows`
with `SIGDN_FILESYSPATH`.

**Returns** the name; an empty string on failure, with the `HRESULT` in `GetLastError()`.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetFolder( "C:\Windows" )
print pofd.GetFolder( SIGDN_FILESYSPATH )   ' C:\Windows
```

Microsoft Learn: [IFileDialog::GetFolder](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-getfolder)

### AddPlace

```freebasic
function AddPlace( byval psi as IShellItem ptr, byval fdap as FDAP ) as HRESULT
```

Adds a folder to the navigation pane on the left of the dialog.

| Parameter | Meaning |
| --- | --- |
| `psi` | The folder. Release your reference after the call. |
| `fdap` | `FDAP_TOP` puts it at the top of the list, `FDAP_BOTTOM` at the bottom. |

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim psi as IShellItem ptr
if SHCreateItemFromParsingName( "C:\Users\Public", NULL, @IID_IShellItem, @psi ) = S_OK then
    pofd.AddPlace( psi, FDAP_TOP )
    psi->lpVtbl->Release( psi )
end if
```

Microsoft Learn: [IFileDialog::AddPlace](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-addplace)

### SetNavigationRoot

```freebasic
function SetNavigationRoot( byval psi as IShellItem ptr ) as HRESULT
```

Sets the top of what the user can browse: the dialog does not navigate above this folder.

**Returns** the result of asking the dialog for `IFileDialog2`, which is `S_OK` on the Windows
versions that have the item dialogs. The result of setting the root itself is not returned.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim psi as IShellItem ptr
if SHCreateItemFromParsingName( "C:\Users\Public", NULL, @IID_IShellItem, @psi ) = S_OK then
    pofd.SetNavigationRoot( psi )
    psi->lpVtbl->Release( psi )
end if
```

Microsoft Learn: [IFileDialog2::SetNavigationRoot](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl/nf-shobjidl-ifiledialog2-setnavigationroot)

### SetFileName

```freebasic
function SetFileName( byval pwszName as wstring ptr ) as HRESULT
```

Puts text in the file name box the dialog opens with.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetFileName( "notes.txt" )
```

Microsoft Learn: [IFileDialog::SetFileName](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setfilename)

### GetFileName

```freebasic
function GetFileName() as ustring
```

Returns the text in the file name box: what the user typed while the dialog is open, or what
[SetFileName](#setfilename) put there. It is the text as typed, not a path.

**Returns** the text; an empty string, with `E_FAIL` in `GetLastError()`, when the box was never
filled.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetFileName( "notes.txt" )
print pofd.GetFileName()   ' notes.txt
```

Microsoft Learn: [IFileDialog::GetFileName](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-getfilename)

### SetDefaultExtension

```freebasic
function SetDefaultExtension( byval pwszDefaultExtension as wstring ptr ) as HRESULT
```

Sets the extension the dialog adds to a name the user types without one. Give it without the
dot.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetDefaultExtension( "txt" )
```

Microsoft Learn: [IFileDialog::SetDefaultExtension](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setdefaultextension)

### SetTitle

```freebasic
function SetTitle( byval pwszTitle as wstring ptr ) as HRESULT
```

Sets the dialog's caption in place of the default *Open*.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetTitle( "Open a project" )
```

Microsoft Learn: [IFileDialog::SetTitle](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-settitle)

### SetOkButtonLabel

```freebasic
function SetOkButtonLabel( byval pwszText as wstring ptr ) as HRESULT
```

Sets the text of the button that accepts the choice, *Open* by default.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetOkButtonLabel( "&Import" )
```

Microsoft Learn: [IFileDialog::SetOkButtonLabel](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setokbuttonlabel)

### SetFileNameLabel

```freebasic
function SetFileNameLabel( byval pwszLabel as wstring ptr ) as HRESULT
```

Sets the label next to the file name box, *File name:* by default.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetFileNameLabel( "Project:" )
```

Microsoft Learn: [IFileDialog::SetFileNameLabel](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setfilenamelabel)

### SetCancelButtonLabel

```freebasic
function SetCancelButtonLabel( byval pwszLabel as LPCWSTR ) as HRESULT
```

Sets the text of the *Cancel* button.

**Returns** the result of asking the dialog for `IFileDialog2`, which is `S_OK` on the Windows
versions that have the item dialogs. The result of setting the label itself is not returned.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetCancelButtonLabel( "&Never mind" )
```

Microsoft Learn: [IFileDialog2::SetCancelButtonLabel](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl/nf-shobjidl-ifiledialog2-setcancelbuttonlabel)

### GetResult

```freebasic
function GetResult() as IShellItem ptr
```

Returns the item the user chose, as a shell item, after `ShowOpen` returned `S_OK` or from an
[OnFileOk](SysWin-Gui-File-Dialog-Events#onfileok) handler. With `FOS_ALLOWMULTISELECT` use
[GetResults](#getresults) instead.

**Returns** a new reference that the caller releases, or `NULL` when there is no result. It does
not set `GetLastError()`.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
if pofd.ShowOpen( hwnd ) = S_OK then
    dim psi as IShellItem ptr = pofd.GetResult()
    ' ... psi->lpVtbl->BindToHandler, GetAttributes and so on
    psi->lpVtbl->Release( psi )
end if
```

Microsoft Learn: [IFileDialog::GetResult](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-getresult)

### GetResultString

```freebasic
function GetResultString( byval sigdnName as SIGDN = SIGDN_NORMALDISPLAY ) as ustring
```

Returns the name of the item the user chose. Pass `SIGDN_FILESYSPATH` for the full path.

**Returns** the name; an empty string when there is no result (`E_UNEXPECTED` in
`GetLastError()` before the dialog has been shown).

**Example**

```freebasic
dim pofd as CIOpenFileDialog
if pofd.ShowOpen( hwnd ) = S_OK then print pofd.GetResultString( SIGDN_FILESYSPATH )
```

Microsoft Learn: [IShellItem::GetDisplayName](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ishellitem-getdisplayname)

### GetResults

```freebasic
function GetResults() as IShellItemArray ptr
```

Returns every item the user chose, as a shell item array; it works with and without
`FOS_ALLOWMULTISELECT`. Read the array with `GetCount` and `GetItemAt`, release each item and
then the array.

**Returns** a new reference, or `NULL` when there is no result, with the `HRESULT` in
`GetLastError()`.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetOptions( pofd.GetOptions() or FOS_ALLOWMULTISELECT )
if pofd.ShowOpen( hwnd ) = S_OK then
    dim psia as IShellItemArray ptr = pofd.GetResults()
    dim n as DWORD
    psia->lpVtbl->GetCount( psia, @n )
    print n; " files"
    psia->lpVtbl->Release( psia )
end if
```

Microsoft Learn: [IFileOpenDialog::GetResults](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifileopendialog-getresults)

### GetResultsString

```freebasic
function GetResultsString( byval sigdnName as SIGDN = SIGDN_NORMALDISPLAY ) as ustring
```

Returns the names of every item the user chose, joined with "\|"and no spaces, in the order
the dialog gives them. Split the list with [ParseResults](#parseresults).

**Returns** the list, or an empty string when there is no result.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
pofd.SetOptions( pofd.GetOptions() or FOS_ALLOWMULTISELECT )
if pofd.ShowOpen( hwnd ) = S_OK then print pofd.GetResultsString( SIGDN_FILESYSPATH )
```

### GetResultsCount

```freebasic
function GetResultsCount() as long
```

Returns how many items the user chose: the number of names in
[GetResultsString](#getresultsstring).

**Returns** the count, 0 when there is no result, with the `HRESULT` in `GetLastError()`.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
if pofd.ShowOpen( hwnd ) = S_OK then print pofd.GetResultsCount(); " chosen"
```

### ParseResults

```freebasic
function ParseResults( byref wszMainStr as const wstring, byval index as long ) as ustring
```

Returns one name from a "\|" separated list such as the one
[GetResultsString](#getresultsstring) returns. It does not use the dialog: it only splits the
string.

| Parameter | Meaning |
| --- | --- |
| `wszMainStr` | The list. |
| `index` | Which name, counting from **1**. |

**Returns** the name; an empty string when `index` is 0, negative or past the last name. For
`"a.txt|b.txt|c.txt"`, index 2 gives `b.txt` and index 4 an empty string.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim ustrRes as ustring = "a.txt|b.txt|c.txt"
print pofd.ParseResults( ustrRes, 2 )   ' b.txt
```

### GetCurrentSelection

```freebasic
function GetCurrentSelection( byval sigdnName as SIGDN = SIGDN_NORMALDISPLAY ) as ustring
```

Returns the name of the item selected in the dialog at this moment. It is useful from an event
handler while the dialog is open; before the dialog is shown it fails.

**Returns** the name; an empty string, with `E_FAIL` in `GetLastError()`, when nothing is
selected.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
' in an event handler, while the dialog is open:
print "selected: "; pofd.GetCurrentSelection( SIGDN_FILESYSPATH )
```

Microsoft Learn: [IFileDialog::GetCurrentSelection](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-getcurrentselection)

### GetSelectedItems

```freebasic
function GetSelectedItems() as IShellItemArray ptr
```

Returns the items selected in the dialog at this moment, in the view or typed in the file name
box. It is useful from an event handler while the dialog is open.

**Returns** a new reference that the caller releases, or `NULL` with the `HRESULT` in
`GetLastError()`.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim psia as IShellItemArray ptr = pofd.GetSelectedItems()
if psia then psia->lpVtbl->Release( psia )
```

Microsoft Learn: [IFileOpenDialog::GetSelectedItems](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifileopendialog-getselecteditems)

### SetEvents

```freebasic
function SetEvents( byval pfde as IFileDialogEvents ptr ) as HRESULT
```

Attaches an event handler: an object of a type extending
[CIFileDialogEvents](SysWin-Gui-File-Dialog-Events), created with `new`. A handler attached
earlier with `SetEvents` is detached first, and the destructor detaches the last one. The dialog
holds a reference to the handler, and the handler deletes itself when the last reference goes,
so do not delete it yourself.

A pointer to a type extending `CIFileDialogEvents` does not convert to `IFileDialogEvents ptr`;
pass it through an `any ptr`.

**Returns** `S_OK`; `E_POINTER` for `NULL`; another error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim pfde as any ptr = new CIFileDialogEvents   ' or a type that extends it
pofd.SetEvents( pfde )
```

Microsoft Learn: [IFileDialog::Advise](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-advise)

### Advise

```freebasic
function Advise( byval pfde as IFileDialogEvents ptr ) as DWORD
```

Attaches an event handler like [SetEvents](#setevents), but leaves earlier handlers attached and
gives the cookie to you: pass it to [Unadvise](#unadvise) to detach the handler. The destructor
does not detach it.

**Returns** the cookie, or 0 on failure with the `HRESULT` in `GetLastError()`. For a `NULL`
handler it returns the value of `E_POINTER` (`&h80004003`) as if it were a cookie.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim pfde as any ptr = new CIFileDialogEvents
dim dwCookie as DWORD = pofd.Advise( pfde )
pofd.ShowOpen( hwnd )
pofd.Unadvise( dwCookie )
```

Microsoft Learn: [IFileDialog::Advise](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-advise)

### Unadvise

```freebasic
function Unadvise( byval dwCookie as DWORD ) as HRESULT
```

Detaches the event handler that [Advise](#advise) returned `dwCookie` for. The dialog releases
its reference to the handler.

**Returns** `S_OK`, or an error code. A cookie of 0 does nothing and returns `S_OK`.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
dim dwCookie as DWORD = pofd.Advise( cast( any ptr, new CIFileDialogEvents ) )
pofd.Unadvise( dwCookie )
```

Microsoft Learn: [IFileDialog::Unadvise](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-unadvise)

### Close

```freebasic
function Close( byval hr as HRESULT ) as HRESULT
```

Closes the dialog while it is open, as if the user had cancelled; `ShowOpen` then returns `hr`.
It is meant for an event handler. Before the dialog is shown it does nothing and returns `S_OK`.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim pofd as CIOpenFileDialog
' in an event handler, while the dialog is open:
pofd.Close( HRESULT_FROM_WIN32( ERROR_CANCELLED ) )
```

Microsoft Learn: [IFileDialog::Close](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-close)

### SetClientGuid

```freebasic
function SetClientGuid( byval guid as GUID ptr ) as HRESULT
```

The dialog remembers state between uses, such as the last folder, per program. A GUID of your
own gives a dialog its own set: an *Import* dialog and an *Export* dialog with different GUIDs
each go back to their own last folder. Call it before the other setup calls.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
static as GUID guidImport = ( &h4C1F0E2A, &h7B3D, &h4E5A, { &h91, &h2C, &h6D, &h0E, &h3A, &h55, &h18, &hB7 } )
dim pofd as CIOpenFileDialog
pofd.SetClientGuid( @guidImport )
```

Microsoft Learn: [IFileDialog::SetClientGuid](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setclientguid)

### ClearClientData

```freebasic
function ClearClientData() as HRESULT
```

Forgets the state the dialog remembered for the GUID set with [SetClientGuid](#setclientguid).

**Returns** `S_OK`, or an error code. In a test on a dialog not yet shown it returned `E_FAIL`
(`&h80004005`), with or without a client GUID.

**Example**

```freebasic
static as GUID guidImport = ( &h4C1F0E2A, &h7B3D, &h4E5A, { &h91, &h2C, &h6D, &h0E, &h3A, &h55, &h18, &hB7 } )
dim pofd as CIOpenFileDialog
pofd.SetClientGuid( @guidImport )
pofd.ClearClientData()
```

Microsoft Learn: [IFileDialog::ClearClientData](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-clearclientdata)

## CISaveFileDialog

The members shared with `CIOpenFileDialog` behave as described there; the entries below note
what differs for the Save dialog.

### Constructor

```freebasic
constructor
```

Calls `CoInitialize` and creates the shell's Save dialog, with the `HRESULT` of the creation in
`GetLastError()` afterwards.

**Example**

```freebasic
dim psfd as CISaveFileDialog
if psfd.GetPtr() = NULL then print "no Save dialog: "; hex( GetLastError() )
```

Microsoft Learn: [CoCreateInstance](https://learn.microsoft.com/en-us/windows/win32/api/combaseapi/nf-combaseapi-cocreateinstance) with `CLSID_FileSaveDialog`

### Destructor

```freebasic
destructor
```

Detaches the [SetEvents](#setevents-1) handler, releases the dialog and calls `CoUninitialize`.

**Example**

```freebasic
scope
    dim psfd as CISaveFileDialog
    psfd.ShowSave( hwnd )
end scope   ' the dialog is released here
```

### GetPtr

```freebasic
function GetPtr() as IFileSaveDialog ptr
```

Returns the `IFileSaveDialog` pointer the object holds. Do not release it.

**Returns** the pointer, or `NULL` when the dialog could not be created.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim pfd as IFileSaveDialog ptr = psfd.GetPtr()
pfd->lpVtbl->SetTitle( pfd, "Export" )
```

Microsoft Learn: [IFileSaveDialog](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-ifilesavedialog)

### GetIFileDialogPtr

```freebasic
function GetIFileDialogPtr() as IFileDialog ptr
```

Returns a new `IFileDialog` reference to the dialog. Release it when done.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim pfd as IFileDialog ptr = psfd.GetIFileDialogPtr()
dim cust as CIFileDialogCustomize = pfd
pfd->lpVtbl->Release( pfd )
```

### ShowSave

```freebasic
function ShowSave( byval hwndOwner as HWND ) as HRESULT
```

Shows the Save dialog, modal to `hwndOwner`, and returns when the user closes it. By default the
dialog asks before overwriting an existing file and refuses read-only ones (see
[GetOptions](#getoptions-1)). The dialog does not create the file: the program writes it to the
path it reads with [GetResultString](#getresultstring-1).

**Returns** `S_OK` when the user chose a name; `HRESULT_FROM_WIN32( ERROR_CANCELLED )`
(`&h800704C7`) when the user cancelled.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetFileName( "report.txt" )
if psfd.ShowSave( hwnd ) = S_OK then print "save to "; psfd.GetResultString( SIGDN_FILESYSPATH )
```

Microsoft Learn: [IModalWindow::Show](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-imodalwindow-show)

### AddFileType

```freebasic
sub AddFileType( byval pwszName as wstring ptr, byval pwszSpec as wstring ptr )
```

Adds an entry to the file-type list the object keeps, for [SetFileTypes](#setfiletypes-1). Only
the pointers are stored: pass literals or strings that live as long as the dialog object.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.AddFileType( "Text files", "*.txt" )
psfd.AddFileType( "CSV files", "*.csv" )
psfd.SetFileTypes()
```

### SetFileTypes

```freebasic
function SetFileTypes() as HRESULT
function SetFileTypes( byval cFileTypes as UINT, byval rgFilterSpec as COMDLG_FILTERSPEC ptr ) as HRESULT
```

Gives the dialog its file types, from the [AddFileType](#addfiletype-1) list or from your own
array; once per dialog. With file types and a default extension set, the Save dialog adds the
selected type's extension to a name typed without one.

**Returns** `S_OK`; `E_UNEXPECTED` on a second call or with an empty list.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim rgSpec(0 to 0) as COMDLG_FILTERSPEC
rgSpec(0).pszName = @wstr( "Text files" ) : rgSpec(0).pszSpec = @wstr( "*.txt" )
psfd.SetFileTypes( 1, @rgSpec(0) )
```

Microsoft Learn: [IFileDialog::SetFileTypes](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setfiletypes)

### SetFileTypeIndex

```freebasic
function SetFileTypeIndex( byval iFileType as UINT ) as HRESULT
```

Selects the file type, one-based, before the dialog is shown.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.AddFileType( "Text files", "*.txt" ) : psfd.AddFileType( "CSV files", "*.csv" )
psfd.SetFileTypes()
psfd.SetFileTypeIndex( 2 )
```

### GetFileTypeIndex

```freebasic
function GetFileTypeIndex() as UINT
```

Returns the one-based index of the file type the user saved as, so the program knows which
format to write.

**Example**

```freebasic
dim psfd as CISaveFileDialog
if psfd.ShowSave( hwnd ) = S_OK andalso psfd.GetFileTypeIndex() = 2 then print "write CSV"
```

### SetOptions

```freebasic
function SetOptions( byval fos as FILEOPENDIALOGOPTIONS ) as HRESULT
```

Replaces the option flags. `FOS_OVERWRITEPROMPT` is on by default; take it out to save over
existing files without asking. `FOS_STRICTFILETYPES` makes the dialog accept only names of the
selected type.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetOptions( psfd.GetOptions() or FOS_STRICTFILETYPES )
```

Microsoft Learn: [IFileDialog::SetOptions](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifiledialog-setoptions)

### GetOptions

```freebasic
function GetOptions() as FILEOPENDIALOGOPTIONS
```

Returns the option flags. A new Save dialog has `&h880A`: `FOS_OVERWRITEPROMPT`,
`FOS_NOCHANGEDIR`, `FOS_PATHMUSTEXIST` and `FOS_NOREADONLYRETURN`.

**Example**

```freebasic
dim psfd as CISaveFileDialog
print hex( psfd.GetOptions() )   ' 880A
```

### SetFolder

```freebasic
function SetFolder( byval pwzFolderName as wstring ptr ) as HRESULT
```

Makes the dialog open in the folder with this path, whatever folder was used last.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetFolder( "shell:Desktop" )
```

### SetDefaultFolder

```freebasic
function SetDefaultFolder( byval psi as IShellItem ptr ) as HRESULT
```

Sets the folder used when the dialog has no recently used one.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim psi as IShellItem ptr
if SHGetKnownFolderItem( @FOLDERID_Documents, 0, NULL, @IID_IShellItem, @psi ) = S_OK then
    psfd.SetDefaultFolder( psi )
    psi->lpVtbl->Release( psi )
end if
```

### GetFolder

```freebasic
function GetFolder( byval sigdnName as SIGDN = SIGDN_NORMALDISPLAY ) as ustring
```

Returns the folder shown while the dialog is open, or the one it will open in.

**Example**

```freebasic
dim psfd as CISaveFileDialog
print "opens in "; psfd.GetFolder( SIGDN_FILESYSPATH )
```

### AddPlace

```freebasic
function AddPlace( byval psi as IShellItem ptr, byval fdap as FDAP ) as HRESULT
```

Adds a folder to the navigation pane, at the top (`FDAP_TOP`) or bottom (`FDAP_BOTTOM`).

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim psi as IShellItem ptr
if SHCreateItemFromParsingName( "C:\Users\Public", NULL, @IID_IShellItem, @psi ) = S_OK then
    psfd.AddPlace( psi, FDAP_BOTTOM )
    psi->lpVtbl->Release( psi )
end if
```

### SetNavigationRoot

```freebasic
function SetNavigationRoot( byval psi as IShellItem ptr ) as HRESULT
```

Sets a folder the user cannot browse above, for instance in the folder tree the Save dialog
shows after *Browse Folders*. Returns the result of asking for `IFileDialog2`, not of setting
the root.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim psi as IShellItem ptr
if SHCreateItemFromParsingName( "C:\Users\Public", NULL, @IID_IShellItem, @psi ) = S_OK then
    psfd.SetNavigationRoot( psi )
    psi->lpVtbl->Release( psi )
end if
```

### SetFileName

```freebasic
function SetFileName( byval pwszName as wstring ptr ) as HRESULT
```

Suggests a name in the file name box.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetFileName( "report.txt" )
```

### GetFileName

```freebasic
function GetFileName() as ustring
```

Returns the text in the file name box, as typed.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetFileName( "report.txt" )
print psfd.GetFileName()   ' report.txt
```

### SetDefaultExtension

```freebasic
function SetDefaultExtension( byval pwszDefaultExtension as wstring ptr ) as HRESULT
```

Sets the extension, without the dot, added to a name typed without one.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetDefaultExtension( "csv" )
```

### SetTitle

```freebasic
function SetTitle( byval pwszTitle as wstring ptr ) as HRESULT
```

Sets the caption in place of *Save As*.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetTitle( "Export the report" )
```

### SetOkButtonLabel

```freebasic
function SetOkButtonLabel( byval pwszText as wstring ptr ) as HRESULT
```

Sets the text of the *Save* button.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetOkButtonLabel( "&Export" )
```

### SetFileNameLabel

```freebasic
function SetFileNameLabel( byval pwszLabel as wstring ptr ) as HRESULT
```

Sets the label next to the file name box.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetFileNameLabel( "Report name:" )
```

### SetCancelButtonLabel

```freebasic
function SetCancelButtonLabel( byval pwszLabel as LPCWSTR ) as HRESULT
```

Sets the text of the *Cancel* button. Returns the result of asking for `IFileDialog2`, not of
setting the label.

**Example**

```freebasic
dim psfd as CISaveFileDialog
psfd.SetCancelButtonLabel( "&Don't export" )
```

### GetResult

```freebasic
function GetResult() as IShellItem ptr
```

Returns the item the user saved as, a new reference to release. Unlike the Open dialog's, it
sets `GetLastError()` to the `HRESULT`: `E_UNEXPECTED` before the dialog has been shown.

**Example**

```freebasic
dim psfd as CISaveFileDialog
if psfd.ShowSave( hwnd ) = S_OK then
    dim psi as IShellItem ptr = psfd.GetResult()
    psi->lpVtbl->Release( psi )
end if
```

### GetResultString

```freebasic
function GetResultString( byval sigdnName as SIGDN = SIGDN_NORMALDISPLAY ) as ustring
```

Returns the name the user saved as; pass `SIGDN_FILESYSPATH` for the path to write to. Empty,
with `E_UNEXPECTED` in `GetLastError()`, before the dialog has been shown.

**Example**

```freebasic
dim psfd as CISaveFileDialog
if psfd.ShowSave( hwnd ) = S_OK then print psfd.GetResultString( SIGDN_FILESYSPATH )
```

### SetSaveAsItem

```freebasic
function SetSaveAsItem( byval psi as IShellItem ptr ) as HRESULT
```

Opens the dialog on an existing file, as a *Save As* command does: its folder is shown and its
name is in the file name box.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim psi as IShellItem ptr
if SHCreateItemFromParsingName( "C:\Users\Public\Documents\report.txt", NULL, @IID_IShellItem, @psi ) = S_OK then
    psfd.SetSaveAsItem( psi )
    psi->lpVtbl->Release( psi )
end if
```

Microsoft Learn: [IFileSaveDialog::SetSaveAsItem](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifilesavedialog-setsaveasitem)

### SetProperties

```freebasic
function SetProperties( byval pStore as IPropertyStore ptr ) as HRESULT
```

Gives the default values for the properties of the file being saved, such as its title or
author, which the dialog shows for editing with [SetCollectedProperties](#setcollectedproperties).

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim pStore as IPropertyStore ptr
if PSCreateMemoryPropertyStore( @IID_IPropertyStore, @pStore ) = S_OK then
    psfd.SetProperties( pStore )
    pStore->lpVtbl->Release( pStore )
end if
```

Microsoft Learn: [IFileSaveDialog::SetProperties](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifilesavedialog-setproperties)

### SetCollectedProperties

```freebasic
function SetCollectedProperties( byval pList as IPropertyDescriptionList ptr, byval fAppendDefault as WINBOOL ) as HRESULT
```

Chooses which properties the dialog lets the user edit for the file being saved.

| Parameter | Meaning |
| --- | --- |
| `pList` | The properties, as a property description list. |
| `fAppendDefault` | `TRUE` adds them to the ones the file type shows by default; `FALSE` shows only these. |

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim pList as IPropertyDescriptionList ptr
if PSGetPropertyDescriptionListFromString( "prop:System.Title;System.Author", @IID_IPropertyDescriptionList, @pList ) = S_OK then
    psfd.SetCollectedProperties( pList, TRUE )
    pList->lpVtbl->Release( pList )
end if
```

Microsoft Learn: [IFileSaveDialog::SetCollectedProperties](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifilesavedialog-setcollectedproperties)

### GetProperties

```freebasic
function GetProperties( byval ppStore as IPropertyStore ptr ptr ) as HRESULT
function GetProperties() as IPropertyStore ptr
```

Reads the property values the user ended with, after the dialog returned `S_OK`, into
`*ppStore`; release the store when done. Before the dialog has been shown it returns
`E_UNEXPECTED`.

The second form is declared but has no body: a program that calls it fails to link. Use the
first.

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim pStore as IPropertyStore ptr
if psfd.ShowSave( hwnd ) = S_OK andalso psfd.GetProperties( @pStore ) = S_OK then
    pStore->lpVtbl->Release( pStore )
end if
```

Microsoft Learn: [IFileSaveDialog::GetProperties](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifilesavedialog-getproperties)

### ApplyProperties

```freebasic
function ApplyProperties( byval psi as IShellItem ptr, byval pStore as IPropertyStore ptr, byval hWnd as HWND, byval pSink as IFileOperationProgressSink ptr ) as HRESULT
```

Writes property values to a file, normally the one just saved: write the file first, then apply
the store [GetProperties](#getproperties) returned.

| Parameter | Meaning |
| --- | --- |
| `psi` | The saved file. |
| `pStore` | The values to write. |
| `hWnd` | The owner of any window the operation shows. |
| `pSink` | A progress sink, or `NULL`. |

**Returns** `S_OK`, or an error code.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim pStore as IPropertyStore ptr
if psfd.ShowSave( hwnd ) = S_OK andalso psfd.GetProperties( @pStore ) = S_OK then
    dim psi as IShellItem ptr = psfd.GetResult()
    psfd.ApplyProperties( psi, pStore, hwnd, NULL )   ' after writing the file
    psi->lpVtbl->Release( psi ) : pStore->lpVtbl->Release( pStore )
end if
```

Microsoft Learn: [IFileSaveDialog::ApplyProperties](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ifilesavedialog-applyproperties)

### GetCurrentSelection

```freebasic
function GetCurrentSelection( byval sigdnName as SIGDN = SIGDN_NORMALDISPLAY ) as ustring
```

Returns the name of the item selected while the dialog is open; empty, with `E_FAIL` in
`GetLastError()`, when nothing is.

**Example**

```freebasic
dim psfd as CISaveFileDialog
' in an event handler, while the dialog is open:
print "selected: "; psfd.GetCurrentSelection()
```

### SetEvents

```freebasic
function SetEvents( byval pfde as IFileDialogEvents ptr ) as HRESULT
```

Attaches an event handler created with `new`, replacing the previous `SetEvents` handler; the
destructor detaches it. An `OnOverwrite` handler is called only by the Save dialog.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim pfde as any ptr = new CIFileDialogEvents
psfd.SetEvents( pfde )
```

### Advise

```freebasic
function Advise( byval pfde as IFileDialogEvents ptr ) as DWORD
```

Attaches another event handler and returns its cookie, for [Unadvise](#unadvise-1). Returns 0 on
failure, and `&h80004003` for a `NULL` handler.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim dwCookie as DWORD = psfd.Advise( cast( any ptr, new CIFileDialogEvents ) )
```

### Unadvise

```freebasic
function Unadvise( byval dwCookie as DWORD ) as HRESULT
```

Detaches the handler [Advise](#advise-1) returned the cookie for; a cookie of 0 does nothing.

**Example**

```freebasic
dim psfd as CISaveFileDialog
dim dwCookie as DWORD = psfd.Advise( cast( any ptr, new CIFileDialogEvents ) )
psfd.Unadvise( dwCookie )
```

### Close

```freebasic
function Close( byval hr as HRESULT ) as HRESULT
```

Closes the open dialog from an event handler; `ShowSave` returns `hr`.

**Example**

```freebasic
dim psfd as CISaveFileDialog
' in an event handler, while the dialog is open:
psfd.Close( HRESULT_FROM_WIN32( ERROR_CANCELLED ) )
```

### SetClientGuid

```freebasic
function SetClientGuid( byval guid as GUID ptr ) as HRESULT
```

Gives the dialog its own remembered state, such as its own last folder.

**Example**

```freebasic
static as GUID guidExport = ( &h0B7E2D41, &h3C9A, &h4F12, { &hA8, &h6B, &h21, &h5D, &hE0, &h4C, &h97, &h33 } )
dim psfd as CISaveFileDialog
psfd.SetClientGuid( @guidExport )
```

### ClearClientData

```freebasic
function ClearClientData() as HRESULT
```

Forgets the state remembered for the client GUID.

**Example**

```freebasic
static as GUID guidExport = ( &h0B7E2D41, &h3C9A, &h4F12, { &hA8, &h6B, &h21, &h5D, &hE0, &h4C, &h97, &h33 } )
dim psfd as CISaveFileDialog
psfd.SetClientGuid( @guidExport )
psfd.ClearClientData()
```

## See also

- [CIFileDialogCustomize](CIFileDialogCustomize) for adding controls to these dialogs
- [File dialog events](SysWin-Gui-File-Dialog-Events) for reacting while a dialog is open
- [Common dialogs](SysWin-Common-Dialogs) for the older open, save, folder and colour dialogs
- [CExplorerBrowser](CExplorerBrowser) for an Explorer view inside a window of your own
- [sys/win/gui](SysWin-Gui)
