#!/bin/bash

# NOTE: This post-download script has been moved to a separate file (rather than being in the qBittorrent config directly)
# to provide a more familiar testing/development environment

# This scripts assumes that both RED_API_KEY and OPS_SESSION_COOKIE environment variables are configured correctly
# For more info about these variables, refer here: https://github.com/x1ppy/gazelle-origin#installation

# Converting bash script inputs into readable env vars
TRACKER=$1
ROOT_PATH=$2
INFO_HASH=$3

OUTPUT_FILE="origin.yaml"

echo "[gazelle_origin]: Creating '$OUTPUT_FILE' file in '$ROOT_PATH', populated with info pulled from $TRACKER tracker"
gazelle-origin --tracker $TRACKER --out "$ROOT_PATH/$OUTPUT_FILE" $INFO_HASH
echo "[gazelle_origin]: Done. Exiting script..."

ROOT_PATH=$1
INFO_HASH=$2
CURRENT_TRACKER_OR_CAT=$3
ROOT_BASE=`basename "$1"`

if [[ $CURRENT_TRACKER_OR_CAT != "" ]]; then
  if [[ "$CURRENT_TRACKER_OR_CAT" == *"flacsfor.me"* || "$CURRENT_TRACKER_OR_CAT" == *"RED"* ]]; then
    gazelle-origin -t red -o "$ROOT_PATH"/origin.yaml --api-key $RED_API_KEY $INFO_HASH
    echo "Grabbing torrent info for $ROOT_BASE from RED."
  else
    echo "No match on $ROOT_BASE with category/tracker of $CURRENT_TRACKER_OR_CAT. Load again in a matching category, or redownload live, to reprocess."
  fi
else
  echo "No matches on $ROOT_BASE as category and tracker are both blank. Load again in a matching category, or redownload live, to reprocess."
fi
