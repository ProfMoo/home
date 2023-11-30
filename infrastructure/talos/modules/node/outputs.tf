output "mac_address" {
  value = macaddress.mac_addresses.address
}

# TODO: Contribute to Unifi provider to add support for the ip address so I can uncomment the lines below
# https://github.com/paultyng/terraform-provider-unifi/blob/main/internal/provider/resource_user.go#L187
// data "unifi_user" "vm" {
//   mac = macaddress.mac_addresses.address
// }

output "ipv4_address" {
  # value = data.unifi_user.vm.network_id
  value = "192.168.1.11"
}
