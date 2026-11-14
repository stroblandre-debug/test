"""Verify recovery from actual game compile errors in disposable project copies."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
godot = os.environ.get("GODOT_BIN", "godot")
with tempfile.TemporaryDirectory(prefix="veil-startup-regression-") as directory:
    work = Path(directory)
    for scenario in ("broken_script", "missing_world"):
        project = work / scenario
        shutil.copytree(root, project, ignore=shutil.ignore_patterns(
            ".godot", ".git", "build", "dist", "__pycache__"))
        if scenario == "broken_script":
            (project / "scripts/game.gd").write_text(
                "extends Node2D\nfunc intentionally_broken(\n", encoding="utf-8")
        else:
            catalog = project / "data/worlds.json"
            values = json.loads(catalog.read_text(encoding="utf-8"))
            values[0]["status"] = "planned"
            values[0]["scene"] = ""
            catalog.write_text(json.dumps(values), encoding="utf-8")
        result = subprocess.run([
            godot, "--headless", "--path", str(project), "--script",
            "res://tests/boot_failure_probe.gd"], text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
        if result.returncode or "EXPECTED_START_FAILURE_VISIBLE" not in result.stdout:
            raise RuntimeError(f"Startup recovery failed: {scenario}\n{result.stdout}")
        if scenario == "broken_script" and "SCRIPT ERROR:" not in result.stdout:
            raise RuntimeError("The compile-error regression did not exercise a real script error")
        print(f"PASS: visible startup recovery after {scenario}")
