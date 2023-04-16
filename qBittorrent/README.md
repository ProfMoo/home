# qBittorrent

A docker container that runs a qBittorrent client with special configuration and conveniences. This installation is built with Red tracker in mind, but other Gazelle-based trackers are likely to work with little or no modifications.

## Features

* Has reasonable defaults set for a seedbox (ex: allowing for unlimited files to be seeding at one time).
* Runs the `gazelle-origin` script automatically after download to generate the `origin.yaml` file, which provides `beets` additional and helpful info during the tagging process. To read more, refer to the `gazelle-origin` README [here](https://github.com/x1ppy/gazelle-origin).
* Doesn't move downloaded files into the "finished" location until 100% complete to avoid importing/scanning incomplete music files.
* Keeps the torrent files in a volume to ensure active torrents aren't lost. This allows for portability of the qBittorrent instance.

## TODO

1. Add username/password that isn't the default

## Shortcomings

1. There isn't currently a way to run qBittorrent on my Windows machine and ensure it can pickup the correct files. It's unclear where exactly the problem lies, as the full volumes path is Synology volume -> WSL mount -> Docker mount. This situation can be re-evaluated once qBittorrent is moved to its final resting place. Features currently broken because of this:
   1. Auto-downloads when torrent files are placed in the directory.
   2. The FASTRESUME feature of qBittorrent where torrents can be picked back up without checking the contents (not super necessary)
