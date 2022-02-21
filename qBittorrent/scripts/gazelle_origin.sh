#!/bin/bash

# NOTE: This post-download script has been moved to a separate file (rather than being in the qBittorrent config directly)
# to provide a more familiar testing/development environment

# This scripts assumes that both ORIGIN_TRACKER and RED_API_KEY environment variables are configured correctly
# For more info about these variable, refer here: https://github.com/x1ppy/gazelle-origin#installation

# Converting bash script inputs into readable env vars
TRACKER_FILE=$1
ROOT_PATH=$2
INFO_HASH=$3

NAME_OF_FILE="origin.yaml"

echo "[gazelle_origin]: Downloading '$NAME_OF_FILE' file into '$ROOT_PATH', populated with info from $ORIGIN_TRACKER tracker"
gazelle-origin --tracker $TRACKER_FILE --out "$ROOT_PATH/$NAME_OF_FILE" $INFO_HASH
echo "[gazelle_origin]: Done. Exiting script..."
