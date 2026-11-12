[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **Explorer browser**

# Explorer browser
Hosts a Windows Explorer folder view in your window and reports where the user navigates.

<!-- scope: CExplorerBrowser -->
<!-- scope: CExplorerBrowserEvents -->

Hosts a Windows Explorer folder view in your window and reports where the user navigates.

The Explorer browser is the shell's own folder window, the view Explorer shows (icons, details,
tiles), with its navigation pane and commands when you ask for them, placed inside a window of
yours. Two classes cover it:

- [CExplorerBrowser](#cexplorerbrowser) creates the browser object, puts its view in your
  window, navigates and forwards everything else to the `IExplorerBrowser` interface;
- [CExplorerBrowserEvents](#cexplorerbrowserevents) is the base of an event handler: derive a
  type from it and redeclare the notifications you want.

**Sequence.** Create a `CExplorerBrowser` (usually with `new`, kept until `WM_DESTROY`), set its
options, call [Initialize](#initialize) with your window and a rectangle, attach a handler with
[SetEvents](#setevents) and navigate with [NavigateTo](#navigateto) or
[BrowseToIDList](#browsetoidlist). On `WM_SIZE` pass the new client rectangle to
[SetRect](#setrect). Deleting the object closes the view.

**COM.** The constructor initialises COM for the thread (single-threaded apartment, with OLE) and
the destructor uninitialises it, so create and use the object on the thread that runs your
window. The methods do not check that the browser object exists: when the constructor could not
create it, [GetPtr](#getptr) returns `NULL` and any other method fails on a null pointer, so
check `GetPtr()` once after creating.

**Results.** Each method returns the `HRESULT` of its call and also stores it, for
[GetLastResult](#getlastresult) and [GetErrorInfo](#geterrorinfo); [SetEvents](#setevents) only
returns it. The fields `m_Result`, `m_pExplorer` and `m_dwCookie` are public; use the methods.

**Item ID lists.** The shell names folders by item identifier lists (PIDLs) rather than paths.
The events hand you one for the folder concerned; `SHGetPathFromIDListW` turns it into a path
when the folder has one. A PIDL you create, for example with `SHParseDisplayName`, is freed
with `ILFree`.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A window that browses drive C: in Details view with the navigation pane, and shows the folder
reached in its caption:

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

' an event handler: shows the folder the browser has reached in the caption
type NavEvents extends CExplorerBrowserEvents
    hwndMain as HWND
    declare function OnNavigationComplete( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
end type

function NavEvents.OnNavigationComplete( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
    dim wszPath as wstring * MAX_PATH
    if SHGetPathFromIDListW( pidlFolder, @wszPath ) then SetWindowTextW( hwndMain, @wszPath )
    return S_OK
end function

dim shared pBrowser as CExplorerBrowser ptr

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "ExplorerDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Explorer browser", @WndProc )
    pWindow.SetClientSize( 640, 400 )
    pWindow.Center

    pBrowser = new CExplorerBrowser
    pBrowser->SetOptions( EBO_SHOWFRAMES )
    dim fs as FOLDERSETTINGS
    fs.ViewMode = FVM_DETAILS
    dim rc as RECT
    GetClientRect( hWin, @rc )
    pBrowser->Initialize( hWin, @rc, @fs )

    dim pEvents as NavEvents ptr = new NavEvents   ' the browser releases it
    pEvents->hwndMain = hWin
    pBrowser->SetEvents( cast( any ptr, pEvents ) )
    pBrowser->NavigateTo( "C:\" )

    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_SIZE
            dim rc as RECT
            GetClientRect( hwnd, @rc )
            if pBrowser then pBrowser->SetRect( NULL, rc )
            return 0
        case WM_DESTROY
            delete pBrowser
            pBrowser = NULL
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
| **CExplorerBrowser** | |
| [Constructor](#constructor) | Initialises COM and creates the browser object. |
| [Destructor](#destructor) | Detaches the handler, closes the browser and uninitialises COM. |
| [GetPtr](#getptr) | Returns the `IExplorerBrowser` interface. |
| [ObjPtr](#objptr) | Returns the interface with a reference of your own. |
| [GetLastResult](#getlastresult) | Returns the result of the last call. |
| [SetResult](#setresult) | Stores a result code. |
| [GetErrorInfo](#geterrorinfo) | Describes a result code in words. |
| [Initialize](#initialize) | Creates the browser's view in a window. |
| [Destroy](#destroy) | Closes the browser's view. |
| [SetRect](#setrect) | Moves and sizes the view. |
| [SetPropertyBag](#setpropertybag) | Names the store the view settings are kept under. |
| [SetEmptyText](#setemptytext) | Sets the text an empty folder shows. |
| [SetFolderSettings](#setfoldersettings) | Sets the view mode and folder flags. |
| [Advise](#advise) | Attaches an event handler and returns its cookie. |
| [Unadvise](#unadvise) | Detaches an event handler by cookie. |
| [SetOptions](#setoptions) | Sets the browser options. |
| [GetOptions](#getoptions) | Reads the browser options. |
| [BrowseToIDList](#browsetoidlist) | Navigates to a folder given by item ID list. |
| [BrowseToObject](#browsetoobject) | Navigates to a folder given by shell object. |
| [FillFromObject](#fillfromobject) | Shows a set of items as a results folder. |
| [RemoveAll](#removeall) | Empties the results folder. |
| [GetCurrentView](#getcurrentview) | Returns an interface of the current view. |
| [NavigateBack](#navigateback) | Goes back in the history. |
| [NavigateForward](#navigateforward) | Goes forward in the history. |
| [NavigateToParent](#navigatetoparent) | Goes up to the parent folder. |
| [NavigateTo](#navigateto) | Navigates to a path. |
| [SetEvents](#setevents) | Attaches an event handler, replacing the previous one. |
| **CExplorerBrowserEvents** | |
| [Constructor](#constructor-1) | Creates a handler with no references. |
| [Destructor](#destructor-1) | Destroys the handler. |
| [QueryInterface](#queryinterface) | Hands out the handler as `IExplorerBrowserEvents` or `IUnknown`. |
| [AddRef](#addref) | Adds a reference. |
| [Release](#release) | Drops a reference and deletes the handler at zero. |
| [OnNavigationPending](#onnavigationpending) | Called before the browser navigates. |
| [OnViewCreated](#onviewcreated) | Called when the view for a folder has been created. |
| [OnNavigationComplete](#onnavigationcomplete) | Called when a navigation has finished. |
| [OnNavigationFailed](#onnavigationfailed) | Called when a navigation has failed. |

## Reference

## CExplorerBrowser

The wrapper around the browser object. Its methods are listed in the order a program uses them.

### Constructor

```freebasic
constructor
```

Initialises COM for the calling thread with `OleInitialize` and creates the shell's Explorer
browser object. When COM was initialised here (or already was, on this thread) the destructor
uninitialises it once. Nothing appears until [Initialize](#initialize).

**Example**

```freebasic
dim pBrowser as CExplorerBrowser ptr = new CExplorerBrowser
if pBrowser->GetPtr() = NULL then print "no Explorer browser"
```

Microsoft Learn: [OleInitialize](https://learn.microsoft.com/en-us/windows/win32/api/ole2/nf-ole2-oleinitialize), [IExplorerBrowser](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-iexplorerbrowser)

### Destructor

```freebasic
destructor
```

Detaches the handler attached with [SetEvents](#setevents) (which releases it), closes the
browser's view, releases the browser object and uninitialises COM. Detach handlers attached with
[Advise](#advise) yourself before this.

**Example**

```freebasic
dim pBrowser as CExplorerBrowser ptr = new CExplorerBrowser
delete pBrowser     ' in WM_DESTROY: the view closes with it
```

### GetPtr

```freebasic
function GetPtr() as IExplorerBrowser ptr
```

Returns the `IExplorerBrowser` interface the object holds, for methods the class does not wrap.
No reference is added: do not release it.

**Returns** the interface, or `NULL` when the browser object could not be created.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim pEB as IExplorerBrowser ptr = eb.GetPtr()
if pEB then pEB->lpVtbl->SetOptions( pEB, EBO_NAVIGATEONCE )
```

### ObjPtr

```freebasic
function ObjPtr() as IExplorerBrowser ptr
```

Returns the same interface with a reference added, for code that will keep it.

**Returns** the interface; call its `Release` when done.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim pEB as IExplorerBrowser ptr = eb.ObjPtr()
if pEB then pEB->lpVtbl->Release( pEB )
```

Microsoft Learn: [IUnknown::AddRef](https://learn.microsoft.com/en-us/windows/win32/api/unknwn/nf-unknwn-iunknown-addref)

### GetLastResult

```freebasic
function GetLastResult() as HRESULT
```

Returns the `HRESULT` stored by the last method that called the browser, or set with
[SetResult](#setresult).

**Returns** the result code; `S_OK` (0) after a call that succeeded.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.NavigateBack()
if eb.GetLastResult() <> S_OK then print "cannot go back"
```

### SetResult

```freebasic
function SetResult( byval Result as HRESULT ) as HRESULT
```

Stores `Result` as the last result; the methods use it to record theirs.

**Returns** `Result`.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.SetResult( S_OK )
```

### GetErrorInfo

```freebasic
function GetErrorInfo( byval nError as long = -1 ) as ustring
```

Returns Windows' description of a result code: the last result when `nError` is -1. For any
nonzero code the text starts with `Error &h` and the code in hexadecimal, then a line break. The
description itself ends with a line break.

| Parameter | Meaning |
| --- | --- |
| `nError` | An `HRESULT` or Windows error code, or -1 for [GetLastResult](#getlastresult). |

**Returns** the text, for example `"Error &h80004002"`, a line break, then `"No such interface
supported"`; for 0 it is `"The operation completed successfully."`.

**Example**

```freebasic
dim eb as CExplorerBrowser
if eb.NavigateTo( "Q:\missing" ) <> S_OK then print eb.GetErrorInfo()
```

Microsoft Learn: [FormatMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-formatmessagew)

### Initialize

```freebasic
function Initialize( byval hwndParent as HWND, byval prc as RECT ptr, byval pfs as FOLDERSETTINGS ptr ) as HRESULT
```

Creates the browser's windows as children of `hwndParent`, in the rectangle `*prc` of its client
area, with the view mode and flags in `*pfs`. Call it once, after [SetOptions](#setoptions)
for options such as `EBO_SHOWFRAMES` that shape the window, and before navigating.

| Parameter | Meaning |
| --- | --- |
| `hwndParent` | Your window. |
| `prc` | The area of its client area the browser covers. |
| `pfs` | The view mode (`FVM_DETAILS`, `FVM_ICON`, `FVM_LIST`, `FVM_TILE` …) and `FWF_*` flags. |

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim fs as FOLDERSETTINGS
fs.ViewMode = FVM_ICON
dim rc as RECT = ( 0, 0, 400, 300 )
eb.Initialize( hwnd, @rc, @fs )
```

Microsoft Learn: [IExplorerBrowser::Initialize](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-initialize), [FOLDERSETTINGS](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ns-shobjidl_core-foldersettings)

### Destroy

```freebasic
function Destroy() as HRESULT
```

Closes the browser's view and its windows. The destructor calls it again, which does no harm.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.Destroy()
```

Microsoft Learn: [IExplorerBrowser::Destroy](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-destroy)

### SetRect

```freebasic
function SetRect( byval phdwp as HDWP ptr, byval rcBrowser as RECT ) as HRESULT
```

Moves and sizes the browser to `rcBrowser`, in the parent's client coordinates. Call it on
`WM_SIZE`. To move it together with other windows in one `BeginDeferWindowPos` batch, pass the
batch handle's address; `NULL` moves it at once.

| Parameter | Meaning |
| --- | --- |
| `phdwp` | The address of a deferred window position handle, or `NULL`. |
| `rcBrowser` | The new rectangle. |

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim rc as RECT
GetClientRect( hwnd, @rc )
eb.SetRect( NULL, rc )
```

Microsoft Learn: [IExplorerBrowser::SetRect](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-setrect)

### SetPropertyBag

```freebasic
function SetPropertyBag( byref wszPropertyBag as wstring ) as HRESULT
```

Names the property bag under which the browser keeps its view settings (view mode, columns,
sorting), so that two browsers in your program can remember different settings.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.SetPropertyBag( "MyApp.Browser" )
```

Microsoft Learn: [IExplorerBrowser::SetPropertyBag](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-setpropertybag)

### SetEmptyText

```freebasic
function SetEmptyText( byref wszEmptyText as wstring ) as HRESULT
```

Sets the text the view shows when the folder has no items.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.SetEmptyText( "Nothing here yet" )
```

Microsoft Learn: [IExplorerBrowser::SetEmptyText](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-setemptytext)

### SetFolderSettings

```freebasic
function SetFolderSettings( byval pfs as FOLDERSETTINGS ptr ) as HRESULT
function SetFolderSettings( byval ViewMode as UINT, byval fFlags as UINT ) as HRESULT
```

Changes the view mode and folder flags, as passed to [Initialize](#initialize). The second form
builds the `FOLDERSETTINGS` from its two values.

| Parameter | Meaning |
| --- | --- |
| `pfs` | The new settings. |
| `ViewMode` | An `FVM_*` view mode. |
| `fFlags` | `FWF_*` flags, or 0. |

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.SetFolderSettings( FVM_TILE, 0 )
```

Microsoft Learn: [IExplorerBrowser::SetFolderSettings](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-setfoldersettings)

### Advise

```freebasic
function Advise( byval psbe as IExplorerBrowserEvents ptr, byval pdwCookie as DWORD ptr ) as HRESULT
```

Attaches an event handler; the browser adds a reference to it. The class does not remember the
cookie: keep it and pass it to [Unadvise](#unadvise) before the object is destroyed.
[SetEvents](#setevents) does that bookkeeping for one handler. Pass a handler derived from
[CExplorerBrowserEvents](#cexplorerbrowserevents) as `cast( any ptr, p )`.

| Parameter | Meaning |
| --- | --- |
| `psbe` | The handler. |
| `pdwCookie` | Receives the cookie that identifies the connection. |

**Returns** the `HRESULT` (first form) or the cookie, 0 on failure (second form).

**Example**

```freebasic
dim eb as CExplorerBrowser
dim pEvents as CExplorerBrowserEvents ptr = new CExplorerBrowserEvents
dim dwCookie as DWORD = eb.Advise( cast( any ptr, pEvents ) )
eb.Unadvise( dwCookie )
```

Microsoft Learn: [IExplorerBrowser::Advise](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-advise)

### Unadvise

```freebasic
function Unadvise( byval dwCookie as DWORD ) as HRESULT
```

Detaches the handler attached with [Advise](#advise) under `dwCookie`; the browser releases its
reference.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim dwCookie as DWORD
if dwCookie then eb.Unadvise( dwCookie )
```

Microsoft Learn: [IExplorerBrowser::Unadvise](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-unadvise)

### SetOptions

```freebasic
function SetOptions( byval dwFlag as EXPLORER_BROWSER_OPTIONS ) as HRESULT
```

Sets the browser options, a combination of `EBO_*` flags: `EBO_SHOWFRAMES` shows the navigation
pane and command bar, `EBO_NAVIGATEONCE` allows a single navigation, `EBO_NOTRAVELLOG` keeps no
back and forward history, `EBO_NOBORDER` drops the border, and so on. `EBO_NONE` (0) is the
default.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.SetOptions( EBO_SHOWFRAMES or EBO_NOBORDER )
```

Microsoft Learn: [IExplorerBrowser::SetOptions](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-setoptions), [EXPLORER_BROWSER_OPTIONS](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-explorer_browser_options)

### GetOptions

```freebasic
function GetOptions( byval pdwFlag as EXPLORER_BROWSER_OPTIONS ptr ) as HRESULT
function GetOptions() as EXPLORER_BROWSER_OPTIONS
```

The first form reads the current options into `*pdwFlag`. The second form calls the same method
and returns the options.

| Parameter | Meaning |
| --- | --- |
| `pdwFlag` | Receives the `EBO_*` flags. |

**Returns** the `HRESULT` of the call, in both forms.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim opts as EXPLORER_BROWSER_OPTIONS
if eb.GetOptions( @opts ) = S_OK andalso ( opts and EBO_SHOWFRAMES ) then print "frames shown"
```

Microsoft Learn: [IExplorerBrowser::GetOptions](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-getoptions)

### BrowseToIDList

```freebasic
function BrowseToIDList( byval pidl as LPCITEMIDLIST, byval uFlags as UINT ) as HRESULT
```

Navigates to the folder `pidl` names. `uFlags` holds `SBSP_*` flags: `SBSP_ABSOLUTE` (0) for a
full ID list, `SBSP_RELATIVE` for one relative to the current folder, or, with a `NULL` `pidl`,
`SBSP_PARENT`, `SBSP_NAVIGATEBACK` or `SBSP_NAVIGATEFORWARD`. The ID list stays yours.

| Parameter | Meaning |
| --- | --- |
| `pidl` | The folder's item ID list, or `NULL` with the moves listed. |
| `uFlags` | `SBSP_*` flags. |

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim pidl as ITEMIDLIST ptr
if SUCCEEDED( SHGetFolderLocation( NULL, CSIDL_PERSONAL, NULL, 0, @pidl ) ) then
    eb.BrowseToIDList( pidl, SBSP_ABSOLUTE )
    ILFree( pidl )
end if
```

Microsoft Learn: [IExplorerBrowser::BrowseToIDList](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-browsetoidlist)

### BrowseToObject

```freebasic
function BrowseToObject( byval punk as IUnknown ptr, byval uFlags as UINT ) as HRESULT
```

Navigates to the folder a shell object stands for: an `IShellItem`, an `IShellFolder`, or any
object that can give its ID list. `uFlags` as for [BrowseToIDList](#browsetoidlist).

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim psi as IShellItem ptr
if SUCCEEDED( SHCreateItemFromParsingName( "C:\Windows", NULL, @IID_IShellItem, @psi ) ) then
    eb.BrowseToObject( cast( IUnknown ptr, psi ), SBSP_ABSOLUTE )
    psi->lpVtbl->Release( psi )
end if
```

Microsoft Learn: [IExplorerBrowser::BrowseToObject](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-browsetoobject)

### FillFromObject

```freebasic
function FillFromObject( byval punk as IUnknown ptr, byval dwFlags as EXPLORER_BROWSER_FILL_FLAGS ) as HRESULT
```

Shows a set of items you choose, instead of a real folder, as a results folder: `punk` is an
`IShellItemArray`, an `IDataObject`, an `IEnumIDList` or similar. `EBF_SELECTFROMDATAOBJECT`
selects the items of a data object; `EBF_NODROPTARGET` refuses drops; `EBF_NONE` is plain.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim pItems as IShellItemArray ptr        ' from a file dialog or SHCreateShellItemArray
if pItems then eb.FillFromObject( cast( IUnknown ptr, pItems ), EBF_NONE )
```

Microsoft Learn: [IExplorerBrowser::FillFromObject](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-fillfromobject)

### RemoveAll

```freebasic
function RemoveAll() as HRESULT
```

Removes every item from the results folder shown with [FillFromObject](#fillfromobject).

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.RemoveAll()
```

Microsoft Learn: [IExplorerBrowser::RemoveAll](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-removeall)

### GetCurrentView

```freebasic
function GetCurrentView( byval riid as IID ptr, byval ppv as any ptr ptr ) as HRESULT
function GetCurrentView( byval riid as IID ptr ) as any ptr
```

Returns an interface of the view now shown, such as `IShellView`, `IFolderView` or
`IFolderView2`, to read the selection or change the view. The interface comes with a reference:
release it. The `IID_*` constants are `const`, so pass them as `cast( IID ptr, @IID_IShellView )`.

| Parameter | Meaning |
| --- | --- |
| `riid` | The interface wanted. |
| `ppv` | Receives the interface. |

**Returns** the `HRESULT` (first form), or the interface, `NULL` on failure, with the result in
[GetLastResult](#getlastresult) (second form).

**Example**

```freebasic
dim eb as CExplorerBrowser
dim pView as IShellView ptr = eb.GetCurrentView( cast( IID ptr, @IID_IShellView ) )
if pView then pView->lpVtbl->Release( pView )
```

Microsoft Learn: [IExplorerBrowser::GetCurrentView](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowser-getcurrentview)

### NavigateBack

```freebasic
function NavigateBack() as HRESULT
```

Goes back to the previous folder in the browser's history.

**Returns** `S_OK` on success, or an error code: `E_FAIL` before [Initialize](#initialize).

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.NavigateBack()
```

### NavigateForward

```freebasic
function NavigateForward() as HRESULT
```

Goes forward again after [NavigateBack](#navigateback).

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.NavigateForward()
```

### NavigateToParent

```freebasic
function NavigateToParent() as HRESULT
```

Goes up to the folder that contains the current one.

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
eb.NavigateToParent()
```

### NavigateTo

```freebasic
function NavigateTo( byref wszPath as wstring ) as HRESULT
```

Navigates to a folder given by path, or by any name the shell can parse such as
`"shell:Downloads"`: it turns the name into an ID list, browses to it and frees the list.

| Parameter | Meaning |
| --- | --- |
| `wszPath` | The folder's path or shell name. |

**Returns** `S_OK` on success, otherwise the error from parsing the name (`&h8007000F` for a
drive that does not exist, `&h80070002` for a missing folder) or from browsing.

**Example**

```freebasic
dim eb as CExplorerBrowser
if eb.NavigateTo( "shell:Downloads" ) <> S_OK then eb.NavigateTo( "C:\" )
```

Microsoft Learn: [SHParseDisplayName](https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shparsedisplayname)

### SetEvents

```freebasic
function SetEvents( byval pebe as IExplorerBrowserEvents ptr ) as HRESULT
```

Attaches an event handler and remembers its cookie, detaching the handler a previous call
attached. The destructor detaches the last one. Once attached the handler belongs to the
browser: create it with `new`, pass it as `cast( any ptr, p )`, and do not delete it; it deletes
itself when the browser lets go of it. The result is not stored for
[GetLastResult](#getlastresult).

| Parameter | Meaning |
| --- | --- |
| `pebe` | The handler. |

**Returns** `S_OK` on success, `E_POINTER` for `NULL`, or an error code.

**Example**

```freebasic
dim eb as CExplorerBrowser
dim pEvents as CExplorerBrowserEvents ptr = new CExplorerBrowserEvents
if eb.SetEvents( cast( any ptr, pEvents ) ) <> S_OK then delete pEvents
```

## CExplorerBrowserEvents

The base of an event handler: a COM object implementing `IExplorerBrowserEvents`, whose four
notifications do nothing and return `S_OK`. Derive a type from it and declare, with the same
parameters, the notifications you want; the browser then calls yours. The reference count
starts at 0 and [Release](#release) deletes the object when it drops back to 0, so create
handlers with `new` and hand them to [SetEvents](#setevents) or [Advise](#advise).

The notifications run on your window's thread while it pumps messages. The ID lists they
receive belong to the browser: use them during the call and do not free them.

### Constructor

```freebasic
constructor
```

Creates a handler whose reference count is 0.

**Example**

```freebasic
dim pEvents as CExplorerBrowserEvents ptr = new CExplorerBrowserEvents
pEvents->AddRef()
pEvents->Release()          ' back to 0: the handler deletes itself
```

### Destructor

```freebasic
virtual destructor
```

Runs when [Release](#release) brings the count to 0. A derived type can declare its own
destructor to free what it holds.

**Example**

```freebasic
dim pEvents as CExplorerBrowserEvents ptr = new CExplorerBrowserEvents
delete pEvents              ' only for a handler that was never attached
```

### QueryInterface

```freebasic
virtual function QueryInterface( byval as REFIID, byval as PVOID ptr ) as HRESULT
```

Hands out the handler itself for `IID_IExplorerBrowserEvents` and `IID_IUnknown`.

**Returns** `S_OK`, `E_NOINTERFACE` for another interface, or `E_INVALIDARG` for a `NULL`
pointer.

**Example**

```freebasic
dim pEvents as CExplorerBrowserEvents ptr = new CExplorerBrowserEvents
dim pUnk as any ptr
if pEvents->QueryInterface( @IID_IUnknown, @pUnk ) = S_OK then print pUnk = pEvents
delete pEvents
```

Microsoft Learn: [IUnknown::QueryInterface](https://learn.microsoft.com/en-us/windows/win32/api/unknwn/nf-unknwn-iunknown-queryinterface%28refiid_void%29)

### AddRef

```freebasic
virtual function AddRef() as ULONG
```

Adds a reference.

**Returns** the new count.

**Example**

```freebasic
dim pEvents as CExplorerBrowserEvents ptr = new CExplorerBrowserEvents
print pEvents->AddRef()     ' 1
pEvents->Release()
```

Microsoft Learn: [IUnknown::AddRef](https://learn.microsoft.com/en-us/windows/win32/api/unknwn/nf-unknwn-iunknown-addref)

### Release

```freebasic
virtual function Release() as ULONG
```

Drops a reference; at 0 the handler deletes itself with `delete`.

**Returns** the new count.

**Example**

```freebasic
dim pEvents as CExplorerBrowserEvents ptr = new CExplorerBrowserEvents
pEvents->AddRef()
pEvents->AddRef()
print pEvents->Release()    ' 1
pEvents->Release()          ' 0: deleted
```

Microsoft Learn: [IUnknown::Release](https://learn.microsoft.com/en-us/windows/win32/api/unknwn/nf-unknwn-iunknown-release)

### OnNavigationPending

```freebasic
virtual function OnNavigationPending( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
```

Called before the browser navigates to `pidlFolder`. Return `S_OK` to let it go ahead; a failure
code cancels the navigation.

**Returns** `S_OK` in the base class.

**Example**

```freebasic
type StayOnC extends CExplorerBrowserEvents
    declare function OnNavigationPending( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
end type
function StayOnC.OnNavigationPending( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
    dim wszPath as wstring * MAX_PATH
    SHGetPathFromIDListW( pidlFolder, @wszPath )
    return iif( lcase( left( wszPath, 2 ) ) = "c:", S_OK, E_FAIL )
end function
```

Microsoft Learn: [IExplorerBrowserEvents::OnNavigationPending](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowserevents-onnavigationpending)

### OnViewCreated

```freebasic
virtual function OnViewCreated( byval psv as IShellView ptr ) as HRESULT
```

Called when the view for the new folder has been created, before it is shown: the moment to
change it through `psv` (or its `IFolderView2`). `psv` is the browser's; add a reference to keep
it.

**Returns** `S_OK` in the base class.

**Example**

```freebasic
type ViewWatcher extends CExplorerBrowserEvents
    declare function OnViewCreated( byval psv as IShellView ptr ) as HRESULT
end type
function ViewWatcher.OnViewCreated( byval psv as IShellView ptr ) as HRESULT
    OutputDebugStringW( "view created" )
    return S_OK
end function
```

Microsoft Learn: [IExplorerBrowserEvents::OnViewCreated](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowserevents-onviewcreated)

### OnNavigationComplete

```freebasic
virtual function OnNavigationComplete( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
```

Called when the browser has reached `pidlFolder` and shows it; the page's example uses it to put
the path in the caption.

**Returns** `S_OK` in the base class.

**Example**

```freebasic
type NavLog extends CExplorerBrowserEvents
    declare function OnNavigationComplete( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
end type
function NavLog.OnNavigationComplete( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
    dim wszPath as wstring * MAX_PATH
    if SHGetPathFromIDListW( pidlFolder, @wszPath ) then OutputDebugStringW( @wszPath )
    return S_OK
end function
```

Microsoft Learn: [IExplorerBrowserEvents::OnNavigationComplete](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowserevents-onnavigationcomplete)

### OnNavigationFailed

```freebasic
virtual function OnNavigationFailed( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
```

Called when a navigation to `pidlFolder` could not be completed, for example because the folder
cannot be opened.

**Returns** `S_OK` in the base class.

**Example**

```freebasic
type NavErrors extends CExplorerBrowserEvents
    declare function OnNavigationFailed( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
end type
function NavErrors.OnNavigationFailed( byval pidlFolder as LPCITEMIDLIST ) as HRESULT
    MessageBeep( MB_ICONWARNING )
    return S_OK
end function
```

Microsoft Learn: [IExplorerBrowserEvents::OnNavigationFailed](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorerbrowserevents-onnavigationfailed)

## See also

- [CWindow](CWindow) for the window that hosts the browser
- [File dialogs](SysWin-Gui-File-Dialogs) for choosing files and folders in the standard dialogs
- [Common dialogs](SysWin-Common-Dialogs) for the folder picker and the other standard dialogs
- [COM procedures](SysWin-Com-Procedures) for working with COM objects
- [sys/win/gui](SysWin-Gui)
