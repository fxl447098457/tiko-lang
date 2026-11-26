[Home](Home) › [All Categories](Categories) › **tiko build**

# tiko build

`tiko build`, `tiko run`, `tiko check`, `tiko clean` and `tiko metadata` build a project the way an editor, a terminal and a CI job all can: from a `tiko.toml`, with every compiled file cached, the misses compiled in parallel, and a line-per-event JSON stream for tools. They are subcommands of the one `tiko` executable. Everything else on a `tiko` command line is the compiler driver: `tiko main.tiko util.tiko -o app.exe` compiles every file every time.

The book's [Building and Shipping](https://tiko-lang.net/book/ch31-building-shipping.html) chapter teaches this with a worked project; this page is the reference, and its [JSON stream](#the-json-event-stream) and [metadata](#tiko-metadata) sections are the contract editors code against.

## The commands

| Command | Does |
|---|---|
| `tiko build [targets]` | builds the named targets of `tiko.toml`, or all of them, into `out/<profile>/` |
| `tiko run [target] [-- args]` | builds one `exe` target, then runs it -- its first `copy_to` copy when it has one -- with the arguments after `--`; exits with the program's exit code |
| `tiko check [targets]` | every error and warning a build would give, through lowering; writes nothing |
| `tiko clean [targets]` | removes what a `tiko build` with the same profile would write |
| `tiko metadata` | prints the project as one JSON object: targets, profiles, modules, search paths; compiles nothing |
| `tiko test [dirs]` | builds the project's tests into one program and runs them -- see [tiko test](Category-Tiko-Test) |
| `tiko doc [dirs]` | writes the API documentation of the project's modules into `out/doc/` -- see [tiko doc](Category-Tiko-Doc) |

```
tiko build    [<target>...] [--profile <p>] [-j <n>] [--options "<flags>"] [--manifest <path>]
tiko run      [<target>] [build options] [-- <program arguments>]
tiko check    [<target>...] [build options]
tiko clean    [<target>...] [--profile <p>] [--manifest <path>]
tiko metadata [--manifest <path>] [--format json] [-target <t>] [--options "<flags>"]
tiko test     [<dirs> | <x_test.tiko>...] [--timeout <s>] [--filter <text>] [--no-run] [build options] [-- <args>]
tiko doc      [<dirs>...] [-o <dir>] [--manifest <path>] [-target <t>]
```

The subcommand must be the first word. A later `build` is a file name.

### Options

| Option | Means |
|---|---|
| `--profile <p>` | the [profile](#profiles); `debug` when a manifest is in force |
| `--manifest <path>` | `tiko.toml`, or the directory holding it. Without it, the nearest `tiko.toml` at or above the current directory, if any |
| `--options "<flags>"` | compiler flags appended to every file of the build, relative to the current directory; they enter every cache key |
| `-target <t>` | `windows-x86_64`, `linux-x86_64`, `linux-arm64` or `macos-arm64`; the host's by default |
| `-j <n>` | how many files compile at once; `TIKO_JOBS` for this build and the processes it starts |
| `--no-cache` | nothing read from or written to the cache, modules or main files |
| `--message-format json` | the [event stream](#the-json-event-stream) on standard output; `text`, the default, is the console rendering |
| `--diagnostics-file <path>` | every diagnostic as tab-separated records too ([below](#diagnostics)) |
| `--format json` | `tiko metadata`'s one format |
| `-o <path>`, `-x <path>` | the output of a build with no manifest |
| `-v` | each cache hit and miss, with the reason, and every tool command; not with `--message-format json` |
| `--color=always\|never\|auto` | the console's colour, as for the driver |
| `--` | ends tiko's arguments; the rest go to the program. `tiko run` and `tiko test` only (`TKO0154` elsewhere) |
| `--timeout <s>`, `--filter <text>`, `--no-run` | `tiko test`'s: see [tiko test](Category-Tiko-Test#running-tests) |

A word is a **target** when a manifest is in force and the word has no `.`, `/` or `\`; otherwise it is a **file**. A target the manifest does not declare is `TKO0160`.

### Without a manifest

`tiko build a.tiko b.tiko` builds one implicit target from the files given, named after the first, with the compiler driver's output (`a.exe`) unless `-o` names another. It gets the cache, the parallel compile and the link check below; no profile applies unless `--profile` names one. `tiko run a.tiko` and `tiko check a.tiko` work the same way.

## The manifest

`tiko.toml` is the [package manifest](https://tiko-lang.net/book/ch15-modules-packages.html) with tables for building. **Every path in it is relative to `tiko.toml`**, including the value of every option in `options` that takes a directory, a file or a path (`-i`, `-p`, `--pkg-dir=`, `-o`) and every file named there. The command line's `--options` stay relative to where they were typed.

```toml
[package]
name = "notepad"

[dependencies]
ui = { path = "../ui" }

[defines]                      # the package's modules see these
LOG_MIN_LEVEL = "2"

[target.notepad]
main      = "src/main.tiko"
sources   = ["src/files.tiko", "src/find.tiko"]
resources = ["res/notepad.rc"]
subsystem = "gui"
libs      = ["comctl32"]
options   = ["-w", "all"]

[target.notepad.defines]       # this target's -d
EDITION = "2"

[profile.fast]
inherits = "release"
options  = ["-mt"]
```

**`[vendor.<module>]`** belongs to the package rather than to a build: `links` names the link modes a C library module ships, and `runtime` the files a module needs beside the program at run time -- fonts, a library it loads itself -- relative to the module's directory, copied beside every program that imports the module and, with it, into each `copy_to` directory. See [Vendor Packages](Vendor-Packages#files-a-module-needs-at-run-time).

### `[target.<name>]`

| Key | Type | Means |
|---|---|---|
| `main` | string | the main file: the first root, which owns the program's top-level code. Required |
| `sources` | array | more roots, compiled with it as though named after it |
| `kind` | string | `"exe"` (default), `"dll"` or `"lib"`: `-dll`, `-lib` |
| `options` | array | further compiler flags. A `-dll` or `-lib` among them decides the kind |
| `libs` | array | libraries to link: `-l` |
| `libpaths` | array | where to look: `-p` |
| `resources` | array | `.rc` files |
| `subsystem` | string | `"gui"` or `"console"`: `-s` |
| `output` | string | the artefact's path, instead of `out/<profile>/<file>` |
| `copy_to` | array | directories the artefact is copied into after each build that succeeds |

A `-x` in `options` names the artefact as `-x` does ([Compiler Option: -x](Compiler-Option-X)), relative to `tiko.toml`, and wins over `output`.

**`copy_to`** puts the program beside the DLLs and data files it needs. After a build that succeeds, the artefact is copied into each directory, which is made when missing; `out/<profile>/` keeps the original, which the link check reads. A copy that is already there with the same size and no older is left alone, so an unchanged build writes nothing. A DLL is copied alone, without its import library. A program that imports a [vendor package](Vendor-Packages) with `link dynamic` takes that package's DLL or `.so` with it: the link step puts the library beside the artefact, and each `copy_to` directory gets it too. `tiko clean` removes the copies of the artefact, and nothing else in those directories. A copy that cannot be written is `TKO0171`, exit 5.

```toml
[target.app]
main    = "src/main.tiko"
copy_to = ["dist"]       # dist/ holds app.ini and sqlite3.dll
```

`[target.<name>.defines]` holds `NAME = "value"` pairs, each a `-d NAME=value` for that target's files.

**`[target.<name>.windows]`, `[target.<name>.linux]` and `[target.<name>.macos]`** hold what is true of one platform only. They take `sources`, `resources`, `libs`, `libpaths` and `options`, which add to the target's own when the build is for that platform (the host's, or `-target`'s) and are not read otherwise. A `.rc` file belongs in the `windows` table: a build for Linux or macOS refuses one (`TKO0108`), so the same `tiko.toml` builds everywhere.

```toml
[target.app]
main = "src/main.tiko"

[target.app.windows]
resources = ["res/app.rc"]   # the program's icon
libs      = ["comctl32"]

[target.app.linux]
options = ["-d", "USE_GTK=1"]
```

A module directory is never a root: modules are reached through `#import` (`TKO0161`). Two targets writing one file is `TKO0165`.

Targets build in the order the manifest declares them, so a `lib` that another target links goes first.

### Profiles

A profile is a named set of compiler options, and part of every cache key.

| Profile | Options |
|---|---|
| `debug` | `-g -exx -O0`, the default |
| `release` | `-O2` |
| `asan` | `-g -exx -O1 -fsanitize=address`: [AddressSanitizer](Compiler-Option-Fsanitize) on top of the debug checks |

`[profile.<name>]` changes a built-in or declares another:

| Key | Type | Means |
|---|---|---|
| `inherits` | string | the profile this one starts from; a cycle is `TKO0164` |
| `opt` | integer | `0` to `3`: `-O` |
| `errors` | string | `"e"`, `"ex"`, `"exx"` or `""` for none |
| `debug` | boolean | whether `-g` is given |
| `options` | array | further flags, after the above |

An unknown profile is `TKO0163`. Each profile writes to its own `out/<profile>/`, so a debug and a release build of one project sit side by side.

## What is not done twice

- **Main files are cached** in the module cache (`TIKO_MODCACHE`, else the user's cache directory), keyed by the compiler, the options, the file and everything it read: includes, and the interfaces of the modules it imports. A change inside a module's procedures recompiles the module, not its importers.
- **Not cached**: a file with an error or a warning (a cached object would not report it again), one that expands `__DATE__`, `__DATE_ISO__` or `__TIME__`, and one whose `#cmdline` restarted the compile. `-v` says why (`TKO0169`).
- **Misses compile in parallel** when there are two or more: one quiet child `tiko` per file, `-j` at once. A child that crashes is `TKO0167`, exit 6.
- **The link is skipped** when nothing it reads has changed. A record in the module cache (`links/` under the cache directory) holds the compiler, the options, and the size and time of every object and library, and of the artefact itself; deleting or touching the artefact relinks. Like a cache entry, a record unused for seven days is removed, and `tiko --clean-module-cache` removes them all.
- **One build per target at a time.** A second `tiko build` of a target whose build is running fails with `TKO0166` instead of writing over it.
- **`tiko check`** reads the cache and writes nothing: a file the last build compiled cleanly is not compiled again, and every other is run through lowering.

## Diagnostics

Diagnostics are written to standard error as the console rendering, `file(line,col): error TKOnnnn: message` and a caret snippet, in text and in JSON mode alike. A tool that wants them as data passes `--diagnostics-file <path>`: when the run ends, the file holds one record per diagnostic, a TAB between fields and LF after each line, UTF-8:

```
tiko-diagnostics	1
<kind>	<id>	<file>	<line>	<col>	<endLine>	<endCol>	<message>
related	<id>	<file>	<line>	<col>	<endLine>	<endCol>	<message>
end	<errors>	<warnings>	<exitcode>
```

`kind` is `error`, `warning`, `note` or `remark`, after `-Werror` and `-Wno-`. Paths are absolute and physical; columns count characters from 1; the end is exclusive. A file with no `end` record means the compiler did not finish. Readers ignore kinds they do not know and fields past the eighth, and a version above the one they support. `tiko build` merges every child's records into the one file.

## The JSON event stream

`--message-format json` writes one JSON object per line to standard output, each line ending in LF on every host. **This is a contract**: format `1`.

```json
{"event":"build-start","format":1,"target":"greeter","profile":"debug","roots":["main.tiko"]}
{"event":"plan","units":2}
{"event":"unit","kind":"module","unit":"greeter.text","status":"miss"}
{"event":"unit","kind":"root","unit":"main.tiko","status":"miss"}
{"event":"artifact","kind":"exe","path":"out/debug/greeter.exe"}
{"event":"build-end","target":"greeter","errors":0,"warnings":0,"exit":0,"ms":605}
```

| Event | Fields | When |
|---|---|---|
| `build-start` | `format`, `target`, `profile` (`""` when none), `roots` | each target, before anything is compiled |
| `plan` | `units` | the number of files and modules this build will report |
| `unit` | `kind` (`module`, `root`), `unit` (a module chain or a file), `status` | each, in build order |
| `runtime-lib` | `path` | a library the program loads at run time -- a [vendor package](Vendor-Packages)'s DLL or `.so` -- now beside the artefact; `copy_to` copies it too |
| `artifact` | `kind` (`exe`, `dll`, `lib`), `path` | a file the build wrote |
| `build-end` | `target`, `errors`, `warnings`, `exit`, `ms` | each target, last. With no `target` when the command failed before any target was built |
| `run` | `path` (absolute: the first `copy_to` copy, else the artefact), `args` | `tiko run`, before the program starts. Until `run-end`, standard output is the program's own |
| `run-end` | `exit` | the program's exit code |
| `copy` | `target`, `from`, `path`, `copied` (true/false) | each `copy_to` directory, after a build that succeeded; `copied` is false when the copy there was already current |
| `clean` | `target`, `path`, `removed` (true/false) | `tiko clean`: the artefact, then each `copy_to` copy |
| `test-plan`, `test-start`, `test-fail`, `test-end`, `test-summary` | see [tiko test](Category-Tiko-Test#the-json-event-stream) | `tiko test`, after the build of the test program |
| `doc`, `doc-end` | `dir`, `exit`; `modules`, `path`, `exit` | `tiko doc`: each module, then the whole ([tiko doc](Category-Tiko-Doc#docjson)) |

| `status` | Means |
|---|---|
| `hit` | taken from the cache |
| `miss` | compiled |
| `compiled` | compiled, with no cache entry possible: `--no-cache`, or a `#cmdline` restart |
| `checked` | `tiko check`: run through lowering, not in the cache |

**Reader rules.** Read a line at a time; ignore events and fields you do not know. A new event or field does not change `format`; any other change does, and a reader that sees a higher `format` than it supports should fall back to the exit code. Paths are as the build was given them: relative to the current directory, `/`-separated where the manifest wrote them so. Diagnostics are not events: see [Diagnostics](#diagnostics). `-v` prints tool commands to standard output, so it cannot be combined with JSON mode (`TKO0154`).

## tiko metadata

`tiko metadata --format json` prints the project, resolved, as one JSON object and compiles nothing. An editor's build menu, a language server and a CI script read it instead of parsing `tiko.toml`.

```json
{"format":1,
 "package":{"name":"greeter","manifest":"tiko.toml","root":"."},
 "profiles":[{"name":"debug","flags":["-g","-exx","-O0"]},{"name":"release","flags":["-O2"]},
             {"name":"asan","flags":["-g","-exx","-O1","-fsanitize=address"]}],
 "targets":[{"name":"greeter","kind":"exe","implicit":false,"main":"main.tiko",
             "roots":["main.tiko"],"resources":[],"defines":["TIMES=2"],
             "flags":["-g","-exx","-O0"],
             "outputs":{"debug":"out/debug/greeter.exe","release":"out/release/greeter.exe",
                        "asan":"out/asan/greeter.exe"}}],
 "modules":[{"chain":"greeter.text","package":"greeter","dir":"text",
             "files":["text/text.tiko"],"imports":[]}],
 "searchPaths":{"roots":[],"pkg":"C:/tiko/pkg"},
 "units":[{"target":"greeter","root":"main.tiko","defines":["TIMES=2"],
           "includes":["C:\\tiko\\inc"]}]}
```

(Printed on one line; wrapped here, and the toolchain's paths shortened.)

| Field | Holds |
|---|---|
| `package` | the package's name, manifest and directory; `null` without a manifest |
| `profiles` | every profile and the flags it stands for |
| `targets` | each target: kind, `main`, roots, resources, defines, the flags of the profile in force, `copyTo`, and its output under every profile. `implicit` is true for the target of a build with no manifest |
| `modules` | every module the roots import, directly or not: its chain, package, directory, files and the chains it imports |
| `searchPaths` | the `-i` roots imports are searched in, and the toolchain's `pkg` |
| `units` | each root: its target, its `-d` defines and its include directories, the `compile_commands.json` of a tiko project |

Paths are relative to the current directory, as for the build; run it in the manifest's directory (`--manifest .`) to have them relative to `tiko.toml`. **When the module graph has an error** — an import of nothing, a module directory with no source — `tiko metadata` still prints everything it knows, including every module that did resolve, and exits 1 with the diagnostics on standard error.

## Exit codes

| Code | Means |
|---|---|
| 0 | success |
| 1 | the code has errors |
| 2 | the command line or `tiko.toml` is wrong (`TKO0144`, `TKO0160`–`TKO0165`, …) |
| 3 | no usable toolchain |
| 4 | an internal compiler error |
| 5 | a tool failed: clang, the linker, or `tiko run` could not start the program; or a `copy_to` copy failed (`TKO0171`) |
| 6 | a child compile crashed (`TKO0167`) |

`tiko run` exits with the program's code once the build succeeds. `tiko test` exits 1 when a test failed, crashed or timed out ([tiko test](Category-Tiko-Test#running-tests)).

## Editors

**VS Code**: `.vscode/tasks.json`. The problem matcher reads the console rendering; `--color=never` keeps escape codes out of it, since a task runs in a terminal.

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "tiko build",
      "type": "process",
      "command": "tiko",
      "args": ["build", "--color=never"],
      "options": { "cwd": "${workspaceFolder}" },
      "group": { "kind": "build", "isDefault": true },
      "problemMatcher": {
        "owner": "tiko",
        "fileLocation": ["autoDetect", "${workspaceFolder}"],
        "pattern": {
          "regexp": "^(.*)\\((\\d+),(\\d+)\\): (error|warning|note) (TKO\\d+): (.*)$",
          "file": 1, "line": 2, "column": 3, "severity": 4, "code": 5, "message": 6
        }
      }
    },
    {
      "label": "tiko run",
      "type": "process",
      "command": "tiko",
      "args": ["run", "--color=never"],
      "options": { "cwd": "${workspaceFolder}" },
      "problemMatcher": []
    }
  ]
}
```

Copy the matcher into a `tiko check` task to get the same list without building.

**Zed**: `.zed/tasks.json`; each task runs in Zed's terminal, from the command palette's `task: spawn`.

```json
[
  { "label": "tiko build", "command": "tiko", "args": ["build"], "cwd": "$ZED_WORKTREE_ROOT" },
  { "label": "tiko run",   "command": "tiko", "args": ["run"],   "cwd": "$ZED_WORKTREE_ROOT" },
  { "label": "tiko check", "command": "tiko", "args": ["check"], "cwd": "$ZED_WORKTREE_ROOT" }
]
```

**Sublime Text**: `tiko.sublime-build` in the `User` package. `file_regex` makes F4 step through the diagnostics.

```json
{
  "cmd": ["tiko", "build", "--color=never"],
  "working_dir": "$folder",
  "file_regex": "^(.+)\\((\\d+),(\\d+)\\): (?:error|warning|note) (.*)$",
  "selector": "source.tiko",
  "variants": [
    { "name": "Run",     "cmd": ["tiko", "run", "--color=never"] },
    { "name": "Check",   "cmd": ["tiko", "check", "--color=never"] },
    { "name": "Release", "cmd": ["tiko", "build", "--profile", "release", "--color=never"] }
  ]
}
```

The [tiko language server](https://github.com/PaulSquires/tiko-lsp), given `initializationOptions.compilerPath`, runs `tiko metadata` to learn where a project's imports resolve and answers `tiko/metadata` with its targets. It also runs `tiko --print-cincludes` on each file that has a `#cinclude`, and indexes the bindings it names (see [C Header Import](Category-C-Header-Import)).

## Diagnostics of these commands

| Id | Message |
|---|---|
| `TKO0144` | malformed tiko.toml: … |
| `TKO0154` | '…' cannot be used with '…' |
| `TKO0160` | no target named '…' (targets: …) |
| `TKO0161` | target '…': '…' is a module directory; modules are reached through #import, not listed |
| `TKO0162` | target '…': '…' not found |
| `TKO0163` | no profile named '…' (profiles: …) |
| `TKO0164` | profile '…' inherits itself: … |
| `TKO0165` | targets '…' and '…' write the same output '…' |
| `TKO0166` | another build of '…' is running (it holds …) |
| `TKO0167` | compiling '…' crashed with exit code … |
| `TKO0168` | 'tiko run' needs an exe target; '…' is a … |
| `TKO0169` | note: '…' is not cached: … (`-v` only) |
| `TKO0170` | 'tiko run' runs one target; name one of: … |
| `TKO0171` | could not copy '…' to '…' |

---

[Home](Home) · [Keyword Index](Keyword-Index)
