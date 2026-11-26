# tkPaint: port notes (from vendor PsBufferPaint)

**Name map:** `PsPaintBuffer` → `TK_PAINT`; `PS_PENDASH_*` → `TK_PENDASH_*`; `PS_IMGFIT_*` →
`TK_IMGFIT_*`; `DT_*` → `TK_DT_*`; `LinearGradientMode*` → `TK_GRADIENT_*`. COLORREF → `ulong`
`&hAARRGGBB`; `RECT` / `POINT` → `TKRECT` / `TKPOINT`.

**Kept:**
- every method controls and PsChart use, with vendor's parameters and conventions:
  curvature as diameter, inset strokes, a pie pen centred on the rim, DPI-scaled pens for
  pie / ring / polyline / curve, dash patterns in pen-width units;
- AA, done with geometry fringes on `SDL_RenderGeometry`.

**Changed:**
- No double buffer: the host paints a frame and presents it.
- `Begin( x, y, w, h, parentClip )` replaces BeginDoubleBuffer.
- Fonts are `TTF_Font ptr`.
- `PaintText` honours TOP / BOTTOM besides the default VCENTER; `PaintTextEx` wraps.

**Added:** `PushClip` / `PopClip`, and the UTF-8 text helpers (`tkText_*`). Recording for tkPrint
(2026-11-23): `TK_PAINT.pfnRec` / `pRecCtx`, `TK_RECOP`, `TKREC_*`, `PlayOp`; every shape method
draws through one of five record-aware helpers (`FillPolyP`, `StrokeClosedP`, `StrokeOpenP`,
`FillRectP`, `GradRectP`), text through `DrawU8`, images through `PaintImage`, clips through `ApplyClip`.

**Dropped:** `SetupBitmap`, `getMemDC`, `rcClient*`, `PaintClientRect` (a widget fills its own
rect), `PaintIconButton` (no caller in the family), `SetSmoothingMode` (always AA).

## Text caching: measured and REJECTED (2026-10-25, for tiko-studio)

The assumption was that `DrawU8` (a new `TTF_Text` per call) plus `tkText_WidthU8` (`TTF_GetStringSize`,
which shapes again) made text the cost of a frame. tkCodeEdit's run cache had paid off. The same
cache here (shaped runs keyed engine+font+colour+bytes, widths keyed font+bytes, each flushed whole
at 8,192) was measured with `examples/tkControls/tkPaint/bench`: 400 labels a frame, rendered without presenting.

| ms / frame | steady (same labels) | scrolling (all new) |
| --- | --- | --- |
| Windows D3D11, no cache | 2.55–2.64 | 1.97–2.33 |
| Windows D3D11, cache | 3.2 | 78 |
| WSLg GL (Wayland), no cache | 3.96 | 3.28 |
| WSLg GL (Wayland), cache | 4.9 | 99.6 |

Short UI labels are cheap to shape. The lookup (a key built and hashed per label) costs more than
it saves, and churn through the cap is ruinous. tkCodeEdit keeps its own cache: Scintilla's runs
are longer and repeat across a whole view. **No cache in tkPaint.** 400 labels at 2.5–4 ms a
frame is within budget. The same numbers answer the "host dirty / texture cache" question: a
whole-window repaint of an IDE-sized frame is not the bottleneck, so that is not built either.
`bench.exe` stays as the instrument for the next time.
