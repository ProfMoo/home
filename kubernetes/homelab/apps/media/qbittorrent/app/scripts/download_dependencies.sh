#!/bin/bash

# This script installs the necessary dependencies for the post-download scripts to run successfully.
#
# If any of the dependencies are already installed, the script will skip the installation process for that dependency.
# (i.e. this script is idempotent)
#
# It's worth noting that this script will not handle upgrades - this is meant to live in the qBittorrent container, where the installation
# will be wiped on restart.

# Install py3-pip and git to enable python package installations
echo "[download_dependencies] Checking if pip is installed..."
if command -v pip >/dev/null; then
	echo "[download_dependencies] pip is already installed. Continuing."
else
	echo "[download_dependencies] pip is not installed. Installing..."
	apk add --no-cache py3-pip
	echo "[download_dependencies] pip finished installing."
fi

echo "[download_dependencies] Checking if git is installed..."
if command -v git >/dev/null; then
	echo "[download_dependencies] Git is already installed. Continuing."
else
	echo "[download_dependencies] Git is not installed. Installing..."
	apk add --no-cache git
	echo "[download_dependencies] Git finished installing."
fi

# Install custom fork of gazelle-origin with necessary dependencies. We want to override system packages if necessary.
echo "[download_dependencies] Checking if bencoder is installed..."
if pip show bencoder >/dev/null; then
	echo "[download_dependencies] Bencoder is already installed. Continuing."
else
	echo "[download_dependencies] Beconder is not installed. Installing..."
	pip install bencoder --break-system-packages
	echo "[download_dependencies] Bencoder finished installing."
fi

echo "[download_dependencies] Checking if gazelle-origin is installed..."
if pip show gazelle-origin >/dev/null; then
	echo "[download_dependencies] Gazelle-origin is already installed. Continuing."
else
	echo "[download_dependencies] Gazelle-origin is not installed. Installing..."
	pip install git+https://github.com/ProfMoo/gazelle-origin@793242ff3efb9e42a9f4869e4de38c5d923d9ab7 --break-system-packages
	echo "[download_dependencies] Gazelle-origin finished installing."
fi

# Install curl to ensure the post-download betanin script has the necessary dependencies
echo "[download_dependencies] Checking if curl is installed..."
if command -v curl >/dev/null; then
	echo "[download_dependencies] Curl is already installed. Continuing."
else
	echo "[download_dependencies] Curl is not installed. Installing..."
	apk add --no-cache curl
	echo "[download_dependencies] Curl finished installing."
fi
