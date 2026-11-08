#!/usr/bin/env bash
# check-listings.sh -- compile and run every listing in the book, on every target.
#
#   tools/check-listings.sh                    both targets, all chapters
#   tools/check-listings.sh --target windows-x86_64
#   tools/check-listings.sh ch01 ch06          only those chapters
#   tools/check-listings.sh --list             show what would run
#
# A listing is examples/chNN/name.tiko (or name.bas, for legacy material). Beside it:
#   name.out    expected stdout (required unless the listing expects a compile error);
#               name.<target>.out, where it exists, replaces it on that target
#   name.exit   expected exit code (default 0)
#   name.args   command-line arguments, one line
#   name.stdin  fed to the program
# A file whose first directive is #module belongs to a module directory and is built
# through the listing that imports it.
#   name.meta   key: value lines --
#                 targets: windows-x86_64          restrict to one target
#                 expect: compile-error TKO0413
#                 modules: a.bas b.bas         extra sources in the same directory
#                 forward: ch16                records a use-before-define
#                 cwd: listing                 compile in the listing's own directory, as a
#                                              reader would -- for a #cmdline -cinclude, which
#                                              is relative to the working directory
#                 prebuild: -lib a.tiko        tiko commands run first, in the listing's
#                                              directory, ';' between them -- a library the
#                                              listing links. Implies cwd: listing; a source
#                                              named here is not a listing of its own
#                 env: LD_LIBRARY_PATH=.       set for the run, on every target
#                 project: greeter             the listing is the main file of a project:
#                                              `tiko build greeter` runs in its directory,
#                                              beside its tiko.toml, and the program run is
#                                              out/debug/greeter -- what `tiko run` runs.
#                                              Implies cwd: listing
#                 linux-libdir: lib/dir        linux-x86_64 only, relative to the project: where
#                                              the WSL host keeps a shared library it does not
#                                              have installed. The build links from it (-p) and
#                                              finds what those libraries need in turn
#                 output: renamed.exe          the listing names its own program (a -x in its
#                                              #cmdline, which wins over the harness's -o):
#                                              that file, in the listing's directory, is run.
#                                              Implies cwd: listing
#                 blocked: T13 linux-x86_64    a known compiler/toolchain defect, and
#                                              where it bites; reported BLOCKED, not FAIL.
#                                              The listing is NEVER weakened to pass --
#                                              the work item gets fixed instead.
#
# Compiler flags belong in the listing itself (#cmdline "-exx"), so the file alone
# reproduces the result.
#
# Exit: 0 all pass, 1 a listing failed, 2 the pin or toolchain is wrong.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# Git Bash rewrites anything that looks like a Unix path before handing it to a Windows
# program, so wsl.exe would receive C:/Program Files/Git/mnt/c/... instead of /mnt/c/...
export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'

# ------------------------------------------------------------------ the pin
yaml_get() { # yaml_get <section> <key>   (flat enough for book.yaml's pin block)
  awk -v sect="$1" -v key="$2" '
    $0 ~ "^  " sect ":" { in_s = 1; next }
    in_s && /^  [a-z_]+:/ { in_s = 0 }
    in_s && $1 == key":" { gsub(/"/, "", $2); print $2; exit }
  ' book.yaml
}

PIN_VERSION="$(awk '/^  version:/ { gsub(/"/, "", $2); print $2; exit }' book.yaml)"
WIN_ROOT="$(yaml_get windows root)";  WIN_EXE="$(yaml_get windows exe)"
LIN_ROOT="$(yaml_get linux root)";    LIN_EXE="$(yaml_get linux exe)"
WSL_DISTRO="$(yaml_get linux wsl_distro)"
MAC_ROOT="$(yaml_get macos root)";    MAC_EXE="$(yaml_get macos exe)"

# THE MAC (docs/tiko-macos M10, D-M10-2). macos-arm64 programs run on a Mac, so that target is
# checked THERE, natively: on a Darwin host it is the local target, as windows-x86_64 is on
# Windows. From Windows, '--target macos-arm64' alone sends this tree to the Mac over ssh
# (TIKO_MAC_HOST, default 'mac'; options in TIKO_MAC_SSH_OPTS), runs this script there, and
# brings its out/ back -- reports and logs, not programs -- as out/macos-arm64/.
# The pin's macos root is relative to the tree there, beside a toolchains/ that links to
# ~/dev/tiko-lang/toolchains.
ON_MAC=0; [[ "$(uname -s)" == Darwin ]] && ON_MAC=1

targets=(windows-x86_64 linux-x86_64)
(( ON_MAC )) && targets=(macos-arm64)
chapters=(); list_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) targets=("${2:?--target needs a name}"); shift ;;
    --list)   list_only=1 ;;
    ch*)      chapters+=("$1") ;;
    *) echo "check-listings: unknown argument $1" >&2; exit 2 ;;
  esac
  shift
done

# The roots in book.yaml are relative to this book directory, which lives inside the
# compiler's repository -- so a clone anywhere works. The Linux side needs the same place
# spelled as WSL sees it.
# --target macos-arm64 FROM WINDOWS: the run happens on the Mac.
if (( ! ON_MAC )) && [[ " ${targets[*]} " == *" macos-arm64 "* ]]; then
  [[ ${#targets[@]} -eq 1 ]] || { echo "check-listings: macos-arm64 runs on the Mac -- ask for it alone" >&2; exit 2; }
  mh="${TIKO_MAC_HOST:-mac}"; mo="${TIKO_MAC_SSH_OPTS:-}"; here="$(basename "$root")"
  # shellcheck disable=SC2086
  tar -cf - --exclude=./out -C "$root" . | ssh -o BatchMode=yes $mo "$mh" \
    "mkdir -p tkm/harness && ln -sfn ~/dev/tiko-lang/toolchains tkm/harness/toolchains && rm -rf tkm/harness/$here && mkdir -p tkm/harness/$here && tar -xf - -C tkm/harness/$here" \
    || { echo "check-listings: could not send the tree to $mh" >&2; exit 2; }
  mkdir -p out/run out/mac-out.tmp
  # A script FILE, run by a login zsh: a non-login ssh shell has no Homebrew on PATH.
  printf 'cd ~/tkm/harness/%s && bash tools/check-listings.sh --target macos-arm64 %s\n' "$here" "${chapters[*]:-}" > out/mac-run.sh
  # shellcheck disable=SC2086
  scp -q -o BatchMode=yes $mo out/mac-run.sh "$mh:tkm/harness/mac-run-$here.sh" || exit 2
  # shellcheck disable=SC2086
  ssh -o BatchMode=yes $mo "$mh" zsh -l "tkm/harness/mac-run-$here.sh" < /dev/null; rrc=$?
  # THE MAC'S out/, its programs left there: reports and logs, into out/macos-arm64/.
  rm -rf out/macos-arm64
  # shellcheck disable=SC2086
  ssh -o BatchMode=yes $mo "$mh" "cd tkm/harness/$here/out && tar -cf - --exclude=bin --exclude=macos-arm64 ." < /dev/null | tar -xf - -C out/mac-out.tmp
  mv out/mac-out.tmp out/macos-arm64
  rm -f out/mac-run.sh
  echo "check-listings: the Mac's reports and logs are in out/macos-arm64/"
  exit $rrc
fi

to_wsl() { cygpath -w "$1" 2>/dev/null | sed -E 's|^([A-Za-z]):|/mnt/\L\1|; s|\\|/|g'; }

win_tiko=""; lin_tiko=""; mac_tiko=""; book_wsl=""
if (( ON_MAC )); then
  mac_tiko="$(cd "$root/$MAC_ROOT" 2>/dev/null && pwd)/$MAC_EXE"
else
  win_tiko="$(cd "$root/$WIN_ROOT" && pwd)/$WIN_EXE"
  lin_tiko="$(to_wsl "$(cd "$root/$LIN_ROOT" && pwd)")/$LIN_EXE"
  book_wsl="$(cygpath -w "$root" 2>/dev/null | sed -E 's|^([A-Za-z]):|/mnt/\L\1|; s|\\|/|g')"
fi

# A stale toolchain yields a plausible number, not an error. Assert the pin first.
assert_pin() {
  local what="$1" got="$2"
  if [[ "$got" != *"$PIN_VERSION"* ]]; then
    echo "check-listings: $what reports '$got', which is not the pinned $PIN_VERSION" >&2
    echo "  update book.yaml's pin deliberately, or point at the pinned toolchain." >&2
    exit 2
  fi
}

# --version says only "0.1.0-dev", which every build says, so it cannot tell two packagings
# apart. The MANIFEST inside each toolchain records the commit it was built from; hold the
# pin to that as well, or a repackaged toolchain silently changes what the book verified.
assert_manifest() {
  local what="$1" manifest="$2" want="$3"
  [[ -n "$want" ]] || return 0
  if [[ ! -f "$manifest" ]]; then
    echo "check-listings: $what has no MANIFEST.txt at $manifest" >&2; exit 2
  fi
  local got; got="$(grep -m1 -oE '^commit +[0-9a-f]{7,40}' "$manifest" | awk '{print $2}')"
  if [[ "$got" != "$want"* && "$want" != "$got"* ]]; then
    echo "check-listings: the $what toolchain was packaged from $got, but book.yaml pins $want." >&2
    echo "  Re-verify the listings and update the pin deliberately." >&2
    exit 2
  fi
}

if (( ON_MAC )); then
  assert_manifest "macos" "$MAC_ROOT/MANIFEST.txt" \
    "$(awk '/^  macos:/,/^  targets:/' book.yaml | awk '/commit:/ { gsub(/"/, "", $2); print $2; exit }')"
else
  assert_manifest "windows" "$(cygpath -u "$WIN_ROOT" 2>/dev/null || echo "$WIN_ROOT")/MANIFEST.txt" \
    "$(awk '/^  windows:/,/^  linux:/' book.yaml | awk '/commit:/ { gsub(/"/, "", $2); print $2; exit }')"
  assert_manifest "linux" "$(cygpath -u "${LIN_ROOT/\/mnt\/c/C:}" 2>/dev/null || echo "$LIN_ROOT")/MANIFEST.txt" \
    "$(awk '/^  linux:/,/^  targets:/' book.yaml | awk '/commit:/ { gsub(/"/, "", $2); print $2; exit }')"
fi

for t in "${targets[@]}"; do
  case "$t" in
    windows-x86_64)
      [[ -x "$win_tiko" ]] || { echo "check-listings: no tiko at $win_tiko" >&2; exit 2; }
      assert_pin "$win_tiko" "$("$win_tiko" --version 2>&1 | head -1)" ;;
    linux-x86_64)
      v="$(wsl -d "$WSL_DISTRO" -- "$lin_tiko" --version 2>&1 | head -1 | tr -d '\r')"
      [[ -n "$v" ]] || { echo "check-listings: no tiko at $lin_tiko (WSL $WSL_DISTRO)" >&2; exit 2; }
      assert_pin "$lin_tiko" "$v" ;;
    macos-arm64)
      (( ON_MAC )) || { echo "check-listings: macos-arm64 runs on the Mac" >&2; exit 2; }
      [[ -x "$mac_tiko" ]] || { echo "check-listings: no tiko at $mac_tiko" >&2; exit 2; }
      assert_pin "$mac_tiko" "$("$mac_tiko" --version 2>&1 | head -1)" ;;
    *) echo "check-listings: unknown target $t" >&2; exit 2 ;;
  esac
done

# ------------------------------------------------------------------ listings
meta_get() { [[ -f "$1" ]] && sed -nE "s/^$2:[[:space:]]*//p" "$1" | head -1; }

all=(); while IFS= read -r _l; do all+=("$_l"); done < <(find examples \( -name '*.tiko' -o -name '*.bas' \) | sed 's|\\|/|g' | sort)
listings=()
for f in "${all[@]}"; do
  # The chapter is the first directory under examples/: a listing may sit deeper, in a
  # project of its own (ch15/app/main.tiko) or among the solutions.
  rel="${f#examples/}"; chap="${rel%%/*}"
  if [[ ${#chapters[@]} -gt 0 ]]; then
    keep=0; for c in "${chapters[@]}"; do [[ "$chap" == "$c" ]] && keep=1; done
    (( keep )) || continue
  fi
  # A file of a module begins with #module (comments may come first). It is compiled
  # through the listing that imports it, never on its own.
  first="$(grep -m1 -vE "^[[:space:]]*('.*)?$" "$f" | tr -d '')"
  [[ "$first" == '#module'* ]] && continue
  # A module named by another listing's meta is built with it, not on its own.
  base="$(basename "$f")"; dir="$(dirname "$f")"
  if grep -qs -- "$base" "$dir"/*.meta 2>/dev/null && ! [[ -f "${f%.*}.meta" ]]; then
    grep -qsE "^(modules|prebuild):.*$base" "$dir"/*.meta && continue
  fi
  listings+=("$f")
done

if (( list_only )); then printf '%s\n' "${listings[@]}"; exit 0; fi
[[ ${#listings[@]} -gt 0 ]] || { echo "check-listings: no listings found"; exit 0; }

mkdir -p out/bin out/run
report="out/listings-report.md"
{ echo "# Listings report"; echo; echo "pin: tiko $PIN_VERSION"; echo;
  hdr="| Listing |"; sep="|---|"
  for t in "${targets[@]}"; do hdr+=" $t |"; sep+="---|"; done
  echo "$hdr Note |"; echo "$sep---|"; } > "$report"

pass=0; fail=0; wide=0; blockedn=0

for f in "${listings[@]}"; do
  base="${f%.*}"; name="$(basename "$base")"; dir="$(dirname "$f")"
  meta="$base.meta"
  only_targets="$(meta_get "$meta" targets)"
  expect="$(meta_get "$meta" expect)"
  modules="$(meta_get "$meta" modules)"
  blocked="$(meta_get "$meta" blocked)"        # e.g. "T13 linux-x86_64"
  cwd="$(meta_get "$meta" cwd)"
  prebuild="$(meta_get "$meta" prebuild)"
  runenv="$(meta_get "$meta" env)"
  project="$(meta_get "$meta" project)"
  output="$(meta_get "$meta" output)"
  linux_libdir="$(meta_get "$meta" linux-libdir)"
  [[ -n "$output" ]] && cwd=listing
  [[ -n "$prebuild" ]] && cwd=listing
  [[ -n "$project" ]] && cwd=listing
  blocked_item="${blocked%% *}"; blocked_where="${blocked#* }"
  srcs=("$f"); for m in $modules; do srcs+=("$dir/$m"); done
  local_srcs=(); for s in "${srcs[@]}"; do local_srcs+=("$(basename "$s")"); done

  # House style: listings fit the book's trim without wrapping.
  long=$(awk 'length > 72 { n++ } END { print n+0 }' "$f")
  (( long )) && { wide=$((wide+1)); }

  results=(); note=""
  for t in "${targets[@]}"; do
    if [[ -n "$only_targets" && "$only_targets" != *"$t"* ]]; then results+=("n/a"); continue; fi

    outdir="out/bin/$t"; mkdir -p "$outdir"
    # LOCAL: compiled and run here. windows-x86_64 on Windows, macos-arm64 on a Mac.
    is_local=0; ltiko=""; xext=""
    case "$t" in
      windows-x86_64) is_local=1; ltiko="$win_tiko"; xext=".exe" ;;
      macos-arm64)    is_local=1; ltiko="$mac_tiko" ;;
    esac
    abs_exe() { if [[ "$t" == windows-x86_64 ]]; then cygpath -m "$root/$1"; else printf '%s' "$root/$1"; fi; }
    log="out/run/$name.$t.log"; rm -f "$log"

    # The prebuild commands, each a tiko invocation in the listing's directory.
    pre_ok=1
    if [[ -n "$prebuild" ]]; then
      IFS=';' read -ra pre_cmds <<< "$prebuild"
      for pc in "${pre_cmds[@]}"; do
        if (( is_local )); then
          ( cd "$dir" && eval "\"$ltiko\" $pc" ) >> "$log" 2>&1 || pre_ok=0
        else
          wsl -d "$WSL_DISTRO" -- bash -c "cd '$book_wsl/$dir' && '$lin_tiko' $pc" >> "$log" 2>&1 || pre_ok=0
        fi
      done
    fi
    if (( ! pre_ok )); then
      results+=("FAIL"); note="prebuild failed: $(head -2 "$log" | tr '\n' ' ' | cut -c1-80)"
      continue
    fi

    [[ -n "$output" ]] && rm -f "$dir/$output"
    if [[ -n "$project" ]]; then
      # A project builds where its tiko.toml is, into its own out/debug.
      if (( is_local )); then
        exe="$dir/out/debug/$project$xext"; rm -f "$exe"
        ( cd "$dir" && "$ltiko" build "$project" ) >> "$log" 2>&1; crc=$?
      else
        exe="$dir/out/debug/$project"; rm -f "$exe"
        wsl -d "$WSL_DISTRO" -- bash -c "cd '$book_wsl/$dir' && ${linux_libdir:+LD_LIBRARY_PATH='$linux_libdir'} '$lin_tiko' build $project ${linux_libdir:+--options '-p $linux_libdir'}" >> "$log" 2>&1; crc=$?
      fi
    elif (( is_local )); then
      exe="$outdir/$name$xext"; rm -f "$exe"
      if [[ "$cwd" == listing ]]; then
        ( cd "$dir" && "$ltiko" "${local_srcs[@]}" -o "$(abs_exe "$exe")" ) >> "$log" 2>&1; crc=$?
      else
        "$ltiko" "${srcs[@]}" -o "$exe" > "$log" 2>&1; crc=$?
      fi
    else
      exe="$outdir/$name"; rm -f "$exe"
      if [[ "$cwd" == listing ]]; then
        wsl -d "$WSL_DISTRO" -- bash -c "cd '$book_wsl/$dir' && '$lin_tiko' ${local_srcs[*]} -o '$book_wsl/$exe'" >> "$log" 2>&1; crc=$?
      else
        wsl -d "$WSL_DISTRO" -- "$lin_tiko" "${srcs[@]/#/$book_wsl/}" -o "$book_wsl/$exe" > "$log" 2>&1; crc=$?
      fi
    fi

    # The listing's own -x named the program: that is the file to run.
    [[ -n "$output" ]] && exe="$dir/$output"
    if [[ -n "$expect" ]]; then           # this listing must NOT compile
      want_id="${expect#compile-error }"
      if (( crc == 0 )); then results+=("FAIL"); note="compiled, but expected $want_id"
      elif grep -q "$want_id" "$log"; then results+=("PASS")
      else results+=("FAIL"); note="failed without $want_id"; fi
      continue
    fi

    if (( crc != 0 )); then
      results+=("FAIL"); note="compile failed: $(head -2 "$log" | tr '\n' ' ' | cut -c1-90)"
      continue
    fi

    args=""; [[ -f "$base.args" ]] && args="$(head -1 "$base.args")"
    if (( is_local )); then
      # Run from the listing's own directory, so a program can open a data file that sits
      # beside it -- which is where a reader would keep it, and how they would run it.
      # One quoted eval: the .args line is parsed once, as a shell would, so a '*' inside
      # quotes reaches the program instead of being expanded against the directory.
      if [[ -f "$base.stdin" ]]; then
        got="$(cd "$dir" && eval "$runenv \"\$root/\$exe\" $args" < "$root/$base.stdin" 2>&1)"
      else
        got="$(cd "$dir" && eval "$runenv \"\$root/\$exe\" $args" 2>&1)"
      fi
    else
      if [[ -f "$base.stdin" ]]; then
        got="$(wsl -d "$WSL_DISTRO" -- bash -c "cd '$book_wsl/$dir' && $runenv '$book_wsl/$exe' $args" < "$base.stdin" 2>&1)"
      else
        got="$(wsl -d "$WSL_DISTRO" -- bash -c "cd '$book_wsl/$dir' && $runenv '$book_wsl/$exe' $args" 2>&1)"
      fi
    fi
    rc=$?
    got="$(printf '%s' "$got" | tr -d '\r')"

    # A program's own output can name its source file -- a runtime error does. The path
    # it prints is whatever was passed to the compiler, which differs between a native
    # build and a WSL one, so reduce every form of it to the bare file name. That is also
    # what a reader compiling in the listing's own directory sees.
    for s in "${srcs[@]}"; do
      b="$(basename "$s")"
      got="${got//$book_wsl\/$s/$b}"
      got="${got//$s/$b}"
      # Hoisted: bash 3.2 (macOS) refuses a substitution nested in another.
      sw="${s//\//\\}"
      got="${got//$sw/$b}"
    done

    want_rc=0; [[ -f "$base.exit" ]] && want_rc="$(head -1 "$base.exit")"
    # A program whose output depends on the platform carries one file per target.
    outf="$base.out"; [[ -f "$base.$t.out" ]] && outf="$base.$t.out"
    if [[ ! -f "$outf" ]]; then
      results+=("FAIL"); note="no expected output file ($name.out)"; continue
    fi
    want="$(tr -d '\r' < "$outf")"; want="${want%$'\n'}"

    if [[ "$got" == "$want" && "$rc" == "$want_rc" ]]; then
      results+=("PASS")
    else
      results+=("FAIL")
      if [[ "$rc" != "$want_rc" ]]; then note="exit $rc, expected $want_rc"
      else note="output differs"; printf '%s\n' "--- expected"  "$want" "--- got" "$got" >> "$log"; fi
    fi
  done

  # A failure on a target a work item is known to break is BLOCKED, not FAIL: it counts
  # against the compiler, not the book, and the chapter cannot go final either way.
  if [[ -n "$blocked_item" ]]; then
    for i in "${!results[@]}"; do
      if [[ "${results[$i]}" == FAIL ]] &&
         { [[ "$blocked" == "$blocked_item" ]] || [[ "$blocked_where" == *"${targets[$i]}"* ]]; }; then
        results[$i]="BLOCKED($blocked_item)"
        note="${note:+$note; }known: $blocked_item"
      fi
    done
  fi

  row_fail=0; row_blocked=0
  for r in "${results[@]}"; do
    [[ "$r" == FAIL ]] && row_fail=1
    [[ "$r" == BLOCKED* ]] && row_blocked=1
  done
  if (( row_fail )); then fail=$((fail+1))
  elif (( row_blocked )); then blockedn=$((blockedn+1))
  else pass=$((pass+1)); fi
  (( long )) && note="${note:+$note; }$long line(s) over 72 columns"
  row="| \`$f\` |"; for r in "${results[@]}"; do row+=" $r |"; done
  echo "$row $note |" >> "$report"
done

{ echo; echo "**$pass passed, $fail failed, $blockedn blocked**, ${#listings[@]} listings, targets: ${targets[*]}.";
  (( wide )) && echo; (( wide )) && echo "$wide listing(s) exceed 72 columns."; } >> "$report"

echo "check-listings: $pass passed, $fail failed, $blockedn blocked (${#listings[@]} listings) -- $report"
# EVERY LISTING COUNTED, or the run says so: on the Mac a shell error once ended the loop and
# the run reported 0 passed, 0 failed -- and exit 0.
if (( pass + fail + blockedn != ${#listings[@]} )); then
  echo "check-listings: only $(( pass + fail + blockedn )) of ${#listings[@]} were checked" >&2; exit 2
fi
(( fail == 0 )) || exit 1
exit 0
