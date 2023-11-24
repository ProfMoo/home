# Virtualization

This Terraform code creates the VMs.

## How To Use

1. Install Proxmox v8.0 on a baremetal machine
2. Follow [this video](https://www.youtube.com/watch?v=shiIi38cJe4) to create VM template on the Proxmox machine.

## Quick Start

1. Ensure you have a file named `aws-credentials` in this directory in the format:

    ```text
    [default]
    aws_access_key_id = <redacted>
    aws_secret_access_key = <redacted>
    ```

2. Run:

    ```bash
    ./run.sh $TERRAFORM_COMMANDS_HERE
    # Ex: ./docker_run.sh apply -auto-approve
    # Ex: ./docker_run.sh plan
    ```
