# qBittorrent

A docker container that runs a qBittorrent client with special configuration and conveniences. This installation is built with RED & OPS trackers in mind. Other Gazelle-based trackers would work, but wouldn't be able to take advantage of the full feature set.

## Features

* Has reasonable defaults set for a seedbox (ex: allowing for unlimited files to be seeding at one time).
* Runs the `gazelle-origin` script automatically after download to generate the `origin.yaml` file, which provides `beets` additional and helpful info during the tagging process. To read more, refer to the `gazelle-origin` README [here](https://github.com/ProfMoo/gazelle-origin). Full scripts are in the [scripts](./scripts) directory.
* Doesn't move downloaded files into the "finished" location until 100% complete to avoid importing/scanning incomplete music files.
* Keeps the torrent files in a volume to ensure active torrents aren't lost. This allows for portability of the qBittorrent instance.

## TODO

1. Ensure the qBittorrent configuration is backed up (or configured as code).

## Shortcomings

1. Need to run qBittorrent as root to avoid a mess of file system and docker mount volume permission problems.
