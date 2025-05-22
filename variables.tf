# ce_cherbao_module2.5/variables.tf

variable "region" {
  description = "AWS Region in Singapore"
  type        = string
  default     = "ap-southeast-1"
}

variable "azs" {
  description = "List of the AZ in Singapore"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "vpc_cidr" {
  description = "CIDR Block for the VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR Block for public subnet"
  type        = string
  default     = "172.16.10.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR Block for private subnet"
  type        = string
  default     = "172.16.20.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR Block for database subnet"
  type        = string
  default     = "172.16.30.0/24"
}

variable "enable_nat_gateway" {
  description = "Enable or disable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway across all AZs"
  type        = bool
  default     = true
}

variable "ssh_key_name" {
  description = "SSH Key name to access EC2 instances"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into EC2"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_igw" {
  description = "Create an Internet Gateway"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC"
  type        = bool
  default     = true
}

# Create Variables for DynamoDB
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "ce10-laoniu-table"
}

variable "dynamodb_env" {
  description = "Environment tag for DynamoDB"
  type        = string
  default     = "dev"
}
