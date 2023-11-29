module "talos_1.5.5_iso" {
  source = "./modules/talos-iso"

  # The Proxmox default storage pool allocated for the Proxmox node itself is "local", but you can use any storage pool you want.
  talos_image_datastore = "local"

  talos_version                 = "1.5.5"
  talos_image_node_storage_name = "pve"
}

module "testing_cluster" {
  source = "./modules/cluster"

  proxmox_resource_pool = "kubernetes-testing"

  control_plane = {
    "control_plane_instance_0" = {
      vm_tags                     = { "role" = "control-plane" }
      vm_id                       = "control-plane-01"
      vm_cpu_cores                = 2
      vm_memory                   = 4096
      vm_disk_size                = "50G"
      proxmox_node_name           = "proxmox-node-1"
      proxmox_node_datastore      = "local-lvm"
      proxmox_node_network_device = "vmbr0"
      vm_vlan_id                  = "1000"
    }
  }

  worker_nodes = {
    "worker_node_instance_0" = {
      vm_tags                     = { "role" = "worker-node" }
      vm_id                       = "worker-node-01"
      vm_cpu_cores                = 2
      vm_memory                   = 4096
      vm_disk_size                = "50G"
      proxmox_node_name           = "proxmox-node-2"
      proxmox_node_datastore      = "local-lvm"
      proxmox_node_network_device = "vmbr0"
      vm_vlan_id                  = "1100"
    },
  }
}
