# tkChart (vendor PsChart): port notes

**Name map:** `PsChart_*` → `tkChart_*`; `PSCHART_*` constants → `TKCHART_*`
(`PSCHART_TYPE_LINE` → `TKCHART_TYPE_LINE`, `PSCHART_COLORS` → `TKCHART_COLORS`, …). The
prefix-free names stay: `CHT_SYM_*`, `CHT_COL_*`, `CHT_LINE_*`, `CHT_LEGEND_*`, `CHT_PIELABEL_*`,
`CHT_PIEPLACE_*`, `CHT_FMT_*`, `CHT_NiceRange`, `CHT_AutoDecimals`, `CHT_FormatNumber`, the
`CHT_*Callback*` types. `HWND` → `TK_WIDGET ptr`, `HFONT` → `TTF_Font ptr`, `COLORREF` → tkRGB's
`ulong` (the vendor's dark defaults, value for value), `RECT` / `POINT` → `TKRECT` / `TKPOINT`.

**The shape.** One leaf widget, like tkButton. `tkChart_Create( hParent, id, nChartType )`; the
type is fixed at create. It is a display control: not focusable, no keys, no capture. The hot
point under the cursor is the only thing that notifies.

**Kept, unchanged:** `ResolveRange` (a column chart forces zero, line and HLOC do not, HLOC reads
low / high, stacked scales to separate positive and negative totals, pie is 0..1, a manual range
turns autoscale off); `CHT_NiceRange` (1/2/5 × 10ⁿ, a flat series opens ±10 % or ±1);
`CHT_AutoDecimals`; `CHT_FormatNumber` (int then cast, "," grouping, no minus on a rounded zero);
`LayoutChart`, in the same order (padding, title, subtitle, legend, then the pie's square inset for
explode and outside labels, or the value gutter, the category strip, the clamped origin, the slot
width and the auto label stride from the widest label); `LayoutPoints` (grouped bar width with a
1 px floor, the HLOC hit band a slot wide, a line hit box of ± the hit radius, empty rects for a
hidden series); `LayoutStackedColumns` (category-outer, accumulated in value space);
`LayoutPieSlices` (sweeps from −90° clockwise, the exploded centre, the chord-fits test at 0.65 r,
outside labels at r + 2 gaps, anchored left or right); the hit test, which reads the same rects
the renderer draws (later series first; pie by distance and angle from the slice's own centre;
the doughnut hole is a hole); tooltip resolution (authored text, then the callback, then the hot
point described, HLOC as O H L C, pie with its percent); the render order (background, plot
background only when it differs, grid, the axis rule and the zero rule, then clipped bands,
fills, lines, markers; wedges, leaders, labels; axis labels; legend; title and subtitle); the
palette; the colours and the theme map, with pinning; BeginUpdate / EndUpdate nesting; silent
setters; every recycled series or point slot reset in full; the probes (`CountRenderedTones`,
`HashRenderedPart`, `GetRenderedPixel`, `CountPlotInkPixels`).

**Changed:**
- **Bands and area fills are filled as runs.** Vendor handed GDI+ one polygon: forward along the
  high edge, back along the low one. tkPaint ear-clips, which needs a simple polygon. A band with
  zero width over part of its length (the demo's forecast band, whose edges coincide through the
  record) was clipped into a triangle across it. `CHT_FillBetween` cuts the region where the edges
  touch or cross, over their common prefix; a tail past it rides on the last run, as vendor's
  polygon did. The union is what GDI+'s alternate fill drew. An area fill is the same call with
  the baseline as its low edge, so a line crossing the origin fills on both sides.
- Tooltips go through tkTipHost. The tool index is `iSeries * 65536 + iPoint`, so moving to
  another point takes the tip down and re-resolves it (vendor's per-point `TTN_GETDISPINFO`).
- Rescale is `TKM_SCALECHANGED`: padding, chrome gap, tick length, bar gap, HLOC tick, hit radius,
  symbol sizes and explode offsets are multiplied by new / old. Axis and grid thickness and the
  pie slice gap are hairlines, as vendor's were, and are never scaled. Line widths are raw: tkPaint
  scales a polyline pen itself, as GDI+ did.
- The message callback gets `TKCHART_MESSAGEINFO` (the `TKM_*` message, mouse position, key, mods,
  clicks, and the hot point). A TRUE eats the message, except `TKM_LBUTTONUP`, whose result is
  ignored.
- Probes render into the host's back buffer at the widget's place and read it back before any
  present.

**Added:** `GetBandCount`, `GetUpdateDepth`, `GetValueStep`, `GetFont`, `GetSliceInfo` (start,
sweep, label out / dropped), `GetPointAnchor`, the rect queries `GetLegendRect`, `GetTitleRect`,
`GetSubtitleRect`, `GetAxisYRect`, `GetAxisXRect`, `GetPieRect`, `GetTooltipHandle`,
`SetHoverTime`; `PaintDefault( p )`, the built-in chart over the filled background, for a paint
callback (the form designer's Paint event).

**Dropped (Win32-only):** the hot-poll timer and `TrackMouseEvent` (the host guarantees the leave),
`WM_SETFONT` / `WM_GETFONT`, `WM_GETDLGCODE`, `TTN_GETDISPINFOW` and the comctl32 tooltip backend,
PsRegistry, `PsChart_Rescale` (now `TKM_SCALECHANGED`), `PsChart_RunSelfTest` (now
`examples/tkControls/tkChart`).

**Vendor bugs found:** none.

**Selftest:** 317 assertions: 11 pure, then 153 at each of 1.0 and 1.75. They cover NiceRange,
AutoDecimals and FormatNumber; the plot rect, value gutter and category strip against the
formulas; ValueToY / YToValue; anchors at the slot centres; hit boxes and HitTest on line, bar,
HLOC band, pie, doughnut and exploded slice; the hot point through pushed motion (one
notification, state already updated, cleared on leave and on disable, eaten by the message
callback); tooltip resolution order and the real popup; value-label callback and fixed decimals
widening the gutter; hidden series leaving the range, the rects and the hit test; manual range and
tick hint; pixels for bands (including a zero-width stretch drawing nothing), area fill, symbols,
point / series / palette colours, HLOC up / down, the zero rule, leaders only for outside labels;
ink for dash, dot, width, smoothing and grid; title, subtitle and legend layout on all four edges;
the paint callback; theme and pinning; rescale; label stride; grouped, negative and stacked
columns; slice sweeps, label placement in AUTO / INSIDE / OUTSIDE / NONE; Clear and recycled
slots. A/B: dropping the column chart's forced zero fails the range check and the two bar-pixel
checks at both scales (311/317).
