#!/bin/zsh

terraform output -raw talosconfig >~/.talosconfig
terraform output -raw kubeconfig >~/.kubeconfig
