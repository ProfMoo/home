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
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
  }

  backend "s3" {
    bucket = "sobrien-home"
    key    = "infrastructure"
    region = "us-east-1"
    # To authenticate access to state (does not authenticate the actual terraform commands)
    shared_credentials_file = "./aws-credentials"
  }
}

provider "sops" {}

data "sops_file" "provider_credentials" {
  source_file = "demo-secret.enc.json"
}

output "db-password" {
  # Access the password variable that is under db via the terraform map of data
  value = data.sops_file.provider_credentials["db.password"]
}

provider "proxmox" {
  endpoint  = "https://192.168.1.64:8006/api2/json"
  api_token = data.sops_file.provider_credentials["PROXMOX_TOKEN"]
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}

provider "talos" {}

provider "unifi" {
  username = "DrMoo"                                               # optionally use UNIFI_USERNAME env var
  password = data.sops_file.provider_credentials["UNIFI_PASSWORD"] # optionally use UNIFI_PASSWORD env var
  api_url  = "https://192.168.1.1/network/default"                 # optionally use UNIFI_API env var

  # you may need to allow insecure TLS communications unless you have configured
  # certificates for your controller
  allow_insecure = true # optionally use UNIFI_INSECURE env var

  # if you are not configuring the default site, you can change the site
  # site = "foo" or optionally use UNIFI_SITE env var
}
