#!/usr/bin/env python3
"""Send SIGHUP to all `claude` CLI processes except self (and self's ancestor chain)."""
import argparse
import os
import signal
import subprocess
import sys


def ps_snapshot():
    out = subprocess.check_output(
        ["ps", "-Ao", "pid=,ppid=,comm=,command="], text=True
    )
    rows = {}
    for line in out.splitlines():
        parts = line.strip().split(None, 3)
        if len(parts) < 4:
            continue
        pid, ppid, comm, cmd = parts
        rows[int(pid)] = {"ppid": int(ppid), "comm": comm, "cmd": cmd}
    return rows


def is_claude_cli(row):
    # Match the claude CLI (argv[0] == "claude" or ends with "/claude"),
    # explicitly exclude the Claude.app desktop app tree.
    cmd = row["cmd"]
    comm = row["comm"]
    if "Claude.app" in cmd or "Claude Helper" in cmd:
        return False
    if comm == "claude":
        return True
    first = cmd.split()[0] if cmd else ""
    return first == "claude" or first.endswith("/claude")


def ancestors(pid, rows):
    seen = set()
    cur = pid
    while cur and cur not in seen:
        seen.add(cur)
        row = rows.get(cur)
        if not row:
            break
        cur = row["ppid"]
    return seen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="list targets, don't signal")
    ap.add_argument("--signal", default="HUP", help="signal name (default HUP)")
    ap.add_argument(
        "--no-sentinel",
        action="store_true",
        help="skip writing the claude-loop restart sentinel",
    )
    args = ap.parse_args()

    sig = getattr(signal, f"SIG{args.signal}", None)
    if sig is None:
        print(f"unknown signal: {args.signal}", file=sys.stderr)
        sys.exit(2)

    rows = ps_snapshot()
    my_chain = ancestors(os.getpid(), rows)

    targets = []
    for pid, row in rows.items():
        if pid in my_chain:
            continue
        if is_claude_cli(row):
            targets.append((pid, row["cmd"]))

    if not targets:
        print("no other claude processes found")
        return

    sentinel_dir = os.environ.get("TMPDIR", "/tmp").rstrip("/")
    for pid, cmd in targets:
        print(f"{'would signal' if args.dry_run else f'sending SIG{args.signal}'} {pid}: {cmd[:120]}")
        if args.dry_run:
            continue
        if not args.no_sentinel:
            try:
                open(f"{sentinel_dir}/claude-loop-restart-{pid}", "w").close()
            except OSError as e:
                print(f"  sentinel write failed for pid {pid}: {e}", file=sys.stderr)
        try:
            os.kill(pid, sig)
        except ProcessLookupError:
            print(f"  pid {pid} gone", file=sys.stderr)
        except PermissionError as e:
            print(f"  pid {pid}: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
