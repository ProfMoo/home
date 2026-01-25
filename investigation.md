# Node Crash Investigation - 2026-01-24

## Problem Statement

Worker nodes become overwhelmed and go unreachable every few hours. The pattern has affected both `skrillex` (pve) and `moody-good` (pve5). The crash manifests as kubelet stopping heartbeats, followed by the node being tainted `unreachable`.

## Timeline

- **moody-good** was cordoned prior to investigation due to repeated crashes every few hours.
- **~8 PM EST (01:02 UTC) Jan 24** — `skrillex` went unreachable. Last heartbeat: `01:02:14Z`.
- **~5 PM EST Jan 24** — `moody-good` uncordoned for observation. Currently stable but showing I/O pressure.

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
| moody-good | worker/storage | 50 | 238GB | 450GB (disk3) | **NONE** | pve5 |

### Kubelet Configuration (all workers identical)

```
system-reserved: cpu=1000m, memory=2Gi, ephemeral-storage=2Gi
kube-reserved: cpu=1000m, memory=2Gi, ephemeral-storage=2Gi
eviction-hard: memory.available<1Gi, nodefs.available<10%
eviction-soft: memory.available<2Gi, nodefs.available<15%
eviction-soft-grace-period: memory.available=1m30s, nodefs.available=2m
```

### Sysctls (all workers)

```
vm.nr_hugepages: 1024       # Pre-allocates 2GB hugepages (non-evictable)
net.core.rmem_max: 67108864 # 64MB receive buffer
net.core.wmem_max: 67108864 # 64MB send buffer
```

### NFS Configuration (all workers)

```
nfsvers=4.2
hard=True       # NFS ops block INDEFINITELY if server unreachable
nconnect=16     # 16 concurrent NFS connections
noatime=True
```

---

## Current Node Resource Usage

| Node | CPU% | Memory% | Status |
|------|------|---------|--------|
| porter-robinson | 42% | **99%** | CRITICAL - nearly OOM |
| fox-stevenson | 72% | 73% | High |
| fred-again | 17% | 81% | High memory |
| mat-zo | 20% | 31% | OK |
| skrillex | 13% | 10% | Recovered from crash |
| moody-good | 1% | 1% | Just uncordoned, **I/O pressure building** |

---

## Critical Findings

### 1. DISK I/O CONTENTION (Primary Suspect)

**moody-good kubelet PSI (Pressure Stall Information) right now:**

```
IO PSI full:  avg10=9.94%  avg60=7.75%  avg300=2.05%  (trending UP)
IO PSI some:  avg10=9.94%  avg60=7.75%  avg300=2.05%
```

The kubelet is stalled on disk I/O for ~10% of recent time, and it's getting **worse** (2% over 5min → 10% over 10s). If this continues, the kubelet will be unable to post heartbeats and the node goes unreachable.

**Why this happens — disk layout problems:**

- **skrillex**: OS disk and Ceph OSD storage disk are on the **same physical datastore** (`disk3`). The OSD's I/O directly competes with the kubelet, containerd, and all container filesystem operations.
- **moody-good**: Has **no dedicated storage disk at all** despite being labeled `rook-osd-node`. Its single 450GB disk handles everpything — OS, kubelet, containerd, all pod ephemeral storage, and CSI volume operations. Any I/O-intensive workload (Ceph, backups, container pulls) hammers the same disk.
- **mat-zo** (the stable node): Has a **separate physical disk** (`disk4`, 500GB) for its second OSD, distributing I/O load.

### 2. EVICTION THRESHOLDS TOO PERMISSIVE

The hard eviction threshold is `memory.available<1Gi`. On these nodes:

- **skrillex (80GB)**: Won't evict until 98.7% memory used
- **moody-good (238GB)**: Won't evict until 99.6% memory used

By the time kubelet starts evicting pods, the kernel OOM killer has likely already killed critical system processes (potentially including kubelet itself). The eviction soft grace period of 1m30s is also extremely short — soft eviction triggers at 2Gi free but only gives 90 seconds before escalating. This barely gives time for graceful pod termination.

### 3. NFS HARD MOUNTS CAN HANG THE NODE

```
hard=True
nconnect=16
```

NFS hard mounts mean any I/O operation to the NFS share (`192.168.8.248:/mnt/vault/media`) will **block indefinitely** if the NFS server becomes unreachable. With `nconnect=16`, up to 16 kernel threads can be blocked simultaneously. If the NFS server has a momentary hiccup, pods using NFS (tqm, media apps) will have blocked I/O threads, contributing to the I/O pressure that stalls the kubelet.

Pods using this NFS mount: tqm, qbittorrent, radarr, sonarr, navidrome, and potentially others in the media namespace.

### 4. HUGEPAGES CONSUMING FIXED MEMORY

`vm.nr_hugepages=1024` pre-allocates 2GB of memory that:

- Cannot be reclaimed by the kernel OOM killer
- Cannot be used for normal allocations
- Reduces effective available memory from 80GB → 78GB (skrillex) or 238GB → 236GB (moody-good)
- Is not accounted for in kubelet eviction thresholds

On skrillex this shows as `hugepages-2Mi: 2Gi` in allocatable. On moody-good it shows `hugepages-2Mi: 0` — meaning the hugepages may not be properly allocated on pve5, or the difference in allocatable vs capacity (~5Gi gap) includes them differently.

### 5. CONTROL PLANE MEMORY EXHAUSTION

`porter-robinson` is at **99% memory** with only 8GB allocated. kube-apiserver alone uses 3.4GB. If this node OOMs:

- API server becomes unavailable
- Node heartbeat processing stops
- All nodes appear unreachable simultaneously
- Pod scheduling halts entirely

This is a separate but related risk — the cluster is running on razor-thin control plane margins.

### 6. moody-good HAS NO CEPH OSD BUT IS LABELED FOR ONE

moody-good has `drmoo.io/storage: rook-osd-node` but:

- Has no dedicated storage disk in its Terraform config
- No active OSD pod running on it
- `rook-ceph-osd-prepare-moody-good` completed 30 days ago but likely found no suitable raw device
- `rook-ceph-mon-l` is Pending (wants to schedule to moody-good but can't for unknown reason)

This means rook-discover is constantly scanning for disks, and CSI operations on the 5 attached RBD volumes all go through the single OS disk, contributing to I/O pressure.

### 7. pve5 HYPERVISOR POTENTIAL DISK DEGRADATION

Both nodes on `pve5` show concerning behavior:

- **moody-good**: I/O PSI pressure trending up, repeated crashes
- **fred-again**: 81% memory usage (control-plane)

If `pve5`'s physical `disk3` (where moody-good's VM disk lives) is degraded or slow (aging HDD, SMART errors, filesystem fragmentation), it would explain why moody-good specifically keeps crashing regardless of pod workload. The node has only 1% CPU and 1% memory usage but 10% I/O stall — this points to underlying disk performance, not Kubernetes workload.

---

## Crash Mechanism Theory

1. Normal operations cause moderate I/O on the shared disk (kubelet, containerd, CSI mounts, pod ephemeral writes)
2. A periodic event triggers heavy I/O (Ceph scrub/rebalance, volsync backup, NFS-dependent CronJob, or container image pull)
3. I/O pressure stalls the kubelet's heartbeat goroutine
4. After `node-monitor-grace-period` (default 40s) without heartbeats, the control plane marks the node unreachable
5. Pod eviction begins after `pod-eviction-timeout` (default 5m), causing more I/O as pods are terminated and recreated
6. If it's an NFS hang: the blocked threads never release, and the node is permanently stuck until manual intervention

---

## What to Check When moody-good Crashes Next

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

### After Recovery

```bash
# Full kubelet logs around crash
talosctl -n 192.168.8.123 logs kubelet --since 1h

# System journal for hints
talosctl -n 192.168.8.123 logs kernel --since 1h
```

### From Proxmox (pve5 host)

```bash
# Check physical disk health
smartctl -a /dev/sdX  # wherever disk3 maps to

# Check for I/O wait on the hypervisor
iostat -x 1 5

# Check if VM disk is fragmented
```

---

## Recommended Fixes (Priority Order)

### P0 — Immediate Stability

1. **Check pve5 disk health** — Run SMART diagnostics on the physical disk backing moody-good's VM. If degraded, this is the root cause.

2. **Add a dedicated storage disk to moody-good** — The node has 50 CPUs and 238GB RAM but only a single shared disk. Add a `storage_disks` entry in Terraform (like skrillex/mat-zo have) on a **separate physical disk** from the OS.

3. **Fix skrillex disk contention** — Both OS and storage disk are on `disk3`. Move one to a different physical datastore.

### P1 — Kubelet Resilience

1. **Increase eviction thresholds** — For nodes this large, percentage-based thresholds are more appropriate:

   ```
   eviction-hard: "memory.available<5%,nodefs.available<10%"
   eviction-soft: "memory.available<10%,nodefs.available<15%"
   ```

   This gives 8GB headroom on skrillex, 24GB on moody-good.

2. **Switch NFS to soft mounts** — Change `hard=True` to `soft=True` (or `hard=True` with `timeo=300,retrans=3`) to prevent indefinite hangs. Alternatively add `intr` if supported.

3. **Remove `drmoo.io/storage: rook-osd-node` from moody-good** until it has a dedicated storage disk. This stops rook-discover from wasting I/O scanning for disks.

### P2 — Control Plane

1. **Increase control-plane VM memory** — 8GB is insufficient. kube-apiserver alone uses 3.4GB on porter-robinson (99% memory). Increase to at least 12-16GB.

### P3 — Optimization

1. **Evaluate hugepages** — Unless a specific workload needs them (Ceph OSD with hugepages?), remove `vm.nr_hugepages: 1024` to reclaim 2GB per node.

2. **Separate Ceph OSD datastore from OS datastore** — On skrillex and mat-zo, the first storage disk uses the same datastore as the OS disk. This guarantees I/O contention during Ceph operations.

---

## Current Broken Services (for context, not root cause)

- **Prometheus**: CrashLoopBackOff (136+ restarts) — no metrics collection
- **Grafana/Loki**: Were on skrillex, recovered but datasources broken
- **jellyfin**: CrashLoopBackOff — PVC full (2Gi)
- **tqm CronJob**: Init failures (qui proxy HTTP 500), creating pod storms
- **volsync-src-jellyfin**: Stale restic lock from crashed pod, retrying every 3min
- **sonarr**: CrashLoopBackOff (233+ restarts)
- **rook-ceph-mon-l**: Pending 22 days

---

## Key Metrics to Monitor

When observability is restored, set alerts for:

- `node_pressure_io_waiting_seconds_total` (PSI I/O full > 5%)
- `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1`
- `kubelet_runtime_operations_duration_seconds` (latency spikes = I/O issues)
- `node_disk_io_time_seconds_total` (disk utilization > 80%)
