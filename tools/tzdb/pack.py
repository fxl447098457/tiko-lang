#!/usr/bin/env python3
"""pack.py -- a compiled zoneinfo tree into one .tzdb file for std/tzdata.

    python3 pack.py <zoneinfo-dir> <tzdata-version> <out.tzdb>

The tree is what `zic -b slim -d <dir> tzdata.zi` writes (tools/tzdb/build.sh runs it).
Every regular file whose name is a valid std/tz id and whose bytes start "TZif" is
an entry; posix/ and right/ are skipped. Files with the same bytes (the links) share
one copy of the data.

FORMAT, all integers big-endian like TZif itself:

    "TZDB"                      magic
    u32   1                     format
    u8    n, n bytes            tzdata version, ASCII ("2026f")
    u32   count
    count x { u8 n, n bytes id (ASCII), u32 offset, u32 length }   ids sorted bytewise
    data                        the TZif files; offset is from the start of data

std/tz reads it defensively anyway (pkg/std/tz/tzzone.tiko, tzDbParse).
"""
import os
import re
import struct
import sys

ID_RE = re.compile(r'^[A-Za-z0-9_+\-]+(/[A-Za-z0-9_+\-]+)*$')


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    root, version, out = sys.argv[1], sys.argv[2], sys.argv[3]
    if not re.fullmatch(r'[0-9]{4}[a-z]', version):
        sys.exit('pack.py: version must look like 2026f, got %r' % version)
    entries = {}
    for dirpath, dirnames, filenames in os.walk(root):
        rel = os.path.relpath(dirpath, root).replace(os.sep, '/')
        if rel == '.':
            dirnames[:] = [d for d in dirnames if d not in ('posix', 'right')]
            rel = ''
        for f in filenames:
            zid = (rel + '/' + f) if rel else f
            if not ID_RE.match(zid) or len(zid) > 255:
                continue
            with open(os.path.join(dirpath, f), 'rb') as fh:
                data = fh.read()
            if data[:4] != b'TZif':
                continue
            entries[zid] = data
    if not entries:
        sys.exit('pack.py: no zone files under %s' % root)

    blobs, where, ids = [], {}, sorted(entries, key=lambda s: s.encode('ascii'))
    offset = 0
    index = []
    for zid in ids:
        data = entries[zid]
        if data not in where:
            where[data] = offset
            blobs.append(data)
            offset += len(data)
        index.append((zid, where[data], len(data)))

    out_bytes = bytearray(b'TZDB')
    out_bytes += struct.pack('>I', 1)
    out_bytes += bytes([len(version)]) + version.encode('ascii')
    out_bytes += struct.pack('>I', len(index))
    for zid, off, ln in index:
        b = zid.encode('ascii')
        out_bytes += bytes([len(b)]) + b + struct.pack('>II', off, ln)
    for data in blobs:
        out_bytes += data
    with open(out, 'wb') as fh:
        fh.write(out_bytes)
    print('pack.py: %d ids, %d distinct files, %d bytes -> %s' % (len(index), len(blobs), len(out_bytes), out))


if __name__ == '__main__':
    main()
