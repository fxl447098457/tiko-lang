[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › **sys/win/gui**

# sys/win/gui

Creates windows, dialogs and common controls, with one namespace of helpers per control.

`sys/win/gui` is the part of `sys/win` that builds user interfaces. It has two kinds of contents:

- **Classes** for windows and the things in them. [CWindow](CWindow) creates a main window, adds
  controls with ready-made styles, scales everything for the display's DPI and runs the message
  loop; [CDialog](CDialog) does the same for dialog boxes; the other classes are controls of their
  own (a themed button, a masked edit box, a drawing surface), tab pages, printing, the Explorer
  browser and the open and save dialogs.
- **One namespace per common control**, holding functions over that control's messages:
  `ListView.AddColumn( hList, 0, "Name", 200 )` instead of filling an `LVCOLUMNW` and sending
  `LVM_INSERTCOLUMNW`. Namespaces are always written out, also after `using gui`.

The module also brings the Win32 headers for common controls, the shell, the common dialogs and
DWM into the importing file, the `RGB_*` colour constants, the `ANCHOR_*` layout constants and
the `CB*` message helpers. It imports `sys/win` itself; import `sys/win` as well to call its
functions bare.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A window with a list box filled through the `ListBox` namespace and a button that reports the
selection.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_LIST = 101
const IDC_SHOW = 102

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "GuiDemo"
    dim hWin as HWND = pWindow.Create( NULL, "sys/win/gui", @WndProc )
    pWindow.SetClientSize( 300, 240 )
    pWindow.Center()
    dim hList as HWND = pWindow.AddControl( "ListBox", hWin, IDC_LIST, "", 10, 10, 280, 180 )
    for i as long = 1 to 12
        ListBox.AddString( hList, "Item " & i )
    next
    ListBox.SetCurSel( hList, 0 )
    pWindow.AddControl( "Button", hWin, IDC_SHOW, "&Show", 190, 202, 100, 28 )
    pWindow.AnchorControl( hList, ANCHOR_HEIGHT_WIDTH )
    pWindow.AnchorControl( IDC_SHOW, ANCHOR_BOTTOM_RIGHT )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            select case CBCTL( wParam, lParam )
                case IDC_SHOW
                    dim hList as HWND = GetDlgItem( hwnd, IDC_LIST )
                    SetWindowText( hwnd, "Selected: " & ListBox.GetText( hList, ListBox.GetCurSel( hList ) ) )
                case IDCANCEL
                    SendMessageW( hwnd, WM_CLOSE, 0, 0 )
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

## Pages

**Classes**

| Page | Covers |
| --- | --- |
| [CWindow](CWindow) | the main window class: creating windows and controls, DPI scaling, the message loop, colours, anchors, accelerators, scrolling |
| [CTabPage](CTabPage) | a `CWindow` that is one page of a tab control |
| [CDialog](CDialog) | dialog boxes built from an in-memory template, with the same services as `CWindow` |
| [CMaskedEdit](CMaskedEdit) | an edit box that accepts input only in the shape of a mask |
| [CMemBmp](CMemBmp) | a memory bitmap with its own device context, blank or loaded from a file or resource |
| [CGraphCtx](CGraphCtx) | a graphic control: a child window that keeps what is drawn on it, with GDI, GDI+ or OpenGL |
| [CExplorerBrowser](CExplorerBrowser) | the Windows Explorer browser hosted in a window, with its events |
| [File dialogs](SysWin-Gui-File-Dialogs) | `CIOpenFileDialog` and `CISaveFileDialog`, the Windows open and save dialogs |
| [CIFileDialogCustomize](CIFileDialogCustomize) | adding check boxes, lists, buttons and other controls to an open or save dialog |
| [File dialog events](SysWin-Gui-File-Dialog-Events) | handling the events of an open or save dialog and of the controls added to it |
| [gui macros and helpers](SysWin-Gui-Procedures) | `CBCTL`, `CBCTLMSG`, `CBNMHDR` and the other macros that read `wParam` and `lParam` |

**Control namespaces**

| Page | Covers |
| --- | --- |
| [ListView](SysWin-Gui-ListView) | list views: columns, items, subitems, selection, image lists, views |
| [TreeView](SysWin-Gui-TreeView) | tree views: inserting, finding and expanding items, selection, images |
| [Header](SysWin-Gui-Header) | header controls: items, widths, order, filters, image lists |
| [ToolBar](SysWin-Gui-ToolBar) | toolbars: buttons, states, image lists, sizes |
| [Rebar](SysWin-Gui-Rebar) | rebars: bands and their child windows |
| [Menu](SysWin-Gui-Menu) | menus: creating them, adding, checking, enabling and finding items |
| [StatusBar](SysWin-Gui-StatusBar) | status bars: parts, text, icons |
| [ToolTip](SysWin-Gui-ToolTip) | tooltips: adding tools, text, delays, colours, titles |
| [Edit](SysWin-Gui-Edit) | edit boxes: text, selection, lines, limits, margins, undo |
| [Combo](SysWin-Gui-Combo) | combo boxes: adding, finding and selecting strings, the drop-down list |
| [CBEx](SysWin-Gui-CBEx) | extended combo boxes, with images |
| [ListBox](SysWin-Gui-ListBox) | list boxes: adding, finding and selecting strings, multiple selection |
| [Button](SysWin-Gui-Button) | buttons, check boxes and radio buttons: state, images, split buttons, notes |
| [Label](SysWin-Gui-Label) | static controls: text, icons, bitmaps, cursors and metafiles |
| [ProgBar](SysWin-Gui-ProgBar) | progress bars: range, position, step, state, colours |
| [TabCtl](SysWin-Gui-TabCtl) | tab controls: tabs, selection, image lists, and destroying `CTabPage` pages |
| [TrackBar](SysWin-Gui-TrackBar) | trackbars: range, position, ticks, selection, buddies |
| [UpDown](SysWin-Gui-UpDown) | up-down controls: range, position, base, buddy |
| [Pager](SysWin-Gui-Pager) | pager controls: the child window, buttons, position |
| [MonthCal](SysWin-Gui-MonthCal) | month calendars: the selected date or range, limits, colours |
| [DTP](SysWin-Gui-DTP) | date and time pickers: the date and time, format, the drop-down calendar |
| [Animate](SysWin-Gui-Animate) | animation controls: opening, playing and stopping a clip |
| [HotKey](SysWin-Gui-HotKey) | hot key controls: reading and setting the key and its rules |
| [IPAddress](SysWin-Gui-IPAddress) | IP address controls: the address, its fields and their ranges |
| [PropSheet](SysWin-Gui-PropSheet) | property sheets and wizards: creating them, their buttons |
| [ScrollBar](SysWin-Gui-ScrollBar) | scroll bar controls: range, position, showing and enabling |
| [SysLink](SysWin-Gui-SysLink) | SysLink controls: links, their state and size |

## See also

- [Category: sys/win](Category-Sys-Win) for the other modules and the conventions every page uses
- [Window size and position](SysWin-Window-Size-and-Position) and the other `sys/win` pages for the helpers the classes are built on
- [Colours](SysWin-Colors) for the `RGB_*` constants
