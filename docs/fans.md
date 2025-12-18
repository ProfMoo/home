# Supermicro

## Overview

My server:

SuperMicro SuperServer SYS-6028U-TR4T+ 2U Rackmount Server
Processor: 2x Intel Xeon E5-2680 v4 2.4GHz 14-Core Processors   (+$34.00)
Memory: 256GB (8x 32GB) DDR4 Registered Memory   (+$560.00)
Storage Controller: 12Gbps IT Mode PCIe Storage Controller (Flashed to IT Mode; No RAID Pass-Thru Only)   (+$59.00)
Hard Drive (1): 480GB 6Gbps SATA SSD   (+$39.00)
Hard Drive (2): 480GB 6Gbps SATA SSD   (+$39.00)
Hard Drive (3): 480GB 6Gbps SATA SSD   (+$39.00)
Hard Drive (4): Tray with Screws
Hard Drive (5): Tray with Screws
Hard Drive (6): Tray with Screws
Hard Drive (7): Tray with Screws
Hard Drive (8): Tray with Screws
Hard Drive (9): Tray with Screws
Hard Drive (10): Tray with Screws
Hard Drive (11): Tray with Screws
Hard Drive (12): Tray with Screws
GPU/PCIe Add-On Card (1): NVIDIA Tesla T4 16GbE GDDR6 PCI-e Graphics Card   (+$699.00)
GPU/PCIe Add-On Card (2): Intel X550-T2 Dual Port 10GbE RJ45 PCIe Adapter   (+$75.00)
GPU/PCIe Add-On Card (3): None Installed
Power Supply: 2x 1000W 80Plus Platinum Power Supplies
4-Post Rack Rail Kit: Original SuperMicro Rails   (+$99.00)
Power Cable: No Power Cable Included
TotalServerShield Extended Warranty: TheServerStore Standard 90 Days (Replacement Parts; No Onsite Support)

[SuperMicro spec page](https://www.supermicro.com/en/products/system/2U/6028/SYS-6028U-TR4_.php)

[Machine IP](https://192.168.1.187/)

## Fans

```bash
# To view fan sensor readings
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN sensor | grep FAN
```

Got this command working to lower the fan:

```bash
# Lowered the threshold
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN sensor thresh FAN1 lower 100 100 100
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN sensor thresh FAN2 lower 100 100 100
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN sensor thresh FAN7 lower 100 100 100
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN sensor thresh FAN8 lower 100 100 100

# First zone (left two fans in front)
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN raw 0x30 0x70 0x66 0x01 0x00 0x11
# Second zone (right two fans in front)
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN raw 0x30 0x70 0x66 0x01 0x01 0x11
```

64 in hex is 100 in decimal, so 0x64 is max fan speed value.

```bash
# Set first zone to max fan speed
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN raw 0x30 0x70 0x66 0x01 0x00 0x64
```

After doing this (still have old PSU and no CPU fan). Currently @ avg ~56dB on wooden ledge after a 1 minute of listening. But currently not running anything. Not sure if things will get hot either.

[This script](https://github.com/petersulyok/smfc) will be huge once I get my Noctuas all set up. Bought [this one](https://www.noctua.at/en/products/nf-a8-pwm) (80mm slot, PWM).

## PSU

Good resource on Supermicro PSUs [here](https://www.supermicro.com/en/support/resources/pws).

I have `1PWS-1K02A-1R` in my machine. It's kinda loud, but honestly OK. I think the front and CPU fans are of bigger importance.

The `PWS-1K04A-1R` seemed promising

This might be a good candidate: `PWS-2K21A-SQ`. Has the right size generally.
