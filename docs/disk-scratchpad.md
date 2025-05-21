# Disk Management Scratchpad

## Proxmox

We load another distinct `disk` block into the Proxmox VM via TF configuration.

## Talos

<https://www.talos.dev/v1.10/talos-guides/configuration/disk-management/>

Show what volumes Talos can see (i.e. loaded into the VM). Not necessarily that Talos has mounted them.

```bash
talosctl get discoveredvolumes --nodes=192.168.8.120
```

Show that Talos has actually mounted (I think this means that it'd be actually available to the k8s nodes)

```bash
talosctl get disks --nodes=192.168.8.120
```

To get more info about a specific disk:

```bash
talosctl get disk sdb --nodes=192.168.8.120 -o yaml
talosctl get volumeconfigs -n=192.168.8.120
```

DO NOT add the disk to Talos disk mount like this:

```yaml
disks:
- device: /dev/sdb
    partitions:
    - mountpoint: /var/mnt/extra
```

We avoid this because this will actually format the drive as a filesystem. Ceph requires RAW disk.

## Kubernetes
