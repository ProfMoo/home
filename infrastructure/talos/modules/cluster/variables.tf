variable "proxmox_resource_pool" {
  type        = string
  default     = "testing-kubernetes-cluster"
  description = "Resource Pool to create on Proxmox for the cluster. Mainly used for resource/VM organization."
}

variable "worker_nodes" {
  type = map(object({
    id                = string
    description       = string
    tags              = map(any)
    cpu_cores         = number
    memory            = number
    disk_size         = string
    datastore         = string
    vlan_id           = string
    network_device    = string
    proxmox_node_name = string
    proxmox_pool      = string
    initial_boot_iso  = string
  }))
}

variable "control_plane" {
  type = map(object({
    id                = string
    description       = string
    tags              = map(any)
    cpu_cores         = number
    memory            = number
    disk_size         = string
    datastore         = string
    vlan_id           = string
    network_device    = string
    proxmox_node_name = string
    proxmox_pool      = string
    initial_boot_iso  = string
  }))
}
