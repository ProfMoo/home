# Kubernetes

## Sops

I use [`sops`](https://github.com/getsops/sops) to manage secrets in a GitOps way. Good tutorial on sops [here](https://blog.gitguardian.com/a-comprehensive-guide-to-sops/).

## Storage

Going to have 3 kinds of storage for my k8s clusters:

    1. Storage that I'd like to persist across pod restarts, but it's really not a big deal if I lose this data. Ex: prometheus data. This data is usually specific to k8s and doesn't have a particular need to persist outside of Kubernetes. Local node data is fine here, replication isn't needed.

    2. Storage that I'd like to be able to create on the fly (i.e. not pre-existing folders). This is important data and would like to maintain good backups of it, but the total size is relatively small. This data won't be 100% mission critical, so I'm comfortable delegating to the k8s control planes. For this type of storage, there is an excellent guide [here](https://github.com/fenio/k8s-truenas), which I'll attempt to use.

    3. For that media storage that is pre-created (i.e. my existing media) and is both HUGE and CRITICAL. This data is 100% critical to the homelab and CANNOT be lost. As such, the k8s control plane can't be trusted with this data and instead it will be managed by TrueNAS (i.e. software and configuration that I don't maintain) and mounted to pods via NFS PVs. For this type of storage, I'll try to use the `node-manual` CSI driver (example [here](https://github.com/democratic-csi/democratic-csi/blob/master/examples/node-manual-nfs-pv.yaml))

I might be able to use `democratic-csi` for all 3 of these, using these 3 drivers, respectively: `democratic-csi/local-hostpath`, `democratic-csi/freenas-api-nfs` & `democratic-csi/freenas-api-iscsi`, and `democratic-csi/node-manual`

### Notes

In the future, I might choose to go down a more "hyperconverged" route and manage storage directly from k8s (instead of having TrueNAS handle most of this). In that case, I'd need to migrate the `StorageClass` of most of my pods, which would be a big lift. To do that, there is a great article [here](https://gist.github.com/deefdragon/d58a4210622ff64088bd62a5d8a4e8cc).

For this hyperconverged route, I might consider using [Harvester](https://github.com/harvester/harvester), which is a more cloud-native hypervisor and VM-management solution.
