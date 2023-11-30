output "control_plane_nodes_ips" {
  value = { for key, instance in module.control_plane_node : key => { "ipv4_address" : instance.ipv4_address, "mac_address" : instance.mac_address } }
}
