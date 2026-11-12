# Custom Types

The built-in types describe single values. Most data comes in groups and in
categories, and tiko has a declaration for each: a `type` (a record) groups
named fields, an `enum` names a set of related values, and a `const` names a
value that never changes.

```tiko
{{#include ../../examples/custom-types/overview.tiko}}
```

**Output**

```text
{{#include ../../examples/custom-types/overview.out}}
```

`StockItem` keeps a label, a category and a count together, so `Report` takes
one argument instead of three. Its `kind` field has the enum type `Category`,
whose members `Tools`, `Parts` and `Supplies` print as 0, 1 and 2.
`ReorderLevel` gives the number 5 a name, so the test reads as what it means.

The pages in this section take each part in turn:

- [Records](records.md): declaring fields, filling them, nesting one type in
  another, and copying.
- [with](with.md): naming a record once and reaching its fields with a dot.
- [Enums](enums.md): named integer constants.
- [Unions](unions.md): several views of the same bytes.
- [Constants](constants.md): `const`, with and without a type.
- [Partial Types](partial.md): one type written in several blocks.

Methods, constructors and operators on your own types are in
[Objects](../objects/index.md).

### Activities

1. Add a fourth item with a count of 0 and check that it is flagged.
2. Add a `Consumables` member to `Category` and use it for `tape`.
