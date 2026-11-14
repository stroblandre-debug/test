"""Create an importable Godot ZIP, including CI but excluding local caches."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
output = root / "dist" / "The_Veil_of_the_Aeon_Godot_0_2.zip"
output.parent.mkdir(exist_ok=True)
excluded = {".git", ".godot", "build", "dist", "__pycache__"}
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for file in sorted(root.rglob("*")):
        relative = file.relative_to(root)
        if (file.is_file() and not excluded.intersection(relative.parts)
                and file.suffix not in {".pyc", ".log", ".tmp", ".keystore", ".apk", ".aab"}
                and file.name != "export_credentials.cfg"):
            archive.write(file, Path("the-veil-of-the-aeon") / relative)
print(output)
