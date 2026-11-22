[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **Themes Tutorial**

# Themes and styles: a beginner's tutorial

Give your program a colour scheme in a few clicks, make a button stand out, and let your users
switch between light and dark. Then do the same for tkEdit itself.

You need tkEdit and nothing else. No colour theory, no code to start with: the code comes later, and
it's short.

## Contents

1. [Five words to know](#1-five-words-to-know)
2. [Make a project](#2-make-a-project)
3. [Pick a ready-made theme](#3-pick-a-ready-made-theme)
4. [Make it yours with one colour](#4-make-it-yours-with-one-colour)
5. [Check the light version](#5-check-the-light-version)
6. [Round corners and fonts](#6-round-corners-and-fonts)
7. [Styles: a red Delete button](#7-styles-a-red-delete-button)
8. [Colour one control by hand](#8-colour-one-control-by-hand)
9. [Light and dark while the program runs](#9-light-and-dark-while-the-program-runs)
10. [Reading a theme file](#10-reading-a-theme-file)
11. [Theming tkEdit itself](#11-theming-tkedit-itself)
12. [Without the designer](#12-without-the-designer)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Five words to know

| Word | What it means |
| --- | --- |
| **Theme** | One file, `something.tktheme`, that says how the whole program looks: colours, corners, fonts and styles. |
| **Variant** | Every theme has two: **Dark** and **Light**. You design both in one file. |
| **Role** | A *job* a colour does, not a colour: `Window` (the background), `Surface` (a button's face), `Text`, `Accent` (checked boxes, progress, the focus ring) and so on. There are 23. |
| **Style** | A named look you can give any control, such as **Primary** or **Danger**. It lives in the theme. |
| **Accent** | The one colour that gives a theme its personality. Set it and tkEdit works out the rest. |

The big idea: **controls never hold a colour of their own unless you ask.** A button doesn't say "I
am grey"; it says "my face is the `Surface` role". Change the theme, or flip Dark to Light, and every
control follows at once.

---

## 2. Make a project

1. In tkEdit, **File > New**, then **GUI Application**. Give it a folder, say `myapp`.
2. tkEdit makes this:

```
myapp/
  tiko.toml
  main.tiko                  starts the program
  appTheme/
    appTheme.tktheme         YOUR THEME (starts as "Default")
    appTheme.design.tiko     made from the theme: don't edit, do commit
  frmMain/
    frmMain.tkform           the form
    frmMain.design.tiko
    frmMain.tiko             your code
```

3. Drop a few controls on the form from the toolbox: a **Button**, a **CheckBox**, a **TextBox** and
   a **ProgressBar** are enough to see what a theme does.
4. Press **F5**. Your program runs in the Default theme, dark or light to match your computer.

> **Tip:** `appTheme` is the *project theme*. Every form in the project shares it. You never edit
> `appTheme.design.tiko`; tkEdit rewrites it each time you save the theme.

---

## 3. Pick a ready-made theme

1. **Design > Project Theme...** opens the **Theme Center**.
2. You are on the **Theme** page. It shows a gallery of themes:

| Theme | What it is |
| --- | --- |
| **Default** | The standard look. |
| **High Contrast** | Strong colours and thicker borders; every text passes the accessibility check. |
| **Ocean**, **Forest**, **Ember**, **Violet** | Default with a blue, green, orange or purple accent. |

3. Click **Ocean**, or move to it with the arrow keys. It becomes your theme at once: the **Name**
   box says Ocean, and the **Preview** on the right shows a label, buttons, a group of options, a
   text box, a combo box and a progress bar, all in Ocean. Try a few.
4. Press **Save** to keep the one you like: it writes the theme and closes the Theme Center.
   **Cancel** closes it without writing anything.

That's it. Your form on the design surface now wears Ocean too. Press **F5** to see the program in it.

> **What Save did:** it wrote `appTheme.tktheme`, regenerated `appTheme.design.tiko`, and made sure
> `main.tiko` installs the theme. New projects already have those lines; older ones get them added.

---

## 4. Make it yours with one colour

Ocean is nice, but maybe your app should be teal.

1. **Design > Project Theme...** again.
2. On the **Theme** page, find **Accent**. Type a colour as `#RRGGBB`, for example `#00897B`, or
   press **Pick...** to choose one in a colour picker.
3. Watch the preview: the check box tick, the progress bar, the toggle and the focus ring all turn
   teal. tkEdit worked out the hover shade, the selection colour and the text that sits on top of
   it, for both Dark and Light.
4. **Save**.

Your theme file is now about this short:

```toml
format = 1
name = "Ocean"
accent = "#00897B"

[dark]

[light]
```

Three lines that matter. That is a complete theme.

> **Rename it:** the name box at the top of the Theme Center sets `name`. Call it after your app.

---

## 5. Check the light version

Your users might run their computer in light mode, so check both.

- **In the Theme Center:** the **Dark | Light** switch at the top changes which variant you're
  looking at and editing.
- **On the form:** the **Preview Light / Dark** command flips the design surface between the two.
  Only the form changes; tkEdit keeps its own look. It has no menu row or key of its own, so give it
  a key once: **File > Options > Keyboard Shortcuts** (**Ctrl+K**), type `preview` in the filter,
  pick the row, **Modify**, and press the key you want.
- **Test Form** (**Alt+F5**) opens in whichever variant the surface shows.

### The contrast line

The Theme Center's contrast line tells you whether people can read your colours:

- `Contrast: every pair passes AA` means all is well.
- Otherwise it names the first pair that fails, such as `Text on Surface: 3.1:1 (needs 4.5)`, and how
  many more there are.

"AA" is the common accessibility standard: text needs a ratio of 4.5:1 against what it sits on.
The line **warns, it never stops you**. Check both variants: a colour that reads well on dark can
vanish on light.

---

## 6. Round corners and fonts

Open the **Fonts and Shape** page.

**Shape**
- **Corner radius:** `0` gives square corners, `4` softly rounded ones, `12` pill-shaped buttons.
- **Border width:** `1` is normal, `2` is bold.

The preview follows as you type. A control whose corners you set yourself in the Properties panel
keeps its own value; the theme only shapes controls you haven't touched.

**Fonts**
- **UI font**, **Bold font**, **Size**: the text of every control.
- **Glyph font**: the icon font.
- **Mono font**: fixed-width text.

Fonts are **file names**, such as `Inter-Regular.ttf`, found in your program's font folder (the
bundled fonts, or font files you ship beside the program). Leave a box empty to keep the bundled
default. Fonts are loaded once when the program starts, so they're the same in Dark and Light.

**Build the fonts into the program** puts all four fonts inside your program's `.exe`, so it needs
no font files beside it. When you Save, tkEdit copies them into `appTheme/fonts/` (from that folder
if a font is already there, else your project folder, else the bundled fonts) and the program is
built with them inside. To use a font of your own, put its file in `appTheme/fonts/` or your project
folder and type its name in the box. The build still copies the bundled font files beside the
program, but the program doesn't use them.

**Save** when you like it.

---

## 7. Styles: a red Delete button

Most buttons should look alike. A few shouldn't: the main action ("Save") should stand out, a risky
one ("Delete") should look risky. That's what **styles** are for.

### Make the style

1. **Design > Project Theme...**, then the **Styles** page.
2. Press **Add**. A new style appears, and its **Name** box is ready: call it `Danger`.
3. Under the list of styles are four rows: **Face**, **Text**, **Border** and **Accent**. Each row has a drop-down,
   a swatch showing the colour you get, **Pick...** and **Reset**. A new style starts with Face set
   to `@Accent` and Text to `@SelectedText`.
4. In the **Face** row's drop-down choose `@Error`. Read it as: "a control wearing Danger uses the
   *Error* colour for its face." The `@` means "the colour of that role", so it stays right in both
   Dark and Light.
5. Look at the preview: under the plain button there's one wearing the selected style, with a check
   box and a toggle beside it. They're red now.
6. Add another style, `Primary`. Its Face is already `@Accent`, so there's nothing more to do.
7. **Save**.

What the drop-down offers:

| Choice | It means |
| --- | --- |
| `(theme)` | Leave this colour as the theme has it. |
| `Color...` | A fixed colour. It starts as the colour shown; press **Pick...** to choose another. |
| `@Accent`, `@Error`, ... | The colour of another role. |

**Reset** puts a row back to `(theme)`. The four rows are what most styles need; tick **Show all
roles** to set any of the 23.

> **You only set the Normal look.** Hover, pressed and disabled shades are worked out from it. A
> style that sets `Surface` also gets a matching `SurfaceHot` and `SurfaceDisabled`.

### Use the style

1. With the Theme Center saved and closed, select your **Delete** button on the form.
2. In the Properties panel, find the **Colors** row. Its button says **Theme**: the button follows
   the theme and nothing else.
3. Click it. The **Colors** dialog opens.
4. At the top, set **Style** to `Danger`. The preview turns red.
5. **OK**. The row now says **Danger**.

One style, any control: the same `Danger` works on a button, a check box or a toggle, because a
style swaps *roles*, and every control uses roles.

And because styles live in the theme, switching the project to another theme restyles your Danger
button too.

---

## 8. Colour one control by hand

Sometimes one control needs its own colour. Select it, click its **Colors** row, and you're in the
**Colors** dialog again.

### The Simple page

One row per main part of the control. For a button: **Back** (the face), **Fore** (the text),
**Border** and **Icon**. Each row has a swatch, a box, **Pick...**, and a note saying where the
colour comes from.

In the box you can type:

| You type | It means |
| --- | --- |
| `#C62828` | This exact colour, in both Dark and Light. |
| `#C6282880` | The same, half see-through (the last two digits are opacity). |
| `@Accent` | Whatever the theme's Accent is, in the current variant. |
| *(nothing)* | Inherit: go back to the style, or the theme. |

When the box is empty it shows the colour in force, so you can see what you'd be changing.

Set **Back** to `#2E7D32` and press **OK**. The hover, pressed and disabled faces follow
automatically. The Colors row now says `1 colours` (or `Danger + 1 colours` if it also wears a style).

### The All States page

For full control: every colour the control has, in every state (Normal, Hot, Pressed, Disabled...).
Select one to set it, **Reset** it, or tick **Different in light mode** to give it one value in Dark
and another in Light. The box then edits the half for the variant the dialog shows; flip the
Dark | Light switch to edit the other half.

### Where did this colour come from?

Each colour shows its source. From strongest to weakest:

1. **set on this control** (or **follows this control's Normal colour**, for a derived state)
2. **from the style**
3. **from the theme, for this type** (a theme-wide rule for, say, every Button)
4. **from the theme**

The first one that sets a colour wins. That's the whole system.

> **Undo:** OK is one step. **Ctrl+Z** on the form takes the whole dialog's changes back.

---

## 9. Light and dark while the program runs

Out of the box your program follows the computer's setting, and switches live when the user
changes it. To let the user choose, call `tkApp_SetThemeMode`:

```freebasic
tkApp_SetThemeMode( TKAPP_THEME_DARK )     ' always dark
tkApp_SetThemeMode( TKAPP_THEME_LIGHT )    ' always light
tkApp_SetThemeMode( TKAPP_THEME_SYSTEM )   ' follow the computer (the default)
```

For example, put a button named `btnTheme` on the form and double-click it. tkEdit writes an empty
`btnTheme_Click` handler in `frmMain.tiko`. Fill it in, and add the `#import` and `using` lines
under `#module` at the top of the file so it can see the theme calls:

```freebasic
#module "frmMain"
#import "vendor/tkControls/tkApp"
using tkApp
using tkTheme

' ... the rest of your form code ...

sub Form.btnTheme_Click( )
    if tkApp_ThemeMode( ) = TKAPP_THEME_DARK then
        tkApp_SetThemeMode( TKAPP_THEME_LIGHT )
    else
        tkApp_SetThemeMode( TKAPP_THEME_DARK )
    end if
end sub
```

Every control, every style and every colour you set by hand switches with it.

### Styles from code

The Colors dialog is the easy way. From code (with the same `using tkTheme`), give any control a
style by name:

```freebasic
tkTheme_SetRecipeNamed( btnDelete.Handle, "Danger", 0, 0 )   ' wear Danger
tkTheme_SetRecipeNamed( btnDelete.Handle, "", 0, 0 )         ' back to plain theme
```

An unknown name simply means "no style": nothing breaks.

---

## 10. Reading a theme file

Everything the Theme Center does is saved as plain text. You can open `appTheme.tktheme` in tkEdit
and edit it directly; saving it regenerates the theme's code, just like the dialog's Save. Here is a
fuller one, with comments:

```toml
format = 1                    # always 1
name = "Teal"
accent = "#00897B"            # the quick theme: everything else is worked out from this

[dark]                        # override any role in the dark variant
Surface = "#2A2F3A"

[light]                       # ...and in the light one
accent = "#00695C"            # a variant may have its own accent

[fonts]
embed = true                  # build the fonts into the program (from appTheme/fonts/)
ui = { file = "Inter-Regular.ttf", bold = "Inter-Bold.ttf", size = 10 }

[shape]
CornerRadius = 4
BorderWidth  = 1

[controls.Button]             # a rule for every Button in the program
BorderColor = "@Border"

[styles.Primary]              # styles: roles to swap
Surface = "@Accent"
Text    = "@SelectedText"

[styles.Danger]
Surface = "@Error"
Text    = "@SelectedText"

[styles.Danger.Button]        # Danger, but only on Buttons
BorderColor = "@Error"
```

Rules to remember:

- **Colors** are `"#RRGGBB"`, or `"#RRGGBBAA"` with opacity. The `Window` role is never see-through.
- **`[dark]` and `[light]` take fixed colours only.** `@Role` links belong in styles and
  `[controls.X]` blocks.
- **Lower-case keys are the file's own** (`name`, `accent`, `fonts`). **Capitalised keys are tiko
  names**: role names (`Surface`), control types (`Button`), colour fields (`BorderColor`).
- The `[controls.X]` and `[styles.S.X]` blocks can only be edited here, not in the Theme Center.
  The Theme Center keeps them and shows them in its preview.

### The 23 roles

| Group | Roles |
| --- | --- |
| Surfaces | `Window`, `Surface`, `SurfaceHot`, `SurfaceDisabled` |
| Text | `Text`, `TextHot`, `TextStrong`, `TextDim`, `TextDisabled` |
| Accent | `Accent`, `AccentHot`, `FocusRing`, `Selected`, `SelectedText` |
| Lines | `Border`, `BorderDisabled`, `Divider`, `Track` |
| Popups | `Popup`, `PopupText` (menus, drop-downs, tooltips) |
| Status | `Success`, `Warning`, `Error` |

The Theme Center's **Colors** page lists them all with a swatch each. Select one, type a colour or
**Pick...** one, and **Reset** gives it back to the theme.

---

## 11. Theming tkEdit itself

tkEdit uses the **same** `.tktheme` format and the **same** Theme Center.

### Choose a theme

Open **File > Settings** (**Ctrl+,**) and set:

```toml
theme = "Ocean"          # Default, HighContrast, Ocean, Forest, Ember, Violet, or one of yours
theme_mode = "system"    # system | dark | light
```

Save `settings.toml` and tkEdit changes at once.

### Edit it

**File > Theme File** (**Ctrl+Shift+T**) opens the Theme Center titled **tkEdit Theme**. The first
time, it copies the theme into your own config folder (`themes/<name>.tktheme`), so the shipped
one stays untouched. **Save** applies your changes immediately and closes the Theme Center;
**Cancel** closes it and keeps your theme as it was.

### The editor's colours

A theme for tkEdit has extra tables for the code editor, one set per variant. Only tkEdit reads
them; your programs ignore them.

```toml
[dark.editor]
bg = "#1e1e1e"
caret = "#aeafad"
selection = "#264f78"

[dark.syntax]
comment = { fg = "#6a9955", italic = true }
keyword = "#569cd6"
string = "#ce9178"

[light.editor]
bg = "#ffffff"

[light.syntax]
keyword = "#0000ff"
```

Any key you leave out keeps Default's value. A syntax entry is a colour, or
`{ fg, bg, bold, italic }`. Open the theme file as text in tkEdit and save it: the change shows at
once. The full key list is in tkEdit's configuration notes.

> **Share it:** **Save to Library** in the Theme Center puts a copy in your themes folder. It then
> shows in the gallery of every project, and tkEdit can use it by name. Give it a name of its own
> first: a name the gallery already has (such as `Default` or `Ocean`) is refused. Saving your own
> library theme again under the same name updates it.

---

## 12. Without the designer

Writing a tkControls program by hand? Two ways to theme it.

**Load a `.tktheme` file when the program starts.** Handy if you want your users to drop in their
own themes:

```freebasic
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkThemeFile"
using tkApp
using tkThemeFile

dim as TKAPP_OPTIONS options
if tkApp_Init( options ) = false then end 1

if tkTheme_Load( "themes/Teal.tktheme" ) = false then
    print "theme not loaded: "; tkTheme_LoadError( )   ' the old theme stays in place
end if
```

`tkTheme_Load` is forgiving: a bad colour or an unknown role is skipped, and the rest loads.
`tkTheme_Loaded( )` returns what was loaded; its `Problems` array (`nProblems` long) says what
was skipped and why. It doesn't change fonts (they're loaded at
`tkApp_Init`); to use a theme's fonts, read it first with `tkThemeFile_Read`, pass it to
`tkThemeFile_ApplyOptions( tf, options )` before `tkApp_Init`, then call `tkThemeFile_Install( tf )`.

**Or just an accent, in code:**

```freebasic
using tkTheme
using tkHost
using tkPaint                     ' tkRGB (tkHost's using must come first)

dim as TKTHEME_COLORS dk = tkTheme_Derive( tkTheme_Dark( ), tkRGB( 0, 137, 123 ) )
dim as TKTHEME_COLORS lt = tkTheme_Derive( tkTheme_Light( ), tkRGB( 0, 137, 123 ) )
tkApp_SetThemePair( dk, lt )      ' both variants; the theme mode picks one
```

See [tkTheme](tkTheme) and [tkApp](tkApp) for the full API.

---

## 13. Troubleshooting

| Problem | Fix |
| --- | --- |
| My form doesn't change when I pick a theme. | Press **Save** in the Theme Center. Picking a theme changes the dialog only. |
| The program runs in the old theme. | Check `main.tiko` has `appTheme.ApplyOptions( options )` before `tkApp_Init` and `appTheme.Install( )` after it. If it has no `if tkApp_Init( ... ) = false then` line, tkEdit can't add them and asks you to by hand. |
| One button ignores the theme. | It has its own colours. Open its **Colors** row and clear the boxes (or **Reset** on All States). In hand-written code, a `Set...Color` call pins a control; `UnpinColors` hands it back. |
| One button ignores my corner radius. | You set its corners in the Properties panel, which beats the theme. |
| A style does nothing. | The name on the control must match a style in the theme exactly. A style the theme no longer has still shows in the dialog's list, but does nothing. |
| Drop-down lists and menus don't follow my theme on the design surface. | Pop-ups always use tkEdit's theme in the designer. In your running program they follow your theme. |
| tkEdit says `theme 'x' not found; using Default`. | The `theme` name in `settings.toml` doesn't match a file in your themes folder or a shipped one. |
| tkEdit says `x.toml: not a .tktheme theme; using Default`. | That's an old-format theme. It isn't converted: start a new one from the Theme Center. |
| My font isn't used. | Fonts are file names in the program's font folder. Check the file is there; otherwise the bundled font is used. |

---

### See also

- [Form Designer](Form-Designer): drawing forms in tkEdit
- [tkTheme](tkTheme): roles, presets and pinning
- [tkApp](tkApp): `tkApp_SetThemeMode` and start-up options
- [tkControls](Category-tkControls)
