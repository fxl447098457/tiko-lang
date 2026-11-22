# tkProgressBar: port notes (from vendor PsProgressBar)

**Name map:**
- `PsProgressBar_*` → `tkProgressBar_*`.
- `PSPROGRESSBAR_*` → `TKPROGRESSBAR_*` (types and the `_DEFAULT_*` / `_CURVATURE_STADIUM`
  constants).
- `PRG_*` enums and the four callback types are unchanged.
- `IDT_CPROGRESSBAR_MARQUEE` → the reserved `TK_TIMER_MARQUEE`.
- GDI+ `LinearGradientMode*` → `TK_GRADIENT_*`, which has the same four values.
- The handle is `TK_WIDGET ptr`; `HFONT` → `TTF_Font ptr`; `COLORREF` → `&hAARRGGBB`.

**Kept verbatim:**
- LayoutProgressBar: the three derived rects, centring, inset collapse, the four
  orientation × reverse projections, and the clip of a WRAP chunk to the fill.
- The three pure functions: `ComputeBarLength`, `ComputeMarqueeOffset` and
  `ComputeBlockCount`.
- Block tiling from the bar's own growth-start edge, so blocks travel with a floating chunk.
- Colour precedence: disabled > error > paused > normal. A solid fill uses the first stop only.
- The four text modes, and the caption drawn twice into the same rect: on-bar colour clipped to
  the bar, track colour clipped to track minus bar. A disabled bar draws it once.
- Every clamping and normalisation rule:
  - `SetRange` swaps an inverted pair and pulls the position into the range;
  - `SetPos` repaints only when the value changes;
  - `StepIt` clamps and does not wrap;
  - chunk percent is clamped to 1..100;
  - marquee speed values ≤ 0 are ignored;
  - negative curvature becomes the stadium sentinel;
  - unknown modes, styles and states fall back to the defaults.
- The marquee:
  - it is the only timer the control runs, and only in indeterminate mode;
  - it runs only while enabled AND not hidden;
  - `SetMode` and `SetMarqueeStyle` reset the tick; re-enabling or re-showing resumes without
    a reset;
  - "assume shown" at create, so it runs before the window is shown.
- Silence: there is no change callback at all.
- The message callback is offered every message except `TKM_DESTROY`, and every answer is
  honoured, `TKM_PAINT` included.
- `CountRenderedTones` / `HashRenderedPart`: FNV-1a over RGB, with vendor's byte order and part
  rects, driven through the same render path as `TKM_PAINT`.
- `ThemeColors` keeps vendor's role mapping, including flat themed gradients.

**Changed:**
- `Create( hParent as TK_WIDGET ptr, id, nOrientation )`; a top-level bar's parent is
  `tkHost_Root( h )`.
- The marquee timer is `tkWidget_SetTimer( w, TK_TIMER_MARQUEE )`. Hidden comes from
  `TKM_SHOW`, disabled from `TKM_ENABLE` (WM_SHOWWINDOW / WM_ENABLE).
- `SetEnabled` goes through `tkWidget_Enable`, the EnableWindow equivalent. A direct
  `tkWidget_Enable` also stops and restarts the marquee.
- `TKPROGRESSBAR_MESSAGEINFO` carries `msg, x, y, key, timerId, bFlag`, which replace
  `uMsg/wParam/lParam`.
- Gradients go through `TK_PAINT.PaintGradientRect`:
  - it takes no separate brush rect, so a segmented gradient block is painted from the
    single ramp's colours at its own two ends (`RampAt`);
  - this is exact for HORIZONTAL and VERTICAL; on the two diagonals each block's corners
    match the ramp, but its interior follows its own diagonal.
- Curvature is clamped to the painted rect's shorter side before it reaches tkPaint, which
  clamps x and y separately. That restores GDI+'s circular corners and vendor's capsule blocks.
- `SetFont(0)` falls back to the host's default font (vendor: the DC's font).
- Probes render into the host's back buffer at the widget's place, not a private DIB.
- The tooltip is a tkTooltip owned through tkTipHost:
  - `GetTooltipHandle` returns it (vendor's `GetPsTooltipHandle`);
  - `SetHoverTime` / `SetAutoPopTime` / `SetReshowTime` → `tkTipHost_SetDelay`;
  - text precedence is unchanged: own text, then the callback, then nothing;
  - a disabled bar pops its tip.

**Dropped (Win32-only):**
- WM_ERASEBKGND;
- WM_NOTIFY / TTN_GETDISPINFOW and the instance tip buffer;
- the comctl32 backend: `SetTooltipMode` / `GetTooltipMode` and the system `GetTooltipHandle`;
- PsRegistry;
- `Rescale(oldDpi, newDpi)` → `TKM_SCALECHANGED` (fNew/fOld scales thickness, inset, block
  length/gap and marquee step; border thickness, curvature and interval are not scaled);
- `RunSelfTest` (it lives in `examples/tkControls/tkProgressBar/selftest.tiko`);
- the "one-pixel seam at curvature 0", a GDI RoundRect artefact that tkPaint does not have.

**Added:**
- `tkProgressBar_GetMarqueeTick` (test probe; vendor's self-test read `nTick` directly);
- `tkProgressBar_GetID`;
- `tkProgressBar_PaintDefault( p )`: the stock bar, for a paint callback (the form designer's
  Paint event).

**Vendor bugs found (fixed here):**
- `PsProgressBar_GetBlockRect` returned FALSE for an index past the last block but left `rc`
  holding that off-bar rect: `PRG_BlockRectAt` had already overwritten the zeroed out-parameter.
  tk empties `rc` on every FALSE.
- The declaration comment on `ComputeMarqueeOffset` says the result is "always within
  [0, track - chunk], for both styles". WRAP deliberately returns [-chunk, track), as the
  definition and the README say. Doc-only.
