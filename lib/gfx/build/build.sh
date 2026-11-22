#!/bin/sh
# build.sh -- build libtkogfx.
#
#   build/build.sh [Debug|Release|RelWithDebInfo] [target ...]
#
# FOUR TARGETS: windows-x86_64, linux-x86_64, macos-arm64 and linux-arm64 (docs/graphics
# RFC-0012, phase P1). Any host builds any of them -- the library is one `tiko -c`
# per target, and nothing here needs the target's SDK -- and with no target named
# the host's own is built. driver/window.ti picks the platform: the Win32 window on
# Windows, and on Linux and macOS, until their drivers land (X11 L1, Cocoa M1),
# driver/nodisplay: GFX_NULL and FBGFX=null screens work and a windowed SCREEN
# answers an error, as gfxlib2 does when no driver loads.
#
# windows-x86_64 IS THE MICROSOFT ABI (TARGET_WINDOWS_X86_64, added 2026-09-05), and
# there is no MSVC libfbgfx anywhere to fall back to: fbc's is MinGW, so it cannot go
# into an MSVC binary at all.
#
# THE LIBRARY IS HEADER-ONLY, so this is ONE translation unit. Every .ti under
# abi/, core/, driver/, raster/ and entry/ is included by src/all.tiko, and every
# routine below entry/ is `private`. That is deliberate -- RFC-0001 makes the
# entry-point layer the only public surface.
#
# THE COMPILER IS TIKO (bootstrap plan, phase G, 2026-10-10): the tree's bin/tiko, or
# TKOGFX_TIKO, which targets windows-x86_64 itself -- one step, no clang retarget. Measured
# when it changed: the same 368 functions and the same 83 public symbols as fbc's build.
# An fbc builds it only as the ORACLE, when TIKO_ORACLE_FBC names one -- to tell a
# library difference from a compiler difference; nothing shipped is built that way. That
# fbc must understand -z msvc (fbc-modern's working tree, 2026-09-05 or later): without it
# fbc emits the gnu triple and builds the wrong ABI without saying so, so that path
# refuses rather than falls back. The oracle builds windows-x86_64 only.

set -e

GFX_ROOT=$(cd "$(dirname "$0")/.." && pwd)

die( ) { echo "libtkogfx: $*" >&2; exit 2; }

CFG=${1:-Release}
case "$CFG" in
    Debug|Release|RelWithDebInfo|MinSizeRel) ;;
    *) die "unknown configuration '$CFG' (Debug, Release, RelWithDebInfo, MinSizeRel)" ;;
esac
shift 2>/dev/null || true

# The host decides the default target, the compiler's name and where LLVM is. On
# macOS that is Homebrew's LLVM: a bare clang there is Apple's, and llvm-ar and
# llvm-nm are not on PATH at all -- lib/rt/build/common.sh, which this follows.
# TKORT_AR and TKORT_NM are honoured too: package.sh's Linux recipe exports them for
# the runtime, and a distribution's LLVM is often only llvm-ar-19 / llvm-nm-19.
LLVMBIN=""
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) HOSTTARGET=windows-x86_64; EXE=.exe ;;
    Linux)                HOSTTARGET=linux-x86_64;   EXE=""
                          [ "$(uname -m)" = aarch64 ] && HOSTTARGET=linux-arm64 ;;
    Darwin)               HOSTTARGET=macos-arm64;    EXE=""
                          [ -d /opt/homebrew/opt/llvm/bin ] && LLVMBIN=/opt/homebrew/opt/llvm/bin/ ;;
    *) die "unsupported host '$(uname -s)' -- this builds on Windows, Linux or macOS" ;;
esac
TARGETS=${*:-$HOSTTARGET}

if [ -n "${TIKO_ORACLE_FBC:-}" ]; then
    FBC=$TIKO_ORACLE_FBC
    [ -x "$FBC" ] || die "no fbc at $FBC (TIKO_ORACLE_FBC)"
    CLANG=${CLANG:-${TIKO_CLANG:-"C:/Program Files/LLVM/bin/clang.exe"}}
    [ -x "$CLANG" ] || die "no clang at $CLANG (set CLANG)"
else
    TIKO=${TKOGFX_TIKO:-"$GFX_ROOT/../../bin/tiko$EXE"}
    [ -x "$TIKO" ] || die "no tiko at $TIKO -- build the compiler first (build/build.sh), or set TKOGFX_TIKO"
fi
AR=${TKOGFX_AR:-${TIKO_AR:-${TKORT_AR:-${LLVMBIN:+${LLVMBIN}llvm-ar}}}}
[ -n "$AR" ] || AR=$(command -v llvm-ar 2>/dev/null || echo "C:/Program Files/LLVM/bin/llvm-ar.exe")
[ -x "$AR" ] || die "no llvm-ar at $AR (set TKOGFX_AR)"
NM=${TIKO_NM:-${TKORT_NM:-${LLVMBIN:+${LLVMBIN}llvm-nm}}}
[ -n "$NM" ] || NM=$(command -v llvm-nm 2>/dev/null || echo "C:/Program Files/LLVM/bin/llvm-nm.exe")
[ -x "$NM" ] || die "no llvm-nm at $NM (set TIKO_NM) -- the archive's entry points are counted with it"

# -z msvc, or nothing -- the fbc path only. Probed rather than assumed.
mkdir -p "$GFX_ROOT/obj"
if [ -n "${TIKO_ORACLE_FBC:-}" ]; then
    printf 'end 0\n' > "$GFX_ROOT/obj/.zprobe.bas"
    if "$FBC" -c -gen llvm -z msvc -m zprobe "$GFX_ROOT/obj/.zprobe.bas" -o "$GFX_ROOT/obj/.zprobe.o" 2>&1 | grep -q 'Invalid command-line option'; then
        die "$FBC does not understand -z msvc -- it takes an fbc built from a working tree, 2026-09-05 or later"
    fi
    rm -f "$GFX_ROOT/obj/.zprobe.bas" "$GFX_ROOT/obj/.zprobe.o" "$GFX_ROOT/obj/zprobe.ll"
fi

case "$CFG" in
    Debug)          OPT=0 ;;
    Release)        OPT=2 ;;
    RelWithDebInfo) OPT=2 ;;
    # clang's own '-Os', which it honours -- this script calls clang directly.
    MinSizeRel)     OPT=s ;;
esac

for target in $TARGETS; do
    case "$target" in
        windows-x86_64|linux-x86_64|macos-arm64|linux-arm64) ;;
        *) die "unsupported target '$target' (windows-x86_64, linux-x86_64, macos-arm64, linux-arm64)" ;;
    esac
    if [ -n "${TIKO_ORACLE_FBC:-}" ] && [ "$target" != "windows-x86_64" ]; then
        die "the fbc oracle builds windows-x86_64 only, not '$target'"
    fi

    OBJDIR="$GFX_ROOT/obj/$target/$CFG"
    LIBDIR="$GFX_ROOT/lib/$target"
    rm -rf "$OBJDIR"; mkdir -p "$OBJDIR" "$LIBDIR"

    # The archive goes FIRST, so a failed build cannot leave a stale one behind
    # for the next tool to read as a complete library. lib/rt's build.sh records
    # five separate incidents of exactly that.
    rm -f "$LIBDIR/libtkogfx.a" "$LIBDIR/.config"

    # -m NAMES THE MAIN MODULE, AND all.tiko MUST NOT BE IT. Compiled as the main
    # module fbc emits a `main` into it, and the archive then collides with every
    # program that links it:
    #
    #     libtkogfx.a(all.o) : error LNK2005: main already defined
    #
    # Naming a module that does not exist in this build makes every module here a
    # NON-main one, which is what a library wants -- the same device fbc's own
    # suite uses when it passes -m fbc-tests to every test module.
    # THE TREE'S OWN HEADERS (phase H): windows.bi, crt/ and the rest from tiko-lang's
    # inc/, ahead of fbc's own. Without it they came from fbc-modern's src/inc.
    GFXINC=""
    [ -d "$GFX_ROOT/../../inc" ] && GFXINC="-i $(cd "$GFX_ROOT/../../inc" && pwd)"
    if [ -z "${TIKO_ORACLE_FBC:-}" ]; then
        # tiko: one step, for any of the three targets. '-O s' is not tiko's; MinSizeRel is -O2.
        TOPT=$OPT; [ "$TOPT" = "s" ] && TOPT=2
        # --keep-temps leaves all.o.ll, which the function count below reads, as fbc's
        # -r left all.ll.
        ( cd "$OBJDIR" && "$TIKO" -c "$GFX_ROOT/src/all.tiko" -m __tkogfx_lib $GFXINC \
            -target "$target" -mt "-O$TOPT" --keep-temps -o "$OBJDIR/all.o" ) > "$OBJDIR/tiko.log" 2>&1 \
            || { sed 's/^/    /' "$OBJDIR/tiko.log" >&2; die "tiko failed -- see $OBJDIR/tiko.log"; }
        [ -f "$OBJDIR/all.o" ] || die "tiko produced no object -- see $OBJDIR/tiko.log"
        mv -f "$OBJDIR/all.o.ll" "$OBJDIR/all.ll"
    else
    # fbc takes only a .bas as a source, so the oracle compiles a one-line .bas that
    # includes all.tiko by a native path (fbc does not see MSYS paths); its own includes
    # resolve from all.tiko's directory as before.
    printf '#include once "%s"\n' "$(cd "$GFX_ROOT/src" && { pwd -W 2>/dev/null || pwd; })/all.tiko" > "$OBJDIR/all.bas"
    ( cd "$OBJDIR" && "$FBC" -c "$OBJDIR/all.bas" -m __tkogfx_lib $GFXINC \
        -target win64 -gen llvm -r -z msvc -mt \
        -o "$OBJDIR/all.o" ) > "$OBJDIR/fbc.log" 2>&1 \
        || { sed 's/^/    /' "$OBJDIR/fbc.log" >&2; die "fbc failed -- see $OBJDIR/fbc.log"; }
    [ -f "$OBJDIR/all.ll" ] || die "fbc produced no .ll -- see $OBJDIR/fbc.log"

    "$CLANG" --target=x86_64-pc-windows-msvc -march=x86-64 "-O$OPT" \
        -Wno-override-module "$OBJDIR/all.ll" -c -o "$OBJDIR/all.o" \
        > "$OBJDIR/clang.log" 2>&1 \
        || { sed 's/^/    /' "$OBJDIR/clang.log" >&2; die "clang failed -- see $OBJDIR/clang.log"; }
    fi

    "$AR" rcs "$LIBDIR/libtkogfx.a" "$OBJDIR/all.o"

    # The configuration, beside the archive. lib/<target>/ holds ONE archive that
    # every configuration overwrites, so without this a tool told "Release" reads
    # whatever was built last and agrees with itself.
    echo "$CFG" > "$LIBDIR/.config"

    # REPORT WHAT IS IN THE ARCHIVE, NOT WHAT WAS IN THE IR. Every routine below the
    # entry layer is `private`, so only what an entry point reaches survives; a
    # build line reporting the IR count would overstate the archive. On Mach-O the
    # symbols carry a leading underscore.
    ir=$(grep -c "^define" "$OBJDIR/all.ll" || echo 0)
    code=$("$NM" --defined-only "$LIBDIR/libtkogfx.a" 2>/dev/null | grep -c " T \| t " || true)
    pub=$("$NM" --defined-only "$LIBDIR/libtkogfx.a" 2>/dev/null | awk '$2=="T"{print $3}' | grep -cE "^_?fb_(Gfx|h)" || true)
    echo "build: $target/libtkogfx.a [$CFG] -- $ir functions compiled, $code reached the archive, $pub public entry points"
    # NO ENTRY POINT IS A BROKEN BUILD, not a quiet one: every graphics program would
    # fail to link against it, and package.sh would ship it.
    if [ "$pub" = "0" ]; then
        rm -f "$LIBDIR/libtkogfx.a" "$LIBDIR/.config"
        die "$target/libtkogfx.a exports no fb_Gfx* entry point -- see $OBJDIR/tiko.log"
    fi
done
echo "build: ok"
