# tkToggle: port notes (from vendor PsToggle)

**Name map:** `PsToggle_*` → `tkToggle_*`; `PSTOGGLE_*` → `TKTOGGLE_*` (`PSTOGGLE_COLORS`,
`_PAINTINFO`, `_MESSAGEINFO`, `_DEFAULT_*`). `TOG_JUSTIFY_*` and the three `TOG_*Callback*`
types are unchanged. The handle is `TK_WIDGET ptr`.

**Kept verbatim:**
- LayoutToggle and its formulas (CENTER from the track, overflow degrades to LEFT, a short client
  clips rather than squeezes, knob diameter from the height and floored at 1);
- the twenty-field colour struct, its dark defaults and its precedence (disabled > hot/pressed >
  idle, per ON/OFF group; no pressed colours);
- the three callbacks and their contracts: LBUTTONUP and SETFOCUS/KILLFOCUS results ignored,
  LBUTTONDOWN and Space/Enter suppressible, focus taken before the callback sees the press;
- press → slide off → release, re-arm on slide back, snapshot before releasing capture;
- Space and Enter (and keypad Enter) on the click's path; silent `SetChecked`;
- double clicks are ordinary clicks (`m->clicks` is never read);
- the right button reported, never acted on; arrows not claimed;
- every setter clamp; `GetIdealSize` from the scalars, valid before sizing; rect queries FALSE
  until sized; `ThemeColors` role for role.

**Changed:**
- `Create( hParent as TK_WIDGET ptr, id )`; a top-level parent is `tkHost_Root( h )`.
- `SetEnabled` → `tkWidget_Enable` (input stops, Tab skips it, capture/focus/hot dropped at once).
- `Rescale(oldDpi, newDpi)` → `TKM_SCALECHANGED` (track size, inset and focus gap × fNew/fOld;
  the two thicknesses never).
- `UnpinColors` re-applies `tkTheme_Get()` (vendor needed PsRegistry to hold a theme).
- Colours start from the current theme (`tkTheme_Get()`); the struct keeps vendor's defaults.
- `TKTOGGLE_MESSAGEINFO` carries `msg, x, y, key` instead of `uMsg, wParam, lParam`. A key the
  control does not claim is reported but its result is ignored: under Win32 the dialog manager
  took Tab before the control saw it, so no callback could eat it.
- `TKM_SHOW` (hidden) clears hot and the press, as `TKM_ENABLE` does.

**Dropped (Win32-only):**
- `WM_GETDLGCODE` (the host owns Tab) and the WM_CHAR swallow with its `bAteKeyDown` flag (SDL
  never beeps);
- the 100 ms hover poll `IDT_CTOGGLE_HOTTRACK` (the host guarantees the leave);
- `WM_ERASEBKGND`, `CS_DBLCLKS`, the `WS_EX_CONTROLPARENT` note (no dialog manager);
- PsRegistry.
- `PsToggle_RenderDefault` and `GetTogglePointer` were public in the .tiko but not in the README
  (they take the internal state struct); private here.

**Not added, by vendor's design:** no caption, no font (`SetFont`/`ApplyFonts` would have nothing
to measure), no tooltip, no animation, no tri-state. PsPlatform's Left/Right = off/on was not
taken: vendor's README rules arrows out.

**Added:** `tkToggle_GetHot`, `tkToggle_GetPressed`, `tkToggle_GetID` (test probes). For the form
designer: a tooltip through tkTipHost (`SetTooltipText` / `GetTooltipText`, `GetTooltipHandle`, the
three delays), the border following the theme's BorderWidth until `SetBorderThickness` (which now
pins it), and `PaintDefault` for a paint callback. PsToggle has none of them.

**Vendor bugs found (fixed here):**
- **A held Space/Enter re-flipped the switch at the typematic rate** — `WM_KEYDOWN` auto-repeat
  went down the click's path. Repeats are claimed and ignored (`m->bFlag`); selftest
  "held Space: auto-repeat does not re-flip".

**Host gap guarded locally:** a press that arrives with no motion before it (the pointer never
made the widget the host's hot one) left `isHot` set after the release, and no leave ever came to
clear it — the switch stayed painted hot. After a release, hot now also requires
`h->pHot = w`. tkButton has the same code and the same gap; the root fix belongs in tkHost (make
the pressed widget hot on a button-down). Selftest "motionless click leaves no stale hot".
