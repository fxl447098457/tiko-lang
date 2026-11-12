[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkFileDialog**

# tkFileDialog

Shows the system open, save and folder dialogs and returns the chosen paths.

tkFileDialog wraps the OS's own file dialogs (the Windows file dialog, the desktop portal or zenity on Linux, the system's panels on macOS) for a tkControls program. SDL's dialogs are asynchronous and may answer on another thread; tkFileDialog brings the answer back to the UI thread, so you can take it two ways:

- **Callback:** `tkFileDialog_Show` returns at once, and your callback runs on the UI thread when the user answers, from whichever loop is pumping (a modal form's included).
- **Waiting:** `tkFileDialog_Wait` keeps the program's loop running until the user answers, then returns the paths. `tkFileDialog_OpenFile`, `SaveFile` and `PickFolder` are its one-path shorthands, returning `""` when cancelled.

## Importing

```freebasic
#import "std/containers"
#import "vendor/tkControls/tkFileDialog"

using containers
using tkFileDialog
using tkHost
```

The answer is an `Array( of ustring )`, so import `std/containers` to name it. tkFileDialog re-exports [tkHost](tkHost).

## Example

```freebasic
sub OnOpened( byval owner as TK_HOST ptr, byref paths as Array( of ustring ), _
              byval filterIndex as long, byval bError as boolean, byval user as any ptr )
    if bError then print "no dialog: " & tkFileDialog_LastError() : exit sub
    for each p as ustring in paths          ' empty when the user cancelled
        print "open " & p
    next
end sub

' the callback form: returns at once
tkFileDialog_Show( TKFD_OPEN, tkForm_Host( f ), "Tiko source|*.tiko;*.ti|All files|*.*", "", true, @OnOpened )

' the waiting form
dim as ustring target = tkFileDialog_SaveFile( tkForm_Host( f ), "Text|*.txt" )
if len( target ) then print "save to " & target
```

`f` is a [tkApp](tkApp) form; the owner is a [tkHost](tkHost) surface, which the dialog is shown over.

- **Kinds:** `TKFD_OPEN` (with `allowMany` for several files), `TKFD_SAVE`, `TKFD_FOLDER`.
- **Filters** are one string of name and pattern pairs, `"Name|*.a;*.b|All files|*.*"`. The callback's `filterIndex` is the filter the user chose, or -1.
- **The default path** is a folder or file to start in; `""` lets the OS choose.
- **Errors:** `bError` (callback) or a FALSE `tkFileDialog_Wait` with `tkFileDialog_LastError` set means the dialog could not be shown at all. A cancel is not an error: the paths are just empty.
- **Tests:** `tkFileDialog_SetDriver` replaces the native dialogs with a procedure of your own that answers through the same path; `0` restores them.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKFD_OPEN = 0
const TKFD_SAVE = 1
const TKFD_FOLDER = 2
```

### Types

```freebasic
type TKFD_ResultSub as sub( byval owner as TK_HOST ptr, byref paths as Array( of ustring ), byval filterIndex as long, byval bError as boolean, byval user as any ptr )
type TKFD_DriverSub as sub( byval kind as long, byval cb as SDL_DialogFileCallback, byval userdata as any ptr, byval win as SDL_Window ptr, byval filters as const SDL_DialogFileFilter ptr, byval nFilters as long, byval defaultLocation as const zstring ptr, byval allowMany as boolean )
```

### Procedures

```freebasic
function tkFileDialog_LastError() as string
sub tkFileDialog_SetDriver( byval d as TKFD_DriverSub )
sub tkFileDialog_Show( byval kind as long, byval owner as TK_HOST ptr, byref filters as string, byref defaultPath as ustring, byval allowMany as boolean, byval cb as TKFD_ResultSub, byval user as any ptr = 0 )
function tkFileDialog_Wait( byval kind as long, byval owner as TK_HOST ptr, byref filters as string, byref defaultPath as ustring, byval allowMany as boolean, byref paths as Array( of ustring ) ) as boolean
function tkFileDialog_OpenFile( byval owner as TK_HOST ptr, byref filters as string, byref defaultPath as ustring = "" ) as ustring
function tkFileDialog_SaveFile( byval owner as TK_HOST ptr, byref filters as string, byref defaultPath as ustring = "" ) as ustring
function tkFileDialog_PickFolder( byval owner as TK_HOST ptr, byref defaultPath as ustring = "" ) as ustring
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
