#!/bin/sh
# build.sh -- build tiko-lang with the stage0 compiler: a tiko seed.
#
#   build/build.sh [Debug|Release|RelWithDebInfo|MinSizeRel] [--test-runner] [--no-dll] [--oracle]
#   build/build.sh [Release|MinSizeRel] --dll
#   TIKO_SEED=<tkEdit's compiler> build/build.sh Release --lib
#
# A compiler build also builds the editor's bin/parser.dll and copies it beside tkEdit
# ($TIKO_EDITOR_DIR, default tkedit/bin in this tree), which loads it from there. '--no-dll'
# skips both; '--dll' builds the DLL alone.
#
# The Windows peer is build/build.bat and is kept line-for-line analogous.
# Configuration flags live here and nowhere else (docs/plan/02 section 3).

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CFG=${1:-Debug}
# '--dll' anywhere: build the editor's parser.dll INSTEAD of the compiler (below).
# '--no-dll': the compiler without it -- for the gate, bootstrap and packaging, which
# have no use for an editor's scanner and should not pay for one.
DLL=0
SCANLIB=0  # never LIB: vcvars64.bat exports it, the linker's library folders
NODLL=0
TESTRUNNER=0
ORACLE=0
for a in "$@"; do
    case "$a" in
        --dll)         DLL=1 ;;
        --lib)         SCANLIB=1 ;;
        --no-dll)      NODLL=1 ;;
        --test-runner) TESTRUNNER=1 ;;
        --oracle)      ORACLE=1 ;;
    esac
done
# FBC CANNOT BUILD THIS TREE ANY MORE: tiko-lang's source imports std/containers and std/fs
# (2026-10-10), and fbc has no modules. '--oracle' -- fbc building the compiler, for the
# bootstrap plan's V5 -- ended with seed-3, whose V5 was the last; MinSizeRel was fbc's gcc
# backend and went with it. fbc stays the ORACLE of the comparison scripts (TIKO_ORACLE_FBC),
# which compile test programs, never this tree.
if [ "$ORACLE" = "1" ] || [ "$CFG" = "MinSizeRel" ]; then
    echo "build: --oracle and MinSizeRel built the compiler with fbc, which cannot build it since" >&2
    echo "build: its source imports the std modules (2026-10-10); seed-3's V5 was the last" >&2
    exit 2
fi
case "$CFG" in
    --dll|--lib)          CFG=Release ;;
    --no-dll|--test-runner|--oracle) CFG=Debug ;;
esac

# Executable suffix. Without this the script writes bin/tiko on Windows while
# everything else looks for bin/tiko.exe, and the stale .exe keeps being tested.
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) HOSTWIN=1; EXT=".exe" ;;
    *)                    HOSTWIN=0; EXT="" ;;
esac
# The editor's parser library: a DLL, a .so, or on macOS a .dylib.
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) DLLEXT=.dll ;; Darwin) DLLEXT=.dylib ;; *) DLLEXT=.so ;; esac

# stage0: overridable, because the pinned commit moves at phase boundaries only.
#
# THE SEED IS STAGE0: a tiko -- seed/seed.lock pins the one releases are built from:
#   TIKO_SEED=<path to a tiko executable>   that tiko;
#   otherwise                              build/defaultseed.sh's default_seed: the
#                                          fetched pinned seed, else a packaged toolchain.
#
# '--oracle' builds with the fbc TIKO_ORACLE_FBC names instead, as the ORACLE and nothing
# else: diverse double-compiling (the bootstrap plan's V5) builds the tree with it and
# compares, and MinSizeRel is fbc's gcc backend. A FLAG, not the variable alone: the
# oracle scripts read TIKO_ORACLE_FBC too, and a fence that points it nowhere must not
# turn every build into an fbc build. Nothing a package ships is built this way.
# TKO_STAGE0 WAS fbc's name until 2026-10-10, when fbc left the build path. It is ignored,
# and said so: an old environment builds with the seed, which is what it should do.
# The seed compiles only what IT understands, so its flags are its own (below) -- the
# seed-compatibility rule: tiko-lang's source may use a feature only once the pinned seed
# compiles it.
. "$ROOT/build/defaultseed.sh"
if [ -n "${TKO_STAGE0:-}" ]; then
    echo "build: TKO_STAGE0 is retired and ignored -- the seed is stage0; an fbc for the oracle is TIKO_ORACLE_FBC" >&2
fi
SEEDED=0
if [ "$ORACLE" = "1" ]; then
    STAGE0=${TIKO_ORACLE_FBC:-}
    [ -n "$STAGE0" ] || { echo "build: --oracle builds with the fbc TIKO_ORACLE_FBC names, and it names none" >&2; exit 3; }
else
    if [ -z "${TIKO_SEED:-}" ]; then
        if ! TIKO_SEED=$(default_seed "$ROOT" "$HOSTWIN"); then
            echo "build: no seed compiler. Fetch the pinned one (seed/fetch-seed.sh), package a" >&2
            echo "build: toolchain (build/package.sh), or set TIKO_SEED to a tiko" >&2
            exit 3
        fi
    fi
    SEEDED=1
    STAGE0=$TIKO_SEED
fi

if [ ! -x "$STAGE0" ]; then
    echo "build: stage0 compiler not found at $STAGE0" >&2
    if [ "$SEEDED" = "1" ]; then
        echo "build: TIKO_SEED must name a tiko executable" >&2
    else
        echo "build: TIKO_ORACLE_FBC must name an fbc executable" >&2
    fi
    exit 3
fi
# The output flag: fbc's is -x, tiko's -o.
OUTOPT="-x"
[ "$SEEDED" = "1" ] && OUTOPT="-o"

# THE TREE'S OWN HEADERS, inc/ (phase H of the bootstrap plan): every stage0 compile
# reads fb/, crt/ and the rest from here, not from whatever stage0 brought. A seed gets
# them as TIKO_INCLUDE -- its ONLY default directory then, so a header missing from inc/
# fails here instead of being found in the seed's copy -- and fbc as '-i inc', ahead of
# its own. An inherited TIKO_INCLUDE is overridden on purpose: a variable left over from
# a probe must not decide what the compiler is built against.
INCOPT=""
if [ -d "$ROOT/inc" ]; then
    if [ "$SEEDED" = "1" ]; then
        TIKO_INCLUDE="$ROOT/inc"; export TIKO_INCLUDE
    else
        INCOPT="-i inc"
    fi
fi
# ...AND THE TREE'S OWN PACKAGES, pkg/: the compiler's source imports std/containers and
# std/fs (2026-10-10), and they are the tree's, not the copy in the seed's pkg/ -- the same
# rule as inc/. TIKO_PKG is searched before the compiler's own pkg/, and its module cache is
# keyed by the sources' content, so a change to pkg/std rebuilds what imports it.
TIKO_PKG="$ROOT/pkg"; export TIKO_PKG
# ...and the same again under the seed's old TKO_* names (defaultseed.sh, seed_env).
seed_env

case "$CFG" in
    Debug)          FLAGS="-g -exx -w all" ;;
    RelWithDebInfo) FLAGS="-g -w all" ;;
    # -O 2 like everything else in this tree. Release passed no optimization flag at
    # all, so the shipped compiler was built at fbc's default -- which is -O 0 --
    # while lib/rt's Release is "-O 2 -w all" and lib/gfx's is OPT=2. The compiler
    # was the only piece not optimized in its own release build.
    #
    # NOT "-O s". fbc ACCEPTS it and silently does nothing: measured on a 3600-line
    # program, "-O s" produced 132,608 bytes, byte for byte what no flag at all
    # produces, while "-O 2" gave 99,328. Real size optimization needs the gcc
    # backend ("-gen gcc -Wc -Os", 84,480), which is a backend change, not a flag.
    Release)        FLAGS="-O 2 -w all" ;;
    # SIZE, AND IT IS A BACKEND CHANGE. '-O s' is not the answer -- measured on
    # this compiler, 2026-09-17: '-O 2' gives 1,781,760 bytes, '-O s' gives
    # 10,202,624, and passing NO optimization flag at all gives 10,202,624 as
    # well, byte for byte. fbc accepts '-O s' and drops it on the floor: on
    # '-gen llvm' it reaches clang as '-O0', measured the same day. So asking for
    # size with it does not merely fail to shrink the binary, it makes it 5.7
    # times bigger than Release.
    #
    # The gcc backend takes '-Wc -Os' and means it: 1,532,416 bytes, 14.0% under
    # Release, in the same 31 seconds. It is the same source through a different
    # code generator, so it is verified like any other configuration -- the suite
    # is what says the two agree, not the flag.
    MinSizeRel)     FLAGS="-gen gcc -Wc -Os -w all" ;;
    *) echo "build: unknown configuration '$CFG'" >&2; exit 2 ;;
esac

# ...AND A SEED'S. The same intent per configuration, in the seed's own spelling: no
# '-w' (tiko warns by default, and the seed predates its '-w'), '-O2' joined. MinSizeRel
# IS fbc's gcc backend and nothing else, so a seed refuses it rather than build
# something that is not what the name says.
if [ "$SEEDED" = "1" ]; then
    case "$CFG" in
        Debug)          FLAGS="-g -exx" ;;
        RelWithDebInfo) FLAGS="-g" ;;
        Release)        FLAGS="-O2" ;;
        MinSizeRel)
            echo "build: MinSizeRel is fbc's gcc backend (-gen gcc), which a tiko seed has not got;" >&2
            echo "build: it is built only by an fbc ('--oracle', TIKO_ORACLE_FBC), and never shipped" >&2
            exit 2 ;;
    esac
fi

# The first entry of sources.txt is the main module; -m makes that explicit so the
# runtime initialises the command line before any module constructor runs.
SOURCES=$(grep -v '^[[:space:]]*#' "$ROOT/build/sources.txt" | grep -v '^[[:space:]]*$')
MAIN=$(echo "$SOURCES" | head -1)
MAINMOD=$(basename "$MAIN" .tiko)

mkdir -p "$ROOT/bin" "$ROOT/build/obj/$CFG"

# THE UNITS IN PARALLEL, THEN ONE LINK. A single fbc call over every source compiles them one
# after another: measured 2026-10-05 on 8 cores, 136 s for a Debug compiler, where one 'fbc
# -c' per unit, TIKO_JOBS at a time (default: one per processor), then a link of the objects
# takes about 35. The same flags reach every unit and the main module still gets '-m', so
# the program is the one the single call built -- the suite passes against it unchanged.
#
# EVERY UNIT, EVERY TIME: there is no dependency tracking, so no object can be stale -- a
# header edit cannot leave a unit built against the old one. The objects live under
# build/obj/<what>/, not beside the sources, so two builds of one tree no longer write the
# same intermediate files either. Each unit's output is collected and printed in source
# order once all have finished; a unit that left no object fails the build.
#
#   compile_units <objdir> <main module or ""> <flags> <sources...>   -> $OBJS
JOBS=${TIKO_JOBS:-$(nproc 2>/dev/null || echo 4)}
compile_units( ) {
    cu_dir=$1; cu_main=$2; cu_flags=$3; shift 3
    rm -rf "$cu_dir"; mkdir -p "$cu_dir"
    printf '%s\n' "$@" > "$cu_dir/units.txt"
    export STAGE0 cu_dir cu_main cu_flags INCOPT
    ( cd "$ROOT" && xargs -P "$JOBS" -I{} sh -c '
        f="{}"; n=$(echo "$f" | tr "/." "__")
        m=""; [ "$(basename "$f" .tiko)" = "$cu_main" ] && m="-m $cu_main"
        "$STAGE0" -c "$f" $m -i src $INCOPT $cu_flags -o "$cu_dir/$n.o" > "$cu_dir/$n.log" 2>&1
        exit 0' < "$cu_dir/units.txt" )
    OBJS=""
    cu_fail=0
    while IFS= read -r f; do
        n=$(echo "$f" | tr "/." "__")
        [ -s "$cu_dir/$n.log" ] && cat "$cu_dir/$n.log"
        if [ -f "$cu_dir/$n.o" ]; then
            OBJS="$OBJS $cu_dir/$n.o"
        else
            echo "build: $f did not compile" >&2
            cu_fail=1
        fi
    done < "$cu_dir/units.txt"
    [ "$cu_fail" = "0" ] || exit 1
}

# THE EDITOR'S DLL, bin/parser.dll (src/api; contract src/api/tikoparser.ti): the
# compiler's own sources less the main module, plus the entry points. Built INSTEAD of the
# compiler, so bin/tiko and the build stamp are not touched. NEVER WITH -exx: a failed
# runtime check ends the PROCESS, and in a DLL the process is the editor. fbc writes the
# import library bin/libparser.dll.a beside it.
#
# THE EDITOR LOADS IT FROM BESIDE ITS EXE, so a Windows build copies it there: tkEdit's
# tkedit/bin, or $TIKO_EDITOR_DIR (another editor, or /nonexistent for none). A failed copy is
# a WARNING, never a failed build: the usual cause is a running editor, which holds the DLL
# open, and the compiler that was just built is still good.
build_dll( ) {
    DLLFLAGS=$(echo "$FLAGS" | sed 's/-exx//')
    # '-mt' SAID, not inferred: tikoparser.tiko starts a thread, and fbc marks the object
    # that does as needing the threaded runtime. One call over every source made the whole
    # link threaded; units compiled apart left the others unmarked and fbc warned (20,
    # mixed multithreading). Saying it gives the same link and no warning.
    DLLFLAGS="$DLLFLAGS -mt"
    LIBSRC=$(echo "$SOURCES" | tail -n +2)
    echo "build: parser.dll [$CFG] with $STAGE0"
    if [ "$SEEDED" = "1" ]; then
        ( cd "$ROOT" && "$STAGE0" -dll $LIBSRC src/api/tikoparser.tiko -i src $DLLFLAGS \
            -o "bin/parser$DLLEXT" )
    else
        compile_units "$ROOT/build/obj/$CFG-dll" "" "$DLLFLAGS" $LIBSRC src/api/tikoparser.tiko
        ( cd "$ROOT" && "$STAGE0" -dll $OBJS $DLLFLAGS -x "bin/parser$DLLEXT" )
    fi
    [ "$HOSTWIN" = "1" ] || return 0
    EDITOR=${TIKO_EDITOR_DIR:-$ROOT/tkedit/bin}
    # ONLY AN OPTIMISED DLL GOES INTO THE EDITOR. A Debug build is ~44 MB, runs -O 0 frames
    # in the editor's process and overflowed its stack on deep input (audit F-53); it stays
    # in bin/. 'build/build.sh Release --dll' is the one that updates the editor.
    if [ "$CFG" = "Debug" ]; then
        echo "build: Debug parser.dll stays in bin/ -- the editor takes a Release one (build.sh Release --dll)"
    elif [ ! -d "$EDITOR" ]; then
        echo "build: no editor at $EDITOR -- parser.dll stays in bin/ (set TIKO_EDITOR_DIR)"
    elif cp -f "$ROOT/bin/parser.dll" "$EDITOR/parser.dll"; then
        echo "build: parser.dll -> $EDITOR"
    else
        echo "build: WARNING: could not copy parser.dll to $EDITOR -- is the editor running?" >&2
    fi
}

# THE EDITOR'S SCANNER AS A STATIC ARCHIVE, bin/parser_<os>_<arch>.a -- what tkEdit links in
# (tkedit/src/svc/parser; it is one file, docs/tkEdit/SINGLE-FILE.md). The same sources and
# flags as the DLL. BUILD IT WITH THE COMPILER THAT BUILDS tkEdit (TIKO_SEED): the archive holds
# that compiler's std module objects, and at tkEdit's link each std module is ONE copy -- one
# from another compiler would be taken silently in place of tkEdit's own.
build_lib( ) {
    LIBFLAGS="$(echo "$FLAGS" | sed 's/-exx//') -mt"
    LIBSRC=$(echo "$SOURCES" | tail -n +2)
    case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) _os=windows ;; Darwin) _os=macos ;; *) _os=linux ;; esac
    case "$(uname -m)" in arm64|aarch64) _arch=arm64 ;; *) _arch=x86_64 ;; esac
    _out="bin/parser_${_os}_${_arch}.a"
    echo "build: $_out [$CFG] with $STAGE0"
    rm -f "$ROOT/$_out"
    ( cd "$ROOT" && "$STAGE0" -lib $LIBSRC src/api/tikoparser.tiko -i src $LIBFLAGS -o "$_out" )
    [ -f "$ROOT/$_out" ] || { echo "build: no $_out" >&2; exit 1; }
}

if [ "$SCANLIB" = "1" ]; then
    build_lib
    echo "build: ok"
    exit 0
fi

if [ "$DLL" = "1" ]; then
    build_dll
    echo "build: ok"
    exit 0
fi

echo "build: tiko-lang [$CFG] with $STAGE0"
# ...and the same for the compiler OFF WINDOWS, where driver/main.tiko starts its big-stack
# thread with threadcreate (Windows uses CreateThread, which fbc does not see).
CFLAGS_="$FLAGS"
[ "$HOSTWIN" = "1" ] || CFLAGS_="$FLAGS -mt"
# A SEED COMPILES THE WHOLE PROGRAM IN ONE CALL, as build/bootstrap.sh's stages do: tiko
# runs clang over the modules several at a time already, and measured 17-33 s for all of
# them where fbc's per-unit build below takes ~42.
if [ "$SEEDED" = "1" ]; then
    ( cd "$ROOT" && "$STAGE0" $SOURCES -m "$MAINMOD" -i src $CFLAGS_ -o "bin/tiko$EXT" )
else
    compile_units "$ROOT/build/obj/$CFG" "$MAINMOD" "$CFLAGS_" $SOURCES
    ( cd "$ROOT" && "$STAGE0" $OBJS $CFLAGS_ -x "bin/tiko$EXT" )
fi

if [ "$TESTRUNNER" = "1" ]; then
    echo "build: tiko-test [$CFG]"
    ( cd "$ROOT" && "$STAGE0" tools/tiko-test/tikotest.tiko -i src $INCOPT $FLAGS -mt $OUTOPT "bin/tiko-test$EXT" )
fi

# WHAT bin/ NOW HOLDS, for anything that needs to know whether it is the right thing.
# build/test.sh skips the build when nothing changed, and a timestamp alone cannot tell
# a Debug binary from a Release one: 'build.sh Release' leaves bin/tiko newer than every
# source, so the Debug suite would have run the Release binary and said nothing about it.
mkdir -p "$ROOT/build/obj"
printf '%s' "$CFG|$STAGE0" > "$ROOT/build/obj/.build-stamp"

[ "$NODLL" = "1" ] || build_dll

echo "build: ok"
