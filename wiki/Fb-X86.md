[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_X86__**

# __FB_X86__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_X86__
```

## Description

Define created at compile time if the compilation target uses the X86 or X86_64 CPU architecture, otherwise undefined.

## Remarks

In tiko, [`TIKO_ARCH_X86_64`](Category-Tiko-Compiler-Define) is tiko's own name for the same test (`windows-x86_64` and `linux-x86_64`); tiko code uses it.

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_ARM__`](Fb-Arm)
- [`TIKO_ARCH_X86_64`](Category-Tiko-Compiler-Define)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_X86__

  '...instructions for X86 OSes...

#else

  '...instructions for other OSes

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
