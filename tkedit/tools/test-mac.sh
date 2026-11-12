#!/bin/bash
# The macOS battery (cocoa), run ON THE MAC from its tiko-lang checkout:
#   bash tkedit/tools/test-mac.sh [core]       "core": only src/core's console suites
# From Windows, as a script file through a login shell (Homebrew is not on a non-login PATH):
#   ssh mac zsh -l <script that runs this>
# Builds in place: the Mac checkout is its own clone, so bin/ and out/ are never shared with
# Windows. The compiler is $TIKO, else the tree's bin/tiko (build/build.sh), else the toolchain's;
# the scanner tkEdit links in, bin/parser_macos_arm64.a, is built with it (parserlib below). It reads
# THIS tree's pkg/, whose static SDL3 archives, vendor/tkControls fonts and scintk build/vendorfetch.sh
# puts in place -- tkEdit links them in, so no Homebrew SDL3 is needed at run time.
# The window opens on the logged-in desktop: the Mac must be awake and unlocked.
SRC=$(cd "$(dirname "$0")/.." && pwd)
TREE=$(cd "$SRC/.." && pwd)
if [ -z "${TIKO:-}" ]; then
    TIKO=$TREE/bin/tiko
    [ -x "$TIKO" ] || TIKO=$TREE/toolchains/tiko-macos/bin/tiko
fi
export TIKO_PKG=${TIKO_PKG:-$TREE/pkg}
# a tree-built compiler links against the toolchain's libraries, which it does not find alone
if [ -z "${TIKO_LIBPATH:-}" ] && [ -d "$TREE/toolchains/tiko-macos/lib/macos-arm64" ]; then
    export TIKO_LIBPATH=$TREE/toolchains/tiko-macos/lib/macos-arm64
fi
export TIKO_MODCACHE=${TIKO_MODCACHE:-$SRC/out/modcache}
bad=0

build() {    # build <package dir>
    local out
    if ! out=$(cd "$SRC/$1" && "$TIKO" build 2>&1); then
        echo "$1: BUILD FAILED"; echo "$out" | head -30; bad=$((bad+1)); return 1
    fi
    # Homebrew's bottles are built for a newer macOS than tiko's 13.0 minimum: ld64 warns once per dylib
    out=$(echo "$out" | grep -v -E "building for macOS-13\.0, but linking with dylib")
    [ -n "$out" ] && { echo "$1: build printed output (warnings?)"; echo "$out" | head -30; bad=$((bad+1)); }
    return 0
}

run() {      # run <name> <dir> <command...>
    local name=$1 dir=$2; shift 2
    local res rc line
    # macOS has no timeout(1): perl's alarm ends a hung self-test
    res=$(cd "$dir" && perl -e 'alarm 300; exec @ARGV' "$@" 2>&1); rc=$?
    echo "$res" | grep -E '^FAIL' | head -20
    line=$(echo "$res" | grep -E ' selftest: ' | tail -1)
    echo "$name [macos]: ${line:-no summary line} (exit $rc)"
    [ $rc -eq 0 ] || bad=$((bad+1))
}

# tkEdit LINKS IN the scanner (svc/parser): tiko-lang's bin/parser_<os>_<arch>.a, which must be built by
# THIS compiler (its std module objects are one copy at the link). Made here when it is missing or older
# than the compiler; a log of the build goes to out/parserlib.log.
parserlib() {
    local lib=$TREE/bin/parser_macos_arm64.a
    [ -f "$lib" ] && [ "$lib" -nt "$TIKO" ] && return 0
    mkdir -p "$SRC/out"
    ( cd "$TREE" && TIKO_SEED="$TIKO" bash build/build.sh Release --lib ) > "$SRC/out/parserlib.log" 2>&1 \
        || { echo "parser library: BUILD FAILED (out/parserlib.log)"; bad=$((bad+1)); return 1; }
}

build src/core && run coreall "$SRC/src/core" ./tests/bin/coreall.exe
build src/design && run designall "$SRC/src/design" ./tests/bin/designall.exe
if [ "${1:-}" != core ] && parserlib && build src/app; then
    # the self-test builds sample programs with this tiko (P4)
    export TKEDIT_TIKO=$TIKO
    run tkEdit "$SRC/bin" ./tkedit --selftest
fi
echo "suites failed: $bad"
exit $bad
