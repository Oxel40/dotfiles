---
name: error-handling
description: Flags failure paths that lose data, hide errors, or leave state inconsistent.
severity-default: medium
---

Look for:

- **Swallowed errors** — `catch {}`, `except: pass`, `if err != nil {}`, a
  rejected promise with no handler. An error that vanishes is a bug that will be
  debugged at 3am.
- **Unchecked results** — a call that can fail whose return value or error is
  ignored. Especially I/O, network, and parsing.
- **Partial writes** — a multi-step mutation with no rollback, where failing
  halfway leaves state inconsistent. Name the intermediate state that can persist.
- **Lost context** — an error re-raised or wrapped in a way that discards the
  original cause, message, or stack.
- **Wrong-layer handling** — an error caught and defaulted deep in a helper when
  the caller needed to know. Silent fallbacks that mask real failure.
- **Unhandled edge inputs** — empty collection, null, zero, negative, or a
  single-element case in code written for the many-element case.
- **Resource leaks** — file, socket, lock, or transaction not released on the
  error path. Check that cleanup is in `finally` / `defer` / a context manager,
  not just the happy path.

Raise to `high` when the failure loses user data or leaves persistent state
corrupt. Lower to `low` for a swallowed error in test setup or a script.

Do not report missing error handling for cases that provably cannot occur, and
do not ask for defensive checks against a function's own callers within the
same module.
