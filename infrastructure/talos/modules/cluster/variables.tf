variable "proxmox_resource_pool" {
  type        = string
  default     = "testing-kubernetes-cluster"
  description = "Resource Pool to create on Proxmox for the cluster. Mainly used for resource/VM organization."
}

variable "talos_image_datastore" {
  type        = string
  default     = "local"
  description = "We need to download and store the desired Talos image on disk. This variable determines where we save it. Usually this is local storage on the Proxmox node."
}

variable "talos_version" {
  type        = string
  description = "Total version to use. Can identify the available versions here: https://github.com/siderolabs/talos/releases."
}

variable "talos_image_node_storage_name" {
  type        = string
  description = "Proxmox node used for storing the Talos image."
}

variable "worker_nodes" {
  type = map(object({
    # "Tags to apply to the worker node virtual machines in Proxmox"
    vm_tags = map(any)

    # The VM ID in proxmox (must be unique)
    vm_id = string



    # The number of cores to assign to this VM
    vm_cpu_cores = number
    # The amount of memory (in megabytes) to assign to this VM
    vm_memory = number
    # The disk size to allocation for the Talos node.
    vm_disk_size = string

    # The proxmox node to provision the VM on
    proxmox_node_name = string
    # The datastore that the VM will use to store the Talos configuration. Ideally, each talos node should install on its own datastore (i.e. physical disk).
    # SOURCE: https://onedr0p.github.io/home-ops/notes/proxmox-considerations.html
    proxmox_node_datastore = string
    # The network device that the VM will use to communicate with the outside world.
    # In general, this should be a network interface that bridges to a physical network interface.
    proxmox_node_network_device = string

    # The VLAN ID to use for the VM
    vm_vlan_id = string
  }))
}

variable "control_plane" {
  type = map(object({
    # "Tags to apply to the worker node virtual machines in Proxmox"
    vm_tags = map(any)

    # The VM ID in proxmox (must be unique)
    vm_id = string

    # The number of cores to assign to this VM
    vm_cpu_cores = number
    # The amount of memory (in megabytes) to assign to this VM
    vm_memory = number
    # The disk size to allocation for the Talos node.
    vm_disk_size = string

    # The proxmox node to provision the VM on
    proxmox_node_name = string
    # The datastore that the VM will use to store the Talos configuration. Ideally, each talos node should install on its own datastore (i.e. physical disk).
    # SOURCE: https://onedr0p.github.io/home-ops/notes/proxmox-considerations.html
    proxmox_node_datastore = string
    # The network device that the VM will use to communicate with the outside world.
    # In general, this should be a network interface that bridges to a physical network interface.
    proxmox_node_network_device = string

    # The VLAN ID to use for the VM
    vm_vlan_id = string
  }))
}
