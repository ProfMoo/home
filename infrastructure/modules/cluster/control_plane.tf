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

  vlan_id               = each.value.vlan_id
  bridge_network_device = each.value.bridge_network_device
  ipv4_address          = each.value.ipv4_address
  mac_address           = each.value.mac_address

  proxmox_node_name = each.value.proxmox_node_name
  initial_boot_iso  = each.value.initial_boot_iso
  proxmox_pool      = proxmox_virtual_environment_pool.pool.pool_id
}

module "control_plane_node_configuration" {
  for_each = var.control_plane

  source = "../talos-node"

  talos_machine_type      = "controlplane"
  talos_cluster_secrets   = talos_machine_secrets.cluster
  kubernetes_cluster_name = var.kubernetes_cluster_name

  node_ip             = module.control_plane_node[each.key].ipv4_address
  cluster_endpoint_ip = module.control_plane_node[each.key].ipv4_address

  kubernetes_version = each.value.kubernetes_version
  talos_version      = each.value.talos_version

  config_patches = [
    templatefile("configs/control-plane.yaml", {
      node_type    = "control-plane",
      proxmox_node = each.value.proxmox_node_name,

      qemu_guest_agent_version = each.value.qemu_guest_agent_version,
      hostname                 = each.value.name,

      # NOTE: The auto-generated interface name is enx<mac_address_without_colons_and_lowercase>
      # ex: enx000c29d3e3e3
      interface      = format("enx%s", replace(lower(module.control_plane_node[each.key].mac_address), ":", "")),
      ipv4_address   = module.control_plane_node[each.key].ipv4_address,
      subnet_gateway = each.value.subnet_gateway,

      talos_virtual_ip = each.value.talos_virtual_ip,
      nodes_subnet     = each.value.nodes_subnet,
      pod_subnets      = each.value.pod_subnets,
      service_subnets  = each.value.service_subnets,
    }),
  ]
}

output "control_plane_nodes_ips" {
  value = { for key, instance in module.control_plane_node : key => { "ipv4_address" : instance.ipv4_address, "mac_address" : instance.mac_address } }
}
