variable "proxmox_resource_pool" {
  type        = string
  default     = "kubernetes-cluster"
  description = "Resource Pool to create on Proxmox for the cluster. Mainly used for resource/VM organization."
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "Kubernetes cluster name you wish for Talos to use"
}

variable "control_plane" {
  type = map(object({
    id                    = string
    name                  = string
    description           = string
    tags                  = list(string)
    cpu_cores             = number
    memory                = number
    bridge_network_device = string
    proxmox_node_name     = string
    initial_boot_iso      = string

    disk_size = number
    datastore = string

    talos_version      = string
    kubernetes_version = string

    talos_virtual_ip = string

    vlan_id        = string
    ipv4_address   = string
    mac_address    = string
    subnet_gateway = string

    # NOTE: The two values below are CIDRs separated by a comma
    pod_subnets     = string
    service_subnets = string

    kubernetes_node_labels = map(string)
  }))
}

variable "worker_nodes" {
  type = map(object({
    id                    = string
    name                  = string
    description           = string
    tags                  = list(string)
    cpu_cores             = number
    memory                = number
    bridge_network_device = string
    proxmox_node_name     = string
    initial_boot_iso      = string

    disk_size                      = number
    datastore                      = string
    enable_storage_cluster         = bool
    storage_cluster_datastore_id   = optional(string)
    storage_cluster_disk_interface = optional(string)
    storage_cluster_disk_size      = optional(number)

    talos_version      = string
    kubernetes_version = string

    talos_virtual_ip = string

    vlan_id        = string
    ipv4_address   = string
    mac_address    = string
    subnet_gateway = string

    # NOTE: The two values below are CIDRs separated by a comma
    pod_subnets     = string
    service_subnets = string

    kubernetes_node_labels = map(string)
  }))
}
