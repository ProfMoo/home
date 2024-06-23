#!/bin/bash

# This script installs the necessary dependencies for the post-download scripts to run successfully.
#
# If any of the dependencies are already installed, the script will skip the installation process for that dependency.
# (i.e. this script is idempotent)
#
# It's worth noting that this script will not handle upgrades - this is meant to live in the qBittorrent container, where the installation
# will be wiped on restart.

# Install py3-pip and git to enable python package installations
echo "Checking if pip is installed..."
if command -v pip >/dev/null; then
    echo "pip is already installed. Continuing."
else
    echo "pip is not installed. Installing..."
    apk add --no-cache py3-pip
    echo "pip finished installing."
fi

echo "Checking if git is installed..."
if command -v git >/dev/null; then
    echo "Git is already installed. Continuing."
else
    echo "Git is not installed. Installing..."
    apk add --no-cache git
    echo "Git finished installing."
fi

# Install custom fork of gazelle-origin with necessary dependencies. We want to override system packages if necessary.
echo "Checking if bencoder is installed..."
if pip show bencoder >/dev/null; then
    echo "Bencoder is already installed. Continuing."
else
    echo "Beconder is not installed. Installing..."
    pip install bencoder --break-system-packages
    echo "Bencoder finished installing."
fi

echo "Checking if gazelle-origin is installed..."
if pip show gazelle-origin >/dev/null; then
    echo "Gazelle-origin is already installed. Continuing."
else
    echo "Gazelle-origin is not installed. Installing..."
    pip install git+https://github.com/ProfMoo/gazelle-origin@95be674662f54f489addfbf2fc02a28f42fd5fe9 --break-system-packages
    echo "Gazelle-origin finished installing."
fi

# Install curl to ensure the post-download betanin script has the necessary dependencies
echo "Checking if curl is installed..."
if command -v curl >/dev/null; then
    echo "Curl is already installed. Continuing."
else
    echo "Curl is not installed. Installing..."
    apk add --no-cache curl
    echo "Curl finished installing."
fi
