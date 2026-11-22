#!/bin/bash
# hostgate.sh -- fbc's own suite, built by tiko for THIS host and run here, held against
# another host's run (docs/tiko-macos M8, the "Mac gate" of RFC-0001 §7).
#
#   build/hostgate.sh [-j N] [PAT]            records for this host, in $HOSTGATE_OUT
#   build/hostgate.sh --against DIR [PAT]     ...then each one compared with DIR's;
#                                             exit 1 on any difference
#   build/hostgate.sh --gfx [...] gfx/        gfx/ as well: libtkogfx's null driver, headless,
#                                             on both Linux hosts (docs/tiko-linux-arm64 L4)
#
# fbc does not run on a Mac, so nothing here is compared with fbc: the oracle is tiko itself on
# another host -- macos-arm64 against linux-x86_64 -- which every other script has already held
# to fbc. One record per corpus file, by its own TEST_MODE:
#
#   SUITE (END_SUITE)        linked -mt with fbcunit's driver and run: its table
#   COMPILE_AND_RUN_OK/_FAIL built and run: the exit code and the output
#   COMPILE_ONLY_OK/_FAIL    compiled (-c): the exit code and the diagnostic ids
#   MULTI_MODULE_*           its .bas compiled (-c) as COMPILE_ONLY: the C/C++ halves and
#                            their .bmk recipes are fbc's make system, not this
#
# Not offered: gfx/ unless --gfx (no window off Windows, docs/tiko-macos D8), interactive/ (a console
# and a person), fbcunit/ (the framework itself), and the 165 files with no TEST_MODE
# (included pieces). Every run is from a COPY of the file's directory -- the suites read and
# write data files beside themselves, and tests/vendor is never edited -- rooted, as fbc's
# makefile runs them, at the tests directory; with a closed stdin and a time limit.
#
# THE RECORDS ARE NORMALISED so two hosts compare: path separators, this tree's and the work
# directory's absolute paths, and an executable's name. What is left differs only when the
# behaviour does.
#
#   HOSTGATE_OUT    the records (default build/.hostgate/<target>)
#   HOSTGATE_WK     the work directory (default ${TMPDIR:-/tmp}/hostgate)
#   RUNTIMEOUT      seconds a program may run (default 180: math/core.bas walks 2^32 floats)
set -u
# BYTES, NOT CHARACTERS: macOS tr and sed refuse a program's non-UTF-8 output otherwise
# ("Illegal byte sequence") and the record is cut short.
export LC_ALL=C
cd "$(dirname "$0")/.."
ROOT=$(pwd)
EXT=; case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) EXT=.exe ;; esac
case "$EXT" in
    .exe) HOST=windows; TGT=windows-x86_64 ;;
    *)    if [ "$(uname -s)" = Darwin ]; then HOST=macos; TGT=macos-arm64
          elif [ "$(uname -m)" = aarch64 ]; then HOST=linux-arm64; TGT=linux-arm64
          else HOST=linux; TGT=linux-x86_64; fi ;;
esac
TKO=${TKO:-$ROOT/bin/tiko$EXT}
TC=$ROOT/toolchains/tiko-$HOST
# linux-arm64 has no packaged toolchain until docs/tiko-linux-arm64 L5: build/standin.sh lays
# out this tree's inc/, runtime, graphics library and libfbcunit.a in its place.
if [ "$TGT" = linux-arm64 ] && [ ! -d "$TC" ]; then
    . "$ROOT/build/standin.sh"; TC=$(standin_linux_arm64)
fi
export TIKO_LIBPATH=${TIKO_LIBPATH:-$TC/lib/$TGT}
INC=$TC/inc
CU=$ROOT/tests/vendor/fbc-tests/fbcunit
DRV=$CU/tests/tests.bas
OUT=${HOSTGATE_OUT:-$ROOT/build/.hostgate/$TGT}
WK=${HOSTGATE_WK:-${TMPDIR:-/tmp}/hostgate}
WK=${WK%/}
RUNTIMEOUT=${RUNTIMEOUT:-180}
JOBS=4
AGAINST=
GFX=0
PAT=
while [ $# -gt 0 ]; do
    case $1 in
        -j)        JOBS=$2; shift 2 ;;
        --against) AGAINST=$2; shift 2 ;;
        --gfx)     GFX=1; shift ;;
        *)         PAT=$1; shift ;;
    esac
done

# macOS has no timeout(1); Homebrew's coreutils calls it gtimeout, and perl's alarm survives
# the exec when neither is there.
run_limited( ) {
    _t=$1; shift
    if command -v timeout > /dev/null 2>&1; then timeout "$_t" "$@"
    elif command -v gtimeout > /dev/null 2>&1; then gtimeout "$_t" "$@"
    else perl -e 'alarm shift; exec @ARGV' "$_t" "$@"; fi
}

norm( ) {
    tr '\\' '/' | sed -E "s|$WK/[^ :()]*/||g; s|$ROOT/||g; s|[A-Za-z]:/[^ :()]*/||g; s|/tmp/[^ :()]*/||g; s|\.exe\b||g"
}

# One file: its record, written to $OUT/<path>.txt.
one( ) {
    f=$1
    rel=${f#tests/vendor/fbc-tests/}
    key=$(echo "${rel%.bas}" | tr '/' '_')
    mode=$(grep -m1 -o "TEST_MODE *: *[A-Z_]*" "$f" | sed 's/.*: *//')
    grep -q END_SUITE "$f" && mode=SUITE
    exe="$WK/x/$key$EXT"; log="$WK/x/$key.log"
    rec=""; out=""
    case $mode in
    SUITE|COMPILE_AND_RUN_OK|COMPILE_AND_RUN_FAIL)
        if [ "$mode" = SUITE ]; then
            "$TKO" -mt -i "$INC" -i "$CU/inc" "$DRV" "$f" -o "$exe" >"$log" 2>&1
        else
            "$TKO" -i "$INC" "$f" -o "$exe" >"$log" 2>&1
        fi
        brc=$?
        rec="mode=$mode build=$brc"
        if [ $brc -eq 0 ]; then
            # FROM A COPY ROOTED WHERE fbc's OWN MAKEFILE RUNS THEM, the tests directory:
            # boolean_file.bas opens "boolean/data-binary-test.dat" (gatemsvc.sh says the same).
            # ONE COPY PER FILE: a suite that writes beside itself must not meet another's file.
            d=$WK/rd/$key; rd=$(dirname "$rel")
            mkdir -p "$d/$rd"; cp "$(dirname "$f")"/* "$d/$rd"/ 2>/dev/null
            ( cd "$d" && run_limited "$RUNTIMEOUT" "$exe" </dev/null >"$WK/x/$key.run" 2>&1 )
            rec="$rec run=$?"
            out=$(norm < "$WK/x/$key.run")
            rm -rf "$d" "$exe"
        else
            out=$(grep -oE "(error|warning) TKO[0-9]+" "$log" | sort -u)
        fi
        ;;
    COMPILE_ONLY_OK|COMPILE_ONLY_FAIL|MULTI_MODULE_OK|MULTI_MODULE_TEST)
        "$TKO" -i "$INC" -c "$f" -o "$WK/x/$key.o" >"$log" 2>&1
        rec="mode=$mode build=$?"
        out=$(grep -oE "(error|warning) TKO[0-9]+" "$log" | sort -u)
        rm -f "$WK/x/$key.o"
        ;;
    *) return ;;
    esac
    mkdir -p "$(dirname "$OUT/$rel")"
    printf '%s\n%s\n' "$rec" "$out" > "$OUT/${rel%.bas}.txt"
}

if [ "$GFX" = 1 ]; then
    LIST=$(find tests/vendor/fbc-tests -name '*.bas' \
            -not -path '*/interactive/*' -not -path '*/fbcunit/*' | sort | grep -F -- "$PAT")
else
    LIST=$(find tests/vendor/fbc-tests -name '*.bas' -not -path '*/gfx/*' \
            -not -path '*/interactive/*' -not -path '*/fbcunit/*' | sort | grep -F -- "$PAT")
fi
if [ -z "$AGAINST" ] || [ ! -d "$OUT" ] || [ -n "${HOSTGATE_RERUN:-}" ]; then
    rm -rf "$WK"; mkdir -p "$WK/x" "$WK/rd" "$WK/cache"
    [ -z "$PAT" ] && rm -rf "$OUT"
    mkdir -p "$OUT"
    export TIKO_MODCACHE="$WK/cache"
    # fbcunit, built by this compiler for this host, beside the runtime it is linked with.
    if [ ! -f "$TIKO_LIBPATH/libfbcunit.a" ]; then
        echo "hostgate: no $TIKO_LIBPATH/libfbcunit.a -- build fbcunit for $TGT first" >&2; exit 3
    fi
    # N WORKERS, each taking every Nth file: the corpus is 2700 files, one at a time is an hour.
    export -f one norm run_limited
    export TKO INC CU DRV OUT WK EXT RUNTIMEOUT ROOT
    for w in $(seq 0 $((JOBS - 1))); do
        ( i=0; for f in $LIST; do
              [ $((i % JOBS)) -eq "$w" ] && one "$f"
              i=$((i + 1))
          done ) &
    done
    wait
fi

n=$(find "$OUT" -name '*.txt' | wc -l | tr -d ' ')
echo "hostgate: $n records for $TGT in $OUT"
for m in SUITE COMPILE_AND_RUN_OK COMPILE_AND_RUN_FAIL COMPILE_ONLY_OK COMPILE_ONLY_FAIL MULTI_MODULE_OK MULTI_MODULE_TEST; do
    c=$(grep -rl "^mode=$m " "$OUT" 2>/dev/null | wc -l | tr -d ' ')
    [ "$c" -gt 0 ] && echo "hostgate:   $m $c"
done
[ -z "$AGAINST" ] && exit 0

nd=0; nm=0
for r in $(cd "$OUT" && find . -name '*.txt' | sort); do
    r=${r#./}
    if [ ! -f "$AGAINST/$r" ]; then
        nm=$((nm + 1)); echo "hostgate: ONLY HERE ${r%.txt}"
    elif ! cmp -s "$OUT/$r" "$AGAINST/$r"; then
        nd=$((nd + 1)); echo "hostgate: DIFF ${r%.txt}"
        diff "$AGAINST/$r" "$OUT/$r" | head -6 | sed 's/^/hostgate:     /'
    fi
done
for r in $(cd "$AGAINST" && find . -name '*.txt' | sort); do
    r=${r#./}
    [ -f "$OUT/$r" ] || { nm=$((nm + 1)); echo "hostgate: ONLY THERE ${r%.txt}"; }
done
echo "hostgate: against $AGAINST -- $nd differ, $nm in one only"
[ $nd -eq 0 ] && [ $nm -eq 0 ]
