#!/bin/sh
# symbols.sh -- Gate 1, mechanised.
#
#   build/symbols.sh [target ...]
#
# For every symbol tiko-rt defines, assert that fbc's own archive defines a
# symbol with the BYTE-IDENTICAL name, on every target.
#
# This is the check that catches the whole class of win32 decoration mistakes,
# and it is worth having as a script rather than as an occasional look, because
# the failure is invisible until link time and then total:
#
#   FBCALL entry points     _fb_WstrCompare@8   -- stdcall, @N = argument bytes
#   non-FBCALL internals    _fb_hListInit       -- cdecl, no suffix
#
# Getting the @N wrong by four bytes produces a symbol that does not resolve; and
# omitting it produces one that resolves against nothing, silently, until a
# program calls it.
#
# win64 and linux-x86_64 have no decoration at all, so **they cannot catch any of
# this** -- which is the point of running it on all three.

set -eu

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/oracle.sh"
rt_check_tools
rt_oracle_check symbols.sh

TARGETS=${*:-$RT_TARGETS}
fails=0
checked=0

for target in $TARGETS; do
    rt_is_target "$target" || rt_die "unsupported target '$target'"

    ours="$RT_ROOT/lib/$target/libfb.a"
    [ -f "$ours" ] || rt_die "no tiko-rt archive at $ours -- run build/build.sh first"

    refdir=$(rt_reflib "$target") || rt_die "no reference libfb.a for $target"
    theirs="$refdir/libfb.a"

    # R IS IN BOTH SETS; T/D/B ALONE IS NOT ENOUGH.
    #
    # fbc puts its const tables -- __fb_utf8_trailingTb and friends -- in
    # read-only data, which nm reports as 'R'. With R left out of the set the
    # reference is built from, every read-only symbol we matched CORRECTLY was
    # reported as "not defined by fbc's libfb.a": a false failure, and the worst
    # kind, because it points at working code and says the ABI is broken.
    #
    # R is in the set we check FROM for the same reason. A table we place in
    # .data and fbc places in .rdata is still the same symbol under the same
    # name, and this script compares NAMES, not sections.
    "$TKORT_NM" --defined-only "$theirs" 2>/dev/null \
        | awk '$2=="T"||$2=="D"||$2=="B"||$2=="R"{print $3}' | sort -u > "$RT_ROOT/obj/.ref.$target"

    # Names beginning with '.' are skipped. Admitting R above brought in the
    # backend's COMDAT thunks -- .refptr.___fb_ctx and friends, emitted once per
    # object that references a global and folded by the linker. fbc's archive has
    # none to match against, so every one read as an ABI failure. They are
    # compiler bookkeeping, not interface; build/build.sh's duplicate check
    # excludes them for the same reason.
    for sym in $("$TKORT_NM" --defined-only "$ours" 2>/dev/null \
                 | awk '($2=="T"||$2=="D"||$2=="B"||$2=="R") && $3 !~ /^[.]/{print $3}' | sort -u); do
        checked=$((checked + 1))
        # tiko's OWN entry points -- int128's tko_Int128ToStr and friends -- have no fbc
        # counterpart by construction: the 'tko_' prefix is reserved for them, and only them.
        case "$sym" in tko_*) continue ;; esac
        if ! grep -qx "$sym" "$RT_ROOT/obj/.ref.$target"; then
            echo "symbols: $target: '$sym' is not defined by fbc's libfb.a" >&2
            # The likeliest cause, named rather than left to be worked out.
            base=$(echo "$sym" | sed 's/@[0-9]*$//; s/^_//')
            alt=$(grep -E "^_?${base}(@[0-9]+)?$" "$RT_ROOT/obj/.ref.$target" || true)
            [ -n "$alt" ] && echo "         fbc spells it: $alt" >&2
            fails=$((fails + 1))
        fi
    done
    rm -f "$RT_ROOT/obj/.ref.$target"
done

if [ "$fails" -gt 0 ]; then
    echo "symbols: $fails mismatch(es) over $checked symbols" >&2
    exit 1
fi
echo "symbols: ok -- $checked symbol names identical to fbc's, across $TARGETS"
