#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  download-mods.sh  —  Downloads enabled mods from the Factorio Mod Portal
#
#  Usage:
#    chmod +x download-mods.sh
#    ./download-mods.sh
#
#  Requirements:
#    - curl, jq
#    - FACTORIO_USERNAME and FACTORIO_TOKEN must be set in .env (or exported)
#
#  The script reads mod-list.json, filters enabled non-base mods, fetches the
#  latest compatible release from the portal, and downloads each .zip into
#  ./data/mods/.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Load .env if present ──────────────────────────────────────────────────────
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
fi

USERNAME="${FACTORIO_USERNAME:?Set FACTORIO_USERNAME in .env}"
TOKEN="${FACTORIO_TOKEN:?Set FACTORIO_TOKEN in .env}"
MOD_LIST="./data/mods/mod-list.json"
MOD_DIR="./data/mods"
PORTAL="https://mods.factorio.com"

# ── Detect Factorio version from the running container (or fallback) ──────────
FACTORIO_VERSION=$(docker compose exec -T factorio /factorio/bin/x64/factorio --version 2>/dev/null \
  | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "2.0")
FACTORIO_MAJOR=$(echo "$FACTORIO_VERSION" | cut -d. -f1,2)
echo "► Factorio version: $FACTORIO_VERSION (using $FACTORIO_MAJOR for mod compatibility)"

# ── Parse enabled mods ────────────────────────────────────────────────────────
MODS=$(jq -r '.mods[] | select(.enabled == true and .name != "base") | .name' "$MOD_LIST")

if [[ -z "$MODS" ]]; then
  echo "No enabled mods found in $MOD_LIST — nothing to download."
  exit 0
fi

echo "► Mods to download:"
echo "$MODS" | sed 's/^/   • /'

echo ""

# ── Download each mod ─────────────────────────────────────────────────────────
for MOD in $MODS; do
  echo -n "  ↓ $MOD … "

  # Fetch mod info from portal
  INFO=$(curl -sf "$PORTAL/api/mods/$MOD" || true)
  if [[ -z "$INFO" ]]; then
    echo "⚠  Not found on mod portal, skipping."
    continue
  fi

  # Find the latest release compatible with our major version
  RELEASE=$(echo "$INFO" | jq -r --arg ver "$FACTORIO_MAJOR" \
    '[.releases[] | select(.info_json.factorio_version == $ver)] | last')

  if [[ -z "$RELEASE" || "$RELEASE" == "null" ]]; then
    # Fall back to the absolute latest release
    RELEASE=$(echo "$INFO" | jq -r '.releases | last')
  fi

  FILE_NAME=$(echo "$RELEASE" | jq -r '.file_name')
  DOWNLOAD_URL=$(echo "$RELEASE" | jq -r '.download_url')
  MOD_VERSION=$(echo "$RELEASE" | jq -r '.version')

  if [[ -f "$MOD_DIR/$FILE_NAME" ]]; then
    echo "already present (v$MOD_VERSION)."
    continue
  fi

  curl -sf -L -o "$MOD_DIR/$FILE_NAME" \
    "$PORTAL$DOWNLOAD_URL?username=$USERNAME&token=$TOKEN"

  echo "done (v$MOD_VERSION → $FILE_NAME)."
done

echo ""
echo "✔  All mods downloaded to $MOD_DIR"
echo "   Restart the server to apply: docker compose restart factorio"
