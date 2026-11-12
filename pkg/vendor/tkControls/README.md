# tkControls

Owner-drawn controls for tiko on **SDL3 + SDL_ttf**, for Windows and Linux. They are the
cross-platform twin of [PsControls](../PsControls/README.md): the same controls, the same
callbacks and the same silent setters, drawn by tkControls itself into SDL windows instead of
Win32 ones. The two families are separate packages and never share names: `tkButton_SetText`
here, `PsButton_SetText` there.

Each control is a module of the `vendor` package, reached with one `#import`:

```freebasic
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkButton"

using tkApp
using tkHost
using tkButton
```

Every module imports `vendor/tkControls/tkHost` (the widget core) and, through it,
`vendor/SDL3/ttf` and `vendor/SDL3/image`.

**Fonts come with the package**: Inter (text), Cascadia Mono (code) and Fluent UI System Icons
(glyphs), copied beside every program that imports tkHost. `tkHost_FontDir() & TK_FONT_UI` is
always a file that is there; the `TK_ICON_*` constants name the glyphs.

`tkCodeEdit` hosts **scintk**, a Scintilla build for tkControls (`tkCodeEdit/scintk`), loaded at
run time and copied beside the program as `scintk.dll` / `libscintk.so`.

Runnable demos and a self-test for every control are in the toolchain's `examples/tkControls/`,
with the porting notes (`FINDINGS.md`, `PORTING.md`).

## The modules

Each directory is one module, `vendor/tkControls/<name>`; its `PORT.md` records what changed
from the PsControls control it ports.

| Module | What it is |
| --- | --- |
| `tkApp` | the application framework (PsApp): start-up, loop, forms, fonts, theme |
| `tkHost` | the widget core: surfaces, widget tree, focus, capture, timers, popups, bundled fonts |
| `tkPaint` | the drawing surface (PsBufferPaint) on SDL_Renderer + SDL_ttf |
| `tkTheme` | the shared light / dark theme |
| `tkThemeFile` | a `.tktheme` read at run time: `tkTheme_Load( path )` installs a theme a user picks |
| `tkKeys` | keyboard shortcuts and key maps |
| `tkTest` | the self-test kit the examples use |
| `tkButton`, `tkCheckBox`, `tkOptionButton`, `tkToggle` | buttons and switches |
| `tkTextBox`, `tkNumericUpDown`, `tkDatePicker`, `tkCalendar`, `tkCodeEdit` | text, numbers, dates, code |
| `tkListTree`, `tkComboBox`, `tkSelectBar`, `tkTabBar`, `tkColumnHeader` | lists and selection |
| `tkMenuBar`, `tkPopupMenu`, `tkToolbar`, `tkIconPanel`, `tkStatusBar` | command surfaces |
| `tkLayout` | automatic position and size: Anchor and Dock, in design units |
| `tkLabel`, `tkPanel`, `tkGroupBox`, `tkPicture`, `tkTabControl` | text, containers, images and tabbed pages |
| `tkSplitter`, `tkScrollPanel`, `tkScrollBar`, `tkVScrollBar`, `tkHScrollBar` | layout and scrolling |
| `tkMessageBox`, `tkColorPicker`, `tkTooltip`, `tkProgressBar`, `tkFileDialog` | popups and feedback |
| `tkChart` | line, column, HLOC and pie charts |
| `tkImage`, `tkFontList` | image files; the fonts installed on the machine |

The controls are under the [Mozilla Public License 2.0](LICENSE). The fonts keep their own
licences (SIL OFL 1.1, MIT), shipped beside them in `fonts/`; scintk's Scintilla and Lexilla
keep theirs in `tkCodeEdit/scintk/vendor/`.
