#!/usr/bin/env bash
# fetch-libs.sh -- download and lay out the four C libraries Chapter 30 uses.
#
#   bash fetch-libs.sh          on Windows (Git Bash): the windows-x86_64 files
#                               on Linux:              the linux-x86_64 files
#                               on macOS:              the macos-arm64 files -- SQLite only:
#                               raylib, GLFW and SDL link Apple's frameworks, which tiko
#                               cannot link yet, so their listings are Windows and Linux
#                               on aarch64 Linux:      the linux-arm64 files -- SQLite only, as
#                               on macOS: the raylib, GLFW and SDL listings are
#                               windows-x86_64 and linux-x86_64 (their metas say so)
#
# Run it once on each platform you build for; both can share one tree, because
# every library file carries its target in its name. Nothing it writes is
# committed: vendor/ and the runtime libraries beside the listings are rebuilt
# from the pinned downloads below, each checked against its SHA-256. The tiko
# headers translate.sh made from the C headers (vendor/**/*.ti) are committed,
# and this script leaves them where they are.
#
# Windows needs LLVM (which tiko needs anyway), CMake and the Visual Studio
# Build Tools with the Windows SDK. Linux needs gcc, make, cmake and the X11 and
# Wayland development packages GLFW and SDL list; GLFW_CMAKE_ARGS and
# SDL_CMAKE_ARGS pass extra options to those two builds.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

SQLITE_VER=3540000
RAYLIB_VER=6.0
GLFW_VER=3.5.1
SDL_VER=3.4.18

case "$(uname -s)" in
  MINGW*|MSYS*) target=windows_x86_64 ;;
  Linux)        target=linux_x86_64; [[ "$(uname -m)" == aarch64 ]] && target=linux_arm64 ;;
  Darwin)       target=macos_arm64 ;;
  *) echo "fetch-libs: unsupported platform $(uname -s)" >&2; exit 1 ;;
esac

dl="$here/vendor/.downloads"
mkdir -p "$dl" vendor/sqlite vendor/raylib vendor/glfw vendor/sdl3

fetch() { # fetch <url> <sha256>: download once into vendor/.downloads, verify
  local url="$1" sum="$2" file="$dl/${1##*/}"
  [[ -f "$file" ]] || curl -fsSL -o "$file" "$url"
  # macOS has no sha256sum; its shasum checks the same line.
  if command -v sha256sum > /dev/null; then
    echo "$sum *$file" | sha256sum -c --quiet - || { rm -f "$file"; exit 1; }
  else
    echo "$sum *$file" | shasum -a 256 -c --quiet - || { rm -f "$file"; exit 1; }
  fi
  printf '%s\n' "$file"
}

unpack() { # unpack <archive>: into a fresh directory, printed
  local out="$dl/x/$(basename "$1")"
  rm -rf "$out"; mkdir -p "$out"
  case "$1" in
    *.zip) unzip -q "$1" -d "$out" ;;
    *)     tar -xzf "$1" -C "$out" ;;
  esac
  printf '%s\n' "$out"
}

# ------------------------------------------------------------------ Windows
windows() {
  local llvm="${LLVM_BIN:-/c/Program Files/LLVM/bin}" a s

  echo "== SQLite $SQLITE_VER"
  a="$(unpack "$(fetch https://sqlite.org/2026/sqlite-amalgamation-$SQLITE_VER.zip \
      68e913b0fe8ec6b4e5f391c594a28872884e80d6cd042a1e50c957be46b5aa4d)")"
  s="$a/sqlite-amalgamation-$SQLITE_VER"
  cp "$s/sqlite3.h" vendor/sqlite/
  # Static: compile the amalgamation and archive the one object.
  "$llvm/clang.exe" -c -O2 -o "$dl/sqlite3.obj" "$s/sqlite3.c"
  "$llvm/llvm-lib.exe" /out:vendor/sqlite/sqlite3-static_$target.lib "$dl/sqlite3.obj"
  # Dynamic: the DLL zip has sqlite3.dll and sqlite3.def but no import
  # library. #foreignlib makes one from the DLL itself when it links, so the
  # DLL goes into vendor/ under its target-tagged name, and beside the
  # program under its own.
  a="$(unpack "$(fetch https://sqlite.org/2026/sqlite-dll-win-x64-$SQLITE_VER.zip \
      a548a9b5d8f695e669f71bcc4669fdc8b3e1eb79995761c81a9128262126f71c)")"
  rm -f vendor/sqlite/sqlite3_$target.lib
  cp "$a/sqlite3.dll" vendor/sqlite/sqlite3_$target.dll
  cp "$a/sqlite3.dll" .

  echo "== raylib $RAYLIB_VER"
  a="$(unpack "$(fetch https://github.com/raysan5/raylib/releases/download/$RAYLIB_VER/raylib-${RAYLIB_VER}_win64_msvc16.zip \
      c93c7dc74576e00e3ee57fa2bd5fd109fbfc5aca87e12046dd7ec2c2268b3f78)")"
  s="$a/raylib-${RAYLIB_VER}_win64_msvc16"
  cp "$s"/include/*.h vendor/raylib/
  cp "$s/lib/raylib.lib"    vendor/raylib/raylib_$target.lib
  cp "$s/lib/raylibdll.lib" vendor/raylib/raylibdll_$target.lib
  cp "$s/lib/raylib.dll" .

  echo "== GLFW $GLFW_VER"
  a="$(unpack "$(fetch https://github.com/glfw/glfw/releases/download/$GLFW_VER/glfw-$GLFW_VER.bin.WIN64.zip \
      34c6766043e09ad9c6e88b5636a5f34d1f2857aae828768c5bf2016dc8821a93)")"
  s="$a/glfw-$GLFW_VER.bin.WIN64"
  mkdir -p vendor/glfw/include; cp -r "$s/include/." vendor/glfw/include/
  # lib-vc2022/glfw3.lib is built for the DLL C runtime, which tiko links.
  cp "$s/lib-vc2022/glfw3.lib"    vendor/glfw/glfw3_$target.lib
  cp "$s/lib-vc2022/glfw3dll.lib" vendor/glfw/glfw3dll_$target.lib
  cp "$s/lib-vc2022/glfw3.dll" .

  echo "== SDL $SDL_VER"
  a="$(unpack "$(fetch https://github.com/libsdl-org/SDL/releases/download/release-$SDL_VER/SDL3-devel-$SDL_VER-VC.zip \
      78d84602ae616cfe26b33a73b7d3b9b6b56e8a6650e53d92c9c6ca938f747acd)")"
  s="$a/SDL3-$SDL_VER"
  mkdir -p vendor/sdl3/include; cp -r "$s/include/." vendor/sdl3/include/
  cp "$s/lib/x64/SDL3.lib" vendor/sdl3/SDL3_$target.lib
  cp "$s/lib/x64/SDL3.dll" .
  # SDL ships no static library for Visual C++: build one from the source.
  a="$(unpack "$(fetch https://github.com/libsdl-org/SDL/releases/download/release-$SDL_VER/SDL3-$SDL_VER.tar.gz \
      9c75cf16330322c217dedd2e0609f1124f1b54b8633e763467b4684d0f4334a3)")"
  s="$a/SDL3-$SDL_VER"
  cmake -S "$s" -B "$s/build" -DSDL_STATIC=ON -DSDL_SHARED=OFF \
      -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF ${SDL_CMAKE_ARGS:-} > "$dl/sdl-static.log"
  cmake --build "$s/build" --config Release -j 8 >> "$dl/sdl-static.log"
  cp "$s/build/Release/SDL3-static.lib" vendor/sdl3/SDL3-static_$target.lib
}

# ------------------------------------------------------------------ Linux
linux() {
  local a s b
  # Builds run in the Linux file system, which is much faster than a
  # Windows drive seen from WSL.
  b="${XDG_CACHE_HOME:-$HOME/.cache}/tiko-book-ch30"; mkdir -p "$b"

  echo "== SQLite $SQLITE_VER"
  a="$(unpack "$(fetch https://sqlite.org/2026/sqlite-autoconf-$SQLITE_VER.tar.gz \
      134ec0802dda5795816e25d25872d20b312cb3973438c49b30bc40b7705ea9ed)")"
  s="$a/sqlite-autoconf-$SQLITE_VER"
  cp "$s/sqlite3.h" vendor/sqlite/
  gcc -O2 -fPIC -c -o "$b/sqlite3.o" "$s/sqlite3.c"
  rm -f vendor/sqlite/sqlite3-static_$target.a
  ar rcs vendor/sqlite/sqlite3-static_$target.a "$b/sqlite3.o"
  # The soname is the name the program will look for when it starts.
  gcc -shared -Wl,-soname,libsqlite3.so.0 -o vendor/sqlite/sqlite3_$target.so \
      "$b/sqlite3.o" -lm
  cp vendor/sqlite/sqlite3_$target.so libsqlite3.so.0
  # linux-arm64 stops here: the rest are x86-64 downloads, for listings that are not its.
  [[ "$target" == linux_arm64 ]] && return 0

  echo "== raylib $RAYLIB_VER"
  a="$(unpack "$(fetch https://github.com/raysan5/raylib/releases/download/$RAYLIB_VER/raylib-${RAYLIB_VER}_linux_amd64.tar.gz \
      b64ba618a19e7da9e9c0e09bb398ecfd477a77d2d7231901bafc8739d27c08d2)")"
  s="$a/raylib-${RAYLIB_VER}_linux_amd64"
  cp "$s"/include/*.h vendor/raylib/
  cp "$s/lib/libraylib.a" vendor/raylib/raylib_$target.a
  cp -L "$s/lib/libraylib.so.$RAYLIB_VER.0" vendor/raylib/raylibdll_$target.so
  cp -L "$s/lib/libraylib.so.$RAYLIB_VER.0" libraylib.so.600

  echo "== GLFW $GLFW_VER"
  a="$(unpack "$(fetch https://github.com/glfw/glfw/releases/download/$GLFW_VER/glfw-$GLFW_VER.zip \
      ea79bc5feffc254c87291980c2d0bce9acebb68c4983b79f961dcd2cb8a611a0)")"
  s="$a/glfw-$GLFW_VER"
  for kind in static shared; do
    local shared=OFF; [[ $kind == shared ]] && shared=ON
    rm -rf "$b/glfw-$kind"
    cmake -S "$s" -B "$b/glfw-$kind" -DBUILD_SHARED_LIBS=$shared \
        -DGLFW_BUILD_EXAMPLES=OFF -DGLFW_BUILD_TESTS=OFF -DGLFW_BUILD_DOCS=OFF \
        -DCMAKE_BUILD_TYPE=Release ${GLFW_CMAKE_ARGS:-} > "$b/glfw-$kind.log"
    cmake --build "$b/glfw-$kind" -j 8 >> "$b/glfw-$kind.log"
  done
  mkdir -p vendor/glfw/include; cp -r "$s/include/." vendor/glfw/include/
  cp "$b/glfw-static/src/libglfw3.a" vendor/glfw/glfw3_$target.a
  cp -L "$b/glfw-shared/src/libglfw.so.3" vendor/glfw/glfw3dll_$target.so
  cp -L "$b/glfw-shared/src/libglfw.so.3" libglfw.so.3

  echo "== SDL $SDL_VER"
  a="$(unpack "$(fetch https://github.com/libsdl-org/SDL/releases/download/release-$SDL_VER/SDL3-$SDL_VER.tar.gz \
      9c75cf16330322c217dedd2e0609f1124f1b54b8633e763467b4684d0f4334a3)")"
  s="$a/SDL3-$SDL_VER"
  rm -rf "$b/sdl"
  cmake -S "$s" -B "$b/sdl" -DSDL_STATIC=ON -DSDL_SHARED=ON -DSDL_TESTS=OFF \
      -DSDL_EXAMPLES=OFF -DCMAKE_BUILD_TYPE=Release ${SDL_CMAKE_ARGS:-} > "$b/sdl.log"
  cmake --build "$b/sdl" -j 8 >> "$b/sdl.log"
  mkdir -p vendor/sdl3/include; cp -r "$s/include/." vendor/sdl3/include/
  cp "$b/sdl/libSDL3.a" vendor/sdl3/SDL3-static_$target.a
  cp -L "$b/sdl/libSDL3.so.0" vendor/sdl3/SDL3_$target.so
  cp -L "$b/sdl/libSDL3.so.0" libSDL3.so.0
}

# ------------------------------------------------------------------ macOS
macos() {
  local a s b
  b="${TMPDIR:-/tmp}/tiko-book-ch30"; mkdir -p "$b"

  echo "== SQLite $SQLITE_VER"
  a="$(unpack "$(fetch https://sqlite.org/2026/sqlite-autoconf-$SQLITE_VER.tar.gz \
      134ec0802dda5795816e25d25872d20b312cb3973438c49b30bc40b7705ea9ed)")"
  s="$a/sqlite-autoconf-$SQLITE_VER"
  cp "$s/sqlite3.h" vendor/sqlite/
  clang -O2 -c -o "$b/sqlite3.o" "$s/sqlite3.c"
  rm -f vendor/sqlite/sqlite3-static_$target.a
  ar rcs vendor/sqlite/sqlite3-static_$target.a "$b/sqlite3.o"
  # The install name is the name the program will look for when it starts.
  clang -dynamiclib -install_name @rpath/libsqlite3.0.dylib \
      -o vendor/sqlite/sqlite3_$target.dylib "$b/sqlite3.o"
  cp vendor/sqlite/sqlite3_$target.dylib libsqlite3.0.dylib
}

case "$target" in
  windows_x86_64) windows ;;
  linux_x86_64|linux_arm64) linux ;;
  macos_arm64)    macos ;;
esac
echo "fetch-libs: done for $target"
