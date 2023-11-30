variable "kubernetes_version" {
  type        = string
  description = "Identify desired version from the list here: https://github.com/siderolabs/kubelet/pkgs/container/kubelet"
}

variable "qemu_guest_agent_version" {
  type        = string
  default     = "8.1.2"
  description = "Identify here: https://github.com/siderolabs/extensions/pkgs/container/qemu-guest-agent"
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "Kubernetes cluster name you wish for Talos to use"
}

variable "talos_virtual_ip" {
  type        = string
  description = "Virtual IP address you wish for Talos to use"
}

variable "talos_version" {
  type        = string
  description = "Talos version to use. Can identify the available versions here: https://github.com/siderolabs/talos/releases."
}

variable "node_ip" {
  type        = string
  description = "IPV4 address of the node we want to operate against"
}

variable "machine_type" {
  type        = string
  description = "The Kubernetes note type that Talos will configure this node as"
}
