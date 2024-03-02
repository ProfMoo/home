# Infrastructure

This directory houses the code that transforms raw bare-metal machines into functional Kubernetes clusters. The code in this directory depends on a LAN-accessible Proxmox VE installation (or multiple!) to create a bare-bones Kubernetes cluster using [Talos](https://github.com/siderolabs/talos).

## Prerequisites

1. Terraform installed (check [the providers file](./talos/providers.tf) for the specific version requirements)
2. Install Proxmox VE v8.0+ on a baremetal machine (or more than one).
3. Ensure you have a file named `aws-credentials` in the `talos` directory in the format:

    ```text
    [default]
    aws_access_key_id = <redacted>
    aws_secret_access_key = <redacted>
    ```

    This provides authentication to the AWS S3 bucket backend that stores the TF state

## How To Use

1. Populate `main.tf` as desired.
2. Run the desired Terraform commands (i.e. `terraform plan`, `terraform apply`).
3. Once the Kubernetes cluster is successfully applied, run this command to get the necessary configs loaded into your shell:

    ```bash
    ./get_configs
    ```

4. Once the cluster is up and running, make sure to create the necessary Flux secret so that Flux can access the Git repository. Docs [here](https://fluxcd.io/flux/components/source/gitrepositories/#ready-gitrepository).

## Operations

### To add new nodes with new disks

1. Create LVM-Thin storage pool for the new disk
2. Assign new nodes to that disk

### Upgrading Kubernetes

Can perform a rolling upgrade with the TF provider and a standard TF workflow (or `talosctl` also works per [the docs](https://www.talos.dev/v1.6/kubernetes-guides/upgrading-kubernetes/)).

### Upgrade Talos

The Talos TF provider is relatively under-featured for upgrades ([Example of lack of features here](https://github.com/siderolabs/terraform-provider-talos/issues/140#issue-2055027252)). So it's best to use `talosctl` and follow the more production-ready upgrade path [here](https://www.talos.dev/v1.6/talos-guides/upgrading-talos/).

### Upgrading Talos-Controlled, Kubernetes-State-Managed Resources

There are some Kubernetes configurations, such as the `kube-proxy` configuration, which `talosctl` manages but only touches during Kubernetes bootstraps/upgrades. [Here](https://github.com/siderolabs/talos/discussions/7835) is a good example. To update a resource whose state is entirely within Kubernetes, but the config is managed via Talos, refer to the [upgrading Kubernetes section](#upgrading-kubernetes) above

## TODOs

1. Enable Talos logs to be sent to a logging endpoint, similar to [this example](https://github.com/buroa/k8s-gitops/blob/860a6b47e39ae0a3c7b91c0ab9ed2294433913fa/talos/talconfig.yaml#L363).

## Notes

### IP Declaration

I attempted for quite a while to avoid tedious manual declarations of IP addresses for each Kubernetes node. I found some level of success assining MAC addresses to the VMs, reading the DHCP-assigned Ipv4 addresses from the Unifi Router, then using that in the rest of the progress. But ultimately it was unsuccessful. The Unifi Router would begin to get confused with the introduction of virtual IPs, such as the Talos Virtual IP, and begin to return the Virtual IP when I needed the direct node IP. I had to scrap this idea unfortunately. Now we must assign each node an IP address and MAC address in `main.tf` manually.

### Cilium Installation

I generated the Cilium YAML via this command:

```bash
helm template cilium \
    cilium/cilium \
    --version 1.13.2 \
    --namespace cilium \
    --set ipam.mode=kubernetes \
    --set tunnel=disabled \
    --set bpf.masquerade=true \
    --set endpointRoutes.enabled=true \
    --set kubeProxyReplacement=strict \
    --set autoDirectNodeRoutes=true \
    --set localRedirectPolicy=true \
    --set operator.rollOutPods=true \
    --set rollOutCiliumPods=true \
    --set ipv4NativeRoutingCIDR="10.244.0.0/16" \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set=cgroup.autoMount.enabled=false \
    --set=cgroup.hostRoot=/sys/fs/cgroup \
    --set=k8sServiceHost="localhost" \
    --set=k8sServicePort="7445"
```

I sourced this command from the [Talos installation guide](https://www.talos.dev/v1.6/kubernetes-guides/network/deploying-cilium/#method-1-helm-install) and [this Proxmox-based GitHub tutorial](https://github.com/kubebn/talos-proxmox-kaas).
