# lib/implib -- windows-x86_64's import libraries, as source

`build/package.sh` turns these into `lib/windows-x86_64/*.lib` in a toolchain with
`build/implibs.sh build`: one `llvm-dlltool` run per `.def`, each `umbrella/<name>/`
merged into `<name>.lib` by `llvm-lib`, and `static/*.lib` copied through. Nothing outside this directory is read, so the default target's import
libraries need no fbc and no MinGW tree.

- `*.def` -- 822 DLLs, one export list each. The code/data split was decided once, on
  the machine `EXPORTED.txt` names, by `build/mkmsvcdef.py` (it consults System32).
- `umbrella/<name>/*.def` -- the five libraries that span several DLLs, one `.def` per DLL:
  `ucrt` (15 `api-ms-win-crt-*` API sets), `mincore` (77), `windowsapp` (79),
  `runtimeobject` (2 API sets) and `vfw32` (AVICAP32, AVIFIL32, MSVFW32). Each was once a
  single `<name>.def` naming `<name>.dll`, which no Windows has, so a program linking
  `-lucrt` or `-lvfw32` built and then failed to load (fixed 2026-11-16). An API set is no
  file in System32: export asks the loader for its host and takes the code/data split from
  there. Where two DLLs of one library export a name (mincore: ncrypt repeats 55 of
  bcrypt's), the first in the MinGW archive keeps it, as a MinGW link would.
- `static/*.lib` -- 16 archives with no DLL behind them: GUID and other data objects
  (`uuid`, `dxguid`, `strmiids`, ...).
- `EXPORTED.txt` -- inputs, machine and counts of the export.

Measured 2026-10-10: `build` reproduced all 843 libraries of the toolchain that
`mkmsvcimplibs.sh` had generated, byte for byte.

**Local additions**, kept by hand, are listed in `ADDED.txt`, and `export` puts them back, so
a fresh export reproduces the committed files: `strnlen` in `ucrtbase.def` and
`umbrella/ucrt/api-ms-win-crt-string-l1-1-0.def` (2026-10-13). mingw-w64 leaves it out because
its libmingwex supplies one; tiko links no libmingwex, so a Visual C++ static library that calls
it (SDL3's) could not link.

**A new Windows library**: write its `.def` by hand, or run
`build/implibs.sh export --from <dir of lib*.dll.a> --only "<name>"` and read the diff
(fbc-modern's `src/lib/win64` holds the inputs).

Derived from mingw-w64's import libraries -- ZPL 2.1, with parts in the public domain;
see `COPYING.MinGW-w64-runtime.txt`, which ships with them.
