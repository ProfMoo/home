module "worker_nodes" {
  for_each = var.worker_nodes

  source = "../node"

  id          = each.value.id
  name        = each.value.name
  description = each.value.description
  tags        = each.value.tags

  cpu_cores = each.value.cpu_cores
  memory    = each.value.memory

  disk_size = each.value.disk_size
  datastore = each.value.datastore

  vlan_id               = each.value.vlan_id
  bridge_network_device = each.value.bridge_network_device
  ipv4_address          = each.value.ipv4_address
  mac_address           = each.value.mac_address

  proxmox_node_name = each.value.proxmox_node_name
  initial_boot_iso  = each.value.initial_boot_iso
  proxmox_pool      = proxmox_virtual_environment_pool.pool.pool_id
}


data "sops_file" "talos_secrets" {
  source_file = "secrets.talos.sops.yaml"
  input_type  = "yaml"
}

locals {
  worker_node_configs = {
    for key, node in var.worker_nodes : node.name => templatefile(
      "configs/worker.yaml",
      {
        node_type    = "worker",
        proxmox_node = node.proxmox_node_name

        hostname      = node.name,
        talos_version = node.talos_version,

        mac_address    = module.worker_nodes[key].mac_address,
        ipv4_address   = module.worker_nodes[key].ipv4_address,
        subnet_gateway = node.subnet_gateway,

        talos_virtual_ip = node.talos_virtual_ip,
        pod_subnets      = node.pod_subnets,
        service_subnets  = node.service_subnets,

        # Secrets
        token          = data.sops_file.talos_secrets.data["talos.machineconfig.trustdinfo.token"]
        client_ca_crt  = data.sops_file.talos_secrets.data["talos.machineconfig.certs.k8s.crt"]
        cluster_id     = data.sops_file.talos_secrets.data["talos.machineconfig.cluster.id"]
        cluster_secret = data.sops_file.talos_secrets.data["talos.machineconfig.cluster.secret"]
        cluster_token  = data.sops_file.talos_secrets.data["talos.machineconfig.secrets.bootstraptoken"]
        cluster_ca_crt = data.sops_file.talos_secrets.data["talos.machineconfig.certs.os.crt"]
      }
    )
  }
}

output "worker_nodes_ips" {
  value = { for key, instance in module.worker_nodes : key => { "ipv4_address" : instance.ipv4_address, "mac_address" : instance.mac_address } }
}

output "worker_node_configs" {
  value = local.worker_node_configs
}
