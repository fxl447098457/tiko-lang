# Flow of Control

A program runs its statements from top to bottom until something changes
that order. tiko has two families of statement that do: ones that **choose**
which block runs (`if`, `select case`, `match`) and ones that **repeat** a block
(`for`, `do ... loop`, `for each`). This program uses one of each:

```tiko
{{#include ../../examples/flow/flow.tiko}}
```

**Output**

```text
{{#include ../../examples/flow/flow.out}}
```

Every block statement ends with a matching keyword: `end if`, `end select`,
`next` for a `for`, `loop` for a `do`. Conditions need no parentheses, and the
body of a block is not limited to one statement.

| Statement | Use it to | Page |
|---|---|---|
| `if` / `elseif` / `else` | choose between a few conditions | [if/else](if.md) |
| `select case` | compare one value against many cases | [select case](select.md) |
| `match` | compare one value against patterns, every case handled | [match](match.md) |
| `for ... next` | count through a range | [for](for.md) |
| `do ... loop` | repeat while (or until) a condition holds | [do loop](do.md) |
| `exit` / `continue` | leave a loop, or skip to its next pass | [exit and continue](exit.md) |
| `for each` | visit every element of an array | [for each](foreach.md) |
| `defer` | run a statement when a block is left | [defer](defer.md) |

### Activities

1. Change the first loop so that it adds up the even numbers instead.
2. Make the `do` loop find the first cube over 500.
