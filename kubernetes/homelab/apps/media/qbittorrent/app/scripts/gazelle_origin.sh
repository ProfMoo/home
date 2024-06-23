#!/bin/bash

# NOTE: This post-download script has been moved to a separate file (rather than being in the qBittorrent config directly)
# to provide a more familiar testing/development environment

# This scripts assumes that both RED_API_KEY and OPS_SESSION_COOKIE environment variables are configured correctly
# For more info about these variables, refer here: https://github.com/ProfMoo/gazelle-origin#installation

# Converting bash script inputs into readable env vars

ROOT_PATH=$1
echo "[gazelle_origin]: ROOT_PATH: $ROOT_PATH"

INFO_HASH=$2
echo "[gazelle_origin]: INFO_HASH: $INFO_HASH"

CURRENT_TRACKER_OR_CAT=$3
# NOTE: Not printing this because it could contain secret announce URL

ROOT_BASE=$(basename "$ROOT_PATH")
echo "[gazelle_origin]: ROOT_BASE: $ROOT_BASE"

if [[ $CURRENT_TRACKER_OR_CAT != "" ]]; then
  if [[ "$CURRENT_TRACKER_OR_CAT" == *"flacsfor.me"* || "$CURRENT_TRACKER_OR_CAT" == *"RED"* ]]; then
    echo "[gazelle_origin]: Grabbing torrent info for '${ROOT_BASE}' from RED..."

    if ! gazelle-origin -t red -o "$ROOT_PATH"/origin.yaml --api-key $RED_API_KEY "${INFO_HASH}"; then
      echo "[gazelle_origin]: Grabbing torrent info for '${ROOT_BASE}' from RED failed."
    else
      echo "[gazelle_origin]: Grabbing torrent info for '${ROOT_BASE}' from RED succeeded."
    fi

  elif [[ "$CURRENT_TRACKER_OR_CAT" == *"opsfet.ch"* || "$CURRENT_TRACKER_OR_CAT" == *"ORP"* ]]; then
    echo "[gazelle_origin]: Grabbing torrent info for '${ROOT_BASE}' from OPS..."

    if ! gazelle-origin -t ops -o "$ROOT_PATH"/origin.yaml --api-key "${OPS_SESSION_COOKIE}" "${INFO_HASH}"; then
      echo "[gazelle_origin]: Grabbing torrent info for '${ROOT_BASE}' from OPS failed."
    else
      echo "[gazelle_origin]: Grabbing torrent info for '${ROOT_BASE}' from OPS succeeded."
    fi

  else
    echo "[gazelle_origin]: No match on download '$ROOT_PATH' with category/tracker of '$CURRENT_TRACKER_OR_CAT'. Load again in a matching category, or redownload live, to reprocess."
  fi
else
  echo "[gazelle_origin]: No matches on '$ROOT_PATH' (tracker environment variable is blank). Load again in a matching category, or redownload live, to reprocess."
fi
