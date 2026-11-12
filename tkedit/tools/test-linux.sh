#!/bin/bash
# The Linux battery, under WSLg, on BOTH SDL video drivers (X11 via XWayland, and Wayland).
# Run from Windows Git Bash:
#   MSYS_NO_PATHCONV=1 wsl.exe -e bash /mnt/c/dev/tiko-lang/tkedit/tools/test-linux.sh [core]
# "core": only src/core's console suites (no app build, no window).
# Copies this checkout into $HOME/tebuild/<hash of the checkout>/: /mnt/c is slow, and the Linux
# and Windows builds must not share out/ or bin/. tkControls is the toolchain's vendor/tkControls,
# which copies libscintk.so beside the program. Never run it while the Windows battery
# runs: WSLg windows take the Windows focus (tkControls FINDINGS).
SRC=$(cd "$(dirname "$0")/.." && pwd)
TIKO=${TIKO:-/mnt/c/dev/tiko-lang/toolchains/tiko-linux/bin/tiko}
# SDL3 for Linux: Ubuntu ships none, nor does the toolchain; tiko-lang's
# examples/tkControls/tools/build-linux-libs.sh builds them, kept (gitignored) in linux-lib/.
LIB=${TK_LINUX_LIB:-$(cd "$SRC/../examples/tkControls/linux-lib" && pwd)}
W=$HOME/tebuild/$(echo "$SRC" | md5sum | cut -c1-10)
E=$W/tkedit
rm -rf "$W"; mkdir -p "$E"
echo "source: $SRC  build: $W"
copy() {     # copy <from> <to>
    ( cd "$1" && tar --exclude='./out' --exclude='*/out' --exclude='*.exe' --exclude='*.dll' \
          --exclude='*.bmp' --exclude='./linux-lib*' --exclude='./.git' --exclude='./bin' -cf - . ) \
        | ( cd "$2" && tar -xf - )
}
copy "$SRC" "$E"
mkdir -p "$E/bin"
export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir EGL_LOG_LEVEL=fatal LD_LIBRARY_PATH=$LIB
export TIKO_MODCACHE=$W/modcache
bad=0

build() {    # build <package dir>
    local out
    if ! out=$(cd "$E/$1" && "$TIKO" build --options "-p $LIB" 2>&1); then
        echo "$1: BUILD FAILED"; echo "$out" | head -30; bad=$((bad+1)); return 1
    fi
    [ -n "$out" ] && { echo "$1: build printed output (warnings?)"; echo "$out" | head -30; bad=$((bad+1)); }
    return 0
}

run() {      # run <name> <dir> <driver> <command...>
    local name=$1 dir=$2 drv=$3; shift 3
    local res rc line
    res=$(cd "$dir" && SDL_VIDEO_DRIVER=$drv timeout -k 10 300 "$@" 2>&1 | grep -v ZINK); rc=${PIPESTATUS[0]}
    echo "$res" | grep -E '^FAIL' | head -20
    line=$(echo "$res" | grep -E ' selftest: ' | tail -1)
    echo "$name [$drv]: ${line:-no summary line} (exit $rc)"
    echo "$line" | grep -q ' 0 failed' || bad=$((bad+1))
}

if build src/core; then
    run coreall "$E/src/core" none ./tests/bin/coreall.exe
fi
build src/design && run designall "$E/src/design" none ./tests/bin/designall.exe
# tkEdit LINKS IN the scanner (svc/parser): tiko-lang's bin/parser_linux_x86_64.a, which must be built by
# THIS compiler (its std module objects are one copy at the link). Made in the checkout when it is missing
# or older than the compiler, then copied to the build folder's bin/, where svc/parser's '#foreignlib'
# looks (four folders above it, as in the checkout).
parserlib() {
    local lib=$SRC/../bin/parser_linux_x86_64.a
    if ! { [ -f "$lib" ] && [ "$lib" -nt "$TIKO" ]; }; then
        ( cd "$SRC/.." && TIKO_SEED="$TIKO" bash build/build.sh Release --lib ) > "$W/parserlib.log" 2>&1 \
            || { echo "parser library: BUILD FAILED ($W/parserlib.log)"; bad=$((bad+1)); return 1; }
    fi
    mkdir -p "$W/bin" && cp -f "$lib" "$W/bin/"
}
if [ "${1:-}" != core ] && parserlib && build src/app; then
    # the self-test builds sample programs with this tiko (P4)
    export TKEDIT_TIKO=$TIKO
    for drv in x11 wayland; do
        run tkEdit "$E/bin" $drv ./tkedit --selftest
    done
fi
echo "suite runs failed: $bad"
exit $bad
