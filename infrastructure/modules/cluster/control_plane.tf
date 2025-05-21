module "control_plane_node" {
  for_each = var.control_plane

  source = "../node"

  id          = each.value.id
  name        = each.value.name
  description = each.value.description
  tags        = each.value.tags

  cpu_cores = each.value.cpu_cores
  memory    = each.value.memory

  disk_size = each.value.disk_size
  datastore = each.value.datastore

  enable_storage_cluster = false

  vlan_id               = each.value.vlan_id
  bridge_network_device = each.value.bridge_network_device
  ipv4_address          = each.value.ipv4_address
  mac_address           = each.value.mac_address

  proxmox_node_name = each.value.proxmox_node_name
  initial_boot_iso  = each.value.initial_boot_iso
  proxmox_pool      = proxmox_virtual_environment_pool.pool.pool_id
}

locals {
  control_plane_configs = {
    for key, node in var.control_plane : node.name => templatefile(
      "configs/controlplane.yaml",
      {
        node_type    = "controlplane",
        proxmox_node = node.proxmox_node_name

        hostname      = node.name,
        talos_version = node.talos_version,

        mac_address    = module.control_plane_node[key].mac_address,
        ipv4_address   = module.control_plane_node[key].ipv4_address,
        subnet_gateway = node.subnet_gateway,

        talos_virtual_ip = node.talos_virtual_ip,
        pod_subnets      = node.pod_subnets,
        service_subnets  = node.service_subnets,

        # Secrets
        token                       = data.sops_file.talos_secrets.data["talos.machineconfig.trustdinfo.token"]
        client_ca_crt               = data.sops_file.talos_secrets.data["talos.machineconfig.certs.k8s.crt"]
        client_key                  = data.sops_file.talos_secrets.data["talos.machineconfig.certs.k8s.key"]
        cluster_id                  = data.sops_file.talos_secrets.data["talos.machineconfig.cluster.id"]
        cluster_secret              = data.sops_file.talos_secrets.data["talos.machineconfig.cluster.secret"]
        cluster_token               = data.sops_file.talos_secrets.data["talos.machineconfig.secrets.bootstraptoken"]
        secretbox_encryption_secret = data.sops_file.talos_secrets.data["talos.machineconfig.secrets.secretboxencryptionsecret"]
        cluster_ca_crt              = data.sops_file.talos_secrets.data["talos.machineconfig.certs.os.crt"]
        cluster_ca_key              = data.sops_file.talos_secrets.data["talos.machineconfig.certs.os.key"]
        aggregator_ca_crt           = data.sops_file.talos_secrets.data["talos.machineconfig.certs.k8saggregator.crt"]
        aggregator_ca_key           = data.sops_file.talos_secrets.data["talos.machineconfig.certs.k8saggregator.key"]
        service_account_key         = data.sops_file.talos_secrets.data["talos.machineconfig.certs.k8sserviceaccount.key"]
        etcd_ca_crt                 = data.sops_file.talos_secrets.data["talos.machineconfig.certs.etcd.crt"]
        etcd_ca_key                 = data.sops_file.talos_secrets.data["talos.machineconfig.certs.etcd.key"]
      }
    )
  }
}

output "control_plane_nodes_ips" {
  value = { for key, instance in module.control_plane_node : key => { "ipv4_address" : instance.ipv4_address, "mac_address" : instance.mac_address } }
}

output "control_plane_configs" {
  value = local.control_plane_configs
}
