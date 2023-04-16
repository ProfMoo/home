FROM linuxserver/qbittorrent:4.5.2

# Install gazelle-origin with necessary dependencies
RUN apk add py3-pip && apk add git && pip install bencoder && pip install git+https://github.com/x1ppy/gazelle-origin

# NOTE: There is no CMD or ENTRYPOINT here because we want to inherit them from the source container
