variable "kubernetes_version" {
  type        = string
  description = "Identify desired version from the list here: https://github.com/siderolabs/kubelet/pkgs/container/kubelet"
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "Kubernetes cluster name you wish for Talos to use"
}

variable "cluster_endpoint_ip" {
  type        = string
  description = "The IPv4 address of the node we want to configure"
}

variable "talos_version" {
  type        = string
  description = "Talos version to use. Can identify the available versions here: https://github.com/siderolabs/talos/releases."
}

variable "talos_cluster_secrets" {
  type        = any
  description = "The cluster secrets to use for the Talos cluster."
}

variable "node_ip" {
  type        = string
  description = "The IPv4 address of the node we want to operate on"
}

variable "talos_machine_type" {
  type        = string
  description = "The Kubernetes note type that Talos will configure this node as"

  validation {
    condition     = contains(["controlplane", "worker"], var.talos_machine_type)
    error_message = "Invalid value. Must be either 'controlplane' or 'worker'."
  }
}

variable "config_patches" {
  type        = list(string)
  description = "List of patches to apply to the Talos config. Each patch must be a valid YAML string."
}
