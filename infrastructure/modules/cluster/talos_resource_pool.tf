resource "proxmox_virtual_environment_pool" "pool" {
  comment = "Resources pertaining to Kubernetes"
  pool_id = var.proxmox_resource_pool
}
