#!/usr/bin/env python3
"""Generate the Appendix A page: reserved words, predeclared names and operator precedence.

Three tables come from the compiler at the pinned commit, so the page cannot drift from it:

- the reserved words, from src/lexer/keywords.ti (the lexer's own table);
- the runtime procedure names a declaration may not reuse, from src/symbols/resolvertl.tiko;
- the precedence levels, from src/parser/prectable.ti, the only place the compiler states them.

The rest -- which names are contextual, where a keyword may name a field -- is MEASURED, not
read: every keyword and runtime name was compiled as a variable, a procedure, a field, a local
and a namespace member, with tiko and with fbc-modern 1.20, and the two agree (2026-10-04). The
statements below say so where they make a claim.

    python tools/gen_keywords.py [--tiko-src C:/dev/tiko-lang]
"""
from __future__ import annotations

import argparse
import datetime
import pathlib
import re
import sys

import pin as pinlib

KW_RE = re.compile(r'KW\(\s*KW_\w+,\s*"([A-Z0-9_$]+)",\s*KWCLASS_(\w+)\s*\)')
PREC_RE = re.compile(r"^\s*(PREC_\w+)\s*=\s*(\d+)", re.M)
BINOP_RE = re.compile(r"BINOP\(\s*(\w+),\s*(PREC_\w+)\s*\)")

TOKEN_TEXT = {
    "TK_EQ": "=", "TK_NE": "<>", "TK_LT": "<", "TK_LE": "<=", "TK_GT": ">", "TK_GE": ">=",
    "TK_AMP": "&", "TK_PLUS": "+", "TK_MINUS": "-", "TK_BACKSLASH": "\\", "TK_STAR": "*",
    "TK_SLASH": "/", "TK_CARET": "^",
}

# The words FBC-Modern added without reserving them. Each was compiled as a variable, a
# procedure, a field, a local and a namespace member, and every one of those compiles.
CONTEXTUAL = [
    ("channel", "`select channel` (Chapter 23)"),
    ("defer", "`defer` statement, when a name, a keyword other than `as`, or the end of the statement follows (Chapter 6)"),
    ("each", "`for each` (Chapter 20)"),
    ("from", "`case receive v from ch` in `select channel`"),
    ("in", "`for each x in …`"),
    ("of", "type arguments: `Array( of int32 )` (Chapter 17)"),
    ("override", "after a method's declaration: `declare sub M( ) override` (Chapter 14)"),
    ("partial", "`partial type` and `partial class`, one type in several blocks (Chapter 15)"),
    ("receive", "`case receive` in `select channel`"),
    ("send", "`case send v to ch` in `select channel`"),
    ("spawn", "`spawn Proc( args )` (Chapter 23)"),
    ("timeout", "`case timeout ms` in `select channel`"),
]

FIXED_WIDTH = [
    ("int8", "byte"), ("uint8", "ubyte"), ("int16", "short"), ("uint16", "ushort"),
    ("int32", "long"), ("uint32", "ulong"), ("int64", "longint"), ("uint64", "ulongint"),
    ("float32", "single"), ("float64", "double"),
]


def columns(words: list[str], ncol: int) -> list[str]:
    """Words down the columns, so the list reads alphabetically top to bottom."""
    rows = (len(words) + ncol - 1) // ncol
    out = ["| " + " | ".join([" "] * ncol) + " |", "|" + "---|" * ncol]
    for r in range(rows):
        cells = []
        for c in range(ncol):
            i = c * rows + r
            cells.append(f"`{words[i]}`" if i < len(words) else "")
        out.append("| " + " | ".join(cells) + " |")
    return out


def rtl_names(src: str) -> tuple[list[str], list[str]]:
    """The two groups of RtlProcName_: those that also take a new overload, and the rest."""
    body = src.split("private function RtlProcName_", 1)[1].split("end function", 1)[0]
    cases = body.split("case _")[1:]
    groups = [sorted(set(re.findall(r'"([a-z0-9_]+)"', c.split("return")[0]))) for c in cases]
    if len(groups) != 2 or not groups[0] or not groups[1]:
        sys.exit("gen_keywords: RtlProcName_ no longer has its two groups -- the table's shape changed")
    return groups[0], groups[1]


def precedence(src: str) -> list[tuple[int, list[str]]]:
    levels = {name: int(v) for name, v in PREC_RE.findall(src)}
    by_level: dict[int, list[str]] = {}
    for tok, prec in BINOP_RE.findall(src):
        text = TOKEN_TEXT.get(tok)
        if text is None:
            if not tok.startswith("KW_"):
                sys.exit(f"gen_keywords: no spelling for {tok} in prectable.bi")
            text = tok[3:].lower()
        by_level.setdefault(levels[prec], []).append(text)
    by_level.setdefault(levels["PREC_SIGN"], []).append("- (sign)")
    by_level.setdefault(levels["PREC_SIGN"], []).append("+ (sign)")
    by_level.setdefault(levels["PREC_NOT"], []).append("not")
    return sorted(by_level.items(), reverse=True)


def main() -> int:
    here = pathlib.Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser()
    pinlib.add_arguments(ap)
    ap.add_argument("--out", default=str(here / "src" / "appendix-A-keywords.md"))
    args = ap.parse_args()

    pin = pinlib.read_pin(args.tiko_src, args.rev, args.worktree)
    pinlib.announce(pin, "gen_keywords")
    kws = KW_RE.findall(pinlib.read_source(pin, "src/lexer/keywords.ti"))
    if len(kws) < 200:
        sys.exit(f"gen_keywords: only {len(kws)} keywords parsed at {pin.commit}")
    words = sorted(w.lower() for w, _ in kws)
    ovl, rtl = rtl_names(pinlib.read_source(pin, "src/symbols/resolvertl.tiko"))
    prec = precedence(pinlib.read_source(pin, "src/parser/prectable.ti"))

    L = [
        "# Appendix A: Keywords and Operator Precedence {#app-keywords}",
        "",
        "<!-- GENERATED by tools/gen_keywords.py. Do not edit. -->",
        "",
        "A name in tiko is one of five things, and they follow different rules. A **reserved "
        "word** is never a name. A **runtime name** may not be reused at module level. A "
        "**contextual word** is a keyword only where its statement expects it. A **fixed-width "
        "type name**, like the constant `nullptr`, is predeclared and may be replaced. "
        "Everything else is free. The rules "
        "below were measured by compiling each word in each position with tiko and with "
        "fbc-modern 1.20, and the two give the same answer for every word in every position.",
        "",
        f"## Reserved words ({len(words)}) {{#app-kw-reserved}}",
        "",
        "A reserved word cannot name a variable, a constant or a procedure, at module level, "
        "inside a procedure or inside a namespace. Case does not matter. The diagnostic is "
        "usually `TKO0600: '…' is already declared in this scope`, because the word is "
        "declared by the language itself; where the word starts a statement of its own, the "
        "parser reports that statement's error instead.",
        "",
    ]
    L += columns(words, 6)
    L += [
        "",
        "The list includes every **statement and function word** of the classic language — "
        "`print`, `open`, `len`, `read`, `name`, `width`, `lock` — and every built-in type "
        "name, `double` and `string` included. `function Double( )` is refused, and so is a "
        "variable called `read`.",
        "",
        "### Keywords as field names {#app-kw-fields}",
        "",
        "A **field** may be named by most reserved words, because a field's name is only ever "
        "read after `.` or `->`, or in its type's body. A type can have a field called "
        "`name`, `type`, `len` or `constructor`, and `t.name` reads it. The exceptions:",
        "",
        "- The operator words `and`, `andalso`, `eqv`, `imp`, `mod`, `not`, `or`, `orelse`, "
        "`shl`, `shr` and `xor`, and `delete` and `new`, are never field names.",
        "- In the type-first spelling, `as T name`, `const`, `ptr` and `pointer` are part of "
        "the type, not a name; `ptr as long` is a field.",
        "- In the name-first spelling, `name as T`, the declaration words `const`, `declare`, "
        "`dim`, `enum`, `redim`, `static`, `private`, `protected` and `public` start a "
        "declaration instead, and `type` and `union` cannot take array bounds "
        "(`type( 0 to 2 ) as long`).",
        "- In the type-first spelling, `alias` is not a name either. `alias as long` is fine.",
        "- `rem` starts a comment where a statement can end, so `rem as long` is a comment. "
        "`as long rem` declares a field named `rem`, and `t.rem` reads it.",
        "",
        f"## Runtime names ({len(ovl) + len(rtl)}) {{#app-kw-runtime}}",
        "",
        "These are the runtime library's procedures. They are not reserved words. The runtime "
        "declares them in the global namespace, so a declaration of the same name at module "
        "level collides with it: `TKO0813: '…' is already declared by the runtime library`. "
        "That covers a variable, a constant, a procedure, a `for` counter, a local inside a "
        "module-level procedure, and a parameter of a procedure's definition. The same name is "
        "fine inside a namespace or a method, as a field, a member procedure or an enum member, "
        "and as a parameter of a prototype.",
        "",
    ]
    L += columns(rtl, 6)
    L += [
        "",
        "These also take a **new overload**: `sub Hex( )` compiles beside the runtime's `hex`, "
        "but `dim as long hex` does not.",
        "",
    ]
    L += columns(ovl, 6)
    L += [
        "",
        "`#define` is the exception: tiko accepts `#define run 5`, where fbc refuses it as a "
        "duplicated definition (Appendix D).",
        "",
        "## Contextual words {#app-kw-contextual}",
        "",
        "FBC-Modern's extensions added these words without reserving them, so existing code "
        "that uses them as names keeps compiling. Each one is a keyword only in the position "
        "shown, and an ordinary name everywhere else: each one compiles as a variable, a "
        "procedure, a field, a local and a namespace member.",
        "",
        "| Word | A keyword in |",
        "|---|---|",
    ]
    for w, where in CONTEXTUAL:
        L.append(f"| `{w}` | {where} |")
    L += [
        "",
        "## Fixed-width type names {#app-kw-fixed}",
        "",
        "tiko predeclares ten type names that fbc does not have. They are typedefs, not "
        "reserved words (Chapter 4): a program's own declaration of one of them replaces "
        "tiko's without a diagnostic, so code that already declares `INT32` — as "
        "`win/basetsd.bi` does — compiles unchanged.",
        "",
        "| Name | Same type as | Name | Same type as |",
        "|---|---|---|---|",
    ]
    for i in range(0, len(FIXED_WIDTH), 2):
        a, b = FIXED_WIDTH[i], FIXED_WIDTH[i + 1]
        L.append(f"| `{a[0]}` | `{a[1]}` | `{b[0]}` | `{b[1]}` |")
    L += [
        "",
        "## The predeclared constant {#app-kw-nullptr}",
        "",
        "tiko predeclares one constant that fbc does not have, `const nullptr as any ptr = 0`: "
        "the null pointer, as a pointer (Chapter 11). It is replaced on the same terms as the "
        "type names above, so a program's own `nullptr` — fbc's own test suite has a field by "
        "that name — compiles unchanged.",
        "",
        "## Operator precedence {#app-precedence}",
        "",
        "Tightest first. Operators on one row bind equally, and **every binary operator is "
        "left-associative**, `^` included. The member operators `.` and `->`, calls `( )` "
        "and indexing `[ ]` bind tighter than everything here.",
        "",
        "| Level | Operators |",
        "|---:|---|",
    ]
    for n, (_, ops) in enumerate(prec, 1):
        cells = []
        for o in ops:
            sym, _, note = o.partition(" (")
            cells.append(f"`{sym}`" + (f" ({note}" if note else ""))
        L.append(f"| {n} | " + " ".join(cells) + " |")
    L += [
        "",
        "The table is FreeBASIC's, measured operator pair by operator pair against fbc, and "
        "several rows differ from C and from intuition (Chapter 5). Each line below prints the "
        "same with tiko and with fbc-modern:",
        "",
        "```text",
        "2 ^ 3 ^ 2            64     ^ is left-associative: (2 ^ 3) ^ 2",
        "-2 ^ 2               -4     ^ binds tighter than the sign",
        "1 shl 2 + 1           5     shl binds tighter than +, unlike C's <<",
        "8 \\ 4 * 2             1     * binds tighter than \\: 8 \\ (4 * 2)",
        "2 * 3 mod 4           2     mod is looser than * and \\",
        "12 or 10 xor 6        8     or binds tighter than xor",
        "1 or 2 and 0          1     and binds tighter than or",
        "0 andalso 1 orelse 1 -1     andalso and orelse share one level",
        "not 1 = 0            -1     not is looser than the comparisons: not (1 = 0)",
        "not 0 and 3           3     ...and tighter than and: (not 0) and 3",
        "```",
        "",
        "`&` binds looser than `+` and `-`, so `\"a\" & 1 + 2` means `\"a\" & (1 + 2)`, and "
        "both compilers print `a3`.",
        "",
        f"<!-- {len(words)} reserved words, {len(ovl) + len(rtl)} runtime names, generated "
        f"{datetime.date.today().isoformat()} from src/lexer/keywords.ti, "
        f"src/symbols/resolvertl.tiko and src/parser/prectable.ti at {pin.commit} -->",
        "",
    ]
    out = pathlib.Path(args.out)
    out.write_text("\n".join(L), encoding="utf-8", newline="\n")
    print(f"gen_keywords: wrote {out} ({len(words)} words, {len(ovl) + len(rtl)} runtime names, {len(prec)} levels)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
