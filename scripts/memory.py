#!/usr/bin/env python3
"""Report what the application is using, so the memory can be followed over
time and checked in the build.

The browser engine runs in separate processes, and those processes share
pages with each other, so the resident memory of each one on its own would
count the same pages several times. The proportional set size accounts for
that, so the total is the memory the application really costs.

    scripts/memory.py [pid]
"""
import io
import os
import sys


def pss_of(pid: int) -> int:
    """The proportional set size of a process, in kilobytes."""
    try:
        with io.open(f"/proc/{pid}/smaps_rollup", encoding="utf-8") as handle:
            for line in handle:
                if line.startswith("Pss:"):
                    return int(line.split()[1])
    except (OSError, ValueError, IndexError):
        pass
    return 0


def rss_of(pid: int) -> int:
    """The resident memory of a process, in kilobytes."""
    try:
        with io.open(f"/proc/{pid}/status", encoding="utf-8") as handle:
            for line in handle:
                if line.startswith("VmRSS:"):
                    return int(line.split()[1])
    except (OSError, ValueError, IndexError):
        pass
    return 0


def children_of(pid: int) -> list:
    """The direct children of a process."""
    found = []
    task_dir = f"/proc/{pid}/task"
    try:
        threads = os.listdir(task_dir)
    except OSError:
        return found
    for thread in threads:
        try:
            with io.open(f"{task_dir}/{thread}/children", encoding="utf-8") as handle:
                for token in handle.read().split():
                    found.append(int(token))
        except (OSError, ValueError):
            continue
    return found


def measure(pid: int) -> tuple:
    """The proportional memory of a process and everything below it."""
    total = pss_of(pid)
    resident = rss_of(pid)
    count = 1
    for child in children_of(pid):
        child_total, child_resident, child_count = measure(child)
        total += child_total
        resident += child_resident
        count += child_count
    return total, resident, count


if __name__ == "__main__":
    target = int(sys.argv[1]) if len(sys.argv) > 1 else os.getpid()
    pss, rss, processes = measure(target)
    print(f"MEMORY pss={pss} kB rss={rss} kB processes={processes}")
