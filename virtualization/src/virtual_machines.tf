# resource "proxmox_vm_qemu" "cloudinit-test" {
#   name        = "tftest1.xyz.com"
#   desc        = "tf description"
#   target_node = "proxmox1-xx"

#   clone = "ci-ubuntu-template"

#   # The destination resource pool for the new VM
#   pool = "pool0"

#   storage = "local"
#   cores   = 3
#   sockets = 1
#   memory  = 2560
#   disk_gb = 4
#   nic     = "virtio"
#   bridge  = "vmbr0"

#   ssh_user        = "root"
#   ssh_private_key = <<EOF
# -----BEGIN RSA PRIVATE KEY-----
# private ssh key root
# -----END RSA PRIVATE KEY-----
# EOF

#   os_type   = "cloud-init"
#   ipconfig0 = "ip=10.0.2.99/16,gw=10.0.2.2"

#   sshkeys = <<EOF
# ssh-rsa AABB3NzaC1kj...key1
# ssh-rsa AABB3NzaC1kj...key2
# EOF

#   provisioner "remote-exec" {
#     inline = [
#       "ip a"
#     ]
#   }
# }
