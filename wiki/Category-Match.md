[Home](Home) › [All Categories](Categories) › **Match**

# Match

```freebasic
match l                                     ' a statement: 'case' arms, any body
    case Red   : Stop( )
    case Amber : SlowDown( )
    case Green : Go( )
end match

dim as ustring label = match code           ' a value: 'pattern => value' arms
    200        => "OK"
    301, 302   => "Redirect"
    400 to 499 => "Client error"
    else       => "Unknown"
end match
```

## Why It Exists

`select case` does not check that every case is handled, cannot produce a value, and cannot take
a tuple or a UDT apart. Add a member to an enum and every `select case` that forgot it still
compiles. `match` refuses to compile until every value of its subject is handled, and it binds the
parts of the value it matched.

`select case` is unchanged, and stays the branch that does not have to be exhaustive.

## The Two Forms

| | Statement | Value |
|---|---|---|
| Where | at the start of a statement | anywhere a value is expected |
| Arm | `case pattern [if guard]`, then a body of any length | `pattern [if guard] => value`, one line |
| Catch-all | `case else` | `else => value` |

`case` arms in a `match` used as a value are TKO1242; `=>` arms in a `match` statement are TKO1243.
`else` must be the last arm (TKO1244) and takes no guard (TKO1249).

## Patterns

| Pattern | Matches | Binds |
|---|---|---|
| `v` | the subject `= v` (any expression; strings compare as strings) | — |
| `a to b` | `a <= subject <= b` | — |
| `is <relop> v` | `subject <relop> v` | — |
| `p1, p2` | either (top level only) | nothing (TKO1248) |
| `any` | anything | — |
| `( p1, p2 )` | a tuple, element by element | what the elements bind |
| `Name( p1, p2 )` | a UDT of type `Name`, field by field in declaration order | what the fields bind |
| `x as Circle` | a `Shape ptr` that is not null and points at a `Circle` | `x`, a `Circle ptr` |
| `any as Circle` | the same, binding nothing | — |
| `starts "pre" rest` | a string that begins with `"pre"` | `rest`, the remainder |

```freebasic
match p
    case Point( 0, 0 )           : print "origin"
    case Point( x, y ) if x = y  : print "diagonal"; x
    case Point( x, y )           : print x; ","; y
end match

dim as double area = match shape            ' shape as Shape ptr
    c as Circle => 3.14159 * c->r ^ 2
    r as Rect   => r->w * r->h
    else        => 0
end match

match ( isAdmin, isOwner )
    case ( true,  any   ) : Allow( )
    case ( false, true  ) : AllowOwnOnly( )
    case ( false, false ) : Deny( )
end match

match cmd
    case "quit", "exit"      : running = false
    case starts "load " rest : Load( rest )
    case else                : print "unknown: "; cmd
end match
```

### A Bare Name

At the top level a bare name is a **value**, as in `select case`: `case Red` compares. Inside a tuple
or UDT pattern a bare name **binds**: `Point( x, 0 )` binds `x`. To compare against a constant there,
qualify it (`Point( Limits.MaxX, y )`) or use a guard. `true`, `false` and `nullptr` are always values.

### A Call Is Not A Pattern

`Name( ... )` is always a UDT pattern. To compare against what a call returns, write `is = F( x )`.

## Guards

`pattern if cond` matches only when `cond` holds; a failed guard tries the next arm. The names the
pattern binds are visible in the guard. A guarded arm counts for nothing in the exhaustiveness check.

## Exhaustiveness

A `match` that leaves a value unhandled is TKO1250, and the message names one:

```
error TKO1250: 'match' is not exhaustive: green is not handled
error TKO1250: 'match' is not exhaustive: (FALSE, FALSE) is not handled
error TKO1250: 'match' is not exhaustive: any other value is not handled
```

- **boolean**: `true` and `false`.
- **a named enum**: its members' **values** (two members with one value are one case). An anonymous enum
  needs `else`.
- **a tuple or UDT**: every combination of its elements' or fields' cases.
- **everything else** — integers, floats, strings, pointers, type patterns: only `else`, `any` or a
  binding covers it.

A value pattern that is not `true`, `false`, an enum member or an integer equal to one is matched at
run time but covers nothing. An arm the arms above it already cover is warning TKO1251.

## Evaluation

- The subject is evaluated **once**, into a copy. Bindings alias that copy: writing to one does not
  change the original. (`starts`' remainder is its own string.)
- Arms are tried top to bottom; the first whose pattern and guard both hold runs. There is no
  fallthrough and no `exit match`.
- **A `match` used as a value evaluates its subject before the statement that contains it.** That is
  invisible unless the subject has side effects and sits where it would not otherwise have run:
  `x andalso match F( ) ...` calls `F` whatever `x` is. For the same reason a `match` expression is
  refused (TKO1245) as a `while` / `do` / `loop` condition and in a declaration.
- An enum variable can hold a value no member has. The check cannot see that: a `match` statement runs
  no arm for it, and a `match` used as a value gives its last arm's value.

## 'match' IS A CONTEXTUAL KEYWORD

`match` is the keyword only when a subject follows it to the end of the line, the next line is an arm,
and an `end match` closes it. Everywhere else it is the name it is in FreeBASIC: `dim match`,
`match = 3`, `sub match`, `match( 21 )`, a label `match:`, and `end match` as `END` with an exit code.
A paren-less call `match 10` inside a `select case` arm keeps its meaning too: the `end select` comes
before any `end match`.

## Diagnostics

| Id | |
|---|---|
| TKO1240 | a `match` with no arms |
| TKO1241 | no `end match` before the end of the procedure or file |
| TKO1242 / 1243 | the other form's arms |
| TKO1244 | `else` that is not the last arm |
| TKO1245 | a `match` expression as a loop condition or in a declaration |
| TKO1246 | a malformed pattern |
| TKO1247 | a name bound twice in one pattern |
| TKO1248 | a pattern list that binds |
| TKO1249 | a guard on `else` |
| TKO1250 | not exhaustive |
| TKO1251 | an arm that can never run (warning) |
| TKO1252 | `Name( ... )` over a subject of another type |
| TKO1253 | the wrong number of fields |
| TKO1254 | a type pattern over something that is not a pointer to a class |
| TKO1255 | `starts` over something that is not a string |
| TKO1256 | a binding in a `match` used as a value that hides a constant (warning) |
| TKO1257 | a tuple pattern over something that is not a tuple |

## Known Limits

- A pattern that does not fit its subject also draws the errors of the code it is rewritten into
  (`'mid' takes a string` beside TKO1255, for instance).
- No `match` expression in an `elseif` condition or a `case` value.
- No `exit match`.
- Sum types, which `match` will take apart when they exist, are a separate step (docs/tiko-comparison
  RFC-0001-match §8.1).

## Implementation

`src/parser/match.tiko` rewrites a `match` in the token buffer, before the parser reads it, into
`scope`, `var`, `if` and `iif` — as `property` get/set blocks are rewritten. A UDT's *k*th field is
reached through `__tko_pos<k>`, which Check's member lookup answers. What needs types is left as a
record on the AST arena and judged by `src/symbols/semmatch.tiko`.

## Tests

`tests/codegen/match-patterns-run`, `match-eval-run`, `match-contextual-run`,
`match-contextual-var-run`; `tests/diagnostics/match-shape`, `match-types`, `match-unclosed`.

---

[Home](Home) · [Keyword Index](Keyword-Index)
