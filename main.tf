# ce_cherbao_module2.5/main.tf

provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  count = var.create_igw ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.azs[1]

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "database" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidr
  availability_zone = var.azs[2]

  tags = {
    Name = "database-subnet"
  }
}

resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "main-nat-gateway"
  }
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  
  depends_on = [aws_internet_gateway.igw]
}

# Creating Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Creating Private Route Table (if using NAT gateway):
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private[0].id
}

# Retrieve latest Amazon Linux 2 AMI ID
data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Security Group to allow SSH
resource "aws_security_group" "ssh_sg" {
  name        = "ce10-laoniu-sgp"      # Change the security group name
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ce10-laoniu-sgp"      # Change the security group name
  }
}

# Create EC2 Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.amzn2_ami.value
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.ssh_key_name
  vpc_security_group_ids      = [aws_security_group.ssh_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "ce10-laoniu-ec2instance"
  }
}

