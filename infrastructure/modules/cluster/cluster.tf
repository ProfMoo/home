resource "talos_machine_secrets" "cluster" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.kubernetes_cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoints            = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address]
}

resource "talos_machine_bootstrap" "node" {
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoint             = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
  node                 = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
}

data "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.node
  ]
  client_configuration = talos_machine_secrets.cluster.client_configuration

  # NOTE: This is the control-plane node to retrieve the kubeconfig from.
  node = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
  # NOTE: This is the IP address that is in the kubeconfig that's returned.
  # endpoint = [for control_plane_node in var.control_plane : control_plane_node.talos_virtual_ip][0]
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
