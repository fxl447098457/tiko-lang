#!/bin/bash
# tkadb.sh -- tkControls' self-tests on an Android device, each built as an app (docs/tiko-android
# A5). A self-test prints '<name> selftest: N passed, M failed' and FAIL lines, and ends with the
# failure count; under 'tiko -app' its PRINT goes to logcat (tag tiko), which this reads.
#
#   bash build/tkadb.sh [--target android-x86_64|android-arm64] [--only tkButton,tkLabel]
#                       [--timeout 120] [--out DIR] [--keep]
#
# For each examples/tkControls/<name>/selftest.tiko, in name order: 'tiko -app' (id
# org.tiko.selftest.<name>), install, start, wait for the summary line, the process to die, or
# the timeout; then uninstall unless --keep. Per test, DIR/<name>.log holds the build output and
# the app's logcat; the table is DIR/table.txt and stdout, one 'tkadb: <name> ...' line each,
# then a total.
#
#   ANDROID_HOME     the SDK (default %LOCALAPPDATA%\Android\Sdk), as build/adbrun.sh
#   ANDROID_SERIAL   the device
#   JAVA_HOME        the JDK -app needs (jar, keytool, apksigner)
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
T=android-x86_64; ONLY=; TMO=120; OUT=; KEEP=0
while [ $# -gt 0 ]; do
    case $1 in
        --target) T=$2; shift 2 ;;
        --only) ONLY=,$2,; shift 2 ;;
        --timeout) TMO=$2; shift 2 ;;
        --out) OUT=$2; shift 2 ;;
        --keep) KEEP=1; shift ;;
        *) echo "tkadb: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
export MSYS_NO_PATHCONV=1
SDK=${ANDROID_HOME:-${LOCALAPPDATA:-}/Android/Sdk}
ADB=$SDK/platform-tools/adb.exe
[ -x "$ADB" ] || ADB=$SDK/platform-tools/adb
[ -x "$ADB" ] || { echo "tkadb: no adb in $SDK/platform-tools (set ANDROID_HOME)" >&2; exit 3; }
TIKO=$ROOT/bin/tiko.exe; [ -x "$TIKO" ] || TIKO=$ROOT/bin/tiko
[ -n "$OUT" ] || OUT=$ROOT/build/.tkadb/$T
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd); : > "$OUT/table.txt"     # absolute: each build runs in its test's directory
# A module cache of its own: other sessions share the per-user default (examples/tkControls/tools/run-all.sh).
export TIKO_MODCACHE=${TIKO_MODCACHE:-$(dirname "$OUT")/modcache}
m( ) { if command -v cygpath > /dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
A( ) { "$ADB" "$@"; }

# A device that never dims or asks: the one-time full-screen prompt takes the first input and
# dims the app (docs/tiko-android FACTS A4).
A shell settings put secure immersive_mode_confirmations confirmed > /dev/null 2>&1
A shell svc power stayon true > /dev/null 2>&1
A shell input keyevent KEYCODE_WAKEUP > /dev/null 2>&1

tp=0; tf=0; nok=0; nbad=0
for st in "$ROOT"/examples/tkControls/*/selftest.tiko; do
    name=$(basename "$(dirname "$st")")
    [ -z "$ONLY" ] || case $ONLY in *,$name,*) ;; *) continue ;; esac
    pkg=org.tiko.selftest.$(printf '%s' "$name" | tr 'A-Z' 'a-z')
    log=$OUT/$name.log; apk=$OUT/$name.apk
    # The files a test reads beside itself go into its APK's assets at the same relative path,
    # where OPEN and std/fs find them (docs/tiko-android A6 step 2): fixtures/, and the resource
    # files a designed app ships (appResources/files/).
    aa=(); rm -rf "$OUT/$name.assets"
    for sub in fixtures appResources/files; do
        [ -d "$(dirname "$st")/$sub" ] || continue
        mkdir -p "$OUT/$name.assets/$(dirname "$sub")"
        cp -r "$(dirname "$st")/$sub" "$OUT/$name.assets/$(dirname "$sub")/"
        aa=(-appassets "$(m "$OUT/$name.assets")")
    done
    ( cd "$(dirname "$st")" && "$TIKO" -target $T -app selftest.tiko -p "$(m "$ROOT/lib/rt/lib/$T")" \
        -appid $pkg -applabel "$name selftest" "${aa[@]}" -x "$(m "$apk")" ) > "$log" 2>&1
    if [ ! -f "$apk" ]; then
        line="tkadb: $name BUILD FAILED"
    else
        A uninstall $pkg > /dev/null 2>&1
        A install -r "$(m "$apk")" > /dev/null 2>&1
        A logcat -c
        A shell am start -n $pkg/org.tiko.app.TikoActivity > /dev/null 2>&1
        sum=; t0=$(date +%s); seen=0
        while :; do
            sleep 2
            lc=$(A logcat -d -v brief 2>/dev/null | tr -d '\r')
            sum=$(printf '%s\n' "$lc" | grep -E 'I/tiko .*selftest: [0-9]+ passed, [0-9]+ failed' | tail -1)
            [ -n "$sum" ] && break
            if [ -n "$(A shell pidof $pkg | tr -d '\r')" ]; then seen=1
            elif [ $seen = 1 ]; then break; fi
            [ $(( $(date +%s) - t0 )) -ge "$TMO" ] && break
        done
        sleep 1
        A logcat -d -v brief 2>/dev/null | tr -d '\r' | grep -E '/tiko|SDL/APP|FATAL|Fatal signal|AndroidRuntime|DEBUG' \
            | grep -v 's_glBind' >> "$log"
        if [ -n "$sum" ]; then
            p=$(printf '%s' "$sum" | sed 's/.*selftest: \([0-9]*\) passed.*/\1/')
            f=$(printf '%s' "$sum" | sed 's/.* passed, \([0-9]*\) failed.*/\1/')
            tp=$((tp + p)); tf=$((tf + f)); nok=$((nok + 1))
            line="tkadb: $name $p passed $f failed"
        elif grep -q 'Fatal signal\|FATAL EXCEPTION' "$log"; then
            line="tkadb: $name CRASHED (no summary)"
        else
            line="tkadb: $name NO SUMMARY ($([ $seen = 1 ] && echo 'ended' || echo 'never started') or timed out)"
        fi
        [ $KEEP = 1 ] || A uninstall $pkg > /dev/null 2>&1
    fi
    case $line in *" passed "*) ;; *) nbad=$((nbad + 1)) ;; esac
    echo "$line" | tee -a "$OUT/table.txt"
done
echo "tkadb: [$T] $nok ran to a summary, $nbad did not; $tp passed, $tf failed" | tee -a "$OUT/table.txt"
