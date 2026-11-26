#!/usr/bin/env python3
"""Write a release version into every place in tiko-lang that carries it.

    python build/bump-version.py X.Y.Z            rewrite every site to X.Y.Z
    python build/bump-version.py X.Y.Z --dry-run  say what would change, write nothing
    python build/bump-version.py --check         every site agrees? print the version (exit 0) or
                                                 the sites that disagree (exit 1)

Each SITE is a file and a pattern that must match EXACTLY ONCE. A site that matches zero or two
times stops the bump before anything is written: a version that reaches only some of its places
is a release that lies about itself. Line endings are kept as they are (newline='').

The compiler (tiko --version, __TIKO_VERSION__) and tkEdit share one version. tkEdit's macOS
Info.plist is not a site: build/package.sh reads it from tkedit/src/app/tiko.toml. The book and
by-example pins are sites because tools/check-listings.sh refuses a toolchain whose
`tiko --version` differs from the pin, and the bumped toolchain will report the new version.

tiko-lsp has its own version and its own release/bump.py; this script does not touch it.
A new place that carries the version adds one line to SITES and changes nothing else.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
N = r"([0-9]+)"
V = r"([0-9]+\.[0-9]+\.[0-9]+)"

# (file relative to the repo root, regex with ONE group, what the group becomes given (major,
# minor, patch)). Patterns are MULTILINE.
DOTTED = lambda v: "%d.%d.%d" % v
SITES = [
    # the compiler
    ("src/tko.ti", r"^    const TKO_VERSION_MAJOR  as int32 = " + N + r"$", lambda v: str(v[0])),
    ("src/tko.ti", r"^    const TKO_VERSION_MINOR  as int32 = " + N + r"$", lambda v: str(v[1])),
    ("src/tko.ti", r"^    const TKO_VERSION_PATCH  as int32 = " + N + r"$", lambda v: str(v[2])),
    ("tests/driver/version.test", r"^'' EXPECT-OUT: tiko " + V + r"$", DOTTED),
    # tkEdit
    ("tkedit/src/core/appinfo/appinfo.tiko", r"^public const VERSION_MAJOR = " + N + r"$", lambda v: str(v[0])),
    ("tkedit/src/core/appinfo/appinfo.tiko", r"^public const VERSION_MINOR = " + N + r"$", lambda v: str(v[1])),
    ("tkedit/src/core/appinfo/appinfo.tiko", r"^public const VERSION_PATCH = " + N + r"$", lambda v: str(v[2])),
    ("tkedit/src/core/appinfo/appinfo.tiko", r'^\' "tkEdit ' + V + r'", or', DOTTED),
    ("tkedit/src/core/tests/coreall.tiko", r'appinfo\.VersionText\( \) = "' + V + r'"', DOTTED),
    ("tkedit/src/core/tests/coreall.tiko", r'appinfo\.WindowTitle\( \) = "tkEdit ' + V + r'"', DOTTED),
    ("tkedit/src/app/res/tkEdit.rc", r"^FILEVERSION     ([0-9]+,[0-9]+,[0-9]+),0$", lambda v: "%d,%d,%d" % v),
    ("tkedit/src/app/res/tkEdit.rc", r"^PRODUCTVERSION  ([0-9]+,[0-9]+,[0-9]+),0$", lambda v: "%d,%d,%d" % v),
    ("tkedit/src/app/res/tkEdit.rc", r'^            VALUE "FileVersion",      "' + V + r'"$', DOTTED),
    ("tkedit/src/app/res/tkEdit.rc", r'^            VALUE "ProductVersion",   "' + V + r'"$', DOTTED),
    ("tkedit/src/app/tiko.toml", r'^version = "' + V + r'"$', DOTTED),
    ("tkedit/src/core/tiko.toml", r'^version = "' + V + r'"$', DOTTED),
    ("tkedit/src/platform/tiko.toml", r'^version = "' + V + r'"$', DOTTED),
    ("tkedit/src/svc/tiko.toml", r'^version = "' + V + r'"$', DOTTED),
    # the book and tiko by Example: the pin, and the listing that prints the compiler's version
    ("book/book.yaml", r'^  version: "' + V + r'"$', DOTTED),
    ("by-example/book.yaml", r'^  version: "' + V + r'"$', DOTTED),
    ("book/examples/ch01/solutions/ex01-01.out", r"^compiler: tiko " + V + r"$", DOTTED),
    ("book/src/appendix-D-from-freebasic.md", r'^\| `__TIKO_VERSION__` \| not defined \| `"' + V + r'"` \|$', DOTTED),
    # the README's release badge (release tags are toolchain-<hash>, so a shields.io release
    # badge would show the hash, not the version)
    ("README.md", r"img\.shields\.io/badge/release-v" + V + r"-orange", DOTTED),
]


def scan():
    """Apply every pattern in memory. Returns (texts, hits) or exits on a bad site."""
    texts, hits = {}, []
    for rel, pattern, fmt in SITES:
        if rel not in texts:
            with open(ROOT / rel, encoding="utf-8", newline="") as f:
                texts[rel] = f.read()
        found = list(re.finditer(pattern, texts[rel], re.MULTILINE))
        if len(found) != 1:
            print(f"bump-version: {rel}: /{pattern}/ matched {len(found)} times, expected 1",
                  file=sys.stderr)
            sys.exit(1)
        hits.append((rel, pattern, fmt, found[0].group(1)))
    return texts, hits


def current_version(hits):
    """The version each site states, as (major, minor, patch) -- None where sites disagree."""
    parts = {}
    for rel, pattern, fmt, old in hits:
        if fmt is DOTTED:
            parts.setdefault("all", set()).add(old)
        elif "," in old:
            parts.setdefault("all", set()).add(old.replace(",", "."))
        else:
            key = "major" if "MAJOR" in pattern else "minor" if "MINOR" in pattern else "patch"
            parts.setdefault(key, set()).add(old)
    for key in ("major", "minor", "patch"):
        if len(parts.get(key, ())) != 1:
            return None
    split = "%s.%s.%s" % (parts["major"].pop(), parts["minor"].pop(), parts["patch"].pop())
    dotted = parts.get("all", set()) | {split}
    return dotted.pop() if len(dotted) == 1 else None


def main(argv):
    args = argv[1:]
    dry = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]

    if args == ["--check"]:
        texts, hits = scan()
        v = current_version(hits)
        if v is None:
            for rel, pattern, fmt, old in hits:
                print(f"  {rel}: {old}", file=sys.stderr)
            print("bump-version: the sites disagree", file=sys.stderr)
            return 1
        print(v)
        return 0

    if len(args) != 1 or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", args[0]):
        print(__doc__.split("\n\n")[1], file=sys.stderr)
        return 2
    new = tuple(int(x) for x in args[0].split("."))

    texts, hits = scan()
    # Rewrite each file's sites from the last match backwards, so earlier offsets stay valid.
    report = []
    for rel in texts:
        text = texts[rel]
        edits = []
        for site_rel, pattern, fmt, old in hits:
            if site_rel == rel:
                m = re.search(pattern, text, re.MULTILINE)
                edits.append((m.start(1), m.end(1), fmt(new), old))
        for start, end, value, old in sorted(edits, reverse=True):
            text = text[:start] + value + text[end:]
        for start, end, value, old in sorted(edits):
            report.append(f"{rel}: {old} -> {value}")
        texts[rel] = text

    if not dry:
        for rel, text in texts.items():
            with open(ROOT / rel, "w", encoding="utf-8", newline="") as f:
                f.write(text)
    print("\n".join(report))
    print(f"bump-version: {len(hits)} sites in {len(texts)} files"
          + (" (dry run, nothing written)" if dry else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
