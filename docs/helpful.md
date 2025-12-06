# Helpful Scripts & One-Liners

Reconcile A Particular Fluxtomization:

```bash
flux reconcile source git profmoo-home && flux reconcile kustomization flux-system && flux reconcile kustomization prowlarr
```

Make a job from a cronjob:

```bash
kubectl create job example-job --from=cronjob/example-cronjob
```

## Reassign a PVC to an Old PV

There are times (i.e. I mess something up) where a PVC makes a new PV instead of re-binding to the old PV as desired. In this scenario, the best remedy is as such:

1. Ensure the old PV (i.e. the one we actually want to use) is marked as `Available`. Most times, it's still `Released`. To do this:

    ```bash
    kubectl edit pv <pv-name>
    ```

2. Remove the `claimRef` block from the old PV. This frees the PV to be reclaimed by the PVC.

3. Delete the new PV and the PVC in question:

    ```bash
    kubectl delete pv <pv-name>
    kubectl delete pvc <pvc-name>
    ```

    The old PV and PVC will hang (i.e. be stuck in terminating). Just ignore that and keep pressing forward.

4. Delete the pod in question:

    ```bash
    kubectl delete pod <pod-name>
    ```

5. Inspect and ensure everything looks right. You should see the PV, PVC, and pod all successfully quit at around the same time. Then, the pod should start back up, ask for the PVC, and the PVC<->PV should bind.

## Rook/Ceph

Use the [`rook-ceph` kubectl plugin](https://rook.io/docs/rook/latest-release/Troubleshooting/kubectl-plugin/) to access `ceph` CLI easily.

### Remove OSD

Remove OSD docs: <https://rook.io/docs/rook/latest-release/Storage-Configuration/Advanced/ceph-osd-mgmt/#purge-the-osd-with-kubectl>

```bash
kubectl rook-ceph -n storage ceph pg
```
