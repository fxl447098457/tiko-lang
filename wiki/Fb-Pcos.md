[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_PCOS__**

# __FB_PCOS__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_PCOS__
```

## Description

Define created at compile time if the OS has filesystem behavior styled like common PC OSes, e.g. DOS, Windows, OS/2, Symbian OS, possibly others. Drive letters, backslashes, that stuff, otherwise undefined.

## Remarks

In tiko only `windows-x86_64` is a PC OS, so tiko code tests [`TIKO_OS_WINDOWS`](Category-Tiko-Compiler-Define) instead.

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_WIN32__`](Fb-Win32)
- [`__FB_DOS__`](Fb-Dos)
- [`__FB_XBOX__`](Fb-Xbox)
- [`__FB_UNIX__`](Fb-Unix)
- [`TIKO_OS_WINDOWS`](Category-Tiko-Compiler-Define)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_PCOS__

  '...instructions for PC-ish OSes...

#else

  '...instructions for other OSes

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
