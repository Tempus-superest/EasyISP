#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION_FILE="$REPO_ROOT/EasyISP.version"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Error: $VERSION_FILE not found" >&2
  exit 1
fi

read -r major minor patch < <(python3 - "$VERSION_FILE" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    content = path.read_text()
except FileNotFoundError:
    sys.exit(f"Error: {path} does not exist")
except OSError as exc:
    sys.exit(f"Error reading {path}: {exc}")

try:
    data = json.loads(content)
except json.JSONDecodeError as exc:
    sys.exit(f"Error: invalid JSON in {path}: {exc}")

version = data.get("VERSION")
if not isinstance(version, dict):
    sys.exit("Error: VERSION object missing or malformed in EasyISP.version")

parts = []
for key in ("MAJOR", "MINOR", "PATCH"):
    value = version.get(key)
    if value is None:
        sys.exit(f"Error: VERSION.{key} missing in EasyISP.version")
    if not isinstance(value, int):
        sys.exit(f"Error: VERSION.{key} must be an integer")
    if value < 0:
        sys.exit(f"Error: VERSION.{key} must be a non-negative integer")
    parts.append(str(value))

print(" ".join(parts))
PY
)

if [[ -z "${major:-}" || -z "${minor:-}" || -z "${patch:-}" ]]; then
  echo "Error: could not parse version components" >&2
  exit 1
fi

VERSION="${major}.${minor}.${patch}"
TAG="v${VERSION}"

emit_value() {
  local label="$1" value="$2"
  echo "$label=$value"
  if [[ -n "${GITHUB_OUTPUT-}" ]]; then
    printf '%s=%s\n' "$label" "$value" >> "$GITHUB_OUTPUT"
  fi
}

emit_value "VERSION" "$VERSION"
emit_value "TAG" "$TAG"
