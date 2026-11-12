[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **PathIsCaseSensitive**

# PathIsCaseSensitive

Returns true if paths compare case-sensitively here: on Linux and macOS, not Windows.

## Syntax

```freebasic
PathIsCaseSensitive( )
```

## Notes

- compile-time, per platform -- NOT per volume

## Examples

```freebasic
#import "std/fs"
using fs

'' COMPILE-TIME, PER PLATFORM -- not per volume. It answers what the
'' grammar assumes, not what the file system in front of you does.
print PathIsCaseSensitive( )             '' false on Windows

print PathIsCaseSensitive( FB_PATH_POSIX )       '' true
print PathIsCaseSensitive( FB_PATH_WIN32 )       '' false

'' A case-sensitive volume mounted on Windows, or a case-insensitive one
'' on Linux or macOS, is not visible here. VolumeInfo.IsCaseSensitive asks the
'' actual volume.
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Paths
