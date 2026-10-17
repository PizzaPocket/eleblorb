#!/usr/bin/env python3
"""Which village validators a push needs, from the files it changes.

Called by .githooks/pre-push with git's pre-push lines on stdin
("<local ref> <local sha> <remote ref> <remote sha>"). Prints one village name
per line (the names tools/check_village_layout.sh takes), or nothing when no
village is touched.

- A file that belongs to one settlement runs that settlement's validator.
- Shared game code (any other script, scene, resource, shader or the project
  file) can break any settlement, so it runs all of them.
- Documents, drawings, skills, prompts and the stale web build run none.
- When the changed files cannot be worked out (a new branch with no common
  history, a missing commit), it runs all of them, to be safe.

Set ELEBLORB_HOOK_ALL=1 to run every validator anyway.
"""
import os
import re
import subprocess
import sys

ALL = ["ohio", "snow", "china", "fishing", "fire", "city", "kai_malie", "sea_folk", "pirate_ships"]
ZERO = re.compile(r"^0+$")

# Files that belong to one settlement (or two that share a builder), matched on the path.
OWN = [
    (r"(^|/)(ohio_|village_inn|ohio\.)", ["ohio"]),
    (r"(^|/)(town_generator|town_props|village_works|villager_appearance)\.", ["ohio", "snow"]),
    (r"(^|/)snow_(plan|buildings|grounds|interiors)|probe_snow", ["snow"]),
    (r"chinese|china|(^|/)assets/generated/chinese", ["china"]),
    (r"fishing", ["fishing"]),
    (r"fire_caldera|fire_kingdom|(^|/)caldera_|validate_fire|player_support_handoff_probe", ["fire"]),
    (r"(^|/)(city_|moy_)|bake_moy|check_moy|validate_city|validate_moy|(^|/)assets/generated/moy_city", ["city"]),
    (r"kai_malie", ["kai_malie"]),
    (r"sea_folk|ocean_kingdom_city", ["sea_folk"]),
    (r"pirate_ships", ["pirate_ships"]),
]
# Changes that need no village validator: documents, drawings, skills, the stale web build, media.
QUIET = re.compile(r"(^docs/|\.md$|^build/web/|^\.claude/|^\.github/|\.(png|jpg|jpeg|svg|wav|ogg|mp3|import|uid)$)")
# Other Python tools (the quick checks always run anyway); a settlement's layout tool is matched in OWN first.
OTHER_TOOLS = re.compile(r"^tools/[^/]+\.py$")
# Shared game code: runs every validator.
SHARED = re.compile(r"(\.(gd|tscn|tres|gdshader|cfg)$|^project\.godot$|^tools/check_village_layout\.sh$|^\.githooks/)")


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True)


def changed_files(lines):
    files = set()
    for line in lines:
        parts = line.split()
        if len(parts) != 4:
            continue
        _, local, _, remote = parts
        if ZERO.match(local):
            continue  # a deleted ref changes no files
        if ZERO.match(remote):
            base = git("merge-base", local, "origin/main")
            if base.returncode != 0:
                return None
            remote = base.stdout.strip()
        if git("cat-file", "-e", remote + "^{commit}").returncode != 0:
            return None
        out = git("diff", "--name-only", remote, local)
        if out.returncode != 0:
            return None
        files.update(f for f in out.stdout.splitlines() if f)
    return files


def villages_for(files):
    if files is None:
        return list(ALL)
    need = set()
    for f in files:
        if QUIET.search(f):
            continue
        owners = [v for pattern, vs in OWN if re.search(pattern, f) for v in vs]
        if owners:
            need.update(owners)
        elif OTHER_TOOLS.search(f):
            continue
        elif SHARED.search(f):
            return list(ALL)
    return [v for v in ALL if v in need]


if __name__ == "__main__":
    if os.environ.get("ELEBLORB_HOOK_ALL") == "1":
        print("\n".join(ALL))
        sys.exit(0)
    if len(sys.argv) == 3:   # for testing: changed_villages.py <from> <to>
        out = git("diff", "--name-only", sys.argv[1], sys.argv[2])
        files = set(out.stdout.split()) if out.returncode == 0 else None
    else:
        files = changed_files(sys.stdin.read().splitlines())
    print("\n".join(villages_for(files)))
