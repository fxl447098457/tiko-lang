[Home](Home) › [Foreign Library Linking](Category-Foreign-Library-Linking) › **#foreignlib Tutorial**

# #foreignlib Tutorial

> 📘 **Reference:** [#foreignlib](modern-Foreignlib) · **Before this:** [#cinclude Tutorial](modern-Cinclude-tutorial)

This tutorial shows you how to link a C library into a tiko program with `#foreignlib`. You will build a tiny C library, link it as a shared library and then statically, keep it inside your project so the project builds from anywhere, and learn what to do when a link goes wrong. No earlier experience with linking is needed.

---

## 1. What linking is

Building a program that uses a C library takes two steps.

1. **Compiling.** tiko reads your source. It needs to know what the library's functions look like: their names, parameters and results. [`#cinclude`](modern-Cinclude-tutorial) gets that from the library's header.
2. **Linking.** The *linker* joins your compiled code with the library's code into one program. It needs to know **which library file** to use. That is the job of `#foreignlib`.

A library can be linked in two ways:

| | Static | Dynamic (shared) |
|---|---|---|
| the library's code is | **copied into** your program | kept in a separate file, loaded when the program starts |
| the file the linker reads | Windows: `.lib` · Linux and macOS: `.a` | Windows: an *import library* `.lib`, or the `.dll` · Linux: `.so` · macOS: `.dylib` |
| the file the program needs when it runs | nothing extra | Windows: the `.dll` · Linux: the `.so` · macOS: the `.dylib` |
| your program is | one file | the program **plus** the library file |

On Windows, the linker does not read a DLL directly. It reads a small **import library** that lists what the DLL contains. Libraries you download usually come with one, and tiko can make one when they do not (section 11).

## 2. `#libpath` and `#inclib`, and where they fall short

tiko has two simple directives for linking: `#libpath` names a folder to search, and `#inclib` names a library to look for there.

```freebasic
'' Linking with #libpath and #inclib: a library name and a search directory.
#cinclude once "vendor/greet/greet.h"
#libpath "vendor/greet"
#inclib "greet"
```

This works when you build from the project folder. But build the same file from any other folder and the link fails:

```
lld-link: error: could not open 'greet.lib': no such file or directory
```

`#libpath "vendor/greet"` means *a folder called `vendor/greet` under the folder you are building in*, not under the source file. The library is right where the source says, but the linker looks in the wrong place.

There are two more problems:

- **It does not say static or dynamic.** `#inclib "greet"` names a library, and the linker takes the first file it finds with that name. Nothing tells you which kind you got.
- **It does not handle platforms.** A Windows `.lib` and a Linux `.so` are different files, and `#inclib` has no way of picking the right one for the platform you are building for.

`#foreignlib` solves all three. You can use `#inclib` and `#libpath` next to `#foreignlib` in the same program.

## 3. `#foreignlib` in one line

```freebasic
#foreignlib GREET dynamic "vendor/greet/greet"
```

| Part | Meaning |
|---|---|
| `GREET` | a name for this library. You choose it. |
| `dynamic` or `static` | **required**. Which kind of library to link. tiko never guesses. |
| `"vendor/greet/greet"` | where the library file is, **relative to this source file**, without its ending |

Three rules carry the whole directive:

1. **The path is relative to the source file**, so the project builds from any folder.
2. **You state the kind.** If no file of that kind is found, you get an error that lists every file tiko tried. tiko never falls back to the other kind.
3. **You never write the platform.** For `"vendor/greet/greet"`, tiko looks for `greet_windows_x86_64.lib` on Windows , `greet_linux_x86_64.so` on Linux and `greet_macos_arm64.dylib` on macOS, among others (section 9). One line works on all three.

## 4. Build a tiny C library

Create this layout:

```
greet-app/
    hello.tiko
    vendor/greet/greet.h
    vendor/greet/greet.c
```

`vendor/greet/greet.h`:

```c
/* greet.h -- a tiny C library, for trying out #foreignlib */
#ifndef GREET_H
#define GREET_H

/* On Windows, a DLL must say which functions it exports. */
#if defined(_WIN32) && defined(GREET_DLL)
#  define GREET_API __declspec(dllexport)
#else
#  define GREET_API
#endif

GREET_API const char *greet_how(void);
GREET_API int greet_add(int a, int b);

#endif
```

`vendor/greet/greet.c`:

```c
/* greet.c -- the code behind greet.h */
#include "greet.h"

const char *greet_how(void)
{
#ifdef GREET_DLL
    return "from a shared library";
#else
    return "from a static library";
#endif
}

int greet_add(int a, int b)
{
    return a + b;
}
```

`greet_how()` reports which way the library was built, so you can see which kind your program linked.

Now build the library both ways, from the `greet-app` folder. clang comes with LLVM, which tiko already needs.

**On Windows:**

```bash
clang -shared -fuse-ld=lld -O2 -DGREET_DLL vendor/greet/greet.c -o greet.dll -Wl,/implib:vendor/greet/greet_windows_x86_64.lib
clang -c -O2 vendor/greet/greet.c -o greet.obj
llvm-lib /out:vendor/greet/greet-static_windows_x86_64.lib greet.obj
```

The first command makes `greet.dll` in the project folder, next to where your program will be, and its import library in `vendor/greet`. The other two make the static library.

**On Linux:**

```bash
clang -shared -fPIC -O2 -DGREET_DLL vendor/greet/greet.c -Wl,-soname,libgreet.so -o vendor/greet/greet_linux_x86_64.so
cp vendor/greet/greet_linux_x86_64.so libgreet.so
clang -c -fPIC -O2 vendor/greet/greet.c -o greet.o
ar rcs vendor/greet/greet-static_linux_x86_64.a greet.o
```

`-Wl,-soname,libgreet.so` records the name the program will ask for when it starts, and the `cp` puts a file with that name next to the program (section 12).

**On macOS:**

```bash
clang -dynamiclib -O2 -DGREET_DLL vendor/greet/greet.c -install_name @rpath/libgreet.dylib -o vendor/greet/greet_macos_arm64.dylib
cp vendor/greet/greet_macos_arm64.dylib libgreet.dylib
clang -c -O2 vendor/greet/greet.c -o greet.o
ar rcs vendor/greet/greet-static_macos_arm64.a greet.o
```

`-install_name @rpath/libgreet.dylib` plays the part of the soname: it is the name the program asks for, found through the program's run path (section 12).

You now have:

```
greet-app/
    greet.dll                                  Windows: loaded when the program runs
    libgreet.so                                Linux: loaded when the program runs
    vendor/greet/greet.h
    vendor/greet/greet_windows_x86_64.lib      Windows: import library
    vendor/greet/greet-static_windows_x86_64.lib   Windows: static library
    vendor/greet/greet_linux_x86_64.so         Linux: shared library
    vendor/greet/greet-static_linux_x86_64.a   Linux: static library
    libgreet.dylib                             macOS: loaded when the program runs
    vendor/greet/greet_macos_arm64.dylib       macOS: shared library
    vendor/greet/greet-static_macos_arm64.a    macOS: static library
```

The static library is called `greet-static` because on Windows a static library and an import library are both `.lib` files, so they cannot share a name.

## 5. Link it dynamically

`hello.tiko`:

```freebasic
'' hello.tiko -- link the greet library as a shared library.
#cinclude once "vendor/greet/greet.h"
#foreignlib GREET dynamic "vendor/greet/greet"

print "2 + 3 ="; greet_add( 2, 3 )
print "greetings "; *greet_how( )
```

Build and run it. On Windows:

```bash
tiko hello.tiko
./hello
```

On Linux, tell the system to look for `libgreet.so` in the current folder (section 12 shows a better way):

```bash
tiko hello.tiko
LD_LIBRARY_PATH=. ./hello
```

```
2 + 3 = 5
greetings from a shared library
```

There is no `-p`, no `-l` and no `#ifdef` anywhere. The program names the library once, and tiko picks the right file for the platform.

### Build it from anywhere

Go to the folder above `greet-app` and build again:

```bash
cd ..
tiko greet-app/hello.tiko
```

It links, because the path in `#foreignlib` is relative to `hello.tiko`, not to where you are. The program is written next to its source, `greet-app/hello`, as always. You can move or copy the whole `greet-app` folder anywhere, and it still builds.

## 6. Link it statically

`hello-static.tiko` is the same program with one changed line:

```freebasic
'' hello-static.tiko -- link the greet library statically.
#cinclude once "vendor/greet/greet.h"
#foreignlib GREET static "vendor/greet/greet-static"

print "2 + 3 ="; greet_add( 2, 3 )
print "greetings "; *greet_how( )
```

```bash
tiko hello-static.tiko
./hello-static
```

```
2 + 3 = 5
greetings from a static library
```

The library's code is now inside `hello-static` itself. Delete `greet.dll` or `libgreet.so` and it still runs.

### Let the build choose

A program can offer both, and let whoever builds it pick:

```freebasic
'' hello-choose.tiko -- the build picks: -d GREET_STATIC for static.
#cinclude once "vendor/greet/greet.h"

#ifdef GREET_STATIC
    #foreignlib GREET static "vendor/greet/greet-static"
#else
    #foreignlib GREET dynamic "vendor/greet/greet"
#endif

print "greetings "; *greet_how( )
```

```bash
tiko hello-choose.tiko
./hello-choose
tiko hello-choose.tiko -d GREET_STATIC
./hello-choose
```

```
greetings from a shared library
greetings from a static library
```

On Linux, run the shared build with `LD_LIBRARY_PATH=.` in front, as in section 5.

## 7. When no file matches

Make a typing mistake in the path, `"vendor/greet/gret"`, and build:

```
hello.tiko(3,1): error TKO0329: #foreignlib found no matching library file: GREET dynamic vendor/greet/gret; tried:     vendor/greet/gret_windows_x86_64.dll.a
    vendor/greet/gret_windows_x86_64.lib
    vendor/greet/gret_windows_x86_64.dll
    vendor/greet/gret_windows.dll.a
    vendor/greet/gret_windows.lib
    vendor/greet/gret_windows.dll
    vendor/greet/gret_x86_64.dll.a
    vendor/greet/gret_x86_64.lib
    vendor/greet/gret_x86_64.dll
    vendor/greet/gret.dll.a
    vendor/greet/gret.lib
    vendor/greet/gret.dll

     |
   3 | #foreignlib GREET dynamic "vendor/greet/gret"
     | ^
```

The error names the directive, the line it is on, and **every file tiko tried, in order**. Compare the file names with the files you have, and the mistake is usually plain. That list is also the easiest way to find out what to call a library file.

Asking for the wrong kind is the same error. On Linux, `#foreignlib GREET static "vendor/greet/greet"` finds only the `.so` there, which is not a static library:

```
error TKO0329: #foreignlib found no matching library file: GREET static vendor/greet/greet; tried:     vendor/greet/greet_linux_x86_64.a
    vendor/greet/greet_linux.a
    vendor/greet/greet_x86_64.a
    vendor/greet/greet.a
```

You do not quietly get a shared library instead.

## 8. The other errors

| Error | Cause |
|---|---|
| `TKO0327: expected a name, STATIC or DYNAMIC, then a quoted spec after #foreignlib` | the directive is incomplete |
| `TKO0328: expected STATIC or DYNAMIC after the #foreignlib name, X` | the kind is missing |
| `TKO0329: #foreignlib found no matching library file` | no file has any of the names listed (section 7) |
| `TKO0330: #foreignlib name already bound to a different library set, X` | the same name is used for two different libraries |

Repeating a `#foreignlib` line exactly is allowed. That happens when two files include the same binding header.

## 9. How tiko picks the file

For `#foreignlib NAME kind "dir/base"`, tiko tries these names, most specific first:

```
dir/base_<os>_<arch><ext>
dir/base_<os><ext>
dir/base_<arch><ext>
dir/base<ext>
```

| | Windows | Linux | macOS |
|---|---|---|---|
| `<os>` | `windows` | `linux` | `macos` |
| `<arch>` | `x86_64` | `x86_64` | `arm64` |
| `<ext>` for `static` | `.a`, then `.lib` | `.a` | `.a` |
| `<ext>` for `dynamic` | `.dll.a`, then `.lib`, then `.dll` | `.so` | `.dylib` |

Every ending for the kind is tried at each step, and the first file that exists is used.

- **Name files with the platform tag** (`greet_windows_x86_64.lib`, `greet_linux_x86_64.so`) whenever files for more than one platform share a folder. Then each platform finds only its own files.
- **No `lib` is added or removed.** The base name is used exactly as written. A file called `libgreet.a` is `"vendor/greet/libgreet"`.
- **A path can also be absolute**, such as `"C:/libs/greet/greet"`.

> ⚠️ **On Windows, `.lib` counts as both kinds.** A static library and an import library are both `.lib` files, and nothing in the name tells them apart. So `#foreignlib GREET static "vendor/greet/greet"` would accept `greet_windows_x86_64.lib`, the **import** library, and the program would quietly need `greet.dll` after all. Give the two different base names, as section 4 does with `greet` and `greet-static`.

## 10. System libraries

Libraries that are part of the operating system, or installed for every program on the machine, are named with `system:`:

```freebasic
#foreignlib WINMM dynamic "system:winmm"
```

`"system:winmm"` hands the name to the linker, which searches its usual folders, exactly as `#inclib "winmm"` does. On Linux and macOS, `"system:m"` links the maths library, and a library installed by your package manager, such as `"system:sqlite3"`, is found the same way.

> ⚠️ **The kind is not checked for `system:`.** tiko does not look for the file itself, so it cannot check that it is the kind you asked for. The linker takes whatever it finds.

### Several libraries at once

One `#foreignlib` can name several libraries. They are linked in the order given. This is how a static library brings along the system libraries it needs:

```freebasic
#foreignlib GREET static "vendor/greet/greet-static", "system:winmm"
```

A static library is only its own code. If it calls other libraries, your program has to link them too. A library's documentation usually lists them. If it does not, link without them, and each `undefined symbol` error names a function you still need. The [Using C Libraries](Using-C-Libraries-Tutorial#static-linking-means-linking-the-librarys-dependencies-too) tutorial shows how to track them down.

## 11. A DLL with no import library

Some Windows libraries come as a `.dll` alone. That is fine. When a `dynamic` search finds only a `.dll`, tiko reads the list of functions inside it and makes the import library itself while linking.

To try it, keep only the DLL in `vendor/greet`, renamed with the platform tag:

```
greet-app/
    greet.dll                                  beside the program, unchanged
    vendor/greet/greet_windows_x86_64.dll      a copy, renamed
```

`hello.tiko` builds and runs exactly as before. The import library records the DLL by the name the DLL gives itself, `greet.dll`, not by the renamed file, so the program loads the copy beside it.

An import library or `.dll.a` with a matching name is found before the `.dll`, and then it is used as it is. A 32-bit DLL is refused with `TKO0172`, because tiko builds 64-bit programs only.

## 12. Running a program that uses a shared library

`#foreignlib` takes care of linking. Making sure the program can **find** the shared library when it starts is up to you.

**Windows** looks in the **program's own folder** first, then in the system folders and on `PATH`. Put the DLL beside the `.exe`. If it is missing, the program stops at once with exit code `-1073741515` (*DLL not found*). Keep the DLL's own name: it is recorded in the import library.

**Linux** does **not** look beside the program. It looks in `LD_LIBRARY_PATH`, then in the system's library folders, for the name recorded with `-soname` (`libgreet.so` here). Without it, you see:

```
./hello: error while loading shared libraries: libgreet.so: cannot open shared object file: No such file or directory
```

`LD_LIBRARY_PATH=. ./hello` is fine for a quick test. To make the program look beside itself every time, record an *rpath* when you link. Add this at the top of `hello.tiko`:

```freebasic
#ifdef __FB_LINUX__
    #cmdline "-Wl -rpath,$ORIGIN"
#endif
```

`$ORIGIN` means *the folder this program is in*, and `-Wl` passes the option to the linker. Now `./hello` runs with no `LD_LIBRARY_PATH`, from any folder, as long as `libgreet.so` is next to it. The `#ifdef` matters: Windows' linker has no `-rpath`.

**macOS** loads a library by its install name, here `@rpath/libgreet.dylib`. A program that links a `.dylib` file from `#foreignlib` gets the run path `@loader_path`, *the folder this program is in*, with nothing written: `./hello` runs as long as `libgreet.dylib` is next to it. Without it, the program stops before it starts:

```
dyld[<pid>]: Library not loaded: @rpath/libgreet.dylib
```

## 13. Naming the library in a declaration

If you write a `declare` by hand, you can say which library it belongs to with `lib` and the name from `#foreignlib`:

```freebasic
'' A system library, and a declaration written by hand that says
'' which library it belongs to.
#foreignlib WINMM dynamic "system:winmm"

declare function timeGetTime lib WINMM alias "timeGetTime" ( ) as uint32

print "Windows has been running for"; timeGetTime( ) \ 60000; " minutes"
```

This is optional. A `#foreignlib` links its libraries whether or not any declaration names them, so the declarations that `#cinclude` makes need no `lib` at all. Treat `lib WINMM` as a note to the reader: tiko does not check the name, so a misspelt one is not an error.

## 14. Sharing a binding

Put the `#cinclude` and `#foreignlib` lines for a library in one `.ti` file, next to the library. Both paths in it are relative to that `.ti` file, so a program includes it with one line, and the folder works wherever it is:

```freebasic
'' greet.ti -- the greet library: its header, and the file to link.
#pragma once

#cinclude once "greet/greet.h"
#foreignlib GREET dynamic "greet/greet"
```

The [#cinclude Tutorial](modern-Cinclude-tutorial#12-sharing-a-binding) shows this in full, and also how to make a binding a module with `public #cinclude`.

**Compiling in pieces.** When you compile one file at a time with `-c` and link the objects later, each object file remembers the libraries its `#foreignlib` lines found, with their full paths. The final link includes them, even when it runs in another folder.

## 15. What `#foreignlib` does not do

- **It does not download anything.** It links a library you already have.
- **It does not copy the DLL or `.so`** next to your program. That is still your job (section 12).
- **It does not load libraries while the program runs.** For that, use [`DyLibLoad`](Dylibload) and [`DyLibSymbol`](Dylibsymbol).

### See also

- [#foreignlib](modern-Foreignlib), the reference page
- [#cinclude Tutorial](modern-Cinclude-tutorial), declaring a library's functions from its header
- [Using C Libraries](Using-C-Libraries-Tutorial), with step-by-step tutorials for [SQLite](SQLite-Tutorial), [raylib](Raylib-Tutorial), [GLFW](GLFW-Tutorial) and [SDL3](SDL3-Tutorial)
- [`#inclib`](Inclib) · [`#libpath`](Libpath) · `#cmdline`

---

**Category:** [Foreign Library Linking](Category-Foreign-Library-Linking)  
**Kind:** tutorial

---

[Home](Home) · [Keyword Index](Keyword-Index)
