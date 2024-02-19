# NOTE: It's critical to create the reservations in the DHCP server before creating the VMs
# or else risk the VMs getting assigned a different IP address than the one we intend, which
# would make it impossible to access via Terraform (without asking the DHCP server for the IP).
resource "unifi_user" "this" {
  mac  = var.mac_address
  name = var.name
  note = "Provisioned via Terraform"

  fixed_ip   = var.ipv4_address
  network_id = var.vlan_id
}

resource "proxmox_virtual_environment_vm" "talos_node" {
  depends_on = [
    # NOTE: We need to wait for this assignment so that the VM doesn't start up and get
    # assigned an address via DHCP before the fixed IP is assigned to the MAC by the DHCP server.
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

  network_device {
    bridge      = var.bridge_network_device
    mac_address = unifi_user.this.mac
    firewall    = false
    vlan_id     = var.vlan_id
    model       = "virtio"
  }

  # NOTE: The boot order is important because we want the VM to boot from the CDROM first, then the disk.
  # Talos functions by booting from the CDROM initially, then performing API-driven updates onto the disk, then rebooting from the disk.
  boot_order = ["scsi0", "ide2", "net0"]

  # NOTE: This provides Talos a location to store its configured state when it's configured via the API.
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

  # NOTE: This runs a script against Kubernets on TF destroy. 
  # Kubernetes nodes need to be drained before deleted, or else the cluster can end up in some really tricky states.
  provisioner "local-exec" {
    when    = destroy
    command = "echo '${self.name}' && ./bin/manage_nodes remove ${self.name}"
  }
}
