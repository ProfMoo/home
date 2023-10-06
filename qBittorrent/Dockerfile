FROM linuxserver/qbittorrent:4.5.2

# Install custom fork of gazelle-origin with necessary dependencies
RUN apk add py3-pip && apk add git && pip install bencoder && pip install git+https://github.com/ProfMoo/gazelle-origin@95be674662f54f489addfbf2fc02a28f42fd5fe9

# NOTE: There is no CMD or ENTRYPOINT here because we want to inherit them from the source container
