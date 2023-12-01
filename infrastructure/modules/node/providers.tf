terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.0"
    }
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
