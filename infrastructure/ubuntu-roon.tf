# Ubuntu VM Configuration for Roon Server
# This creates a plug-and-play Ubuntu VM with pre-configured credentials

# Load secrets from SOPS
data "sops_file" "ubuntu_secrets" {
  source_file = "secrets.roon.sops.yaml"
}

locals {
  ubuntu_username = data.sops_file.ubuntu_secrets.data["data.username"]
  ubuntu_password = data.sops_file.ubuntu_secrets.data["data.password"]
}

# Download Ubuntu cloud image to Proxmox
resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve5"

  source_file {
    path      = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    file_name = "ubuntu-24.04-cloudimg.img"
  }
}

# DHCP Reservation for Ubuntu Roon VM on VLAN 1
resource "unifi_user" "ubuntu_roon" {
  mac  = "52:54:00:0f:42:44" # Unique MAC address for the Ubuntu Roon VM
  name = "ubuntu-roon"
  note = "Ubuntu VM for Roon Server - Provisioned via Terraform"

  fixed_ip   = "192.168.1.198" # Choose an available IP on VLAN 1 (avoiding conflict with existing Roon at .200)
  network_id = "1"             # VLAN 1
}

# Ubuntu VM for Roon Server
resource "proxmox_virtual_environment_vm" "ubuntu_roon" {
  depends_on = [
    unifi_user.ubuntu_roon,
    proxmox_virtual_environment_file.ubuntu_cloud_image,
  ]

  vm_id = "2001" # Changed from 2000 to force VM recreation with proper cloud-init

  node_name = "pve4"
  name      = "ubuntu-roon"

  description = "Ubuntu VM for Roon Server - Login: ${local.ubuntu_username}/${local.ubuntu_password}"
  tags        = ["roon", "media", "ubuntu"]

  # CPU Configuration - Good performance for Roon Server
  cpu {
    cores = 3
    type  = "host"
  }

  memory {
    dedicated = 14336
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = unifi_user.ubuntu_roon.mac
    firewall    = false
    model       = "virtio"
  }

  disk {
    datastore_id = "pve4-disk1"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    size         = 512
  }

  initialization {
    user_account {
      username = local.ubuntu_username
      password = local.ubuntu_password
    }

    ip_config {
      ipv4 {
        address = "192.168.1.198/24"
        gateway = "192.168.1.1"
      }
    }

    dns {
      servers = ["8.8.8.8", "1.1.1.1"] # Use public DNS directly, skip local resolver
    }
  }

  agent {
    enabled = true
    timeout = "1s"
  }

  operating_system {
    type = "l26" # Linux
  }

  machine = "q35"

  bios = "ovmf"

  efi_disk {
    datastore_id = "pve4-disk1"
    file_format  = "raw"
  }

  started = true
}

output "ubuntu_roon_ip" {
  value       = unifi_user.ubuntu_roon.fixed_ip
  description = "IP address of the Ubuntu Roon VM"
}

output "ubuntu_roon_mac" {
  value       = unifi_user.ubuntu_roon.mac
  description = "MAC address of the Ubuntu Roon VM"
}

output "ubuntu_roon_username" {
  value       = local.ubuntu_username
  description = "Username for the Ubuntu Roon VM"
  sensitive   = true
}

output "ubuntu_roon_password" {
  value       = local.ubuntu_password
  description = "Password for the Ubuntu Roon VM"
  sensitive   = true
}

# 1. After applying this configuration, a few things needs to be installed:
#   sudo apt update && sudo apt install ubuntu-desktop-minimal firefox ffmpeg cifs-utils bzip2
# 2. Access desktop GUI:
#   sudo systemctl enable gdm3 && sudo systemctl start gdm3
#   OR just 'reboot'
# 3. Download and install Roon Server:
#   wget https://download.roonlabs.net/builds/roonserver-installer-linuxx64.sh
#   chmod +x roonserver-installer-linuxx64.sh
#   sudo ./roonserver-installer-linuxx64.sh

# To mount storage (e.g. NFS share from NAS @ 192.168.1.26):
# 1. Install NFS client:
#   sudo apt update && sudo apt install nfs-common
# 2. Mount the NFS share:
#   sudo mkdir -p /mnt/music
#   sudo mount -t nfs 192.168.1.26:/path/to/music /mnt/music
# 3. Make it persistent across reboots:
#   echo "192.168.1.26:/path/to/music /mnt/music nfs defaults 0 0" | sudo tee -a /etc/fstab

# To restart Roon Server after the VM is rebooted should happen automatically, but to check:
#   sudo systemctl status roonserver
#   sudo journalctl -u roonserver
