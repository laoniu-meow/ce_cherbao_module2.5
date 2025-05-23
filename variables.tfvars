# ce_cherbao_module2.5/variables.tfvars

region              = "ap-southeast-1"
vpc_cidr            = "172.16.0.0/16"
public_subnet_cidr  = "172.16.10.0/24"
private_subnet_cidr = "172.16.20.0/24"
database_subnet_cidr = "172.16.30.0/24"
ssh_key_name        = "laoniu-pem.pem"
allowed_ssh_cidr    = ["0.0.0.0/0"]
enable_nat_gateway  = true
single_nat_gateway  = true
create_igw          = true
enable_dns_hostnames = true
