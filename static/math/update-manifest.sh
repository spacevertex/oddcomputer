#!/usr/bin/env bash
# Scans the patterns folder for .json files not yet listed in manifest.json,
# prompts for a display name for each, and writes the updated manifest.
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

known_files = {entry.get("file") for entry in manifest if isinstance(entry, dict)}

all_json = sorted(
    f for f in os.listdir(folder)
    if f.endswith(".json") and f != "manifest.json"
)

# flag manifest entries pointing at files that no longer exist — doesn't
# fix them (might be intentional, might be a rename), just surfaces it
orphaned = sorted(known_files - set(all_json))
if orphaned:
    print("Note: these manifest entries don't match any file currently in the folder:")
    for f in orphaned:
        print(f"  - {f}")
    print()

missing = [f for f in all_json if f not in known_files]

if not missing:
    print("Every JSON file in the folder is already represented in manifest.json. Nothing to add.")
    sys.exit(0)

print(f"Found {len(missing)} file(s) not yet in manifest.json:\n")

new_entries = []
for filename in missing:
    while True:
        name = input(f'  {filename}\n  Display name (blank = use filename): ').strip()
        if name == "":
            name = filename
        confirm = input(f'  -> "{name}"   [Enter to accept, r to redo] ').strip().lower()
        if confirm != 'r':
            break
    new_entries.append({"file": filename, "name": name})
    print()

manifest.extend(new_entries)
manifest.sort(key=lambda e: e.get("file", ""))

with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")

plural = "y" if len(new_entries) == 1 else "ies"
print(f"Added {len(new_entries)} entr{plural} to manifest.json.")
PYEOF

python3 "$TMP_PY" "$DIR"
