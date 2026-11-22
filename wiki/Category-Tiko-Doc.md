[Home](Home) › [All Categories](Categories) › [tiko build](Category-Tiko-Build) › **tiko doc**

# tiko doc

```
> tiko doc
doc: 3 modules -> out/doc/index.html
```

`tiko doc` writes the API documentation of a project's modules: a Markdown page and an HTML page per module, an index with a search, and `doc.json` for tools. What it documents is what an importer sees -- the module's public names, with the signatures the compiler resolved -- and the words are the comments written above them.

## Writing documentation

```freebasic
#module "geo"
'' geo: shapes and their areas.
''
''     #import "shapes/geo"
''     print geo.Area( geo.Square( 2 ) )
''
'' Every public name below is documented by the comment above it.

'' A shape: a kind and its size.
public type Shape
    '' how many sides; 0 for a circle
    as long sides
    as double size              '' the length of a side, or the radius
    '' Its perimeter, in units.
    declare function Perimeter( ) as double
end type

'' The area of a shape, in square units.
public declare function Area( byref s as Shape ) as double
```

- **A name's documentation is the block of comment lines directly above it.** A blank line ends a block, so a comment separated from the declaration by a blank line is not its documentation.
- **A declaration with no comment of its own** takes the one above its definition: `public declare function Area( ... )` with the comment above `function Area( ... )`.
- **A field** may also be documented by the comment at the end of its line.
- **The module's overview** is the first comment block after `#module` in the file named like the module (`geo/geo.tiko`); it is not taken as the first declaration's documentation as well.
- **Text is Markdown-ish**: a line indented four spaces past the quotes is code, `backticks` are code, `- ` starts a list item, a blank comment line (`''` alone) starts a paragraph. Divider lines (`'' -----`, `'' =====`) are dropped.
- **Overloads are one entry** with each signature, documented by the first comment found.
- `''` and `'` comments both work. `/' ... '/` block comments are not read.

What is documented: every `public` procedure, type, class, union, interface, enum, constant, `dim shared` and type alias at the top level of the module or in its namespaces; a public type's `public` and `protected` members (fields, constructors, methods, properties, operators); a generic's header (not its body); and each macro the module `#export`s. A module-private or `private` name, a type's `private:` members, and the module's `*_test.tiko` files are never part of it.

## Running it

```
tiko doc [<dirs>...] [-o <dir>] [--manifest <path>] [-target <t>] [--message-format json]
```

| | |
|---|---|
| *(no words)* | every module of the project: under the `tiko.toml`'s directory, else the current one |
| `<dir>` | that module, or every module under that directory |
| `-o <dir>` | where the pages go; `out/doc` beside the `tiko.toml` (else in the current directory) unless given |

`tiko doc pkg/std/strings -o docs/std` documents a toolchain module the same way.

Each module is built as a program that imports it builds it, through the module cache, so documenting an unchanged project compiles nothing.

## What it writes

| File | |
|---|---|
| `<chain>.md` | the module's page in Markdown: its import line (the package path, `#import "shapes/geo"`, which works from anywhere -- a file of the same package included), its overview, the contents, then each item with its signatures, its documentation, its members and where it is defined |
| `<chain>.html` | the same as a web page, light or dark with the system, with the search box |
| `index.md`, `index.html` | every module, with its import line and the first sentence of its overview |
| `search.js` | every name, for the search box -- a script rather than JSON, so the search works on pages opened from the disk |
| `doc.json` | everything, for tools: `{"format":1,"generator":"tiko 0.1.6","modules":[...]}` |

`<chain>` is the module's package path with dots: `std.strings`, `myapp.src.util`.

### doc.json

```
{"format":1,"generator":"tiko 0.1.6","modules":[
  {"chain":"std.strings","import":"std/strings","name":"strings","files":["csv.tiko", ...],
   "summary":"...","doc":"<the overview>",
   "items":[
     {"kind":"function","name":"Tally","namespace":"","qualified":"strings.Tally","anchor":"tally",
      "summary":"...","doc":"...",
      "signatures":[{"text":"function Tally( ... ) as long","file":"string.tiko","line":120}],
      "members":[]} ]} ]}
```

`kind` is `function`, `sub`, `operator`, `property`, `type`, `class`, `union`, `interface`, `enum`, `const`, `variable`, `alias` or `macro`. A member's `kind` is `field`, `method`, `property`, `constructor`, `destructor`, `operator`, `const` or `value` (an enum's), with `visibility` `public` or `protected`.

With `--message-format json`, each module is `{"event":"doc","dir":...,"exit":0}` and the end is `{"event":"doc-end","modules":N,"path":...,"exit":0}`.

## Diagnostics

| Id | When |
|---|---|
| `TKO1207` | `--emit-doc` (the compiler mode `tiko doc` runs per module) without one module directory |
| `TKO1208` | a page that cannot be written |
| `TKO1209` | (warning) no module directories to document |
| `TKO1210` | a word that is not a directory |

## Not yet

- Code examples in documentation comments are not compiled or run.
- `/' ... '/` comments.
- A program's main file is not documented: only modules are.
