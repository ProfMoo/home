module "testing_cluster" {
  source = "./modules/cluster"

  proxmox_resource_pool         = var.proxmox_resource_pool
  talos_image_datastore         = var.talos_image_datastore
  talos_version                 = var.talos_version
  talos_image_node_storage_name = var.talos_image_node_storage_name

  control_plane = var.control_plane
  worker_nodes  = var.worker_nodes
}
