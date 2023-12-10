resource "talos_machine_secrets" "cluster" {
  # Determines the schema we'll use for the machine secrets
  talos_version = "v1.5.5"
}

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

  # TODO: This needs to be the Talos virtual IP and not just a single, "random" control plane node
  endpoint = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
  node     = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
