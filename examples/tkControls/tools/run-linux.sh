#!/bin/bash
# The Linux battery, under WSLg, BOTH SDL video drivers (X11 via XWayland, and Wayland).
# Run from Windows Git Bash:
#   MSYS_NO_PATHCONV=1 wsl.exe -e bash /mnt/c/dev/tiko-lang/examples/tkControls/tools/run-linux.sh [names...] [--runs N]
# (from a worktree, give that worktree's /mnt/c/... path to the script instead)
# Builds in $HOME/tkbuild/<hash of the checkout>: a copy of examples/tkControls, pkg/ and
# build/vendorfetch.sh (/mnt/c is slow, and Linux and Windows builds must not share out/ or the
# .exe names). TIKO_PKG is the copy's pkg/, whose vendor/tkControls fonts and libscintk.so
# vendorfetch.sh makes there. Needs SDL3 + SDL3_ttf + SDL3_image: the system's, or linux-lib/
# (tools/build-linux-libs.sh), or TK_LINUX_LIB.
# TK_DRIVERS narrows the SDL video drivers (default "x11 wayland"): a headless box under Xvfb
# has X11 only (docs/tiko-linux-arm64 L4, the Lima VM).
# The examples folder this script lives in, and its tiko-lang checkout (main or a worktree).
SRC=$(cd "$(dirname "$0")/.." && pwd)
TREE=$(cd "$SRC/../.." && pwd)
TIKO=${TIKO:-/mnt/c/dev/tiko-lang/toolchains/tiko-linux/bin/tiko}
LIB=${TK_LINUX_LIB:-}
[ -d "$SRC/linux-lib" ] && LIB=$SRC/linux-lib
# One build folder PER CHECKOUT, so parallel sessions never share one.
W=$HOME/tkbuild/$(echo "$SRC" | md5sum | cut -c1-10)
runs=1
names=()
while [ $# -gt 0 ]; do
    case "$1" in
        --runs) runs=$2; shift 2 ;;
        *) names+=("$1"); shift ;;
    esac
done
rm -rf "$W"; mkdir -p "$W"
echo "source: $SRC  build: $W"
mkdir -p "$W/examples/tkControls" "$W/build"
( cd "$SRC" && tar --exclude='./out' --exclude='*/out' --exclude='*.exe' --exclude='*.dll' \
      --exclude='*.bmp' --exclude='Inter-*.ttf' --exclude='CascadiaMono-*.ttf' \
      --exclude='FluentSystemIcons-*.ttf' --exclude='./linux-lib*' -cf - . ) | ( cd "$W/examples/tkControls" && tar -xf - )
( cd "$TREE" && tar --exclude='pkg/vendor/*/lib' --exclude='pkg/vendor/tkControls/fonts' \
      --exclude='*/scintk/bin' --exclude='*/scintk/out' -cf - pkg ) | ( cd "$W" && tar -xf - )
cp "$TREE/build/vendorfetch.sh" "$W/build/"
TIKO_VENDOR_CACHE=${TIKO_VENDOR_CACHE:-$HOME/.cache/tko-vendorfetch} sh "$W/build/vendorfetch.sh" --module tkControls \
    || { echo "vendorfetch.sh failed: no fonts or libscintk.so"; exit 1; }
# tkStatic links SDL3 statically: vendor/SDL3's archives (static/build.sh; a finished build is
# kept in the cache, so only the first run on a host pays for it).
case " ${names[*]} " in
    *" tkStatic "*|"  ")
        TIKO_VENDOR_CACHE=${TIKO_VENDOR_CACHE:-$HOME/.cache/tko-vendorfetch} sh "$W/build/vendorfetch.sh" --module SDL3 \
            || { echo "vendorfetch.sh failed: no static SDL3"; exit 1; } ;;
esac
# tkContacts, tkGridData, tkReportBarcode and the report suites read SQLite: vendor/sqlite3's library (built from source once, then cached).
case " ${names[*]} " in
    *" tkContacts "*|*" tkGridData "*|*" tkReportBarcode "*|*" tkReport "*|*" tkReportDef "*|*" tkReportDesigner "*|"  ")
        TIKO_VENDOR_CACHE=${TIKO_VENDOR_CACHE:-$HOME/.cache/tko-vendorfetch} sh "$W/build/vendorfetch.sh" --module sqlite3 \
            || { echo "vendorfetch.sh failed: no sqlite3"; exit 1; } ;;
esac
# tkBarcode links libzint (vendor/zint, built from source once, then cached); tkMeta's table, and so
# every designed form, imports it.
TIKO_VENDOR_CACHE=${TIKO_VENDOR_CACHE:-$HOME/.cache/tko-vendorfetch} sh "$W/build/vendorfetch.sh" --module zint \
    || { echo "vendorfetch.sh failed: no zint"; exit 1; }
export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir EGL_LOG_LEVEL=fatal
[ -n "$LIB" ] && export LD_LIBRARY_PATH=$LIB
export TIKO_PKG=$W/pkg
export TIKO_MODCACHE=$W/modcache          # per checkout, like the build folder
if [ ${#names[@]} -eq 0 ]; then
    for d in "$W"/examples/tkControls/*/; do [ -f "$d/selftest.tiko" ] && names+=("$(basename "$d")"); done
fi
bad=0
for n in "${names[@]}"; do
    d="$W/examples/tkControls/$n"
    if ! out=$(cd "$d" && "$TIKO" build ${LIB:+--options "-p $LIB"} 2>&1); then
        echo "$n: BUILD FAILED"; echo "$out" | head -20; bad=$((bad+1)); continue
    fi
    for drv in ${TK_DRIVERS:-x11 wayland}; do
        for r in $(seq 1 "$runs"); do
            res=$(cd "$d" && SDL_VIDEO_DRIVER=$drv timeout 300 ./selftest.exe 2>&1 | grep -v ZINK); rc=$?
            rc=${PIPESTATUS[0]}
            echo "$res" | grep -E '^FAIL' | head -20
            line=$(echo "$res" | grep -E ' selftest: ' | tail -1)
            echo "$n [$drv run $r]: ${line:-no summary line}"
            echo "$line" | grep -q ' 0 failed' || bad=$((bad+1))
        done
    done
done
echo "suite runs failed: $bad"
exit $bad
