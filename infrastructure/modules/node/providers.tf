terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.1"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
