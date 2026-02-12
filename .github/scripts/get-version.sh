#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION_FILE="$REPO_ROOT/VERSION"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Error: $VERSION_FILE not found" >&2
  exit 1
fi

TAG="$(tr -d '\r\n' < "$VERSION_FILE")"
if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: VERSION must match ^v[0-9]+\\.[0-9]+\\.[0-9]+$, got '$TAG'" >&2
  exit 1
fi

VERSION="${TAG#v}"

emit_value() {
  local label="$1" value="$2"
  echo "$label=$value"
  if [[ -n "${GITHUB_OUTPUT-}" ]]; then
    printf '%s=%s\n' "$label" "$value" >> "$GITHUB_OUTPUT"
  fi
}

emit_value "VERSION" "$VERSION"
emit_value "TAG" "$TAG"
