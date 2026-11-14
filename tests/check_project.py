"""Fail CI on Godot errors, even when its import command returns exit code 0."""
from pathlib import Path
import os
import subprocess
import sys

project = Path(__file__).resolve().parents[1]
godot = os.environ.get("GODOT_BIN", "godot")
commands = [
    [godot, "--headless", "--path", str(project), "--editor", "--import"],
    [godot, "--headless", "--path", str(project), "--script", "res://tests/run_tests.gd"],
    [godot, "--headless", "--path", str(project), "--script", "res://tests/foundation_tests.gd"],
    [godot, "--headless", "--path", str(project), "--quit-after", "120"],
]
for command in commands:
    completed = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, timeout=90)
    print(completed.stdout, flush=True)
    if completed.returncode or any(marker in completed.stdout for marker in
                                   ("SCRIPT ERROR:", "ERROR:", "FAIL:")):
        sys.exit(completed.returncode or 1)
subprocess.run([sys.executable, str(project / "tests/check_startup_recovery.py")], check=True, timeout=90)
print("Project import, gameplay, foundation, startup recovery, and startup smoke check passed.")
