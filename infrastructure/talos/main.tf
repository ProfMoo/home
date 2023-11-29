module "talos_1_5_5_iso" {
  source = "./modules/talos-iso"

  # The Proxmox default storage pool allocated for the Proxmox node itself is "local", but you can use any storage pool you want.
  talos_image_datastore = "local"

  talos_version            = "1.5.5"
  talos_image_storage_node = "pve"
}

module "testing_cluster" {
  source = "./modules/cluster"

  proxmox_resource_pool = "kubernetes-testing"

  control_plane = {
    "control_plane_instance_0" = {
      id                    = "1000"
      name                  = "porter-robinson"
      description           = "Control plane instance in the Kubernetes testing cluster"
      tags                  = ["control-plane", "kubernetes"]
      cpu_cores             = 2
      memory                = 4096
      disk_size             = "50"
      datastore             = "local-lvm"
      vlan_id               = "0"
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_5_5_iso.talos_iso_id
    }
  }

  worker_nodes = {
    "worker_node_instance_0" = {
      id                    = "1100"
      name                  = "madeon"
      description           = "Worker node instance in the Kubernetes testing cluster"
      tags                  = ["worker-node", "kubernetes"]
      cpu_cores             = 2
      memory                = 4096
      disk_size             = "50"
      datastore             = "local-lvm"
      vlan_id               = "0"
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_5_5_iso.talos_iso_id
    }
  }
}
