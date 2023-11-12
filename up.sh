#!/bin/bash

# Determining what type of startup we will need
RUN_TYPE=$1

echo "Starting up the docker container for the home setup..."

if [ "$RUN_TYPE" = "local-synology" ]; then
    echo "Starting up with compute in 'local' configuration and storage in 'synology' configuration"
    source config/local-synology.sh
elif [ "$RUN_TYPE" = "local-truenas" ]; then
    echo "Starting up with compute in 'local' configuration and storage in 'truenas' configuration"
    source config/local-truenas.sh
elif [ "$RUN_TYPE" = "nas" ]; then
    echo "Starting up with the 'nas' configuration"
    source config/nas.sh
else
    echo "Run type '$RUN_TYPE' not supported. Supported types are 'local' and 'nas'. Exiting..."
fi

if docker-compose build; then
    docker-compose up --remove-orphans -d
else
    echo "Docker compose build failed"
fi
