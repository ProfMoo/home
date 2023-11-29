variable "proxmox_resource_pool" {
  type        = string
  default     = "testing-kubernetes-cluster"
  description = "Resource Pool to create on Proxmox for the cluster. Mainly used for resource/VM organization."
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
  }))
}
