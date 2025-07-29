# TODO

1. [ ] Remove unnecessary Grafana dashboards.
   1. [ ] Fix Grafana. Lots of dashboards were broken with a recent upgrade.
2. [X] ~~Setup TrueNAS storage~~. Actually, just do Ceph/Rook with Volsync natively on the nodes for PVCs.
3. [ ] Move over all applications from windows machine:
   1. [ ] Jellyfin (needs GPU)
   2. [ ] Roon (might need a completely different setup to accomplish this)
   3. [ ] Factorio (need to figure out filesystem permission issue)
4. [X] Switch over to use local storage and volsync to my TrueNas cluster instead of the democratic-csi storage class.
5. [ ] Fix my beets path by doing a raw SQLite query, described [here](https://discourse.beets.io/t/library-db-still-has-old-path-after-moving-collection-to-a-new-location/2331).
   1. [ ] Consider standing up a little IDE (similar to what I have for HASS) that I can run beets queries in and modify the SQLite DB.
6. [X] Migrate to Flux Operator using [this PR](https://github.com/onedr0p/home-ops/pull/8624) as a guide.
7. [ ] System Upgrade Controller.
8. [ ] Work on pre-emptions for k8s so that the most important pods are always scheduled.
9. [ ] Move fluxtomization to specific namespaces instead of having them all in `flux-system`
10. [ ] Fix renovate so that I actually get a net benefit from the tool.
11. [ ] Add the Cloudflare `minecraft.drmoo.io` DNS record to TF (or try the TF operator!!!)

## July 27th, 2025

* Pretty sure the Rook/Ceph issue is isolated to `bonobo` and is because of faulty RAM. Was seeing some telling kernel and dmesg logs.
  * Going to run `memtest+` on the RAM overnight to see what the situation is
* Not sure what the NFS issue is - some nodes struggle to connect at times and truenas.local lags out.
  * Update TrueNAS
  * Try to get a node working again
