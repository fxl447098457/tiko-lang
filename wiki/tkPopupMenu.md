[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPopupMenu**

# tkPopupMenu

Shows a popup menu of commands, separators, check marks and submenus.

tkPopupMenu is the menu itself: rows with a caption, an optional accelerator label on the right, a check mark, a disabled state, separators and nested submenus. It serves as a right-click context menu, as the dropdowns of a [tkMenuBar](tkMenuBar), and as a menu for any button. Create a menu once and show it as often as you like; while it is closed it has no window at all.

Hover is selection, and resting on a submenu row for a moment opens it. A command runs when the mouse button is released over an enabled row (or on Enter), and the Select callback receives its id after the whole chain of menus has closed. The keyboard works as in any desktop menu: Up / Down wrap, Home / End, Right and Left go in and out of submenus, Enter chooses, Escape closes one level. A click outside closes the menus and still reaches what it lands on. Only one chain of menus is open at a time.

Operations that take an id (`tkPopupMenu_SetItemChecked`, `tkPopupMenu_SetItemEnabled`, `tkPopupMenu_DeleteItem` and the rest) search the submenus too. A submenu attached with `tkPopupMenu_SetItemSubMenu` is owned by its parent and destroyed with it.

## Importing

```freebasic
#import "vendor/tkControls/tkPopupMenu"
using tkPopupMenu
using tkHost
```

The module brings in [tkHost](tkHost) and [tkTheme](tkTheme). The handle is a `TK_MENU ptr`, not a widget.

## Example

A right-click menu with a submenu. `gHost` is the window ([tkHost](tkHost)); `gFont10` and `gGlyph9` are fonts opened with `tkHost_OpenFont`, the second from `tkHost_FontDir() & TK_FONT_ICONS`.

```freebasic
const as long IDM_INSERT = 1, IDM_RENAME = 2, IDM_ADVANCED = 3, IDM_ADV_ONE = 4
dim shared as TK_MENU ptr gCtx

sub OnSelect( byval hPopup as TK_MENU ptr, byval id as long )
    print "command "; id
end sub

function NewMenu() as TK_MENU ptr
    dim as TK_MENU ptr m = tkPopupMenu_Create( gHost )
    tkPopupMenu_SetFonts( m, gFont10, gGlyph9 )
    tkPopupMenu_SetGlyphs( m, wchr( TK_ICON_CHECKMARK ), wchr( TK_ICON_CHEVRON_RIGHT ) )
    return m
end function

gCtx = NewMenu()
tkPopupMenu_SetSelectCallback( gCtx, @OnSelect )
tkPopupMenu_AddItem( gCtx, IDM_INSERT, "Insert Row" )
tkPopupMenu_AddItem( gCtx, IDM_RENAME, "Rename...", "F2" )
tkPopupMenu_AddSeparator( gCtx )
tkPopupMenu_AddItem( gCtx, IDM_ADVANCED, "Advanced" )
dim as TK_MENU ptr hAdv = NewMenu()
tkPopupMenu_AddItem( hAdv, IDM_ADV_ONE, "Advanced Option One" )
tkPopupMenu_SetItemSubMenu( gCtx, IDM_ADVANCED, hAdv )

' in a widget's procedure, on TKM_RBUTTONUP (m->x, m->y are widget-local):
'     dim as TKRECT a
'     tkWidget_AbsRect( w, a )
'     tkPopupMenu_Show( gCtx, a.left + cint( m->x ), a.top + cint( m->y ) )
```

The submenu needs no Select callback of its own: the root menu's callback receives a command chosen anywhere in its chain. The toolchain's `examples/tkControls/tkMenuBar/` uses this menu both as dropdowns and as a context menu.

## Where a menu appears

`tkPopupMenu_Show( m, x, y )` puts the menu's top-left at `x, y`, and `tkPopupMenu_ShowForRect( m, rc, PM_ALIGN_BELOW )` (or `PM_ALIGN_RIGHT`) places it against a rectangle, such as the button that opened it. Both take pixels of the **owner window**, the `TK_HOST ptr` given to `tkPopupMenu_Create`, not screen coordinates. Showing is not modal: the call returns at once and the command arrives through the Select callback. It returns `false` when there is no font to measure with or the popup cannot be opened.

- `PM_ALIGN_BELOW` opens under the rectangle, overlapping its bottom pixel so the two edges merge; with no room below it opens above the rectangle.
- `PM_ALIGN_RIGHT` opens to the right with the tops aligned; with no room on the right it opens on the left. Submenus open this way against their parent row.
- Otherwise the menu is pushed back inside the display's usable area. There is no scrolling: a menu taller than that area keeps its top edge on screen and loses its bottom rows, so keep menus to a screen's worth of rows or split them into submenus. (On Wayland the compositor keeps popups on screen instead.)

Only one chain of menus is open at a time in the application: showing a menu as a root first closes any other open chain, silently. A menu always opens with no row selected; `tkPopupMenu_SelectFirst` selects its first selectable row, as a menu opened from the keyboard wants.

## Layout

Rows stack top to bottom. A command row is the item height (default 24, `tkPopupMenu_SetItemHeight`); a separator row is the shorter separator height (default 9, `tkPopupMenu_SetSeparatorHeight`). The size is computed, never assigned:

```
contentW = max( minWidth, checkCol + widestCaption + accelBlock + chevronCol )
           accelBlock = accelGap + widestAccel, or 0 when no row has accelerator text
width    = contentW + 2 * hPadding + 2 * border
height   = sum of the row heights + 2 * vPadding + 2 * border
```

Each row is split into three cells: the check column (default 30) with the check glyph centred, the text cell with the caption left-aligned and the accelerator right-aligned, and the chevron column (default 20) with the submenu chevron centred. The padding strips beside the rows are background; `tkPopupMenu_HitTest` there returns -1. The border is one pixel at 100% scale, painted after the rows, and has no setter.

A separator row draws a rule `tkPopupMenu_SetSeparatorThickness` pixels thick (default 1) across its middle, inset by half the item height at each end. Heights and the thickness clamp to at least 1, `tkPopupMenu_SetMinWidth` to at least 0.

Layout is lazy: changes mark it stale and the next paint, show or geometry query measures once, so rebuilding a whole menu with a burst of `tkPopupMenu_AddItem` costs one pass. `tkPopupMenu_GetItemRect` and `tkPopupMenu_HitTest` take **row indices** and the menu's own pixels; `tkPopupMenu_GetIdealSize` returns `false` while there is no font to measure with.

The id operations search the menu and then its submenus depth-first and take the first match, so keep ids unique across the tree. Id 0 never matches: it is what separators carry. `tkPopupMenu_SetItemText` without an accelerator clears the row's accelerator text. Accelerator text is display only: the menu has no mnemonics or type-ahead, and a check mark is per-row state, so making a group of rows mutually exclusive is up to you.

## Mouse and keyboard

There is one highlight, moved by the mouse and the keyboard alike. Resting the cursor on a row for `TKPOPUPMENU_HOVER_MS` (250 ms) opens its submenu, or closes another row's open submenu; pressing on a submenu row opens it at once. While a submenu is open its parent row stays highlighted, so crossing into the submenu never loses it. The menu remembers who set the highlight: when the cursor leaves, a highlight set by the mouse clears and one set by the keyboard stays, and a rest only acts on a highlight set by the mouse.

A command runs on the left-button release over an **enabled command row**; separators, disabled rows and submenu rows never run. A disabled row or a separator under the cursor is still the selection (`isHot` in the paint info), but the built-in painter never lights it up.

Keys go to the innermost open menu with no setup, and while a chain is open it consumes every key and typed character, so nothing reaches the window behind it.

| Key | Effect on the innermost open menu |
| --- | --- |
| Down / Up | Next / previous selectable row, wrapping; Up from no selection takes the last |
| Home / End | First / last selectable row |
| Right | Open the selected row's submenu with its first row selected |
| Left | Close this submenu; at the root, nothing |
| Enter | Run the selected row, or open its submenu |
| Escape | Close this submenu; at the root, close the whole chain |

"Selectable" is neither a separator nor disabled; a menu whose every row is disabled keeps no selection. `tkPopupMenu_SetKeyHook` on the root sees each key first, with the root and the innermost open menu, as an `SDLK_*` key code; returning `true` skips the table. [tkMenuBar](tkMenuBar) uses it to turn Left at the root and Right on a plain row into stepping between bar items.

From code: `tkPopupMenu_SetCurSel` (-1 clears; it does not refuse separators or disabled rows), `tkPopupMenu_SelectFirst` and `tkPopupMenu_OpenSubMenu` (as Right or Enter would, on an open menu).

## Notifications

- **Select** `( root, id )`: an enabled command row ran, by the mouse or Enter. Only the root's callback is consulted, wherever in the chain the row lives. It runs **after the whole chain has closed**, so the handler can open a dialog or another menu straight away.
- **Init popup** `( menu )`: each menu has its own, fired as that menu is about to show (from code too) and before it is measured. It is the place to enable, check or retitle rows, or to rebuild a section with `tkPopupMenu_Clear` and `tkPopupMenu_AddItem`. `Clear` destroys the submenus of the rows it removes, so a rebuild re-creates and re-attaches them.
- **Closed** `( root, reason )`: the user dismissed the chain without running a command. `PM_CLOSED_ESCAPE` is Escape at the root; `PM_CLOSED_OTHER` is a press outside the chain or the application losing the focus. A press outside closes the menus and still reaches what it lands on. `tkPopupMenu_Hide`, `tkPopupMenu_CloseChain` and showing another root are silent.
- **Paint item** `( p )`: replaces the built-in painter for **every** row of that menu, separators included. Paint through `p->b`, fill `p->rc` and nothing wider, use the three cell rects as given, and draw with the fonts given to `tkPopupMenu_SetFonts`, since the widths were measured with them. The menu fills its background before the rows and paints the border after them, whatever the callback drew.

## Colours and theme

Every colour comes from the theme ([tkTheme](tkTheme)) when the menu is created, each time it shows, and while it is open when the theme changes.

| Field | Paints | Theme colour |
| --- | --- | --- |
| `BackColor` | The background, normal rows, disabled rows, separator rows | `Popup` |
| `ForeColor` | Caption and accelerator on a normal row | `PopupText` |
| `BackColorHot` | The selected row's fill | `Selected` |
| `ForeColorHot` | The selected row's text | `SelectedText` |
| `ForeColorDisabled` | A disabled row's caption and accelerator | `TextDisabled` |
| `BorderColor` | The border | `Border` |
| `SeparatorColor` | The separator rule | `Divider` |

A disabled row never lights up: it draws `ForeColorDisabled` over `BackColor`, and there is no disabled background colour. `tkPopupMenu_SetColors` copies the struct and pins it, so the theme no longer applies until `tkPopupMenu_UnpinColors`. A freshly declared `TKPOPUPMENU_COLORS` is all zero except `SeparatorColor` (mid grey), so start from `tkPopupMenu_GetColors` or `tkPopupMenu_ThemeColors` and change what you need.

## Fonts, glyphs and scale

The text font draws the captions and accelerators and is the one the layout measures with; without `tkPopupMenu_SetFonts` the owner window's default font is used. The glyph font draws the check mark and the chevron; without one they are drawn in the text font. The default glyphs are the characters ✓ (U+2713) and › (U+203A); give the bundled icon font and `tkPopupMenu_SetGlyphs` for the icon look, as the example does. `tkPopupMenu_ApplyFonts` replaces only the fonts it is given. Fonts are borrowed, never freed.

The default metrics are scaled to the owner window when the menu is created, and each time a menu shows its metrics follow the scale of the window it opens on. The setters take pixels at the menu's current scale. The separator thickness never scales, so a hairline stays a hairline.

## Lifetime and ownership

Create a menu once and show it as often as you like. `tkPopupMenu_Destroy` closes it if open and frees it with every submenu attached to it. `tkPopupMenu_SetItemSubMenu` hands the submenu to its parent, and attaching over an existing submenu destroys the old one; never attach one menu to two parents, as both would destroy it. `tkPopupMenu_DeleteItem` and `tkPopupMenu_Clear` destroy the submenus of the rows they remove. A menu given to `tkMenuBar_SetDropDown` belongs to the bar.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKPOPUPMENU_HOVER_MS = 250
const TKPOPUPMENU_DEFAULT_ITEMHEIGHT = 24
const TKPOPUPMENU_DEFAULT_SEPHEIGHT = 9
const TKPOPUPMENU_DEFAULT_SEPTHICKNESS = 1
const TKPOPUPMENU_DEFAULT_CHECKCOL = 30
const TKPOPUPMENU_DEFAULT_CHEVRONCOL = 20
const TKPOPUPMENU_DEFAULT_ACCELGAP = 24
const TKPOPUPMENU_DEFAULT_HPADDING = 2
const TKPOPUPMENU_DEFAULT_VPADDING = 8
const PM_ALIGN_BELOW = 1
const PM_ALIGN_RIGHT = 2
const PM_CLOSED_OTHER = 0
const PM_CLOSED_ESCAPE = 1
```

### Types

```freebasic
type TKPOPUPMENU_COLORS
    BackColor         as ulong
    ForeColor         as ulong
    BackColorHot      as ulong
    ForeColorHot      as ulong
    ForeColorDisabled as ulong
    BorderColor       as ulong
    SeparatorColor    as ulong = &hFF808080ul
end type

type TKPOPUPMENU_PAINTINFO
    hPopup      as TK_MENU ptr
    itemID      as long             ' the row index
    id          as long             ' the row's command id (0 for separators)
    b           as TK_PAINT ptr
    rc          as TKRECT           ' the full row -- fill this
    rcCheck     as TKRECT
    rcText      as TKRECT           ' caption LEFT, accelerator RIGHT, same rect
    rcChevron   as TKRECT
    isSeparator as boolean
    isDisabled  as boolean
    isChecked   as boolean
    hasSubMenu  as boolean
    isHot       as boolean
    wszCaption  as ustring
    wszAccel    as ustring
end type

type TKPM_ITEM
    id          as long
    wszCaption  as ustring
    wszAccel    as ustring
    isSeparator as boolean
    isDisabled  as boolean
    isChecked   as boolean
    pSub        as TK_MENU ptr        ' OWNED
    rc          as TKRECT
end type

type TK_MENU_   ' per-instance state; reach it through the procedures

type TK_MENU as TK_MENU_
type PM_SelectCallbackSub as sub( byval hPopup as TK_MENU ptr, byval id as long )
type PM_InitPopupCallbackSub as sub( byval hPopup as TK_MENU ptr )
type PM_PaintItemCallbackSub as sub( byval p as TKPOPUPMENU_PAINTINFO ptr )
type PM_ClosedCallbackSub as sub( byval hPopup as TK_MENU ptr, byval nReason as long )
type PM_KeyHookFunc as function( byval hRoot as TK_MENU ptr, byval hInner as TK_MENU ptr, byval key as long ) as boolean
```

### Procedures

```freebasic
function tkPopupMenu_ThemeColors( byref t as TKTHEME_COLORS ) as TKPOPUPMENU_COLORS
sub tkPopupMenu_ApplyTheme( byval hPopup as TK_MENU ptr, byref t as TKTHEME_COLORS )
sub tkPopupMenu_Rescale( byval hPopup as TK_MENU ptr, byval fOld as single, byval fNew as single )
function tkPopupMenu_Create( byval hOwner as TK_HOST ptr, byval CtrlID as long = 0 ) as TK_MENU ptr
sub tkPopupMenu_Destroy( byval hPopup as TK_MENU ptr )
function tkPopupMenu_AddItem( byval hPopup as TK_MENU ptr, byval id as long, byval Caption as ustring, byval Accel as ustring = "", byval bDisabled as boolean = false, byval bChecked as boolean = false ) as long
function tkPopupMenu_AddSeparator( byval hPopup as TK_MENU ptr ) as long
function tkPopupMenu_GetItemCount( byval hPopup as TK_MENU ptr ) as long
function tkPopupMenu_SetItemText( byval hPopup as TK_MENU ptr, byval id as long, byval Caption as ustring, byval Accel as ustring = "" ) as boolean
function tkPopupMenu_SetItemEnabled( byval hPopup as TK_MENU ptr, byval id as long, byval bEnabled as boolean ) as boolean
function tkPopupMenu_GetItemEnabled( byval hPopup as TK_MENU ptr, byval id as long ) as boolean
function tkPopupMenu_SetItemChecked( byval hPopup as TK_MENU ptr, byval id as long, byval bChecked as boolean ) as boolean
function tkPopupMenu_GetItemChecked( byval hPopup as TK_MENU ptr, byval id as long ) as boolean
function tkPopupMenu_DeleteItem( byval hPopup as TK_MENU ptr, byval id as long ) as boolean
sub tkPopupMenu_Clear( byval hPopup as TK_MENU ptr )
function tkPopupMenu_SetItemSubMenu( byval hPopup as TK_MENU ptr, byval id as long, byval hSubMenu as TK_MENU ptr ) as boolean
function tkPopupMenu_GetItemSubMenu( byval hPopup as TK_MENU ptr, byval id as long ) as TK_MENU ptr
function tkPopupMenu_Show( byval hPopup as TK_MENU ptr, byval x as long, byval y as long ) as boolean
function tkPopupMenu_ShowForRect( byval hPopup as TK_MENU ptr, byref rcAnchor as TKRECT, byval nAlign as long ) as boolean
sub tkPopupMenu_Hide( byval hPopup as TK_MENU ptr )
sub tkPopupMenu_CloseChain( byval hPopup as TK_MENU ptr )
function tkPopupMenu_IsOpen( byval hPopup as TK_MENU ptr ) as boolean
function tkPopupMenu_GetOpenRoot() as TK_MENU ptr
function tkPopupMenu_GetCurSel( byval hPopup as TK_MENU ptr ) as long
function tkPopupMenu_SetCurSel( byval hPopup as TK_MENU ptr, byval idx as long ) as boolean
function tkPopupMenu_SelectFirst( byval hPopup as TK_MENU ptr ) as boolean
function tkPopupMenu_OpenSubMenu( byval hPopup as TK_MENU ptr, byval idx as long, byval bSelectFirst as boolean ) as boolean
function tkPopupMenu_GetItemRect( byval hPopup as TK_MENU ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkPopupMenu_HitTest( byval hPopup as TK_MENU ptr, byval x as long, byval y as long ) as long
function tkPopupMenu_GetIdealSize( byval hPopup as TK_MENU ptr, byref nWidth as long, byref nHeight as long ) as boolean
function tkPopupMenu_SetMinWidth( byval hPopup as TK_MENU ptr, byval nMinWidth as long ) as boolean
sub tkPopupMenu_SetItemHeight( byval hPopup as TK_MENU ptr, byval nItemHeight as long )
sub tkPopupMenu_SetSeparatorHeight( byval hPopup as TK_MENU ptr, byval nSeparatorHeight as long )
sub tkPopupMenu_SetSeparatorThickness( byval hPopup as TK_MENU ptr, byval nThickness as long )
sub tkPopupMenu_SetColors( byval hPopup as TK_MENU ptr, byval pColors as TKPOPUPMENU_COLORS ptr )
sub tkPopupMenu_GetColors( byval hPopup as TK_MENU ptr, byval pColors as TKPOPUPMENU_COLORS ptr )
sub tkPopupMenu_UnpinColors( byval hPopup as TK_MENU ptr )
sub tkPopupMenu_SetFonts( byval hPopup as TK_MENU ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr = 0 )
sub tkPopupMenu_ApplyFonts( byval hPopup as TK_MENU ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkPopupMenu_SetGlyphs( byval hPopup as TK_MENU ptr, byval wszCheck as ustring, byval wszChevron as ustring )
sub tkPopupMenu_SetSelectCallback( byval hPopup as TK_MENU ptr, byval usersub as PM_SelectCallbackSub )
sub tkPopupMenu_SetInitPopupCallback( byval hPopup as TK_MENU ptr, byval usersub as PM_InitPopupCallbackSub )
sub tkPopupMenu_SetPaintItemCallback( byval hPopup as TK_MENU ptr, byval usersub as PM_PaintItemCallbackSub )
sub tkPopupMenu_SetClosedCallback( byval hPopup as TK_MENU ptr, byval usersub as PM_ClosedCallbackSub )
sub tkPopupMenu_SetKeyHook( byval hPopup as TK_MENU ptr, byval userfunc as PM_KeyHookFunc )
function tkPopupMenu_Surface( byval hPopup as TK_MENU ptr ) as TK_HOST ptr
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
