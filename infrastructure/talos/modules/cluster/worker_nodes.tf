module "worker_nodes" {
  for_each = var.worker_nodes

  source = "../node"

  id                    = each.value.id
  name                  = each.value.name
  description           = each.value.description
  tags                  = each.value.tags
  cpu_cores             = each.value.cpu_cores
  memory                = each.value.memory
  disk_size             = each.value.disk_size
  datastore             = each.value.datastore
  vlan_id               = each.value.vlan_id
  bridge_network_device = each.value.bridge_network_device
  proxmox_node_name     = each.value.proxmox_node_name
  initial_boot_iso      = each.value.initial_boot_iso

  proxmox_pool = proxmox_virtual_environment_pool.pool.pool_id
}

module "worker_node_configuration" {
  for_each = var.worker_nodes

  source = "../talos-node"

  # cluster_endpoint_ip = "192.168.1.44"
  cluster_endpoint_ip = values(module.control_plane_node)[0].ipv4_address
  talos_machine_type  = "worker"

  kubernetes_cluster_name = var.kubernetes_cluster_name

  # node_ip = module.worker_nodes[each.key].ipv4_address
  node_ip = "192.168.1.99"

  kubernetes_version = each.value.kubernetes_version
  talos_version      = each.value.talos_version

  config_patches = [
    templatefile("configs/global.yml", {
      qemu_guest_agent_version = "8.1.2"
    })
  ]
}

output "worker_nodes_ips" {
  value = { for key, instance in module.worker_nodes : key => { "ipv4_address" : instance.ipv4_address, "mac_address" : instance.mac_address } }
}
