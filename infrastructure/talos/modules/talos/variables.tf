
variable "control_plane_ip_prefix" {
  # While I use DHCP reservation to assign IP Addresses to each virtual machine, talos must know
  # the IP Address of a node in order to apply configuration and bootstrap it. This prefix is used
  # in combination with the VM count integer to form the dynamic IP Address of each node. As a
  # consequence, only 9 of each control_plane and worker_node are supported: 101-109
  type        = string
  description = "IP address prefix (less the last digit) of the control_plane nodes"
}
variable "worker_node_ip_prefix" {
  # While I use DHCP reservation to assign IP Addresses to each virtual machine, talos must know
  # the IP Address of a node in order to apply configuration and bootstrap it. This prefix is used
  # in combination with the VM count integer to form the dynamic IP Address of each node. As a
  # consequence, only 9 of each control_plane and worker_node are supported: 151-159
  type        = string
  description = "IP address prefix (less the last digit) of the Worker Nodes"
}


# control_planes
variable "control_plane_vmid_prefix" {
  # I set my VMIDs according to my IP Addressing.
  # This prefix has the last digit set to the Terraform Count.
  type        = number
  description = "VMID prefix (less the last digit) of the control_plane nodes"
}
variable "control_plane_num" {
  type        = number
  default     = 1
  description = "Quantity of control_plane nodes to provision"
}
variable "control_plane_hostname_prefix" {
  type        = string
  default     = "k8s-cp"
  description = "Hostname prefix (less the last digit) of the control_plane nodes"
}
variable "control_plane_node_name" {
  type        = string
  description = "Proxmox node used for provisioning the worker_nodes"
}
variable "control_plane_tags" {
  type        = list
  default     = ["app-kubernetes", "type-control_plane"]
  description = "Tags to apply to the control_plane virtual machines"
}
variable "control_plane_cpu_cores" {
  type        = number
  default     = 4
  description = "Quantity of CPU cores to apply to the control_plane virtual machines"
}
variable "control_plane_memory" {
  type        = number
  default     = 8096
  description = "Quantity of memory (megabytes) to apply to the control_plane virtual machines"
}
variable "control_plane_datastore" {
  type        = string
  default     = "FlashPool"
  description = "Datastore used for the control_plane virtual machines"
}
variable "control_plane_disk_size" {
  # Talos recommends 100Gb
  type        = string
  default     = "50"
  description = "Quantity of disk space (gigabytes) to apply to the control_plane virtual machines"
}
variable "control_plane_network_device" {
  type        = string
  default     = "vmbr0"
  description = "Network device used for the control_plane virtual machines"
}
variable "control_plane_vlan_id" {
  type        = number
  default     = null
  description = "VLAN ID used for the control_plane nodes"
}


# Worker Nodes
variable "worker_node_vmid_prefix" {
  # I set my VMIDs according to my IP Addressing.
  # This prefix has the last digit set to the Terraform Count.
  type        = number
  description = "The VMID Prefix (less the last digit) of the worker_node nodes"
}
variable "worker_node_num" {
  type        = number
  default     = 1
  description = "Quantity of worker_node nodes to provision"
}
variable "worker_node_hostname_prefix" {
  type        = string
  default     = "k8s-node"
  description = "Hostname prefix (less the last digit) of the worker_node nodes"
}
variable "worker_node_node_name" {
  type        = string
  description = "Proxmox node used for provisioning the worker_nodes"
}
variable "worker_node_tags" {
  type        = list
  default     = ["app-kubernetes", "type-worker_node"]
  description = "Tags to apply to the worker_node virtual machines"
}
variable "worker_node_cpu_cores" {
  type        = number
  default     = 10
  description = "Quantity of CPU cores to apply to the worker_node virtual machines"
}
variable "worker_node_memory" {
  type        = number
  default     = 51200
  description = "Quantity of memory (megabytes) to apply to the worker_node virtual machines"
}
variable "worker_node_datastore" {
  type        = string
  description = "Datastore used for the worker_node virtual machines"
}
variable "worker_node_disk_size" {
  # Talos recommends 100Gb
  type        = string
  default     = "50"
  description = "Quantity of disk space (gigabytes) to apply to the worker_node virtual machines"
}
variable "worker_node_network_device" {
  type        = string
  default     = "vmbr0"
  description = "Network device used for the worker_node virtual machines"
}
variable "worker_node_vlan_id" {
  type        = number
  default     = null
  description = "VLAN ID used for the worker_node nodes"
}
