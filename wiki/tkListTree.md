[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkListTree**

# tkListTree

Shows a scrolling list of rows you paint that is also a tree, with columns and editing.

tkListTree is a list box and a tree view in one control. Rows have a fixed height and are drawn by your paint callback; the control decides which rows are visible, where they sit and what state each is in. A flat list, a grouped list (collapsible header rows), a report with resizable columns and a tree of any depth with twisties are all the same control. It also does single, multiple and extended selection, per-row tooltips, in-place label editing, drag reordering and check boxes (two- or three-state, with a tri-state cascade over a tree).

Reach for it for a file pane, a results list, a symbol browser or a settings tree. Rows are addressed by **model index**, the order you added them: collapsing a group or a node hides rows but never renumbers anything, and selection stays on the rows across a collapse.

The control builds its own parts: the row surface, a [tkVScrollBar](tkVScrollBar) that shows only while the rows overflow, and a [tkColumnHeader](tkColumnHeader) band that starts hidden. The in-place editor is a [tkTextBox](tkTextBox). Setters are silent; the callbacks fire only for what the user does.

## Importing

```freebasic
#import "vendor/tkControls/tkListTree"
using tkListTree
using tkHost
using tkPaint
```

The module brings in [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkTextBox](tkTextBox), [tkColumnHeader](tkColumnHeader), [tkVScrollBar](tkVScrollBar), [tkScrollBar](tkScrollBar) and [tkCheckBox](tkCheckBox) (for the check boxes' colour struct and painter). Add `using tkColumnHeader` to name the `HDR_*` callback types for the column band.

## Example

A tree with twisties and rename-in-place, using the built-in row painter. `gHost` is the window ([tkHost](tkHost)); `gFont10` is a font opened with `tkHost_OpenFont`.

```freebasic
sub OnSel( byval hList as TK_WIDGET ptr, byval row as integer )
    print "selected: "; tkListTree_GetText( hList, row )
end sub

sub PaintRow( byval p as TKLISTTREE_PAINTINFO ptr )
    tkListTree_PaintRowDefault( p )
end sub

dim as TK_WIDGET ptr gTree = tkListTree_Create( tkHost_Root( gHost ), 1020 )
tkListTree_SetFont( gTree, gFont10 )
tkListTree_SetPaintCallback( gTree, @PaintRow )
tkListTree_SetSelChangeCallback( gTree, @OnSel )
tkListTree_SetTreeIndent( gTree, true )
tkListTree_ShowTwisty( gTree, true )
tkListTree_EnableLabelEdit( gTree, true )
tkListTree_SetBorderWidth( gTree, 1 )

dim as integer proj = tkListTree_AddNode( gTree, -1, "MyProject" )
dim as integer src = tkListTree_AddNode( gTree, proj, "src" )
tkListTree_AddNode( gTree, src, "main.tiko" )
dim as integer docs = tkListTree_AddNode( gTree, proj, "docs" )
tkListTree_AddNode( gTree, docs, "README.md" )
tkListTree_SetCurSel( gTree, proj )
tkWidget_SetPos( gTree, 16, 16, 300, 240 )
```

For a report, add columns with `tkListTree_AddColumn`, call `tkListTree_ShowHeader( h, true )` and fill cells with `tkListTree_SetCellText`. Column 0 is the row's text. The toolchain's `examples/tkControls/tkListTree/` shows a grouped list, a report and a tree side by side.

## How it works

### The control and its parts

`tkListTree_Create` returns the container, and every `tkListTree_*` procedure takes it. It
holds the row surface (which takes the focus, the keys and the mouse), the scrollbar and the
header band; they take the ids `CtrlID`, `CtrlID + 1` and `CtrlID + 2`, and the editor
`CtrlID + 3`. Focus given to the container goes straight to the rows. `GetSurface`,
`GetScrollBar`, `GetHeader` and `GetEditor` return the parts for direct calls; never pass one
of them to a `tkListTree_*` procedure.

### Row indices are model indices

Rows are addressed by the order they were added, whatever is on screen. Collapsing does not
renumber anything, and hidden rows keep working with every row procedure, selection included.
Everything you receive (`TKLISTTREE_PAINTINFO.itemID`, `TKLISTTREE_MESSAGEINFO.idx`,
`GetCurSel`, `GetSelItems`, `GetTopIndex`) is a model index. `GetCount` is every row;
`GetVisibleCount` is the rows on show, which differ exactly when something is collapsed.

### Groups and trees

Every row has a tree level (0 = top level), and the tree lives in plain row order: a node's
subtree is the run of deeper rows right after it, so parent, child count and "has children"
are derived. Collapsing a node hides its whole subtree, at any depth.

- `AddNode( h, parentRow, text )` appends a child after the parent's existing subtree
  (`parentRow = -1` for a new top-level node); `InsertNode` places one at a child position
  (clamped; past the end appends). `GetLevel`, `GetParent`, `GetChildCount` and `HasChildren`
  read the shape.
- The flat group is the depth-1 case: `AddHeader` adds a level-0 row flagged as a header, and
  `AddString` / `InsertString` rows after a header (or after one of its items) become its
  level-1 children. Legacy groups do not nest; use `AddNode` for depth.
- A header is otherwise an ordinary row: selectable, returned by `GetSelItems`, carrying
  `itemData`. `IsHeader` tells them apart.
- `CollapseRow`, `ExpandRow`, `ToggleRow` and `SetNodeCollapsed` act on anything that can fold
  (a header, or any node with children) and return false for a leaf; `CollapseAll` /
  `ExpandAll` do every node in one refresh. All are silent.
- `DeleteString` deletes one row; to remove a subtree, delete its descendants too. `Clear`
  removes every row and resets the caret and anchor.

### Selection lives on the rows

Selection is a flag on each row, so it survives a collapse and a hidden row can be selected.

| Mode | How to get it | Mouse |
| --- | --- | --- |
| Single | both flags off (the default) | A click selects exactly one row |
| Extended | `SetExtendedSelect( h, true )` | Shift extends a range from the anchor, Ctrl (Cmd on macOS) toggles one row |
| Multiple | `SetMultiSelect( h, true )` | Every click toggles one row, checklist style |

Turning either mode on turns the other off. `GetCurSel` is the focused row (the caret), which
is not "the selection" once several rows can be selected: use `GetSelItems` for that.
`SetCurSel( h, row )` focuses, selects only that row, sets the anchor and scrolls it into view;
an invalid index clears the selection and the caret and returns -1.

### Painting

One paint of the surface fills it with the back colour and then calls your paint callback
once per visible row. Rows below the last are not painted, so an empty list needs no special
case. **With no paint callback no rows are drawn**; `tkListTree_PaintRowDefault( p )` is a
ready-made painter to call from yours (selected, then hot, then plain colours from the theme,
a focus bar on the caret row while the list has focus, `+` / `-` before a header's caption,
and every cell ellipsised in its own rect).

`p->rc` and the cell rects are surface-local. The control does not clip between cells and
never sorts. In report mode, fill `p->rc` first so selection and hover span the row, then
draw each cell in `cells[i].rc`.

### The scrollbar manages itself

The control creates a [tkVScrollBar](tkVScrollBar), keeps its range in step with the visible
rows, and hides it whenever the rows fit, when the surface takes the full width back. Only its
look is yours: `SetScrollBarWidth`, `SetScrollBarColors`, `SetScrollBarDividerColor`,
`SetScrollBarPaintCallback`, or `GetScrollBar` for direct calls.

The wheel is handled on the surface: 3 rows a notch, at most a page, with partial notches
accumulated. A wheel that cannot move the list further is left unclaimed, so a parent can
scroll.

### Columns

With no columns the list paints as one column and the painter sees `columnCount = 0`. Define
columns (`AddColumn`, `InsertColumn`) and item rows arrive with a `cells` array giving each
column's span; header rows never get cells. The column model lives in the embedded
[tkColumnHeader](tkColumnHeader) (widths, minimums and the fill column); the
`tkListTree_*Column*` procedures delegate to it. The band starts hidden: columns lay out and
rows paint in columns either way, and `ShowHeader( h, true )` adds the interactive strip. It
spans the full width, over the scrollbar strip, so column geometry does not shift when the bar
hides. `GetColumnRect` gives a column's rect in surface-local x, the same x the message
callback carries, which is how to tell which column a click landed in.

- **Column 0 is the row's text.** `GetText` / `SetText` and the cell procedures with `col = 0`
  address the same storage; columns 1..N are sparse per row, and a cell never set reads `""`.
  Inserting or deleting a column shifts every row's cells across that alias (insert at 0 and
  each row's text becomes its column 1).
- **Column definitions and cell text are independent.** Rows can be filled before or after the
  columns exist, and `ClearColumns` keeps the cell text.
- **A spanned row** (`SetRowSpanColumns( h, row, true )`) paints as one cell across the whole
  band, for a note or a "no results" line among columned rows. Its text stays in column 0; the
  painter gets `isSpanned = true`, `columnCount = 1` and a `cells[0]` from column 0's (indented)
  left to the last column's right. A spanned row is exempt from the column shift.
- `SetColumnWidth` is silent; only a user drag or an autosize calls the column-resize
  callback. Subscribe with `tkListTree_SetColumnResizeCallback`, never on the header itself:
  the control uses the header's width-changed slot to repaint the rows.

### Non-selectable rows

`SetRowSelectable( h, row, false )` makes a row impossible to select or focus by any path: a
click changes nothing (the message callback still sees it), the keys step past it, `SetCurSel`
returns -1, `SetSel( ..., true )` returns false, and a Shift range skips it. Marking the current
or a selected row clears its selection and drops the caret, silently. The painter gets
`isSelectable` to grey the row if you like.

### Batch updates

Every structural change rebuilds the visible map and repaints. Wrap a bulk load in
`BeginUpdate` / `EndUpdate` (they nest) and it costs one rebuild. `SetText` and `SetCellText`
repaint only their row, and inside a batch that touched nothing else `EndUpdate` repaints just
those rows; any structural change in the batch makes it a full refresh. `Refresh` rebuilds
and repaints; `InvalidateRow` / `InvalidateRows` repaint rows whose look depends on something
outside the control (a no-op for a hidden or off-screen row); `UpdateNow` paints whatever is
pending at once. `SetItemData`, `SetItemDataExtra` and `SetBackColor` do not repaint.

### Programmatic changes are silent

`SetCurSel`, `SetSel`, `SelectAll`, `Clear`, `MoveRows`, `SetColumnWidth` and the fold setters
fire no callback. SelChange, ExpandCollapse, Activate, DragDrop and the label-edit callbacks
report what the user did, so a setter is safe inside them.

### Units

| Setting | Unit | Default |
| --- | --- | ---: |
| Row height (`SetRowHeight`) | Unscaled: the control scales it | 22 |
| Header height (`SetHeaderHeight`) | Unscaled | 24 |
| Scrollbar width (`SetScrollBarWidth`) | Unscaled | 12 |
| Indent and twisty width | Unscaled | 16 / 16 |
| Column widths and minimums | Pixels, as given | 100 / 0 |
| Border width (`SetBorderWidth`) | Pixels, never scaled: a hairline | 0 |

Hand an unscaled setting a value you have already scaled and it is scaled twice.
`GetItemHeightPx` returns the row height in pixels.

### Keyboard

The surface handles these and they never reach the message callback:

| Key | Action |
| --- | --- |
| Up / Down | Move the caret one visible row |
| Page Up / Page Down | One page |
| Home / End | First / last visible row |
| Left | Collapse an expanded node; otherwise jump to its parent |
| Right | Expand a collapsed node; otherwise step to its first child |
| Space | Toggle the caret row's selection (multiple, extended), or select it (single). With check boxes on: toggle the caret row's check, and Ctrl+Space is the selection toggle |
| `+` / `-` | With check boxes on: check / uncheck the caret row (keypad, or the `=+` key) |
| F2 | Edit the caret row, when label editing is on |
| Enter | Edit (with `SetEnterEdits`), else activate (with an Activate callback) |

Shift and Ctrl modify the moves as they modify a click; in multiple mode the arrows move the
caret without selecting. Every move keeps the caret row on screen and skips non-selectable
rows. Tab and other keys reach the host. SelChange is the only way to observe keyboard
navigation.

### Hover, tooltips and focus

One row is hot at a time, cleared when the pointer leaves. The tooltip text is your tooltip
callback's (`""` for no tip), else the row's own text; it is asked again when the hot row
changes. The initial delay is 250 ms; `SetHoverTime`, `SetAutoPopTime` and `SetReshowTime`
change the delays, and `GetTooltipHandle` returns the `TK_TIP ptr` for
[tkTooltip](tkTooltip) calls.

A left press gives the rows the focus before anything else happens. If the list must not keep
it (an autocomplete list over an editor, say), give it back from the message callback.

### Drag reorder

`SetDragReorder( h, true )` (off by default) lets the user drag rows within the list.

- Press a row and move past a small threshold. If the pressed row is part of a
  multi-selection, the whole selection moves, gathered at the drop in its original order;
  otherwise just that row. Headers and non-selectable rows never drag.
- A line shows the gap the rows will land in. Dropping on a header outlines it and puts the
  block right after it, as its first rows, expanding it.
- Near the top or bottom edge the list scrolls. Escape, or losing the mouse capture, cancels
  with nothing moved. Only an active drag holds the capture.
- CanDrop runs just before the move (return false to refuse) and DragDrop just after.
  `tkListTree_MoveRows( h, srcRows(), insertBefore )` does the same move silently: the sources
  are de-duplicated, kept in order, headers ignored, selection travels with each row, the block
  becomes the caret and anchor, and the new first index is returned (-1 if nothing moved).
- `SetDragIndicatorColor` sets the line and outline colour; `IsDragging` is true during a drag.

### Twisties and indentation

Both are off by default, so a flat or grouped list is unchanged. `SetTreeIndent( h, true )`
indents column 0 by depth (`SetIndentWidth`), and `ShowTwisty( h, true )` reserves a band
(`SetTwistyWidth`) and draws the expand/collapse mark after your painter runs: a drawn chevron,
or the `SetTwistyGlyphs` glyphs once `SetTwistyFont` gives it a font, in `SetTwistyColor`.
With the twisty on, clicking it folds the node without touching the selection and clicking
the label selects; a legacy header folds on a click anywhere and leaves the selection alone.

`p->indent` is the depth indent plus the twisty band: draw column-0 text at
`p->rc.left + p->indent` when there are no cells (with columns, `cells[0].rc` is already
indented). To draw your own mark, turn the twisty off and use `p->rcTwisty`, `p->level`,
`p->hasChildren` and `p->isExpanded`.

### In-place label editing

`EnableLabelEdit( h, true )` turns it on. An edit starts on F2 on the caret row, on
`BeginEdit`, with `SetClickToEdit( h, true )` on a click on the row that is already current,
and with `SetEnterEdits( h, true )` on Enter (which then no longer activates). Enter commits,
Escape cancels, and focus leaving the editor commits. Because the editor sits over a row,
scrolling, resizing the list or a fold setter commits it first.

- F2, Enter and click-to-edit all open the column `SetEditColumn` names (default 0). `BeginEdit(
  h, row, col )` can open any column; to edit another column from a click, find it with
  `GetColumnRect` in the message callback. Column 0's editor starts past the indent and the
  twisty.
- The editor is a [tkTextBox](tkTextBox), created on the first edit and hidden between edits.
  It uses the list's font, and the theme's colours or those of `SetEditColors` (which a
  theme change replaces unless the list's colours are pinned). `SetEditTextInset` lines its
  text up with your painter's cell inset; `SetEditSelectAll( h, false )` puts the caret at the
  end instead of selecting everything.
- BeginLabelEdit can veto an edit before it starts; EndLabelEdit gets the new text on a commit
  and can refuse it (the row keeps its text). Neither runs for a cancel. `GetEditCol` still
  reports the column while EndLabelEdit runs, so a host can refuse edits of other columns.
- `BeginEdit` returns false when editing is off, the row is non-selectable or hidden, or the
  veto refuses; `EndEdit( h, bCommit )` returns true when the model was written.

### Check boxes

`SetCheckBoxes( h, true )` gives every non-header row a box, in a band after the twisty. A row's
state is `LT_CHECK_UNCHECKED`, `LT_CHECK_CHECKED` or `LT_CHECK_MIXED` (the same values as
[tkCheckBox](tkCheckBox)'s `CHK_STATE_*`). It travels with the row like its selection, and is
independent of it. Check boxes are off by default; with them off, nothing about the list changes.

- **Layout.** The band is 20 wide and the box 16, unscaled. The box is never taller than the row
  less 2 a side, and it is centred in the band. Every non-header row reserves the band, so text keeps
  its column on a row with no box. `pi->indent`, column 0's cell and the label editor all start after
  it. Legacy header rows (`AddHeader`) never have a box. `GetCheckRect( h, row, rc )` answers the
  box's cell, surface-local.
- **The user.** A press on the box and a release over it toggle the check. The press is captured;
  sliding off cancels it. The row becomes the caret row, the selection is left alone, and the press
  neither starts a drag nor click-to-edit. A double click on the box is two toggles and never
  activates. `SetCheckOnClick( h, true )` makes a click on the row select it and toggle it. Space
  toggles the caret row; when the caret row is selected among others, every selected row follows it.
  `+` / `-` check and uncheck. A non-selectable row's box is drawn disabled and never toggles.
- **Modes.** `SetCheckMode( h, LT_CHECKMODE_THREESTATE )` makes a user toggle cycle unchecked,
  checked, mixed. `SetCheckCascade( h, true )` makes a user toggle take the row's subtree with it and
  re-derive its ancestors: a parent is checked when all its direct children are, unchecked when none
  are, and mixed otherwise. Rows that are not checkable are left out. Clicking a mixed box checks it,
  and with the cascade on a toggle is never three-state. `RecomputeChecks` derives every parent from
  its children in one pass, for after a bulk load.
- **Setters are silent:** `SetCheck( h, row, state, bCascade )` (bCascade applies the cascade as a user
  toggle would), `CheckAll`, `SetRowCheckable`, `RecomputeChecks`. The queries are `GetCheck`,
  `GetCheckedCount` (checked rows, not mixed ones), `GetCheckedItems( h, rows() )` (in row order) and
  `GetRowCheckable`.
- **Events.** Each gesture fires one `ItemCheck` before the change (vetoable; it may rewrite the new
  state) and one `ItemChecked` after it, however many rows changed. See Callbacks.
- **Painting.** The control paints the box after your row painter, as it paints the twisty, through
  `tkCheckBox_PaintMark`. `SetCheckOwnerDraw( h, true )` leaves it to your painter, which gets
  `rcCheck`, `checkState`, `isCheckable`, `isCheckHot` and `isCheckPressed`. The message callback's
  `onCheck` says a press was on the box.

## Colours

There is no colour struct: every row pixel is your painter's. What the control paints itself
follows the theme until a setter pins it (`SetBackColor`, `SetBorderColor`,
`SetTwistyColor`, `SetDragIndicatorColor`, `SetScrollBarColors`); `UnpinColors` hands them
back.

| Setting | Theme role | Paints |
| --- | --- | --- |
| `SetBackColor` | `Window` | The whole surface, behind and below the rows |
| `SetBorderColor` | `Border` | The frame, when the border width is not 0 |
| `SetTwistyColor` | `TextDim` | The twisty |
| `SetDragIndicatorColor` | `Accent` | The drop line and header outline |
| `SetScrollBarColors` | `Window`, `Border`, `TextDisabled` | The track, thumb and active thumb |
| `SetEditColors` | `Surface`, `Text`, `Border`, `FocusRing` | The editor |
| `SetHeaderBackColor` | the header's own | The column band |
| `SetCheckColors` | `tkCheckBox_ThemeColors` | The check boxes (a `TKCHECKBOX_COLORS`, pinned on its own; `UnpinColors` unpins it too) |

The border width follows the theme's `BorderWidth` until `SetBorderWidth` is called; the rows,
scrollbar and band are inset by it. The paint callback gets the state flags and resolves them:
at most one row is hot; hot and selected can both be true; `isFocused` marks the caret row and
is independent of selection; `hasFocus` says the rows have the keyboard focus.

## Callbacks

- **Paint**, `LT_PaintCallbackSub( p )`: one row, called for every visible row on every
  repaint, so keep it cheap. The surface is already filled and the list's font selected.
  `TKLISTTREE_PAINTINFO` carries the control (`hList`), the model index, the row rect, the hot,
  selected, focused, has-focus, header, collapsed, spanned and selectable flags, the caption,
  the tree fields (`level`, `hasChildren`, `isExpanded`, `indent`, `rcTwisty`, empty for a
  leaf or with the twisty off) and `columnCount` / `cells`. `cells` is control-owned scratch,
  valid only during the call.
- **Message**, `LT_MessageCallbackFunc( m )`: an observer of the surface's mouse messages,
  with surface-local `x` / `y`, `clicks`, `wheelY`, `idx` (the model row, or -1) and the Ctrl
  and Shift state. `TKM_MOUSEMOVE` carries the row under the pointer and `TKM_MOUSELEAVE`
  -1. `TKM_LBUTTONDOWN`, `TKM_LBUTTONUP` and `TKM_RBUTTONDOWN` arrive only over a row, and for
  the press the control's own handling (focus, selection, fold) has already run. The wheel
  arrives only when it scrolled the list. The return value changes nothing, except for a
  double click (`TKM_LBUTTONDOWN` with `clicks = 2`), where true stops the activation.
- **Tooltip**, `LT_TooltipCallbackFunc( h, row, col ) as ustring`: the tip for a row, asked
  only when one is about to show. `col` is the column the pointer was over: 0 with no columns,
  -1 past the last.
- **SelChange**, `LT_SelChangeCallbackSub( h, row )`: the user moved the caret, by click or
  key; `row` is the new caret row, and `GetCurSel` already agrees. It does not fire when the
  caret did not actually move.
- **Activate**, `LT_ActivateCallbackSub( h, row )`: the row's default action, a double click or
  Enter on the caret row. Setting it is what makes the list claim Enter; `SetEnterEdits` wins
  over it. A non-selectable row is never activated. With `PreventDoubleClick( h, true )` a
  double click is an ordinary click (it selects, or folds a header) and neither it nor the
  release after it is reported.
- **ExpandCollapse**, `LT_ExpandCollapseCallbackSub( h, row, bExpanded )`: the user folded a
  node, with the twisty, a header click, or Left / Right.
- **BeginLabelEdit** / **EndLabelEdit**: see In-place label editing.
- **ItemCheck**, `LT_ItemCheckCallbackFunc( h, row, oldState, byref newState ) as boolean`: just
  before a user's check change, for the row the user touched (not for rows a cascade or the
  selection carries along). False vetoes the gesture; `newState` may be rewritten. `GetCheck` still
  answers the old state.
- **ItemChecked**, `LT_ItemCheckedCallbackSub( h, row, newState )`: once after the whole gesture
  (cascade and selection included), only if any row changed.
- **CanDrop**, `LT_CanDropCallbackFunc( p ) as boolean`: just before a user drop; false refuses
  it. `TKLISTTREE_DROPINFO` (source rows, insert position, whether it is on a header, the target
  row and its `TKLISTTREE_ROWINFO`) is valid only during the call; do not change the model from
  inside.
- **DragDrop**, `LT_DragDropCallbackSub( h, newFirstRow, count )`: just after a user drop; walk
  `newFirstRow .. newFirstRow + count - 1` to resync parallel data.
- **Header callbacks** (`SetColumnClickCallback`, `SetColumnAutoSizeCallback`,
  `SetHeaderPaintCallback`, `SetHeaderTooltipCallback`) and `SetHeaderBackColor` /
  `SetHeaderFont` pass straight to the [tkColumnHeader](tkColumnHeader); those callbacks get
  the header widget, not the list. Passing 0 to any callback setter clears it.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const CLISTTREE_DEFAULT_ROWHEIGHT = 22 ' unscaled
const CLISTTREE_DEFAULT_HEADERHEIGHT = 24 ' unscaled
const CLISTTREE_DEFAULT_SCROLLWIDTH = 12 ' unscaled
const CLISTTREE_DEFAULT_INDENT = 16 ' unscaled
const CLISTTREE_DEFAULT_TWISTY = 16 ' unscaled
const CLISTTREE_DRAG_THRESHOLD = 4 ' scaled: SDL has no SM_CXDRAG
const CLISTTREE_DRAGSCROLL_ZONE = 16 ' scaled
const CLISTTREE_DRAGSCROLL_MS = 60
const CLISTTREE_DEFAULT_CHECKBOX = 16 ' unscaled: the box's side
const CLISTTREE_DEFAULT_CHECKBAND = 20 ' unscaled: the column the box sits in
const LT_CHECK_UNCHECKED = CHK_STATE_UNCHECKED
const LT_CHECK_CHECKED = CHK_STATE_CHECKED
const LT_CHECK_MIXED = CHK_STATE_MIXED

enum
    LT_CHECKMODE_TWOSTATE = 0      ' a user toggle goes unchecked <-> checked; MIXED -> checked
    LT_CHECKMODE_THREESTATE        ' a user toggle cycles unchecked -> checked -> mixed -> unchecked
end enum
```

### Types

```freebasic
type TKLISTTREE_CELLINFO
    iCol    as integer
    rc      as TKRECT
    wszText as ustring
end type

type TKLISTTREE_PAINTINFO
    hList        as TK_WIDGET ptr      ' the control
    itemID       as integer            ' MODEL index
    b            as TK_PAINT ptr
    rc           as TKRECT             ' surface-local
    isHot        as boolean
    isSelected   as boolean
    isFocused    as boolean            ' the caret row
    hasFocus     as boolean            ' the surface has the keyboard focus (tk addition)
    isHeader     as boolean
    isCollapsed  as boolean
    isSpanned    as boolean
    isSelectable as boolean
    wszCaption   as ustring
    level        as integer
    hasChildren  as boolean
    isExpanded   as boolean
    indent       as integer
    rcTwisty     as TKRECT
    rcCheck      as TKRECT             ' the box cell (C1); empty when the row has no box
    checkState   as long               ' LT_CHECK_*
    isCheckable  as boolean            ' a box is drawn on this row
    isCheckHot   as boolean
    isCheckPressed as boolean
    columnCount  as integer
    cells        as TKLISTTREE_CELLINFO ptr
end type

type TKLISTTREE_MESSAGEINFO
    hList   as TK_WIDGET ptr
    msg     as long                    ' TKM_*
    x       as single                  ' surface-local
    y       as single
    clicks  as long
    wheelY  as single
    idx     as integer                 ' MODEL row under the mouse, or -1
    isCtrl  as boolean
    isShift as boolean
    onCheck as boolean                 ' (C1) the point is over the row's check box
end type

type TKLISTTREE_ROWINFO
    IsHeader      as boolean = false
    bCollapsed    as boolean = false
    bSpanColumns  as boolean = false
    bSelectable   as boolean = true
    level         as integer = 0
    selected      as boolean = false
    Text          as ustring
    cells(any)    as ustring           ' columns 1..N, sparse
    itemData      as integer
    itemDataExtra as integer
    check         as ubyte = 0         ' LT_CHECK_* (C1); travels with the row like `selected`
    bCheckable    as boolean = true    ' false: no box, never toggled, left out of the cascade
    declare sub EnsureCells( byval n as integer )
    declare sub TrimCells( byval n as integer )
end type

type TKLISTTREE_DROPINFO
    hList        as TK_WIDGET ptr
    srcRows      as integer ptr
    srcCount     as integer
    insertBefore as integer
    onHeader     as boolean
    targetRow    as integer
    targetInfo   as TKLISTTREE_ROWINFO ptr
end type

type TKLISTTREE_STATE   ' per-instance state; reach it through the procedures

type LT_PaintCallbackSub as sub( byval p as TKLISTTREE_PAINTINFO ptr )
type LT_MessageCallbackFunc as function( byval m as TKLISTTREE_MESSAGEINFO ptr ) as boolean
type LT_TooltipCallbackFunc as function( byval hList as TK_WIDGET ptr, byval row as integer, byval col as integer ) as ustring
type LT_SelChangeCallbackSub as sub( byval hList as TK_WIDGET ptr, byval row as integer )
type LT_ActivateCallbackSub as sub( byval hList as TK_WIDGET ptr, byval row as integer )
type LT_CanDropCallbackFunc as function( byval p as TKLISTTREE_DROPINFO ptr ) as boolean
type LT_DragDropCallbackSub as sub( byval hList as TK_WIDGET ptr, byval newFirstRow as integer, byval count as integer )
type LT_BeginLabelEditCallbackFunc as function( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
type LT_EndLabelEditCallbackFunc as function( byval hList as TK_WIDGET ptr, byval row as integer, byval newText as ustring ) as boolean
type LT_ExpandCollapseCallbackSub as sub( byval hList as TK_WIDGET ptr, byval row as integer, byval bExpanded as boolean )
type LT_ItemCheckCallbackFunc as function( byval hList as TK_WIDGET ptr, byval row as integer, byval oldState as long, byref newState as long ) as boolean
type LT_ItemCheckedCallbackSub as sub( byval hList as TK_WIDGET ptr, byval row as integer, byval newState as long )
```

### Procedures

```freebasic
function tkListTree_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkListTree_AddString( byval hList as TK_WIDGET ptr, byval Text as ustring, byval itemData as integer = 0, byval itemDataExtra as integer = 0 ) as integer
function tkListTree_AddHeader( byval hList as TK_WIDGET ptr, byval Text as ustring, byval itemData as integer = 0, byval itemDataExtra as integer = 0 ) as integer
function tkListTree_InsertString( byval hList as TK_WIDGET ptr, byval row as integer, byval Text as ustring, byval itemData as integer = 0, byval itemDataExtra as integer = 0 ) as integer
function tkListTree_AddNode( byval hList as TK_WIDGET ptr, byval parentRow as integer, byval Text as ustring, byval itemData as integer = 0, byval itemDataExtra as integer = 0 ) as integer
function tkListTree_InsertNode( byval hList as TK_WIDGET ptr, byval parentRow as integer, byval childIndex as integer, byval Text as ustring, byval itemData as integer = 0, byval itemDataExtra as integer = 0 ) as integer
function tkListTree_DeleteString( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
sub tkListTree_Clear( byval hList as TK_WIDGET ptr )
function tkListTree_GetCount( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_GetVisibleCount( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_GetText( byval hList as TK_WIDGET ptr, byval row as integer ) as ustring
function tkListTree_SetText( byval hList as TK_WIDGET ptr, byval row as integer, byval Text as ustring ) as boolean
function tkListTree_GetCellText( byval hList as TK_WIDGET ptr, byval row as integer, byval col as integer ) as ustring
function tkListTree_SetCellText( byval hList as TK_WIDGET ptr, byval row as integer, byval col as integer, byval Text as ustring ) as boolean
function tkListTree_GetItemData( byval hList as TK_WIDGET ptr, byval row as integer ) as integer
function tkListTree_SetItemData( byval hList as TK_WIDGET ptr, byval row as integer, byval itemData as integer ) as boolean
function tkListTree_GetItemDataExtra( byval hList as TK_WIDGET ptr, byval row as integer ) as integer
function tkListTree_SetItemDataExtra( byval hList as TK_WIDGET ptr, byval row as integer, byval itemDataExtra as integer ) as boolean
sub tkListTree_BeginUpdate( byval hList as TK_WIDGET ptr )
sub tkListTree_EndUpdate( byval hList as TK_WIDGET ptr )
sub tkListTree_Refresh( byval hList as TK_WIDGET ptr )
sub tkListTree_InvalidateRow( byval hList as TK_WIDGET ptr, byval row as integer )
sub tkListTree_InvalidateRows( byval hList as TK_WIDGET ptr, byval first_ as integer, byval last_ as integer )
sub tkListTree_UpdateNow( byval hList as TK_WIDGET ptr )
function tkListTree_IsHeader( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_IsCollapsed( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_CollapseRow( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_ExpandRow( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_ToggleRow( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_SetNodeCollapsed( byval hList as TK_WIDGET ptr, byval row as integer, byval bCollapsed as boolean ) as boolean
function tkListTree_CollapseAll( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_ExpandAll( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_GetLevel( byval hList as TK_WIDGET ptr, byval row as integer ) as integer
function tkListTree_GetParent( byval hList as TK_WIDGET ptr, byval row as integer ) as integer
function tkListTree_GetChildCount( byval hList as TK_WIDGET ptr, byval row as integer ) as integer
function tkListTree_HasChildren( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_GetCurSel( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_SetCurSel( byval hList as TK_WIDGET ptr, byval row as integer ) as integer
function tkListTree_GetTopIndex( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_SetTopIndex( byval hList as TK_WIDGET ptr, byval row as integer ) as integer
function tkListTree_GetSel( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_SetSel( byval hList as TK_WIDGET ptr, byval row as integer, byval state as boolean ) as boolean
function tkListTree_GetSelCount( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_GetSelItems( byval hList as TK_WIDGET ptr, selItems() as integer ) as integer
sub tkListTree_SelectAll( byval hList as TK_WIDGET ptr, byval state as boolean )
function tkListTree_SetMultiSelect( byval hList as TK_WIDGET ptr, byval enable as boolean ) as boolean
function tkListTree_SetExtendedSelect( byval hList as TK_WIDGET ptr, byval enable as boolean ) as boolean
function tkListTree_PreventDoubleClick( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_SetRowSpanColumns( byval hList as TK_WIDGET ptr, byval row as integer, byval bSpan as boolean = true ) as boolean
function tkListTree_GetRowSpanColumns( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_SetRowSelectable( byval hList as TK_WIDGET ptr, byval row as integer, byval bSelectable as boolean = true ) as boolean
function tkListTree_GetRowSelectable( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
function tkListTree_SetDragReorder( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_GetDragReorder( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_MoveRows( byval hList as TK_WIDGET ptr, srcRows() as integer, byval insertBefore as integer ) as integer
function tkListTree_SetDragIndicatorColor( byval hList as TK_WIDGET ptr, byval clr as ulong ) as ulong
function tkListTree_GetDragIndicatorColor( byval hList as TK_WIDGET ptr ) as ulong
function tkListTree_IsDragging( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_GetBackColor( byval hList as TK_WIDGET ptr ) as ulong
function tkListTree_SetBackColor( byval hList as TK_WIDGET ptr, byval clr as ulong ) as ulong
function tkListTree_GetRowHeight( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_SetRowHeight( byval hList as TK_WIDGET ptr, byval nHeight as integer ) as integer
function tkListTree_GetItemHeightPx( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_GetFont( byval hList as TK_WIDGET ptr ) as TTF_Font ptr
function tkListTree_SetFont( byval hList as TK_WIDGET ptr, byval f as TTF_Font ptr ) as boolean
function tkListTree_GetBorderWidth( byval hList as TK_WIDGET ptr ) as integer
sub tkListTree_SetBorderWidth( byval hList as TK_WIDGET ptr, byval nWidth as integer )
function tkListTree_GetBorderColor( byval hList as TK_WIDGET ptr ) as ulong
sub tkListTree_SetBorderColor( byval hList as TK_WIDGET ptr, byval clr as ulong )
function tkListTree_SetTreeIndent( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_GetTreeIndent( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_SetIndentWidth( byval hList as TK_WIDGET ptr, byval nWidth as integer ) as integer
function tkListTree_GetIndentWidth( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_ShowTwisty( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_IsTwistyShown( byval hList as TK_WIDGET ptr ) as boolean
sub tkListTree_SetTwistyWidth( byval hList as TK_WIDGET ptr, byval nWidth as integer )
sub tkListTree_SetTwistyColor( byval hList as TK_WIDGET ptr, byval clr as ulong )
sub tkListTree_SetTwistyFont( byval hList as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkListTree_SetTwistyGlyphs( byval hList as TK_WIDGET ptr, byval wszExpanded as ustring, byval wszCollapsed as ustring )
function tkListTree_EnableLabelEdit( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_IsLabelEditEnabled( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_SetClickToEdit( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_SetEditColumn( byval hList as TK_WIDGET ptr, byval col as integer ) as boolean
function tkListTree_GetEditColumn( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_SetEnterEdits( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
sub tkListTree_SetEditColors( byval hList as TK_WIDGET ptr, byval clrBack as ulong, byval clrFore as ulong, byval clrBorder as ulong, byval clrFocusBorder as ulong )
sub tkListTree_SetEditSelectAll( byval hList as TK_WIDGET ptr, byval enable as boolean )
sub tkListTree_SetEditTextInset( byval hList as TK_WIDGET ptr, byval nPx as integer )
function tkListTree_BeginEdit( byval hList as TK_WIDGET ptr, byval row as integer, byval col as integer = 0 ) as boolean
function tkListTree_EndEdit( byval hList as TK_WIDGET ptr, byval bCommit as boolean = true ) as boolean
function tkListTree_IsEditing( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_GetEditRow( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_GetEditCol( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_GetEditor( byval hList as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkListTree_GetTooltipHandle( byval hList as TK_WIDGET ptr ) as TK_TIP ptr
sub tkListTree_SetHoverTime( byval hList as TK_WIDGET ptr, byval ms as long )
sub tkListTree_SetAutoPopTime( byval hList as TK_WIDGET ptr, byval ms as long )
sub tkListTree_SetReshowTime( byval hList as TK_WIDGET ptr, byval ms as long )
function tkListTree_GetScrollBar( byval hList as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkListTree_SetScrollBarWidth( byval hList as TK_WIDGET ptr, byval nWidth as integer )
sub tkListTree_SetScrollBarColors( byval hList as TK_WIDGET ptr, byval backclr as ulong, byval foreclr as ulong, byval foreclrhot as ulong )
sub tkListTree_SetScrollBarDividerColor( byval hList as TK_WIDGET ptr, byval clr as ulong, byval bShow as boolean = true )
sub tkListTree_SetScrollBarPaintCallback( byval hList as TK_WIDGET ptr, byval usersub as VScrollPaintCallbackSub )
function tkListTree_AddColumn( byval hList as TK_WIDGET ptr, byval Text as ustring, byval nWidth as integer = 100, byval nMinWidth as integer = 0, byval itemData as integer = 0 ) as integer
function tkListTree_InsertColumn( byval hList as TK_WIDGET ptr, byval idx as integer, byval Text as ustring, byval nWidth as integer = 100, byval nMinWidth as integer = 0, byval itemData as integer = 0 ) as integer
function tkListTree_DeleteColumn( byval hList as TK_WIDGET ptr, byval idx as integer ) as boolean
sub tkListTree_ClearColumns( byval hList as TK_WIDGET ptr )
function tkListTree_GetColumnCount( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_GetColumnText( byval hList as TK_WIDGET ptr, byval idx as integer ) as ustring
function tkListTree_SetColumnText( byval hList as TK_WIDGET ptr, byval idx as integer, byval Text as ustring ) as boolean
function tkListTree_GetColumnWidth( byval hList as TK_WIDGET ptr, byval idx as integer ) as integer
function tkListTree_SetColumnWidth( byval hList as TK_WIDGET ptr, byval idx as integer, byval nWidth as integer ) as boolean
function tkListTree_GetColumnRect( byval hList as TK_WIDGET ptr, byval idx as integer, byref rc as TKRECT ) as boolean
function tkListTree_GetColumnMinWidth( byval hList as TK_WIDGET ptr, byval idx as integer ) as integer
function tkListTree_SetColumnMinWidth( byval hList as TK_WIDGET ptr, byval idx as integer, byval nMinWidth as integer ) as boolean
function tkListTree_GetFillColumn( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_SetFillColumn( byval hList as TK_WIDGET ptr, byval idx as integer ) as boolean
function tkListTree_ShowHeader( byval hList as TK_WIDGET ptr, byval bShow as boolean = true ) as boolean
function tkListTree_IsHeaderVisible( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_GetHeaderHeight( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_SetHeaderHeight( byval hList as TK_WIDGET ptr, byval nHeight as integer ) as integer
function tkListTree_GetHeader( byval hList as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkListTree_GetSurface( byval hList as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkListTree_SetCheckBoxes( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_GetCheckBoxes( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_SetCheckMode( byval hList as TK_WIDGET ptr, byval nMode as long ) as boolean
function tkListTree_GetCheckMode( byval hList as TK_WIDGET ptr ) as long
function tkListTree_SetCheckCascade( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_GetCheckCascade( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_SetCheckOnClick( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
function tkListTree_GetCheckOnClick( byval hList as TK_WIDGET ptr ) as boolean
function tkListTree_SetCheck( byval hList as TK_WIDGET ptr, byval row as integer, byval state as long, byval bCascade as boolean = false ) as boolean
function tkListTree_GetCheck( byval hList as TK_WIDGET ptr, byval row as integer ) as long
function tkListTree_SetRowCheckable( byval hList as TK_WIDGET ptr, byval row as integer, byval bCheckable as boolean = true ) as boolean
function tkListTree_GetRowCheckable( byval hList as TK_WIDGET ptr, byval row as integer ) as boolean
sub tkListTree_CheckAll( byval hList as TK_WIDGET ptr, byval state as long )
sub tkListTree_RecomputeChecks( byval hList as TK_WIDGET ptr )
function tkListTree_GetCheckedCount( byval hList as TK_WIDGET ptr ) as integer
function tkListTree_GetCheckedItems( byval hList as TK_WIDGET ptr, checkedRows() as integer ) as integer
function tkListTree_GetCheckRect( byval hList as TK_WIDGET ptr, byval row as integer, byref rc as TKRECT ) as boolean
sub tkListTree_SetCheckColors( byval hList as TK_WIDGET ptr, byval pColors as TKCHECKBOX_COLORS ptr )
sub tkListTree_GetCheckColors( byval hList as TK_WIDGET ptr, byval pColors as TKCHECKBOX_COLORS ptr )
function tkListTree_SetCheckOwnerDraw( byval hList as TK_WIDGET ptr, byval enable as boolean = true ) as boolean
sub tkListTree_SetItemCheckCallback( byval hList as TK_WIDGET ptr, byval userfunc as LT_ItemCheckCallbackFunc )
sub tkListTree_SetItemCheckedCallback( byval hList as TK_WIDGET ptr, byval usersub as LT_ItemCheckedCallbackSub )
sub tkListTree_SetPaintCallback( byval hList as TK_WIDGET ptr, byval usersub as LT_PaintCallbackSub )
sub tkListTree_SetMessageCallback( byval hList as TK_WIDGET ptr, byval userfunc as LT_MessageCallbackFunc )
sub tkListTree_SetTooltipCallback( byval hList as TK_WIDGET ptr, byval userfunc as LT_TooltipCallbackFunc )
sub tkListTree_SetSelChangeCallback( byval hList as TK_WIDGET ptr, byval usersub as LT_SelChangeCallbackSub )
sub tkListTree_SetActivateCallback( byval hList as TK_WIDGET ptr, byval usersub as LT_ActivateCallbackSub )
sub tkListTree_SetBeginLabelEditCallback( byval hList as TK_WIDGET ptr, byval userfunc as LT_BeginLabelEditCallbackFunc )
sub tkListTree_SetEndLabelEditCallback( byval hList as TK_WIDGET ptr, byval userfunc as LT_EndLabelEditCallbackFunc )
sub tkListTree_SetExpandCollapseCallback( byval hList as TK_WIDGET ptr, byval usersub as LT_ExpandCollapseCallbackSub )
sub tkListTree_SetCanDropCallback( byval hList as TK_WIDGET ptr, byval userfunc as LT_CanDropCallbackFunc )
sub tkListTree_SetDragDropCallback( byval hList as TK_WIDGET ptr, byval usersub as LT_DragDropCallbackSub )
sub tkListTree_SetColumnResizeCallback( byval hList as TK_WIDGET ptr, byval usersub as HDR_WidthChangedCallbackSub )
sub tkListTree_SetColumnClickCallback( byval hList as TK_WIDGET ptr, byval usersub as HDR_ClickCallbackSub )
sub tkListTree_SetColumnAutoSizeCallback( byval hList as TK_WIDGET ptr, byval userfunc as HDR_AutoSizeCallbackFunc )
sub tkListTree_SetHeaderPaintCallback( byval hList as TK_WIDGET ptr, byval usersub as HDR_PaintCallbackSub )
sub tkListTree_SetHeaderTooltipCallback( byval hList as TK_WIDGET ptr, byval userfunc as HDR_TooltipCallbackFunc )
sub tkListTree_SetHeaderBackColor( byval hList as TK_WIDGET ptr, byval clr as ulong )
sub tkListTree_SetHeaderFont( byval hList as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkListTree_ApplyTheme( byval hList as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkListTree_UnpinColors( byval hList as TK_WIDGET ptr )
sub tkListTree_ApplyFonts( byval hList as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkListTree_PaintRowDefault( byval pi as TKLISTTREE_PAINTINFO ptr )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkColumnHeader](tkColumnHeader), [tkVScrollBar](tkVScrollBar), [tkTextBox](tkTextBox), [tkTooltip](tkTooltip)
- [tkCheckBox](tkCheckBox) (the box painter), [tkCheckedList](tkCheckedList) (a checked list built on these check boxes)
