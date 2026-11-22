# SDL3 examples

SDL's own examples, in tiko: each is one `.tiko` program that imports `vendor/SDL3`, which comes with
the toolchain.

| Folder | Shows |
| --- | --- |
| `renderer/01-clear` … `18-debug-text` | the 2D renderer: clearing, primitives, lines, points, rectangles, textures, geometry, colour mods, viewports, clip rectangles, reading pixels, debug text |
| `audio/03-load-wav`, `04-multiple-streams` | playing `.wav` files through audio streams |
| `input/03-gamepad-polling` | reading a gamepad's buttons and axes |
| `asyncio/01-load-bitmaps` | loading files with asynchronous I/O |

## Building and running

From an example's folder, with the toolchain's compiler (`tiko.exe` at its top on Windows,
`bin/tiko` on Linux):

```
tiko clear.tiko
clear.exe
```

On Windows, `SDL3.dll` is copied beside the program when it is built. On Linux, install your
distribution's SDL3 development package (`libsdl3-dev` on Debian and Ubuntu) first; the program
then loads the system's `libSDL3.so.0`. On macOS, `brew install sdl3` first; the program links
Homebrew's.

To put SDL inside the program instead, so it runs with no `SDL3.dll` beside it, change the
example's import to

```
#import "vendor/SDL3" link static
```

On Windows that link also needs Visual Studio's C runtime libraries (`libvcruntime.lib`,
`oldnames.lib`) on the machine that builds.

## Main loop or main callbacks

SDL's own examples are written with SDL3's *main callbacks*: four functions SDL calls, instead of
a main loop the program writes. These ports keep a plain main loop, which reads the same way in
every example. `vendor/SDL3` has the callbacks too (`SDL_EnterAppMainCallbacks`); the
[SDL3 tutorial](https://github.com/PaulSquires/tiko-lang/wiki/SDL3-Tutorial) writes
`01-clear` that way.

The pictures and sounds the examples load are in `Data/`. Each example finds them from where the
program is, not from the current directory, so it can be run from anywhere.

These examples are public domain, as SDL's are: use them for any purpose.
