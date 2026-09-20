#!/usr/bin/env sh
# AVAIL-001 -- a worker killed by a NON-exception fatal (memory_limit) emits no WORKER_ERROR:: line,
# so Runner.php:497-511 ignores its non-zero exit. Its whole file chunk is silently unanalysed and
# the command still exits 0 ("clean"), defeating a CI lint gate.
#
# Control = --sequential: the SAME crash takes down the one process, exit != 0, VISIBLE to CI.
set -u
LIM="${1:-256M}"
mkdir -p /tmp/proj && cd /tmp/proj && rm -f *.php

# 14 clean, PSR-12-correct files: their workers must succeed, so any silent loss is attributable
# to the one pathological file rather than to noise.
i=1; while [ $i -le 14 ]; do printf '<?php\n\nnamespace A;\n\nclass C%d\n{\n}\n' "$i" > "clean$i.php"; i=$((i+1)); done

# One file that (a) WOULD be reported by the linter (bad formatting) and (b) exhausts the worker's
# memory while tokenising, via a very large flat literal. If the worker died silently, a clean exit
# is a false negative.
{ printf '<?php\n$x=['; j=0; while [ $j -lt 1200000 ]; do printf '%d,' "$j"; j=$((j+1)); done; printf '];\n'; } > pathological.php
echo "pathological.php size: $(wc -c < pathological.php) bytes"

run() {
  MODE="$1"; FLAG="$2"
  echo "=== $MODE (memory_limit=$LIM) ==="
  php -d memory_limit="$LIM" /project/vendor/bin/php-cs-fixer fix /tmp/proj --dry-run --rules=@PSR12 $FLAG >/tmp/o.txt 2>&1
  echo "  exit=$?  (0=clean/no-violations, 8=violations-found, other=error)"
  grep -iE "memory|fatal|worker|exhausted" /tmp/o.txt | head -2
  echo "  files the run reported it would fix: $(grep -cE '^ +[0-9]+\)' /tmp/o.txt)"
}

run "PARALLEL (default)" ""
echo
run "SEQUENTIAL (control)" "--sequential"
