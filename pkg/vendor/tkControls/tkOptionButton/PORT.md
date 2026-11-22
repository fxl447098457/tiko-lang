# tkOptionButton: port notes (from vendor PsOptionButton)

**Name map:** `PsOptionButton_*` → `tkOptionButton_*`; `PSOPTIONBUTTON_*` → `TKOPTIONBUTTON_*`
(`_COLORS`, `_PAINTINFO`, `_MESSAGEINFO`, `_DEFAULT_*`, `_DOTRATIO_PCT`). `OPT_BOXALIGN_*`,
`OPT_TEXTALIGN_*`, `OPT_MOOD_*`, `OPT_PART_*` and the four `OPT_*Callback*` types are unchanged.
The handle is `TK_WIDGET ptr`; a group's parent is a `TK_WIDGET ptr` (`tkHost_Root( h )` for
top-level buttons).

**Kept verbatim:**
- LayoutOptionButton and its geometry (ideal size, rcContent / rcBox / rcCircle / rcDot / rcText
  span / rcVisual, the inscribed circle, the dot as 40 % of the circle or a declared size clamped
  to 2..side, the box pinned to its side's padding, the caption taking the leftover span,
  degenerate span when starved, no gap and a box-only height without a caption);
- ResolveMood / ResolveColors, the 21-field colour struct and its dark defaults, `ThemeColors`
  role for role (Dot* = SelectedText, DotColorDisabled = Window);
- THE GROUP: (parent, group id); a module registry in CREATION order (compacted on removal), so
  arrow order is creation order; `GetGroupID` / `SetGroupID` / `GetGroupCount` / `GetGroupMember` /
  `GetGroupChecked` / `FindChecked` / `FindCheckedID` (-1 = unanswered) / `ClearGroup`;
- mutual exclusion in one funnel (ApplyCheck): both writes land before any callback, then the
  loser is notified first, then the winner; nothing-checked is legal and unreachable by the user;
- silent `SetChecked` (works on a disabled member) / `SetGroupID` (an arriving checked button
  loses; the group left keeps nothing checked) / `ClearGroup`; `Click` is the notifying action
  (no-op when checked or disabled);
- ONE tab stop per group (see Changed for what a tab stop is here), re-synced at create, on every
  check move, on enable/disable, on regroup, on destroy (destroying the checked member leaves the
  group empty but hands the stop on);
- arrows Up/Left = previous, Down/Right = next, wrapping, stepping over disabled members, focus
  first then the check (a notifying user action); the message callback sees the key first and can
  veto it; Space checks; **Enter is not claimed**;
- press → slide off → release; capture lost cancels the press; the whole client is the hit area;
- the message callback's three ignored results (LBUTTONUP, SETFOCUS, KILLFOCUS);
- AutoSize (keeps the top-left), GetIdealSize before sizing; rect getters force the layout and
  return FALSE with no geometry yet or an empty rect (no caption → GetTextRect FALSE);
- `CountRenderedTones` / `HashRenderedPart` (now `SDL_RenderReadPixels`, focus forced on);
- tooltip text resolution: own text, then callback, then nothing (no caption fallback).

**Changed:**
- `Create( hParent as TK_WIDGET ptr, id, nGroupID = 0 )`.
- **WS_TABSTOP is `w->isFocusable`.** tkHost's Tab order walks focusable widgets, so exactly one
  member of a group is focusable. tkHost was not changed. **Added rule:** while keyboard focus is
  on a member of the group, *that* member holds the stop (it reverts on KILLFOCUS). tkHost's
  FocusNext restarts at the window's first stop when the focused widget is not in its list, so a
  focused non-holder (a slid-off or vetoed press, a programmatic SetFocus) would otherwise Tab to
  the top of the window instead of out of the group. Still exactly one stop per group; with focus
  outside the group the holder is vendor's (the checked member, else the first enabled).
- The circle is two `PaintEllipse` calls: unchecked = filled in the back colour and stroked with
  the ring pen (`nRingThick`, 0 = no ring, as vendor); checked = the accent disc, then the dot.
  Vendor stroked the unchecked ring with PaintRoundOutline (no fill); the fill is the mood's back
  colour, so it is invisible.
- **Pens are never scaled** (tk rule): `nRingThick` and `nFocusThick` are drawn as given. Vendor's
  PaintRoundOutline DPI-scaled them at paint time, so at 175 % a 1 px ring is 1 px here, 2 px there.
- `TKOPTIONBUTTON_MESSAGEINFO` carries `msg` (TKM_*), `x`, `y`, `key` instead of uMsg/wParam/lParam.
- Out-of-range `SetBoxAlign` / `SetTextAlign` are ignored, and negative padding / box gap clamp to
  0 (tkCheckBox's rules; vendor stored them as given).
- Arrow navigation also steps over a HIDDEN member (tkHost refuses focus to it).
- The tooltip is a tkTooltip owned through tkTipHost. `GetTooltipHandle` returns it (vendor's
  `GetPsTooltipHandle`); `SetHoverTime` / `SetAutoPopTime` / `SetReshowTime` → tkTipHost delays.
- Colours start from the current theme (`tkTheme_Get()`); `SetColors` pins, `ApplyTheme` skips
  pinned, `UnpinColors` re-applies, `TKM_THEMECHANGED` re-applies.
- `Rescale( oldDpi, newDpi )` → `TKM_SCALECHANGED` (every metric incl. a declared `nDotSize` ×
  fNew/fOld; a derived dot stays 0; pens not).
- Fonts are `TTF_Font ptr`, borrowed. `ApplyFonts( h, fText, fGlyph )` ignores fGlyph (no glyph
  font: the circle is geometry, as in vendor).
- "Is this handle ours?" is answered by `w->proc = @tkOptionButton_Proc` (vendor: a registry scan
  plus a signature), so group functions given a foreign widget answer 0 / FALSE.

**Dropped (Win32-only):**
- `WM_SETTEXT` / `WM_GETTEXT` / `WM_GETTEXTLENGTH` (no window text);
- `WM_GETDLGCODE` and the WM_CHAR swallow (the host owns Tab; SDL never beeps);
- the 100 ms hover poll, `IDT_PSOPTIONBUTTON_HOTTRACK` / `PSOPTIONBUTTON_HOTTRACK_MS` (the host
  guarantees the leave);
- `SetTooltipMode` / `GetTooltipMode` and the comctl32 handle;
- `PSOPTIONBUTTON_SIGNATURE`, `GWLP_ID`, `WS_EX_CONTROLPARENT` notes;
- `PsOptionButton_RunSelfTest` (replaced by `examples/tkControls/tkOptionButton/selftest.tiko`);
- PsRegistry.

**Added:**
- probes `tkOptionButton_GetTabStop` (does this member carry its group's stop), `GetHot`,
  `GetPressed` (the live gesture), `GetTextSize`.
- `tkOptionButton_PaintDefault( p )`: the stock drawing, for a paint callback (the form designer's
  Paint event).

**Vendor bugs found (fixed here):**
- **Sliding off did not un-flash** (same as PsCheckBox). The README says `PAINTINFO.isPressed` is
  "a live left press AND the cursor is still inside" and that the press "visibly cancels before
  the release"; the code painted and reported the raw gesture flag, and ResolveMood ranks pressed
  above hot, so a slid-off press kept the pressed colours. tk paints `isPressed andalso isHot`.
  Asserted: `slid off: un-flashed to RingColor`.
- **A disabled checked member kept the group's tab stop.** The README says disabling the holder
  "hands it to another enabled member", but SyncTabStop picked the checked member without testing
  `isEnabled`, and the dialog manager skips disabled windows -- so disabling the checked option
  took the whole group out of the Tab order. tk skips a disabled checked member (then first
  enabled, then first). Asserted: `disabling the checked holder hands the tab stop to an enabled
  member` (it failed against the vendor rule on the first run).

**A/B plant:** removed `if pTo->isEnabled = false then continue for` from NavigateGroup (arrows no
longer step over disabled members). Failed 10 checks, 5 per scale pass: `Down steps OVER a
disabled member`, `Up steps over it too`, and three downstream (`every other member disabled:
arrows stay put`, `message callback vetoes Down`, `...but not Up`, because focus was left on the
wrong member). Restored by inverse replace; 302 / 0.
