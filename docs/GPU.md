# NVIDIA GPU Support for Kubernetes Cluster

This guide documents how to add NVIDIA Tesla T4 GPU support to the homelab Kubernetes cluster for hardware-accelerated transcoding in Jellyfin.

## Overview

| Component | Details |
| ----------- | --------- |
| GPU | NVIDIA Tesla T4 16GB GDDR6 (Turing architecture) |
| Proxmox Host | pve5 (SuperMicro SYS-6028U-TR4T+) |
| Target VM | moody-good (50 vCPU, 238GB RAM) |
| Primary Use Case | Jellyfin NVENC/NVDEC hardware transcoding |

Current validated target for this repo:

- Talos: `v1.13.x`
- Kubernetes: `v1.37.0`
- NVIDIA GPU Operator: `v26.7.0`
- NVIDIA DRA Driver for GPUs: `v0.5.0` via GPU Operator

NVIDIA GPU Operator `v26.7.0` supports Kubernetes `1.33-1.37`. `v25.10.x` and older are end-of-support, so do not use older chart versions from stale examples.

Before applying Talos machine config, verify your Talos release supports the selected Kubernetes control plane and kubelet images.

This guide uses Kubernetes Dynamic Resource Allocation (DRA) as the only GPU API. DRA is the newer Kubernetes hardware resource model and is the right fit for Kubernetes `1.37.0`.

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
│  Containerd: CDI-capable NVIDIA runtime                      │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Kubernetes                                                  │
│                                                             │
│  ┌──────────────────┐     ┌─────────────────────────────┐  │
│  │ GPU Operator     │     │        GPU Workloads        │  │
│  │ (GPUCluster,     │     │  ResourceClaim / DRA        │  │
│  │  DRA driver,     │     ├─────────────────────────────┤  │
│  │  DCGM)           │────▶│ Jellyfin     gpu.nvidia.com │  │
│  │                  │     │ Ollama       gpu.nvidia.com │  │
│  │ DeviceClasses:   │     │ Frigate      gpu.nvidia.com │  │
│  │ gpu.nvidia.com   │     │                             │  │
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

### 1.1 Enable IOMMU in GRUB (DONE)

**What**: IOMMU (Input-Output Memory Management Unit) is a hardware feature that allows the hypervisor to control which memory regions a device can access.

**Why**: Without IOMMU, a passed-through device could read/write any memory address, including the hypervisor's memory or other VMs' memory. IOMMU creates isolated memory domains, making passthrough safe. Intel calls their implementation "VT-d" (Virtualization Technology for Directed I/O).

The `iommu=pt` parameter enables "passthrough mode" which improves performance by skipping IOMMU translation for devices that don't need isolation (like the CPU's own memory access).

> **Source**: [Intel VT-d Documentation](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html), [Proxmox PCI Passthrough Guide](https://pve.proxmox.com/wiki/PCI_Passthrough#Enable_the_IOMMU)

SSH to pve5 and edit `/etc/default/grub`:

```bash
# For Intel CPU (SuperMicro uses Intel Xeons)
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
```

Update GRUB and reboot:

```bash
update-grub
reboot
```

---

### 1.2 Load VFIO Modules (DONE)

**What**: VFIO (Virtual Function I/O) is a Linux kernel framework that provides safe, non-privileged userspace drivers. It's the mechanism that allows QEMU/KVM to give VMs direct access to PCI devices.

**Why**: These kernel modules must be loaded for PCI passthrough to work:

- `vfio`: Core VFIO framework
- `vfio_iommu_type1`: IOMMU driver for x86 systems with Intel VT-d or AMD-Vi
- `vfio_pci`: Allows binding PCI devices to VFIO instead of their native drivers
- `vfio_virqfd`: Enables interrupt forwarding to VMs

> **Source**: [Linux Kernel VFIO Documentation](https://www.kernel.org/doc/html/latest/driver-api/vfio.html)

Add to `/etc/modules`:

```text
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

---

### 1.3 Blacklist NVIDIA Drivers on Host (DONE)

**What**: Prevent the Proxmox host from loading any NVIDIA drivers.

**Why**: If the host loads NVIDIA drivers, they will "claim" the GPU and bind to it. A device can only be bound to one driver at a time. By blacklisting NVIDIA drivers, we ensure the GPU remains unbound so VFIO can claim it instead. The `nouveau` driver is the open-source NVIDIA driver that Linux loads by default.

> **Source**: [Proxmox Forum - GPU Passthrough Tutorial](https://forum.proxmox.com/threads/pci-gpu-passthrough-on-proxmox-ve-8-installation-and-configuration.130218/)

Create `/etc/modprobe.d/blacklist-nvidia.conf`:

```text
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
blacklist nvidiafb
```

---

### 1.4 Bind GPU to VFIO (DONE)

**What**: Tell the kernel to bind the GPU to the `vfio-pci` driver at boot time.

**Why**: By default, Linux would try to find and load an appropriate driver for the GPU. By specifying the GPU's vendor:device ID (`10de:1eb8` = NVIDIA Tesla T4), we tell the kernel "always use vfio-pci for this device." This ensures the GPU is ready for passthrough before any VM starts.

> **Source**: [VFIO Tips and Tricks](https://vfio.blogspot.com/2015/05/vfio-gpu-how-to-series-part-3-host.html)

Find the GPU's PCI address and device IDs:

```bash
lspci -nn | grep -i nvidia
# Example output: 3b:00.0 3D controller [0302]: NVIDIA Corporation TU104GL [Tesla T4] [10de:1eb8] (rev a1)
```

Create `/etc/modprobe.d/vfio.conf`:

```text
options vfio-pci ids=10de:1eb8
```

Update initramfs and reboot:

```bash
update-initramfs -u -k all
reboot
```

---

### 1.5 Verify VFIO Binding (DONE)

**What**: Confirm the GPU is bound to vfio-pci and ready for passthrough.

**Why**: This verification step ensures all previous configuration took effect. If the GPU shows a different driver (like `nouveau` or `nvidia`), passthrough will fail.

```bash
lspci -nnk -s 3b:00.0
# Should show: Kernel driver in use: vfio-pci
```

---

## Phase 2: OpenTofu Changes

### Why This Phase is Needed

Your infrastructure follows IaC principles using OpenTofu to provision Proxmox VMs. To pass the GPU through to moody-good, we need to:

1. Add the `hostpci` configuration to the VM definition
2. Keep this change version-controlled and reproducible
3. Allow future GPU nodes to be easily configured

> **Source**: [Proxmox OpenTofu Provider - hostpci](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#hostpci)

---

### 2.1 Add PCI Passthrough to Node Module

**What**: Extend the node OpenTofu module to support PCI device passthrough.

**Why**: The current `infrastructure/modules/node/proxmox_vm.tf` doesn't have a `hostpci` block. Adding this as a variable with a default empty list means existing nodes are unaffected, while GPU nodes can specify devices to pass through.

Update `infrastructure/modules/node/variables.tf`:

```hcl
variable "pci_devices" {
  type = list(object({
    mapping = string # Proxmox cluster-wide PCI resource mapping name (e.g., "tesla-t4")
    pcie    = bool   # Use PCIe passthrough mode
    rombar  = bool   # Enable ROM BAR
    xvga    = bool   # Primary GPU (usually false for compute GPUs)
  }))
  description = "PCI devices to pass through to the VM (e.g., GPUs)"
  default     = []
}
```

**Parameter explanations**:

- `mapping`: Proxmox Datacenter PCI resource mapping name. This repo uses mappings because the Proxmox provider runs with API token auth; raw PCI IDs require root username/password auth in this provider.
- `pcie`: Enables PCIe mode vs legacy PCI. PCIe provides better performance and is required for modern GPUs
- `rombar`: Exposes the device's option ROM to the VM. Required for some devices to initialize properly
- `xvga`: Marks this as the primary display adapter. Set `false` for compute GPUs like the T4 (they have no display outputs)

> **Source**: [Proxmox VM hostpci Documentation](https://pve.proxmox.com/wiki/Qemu/KVM_Virtual_Machines#qm_pci_passthrough)

Update `infrastructure/modules/node/proxmox_vm.tf`:

```hcl
resource "proxmox_virtual_environment_vm" "talos_node" {
  # ... existing configuration ...

  # GPU passthrough
  dynamic "hostpci" {
    for_each = var.pci_devices
    content {
      device  = "hostpci${pci.key}"
      mapping = pci.value.mapping
      pcie    = pci.value.pcie
      rombar  = pci.value.rombar
      xvga    = pci.value.xvga
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

      talos_version      = "1.13.0" # Use your exact Talos 1.13 patch version
      kubernetes_version = "1.37.0"

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

> **Source**: [Talos Linux NVIDIA GPU Documentation](https://docs.siderolabs.com/talos/latest/configure-your-talos-cluster/hardware-and-drivers/nvidia-gpu-proprietary/)

---

### 3.1 Generate New Image Factory Schematic

**What**: Create a custom Talos image that includes NVIDIA drivers and container toolkit.

**Why**: The [Talos Image Factory](https://factory.talos.dev/) generates custom Talos images with specific extensions. Your current schematic (`dc7b152...`) doesn't include NVIDIA extensions. A new schematic will include:

- `nonfree-kmod-nvidia-production`: The NVIDIA proprietary kernel modules (nvidia.ko, nvidia-uvm.ko, etc.). These are required for the GPU to function.
- `nvidia-container-toolkit-production`: Enables containers to access the GPU. This includes `nvidia-container-runtime` which wraps containerd to inject GPU device access into containers.

> **Source**: [Talos Image Factory](https://factory.talos.dev/), [Sidero Labs Extensions Repository](https://github.com/siderolabs/extensions)

**Steps**:

1. Go to [Talos Image Factory](https://factory.talos.dev/)
2. Select your Talos `v1.13.x` patch version (matching your current version)
3. Add extensions:
   - Search for `nvidia` and select both:
     - `siderolabs/nonfree-kmod-nvidia-production`
     - `siderolabs/nvidia-container-toolkit-production`
4. Keep any existing extensions from your current schematic (e.g., `qemu-guest-agent`)
5. Generate the schematic and copy the new ID

**Important version matching**: The NVIDIA driver version in `nonfree-kmod-nvidia` must match the version expected by `nvidia-container-toolkit`. The Image Factory helps here, but verify both extension tags use compatible NVIDIA driver versions. Talos published NVIDIA drivers are tied to a specific Talos release, so update the extension set whenever Talos is upgraded.

> **Source**: [Talos Extensions Compatibility](https://github.com/siderolabs/extensions#nvidia-gpu-support)

---

### 3.2 Create GPU-Specific Worker Config

**What**: Update the Talos machine configuration for moody-good to use the new NVIDIA-enabled image and configure containerd.

**Why**: Two critical changes are needed:

1. **New install image**: Points to the Image Factory schematic with NVIDIA extensions
2. **Containerd runtime configuration**: DRA requires a CDI-capable runtime path so the NVIDIA DRA kubelet plugin can inject allocated devices into pods.

> **Source**: [Talos NVIDIA Configuration](https://docs.siderolabs.com/talos/latest/configure-your-talos-cluster/hardware-and-drivers/nvidia-gpu-proprietary/#deploying-nvidia-gpu-operator)

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
    image: factory.talos.dev/installer/<NEW-SCHEMATIC-ID>:v1.13.0 # Use your exact Talos 1.13 patch version
    disk: /dev/sda
    wipe: false
  kubelet:
    image: ghcr.io/siderolabs/kubelet:v1.37.0
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
    # NEW: Configure containerd for NVIDIA runtime support.
    # DRA uses CDI for device injection; the NVIDIA runtime handler remains useful
    # for validation/debug pods that set runtimeClassName: nvidia.
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
      # NVIDIA modules are provided by the nonfree-kmod-nvidia extension,
      # but Talos docs now load them explicitly here.
      - name: nvidia
      - name: nvidia_uvm
      - name: nvidia_drm
      - name: nvidia_modeset
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

> **Source**: [Talos Configuration Application](https://docs.siderolabs.com/talos/latest/configure-your-talos-cluster/system-configuration/editing-machine-configuration/)

---

## Phase 4: Kubernetes GPU Operator with DRA

### Why This Phase is Needed

The NVIDIA GPU Operator automates GPU integration with Kubernetes. This guide uses the DRA-managed workflow introduced by NVIDIA GPU Operator `v26.7.0`:

1. **GPUCluster**: Cluster-scoped singleton that tells the Operator to deploy DRA components.
2. **DRA Driver for NVIDIA GPUs**: Publishes GPUs through Kubernetes `ResourceSlice` and `DeviceClass` APIs.
3. **DCGM Exporter**: Exports Prometheus GPU metrics.
4. **Validator**: Verifies that DRA allocation works.

On Talos, drivers and toolkit are provided by system extensions from Phase 3. Keep GPU Operator driver installation disabled.

Deploy only the DRA `GPUCluster` workflow. Do not mix it with another GPU allocation stack.

> **Source**: [NVIDIA GPU Operator DRA Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/dra-intro-install.html), [Kubernetes Dynamic Resource Allocation](https://kubernetes.io/docs/concepts/resource-management/dynamic-resource-allocation/)

---

### 4.1 Create Flux Deployment Structure

**What**: Create the directory structure matching your existing GitOps patterns.

**Why**: Consistency with your existing app deployments (like rook-ceph, reloader, etc.) makes the codebase maintainable and follows the established Flux CD patterns.

```text
kubernetes/homelab/apps/base/nvidia-gpu-operator/
├── ks.yaml                      # Flux Kustomization - tells Flux what to deploy
└── app/
    ├── kustomization.yaml       # Kustomize resources list
    ├── namespace.yaml           # GPU Operator namespace with PSA labels
    ├── oci-repository.yaml      # Helm chart source
    └── helm-release.yaml        # Helm values and DRA configuration
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

- DRA kubelet plugin needs access to `/dev/nvidia*` devices
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

**Why**: NVIDIA publishes the GPU Operator Helm chart as an OCI artifact. This matches your existing Flux `OCIRepository` pattern. Version `v26.7.0` is the current stable release and supports Kubernetes `1.33-1.37`; `v25.10.x` and older are end-of-support.

> **Source**: [NVIDIA GPU Operator Releases](https://github.com/NVIDIA/gpu-operator/releases)

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: nvidia-gpu-operator
  namespace: gpu-operator
spec:
  interval: 12h
  layerSelector:
    mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
    operation: copy
  url: oci://nvcr.io/nvidia/cloud-native-charts/gpu-operator
  ref:
    tag: v26.7.0
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
```

---

### 4.6 HelmRelease (app/helm-release.yaml)

**What**: Configure the GPU Operator Helm chart for the DRA `GPUCluster` workflow.

**Why**: This is the most critical configuration. The key insight is:

- **`driver.enabled: false`**: Talos provides drivers via the `nonfree-kmod-nvidia` extension. The GPU Operator's driver installer expects a standard Linux filesystem with `/bin/sh` - Talos doesn't have this.
- **`toolkit.enabled: false`**: Talos provides the toolkit via the `nvidia-container-toolkit` extension. Same reason as above.
- **`clusterPolicy.deployCR: false`**: Required so the chart creates only DRA resources.
- **`gpuCluster.deployCR: true`**: Create the DRA `GPUCluster` resource.

The components we do enable provide the Kubernetes DRA integration layer.

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

    # Talos places host-installed NVIDIA driver files under /usr/local.
    # Upstream Talos docs require this override when using GPU Operator.
    hostPaths:
      driverInstallDir: /usr/local

    # ============================================================
    # DRA: Create GPUCluster only
    # ============================================================
    clusterPolicy:
      deployCR: false
    gpuCluster:
      deployCR: true

    # ============================================================
    # DRA Driver - REQUIRED
    # ============================================================
    # Full GPU allocation is GA in NVIDIA DRA Driver v0.5.0.
    # ComputeDomain is for multi-node NVLink systems; disable for Tesla T4.
    draDriver:
      version: v0.5.0
      computeDomains:
        enabled: false

    # ============================================================
    # DCGM Exporter - RECOMMENDED for observability
    # ============================================================
    dcgmExporter:
      enabled: true
      serviceMonitor:
        enabled: true  # Auto-creates ServiceMonitor for Prometheus Operator

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
```

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

### 5.1 Add DRA ResourceClaimTemplate

**What**: Create a DRA `ResourceClaimTemplate` in Jellyfin's namespace.

**Why**: With DRA, pods do not request GPUs through `limits`. Pods reference a claim, and Kubernetes allocates a matching device from the `gpu.nvidia.com` `DeviceClass`.

Create `kubernetes/homelab/apps/media/jellyfin/app/gpu-resource-claim-template.yaml` and add it to Jellyfin's `kustomization.yaml`:

```yaml
---
apiVersion: resource.k8s.io/v1
kind: ResourceClaimTemplate
metadata:
  name: jellyfin-gpu
spec:
  spec:
    devices:
      requests:
        - name: gpu
          exactly:
            deviceClassName: gpu.nvidia.com
            selectors:
              - cel:
                  expression: |
                    device.attributes['gpu.nvidia.com'].productName.lowerAscii().matches('^.*t4.*$')
```

### 5.2 Update Jellyfin Pod Spec

**What**: Add the DRA claim to Jellyfin's pod spec and container resources.

**Why**: DRA has two links: pod-level `resourceClaims` points at the template, and container-level `resources.claims` says which container can use the allocated device.

The rendered Jellyfin pod template needs these fields:

```yaml
spec:
  resourceClaims:
    - name: gpu
      resourceClaimTemplateName: jellyfin-gpu
  containers:
    - name: app
      resources:
        claims:
          - name: gpu
```

Keep Jellyfin's normal CPU/memory requests and limits. Do not add GPU `requests` or `limits`.

If the current bjw-s `app-template` values cannot express `spec.resourceClaims` and `resources.claims`, add a Kustomize patch against the rendered Deployment/StatefulSet rather than falling back to extended resources.

Keep scheduling constrained to the GPU node:

```yaml
nodeSelector:
  drmoo.io/gpu: nvidia-t4
```

---

### 5.3 Jellyfin UI Configuration

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
# Verify GPU Operator pods are running.
kubectl get pods -n gpu-operator
# Expected: nvidia-dra-driver-kubelet-plugin, nvidia-dra-validator,
# nvidia-dcgm-exporter-dra, and gpu-operator pods Running/Completed.

# Verify DRA GPUCluster is ready.
kubectl get gpucluster gpu-cluster
# Expected: STATUS ready

# Verify DRA DeviceClass exists.
kubectl get deviceclass gpu.nvidia.com

# Verify DRA ResourceSlice publishes the GPU.
kubectl get resourceslice
kubectl get resourceslice -o yaml | grep -i "productName\|Tesla\|T4"
```

### Check DRA Claim Allocation

```bash
# Verify Jellyfin claim was created from the template.
kubectl get resourceclaim -n media

# Inspect allocation state and selected device.
kubectl get resourceclaim -n media -o yaml | grep -i "allocated\|device\|driver\|gpu.nvidia.com"
```

### Check Jellyfin GPU Access

```bash
# Verify Jellyfin pod references the DRA claim.
kubectl get pod -n media -l app.kubernetes.io/name=jellyfin -o yaml | grep -i "resourceClaims\|jellyfin-gpu\|claims:"

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
3. **Incorrect PCI address**: Verify address in OpenTofu matches `lspci` output
4. **Another VM using GPU**: Each GPU can only be passed to one VM at a time

### NVIDIA Modules Not Loading in Talos

**Symptoms**: `/proc/driver/nvidia/version` doesn't exist

**Causes & Solutions**:

1. **Wrong Image Factory schematic**: Regenerate with correct extensions
2. **Extension version mismatch**: Ensure nvidia-container-toolkit and nonfree-kmod-nvidia versions match
3. **Check dmesg for errors**: `talosctl dmesg | grep -i "nvidia\|error"`

### DRA Driver Not Publishing GPU

**Symptoms**: `kubectl get resourceslice` does not show `gpu.nvidia.com` resources.

**Causes & Solutions**:

1. **Check GPUCluster**: `kubectl describe gpucluster gpu-cluster`
2. **Check DRA pods**: `kubectl get pods -n gpu-operator | grep dra`
3. **Check DRA logs**: `kubectl logs -n gpu-operator -l app=nvidia-dra-driver-kubelet-plugin`
4. **Wrong GPU Operator mode**: Ensure `clusterPolicy.deployCR=false` and `gpuCluster.deployCR=true`
5. **Driver too old**: NVIDIA DRA workflow requires NVIDIA driver `580+`

### Jellyfin Transcoding Fails

**Symptoms**: FFmpeg errors in Jellyfin logs, "Hardware acceleration failed"

**Causes & Solutions**:

1. **GPU not allocated to pod**: Check `kubectl describe resourceclaim -n media`
2. **Pod not wired to claim**: Check rendered pod has both `spec.resourceClaims` and container `resources.claims`
3. **Wrong Jellyfin settings**: Verify "Nvidia NVENC" is selected in transcoding settings
4. **Codec not supported**: T4 doesn't support AV1 encoding, limited VP9 support

### GPU Memory Exhaustion (OOM)

**Symptoms**: CUDA out of memory errors, pods crashing with GPU memory errors

**Causes & Solutions**:

1. **Too many concurrent GPU workloads**: A Tesla T4 has 16GB VRAM. With full-GPU DRA allocation, schedule one workload per GPU unless intentionally sharing one claim inside one pod.
2. **Large LLM models**: Ollama with 13B+ models may consume 8-10GB. Use smaller/quantized models or avoid colocating GPU-heavy workloads.

3. **Monitor memory usage**:

   ```bash
   kubectl exec -it -n media $(kubectl get pod -n media -l app.kubernetes.io/name=jellyfin -o name) -- nvidia-smi
   ```

---

## Future Considerations

### GPU Monitoring Dashboard

The DCGM Exporter (enabled in GPU Operator) exports Prometheus metrics. Key metrics for transcoding monitoring:

| Metric | Description |
| -------- | ------------- |
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

- [Talos NVIDIA GPU Documentation](https://docs.siderolabs.com/talos/latest/configure-your-talos-cluster/hardware-and-drivers/nvidia-gpu-proprietary)
- [Talos Image Factory](https://factory.talos.dev/)
- [Sidero Labs Extensions Repository](https://github.com/siderolabs/extensions)
- [AI Workloads on Talos Linux Blog](https://www.siderolabs.com/blog/ai-workloads-on-talos-linux/)

### NVIDIA GPU Operator

- [GPU Operator Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html)
- [GPU Operator DRA Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/dra-intro-install.html)
- [GPU Operator GitHub](https://github.com/NVIDIA/gpu-operator)
- [GPU Operator Helm Values Reference](https://github.com/NVIDIA/gpu-operator/blob/master/deployments/gpu-operator/values.yaml)
- [DCGM Exporter](https://github.com/NVIDIA/dcgm-exporter)

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

---

## Implementation

```sh
> lspci -nn | grep -i nvidia
82:00.0 3D controller [0302]: NVIDIA Corporation TU104GL [Tesla T4] [10de:1eb8] (rev a1)
```

```sh
82:00.0 3D controller [0302]: NVIDIA Corporation TU104GL [Tesla T4] [10de:1eb8] (rev a1)
 Subsystem: NVIDIA Corporation TU104GL [Tesla T4] [10de:12a2]
 Kernel driver in use: vfio-pci
 Kernel modules: nvidiafb, nouveau
```
