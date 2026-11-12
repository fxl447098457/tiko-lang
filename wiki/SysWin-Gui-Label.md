[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **Label**

# Label

Sets and reads the text, icon, bitmap, cursor or metafile of a static control.

A static control, or label, shows something the user reads but does not edit: a line of text, an
icon, a bitmap, an enhanced metafile, a frame or an etched line. Create one with
`CWindow.AddControl`: `"Label"` for text (left-aligned, with `SS_NOTIFY` so that a click reaches
the parent as `STN_CLICKED`), `"IconLabel"` or `"BitmapLabel"` for an image loaded from the
resource named in the title, `"Frame"` and `"Line"` for decoration. Every function here takes
the control's handle first and is written with the namespace: `Label.SetText( hLabel, "Ready" )`.

**Images.** The style decides what a static control can show: `SS_ICON` an icon or a cursor,
`SS_BITMAP` a bitmap, `SS_ENHMETAFILE` an enhanced metafile. The control never destroys the
image it shows, not even when it is destroyed itself; the program does, once the control no
longer shows it. Bitmaps go to `DeleteObject`, which [FreeBitmap](#freebitmap) does for you.
Icons, cursors and metafiles are not GDI objects: [DeleteIcon](#deleteicon),
[DeleteCursor](#deletecursor) and [DeleteEnhancedMetafile](#deleteenhancedmetafile) take them
off the control but leave them in memory, so read the handle first and free it with
`DestroyIcon`, `DestroyCursor` or `DeleteEnhMetaFile`. Images loaded with `LR_SHARED`, and icons
from `LoadIconW`, are shared and never freed.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A label with the system's information icon beside it, and a text label that counts how often
it is clicked.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_INFOICON = 101
const IDC_CLICKTEXT = 102

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

dim shared nClicks as long

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "LabelDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Label", @WndProc )
    pWindow.SetClientSize( 320, 80 )
    pWindow.Center()
    dim hIcon as HWND = pWindow.AddControl( "IconLabel", hWin, IDC_INFOICON, "", 16, 20, 32, 32 )
    Label.SetIcon( hIcon, LoadIconW( NULL, cast( LPCWSTR, IDI_INFORMATION ) ) )
    pWindow.AddControl( "Label", hWin, IDC_CLICKTEXT, "Click this text", 60, 28, 240, 20 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTL( wParam, lParam ) = IDC_CLICKTEXT andalso CBCTLMSG( wParam, lParam ) = STN_CLICKED then
                nClicks += 1
                Label.SetText( GetDlgItem( hwnd, IDC_CLICKTEXT ), "Clicked " & nClicks & " times" )
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

The icon comes from `LoadIconW` and is shared, so nothing is freed at the end.

## Functions

| Function | Does |
| --- | --- |
| [GetText](#gettext) | Returns the label's text. |
| [GetTextLength](#gettextlength) | Returns the length of the label's text. |
| [SetText](#settext) | Changes the label's text. |
| [Enable](#enable) | Draws the label normally again. |
| [Disable](#disable) | Greys the label out. |
| [GetImage](#getimage) | Returns the image the label shows. |
| [GetIcon](#geticon) | Returns the icon the label shows. |
| [SetImage](#setimage) | Shows a bitmap, icon, cursor or enhanced metafile. |
| [SetBitmap](#setbitmap) | Shows a bitmap. |
| [SetIcon](#seticon) | Shows an icon. |
| [SetCursor](#setcursor) | Shows a cursor. |
| [SetEnhancedMetafile](#setenhancedmetafile) | Shows an enhanced metafile. |
| [DeleteImage](#deleteimage) | Takes an image off the label and deletes it as a GDI object. |
| [FreeBitmap](#freebitmap) | Takes the bitmap off the label and deletes it. |
| [DeleteIcon](#deleteicon) | Takes the icon off the label. |
| [DeleteCursor](#deletecursor) | Takes the cursor off the label. |
| [DeleteEnhancedMetafile](#deleteenhancedmetafile) | Takes the enhanced metafile off the label. |

## Reference

### GetText

```freebasic
function GetText( byval hStatic as HWND ) as ustring
```

Returns the label's text.

**Returns** the text of the control for an empty label, an empty string.

**Example**

```freebasic
dim ustrText as ustring = rtrim( Label.GetText( hCtrl ), chr(0) )
print "["; ustrText; "]"
```

Microsoft Learn: [GetWindowTextW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtextw)

### GetTextLength

```freebasic
function GetTextLength( byval hStatic as HWND ) as long
```

Returns the length of the label's text.

**Returns** the length, or 0 when the label has no text.

**Example**

```freebasic
if Label.GetTextLength( hCtrl ) = 0 then Label.SetText( hCtrl, "(empty)" )
```

Microsoft Learn: [GetWindowTextLengthW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtextlengthw)

### SetText

```freebasic
function SetText( byval hStatic as HWND, byval pwszText as wstring ptr ) as boolean
```

Replaces the label's text. Unless the label has `SS_NOPREFIX`, an `&` underlines the next
character, which then moves the focus to the next control in the tab order when pressed with
`Alt`; write `&&` for an ampersand.

**Returns** `true` on success.

**Example**

```freebasic
Label.SetText( hCtrl, "Saved " & time() )
```

Microsoft Learn: [SetWindowTextW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowtextw)

### Enable

```freebasic
function Enable( byval hStatic as HWND ) as boolean
```

Enables the label: its text is drawn normally again and, with `SS_NOTIFY`, clicks reach the
parent.

**Returns** `true` when the label was disabled before the call, `false` when it was already
enabled.

**Example**

```freebasic
Label.Enable( hCtrl )
```

Microsoft Learn: [EnableWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablewindow)

### Disable

```freebasic
function Disable( byval hStatic as HWND ) as boolean
```

Disables the label: its text is greyed out and it sends no notifications.

**Returns** `true` or `false`.

**Example**

```freebasic
Label.Disable( hCtrl )
```

Microsoft Learn: [EnableWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enablewindow)

### GetImage

```freebasic
function GetImage( byval hStatic as HWND, byval nType as long ) as HANDLE
```

Returns the image the label shows. `nType` is `IMAGE_BITMAP`, `IMAGE_ICON`, `IMAGE_CURSOR` or
`IMAGE_ENHMETAFILE`; an `SS_ICON` label returns its icon or cursor for both `IMAGE_ICON` and
`IMAGE_CURSOR`.

**Returns** the handle, or `NULL` when the label shows no image of that type.

**Example**

```freebasic
dim hBmp as HBITMAP = cast( HBITMAP, Label.GetImage( hCtrl, IMAGE_BITMAP ) )
```

Microsoft Learn: [STM_GETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/stm-getimage)

### GetIcon

```freebasic
function GetIcon( byval hStatic as HWND ) as HICON
```

Returns the icon of an `SS_ICON` label.

**Returns** the icon, or `NULL`.

**Example**

```freebasic
dim hIcon as HICON = Label.GetIcon( hCtrl )
```

Microsoft Learn: [STM_GETICON](https://learn.microsoft.com/en-us/windows/win32/controls/stm-geticon)

### SetImage

```freebasic
function SetImage( byval hStatic as HWND, byval nType as long, byval hImage as HANDLE ) as HANDLE
```

Shows an image. The label must have the style for it:

| `nType` | Style needed |
| --- | --- |
| `IMAGE_BITMAP` | `SS_BITMAP` |
| `IMAGE_ICON`, `IMAGE_CURSOR` | `SS_ICON` |
| `IMAGE_ENHMETAFILE` | `SS_ENHMETAFILE` |

The label does not take ownership: the program frees the image once the label no longer shows
it, and frees the previous image this returns if nothing else uses it. Pass `NULL` to remove
the image.

**Returns** the image shown before, or `NULL`.

**Example**

```freebasic
dim hOld as HANDLE = Label.SetImage( hCtrl, IMAGE_ICON, LoadIconW( NULL, cast( LPCWSTR, IDI_WARNING ) ) )
```

Microsoft Learn: [STM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/stm-setimage)

### SetBitmap

```freebasic
function SetBitmap( byval hStatic as HWND, byval hBmp as HBITMAP ) as HBITMAP
```

Shows a bitmap in an `SS_BITMAP` label: [SetImage](#setimage) with `IMAGE_BITMAP`. Unless the
label has `SS_REALSIZECONTROL`, it resizes itself to the bitmap. [FreeBitmap](#freebitmap)
takes the bitmap off again and deletes it.

**Returns** the bitmap shown before, or `NULL`; delete it if nothing else uses it.

**Example**

```freebasic
dim hBmp as HBITMAP = cast( HBITMAP, LoadImageW( NULL, "photo.bmp", IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE ) )
dim hOld as HBITMAP = Label.SetBitmap( hCtrl, hBmp )
if hOld then DeleteObject( hOld )
```

Microsoft Learn: [STM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/stm-setimage)

### SetIcon

```freebasic
function SetIcon( byval hStatic as HWND, byval hIcon as HICON ) as HICON
```

Shows an icon in an `SS_ICON` label.

**Returns** the icon shown before, or `NULL`.

**Example**

```freebasic
Label.SetIcon( hCtrl, LoadIconW( NULL, cast( LPCWSTR, IDI_INFORMATION ) ) )
```

Microsoft Learn: [STM_SETICON](https://learn.microsoft.com/en-us/windows/win32/controls/stm-seticon)

### SetCursor

```freebasic
function SetCursor( byval hStatic as HWND, byval hCur as HCURSOR ) as HCURSOR
```

Shows a cursor, drawn like an icon, in an `SS_ICON` label: [SetImage](#setimage) with
`IMAGE_CURSOR`. It does not change the mouse pointer over the label.

**Returns** the image shown before, or `NULL`.

**Example**

```freebasic
Label.SetCursor( hCtrl, LoadCursorW( NULL, cast( LPCWSTR, IDC_HAND ) ) )
```

Microsoft Learn: [STM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/stm-setimage)

### SetEnhancedMetafile

```freebasic
function SetEnhancedMetafile( byval hStatic as HWND, byval _hEnhMetafile as HENHMETAFILE ) as HENHMETAFILE
```

Shows an enhanced metafile, scaled to the label, in an `SS_ENHMETAFILE` label:
[SetImage](#setimage) with `IMAGE_ENHMETAFILE`.

**Returns** the metafile shown before, or `NULL`; free it with `DeleteEnhMetaFile` if nothing
else uses it.

**Example**

```freebasic
dim hEmf as HENHMETAFILE = GetEnhMetaFileW( "chart.emf" )
if hEmf then Label.SetEnhancedMetafile( hCtrl, hEmf )
```

Microsoft Learn: [STM_SETIMAGE](https://learn.microsoft.com/en-us/windows/win32/controls/stm-setimage)

### DeleteImage

```freebasic
function DeleteImage( byval hStatic as HWND, byval nType as long ) as boolean
```

Takes the image of type `nType` off the label and passes its handle to `DeleteObject`. That
deletes a bitmap. Icons, cursors and enhanced metafiles are not GDI objects: they are taken
off the label but stay in memory, and the function returns `false`.

**Returns** `true` when the image was deleted; `false` when it was not a bitmap, or the label
showed none.

**Example**

```freebasic
Label.DeleteImage( hCtrl, IMAGE_BITMAP )
```

Microsoft Learn: [DeleteObject](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deleteobject)

### FreeBitmap

```freebasic
function FreeBitmap( byval hStatic as HWND ) as boolean
```

Takes the bitmap off an `SS_BITMAP` label and deletes it. Call it before the program ends for
a `BitmapLabel`, whose bitmap `AddControl` loaded.

**Returns** `true` when a bitmap was deleted, `false` when the label had none.

**Example**

```freebasic
Label.FreeBitmap( hCtrl )
```

Microsoft Learn: [DeleteObject](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deleteobject)

### DeleteIcon

```freebasic
function DeleteIcon( byval hStatic as HWND ) as boolean
```

Takes the icon off an `SS_ICON` label. The icon is passed to `DeleteObject`, which does not
destroy icons, so it stays in memory; to free an icon the program created, read it first and
destroy it.

**Returns** `false` (the icon is taken off but not destroyed).

**Example**

```freebasic
dim hIcon as HICON = Label.GetIcon( hCtrl )
Label.DeleteIcon( hCtrl )
if hIcon then DestroyIcon( hIcon )
```

Microsoft Learn: [DestroyIcon](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroyicon)

### DeleteCursor

```freebasic
function DeleteCursor( byval hStatic as HWND ) as boolean
```

Takes the cursor off an `SS_ICON` label. As with [DeleteIcon](#deleteicon), the cursor itself
is not destroyed; free a cursor the program created with `DestroyCursor`.

**Returns** `false` (the cursor is taken off but not destroyed).

**Example**

```freebasic
dim hCur as HCURSOR = cast( HCURSOR, Label.GetImage( hCtrl, IMAGE_CURSOR ) )
Label.DeleteCursor( hCtrl )
if hCur then DestroyCursor( hCur )
```

Microsoft Learn: [DestroyCursor](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroycursor)

### DeleteEnhancedMetafile

```freebasic
function DeleteEnhancedMetafile( byval hStatic as HWND ) as boolean
```

Takes the enhanced metafile off an `SS_ENHMETAFILE` label. The metafile itself is not freed;
free it with `DeleteEnhMetaFile`.

**Returns** `false` (the metafile is taken off but not freed).

**Example**

```freebasic
dim hEmf as HENHMETAFILE = cast( HENHMETAFILE, Label.GetImage( hCtrl, IMAGE_ENHMETAFILE ) )
Label.DeleteEnhancedMetafile( hCtrl )
if hEmf then DeleteEnhMetaFile( hEmf )
```

Microsoft Learn: [DeleteEnhMetaFile](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-deleteenhmetafile)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for `AddControl( "Label", ... )`, `"IconLabel"`, `"BitmapLabel"`, `"Frame"` and `"Line"`
- [Button](SysWin-Gui-Button) for buttons, which take images the same way
- [Bitmaps](SysWin-Bitmaps) for loading and creating bitmaps
- [Dark mode](SysWin-Dark-Mode)
