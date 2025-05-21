variable "id" {
  type        = string
  description = "The VM ID in Proxmox (must be unique)"
}

variable "name" {
  type        = string
  description = "Name of the VM"
  default     = ""
}

variable "description" {
  type        = string
  description = "Optional description for the VM in Proxmox"
  default     = ""
}

variable "tags" {
  type        = list(string)
  description = "Tags to apply to the worker node virtual machines in Proxmox"
  default     = []
}

variable "cpu_cores" {
  type        = number
  description = "The number of cores to assign to this VM"
  default     = 2
}

variable "memory" {
  type        = number
  description = "The amount of memory (in megabytes) to assign to this VM"
  default     = 4096
}

variable "disk_size" {
  type        = number
  description = "The disk size (in GB) to allocate for the Talos node to store its configuration and boot from."
  default     = 50
}

variable "datastore" {
  type        = string
  description = "The datastore that the VM will use to store the Talos configuration. Corresponds to a datastore on the Proxmox node. Ideally, each Talos node should install on its own datastore (i.e. physical disk)."
  default     = "local-lvm" # The default name for the data partitiion available to VMs in Proxmox
}

variable "enable_storage_cluster" {
  type        = bool
  description = "Whether to enable the storage cluster for the VM. This is used for Rook/Ceph."
  default     = false
}

variable "storage_cluster_datastore_id" {
  type        = string
  description = "The datastore ID for the storage cluster. This is used for Rook/Ceph."
  default     = ""
}

variable "storage_cluster_disk_interface" {
  type        = string
  description = "The disk interface for the storage cluster. This is used for Rook/Ceph."
  default     = ""
}

variable "storage_cluster_disk_size" {
  type        = number
  description = "The disk size (in GB) for the storage cluster. This is used for Rook/Ceph."
  default     = 50
}

variable "bridge_network_device" {
  type        = string
  description = "The network device that the VM will use to communicate with the outside world. Corresponds to a network device on the Proxmox node. This should be a network interface that bridges to a physical network interface."
  default     = "vmbr0" # The default name for the first bridge interface in Proxmox
}

variable "ipv4_address" {
  type        = string
  description = "The ipv4 address that is assigned to the newly created VM"
}

variable "mac_address" {
  type        = string
  description = "The MAC address that is assigned to the newly created VM"
}

variable "proxmox_node_name" {
  type        = string
  description = "The Proxmox node to provision the VM on"
}

variable "proxmox_pool" {
  type        = string
  description = "The Proxmox pool to provision the VM on"
}

variable "initial_boot_iso" {
  type        = string
  description = "The ISO to boot the VM from initially. This should be the Talos ISO."
}

variable "vlan_id" {
  type        = string
  description = "The ID of the VLAN to use for the VM. This should correspond to a VLAN on the gateway of the network."
}
