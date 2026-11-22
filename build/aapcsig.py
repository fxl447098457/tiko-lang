"""aapcsig.py -- compare tiko's AAPCS64 (Apple) signatures with clang's. See aapcsig.sh.

    python aapcsig.py <clang .ll> <tiko .ll>

Every function the C side DECLARES (it calls it) or DEFINES is matched by name against
the one tiko declares or defines, and the two signatures are compared after the
spellings that are the same registers are made equal:

  - attributes that move no bits: noundef, dead_on_unwind, writable, the sret pointee
    type and its alignment;
  - an HFA result clang writes as its struct (%struct.F3 = { float, float, float }) is
    tiko's [3 x float] -- the same s0..s2, measured with 'clang -S';
  - a result clang writes as i24 / i40 / i48 / i56 is tiko's i64 -- the same x0, each
    side reading only the bytes the aggregate has.

Exits 1 on any other difference, or when a function the C side has is missing from
tiko's module.
"""
import re
import sys


def struct_types(text):
    """name -> list of flattened leaf types, for every '%struct.X = type { ... }'."""
    raw = {}
    for m in re.finditer(r'^%(struct\.\w+|union\.\w+) = type \{ ?(.*?) ?\}$', text, re.M):
        raw[m.group(1)] = [p.strip() for p in m.group(2).split(',') if p.strip()]

    def flat(name, seen=()):
        out = []
        for p in raw.get(name, []):
            am = re.match(r'^\[(\d+) x (.+)\]$', p)
            if am:
                inner = am.group(2)
                n = int(am.group(1))
                leaves = flat(inner[1:], seen) if inner.startswith('%') else [inner]
                out += leaves * n
            elif p.startswith('%'):
                out += flat(p[1:], seen)
            else:
                out.append(p)
        return out

    return {k: flat(k) for k in raw}


def norm_ret(ret, structs):
    ret = ret.strip()
    if ret.startswith('%'):
        leaves = structs.get(ret[1:], [])
        if leaves and len(set(leaves)) == 1 and leaves[0] in ('float', 'double') and len(leaves) <= 4:
            return '[%d x %s]' % (len(leaves), leaves[0])
    if ret in ('i24', 'i40', 'i48', 'i56'):
        return 'i64'
    return ret


def norm_params(params):
    params = re.sub(r'sret\([^)]*\)( align \d+)?', 'sret', params)
    # clang 23 marks a by-address aggregate 'align N dead_on_return': hints about the caller's
    # copy, not where the argument travels (seen 2026-11-19, clang 23.1.5). alignstack(8) on an
    # aarch64-linux HFA is NOT stripped: it is part of clang's signature, so tiko writes it.
    params = re.sub(r'\balign \d+ dead_on_return\b', '', params)
    params = re.sub(r'\b(noundef|dead_on_unwind|writable|signext|zeroext)\b', '', params)
    params = re.sub(r'%[\w.$"]+', '', params)       # parameter names of a definition
    params = re.sub(r'\s+', ' ', params)
    return ', '.join(p.strip() for p in params.split(',') if p.strip())


SIG = re.compile(r'^(declare|define)\s+(?:dso_local\s+|internal\s+|hidden\s+)*'
                 r'(\S+(?: \S+)*?|\[[^\]]+\]|%[\w.]+)\s+@"?([\w.$]+)"?\(', re.M)


def balanced(text, at):
    """The text from 'at' (just past an opening parenthesis) to its matching close."""
    depth = 1
    i = at
    while i < len(text) and depth:
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
        i += 1
    return text[at:i - 1]


def signatures(text):
    structs = struct_types(text)
    out = {}
    for m in SIG.finditer(text):
        name = m.group(3)
        if name.startswith('llvm.'):
            continue
        out[name] = (norm_ret(m.group(2), structs), norm_params(balanced(text, m.end())))
    return out


def main():
    c = signatures(open(sys.argv[1], encoding='utf-8').read())
    t = signatures(open(sys.argv[2], encoding='utf-8').read())
    bad = 0
    checked = 0
    for name in sorted(c):
        if name.startswith('call'):
            continue        # the C side's own callers: not part of the contract
        checked += 1
        if name not in t:
            print('MISSING  %s: clang %s(%s)' % (name, c[name][0], c[name][1]))
            bad += 1
        elif c[name] != t[name]:
            print('DIFFER   %s:\n    clang  %s(%s)\n    tiko   %s(%s)'
                  % (name, c[name][0], c[name][1], t[name][0], t[name][1]))
            bad += 1
    print('aapcsig: %d signatures, %d differ' % (checked, bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
