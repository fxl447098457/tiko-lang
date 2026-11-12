[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **Button**

# Button

Checks, clicks and labels push buttons, check boxes, radio buttons and split buttons.

One window class, `Button`, draws push buttons, check boxes, three-state check boxes, radio
buttons, group boxes, split buttons and command links; the `BS_*` style picks which. Create one
with `CWindow.AddControl`: `"Button"`, `"CheckBox"`, `"Check3State"`, `"RadioButton"` (pass
`WS_GROUP` as the style for the first of a group), `"GroupBox"`, `"BitmapButton"` or
`"IconButton"`, or `"Button"` with `BS_SPLITBUTTON` or `BS_COMMANDLINK` in the style. Every
function here takes the button's handle first and is written with the namespace:
`Button.GetCheck( hCheck )`.

A click reaches the parent as `WM_COMMAND` with `BN_CLICKED`; the arrow of a split button sends
`BCN_DROPDOWN` in a `WM_NOTIFY`. The functions here are programmatic: apart from
[Click](#click), none of them makes the button notify its parent.

**Images.** A button shows a bitmap or an icon (`BS_BITMAP`, `BS_ICON`) or an image list next to
its text. It never destroys any of them: the program does, once the button no longer uses them.
[FreeBitmap](#freebitmap) removes and deletes a bitmap; [DeleteIcon](#deleteicon) removes an icon
but cannot destroy it, so keep the handle and pass it to `DestroyIcon`.

**Version 6.** Image lists, ideal size, text margins, split buttons, notes and the shield icon
belong to version 6 of the common controls, which a program selects with a manifest or by calling
`EnableVisualStyles()` before it creates the button. Without it those functions return 0 or
`false` and do nothing.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A check box, a three-state check box, two radio buttons and a command link with a note. Clicking
the command link puts the three choices in the caption.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_BOLD = 101
const IDC_SHARED = 102
const IDC_SMALL = 103
const IDC_LARGE = 104
const IDC_APPLY = 105

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function CheckName( byval hButton as HWND ) as ustring
    select case Button.GetCheck( hButton )
        case BST_CHECKED : return "on"
        case BST_INDETERMINATE : return "mixed"
    end select
    return "off"
end function

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    EnableVisualStyles()
    dim pWindow as CWindow = "ButtonDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Button", @WndProc )
    pWindow.SetClientSize( 360, 190 )
    pWindow.Center()
    pWindow.AddControl( "CheckBox", hWin, IDC_BOLD, "&Bold", 20, 20, 150, 22 )
    dim hShared as HWND = pWindow.AddControl( "Check3State", hWin, IDC_SHARED, "&Shared", 20, 48, 150, 22 )
    dim hSmall as HWND = pWindow.AddControl( "RadioButton", hWin, IDC_SMALL, "S&mall", 200, 20, 140, 22, WS_GROUP )
    pWindow.AddControl( "RadioButton", hWin, IDC_LARGE, "&Large", 200, 48, 140, 22 )
    dim hApply as HWND = pWindow.AddControl( "Button", hWin, IDC_APPLY, "&Apply", 20, 95, 320, 70, _
                                             WS_VISIBLE or WS_TABSTOP or BS_COMMANDLINK )
    Button.SetNote( hApply, "Shows the choices in the caption" )
    Button.Indeterminate( hShared )
    Button.Check( hSmall )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTL( wParam, lParam ) = IDC_APPLY andalso CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                dim ustrSize as ustring = "small"
                if Button.GetCheck( GetDlgItem( hwnd, IDC_LARGE ) ) = BST_CHECKED then ustrSize = "large"
                SetWindowText( hwnd, "Bold " & CheckName( GetDlgItem( hwnd, IDC_BOLD ) ) & _
                                     ", shared " & CheckName( GetDlgItem( hwnd, IDC_SHARED ) ) & ", " & ustrSize )
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

| Function | Does |
| --- | --- |
| [Click](#click) | Clicks the button as if the user had. |
| [GetText](#gettext) | Returns the button's text. |
| [GetTextLength](#gettextlength) | Returns the length of the button's text. |
| [SetText](#settext) | Changes the button's text. |
| [Enable](#enable) | Lets the user click the button. |
| [Disable](#disable) | Greys the button out. |
| [GetCheck](#getcheck) | Returns whether a check box or radio button is checked. |
| [SetCheck](#setcheck) | Sets a check box or radio button to a check state. |
| [Check](#check) | Checks a check box or radio button. |
| [Uncheck](#uncheck) | Clears a check box or radio button. |
| [Gray](#gray) | Sets a three-state check box to its mixed state. |
| [Indeterminate](#indeterminate) | Sets a three-state check box to its mixed state. |
| [GetState](#getstate) | Returns the check, pushed, focus and hot state flags. |
| [SetState](#setstate) | Draws the button pushed in or released. |
| [GetStyle](#getstyle) | Returns the button's window style. |
| [SetStyle](#setstyle) | Changes the button's style. |
| [SetDontClick](#setdontclick) | Sets the flag that once made radio buttons click on focus. |
| [GetImage](#getimage) | Returns the bitmap or icon the button shows. |
| [GetBitmap](#getbitmap) | Returns the bitmap the button shows. |
| [GetIcon](#geticon) | Returns the icon the button shows. |
| [SetImage](#setimage) | Gives the button a bitmap or an icon. |
| [SetBitmap](#setbitmap) | Gives the button a bitmap. |
| [SetIcon](#seticon) | Gives the button an icon. |
| [DeleteImage](#deleteimage) | Removes the bitmap or icon and deletes it as a GDI object. |
| [FreeBitmap](#freebitmap) | Removes and deletes the button's bitmap. |
| [DeleteIcon](#deleteicon) | Removes the button's icon. |
| [GetImageList](#getimagelist) | Reads the image list shown next to the text. |
| [SetImageList](#setimagelist) | Shows an image list next to the text. |
| [GetIdealSize](#getidealsize) | Returns the size that fits the text and image. |
| [GetTextMargin](#gettextmargin) | Returns the margins around the text. |
| [SetTextMargin](#settextmargin) | Sets the margins around the text. |
| [SetDropDownState](#setdropdownstate) | Draws a split button's arrow pushed in or released. |
| [GetSplitInfo](#getsplitinfo) | Reads a split button's settings into a `BUTTON_SPLITINFO`. |
| [SetSplitInfo](#setsplitinfo) | Changes a split button's settings from a `BUTTON_SPLITINFO`. |
| [GetSplitStyle](#getsplitstyle) | Returns a split button's `BCSS_*` style. |
| [SetSplitStyle](#setsplitstyle) | Sets a split button's `BCSS_*` style. |
| [GetSplitImageList](#getsplitimagelist) | Returns the image list of a split button's arrow part. |
| [SetSplitImageList](#setsplitimagelist) | Sets the image list of a split button's arrow part. |
| [GetSplitGlyphSize](#getsplitglyphsize) | Returns the size of a split button's arrow part. |
| [SetSplitGlyphSize](#setsplitglyphsize) | Sets the size of a split button's arrow part. |
| [GetNoteLength](#getnotelength) | Returns the length of a command link's note. |
| [GetNote](#getnote) | Returns a command link's note. |
| [SetNote](#setnote) | Sets the note under a command link's text. |
| [SetElevationRequiredState](#setelevationrequiredstate) | Shows or hides the shield icon. |
| [SetDarkMode](#setdarkmode) | Draws the button with the dark theme. |
| [RemoveDarkMode](#removedarkmode) | Draws the button with the default theme again. |

## Reference

### Click

```freebasic
sub Click( byval hButton as HWND )
```

Clicks the button as if the user had: the button receives a mouse press and release and its
parent receives `BN_CLICKED`, so an automatic check box or radio button also changes its state.
It does so while the button is disabled, too.

**Example**

```freebasic
Button.Click( hCtrl )
```

Microsoft Learn: [BM_CLICK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-click)

### GetText

```freebasic
function GetText( byval hButton as HWND ) as ustring
```

Returns the button's text. The string is one character longer than the text: its last character
is the null character that ends it, so `len()` is [GetTextLength](#gettextlength) + 1 and a
comparison with a literal is false. Remove it with `rtrim( ..., chr(0) )`.

**Returns** the text and its terminating null.

**Example**

```freebasic
dim ustrCaption as ustring = rtrim( Button.GetText( hCtrl ), chr(0) )
if ustrCaption = "&OK" then print "the OK button"
```

Microsoft Learn: [GetWindowTextW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtextw)

### GetTextLength

```freebasic
function GetTextLength( byval hButton as HWND ) as long
```

Returns the number of characters in the button's text, an `&` that marks the access key
included.

**Returns** the length, or 0 when the button has no text.

**Example**

```freebasic
print "the caption has"; Button.GetTextLength( hCtrl ); " characters"
```

Microsoft Learn: [GetWindowTextLengthW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtextlengthw)

### SetText

```freebasic
function SetText( byval hButton as HWND, byval pwszText as wstring ptr ) as boolean
```

Replaces the button's text. An `&` underlines the next character and makes it the access key;
write `&&` for an ampersand.

**Returns** `true` on success.

**Example**

```freebasic
Button.SetText( hCtrl, "&Stop" )
```

Microsoft Learn: [SetWindowTextW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowtextw)

### Enable

```freebasic
function Enable( byval hButton as HWND ) as boolean
```

Enables the button, so that it takes mouse and keyboard input again and is drawn normally.

**Returns** `true` when the button was disabled before the call, `false` when it was already
enabled.

**Example**

```freebasic
Button.Enable( hCtrl )
```

Microsoft Learn: [EnableWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablewindow)

### Disable

```freebasic
function Disable( byval hButton as HWND ) as boolean
```

Disables the button: it is greyed out and ignores the mouse and the keyboard.

**Returns** `true` when the button was already disabled before the call, `false` when it was
enabled.

**Example**

```freebasic
Button.Disable( hCtrl )
```

Microsoft Learn: [EnableWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablewindow)

### GetCheck

```freebasic
function GetCheck( byval hButton as HWND ) as LRESULT
```

Returns the check state of a check box or radio button. A push button returns `BST_UNCHECKED`.

**Returns** `BST_UNCHECKED` (0), `BST_CHECKED` (1) or, for a three-state check box,
`BST_INDETERMINATE` (2).

**Example**

```freebasic
if Button.GetCheck( hCtrl ) = BST_CHECKED then print "checked"
```

Microsoft Learn: [BM_GETCHECK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-getcheck)

### SetCheck

```freebasic
sub SetCheck( byval hButton as HWND, byval checkState as long )
```

Sets a check box or radio button to `BST_UNCHECKED`, `BST_CHECKED` or `BST_INDETERMINATE`. The
parent is not notified, and checking one radio button does not clear the others of its group.

**Example**

```freebasic
Button.SetCheck( hCtrl, BST_CHECKED )
```

Microsoft Learn: [BM_SETCHECK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setcheck)

### Check

```freebasic
sub Check( byval hButton as HWND )
```

Checks a check box or radio button: [SetCheck](#setcheck) with `BST_CHECKED`.

**Example**

```freebasic
Button.Check( hCtrl )
```

Microsoft Learn: [BM_SETCHECK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setcheck)

### Uncheck

```freebasic
sub Uncheck( byval hButton as HWND )
```

Clears a check box or radio button: [SetCheck](#setcheck) with `BST_UNCHECKED`.

**Example**

```freebasic
Button.Uncheck( hCtrl )
```

Microsoft Learn: [BM_SETCHECK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setcheck)

### Gray

```freebasic
sub Gray( byval hButton as HWND )
```

Sets a three-state check box (`BS_3STATE` or `BS_AUTO3STATE`) to its mixed state:
[SetCheck](#setcheck) with `BST_INDETERMINATE`. The same as [Indeterminate](#indeterminate).

**Example**

```freebasic
Button.Gray( hCtrl )
```

Microsoft Learn: [BM_SETCHECK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setcheck)

### Indeterminate

```freebasic
sub Indeterminate( byval hButton as HWND )
```

Sets a three-state check box to its mixed state, as [Gray](#gray) does.

**Example**

```freebasic
Button.Indeterminate( hCtrl )
if Button.GetCheck( hCtrl ) = BST_INDETERMINATE then print "mixed"
```

Microsoft Learn: [BM_SETCHECK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setcheck)

### GetState

```freebasic
function GetState( byval hButton as HWND ) as LRESULT
```

Returns the state of the button as `BST_*` flags: the check state in the low bits, plus
`BST_PUSHED` while it is drawn pushed in, `BST_FOCUS` while it has the keyboard focus, `BST_HOT`
while the mouse is over it and, for a split button, `BST_DROPDOWNPUSHED` while its arrow is
pushed.

**Returns** the flags. A checked box drawn pushed in returns `BST_CHECKED or BST_PUSHED` (5).

**Example**

```freebasic
if Button.GetState( hCtrl ) and BST_PUSHED then print "pushed in"
```

Microsoft Learn: [BM_GETSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-getstate)

### SetState

```freebasic
sub SetState( byval hButton as HWND, byval bstate as boolean )
```

Draws the button pushed in (`true`) or released (`false`), as while the user holds the mouse
button down on it. It does not click the button or change its check state.

**Example**

```freebasic
Button.SetState( hCtrl, true )
```

Microsoft Learn: [BM_SETSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setstate)

### GetStyle

```freebasic
function GetStyle( byval hButton as HWND ) as DWORD
```

Returns the button's whole window style: the `WS_*` bits and the `BS_*` bits. The kind of button
is `GetStyle( h ) and BS_TYPEMASK`.

**Returns** the style.

**Example**

```freebasic
if ( Button.GetStyle( hCtrl ) and BS_TYPEMASK ) = BS_AUTOCHECKBOX then print "a check box"
```

Microsoft Learn: [GetWindowLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowlongptrw)

### SetStyle

```freebasic
sub SetStyle( byval hButton as HWND, byval dwStyle as DWORD, byval fRedraw as boolean )
```

Changes the button's `BS_*` style, for instance from `BS_PUSHBUTTON` to `BS_DEFPUSHBUTTON`, and
redraws it when `fRedraw` is `true`.

| Parameter | Meaning |
| --- | --- |
| `hButton` | The button. |
| `dwStyle` | The new `BS_*` style. |
| `fRedraw` | `true` to redraw the button now. |

**Example**

```freebasic
Button.SetStyle( hCtrl, BS_DEFPUSHBUTTON, true )
```

Microsoft Learn: [BM_SETSTYLE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setstyle)

### SetDontClick

```freebasic
sub SetDontClick( byval hButton as HWND, byval fState as boolean )
```

Sets the flag that stops a radio button from sending `BN_CLICKED` when it gets the focus.
Current versions of Windows never send it on focus, so the flag changes nothing.

**Example**

```freebasic
Button.SetDontClick( hCtrl, true )
```

Microsoft Learn: [BM_SETDONTCLICK](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setdontclick)

### GetImage

```freebasic
function GetImage( byval hButton as HWND, byval imgType as long ) as HANDLE
```

Returns the bitmap (`IMAGE_BITMAP`) or icon (`IMAGE_ICON`) the button shows. The button still
owns the use of it; do not destroy it while the button shows it.

**Returns** the handle, or `NULL` when the button has no image of that type.

**Example**

```freebasic
dim hImage as HANDLE = Button.GetImage( hCtrl, IMAGE_BITMAP )
```

Microsoft Learn: [BM_GETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-getimage)

### GetBitmap

```freebasic
function GetBitmap( byval hButton as HWND ) as HANDLE
```

Returns the bitmap the button shows: [GetImage](#getimage) with `IMAGE_BITMAP`.

**Returns** the bitmap, or `NULL`.

**Example**

```freebasic
dim hBmp as HBITMAP = cast( HBITMAP, Button.GetBitmap( hCtrl ) )
```

Microsoft Learn: [BM_GETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-getimage)

### GetIcon

```freebasic
function GetIcon( byval hButton as HWND ) as HANDLE
```

Returns the icon the button shows: [GetImage](#getimage) with `IMAGE_ICON`.

**Returns** the icon, or `NULL`.

**Example**

```freebasic
dim hIcon as HICON = cast( HICON, Button.GetIcon( hCtrl ) )
```

Microsoft Learn: [BM_GETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-getimage)

### SetImage

```freebasic
function SetImage( byval hButton as HWND, byval ImageType as DWORD, byval hImage as HANDLE ) as HANDLE
```

Gives the button a bitmap (`IMAGE_BITMAP`) or an icon (`IMAGE_ICON`). A button with `BS_BITMAP`
or `BS_ICON` shows only the image; with version 6 of the common controls, any other push button
shows it next to its text. The button does not take ownership: destroy the image yourself once
the button no longer shows it, and destroy the previous image this returns if nothing else uses
it.

| Parameter | Meaning |
| --- | --- |
| `hButton` | The button. |
| `ImageType` | `IMAGE_BITMAP` or `IMAGE_ICON`. |
| `hImage` | The bitmap or icon, or `NULL` to remove the image. |

**Returns** the image the button showed before, or `NULL`.

**Example**

```freebasic
dim hIcon as HICON = LoadIconW( NULL, cast( LPCWSTR, IDI_INFORMATION ) )
Button.SetImage( hCtrl, IMAGE_ICON, hIcon )
```

Microsoft Learn: [BM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setimage)

### SetBitmap

```freebasic
function SetBitmap( byval hButton as HWND, byval hbmp as HBITMAP ) as HBITMAP
```

Gives the button a bitmap: [SetImage](#setimage) with `IMAGE_BITMAP`. The program still owns
the bitmap; [FreeBitmap](#freebitmap) removes and deletes it.

**Returns** the bitmap the button showed before, or `NULL`.

**Example**

```freebasic
dim hBmp as HBITMAP = cast( HBITMAP, LoadImageW( NULL, "logo.bmp", IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE ) )
if hBmp then Button.SetBitmap( hCtrl, hBmp )
```

Microsoft Learn: [BM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setimage)

### SetIcon

```freebasic
function SetIcon( byval hButton as HWND, byval hIcon as HICON ) as HICON
```

Gives the button an icon: [SetImage](#setimage) with `IMAGE_ICON`. The program still owns the
icon and destroys it with `DestroyIcon` once the button no longer shows it (an icon from
`LoadIconW` is shared and is never destroyed).

**Returns** the icon the button showed before, or `NULL`.

**Example**

```freebasic
Button.SetIcon( hCtrl, LoadIconW( NULL, cast( LPCWSTR, IDI_WARNING ) ) )
```

Microsoft Learn: [BM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/bm-setimage)

### DeleteImage

```freebasic
function DeleteImage( byval hButton as HWND, byval ImageType as DWORD ) as boolean
```

Removes the button's image of type `ImageType` and passes the handle it had to `DeleteObject`.
That deletes a bitmap. An icon is not a GDI object: `DeleteObject` fails, the icon is removed
from the button but stays in memory, and the function returns `false`; read it with
[GetIcon](#geticon) first and destroy it with `DestroyIcon`.

**Returns** `true` when the image was deleted; `false` for an icon, or when the button had no
image of that type.

**Example**

```freebasic
Button.DeleteImage( hCtrl, IMAGE_BITMAP )
```

Microsoft Learn: [DeleteObject](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deleteobject)

### FreeBitmap

```freebasic
function FreeBitmap( byval hButton as HWND ) as boolean
```

Removes the button's bitmap and deletes it. Call it before the program ends, or before giving a
`BitmapButton` a new bitmap, so that the old one is not leaked.

**Returns** `true` when a bitmap was deleted, `false` when the button had none.

**Example**

```freebasic
Button.FreeBitmap( hCtrl )
```

Microsoft Learn: [DeleteObject](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deleteobject)

### DeleteIcon

```freebasic
function DeleteIcon( byval hButton as HWND ) as boolean
```

Removes the button's icon. The icon is passed to `DeleteObject`, which does not destroy icons,
so it stays in memory and the function returns `false`. To free an icon the program created,
read it first and destroy it.

**Returns** `false` (the icon is removed but not destroyed).

**Example**

```freebasic
dim hIcon as HICON = cast( HICON, Button.GetIcon( hCtrl ) )
Button.DeleteIcon( hCtrl )
if hIcon then DestroyIcon( hIcon )
```

Microsoft Learn: [DestroyIcon](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroyicon)

### GetImageList

```freebasic
function GetImageList( byval hButton as HWND, byval pbuttonImagelist as BUTTON_IMAGELIST ptr ) as boolean
function GetImageList( byval hButton as HWND, byref buttonImagelist as BUTTON_IMAGELIST ) as boolean
function GetImageList( byval hButton as HWND ) as BUTTON_IMAGELIST
```

Reads the image list the button shows next to its text, with its margins and alignment, into a
`BUTTON_IMAGELIST`. The third form returns the structure; its `himl` is `NULL` when the button
has none. Needs version 6 of the common controls.

**Returns** `true` on success (first two forms), or the structure.

**Example**

```freebasic
dim bil as BUTTON_IMAGELIST = Button.GetImageList( hCtrl )
if bil.himl then print "align"; bil.uAlign
```

Microsoft Learn: [BCM_GETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-getimagelist)

### SetImageList

```freebasic
function SetImageList( byval hButton as HWND, byval pbuttonImagelist as BUTTON_IMAGELIST ptr ) as boolean
function SetImageList( byval hButton as HWND, byval himl as HIMAGELIST, byval nLeft as long, byval nTop as long, byval nRight as long, byval nBottom as long, byval uALign as UINT = 0 ) as boolean
```

Shows an image list next to the button's text. With one image the button shows it in every
state; with six, it shows the image for its state (normal, hot, pressed, disabled, defaulted,
stylus hot). The second form fills the `BUTTON_IMAGELIST` for you: `nLeft` to `nBottom` are the
margins around the image, and `uALign` is `BUTTON_IMAGELIST_ALIGN_LEFT` (0, the default),
`_RIGHT`, `_TOP`, `_BOTTOM` or `_CENTER`. The button does not destroy the image list. Needs
version 6 of the common controls.

| Parameter | Meaning |
| --- | --- |
| `hButton` | The button. |
| `pbuttonImagelist` | The image list, margins and alignment. |
| `himl` | The image list. |
| `nLeft`, `nTop`, `nRight`, `nBottom` | The space to leave around the image, in pixels. |
| `uALign` | Where the image goes. |

**Returns** `true` on success.

**Example**

```freebasic
dim himl as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32, 1, 0 )
ImageList_AddIcon( himl, LoadIconW( NULL, cast( LPCWSTR, IDI_SHIELD ) ) )
Button.SetImageList( hCtrl, himl, 4, 0, 0, 0, BUTTON_IMAGELIST_ALIGN_LEFT )
```

Microsoft Learn: [BCM_SETIMAGELIST](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setimagelist)

### GetIdealSize

```freebasic
function GetIdealSize( byval hButton as HWND, byval pSize as SIZE ptr ) as boolean
function GetIdealSize( byval hButton as HWND, byref sz as SIZE ) as boolean
function GetIdealSize( byval hButton as HWND ) as ( long, long )
```

Returns the width and height, in pixels, that fit the button's text and image list in its
current font. For a command link, set `cx` of the `SIZE` to the width wanted before the call
(first two forms), and `cy` comes back as the height needed at that width; the third form passes
a width of 0. Needs version 6 of the common controls.

**Returns** `true` on success (first two forms), or `( cx, cy )`; afterwards `GetLastError()` is
1 when the call succeeded and 0 when it failed.

**Example**

```freebasic
var (cx, cy) = Button.GetIdealSize( hCtrl )
if GetLastError() = 1 then SetWindowSize( hCtrl, cx, cy )
```

Microsoft Learn: [BCM_GETIDEALSIZE](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-getidealsize)

### GetTextMargin

```freebasic
function GetTextMargin( byval hButton as HWND, byval pMargin as RECT ptr ) as boolean
function GetTextMargin( byval hButton as HWND, byref margin as RECT ) as boolean
function GetTextMargin( byval hButton as HWND ) as ( long, long, long, long )
```

Returns the space the button leaves around its text, in pixels, as left, top, right and bottom
margins. Needs version 6 of the common controls.

**Returns** `true` on success (first two forms), or `( left, top, right, bottom )`; afterwards
`GetLastError()` is 1 when the call succeeded and 0 when it failed.

**Example**

```freebasic
var (l, t, r, b) = Button.GetTextMargin( hCtrl )
if GetLastError() = 1 then print "margins"; l; t; r; b
```

Microsoft Learn: [BCM_GETTEXTMARGIN](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-gettextmargin)

### SetTextMargin

```freebasic
function SetTextMargin( byval hButton as HWND, byval pMargin as RECT ptr ) as boolean
function SetTextMargin( byval hButton as HWND, byref margin as RECT ) as boolean
function SetTextMargin( byval hButton as HWND, byval nLeft as long, byval nTop as long, byval nRight as long, byval nBottom as long ) as boolean
```

Sets the space the button leaves around its text, in pixels, from a `RECT` whose members are the
four margins, or from four numbers. Needs version 6 of the common controls.

**Returns** `true` on success.

**Example**

```freebasic
Button.SetTextMargin( hCtrl, 8, 2, 8, 2 )
```

Microsoft Learn: [BCM_SETTEXTMARGIN](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-settextmargin)

### SetDropDownState

```freebasic
function SetDropDownState( byval hButton as HWND, byval fDropDown as boolean ) as boolean
```

Draws the arrow part of a split button (`BS_SPLITBUTTON`) pushed in (`true`) or released
(`false`). Push it in while the drop-down menu is open, in answer to `BCN_DROPDOWN`, and release
it when the menu closes. [GetState](#getstate) has `BST_DROPDOWNPUSHED` while it is pushed in.

**Returns** what the button returns. In testing it returned `false` even when the arrow was
pushed in, so check [GetState](#getstate) rather than the return value.

**Example**

```freebasic
Button.SetDropDownState( hCtrl, true )
' ... show the menu ...
Button.SetDropDownState( hCtrl, false )
```

Microsoft Learn: [BCM_SETDROPDOWNSTATE](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setdropdownstate)

### GetSplitInfo

```freebasic
function GetSplitInfo( byval hButton as HWND, byval pinfo as BUTTON_SPLITINFO ptr ) as boolean
function GetSplitInfo( byval hButton as HWND, byref info as BUTTON_SPLITINFO ) as boolean
function GetSplitInfo( byval hButton as HWND ) as BUTTON_SPLITINFO
```

Reads the settings of a split button into a `BUTTON_SPLITINFO`. In the first two forms set
`mask` to the `BCSIF_*` members you want before the call. The third form asks for the image list
(`BCSIF_IMAGE`), the size (`BCSIF_SIZE`) and the style (`BCSIF_STYLE`) and returns the structure.

**Returns** `true` on success (first two forms), or the structure; afterwards the third form
leaves `GetLastError()` at 1 when the call succeeded and 0 when it failed.

**Example**

```freebasic
dim info as BUTTON_SPLITINFO = Button.GetSplitInfo( hCtrl )
if GetLastError() = 1 then print "arrow width"; info.size.cx
```

Microsoft Learn: [BCM_GETSPLITINFO](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-getsplitinfo)

### SetSplitInfo

```freebasic
function SetSplitInfo( byval hButton as HWND, byval pinfo as BUTTON_SPLITINFO ptr ) as boolean
function SetSplitInfo( byval hButton as HWND, byref info as BUTTON_SPLITINFO ) as boolean
```

Changes the settings of a split button named in `mask`: the image list or glyph, the size of the
arrow part and the `BCSS_*` style.

**Returns** `true` on success.

**Example**

```freebasic
dim info as BUTTON_SPLITINFO
info.mask = BCSIF_STYLE : info.uSplitStyle = BCSS_ALIGNLEFT
Button.SetSplitInfo( hCtrl, info )
```

Microsoft Learn: [BCM_SETSPLITINFO](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setsplitinfo)

### GetSplitStyle

```freebasic
function GetSplitStyle( byval hButton as HWND ) as UINT
```

Returns the style of a split button: a combination of `BCSS_NOSPLIT` (no separate arrow part),
`BCSS_STRETCH` (the glyph keeps its proportions), `BCSS_ALIGNLEFT` (the arrow part on the left)
and `BCSS_IMAGE` (an image list in place of the arrow).

**Returns** the `BCSS_*` flags; afterwards `GetLastError()` is 1 when the call succeeded and 0
when it failed.

**Example**

```freebasic
if Button.GetSplitStyle( hCtrl ) and BCSS_NOSPLIT then print "one part"
```

Microsoft Learn: [BUTTON_SPLITINFO](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/ns-commctrl-button_splitinfo)

### SetSplitStyle

```freebasic
function SetSplitStyle( byval hButton as HWND, byval uStyle as UINT ) as boolean
```

Sets the `BCSS_*` style of a split button; see [GetSplitStyle](#getsplitstyle).

**Returns** `true` on success.

**Example**

```freebasic
Button.SetSplitStyle( hCtrl, BCSS_ALIGNLEFT )
```

Microsoft Learn: [BCM_SETSPLITINFO](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setsplitinfo)

### GetSplitImageList

```freebasic
function GetSplitImageList( byval hButton as HWND ) as HIMAGELIST
```

Returns the image list a split button shows in its arrow part.

**Returns** the image list, or `NULL` when it shows the standard arrow; afterwards
`GetLastError()` is 1 when the call succeeded and 0 when it failed.

**Example**

```freebasic
dim himl as HIMAGELIST = Button.GetSplitImageList( hCtrl )
```

Microsoft Learn: [BCM_GETSPLITINFO](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-getsplitinfo)

### SetSplitImageList

```freebasic
function SetSplitImageList( byval hButton as HWND, byval himlGlyph as HIMAGELIST ) as boolean
```

Sets the image list a split button shows in its arrow part. Add `BCSS_IMAGE` to its style with
[SetSplitStyle](#setsplitstyle) for the image to be drawn. The button does not destroy the image
list.

**Returns** `true` on success.

**Example**

```freebasic
dim himl as HIMAGELIST = ImageList_Create( 16, 16, ILC_COLOR32, 1, 0 )
Button.SetSplitImageList( hCtrl, himl )
```

Microsoft Learn: [BCM_SETSPLITINFO](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setsplitinfo)

### GetSplitGlyphSize

```freebasic
function GetSplitGlyphSize( byval hButton as HWND ) as ( long, long )
```

Returns the size, in pixels, of the arrow part of a split button.

**Returns** `( cx, cy )`; afterwards `GetLastError()` is 1 when the call succeeded and 0 when it
failed.

**Example**

```freebasic
var (cx, cy) = Button.GetSplitGlyphSize( hCtrl )
if GetLastError() = 1 then print "arrow part"; cx; " x"; cy
```

Microsoft Learn: [BCM_GETSPLITINFO](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-getsplitinfo)

### SetSplitGlyphSize

```freebasic
function SetSplitGlyphSize( byval hButton as HWND, byval cx as long, byval cy as long ) as boolean
```

Sets the size, in pixels, of the arrow part of a split button.

**Returns** `true` on success.

**Example**

```freebasic
Button.SetSplitGlyphSize( hCtrl, 24, 0 )
```

Microsoft Learn: [BCM_SETSPLITINFO](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setsplitinfo)

### GetNoteLength

```freebasic
function GetNoteLength( byval hButton as HWND ) as long
```

Returns the number of characters in the note of a command link (`BS_COMMANDLINK`).

**Returns** the length, or 0 when there is no note.

**Example**

```freebasic
if Button.GetNoteLength( hCtrl ) = 0 then print "no note"
```

Microsoft Learn: [BCM_GETNOTELENGTH](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-getnotelength)

### GetNote

```freebasic
function GetNote( byval hButton as HWND ) as ustring
```

Returns the note of a command link, the smaller text under its caption. Unlike
[GetText](#gettext), the string has no null character at the end.

**Returns** the note, or `""` when there is none. When there is a note, `GetLastError()` is 1
afterwards if it was read.

**Example**

```freebasic
print "note: "; Button.GetNote( hCtrl )
```

Microsoft Learn: [BCM_GETNOTE](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-getnote)

### SetNote

```freebasic
function SetNote( byval hButton as HWND, byval pwsz as wstring ptr ) as boolean
```

Sets the note a command link shows under its caption. The button must be tall enough for two
lines of text; when it is not, Windows leaves the note out.

**Returns** `true` on success.

**Example**

```freebasic
Button.SetNote( hCtrl, "Keeps a copy of every file" )
```

Microsoft Learn: [BCM_SETNOTE](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setnote)

### SetElevationRequiredState

```freebasic
function SetElevationRequiredState( byval hButton as HWND, byval fRequired as boolean ) as long
```

Shows (`true`) or hides (`false`) the shield icon on a push button or command link, to say that
the action needs administrator rights.

**Returns** what the button returns: 0 in testing, also when the shield was shown.

**Example**

```freebasic
Button.SetElevationRequiredState( hCtrl, true )
```

Microsoft Learn: [BCM_SETSHIELD](https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setshield)

### SetDarkMode

```freebasic
function SetDarkMode( byval hButton as HWND ) as HRESULT
```

Gives the button the `DarkMode_Explorer` theme, the dark look of push buttons in File Explorer.
The text colour of check boxes, radio buttons and group boxes still comes from the parent's
`WM_CTLCOLORBTN` / `WM_CTLCOLORSTATIC` handling.

**Returns** `S_OK` on success.

**Example**

```freebasic
if AppsUseDarkMode() then Button.SetDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

### RemoveDarkMode

```freebasic
function RemoveDarkMode( byval hButton as HWND ) as HRESULT
```

Gives the button the default theme again.

**Returns** `S_OK` on success.

**Example**

```freebasic
Button.RemoveDarkMode( hCtrl )
```

Microsoft Learn: [SetWindowTheme](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for `AddControl( "Button", ... )` and the other button kinds
- [CXpButton](CXpButton) for an owner-drawn button with images in every state
- [Label](SysWin-Gui-Label) for static text and images
- [Dark mode](SysWin-Dark-Mode)
