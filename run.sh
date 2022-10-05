#!/bin/bash

# Getting the location of the config file
RUN_TYPE=$1

echo "Starting up the docker container for the home setup..."

if [ "$RUN_TYPE" = "local" ]; then
    echo "Starting up with the 'local' configuration"
    source config/local.sh
elif [ "$RUN_TYPE" = "nas" ]; then
    echo "Starting up with the 'nas' configuration"
    source config/nas.sh
else
    echo "Run type '$RUN_TYPE' not supported. Exiting..."
fi

if docker-compose build ; then
    docker-compose up --remove-orphans
else
    echo "Docker compose build failed"
fi
