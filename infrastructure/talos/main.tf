module "talos_1_5_5_iso" {
  source = "./modules/talos-iso"

  # The Proxmox default storage pool allocated for the Proxmox node itself is "local", but you can use any storage pool you want.
  talos_image_datastore = "local"

  talos_version            = "1.5.5"
  talos_image_storage_node = "pve"
}

module "cluster" {
  source = "./modules/cluster"

  proxmox_resource_pool   = "kubernetes"
  kubernetes_cluster_name = "homelab"
  talos_virtual_ip        = "192.168.1.99"

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

      # This doesn't necessarily need to match the boot ISO. 
      talos_version      = "1.5.5"
      kubernetes_version = "1.28.3"
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

      # This doesn't necessarily need to match the boot ISO. 
      talos_version      = "1.5.5"
      kubernetes_version = "1.28.3"
    }
    "worker_node_instance_1" = {
      id                    = "1101"
      name                  = "skrillex"
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

      # This doesn't necessarily need to match the boot ISO. 
      talos_version      = "1.5.5"
      kubernetes_version = "1.28.3"
    }
  }
}

output "control_plane_node_ips" {
  value = module.cluster.control_plane_nodes_ips
}

output "worker_node_ips" {
  value = module.cluster.worker_nodes_ips
}

output "kubeconfig" {
  value     = module.cluster.kubeconfig
  sensitive = true
}

output "talosconfig" {
  value     = module.cluster.talosconfig
  sensitive = true
}
