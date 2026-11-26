#!/bin/bash
# stdsuite.sh -- RUN the standard library's own tests, and hold them to a baseline.
#
# 108 files of fbc's corpus (tests/vendor/fbc-tests) test the libraries pkg/std is made of:
# containers, strings, chrono, tasks, outcome, numeric, money, logs, tui and COM. They were
# written against the headers -- '#include "fb/string.bi"', 'using FB' -- and tests/vendor is
# never edited, so when the headers became modules each file was COPIED to tests/std and
# rewritten there to '#import' (build/stdtests.py). This script runs either set:
#
#   build/stdsuite.sh --baseline [PAT]   the vendored originals, over the headers; writes
#                                        tests/std/baseline/<area>/<name>.txt
#   build/stdsuite.sh [PAT]              the ports in tests/std, each compared with its
#                                        baseline; exit 1 on any difference
#
# PAT is a substring of the path ('string/', 'container-map'). One record per file:
#
#   build=<rc> run=<rc>        and the program's output, normalised
#
# by the corpus's own TEST_MODE: an fbcunit SUITE links with fbcunit's driver and prints its
# table; COMPILE_AND_RUN_OK / _FAIL build alone and run; COMPILE_ONLY_FAIL only builds, and
# its record is the build's exit code and the diagnostic IDS (not their text: a port may
# spell a type 'containers.Array' where the header spelled 'FB.Array'). A '_mod2.bas' beside
# a suite is the second module it is linked with.
#
# Every run is from a COPY of the test's directory (data files; and these suites write), with
# a closed stdin and a timeout. Modules are cached in a private TIKO_MODCACHE, emptied first.
#
#   build/stdsuite.sh --adb [PAT]        the ports, built on Windows for TIKO_ADB_TARGET (android-x86_64,
#                                        the default, or android-arm64) and run
#                                        on the device adb reaches (docs/tiko-android A2): every
#                                        program is built first and staged with a copy of its
#                                        directory, build/adbrun.sh runs them all in one push,
#                                        and each record is then judged as above. The runtime
#                                        is this tree's lib/rt/lib/<that target>, with
#                                        fbcunit built for it here.
set -u
cd "$(dirname "$0")/.."
ROOT=$(pwd)
EXT=; case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) EXT=.exe ;; esac
TKO=${TKO:-$ROOT/bin/tiko$EXT}
case "$EXT" in
    .exe) TC=$ROOT/toolchains/tiko-windows; LIBT=windows-x86_64 ;;
    *)    if [ "$(uname -s)" = Darwin ]; then TC=$ROOT/toolchains/tiko-macos; LIBT=macos-arm64
          elif [ "$(uname -m)" = aarch64 ]; then TC=$ROOT/toolchains/tiko-linux-arm64; LIBT=linux-arm64
          else TC=$ROOT/toolchains/tiko-linux; LIBT=linux-x86_64; fi ;;
esac
ADB=0
[ "${1:-}" = "--adb" ] && { ADB=1; shift; }
TGTOPT=""
if [ "$ADB" = 1 ]; then
    [ "$EXT" = .exe ] || { echo "stdsuite: --adb runs from Windows" >&2; exit 3; }
    LIBT=${TIKO_ADB_TARGET:-android-x86_64}; TGTOPT="-target $LIBT"; EXT=""  # docs/tiko-android A3, D-A3-4
fi
# linux-arm64 has no packaged toolchain until docs/tiko-linux-arm64 L5: build/standin.sh lays
# out this tree's inc/, runtime, graphics library and libfbcunit.a in its place.
if [ "$LIBT" = linux-arm64 ] && [ ! -d "$TC" ]; then
    . "$ROOT/build/standin.sh"; TC=$(standin_linux_arm64)
fi
# A RUN WITH A TIME LIMIT. macOS has no timeout(1): Homebrew's coreutils call it gtimeout, and
# without either perl's alarm survives the exec -- a hang is still a result, not a stall.
run_limited( ) {
    _t=$1; shift
    if command -v timeout > /dev/null 2>&1; then timeout "$_t" "$@"
    elif command -v gtimeout > /dev/null 2>&1; then gtimeout "$_t" "$@"
    else perl -e 'alarm shift; exec @ARGV' "$_t" "$@"; fi
}
export TIKO_LIBPATH="$TC/lib/$LIBT"
CU=$ROOT/tests/vendor/fbc-tests/fbcunit
DRV=$CU/tests/tests.bas
WK=${STDSUITE_WK:-${TMPDIR:-/tmp}/stdsuite}
RUNTIMEOUT=${RUNTIMEOUT:-180}

MODE=port
if [ "${1:-}" = "--baseline" ]; then MODE=baseline; shift; fi
PAT=${1:-}

rm -rf "$WK"; mkdir -p "$WK/cache" "$WK/rd"
export TIKO_MODCACHE="$WK/cache"
if [ "$ADB" = 1 ]; then
    # THIS TREE'S ANDROID RUNTIME, and fbcunit built for it as package.sh builds it per target.
    export TIKO_LIBPATH="$WK/lib"
    STAGE=$WK/stage
    mkdir -p "$TIKO_LIBPATH" "$WK/fbcunit" "$STAGE"
    cp "$ROOT"/lib/rt/lib/$LIBT/* "$TIKO_LIBPATH"/ || { echo "stdsuite: no lib/rt/lib/$LIBT (lib/rt/build/build.sh Release $LIBT)" >&2; exit 3; }
    for s in "$CU"/src/*.bas; do
        "$TKO" $TGTOPT -c "$s" -i "$CU/inc" -i "$CU/src" -o "$WK/fbcunit/$(basename "$s" .bas).o" > /dev/null 2>&1
    done
    AR=${TIKO_AR:-/c/Program Files/LLVM/bin/llvm-ar.exe}
    "$AR" rcs "$TIKO_LIBPATH/libfbcunit.a" "$WK"/fbcunit/*.o || { echo "stdsuite: fbcunit did not build for $LIBT" >&2; exit 3; }
    : > "$STAGE/list"; : > "$WK/pending"
fi

if [ "$MODE" = baseline ]; then
    # THE BASELINE WAS TAKEN ONCE, over inc/fb, which left the tree on 2026-10-10: it runs
    # only in a checkout from before that (git worktree add <dir> a04bae1f), and its results
    # are tests/std/baseline as committed -- never rewrite them from a later tree.
    [ -d "$ROOT/inc/fb" ] || { echo "stdsuite: --baseline needs inc/fb, gone since 2026-10-10 -- run it in a checkout of a04bae1f" >&2; exit 3; }
    SRCROOT=tests/vendor/fbc-tests
    INC=$ROOT/inc
    # Not com/: fb/comptr.bi is gone, ComPtr no longer a supported feature (2026-10-10).
    LIST=$(grep -rlE '^[^'"'"']*#include( once)? "(fb/|containers\.bi)' $SRCROOT --include='*.bas' | grep -v '/com/' | sort)
else
    SRCROOT=tests/std
    INC=$TC/inc
    LIST=$(find $SRCROOT -name '*.bas' -not -path '*/baseline/*' | sort)
fi

norm( ) {
    # Paths and their separators are not a difference; nor is a temporary's address. The
    # device's run directory goes first: '/tmp/' alone would leave its '/data/local' behind.
    tr '\\' '/' | sed -E "s|/data/local/tmp/[^ :()]*/||g; s|[A-Za-z]:/[^ :()]*/||g; s|$ROOT/||g; s|/tmp/[^ :()]*/||g"
}

# A FAILING ASSERT'S SITE, compared without its directory or line: the port lives in
# tests/std rather than tests/vendor/fbc-tests, and its rewritten imports move its lines.
site( ) {
    # ...and a runtime error in the library names its file, which was fb/x.bi and is x.tiko --
    # and its LINE, which is the library's, not the test's: x.tiko is not x.bi line for line,
    # and any edit above the aborting procedure moved it (review LIB-04 added two lines).
    sed -E 's|tests/(vendor/fbc-tests\|std)/[A-Za-z0-9_]+/([A-Za-z0-9_.-]+\.bas)\([0-9]+(,[0-9]+)?\)|\2(L)|g; s|of ([A-Za-z0-9_]+)\.(bi\|tiko)\(|of \1(|g; s|at line [0-9]+ of ([A-Za-z0-9_]+)\(|at line L of \1(|g'
}

judge( ) {
    area=$1; name=$2; got=$3
    want="tests/std/baseline/$area/$name.txt"
    if [ "$MODE" = baseline ]; then
        mkdir -p "$(dirname "$want")"
        printf '%s\n' "$got" > "$want"
        echo "stdsuite: $(printf '%s\n' "$got" | head -1)  $area/$name"
    elif [ ! -f "$want" ]; then
        nbad=$((nbad+1)); echo "stdsuite: NO BASELINE $area/$name"
    elif ! diff -q <(printf '%s\n' "$got" | site) <(site < "$want") >/dev/null; then
        nbad=$((nbad+1)); echo "stdsuite: DIFF $area/$name"
        diff <(site < "$want") <(printf '%s\n' "$got" | site) | head -8 | sed 's/^/stdsuite:     /'
    fi
}

n=0; nbad=0
for f in $LIST; do
    case "$f" in *_mod2.bas) continue ;; esac
    echo "$f" | grep -qF -- "$PAT" || continue
    rel=${f#$SRCROOT/}
    area=${rel%%/*}; name=$(basename "$rel" .bas)
    mode=$(grep -m1 -o "TEST_MODE *: *[A-Z_]*" "$f" | sed 's/.*: *//')
    grep -q END_SUITE "$f" && mode=SUITE
    [ -z "$mode" ] && continue
    n=$((n+1))
    exe="$WK/$area-$name$EXT"; log="$WK/$area-$name.log"
    extra=""; [ -f "${f%.bas}_mod2.bas" ] && extra="${f%.bas}_mod2.bas"
    if [ "$mode" = SUITE ]; then
        "$TKO" $TGTOPT -mt -i "$INC" -i "$CU/inc" "$DRV" "$f" $extra -o "$exe" >"$log" 2>&1
    else
        "$TKO" $TGTOPT -i "$INC" "$f" $extra -o "$exe" >"$log" 2>&1
    fi
    brc=$?
    rec="mode=$mode build=$brc"
    out=""
    if [ "$mode" = COMPILE_ONLY_FAIL ]; then
        out=$(grep -oE "(error|warning) TKO[0-9]+" "$log" | sort -u)
    elif [ $brc -eq 0 ] && [ "$ADB" = 1 ]; then
        # STAGED, run later on the device: the program and a copy of its directory, run there.
        key="$area-$name"; d=$(dirname "$f")
        mkdir -p "$STAGE/$key/$d"; cp "$d"/* "$STAGE/$key/$d"/ 2>/dev/null
        mv "$exe" "$STAGE/$key/$key"
        echo "$key $d" >> "$STAGE/list"
        echo "$area $name $key $rec" >> "$WK/pending"
        continue
    elif [ $brc -eq 0 ]; then
        d=$(dirname "$f")
        mkdir -p "$WK/rd/$d"; cp "$d"/* "$WK/rd/$d"/ 2>/dev/null
        ( cd "$WK/rd/$d" && run_limited "$RUNTIMEOUT" "$exe" </dev/null >"$WK/run.txt" 2>&1 )
        rec="$rec run=$?"
        out=$(norm < "$WK/run.txt")
    else
        out=$(grep -E "error TKO" "$log" | head -5 | norm)
    fi
    judge "$area" "$name" "$(printf '%s\n%s\n' "$rec" "$out")"
done

if [ "$ADB" = 1 ] && [ -s "$STAGE/list" ]; then
    sh "$ROOT/build/adbrun.sh" "$STAGE" "$RUNTIMEOUT"
    while read -r area name key rec; do
        rc=$(cat "$STAGE/out/$key.rc" 2>/dev/null || echo missing)
        out=$(norm < "$STAGE/out/$key.out" 2>/dev/null)
        judge "$area" "$name" "$(printf '%s\n%s\n' "$rec run=$rc" "$out")"
    done < "$WK/pending"
fi
echo "stdsuite: $n files ($MODE), $nbad differ"
[ $nbad -eq 0 ]
