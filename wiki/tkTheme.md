[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTheme**

# tkTheme

Keeps the shared light and dark theme every tkControls control takes its colours from.

A theme is one `TKTHEME_COLORS` struct of semantic **roles** (`Window`, `Surface`, `Text`, `Accent`, `Selected`, `Popup`, `Border`, `Error` and the rest), not a colour for each field of each control. Every control derives its own colours from the roles, so one theme switch restyles the whole program.

A theme is **applied**, not looked up at paint time. `tkTheme_Apply( t )` makes `t` the process-wide current theme and sends `TKM_THEMECHANGED` to every widget on every surface; each control then copies the roles it uses into its own colours, unless the program pinned that control's colours. Main windows and dialogs take `t.Window` as their background. Applying a theme equal to the current one does nothing. Before any theme is applied, `tkTheme_Get()` is the Dark preset, which is what every control starts with.

In a [tkApp](tkApp) program use `tkApp_SetTheme` or `tkApp_SetThemeMode` instead: they apply the theme and also fire the forms' `OnThemeChanged`, and `TKAPP_THEME_SYSTEM` follows the OS light/dark setting live.

## Importing

```freebasic
#import "vendor/tkControls/tkTheme"

using tkTheme
```

Every control and [tkApp](tkApp) import tkTheme publicly, so `using tkTheme` usually needs no `#import` of its own. It re-exports [tkHost](tkHost).

## Example

```freebasic
dim as TKTHEME_COLORS t = tkTheme_Dark()
t.Accent = tkRGB( 0, 120, 215 )
tkApp_SetTheme( t )                      ' every unpinned control and every form repaints

dim as TKBUTTON_COLORS danger = tkButton_ThemeColors( t )
danger.BackColor = tkRGB( 196, 43, 28 )
tkButton_SetColors( hDelete, @danger )   ' pins this button: the theme leaves it alone
tkButton_UnpinColors( hDelete )          ' ...until it is handed back
```

## Presets and the system setting

`tkTheme_Dark()` and `tkTheme_Light()` are the two presets. `tkTheme_SystemIsDark()` reads the OS preference through SDL (an unknown answer reads as light), and `tkTheme_System()` is the matching preset. `tkTheme_Equal( a, b )` compares two themes.

## Controls and pinning

Each control has, beside its own `SetColors`:

- `tk<X>_ThemeColors( t )`: the control's colour set derived from the roles (controls with a `TK<X>_COLORS` type);
- `tk<X>_ApplyTheme( h, t )`: applies the theme unless the colours are pinned;
- `tk<X>_UnpinColors( h )`: hands the control back to the theme and applies it at once.

Any colour setter the program calls pins the control. Item-level colours (a chart series, a toolbar item's foreground) are data, never pinned and never themed. A widget of your own follows the theme by handling `TKM_THEMECHANGED` and reading `tkTheme_Get()`.

## The roles

| Role | Used for |
| --- | --- |
| `IsDark` | Whether this is a dark theme, for the program's own choices |
| `Window` | The form background, and controls that sit flat on it |
| `Surface`, `SurfaceHot`, `SurfaceDisabled` | Control faces: buttons, fields, bars |
| `Text`, `TextHot`, `TextStrong`, `TextDim`, `TextDisabled` | Text: normal, under the mouse, emphasised (titles, pressed), secondary (captions, placeholders), disabled |
| `Accent`, `AccentHot` | Checked, on, progress, today |
| `FocusRing` | Focus rings and focused borders |
| `Border`, `BorderDisabled`, `Divider` | Outlines, separators, grid lines |
| `Selected`, `SelectedText` | Selection and pressed fill |
| `Popup`, `PopupText` | Menus, dropdowns, tooltips |
| `Track` | The unfilled part of a track: toggle off, progress |
| `Success`, `Warning`, `Error` | Status colours |

Colours are `ulong` `&hAARRGGBB` values, built with `tkRGB`. `tkTheme_Apply` makes `Window`
opaque whatever alpha it was given.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Types

```freebasic
type TKTHEME_COLORS
    IsDark          as boolean
    Window          as ulong     ' form background; controls that sit flat on it
    Surface         as ulong     ' control face: buttons, fields, bars
    SurfaceHot      as ulong     ' face under the mouse
    SurfaceDisabled as ulong
    Text            as ulong
    TextHot         as ulong     ' text under the mouse
    TextStrong      as ulong     ' titles, pressed and emphasised text
    TextDim         as ulong     ' secondary text: captions, labels, placeholders
    TextDisabled    as ulong
    Accent          as ulong     ' checked / on / progress / today
    AccentHot       as ulong
    FocusRing       as ulong     ' focus rings and focused borders
    Border          as ulong
    BorderDisabled  as ulong
    Divider         as ulong     ' separators, grid lines, hairlines
    Selected        as ulong     ' selection and pressed fill
    SelectedText    as ulong
    Popup           as ulong     ' menus, dropdowns, tooltips
    PopupText       as ulong
    Track           as ulong     ' the unfilled part of a track: toggle off, progress
    Success         as ulong
    Warning         as ulong
    Error           as ulong
end type
```

### Procedures

```freebasic
function tkTheme_Dark( ) as TKTHEME_COLORS
function tkTheme_Light( ) as TKTHEME_COLORS
function tkTheme_SystemIsDark( ) as boolean
function tkTheme_System( ) as TKTHEME_COLORS
function tkTheme_Equal( byref a as TKTHEME_COLORS, byref b as TKTHEME_COLORS ) as boolean
function tkTheme_Get( ) as TKTHEME_COLORS
sub tkTheme_Apply( byref t as TKTHEME_COLORS )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
