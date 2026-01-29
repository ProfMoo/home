# Node Crash Investigation

## Problem Statement

Worker nodes occasionally become overwhelmed and go unreachable. The crash manifests as kubelet stopping heartbeats, followed by the node being tainted `unreachable`.

---

## Infrastructure Layout

### Proxmox Hypervisors

| Hypervisor | Physical CPUs | Physical RAM | Nodes Hosted |
|------------|--------------|--------------|--------------|
| **pve** | unknown | unknown | porter-robinson, fox-stevenson, skrillex, mat-zo |
| **pve5** | 56 cores | 256GB | fred-again, moody-good |

### VM Specifications

| Node | Role | vCPUs | RAM | OS Disk | Storage Disks | Hypervisor |
|------|------|-------|-----|---------|---------------|------------|
| porter-robinson | control-plane | 3 | 8GB | 50GB (disk2) | none | pve |
| fox-stevenson | control-plane | 3 | 8GB | 50GB (disk1) | none | pve |
| fred-again | control-plane | 3 | 8GB | 450GB (disk2) | none | pve5 |
| skrillex | worker/storage | 15 | 80GB | 200GB (disk3) | 200GB scsi1 (**disk3**) | pve |
| mat-zo | worker/storage | 15 | 80GB | 200GB (disk2) | 200GB scsi1 (disk2) + 500GB scsi2 (disk4) | pve |
| moody-good | worker | 50 | 238GB | 450GB (disk3) | **NONE** | pve5 |

### Kubelet Configuration (all workers)

```
system-reserved: cpu=1000m, memory=2Gi, ephemeral-storage=2Gi
kube-reserved: cpu=1000m, memory=2Gi, ephemeral-storage=2Gi
eviction-hard: memory.available<1Gi, nodefs.available<10%
eviction-soft: memory.available<2Gi, nodefs.available<15%
eviction-soft-grace-period: memory.available=1m30s, nodefs.available=2m
```

### NFS Configuration (all workers)

```
nfsvers=4.2
hard=True       # NFS ops block INDEFINITELY if server unreachable
nconnect=16     # 16 concurrent NFS connections
noatime=True
```

---

## Potential Issues

### 1. DISK I/O CONTENTION

Disk layout on some nodes may cause I/O contention:

- **skrillex**: OS disk and Ceph OSD storage disk are on the **same physical datastore** (`disk3`). The OSD's I/O directly competes with kubelet, containerd, and container filesystem operations.
- **moody-good**: Has **no dedicated storage disk** despite being labeled `rook-osd-node`. Its single 450GB disk handles everything — OS, kubelet, containerd, all pod ephemeral storage, and CSI volume operations.
- **mat-zo** (stable): Has a **separate physical disk** (`disk4`, 500GB) for its second OSD, distributing I/O load.

### 2. EVICTION THRESHOLDS MAY BE TOO PERMISSIVE

The hard eviction threshold is `memory.available<1Gi`. On large-memory nodes:

- **skrillex (80GB)**: Won't evict until 98.7% memory used
- **moody-good (238GB)**: Won't evict until 99.6% memory used

By the time kubelet starts evicting pods, the kernel OOM killer may have already killed critical system processes.

### 3. NFS HARD MOUNTS CAN HANG THE NODE

```
hard=True
nconnect=16
```

NFS hard mounts mean any I/O operation to the NFS share (`192.168.8.248:/mnt/vault/media`) will **block indefinitely** if the NFS server becomes unreachable. With `nconnect=16`, up to 16 kernel threads can be blocked simultaneously.

Pods using this NFS mount: qbittorrent, radarr, sonarr, jellyfin, and others in the media namespace.

### 4. CONTROL PLANE MEMORY

Control plane nodes have 8GB RAM but kube-apiserver alone uses 2-3.5GB. This leaves little headroom.

### 5. moody-good LABELED FOR STORAGE BUT HAS NO DISK

moody-good has `drmoo.io/storage: rook-osd-node` but has no dedicated storage disk in its Terraform config. This means rook-discover is constantly scanning for disks.

---

## Diagnostic Commands for Future Crashes

### Immediately (from a working node or local machine)

```bash
# Check if it's an NFS hang (D-state processes)
talosctl -n 192.168.8.123 dmesg | grep -i "nfs\|blocked\|hung_task\|D state"

# Check for OOM kills
talosctl -n 192.168.8.123 dmesg | grep -i "oom\|killed process\|out of memory"

# Check disk I/O stats
talosctl -n 192.168.8.123 read /proc/diskstats

# Check for disk errors
talosctl -n 192.168.8.123 dmesg | grep -i "error\|I/O\|scsi\|ata\|reset"

# Check kubelet status
talosctl -n 192.168.8.123 service kubelet status

# PSI metrics at crash time
talosctl -n 192.168.8.123 read /proc/pressure/io
talosctl -n 192.168.8.123 read /proc/pressure/memory
talosctl -n 192.168.8.123 read /proc/pressure/cpu
```

### From Proxmox (pve5 host)

```bash
# Check physical disk health
smartctl -a /dev/sdX  # wherever disk3 maps to

# Check for I/O wait on the hypervisor
iostat -x 1 5
```

---

## Recommended Fixes

### P0 — Disk I/O

1. **Check pve5 disk health** — Run SMART diagnostics on the physical disk backing moody-good's VM.

2. **Add a dedicated storage disk to moody-good** — The node has 50 CPUs and 238GB RAM but only a single shared disk. Add a `storage_disks` entry in Terraform on a **separate physical disk** from the OS.

3. **Fix skrillex disk contention** — Both OS and storage disk are on `disk3`. Move one to a different physical datastore.

### P1 — Kubelet Resilience

1. **Consider percentage-based eviction thresholds** — For large-memory nodes:

   ```
   eviction-hard: "memory.available<5%,nodefs.available<10%"
   eviction-soft: "memory.available<10%,nodefs.available<15%"
   ```

2. **Consider NFS soft mounts** — Change `hard=True` to `soft=True` (or add `timeo=300,retrans=3`) to prevent indefinite hangs.

3. **Remove `drmoo.io/storage: rook-osd-node` from moody-good** until it has a dedicated storage disk.

### P2 — Control Plane

1. **Increase control-plane VM memory** — 8GB may be insufficient. kube-apiserver uses 2-3.5GB. Consider 12-16GB.

---

## Key Metrics to Monitor

- `node_pressure_io_waiting_seconds_total` (PSI I/O full > 5%)
- `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1`
- `kubelet_runtime_operations_duration_seconds` (latency spikes = I/O issues)
- `node_disk_io_time_seconds_total` (disk utilization > 80%)

---

## Current Status (2026-01-28): STABLE

| Node | Role | CPU% | Memory% | Status |
|------|------|------|---------|--------|
| porter-robinson | control-plane | 36% | 89% | High memory |
| fox-stevenson | control-plane | 33% | 66% | OK |
| fred-again | control-plane | 13% | 82% | High memory |
| mat-zo | worker | 18% | 33% | OK |
| moody-good | worker | 1% | 2% | Healthy |
| skrillex | worker | 16% | 26% | OK |

The cluster is stable. Control plane memory pressure remains the main concern to address.
