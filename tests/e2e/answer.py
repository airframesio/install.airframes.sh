#!/usr/bin/env python3
# Runs a command on a pseudo-terminal and answers its prompts, like expect.
# Usage: answer.py "<prompt regex>=<answer>" ... -- command args
# Each answer is sent once, in order, when its prompt appears. Prints the
# output; exits with the command's exit code (124 after 90 s).
import os, pty, re, select, sys, time
sep = sys.argv.index("--")
pairs = [a.split("=", 1) for a in sys.argv[1:sep]]
cmd = sys.argv[sep + 1:]
pid, fd = pty.fork()
if pid == 0:
    os.execvp(cmd[0], cmd)
buf = b""; seen = 0; deadline = time.time() + 90
while True:
    if time.time() > deadline:
        os.kill(pid, 9); sys.stdout.write(buf.decode(errors="replace")); sys.exit(124)
    r, _, _ = select.select([fd], [], [], 0.5)
    if r:
        try: chunk = os.read(fd, 4096)
        except OSError: break
        if not chunk: break
        buf += chunk
    while pairs and re.search(pairs[0][0].encode(), buf[seen:]):
        m = re.search(pairs[0][0].encode(), buf[seen:]); seen += m.end()
        os.write(fd, (pairs[0][1] + "\n").encode()); pairs.pop(0)
sys.stdout.write(buf.decode(errors="replace"))
_, status = os.waitpid(pid, 0)
sys.exit(os.waitstatus_to_exitcode(status))
