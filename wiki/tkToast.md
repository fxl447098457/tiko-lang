[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkToast**

# tkToast

Shows toasts: short-lived notification cards stacked in a corner of a window, queued, timed, with
up to two actions.

`tkToast` is the [tkControls](Category-tkControls) toast system, in the manner of Fluent's Toaster,
GNOME's AdwToastOverlay or Sonner. A window has **one toaster**, made the first time it is used.
Every `tkToast_*` call takes **any widget of that window** and finds it. Cards float over the
content: a click outside them reaches what is beneath, and showing one never moves the keyboard
focus. The look — severities, colours, glyphs, buttons — is [tkInfoBar](tkInfoBar)'s; use an info
bar for a message that should stay in the layout until it is dealt with.

Toasts time out on their own, and the timer **holds** while the user is engaged with them.
Programmatic dismissals are silent. The close button, an action, a swipe, a key and a toast's own
timeout notify.

## Importing

```freebasic
#import "vendor/tkControls/tkToast"

using tkToast
using tkNotify
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme), and **tkNotify** — the part it shares with [tkInfoBar](tkInfoBar),
which holds the severities, the close reasons and the colour struct. Add `using tkPaint` for
`TKRECT`.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example;
`root_ = tkHost_Root( host )`.

```freebasic
sub Deleted_Action( byval hToaster as TK_WIDGET ptr, byval id as long, byval nAction as long, byval pCtx as any ptr )
    if nAction = 1 then print "undo"                    ' the toast's own handler
end sub

' One line: a message at a severity (info, timed by the toaster's rule).
tkToast_ShowText( root_, "Saved" )

' A toast with an action: it stays until the user acts or closes it.
dim as TK_TOAST t
t.severity = TKN_WARNING
t.title = "3 files deleted"
t.message = "They are in the recycle bin."
t.action1 = "Undo"
t.OnAction = @Deleted_Action
tkToast_Show( root_, t )

' Loading, then its result, on the same card.
dim as long id = tkToast_Begin( root_, "Exporting 12,408 rows..." )
' ... later, on the UI thread (tkApp_RunOnUI from a worker) ...
tkToast_SetProgress( root_, id, 60 )
tkToast_Finish( root_, id, TKN_SUCCESS, "Exported to orders.csv" )
```

## Posting

- `tkToast_ShowText( hWnd, msg, severity = TKN_INFO )` posts a message.
- `tkToast_Show( hWnd, t )` posts a `TK_TOAST`. Both return the toast's id (> 0).
- **`TK_TOAST`'s fields:**
  - `severity` (the `TKN_*` four), `title`, `message`, `glyph` ("" = the severity's);
  - `action1`, `action2` (captions; "" = none);
  - `duration` (ms; -1 = the toaster's rule, 0 = never times out);
  - `priority` (`TST_PRIO_NORMAL` / `TST_PRIO_HIGH`), `bClosable` (default true), `bKeepOnAction`;
  - `progress`, `key`;
  - `OnAction`, `OnDismissed` and `pCtx` (this toast's own handlers);
  - `itemData`, kept in the history;
  - `bAlert`, stored for a future accessibility bridge and read by nothing today.
- **Update in place.** A `key` makes a toast updatable: posting again with the same key while it is
  live updates it (the same id, its time re-armed). `tkToast_Update( hWnd, id, t )` replaces a live
  toast's content, and `tkToast_SetMessage` its message, both silently.
- **Repeats.** The same severity, title and message posted again with no key, while one like it
  shows, counts up on that card ("×2") and re-arms it. `SetCoalesceRepeats( false )` turns this off.
- **Thread.** `Show` (and `ShowText`, `Begin`) refuse, returning 0, off the main thread. Post from a
  worker through `tkApp_RunOnUI`.

## Loading → result

- `tkToast_Begin( hWnd, msg, key = "" )` posts a toast that never times out and has no close
  button, with a moving progress strip.
- `tkToast_SetProgress( hWnd, id, n )` makes the strip 0..100 (clamped), or
  `TKN_PROGRESS_INDETERMINATE` / `TKN_PROGRESS_NONE`.
- `tkToast_Finish( hWnd, id, severity, msg, duration = -1 )` turns the loading toast into its
  result: closable, no strip, and timed by the rule. If the user closed it meanwhile, the result is
  posted as a new toast and its id returned, so a result is never lost.

## The queue

- At most **MaxVisible** toasts show (default 3). The rest wait, the highest priority first, then
  the oldest. Nothing is dropped.
- A **HIGH**-priority toast with every slot full takes the slot of the oldest NORMAL one. That one
  goes back to the head of the queue, keeping its remaining time, with no callback.
- `IsLive` (shown or waiting), `IsShown`, `FindKey`, `GetVisibleCount`, `GetQueuedCount`,
  `GetRemaining` (ms; -1 never times out, -2 waiting or gone) and `GetRepeat`.

## Timing

- **The rule** (`duration = -1`):
  - info and success last 5000 ms, warning and error 8000 ms (`SetDurations( normal, alert )`);
  - a toast with an action never times out;
  - `duration = 0` never times out, and any other value is that many ms.
- **The timer holds** — the remaining time is frozen — while any of these is true:
  - the pointer is over any card (`SetPauseOnHover`, default on);
  - a card is pressed;
  - a card has the keyboard focus;
  - the window does not have input focus (`SetPauseOnWindowBlur`, default on);
  - the app is in the background (`SDL_EVENT_DID_ENTER_BACKGROUND` until `WILL_ENTER_FOREGROUND`).

  When a hold ends, a toast with less than `TKTOAST_HOLD_MIN_MS` (1 s) left gets 1 s. `IsHeld`
  answers whether time is held.
- **Accessibility (WCAG 2.2.1):**
  - `SetTimeScale( f )` multiplies every duration armed from then on, the rule's and explicit ones;
    10 meets "extend at least 10×".
  - `SetTimeouts( false )` makes every toast never time out, those showing included.
- **The clock** is one timer on the toaster: a one-shot at the nearest deadline, 15 ms while a card
  moves, 30 ms while an indeterminate strip shows, and none at all when nothing counts down.
  `TickForTest( hWnd, ms )` pins it, for self-tests.

## Placement

- Cards stack from a corner: `SetPosition` takes one of `TST_POS_TOP_LEFT`, `_TOP_CENTER`,
  `_TOP_RIGHT`, `_BOTTOM_LEFT`, `_BOTTOM_CENTER`, `_BOTTOM_RIGHT` (the default).
- **Spacing:** a card is `SetWidth` wide (default 360 design units), `SetMargins` from the window's
  edges (16), and `SetGap` from the next card (8).
- **Insets:** `SetInsets( l, t, r, b )` keeps the cards clear of a toolbar or status bar.
- **Order:** `SetNewestNearEdge` (default true) puts the newest card in the corner.
- **Narrow windows:** narrower than `SetNarrowWidth` (600), cards stack full width from the bottom
  centre.
- **Following the window:** the cards follow a resize, a live drag on Windows included (tkHost's
  size hook).
- `tkToast_ComputeLayout( st, rcRoot, fScale, heights(), n, rects() )` is the placement rule as a
  pure procedure (index 0 = the newest), with `tkToast_ComputeArea` and `tkToast_CardWidth`.
- `GetCardRect( hWnd, id, rc )` answers where a shown card belongs, in root pixels, without its
  shadow. `GetPartRect( hWnd, id, part, rc )` answers a part in card pixels. `GetCard` returns the
  card's widget.

## Motion, swipe and keyboard

- **Motion** (`SetAnimate`, default on):
  - **enter:** a card fades in and slides 24 units from its stack's edge (`TKTOAST_ENTER_MS`,
    180 ms);
  - **leave:** it fades and slides back (150 ms), or flies on in a swipe's direction;
  - **move:** the others travel to their new places (150 ms).

  A resize or a settings change places cards at once. `IsAnimating`, `GetCardOpacity`.
- **Swipe.** A card dragged sideways follows the pointer and fades. It moves only away from its
  stack's side (a centred stack either way). Released past `TKTOAST_SWIPE` (45 units), or flicked at
  `TKTOAST_SWIPE_SPEED` (0.5 units/ms) or faster, it is dismissed (`TKN_CLOSE_SWIPE`); otherwise it
  springs back. A drag that starts on a button cancels the button. A finger is the mouse on Android.
- **Keyboard.** Cards never take focus on their own. `tkToast_FocusToasts( hWnd )` remembers the
  focused widget and focuses the newest card. Bind it to a chord of your choosing (tkKeys): there is
  no default. On a focused card:
  - **Tab / Shift+Tab** walk its parts (enabled actions, then close), then the next or previous
    card down or up the screen; past the last, focus goes back.
  - **Up / Down** move between cards.
  - **Enter / Space** press the part.
  - **Esc** or **Delete** dismiss the card (`TKN_CLOSE_KEY`, if it is closable).
  - **Shift+Esc** dismisses every closable toast, each one told.

  When the focused card goes, the newest card takes focus, or the saved widget once none is left.
  `IsKeyMode`, `GetFocusPart`.

## Notifications

Each toast may carry its own `OnAction` / `OnDismissed` and a `pCtx`, so the code that posts it
handles it. Toasts without them go to the toaster's callbacks. Every callback receives the toaster's
handle (`tkToast_GetToaster`), which any `tkToast_*` call accepts.

| Callback | When |
| --- | --- |
| `OnAction` / `SetActionCallback` | an action is pressed: `( hToaster, id, nAction, pCtx )`, `nAction` 1 or 2; then the toast is dismissed (`TKN_CLOSE_ACTION`) unless `bKeepOnAction` |
| `OnDismissed` / `SetDismissedCallback` | the user or the timeout dismissed it: `( hToaster, id, reason, pCtx )` — `TKN_CLOSE_BUTTON`, `_ACTION`, `_KEY`, `_SWIPE`, `_TIMEOUT` |
| `SetClickCallback` | a click on a card's body: `( hToaster, id, pCtx )`; without one the body takes no clicks |

A callback runs after the toast has left the queue: it may post or dismiss. `Dismiss`, `DismissKey`
and `DismissAll` are silent. `GetHistory( hWnd, recs() )` returns the last toasts to go, oldest
first: id, key, severity, title, message, reason (`TKN_CLOSE_PROGRAMMATIC` for those dismissed in
code), repeat count, times, itemData. Its size is set with `SetHistorySize`, default 50.

## Colours and theme

`TKNOTIFY_COLORS`, the struct [tkInfoBar](tkInfoBar) uses, with its `Shadow` (black at an alpha: 120
on a dark theme, 64 on a light one) drawn as rings round each card. `tkNotify_ThemeColors( t )` maps
them from the theme's roles. `SetColors` pins them until `UnpinColors`. `ApplyFonts( hWnd, text, title, glyph )`
hands over a form's fonts. Otherwise the title is Inter Bold and the glyph the bundled icon font,
opened on the surface.

## Settings

`TKTOASTER_SETTINGS` holds every setting above. `tkToast_SetSettings` and `GetSettings` work per
window. `tkToast_SetDefaults` and `GetDefaults` set what a new toaster starts with, so an app sets
its policy once.

## In the Form Designer

The toolbox's **Toaster** (Components) is the form window's toaster; a second one on a form is the
same toaster.

- **Properties:** Position, MaxVisible, Width, Durations, Insets, PauseOnHover, PauseOnWindowBlur,
  CoalesceRepeats, Animate, TimeScale and Timeouts.
- **Events:** Action, Dismissed and Click, for toasts posted without handlers of their own.

Post toasts from the form's code with `tkToast_ShowText( any widget, ... )`. A toast is an event,
not a value, so a Toaster has no binding. See [Form Designer](Form-Designer).

## Public declarations

### Constants

- `TST_POS_TOP_LEFT`, `TST_POS_TOP_CENTER`, `TST_POS_TOP_RIGHT`, `TST_POS_BOTTOM_LEFT`,
  `TST_POS_BOTTOM_CENTER`, `TST_POS_BOTTOM_RIGHT` · `TST_PRIO_NORMAL`, `TST_PRIO_HIGH`.
- **Timings and sizes:** `TKTOAST_HOLD_MIN_MS`, `TKTOAST_ENTER_MS`, `TKTOAST_LEAVE_MS`,
  `TKTOAST_MOVE_MS`, `TKTOAST_SLIDE`, `TKTOAST_SHADOW`, `TKTOAST_SWIPE`, `TKTOAST_SWIPE_SLOP`,
  `TKTOAST_SWIPE_SPEED`, `TKTOAST_MARQUEE_MS`, `TKTOAST_TIMER`.
- **From tkNotify:** the severities `TKN_INFO` … `TKN_ERROR`, the close reasons `TKN_CLOSE_*`, the
  progress values `TKN_PROGRESS_*` and the parts `TKN_PART_*` — see [tkInfoBar](tkInfoBar).

### Types

`TK_TOAST`, `TKTOAST_RECORD`, `TKTOASTER_SETTINGS`, `TKNOTIFY_COLORS` (from tkNotify), and the
callback types `TST_ActionSub`, `TST_DismissedSub`, `TST_ClickSub`.

### Procedures

```freebasic
function tkToast_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkToast_GetToaster( byval hWnd as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkToast_Show( byval hWnd as TK_WIDGET ptr, byref t as TK_TOAST ) as long
function tkToast_ShowText( byval hWnd as TK_WIDGET ptr, byref msg as const ustring, byval nSeverity as long = TKN_INFO ) as long
function tkToast_Begin( byval hWnd as TK_WIDGET ptr, byref msg as const ustring, byref key as const ustring = "" ) as long
function tkToast_SetProgress( byval hWnd as TK_WIDGET ptr, byval id as long, byval n as long ) as boolean
function tkToast_Finish( byval hWnd as TK_WIDGET ptr, byval id as long, byval nSeverity as long, _
                         byref msg as const ustring, byval duration as long = -1 ) as long
function tkToast_Update( byval hWnd as TK_WIDGET ptr, byval id as long, byref t as TK_TOAST ) as boolean
function tkToast_SetMessage( byval hWnd as TK_WIDGET ptr, byval id as long, byref msg as const ustring ) as boolean
sub tkToast_Dismiss( byval hWnd as TK_WIDGET ptr, byval id as long )
sub tkToast_DismissKey( byval hWnd as TK_WIDGET ptr, byref key as const ustring )
sub tkToast_DismissAll( byval hWnd as TK_WIDGET ptr )
function tkToast_IsLive( byval hWnd as TK_WIDGET ptr, byval id as long ) as boolean
function tkToast_IsShown( byval hWnd as TK_WIDGET ptr, byval id as long ) as boolean
function tkToast_FindKey( byval hWnd as TK_WIDGET ptr, byref key as const ustring ) as long
function tkToast_GetVisibleCount( byval hWnd as TK_WIDGET ptr ) as long
function tkToast_GetQueuedCount( byval hWnd as TK_WIDGET ptr ) as long
function tkToast_GetRemaining( byval hWnd as TK_WIDGET ptr, byval id as long ) as long
function tkToast_GetRepeat( byval hWnd as TK_WIDGET ptr, byval id as long ) as long
function tkToast_IsHeld( byval hWnd as TK_WIDGET ptr ) as boolean
function tkToast_GetHistory( byval hWnd as TK_WIDGET ptr, recs() as TKTOAST_RECORD ) as long
function tkToast_GetCardRect( byval hWnd as TK_WIDGET ptr, byval id as long, byref rc as TKRECT ) as boolean
function tkToast_GetPartRect( byval hWnd as TK_WIDGET ptr, byval id as long, byval part as long, byref rc as TKRECT ) as boolean
function tkToast_GetCard( byval hWnd as TK_WIDGET ptr, byval id as long ) as TK_WIDGET ptr
sub tkToast_ComputeArea( byref st as TKTOASTER_SETTINGS, byref rcRoot as TKRECT, byval fScale as single, _
                         byref rcArea as TKRECT )
function tkToast_CardWidth( byref st as TKTOASTER_SETTINGS, byref rcRoot as TKRECT, byval fScale as single ) as long
sub tkToast_ComputeLayout( byref st as TKTOASTER_SETTINGS, byref rcRoot as TKRECT, byval fScale as single, _
                           heights() as long, byval n as long, rects() as TKRECT )
sub tkToast_SetDefaults( byref st as TKTOASTER_SETTINGS )
function tkToast_GetDefaults( ) as TKTOASTER_SETTINGS
sub tkToast_GetSettings( byval hWnd as TK_WIDGET ptr, byref st as TKTOASTER_SETTINGS )
sub tkToast_SetSettings( byval hWnd as TK_WIDGET ptr, byref st as TKTOASTER_SETTINGS )
function tkToast_GetPosition( byval hWnd as TK_WIDGET ptr ) as long
sub tkToast_SetPosition( byval hWnd as TK_WIDGET ptr, byval nPos as long )
function tkToast_GetMaxVisible( byval hWnd as TK_WIDGET ptr ) as long
sub tkToast_SetMaxVisible( byval hWnd as TK_WIDGET ptr, byval n as long )
function tkToast_GetWidth( byval hWnd as TK_WIDGET ptr ) as long
sub tkToast_SetWidth( byval hWnd as TK_WIDGET ptr, byval cwDesign as long )
sub tkToast_SetMargins( byval hWnd as TK_WIDGET ptr, byval nMargin as long )
sub tkToast_SetGap( byval hWnd as TK_WIDGET ptr, byval nGap as long )
sub tkToast_SetInsets( byval hWnd as TK_WIDGET ptr, byval l as long, byval t as long, byval r as long, byval b as long )
sub tkToast_SetNarrowWidth( byval hWnd as TK_WIDGET ptr, byval cwDesign as long )
sub tkToast_SetNewestNearEdge( byval hWnd as TK_WIDGET ptr, byval b as boolean )
function tkToast_GetPauseOnHover( byval hWnd as TK_WIDGET ptr ) as boolean
sub tkToast_SetPauseOnHover( byval hWnd as TK_WIDGET ptr, byval b as boolean )
function tkToast_GetPauseOnWindowBlur( byval hWnd as TK_WIDGET ptr ) as boolean
sub tkToast_SetPauseOnWindowBlur( byval hWnd as TK_WIDGET ptr, byval b as boolean )
sub tkToast_SetDurations( byval hWnd as TK_WIDGET ptr, byval normalMs as long, byval alertMs as long )
function tkToast_GetCoalesceRepeats( byval hWnd as TK_WIDGET ptr ) as boolean
sub tkToast_SetCoalesceRepeats( byval hWnd as TK_WIDGET ptr, byval b as boolean )
function tkToast_GetTimeScale( byval hWnd as TK_WIDGET ptr ) as single
sub tkToast_SetTimeScale( byval hWnd as TK_WIDGET ptr, byval f as single )
function tkToast_GetTimeouts( byval hWnd as TK_WIDGET ptr ) as boolean
sub tkToast_SetTimeouts( byval hWnd as TK_WIDGET ptr, byval bOn as boolean )
sub tkToast_SetHistorySize( byval hWnd as TK_WIDGET ptr, byval n as long )
function tkToast_GetAnimate( byval hWnd as TK_WIDGET ptr ) as boolean
sub tkToast_SetAnimate( byval hWnd as TK_WIDGET ptr, byval bAnimate as boolean )
function tkToast_IsAnimating( byval hWnd as TK_WIDGET ptr ) as boolean
function tkToast_GetCardOpacity( byval hWnd as TK_WIDGET ptr, byval id as long ) as single
function tkToast_FocusToasts( byval hWnd as TK_WIDGET ptr ) as boolean
function tkToast_IsKeyMode( byval hWnd as TK_WIDGET ptr ) as boolean
function tkToast_GetFocusPart( byval hWnd as TK_WIDGET ptr, byval id as long ) as long
sub tkToast_SetActionCallback( byval hWnd as TK_WIDGET ptr, byval usersub as TST_ActionSub )
sub tkToast_SetDismissedCallback( byval hWnd as TK_WIDGET ptr, byval usersub as TST_DismissedSub )
sub tkToast_SetClickCallback( byval hWnd as TK_WIDGET ptr, byval usersub as TST_ClickSub )
sub tkToast_ApplyFonts( byval hWnd as TK_WIDGET ptr, byval fText as TTF_Font ptr, _
                        byval fTitle as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkToast_ApplyTheme( byval hWnd as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkToast_GetColors( byval hWnd as TK_WIDGET ptr, byval pColors as TKNOTIFY_COLORS ptr )
sub tkToast_SetColors( byval hWnd as TK_WIDGET ptr, byval pColors as TKNOTIFY_COLORS ptr )
sub tkToast_UnpinColors( byval hWnd as TK_WIDGET ptr )
sub tkToast_TickForTest( byval hWnd as TK_WIDGET ptr, byval nowMs as longint )
function tkToast_GetClockMs( byval hWnd as TK_WIDGET ptr ) as long
```

### See also

- [tkControls](Category-tkControls)
- [tkInfoBar](tkInfoBar), the same look in the layout; its page lists tkNotify's constants
- [tkHost](tkHost), [tkTheme](tkTheme), [tkKeys](tkKeys) (a chord for `tkToast_FocusToasts`)
- [Form Designer](Form-Designer)
