#!/usr/bin/env python3
"""Fail closed when the shipped China geometry no longer matches its authoring."""
import ast
import hashlib
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
source = (root / "scripts/settlement_bake.gd").read_text()
paths = ast.literal_eval(re.search(r"const SOURCES := (\[.*?\])", source, re.S)[1])
digest = hashlib.sha256()
for name in paths:
    digest.update((root / "scripts" / name).read_bytes())
cache = root / "assets/generated/chinese_village.scn"
manifest = cache.with_suffix(cache.suffix + ".sha256")
if not cache.exists() or not manifest.exists() or manifest.read_text().strip() != digest.hexdigest():
    sys.exit("China bake missing/stale: run tools/bake_chinese_village.tscn in an isolated scratch copy, then copy assets/generated/chinese_village.scn and its .sha256 back.")
plan = (root / "scripts/chinese_plan.gd").read_text()
model = (root / "docs/drawings/chinese_gorge_3d.html").read_text()
model_data = json.loads(re.search(r"/\*DATA\*/(.*?)/\*END\*/", model, re.S)[1])
def serialized(value):
    if isinstance(value, float):
        return round(value, 3)
    if isinstance(value, list):
        return [serialized(item) for item in value]
    if isinstance(value, dict):
        return {key: serialized(item) for key, item in value.items()}
    return value

for field in ("paving_network", "workyards", "gardens", "palace_architecture", "items", "ramps", "openings", "paths", "lanterns", "bridges", "parapets", "aprons"):
    value = json.loads(re.search(r"^const " + field.upper() + r" := (.*)$", plan, re.M)[1])
    if value != serialized(model_data[field]):
        sys.exit("China model/runtime data differ: " + field)
print("China bake, runtime plan and Three.js reference data agree.")
