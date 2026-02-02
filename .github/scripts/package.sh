#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: $0 --version X.Y.Z
       VERSION can also be provided via the VERSION environment variable.
USAGE
  exit 1
}

VERSION_ARG=""
while (( "$#" )); do
  case "$1" in
    --version)
      shift
      if [[ $# -eq 0 || -z "$1" ]]; then
        echo "Error: --version requires a value" >&2
        usage
      fi
      VERSION_ARG="$1"
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Error: unknown argument $1" >&2
      usage
      ;;
  esac
done

VERSION="${VERSION_ARG:-${VERSION:-}}"
if [[ -z "$VERSION" ]]; then
  echo "Error: VERSION is required" >&2
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST_FILE="$REPO_ROOT/release-manifest.txt"
if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "Error: release-manifest.txt not found in repository root" >&2
  exit 1
fi

DIST_ROOT="$REPO_ROOT/dist"
DEST_ROOT="$DIST_ROOT/GameData/EasyISP"
rm -rf "$DIST_ROOT"
mkdir -p "$DEST_ROOT"

paths=()
while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="$raw"
  line="${line//$'\r'/}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
    continue
  fi
  paths+=("$line")
done < "$MANIFEST_FILE"

if [[ ${#paths[@]} -eq 0 ]]; then
  echo "Error: release-manifest.txt does not list any files" >&2
  exit 1
fi

for relative in "${paths[@]}"; do
  if [[ "${relative:0:1}" == "/" ]]; then
    echo "Error: manifest paths must be relative, got $relative" >&2
    exit 1
  fi
  source_path="$REPO_ROOT/$relative"
  if [[ ! -e "$source_path" ]]; then
    echo "Error: manifest path missing: $relative" >&2
    exit 1
  fi
  dest_path="$DEST_ROOT/$relative"
  mkdir -p "$(dirname "$dest_path")"
  cp -a -- "$source_path" "$dest_path"
done

ZIP_NAME="EasyISP-v${VERSION}.zip"
ZIP_PATH="$REPO_ROOT/$ZIP_NAME"
if [[ -f "$ZIP_PATH" ]]; then
  rm -f "$ZIP_PATH"
fi

(
  cd "$DIST_ROOT"
  zip -r "$ZIP_PATH" GameData
)

echo "Created release archive: $ZIP_PATH"
