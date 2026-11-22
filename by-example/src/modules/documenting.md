# Documenting a module

`tiko doc` writes a module's documentation from the comments above its public
names: a page per module in Markdown and HTML, an index with a search box, and
`doc.json` for tools.

````admonish warning title="Status in this version"
`tiko doc` arrives after tiko 0.1.6, the toolchain this site is pinned to.
This example was compiled and run on Windows with the development toolchain.
````

A module, `money/money.tiko`, in a project whose `tiko.toml` names the package
`shop`:

```tiko
{{#include ../../examples/modules/documented/money/money.tiko}}
```

`tiko doc` in the project's directory, and the page it writes,
`out/doc/shop.money.md`:

**Output**

```text
{{#include ../../examples/modules/documented/main.out}}
```

- **The `''` lines directly above a public name document it.** A blank line
  ends the block.
- **A declaration with no comment** takes the one above its definition.
- **A field** may be documented at the end of its line, as `cents` is.
- **The overview** is the first comment block after `#module`, in the file
  named like the module. Indented lines in it are code.
- **Only public names appear**, with the signatures the compiler resolved, and
  the import line that works from anywhere: `#import "shop/money"`.

`tiko doc` documents every module of the project into `out/doc/`;
`tiko doc money` documents one, and `-o` names another directory. Open
`out/doc/index.html` to browse the pages and search them.

### Activities

1. Add a module-private helper to `money.tiko`, with a comment, and confirm it
   does not appear in the page.
