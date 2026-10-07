---
name: perf
description: Flags algorithmic and I/O performance anti-patterns in the diff.
severity-default: medium
---

Look for:

- **N+1 queries / requests** — a database call, HTTP request, or file read
  inside a loop that could be batched. The single highest-value finding in this
  check.
- **Accidental O(n²)** — nested loops over the same collection, `includes` /
  `indexOf` / `in list` inside a loop where a set or map would be O(1),
  repeated linear scans of the same data.
- **Work repeated inside a loop** — sorting, compiling a regex, opening a
  connection, or recomputing an invariant on every iteration.
- **Loading everything into memory** — reading a whole file or table when the
  code only streams over it once.
- **Blocking the event loop / holding a lock** — synchronous I/O or CPU-heavy
  work in an async path or inside a critical section.
- **String concatenation in a loop** — where the language makes that quadratic.

Report the line, the input size at which it starts to matter, and the fix.

Only report what the diff introduces or makes measurably worse. Do not report
theoretical inefficiency on data that is bounded and small — say the bound and
move on. `n` is 5 and always will be is not a finding.

Raise to `high` for anything in a request path or a hot loop with unbounded
input. Lower to `low` for startup or one-shot script code.
