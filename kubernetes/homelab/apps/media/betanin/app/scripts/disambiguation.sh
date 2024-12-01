#!/bin/sh

# Script to assist in disambiguating similar releases.
# How to use:
#   /scripts/disambiguation.sh "<release_name>"

beet ls album:"$1" -af 'id: $id path: $path | $albumartist - $album - $albumtype - $releasegroupdisambig - $albumdisambig - $label - $catalognum | (%aunique{})'
