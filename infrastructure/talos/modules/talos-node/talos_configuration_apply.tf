resource "talos_machine_secrets" "node" {
  talos_version = "v${var.talos_version}"
}

data "talos_machine_configuration" "node" {
  cluster_name     = var.kubernetes_cluster_name
  cluster_endpoint = "https://${var.cluster_endpoint_ip}:6443"

  machine_type    = var.talos_machine_type
  machine_secrets = talos_machine_secrets.node.machine_secrets

  talos_version      = "v${var.talos_version}"
  kubernetes_version = var.kubernetes_version
}

resource "talos_machine_configuration_apply" "node" {
  node     = var.node_ip
  endpoint = var.node_ip

  client_configuration        = talos_machine_secrets.node.client_configuration
  machine_configuration_input = data.talos_machine_configuration.node.machine_configuration

  config_patches = var.config_patches
}

output "talos_machine_configuration" {
  value     = talos_machine_secrets.node.client_configuration
  sensitive = true
}
