#!/bin/bash

if docker compose build --parallel; then
    docker compose up --remove-orphans --detach
else
    echo "Docker compose build failed"
fi
