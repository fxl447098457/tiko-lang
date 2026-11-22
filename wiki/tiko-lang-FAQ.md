# FAQ

**What is tiko?**
A compiled, statically typed programming language, with its own compiler, type system and runtime. See [What Is tiko](What-Is-tiko-lang).

**Is tiko a BASIC?**
No. Its syntax comes from the most readable family of languages ever designed for people, and it keeps that readability on purpose: `end function` and `next` tell a reviewer which block just closed, with no brace counting and no indentation errors. Everything underneath is tiko's own. One consequence is that it still compiles FreeBASIC code, which is what [Compatibility](Compatibility) is about.

**Is tiko a fork of another compiler?**
No. It is a separate compiler with its own frontend, its own typed IR and an LLVM backend. See [What Is tiko](What-Is-tiko-lang).

**Will my existing FreeBASIC code compile?**
If it is `#lang "fb"` code, that is the aim. The known exceptions are listed on [Compatibility](Compatibility). They include `qb`/`fblite`/`deprecated` dialect code and inline `ASM`, each refused with a diagnostic. Code that must know it is being built by tiko tests `#ifdef __TIKO_COMPILER__`.

**Do I have to build anything?**
Normally not. Toolchains are published ready-built as GitHub [Releases](https://github.com/PaulSquires/tiko-lang/releases) -- the newest one titled *tiko toolchains* -- with one archive per host: `tiko-windows-x86_64-<commit>.zip`, `tiko-linux-x86_64-<commit>.tar.gz`, `tiko-linux-arm64-<commit>.tar.gz` and `tiko-macos-arm64-<commit>.tar.gz`. Unpack the one for your host -- it holds one directory, `tiko-lang/`, with the compiler and the tkEdit editor -- and it is ready; the only other thing it needs is clang, to run (see *Which backends?* below). Building tiko from its source is for working on the compiler itself: `bash build/package.sh --verify` builds a toolchain for your host, compiling tiko with the seed -- the earlier tiko release `sh seed/fetch-seed.sh` fetches. See [Quick Start](Quick-Start).

**Which targets are supported?**
- `windows-x86_64`: the default on Windows, and it needs no Visual Studio.
- `linux-x86_64`: the default on x86-64 Linux.
- `linux-arm64`: the default on arm64 (aarch64) Linux, with glibc 2.35 or newer.
- `macos-arm64`: the default on macOS (Apple Silicon, macOS 13 or newer). Programs for it link on a Mac, because the link needs Apple's linker and SDK; elsewhere `-c` compiles an object.

ARM64 means Linux and macOS: there is no Windows ARM64 target. `-m32` and `-target win32` are refused.

**Which backends?**
One: tiko emits LLVM IR and runs clang. There is no `-gen` switch. clang 18 or newer must be installed; tiko takes `TIKO_CLANG` first, then the default install path, then `clang` on `PATH`. See [LLVM Backend](Category-LLVM-Backend).

**Can I use inline `ASM`?**
Not in tiko. It is refused with `TKO0407` rather than miscompiled.

**Are generics macros?**
No. tiko builds one concrete type per distinct type-argument list, checked like any other type. See [Generics](Category-Generics).

**Can I put constraints on a type parameter?**
No. The language has none. This is why `IndexOf`/`Contains` and the whole sort library are free procedures rather than `Array` members.

**Do the containers get special compiler treatment?**
None at all. `Array`, `Map`, `Set`, `LinkedList`, `OrderedMap` and `OrderedSet` are ordinary library code, written on top of generics, the iterator protocol and `for each`.

**What does a type need to be usable with `FOR EACH`?**
`GetIterator( )` returning something with `IsValid( )`, `Value( )` and `MoveNext( )`. That is the whole contract — structural, with no base class, interface or registration. See [Iterator Protocol](Category-Iterators).

**Why `USTRING` when `WSTRING` exists?**
- `WSTRING` is 2 bytes on Windows and 4 on Linux and macOS. It is fixed-length, and appending walks to the terminator, which is O(n²).
- `USTRING` is dynamic and UTF-16 on every target. It keeps its length in the descriptor, so `LEN` is O(1) and appending is amortised O(1).
- Conversion to and from `STRING` is UTF-8 on every target, instead of going through the C locale.

**Does the new date/time library replace `datetime.bi`?**
No. `std/chrono` ships alongside it, and the two meet at `FromSerial` / `Serial`.

**Are goroutines as cheap as Go's?**
No. `spawn` copies the call's arguments at the spawn point and queues the call for a pool of operating-system worker threads: tiko-rt's scheduler, `lib/rt/src/thread/sched.tiko`. No green threads run underneath.

**Where do I report a bug or send a patch?**
<https://github.com/PaulSquires/tiko-lang/issues>

**Where does the language reference in this wiki come from?**
The keyword, statement, operator and function pages are the FreeBASIC 1.20.0 manual, reproduced under the GNU Free Documentation License 1.3, and they describe the dialect tiko compiles. tiko's own pages are written for this wiki. See [License](License).
