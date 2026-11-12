[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **DirEntry.Info**

# DirEntry.Info

Returns the entry's FileInfo: free on Windows, one extra system call on Linux and macOS.

## Syntax

```freebasic
DirEntry.Info( )
```

## Notes

- FsResultInfo -- MAY cost a stat

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
WriteAllText( PathJoin( dir_, "a.txt" ), "aaa" )
WriteAllText( PathJoin( dir_, "b.txt" ), "bb" )
CreateDir( PathJoin( dir_, "sub" ) )
WriteAllText( PathJoin( dir_, "sub", "c.txt" ), "c" )

'' The full FileInfo for this entry. MAY COST A STAT: free on Windows,
'' where the find record already carries size, times and attributes, but
'' dirent carries neither, so on POSIX this issues an lstat.
for each r in ReadDir( dir_ )
    if r.IsOk( ) then
        dim inf as FsResultInfo = r.Value( ).Info( )
        if inf.IsOk( ) then
            print r.Value( ).Name( ) & " " & inf.Value( ).Size( )
        end if
    end if
next                         '' a.txt 3 / b.txt 2 / sub <n>

'' It returns a Result because the entry may have been DELETED between
'' being enumerated and being stat'd

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Directories
