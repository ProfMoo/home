# TODO

1. [ ] Remove unnecessary Grafana dashboards.
   1. [ ] Fix Grafana. Lots of dashboards were broken with a recent upgrade.
2. [ ] ~~Setup TrueNAS storage~~. Actually, just do Ceph/Rook with Volsync natively on the nodes for PVCs.
3. [ ] Figure out the correct way to expose endpoints outside my local network (via Cloudflare)
4. [ ] Move over all applications from windows machine:
   1. [ ] Jellyfin (needs GPU)
   2. [ ] Roon (might need a completely different setup to accomplish this)
   3. [ ] Factorio (need to figure out filesystem permission issue)
5. [ ] Switch over to use local storage and volsync to my TrueNas cluster instead of the democratic-csi storage class.
6. [ ] Fix my beets path by doing a raw SQLite query, described [here](https://discourse.beets.io/t/library-db-still-has-old-path-after-moving-collection-to-a-new-location/2331).
   1. [ ] Consider standing up a little IDE (similar to what I have for HASS) that I can run beets queries in and modify the SQLite DB.
