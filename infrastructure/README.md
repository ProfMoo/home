# Infrastructure

This directory houses the code that transform raw bare-metal machines into functional Kubernetes clusters. It's currently divided into two directories: `talos` and `k8s`. The `talos` directory uses a LAN-accessible Proxmox VE installation to create a bare-bones Kubernetes cluster using [Talos](https://github.com/siderolabs/talos). The `k8s` directory then hooks into these bare-bones Kubernetes clusters to install the necessary Kubernetes infrastructure,

## Prerequisites

1. Terraform installed (check [the providers file](./talos/providers.tf) for the specific version requirements)

## How To Use

1. Install Proxmox VE v8.0+ on a baremetal machine (or more than one).
2. Ensure you have a file named `aws-credentials` in the `talos` directory in the format:

    ```text
    [default]
    aws_access_key_id = <redacted>
    aws_secret_access_key = <redacted>
    ```

    This provides authentication to the AWS S3 bucket backend that stores the TF state

3. Navigate to the `talos` directory and then run the desired Terraform command (i.e. `terraform plan`, `terraform apply`).
