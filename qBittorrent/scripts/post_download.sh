#!/bin/bash

# NOTE: This gets the directory of this bash script
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[post_download]: Running post-download scripts..."

source $DIR/gazelle_origin.sh "$5" "$10" "$9" "$2"
source $DIR/betanin.sh "$5"

echo "[post_download]: Completed post-download scripts."
