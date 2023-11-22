# HOME

This repository contains the configuration and code necessary to deploy and maintain my home stack. This currently includes mostly music configuration (ex: beets, qBittorrent, etc), but also includes various game servers and whatever other processes I want to run at home.

## Requirements

### Prerequisites

1. Docker installed on your system (I currently using `20.10.14`)
2. Docker compose installed on your system (I currently using `v2.4.1`)

### Quick Start

1. Ensure you have a `.env` file with your RED_API_KEY in the top level of this repository.
2. Create a configuration file for your needs using this format:

    ```yaml
    TORRENT_DIR: mydir/torrent-files
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

- <https://github.com/markdumay/synology-docker/issues/22>
- <https://kristoferlundgren.medium.com/synology-run-the-latest-docker-daemon-without-patching-dsm6-x-7bb4834d87bc>
- <https://github.com/markdumay/synology-docker>

The potential solution to this problem would be a DIND setup, which would allow me to alleviate the dependency on a specific version of docker and docker-compose to run these containers. This is a WIP.

## TODO

1. Move containers to a paradigm that allows them to moved more easily (ex: k8s)
2. Move Roon to a container (or move to a new music server that runs in a container, when ready)

### Some Thoughts

Should separate the process environment (i.e. k8s, docker-compose) from the storage story. Can probably solve the process environment problem first and just hardcode all the storage locations (which would be on the Synology still). Then, figure out the storage situation later.

Definitely seems like using Rancher is the move. It's a great open source solution for managing k8s clusters and will give a lot more repeatability for standing the k8s clusters back up. Ex: <https://jmcglock.substack.com/p/running-a-kubernetes-cluster-using>

Perhaps could use Proxmox on my Windows machine to get a feel for it, then see about getting a server rack.

The term for the kind of setup I'm looking for is: "homelab". I played around with some homelab-esque situations and got a small, local K8s cluster running using [k3d](https://k3d.io/v5.4.9/).

#### Inspiration

<https://www.youtube.com/watch?v=cFm9z54TyT8>

<https://www.youtube.com/watch?v=dzh3so5wOro>

### Torrent Management

<https://github.com/rndusr/torf>

<https://github.com/pobrn/mktorrent>

<https://redacted.ch/wiki.php?action=article&id=455#_3053351046>

<https://redacted.ch/wiki.php?action=article&id=35>

<https://redacted.ch/wiki.php?action=article&name=Creating+torrents+with+qBittorrent>

<https://github.com/aruhier/gazelle-uploader>

### K8s on Proxmox

<https://betterprogramming.pub/rancher-k3s-kubernetes-on-proxmox-containers-2228100e2d13>
