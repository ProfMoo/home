#!/bin/sh

echo '[ENTRYPOINT SCRIPT] Printing beets help page to display list of available commands (helps ensure plugins are enabled)'
beet --help

echo '[ENTRYPOINT SCRIPT] Continuously importing music files'

# Uncomment this when you want to run manual imports
sleep 1000000

while true
do
    echo '[ENTRYPOINT SCRIPT] Running beets import'
    beet import -q /downloads

    echo '[ENTRYPOINT SCRIPT] Running beets move in case there is new configuration that needs to be backported, or there are duplicates recently added that need to be disambiguated.'
    beet move

    # Commenting this out until I understand why beet update continually updates the same info
    # echo '[ENTRYPOINT SCRIPT] Running beets update in case there are any metadata updates'
    # beet update

    echo '[ENTRYPOINT SCRIPT] Sleeping for 1000 seconds...'
    sleep 1000
done
