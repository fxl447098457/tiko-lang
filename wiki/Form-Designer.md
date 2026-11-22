[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **Form Designer**

# Form Designer

Draw a window in tkEdit, double-click a control, write the handler, press Run.

New to it? The [Contacts Tutorial](Contacts-Tutorial) builds a whole program step by step: menus, a
toolbar, a status bar, a list, a dialog with tabs, a popup menu, the Resource Center and SQLite.

The Form Designer is part of tkEdit. A form is a `.tkform` file. Open one and it appears on a design
surface of real [tkControls](Category-tkControls), so what you see is what the program will show. The
result is ordinary tiko source that builds on Windows, Linux and macOS without the designer.

## Getting started

**File > New**, then **GUI Application**, makes a folder with everything a program needs, and opens its form:

```
myapp/
  tiko.toml
  main.tiko             starts the program and shows the first form
  appTheme/
    appTheme.tktheme    the project's theme: colours, fonts, shape, styles
    appTheme.design.tiko generated from it: don't edit, do commit
  frmMain/
    frmMain.tkform      the form: the designer owns this
    frmMain.design.tiko generated from it: don't edit, do commit
    frmMain.tiko        your code
```

**Design > New Form...** adds another form to a program. Press **F5** to build and run.

From the designer, **Alt+F5** (Test Form) shows the form in its own window with working controls and no
handlers, so you can try the layout without building. Esc closes it.

## On the surface

| To do this | Do this |
|---|---|
| Place a control | Click it in the Toolbox, then click or drag on the form |
| Place one at its default size | Double-click it in the Toolbox. With a panel, group box or scroll panel selected, it goes in it; with a tab control, on the page showing |
| Select | Click. Ctrl or Shift adds or removes. Drag on empty form for a band |
| Move | Drag. It snaps to the grid; hold Alt to place it freely |
| Resize | Drag a grip |
| Nudge | Arrow keys move a grid step, Shift+arrow resizes, Primary+arrow moves one unit |
| Next control | Tab, in tab order |
| Remove | Delete |
| Copy | Primary+X, C and V. Paste goes into the selected container |
| Undo | Primary+Z and Primary+Shift+Z, one step per gesture |
| Line up | The Design menu: align, same size, spacing, bring to front, send to back |

Primary is Ctrl on Windows and Linux, and Cmd on macOS.

The Toolbox and the Properties panel sit beside the form. **Float** puts either one in its own window;
closing that window docks it again.

A control's place in the list is both its stacking order and its tab order.

## Resizing with the window

Each control has an **Anchor** or a **Dock**, set in the Properties panel.

| Anchor | When the parent changes size |
|---|---|
| Left and top (default) | Stays put |
| Right or bottom | Keeps its distance from that edge |
| Both sides of an axis | Stretches |
| Neither side of an axis | Stays centred |

A **Dock** takes a slice of what's left of the parent, in list order: top, bottom, left or right. Fill
takes whatever remains after every other dock. [tkLayout](tkLayout) has the full rules.

A MenuBar or Toolbar docks to the top when you place it, and a StatusBar to the bottom.

## Handlers

Double-click a control and tkEdit binds its usual event, adds an empty handler to your file, and puts
the caret inside. Double-click the empty form for `Form_Load`. **Shift+F7** goes between a form and its
code. The event rows in the Properties panel name any other event: type a name to bind it, or press
`...` to go to its code.

A handler is a member of the form, so it can use the form's controls by name:

```freebasic
#module "frmMain"

public partial type Form
    Clicks as long
end type

sub Form.btnOK_Click( )
    Clicks += 1
    lblCount.Text = str( Clicks )
end sub
```

Each control is a typed value. `.Text`, `.Enabled` and the rest are properties, and `.Handle` reaches
the whole control API.

Some events ask your handler for an answer through a `byref` parameter, which starts at its default:
a Button's, CheckBox's, OptionButton's, SelectBar's, TabBar's, Toolbar's, IconPanel's, StatusBar's, ProgressBar's or Chart's **Tooltip** handler sets `Text` to the tip it should show, and a **Message** handler
(Button, CheckBox, OptionButton, Toggle, TextBox, ComboBox, SelectBar, TabBar, Toolbar, IconPanel, StatusBar, Splitter, ScrollPanel, ColorPicker, ProgressBar, Chart, NumericUpDown, DatePicker, Calendar, ListTree) sets `Handled` to keep a mouse or key message from the
control. A **Paint** handler (Button, CheckBox, OptionButton, Toggle, ComboBox, NumericUpDown, DatePicker, Splitter, ScrollPanel, VScrollBar, HScrollBar, ProgressBar, Chart) draws the control instead (a SelectBar's draws one panel: `tkSelectBar_PaintPanelDefault`; a TabBar's one tab: `tkTabBar_PaintTabDefault`; a MenuBar's, Toolbar's or IconPanel's one item: `tkMenuBar_PaintItemDefault`, `tkToolbar_PaintItemDefault`, `tkIconPanel_PaintItemDefault`; a StatusBar's one panel: `tkStatusBar_PaintPanelDefault`; a ColorPicker's popup: `tkColorPicker_RenderInfo`); call its
`PaintDefault( p )` (`tkButton_PaintDefault` and the rest) first to draw the stock one and add to it. A Panel's **Paint**
handler draws over its background and border, under its children, so there is nothing to call first.
A ScrollPanel's **Layout** handler runs on every layout pass with the page's width (`cxPanel`): place
the children against it and set `ContentHeight` to the height they take (0 keeps the one set).

A ListTree draws no row by itself: with no **Paint** handler the form gives it the stock row painter
(`tkListTree_PaintRowDefault`), and a Paint handler can call that and add to it. Its header shows
only with **ShowHeader** on; **HeaderPaint** draws a column heading (`tkColumnHeader_PaintColumnDefault`
for the stock one). **CanDrop**, **BeginLabelEdit** and **EndLabelEdit** answer through `Allow` or
`Accept`, which start true, and editing a cell needs **LabelEdit** on. **ColumnAutoSize** answers the
width a double-clicked divider should take (`BestWidth`; 0 leaves it).

A Calendar's **Paint**, **DayPaint** and **MonthYearPaint** handlers draw the whole control, a day,
or a month or year cell (`tkCalendar_PaintDefault`, `PaintDayDefault`, `PaintMonthYearDefault` draw
the stock ones), and its **Tooltip** handler sets `t->outText` for the day under the pointer.

A CodeEdit's **Change** fires for every insert or delete, by the user or by code; **DirtyChanged**
follows the save point (`tkCodeEdit_Send( ed.Handle, SCI_SETSAVEPOINT )` after loading or saving),
and **Notify** gets every Scintilla notification raw. A **ContextMenu** handler replaces the
editor's own right-click menu.

A DatePicker needs a **Parse** handler before anyone can type a date: without one, typed text is
never accepted. `Accepted = tkDatePicker_ParseIso( sText, pDate )` takes ISO dates; **Format** sets
`sOut` (`tkDatePicker_FormatIso` is the default). Its **Tooltip** handler sets `t->outText` for the
day under the pointer (`Show` starts true), and **DayPaint** draws a calendar day, with
`tkDatePicker_PaintDayDefault( d )` for the stock cell.

Your file and the generated one are the same module, joined by a [partial type](Partial). A file's own
`#import` and `using` lines apply only to it, so add those your code needs.

Handlers follow what you do on the form:

| You | The code |
|---|---|
| Rename a control | Its name and handlers are renamed, as one undo step |
| Delete a control whose handler is empty | The handler goes too |
| Delete a control whose handler has code | The code stays, and still compiles, until you delete it |
| Delete a handler's body by hand | Its event is unbound when you next save the form |

## Menus, toolbars and lists

Select a MenuBar, Toolbar, IconPanel, StatusBar, ListTree, ComboBox, SelectBar, TabBar or TabControl and press **Edit
items** in the Properties panel. A SelectBar's items are its panels, a TabBar's its tabs (each with a **Glyph**, as a TabControl's pages have) and a TabControl's its
pages, each with a caption and a **Glyph** drawn before it (the tab control's **GlyphSize** sizes them all); the **SelectedIndex** of each (like a ComboBox's) picks one of them once they're added. A TabControl's
tabs have no close X unless **Closable** is on; its **Close** handler is then told which tab, and closing it
(`tkTabControl_DeletePage`) is up to you.

A ProgressBar whose **TextMode** is Callback shows what its **Text** handler sets `Text` to; the handler
is told the position and the range. A Chart's **ValueLabel** handler formats a number for an axis, a pie
label or a tooltip (`nContext`: `CHT_FMT_AXIS`, `CHT_FMT_PIELABEL`, `CHT_FMT_TOOLTIP`); leaving `Text`
empty keeps the chart's own format. Menu items are indented to make drop-downs and submenus. A menu item can have a
shortcut such as `Primary+O`, and a handler. Set the text of a menu item to `-` for a separator.

A MenuBar dropped on a form opens this editor straight away, filled with a standard menu -- **File**
(New, Open, Save, Save As, Exit), **Edit** (Undo, Redo, Cut, Copy, Paste, Select All) and **Help**
(About), with the usual shortcuts. Change what you like; **Cancel** leaves the bar empty. A Toolbar
starts the same way, with New, Open, Save, a separator, Cut, Copy and Paste, each with a glyph and its
words. Every other control with **Edit items** opens its editor when dropped too: a TabBar on its Tab1,
a TabControl on its Page1, the rest empty. In the editor
the arrow buttons move the selected item up or down and out or in a level, **+** adds one and the bin
removes it. The pencil beside **Handler** closes the editor as **OK** does and shows that handler in
the code; an item with no handler is first given one: the control's name and its menu path -- MenuBar1's
**File** > **Save As...** is `MenuBar1_File_SaveAs` (a toolbar's or status bar's item, the control's name and
its text, `tbr_Go`).

A menu item's handler runs when it is chosen. The bar's own **Command** handler runs after it for
every item and is told which (`sub Form.OnCommand( byval id as long )`); **InitPopup** runs before a
drop-down opens (`byval idx as long, byval hPopup as TK_MENU ptr`), the moment to check or disable its
items.

An IconPanel's items are its icons: each has a **Kind** (toggle, command or separator), a **Glyph** and
a **Handler**, which runs when the icon is clicked. An icon has no caption; give it a tip from the
panel's **Tooltip** handler.

A StatusBar panel has a text, a width, a **Handler** and **Stretch**. The handler runs when the panel is
clicked and is told how many clicks (`sub Form.OnPanel( byval clicks as long )`, 2 for a double click).
**Stretch** gives that panel a share of the space the others leave; when several panels stretch they share
it evenly. It is saved per panel (`stretch = true`). A form from before this keeps its bar's `ExpandPanel`
property until the panels are next edited, when it becomes that panel's Stretch.

## Option buttons

Option buttons with the same parent and the same **GroupID** are one group: one of them is checked, the
arrow keys move through them and Tab stops at the group once. An option button you place takes the
GroupID of the last one placed on the same parent, so a column drawn one after another is one group;
give a new group its own GroupID on its first button.

## Components

A **Timer** is a component, not a control: the form has one, but it is never shown. On the surface it is
a small box with its name, on the form itself whatever you drop it on; you can move it, not resize,
anchor or dock it. Its **Interval** is in milliseconds (0, the default, means stopped), **Enabled** starts
and stops it, and its **Tick** handler (`sub Form.OnTick( )`) runs every Interval while it is enabled. A
Test Form leaves it out. See [tkTimer](tkTimer).

A **PopupMenu** is a right-click menu. Its **Edit items** are a menu's -- text, shortcut, handler, indented
for a submenu -- but the first level is the menu that opens, not a bar. Give a control (or the form)
that menu in its **ContextMenu** property: a right-click on it, or the Menu key or Shift+F10 when it has
the focus, opens the menu instead of whatever menu the control has itself, and anything inside it
opens it too. An item's handler runs when it is chosen; the menu's **Popup** handler runs just before
it opens and is told which control it opens for (`sub Form.OnPopup( byval hSource as TK_WIDGET ptr )`),
the moment to enable or check its items. See [tkContextMenu](tkContextMenu).

## Your own controls

The Toolbox's **Custom** row places a labelled stand-in. In the Properties panel, give it the name of
your type and the module it's in. Your type needs:

```freebasic
public type Gauge
    Handle as TK_WIDGET ptr
    declare sub Create( byval hParent as TK_WIDGET ptr, byval id as long )
end type
```

The module is imported as written, so a path like `../gauges` is relative to the form's folder. The type
can't have the same name as its module.

## Resources: images and fonts

A project keeps its images and fonts in one place, **Design > Resource Center...**, each under a name.
A property that takes a file (a Button's **ImageLeft** and **ImageRight**, a Picture's **File**, the
form's **Icon**) has a **...** button that opens the Center to pick one, and then holds `res:` and the
name, `res:logo`. The Theme Center's font files have the same button, for a font of your own.

- **+** adds files (several at once), copied into the project's `appResources/files/`, each named from
  its file name. The bin removes one, asking first when a form or the theme uses it.
- Rename one in its **Name** box, and every form and the theme that use it follow.
- **Build into the program** (on by default) puts the file inside the program. Off, the file is
  copied beside the program into `resources/` after each build, and read from there.
- **Application icon (Windows)**, on an image, makes it the program's icon: the exe's in Explorer and
  the taskbar, and the title-bar icon of every window whose form has no **Icon** of its own. One image
  at a time. The Center writes `appResources/app.ico` (16 to 256 pixels; an `.ico` is used as it is)
  and `appResources/app.rc`, and adds `resources = ["appResources/app.rc"]` to the `[target.<name>.windows]`
  table of `tiko.toml`; unticking it takes all three away again. Linux and macOS programs have no icon
  in the file, so the setting doesn't change them.

The Center writes `appResources/appResources.tkres`, and from it `appResources.design.tiko`, whose
`Register` names every resource before `tkApp_Init`. A typed path still works where a `res:` name
does.

## Using a form

```freebasic
#import "vendor/tkControls/tkApp"
#import "./appResources"
#import "./appTheme"
#import "./frmMain"
using tkApp

dim as TKAPP_OPTIONS options
appResources.Register( )                ' the project's images and fonts, by name
appTheme.ApplyOptions( options )        ' the theme's fonts, read by tkApp_Init
if tkApp_Init( options ) = false then end 1
appTheme.Install( )                     ' the theme's colours, shape and styles
dim as frmMain.Form mainForm
mainForm.Build( )
end tkApp_Run( mainForm.Handle )
```

`Build` makes the window, hidden. A second form can be shown beside the first with `Show`, or as a dialog
with `ShowModal`, after which its controls can still be read. Both build the form first when it has no
window, the first time or after the user closed it, so another form's handler needs only this:

```freebasic
#import "../frmOther"
dim shared as frmOther.Form other

sub Form.btnOther_Click( )
    other.Show( Handle )              ' owned by this form; its controls are other.txtName and so on
end sub
```

[tkForms](tkForms) has the details.

## Colours and themes

A project's look lives in `appTheme/appTheme.tktheme`: **Design > Project Theme...** picks or edits it,
and each control's **Colors** row gives it a style or its own colours. The
[Themes Tutorial](Themes-Tutorial) walks through it step by step.

## The form's own properties and events

Click the empty form and the Properties panel shows the window's settings. **StartPosition** is where
it first appears (Default, CenterScreen, CenterOwner), **WindowState** how (Normal, Maximized,
Minimized; a maximized window must be resizable), **Resizable** blank for the default (a top-level
form resizes, an owned one doesn't), true or false. **MinWidth**, **MinHeight**, **MaxWidth** and
**MaxHeight** limit the client the user can size it to, in design units; blank is no limit.
**AlwaysOnTop** keeps it above other windows, and **Icon** is an image for its title bar (its **...**
picks one from the Resource Center). On Windows the taskbar and Alt+Tab keep showing the program's
**Application icon**; only a program without one shows the form's Icon there.

Its events:

| Event | Handler | When |
|---|---|---|
| Load | `( )` | At the end of `Build`, the controls made |
| Close | `( byref Cancel as boolean )` | The close button or `Close`; set `Cancel` to keep the form open |
| Resize | `( byval cx as long, byval cy as long )` | After every resize and the first show, the layout applied; pixels |
| KeyDown | `( byval keyCode as long, byval mods as long, byref Handled as boolean )` | A key no control claimed; set `Handled` to consume it |
| Paint | `( byval pPaint as TK_PAINT ptr )` | The form's background, under its controls |
| Destroy | `( )` | The window is going, its controls still there |
| ThemeChanged | `( )` | The application's theme changed |
| MouseMove | `( byval x as long, byval y as long, byval buttons as long, byval mods as long )` | The mouse moved over the form, or over a control with no MouseMove of its own; pixels from the client's top-left |

Every control (not a Timer or a PopupMenu) has a **MouseMove** event too, with the same handler, `x`
and `y` from the control's own top-left. A move goes to the nearest of the control under the mouse
and its containers that has a MouseMove handler, so a form's handler follows the mouse across the whole
form unless a control handles it itself. `buttons` is SDL's mouse-button mask (`SDL_BUTTON_LMASK` and
so on), `mods` the modifier keys, as KeyDown's.

## Other languages

Tick **Translatable** on the form and its captions go through `tkForms_Tr`, with keys like
`frmMain.btnOK.Text`. Install your lookup with `tkForms_SetTranslator` before `Build`.

## The files

A `.tkform` is TOML, one table per control, in stacking order. It's meant to diff well: one form has one
spelling, and values that are the default aren't written.

`tkEdit --generate-forms DIR` writes the generated file of every form below a folder. `tkEdit --check-forms DIR`
lists any that are stale and exits with the count, which suits a build check.

## See also

- [tkForms](tkForms): the form base
- [tkLayout](tkLayout): anchors and docks
- [Themes Tutorial](Themes-Tutorial): themes, styles and colours, in tkEdit and in code
- [tkControls](Category-tkControls): every control
- [partial type](Partial)
- [Contacts Tutorial](Contacts-Tutorial): an address book built step by step, finished in the
  toolchain's `examples/tkControls/tkContacts`
