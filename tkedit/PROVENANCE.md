# Provenance

tkEdit copies and trims tiko-studio's GUI-free modules (PLAN.md D7) instead of depending on them.
Every copied file is listed here with its source, so a fix in either editor can be carried across
by hand. Source commit for everything below: **tiko-studio `2c83fca`** (2026-10-26).

Common edits to every copied file: package prefixes `tsp/ tsc/ tss/ tsa/` → `tkp/ tkc/ tks/ tka/`,
the name `tiko-studio` → `tkEdit` (incl. `platform.APP_NAME` and the run-script names).

| tkEdit | From tiko-studio | Changes beyond the common ones |
| --- | --- | --- |
| `src/platform/platform` | `src/platform/platform` | — |
| `src/core/appinfo` | `src/core/appinfo` | — |
| `src/core/autoinsert` | `src/core/autoinsert` | — |
| `src/core/build` | `src/core/build` | — |
| `src/core/docencoding` | `src/core/docencoding` | — |
| `src/core/fuzzy` | `src/core/fuzzy` | — |
| `src/core/mru` | `src/core/mru` | — |
| `src/core/navhistory` | `src/core/navhistory` | — |
| `src/core/outline` | `src/core/outline` | — |
| `src/core/symboldb` | `src/core/symboldb` | `Definitions`, `Procedures`, `QualifiedName`, `HasFile` added (tkEdit's F4 / Ctrl+P lists) |
| `src/core/text` | `src/core/text` | — |
| `src/core/textsearch` | `src/core/textsearch` | — |
| `src/core/textstream` | `src/core/textstream` | — |
| `src/core/tomlget` | `src/core/tomlget` | — |
| `src/core/keybind` | `src/core/keybind` | importer of the old keybindings.ini dropped; `ToToml` writes every command at its chord in force, none commented, as literal strings |
| `src/core/cmdids` | — | new: tkEdit's 83 commands (shape of tiko-studio's `CommandTable`, no OldName, `MenuGroup`, `SepBefore`, `InGroup`) |
| `src/core/settings` | — | new, trimmed schema; `Template`/`EnsureFile` |
| `src/core/themes` | — | new: TOML themes (not tiko-studio's `.theme`) |
| `src/core/tests/{tally,fuzzysuite,textsuite,buildsuite,mrusuite,navsuite,encsuite}` | same | — |
| `src/core/tests/outlinesuite` | same | `ProjectRun` (tsc/projects) dropped |
| `src/core/tests/intelsuite` | `src/core/tests/p8suite` | renamed |
| `src/core/tests/keybindsuite` | same | vocabulary and chord checks kept; map and TOML checks rewritten for tkEdit's table; importer checks dropped |
| `src/core/tests/coreall.tiko` | same | only the suites above; tkEdit's names |
| `src/svc/parser` | `src/svc/parser` | — |
| `src/svc/runner` | `src/svc/runner` | — |
| `src/app/editor` | `src/app/editor` | `ViewLook` (settings + .theme) replaced by a resolved `Look`/`Style` and `DefaultLook`; breakpoints, debug line, `KeywordFore`, `DefaultBackColor` removed (no debugger, D6); whitespace/wrap applied from the look; `Indent`/`Unindent`/`NewLineBelow` added; Scintilla's own letter chords (Ctrl+D, Ctrl+L, Ctrl+U ...) cleared; `FindOptions` range (`InSelection`), `SetSelection`/`SelectionStart`/`SelectionEnd`, `FoldLineAt` |
| `src/app/documents` | `src/app/documents` | `SplitMode` / `Split` dropped (the panes own the split); `Other` is the buffer's view in pane 2 |
| `src/app/findstrip` | `src/app/findbar` | rows of the status line's height in its place, labels, a `Sel` toggle, a Go to Line mode, Ctrl+Alt+Enter, Enter's text swallowed |
| `src/app/popuplist` | — | new: the one chooser popup (query box + tkListTree, fuzzy filter, Ctrl-release accept) |
| `src/core/session` | `src/core/projstate` (shape) | new: session.toml / a project's session file, `StoredPath`/`FullPath` from projstate |
| `src/core/tests/sessionsuite` | — | new |
| `src/core/project` | — | new: reads the project's tiko.toml, the per-project options file; `SplitArgs` from tiko-studio's `tsc/manifest` |
| `src/core/tests/projectsuite` | — | new |
| `src/core/tests/fmtsuite` | `src/core/tests/fmtsuite` | — |
| `src/core/tests/keysdoc.tiko` | — | new: KEYS.md from the command table |
| `src/app/outputpane` | `src/app/outputpane` | Results, Log and Search only |
| `src/app/chrome` | `src/app/chrome` | rewritten for TOML themes: `PaletteOf`, `LookOf` |
| `src/app/mainwin/mainwin.tiko` | — | new; `AppOptions`, `WordsOf`/`LoadKeywords`, `AskPerson`/`PickPerson`, the buffer flow (`FindOpen`, `SaveDoc`, `CloseDoc`, `CheckDisk`) and the build flow (`StartBuild`, `PollBuild`, `FinishBuild`, `ShowDiagnostics`, `OpenDiagnostic`, `RunProgram`, `LaunchProgram`) and code intelligence (`StartScanner`, `QueueScan`, `PollScans`, `GoToDefinition`, `GoHistory`, `GoFunction`, the `OnCharAdded` codetips, `SplitQualified`, `SortNames`, `PkgDir`) after tiko-studio's `mainwin` |
| `tools/test-win.sh`, `tools/test-linux.sh`, `tools/idiom.sh` | `tools/` | tkEdit's paths, exe and build folder (`$HOME/tebuild`); tikoParser copied only when present |
| `fonts/` | `fonts/` | README points at `mainwin.AppOptions` |
| `keywords/tiko.txt`, `keywords/extra.txt` | `settings/keywords/freebasic_keywords.txt`, `extra_keywords.txt` | renamed |
| `keywords/codetips.txt` | **tiko-editor-tiko `33172d82`** `settings/keywords/codetips.ini` | renamed, LF line ends; read by `symboldb.Intrinsics` (the old `LoadCodetipsFB` / `FindIntrinsicCalltip`) |
| `.gitattributes`, `.gitignore` | same | — |
| `src/svc/dapjson` | **tiko-editor-tiko `effa02fb`** `src/debugparser/dapjson` | `'` comments, LF |
| `src/svc/dapclient` | **tiko-editor-tiko `effa02fb`** `src/debugparser/dapclient` | no `sys/win`: the job object by its own `extern`, Windows only; `Dap_Adopt` |
| `src/svc/dapengine` | **tiko-editor-tiko `effa02fb`** `src/debugparser/dapengine` + `dbgtypes` | cross-platform: Windows keeps CreateProcess+attach, Linux/macOS a terminal's tty + DAP `launch`; notes on a channel (no PostMessage); ELF/Mach-O(.dSYM) checks; user frame = a file that exists; SIGSTOP pause |
| `src/svc/tests/dbgtest.tiko` | **tiko-editor-tiko `effa02fb`** `src/debugparser/tests/dbgtest` | no window: polls `Engine_NextNote`; takes the source path |
| `src/core/debugview` | **tiko-editor-tiko `effa02fb`** `src/eda/frmDebug` (its pure functions) | GroupSpan/GroupBounds, SortLess + SortState, the value cache as `ValueMemory` (Maps), `ExpandMemory`, ExprFromLine (a number is no expression) |
| `src/core/tests/debugviewsuite` | **tiko-editor-tiko `effa02fb`** `frmDebug_RunSelfTest` (its pure checks) | — |
| `src/app/debugpane` | **tiko-editor-tiko `effa02fb`** `src/eda/frmDebug` | a tab, not a window: bottom tab strips (Locals/Globals/Watch, Call Stack/Breakpoints), a Breakpoints list, tkToolbar buttons; lazy trees, array groups, watch editing, sort, changed values, expansion across stops as frmDebug |
