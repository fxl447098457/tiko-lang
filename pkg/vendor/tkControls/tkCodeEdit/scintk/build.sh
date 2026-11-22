#!/bin/bash
# Build scintk: Scintilla 5.5.7 + Lexilla (LexTiko) + PlatTk + ScintillaTk, as ONE shared library
# with the C++ runtime linked in statically, so nothing of it reaches the tiko link.
#   bash build.sh            Windows (Git Bash, clang++ -> scintk.dll), Linux (g++ -> libscintk.so)
#                            or macOS (clang++ -> libscintk.dylib)
# Incremental by timestamp. Output: bin/<os>/ beside this script.
# Also a STATIC archive, bin/<os>/scintk_<os>_<arch>.a, for tkCodeEdit's 'link static': the same
# objects, PlatTk and ScintillaTk compiled again with SCITK_STATIC. Its C++ runtime is the program's
# to link (tkCodeEdit names it): Visual Studio's static one on Windows, libstdc++ on Linux, libc++
# on macOS.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
V=$HERE/vendor
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) OS=windows ;;
    Darwin) OS=macos ;;
    *) OS=linux ;;
esac
OBJ=$HERE/out/$OS
OUT=$HERE/bin/$OS
mkdir -p "$OBJ" "$OUT"
INC="-I$V/scintilla/include -I$V/scintilla/src -I$V/lexilla/include -I$V/lexilla/lexlib -I$HERE"
if [ "$OS" = windows ]; then
    CXX=${CXX:-clang++}
    FLAGS="-std=c++17 -O2 --target=x86_64-pc-windows-msvc -fms-runtime-lib=static -D_CRT_SECURE_NO_WARNINGS -DNOMINMAX"
    SO=$OUT/scintk.dll
    O=obj
elif [ "$OS" = macos ]; then
    CXX=${CXX:-clang++}
    FLAGS="-std=c++17 -O2 -fPIC -fvisibility=hidden -mmacosx-version-min=13.0"
    SO=$OUT/libscintk.dylib
    O=o
else
    CXX=${CXX:-g++}
    FLAGS="-std=c++17 -O2 -fPIC -fvisibility=hidden"
    SO=$OUT/libscintk.so
    O=o
fi
# THE SHARED LIBRARY IS $SO, NEVER $LIB: Visual Studio's vcvars64.bat exports LIB, the folders
# lld-link looks in for libcmt.lib and the rest, and a shell variable of the same name replaces it
# for every command run below. That is what broke a build run from a vcvars shell.
#
# VISUAL STUDIO, or its Build Tools, is what this needs on Windows: Scintilla is C++, and the MSVC
# target's C++ headers and its static runtime (libcmt, libcpmt, oldnames) come only from there.
# A program that loads scintk.dll needs none of it; one that links scintk in ('link static') does.
# Checked before anything compiles, so a machine without it is told so. clang finds Visual Studio
# by itself only while LIB is unset: a LIB that is set replaces what clang would have found.
if [ "$OS" = windows ]; then
    vsok=0
    # The folders lld-link would search: clang's -libpath ones (-### prints them, backslashes
    # doubled), then LIB's.
    dirs=$( "$CXX" -### --target=x86_64-pc-windows-msvc -fms-runtime-lib=static -fuse-ld=lld \
                "$HERE/PlatTk.cxx" 2>&1 | grep -o '"-libpath:[^"]*"' | sed 's/^"-libpath://; s/"$//; s/\\\\/\\/g' )
    [ -n "${LIB:-}" ] && dirs="$dirs
$(printf '%s' "$LIB" | tr ';' '\n')"
    while IFS= read -r d; do
        [ -n "$d" ] && [ -f "$(cygpath -u "$d")/libcmt.lib" ] && vsok=1
    done <<< "$dirs"
    if [ "$vsok" = 0 ]; then
        if [ -n "${LIB:-}" ]; then
            echo "scintk: LIB is set, but none of its folders has libcmt.lib, and while LIB is set" >&2
            echo "        clang does not look for Visual Studio. Unset it ('unset LIB'), or set it" >&2
            echo "        the way vcvars64.bat does." >&2
        else
            echo "scintk: Visual Studio's C++ libraries were not found (no libcmt.lib). Building" >&2
            echo "        scintk on Windows needs Visual Studio 2022 or later, or its Build Tools," >&2
            echo "        with 'Desktop development with C++'." >&2
        fi
        exit 1
    fi
fi
srcs=( "$V"/scintilla/src/*.cxx "$V"/lexilla/src/Lexilla.cxx "$V"/lexilla/lexlib/*.cxx "$V"/lexilla/lexers/*.cxx \
       "$HERE"/PlatTk.cxx "$HERE"/ScintillaTk.cxx )
objs=()
n=0
for s in "${srcs[@]}"; do
    b=$(basename "$s" .cxx)
    [ "$(dirname "$s")" = "$V/lexilla/src" ] && b="lexilla_$b"
    o=$OBJ/$b.$O
    objs+=("$o")
    if [ ! -f "$o" ] || [ "$s" -nt "$o" ] || [ "$HERE/scintk.h" -nt "$o" ]; then
        # Vendor code compiles quiet (-w); ours must compile clean under -Wall.
        W=-w; case "$b" in PlatTk|ScintillaTk) W="-Wall -Wextra -Wno-unused-parameter" ;; esac
        "$CXX" $FLAGS $W $INC -c "$s" -o "$o"
        n=$((n+1))
    fi
done
if [ "$OS" = windows ]; then
    "$CXX" --target=x86_64-pc-windows-msvc -fms-runtime-lib=static -shared -fuse-ld=lld -o "$SO" "${objs[@]}"
elif [ "$OS" = macos ]; then
    # libc++ is the system's on macOS (no static one ships), so only the install name is ours.
    "$CXX" -mmacosx-version-min=13.0 -dynamiclib -Wl,-install_name,@rpath/libscintk.dylib -o "$SO" "${objs[@]}"
else
    "$CXX" -shared -o "$SO" "${objs[@]}" -static-libstdc++ -static-libgcc -Wl,-z,noexecstack
fi

# THE HOST'S ARCHITECTURE on Linux: aarch64 is linux-arm64 (docs/tiko-linux-arm64 L4).
case $OS in windows) ARCH=x86_64 ;; macos) ARCH=arm64 ;; *) ARCH=x86_64; [ "$(uname -m)" = aarch64 ] && ARCH=arm64 ;; esac
ST=$OUT/scintk_${OS}_$ARCH.a
# PlatTk and ScintillaTk define the exported entry points: compiled again with SCITK_STATIC,
# which on Windows exports nothing (scintk.h) and initialises the C++ runtime (ScintillaTk.cxx).
sobjs=()
for o in "${objs[@]}"; do
    case "$o" in "$OBJ/PlatTk.$O"|"$OBJ/ScintillaTk.$O") ;; *) sobjs+=("$o") ;; esac
done
for b in PlatTk ScintillaTk; do
    so=$OBJ/${b}_static.$O
    if [ ! -f "$so" ] || [ "$HERE/$b.cxx" -nt "$so" ] || [ "$HERE/scintk.h" -nt "$so" ]; then
        "$CXX" $FLAGS -DSCITK_STATIC -Wall -Wextra -Wno-unused-parameter $INC -c "$HERE/$b.cxx" -o "$so"
        n=$((n+1))
    fi
    sobjs+=("$so")
done
stale=0
[ -f "$ST" ] || stale=1
for o in "${sobjs[@]}"; do [ "$o" -nt "$ST" ] && stale=1; done
if [ "$stale" = 1 ]; then
    rm -f "$ST"
    if [ "$OS" = windows ]; then
        "$(dirname "$(command -v "$CXX")")/llvm-lib.exe" -out:"$(cygpath -m "$ST")" $(for o in "${sobjs[@]}"; do cygpath -m "$o"; done)
    else
        ar rcs "$ST" "${sobjs[@]}"
    fi
fi
echo "scintk: $SO, $ST ($n compiled)"
