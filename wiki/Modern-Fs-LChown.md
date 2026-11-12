[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **LChown**

# LChown

Changes a symbolic link's own owner and group, on Linux and macOS only.

## Syntax

```freebasic
LChown( p, uid, gid )
```

## Notes

- Chown on a symbolic link itself, not what it points to. POSIX only.

## Examples

```freebasic
#import "std/fs"
#import "std/chrono"
using fs

dim as ustring dir_ = CreateTempDir( "tkdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "x" )
dim as FsResultBool r = LChown( p, -1, -1 )
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
