#!/bin/sh
# posixgen.sh -- regenerate this POSIX host's binding: build/posixgen.c measures the C ABI
# listed in build/posix.spec and prints it as tiko.
#
#   build/posixgen.sh            on linux-x86_64: lib/rt/src/inc/sysbind/linux-x86_64-posix.ti
#                                and pkg/sys/posix/linux-x86_64-posix.ti (the same bytes)
#   build/posixgen.sh --check    regenerate into a temporary file and diff, writing nothing
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
[ "${1:-}" = "--check" ] && CHECK=1

case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)  TARGET=linux-x86_64 ;;
    Linux-aarch64) TARGET=linux-arm64 ;;
    Darwin-arm64)  TARGET=macos-arm64 ;;
    *) echo "posixgen: no tiko target for host $(uname -s)-$(uname -m)" >&2; exit 2 ;;
esac

CC=${CLANG:-${TIKO_CLANG:-clang}}
command -v "$CC" >/dev/null 2>&1 || { echo "posixgen: no C compiler '$CC' (set CLANG)" >&2; exit 2; }

case "$TARGET" in
    linux-*) LIBC=$(ldd --version 2>&1 | head -1) ;;
    macos-*) LIBC="macOS SDK $(xcrun --show-sdk-version 2>/dev/null || echo '?')" ;;
esac

WK=${TMPDIR:-/tmp}/posixgen.$$
mkdir -p "$WK"
trap 'rm -rf "$WK"' EXIT

"$CC" -std=c11 -Wall -Werror -Wno-pointer-compare -Wno-unused-function -o "$WK/posixgen" build/posixgen.c -I build
"$WK/posixgen" "$TARGET" "$(uname -sr) $(uname -m)" "$("$CC" --version | head -1)" "$LIBC" > "$WK/out.ti"

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
