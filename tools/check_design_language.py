#!/usr/bin/env python3
"""Design-language checks that a text scan can make (settlement backlog 16).

Roof thickness belongs to TownProps.ROOF_THICKNESS alone: the first fishing
village pass shipped thin rounded-rectangle roofs from a kit that declared
its own. Fails any script other than town_props.gd that sets a roof
thickness to a number instead of reading the shared constant.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
NUMBER = r"-?\d+(\.\d+)?"
ROOF_CONST = re.compile(r"^\s*const\s+(\w*ROOF\w*THICKNESS\w*)\s*:?=\s*" + NUMBER, re.M)
PLAIN_THICKNESS = re.compile(r"^\s*const\s+(THICKNESS)\s*:?=\s*" + NUMBER, re.M)

failures = []
for path in sorted((ROOT / "scripts").rglob("*.gd")):
    if path.name == "town_props.gd":
        continue
    text = path.read_text(encoding="utf-8")
    for match in ROOF_CONST.finditer(text):
        failures.append(f"{path.relative_to(ROOT)}: {match.group(1)} is set to a number; read TownProps.ROOF_THICKNESS")
    if "roof" in path.stem:
        for match in PLAIN_THICKNESS.finditer(text):
            failures.append(f"{path.relative_to(ROOT)}: a roof script sets THICKNESS to a number; read TownProps.ROOF_THICKNESS")

for failure in failures:
    print("FAIL " + failure)
if failures:
    sys.exit(1)
print("Design language check passed.")
