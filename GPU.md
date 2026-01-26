# NVIDIA GPU Support for Kubernetes Cluster

This guide documents how to add NVIDIA Tesla T4 GPU support to the homelab Kubernetes cluster for hardware-accelerated transcoding in Jellyfin.

## Overview

| Component | Details |
|-----------|---------|
| GPU | NVIDIA Tesla T4 16GB GDDR6 (Turing architecture) |
| Proxmox Host | pve5 (SuperMicro SYS-6028U-TR4T+) |
| Target VM | moody-good (50 vCPU, 238GB RAM) |
| Primary Use Case | Jellyfin NVENC/NVDEC hardware transcoding |

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│ pve5 (Proxmox Host)                                         │
│                                                             │
│  ┌─────────────────┐    PCI Passthrough    ┌─────────────┐ │
│  │  NVIDIA T4 GPU  │ ──────────────────▶   │ moody-good  │ │
│  │  (Physical)     │                       │    (VM)     │ │
│  └─────────────────┘                       └──────┬──────┘ │
└────────────────────────────────────────────────────────────┼┘
                                                     │
                    ┌────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Talos Linux (moody-good)                                    │
│                                                             │
│  System Extensions:                                         │
│  • nonfree-kmod-nvidia-production (kernel drivers)          │
│  • nvidia-container-toolkit-production (container runtime)  │
│                                                             │
│  Containerd: default_runtime = "nvidia"                     │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Kubernetes                                                  │
│                                                             │
│  ┌──────────────────┐     ┌─────────────────────────────┐  │
│  │ GPU Operator     │     │        GPU Workloads        │  │
│  │ (device plugin,  │     │  (Time-sliced: 4 replicas)  │  │
│  │  GFD, DCGM)      │     ├─────────────────────────────┤  │
│  │                  │────▶│ Jellyfin    nvidia.com/gpu:1│  │
│  │ Time-slicing:    │     │ Ollama      nvidia.com/gpu:1│  │
│  │ nvidia.com/gpu:4 │     │ Frigate     nvidia.com/gpu:1│  │
│  │ (advertised)     │     │ (1 slot free)               │  │
│  └──────────────────┘     └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Proxmox Configuration (pve5)

### Why This Phase is Needed

PCI passthrough allows a virtual machine to directly access physical hardware, bypassing the hypervisor for that device. This is essential for GPU workloads because:

1. **Performance**: Direct hardware access eliminates virtualization overhead. The VM talks directly to the GPU via DMA (Direct Memory Access), achieving near-native performance.

2. **Driver compatibility**: The guest OS loads the actual NVIDIA drivers, enabling full CUDA, NVENC, and NVDEC functionality. Emulated/virtualized GPUs can't provide this.

3. **Exclusive access**: The GPU is fully dedicated to the VM. Unlike vGPU (which requires expensive enterprise licenses for consumer use), passthrough gives the VM complete control.

> **Source**: [Proxmox PCI Passthrough Wiki](https://pve.proxmox.com/wiki/PCI_Passthrough)

---

### 1.1 Enable IOMMU in GRUB

**What**: IOMMU (Input-Output Memory Management Unit) is a hardware feature that allows the hypervisor to control which memory regions a device can access.

**Why**: Without IOMMU, a passed-through device could read/write any memory address, including the hypervisor's memory or other VMs' memory. IOMMU creates isolated memory domains, making passthrough safe. Intel calls their implementation "VT-d" (Virtualization Technology for Directed I/O).

The `iommu=pt` parameter enables "passthrough mode" which improves performance by skipping IOMMU translation for devices that don't need isolation (like the CPU's own memory access).

> **Source**: [Intel VT-d Documentation](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html), [Proxmox PCI Passthrough Guide](https://pve.proxmox.com/wiki/PCI_Passthrough#Enable_the_IOMMU)

SSH to pve5 and edit `/etc/default/grub`:

```bash
# For Intel CPU (SuperMicro uses Intel Xeons)
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
```

Update GRUB and reboot:

```bash
update-grub
reboot
```

---

### 1.2 Load VFIO Modules

**What**: VFIO (Virtual Function I/O) is a Linux kernel framework that provides safe, non-privileged userspace drivers. It's the mechanism that allows QEMU/KVM to give VMs direct access to PCI devices.

**Why**: These kernel modules must be loaded for PCI passthrough to work:

- `vfio`: Core VFIO framework
- `vfio_iommu_type1`: IOMMU driver for x86 systems with Intel VT-d or AMD-Vi
- `vfio_pci`: Allows binding PCI devices to VFIO instead of their native drivers
- `vfio_virqfd`: Enables interrupt forwarding to VMs

> **Source**: [Linux Kernel VFIO Documentation](https://www.kernel.org/doc/html/latest/driver-api/vfio.html)

Add to `/etc/modules`:

```
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

---

### 1.3 Blacklist NVIDIA Drivers on Host

**What**: Prevent the Proxmox host from loading any NVIDIA drivers.

**Why**: If the host loads NVIDIA drivers, they will "claim" the GPU and bind to it. A device can only be bound to one driver at a time. By blacklisting NVIDIA drivers, we ensure the GPU remains unbound so VFIO can claim it instead. The `nouveau` driver is the open-source NVIDIA driver that Linux loads by default.

> **Source**: [Proxmox Forum - GPU Passthrough Tutorial](https://forum.proxmox.com/threads/pci-gpu-passthrough-on-proxmox-ve-8-installation-and-configuration.130218/)

Create `/etc/modprobe.d/blacklist-nvidia.conf`:

```
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
blacklist nvidiafb
```

---

### 1.4 Bind GPU to VFIO

**What**: Tell the kernel to bind the GPU to the `vfio-pci` driver at boot time.

**Why**: By default, Linux would try to find and load an appropriate driver for the GPU. By specifying the GPU's vendor:device ID (`10de:1eb8` = NVIDIA Tesla T4), we tell the kernel "always use vfio-pci for this device." This ensures the GPU is ready for passthrough before any VM starts.

> **Source**: [VFIO Tips and Tricks](https://vfio.blogspot.com/2015/05/vfio-gpu-how-to-series-part-3-host.html)

Find the GPU's PCI address and device IDs:

```bash
lspci -nn | grep -i nvidia
# Example output: 3b:00.0 3D controller [0302]: NVIDIA Corporation TU104GL [Tesla T4] [10de:1eb8] (rev a1)
```

Create `/etc/modprobe.d/vfio.conf`:

```
options vfio-pci ids=10de:1eb8
```

Update initramfs and reboot:

```bash
update-initramfs -u -k all
reboot
```

---

### 1.5 Verify VFIO Binding

**What**: Confirm the GPU is bound to vfio-pci and ready for passthrough.

**Why**: This verification step ensures all previous configuration took effect. If the GPU shows a different driver (like `nouveau` or `nvidia`), passthrough will fail.

```bash
lspci -nnk -s 3b:00.0
# Should show: Kernel driver in use: vfio-pci
```

---

## Phase 2: Terraform Changes

### Why This Phase is Needed

Your infrastructure follows IaC principles using Terraform to provision Proxmox VMs. To pass the GPU through to moody-good, we need to:

1. Add the `hostpci` configuration to the VM definition
2. Keep this change version-controlled and reproducible
3. Allow future GPU nodes to be easily configured

> **Source**: [Proxmox Terraform Provider - hostpci](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#hostpci)

---

### 2.1 Add PCI Passthrough to Node Module

**What**: Extend the node Terraform module to support PCI device passthrough.

**Why**: The current `infrastructure/modules/node/proxmox_vm.tf` doesn't have a `hostpci` block. Adding this as a variable with a default empty list means existing nodes are unaffected, while GPU nodes can specify devices to pass through.

Update `infrastructure/modules/node/variables.tf`:

```hcl
variable "pci_devices" {
  type = list(object({
    device_id  = string  # PCI address (e.g., "0000:3b:00.0")
    pcie       = bool    # Use PCIe passthrough mode
    rombar     = bool    # Enable ROM BAR
    x_vga      = bool    # Primary GPU (usually false for compute GPUs)
  }))
  description = "PCI devices to pass through to the VM (e.g., GPUs)"
  default     = []
}
```

**Parameter explanations**:

- `device_id`: The PCI address from `lspci` (format: `0000:bus:device.function`)
- `pcie`: Enables PCIe mode vs legacy PCI. PCIe provides better performance and is required for modern GPUs
- `rombar`: Exposes the device's option ROM to the VM. Required for some devices to initialize properly
- `x_vga`: Marks this as the primary display adapter. Set `false` for compute GPUs like the T4 (they have no display outputs)

> **Source**: [Proxmox VM hostpci Documentation](https://pve.proxmox.com/wiki/Qemu/KVM_Virtual_Machines#qm_pci_passthrough)

Update `infrastructure/modules/node/proxmox_vm.tf`:

```hcl
resource "proxmox_virtual_environment_vm" "talos_node" {
  # ... existing configuration ...

  # GPU passthrough
  dynamic "hostpci" {
    for_each = var.pci_devices
    content {
      device  = hostpci.value.device_id
      pcie    = hostpci.value.pcie
      rombar  = hostpci.value.rombar
      xvga    = hostpci.value.x_vga
    }
  }
}
```

---

### 2.2 Update moody-good Configuration

**What**: Add the Tesla T4 to moody-good's VM configuration.

**Why**: This is where we actually assign the GPU to the specific worker node. The `drmoo.io/gpu: nvidia-t4` label will be used later by Kubernetes to schedule GPU workloads to this node.

In `infrastructure/main.tf`, update the moody-good worker node:

```hcl
"worker_node_instance_4" = {
  id                    = "1105"
  name                  = "moody-good"
  description           = "GPU-enabled worker node in the Kubernetes homelab cluster"
  tags                  = ["worker-node", "kubernetes", "gpu"]
  cpu_cores             = 50
  memory                = 243712
  bridge_network_device = "vmbr0"
  proxmox_node_name     = "pve5"
  initial_boot_iso      = module.talos_1_10_6_iso_pve5.talos_iso_id

  disk_size = "450"
  datastore = "disk3"

  # GPU Passthrough - Tesla T4
  # The GPU appears as a PCI device inside the VM, just like on bare metal
  pci_devices = [
    {
      device_id = "0000:3b:00.0"  # Adjust to actual PCI address from lspci
      pcie      = true
      rombar    = true
      x_vga     = false  # T4 is a compute GPU, not display
    }
  ]

  talos_version      = "1.10.6"
  kubernetes_version = "1.33.4"

  talos_virtual_ip = "192.168.8.99"

  vlan_id        = "2"
  ipv4_address   = "192.168.8.123"
  mac_address    = "94:96:cc:43:7d:80"
  subnet_gateway = "192.168.8.1"

  pod_subnets     = "10.244.0.0/16"
  service_subnets = "10.96.0.0/12"

  kubernetes_node_labels = {
    "drmoo.io/role" : "worker"
    "drmoo.io/zone" : "pve5"
    "drmoo.io/storage" : "rook-osd-node"
    "drmoo.io/gpu" : "nvidia-t4"  # New label for GPU scheduling
  }
}
```

---

## Phase 3: Talos Configuration

### Why This Phase is Needed

Talos Linux is an immutable, secure operating system designed for Kubernetes. Unlike traditional Linux distributions:

1. **No shell access**: You can't SSH in and run `apt install nvidia-driver`
2. **Read-only filesystem**: The root filesystem is immutable
3. **Signed kernel modules only**: For security, Talos only loads kernel modules signed by Sidero Labs

This means NVIDIA drivers must be installed via **system extensions** - pre-built, signed modules that are baked into the Talos image at boot time.

> **Source**: [Talos Linux NVIDIA GPU Documentation](https://www.talos.dev/v1.9/talos-guides/configuration/nvidia-gpu-proprietary/)

---

### 3.1 Generate New Image Factory Schematic

**What**: Create a custom Talos image that includes NVIDIA drivers and container toolkit.

**Why**: The [Talos Image Factory](https://factory.talos.dev/) generates custom Talos images with specific extensions. Your current schematic (`dc7b152...`) doesn't include NVIDIA extensions. A new schematic will include:

- `nonfree-kmod-nvidia-production`: The NVIDIA proprietary kernel modules (nvidia.ko, nvidia-uvm.ko, etc.). These are required for the GPU to function.
- `nvidia-container-toolkit-production`: Enables containers to access the GPU. This includes `nvidia-container-runtime` which wraps containerd to inject GPU device access into containers.

> **Source**: [Talos Image Factory](https://factory.talos.dev/), [Sidero Labs Extensions Repository](https://github.com/siderolabs/extensions)

**Steps**:

1. Go to [Talos Image Factory](https://factory.talos.dev/)
2. Select Talos version `v1.11.6` (matching your current version)
3. Add extensions:
   - Search for `nvidia` and select both:
     - `siderolabs/nonfree-kmod-nvidia-production`
     - `siderolabs/nvidia-container-toolkit-production`
4. Keep any existing extensions from your current schematic (e.g., `qemu-guest-agent`)
5. Generate the schematic and copy the new ID

**Important version matching**: The NVIDIA driver version in `nonfree-kmod-nvidia` must match the version expected by `nvidia-container-toolkit`. The Image Factory handles this automatically when you select compatible versions.

> **Source**: [Talos Extensions Compatibility](https://github.com/siderolabs/extensions#nvidia-gpu-support)

---

### 3.2 Create GPU-Specific Worker Config

**What**: Update the Talos machine configuration for moody-good to use the new NVIDIA-enabled image and configure containerd.

**Why**: Two critical changes are needed:

1. **New install image**: Points to the Image Factory schematic with NVIDIA extensions
2. **Containerd runtime configuration**: By default, containerd uses `runc`. We need to make `nvidia` the default runtime so containers automatically get GPU access without special configuration.

> **Source**: [Talos NVIDIA Configuration](https://docs.siderolabs.com/talos/v1.9/configure-your-talos-cluster/hardware-and-drivers/nvidia-gpu-proprietary/#configuring-containerd)

Create `infrastructure/configs/worker-gpu.yaml` (or add conditionals to worker.yaml):

```yaml
---
version: v1alpha1
debug: false
persist: true
machine:
  type: ${node_type}
  token: ${token}
  ca:
    crt: ${client_ca_crt}
    key: ""
  nodeLabels:
%{ for key, value in kubernetes_node_labels ~}
    ${key}: ${value}
%{ endfor ~}
  install:
    # NEW: Image Factory schematic with NVIDIA extensions
    # The schematic ID encodes which extensions are included
    # This image contains: base Talos + NVIDIA kernel modules + NVIDIA container toolkit
    image: factory.talos.dev/installer/<NEW-SCHEMATIC-ID>:v1.11.6
    disk: /dev/sda
    wipe: false
  kubelet:
    image: ghcr.io/siderolabs/kubelet:v1.34.3
    defaultRuntimeSeccompProfileEnabled: true
    disableManifestsDirectory: true
    extraArgs:
      rotate-server-certificates: true
      system-reserved: "cpu=1000m,memory=2Gi,ephemeral-storage=2Gi"
      kube-reserved: "cpu=1000m,memory=2Gi,ephemeral-storage=2Gi"
      eviction-hard: "memory.available<2Gi,nodefs.available<10%"
      eviction-soft: "memory.available<4Gi,nodefs.available<15%"
      eviction-soft-grace-period: "memory.available=3m,nodefs.available=2m"
  sysctls:
    user.max_user_namespaces: "11255"
    vm.nr_hugepages: "1024"
    net.core.rmem_max: "67108864"
    net.core.wmem_max: "67108864"
  network:
    hostname: ${hostname}
    nameservers:
      - 8.8.8.8
      - 1.1.1.1
    interfaces:
      - addresses:
          - ${ipv4_address}/24
        routes:
          - network: 0.0.0.0/0
            gateway: ${subnet_gateway}
        deviceSelector:
          hardwareAddr: '${mac_address}'
  features:
    kubePrism:
      enabled: true
      port: 7445
    hostDNS:
      enabled: true
      resolveMemberNames: true
      forwardKubeDNSToHost: false
    rbac: true
    stableHostname: true
    apidCheckExtKeyUsage: true
  files:
    - op: overwrite
      path: /etc/nfsmount.conf
      permissions: 0o644
      content: |
        [ NFSMount_Global_Options ]
        nfsvers=4.2
        hard=True
        nconnect=16
        noatime=True
    # NEW: Configure containerd to use NVIDIA runtime by default
    # Without this, containers would use runc and not see the GPU
    # The nvidia runtime wraps runc and adds GPU device mounts + environment variables
    - op: create
      path: /etc/cri/conf.d/20-customization.part
      permissions: 0o644
      content: |
        [plugins]
          [plugins."io.containerd.cri.v1.runtime"]
            [plugins."io.containerd.cri.v1.runtime".containerd]
              default_runtime_name = "nvidia"
  kernel:
    modules:
      - name: nbd
      # Note: NVIDIA modules (nvidia, nvidia_uvm, nvidia_modeset, nvidia_drm)
      # are loaded automatically by the nonfree-kmod-nvidia extension
cluster:
  # ... keep existing cluster config unchanged ...
```

---

### 3.3 Apply Configuration to moody-good

**What**: Push the new configuration to the node and trigger a reboot.

**Why**: Talos applies configuration changes atomically. The node will:

1. Download the new installer image (with NVIDIA extensions)
2. Write it to disk
3. Reboot into the new image
4. Load NVIDIA kernel modules during boot
5. Start containerd with the NVIDIA runtime available

```bash
# From infrastructure directory
talosctl apply-config --nodes 192.168.8.123 --file nodes/moody-good.yaml

# The node will reboot to apply the new image with NVIDIA extensions
# Monitor the reboot progress:
talosctl -n 192.168.8.123 dmesg -f
```

> **Source**: [Talos Configuration Application](https://www.talos.dev/v1.9/talos-guides/configuration/editing-machine-configuration/)

---

## Phase 4: Kubernetes GPU Operator

### Why This Phase is Needed

The NVIDIA GPU Operator automates the deployment and management of GPU software components in Kubernetes. On a standard Linux distribution, it would install:

- NVIDIA drivers
- NVIDIA Container Toolkit
- Kubernetes device plugin
- GPU Feature Discovery (GFD)
- DCGM Exporter (monitoring)

However, **on Talos**, drivers and toolkit are provided by system extensions (Phase 3). We disable those components and only use the GPU Operator for:

1. **Device Plugin**: Exposes GPUs as schedulable resources (`nvidia.com/gpu`)
2. **GPU Feature Discovery**: Labels nodes with GPU capabilities (architecture, memory, driver version)
3. **DCGM Exporter**: Prometheus metrics for GPU monitoring

> **Source**: [NVIDIA GPU Operator Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html), [GPU Operator on Talos](https://github.com/siderolabs/talos/issues/9014)

---

### 4.1 Create Flux Deployment Structure

**What**: Create the directory structure matching your existing GitOps patterns.

**Why**: Consistency with your existing app deployments (like rook-ceph, reloader, etc.) makes the codebase maintainable and follows the established Flux CD patterns.

```
kubernetes/homelab/apps/base/nvidia-gpu-operator/
├── ks.yaml                      # Flux Kustomization - tells Flux what to deploy
└── app/
    ├── kustomization.yaml       # Kustomize resources list
    ├── namespace.yaml           # GPU Operator namespace with PSA labels
    ├── oci-repository.yaml      # Helm chart source
    ├── helm-release.yaml        # Helm values and configuration
    └── time-slicing-config.yaml # GPU sharing configuration (multiple pods per GPU)
```

---

### 4.2 Flux Kustomization (ks.yaml)

**What**: Tells Flux CD to deploy the GPU Operator from this path.

**Why**: This is the entry point for Flux. When this file is added to the base kustomization, Flux will reconcile the GPU Operator deployment.

```yaml
---
# yaml-language-server: $schema=https://kubernetes-schemas.pages.dev/kustomize.toolkit.fluxcd.io/kustomization_v1.json
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app nvidia-gpu-operator
  namespace: &namespace gpu-operator
spec:
  targetNamespace: *namespace
  commonMetadata:
    labels:
      app.kubernetes.io/name: *app
  path: ./kubernetes/homelab/apps/base/nvidia-gpu-operator/app
  prune: true
  sourceRef:
    kind: GitRepository
    name: profmoo-home
    namespace: flux-system
  wait: false
  interval: 30m
  retryInterval: 1m
  timeout: 15m
```

---

### 4.3 Namespace (app/namespace.yaml)

**What**: Create a dedicated namespace with privileged Pod Security Admission.

**Why**: The GPU Operator components need elevated privileges:

- Device plugin needs access to `/dev/nvidia*` devices
- Some components need `hostPath` volumes
- DCGM needs access to GPU management interfaces

Without the `privileged` PSA label, Kubernetes would block these pods.

> **Source**: [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: gpu-operator
  labels:
    # Required: GPU Operator pods need privileged access to GPU devices
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
```

---

### 4.4 OCI Repository (app/oci-repository.yaml)

**What**: Define the Helm chart source as an OCI artifact.

**Why**: NVIDIA publishes the GPU Operator Helm chart to GitHub Container Registry as an OCI artifact. This matches your existing pattern (rook-ceph, app-template use OCI repositories). Version `v25.10.1` is the latest stable release as of January 2025.

> **Source**: [NVIDIA GPU Operator Releases](https://github.com/NVIDIA/gpu-operator/releases)

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: nvidia-gpu-operator
  namespace: gpu-operator
spec:
  interval: 12h
  url: oci://ghcr.io/nvidia/gpu-operator
  ref:
    tag: v25.10.1
```

---

### 4.5 Kustomization (app/kustomization.yaml)

**What**: List all resources to be applied.

**Why**: Standard Kustomize pattern - tells `kustomize build` which files to include.

```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: gpu-operator
resources:
  - namespace.yaml
  - oci-repository.yaml
  - helm-release.yaml
  - time-slicing-config.yaml  # GPU sharing configuration
```

---

### 4.6 HelmRelease (app/helm-release.yaml)

**What**: Configure the GPU Operator Helm chart with Talos-specific settings.

**Why**: This is the most critical configuration. The key insight is:

- **`driver.enabled: false`**: Talos provides drivers via the `nonfree-kmod-nvidia` extension. The GPU Operator's driver installer expects a standard Linux filesystem with `/bin/sh` - Talos doesn't have this.
- **`toolkit.enabled: false`**: Talos provides the toolkit via the `nvidia-container-toolkit` extension. Same reason as above.

The components we DO enable provide the Kubernetes integration layer.

> **Source**: [GPU Operator Helm Values](https://github.com/NVIDIA/gpu-operator/blob/master/deployments/gpu-operator/values.yaml), [Talos GPU Operator Discussion](https://github.com/siderolabs/talos/issues/9014#issuecomment-2107070034)

```yaml
---
# yaml-language-server: $schema=https://kubernetes-schemas.pages.dev/helm.toolkit.fluxcd.io/helmrelease_v2.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: nvidia-gpu-operator
spec:
  interval: 1h
  timeout: 15m
  chartRef:
    kind: OCIRepository
    name: nvidia-gpu-operator
  install:
    crds: CreateReplace
    remediation:
      retries: 3
  upgrade:
    crds: CreateReplace
    cleanupOnFail: true
    remediation:
      strategy: rollback
      retries: 3
  values:
    # ============================================================
    # CRITICAL FOR TALOS: Disable driver and toolkit installation
    # ============================================================
    # Talos provides these via system extensions. The GPU Operator's
    # installers expect a mutable filesystem with /bin/sh, which
    # Talos doesn't have. If enabled, the driver pod will crash.
    driver:
      enabled: false
    toolkit:
      enabled: false

    # ============================================================
    # Device Plugin - REQUIRED
    # ============================================================
    # The device plugin is a DaemonSet that:
    # 1. Discovers NVIDIA GPUs on each node
    # 2. Reports them to kubelet as allocatable resources (nvidia.com/gpu)
    # 3. Handles GPU allocation when pods request nvidia.com/gpu resources
    # Without this, Kubernetes has no idea GPUs exist.
    # Source: https://github.com/NVIDIA/k8s-device-plugin
    devicePlugin:
      enabled: true
      # Reference the time-slicing ConfigMap to enable GPU sharing
      # This tells the device plugin to advertise 4 GPU "replicas" instead of 1
      config:
        name: time-slicing-config  # ConfigMap name
        default: any               # Apply to all GPUs (or specify per-GPU rules)

    # ============================================================
    # GPU Feature Discovery (GFD) - RECOMMENDED
    # ============================================================
    # GFD labels nodes with detailed GPU information:
    # - nvidia.com/gpu.product: Tesla-T4
    # - nvidia.com/gpu.memory: 15360 (MB)
    # - nvidia.com/cuda.driver.major: 550
    # - nvidia.com/gpu.compute.major: 7 (Turing = compute 7.5)
    # This enables advanced scheduling (e.g., "only schedule on Turing+ GPUs")
    # Source: https://github.com/NVIDIA/gpu-feature-discovery
    gfd:
      enabled: true

    # ============================================================
    # DCGM Exporter - RECOMMENDED for observability
    # ============================================================
    # Exports GPU metrics to Prometheus:
    # - GPU utilization, memory usage, temperature
    # - Encoder/decoder utilization (useful for transcoding monitoring)
    # - Power consumption, clock speeds
    # Source: https://github.com/NVIDIA/dcgm-exporter
    dcgmExporter:
      enabled: true
      serviceMonitor:
        enabled: true  # Auto-creates ServiceMonitor for Prometheus Operator

    # ============================================================
    # Node Feature Discovery (NFD) - OPTIONAL
    # ============================================================
    # NFD detects hardware features (CPU flags, PCI devices, etc.) and
    # labels nodes accordingly. The GPU Operator uses NFD to detect
    # nodes with NVIDIA GPUs (PCI vendor ID 10de).
    # If you already have NFD deployed cluster-wide, set this to false.
    # Source: https://github.com/kubernetes-sigs/node-feature-discovery
    nfd:
      enabled: true

    # ============================================================
    # MIG Manager - NOT NEEDED for T4
    # ============================================================
    # Multi-Instance GPU (MIG) allows partitioning a single GPU into
    # multiple isolated instances. Only supported on A30, A100, H100.
    # The T4 is Turing architecture and doesn't support MIG.
    # Source: https://docs.nvidia.com/datacenter/tesla/mig-user-guide/
    migManager:
      enabled: false

    # ============================================================
    # Validator - RECOMMENDED
    # ============================================================
    # Runs validation tests to ensure the GPU stack is working:
    # - Can containers see the GPU?
    # - Is CUDA working?
    # - Can workloads be scheduled?
    # Useful for debugging deployment issues.
    validator:
      enabled: true

    # ============================================================
    # Operator settings
    # ============================================================
    operator:
      defaultRuntime: containerd  # Talos uses containerd
```

---

### 4.7 Time-Slicing Configuration (app/time-slicing-config.yaml)

**What**: Configure the GPU to be shared among multiple pods using time-slicing.

**Why**: By default, the NVIDIA device plugin treats each GPU as an indivisible resource - one pod gets the whole GPU. Time-slicing allows multiple pods to share a single GPU by giving each pod alternating time slices of GPU access. This is ideal for workloads that don't constantly saturate the GPU:

- **Jellyfin**: Only uses GPU during active transcoding sessions
- **Ollama**: Only uses GPU during inference requests
- **Frigate**: Uses GPU for object detection, but not constantly at 100%

With `replicas: 4`, the device plugin advertises `nvidia.com/gpu: 4` instead of `nvidia.com/gpu: 1`. Kubernetes can then schedule up to 4 pods that each request `nvidia.com/gpu: 1`. The GPU driver handles context-switching between them.

**Trade-offs**:

- **Performance**: Each workload gets less GPU time when others are active. Heavy simultaneous use will cause slowdowns.
- **Memory**: All pods share the GPU's 16GB VRAM. If total memory requests exceed 16GB, you'll get OOM errors.
- **No isolation**: Unlike MIG (not supported on T4), time-slicing provides no memory or fault isolation.

> **Source**: [GPU Sharing in Kubernetes](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html), [Time-Slicing GPUs in Kubernetes](https://docs.nvidia.com/datacenter/cloud-native/k8s-device-plugin/latest/time-slicing.html)

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config
  namespace: gpu-operator
data:
  # The "any" key is the default config applied to all GPUs on all nodes
  # You can also create per-node or per-GPU-model configs if needed
  any: |-
    version: v1
    sharing:
      timeSlicing:
        # Number of time-sliced "replicas" to create per physical GPU
        # This makes Kubernetes see 4 allocatable GPUs instead of 1
        # Each replica is a virtual slice that shares the physical GPU
        replicas: 4

        # Whether to fail pod creation if more pods request GPU than replicas
        # true: Pods beyond the replica count will fail to schedule (safer)
        # false: Pods may oversubscribe the GPU (can cause OOMs)
        failRequestsGreaterThanOne: false

        # Optional: rename the resource (default: nvidia.com/gpu)
        # Useful if you want separate resource names for shared vs dedicated GPUs
        # renameByDefault: false
        # resourceName: nvidia.com/gpu-shared
```

**How it works**:

1. The ConfigMap is mounted into the device plugin pod
2. Device plugin reads the config and advertises 4 GPUs to kubelet
3. When a pod requests `nvidia.com/gpu: 1`, it gets assigned one of the 4 "slots"
4. The NVIDIA driver's CUDA Time Slice Scheduler handles fair queuing between processes
5. Each process gets exclusive GPU access during its time slice (~10-50ms per slice)

**Memory considerations for your workloads**:

| Workload | Typical VRAM Usage | Notes |
|----------|-------------------|-------|
| Jellyfin (1080p transcode) | ~500MB-1GB | Very efficient |
| Jellyfin (4K transcode) | ~2-3GB | Higher for HDR tone mapping |
| Ollama (7B model) | ~4-6GB | Depends on quantization |
| Ollama (13B model) | ~8-10GB | May not fit with others |
| Frigate (object detection) | ~1-2GB | Depends on model |

With 16GB total, running Jellyfin + Ollama (7B) + Frigate simultaneously should work fine. Running larger LLM models may require either dedicated GPU access or reducing replicas.

---

### 4.8 Add to Base Kustomization

**What**: Register the GPU Operator in the base namespace's Kustomization.

**Why**: This is what triggers Flux to actually deploy the GPU Operator. Without this line, the manifests exist but aren't reconciled.

Update `kubernetes/homelab/apps/base/kustomization.yaml`:

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: base
components:
  - ../../common/all-namespaces
resources:
  - ./namespace.yaml
  - ./metrics-server/ks.yaml
  - ./reloader/ks.yaml
  - ./cert-approver/ks.yaml
  - ./external-secrets/ks.yaml
  - ./priority-classes/ks.yaml
  - ./spegel/ks.yaml
  - ./gateway-api-crds/ks.yaml
  - ./descheduler/ks.yaml
  - ./neko/ks.yaml
  - ./homepage/ks.yaml
  - ./goldpinger/ks.yaml
  - ./nvidia-gpu-operator/ks.yaml  # ADD THIS LINE
```

---

## Phase 5: Jellyfin Configuration

### Why This Phase is Needed

Now that the GPU is:

1. Passed through to the VM (Phase 1-2)
2. Visible to Talos with drivers loaded (Phase 3)
3. Exposed to Kubernetes as a schedulable resource (Phase 4)

We need to:

1. Tell Jellyfin's pod to request the GPU resource
2. Schedule Jellyfin on the GPU node
3. Configure Jellyfin's transcoding settings to use NVENC/NVDEC

> **Source**: [Jellyfin NVIDIA Hardware Acceleration](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia/)

---

### 5.1 Update HelmRelease

**What**: Modify Jellyfin's Helm values to request GPU resources and schedule on the GPU node.

**Why**:

- `nvidia.com/gpu: 1` in resources tells Kubernetes to allocate one GPU to this pod
- `nodeSelector` ensures the pod only runs on moody-good (the GPU node)
- Environment variables tell the NVIDIA runtime to expose all GPU capabilities

Modify `kubernetes/homelab/apps/media/jellyfin/app/helm-release.yaml`:

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: jellyfin
spec:
  interval: 1h
  chartRef:
    kind: OCIRepository
    name: app-template
  values:
    controllers:
      jellyfin:
        annotations:
          reloader.stakater.com/auto: "true"
        containers:
          app:
            image:
              repository: ghcr.io/jellyfin/jellyfin
              tag: 10.11.6@sha256:25db4eb10143c1c12adb79ed978e31d94fc98dc499fbae2d38b2c935089ced3e
            env:
              TZ: America/New_York
              # ============================================================
              # NVIDIA Container Runtime environment variables
              # ============================================================
              # These are typically set automatically by nvidia-container-toolkit,
              # but we set them explicitly for clarity and to ensure they're present.
              #
              # NVIDIA_VISIBLE_DEVICES: Which GPUs to expose to the container
              #   "all" = all GPUs, or specify by index (0,1) or UUID
              #
              # NVIDIA_DRIVER_CAPABILITIES: Which driver features to expose
              #   "all" = everything (compute, graphics, video, utility)
              #   For transcoding, we specifically need "video" for NVENC/NVDEC
              #   Using "all" is simpler and ensures nothing is missing
              #
              # Source: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html
              NVIDIA_VISIBLE_DEVICES: all
              NVIDIA_DRIVER_CAPABILITIES: all
            probes:
              liveness: &probes
                enabled: true
                custom: true
                spec:
                  httpGet:
                    path: /health
                    port: &port 8096
                  initialDelaySeconds: 0
                  periodSeconds: 10
                  timeoutSeconds: 1
                  failureThreshold: 5
              readiness: *probes
              startup:
                enabled: true
                spec:
                  failureThreshold: 30
                  periodSeconds: 10
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              capabilities: {drop: ["ALL"]}
            resources:
              requests:
                cpu: 4
                memory: 6Gi
                # ============================================================
                # GPU Resource Request
                # ============================================================
                # This tells Kubernetes to allocate 1 GPU to this pod.
                # The nvidia-device-plugin handles the actual allocation.
                # The pod won't start if no GPU is available.
                nvidia.com/gpu: 1
              limits:
                cpu: 16
                memory: 12Gi
                # Limits should match requests for GPUs (they're not burstable)
                nvidia.com/gpu: 1

    defaultPodOptions:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        fsGroupChangePolicy: OnRootMismatch
      # ============================================================
      # Node Selection
      # ============================================================
      # Ensure Jellyfin only schedules on GPU-enabled nodes.
      # This matches the label we added in Phase 2.
      nodeSelector:
        drmoo.io/gpu: nvidia-t4
      # ============================================================
      # Tolerations
      # ============================================================
      # If GPU nodes have taints (to prevent non-GPU workloads from scheduling),
      # this toleration allows Jellyfin to schedule anyway.
      # The GPU Operator may add this taint automatically.
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule

    # ... rest of config unchanged (service, route, persistence) ...
    service:
      app:
        ports:
          http:
            port: *port
    route:
      app:
        annotations:
          gethomepage.dev/enabled: "true"
          gethomepage.dev/description: Media server
          gethomepage.dev/group: Home
          gethomepage.dev/icon: jellyfin
          gethomepage.dev/app: jellyfin
          gethomepage.dev/name: Jellyfin
          gethomepage.dev/instance: homepage-internal
          gethomepage.dev/widget.type: "jellyfin"
          gethomepage.dev/widget.url: "https://jellyfin.drmoo.io"
          gethomepage.dev/widget.key: "f58cd19c3e6749f585f580fb11d7d180"
        hostnames:
          - "{{ .Release.Name }}.drmoo.io"
        parentRefs:
          - name: envoy-internal
            namespace: networking
            sectionName: https
      external:
        annotations:
          gethomepage.dev/enabled: "true"
          gethomepage.dev/name: "Movies & TV"
          gethomepage.dev/description: "Stream movies and TV shows"
          gethomepage.dev/group: "Media"
          gethomepage.dev/icon: "mdi-filmstrip"
          gethomepage.dev/app: "jellyfin"
          gethomepage.dev/instance: "homepage-external"
          gethomepage.dev/widget.type: "jellyfin"
          gethomepage.dev/widget.url: "https://movies.drmoo.io"
          gethomepage.dev/widget.key: "f58cd19c3e6749f585f580fb11d7d180"
        hostnames:
          - "movies.drmoo.io"
          - "moovies.drmoo.io"
        parentRefs:
          - name: envoy-external
            namespace: networking
            sectionName: https
    persistence:
      config:
        existingClaim: "{{ .Release.Name }}"
        globalMounts:
          - path: /config
      config-cache:
        existingClaim: "{{ .Release.Name }}-cache"
        globalMounts:
          - path: /config/metadata
      media:
        type: nfs
        server: 192.168.8.248
        path: /mnt/vault/media
        globalMounts:
          - path: /data
            readOnly: true
      tmpfs:
        type: emptyDir
        advancedMounts:
          jellyfin:
            app:
              - path: /cache
                subPath: cache
              - path: /config/log
                subPath: log
              - path: /tmp
                subPath: tmp
```

---

### 5.2 Jellyfin UI Configuration

**What**: Configure Jellyfin's transcoding settings to use NVIDIA hardware acceleration.

**Why**: Even with the GPU available to the container, Jellyfin defaults to software transcoding. We need to explicitly enable NVENC (encoder) and NVDEC (decoder) in the Jellyfin settings.

> **Source**: [Jellyfin Transcoding Configuration](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia/)

After Jellyfin is running with GPU access:

1. Navigate to **Dashboard** > **Playback** > **Transcoding**

2. Set **Hardware acceleration** to `Nvidia NVENC`

3. Enable hardware decoding for supported codecs (Tesla T4 capabilities):
   - [x] H.264 (AVC) - Full hardware decode/encode
   - [x] HEVC (H.265) - Full hardware decode/encode
   - [x] VP9 - Hardware decode only (no encode on T4)
   - [ ] AV1 - Not supported on Turing architecture

4. Enable these options:
   - [x] **Enable hardware encoding** - Uses NVENC for output
   - [x] **Enable enhanced NVDEC decoder** - Better quality decoding
   - [x] **Enable hardware decoding for all compatible media**
   - [x] **Prefer OS native DXVA or VA-API hardware decoders** - Not applicable for NVDEC, leave default

5. Set **Transcoding thread count** to `0` (auto-detect)

6. Click **Save**

**What each setting does**:

- **NVDEC** (decoder): Decodes the source video (e.g., 4K HEVC) in hardware
- **NVENC** (encoder): Encodes the output video (e.g., 1080p H.264) in hardware
- **Enhanced NVDEC**: Uses newer decoding paths with better quality/performance

---

## Verification

### Check GPU Passthrough (Proxmox)

```bash
# On pve5 - verify VM has GPU attached
qm config 1105 | grep hostpci
# Expected: hostpci0: 0000:3b:00.0,pcie=1,rombar=1
```

### Check GPU Visibility (Talos)

```bash
# Verify NVIDIA driver is loaded
talosctl -n 192.168.8.123 read /proc/driver/nvidia/version
# Expected: NVRM version: NVIDIA UNIX x86_64 Kernel Module  550.xxx

# Check kernel messages for NVIDIA initialization
talosctl -n 192.168.8.123 dmesg | grep -i nvidia
# Expected: nvidia: module loaded, NVIDIA GPU at PCI address 0000:XX:00.0
```

### Check Kubernetes GPU Resources

```bash
# Verify node has GPU in allocatable resources
kubectl describe node moody-good | grep -A5 "Allocatable:"
# Expected: nvidia.com/gpu: 1

# Verify GPU Operator pods are running
kubectl get pods -n gpu-operator
# Expected: nvidia-device-plugin-xxx, nvidia-dcgm-exporter-xxx, etc. all Running

# Check GPU labels applied by GFD
kubectl get node moody-good -o json | jq '.metadata.labels | with_entries(select(.key | startswith("nvidia")))'
# Expected: nvidia.com/gpu.product, nvidia.com/cuda.driver.major, etc.
```

### Check Jellyfin GPU Access

```bash
# Verify Jellyfin pod has GPU allocated
kubectl describe pod -n media -l app.kubernetes.io/name=jellyfin | grep -A3 "Limits:"
# Expected: nvidia.com/gpu: 1

# Run nvidia-smi inside Jellyfin container
kubectl exec -it -n media $(kubectl get pod -n media -l app.kubernetes.io/name=jellyfin -o name) -- nvidia-smi
# Expected: Tesla T4 with memory usage, no errors

# Verify FFmpeg has NVENC support
kubectl exec -it -n media $(kubectl get pod -n media -l app.kubernetes.io/name=jellyfin -o name) -- /usr/lib/jellyfin-ffmpeg/ffmpeg -encoders 2>/dev/null | grep nvenc
# Expected: h264_nvenc, hevc_nvenc listed
```

---

## Troubleshooting

### GPU Not Visible in VM

**Symptoms**: `lspci` in VM doesn't show NVIDIA device

**Causes & Solutions**:

1. **IOMMU not enabled**: Check `dmesg | grep -i iommu` on pve5 - should show "IOMMU enabled"
2. **GPU not bound to VFIO**: Run `lspci -nnk -s <pci-addr>` on pve5 - should show "vfio-pci"
3. **Incorrect PCI address**: Verify address in Terraform matches `lspci` output
4. **Another VM using GPU**: Each GPU can only be passed to one VM at a time

### NVIDIA Modules Not Loading in Talos

**Symptoms**: `/proc/driver/nvidia/version` doesn't exist

**Causes & Solutions**:

1. **Wrong Image Factory schematic**: Regenerate with correct extensions
2. **Extension version mismatch**: Ensure nvidia-container-toolkit and nonfree-kmod-nvidia versions match
3. **Check dmesg for errors**: `talosctl dmesg | grep -i "nvidia\|error"`

### Device Plugin Not Detecting GPU

**Symptoms**: Node shows `nvidia.com/gpu: 0` in allocatable

**Causes & Solutions**:

1. **Check device plugin logs**: `kubectl logs -n gpu-operator -l app=nvidia-device-plugin`
2. **Verify NFD labeled the node**: `kubectl get node moody-good -o json | jq '.metadata.labels["feature.node.kubernetes.io/pci-10de.present"]'` should be `true`
3. **Wrong GPU Operator config**: Ensure `driver.enabled=false` and `toolkit.enabled=false`

### Jellyfin Transcoding Fails

**Symptoms**: FFmpeg errors in Jellyfin logs, "Hardware acceleration failed"

**Causes & Solutions**:

1. **GPU not allocated to pod**: Check `kubectl describe pod` for `nvidia.com/gpu` in limits
2. **Missing env vars**: Ensure `NVIDIA_VISIBLE_DEVICES` and `NVIDIA_DRIVER_CAPABILITIES` are set
3. **Wrong Jellyfin settings**: Verify "Nvidia NVENC" is selected in transcoding settings
4. **Codec not supported**: T4 doesn't support AV1 encoding, limited VP9 support

---

## Future Considerations

### Dynamic Resource Allocation (DRA)

**What**: DRA is a Kubernetes API for requesting specialized hardware resources with more flexibility than device plugins.

**Why it matters**: DRA (GA in Kubernetes 1.34) will eventually replace device plugins because it supports:

- Fine-grained resource requests (specific GPU memory amounts)
- Dynamic partitioning (MIG on A100/H100)
- Time-slicing configuration per-workload
- Better multi-tenant scenarios

**Current status**: Your cluster runs K8s 1.33.4 where DRA is beta. The NVIDIA DRA driver (`k8s-dra-driver-gpu`) is still experimental for GPU allocation. The device plugin approach used in this guide is the recommended production path for now.

**Note**: The Tesla T4 doesn't support MIG (requires Ampere+), but time-slicing via DRA would work when it's production-ready.

> **Source**: [Kubernetes DRA Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/), [NVIDIA DRA Driver](https://github.com/NVIDIA/k8s-dra-driver-gpu)

### GPU Monitoring Dashboard

The DCGM Exporter (enabled in GPU Operator) exports Prometheus metrics. Key metrics for transcoding monitoring:

| Metric | Description |
|--------|-------------|
| `DCGM_FI_DEV_GPU_UTIL` | GPU compute utilization % |
| `DCGM_FI_DEV_MEM_COPY_UTIL` | Memory bandwidth utilization % |
| `DCGM_FI_DEV_ENC_UTIL` | NVENC encoder utilization % |
| `DCGM_FI_DEV_DEC_UTIL` | NVDEC decoder utilization % |
| `DCGM_FI_DEV_FB_USED` | GPU memory used (bytes) |
| `DCGM_FI_DEV_GPU_TEMP` | GPU temperature (°C) |
| `DCGM_FI_DEV_POWER_USAGE` | Power consumption (W) |

Consider adding a Grafana dashboard once your observability stack is stable. NVIDIA provides a [reference dashboard](https://grafana.com/grafana/dashboards/12239-nvidia-dcgm-exporter-dashboard/).

---

## References

### Proxmox & Virtualization

- [Proxmox PCI Passthrough Wiki](https://pve.proxmox.com/wiki/PCI_Passthrough)
- [Proxmox Forum - GPU Passthrough Tutorial 2025](https://forum.proxmox.com/threads/2025-proxmox-pcie-gpu-passthrough-with-nvidia.169543/)
- [Linux VFIO Documentation](https://www.kernel.org/doc/html/latest/driver-api/vfio.html)

### Talos Linux

- [Talos NVIDIA GPU Documentation](https://docs.siderolabs.com/talos/v1.9/configure-your-talos-cluster/hardware-and-drivers/nvidia-gpu-proprietary)
- [Talos Image Factory](https://factory.talos.dev/)
- [Sidero Labs Extensions Repository](https://github.com/siderolabs/extensions)
- [AI Workloads on Talos Linux Blog](https://www.siderolabs.com/blog/ai-workloads-on-talos-linux/)

### NVIDIA GPU Operator

- [GPU Operator Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html)
- [GPU Operator GitHub](https://github.com/NVIDIA/gpu-operator)
- [GPU Operator Helm Values Reference](https://github.com/NVIDIA/gpu-operator/blob/master/deployments/gpu-operator/values.yaml)
- [NVIDIA Device Plugin](https://github.com/NVIDIA/k8s-device-plugin)
- [GPU Feature Discovery](https://github.com/NVIDIA/gpu-feature-discovery)
- [DCGM Exporter](https://github.com/NVIDIA/dcgm-exporter)
- [GPU Sharing in Kubernetes](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html)
- [Time-Slicing GPUs](https://docs.nvidia.com/datacenter/cloud-native/k8s-device-plugin/latest/time-slicing.html)

### Jellyfin

- [Jellyfin NVIDIA Hardware Acceleration](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia/)
- [Jellyfin Hardware Selection Guide](https://jellyfin.org/docs/general/administration/hardware-selection/)

### Kubernetes

- [Dynamic Resource Allocation](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [NVIDIA DRA Driver for GPUs](https://github.com/NVIDIA/k8s-dra-driver-gpu)

### Hardware

- [NVIDIA Tesla T4 Specifications](https://www.nvidia.com/en-us/data-center/tesla-t4/)
- [NVIDIA Video Codec SDK (NVENC/NVDEC)](https://developer.nvidia.com/nvidia-video-codec-sdk)
- [NVIDIA GPU Support Matrix](https://developer.nvidia.com/video-encode-and-decode-gpu-support-matrix-new)
