[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkMenuBar**

# tkMenuBar

Draws a window's menu bar, whose items drop down tkPopupMenu menus.

tkMenuBar is the strip of top-level menu names (File, Edit, View, Help) along the top of a window. Each item can own a dropdown, a [tkPopupMenu](tkPopupMenu) menu attached with `tkMenuBar_SetDropDown`; the bar owns it from then on and destroys it with itself. Items are appended in order, each as wide as its text in the bar's font; `tkMenuBar_GetIdealWidth` is the width they need.

It behaves like a desktop menu bar. A click opens an item's dropdown, moving the mouse along the bar switches dropdowns while one is open, and clicking the bar again closes it. Left and Right step between dropdowns. `tkMenuBar_SetActiveIndex` starts the keyboard highlight mode (bind it to a key such as F10): Left / Right move the highlight, Down or Enter open, Escape clears.

A chosen command arrives at the bar's Command callback with its id, after the whole menu has closed. The InitPopup callback runs before every dropdown opens, the moment to update check marks and enabled states. A paint callback draws each bar item yourself; `tkMenuBar_PaintItemDefault( p )` in it draws the stock item first. Setters are silent.

## Importing

```freebasic
#import "vendor/tkControls/tkMenuBar"
using tkMenuBar
using tkPopupMenu
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme) and [tkPopupMenu](tkPopupMenu); `using tkPopupMenu` names the `tkPopupMenu_*` calls that build the dropdowns.

## Example

`gHost` is the window ([tkHost](tkHost)); `gFont10` and `gGlyph9` are fonts opened with `tkHost_OpenFont`, the second from `tkHost_FontDir() & TK_FONT_ICONS`.

```freebasic
const as long IDM_FILE_NEW = 101, IDM_FILE_WRAP = 102, IDM_FILE_EXIT = 103
dim shared as boolean gWrap

sub OnCommand( byval hMenuBar as TK_WIDGET ptr, byval id as long )
    if id = IDM_FILE_WRAP then gWrap = not gWrap
end sub

sub OnInitPopup( byval hMenuBar as TK_WIDGET ptr, byval idx as long, byval hPopup as TK_MENU ptr )
    if idx = 0 then tkPopupMenu_SetItemChecked( hPopup, IDM_FILE_WRAP, gWrap )
end sub

dim as TK_WIDGET ptr bar = tkMenuBar_Create( tkHost_Root( gHost ), 100 )
tkMenuBar_SetFont( bar, gFont10 )
tkMenuBar_SetCommandCallback( bar, @OnCommand )
tkMenuBar_SetInitPopupCallback( bar, @OnInitPopup )
tkMenuBar_AddItem( bar, "File", 1 )
tkMenuBar_AddItem( bar, "Help", 2 )

dim as TK_MENU ptr hFile = tkPopupMenu_Create( gHost )
tkPopupMenu_SetFonts( hFile, gFont10, gGlyph9 )
tkPopupMenu_SetGlyphs( hFile, wchr( TK_ICON_CHECKMARK ), wchr( TK_ICON_CHEVRON_RIGHT ) )
tkPopupMenu_AddItem( hFile, IDM_FILE_NEW, "New File", "Ctrl+N" )
tkPopupMenu_AddItem( hFile, IDM_FILE_WRAP, "Word Wrap" )
tkPopupMenu_AddSeparator( hFile )
tkPopupMenu_AddItem( hFile, IDM_FILE_EXIT, "Exit", "Alt+F4" )
tkMenuBar_SetDropDown( bar, 0, hFile )

tkWidget_SetPos( bar, 0, 0, 600, tkHost_Scale( gHost, 30 ) )   ' a height first,
tkWidget_SetPos( bar, 0, 0, tkMenuBar_GetIdealWidth( bar ), tkHost_Scale( gHost, 30 ) )
```

The item rects, and so `tkMenuBar_GetIdealWidth`, are only known once the bar has a height, hence the two calls. The accelerator text in a menu is only a label: bind the keys themselves with [tkKeys](tkKeys). The toolchain's `examples/tkControls/tkMenuBar/` has four dropdowns, a submenu rebuilt on every open and a right-click menu.

## How it works

### The bar's height, and the strip beside it, are yours

The bar is created zero-sized and does not decide its own size. Item rects always span the
full height, so whatever height you give the bar is the height of every item, the caption
centred in it. `tkMenuBar_GetIdealWidth` reports the right edge of the last item: size the bar
to that and put your own widget beside it, or leave the bar full-width and use the leftover
strip. `GetIdealWidth` and `GetItemRect` return nothing useful (0, an empty rect) until the bar
has a height, because layout does not run against a zero-height bar.

### Geometry is derived

Items run end to end from `x = 0`:

```
  itemWidth  = caption width in the bar's font + 2 * padding
  item rect  = [ runningX, 0 ] .. [ runningX + itemWidth, height ]
  idealWidth = the last item's right edge
```

Layout is lazy: adding or retitling an item, changing the padding or the font, or resizing
marks it stale, and the next paint or rect query recomputes it. Items that do not fit clip at
the right edge; nothing is squeezed and there is no overflow chevron. The padding default (6
per side) is scaled for the surface at creation and rescaled when the scale changes;
`SetPadding` takes pixels as given.

### Hot and active

Two separate facts, painted alike by the built-in painter:

- **Hot** is the item under the pointer (`GetHotIndex`), cleared when the pointer leaves the
  bar. Any item highlights on hover, with a dropdown or without.
- **Active** is the item whose dropdown is open, or the item holding the keyboard highlight
  when nothing is open (`GetActiveIndex`). `IsMenuOpen` tells the two apart.

A click opens the dropdown at once, so hover and active are two frames of one gesture and
styling them differently would make the fill flicker on press. A paint callback receives
`isHot` and `isActive` separately if your design wants them distinct.

### Opening, switching and closing

| Gesture | Effect |
| --- | --- |
| Click an item with a dropdown | Opens it, nothing selected |
| Move onto another item while a dropdown is open | Switches to that item's dropdown, if it has one |
| Click the bar again while a dropdown is open | Closes it |
| Click an item with no dropdown | Nothing |
| Press anywhere outside | Closes the menu, and the press still reaches its target |

Opening runs the bar's InitPopup callback, then the dropdown's own, then shows the dropdown
under the item with its border merged into the bar's bottom edge. The bar takes no mouse
capture for clicks; it acts on the press alone, so a double click toggles once per press.
Only one menu is open at a time in the whole application: opening a context menu elsewhere
closes the bar's dropdown, and the bar notices on its next paint, mouse event or
`IsMenuOpen`. Focus leaving the application closes the menus too.

### Keyboard

**A dropdown is open.** Keys go to the open menu (see [tkPopupMenu](tkPopupMenu)), with two
moves added at the bar's edge:

| Key | Effect |
| --- | --- |
| Left, at the top level of the menu | Open the previous bar item that has a dropdown, wrapping, with its first row selected |
| Right, on a row without an enabled submenu | Open the next such item, the same way |
| Escape, at the top level | Close the dropdown and keep the item highlighted (the highlight mode below) |

Inside a submenu, Left closes it, and Right on a submenu row opens it: the bar takes only the
two keys the menu itself would ignore.

**Highlight mode**, entered with `tkMenuBar_SetActiveIndex`: an item is highlighted and nothing
is open. For as long as it lasts the bar holds the keyboard focus and the mouse capture, and
gives the focus back to whoever had it when it ends.

| Key | Effect |
| --- | --- |
| Left / Right | Move the highlight to any item, wrapping |
| Down / Enter | Open the highlighted item's dropdown with its first row selected |
| Escape | Clear the highlight |
| A press anywhere off the bar | Ends the highlight; the press still lands where it was aimed |
| Tab | Moves the focus on and ends the highlight |

Alt does nothing on its own: what it means is the application's decision. Drive the bar for
it with `tkMenuBar_OpenMenu( h, idx, bSelectFirst )` (open a named menu, as an Alt+F
accelerator would) or `tkMenuBar_SetActiveIndex` (highlight only, as a bare Alt or F10 press
would). There is no mnemonic parsing: a caption is drawn as written.

### Programmatic changes are silent

`OpenMenu`, `CloseMenu`, `SetActiveIndex`, `AddItem` and `SetItemText` fire no Command
callback. Opening a menu by any route does run the InitPopup callbacks, because they report a
dropdown becoming visible, not a choice. `CloseMenu` closes any open dropdown and clears the
highlight.

### Dropdowns and lifetime

`tkMenuBar_SetDropDown( h, idx, hPopup )` attaches a [tkPopupMenu](tkPopupMenu) menu, and
ownership passes to the bar: it is destroyed with the bar, together with its submenus.
Attaching over an existing dropdown destroys the old one; passing 0 detaches it without
destroying it, and hands back its own callbacks. `GetDropDown` returns it, which is how you
reach its rows to flip a check mark or an enabled state. Fonts stay yours: the bar borrows
them, and with none set it uses the host's default font for measuring and drawing.

The dropdown's own select and closed callbacks, and its key hook, still run while it is
attached; the bar chains its own behind them. Colours for the dropdowns are their own
(`tkPopupMenu_SetColors`); nothing passes from the bar to its menus.

## Behaviour and limits

- Items are append-only: no insert, delete, clear or hide. Build the bar once; the dropdowns
  are the dynamic part.
- The id passed to `AddItem` is stored and never read; there is no getter. Bar items are
  addressed by index, and commands come from the dropdown rows.
- The bar is never a tab stop and takes the focus only during highlight mode.
- Right and middle presses on the bar do nothing.

## Colours

`TKMENUBAR_COLORS` has four fields, filled from the theme at creation and on every theme
change until `SetColors` pins them; `UnpinColors` hands them back, and `GetColors` reads them.

| Field | Theme role | Paints |
| --- | --- | --- |
| `BackColor` | `Window` | The bar background, and an idle item |
| `ForeColor` | `Text` | An idle caption |
| `BackColorHot` | `SurfaceHot` | A hovered or active item |
| `ForeColorHot` | `TextHot` | A hovered or active caption |

The painter fills the whole bar with `BackColor`, then each item's rect in its pair, then the
caption centred in it.

## Callbacks

- **Command**, `MB_CommandCallbackSub( hMenuBar, id )`: a command row on one of the bar's
  dropdowns was chosen, by click or Enter. `id` is the row's command id, not the bar item's.
  By the time it runs the menu is closed and the highlight cleared (`IsMenuOpen` is false), so
  the handler can open a dialog or another menu; the dropdown's own select callback, if any,
  has run just before it. User action only.
- **InitPopup**, `MB_InitPopupCallbackSub( hMenuBar, idx, hPopup )`: the dropdown of item `idx`
  is about to open, by any route. Update check marks, enabled states and captions here (the
  by-id setters reach into submenus), or rebuild a dynamic section; it runs before the
  dropdown's own InitPopup.
- **Paint item**, `MB_PaintItemCallbackSub( p )`: draws every bar item instead of the built-in
  painter. The bar background is already painted; fill `p->rc` (not the whole bar) and draw the
  caption in it. `TKMENUBAR_PAINTINFO` carries the bar, the item index, the paint context, the
  rect, `isHot`, `isActive` (both can be true at once) and the caption.
  `tkMenuBar_PaintItemDefault( p )` draws the stock item first.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKMENUBAR_DEFAULT_PADDING = 6
```

### Types

```freebasic
type TKMENUBAR_ITEM
    id          as long
    wszText     as ustring
    hDropDown   as TK_MENU ptr            ' OWNED once attached
    prevSelect  as PM_SelectCallbackSub
    prevClosed  as PM_ClosedCallbackSub
    prevKeyHook as PM_KeyHookFunc
    nWidth      as long
    rc          as TKRECT
end type

type TKMENUBAR_COLORS
    BackColor    as ulong = &hFF21252Bul    ' bar + idle item
    ForeColor    as ulong = &hFFC8CDD6ul
    BackColorHot as ulong = &hFF373D48ul    ' hovered / active item
    ForeColorHot as ulong = &hFFE2E6EEul
end type

type TKMENUBAR_PAINTINFO
    hMenuBar   as TK_WIDGET ptr
    itemID     as long
    b          as TK_PAINT ptr
    rc         as TKRECT
    isHot      as boolean
    isActive   as boolean
    wszCaption as ustring
end type

type TKMENUBAR_STATE   ' per-instance state; reach it through the procedures

type MB_CommandCallbackSub as sub( byval hMenuBar as TK_WIDGET ptr, byval id as long )
type MB_InitPopupCallbackSub as sub( byval hMenuBar as TK_WIDGET ptr, byval idx as long, byval hPopup as TK_MENU ptr )
type MB_PaintItemCallbackSub as sub( byval p as TKMENUBAR_PAINTINFO ptr )
```

### Procedures

```freebasic
function tkMenuBar_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkMenuBar_AddItem( byval hMenuBar as TK_WIDGET ptr, byval Text as ustring, byval id as long ) as long
function tkMenuBar_GetItemCount( byval hMenuBar as TK_WIDGET ptr ) as long
function tkMenuBar_GetItemText( byval hMenuBar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkMenuBar_SetItemText( byval hMenuBar as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkMenuBar_SetDropDown( byval hMenuBar as TK_WIDGET ptr, byval idx as long, byval hPopup as TK_MENU ptr ) as boolean
function tkMenuBar_GetDropDown( byval hMenuBar as TK_WIDGET ptr, byval idx as long ) as TK_MENU ptr
function tkMenuBar_GetItemRect( byval hMenuBar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkMenuBar_GetIdealWidth( byval hMenuBar as TK_WIDGET ptr ) as long
function tkMenuBar_GetPadding( byval hMenuBar as TK_WIDGET ptr ) as long
sub tkMenuBar_SetPadding( byval hMenuBar as TK_WIDGET ptr, byval nPadding as long )
function tkMenuBar_OpenMenu( byval hMenuBar as TK_WIDGET ptr, byval idx as long, byval bSelectFirst as boolean = false ) as boolean
sub tkMenuBar_CloseMenu( byval hMenuBar as TK_WIDGET ptr )
function tkMenuBar_IsMenuOpen( byval hMenuBar as TK_WIDGET ptr ) as boolean
function tkMenuBar_GetActiveIndex( byval hMenuBar as TK_WIDGET ptr ) as long
function tkMenuBar_SetActiveIndex( byval hMenuBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkMenuBar_GetHotIndex( byval hMenuBar as TK_WIDGET ptr ) as long
sub tkMenuBar_SetColors( byval hMenuBar as TK_WIDGET ptr, byval pColors as TKMENUBAR_COLORS ptr )
sub tkMenuBar_GetColors( byval hMenuBar as TK_WIDGET ptr, byval pColors as TKMENUBAR_COLORS ptr )
function tkMenuBar_ThemeColors( byref t as TKTHEME_COLORS ) as TKMENUBAR_COLORS
sub tkMenuBar_ApplyTheme( byval hMenuBar as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkMenuBar_UnpinColors( byval hMenuBar as TK_WIDGET ptr )
sub tkMenuBar_ApplyFonts( byval hMenuBar as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkMenuBar_SetFont( byval hMenuBar as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkMenuBar_SetCommandCallback( byval hMenuBar as TK_WIDGET ptr, byval usersub as MB_CommandCallbackSub )
sub tkMenuBar_SetInitPopupCallback( byval hMenuBar as TK_WIDGET ptr, byval usersub as MB_InitPopupCallbackSub )
sub tkMenuBar_PaintItemDefault( byval p as TKMENUBAR_PAINTINFO ptr )
sub tkMenuBar_SetPaintItemCallback( byval hMenuBar as TK_WIDGET ptr, byval usersub as MB_PaintItemCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkPopupMenu](tkPopupMenu), [tkKeys](tkKeys)
