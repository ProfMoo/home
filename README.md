# Moos Pasture

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
    # local-truenas is the name of the configuration file in the `config` directory
    ./up.sh local-truenas
    ```
