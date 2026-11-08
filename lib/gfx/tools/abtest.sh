#!/bin/sh
# abtest.sh -- pixel-exactness A/B against gfxlib2, on every ABI we ship.
#
# ORIGINAL WORK. Part of libtkogfx (LGPL-2.1-or-later with the static-linking
# exception).
#
# gate-abi.sh checks the ABI seam -- that we agree with the runtime about memory.
# This checks the RASTER OUTPUT -- that we agree with gfxlib2 about pixels.
#
# THE MinGW CONFIGURATIONS (unchanged)
#
# Each abtest-* program asks gfxlib2 to draw a case into an IMAGECREATE buffer,
# draws the same case itself into an identical buffer, and compares digests. No
# object substitution needed, so raster work can be verified from the first
# primitive rather than after the whole library exists.
#
# THE MSVC CONFIGURATION
#
# libtkogfx's shipping target is windows-x86_64, and that is the one configuration
# the in-process A/B cannot reach: gfxlib2 is a MinGW archive (libfbgfx.a) and
# an MSVC-ABI binary cannot link it. There is no shim -- the two CRTs disagree
# about FILE, about errno, about argument validation.
#
# So the two sides are separated in time instead. gfxlib2 answers are constants;
# they are recorded once, under MinGW, into golden/, and the MSVC build compares
# against the recording without ever naming gfxlib2. See abtest.bi for the three
# compile-time roles and msvc-manifest.txt for which source has which shape.
#
# The recording cannot go stale unnoticed: every win64 MinGW run re-emits it and
# fails if the checked-in bytes disagree. --record is the only thing that
# rewrites it, and its diff is meant to be read.
#
# Usage: tools/abtest.sh [--keep] [--record]
#          --keep     leave the built exes in $TMP
#          --record   rewrite golden/ from gfxlib2 instead of checking it

HERE=$( cd "$( dirname "$0" )" && pwd )
GFX=$( cd "$HERE/.." && pwd )
: "${FBC:=${TIKO_ORACLE_FBC:-/c/dev/fbc-modern/toolchains/fbc-modern-windows/fbc64.exe}}"
: "${CLANG:=$( command -v clang 2>/dev/null || echo "/c/Program Files/LLVM/bin/clang.exe" )}"

TKOGFX_MSVC="$GFX/lib/windows-x86_64/libtkogfx.a"
LIBFB_MSVC="$GFX/../rt/lib/windows-x86_64/libfb.a"
# The import libraries tiko's own windows-x86_64 link resolves the CRT and Win32
# through (build/implibs.sh builds them). See the windows-x86_64 link below.
: "${MSVC_IMPLIBS:=$( cd "$GFX/../.." && pwd )/toolchains/tiko-windows/lib/windows-x86_64}"

keep=0
record=0
for a in "$@"; do
    case $a in
        --keep)   keep=1 ;;
        --record) record=1 ;;
        *) echo "abtest: unknown argument $a" >&2 ; exit 3 ;;
    esac
done

if [ ! -x "$FBC" ]; then
    echo "abtest: SKIPPED -- no oracle fbc at $FBC (TIKO_ORACLE_FBC, or FBC)"
    exit 0
fi

TMP=$( mktemp -d )
[ "$keep" = 1 ] || trap 'rm -rf "$TMP"' EXIT

mkdir -p "$HERE/golden"

status=0

# The manifest is the list, not the directory: a source nobody has classified
# should fail the gate rather than quietly not run in it.
manifest() {
    sed 's/#.*//' "$HERE/msvc-manifest.txt" | awk 'NF >= 2 { print $1, $2 }'
}

for src in "$HERE"/abtest-*.bas "$HERE"/probe-driver.bas "$HERE"/probe-gdi.bas "$HERE"/probe-window.bas; do
    [ -f "$src" ] || continue
    name=$( basename "$src" .bas )
    if ! manifest | grep -q "^$name "; then
        echo "abtest: $name -- NOT IN msvc-manifest.txt (classify it)" >&2
        status=1
    fi
done

# ---------------------------------------------------------------- MinGW
#
# probe-driver is a unit test rather than an A/B (gfxlib2 driver table is
# internal and its presentation is only observable by eye), but it runs in the
# same four configurations and fails the same way, so it lives here.
# probe-window opens a REAL WINDOW and reads pixels back off it, so it needs a
# desktop session -- it cannot run on a headless runner and will fail there
# rather than skip. That is deliberate: the checks it makes (client size,
# orientation, dirty presentation) have no offscreen equivalent.
for src in "$HERE"/abtest-*.bas "$HERE"/probe-driver.bas "$HERE"/probe-gdi.bas "$HERE"/probe-window.bas; do
    [ -f "$src" ] || continue
    name=$( basename "$src" .bas )
    mode=$( manifest | awk -v n="$name" '$1 == n { print $2 }' )

    for cfg in "win64|" "win64-mt|-mt" "win32|-target win32" "win32-mt|-target win32 -mt"; do
        label=${cfg%%|*}
        flags=${cfg#*|}

        if ! "$FBC" -d nullptr=0 $flags -gen llvm "$src" -x "$TMP/$name-$label.exe" \
                 > "$TMP/$name-$label.err" 2>&1; then
            echo "abtest: $name/$label -- FAILED TO BUILD" >&2
            sed -n '1,8p' "$TMP/$name-$label.err" >&2
            status=1
            continue
        fi

        if "$TMP/$name-$label.exe" > "$TMP/$name-$label.out" 2>&1; then
            # The SKIPPED, SEEDED and KNOWN lines are the honest part of a
            # result: they say what was NOT compared. Printing only the PASS
            # line would hide exactly the thing worth reading.
            grep -E "SKIPPED|SEEDED|KNOWN|: PASS" "$TMP/$name-$label.out" |
                sed "s/^/abtest: $label -- /"
        else
            echo "abtest: $name/$label -- PIXELS DIFFER FROM gfxlib2" >&2
            cat "$TMP/$name-$label.out" >&2
            status=1
        fi
    done

    # ------------------------------------------------------------ recording
    #
    # One configuration only. The recording is what gfxlib2 answers, and that
    # does not depend on whether OUR build is -mt or win32; recording it four
    # times would only invite four ways to disagree.
    [ "$mode" = "split" ] || continue

    gold="$HERE/golden/$name.txt"
    if ! "$FBC" -d nullptr=0 -gen llvm -d ABTEST_EMIT "$src" -x "$TMP/$name-emit.exe" \
             > "$TMP/$name-emit.err" 2>&1; then
        echo "abtest: $name -- FAILED TO BUILD IN THE ABTEST_EMIT ROLE" >&2
        sed -n '1,8p' "$TMP/$name-emit.err" >&2
        status=1
        continue
    fi
    if ! "$TMP/$name-emit.exe" > "$TMP/$name.emitted" 2>&1; then
        echo "abtest: $name -- gfxlib2 could not produce a recording" >&2
        cat "$TMP/$name.emitted" >&2
        status=1
        continue
    fi

    if [ "$record" = 1 ]; then
        if [ -f "$gold" ] && cmp -s "$gold" "$TMP/$name.emitted"; then
            echo "abtest: recorded -- $name unchanged"
        else
            cp "$TMP/$name.emitted" "$gold"
            echo "abtest: recorded -- $name REWRITTEN, read the diff"
        fi
    elif [ ! -f "$gold" ]; then
        echo "abtest: $name -- no recording; run tools/abtest.sh --record" >&2
        status=1
    elif ! cmp -s "$gold" "$TMP/$name.emitted"; then
        echo "abtest: $name -- THE RECORDING IS STALE (gfxlib2 no longer agrees with golden/$name.txt)" >&2
        diff "$gold" "$TMP/$name.emitted" >&2
        status=1
    fi
done

# ---------------------------------------------------------------- windows-x86_64
#
# fbc stops at the .ll (-r) and clang is given the triple we want; the .ll is
# not edited, because clang --target overrides the module own triple line. Same
# two-step as lib/rt/build/diffmsvc.sh, and for the same reason.
if [ ! -x "$CLANG" ]; then
    echo "abtest: no clang at $CLANG -- windows-x86_64 NOT RUN (set CLANG)" >&2
    status=1
elif [ ! -f "$TKOGFX_MSVC" ]; then
    echo "abtest: no $TKOGFX_MSVC -- windows-x86_64 NOT RUN (run build/build.sh)" >&2
    status=1
elif [ ! -f "$LIBFB_MSVC" ]; then
    echo "abtest: no $LIBFB_MSVC -- windows-x86_64 NOT RUN (build tiko-rt for windows-x86_64)" >&2
    status=1
elif [ ! -f "$MSVC_IMPLIBS/ucrtbase.lib" ]; then
    echo "abtest: no ucrtbase.lib in $MSVC_IMPLIBS -- windows-x86_64 NOT RUN (run build/implibs.sh build --out <dir>)" >&2
    status=1
else
    ran=0
    manifest | while read -r name mode; do
        case $mode in
            native) role="" ;;
            split)  role="-d ABTEST_SUT" ;;
            *)      continue ;;
        esac
        src="$HERE/$name.bas"
        if [ ! -f "$src" ]; then
            echo "abtest: $name is in the manifest but has no source" >&2
            exit 1
        fi

        ll="$TMP/$name-msvc.ll"
        obj="$TMP/$name-msvc.o"
        exe="$TMP/$name-msvc.exe"
        log="$TMP/$name-msvc.log"
        rm -f "$ll" "$obj"

        if ! "$FBC" -d nullptr=0 -c "$src" -m "$name" -target win64 -gen llvm -r $role \
                 -o "$obj" > "$log" 2>&1; then
            echo "abtest: $name/windows-x86_64 -- FAILED TO EMIT IR" >&2
            sed -n '1,8p' "$log" >&2
            exit 1
        fi
        if [ ! -f "$ll" ]; then
            echo "abtest: $name/windows-x86_64 -- fbc emitted no .ll" >&2
            exit 1
        fi

        if ! "$CLANG" --target=x86_64-pc-windows-msvc -march=x86-64 -O2 \
                 -Wno-override-module "$ll" -c -o "$obj" >> "$log" 2>&1; then
            echo "abtest: $name/windows-x86_64 -- DOES NOT ASSEMBLE FOR MSVC, see $log" >&2
            exit 1
        fi

        # An unresolved fb_Gfx* here is not a build accident: it means the
        # source still calls gfxlib2 in-process, so the manifest is wrong.
        #
        # THE LINK tiko ITSELF DOES for windows-x86_64 (src/codegen/toolchain.tiko):
        # lld, '-nostdlib' so no Visual Studio CRT, ucrtbase.dll plus tiko-rt's
        # msvccrt.o in its place, and kernel32 named because '-nostdlib' drops
        # it. NOT -llegacy_stdio_definitions -- msvccrt.o defines sprintf, and
        # the two collide. No -lwinspool/-lgdi32 here: LIBFB_MSVC is built from
        # the current sources, whose printer driver loads both DLLs at runtime.
        # tiko's MSVC link line still names them, but only for the seed's older
        # prebuilt libfb.a that the suite links.
        if ! "$CLANG" --target=x86_64-pc-windows-msvc -fuse-ld=lld "$obj" \
                 "$TKOGFX_MSVC" "$LIBFB_MSVC" -o "$exe" \
                 -nostdlib "-L$( cygpath -m "$MSVC_IMPLIBS" )" -lucrtbase -lkernel32 \
                 -luser32 -ladvapi32 -lwinmm -lmsimg32 -lversion -limm32 -lws2_32 \
                 -Xlinker /INCLUDE:tkort_msvc_init_ >> "$log" 2>&1; then
            echo "abtest: $name/windows-x86_64 -- DOES NOT LINK, still needs:" >&2
            grep -o 'undefined symbol: [A-Za-z0-9_@$]*' "$log" \
                | sed 's/undefined symbol: /    /' | sort -u >&2
            exit 1
        fi

        if ABTEST_GOLDEN="$HERE/golden" "$exe" > "$TMP/$name-msvc.out" 2>&1; then
            # The SKIPPED and SEEDED lines are the honest part of the result:
            # they say what MSVC did NOT check. Printing only the PASS line
            # would hide exactly the thing worth seeing.
            grep -E "SKIPPED|SEEDED|KNOWN|: PASS" "$TMP/$name-msvc.out" |
                sed "s/^/abtest: windows-x86_64 -- /"
        else
            echo "abtest: $name/windows-x86_64 -- FAILED" >&2
            cat "$TMP/$name-msvc.out" >&2
            exit 1
        fi
    done || status=1

    ran=$( manifest | awk '$2 == "native" || $2 == "split" { n++ } END { print n + 0 }' )
    bound=$( manifest | awk '$2 == "mingw-only" { n++ } END { print n + 0 }' )
    echo "abtest: windows-x86_64 -- $ran source(s) ran, $bound still gfxlib2-bound (msvc-manifest.txt)"
fi

[ "$keep" = 1 ] && echo "abtest: build products left in $TMP"

exit $status
