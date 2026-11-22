#!/usr/bin/env python3
"""flatten.py -- PCRE2's pcre2.h, flattened to the 8-bit API, for 'tiko c2t'.

    python3 flatten.py <pcre2.h.generic> <pcre2_8.h>

pcre2.h declares its whole API -- types, records and every function -- inside list macros
(PCRE2_TYPES_LIST, PCRE2_STRUCTURE_LIST, PCRE2_*_FUNCTIONS), invoked three times with
PCRE2_LOCAL_WIDTH 8, 16 and 32, the names pasted with ## (pcre2_compile -> pcre2_compile_8).
c2t translates a declaration a macro invocation makes as a TODO, so translated as it is the
header would have constants and no API. This writes the same header with that one expansion
done by hand, for width 8 only:

  - every list macro's body is written in place as plain C, its line continuations removed,
    each width-specific name spelled as the 8-bit one (pcre2_code -> pcre2_code_8,
    PCRE2_SPTR -> PCRE2_SPTR8): the names the library exports;
  - the ## machinery, the three invocations, the #undefs and the PCRE2_CODE_UNIT_WIDTH tail
    are dropped;
  - the generic names follow the declarations as plain object-like macros
    (#define pcre2_compile pcre2_compile_8), so a program writes pcre2_compile as C does.

Everything else -- the option bits, error codes, comments, includes -- is the header's own,
line for line. The output is deterministic: the same input gives the same bytes.
"""
import re
import sys

LIST_HEAD = re.compile(r"^#define (PCRE2_[A-Z0-9_]+)[ \t]*\\[ \t]*$")
ALIAS = re.compile(r"^#define[ \t]+(\w+)([ \t]+)PCRE2_SUFFIX\((\w+)\)[ \t]*$")


def die(msg):
    sys.exit("flatten.py: " + msg)


def main(src, dst):
    lines = open(src, encoding="utf-8").read().split("\n")
    if lines and lines[-1] == "":
        lines.pop()

    def find(pred, start=0, what=""):
        for i in range(start, len(lines)):
            if pred(lines[i]):
                return i
        die("not found: " + what)

    # The regions: [first list macro, PCRE2_JOIN) holds the lists; [PCRE2_JOIN, the
    # TYPES_STRUCTURES_AND_FUNCTIONS definition) the aliases; the rest up to the C++ close is
    # dropped.
    lists_at = find(lambda s: LIST_HEAD.match(s), 0, "the first list macro")
    join_at = find(lambda s: s.startswith("#define PCRE2_JOIN("), lists_at, "PCRE2_JOIN")
    tsaf_at = find(lambda s: s.startswith("#define PCRE2_TYPES_STRUCTURES_AND_FUNCTIONS"),
                   join_at, "PCRE2_TYPES_STRUCTURES_AND_FUNCTIONS")
    cpp_close = find(lambda s: s.startswith("#ifdef __cplusplus"), tsaf_at, "the closing __cplusplus")

    # The aliases: generic name -> 8-bit name, and their lines in order with their comments.
    names = {}
    alias_lines = []
    for s in lines[join_at:tsaf_at]:
        m = ALIAS.match(s)
        if m:
            generic, gap, stem = m.groups()
            if generic == "PCRE2_SUFFIX":
                continue
            names[generic] = stem + "8"
            # pcre2_real_* are the C tags of the opaque records; tiko has no tags, and
            # nothing declares the 8-bit ones to alias, so only the typedef names are given.
            if not generic.startswith("pcre2_real_"):
                alias_lines.append("#define " + generic + gap + stem + "8")
        elif s.startswith("#define PCRE2_JOIN") or s.startswith("#define PCRE2_GLUE") \
                or s.startswith("#define PCRE2_SUFFIX"):
            continue
        else:
            alias_lines.append(s)
    if "pcre2_compile" not in names or "PCRE2_SPTR" not in names:
        die("no PCRE2_SUFFIX aliases found -- has pcre2.h changed shape?")
    # The comment introducing the invocations ("Now generate all three sets ...") is about
    # what is dropped: drop it, and the blank lines around the aliases.
    while alias_lines and alias_lines[0].strip() == "":
        alias_lines.pop(0)
    while alias_lines and alias_lines[-1].strip() == "":
        alias_lines.pop()
    if alias_lines and alias_lines[-1].rstrip().endswith("*/"):
        while alias_lines and not alias_lines[-1].lstrip().startswith("/*"):
            alias_lines.pop()
        alias_lines.pop()

    rename = re.compile(r"\b(" + "|".join(sorted(map(re.escape, names), key=len, reverse=True)) + r")\b")

    # The lists, expanded in place.
    out_lists = []
    seen = []
    i = lists_at
    # Drop the trailing comment that introduces the ## machinery (the block just above
    # PCRE2_JOIN): find it as the last comment before join_at.
    machinery_comment = join_at
    j = join_at - 1
    while j > lists_at and lines[j].strip() == "":
        j -= 1
    if lines[j].rstrip().endswith("*/"):
        while j > lists_at and not lines[j].lstrip().startswith("/*"):
            j -= 1
        machinery_comment = j
    while i < machinery_comment:
        s = lines[i]
        m = LIST_HEAD.match(s)
        if not m:
            out_lists.append(s)
            i += 1
            continue
        seen.append(m.group(1))
        i += 1
        while True:
            if i >= len(lines):
                die("unterminated list macro " + m.group(1))
            body = lines[i]
            cont = body.rstrip().endswith("\\")
            if cont:
                body = body.rstrip()[:-1].rstrip()
            out_lists.append(rename.sub(lambda k: names[k.group(1)], body))
            i += 1
            if not cont:
                break
    # THE ORDER IS THE DEFINITIONS', not the invocation's: they differ only among the
    # function lists, which depend on nothing but the types and records, defined first.
    invoked = []
    for s in lines[tsaf_at + 1:]:
        name = s.strip().rstrip("\\").strip()
        if not name:
            break
        invoked.append(name)
    if sorted(seen) != sorted(invoked) or seen[:2] != invoked[:2] \
            or seen[:2] != ["PCRE2_TYPES_LIST", "PCRE2_STRUCTURE_LIST"]:
        die("the list macros defined (" + " ".join(seen) + ") are not the ones "
            "PCRE2_TYPES_STRUCTURES_AND_FUNCTIONS invokes (" + " ".join(invoked) + "), "
            "or the types and records do not come first")

    head = lines[:lists_at]
    # THE INCLUDES: pcre2.h takes size_t, SIZE_MAX and the fixed-width integers from
    # <limits.h>, <stdlib.h> and <inttypes.h>, and nothing else of theirs. <stddef.h> and
    # <stdint.h> give exactly those and are the compiler's own, so every c2t pass parses the
    # header with no C library at all -- the Windows pass on a Mac included -- as sqlite3's and
    # cJSON's do; and the translation brings no crt/ header into a program.
    want = ["#include <limits.h>", "#include <stdlib.h>", "#include <inttypes.h>"]
    at = [k for k in range(len(head) - 2) if head[k:k + 3] == want]
    if len(at) != 1:
        die("pcre2.h's includes are not " + ", ".join(want) + " -- has it changed?")
    head[at[0]:at[0] + 3] = [
        "/* flatten.py: <stddef.h> and <stdint.h> for pcre2.h's <limits.h>, <stdlib.h> and",
        "<inttypes.h> -- size_t, SIZE_MAX and the fixed-width integers are all it uses. */",
        "",
        "#include <stddef.h>",
        "#include <stdint.h>",
    ]
    # PCRE2_SIZE IS A TYPEDEF HERE, not pcre2.h's '#define PCRE2_SIZE size_t' -- the same to C.
    # c2t spells size_t itself where a declaration uses it, but a macro's value is text, and
    # tiko declares no size_t without crt/stddef.bi: as a macro, every PCRE2_SIZE a program
    # wrote would be an undeclared type. As a typedef it is a tiko type, and the prototypes
    # read PCRE2_SIZE as PCRE2's documentation does.
    sz = [k for k, s in enumerate(head) if re.match(r"^#define PCRE2_SIZE[ \t]+size_t[ \t]*$", s)]
    if len(sz) != 1:
        die("no '#define PCRE2_SIZE size_t' -- has pcre2.h changed?")
    head[sz[0]] = "typedef size_t PCRE2_SIZE;  /* flatten.py: pcre2.h's #define, as a typedef */"
    # The guard's #define is followed by the width this header is.
    g = find(lambda s: s.startswith("#define PCRE2_H_IDEMPOTENT_GUARD"), 0, "the include guard")
    head = head[:g + 1] + [
        "",
        "/* pcre2_8.h -- written by flatten.py from pcre2.h: the 8-bit API only, its list",
        "macros expanded in place and its ## names spelled out. Not PCRE2's own file. */",
        "",
        "#define PCRE2_CODE_UNIT_WIDTH 8",
    ] + head[g + 1:]

    tail = [
        "",
        "/* The generic names, as pcre2.h gives them with PCRE2_CODE_UNIT_WIDTH 8. */",
        "",
    ] + alias_lines
    while tail and tail[-1].strip() == "":
        tail.pop()

    out = head + out_lists
    while out and out[-1].strip() == "":
        out.pop()
    out += tail + [""] + lines[cpp_close:]
    open(dst, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        die("usage: flatten.py <pcre2.h.generic> <pcre2_8.h>")
    main(sys.argv[1], sys.argv[2])
