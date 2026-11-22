# Libraries

Four libraries cover jobs most programs end up doing. **`std/logs`** records
what a program did, with levels, typed fields and several destinations.
**`std/tui`** draws full-screen terminal interfaces. **`vendor/sqlite3`** puts
the SQLite database an `#import` away, and **`vendor/pcre2`** does the same
for PCRE2's regular expressions. This first example is the shortest useful
log.

```tiko
{{#include ../../examples/libraries/overview.tiko}}
```

**Output**

```text
{{#include ../../examples/libraries/overview.out}}
```

`logs.LogInit` connects the program's **default logger** to a sink and sets its
level; after that, `logs.LogInfo` and its siblings can be called from anywhere.
The debug message is dropped because `LOG_DEBUG` is below the `LOG_INFO`
level the logger was given. `logs.LogShutdown( )` flushes and closes the sinks
at the end.

A `ConsoleSink` normally writes to **stderr**, because logs are diagnostics and
must not mix into output that is piped to another program, and each line
normally starts with the time. The examples in this section send their logs to
stdout without a timestamp, so that the output is the same on every run.

The pages that follow:

- [Logging](logging.md): your own `Logger`, levels, fields and child loggers.
- [The default logger](default-logger.md): the logging macros.
- [Terminal UI](tui.md) and [Layout and widgets](tui-layout.md).
- [SQLite](sqlite.md) and [Prepared statements](sqlite-bind.md).
- [Regular expressions](pcre2.md) and [Search and replace](pcre2-replace.md).

### Activities

1. Change the level passed to `LogInit` to `logs.LOG_DEBUG`.
2. Remove `tr.stamp = logs.TS_NONE` and run the program twice.
