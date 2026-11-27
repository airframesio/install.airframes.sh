#!/bin/bash
# Live installer test: the real xng release from GitHub on a fresh Debian
# Bookworm (run under QEMU for arm64 and armhf in CI). Nothing is faked but
# the SDRs. Usage, inside the container:
#   run.sh /t/installer      test this checkout's installer
#   run.sh online            test the one-liner from install.airframes.sh
# Prints "ASSERT ok|FAIL ..." lines and exits nonzero on any failure.
set -u
SRC="${1:-/t/installer}"
fail=0
check() { if eval "$2"; then echo "ASSERT ok   $1"; else echo "ASSERT FAIL $1"; fail=1; fi; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
# What a fresh Raspberry Pi OS Lite has: curl and sudo, no python3
apt-get install -y -qq curl ca-certificates sudo procps >/dev/null

# Two RTL-SDRs on "USB" (the installer reads them from sysfs)
for i in 1 2; do
  d=/tmp/usb/1-1.$i; mkdir -p "$d"
  echo 0bda > "$d/idVendor"; echo 2838 > "$d/idProduct"; echo "0000000$i" > "$d/serial"
done
export AIRFRAMES_SYSFS_USB=/tmp/usb AIRFRAMES_NO_TTY=1
ARGS=(-y xng --no-sign-in --no-auto-update --lat 38.68 --lon -120.99 --modes "00000001=acars,00000002=vdl2")

latest=$(curl -fsSIL -o /dev/null -w '%{url_effective}' https://github.com/airframesio/xng/releases/latest)
latest="${latest##*/}"; latest="${latest#v}"
echo "Latest xng release: ${latest:-unknown}  ($(uname -m), $(. /etc/os-release; echo "$PRETTY_NAME"))"

if [ "$SRC" = online ]; then
  out=$(curl -sSL https://install.airframes.sh/installer | bash -s -- "${ARGS[@]}" 2>&1); rc=$?
else
  out=$(bash "$SRC" "${ARGS[@]}" 2>&1); rc=$?
fi
echo "$out" | sed 's/\x1b\[[0-9;]*m//g'
echo "EXIT=$rc"

check "installer exit 0" '[ "$rc" = 0 ]'
check "download checked against SHA256SUMS" 'echo "$out" | grep -q "Checked xng.*(SHA-256)"'
bin=$(command -v xng || true)
[ -n "$bin" ] || bin=$(ls /usr/bin/xng /usr/local/bin/xng 2>/dev/null | head -1)
check "xng installed natively" '[ -n "$bin" ] && [ -x "$bin" ]'
ver=$("$bin" --version 2>/dev/null | head -1)
echo "xng --version: $ver"
check "latest release installed" '[ -n "$latest" ] && echo "$ver" | grep -q "$latest"'
st=$(timeout 600 "$bin" selftest 2>&1); src=$?
echo "$st" | tail -5
check "xng selftest" "[ $src = 0 ]"
check "station.toml written" 'grep -q "^mode = \"acars\"" /etc/xng/station.toml'

# Start the station by hand (no systemd in the container). The RTL-SDRs are
# fake, so xng stops when it opens one; getting that far shows that the
# config loads and that session is tuned. xng stops at the first SDR it
# can't open, so run each session on its own to check every one.
check "station.toml has both SDR jobs" 'grep -q "00000001" /etc/xng/station.toml && grep -q "00000002" /etc/xng/station.toml && grep -q "^mode = \"vdl2\"" /etc/xng/station.toml'
seen=""
awk '/^\[\[session\]\]/{n++} {f = n ? "/tmp/session-" n ".toml" : "/tmp/head.toml"; print > f}' /etc/xng/station.toml
for part in /tmp/session-*.toml; do
  serial=$(grep -o '0000000[0-9]' "$part" | head -1)
  mode=$(sed -n 's/^mode = "\(.*\)"/\1/p' "$part" | head -1)
  case "$serial" in 00000001) want=acars ;; 00000002) want=vdl2 ;; *) want="?" ;; esac
  check "SDR $serial runs $want" '[ "$mode" = "$want" ]'
  seen="$seen $serial"
  cat /tmp/head.toml "$part" > /tmp/one.toml
  log="/tmp/xng-$serial.log"
  ("$bin" station /tmp/one.toml > "$log" 2>&1 &)
  for _ in $(seq 1 30); do
    grep -q "^Error:" "$log" 2>/dev/null && break
    curl -s -m 3 http://127.0.0.1:8080/api/state | grep -q '"sessions"' && break
    sleep 2
  done
  pkill -f "xng station /tmp/one.toml" 2>/dev/null || true
  sleep 1
  echo "--- xng log ($mode on $serial)"; tail -8 "$log"
  check "$mode session loads and reaches SDR $serial" "grep -q 'rtlsdr_get_index_by_serial($serial)' '$log'"
  check "$mode session has no config errors" "! grep -qi 'config\\|toml\\|unknown field\\|parse' '$log'"
done
check "both SDR jobs ran" 'echo "$seen" | grep -q 00000001 && echo "$seen" | grep -q 00000002'

if [ "$SRC" = online ]; then
  st=$(curl -sSL https://install.airframes.sh/installer | bash -s -- status 2>&1)
else
  st=$(bash "$SRC" status 2>&1)
fi
echo "$st" | sed 's/\x1b\[[0-9;]*m//g'
check "status report" 'echo "$st" | grep -q "Airframes station report"'
pkill -f "xng station" 2>/dev/null || true
exit $fail
