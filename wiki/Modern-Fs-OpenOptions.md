[Home](Home) › [Filesystem](Category-Filesystem) › [File Streams](Category-File-Streams) › **OpenOptions**

# OpenOptions

Holds the flags that say how File.Open opens a file: read, write, create, share and more.

## Syntax

```freebasic
type OpenOptions
    as boolean Read, Write, Append, Truncate, Create, CreateNew
    as boolean ShareRead, ShareWrite, ShareDelete    '' TRUE -- Windows only
    as boolean Inheritable                           '' FALSE
    as boolean NoFollow                              '' FALSE
    as ulong   PosixMode                             '' &o666 -- POSIX only
end type
```

## Notes

- Everything defaults FALSE except the three share flags, which default TRUE so a file open in one program can still be read, written, renamed and deleted by others, as on Linux and macOS.
- Append implies Write and puts every write at the end. Truncate requires Write and cannot be combined with Append. Create and CreateNew need Write or Append. CreateNew fails FS_ALREADY_EXISTS if the file is there, atomically, and ignores Create and Truncate. Read alone, Write alone or both is the access mode. A combination outside these rules is FS_INVALID_ARGUMENT, before anything is opened.
- Inheritable FALSE means a child process started later does not get the handle.
- NoFollow fails with FS_LOOP when the last component of the path is a symbolic link.
- OpenOptionsRead( ), OpenOptionsWrite( ) (Write + Create + Truncate) and OpenOptionsAppend( ) (Append + Create) are the common sets.

## Examples

```freebasic
#import "std/fs"
using fs

dim as ustring dir_ = CreateTempDir( "tkdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
dim as OpenOptions o
o.Read = true
o.Write = true
o.Create = true
dim as File f
print f.Open( p, o ).IsOk( )              '' true
f.Close( )

dim as OpenOptions bad
bad.Read = true
bad.Truncate = true                       '' Truncate needs Write
print f.Open( p, bad ).Failure( ).Message( )    '' invalid argument

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [File Streams](Category-File-Streams)
**Documented under:** Files
