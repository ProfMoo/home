#!/bin/sh

echo '[entrypoint.sh] Printing beets help page to display list of available commands (helps ensure plugins are enabled)'
beet --help

echo '[entrypoint.sh] Continuously importing music files'
while true
do
    echo '[entrypoint.sh] Running beets import'
    beet import /downloads

    echo '[entrypoint.sh] Running beets move in case there is new configuration that needs to be backported, or there are duplicates recently added that need to be disambiguated.'
    beet move

    echo '[entrypoint.sh] Running beets update in case there are any metadata updates'
    beet update

    echo '[entrypoint.sh] Sleeping...'
    sleep 100
done
