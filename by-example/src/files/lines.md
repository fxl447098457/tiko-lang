# Line by line

A `File` is an open file. It is opened in place, by a method, and it **closes
itself** when it goes out of scope. A `TextWriter` writes lines to it, and
`ReadLines` reads a file back one line at a time.

```tiko
{{#include ../../examples/files/lines.tiko}}
```

**Output**

```text
{{#include ../../examples/files/lines.out}}
```

`Create` makes the file, or empties one that is there. `OpenAppend` keeps what
is there and writes at the end. Each `scope` is where its `File` ends: the
`TextWriter`, declared after the `File`, is destroyed first, then the `File`
closes its handle.

`WriteLine` ends a line the way the platform does: carriage return and line
feed on Windows, line feed on Linux and macOS. Set the writer's `NewLine` to `chr( 10 )`
to write the same bytes everywhere.

`for each ln in fs.ReadLines( p )` opens the file, yields one
`Result( of ustring, FsError )` per line and closes the file at the end, or as
soon as the loop is left with `exit for`. Only one line is in memory at a
time, so it reads a file of any size. If the file cannot be opened, the
failure is the first and only element.

A `File` cannot be copied. Pass it to a procedure `byref`.

### Activities

1. Stop the loop with `exit for` after the second line.
2. Read a file that does not exist and print what the one element says.
