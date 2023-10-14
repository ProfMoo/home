# Prowlarr

Tool that provides a consistent API on top of a large list of trackers. The homepage is found [here](https://github.com/Prowlarr/Prowlarr).

I have minimal configuration and usage for Prowlarr at this time, but it's working as is.

## Shortcomings

The Arr software stack in general shockingly lacks configuration as code. Docker Compose allows you to deploy containers of your Arr applications as a set of services which can communicate with each other, but it does not actually do the application-level configuration that makes them actually work together. In other words, it will deploy your Sonarr/Radarr PVRs and your Prowlarr indexer manager, but it will not actually setup the apps themselves to make them talk to each other.

There is a tool called [Buildarr](https://github.com/buildarr/buildarr) which attempts to solve this problem. I haven't verified that it works, but it seems generally promising. Buildarr has a [plugin built specifically for Prowlarr](https://github.com/buildarr/buildarr-prowlarr) as well.
