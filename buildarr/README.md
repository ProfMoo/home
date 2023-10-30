# Buildarr

The Arr software stack in general shockingly lacks configuration as code. Docker Compose allows you to deploy containers of your Arr applications as a set of services which can communicate with each other, but it does not actually do the application-level configuration that makes them actually work together. In other words, it will deploy your Sonarr/Radarr PVRs and your Prowlarr indexer manager, but it will not actually setup the apps themselves to make them talk to each other.

There is a tool called [Buildarr](https://github.com/buildarr/buildarr) which attempts to solve this problem. I haven't verified that it works, but it seems generally promising. Buildarr has a [plugin built specifically for Prowlarr](https://github.com/buildarr/buildarr-prowlarr) as well.

Opened up [this issue](https://github.com/buildarr/buildarr-prowlarr/issues/25) due to issue that makes buildarr inoperable for me. We'll see what happens.
