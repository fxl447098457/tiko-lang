[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **Chown**

# Chown

Changes a file's owner and group on Linux and macOS, -1 keeping one; fails on Windows.

## Syntax

```freebasic
Chown( p, uid, gid )
```

## Notes

- Sets the owner of p (following a symbolic link). -1 leaves that id unchanged.
- POSIX only: FS_UNSUPPORTED on Windows. Giving a file to another user generally needs privilege (FS_ACCESS_DENIED).

## Examples

```freebasic
#import "std/fs"
#import "std/chrono"
using fs

dim as ustring dir_ = CreateTempDir( "tkdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "x" )
dim as FsResultBool r = Chown( p, -1, -1 )
#ifdef __FB_WIN32__
print r.Failure( ).Message( )    '' unsupported
#else
print r.IsOk( )                  '' true
#endif

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [Filesystem](Category-Filesystem)
**Documented under:** Metadata
