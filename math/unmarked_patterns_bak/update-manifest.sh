#!/usr/bin/env bash
# Scans the patterns folder — including nested subfolders, to any depth —
# for .json files not yet listed in manifest.json, adds them, and writes
# the updated manifest. No prompts: every pattern's display name is its
# filename without the .json suffix (osc_n5_b0_Pip_p100.json -> 
# osc_n5_b0_Pip_p100), and existing entries are renamed to match, so the
# Zoo always shows the filenames. To change a name, rename the file.
# Subfolder names are used directly as the Zoo's folder names.
#
# Usage (keep this script inside the patterns folder):
#   ./update-manifest.sh              # scans the folder this script lives in,
#                                     # no matter where you run it from
#   ./update-manifest.sh some/folder/ # or point it at a specific folder
#   ./update-manifest.sh -f           # fresh: ignore the current manifest and
#                                     # rebuild it from scratch from what's on disk

# If started with `sh update-manifest.sh`, sh may not be bash and would
# choke on the line below; quietly re-run ourselves under bash instead.
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRESH=0
DIR=""
for arg in "$@"; do
  case "$arg" in
    -f|--fresh) FRESH=1 ;;
    -*) echo "Unknown option: $arg  (the only option is -f)" >&2; exit 1 ;;
    *) DIR="$arg" ;;
  esac
done
DIR="${DIR:-$SCRIPT_DIR}"
echo "Scanning: $DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "This script needs python3 (used for the actual JSON reading/writing)." >&2
  exit 1
fi

if [ ! -d "$DIR" ]; then
  echo "No such directory: $DIR" >&2
  exit 1
fi

if [ "$FRESH" = 1 ]; then
  echo "Fresh run: rebuilding manifest.json from scratch."
  echo "[]" > "$DIR/manifest.json"
elif [ ! -f "$DIR/manifest.json" ]; then
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

def display_name(filename):
    return filename[:-5] if filename.lower().endswith(".json") else filename

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
        items.append({"file": filename, "name": display_name(filename)})
        print(f"  + {(rel_path + '/') if rel_path else ''}{filename}")
        added += 1

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

before = json.dumps(manifest, sort_keys=True)
added = scan_and_update(folder, manifest, "")

# every file entry, old or new, is named after its file
def rename_all(items):
    renamed = 0
    for entry in items:
        if "file" in entry:
            want = display_name(entry["file"])
            if entry.get("name") != want:
                entry["name"] = want
                renamed += 1
        elif "folder" in entry:
            renamed += rename_all(entry.get("items", []))
    return renamed
renamed = rename_all(manifest)

def sort_recursive(items):
    for entry in items:
        if "items" in entry:
            sort_recursive(entry["items"])
    items.sort(key=lambda e: (0, e["folder"]) if "folder" in e else (1, e["file"]))

sort_recursive(manifest)

if json.dumps(manifest, sort_keys=True) == before:
    print("manifest.json is already up to date. Nothing changed.")
    sys.exit(0)

with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")

plural = lambda n, one, many: one if n == 1 else many
print(f"Added {added} {plural(added, 'entry', 'entries')}, renamed {renamed} to match {plural(renamed, 'its filename', 'their filenames')}.")
PYEOF

python3 "$TMP_PY" "$DIR"
