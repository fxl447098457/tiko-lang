[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_LINUX__**

# __FB_LINUX__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_LINUX__
```

## Description

Define without a value, created when compiling for Linux: the `linux-x86_64` and `linux-arm64` targets, the default on Linux, or *[-target linux-x86_64](Compiler-Option-Target)* and *[-target linux-arm64](Compiler-Option-Target)* on any host. It can be used to compile parts of the program only if the target is Linux.

## Remarks

[`TIKO_OS_LINUX`](Category-Tiko-Compiler-Define) is tiko's own name for the same test; tiko code uses it.

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_DOS__`](Fb-Dos)
- [`__FB_WIN32__`](Fb-Win32)
- [`__FB_UNIX__`](Fb-Unix)
- [`__FB_DARWIN__`](Fb-Darwin)
- [`TIKO_OS_LINUX`](Category-Tiko-Compiler-Define)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_LINUX__

  ' ... instructions only for Linux ...

  ' ... #libpath "/usr/X11/lib"

#else

  ' ... instructions not for Linux ...

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
