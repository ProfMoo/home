# Roon Rock VM Configuration
# This creates a standalone VM on pve2 running Roon Rock

# Variable for Roon Rock download URL - for manual USB creation
variable "roon_rock_download_url" {
  type        = string
  description = "URL to download the Roon Rock installer image"
  # Check https://help.roonlabs.com/portal/en/kb/articles/rock-install-guide for the latest version
  # The URL typically follows the pattern: https://download.roonlabs.com/builds/RoonOS_X.Y_ZZZ.img
  default = "https://download.roonlabs.net/builds/roonbox-linuxx64-nuc4-usb-factoryreset.img.gz"
}

# Note: ROCK requires USB installation - download the image above and burn to USB stick
# The USB stick will need to be manually attached to the Proxmox server and added to the VM

# DHCP Reservation for Roon Rock VM on VLAN 1
resource "unifi_user" "roon_rock" {
  mac  = "52:54:00:0f:42:44" # Unique MAC address for the Roon Rock VM
  name = "roon-rock"
  note = "Roon Rock VM - Provisioned via Terraform"

  fixed_ip   = "192.168.1.210" # Choose an available IP on VLAN 1 (avoiding conflict with existing Roon at .200)
  network_id = "1"             # VLAN 1
}

# Roon Rock VM
resource "proxmox_virtual_environment_vm" "roon_rock" {
  depends_on = [
    unifi_user.roon_rock,
  ]

  vm_id = "2000" # Choose an available VM ID

  # Optional: Add to a resource pool for organization
  # pool_id   = "media"  # Uncomment and create pool if desired
  node_name = "pve2"
  name      = "roon-rock"

  description = "Roon Rock VM for music streaming - Requires manual USB installation"
  tags        = ["roon", "media", "standalone"]

  # CPU Configuration - Enhanced from article recommendations for better performance
  cpu {
    cores = 4      # Increased from 2 cores for better DSP/upsampling performance
    type  = "host" # Use host CPU type for best performance
  }

  # Memory Configuration - Enhanced from article recommendations
  memory {
    dedicated = 8192 # Increased from 2GB to 8GB for larger libraries and better caching
  }                  # Network Configuration for VLAN 1
  # CRITICAL: Must use Intel E1000, not VirtIO for ROCK compatibility
  network_device {
    bridge      = "vmbr0"
    mac_address = unifi_user.roon_rock.mac
    firewall    = false
    vlan_id     = "1"     # VLAN 1 for normal network access
    model       = "e1000" # Intel E1000 required for ROCK
  }

  # Boot configuration - Will need manual USB device addition in Proxmox
  boot_order = [
    "sata0", # Main disk after installation
  ]

  # Main disk for Roon Rock OS and database
  # CRITICAL: Must use SATA interface, not SCSI for ROCK compatibility
  disk {
    datastore_id = "disk1" # Using disk1 datastore available on pve2
    file_format  = "raw"
    interface    = "sata0"
    size         = 128 # Increased from 64GB to 128GB for larger music libraries
  }

  # No CD-ROM - ROCK requires USB installation
  # The downloaded image needs to be manually attached as USB device in Proxmox

  # Disable QEMU guest agent during installation
  agent {
    enabled = false
  }

  # Operating system type
  operating_system {
    type = "l26" # Linux
  }

  # Machine type for better compatibility
  machine = "q35"

  # BIOS settings - CRITICAL: Must use SeaBIOS, not UEFI for ROCK
  bios = "seabios"

  # No EFI disk needed with SeaBIOS

  # Start VM after creation (will need manual USB installation)
  started = false # Don't start automatically - needs USB device first
}

# Manual Installation Steps:
# 1. Download ROCK from the URL above and burn to USB stick using Etcher
# 2. Connect USB stick to the Proxmox server (pve2)
# 3. In Proxmox VM Hardware panel, Add -> USB Device and select the USB stick
# 4. Add a USB keyboard to the VM as well (needed for installer input)
# 5. Start the VM and press ESC at boot to select USB device
# 6. Follow ROCK installer prompts (responses typed on physical keyboard)
# 7. After installation, remove USB stick and keyboard from VM, then reboot

# Output the VM's IP address
output "roon_rock_ip" {
  value       = unifi_user.roon_rock.fixed_ip
  description = "IP address of the Roon Rock VM"
}

output "roon_rock_mac" {
  value       = unifi_user.roon_rock.mac
  description = "MAC address of the Roon Rock VM"
}
