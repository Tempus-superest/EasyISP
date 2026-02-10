#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  SPACEDOCK_USERNAME
  SPACEDOCK_PASSWORD
  SPACEDOCK_WEBSITE
  SPACEDOCK_MOD_ID
  SPACEDOCK_GAME_ID
  SPACEDOCK_VERSION
  SPACEDOCK_ZIPBALL
  SPACEDOCK_CHANGELOG_FILE
)

for var_name in "${required_vars[@]}"; do
  if [ -z "${!var_name:-}" ]; then
    echo "Missing required environment variable: $var_name" >&2
    exit 1
  fi
done

if [ ! -f "$SPACEDOCK_ZIPBALL" ]; then
  echo "Zipball not found: $SPACEDOCK_ZIPBALL" >&2
  exit 1
fi

if [ ! -f "$SPACEDOCK_CHANGELOG_FILE" ]; then
  echo "Changelog file not found: $SPACEDOCK_CHANGELOG_FILE" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required but not installed" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed" >&2
  exit 1
fi

echo "::add-mask::$SPACEDOCK_USERNAME"
echo "::add-mask::$SPACEDOCK_PASSWORD"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cookies="$tmp_dir/cookies.txt"
login_json="$tmp_dir/login.json"
versions_json="$tmp_dir/versions.json"
update_json="$tmp_dir/update.json"

sanitize_reason() {
  tr '\r\n' ' ' | sed 's/[^[:print:]]/?/g'
}

base_url="${SPACEDOCK_WEBSITE%/}"
user_agent="EasyISP-Spacedock-Fallback/${GITHUB_REPOSITORY:-local}"

echo "Logging in to SpaceDock API (fallback uploader)..."
login_http="$(
  curl -sS -o "$login_json" -w "%{http_code}" \
    -A "$user_agent" \
    -c "$cookies" \
    -F "username=$SPACEDOCK_USERNAME" \
    -F "password=$SPACEDOCK_PASSWORD" \
    "$base_url/api/login"
)"

login_error="$(jq -r '.error // "unknown"' "$login_json" 2>/dev/null | tr -d '\r\n')"
login_reason="$(jq -r '.reason // "none"' "$login_json" 2>/dev/null | sanitize_reason)"

if [ "$login_http" != "200" ] || [ "$login_error" != "false" ]; then
  echo "SpaceDock API login failed in fallback uploader (HTTP $login_http): $login_reason" >&2
  exit 1
fi

echo "Fetching latest SpaceDock game version for game_id=$SPACEDOCK_GAME_ID..."
versions_http="$(
  curl -sS -o "$versions_json" -w "%{http_code}" \
    -A "$user_agent" \
    "$base_url/api/$SPACEDOCK_GAME_ID/versions"
)"

latest_game_version="$(jq -r '.[0].friendly_version // empty' "$versions_json" 2>/dev/null)"
if [ "$versions_http" != "200" ] || [ -z "$latest_game_version" ]; then
  echo "Could not determine latest game version (HTTP $versions_http)." >&2
  exit 1
fi

echo "Uploading update to SpaceDock mod_id=$SPACEDOCK_MOD_ID..."
update_http="$(
  curl -sS -o "$update_json" -w "%{http_code}" \
    -A "$user_agent" \
    -b "$cookies" \
    -F "version=$SPACEDOCK_VERSION" \
    -F "changelog=$(cat "$SPACEDOCK_CHANGELOG_FILE")" \
    -F "game-version=$latest_game_version" \
    -F "notify-followers=yes" \
    -F "zipball=@$SPACEDOCK_ZIPBALL" \
    "$base_url/api/mod/$SPACEDOCK_MOD_ID/update"
)"

update_error="$(jq -r '.error // "unknown"' "$update_json" 2>/dev/null | tr -d '\r\n')"
update_reason="$(jq -r '.reason // "none"' "$update_json" 2>/dev/null | sanitize_reason)"

if [ "$update_http" != "200" ] || [ "$update_error" != "false" ]; then
  echo "SpaceDock fallback upload failed (HTTP $update_http): $update_reason" >&2
  exit 1
fi

echo "SpaceDock fallback upload succeeded."
