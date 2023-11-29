terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.4"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.0"
    }
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
  }

  backend "s3" {
    bucket = "sobrien-home"
    key    = "infrastructure"
    region = "us-east-1"
    # To authenticate to access the state (not the actual terraform commands)
    shared_credentials_file = "./aws-credentials"
  }
}

provider "proxmox" {
  endpoint  = "https://192.168.1.64:8006/api2/json"
  api_token = "root@pam!tjs-test-2=fd03ad68-f6fd-4610-8dc2-4b6af00e7407"
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}

provider "talos" {}


provider "unifi" {
  # I haven't configured TLS communications for my controller
  allow_insecure = true
}

data "unifi_network" "lan_network" {
  name = "Default"
}
