// data "talos_machine_configuration" "worker_node" {
//   cluster_name     = var.kubernetes_cluster_name
//   cluster_endpoint = "https://${var.talos_virtual_ip}:6443"

//   machine_type    = "worker"
//   machine_secrets = talos_machine_secrets.this.machine_secrets

//   talos_version      = var.talos_version
//   kubernetes_version = var.kubernetes_version
// }

// resource "talos_machine_configuration_apply" "worker_node" {
//   depends_on = [
//     proxmox_virtual_environment_vm.worker_node
//   ]

//   count    = var.worker_node_num
//   node     = local.worker_nodes[count.index]
//   endpoint = local.worker_nodes[count.index]

//   client_configuration        = talos_machine_secrets.this.client_configuration
//   machine_configuration_input = data.talos_machine_configuration.worker_node.machine_configuration

//   config_patches = [
//     templatefile("configs/global.yml", {
//       qemu_guest_agent_version = var.qemu_guest_agent_version
//     })
//   ]
// }

// data "talos_machine_configuration" "control_plane" {
//   cluster_name     = var.kubernetes_cluster_name
//   cluster_endpoint = "https://${var.talos_virtual_ip}:6443"

//   machine_type    = "control_plane"
//   machine_secrets = talos_machine_secrets.this.machine_secrets

//   talos_version      = var.talos_version
//   kubernetes_version = var.kubernetes_version
// }

// resource "talos_machine_configuration_apply" "control_plane" {
//   depends_on = [
//     proxmox_virtual_environment_vm.control_plane
//   ]

//   count    = var.control_plane_num
//   node     = local.control_plane_nodes[count.index]
//   endpoint = local.control_plane_nodes[count.index]

//   client_configuration        = talos_machine_secrets.this.client_configuration
//   machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration

//   config_patches = [
//     templatefile("configs/global.yml", {
//       qemu_guest_agent_version = var.qemu_guest_agent_version
//     }),
//     templatefile("configs/control_plane.yml", {
//       talos_virtual_ip = var.talos_virtual_ip
//     }),
//     var.talos_disable_flannel ? templatefile("configs/disable_flannel.yml", {}) : null
//   ]
// }
