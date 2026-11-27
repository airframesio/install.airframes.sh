#!/bin/bash
# End-to-end installer tests: each scenario runs the installer, piped like the
# one-liner, in a fresh container with a stubbed Airframes API and stubbed
# system tools (nothing reaches the network or real hardware).
# Usage: tests/e2e/run.sh [scenario ...]
set -u
cd "$(dirname "$0")/../.."
IMAGE="${E2E_IMAGE:-python:3.11-slim-bookworm}"
ALL="unattended signin sign-in-later port-taken failed status update update-fails auto-update uninstall checksum checksum-bad feed-check preflight report report-off report-failed report-not-running report-ask"
fail=0
for s in ${*:-$ALL}; do
  out=$(timeout 300 docker run --rm -v "$PWD:/t:ro" "$IMAGE" bash /t/tests/e2e/scenario.sh "$s" 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ] || echo "$out" | grep -q '^ASSERT FAIL' || ! echo "$out" | grep -q '^ASSERT ok'; then
    echo "FAIL $s (exit $rc)"; echo "$out" | sed 's/^/    /'; fail=1
  else
    echo "ok   $s ($(echo "$out" | grep -c '^ASSERT ok') checks)"
  fi
done
exit $fail
