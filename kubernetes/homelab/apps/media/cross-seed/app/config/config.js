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
  outputDir: "/config",
  // We don't use this, but it's required for the app to start for some reason.
}
