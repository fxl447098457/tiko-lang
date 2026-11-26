[Home](Home) › [All Categories](Categories) › [C Header Import](Category-C-Header-Import) › **Vendor Packages**

# Vendor Packages

> **In tiko.** A C library the toolchain ships, reached with one `#import` and nothing on the command line: `#import "vendor/sqlite3" link dynamic`. Its header comes across whole and unqualified, its library is linked, and a dynamic library is copied beside the program so the program starts. Measured on windows-x86_64, linux-x86_64, linux-arm64 and macos-arm64.

## Syntax

```
#import "vendor/<library>" [as name] [public] [link static|dynamic]
```

## Description

```freebasic
#import "vendor/sqlite3" link dynamic

dim as sqlite3 ptr db
if sqlite3_open( ":memory:", @db ) <> SQLITE_OK then print "open failed"
dim as sqlite3_stmt ptr st
sqlite3_prepare_v2( db, "select ? || '!'", -1, @st, 0 )
sqlite3_bind_text( st, 1, "hi", -1, SQLITE_TRANSIENT )
if sqlite3_step( st ) = SQLITE_ROW then print *cast( zstring ptr, sqlite3_column_text( st, 0 ) )
sqlite3_finalize( st )
sqlite3_close( db )
```

```
hi!
```

Every routine, type and constant of the library's C header is callable as the library documents it: `sqlite3_open`, `SQLITE_OK`, not `sqlite3.sqlite3_open`. No `#cinclude`, no `#foreignlib`, no `-i`, `-l` or `-p`, and no Clang at your end: the header was translated once, by [`tiko c2t`](C2t), and ships translated.

`vendor/` is the toolchain's, as `std/` is. It is looked for in the toolchain's `pkg/` directory alone: a project directory, an `-i` directory, a `TIKO_PATH` entry or a dependency called `vendor` cannot stand in for it, and a project whose `tiko.toml` names itself `vendor` is `TKO0148`.

| Package | Library | Link modes |
| --- | --- | --- |
| `vendor/sqlite3` | SQLite 3.54.0 | `static`, `dynamic` (the default) |
| `vendor/SDL3` | SDL 3.4.14 (the binding is 3.4.4's) | `static`, `dynamic` (the default) |
| `vendor/SDL3/image` | SDL3_image 3.4.x, built from release-3.4.x past 3.4.8 for its ILBM fix (brings `vendor/SDL3`) | `static`, `dynamic` (the default) |
| `vendor/SDL3/ttf` | SDL3_ttf 3.2.2 with FreeType 2.15.0 and HarfBuzz 14.3.0 (brings `vendor/SDL3`) | `static`, `dynamic` (the default) |
| `vendor/SDL3/mixer` | SDL3_mixer 3.2.4 (brings `vendor/SDL3`) | `dynamic` (the default) |
| `vendor/raylib6` | raylib 6.2 | `static`, `dynamic` (the default) |
| `vendor/raylib6/raymath` | raylib's raymath (brings `vendor/raylib6`) | chosen on `vendor/raylib6` |
| `vendor/raylib6/rlgl` | raylib's rlgl (brings `vendor/raylib6`) | chosen on `vendor/raylib6` |
| `vendor/cJSON` | cJSON 1.7.19, built from master past it with four upstream security PRs applied | `static`, `dynamic` (the default) |
| `vendor/cJSON/utils` | cJSON_Utils: JSON Pointer, Patch, Merge Patch (brings `vendor/cJSON`) | chosen on `vendor/cJSON` |
| `vendor/pcre2` | PCRE2 10.49, the 8-bit library (UTF-8), with Unicode support and the JIT | `static`, `dynamic` (the default) |
| `vendor/zint` | libzint 2.16.0, the barcode library: its BSD-3 backend, built without PNG output | `static`, `dynamic` (the default) |

**`vendor/tkControls/<control>`** is tiko source, not a C library: owner-drawn controls on SDL3 for Windows, Linux and macOS, one module each. On macOS they run with Homebrew's SDL3. It links no library of its own (`vendor/SDL3` does) but has runtime files: its fonts, copied beside every program that imports it, and the scintk library for `tkCodeEdit`. `vendor/tkControls/tkCodeEdit` takes `link static`, which puts scintk inside the program. See [tkControls](Category-tkControls).

**The SDL packages on linux-x86_64 and linux-arm64 link the system's libraries.** SDL publishes no Linux binaries, so the toolchain ships none: a program is linked with `-lSDL3` (and `-lSDL3_image`, `-lSDL3_ttf`, `-lSDL3_mixer` for those packages) and loads `libSDL3.so.0` and the others from the system's library folders, like any library the distribution installs. Install the distribution's development packages (`libsdl3-dev`, `libsdl3-image-dev`, `libsdl3-ttf-dev`, `libsdl3-mixer-dev` on Debian and Ubuntu; `SDL3-devel` and the like on Fedora) to build; without one the link fails with `cannot find -lSDL3`. Nothing is copied beside the program. Ubuntu has `libsdl3-dev` from 24.04; on 22.04, build SDL3 from source.

**On macos-arm64 the SDL packages link Homebrew's** (`brew install sdl3 sdl3_image sdl3_ttf sdl3_mixer`), the same way: `-lSDL3`, found in `/opt/homebrew/lib`, which the link searches after your own paths. Nothing is copied beside the program.

**`vendor/raylib6` is not available on macos-arm64** yet. Importing it there stops with an `#error` that says so.

**The packages' shared libraries on linux-x86_64 need glibc 2.34 or newer**, `vendor/raylib6`'s included: the toolchain builds raylib's from its source rather than shipping raylib's prebuilt one, which needs 2.38. On linux-arm64 the toolchain itself needs glibc 2.35 or newer.

**`vendor/pcre2` is PCRE2's 8-bit library only**, so a pattern and a subject are bytes, or UTF-8 with `PCRE2_UTF`: assign a `ustring` to a `string` to get its UTF-8. Its names are the generic ones PCRE2 documents -- `pcre2_compile`, `pcre2_match`, `pcre2_match_data` -- each a `#define` of the `_8` name the library exports. A pattern or subject is a `PCRE2_SPTR`: `strptr( s )` of a `string` passes as one, a string literal does not. PCRE2 backtracks, so a pattern from outside the program can take exponential time: give `pcre2_match` a match context with `pcre2_set_match_limit` (and `pcre2_set_depth_limit`, `pcre2_set_heap_limit`). `pcre2_dfa_match` is no way out: it does not backtrack, but its time still grows steeply and the match limit does not stop it. See the [PCRE2 tutorial](PCRE2-Tutorial).

**`vendor/zint` is libzint alone** (zint's command line and GUI are GPL and not shipped): `ZBarcode_Create`, `ZBarcode_Encode_and_Buffer_Vector`, `ZBarcode_Delete` and the rest, as its manual has them. Data is bytes; with `UNICODE_MODE` a `string` holding UTF-8 (assign a `ustring` to one). Empty data is an error. `encoded_data` is bit-packed: module (row, col) is `( encoded_data(row, col shr 3) shr ( col and 7 ) ) and 1`. With `scale = 0.5` the vector's units are modules. `ZBarcode_Print` writes BMP, EMF, GIF, PCX, EPS, SVG and TIF files, not PNG. [tkBarcode](tkBarcode) is the control built on it.

**`vendor/SDL3` declares `SDL_main.h`'s routines but not its `main`**: `SDL_EnterAppMainCallbacks`, `SDL_RunApp` and `SDL_SetMainReady` (and on Windows `SDL_RegisterApp` and `SDL_UnregisterApp`), as C has them with `SDL_MAIN_HANDLED`. A program written with SDL's main callbacks calls `SDL_EnterAppMainCallbacks` itself; see the [SDL3 tutorial](SDL3-Tutorial).

`vendor/SDL3/image`, `vendor/SDL3/ttf` and `vendor/SDL3/mixer` -- modules inside `vendor/SDL3`, their libraries in its `lib/` -- each import `vendor/SDL3` publicly: one `#import` brings SDL's own names too, and links SDL3 as well.

### SDL linked in

`link static` puts SDL inside the program, on every target: the toolchain builds SDL3, SDL3_ttf and SDL3_image as archives itself. Each module's mode is its own, so a program that wants all of it inside writes `link static` on each:

```freebasic
#import "vendor/SDL3" link static
#import "vendor/SDL3/ttf" link static
#import "vendor/SDL3/image" link static
#import "vendor/tkControls/tkCodeEdit" link static     ' scintk too
```

The program then needs only what the operating system provides. SDL still loads the display libraries itself when it starts (X11 or Wayland and GL on Linux), as it does when linked dynamically.

| Target | What the link adds |
| --- | --- |
| windows-x86_64 | system libraries (`setupapi`, `winmm`, `imm32`, `version`, `ole32`, `oleaut32`, `shell32`, `uuid`, `advapi32`, `cfgmgr32`) and the static C and C++ runtime: Visual Studio's `libvcruntime.lib`, `oldnames.lib` and `libcpmt.lib` must be installed on the machine that links |
| linux-x86_64 | `libm`, `libdl`, `libpthread`, `librt`, and the system's `libstdc++` (HarfBuzz and scintk are C++) |
| macos-arm64 | the system frameworks SDL uses (Cocoa, Metal, IOKit and others), `libiconv` and `libc++` |

`vendor/SDL3/image` linked in decodes through its built-in codecs: PNG, JPEG, BMP, GIF, TGA and the other formats SDL_image carries itself; AVIF, JPEG XL, TIFF and WebP are not included. `vendor/SDL3/mixer` is dynamic only.

## `link static` and `link dynamic`

- **`link static`** links the library's archive into the program. Nothing else is needed at run time.
- **`link dynamic`** links the shared library (`sqlite3.dll`, `sqlite3_linux_x86_64.so`, `sqlite3_macos_arm64.dylib`) and **copies it beside the program**, under the name the program will load it by: a DLL's own name, an ELF library's soname (`libraylib.so.620`), and a macOS library's install name (`@rpath/sqlite3_macos_arm64.dylib`). A copy already there with the same size and no older is left alone, and one that was deleted is put back by the next build. [`tiko build`](Category-Tiko-Build)'s `copy_to` copies the library along with the program. `-nocopylibs` turns the copy off.
- **No `link`** leaves the choice to the package: each one names its default. `vendor/sqlite3`'s is dynamic.

One program links a library one way. Two imports asking for different modes are `TKO0157`, with a note at the other import; an import without `link` goes along with one that has it. A mode the package does not ship is `TKO0156`, and `link` on a package that ships no library -- any source-only package -- is `TKO0155`.

On linux-x86_64 and linux-arm64 a program that links a shared library from `#foreignlib` gets a run path of `$ORIGIN`, so the copy beside it is the one it finds. `LD_LIBRARY_PATH` still wins, and an `-rpath` the program passes with [`-Wl`](Compiler-Option-Wl) stands. `-norpath` turns it off. On macos-arm64 the same run path is `@loader_path`.

## Inside a vendor package

A vendor package is an ordinary module. `vendor/sqlite3` is one file:

```freebasic
#module "sqlite3"

public #include once "sqlite3.ti"
public #include once "sqlite3-residue.ti"

#ifdef TIKO_LINK_STATIC
    #foreignlib SQLITE static "lib/sqlite3"
#else
    #foreignlib SQLITE dynamic "lib/sqlite3"
#endif
```

- **`public #include`** carries a header with the module's interface, whole: an importer reads it as if it had included it itself, names and macros unqualified. Outside a module file it is `TKO0369`.
  It reaches the module's own importers, not theirs: a module of yours that imports `vendor/sqlite3` keeps SQLite's names to itself, unless it imports it with `public`, or its public declarations name the header's types (a field of type `sqlite3 ptr`), when they go along to the programs that import it.
- **`TIKO_LINK_STATIC`** or **`TIKO_LINK_DYNAMIC`** (each `1`) is defined in the module when an importer wrote `link`; with no `link` anywhere, neither is, and the module's `#else` decides. The mode is part of the module's cache entry, so changing it rebuilds the module.
- **`sqlite3.ti`** is the C header translated by `tiko c2t ... --shared-macro "SQLITE_API=__attribute__((dllimport))"`: a variable the library exports is written twice, `extern import` for a dynamic link on Windows and plain `extern` otherwise.
- **`sqlite3-residue.ti`** is written by hand: what the translation could not carry (`SQLITE_STATIC` and `SQLITE_TRANSIENT`, which are pointers), each with the reason.
- **`tiko.toml`** says what the package ships: `[vendor.sqlite3] links = ["static", "dynamic"]`, and what a module needs beside the program at run time: `runtime = [...]` (below).
- **`lib/`** holds the library files. They are not part of the source: `build/vendorfetch.sh` downloads them, or builds them from the library's source where no binary is published, each archive pinned by version and SHA-256, from the module's `fetch.toml`.

### Files a module needs at run time

Some modules need files that no link names: a font they draw with, a library they load themselves with `SDL_LoadObject` or `dylibload`. The package lists them in its `tiko.toml`, in the module's table:

```toml
[vendor.ui]
runtime = ["fonts/ui.ttf", "fonts/ui-mono.ttf", "lib/editcore"]
```

- Each entry is a path relative to the **module's** directory, as `#foreignlib "lib/x"` is. It may climb out of it with `..`; an absolute path is `TKO0144`.
- An entry whose file name has **no extension** is a shared library, spelled as the target spells one: `lib/editcore` is `lib/editcore.dll` for windows-x86_64, `lib/libeditcore.so` for linux-x86_64 and linux-arm64, and `lib/libeditcore.dylib` for macos-arm64.
- After a link that succeeds, each listed file of **each module the program imports** is copied into the output's directory, flat, under its own file name. A copy already there with the same size and no older is left alone. A module of the package that the program does not import brings nothing.
- A listed file that is not there is `TKO0176`, before anything is compiled: `module 'vendor.ui' needs 'lib/editcore' at run time, and there is no '.../pkg/vendor/ui/lib/libeditcore.so'`.
- A module the module cache supplies brings its files too: they are read from the manifest, not from the compile.
- [`tiko build`](Category-Tiko-Build)'s `copy_to` copies them along with the program, and `-nocopylibs` turns the copy off.
- A table may hold `links`, `runtime` or both, and any package's `tiko.toml` may have one, not only `vendor`'s: `[vendor.core]` in a package `widgets` is its module `widgets/core`, and `[vendor.widgets]` its root module.

### A header read in two places

A public header is read twice: once in the module, and again in every program that imports it. The program's macros can change what the header declares there. So the module records each macro the header's `#if`, `#ifdef` and `defined( )` lines looked at, as it was in the module, and the importer checks its own against them:

- the same in both, or undefined in both: nothing happens;
- defined in the module only -- its package's `[defines]`, its `TIKO_LINK_*` -- it is defined for the header and undefined again after it, so one package's link mode never reaches another's header;
- anything else is `TKO0370`, at the `#import`: `'unicode' is defined as '-1' here, but module 'vp.geo' read '.../geo.ti' with it undefined`.

## Options

| Option | Effect |
| --- | --- |
| `-nocopylibs` | do not copy a vendor package's dynamic library, or a module's runtime files, beside the output |
| `-norpath` | no `$ORIGIN` run path on a linux-x86_64 or linux-arm64 link, and no `@loader_path` one on a macos-arm64 link, that takes a shared library |

## Diagnostics

| Id | When |
| --- | --- |
| `TKO0148` | a package named `vendor` that is not the toolchain's |
| `TKO0155` | `link` on a package that ships no library |
| `TKO0156` | a link mode the package does not ship |
| `TKO0157` | two imports of one module with different link modes |
| `TKO0171` | the dynamic library, or a runtime file, could not be copied beside the output |
| `TKO0176` | a file a module's `runtime` lists is not there |
| `TKO0369` | `public #include` outside a module file |
| `TKO0370` | a macro a public header consulted differs between the module and the importer |

### See also

- [`tiko c2t`](C2t)
- [C Header Import](Category-C-Header-Import)
- [Foreign Library Linking](Category-Foreign-Library-Linking)
- [SQLite Tutorial](SQLite-Tutorial)
- [PCRE2 Tutorial](PCRE2-Tutorial)
- [tkControls](Category-tkControls)
