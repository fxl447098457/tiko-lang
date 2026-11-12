#!/bin/sh
# build.sh -- regenerate pkg/std/tzdata/tzdata.tzdb, the zone database std/tzdata embeds.
#
#   sh tools/tzdb/build.sh <tzdata.zi> <version>
#   sh tools/tzdb/build.sh /usr/share/zoneinfo/tzdata.zi 2026f
#
# Runs on Linux or macOS (it needs zic; from Windows run it in WSL). tzdata.zi is the
# whole tz source in one file: a tzdata release's `make tzdata.zi` writes it, and Debian
# and Ubuntu install theirs as /usr/share/zoneinfo/tzdata.zi. THE BUILD MATTERS, NOT
# ONLY THE VERSION: Ubuntu's includes backzone (pre-1970 history of merged zones, e.g.
# Europe/Amsterdam's +00:19:32), a plain release build does not, and Apple's does not.
# The shipped database is Ubuntu 24.04's 2026f, the same build as tests/codegen/tzdata.
#
# zic -b slim: no 32-bit data and no transitions a footer can give, about a third of the
# "fat" size. std/tz reads either.
set -eu
[ $# -eq 2 ] || { sed -n '2,13p' "$0"; exit 2; }
zi=$1
ver=$2
here=$(cd "$(dirname "$0")" && pwd)
out=$(cd "$here/../.." && pwd)/pkg/std/tzdata/tzdata.tzdb
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
zic -b slim -d "$tmp/zi" "$zi"
python3 "$here/pack.py" "$tmp/zi" "$ver" "$out"
