# NOTE: This creates the random mac addresses that we assign to the VMs
resource "macaddress" "control_plane_mac_addresses" {
  count = var.controlplane_num
}

resource "proxmox_virtual_environment_vm" "controlplane" {
  depends_on = [
    macaddress.control_plane_mac_addresses
  ]

  count = var.controlplane_num
  vm_id = "${var.controlplane_vmid_prefix}${count.index + 1}"

  pool_id   = proxmox_virtual_environment_pool.proxmox_resource_pool.id
  node_name = var.controlplane_node_name

  name        = "${var.controlplane_hostname_prefix}-${count.index + 1}"
  description = "${var.controlplane_hostname_prefix}: ${count.index + 1}"
  tags        = var.controlplane_tags

  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = var.controlplane_cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.controlplane_memory
  }

  network_device {
    bridge      = var.controlplane_network_device
    mac_address = macaddress.control_plane_mac_addresses[count.index].address
    vlan_id     = var.controlplane_vlan_id
    firewall    = true
  }

  # NOTE: THis loads the Talos onto disk via block storage.
  disk {
    datastore_id = var.workernode_datastore
    file_id      = proxmox_virtual_environment_file.talos_image.id
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.workernode_disk_size
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # Talos is responsible for installing the QEMU guest agent, but this creates some issues with the Proxmox TF provider.
  # The Proxmox provider expects significantly different behavior depending on whether or not the agent is installed.
  # So we enable it, but quickly time it out so that the Proxmox provider doens't wait for it to start.
  agent {
    enabled = true
    timeout = "1s"
  }

  operating_system {
    type = "l26"
  }

  vga {
    enabled = true
    memory  = 4
  }

  # Remove the node from Kubernetes on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "./bin/manage_nodes remove ${self.name}"
  }
}
