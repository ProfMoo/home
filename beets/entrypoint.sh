#!/bin/sh

# Import downloaded music
beet -v import /downloads

# Fetch artwork if it's available
beet fetchart

# Embed the artwork into the metadata of the file
beet embedart

# List the music (and other files) that aren't imported
beet unimported

sleep 100
