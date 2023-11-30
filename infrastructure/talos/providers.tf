terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.4"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.0"
    }
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
  }

  backend "s3" {
    bucket = "sobrien-home"
    key    = "infrastructure"
    region = "us-east-1"
    # To authenticate to access the state (not the actual terraform commands)
    shared_credentials_file = "./aws-credentials"
  }
}

provider "proxmox" {
  endpoint  = "https://192.168.1.64:8006/api2/json"
  api_token = "root@pam!tjs-test-2=fd03ad68-f6fd-4610-8dc2-4b6af00e7407"
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}

provider "talos" {}

provider "unifi" {
  username = "DrMoo"                               # optionally use UNIFI_USERNAME env var
  password = "werpPF2$nPcR68Z5hsiD"                # optionally use UNIFI_PASSWORD env var
  api_url  = "https://192.168.1.1/network/default" # optionally use UNIFI_API env var

  # you may need to allow insecure TLS communications unless you have configured
  # certificates for your controller
  allow_insecure = true # optionally use UNIFI_INSECURE env var

  # if you are not configuring the default site, you can change the site
  # site = "foo" or optionally use UNIFI_SITE env var
}
