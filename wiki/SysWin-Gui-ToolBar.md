[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **ToolBar**

# ToolBar

Adds, changes and queries the buttons of a toolbar control and the images they show.

A toolbar is a row of buttons, usually under the menu bar, that send `WM_COMMAND` to the parent
with the button's **command identifier** when they are clicked, just as menu items do. Create
one with `CWindow.AddControl( "Toolbar", ... )`, which also tells the control the size of
`TBBUTTON` (a toolbar made with `CreateWindowExW` needs [ButtonStructSize](#buttonstructsize)
first). Every function here takes the toolbar's handle first and is written with the namespace:
`ToolBar.AddButton( hToolBar, ... )`.

Buttons have two numbers, and each function says which one it takes:

| Number | What it is | Taken by |
| --- | --- | --- |
| Command identifier | the id you gave the button; fixed | `CheckButton`, `EnableButton`, `GetState`, `GetRect`, `GetButtonText` … |
| Index | the button's position from the left, separators counted; changes as buttons are added, moved or deleted | `GetButton`, `GetItemRect`, `DeleteButton`, `MoveButton`, `InsertButton` |

[CommandToIndex](#commandtoindex) converts one to the other.

The pictures come from image lists: one for the normal state, and optionally one each for hot
(under the mouse), disabled and pressed buttons. A button's image number is an index into them.
[LoadImages](#loadimages) fills the normal list with the standard Windows images; your own
lists are made with `ImageList_Create` and are yours to destroy, after the toolbar is gone or
when you replace them. Rectangles are client coordinates of the toolbar. Several messages (padding
metrics, themes, pressed images, list gap) need version 6 of the common controls: give the
program a manifest or call `EnableVisualStyles()` first.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A toolbar with the standard New, Open and Save images and a check button. Save is disabled
until New or Open is clicked; the check button reports its state in the caption.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_TOOLBAR = 100
enum
    IDM_NEW = 1001
    IDM_OPEN
    IDM_SAVE
    IDM_LOCK
end enum

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    EnableVisualStyles()
    dim pWindow as CWindow = "ToolBarDemo"
    dim hWin as HWND = pWindow.Create( NULL, "ToolBar", @WndProc )
    pWindow.SetClientSize( 420, 200 )
    pWindow.Center()
    dim hToolBar as HWND = pWindow.AddControl( "Toolbar", hWin, IDC_TOOLBAR )
    ToolBar.LoadImages( hToolBar, IDB_STD_SMALL_COLOR )
    ToolBar.AddButton( hToolBar, STD_FILENEW, IDM_NEW, 0, BTNS_AUTOSIZE, 0, "New" )
    ToolBar.AddButton( hToolBar, STD_FILEOPEN, IDM_OPEN, 0, BTNS_AUTOSIZE, 0, "Open" )
    ToolBar.AddButton( hToolBar, STD_FILESAVE, IDM_SAVE, 0, BTNS_AUTOSIZE, 0, "Save" )
    ToolBar.AddSeparator( hToolBar )
    ToolBar.AddButton( hToolBar, STD_PROPERTIES, IDM_LOCK, 0, BTNS_CHECK or BTNS_AUTOSIZE, 0, "Lock" )
    ToolBar.DisableButton( hToolBar, IDM_SAVE )
    ToolBar.AutoSize( hToolBar )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_SIZE
            ToolBar.AutoSize( GetDlgItem( hwnd, IDC_TOOLBAR ) )
            return 0
        case WM_COMMAND
            dim hToolBar as HWND = GetDlgItem( hwnd, IDC_TOOLBAR )
            select case CBCTL( wParam, lParam )
                case IDM_NEW, IDM_OPEN
                    ToolBar.EnableButton( hToolBar, IDM_SAVE )
                    SetWindowText( hwnd, "Clicked " & ToolBar.GetButtonText( hToolBar, CBCTL( wParam, lParam ) ) )
                case IDM_SAVE
                    ToolBar.DisableButton( hToolBar, IDM_SAVE )
                    SetWindowText( hwnd, "Saved" )
                case IDM_LOCK
                    SetWindowText( hwnd, iif( ToolBar.IsButtonChecked( hToolBar, IDM_LOCK ), "Locked", "Unlocked" ) )
            end select
            return 0
        case WM_DESTROY
            PostQuitMessage( 0 )
            return 0
    end select
    return DefWindowProcW( hwnd, uMsg, wParam, lParam )
end function

end main()
```

The toolbar sits at the top of the client area by itself (`CCS_TOP`); calling
[AutoSize](#autosize) from `WM_SIZE` keeps it the width of the window.

## Functions

| Function | Does |
| --- | --- |
| [AddButton](#addbutton) | Adds one button from its parts. |
| [AddButtons](#addbuttons) | Adds buttons from an array of `TBBUTTON`. |
| [AddSeparator](#addseparator) | Adds a separator. |
| [InsertButton](#insertbutton) | Inserts a button at an index. |
| [InsertSeparator](#insertseparator) | Inserts a separator at an index. |
| [DeleteButton](#deletebutton) | Deletes the button at an index. |
| [MoveButton](#movebutton) | Moves a button to another index. |
| [ButtonCount](#buttoncount) | Returns the number of buttons and separators. |
| [ButtonStructSize](#buttonstructsize) | Tells the toolbar the size of `TBBUTTON`. |
| [AutoSize](#autosize) | Resizes the toolbar to fit its buttons and its parent. |
| [CommandToIndex](#commandtoindex) | Returns the index of the button with a command identifier. |
| [SetCmdId](#setcmdid) | Changes the command identifier of the button at an index. |
| [GetButton](#getbutton) | Reads the `TBBUTTON` of the button at an index. |
| [GetButtonInfo](#getbuttoninfo) | Reads a button's attributes into a `TBBUTTONINFOW`. |
| [SetButtonInfo](#setbuttoninfo) | Changes a button's attributes from a `TBBUTTONINFOW`. |
| [CheckButton, UncheckButton](#checkbutton-uncheckbutton) | Checks or unchecks a button. |
| [EnableButton, DisableButton](#enablebutton-disablebutton) | Enables or disables a button. |
| [HideButton, UnhideButton](#hidebutton-unhidebutton) | Hides or shows a button. |
| [PressButton, ReleaseButton](#pressbutton-releasebutton) | Draws a button pressed or released. |
| [MarkButton, HighlightButton, UnhighlightButton](#markbutton-highlightbutton-unhighlightbutton) | Sets or clears a button's highlight. |
| [Indeterminate](#indeterminate) | Sets or clears a button's indeterminate (greyed) state. |
| [IsButtonChecked, IsButtonEnabled, IsButtonHidden, IsButtonHighlighted, IsButtonIndeterminate, IsButtonPressed](#isbuttonchecked-isbuttonenabled-isbuttonhidden-isbuttonhighlighted-isbuttonindeterminate-isbuttonpressed) | Test one state of a button. |
| [GetState](#getstate) | Returns all the state flags of a button. |
| [SetState](#setstate) | Sets all the state flags of a button. |
| [GetButtonText](#getbuttontext) | Returns or reads the text of a button. |
| [GetButtonTextLength](#getbuttontextlength) | Returns the length of a button's text. |
| [AddString](#addstring) | Adds strings to the toolbar's string pool. |
| [GetString](#getstring) | Reads a string from the string pool. |
| [MapAccelerator](#mapaccelerator) | Finds the button whose text has a given accelerator letter. |
| [SetMaxTextRows](#setmaxtextrows) | Sets how many lines of text a button may show. |
| [GetTextRows](#gettextrows) | Returns how many lines of text a button may show. |
| [SetDrawTextFlags](#setdrawtextflags) | Sets the `DrawText` flags for button text. |
| [LoadImages](#loadimages) | Loads a set of standard Windows images. |
| [AddBitmap](#addbitmap) | Adds images from a bitmap. |
| [ReplaceBitmap](#replacebitmap) | Replaces images added from a bitmap. |
| [SetBitmapSize](#setbitmapsize) | Sets the size of the images to be added. |
| [GetBitmapFlags](#getbitmapflags) | Says whether large images should be used. |
| [GetBitmap](#getbitmap) | Returns a button's image number. |
| [ChangeBitmap](#changebitmap) | Changes a button's image number. |
| [GetImageList, SetImageList](#getimagelist-setimagelist) | Read or set the normal image list. |
| [GetHotImageList, SetHotImageList](#gethotimagelist-sethotimagelist) | Read or set the image list for hot buttons. |
| [GetDisabledImageList, SetDisabledImageList](#getdisabledimagelist-setdisabledimagelist) | Read or set the image list for disabled buttons. |
| [SetPressedImageList](#setpressedimagelist) | Sets the image list for pressed buttons. |
| [GetImageListCount](#getimagelistcount) | Returns the number of normal image lists. |
| [GetButtonSize, GetButtonWidth, GetButtonHeight](#getbuttonsize-getbuttonwidth-getbuttonheight) | Return the button size. |
| [SetButtonSize](#setbuttonsize) | Sets the button size. |
| [SetButtonWidth](#setbuttonwidth) | Sets the smallest and largest button width. |
| [GetItemRect](#getitemrect) | Returns the rectangle of the button at an index. |
| [GetRect](#getrect) | Returns the rectangle of the button with a command identifier. |
| [GetMaxSize](#getmaxsize) | Returns the size of all visible buttons together. |
| [GetPadding, GetHorizontalPadding, GetVerticalPadding](#getpadding-gethorizontalpadding-getverticalpadding) | Return the padding inside buttons. |
| [SetPadding](#setpadding) | Sets the padding inside buttons. |
| [GetMetrics](#getmetrics) | Reads padding and spacing into a `TBMETRICS`. |
| [SetMetrics](#setmetrics) | Sets padding and spacing from a `TBMETRICS`. |
| [SetIndent](#setindent) | Sets the space before the first button. |
| [SetListGap](#setlistgap) | Sets the gap between buttons in list style. |
| [GetRows](#getrows) | Returns the number of rows of a wrapping toolbar. |
| [SetRows](#setrows) | Sets the number of rows of a wrapping toolbar. |
| [HitTest](#hittest) | Finds the button at a point. |
| [GetHotItem](#gethotitem) | Returns the index of the hot button. |
| [SetHotItem](#sethotitem) | Makes a button hot. |
| [GetAnchorHighlight](#getanchorhighlight) | Says whether hot-item highlighting is anchored. |
| [SetAnchorHighlight](#setanchorhighlight) | Anchors or releases hot-item highlighting. |
| [GetInsertMark](#getinsertmark) | Reads the insertion mark. |
| [SetInsertMark](#setinsertmark) | Places or removes the insertion mark. |
| [GetInsertMarkColor](#getinsertmarkcolor) | Returns the colour of the insertion mark. |
| [SetInsertMarkColor](#setinsertmarkcolor) | Sets the colour of the insertion mark. |
| [InsertMarkHitTest](#insertmarkhittest) | Works out where an insertion mark for a point goes. |
| [GetStyle](#getstyle) | Returns the toolbar styles. |
| [SetStyle](#setstyle) | Sets the toolbar styles. |
| [GetExtendedStyle](#getextendedstyle) | Returns the extended toolbar styles. |
| [SetExtendedStyle](#setextendedstyle) | Sets the extended toolbar styles. |
| [MakeOpaque](#makeopaque) | Removes `TBSTYLE_TRANSPARENT`. |
| [GetColorScheme](#getcolorscheme) | Reads the highlight and shadow colours. |
| [SetColorScheme](#setcolorscheme) | Sets the highlight and shadow colours. |
| [SetWindowTheme](#setwindowtheme) | Asks for a visual style by name. |
| [SetDarkMode, RemoveDarkMode](#setdarkmode-removedarkmode) | Gives the toolbar the dark theme, or its normal one. |
| [GetTooltips](#gettooltips) | Returns the toolbar's tooltip control. |
| [SetToolTips](#settooltips) | Gives the toolbar a tooltip control. |
| [SetParent](#setparent) | Sets the window that receives the toolbar's notifications. |
| [Customize](#customize) | Opens the Customize Toolbar dialog. |
| [SaveRestore](#saverestore) | Saves the buttons to the registry or restores them. |
| [GetObject](#getobject) | Meant to return the toolbar's `IDropTarget`. |

## Reference

### AddButton

```freebasic
function AddButton( byval hToolbar as HWND, byval idxBitmap as long, byval idCommand as long, byval fsState as ubyte = 0, byval fsStyle as ubyte = 0, byval dwData as DWORD_PTR = 0, byval pwszText as wstring ptr = NULL ) as boolean
```

Adds one button at the right-hand end, building the `TBBUTTON` for you. The text, if any, is
copied by the toolbar, so the string you pass need not outlive the call.

| Parameter | Meaning |
| --- | --- |
| `idxBitmap` | The image number in the image lists, or `I_IMAGENONE` for none. |
| `idCommand` | The command identifier sent with `WM_COMMAND` when the button is clicked. |
| `fsState` | `TBSTATE_*` flags. 0, the default, is taken as `TBSTATE_ENABLED`; to add a disabled button, call [DisableButton](#enablebutton-disablebutton) afterwards. |
| `fsStyle` | `BTNS_*` styles: `BTNS_BUTTON` (0), `BTNS_CHECK`, `BTNS_CHECKGROUP`, `BTNS_DROPDOWN`, `BTNS_AUTOSIZE`, `BTNS_SHOWTEXT` … |
| `dwData` | A value of your own, read back with [GetButton](#getbutton). |
| `pwszText` | The button's text; `NULL` or an empty string for none. |

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.AddButton( hCtrl, STD_PRINT, 1005, 0, BTNS_AUTOSIZE, 0, "Print" )
```

Microsoft Learn: [TB_ADDBUTTONS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-addbuttons)

### AddButtons

```freebasic
function AddButtons overload( byval hToolbar as HWND, byval nButtons as DWORD, byval pButtons as TBBUTTON ptr ) as boolean
function AddButtons overload( byval hToolbar as HWND, byval nButtons as DWORD, byref Buttons as TBBUTTON ) as boolean
```

Adds `nButtons` buttons at the right-hand end from an array of `TBBUTTON`; pass a pointer to
its first element, or the first element itself. Fill `iBitmap`, `idCommand`, `fsState` (at
least `TBSTATE_ENABLED`), `fsStyle` and `iString` (a pool index from [AddString](#addstring), a
`wstring` pointer, or -1 for none).

**Returns** `true` on success.

**Example**

```freebasic
dim tbb(1) as TBBUTTON
tbb(0).iBitmap = STD_CUT : tbb(0).idCommand = 1011 : tbb(0).fsState = TBSTATE_ENABLED : tbb(0).iString = -1
tbb(1).iBitmap = STD_COPY : tbb(1).idCommand = 1012 : tbb(1).fsState = TBSTATE_ENABLED : tbb(1).iString = -1
ToolBar.AddButtons( hCtrl, 2, tbb(0) )
```

Microsoft Learn: [TB_ADDBUTTONS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-addbuttons)

### AddSeparator

```freebasic
function AddSeparator( byval hToolbar as HWND, byval nWidth as long = 0 ) as boolean
```

Adds a separator at the right-hand end: a gap, drawn as a line in a flat toolbar. A separator
counts as a button for indexes and [ButtonCount](#buttoncount). `nWidth` is its width in pixels;
0 gives the default width.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.AddSeparator( hCtrl )
```

### InsertButton

```freebasic
function InsertButton overload( byval hToolbar as HWND, byval idxButton as long, byval pButton as TBBUTTON ptr ) as boolean
function InsertButton overload( byval hToolbar as HWND, byval idxButton as long, byref Button as TBBUTTON ) as boolean
function InsertButton overload( byval hToolbar as HWND, byval idxButton as long, byval idxBitmap as long, byval idCommand as long, byval fsState as ubyte = 0, byval fsStyle as ubyte = 0, byval dwData as DWORD_PTR = 0, byval pwszText as wstring ptr = NULL ) as boolean
```

Inserts a button to the left of the button at index `idxButton`; an index equal to the button
count, or -1, adds it at the end. The first two forms take a filled-in `TBBUTTON`; the third builds one
from its parts exactly as [AddButton](#addbutton) does (`fsState` 0 means enabled).

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.InsertButton( hCtrl, 0, STD_FIND, 1020, 0, BTNS_AUTOSIZE, 0, "Find" )   ' first
```

Microsoft Learn: [TB_INSERTBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-insertbutton)

### InsertSeparator

```freebasic
function InsertSeparator( byval hToolbar as HWND, byval idxButton as long, byval nWidth as long = 0 ) as boolean
```

Inserts a separator to the left of the button at index `idxButton`. `nWidth` 0 gives the default
width.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.InsertSeparator( hCtrl, 1 )
```

### DeleteButton

```freebasic
function DeleteButton( byval hToolbar as HWND, byval nButton as long ) as boolean
```

Deletes the button or separator at index `nButton`. The buttons to its right move down one index.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.DeleteButton( hCtrl, ToolBar.CommandToIndex( hCtrl, 1005 ) )
```

Microsoft Learn: [TB_DELETEBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-deletebutton)

### MoveButton

```freebasic
function MoveButton( byval hToolbar as HWND, byval uOldPos as DWORD, byval uNewPos as DWORD ) as boolean
```

Moves the button at index `uOldPos` to index `uNewPos`.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.MoveButton( hCtrl, 0, ToolBar.ButtonCount( hCtrl ) - 1 )   ' first to last
```

Microsoft Learn: [TB_MOVEBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-movebutton)

### ButtonCount

```freebasic
function ButtonCount( byval hToolbar as HWND ) as DWORD
```

**Returns** the number of buttons, separators included.

**Example**

```freebasic
print ToolBar.ButtonCount( hCtrl ); " buttons"
```

Microsoft Learn: [TB_BUTTONCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-buttoncount)

### ButtonStructSize

```freebasic
sub ButtonStructSize( byval hToolbar as HWND, byval cb as long )
```

Tells the toolbar the size of the `TBBUTTON` structures it will be given. A toolbar created with
`CreateWindowExW` needs it once, before the first button is added; `CWindow.AddControl` sends
it already.

**Example**

```freebasic
ToolBar.ButtonStructSize( hCtrl, sizeof( TBBUTTON ) )
```

Microsoft Learn: [TB_BUTTONSTRUCTSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-buttonstructsize)

### AutoSize

```freebasic
sub AutoSize( byval hToolbar as HWND )
```

Resizes the toolbar to the height of its buttons and, unless it has `CCS_NORESIZE`, to the
width of its parent. Call it after adding buttons or changing their size, and from the parent's
`WM_SIZE`.

**Example**

```freebasic
ToolBar.AutoSize( hCtrl )
```

Microsoft Learn: [TB_AUTOSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-autosize)

### CommandToIndex

```freebasic
function CommandToIndex( byval hToolbar as HWND, byval idButton as long ) as long
```

**Returns** the index of the button whose command identifier is `idButton`, or -1 if there is
none.

**Example**

```freebasic
dim i as long = ToolBar.CommandToIndex( hCtrl, 1002 )
if i >= 0 then print "button 1002 is at index"; i
```

Microsoft Learn: [TB_COMMANDTOINDEX](https://learn.microsoft.com/en-us/windows/win32/controls/tb-commandtoindex)

### SetCmdId

```freebasic
function SetCmdId( byval hToolbar as HWND, byval index as short, byval cmdid as short ) as boolean
```

Gives the button at index `index` the command identifier `cmdid`. Both are `short`, so
identifiers above 32767 do not fit.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.SetCmdId( hCtrl, 0, 1030 )
```

Microsoft Learn: [TB_SETCMDID](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setcmdid)

### GetButton

```freebasic
function GetButton overload( byval hToolbar as HWND, byval nButton as long, byval ptbb as TBBUTTON ptr ) as boolean
function GetButton overload( byval hToolbar as HWND, byval nButton as long, byref tbb as TBBUTTON ) as boolean
function GetButton overload( byval hToolbar as HWND, byval nButton as long ) as TBBUTTON
```

Reads the `TBBUTTON` of the button at index `nButton`: image number, command identifier, state,
style, your `dwData` and string. The third form returns the structure, all zero when the index
is out of range.

**Returns** `true` on success (first two forms).

**Example**

```freebasic
dim tbb as TBBUTTON = ToolBar.GetButton( hCtrl, 0 )
print "command"; tbb.idCommand; ", image"; tbb.iBitmap
```

Microsoft Learn: [TB_GETBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getbutton)

### GetButtonInfo

```freebasic
function GetButtonInfo overload( byval hToolbar as HWND, byval iID as long, byval ptbbi as TBBUTTONINFOW ptr ) as long
function GetButtonInfo overload( byval hToolbar as HWND, byval iID as long, byref tbbi as TBBUTTONINFOW ) as long
function GetButtonInfo overload( byval hToolbar as HWND, byval iID as long ) as TBBUTTONINFOW
```

Reads the attributes that `dwMask` asks for (`TBIF_COMMAND`, `TBIF_IMAGE`, `TBIF_STATE`,
`TBIF_STYLE`, `TBIF_TEXT`, `TBIF_SIZE`, `TBIF_LPARAM` …) of the button with command identifier
`iID`, or of the button at index `iID` when the mask includes `TBIF_BYINDEX`. Set `cbSize` to
`sizeof( TBBUTTONINFOW )` first. The third form sends a structure whose `cbSize` and `dwMask`
are 0, so the control fills in nothing and it comes back all zero; use one of the first two.

**Returns** the index of the button, or -1 on failure.

**Example**

```freebasic
dim tbbi as TBBUTTONINFOW
tbbi.cbSize = sizeof( tbbi ) : tbbi.dwMask = TBIF_IMAGE or TBIF_STYLE
if ToolBar.GetButtonInfo( hCtrl, 1001, tbbi ) >= 0 then print "image"; tbbi.iImage
```

Microsoft Learn: [TB_GETBUTTONINFO](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getbuttoninfo)

### SetButtonInfo

```freebasic
function SetButtonInfo overload( byval hToolbar as HWND, byval iID as long, byval ptbbi as TBBUTTONINFOW ptr ) as long
function SetButtonInfo overload( byval hToolbar as HWND, byval iID as long, byref tbbi as TBBUTTONINFOW ) as long
```

Changes the attributes that `dwMask` names of the button with command identifier `iID` (or
index, with `TBIF_BYINDEX`); the others stay as they are. Set `cbSize` first. This is the way to
change a button's text or width after it has been added.

**Returns** nonzero on success, 0 on failure.

**Example**

```freebasic
dim tbbi as TBBUTTONINFOW
tbbi.cbSize = sizeof( tbbi ) : tbbi.dwMask = TBIF_TEXT : tbbi.pszText = @wstr( "Paste" )
ToolBar.SetButtonInfo( hCtrl, 1001, tbbi )
```

Microsoft Learn: [TB_SETBUTTONINFO](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setbuttoninfo)

### CheckButton, UncheckButton

```freebasic
function CheckButton overload( byval hToolbar as HWND, byval idButton as long, byval fCheck as short ) as boolean
function CheckButton overload( byval hToolbar as HWND, byval idButton as long ) as boolean
function UncheckButton( byval hToolbar as HWND, byval idButton as long ) as boolean
```

Checks (draws pushed in) or unchecks the button with command identifier `idButton`. The form
with `fCheck` checks for nonzero and unchecks for 0; the form without it checks. A check button
(`BTNS_CHECK`) also changes state when the user clicks it.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.CheckButton( hCtrl, 1004 )
ToolBar.UncheckButton( hCtrl, 1004 )
```

Microsoft Learn: [TB_CHECKBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-checkbutton)

### EnableButton, DisableButton

```freebasic
function EnableButton( byval hToolbar as HWND, byval idButton as long ) as boolean
function DisableButton( byval hToolbar as HWND, byval idButton as long ) as boolean
```

Enables or disables the button with command identifier `idButton`. A disabled button is drawn
greyed (from the disabled image list, if there is one) and cannot be clicked.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.DisableButton( hCtrl, 1003 )
ToolBar.EnableButton( hCtrl, 1003 )
```

Microsoft Learn: [TB_ENABLEBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-enablebutton)

### HideButton, UnhideButton

```freebasic
function HideButton overload( byval hToolbar as HWND, byval idButton as long, byval fShow as short ) as boolean
function HideButton overload( byval hToolbar as HWND, byval idButton as long ) as boolean
function UnhideButton( byval hToolbar as HWND, byval idButton as long ) as boolean
```

Hides or shows the button with command identifier `idButton`; the buttons to its right close
the gap. Despite its name, `fShow` **hides** the button when nonzero and shows it when 0, as
the message does; the form without it hides.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.HideButton( hCtrl, 1003 )
ToolBar.UnhideButton( hCtrl, 1003 )
```

Microsoft Learn: [TB_HIDEBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-hidebutton)

### PressButton, ReleaseButton

```freebasic
function PressButton overload( byval hToolbar as HWND, byval idButton as long, byval fPress as short ) as boolean
function PressButton overload( byval hToolbar as HWND, byval idButton as long ) as boolean
function ReleaseButton( byval hToolbar as HWND, byval idButton as long ) as boolean
```

Draws the button with command identifier `idButton` pressed or released, without sending a
command. The form with `fPress` presses for nonzero and releases for 0.

**Returns** `true` on success, `false` when there is no such button.

**Example**

```freebasic
ToolBar.PressButton( hCtrl, 1001 )
ToolBar.ReleaseButton( hCtrl, 1001 )
```

Microsoft Learn: [TB_PRESSBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-pressbutton)

### MarkButton, HighlightButton, UnhighlightButton

```freebasic
function MarkButton( byval hToolbar as HWND, byval idButton as long, byval fHighlight as short ) as boolean
function HighlightButton( byval hToolbar as HWND, byval idButton as long ) as boolean
function UnhighlightButton( byval hToolbar as HWND, byval idButton as long ) as boolean
```

Sets (`fHighlight` nonzero) or clears the highlight of the button with command identifier
`idButton`: the `TBSTATE_MARKED` state, drawn in the highlight colour.
`HighlightButton` and `UnhighlightButton` are `MarkButton` with `fHighlight` set and clear.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.MarkButton( hCtrl, 1002, CTRUE )
ToolBar.UnhighlightButton( hCtrl, 1002 )
ToolBar.HighlightButton( hCtrl, 1003 )
```

Microsoft Learn: [TB_MARKBUTTON](https://learn.microsoft.com/en-us/windows/win32/controls/tb-markbutton)

### Indeterminate

```freebasic
function Indeterminate( byval hToolbar as HWND, byval idButton as long, byval fIndeterminate as short ) as boolean
```

Sets (`fIndeterminate` nonzero) or clears the indeterminate state of the button with command
identifier `idButton`. An indeterminate button is drawn greyed but can still be clicked.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.Indeterminate( hCtrl, 1004, CTRUE )
```

Microsoft Learn: [TB_INDETERMINATE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-indeterminate)

### IsButtonChecked, IsButtonEnabled, IsButtonHidden, IsButtonHighlighted, IsButtonIndeterminate, IsButtonPressed

```freebasic
function IsButtonChecked( byval hToolbar as HWND, byval idButton as long ) as long
function IsButtonEnabled( byval hToolbar as HWND, byval idButton as long ) as long
function IsButtonHidden( byval hToolbar as HWND, byval idButton as long ) as long
function IsButtonHighlighted( byval hToolbar as HWND, byval idButton as long ) as long
function IsButtonIndeterminate( byval hToolbar as HWND, byval idButton as long ) as long
function IsButtonPressed( byval hToolbar as HWND, byval idButton as long ) as long
```

Each tests one state of the button with command identifier `idButton`.

**Returns** 0 when the state is off. When it is on, the value is the state's own `TBSTATE_*`
flag, not 1: `IsButtonEnabled` returns 4 (`TBSTATE_ENABLED`), `IsButtonHidden` 8,
`IsButtonPressed` 2, `IsButtonIndeterminate` 16, `IsButtonHighlighted` 128 and
`IsButtonChecked` 1. Test them as true or false, not against 1.

**Example**

```freebasic
if ToolBar.IsButtonEnabled( hCtrl, 1003 ) andalso ToolBar.IsButtonHidden( hCtrl, 1003 ) = 0 then print "1003 can be clicked"
print ToolBar.IsButtonChecked( hCtrl, 1004 ) <> 0; ToolBar.IsButtonPressed( hCtrl, 1004 ) <> 0
print ToolBar.IsButtonHighlighted( hCtrl, 1004 ) <> 0; ToolBar.IsButtonIndeterminate( hCtrl, 1004 ) <> 0
```

Microsoft Learn: [TB_ISBUTTONENABLED](https://learn.microsoft.com/en-us/windows/win32/controls/tb-isbuttonenabled)

### GetState

```freebasic
function GetState( byval hToolbar as HWND, byval idButton as long ) as DWORD
```

**Returns** the `TBSTATE_*` flags of the button with command identifier `idButton`
(`TBSTATE_ENABLED`, `TBSTATE_CHECKED`, `TBSTATE_PRESSED`, `TBSTATE_HIDDEN`,
`TBSTATE_INDETERMINATE`, `TBSTATE_MARKED`, `TBSTATE_WRAP` …): 5 for a checked, enabled button.
For a button that does not exist the message returns -1, which arrives here as &hFFFFFFFF.

**Example**

```freebasic
if ToolBar.GetState( hCtrl, 1004 ) and TBSTATE_CHECKED then print "checked"
```

Microsoft Learn: [TB_GETSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getstate)

### SetState

```freebasic
function SetState( byval hToolbar as HWND, byval idButton as long, byval fState as short ) as boolean
```

Replaces all the state flags of the button with command identifier `idButton` with `fState`.
Leave out `TBSTATE_ENABLED` and the button is disabled.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.SetState( hCtrl, 1004, TBSTATE_ENABLED or TBSTATE_CHECKED )
```

Microsoft Learn: [TB_SETSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setstate)

### GetButtonText

```freebasic
function GetButtonText overload( byval hToolbar as HWND, byval idButton as long, byval pBuffer as wstring ptr ) as long
function GetButtonText overload( byval hToolbar as HWND, byval idButton as long ) as ustring
```

Reads the text the button with command identifier `idButton` shows. The first form copies it
into `pBuffer`, which must be big enough: the control does not know its size, so ask
[GetButtonTextLength](#getbuttontextlength) first and allow one more character for the
terminating null.

The second form returns a `ustring`, or "" for a button without text.

**Returns** the length of the text in characters, or -1 when the button has no text (first form);
the text, or an empty string on failure (second form).

**Example**

```freebasic
dim s as ustring = ToolBar.GetButtonText( hToolbar, 1001 )
print s
```

Microsoft Learn: [TB_GETBUTTONTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getbuttontext)

### GetButtonTextLength

```freebasic
function GetButtonTextLength( byval hToolbar as HWND, byval idButton as long ) as long
```

**Returns** the length in characters of the text of the button with command identifier
`idButton`, without the terminating null, or -1 when it has no text.

**Example**

```freebasic
dim n as long = ToolBar.GetButtonTextLength( hCtrl, 1001 )
dim buf as wstring * 260
if n > 0 andalso n < 260 then ToolBar.GetButtonText( hCtrl, 1001, @buf )
```

Microsoft Learn: [TB_GETBUTTONTEXT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getbuttontext)

### AddString

```freebasic
function AddString( byval hToolbar as HWND, byval hInst as HINSTANCE, byval idString as INT_PTR ) as long
```

Adds strings to the toolbar's string pool, from which `TBBUTTON.iString` can take a button's
text by number. With `hInst` `NULL`, `idString` is the address of the strings themselves: one or
more wide strings one after the other, the last followed by a second null. Otherwise `idString`
is the identifier of a string resource in the module `hInst`.

**Returns** the pool index of the first new string, or -1 on failure.

**Example**

```freebasic
dim pool as wstring * 32 = "Alpha"   ' the rest of the buffer is nulls
dim i as long = ToolBar.AddString( hCtrl, NULL, cast( INT_PTR, @pool ) )
```

Microsoft Learn: [TB_ADDSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/tb-addstring)

### GetString

```freebasic
function GetString( byval hToolbar as HWND, byval iString as short, byval pBuffer as wstring ptr, byval cchMax as short ) as long
```

Copies string number `iString` of the string pool into `pBuffer`, which holds `cchMax`
characters.

**Returns** the length of the string, or -1 on failure.

**Example**

```freebasic
dim buf as wstring * 64
if ToolBar.GetString( hCtrl, 0, @buf, 64 ) >= 0 then MessageBoxW( hwnd, buf, "String 0", MB_OK )
```

Microsoft Learn: [TB_GETSTRING](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getstring)

### MapAccelerator

```freebasic
function MapAccelerator overload( byval hToolbar as HWND, byval chAccel as DWORD, byval pIDBtn as DWORD ptr ) as boolean
function MapAccelerator overload( byval hToolbar as HWND, byval chAccel as DWORD, byref IDBtn as DWORD ) as boolean
function MapAccelerator overload( byval hToolbar as HWND, byval chAccel as DWORD ) as DWORD
```

Finds the button whose text has `chAccel` as its accelerator: the letter after `&`, or the
first letter when the text has no `&`. Upper and lower case match alike. The character is sent
with the ANSI form of the message, so letters outside ASCII may not be found.

**Returns** `true` when a button matches, with its command identifier stored in `pIDBtn` /
`IDBtn` (first two forms); the command identifier, or 0 when no button matches (third form).

**Example**

```freebasic
dim id as DWORD = ToolBar.MapAccelerator( hCtrl, asc( "o" ) )
if id then SendMessageW( hwnd, WM_COMMAND, id, 0 )
```

Microsoft Learn: [TB_MAPACCELERATOR](https://learn.microsoft.com/en-us/windows/win32/controls/tb-mapaccelerator)

### SetMaxTextRows

```freebasic
function SetMaxTextRows( byval hToolbar as HWND, byval iMaxRows as long ) as boolean
```

Sets how many lines of text a button may show; longer text is cut. 0 shows no text at all,
leaving the text for tooltips.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.SetMaxTextRows( hCtrl, 2 )
```

Microsoft Learn: [TB_SETMAXTEXTROWS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setmaxtextrows)

### GetTextRows

```freebasic
function GetTextRows( byval hToolbar as HWND ) as DWORD
```

**Returns** the largest number of text lines a button may show, as set by
[SetMaxTextRows](#setmaxtextrows): 1 for a new toolbar, 2 after `SetMaxTextRows( h, 2 )`. (For
the number of rows of buttons, use [GetRows](#getrows).)

**Example**

```freebasic
print "text lines per button:"; ToolBar.GetTextRows( hCtrl )
```

Microsoft Learn: [TB_GETTEXTROWS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-gettextrows)

### SetDrawTextFlags

```freebasic
function SetDrawTextFlags( byval hToolbar as HWND, byval dwMask as DWORD, byval dwDTFlags as DWORD ) as DWORD
```

Sets the `DT_*` flags the toolbar passes to `DrawTextW` for button text. Only the flags named in
`dwMask` change, to their value in `dwDTFlags`.

**Returns** the previous flags.

**Example**

```freebasic
ToolBar.SetDrawTextFlags( hCtrl, DT_LEFT or DT_CENTER, DT_LEFT )   ' left-aligned text
```

Microsoft Learn: [TB_SETDRAWTEXTFLAGS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setdrawtextflags)

### LoadImages

```freebasic
function LoadImages overload( byval hToolbar as HWND, byval iBitmapID as DWORD, byval hinst as HINSTANCE ) as long
function LoadImages overload( byval hToolbar as HWND, byval iBitmapID as DWORD ) as long
```

Adds one of the sets of standard images that come with Windows to the toolbar's normal image
list, creating the list when there is none. The second form loads from the common controls
(`HINST_COMMCTRL`), which is what you want. Sets: `IDB_STD_SMALL_COLOR` / `IDB_STD_LARGE_COLOR`
(file and edit commands: `STD_FILENEW`, `STD_FILEOPEN`, `STD_FILESAVE`, `STD_CUT`, `STD_COPY`,
`STD_PASTE`, `STD_UNDO`, `STD_PRINT`, `STD_FIND` …), `IDB_VIEW_SMALL_COLOR` /
`IDB_VIEW_LARGE_COLOR` (`VIEW_*`) and `IDB_HIST_SMALL_COLOR` / `IDB_HIST_LARGE_COLOR`
(`HIST_*`). The list created belongs to the toolbar.

**Returns** the number of images the list held **before** the call, which is the image number
of the first image just loaded: 0 for the first set, 15 when a second set follows
`IDB_STD_SMALL_COLOR`.

**Example**

```freebasic
ToolBar.LoadImages( hCtrl, IDB_STD_SMALL_COLOR )
ToolBar.AddButton( hCtrl, STD_UNDO, 1040 )
```

Microsoft Learn: [TB_LOADIMAGES](https://learn.microsoft.com/en-us/windows/win32/controls/tb-loadimages)

### AddBitmap

```freebasic
function AddBitmap overload( byval hToolbar as HWND, byval nButtons as DWORD, byval ptabm as TBADDBITMAP ptr ) as long
function AddBitmap overload( byval hToolbar as HWND, byval nButtons as DWORD, byref tabm as TBADDBITMAP ) as long
```

Adds `nButtons` images taken from one bitmap, cut into squares of the toolbar's image size (see
[SetBitmapSize](#setbitmapsize)). The `TBADDBITMAP` names the bitmap: `hInst` and a resource
`nID`, or `hInst` `NULL` and an `HBITMAP` in `nID`. It does not mix with image lists set with
[SetImageList](#getimagelist-setimagelist); use one way or the other.

**Returns** the image number of the first new image, or -1 on failure.

**Example**

```freebasic
dim tabm as TBADDBITMAP
tabm.hInst = HINST_COMMCTRL : tabm.nID = IDB_VIEW_SMALL_COLOR
dim first as long = ToolBar.AddBitmap( hCtrl, 12, tabm )
```

Microsoft Learn: [TB_ADDBITMAP](https://learn.microsoft.com/en-us/windows/win32/controls/tb-addbitmap)

### ReplaceBitmap

```freebasic
function ReplaceBitmap overload( byval hToolbar as HWND, byval ptbrb as TBREPLACEBITMAP ptr ) as boolean
function ReplaceBitmap overload( byval hToolbar as HWND, byref tbrb as TBREPLACEBITMAP ) as boolean
```

Replaces the images that were added from one bitmap with [AddBitmap](#addbitmap) by images
from another. The `TBREPLACEBITMAP` names the old bitmap (`hInstOld`, `nIDOld`), the new one
(`hInstNew`, `nIDNew`) and the number of images in the new one (`nButtons`).

**Returns** `true` on success.

**Example**

```freebasic
dim tbrb as TBREPLACEBITMAP
tbrb.hInstOld = HINST_COMMCTRL : tbrb.nIDOld = IDB_STD_SMALL_COLOR
tbrb.hInstNew = HINST_COMMCTRL : tbrb.nIDNew = IDB_STD_LARGE_COLOR : tbrb.nButtons = 15
ToolBar.ReplaceBitmap( hCtrl, tbrb )
```

Microsoft Learn: [TB_REPLACEBITMAP](https://learn.microsoft.com/en-us/windows/win32/controls/tb-replacebitmap)

### SetBitmapSize

```freebasic
function SetBitmapSize( byval hToolbar as HWND, byval dxBitmap as short, byval dyBitmap as short ) as boolean
```

Sets the width and height, in pixels, of the images the toolbar will be given, before any are
added. The default is 16 × 15.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.SetBitmapSize( hCtrl, 24, 24 )
```

Microsoft Learn: [TB_SETBITMAPSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setbitmapsize)

### GetBitmapFlags

```freebasic
function GetBitmapFlags( byval hToolbar as HWND ) as DWORD
```

**Returns** `TBBF_LARGE` when the display calls for large (24 × 24) images, 0 for small
(16 × 16) ones. The other bits are reserved.

**Example**

```freebasic
dim set as DWORD = iif( ToolBar.GetBitmapFlags( hCtrl ) and TBBF_LARGE, IDB_STD_LARGE_COLOR, IDB_STD_SMALL_COLOR )
ToolBar.LoadImages( hCtrl, set )
```

Microsoft Learn: [TB_GETBITMAPFLAGS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getbitmapflags)

### GetBitmap

```freebasic
function GetBitmap( byval hToolbar as HWND, byval idButton as long ) as long
```

**Returns** the image number of the button with command identifier `idButton`, or 0 on failure.

**Example**

```freebasic
print "image"; ToolBar.GetBitmap( hCtrl, 1002 )
```

Microsoft Learn: [TB_GETBITMAP](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getbitmap)

### ChangeBitmap

```freebasic
function ChangeBitmap( byval hToolbar as HWND, byval idButton as long, byval iBitmap as WORD ) as boolean
```

Shows image `iBitmap` on the button with command identifier `idButton`.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.ChangeBitmap( hCtrl, 1004, STD_DELETE )
```

Microsoft Learn: [TB_CHANGEBITMAP](https://learn.microsoft.com/en-us/windows/win32/controls/tb-changebitmap)

### GetImageList, SetImageList

```freebasic
function GetImageList( byval hToolbar as HWND ) as HIMAGELIST
function SetImageList( byval hToolbar as HWND, byval himlNew as HIMAGELIST ) as HIMAGELIST
```

Read or replace the image list for buttons in their normal state; it also stands in for the hot,
disabled and pressed lists when those are not set. The toolbar does not destroy a list you set:
destroy the old one that `SetImageList` returns, and your own list when the window closes.

**Returns** the image list, or `NULL` when there is none (`GetImageList`); the previous image
list, or `NULL` (`SetImageList`).

**Example**

```freebasic
dim himl as HIMAGELIST = ImageList_Create( 24, 24, ILC_COLOR32 or ILC_MASK, 4, 0 )
dim hOld as HIMAGELIST = ToolBar.SetImageList( hCtrl, himl )
if hOld then ImageList_Destroy( hOld )
print ToolBar.GetImageList( hCtrl ) = himl
```

Microsoft Learn: [TB_SETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setimagelist)

### GetHotImageList, SetHotImageList

```freebasic
function GetHotImageList( byval hToolbar as HWND ) as HIMAGELIST
function SetHotImageList( byval hToolbar as HWND, byval himlNewHot as HIMAGELIST ) as HIMAGELIST
```

Read or replace the image list for the hot button, the one under the mouse in a flat toolbar.
The same list may be given as the normal and the hot list.

**Returns** the image list, or `NULL` (`GetHotImageList`); the previous one, or `NULL`
(`SetHotImageList`).

**Example**

```freebasic
ToolBar.SetHotImageList( hCtrl, ToolBar.GetImageList( hCtrl ) )
print ToolBar.GetHotImageList( hCtrl ) <> NULL
```

Microsoft Learn: [TB_SETHOTIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/tb-sethotimagelist)

### GetDisabledImageList, SetDisabledImageList

```freebasic
function GetDisabledImageList( byval hToolbar as HWND ) as HIMAGELIST
function SetDisabledImageList( byval hToolbar as HWND, byval himlNewDisabled as HIMAGELIST ) as HIMAGELIST
```

Read or replace the image list for disabled buttons. Without one, the toolbar greys the normal
image itself.

**Returns** the image list, or `NULL` (`GetDisabledImageList`); the previous one, or `NULL`
(`SetDisabledImageList`).

**Example**

```freebasic
dim himlGrey as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32 or ILC_MASK, 4, 0 )
ToolBar.SetDisabledImageList( hCtrl, himlGrey )
print ToolBar.GetDisabledImageList( hCtrl ) = himlGrey
```

Microsoft Learn: [TB_SETDISABLEDIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setdisabledimagelist)

### SetPressedImageList

```freebasic
function SetPressedImageList( byval hToolbar as HWND, byval iImageID as DWORD, byval himlNew as HIMAGELIST ) as HIMAGELIST
```

Sets the image list for buttons while they are pressed. `iImageID` is the number of the image
list (0 unless you use several).

**Returns** the previous image list, or `NULL`.

**Example**

```freebasic
dim himlDown as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32 or ILC_MASK, 4, 0 )
ToolBar.SetPressedImageList( hCtrl, 0, himlDown )
```

Microsoft Learn: [TB_SETPRESSEDIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setpressedimagelist)

### GetImageListCount

```freebasic
function GetImageListCount( byval hToolbar as HWND ) as long
```

**Returns** the number of normal image lists the toolbar has.

**Example**

```freebasic
print ToolBar.GetImageListCount( hCtrl ); " image lists"
```

Microsoft Learn: [TB_GETIMAGELISTCOUNT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getimagelistcount)

### GetButtonSize, GetButtonWidth, GetButtonHeight

```freebasic
function GetButtonSize( byval hToolbar as HWND ) as DWORD
function GetButtonWidth( byval hToolbar as HWND ) as DWORD
function GetButtonHeight( byval hToolbar as HWND ) as DWORD
```

Return the size of the toolbar's buttons in pixels. `GetButtonSize` packs both, the width in the
low word and the height in the high word; the other two return one each. The height is what a
rebar band holding the toolbar needs (see [Rebar](SysWin-Gui-Rebar)).

**Returns** the size.

**Example**

```freebasic
dim sz as DWORD = ToolBar.GetButtonSize( hCtrl )
print LOWORD( sz ); " x"; HIWORD( sz )
print ToolBar.GetButtonWidth( hCtrl ); " x"; ToolBar.GetButtonHeight( hCtrl )
```

Microsoft Learn: [TB_GETBUTTONSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getbuttonsize)

### SetButtonSize

```freebasic
function SetButtonSize( byval hToolbar as HWND, byval dxButton as short, byval dyButton as short ) as boolean
```

Sets the size of the buttons, in pixels. The toolbar does not make a button smaller than its
image and text need. Call [AutoSize](#autosize) afterwards.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.SetButtonSize( hCtrl, 40, 36 )
ToolBar.AutoSize( hCtrl )
```

Microsoft Learn: [TB_SETBUTTONSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setbuttonsize)

### SetButtonWidth

```freebasic
function SetButtonWidth( byval hToolbar as HWND, byval cxMin as short, byval cxMax as short ) as boolean
```

Sets the smallest and largest width, in pixels, of buttons sized to their text.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.SetButtonWidth( hCtrl, 60, 120 )
```

Microsoft Learn: [TB_SETBUTTONWIDTH](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setbuttonwidth)

### GetItemRect

```freebasic
function GetItemRect overload( byval hToolbar as HWND, byval nButton as long, byval prc as RECT ptr ) as boolean
function GetItemRect overload( byval hToolbar as HWND, byval nButton as long, byref rc as RECT ) as boolean
function GetItemRect overload( byval hToolbar as HWND, byval nButton as long ) as ( long, long, long, long )
```

Reads the rectangle of the button or separator at index `nButton`, in client coordinates of the
toolbar. A hidden button has no rectangle. The third form returns `( left, top, right, bottom )`
and leaves the message's result in `GetLastError()`: nonzero on success, 0 on failure.

**Returns** `true` on success (first two forms); the four edges (third form).

**Example**

```freebasic
var (l, t, r, b) = ToolBar.GetItemRect( hCtrl, 0 )
if GetLastError() then print "first button:"; r - l; " x"; b - t
```

Microsoft Learn: [TB_GETITEMRECT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getitemrect)

### GetRect

```freebasic
function GetRect overload( byval hToolbar as HWND, byval iID as long, byval prc as RECT ptr ) as boolean
function GetRect overload( byval hToolbar as HWND, byval iID as long, byref rc as RECT ) as boolean
function GetRect overload( byval hToolbar as HWND, byval iID as long ) as ( long, long, long, long )
```

Reads the rectangle of the button with command identifier `iID`, in client coordinates of the
toolbar. The third form returns `( left, top, right, bottom )` and leaves the result in
`GetLastError()`: nonzero on success. Map it to the screen to drop a menu below a
`BTNS_DROPDOWN` button.

**Returns** `true` on success (first two forms); the four edges (third form).

**Example**

```freebasic
dim rc as RECT
if ToolBar.GetRect( hCtrl, 1002, rc ) then MapWindowPoints( hCtrl, HWND_DESKTOP, cast( POINT ptr, @rc ), 2 )
```

Microsoft Learn: [TB_GETRECT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getrect)

### GetMaxSize

```freebasic
function GetMaxSize overload( byval hToolbar as HWND, byval psize as SIZE ptr ) as boolean
function GetMaxSize overload( byval hToolbar as HWND, byref sz as SIZE ) as boolean
function GetMaxSize overload( byval hToolbar as HWND ) as ( long, long )
```

Reads the width and height that all the visible buttons and separators take up together: the
size a toolbar needs to show them all, for example as the ideal width of a rebar band. The
third form returns `( cx, cy )` and leaves the result in `GetLastError()`: nonzero on success.

**Returns** `true` on success (first two forms); the size (third form).

**Example**

```freebasic
var (cx, cy) = ToolBar.GetMaxSize( hCtrl )
if GetLastError() then print "all buttons:"; cx; " x"; cy
```

Microsoft Learn: [TB_GETMAXSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getmaxsize)

### GetPadding, GetHorizontalPadding, GetVerticalPadding

```freebasic
function GetPadding( byval hToolbar as HWND ) as DWORD
function GetHorizontalPadding( byval hToolbar as HWND ) as DWORD
function GetVerticalPadding( byval hToolbar as HWND ) as DWORD
```

Return the padding, in pixels, between a button's edge and its image and text. `GetPadding`
packs both, horizontal in the low word and vertical in the high word.

**Returns** the padding.

**Example**

```freebasic
print "padding"; ToolBar.GetHorizontalPadding( hCtrl ); ","; ToolBar.GetVerticalPadding( hCtrl )
print hex( ToolBar.GetPadding( hCtrl ) )
```

Microsoft Learn: [TB_GETPADDING](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getpadding)

### SetPadding

```freebasic
function SetPadding( byval hToolbar as HWND, byval cx as short, byval cy as short ) as DWORD
```

Sets the horizontal and vertical padding inside buttons, in pixels.

**Returns** the previous padding, horizontal in the low word and vertical in the high word.

**Example**

```freebasic
ToolBar.SetPadding( hCtrl, 10, 6 )
ToolBar.AutoSize( hCtrl )
```

Microsoft Learn: [TB_SETPADDING](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setpadding)

### GetMetrics

```freebasic
sub GetMetrics overload( byval hToolbar as HWND, byval ptbMetrics as TBMETRICS ptr )
sub GetMetrics overload( byval hToolbar as HWND, byref tbMet as TBMETRICS )
function GetMetrics overload( byval hToolbar as HWND ) as TBMETRICS
```

Reads the padding and spacing values that `dwMask` asks for (`TBMF_PAD`, `TBMF_BARPAD`,
`TBMF_BUTTONSPACING`) into a `TBMETRICS`; `cbSize` is set for you. Needs version 6 of the
common controls. The third form sends a structure whose `dwMask` is 0, so nothing is asked for
and only `cbSize` comes back set; use one of the first two.

**Example**

```freebasic
dim tbm as TBMETRICS
tbm.dwMask = TBMF_PAD or TBMF_BUTTONSPACING
ToolBar.GetMetrics( hCtrl, tbm )
print "spacing"; tbm.cxButtonSpacing
```

Microsoft Learn: [TB_GETMETRICS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getmetrics)

### SetMetrics

```freebasic
sub SetMetrics overload( byval hToolbar as HWND, byval ptbMetrics as TBMETRICS ptr )
sub SetMetrics overload( byval hToolbar as HWND, byref tbMet as TBMETRICS )
```

Sets the padding and spacing values that `dwMask` names. Unlike [GetMetrics](#getmetrics) it
does not fill in `cbSize`: set it to `sizeof( TBMETRICS )` yourself.

**Example**

```freebasic
dim tbm as TBMETRICS
tbm.cbSize = sizeof( tbm ) : tbm.dwMask = TBMF_BUTTONSPACING : tbm.cxButtonSpacing = 6
ToolBar.SetMetrics( hCtrl, tbm )
```

Microsoft Learn: [TB_SETMETRICS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setmetrics)

### SetIndent

```freebasic
function SetIndent( byval hToolbar as HWND, byval iIndent as long ) as boolean
```

Sets the space, in pixels, before the first button.

**Returns** `true` on success.

**Example**

```freebasic
ToolBar.SetIndent( hCtrl, 8 )
```

Microsoft Learn: [TB_SETINDENT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setindent)

### SetListGap

```freebasic
sub SetListGap( byval hToolbar as HWND, byval gap as DWORD )
```

Sets the distance, in pixels, between buttons of a toolbar with `TBSTYLE_LIST` (text to the
right of the image). Needs version 6 of the common controls.

**Example**

```freebasic
ToolBar.SetListGap( hCtrl, 12 )
```

Microsoft Learn: [TB_SETLISTGAP](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setlistgap)

### GetRows

```freebasic
function GetRows( byval hToolbar as HWND ) as DWORD
```

**Returns** the number of rows of buttons in a toolbar with `TBSTYLE_WRAPABLE`; 1 for a toolbar
on one line.

**Example**

```freebasic
print ToolBar.GetRows( hCtrl ); " rows"
```

Microsoft Learn: [TB_GETROWS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getrows)

### SetRows

```freebasic
sub SetRows overload( byval hToolbar as HWND, byval cRows as WORD, byval fLarger as boolean, byval prc as RECT ptr )
sub SetRows overload( byval hToolbar as HWND, byval cRows as WORD, byval fLarger as boolean, byref rc as RECT )
```

Lays the buttons out in `cRows` rows. When that number cannot be made, `fLarger` `true` takes
the next larger number of rows and `false` the next smaller. The toolbar's new rectangle comes
back in `prc` / `rc`.

**Example**

```freebasic
dim rc as RECT
ToolBar.SetRows( hCtrl, 2, true, rc )
```

Microsoft Learn: [TB_SETROWS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setrows)

### HitTest

```freebasic
function HitTest overload( byval hToolbar as HWND, byval pptHitTest as POINT ptr ) as long
function HitTest overload( byval hToolbar as HWND, byref ptHitTest as POINT ) as long
function HitTest overload( byval hToolbar as HWND ) as POINT
```

Finds the button under a point given in client coordinates of the toolbar.

The third form tests the point (0, 0) and returns that point, not the result of the test; it is
of no use, so pass a point to one of the first two.

**Returns** the index of the button (not separator) under the point when it is 0 or more. A
negative value means the point is on no button; its absolute value is then the index of the
separator it is on or of the nearest button.

**Example**

```freebasic
dim pt as POINT
GetCursorPos( @pt ) : ScreenToClient( hCtrl, @pt )
dim i as long = ToolBar.HitTest( hCtrl, pt )
if i >= 0 then print "over button"; i
```

Microsoft Learn: [TB_HITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/tb-hittest)

### GetHotItem

```freebasic
function GetHotItem( byval hToolbar as HWND ) as DWORD
```

**Returns** the index of the hot button: the one under the mouse, or picked with the arrow keys.
When no button is hot the message's -1 arrives as a `DWORD`, &hFFFFFFFF (4294967295): test for
that, or convert with `cast( long, ... )` and test for -1.

**Example**

```freebasic
dim i as long = cast( long, ToolBar.GetHotItem( hCtrl ) )
if i <> -1 then print "hot button:"; i
```

Microsoft Learn: [TB_GETHOTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tb-gethotitem)

### SetHotItem

```freebasic
function SetHotItem( byval hToolbar as HWND, byval iHot as long ) as long
```

Makes the button at index `iHot` hot; -1 makes none hot. Has effect only on a flat toolbar.

**Returns** the index of the previous hot button, or -1 when there was none.

**Example**

```freebasic
ToolBar.SetHotItem( hCtrl, 0 )
```

Microsoft Learn: [TB_SETHOTITEM](https://learn.microsoft.com/en-us/windows/win32/controls/tb-sethotitem)

### GetAnchorHighlight

```freebasic
function GetAnchorHighlight( byval hToolbar as HWND ) as boolean
```

**Returns** `true` when anchor highlighting is on: the hot button then stays hot when the mouse
leaves the toolbar, until another becomes hot. It is off in a new toolbar.

**Example**

```freebasic
print "anchored:"; ToolBar.GetAnchorHighlight( hCtrl )
```

Microsoft Learn: [TB_GETANCHORHIGHLIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getanchorhighlight)

### SetAnchorHighlight

```freebasic
function SetAnchorHighlight( byval hToolbar as HWND, byval fAnchor as boolean ) as boolean
```

Turns anchor highlighting on (`true`) or off.

**Returns** the previous setting.

**Example**

```freebasic
ToolBar.SetAnchorHighlight( hCtrl, true )
```

Microsoft Learn: [TB_SETANCHORHIGHLIGHT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setanchorhighlight)

### GetInsertMark

```freebasic
function GetInsertMark overload( byval hToolbar as HWND, byval ptbim as TBINSERTMARK ptr ) as long
function GetInsertMark overload( byval hToolbar as HWND, byref tbim as TBINSERTMARK ) as long
function GetInsertMark overload( byval hToolbar as HWND ) as TBINSERTMARK
```

Reads the insertion mark, the line a toolbar can show between buttons while one is dragged: the
index of the button it is next to (`iButton`, -1 for none) and `dwFlags` (`TBIMHT_AFTER` when it
is on the button's right).

**Returns** always `true` (first two forms); the mark (third form).

**Example**

```freebasic
dim tbim as TBINSERTMARK = ToolBar.GetInsertMark( hCtrl )
if tbim.iButton >= 0 then print "mark at button"; tbim.iButton
```

Microsoft Learn: [TB_GETINSERTMARK](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getinsertmark)

### SetInsertMark

```freebasic
sub SetInsertMark overload( byval hToolbar as HWND, byval ptbim as TBINSERTMARK ptr )
sub SetInsertMark overload( byval hToolbar as HWND, byref tbim as TBINSERTMARK )
```

Shows the insertion mark next to button `iButton` (to its right with `TBIMHT_AFTER` in
`dwFlags`), or removes it when `iButton` is -1.

**Example**

```freebasic
dim tbim as TBINSERTMARK
tbim.iButton = 1 : tbim.dwFlags = TBIMHT_AFTER
ToolBar.SetInsertMark( hCtrl, tbim )
```

Microsoft Learn: [TB_SETINSERTMARK](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setinsertmark)

### GetInsertMarkColor

```freebasic
function GetInsertMarkColor( byval hToolbar as HWND ) as COLORREF
```

**Returns** the colour the insertion mark is drawn in.

**Example**

```freebasic
print hex( ToolBar.GetInsertMarkColor( hCtrl ) )
```

Microsoft Learn: [TB_GETINSERTMARKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getinsertmarkcolor)

### SetInsertMarkColor

```freebasic
function SetInsertMarkColor( byval hToolbar as HWND, byval clrInsertMark as COLORREF ) as COLORREF
```

**Returns** the previous colour.

**Example**

```freebasic
SendMessageW( hCtrl, TB_SETINSERTMARKCOLOR, 0, RGB_RED )
```

Microsoft Learn: [TB_SETINSERTMARKCOLOR](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setinsertmarkcolor)

### InsertMarkHitTest

```freebasic
function InsertMarkHitTest overload( byval hToolbar as HWND, byval ppt as POINT ptr, byval ptbim as TBINSERTMARK ptr ) as boolean
function InsertMarkHitTest overload( byval hToolbar as HWND, byref pt as POINT, byval tbim as TBINSERTMARK ) as boolean
```

Works out where the insertion mark belongs for a point in client coordinates of the toolbar, as
a `TBINSERTMARK` ready for [SetInsertMark](#setinsertmark). The second form takes the
`TBINSERTMARK` **by value**: the control fills in a copy, and the structure you pass is not
changed. Use the first form, with pointers.

**Returns** `true` when the point is on a button, `false` when it is not (the mark then goes to
the nearest one).

**Example**

```freebasic
dim pt as POINT = ( 30, 10 )
dim tbim as TBINSERTMARK
ToolBar.InsertMarkHitTest( hCtrl, @pt, @tbim )
ToolBar.SetInsertMark( hCtrl, tbim )
```

Microsoft Learn: [TB_INSERTMARKHITTEST](https://learn.microsoft.com/en-us/windows/win32/controls/tb-insertmarkhittest)

### GetStyle

```freebasic
function GetStyle( byval hToolbar as HWND ) as DWORD
```

**Returns** the toolbar's styles: window, common-control (`CCS_*`) and toolbar (`TBSTYLE_FLAT`,
`TBSTYLE_LIST`, `TBSTYLE_TOOLTIPS`, `TBSTYLE_WRAPABLE`, `TBSTYLE_TRANSPARENT` …) together.

**Example**

```freebasic
if ToolBar.GetStyle( hCtrl ) and TBSTYLE_FLAT then print "flat"
```

Microsoft Learn: [TB_GETSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getstyle)

### SetStyle

```freebasic
sub SetStyle( byval hToolbar as HWND, byval dwStyle as DWORD )
```

Replaces the toolbar's styles with `dwStyle`. Start from [GetStyle](#getstyle) to change one.

**Example**

```freebasic
ToolBar.SetStyle( hCtrl, ToolBar.GetStyle( hCtrl ) or TBSTYLE_LIST )
ToolBar.AutoSize( hCtrl )
```

Microsoft Learn: [TB_SETSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setstyle)

### GetExtendedStyle

```freebasic
function GetExtendedStyle( byval hToolbar as HWND ) as DWORD
```

**Returns** the extended toolbar styles (`TBSTYLE_EX_DRAWDDARROWS`, `TBSTYLE_EX_MIXEDBUTTONS`,
`TBSTYLE_EX_HIDECLIPPEDBUTTONS`, `TBSTYLE_EX_DOUBLEBUFFER` …); 0 for a new toolbar. These are
not the `WS_EX_*` window styles.

**Example**

```freebasic
print hex( ToolBar.GetExtendedStyle( hCtrl ) )
```

Microsoft Learn: [TB_GETEXTENDEDSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getextendedstyle)

### SetExtendedStyle

```freebasic
function SetExtendedStyle( byval hToolbar as HWND, byval dwExStyle as DWORD ) as DWORD
```

Replaces the extended toolbar styles with `dwExStyle`. `TBSTYLE_EX_DRAWDDARROWS` gives
`BTNS_DROPDOWN` buttons a separate arrow; `TBSTYLE_EX_MIXEDBUTTONS` shows text only on buttons
with `BTNS_SHOWTEXT` and uses the rest as tooltips.

**Returns** the previous extended styles.

**Example**

```freebasic
ToolBar.SetExtendedStyle( hCtrl, ToolBar.GetExtendedStyle( hCtrl ) or TBSTYLE_EX_DRAWDDARROWS )
```

Microsoft Learn: [TB_SETEXTENDEDSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setextendedstyle)

### MakeOpaque

```freebasic
sub MakeOpaque( byval hToolbar as HWND )
```

Removes `TBSTYLE_TRANSPARENT` from the toolbar's window style, so that it paints its own
background instead of letting the parent's show through. It changes the style bits only; call
`InvalidateRect` to repaint.

**Example**

```freebasic
ToolBar.MakeOpaque( hCtrl )
InvalidateRect( hCtrl, NULL, CTRUE )
```

Microsoft Learn: [Toolbar control and button styles](https://learn.microsoft.com/en-us/windows/win32/controls/toolbar-control-and-button-styles)

### GetColorScheme

```freebasic
function GetColorScheme overload( byval hToolbar as HWND, byval pcs as COLORSCHEME ptr ) as boolean
function GetColorScheme overload( byval hToolbar as HWND, byref cs as COLORSCHEME ) as boolean
function GetColorScheme overload( byval hToolbar as HWND ) as COLORSCHEME
```

Reads the colours the toolbar draws button highlights and shadows with
(`clrBtnHighlight`, `clrBtnShadow`); `dwSize` is set for you. `CLR_DEFAULT` means the system
colour. The first form returns `false` for a `NULL` pointer.

**Returns** `true` on success (first two forms); the colours (third form).

**Example**

```freebasic
dim cs as COLORSCHEME = ToolBar.GetColorScheme( hCtrl )
if cs.clrBtnHighlight = CLR_DEFAULT then print "system highlight colour"
```

Microsoft Learn: [TB_GETCOLORSCHEME](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getcolorscheme)

### SetColorScheme

```freebasic
sub SetColorScheme overload( byval hToolbar as HWND, byval pcs as COLORSCHEME ptr )
sub SetColorScheme overload( byval hToolbar as HWND, byref cs as COLORSCHEME )
```

Sets the highlight and shadow colours. Unlike [GetColorScheme](#getcolorscheme) it does not fill
in `dwSize`: set it to `sizeof( COLORSCHEME )` yourself.

**Example**

```freebasic
dim cs as COLORSCHEME
cs.dwSize = sizeof( cs ) : cs.clrBtnHighlight = RGB_WHITE : cs.clrBtnShadow = RGB_GRAY
ToolBar.SetColorScheme( hCtrl, cs )
```

Microsoft Learn: [TB_SETCOLORSCHEME](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setcolorscheme)

### SetWindowTheme

```freebasic
sub SetWindowTheme( byval hToolbar as HWND, byval pwszTheme as wstring ptr )
```

**Example**

```freebasic
SendMessageW( hCtrl, TB_SETWINDOWTHEME, 0, cast( LPARAM, @wstr( "Explorer" ) ) )
```

Microsoft Learn: [TB_SETWINDOWTHEME](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setwindowtheme)

### SetDarkMode, RemoveDarkMode

```freebasic
function SetDarkMode( byval hToolbar as HWND ) as HRESULT
function RemoveDarkMode( byval hToolbar as HWND ) as HRESULT
```

`SetDarkMode` gives the toolbar the dark theme of Explorer's information pane
(`DarkMode_InfoPaneToolbar`); `RemoveDarkMode` gives it back its normal visual style. Use them
with a window in dark mode, see [Dark mode](SysWin-Dark-Mode).

**Returns** `S_OK` on success, or an error code.

**Example**

```freebasic
if AppsUseDarkMode() then ToolBar.SetDarkMode( hCtrl ) else ToolBar.RemoveDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

### GetTooltips

```freebasic
function GetTooltips( byval hToolbar as HWND ) as HWND
```

**Returns** the tooltip control of the toolbar, or `NULL` when it has none. A toolbar with
`TBSTYLE_TOOLTIPS` (the `CWindow.AddControl` default) makes its own; its tooltips ask the parent
for their text with `TTN_GETDISPINFOW`, whose `hdr.hwndFrom` is this handle.

**Example**

```freebasic
dim hTip as HWND = ToolBar.GetTooltips( hCtrl )
if hTip then SendMessageW( hTip, TTM_SETMAXTIPWIDTH, 0, 300 )
```

Microsoft Learn: [TB_GETTOOLTIPS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-gettooltips)

### SetToolTips

```freebasic
sub SetToolTips( byval hToolbar as HWND, byval hwndToolTip as HWND )
```

Gives the toolbar the tooltip control `hwndToolTip` to use instead of its own.

**Example**

```freebasic
dim hTip as HWND = CreateWindowExW( 0, TOOLTIPS_CLASSW, NULL, TTS_ALWAYSTIP, 0, 0, 0, 0, hwnd, NULL, NULL, NULL )
ToolBar.SetToolTips( hCtrl, hTip )
```

Microsoft Learn: [TB_SETTOOLTIPS](https://learn.microsoft.com/en-us/windows/win32/controls/tb-settooltips)

### SetParent

```freebasic
function SetParent( byval hToolbar as HWND, byval hwndParent as HWND ) as HWND
```

Sets the window that receives the toolbar's `WM_COMMAND` and `WM_NOTIFY` messages. The toolbar's
parent window, and where it is drawn, stay as they are.

**Returns** the previous notification window, or `NULL`.

**Example**

```freebasic
ToolBar.SetParent( hCtrl, hwnd )
```

Microsoft Learn: [TB_SETPARENT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-setparent)

### Customize

```freebasic
sub Customize( byval hToolbar as HWND )
```

Opens the Customize Toolbar dialog, in which the user adds, removes and reorders buttons. The
toolbar needs `CCS_ADJUSTABLE`, and the parent must answer the `TBN_QUERYINSERT`,
`TBN_QUERYDELETE` and `TBN_GETBUTTONINFOW` notifications. The call returns when the dialog
closes.

**Example**

```freebasic
ToolBar.Customize( hCtrl )
```

Microsoft Learn: [TB_CUSTOMIZE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-customize)

### SaveRestore

```freebasic
sub SaveRestore overload( byval hToolbar as HWND, byval fSave as long, byval ptbsp as TBSAVEPARAMSW ptr )
sub SaveRestore overload( byval hToolbar as HWND, byval fSave as long, byref tbsp as TBSAVEPARAMSW )
```

Saves the toolbar's buttons to a registry value (`fSave` nonzero) or rebuilds them from it
(0). The `TBSAVEPARAMSW` names the key (`hkr`, `pszSubKey`) and the value (`pszValueName`).

**Example**

```freebasic
dim tbsp as TBSAVEPARAMSW
tbsp.hkr = HKEY_CURRENT_USER : tbsp.pszSubKey = @wstr( "Software\MyApp" ) : tbsp.pszValueName = @wstr( "Toolbar" )
ToolBar.SaveRestore( hCtrl, CTRUE, tbsp )
```

Microsoft Learn: [TB_SAVERESTORE](https://learn.microsoft.com/en-us/windows/win32/controls/tb-saverestore)

### GetObject

```freebasic
function GetObject( byval hToolbar as HWND ) as IDropTarget ptr
```

Meant to return the toolbar's `IDropTarget`, the interface it uses when something is dragged
over it. As written it gives the control a null address to store the pointer in, and the program
stops with an access violation. Send the message yourself, with the address of your pointer, as
in the example; release the interface when done.

**Returns** nothing usable: the call does not come back.

**Example**

```freebasic
dim iid as GUID = ( &h00000122, &h0000, &h0000, { &hC0, 0, 0, 0, 0, 0, 0, &h46 } )   ' IID_IDropTarget
dim pDropTarget as IDropTarget ptr
if SendMessageW( hCtrl, TB_GETOBJECT, cast( WPARAM, @iid ), cast( LPARAM, @pDropTarget ) ) = S_OK then pDropTarget->lpVtbl->Release( pDropTarget )
```

Microsoft Learn: [TB_GETOBJECT](https://learn.microsoft.com/en-us/windows/win32/controls/tb-getobject)

## See also

- [sys/win/gui](SysWin-Gui)
- [Rebar](SysWin-Gui-Rebar) for toolbars in movable bands
- [CWindow](CWindow) for `AddControl( "Toolbar", ... )`
- [ToolTip](SysWin-Gui-ToolTip)
- [Menu](SysWin-Gui-Menu) for the drop-down menu of a `BTNS_DROPDOWN` button
- [gui macros and helpers](SysWin-Gui-Procedures) for reading `WM_COMMAND` and `WM_NOTIFY`
- [Dark mode](SysWin-Dark-Mode)
