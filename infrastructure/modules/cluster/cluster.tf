# Generate a client certificate signed by the Talos OS CA from SOPS.
# This is needed instead of talos_machine_secrets, which would generate new secrets.
# https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets
# What we want is to use the existing CA from the SOPS-managed secrets file.
resource "tls_private_key" "talos_client" {
  algorithm = "ED25519"
}

resource "tls_cert_request" "talos_client" {
  private_key_pem = tls_private_key.talos_client.private_key_pem

  subject {
    organization = "os:admin"
  }
}

resource "tls_locally_signed_cert" "talos_client" {
  cert_request_pem = tls_cert_request.talos_client.cert_request_pem
  ca_cert_pem      = base64decode(data.sops_file.talos_secrets.data["talos.machineconfig.certs.os.crt"])
  # Talos stores ED25519 keys as PKCS#8 DER but uses a non-standard PEM type
  # ("ED25519 PRIVATE KEY" instead of "PRIVATE KEY"). Rewrite the headers so
  # the hashicorp/tls provider can parse it.
  ca_private_key_pem = replace(
    replace(
      base64decode(data.sops_file.talos_secrets.data["talos.machineconfig.certs.os.key"]),
      "-----BEGIN ED25519 PRIVATE KEY-----",
      "-----BEGIN PRIVATE KEY-----"
    ),
    "-----END ED25519 PRIVATE KEY-----",
    "-----END PRIVATE KEY-----"
  )

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_encipherment",
  ]
}

locals {
  # The Talos provider expects client_configuration values to be base64-encoded.
  # The OS CA cert is already base64-encoded in SOPS; the TLS-generated PEM
  # outputs need to be base64-encoded to match.
  client_configuration = {
    ca_certificate     = data.sops_file.talos_secrets.data["talos.machineconfig.certs.os.crt"]
    client_certificate = base64encode(tls_locally_signed_cert.talos_client.cert_pem)
    client_key         = base64encode(tls_private_key.talos_client.private_key_pem)
  }
}

data "talos_client_configuration" "this" {
  cluster_name         = var.kubernetes_cluster_name
  client_configuration = local.client_configuration

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

# TODO: This kubeconfig has a dependency on the 'talosctl bootstrap' command being run manually.
# We should be able to remove this dependency by using the Talos provider to bootstrap the cluster.
# https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_bootstrap
# But it doesn't seem to be working as expected with error msg: 'Bootstrap not implemented' in dmesg.
resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    data.talos_client_configuration.this
  ]
  client_configuration = local.client_configuration
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
