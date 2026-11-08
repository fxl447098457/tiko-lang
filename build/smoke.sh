#!/bin/sh
# smoke.sh -- compile and run tests/smoke/*.bas FOR ONE TARGET, and fail on any
# difference from the expectation the source's header records.
#
#   build/smoke.sh <target> [--mt] [--filter <name>]
#
# <target> is tiko's own spelling: win32, win64, windows-x86_64, linux-x86_64.
# The Windows gnu targets need a mingw sysroot on PATH (clang finds it through the
# gcc there) -- win32 the i686 one, win64 the x86_64 one, msvcrt flavor against
# lib/win32 and lib/win64. --mt adds -mt (the conc program needs the threaded
# runtime); a target's smoke run is expected to pass BOTH with and without it.
#
# WHY SMOKE AND NOT THE SUITE: the suite's cli tests name their target in the
# file, and the goldens are per-target for the targets that share them -- a
# second target's full run is Phase 4. This is the lane that says the target
# compiles, links against its runtime archive, and runs, which is what the win32
# and win64 jobs of the workflow exist to check.
set -eu
cd "$(dirname "$0")/.."
ROOT=$(pwd)

TARGET=${1:?usage: build/smoke.sh <target> [--mt] [--filter <name>]}; shift
MT=""
FILTER=""
while [ $# -gt 0 ]; do
    case "$1" in
        --mt) MT="-mt" ;;
        --filter) shift; FILTER=$1 ;;
        *) echo "smoke: unknown option '$1'" >&2; exit 2 ;;
    esac
    shift
done

# THE TARGET'S WIDTH, for -m32 on the 64-bit host: win32 is the width override,
# the gnu win64 the explicit target, windows-x86_64 the host default.
case "$TARGET" in
    win32) W32="-m32";; *) W32="";;
    *) W32="";;
esac

if [ ! -x "bin/tiko$( [ "$(uname -s)" = "Linux" ] && echo '' || echo '.exe' )" ] && \
   [ ! -x bin/tiko ] && [ ! -x bin/tiko.exe ]; then
    echo "smoke: no bin/tiko -- build first (build.sh Release --no-dll)" >&2
    exit 3
fi

rc=0
for src in tests/smoke/*.bas; do
    name=$(basename "$src" .bas)
    if [ -n "$FILTER" ] && [ "$name" != "$FILTER" ]; then continue; fi
    # -mt IS PER PROGRAM: conc names threads; the rest run single-threaded, and
    # their lanes check both widths of the runtime anyway. THE TARGET IS NAMED
    # ALWAYS -- without it 'win64' would fall back to the host default, the MSVC
    # flavor, and link against the ucrt import libraries a mingw PATH does not
    # carry (measured: 'could not open ucrtbase.lib').
    case "$name" in conc) pmt="-mt";; *) pmt="";; esac
    out="$ROOT/build/obj/smoke/$TARGET/$name"
    mkdir -p "$(dirname "$out")"
    if ! ./bin/tiko$( [ -f bin/tiko.exe ] && echo '.exe' || echo '' ) -target "$TARGET" $W32 $MT $pmt -O2 \
            "$src" -o "$out.exe" > "$out.log" 2>&1; then
        echo "smoke: FAIL $name [$TARGET] build:" >&2
        grep -m3 "error" "$out.log" >&2 || tail -3 "$out.log" >&2
        rc=1
        continue
    fi
    # THE EXPECTATION IS THE SOURCE'S 'expect:' LINES, in order: what the program
    # prints is asserted by the same file that prints it, so a new program is one
    # file and its expectation travels with it.
    if ! "$out.exe" > "$out.run" 2>&1; then
        echo "smoke: FAIL $name [$TARGET] run -- exit $?:" >&2
        tail -3 "$out.run" >&2
        rc=1
        continue
    fi
    if ! grep -qi "^'' *expect:.*" "$src"; then
        echo "smoke: $name [$TARGET] ran (no expect lines recorded)" >&2
        continue
    fi
    fail=0
    # 'expect:' lines match SUBSTRINGS of the output, in order -- a print with a
    # leading-space boolean has its spaces spelled here as ' ' where it matters.
    sed -n "s/^'' *expect:[[:space:]]*//p" "$src" > "$out.want"
    while IFS= read -r want; do
        if ! grep -qF "$want" "$out.run"; then
            echo "smoke: FAIL $name [$TARGET] -- output lacks: $want" >&2
            fail=1
        fi
    done < "$out.want"
    if [ "$fail" = 0 ]; then
        echo "smoke: ok $name [$TARGET]"
    else
        rc=1
    fi
done
exit $rc
