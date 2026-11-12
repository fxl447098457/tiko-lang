[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_WIN32__**

# __FB_WIN32__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_WIN32__
```

## Description

Define without a value created at compile time if compiling to the Win (32-bit or 64-bit) target. Default in Win hosted version, or active if the *[-target win32](Compiler-Option-Target)* or *[-target win64](Compiler-Option-Target)* command line option is used. It can be used to compile parts of the program only if the target is Win.

## Remarks

> **In tiko:** the define itself is unchanged — it still names the *operating system*, not the word size, and is set for the Windows target, `windows-x86_64`. There is no `-target win32`: tiko is x86-64 only. See [Compatibility](Compatibility).

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_DOS__`](Fb-Dos)
- [`__FB_LINUX__`](Fb-Linux)
- [`__FB_DARWIN__`](Fb-Darwin)
- [`__FB_PCOS__`](Fb-Pcos)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_WIN32__

  ' ... instructions only for Win ...

  ' ... GetProcAddress ...

#else

  ' ... instructions not for Win ...

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
