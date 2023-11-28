// data "talos_machine_configuration" "workernode" {
//   cluster_name     = var.kubernetes_cluster_name
//   cluster_endpoint = "https://${var.talos_virtual_ip}:6443"

//   machine_type    = "worker"
//   machine_secrets = talos_machine_secrets.this.machine_secrets

//   talos_version      = var.talos_version
//   kubernetes_version = var.kubernetes_version
// }

// resource "talos_machine_configuration_apply" "workernode" {
//   depends_on = [
//     proxmox_virtual_environment_vm.workernode
//   ]

//   count    = var.workernode_num
//   node     = local.worker_nodes[count.index]
//   endpoint = local.worker_nodes[count.index]

//   client_configuration        = talos_machine_secrets.this.client_configuration
//   machine_configuration_input = data.talos_machine_configuration.workernode.machine_configuration

//   config_patches = [
//     templatefile("configs/global.yml", {
//       qemu_guest_agent_version = var.qemu_guest_agent_version
//     })
//   ]
// }

// data "talos_machine_configuration" "controlplane" {
//   cluster_name     = var.kubernetes_cluster_name
//   cluster_endpoint = "https://${var.talos_virtual_ip}:6443"

//   machine_type    = "controlplane"
//   machine_secrets = talos_machine_secrets.this.machine_secrets

//   talos_version      = var.talos_version
//   kubernetes_version = var.kubernetes_version
// }

// resource "talos_machine_configuration_apply" "controlplane" {
//   depends_on = [
//     proxmox_virtual_environment_vm.controlplane
//   ]

//   count    = var.controlplane_num
//   node     = local.controlplane_nodes[count.index]
//   endpoint = local.controlplane_nodes[count.index]

//   client_configuration        = talos_machine_secrets.this.client_configuration
//   machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

//   config_patches = [
//     templatefile("configs/global.yml", {
//       qemu_guest_agent_version = var.qemu_guest_agent_version
//     }),
//     templatefile("configs/controlplane.yml", {
//       talos_virtual_ip = var.talos_virtual_ip
//     }),
//     var.talos_disable_flannel ? templatefile("configs/disable_flannel.yml", {}) : null
//   ]
// }
