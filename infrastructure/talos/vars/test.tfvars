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


# Controlplanes #################
controlplane_vmid_prefix        = "405"               # 4051-4059
controlplane_node_name          = "pve"
controlplane_num                = 1

controlplane_hostname_prefix    = "test-k8s-cp"
controlplane_ip_prefix          = "192.168.1.5"      # 51-59
controlplane_vlan_id            = "0"

controlplane_cpu_cores          = "4"
controlplane_memory             = "4096"
controlplane_disk_size          = "40"

controlplane_datastore = "local-lvm"

controlplane_tags               = [
  "app-kubernetes",
  "clusterid-test",
  "type-controlplane"
]


# Worker Nodes ##################
workernode_vmid_prefix          = "406"               # 4061-4069
workernode_node_name            = "pve"
workernode_num                  = 1

workernode_hostname_prefix      = "test-k8s-node"
workernode_ip_prefix            = "192.168.1.6"      # 62-69
workernode_vlan_id              = "0"

workernode_cpu_cores            = "4"
workernode_memory               = "4096"
workernode_disk_size            = "40"

workernode_datastore = "local-lvm"

workernode_tags                 = [
  "app-kubernetes",
  "clusterid-test",
  "type-workernode"
]
