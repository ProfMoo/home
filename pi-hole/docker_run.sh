#!/bin/bash

if docker compose build --parallel; then
    docker compose up --remove-orphans
else
    echo "Docker compose build failed"
fi
