"""Shared fingerprint and validation helpers for Eleblorb web exports."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WEB_DIR = ROOT / "build" / "web"
MANIFEST = WEB_DIR / "build-manifest.json"

SOURCE_FILES = (
    ROOT / "project.godot",
    ROOT / "export_presets.cfg",
    ROOT / "tools" / "export_web.py",
    ROOT / "tools" / "web_build.py",
)
SOURCE_DIRECTORIES = (
    ROOT / "assets",
    ROOT / "scenes",
    ROOT / "scripts",
)
REQUIRED_WEB_FILES = (
    "index.html",
    "index.js",
    "index.pck",
    "index.wasm",
)


def source_paths() -> list[Path]:
    paths = [path for path in SOURCE_FILES if path.is_file()]
    for directory in SOURCE_DIRECTORIES:
        paths.extend(path for path in directory.rglob("*") if path.is_file())
    return sorted(paths, key=lambda path: path.relative_to(ROOT).as_posix())


def source_fingerprint() -> tuple[str, int]:
    digest = hashlib.sha256()
    paths = source_paths()
    for path in paths:
        relative = path.relative_to(ROOT).as_posix().encode("utf-8")
        digest.update(relative)
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest(), len(paths)


def write_manifest() -> None:
    fingerprint, file_count = source_fingerprint()
    payload = {
        "format": 1,
        "source_file_count": file_count,
        "source_sha256": fingerprint,
    }
    MANIFEST.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def validate_build() -> list[str]:
    errors: list[str] = []
    for filename in REQUIRED_WEB_FILES:
        path = WEB_DIR / filename
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"Missing web artifact: build/web/{filename}")

    if not MANIFEST.is_file():
        errors.append("Missing build/web/build-manifest.json; run python3 tools/export_web.py")
        return errors

    try:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as error:
        errors.append(f"Invalid web build manifest: {error}")
        return errors

    fingerprint, file_count = source_fingerprint()
    if manifest.get("source_sha256") != fingerprint or manifest.get("source_file_count") != file_count:
        errors.append("Web build is stale; run python3 tools/export_web.py and commit build/web")

    html_path = WEB_DIR / "index.html"
    if html_path.is_file():
        html = html_path.read_text(encoding="utf-8")
        for marker in ("eleblorbLoadingPhase", "eleblorbWorldReady", "Building the world"):
            if marker not in html:
                errors.append(f"Unified loading handshake is missing from index.html: {marker}")

    return errors
