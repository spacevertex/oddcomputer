#!/usr/bin/env bash
# Scans a folder for .json pattern files and adds any not already listed
# in manifest.json to it. No naming step — bobo_3d.html derives each
# button's label straight from the filename, so there's nothing to ask.
# Existing entries and their order are left completely untouched; new
# files are appended to the end, alphabetically among themselves, so your
# own manual ordering in the manifest is never disturbed.
#
# Usage:
#   ./update-manifest-3d.sh              # operates on the current directory
#   ./update-manifest-3d.sh 3d_patterns/ # or point it at a specific folder
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

python3 - "$DIR" <<'PYEOF'
import json, os, sys

folder = sys.argv[1]
manifest_path = os.path.join(folder, "manifest.json")

try:
    with open(manifest_path) as f:
        manifest = json.load(f)
    if not isinstance(manifest, list) or not all(isinstance(x, str) for x in manifest):
        raise ValueError("manifest.json must be a flat JSON array of filenames")
except (json.JSONDecodeError, ValueError) as e:
    print(f"manifest.json is present but not valid: {e}", file=sys.stderr)
    sys.exit(1)

known = set(manifest)

all_json = sorted(
    f for f in os.listdir(folder)
    if f.endswith(".json") and f != "manifest.json" and os.path.isfile(os.path.join(folder, f))
)

# flag manifest entries with no matching file — doesn't remove them,
# just surfaces it (might be a rename, might be intentional)
orphaned = sorted(known - set(all_json))
if orphaned:
    print("Note: these manifest entries don't match any file currently in the folder:")
    for f in orphaned:
        print(f"  - {f}")
    print()

missing = sorted(f for f in all_json if f not in known)

if not missing:
    print("Every JSON file in the folder is already listed in manifest.json. Nothing to add.")
    sys.exit(0)

print(f"Adding {len(missing)} file(s) to manifest.json:")
for f in missing:
    print(f"  + {f}")

manifest.extend(missing)

with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")

plural = "y" if len(missing) == 1 else "ies"
print(f"\nAdded {len(missing)} entr{plural}. Existing order preserved; new entries appended at the end.")
PYEOF
