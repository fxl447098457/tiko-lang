[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkColumnHeader**

# tkColumnHeader

Draws a band of column headings with draggable dividers and one column taking the rest.

tkColumnHeader is the heading strip above a report or grid: one cell per column, a divider between cells that the user drags to resize, and one **fill column** that absorbs the width left over (the last column by default, or none). Widths are in pixels with a per-column minimum. The control reports clicks, width changes and divider double-clicks; it never sorts, and never lays out anything but itself.

Use it above any list whose columns you draw yourself. [tkListTree](tkListTree) builds one in for its report mode, so you only create a tkColumnHeader directly for your own grid.

Without a paint callback the header draws itself: hover and press fills, the caption with an ellipsis, a sort triangle and a divider tick. Your program sets the sort indicator with `tkColumnHeader_SetSortColumn`, usually from the Click callback. A paint callback can call `tkColumnHeader_PaintColumnDefault` and draw on top. Setters are silent; the header never takes the keyboard focus.

## Importing

```freebasic
#import "vendor/tkControls/tkColumnHeader"
using tkColumnHeader
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` to write a paint callback.

## Example

`gHost` is the window ([tkHost](tkHost)); `gFont9b` is a font opened with `tkHost_OpenFont`.

```freebasic
sub OnClick( byval hHdr as TK_WIDGET ptr, byval idx as integer )
    dim as boolean bDesc = (tkColumnHeader_GetSortColumn( hHdr ) = idx) andalso _
                           (tkColumnHeader_GetSortDirection( hHdr ) = HDR_SORT_ASC)
    tkColumnHeader_SetSortColumn( hHdr, idx, iif( bDesc, HDR_SORT_DESC, HDR_SORT_ASC ) )
    ' ... sort your rows by column idx and repaint them
end sub

sub OnWidth( byval hHdr as TK_WIDGET ptr, byval idx as integer, byval nWidth as integer, byval bLive as boolean )
    ' bLive is true while the divider is dragged, false once at the end
end sub

function OnAutoSize( byval hHdr as TK_WIDGET ptr, byval idx as integer ) as integer
    return tkText_Width( gFont9b, tkColumnHeader_GetColumnText( hHdr, idx ) ) + _
           2 * tkColumnHeader_GetPadding( hHdr )
end function

dim as TK_WIDGET ptr hdr = tkColumnHeader_Create( tkHost_Root( gHost ), 1 )
tkColumnHeader_SetFont( hdr, gFont9b )
tkColumnHeader_AddColumn( hdr, "Name", tkHost_Scale( gHost, 200 ) )
tkColumnHeader_AddColumn( hdr, "Size", tkHost_Scale( gHost, 90 ), tkHost_Scale( gHost, 50 ) )
tkColumnHeader_AddColumn( hdr, "Type" )                ' the fill column
tkColumnHeader_SetClickCallback( hdr, @OnClick )
tkColumnHeader_SetWidthChangedCallback( hdr, @OnWidth )
tkColumnHeader_SetAutoSizeCallback( hdr, @OnAutoSize )
```

The toolchain's `examples/tkControls/tkColumnHeader/` sorts a table from the header and shows a paint callback over the built-in painter.

## Concepts

### The handle is the widget

`tkColumnHeader_Create( parent, id )` takes a `TK_WIDGET ptr` parent (for a top-level header,
`tkHost_Root( h )`) and returns the header as a `TK_WIDGET ptr`; every `tkColumnHeader_*` call
takes it. `id` is the control id, read back with `tkColumnHeader_GetID`. The header is created
at 0,0 with no size: place and size it with `tkWidget_SetPos`. It has no intrinsic height, and
every column spans the full height you give it.

### Widths are pixels

Column widths, minimum widths, the caption padding and the X offset are all **pixels**, stored
and used as given; scale your literals with `tkHost_Scale`. The control's own defaults are
scaled for you: the caption padding once at create, the divider gutter and the default minimum
width each time they are consulted. A padding you set yourself is taken as raw pixels.

When the host's scale changes (`TKM_SCALECHANGED`), the header rescales every column's width
and minimum, the padding and the X offset itself, and lays out again. Nothing is notified.

### Geometry is derived, never assigned

You set widths; the control computes rects. There is no way to write a rect.

```
  for each fixed column:  w = max( nWidth, effectiveMinWidth )
  fill column:            w = max( widgetWidth - sum(fixed widths), its effectiveMinWidth )

  x starts at -xOffset, and each column is
      rc = ( x, 0, x + w, widgetHeight )
  laid left to right, contiguous, spanning the full height.
```

`effectiveMinWidth` is the column's own `nMinWidth`, or, when that is 0, the scaled
`CCOLHDR_DEFAULT_MINWIDTH` of 16 pixels. A column can never be laid out or dragged below it.

Layout is lazy. Every mutator marks it stale and repaints; the next paint, or any query that
needs a rect, recomputes it. While the header has no size yet, layout does nothing and stays
stale, so the first real `tkWidget_SetPos` recomputes it.

### Exactly one column can be the fill column

The fill column absorbs whatever width the fixed columns leave over. It **shrinks as well as
grows** with the header, but never below its own minimum, so no dead strip appears to the right
of the last column when the window widens.

`tkColumnHeader_SetFillColumn` takes three kinds of value:

| Value | Meaning |
|---|---|
| `CCOLHDR_FILL_LAST` | Whichever column is currently last (**the default**) |
| `CCOLHDR_FILL_NONE` | No fill column; columns end where their widths end |
| a column index | That specific column, tracked across inserts and deletes |

`tkColumnHeader_GetFillColumn` returns the **resolved** index, or -1 for none.

A stored index looks after itself: inserting at or before it shifts it up, deleting before it
shifts it down, and deleting the fill column itself falls back to `CCOLHDR_FILL_LAST`.
`tkColumnHeader_Clear` resets the designation to `CCOLHDR_FILL_LAST` as well.

**The fill column's own right-hand divider is not grabbable**, since its width is derived. The
painter is told which column that is (`isFill`) so it can omit the divider tick.

### On overflow, the rects run honestly past the edge

When the columns are collectively wider than the header, the layout does not squeeze them: the
later rects extend past the right edge. Clipping is the paint pass's job, and columns wholly
outside the header are not painted at all.

There is no horizontal scrolling. `tkColumnHeader_SetXOffset` shifts the whole column run left
by a pixel amount and every rect follows, which is the hook a horizontal scrollbar would drive;
nothing in the control moves it for you, and it is 0 unless you set it.

### Padding is a paint-time value

`tkColumnHeader_GetPadding` is the inset the built-in painter gives the caption, and the one a
paint callback should honour. The control does not measure text and does not use the padding in
the layout. Read it in your paint callback and in your auto-fit measurement, so captions and the
cells you draw underneath line up.

### The divider gutter

A boundary is grabbable within ± `CCOLHDR_DIVIDER_GUTTER` (3, scaled) pixels of a column's right
edge. Inside a gutter the gesture is a resize, not a column press, which is why the message
callback's `idx` is -1 there even though the cursor is over a column, and why the cursor shows
`TK_CURSOR_SIZEWE`.

When two boundaries nearly coincide, because a column sits at its minimum width, the gutters
are tested right to left, so the later divider wins.

### The sort indicator

The control never sorts. The click callback is the hook: reorder your own rows, then set the
indicator with `tkColumnHeader_SetSortColumn( h, idx, nDir )`, where `nDir` is `HDR_SORT_ASC`,
`HDR_SORT_DESC` or `HDR_SORT_NONE`. An invalid index or `HDR_SORT_NONE` clears it. The built-in
painter draws an accent triangle at the right end of that column, pointing up for ascending and
down for descending; a paint callback receives it as `nSortDir`, which is `HDR_SORT_NONE` for
every other column.

The indicator follows its column across inserts and deletes. Deleting the sorted column, or
`tkColumnHeader_Clear`, clears it. `tkColumnHeader_SetSortColumn` is silent: it repaints and
calls nothing.

### Programmatic changes are silent

`tkColumnHeader_SetColumnWidth` stores a width, re-lays out and repaints, but fires **no**
WidthChanged callback. That notification is reserved for the user: a divider drag or an applied
auto-fit. You can call the setter from inside your own WidthChanged handler without recursing.

### Interaction, and what capture buys

The header takes the mouse capture on a left press, before the message callback runs, because
both of its gestures rely on the matched down and up:

- **Divider drag.** The width is applied live: every mouse move that actually changes it stores
  the clamped value, re-lays out, repaints, and fires WidthChanged with `bLive = true`.
  Releasing fires one final notification with `bLive = false`. Pressing **Escape** mid-drag,
  losing the capture, or disabling the header restores the pre-drag width and fires that final
  notification carrying the restored value, so a host that consumed the live updates converges
  back on its own. Escape reaches the header even though it never has the focus: the host sends
  Escape to the widget holding the capture first.
- **Column body click.** The click fires only on a matched gesture: pressed on a column's body
  and released still on it, outside any divider gutter. Press, slide off, release does nothing.

Hover tracking is **suspended for the whole drag**: with the capture held the cursor roams
outside the header, and clearing the hot column there would strip the resize visuals. When the
button comes up, hover is re-derived from where the cursor finished.

### Double-clicks

A double click arrives as `TKM_LBUTTONDOWN` with a click count of 2.

- **On a divider**, the second press asks your AutoSize callback for a best-fit width and
  applies it instead of starting a drag. The first press of the pair was an ordinary divider
  press and release, so it has already sent one `bLive = false` notification with the width
  unchanged.
- **On a column body**, the second press is an ordinary press. A rapid double click on a caption
  fires the click callback **twice**, one per matched press and release. If your click handler
  toggles a sort direction that is what you want; if it is destructive, guard it.

### Tooltips

One tip covers the whole band, its text resolved on demand for whichever column is hot. With no
tooltip callback the column's own caption is used; with one, whatever it returns, and `""`
suppresses the tip. The tip hides when the hot column changes, so the next hover re-queries, and
it hides on a press and when the mouse leaves. A cursor in a divider gutter has no hot column and
gets no tip.

`tkColumnHeader_SetHoverTime` sets the dwell before a tip appears (250 ms by default),
`tkColumnHeader_SetAutoPopTime` how long a shown tip stays up, and
`tkColumnHeader_SetReshowTime` the delay when the cursor moves to another column while a tip is
up. A negative time is taken as 0; a delay you never set keeps the tooltip's own default.
`tkColumnHeader_GetTooltipHandle` returns the header's `TK_TIP ptr` for anything else
[tkTooltip](tkTooltip) offers.

### Fonts and lifetime

The font is a `TTF_Font ptr` and is **borrowed**: the header stores it and never closes it.
Without one, the built-in painter uses the host's default font. The font drives no layout, and a
paint callback is free to use a different one per column. `tkColumnHeader_ApplyFonts` sets the
text font when it is not 0; the header has no glyph font.

The header frees its state and its tooltip when the widget is destroyed.

## Behaviour and limits

- **Never focusable.** A header must not steal the caret from whatever the host is editing. The
  only key it handles is Escape during a divider drag.
- **The header has no intrinsic height**, and every column spans it. There are no sub-rows and
  no column groups.
- **Widths are stored, never measured.** The control does not look at your captions, your font
  or your data, which is why auto-fit has to ask you.
- **Padding does not affect layout.** The built-in painter ends a caption wider than its cell
  with an ellipsis; a paint callback handles that itself.
- **A column can never go below its effective minimum**, by drag, by layout, by auto-fit or by
  `tkColumnHeader_SetColumnWidth`.
- **`tkColumnHeader_GetColumnWidth` on the fill column reports its laid-out width**, not the
  stored one. Setting a width on the fill column stores it but has no visual effect until that
  column stops being the fill.
- **`tkColumnHeader_SetColumnMinWidth` does not rewrite a smaller stored width.** The clamp is
  applied at layout and when the width is read, so `tkColumnHeader_GetColumnWidth` reflects it
  at once.
- **The fill column's divider is not grabbable**, and its gutter is not hit-tested at all.
- **A body double-click fires the click callback twice.**
- **The message callback can suppress only the left press.** Its answer is ignored for every
  other message; see [Message](#message).
- **The right mouse button is reported, never acted on.** No capture is taken for it, so a
  right-up can arrive without a matching down. A context menu is your business.
- **No horizontal scrolling.** `tkColumnHeader_SetXOffset` works, but nothing drives it for you.
- **No sorting, no column reordering by drag, no hidden columns.** The sort indicator is only a
  marker you set.
- **Inserting, deleting or clearing columns abandons any live press or drag** without firing
  callbacks (a dragged width stays where the drag left it), and clears the hover state: a gesture
  whose target just shifted is ambiguous, so it is dropped rather than guessed at.
- **Disabled** (`tkWidget_Enable`), the header cancels a drag (restoring the width, with the
  final notification), drops any press and its hover, and takes no mouse input.

## Procedures in brief

Every procedure takes the header from `tkColumnHeader_Create` first, written `h` below. Each
returns its failure value (FALSE, 0, -1 or `""`) for an invalid index.

### Columns

| Procedure | Description |
|---|---|
| `tkColumnHeader_AddColumn( h, Text, nWidth, nMinWidth, itemData )` | Appends a column and returns its index, or -1. A `nWidth` of 0 or less gives the 100-pixel default; a `nMinWidth` of 0 or less stores 0, meaning the scaled default floor. |
| `tkColumnHeader_InsertColumn( h, idx, Text, nWidth, nMinWidth, itemData )` | Inserts at `idx`, clamped to `[0, count]`, and returns the index used. A stored fill index and the sort column shift up with it. |
| `tkColumnHeader_DeleteColumn( h, idx )` | Deletes the column. A stored fill index shifts down, or falls back to `CCOLHDR_FILL_LAST` if it was the deleted column; the sort column shifts down, or clears. |
| `tkColumnHeader_Clear( h )` | Removes every column, resets the fill designation to `CCOLHDR_FILL_LAST` and clears the sort indicator. |
| `tkColumnHeader_GetCount( h )` | How many columns are defined. |
| `tkColumnHeader_Refresh( h )` | Marks the layout stale and repaints. Rarely needed, since every mutator does it; useful after changing host state a paint callback reads. |
| `tkColumnHeader_SetColumnText( h, idx, Text )` | Sets the caption and repaints. Captions never drive layout. |
| `tkColumnHeader_SetColumnItemData( h, idx, itemData )` | Sets the column's user value. Does not repaint; the control never draws it. |

### Geometry

| Procedure | Description |
|---|---|
| `tkColumnHeader_GetColumnWidth( h, idx )` | The width, already raised to the effective minimum; for the fill column, its laid-out width. |
| `tkColumnHeader_SetColumnWidth( h, idx, nWidth )` | Stores the width, clamped up to the effective minimum, re-lays out and repaints. **Silent.** Called on the column whose divider is being dragged, the new value becomes the drag's base: a later Escape restores to it, and the drag resumes from it at the current cursor position. |
| `tkColumnHeader_GetColumnMinWidth( h, idx )` | The column's **own stored** minimum; 0 means the control default. |
| `tkColumnHeader_SetColumnMinWidth( h, idx, nMinWidth )` | Sets it (negatives become 0), re-lays out and repaints. |
| `tkColumnHeader_SetFillColumn( h, idx )` | A column index, `CCOLHDR_FILL_LAST` or `CCOLHDR_FILL_NONE`; FALSE for anything else. |
| `tkColumnHeader_GetColumnRect( h, idx, rc )` | The column's rect in widget pixels, after any pending layout; an embedding host reads its cell x-coordinates from here. FALSE, with `rc` emptied, for an invalid index. |
| `tkColumnHeader_HitTestDivider( h, x, y )` | The column whose right-hand gutter holds this widget-local point, or -1. Tested right to left; the fill column's divider is never reported. |
| `tkColumnHeader_HitTestColumn( h, x, y )` | The column whose rect holds the point, or -1. Gutters are not excluded. |
| `tkColumnHeader_SetPadding( h, nPadding )` | Raw pixels (negatives become 0). Repaints but never re-lays out. |
| `tkColumnHeader_SetXOffset( h, xOffset )` | Shifts the whole run left; negatives become 0, and the value it already has does nothing. |

### State

`tkColumnHeader_GetHotColumn` (the body under the mouse), `tkColumnHeader_GetHotDivider` (the
gutter under the mouse), `tkColumnHeader_GetPressedColumn` (a live body press) and
`tkColumnHeader_GetDragColumn` (the column whose divider is being dragged) each return -1 for
none. They are the same values the paint callback receives as flags.

## Colours

The built-in painter uses the nine colours of `TKCOLUMNHEADER_COLORS`:

| Colour | Paints | Theme role |
|---|---|---|
| `BackColor` | The whole band, before any column is painted, every repaint. It also covers any strip no column owns, such as the far right with `CCOLHDR_FILL_NONE` | `Surface` |
| `BackColorHot` | The hot column's cell | `SurfaceHot` |
| `BackColorPressed` | The pressed column's cell | `Selected` |
| `ForeColor` | A caption, idle | `TextDim` |
| `ForeColorHot` | The hot column's caption | `TextHot` |
| `ForeColorPressed` | The pressed column's caption | `SelectedText` |
| `DividerColor` | The divider tick, 1 pixel at each column's right edge but the fill's | `Border` |
| `DividerColorHot` | The divider tick, 2 pixels, while its gutter is hot or dragged | `FocusRing` |
| `SortMarkColor` | The sort triangle | `Accent` |

A cell is pressed over hot over plain; a plain cell gets no fill of its own, so `BackColor` shows
through.

The header takes its colours from the current theme when it is created (including any theme
recipe for `"ColumnHeader"`) and follows every theme change. `tkColumnHeader_SetColors` sets all
nine and pins them, so a theme change leaves this header alone; `tkColumnHeader_SetBackColor`
sets the band colour, returns the previous one, and pins as well. `tkColumnHeader_UnpinColors`
hands the header back to the theme and applies it at once. `tkColumnHeader_GetColors` reads the
colours in force, `tkColumnHeader_ThemeColors` gives the theme mapping as a value, and
`tkColumnHeader_ApplyTheme` applies a given theme to an unpinned header.

A paint callback is handed the state flags and chooses its own colours; only `BackColor` is
still painted for it.

## Callbacks

All six are optional. Passing 0 clears a callback; clearing the paint callback restores the
built-in painter.

### Paint

```freebasic
type HDR_PaintCallbackSub as sub( byval p as TKCOLUMNHEADER_PAINTINFO ptr )
```

Draws one column's cell instead of the built-in painter. It is called for each column at least
partly inside the header, clipped to that column's rect, after the whole band has been filled
with `BackColor`. Paint through `p->b` inside `p->rc`, and inset the caption by
`tkColumnHeader_GetPadding( p->hHeader )`. To draw the stock cell and add to it, call
`tkColumnHeader_PaintColumnDefault( p )` first.

| Field | Meaning |
|---|---|
| `hHeader` | The control, so the callback can query it |
| `itemID` | The column index |
| `b` | The paint context for this repaint (borrowed, not owned) |
| `rc` | This column's rect, in widget pixels |
| `isHot` | The mouse is over this column's **body** |
| `isPressed` | A live left press on this column's body; never set for a divider drag |
| `isResizeHot` | The cursor is in this column's right-hand divider gutter |
| `isResizing` | This column's divider is being dragged right now |
| `isFill` | This is the effective fill column: draw no divider tick |
| `wszCaption` | The column's text |
| `nSortDir` | `HDR_SORT_ASC` or `HDR_SORT_DESC` on the sort column, `HDR_SORT_NONE` elsewhere |

At most one column is hot and at most one pressed. `isResizeHot` and `isHot` never hold for the
same column, because a gutter hit takes the body hit away. While `isResizing` is set, hover is
frozen, so `isHot` keeps the value it had when the drag started.

### Message

```freebasic
type HDR_MessageCallbackFunc as function( byval m as TKCOLUMNHEADER_MESSAGEINFO ptr ) as boolean
```

Observes the header's mouse messages. `TKCOLUMNHEADER_MESSAGEINFO` carries `hHeader`, `msg` (a
`TKM_*` value), widget-local `x` / `y`, and `idx`. Return TRUE to suppress the control's own
handling, which only a left press honours:

| Message | `idx` | Effect of returning TRUE |
|---|---|---|
| `TKM_MOUSEMOVE` | the hot column, -1 on a gutter; -1 throughout a drag | Ignored: hover is already updated, and a drag is not suppressible in flight |
| `TKM_MOUSELEAVE` | always -1 | Ignored: the hot state is already cleared (except during a drag) |
| `TKM_LBUTTONDOWN` | the pressed column, -1 on a gutter | Suppresses the press, the drag and the auto-fit of a double click. The capture is already taken and is released on the trailing up |
| `TKM_LBUTTONUP` | the column under the release, -1 outside | **Ignored.** The up releases the capture regardless, so a callback cannot strand it |
| `TKM_RBUTTONDOWN`, `TKM_RBUTTONUP` | the column under the cursor | Nothing to suppress: the right button is only reported |

On `TKM_LBUTTONUP` the message callback runs first, then the final WidthChanged or the Click,
then hover is re-derived.

### Tooltip

```freebasic
type HDR_TooltipCallbackFunc as function( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as ustring
```

Supplies the tip text for a column, on demand. Return `""` for no tip. With no callback the
column's caption is used.

### Click

```freebasic
type HDR_ClickCallbackSub as sub( byval hHeader as TK_WIDGET ptr, byval idx as integer )
```

A completed click on a column's **body**: pressed and released on the same column, not on a
divider. This is the sorting hook. Press, slide off, release fires nothing; a rapid double click
on a body fires it twice.

### Width changed

```freebasic
type HDR_WidthChangedCallbackSub as sub( byval hHeader as TK_WIDGET ptr, byval idx as integer, byval nWidth as integer, byval bLive as boolean )
```

A column's width changed through the **user**. `nWidth` is the new width in pixels, already
clamped to the column's minimum.

| When | `bLive` |
|---|---|
| Each mouse move during a divider drag that actually changes the width | `true` |
| The drag ends on release, moved or not | `false` |
| The drag is cancelled by Escape, capture loss or disabling, carrying the **restored** width | `false` |
| An auto-fit is applied | `false` |

A drag always ends with exactly one `bLive = false` notification, and that final value is the
truth. `tkColumnHeader_SetColumnWidth` does not fire it.

### Auto size

```freebasic
type HDR_AutoSizeCallbackFunc as function( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as integer
```

A divider was double-clicked. Return the best-fit width for that column in pixels, or 0 or less
for no change. Only you can measure, because you own the cell data and the fonts; add the
padding on both sides. The answer is clamped up to the column's effective minimum, applied, and
reported through WidthChanged with `bLive = false`. With no AutoSize callback, a divider double
click does nothing.

## Defaults

| Setting | Default |
|---|---:|
| Column width | 100 pixels (`CCOLHDR_DEFAULT_WIDTH`) |
| Column minimum | 0, meaning the scaled 16-pixel `CCOLHDR_DEFAULT_MINWIDTH` |
| Column `itemData` | 0 |
| Caption padding | 8 pixels, scaled at create (`CCOLHDR_DEFAULT_PADDING`) |
| Divider gutter | ± 3 pixels, scaled at use (`CCOLHDR_DIVIDER_GUTTER`) |
| Fill column | `CCOLHDR_FILL_LAST` |
| Sort indicator | none |
| Hover time | 250 ms |
| X offset | 0 |

## Inside a tkListTree

[tkListTree](tkListTree) builds one tkColumnHeader above its rows and keeps its column model
there. Reach it with `tkListTree_GetHeader`, and:

| Do | Instead of |
|---|---|
| Define columns with `tkListTree_AddColumn` and the other `tkListTree_*Column*` calls | `tkColumnHeader_AddColumn` on the header |
| Subscribe to resizes with `tkListTree_SetColumnResizeCallback` | `tkColumnHeader_SetWidthChangedCallback`: that slot is the list's, which repaints its rows on every live drag |
| Size and show the band with `tkListTree_SetHeaderHeight` and `tkListTree_ShowHeader` | `tkWidget_SetPos` / `tkWidget_Show` on the header, which the list lays out itself |

The padding, colours, font, the paint, click, auto-size and tooltip callbacks,
`tkColumnHeader_GetColumnRect` and the hit tests are safe to use directly on the list's header.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const CCOLHDR_DEFAULT_PADDING = 8 ' scaled once at create
const CCOLHDR_DIVIDER_GUTTER = 3 ' scaled at use: half-width of the grab zone
const CCOLHDR_DEFAULT_MINWIDTH = 16 ' scaled at use: the floor for nMinWidth = 0
const CCOLHDR_DEFAULT_WIDTH = 100
const CCOLHDR_FILL_LAST = -2
const CCOLHDR_FILL_NONE = -1

enum
    HDR_SORT_NONE = 0
    HDR_SORT_ASC
    HDR_SORT_DESC
end enum
```

### Types

```freebasic
type TKCOLUMNHEADER_COLORS
    BackColor        as ulong = &hFF2C313Aul
    BackColorHot     as ulong = &hFF373D48ul
    BackColorPressed as ulong = &hFF264F78ul
    ForeColor        as ulong = &hFF969CA6ul
    ForeColorHot     as ulong = &hFFE2E6EEul
    ForeColorPressed as ulong = &hFFFFFFFFul
    DividerColor     as ulong = &hFF444A56ul
    DividerColorHot  as ulong = &hFF61AFEFul
    SortMarkColor    as ulong = &hFF569CD6ul
end type

type TKCOLUMNHEADER_PAINTINFO
    hHeader     as TK_WIDGET ptr
    itemID      as integer
    b           as TK_PAINT ptr
    rc          as TKRECT
    isHot       as boolean
    isPressed   as boolean
    isResizeHot as boolean
    isResizing  as boolean
    isFill      as boolean
    wszCaption  as ustring
    nSortDir    as long            ' HDR_SORT_* (the host's indicator)
end type

type TKCOLUMNHEADER_MESSAGEINFO
    hHeader as TK_WIDGET ptr
    msg     as long                ' TKM_*
    x       as single
    y       as single
    idx     as integer             ' the column under the mouse; -1 on a divider gutter
end type

type TKCOLUMNHEADER_COLINFO
    wszText   as ustring
    itemData  as integer
    nWidth    as integer = CCOLHDR_DEFAULT_WIDTH
    nMinWidth as integer
    rc        as TKRECT
end type

type TKCOLUMNHEADER_STATE   ' per-instance state; reach it through the procedures

type HDR_PaintCallbackSub as sub( byval p as TKCOLUMNHEADER_PAINTINFO ptr )
type HDR_MessageCallbackFunc as function( byval m as TKCOLUMNHEADER_MESSAGEINFO ptr ) as boolean
type HDR_TooltipCallbackFunc as function( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as ustring
type HDR_ClickCallbackSub as sub( byval hHeader as TK_WIDGET ptr, byval idx as integer )
type HDR_WidthChangedCallbackSub as sub( byval hHeader as TK_WIDGET ptr, byval idx as integer, byval nWidth as integer, byval bLive as boolean )
type HDR_AutoSizeCallbackFunc as function( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as integer
```

### Procedures

```freebasic
function tkColumnHeader_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkColumnHeader_GetID( byval hHeader as TK_WIDGET ptr ) as long
function tkColumnHeader_InsertColumn( byval hHeader as TK_WIDGET ptr, byval idx as integer, byval Text as ustring, byval nWidth as integer = CCOLHDR_DEFAULT_WIDTH, byval nMinWidth as integer = 0, byval itemData as integer = 0 ) as integer
function tkColumnHeader_AddColumn( byval hHeader as TK_WIDGET ptr, byval Text as ustring, byval nWidth as integer = CCOLHDR_DEFAULT_WIDTH, byval nMinWidth as integer = 0, byval itemData as integer = 0 ) as integer
function tkColumnHeader_DeleteColumn( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as boolean
sub tkColumnHeader_Clear( byval hHeader as TK_WIDGET ptr )
function tkColumnHeader_GetCount( byval hHeader as TK_WIDGET ptr ) as integer
sub tkColumnHeader_Refresh( byval hHeader as TK_WIDGET ptr )
function tkColumnHeader_GetColumnText( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as ustring
function tkColumnHeader_SetColumnText( byval hHeader as TK_WIDGET ptr, byval idx as integer, byval Text as ustring ) as boolean
function tkColumnHeader_GetColumnItemData( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as integer
function tkColumnHeader_SetColumnItemData( byval hHeader as TK_WIDGET ptr, byval idx as integer, byval itemData as integer ) as boolean
function tkColumnHeader_GetColumnWidth( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as integer
function tkColumnHeader_SetColumnWidth( byval hHeader as TK_WIDGET ptr, byval idx as integer, byval nWidth as integer ) as boolean
function tkColumnHeader_GetColumnMinWidth( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as integer
function tkColumnHeader_SetColumnMinWidth( byval hHeader as TK_WIDGET ptr, byval idx as integer, byval nMinWidth as integer ) as boolean
function tkColumnHeader_GetFillColumn( byval hHeader as TK_WIDGET ptr ) as integer
function tkColumnHeader_SetFillColumn( byval hHeader as TK_WIDGET ptr, byval idx as integer ) as boolean
function tkColumnHeader_GetColumnRect( byval hHeader as TK_WIDGET ptr, byval idx as integer, byref rc as TKRECT ) as boolean
function tkColumnHeader_HitTestDivider( byval hHeader as TK_WIDGET ptr, byval x as long, byval y as long ) as integer
function tkColumnHeader_HitTestColumn( byval hHeader as TK_WIDGET ptr, byval x as long, byval y as long ) as integer
function tkColumnHeader_GetPadding( byval hHeader as TK_WIDGET ptr ) as integer
sub tkColumnHeader_SetPadding( byval hHeader as TK_WIDGET ptr, byval nPadding as integer )
function tkColumnHeader_GetXOffset( byval hHeader as TK_WIDGET ptr ) as integer
sub tkColumnHeader_SetXOffset( byval hHeader as TK_WIDGET ptr, byval xOffset as integer )
function tkColumnHeader_GetHotColumn( byval hHeader as TK_WIDGET ptr ) as integer
function tkColumnHeader_GetHotDivider( byval hHeader as TK_WIDGET ptr ) as integer
function tkColumnHeader_GetPressedColumn( byval hHeader as TK_WIDGET ptr ) as integer
function tkColumnHeader_GetDragColumn( byval hHeader as TK_WIDGET ptr ) as integer
sub tkColumnHeader_SetSortColumn( byval hHeader as TK_WIDGET ptr, byval idx as integer, byval nDir as long )
function tkColumnHeader_GetSortColumn( byval hHeader as TK_WIDGET ptr ) as integer
function tkColumnHeader_GetSortDirection( byval hHeader as TK_WIDGET ptr ) as long
sub tkColumnHeader_PaintColumnDefault( byval pi as TKCOLUMNHEADER_PAINTINFO ptr )
function tkColumnHeader_GetBackColor( byval hHeader as TK_WIDGET ptr ) as ulong
function tkColumnHeader_SetBackColor( byval hHeader as TK_WIDGET ptr, byval clr as ulong ) as ulong
sub tkColumnHeader_GetColors( byval hHeader as TK_WIDGET ptr, byval pColors as TKCOLUMNHEADER_COLORS ptr )
sub tkColumnHeader_SetColors( byval hHeader as TK_WIDGET ptr, byval pColors as TKCOLUMNHEADER_COLORS ptr )
function tkColumnHeader_ThemeColors( byref t as TKTHEME_COLORS ) as TKCOLUMNHEADER_COLORS
sub tkColumnHeader_ApplyTheme( byval hHeader as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkColumnHeader_UnpinColors( byval hHeader as TK_WIDGET ptr )
function tkColumnHeader_GetFont( byval hHeader as TK_WIDGET ptr ) as TTF_Font ptr
function tkColumnHeader_SetFont( byval hHeader as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
sub tkColumnHeader_ApplyFonts( byval hHeader as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
function tkColumnHeader_GetTooltipHandle( byval hHeader as TK_WIDGET ptr ) as TK_TIP ptr
sub tkColumnHeader_SetHoverTime( byval hHeader as TK_WIDGET ptr, byval ms as long )
sub tkColumnHeader_SetAutoPopTime( byval hHeader as TK_WIDGET ptr, byval ms as long )
sub tkColumnHeader_SetReshowTime( byval hHeader as TK_WIDGET ptr, byval ms as long )
sub tkColumnHeader_SetPaintCallback( byval hHeader as TK_WIDGET ptr, byval usersub as HDR_PaintCallbackSub )
sub tkColumnHeader_SetMessageCallback( byval hHeader as TK_WIDGET ptr, byval userfunc as HDR_MessageCallbackFunc )
sub tkColumnHeader_SetTooltipCallback( byval hHeader as TK_WIDGET ptr, byval userfunc as HDR_TooltipCallbackFunc )
sub tkColumnHeader_SetClickCallback( byval hHeader as TK_WIDGET ptr, byval usersub as HDR_ClickCallbackSub )
sub tkColumnHeader_SetWidthChangedCallback( byval hHeader as TK_WIDGET ptr, byval usersub as HDR_WidthChangedCallbackSub )
sub tkColumnHeader_SetAutoSizeCallback( byval hHeader as TK_WIDGET ptr, byval userfunc as HDR_AutoSizeCallbackFunc )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
