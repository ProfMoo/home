locals {
  first_node       = keys(module.control_plane_node)[0]
  first_talos_node = keys(module.control_plane_node_configuration)[0]
}

resource "talos_machine_bootstrap" "node" {
  # NOTE: This count creates AT MOST one instance of the resource. We only want to bootstrap once per cluster.
  # Source: https://www.talos.dev/v1.5/introduction/getting-started/#kubernetes-bootstrap
  for_each = { (local.first_node) = module.control_plane_node[local.first_node] }

  endpoint = each.value.ipv4_address
  node     = each.value.ipv4_address

  client_configuration = module.control_plane_node_configuration[local.first_talos_node].talos_machine_configuration
}

data "talos_client_configuration" "this" {
  cluster_name         = var.kubernetes_cluster_name
  client_configuration = [for control_plane_node_configuration in module.control_plane_node_configuration : control_plane_node_configuration.talos_machine_configuration][0]
  endpoints            = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address]
}

data "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.node
  ]
  client_configuration = [for control_plane_node_configuration in module.control_plane_node_configuration : control_plane_node_configuration.talos_machine_configuration][0]
  endpoint             = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
  node                 = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
