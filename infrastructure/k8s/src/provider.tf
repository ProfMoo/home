terraform {
  required_version = ">= 1.6"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
  backend "s3" {
    bucket = "sobrien-home"
    key    = "virtualization"
    region = "us-east-1"
    # To authenticate to access the state (not the actual terraform commands)
    shared_credentials_file = "./aws-credentials"
  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = "https://192.168.1.64:8006/api2/json"
  pm_user         = "root@pam"
  pm_password     = "admin"
}
