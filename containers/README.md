# Containers

This directory contains a small collection of containers for apps that require custom builds to run on my cluster. I usually try to avoid custom container images to save myself the hassle of maintaing a `Dockerfile` and the associated build pipeline, but sometimes it can't be avoided. For example, the [`betanin`](https://github.com/sentriz/betanin) process running in my cluster build requires a [specific list of packages](./beets/requirements.txt).

As of now, I manually build and push these containers to ghcr.io.
