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
install -m 755 "$T/fakedocker.py" /usr/local/bin/docker
mkdir -p /tmp/fake/docker
cat > /usr/local/bin/systemctl <<'S'
#!/bin/sh
echo "$*" >> /tmp/fake/systemctl.log
q=false; [ "$2" = "--quiet" ] && q=true
[ "$q" = true ] && u="$3" || u="$2"
case "$1" in
  is-active)
    case "$u" in
      xng-station) st=$(cat /tmp/fake/svc 2>/dev/null || echo inactive) ;;
      *) [ -f "/tmp/fake/active-$u" ] && st=active || st=inactive ;;
    esac
    [ "$q" = true ] || echo "$st"; [ "$st" = active ] ;;
  is-enabled)
    [ -f "/tmp/fake/enabled-$u" ] && st=enabled || st=disabled
    [ "$q" = true ] || echo "$st"; [ "$st" = enabled ] ;;
  enable|disable)
    act="$1"; now=false; shift
    for u in "$@"; do
      case "$u" in --now) now=true; continue ;; -*) continue ;; esac
      if [ "$act" = enable ]; then touch "/tmp/fake/enabled-$u"; [ "$now" = true ] && touch "/tmp/fake/active-$u"
      else rm -f "/tmp/fake/enabled-$u"; [ "$now" = true ] && rm -f "/tmp/fake/active-$u"; fi
    done; true ;;
  start|restart) [ "$2" = xng-station ] && cp /tmp/fake/svc.next /tmp/fake/svc 2>/dev/null; touch "/tmp/fake/active-$2"; true ;;
  stop) rm -f "/tmp/fake/active-$2"; [ "$2" = xng-station ] && echo inactive > /tmp/fake/svc; true ;;
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


# Decoders set up the old way: systemd units like the old installer's, and
# containers like sdr-enthusiasts' and AIS-catcher's
old_unit() {  # old_unit <name> <ExecStart> [enabled|stopped]
  mkdir -p /etc/systemd/system
  printf '[Unit]\nDescription=Airframes decoder\n\n[Service]\nExecStart=%s\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n' "$2" > "/etc/systemd/system/$1.service"
  [ "${3:-enabled}" = enabled ] && touch "/tmp/fake/enabled-$1" "/tmp/fake/active-$1"
  return 0
}
old_container() {  # old_container <name> <image> <restart> <env json> <cmd json>
  cat > "/tmp/fake/docker/$1.json" <<J
{"Name": "/$1", "Config": {"Image": "$2", "Env": $4, "Cmd": $5, "Entrypoint": null},
 "State": {"Running": true}, "HostConfig": {"RestartPolicy": {"Name": "$3"}}}
J
}
OLDF=/opt/airframes/config/old-decoders.tsv

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
  migrate-systemd)
    # The old installer's units: acarsdec on RTL-SDR 1 (by index), dumpvdl2 by serial
    old_unit airframes-acarsdec "acarsdec -v -o 4 -g 42 -i KE-KSEA-ACARS1 -j feed.airframes.io:5550 -r 1 131.550 131.725 130.025"
    old_unit airframes-dumpvdl2 "dumpvdl2 --rtlsdr 00000001 --station-id KE-KSEA-VDL2 --output decoded:json:udp:address=feed.airframes.io,port=5552 136650000 136975000"
    out=$(run -y xng --no-sign-in); echo "$out"; cat $TOML
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "found both" 'echo "$out" | grep -q "acarsdec (systemd airframes-acarsdec), running" && echo "$out" | grep -q "dumpvdl2 (systemd airframes-dumpvdl2), running"'
    check "station ID kept" 'grep -q "^station-id = \"KE-KSEA\"" $TOML'
    sess() { awk -v s="serial=$1" '/^\[\[session\]\]/{p=0} index($0,s){p=1} p' $TOML; }
    check "acars on its SDR" 'sess 00000002 | grep -q "mode = \"acars\""'
    check "acars gain" 'sess 00000002 | grep -q "^gain = 42.0"'
    check "acars channels" 'sess 00000002 | grep -q "^channels = \[\"130.025\", \"131.550\", \"131.725\"\]"'
    check "acars name kept" 'sess 00000002 | grep -q "^airframes-station-id = \"KE-KSEA-ACARS1\""'
    check "vdl2 on its SDR" 'sess 00000001 | grep -q "mode = \"vdl2\""'
    check "vdl2 channels" 'sess 00000001 | grep -q "^channels = \[\"136.650\", \"136.975\"\]"'
    check "vdl2 needs no override" '! sess 00000001 | grep -q airframes-station-id'
    check "units stopped" '[ ! -e /tmp/fake/enabled-airframes-acarsdec ] && [ ! -e /tmp/fake/active-airframes-dumpvdl2 ]'
    check "units kept" '[ -f /etc/systemd/system/airframes-acarsdec.service ] && [ -f /etc/systemd/system/airframes-dumpvdl2.service ]'
    check "recorded" 'grep -q "^systemd	airframes-acarsdec	yes	yes" $OLDF && grep -q "^systemd	airframes-dumpvdl2	yes	yes" $OLDF'
    check "way back shown" 'echo "$out" | grep -q "Switch back: .*restore-decoders"'
    check "names in summary" 'echo "$out" | grep -q "keep their names: KE-KSEA-VDL2, KE-KSEA-ACARS1"'
    echo '{"KE-KSEA-ACARS1": 30}' > /tmp/fake/stations.json
    out=$(run status); echo "$out"
    check "status checks the kept name" 'echo "$out" | grep -q "KE-KSEA-ACARS1: last heard [0-9]* s ago$" && echo "$out" | grep -q "KE-KSEA-VDL2: not seen yet"'
    out=$(run -y restore-decoders); echo "$out"
    check "restore exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "xng stopped" 'grep -q "disable --now xng-station" /tmp/fake/systemctl.log'
    check "units back" '[ -e /tmp/fake/enabled-airframes-acarsdec ] && [ -e /tmp/fake/active-airframes-acarsdec ] && [ -e /tmp/fake/active-airframes-dumpvdl2 ]'
    check "xng kept" '[ -x /usr/local/bin/xng ] && [ -f $TOML ]'
    check "record archived" '[ ! -e $OLDF ] && ls /opt/airframes/config/old-decoders.restored-*.tsv >/dev/null'
    ;;
  migrate-docker)
    old_container airframes-dumpvdl2 ghcr.io/sdr-enthusiasts/docker-dumpvdl2:latest unless-stopped \
      '["FEED_ID=XX-TEST-VDL2", "SERIAL=00000002", "FREQUENCIES=136650000;136975000", "GAIN=40"]' null
    old_container ais-catcher ghcr.io/jvde-github/ais-catcher:edge always '[]' \
      '["-d", "00000001", "-gr", "TUNER", "38.6", "-H", "https://ais.airframes.io/intake", "ID", "XX-TEST-AIS", "INTERVAL", "10"]'
    out=$(run -y xng --no-sign-in); echo "$out"; cat $TOML
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "station ID kept" 'grep -q "^station-id = \"XX-TEST\"" $TOML'
    sess() { awk -v s="serial=$1" '/^\[\[session\]\]/{p=0} index($0,s){p=1} p' $TOML; }
    check "vdl2 on its SDR" 'sess 00000002 | grep -q "mode = \"vdl2\"" && sess 00000002 | grep -q "^gain = 40.0"'
    check "ais on its SDR" 'sess 00000001 | grep -q "mode = \"ais\"" && sess 00000001 | grep -q "^gain = 38.6"'
    check "no overrides" '! grep -q airframes-station-id $TOML'
    check "containers stopped" 'grep -q "^stop airframes-dumpvdl2" /tmp/fake/docker.log && grep -q "^stop ais-catcher" /tmp/fake/docker.log'
    check "no restart at boot" 'grep -q "^update --restart=no ais-catcher" /tmp/fake/docker.log'
    check "containers kept" '! grep -q "^rm" /tmp/fake/docker.log && [ -f /tmp/fake/docker/ais-catcher.json ]'
    check "recorded" 'grep -q "^docker	ais-catcher		yes	always" $OLDF'
    out=$(run -y restore-decoders); echo "$out"
    check "policy back" 'grep -q "^update --restart=always ais-catcher" /tmp/fake/docker.log && grep -q "^update --restart=unless-stopped airframes-dumpvdl2" /tmp/fake/docker.log'
    check "started" 'grep -q "^start ais-catcher" /tmp/fake/docker.log && grep -q "^start airframes-dumpvdl2" /tmp/fake/docker.log'
    ;;
  migrate-compose)
    # A compose file from the old installer that was never started, plus a
    # wrapper-script unit (EnvironmentFile) for dumpvdl2
    mkdir -p /opt/airframes/config/acarsdec /etc/default /usr/local/share/dumpvdl2
    cat > /opt/airframes/config/acarsdec/docker-compose.yml <<'Y'
version: '3.8'
services:
  acarsdec:
    image: ghcr.io/sdr-enthusiasts/docker-acarsdec:latest
    container_name: airframes-acarsdec
    restart: unless-stopped
    environment:
      FEED_ID: "ZZ-HOME-ACARS"
      FREQUENCIES: "130.025 130.450 131.125 131.550"
      OUTPUT_SERVER: "feed.airframes.io"
      SERIAL: "00000001"
Y
    printf 'SERIAL=00000002\nOPTIONS="--station-id ZZ-HOME-VDL2 --gain 39.6"\n' > /etc/default/dumpvdl2
    printf '#!/bin/sh\n# start dumpvdl2\nexec /usr/local/bin/dumpvdl2 --rtlsdr $SERIAL $OPTIONS 136725000 136975000\n' > /usr/local/share/dumpvdl2/start.sh
    chmod +x /usr/local/share/dumpvdl2/start.sh
    old_unit dumpvdl2 "/usr/local/share/dumpvdl2/start.sh"
    sed -i 's/^\[Service\]/[Service]\nEnvironmentFile=\/etc\/default\/dumpvdl2/' /etc/systemd/system/dumpvdl2.service
    out=$(run -y xng --no-sign-in); echo "$out"; cat $TOML
    sess() { awk -v s="serial=$1" '/^\[\[session\]\]/{p=0} index($0,s){p=1} p' $TOML; }
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "compose found" 'echo "$out" | grep -q "compose file .*acarsdec/docker-compose.yml"'
    check "acars from compose" 'sess 00000001 | grep -q "mode = \"acars\"" && sess 00000001 | grep -q "\"130.450\""'
    check "vdl2 from script" 'sess 00000002 | grep -q "mode = \"vdl2\"" && sess 00000002 | grep -q "^gain = 39.6" && sess 00000002 | grep -q "\"136.725\""'
    check "station ID kept" 'grep -q "^station-id = \"ZZ-HOME\"" $TOML'
    check "only the unit recorded" '[ "$(grep -vc "^#" $OLDF)" = 1 ] && grep -q "^systemd	dumpvdl2	" $OLDF'
    check "compose file kept" '[ -f /opt/airframes/config/acarsdec/docker-compose.yml ]'
    ;;
  keep-old)
    old_unit airframes-acarsdec "acarsdec -v -o 4 -g 42 -i KE-KSEA-ACARS1 -j feed.airframes.io:5550 -r 00000001 131.550 131.725"
    out=$(run -y xng --no-sign-in --keep-old-decoders); echo "$out"; cat $TOML
    check "exit 0" 'echo "$out" | grep -q "^EXIT=0"'
    check "left running" '[ -e /tmp/fake/active-airframes-acarsdec ] && [ -e /tmp/fake/enabled-airframes-acarsdec ]'
    check "its SDR left alone" '! grep -q "serial=00000001" $TOML && grep -q "serial=00000002" $TOML'
    check "nothing recorded" '[ ! -e $OLDF ]'
    out=$(run restore-decoders); echo "$out"
    check "nothing to restore" 'echo "$out" | grep -q "nothing to restore" && echo "$out" | grep -q "^EXIT=0"'
    ;;
  *) echo "unknown scenario $1"; exit 2 ;;
esac
