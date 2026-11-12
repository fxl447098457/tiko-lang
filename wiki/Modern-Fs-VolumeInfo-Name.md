[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **VolumeInfo.Name**

# VolumeInfo.Name

Returns the volume's label, which may be empty and always is on Linux and macOS.

## Syntax

```freebasic
VolumeInfo.Name
```

## Examples

```freebasic
#import "std/fs"
using fs

dim v as VolumeInfo = GetVolumeInfo( "." ).Value( )

'' THE LABEL, AND IT MAY BE EMPTY -- always is on Linux, where reading
'' one portably would mean linking blkid, and often is for a network
'' share on Windows. Never assert on it; print it only as decoration.
print len( v.Name ) >= 0     '' -1 (true)
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Volumes
