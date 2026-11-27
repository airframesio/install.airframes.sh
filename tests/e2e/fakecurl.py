#!/usr/bin/env python3
# Stand-in for curl in the end-to-end tests: serves the installer, GitHub
# release info, a fake Airframes API (device sign-in, station registration,
# ATC directory) and a fake xng dashboard (/tmp/fake/state.json).
import json, os, sys, shutil
args = sys.argv[1:]
url = None; out = None; wfmt = None; data = None; method = "GET"; hdrs = []
i = 0
while i < len(args):
    a = args[i]
    if a in ("-o",): out = args[i+1]; i += 2; continue
    if a in ("-w",): wfmt = args[i+1]; i += 2; continue
    if a in ("-X",): method = args[i+1]; i += 2; continue
    if a in ("--data", "-d"): data = args[i+1]; i += 2; continue
    if a in ("-H",): hdrs.append(args[i+1]); i += 2; continue
    if a in ("-m", "--max-time"): i += 2; continue
    if a.startswith("http"): url = a
    i += 1
state = "/tmp/fakeapi"; os.makedirs(state, exist_ok=True)
log = open(state + "/requests.log", "a")
log.write("%s %s %s %s\n" % (method, url, data or "", " ".join(h for h in hdrs if h.startswith("Authorization"))))
def reply(code, body):
    s = body if isinstance(body, str) else json.dumps(body)
    if out:
        open(out, "w").write(s)
    else:
        sys.stdout.write(s)
    if wfmt:
        sys.stdout.write(wfmt.replace("\\n", "\n").replace("%{http_code}", str(code)))
    sys.exit(0 if code < 400 or wfmt else 22)
if url and url.startswith("http://127.0.0.1") and "/api/state" in url:
    if os.path.exists("/tmp/fake/state.json"):
        sys.stdout.write(open("/tmp/fake/state.json").read()); sys.exit(0)
    sys.exit(7)
if url == "https://install.airframes.sh/installer":
    sys.stdout.write(open(os.environ.get("INSTALLER", "/t/installer")).read()); sys.exit(0)
if url and "api.github.com/repos/airframesio/xng/releases/latest" in url:
    reply(200, {"tag_name": os.environ.get("XNG_LATEST", "v0.23.1")})
if url and "github.com/airframesio/xng/releases/download" in url:
    src = os.environ.get("XNG_TARBALL", "/tmp/fake/xng.tgz")
    if not os.path.exists(src): sys.stderr.write("curl: (22) 404\n"); sys.exit(22)
    shutil.copy(src, out); sys.exit(0)
api = "https://api.airframes.io"
if url and url.startswith(api):
    path = url[len(api):]
    if path == "/auth/device/code":
        reply(200, {"device_code": "dev-123", "user_code": "WDJB-MJHT", "verification_uri": "https://app.airframes.io/device",
                    "verification_uri_complete": "https://app.airframes.io/device?user_code=WDJB-MJHT", "expires_in": 900, "interval": 1})
    if path == "/auth/token":
        n = int(open(state + "/polls").read()) if os.path.exists(state + "/polls") else 0
        open(state + "/polls", "w").write(str(n + 1))
        if n < int(os.environ.get("PENDING_POLLS", "2")):
            reply(400, {"error": "authorization_pending"})
        reply(200, {"access_token": "acc-xyz", "refresh_token": "ref-abc", "token_type": "Bearer", "expires_in": 3600,
                    "user": {"id": 4242, "username": "semicolons"}})
    if path == "/feeder/station":
        body = json.loads(data)
        if body["ident"] in os.environ.get("TAKEN", "").split(","):
            reply(409, {"error": "station_ident_taken"})
        reply(201, {"created": True, "claimed": False, "station": {"ident": body["ident"]}})
    if path.startswith("/v1/atc/frequencies"):
        rows = [
            (120.500, "KMHR", "TWR", 9), (127.400, "KMHR", "GND", 9), (119.100, "KMCC", "TWR", 18),
            (121.200, "KSAC", "TWR", 21), (125.700, "KSMF", "TWR", 26), (121.700, "KSMF", "GND", 26),
            (125.250, "NCT", "APP", 22), (126.000, "KSAC", "ATIS", 21), (118.000, "KSMF", "CLNC", 26),
        ]
        reply(200, {"data": [{"id": n, "frequencyMhz": f, "frequencyHz": int(f*1e6), "service": s, "name": "%s %s" % (i_, s),
                              "facility": {"ident": i_, "type": "airport"}, "streamable": True, "distanceNm": d}
                             for n, (f, i_, s, d) in enumerate(rows)]})
    reply(404, {"error": "not_found"})
sys.stderr.write("curl stub: no network in this test (%s)\n" % url); sys.exit(22)
