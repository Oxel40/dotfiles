---
name: security
description: Flags security defects introduced or exposed by the diff.
severity-default: high
---

Look for:

- **Injection** — user input reaching SQL, shell, `eval`, template rendering, or
  a file path without parameterization or escaping. Check the whole path from
  input to sink, not just the line in the diff.
- **Missing authorization** — a new endpoint, handler, or mutation that does not
  check who is calling it. Compare against how sibling handlers do it.
- **Secrets** — credentials, tokens, keys, or connection strings in source,
  config, tests, or log statements. Also: secrets that got added to a file that
  is not gitignored.
- **Unsafe deserialization** — `pickle`, `yaml.load` without `SafeLoader`,
  `JSON.parse` on untrusted input feeding into object construction.
- **Path traversal** — user-controlled path segments joined without
  normalization and containment checks.
- **Weak crypto** — MD5/SHA1 for anything security-relevant, hand-rolled
  crypto, hardcoded IVs, `Math.random()` for tokens.
- **Trust-boundary validation removed** — a diff that deletes or weakens an
  existing check. Deletions are as important as additions.

Report the line, the concrete attack it enables, and the fix. If the input is
provably not attacker-controlled, do not report it — say why in one line only
if it looks alarming at a glance.

Raise to `critical` for anything remotely exploitable without authentication.
