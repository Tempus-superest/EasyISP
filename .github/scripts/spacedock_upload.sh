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

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  echo "::add-mask::$SPACEDOCK_USERNAME"
  echo "::add-mask::$SPACEDOCK_PASSWORD"
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cookies="$tmp_dir/cookies.txt"
login_json="$tmp_dir/login.json"
login_headers="$tmp_dir/login.headers"
login_metrics="$tmp_dir/login.metrics"
versions_json="$tmp_dir/versions.json"
update_json="$tmp_dir/update.json"

sanitize_reason() {
  tr '\r\n' ' ' | sed 's/[^[:print:]]/?/g'
}

base_url="${SPACEDOCK_WEBSITE%/}"
user_agent="EasyISP-Spacedock-Native/${GITHUB_REPOSITORY:-local}"

echo "Logging in to SpaceDock API..."
login_curl_exit=0
# Use --form-string so credentials are sent literally; -F can treat
# leading @/< as file syntax and break auth for edge-case secrets.
curl -sS -L -D "$login_headers" -o "$login_json" -w "%{http_code}\n%{url_effective}" \
  -A "$user_agent" \
  -c "$cookies" \
  --form-string "username=$SPACEDOCK_USERNAME" \
  --form-string "password=$SPACEDOCK_PASSWORD" \
  "$base_url/api/login" \
> "$login_metrics" || login_curl_exit=$?

login_http="$(sed -n '1p' "$login_metrics" | tr -d '\r\n' || true)"
login_http="${login_http:-000}"
final_url="$(sed -n '2p' "$login_metrics" | tr -d '\r\n' || true)"
final_url="${final_url:-$base_url/api/login}"

login_content_type="$(awk 'BEGIN{IGNORECASE=1} /^content-type:/ {sub(/\r$/,"",$0); sub(/^content-type:[[:space:]]*/,"",$0); last=$0} END{if (last!="") print last}' "$login_headers" || true)"
login_content_type="${login_content_type:-unknown}"

login_error="unknown"
login_reason="none"
is_json=false
case "$login_content_type" in
  application/json*|application/*+json*) is_json=true ;;
esac

if [ "$is_json" = true ]; then
  login_error_raw="$(jq -r '.error // "unknown"' "$login_json" 2>/dev/null || true)"
  login_reason_raw="$(jq -r '.reason // "none"' "$login_json" 2>/dev/null || true)"
  if [ -z "$login_error_raw" ] || [ "$login_error_raw" = "null" ]; then
    login_error="unknown"
    login_reason="jq_parse_failed"
  else
    login_error="$(printf '%s' "$login_error_raw" | tr -d '\r\n' | tr '[:upper:]' '[:lower:]')"
    login_reason="$(printf '%s' "${login_reason_raw:-none}" | sanitize_reason)"
    login_reason="${login_reason:-none}"
  fi
else
  login_reason="non_json_response"
fi

if [ "$login_curl_exit" -ne 0 ] || [ "$login_http" != "200" ] || [ "$login_error" != "false" ]; then
  if [ "$login_curl_exit" -ne 0 ]; then
    echo "SpaceDock API login failed (transport curl_exit_${login_curl_exit}, URL: $final_url)." >&2
  elif [ "$login_reason" = "non_json_response" ] || [ "$login_reason" = "jq_parse_failed" ]; then
    snippet="$(head -c 200 "$login_json" 2>/dev/null | tr '\r\n' ' ' | sed 's/[^[:print:]]/?/g' || true)"
    snippet="${snippet:-empty}"
    echo "SpaceDock API login failed (HTTP $login_http, Content-Type: $login_content_type, URL: $final_url): $login_reason" >&2
    echo "Response snippet: $snippet" >&2
  else
    echo "SpaceDock API login failed (HTTP $login_http, Content-Type: $login_content_type, URL: $final_url): $login_reason" >&2
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
