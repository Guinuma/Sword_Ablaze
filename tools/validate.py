"""Validate Godot, including script errors that may return exit code zero."""
import argparse
from pathlib import Path
import re
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    checks = [
        ("Import", ["--editor", "--quit"], None),
        ("Combat", ["--script", "tests/combat_smoke.gd"], "Combat checks complete: 0 failures"),
        ("Startup", ["--quit-after", "120"], None),
    ]
    for name, flags, marker in checks:
        try:
            result = subprocess.run(
                [args.godot, "--headless", "--path", str(root), *flags],
                cwd=root, text=True, encoding="utf-8", errors="replace",
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60,
            )
        except (OSError, subprocess.TimeoutExpired) as error:
            print(f"{name} failed: {error}", file=sys.stderr)
            return 1
        print(result.stdout, end="")
        if result.returncode or re.search(r"(?:SCRIPT ERROR:|(?:^|\n)ERROR:)", result.stdout) or (marker and marker not in result.stdout):
            print(f"{name} failed", file=sys.stderr)
            return 1
        print(f"{name}: passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
