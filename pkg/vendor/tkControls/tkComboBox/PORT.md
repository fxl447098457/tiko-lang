# tkComboBox: port notes (vendor PsComboBox's button + PsPlatform's scrolling list)

**Name map:** `PsComboBox_*` → `tkComboBox_*`; `PSCOMBOBOX_*` → `TKCOMBOBOX_*`.
`CBO_TEXT_*` and the `CBO_*Callback*` types are unchanged. The handle is the widget.

**Kept (vendor, the button):**
- the four-rect layout and its formulas; the width from the WIDEST item; the placeholder never
  measured; the text gap charged only when a caption is drawn; the ideal size valid before
  sizing; a too-narrow control collapses rcText and keeps the chevron;
- `CBO_TEXT_ALWAYS` / `NEVER` / `WHENSELECTED` (the one mode whose width moves), `GetShowText`
  answering "is a caption drawn now", invalid modes ignored;
- the chevron as four strokes, apexes away from the centre, its thickness scaled at paint time;
  the moods disabled > open > hot > idle (no pressed mood: the list opens on the DOWN);
- items with id / itemData / enabled; every mutator silent; the selection fix-ups (insert
  shifts, deleting or disabling the current item clears to -1); `SetCurSel` silent and refusing
  a disabled item;
- the closed-list keyboard: Down/Up clamp and skip disabled items, Up from -1 lands on the last,
  Home/End, Alt+arrows / F4 / Space / Enter open; SelChange for user picks only;
- DropDown callback for programmatic opens too, fired BEFORE the list exists, paired with a
  close on a failed open; on a pick the close is reported before the selection change;
- no capture; focus on the down even when the message callback vetoes the click; the callback's
  answer ignored for SETFOCUS / KILLFOCUS; disabling closes an open list;
- the 18-field colour struct, `ThemeColors`, pinning, the list colours derived from the button's
  (border from `BorderColorHot`) until `SetListColors` claims them; auto-size.

**Changed:**
- **The list is PsPlatform's PsComboList as a tkHost popup surface, not a tkPopupMenu**, so
  vendor's first limit is gone: it **scrolls** past `SetListMaxRows` rows (default 12) with a
  tkVScrollBar, the wheel and PgUp/PgDn. Kept from vendor's menu look: the left checkmark gutter
  (30) and the reserved right column (20), the row height (24), the open list's arrows WRAP.
  The checkmark is drawn as geometry, so no font has to carry U+2713.
- The highlight is PROVISIONAL (PsPlatform): hover or arrows move it, a click or Enter/Space
  commits, Escape / Tab / F4 / Alt+arrow close without a change.
- **The press that dismisses the list is consumed** (tkHost's popup rule), so a click on the
  button while open just closes it — vendor needed a one-shot reopen guard in FilterMessage for
  that — and a click elsewhere closes the list without also activating its target.
- One open chain: another popup opening closes this list at once, and the DropDown(false)
  callback fires then (vendor deferred it to the next non-paint touch).
- `GetListHandle` returns the open list's `TK_HOST ptr` (0 while closed): the list is created per
  open (Wayland cannot re-show an unmapped popup). `SetListColors` / `GetListColors` take a
  `TKPOPUPMENU_COLORS`.
- `FindItemByText` has no 1024-character buffer limit.
- `TKCOMBOBOX_MESSAGEINFO` carries `msg` (TKM_*), `x`, `y`, `key`, `mods`.

**Added:** `SetListMaxRows` / `GetListMaxRows`, `GetListItemHeight`, `GetListItemRect`,
`GetListHot`, `GetListTopIndex`, `GetListScrollBar`, `GetListColors`, `GetHot`, `GetID`; the
wheel steps a FOCUSED, closed combo's selection (PsPlatform; the parent scrolls otherwise).
For the form designer: a tooltip through tkTipHost (`SetTooltipText` / `GetTooltipText`,
`GetTooltipHandle`, the three delays; opening the list hides it), the border following the theme's
BorderWidth until `SetBorderThickness` (which now pins it), and `PaintDefault` for a paint callback.

**Dropped (Win32-only):** `FilterMessage` and the reopen guard, `EnsureList` (no list exists
between opens), `WM_GETDLGCODE` and the WM_CHAR swallow, the 100 ms hover poll and its timer id,
`CS_DBLCLKS`, PsRegistry, `Rescale(oldDpi, newDpi)` (`TKM_SCALECHANGED` scales every stored
metric, the list's too, and closes an open list).

## EDITABLE mode (2026-10-25, for tiko-studio)

Win32's `CBS_DROPDOWN`, which vendor's PsComboBox never had: `tkComboBox_SetEditable( c, true )`.
- **The edit.** A single-line tkTextBox (no border, the combo's colours) lies over the text
  area. The chevron, F4 and Alt+Down still drop the list.
- **Picks fill it.** A pick from the list, or Down/Up from the edit (the key bubbles to the
  combo), fills the edit SILENTLY; SelChange reports the pick.
- **Typing** changes no selection. It notifies `SetEditChangeCallback`; Enter notifies
  `SetEditEnterCallback`. `tkComboBox_GetText` is the edit's text, and `SetEditText` sets it
  silently.
- **Focus.** The combo stops taking focus and the edit takes it. The combo shows its focus ring
  while the edit has the keyboard.
- **Theme.** The edit is re-coloured on a theme change.

Measured: examples/tkControls/tkComboBox 196/196 (28 new, at 1.0 and 1.75) on Windows, X11 and Wayland. The
plant (a pick not filling the edit) failed 4 checks; reverted.

Not verified:
- Autocomplete-as-you-type (filling from the list while typing). It is not built: tiko-studio's
  find box needs history, not completion.
- An interactive pass.
