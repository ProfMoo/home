# qBittorrent

A docker container that runs a qBittorrent client with special configuration and conveniences. This installation is built with Red tracker in mind, but other Gazelle-based trackers are likely to work with little or no modifications.

## Features

* Auto-downloads when torrent files are placed in the directory
* Has reasonable defaults set for a seedbox (ex: allowing for unlimited files to be seeding at one time)
* Runs the `gazelle-origin` script automatically after download to generate the `origin.yaml` file, which provides `beets` additional and helpful info during the tagging process. To read more, refer to the `gazelle-origin` README [here](https://github.com/x1ppy/gazelle-origin)
* Doesn't move downloaded files into the "finished" location until 100% complete to avoid importing/scanning incomplete music files

## TODO

1. Add username/password that isn't the default

## Shortcomings

1. qBittorrent has no way to configure the monitored folders (i.e. where you put your torrent files) from the config file. This has to be configured manually from the UI
