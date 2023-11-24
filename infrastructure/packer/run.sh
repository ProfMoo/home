packer init ./ubuntu-server-jammy.pkr.hcl
packer build -var-file='credentials.pkr.hcl' ./ubuntu-server-jammy.pkr.hcl
