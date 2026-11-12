[Home](Home) › [Filesystem](Category-Filesystem) › [File Streams](Category-File-Streams) › **File.SyncData**

# File.SyncData

Forces the file's data onto the disk; can be cheaper than Sync on Linux.

## Syntax

```freebasic
File.SyncData( )
```

## Notes

- The data only (fdatasync), which can be cheaper on POSIX. The same as Sync on Windows. On macOS it is F_FULLFSYNC, which also flushes the drive's own cache.

## Examples

```freebasic
#import "std/fs"
using fs

dim as ustring dir_ = CreateTempDir( "tkdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
dim as File f
f.Create( p )
f.WriteUtf8( "data" )
print f.SyncData( ).IsOk( )    '' true
f.Close( )

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [File Streams](Category-File-Streams)
**Documented under:** Files
