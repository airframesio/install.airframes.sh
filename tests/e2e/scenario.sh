#!/bin/bash
# One end-to-end scenario, inside a python:3.11-slim-bookworm container with
# the repository at /t. Prints the installer output, then "ASSERT ok|FAIL ..."
# lines that run.sh checks. Usage: scenario.sh <name>
set -u
T=/t/tests/e2e
export INSTALLER=/t/installer AIRFRAMES_SYSFS_USB=/tmp/usb AIRFRAMES_NO_TTY=1 TZ=America/Los_Angeles
mkdir -p /usr/local/bin /tmp/fake /tmp/usb /run/systemd/system
install -m 755 "$T/fakecurl.py" /usr/local/bin/curl

# Two RTL-SDRs
for i in 1 2; do
  d=/tmp/usb/1-1.$i; mkdir -p $d
  echo 0bda > $d/idVendor; echo 2838 > $d/idProduct; echo "0000000$i" > $d/serial
done
# Stubs: packages, docker, systemd, logs, USB listing
printf '#!/bin/sh\necho "[stub] apt-get $*" >&2\n' > /usr/local/bin/apt-get
printf '#!/bin/sh\nexit 1\n' > /usr/local/bin/apt-cache
cat > /usr/local/bin/docker <<'S'
#!/bin/sh
case "$1" in ps) exit 0;; inspect) exit 1;; esac
[ -n "${DOCKER_FAILS:-}" ] && case "$*" in *compose*pull*|*compose*up*) exit 1;; esac
echo "[stub] docker $*" >&2
S
cat > /usr/local/bin/systemctl <<'S'
#!/bin/sh
echo "$*" >> /tmp/fake/systemctl.log
case "$1" in
  is-active) [ "$2" = "--quiet" ] && u="$3" || u="$2"
    case "$u" in xng-station) st=$(cat /tmp/fake/svc 2>/dev/null || echo inactive); [ "$2" = "--quiet" ] || echo "$st"; [ "$st" = active ];; *) exit 1;; esac ;;
  is-enabled) [ "$2" = "--quiet" ] && u="$3" || u="$2"; [ -f "/tmp/fake/enabled-$u" ] ;;
  enable) for u in "$@"; do touch "/tmp/fake/enabled-$u"; done ;;
  disable) for u in "$@"; do rm -f "/tmp/fake/enabled-$u"; done ;;
  restart|start) [ "$2" = xng-station ] && cp /tmp/fake/svc.next /tmp/fake/svc 2>/dev/null ;;
  list-unit-files) exit 1 ;;
  *) true ;;
esac
S
printf '#!/bin/sh\ncat /tmp/fake/journal 2>/dev/null\n' > /usr/local/bin/journalctl
printf '#!/bin/sh\necho "Bus 001 Device 004: ID 0bda:2838 Realtek RTL2838"\n' > /usr/local/bin/lsusb
chmod +x /usr/local/bin/*
echo active > /tmp/fake/svc.next
printf 'INFO xng station started\n' > /tmp/fake/journal
NOW=$(date +%s)
cat > /tmp/fake/state.json <<J
{"now":$NOW,"started":$((NOW-30)),"totals":{"acars":12},"last_seen":{"acars":$((NOW-4))},"sessions":[{"sdr":"driver=rtlsdr,serial=00000001","serial":"00000001","mode":"acars","channels":[1],"center_mhz":130.5}]}
J

# Fake xng release: a binary that only prints its version
fake_release() {
  local d=/tmp/rel/xng-v$1-x86_64-unknown-linux-gnu
  rm -rf /tmp/rel; mkdir -p "$d"
  if [ "${2:-ok}" = ok ]; then printf '#!/bin/sh\necho "xng %s"\n' "$1" > "$d/xng"; else printf '#!/bin/sh\nexit 1\n' > "$d/xng"; fi
  chmod +x "$d/xng"; tar czf /tmp/fake/xng.tgz -C /tmp/rel .
}
fake_release 0.23.1
export XNG_LATEST=v0.23.1

I='bash -s --'
run() { echo "\$ installer $*"; bash -s -- "$@" < "$INSTALLER" 2>&1; echo "EXIT=$?"; }
check() { if eval "$2"; then echo "ASSERT ok   $1"; else echo "ASSERT FAIL $1"; fi; }
TOML=/etc/xng/station.toml
REQ=/tmp/fakeapi/requests.log

case "$1" in
  unattended)
    out=$(run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "two sessions" '[ "$(grep -c "^\[\[session\]\]" $TOML)" = 2 ]'
    check "acars + vdl2" 'grep -q "mode = \"acars\"" $TOML && grep -q "mode = \"vdl2\"" $TOML'
    check "service unit" 'grep -q "^ExecStart=/usr/local/bin/xng station /etc/xng/station.toml" /etc/systemd/system/xng-station.service'
    check "station checked" 'echo "$out" | grep -q "xng is running"'
    check "no sign-in file" '[ ! -e /etc/xng/atc.json ]'
    check "nothing else stopped" '! echo "$out" | grep -q "Stopped airframes-"'
    check "no auto-update unasked" '[ ! -e /etc/systemd/system/airframes-xng-update.timer ]'
    ;;
  signin)
    out=$(run -y xng --sign-in --lat 38.68 --lon -120.99 --modes 00000001=acars,00000002=airband --airband nearest); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "code shown" 'echo "$out" | grep -q "WDJB-MJHT"'
    check "atc.json 0600" '[ "$(stat -c %a /etc/xng/atc.json)" = 600 ]'
    check "refresh token saved" 'grep -q "ref-abc" /etc/xng/atc.json'
    check "station registered" 'grep -q "POST https://api.airframes.io/feeder/station .*Bearer acc-xyz" $REQ'
    check "airband atc output" 'grep -q "^\[outputs.airband.atc\]" $TOML'
    check "airband channels" 'grep -q "^\[\[session.airband.channel\]\]" $TOML'
    ;;
  sign-in-later)
    run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2 >/dev/null
    out=$(run sign-in); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "atc.json written" 'grep -q "ref-abc" /etc/xng/atc.json'
    check "station registered" 'grep -q "/feeder/station" $REQ'
    check "airband hint" 'echo "$out" | grep -q "To add airband audio"'
    # A station that already has an airband job gets the ATC output
    printf '\n[[session]]\nsdr = "driver=rtlsdr,serial=00000003"\nmode = "airband"\n' >> $TOML
    out=$(run sign-in); echo "$out"
    check "airband atc added" 'grep -q "^\[outputs.airband.atc\]" $TOML'
    check "xng restarted" 'grep -q "restart xng-station" /tmp/fake/systemctl.log'
    out=$(run -y sign-in --station-id NEW-STATION); echo "$out"
    check "renamed with --station-id" 'grep -q "^station-id = \"NEW-STATION\"" $TOML'
    ;;
  port-taken)
    python3 -m http.server 8080 >/dev/null 2>&1 & sleep 1
    out=$(run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "dashboard moved to 8081" 'grep -q "^http = \"0.0.0.0:8081\"" $TOML'
    ;;
  failed)
    echo failed > /tmp/fake/svc.next; rm -f /tmp/fake/state.json
    printf 'usb_claim_interface error -6\nLIBUSB_ERROR_BUSY\n' > /tmp/fake/journal
    out=$(run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "failure reported" 'echo "$out" | grep -q "xng isn.t running"'
    check "busy hint" 'echo "$out" | grep -q "Another program has the SDR"'
    ;;
  status)
    run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2 >/dev/null
    printf 'INFO refresh_token="abc def" ok\n' > /tmp/fake/journal
    out=$(XNG_LATEST=v0.23.3 run status); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "version + newer" 'echo "$out" | grep -q "0.23.1 (native)" && echo "$out" | grep -q "0.23.3 is out"'
    check "token hidden" '! echo "$out" | grep -q "abc def"'
    check "claim hint" 'echo "$out" | grep -q "sign-in"'
    ;;
  update)
    run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2 >/dev/null
    fake_release 0.23.3
    out=$(XNG_LATEST=v0.23.3 run -y update); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "new binary" '[ "$(/usr/local/bin/xng --version)" = "xng 0.23.3" ]'
    ;;
  update-fails)
    run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2 >/dev/null
    fake_release 0.23.3 broken
    out=$(XNG_LATEST=v0.23.3 DOCKER_FAILS=1 run -y update); echo "$out"
    check "exit 1" 'echo "$out" | grep -q "^EXIT=1"'
    check "old binary kept" '[ "$(/usr/local/bin/xng --version)" = "xng 0.23.1" ]'
    check "unit kept" '[ -f /etc/systemd/system/xng-station.service ]'
    check "old xng started again" 'grep -q "start xng-station" /tmp/fake/systemctl.log'
    ;;
  auto-update)
    out=$(run -y xng --no-sign-in --auto-update --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "timer written" 'grep -q "OnCalendar=weekly" /etc/systemd/system/airframes-xng-update.timer'
    check "timer enabled" '[ -f /tmp/fake/enabled-airframes-xng-update.timer ]'
    check "config dir kept" 'grep -q "^Environment=\"XNG_CONFIG_DIR=/etc/xng\"" /etc/systemd/system/airframes-xng-update.service'
    out=$(run auto-update off); echo "$out"
    check "timer removed" '[ ! -e /etc/systemd/system/airframes-xng-update.timer ]'
    ;;
  uninstall)
    run -y xng --no-sign-in --auto-update --modes 00000001=acars,00000002=vdl2 >/dev/null
    out=$(run -y uninstall); echo "$out"
    check "unit removed" '[ ! -e /etc/systemd/system/xng-station.service ]'
    check "binary removed" '[ ! -e /usr/local/bin/xng ]'
    check "timer removed" '[ ! -e /etc/systemd/system/airframes-xng-update.timer ]'
    check "config kept" '[ -f $TOML ]'
    ;;
  *) echo "unknown scenario $1"; exit 2 ;;
esac
