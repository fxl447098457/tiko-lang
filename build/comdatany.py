"""comdatany.py -- a GUID archive's COMDATs from SAME_SIZE to ANY, in place.

    python build/comdatany.py <archive.lib> ...

Prints "<archive> <patched> <already ANY>" per archive. Changes one byte per
COMDAT section and nothing else: no member, symbol, size or offset moves.

WHY. mingw-w64's GUID archives (uuid, dxguid, strmiids, ...: lib/implib/static/)
put each GUID in its own '.rdata$<name>' COMDAT with selection 3,
IMAGE_COMDAT_SELECT_SAME_SIZE. MSVC compiles DEFINE_GUID under INITGUID as
__declspec(selectany): selection 2, IMAGE_COMDAT_SELECT_ANY. lld-link reports
two COMDATs of DIFFERENT selection types as a duplicate symbol (it reconciles
ANY with SAME_SIZE only under -lldmingw), so an MSVC-built object that defines
a GUID -- static SDL3 defines GUID_DEVINTERFACE_* and CLSID_CUrlHistory -- and a
uuid.lib member pulled in for another GUID (IID_IUnknown) cannot link together.
Measured 2026-11-16 on tkedit's link: 'duplicate symbol: GUID_DEVINTERFACE_DISK
>>> defined at SDL3_windows_x86_64.a(SDL_hidapi.c.obj) >>> uuid.lib(...)'.

It hid behind the search order. With LIB unset, clang's msvc driver puts the
Windows SDK's lib folder ahead of the toolchain's, and the SDK's uuid.lib (ANY)
wins; a shell after vcvars64.bat sets LIB, clang then adds no SDK folder, and
lld-link finds the toolchain's uuid.lib first.

WHY ANY IS SAFE. Every GUID is 16 bytes, so the size check SAME_SIZE adds can
never fire; ANY is what Microsoft's own uuid.lib and every selectany GUID use.
Only selection 3 is touched -- 0 (not a COMDAT) and anything else stay.
"""

import struct
import sys

SAME_SIZE, ANY = 3, 2
SCN_LNK_COMDAT = 0x1000
AMD64 = 0x8664


def patch_coff(buf, base, size):
    """Patch one COFF object at buf[base:base+size]; returns (patched, any)."""
    if size < 20:
        return 0, 0
    machine, nsect, _, symptr, nsyms, optsz, _ = struct.unpack_from("<HHIIIHH", buf, base)
    if machine != AMD64 or symptr == 0 or symptr + nsyms * 18 > size:
        return 0, 0        # an import member, a /, // or other non-object member
    shdr = base + 20 + optsz
    comdat = set()
    for i in range(nsect):
        chars = struct.unpack_from("<I", buf, shdr + i * 40 + 36)[0]
        if chars & SCN_LNK_COMDAT:
            comdat.add(i + 1)
    patched = already = 0
    i = 0
    while i < nsyms:
        at = base + symptr + i * 18
        secnum, _, sclass, naux = struct.unpack_from("<hHBB", buf, at + 12)
        # A section definition: STATIC storage, one aux record, a COMDAT section.
        if sclass == 3 and naux == 1 and secnum in comdat:
            sel_at = at + 18 + 14
            if buf[sel_at] == SAME_SIZE:
                buf[sel_at] = ANY
                patched += 1
            elif buf[sel_at] == ANY:
                already += 1
        i += 1 + naux
    return patched, already


def patch_archive(path):
    with open(path, "rb") as f:
        buf = bytearray(f.read())
    if buf[:8] != b"!<arch>\n":
        sys.exit(f"comdatany: {path} is not an archive")
    pos, patched, already = 8, 0, 0
    while pos + 60 <= len(buf):
        name = bytes(buf[pos:pos + 16]).rstrip()
        size = int(bytes(buf[pos + 48:pos + 58]).decode("ascii").strip())
        data = pos + 60
        if name not in (b"/", b"//"):
            p, a = patch_coff(buf, data, size)
            patched += p
            already += a
        pos = data + size + (size & 1)
    if patched:
        with open(path, "wb") as f:
            f.write(buf)
    return patched, already


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__.split("\n\n")[1])
    for a in sys.argv[1:]:
        p, n = patch_archive(a)
        print(f"{a} {p} {n}")
