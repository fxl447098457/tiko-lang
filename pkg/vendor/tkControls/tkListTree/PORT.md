# tkListTree: port notes (from vendor PsListTree)

**Name map:** `PsListTree_*` → `tkListTree_*`; `PSLISTTREE_*` types → `TKLISTTREE_*`. The
handle is the container widget.

Vendor's **unprefixed** callback typedefs take an `LT_` prefix here (`LT_PaintCallbackSub`,
`LT_MessageCallbackFunc`, `LT_SelChangeCallbackSub` …), matching the family's `TXT_`, `HDR_` and
`TB_`. This avoids the name collision vendor's README warns about.

**Kept, nearly verbatim (vendor's model):**
- rows in pre-order with a level per row; parent, child count and subtree extent are derived;
- AddNode / InsertNode placement;
- legacy AddHeader / AddString as the depth-1 case;
- the visible map's single "hide below" integer;
- selection as a row flag, so it survives collapse and includes hidden rows;
- `MoveRows`' stable permutation, with headers ignored;
- BeginUpdate / EndUpdate batch kinds: row contents get a row repaint, shape changes get a
  refresh;
- the column-0 / Text alias and its shift on InsertColumn / DeleteColumn (spanned rows exempt);
- ClearColumns keeps cell text;
- non-selectable rows blocked on every path;
- single / extended / multiple selection;
- the keyboard: arrows, PageUp/PageDown, Home/End, Left/Right fold at any depth, Space, F2,
  Enter;
- a header click folds without selecting; the twisty folds and the label selects;
- SelChange only for a real user change; every setter is silent;
- Activate on double-click or Enter (EnterEdits wins); PreventDoubleClick;
- drag reorder: a threshold, the whole selection drags, a drop on a header makes first
  children, auto-scroll at the edges, Esc / capture loss cancel, CanDrop / DragDrop;
- in-place editing: F2, click-to-edit and Enter on the gesture column; BeginEdit on any column;
  Enter commits, Esc cancels, focus loss commits; Begin / EndLabelEdit veto; edit colours;
  select-all or caret at the end; text inset;
- an edit is committed before a scroll moves rows under it;
- the theme role mapping; colour setters pin; the border is a raw-pixel hairline;
- unscaled row / header / scrollbar / indent / twisty units.

**Changed:**
- The row surface is a widget, and so are the tkVScrollBar (auto-hidden) and the
  tkColumnHeader band. The band starts hidden and spans the scrollbar strip.
- The editor is a tkTextBox child of the surface, created on the first edit and **hidden**
  rather than destroyed when an edit ends. An edit usually ends inside the editor's own
  callback, and destroying it there would free it under itself.
- A double click is `TKM_LBUTTONDOWN` with `clicks = 2` (vendor: `WM_LBUTTONDBLCLK`).
- `TKLISTTREE_MESSAGEINFO.hList` is the **control** (vendor: the row surface). It carries
  surface-local `x`, `y`, `clicks` and `wheelY` instead of wParam / lParam. The message
  callback is an observer for presses, exactly as vendor's.
- Wheel: 3 rows a notch (SDL has no SPI_GETWHEELSCROLLLINES), capped at a page, sub-notch
  deltas accumulated. A wheel against the end is returned unclaimed, so the parent may
  scroll.
- The twisty is a drawn chevron until a glyph font is set (`SetTwistyFont`); then it uses
  vendor's glyphs E70D / E76C.
- The drag threshold is 4 scaled pixels (there is no SM_CXDRAG).
- Tooltips use tkTipHost, with a 250 ms initial delay as vendor. Text comes from the tooltip
  callback, else the row text. `GetTooltipHandle` returns the `TK_TIP ptr`.

**Added:**
- `tkListTree_PaintRowDefault( p )`: PsPlatform's built-in row painter, opt-in. Vendor still
  draws nothing without a paint callback, and so does this.
- `TKLISTTREE_PAINTINFO.hList` and `.hasFocus`.
- Accessors: `GetSurface`, `GetEditor`, `GetItemHeightPx`, `IsDragging`.
- **Check boxes** (2026-11-22, C1 of docs/tkControls/CHECKED-LISTS.md in the claude-docs repo; off
  by default, nothing changes until `SetCheckBoxes`):
  - a state per row (`LT_CHECK_UNCHECKED / CHECKED / MIXED` = tkCheckBox's `CHK_STATE_*`) that travels
    with the row like `selected`; `SetRowCheckable` per row. Legacy header rows never have a box;
  - a band after the twisty (box 16 in a band of 20, unscaled; the box never taller than the row
    less 2 px each side). Every non-header row reserves it, so text keeps its column on an
    uncheckable row. `pi.indent`, column 0's cell and the label editor all start after it.
    `TKLISTTREE_PAINTINFO` gains `rcCheck`, `checkState`, `isCheckable`, `isCheckHot`, `isCheckPressed`;
    `TKLISTTREE_MESSAGEINFO` gains `onCheck`;
  - the control paints the box after the row, as it paints the twisty, through
    `tkCheckBox_PaintMark` with `TKCHECKBOX_COLORS` (theme: `tkCheckBox_ThemeColors`; `SetCheckColors`
    pins apart from the rows' colours; `UnpinColors` unpins both). `SetCheckOwnerDraw` leaves it to
    the host's painter;
  - the box: press + release over it toggles (tkCheckBox's model: captured, cancelled by sliding
    off or by a lost capture); the row becomes the focus row, the selection is untouched, no drag,
    no click-to-edit, a double click is two toggles and never Activate. `SetCheckOnClick`: a row
    click selects and toggles;
  - keys: Space toggles the focus row, and every selected row with it when the focus row is
    selected among others; **Ctrl+Space is the old Space** (selection toggle) while check boxes
    are on; `+` (keypad, `SDLK_PLUS`, the `=+` key) checks and `-` unchecks;
  - `SetCheckMode( LT_CHECKMODE_THREESTATE )`: a user toggle cycles unchecked → checked → mixed;
    `SetCheckCascade`: a user toggle takes the subtree and re-derives the ancestors (all checked /
    all unchecked / mixed, uncheckable rows left out; a mixed box checks); `RecomputeChecks` derives
    every parent in one O(n) reverse pass;
  - events: `ItemCheck( h, row, oldState, byref newState ) as boolean` BEFORE (veto or rewrite),
    `ItemChecked( h, row, newState )` AFTER the whole gesture -- one of each per gesture, however
    many rows changed; setters (`SetCheck`, `CheckAll`, `RecomputeChecks`) are silent;
  - queries: `GetCheck`, `GetCheckedCount`, `GetCheckedItems`, `GetCheckRect`.
  tkListTree now imports tkCheckBox (`public`, for `TKCHECKBOX_COLORS`). Not in controls.toml yet
  (the designer entry is C2).

**Dropped (Win32-only):**
- `FilterMessage`: the host routes Enter and Escape to the focused editor.
- `WM_GETDLGCODE`, the WM_CHAR swallows and `IsCharSwallowArmed`: SDL never beeps.
- `CS_DBLCLKS`.
- The 100 ms hot poll: the host guarantees the leave.
- `SetTooltipMode` / `GetTooltipMode` / `GetPsTooltipHandle`.
- `ProbeRenderedPixel`: use the tkTest pixel probes.
- `PositionWindows` and the four `PSLISTTREE_STATE` helpers.
- PsRegistry.
- `Rescale`: `TKM_SCALECHANGED` re-derives the unscaled metrics.

**Not verified:**
- the interactive pass;
- auto-scroll during a drag (the timer path is not driven by the selftest);
- tooltips (rendering is tkTooltip's, tested there).
