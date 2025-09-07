# TODO

1. [X] Remove unnecessary Grafana dashboards.
   1. [X] Fix Grafana. Lots of dashboards were broken with a recent upgrade.
2. [X] ~~Setup TrueNAS storage~~. Actually, just do Ceph/Rook with Volsync natively on the nodes for PVCs.
3. [X] Move over all applications from windows machine:
   1. [X] Jellyfin (needs GPU)
   2. [X] Roon (might need a completely different setup to accomplish this)
   3. [X] Factorio (need to figure out filesystem permission issue)
4. [X] Switch over to use local storage and volsync to my TrueNas cluster instead of the democratic-csi storage class.
5. [X] Fix my beets path by doing a raw SQLite query, described [here](https://discourse.beets.io/t/library-db-still-has-old-path-after-moving-collection-to-a-new-location/2331).
   1. [X] Consider standing up a little IDE (similar to what I have for HASS) that I can run beets queries in and modify the SQLite DB.
   2. [ ] Or maybe I just move to `wrtag`. Tired of beets - too finicky.
6. [X] Migrate to Flux Operator using [this PR](https://github.com/onedr0p/home-ops/pull/8624) as a guide.
7. [ ] System Upgrade Controller.
8. [ ] Work on preemptions for k8s so that the most important pods are always scheduled.
9. [X] Move fluxtomization to specific namespaces instead of having them all in `flux-system`
   1. [ ] Also do this for OCI Resources (i.e. Helm charts) (<https://github.com/onedr0p/home-ops/pull/8706>)
   2. [X] Move bootstrap to values.yaml (<https://github.com/onedr0p/home-ops/pull/9671>)
10. [x] Fix renovate so that I actually get a net benefit from the tool.
11. [ ] Add the Cloudflare `minecraft.drmoo.io` DNS record to TF (or try the TF operator!!!). It's currently manually entered on the CF website.
    1. [ ] Move Minecraft svcs off of Nodeport to use L2 cilium.
    2. [ ] I like how JFrog did it [here](https://github.com/joryirving/home-ops/blob/9d327c98f5bb1f97e21bbb522258b112609e76c0/kubernetes/apps/base/games/minecraft/mc-router/dnsendpoint.yaml#L2). Very clean.
12. [ ] Jellyfin MV organizational improvements. Doc with recommendations [here](https://github.com/mystoragebox/Jellyfin-Music-Video-Tutorial). Generally Jellyfin navigation isn't great currently.
13. [ ] Replace qbtools with tqm. qbtools is deprecated per [this README](https://github.com/buroa/qbtools).
14. [ ] Manage coredns in Flux. That's how onedr0p does it. [Link](https://github.com/onedr0p/home-ops/blob/5899f27553d145b40d029be4eb34d8e254a7cc23/talos/machineconfig.yaml.j2#L147) and [link](https://github.com/onedr0p/home-ops/blob/5899f27553d145b40d029be4eb34d8e254a7cc23/kubernetes/apps/kube-system/coredns/ks.yaml#L23).
15. [X] Add spegel for more stable image pulling
16. [ ] Read [this](https://blog.nfreak.tv/music-stack/) and revamp music perhaps?
17. [ ] For k8s 1.34 upgrade, check [this message](https://discord.com/channels/673534664354430999/942576972943491113/1410643392785944708).
18. [ ] Setup automatic transcoding for Jellyfin videos.
19. [ ] Move ALL STORAGE to Ceph -> bye bye TrueNAS.

## July 27th, 2025

* Pretty sure the Rook/Ceph issue is isolated to `bonobo` and is because of faulty RAM. Was seeing some telling kernel and dmesg logs.
  * Going to run `memtest+` on the RAM overnight to see what the situation is
* Not sure what the NFS issue is - some nodes struggle to connect at times and truenas.local lags out.
  * Update TrueNAS
  * Try to get a node working again
  * I am seeing correlation between the NFS issue and the sporadic overload/pause of Proxmox VMs. It's almost like the Proxmox VM pinning CPU causes everything to break on the node and somehow messes up NFS. Gotta figure out a way to reserve CPU for critical processes perhaps?

### Logs

#### NFS Issues

```bash

```

#### Ceph Issues

```text
*arr logs:

System.IO.IOException: I/O error : '/config/config.xml'

rbd storage pod logs:

E0713 20:26:21.470936  173611 utils.go:270] ID: 106 Req-ID: 0001-0007-storage-0000000000000001-e309164c-4f7e-4f45-8fc4-f90b57e9eecd GRPC error: rpc error: code = Internal desc = rbd: map failed with error an error (exit status 108) occurred while running rbd args: [--id csi-rbd-node -m 192.168.8.119:3300,192.168.8.122:3300,192.168.8.124:3300 --keyfile=***stripped*** map ceph-blockpool/csi-vol-e309164c-4f7e-4f45-8fc4-f90b57e9eecd --device-type krbd --options noudev --options read_from_replica=localize,crush_location=host:bonobo], rbd error output: rbd: sysfs write failed
rbd: map failed: (108) Cannot send after transport endpoint shutdown
W0713 20:26:44.595674  173611 rbd_attach.go:488] ID: 120 Req-ID: 0001-0007-storage-0000000000000001-5ef909c0-14f7-4df1-a4a4-19bbd7bfcd63

dmesg logs (talosctl dmesg -n bonobo -f):

traps: Sonarr[164778] general protection fault ip:7f784f3d7468 sp:7ffd89385f70 error:0 in libcoreclr.so
traps: Sonarr[171372] general protection fault ip:7f248642f468 sp:7fff15c2a030 error:0 in libcoreclr.so
traps: Sonarr[172096] general protection fault ip:7fb4b7d9b468 sp:7ffe2af14990 error:0 in libcoreclr.so
```
