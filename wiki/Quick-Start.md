# Quick Start

tiko is distributed as a **toolchain**: the compiler, its headers, its runtime libraries and its packages in one directory. Toolchains are published ready-built, so getting started is a download, not a build.

## What you need

- **A toolchain.** Download the newest release titled *tiko toolchains* from [Releases](https://github.com/PaulSquires/tiko-lang/releases): `tiko-windows-x86_64-<commit>.zip` for Windows, `tiko-linux-x86_64-<commit>.tar.gz` for Linux on x86-64, `tiko-linux-arm64-<commit>.tar.gz` for Linux on arm64 (aarch64), `tiko-macos-arm64-<commit>.tar.gz` for macOS on Apple Silicon. Unpack it anywhere; it holds one directory, `tiko-lang/`, on every system.
- **tkEdit**, the editor, comes in the same directory, beside the compiler: `tiko-lang\tkedit.exe` on Windows, `tiko-lang/tkedit` on Linux, `tiko-lang/tkEdit.app` on macOS -- in the top of the directory on every system. It is one file -- its fonts, themes and libraries are inside it -- and it finds the compiler next to itself or in `bin/`. It has a debugger too: `F9` sets a breakpoint and `F6` runs to it (see [Debugging](Debugging#in-tkedit)).
- **clang 18 or newer.** It is not bundled: tiko uses it to compile and to link. tiko takes the first it finds of `TIKO_CLANG`, then `C:\Program Files\LLVM\bin\clang.exe` on Windows, `/usr/bin/clang` on Linux or `/opt/homebrew/opt/llvm/bin/clang` on macOS, then `clang` on `PATH`.

## Compile a program

```bat
tiko-lang\tiko.exe hello.tiko
hello.exe
```

```bash
tiko-lang/bin/tiko hello.tiko
./hello
```

The same on Linux and macOS. No flags are needed. tiko finds its headers and libraries relative to its own executable, and the default target is the host's: `windows-x86_64` on Windows, `linux-x86_64` on x86-64 Linux, `linux-arm64` on arm64 Linux, `macos-arm64` on macOS.

## Installing on Linux arm64

tiko runs on aarch64 Linux with glibc 2.35 or newer: Ubuntu 22.04 or newer, Debian 12 or newer, Raspberry Pi OS bookworm (64-bit). The target is `linux-arm64`, the default there.

- **clang 18 or newer.** On Ubuntu 24.04, `apt install clang` gives clang 18. Ubuntu 22.04, Debian 12 and Raspberry Pi OS ship an older clang: install a `clang-NN` from [apt.llvm.org](https://apt.llvm.org) and point tiko at it with `TIKO_CLANG=/usr/bin/clang-NN`.
- **lld**, optional: `apt install lld`. tiko links with it when it is present, else with the system linker.
- **SDL3**, for a program that links [vendor/SDL3](Vendor-Packages) dynamically, as on x86-64 Linux: `libsdl3-dev` on Ubuntu 24.04 or newer; on Ubuntu 22.04, build SDL3 from source.

The graphics library (`SCREEN`, `PSET`) draws through X11, as on x86-64 Linux.

## Installing on macOS

tiko runs on Apple Silicon Macs with macOS 13 or newer.

- **Xcode's Command Line Tools:** `xcode-select --install`. Every link uses the macOS SDK and Apple's linker from them.
- **Homebrew's LLVM:** `brew install llvm`. Homebrew does not put this clang on `PATH`, and tiko does not need it there: it looks in `/opt/homebrew/opt/llvm/bin` itself.
- **Clear the download quarantine before the first run.** A browser marks what it downloads, and macOS then refuses the unsigned compiler: it hangs rather than failing. Unpack, then:

```bash
xattr -dr com.apple.quarantine tiko-lang
```

An archive fetched with `curl` or `gh release download` is not marked.

Optional, also from Homebrew: `openssl@3` for [std/tls and std/http](Category-Http), and `sdl3` (with `sdl3_image`, `sdl3_ttf`, `sdl3_mixer`) for [vendor/SDL3](Vendor-Packages). The graphics library (`SCREEN`, `PSET`) needs nothing installed: it draws through Cocoa on macOS, as it draws through X11 on Linux and GDI on Windows.

## Building for Android

> **Experimental.** See [Android](Android) for what works and what may still change.

The Windows toolchain also builds for Android phones (`-target android-arm64`) and the Android emulator (`-target android-x86_64`), on Android 10 or newer. `-app` packs an SDL3 or [tkControls](Category-tkControls) program as a signed APK. Besides clang it needs Android's NDK, SDK and a JDK, which Android Studio installs where tiko finds them: the [Android Setup Tutorial](Android-Setup-Tutorial) goes from a bare PC to an app on a phone.

## A first tour

```freebasic
#import "std/containers"

'' generics
type Box( of T )
    as T value
end type

dim b as Box( of int32 )
b.value = 7

'' a typed container, and for each over it
dim names as containers.Array( of ustring )
names.Push( "ada" )
names.Push( "grace" )

for each n as ustring in names
    print n
next

'' multiple return, by tuple
function MinMax( ) as (min as int32, max as int32)
    return (3, 9)
end function

var (lo, hi) = MinMax( )
print lo, hi

'' defer runs on the way out of the scope, on every path
scope
    defer print "cleaned up"
    print "working"
end scope
```

It prints:

```
ada
grace
 3             9
working
cleaned up
```

## Building a toolchain from source

Only needed to work on the compiler itself. From Git Bash on Windows, or from Linux, WSL or macOS:

```bash
git clone https://github.com/PaulSquires/tiko-lang.git
cd tiko-lang
sh seed/fetch-seed.sh
bash build/package.sh --verify
```

tiko builds tiko: the build compiles it with a **seed**, the earlier tiko release that `seed/seed.lock` pins. `sh seed/fetch-seed.sh` downloads it (through `gh` while the repository is private) and checks its SHA-256 before unpacking it into `seed/cache/`. `package.sh` then builds the compiler, the runtime and the graphics library, and assembles `toolchains/tiko-windows/`, `toolchains/tiko-linux/`, `toolchains/tiko-linux-arm64/` (on aarch64 Linux) or `toolchains/tiko-macos/`. It compiles **and runs** a program per target and records the result in `MANIFEST.txt`.

## Next

- [Feature Index](Feature-Index) — every language feature and library, with its reference page.
- [Compatibility](Compatibility) — what changes for FreeBASIC code you already have.
- [Keyword Index](Keyword-Index) — every keyword, A–Z.
