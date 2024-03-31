# Secret variations with Flux

There are several different ways to utilize Kubernetes secrets when using [Flux](https://fluxcd.io/) and [SOPS](https://github.com/mozilla/sops). Here’s a breakdown of some common methods.

_I will not be covering how to integrate SOPS into Flux for that be sure to check out the [Flux documentation on integrating SOPS](https://fluxcd.io/docs/guides/mozilla-sops/)_

## Example Secret

> The three following methods will use this secret as an example.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: application-secret
  namespace: default
stringData:
  SUPER_SECRET_KEY: "SUPER SECRET VALUE"
```

### Method 1: `envFrom`

> _Use `envFrom` in a deployment or a Helm chart that supports the setting, this will pass all secret items from the secret into the containers environment._

```yaml
envFrom:
  - secretRef:
      name: application-secret
```

```admonish example
View example [Helm Release](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/default/home-assistant/helm-release.yaml) and corresponding [Secret](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/default/home-assistant/secret.sops.yaml).
```

### Method 2: `env.valueFrom`

> _Similar to the above but it's possible with `env` to pick an item from a secret._

```yaml
env:
  - name: WAY_COOLER_ENV_VARIABLE
    valueFrom:
      secretKeyRef:
        name: application-secret
        key: SUPER_SECRET_KEY
```

```admonish example
View example [Helm Release](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/networking/external-dns/helm-release.yaml) and corresponding [Secret](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/networking/external-dns/secret.sops.yaml).
```

### Method 3: `spec.valuesFrom`

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

```admonish example
View example [Helm Release](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/default/emqx/helm-release.yaml) and corresponding [Secret](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/default/emqx/secret.sops.yaml).
```

### Method 4: Variable Substitution with Flux

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

```admonish example
View example [Fluxtomization](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/flux/apps.yaml), [Helm Release](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/apps/monitoring/kube-prometheus-stack/helm-release.yaml), and corresponding [Secret](https://github.com/onedr0p/home-ops/blob/782ec8c15cacc17329aec08841380aba134794a1/cluster/config/cluster-secrets.sops.yaml).
```

## Final Thoughts

* For the first **three methods** consider using a tool like [stakater/reloader](https://github.com/stakater/Reloader) to restart the pod when the secret changes.

* Using reloader on a pod using a secret provided by Flux Variable Substitution will lead to pods being restarted during any change to the secret while related to the pod or not.

* The last method should be used when all other methods are not an option, or used when you have a “global” secret used by a bunch of YAML manifests.
