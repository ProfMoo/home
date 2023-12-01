# Remote Storage

This Terraform code is used to generate the AWS resources necessary for long-time archival S3 storage. I use S3 as a low-cost, API-driven remote backup service.

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

## TODO

Add Sops key to the managed state here if I end up using Sops
