# moody-good RCU Stall Investigation — NUMA Root Cause

## TL;DR

`moody-good` periodically experiences kernel RCU stalls that cause kubelet/containerd
to time out, marking the node unreachable. Root cause is **NUMA topology mismatch**:
the VM (50 vCPU, 238GB RAM) is too large to fit within a single NUMA node on its
dual-socket host (`pve5`), and the guest is configured `numa: 0`, so the guest
kernel cannot make NUMA-aware scheduling decisions. Cross-socket memory access and
spinlock contention in per-CPU subsystems (cgroup rstat flush, RCU bookkeeping,
scheduler load balancer) starve the `rcu_sched` kthread long enough to trigger
RCU stall warnings.

The disk-I/O and Cilium-BPF-SNAT theories from prior investigations were both wrong.

## Background

This investigation supersedes `investigation.md` (Jan–Feb 2026), which focused on
disk I/O contention, NFS hangs, and kubelet eviction thresholds. None of those
were the actual cause. Both prior diagnoses were misled by sample bias in the
single stack trace available at the time.

## Evidence

### Three stalls, three different stacks

| Date | Stuck CPU was running | Subsystem |
|------|----------------------|-----------|
| 2026-02-12 10:54 / 11:24 | `tail_handle_snat_fwd_ipv4` | Cilium BPF SNAT |
| 2026-04-25 22:22 (cpu=2) | `update_sd_lb_stats` -> `sched_balance_domains` | Kernel scheduler |
| 2026-04-25 22:22 (cpu=3) | `queued_spin_lock_slowpath` -> `rcu_report_qs_rdp` | RCU per-CPU spinlock |
| 2026-04-26 13:26 (cpu=33) | `mem_cgroup_stat_aggregate` -> `flush_memcg_stats_dwork` | Cgroup rstat |

The variety rules out a bug in any one subsystem. They are bystanders. The
common signal across every event is:

```text
rcu: rcu_sched kthread timer wakeup didn't happen for 5249 jiffies!
rcu: Possible timer handling issue on cpu=33 timer-softirq=...
rcu: Unless rcu_sched kthread gets sufficient CPU time, OOM is now expected behavior.
```

That is a generic CPU-starvation message. The crashes are about CPU time, not
about disk, NFS, network, or any specific kernel subsystem.

### Other nodes do not stall

`mat-zo` (15 vCPU, 80GB) and `skrillex` (15 vCPU, 80GB) run the same Cilium
config (`bpf.masquerade: true`), the same Talos kernel (6.18.5), and the same
Ceph workload. Neither shows any RCU stalls. The bug is `moody-good`-specific.

### CPU steal time on moody-good is ~zero

```text
$ talosctl -n 192.168.8.123 read /proc/stat | head -1
cpu  154054217 3755883 99783013 32075114117 30953873 0 37553205 383172 0 0
                                                              ^^^^^^
                                                              steal
```

steal / total = 383,172 / ~32.4e9 = **0.0012%**. The hypervisor is not
pre-empting `moody-good`'s vCPUs in any meaningful way. Whatever is starving the
guest CPU is internal to the guest, not host-induced overcommit.

### pve5 host topology

```text
$ lscpu
CPU(s):              56
Thread(s) per core:  2
Core(s) per socket:  14
Socket(s):           2

$ cat /sys/devices/system/node/node{0,1}/cpulist
node0: 0-13,28-41
node1: 14-27,42-55

$ cat /sys/devices/system/node/node{0,1}/meminfo | grep MemTotal
node0: 131930680 kB  (~128 GB)
node1: 132056972 kB  (~128 GB)
```

Two NUMA nodes, each with 28 threads (14 cores + SMT siblings) and 128 GB RAM.

### moody-good Proxmox config

```text
cores: 50
sockets: 1
numa: 0
memory: 243712 (~238 GB)
```

50 vCPUs cannot fit in 28 threads of a single NUMA node. 238 GB cannot fit in
128 GB of a single node. Both CPU and memory force the VM to span both sockets,
yet `numa: 0` hides the topology from the guest.

## Mechanism

When a guest VM spans multiple host NUMA nodes without NUMA awareness:

1. The Linux scheduler in the guest treats all 50 vCPUs as equivalent and
   migrates tasks freely between them.
2. Per-CPU data structures (RCU bookkeeping, percpu counters, cgroup rstat,
   scheduler runqueue stats) are accessed by whichever vCPU thread the host
   schedules on whichever physical CPU.
3. Cache lines containing those structures bounce between sockets through the
   inter-socket link (UPI/QPI). A cross-socket cache-line transfer is roughly
   5-10x slower than a local L3 fetch, and `cmpxchg` operations across sockets
   are dramatically slower still.
4. Hot spinlocks (e.g. `rcu_report_qs_rdp`, `css_rstat_flush`) become
   bottlenecks: holders sit waiting on cross-socket cache transfers while
   waiters spin, multiplied across 50 vCPUs.
5. Workloads that iterate per-CPU data — and there are many in modern Linux:
   `flush_memcg_stats_dwork`, `update_sd_lb_stats`, RCU grace period
   tracking — take long enough that the `rcu_sched` kthread fails to be
   scheduled within its grace-period deadline.
6. Kernel emits `rcu_sched self-detected stall` and `Possible timer handling
   issue on cpu=N`. While stalled, kubelet's `/healthz` and containerd's
   gRPC health checks time out, kubelet stops heartbeating, and the API
   server marks the node unreachable.

The stack trace from any given stall is essentially random — it shows whatever
the stalled CPU happened to be doing when the grace-period deadline expired.

## Why other nodes are fine

| VM | vCPU | RAM | Fits one NUMA node? | Stalls? |
|----|------|-----|---------------------|---------|
| moody-good | 50 | 238G | **No** (cpu and mem both exceed) | Yes |
| mat-zo | 15 | 80G | Yes | No |
| skrillex | 15 | 80G | Yes | No |
| fred-again | 3 | 8G | Yes | No |

Linux on the host automatically NUMA-balances small VMs onto a single node.
moody-good is too large to be placed on one node, so it cannot benefit.

## What's documented vs. inferred

**Documented** (cite-able):
- Proxmox wiki on NUMA: a VM larger than one host NUMA node should have
  `numa: 1` or it will pay cross-socket costs.
- QEMU and RHEL virtualization tuning guides say the same.

**Inferred** (pattern-matched from stack traces):
- That cross-NUMA contention is severe enough to specifically trigger
  `rcu_sched` stalls in the patterns we observed. There is no upstream kernel
  bug or fix to point at; this is a scalability/locality issue, not a defect.

The fix below is therefore being applied as an empirical test: shrink the VM to
fit in one NUMA node, observe whether the stalls stop. If they continue,
this theory is wrong and a different mechanism is at play.

## Fix Applied

`infrastructure/main.tf` — moody-good resized:

| Field | Before | After |
|-------|--------|-------|
| cpu_cores | 50 | 16 |
| memory | 243712 (238 GB) | 102400 (100 GB) |

Both values now fit comfortably within one NUMA node (28 threads, 128 GB) with
headroom for `fred-again` (3 vCPU / 8 GB, also on pve5) and host overhead.
The Linux scheduler on the host will automatically place this VM on whichever
NUMA node has more free resources at boot, and NUMA balancing will keep it
there.

The Talos node config (`infrastructure/nodes/moody-good.yaml`) is unchanged.
Kubelet `system-reserved` (1 CPU / 2 GB) and `kube-reserved` (1 CPU / 2 GB)
leave 14 CPU / 96 GB allocatable — well above current moody-good utilization
(~1% CPU per `kubectl top`).

The VM must be rebooted for Proxmox to apply the new sizing. Apply the
Terraform plan, then reboot the VM via Proxmox or `talosctl reboot`.

## Soak Plan

Run for at least 7 days post-reboot. Monitor:

```bash
# Should return no recent matches if fix worked
talosctl -n 192.168.8.123 dmesg 2>&1 | grep -E "rcu_sched|stalls on CPUs|hung_task"

# Steal time should stay near zero (it already does)
talosctl -n 192.168.8.123 read /proc/stat | head -1 | awk '{print "steal=" $9}'

# kubectl/Proxmox should not show NodeReady=False transitions
kubectl get events --field-selector involvedObject.name=moody-good --sort-by='.lastTimestamp'
```

### Outcomes

- **Stalls stop:** NUMA was the cause. Optionally consider scaling moody-good
  back up later by either (a) staying within one NUMA node, or (b) enabling
  full guest NUMA passthrough (`numa: 1`, `sockets: 2`, `cores: 14` per
  socket, plus `numa0`/`numa1` host-pinning lines in `/etc/pve/qemu-server/`).
  Option (b) requires a custom Terraform module change since the bpg/proxmox
  provider may not expose those fields directly.

- **Stalls continue:** This theory is wrong. Next places to look:
  - Talos kernel 6.18.5 timer/clocksource regression (try Talos LTS).
  - Local oddity on pve5 (BIOS settings, microcode, hardware IPMI events).
  - Workload-specific: drain rook-ceph OSDs from moody-good and observe
    whether stalls correlate with Ceph activity.

## Corrections to Prior Investigation

- `investigation.md` says moody-good has "NONE" for storage disks. That is
  outdated: it currently has three storage disks (`pve5-disk4`, `disk5`,
  `disk6`) — see `infrastructure/main.tf` lines 250–266. The disk-I/O
  contention concern is therefore moot.
- The eviction-threshold concern (memory.available<1Gi on a large-memory node)
  was already addressed: kubelet config now uses `memory.available<2Gi`
  hard / `<4Gi` soft.
- The NFS `hard` mount concern was addressed: `/etc/nfsmount.conf` now sets
  `soft=True, timeo=300, retrans=3`.

## Reference: Stack Trace Excerpts

### 2026-04-26 13:26:10 (cpu=33, cgroup rstat path)

```text
rcu: INFO: rcu_sched self-detected stall on CPU
rcu:    41-...!: (5250 ticks this GP) idle=512c/1/0x4000000000000000 softirq=...
rcu: rcu_sched kthread starved for 5174 jiffies! ->cpu=33
rcu:    Unless rcu_sched kthread gets sufficient CPU time, OOM is now expected behavior.

NMI backtrace for cpu 33
CPU: 33 UID: 0 PID: 140216 Comm: kworker/u200:5
Workqueue: events_unbound flush_memcg_stats_dwork
RIP: 0010:mem_cgroup_stat_aggregate+0x7d/0xf0
Call Trace:
  mem_cgroup_css_rstat_flush+0xba/0x350
  css_rstat_flush+0x2b4/0x790
  flush_memcg_stats_dwork+0x1a/0x40
  process_one_work+0x189/0x2f0
  worker_thread+0x272/0x3c0
```

### 2026-04-25 22:22:34 (cpu=3, RCU spinlock path)

```text
rcu: rcu_sched kthread timer wakeup didn't happen for 5249 jiffies!
rcu:    Possible timer handling issue on cpu=33 timer-softirq=48199641
rcu: rcu_sched kthread starved for 5250 jiffies! ->cpu=33

NMI backtrace for cpu 3
CPU: 3 UID: 0 PID: 277 Comm: kcompactd0
RIP: 0010:queued_spin_lock_slowpath+0x176/0x320
Call Trace:
  <IRQ>
  _raw_spin_lock_irqsave+0x55/0x80
  rcu_report_qs_rdp+0x2d/0xd0
  rcu_core+0x566/0xdb0
```

### 2026-02-12 10:54:31 (Cilium BPF SNAT path — sample bias)

```text
rcu: INFO: rcu_sched detected stalls on CPUs/tasks:
rcu:    13-...!: (764 ticks this GP) idle=413c/1/0x4000000000000002

NMI backtrace for cpu 13
RIP: 0010:lookup_nulls_elem_raw+0x1d/0xa0
Call Trace:
  <IRQ>
  bpf_prog_..._tail_handle_snat_fwd_ipv4+0x221/0x5c52
  htab_lru_map_lookup_elem+0x4d/0x90
  bpf_prog_..._cil_to_netdev+0x117e/0x2103
  __dev_queue_xmit+0x661/0xea0
  ip_finish_output2+0x3f2/0x590
  __tcp_transmit_skb+0xbcb/0xde0
  tcp_keepalive_timer+0x126/0x310
```
