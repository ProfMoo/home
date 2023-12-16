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
3. Once the Kubernetes cluster is successfully applied, run this command to get the necessary configs:

    ```bash
    source get_configs
    ```

## Gotchas

1. I currently use a forked version of the Unifi Terraform provider which fixes a missing IP bug. PR is [here](https://github.com/paultyng/terraform-provider-unifi/pull/430).
2. For some reason the certs aren't correct on the initial cluster installation. Commands such as `kubectl logs` don't work as a result (but the cluster still functions as normal). To fix this, I needed to run the commands found in [this GitHub comment](https://github.com/kubernetes/kubeadm/issues/591#issuecomment-1257061416).

   I need to run the approval command for each new node in the cluster or else I get some weird warnings, can't view logs, the status of control-plane component is unknown, and more. This problem could probably be debugged and automated

## Operations

To add new nodes with new disks:

1. Create LVM-Thin storage pool for the new disk
2. Assign new nodes to that disk
