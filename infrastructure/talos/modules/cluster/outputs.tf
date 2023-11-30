output "control_plane_nodes_ips" {
  value = { for key, instance in module.control_plane_node : key => instance.vm_ipv4_address }
}
