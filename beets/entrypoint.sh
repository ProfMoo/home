#!/bin/sh

# Print list of available commands
beet --help

# Import downloaded music
beet -v import /downloads

# Fetch artwork if it's available
beet fetchart

# Embed the artwork into the metadata of the file
beet embedart

sleep 100
