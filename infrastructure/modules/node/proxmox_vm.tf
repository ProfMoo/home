# NOTE: This creates the random mac addresses that we assign to the VMs
resource "macaddress" "mac_addresses" {}

resource "unifi_user" "this" {
  mac  = macaddress.mac_addresses.address
  name = var.name
  note = "Provisioned via the Terraform client"

  fixed_ip   = var.ipv4_address
  network_id = var.vlan_id
}

resource "proxmox_virtual_environment_vm" "talos_node" {
  depends_on = [
    macaddress.mac_addresses,
    // NOTE: We need to wait for this assignment so that the VM doesn't start up 
    // and get assigned an address via DHCP before the fixed IP is assigned to the MAC.
    unifi_user.this,
  ]

  vm_id = var.id

  pool_id   = var.proxmox_pool
  node_name = var.proxmox_node_name

  name        = var.name
  description = var.description
  tags        = var.tags

  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  initialization {
    ip_config {
      ipv4 {
        address = format("%s/24", var.ipv4_address)
      }
    }
  }

  network_device {
    bridge      = var.bridge_network_device
    mac_address = macaddress.mac_addresses.address
    firewall    = false
    vlan_id     = var.vlan_id
    model       = "virtio"
  }

  # NOTE: The boot order is important because we want the VM to boot from the CDROM first, then the disk.
  # Talos functions by booting from the CDROM initially, then performing API-driven updates onto the disk, then rebooting from the disk.
  boot_order = ["scsi0", "ide2", "net0"]

  # NOTE: This provides Talos a location to store its state when it's configured via the API.
  disk {
    datastore_id = var.datastore
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.disk_size
  }

  # NOTE: This loads the Talos onto disk via block storage.
  cdrom {
    enabled   = true
    file_id   = var.initial_boot_iso
    interface = "ide2"
  }

  # Talos is responsible for installing the QEMU guest agent, but this creates some issues with the Proxmox TF provider.
  # The Proxmox provider expects significantly different behavior depending on whether or not the agent is installed.
  # So we enable it, but quickly time it out so that the Proxmox provider doens't wait for it to start.
  # Details here: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#qemu-guest-agent
  agent {
    enabled = true
    timeout = "1s"
  }

  operating_system {
    type = "l26"
  }

  # Remove the node from Kubernetes on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "echo '${self.name}' && ./bin/manage_nodes remove ${self.name}"
  }
}
