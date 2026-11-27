#!/usr/bin/env python3
# Stand-in for docker in the end-to-end tests. Containers are JSON files in
# /tmp/fake/docker/<name>.json, in `docker inspect` form; every call is
# logged to /tmp/fake/docker.log.
import glob, json, os, sys
D = "/tmp/fake/docker"
args = sys.argv[1:]
open("/tmp/fake/docker.log", "a").write(" ".join(args) + "\n")

def load(name):
    p = os.path.join(D, name + ".json")
    return json.load(open(p)) if os.path.exists(p) else None

def save(c):
    json.dump(c, open(os.path.join(D, c["Name"].lstrip("/") + ".json"), "w"))

def names():
    return sorted(os.path.basename(p)[:-5] for p in glob.glob(D + "/*.json"))

cmd = args[0] if args else ""
if cmd == "ps":
    fmt = args[args.index("--format") + 1] if "--format" in args else ""
    for n in names():
        c = load(n)
        if "-a" not in args and not c["State"]["Running"]:
            continue
        print(n if fmt == "{{.Names}}" else "%s %s" % (n, c["Config"]["Image"]))
    sys.exit(0)
if cmd == "inspect":
    rest = args[1:]
    fmt = None
    if rest[:1] in (["-f"], ["--format"]):
        fmt, rest = rest[1], rest[2:]
    found = [load(n) for n in rest]
    if not found or None in found:
        sys.exit(1)
    if fmt == "{{.HostConfig.RestartPolicy.Name}}":
        print(found[0]["HostConfig"]["RestartPolicy"]["Name"])
    elif fmt == "{{.State.Running}}":
        print("true" if found[0]["State"]["Running"] else "false")
    else:
        print(json.dumps(found))
    sys.exit(0)
if cmd == "update":
    pol = [a.split("=", 1)[1] for a in args if a.startswith("--restart=")]
    c = load(args[-1])
    if c is None: sys.exit(1)
    if pol: c["HostConfig"]["RestartPolicy"]["Name"] = pol[0]
    save(c); sys.exit(0)
if cmd in ("stop", "start", "restart"):
    c = load(args[-1])
    if c is None: sys.exit(1)
    c["State"]["Running"] = cmd != "stop"
    save(c); sys.exit(0)
if cmd == "rm":
    for n in args[1:]:
        if not n.startswith("-") and os.path.exists(os.path.join(D, n + ".json")):
            os.remove(os.path.join(D, n + ".json"))
    sys.exit(0)
if os.environ.get("DOCKER_FAILS") and cmd == "compose" and ("pull" in args or "up" in args):
    sys.exit(1)
sys.stderr.write("[stub] docker %s\n" % " ".join(args))
