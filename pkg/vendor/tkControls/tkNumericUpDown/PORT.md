# tkNumericUpDown: port notes (from vendor PsNumericUpDown)

**Name map:** `PsNumericUpDown_*` → `tkNumericUpDown_*`; `PSNUMERICUPDOWN_*` →
`TKNUMERICUPDOWN_*`; `CNUD_DEFAULT_*` → `TKNUD_DEFAULT_*`. `NUD_PART_*` and the `NUD_*Callback*`
types are unchanged. The handle is the widget.

**Kept:**
- the nine-rect layout: the cells span the full height and are not deflated by the border; only
  rcValue is inset (border + vpad); both "+" bars share one centre; an over-narrow control
  collapses rcValue (never inverted) and hides the field;
- the paint order (client, rounded base fill, cells extended past the divider, dividers and
  glyphs as rects, outline last) and the precedences (disabled-or-at-limit > pressed > hot >
  idle; outline disabled > focused > idle);
- the decimal grid (snap half away from zero), the clamp that never wraps, the quarter-grid
  "differs" test, the committed value vs the field's text;
- the step on the button DOWN; capture for the repeat; repeat after the delay then the interval,
  paused off the button and resumed after the full delay, stopped dead at a limit; either
  timing ≤ 0 disables it; a double click is two presses;
- notify at once for buttons, repeat, arrows, PgUp/PgDn and the wheel (one increment a notch,
  sub-notches accumulate); notify on COMMIT (Enter, focus loss) for typing; every setter silent;
- the ideal size measured from both range ends; the defaults and which are scaled (the glyph
  stroke yes, the two hairlines no);
- read-only blocks typing only; disabled stops everything;
- the relayed message stream (the field's key/char/mouse/wheel/focus messages with `hCtrl`
  rewritten); the host's answer is ignored for LBUTTONUP and KILLFOCUS;
- the colour struct (18 fields), `ThemeColors` roles, pinning, `ApplyFonts` (no glyph font).

**Changed:**
- The field is a `tkTextBox` CHILD WIDGET (vendor: PsTextBox → RichEdit, two windows down). Its
  focus, enter and message callbacks belong to this control, as do `SetValue`,
  `SetDecimalPlaces` and `SetBorderWidth`.
- Disabling the container disables the field through the widget tree (`tkWidget_IsEnabled`),
  so one `tkWidget_Enable` is enough.
- `HitTest( h, x, y )` takes widget pixels (vendor: a client POINT).
- `TKNUMERICUPDOWN_MESSAGEINFO` carries `msg` (TKM_*), `x`, `y`, `key`, `mods`, `wheelY`
  instead of uMsg/wParam/lParam.

**Added:** `GetID`, `GetHotPart`, `GetPressedPart`, `IsRepeating` (state for tests and custom
painters). For the form designer: a tooltip (`SetTooltipText` / `GetTooltipText`, `GetTooltipHandle`,
`SetHoverTime` / `SetAutoPopTime` / `SetReshowTime`, through tkTipHost as tkButton's), the border
following the theme's BorderWidth until `SetBorderThickness` (which now pins the shape), and
`PaintDefault` (the stock drawing, for a paint callback). PsNumericUpDown has none of them.

**Fixed while porting (vendor bug):** a button cell's fill, extended past the divider so only its
outer rounding survives, also paints into the value cell's vpad strips above and below the field
whenever its colour differs from the value colour (a hot or pressed button) — vendor added the
vpad inset to rcValue after the extension was designed. The fill is now clipped to its own cell
(selftest: "hot fill clipped to its cell").

**Dropped (Win32-only):** `FilterMessage`, `WS_EX_CONTROLPARENT`, `CS_DBLCLKS`, the 100 ms
hover poll and its timer id (the host guarantees the leave), PsRegistry,
`Rescale(oldDpi, newDpi)` (`TKM_SCALECHANGED` scales every stored metric; the field rescales its
own margins).
