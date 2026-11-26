# Profiles

The `debug` in `out/debug` is the project's **profile**: a named set of
compiler options. `tiko build` and `tiko run` use `debug` unless told
otherwise, and `--profile` chooses another. This program reports what its
profile gave it:

```toml
{{#include ../../examples/building/profiles/tiko.toml}}
```

```tiko
{{#include ../../examples/building/profiles/main.tiko}}
```

Built with `tiko build`, the default profile:

**Output**

```text
{{#include ../../examples/building/profiles/main.out}}
```

The other two profiles, built and run the same way, print:

```text
> tiko build --profile release
this build:
debug information:   false
error checks:        false
optimisation level:   2
thread-safe runtime: false
> tiko build --profile fast
this build:
debug information:   false
error checks:        false
optimisation level:   2
thread-safe runtime: true
```

| Profile | Options |
|---|---|
| `debug` | `-g -exx -O0`: a [checked build](checked.md), with debug information |
| `release` | `-O2` |

Both are built in. A `[profile.name]` table changes one or declares another:

| Key | Sets |
|---|---|
| `inherits` | the profile this one starts from |
| `opt` | the optimisation level, `0` to `3`, or `"s"` for size |
| `errors` | the checks: `"e"`, `"ex"`, `"exx"`, or `""` for none |
| `debug` | whether `-g` is given |
| `options` | further compiler options |

Each profile writes to its own directory, `out/debug`, `out/release`,
`out/fast`, so a debug build and a release build of the same project sit side
by side. Each profile's compiled files are cached separately, so switching
back to a profile does not compile again what it compiled before.

### Activities

1. Add a profile `checked` that inherits `release` and sets
   `errors = "exx"`, and build with it.
2. Run `tiko run --profile release` and find the program it ran.
