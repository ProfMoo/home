variable "id" {
  type        = string
  description = "The VM ID in Proxmox (must be unique)"
}

variable "description" {
  type        = string
  description = "Optional description for the VM in Proxmox"
  default     = ""
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to the worker node virtual machines in Proxmox"
  default = {
    # Define default values or leave empty, depending on your needs
  }
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
  type        = string
  description = "The disk size to allocate for the Talos node to store its configuration and boot from."
  default     = "50G"
}

variable "datastore" {
  type        = string
  description = "The datastore that the VM will use to store the Talos configuration. Corresponds to a datastore on the Proxmox node. Ideally, each Talos node should install on its own datastore (i.e. physical disk)."
  default     = "local-lvm" # The default name for the data partitiion available to VMs in Proxmox
}

variable "vlan_id" {
  type        = string
  description = "The VLAN ID to use for the VM"
}

variable "network_device" {
  type        = string
  description = "The network device that the VM will use to communicate with the outside world. Corresponds to a network device on the Proxmox node. In general, this should be a network interface that bridges to a physical network interface."
  default     = "vmbr0" # The default name for the first bridge interface in Proxmox
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
