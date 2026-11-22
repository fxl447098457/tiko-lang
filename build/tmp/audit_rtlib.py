import re, glob

results = []
paths = glob.glob('src/**/*.tiko', recursive=True) + glob.glob('src/**/*.ti', recursive=True)
for path in paths:
    try:
        lines = open(path, encoding='utf-8', errors='replace').read().split('\n')
    except Exception:
        continue
    block = None
    for i, ln in enumerate(lines, 1):
        s = ln.strip()
        if s.startswith("''") or s.startswith("'"):
            continue
        m = re.match(r'extern\s+"([a-zA-Z\-]+)"', s)
        if m:
            block = m.group(1)
            continue
        if block:
            if re.match(r'end extern\b', s):
                block = None
                continue
            dm = re.search(r'declare\s+(?:sub|function)\s+\w+\s+alias\s+"([^"]+)"', s)
            if dm and block == 'rtlib':
                alias = dm.group(1)
                if not alias.startswith('fb_'):
                    results.append((path, i, alias))

print(len(results), 'non-fb_ aliases inside extern "rtlib" blocks:')
for p, i, a in results:
    print(' ', p + ':' + str(i) + ': alias "' + a + '"')
