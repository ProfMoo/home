resource "proxmox_virtual_environment_file" "talos_image" {
  content_type = "iso"
  datastore_id = var.talos_image_datastore
  node_name    = var.talos_image_node_name

  source_file {
    path      = "https://github.com/siderolabs/talos/releases/download/${var.talos_version}/metal-amd64.iso"
    file_name = "talos-${var.talos_version}-metal-amd64.iso"
  }
}
