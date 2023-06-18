# HOME

This repository contains the configuration and code necessary to deploy and maintain my home stack. This currently includes mostly music configuration (ex: beets, lidarr, etc), but also includes various game servers and whatever other processes I want to run at home.

## Requirements

### Prerequisites

1. Docker installed on your system (I currently using `20.10.14`)
2. Docker compose installed on your system (I currently using `v2.4.1`)

### Quick Start

1. Ensure you have a `.env` file with your RED_API_KEY in the top level of this repository.
2. Create a configuration file for your needs using this format:

    ```yaml
    TRACKER_DIR: mydir/torrent-files
    DOWNLOAD_DIR: mydir/pre-process
    MUSIC_LIBRARY_DIR: mydir/post-process
    ```

3. Run

    ```bash
    # ex: ./run.sh config/local
    ./run.sh <config location>
    ```

## Docker In Docker

I'd like to run these home services on a NAS or other type of home server eventually (rather than mostly on my personal desktop). However, when trying to deploy the docker containers to the NAS, I ran into numerous issues, as detailed in some of these blogs posts:

- https://github.com/markdumay/synology-docker/issues/22
- https://kristoferlundgren.medium.com/synology-run-the-latest-docker-daemon-without-patching-dsm6-x-7bb4834d87bc
- https://github.com/markdumay/synology-docker

The potential solution to this problem would be a DIND setup, which would allow me to alleviate the dependency on a specific version of docker and docker-compose to run these containers. This is a WIP.

## Torrent Management

https://github.com/rndusr/torf

https://github.com/pobrn/mktorrent

https://github.com/flyingrub/scdl

## Upload Torrents

https://redacted.ch/wiki.php?action=article&id=455#_3053351046

https://redacted.ch/wiki.php?action=article&id=35

https://redacted.ch/wiki.php?action=article&name=Creating+torrents+with+qBittorrent

https://github.com/aruhier/gazelle-uploader

## K8s Exploration

Got a small, local K8s cluster running using [k3d](https://k3d.io/v5.4.9/).
