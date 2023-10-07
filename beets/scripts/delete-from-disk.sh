#!/bin/sh

# Script to assist in deleting a release entirely from disk (rather than just from the beets DB).
# The script will ask you for a confirmation before deleting from disk permanently.
# How to use:
#   ./delete-from-disk.sh "<release_id>"
#
# To get the release ID, you can use the disambig.sh script

beet rm -a id:$1 -d
