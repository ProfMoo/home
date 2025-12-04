# Kubernetes

## Overview

Within the `homelab` directory is all the in-cluster configuration for my homelab rack server.

* Code in the [`bootstrap`](./homelab/bootstrap/) dir is used to bootstrap the cluster.

* Code in the [`apps`](./homelab/apps/) dir is sync'd to the cluster after the cluster has been bootstrapped.

* Code in the [`common`](./homelab/common/) is basically a YAML template containing common components. Ex: All the `volsync` configuration needed for a fully-backed up PVC

* The [`repo`](./homelab/repo/) dir is the Kustomization that kicks off the whole process. It finds the rest of the Kustomization YAMLs in the cluster.

## Bootstrapping

The steps below are run after the cluster is created with Talos to start the flux-focused GitOps workflow. One the steps below are run, all the K8s cluster components and apps should install onto the cluster.

### 1. Secrets

In [this directory](./bootstrap), there are two secrets that must be applied to the cluster for flux to function properly:

* `age.secret.sops.yaml`: The age secret that Flux will use to decrypt secrets checked into the codebase. Primarily, this particular deployment is used by Flux to decrypt the `sops-age` secret that is deployed to each namespace.
* `github.secret.sops.yaml`: The Github SSH keys and access token necessary for Flux to access this repository on `github.com`.

These bootstrap secrets can be decrypted by either an age key (defined in the top-level `.sops.yaml` file) OR a KMS key (ARN also defined in the top-level `.sops.yaml` file). Age is a locally managed secret that should be used in most cases. KMS key can be used a backup to decrypt and recover the bootstrap secrets if needed.

To deploy these secret during initial bootstrapping:

```bash
sops --decrypt kubernetes/homelab/bootstrap/age.bootstrap.sops.yaml | kubectl apply --server-side --filename -
sops --decrypt kubernetes/homelab/bootstrap/github.bootstrap.sops.yaml | kubectl apply --server-side --filename -
```

Most of the Kubernetes components are added via Flux defined in the [kubernetes directory](../kubernetes/). For the remaining components that are installed during cluster instantiation, the instructions are defined below.

### 2. Helmfile Installation

There are a few components that need to installed manually before the cluster can start updating itself.

After the initial Talos cluster creation (with the CNI set to none), the cluster will be waiting for a CNI to be installed ([docs](https://www.talos.dev/v1.9/kubernetes-guides/network/deploying-cilium/)).

To install the initial bootstrap components, use `helmfile`:

```bash
helmfile --file kubernetes/homelab/bootstrap/helmfile.yaml apply  --skip-diff-on-install --suppress-diff
```

## Storage

### Current

Going to have 3 kinds of storage for my k8s clusters:

1. Storage that I'd like to persist across pod restarts, but it's really not a big deal if I lose this data. Ex: prometheus data. This data is usually specific to k8s and doesn't have a particular need to persist outside of Kubernetes. Local node data is fine here, replication isn't needed. I use a less resilient and compression-lite Rook/Ceph `StorageClass` for this.

2. Storage that is critical and can't be lost without significant sadness. Examples include application configuration that's stored in filesystem and Radarr movie lists. This is important data and would like to maintain good backups of it, but the total size is relatively small. I use a robustly replicated Rook/Ceph `StorageClass` for these use-cases, with Volsync as the designated backup/restore/snapshot tool.

3. For that media storage that is pre-created (i.e. my existing media) and is both HUGE and CRITICAL. This data is 100% critical to the homelab and CANNOT be lost. As such, the k8s control plane can't be trusted with this data and instead it will be managed by TrueNAS (i.e. software and configuration that I don't maintain) and mounted to pods via NFS PVs. For this type of storage, I'll try to use the `node-manual` CSI driver ([example](https://github.com/democratic-csi/democratic-csi/blob/master/examples/node-manual-nfs-pv.yaml))

### Future

In the future, I might choose to go down a more "hyperconverged" route and manage storage directly from k8s (instead of having TrueNAS handle the critical NFS data). In that case, I'd need to migrate the `StorageClass` of most of my pods, which would be a big lift. To do that, I've found the [`pv-migrate`](https://github.com/utkuozdemir/pv-migrate) tool to be of great use.

For this hyperconverged route, I might consider using [Harvester](https://github.com/harvester/harvester), which is a more cloud-native hypervisor and VM-management solution.

## Secrets

I use [`sops`](https://github.com/getsops/sops) to manage secrets in a GitOps way. There's a good overview of sops [here](https://blog.gitguardian.com/a-comprehensive-guide-to-sops/).

### Secrets With Flux

To properly ensure secrets are GitOps-ified and still kept secret across the wide array of apps in this repo, there are numerous methods in which an app can be supplied secrets. This section describes numerous ways to supply secrets with [Flux](https://fluxcd.io/) and [SOPS](https://github.com/mozilla/sops).

_This guide will not be covering how to integrate SOPS into Flux initially (i.e. bootstrapping SOPS with Flux during initial setup). For that, check out the [Flux documentation on integrating SOPS](https://fluxcd.io/docs/guides/mozilla-sops/). This guide is also not covering [External Secrets](https://external-secrets.io/latest/), which is also used in this repository._

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
> * _Does not work with merging array values_
> * _Care needed with keys that contain dot notation in the name_

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

### Kustomization Wait & DependOn

When managing dependencies between HelmReleases and Flux Kustomizations (i.e. KS), there are some import configuration flags that could have a large impact on developer experience: `wait` and `dependsOn`. As a quick overview: there are two bits of configuration that are relevant here:

`wait: false` only marks the Kustomization as successful if all the resources it creates are healthy
`wait: false` just does a kubectl apply -k and then says 'all good, chief'
`dependsOn` tells either the KS or the HelmRelease to confirm the health of another KS or HelmRelease before trying to apply. The health of the KS/HelmRelease could depend on HealthChecks or `wait`

There are two camps here, mostly: You can either handle the dependencies via dependsOn at the KS level, or at the HelmRelease level. There are pros and cons to each:

If you do it at the KS level, you'll run into situations where a KS fails to apply but then you have to wait for it to timeout before it notices you pushed a change and applies that instead, so it's a bit more clunky

Doing it at the HR level is a bit nicer in terms of developer experience, but it has limitations. For example, if your KS applies manifests that are not helm releases, then you can't really do depends on at the HR level, so you'll have to mix and match.

As a rule of thumb, if your KS only applies a HelmRelease (and associated configmaps, secrets etc), then you can set wait to false in the KS and implement your depends on at the HR level.

If you need to apply other things that depend on a HR, think applying your cert-manager cluster issuers as raw manifests, but they depend on the cert-manager HR, then you must do it at the KS level

Thanks to `mirceanton` for the overview in the [Home Operations discord server](https://discord.gg/home-operations).
