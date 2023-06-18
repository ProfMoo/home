#!/bin/bash

# Determining what type of startup we will need
RUN_TYPE=$1

echo "Starting up the docker container for the home setup..."

if [ "$RUN_TYPE" = "local" ]; then
    echo "Starting up with the 'local' configuration"
    source config/local.sh
elif [ "$RUN_TYPE" = "nas" ]; then
    echo "Starting up with the 'nas' configuration"
    source config/nas.sh
    RUN_ARGS="--detach"
else
    echo "Run type '$RUN_TYPE' not supported. Supported types are 'local' and 'nas'. Exiting..."
fi

if docker-compose build; then
    docker-compose down --remove-orphans ${RUN_ARGS}
else
    echo "Docker compose build failed"
fi
