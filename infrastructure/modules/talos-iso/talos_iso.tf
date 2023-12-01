resource "proxmox_virtual_environment_file" "talos_image" {
  content_type = "iso"
  datastore_id = var.talos_image_datastore
  node_name    = var.talos_image_storage_node

  source_file {
    path      = "https://github.com/siderolabs/talos/releases/download/v${var.talos_version}/metal-amd64.iso"
    file_name = "talos-${var.talos_version}-metal-amd64.iso"
  }
}
