# defaultseed.sh -- sourced, not run: default_seed prints the seed stage0 builds with when
# neither TIKO_SEED nor TIKO_ORACLE_FBC says otherwise, or returns 1 when there is none.
#
#   . "$ROOT/build/defaultseed.sh"; SEED=$(default_seed "$ROOT" "$HOSTWIN")
#
# build.sh, test.sh and bootstrap.sh share it so the three cannot disagree about which
# compiler built bin/. build/defaultseed.bat is the Windows peer.
#
# IN THIS ORDER, first that exists:
#   1. <root>/seed/cache/<host>/...   the PINNED seed, as seed/fetch-seed.sh unpacks it;
#   2. <root>/toolchains/tiko-<host>  a locally packaged toolchain (build/package.sh) --
#      the seed until one is published, which is what seed/seed.lock says;
#   3. both again in the MAIN checkout, found through git's common directory: a worktree
#      junctions only toolchains/.../inc and lib, never the compiler beside them.

default_seed( ) {
    ds_root=$1
    if [ "$2" = "1" ]; then ds_host=windows; ds_rel="tiko-windows/tiko.exe"
    elif [ "$(uname -s)" = "Darwin" ]; then ds_host=macos; ds_rel="tiko-macos/bin/tiko"
    # aarch64 Linux is ITS OWN HOST, never 'linux': that seed is x86-64 and would not run.
    # seed-10 is the first seed with a linux-arm64 line (seed/fetch-seed.sh unpacks it here).
    elif [ "$(uname -m)" = "aarch64" ]; then ds_host=linux-arm64; ds_rel="tiko-linux-arm64/bin/tiko"
    else                    ds_host=linux;   ds_rel="tiko-linux/bin/tiko"; fi
    ds_main=$(git -C "$ds_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
    [ -n "$ds_main" ] && ds_main=$(dirname "$ds_main")
    for ds_c in "$ds_root/seed/cache/$ds_host/$ds_rel" "$ds_root/toolchains/$ds_rel" \
                ${ds_main:+"$ds_main/seed/cache/$ds_host/$ds_rel"} ${ds_main:+"$ds_main/toolchains/$ds_rel"}; do
        if [ -x "$ds_c" ]; then echo "$ds_c"; return 0; fi
    done
    return 1
}

# seed_env -- THE PINNED SEED READS THE OLD NAMES. The compiler's environment variables were
# renamed TKO_* -> TIKO_* on 2026-11-06, and a seed built before that reads only TKO_*. This
# mirrors each variable the compiler reads into its old name -- set, or unset when the TIKO_
# one is empty -- so the seed sees what a current compiler would. A compiler that reads TIKO_*
# ignores the copies. Drop it, and its callers, once the pinned seed reads TIKO_*.
seed_env( ) {
    for se_v in INCLUDE LIBPATH PKG MODCACHE PATH CLANG AR LIBCLANG SDKROOT JOBS; do
        eval "se_x=\${TIKO_$se_v:-}"
        if [ -n "$se_x" ]; then eval "TKO_$se_v=\$se_x; export TKO_$se_v"; else unset "TKO_$se_v"; fi
    done
}
