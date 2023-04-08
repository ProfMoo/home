#!/bin/bash

# Determining what type of startup we will need
RUN_TYPE=$1

echo "Starting up the factorio server..."

if [ "$RUN_TYPE" = "local" ]; then
    echo "Starting up with the 'local' configuration"
    export FACTORIO_DIR="/mnt/z/factorio"
elif [ "$RUN_TYPE" = "nas" ]; then
    echo "Starting up with the 'nas' configuration"
    export FACTORIO_DIR="/volume2/docker/factorio"
    RUN_ARGS="--detach"
else
    echo "Run type '$RUN_TYPE' not supported. Supported types are 'local' and 'nas'. Exiting..."
fi

if docker compose build --parallel; then
    docker compose --env-file .env up --remove-orphans ${RUN_ARGS}
else
    echo "Docker compose build failed"
fi
