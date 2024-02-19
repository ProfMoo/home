output "mac_address" {
  value = unifi_user.this.mac
}

output "ipv4_address" {
  value = unifi_user.this.fixed_ip
}
