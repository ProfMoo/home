data "unifi_user" "vm" {
  mac = macaddress.mac_addresses.address
}

output "vm_ipv4_address" {
  value = data.unifi_user.vm.ip
}
