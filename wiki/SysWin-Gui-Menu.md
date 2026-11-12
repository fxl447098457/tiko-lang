[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **Menu**

# Menu

Builds menu bars, drop-down and shortcut menus, and reads and changes their items.

A menu is an `HMENU`. [Create](#create) makes a menu bar, [CreatePopup](#createpopup-newpopup)
a drop-down, submenu or shortcut menu; items are added with [AppendItem](#appenditem) and
[AddPopup](#addpopup), and a bar is given to a window with [Attach](#attach-setmenu). Every
function is written with the namespace: `Menu.AppendItem( hFile, MF_ENABLED, IDM_OPEN, "&Open" )`.

**Items** are named in one of two ways, chosen by the `fByPosition` parameter: by their command
identifier (`false`, the default for most functions), which also finds an item inside the
menu's submenus, or by their zero-based position in that one menu (`true`). The defaults
differ in a few places, noted in each entry: [RemoveMenu](#removemenu-deletemenu),
[SetDefaultItem](#setdefaultitem) and [GetDefaultItem](#getdefaultitem) count by position
unless told otherwise. Choosing an item sends `WM_COMMAND` to the window with the identifier in
the low word of `wParam` (`CBCTL( wParam, lParam )`).

**Ownership.** A menu attached to a window is destroyed with the window. A menu that is not
attached, such as a shortcut menu built on the fly, must be destroyed with
[Destroy](#destroy); destroying a menu destroys its submenus too. Bitmaps placed on items are
never freed by the menu: [DestroyBitmaps](#destroybitmaps) does it.

**Redrawing.** Most functions that change an item redraw the menu bar themselves when the menu
they are given is the bar of a top-level window ([OwnerWindow](#ownerwindow) finds it). A
drop-down is drawn afresh each time it opens, so changes to its items show without a redraw.
[CheckItem](#checkitem), [UncheckItem](#uncheckitem), [ToggleItem](#toggleitem),
[AppendItem](#appenditem) and [Modify](#modify) never redraw: after changing the bar itself
with them, call [DrawBar](#drawbar).

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A window with a File, View and Help menu (Help on the right), View items that check and
uncheck, and a shortcut menu on right-click whose choice goes to the caption:

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

enum
    IDM_NEW = 1001
    IDM_EXIT
    IDM_STATUSBAR
    IDM_WORDWRAP
    IDM_ABOUT
    IDM_COPY
    IDM_PASTE
end enum

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function BuildMenu() as HMENU
    dim hMenu as HMENU = Menu.Create()
    dim hFile as HMENU = Menu.CreatePopup()
    Menu.AppendItem( hFile, MF_ENABLED, IDM_NEW, "&New" )
    Menu.AppendItem( hFile, MF_SEPARATOR, 0, "" )
    Menu.AppendItem( hFile, MF_ENABLED, IDM_EXIT, "E&xit" )
    Menu.AddPopup( hMenu, hFile, MF_ENABLED, 0, "&File" )
    dim hView as HMENU = Menu.CreatePopup()
    Menu.AppendItem( hView, MF_ENABLED or MF_CHECKED, IDM_STATUSBAR, "&Status bar" )
    Menu.AppendItem( hView, MF_ENABLED, IDM_WORDWRAP, "&Word wrap" )
    Menu.AddPopup( hMenu, hView, MF_ENABLED, 0, "&View" )
    dim hHelp as HMENU = Menu.CreatePopup()
    Menu.AppendItem( hHelp, MF_ENABLED, IDM_ABOUT, "&About" )
    Menu.AddPopup( hMenu, hHelp, MF_ENABLED, 0, "&Help" )
    Menu.RightJustifyItem( hMenu, 2 )
    return hMenu
end function

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "MenuDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Menu", @WndProc )
    Menu.Attach( BuildMenu(), hWin )
    pWindow.SetClientSize( 400, 200 )
    pWindow.Center()
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            dim id as long = CBCTL( wParam, lParam )
            select case id
                case IDM_STATUSBAR, IDM_WORDWRAP
                    dim hMenu as HMENU = Menu.GetHandle( hwnd )
                    dim onOff as ustring
                    if Menu.GetState( hMenu, id ) and MFS_CHECKED then
                        Menu.UncheckItem( hMenu, id )
                        onOff = "off"
                    else
                        Menu.CheckItem( hMenu, id )
                        onOff = "on"
                    end if
                    SetWindowText( hwnd, Menu.GetItemText( hMenu, id ) & " is now " & onOff )
                case IDM_ABOUT
                    SetWindowText( hwnd, "A menu demo" )
                case IDM_EXIT
                    SendMessageW( hwnd, WM_CLOSE, 0, 0 )
            end select
            return 0
        case WM_CONTEXTMENU
            dim hPopup as HMENU = Menu.CreatePopup()
            Menu.AppendItem( hPopup, MF_ENABLED, IDM_COPY, "&Copy" )
            Menu.AppendItem( hPopup, MF_GRAYED, IDM_PASTE, "&Paste" )
            dim pt as POINT
            GetCursorPos( @pt )
            dim id as long = Menu.ContextMenu( hwnd, hPopup, pt.x, pt.y, TPM_RETURNCMD or TPM_RIGHTBUTTON )
            if id then SetWindowText( hwnd, "Chose " & Menu.GetItemText( hPopup, id ) )
            Menu.Destroy( hPopup )
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
| [Create](#create) | Creates an empty menu bar. |
| [CreatePopup, NewPopup](#createpopup-newpopup) | Creates an empty drop-down, submenu or shortcut menu. |
| [AppendItem](#appenditem) | Adds an item, separator or submenu at the end of a menu. |
| [AddPopup](#addpopup) | Adds a submenu to a menu, at the end or before an item. |
| [Modify](#modify) | Changes an item's identifier, text and flags. |
| [Load](#load) | Loads a menu from a resource. |
| [LoadIndirect](#loadindirect) | Creates a menu from a template in memory. |
| [Attach, SetMenu](#attach-setmenu) | Gives a window a menu bar. |
| [GetHandle](#gethandle) | Returns a window's menu bar. |
| [DrawBar](#drawbar) | Redraws a window's menu bar. |
| [Destroy](#destroy) | Destroys a menu, or the menu bar of a window. |
| [OwnerWindow](#ownerwindow) | Returns the top-level window whose menu bar a menu is. |
| [IsMenu, IsMenuHandle](#ismenu-ismenuhandle) | Tells whether a handle is a menu. |
| [GetItemCount](#getitemcount) | Returns the number of items in a menu. |
| [GetSubMenu](#getsubmenu) | Returns the submenu an item opens. |
| [GetSubmenusCount](#getsubmenuscount) | Returns how many items of a menu open submenus. |
| [GetItemID](#getitemid) | Returns the identifier of the item at a position. |
| [FindItemPos](#finditempos) | Finds the menu and position that hold an identifier. |
| [RemoveItem, DeleteItem](#removeitem-deleteitem) | Removes an item, by identifier unless told otherwise. |
| [RemoveMenu, DeleteMenu](#removemenu-deletemenu) | Removes an item, by position unless told otherwise. |
| [GetItemText](#getitemtext) | Returns or reads an item's text. |
| [GetItemTextLen](#getitemtextlen) | Returns the length of an item's text. |
| [SetItemText](#setitemtext) | Changes an item's text. |
| [GetItemState, GetState](#getitemstate-getstate) | Returns an item's `MFS_*` state. |
| [SetItemState, SetState](#setitemstate-setstate) | Sets an item's `MFS_*` state. |
| [EnableItem](#enableitem) | Enables an item. |
| [DisableItem](#disableitem) | Disables and greys an item. |
| [GrayItem](#grayitem) | Disables and greys an item. |
| [HiliteItem](#hiliteitem) | Highlights an item. |
| [CheckItem](#checkitem) | Puts a check mark next to an item. |
| [UncheckItem](#uncheckitem) | Removes an item's check mark. |
| [ToggleItem](#toggleitem) | Checks or unchecks an item, keeping its other state. |
| [ToggleCheckState](#togglecheckstate) | Checks or unchecks an item, replacing its state. |
| [CheckRadioButton](#checkradiobutton) | Checks one item of a group with a radio dot and clears the rest. |
| [IsItemChecked](#isitemchecked) | Tests an item's state for a check mark. |
| [IsItemEnabled](#isitemenabled) | Tells whether an item can be chosen. |
| [IsItemDisabled](#isitemdisabled) | Tests an item's state for `MF_DISABLED`. |
| [IsItemGrayed](#isitemgrayed) | Tests an item's state for `MF_GRAYED`. |
| [IsItemHighlighted](#isitemhighlighted) | Tests an item's state for `MF_HILITE`. |
| [IsItemSeparator](#isitemseparator) | Tests whether an item is a separator. |
| [IsItemPopup](#isitempopup) | Tests whether an item opens a submenu. |
| [IsItemOwnerdraw](#isitemownerdraw) | Tests whether an item is owner-drawn. |
| [SetItemBold, BoldItem](#setitembold-bolditem) | Makes an item the menu's default item, drawn in bold. |
| [SetDefaultItem](#setdefaultitem) | Makes an item the menu's default item. |
| [GetDefaultItem](#getdefaultitem) | Returns the position of a menu's default item, plus one. |
| [RightJustifyItem](#rightjustifyitem) | Moves a menu bar item, and those after it, to the right. |
| [GetItemInfo](#getiteminfo) | Reads an item's attributes into a `MENUITEMINFOW`. |
| [SetItemInfo](#setiteminfo) | Passes a `MENUITEMINFOW` on to Windows to change an item. |
| [GetInfo](#getinfo) | Reads a menu's attributes into a `MENUINFO`. |
| [SetInfo](#setinfo) | Sets a menu's attributes from a `MENUINFO`. |
| [SetContextHelpId](#setcontexthelpid) | Stores a Help context identifier with a menu. |
| [GetContextHelpId](#getcontexthelpid) | Returns a menu's Help context identifier. |
| [ContextMenu](#contextmenu) | Shows a shortcut menu and returns what was chosen. |
| [TrackPopupMenu](#trackpopupmenu) | Shows a shortcut menu. |
| [TrackPopupMenuEx](#trackpopupmenuex) | Shows a shortcut menu that keeps clear of a rectangle. |
| [GetItemRect](#getitemrect) | Returns the screen rectangle of a menu item. |
| [GetRect](#getrect) | Returns the union of a menu's item rectangles after the first. |
| [GetBarInfo](#getbarinfo) | Reads the rectangle and state of a menu bar, a menu or an item. |
| [GetItemFromPoint](#getitemfrompoint) | Returns the position of the item under a screen point. |
| [GetCheckMarkWidth](#getcheckmarkwidth) | Returns the width of the default check mark. |
| [GetCheckMarkHeight](#getcheckmarkheight) | Returns the height of the default check mark. |
| [GetFont](#getfont) | Returns the font Windows uses for menus. |
| [GetFontPointSize](#getfontpointsize) | Returns the point size of the menu font. |
| [GetSystemMenuHandle](#getsystemmenuhandle) | Returns, or resets, a window's system menu. |
| [RemoveCloseOption](#removecloseoption) | Removes Close from the system menu and greys the X button. |
| [RestoreCloseOption](#restorecloseoption) | Puts the system menu back as Windows made it. |
| [SetItemBitmaps](#setitembitmaps) | Replaces an item's check-mark images. |
| [AddIconToItem](#addicontoitem) | Shows an icon next to an item. |
| [AddBitmapToItem](#addbitmaptoitem) | Shows a bitmap next to an item. |
| [DestroyBitmaps](#destroybitmaps) | Deletes the item bitmaps of a menu and its submenus. |
| [Create32BitHBITMAP](#create32bithbitmap) | Creates a 32-bit DIB section. |
| [InitBitmapInfo](#initbitmapinfo) | Fills a `BITMAPINFO` for an uncompressed bitmap. |
| [HasAlpha](#hasalpha) | Tells whether a block of 32-bit pixels uses the alpha byte. |
| [ConvertToPARGB32](#converttopargb32) | Gives 32-bit pixels alpha from an icon mask. |
| [ConvertBufferToPARGB32](#convertbuffertopargb32) | Gives a buffered-paint buffer alpha from an icon mask. |

## Reference

### Create

```freebasic
function Create() as HMENU
```

Creates an empty menu bar. Add drop-downs to it with [AddPopup](#addpopup) or
[AppendItem](#appenditem) and give it to a window with [Attach](#attach-setmenu).

**Returns** the menu, or `NULL` on failure.

**Example**

```freebasic
dim hMenu as HMENU = Menu.Create()
Menu.Attach( hMenu, hwnd )
```

Microsoft Learn: [CreateMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createmenu)

### CreatePopup, NewPopup

```freebasic
function CreatePopup() as HMENU
function NewPopup() as HMENU
```

Create an empty menu for use as a drop-down of a menu bar, a submenu or a shortcut menu. The
two names do the same thing.

**Returns** the menu, or `NULL` on failure.

**Example**

```freebasic
dim hFile as HMENU = Menu.CreatePopup()
Menu.AppendItem( hFile, MF_ENABLED, 1001, "&Open" )
dim hEdit as HMENU = Menu.NewPopup()
```

Microsoft Learn: [CreatePopupMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createpopupmenu)

### AppendItem

```freebasic
function AppendItem( byval hMenu as HMENU, byval uFlags as UINT, byval uIDNewItem as UINT_PTR, byval pwszNewItem as wstring ptr ) as boolean
```

Adds an item at the end of a menu. A tab character in the text (`chr( 9 )`) starts a second,
right-aligned column, the place for a shortcut key; `&` marks the access key.

| Parameter | Meaning |
| --- | --- |
| `hMenu` | The menu bar, drop-down or shortcut menu. |
| `uFlags` | `MF_*` flags: `MF_ENABLED`, `MF_GRAYED`, `MF_CHECKED`, `MF_SEPARATOR` for a separator line, `MF_POPUP` for an item that opens a submenu, `MF_MENUBREAK` to start a new column. |
| `uIDNewItem` | The command identifier; with `MF_POPUP`, the submenu's handle cast to `UINT_PTR`. |
| `pwszNewItem` | The text; ignored for a separator. |

**Returns** `true` on success.

**Example**

```freebasic
dim hFile as HMENU = Menu.CreatePopup()
Menu.AppendItem( hFile, MF_ENABLED, 1001, "&Open..." & chr( 9 ) & "Ctrl+O" )
Menu.AppendItem( hFile, MF_SEPARATOR, 0, "" )
Menu.AppendItem( Menu.GetHandle( hwnd ), MF_POPUP or MF_ENABLED, cast( UINT_PTR, hFile ), "&File" )
Menu.DrawBar( hwnd )
```

Microsoft Learn: [AppendMenuW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-appendmenuw)

### AddPopup

```freebasic
function AddPopup( byval hMenu as HMENU, byval hPopup as HMENU, byval fState as UINT, byval item as long, byref wszText as wstring, byval fByPosition as boolean = false ) as boolean
```

Adds an item with the text `wszText` that opens the submenu `hPopup`.

With `item = 0` the item goes at the end of the menu, with the `MF_*` flags in `fState`, and the
result is that of [AppendItem](#appenditem). With any other `item` it is inserted **before** an
existing item: the one at position `item` when `fByPosition` is `true`, or the one with the
identifier `item` otherwise (at the end when there is no such item), and in that last case the
new item also takes `item` as its own identifier.

The submenu becomes part of the menu and is destroyed with it.

| Parameter | Meaning |
| --- | --- |
| `hMenu` | The menu to add to. |
| `hPopup` | The submenu, from [CreatePopup](#createpopup-newpopup). |
| `fState` | `MF_*` flags for an appended item, such as `MF_ENABLED` or `MF_GRAYED`. |
| `item` | 0 to append, otherwise the item to insert before. |
| `wszText` | The item's text. |
| `fByPosition` | Whether a nonzero `item` is a position (`true`) or an identifier (`false`). |

**Returns** `true` when an item was appended; `false` on failure and after an insertion.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
dim hView as HMENU = Menu.CreatePopup()
Menu.AppendItem( hView, MF_ENABLED, 2001, "&Toolbar" )
Menu.AddPopup( hMenu, hView, MF_ENABLED, 0, "&View" )
Menu.AddPopup( hMenu, Menu.CreatePopup(), 0, 1, "&Edit", true )   ' before position 1
```

Microsoft Learn: [InsertMenuItemW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-insertmenuitemw)

### Modify

```freebasic
function Modify( byval hMenu as HMENU, byval uPosition as UINT, byval uFlags as UINT, byval uIDNewItem as UINT_PTR, byval pNewItem as wstring ptr ) as boolean
```

Replaces an item's flags, identifier and text in one call. Put `MF_BYCOMMAND` or
`MF_BYPOSITION` in `uFlags` to say what `uPosition` is. The menu bar is not redrawn.

| Parameter | Meaning |
| --- | --- |
| `uPosition` | The item, as an identifier or a position. |
| `uFlags` | `MF_BYCOMMAND` or `MF_BYPOSITION`, plus the `MF_*` flags the item gets. |
| `uIDNewItem` | The new identifier, or a submenu handle with `MF_POPUP`. |
| `pNewItem` | The new text. |

**Returns** `true` on success.

**Example**

```freebasic
dim hFile as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 )
Menu.Modify( hFile, 0, MF_BYPOSITION or MF_STRING, 1010, "Sa&ve all" )
```

Microsoft Learn: [ModifyMenuW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-modifymenuw)

### Load

```freebasic
function Load( byval hInst as HINSTANCE, byval pMenuName as wstring ptr ) as HMENU
```

Loads a `MENU` resource from a module. Name it by its resource name, or by a number with
`MAKEINTRESOURCEW`. A loaded menu that is never attached to a window must be destroyed.

**Returns** the menu, or `NULL` when there is no such resource.

**Example**

```freebasic
dim hMenu as HMENU = Menu.Load( GetModuleHandleW( NULL ), "MAINMENU" )
if hMenu then Menu.Attach( hMenu, hwnd )
```

Microsoft Learn: [LoadMenuW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadmenuw)

### LoadIndirect

```freebasic
function LoadIndirect( byval pMenuTemplate as MENUTEMPLATEW ptr ) as HMENU
```

Creates a menu from a menu template held in memory, the binary layout a `MENU` resource has.
The pointer must not be `NULL`.

**Returns** the menu, or `NULL` on failure.

**Example**

```freebasic
dim hRes as HRSRC = FindResourceW( NULL, "MAINMENU", cast( wstring ptr, RT_MENU ) )
if hRes then
    dim hMenu as HMENU = Menu.LoadIndirect( LockResource( LoadResource( NULL, hRes ) ) )
end if
```

Microsoft Learn: [LoadMenuIndirectW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadmenuindirectw)

### Attach, SetMenu

```freebasic
function Attach( byval hMenu as HMENU, byval hwnd as HWND ) as boolean
function SetMenu( byval hwnd as HWND, byval hMenu as HMENU ) as boolean
```

Make `hMenu` the menu bar of `hwnd` and redraw it. The two do the same thing with the arguments
in a different order. `NULL` removes the bar. The bar the window had before is not destroyed;
destroy it yourself if nothing else uses it.

**Returns** `true` on success.

**Example**

```freebasic
dim hOld as HMENU = Menu.GetHandle( hwnd )
Menu.Attach( Menu.Create(), hwnd )
Menu.Destroy( hOld )
Menu.SetMenu( hwnd, NULL )   ' no menu bar
```

Microsoft Learn: [SetMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setmenu)

### GetHandle

```freebasic
function GetHandle( byval hwnd as HWND ) as HMENU
```

Returns the menu bar of a window.

**Returns** the menu, or `NULL` when the window has none.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
print "items on the bar:"; Menu.GetItemCount( hMenu )
```

Microsoft Learn: [GetMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenu)

### DrawBar

```freebasic
function DrawBar( byval hwnd as HWND ) as boolean
```

Redraws the menu bar of a window. Call it after changing the bar with a function that does not
redraw (see the introduction).

**Returns** `true` on success.

**Example**

```freebasic
Menu.CheckItem( Menu.GetHandle( hwnd ), 0, true )
Menu.DrawBar( hwnd )
```

Microsoft Learn: [DrawMenuBar](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-drawmenubar)

### Destroy

```freebasic
function Destroy overload( byval hMenu as HMENU ) as boolean
function Destroy overload( byval hwnd as HWND ) as boolean
```

The first form destroys a menu and every submenu in it. The second detaches the menu bar from a
window and destroys it; the window is left without a bar and is not redrawn, so call
[DrawBar](#drawbar) if it is on screen.

**Returns** `true` on success; the second form returns `false` when the window has no menu.

**Example**

```freebasic
dim hPopup as HMENU = Menu.CreatePopup()
Menu.Destroy( hPopup )
Menu.Destroy( hwnd )
Menu.DrawBar( hwnd )
```

Microsoft Learn: [DestroyMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroymenu)

### OwnerWindow

```freebasic
function OwnerWindow( byval hMenu as HMENU ) as HWND
```

Looks through the top-level windows for the one whose menu bar is `hMenu`. A drop-down, a
submenu or a menu not attached to any window has no owner.

**Returns** the window, or `NULL`.

**Example**

```freebasic
dim hOwner as HWND = Menu.OwnerWindow( Menu.GetHandle( hwnd ) )   ' hwnd
```

### IsMenu, IsMenuHandle

```freebasic
function IsMenu( byval hMenu as HMENU ) as boolean
function IsMenuHandle( byval hMenu as HMENU ) as boolean
```

Tell whether a handle is a menu that still exists. The two names do the same thing.

**Returns** `true` for a menu.

**Example**

```freebasic
dim hPopup as HMENU = Menu.CreatePopup()
Menu.Destroy( hPopup )
print Menu.IsMenu( hPopup )   ' false
```

Microsoft Learn: [IsMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-ismenu)

### GetItemCount

```freebasic
function GetItemCount( byval hMenu as HMENU ) as long
```

Returns the number of items in a menu, separators included. Items of submenus are not counted.

**Returns** the count, or -1 on failure.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
print Menu.GetItemCount( hMenu ); Menu.GetItemCount( Menu.GetSubMenu( hMenu, 0 ) )
```

Microsoft Learn: [GetMenuItemCount](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenuitemcount)

### GetSubMenu

```freebasic
function GetSubMenu( byval hMenu as HMENU, byval nPos as long ) as HMENU
```

Returns the drop-down or submenu that the item at zero-based position `nPos` opens.

**Returns** the submenu, or `NULL` when the item opens none.

**Example**

```freebasic
dim hFile as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 )
```

Microsoft Learn: [GetSubMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsubmenu)

### GetSubmenusCount

```freebasic
function GetSubmenusCount( byval hMenu as HMENU ) as long
```

Counts the items of a menu that open a submenu. Submenus of submenus are not counted.

**Returns** the count.

**Example**

```freebasic
print "drop-downs on the bar:"; Menu.GetSubmenusCount( Menu.GetHandle( hwnd ) )
```

### GetItemID

```freebasic
function GetItemID overload( byval hMenu as HMENU, byval nPos as long ) as long
function GetItemID overload( byval hMenu as HMENU, byval submenu as long, byval nPos as long ) as long
```

Returns the command identifier of the item at zero-based position `nPos`. The second form looks
in the submenu opened by the item at position `submenu` of `hMenu`.

**Returns** the identifier; -1 for an item that opens a submenu or when there is no such item,
and 0 for a separator.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
print Menu.GetItemID( Menu.GetSubMenu( hMenu, 0 ), 1 )
print Menu.GetItemID( hMenu, 0, 1 )   ' the same item
```

Microsoft Learn: [GetMenuItemID](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenuitemid)

### FindItemPos

```freebasic
function FindItemPos( byval hMenu as HMENU, byval itemID as UINT, byref hMenuFound as HMENU, byref itemPos as long ) as boolean
```

Searches `hMenu`, then its submenus at every depth, for the item with the identifier `itemID`,
and reports which menu holds it and at what position. Use it to turn an identifier into the
position that functions taking `fByPosition = true` need.

| Parameter | Meaning |
| --- | --- |
| `hMenu` | The menu to search. |
| `itemID` | The command identifier. |
| `hMenuFound` | Receives the menu that holds the item. |
| `itemPos` | Receives the item's zero-based position in that menu. |

**Returns** `true` when the item was found; otherwise `false` and the two outputs are unchanged.

**Example**

```freebasic
dim hFound as HMENU, itemPos as long
if Menu.FindItemPos( Menu.GetHandle( hwnd ), 1002, hFound, itemPos ) then
    Menu.RemoveItem( hFound, itemPos, true )
end if
```

### RemoveItem, DeleteItem

```freebasic
function RemoveItem( byval hMenu as HMENU, byval item as long, byval fByPosition as boolean = false ) as boolean
function DeleteItem( byval hMenu as HMENU, byval item as long, byval fByPosition as boolean = false ) as boolean
```

Remove an item from a menu, by identifier unless `fByPosition` is `true`. The two names do the
same thing. When the item opens a submenu, the submenu is detached, not destroyed: keep its
handle (from [GetSubMenu](#getsubmenu)) to reuse it or destroy it.

**Returns** `true` on success, `false` when there is no such item.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
Menu.RemoveItem( hMenu, 1002 )           ' by identifier, in any drop-down
Menu.DeleteItem( hMenu, 1, true )        ' the second item of the bar
```

Microsoft Learn: [RemoveMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-removemenu)

### RemoveMenu, DeleteMenu

```freebasic
function RemoveMenu( byval hMenu as HMENU, byval uPositiom as DWORD, byval fByPosition as boolean = true ) as boolean
function DeleteMenu( byval hMenu as HMENU, byval uPositiom as DWORD, byval fByPosition as boolean = true ) as boolean
```

The same as [RemoveItem](#removeitem-deleteitem), but `uPositiom` is a position unless
`fByPosition` is `false`: the form for taking a whole drop-down off a menu bar. Both names
detach a submenu without destroying it, `DeleteMenu` included.

**Returns** `true` on success.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
dim hView as HMENU = Menu.GetSubMenu( hMenu, 1 )
Menu.RemoveMenu( hMenu, 1 )
Menu.Destroy( hView )
```

Microsoft Learn: [RemoveMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-removemenu)

### GetItemText

```freebasic
function GetItemText overload( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long, byval pwszText as wstring ptr, byval cchTextMax as long ) as boolean
function GetItemText overload( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as ustring
```

Returns an item's text, with its `&` and any tab and shortcut text. The second form returns at
most 259 characters; the first copies into a buffer of `cchTextMax` characters, terminator
included.

**Returns** the text, or `""` on failure; the first form `true` on success and `false` on
failure or for a `NULL` buffer.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
print Menu.GetItemText( hMenu, 0, true )   ' "&File"
dim wszText as wstring * 64
Menu.GetItemText( hMenu, 1001, false, @wszText, 64 )
```

Microsoft Learn: [GetMenuItemInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenuiteminfow)

### GetItemTextLen

```freebasic
function GetItemTextLen( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as long
```

Returns the length of an item's text in characters, without the terminator: 5 for `"&Open"`.

**Returns** the length, or 0 on failure.

**Example**

```freebasic
dim n as long = Menu.GetItemTextLen( Menu.GetHandle( hwnd ), 1001 )
```

### SetItemText

```freebasic
function SetItemText( byval hMenu as HMENU, byval uItem as DWORD, byref wszText as wstring, byval fByPosition as long = false ) as boolean
```

Replaces an item's text. The menu keeps its own copy.

**Returns** `true` on success.

**Example**

```freebasic
Menu.SetItemText( Menu.GetHandle( hwnd ), 1001, "&Open..." & chr( 9 ) & "Ctrl+O" )
```

Microsoft Learn: [SetMenuItemInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setmenuiteminfow)

### GetItemState, GetState

```freebasic
function GetItemState( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as DWORD
function GetState( byval hMenu as HMENU, byval item as long, byval fByPosition as boolean = false ) as UINT
```

Return an item's state as `MFS_*` bits: `MFS_CHECKED` (8), `MFS_GRAYED` (3, the same value as
`MFS_DISABLED`), `MFS_HILITE` (&h80) and `MFS_DEFAULT` (&h1000). An enabled, unchecked item is
0. The two names do the same thing. Test a bit with `and`, which is the reliable way to ask
whether an item is checked.

**Returns** the state, or 0 on failure (see `GetLastError()`).

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
if Menu.GetState( hMenu, 1001 ) and MFS_CHECKED then print "checked"
print hex( Menu.GetItemState( hMenu, 0, true ) )
```

Microsoft Learn: [MENUITEMINFOW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-menuiteminfow)

### SetItemState, SetState

```freebasic
function SetItemState( byval hMenu as HMENU, byval uItem as DWORD, byval fState as DWORD, byval fByPosition as long = false ) as boolean
function SetState( byval hMenu as HMENU, byval item as long, byval fState as UINT, byval fByPosition as boolean = false ) as boolean
```

Set an item's state to `fState`, a combination of `MFS_*` values. The check mark and the
greyed state become what `fState` says, so a check mark the item had is cleared unless `fState`
includes `MFS_CHECKED`; the default and highlighted states are kept. The two names do the same
thing.

**Returns** `true` on success.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
Menu.SetState( hMenu, 1001, MFS_CHECKED or MFS_GRAYED )
Menu.SetItemState( hMenu, 1001, MFS_ENABLED )
```

Microsoft Learn: [SetMenuItemInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setmenuiteminfow)

### EnableItem

```freebasic
function EnableItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Enables an item: [SetState](#setitemstate-setstate) with `MFS_ENABLED`. That also clears its
check mark; check it again afterwards if it should keep one.

**Returns** `true` on success.

**Example**

```freebasic
Menu.EnableItem( Menu.GetHandle( hwnd ), 1002 )
```

### DisableItem

```freebasic
function DisableItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Disables an item so it cannot be chosen: [SetState](#setitemstate-setstate) with `MFS_DISABLED`,
which Windows draws grey. It does the same as [GrayItem](#grayitem) and also clears the check
mark.

**Returns** `true` on success.

**Example**

```freebasic
Menu.DisableItem( Menu.GetHandle( hwnd ), 1002 )
```

### GrayItem

```freebasic
function GrayItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Disables an item and draws it grey: [SetState](#setitemstate-setstate) with `MFS_GRAYED`. It
also clears the check mark.

**Returns** `true` on success.

**Example**

```freebasic
Menu.GrayItem( Menu.GetHandle( hwnd ), 1002 )
```

### HiliteItem

```freebasic
function HiliteItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Draws an item highlighted, as if the mouse were on it: [SetState](#setitemstate-setstate) with
`MFS_HILITE`, so it also clears the check mark and the greyed state.

**Returns** `true` on success.

**Example**

```freebasic
Menu.HiliteItem( Menu.GetHandle( hwnd ), 0, true )
```

### CheckItem

```freebasic
function CheckItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as long
```

Puts a check mark next to an item. Its other state is unchanged.

**Returns** the previous check state, `MF_CHECKED` (8) or `MF_UNCHECKED` (0), or -1 when there
is no such item.

**Example**

```freebasic
Menu.CheckItem( Menu.GetHandle( hwnd ), 2001 )
dim hFile as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 )
Menu.CheckItem( hFile, 1, true )
```

Microsoft Learn: [CheckMenuItem](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-checkmenuitem)

### UncheckItem

```freebasic
function UncheckItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as DWORD
```

Removes an item's check mark. Its other state is unchanged.

**Returns** the previous check state, `MF_CHECKED` or `MF_UNCHECKED`, or `&hFFFFFFFF` when there
is no such item.

**Example**

```freebasic
Menu.UncheckItem( Menu.GetHandle( hwnd ), 2001 )
```

Microsoft Learn: [CheckMenuItem](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-checkmenuitem)

### ToggleItem

```freebasic
function ToggleItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as long
```

Checks or unchecks an item, keeping the rest of its state.

**Returns** the previous check state, as [CheckItem](#checkitem), or -1 when there is no such
item.

**Example**

```freebasic
Menu.ToggleItem( Menu.GetHandle( hwnd ), 2001 )
```

### ToggleCheckState

```freebasic
function ToggleCheckState( byval hMenu as HMENU, byval item as long, byval fByPosition as boolean = false ) as boolean
```

Checks or unchecks an item, deciding as [ToggleItem](#toggleitem) does; it redraws the bar.

**Returns** `true` on success.

**Example**

```freebasic
Menu.ToggleCheckState( Menu.GetHandle( hwnd ), 2001 )
```

### CheckRadioButton

```freebasic
function CheckRadioButton( byval hMenu as HMENU, byval first as long, byval last as long, byval check as long, byval fByPosition as boolean = false ) as boolean
```

Treats the items from `first` to `last` as a group of options: `check` gets a round radio mark
and the others in the range lose theirs. With `fByPosition = false` the three are identifiers
and the items must be in one menu.

**Returns** `true` on success.

**Example**

```freebasic
dim hView as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 1 )
Menu.CheckRadioButton( hView, 0, 2, 1, true )   ' the second of three
```

Microsoft Learn: [CheckMenuRadioItem](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-checkmenuradioitem)

### IsItemChecked

```freebasic
function IsItemChecked( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Tests an item's state for a check mark.

**Returns** `true` if the item is checked; `false` otherwise.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
if Menu.IsItemChecked( hMenu, 2001 ) then print "on"
```

Microsoft Learn: [GetMenuState](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenustate)

### IsItemEnabled

```freebasic
function IsItemEnabled( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Tells whether an item can be chosen: neither disabled nor greyed.

**Returns** `true` for an enabled item; `false` for a disabled or greyed one, or when there is
no such item.

**Example**

```freebasic
if Menu.IsItemEnabled( Menu.GetHandle( hwnd ), 1002 ) = false then print "Save is off"
```

### IsItemDisabled

```freebasic
function IsItemDisabled( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Tests an item's state for the `MF_DISABLED` bit. An item made with [DisableItem](#disableitem)
or [GrayItem](#grayitem) has it; one added with `MF_GRAYED` alone does not. Use
[IsItemEnabled](#isitemenabled) to ask whether an item can be chosen.

**Returns** `true` when the bit is set or there is no such item.

**Example**

```freebasic
print Menu.IsItemDisabled( Menu.GetHandle( hwnd ), 1002 )
```

### IsItemGrayed

```freebasic
function IsItemGrayed( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Tests an item's state for the `MF_GRAYED` bit, which every greyed or disabled item made by this
namespace has.

**Returns** `true` when the bit is set or there is no such item.

**Example**

```freebasic
print Menu.IsItemGrayed( Menu.GetHandle( hwnd ), 1002 )
```

### IsItemHighlighted

```freebasic
function IsItemHighlighted( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Tests an item's state for `MF_HILITE`.

**Returns** `true` when the item is highlighted or there is no such item.

**Example**

```freebasic
print Menu.IsItemHighlighted( Menu.GetHandle( hwnd ), 0, true )
```

### IsItemSeparator

```freebasic
function IsItemSeparator( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Tells whether an item is a separator line. Separators have no identifier, so ask by position.

**Returns** `true` for a separator or when there is no such item.

**Example**

```freebasic
dim hFile as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 )
print Menu.IsItemSeparator( hFile, 1, true )
```

### IsItemPopup

```freebasic
function IsItemPopup( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Tells whether an item opens a submenu.

**Returns** `true` when it does or when there is no such item.

**Example**

```freebasic
print Menu.IsItemPopup( Menu.GetHandle( hwnd ), 0, true )   ' File: true
```

### IsItemOwnerdraw

```freebasic
function IsItemOwnerdraw( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Tells whether an item is drawn by its window (`MF_OWNERDRAW`), through `WM_MEASUREITEM` and
`WM_DRAWITEM`.

**Returns** `true` when it is or when there is no such item.

**Example**

```freebasic
print Menu.IsItemOwnerdraw( Menu.GetHandle( hwnd ), 1001 )
```

### SetItemBold, BoldItem

```freebasic
function SetItemBold( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
function BoldItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as long = false ) as boolean
```

Add `MFS_DEFAULT` to an item's state, keeping the rest. Windows draws the default item in bold;
a menu has one default item, so this takes the mark off any other. The two names do the same
thing.

**Returns** `true` on success.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
Menu.SetItemBold( hMenu, 1003 )
Menu.BoldItem( Menu.GetSubMenu( hMenu, 0 ), 0, true )
```

### SetDefaultItem

```freebasic
function SetDefaultItem( byval hMenu as HMENU, byval item as long, byval fByPosition as boolean = true ) as boolean
```

Makes an item the default item of its menu (bold, and the one a double-click on a system menu
chooses). `item` is a position unless `fByPosition` is `false`; -1 removes the default.

**Returns** `true` on success.

**Example**

```freebasic
dim hFile as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 )
Menu.SetDefaultItem( hFile, 0 )
Menu.SetDefaultItem( hFile, -1 )   ' none
```

Microsoft Learn: [SetMenuDefaultItem](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setmenudefaultitem)

### GetDefaultItem

```freebasic
function GetDefaultItem( byval hMenu as HMENU, byval gmdiFlags as UINT = 0, byval fByPosition as boolean = true ) as long
```

Finds the default item of a menu and returns its **position plus one**, so the first item gives
1 and a menu with no default gives 0. The result is a position whatever `fByPosition` says.
`gmdiFlags = 0` stands for `GMDI_GOINTOPOPUPS`. When `fByPosition` is `true` (the default),
disabled default items are found too.

**Returns** the position of the default item plus one, or 0 when there is none.

**Example**

```freebasic
dim hFile as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 )
Menu.SetDefaultItem( hFile, 0 )
print Menu.GetDefaultItem( hFile )   ' 1
```

Microsoft Learn: [GetMenuDefaultItem](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenudefaultitem)

### RightJustifyItem

```freebasic
function RightJustifyItem( byval hMenu as HMENU, byval uItem as DWORD ) as boolean
```

Moves the menu bar item at zero-based position `uItem`, and every item after it, to the right
end of the bar: the traditional place for Help.

**Returns** `true` on success.

**Example**

```freebasic
dim hMenu as HMENU = Menu.GetHandle( hwnd )
Menu.RightJustifyItem( hMenu, Menu.GetItemCount( hMenu ) - 1 )
```

Microsoft Learn: [MENUITEMINFOW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-menuiteminfow) (`MFT_RIGHTJUSTIFY`)

### GetItemInfo

```freebasic
function GetItemInfo overload( byval hMenu as HMENU, byval item as UINT, byval fByPositon as boolean, byval pmii as MENUITEMINFOW ptr ) as boolean
function GetItemInfo overload( byval hMenu as HMENU, byval item as UINT, byval fByPositon as boolean, byref mii as MENUITEMINFOW ) as boolean
```

Reads the attributes of an item named in `fMask` into a `MENUITEMINFOW`. `cbSize` is filled in
for you; set `fMask` (`MIIM_STATE`, `MIIM_ID`, `MIIM_SUBMENU`, `MIIM_FTYPE`, `MIIM_STRING` …)
and, for the text, `dwTypeData` and `cch`.

**Returns** `true` on success; `false` on failure or for a `NULL` pointer.

**Example**

```freebasic
dim mii as MENUITEMINFOW
mii.fMask = MIIM_ID or MIIM_SUBMENU
if Menu.GetItemInfo( Menu.GetHandle( hwnd ), 0, true, mii ) then print mii.wID; mii.hSubMenu
```

Microsoft Learn: [GetMenuItemInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenuiteminfow)

### SetItemInfo

```freebasic
function SetItemInfo overload( byval hMenu as HMENU, byval item as UINT, byval fByPositon as boolean, byval pmii as MENUITEMINFOW ptr ) as boolean
function SetItemInfo overload( byval hMenu as HMENU, byval item as UINT, byval fByPositon as boolean, byref mii as MENUITEMINFOW ) as boolean
```

**Returns** `true`, on success; `false`otherwise.

**Example**

```freebasic
Menu.SetMenuItemInfoW( Menu.GetHandle( hwnd ), 1003, false, @mii )
```

Microsoft Learn: [SetMenuItemInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setmenuiteminfow)

### GetInfo

```freebasic
function GetInfo overload( byval hMenu as HMENU, byval pmi as MENUINFO ptr ) as boolean
function GetInfo overload( byval hMenu as HMENU, byref mi as MENUINFO ) as boolean
```

Reads the attributes of a whole menu named in `fMask` (`MIM_STYLE`, `MIM_BACKGROUND`,
`MIM_HELPID`, `MIM_MAXHEIGHT`, `MIM_MENUDATA`) into a `MENUINFO`. `cbSize` is filled in for
you.

**Returns** `true` on success; `false` on failure or for a `NULL` pointer.

**Example**

```freebasic
dim mi as MENUINFO
mi.fMask = MIM_STYLE or MIM_HELPID
if Menu.GetInfo( Menu.GetHandle( hwnd ), mi ) then print hex( mi.dwStyle ); mi.dwContextHelpID
```

Microsoft Learn: [GetMenuInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenuinfo)

### SetInfo

```freebasic
function SetInfo overload( byval hMenu as HMENU, byval pmi as MENUINFO ptr ) as boolean
function SetInfo overload( byval hMenu as HMENU, byref mi as MENUINFO ) as boolean
```

Sets the attributes of a whole menu named in `fMask`: a background brush, a maximum height
after which it scrolls, a style such as `MNS_NOTIFYBYPOS` or `MNS_CHECKORBMP`, and so on. Add
`MIM_APPLYTOSUBMENUS` to `fMask` to change the submenus as well. `cbSize` is filled in for you.

**Returns** `true` on success; `false` on failure or for a `NULL` pointer.

**Example**

```freebasic
dim mi as MENUINFO
mi.fMask = MIM_MAXHEIGHT
mi.cyMax = 300
Menu.SetInfo( Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 ), mi )
```

Microsoft Learn: [SetMenuInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setmenuinfo)

### SetContextHelpId

```freebasic
function SetContextHelpId( byval hMenu as HMENU, byval helpID as DWORD ) as boolean
```

Stores a Help context identifier with a menu, for a Help system to look up when the user asks
for help on it.

**Returns** `true` on success.

**Example**

```freebasic
Menu.SetContextHelpId( Menu.GetHandle( hwnd ), 77 )
```

Microsoft Learn: [SetMenuContextHelpId](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setmenucontexthelpid)

### GetContextHelpId

```freebasic
function GetContextHelpId( byval hMenu as HMENU ) as DWORD
```

Returns the Help context identifier stored with [SetContextHelpId](#setcontexthelpid).

**Returns** the identifier, or 0 when there is none.

**Example**

```freebasic
print Menu.GetContextHelpId( Menu.GetHandle( hwnd ) )   ' 77 after the call above
```

Microsoft Learn: [GetMenuContextHelpId](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenucontexthelpid)

### ContextMenu

```freebasic
function ContextMenu( byval hwnd as HWND, byval hPopupMenu as HMENU, byval x as long, byval y as long, byval flags as UINT = 0 ) as long
```

Shows `hPopupMenu` as a floating shortcut menu at the screen point (`x`, `y`) and waits until
the user chooses an item or dismisses it. The usual place is `WM_CONTEXTMENU`.

With `TPM_RETURNCMD` in `flags` the chosen identifier is returned and no `WM_COMMAND` is sent;
without it the window gets `WM_COMMAND` as for a menu bar item. The menu is not destroyed:
destroy a menu built for the occasion afterwards.

| Parameter | Meaning |
| --- | --- |
| `hwnd` | The window that owns the menu and receives its messages. |
| `hPopupMenu` | A menu from [CreatePopup](#createpopup-newpopup), or a drop-down from [GetSubMenu](#getsubmenu). |
| `x`, `y` | The position in screen coordinates. |
| `flags` | `TPM_*` flags: alignment (`TPM_LEFTALIGN`, `TPM_CENTERALIGN`, `TPM_RIGHTALIGN`, `TPM_TOPALIGN`, `TPM_BOTTOMALIGN` …), `TPM_RIGHTBUTTON` to allow choosing with the right button, `TPM_RETURNCMD`, `TPM_NONOTIFY`. |

**Returns** with `TPM_RETURNCMD`, the chosen identifier or 0 when the menu was dismissed;
otherwise nonzero on success.

**Example**

```freebasic
dim hPopup as HMENU = Menu.CreatePopup()
Menu.AppendItem( hPopup, MF_ENABLED, 3001, "&Copy" )
dim pt as POINT : GetCursorPos( @pt )
dim id as long = Menu.ContextMenu( hwnd, hPopup, pt.x, pt.y, TPM_RETURNCMD )
Menu.Destroy( hPopup )
```

Microsoft Learn: [TrackPopupMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-trackpopupmenu)

### TrackPopupMenu

```freebasic
function TrackPopupMenu( byval hMenu as HMENU, byval uFlags as UINT, byval x as long, byval y as long, byval hwnd as HWND, byval prc as RECT ptr = NULL ) as long
```

Shows a shortcut menu like [ContextMenu](#contextmenu), with the Windows argument order.
`prc` is ignored by Windows.

**Example**

```freebasic
dim hView as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 1 )
dim pt as POINT : GetCursorPos( @pt )
Menu.TrackPopupMenu( hView, TPM_LEFTALIGN or TPM_RIGHTBUTTON, pt.x, pt.y, hwnd )
```

Microsoft Learn: [TrackPopupMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-trackpopupmenu)

### TrackPopupMenuEx

```freebasic
function TrackPopupMenuEx( byval hMenu as HMENU, byval uFlags as UINT, byval x as long, byval y as long, byval hwnd as HWND, byval ptpm as TPMPARAMS ptr = NULL ) as long
```

Shows a shortcut menu like [TrackPopupMenu](#trackpopupmenu), and keeps it clear of the
rectangle in `ptpm` (for instance the button that opened it).

**Example**

```freebasic
dim tpm as TPMPARAMS
tpm.cbSize = sizeof( TPMPARAMS )
GetWindowRect( hCtrl, @tpm.rcExclude )
Menu.TrackPopupMenuEx( Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 ), TPM_VERTICAL, tpm.rcExclude.left, tpm.rcExclude.bottom, hwnd, @tpm )
```

Microsoft Learn: [TrackPopupMenuEx](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-trackpopupmenuex)

### GetItemRect

```freebasic
function GetItemRect overload( byval hwnd as HWND, byval hmenu as HMENU, byval uItem as UINT, byval prcItem as RECT ptr ) as boolean
function GetItemRect overload( byval hwnd as HWND, byval hmenu as HMENU, byval uItem as UINT, byref rcItem as RECT ) as boolean
function GetItemRect overload( byval hwnd as HWND, byval hmenu as HMENU, byval uItem as UINT ) as ( long, long, long, long )
```

Returns the rectangle of the item at zero-based position `uItem`, in screen coordinates. For a
menu bar item pass the window and its bar; for a drop-down item, which has a rectangle only
while the drop-down is open, `hwnd` may be `NULL`.

**Returns** `true` on success; the third form returns `( left, top, right, bottom )`, and
`GetLastError()` is nonzero afterwards when the call succeeded and 0 when it failed.

**Example**

```freebasic
var (l, t, r, b) = Menu.GetItemRect( hwnd, Menu.GetHandle( hwnd ), 0 )
if GetLastError() then print "File is"; r - l; " x"; b - t
```

Microsoft Learn: [GetMenuItemRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenuitemrect)

### GetRect

```freebasic
function GetRect overload( byval hwnd as HWND, byval hmenu as HMENU, byval prcmenu as RECT ptr ) as long
function GetRect overload( byval hwnd as HWND, byval hmenu as HMENU, byref rcmenu as RECT ) as long
function GetRect overload( byval hwnd as HWND, byval hmenu as HMENU ) as ( long, long, long, long )
```

Joins item rectangles into one, in screen coordinates. It asks for the items at positions 1 to
`GetItemCount`, so the rectangle starts at the **second** item: on a bar with File and Help it
covers Help only. The first two forms add to the rectangle you pass, so set it to zero first.
For the rectangle of a whole menu bar, use [GetBarInfo](#getbarinfo).

**Returns** 0 from the first two forms; the third returns `( left, top, right, bottom )`.

**Example**

```freebasic
var (l, t, r, b) = Menu.GetRect( hwnd, Menu.GetHandle( hwnd ) )
dim rc as RECT
Menu.GetRect( hwnd, Menu.GetHandle( hwnd ), rc )
```

Microsoft Learn: [GetMenuItemRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenuitemrect)

### GetBarInfo

```freebasic
function GetBarInfo overload( byval hwnd as HWND, byval idObject as long, byval idItem as long, byval pmbi as MENUBARINFO ptr ) as boolean
function GetBarInfo overload( byval hwnd as HWND, byval idObject as long, byval idItem as long, byref mbi as MENUBARINFO ) as boolean
function GetBarInfo overload( byval hwnd as HWND, byval idObject as long, byval idItem as long ) as MENUBARINFO
```

Reads the screen rectangle and state of a window's menu bar, system menu or open shortcut menu,
or of one of its items, into a `MENUBARINFO` (`cbSize` is filled in for you).

| Parameter | Meaning |
| --- | --- |
| `hwnd` | The window. |
| `idObject` | `OBJID_MENU` (the menu bar), `OBJID_SYSMENU` (the system menu) or `OBJID_CLIENT` (a shortcut menu open on the window). |
| `idItem` | 0 for the menu itself, 1 for its first item, 2 for the second, and so on. |

**Returns** `true` on success; the third form returns the structure, all zeros on failure.

**Example**

```freebasic
dim mbi as MENUBARINFO = Menu.GetBarInfo( hwnd, OBJID_MENU, 0 )
print "menu bar:"; mbi.rcBar.right - mbi.rcBar.left; " x"; mbi.rcBar.bottom - mbi.rcBar.top
```

Microsoft Learn: [GetMenuBarInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenubarinfo)

### GetItemFromPoint

```freebasic
function GetItemFromPoint overload( byval hwnd as HWND, byval hmenu as HMENU, byval ptScreen as POINT ) as long
function GetItemFromPoint overload( byval hwnd as HWND, byval hmenu as HMENU, byval x as long, byval y as long ) as long
```

Returns the position of the item of `hmenu` at a point in screen coordinates.

**Returns** the zero-based position, or -1 when no item is there.

**Example**

```freebasic
dim pt as POINT : GetCursorPos( @pt )
print Menu.GetItemFromPoint( hwnd, Menu.GetHandle( hwnd ), pt )
print Menu.GetItemFromPoint( hwnd, Menu.GetHandle( hwnd ), pt.x, pt.y )
```

Microsoft Learn: [MenuItemFromPoint](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-menuitemfrompoint)

### GetCheckMarkWidth

```freebasic
function GetCheckMarkWidth() as long
```

Returns the size of the default check mark, the size a bitmap for
[SetItemBitmaps](#setitembitmaps) should have. It reads `SM_CYMENUCHECK`, the height; Windows
makes the check mark square, so the value is the width as well (15 at 96 DPI).

**Returns** the size in pixels.

**Example**

```freebasic
dim cx as long = Menu.GetCheckMarkWidth()
```

Microsoft Learn: [GetSystemMetrics](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmetrics)

### GetCheckMarkHeight

```freebasic
function GetCheckMarkHeight() as long
```

Returns the size of the default check mark from `SM_CXMENUCHECK`, the width; see
[GetCheckMarkWidth](#getcheckmarkwidth).

**Returns** the size in pixels.

**Example**

```freebasic
dim cy as long = Menu.GetCheckMarkHeight()
```

### GetFont

```freebasic
function GetFont overload( byval plfw as LOGFONTW ptr ) as boolean
function GetFont overload() as LOGFONTW
```

Returns the font Windows draws menus with, from the non-client metrics: Segoe UI on a standard
Windows 11 system. Pass the `LOGFONTW` to `CreateFontIndirectW` for a font that matches menus.

**Returns** `true` on success for the first form; the second returns the `LOGFONTW` and leaves
`GetLastError()` nonzero when the call succeeded and 0 when it failed.

**Example**

```freebasic
dim lf as LOGFONTW = Menu.GetFont()
dim hFont as HFONT = CreateFontIndirectW( @lf )
```

Microsoft Learn: [NONCLIENTMETRICSW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-nonclientmetricsw)

### GetFontPointSize

```freebasic
function GetFontPointSize() as long
```

Returns the point size of the menu font: its height converted with the display's vertical DPI
(9 on a standard system).

**Returns** the size in points, or 0 on failure.

**Example**

```freebasic
print "menus use"; Menu.GetFontPointSize(); " pt"
```

### GetSystemMenuHandle

```freebasic
function GetSystemMenuHandle( byval hwnd as HWND, byval bRevert as boolean = false ) as HMENU
```

Returns the window's system menu (the one under the icon and on Alt+Space), which can be
changed like any other menu. With `bRevert = true` the system menu is put back as Windows made
it, and the result is `NULL`.

**Returns** the system menu, or `NULL`.

**Example**

```freebasic
dim hSys as HMENU = Menu.GetSystemMenuHandle( hwnd )
Menu.AppendItem( hSys, MF_ENABLED, 4001, "&Always on top" )   ' arrives as WM_SYSCOMMAND
```

Microsoft Learn: [GetSystemMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmenu)

### RemoveCloseOption

```freebasic
function RemoveCloseOption( byval hwnd as HWND ) as boolean
```

Removes the last two items of the window's system menu, which on a standard window are Close and
the separator above it, and redraws the caption: the X button is greyed.

**Returns** `true` on success.

**Example**

```freebasic
Menu.RemoveCloseOption( hwnd )
```

Microsoft Learn: [RemoveMenu](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-removemenu)

### RestoreCloseOption

```freebasic
function RestoreCloseOption( byval hwnd as HWND ) as boolean
```

Puts the window's system menu back as Windows made it, which brings Close and the X button back
after [RemoveCloseOption](#removecloseoption). Any other change to the system menu is undone
too.

**Returns** `true` on success.

**Example**

```freebasic
Menu.RestoreCloseOption( hwnd )
```

### SetItemBitmaps

```freebasic
function SetItemBitmaps( byval hMenu as HMENU, byval item as long, byval hBitmapUnchecked as HBITMAP, byval hBitmapChecked as HBITMAP, byval fByPosition as boolean = false ) as boolean
```

Replaces the images Windows shows next to an item when it is unchecked and checked. `NULL`
for both puts back the default check mark. The menu does not destroy the bitmaps; delete them
when the menu is gone.

**Returns** `true` on success.

**Example**

```freebasic
Menu.SetItemBitmaps( Menu.GetHandle( hwnd ), 2001, NULL, NULL )
```

Microsoft Learn: [SetMenuItemBitmaps](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setmenuitembitmaps)

### AddIconToItem

```freebasic
function AddIconToItem( byval hMenu as HMENU, byval uItem as DWORD, byval fByPosition as boolean, byval hIcon as HICON, byval fAutoDestroy as boolean = true, byval phbmp as HBITMAP ptr = NULL ) as boolean
```

Shows an icon to the left of an item's text. The icon is drawn at the small-icon size
(`SM_CXSMICON`) into a new 32-bit bitmap with alpha, and that bitmap is put on the item, which
keeps the menu drawn with visual styles. An icon with an alpha channel is needed: for an icon
without one, the call returns `false` and adds nothing.

The bitmap belongs to the program: delete it with [DestroyBitmaps](#destroybitmaps) (which finds
it on the item) or keep it from `phbmp` and delete it yourself. With `fAutoDestroy` (the default)
the icon is destroyed before returning, whether or not the call succeeded.

| Parameter | Meaning |
| --- | --- |
| `hMenu`, `uItem`, `fByPosition` | The item. |
| `hIcon` | The icon. |
| `fAutoDestroy` | `true` to destroy the icon. |
| `phbmp` | Receives the bitmap, or `NULL` on failure; may be `NULL`. |

**Returns** `true` on success.

**Example**

```freebasic
dim hFile as HMENU = Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 )
dim hIcon as HICON = LoadImageW( NULL, "open.ico", IMAGE_ICON, 16, 16, LR_LOADFROMFILE )
if hIcon then Menu.AddIconToItem( hFile, 0, true, hIcon )
```

Microsoft Learn: [BeginBufferedPaint](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-beginbufferedpaint)

### AddBitmapToItem

```freebasic
function AddBitmapToItem( byval hMenu as HMENU, byval nMenuItem as long, byval fByPosition as boolean, byval hbmp as HBITMAP ) as boolean
```

Puts a bitmap to the left of an item's text. For a menu drawn with visual styles the bitmap
should be a 32-bit DIB section with premultiplied alpha. The menu does not own the bitmap; see
[DestroyBitmaps](#destroybitmaps).

**Returns** `true` on success.

**Example**

```freebasic
dim sz as SIZE : sz.cx = 16 : sz.cy = 16
dim hbmp as HBITMAP
Menu.Create32BitHBITMAP( NULL, @sz, NULL, @hbmp )
Menu.AddBitmapToItem( Menu.GetSubMenu( Menu.GetHandle( hwnd ), 0 ), 0, true, hbmp )
```

Microsoft Learn: [MENUITEMINFOW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-menuiteminfow) (`hbmpItem`)

### DestroyBitmaps

```freebasic
sub DestroyBitmaps( byval hMenu as HMENU )
```

Deletes the bitmap of every item of a menu and of all its submenus, as placed by
[AddIconToItem](#addicontoitem) and [AddBitmapToItem](#addbitmaptoitem), and clears the items'
bitmap field. The predefined `HBMMENU_*` values are left alone, and so are check-mark bitmaps
from [SetItemBitmaps](#setitembitmaps). Call it in `WM_DESTROY`, before the menu goes.

**Example**

```freebasic
Menu.DestroyBitmaps( Menu.GetHandle( hwnd ) )
```

### Create32BitHBITMAP

```freebasic
function Create32BitHBITMAP( byval hDC as HDC, byval psize as SIZE ptr, byval ppvBits as any ptr ptr, byval phBmp as HBITMAP ptr ) as boolean
```

Creates a bottom-up, uncompressed 32-bit DIB section of the size in `psize`, the kind of bitmap
menus draw with alpha. `hDC` may be `NULL` for the screen. The bitmap belongs to the program:
delete it with `DeleteObject`.

| Parameter | Meaning |
| --- | --- |
| `hDC` | A device context, or `NULL`. |
| `psize` | The width and height. |
| `ppvBits` | Receives a pointer to the pixels; may be `NULL`. |
| `phBmp` | Receives the bitmap. |

**Returns** `true` once the bitmap has been asked for; check `*phBmp` for `NULL` to know whether
it was made. `false` when `psize` or `phBmp` is `NULL`.

**Example**

```freebasic
dim sz as SIZE : sz.cx = 16 : sz.cy = 16
dim hbmp as HBITMAP, pBits as any ptr
if Menu.Create32BitHBITMAP( NULL, @sz, @pBits, @hbmp ) andalso hbmp then DeleteObject( hbmp )
```

Microsoft Learn: [CreateDIBSection](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-createdibsection)

### InitBitmapInfo

```freebasic
function InitBitmapInfo( byval pbmi as BITMAPINFO ptr, byval cbInfo as ulong, byval cx as long, byval cy as long, byval bpp as WORD ) as boolean
```

Clears `cbInfo` bytes at `pbmi` and fills the header for an uncompressed (`BI_RGB`), bottom-up
bitmap of `cx` × `cy` pixels at `bpp` bits per pixel.

**Returns** `true`, or `false` for a `NULL` pointer.

**Example**

```freebasic
dim bmi as BITMAPINFO
Menu.InitBitmapInfo( @bmi, sizeof( bmi ), 16, 16, 32 )
```

Microsoft Learn: [BITMAPINFOHEADER](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfoheader)

### HasAlpha

```freebasic
function HasAlpha( byval pargb as DWORD ptr, byval sizeImage as SIZE, byval cxRow as long ) as boolean
```

Looks at `sizeImage.cx` × `sizeImage.cy` 32-bit pixels, rows `cxRow` pixels apart, and tells
whether any of them has a nonzero alpha byte.

**Returns** `true` when one does; `false` otherwise or for a `NULL` pointer.

**Example**

```freebasic
dim px(0 to 3) as DWORD
dim sz as SIZE : sz.cx = 2 : sz.cy = 2
print Menu.HasAlpha( @px(0), sz, 2 )   ' false
```

### ConvertToPARGB32

```freebasic
function ConvertToPARGB32( byval hDC as HDC, byval pargb as DWORD ptr, byval hbmp as HBITMAP, byval sizeImage as SIZE, byval cxRow as long ) as boolean
```

A helper of [AddIconToItem](#addicontoitem): reads the mask bitmap `hbmp` and gives the pixels at
`pargb` an alpha byte from it, making a pixel transparent (0) where the mask is set and opaque
where it is clear.

**Returns** `true` whenever `hDC`, `pargb` and `hbmp` are not `NULL`, whether or not the pixels
were read; `false` otherwise.

**Example**

```freebasic
dim px(0 to 255) as DWORD
dim sz as SIZE : sz.cx = 16 : sz.cy = 16
dim hdc as HDC = CreateCompatibleDC( NULL )
dim hMask as HBITMAP = CreateBitmap( 16, 16, 1, 1, NULL )
Menu.ConvertToPARGB32( hdc, @px(0), hMask, sz, 16 )
DeleteObject( hMask ) : DeleteDC( hdc )
```

Microsoft Learn: [GetDIBits](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getdibits)

### ConvertBufferToPARGB32

```freebasic
function ConvertBufferToPARGB32( byval hPaintBuffer as HPAINTBUFFER, byval hDC as HDC, byval hIcon as HICON, byval sizeIcon as SIZE ) as boolean
```

A helper of [AddIconToItem](#addicontoitem): looks at the pixels of a buffered-paint buffer into
which an icon has been drawn and, when none has alpha, converts them with the icon's mask
through [ConvertToPARGB32](#converttopargb32).

**Returns** `true` when the buffer had alpha; `false` otherwise.

Microsoft Learn: [GetBufferedPaintBits](https://learn.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-getbufferedpaintbits)

## See also

- [sys/win/gui](SysWin-Gui)
- [CWindow](CWindow) for the window a menu bar belongs to
- [StatusBar](SysWin-Gui-StatusBar) for showing a menu item's help text
- [ToolBar](SysWin-Gui-ToolBar), whose buttons usually repeat menu commands
- [gui macros and helpers](SysWin-Gui-Procedures) for `CBCTL` and the other `WM_COMMAND` helpers
- [Fonts](SysWin-Fonts)
