#!/bin/bash

PATH=$1
echo "[betanin]: PATH: $PATH"

echo "[betanin]: Adding new torrent '$PATH' to betanin queue..."

echo "[betanin]: Running curl against betanin..."

# NOTE: For some reason I need to specify the full path for curl to work here
# OK with adding an API Key here for now since it's only an API Key for a process running on local network (not exposed publicly)
if ! /usr/bin/curl --request POST --data-urlencode "both=$PATH" --header "X-API-Key: f3d5a5a95fad096470ca411eb41161fb" http://betanin.media.svc.cluster.local:9393/api/torrents; then
	echo "[betanin]: Adding new torrent '$PATH' to betanin queue failed."
else
	echo "[betanin]: Adding new torrent '$PATH' to betanin queue succeeded."
fi
