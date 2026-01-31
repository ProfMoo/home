terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.93.0"
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
