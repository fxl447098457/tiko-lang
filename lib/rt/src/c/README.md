# src/c -- the closed list of files that stay C

RFC-0003 section 4. Anything here must be listed below with its reason, or
`build/lint.sh` fails the build. The list is closed: it shrinks, it does not grow.

**Currently empty, and the table below is what was PREDICTED. The six files the
build actually still takes from fbc are different, and each now has a measured
reason -- see the second table.**

**Present, and compiled by `build/build.sh`:**

| File | Reason |
| --- | --- |
| `msvcinit.c` | The runtime's startup hook for the MSVC ABI, and MSVC-only -- empty on the gnu targets, where fbc's own `fbrt0.o` is on the link line doing this job. fbc names that object itself and it is not an archive member, so a program linked against tiko-rt's archive ALONE never calls `fb_hRtInit`. Measured: the process stayed in the `C` locale and `UCASE` left every accented character alone. `.CRT$XCY` is the last `.CRT$XC` fragment and tiko-rt walks the range backwards, as mingw walks `.ctors`, so it runs before every constructor a program can write -- RFC-0006 §4.4. |
| `msvccrt.c` | The CRT startup and the six things `ucrtbase.dll` does not export, and MSVC-only. Without it a windows-x86_64 link needed **Visual Studio on the compiling machine** -- not the SDK, VC Tools specifically, for `libcmt.lib`, `libvcruntime.lib`, `oldnames.lib` and `legacy_stdio_definitions.lib` -- and those are **not in Microsoft's own redistributable set**, which carries runtime DLLs and no static libraries, so shipping copies was not obviously permitted. What was missing is small, because `ucrtbase.dll` is a Windows system component exporting 2,650 symbols: `mainCRTStartup` (in no DLL), `_fltused`, `atexit` (over the exported `_crt_atexit`), `sprintf` (inline in the UCRT headers), `time`/`localtime` (named `_time64`/`_localtime64`), `feraiseexcept` (inline in the UCRT's `fenv.h`, and set through the exported `fesetexceptflag` so exactly the flags asked for are raised, as fbc's libmingwex does), and `__chkstk` (in `libcmt`, and **not** in clang's `clang_rt.builtins` -- checked). Nothing is transliterated: every entry point is declared from its documented signature, and `sprintf`'s option word was read out of the SDK's `stdio.h` rather than guessed, because getting it wrong is a silent formatting difference and not a link error. |
| `msvccrtexe.c` | `mainCRTStartup`, the entry point of an EXECUTABLE, and a translation unit of its own. An archive member is pulled in only to satisfy an undefined symbol, so keeping this out of `msvccrt.c` is what stops a DLL from dragging in a reference to `main`, which a DLL has not got. It runs the `.CRT$XI*` and `.CRT$XC*` initialiser ranges, calls `main`, and exits through the UCRT's `exit` so the `_crt_atexit` handlers run and stdio is flushed. It also registers the walk of the `.CRT$XT*` TERMINATOR range: LLVM lowers `@llvm.global_dtors` into `.CRT$XTX` on this target and the real MSVC CRT walks that range inside `exit`, which the UCRT's `exit` does not do for our fragments -- so without it a module destructor was emitted correctly and never called. The same handler then calls `fb_hRtExit`, after the destructors, as the gnu targets' priority-100 destructor runs: `msvcinit.c` used to `atexit` it, which ran it first and left an `-mt` destructor entering a deleted lock. |
| `msvccrtdll.c` | `_DllMainCRTStartup`, the entry point of a DLL, split out for the same reason and with the same rule: a DLL link must not pull in the executable entry point or its reference to `main`. Its detach runs the DLL's own exit table, then `fb_hRtExit`. |
| `atomic.c` | FreeBASIC has no atomic operations and no way to spell a memory barrier, so there is nothing to reimplement in FB. tiko-rt's own, written against the three signatures in `fb_thread.h`; clang builtins throughout, so the MinGW and MSVC builds of it are textually identical. |
| `oop_object.c` | `fb_Object$`'s default constructor and its RTTI record, on EVERY target since 2026-09-19 (decision 0015, D15). It was `msvcobject.c`, and MSVC-only: empty on the gnu targets, where fbc's own `oop_object.o` supplied both from `lib/<target>-fb/`, and retiring fbc's libfb from there is what moved them here. **fbc RESERVES `__fb_ZTS6Object`**: every module it compiles gets an automatic `external global` declaration of it, so a FreeBASIC file defining it emits the name twice and clang refuses the module -- the reason it is C, re-measured 2026-09-05. The layout was taken from fbc's own object with `llvm-objdump`, not from its sources: RTTI `{ NULL, "6OBJECT", NULL }`, a local vtable `{ NULL, &RTTI }`, and a constructor storing the vtable **plus `sizeof(header)`**, which is the bias `src/oop/istypeof.tiko` subtracts back. Found by `build/gatemsvc.sh`: 728 modules of fbc's suite linked three symbols short. **The name is fbc's member name now, deliberately**; while the file was empty on the gnu targets that name replaced fbc's `oop_object.o` with an empty object in the gate's merge and deleted the constructor, which is why it was renamed then and is not a hazard any more. |
| `errjmp.c` | The non-local jump ON ERROR GOTO needs, since 2026-09-20: `fb_ErrorJmpGo`/`fb_ErrorJmpGoAt` longjmp into the buffer the compiler `_setjmp`s where ON ERROR GOTO appears. fbc's error path is a cross-function computed goto, which GCC takes and LLVM's `indirectbr` cannot express (it names labels of its own function only), so a throw inside a called procedure died with STATUS_BREAKPOINT where fbc ran the handler. setjmp/longjmp is the jump C can spell and FreeBASIC cannot. Nothing is unwound -- no destructor, no DEFER -- which is what `com/comptr-error-path.bas` asserts. No libc headers: the two entry points are declared by hand and the buffer is a plain aligned array. |
| `fbrt0.c` | The runtime's startup and shutdown hooks on the GNU targets -- win64 and linux-x86_64 -- since 2026-10-09: `fb_hRtInit` / `fb_hRtExit` at constructor/destructor priority **100**, below the 101 floor FreeBASIC code can spell, which is why it is C (the first table's predicted `fbrt0.c`). It replaces fbc's `fbrt0.o`, the last file of fbc's that a gnu link still named. Built as a LOOSE OBJECT into `lib/<target>/fbrt0.o` (and `fbrt0pic.o` for Linux), never an archive member: nothing refers to it by name, so an archive search would never pull it in; the driver names it on the link line as fbc's driver names its own. The layout was measured from fbc's two packaged copies with `llvm-nm`/`llvm-objdump`, not read from fbc's source. Empty under `TKORT_MSVC`, where `msvcinit.c` does the job. |
| `fbrtapp.c` | An Android app's entry, for `tiko -app` (docs/tiko-android A4), and Android-only -- empty elsewhere. `SDL_main`, which SDL's Java side calls on its own thread: stdout/stderr to logcat (a pipe, a reader thread, `__android_log_write`), then the program's `tko_AppMain` under `setjmp`, so that `fb_End` -- through the Android-only hook `tkort_SetAppEnd` in `init/rtinit.tiko` -- returns from `SDL_main` rather than calling `exit()`, which kills an app (measured). Then `SDL_Quit` and libmain.so's `.fini_array` backwards (module destructors, `fb_hRtExit`), because ART ends the process without native clean-up. It also gives the runtime an app's file model (A5, A6): `EXEPATH` is `"."`, the working directory is the app's internal storage, and a read-only open of a relative path that finds no file reads the APK's asset -- through the Android-only hooks `tkort_SetAppAssetOpen` (a stdio stream over SDL's I/O, for OPEN) and `tkort_SetAppAssetFd` (the asset copied into an unlinked cache file, for `fs/ops` and std/fs) in `fs/upath.tiko`. A LOOSE OBJECT like `fbrt0.c`, built PIC into `lib/android-<arch>/fbrtapp.o` and named by the driver on an app's link only. C because `setjmp` must be in the frame `longjmp` returns to. |
| `portinsn.c` | The x86 `inb` and `outb` instructions, linux-x86_64 only, since 2026-09-19 (decision 0015, D15). `src/sys/ports.tiko` is `fb_hIn`/`fb_hOut` and keeps the permission check in FreeBASIC; `-gen llvm` rejects inline ASM (measured, recorded in ports.bas) and no API performs port I/O, so the two instructions are all that is here. This is the first table's predicted `sys_portio.c`, not named that because the logic is not here. Needed because `src/io/hookkey.tiko` refers to both from the same object as INKEY, GETKEY and WAIT, and fbc's `sys_portio.o` is no longer linked behind tiko-rt. |

**Predicted:** The spike slice (memory, strings, error, startup) needs
nothing from it. The entries expected later, each already justified in RFC-0003:

| Expected file | Reason |
| --- | --- |
| `hinit_x87.c` | x87 control word via `fstcw`/`fldcw` -- inline asm, rejected by `-gen llvm` |
| `sys_portio.c` | `inb`/`outb` -- inline asm, and the fbportio driver path |
| `cpudetect.s` | hand-written assembly |
| `fbrt0.c` `fbrt1.c` `fbrt2.c` | constructor priority **100**. PROBE-4 confirmed FB's `constructor 101` does beat every unprioritised constructor -- but 101 is FB's floor, so a user can *tie* it. The C stub sits below the range user code can express, which is why it was chosen. Staying C |

---

## What is actually still fbc's, measured 2026-09-19

`build/gate.sh` now reports **533 of 534 fbc members replaced** on win64 and 531 on
linux-x86_64. fbc's suite is identical to baseline on both: the same 11 `threadcall` failures.

**On windows-x86_64, nothing.** It has no `lib/<target>-fb/` directory and links tiko-rt alone.

**On win64 and linux-x86_64, nothing from `libfb` either, once decision 0015 (D15) is packaged.**
`llvm-nm` over the packaged archives found only the following symbols that fbc's `libfb.a` defines
and tiko-rt's did not. They are why fbc's `libfb.a` and `libfbmt.a` were still linked behind
tiko-rt:

| Symbol | Now |
| --- | --- |
| `_ZN10fb_Object$C1Ev`, `__fb_ZTS6Object` (win64, linux) | `oop_object.c`, on every target |
| `fb_ThreadCall` (all three) | `src/thread/call.tiko`: NULL, as fbc-modern's own `DISABLE_FFI` build returns. The compiler warns at every THREADCALL |
| `fb_hIn`, `fb_hOut` (linux) | `src/sys/ports.tiko` with `portinsn.c` |
| `fb_InitProfileCycles`, `fb_EndProfileCycles`, `fb_ProfileGetCyclesProfiler` | **Not provided, deliberately.** Only compiled code built with `-profile` calls them; the LLVM backend emits none, and tiko has no `-profile` in any spelling (RFC-0006 section 14) |
| `__fb_keytable` (win64) | **Not provided.** Only fbc's `libfbgfx` refers to it. tiko links `libtkogfx` on windows-x86_64 and no graphics library on win64 |

So the closed list is five files of tiko-rt's own C:
- **one hard case**, `atomic.c`, until RFC-0002 lands;
- **one reserved symbol**, `oop_object.c`, which is fbc's to give up;
- **one instruction pair**, `portinsn.c`;
- **the MSVC CRT shims.**

The 2026-09-05 version of this section said "528 of 534 members replaced" and listed six survivors.
Two of those six became FreeBASIC (`src/oop/object_copyctor.tiko`, `src/oop/istypeof.tiko`). The other
four are the table above.

What is still fbc's in `lib/<target>-fb/` is **not `libfb`**:
- its CRT startup objects (`fbrt0.o` etc.);
- `libfbgfx`;
- the third-party archives: libffi, MinGW's CRT and import libraries, and gcc's runtime.

Retiring those is outside D15.
