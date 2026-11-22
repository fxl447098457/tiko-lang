#!/usr/bin/env python3
"""stdtests.py -- port fbc's tests of the standard library from the headers to the modules.

108 files of tests/vendor/fbc-tests test what pkg/std is made of, through the headers:

    #include once "fb/string.bi"
    using FB
    ... FB.Split( s ) ...

tests/vendor is fbc's own suite and is never edited, so each file is COPIED to tests/std
and rewritten there, for every module that is already real:

    #import "std/strings"
    using strings
    ... strings.Split( s ) ...

A header of a module that is still a facade stays included, with 'using FB'. The copies
are GENERATED -- re-run this whenever a module converts, and never edit one by hand; a
port that needs more than this rewrite gets an entry in PATCHES.

Beside each copy it writes a .test that builds and runs it the way build/stdsuite.sh does,
expecting what tests/std/baseline/ recorded for the original: the same exit codes, the
same fbcunit summary line, the same diagnostic ids for a file that must not compile.

    python build/stdtests.py            write tests/std
    python build/stdtests.py --check    exit 1 if anything would change
"""
import argparse
import io
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "build"))
# The std modules and the inc/fb headers each was made from (build/stdport.py's table,
# 2026-10-10; the script went with inc/fb).
MODULES = {
    "strings": ["string.bi"],
    "tui": ["tuiwidthtab.bi", "tuiwidth.bi", "tuicore.bi", "tuiterm.bi", "tuibuffer.bi",
            "tuiinput.bi", "tuilayout.bi", "tuiwidget.bi", "tuiwidgets.bi", "tuidraw.bi",
            "tuiform.bi", "tuichrome.bi", "tuiapp.bi", "tui.bi"],
    "money": ["currency.bi", "decimal.bi", "moneyformat.bi", "finerror.bi", "fincore.bi",
              "finsolve.bi", "fintvm.bi", "fincash.bi", "findeprec.bi", "finloan.bi",
              "finport.bi", "finance.bi"],
    "logs": ["logrecord.bi", "logrender.bi", "logerror.bi", "logsink.bi", "logger.bi",
             "logdefault.bi", "logfile.bi", "logasync.bi", "logging.bi", "logmacros.bi"],
    "fs": ["fserror.bi", "fspath.bi", "fsinfo.bi", "fsdir.bi", "fsops.bi", "fsglob.bi",
           "fslink.bi", "fsvolume.bi", "fsadvanced.bi", "filesystem.bi"],
    "numeric": ["math.bi", "mathint.bi", "mathtext.bi", "complex.bi", "random.bi",
                "stats.bi", "fenv.bi", "vector.bi"],
    "tasks": ["scheduler.bi", "channel.bi", "sync.bi", "select.bi"],
    "memory": ["sharedptr.bi"],
    "chrono": ["chrono.bi"],
    "outcome": ["optional.bi", "result.bi"],
    "containers": ["hash.bi", "array.bi", "linkedlist.bi", "map.bi", "set.bi",
                   "orderedmap.bi", "orderedset.bi", "sort.bi", "../containers.bi"],
}
UMBRELLAS = {"tui.bi", "finance.bi", "logging.bi", "filesystem.bi", "../containers.bi"}
# The names a module exports beyond its facade's list.
EXTRA_PUBLIC = {
    # a new module: fb/sharedptr.bi was in no facade. SpCtl is the field type behind both.
    "memory": {"sharedptr", "weakptr", "makeshared", "makesharedfrom", "spcast", "spctl"},
    # the type behind the public alias Logger (TKO0868 otherwise)
    "logs": {"logger_"},
    # what a SELECT statement lowers to (src/parser/selchan.tiko): the parser writes these
    # names into the importer's own code, so they must be public, though no one writes them
    "tasks": {"selectcase", "selectctx", "selectaddrecv", "selectaddsend", "selectaddrecvdiscard",
              "selectrun", "selectcommitrecv", "selectcommitsend", "selectreleaserecv",
              "selectreleasesend",
              # ...and the channel types those and Channel's own members name
              "chanwaiter", "chancore", "chanwaitercore"},
}

HDR_MODULE = {}
for _m, _hs in MODULES.items():
    for _h in _hs:
        HDR_MODULE[os.path.basename(_h)] = _m

VENDOR = os.path.join(ROOT, "tests", "vendor", "fbc-tests")
OUT = os.path.join(ROOT, "tests", "std")
DRIVER = "tests/vendor/fbc-tests/fbcunit/tests/tests.bas"

# file (area/name.bas) -> [(old, new)], applied after the rewrite, each exactly once.
#
# STD/CHRONO'S C KERNEL IS THE RUNTIME'S, not chrono's API: under 'using FB' the header's
# global declarations of it were visible, and a module's are its own. A test that calls the
# kernel declares the functions it calls.
_DT_KERNEL = '''#include once "fbcunit.bi"
extern "C"
declare function fb_DtTicksFromCounts alias "fb_DtTicksFromCounts" ( byval counts as longint, byval freq as longint ) as longint
declare function fb_DtIsValidTicks alias "fb_DtIsValidTicks" ( byval ticks as longint ) as long
end extern'''
#
# THE HASH HOOK IS A MEMBER NOW. A user key type was made hashable by re-opening namespace FB
# and adding a HashOf overload; std/containers' namespace cannot be re-opened, so the type
# extends containers.Hashable and overrides its HashOf( ) (hash.tiko says why).
_MAP_KEY_OLD = """type PairKey
\tas long a, b
end type"""
_MAP_KEY_NEW = """type PairKey extends containers.Hashable
\tas long a, b
\tdeclare function HashOf( ) as ulongint override
end type"""
_MAP_HASH_OLD = """namespace FB
\tfunction HashOf overload ( byref k as PairKey ) as ulongint
\t\t'' equal keys must hash equal -- derived only from the compared fields
\t\treturn HashOf( k.a ) xor (HashOf( k.b ) shl 1)
\tend function
end namespace"""
_MAP_HASH_NEW = """function PairKey.HashOf( ) as ulongint
\t'' equal keys must hash equal -- derived only from the compared fields
\treturn containers.HashOf( a ) xor (containers.HashOf( b ) shl 1)
end function"""
_SET_KEY_OLD = """\tdeclare destructor( )
end type"""
_SET_KEY_NEW = """\tdeclare destructor( )
\tdeclare function HashOf( ) as ulongint override
end type"""
_SET_HASH_OLD = """namespace FB
\tfunction HashOf overload ( byref k as Counted ) as ulongint
\t\treturn HashOf( k.v )
\tend function
end namespace"""
_SET_HASH_NEW = """function Counted.HashOf( ) as ulongint
\treturn containers.HashOf( v )
end function"""
PATCHES = {
    "chrono/clocks.bas": [('#include once "fbcunit.bi"', _DT_KERNEL)],
    "generics/container-map.bas": [(_MAP_KEY_OLD, _MAP_KEY_NEW), (_MAP_HASH_OLD, _MAP_HASH_NEW)],
    "generics/container-set.bas": [("type Counted\n", "type Counted extends containers.Hashable\n"),
                                   (_SET_KEY_OLD, _SET_KEY_NEW), (_SET_HASH_OLD, _SET_HASH_NEW)],
    "chrono/zones.bas": [('#include once "fbcunit.bi"', _DT_KERNEL)],
}
# file -> [(regex, replacement)], applied after PATCHES; each must match at least once.
#
# CONTAINS IS TWO NAMES NOW. Under 'using FB' strings' Contains and containers' generic
# Contains( of T ) were one overload set in one namespace; as two modules, a bare call under
# both 'using's is TKO0919 (ambiguous), which is the module rule, so the port qualifies it.
#
# SUITES WHOSE ASSERT COUNT DESCRIBES THE MACHINE, not the code: their .test matches the
# summary from the suite name on (name + test count), and a failure still shows as fbcunit's
# exit 1. A recorded count passed on the author's box and failed on the UTC, two-drive CI runner.
HOST_DEPENDENT = {
    "chrono/zones.bas": "the assert count follows the machine's zone (no DST, e.g. a UTC CI runner, skips nine).",
    "filesystem/fsvolume.bas": "the assert count follows the machine's volumes (five per drive).",
}

# PORTED BUT NOT RUN: no .test is written for these. filesystem/fslink makes symbolic links,
# which Windows refuses to a process that is not elevated (and has no Developer Mode), so it
# failed on every ordinary run and said nothing about the code (the author's decision, 2026-11-21).
NOT_RUN = {
    "filesystem/fslink.bas": "creating a symbolic link needs elevation on Windows.",
}

# THE LOGEVENT FIELD METHODS ARE Add<kind> in std/logs -- AddText, AddInt, ... -- where
# fb/logging.bi spelled them Str, Int_, UInt, Dbl, Bool, Ptr_, Time, Span and Val. The
# old names collided with keywords and intrinsics; see pkg/std/logs/logger.tiko.
RPATCHES = {
    "string/fbstr_search.bas": [(r"(?<![.\w])Contains\(", "strings.Contains(")],
    "logging/logger_sinks.bas": [(r"\.Str\(", ".AddText("), (r"\.Int_\(", ".AddInt("),
                                 (r"\.UInt\(", ".AddUInt("), (r"\.Dbl\(", ".AddFloat("),
                                 (r"\.Bool\(", ".AddBool("), (r"\.Ptr_\(", ".AddPtr("),
                                 (r"\.Time\(", ".AddTime("), (r"\.Span\(", ".AddSpan("),
                                 (r"\.Val\(", ".AddValue(")],
    # NO U NAMES IN std/chrono: a producer that takes no text returns USTRING under its plain
    # name, so ToIsoUString, ToLocale*UString, MonthUName and WeekdayUName are those names.
    "chrono/utext.bas": [(r"\bToIsoUString\(", "ToIsoString("),
                         (r"\bToLocaleDateUString\(", "ToLocaleDateString("),
                         (r"\bToLocaleTimeUString\(", "ToLocaleTimeString("),
                         (r"\bToLocaleUString\(", "ToLocaleString("),
                         (r"\bMonthUName\(", "MonthName("),
                         (r"\bWeekdayUName\(", "WeekdayName(")],
}

RX_INC = re.compile(r'^\s*#include(?:\s+once)?\s+"(fb/[\w]+\.bi|containers\.bi)"[^\n]*\n?', re.I | re.M)


def converted():
    out = set()
    for m in MODULES:
        d = os.path.join(ROOT, "pkg", "std", m)
        if os.path.isdir(d) and not os.path.isfile(os.path.join(d, m + ".bas")) \
                and any(f.endswith(".tiko") for f in os.listdir(d)):
            out.add(m)
    return out


def public_names(mod):
    """A real module's public names, lower-cased -> spelling: from its INTERFACE, as the
    compiler writes it (--emit-tki), where a macro has been expanded -- numeric's vector
    types are pasted together by '##' and are nowhere whole in the source. The source
    is read instead when there is no compiler to ask."""
    names = {}
    exe = os.path.join(ROOT, "bin", "tiko.exe" if os.name == "nt" else "tiko")
    texts = []
    if os.path.isfile(exe):
        r = subprocess.run([exe, "-i", os.path.join(ROOT, "inc"), "--emit-tki", mod],
                           cwd=os.path.join(ROOT, "pkg", "std"), capture_output=True,
                           text=True, encoding="utf-8", errors="replace")
        if r.returncode == 0 and "tiko-interface" in r.stdout:
            texts = [r.stdout]
            for m in re.finditer(r"(?m)^#define __tko_mac_\w+?__(\w+) ", r.stdout):
                names.setdefault(m.group(1).lower(), m.group(1))
    if not texts:
        d = os.path.join(ROOT, "pkg", "std", mod)
        texts = [io.open(os.path.join(d, f), encoding="utf-8").read()
                 for f in sorted(os.listdir(d)) if f.endswith(".tiko")]
    for text in texts:
        inenum = False
        for ln in text.split("\n"):
            code = ln.split("''")[0]
            if inenum:
                if re.match(r"\s*end\s+enum\b", code, re.I):
                    inenum = False
                    continue
                for m in re.finditer(r"(?:^|[,:])\s*([A-Za-z_]\w*)", code):
                    names.setdefault(m.group(1).lower(), m.group(1))
                continue
            m = re.match(r"\s*public\s+(?:declare\s+)?(?:function|sub|type|union|enum|const)"
                         r"\s+(?:as\s+\w+\s+)?(\w+)", code, re.I)
            if m:
                names.setdefault(m.group(1).lower(), m.group(1))
                if re.match(r"\s*public\s+enum\b", code, re.I):
                    inenum = True
            m = re.match(r"\s*#export\s+(.*)", code)
            if m:
                for n in re.findall(r"\w+", m.group(1)):
                    names.setdefault(n.lower(), n)
            # A NESTED NAMESPACE the interface carries -- chrono's WallClock -- is reachable
            # through the module when its members are public, which the interface says.
            m = re.match(r"\s*namespace\s+(\w+)\s*$", code, re.I)
            if m and not m.group(1).lower().startswith("__tko_mod_") and "public " in text:
                names.setdefault(m.group(1).lower(), m.group(1))
    return names


FBNS_HEADERS = {"fberror.bi", "fbpark.bi", "fbclaim.bi", "fblimits.bi", "fbatomic.bi"}


# WHAT EACH HEADER INCLUDED, frozen from inc/ on 2026-10-10 before inc/fb was deleted: the
# fb/ library headers and the namespace-FB ones that stay. port() re-adds what a removed
# header brought with it ('fb/string.bi' gave its includer 'fb/array.bi', hence Array).
HEADER_INCLUDES = {
    'containers.bi': ['fb/hash.bi', 'fb/array.bi', 'fb/map.bi', 'fb/set.bi', 'fb/linkedlist.bi', 'fb/orderedmap.bi', 'fb/orderedset.bi', 'fb/sort.bi'],
    'fb/channel.bi': ['fberror.bi', 'fbpark.bi', 'fbclaim.bi'],
    'fb/complex.bi': ['fb/math.bi', 'fb/mathtext.bi'],
    'fb/currency.bi': ['fb/optional.bi', 'fblimits.bi'],
    'fb/decimal.bi': ['fb/optional.bi', 'fb/currency.bi', 'fblimits.bi'],
    'fb/filesystem.bi': ['fb/fserror.bi', 'fb/fspath.bi', 'fb/fsinfo.bi', 'fb/fsdir.bi', 'fb/fsops.bi', 'fb/fsglob.bi', 'fb/fslink.bi', 'fb/fsvolume.bi', 'fb/fsadvanced.bi'],
    'fb/finance.bi': ['fb/finerror.bi', 'fb/fincore.bi', 'fb/finsolve.bi', 'fb/fintvm.bi', 'fb/finloan.bi', 'fb/fincash.bi', 'fb/findeprec.bi', 'fb/finport.bi'],
    'fb/fincash.bi': ['fb/fincore.bi', 'fb/finsolve.bi', 'fb/array.bi'],
    'fb/fincore.bi': ['fb/finerror.bi', 'fb/math.bi', 'fb/decimal.bi', 'fb/currency.bi', 'fb/chrono.bi'],
    'fb/findeprec.bi': ['fb/fincore.bi', 'fb/array.bi'],
    'fb/finerror.bi': ['fb/result.bi', 'fb/math.bi', 'fb/decimal.bi', 'fb/currency.bi'],
    'fb/finloan.bi': ['fb/fincore.bi', 'fb/fintvm.bi', 'fb/finsolve.bi', 'fb/array.bi'],
    'fb/finport.bi': ['fb/fincore.bi', 'fb/fincash.bi', 'fb/stats.bi', 'fb/array.bi'],
    'fb/finsolve.bi': ['fb/finerror.bi', 'fb/math.bi'],
    'fb/fintvm.bi': ['fb/fincore.bi', 'fb/finsolve.bi'],
    'fb/fsadvanced.bi': ['fb/fserror.bi', 'fb/fspath.bi', 'fb/array.bi'],
    'fb/fsdir.bi': ['fb/fserror.bi', 'fb/fspath.bi', 'fb/fsinfo.bi', 'fb/array.bi'],
    'fb/fserror.bi': ['fb/result.bi'],
    'fb/fsglob.bi': ['fb/fserror.bi', 'fb/fspath.bi', 'fb/fsinfo.bi', 'fb/fsdir.bi', 'fb/array.bi'],
    'fb/fsinfo.bi': ['fb/fserror.bi', 'fb/fspath.bi'],
    'fb/fslink.bi': ['fb/fserror.bi', 'fb/fspath.bi', 'fb/fsinfo.bi', 'fb/fsdir.bi', 'fb/fsops.bi'],
    'fb/fsops.bi': ['fb/fserror.bi', 'fb/fspath.bi', 'fb/fsinfo.bi', 'fb/fsdir.bi', 'fb/array.bi'],
    'fb/fspath.bi': ['fb/fserror.bi', 'fb/array.bi'],
    'fb/fsvolume.bi': ['fb/fserror.bi', 'fb/fspath.bi', 'fb/array.bi'],
    'fb/logasync.bi': ['fb/logsink.bi'],
    'fb/logdefault.bi': ['fb/logger.bi'],
    'fb/logerror.bi': ['fb/logrecord.bi'],
    'fb/logfile.bi': ['fb/logsink.bi', 'fb/fsops.bi'],
    'fb/logger.bi': ['fb/logsink.bi', 'fb/fserror.bi'],
    'fb/logging.bi': ['fb/logrecord.bi', 'fb/logrender.bi', 'fb/logsink.bi', 'fb/logfile.bi', 'fb/logasync.bi', 'fb/logger.bi', 'fb/logdefault.bi'],
    'fb/logmacros.bi': ['fb/logging.bi'],
    'fb/logrecord.bi': ['fb/chrono.bi', 'fb/array.bi', 'fb/mathtext.bi'],
    'fb/logrender.bi': ['fb/logrecord.bi'],
    'fb/logsink.bi': ['fb/logrender.bi', 'fb/logerror.bi'],
    'fb/map.bi': ['fb/hash.bi', 'fb/array.bi'],
    'fb/math.bi': ['fblimits.bi'],
    'fb/mathint.bi': ['fb/optional.bi', 'fblimits.bi'],
    'fb/mathtext.bi': ['fb/optional.bi', 'fblimits.bi'],
    'fb/moneyformat.bi': ['fb/decimal.bi'],
    'fb/optional.bi': ['fberror.bi'],
    'fb/orderedmap.bi': ['fb/array.bi'],
    'fb/orderedset.bi': ['fb/array.bi'],
    'fb/random.bi': ['fblimits.bi'],
    'fb/result.bi': ['fberror.bi'],
    'fb/select.bi': ['fb/channel.bi'],
    'fb/set.bi': ['fb/hash.bi', 'fb/array.bi'],
    'fb/sharedptr.bi': ['fberror.bi', 'fbatomic.bi'],
    'fb/sort.bi': ['fb/array.bi', 'fb/linkedlist.bi'],
    'fb/stats.bi': ['fb/array.bi', 'fblimits.bi'],
    'fb/string.bi': ['fb/array.bi'],
    'fb/sync.bi': ['fb/channel.bi', 'fb/scheduler.bi'],
    'fb/tui.bi': ['fb/tuicore.bi', 'fb/tuiwidth.bi', 'fb/tuiterm.bi', 'fb/tuibuffer.bi', 'fb/tuilayout.bi', 'fb/tuiinput.bi', 'fb/tuiwidget.bi', 'fb/tuiwidgets.bi', 'fb/tuidraw.bi', 'fb/tuiform.bi', 'fb/tuichrome.bi', 'fb/tuiapp.bi'],
    'fb/tuiapp.bi': ['fb/tuichrome.bi', 'fb/chrono.bi'],
    'fb/tuibuffer.bi': ['fb/tuicore.bi', 'fb/tuiwidth.bi', 'fb/array.bi'],
    'fb/tuichrome.bi': ['fb/tuiform.bi'],
    'fb/tuidraw.bi': ['fb/tuiwidgets.bi'],
    'fb/tuiform.bi': ['fb/tuidraw.bi'],
    'fb/tuiinput.bi': ['fb/tuicore.bi', 'fb/tuiterm.bi', 'fb/optional.bi', 'fb/array.bi'],
    'fb/tuilayout.bi': ['fb/tuicore.bi', 'fb/array.bi'],
    'fb/tuiterm.bi': ['fb/tuicore.bi', 'fb/result.bi', 'fb/optional.bi'],
    'fb/tuiwidget.bi': ['fb/tuicore.bi', 'fb/tuiwidth.bi', 'fb/tuibuffer.bi', 'fb/tuilayout.bi', 'fb/tuiinput.bi', 'fb/optional.bi', 'fb/array.bi'],
    'fb/tuiwidgets.bi': ['fb/tuiwidget.bi'],
    'fb/tuiwidth.bi': ['fb/tuiwidthtab.bi', 'fb/array.bi'],
    'fb/vector.bi': ['fblimits.bi'],
}


def includes_of(hdr):
    """The fb/ headers (and containers.bi, fblimits.bi and the rest) one header included."""
    return HEADER_INCLUDES.get(hdr, [])


def port(text, conv, pub):
    mods = []
    keep_fb = False
    removed = []
    for m in RX_INC.finditer(text):
        hdr = os.path.basename(m.group(1))
        mod = HDR_MODULE.get(hdr)
        if mod in conv:
            if mod not in mods:
                mods.append(mod)
            removed.append(m.group(1))
        else:
            keep_fb = True
    if not mods:
        return None
    # WHAT A REMOVED HEADER BROUGHT WITH IT: 'fb/string.bi' included 'fb/array.bi', and the
    # test wrote 'Array' through 'using FB'. A header of a converted module is an import;
    # one of a module still a facade is included again.
    readd, seen = [], set(removed)
    work = list(removed)
    while work:
        h = work.pop(0)
        for d in includes_of(h):
            if d in seen:
                continue
            seen.add(d)
            dm = HDR_MODULE.get(os.path.basename(d))
            if dm in conv:
                if dm not in mods:
                    mods.append(dm)
                work.append(d)
            elif dm is not None or d in FBNS_HEADERS:
                readd.append(d)
                keep_fb = True
    text = RX_INC.sub(lambda m: "" if HDR_MODULE.get(os.path.basename(m.group(1))) in conv else m.group(0), text)
    if readd:
        text = re.sub(r"(?im)^(\s*)using\s+FB\s*$",
                      lambda m: "".join('%s#include once "%s"\n' % (m.group(1), d) for d in readd) + m.group(0),
                      text, count=1)
    using = ", ".join(mods)
    text = re.sub(r"(?im)^(\s*)using\s+FB\s*$",
                  lambda m: m.group(1) + "using " + using + (("\n" + m.group(1) + "using FB") if keep_fb else ""),
                  text)

    def qual(m):
        n = m.group(1)
        for mod in mods:
            if n.lower() in pub[mod]:
                return mod + "." + n
        return m.group(0)
    text = re.sub(r"\bFB\.(\w+)", qual, text)
    # The imports go first: before any code, after the opening comments.
    lines = text.split("\n")
    at = 0
    while at < len(lines) and (lines[at].strip() == "" or lines[at].lstrip().startswith("'")):
        at += 1
    imp = ['#import "std/%s"' % m for m in mods]
    return "\n".join(lines[:at] + imp + lines[at:])


def test_for(rel, base, has_mod2):
    """The .test for one ported file, from its baseline record."""
    area, fn = rel.split("/")
    name = fn[:-4]
    rec = base.split("\n", 1)
    head = rec[0]
    body = rec[1] if len(rec) > 1 else ""
    kv = dict(x.split("=", 1) for x in head.split())
    mode = kv["mode"]
    exe = "tests/std/%s/%s.exe" % (area, name)
    src = "tests/std/%s/%s" % (area, fn)
    extra = (" tests/std/%s/%s_mod2.bas" % (area, name)) if has_mod2 else ""
    t = ["'' tests/vendor/fbc-tests/%s ported to the std modules (build/stdtests.py, generated)." % rel,
         "'' Expected: what tests/std/baseline/%s/%s.txt recorded for the original." % (area, name),
         "'' TEST: cli"]
    if mode == "SUITE":
        t.append("'' ARGS: -target windows-x86_64 -mt -i toolchains/tiko-windows/inc %s %s%s -o %s"
                 % (DRIVER, src, extra, exe))
    else:
        t.append("'' ARGS: -target windows-x86_64 -i toolchains/tiko-windows/inc %s%s -o %s" % (src, extra, exe))
    t.append("'' ENV: TIKO_LIBPATH=toolchains/tiko-windows/lib/windows-x86_64")
    t.append("'' EXPECT-EXIT: %s" % kv["build"])
    if mode == "COMPILE_ONLY_FAIL":
        for ln in body.split("\n"):
            if ln.strip():
                t.append("'' EXPECT-OUT: %s" % ln.strip())
    elif kv["build"] == "0":
        t.append("'' RUN: %s" % exe)
        if kv.get("run", "0") != "0":
            t.append("'' EXPECT-RUN-EXIT: %s" % kv["run"])
        if mode == "SUITE":
            for ln in body.split("\n"):
                if re.match(r"\s+\d+\s+\d+\s+\d+\s+fbc_tests\.", ln):
                    if rel in HOST_DEPENDENT:
                        # the counts are the recording machine's; match from the suite name on
                        t.append("'' Host-dependent: %s" % HOST_DEPENDENT[rel])
                        ln = ln[ln.index("fbc_tests."):]
                    t.append("'' EXPECT-RUN-OUT: %s" % ln.strip())
    return "\n".join(t) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    conv = converted()
    pub = {m: public_names(m) for m in conv}
    want = {}
    for dp, _, fs in os.walk(VENDOR):
        for f in fs:
            if not (f.endswith(".bas") or f.endswith(".bi")):
                continue
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, VENDOR).replace("\\", "/")
            raw = open(p, "rb").read()
            if b'"fb/' not in raw and b'"containers.bi"' not in raw:
                continue
            # ComPtr is no longer a supported feature (2026-10-10): its tests are not ported.
            if b'"fb/comptr.bi"' in raw:
                continue
            text = raw.decode("utf-8").replace("\r\n", "\n")
            if not RX_INC.search(text):
                continue
            ported = port(text, conv, pub)
            if ported is None:
                continue
            for old, new in PATCHES.get(rel, []):
                assert ported.count(old) == 1, (rel, old)
                ported = ported.replace(old, new)
            for rx, new in RPATCHES.get(rel, []):
                ported, k = re.subn(rx, new, ported)
                assert k > 0, (rel, rx)
            want[rel] = ported
    # A SIBLING A PORT INCLUDES -- tui/tuiwidthdata_.bi -- is copied beside it as it is: it
    # names no fb/ header, or it would have been ported above.
    for rel in list(want):
        area = rel.split("/")[0]
        for inc in re.findall(r'(?im)^\s*#include(?:\s+once)?\s+"([^"/\\]+)"', want[rel]):
            sib = area + "/" + inc
            p = os.path.join(VENDOR, area, inc)
            if sib not in want and os.path.isfile(p):
                want[sib] = open(p, "rb").read().decode("utf-8").replace("\r\n", "\n")
    for rel in sorted(want):
        if not rel.endswith(".bas") or rel.endswith("_mod2.bas"):
            continue
        area, fn = rel.split("/")
        basef = os.path.join(OUT, "baseline", area, fn[:-4] + ".txt")
        if not os.path.isfile(basef) or rel in NOT_RUN:
            continue
        base = io.open(basef, encoding="utf-8").read()
        want[rel[:-4] + ".test"] = test_for(rel, base, (rel[:-4] + "_mod2.bas") in want)
    changed = []
    for rel, text in sorted(want.items()):
        p = os.path.join(OUT, rel)
        old = io.open(p, encoding="utf-8", newline="").read() if os.path.isfile(p) else None
        if old != text:
            changed.append(rel)
            if not a.check:
                os.makedirs(os.path.dirname(p), exist_ok=True)
                io.open(p, "w", encoding="utf-8", newline="\n").write(text)
    for rel in changed:
        print("stdtests: %s %s" % ("would write" if a.check else "wrote", rel))
    print("stdtests: %d files for modules %s, %d changed" % (len(want), ",".join(sorted(conv)), len(changed)))
    # API PARITY: every name the module's facade exported (frozen in tests/std/api/<m>.txt
    # when the facades went) is still a public name of the real module.
    bad = 0
    for m in sorted(conv):
        apif = os.path.join(OUT, "api", m + ".txt")
        if not os.path.isfile(apif):
            continue
        for ln in io.open(apif, encoding="utf-8"):
            n = ln.split()[0] if ln.strip() else ""
            if n and n.lower() not in pub[m]:
                print("stdtests: API %s.%s is not public any more" % (m, n))
                bad += 1
    if (a.check and changed) or bad:
        sys.exit(1)


if __name__ == "__main__":
    main()
