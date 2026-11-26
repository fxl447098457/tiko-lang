#!/bin/sh
# aapcsig.sh -- the AAPCS64 signature lane: tiko's lowering against clang's.
#
#   build/aapcsig.sh                         macos-arm64 (Apple's AAPCS64)
#   build/aapcsig.sh --target linux-arm64    generic AAPCS64 (docs/tiko-linux-arm64)
#   build/aapcsig.sh --target android-arm64  generic AAPCS64 under Bionic (docs/tiko-android A3)
#
# tests/abi/apple/sig.c and sig.tiko declare the same shapes -- integer aggregates of 1 to
# 17 bytes, HFAs of 1 to 5 floats and doubles (nested, arrayed, a union), mixed float and
# integer, and register-exhausting prefixes -- passed and returned by value, called in
# both directions. Both are compiled to LLVM IR for the target's triple
# (arm64-apple-macosx13.0 or aarch64-unknown-linux-gnu), clang's by clang and tiko's by
# bin/tiko, and build/aapcsig.py compares every signature.
#
# WHY: no Mac is needed. The registers an argument travels in are decided by the IR
# signature, so matching clang's -- the platform's own C compiler -- is the static half
# of the ABI. The running half (a C library called and calling back) needs the Mac, or the
# Linux VM on it: build/aapcslane.sh.
#
# Needs clang (TIKO_CLANG, else on PATH) and python. Exits 1 on any difference.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) EXT=".exe" ;;
    *) EXT="" ;;
esac
TKO="$ROOT/bin/tiko$EXT"
[ -x "$TKO" ] || { echo "aapcsig: build tiko first (build/build.sh)" >&2; exit 3; }
CLANG=${TIKO_CLANG:-clang}
command -v "$CLANG" > /dev/null 2>&1 || { echo "aapcsig: no clang (set TIKO_CLANG)" >&2; exit 3; }
PY=${PYTHON:-python}
command -v "$PY" > /dev/null 2>&1 || PY=python3

TGT=macos-arm64
if [ "${1:-}" = "--target" ]; then TGT=${2:-}; fi
case "$TGT" in
    macos-arm64) T=arm64-apple-macosx13.0 ;;
    linux-arm64) T=aarch64-unknown-linux-gnu ;;
    android-arm64) T=aarch64-linux-android29 ;;
    *) echo "aapcsig: no AAPCS64 target '$TGT' (macos-arm64, linux-arm64 or android-arm64)" >&2; exit 3 ;;
esac
W="$ROOT/build/.aapcsig/$TGT"
mkdir -p "$W"
"$CLANG" -target $T -O0 -S -emit-llvm "$ROOT/tests/abi/apple/sig.c" -o "$W/c.ll" || exit 2
"$TKO" -target $TGT --emit-ir "$ROOT/tests/abi/apple/sig.tiko" > "$W/t.ll" || exit 2
# The IR must also be IR clang accepts for the target, or the comparison proves nothing.
"$CLANG" -target $T -Wno-override-module -c "$W/t.ll" -o "$W/t.o" || exit 2
"$PY" -I "$ROOT/build/aapcsig.py" "$W/c.ll" "$W/t.ll"
