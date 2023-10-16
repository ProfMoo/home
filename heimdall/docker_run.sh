#!/bin/bash

if docker compose build --parallel; then
    docker compose up --remove-orphans -d
else
    echo "Docker compose build failed"
fi
