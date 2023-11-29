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
