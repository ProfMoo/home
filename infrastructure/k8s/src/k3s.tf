module "k3s" {
  source = "github.com/klimer2012/terraform-proxmox-k3s?ref=v0.1.5"

  authorized_keys_file = "authorized_keys"
  private_key = "private_key"

  proxmox_node = "pve"

  # NOTE: This string must be a cloud-init enabled template ALREADY IN PROXMOX.
  # So make sure you have a template named "ubuntu-server-jammy" in your proxmox.
  # In this codebase, the name is defined by the packer template found here: infrastructure/packer/ubuntu-server-jammy.json
  node_template = "ubuntu-server-jammy"

  network_gateway = "192.168.1.1"
  lan_subnet      = "192.168.1.0/24"

  support_node_settings = {
    cores  = 4
    memory = 8096
  }

  # Disable default traefik and servicelb installs for metallb and traefik 2
  k3s_disable_components = [
    "traefik",
    "servicelb"
  ]

  master_nodes_count = 2
  master_node_settings = {
    cores  = 2
    memory = 4096
  }

  # 192.168.0.200 -> 192.168.0.207 (6 available IPs for nodes)
  control_plane_subnet = "192.168.1.200/29"

  node_pools = [
    {
      name = "default"
      size = 3
      # 192.168.0.208 -> 192.168.0.223 (14 available IPs for nodes)
      subnet = "192.168.1.208/28"
    }
  ]
}

output "kubeconfig" {
  value     = module.k3s.k3s_kubeconfig
  sensitive = true
}
