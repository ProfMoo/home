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
