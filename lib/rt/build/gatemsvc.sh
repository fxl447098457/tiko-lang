#!/bin/sh
# gatemsvc.sh -- run fbc's own unit-test suite against the MICROSOFT ABI runtime.
#
#   build/gatemsvc.sh [Debug|Release|RelWithDebInfo] [dir ...]
#
#   build/gatemsvc.sh Release                 the default directory set
#   build/gatemsvc.sh Release boolean string  just those two
#
# gate.sh cannot do this and never will: it swaps tiko-rt's archive into fbc's
# own build, and fbc links MinGW. RFC-0006 section 13 called that the one
# unbounded item in the MSVC move. The route turns out not to be swapping the
# archive at all -- it is RETARGETING THE SUITE:
#
#   fbc -c -gen llvm -r -z msvc   per module, emitting the msvc triple
#   clang --target=...-msvc       per module, to a COFF object
#   clang, linked against         lib/windows-x86_64/libfbmt.a
#
# and then RUN. RFC-0008 sections 15 to 17 are the measurements that got here.
#
# WHAT THIS NEEDS THAT THE OTHER SCRIPTS DO NOT: an fbc that understands
# `-z msvc`. The prebuilt toolchain compiler does not -- the switch landed in
# fbc-modern 2026-09-05 -- so this script looks for a built one and REFUSES
# rather than falling back, because falling back would silently emit the gnu
# triple and gate the wrong ABI.
#
# THE RUN HAPPENS FROM fbc's OWN TESTS DIRECTORY, and that is not a detail.
# boolean_file.bas opens "boolean/data-binary-test.dat" -- a RELATIVE path --
# so a run from anywhere else writes nothing, reads nothing back, and reports
# 26 failures that look like an ABI difference and are the harness's own doing.
# That happened; RFC-0008 section 17.4 is the retraction.
#
# GFX IS EXCLUDED BY CONSTRUCTION. tiko-rt ships no graphics library and there
# is no MSVC libfbgfx, so the 14 files that touch fbgfx cannot be part of this
# and are not silently skipped -- they are not offered.

# TKORT_GATE_OPTIONAL=1 turns every REFUSAL into a SKIP. Everything this script dies on
# is an environment gap -- no fbc that understands '-z msvc', no clang, no import
# libraries, no windows-x86_64 archive of the right configuration -- and none of them is a
# regression in tiko-lang. check-all sets it for the same reason crosslink.sh skips
# rather than failing when the toolchain has not been packaged: a gate that fails for
# the wrong reason gets ignored, and then it fails for the right reason and is ignored
# too. Run by hand with it unset, the refusals stay refusals.
set -e

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/oracle.sh"

# AFTER the source, or common.sh's own definition replaces this one -- and before
# rt_check_tools, which is the first thing that can refuse.
if [ "${TKORT_GATE_OPTIONAL:-0}" = "1" ] ; then
    rt_die( ) { echo "gatemsvc: SKIPPED -- $*" >&2; exit 0; }
fi

rt_check_tools
rt_oracle_check gatemsvc.sh

CFG=${1:-Release}
rt_cfg_flags "$CFG" > /dev/null || rt_die "unknown configuration '$CFG'"
shift 2>/dev/null || true

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) rt_die "win64 host only -- there is no MSVC ABI to gate against here" ;;
esac

# Directories to include; empty means EVERY directory the suite links.
DIRS="$*"

T="$FBC_TREE/src/tests"
[ -d "$T" ] || rt_die "no fbc test suite at $T"

# ---------------------------------------------------------------- the compiler
FBCX=${TKORT_FBC_MSVC:-$FBC_TREE/src/fbc.exe}
[ -f "$FBCX" ] || rt_die "no fbc at $FBCX -- build fbc-modern (make compiler) or set TKORT_FBC_MSVC"
if ! "$FBCX" -prefix "$FBC_TREE/src" -c -gen llvm -z msvc -m __probe /dev/null -o /dev/null > /dev/null 2>&1; then
    printf 'x\n' > /tmp/tkort_zmsvc_probe.bas
    if "$FBCX" -prefix "$FBC_TREE/src" -z msvc -gen llvm -c /tmp/tkort_zmsvc_probe.bas -o /tmp/tkort_zmsvc_probe.o 2>&1 | grep -q 'Invalid command-line option'; then
        rt_die "$FBCX does not understand -z msvc -- it predates 2026-09-05; build fbc-modern from source"
    fi
fi

# THE MSVC IMPORT LIBRARIES, which stand in for the CRT here -- see the link step.
# build/package.sh builds them there, from lib/implib/ (build/implibs.sh).
# REFUSED rather than skipped: without them the link fails on memset, which reads as an
# ABI difference -- exactly the misdiagnosis this script's header warns about.
IMPLIBS=${TKORT_MSVC_IMPLIBS:-$(cd "$(dirname "$0")/../../.." && pwd)/toolchains/tiko-windows/lib/windows-x86_64}
[ -f "$IMPLIBS/ucrtbase.lib" ] || rt_die "no ucrtbase.lib in $IMPLIBS -- run build/implibs.sh build --out <dir>"
IMPLIBS=$(cygpath -m "$IMPLIBS")

CLANGX=${CLANG:-${TIKO_CLANG:-"C:/Program Files/LLVM/bin/clang.exe"}}
ARX=${TKORT_AR_MSVC:-"C:/Program Files/LLVM/bin/llvm-ar.exe"}

# ---------------------------------------------------------------- the archive
LIB="$RT_ROOT/lib/windows-x86_64/libfbmt.a"
[ -f "$LIB" ] || rt_die "no archive at $LIB -- run build/build.sh $CFG windows-x86_64 first"
STAMP="$RT_ROOT/lib/windows-x86_64/.config"
[ -f "$STAMP" ] || rt_die "no .config beside $LIB -- rebuild with build/build.sh $CFG windows-x86_64"
HAVE=$(cat "$STAMP")
[ "$HAVE" = "$CFG" ] || rt_die "the windows-x86_64 archives were built [$HAVE], not [$CFG]"

W="$RT_ROOT/obj/gatemsvc"
rm -rf "$W"; mkdir -p "$W/cu" "$W/t"

# One FB source to one MSVC object, through -gen llvm -r. `-m fbc-tests` marks
# every module NON-MAIN except the driver itself, which is how fbc's own
# makefile builds them; without it each module defines main and the link dies
# with "main already defined".
build_obj( ) {
    _src=$1; _out=$2; _m=$3; shift 3
    ( cd "$_out" && "$FBCX" -prefix "$FBC_TREE/src" -c "$_src" -m "$_m" \
        -target win64 -gen llvm -r -z msvc -mt \
        -i "$FBC_TREE/src/inc" -i "$T/fbcunit/inc" "$@" -o "$_out/$_m.o" ) \
        > "$_out/$_m.fbclog" 2>&1 || return 1
    [ -f "$_out/$_m.ll" ] || return 2
    "$CLANGX" --target=x86_64-pc-windows-msvc -march=x86-64 -O0 -Wno-override-module \
        "$_out/$_m.ll" -c -o "$_out/$_m.o" > "$_out/$_m.clanglog" 2>&1 || return 3
    return 0
}

echo "gatemsvc: fbc  $FBCX"
echo "gatemsvc: lib  $LIB [$HAVE]"

# ---------------------------------------------------------------- fbcunit
CUOBJS=""
for f in "$T"/fbcunit/src/*.bas; do
    n=$(basename "$f" .bas)
    if build_obj "$f" "$W/cu" "$n" -m fbc-tests; then
        CUOBJS="$CUOBJS $W/cu/$n.o"
    else
        rt_die "fbcunit module $n did not build -- see $W/cu/$n.fbclog and $n.clanglog"
    fi
done
rm -f "$W/libfbcunit.a"
"$ARX" rcs "$W/libfbcunit.a" $CUOBJS

# ---------------------------------------------------------------- the suite
#
# THE MODULE LIST COMES FROM unit-tests.inc, NOT FROM A GLOB, and that is the
# difference between a gate and an approximation. The tree holds 2715 .bas
# files and only 737 of them are LINKED INTO THE BINARY: the rest are
# compile-only and negative-compile tests, checked by a different harness and
# written to FAIL. Globbing *.bas fed 277 of those to the compiler, reported
# them as build failures, and then collided on the duplicate symbols the ones
# that did build all define -- both artefacts of the glob, neither an ABI
# finding. unit-tests.mk generates the list; regenerate it if it is missing.
if [ ! -f "$T/unit-tests.inc" ]; then
    ( cd "$T" && make -f unit-tests.mk unit-tests.inc ) > "$W/genlist.log" 2>&1         || rt_die "could not generate $T/unit-tests.inc -- see $W/genlist.log"
fi
SRCS=$(sed -n 's/^SRCLIST += //p' "$T/unit-tests.inc")

# WHAT THIS TARGET CANNOT LINK, EXCLUDED BY NAME AND WITH A REASON EACH.
# Measured: with these in, the link ends on 26 unresolved symbols, 23 of them
# fb_Gfx* plus fb_ThreadCall. Neither is an ABI question --
#
#   gfx/, fbc-int/gfx   tiko-rt ships no graphics library and there is no MSVC
#                       libfbgfx to borrow one from. 22 symbols.
#   threads/threadcall  libffi, which is why the MinGW gate carries 11 known
#                       failures of its own. 1 symbol.
#   quirk/inline-asm    Inline ASM, which -gen llvm rejects permanently and by
#   quirk/inline-asm-   design -- error 374. gate-win.sh moves these same two
#     syntax            files aside for its own llvm runs. THEY WERE NOT LISTED
#                       HERE AT FIRST, and this script reported '0 failed to
#                       build' anyway -- because gate-win.sh had them moved
#                       aside while these runs happened. Two harnesses sharing
#                       one tree, and a number that was right by accident.
#   math/fenv           feraiseexcept, which the UCRT does not EXPORT. Its own
#                       <fenv.h> says why: "feraiseexcept is defined inline in
#                       this header so that it is compiled". A C caller gets it
#                       inlined and never needs the symbol; a FreeBASIC caller
#                       naming it cannot link. Same shape as sprintf, which is
#                       what -llegacy_stdio_definitions exists for -- there is
#                       no equivalent library for fenv. 1 symbol.
#
# They are named here rather than silently dropped, so the exclusion is a
# statement about this target and not a hole nobody can see.
SRCS=$(printf '%s
' $SRCS | grep -v '^\./gfx/' | grep -v '^\./fbc-int/gfx\.bas$' | grep -v '^\./threads/threadcall\.bas$' | grep -v '^\./math/fenv\.bas$' | grep -v '^\./quirk/inline-asm\.bas$' | grep -v '^\./quirk/inline-asm-syntax\.bas$')
[ -n "$SRCS" ] || rt_die "no SRCLIST entries in $T/unit-tests.inc"

if [ -n "$DIRS" ]; then
    _sel=""
    for d in $DIRS; do
        _hit=$(printf '%s
' $SRCS | grep "^\./$d/" || true)
        [ -n "$_hit" ] || rt_die "no linked modules under '$d' -- check the name against $T/unit-tests.inc"
        _sel="$_sel $_hit"
    done
    SRCS="$_sel"
fi

ok=0; bad=0; TOBJS=""
for rel in $SRCS; do
    f="$T/${rel#./}"
    if [ -f "$f" ]; then
        d=$(dirname "${rel#./}")
        n=$(basename "$f" .bas)
        LANGOPT=""
        grep -q 'NEEDS-LANG-FBLITE' "$f" 2>/dev/null && LANGOPT="-lang fblite"
        grep -q 'NEEDS-LANG-QB' "$f" 2>/dev/null && LANGOPT="-lang qb"
        if build_obj "$f" "$W/t" "$n" -m fbc-tests $LANGOPT; then
            ok=$((ok + 1)); TOBJS="$TOBJS $W/t/$n.o"
        else
            bad=$((bad + 1))
            echo "gatemsvc: FAILED TO BUILD $d/$n" >&2
            grep -m2 -iE 'error' "$W/t/$n.fbclog" "$W/t/$n.clanglog" 2>/dev/null | sed 's/^/    /' >&2
        fi
    fi
done
echo "gatemsvc: $ok modules built, $bad failed to build"

build_obj "$T/fbc-tests.bas" "$W/t" "fbc-tests" \
    || rt_die "the fbc-tests driver did not build -- see $W/t/fbc-tests.fbclog"

# ---------------------------------------------------------------- link
# A RESPONSE FILE, because 737 object paths do not fit on a command line --
# "Argument list too long", which is the shell refusing before clang is even
# reached. The @file form is clang's own and takes one path per line.
# NATIVE PATHS INSIDE THE FILE. The shell rewrites /c/... to C:/... on a
# COMMAND LINE, and does not look inside a response file, so the MSYS form
# reaches clang untranslated and every object is "no such file or directory"
# -- while sitting exactly where it was just written. cygpath -m emits the
# mixed form clang takes.
rm -f "$W/objs.rsp"
for o in $TOBJS "$W/t/fbc-tests.o"; do cygpath -m "$o" >> "$W/objs.rsp"; done

# THE SAME LINK SHAPE tiko-lang ITSELF USES, and it has to be: this gate exists to say
# whether a program built the way tiko builds one behaves the way fbc's suite expects.
#
# Without '-nostdlib' clang reaches for the MSVC CRT out of a Visual Studio install, and
# there is none on a machine that has only the toolchain -- so every module came back
# with "unresolved external symbol memset" and the gate read as an ABI failure when it
# was a missing library. See src/codegen/toolchain.tiko: what replaces the CRT is
# ucrtbase.dll, reached through the import library build/implibs.sh builds, and
# the handful it does not export are tiko-rt's own src/c/msvccrt.c -- already inside the
# archive being linked here, mainCRTStartup included.
#
# kernel32 IS NAMED because '-nostdlib' drops clang's own defaults with it: the thread
# and timing layers need Sleep, CreateSemaphoreA and CloseHandle. winspool/gdi32 are
# NOT named: $LIB is built from the current sources, and io/printerwin.tiko resolves
# them through LoadLibrary/GetProcAddress. tiko's own MSVC link line keeps the two
# only for the seed's older prebuilt libfb.a, which this gate does not link.
if ! "$CLANGX" --target=x86_64-pc-windows-msvc "@$W/objs.rsp" \
        "$W/libfbcunit.a" "$LIB" -o "$W/gatemsvc.exe" \
        -nostdlib "-L$IMPLIBS" -lucrtbase -lkernel32 \
        -luser32 -ladvapi32 -lwinmm -lmsimg32 -lversion -limm32 -lws2_32 \
        -Xlinker /INCLUDE:tkort_msvc_init_ -Xlinker /STACK:2097152 \
        > "$W/link.log" 2>&1; then
    echo "gatemsvc: LINK FAILED" >&2
    grep -iE 'error|unresolved' "$W/link.log" | head -20 | sed 's/^/    /' >&2
    exit 1
fi

# ---------------------------------------------------------------- run
# FROM $T. See the header: the suite's file tests use relative paths.
( cd "$T" && "$W/gatemsvc.exe" ) > "$W/run.out" 2>&1 < /dev/null && rc=0 || rc=$?

sed -n '/SUMMARY/,$p' "$W/run.out" | tail -3
FAILED=$(sed -n '/SUMMARY/,$p' "$W/run.out" | awk '$4=="Total"{print $3}')
[ -n "$FAILED" ] || { echo "gatemsvc: NO SUMMARY -- the binary did not finish, see $W/run.out" >&2; exit 1; }

echo "gatemsvc: failing suites:"
sed -n '/SUMMARY/,$p' "$W/run.out" | awk '$3+0>0' | sed 's/^/    /'

if [ "$FAILED" = "0" ] && [ "$bad" = "0" ]; then
    echo "gatemsvc: PASS -- windows-x86_64 [$CFG], $ok modules, 0 assertion failures"
    exit 0
fi
echo "gatemsvc: FAIL -- $FAILED assertion failures, $bad modules unbuilt (exit=$rc)" >&2
exit 1
