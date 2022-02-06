#!/bin/sh

echo 'Printing beets help page to display list of available commands (helps ensure plugins are enabled)'
beet --help

echo 'Running beets import'
beet import /downloads

echo 'Sleeping...'
sleep 100
