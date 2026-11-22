# tkApp: port notes (from vendor PsApp)

Vendor PsApp is a class pair, `PsApplication` and `PsForm`. tkApp keeps the family's
procedural shape:

| Vendor | tkApp |
| --- | --- |
| `app.Init( opts )` | `tkApp_Init( opts )` |
| `app.NewForm( title, cx, cy, ... , hParent )` | `tkApp_NewForm( title, cx, cy, pOwner, forcedScale )` |
| `app.Run` / `Quit` / `RunOnUI` / `IsUIThread` | `tkApp_Run` / `tkApp_Quit` / `tkApp_RunOnUI` / `tkApp_IsUIThread` |
| `app.SetTimer` / `KillTimer` | `tkApp_SetTimer` / `tkApp_KillTimer` |
| `app.SetTheme` / `Theme` / `SetThemeMode` / `ThemeMode` / `GlyphFace` / `Options` | `tkApp_*` equivalents |
| `PsApp_Instance` | — (one application per process; `tkApp_IsInit`) |
| `PsForm` members | `tkForm_*( f, … )` |
| `PSFONT_*` | `TKFONT_*` |
| `PSAPP_THEME_*` | `TKAPP_THEME_*` |
| `PSAPP_OPTIONS` | `TKAPP_OPTIONS` |

**Kept:**
- one application per process; a second Init is refused;
- the theme mode: SYSTEM follows the OS live (`SDL_EVENT_SYSTEM_THEME_CHANGED`), LIGHT / DARK
  fix it, NONE leaves the controls' colours;
- SetTheme restyles every unpinned control, gives every form the Window role and fires
  OnThemeChanged;
- `RunOnUI` from any thread, in call order, copying the payload pointer. It runs wherever the
  pump is, inside modal loops too; work still queued when Run returns is dropped;
- form-less timers that are safe to kill from their own proc;
- the font roles (UI, small = −1 pt, bold, large = +2 pt, glyph, glyph large, mono), opened at
  the form's scale on first use and freed with the form;
- the glyph-face fallback order: GlyphFontFile, Segoe Fluent Icons, Segoe MDL2;
- the form callbacks OnSize, OnPaint, OnKeyDown, OnClose (FALSE vetoes), OnDestroy,
  OnThemeChanged, and OnScaleChanged (vendor: OnDpiChanged);
- Show runs OnSize once and focuses the first tab stop;
- ShowModal / EndModal / IsModal; Esc in a modal form ends it with IDCANCEL; the close
  button asks OnClose; ShowModal destroys the form; `Tag`;
- FromWidget (vendor: FromHwnd), walking a popup's owners;
- Run shows the main form, pumps until it closes or Quit, destroys every form and undoes
  Init, then returns the exit code.

**Added (tk only):** the window's settings, which PsForm leaves to Win32 calls on its HWND --
`tkForm_SetStartPosition`, `SetResizable`, `SetMinSize` / `SetMaxSize` (design units, re-applied on a
scale change), `SetWindowState`, `SetAlwaysOnTop`, `SetIcon`, each with a getter.

**Changed:**
- **Fonts are files.** SDL_ttf cannot look up a face, so `TKAPP_OPTIONS` names files
  (`FontUIFile`, `FontUIBoldFile`, `GlyphFontFile`, `FontMonoFile`) inside `FontDir`. The
  default `FontDir` is `%WINDIR%\Fonts\` on Windows and `/mnt/c/Windows/Fonts/` on Linux,
  which suits WSL; a native Linux host must set it. Mono falls back from Cascadia Mono to
  Consolas to the UI file.
- **Controls get the form's font by being on it**: the UI role IS the surface's default font,
  which every control falls back to. Vendor handed `PSFONT_UI` / `PSFONT_GLYPH` to each
  control through PsRegistry. Hand the glyph role over yourself with `ApplyFonts`.
- A form is a tkHost surface plus a full-size **form widget** (`tkForm_Widget`), which is the
  parent for the form's controls. Keys that no control claims bubble up to it, so OnKeyDown
  sees them; Tab is still the host's focus walk.
- A form with an owner is a dialog surface (`tkHost_CreateDialog`), and the owner gets no
  input while it is modal. `cx` / `cy` are DIPs either way.
- `tkApp_Pump()`: one non-blocking turn, used by the self-tests.
- `tkApp_Shutdown()`: Run's tear-down, callable on its own.

**Dropped (Win32-only):**
- COM (`ComMode`), DPI awareness modes (`DpiMode`), GDI+;
- the message filters (`AddMessageFilter`), accelerator tables, `IsDialogMessage`;
- OnCommand, OnNotify, OnMessage and OnTimer (per form) — use `tkApp_SetTimer`;
- OnActivateApp: the host closes popups when the application loses focus;
- the WM_* built-ins, per-form window classes, `Item( id )` (keep your widget pointers), and
  CWindow inheritance.

**Shared change:** `tkHost_SetEventHook` (every event tkHost_Dispatch sees, in every loop),
and `OnCloseRequest` is honoured on main windows too.

**Bugs found:**
- **tiko-lang vendor/SDL3:** `SDL_CreateThread` (a macro over `SDL_CreateThreadRuntime`) does
  not compile — it casts `_beginthreadex` without `@`. The test and demo call
  `SDL_CreateThreadRuntime( fn, name, data, 0, 0 )` directly.
- **Fixed while porting:** Run drained the queue and *then* blocked in `SDL_WaitEvent`. A Quit
  that the drain had just run left the loop asleep (measured: 1 hang in 8). Run now tests
  before it blocks.

**Not verified:**
- the live OS theme switch (`SDL_EVENT_SYSTEM_THEME_CHANGED` is not synthesised by the test);
- a real DPI move between monitors;
- a native Linux font directory;
- the interactive pass.
