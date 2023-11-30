data "unifi_user" "vm" {
  mac = macaddress.mac_addresses.address
}

output "mac_address" {
  value = macaddress.mac_addresses.address
}

output "ipv4_address" {
  value = "192.168.1.29"
}
