[Home](Home) › [Using C Libraries](Using-C-Libraries-Tutorial) › **SQLite**

# SQLite Tutorial

> 📘 **Start with:** [Using C Libraries](Using-C-Libraries-Tutorial), the ideas these steps rely on.
>
> 📖 **In the book:** [Chapter 30, SQLite](https://tiko-lang.net/book/ch30-c-libraries.html#sqlite). Measured with SQLite 3.54.0 and tiko, on Windows and Linux.

[SQLite](https://sqlite.org) is a complete SQL database in a library. There is no server, and a database is one ordinary file.

tiko ships SQLite 3.54.0 as a [vendor package](Vendor-Packages). One line gives a program SQLite's whole C API and links the library:

```freebasic
#import "vendor/sqlite3"
```

There is nothing to download, no header to translate, no `#foreignlib` and nothing on the command line, on Windows, Linux and macOS. More programs, from transactions to blobs and backups, are in the toolchain's `examples/sqlite3`.

---

## 1. The program, linked dynamically

This is SQLite's own *"SQLite In 5 Minutes Or Less"* program in tiko. It opens the database named by the first argument, runs the SQL in the second, and prints each row:

```freebasic
'' SQLite's "SQLite In 5 Minutes Or Less" program: run one SQL string
'' against a database and print each row the callback is given.
#import "vendor/sqlite3"

'' Called once for each row of the result.
function Callback cdecl( byval notUsed as any ptr, _
        byval argc as int32, byval argv as zstring ptr ptr, _
        byval colName as zstring ptr ptr ) as int32
    for i as int32 = 0 to argc - 1
        dim value as ustring = "NULL"
        if argv[i] <> nullptr then value = *argv[i]
        print *colName[i]; " = "; value
    next
    print
    return 0
end function

if command( 2 ) = "" then
    print "Usage: sqlite-quick DATABASE SQL-STATEMENT"
    end 1
end if

dim db as sqlite3 ptr
if sqlite3_open( command( 1 ), @db ) <> SQLITE_OK then
    print "Can't open database: "; *sqlite3_errmsg( db )
    sqlite3_close( db )
    end 1
end if

dim errMsg as zstring ptr
if sqlite3_exec( db, command( 2 ), @Callback, nullptr, @errMsg ) _
        <> SQLITE_OK then
    print "SQL error: "; *errMsg
    sqlite3_free( errMsg )
end if
sqlite3_close( db )
```

```bash
tiko sqlite-quick.tiko
./sqlite-quick :memory: "create table tbl1(one text, two int);
    insert into tbl1 values('hello!', 10);
    insert into tbl1 values('goodbye', 20);
    select * from tbl1"
```

```
one = hello!
two = 10

one = goodbye
two = 20
```

**What each part does:**

| Line | Why |
|---|---|
| `#import "vendor/sqlite3"` | every SQLite function, type and constant, unqualified, as SQLite documents them: `sqlite3_open`, `SQLITE_OK`. The header was translated once by [`tiko c2t`](C2t) and ships with the toolchain, so you write no `declare`s. With no `link`, SQLite is linked dynamically. |
| `function Callback cdecl( ... )` | `sqlite3_exec` calls it once per row, so it must be `cdecl` and match C's `int (*)(void*, int, char**, char**)` exactly |
| `dim db as sqlite3 ptr` / `@db` | `sqlite3` is opaque, so you only ever hold a pointer. C's `&db` is tiko's `@db`. |
| `*sqlite3_errmsg( db )` | a `const char *` from C; `*` copies the text into a tiko string |
| `sqlite3_free( errMsg )` | SQLite allocated the message, so SQLite frees it |

**The library is copied beside the program** when it is built: `sqlite3.dll` on Windows, `sqlite3_linux_x86_64.so` on Linux, `sqlite3_macos_arm64.dylib` on macOS. On Linux and macOS the program is linked with a run path to its own folder, so it finds that copy with no `LD_LIBRARY_PATH`, wherever it is run from. It does not pick up the system's own `libsqlite3.so.0` (Ubuntu ships an older SQLite): ask with `select sqlite_version()`, and it answers `3.54.0`.

## 2. Prepared statements, linked statically

Real programs **prepare** a statement once with `?` placeholders and **bind** values to them. That is faster, and it is safe from SQL injection. This program does that, and links SQLite statically:

```freebasic
'' Insert and query with prepared statements: the values travel as
'' parameters, never as text pasted into the SQL. Linked statically.
#import "vendor/sqlite3" link static

sub Check( byval rc as int32, byval db as sqlite3 ptr )
    if rc <> SQLITE_OK andalso rc <> SQLITE_DONE then
        print "SQLite error "; rc; ": "; *sqlite3_errmsg( db )
        end 1
    end if
end sub

print "SQLite "; *sqlite3_libversion( )

dim db as sqlite3 ptr
Check( sqlite3_open( ":memory:", @db ), db )
Check( sqlite3_exec( db, "create table city( name text, pop int )", _
    nullptr, nullptr, nullptr ), db )

dim names( 0 to 2 ) as string = _
    { "St. John's", "Gander", "Corner Brook" }
dim pops( 0 to 2 ) as int32 = { 110525, 11880, 19316 }

dim ins as sqlite3_stmt ptr
Check( sqlite3_prepare_v2( db, "insert into city values( ?, ? )", _
    -1, @ins, nullptr ), db )
for i as int32 = 0 to 2
    '' -1: the text ends at its zero byte. SQLITE_STATIC: the string
    '' outlives the statement's use of it, so SQLite need not copy it.
    Check( sqlite3_bind_text( ins, 1, names( i ), -1, SQLITE_STATIC ), db )
    Check( sqlite3_bind_int( ins, 2, pops( i ) ), db )
    Check( sqlite3_step( ins ), db )
    sqlite3_reset( ins )
next
sqlite3_finalize( ins )

dim sel as sqlite3_stmt ptr
Check( sqlite3_prepare_v2( db, _
    "select name, pop from city where pop > ? order by pop desc", _
    -1, @sel, nullptr ), db )
sqlite3_bind_int( sel, 1, 15000 )
do while sqlite3_step( sel ) = SQLITE_ROW
    print *cast( zstring ptr, sqlite3_column_text( sel, 0 ) ); ": "; _
        str( sqlite3_column_int( sel, 1 ) )
loop
sqlite3_finalize( sel )
sqlite3_close( db )
```

```bash
tiko sqlite-bind.tiko
./sqlite-bind
```

```
SQLite 3.54.0
St. John's: 110525
Corner Brook: 19316
```

Only the import differs from a dynamic program: `link static`. SQLite is then inside the program, which runs with nothing beside it: about 1.1 MB on Windows and 1.2 MB on Linux, compared with 40 KB plus a 3.5 MB DLL.

**Details worth knowing:**

- `sqlite3_bind_text`'s last argument says whether SQLite must copy the text. `SQLITE_STATIC` says the string outlives the statement, as here; `SQLITE_TRANSIENT` says copy it, for a string that goes away first. In C both are macros that cast a number to a function pointer; `vendor/sqlite3` has them as constants, so you write them as in C.
- `sqlite3_column_text` returns `const unsigned char *`, which tiko sees as `const ubyte ptr`. Cast it to `zstring ptr` to read it as text.
- The names are `string`, tiko's byte string, because SQLite's `_text` functions take UTF-8 bytes.

## 3. In a project

A [`tiko build`](Category-Tiko-Build) project needs nothing in its `tiko.toml` for SQLite: the import says it all. `tiko build`'s `copy_to` copies the shared library along with the program.

## 4. Shipping the program

- **Linked dynamically:** ship the library the build put beside the program (`sqlite3.dll`, `sqlite3_linux_x86_64.so` or `sqlite3_macos_arm64.dylib`).
- **Linked statically:** the program alone.

If `sqlite3.dll` is missing, the program exits at once with `-1073741515` and prints nothing. Windows also looks in the current directory, so test a copy from its own folder.

## 5. Your own SQLite build

Use this when you need a newer SQLite than the toolchain's, or SQLite built with compile options of your own. It replaces the import with the parts the vendor package does for you, and it is the pattern for every library that has no vendor package.

### Download

All files are on [sqlite.org/download.html](https://sqlite.org/download.html). The number in each file name is the version: 3.54.0 is `3540000`.

| File | Contains | You need it for |
|---|---|---|
| `sqlite-amalgamation-3540000.zip` | `sqlite3.c`, `sqlite3.h` (the whole library as **one C file**) | the header, on every platform; a static library on Windows |
| `sqlite-dll-win-x64-3540000.zip` | `sqlite3.dll`, `sqlite3.def` | the DLL, on Windows |
| `sqlite-autoconf-3540000.tar.gz` | `sqlite3.c`, `sqlite3.h` and a Unix build script | building on Linux |

The project keeps SQLite in `vendor/sqlite/`. Each library file carries its target in its name, so both platforms' files can share the folder:

```
myapp/
  sqlite-quick.tiko
  sqlite3.dll                                   (Windows: the DLL, beside the program)
  libsqlite3.so.0                               (Linux: the .so, beside the program)
  vendor/sqlite/
    sqlite3.h
    sqlite3_windows_x86_64.dll                  sqlite3.dll, renamed: tiko makes its import library
    sqlite3-static_windows_x86_64.lib           static library
    sqlite3_linux_x86_64.so                     shared library
    sqlite3-static_linux_x86_64.a               static library
```

### Lay it out: Windows

**The header.** Copy `sqlite3.h` from the amalgamation zip into `vendor/sqlite/`.

**For dynamic linking.** The DLL zip has `sqlite3.dll` and `sqlite3.def`, but **no import library**, and you don't need one. Copy `sqlite3.dll` to `vendor/sqlite/sqlite3_windows_x86_64.dll`, and again, unrenamed, beside your program. When `#foreignlib SQLITE dynamic "vendor/sqlite/sqlite3"` finds only the `.dll`, tiko reads the DLL's exports and makes the import library while linking. The import library names the DLL **as the DLL names itself**, `sqlite3.dll`, so the program loads the copy beside it.

To keep an import library in the project instead, make it with `llvm-dlltool`, and give it the DLL's name with `-D`:

```bash
llvm-dlltool -m i386:x86-64 -d sqlite3.def -D sqlite3.dll -l vendor/sqlite/sqlite3_windows_x86_64.lib
```

> ⚠️ **Without `-D`, the program cannot start.** `sqlite3.def` has no `LIBRARY` line, so an import library made without it records an **empty** DLL name. Everything links, and then the program dies on start with code `-1073741515`. Check with `llvm-readobj --coff-imports program.exe`: a `Name:` line with nothing after it is the problem.

**For static linking.** Compile the amalgamation and archive it. This needs the Visual Studio Build Tools, for the C runtime headers, and takes about 20 seconds (`sqlite3.c` is 9.6 MB of C):

```bash
clang -c -O2 -o sqlite3.obj sqlite3.c
llvm-lib /out:vendor/sqlite/sqlite3-static_windows_x86_64.lib sqlite3.obj
```

The static library is called `sqlite3-static` because on Windows a static `.lib` and an import `.lib` cannot share a name.

### Lay it out: Linux

From the autoconf archive (or the amalgamation, which has the same `sqlite3.c`):

```bash
cp sqlite3.h vendor/sqlite/
gcc -O2 -fPIC -c -o sqlite3.o sqlite3.c

# static
ar rcs vendor/sqlite/sqlite3-static_linux_x86_64.a sqlite3.o

# shared, with the soname the program will ask for when it starts
gcc -shared -Wl,-soname,libsqlite3.so.0 \
    -o vendor/sqlite/sqlite3_linux_x86_64.so sqlite3.o -lm
cp vendor/sqlite/sqlite3_linux_x86_64.so libsqlite3.so.0
```

`-fPIC` is needed for code that goes into a shared library. `-Wl,-soname,...` records the name the program will look for; without it, the program would remember the path it was linked with.

### The program

Replace the `#import` with SQLite's own header, read by `#cinclude`, and the library, linked by `#foreignlib`:

```freebasic
#cinclude once "vendor/sqlite/sqlite3.h"
#foreignlib SQLITE dynamic "vendor/sqlite/sqlite3"
```

or, statically:

```freebasic
#cinclude once "vendor/sqlite/sqlite3.h"
#foreignlib SQLITE static "vendor/sqlite/sqlite3-static"
```

Both paths are relative to **the file that holds them**, and `#foreignlib` picks the file that matches the target. Three things differ from the vendor package:

- **`SQLITE_STATIC` and `SQLITE_TRANSIENT` are not imported**, because `#cinclude` does not import a macro that casts a number to a function pointer. Write `nullptr` for `SQLITE_STATIC` and `cast( sqlite3_destructor_type, -1 )` for `SQLITE_TRANSIENT`.
- **On Linux, the program does not look beside itself.** Run it with `LD_LIBRARY_PATH=.`, or add `#cmdline "-Wl -rpath,$ORIGIN"` inside `#ifdef TIKO_OS_LINUX`.
- **On Linux, forgetting that may not fail.** The program asks for `libsqlite3.so.0`, and Ubuntu has its own installed; the program quietly uses that older version (3.45.1 on Ubuntu 24.04). Ask SQLite: `select sqlite_version()`.

**Installed for every program.** On Linux, `sudo apt install libsqlite3-dev` installs `sqlite3.h` and the library where they are found by default, and a program needs no paths: `#cinclude once "sqlite3.h"` and `#foreignlib SQLITE dynamic "system:sqlite3"`. That is the distribution's SQLite. On Windows, keep `vendor/sqlite/` in a shared folder and use a [binding header](Using-C-Libraries-Tutorial#5-a-binding-header).

## 6. Troubleshooting

| Problem | Fix |
|---|---|
| the program exits at once with `-1073741515` | `sqlite3.dll` is not beside the program (or, your own build, the import library was made without `-D sqlite3.dll`) |
| `TKO0336: unable to import C header vendor/sqlite/sqlite3.h` (your own build) | check the path; on Windows install the Visual Studio Build Tools |
| `TKO0329: #foreignlib found no matching library file` (your own build) | the file names in the list are what tiko looked for; rename yours to match |
| `TKO0172: cannot make an import library for '...': it is not a 64-bit x86-64 DLL` (your own build) | that is `sqlite-dll-win-x86`, the 32-bit download; take `win-x64` |
| `error while loading shared libraries: libsqlite3.so.0` (your own build) | `LD_LIBRARY_PATH=.`, an rpath of `$ORIGIN`, or install SQLite |
| wrong SQLite version reported on Linux (your own build) | the system's copy was loaded; see above |

---

**Next:** [PCRE2](PCRE2-Tutorial) · [raylib](Raylib-Tutorial) · [GLFW](GLFW-Tutorial) · [SDL3](SDL3-Tutorial) · [Vendor Packages](Vendor-Packages)

[Home](Home)
