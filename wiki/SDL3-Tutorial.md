[Home](Home) › [Using C Libraries](Using-C-Libraries-Tutorial) › **SDL3**

# SDL3 Tutorial

> 📘 **Start with:** [Using C Libraries](Using-C-Libraries-Tutorial), the ideas these steps rely on.
>
> 📖 **In the book:** [Chapter 30, SDL3](https://tiko-lang.net/book/ch30-c-libraries.html#sdl3). `vendor/SDL3` (SDL 3.4.14) measured on Windows; your own build (step 6) measured with SDL 3.4.18, on Windows and Linux.

[SDL](https://libsdl.org), the *Simple DirectMedia Layer*, is the broadest of the common game libraries. It covers windows, a 2D renderer, a GPU interface, audio, gamepads, cameras, file dialogs, threads and timers, on desktop and mobile alike. SDL3 is its current version.

tiko ships SDL3 as a [vendor package](Vendor-Packages). One line gives a program all of SDL's API and links the library:

```freebasic
#import "vendor/SDL3"
```

There is no header to download, no include directory, no `#foreignlib` and nothing on the command line.

---

## 1. Get SDL

| Platform | What to do |
|---|---|
| **Windows** | Nothing. The toolchain ships `SDL3.dll` and copies it beside your program when it links. |
| **Linux** | Install your distribution's development package: `libsdl3-dev` on Debian and Ubuntu, `SDL3-devel` on Fedora. SDL publishes no Linux binary, so the toolchain ships none; the program links the system's `libSDL3`. |
| **macOS** | `brew install sdl3`. The program links Homebrew's, found in `/opt/homebrew/lib`. |

Write the module name as `SDL3`, in capitals. Windows also accepts `vendor/sdl3`, but Linux and macOS compare file names case-sensitively.

## 2. The program

SDL's example `renderer/01-clear` opens a window whose colour cycles smoothly. It is written with SDL3's **main callbacks**. Instead of writing the main loop yourself, you give SDL four functions:

| Callback | Called |
|---|---|
| `AppInit` | once, at the start |
| `AppEvent` | for every event: a key, the mouse, closing the window |
| `AppIterate` | once per frame |
| `AppQuit` | once, at the end |

SDL recommends this style because it works unchanged on platforms where a program cannot own its main loop, such as phones and the web. Here is the example in tiko:

```freebasic
'' SDL's example renderer/01-clear: a window whose colour cycles, built
'' on SDL3's main callbacks. A number on the command line stops it
'' after that many frames instead of when the window is closed.
#import "vendor/SDL3"

'' Everything the callbacks share, reached through SDL's appstate.
type AppState
    window as SDL_Window ptr
    renderer as SDL_Renderer ptr
    frames as int32
    maxFrames as int32
end type

function AppInit cdecl( byval appstate as any ptr ptr, _
        byval argc as int32, byval argv as zstring ptr ptr ) _
        as SDL_AppResult
    SDL_SetAppMetadata( "Example Renderer Clear", "1.0", _
        "com.example.renderer-clear" )
    if SDL_Init( SDL_INIT_VIDEO ) = false then
        print "Couldn't initialize SDL: "; *SDL_GetError( )
        return SDL_APP_FAILURE
    end if
    var st = new AppState
    st->maxFrames = valint( command( 1 ) )   '' 0: until closed
    *appstate = st
    if SDL_CreateWindowAndRenderer( "examples/renderer/clear", _
            640, 480, SDL_WINDOW_RESIZABLE, _
            @st->window, @st->renderer ) = false then
        print "Couldn't create window/renderer: "; *SDL_GetError( )
        return SDL_APP_FAILURE
    end if
    SDL_SetRenderLogicalPresentation( st->renderer, 640, 480, _
        SDL_LOGICAL_PRESENTATION_LETTERBOX )
    return SDL_APP_CONTINUE
end function

function AppEvent cdecl( byval appstate as any ptr, _
        byval event as SDL_Event ptr ) as SDL_AppResult
    if event->type = SDL_EVENT_QUIT then return SDL_APP_SUCCESS
    return SDL_APP_CONTINUE
end function

function AppIterate cdecl( byval appstate as any ptr ) as SDL_AppResult
    var st = cast( AppState ptr, appstate )
    var now = SDL_GetTicks( ) / 1000.0
    var red = 0.5 + 0.5 * SDL_sin( now )
    var green = 0.5 + 0.5 * SDL_sin( now + SDL_PI_D * 2 / 3 )
    var blue = 0.5 + 0.5 * SDL_sin( now + SDL_PI_D * 4 / 3 )
    SDL_SetRenderDrawColorFloat( st->renderer, red, green, blue, _
        SDL_ALPHA_OPAQUE_FLOAT )
    SDL_RenderClear( st->renderer )
    SDL_RenderPresent( st->renderer )
    st->frames += 1
    if st->frames = st->maxFrames then return SDL_APP_SUCCESS
    return SDL_APP_CONTINUE
end function

sub AppQuit cdecl( byval appstate as any ptr, _
        byval result as SDL_AppResult )
    var st = cast( AppState ptr, appstate )
    if st <> nullptr then
        print "drew "; str( st->frames ); " frames"
        delete st
    end if
end sub

'' SDL calls AppInit once, then AppEvent and AppIterate until one of
'' them returns something other than SDL_APP_CONTINUE, then AppQuit.
var rc = SDL_EnterAppMainCallbacks( 0, nullptr, @AppInit, _
    @AppIterate, @AppEvent, @AppQuit )
end rc
```

```bash
tiko sdl-clear.tiko
./sdl-clear
```

On Windows the build leaves `SDL3.dll` beside `sdl-clear.exe`; on Linux and macOS the program loads the system's SDL. Close the window and the program prints how many frames it drew. With a number, `./sdl-clear 60` stops by itself:

```
drew 60 frames
```

### What the import brings

- **Every routine, type and constant of SDL's headers**, unqualified, as SDL documents them: `SDL_Init`, `SDL_Window`, `SDL_INIT_VIDEO`. They come from a translated binding (SDL 3.4.4's headers) that ships with the toolchain, so no C compiler reads SDL's headers at your end.
- **The library, linked.** With no `link` the link is dynamic. `#import "vendor/SDL3" link static` puts SDL inside the program (step 3).
- **`SDL_main.h`'s routines, without its `main`.** In C that header supplies the program's `main`, which runs the callbacks; a tiko program has its own start. So the import declares only what the library exports: `SDL_EnterAppMainCallbacks`, `SDL_RunApp`, `SDL_SetMainReady` and, on Windows, `SDL_RegisterApp` and `SDL_UnregisterApp`. The program's last statement calls `SDL_EnterAppMainCallbacks` with the addresses of the four callbacks, exactly what C's `main` would have done.

### How the callbacks share data, with no globals

SDL's C example keeps the window and renderer in global variables. SDL also offers something better: `AppInit` receives the address of a pointer, `appstate`, and whatever you store there is handed to every later callback. The tiko version allocates one `AppState` with `new` in `AppInit` and frees it in `AppQuit`.

### Details

- **The callbacks must match SDL's types exactly**: `cdecl`, with the same parameter types as the binding's `SDL_AppInit_func`, `SDL_AppEvent_func` and the others. A mismatch is only warning `TKO0833: passing different pointer types`, and the program still builds, so treat that warning as an error.
- **SDL3 functions return `boolean`.** Compare them with `false`: `if SDL_Init( SDL_INIT_VIDEO ) = false then`.
- **`event->type`.** `SDL_Event` is a C union, and `->` reaches its fields as for any pointer to a struct.
- **`SDL_PI_D`, `SDL_ALPHA_OPAQUE_FLOAT`** are constants in the binding.

> 💡 **Running without a screen.** SDL reads the environment variable `SDL_VIDEO_DRIVER`. With `SDL_VIDEO_DRIVER=dummy`, it draws nowhere, so a program that opens windows still runs on a build server, for example: `SDL_VIDEO_DRIVER=dummy ./sdl-clear 60`.

## 3. Linking SDL statically

Change the import, nothing else:

```freebasic
#import "vendor/SDL3" link static
```

SDL is then inside the program; on Windows `sdl-clear.exe` grows to 2.9 MB and runs with no `SDL3.dll` beside it. The link adds the system libraries SDL needs by itself:

| Target | What the link adds |
|---|---|
| Windows | `setupapi`, `winmm`, `imm32`, `version`, `ole32`, `oleaut32`, `shell32`, `uuid`, `advapi32`, `cfgmgr32`, and the static C runtime: Visual Studio's `libvcruntime.lib` and `oldnames.lib` must be installed on the machine that links |
| Linux | `libm`, `libdl`, `libpthread`, `librt` |
| macOS | the system frameworks SDL uses (Cocoa, Metal, IOKit and others) and `libiconv` |

SDL still loads the display and sound libraries itself when it starts (X11 or Wayland and GL on Linux), as it does when linked dynamically.

One program links a module one way: two imports of `vendor/SDL3` asking for different modes are `TKO0157`.

## 4. More of SDL

SDL's satellite libraries are vendor packages too. Each imports `vendor/SDL3` publicly, so one line brings SDL's own names as well:

| Import | Library | Link modes |
|---|---|---|
| `#import "vendor/SDL3/image"` | SDL3_image: PNG, JPEG, BMP, GIF and more | `static`, `dynamic` (the default) |
| `#import "vendor/SDL3/ttf"` | SDL3_ttf: TrueType text, with FreeType and HarfBuzz | `static`, `dynamic` (the default) |
| `#import "vendor/SDL3/mixer"` | SDL3_mixer: sound and music | `dynamic` |

Each module's link mode is its own: a program that wants all of it inside writes `link static` on each import. On Linux install `libsdl3-image-dev`, `libsdl3-ttf-dev` and `libsdl3-mixer-dev` as well; on macOS `brew install sdl3_image sdl3_ttf sdl3_mixer`.

## 5. Shipping the program

- **Windows, dynamic:** ship `SDL3.dll` with the program; the build already put it beside the `.exe`. [`tiko build`](Category-Tiko-Build)'s `copy_to` copies it along with the program.
- **Windows, static:** the `.exe` alone.
- **Linux and macOS:** the program needs SDL3 installed on the machine that runs it (`libsdl3-0` or the distribution's equivalent; Homebrew's `sdl3`), or link it statically.

## 6. Your own SDL build

Use this when you need a different SDL version from the one `vendor/SDL3` ships, or your own build options. It replaces the import with the parts the vendor package does for you.

**Get it** from [github.com/libsdl-org/SDL/releases](https://github.com/libsdl-org/SDL/releases):

| File | Contains | You need it for |
|---|---|---|
| `SDL3-devel-3.4.18-VC.zip` | `include/SDL3/*.h`; `lib/x64/SDL3.lib` (import library) and `lib/x64/SDL3.dll` | building on Windows, linked dynamically |
| `SDL3-3.4.18.tar.gz` | the source | Linux, and a static library on Windows |

**Lay it out on Windows:**

| Copy | To |
|---|---|
| `include/` (the whole folder, with `SDL3/` inside) | `vendor/sdl3/include/` |
| `lib/x64/SDL3.lib` | `vendor/sdl3/SDL3_windows_x86_64.lib` |
| `lib/x64/SDL3.dll` | `SDL3.dll`, **beside your program** |

**Build it on Linux** (SDL's `docs/README-linux.md` lists the packages its build can use):

```bash
tar -xzf SDL3-3.4.18.tar.gz
cmake -S SDL3-3.4.18 -B build -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=ON -DSDL_SHARED=ON
cmake --build build
```

Copy `SDL3-3.4.18/include/` to `vendor/sdl3/include/`, `build/libSDL3.a` to `vendor/sdl3/SDL3-static_linux_x86_64.a`, and `build/libSDL3.so.0` (with `cp -L`; it is a link) to `vendor/sdl3/SDL3_linux_x86_64.so` and beside your program.

**Then replace the `#import`** with SDL's own headers, read by `#cinclude`:

```freebasic
#cmdline "-cinclude vendor/sdl3/include -cdefine SDL_MAIN_HANDLED"
#cinclude once "SDL3/SDL.h"
#cinclude once "SDL3/SDL_main.h"
#foreignlib SDL3 dynamic "vendor/sdl3/SDL3"
```

1. **`-cinclude vendor/sdl3/include`.** SDL's headers include each other as `#include <SDL3/SDL_stdinc.h>`, and for angle-bracket includes clang searches only the include directories. Inside `#cmdline` the path is relative to where you run `tiko`; in a project put it in `tiko.toml`'s `options`, where it is relative to `tiko.toml`.
2. **`-cdefine SDL_MAIN_HANDLED`** tells `SDL_main.h` to declare things only, not to supply `main`.
3. **`SDL_main.h`** then declares `SDL_EnterAppMainCallbacks` for you.
4. **SDL's own functions return C `bool`**; `= false` compares them as before.

For a static link, build `SDL3-static.lib` from the source with the Visual Studio Build Tools (`cmake -S SDL3-3.4.18 -B build -DSDL_STATIC=ON -DSDL_SHARED=OFF`, then `cmake --build build --config Release`), copy it to `vendor/sdl3/SDL3-static_windows_x86_64.lib`, and link it with the system libraries it needs:

```freebasic
#ifdef __FB_WIN32__
    #foreignlib SDL3 static "vendor/sdl3/SDL3-static", _
        "system:cfgmgr32", "system:ole32", "system:oleaut32", _
        "system:setupapi", "system:shell32"
#else
    #foreignlib SDL3 static "vendor/sdl3/SDL3-static"
#endif
```

## 7. Troubleshooting

| Problem | Fix |
|---|---|
| `cannot find -lSDL3` on Linux | install `libsdl3-dev` (or your distribution's SDL3 development package) |
| `TKO0743: 'sdl_enterappmaincallbacks' is not declared` | your tiko predates `vendor/SDL3`'s `SDL_main.h` routines; update tiko |
| `TKO0600: 'sdl_enterappmaincallbacks' is already declared in this scope` | the program declares it itself; delete that declaration, the import has it |
| `TKO0157: module 'vendor.sdl3' is imported with 'link dynamic' here and 'link static' elsewhere` | two imports of the same module ask for different link modes; make them agree |
| `Couldn't initialize SDL: No available video device` on Linux | no display SDL can use: check `DISPLAY`/`WAYLAND_DISPLAY`, or use `SDL_VIDEO_DRIVER=dummy` |
| `warning TKO0833` at `SDL_EnterAppMainCallbacks` | a callback's parameters differ from SDL's type; make them match |
| `TKO0336: unable to import C header` with `'SDL3/SDL_stdinc.h' file not found` (your own build) | add `-cinclude` for SDL's `include` folder |

---

**Back:** [GLFW](GLFW-Tutorial) · [raylib](Raylib-Tutorial) · [SQLite](SQLite-Tutorial) · [Vendor Packages](Vendor-Packages) · [Using C Libraries](Using-C-Libraries-Tutorial)

[Home](Home)
