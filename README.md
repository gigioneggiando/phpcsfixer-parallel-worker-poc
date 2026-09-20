# PHP-CS-Fixer — parallel worker fatal silently drops a file chunk (demo)

Repro for [PHP-CS-Fixer/PHP-CS-Fixer#9854](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/issues/9854).

In parallel mode (the default), a worker killed by a **non-exception fatal** — e.g. hitting
`memory_limit` while tokenising a pathological file — emits no `WORKER_ERROR::` line, so the runner's
`exit` callback treats its non-zero exit as nothing to report. That worker's whole file chunk is
silently skipped and the command still **exits 0**, whereas `--sequential` exits non-zero on the same
crash. Used as a CI lint gate (`fix --dry-run`), parallel mode therefore reports green for files it
never actually checked.

## Run

```sh
docker build -t phpcsfixer-worker-poc .
docker run --rm phpcsfixer-worker-poc
```

## Expected output

- **PARALLEL (default):** `exit=0`, `Found 0 of 15 files ...` — the pathological file's worker was
  killed and its chunk dropped silently.
- **SEQUENTIAL (control):** `exit=255`, `Fatal error: Allowed memory size ... exhausted`.

`poc.sh` builds the input (14 clean PSR-12 files + one file with a huge flat literal array that
exhausts a worker's memory) and runs both modes. `sample-run.log` is a captured run.

Pinned to php-cs-fixer `945e6d8` (`dev-master`) where this was reproduced; bump the `COMMIT` build-arg
to test another ref. Reported by [@gigioneggiando](https://github.com/gigioneggiando).
