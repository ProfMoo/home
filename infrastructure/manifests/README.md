# Manifests

Directory that houses the kubernetes manifests that should be applied during cluster and node creation. Typically, kubernetes manifests are installed via flux, but some manifests are best applied during the initial cluster/node bootstrapping phase. For some examples:

* Desired CNI configuration
* Flux configuration (to enable other manifests to be applied)

kubernetes = {
  podSubnets              = "10.244.0.0/16"       # pod subnet
  serviceSubnets          = "10.96.0.0/12"        # svc subnet
  domain                  = "cluster.local"       # cluster local kube-dns svc.cluster.local
  ipv4_vip                = "10.1.1.20"           # vip ip address
  apiDomain               = "api.cluster.local"   # cluster endpoint
  talos-version           = "v1.4.1"              # talos installer version
  metallb_l2_addressrange = "10.1.1.30-10.1.1.35" # metallb L2 configuration ip range
  registry-endpoint       = "reg.weecodelab.nl"   # set registry url for cache image pull

# FLUX ConfigMap settings

  sidero-endpoint = "10.1.1.30"
  cluster-0-vip   = "10.1.1.40"
}
