data "talos_client_configuration" "this" {
  cluster_name = var.kubernetes_cluster_name
  client_configuration = {
    ca_certificate     = data.sops_file.talos_secrets.data["talos.client.ca_certificate"]
    client_certificate = data.sops_file.talos_secrets.data["talos.client.client_certificate"]
    client_key         = data.sops_file.talos_secrets.data["talos.client.client_key"]
  }

  # NOTE: Nodes to set in the generated config.
  # These are the IPs of the nodes that the talosctl commands affect.
  # We put ALL the kubernetes nodes in here.
  nodes = concat(
    [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address],
    [for worker_node in module.worker_nodes : worker_node.ipv4_address]
  )
  # NOTE: Endpoints to set in the generated config.
  # These are the IPs that the talosctl commands use to find a talos control plane node.
  # Per the docs, this shouldn't be the VIP: https://www.talos.dev/v1.6/talos-guides/network/vip/#caveats
  endpoints = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address]
}

resource "talos_machine_bootstrap" "node" {
  client_configuration = {
    ca_certificate     = data.sops_file.talos_secrets.data["talos.client.ca_certificate"]
    client_certificate = data.sops_file.talos_secrets.data["talos.client.client_certificate"]
    client_key         = data.sops_file.talos_secrets.data["talos.client.client_key"]
  }

  endpoint = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
  node     = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.node,
    data.talos_client_configuration.this
  ]
  client_configuration = {
    ca_certificate     = data.sops_file.talos_secrets.data["talos.client.ca_certificate"]
    client_certificate = data.sops_file.talos_secrets.data["talos.client.client_certificate"]
    client_key         = data.sops_file.talos_secrets.data["talos.client.client_key"]
  }
  # NOTE: This is the control-plane node to retrieve the kubeconfig from.
  # (i.e. this is the node whose kubeconfig we are reading. It is not the node we are reading from)
  node = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
  # NOTE: Endpoint to use for the talosclient to get the kubeconfig. If not set, the node value will be used.
  # This is the endpoint that we reach out to to retrieve the kubeconfig.
  endpoint = [for control_plane_node in module.control_plane_node : control_plane_node.ipv4_address][0]
}

output "kubeconfig" {
  value     = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

