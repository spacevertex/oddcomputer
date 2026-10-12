#!/usr/bin/env bash
# Scans the patterns folder — including nested subfolders, to any depth —
# for .json files not yet listed in manifest.json, prompts for a display
# name for each, and writes the updated manifest. Subfolder names are
# used directly as the GUI folder names; only individual files get
# prompted for a name.
#
# Usage:
#   ./update-manifest.sh              # operates on the current directory
#   ./update-manifest.sh patterns/    # or point it at a specific folder
set -euo pipefail

DIR="${1:-.}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "This script needs python3 (used for the actual JSON reading/writing)." >&2
  exit 1
fi

if [ ! -d "$DIR" ]; then
  echo "No such directory: $DIR" >&2
  exit 1
fi

if [ ! -f "$DIR/manifest.json" ]; then
  echo "[]" > "$DIR/manifest.json"
  echo "No manifest.json found in $DIR — created an empty one."
fi

TMP_PY="$(mktemp -t update-manifest.XXXXXX.py)"
trap 'rm -f "$TMP_PY"' EXIT

cat > "$TMP_PY" <<'PYEOF'
import json, os, sys

folder = sys.argv[1]
manifest_path = os.path.join(folder, "manifest.json")

try:
    with open(manifest_path) as f:
        manifest = json.load(f)
    if not isinstance(manifest, list):
        raise ValueError("manifest.json does not contain a JSON array")
except (json.JSONDecodeError, ValueError) as e:
    print(f"manifest.json is present but not valid: {e}", file=sys.stderr)
    sys.exit(1)

# Two kinds of entries, and folders can now nest arbitrarily deep:
#   {"file": "...", "name": "..."}
#   {"folder": "...", "items": [ ...more entries, recursively... ]}
# On-disk folder names ARE the GUI folder names — only individual files
# get prompted for a display name, at any depth.

def get_known_files(items):
    return {e["file"] for e in items if "file" in e}

def get_known_folders(items):
    return {e["folder"]: e for e in items if "folder" in e}

def prompt_name(filename, prefix=""):
    while True:
        label = prefix + filename
        name = input(f'  {label}\n  Display name (blank = use filename): ').strip()
        if name == "":
            name = filename
        confirm = input(f'  -> "{name}"   [Enter to accept, r to redo] ').strip().lower()
        if confirm != 'r':
            return name
        print()

def find_orphans(disk_path, items, rel_path=""):
    orphans = []
    disk_entries = set(os.listdir(disk_path)) if os.path.isdir(disk_path) else set()
    for entry in items:
        if "file" in entry:
            if entry["file"] not in disk_entries:
                orphans.append((rel_path + "/" + entry["file"]) if rel_path else entry["file"])
        elif "folder" in entry:
            sub_disk = os.path.join(disk_path, entry["folder"])
            sub_rel = (rel_path + "/" + entry["folder"]) if rel_path else entry["folder"]
            if not os.path.isdir(sub_disk):
                orphans.append(sub_rel + "/  (entire folder missing)")
            else:
                orphans.extend(find_orphans(sub_disk, entry.get("items", []), sub_rel))
    return orphans

def scan_and_update(disk_path, items, rel_path=""):
    added = 0

    disk_files = sorted(
        f for f in os.listdir(disk_path)
        if f.endswith(".json") and f != "manifest.json" and os.path.isfile(os.path.join(disk_path, f))
    )
    known_files = get_known_files(items)
    for filename in [f for f in disk_files if f not in known_files]:
        prefix = (rel_path + "/") if rel_path else ""
        name = prompt_name(filename, prefix=prefix)
        items.append({"file": filename, "name": name})
        added += 1
        print()

    disk_subdirs = sorted(
        d for d in os.listdir(disk_path)
        if os.path.isdir(os.path.join(disk_path, d))
    )
    known_folders = get_known_folders(items)
    for subdir in disk_subdirs:
        entry = known_folders.get(subdir)
        if entry is None:
            entry = {"folder": subdir, "items": []}
            items.append(entry)
        else:
            entry.setdefault("items", [])
        added += scan_and_update(
            os.path.join(disk_path, subdir),
            entry["items"],
            (rel_path + "/" + subdir) if rel_path else subdir
        )

    return added

orphans = find_orphans(folder, manifest, "")
if orphans:
    print("Note: these manifest entries don't match anything currently on disk:")
    for o in orphans:
        print(f"  - {o}")
    print()

added = scan_and_update(folder, manifest, "")

if added == 0:
    print("Every JSON file is already represented in manifest.json. Nothing to add.")
    sys.exit(0)

def sort_recursive(items):
    for entry in items:
        if "items" in entry:
            sort_recursive(entry["items"])
    items.sort(key=lambda e: (0, e["folder"]) if "folder" in e else (1, e["file"]))

sort_recursive(manifest)

with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")

plural = "y" if added == 1 else "ies"
print(f"Added {added} entr{plural} to manifest.json.")
PYEOF

python3 "$TMP_PY" "$DIR"
