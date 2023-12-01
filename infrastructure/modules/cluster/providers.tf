terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.4"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.0"
    }
  }
}
