terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.53.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.4.0"
    }
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }

  backend "s3" {
    bucket = "sobrien-home"
    key    = "infrastructure"
    region = "us-east-1"

    # To authenticate access to state (does not authenticate the actual terraform commands).
    # These credentials also need to have access to the KMS key used to decrypt the keys in ./secrets.sops.yaml.
    shared_credentials_file = "./aws-credentials"
  }
}

data "sops_file" "provider_credentials" {
  source_file = "secrets.sops.yaml"
}

provider "proxmox" {
  endpoint  = "https://192.168.1.64:8006/api2/json"
  api_token = data.sops_file.provider_credentials.data["secrets.proxmox.token"]
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}

provider "talos" {}

provider "unifi" {
  username = data.sops_file.provider_credentials.data["secrets.unifi.username"]
  password = data.sops_file.provider_credentials.data["secrets.unifi.password"]
  api_url  = "https://192.168.1.1/network/default"

  # I don't have certs setup on my unifi controller
  allow_insecure = true
}
