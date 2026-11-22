[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTabControl**

# tkTabControl

Shows one page of controls at a time under a strip of tabs.

`tkTabControl` is the [tkControls](Category-tkControls) tab container. It is a [tkTabBar](tkTabBar) across the top and one [tkPanel](tkPanel) page for each tab. Only the page of the selected tab is visible. To put controls on a tab, make them children of `tkTabControl_GetPage( tab, index )`.

The control itself is never a tab stop; its bar is. The bar takes a fixed height (`tkTabControl_SetTabHeight`, in design units) and the pages fill the rest of the control. Pages are laid out again when the control is resized or the scale changes.

`tkTabControl_AddPage` appends a tab and its empty page. The first page added is selected; adding later ones leaves the selection where it is. `tkTabControl_SetCurSel` is silent: the selection callback runs only when the user changes the tab.

Its tabs are pages, not documents, so they have no close X. `tkTabControl_SetClosable( tab, true )` gives every tab one, including tabs added later; the Close callback then says which tab's X was used, and the program decides what closing means (`tkTabControl_DeletePage`, or nothing). `tkTabControl_SetFont` sets the strip's font. `tkTabControl_SetPageGlyph( tab, index, glyph )` draws a glyph before a page's caption, in the font `tkTabControl_SetGlyphFont` gives (with none, no glyph is drawn and the close X is a multiplication sign). The glyph box grows to fit a glyph font taller than the default one. For the rest of the strip's styling (colours, glyphs, one tab's X) use the bar that `tkTabControl_GetTabBar` returns, with the [tkTabBar](tkTabBar) functions.

`tkTabControl_SetPageVisible( tab, index, false )` hides a page: its tab leaves the strip, but the page, its controls and its caption stay, and `true` brings the tab back in its place among the others. So closing can mean hiding:

```freebasic
sub Tabs_Close( byval hTab as TK_WIDGET ptr, byval idx as long )
    tkTabControl_SetPageVisible( hTab, idx, false )
end sub
```

Every index the module takes or gives -- in the procedures and the callbacks -- is the page's: its place in creation order, hidden pages counted. It doesn't change when a page is hidden or the user drags a tab to a new place in the strip. A tab's place in the strip is the bar's business; each tab's item data holds its page's index, so leave `tkTabBar_SetItemData` alone on this control's bar.

## Importing

```freebasic
#import "vendor/tkControls/tkTabControl"

using tkTabControl
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and SDL_image), [tkTheme](tkTheme), [tkTabBar](tkTabBar) and [tkPanel](tkPanel).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
#import "vendor/tkControls/tkLabel"
using tkLabel

sub Tabs_Changed( byval hTab as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
    print "tab " & idxOld & " to " & idxNew
end sub

dim as TK_WIDGET ptr tabs = tkTabControl_Create( tkHost_Root( host ), 2400 )
tkTabControl_AddPage( tabs, "General" )
tkTabControl_AddPage( tabs, "Advanced" )
tkTabControl_SetSelChangeCallback( tabs, @Tabs_Changed )

dim as TK_WIDGET ptr page1 = tkTabControl_GetPage( tabs, 1 )
dim as TK_WIDGET ptr note = tkLabel_Create( page1, 2401 )
tkLabel_SetText( note, "Settings for experts." )
tkWidget_SetPos( note, tkHost_Scale( host, 12 ), tkHost_Scale( host, 12 ), _
                 tkHost_Scale( host, 200 ), tkHost_Scale( host, 24 ) )

tkTabControl_SetCurSel( tabs, 1 )          ' silent: no callback
tkWidget_SetPos( tabs, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkHost_Scale( host, 400 ), tkHost_Scale( host, 240 ) )
```

## Typed wrapper

The module also provides `TabControl`, a typed value for designed forms (see [tkForms](tkForms) and the [Form Designer](Form-Designer)). `TabControl.Handle` is the `TK_WIDGET ptr`. It has `Create( hParent, id )`, `SetFocus( )`, and these properties, each read and write:

`Enabled`, `Visible`, `TabHeight`, `Font`, `Closable`, `GlyphFont`, `SelectedIndex`.

Pages are added through the procedures, with `TabControl.Handle`.

## Behaviour notes

- `tkTabControl_InsertPage( h, idx, text )` inserts at `idx`; `-1`, or an index past the end, appends. It returns the new index, or -1 on failure. Inserting before the selected tab keeps the same page selected.
- `tkTabControl_DeletePage` destroys the tab, its page and everything on the page. Do not call it from inside an event callback of a control on that page; the Close callback is fine. It returns false for a bad index. Deleting the selected page selects its neighbour (the tab that takes its place in the strip, else the one before), silently.
- `tkTabControl_SetPageVisible` hiding the selected page selects its neighbour the same way, silently; showing one leaves the selection alone unless nothing was selected. It returns false for a bad index; hiding a hidden page, or showing a shown one, does nothing and returns true. `tkTabControl_GetPageVisible` says which.
- `tkTabControl_GetPageCount` counts every page, the hidden ones too. `tkTabControl_GetPageText`, `tkTabControl_SetPageText`, `tkTabControl_GetPageGlyph` and `tkTabControl_SetPageGlyph` work on a hidden page; the tab has the new caption and glyph when it comes back.
- `tkTabControl_SetGlyphFont` sets the glyph box to the font's height when that is taller than the default (`TKTABBAR_DEFAULT_ICONWIDTH`, scaled), else to the default. Setting the bar's icon width after it overrides that.
- `tkTabControl_SetCurSel` returns false for an index outside the pages or a hidden page, and changes nothing.
- `tkTabControl_GetCurSel` is -1 while no page is showing: no pages, or every one hidden.
- `tkTabControl_GetPage` returns 0 for an index outside the pages.
- `tkTabControl_SetTabHeight` is in design units and ignores a negative value. The default is `TKTABCONTROL_DEFAULT_TABHEIGHT`.
- The control's bar has control id 1, and the pages take ids from 100 up. Give your own controls ids that do not clash within the same parent.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKTABCONTROL_DEFAULT_TABHEIGHT = 30
```

### Types

```freebasic
type TKTABCONTROL_STATE   ' per-instance state; reach it through the procedures

type TC_SelChangeCallbackSub as sub( byval hTabControl as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
type TC_CloseCallbackSub as sub( byval hTabControl as TK_WIDGET ptr, byval idx as long )
```

### Procedures

```freebasic
function tkTabControl_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkTabControl_GetTabBar( byval h as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkTabControl_InsertPage( byval h as TK_WIDGET ptr, byval idx as long, byref text as const ustring ) as long
function tkTabControl_AddPage( byval h as TK_WIDGET ptr, byref text as const ustring ) as long
function tkTabControl_DeletePage( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabControl_SetPageVisible( byval h as TK_WIDGET ptr, byval idx as long, byval bVisible as boolean ) as boolean
function tkTabControl_GetPageVisible( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabControl_GetPageCount( byval h as TK_WIDGET ptr ) as long
function tkTabControl_GetPage( byval h as TK_WIDGET ptr, byval idx as long ) as TK_WIDGET ptr
function tkTabControl_GetPageText( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
function tkTabControl_SetPageText( byval h as TK_WIDGET ptr, byval idx as long, byref text as const ustring ) as boolean
function tkTabControl_GetCurSel( byval h as TK_WIDGET ptr ) as long
function tkTabControl_SetCurSel( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
function tkTabControl_GetTabHeight( byval h as TK_WIDGET ptr ) as long
sub tkTabControl_SetTabHeight( byval h as TK_WIDGET ptr, byval nHeight as long )
function tkTabControl_GetClosable( byval h as TK_WIDGET ptr ) as boolean
sub tkTabControl_SetClosable( byval h as TK_WIDGET ptr, byval bClosable as boolean )
function tkTabControl_SetPageGlyph( byval h as TK_WIDGET ptr, byval idx as long, byref glyph as const ustring ) as boolean
function tkTabControl_GetPageGlyph( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
sub tkTabControl_SetGlyphFont( byval h as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkTabControl_GetGlyphFont( byval h as TK_WIDGET ptr ) as TTF_Font ptr
function tkTabControl_GetFont( byval h as TK_WIDGET ptr ) as TTF_Font ptr
function tkTabControl_SetFont( byval h as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
sub tkTabControl_SetCloseCallback( byval h as TK_WIDGET ptr, byval usersub as TC_CloseCallbackSub )
sub tkTabControl_SetSelChangeCallback( byval h as TK_WIDGET ptr, byval usersub as TC_SelChangeCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme)
- [tkTabBar](tkTabBar), [tkPanel](tkPanel), [tkLayout](tkLayout)
