module "worker_nodes" {
  for_each = var.worker_nodes

  source = "../node"

  vm_tags                     = each.value.vm_tags
  vm_id                       = each.value.vm_id
  vm_cpu_cores                = each.value.vm_cpu_cores
  vm_memory                   = each.value.vm_memory
  vm_disk_size                = each.value.vm_disk_size
  proxmox_node_name           = each.value.proxmox_node_name
  proxmox_node_datastore      = each.value.proxmox_node_datastore
  proxmox_node_network_device = each.value.proxmox_node_network_device
  vm_vlan_id                  = each.value.vm_vlan_id

  initial_boot_iso = proxmox_virtual_environment_file.talos_image.id
}
