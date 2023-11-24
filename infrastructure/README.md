# Infrastructure

This directory houses the code that transform raw baremetal machines into functional Kubernetes clusters. It's currently divided into two directories: `packer` and `k8s`. The `packer` directory uses a LAN-accessible Proxmox VE installation to create a ready-to-k8s VM image. The `k8s` directory uses the output VM template from the `packer` directory to standup multiple VMs and create a bare-bones K3s cluster.

## How To Use

1. Install Proxmox VE v8.0+ on a baremetal machine.
2. Ensure you have a file named `aws-credentials` in the `virtualization` directory in the format:

    ```text
    [default]
    aws_access_key_id = <redacted>
    aws_secret_access_key = <redacted>
    ```

3. Run the `./packer/run.sh` script.
   1. This creates the necessary VM templates that we will use as a base for building VMs declaratively
4. Run `./k8s/docker_run.sh apply -auto-approve` (assuming you want to auto-approve) script. This will stand up the K8s cluster, outputting a kubeconfig.

## Terraform Plan

For local testing and verification, you can use the `k8s` script directly:

```bash
./docker_run.sh $TERRAFORM_COMMANDS_HERE
# Ex: ./docker_run.sh apply -auto-approve
# Ex: ./docker_run.sh plan
```
