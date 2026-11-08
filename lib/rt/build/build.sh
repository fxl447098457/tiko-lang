#!/bin/sh
# build.sh -- build tiko-rt's archives with tiko.
#
#   build/build.sh [Debug|Release|RelWithDebInfo] [target ...]
#
#   build/build.sh                       Debug, all three targets, st and mt
#   build/build.sh Release win64         Release, win64 only
#   build/build.sh Debug linux-x86_64
#
# Produces  lib/<target>/libfb.a   (single-threaded)
#           lib/<target>/libfbmt.a (ENABLE_MT)
# and on linux-x86_64 also
#           lib/<target>/libfbpic.a, libfbmtpic.a   (the same, position-independent)
#
# THE PIC PAIR IS WHAT A LINUX SHARED LIBRARY LINKS. fbc ships both and names them
# on its '-dll' line ('-lfbpic', measured with 'fbc -dll -v'), and tiko's driver
# names them the same way. fbc's -pic makes its -gen llvm clang call add -fPIC --
# measured with -v, it does reach clang here.
#
# TODAY THE PAIR IS BYTE-IDENTICAL TO THE PLAIN ONE, measured 2026-09-19 with cmp:
# the Linux clang this builds with already emits position-independent code by
# default. The only absolute relocations in either archive are R_X86_64_32 entries
# in the C objects' .debug_* sections, which ld accepts in a .so. The pair exists so
# that a clang whose default is not PIC cannot turn every '-dll' into a relocation
# error -- the flag is the guarantee, the identity is an accident of this clang.
# Windows needs no such variant: COFF has no PIC/non-PIC distinction here.
#
# Both come from ONE source tree, distinguished by -d ENABLE_MT, exactly as the
# C runtime's two builds do.
#
# The archive names are deliberately fbc's own: that is what makes build/gate.sh
# able to drop tiko-rt into fbc's link line and run fbc's suite unmodified
# (docs/tiko-rt/RFC-0001 section 4.1).

set -e

# A WORKER: 'build.sh --one <source> <object>' -- one source to one object, the two
# compiles and nothing else. build_one runs RT_JOBS of these at once and checks every
# object afterwards in one pass. It reads what it needs from the RTW_* variables
# build_one exports and does NOT source common.sh: on Windows every process costs
# ~25 ms under MSYS, and the per-source checks this used to run -- an 'ar t' of fbc's
# archive, two nm pipelines, sort and comm -- were ~0.9 s of each source's ~1.05 s,
# where fbc takes 0.04 s and clang 0.08 s.
rtw_die( ) { echo "tiko-rt: $RTW_WHAT: $*" >&2; exit 2; }
compile_src( ) {
    src=$1
    obj=$2

    # FROM src/, WHATEVER DIRECTORY THE CALLER IS IN. tiko-rt includes its own headers
    # as '#include once "inc/file.ti"', and fbc tries the CURRENT DIRECTORY before any
    # -i. Run from tiko-lang's root -- package.sh does -- that found the root's
    # inc/file.bi, FreeBASIC's, once tiko-lang had an inc/ of its own (phase H,
    # 2026-10-10): FB_FILE undefined in io/devlptopen and three more. From src/, 'inc/'
    # is tiko-rt's. The paths below are all absolute, so nothing else moves.
    cd "$RT_ROOT/src" || rtw_die "no directory $RT_ROOT/src"

    # ONE STEP: tiko targets windows-x86_64 itself, and its per-function sections come
    # from tiko's own clang line. (fbc could not be asked for the Microsoft ABI, so the
    # fbc-built archives took '-gen llvm -r' and then clang with the triple; that path
    # went with fbc, 2026-10-10.)
    "$TKORT_TIKO" -c "$RT_ROOT/src/$src" -target "$RTW_TARGET" $RTW_INC \
        $RTW_FLAGS $RTW_PIC -o "$obj" || rtw_die "$src failed to compile"
    [ -f "$obj" ] || rtw_die "$src produced no object"
}
if [ "${1:-}" = "--one" ]; then
    compile_src "$2" "$3"
    exit 0
fi

. "$(dirname "$0")/common.sh"
rt_check_tools
RT_SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
RT_JOBS=${TKORT_JOBS:-$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}

CFG=${1:-Debug}
FLAGS=$(rt_cfg_flags "$CFG") || rt_die "unknown configuration '$CFG' (Debug|Release|RelWithDebInfo)"
# THE C OBJECTS' DEBUG INFO FOLLOWS THE CONFIGURATION, and names no build directory. Every
# Release libfb.a object carried its -cc1 line -- the worktree's path, the MSVC and SDK
# versions -- because -g was passed in every configuration (review BLD-05). The prefix map
# rewrites the tree's absolute path to lib/rt in whatever debug info remains.
case "$CFG" in
    Release|MinSizeRel) CDBG="" ;;
    *)                  CDBG="-g" ;;
esac
CMAP="-ffile-prefix-map=$RT_ROOT=lib/rt"
# ...in both spellings on Windows: clang is handed the source as C:/..., not /c/...
if command -v cygpath > /dev/null 2>&1; then
    CMAP="$CMAP -ffile-prefix-map=$(cygpath -m "$RT_ROOT")=lib/rt"
fi
shift 2>/dev/null || true

TARGETS=${*:-$RT_TARGETS}
for t in $TARGETS; do
    rt_is_buildable "$t" || rt_die "unsupported target '$t' (R3: $RT_TARGETS $RT_BUILD_ONLY_TARGETS)"
done

SOURCES=$(rt_sources)

# The variant's flags, directories and reference library: what build_one and a --one
# worker both need, from $target, $thread and $CFG.
thread_vars( ) {
    picdef=""; cpic=""
    case $thread in
        st)    archive=libfb.a;      mtdef="" ;;
        mt)    archive=libfbmt.a;    mtdef="-d ENABLE_MT" ;;
        stpic) archive=libfbpic.a;   mtdef="";             picdef="-pic"; cpic="-fPIC" ;;
        mtpic) archive=libfbmtpic.a; mtdef="-d ENABLE_MT"; picdef="-pic"; cpic="-fPIC" ;;
    esac

    objdir="$RT_ROOT/obj/$target/$CFG/$thread"
    libdir="$RT_ROOT/lib/$target"
}

build_one( ) {
    target=$1
    thread=$2                       # st | mt | stpic | mtpic
    thread_vars
    rm -rf "$objdir"
    mkdir -p "$objdir" "$libdir"

    # THE ARCHIVE IS REMOVED BEFORE THE COMPILE, NOT AFTER IT.
    #
    # build.sh already exits non-zero when a compile fails (verified by planting
    # one), but it used to leave the PREVIOUS run's archive sitting in lib/, so
    # anything reading it afterwards saw a complete, valid, stale library.
    #
    # That is not hypothetical: a linux-only failure in strw/case.tiko let
    # build/symbols.sh report "912 symbol names identical" for a tree that had
    # just failed to build, because the caller piped build.sh through `tail` and
    # `&&` then saw the PIPE's exit status rather than the build's.
    #
    # Removing the archive first makes the failure impossible to read past --
    # every downstream tool dies with "no archive" instead of agreeing with a
    # library nobody just built. Fifth stale-artefact incident here, and the
    # same shape as the other four.
    rm -f "$libdir/$archive"

    # A stale object yields a plausible archive, never an error, so the object
    # directory is removed above rather than reused.

    # THE SOURCES COMPILE IN PARALLEL, RT_JOBS at a time (TKORT_JOBS, else every CPU),
    # each by a --one worker -- see compile_src at the top. The archive below still
    # takes the objects in sources.txt order.
    RTW_WHAT="$target/$thread"
    RTW_INC=$(rt_incflags)
    RTW_FLAGS="$FLAGS $mtdef $(rt_abi_define "$target")"
    RTW_PIC=$picdef
    # THE COMPILER'S TARGET NAME, not this build's: 'win64ucrt' is a FLAVOR of the
    # same tiko target -- same triple, same ABI, different CRT -- and tiko knows
    # 'win64', not the flavor. The flavor travels in RTW_FLAGS as TKORT_UCRT; only
    # the archive and the object directory this build writes differ.
    RTW_TARGET=$target
    case "$target" in win64ucrt) RTW_TARGET=win64 ;; esac
    export TKORT_TIKO CLANG RT_ROOT RTW_WHAT RTW_TARGET RTW_INC RTW_FLAGS RTW_PIC
    rt_sources | awk -v d="$objdir" '{ o = $0; gsub("/", "_", o); sub(/\.tiko$/, ".o", o); print $0, d "/" o }' \
        > "$objdir/.pairs"
    if ! xargs -P "$RT_JOBS" -n 2 sh "$RT_SELF" --one < "$objdir/.pairs"; then
        rt_die "$target/$thread: a source failed to build -- see above"
    fi
    objs=$(awk '{ printf " %s", $2 }' "$objdir/.pairs")

    # THE TWO CHECKS EVERY OBJECT GETS, made ONCE over all of them: one nm of the
    # objects, one of fbc's archive, and one awk joining them by member name.
    #
    # A NAME COLLISION WITH AN fbc MEMBER MUST NOT LOSE SYMBOLS.
    #
    # Objects are named after their source path -- io/input.bas became
    # io_input.o -- and gate.sh merges them INTO fbc's archive, so llvm-ar
    # REPLACES any member of the same name. fbc has an io_input.o of its own,
    # and the merge dropped fb_hConsoleGetKey, fb_ConsoleHasFocus and five
    # more that this project does not define.
    #
    # IT WAS SILENT ON ALL THREE TARGETS. win64 and win32 passed the whole
    # 2,715-file suite with that member gone; only linux-x86_64 failed, and
    # only because time_sleep.c happens to reference one of the lost symbols
    # there.
    #
    # Replacing a member IS the point of the port -- str/core.tiko becomes
    # str_core.o and supplies all ten of its symbols. What must never happen
    # is replacing one by NAME while leaving some of its symbols undefined.
    # So the test is not "does the name collide" but "does the collision lose
    # anything".
    #
    # A SOURCE THAT CONTRIBUTES NO GLOBAL SYMBOL SHIPPED NOTHING.
    #
    # src/error/errmsg.tiko defined __fb_errmsg as a bare "dim shared" inside
    # an EXTERN "c" block, which FreeBASIC emits as a FILE-LOCAL symbol --
    # nm shows lowercase b, not B. tiko-rt's archive therefore still carried
    # an UNDEFINED reference to the name and fbc's own error_message.o kept
    # supplying it.
    #
    # ALL THREE EXISTING CHECKS PASSED. symbols.sh compares the names
    # tiko-rt DOES define, and an absent symbol is not a mismatch. gate.sh
    # deletes fbc's members BY SYMBOL, and there was none to delete. The
    # differential was reading fbc's buffer.
    #
    # A check that compares what was emitted cannot see what was not. This
    # one asks a different question: did this file put anything in the
    # archive at all.
    #
    # A MODULE THAT IS DELIBERATELY EMPTY ON SOME TARGETS MUST SAY SO, with
    # a marker naming them -- io/conprint.tiko is the POSIX console writer and
    # is #ifdef-ed to nothing on Windows. The marker is what separates that
    # from a module that meant to define something and did not.
    "$TKORT_NM" --defined-only $objs > "$objdir/.ours" 2>/dev/null || true
    : > "$objdir/.theirs"
    awk '
        FILENAME == ARGV[1] { n = split($2, p, /[\/\\]/); src[p[n]] = $1; order[++no] = p[n]; next }
        /:$/                { c = $0; sub(/:$/, "", c); n = split(c, p, /[\/\\]/); c = p[n]; next }
        NF == 3 {
            # C, A COMMON SYMBOL, DEFINES THE NAME TOO: the gcc and gas64 backends of fbc,
            # and tiko, measured alike, emit an uninitialised extern+dim as one; only
            # fbc -gen llvm wrote B. __fb_errmsg (error/errmsg.tiko) read as having no
            # global symbols without it. (No apostrophes: this is inside a quoted awk.)
            tdb = ($2 == "T" || $2 == "D" || $2 == "B" || $2 == "C")
            if (FILENAME == ARGV[2]) { if (tdb) th[c] = th[c] " " $3 }
            else {
                if (tdb) ou[c, $3] = 1
                if (tdb || $2 == "R") g[c]++
            }
        }
        END {
            for (i = 1; i <= no; i++) {
                c = order[i]
                if (c in th) {
                    k = split(th[c], ss, " "); m = 0
                    for (j = 1; j <= k && m < 5; j++)
                        if (!((c, ss[j]) in ou)) { print "LOSES", src[c], c, ss[j]; m++ }
                }
                if (!(c in g)) print "EMPTY", src[c], c
            }
        }' "$objdir/.pairs" "$objdir/.theirs" "$objdir/.ours" > "$objdir/.checks"
    _loses=""
    while read -r _k _src _o _sym; do
        [ "$_k" = "LOSES" ] || continue
        if [ "$_loses" != "$_o" ]; then
            [ -z "$_loses" ] || rt_die "rename the source, or define those symbols too"
            echo "build: $_src compiles to $_o, an fbc member name," >&2
            echo "build: so the gate's merge would REPLACE it -- losing:" >&2
            _loses=$_o
        fi
        echo "    $_sym" >&2
    done < "$objdir/.checks"
    [ -z "$_loses" ] || rt_die "rename the source, or define those symbols too"
    while read -r _k _src _o _sym; do
        [ "$_k" = "EMPTY" ] || continue
        # THE PLATFORM, NOT THE ABI. windows-x86_64 is win64 with a different
        # calling-convention-free ABI: the same files are empty on it for
        # the same reasons, and hinitposix.tiko is empty on both because
        # neither is POSIX. Matching the full target name instead would
        # mean adding "windows-x86_64" to every EMPTY-ON line in the tree, and
        # again to each one for any later ABI variant.
        case $target in windows-x86_64|win64ucrt) __base=win64 ;; *) __base=$target ;; esac
        if grep -qE "EMPTY-ON:.*($target|$__base)" "$RT_ROOT/src/$_src" 2>/dev/null; then
            : # declared empty for this target
        else
            echo "build: $_src compiles to an object with NO GLOBAL SYMBOLS on $target." >&2
            echo "build: it is in build/sources.txt but contributes nothing to the archive." >&2
            echo "build: a data definition needs the EXTERN ... ALIAS declaration inside" >&2
            echo "build: an extern block AND the DIM SHARED outside it -- a bare" >&2
            echo "build: dim shared inside the block is file-local. See src/utf/core.tiko." >&2
            echo "build: if the file is empty on this target BY DESIGN, add a comment" >&2
            echo "build: line naming them, e.g.   '' EMPTY-ON: win64" >&2
            rt_die "define something, mark it EMPTY-ON, or take it out of sources.txt"
        fi
    done < "$objdir/.checks"
    rm -f "$objdir/.pairs" "$objdir/.ours" "$objdir/.theirs" "$objdir/.checks"

    # ------------------------------------------------------------ the C residue
    #
    # src/c/ is the closed list of files that stay C, each listed in its README
    # with a reason (RFC-0003 section 4, enforced by lint.sh). It was empty until
    # 2026-09-05 and so there was no C path here at all; the six members the gate
    # still takes from fbc are what made one necessary.
    #
    # CLANG, WITH THE SAME TRIPLE THE FreeBASIC MODULES GOT. For windows-x86_64 that
    # is the whole point: the FB half is retargeted at its assemble step above,
    # and a C object built for the gnu triple beside it would be the one thing in
    # the archive with the wrong ABI.
    #
    # NO fbc HEADERS ON THE INCLUDE PATH, deliberately. Anything here is tiko-rt's
    # own C written against a documented signature, not a transliteration of a
    # body (PROVENANCE.md), and reaching for fb.h is how the second kind starts.
    #
    # -O2 EVEN IN Debug. These are primitives -- an atomic wrapper compiled at -O0
    # is a call around a call -- and there is no tiko-rt source to step through in
    # them. -g (CDBG) is passed outside Release so a backtrace names the file.
    for csrc in $(ls "$RT_ROOT"/src/c/*.c 2>/dev/null); do
        # fbrt0.c IS A LOOSE OBJECT, never a member: nothing refers to it by name, so
        # an archive search would never pull it in. build_rt0 installs it.
        case $(basename "$csrc") in fbrt0.c) continue ;; esac
        cobj="$objdir/$(basename "$csrc" .c).o"
        ctgt=$(rt_clang_triple "$target")
        [ -n "$ctgt" ] || ctgt=$(rt_target_triple "$target")
        # THE SAME ABI DEFINE THE FreeBASIC MODULES GET, spelled -D rather than -d.
        # A C file has no more way than a .bas one to tell win64 from windows-x86_64:
        # fbc compiles both AS win64 and clang defines _MSC_VER for the msvc
        # triple only by accident of which headers it reaches for.
        cabi=""
        case "$target" in windows-x86_64) cabi="-D TKORT_MSVC" ;; esac
        if ! "$CLANG" --target="$ctgt" -O2 $CDBG $CMAP -std=c99 -Wall -Wextra $cabi $cpic \
                -c "$csrc" -o "$cobj"; then
            rt_die "$target/$thread: $(basename "$csrc") failed to compile"
        fi
        objs="$objs $cobj"
    done

    if [ -z "$objs" ]; then
        # S0: no modules yet. An archive with no members is still a valid
        # archive and still proves the whole toolchain path works.
        "$TKORT_AR" rcs "$libdir/$archive"
    else
        "$TKORT_AR" rcs "$libdir/$archive" $objs
    fi

    # ONE SYMBOL, ONE MEMBER. ar will happily archive two objects that define
    # the same symbol; nothing complains until a LINK, and by then the message
    # names .ll files rather than the two sources. This caught a whole family
    # reimplemented in a second file when it already existed in a first -- the
    # archive built clean, the symbol count went UP by the duplicate count, and
    # it looked like progress.
    #
    # Names beginning with '.' are excluded: .refptr.__fb_ctx and friends are
    # COMDAT thunks the backend emits ONCE PER OBJECT THAT REFERENCES THE
    # SYMBOL, so they are duplicated by design and the linker folds them.
    #
    # __real@... and __xmm@... are excluded for exactly the same reason on the
    # MSVC ABI. Under the gnu triple a float constant is an anonymous .rdata
    # label; under msvc clang gives it a NAME derived from its bit pattern and
    # puts it in a COMDAT, so every module using 1.0 defines __real@3ff00...0
    # and the linker folds them. Anything else that collides is still a real
    # duplicate, which is the whole point of this check.
    "$TKORT_NM" --defined-only "$libdir/$archive" 2>/dev/null         | awk '($2=="T"||$2=="D"||$2=="B"||$2=="R") && $3 !~ /^\./ && $3 !~ /^__(real|xmm|ymm|zmm)@/{print $3}'         | sort | uniq -d > "$objdir/.dup.tmp"
    if [ -s "$objdir/.dup.tmp" ]; then
        echo "build: $target/$archive defines these symbols TWICE:" >&2
        sed 's/^/    /' "$objdir/.dup.tmp" >&2
        echo "tiko-rt: a second module reimplements something already present" >&2
        rm -f "$objdir/.dup.tmp" "$libdir/$archive"
        exit 1
    fi
    rm -f "$objdir/.dup.tmp"

    n=$("$TKORT_NM" --defined-only "$libdir/$archive" 2>/dev/null | grep -c ' T ' || true)
    # STAMP THE CONFIGURATION NEXT TO THE ARCHIVE.
    #
    # The OBJECTS are per-configuration -- obj/<target>/<cfg>/<thread> -- but the
    # ARCHIVE is not: lib/<target>/libfb.a is one path that every configuration
    # overwrites. So a tool told "Release" reads whatever was built last, agrees
    # with itself, and reports a number for a library nobody asked for. That is
    # not hypothetical either: an abidelta run in this tree compared a Release
    # MinGW archive against a Debug MSVC one and reported five inlining
    # differences as ABI divergences.
    #
    # Sixth stale-artefact incident, same shape as the five above. The stamp lets
    # a reader of the archive CHECK rather than assume.
    echo "$CFG" > "$libdir/.config"

    echo "build: $target/$archive [$CFG] -- $(echo $objs | wc -w) objects, $n text symbols"
}

# THE STARTUP OBJECT, fbrt0.o, for a gnu target: src/c/fbrt0.c says what it is and
# why it is a loose file in lib/<target>/ rather than a member. A Linux shared library
# links fbrt0pic.o, as fbc's does. windows-x86_64 has msvcinit.c instead and gets none --
# and any left there by an older build is removed, since the driver would not name
# it but a reader of the directory might believe it.
build_rt0( ) {
    _t=$1
    _dir="$RT_ROOT/lib/$_t"
    case $_t in
        windows-x86_64) rm -f "$_dir/fbrt0.o" "$_dir/fbrt0pic.o"; return 0 ;;
    esac
    _tri=$(rt_clang_triple "$_t")
    [ -n "$_tri" ] || _tri=$(rt_target_triple "$_t")
    mkdir -p "$_dir"
    "$CLANG" --target="$_tri" -O2 $CDBG $CMAP -std=c99 -Wall -Wextra \
        -c "$RT_ROOT/src/c/fbrt0.c" -o "$_dir/fbrt0.o" \
        || rt_die "$_t: fbrt0.c failed to compile"
    case $_t in
        linux-*)
            "$CLANG" --target="$_tri" -O2 $CDBG $CMAP -std=c99 -Wall -Wextra -fPIC \
                -c "$RT_ROOT/src/c/fbrt0.c" -o "$_dir/fbrt0pic.o" \
                || rt_die "$_t: fbrt0.c (pic) failed to compile" ;;
    esac
    echo "build: $_t/fbrt0.o$(case $_t in linux-*) echo ' + fbrt0pic.o' ;; esac)"
}

echo "build: tiko-rt [$CFG] with $TKORT_TIKO ($RT_JOBS jobs)"
for target in $TARGETS; do
    build_one "$target" st
    build_one "$target" mt
    case $target in
        linux-*) build_one "$target" stpic
                 build_one "$target" mtpic ;;
    esac
    build_rt0 "$target"
done
echo "build: ok"
