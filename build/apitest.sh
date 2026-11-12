#!/bin/sh
# apitest.sh -- the in-process checks for the editor's parser.dll (src/api).
#
#   build/apitest.sh            (after build/build.sh --dll; Windows only)
#
# tests/api/*.test cover WHAT a scan records, through 'tiko --dump-scan'. This covers what
# only a host that loads the DLL can see: the exports and the contract version, scan_text
# byte-identical to scan, the same result scan after scan in one process, a working set
# that does not keep growing, a broken file that stays quiet, and an '#import' scan.

set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) echo "apitest: Windows only (the harness loads a .dll)"; exit 0 ;;
esac
DLL=bin/parser.dll
[ -f "$DLL" ] || { echo "apitest: $DLL not built -- build/build.sh --dll" >&2; exit 3; }

# THE HARNESS IS BUILT BY THE STAGE0 build.sh USES: TIKO_SEED, else build/defaultseed.sh's
# pick -- the seed, against the tree's inc/, as the DLL it loads was built. It was fbc
# until 2026-10-10 (bootstrap plan, phase T); seed-2 is the first seed whose runtime runs
# a DLL's atexit handlers at DLL_PROCESS_DETACH, which the harness's unload checks need.
. "$ROOT/build/defaultseed.sh"
SEEDCC=${TIKO_SEED:-$(default_seed "$ROOT" 1)} || {
    echo "apitest: no seed compiler -- seed/fetch-seed.sh, or TIKO_SEED" >&2; exit 3; }
TIKO_INCLUDE="$ROOT/inc" TIKO_INCLUDE="$ROOT/inc" "$SEEDCC" tools/tkpdump/tkpdump.tiko -i src -o bin/tkpdump.exe
H=bin/tkpdump.exe
FAIL=0
check( ) {  # check <label> <expected-substring> <command...>
    label=$1; want=$2; shift 2
    if out=$("$@" 2>&1) && echo "$out" | grep -qF -- "$want"; then
        echo "ok    $label"
    else
        echo "FAIL  $label"; echo "$out" | sed 's/^/      /'; FAIL=1
    fi
}

check "scan_text == scan (basic)"  "TEXT OK" $H $DLL tests/api/src/scanbasic.tiko text
check "scan_text == scan (broken)" "TEXT OK" $H $DLL tests/api/src/scanbroken.tiko text
check "100 scans, one result, no leak" "all identical = yes" $H $DLL tests/api/src/scanbasic.tiko loop 100

# A broken file: records and diagnostics come back, and NOTHING reaches the host's console.
out=$($H $DLL tests/api/src/scanbroken.tiko dump 2>&1)
if echo "$out" | grep -qF "diags: 3" && ! echo "$out" | grep -qF "TKO0"; then
    echo "ok    broken file: 3 diags, none printed"
else
    echo "FAIL  broken file"; echo "$out" | sed 's/^/      /'; FAIL=1
fi

# '#import' through the DLL: the module's public procedure under its alias, at its source.
INC=$(cygpath -w "$ROOT/tests/driver/src/modcache/libs")
# The pool a scan must not make: named, so the check below asks the place it would go.
SCANCACHE="$ROOT/build/.apitest-scancache"
rm -rf "$SCANCACHE"
out=$(TIKO_MODCACHE="$SCANCACHE" TKP_INCDIR="$INC" $H $DLL tests/driver/src/modcache/app/main.bas dump 2>&1)
# parent=1, the 'middle' namespace: the scan lists the two symbols main.bas can see, as
# 'tiko --dump-scan' does over the same files. It said parent=2 when this was written, and
# had gone stale unrun while the harness needed an fbc (found 2026-10-10).
if echo "$out" | grep -qF "k2 Twice as long  @3:3:17  parent=1  body=3..5" && \
   echo "$out" | grep -qF "k13 middle  @0:1:15"; then
    echo "ok    #import: middle.Twice at middle.bas:3:17"
else
    echo "FAIL  #import"; echo "$out" | sed 's/^/      /'; FAIL=1
fi
[ -e "$SCANCACHE" ] && { echo "FAIL  #import scan wrote a module cache"; FAIL=1; }

# A PACKAGE IMPORT, from a host whose folder has no pkg/ beside it -- the editor's case.
# bin/ has ../pkg, which tiko's beside-the-exe fallback would find, so the harness and the
# DLL are copied out first: only TKP_OPTIONS.pkgDir (--pkg-dir) can find std/ from there.
HOST=$(mktemp -d)
cp "$H" "$DLL" "$HOST/"
# std/strings is a real module (2026-10-10; it was a facade over fb/string.bi until then),
# and its public procedures are listed as FUNCTION (k2) members of the alias (the k13
# record), one per overload, at their declarations in the module's file. Its interface
# still includes fb/array.bi, found through TKP_INCDIR. The alias record exists only when
# the package was found, which is what the pkgDir checks test.
STDINC=$(cygpath -w "$ROOT/toolchains/tiko-windows/inc")
printf '#import "std/strings"
print strings.Reverse( "tiko" )
' > "$HOST/usestd.tiko"
out=$(TKP_INCDIR="$STDINC" TKP_PKGDIR=$(cygpath -w "$ROOT/pkg") "$HOST/tkpdump.exe" "$HOST/parser.dll" "$HOST/usestd.tiko" dump 2>&1)
if echo "$out" | grep -qE "k13 strings" && echo "$out" | grep -qF "diags: 0"; then
    echo "ok    #import std/strings through pkgDir"
else
    echo "FAIL  #import std/strings through pkgDir"; echo "$out" | sed 's/^/      /'; FAIL=1
fi
ALIAS=$( echo "$out" | sed -n 's/^  \[\([0-9]*\)\] k13 strings .*/\1/p' | head -1 )
if [ -n "$ALIAS" ] && [ "$( echo "$out" | grep -cE "k2 Replace as u?string  @[0-9]+:[0-9]+:[0-9]+  parent=$ALIAS " )" = 3 ]; then
    echo "ok    strings.Replace is a member of strings: its three overloads"
else
    echo "FAIL  strings.Replace as a member of strings (alias record '$ALIAS')"; echo "$out" | grep -E "k13 strings|Replace" | sed 's/^/      /'; FAIL=1
fi
out=$(TKP_INCDIR="$STDINC" "$HOST/tkpdump.exe" "$HOST/parser.dll" "$HOST/usestd.tiko" dump 2>&1)
if echo "$out" | grep -qE "k13 strings"; then
    echo "FAIL  std/strings resolved with no pkgDir -- this check proves nothing"; FAIL=1
else
    echo "ok    ...and without pkgDir it is not found (the check is live)"
fi
rm -rf "$HOST"

# v5: one unsaved buffer, and a '#module' file standing for its whole module.
out=$(TKP_PKGDIR=$(cygpath -w "$ROOT/pkg") TKP_OVERLAY="tests/api/src/partialscan/frm/frm.design.tiko=tests/api/src/partialscan/unsaved/frm.design.tiko" \
      $H $DLL tests/api/src/partialscan/frm/frm.tiko dump 2>&1)
if echo "$out" | grep -qF "txtFresh as string" && echo "$out" | grep -qF "Count as long"; then
    echo "ok    v5: overlay and module root through the DLL"
else
    echo "FAIL  v5: overlay and module root"; echo "$out" | sed 's/^/      /'; FAIL=1
fi

[ "$FAIL" = "0" ] && echo "apitest: ok" || { echo "apitest: FAILED"; exit 1; }
