# tkVScrollBar / tkHScrollBar (engine: tkScrollBar): port notes

**Name map:** `PsVScrollBar_*` → `tkVScrollBar_*`, `PsHScrollBar_*` → `tkHScrollBar_*`;
`CVSCROLL_*` → `TKVSCROLL_*`, `CHSCROLL_*` → `TKHSCROLL_*`. The callback type names
(`VScrollCallbackSub` ...) are unchanged.

**Kept:**
- no arrow buttons;
- track paging, then auto-repeat (400 / 80 ms) until the thumb reaches the cursor;
- the minimum thumb (20, scaled);
- whole-unit positions clamped to `[0, total - page]`; silent SetPos;
- wheel accumulation in 120ths;
- each bar takes only its own wheel axis (the other bubbles), with vendor's sign trap kept
  (positive moves V up, H right);
- the V divider;
- theme, pinning, paint callback.

**Changed:**
- One engine, with V and H as thin modules (PsPlatform's PsScrollBar idea).
- The system lines-per-notch has no SDL query, so it is 3 (Windows' default).
- `IsDragging` and `GetThumbRect` exist on both bars (vendor had IsDragging on H only).
- The paint info names its bar (`hScrollBar`), and `PaintDefault( p )` (on both bars) draws the
  stock bar from inside a paint callback (the form designer's Paint event).

**Dropped:** the hover poll timer; `WM_SHOWWINDOW` → `TKM_SHOW`; PsRegistry; `Rescale` →
`TKM_SCALECHANGED`.

**VENDOR BUG FOUND (both bars, not yet verified on Win32):** WM_LBUTTONUP calls ReleaseCapture
only `if isDragging orelse repeatTimerOn`. When the auto-repeat has already stopped because the
thumb reached the cursor, the button comes up and the bar KEEPS the capture. tk releases
whenever it holds capture; this port's selftest is what found it.
