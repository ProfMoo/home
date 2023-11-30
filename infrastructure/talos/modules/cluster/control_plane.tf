module "control_plane_node" {
  for_each = var.control_plane

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

module "control_plane_node_configuration" {
  for_each = var.control_plane

  source = "../talos-node"

  talos_virtual_ip = "192.168.1.99"
  machine_type     = "controlplane"

  kubernetes_cluster_name = var.kubernetes_cluster_name

  node_ip = module.control_plane_node[each.key].ipv4_address

  kubernetes_version = each.value.kubernetes_version
  talos_version      = each.value.talos_version
}
