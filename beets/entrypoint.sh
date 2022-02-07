#!/bin/sh

echo '[ENTRYPOINT SCRIPT] Printing beets help page to display list of available commands (helps ensure plugins are enabled)'
beet --help

echo '[ENTRYPOINT SCRIPT] Continuously importing music files'
while true
do
    echo '[ENTRYPOINT SCRIPT] Running beets import'
    beet import /downloads

    echo '[ENTRYPOINT SCRIPT] Sleeping...'
    sleep 100
done
