# Proxmox #######################
proxmox_hostname                = "192.168.1.64"
proxmox_ssh_key_path            = "~/.ssh/id_rsa.root_proxmox"

# Talos #########################
talos_image_node_name           = "pve"
# The single control plane node. TODO: Make this a DNS in the future that loadbalances between multiple control plane nodes (for HA).
talos_virtual_ip                = "192.168.1.95"
talos_disable_flannel           = true

gateway_ip                      = "192.168.1.1"

# Kubernetes ####################
kubernetes_cluster_name         = "test"


# control_planes #################
control_plane_vmid_prefix        = "405"               # 4051-4059
control_plane_node_name          = "pve"
control_plane_num                = 1

control_plane_hostname_prefix    = "test-k8s-cp"
control_plane_ip_prefix          = "192.168.1.5"      # 51-59
control_plane_vlan_id            = "1"

control_plane_cpu_cores          = "4"
control_plane_memory             = "4096"
control_plane_disk_size          = "40"

control_plane_datastore = "local-lvm"

control_plane_tags               = [
  "app-kubernetes",
  "clusterid-test",
  "type-control_plane"
]


# Worker Nodes ##################
worker_node_vmid_prefix          = "406"               # 4061-4069
worker_node_node_name            = "pve"
worker_node_num                  = 1

worker_node_hostname_prefix      = "test-k8s-node"
worker_node_ip_prefix            = "192.168.1.6"      # 62-69
worker_node_vlan_id              = "1"

worker_node_cpu_cores            = "4"
worker_node_memory               = "4096"
worker_node_disk_size            = "40"

worker_node_datastore = "local-lvm"

worker_node_tags                 = [
  "app-kubernetes",
  "clusterid-test",
  "type-worker_node"
]
