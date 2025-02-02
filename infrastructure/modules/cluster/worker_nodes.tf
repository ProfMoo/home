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

module "worker_node_configuration" {
  for_each = var.worker_nodes

  source = "../talos-node"

  talos_machine_type      = "worker"
  talos_cluster_secrets   = talos_machine_secrets.cluster
  kubernetes_cluster_name = var.kubernetes_cluster_name

  cluster_endpoint_ip = module.worker_nodes[each.key].ipv4_address
  node_ip             = module.worker_nodes[each.key].ipv4_address

  kubernetes_version = each.value.kubernetes_version
  talos_version      = each.value.talos_version

  config_patches = [
    templatefile("configs/worker-node.yaml", {
      node_type    = "worker",
      proxmox_node = each.value.proxmox_node_name

      hostname      = each.value.name,
      talos_version = each.value.talos_version,

      mac_address    = module.worker_nodes[each.key].mac_address,
      ipv4_address   = module.worker_nodes[each.key].ipv4_address,
      subnet_gateway = each.value.subnet_gateway,

      talos_virtual_ip = each.value.talos_virtual_ip,
      pod_subnets      = each.value.pod_subnets,
      service_subnets  = each.value.service_subnets,
    })
  ]
}

output "worker_nodes_ips" {
  value = { for key, instance in module.worker_nodes : key => { "ipv4_address" : instance.ipv4_address, "mac_address" : instance.mac_address } }
}
