[Home](Home) › [All Categories](Categories) › [Vendor Packages](Vendor-Packages) › **tkControls**

# tkControls

> **In tiko.** Owner-drawn controls on **SDL3 and SDL_ttf**, for **Windows, Linux and macOS**, written in tiko. They ship with the toolchain as modules of the `vendor` package, source only: `#import "vendor/tkControls/tkButton"` and nothing on the command line.

tkControls is the cross-platform twin of [PsControls](Category-PsControls): the same controls, the same callbacks and the same silent setters, drawn into SDL windows instead of Win32 ones. One program builds and runs on all three systems unchanged. The two families are separate and never share names: `tkButton_SetText` here, `PsButton_SetText` there.

Every control draws itself. There is no system control underneath, so a window looks the same on every machine and can be themed to any palette, dark ones included.

To draw a window instead of coding it, see the [Form Designer](Form-Designer).

## Importing a control

Each control is one module, `vendor/tkControls/<name>`:

```freebasic
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkButton"

using tkApp
using tkHost
using tkButton
```

`using` lets every name be written bare: `tkButton_Create`, `BTN_ALIGN_CENTER`. Without it, write `tkButton.tkButton_Create`.

Every module imports [tkHost](tkHost), the widget core, and through it `vendor/SDL3/ttf` and `vendor/SDL3/image`, so SDL's own names are there too. A control is a `TK_WIDGET ptr`, made with `tk<Name>_Create( hParent, id )`; `using tkHost` names the type and the `tkWidget_*` calls that place it.

A module that comes in through another one's import is named only after that one's `using`: write `using tkButton` before `using tkHost`, and `using tkHost` before `using tkPaint`. The other order stops with `TKO0923`.

Runnable demos and a self-test for every control are in the toolchain's `examples/tkControls/`, one folder each, built with [`tiko build`](Category-Tiko-Build). `examples/tkControls/tpad` is the program of the [Notepad2 Tutorial](Notepad2-Tutorial): the [Notepad Tutorial](Notepad-Tutorial)'s text editor rebuilt on tkControls, running on Windows, Linux and macOS.

## The application framework

[tkApp](tkApp) is the quick way to a running program. It starts SDL, loads the fonts, runs the event loop and tears down, and each form's events arrive as callbacks:

```freebasic
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkButton"
using tkApp
using tkHost
using tkButton

dim shared as TK_WIDGET ptr gOk

sub Main_Size( byval f as TK_FORM ptr, byval cx as long, byval cy as long )
    tkWidget_SetPos( gOk, cx - tkForm_Scale( f, 100 ), cy - tkForm_Scale( f, 44 ), _
                     tkForm_Scale( f, 88 ), tkForm_Scale( f, 32 ) )
end sub

sub Ok_Click( byval hButton as TK_WIDGET ptr, byval id as long )
    tkApp_Quit( 0 )
end sub

if tkApp_Init( ) = false then end 1
dim as TK_FORM ptr f = tkApp_NewForm( "Hello", 640, 400 )
gOk = tkButton_Create( tkForm_Widget( f ), 1001 )   ' themed, with the form's font
tkButton_SetText( gOk, "OK" )
tkButton_SetClickCallback( gOk, @Ok_Click )
tkForm_OnSize( f, @Main_Size )
end tkApp_Run( f )
```

| Module | What it is |
|---|---|
| [tkApp](tkApp) | Start-up, the event loop, tear-down, `tkApp_RunOnUI` for background threads, timers, and forms whose events arrive as callbacks; modal forms; per-monitor scale |
| [tkTheme](tkTheme) | The shared theme: semantic colour roles, Dark and Light presets, or the system's choice |
| [tkHost](tkHost) | The widget core: windows ("surfaces"), the widget tree, focus, capture, timers, popups, the bundled fonts |
| [tkPaint](tkPaint) | The drawing surface every control paints through, on SDL_Renderer and SDL_ttf |
| [tkKeys](tkKeys) | Keyboard shortcuts: chords such as `Ctrl+Shift+S`, parsed, matched and shown |

The toolchain's `examples/tkControls/tkApp` is a starter to copy: a form with a text box, a theme switch, a modal About box and a worker thread reporting progress.

## The controls

| Group | Pages |
|---|---|
| Text, numbers and dates | [tkTextBox](tkTextBox), [tkNumericUpDown](tkNumericUpDown), [tkDatePicker](tkDatePicker), [tkCalendar](tkCalendar), [tkCodeEdit](tkCodeEdit) |
| Buttons and switches | [tkButton](tkButton), [tkCheckBox](tkCheckBox), [tkOptionButton](tkOptionButton), [tkToggle](tkToggle) |
| Lists and selection | [tkListTree](tkListTree), [tkComboBox](tkComboBox), [tkSelectBar](tkSelectBar), [tkTabBar](tkTabBar) |
| Command surfaces | [tkMenuBar](tkMenuBar), [tkToolbar](tkToolbar), [tkIconPanel](tkIconPanel), [tkStatusBar](tkStatusBar) |
| Containers and layout | [tkPanel](tkPanel), [tkGroupBox](tkGroupBox), [tkTabControl](tkTabControl), [tkSplitter](tkSplitter) |
| Scrolling | [tkScrollPanel](tkScrollPanel), [tkVScrollBar](tkVScrollBar), [tkHScrollBar](tkHScrollBar) |
| Popups and feedback | [tkMessageBox](tkMessageBox), [tkColorPicker](tkColorPicker), [tkFileDialog](tkFileDialog), [tkTooltip](tkTooltip), [tkProgressBar](tkProgressBar) |
| Static display | [tkLabel](tkLabel), [tkPicture](tkPicture) |
| Data display | [tkChart](tkChart) |

## Support modules

| Module | What it is |
|---|---|
| [tkLayout](tkLayout) | Automatic placement by anchor and dock, in design units, shared with the form designer |
| [tkForms](tkForms) | `FormBase`, the base a designed form extends: a window, a layout, modal and modeless show, caption translation |
| [tkImage](tkImage) | Image files (`.png`, `.bmp`, `.jpg`, `.gif`, `.ico`, ...) for icon slots, through SDL_image |
| [tkPopupMenu](tkPopupMenu) | The dropdown behind menus, combo boxes and toolbars |
| [tkColumnHeader](tkColumnHeader) | The column header band; tkListTree places one above its rows |
| [tkScrollBar](tkScrollBar) | The scrollbar engine behind tkVScrollBar and tkHScrollBar |
| [tkFontList](tkFontList) | The fonts installed on the machine, for a font picker |
| [tkTest](tkTest) | The self-test kit the examples use: real SDL events, `PASS` / `FAIL` lines |

## Fonts

**The fonts come with the package**, so a program looks the same on every system: Inter for text, Cascadia Mono for code and Fluent UI System Icons for glyphs. They are copied beside every program that imports tkHost, with their licences, so `tkHost_FontDir() & TK_FONT_UI` is always a file that is there. The `TK_ICON_*` constants name the glyphs. See [tkHost](tkHost).

[tkCodeEdit](tkCodeEdit) hosts **scintk**, a Scintilla build for tkControls, loaded at run time and copied beside the program as `scintk.dll` or `libscintk.so` when the program imports tkCodeEdit.

## Coming from PsControls

The controls keep PsControls' names with a `tk` prefix: `PsButton_*` is `tkButton_*`, `PSBUTTON_*` is `TKBUTTON_*`, and `PsApp`'s `PsApplication` / `PsForm` become `tkApp_*` / `tkForm_*` procedures over a `TK_FORM ptr`. What changes is what Win32 provided:

- A control is a `TK_WIDGET ptr`, not an `HWND`, and `Create` takes the parent widget and an id. A form's own widget is `tkForm_Widget( f )`.
- Fonts are `TTF_Font ptr` (SDL_ttf), not `HFONT`; images load through SDL_image.
- Colours are `ulong` ARGB (`tkRGB( r, g, b )`), not `COLORREF`.
- Messages are `TKM_*`, shaped like the `WM_*` ones they replace; there is no message pump to filter and no `PsRegistry`.
- Scale replaces DPI: a form reports `tkForm_OnScaleChanged` when it moves to a monitor with a different scale.

Each control's page lists its own differences. The PsControls page of the same control remains the behaviour reference for everything else.

## Requirements

- **Windows or Linux** (x86-64), or **macOS** on Apple Silicon.
- **SDL3, SDL3_ttf and SDL3_image.** On Windows the toolchain ships them and copies them beside the program. On Linux the program links the system's libraries: install the distribution's SDL3 development packages. On macOS it links Homebrew's: `brew install sdl3 sdl3_ttf sdl3_image`. See [Vendor Packages](Vendor-Packages).

## Licence

[Mozilla Public License 2.0](https://github.com/PaulSquires/tiko-lang/blob/master/pkg/vendor/tkControls/LICENSE), file-level copyleft: use the controls in closed-source software freely; if you modify these files, publish those files' changes. The fonts keep their own licences (SIL OFL 1.1 for Inter and Cascadia Mono, MIT for Fluent UI System Icons), copied beside them; scintk's Scintilla and Lexilla keep theirs.

### See also

- [PsControls](Category-PsControls)
- [Vendor Packages](Vendor-Packages)
- [SDL3 Tutorial](SDL3-Tutorial)
- [Notepad2 Tutorial](Notepad2-Tutorial)
- [Notepad Tutorial](Notepad-Tutorial)
- [tiko build](Category-Tiko-Build)
