# qBittorrent

A docker container that runs a qBittorrent client with special configuration and conveniences. This installation is built with Red tracker in mind, but other Gazelle-based trackers are likely to work with little or no modifications.

## Features

* Auto-downloads when torrent files are placed in the directory
* Has reasonable defaults set for a seedbox (ex: allowing for unlimited files to be seeding at one time)
* Runs the `gazelle-origin` script automatically after download, which provides `beets` additional and helpful info during the tagging process. To read more, refer to the `gazelle-origin` README [here](https://github.com/x1ppy/gazelle-origin)
