# Helpful Scripts & One-Liners

Reconcile A Particular Fluxtomization:

```bash
flux reconcile source git profmoo-home && flux reconcile kustomization flux-system && flux reconcile kustomization prowlarr
```

Make a job from a cronjob:

```bash
kubectl create job example-job --from=cronjob/example-cronjob
```
