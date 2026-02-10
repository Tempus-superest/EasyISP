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

password_encoded="$SPACEDOCK_PASSWORD"
login_mode="raw"
encoded_try="$(printf '%s' "$SPACEDOCK_PASSWORD" | jq -sRr @uri 2>/dev/null || true)"
if [ -n "$encoded_try" ]; then
  password_encoded="$encoded_try"
  login_mode="encoded"
fi
if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  echo "::add-mask::$SPACEDOCK_USERNAME"
  echo "::add-mask::$SPACEDOCK_PASSWORD"
  if [ "$login_mode" = "encoded" ]; then
    echo "::add-mask::$password_encoded"
  fi
fi

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
user_agent="EasyISP-Spacedock-Native/${GITHUB_REPOSITORY:-local}"

echo "Logging in to SpaceDock API..."
login_curl_exit=0
login_http=""
login_error="unknown"
login_reason="none"
run_login() {
  local password_value="$1"
  curl -sS -o "$login_json" -w "%{http_code}" \
    -A "$user_agent" \
    -c "$cookies" \
    --form-string "username=$SPACEDOCK_USERNAME" \
    --form-string "password=$password_value" \
    "$base_url/api/login"
}
parse_login_json() {
  login_error="$(
    jq -r '.error // "unknown"' "$login_json" 2>/dev/null \
      | tr -d '\r\n' \
      | tr '[:upper:]' '[:lower:]' \
      || true
  )"
  login_error="${login_error:-unknown}"
  login_reason="$(
    jq -r '.reason // "none"' "$login_json" 2>/dev/null \
      | sanitize_reason \
      || true
  )"
  login_reason="${login_reason:-none}"
}
login_succeeded() {
  [ "$login_curl_exit" -eq 0 ] && [ "$login_http" = "200" ] && [ "$login_error" = "false" ]
}

login_http="$(run_login "$password_encoded")" || login_curl_exit=$?
parse_login_json

if ! login_succeeded && [ "$login_mode" != "raw" ]; then
  login_mode="raw"
  login_curl_exit=0
  login_http="$(run_login "$SPACEDOCK_PASSWORD")" || login_curl_exit=$?
  parse_login_json
fi

if ! login_succeeded; then
  if [ "$login_curl_exit" -ne 0 ]; then
    echo "SpaceDock API login failed (transport curl_exit_${login_curl_exit}, login_mode=$login_mode)." >&2
  else
    echo "SpaceDock API login failed (HTTP $login_http, login_mode=$login_mode): $login_reason" >&2
  fi
  exit 1
fi

echo "Fetching latest SpaceDock game version for game_id=$SPACEDOCK_GAME_ID..."
versions_http="$(
  curl -sS -o "$versions_json" -w "%{http_code}" \
    -A "$user_agent" \
    "$base_url/api/$SPACEDOCK_GAME_ID/versions"
)"

latest_game_version="$(jq -r '.[0].friendly_version // empty' "$versions_json" 2>/dev/null || true)"
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

update_error="$(jq -r '.error // "unknown"' "$update_json" 2>/dev/null | tr -d '\r\n' || true)"
update_error="${update_error:-unknown}"
update_reason="$(jq -r '.reason // "none"' "$update_json" 2>/dev/null | sanitize_reason || true)"
update_reason="${update_reason:-none}"

if [ "$update_http" != "200" ] || [ "$update_error" != "false" ]; then
  echo "SpaceDock upload failed (HTTP $update_http): $update_reason" >&2
  exit 1
fi

echo "SpaceDock upload succeeded."
