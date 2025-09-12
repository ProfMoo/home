module "talos_1_9_2_iso" {
  source = "./modules/talos-iso"

  # The Proxmox default storage pool allocated for the Proxmox node itself is "local", but you can use any storage pool you want.
  talos_image_datastore = "local"

  talos_version = "1.9.2"
  # The Proxmox node identifier for the storage location of the Talos image
  talos_image_storage_node = "pve"
}

module "talos_1_9_2_iso_pve2" {
  source = "./modules/talos-iso"

  # The Proxmox default storage pool allocated for the Proxmox node itself is "local", but you can use any storage pool you want.
  talos_image_datastore = "local"

  talos_version = "1.9.2"
  # The Proxmox node identifier for the storage location of the Talos image
  talos_image_storage_node = "pve2"
}

module "talos_1_10_6_iso_pve2" {
  source = "./modules/talos-iso"

  # The Proxmox default storage pool allocated for the Proxmox node itself is "local", but you can use any storage pool you want.
  talos_image_datastore = "local"

  talos_version = "1.10.6"
  # The Proxmox node identifier for the storage location of the Talos image
  talos_image_storage_node = "pve2"
}

module "cluster" {
  source = "./modules/cluster"

  proxmox_resource_pool   = "kubernetes"
  kubernetes_cluster_name = "homelab"

  control_plane = {
    "control_plane_instance_0" = {
      id                    = "1000"
      name                  = "porter-robinson"
      description           = "Control plane instance in the Kubernetes homelab cluster"
      tags                  = ["control-plane", "kubernetes"]
      cpu_cores             = 3
      memory                = 8096
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      disk_size = "50"
      datastore = "disk2"

      enable_storage_cluster = false

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.10.6"
      kubernetes_version = "1.33.4"

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

      kubernetes_node_labels = {
        "drmoo.io/role" : "controlplane"
        "drmoo.io/zone" : "pve"
      }
    },
    "control_plane_instance_1" = {
      id                    = "1001"
      name                  = "fox-stevenson"
      description           = "Control plane instance in the Kubernetes homelab cluster"
      tags                  = ["control-plane", "kubernetes"]
      cpu_cores             = 3
      memory                = 8096
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      disk_size = "50"
      datastore = "disk1"

      enable_storage_cluster = false

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.10.6"
      kubernetes_version = "1.33.4"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      # VLAN 2 configuration
      vlan_id        = "2"
      ipv4_address   = "192.168.8.24"
      mac_address    = "e4:92:a3:d1:bc:8e"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"

      kubernetes_node_labels = {
        "drmoo.io/role" : "controlplane"
        "drmoo.io/zone" : "pve"
      }
    },
    "control_plane_instance_2" = {
      id                    = "1002"
      name                  = "daft-punk"
      description           = "Control plane instance in the Kubernetes homelab cluster"
      tags                  = ["control-plane", "kubernetes"]
      cpu_cores             = 3
      memory                = 8096
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve2"
      initial_boot_iso      = module.talos_1_10_6_iso_pve2.talos_iso_id

      disk_size = "50"
      datastore = "disk3"

      enable_storage_cluster = false

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.10.6"
      kubernetes_version = "1.33.4"

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

      kubernetes_node_labels = {
        "drmoo.io/role" : "controlplane"
        "drmoo.io/zone" : "pve2"
      }
    }
  }

  worker_nodes = {
    "worker_node_instance_0" = {
      id                    = "1100"
      name                  = "skrillex"
      description           = "Worker node instance in the Kubernetes homelab cluster"
      tags                  = ["worker-node", "kubernetes"]
      cpu_cores             = 15
      memory                = 49152 # 48GB
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      disk_size = "200"
      datastore = "disk3"

      storage_disks = [
        {
          datastore_id   = "disk3"
          disk_interface = "scsi1"
          size           = 200
        }
      ]

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.10.6"
      kubernetes_version = "1.33.4"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      # VLAN 2 configuration
      vlan_id        = "2"
      ipv4_address   = "192.168.8.124"
      mac_address    = "e4:f8:b3:a2:b1:e1"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"

      kubernetes_node_labels = {
        "drmoo.io/role" : "worker"
        "drmoo.io/zone" : "pve"
        "drmoo.io/storage" : "rook-osd-node"
      }
    },
    "worker_node_instance_1" = {
      id                    = "1101"
      name                  = "mat-zo"
      description           = "Worker node instance in the Kubernetes homelab cluster"
      tags                  = ["worker-node", "kubernetes"]
      cpu_cores             = 15
      memory                = 49152 # 48GB
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve"
      initial_boot_iso      = module.talos_1_9_2_iso.talos_iso_id

      disk_size = "200"
      datastore = "disk2"

      storage_disks = [
        {
          datastore_id   = "disk2"
          disk_interface = "scsi1"
          size           = 200
        },
        {
          datastore_id   = "disk4"
          disk_interface = "scsi2"
          size           = 500
        }
      ]

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.10.6"
      kubernetes_version = "1.33.4"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      vlan_id        = "2"
      ipv4_address   = "192.168.8.119"
      mac_address    = "d4:9f:6a:b1:5c:4e"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"

      kubernetes_node_labels = {
        "drmoo.io/role" : "worker"
        "drmoo.io/zone" : "pve"
        "drmoo.io/storage" : "rook-osd-node"
      }
    },
    "worker_node_instance_3" = {
      id                    = "1103"
      name                  = "bonobo"
      description           = "Worker node instance in the Kubernetes homelab cluster"
      tags                  = ["worker-node", "kubernetes"]
      cpu_cores             = 56
      memory                = 114688 # 112GB
      bridge_network_device = "vmbr0"
      proxmox_node_name     = "pve2"
      initial_boot_iso      = module.talos_1_9_2_iso_pve2.talos_iso_id

      disk_size = "450"
      datastore = "disk1"

      storage_disks = [
        {
          datastore_id   = "disk2"
          disk_interface = "scsi1"
          size           = 450
        },
        {
          datastore_id   = "disk3"
          disk_interface = "scsi2"
          size           = 400
        }
      ]

      # This doesn't necessarily need to match the boot ISO.
      talos_version      = "1.10.6"
      kubernetes_version = "1.33.4"

      # External kubernetes network configuration
      talos_virtual_ip = "192.168.8.99"

      vlan_id        = "2"
      ipv4_address   = "192.168.8.123"
      mac_address    = "94:96:cc:43:7d:79"
      subnet_gateway = "192.168.8.1"

      # Internal kubernetes network configuration
      pod_subnets     = "10.244.0.0/16"
      service_subnets = "10.96.0.0/12"

      kubernetes_node_labels = {
        "drmoo.io/role" : "worker"
        "drmoo.io/zone" : "pve2"
        "drmoo.io/storage" : "rook-osd-node"
      }
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

# Automatically regens the Talos node configuration files.
resource "null_resource" "generate_talos_configs" {
  triggers = {
    # Only trigger when control plane or worker configurations change
    control_plane_changes = sha256(jsonencode(module.cluster.control_plane_configs))
    worker_changes        = sha256(jsonencode(module.cluster.worker_node_configs))
  }

  depends_on = [module.cluster]

  provisioner "local-exec" {
    command = "${path.module}/create_talos_node_configs"
  }
}

# Automatically repopulates the local Talosctl and Kubectl configurations.
resource "null_resource" "generate_cli_configs" {
  triggers = {
    # Only trigger when the CLI configs change
    kubeconfig_changes  = sha256(jsonencode(module.cluster.kubeconfig))
    talosconfig_changes = sha256(jsonencode(module.cluster.talosconfig))
  }

  depends_on = [module.cluster]

  provisioner "local-exec" {
    command = "${path.module}/get_local_configs"
  }
}
