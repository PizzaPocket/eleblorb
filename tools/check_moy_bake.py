#!/usr/bin/env python3
"""Fail if the baked Moy packs were not produced from current authoring inputs."""
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parents[1]
manifest_path = root / "assets/generated/moy_city/manifest.json"
if not manifest_path.exists():
    sys.exit("Moy city bake is missing; run Godot --headless --path . tools/bake_moy_city.tscn")
manifest = json.loads(manifest_path.read_text())
bad = []
if manifest.get("format") != 4:
	bad.append("pass-4 manifest format missing")
for rel, expected in manifest.get("sources", {}).items():
    path = root / rel.removeprefix("res://")
    actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else "MISSING"
    if actual != expected:
        bad.append(rel)
for pack in manifest.get("packs", []):
    if not (root / pack.removeprefix("res://")).is_file():
        bad.append(pack)
silhouette = manifest.get("silhouette")
if silhouette and not (root / silhouette.removeprefix("res://")).is_file():
    bad.append(silhouette)
coverage = manifest.get("coverage")
if coverage and not (root / coverage.removeprefix("res://")).is_file():
    bad.append(coverage)
if not coverage:
    bad.append("coverage ledger missing")
else:
    ledger_path = root / coverage.removeprefix("res://")
    if ledger_path.exists():
        rows = json.loads(ledger_path.read_text())
        keys = {row.get("key") for row in rows}
        building_rows = [row for row in rows if str(row.get("key", "")).startswith("building:")]
        lot_rows = [row for row in rows if str(row.get("key", "")).startswith("lot:")]
        house_rows = [row for row in rows if str(row.get("key", "")).startswith("old_house:")]
        if len(building_rows) != 47 or len(lot_rows) != 133 or len(house_rows) != 60:
            bad.append("coverage ledger incomplete")
expected_prototype_counts = {
    "crossing_towers": 4, "deck_columns": 140, "deck_parapets": 123,
    "deck_beds": 44, "deck_trees": 10, "park_trees": 23, "shrubs": 62,
    "reed_clumps": 28, "rocks": 21, "agave": 6, "climber_panels": 72,
    "meridian_piers": 8, "spine_frames": 8, "station_escalator_sets": 8,
    "trains_per_service": 3, "service_lines": 4, "deck_escalator_pairs": 4,
    "deck_ramp_towers": 2, "city_clocks": 4, "city_bells": 1, "timekeepers": 0,
}
if manifest.get("prototype_counts") != expected_prototype_counts:
    bad.append("pass-4 data counts mismatch: " + json.dumps(manifest.get("prototype_counts", {}), sort_keys=True))
if bad:
    sys.exit("Moy city bake is stale or incomplete: " + ", ".join(bad))
print("Moy city bake current:", len(manifest["packs"]), "packs;", manifest["counts"])
