[Home](Home) › [Using C Libraries](Using-C-Libraries-Tutorial) › **raylib**

# raylib Tutorial

> 📘 **Start with:** [Using C Libraries](Using-C-Libraries-Tutorial), the ideas these steps rely on.
>
> 📖 **In the book:** [Chapter 30, raylib](https://tiko-lang.net/book/ch30-c-libraries.html#raylib). `vendor/raylib6` (raylib 6.2) measured on Windows and Linux; your own build (step 7) measured with raylib 6.0.

[raylib](https://www.raylib.com) is a library for making games. It has one header and 600 functions with plain names, and nothing to set up before your first window. It covers 2D and 3D drawing, textures, fonts, keyboard, mouse, gamepads and sound.

tiko ships raylib as a [vendor package](Vendor-Packages). One line gives a program all of raylib's API and links the library:

```freebasic
#import "vendor/raylib6"
```

There is nothing to download, no header to translate, no `#foreignlib` and nothing on the command line. raylib's own examples, ported to tiko, are in the toolchain's `examples/raylib6`.

> ⚠️ **Windows and Linux only.** `vendor/raylib6` is not available on macOS yet; importing it there stops with `TKO0309: #error: "vendor/raylib6 on macOS needs framework linking, not yet supported"`.

---

## 1. Your first window

This is raylib's first example, `core_basic_window`:

```freebasic
'' raylib's first example, core_basic_window: open a window and draw a
'' line of text until it is closed. A number on the command line stops
'' it after that many frames instead.
#import "vendor/raylib6"

const ScreenWidth = 800
const ScreenHeight = 450
dim maxFrames as int32 = valint( command( 1 ) )  '' 0: until closed

SetTraceLogLevel( LOG_WARNING )   '' raylib logs to stdout otherwise
InitWindow( ScreenWidth, ScreenHeight, _
    "raylib [core] example - basic window" )
SetTargetFPS( 60 )

dim frames as int32 = 0
do until WindowShouldClose( )
    BeginDrawing( )
    ClearBackground( RAYWHITE )
    DrawText( "Congrats! You created your first window!", _
        190, 200, 20, LIGHTGRAY )
    EndDrawing( )
    frames += 1
    if frames = maxFrames then exit do
loop
CloseWindow( )
print "drew "; str( frames ); " frames"
```

```bash
tiko raylib-window.tiko
./raylib-window
```

An 800×450 window opens with *"Congrats! You created your first window!"* in grey. Close it, and the program prints how many frames it drew. Give it a number, as in `./raylib-window 60`, and it stops by itself after that many frames:

```
drew 60 frames
```

**What the import does:**

- **raylib's names, unqualified**: `InitWindow`, `DrawText`, `KEY_RIGHT`, `Vector2`, as raylib documents them. They come from `raylib.h`, translated once by [`tiko c2t`](C2t) and shipped with the toolchain.
- **The library, linked dynamically** when no `link` is given, and **copied beside the program**: `raylib.dll` on Windows, `libraylib.so.620` on Linux. On Linux the program is linked with a run path of `$ORIGIN`, so it finds the copy beside it with no `LD_LIBRARY_PATH`. The program is 29 KB; `raylib.dll` is 1.8 MB.
- **`RAYWHITE` and `LIGHTGRAY`** are C macros that build a `Color` struct. The translation has them as `type<Color>(245, 245, 245, 255)` and so on, and `DrawText` takes the `Color` **by value**, as in C.

`SetTraceLogLevel( LOG_WARNING )` is raylib's, not tiko's: raylib reports everything it does on standard output, about forty lines when a window opens. Leave it out to see them.

## 2. Linked statically

Change the import, nothing else:

```freebasic
#import "vendor/raylib6" link static
```

raylib is then inside the program, which runs with nothing beside it: 491 KB on Windows, 945 KB on Linux. The link adds the system libraries a static raylib needs by itself:

| Target | What the link adds |
|---|---|
| Windows | `winmm` (timers), `gdi32`, `user32`, `shell32` |
| Linux | OpenGL (`GL`), `m`, `pthread`, `dl`, `rt` and `X11` |

On Linux, a static program still needs the system's OpenGL and X11 libraries when it runs, as any desktop program does.

## 3. Keyboard input

`core_input_keys` moves a ball with the arrow keys:

```freebasic
'' raylib's example core_input_keys: move a ball with the arrow keys.
'' A number on the command line stops it after that many frames.
#import "vendor/raylib6"

const ScreenWidth = 800
const ScreenHeight = 450
dim maxFrames as int32 = valint( command( 1 ) )  '' 0: until closed

SetTraceLogLevel( LOG_WARNING )
InitWindow( ScreenWidth, ScreenHeight, _
    "raylib [core] example - keyboard input" )
dim ball as Vector2 = type( ScreenWidth / 2, ScreenHeight / 2 )
SetTargetFPS( 60 )

dim frames as int32 = 0
do until WindowShouldClose( )
    if IsKeyDown( KEY_RIGHT ) then ball.x += 2
    if IsKeyDown( KEY_LEFT ) then ball.x -= 2
    if IsKeyDown( KEY_UP ) then ball.y -= 2
    if IsKeyDown( KEY_DOWN ) then ball.y += 2

    BeginDrawing( )
    ClearBackground( RAYWHITE )
    DrawText( "move the ball with arrow keys", 10, 10, 20, DARKGRAY )
    DrawCircleV( ball, 50, MAROON )
    EndDrawing( )
    frames += 1
    if frames = maxFrames then exit do
loop
CloseWindow( )
print "ball at "; str( ball.x ); ", "; str( ball.y ); _
    " after "; str( frames ); " frames"
```

```bash
tiko raylib-keys.tiko
./raylib-keys 30
```

```
ball at 400, 225 after 30 frames
```

`ball` is a `Vector2`, a C struct of two floats. `type( ... )` fills it, and it is passed to `DrawCircleV` by value. `KEY_RIGHT` and the other key names come from a C `enum` in `raylib.h`.

## 4. raymath and rlgl

raylib's two other headers are modules of their own, as they are headers of their own in C:

| Import | What it is |
|---|---|
| `#import "vendor/raylib6/raymath"` | vector, matrix and quaternion arithmetic: `Vector2Add`, `Vector3Normalize`, `MatrixRotateY` |
| `#import "vendor/raylib6/rlgl"` | raylib's immediate-mode layer over OpenGL: `rlPushMatrix`, `rlTranslatef`, `rlBegin`, `rlVertex3f` |

Each brings `vendor/raylib6` with it, so one import is enough:

```freebasic
'' raymath, raylib's vector and matrix library: no window needed.
#import "vendor/raylib6/raymath"

dim a as Vector2 = type( 3, 4 )
dim b as Vector2 = type( 1, 2 )
dim c as Vector2 = Vector2Add( a, b )
print "a + b = "; str( c.x ); ", "; str( c.y )
print "|a|   = "; str( Vector2Length( a ) )
dim n as Vector3 = Vector3Normalize( type<Vector3>( 0, 0, 5 ) )
print "norm  = "; str( n.x ); ", "; str( n.y ); ", "; str( n.z )
```

```
a + b = 4, 6
|a|   = 5
norm  = 0, 0, 1
```

raymath's functions are `inline` in C; raylib's libraries export every one of them, so here each is an ordinary call into the library.

**The link mode is chosen on `vendor/raylib6`**, the module that links. For a static program that uses raymath, write both imports:

```freebasic
#import "vendor/raylib6" link static
#import "vendor/raylib6/raymath"
```

`link` on raymath or rlgl themselves is `TKO0155`, because they link nothing of their own.

## 5. In a project

A [`tiko build`](Category-Tiko-Build) project needs nothing in its `tiko.toml` for raylib: the import says it all.

```toml
[package]
name = "game"

[target.game]
main = "main.tiko"
```

`tiko build`'s `copy_to` copies the shared library along with the program.

## 6. Shipping the program

- **Linked dynamically:** ship `raylib.dll` (Windows) or `libraylib.so.620` (Linux) beside the program. The build already put it there.
- **Linked statically:** the program alone.

If the shared library is missing, Windows exits with `-1073741515` and prints nothing (from Git Bash: `error while loading shared libraries: raylib.dll`, exit 127), while Linux says `error while loading shared libraries: libraylib.so.620`. Windows also looks in the current directory, so test a copy from its own folder.

## 7. Your own raylib build

Use this when you need a different raylib version from the one `vendor/raylib6` ships, or raylib built with your own options. It replaces the import with the parts the vendor package does for you.

**Get it** from [github.com/raysan5/raylib/releases](https://github.com/raysan5/raylib/releases):

| File | For | Contains |
|---|---|---|
| `raylib-6.0_win64_msvc16.zip` | Windows | `include/raylib.h` (+ `raymath.h`, `rlgl.h`)<br>`lib/raylib.lib` (**static**, 5.3 MB)<br>`lib/raylibdll.lib` (**import library**)<br>`lib/raylib.dll` |
| `raylib-6.0_linux_amd64.tar.gz` | Linux | the same headers<br>`lib/libraylib.a` (**static**)<br>`lib/libraylib.so.6.0.0`, plus links `libraylib.so.600` and `libraylib.so` |

**Copy the files into your project**, renaming the link-time files so that each carries its target. Both platforms can then share the folder, and one `#foreignlib` line finds the right file on each:

| Copy | To |
|---|---|
| `include/raylib.h` | `vendor/raylib/raylib.h` |
| `lib/raylib.lib` (Windows) | `vendor/raylib/raylib_windows_x86_64.lib` |
| `lib/raylibdll.lib` (Windows) | `vendor/raylib/raylibdll_windows_x86_64.lib` |
| `lib/raylib.dll` (Windows) | `raylib.dll`, **beside your program** |
| `lib/libraylib.a` (Linux) | `vendor/raylib/raylib_linux_x86_64.a` |
| `lib/libraylib.so.6.0.0` (Linux) | `vendor/raylib/raylibdll_linux_x86_64.so`, and `libraylib.so.600` **beside your program** |

On Linux use `cp -L` (or copy the real file `libraylib.so.6.0.0`), so that you copy the library and not a link to it.

**Then replace the `#import`** with raylib's own header, read by `#cinclude`, and the library, linked by `#foreignlib`. Statically, with the system libraries step 2 lists:

```freebasic
#cinclude once "vendor/raylib/raylib.h"
#ifdef __FB_WIN32__
    #foreignlib RAYLIB static "vendor/raylib/raylib", _
        "system:winmm", "system:gdi32", "system:user32", _
        "system:shell32"
#else
    #foreignlib RAYLIB static "vendor/raylib/raylib", _
        "system:GL", "system:m", "system:pthread", "system:dl", _
        "system:rt", "system:X11"
#endif
```

Or dynamically, where the DLL brings its own system libraries:

```freebasic
#cinclude once "vendor/raylib/raylib.h"
#foreignlib RAYLIB dynamic "vendor/raylib/raylibdll"
```

To keep those lines out of every program, put them in a **binding header** or a **binding module**, as [Using C Libraries](Using-C-Libraries-Tutorial#5-a-binding-header) shows; a binding module is exactly what `vendor/raylib6` is.

## 8. Troubleshooting

| Problem | Fix |
|---|---|
| `TKO0140: cannot find module 'vendor/raylib'` | the package is `vendor/raylib6` |
| `TKO0309: #error: "vendor/raylib6 on macOS needs framework linking, not yet supported"` | raylib is not available on macOS yet |
| `undefined reference to 'fmod@GLIBC_2.38'` on Linux | toolchain 0.1.5 or older: its raylib shared library needs glibc 2.38; use a newer toolchain, or `#import "vendor/raylib6" link static` |
| `TKO0155: 'link static' on '#import "vendor/raylib6/raymath"': package 'vendor' links nothing` | put `link` on `#import "vendor/raylib6"` instead (step 4) |
| a long list of `INFO:` lines | `SetTraceLogLevel( LOG_WARNING )` before `InitWindow` |
| `undefined symbol: __declspec(dllimport) DragQueryFileW` linking statically on Windows (your own build) | a system library is missing (that one is `shell32`); the full list is `winmm`, `gdi32`, `user32`, `shell32` |
| `undefined reference to 'XOpenDisplay'` linking statically on Linux (your own build) | add `"system:X11"` (and the rest of the list in step 2) |
| `TKO0329` with `raylib.a` among the names tried (your own build) | rename the Linux archive to `raylib_linux_x86_64.a`; untagged, Windows would try it before `raylib.lib` |

---

**Next:** [GLFW](GLFW-Tutorial) · [SDL3](SDL3-Tutorial) · **Back:** [SQLite](SQLite-Tutorial) · [Vendor Packages](Vendor-Packages)

[Home](Home)
