#!/bin/bash

# NOTE: This post-download script has been moved to a separate file (rather than being in the qBittorrent config directly)
# to provide a more familiar testing/development environment

# This scripts assumes that both RED_API_KEY and OPS_SESSION_COOKIE environment variables are configured correctly
# For more info about these variable, refer here: https://github.com/ProfMoo/gazelle-origin#installation

# Converting bash script inputs into readable env vars
TRACKER=$1
ROOT_PATH=$2
INFO_HASH=$3

OUTPUT_FILE="origin.yaml"

echo "[gazelle_origin]: Creating '$OUTPUT_FILE' file in '$ROOT_PATH', populated with info pulled from $TRACKER tracker"
gazelle-origin --tracker $TRACKER --out "$ROOT_PATH/$OUTPUT_FILE" $INFO_HASH
echo "[gazelle_origin]: Done. Exiting script..."
