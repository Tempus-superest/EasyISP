#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$REPO_ROOT/VERSION"
EASYISP_VERSION_FILE="$REPO_ROOT/EasyISP.version"
README_FILE="$REPO_ROOT/README.md"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Error: $VERSION_FILE not found" >&2
  exit 1
fi
if [[ ! -f "$EASYISP_VERSION_FILE" ]]; then
  echo "Error: $EASYISP_VERSION_FILE not found" >&2
  exit 1
fi
if [[ ! -f "$README_FILE" ]]; then
  echo "Error: $README_FILE not found" >&2
  exit 1
fi

TAG="$(tr -d '\r\n' < "$VERSION_FILE")"
if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: VERSION must match ^v[0-9]+\\.[0-9]+\\.[0-9]+$, got '$TAG'" >&2
  exit 1
fi

VERSION="${TAG#v}"
DOWNLOAD_URL="https://github.com/Tempus-superest/EasyISP/releases/tag/$TAG"

python3 - "$EASYISP_VERSION_FILE" "$VERSION" "$DOWNLOAD_URL" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
version = sys.argv[2]
download_url = sys.argv[3]

parts = version.split(".")
if len(parts) != 3:
    raise SystemExit(f"Error: expected X.Y.Z version, got {version}")
try:
    major, minor, patch = (int(part) for part in parts)
except ValueError as exc:
    raise SystemExit(f"Error: version must be numeric, got {version}: {exc}")
if major < 0 or minor < 0 or patch < 0:
    raise SystemExit(f"Error: version parts must be non-negative, got {version}")

try:
    data = json.loads(path.read_text())
except Exception as exc:
    raise SystemExit(f"Error: failed to parse {path}: {exc}")

version_obj = data.get("VERSION")
if not isinstance(version_obj, dict):
    raise SystemExit("Error: EasyISP.version missing VERSION object")

version_obj["MAJOR"] = major
version_obj["MINOR"] = minor
version_obj["PATCH"] = patch
data["DOWNLOAD"] = download_url

path.write_text(json.dumps(data, indent=4) + "\n")
PY

python3 - "$README_FILE" "$TAG" "$DOWNLOAD_URL" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
tag = sys.argv[2]
download_url = sys.argv[3]
text = path.read_text()

pattern = re.compile(
    r"^Current Version - \[v[0-9]+\.[0-9]+\.[0-9]+\]\(https://github\.com/Tempus-superest/EasyISP/releases/tag/v[0-9]+\.[0-9]+\.[0-9]+\)$",
    re.MULTILINE,
)
matches = list(pattern.finditer(text))
if len(matches) != 1:
    raise SystemExit(
        f"Error: expected exactly one Current Version line in README.md, found {len(matches)}"
    )

replacement = f"Current Version - [{tag}]({download_url})"
updated = pattern.sub(replacement, text, count=1)
path.write_text(updated)
PY

echo "Synced EasyISP.version and README.md for $TAG"
