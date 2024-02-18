resource "talos_machine_secrets" "cluster" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.kubernetes_cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  # NOTE: Endpoints to set in the generated config
  nodes = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address]
  # NOTE: Nodes to set in the generated config
  endpoints = [for control_plane_node in var.control_plane : control_plane_node.talos_virtual_ip]
}

resource "talos_machine_bootstrap" "node" {
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoint             = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
  node                 = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
}

data "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.node,
    data.talos_client_configuration.this
  ]
  client_configuration = talos_machine_secrets.cluster.client_configuration

  # NOTE: This is the control-plane node to retrieve the kubeconfig from.
  node = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
  # NOTE: Endpoint to use for the talosclient to get the kubeconfig. If not set, the node value will be used
  endpoint = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
