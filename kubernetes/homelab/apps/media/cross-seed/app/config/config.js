module.exports = {
  delay: 20,
  searchCadence: "1 day",
  excludeRecentSearch: "2 weeks",
  qbittorrentUrl: "http://$${process.env.QBT_USERNAME}:$${process.env.QBT_PASSWORD}@qbittorrent.media.svc.cluster.local:8080",
  torznab: [
    `http://prowlarr.media.svc.cluster.local:80/5/api?apikey=$${process.env.PROWLARR_API_KEY}`,
    `http://prowlarr.media.svc.cluster.local:80/6/api?apikey=$${process.env.PROWLARR_API_KEY}`,
  ],
  port: process.env.CROSSSEED_PORT || 2468,
  apiAuth: false,
  action: "inject",
  includeEpisodes: false,
  includeSingleEpisodes: true,
  includeNonVideos: true,
  duplicateCategories: true,
  matchMode: "safe",
  skipRecheck: true,
  // NOTE: We don't actually use this folder because we inject the downloaded torrents directly into the torrent client,
  // but we need to include this directory in the container for cross-seed to startup correctly.
  outputDir: "/config",
}
