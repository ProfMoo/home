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

variable "storage_disks" {
  type = list(object({
    datastore_id   = string
    disk_interface = string
    size           = number
  }))
  description = "List of storage disks for the storage cluster. This is used for Rook/Ceph. If provided, storage cluster will be automatically enabled."
  default     = []
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

variable "machine_type" {
  type        = string
  description = "The QEMU machine type. PCIe passthrough requires 'q35'. Defaults to 'pc' for backwards compatibility with existing nodes."
  default     = "pc"
}

variable "pci_devices" {
  type = list(object({
    mapping = string # Proxmox cluster-wide resource mapping name (e.g. 'tesla-t4'). Created in Datacenter > Resource Mappings.
    pcie    = bool   # Use PCIe (true) vs legacy PCI (false). Required true for modern GPUs. Requires machine_type='q35'.
    rombar  = bool   # Expose device option ROM to VM. Usually true.
    xvga    = bool   # Mark as primary display adapter. False for compute GPUs (e.g. Tesla T4) with no display outputs.
  }))
  description = "PCI devices to pass through to the VM (e.g. GPUs). Uses Proxmox resource mappings (api_token compatible). Requires machine_type='q35' if pcie=true."
  default     = []
}
