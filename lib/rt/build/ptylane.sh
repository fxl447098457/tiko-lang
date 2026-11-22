#!/bin/sh
# ptylane.sh -- tiko-rt's CONSOLE BYTES on a terminal, pinned: tests/pty/*.bas run under a pty
# with TERM=xterm-256color on linux-x86_64 (WSL) and macos-arm64 (ssh), output compared with
# tests/pty/<name>.expected.
#
#   lib/rt/build/ptylane.sh [linux-x86_64] [macos-arm64]   (default: both)
#
# WHY A PTY. diff.sh and darwinlane.sh run with stdout redirected, and tiko-rt (like fbc) does
# not drive a console that is not a terminal: COLOR, LOCATE and CLS write nothing there. So a
# console sequence that is wrong in every byte passes both of them. Found 2026-11-20:
# fb_hTermOut wrote COLOR as !"\033[%dm", '!' and not ESC, on every POSIX target.
#
# THE ORACLE IS fbc. Each .expected is fbc's own output for that program, measured on Linux
# (how, in the program's header), rendered with cat -v so ESC reads ^[ and CR reads ^M. A
# <name>.<target>.expected, if present, overrides it for that target -- for a difference that
# is the terminal database's, not the runtime's, and is listed as such in that file's commit.
#
# HOW IT RUNS. script(1) gives the program a pty; its stdout is the capture (util-linux
# 'script -q -e -c CMD /dev/null', BSD 'script -q /dev/null CMD'). tiko-rt asks the terminal
# where the cursor is (ESC[6n) and blocks until it answers, so a feeder answers ESC[1;1R once a
# second, five times. NOT timeout(1): it puts the program in a background process group, and a
# program not in its terminal's foreground drives no console at all -- the capture would be
# empty and would pass against an empty .expected. A 15 s watchdog kills a hang instead.
#
# Needs: bin/tiko and lib/rt/lib/<target>/{fbrt0.o,libfb.a} from this tree
#     (lib/rt/build/build.sh <cfg> linux-x86_64 macos-arm64); WSL with clang and script(1);
#     ssh to the Mac (TIKO_MAC_HOST, default 'mac'; extra options in TIKO_MAC_SSH_OPTS).
# Exits 1 on any difference or failure.

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
RT="$ROOT/lib/rt"
TARGETS=${*:-"linux-x86_64 macos-arm64"}
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) EXT=".exe" ;;
    *) echo "ptylane: run from Windows (it drives WSL and ssh)" >&2; exit 3 ;;
esac
TKO="$ROOT/bin/tiko$EXT"
[ -x "$TKO" ] || { echo "ptylane: build tiko first (build/build.sh)" >&2; exit 3; }
for t in $TARGETS; do
    case "$t" in linux-x86_64|macos-arm64) ;; *) echo "ptylane: unknown target '$t'" >&2; exit 3 ;; esac
    [ -f "$RT/lib/$t/libfb.a" ] && [ -f "$RT/lib/$t/fbrt0.o" ] || \
        { echo "ptylane: no $t runtime (lib/rt/build/build.sh Release $t)" >&2; exit 3; }
done
HOST=${TIKO_MAC_HOST:-mac}
SSHO=${TIKO_MAC_SSH_OPTS:-}

W="$ROOT/build/.ptylane"
rm -rf "$W"
mkdir -p "$W"

# ------------------------------------------------------------------ the run script, one per side
# FILES, not inline commands: a non-login ssh shell has no Homebrew, and inline variables
# expand on the wrong side. Both read 'list' and leave out/<name>.txt (cat -v) per program.
cat > "$W/mac.sh" <<'EOF'
set -u
cd ~/tkm/ptylane || exit 2
CC=/opt/homebrew/opt/llvm/bin/clang
SDK=$(xcrun --show-sdk-path)
mkdir -p out run
while read -r name; do
    if ! $CC -target arm64-apple-macosx13.0 -isysroot $SDK lib/fbrt0.o obj/$name.o -o run/$name \
            -Llib lib/libfb.a -lncurses > out/$name.link 2>&1; then
        print -r -- "LINKFAIL" > out/$name.txt; continue
    fi
    ( sleep 15; pkill -f "^run/$name\$" ) & wd=$!
    ( for i in 1 2 3 4 5; do sleep 1; printf '\033[1;1R'; done; sleep 1 ) | \
        TERM=xterm-256color script -q /dev/null run/$name > out/$name.raw 2> out/$name.err
    kill $wd 2> /dev/null
    cat -v out/$name.raw > out/$name.txt
done < list
print -r -- "rc=0"
EOF
cat > "$W/linux.sh" <<'EOF'
set -u
cd "$1" || exit 2
CC=$(command -v clang || command -v clang-18)
mkdir -p out run
while read -r name; do
    if ! "$CC" -target x86_64-pc-linux-gnu lib/fbrt0.o obj/$name.o -o run/$name \
            -Llib lib/libfb.a -lm -lpthread -ltinfo > out/$name.link 2>&1; then
        echo "LINKFAIL" > out/$name.txt; continue
    fi
    ( sleep 15; pkill -f "^run/$name\$" ) & wd=$!
    ( for i in 1 2 3 4 5; do sleep 1; printf '\033[1;1R'; done; sleep 1 ) | \
        TERM=xterm-256color script -q -e -c run/$name /dev/null > out/$name.raw 2> out/$name.err
    kill $wd 2> /dev/null
    cat -v out/$name.raw > out/$name.txt
done < list
echo "rc=0"
EOF
sed -i 's/\r$//' "$W/mac.sh" "$W/linux.sh"

# ------------------------------------------------------------------ compile, each target
pass=0; diffs=0; buildfail=0
for t in $TARGETS; do
    d="$W/$t"
    mkdir -p "$d/obj" "$d/lib"
    cp "$RT/lib/$t/fbrt0.o" "$RT/lib/$t/libfb.a" "$d/lib/"
    : > "$d/list"
    for src in "$RT"/tests/pty/*.bas; do
        name=$(basename "$src" .bas)
        if "$TKO" -c -m "$name" -target "$t" "$src" -o "$d/obj/$name.o" > "$d/obj/$name.build" 2>&1; then
            echo "$name" >> "$d/list"
        else
            echo "ptylane: FAIL $name -- tiko did not compile it for $t" >&2
            sed 's/^/    /' "$d/obj/$name.build" | head -5 >&2
            buildfail=$((buildfail + 1))
        fi
    done

    # -------------------------------------------------------------- run there
    if [ "$t" = macos-arm64 ]; then
        cp "$W/mac.sh" "$d/run.sh"
        # shellcheck disable=SC2086
        ssh -o BatchMode=yes $SSHO "$HOST" 'rm -rf ~/tkm/ptylane && mkdir -p ~/tkm/ptylane' < /dev/null \
            || { echo "ptylane: no ssh to $HOST" >&2; exit 3; }
        # shellcheck disable=SC2086
        tar -C "$d" -cf - list run.sh obj lib | ssh -o BatchMode=yes $SSHO "$HOST" 'tar -C ~/tkm/ptylane -xf -' \
            || { echo "ptylane: copy to $HOST failed" >&2; exit 3; }
        # shellcheck disable=SC2086
        ssh -o BatchMode=yes $SSHO "$HOST" zsh -l tkm/ptylane/run.sh < /dev/null > "$d/run.log" 2>&1
        # shellcheck disable=SC2086
        ssh -o BatchMode=yes $SSHO "$HOST" 'tar -C ~/tkm/ptylane -cf - out' < /dev/null | tar -C "$d" -xf -
    else
        cp "$W/linux.sh" "$d/run.sh"
        mnt=$(echo "$d" | sed 's#^/\([a-zA-Z]\)/#/mnt/\L\1/#')
        # The run happens on WSL's own disk: a pkill pattern and a pty want a plain path.
        MSYS_NO_PATHCONV=1 wsl.exe -- bash -c "rm -rf ~/ptylane && cp -r '$mnt' ~/ptylane && bash ~/ptylane/run.sh ~/ptylane > ~/ptylane/run.log 2>&1; tar -C ~/ptylane -cf - out run.log" \
            < /dev/null 2> "$d/wsl.err" | tar -C "$d" -xf -
    fi

    # -------------------------------------------------------------- compare
    while read -r name; do
        got="$d/out/$name.txt"
        exp="$RT/tests/pty/$name.$t.expected"
        [ -f "$exp" ] || exp="$RT/tests/pty/$name.expected"
        if [ ! -f "$got" ]; then
            echo "ptylane: FAIL $name [$t] -- no output (see $d/run.log)" >&2
            diffs=$((diffs + 1)); continue
        fi
        if grep -qx 'LINKFAIL' "$got"; then
            echo "ptylane: FAIL $name [$t] -- does not link" >&2
            sed 's/^/    /' "$d/out/$name.link" | head -5 >&2
            diffs=$((diffs + 1)); continue
        fi
        # AN EMPTY CAPTURE IS A FAILURE, whatever it is compared with: it is what a program
        # that never saw a terminal writes.
        if [ ! -s "$got" ]; then
            echo "ptylane: FAIL $name [$t] -- empty capture: the program did not see a terminal" >&2
            diffs=$((diffs + 1)); continue
        fi
        if cmp -s "$exp" "$got"; then
            pass=$((pass + 1))
        else
            echo "ptylane: DIFF $name [$t] (expected, then got; cat -v)" >&2
            echo "  < $(cat "$exp")" >&2
            echo "  > $(cat "$got")" >&2
            diffs=$((diffs + 1))
        fi
    done < "$d/list"
done

echo "ptylane: $pass identical, $diffs different, $buildfail not built ($TARGETS)"
[ "$diffs" = 0 ] && [ "$buildfail" = 0 ]
