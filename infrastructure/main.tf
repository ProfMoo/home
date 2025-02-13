module "talos_1_9_2_iso" {
  source = "./modules/talos-iso"

  # The Proxmox default storage pool allocated for the Proxmox node itself is "local", but you can use any storage pool you want.
  talos_image_datastore = "local"

  talos_version = "1.9.2"
  # The Proxmox node identifier for the storage location of the Talos image
  talos_image_storage_node = "pve"
}



module "cluster" {
  source = "./modules/cluster"

  proxmox_resource_pool   = "kubernetes"
  kubernetes_cluster_name = "homelab"

  control_plane = {
    "control_plane_instance_0" = {
      id          = "1000"
      name        = "porter-robinson"
      description = "Control plane instance in the Kubernetes homelab cluster"
      tags        = ["control-plane", "kubernetes"]
      cpu_cores   = 2
      memory      = 6144
      disk_size   = "50"
      datastore   = "disk2"

      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.9.2"
      kubernetes_version = "1.32.1"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      # VLAN 2 configuration
      vlan_id        = "2"
      ipv4_address   = "192.168.8.20"
      mac_address    = "52:74:f2:b3:a4:1c"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"
    },
    "control_plane_instance_1" = {
      id                    = "1001"
      name                  = "mr-carmack"
      description           = "Control plane instance in the Kubernetes homelab cluster"
      tags                  = ["control-plane", "kubernetes"]
      cpu_cores             = 2
      memory                = 6144
      disk_size             = "50"
      datastore             = "disk1"
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.9.2"
      kubernetes_version = "1.32.1"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      # VLAN 2 configuration
      vlan_id        = "2"
      ipv4_address   = "192.168.8.21"
      mac_address    = "e4:92:a3:d1:b6:7f"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"
    },
    "control_plane_instance_2" = {
      id                    = "1002"
      name                  = "daft-punk"
      description           = "Control plane instance in the Kubernetes homelab cluster"
      tags                  = ["control-plane", "kubernetes"]
      cpu_cores             = 2
      memory                = 6144
      disk_size             = "50"
      datastore             = "disk3"
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.9.2"
      kubernetes_version = "1.32.1"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      # VLAN 2 configuration
      vlan_id        = "2"
      ipv4_address   = "192.168.8.22"
      mac_address    = "3e:4f:2c:9a:5d:1b"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"
    }
  }

  worker_nodes = {
    "worker_node_instance_0" = {
      id          = "1100"
      name        = "skrillex"
      description = "Worker node instance in the Kubernetes homelab cluster"
      tags        = ["worker-node", "kubernetes"]
      cpu_cores   = 10
      memory      = 32768 # 32GB
      disk_size   = "100"
      datastore   = "disk3"

      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.9.2"
      kubernetes_version = "1.32.1"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      # VLAN 1 configuration
      vlan_id        = "2"
      ipv4_address   = "192.168.8.120"
      mac_address    = "e4:f8:b3:a2:b1:c8"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"
    },
    "worker_node_instance_1" = {
      id                    = "1101"
      name                  = "flume"
      description           = "Worker node instance in the Kubernetes homelab cluster"
      tags                  = ["worker-node", "kubernetes"]
      cpu_cores             = 10
      memory                = 32768 # 32GB
      disk_size             = "100"
      datastore             = "disk1"
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.9.2"
      kubernetes_version = "1.32.1"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      vlan_id        = "2"
      ipv4_address   = "192.168.8.121"
      mac_address    = "d4:9f:6a:b1:5c:2f"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"
    },
    "worker_node_instance_2" = {
      id                    = "1102"
      name                  = "jon-hopkins"
      description           = "Worker node instance in the Kubernetes homelab cluster"
      tags                  = ["worker-node", "kubernetes"]
      cpu_cores             = 10
      memory                = 32768 # 32GB
      disk_size             = "100"
      datastore             = "disk2"
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.9.2"
      kubernetes_version = "1.32.1"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      vlan_id        = "2"
      ipv4_address   = "192.168.8.122"
      mac_address    = "94:96:cc:43:7d:76"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"
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

output "worker_node_configs" {
  value     = module.cluster.worker_node_configs
  sensitive = true
}

output "control_plane_configs" {
  value     = module.cluster.control_plane_configs
  sensitive = true
}
