#!/bin/bash
# The Windows battery: build every package, run every self-test.
#   bash tools/test-win.sh [core]       "core": only src/core's console suites
# A build that prints anything (a warning) counts as a failure: zero warnings is the bar.
# Prints one summary line per suite and exits with the number of suites that failed.
TIKO=${TIKO:-/c/dev/tiko-lang/toolchains/tiko-windows/tiko.exe}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
# One tiko module cache PER CHECKOUT: parallel sessions must not share the per-user default.
export TIKO_MODCACHE=${TIKO_MODCACHE:-$ROOT/out/modcache}
bad=0

build() {    # build <package dir>
    local out
    if ! out=$(cd "$ROOT/$1" && "$TIKO" build 2>&1); then
        echo "$1: BUILD FAILED"; echo "$out" | head -30; bad=$((bad+1)); return 1
    fi
    [ -n "$out" ] && { echo "$1: build printed output (warnings?)"; echo "$out" | head -30; bad=$((bad+1)); }
    return 0
}

run() {      # run <name> <dir> <command...>
    local name=$1 dir=$2; shift 2
    local res rc line
    res=$(cd "$dir" && timeout -k 10 300 "$@" 2>&1); rc=$?
    echo "$res" | grep -E '^FAIL' | head -20
    line=$(echo "$res" | grep -E ' selftest: ' | tail -1)
    echo "$name [windows]: ${line:-no summary line} (exit $rc)"
    [ $rc -eq 0 ] || bad=$((bad+1))
}

# tkEdit LINKS IN the scanner (svc/parser): tiko-lang's bin/parser_<os>_<arch>.a, which must be built by
# THIS compiler (its std module objects are one copy at the link). Made here when it is missing or older
# than the compiler; a log of the build goes to out/parserlib.log.
parserlib() {
    local lib=$ROOT/../bin/parser_windows_x86_64.a
    [ -f "$lib" ] && [ "$lib" -nt "$TIKO" ] && return 0
    mkdir -p "$ROOT/out"
    ( cd "$ROOT/.." && TIKO_SEED="$TIKO" bash build/build.sh Release --lib ) > "$ROOT/out/parserlib.log" 2>&1 \
        || { echo "parser library: BUILD FAILED (out/parserlib.log)"; bad=$((bad+1)); return 1; }
}

build src/core && run coreall "$ROOT/src/core" ./tests/bin/coreall.exe
build src/design && run designall "$ROOT/src/design" ./tests/bin/designall.exe
if [ "${1:-}" != core ] && parserlib && build src/app; then
    # the self-test builds sample programs with this tiko (P4; a Windows path for the program)
    export TKEDIT_TIKO=$(cygpath -w "$TIKO")
    run tkEdit "$ROOT/bin" ./tkedit.exe --selftest
fi
echo "suites failed: $bad"
exit $bad
