[Home](Home) › [Using C Libraries](Using-C-Libraries-Tutorial) › **GLFW**

# GLFW Tutorial

> 📘 **Start with:** [Using C Libraries](Using-C-Libraries-Tutorial), the ideas these steps rely on.
>
> 📖 **In the book:** [Chapter 30, GLFW](https://tiko-lang.net/book/ch30-c-libraries.html#glfw). Measured with GLFW 3.5.1, on Windows and Linux.

[GLFW](https://www.glfw.org) does a small job well. It opens windows, gives each one an **OpenGL context** (the surface OpenGL draws on) or a Vulkan surface, and reports keyboard, mouse, gamepad and window events. It draws nothing itself; that is OpenGL's job. Use GLFW when you want to write the graphics code yourself.

On Windows, GLFW publishes ready-built libraries. On Linux you build it from source with CMake.

---

## 1. Download

From [glfw.org/download.html](https://www.glfw.org/download.html):

- **Windows:** *64-bit Windows binaries*, `glfw-3.5.1.bin.WIN64.zip`
- **Linux:** *Source package*, `glfw-3.5.1.zip`

The Windows zip holds `include/GLFW/glfw3.h` and one folder of libraries per compiler:

| Folder | Use it? |
|---|---|
| `lib-vc2022` | **yes:** `glfw3.lib` (static), `glfw3dll.lib` (import library), `glfw3.dll` |
| `lib-vc2017`, `lib-vc2019`, `lib-vc2026` | the same, built by other Visual C++ versions |
| `lib-static-ucrt` | a DLL with the C runtime built into it |
| `lib-mingw-w64` | no: that is for the MinGW toolchain |

`lib-vc2022` also has `glfw3_mt.lib`. GLFW's `README.md` explains it: `glfw3.lib` is for programs that use the C runtime **as a DLL**, and `glfw3_mt.lib` for programs that link the runtime statically. tiko programs use the C runtime DLL (`ucrtbase.dll`), so take **`glfw3.lib`**.

## 2. Lay it out: Windows

| Copy | To |
|---|---|
| `include/` (the whole folder) | `vendor/glfw/include/` |
| `lib-vc2022/glfw3.lib` | `vendor/glfw/glfw3_windows_x86_64.lib` |
| `lib-vc2022/glfw3dll.lib` | `vendor/glfw/glfw3dll_windows_x86_64.lib` |
| `lib-vc2022/glfw3.dll` | `glfw3.dll`, **beside your program** |

## 3. Build it and lay it out: Linux

First the packages GLFW needs to build. This is the list from GLFW's `docs/compile.md`, covering both of Linux's window systems, X11 and Wayland:

```bash
sudo apt install libwayland-dev libxkbcommon-dev xorg-dev
```

Then build it twice, once static and once shared:

```bash
unzip glfw-3.5.1.zip
cmake -S glfw-3.5.1 -B build-static -DCMAKE_BUILD_TYPE=Release
cmake --build build-static
cmake -S glfw-3.5.1 -B build-shared -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
cmake --build build-shared
```

> ℹ️ To build for **Wayland only**, without the X11 packages, add `-DGLFW_BUILD_X11=OFF` to both `cmake -S` lines. The tutorial's programs were checked with that build.

| Copy | To |
|---|---|
| `glfw-3.5.1/include/` | `vendor/glfw/include/` |
| `build-static/src/libglfw3.a` | `vendor/glfw/glfw3_linux_x86_64.a` |
| `build-shared/src/libglfw.so.3` | `vendor/glfw/glfw3dll_linux_x86_64.so` |
| `build-shared/src/libglfw.so.3` | `libglfw.so.3`, **beside your program** |

`libglfw.so.3` is a link to the real file. Copy it with `cp -L` so that you get the file.

## 4. A window, linked statically

GLFW's documentation shows this program first: create a window, make its OpenGL context current, and clear it every frame until it is closed.

```freebasic
'' GLFW's example from its documentation: a window with an OpenGL
'' context, cleared every frame until it is closed. A number on the
'' command line stops it after that many frames instead.
#cinclude once "vendor/glfw/include/GLFW/glfw3.h"
#ifdef TIKO_OS_WINDOWS
    #foreignlib GLFW static "vendor/glfw/glfw3", "system:opengl32", _
        "system:gdi32", "system:user32", "system:shell32"
#else
    #foreignlib GLFW static "vendor/glfw/glfw3", "system:GL", _
        "system:m"
#endif

'' GLFW reports every error here, as it happens.
sub OnError cdecl( byval code as int32, _
        byval description as const zstring ptr )
    print "GLFW error "; hex( code ); ": "; *description
end sub

dim maxFrames as int32 = valint( command( 1 ) )  '' 0: until closed

glfwSetErrorCallback( @OnError )
if glfwInit( ) = GLFW_FALSE then end 1

dim win as GLFWwindow ptr = _
    glfwCreateWindow( 640, 480, "Hello World", nullptr, nullptr )
if win = nullptr then
    glfwTerminate( )
    end 1
end if
glfwMakeContextCurrent( win )

dim frames as int32 = 0
do until glfwWindowShouldClose( win )
    glClear( GL_COLOR_BUFFER_BIT )
    glfwSwapBuffers( win )
    glfwPollEvents( )
    frames += 1
    if frames = maxFrames then exit do
loop
glfwTerminate( )

dim as int32 major, minor, revision
glfwGetVersion( @major, @minor, @revision )
print "GLFW "; str( major ); "."; str( minor ); "."; str( revision ); _
    ": drew "; str( frames ); " frames"
```

```bash
tiko glfw-window.tiko
./glfw-window
```

A black 640×480 window titled *Hello World* opens. Close it, and the program prints the GLFW version and the number of frames it drew. Give a number to stop it after that many frames: `./glfw-window 60` prints

```
GLFW 3.5.1: drew 60 frames
```

**Things to notice:**

- **`glClear` and `GL_COLOR_BUFFER_BIT` belong to OpenGL, not GLFW.** `glfw3.h` includes `GL/gl.h` for you, so `#cinclude` imports them too. Their code is in OpenGL's library, so the program links it: `"system:opengl32"` on Windows, `"system:GL"` on Linux.
- **The error callback** is a `cdecl` sub that matches C's `void (*)(int, const char *)`. GLFW calls it whenever something fails. It is installed before `glfwInit`, so that even a failed start is explained.
- **On Windows, static GLFW also needs `gdi32`, `user32` and `shell32`.** On Linux, GLFW loads its window-system libraries while the program runs, so the static library needs only `GL` and `m` here.

## 5. The same window, linked dynamically

Replace the directives with:

```freebasic
#cinclude once "vendor/glfw/include/GLFW/glfw3.h"
#ifdef TIKO_OS_WINDOWS
    #foreignlib GLFW dynamic "vendor/glfw/glfw3dll", "system:opengl32"
#else
    #foreignlib GLFW dynamic "vendor/glfw/glfw3dll", "system:GL"
#endif
```

The OpenGL library stays, because the **program** calls `glClear` itself. The DLL links its own dependencies, but not yours. Then:

```bash
tiko glfw-dll.tiko
./glfw-dll                          # Windows: glfw3.dll beside it
LD_LIBRARY_PATH=. ./glfw-dll        # Linux: libglfw.so.3 beside it
```

## 6. Installing GLFW for every program

**Linux:** `sudo apt install libglfw3-dev` installs the distribution's version, 3.3.10 on Ubuntu 24.04. For 3.5.1, run `sudo cmake --install build-shared` after step 3, then `sudo ldconfig`. Either way the program says:

```freebasic
#cinclude once "GLFW/glfw3.h"
#foreignlib GLFW dynamic "system:glfw", "system:GL"
```

**Windows:** keep `vendor/glfw/` in a shared folder with a [binding header](Using-C-Libraries-Tutorial#5-a-binding-header).

## 7. Beyond OpenGL 1.1

On Windows, `opengl32.dll` exports only the functions of OpenGL 1.1, from 1997, and `glClear` is one of them. Every later function, shaders and buffers included, has to be looked up while the program runs. Pass its name to `glfwGetProcAddress` and assign the result to a function pointer of the right type. Most C programs use a generated *loader* such as [glad](https://glad.dav1d.de) to do that for every function at once. The same applies on every platform; it is how OpenGL is designed.

## 8. Troubleshooting

| Problem | Fix |
|---|---|
| `undefined symbol: glClear` / `undefined reference to 'glClear'` | link OpenGL: `"system:opengl32"` or `"system:GL"` |
| on Linux the program prints a `GLFW error` ending `Wayland: Failed to connect to display` | no Wayland display: check `WAYLAND_DISPLAY` and `XDG_RUNTIME_DIR`, or build GLFW with X11 |
| `Xinerama headers not found` from CMake | install `xorg-dev`, or build for Wayland only (`-DGLFW_BUILD_X11=OFF`) |
| `error while loading shared libraries: libglfw.so.3` | `LD_LIBRARY_PATH=.` or install GLFW |

---

**Next:** [SDL3](SDL3-Tutorial) · **Back:** [raylib](Raylib-Tutorial) · [SQLite](SQLite-Tutorial)

[Home](Home)
