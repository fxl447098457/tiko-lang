# Security policy

## Reporting a vulnerability

Please report a security problem in tiko privately, not in a public issue or discussion.
Use GitHub's private reporting: on this repository's **Security** tab, choose
**Report a vulnerability**. Only the maintainer sees the report.

Please include:

- the tiko version (`tiko --version`) and the platform,
- what an attacker controls: a source file being compiled, a program's input, a file or
  network peer the program reads,
- the smallest program or input that shows it, and what happens.

A confirmed problem is fixed in the next release.

## What is in scope

- **The compiler**: compiling a file must not run it. A source that makes the compiler write
  outside its build, run code, or crash with memory corruption is a vulnerability. That
  includes doing so through `#cmdline`, `#include`, `#inclib`, `#cinclude` or the module cache.
- **The runtime and `pkg/std`**: memory safety, and anything that weakens TLS, HTTP, URL,
  randomness, process or file-system behaviour that a program relies on for safety.
- **Bundled libraries** in `pkg/vendor`: a known advisory that affects the pinned version.

To compile a source you do not trust, pass `-z nocmdline`, so the file cannot choose its own
compiler options.

## Supported versions

tiko is pre-1.0. Only the latest release gets fixes.
