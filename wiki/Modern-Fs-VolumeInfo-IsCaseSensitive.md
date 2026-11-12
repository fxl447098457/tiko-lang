[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **VolumeInfo.IsCaseSensitive**

# VolumeInfo.IsCaseSensitive

Returns true if names on this volume are case-sensitive.

## Syntax

```freebasic
VolumeInfo.IsCaseSensitive
```

## Examples

```freebasic
#import "std/fs"
using fs

dim v as VolumeInfo = GetVolumeInfo( "." ).Value( )

print v.IsCaseSensitive      '' false on a plain NTFS volume

'' PER-VOLUME, and deliberately NOT the same question as
'' PathIsCaseSensitive( ), which is a compile-time per-platform
'' constant. They disagree in two real cases: an NTFS directory with
'' per-directory case sensitivity enabled -- WSL sets this -- and a
'' case-insensitive filesystem mounted on Linux or, by default, on macOS.
''
'' PathIsCaseSensitive for LEXICAL comparison, which must be
'' deterministic and do no IO. This one for "will these two names
'' collide on this disk". The wrong choice is a bug that only appears on
'' someone else's machine.
print PathIsCaseSensitive( )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Volumes
