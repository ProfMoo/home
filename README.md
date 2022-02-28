# HOME

This repository contains the configuration and code necessary to deploy and maintain my home stack. This currently includes mostly music configuration (ex: beets, lidarr, etc), but could eventually include router configuration and more.

## Requirements

### Install

1. Docker
2. Docker-compose
3. `yq`

### API Key

Ensure you have a `.env` file with your RED_API_KEY in the top level of this repository.

### Configuration

Create a configuration file of this format:

```yaml
TRACKER_DIR: mydir/torrent-files
DOWNLOAD_DIR: mydir/pre-process
MUSIC_LIBRARY_DIR: mydir/post-process
```

## Install

```bash
# ex: ./run.sh config.yaml
./run.sh <config location>
```
