<!-- markdownlint-disable MD041 -->
<p align="center">
  <img src="./docs/repo.png" alt="diagram" width="250" height="250">
</p>

<div align="center">

[![GitHub Stars](https://img.shields.io/github/stars/ProfMoo/home.svg?color=3498DB)](https://github.com/ProfMoo/home/stargazers) [![GitHub last commit](https://img.shields.io/github/last-commit/ProfMoo/home?color=purple&style=flat-square)](https://github.com/ProfMoo/home/commits/main)

</div>

# [Moo's Pasture](https://github.com/ProfMoo/home)

> A [onedr0p home-ops](https://github.com/onedr0p/home-ops) inspired project, with some [ProfMoo](https://github.com/ProfMoo) sprinkled in.

## Overview

A mono-repository for my homelab Kubernetes cluster. I strictly adhere to Infrastructure as Code (IaC) and GitOps practices using tools like Kubernetes, Terraform, Talos, Flux, Renovate, and GitHub Actions.

<p align="center">
  <img src="./docs/diagram.drawio.png" alt="diagram" width="500" height="500">
</p>

### Infrastructure

I use [Talos](https://github.com/siderolabs/talos), [Terraform](https://github.com/hashicorp/terraform), and [Proxmox](https://github.com/proxmox) to spin up Kubernetes in a GitOps fashion in [this directory](./infrastructure).

Proxmox, a VM-management technology, is used to spin up VMs in the Proxmox cluster. These raw VMs are bootstrapped via Terraform with Talos configuration(s) that create a functional Kubernetes cluster with the initial cluster components (such as Flux) already deployed.

### Kubernetes

I configure Kubernetes with GitOps via [Flux](https://github.com/fluxcd/flux2). The Flux controllers scans the [kubernetes](./kubernetes/) directory for `kustomization` files to apply to the cluster.

## Inspirations

The [home-operations Discord group](https://discord.gg/home-operations) has been a huge inspiration for this repository. In particular, the repos by [onedr0p](https://github.com/onedr0p/home-ops), [bjw-s](https://github.com/bjw-s/home-ops), and [buroa](https://github.com/buroa/k8s-gitops).

One major change from the typical home-operations setup is that I configured Kubernetes inside VMs instead of bare-metal. For that modification, I drew great inspiration from the two repos [here](https://github.com/zimmertr/TJs-Kubernetes-Service) and [here](https://github.com/kubebn/talos-proxmox-kaas).

## Local Dev

Some binaries needed for local development: `talosctl` `kubectl` `flux` `terraform` `docker` `yamlfmt` `markdownlint-cli2` `hadolint` `shfmt`, `minijinja-cli`
