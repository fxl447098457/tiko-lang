#!/bin/sh
# test.sh -- build everything and run the suite.
#
#   build/test.sh [suite...] [--accept] [--filter <pat>] [-j N] [-v] [--no-build]
#
# --accept rewrites golden files. The resulting diff is reviewed like code; a commit
# that accepts goldens without saying why does not land (docs/plan/13 section 3).
#
# THE BUILD IS SKIPPED WHEN NOTHING IT DEPENDS ON HAS CHANGED. Building tiko-lang is
# one fbc invocation over every module and takes about 80 seconds -- more than three
# times the suite itself -- and it ran unconditionally, so re-running one --filter,
# accepting a golden, or re-reading a failure each paid it for nothing.
#
# What counts as a dependency is deliberately COARSE: for the compiler, anything under
# src/ plus the source list and build.sh; for the runner, anything under tools/. A .ti
# is included by whatever includes it and 23 of the .tiko files under src/ are #included
# rather than compiled, so per-file dependency tracking is not something a timestamp
# can do honestly -- and being wrong in that direction means NOT rebuilding, which is
# the expensive kind of wrong.
#
# TIMESTAMPS ALONE ARE NOT ENOUGH, because they cannot tell a Debug binary from a
# Release one: 'build/build.sh Release' leaves bin/tiko newer than every source, and
# the Debug suite would then run the Release binary and report nothing about it. So
# build.sh -- either peer -- records what it built in build/obj/.build-stamp, and this
# rebuilds whenever that is missing, is for another configuration, or names another
# compiler. The compiler ITSELF is a dependency too: a rebuilt stage0 changes what
# every one of these binaries is.
#
# TIKO_TEST_REBUILD=1 forces the build; --no-build skips it even when stale.

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) EXT=".exe" ;;
    *)                    EXT="" ;;
esac

CFG=Debug
TIKO="$ROOT/bin/tiko$EXT"
RUNNER="$ROOT/bin/tiko-test$EXT"
STAMP="$ROOT/build/obj/.build-stamp"

# --no-build is ours, not the runner's: strip it before the arguments are passed on.
ARGS=""
NOBUILD=0
for a in "$@"; do
    if [ "$a" = "--no-build" ]; then
        NOBUILD=1
    else
        ARGS="$ARGS $a"
    fi
done

# Any FILE newer than the reference, in any of these? '-print -quit' stops at the
# first hit rather than walking the whole tree to build a list nothing reads.
#
# '-type f' IS LOAD-BEARING, not tidiness. fbc writes its objects beside the sources
# and deletes them after linking, so every directory under src/ ends the build with an
# mtime NEWER THAN THE EXECUTABLE it just produced -- and a directory-inclusive test
# therefore says 'stale' immediately after a successful build, every time, which is
# exactly the bug this guard exists to remove. The '*.o' exclusion is the same hazard
# from the other side: one left behind by an interrupted build would do it too.
newer_than( ) {
    ref=$1
    shift
    for inp in "$@"; do
        [ -e "$inp" ] || continue
        # __pycache__ is a byproduct of running a tool, never an input (review BLD-04).
        if [ -n "$(find "$inp" -type f ! -name '*.o' ! -name '*.pyc' ! -path '*/__pycache__/*' \
                -newer "$ref" -print -quit 2>/dev/null)" ]; then
            return 0
        fi
    done
    return 1
}

# The stage0 build.sh would use now: TIKO_SEED, else the default seed.
. "$ROOT/build/defaultseed.sh"
WANTCC=${TIKO_SEED:-}
if [ -z "$WANTCC" ]; then
    case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) _hw=1 ;; *) _hw=0 ;; esac
    WANTCC=$(default_seed "$ROOT" "$_hw" || true)
fi
STALE=0
if [ "${TIKO_TEST_REBUILD:-0}" = "1" ]; then
    STALE=1
elif [ ! -x "$TIKO" ] || [ ! -x "$RUNNER" ] || [ ! -f "$STAMP" ]; then
    STALE=1
else
    STAMPED=$(cat "$STAMP")
    STAMPCFG=${STAMPED%%|*}
    STAMPCC=${STAMPED#*|}
    if [ "$STAMPCFG" != "$CFG" ]; then
        STALE=1
    elif [ -n "$WANTCC" ] && [ "$STAMPCC" != "$WANTCC" ]; then
        # A DIFFERENT STAGE0 than the one bin/ was built with, chosen as build.sh chooses
        # it -- so a bin/ an fbc built is rebuilt once the seed is the default.
        STALE=1
    # pkg/ AND inc/ ARE INPUTS: the compiler imports std/containers and std/fs from pkg/ and
    # builds against the tree's inc/, so an edit there left a stale bin/ "up to date".
    elif newer_than "$TIKO" "$ROOT/src" "$ROOT/pkg" "$ROOT/inc" "$ROOT/build/sources.txt" \
                    "$ROOT/build/build.sh" "$STAMPCC"; then
        STALE=1
    elif newer_than "$RUNNER" "$ROOT/tools" "$STAMPCC"; then
        STALE=1
    fi
fi

if [ "$NOBUILD" = "1" ]; then
    if [ ! -x "$TIKO" ] || [ ! -x "$RUNNER" ]; then
        echo "test: --no-build, but bin/tiko$EXT or bin/tiko-test$EXT is missing" >&2
        exit 3
    fi
    STALE=0
fi

if [ "$STALE" = "1" ]; then
    "$ROOT/build/build.sh" "$CFG" --test-runner --no-dll
else
    echo "build: tiko-lang [$CFG] up to date"
fi

# THE RUNTIME UNDER TEST IS THE TREE'S (review BLD-01, 2026-10-24). Every RUN test linked the
# gitignored, hand-packaged toolchains/ runtime, so a lib/rt change was invisible to the suite
# until a repackage -- and nothing asserted the two were the same. The tests now name
# build/obj/rtlib/<target>: the packaged directory (its import libraries, fbcunit, libtkogfx),
# with libfb.a and libfbmt.a built from lib/rt over it. Rebuilt when lib/rt changes.
# TIKO_TEST_PACKAGED_RT=1 tests the packaged runtime instead, as before.
rt_overlay( ) {
    _t=$1 _host=$2
    _pkg="$ROOT/toolchains/tiko-$_host/lib/$_t"
    _ovl="$ROOT/build/obj/rtlib/$_t"
    if [ ! -d "$_pkg" ]; then
        echo "test: no packaged $_pkg -- RUN tests that link will fail (seed/fetch-seed.sh, then lay it out)" >&2
        return 0
    fi
    if [ "${TIKO_TEST_PACKAGED_RT:-0}" = "1" ]; then
        rm -rf "$_ovl" && mkdir -p "$_ovl" && cp -r "$_pkg/." "$_ovl/"
        echo "test: runtime -- the PACKAGED one (TIKO_TEST_PACKAGED_RT=1)"
        return 0
    fi
    if [ -f "$_ovl/.tree-rt" ] && ! newer_than "$_ovl/.tree-rt" "$ROOT/lib/rt/src" "$ROOT/lib/rt/build" "$_pkg"; then
        echo "test: runtime -- the tree's lib/rt [$_t], up to date"
        return 0
    fi
    echo "test: runtime -- building the tree's lib/rt [$_t]"
    TKORT_TIKO="$TIKO" bash "$ROOT/lib/rt/build/build.sh" Release "$_t" > "$ROOT/build/obj/rtlib.log" 2>&1 || {
        tail -5 "$ROOT/build/obj/rtlib.log" >&2
        echo "test: lib/rt did not build for $_t (build/obj/rtlib.log)" >&2
        exit 4
    }
    rm -rf "$_ovl" && mkdir -p "$_ovl" && cp -r "$_pkg/." "$_ovl/"
    for _a in "$ROOT/lib/rt/lib/$_t"/libfb*.a "$ROOT/lib/rt/lib/$_t"/fbrt0*.o; do
        [ -f "$_a" ] && cp -f "$_a" "$_ovl/"
    done
    : > "$_ovl/.tree-rt"
}
mkdir -p "$ROOT/build/obj"
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) rt_overlay windows-x86_64 windows ;;
    Linux)                if [ "$(uname -m)" = "aarch64" ]; then rt_overlay linux-arm64 linux-arm64
                          else rt_overlay linux-x86_64 linux; fi ;;
    Darwin)               rt_overlay macos-arm64 macos ;;
esac

cd "$ROOT"
exec "./bin/tiko-test$EXT" $ARGS
