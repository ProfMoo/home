FROM --platform=linux/arm64 alpine:3.18

# Install the most basic command line tooling
RUN apk add bash zsh curl wget git tmux fzf

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install python/pip for dotbot
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools

# Install docker
RUN apk add --update docker=23.0.6-r5 openrc

# Install additional, more specific tooling
RUN apk add hadolint
