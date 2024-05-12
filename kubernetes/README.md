# Kubernetes

## Sops

I use [`sops`](https://github.com/getsops/sops) to manage secrets in a GitOps way. Good tutorial on sops [here](https://blog.gitguardian.com/a-comprehensive-guide-to-sops/).

## Storage

Going to have 3 kinds of storage for my k8s clusters:

    1. Storage that I'd like to persist across pod restarts, but it's really not a big deal if I lose this data. Ex: prometheus data. This data is usually specific to k8s and doesn't have a particular need to persist outside of Kubernetes. Local node data is fine here, replication isn't needed.

    2. Storage that I'd like to be able to create on the fly (i.e. not pre-existing folders). This is important data and would like to maintain good backups of it, but the total size is relatively small. This data won't be 100% mission critical, so I'm comfortable delegating to the k8s control planes. For this type of storage, there is an excellent guide [here](https://github.com/fenio/k8s-truenas), which I'll attempt to use. This 2nd type of storage is one where the value of TrueNAS is up in the air. What if instead... I just used rook/ceph for these use-cases?

    3. For that media storage that is pre-created (i.e. my existing media) and is both HUGE and CRITICAL. This data is 100% critical to the homelab and CANNOT be lost. As such, the k8s control plane can't be trusted with this data and instead it will be managed by TrueNAS (i.e. software and configuration that I don't maintain) and mounted to pods via NFS PVs. For this type of storage, I'll try to use the `node-manual` CSI driver (example [here](https://github.com/democratic-csi/democratic-csi/blob/master/examples/node-manual-nfs-pv.yaml))

I might be able to use `democratic-csi` for all 3 of these, using these 3 drivers, respectively: `democratic-csi/local-hostpath`, `democratic-csi/freenas-api-nfs` & `democratic-csi/freenas-api-iscsi`, and `democratic-csi/node-manual`

## Storage 2

Now that I'm further along, I think I have an idea for how I'm wanna do storage in the future:

    1. Run Ceph/Rook directly in k8s to replace option 1 & 2 from above. Can expose iSCSI or NFS mounts when needed. Then run volsync to backup these drives to TrueNAS.
    2. When using the `/media` from the NAS, just do a simple NFS mount PVC in k8s (nothing fancy).

## Secrets

At the top level of the `homelab` directory is two secrets that must be applied to the cluster for flux to function properly:

- `age.secret.sops.yaml`: The age secret that Flux will use to decrypt secrets checked into the codebase.
- `github.secret.sops.yaml`: The Github SSH keys and access token necessary for Flux to access this repository on github.com.

These secrets can be decrypted by either an age key (defined in the top-level `.sops.yaml` file) OR a KMS key (ARN also defined in the top-level `.sops.yaml` file). Age is the primary key used to decrypt secrets by Flux at deploy time. KMS key can be used a backup to decrypt and recover the bootstrap secrets if needed.

To deploy these secret during initial bootstrapping:

```bash
sops --decrypt kubernetes/homelab/age.bootstrap.sops.yaml | kubectl apply --server-side --filename -
sops --decrypt kubernetes/homelab/github.bootstrap.sops.yaml | kubectl apply --server-side --filename -
```

### Secrets With Flux

To properly ensure secrets are GitOps-ified and still kept secret across the wide array of apps in this repo, there are numerous methods in which an app can be supplied secrets. Here’s a breakdown of some common methods using the tools in this repo: [Flux](https://fluxcd.io/) and [SOPS](https://github.com/mozilla/sops).

_This guide will not be covering how to integrate SOPS into Flux initially (i.e. bootstrapping SOPS with Flux during initial setup). For that be sure to check out the [Flux documentation on integrating SOPS](https://fluxcd.io/docs/guides/mozilla-sops/)_

For the first three examples, the following secret will be used:.

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: application-secret
    namespace: default
stringData:
    SUPER_SECRET_KEY: "SUPER SECRET VALUE"
```

#### Method 1: `envFrom`

> _Use `envFrom` in a deployment or a Helm chart that supports the setting, this will pass all secret items from the secret into the containers environment._

```yaml
envFrom:
- secretRef:
    name: application-secret
```

View example [Helm Release](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/default/home-assistant/helm-release.yaml) and corresponding [Secret](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/default/home-assistant/secret.sops.yaml).

#### Method 2: `env.valueFrom`

> _Similar to the above but it's possible with `env` to pick an item from a secret._

```yaml
env:
- name: WAY_COOLER_ENV_VARIABLE
    valueFrom:
    secretKeyRef:
        name: application-secret
        key: SUPER_SECRET_KEY
```

View example [Helm Release](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/networking/external-dns/helm-release.yaml) and corresponding [Secret](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/networking/external-dns/secret.sops.yaml).

#### Method 3: `spec.valuesFrom`

> _The Flux HelmRelease option `valuesFrom` can inject a secret item into the Helm values of a `HelmRelease`_
>
> - _Does not work with merging array values_
> - _Care needed with keys that contain dot notation in the name_

```yaml
valuesFrom:
- targetPath: config."admin\.password"
    kind: Secret
    name: application-secret
    valuesKey: SUPER_SECRET_KEY
```

View example [Helm Release](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/default/emqx/helm-release.yaml) and corresponding [Secret](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/default/emqx/secret.sops.yaml).

#### Method 4: Variable Substitution with Flux

> _Flux variable substitution can inject secrets into any YAML manifest. This requires the [Flux Kustomization](https://fluxcd.io/docs/components/kustomize/kustomization/) configured to enable [variable substitution](https://fluxcd.io/docs/components/kustomize/kustomization/#variable-substitution). Correctly configured this allows you to use `${GLOBAL_SUPER_SECRET_KEY}` in any YAML manifest._

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: cluster-secrets
    namespace: flux-system
stringData:
    GLOBAL_SUPER_SECRET_KEY: "GLOBAL SUPER SECRET VALUE"
```

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
# ...
spec:
# ...
decryption:
    provider: sops
    secretRef:
        name: sops-age
postBuild:
    substituteFrom:
    - kind: Secret
        name: cluster-secrets
```

View example [Fluxtomization](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/flux/apps.yaml), [Helm Release](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/monitoring/kube-prometheus-stack/helm-release.yaml), and corresponding [Secret](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/config/cluster-secrets.sops.yaml).

#### Final Thoughts

- TODO: For the first **three methods** consider using a tool like [stakater/reloader](https://github.com/stakater/Reloader) to restart the pod when the secret changes. Using reloader on a pod using a secret provided by Flux Variable Substitution will lead to pods being restarted during any change to the secret while related to the pod or not.

- The last method should be used when all other methods are not an option, or used when you have a “global” secret used by numerous HelmReleases across the cluster.

### Notes

In the future, I might choose to go down a more "hyperconverged" route and manage storage directly from k8s (instead of having TrueNAS handle most of this). In that case, I'd need to migrate the `StorageClass` of most of my pods, which would be a big lift. To do that, there is a great article [here](https://gist.github.com/deefdragon/d58a4210622ff64088bd62a5d8a4e8cc).

For this hyperconverged route, I might consider using [Harvester](https://github.com/harvester/harvester), which is a more cloud-native hypervisor and VM-management solution.
