#!/bin/bash

# NOTE: This gets the directory of this bash script
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Reassigning all the inputs from qBittorrent to a human-readable name
TORRENT_NAME=$1
echo "TORRENT_NAME: $TORRENT_NAME"

CATEGORY=$2
echo "CATEGORY: $CATEGORY"

TAGS=$3
echo "TAGS: $TAGS"

CONTENT_PATH=$4
echo "CONTENT_PATH: $CONTENT_PATH"

ROOT_PATH=$5
echo "ROOT_PATH: $ROOT_PATH"

SAVE_PATH=$6
echo "SAVE_PATH: $SAVE_PATH"

NUMBER_OF_FILES=$7
echo "NUMBER_OF_FILES: $NUMBER_OF_FILES"

TORRENT_SIZE=$8
echo "TORRENT_SIZE: $TORRENT_SIZE"

CURRENT_TRACKER=$9
echo "CURRENT_TRACKER: $CURRENT_TRACKER"

INFO_HASH_V1="${10}"
echo "INFO_HASH_V1: $INFO_HASH_V1"

INFO_HASH_V2="${11}"
echo "INFO_HASH_V2: $INFO_HASH_V2"

TORRENT_ID="${12}"
echo "TORRENT_ID: $TORRENT_ID"

echo "[post_download]: Tag(s) of torrent: ${TAGS}"

echo "[post_download]: Ensuring dependencies are installed..."

source $DIR/download_dependencies.sh

echo "[post_download]: Done downloading dependencies."

echo "[post_download]: Running post-download scripts..."

if [[ "$TAGS" == *"movies"* ]] || [[ "$SAVE_PATH" == *"movies"* ]]; then
    echo "[post_download]: Torrent is category 'movie'. No post-download scripts for 'movies'"
elif [[ "$TAGS" == *"tv"* ]] || [[ "$SAVE_PATH" == *"tv"* ]]; then
    echo "[post_download]: Torrent is category 'tv'. No post-download scripts for 'tv'"
elif [[ "$TAGS" == *"books"* ]] || [[ "$SAVE_PATH" == *"books"* ]]; then
    echo "[post_download]: Torrent is category 'books'. No post-download scripts for 'books'"
elif [[ "$TAGS" == *"music"* ]] || [[ "$SAVE_PATH" == *"music"* ]]; then
    echo "[post_download]: Torrent is category 'music'. Running post-download scripts for 'music'"
    source $DIR/gazelle_origin.sh "${ROOT_PATH}" "${INFO_HASH_V1}" "${CURRENT_TRACKER}"
    source $DIR/betanin.sh "${ROOT_PATH}"
else
    echo "[post_download]: No recognizable torrent category. Not running any post-download scripts..."
fi

echo "[post_download]: Done."
