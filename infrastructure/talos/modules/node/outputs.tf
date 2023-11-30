output "mac_address" {
  value = macaddress.mac_addresses.address
}

# NOTE: This allows time for the DHCP server to assign an IP address to the VM.
# It takes a significant period of time because the VM needs to boot from the Talos ISO and do an initial configuration.
resource "time_sleep" "wait_for_ip" {
  depends_on = [proxmox_virtual_environment_vm.talos_node]

  // Specifying the duration to wait
  create_duration = "60s"
}

# TODO: Contribute to Unifi provider to add support for the ip address so I can uncomment the lines below
# https://github.com/paultyng/terraform-provider-unifi/blob/main/internal/provider/resource_user.go#L187
data "unifi_user" "vm" {
  depends_on = [
    time_sleep.wait_for_ip
  ]
  mac = macaddress.mac_addresses.address
}

output "ipv4_address" {
  value = data.unifi_user.vm.ip
}
