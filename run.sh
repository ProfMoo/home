#!/bin/bash

# Getting the location of the config file
CONFIG_FILE=$1

echo "Starting up the docker container for the home setup..."

TRACKER_DIR=$(cat $CONFIG_FILE | yq eval '.TRACKER_DIR' -)
echo "Tracker directory: $TRACKER_DIR"

DOWNLOAD_DIR=$(cat $CONFIG_FILE | yq eval '.DOWNLOAD_DIR' -)
echo "Download directory: $DOWNLOAD_DIR"

MUSIC_LIBRARY_DIR=$(cat $CONFIG_FILE | yq eval '.MUSIC_LIBRARY_DIR' -)
echo "Music library directory: $MUSIC_LIBRARY_DIR"

if TRACKER_DIR=$TRACKER_DIR DOWNLOAD_DIR=$DOWNLOAD_DIR MUSIC_LIBRARY_DIR=$MUSIC_LIBRARY_DIR docker compose build --parallel ; then
    TRACKER_DIR=$TRACKER_DIR DOWNLOAD_DIR=$DOWNLOAD_DIR MUSIC_LIBRARY_DIR=$MUSIC_LIBRARY_DIR docker compose up --remove-orphans
else
    echo "Docker compose build failed"
fi
