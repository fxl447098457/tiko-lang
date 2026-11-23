#!/usr/bin/env python3
"""Compare tiko-lang's DECLARE/definition calling-convention rule with fbc's, and with its own.

    python tools/gen/check-callconv.py

Two expectations, and both are checked:

  tests/types/expected/fbc-callconv.txt   what fbc does -- produced by callconv-truth.py
                                          from fbc itself, and never edited by hand
  tests/types/expected/tiko-callconv.txt   what tiko does, and why it differs where it does

A refusal is TKO0603. tiko must match its own file; the fbc file is compared too, and
the pairings where the two differ are printed, because a divergence nobody reads is a
divergence nobody notices. Two differ on Windows x86-64 (the default is cdecl in tiko
and stdcall in fbc there); the count is printed, not failed on.
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
import tkotargets

TRUTH = ROOT / "tests/types/expected/fbc-callconv.txt"
OURS = ROOT / "tests/types/expected/tiko-callconv.txt"
TGT = []
LABEL = "win64"
WORK = ROOT / "build/.cc"
TKO = ROOT / "bin/tiko.exe"


def spell(c):
    return "" if c == "none" else c + " "


def read_rows(path):
    return [l.split("\t") for l in path.read_text(encoding="utf-8").splitlines()
            if l.strip() and not l.startswith("#")]


def one_target() -> int:
    if not TRUTH.exists():
        print(f"check-callconv: {LABEL} no truth file; run tools/gen/callconv-truth.py",
              file=sys.stderr)
        return 3
    if not OURS.exists():
        print(f"check-callconv: {LABEL} no tiko-callconv.txt", file=sys.stderr)
        return 3
    tiko = TKO if TKO.exists() else ROOT / "bin/tiko"
    if not tiko.exists():
        print(f"check-callconv: {LABEL} tiko not built", file=sys.stderr)
        return 3

    rows = read_rows(TRUTH)
    want = {(d, f): v for d, f, v in rows}
    mine = {(d, f): v for d, f, v in read_rows(OURS)}
    WORK.mkdir(parents=True, exist_ok=True)

    ok, bad, differ = 0, [], []
    for d, f, fbc_want in rows:
        src = (f"declare sub B {spell(d)}( byval x as long )\n"
               f"sub B {spell(f)}( byval x as long ) : end sub\n")
        p = WORK / "chk.bas"
        p.write_text(src, encoding="utf-8", newline="\n")
        proc = subprocess.run([str(tiko), "--check"] + TGT + [str(p)],
                              capture_output=True, text=True)
        out = (proc.stdout or "") + (proc.stderr or "")
        got = "reject" if "TKO0603" in out else "accept"
        if got == mine.get((d, f), ""):
            ok += 1
        else:
            bad.append(f"declare {d} / definition {f}: tiko={got} "
                       f"tiko-callconv.txt says {mine.get((d, f), '?')}")
        if got != fbc_want:
            differ.append(f"declare {d} / definition {f}: fbc={fbc_want} tiko={got}")

    print(f"check-callconv: {LABEL} {ok}/{len(rows)} match tiko-callconv.txt")
    if bad:
        print(f"check-callconv: {LABEL} {len(bad)} disagreements:")
        for b in bad:
            print("   ", b)
    if differ:
        print(f"check-callconv: {LABEL} {len(differ)} deliberate differences from fbc:")
        for d in differ:
            print("   ", d)
    return 0 if not bad else 1


def main() -> int:
    """Every target, against its own expectations file."""
    global TRUTH, OURS, TGT, LABEL
    rc = 0
    for LABEL, TRUTH, TGT in tkotargets.check_targets(TRUTH):
        if one_target() != 0:
            rc = 1
    return rc


if __name__ == "__main__":
    sys.exit(main())
