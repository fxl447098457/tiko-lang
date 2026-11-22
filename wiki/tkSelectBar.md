[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkSelectBar**

# tkSelectBar

Draws a strip of text panels where exactly one is current, marked by a line beneath it.

tkSelectBar is a flat, tab-like row of text labels: one panel is always the current one and carries an indicator line under its label. It suits switching the view of a panel underneath, such as an output pane's Results / Log / Notes, without the weight of a tab control. The panel set is static: add panels with `tkSelectBar_AddPanel` and remove them all with `tkSelectBar_Clear`; there is no insert or delete.

Exactly one panel is current. The first panel added becomes current silently, `tkSelectBar_SetCurSel` refuses -1 and disabled panels, and the current panel cannot be disabled. Panels can carry their own padding and tooltip text, and a paint callback can draw each panel yourself; `tkSelectBar_PaintPanelDefault( p )` in it draws the stock panel first.

Setters are silent; the SelChange callback fires only for a user's click or key. A click never takes the keyboard focus, so the bar does not pull the caret out of an editor, but the bar is a Tab stop.

## Importing

```freebasic
#import "vendor/tkControls/tkSelectBar"
using tkSelectBar
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` to write a panel paint callback.

## Example

`gHost` is the window ([tkHost](tkHost)); `gFont10` is a font opened with `tkHost_OpenFont`.

```freebasic
sub OnSelChange( byval hBar as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
    print "now showing panel id "; tkSelectBar_GetPanelID( hBar, idxNew )
end sub

dim as TK_WIDGET ptr bar = tkSelectBar_Create( tkHost_Root( gHost ), 1000 )
tkSelectBar_SetFont( bar, gFont10 )
tkSelectBar_SetSelChangeCallback( bar, @OnSelChange )

dim as long idx = tkSelectBar_AddPanel( bar, "COMPILER RESULTS", 1 )
tkSelectBar_SetTooltipText( bar, idx, "Errors and warnings from the last build" )
tkSelectBar_AddPanel( bar, "COMPILER LOG FILE", 2 )
idx = tkSelectBar_AddPanel( bar, "SEARCH RESULTS", 3 )
tkSelectBar_SetEnabled( bar, idx, false )
tkSelectBar_AddPanel( bar, "NOTES", 4 )
tkSelectBar_SetCurSel( bar, 1 )
tkSelectBar_SetIndicator( bar, tkHost_Scale( gHost, 3 ), tkHost_Scale( gHost, 6 ) )

tkWidget_SetPos( bar, 0, 0, tkSelectBar_GetIdealWidth( bar ), tkHost_Scale( gHost, 32 ) )
```

The toolchain's `examples/tkControls/tkSelectBar/` shows three bars: the default look, custom colours and padding, and a custom panel painter.

## Panels and selection

`tkSelectBar_Create( hParent, CtrlID )` creates the bar zero-sized; pass `tkHost_Root( h )` as the parent for a window's top level, and place it with `tkWidget_SetPos`. The panels are not widgets of their own: each is drawn in the bar's paint.

- Panels are addressed by 0-based index in the order they were added; with no insert or delete, an index is stable for the life of the bar. Each panel also carries an `id` and a free-form `itemData`; `tkSelectBar_FindPanelByID` maps an id back to an index, which keeps a `select case` on ids safe when a panel is added later.
- Exactly one panel is current. The first panel added becomes current, silently. `tkSelectBar_SetCurSel` returns false and changes nothing for -1, an invalid index or a disabled panel (true, silently, if it is already current). `tkSelectBar_SetEnabled( h, idx, false )` returns false for the current panel: switch away first, then disable. `tkSelectBar_GetCurSel` is -1 only between `tkSelectBar_Clear` and the next `tkSelectBar_AddPanel`.
- Disabling a panel that is hot or pressed clears that state at once and moves its tooltip off.
- `tkSelectBar_SetText` and the padding setters re-measure, shifting every panel to the right of the change.

## Layout

- A panel is as wide as its own label: `cell width = left padding + measured text width + right padding`. There is no equal-width or fill mode. The bar-wide padding (`tkSelectBar_SetPadding`) applies unless a panel overrides it with `tkSelectBar_SetPanelPadding`, where -1 on either side inherits the bar's value.
- The run starts at x = 0; the indent before the first label is panel 0's left padding. `tkSelectBar_GetIdealWidth` is the sum of every cell width, and is valid before the bar has ever been sized.
- One text height serves the whole bar (`tkSelectBar_GetTextHeight`, the font's height), so every label sits on the same baseline and every indicator on the same pixel row.
- The indicator spans the text, not the padded cell, and **text + gap + indicator** is centred vertically as one block. So the indicator thickness and gap (`tkSelectBar_SetIndicator`) are layout inputs: changing either moves the text as well as the line.
- Each panel has three derived rectangles, read with `tkSelectBar_GetPanelRect`, `GetPanelTextRect` and `GetPanelIndicatorRect`: the full cell at full bar height (the fill and hit rectangle), exactly the measured text box, and the indicator under it.
- Layout is lazy: a change marks it stale and the next paint or rectangle query recomputes it, so a run of `AddPanel` calls costs one measuring pass. The queries return true for any valid index, but the rectangles stay empty while the bar has no size.
- When the panels are wider than the bar, the tail is clipped at the edge; there is no scrolling. A panel past the edge cannot be clicked, since interaction requires the cursor inside the bar.
- The defaults (padding 12, indicator 2, gap 4, focus-ring inset 2) are scaled when the bar is created. Every setter afterwards takes raw pixels, so scale your own values (`tkHost_Scale`). A display-scale change rescales the padding, the per-panel padding overrides, the indicator and the focus-ring inset on its own.
- The font is a `TTF_Font ptr` the bar borrows and never frees; with none set, the host's default font is used for both measuring and drawing. `tkSelectBar_SetFont` re-lays out the whole bar. `tkSelectBar_ApplyFonts` sets the text font (0 keeps the current one); the bar has no glyph font.

## Mouse and keyboard

- Pressing the left button over an enabled panel captures the mouse and arms that panel; the selection moves on **release**, and only if the release lands on the same panel. Press, slide off, release, and the selection does not move. While the cursor is off the panel it stops painting as pressed; sliding back re-arms it. Losing the capture cancels the press.
- A press never takes the keyboard focus, so the bar does not pull the caret out of an editor.
- Clicking the panel that is already current is not a change and notifies nothing.
- A double click arrives as a second `TKM_LBUTTONDOWN` with `clicks = 2` and is handled as an ordinary press, followed by its own `TKM_LBUTTONUP`. The bar gives a double click no meaning of its own; implement one in the message callback. If your double-click action reverses what the single click did, consume the up that follows it yourself.
- The right button is reported to the message callback and otherwise ignored; a context menu is yours to show. No capture is taken for it.
- Hot tracking follows the cursor; disabled panels are never hot, and the hot panel clears when the mouse leaves.
- The bar is a Tab stop. Left / Right move the selection to the next enabled panel, skipping disabled ones and never wrapping; Home / End go to the first / last enabled panel. A key is a user action, so it notifies. Up / Down, Space and Enter are not claimed and pass on to the parent.
- While the bar has the focus, a 1-pixel ring is drawn round the current panel's cell, inset by the focus gap.
- Disabling the whole widget with `tkWidget_Enable` cancels any press, clears the hot panel, closes the tooltip and greys every label; the indicator stays.
- `tkSelectBar_HitTest` answers geometry only: it includes disabled panels and does not require the point to be inside the bar. The hover and click paths add both tests, so the message callback's `idx` can be -1 where `HitTest` returns a panel.

## Tooltips

One [tkTooltip](tkTooltip) covers the whole bar and follows the hot panel. Its text is resolved when a tip is about to show: the panel's own text (`tkSelectBar_SetTooltipText`), otherwise the tooltip callback, otherwise no tip. There is deliberately no fallback to the caption, which is already on screen. A press closes a showing tip, and `tkSelectBar_Clear` moves the tip off the panels it removed. The hover delay defaults to 250 ms (`tkSelectBar_SetHoverTime`); `tkSelectBar_SetAutoPopTime` and `tkSelectBar_SetReshowTime` set the tip's other delays, and `tkSelectBar_GetTooltipHandle` returns the tip itself.

## Colours and theme

`TKSELECTBAR_COLORS` holds nine colours. The bar takes them from the current theme when it is created (including any theme recipe for `"SelectBar"`) and follows every theme change.

| Colour | Paints | Theme role |
|---|---|---|
| `BackColor` | The bar's background and an idle panel's cell | `Window` |
| `ForeColor` | An idle panel's label | `TextDim` |
| `BackColorHot` | The cell when hot or pressed | `Window` |
| `ForeColorHot` | The label when hot or pressed | `TextHot` |
| `BackColorSelect` | The current panel's cell | `Window` |
| `ForeColorSelect` | The current panel's label | `TextStrong` |
| `ForeColorDisabled` | A disabled panel's label | `TextDisabled` |
| `IndicatorColor` | The line under the current panel | `TextStrong` |
| `FocusRingColor` | The keyboard focus ring | `FocusRing` |

`BackColorHot` and `BackColorSelect` equal `BackColor` out of the box: the flat look, where only the label colour and the indicator move. Give them other values for filled hover or selected cells. A disabled panel keeps `BackColor` and changes only its label.

The built-in painter fills the whole bar with `BackColor`, then for each panel picks one fill and one label colour in the order **disabled > pressed = hot > selected > idle**, fills the cell, draws the label centred in its text rectangle, draws the indicator (current panel only) last so a `BackColorSelect` cannot cover it, and finally the focus ring.

`tkSelectBar_SetColors` copies a struct and pins it, so a theme change leaves this bar alone; `tkSelectBar_UnpinColors` hands the bar back to the theme and applies it at once. `tkSelectBar_ThemeColors( t )` builds the struct from a theme.

## Callbacks

- **SelChange** `( hSelectBar, idxOld, idxNew )` reports a user selection: a press and release on the same enabled panel, or a key. It fires after the state is updated, so `tkSelectBar_GetCurSel` already equals `idxNew`. It never fires for `tkSelectBar_SetCurSel`, so that setter is safe inside the handler.
- **PaintPanel** draws each panel instead of the built-in painter (for every panel; there is no per-panel opt-in). `tkSelectBar_PaintPanelDefault( p )` draws the stock panel, to add to it. Paint through `p->b` and fill `p->rc`, the whole cell; the bar's background is already down, and a fill covering the whole widget would erase the panels drawn before it. Use the rectangles as handed: `p->rcText` is exactly the measured text and `p->rcIndicator` sits under it. Draw with the bar's font (`tkSelectBar_GetFont`, or the host's default when that is 0), or the measured widths lie. `p->isPressed` is true only while a live press is on this panel and the cursor is still over it; `p->isFocused` is true for the current panel while the bar has the focus; `p->isEnabled` is false for every panel while the whole widget is disabled.
- **Message** observes `TKM_MOUSEMOVE`, `TKM_MOUSELEAVE`, `TKM_LBUTTONDOWN`, `TKM_LBUTTONUP`, `TKM_RBUTTONDOWN` and `TKM_RBUTTONUP`, with `x`, `y` (bar-local), `clicks` and `idx`, the panel under the mouse for interaction: -1 for none, a disabled panel or a point outside the bar, and always -1 for `TKM_MOUSELEAVE`. Returning true from `TKM_LBUTTONDOWN` suppresses the press; for every other message the return value is ignored (the left-button up is what releases the capture). On a release, the message callback runs before SelChange.
- **Tooltip** `( hSelectBar, idx )` supplies a panel's tip text, consulted only for panels with none of their own; return `""` for no tip.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKSELECTBAR_DEFAULT_PADLEFT = 12
const as long TKSELECTBAR_DEFAULT_PADRIGHT = 12
const as long TKSELECTBAR_DEFAULT_INDICATORH = 2
const as long TKSELECTBAR_DEFAULT_INDICATORGAP = 4
const as long TKSELECTBAR_DEFAULT_FOCUSGAP = 2
const as long TKSELECTBAR_FOCUSTHICK = 1
```

### Types

```freebasic
type TKSELECTBAR_COLORS
    BackColor         as ulong = &hFF21252Bul    ' ( 33, 37, 43) bar background + idle cell
    ForeColor         as ulong = &hFF969CA6ul    ' (150,156,166) idle label
    BackColorHot      as ulong = &hFF21252Bul
    ForeColorHot      as ulong = &hFFD7DAE0ul    ' (215,218,224)
    BackColorSelect   as ulong = &hFF21252Bul
    ForeColorSelect   as ulong = &hFFFFFFFFul
    ForeColorDisabled as ulong = &hFF5A606Aul    ' ( 90, 96,106)
    IndicatorColor    as ulong = &hFFFFFFFFul    ' the line under the current panel
    FocusRingColor    as ulong = &hFF61AFEFul    ' ADDED: the keyboard focus ring ( 97,175,239)
end type

type TKSELECTBAR_PANEL
    wszText     as ustring
    wszTooltip  as ustring            ' "" = ask the tooltip callback, then nothing
    id          as long = 0
    itemData    as integer = 0
    isEnabled   as boolean = true
    nPadLeft    as long = -1          ' -1 = inherit the bar's
    nPadRight   as long = -1
    nTextW      as long = 0
    nCellWidth  as long = 0
    rc          as TKRECT             ' the full cell: the FILL and HIT rect
    rcText      as TKRECT             ' exactly the measured text box
    rcIndicator as TKRECT             ' spans rcText, gap below it
end type

type TKSELECTBAR_PAINTINFO
    hSelectBar  as TK_WIDGET ptr
    itemID      as long
    b           as TK_PAINT ptr       ' this repaint's painter (borrowed)
    rc          as TKRECT             ' fill THIS
    rcText      as TKRECT
    rcIndicator as TKRECT
    isHot       as boolean
    isSelected  as boolean
    isPressed   as boolean            ' live left press on this panel AND the cursor still on it
    isEnabled   as boolean
    isFocused   as boolean            ' ADDED: the bar has keyboard focus and this is current
    wszCaption  as ustring
end type

type TKSELECTBAR_MESSAGEINFO
    hSelectBar  as TK_WIDGET ptr
    msg         as long               ' TKM_*
    x           as single             ' widget-local pixels
    y           as single
    clicks      as long
    idx         as long               ' the INTERACTION index: -1 for none, disabled, outside
end type

type TKSELECTBAR_STATE   ' per-instance state; reach it through the procedures

type SEL_PaintPanelCallbackSub as sub( byval p as TKSELECTBAR_PAINTINFO ptr )
type SEL_MessageCallbackFunc as function( byval m as TKSELECTBAR_MESSAGEINFO ptr ) as boolean
type SEL_TooltipCallbackFunc as function( byval hSelectBar as TK_WIDGET ptr, byval idx as long ) as ustring
type SEL_SelChangeCallbackSub as sub( byval hSelectBar as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
```

### Procedures

```freebasic
function tkSelectBar_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkSelectBar_AddPanel( byval hSelectBar as TK_WIDGET ptr, byval Text as ustring, byval id as long = 0, byval itemData as integer = 0 ) as long
sub tkSelectBar_Clear( byval hSelectBar as TK_WIDGET ptr )
sub tkSelectBar_Refresh( byval hSelectBar as TK_WIDGET ptr )
function tkSelectBar_GetCount( byval hSelectBar as TK_WIDGET ptr ) as long
function tkSelectBar_IsValidPanel( byval hSelectBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkSelectBar_FindPanelByID( byval hSelectBar as TK_WIDGET ptr, byval id as long ) as long
function tkSelectBar_HitTest( byval hSelectBar as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkSelectBar_GetText( byval hSelectBar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkSelectBar_SetText( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkSelectBar_GetPanelID( byval hSelectBar as TK_WIDGET ptr, byval idx as long ) as long
function tkSelectBar_SetPanelID( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byval id as long ) as boolean
function tkSelectBar_GetItemData( byval hSelectBar as TK_WIDGET ptr, byval idx as long ) as integer
function tkSelectBar_SetItemData( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byval itemData as integer ) as boolean
function tkSelectBar_GetEnabled( byval hSelectBar as TK_WIDGET ptr, byval idx as long ) as boolean
function tkSelectBar_SetEnabled( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byval isEnabled as boolean ) as boolean
function tkSelectBar_GetCurSel( byval hSelectBar as TK_WIDGET ptr ) as long
function tkSelectBar_SetCurSel( byval hSelectBar as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkSelectBar_GetPadding( byval hSelectBar as TK_WIDGET ptr, byref nPadLeft as long, byref nPadRight as long )
sub tkSelectBar_SetPadding( byval hSelectBar as TK_WIDGET ptr, byval nPadLeft as long, byval nPadRight as long )
function tkSelectBar_SetPanelPadding( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byval nPadLeft as long, byval nPadRight as long ) as boolean
sub tkSelectBar_GetIndicator( byval hSelectBar as TK_WIDGET ptr, byref nThickness as long, byref nGap as long )
sub tkSelectBar_SetIndicator( byval hSelectBar as TK_WIDGET ptr, byval nThickness as long, byval nGap as long )
function tkSelectBar_GetPanelRect( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkSelectBar_GetPanelTextRect( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkSelectBar_GetPanelIndicatorRect( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkSelectBar_GetIdealWidth( byval hSelectBar as TK_WIDGET ptr ) as long
sub tkSelectBar_GetColors( byval hSelectBar as TK_WIDGET ptr, byval pColors as TKSELECTBAR_COLORS ptr )
sub tkSelectBar_SetColors( byval hSelectBar as TK_WIDGET ptr, byval pColors as TKSELECTBAR_COLORS ptr )
function tkSelectBar_ThemeColors( byref t as TKTHEME_COLORS ) as TKSELECTBAR_COLORS
sub tkSelectBar_ApplyTheme( byval hSelectBar as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkSelectBar_UnpinColors( byval hSelectBar as TK_WIDGET ptr )
function tkSelectBar_GetFont( byval hSelectBar as TK_WIDGET ptr ) as TTF_Font ptr
function tkSelectBar_SetFont( byval hSelectBar as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
sub tkSelectBar_ApplyFonts( byval hSelectBar as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
function tkSelectBar_GetTooltipHandle( byval hSelectBar as TK_WIDGET ptr ) as TK_TIP ptr
sub tkSelectBar_SetHoverTime( byval hSelectBar as TK_WIDGET ptr, byval milliseconds as long )
sub tkSelectBar_SetAutoPopTime( byval hSelectBar as TK_WIDGET ptr, byval milliseconds as long )
sub tkSelectBar_SetReshowTime( byval hSelectBar as TK_WIDGET ptr, byval milliseconds as long )
function tkSelectBar_GetTooltipText( byval hSelectBar as TK_WIDGET ptr, byval idx as long ) as ustring
function tkSelectBar_SetTooltipText( byval hSelectBar as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
sub tkSelectBar_PaintPanelDefault( byval p as TKSELECTBAR_PAINTINFO ptr )
sub tkSelectBar_SetPaintPanelCallback( byval hSelectBar as TK_WIDGET ptr, byval usersub as SEL_PaintPanelCallbackSub )
sub tkSelectBar_SetMessageCallback( byval hSelectBar as TK_WIDGET ptr, byval userfunc as SEL_MessageCallbackFunc )
sub tkSelectBar_SetTooltipCallback( byval hSelectBar as TK_WIDGET ptr, byval userfunc as SEL_TooltipCallbackFunc )
sub tkSelectBar_SetSelChangeCallback( byval hSelectBar as TK_WIDGET ptr, byval usersub as SEL_SelChangeCallbackSub )
function tkSelectBar_GetHot( byval hSelectBar as TK_WIDGET ptr ) as long
function tkSelectBar_GetPressed( byval hSelectBar as TK_WIDGET ptr ) as long
function tkSelectBar_GetFocused( byval hSelectBar as TK_WIDGET ptr ) as boolean
function tkSelectBar_GetTextHeight( byval hSelectBar as TK_WIDGET ptr ) as long
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
