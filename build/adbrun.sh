#!/bin/sh
# adbrun.sh -- run a staged set of programs on the Android device adb reaches, and bring back
# what each printed and how it exited (docs/tiko-android A2, D-A2-5). The device half of
# build/hostgate.sh --adb and build/stdsuite.sh --adb; lib/rt/build/adblane.sh does the same
# for the runtime's parity programs.
#
#   build/adbrun.sh <stage> [timeout-seconds] [workers]
#
# <stage> holds <stage>/list -- one line per program, '<key> <cwd>' -- and for each key a
# directory <stage>/<key>/ that is that program's own tree: the executable at <key>/<key> and
# whatever data it reads, with <cwd> (relative to <key>/, '.' for the top) the directory it runs
# in. It is pushed whole, every program runs once on the device -- in <cwd>, with HOME and
# TMPDIR set to it, stdin closed and toybox's timeout (124 on expiry) -- spread over <workers>
# shells, and the results come back as <stage>/out/<key>.out (stdout and stderr) and
# <stage>/out/<key>.rc (the exit code). The device's copy is removed afterwards.
#
# ONE PUSH AND ONE PULL, not an adb round trip per program: the fbc corpus is 2,700 files.
# MSYS would rewrite /data/local/tmp in adb's arguments, so it is told not to, and the paths
# handed to adb.exe are C:/... (cygpath -m).
#
#   ANDROID_HOME   the SDK (default %LOCALAPPDATA%\Android\Sdk); its platform-tools/adb runs
#   ADB_SERIAL     a device to choose when more than one is attached
set -u
STAGE=${1:?usage: adbrun.sh <stage> [timeout] [workers]}
TMO=${2:-180}
WORKERS=${3:-4}
export MSYS_NO_PATHCONV=1
SDK=${ANDROID_HOME:-${LOCALAPPDATA:-}/Android/Sdk}
ADB=$SDK/platform-tools/adb.exe
[ -x "$ADB" ] || ADB=$SDK/platform-tools/adb
[ -x "$ADB" ] || { echo "adbrun: no adb in $SDK/platform-tools (set ANDROID_HOME)" >&2; exit 3; }
adb_( ) { if [ -n "${ADB_SERIAL:-}" ]; then "$ADB" -s "$ADB_SERIAL" "$@"; else "$ADB" "$@"; fi; }
adb_ get-state > /dev/null 2>&1 || { echo "adbrun: adb reaches no device" >&2; exit 3; }
[ -f "$STAGE/list" ] || { echo "adbrun: no $STAGE/list" >&2; exit 3; }
command -v cygpath > /dev/null 2>&1 && SM=$(cygpath -m "$STAGE") || SM=$STAGE
# ADBRUN_DIR: the device directory, so two runs at once (a suite and a probe) do not collide.
D=${ADBRUN_DIR:-/data/local/tmp/tkadb}

cat > "$STAGE/run.sh" <<EOF
cd $D || exit 2
mkdir -p out
one( ) {
    chmod 755 "$D/\$1/\$1" 2> /dev/null
    ( cd "$D/\$1/\$2" && HOME=\$PWD TMPDIR=\$PWD timeout $TMO "$D/\$1/\$1" < /dev/null > "$D/out/\$1.out" 2>&1
      echo \$? > "$D/out/\$1.rc" )
}
w=0
while [ \$w -lt $WORKERS ]; do
    ( i=0
      while read -r key cwd; do
          [ \$((i % $WORKERS)) -eq \$w ] && one "\$key" "\$cwd"
          i=\$((i + 1))
      done < list ) &
    w=\$((w + 1))
done
wait
echo "adbrun: done"
EOF
sed -i 's/\r$//' "$STAGE/run.sh" "$STAGE/list"

adb_ shell "rm -rf $D && mkdir -p $D" > /dev/null
# The stage's directories, pushed as one tree; out/ is the device's to write.
rm -rf "$STAGE/out"
adb_ push "$SM/." "$D/" > "$STAGE/push.log" 2>&1 || { echo "adbrun: push failed (see $STAGE/push.log)" >&2; exit 3; }
adb_ shell "sh $D/run.sh" > "$STAGE/run.log" 2>&1
mkdir -p "$STAGE/out"
adb_ pull "$D/out/." "$SM/out/" > "$STAGE/pull.log" 2>&1
adb_ shell "rm -rf $D" > /dev/null
n=$(ls "$STAGE/out" 2>/dev/null | grep -c '\.rc$')
echo "adbrun: $n of $(wc -l < "$STAGE/list" | tr -d ' ') programs ran"
