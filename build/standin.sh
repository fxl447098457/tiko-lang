# standin.sh -- sourced by build/stdsuite.sh and build/hostgate.sh: a stand-in for the packaged
# linux-arm64 toolchain, which does not exist until docs/tiko-linux-arm64 L5.
#
#   . "$ROOT/build/standin.sh"; TC=$(standin_linux_arm64)      (needs ROOT and TKO)
#
# What a packaged toolchain's inc/ and lib/linux-arm64/ hold, from this tree: inc/ is the tree's
# own; lib/linux-arm64/ links the runtime (lib/rt/lib/linux-arm64) and the graphics library
# (lib/gfx/lib/linux-arm64) and holds libfbcunit.a, built here from tests/vendor/fbc-tests/fbcunit
# by the tree's tiko as build/package.sh builds it -- the suite drivers '#inclib "fbcunit"'.
# Kept in build/.standin/; a missing piece is laid out again, an existing one is left.
standin_linux_arm64( ) {
    _si=$ROOT/build/.standin/tiko-linux-arm64
    _sl=$_si/lib/linux-arm64
    # The first version linked lib/linux-arm64 to the runtime's directory itself: writing
    # libfbcunit.a through that link would land in lib/rt/lib.
    [ -L "$_sl" ] && rm -f "$_sl"
    mkdir -p "$_sl"
    ln -sfn "$ROOT/inc" "$_si/inc"
    for _f in "$ROOT"/lib/rt/lib/linux-arm64/* "$ROOT"/lib/gfx/lib/linux-arm64/*; do
        [ -f "$_f" ] && ln -sfn "$_f" "$_sl/$(basename "$_f")"
    done
    if [ ! -f "$_sl/libfbcunit.a" ]; then
        _fu=$ROOT/tests/vendor/fbc-tests/fbcunit
        _fo=$ROOT/build/.standin/fbcunit-obj
        _ar=${TIKO_AR:-$(command -v llvm-ar 2>/dev/null || command -v ar)}
        rm -rf "$_fo"; mkdir -p "$_fo"
        for _fs in "$_fu"/src/*.bas; do
            "$TKO" -target linux-arm64 -c "$_fs" -i "$_fu/inc" -i "$_fu/src" \
                -o "$_fo/$(basename "$_fs" .bas).o" >> "$_fo/log" 2>&1
        done
        "$_ar" rcs "$_sl/libfbcunit.a" "$_fo"/*.o >> "$_fo/log" 2>&1 || \
            echo "standin: libfbcunit.a not built -- $_fo/log" >&2
    fi
    echo "$_si"
}
