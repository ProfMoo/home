#!/bin/sh

echo '[ENTRYPOINT SCRIPT] Printing beets help page to display list of available commands (helps ensure plugins are enabled)'
beet --help

echo '[ENTRYPOINT SCRIPT] Continuously importing music files'

while true
do
    echo '[ENTRYPOINT SCRIPT] Running beets import'
    beet import /downloads

    echo '[ENTRYPOINT SCRIPT] Running beets move in case there is new configuration that needs to be backported, or there are duplicates recently added that need to be disambiguated.'
    beet move

    echo '[ENTRYPOINT SCRIPT] Running beets update in case there are any metadata updates'
    beet update

    echo '[ENTRYPOINT SCRIPT] Sleeping for 100 seconds...'
    sleep 100
done
