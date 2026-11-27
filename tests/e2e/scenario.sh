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
# qrencode stand-in (only installed by the qr scenarios): a 33-module code,
# "##" per module in ASCII, one cell per module and a marker otherwise
cat > /tmp/fake/qrencode <<'S'
#!/bin/sh
echo "$*" >> /tmp/fake/qrencode.log
for a in "$@"; do t="$a"; done
case " $* " in
  *" ASCII "*) i=0; while [ $i -lt 33 ]; do printf '%066d\n' 0 | tr 0 '#'; i=$((i+1)); done ;;
  *) echo "QRCODE-FOR $t"; printf '%033d\n' 0 | tr 0 '#' ;;
esac
S
chmod +x /tmp/fake/qrencode
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
    id=$(sed -n 's/^station-id *= *"\(.*\)"/\1/p' $TOML)
    check "station page linked" 'echo "$out" | grep -q "Its page: https://app.airframes.io/stations/$id$"'
    check "summary links page" 'echo "$out" | grep -q "On Airframes: .*https://app.airframes.io/stations/$id"'
    check "full link shown" 'echo "$out" | grep -q "https://app.airframes.io/device?user_code=WDJB-MJHT"'
    check "tried to install qrencode" 'echo "$out" | grep -q "Installing qrencode"'
    check "no QR without qrencode" '! echo "$out" | grep -q "scan this"'
    out=$(run status); echo "$out"
    check "status links page" 'echo "$out" | grep -q "Page:     https://app.airframes.io/stations/$id$"'
    ;;
  qr)
    cp /tmp/fake/qrencode /usr/local/bin/qrencode
    run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2 >/dev/null
    out=$(AIRFRAMES_COLUMNS=100 LC_ALL=C.UTF-8 run sign-in); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "QR of the full link" 'echo "$out" | grep -q "^    QRCODE-FOR https://app.airframes.io/device?user_code=WDJB-MJHT"'
    check "half blocks with UTF-8" 'grep -q -- "-t ANSIUTF8" /tmp/fake/qrencode.log'
    check "link shown too" 'echo "$out" | grep -q "Or open this link"'
    check "no install attempt" '! echo "$out" | grep -q "Installing qrencode"'
    : > /tmp/fake/qrencode.log
    # 33 modules: 37 columns with half blocks, 70 without UTF-8
    out=$(AIRFRAMES_COLUMNS=60 LC_ALL=C LANG= run sign-in); echo "$out"
    check "narrow without UTF-8: link only" '! echo "$out" | grep -q QRCODE-FOR && echo "$out" | grep -q "user_code=WDJB-MJHT"'
    check "wider hint" 'echo "$out" | grep -q "Make the window wider"'
    out=$(AIRFRAMES_COLUMNS=36 LC_ALL=C.UTF-8 run sign-in); echo "$out"
    check "too narrow: link only" '! echo "$out" | grep -q QRCODE-FOR && echo "$out" | grep -q "Make the window wider"'
    out=$(AIRFRAMES_COLUMNS=80 LC_ALL=C LANG= run sign-in); echo "$out"
    check "plain ANSI without UTF-8" 'echo "$out" | grep -q QRCODE-FOR && grep -q -- "-t ANSI " /tmp/fake/qrencode.log'
    out=$(AIRFRAMES_NO_QR=1 AIRFRAMES_COLUMNS=100 run sign-in); echo "$out"
    check "AIRFRAMES_NO_QR" '! echo "$out" | grep -q QRCODE-FOR && ! echo "$out" | grep -q "Make the window wider"'
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
  checksum)
    out=$(XNG_SUMS=good run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "tarball checked" 'echo "$out" | grep -q "Checked xng-v0.23.1-.*(SHA-256)"'
    check "native install" '[ "$(/usr/local/bin/xng --version)" = "xng 0.23.1" ]'
    ;;
  checksum-bad)
    out=$(XNG_SUMS=bad run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "mismatch reported" 'echo "$out" | grep -q "doesn.t match the release.s SHA256SUMS"'
    check "not installed" '[ ! -e /usr/local/bin/xng ]'
    ;;
  feed-check)
    run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2 >/dev/null
    id=$(sed -n 's/^station-id *= *"\(.*\)"/\1/p' $TOML)
    echo "{\"$id-ACARS\": 30, \"$id-VDL2\": 18000}" > /tmp/fake/stations.json
    out=$(run status); echo "$out"
    check "acars heard" 'echo "$out" | grep -q "$id-ACARS: last heard [0-9]* s ago$"'
    check "vdl2 quiet" 'echo "$out" | grep -q "$id-VDL2: last heard 5 h ago  <- nothing for a while"'
    rm /tmp/fake/stations.json
    out=$(run status); echo "$out"
    check "not seen yet" 'echo "$out" | grep -q "$id-ACARS: not seen yet"'
    ;;
  preflight)
    out=$(FAKE_DATE_OFFSET=900 run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "clock warning" 'echo "$out" | grep -q "clock is off by 15 minutes"'
    out=$(run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "no warning when right" '! echo "$out" | grep -q "clock is off"'
    ;;
  report)
    out=$(run -y xng --no-sign-in --report --modes 00000001=acars,00000002=vdl2); echo "$out"
    R=/tmp/fakeapi/report.json; cat $R
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "report sent" '[ "$(wc -l < $R)" = 1 ]'
    check "success" 'grep -q "\"outcome\":\"success\"" $R && grep -q "\"failed_step\":\"\"" $R'
    check "versions" 'grep -q "\"installer_version\":\"3.7.0\"" $R && grep -q "\"xng_version\":\"0.23.1\"" $R'
    check "system" 'grep -q "\"os\":\"linux\",\"distro\":\"debian\",\"arch\":\"amd64\"" $R'
    check "sdrs and modes" 'grep -q "\"sdrs\":\[\"rtlsdr\",\"rtlsdr\"\],\"modes\":\[\"acars\",\"vdl2\"\]" $R'
    id=$(sed -n 's/^station-id *= *"\(.*\)"/\1/p' $TOML)
    check "no station id, serial or host" '! grep -q -e "$id" -e 00000001 -e "$(hostname)" $R'
    check "thanks shown" 'echo "$out" | grep -q "Report sent"'
    ;;
  report-off)
    out=$(run -y xng --no-sign-in --modes 00000001=acars,00000002=vdl2); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "-y sends nothing" '[ ! -e /tmp/fakeapi/report.json ] && ! grep -q /installer/report $REQ'
    out=$(run -y xng --no-sign-in --no-report --modes 00000001=acars); echo "$out"
    check "--no-report sends nothing" '! grep -q /installer/report $REQ'
    ;;
  report-failed)
    rm -f /tmp/fake/xng.tgz
    out=$(run -y xng --no-sign-in --report --xng-method native --modes 00000001=acars,00000002=vdl2); echo "$out"
    R=/tmp/fakeapi/report.json; cat $R
    check "exit 1" 'echo "$out" | grep -q "^EXIT=1"'
    check "failed at native install" 'grep -q "\"outcome\":\"failed\",\"failed_step\":\"xng-install-native\",\"exit_code\":1" $R'
    ;;
  report-not-running)
    echo failed > /tmp/fake/svc.next; rm -f /tmp/fake/state.json
    out=$(REPORT_STATUS=503 run -y xng --no-sign-in --report --modes 00000001=acars,00000002=vdl2); echo "$out"
    R=/tmp/fakeapi/report.json; cat $R
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "not running" 'grep -q "\"outcome\":\"not_running\"" $R'
    check "send failure is quiet" 'echo "$out" | grep -q "couldn.t be sent (HTTP 503)"'
    ;;
  report-ask)
    # On a terminal (answer.py answers the prompts): install, no auto-update, then the report
    tty_run() { AIRFRAMES_NO_TTY= python3 -I $T/answer.py 'Install the xng station=y' 'up to date automatically=n' "Send it\\?=$1" -- \
      bash $INSTALLER xng --no-sign-in --station-id TEST-1 --lat 38.68 --lon -120.99 --modes 00000001=acars,00000002=vdl2; echo "EXIT=$?"; }
    out=$(tty_run ''); echo "$out"
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "asks with a preview" 'echo "$out" | grep -q "send Airframes this anonymous report" && echo "$out" | grep -q "Modes:.*acars vdl2"'
    check "default is no" 'echo "$out" | grep -q "Send it? \[y/N\]" && [ ! -e /tmp/fakeapi/report.json ]'
    out=$(tty_run y); echo "$out"
    check "yes sends it" '[ "$(wc -l < /tmp/fakeapi/report.json)" = 1 ] && ! grep -q TEST-1 /tmp/fakeapi/report.json'
    out=$(AIRFRAMES_NO_TTY= python3 -I $T/answer.py 'Install the xng station=n' -- bash $INSTALLER xng --no-sign-in --station-id TEST-1 --lat 38.68 --lon -120.99 --modes 00000001=acars); echo "$out"
    check "not asked after no to the install" 'echo "$out" | grep -q "Aborted" && ! echo "$out" | grep -q "anonymous report"'
    ;;
  *) echo "unknown scenario $1"; exit 2 ;;
esac
