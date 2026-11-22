# tkSpinner -- not a port

PsControls has no busy indicator. tkSpinner is new to tkControls: the small animation a program shows
while something takes its time (loading, saving, waiting on the network).

**Modelled on:** tkProgressBar's indeterminate marquee -- ONE widget timer (`TK_TIMER_MARQUEE`) whose
ticks are the only clock, running only while the spinner is started, enabled and shown (`TKM_SHOW`,
`TKM_ENABLE`); a colour struct the theme fills unless pinned (`SetColors` / `UnpinColors`, recipes
through `tkTheme_ResolveInto`, type name "Spinner"); a paint callback with a paint info and a
`PaintDefault` for the stock frame; a message callback offered every message but `TKM_DESTROY`; the
two offscreen probes (`CountRenderedTones`, `HashRenderedPart`).

**Drawing:** tkPaint's anti-aliased shapes, in the largest square centred in the client, from the
client's size at every paint: `PaintPieRing` (RING, ARC; round ends as discs), `PaintEllipse` (DOTS,
PULSE, BOUNCE), `PaintLine` (SPOKES: one strip per bar, so a translucent colour is even along it).

**Rules:** each tick moves the phase on by FrameMs / Period of a cycle (wrapping at 1). Stop keeps
the phase; HideWhenStopped draws nothing while stopped. A disabled spinner draws in
ForeColorDisabled and doesn't tick. Display-only: never a tab stop, no capture, no hot state.
Setters are silent.
