#!/usr/bin/env bash
# publish-site.sh -- build the book, its PDF and tiko by Example, and put them on tiko-lang.net.
#
#   build/publish-site.sh                 book, PDF and by-example from origin/master
#   build/publish-site.sh --release       the same, plus the landing page for the latest release
#   build/publish-site.sh --release-only  the landing page alone
#   build/publish-site.sh --dry-run       build and check, upload and commit nothing
#   build/publish-site.sh --ref <ref>     build another commit
#
# The build runs in a throwaway worktree, so nothing uncommitted in this checkout is published.
# Each site is unpacked outside the web root and then swapped in whole, which also removes what
# the build no longer produces. The previous version stays in ~/.tiko-publish/<name>.prev on the
# server (not in the domain folder, which Hostinger marks DO_NOT_UPLOAD_HERE).
#
# THE PDF LIVES IN THE BOOK'S FOLDER. Everything links
# https://tiko-lang.net/book/the-tiko-programming-language.pdf, and the swap replaces book/ whole,
# so a tree without the PDF would delete it. It is copied in before the tar and refused if absent.
#
# The server is the ssh alias 'tiko-site' (~/.ssh/config); this file is public and names no host.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_HOST="${TIKO_SITE_SSH:-tiko-site}"
DOMAIN_DIR="domains/tiko-lang.net"
STAGE=".tiko-publish"
SITE_URL="https://tiko-lang.net"
PDF_NAME="the-tiko-programming-language.pdf"
WEBSITE="${TIKO_WEBSITE:-$root/../tiko-website}"
PYTHON="${PYTHON:-python}"

ref="origin/master"; docs=1; release=0; dry=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --release)      release=1 ;;
    --release-only) release=1; docs=0 ;;
    --dry-run)      dry=1 ;;
    --ref)          ref="${2:?--ref needs a commit}"; shift ;;
    *) echo "publish-site: unknown argument $1" >&2; exit 2 ;;
  esac
  shift
done

say() { echo "publish-site: $*"; }
die() { echo "publish-site: ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------- one run at a time
tmp=""; locked=0
lock="${TMPDIR:-/tmp}/tiko-publish.lock"
cleanup() {
  if [[ -n "$tmp" ]]; then
    git -C "$root" worktree remove --force "$tmp/wt" 2>/dev/null || true
    git -C "$root" worktree prune 2>/dev/null || true
    rm -rf "$tmp"
  fi
  if (( locked )); then rmdir "$lock" 2>/dev/null || true; fi
}
trap cleanup EXIT
mkdir "$lock" 2>/dev/null || die "another publish is running (or died): remove $lock if not"
locked=1

# ---------------------------------------------------------------- checks
# Every page SUMMARY.md lists must have been built. This, not a comparison with the live site,
# is the guard against a broken build: the live folders can hold leftovers.
check_tree() {
  local name="$1" src="$2" tree="$3" missing=0 count=0 md html
  [[ -s "$tree/index.html" ]] || die "$name: no index.html in the build"
  while IFS= read -r md; do
    html="${md%.md}.html"
    html="${html#./}"
    [[ "$html" == "README.html" ]] && html="index.html"
    count=$((count + 1))
    if [[ ! -s "$tree/$html" ]]; then
      echo "publish-site: $name: missing page $html" >&2
      missing=$((missing + 1))
    fi
  done < <(grep -oE '\]\([^)#]+\.md' "$src/SUMMARY.md" | sed 's/^](//' | sort -u)
  (( count >= 30 )) || die "$name: only $count pages listed in SUMMARY.md"
  (( missing == 0 )) || die "$name: $missing of $count pages were not built"
  say "$name: all $count pages built, $(find "$tree" -type f | wc -l) files"
}

check_pdf() {
  local pdf="$1" size
  [[ -f "$pdf" ]] || die "the PDF is not in the book tree: $pdf"
  size=$(wc -c < "$pdf")
  (( size > 1048576 )) || die "the PDF is only $size bytes"
  [[ "$(head -c 4 "$pdf")" == "%PDF" ]] || die "$pdf is not a PDF"
  say "PDF: $size bytes, in the book's folder"
}

sha_of() { sha256sum "$1" | cut -d' ' -f1; }

# The live file must be byte for byte the one just built. Retries cover a slow edge.
verify_live() {
  local url="$1" file="$2" want_type="${3:-}" got ctype want attempt
  want=$(sha_of "$file")
  for attempt in 1 2 3 4; do
    ctype=$(curl -fsSL -m 60 -A 'Mozilla/5.0' -o "$tmp/live.bin" -w '%{content_type}' "$url" || echo FETCH-FAILED)
    got=""
    [[ -f "$tmp/live.bin" ]] && got=$(sha_of "$tmp/live.bin")
    if [[ "$got" == "$want" && ( -z "$want_type" || "$ctype" == "$want_type"* ) ]]; then
      say "live OK: $url"
      return 0
    fi
    sleep 5
  done
  die "live check failed: $url (type '$ctype', sha $got, wanted $want)"
}

# ---------------------------------------------------------------- the docs
publish_docs() {
  git -C "$root" fetch -q origin
  local commit
  commit=$(git -C "$root" rev-parse --short=9 "$ref^{commit}")
  say "building $ref ($commit)"
  git -C "$root" worktree add -q --detach "$tmp/wt" "$commit"
  local wt="$tmp/wt"

  (cd "$wt/book" && bash build/site.sh >/dev/null 2>&1) || die "book site build failed"
  (cd "$wt/book" && bash build/pdf.sh >/dev/null 2>&1) || die "PDF build failed"
  (cd "$wt/by-example" && bash build/site.sh >/dev/null 2>&1) || die "by-example build failed"

  cp "$wt/book/out/$PDF_NAME" "$wt/book/book/$PDF_NAME"

  check_tree book "$wt/book/src" "$wt/book/book"
  check_tree by-example "$wt/by-example/src" "$wt/by-example/book"
  check_pdf "$wt/book/book/$PDF_NAME"

  if (( dry )); then say "dry run: docs built and checked, nothing uploaded"; return 0; fi

  local n tree
  for n in book by-example; do
    tree="$wt/$n/book"
    say "uploading $n"
    tar -czf - -C "$tree" . | ssh "$SSH_HOST" "set -e; mkdir -p $STAGE; rm -rf $STAGE/$n.new; mkdir $STAGE/$n.new; tar -xzf - -C $STAGE/$n.new; chmod -R u=rwX,go=rX $STAGE/$n.new"
    local here there
    here=$(find "$tree" -type f | wc -l)
    there=$(ssh "$SSH_HOST" "find $STAGE/$n.new -type f | wc -l")
    [[ "$here" -eq "$there" ]] || die "$n: built $here files, the server unpacked $there; nothing swapped"
  done

  # Both uploaded and counted before either goes live.
  ssh "$SSH_HOST" bash -s -- "$DOMAIN_DIR/public_html" "$STAGE" <<'REMOTE'
set -e
web="$1"; stage="$2"
for n in book by-example; do
  rm -rf "$stage/$n.prev"
  mv "$web/$n" "$stage/$n.prev"
  if ! mv "$stage/$n.new" "$web/$n"; then
    mv "$stage/$n.prev" "$web/$n"
    echo "swap of $n failed; previous version restored" >&2
    exit 1
  fi
done
REMOTE
  say "swapped book and by-example"

  verify_live "$SITE_URL/book/$PDF_NAME" "$wt/book/book/$PDF_NAME" application/pdf
  verify_live "$SITE_URL/book/index.html" "$wt/book/book/index.html"
  verify_live "$SITE_URL/by-example/index.html" "$wt/by-example/book/index.html"
}

# ---------------------------------------------------------------- the landing page
publish_landing() {
  [[ -f "$WEBSITE/tools/set-release.py" ]] || die "no tiko-website at $WEBSITE"
  local branch
  branch=$(git -C "$WEBSITE" branch --show-current)
  git -C "$WEBSITE" fetch -q origin
  [[ -z "$(git -C "$WEBSITE" status --porcelain)" ]] || die "tiko-website has uncommitted changes"
  [[ "$(git -C "$WEBSITE" rev-parse HEAD)" == "$(git -C "$WEBSITE" rev-parse "origin/$branch")" ]] \
    || die "tiko-website is not level with origin/$branch"

  local result
  if (( dry )); then
    result=$("$PYTHON" "$WEBSITE/tools/set-release.py" --dry-run | tail -1)
    say "dry run, landing page: $result"
    return 0
  fi
  result=$("$PYTHON" "$WEBSITE/tools/set-release.py" | tail -1)
  case "$result" in
    CHANGED\ *)
      git -C "$WEBSITE" add index.html assets/tiko.js
      git -C "$WEBSITE" commit -q -m "${result#CHANGED }"
      git -C "$WEBSITE" push -q origin "HEAD:$branch"
      say "tiko-website: ${result#CHANGED }" ;;
    CURRENT\ *) say "landing page already at ${result#CURRENT }" ;;
    *) die "set-release said: $result" ;;
  esac

  # Files are overwritten, never swapped: the web root also holds what this repo does not own.
  tar -czf - -C "$WEBSITE" index.html assets | ssh "$SSH_HOST" "set -e; mkdir -p $STAGE; rm -rf $STAGE/landing.new; mkdir $STAGE/landing.new; tar -xzf - -C $STAGE/landing.new; chmod -R u=rwX,go=rX $STAGE/landing.new; cp -f $STAGE/landing.new/assets/* $DOMAIN_DIR/public_html/assets/; cp -f $STAGE/landing.new/index.html $DOMAIN_DIR/public_html/index.html; rm -rf $STAGE/landing.new"
  verify_live "$SITE_URL/index.html" "$WEBSITE/index.html"
  verify_live "$SITE_URL/assets/tiko.js" "$WEBSITE/assets/tiko.js"
}

tmp=$(mktemp -d "${TMPDIR:-/tmp}/tiko-publish.XXXXXX")
if (( docs )); then publish_docs; fi
if (( release )); then publish_landing; fi
say "done"
