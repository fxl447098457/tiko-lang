#!/bin/sh
# common.sh -- configuration shared by every tiko-rt build script.
#
# Sourced, never executed:  . "$(dirname "$0")/common.sh"
#
# Everything target- or toolchain-specific lives here and nowhere else, so that
# adding a target is one edit rather than five.

# ------------------------------------------------------------------ paths

RT_ROOT=$(cd "$(dirname "$0")/.." && pwd)

# THE COMPILER THAT BUILDS tiko-rt is tiko (bootstrap plan, phases R and X,
# 2026-10-10): the tree's own bin/tiko -- build/package.sh builds it first -- or
# TKORT_TIKO. Measured when it changed: the tiko-built archives define exactly the
# global symbols the fbc-built ones did, on windows-x86_64, win64 and linux-x86_64.
#
# fbc and fbc-modern's tree are the ORACLE scripts' business, and live in oracle.sh:
# nothing that builds tiko-rt reads them.
if [ -z "${TKORT_TIKO:-}" ]; then
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) TKORT_TIKO="$RT_ROOT/../../bin/tiko.exe" ;;
        *)                    TKORT_TIKO="$RT_ROOT/../../bin/tiko" ;;
    esac
fi

# clang. fbc's -gen llvm hands the .ll to clang -c, and looks for a
# target-prefixed <target>-clang.exe that does not exist: one clang serves every
# target through --target. Absolute, and with .exe on Windows. This is the same
# workaround gate-win.sh in fbc-modern uses, for the same reason.
# TIKO_CLANG FIRST, as build/toolchain.sh reads it: this was the one place it was ignored.
# ON macOS, HOMEBREW'S LLVM, which tiko itself uses (codegen/toolchain.tiko): a bare 'clang'
# there is Apple's, and llvm-ar and llvm-nm are not on PATH at all (docs/tiko-macos FACTS).
[ "$(uname -s)" = "Darwin" ] && [ -d /opt/homebrew/opt/llvm/bin ] && TKORT_LLVMBIN=/opt/homebrew/opt/llvm/bin/
if [ -z "${CLANG:-}" ]; then
    CLANG=${TIKO_CLANG:-${TKORT_LLVMBIN:+${TKORT_LLVMBIN}clang}}
    [ -n "$CLANG" ] || CLANG=$(command -v clang 2>/dev/null || echo "/c/Program Files/LLVM/bin/clang.exe")
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            case $CLANG in *.exe) ;; *) CLANG="$CLANG.exe" ;; esac ;;
    esac
fi
export CLANG

# llvm-ar. D13: the toolchain is 100% LLVM -- llvm-ar, not the MinGW ar.
if [ -z "${TKORT_AR:-}" ]; then
    TKORT_AR=${TIKO_AR:-${TKORT_LLVMBIN:+${TKORT_LLVMBIN}llvm-ar}}
    [ -n "$TKORT_AR" ] || TKORT_AR=$(command -v llvm-ar 2>/dev/null || echo "/c/Program Files/LLVM/bin/llvm-ar.exe")
fi
if [ -z "${TKORT_NM:-}" ]; then
    TKORT_NM=${TIKO_NM:-${TKORT_LLVMBIN:+${TKORT_LLVMBIN}llvm-nm}}
    [ -n "$TKORT_NM" ] || TKORT_NM=$(command -v llvm-nm 2>/dev/null || echo "/c/Program Files/LLVM/bin/llvm-nm.exe")
fi

# ------------------------------------------------------------------ targets

# The targets of R3, as amended 2026-09-04. Any other target is not a gap to be
# filled later: it is out of scope, and the build refuses it rather than guessing.
#
# X86-64 IS THE SUPPORTED ARCHITECTURE, and win32 is back in the Windows family
# (2026-11-08) after D14 removed it: the MinGW ABI under i686-w64-windows-gnu,
# whose msvcrt links no UCRT update. Linux and macOS have no 32-bit member.
#
# ARM64 is considered and not implemented -- fbc-modern refuses aarch64 outright
# (error 83), so there is no runtime to build and no fbc archive to gate against.
# RFC-0007 section 9.
RT_TARGETS="win64 linux-x86_64 win32"

# BUILD-ONLY TARGETS. Buildable, and deliberately NOT in RT_TARGETS, because
# RT_TARGETS is what gate.sh, symbols.sh and diff.sh validate against -- leaving
# windows-x86_64 out of it is what makes those three refuse it with the message they
# already have, rather than accepting it and failing somewhere less obvious.
#
# windows-x86_64 is the Microsoft ABI (docs/tiko-rt/RFC-0006). It CANNOT be gated:
# the gate works by dropping this archive into fbc's own MinGW link line, and an
# MSVC-ABI archive cannot link there. RFC-0006 section 5 is the open question of
# what replaces that, and until it is answered this target is built and not
# validated. Nothing should be shipped from it.
#
# macos-arm64 (docs/tiko-macos RFC-0001) is build-only for the same reason as ARM64 above:
# fbc has no aarch64, so there is nothing to gate it against. Its oracle is tiko's own
# linux-x86_64 output, compared by lib/rt/build/darwinlane.sh on the Mac.
RT_BUILD_ONLY_TARGETS="windows-x86_64 macos-arm64 win64ucrt"

# Include path: tiko-rt's own src/, then tiko-lang's inc/ (phase H, 2026-10-10), which
# supplies crt/long.bi -- the only header lint lets through. It was fbc-modern's src/inc
# until then.
#
# Note this also puts fb/*.bi, string.bi and the containers within reach -- all
# of them BANNED by the freestanding subset. lint.sh is what keeps them out;
# the include path cannot.
RT_INC="$RT_ROOT/src $(cd "$RT_ROOT/../../inc" && pwd)"

rt_incflags( ) {
    for d in $RT_INC; do printf -- '-i %s ' "$d"; done
}

rt_is_target( ) {
    # __t, NOT t. Shell functions share the caller's scope, and build.sh validates
    # with `for t in $TARGETS; do rt_is_target "$t" ...`. Using t here CLOBBERED the
    # caller's loop variable: every rejection named the LAST entry of RT_TARGETS
    # instead of the target actually asked for, so `build.sh Debug win32` reported
    # "unsupported target 'linux-x86_64'" -- naming a target that IS supported.
    # Found 2026-09-04 while narrowing RT_TARGETS for RFC-0007 phase 3.
    for __t in $RT_TARGETS; do [ "$1" = "$__t" ] && return 0; done
    return 1
}

# ...AND THE WIDER SET build.sh ACCEPTS. Separate from rt_is_target on purpose;
# see RT_BUILD_ONLY_TARGETS above.
rt_is_buildable( ) {
    for __t in $RT_TARGETS $RT_BUILD_ONLY_TARGETS; do
        [ "$1" = "$__t" ] && return 0
    done
    return 1
}

# THE TRIPLE FOR A TARGET THAT DOES NOT RETARGET, which is what the C residue
# needs: the FreeBASIC modules get their triple from fbc, but a .c compiled here
# has to be told. Kept beside rt_clang_triple so the two cannot drift.
#
# EVERY TARGET BY NAME. An unknown one used to fall through to the Windows triple, which
# would have compiled a new target's C files for MinGW without a word (docs/tiko-macos
# RFC-0001 section 1 lists that fall-through among the hazards).
rt_target_triple( ) {
    case "$1" in
        linux-x86_64)          echo "x86_64-pc-linux-gnu" ;;
        macos-arm64)           echo "arm64-apple-macosx13.0" ;;
        win64|windows-x86_64)  echo "x86_64-w64-windows-gnu" ;;
        win64ucrt)             echo "x86_64-w64-windows-gnu" ;;
        win32)                 echo "i686-w64-windows-gnu" ;;
        *) echo "rt_target_triple: no triple for target '$1'" >&2; return 1 ;;
    esac
}

# THE ABI DEFINE THE SOURCES SEE. fbc compiles windows-x86_64 AS win64 (it has no
# MSVC target), so __FB_WIN64__ is defined either way and no built-in symbol
# tells the two ABIs apart. The sources need to: UCRT spells the stdio stream
# accessor __acrt_iob_func where MinGW spells it __iob_func, and there is no
# __mingw_sprintf at all. Same mechanism as -d ENABLE_MT.
rt_abi_define( ) {
    case "$1" in
        windows-x86_64) echo "-d TKORT_MSVC -d TKORT_FBCALL= -d TKORT_STDCALL= -d TKORT_CDECL=" ;;
        win64ucrt)      echo "-d TKORT_UCRT -d TKORT_FBCALL=cdecl -d TKORT_STDCALL= -d TKORT_CDECL=" ;;
        win32)          echo "-d TKORT_FBCALL=stdcall -d TKORT_STDCALL=stdcall -d TKORT_CDECL=cdecl" ;;
        *)      echo "-d TKORT_FBCALL=cdecl -d TKORT_STDCALL= -d TKORT_CDECL=" ;;
    esac
}

# win32 takes NO define, like win64: it is the MinGW ABI, and the sources' MinGW
# spellings (__iob_func, strcasecmp) are the ones its msvcrt resolves.

# THE TRIPLE clang IS GIVEN, or empty when fbc's own assemble step is right.
#
# Measured 2026-09-04 (RFC-0006 section 12): clang's --target OVERRIDES the
# 'target triple' line fbc writes into the .ll, and the object that comes out is
# symbol-for-symbol identical to one built from an .ll whose line was rewritten.
# So the IR needs no editing -- only the assemble step changes.
rt_clang_triple( ) {
    case "$1" in
        windows-x86_64) echo "x86_64-pc-windows-msvc" ;;
        *)          echo "" ;;
    esac
}

# ------------------------------------------------------------------ flags

# Configuration flags. Note what is ABSENT: -exx and -e are NEVER used, on any
# configuration. They insert bounds and null checks that call into the runtime,
# which is the code being defined. See docs/tiko-rt/RFC-0003 section 3.
# The -O level fbc would have passed to clang, for the targets where this script
# calls clang itself. fbc computes it the same way -- 'clopts += "-O" & level'.
rt_opt_level( ) {
    case "$1" in
        Debug)          echo 0 ;;
        RelWithDebInfo) echo 2 ;;
        Release)        echo 2 ;;
        # THE ONLY PLACE SIZE CAN BE ASKED FOR ON THIS PATH, because this script
        # calls clang itself. fbc cannot be asked: '-O s' reaches clang as '-O0',
        # measured 2026-09-17, so the targets below where fbc drives the whole
        # compile keep '-O 2' and only windows-x86_64 gets a smaller archive.
        MinSizeRel)     echo s ;;
        *)              echo 0 ;;
    esac
}

rt_cfg_flags( ) {
    case "$1" in
        Debug)          echo "-g -w all" ;;
        RelWithDebInfo) echo "-g -O 2 -w all" ;;
        Release)        echo "-O 2 -w all" ;;
        # '-O 2', NOT '-O s' -- see rt_opt_level. Under '-gen llvm' this only sets
        # the level of the .ll that clang then re-optimizes at '-Os', and for the
        # targets fbc compiles end to end '-O s' would mean '-O0'.
        MinSizeRel)     echo "-O 2 -w all" ;;
        *)              return 1 ;;
    esac
}

# Every export is declared inside EXTERN "rtlib", which reproduces FBCALL on all
# three targets. Measured, not assumed -- PROBE-1, 2026-08-28:
#
#   extern "rtlib"    win32 _fb_Probe@8   win64 fb_Probe   linux fb_Probe   CORRECT
#   extern "c"        win32 _fb_Probe     -- no @N, wrong on win32
#   extern "windows"  win32 _fb_Probe@8   -- right by accident, wrong in meaning
#
# There is no flag for this; it is a source rule, checked by lint.sh.

# ------------------------------------------------------------------ helpers

rt_die( ) { echo "tiko-rt: $*" >&2; exit 2; }

rt_check_tools( ) {
    [ -x "$TKORT_TIKO" ] || rt_die "no tiko at $TKORT_TIKO -- build the compiler first (build/build.sh), or set TKORT_TIKO"
    [ -x "$CLANG" ]     || rt_die "clang not found at $CLANG (set CLANG)"
    [ -x "$TKORT_AR" ]  || rt_die "llvm-ar not found at $TKORT_AR (set TKORT_AR)"
    # AND llvm-nm, WHICH HAD NO GUARD. Every use of it redirects stderr away and
    # pipes into wc or grep, so a missing one does not fail -- it reports ZERO
    # symbols, and the empty-object check then names a real source file:
    #
    #   build: mem/mem.tiko compiles to an object with NO GLOBAL SYMBOLS on linux-x86_64.
    #
    # mem.tiko defines two. Measured under WSL, where llvm-nm is spelled llvm-nm-19
    # and the fallback is a Windows path that does not exist there. A tool that did
    # not run is worth an error rather than a believable number.
    [ -x "$TKORT_NM" ]  || rt_die "llvm-nm not found at $TKORT_NM (set TKORT_NM)"
}

# Source list: one module path per line, relative to src/, '#' comments allowed.
#
# The '|| true' is not defensive clutter. Until S2 the list is empty, grep exits
# 1, and under 'set -e' the caller's assignment inherits that status and the
# script dies with NO OUTPUT AT ALL -- which reads as "nothing to do" rather than
# as a failure. An empty source list is a legitimate state; grep's exit code is
# not the way to learn about it.
rt_sources( ) {
    grep -v '^[[:space:]]*#' "$RT_ROOT/build/sources.txt" 2>/dev/null \
        | grep -v '^[[:space:]]*$' || true
}
