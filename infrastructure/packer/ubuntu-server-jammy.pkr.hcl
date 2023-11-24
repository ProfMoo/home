# Ubuntu Server jammy
# ---
# Packer Template to create an Ubuntu Server (jammy) on Proxmox

packer {
  required_plugins {
    proxmox-iso = {
      version = ">= 1.1.6"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variable Definitions
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

# Resource Definiation for the VM Template
source "proxmox" "ubuntu-server-jammy" {

  # Proxmox Connection Settings
  proxmox_url = var.proxmox_api_url
  username    = var.proxmox_api_token_id
  token       = var.proxmox_api_token_secret
  # (Optional) Skip TLS Verification
  insecure_skip_tls_verify = true

  # VM General Settings
  node                 = "pve"
  vm_id                = "106"
  vm_name              = "ubuntu-server-jammy"
  template_description = "Ubuntu Server Jammy Image"

  # VM OS Settings
  # (Option 1) Local ISO File
  # iso_file = "local:iso/ubuntu-22.04-live-server-amd64.iso"
  # - or -
  # (Option 2) Download ISO
  iso_url          = "https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.img"
  iso_checksum     = "a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
  iso_storage_pool = "local"
  unmount_iso      = true

  # VM System Settings
  qemu_agent = true

  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-pci"


  disks {
    disk_size         = "20G"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    type              = "virtio"
  }

  # VM Network Settings
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }

  # VM CPU Settings
  cores = "2"

  # VM Memory Settings
  memory = "4096"

  # VM Cloud-Init Settings
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # PACKER Boot Commands
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds='nocloud-net;s=http://192.168.1.78:51015/' ---<wait>",
    "<f10><wait>"
  ]

  boot = "c"
  # We need to be at the boot page (GNU GRUB) before running the boot command
  boot_wait = "5s"

  # PACKER Autoinstall Settings
  http_directory = "http"
  # (Optional) Bind IP Address and Port
  http_bind_address = "0.0.0.0"
  http_port_min     = 51015
  http_port_max     = 51015

  ssh_username = "drmoo"

  # (Option 1) Add your Password here
  ssh_password = "password"
  # - or -
  # (Option 2) Add your Private SSH KEY file here
  # ssh_private_key_file = "~/.ssh/id_rsa"

  # Raise the timeout, when installation takes longer
  ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

  name    = "ubuntu-server-jammy"
  sources = ["source.proxmox.ubuntu-server-jammy"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # Add additional provisioning scripts here
  # ...
}
