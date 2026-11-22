# tiko-rt

The FreeBASIC runtime library, written in FreeBASIC.

API- and ABI-compatible with fbc-modern's `libfb`, for use by the
[tiko](../tiko-lang) compiler. Built by tiko itself (the tree's `bin/tiko`) since
2026-10-10, where it was FBC-Modern's `-gen llvm`; targets **windows-x86_64, win64 and
linux-x86_64**.

> **Status: decision spike.** This exists to answer one question — *would a
> runtime written in FreeBASIC be as efficient and performant as the C one?* —
> by measuring it. tiko-lang's decisions D2 ("write no runtime") and D13
> ("recompile the C rtlib with clang") are **unchanged** until the spike reports.
> A no-go is a real outcome and most of this repo transfers to D13 either way.

Design record: [`C:\dev\docs\tiko-rt`](../docs/tiko-rt/README.md).

## The one rule

**tiko-rt is a reimplementation in FreeBASIC, not a transliteration.** Until
2026-08-29 no `rtlib/**/*.c` file was ever opened; the author lifted that rule
(R2) on that date and rtlib bodies may now be read to learn what a function
does -- see [PROVENANCE.md](PROVENANCE.md) for the rule, what it costs and what
stands. Copying a body in is still not the method, and `build/lint.sh` keeps any
`.c` outside the closed list in `src/c/` out of the tree.

## Build

```sh
build/build.sh [Debug|Release|RelWithDebInfo] [target ...]
```

Produces `lib/<target>/libfb.a` and `lib/<target>/libfbmt.a` — one source tree,
two builds, distinguished by `-d ENABLE_MT`, exactly as the C runtime does. The
archive names are fbc's own on purpose: that is what lets `build/gate.sh` drop
tiko-rt into fbc's link line.

## Verify

Four gates. None is optional and none substitutes for another.

```sh
build/lint.sh                    # provenance + the freestanding subset
build/test.sh                    # compile-only on every target, run on the host
build/gate.sh win64 --baseline   # the harness, against the UNMODIFIED C runtime
build/gate.sh win64              # the real thing: fbc's 2,715-file suite
build/bench.sh win64             # C-libfb vs FB-libfb, the actual question
```

Console bytes on a real terminal (COLOR, LOCATE, CLS write nothing to a redirected stdout,
so the gates above cannot see them) are pinned against fbc's by
`build/ptylane.sh [linux-x86_64] [macos-arm64]`: `tests/pty/*.bas` under a pty with
`TERM=xterm-256color`, in WSL and on the Mac.

`gate.sh --baseline` comes first and matters most. A harness that cannot
reproduce fbc's published numbers with fbc's own runtime cannot judge a change
to it.

## Requirements

| Tool | Where |
| --- | --- |
| tiko | the tree's `bin/tiko` (`build/build.sh`) — override with `TKORT_TIKO` |
| clang 18+ | on `PATH`; tiko hands it the emitted IR, and the C residue is compiled with it |
| llvm-ar, llvm-nm | on `PATH` (D13: the toolchain is 100% LLVM) |
| FBC-Modern | the ORACLE scripts only (`gate.sh`, `diff.sh`, ...; `build/oracle.sh`): `C:\dev\fbc-modern`, or `TIKO_ORACLE_FBC` / `FBC_TREE`. Without it they skip |
| make | for `gate.sh` only |

## Layout

```
build/    common.sh build.sh lint.sh test.sh gate.sh bench.sh
src/inc/  descriptor layouts, macro contracts, error codes
src/sys/  the OS and libc surface, and why it is bound the way it is
src/c/    the closed list of files that stay C -- see its README
tests/    unit/ (compile + run)  abi/ (layout and symbol parity)  bench/
lib/      build output
```

## Where the work is

Step table, open probes, gate numbers and measured facts:
[`docs/tiko-rt/status/spike.md`](../docs/tiko-rt/status/spike.md).
