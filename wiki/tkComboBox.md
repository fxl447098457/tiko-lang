[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkComboBox**

# tkComboBox

Shows the current choice on a button that drops a scrolling list of the alternatives.

tkComboBox is a drop-down picker: a button with the current item's text and an up/down chevron, which opens a list where the current item carries a checkmark. Items have text, an id, item data and an enabled flag. The list scrolls once it has more than `tkComboBox_SetListMaxRows` rows (12 by default), with a scrollbar, the wheel and PageUp / PageDown.

Use it where a choice from a short-to-medium list must take little room. Three text modes decide whether the button shows a caption (`CBO_TEXT_ALWAYS`, `CBO_TEXT_NEVER`, `CBO_TEXT_WHENSELECTED`), and `tkComboBox_SetAutoSize` sizes the button to its widest item. With `tkComboBox_SetEditable` it becomes an editable combo: a text field over the button that the list fills.

Setters are silent. The SelChange callback fires only for a user's pick; the DropDown callback fires for every open and close, programmatic ones included.

`tkComboBox_SetTooltipText` gives the combo a tooltip (the edit box of an editable one included), with `SetHoverTime` / `SetAutoPopTime` / `SetReshowTime` and `GetTooltipHandle`; opening the list hides it. The corner curvature and border thickness follow the theme's shape until `SetCornerCurvature` or `SetBorderThickness` sets them. A paint callback replaces the button's drawing; `tkComboBox_PaintDefault( p )` draws the stock one first.

## Importing

```freebasic
#import "vendor/tkControls/tkComboBox"
using tkComboBox
using tkHost
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme), [tkPopupMenu](tkPopupMenu) (for `TKPOPUPMENU_COLORS`, the list's colours) and [tkVScrollBar](tkVScrollBar). Add `using tkPaint` to write a paint callback.

## Example

`gHost` is the window ([tkHost](tkHost)); `gFont10` is a font opened with `tkHost_OpenFont`.

```freebasic
sub OnSel( byval hCombo as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
    print "picked: "; tkComboBox_GetItemText( hCombo, idxNew )
end sub

sub OnDrop( byval hCombo as TK_WIDGET ptr, byval isOpen as boolean )
    print iif( isOpen, "list opened", "list closed" )
end sub

dim as TK_WIDGET ptr c = tkComboBox_Create( tkHost_Root( gHost ), 100 )
tkComboBox_SetFont( c, gFont10 )
tkComboBox_SetSelChangeCallback( c, @OnSel )
tkComboBox_SetDropDownCallback( c, @OnDrop )
tkComboBox_SetPlaceholderText( c, "Choose an action..." )
tkComboBox_AddItem( c, "Add to Existing Window", 1 )
tkComboBox_AddItem( c, "Open a New Window", 2 )
tkComboBox_AddItem( c, "Not Available Right Now", 3 )
tkComboBox_SetItemEnabled( c, 2, false )

dim as long iw, ih
tkComboBox_GetIdealSize( c, iw, ih )
tkWidget_SetPos( c, 16, 16, iw, ih )
```

The toolchain's `examples/tkControls/tkComboBox/` shows every text mode, a disabled combo, a custom-painted one and a long scrolling list.

## Concepts

### The handle is a widget

`tkComboBox_Create( hParent, CtrlID )` creates the control as a child of `hParent` — a `TK_WIDGET ptr` such as `tkHost_Root( gHost )` or a panel — and returns it as a `TK_WIDGET ptr`. Every `tkComboBox_*` procedure takes that pointer. Place and size it with `tkWidget_SetPos`, usually at the size `tkComboBox_GetIdealSize` reports; `tkComboBox_GetID` returns the `CtrlID` it was created with. The control takes the keyboard focus (in editable mode its edit takes it instead).

Single selection only: no multi-select and no per-item icons. The button has no label of its own — it shows the selected item's caption, a placeholder, or nothing — so a field label goes beside it, placed by you.

### The list exists only while it is open

The button is the control. The list is a separate popup surface, a `TK_HOST ptr`, which the control creates on every open and which goes away on every close. Nothing of it survives between opens except the settings the combo keeps for it: its colours, its row height and its row limit. It reads its rows straight from the combo's items, so the item set and the list cannot drift, and the opening edge of the DropDown callback is the place to rebuild a dynamic item set (see *Callbacks*).

The list shows at most `tkComboBox_GetListMaxRows` rows (12 by default). With more items than that it carries a [tkVScrollBar](tkVScrollBar) on its right and scrolls with the wheel and PageUp / PageDown, so long lists are fine. It is at least as wide as the button's chrome, and wider when its widest row — check gutter, caption, right column, plus the scrollbar when there is one — needs more. It sits below the button's chrome with the left edges aligned; it flips above the button, or aligns its right edge with the button's, when the display has no room for it there.

While the list is open it has the keyboard focus. The current item starts highlighted and scrolled into view; a disabled current item, or no selection, starts with no highlight.

### Geometry is derived, never assigned

The control computes four rectangles and owns all four. You influence them through the layout setters; you never write them.

| Rect | What it is |
|---|---|
| `rcButton` | The chrome: the client area deflated by the focus-ring band |
| `rcText` | The caption box. **Empty** when no caption is drawn |
| `rcChevron` | The cell the stacked up/down chevron is drawn in |
| `rcVisual` | `rcButton` inflated by the focus-ring band |

The formulas, if you need to predict them:

```
  ringPad   = focusGap + focusThickness
  textW     = MAX over all items of the measured caption width  (0 when no caption is drawn)
  textH     = the font's line height       ONE height for the whole control
  contentH  = max( textH, chevronHeight )

  idealW    = 2*ringPad + padLeft + [textW + textGap] + chevronWidth + padRight
  idealH    = 2*ringPad + padTop  + contentH + padBottom

  rcButton  = rcClient deflated by ringPad on all four sides
  rcChevron = right-aligned inside rcButton at padRight, v-centred, chevronWidth wide
  rcText    = from rcButton.left + padLeft to rcChevron.left - textGap, v-centred on textH
  rcVisual  = rcButton inflated by ringPad  ( = rcClient when you sized the control ideally )
```

The `[textW + textGap]` term is spent **only when a caption is drawn**. In arrow-only mode there is nothing on the left for the chevron to be separated from, so charging for the gap would leave the arrow visibly off-centre in its own padding.

Layout is lazy. A setter marks the layout stale and asks for a repaint; the next paint — or any rect query, size query or auto-size pass — recomputes it. There is no begin-update / end-update pair to remember, and adding forty items in a row costs one measuring pass, not forty.

### The width comes from the widest item, never the selected one

The button must not change width when the selection changes: a combo that grows and shrinks as the user picks reflows whatever surrounds it and drags its own list anchor sideways. So every caption is measured and the widest wins. Disabled items count too. The **placeholder is deliberately not measured** — a long one cannot inflate the button and a short one cannot let it shrink, either of which would make the button resize on the user's first pick.

The one place the width *does* move is the `-1` ↔ selected boundary under `CBO_TEXT_WHENSELECTED`, which is that mode's purpose rather than an exception: every *selected* state still has the same width as every other. See *Constants*.

### The ideal size is valid before the control has ever been sized

`tkComboBox_GetIdealSize` is what you call to decide how big to make the control in the first place, so it does not need the control to have a size yet: the measuring pass runs ahead of the layout's zero-size bail. The rect queries are the other way round — they describe placement, so they return FALSE until the control has a size.

### Pixels and scale

The creation-time defaults are multiplied by the window's scale (`tkHost_Scale`) for you:

| Setting | Constant | Default | Scaled at create? |
|---|---|---:|---|
| Padding left / right | `TKCOMBOBOX_DEFAULT_PADLEFT` / `PADRIGHT` | 12 / 10 | Yes |
| Padding top / bottom | `TKCOMBOBOX_DEFAULT_PADTOP` / `PADBOTTOM` | 6 / 6 | Yes |
| Text gap | `TKCOMBOBOX_DEFAULT_TEXTGAP` | 8 | Yes |
| Chevron width / height | `TKCOMBOBOX_DEFAULT_CHEVRONW` / `CHEVRONH` | 9 / 12 | Yes. The width is odd so the glyph comes to a point |
| Chevron gap | `TKCOMBOBOX_DEFAULT_CHEVRONGAP` | 3 | Yes |
| Corner curvature | `TKCOMBOBOX_DEFAULT_CURVATURE` | 12 | Yes. A **diameter**, so a 6px radius. The theme's corner radius replaces it (see *Colors*) |
| Border thickness | `TKCOMBOBOX_DEFAULT_BORDERTHICK` | 1 | **No**. The theme's border width replaces it |
| Focus-ring gap | `TKCOMBOBOX_DEFAULT_FOCUSGAP` | 2 | Yes |
| Focus-ring thickness | `TKCOMBOBOX_DEFAULT_FOCUSTHICK` | 1 | **No** |
| Chevron thickness | — | 1 | **No** — but scaled at paint time, see below |
| List row height | `TKCOMBOBOX_DEFAULT_LISTITEMHEIGHT` | 24 | Yes |
| List check gutter | `TKCOMBOBOX_DEFAULT_LISTCHECKCOL` | 30 | Yes |
| List right column | `TKCOMBOBOX_DEFAULT_LISTRIGHTCOL` | 20 | Yes |
| List row limit | `TKCOMBOBOX_DEFAULT_LISTMAXROWS` | 12 | A count, not pixels |

Every setter afterwards takes raw pixels and expects **you** to scale — typically with `tkHost_Scale`. The border and focus-ring thicknesses should not be scaled: a hairline stays a hairline at any scale. **The chevron thickness is the exception**: it is stored unscaled, but the painter multiplies it by the window's scale, so the chevron's stroke grows with the glyph.

A scale change arrives as `TKM_SCALECHANGED`. The control multiplies every scaled metric it holds — the paddings, the text gap, the chevron size and gap, the curvature, the focus-ring gap, and the list's row height, check gutter and right column — by the ratio of new scale to old, closes an open list, and re-measures (re-sizing itself when auto-size is on).

### Programmatic changes are silent — with one deliberate exception

`tkComboBox_SetCurSel` never fires the selection callback. SelChange reports **user** action — a pick from the list, an arrow / Home / End key, or the wheel — and nothing else, so you can call `tkComboBox_SetCurSel` from inside your own handler without recursing. Every item mutator (`AddItem`, `InsertItem`, `DeleteItem`, `Clear`, and all the `SetItem*` setters) is silent too.

**The DropDown callback is the exception.** It fires for `tkComboBox_DropDown` and `tkComboBox_CloseUp` as well as for user opens, because it reports a state transition of the list rather than a value change — and a host that rebuilds its item set on open needs that hook to run however the list was opened.

### How a click is decided

**The list opens on the button press**, not on the release. Pressing the left button focuses the control (even if a message callback goes on to suppress the click), hides the tooltip, then opens the list — or closes it if it was open. From the instant of the press the list owns the interaction, so there is no pressed state, no mouse capture, and the release over the button is reported to the message callback but not acted on.

In the open list, hovering moves the highlight onto enabled rows, and **releasing** the button over an enabled row picks it. A press, or a release over a disabled row, does nothing.

### Keyboard

With the list **closed** (and the control focused and enabled):

| Key | Effect |
|---|---|
| Down / Up | Move the selection in place, without opening. Fires SelChange |
| Home / End | Jump to the first / last selectable item. Fires SelChange |
| Alt+Down, Alt+Up | Open the list |
| F4, Space, Enter (either Enter key) | Open the list |

Arrow movement **clamps at the ends, it does not wrap**: a wrapping Down at the last item would jump the user back to the first with no list visible to explain it. Disabled items are skipped. From "nothing selected", Up lands on the last selectable item.

With the list **open**, the highlight is **provisional**: moving it changes nothing until a row is committed.

| Key | Effect |
|---|---|
| Down / Up | Move the highlight to the next / previous selectable row, **wrapping** at the ends. From no highlight, Up lands on the last selectable row |
| Home / End | Highlight the first / last selectable row |
| PageDown / PageUp | Move the highlight a page (one row less than the rows shown), clamping at the ends |
| Enter, Space | Commit the highlighted row; with no highlight, just close |
| Escape, Tab, F4, Alt+Down, Alt+Up | Close the list with no change |

The highlight is scrolled into view as it moves.

### The mouse wheel

Over a **focused, closed, enabled** combo, the wheel steps the selection one selectable item per notch — up to the previous item, down to the next — clamping at the ends and firing SelChange. From "nothing selected", wheeling up lands on the last selectable item and wheeling down on the first. Over any other combo the wheel is not taken, so the parent scrolls.

Over the open list, the wheel scrolls it three rows per notch and leaves the highlight where it is.

### Enabling and disabling

`tkComboBox_SetEnabled` goes through `tkWidget_Enable`, and the control reacts the same way however it was enabled. A disabled combo ignores presses, hover, keys and the wheel. Disabling also clears the hover state, closes an open list and hides the tooltip at once.

Disabling does **not** change the selection. A disabled combo still reads as showing its value, which is why the colour struct carries a full disabled set.

### Lifetime

The control frees itself when its widget is destroyed: an open list is closed (without a DropDown callback), and its tooltip is destroyed with it. The font you pass in stays yours: it is borrowed, never owned, so keep it alive for as long as the control lives. With no font set, the control uses the window's default font.

## Editable mode

`tkComboBox_SetEditable( c, true )` lays a single-line [tkTextBox](tkTextBox) over the text area, borderless and in the combo's colours. The chevron, F4 and Alt+Down still open the list.

- A pick from the list, or Down / Up in the edit, fills the edit silently and selects its text; SelChange reports the pick.
- Typing changes no selection. It notifies `tkComboBox_SetEditChangeCallback`; Enter notifies `tkComboBox_SetEditEnterCallback`.
- `tkComboBox_GetText` returns the edit's text; `tkComboBox_SetEditText` sets it silently. `tkComboBox_GetEditHandle` returns the edit widget, for anything the combo does not wrap.
- `tkComboBox_SetCurSel` changes the selection only; it does not fill the edit. Set the edit's text with `tkComboBox_SetEditText`.
- Turning editable mode on puts the current item's caption, if any, in the edit. The edit spans the text area's width and the button's inner height.
- The edit takes the keyboard focus instead of the combo; the combo draws its focus ring while the edit has it.
- The text mode no longer applies: the edit is always shown, and the combo paints no caption of its own.
- The edit is re-coloured from the combo's colours on a theme change.
- `tkComboBox_SetEditable( c, false )` destroys the edit, and the combo becomes focusable itself again.
- There is no autocomplete while typing.

## Behaviour and limits

Firm properties of the control, not settings:

- **The list scrolls.** Past `tkComboBox_GetListMaxRows` rows it has a scrollbar, and the wheel and PageUp / PageDown move through it.
- **The checkmark sits in a fixed left gutter.** The list reserves a check column on the left of every row and a column on the right (`TKCOMBOBOX_DEFAULT_LISTCHECKCOL` and `TKCOMBOBOX_DEFAULT_LISTRIGHTCOL`, scaled), with no setters for either. The checkmark is drawn as geometry, so no font has to carry a check glyph.
- **The press that closes the list is consumed.** Clicking the button while the list is open just closes it, and a click elsewhere closes the list without also acting on what it lands on.
- **Only one popup is open at a time.** Opening another popup closes this list at once, and the DropDown callback reports the close then. The list also closes when the application loses the focus.
- **`tkComboBox_DropDown` fails on an empty list.** With no items there is nothing to show, so it returns FALSE. It fires the opening callback first and then a matching closing one, so the callback's open/close pairing always holds even when the open fails.
- **No mouse capture is taken.** See *How a click is decided*.
- **No multi-select**, and no per-item icons or images.
- **No hit-test function.** The entire control opens the list, so a hit test could only ever return TRUE for points the caller already knows are inside.
- **Arrow keys clamp, they do not wrap** — while the list is closed. In the open list they wrap.
- **The right mouse button is reported, never acted on.** A context menu is your business.
- **`tkComboBox_GetListHandle` is 0 while the list is closed.** The list is created on each open, so settings for it go through the combo (`SetListColors`, `SetListItemHeight`, `SetListMaxRows`) and take effect at the next open.
- **Invalid text-mode values are ignored**, leaving the current mode in place, rather than laying the button out somewhere unexpected.
- **When the control is too narrow, `rcText` collapses and the chevron survives.** The chevron keeps its size and stays pinned to the right, and the caption box degenerates to an empty rect rather than a negative one. So a too-narrow combo loses its caption and keeps its arrow, which is the useful failure.

## Colors

The colour surface is one flat struct, `TKCOMBOBOX_COLORS`, with eighteen `ulong` fields: four drawn parts (background, caption, border, chevron) × four moods (idle, hot, open, disabled), plus the placeholder colour and the focus ring.

| Field | Paints |
|---|---|
| `BackColor` | Chrome fill, idle |
| `ForeColor` | Caption, idle |
| `BorderColor` | Chrome border, idle |
| `ChevronColor` | Chevron strokes, idle |
| `BackColorHot` | Chrome fill, pointer over the button with the list closed |
| `ForeColorHot` | Caption, hot |
| `BorderColorHot` | Chrome border, hot |
| `ChevronColorHot` | Chevron strokes, hot |
| `BackColorOpen` | Chrome fill while the list is open |
| `ForeColorOpen` | Caption, open |
| `BorderColorOpen` | Chrome border, open |
| `ChevronColorOpen` | Chevron strokes, open |
| `BackColorDisabled` | Chrome fill, disabled |
| `ForeColorDisabled` | Caption, disabled |
| `BorderColorDisabled` | Chrome border, disabled |
| `ChevronColorDisabled` | Chevron strokes, disabled |
| `ForeColorPlaceholder` | The placeholder string, drawn instead of the caption colour when nothing is selected. **One field, not four** — a placeholder is already a muted state |
| `FocusRingColor` | The focus ring, drawn only while the control has focus |

### Where the colours come from

A new control takes its colours from its [theme](tkTheme) through `tkComboBox_ThemeColors`, plus any ComboBox-specific entries the theme carries, and follows every theme change (`TKM_THEMECHANGED`) the same way:

| Fields | Theme colour |
|---|---|
| `BackColor`, `BorderColor`, `BackColorOpen`, `BorderColorOpen` | `Surface` |
| `ForeColor`, `ChevronColor` | `Text` |
| `BackColorHot`, `BorderColorHot` | `SurfaceHot` |
| `ForeColorHot`, `ChevronColorHot` | `TextHot` |
| `ForeColorOpen`, `ChevronColorOpen` | `Accent` |
| `BackColorDisabled`, `BorderColorDisabled` | `SurfaceDisabled` |
| `ForeColorDisabled`, `ChevronColorDisabled` | `TextDisabled` |
| `ForeColorPlaceholder` | `TextDim` |
| `FocusRingColor` | `FocusRing` |

`tkComboBox_SetColors` **pins** the colours: theme changes leave a pinned control's colours alone until `tkComboBox_UnpinColors`, which drops the pin and re-applies the current theme. A `TKCOMBOBOX_COLORS` you `dim` yourself starts at a dark set with the same relationships.

The shape follows the theme as well: the corner curvature is the theme's corner radius × 2 (scaled) and the border thickness is the theme's border width, or the control's defaults where the theme gives -1. Calling `tkComboBox_SetCornerCurvature` or `tkComboBox_SetBorderThickness` pins the shape, and theme changes then leave both alone.

To change one colour, read-modify-write:

```freebasic
dim as TKCOMBOBOX_COLORS clrs
tkComboBox_GetColors( c, @clrs )
clrs.BorderColor    = &hFF505660ul
clrs.BorderColorHot = &hFF6E7682ul
tkComboBox_SetColors( c, @clrs )
```

### Which colour wins

The built-in painter picks one fill, one caption, one border and one chevron colour per repaint, in this precedence:

```
disabled   >   open   >   hot   >   idle
```

**Open beats hot on purpose.** While the list is up, the pointer is normally over the *list*, not over the button — and the button must stay lit while its own list is showing.

**There are no pressed colours, and there is no pressed mood.** The list opens on the press, so "pressed" and "open" are the same instant and collapse into one state.

### Why the button reads borderless by default

Every `BorderColorXxx` defaults **equal to** the matching `BackColorXxx`, so the chrome reads as a solid shape with no outline. If you want a visible border, set those four fields to something different from the fill.

The chevron follows the caption for the same reason: each `ChevronColorXxx` defaults equal to the matching `ForeColorXxx`, so caption and chevron change colour together. Set them to break that coupling.

`BackColorOpen` defaults equal to `BackColor`, **not** to `BackColorHot`: in the open state only the caption and the chevron change, and the fill stays put.

### The list's colours

The list paints with a `TKPOPUPMENU_COLORS` (from [tkPopupMenu](tkPopupMenu)). The control **derives it from its own colours** at creation, on every `tkComboBox_SetColors` and on every theme change it follows, so theming the button themes the list:

| List field | Taken from | Paints |
|---|---|---|
| `BackColor` | `BackColor` | The list's background |
| `ForeColor` | `ForeColor` | Row captions and the checkmark |
| `BackColorHot` | `BackColorHot` | The highlighted row's fill |
| `ForeColorHot` | `ForeColorHot` | The highlighted row's caption and checkmark |
| `ForeColorDisabled` | `ForeColorDisabled` | Disabled rows |
| `BorderColor` | **`BorderColorHot`** | The list's one-pixel border |
| `SeparatorColor` | `ForeColorDisabled` | — |

The border comes from `BorderColorHot` rather than `BorderColor` because the latter defaults equal to `BackColor` — deriving from it would give the list an invisible border and no edge against the window behind it.

`tkComboBox_SetListColors` overrides the whole set and **claims** it: the derivation stands down permanently for that control, so a later `SetColors` or theme change will not overwrite your choice. `tkComboBox_GetListColors` reads the set in use, derived or claimed.

### What the painter draws

Before the button is drawn — by the built-in painter or by a paint callback — the whole client area is filled with the current mood's `BackColor`.

| Part | Shape |
|---|---|
| Chrome | A rounded rectangle over `rcButton` with the corner curvature, stroked with a border when the border thickness is above 0 and filled without one at 0. |
| Caption | Drawn left-aligned into `rcText`, ellipsized when it does not fit, in `ForeColorPlaceholder` when it is the placeholder. Not drawn in editable mode, where the edit shows the text. |
| Chevron | Four strokes: an up chevron in the top half of the cell and a down chevron in the bottom half, separated by the chevron gap, both apexes pointing **away** from the centre. It is geometry, not a glyph, so it needs no icon font and it scales cleanly. A degenerate cell is skipped rather than drawn wrong. |
| Focus ring | A rounded **outline** over `rcVisual`, drawn only while the control has focus and the ring thickness is above 0. Never a fill. Its curvature is the chrome's plus the band on both sides, which keeps the two curves concentric. |

## Callbacks

All of them are optional and independent.

### Selection changed

```freebasic
type CBO_SelChangeCallbackSub as sub( byval hCombo as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
```

The **user** changed the selection — a pick from the list, an arrow / Home / End key while the list is closed, or the wheel. Fires **after** the control's state is updated, so `tkComboBox_GetCurSel( hCombo )` already equals `idxNew`.

It does not fire for `tkComboBox_SetCurSel`, which is what makes it safe to call that setter from inside this handler. Picking the item that is already current is not a change and fires nothing (the list still closes).

Under `CBO_TEXT_WHENSELECTED` the new ideal width is already in place by the time you are called, so a host that re-places the control from here reads the correct size.

### List opened or closed

```freebasic
type CBO_DropDownCallbackSub as sub( byval hCombo as TK_WIDGET ptr, byval isOpen as boolean )
```

The list is about to open (`isOpen = TRUE`) or has just closed (`isOpen = FALSE`), for whatever reason — a pick, Escape, a click outside, another popup opening, a scale change, `tkComboBox_CloseUp`.

**It fires for programmatic opens too** — `tkComboBox_DropDown` and `tkComboBox_CloseUp` — unlike the selection callback.

**The opening edge runs before the list exists**, which makes it the just-in-time hook: `Clear` + `AddItem` here and the new set is picked up by the same open. On a pick, the closing notification goes out *before* the selection change, so a host handling both sees a consistent "closed, and here is the new value" order.

```freebasic
sub OnDropRebuild( byval hCombo as TK_WIDGET ptr, byval isOpen as boolean )
    if isOpen = false then exit sub
    tkComboBox_Clear( hCombo )
    for i as long = 0 to gDocCount - 1
        tkComboBox_AddItem( hCombo, gDocName(i), gDocID(i) )
    next
end sub
```

### Paint

```freebasic
type CBO_PaintCallbackSub as sub( byval p as TKCOMBOBOX_PAINTINFO ptr )
```

Draws the whole **button** instead of the built-in painter. Paint through `p->b`, the control's `TK_PAINT` for this repaint (add `using tkPaint`). This callback owns the button only; the list is painted by the control.

The control has already filled the client with the current mood's `BackColor` before calling you. To add to the stock look rather than replace it, call `tkComboBox_PaintDefault( p )` first and draw on top.

Draw with the **same font** the control uses (`tkComboBox_GetFont`, or the window's default font when that is 0): the button's width was measured with it, and a different font means the width lies.

`TKCOMBOBOX_PAINTINFO` carries everything you need:

| Field | Meaning |
|---|---|
| `hCombo` | The control, so the callback can query it |
| `b` | The `TK_PAINT` for this repaint (borrowed, not owned) |
| `rcClient` | The whole client area |
| `rcButton` | The chrome: `rcClient` deflated by the focus-ring band |
| `rcText` | The caption box. Empty when `isTextVisible` is FALSE |
| `rcChevron` | The stacked up/down chevron cell |
| `rcVisual` | `rcButton` inflated by the focus-ring band |
| `isHot` | The pointer is over the control and the list is closed |
| `isOpen` | The list is showing |
| `isEnabled` | The control's enabled state |
| `isFocused` | Draw a focus ring when TRUE |
| `nCurSel` | The selected index, or -1 |
| `wszText` | The caption to draw: the selected item's, or the placeholder, or `""` |
| `isPlaceholder` | `wszText` is the placeholder, not a real selection |
| `isTextVisible` | Is a caption drawn at all right now — already resolved from the text mode *and* the selection |

All four rects are precomputed. Use them as given — in particular, do not re-derive `rcText` by re-applying the padding to `rcButton`, because the chevron size and the text gap can change underneath you.

When `isTextVisible` is FALSE, `rcText` is empty and only the chevron should be drawn. Do not fall back to painting `wszText` somewhere of your own choosing: the field is still computed and handed to you as information.

> **A paint callback that fills a rectangle covering the whole control will erase everything under it.** Draw your additions, not a background — the control has already painted one. In particular, stroke a focus ring with `PaintRoundOutline` and not `PaintBorderRect`: `PaintBorderRect` always fills before it strokes.

### Message

```freebasic
type CBO_MessageCallbackFunc as function( byval m as TKCOMBOBOX_MESSAGEINFO ptr ) as boolean
```

Observes messages as they arrive. Return TRUE to suppress the control's own handling of that message, FALSE to let it proceed.

`TKCOMBOBOX_MESSAGEINFO` carries:

| Field | Meaning |
|---|---|
| `hCombo` | The control |
| `msg` | The message, a `TKM_*` value |
| `x`, `y` | The pointer position for mouse messages, in the control's pixels |
| `key` | The key for `TKM_KEYDOWN` (an `SDLK_*` code) |
| `mods` | The modifier keys held (`SDL_KMOD_*`) |

Reported messages, and whether your answer counts:

| Message | Reported | Returning TRUE |
|---|---|---|
| `TKM_LBUTTONDOWN` | While enabled | Suppresses the open/close — but **not** the focus change, which happens before you are called |
| `TKM_KEYDOWN` | While enabled and the list is closed | Suppresses the key's action |
| `TKM_MOUSEWHEEL` | While focused, enabled and the list is closed | Suppresses the selection step |
| `TKM_MOUSEMOVE` | While enabled | Ignored |
| `TKM_MOUSELEAVE`, `TKM_LBUTTONUP`, `TKM_RBUTTONDOWN`, `TKM_RBUTTONUP` | Always | Ignored — the control does nothing with them |
| `TKM_SETFOCUS`, `TKM_KILLFOCUS` | Always | Ignored — focus is a fact the host reports, not an action to veto. The state is already updated by the time you are called |

## Constants

### Text mode

```freebasic
enum
    CBO_TEXT_ALWAYS = 0       ' the default
    CBO_TEXT_NEVER
    CBO_TEXT_WHENSELECTED
end enum
```

| Constant | Meaning |
|---|---|
| `CBO_TEXT_ALWAYS` | The caption is always drawn. With nothing selected that means the placeholder, or an empty button. The width never changes. |
| `CBO_TEXT_NEVER` | Arrow-only, permanently: the ideal width collapses to padding + chevron. The control still **has** a selection and the list still checkmarks it; only the button's caption is suppressed. |
| `CBO_TEXT_WHENSELECTED` | Arrow-only while nothing is selected, and an ordinary captioned combo once something is. The button collapses until the user answers it. |

**`CBO_TEXT_WHENSELECTED` is the one mode whose width moves**, and that is its purpose rather than a violation of the widest-item rule: every *selected* state still has the same width as every other, and what changes is the one-time `-1` → selected transition from "unanswered" to "answered".

The practical consequence: in this mode, either turn on `tkComboBox_SetAutoSize`, or re-place the control from your SelChange handler. Left at a fixed size, the control keeps its collapsed width and the caption arrives ellipsized into a chevron-sized box. A placeholder can never be seen in this mode either, since the only state that would show it is the collapsed, caption-less one.

In editable mode the text mode does not apply.

## API reference

### Creation

| Procedure | Description |
|---|---|
| `tkComboBox_Create( hParent, CtrlID ) as TK_WIDGET ptr` | Creates the control as a child of `hParent` and returns it, or 0 when `hParent` is 0. Size it with `tkComboBox_GetIdealSize` and place it with `tkWidget_SetPos`. |
| `tkComboBox_GetID( hCombo ) as long` | The `CtrlID` it was created with. |

### Items

The set is dynamic, and every structural mutation fixes up the current selection. **All of these are silent.**

| Procedure | Description |
|---|---|
| `tkComboBox_AddItem( hCombo, Text, id = 0, itemData = 0 ) as long` | Appends an item and returns its index. The selection is untouched — it does **not** auto-select the first item; -1 is a legal state. `id` and `itemData` are free-form host payloads. |
| `tkComboBox_InsertItem( hCombo, idx, Text, id = 0, itemData = 0 ) as long` | Inserts **before** `idx`, shifting the tail up; `idx` equal to the count appends. Returns `idx`, or -1 for an out-of-range index. A selection at or after `idx` moves up by one. |
| `tkComboBox_DeleteItem( hCombo, idx ) as boolean` | Removes one item. Deleting the **current** item clears the selection to -1 rather than sliding it onto a neighbour; a selection after `idx` moves down by one. FALSE for an invalid index. |
| `tkComboBox_Clear( hCombo )` | Removes everything and clears the selection to -1. |
| `tkComboBox_GetCount( hCombo ) as long` | Number of items. |
| `tkComboBox_IsValidItem( hCombo, idx ) as boolean` | TRUE when `idx` is in range. |
| `tkComboBox_GetItemText( hCombo, idx ) as ustring` | The item's caption, or `""` for an invalid index. |
| `tkComboBox_SetItemText( hCombo, idx, Text ) as boolean` | Sets the caption and **re-measures**, so this can change the ideal width — and, with auto-size on, the control itself. FALSE for an invalid index. |
| `tkComboBox_GetItemID( hCombo, idx ) as long` | The host id, or 0 for an invalid index. |
| `tkComboBox_SetItemID( hCombo, idx, id ) as boolean` | Sets the host id. No repaint — nothing draws it. |
| `tkComboBox_GetItemData( hCombo, idx ) as integer` | The host payload, or 0 for an invalid index. |
| `tkComboBox_SetItemData( hCombo, idx, itemData ) as boolean` | Sets the host payload. No repaint. |
| `tkComboBox_GetItemEnabled( hCombo, idx ) as boolean` | The item's enabled state (FALSE for an invalid index). |
| `tkComboBox_SetItemEnabled( hCombo, idx, bEnabled ) as boolean` | A disabled item is greyed in the list, cannot be highlighted or picked, and is skipped by the keys and the wheel — but it still counts for indexing and **still contributes its width**. **Disabling the current item clears the selection to -1**, because `SetCurSel` refuses to put it back. |
| `tkComboBox_FindItemByID( hCombo, id ) as long` | Index of the **first** item carrying this id, or -1. |
| `tkComboBox_FindItemByText( hCombo, Text ) as long` | Index of the **first** item with this exact caption, compared case-insensitively, or -1. |

### Selection and state

| Procedure | Description |
|---|---|
| `tkComboBox_GetCurSel( hCombo ) as long` | The selected index, or -1 for nothing selected. |
| `tkComboBox_SetCurSel( hCombo, idx ) as boolean` | Sets the selection and repaints. **Silent**. **Refuses a disabled item** (returns FALSE, changes nothing). `-1` always succeeds; an out-of-range index does not. Returns TRUE when the selection already matched. Re-measures only when it crosses the `CBO_TEXT_WHENSELECTED` boundary. |
| `tkComboBox_GetText( hCombo ) as ustring` | What the **button** is showing: the selected caption, or the placeholder, or `""`. In editable mode, the edit's text. |
| `tkComboBox_GetEnabled( hCombo ) as boolean` | The control's enabled state. |
| `tkComboBox_SetEnabled( hCombo, isEnabled )` | Enables or disables the widget. Disabling closes an open list, clears hover and hides the tooltip. Does not change the selection. |
| `tkComboBox_GetFocused( hCombo ) as boolean` | TRUE while the control (or, in editable mode, its edit) has the keyboard focus and the focus ring is drawn. |
| `tkComboBox_GetHot( hCombo ) as boolean` | TRUE while the pointer is over the control. |
| `tkComboBox_Refresh( hCombo )` | Marks the layout stale and requests a repaint. Rarely needed — every setter does this for you. |

### The list

| Procedure | Description |
|---|---|
| `tkComboBox_IsDroppedDown( hCombo ) as boolean` | TRUE while the list is showing. |
| `tkComboBox_DropDown( hCombo ) as boolean` | Opens the list. Returns TRUE if it is open (including when it already was). FALSE, with no callback, when the control is disabled. Otherwise the `DropDown(true)` callback fires **first**, before the list exists; then FALSE if the item set is **empty** or the list could not be shown, each with a matching `DropDown(false)`. Opening hides the tooltip. |
| `tkComboBox_CloseUp( hCombo )` | Closes the list, firing `DropDown(false)` if it was open. Silent when it was already closed. No selection change. |
| `tkComboBox_GetListHandle( hCombo ) as TK_HOST ptr` | The open list's popup surface, or 0 while it is closed. |
| `tkComboBox_GetListItemRect( hCombo, idx, byref rc ) as boolean` | Row `idx`'s rect in the open list's pixels. FALSE (and `rc` empty) when the list is closed or the row is scrolled out of view. |
| `tkComboBox_GetListHot( hCombo ) as long` | The provisional highlight in the open list, or -1. |
| `tkComboBox_GetListTopIndex( hCombo ) as long` | The first visible row of the open list. |
| `tkComboBox_GetListScrollBar( hCombo ) as TK_WIDGET ptr` | The open list's [tkVScrollBar](tkVScrollBar) when the rows overflow, else 0. |
| `tkComboBox_SetListColors( hCombo, pColors as TKPOPUPMENU_COLORS ptr )` | Sets the list's colours and **claims** them, so the button's colours and the theme no longer re-derive them. |
| `tkComboBox_GetListColors( hCombo, pColors as TKPOPUPMENU_COLORS ptr )` | Fills your struct with the list colours in use. |
| `tkComboBox_SetListItemHeight( hCombo, nItemHeight )` | The list's row height in pixels, minimum 1. Takes effect at the next open. |
| `tkComboBox_GetListItemHeight( hCombo ) as long` | The list's row height. |
| `tkComboBox_SetListMaxRows( hCombo, nRows )` | Rows shown before the list scrolls, minimum 1. Takes effect at the next open. |
| `tkComboBox_GetListMaxRows( hCombo ) as long` | Rows shown before the list scrolls. |

### Geometry and layout

All setters take **raw pixels**; you do the scaling. Each requests a repaint, and — when the change can move the ideal width — re-measures and re-applies auto-size if you turned it on.

| Procedure | Description |
|---|---|
| `tkComboBox_GetTextMode( hCombo ) as long` | `CBO_TEXT_ALWAYS` (the default), `CBO_TEXT_NEVER` or `CBO_TEXT_WHENSELECTED`. |
| `tkComboBox_SetTextMode( hCombo, nTextMode )` | Sets the mode. Values outside the three constants are **ignored**. See *Constants*. |
| `tkComboBox_GetShowText( hCombo ) as boolean` | Answers "**is a caption drawn right now**", not "what mode is set" — under `CBO_TEXT_WHENSELECTED` those are different questions. |
| `tkComboBox_SetShowText( hCombo, bShowText )` | The two-state convenience over `SetTextMode`: TRUE = `CBO_TEXT_ALWAYS`, FALSE = `CBO_TEXT_NEVER`. It cannot reach `CBO_TEXT_WHENSELECTED`. |
| `tkComboBox_GetAutoSize( hCombo ) as boolean` | Whether the control sizes itself. |
| `tkComboBox_SetAutoSize( hCombo, bAutoSize )` | When TRUE the control resizes **itself** to its ideal size, keeping its position, whenever something that changes that size changes: items, item text, font, text mode, padding, text gap, chevron size, focus ring, scale. Default FALSE. Turning it on applies immediately. **The control owns its size; you still own its position**, so a right-aligned control that grows in place must be re-placed by you. |
| `tkComboBox_GetPadding( hCombo, byref nLeft, nTop, nRight, nBottom )` | The four inner paddings, inside the chrome. |
| `tkComboBox_SetPadding( hCombo, nLeft, nTop, nRight, nBottom )` | Sets them; each clamped to a minimum of 0. Changes the ideal size. |
| `tkComboBox_GetTextGap( hCombo ) as long` | The gap between the caption and the chevron. |
| `tkComboBox_SetTextGap( hCombo, nTextGap )` | Sets it; minimum 0. **Spent only when a caption is drawn**. |
| `tkComboBox_GetChevronSize( hCombo, byref nWidth, nHeight )` | The chevron cell's size. |
| `tkComboBox_SetChevronSize( hCombo, nWidth, nHeight )` | Sets it; **clamped to a minimum of 2×2**. Changes the ideal size. |
| `tkComboBox_GetChevronGap( hCombo ) as long` | The vertical air between the up chevron and the down chevron. |
| `tkComboBox_SetChevronGap( hCombo, nGap )` | Sets it; minimum 0. It lives **inside** the chevron cell, so it never changes the ideal size — repaint only. |
| `tkComboBox_GetChevronThickness( hCombo ) as long` | The chevron's stroke weight. |
| `tkComboBox_SetChevronThickness( hCombo, nThickness )` | Sets it; minimum 1. Repaint only. **The one thickness the painter scales**. |
| `tkComboBox_GetCornerCurvature( hCombo ) as long` | The chrome's corner curvature. |
| `tkComboBox_SetCornerCurvature( hCombo, nCurvature )` | Sets it; minimum 0, where **0 means square corners**. An ellipse **diameter**, not a radius, so 12 draws a 6px radius. Repaint only. Pins the shape against the theme. |
| `tkComboBox_GetBorderThickness( hCombo ) as long` | The chrome's border thickness. |
| `tkComboBox_SetBorderThickness( hCombo, nThickness )` | Sets it; minimum 0, where **0 means no border at all** (the chrome is then a plain filled rounded rect). Repaint only. Do not scale this value. Pins the shape against the theme. |
| `tkComboBox_GetFocusRing( hCombo, byref nGap, nThickness )` | The gap from the chrome to the focus ring, and the ring's own thickness. |
| `tkComboBox_SetFocusRing( hCombo, nGap, nThickness )` | Sets both; each minimum 0. **Both change the ideal size**, because the ring's band is reserved whether or not the control has focus — which stops the button jumping sideways when it gains focus. Do not scale the thickness. |
| `tkComboBox_GetIdealSize( hCombo, byref nWidth, nHeight )` | The measured size: chrome plus the focus-ring band on every side. Forces a pending layout, and is **valid before the control has ever been sized**. |
| `tkComboBox_GetButtonRect( hCombo, byref rc ) as boolean` | The chrome, in the control's pixels. |
| `tkComboBox_GetTextRect( hCombo, byref rc ) as boolean` | The caption box. Returns TRUE with an **empty** rect in arrow-only mode — empty is the honest answer, and failing would conflate "no caption" with "not sized yet". |
| `tkComboBox_GetChevronRect( hCombo, byref rc ) as boolean` | The chevron cell. |
| `tkComboBox_GetVisualRect( hCombo, byref rc ) as boolean` | The chrome inflated by the focus-ring band. |

The four rect queries force any pending layout first, so their results are always current. Each returns FALSE — leaving `rc` empty — while the control has no size yet.

### Appearance

| Procedure | Description |
|---|---|
| `tkComboBox_GetColors( hCombo, pColors as TKCOMBOBOX_COLORS ptr )` | Fills your struct with the control's current colours. |
| `tkComboBox_SetColors( hCombo, pColors as TKCOMBOBOX_COLORS ptr )` | Copies the whole struct in, **pins** it against theme changes, and repaints. Also re-derives the list's colours — unless you have claimed them with `tkComboBox_SetListColors`. |
| `tkComboBox_ThemeColors( t ) as TKCOMBOBOX_COLORS` | The colour set a theme gives the control (see *Where the colours come from*). |
| `tkComboBox_ApplyTheme( hCombo, t )` | Applies a theme: its shape, unless pinned, and its colours, unless pinned, re-deriving the list's colours. The control calls this itself on `TKM_THEMECHANGED`. |
| `tkComboBox_UnpinColors( hCombo )` | Drops the colour pin and re-applies the current theme. |
| `tkComboBox_GetFont( hCombo ) as TTF_Font ptr` | The font you handed in, or 0 (the window's default font is then used). |
| `tkComboBox_SetFont( hCombo, f )` | Sets the font and re-measures. **Borrowed, never owned**. It is also the measuring font and the list's font, so button and list always agree about widths. Turning editable mode on hands it to the edit. |
| `tkComboBox_ApplyFonts( hCombo, fText, fGlyph )` | Sets the text font when `fText` is not 0. `fGlyph` is unused: the chevron and checkmark are geometry. |
| `tkComboBox_GetPlaceholderText( hCombo ) as ustring` | The placeholder string, or `""`. |
| `tkComboBox_SetPlaceholderText( hCombo, Text )` | The string drawn when nothing is selected; `""` draws nothing. Repaint only — the placeholder is **never measured**. |

### Tooltip

| Procedure | Description |
|---|---|
| `tkComboBox_SetTooltipText( hCombo, Text )` | The tooltip shown while the pointer rests on the combo, its edit box included; `""` = none. Pressing the button, opening the list or disabling the control hides it. |
| `tkComboBox_GetTooltipText( hCombo ) as ustring` | The tooltip text. |
| `tkComboBox_GetTooltipHandle( hCombo ) as TK_TIP ptr` | The combo's [tkTooltip](tkTooltip), for any `tkTooltip_*` call (title, glyph, style, colours). Owned by the combo. |
| `tkComboBox_SetHoverTime( hCombo, ms )` | The initial delay before the tip appears (`TK_TIPDELAY_INITIAL`). |
| `tkComboBox_SetAutoPopTime( hCombo, ms )` | The auto-pop delay: how long the tip stays up (`TK_TIPDELAY_AUTOPOP`). |
| `tkComboBox_SetReshowTime( hCombo, ms )` | The reshow delay (`TK_TIPDELAY_RESHOW`). |

### Callback registration

| Procedure | Description |
|---|---|
| `tkComboBox_SetPaintCallback( hCombo, usersub )` | Installs a renderer that draws the whole **button** instead of the built-in painter. Repaints. |
| `tkComboBox_PaintDefault( pi )` | From inside a paint callback, draws the button as the built-in painter would. |
| `tkComboBox_SetMessageCallback( hCombo, userfunc )` | Installs an observer for mouse, wheel, focus and key messages. |
| `tkComboBox_SetSelChangeCallback( hCombo, usersub )` | Installs the handler told when the **user** changes the selection. |
| `tkComboBox_SetDropDownCallback( hCombo, usersub )` | Installs the handler told when the list opens or closes — **including programmatically**. |

### Editable mode

| Procedure | Description |
|---|---|
| `tkComboBox_SetEditable( hCombo, bEditable )` | Creates (TRUE) or destroys (FALSE) the edit over the text area. See *Editable mode*. |
| `tkComboBox_GetEditable( hCombo ) as boolean` | Whether the combo is editable. |
| `tkComboBox_SetEditText( hCombo, Text )` | Sets the edit's text, silently. The selection is not changed. Does nothing when not editable. |
| `tkComboBox_GetEditHandle( hCombo ) as TK_WIDGET ptr` | The edit (a [tkTextBox](tkTextBox)), or 0 when not editable. |
| `tkComboBox_SetEditChangeCallback( hCombo, usersub )` | Told when the user changes the edit's text. |
| `tkComboBox_SetEditEnterCallback( hCombo, usersub )` | Told when the user presses Enter in the edit. |

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKCOMBOBOX_DEFAULT_PADLEFT = 12
const TKCOMBOBOX_DEFAULT_PADRIGHT = 10
const TKCOMBOBOX_DEFAULT_PADTOP = 6
const TKCOMBOBOX_DEFAULT_PADBOTTOM = 6
const TKCOMBOBOX_DEFAULT_TEXTGAP = 8
const TKCOMBOBOX_DEFAULT_CHEVRONW = 9 ' odd, so the glyph comes to a point
const TKCOMBOBOX_DEFAULT_CHEVRONH = 12
const TKCOMBOBOX_DEFAULT_CHEVRONGAP = 3
const TKCOMBOBOX_DEFAULT_CURVATURE = 12 ' a DIAMETER
const TKCOMBOBOX_DEFAULT_BORDERTHICK = 1 ' not scaled
const TKCOMBOBOX_DEFAULT_FOCUSGAP = 2
const TKCOMBOBOX_DEFAULT_FOCUSTHICK = 1 ' not scaled
const TKCOMBOBOX_DEFAULT_LISTITEMHEIGHT = 24
const TKCOMBOBOX_DEFAULT_LISTCHECKCOL = 30 ' the left checkmark gutter
const TKCOMBOBOX_DEFAULT_LISTRIGHTCOL = 20
const TKCOMBOBOX_DEFAULT_LISTMAXROWS = 12 ' the list scrolls past this many

enum
    CBO_TEXT_ALWAYS = 0
    CBO_TEXT_NEVER
    CBO_TEXT_WHENSELECTED
end enum
```

### Types

```freebasic
type TKCOMBOBOX_COLORS
    BackColor            as ulong = &hFF2C313Aul
    ForeColor            as ulong = &hFFC8CDD6ul
    BorderColor          as ulong = &hFF2C313Aul    ' = BackColor: borderless by default
    ChevronColor         as ulong = &hFFC8CDD6ul    ' = ForeColor
    BackColorHot         as ulong = &hFF373D48ul
    ForeColorHot         as ulong = &hFFE2E6EEul
    BorderColorHot       as ulong = &hFF373D48ul
    ChevronColorHot      as ulong = &hFFE2E6EEul
    BackColorOpen        as ulong = &hFF2C313Aul    ' = BackColor, NOT BackColorHot
    ForeColorOpen        as ulong = &hFF61AFEFul
    BorderColorOpen      as ulong = &hFF2C313Aul
    ChevronColorOpen     as ulong = &hFF61AFEFul
    BackColorDisabled    as ulong = &hFF282C33ul
    ForeColorDisabled    as ulong = &hFF606670ul
    BorderColorDisabled  as ulong = &hFF282C33ul
    ChevronColorDisabled as ulong = &hFF606670ul
    ForeColorPlaceholder as ulong = &hFF787E88ul
    FocusRingColor       as ulong = &hFF61AFEFul
end type

type TKCOMBOBOX_ITEM
    wszText   as ustring
    id        as long
    itemData  as integer
    isEnabled as boolean = true
end type

type TKCOMBOBOX_PAINTINFO
    hCombo        as TK_WIDGET ptr
    b             as TK_PAINT ptr
    rcClient      as TKRECT
    rcButton      as TKRECT
    rcText        as TKRECT
    rcChevron     as TKRECT
    rcVisual      as TKRECT
    isHot         as boolean
    isOpen        as boolean
    isEnabled     as boolean
    isFocused     as boolean
    nCurSel       as long
    wszText       as ustring
    isPlaceholder as boolean
    isTextVisible as boolean
end type

type TKCOMBOBOX_MESSAGEINFO
    hCombo as TK_WIDGET ptr
    msg    as long                    ' TKM_*
    x      as single
    y      as single
    key    as long
    mods   as long
end type

type TKCOMBOBOX_STATE   ' per-instance state; reach it through the procedures

type CBO_PaintCallbackSub as sub( byval p as TKCOMBOBOX_PAINTINFO ptr )
type CBO_MessageCallbackFunc as function( byval m as TKCOMBOBOX_MESSAGEINFO ptr ) as boolean
type CBO_SelChangeCallbackSub as sub( byval hCombo as TK_WIDGET ptr, byval idxOld as long, byval idxNew as long )
type CBO_DropDownCallbackSub as sub( byval hCombo as TK_WIDGET ptr, byval isOpen as boolean )
type CBO_EditCallbackSub as sub( byval hCombo as TK_WIDGET ptr )
```

### Procedures

```freebasic
function tkComboBox_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkComboBox_GetID( byval hCombo as TK_WIDGET ptr ) as long
function tkComboBox_AddItem( byval hCombo as TK_WIDGET ptr, byval Text as ustring, byval id as long = 0, byval itemData as integer = 0 ) as long
function tkComboBox_InsertItem( byval hCombo as TK_WIDGET ptr, byval idx as long, byval Text as ustring, byval id as long = 0, byval itemData as integer = 0 ) as long
function tkComboBox_DeleteItem( byval hCombo as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkComboBox_Clear( byval hCombo as TK_WIDGET ptr )
function tkComboBox_GetCount( byval hCombo as TK_WIDGET ptr ) as long
function tkComboBox_IsValidItem( byval hCombo as TK_WIDGET ptr, byval idx as long ) as boolean
function tkComboBox_GetItemText( byval hCombo as TK_WIDGET ptr, byval idx as long ) as ustring
function tkComboBox_SetItemText( byval hCombo as TK_WIDGET ptr, byval idx as long, byval Text as ustring ) as boolean
function tkComboBox_GetItemID( byval hCombo as TK_WIDGET ptr, byval idx as long ) as long
function tkComboBox_SetItemID( byval hCombo as TK_WIDGET ptr, byval idx as long, byval id as long ) as boolean
function tkComboBox_GetItemData( byval hCombo as TK_WIDGET ptr, byval idx as long ) as integer
function tkComboBox_SetItemData( byval hCombo as TK_WIDGET ptr, byval idx as long, byval itemData as integer ) as boolean
function tkComboBox_GetItemEnabled( byval hCombo as TK_WIDGET ptr, byval idx as long ) as boolean
function tkComboBox_SetItemEnabled( byval hCombo as TK_WIDGET ptr, byval idx as long, byval bEnabled as boolean ) as boolean
function tkComboBox_FindItemByID( byval hCombo as TK_WIDGET ptr, byval id as long ) as long
function tkComboBox_FindItemByText( byval hCombo as TK_WIDGET ptr, byval Text as ustring ) as long
function tkComboBox_GetCurSel( byval hCombo as TK_WIDGET ptr ) as long
function tkComboBox_SetCurSel( byval hCombo as TK_WIDGET ptr, byval idx as long ) as boolean
function tkComboBox_GetText( byval hCombo as TK_WIDGET ptr ) as ustring
function tkComboBox_GetEnabled( byval hCombo as TK_WIDGET ptr ) as boolean
sub tkComboBox_SetEnabled( byval hCombo as TK_WIDGET ptr, byval isEnabled as boolean )
function tkComboBox_GetFocused( byval hCombo as TK_WIDGET ptr ) as boolean
function tkComboBox_GetHot( byval hCombo as TK_WIDGET ptr ) as boolean
sub tkComboBox_Refresh( byval hCombo as TK_WIDGET ptr )
function tkComboBox_IsDroppedDown( byval hCombo as TK_WIDGET ptr ) as boolean
function tkComboBox_DropDown( byval hCombo as TK_WIDGET ptr ) as boolean
sub tkComboBox_CloseUp( byval hCombo as TK_WIDGET ptr )
function tkComboBox_GetListHandle( byval hCombo as TK_WIDGET ptr ) as TK_HOST ptr
function tkComboBox_GetListItemRect( byval hCombo as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkComboBox_GetListHot( byval hCombo as TK_WIDGET ptr ) as long
function tkComboBox_GetListTopIndex( byval hCombo as TK_WIDGET ptr ) as long
function tkComboBox_GetListScrollBar( byval hCombo as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkComboBox_SetListColors( byval hCombo as TK_WIDGET ptr, byval pColors as TKPOPUPMENU_COLORS ptr )
sub tkComboBox_GetListColors( byval hCombo as TK_WIDGET ptr, byval pColors as TKPOPUPMENU_COLORS ptr )
sub tkComboBox_SetListItemHeight( byval hCombo as TK_WIDGET ptr, byval nItemHeight as long )
function tkComboBox_GetListItemHeight( byval hCombo as TK_WIDGET ptr ) as long
sub tkComboBox_SetListMaxRows( byval hCombo as TK_WIDGET ptr, byval nRows as long )
function tkComboBox_GetListMaxRows( byval hCombo as TK_WIDGET ptr ) as long
function tkComboBox_GetTextMode( byval hCombo as TK_WIDGET ptr ) as long
sub tkComboBox_SetTextMode( byval hCombo as TK_WIDGET ptr, byval nTextMode as long )
function tkComboBox_GetShowText( byval hCombo as TK_WIDGET ptr ) as boolean
sub tkComboBox_SetShowText( byval hCombo as TK_WIDGET ptr, byval bShowText as boolean )
function tkComboBox_GetAutoSize( byval hCombo as TK_WIDGET ptr ) as boolean
sub tkComboBox_SetAutoSize( byval hCombo as TK_WIDGET ptr, byval bAutoSize as boolean )
sub tkComboBox_GetPadding( byval hCombo as TK_WIDGET ptr, byref nLeft as long, byref nTop as long, byref nRight as long, byref nBottom as long )
sub tkComboBox_SetPadding( byval hCombo as TK_WIDGET ptr, byval nLeft as long, byval nTop as long, byval nRight as long, byval nBottom as long )
function tkComboBox_GetTextGap( byval hCombo as TK_WIDGET ptr ) as long
sub tkComboBox_SetTextGap( byval hCombo as TK_WIDGET ptr, byval nTextGap as long )
sub tkComboBox_GetChevronSize( byval hCombo as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
sub tkComboBox_SetChevronSize( byval hCombo as TK_WIDGET ptr, byval nWidth as long, byval nHeight as long )
function tkComboBox_GetChevronGap( byval hCombo as TK_WIDGET ptr ) as long
sub tkComboBox_SetChevronGap( byval hCombo as TK_WIDGET ptr, byval nGap as long )
function tkComboBox_GetChevronThickness( byval hCombo as TK_WIDGET ptr ) as long
sub tkComboBox_SetChevronThickness( byval hCombo as TK_WIDGET ptr, byval nThickness as long )
function tkComboBox_GetCornerCurvature( byval hCombo as TK_WIDGET ptr ) as long
sub tkComboBox_SetCornerCurvature( byval hCombo as TK_WIDGET ptr, byval nCurvature as long )
function tkComboBox_GetBorderThickness( byval hCombo as TK_WIDGET ptr ) as long
sub tkComboBox_SetBorderThickness( byval hCombo as TK_WIDGET ptr, byval nThickness as long )
sub tkComboBox_GetFocusRing( byval hCombo as TK_WIDGET ptr, byref nGap as long, byref nThickness as long )
sub tkComboBox_SetFocusRing( byval hCombo as TK_WIDGET ptr, byval nGap as long, byval nThickness as long )
sub tkComboBox_GetIdealSize( byval hCombo as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkComboBox_GetButtonRect( byval hCombo as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkComboBox_GetTextRect( byval hCombo as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkComboBox_GetChevronRect( byval hCombo as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkComboBox_GetVisualRect( byval hCombo as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkComboBox_GetColors( byval hCombo as TK_WIDGET ptr, byval pColors as TKCOMBOBOX_COLORS ptr )
sub tkComboBox_SetColors( byval hCombo as TK_WIDGET ptr, byval pColors as TKCOMBOBOX_COLORS ptr )
function tkComboBox_ThemeColors( byref t as TKTHEME_COLORS ) as TKCOMBOBOX_COLORS
sub tkComboBox_ApplyTheme( byval hCombo as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkComboBox_UnpinColors( byval hCombo as TK_WIDGET ptr )
function tkComboBox_GetFont( byval hCombo as TK_WIDGET ptr ) as TTF_Font ptr
sub tkComboBox_SetFont( byval hCombo as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkComboBox_ApplyFonts( byval hCombo as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
function tkComboBox_GetPlaceholderText( byval hCombo as TK_WIDGET ptr ) as ustring
sub tkComboBox_SetPlaceholderText( byval hCombo as TK_WIDGET ptr, byval Text as ustring )
sub tkComboBox_SetPaintCallback( byval hCombo as TK_WIDGET ptr, byval usersub as CBO_PaintCallbackSub )
sub tkComboBox_PaintDefault( byval pi as TKCOMBOBOX_PAINTINFO ptr )
sub tkComboBox_SetTooltipText( byval hCombo as TK_WIDGET ptr, byval Text as ustring )
function tkComboBox_GetTooltipText( byval hCombo as TK_WIDGET ptr ) as ustring
function tkComboBox_GetTooltipHandle( byval hCombo as TK_WIDGET ptr ) as TK_TIP ptr
sub tkComboBox_SetHoverTime( byval hCombo as TK_WIDGET ptr, byval ms as long )
sub tkComboBox_SetAutoPopTime( byval hCombo as TK_WIDGET ptr, byval ms as long )
sub tkComboBox_SetReshowTime( byval hCombo as TK_WIDGET ptr, byval ms as long )
sub tkComboBox_SetMessageCallback( byval hCombo as TK_WIDGET ptr, byval userfunc as CBO_MessageCallbackFunc )
sub tkComboBox_SetSelChangeCallback( byval hCombo as TK_WIDGET ptr, byval usersub as CBO_SelChangeCallbackSub )
sub tkComboBox_SetDropDownCallback( byval hCombo as TK_WIDGET ptr, byval usersub as CBO_DropDownCallbackSub )
sub tkComboBox_SetEditable( byval hCombo as TK_WIDGET ptr, byval bEditable as boolean )
function tkComboBox_GetEditable( byval hCombo as TK_WIDGET ptr ) as boolean
sub tkComboBox_SetEditText( byval hCombo as TK_WIDGET ptr, byval Text as ustring )
function tkComboBox_GetEditHandle( byval hCombo as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkComboBox_SetEditChangeCallback( byval hCombo as TK_WIDGET ptr, byval usersub as CBO_EditCallbackSub )
sub tkComboBox_SetEditEnterCallback( byval hCombo as TK_WIDGET ptr, byval usersub as CBO_EditCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkPopupMenu](tkPopupMenu), [tkTextBox](tkTextBox), [tkTheme](tkTheme)
