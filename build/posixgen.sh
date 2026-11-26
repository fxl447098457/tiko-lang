#!/bin/sh
# posixgen.sh -- regenerate this POSIX host's binding: build/posixgen.c measures the C ABI
# listed in build/posix.spec and prints it as tiko.
#
#   build/posixgen.sh            on linux-x86_64: lib/rt/src/inc/sysbind/linux-x86_64-posix.ti
#                                and pkg/sys/posix/linux-x86_64-posix.ti (the same bytes)
#   build/posixgen.sh --check    regenerate into a temporary file and diff, writing nothing
#   build/posixgen.sh --adb [--check]
#                                on Windows, for TIKO_ADB_TARGET (android-x86_64, the default, or
#                                android-arm64): built with the NDK's clang and run on the device
#                                or emulator adb reaches (docs/tiko-android A1, A3). An arm64
#                                build runs under the x86_64 emulator's ARM translation as well:
#                                every value it prints is a compile-time constant.
#
# RUN IT ON THE TARGET'S OWN HOST -- WSL for linux-x86_64, the Mac for macos-arm64, the Lima VM
# on the Mac for linux-arm64 (docs/tiko-linux-arm64) -- with that
# host's C compiler and C library: the values are measured, never typed in. Commit both
# outputs. tiko-rt includes the first (inc/sysbind.ti); the std modules include the second as a
# private header (pkg/sys/posix/posix.ti). Two copies because the packaged toolchain ships pkg/
# but not lib/rt/src; build/lint.sh fails if they differ.
#
# CLANG (or TIKO_CLANG) names the compiler; else clang on PATH.
set -eu
cd "$(dirname "$0")/.."
ROOT=$(pwd)
CHECK=0
ADB=0
for a in "$@"; do
    case "$a" in
        --check) CHECK=1 ;;
        --adb)   ADB=1 ;;
        *) echo "posixgen: unknown option '$a'" >&2; exit 2 ;;
    esac
done

if [ "$ADB" = "1" ]; then
    TARGET=${TIKO_ADB_TARGET:-android-x86_64}
    case "$TARGET" in
        android-x86_64) ATRIPLE=x86_64-linux-android29 ;;
        android-arm64)  ATRIPLE=aarch64-linux-android29 ;;
        *) echo "posixgen: TIKO_ADB_TARGET is android-x86_64 or android-arm64, not '$TARGET'" >&2; exit 2 ;;
    esac
else
    case "$(uname -s)-$(uname -m)" in
        Linux-x86_64)  TARGET=linux-x86_64 ;;
        Linux-aarch64) TARGET=linux-arm64 ;;
        Darwin-arm64)  TARGET=macos-arm64 ;;
        *) echo "posixgen: no tiko target for host $(uname -s)-$(uname -m)" >&2; exit 2 ;;
    esac
fi

WK=${TMPDIR:-/tmp}/posixgen.$$
mkdir -p "$WK"
trap 'rm -rf "$WK"' EXIT

if [ "$ADB" = "1" ]; then
    # ANDROID IS MEASURED ON THE DEVICE, as every target is on its own host: the NDK's clang
    # builds posixgen.c against Bionic's headers at the target's API level (29, the triple's),
    # and adb runs it there. MSYS would rewrite /data/local/tmp into a Windows path in adb's
    # arguments, so it is told not to -- which means every path a native tool gets is C:/...
    export MSYS_NO_PATHCONV=1
    SDK=${ANDROID_HOME:-${LOCALAPPDATA:-}/Android/Sdk}
    NDK=${TIKO_ANDROID_NDK:-${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-$(ls -d "$SDK"/ndk/* 2>/dev/null | sort -V | tail -1)}}}
    CC=$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin/clang.exe
    ADBX=$SDK/platform-tools/adb.exe
    [ -x "$CC" ] || { echo "posixgen: no NDK clang at '$CC' (set ANDROID_NDK_HOME)" >&2; exit 2; }
    [ -x "$ADBX" ] || { echo "posixgen: no adb at '$ADBX' (set ANDROID_HOME)" >&2; exit 2; }
    "$ADBX" get-state >/dev/null 2>&1 || { echo "posixgen: adb reaches no device" >&2; exit 2; }
    WKW=$(cygpath -m "$WK")
    "$CC" --target=$ATRIPLE -std=c11 -Wall -Werror -Wno-pointer-compare \
        -Wno-unused-function -o "$WKW/posixgen" "$(cygpath -m "$ROOT")/build/posixgen.c" -I "$(cygpath -m "$ROOT")/build"
    "$ADBX" push "$WKW/posixgen" /data/local/tmp/tiko-posixgen >/dev/null
    HOSTD=$("$ADBX" shell 'uname -sr; uname -m' | tr -d '\r' | tr '\n' ' ' | sed 's/ $//')
    DAPI=$("$ADBX" shell getprop ro.build.version.sdk | tr -d '\r')
    LIBC="Bionic, device API $DAPI, NDK $(basename "$NDK") headers at API 29"
    "$ADBX" shell "chmod 755 /data/local/tmp/tiko-posixgen && /data/local/tmp/tiko-posixgen $TARGET '$HOSTD' '$("$CC" --version | head -1)' '$LIBC'; rc=\$?; rm -f /data/local/tmp/tiko-posixgen; exit \$rc" \
        | tr -d '\r' > "$WK/out.ti"
else
    CC=${CLANG:-${TIKO_CLANG:-clang}}
    command -v "$CC" >/dev/null 2>&1 || { echo "posixgen: no C compiler '$CC' (set CLANG)" >&2; exit 2; }

    case "$TARGET" in
        linux-*) LIBC=$(ldd --version 2>&1 | head -1) ;;
        macos-*) LIBC="macOS SDK $(xcrun --show-sdk-version 2>/dev/null || echo '?')" ;;
    esac

    "$CC" -std=c11 -Wall -Werror -Wno-pointer-compare -Wno-unused-function -o "$WK/posixgen" build/posixgen.c -I build
    "$WK/posixgen" "$TARGET" "$(uname -sr) $(uname -m)" "$("$CC" --version | head -1)" "$LIBC" > "$WK/out.ti"
fi

RT_OUT=lib/rt/src/inc/sysbind/$TARGET-posix.ti
PKG_OUT=pkg/sys/posix/$TARGET-posix.ti
if [ "$CHECK" = "1" ]; then
    rc=0
    for f in "$RT_OUT" "$PKG_OUT"; do
        # The header names the host it was measured on; compare everything below it.
        sed '1,/^#pragma once/d' "$f" > "$WK/old.body" 2>/dev/null || : > "$WK/old.body"
        sed '1,/^#pragma once/d' "$WK/out.ti" > "$WK/new.body"
        if ! cmp -s "$WK/old.body" "$WK/new.body"; then
            echo "posixgen: $f differs from this host's measurement"; rc=1
        fi
    done
    [ "$rc" = "0" ] && echo "posixgen: $TARGET binding matches this host"
    exit $rc
fi
cp "$WK/out.ti" "$RT_OUT"
cp "$WK/out.ti" "$PKG_OUT"
echo "posixgen: $RT_OUT, $PKG_OUT ($(grep -c '^const ' "$RT_OUT") constants, $(grep -c '^type ' "$RT_OUT") types)"
