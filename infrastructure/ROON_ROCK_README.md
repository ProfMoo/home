# Roon ROCK VM Setup Guide

This guide explains how to set up a virtualized Roon ROCK installation on Proxmox VE, based on the methodology from [HiFiZine's virtualization guide](https://www.hifizine.com/2019/12/virtualizing-roon-rock/).

## Key Configuration Requirements

Based on extensive testing and the referenced article, ROCK has very specific virtualization requirements that differ from typical VM configurations:

### Critical Settings

- **BIOS**: Must use **SeaBIOS** (not UEFI/OVMF)
- **Network**: Must use **Intel E1000** network adapter (not VirtIO)
- **Disk**: Must use **SATA** interface (not SCSI)
- **Minimum Disk Size**: 64GB (installations fail with smaller disks)
- **Installation Method**: USB device only (not CD-ROM/ISO)

### Hardware Specifications

- **CPU**: 2 cores (can be increased later if needed)
- **Memory**: 2GB (can be increased later if needed)
- **Disk**: 64GB minimum on SATA interface
- **Network**: Intel E1000 on VLAN 1

## Installation Process

### 1. Terraform Deployment

```bash
cd /Users/drmoo/code/home/infrastructure
terraform plan
terraform apply
```

This creates the VM with the correct hardware configuration but does not start it automatically.

### 2. Manual USB Installation

Since ROCK requires USB installation, the following steps must be done manually:

1. **Download ROCK Image**:

   ```bash
   wget https://download.roonlabs.net/builds/roonbox-linuxx64-nuc4-usb-factoryreset.img.gz
   gunzip roonbox-linuxx64-nuc4-usb-factoryreset.img.gz
   ```

2. **Create Bootable USB**:
   - Use Etcher or `dd` to write the image to a USB stick
   - Connect the USB stick to the Proxmox server (pve2)

3. **Attach USB to VM**:
   - In Proxmox web interface, go to VM 2000 (roon-rock)
   - Hardware → Add → USB Device
   - Select the connected USB stick

4. **Add USB Keyboard**:
   - Hardware → Add → USB Device
   - Select a USB keyboard (installer requires physical keyboard input)

5. **Install ROCK**:
   - Start the VM
   - Press ESC when you see "Press ESC for Boot Menu"
   - Select the USB device from boot menu
   - Follow ROCK installer prompts (type responses on physical keyboard)
   - Install to the QEMU hard disk when prompted

6. **Post-Installation**:
   - After installation completes, shut down VM
   - Remove USB stick and keyboard from VM hardware
   - Start VM normally

### 3. Access ROCK

- ROCK should be accessible at <http://rock/> or <http://192.168.1.210/>
- Install missing codecs as needed
- Configure Roon app to connect to the new ROCK server

## Network Configuration

- VM has static IP: 192.168.1.210
- MAC address: 52:54:00:0f:42:44
- DHCP reservation configured via UniFi controller
- On VLAN 1 for normal network access

## Troubleshooting

### Common Issues

1. **Installer won't boot**: Ensure SeaBIOS is used, not UEFI
2. **Network not working**: Verify Intel E1000 adapter is configured
3. **Disk errors during install**: Ensure SATA interface and minimum 64GB size
4. **Can't type in installer**: Physical USB keyboard must be attached to VM

### Boot Problems

- If VM boots to EFI shell, the BIOS setting is wrong (should be SeaBIOS)
- If USB device not detected, verify it's properly attached in Proxmox hardware panel
- Use physical keyboard connected to server for installer input

## Performance Notes

- ROCK VM uses slightly more CPU than regular Roon Server
- Performance is otherwise equivalent to bare metal ROCK installation
- Can handle upsampling and DSP processing as expected

## Storage Options

After installation, ROCK supports:

1. **Network Storage**: Add NAS or network shares via ROCK web interface
2. **USB Storage**: Attach USB drives directly to the VM
3. **Internal Storage**: Use disk passthrough for dedicated music storage

## References

- [HiFiZine ROCK Virtualization Guide](https://www.hifizine.com/2019/12/virtualizing-roon-rock/)
- [Roon Community Forum Thread](https://community.roonlabs.com/t/rock-on-proxmoxve/70397)
- [ROCK Installation Guide](https://help.roonlabs.com/portal/en/kb/articles/rock-install-guide)
