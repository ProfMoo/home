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
  node_name    = "pve2"

  source_file {
    path      = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    file_name = "ubuntu-22.04-cloudimg.img"
  }
}

# Cloud-init configuration file to enable password authentication
resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve2"

  source_raw {
    data = <<-EOF
      #cloud-config
      users:
        - name: ${local.ubuntu_username}
          passwd: ${local.ubuntu_password}
          lock_passwd: false
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_pwauth: true

      ssh_pwauth: true
      disable_root: false

      package_update: true
      packages:
        - qemu-guest-agent

      runcmd:
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
        - sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
        - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        - systemctl restart sshd
    EOF

    file_name = "ubuntu-roon-cloud-config.yaml"
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
    proxmox_virtual_environment_file.cloud_config,
  ]

  vm_id = "2000" # Choose an available VM ID

  node_name = "pve2"
  name      = "ubuntu-roon"

  description = "Ubuntu VM for Roon Server - Login: ${local.ubuntu_username}/${local.ubuntu_password}"
  tags        = ["roon", "media", "ubuntu"]

  # CPU Configuration - Good performance for Roon Server
  cpu {
    cores = 4      # 4 cores for good DSP/upsampling performance
    type  = "host" # Use host CPU type for best performance
  }

  # Memory Configuration - Plenty for Ubuntu + Roon
  memory {
    dedicated = 8192 # 8GB for comfortable Ubuntu desktop + Roon Server
  }

  # Network Configuration for VLAN 1
  network_device {
    bridge      = "vmbr0"
    mac_address = unifi_user.ubuntu_roon.mac
    firewall    = false
    # vlan_id     = 1        # Remove VLAN tagging - use native/untagged
    model = "virtio" # VirtIO for best performance
  }

  # Main disk for Ubuntu + Roon (imported from cloud image)
  disk {
    datastore_id = "disk1"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    size         = 128 # Resize to 128GB for OS, Roon, and database
  }

  # Cloud-init configuration (inline)
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

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  # Enable QEMU guest agent for better VM management
  agent {
    enabled = true
    timeout = "1s"
  }

  # Operating system type
  operating_system {
    type = "l26" # Linux
  }

  # Machine type
  machine = "q35"

  # Use UEFI for modern Ubuntu
  bios = "ovmf"

  # EFI disk for UEFI boot
  efi_disk {
    datastore_id = "disk1"
    file_format  = "raw"
  }

  # Start VM automatically - it's ready to go!
  started = true
}

# Output the VM's details
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

# After applying this configuration, a few things needs to be installed:
# sudo apt update && sudo apt install ubuntu-desktop-minimal firefox ffmpeg cifs-utils
# wget https://download.roonlabs.net/builds/roonserver-installer-linuxx64.sh
# chmod +x roonserver-installer-linuxx64.sh
# sudo ./roonserver-installer-linuxx64.sh
