# Supermicro

Got this command working:

```bash
# First zone (left two fans in front)
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN raw 0x30 0x70 0x66 0x01 0x01 0x11
# Second zone (right two fans in front)
ipmitool -H 192.168.1.187 -U ADMIN -P ADMIN raw 0x30 0x70 0x66 0x01 0x01 0x11
```

After doing this (still have old PSU and no CPU fan). Currently @ avg ~56dB on wooden ledge after a 1 minute of listening. But currently not running anything. Not sure if things will get hot either.
