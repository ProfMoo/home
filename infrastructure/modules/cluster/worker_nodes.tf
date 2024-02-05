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

  talos_machine_type      = "worker"
  talos_cluster_secrets   = talos_machine_secrets.cluster
  kubernetes_cluster_name = var.kubernetes_cluster_name

  cluster_endpoint_ip = module.worker_nodes[each.key].ipv4_address
  node_ip             = module.worker_nodes[each.key].ipv4_address

  kubernetes_version = each.value.kubernetes_version
  talos_version      = each.value.talos_version

  config_patches = [
    templatefile("configs/worker-node.yml", {
      node_type    = "workernode",
      proxmox_node = each.value.proxmox_node_name

      qemu_guest_agent_version = each.value.qemu_guest_agent_version,
      hostname                 = each.value.name,

      subnet_gateway   = each.value.subnet_gateway,
      talos_virtual_ip = each.value.talos_virtual_ip,
      nodes_subnet     = each.value.nodes_subnet,

      pod_subnets     = each.value.pod_subnets,
      service_subnets = each.value.service_subnets,

      kube_api_dns = "api.cluster.local",
      kube_domain  = "cluster.local",
    })
  ]
}

output "worker_nodes_ips" {
  value = { for key, instance in module.worker_nodes : key => { "ipv4_address" : instance.ipv4_address, "mac_address" : instance.mac_address } }
}
