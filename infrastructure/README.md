# Infrastructure

This directory houses the code that transforms raw bare-metal machines into functional Kubernetes clusters. The code in this directory depends on a LAN-accessible Proxmox VE installation (or multiple!) to create a bare-bones Kubernetes cluster using [Talos](https://github.com/siderolabs/talos).

## Prerequisites

1. Terraform installed (check [the providers file](./talos/providers.tf) for the specific version requirements)
2. Install Proxmox VE v8.0+ on a bare-metal machine (or more than one).
3. Ensure you have a file named `aws-credentials` in the `talos` directory in the format:

    ```text
    [default]
    aws_access_key_id = <redacted>
    aws_secret_access_key = <redacted>
    ```

    This provides authentication to the AWS S3 bucket backend that stores the TF state AND the KMS secret to decrypt the sops file.

## How To Use

1. Populate `main.tf` as desired.
2. Run the desired Terraform commands (i.e. `terraform plan`, `terraform apply`).
3. Run this command to create the per-node Talos configs:

    ```bash
    ./create_talos_node_configs
    ```

4. Apply (or dry-run apply) to the desired Talos cluster nodes:

    ```bash
    # Dry run
    talosctl apply-config -n skrillex --file ./nodes/skrillex.yaml --dry-run
    # Apply
    talosctl apply-config -n skrillex --file ./nodes/skrillex.yaml
    ```

5. Follow the Kubernetes bootstrapping steps defined [here](../kubernetes/README.md#bootstrapping)

## Operations

### Adding New Disks To Proxmox

0. If the disk is already formatted, you'll need to 'zap' it to remove formatting to be able to add it to an LVM-Thin Pool. To do so: `sgdisk --zap-all /dev/<disk>`. To find the disk path, use `lsblk`.
   1. The disk will be formatted if, for example, if was previously used in a storage cluster.
1. Navigate to relevant node in Proxmox GUI -> Disks -> LVM-Thin -> "Create: Thinpool"
2. Select new disk by block device name (`lsblk` might help show available nodes on the node). Example names: `/dev/sda`, `/dev/sdb`, `/dev/sdc`.
3. Give the disk a name. I've chosen to increment the disks by the bay #. Example: Bay #3 -> `disk3`
4. Hit "Create".

### Adding New OSD To Rook/Ceph

EZPZ. Once the disk is available on the node:

```sh
kubectl -n storage rollout restart deploy/rook-ceph-operator
```

### Removing OSD From Rook/Ceph

1. Identify the OSD(s) to remove:

    ```sh
    kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph osd tree
    ```

2. Mark the OSD out (starts data rebalancing away from it):

    ```sh
    kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph osd out osd.<ID>
    ```

3. Wait for rebalancing to complete:

    ```sh
    kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph -w
    # Or check status periodically
    # Wait until HEALTH_OK or at least no recovery/rebalancing in progress.
    kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph status
    ```

4. Purge the OSD (removes it from the cluster):

    ```sh
    kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph osd purge osd.<ID> --yes-i-really-mean-it
    ```

5. Delete the OSD deployment:

    ```sh
    kubectl -n storage delete deploy rook-ceph-osd-<ID>
    ```

6. If the disk was explicitly listed in CephCluster CR, update the spec to remove it, otherwise Rook may try to recreate the OSD.

7. Clean the disk (if reusing or decommissioning):

    ```sh
    # From rook-tools or the node itself
    kubectl -n storage exec -it deploy/rook-ceph-tools -- ceph-volume lvm zap /dev/sdX --destroy
    ```

Tip: If removing multiple OSDs, do them one at a time and wait for full rebalancing between each to minimize risk and cluster load.

### Upgrading Kubernetes

Can perform a rolling upgrade with the TF provider and a standard TF workflow (or `talosctl` also works per [the docs](https://www.talos.dev/v1.9/kubernetes-guides/upgrading-kubernetes/)).

### Upgrading Talos

The Talos TF provider is relatively under-featured for upgrades ([Example of lack of features here](https://github.com/siderolabs/terraform-provider-talos/issues/140#issue-2055027252)). So it's best to use `talosctl` and follow the more production-ready upgrade path [here](https://www.talos.dev/v1.9/talos-guides/upgrading-talos/).

### Upgrading Talos-Controlled, Kubernetes-State-Managed Resources

There are some Kubernetes configurations, such as the `kube-proxy` configuration, which `talosctl` manages but only touches during Kubernetes bootstraps/upgrades. [Here](https://github.com/siderolabs/talos/discussions/7835) is a good example. To update a resource whose state is entirely within Kubernetes, but the config is managed via Talos, refer to the [upgrading Kubernetes section](#upgrading-kubernetes) above

### Upgrading Multiple Version Of Talos of Kubernetes At Once

Talos & Kubernetes versions are linked quite closely. If you're multiple versions behind on each:

* Upgrade them in lock step (i.e. upgrade Talos one minor version, then Kubernetes one minor version). If this isn't done, weird stuff can start to happen. (Trust me)
* Upgrade Talos's minor version first, then Kubernetes's minor version.

## TODOs

1. Enable Talos logs to be sent to a logging endpoint, similar to [this example](https://github.com/buroa/k8s-gitops/blob/860a6b47e39ae0a3c7b91c0ab9ed2294433913fa/talos/talconfig.yaml#L363).

## Notes

### IP Declaration

I attempted for quite a while to avoid tedious manual declarations of IP addresses for each Kubernetes node. I found some level of success assigning MAC addresses to the VMs, reading the DHCP-assigned IPv4 addresses from the Unifi Router, then using that in the rest of the process. But ultimately, it was unsuccessful. The Unifi Router would begin to get confused with the introduction of virtual IPs, such as the Talos Virtual IP, and begin to return the Virtual IP when I needed the direct node IP. I had to scrap this idea unfortunately. Instead, we assign each node an IP address and MAC address in `main.tf` manually.
