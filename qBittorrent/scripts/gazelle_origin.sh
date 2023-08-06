#!/bin/bash

# NOTE: This post-download script has been moved to a separate file (rather than being in the qBittorrent config directly)
# to provide a more familiar testing/development environment

# This scripts assumes that both RED_API_KEY and OPS_SESSION_COOKIE environment variables are configured correctly
# For more info about these variables, refer here: https://github.com/x1ppy/gazelle-origin#installation

# Converting bash script inputs into readable env vars
ROOT_PATH=$1
echo "ROOT_PATH: $ROOT_PATH"
INFO_HASH=$2
echo "INFO_HASH: $INFO_HASH"
CURRENT_TRACKER_OR_CAT=$3
echo "CURRENT_TRACKER_OR_CAT: $CURRENT_TRACKER_OR_CAT"
ROOT_BASE=`basename "$1"`
echo "ROOT_BASE: $ROOT_BASE"

if [[ $CURRENT_TRACKER_OR_CAT != "" ]]; then
  if [[ "$CURRENT_TRACKER_OR_CAT" == *"flacsfor.me"* || "$CURRENT_TRACKER_OR_CAT" == *"RED"* ]]; then
    echo "[gazelle_origin]: Grabbing torrent info for $ROOT_BASE from RED."
    gazelle-origin -t red -o "$ROOT_PATH"/origin.yaml --api-key $RED_API_KEY $INFO_HASH
    echo "[gazelle origin]: Finished grabbing torrent info for '$ROOT_BASE' from RED."
  else
    echo "[gazelle_origin]: No match on '$ROOT_BASE' with category/tracker of '$CURRENT_TRACKER_OR_CAT'. Load again in a matching category, or redownload live, to reprocess."
  fi
else
  echo "No matches on '$ROOT_BASE' (category and tracker are both blank). Load again in a matching category, or redownload live, to reprocess."
fi
