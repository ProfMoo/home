# NOTE: This creates the random mac addresses that we assign to the VMs
resource "macaddress" "worker_node_mac_addresses" {
  count = var.worker_node_num
}

resource "proxmox_virtual_environment_vm" "worker_node" {
  depends_on = [
    macaddress.worker_node_mac_addresses
  ]

  count = var.worker_node_num
  vm_id = "${var.worker_node_vmid_prefix}${count.index + 1}"

  pool_id   = proxmox_virtual_environment_pool.proxmox_resource_pool.id
  node_name = var.worker_node_node_name

  name        = "${var.worker_node_hostname_prefix}-${count.index + 1}"
  description = "${var.worker_node_hostname_prefix}: ${count.index + 1}"
  tags        = var.worker_node_tags

  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = var.worker_node_cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.worker_node_memory
  }

  network_device {
    bridge      = var.worker_node_network_device
    mac_address = macaddress.worker_node_mac_addresses[count.index].address
    firewall    = false
  }

  boot_order = ["scsi0", "ide2", "net0"]

  # NOTE: This provides Talos a location to store its state when it's configured via the API.
  disk {
    datastore_id = var.worker_node_datastore
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.worker_node_disk_size
  }

  # NOTE: This loads the Talos onto disk via block storage.
  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_file.talos_image.id
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
    command = "./bin/manage_nodes remove ${self.name}"
  }
}
