variable "proxmox_resource_pool" {
  type        = string
  default     = "testing-kubernetes-cluster"
  description = "Resource Pool to create on Proxmox for the cluster. Mainly used for resource/VM organization."
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "Kubernetes cluster name you wish for Talos to use"
}

variable "talos_virtual_ip" {
  type        = string
  description = "Virtual IP to be used by Talos. https://www.talos.dev/v1.5/talos-guides/network/vip/"
}

variable "worker_nodes" {
  type = map(object({
    id                    = string
    name                  = string
    description           = string
    tags                  = list(string)
    cpu_cores             = number
    memory                = number
    disk_size             = number
    datastore             = string
    vlan_id               = string
    bridge_network_device = string
    proxmox_node_name     = string

    initial_boot_iso = string

    talos_version      = string
    kubernetes_version = string
  }))
}

variable "control_plane" {
  type = map(object({
    id                    = string
    name                  = string
    description           = string
    tags                  = list(string)
    cpu_cores             = number
    memory                = number
    disk_size             = number
    datastore             = string
    vlan_id               = string
    bridge_network_device = string
    proxmox_node_name     = string

    initial_boot_iso = string

    talos_version      = string
    kubernetes_version = string
  }))
}
